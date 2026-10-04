#once
!~
 ~  bootstrap/frontend/clone.b: the frontend/clone.
 ~
 ~  The AST helpers every later pass uses: folding a constant expression, spelling a
 ~  type, and deep-copying a statement or an expression while substituting the type
 ~  parameters of the template it comes from.
 ~
 ~  Two shapes differ from the toolchain version, both because the language has no
 ~  container types:
 ~   * `name table<str, TArg>` is a chain of named arguments
 ~     (`TArgMap`), searched by walking it;
 ~   * a function answers one value, so the folders report success in `p_const_ok` /
 ~     `p_dbl_ok` and leave the value they folded in a field, and
 ~     `p_eval_const_arg` leaves its `TArg` in `p_arg_out`.
 ~!

#head "parser"

@TArg p_map_find -> @TArgMap m, str name {
    @TArgMap e = m;
    while e != null {
        if p_text_eq(e.name, name) {
            return e.arg;
        }
        e = e.next;
    }
    return null;
}

@TArgMap p_map_add -> @TArgMap m, str name, @TArg arg {
    TArgMap proto;
    @TArgMap e;
    malloc(@e, size proto);
    e.name = name;
    e.arg = arg;
    e.next = m;
    return e;
}

!!! A fresh argument record. Everything is written, because a partly filled record
!!! is read as whatever the block held before.
@TArg p_new_arg {
    TArg proto;
    @TArg a;
    malloc(@a, size proto);
    a.ty = INT;
    a.struct_name = "";
    a.is_value = false;
    a.value = 0;
    a.fvalue = 0.0;
    a.svalue = "";
    a.is_template = false;
    a.tname = "";
    a.is_pack = false;
    a.pack = null;
    a.next_pack = null;
    a.next = null;
    return a;
}

!!! Whether `is_const_expr` finds a constant expression: literals and the operators
!!! over them. A name, a call, a subscript or an address is not one.
bool p_is_const_expr -> @ExprNode n {
    if n == null {
        return false;
    }
    if n.nk == LIT_INT || n.nk == LIT_FLOAT || n.nk == LIT_STR || n.nk == LIT_BOOL ||
       n.nk == LIT_CHAR || n.nk == LIT_NULL {
        return true;
    }
    if n.nk == BINOP || n.nk == UNARY || n.nk == BITNOT || n.nk == SHL || n.nk == SHR {
        return p_is_const_expr(n.left) && p_is_const_expr(n.right);
    }
    if n.nk == TERNARY {
        if !p_is_const_expr(n.left) || !p_is_const_expr(n.right) {
            return false;
        }
        if n.args == null {
            return true;
        }
        return p_is_const_expr(n.args);
    }
    return false;
}

!!! The integer value of a constant expression: `5`, `-3`, `1 << 4`, `N * 2`. The
!!! answer is left in `p_eval_value` and `p_const_ok` says whether it folded.
void p_eval_const_int -> @ExprNode n {
    p_const_ok = false;
    if n == null {
        end;
    }
    if n.nk == LIT_INT {
        p_eval_value = n.int_val;
        p_const_ok = true;
        end;
    }
    if n.nk == LIT_BOOL {
        if n.bool_val {
            p_eval_value = 1;
        } else {
            p_eval_value = 0;
        }
        p_const_ok = true;
        end;
    }
    if n.nk == LIT_CHAR {
        p_eval_value = n.char_val;
        p_const_ok = true;
        end;
    }
    if n.nk == UNARY {
        p_eval_const_int(n.left);
        if !p_const_ok {
            end;
        }
        if p_text_eq(n.op, "-") {
            p_eval_value = 0 - p_eval_value;
            end;
        }
        if p_text_eq(n.op, "!") {
            if p_eval_value != 0 {
                p_eval_value = 0;
            } else {
                p_eval_value = 1;
            }
            end;
        }
        p_const_ok = false;
        end;
    }
    if n.nk == BITNOT {
        p_eval_const_int(n.left);
        if !p_const_ok {
            end;
        }
        p_eval_value = ~p_eval_value;
        end;
    }
    if n.nk == BINOP || n.nk == SHL || n.nk == SHR {
        p_eval_const_int(n.left);
        if !p_const_ok {
            end;
        }
        longlong a = p_eval_value;
        p_eval_const_int(n.right);
        if !p_const_ok {
            end;
        }
        longlong b = p_eval_value;
        if p_text_eq(n.op, "+") { p_eval_value = a + b; end; }
        if p_text_eq(n.op, "-") { p_eval_value = a - b; end; }
        if p_text_eq(n.op, "*") { p_eval_value = a * b; end; }
        if p_text_eq(n.op, "/") {
            if b == 0 {
                p_const_ok = false;
                end;
            }
            p_eval_value = a / b;
            end;
        }
        if p_text_eq(n.op, "%") {
            if b == 0 {
                p_const_ok = false;
                end;
            }
            p_eval_value = a % b;
            end;
        }
        if p_text_eq(n.op, "<<") { p_eval_value = a << b; end; }
        if p_text_eq(n.op, ">>") { p_eval_value = a >> b; end; }
        if p_text_eq(n.op, "&") { p_eval_value = a & b; end; }
        if p_text_eq(n.op, "|") { p_eval_value = a | b; end; }
        if p_text_eq(n.op, "^") { p_eval_value = a ^ b; end; }
        p_const_ok = false;
        end;
    }
    p_const_ok = false;
}

