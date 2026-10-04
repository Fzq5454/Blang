#once
!~
 ~  bootstrap/frontend/rgen_check_expr.b: the frontend/rgen_check_expr.
 ~
 ~  The expression side of the type check: the initializer of a declaration against
 ~  the type it is declared with, the value of a `return` against the enclosing
 ~  function's return type, the integer an array size or a subscript has to be, the
 ~  collection of the call sites the driver asks for, and the body loop that walks a
 ~  statement chain while the declarations of that body are in scope.
 ~
 ~  Three things the toolchain carries that this implementation holds differently:
 ~   * `n->lambda_ret_type` lives in the literal's LambdaRec here (ast.b carries only
 ~     the id), so it is read through p_find_lambda(n->lambda_id);
 ~   * the `sites` table of collect_call_sites is a parameter of both overloads
 ~     and the two rg_collect_call_sites_*_out_sites globals here, one per overload;
 ~     the statement walk hands its table to the expression walk and takes the
 ~     possibly longer chain back (rgx_sites_to_expr below);
 ~   * a void function that has to say something uses rg_has_errors, which is the
 ~     `has_errors = true` of the toolchain.
 ~
 ~  `s->children` (the members of a PACKAGE) is `s->true_body` in this implementation
 ~  (parser_package.b), so the true_body walk below already covers the `children`
 ~  walk and is written once.
 ~!

#head "rgen"
#head "rgen_heads"

!!! check_expr: the value of a declaration or an assignment element against the type
!!! it is written into. `missing` is the type expected at that position; `d` is the
!!! statement it belongs to, which is what the note under a mismatch points at.
bool rg_check_expr -> @StmtNode d, @ExprNode n, VarType missing {
    !!! Struct variables bypass type checking (expanded into fields). The initializer
    !!! still has to be resolved when the struct value is read from a field or an
    !!! array element, so the copy knows which struct it reads.
    if d.struct_type != "" {
        if n != null && (n.nk == FIELD_ELEM || n.nk == ARRAY_ACCESS ||
                         n.nk == MEMBER_ACCESS || n.nk == ASSIGN_EXPR) {
            rg_resolve_expr_type(n);
        }
        return true;
    }
    if d.nk == DECLARE && rg_has_self_ref(n, d.var_name) {
        rg_fmt_err(d.var_line, d.var_col,
                   "variable cannot reference itself in its own initializer",
                   pe_len(d.var_name), (str)null, 0, true);
        return false;
    }
    if !rg_resolve_expr_type(n) {
        return false;
    }
    VarType actual = n.result_type;
    !!! `@void` declared pointer initialized from a typed pointer: inherit the pointee
    !!! type + depth so $$ / $$$ / ... multi-deref stays type-correct.
    if d.nk == DECLARE && missing == AT_VOID && n.ptr_depth >= 1 {
        rg_syms = rg_vartypemap_set(rg_syms, d.var_name, n.result_type);
        rg_sym_depth = rg_intmap_set(rg_sym_depth, d.var_name, n.ptr_depth);
        d.decl_type = n.result_type;
        d.ptr_depth = n.ptr_depth;
    }
    !!! Track the return type of func/@func variables so later indirect calls resolve
    !!! to the correct result type (needed for lambda-returning lambdas). the toolchain
    !!! reads `n->lambda_ret_type`; this implementation reads the literal's record by id.
    if (missing == FUNC || missing == AT_FUNC) && n.nk == LAMBDA {
        @LambdaRec lr = p_find_lambda(n.lambda_id);
        if lr != null {
            rg_sym_call_ret = rg_vartypemap_set(rg_sym_call_ret, d.var_name, lr.ret_type);
        }
    }
    if missing == ANY || actual == ANY {
        return true;
    }
    if missing == actual {
        return true;
    }
    !!! Implicit conversion: @void <-> any address type (@int, @str, @bool, @float,
    !!! @char).
    if (missing == AT_VOID && rg_is_at_type(actual)) ||
       (actual == AT_VOID && rg_is_at_type(missing)) {
        return true;
    }
    !!! -Econversion: allow safe implicit conversions with real codegen.
    if (rg_wconversion && rg_is_wconversion_allowed(actual, missing)) ||
       rg_is_free_widening(actual, missing) {
        n.convert_to = missing;
        return true;
    }
    !!! Check -Rimp flags: downgrade to warning + note.
    str pair = rg_type_name(missing) + "-" + rg_type_name(actual);
    if rg_rimp_is_allowed(pair) {
        rg_fmt_warn(n.line, n.col, "type mismatch", n.tok_len);
        rg_emit_rimp_note(d, n, missing, actual);
        return true;
    }
    !!! Error: type mismatch. The pair between the escape codes is the flag that would
    !!! downgrade this one, spelled `-Rimp-<missing>-<actual>`.
    str esc = char_text((char)27);
    str msg = "type mismatch [" + esc + "[1;31m-Rimp-" + rg_type_name(missing) + "-" +
              rg_type_name(actual) + esc + "[0m]";
    rg_fmt_err(n.line, n.col, msg, n.tok_len, (str)null, 0, true);
    rg_emit_type_note(d, n, missing, actual);
    return false;
}

!!! rg_resolve_assign: `a = b` written where a value is wanted. The expression is
!!! worth the object that was written, so its type is the target's: `int b = (a = 1);`
!!! takes an int, and a struct assignment is a struct value. The value has to fit the
!!! target exactly as it does in the statement form - an int is stored in a longlong
!!! because widening cannot lose a value, while a `str` into an `int` is the same
!!! `type mismatch` the statement `a = b;` reports. the toolchain
!!! `RGenerator::resolve_assign` is the same step.
bool rg_resolve_assign -> @ExprNode n {
    if n == null || n.left == null || n.right == null {
        return false;
    }
    !!! The target first: a field, an element and the object a pointer names all have
    !!! to be resolved to be typed, and resolving them is what checks the field access
    !!! and the subscript.
    if !rg_resolve_expr_type(n.left) {
        return false;
    }
    !!! What the value is stored into. The .r has no assignment that answers a value,
    !!! so the store is a call of a generated function that is handed the address of
    !!! the target - and the two things this front end can spell an address of are a
    !!! variable and the object a pointer already names.
    @ExprNode t = n.left;
    while t != null && t.nk == ASSIGN_EXPR {
        t = t.left;
    }
    bool deref = false;
    if t != null && t.nk == UNARY && p_text_eq(t.op, "$") && t.left != null && t.left.nk == VAR_REF {
        deref = true;
    }
    if t == null || (t.nk != VAR_REF && !deref) {
        rg_fmt_err(n.line, n.col, "an assignment written as a value must target a variable",
                   n.left.tok_len, (str)null, 0, true);
        rg_has_errors = true;
        return false;
    }
    !!! A `func`, `@func` or `any` target has no store helper: the value those hold is
    !!! not one the generated function could be given a name for.
    if pe_eq(rg_assign_helper_tag(t), "") {
        str msg = "cannot write an assignment of type '" + rg_type_name(t.result_type) + "' as a value";
        rg_fmt_err(n.line, n.col, msg, n.left.tok_len, (str)null, 0, true);
        rg_has_errors = true;
        return false;
    }
    bool seq = n.left.nk == ASSIGN_EXPR;
    rg_ensure_assign_helper(t, seq);
    n.result_type = n.left.result_type;
    n.struct_type = n.left.struct_type;
    n.ptr_depth = n.left.ptr_depth;
    str tst = n.left.struct_type;
    if tst != "" {
        !!! A whole-object assignment: the value has to be that struct. A different
        !!! struct, or a value that is definitely not a struct, would copy the wrong
        !!! bits into the object.
        str st = rg_expr_struct_type(n.right);
        if !pe_eq(st, tst) && (st != "" || rg_expr_definitely_not_struct(n.right)) {
            str shown = st;
            if shown == "" {
                shown = rg_type_name(n.right.result_type);
            }
            str msg2 = "cannot assign a '" + shown + "' value to '" + tst + "'";
            rg_fmt_err(n.line, n.col, msg2, n.left.tok_len, (str)null, 0, true);
            rg_has_errors = true;
            return false;
        }
        return true;
    }
    !!! The check is the one a declaration runs, with the target standing in for the
    !!! declared name: its position and its name are what the note under a mismatch
    !!! quotes. The record is made by the parser's own constructor, so every field the
    !!! check reads is a value and not whatever the block held.
    @StmtNode synth = p_new_stmt(ASSIGN);
    synth.line = n.line;
    synth.col = n.col;
    synth.struct_type = "";
    synth.var_line = n.left.line;
    synth.var_col = n.left.col;
    synth.var_name = n.left.var_name;
    if pe_eq(synth.var_name, "") {
        synth.var_name = n.left.member_name;
    }
    if !rg_check_expr(synth, n.right, n.result_type) {
        rg_has_errors = true;
        return false;
    }
    return true;
}