!!! The floating-point value of a constant expression: float and integer literals
!!! with + - * /, and the value is left in p_eval_dbl.

void p_eval_const_double -> @ExprNode n {
    p_dbl_ok = false;
    if n == null {
        end;
    }
    if n.nk == LIT_FLOAT {
        p_eval_dbl = n.float_val;
        p_dbl_ok = true;
        end;
    }
    if n.nk == LIT_INT {
        p_eval_dbl = (float)n.int_val;
        p_dbl_ok = true;
        end;
    }
    if n.nk == LIT_CHAR {
        p_eval_dbl = (float)n.char_val;
        p_dbl_ok = true;
        end;
    }
    if n.nk == UNARY {
        if !p_text_eq(n.op, "-") {
            end;
        }
        p_eval_const_double(n.left);
        if !p_dbl_ok {
            end;
        }
        p_eval_dbl = 0.0 - p_eval_dbl;
        end;
    }
    if n.nk == BINOP {
        p_eval_const_double(n.left);
        if !p_dbl_ok {
            end;
        }
        float a = p_eval_dbl;
        p_eval_const_double(n.right);
        if !p_dbl_ok {
            end;
        }
        float b = p_eval_dbl;
        if p_text_eq(n.op, "+") { p_eval_dbl = a + b; end; }
        if p_text_eq(n.op, "-") { p_eval_dbl = a - b; end; }
        if p_text_eq(n.op, "*") { p_eval_dbl = a * b; end; }
        if p_text_eq(n.op, "/") {
            if b == 0.0 {
                p_dbl_ok = false;
                end;
            }
            p_eval_dbl = a / b;
            end;
        }
        p_dbl_ok = false;
        end;
    }
    p_dbl_ok = false;
}

!!! The argument `eval_const_arg` folded, and whether it folded one at all: the
!!! result is an `@TArg` because a value argument carries a value, a float or a
!!! string. It is left in p_arg_out, with p_arg_ok saying whether it was folded.

void p_eval_const_arg -> @ExprNode n, VarType want {
    p_arg_ok = false;
    p_arg_out = null;
    if n == null {
        end;
    }
    @TArg out = p_new_arg();
    out.is_value = true;
    out.ty = want;
    if want == STR {
        if n.nk == LIT_STR {
            out.svalue = n.str_val;
            p_arg_out = out;
            p_arg_ok = true;
            end;
        }
        if n.nk == BINOP && p_text_eq(n.op, "+") {
            p_eval_const_arg(n.left, want);
            if !p_arg_ok {
                end;
            }
            @TArg a = p_arg_out;
            p_eval_const_arg(n.right, want);
            if !p_arg_ok {
                end;
            }
            out.svalue = a.svalue + p_arg_out.svalue;
            p_arg_out = out;
            p_arg_ok = true;
            end;
        }
        end;
    }
    if want == FLOAT {
        p_eval_const_double(n);
        if !p_dbl_ok {
            end;
        }
        out.fvalue = p_eval_dbl;
        p_arg_out = out;
        p_arg_ok = true;
        end;
    }
    p_eval_const_int(n);
    if !p_const_ok {
        end;
    }
    out.value = p_eval_value;
    p_arg_out = out;
    p_arg_ok = true;
}

!!! The spelling of a builtin type, which is what a type argument is written back
!!! as (the same text the .r carries).
str p_vt_spell -> VarType t {
    if t == VOID { return "void"; }
    if t == BOOL { return "bool"; }
    if t == INT { return "int"; }
    if t == STR { return "str"; }
    if t == FLOAT { return "float"; }
    if t == CHAR { return "char"; }
    if t == LONG { return "longlong"; }
    if t == ANY { return "any"; }
    if t == AT_INT { return "@int"; }
    if t == AT_LONG { return "@longlong"; }
    if t == AT_FLOAT { return "@float"; }
    if t == AT_CHAR { return "@char"; }
    if t == AT_STR { return "@str"; }
    if t == AT_VOID { return "@void"; }
    if t == AT_BOOL { return "@bool"; }
    if t == FUNC { return "func"; }
    if t == AT_FUNC { return "@func"; }
    return "int";
}

!!! Whether one character may stand in an identifier.
bool p_ident_char -> char c {
    return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'z') ||
           (c >= 'A' && c <= 'Z') || c == '_';
}

!!! One hexadecimal digit, lower case, as the text escape above writes it.
str hex_digit -> int v {
    if v < 10 {
        return (str)v;
    }
    if v == 10 { return "a"; }
    if v == 11 { return "b"; }
    if v == 12 { return "c"; }
    if v == 13 { return "d"; }
    if v == 14 { return "e"; }
    return "f";
}

!!! The identifier-safe encoding of one instantiation argument, used to mangle the
!!! instantiation: the type spelling, the struct name, or the value - with a
!!! negative sign spelled `m` and a float's point `_`, so distinct arguments never
!!! collide.
str p_targ_ident -> @TArg a {
    if a.is_template {
        return "tt_" + a.tname;
    }
    !!! A pack is mangled by the elements it holds, in order: `add(int, str)`
    !!! becomes `add_int_str`.
    if a.is_pack {
        str out_p = "";
        @TArg e = a.pack;
        while e != null {
            out_p = out_p + "_" + p_targ_ident(e);
            e = e.next_pack;
        }
        return out_p;
    }
    if !a.is_value {
        if a.struct_name != "" {
            return a.struct_name;
        }
        return p_vt_spell(a.ty);
    }
    if a.ty == STR {
        !!! The text is taken into a local first: a str that is a *field* cannot be
        !!! subscripted (see the note in lexer.b), and a local can.
        str sv = a.svalue;
        str out = "s";
        int i = 0;
        while sv[i] != (char)0 {
            char ch = sv[i];
            if (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') {
                out = out + char_text(ch);
            } else {
                int hi = ((int)ch) / 16;
                int lo = ((int)ch) % 16;
                out = out + "_" + hex_digit(hi) + hex_digit(lo);
            }
            i = i + 1;
        }
        return out;
    }
    if a.ty == FLOAT {
        !!! `%.17g`, the same text the toolchain prints before it is made into a name.
        str f = rgx_float_text(a.fvalue);
        str out2 = "f";
        int k = 0;
        while f[k] != (char)0 {
            char ch2 = f[k];
            if ch2 == '.' {
                out2 = out2 + "_";
            } else if ch2 == '-' {
                out2 = out2 + "m";
            } else if ch2 == '+' {
                out2 = out2 + "p";
            } else {
                out2 = out2 + char_text(ch2);
            }
            k = k + 1;
        }
        return out2;
    }
    !!! A negative value keeps its bits: the sign is not a character a name can hold,
    !!! so it becomes `m` (`val(18446744073709551615)()` mangles to `val_m1`).
    !!! `+ ""` copies the text out of the conversion ring (see rg_emit_struct_leaf_copy).
    str iout = (str)a.value + "";
    str res = "";
    int j = 0;
    while iout[j] != (char)0 {
        if iout[j] == '-' {
            res = res + "m";
        } else {
            res = res + char_text(iout[j]);
        }
        j = j + 1;
    }
    return res;
}