!!! check_return_type: `return expr;` must produce the enclosing function's declared
!!! return type. It used to be unchecked, so e.g. returning an int from a `float`
!!! function compiled and the caller then read the result from the wrong register
!!! (xmm0), printing 0.0. The rules mirror check_expr() so -Econversion / -Rimp and
!!! the @void wildcard behave exactly like they do in a declaration.
bool rg_check_return_type -> @StmtNode s {
    if s.expr == null {
        return true;
    }
    VarType want = rg_cur_func_ret;
    !!! Void functions: the returned value is discarded, so nothing to check. Struct
    !!! returns use a pointer convention checked elsewhere.
    if want == VOID || want == ANY {
        return true;
    }
    !!! Struct return: the value has to be that struct object. A different struct, or a
    !!! value that is definitely not a struct, would copy the wrong bits.
    if rg_cur_func_ret_struct != "" {
        str st = rg_expr_struct_type(s.expr);
        !!! The struct names are compared as text: `==`/`!=` on two `str` values
        !!! compares the blocks they point at, and a name read out of a table is a
        !!! block of its own.
        if !pe_eq(st, rg_cur_func_ret_struct) &&
           (st != "" || rg_expr_definitely_not_struct(s.expr)) {
            str shown = st;
            if shown == "" {
                shown = rg_type_name(s.expr.result_type);
            }
            str msg = "cannot return a '" + shown + "' value from a function returning '" +
                      rg_cur_func_ret_struct + "'";
            rg_fmt_err(s.line, s.col, msg, 6, (str)null, 0, true);
            rg_has_errors = true;
            return false;
        }
        return true;
    }
    !!! A struct returned from a scalar-returning function: the conversion has to be
    !!! written explicitly (`return (int)v;`), so this is an error.
    str st2 = rg_expr_struct_type(s.expr);
    if st2 != "" {
        str msg2 = "cannot return a '" + st2 + "' value from a function returning '" +
                   rg_type_name(want) + "'; convert it explicitly";
        rg_fmt_err(s.line, s.col, msg2, 6, (str)null, 0, true);
        rg_has_errors = true;
        return false;
    }
    if !rg_resolve_expr_type(s.expr) {
        return false;
    }
    VarType got = s.expr.result_type;
    if got == want || got == ANY {
        return true;
    }
    if (want == AT_VOID && rg_is_at_type(got)) ||
       (got == AT_VOID && rg_is_at_type(want)) {
        return true;
    }
    if (rg_wconversion && rg_is_wconversion_allowed(got, want)) ||
       rg_is_free_widening(got, want) {
        s.expr.convert_to = want;
        return true;
    }
    str pair = rg_type_name(want) + "-" + rg_type_name(got);
    if rg_rimp_is_allowed(pair) {
        rg_fmt_warn(s.expr.line, s.expr.col, "type mismatch", s.expr.tok_len);
        return true;
    }
    str esc = char_text((char)27);
    str msg3 = "return type mismatch [" + esc + "[1;31m-Rimp-" + rg_type_name(want) + "-" +
               rg_type_name(got) + esc + "[0m]";
    rg_fmt_err(s.expr.line, s.expr.col, msg3, s.expr.tok_len, (str)null, 0, true);
    return false;
}

!!! check_int_index: array sizes and subscripts must be integers. Reported with a
!!! dedicated message instead of the generic type mismatch, which used to compare the
!!! *element* type against the subscript and read like "has 'int' and 'str'". `what`
!!! is the `const char*` naming the position ("size" or "index"). Each position is
!!! reported once: the key of the report is `what:line:col` in rg_index_reported.
bool rg_check_int_index -> @ExprNode e, str what {
    if e == null {
        return true;
    }
    if !rg_resolve_expr_type(e) {
        return false;
    }
    VarType got = e.result_type;
    !!! Whole numbers only: a char/bool index is an integer in this language, `any` is
    !!! the usual wildcard.
    if got == INT || got == CHAR || got == BOOL || got == ANY {
        return true;
    }
    if rg_wconversion && rg_is_wconversion_allowed(got, INT) {
        e.convert_to = INT;
        return true;
    }
    str key = what + ":" + (str)e.line + ":" + (str)e.col;
    if rg_set_has(rg_index_reported, key) {
        return false;
    }
    rg_index_reported = rg_set_add(rg_index_reported, key);
    str msg = "array " + what + " must be an integer, got '" + rg_type_name(got) + "'";
    rg_fmt_err(e.line, e.col, msg, e.tok_len, (str)null, 0, true);
    return false;
}

!!! gen_body: a statement chain generated with its own declarations in scope. The
!!! declarations of this body shadow outer variables of the same name for as long as
!!! the body is generated.
void rg_gen_body -> @StmtNode body {
    rg_push_local_decls(body);
    @StmtNode s = body;
    while s != null {
        rg_gen_stmt(s);
        s = s.next;
    }
    rg_pop_local_decls();
}