!!! A type argument written back as a type: `int`, `@float`, a struct name or the
!!! name of an already instantiated generic struct.
str p_targ_spell -> @TArg a {
    if a.is_template {
        return a.tname;
    }
    if a.struct_name != "" {
        return a.struct_name;
    }
    return p_vt_spell(a.ty);
}

!!! A non-type argument written back as the constant expression it came from, so a
!!! value parameter substituted into a type spelling (`Vec(N)` -> `Vec(3)`) stays
!!! parseable when the instantiation is resolved.
str p_spell_const -> @TArg a {
    if a.ty == STR {
        str sv = a.svalue;
        str out = "\"";
        int i = 0;
        while sv[i] != (char)0 {
            char c = sv[i];
            if c == '\\' || c == '"' {
                out = out + "\\";
                out = out + char_text(c);
            } else if c == '\n' {
                out = out + "\\n";
            } else if c == '\t' {
                out = out + "\\t";
            } else {
                out = out + char_text(c);
            }
            i = i + 1;
        }
        return out + "\"";
    }
    if a.ty == FLOAT {
        return rgx_float_text(a.fvalue);
    }
    return (str)a.value;
}

!!! Whether `name` stands at `s[i]`.
bool p_span_matches -> str s, int i, str name {
    int k = 0;
    while name[k] != (char)0 {
        if s[i + k] != name[k] {
            return false;
        }
        k = k + 1;
    }
    return true;
}

!!! Every whole occurrence of `name` in `s` replaced by `rep`. An occurrence that
!!! is part of a longer identifier is left alone.
str p_replace_ident -> str s, str name, str rep {
    str out = "";
    int n = p_text_len(name);
    int i = 0;
    int len = p_text_len(s);
    while i < len {
        if s[i] == name[0] && i + n <= len && p_span_matches(s, i, name) {
            bool left_ok = true;
            if i > 0 && p_ident_char(s[i - 1]) {
                left_ok = false;
            }
            bool right_ok = true;
            if i + n < len && p_ident_char(s[i + n]) {
                right_ok = false;
            }
            if left_ok && right_ok {
                out = out + rep;
                i = i + n;
                continue;
            }
        }
        out = out + char_text(s[i]);
        i = i + 1;
    }
    return out;
}

!!! Substitute template parameters into a type spelling: `Box(T)` becomes
!!! `Box(int)`, `Vec(N)` becomes `Vec(3)`. Only whole identifiers are replaced, so a
!!! parameter named `T` leaves `Tx` alone.
str p_subst_type_spelling -> str sp, @TArgMap tmap {
    if sp == "" || !p_is_generic_spelling(sp) {
        return sp;
    }
    str out = sp;
    @TArgMap e = tmap;
    while e != null {
        if e.name != "" && e.arg != null {
            str rep = "";
            if e.arg.is_value {
                rep = p_spell_const(e.arg);
            } else {
                rep = p_targ_spell(e.arg);
            }
            out = p_replace_ident(out, e.name, rep);
        }
        e = e.next;
    }
    return out;
}

!!! The CAST operator spelling of a concrete type, which is what a `(T)expr` cast
!!! inside a template becomes once T is bound.
str p_cast_op_for_type -> VarType t {
    if t == STR { return "toStr"; }
    if t == INT { return "toInt"; }
    if t == LONG { return "toLong"; }
    if t == FLOAT { return "toFloat"; }
    if t == BOOL { return "toBool"; }
    if t == CHAR { return "toChar"; }
    if t == AT_VOID { return "@void"; }
    if t == AT_INT { return "@int"; }
    if t == AT_LONG { return "@longlong"; }
    if t == AT_FLOAT { return "@float"; }
    if t == AT_CHAR { return "@char"; }
    if t == AT_STR { return "@str"; }
    if t == AT_BOOL { return "@bool"; }
    if t == FUNC { return "toFunc"; }
    if t == AT_FUNC { return "toAtFunc"; }
    return "toInt";
}

@ExprNode p_clone_expr -> @ExprNode n {
    return p_clone_expr_t(n, null);
}

!!! A copy of an expression, with the type parameters of `tmap` substituted. The
!!! version copies the fields it knows about and leaves the rest at their
!!! defaults; here every field is written, because nothing else would define it.
@ExprNode p_clone_expr_t -> @ExprNode n, @TArgMap tmap {
    if n == null {
        return null;
    }
    @ExprNode c = p_new_expr(n.nk);
    c.int_val = n.int_val;
    c.lit_is_long = n.lit_is_long;
    !!! `count a` of a stack array is answered with a number; the clone carries the
    !!! answer and the flag that says it is one.
    c.count_folded = n.count_folded;
    c.fold_right = n.fold_right;
    c.float_val = n.float_val;
    c.str_val = n.str_val;
    c.str_from = n.str_from;
    c.str_to = n.str_to;
    c.bool_val = n.bool_val;
    c.char_val = n.char_val;
    c.var_name = n.var_name;
    c.var_name_start = n.var_name_start;
    c.var_name_stop = n.var_name_stop;
    c.member_name = n.member_name;
    c.op = n.op;
    c.is_super = n.is_super;
    c.has_receiver = n.has_receiver;
    c.is_overload_call = n.is_overload_call;
    c.spread = n.spread;
    c.struct_type = n.struct_type;
    c.result_type = n.result_type;
    c.is_unsigned = n.is_unsigned;
    c.type_resolved = n.type_resolved;
    c.address_type = n.address_type;
    c.convert_to = n.convert_to;
    c.ptr_depth = n.ptr_depth;
    c.line = n.line;
    c.col = n.col;
    c.tok_len = n.tok_len;
    c.op_line = n.op_line;
    c.op_col = n.op_col;
    c.cast_type_param = n.cast_type_param;
    c.left = p_clone_expr_t(n.left, tmap);
    c.right = p_clone_expr_t(n.right, tmap);
    @ExprNode a = n.args;
    while a != null {
        c.args = p_chain_expr(c.args, p_clone_expr_t(a, tmap));
        a = a.next;
    }
    c.nargs = n.nargs;
    @ExprNode ix = n.indices;
    while ix != null {
        c.indices = p_chain_expr(c.indices, p_clone_expr_t(ix, tmap));
        ix = ix.next;
    }
    @VarTypeNode tv = n.targs;
    while tv != null {
        c.targs = p_chain_type(c.targs, p_new_type(tv.ty));
        tv = tv.next;
    }
    @StrNode ts = n.targ_structs;
    while ts != null {
        str sp = ts.s;
        if tmap != null && p_is_generic_spelling(sp) {
            sp = p_subst_type_spelling(sp, tmap);
        }
        c.targ_structs = p_chain_str(c.targ_structs, p_new_name(sp, ts.line, ts.col));
        ts = ts.next;
    }
    @ExprNode te = n.targ_exprs;
    while te != null {
        c.targ_exprs = p_chain_expr(c.targ_exprs, p_clone_expr_t(te, tmap));
        te = te.next;
    }
    @BoolNode tb = n.targ_is_value;
    while tb != null {
        c.targ_is_value = p_chain_bool(c.targ_is_value, p_new_bool(tb.v));
        tb = tb.next;
    }
    @StrNode an = n.arg_names;
    while an != null {
        c.arg_names = p_chain_str(c.arg_names, p_new_name(an.s, an.line, an.col));
        an = an.next;
    }
    @IntNode al = n.arg_name_lines;
    while al != null {
        c.arg_name_lines = p_chain_int(c.arg_name_lines, p_new_int(al.v));
        al = al.next;
    }
    @IntNode ac = n.arg_name_cols;
    while ac != null {
        c.arg_name_cols = p_chain_int(c.arg_name_cols, p_new_int(ac.v));
        ac = ac.next;
    }
    @IntNode aln = n.arg_name_lens;
    while aln != null {
        c.arg_name_lens = p_chain_int(c.arg_name_lens, p_new_int(aln.v));
        aln = aln.next;
    }
    !!! A non-type template parameter is substituted as a literal everywhere it is
    !!! used (an array size, arithmetic, a loop bound, ...).
    if tmap != null && c.nk == VAR_REF {
        @TArg arg = p_map_find(tmap, c.var_name);
        if arg != null && arg.is_value {
            c.var_name = "";
            if arg.ty == FLOAT {
                c.nk = LIT_FLOAT;
                c.float_val = arg.fvalue;
                c.result_type = FLOAT;
            } else if arg.ty == STR {
                c.nk = LIT_STR;
                c.str_val = arg.svalue;
                !!! The text comes from the argument and not from the source the node
                !!! was read in, so the span it was read with does not stand for it.
                c.str_from = 0;
                c.str_to = 0;
                c.result_type = STR;
            } else {
                c.nk = LIT_INT;
                c.int_val = arg.value;
                c.result_type = int_literal_type(arg.value);
            }
            return c;
        }
    }
    !!! `(T)expr` inside a template body: with T bound, the cast that was left open
    !!! becomes the concrete one.
    if c.nk == CAST && c.cast_type_param != "" && tmap != null {
        @TArg it = p_map_find(tmap, c.cast_type_param);
        if it != null {
            !!! A struct argument has no value cast; only a builtin binding names one.
            if it.struct_name == "" {
                c.op = p_cast_op_for_type(it.ty);
            }
            c.cast_type_param = "";
        }
    }
    return c;
}

!!! A copy of a statement tree with the type parameters of `tmap` substituted. A
!!! type parameter is carried in the struct_type/ret_struct/fparam_struct name
!!! slots; when one matches a key of the map, the concrete type replaces it.
@StmtNode p_clone_stmt -> @StmtNode s, @TArgMap tmap {
    if s == null {
        return null;
    }
    @StmtNode c = p_new_stmt(s.nk);
    c.decl_type = s.decl_type;
    c.ptr_depth = s.ptr_depth;
    c.decl_is_ref = s.decl_is_ref;
    c.decl_is_const = s.decl_is_const;
    c.decl_is_static = s.decl_is_static;
    c.decl_is_unsigned = s.decl_is_unsigned;
    c.static_guard = s.static_guard;
    c.static_init = s.static_init;
    c.var_name = s.var_name;
    c.line = s.line;
    c.col = s.col;
    c.var_line = s.var_line;
    c.var_col = s.var_col;
    c.type_col = s.type_col;
    c.type_len = s.type_len;
    c.incr_op = s.incr_op;
    c.incr_prefix = s.incr_prefix;
    @StrNode fp = s.fparams;
    while fp != null {
        c.fparams = p_chain_str(c.fparams, p_new_name(fp.s, fp.line, fp.col));
        fp = fp.next;
    }
    @VarTypeNode ft = s.fparam_types;
    while ft != null {
        c.fparam_types = p_chain_type(c.fparam_types, p_new_type(ft.ty));
        ft = ft.next;
    }
    @StrNode fs = s.fparam_struct;
    while fs != null {
        c.fparam_struct = p_chain_str(c.fparam_struct, p_new_name(fs.s, fs.line, fs.col));
        fs = fs.next;
    }
    @BoolNode fa = s.fparam_is_array;
    while fa != null {
        c.fparam_is_array = p_chain_bool(c.fparam_is_array, p_new_bool(fa.v));
        fa = fa.next;
    }
    @BoolNode fr = s.fparam_is_ref;
    while fr != null {
        c.fparam_is_ref = p_chain_bool(c.fparam_is_ref, p_new_bool(fr.v));
        fr = fr.next;
    }
    @BoolNode fc = s.fparam_is_const;
    while fc != null {
        c.fparam_is_const = p_chain_bool(c.fparam_is_const, p_new_bool(fc.v));
        fc = fc.next;
    }
    @BoolNode fst = s.fparam_is_static;
    while fst != null {
        c.fparam_is_static = p_chain_bool(c.fparam_is_static, p_new_bool(fst.v));
        fst = fst.next;
    }
    @BoolNode fu = s.fparam_is_unsigned;
    while fu != null {
        c.fparam_is_unsigned = p_chain_bool(c.fparam_is_unsigned, p_new_bool(fu.v));
        fu = fu.next;
    }
    @BoolNode fhd = s.fparam_has_default;
    while fhd != null {
        c.fparam_has_default = p_chain_bool(c.fparam_has_default, p_new_bool(fhd.v));
        fhd = fhd.next;
    }
    @ExprNode fd = s.fparam_defaults;
    while fd != null {
        c.fparam_defaults = p_chain_expr(c.fparam_defaults, p_clone_expr(fd));
        fd = fd.next;
    }
    c.nfparams = s.nfparams;
    @StrNode an = s.arg_names;
    while an != null {
        c.arg_names = p_chain_str(c.arg_names, p_new_name(an.s, an.line, an.col));
        an = an.next;
    }
    @TArg ta = s.targs;
    while ta != null {
        @TArg na = p_new_arg();
        na.ty = ta.ty;
        na.struct_name = ta.struct_name;
        na.is_value = ta.is_value;
        na.value = ta.value;
        na.fvalue = ta.fvalue;
        na.svalue = ta.svalue;
        na.is_template = ta.is_template;
        na.tname = ta.tname;
        !!! A pack argument keeps its elements, in order.
        na.is_pack = ta.is_pack;
        @TArg pe = ta.pack;
        @TArg pe_tail = null;
        while pe != null {
            @TArg ne = p_new_arg();
            ne.ty = pe.ty;
            ne.struct_name = pe.struct_name;
            ne.is_value = pe.is_value;
            ne.value = pe.value;
            ne.fvalue = pe.fvalue;
            ne.svalue = pe.svalue;
            ne.is_template = pe.is_template;
            ne.tname = pe.tname;
            ne.next_pack = null;
            if pe_tail == null {
                na.pack = ne;
            } else {
                pe_tail.next_pack = ne;
            }
            pe_tail = ne;
            pe = pe.next_pack;
        }
        c.targs = p_chain_targ(c.targs, na);
        ta = ta.next;
    }
    @StrNode ts = s.targ_structs;
    while ts != null {
        str sp = ts.s;
        if p_is_generic_spelling(sp) {
            sp = p_subst_type_spelling(sp, tmap);
        }
        c.targ_structs = p_chain_str(c.targ_structs, p_new_name(sp, ts.line, ts.col));
        ts = ts.next;
    }
    @ExprNode te = s.targ_exprs;
    while te != null {
        c.targ_exprs = p_chain_expr(c.targ_exprs, p_clone_expr(te));
        te = te.next;
    }
    @BoolNode tb = s.targ_is_value;
    while tb != null {
        c.targ_is_value = p_chain_bool(c.targ_is_value, p_new_bool(tb.v));
        tb = tb.next;
    }
    c.variadic = s.variadic;
    c.params_from_pack = s.params_from_pack;
    c.pack_ptypes = s.pack_ptypes;
    c.pack_pnames = s.pack_pnames;
    c.func_ret_type = s.func_ret_type;
    c.ret_is_unsigned = s.ret_is_unsigned;
    c.ret_struct = s.ret_struct;
    c.ret_struct_ptr = s.ret_struct_ptr;
    c.ret_ptr_depth = s.ret_ptr_depth;
    c.has_return = s.has_return;
    c.call_target = s.call_target;
    c.bapi_segs = s.bapi_segs;
    c.builtin_annotation = s.builtin_annotation;
    c.end_line = s.end_line;
    c.end_col = s.end_col;
    c.broken = s.broken;
    c.is_local = s.is_local;
    c.is_stub = s.is_stub;
    c.is_reload = s.is_reload;
    c.synth_op = s.synth_op;
    c.params_line = s.params_line;
    c.params_col = s.params_col;
    c.params_len = s.params_len;
    c.struct_type = s.struct_type;
    c.member_name = s.member_name;
    c.member_chain = s.member_chain;
    c.members_before_index = s.members_before_index;
    c.is_method_call = s.is_method_call;
    c.is_overload_call = s.is_overload_call;
    !!! The access section the member was written in: an instantiated method keeps
    !!! the one of the template it was cloned from.
    c.access = s.access;
    c.member_line = s.member_line;
    c.member_col = s.member_col;
    c.is_super = s.is_super;
    c.is_index_ptr_store = s.is_index_ptr_store;
    c.is_index_chain_store = s.is_index_chain_store;
    c.is_array = s.is_array;
    c.array_dims = s.array_dims;
    c.rcode_text = s.rcode_text;

    c.expr = p_clone_expr_t(s.expr, tmap);
    c.array_len_expr = p_clone_expr_t(s.array_len_expr, tmap);
    @ExprNode a = s.args;
    while a != null {
        c.args = p_chain_expr(c.args, p_clone_expr_t(a, tmap));
        a = a.next;
    }
    @ExprNode ai = s.array_init;
    while ai != null {
        c.array_init = p_chain_expr(c.array_init, p_clone_expr_t(ai, tmap));
        ai = ai.next;
    }
    @ExprNode as = s.assign_indices;
    while as != null {
        c.assign_indices = p_chain_expr(c.assign_indices, p_clone_expr_t(as, tmap));
        as = as.next;
    }
    @ExprNode ce = s.case_exprs;
    while ce != null {
        c.case_exprs = p_chain_expr(c.case_exprs, p_clone_expr_t(ce, tmap));
        ce = ce.next;
    }
    @StmtNode b1 = s.true_body;
    while b1 != null {
        c.true_body = p_chain_stmt(c.true_body, p_clone_stmt(b1, tmap));
        b1 = b1.next;
    }
    @StmtNode b2 = s.false_body;
    while b2 != null {
        c.false_body = p_chain_stmt(c.false_body, p_clone_stmt(b2, tmap));
        b2 = b2.next;
    }
    @StmtNode cb = s.case_bodies;
    while cb != null {
        c.case_bodies = p_chain_stmt(c.case_bodies, p_clone_stmt(cb, tmap));
        cb = cb.next;
    }
    @StmtNode ub = s.unmatch_body;
    while ub != null {
        c.unmatch_body = p_chain_stmt(c.unmatch_body, p_clone_stmt(ub, tmap));
        ub = ub.next;
    }

    !!! The type positions: a struct argument keeps its name in the struct slot (with
    !!! an INT placeholder for its VarType), a builtin argument replaces the VarType
    !!! and clears the name.
    if c.ret_struct != "" {
        @TArg it = p_map_find(tmap, c.ret_struct);
        if it != null && !it.is_value {
            c.func_ret_type = it.ty;
            c.ret_struct = it.struct_name;
        }
    }
    @StrNode fsn = c.fparam_struct;
    @VarTypeNode ftn = c.fparam_types;
    while fsn != null {
        if fsn.s != "" {
            @TArg it2 = p_map_find(tmap, fsn.s);
            if it2 != null && !it2.is_value {
                if ftn != null {
                    ftn.ty = it2.ty;
                }
                fsn.s = it2.struct_name;
            }
        }
        fsn = fsn.next;
        if ftn != null {
            ftn = ftn.next;
        }
    }
    if c.struct_type != "" {
        @TArg it3 = p_map_find(tmap, c.struct_type);
        if it3 != null && !it3.is_value {
            c.decl_type = it3.ty;
            c.struct_type = it3.struct_name;
        }
    }
    !!! A type spelling that carries template arguments (`Box(T)`) is substituted
    !!! textually; the concrete spelling is resolved afterwards.
    if p_is_generic_spelling(c.ret_struct) {
        c.ret_struct = p_subst_type_spelling(c.ret_struct, tmap);
    }
    @StrNode gs = c.fparam_struct;
    while gs != null {
        if p_is_generic_spelling(gs.s) {
            gs.s = p_subst_type_spelling(gs.s, tmap);
        }
        gs = gs.next;
    }
    if p_is_generic_spelling(c.struct_type) {
        c.struct_type = p_subst_type_spelling(c.struct_type, tmap);
    }
    return c;
}
