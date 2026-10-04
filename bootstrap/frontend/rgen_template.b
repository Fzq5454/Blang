#once
!~
 ~  bootstrap/frontend/rgen_template.b: the frontend/rgen_template, the
 ~  instantiation of the `introduce TYPENAME T { ... }` function templates.
 ~
 ~  A template call is deduced, cloned with the concrete type arguments and
 ~  registered under a mangled name (`add` becomes `add_int`), and the call site is
 ~  retargeted to the clone. The clones are inserted right before the statement that
 ~  first needed one, because the backend resolves FUNC definitions in source order.
 ~
 ~  The `done` set and the `new_stmts` list the toolchain passes by reference down the
 ~  descent are the `rg_<method>_out_done` / `_out_new_stmts` globals per method
 ~  (rgen.b): each nested call is handed the one of the caller and its answer is read
 ~  back, so one set and one list travel through the whole walk, exactly as the two
 ~  references do in the toolchain.
 ~
 ~  A template body is only resolved when it is instantiated, so a name that nothing
 ~  ever resolves was never checked: check_template_bodies() walks each template that
 ~  no instantiation resolved once and reports the names that are neither a parameter,
 ~  a local, nor anything the file declares.
 ~!

#head "rgen"

!!! The local helpers below are used before their definitions.
stub void rgt_instantiate_body -> @StmtNode body;
stub int rgt_expr_count -> @ExprNode head;
stub @VarTypeNode rgt_vt_of_targs -> @TArg head;
stub int rgt_intnode_n -> @IntNode head;
stub @RgLongNode rgt_longchain -> @IntNode head;
stub void rgt_str_set -> @StrNode head, int i, str to;

@StrNode rgt_str_at -> @StrNode head, int i {
    int k = 0;
    @StrNode e = head;
    while e != null {
        if k == i {
            return e;
        }
        k = k + 1;
        e = e.next;
    }
    return null;
}

int rgt_str_n -> @StrNode head {
    int n = 0;
    @StrNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

int rgt_vt_n -> @VarTypeNode head {
    int n = 0;
    @VarTypeNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

int rgt_bool_n -> @BoolNode head {
    int n = 0;
    @BoolNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

VarType rgt_vt_at -> @VarTypeNode head, int i {
    int k = 0;
    @VarTypeNode e = head;
    while e != null {
        if k == i {
            return e.ty;
        }
        k = k + 1;
        e = e.next;
    }
    return VOID;
}

bool rgt_bool_at -> @BoolNode head, int i {
    int k = 0;
    @BoolNode e = head;
    while e != null {
        if k == i {
            return e.v;
        }
        k = k + 1;
        e = e.next;
    }
    return false;
}

@ExprNode rgt_expr_at -> @ExprNode head, int i {
    int k = 0;
    @ExprNode e = head;
    while e != null {
        if k == i {
            return e;
        }
        k = k + 1;
        e = e.next;
    }
    return null;
}

!!! Type deduction of one call, as a probe: if it cannot type the arguments, what it
!!! reported is rolled back and the call is left unresolved, because
!!! typecheck_pass() re-resolves the same expression afterwards and emits the real
!!! error at the right position. Without the rollback a nested template call
!!! reported a bogus "undeclared function '<name>'" error even though the template
!!! does exist.
void rgt_give_up -> str saved_err, bool saved_has_errors {
    rg_err = saved_err;
    rg_has_errors = saved_has_errors;
}

str rg_instantiate_template_call -> str name, @ExprNode args, int line, int col {
    @TemplateFunc tf = p_find_template_func(name);
    if tf == null {
        return "";
    }
    str saved_err = rg_err;
    bool saved_has_errors = rg_has_errors;
    @RgStrSet done = rg_instantiate_template_call_out_done;
    @StmtNode new_stmts = rg_instantiate_template_call_out_new_stmts;
    @TArgMap tmap = null;
    !!! A template with a type pack takes its parameters from that pack, so a single
    !!! type parameter is not deduced from an argument - it is the return type, not a
    !!! parameter type. Only an explicit `name(T)(...)` binds it, and an
    !!! instantiation that never mentions it does not need it at all (a pack-only
    !!! helper like `howmany` is called with no type list).
    bool has_pack = rgt_bool_any(tf.tparam_is_pack);
    int i = 0;
    int nt = rgt_str_n(tf.tparams);
    while i < nt {
        @StrNode tp = rgt_str_at(tf.tparams, i);
        if rgt_bool_at(tf.tparam_is_value, i) {
            !!! A non-type parameter is never deduced from a runtime value.
            rgt_give_up(saved_err, saved_has_errors);
            rg_report_value_needed(name, tp.s, line, col);
            return "";
        }
        if rgt_bool_at(tf.tparam_is_pack, i) {
            !!! The pack holds every argument: `add(1, 2, 3)` gives it all three.
            @TArg pa = p_new_arg();
            pa.is_pack = true;
            @ExprNode ae = args;
            while ae != null {
                @TArg pe = p_new_arg();
                if !rg_targ_from_arg(ae, pe) {
                    rgt_give_up(saved_err, saved_has_errors);
                    return "";
                }
                pa.pack = p_chain_pack_targ(pa.pack, pe);
                ae = ae.next;
            }
            tmap = p_map_add(tmap, tp.s, pa);
            i = i + 1;
            continue;
        }
        if has_pack {
            !!! Left unbound; the instantiation is refused below when it uses it.
            i = i + 1;
            continue;
        }
        if i >= rgt_expr_count(args) {
            !!! Nothing left to deduce from: every type parameter needs either an
            !!! argument of that type or an explicit `name(<type>)(...)`. Report that
            !!! instead of the misleading "cannot find the implementation".
            rgt_give_up(saved_err, saved_has_errors);
            rg_report_missing_targ(name, tp.s, line, col);
            return "";
        }
        @ExprNode arg = rgt_expr_at(args, i);
        @TArg ta = p_new_arg();
        if !rg_targ_from_arg(arg, ta) {
            rgt_give_up(saved_err, saved_has_errors);
            return "";
        }
        tmap = p_map_add(tmap, tp.s, ta);
        i = i + 1;
    }
    !!! A type parameter the instantiation does not bind and does not mention is
    !!! simply unused (`howmany` returns `int`, so its `T` never matters); one it
    !!! does use has to be written at the call site.
    @StrNode tp3 = tf.tparams;
    while tp3 != null {
        if p_map_find(tmap, tp3.s) == null {
            bool used = false;
            if tf.fn != null && p_text_eq(tf.fn.ret_struct, tp3.s) {
                used = true;
            }
            if !used && tf.fn != null && rg_tparam_used_in(tf.fn.true_body, tp3.s) {
                used = true;
            }
            if used {
                rgt_give_up(saved_err, saved_has_errors);
                rg_report_missing_targ(name, tp3.s, line, col);
                return "";
            }
        }
        tp3 = tp3.next;
    }
    str mangled = name;
    @StrNode tp2 = tf.tparams;
    while tp2 != null {
        @TArg a = p_map_find(tmap, tp2.s);
        if a != null {
            mangled = mangled + "_" + rg_targ_display(a);
        }
        tp2 = tp2.next;
    }
    rg_materialize_template_out_done = done;
    rg_materialize_template_out_new_stmts = new_stmts;
    rg_instantiate_template_call_out_done = done;
    rg_instantiate_template_call_out_new_stmts = new_stmts;
    str result = rg_materialize_template(name, mangled, tmap, line, col);
    rg_instantiate_template_call_out_done = rg_materialize_template_out_done;
    rg_instantiate_template_call_out_new_stmts = rg_materialize_template_out_new_stmts;
    return result;
}

!!! Whether any entry of a flag chain is set.
bool rgt_bool_any -> @BoolNode head {
    @BoolNode e = head;
    while e != null {
        if e.v {
            return true;
        }
        e = e.next;
    }
    return false;
}

!!! The type argument one call argument gives: a struct value names its own type,
!!! any other value its type. False when the argument has no usable type (an `any`,
!!! a `void` or a function object), which leaves the call unresolved.
bool rg_targ_from_arg -> @ExprNode arg, @TArg out {
    if arg == null || !rg_resolve_expr_type(arg) {
        return false;
    }
    if arg.struct_type != "" {
        out.ty = INT;
        out.struct_name = arg.struct_type;
        return true;
    }
    VarType t = rg_deref_of(arg.result_type);
    if t == ANY || t == VOID || t == FUNC {
        return false;
    }
    out.ty = t;
    return true;
}

!!! Whether a body or an expression names `name`: an unbound type parameter the
!!! instantiation never mentions does not have to be given.
bool rg_tparam_used_in -> @StmtNode body, str name {
    @StmtNode s = body;
    while s != null {
        if rg_tparam_used_in_expr(s.expr, name) {
            return true;
        }
        if rg_tparam_used_in_expr(s.array_len_expr, name) {
            return true;
        }
        @ExprNode a = s.args;
        while a != null {
            if rg_tparam_used_in_expr(a, name) {
                return true;
            }
            a = a.next;
        }
        @ExprNode ai = s.array_init;
        while ai != null {
            if rg_tparam_used_in_expr(ai, name) {
                return true;
            }
            ai = ai.next;
        }
        @ExprNode asi = s.assign_indices;
        while asi != null {
            if rg_tparam_used_in_expr(asi, name) {
                return true;
            }
            asi = asi.next;
        }
        @ExprNode ce = s.case_exprs;
        while ce != null {
            if rg_tparam_used_in_expr(ce, name) {
                return true;
            }
            ce = ce.next;
        }
        if rg_tparam_used_in(s.true_body, name) || rg_tparam_used_in(s.false_body, name) ||
           rg_tparam_used_in(s.case_bodies, name) || rg_tparam_used_in(s.unmatch_body, name) {
            return true;
        }
        s = s.next;
    }
    return false;
}

bool rg_tparam_used_in_expr -> @ExprNode n, str name {
    if n == null {
        return false;
    }
    if n.nk == VAR_REF || n.nk == ARRAY_ACCESS || n.nk == COUNT || n.nk == FOLD {
        if p_text_eq(n.var_name, name) {
            return true;
        }
    }
    if n.nk == CAST && p_text_eq(n.cast_type_param, name) {
        return true;
    }
    if rg_tparam_used_in_expr(n.left, name) || rg_tparam_used_in_expr(n.right, name) {
        return true;
    }
    @ExprNode a = n.args;
    while a != null {
        if rg_tparam_used_in_expr(a, name) {
            return true;
        }
        a = a.next;
    }
    @ExprNode ix = n.indices;
    while ix != null {
        if rg_tparam_used_in_expr(ix, name) {
            return true;
        }
        ix = ix.next;
    }
    if n.nk == LAMBDA {
        @LambdaRec rec = p_find_lambda(n.lambda_id);
        if rec != null {
            @ExprNode ia = rec.immediate_args;
            while ia != null {
                if rg_tparam_used_in_expr(ia, name) {
                    return true;
                }
                ia = ia.next;
            }
            if rg_tparam_used_in(rec.body, name) {
                return true;
            }
        }
    }
    return false;
}

!!! One operand of a fold: a reference to the parameter a pack element became.
@ExprNode rg_pack_var_ref -> str name, @ExprNode from {
    @ExprNode v = p_new_expr(VAR_REF);
    v.line = from.line;
    v.col = from.col;
    v.var_name = name;
    v.tok_len = pe_len(name);
    !!! The type checker gives it its own.
    v.result_type = INT;
    return v;
}

!!! `(Pack etc op)` / `(op Pack etc)` folded into one expression: the elements in
!!! order, combined with `op` from the end the operator was written on.
@ExprNode rg_pack_fold -> str op, @StrNode names, bool right, @ExprNode from {
    @ExprNode built = null;
    int n = rgt_str_n(names);
    if right {
        !!! From the last element back: `a0 op (a1 op (a2 op ...))`, so each step
        !!! puts the element it reached on the left of what is already built.
        int i = n - 1;
        while i >= 0 {
            @StrNode ne = rgt_str_at(names, i);
            @ExprNode v = rg_pack_var_ref(ne.s, from);
            if built == null {
                built = v;
            } else {
                @ExprNode b = p_new_expr(BINOP);
                b.line = from.line;
                b.col = from.col;
                b.op = op;
                b.left = v;
                b.right = built;
                built = b;
            }
            i = i - 1;
        }
        return built;
    }
    int j = 0;
    while j < n {
        @StrNode ne2 = rgt_str_at(names, j);
        @ExprNode v2 = rg_pack_var_ref(ne2.s, from);
        if built == null {
            built = v2;
        } else {
            @ExprNode b2 = p_new_expr(BINOP);
            b2.line = from.line;
            b2.col = from.col;
            b2.op = op;
            b2.left = built;
            b2.right = v2;
            built = b2;
        }
        j = j + 1;
    }
    return built;
}

!!! `f(Pack etc)`: the one spread argument becomes one argument per element.
@ExprNode rg_expand_pack_args -> @ExprNode head, str pack, @StrNode names {
    @ExprNode a = head;
    bool spread = false;
    while a != null {
        if a.spread && a.nk == VAR_REF && p_text_eq(a.var_name, pack) {
            spread = true;
        }
        a = a.next;
    }
    if !spread {
        return head;
    }
    @ExprNode out = null;
    a = head;
    while a != null {
        @ExprNode nx = a.next;
        if a.spread && a.nk == VAR_REF && p_text_eq(a.var_name, pack) {
            @StrNode e = names;
            while e != null {
                out = p_chain_expr(out, rg_pack_var_ref(e.s, a));
                e = e.next;
            }
        } else {
            a.next = null;
            out = p_chain_expr(out, a);
        }
        a = nx;
    }
    return out;
}

!!! Expand every expression of a chain that the pack stands in for: the fold
!!! becomes the operator chain, `count` the number of elements, `Pack[i]` the i-th
!!! parameter and a spread argument one argument per element.
@ExprNode rg_expand_pack_chain -> @ExprNode head, str pack, @StrNode names,
                                  int line, int col {
    !!! The rebuilt list is answered in `out`, the loop's own accumulator, so the
    !!! parameter is only read.
    @ExprNode out = null;
    @ExprNode a = head;
    @ExprNode prev = null;
    while a != null {
        @ExprNode nx = a.next;
        @ExprNode ra = rg_expand_pack_expr(a, pack, names, line, col);
        if ra != null {
            ra.next = nx;
        }
        if prev == null {
            out = ra;
        } else {
            prev.next = ra;
        }
        if ra != null {
            prev = ra;
        }
        a = nx;
    }
    return out;
}

@ExprNode rg_expand_pack_expr -> @ExprNode n, str pack, @StrNode names, int line, int col {
    if n == null {
        return null;
    }
    if n.nk == FOLD && p_text_eq(n.var_name, pack) {
        if names == null {
            str msg = "cannot fold the empty pack '" + pack + "'";
            rg_fmt_err(line, col, msg, pe_len(pack), (str)null, 0, true);
            rg_has_errors = true;
            return null;
        }
        return rg_pack_fold(n.op, names, n.fold_right, n);
    }
    if n.nk == COUNT && p_text_eq(n.var_name, pack) {
        n.nk = LIT_INT;
        n.int_val = (longlong)rgt_str_n(names);
        n.lit_is_long = false;
        n.count_folded = true;
        n.result_type = INT;
        return n;
    }
    if n.nk == ARRAY_ACCESS && p_text_eq(n.var_name, pack) {
        !!! `Pack[i]`: the element the index names, which has to be a constant. The
        !!! index is expanded first so `Pack[count Pack - 1]` works: the `count
        !!! Pack` inside it folds to a literal before it is evaluated.
        n.left = rg_expand_pack_expr(n.left, pack, names, line, col);
        n.indices = rg_expand_pack_chain(n.indices, pack, names, line, col);
        @ExprNode in = n.indices;
        if in == null {
            in = n.left;
        }
        p_eval_const_int(in);
        longlong idx = p_eval_value;
        if !p_const_ok || idx < 0 || idx >= (longlong)rgt_str_n(names) {
            str msg2 = "the index of pack '" + pack + "' must be a constant inside the pack";
            rg_fmt_err(line, col, msg2, pe_len(pack), (str)null, 0, true);
            rg_has_errors = true;
            return null;
        }
        @StrNode elem = rgt_str_at(names, (int)idx);
        return rg_pack_var_ref(elem.s, n);
    }
    !!! `f(Pack etc)`: one argument per element.
    n.args = rg_expand_pack_args(n.args, pack, names);
    n.left = rg_expand_pack_expr(n.left, pack, names, line, col);
    n.right = rg_expand_pack_expr(n.right, pack, names, line, col);
    n.args = rg_expand_pack_chain(n.args, pack, names, line, col);
    n.indices = rg_expand_pack_chain(n.indices, pack, names, line, col);
    if n.nk == VAR_REF && p_text_eq(n.var_name, pack) {
        str msg3 = "the pack '" + pack + "' cannot be used as a value; fold or index it";
        rg_fmt_err(line, col, msg3, pe_len(pack), (str)null, 0, true);
        rg_has_errors = true;
    }
    return n;
}

void rg_expand_pack_stmt -> @StmtNode body, str pack, @StrNode names, int line, int col {
    @StmtNode s = body;
    while s != null {
        s.expr = rg_expand_pack_expr(s.expr, pack, names, line, col);
        s.array_len_expr = rg_expand_pack_expr(s.array_len_expr, pack, names, line, col);
        !!! A call statement spreads the pack the way an expression does.
        s.args = rg_expand_pack_args(s.args, pack, names);
        s.args = rg_expand_pack_chain(s.args, pack, names, line, col);
        s.array_init = rg_expand_pack_chain(s.array_init, pack, names, line, col);
        s.assign_indices = rg_expand_pack_chain(s.assign_indices, pack, names, line, col);
        s.case_exprs = rg_expand_pack_chain(s.case_exprs, pack, names, line, col);
        rg_expand_pack_stmt(s.true_body, pack, names, line, col);
        rg_expand_pack_stmt(s.false_body, pack, names, line, col);
        rg_expand_pack_stmt(s.case_bodies, pack, names, line, col);
        rg_expand_pack_stmt(s.unmatch_body, pack, names, line, col);
        s = s.next;
    }
}

!!! Build the parameter list of one instantiated template function from its type
!!! pack (`-> (Y etc) (Args etc)`) and rewrite the body so the argument pack stands
!!! for those parameters.
void rg_expand_pack_params -> @StmtNode inst, @TArgMap tmap, int line, int col {
    @TArg pit = p_map_find(tmap, inst.pack_ptypes);
    if pit == null || !pit.is_pack {
        str msg = "template '" + rg_display_name(inst.var_name) + "' has no type pack '" +
                  inst.pack_ptypes + "'";
        rg_fmt_err(line, col, msg, pe_len(inst.pack_ptypes), (str)null, 0, true);
        rg_has_errors = true;
        end;
    }
    @StrNode names = null;
    @TArg e = pit.pack;
    int i = 0;
    while e != null {
        str pn = "__pa" + (str)i;
        names = rg_strchain_append(names, pn);
        inst.fparams = p_chain_str(inst.fparams, p_new_name(pn, line, col));
        inst.fparam_types = p_chain_type(inst.fparam_types, p_new_type(e.ty));
        inst.fparam_struct = p_chain_str(inst.fparam_struct, p_new_name(e.struct_name, line, col));
        inst.fparam_is_array = p_chain_bool(inst.fparam_is_array, p_new_bool(false));
        inst.fparam_is_ref = p_chain_bool(inst.fparam_is_ref, p_new_bool(false));
        inst.fparam_is_const = p_chain_bool(inst.fparam_is_const, p_new_bool(false));
        inst.fparam_is_static = p_chain_bool(inst.fparam_is_static, p_new_bool(false));
        inst.fparam_is_unsigned = p_chain_bool(inst.fparam_is_unsigned, p_new_bool(false));
        inst.fparam_has_default = p_chain_bool(inst.fparam_has_default, p_new_bool(false));
        inst.nfparams = inst.nfparams + 1;
        e = e.next_pack;
        i = i + 1;
    }
    rg_expand_pack_stmt(inst.true_body, inst.pack_pnames, names, line, col);
}

int rgt_expr_count -> @ExprNode head {
    int n = 0;
    @ExprNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

!!! Name used to mangle an instantiation: "int" for builtins, the struct name for a
!!! struct argument, an identifier-safe encoding of the value for a non-type
!!! argument, and "tt_<name>" for a template-template argument.
str rg_targ_display -> @TArg a {
    return p_targ_ident(a);
}

void rg_report_missing_targ -> str name, str tparam, int line, int col {
    str key = (str)line + ":" + (str)col + ":" + name;
    if rg_set_has(rg_deduce_reported, key) {
        end;
    }
    rg_deduce_reported = rg_set_add(rg_deduce_reported, key);
    str msg = "cannot deduce type argument '" + tparam + "' of template '" + name + "'";
    rg_fmt_err(line, col, msg, pe_len(name), (str)null, 0, true);
    rg_has_errors = true;
}

!!! The name a diagnostic should show: an instantiated template is stored under its
!!! mangled name (`add_int`) and a package member under `<pkg>__<name>`, but the user
!!! only ever wrote `add` / `pkg::name`.
str rg_display_name -> str name {
    @RgStrMap it = rg_strmap_find(rg_display_names, name);
    if it != null {
        return it.v;
    }
    return name;
}

!!! The template has a non-type parameter, which can only come from an explicit
!!! `name(<value>)(...)` instantiation.
void rg_report_value_needed -> str name, str tparam, int line, int col {
    str key = "v:" + (str)line + ":" + (str)col + ":" + name;
    if rg_set_has(rg_deduce_reported, key) {
        end;
    }
    rg_deduce_reported = rg_set_add(rg_deduce_reported, key);
    str msg = "template '" + name + "' needs a value for parameter '" + tparam +
              "'; write " + name + "(<value>)(...) to give it";
    rg_fmt_err(line, col, msg, pe_len(name), (str)null, 0, true);
    rg_has_errors = true;
}

!!! Rename `from` into `to` everywhere a variable can be referenced. A DECLARE that
!!! redeclares the name is left alone on purpose (it is a different variable).
void rg_rename_var_expr -> @ExprNode n, str from, str to {
    if n == null {
        end;
    }
    !!! ARRAY_ACCESS keeps the array name in var_name as well (`a[0]`).
    if (n.nk == VAR_REF || n.nk == ARRAY_ACCESS) && p_text_eq(n.var_name, from) {
        n.var_name = to;
    }
    rg_rename_var_expr(n.left, from, to);
    rg_rename_var_expr(n.right, from, to);
    @ExprNode a = n.args;
    while a != null {
        rg_rename_var_expr(a, from, to);
        a = a.next;
    }
    @ExprNode ix = n.indices;
    while ix != null {
        rg_rename_var_expr(ix, from, to);
        ix = ix.next;
    }
    if n.nk == LAMBDA {
        @LambdaRec rec = p_find_lambda(n.lambda_id);
        if rec != null {
            @ExprNode ia = rec.immediate_args;
            while ia != null {
                rg_rename_var_expr(ia, from, to);
                ia = ia.next;
            }
            rg_rename_var_stmts(rec.body, from, to);
        }
    }
}

void rg_rename_var_stmts -> @StmtNode body, str from, str to {
    @StmtNode s = body;
    while s != null {
        if s.nk != DECLARE && p_text_eq(s.var_name, from) {
            s.var_name = to;
        }
        rg_rename_var_expr(s.expr, from, to);
        rg_rename_var_expr(s.array_len_expr, from, to);
        @ExprNode a = s.args;
        while a != null {
            rg_rename_var_expr(a, from, to);
            a = a.next;
        }
        @ExprNode ai = s.array_init;
        while ai != null {
            rg_rename_var_expr(ai, from, to);
            ai = ai.next;
        }
        @ExprNode asi = s.assign_indices;
        while asi != null {
            rg_rename_var_expr(asi, from, to);
            asi = asi.next;
        }
        @ExprNode ce = s.case_exprs;
        while ce != null {
            rg_rename_var_expr(ce, from, to);
            ce = ce.next;
        }
        !!! `true_body` is the `true_body` and the `children` at once.
        rg_rename_var_stmts(s.true_body, from, to);
        rg_rename_var_stmts(s.false_body, from, to);
        rg_rename_var_stmts(s.case_bodies, from, to);
        rg_rename_var_stmts(s.unmatch_body, from, to);
        s = s.next;
    }
}

void rg_collect_declare_names -> @StmtNode body {
    @StrNode out = rg_collect_declare_names_out;
    @StmtNode s = body;
    while s != null {
        if s.nk == DECLARE && s.var_name != "" {
            out = rg_strchain_append(out, s.var_name);
        }
        rg_collect_declare_names_out = out;
        rg_collect_declare_names(s.true_body);
        rg_collect_declare_names(s.false_body);
        rg_collect_declare_names(s.case_bodies);
        rg_collect_declare_names(s.unmatch_body);
        out = rg_collect_declare_names_out;
        s = s.next;
    }
    rg_collect_declare_names_out = out;
}

void rg_rename_declared_local -> @StmtNode body, str from, str to {
    @StmtNode s = body;
    while s != null {
        if s.nk == DECLARE && p_text_eq(s.var_name, from) {
            s.var_name = to;
        }
        !!! `true_body` is the `true_body` and the `children` at once; the
        !!! sibling chain is walked here, not by a recursive call.
        rg_rename_declared_local(s.true_body, from, to);
        rg_rename_declared_local(s.false_body, from, to);
        rg_rename_declared_local(s.case_bodies, from, to);
        rg_rename_declared_local(s.unmatch_body, from, to);
        s = s.next;
    }
    !!! The references are renamed after the declarations of the whole body, which is
    !!! what keeps a declaration from being renamed twice.
    rg_rename_var_stmts(body, from, to);
}

!!! Build (once) the hidden function of one instantiation and register it under its
!!! mangled name. Shared by the deduced and the explicitly typed calls.
str rg_materialize_template -> str name, str mangled, @TArgMap tmap, int line, int col {
    @TemplateFunc tf = p_find_template_func(name);
    if tf == null {
        return "";
    }
    @RgStrSet done = rg_materialize_template_out_done;
    if !rg_set_has(done, mangled) {
        done = rg_set_add(done, mangled);
        rg_materialize_template_out_done = done;
        rg_instantiated_templates = rg_set_add(rg_instantiated_templates, name);
        @StmtNode inst = p_clone_stmt(tf.fn, tmap);
        inst.var_name = mangled;
        inst.is_local = true;
        !!! A pack parameter list (`-> (Y etc) (Args etc)`) is built here: one
        !!! parameter per element of the instantiated type pack, and the body is
        !!! rewritten to reach them through the argument pack.
        if inst.params_from_pack {
            rg_expand_pack_params(inst, tmap, line, col);
        }
        int nfp = rgt_str_n(inst.fparams);
        rg_func_arity = rg_intmap_set(rg_func_arity, mangled, nfp);
        rg_display_names = rg_strmap_set(rg_display_names, mangled, name);
        rg_func_param_types = rg_vartypelistmap_set(rg_func_param_types, mangled, inst.fparam_types,
                                                    rgt_vt_n(inst.fparam_types));
        rg_func_param_struct = rg_strlistmap_set(rg_func_param_struct, mangled, inst.fparam_struct,
                                                 rgt_str_n(inst.fparam_struct));
        rg_func_param_is_array = rg_boollistmap_set(rg_func_param_is_array, mangled,
                                                    inst.fparam_is_array,
                                                    rgt_bool_n(inst.fparam_is_array));
        rg_func_param_is_ref = rg_boollistmap_set(rg_func_param_is_ref, mangled,
                                                  inst.fparam_is_ref,
                                                  rgt_bool_n(inst.fparam_is_ref));
        rg_func_param_is_unsigned = rg_boollistmap_set(rg_func_param_is_unsigned, mangled,
                                                       inst.fparam_is_unsigned,
                                                       rgt_bool_n(inst.fparam_is_unsigned));
        rg_func_ret_is_unsigned = rg_boolmap_set(rg_func_ret_is_unsigned, mangled,
                                                 inst.ret_is_unsigned);
        rg_func_variadic = rg_boolmap_set(rg_func_variadic, mangled, inst.variadic);
        rg_func_ret_struct = rg_strmap_set(rg_func_ret_struct, mangled, inst.ret_struct);
        !!! Callers may use the source parameter names, so those are kept here even
        !!! though the body is renamed below.
        rg_func_param_names = rg_strlistmap_set(rg_func_param_names, mangled, inst.fparams, nfp);
        !!! Hygiene: during type checking every function's parameters share one global
        !!! symbol table, so an instantiated parameter named like a user variable
        !!! would shadow it. They are given unique names.
        int pi = 0;
        while pi < nfp {
            @StrNode pn = rgt_str_at(inst.fparams, pi);
            str to = "__tp_" + mangled + "_" + pn.s;
            if !p_text_eq(pn.s, to) {
                rg_rename_var_stmts(inst.true_body, pn.s, to);
                !!! A diagnostic about this parameter names what the user wrote, not
                !!! the hidden name hygiene gave it.
                rg_display_names = rg_strmap_set(rg_display_names, to, pn.s);
                rgt_str_set(inst.fparams, pi, to);
            }
            pi = pi + 1;
        }
        !!! Locals have the same problem: every instantiation registers its
        !!! declarations in one shared symbol table, so two clones declaring `T tmp;`
        !!! would share a single entry. The declared names of this clone get a unique
        !!! prefix as well.
        rg_collect_declare_names_out = null;
        rg_collect_declare_names(inst.true_body);
        @StrNode loc = rg_collect_declare_names_out;
        while loc != null {
            str lname = loc.s;
            str to2 = "__tl_" + mangled + "_" + lname;
            if !p_text_eq(lname, to2) {
                rg_rename_declared_local(inst.true_body, lname, to2);
                rg_display_names = rg_strmap_set(rg_display_names, to2, lname);
            }
            loc = loc.next;
        }
        !!! The return type is registered so call expressions resolve it (like the
        !!! FUNCTION pass does with syms[funcname] = func_ret_type).
        if rg_vartypemap_find(rg_syms, mangled) == null {
            rg_syms = rg_vartypemap_set(rg_syms, mangled, inst.func_ret_type);
        }
        !!! Parameters are registered in syms (like the FUNCTION pass does) so the
        !!! instantiated body can resolve its own parameters.
        rg_push_func_params(inst);
        int pi2 = 0;
        while pi2 < nfp {
            @StrNode p2 = rgt_str_at(inst.fparams, pi2);
            rg_non_global_syms = rg_set_add(rg_non_global_syms, p2.s);
            if rgt_bool_at(inst.fparam_is_array, pi2) {
                rg_sym_is_array = rg_boolmap_set(rg_sym_is_array, p2.s, true);
            }
            pi2 = pi2 + 1;
        }
        !!! The local DECLARE variables are registered (like the first pass does) so
        !!! the instantiated body can resolve them.
        rg_register_declare_locals(inst, mangled);
        @StmtNode ns = rg_materialize_template_out_new_stmts;
        @StmtNode nx = inst.next;
        inst.next = null;
        rg_materialize_template_out_new_stmts = p_chain_stmt(ns, inst);
    }
    return mangled;
}

!!! Write `to` into entry `i` of a chain of names. A chain node cannot be replaced
!!! in place through a local, so the text of the node that stands there is written.
void rgt_str_set -> @StrNode head, int i, str to {
    int k = 0;
    @StrNode e = head;
    while e != null {
        if k == i {
            e.s = to;
            end;
        }
        k = k + 1;
        e = e.next;
    }
}

!!! `name(T1, T2)(args)`: the type arguments are written at the call site instead of
!!! being deduced from the argument types. This is what makes a template usable when
!!! a parameter does not mention the type parameter at all.
str rg_instantiate_template_explicit -> str name, @VarTypeNode targs, @StrNode targ_structs,
                                       @ExprNode targ_exprs, @BoolNode targ_is_value,
                                       @ExprNode call_args,
                                       int line, int col {
    @TemplateFunc tf = p_find_template_func(name);
    if tf == null {
        return "";
    }
    int nt = rgt_str_n(tf.tparams);
    @RgStrSet done = rg_instantiate_template_explicit_out_done;
    @TArgMap tmap = null;
    str mangled = name;
    !!! The explicit type arguments are matched to the declared parameters in order;
    !!! a pack takes every one that is left.
    int ti = 0;
    int i = 0;
    while i < nt {
        @StrNode tp = rgt_str_at(tf.tparams, i);
        bool want_value = rgt_bool_at(tf.tparam_is_value, i);
        bool is_pack = rgt_bool_at(tf.tparam_is_pack, i);
        @TArg ta = p_new_arg();
        if want_value {
            bool got_value = rgt_bool_at(targ_is_value, ti);
            if !got_value {
                str msg = "template '" + name + "' needs a value for parameter '" + tp.s + "'";
                rg_fmt_err(line, col, msg, pe_len(name), (str)null, 0, true);
                rg_has_errors = true;
                return "";
            }
            VarType want = INT;
            if i < rgt_vt_n(tf.tparam_types) {
                want = rgt_vt_at(tf.tparam_types, i);
            }
            @ExprNode ve = rgt_expr_at(targ_exprs, ti);
            p_eval_const_arg(ve, want);
            if !p_arg_ok {
                int el = line;
                int ec = col;
                int hlen = pe_len(name);
                if ve != null {
                    el = ve.line;
                    ec = ve.col;
                    hlen = ve.tok_len;
                }
                str msg2 = "value for parameter '" + tp.s + "' must be a constant " +
                           rg_type_name(want) + " expression";
                rg_fmt_err(el, ec, msg2, hlen, (str)null, 0, true);
                rg_has_errors = true;
                return "";
            }
            ta = p_arg_out;
            ti = ti + 1;
        } else if is_pack {
            !!! `add(int, int, int)(1, 2, 3)`: the pack takes the type arguments that
            !!! are left...
            ta.is_pack = true;
            while ti < rgt_vt_n(targs) {
                @TArg e = p_new_arg();
                e.ty = rgt_vt_at(targs, ti);
                @StrNode ts0 = rgt_str_at(targ_structs, ti);
                if ts0 != null {
                    e.struct_name = ts0.s;
                }
                ta.pack = p_chain_pack_targ(ta.pack, e);
                ti = ti + 1;
            }
            !!! ...and the arguments the type list does not cover give the rest of
            !!! the parameter types (`add(int)(1, 2, 3)`).
            @ExprNode ca = rgt_expr_at(call_args, rgt_targ_n(ta.pack));
            while ca != null {
                @TArg e2 = p_new_arg();
                if !rg_targ_from_arg(ca, e2) {
                    return "";
                }
                ta.pack = p_chain_pack_targ(ta.pack, e2);
                ca = ca.next;
            }
        } else {
            if ti >= rgt_vt_n(targs) {
                !!! No type left for this parameter. It cannot be deduced from the
                !!! arguments, so the call has to write it: `add(int, int)(1, 2)`.
                str msg5 = "template '" + name + "' needs a type for parameter '" + tp.s + "'";
                rg_fmt_err(line, col, msg5, pe_len(name), (str)null, 0, true);
                rg_has_errors = true;
                return "";
            }
            bool got_value2 = rgt_bool_at(targ_is_value, ti);
            if got_value2 {
                str msg3 = "template '" + name + "' needs a type for parameter '" + tp.s + "'";
                rg_fmt_err(line, col, msg3, pe_len(name), (str)null, 0, true);
                rg_has_errors = true;
                return "";
            }
            bool want_tmpl = rgt_bool_at(tf.tparam_is_template, i);
            ta.ty = rgt_vt_at(targs, ti);
            !!! `add(Person)(...)`: the argument is the struct name, carried in the
            !!! struct slot so the clone can substitute it into field types.
            @StrNode ts = rgt_str_at(targ_structs, ti);
            if ts != null {
                ta.struct_name = ts.s;
            }
            if want_tmpl {
                !!! `wrap(Box)(...)`: the argument names another template, used as
                !!! `C(int)` inside the body.
                if ta.struct_name == "" {
                    str msg4 = "template '" + name + "' needs a template name for parameter '" +
                               tp.s + "'";
                    rg_fmt_err(line, col, msg4, pe_len(name), (str)null, 0, true);
                    rg_has_errors = true;
                    return "";
                }
                ta.is_template = true;
                ta.tname = ta.struct_name;
                ta.struct_name = "";
            }
            ti = ti + 1;
        }
        tmap = p_map_add(tmap, tp.s, ta);
        mangled = mangled + "_" + rg_targ_display(ta);
        i = i + 1;
    }
    if ti != rgt_vt_n(targs) {
        str msg6 = "template '" + name + "' needs " + (str)ti + " type argument(s), got " +
                   (str)rgt_vt_n(targs);
        rg_fmt_err(line, col, msg6, pe_len(name), (str)null, 0, true);
        rg_has_errors = true;
        return "";
    }
    rg_materialize_template_out_done = done;
    rg_materialize_template_out_new_stmts = rg_instantiate_template_explicit_out_new_stmts;
    str result = rg_materialize_template(name, mangled, tmap, line, col);
    rg_instantiate_template_explicit_out_done = rg_materialize_template_out_done;
    rg_instantiate_template_explicit_out_new_stmts = rg_materialize_template_out_new_stmts;
    return result;
}

!!! The number of elements of a pack binding.
int rgt_targ_n -> @TArg head {
    int n = 0;
    @TArg e = head;
    while e != null {
        n = n + 1;
        e = e.next_pack;
    }
    return n;
}

void rg_instantiate_expr -> @ExprNode n {
    if n == null {
        end;
    }
    @RgStrSet done = rg_instantiate_expr_out_done;
    @StmtNode new_stmts = rg_instantiate_expr_out_new_stmts;
    !!! Children first: a template call deduces its type parameters from the types of
    !!! its arguments, so a nested template call in an argument has to be renamed and
    !!! registered before the enclosing call probes it.
    rg_instantiate_expr_out_done = done;
    rg_instantiate_expr_out_new_stmts = new_stmts;
    rg_instantiate_expr(n.left);
    done = rg_instantiate_expr_out_done;
    new_stmts = rg_instantiate_expr_out_new_stmts;
    rg_instantiate_expr_out_done = done;
    rg_instantiate_expr_out_new_stmts = new_stmts;
    rg_instantiate_expr(n.right);
    done = rg_instantiate_expr_out_done;
    new_stmts = rg_instantiate_expr_out_new_stmts;
    @ExprNode a = n.args;
    while a != null {
        rg_instantiate_expr_out_done = done;
        rg_instantiate_expr_out_new_stmts = new_stmts;
        rg_instantiate_expr(a);
        done = rg_instantiate_expr_out_done;
        new_stmts = rg_instantiate_expr_out_new_stmts;
        a = a.next;
    }
    @ExprNode ix = n.indices;
    while ix != null {
        rg_instantiate_expr_out_done = done;
        rg_instantiate_expr_out_new_stmts = new_stmts;
        rg_instantiate_expr(ix);
        done = rg_instantiate_expr_out_done;
        new_stmts = rg_instantiate_expr_out_new_stmts;
        ix = ix.next;
    }
    if n.nk == LAMBDA {
        @LambdaRec rec = p_find_lambda(n.lambda_id);
        if rec != null {
            @StmtNode lb = rec.body;
            while lb != null {
                rg_instantiate_stmt_out_done = done;
                rg_instantiate_stmt_out_new_stmts = new_stmts;
                rg_instantiate_stmt(lb);
                done = rg_instantiate_stmt_out_done;
                new_stmts = rg_instantiate_stmt_out_new_stmts;
                lb = lb.next;
            }
            @ExprNode ia = rec.immediate_args;
            while ia != null {
                rg_instantiate_expr_out_done = done;
                rg_instantiate_expr_out_new_stmts = new_stmts;
                rg_instantiate_expr(ia);
                done = rg_instantiate_expr_out_done;
                new_stmts = rg_instantiate_expr_out_new_stmts;
                ia = ia.next;
            }
        }
    }
    rg_instantiate_expr_out_done = done;
    rg_instantiate_expr_out_new_stmts = new_stmts;
    if n.nk == FUNC_CALL && n.targs != null {
        !!! Explicit `name(T)(args)` / `name(int, 5)(args)`: bind as written.
        rg_instantiate_template_explicit_out_done = done;
        rg_instantiate_template_explicit_out_new_stmts = new_stmts;
        str m = rg_instantiate_template_explicit(n.var_name, n.targs, n.targ_structs,
                                                 n.targ_exprs, n.targ_is_value, n.args,
                                                 n.line, n.col);
        done = rg_instantiate_template_explicit_out_done;
        new_stmts = rg_instantiate_template_explicit_out_new_stmts;
        rg_instantiate_expr_out_done = done;
        rg_instantiate_expr_out_new_stmts = new_stmts;
        if m != "" {
            n.var_name = m;
            n.targs = null;
            n.targ_structs = null;
            n.targ_exprs = null;
            n.targ_is_value = null;
        }
        end;
    }
    if n.nk == FUNC_CALL && p_find_template_func(n.var_name) != null {
        rg_instantiate_template_call_out_done = done;
        rg_instantiate_template_call_out_new_stmts = new_stmts;
        str m2 = rg_instantiate_template_call(n.var_name, n.args, n.line, n.col);
        done = rg_instantiate_template_call_out_done;
        new_stmts = rg_instantiate_template_call_out_new_stmts;
        rg_instantiate_expr_out_done = done;
        rg_instantiate_expr_out_new_stmts = new_stmts;
        if m2 != "" {
            n.var_name = m2;
        }
    }
}

void rg_instantiate_stmt -> @StmtNode s {
    if s == null {
        end;
    }
    @RgStrSet done = rg_instantiate_stmt_out_done;
    @StmtNode new_stmts = rg_instantiate_stmt_out_new_stmts;
    !!! Children first, for the same reason as rg_instantiate_expr.
    rg_instantiate_expr_out_done = done;
    rg_instantiate_expr_out_new_stmts = new_stmts;
    rg_instantiate_expr(s.expr);
    done = rg_instantiate_expr_out_done;
    new_stmts = rg_instantiate_expr_out_new_stmts;
    @ExprNode a = s.args;
    while a != null {
        rg_instantiate_expr_out_done = done;
        rg_instantiate_expr_out_new_stmts = new_stmts;
        rg_instantiate_expr(a);
        done = rg_instantiate_expr_out_done;
        new_stmts = rg_instantiate_expr_out_new_stmts;
        a = a.next;
    }
    @ExprNode ai = s.array_init;
    while ai != null {
        rg_instantiate_expr_out_done = done;
        rg_instantiate_expr_out_new_stmts = new_stmts;
        rg_instantiate_expr(ai);
        done = rg_instantiate_expr_out_done;
        new_stmts = rg_instantiate_expr_out_new_stmts;
        ai = ai.next;
    }
    @ExprNode asi = s.assign_indices;
    while asi != null {
        rg_instantiate_expr_out_done = done;
        rg_instantiate_expr_out_new_stmts = new_stmts;
        rg_instantiate_expr(asi);
        done = rg_instantiate_expr_out_done;
        new_stmts = rg_instantiate_expr_out_new_stmts;
        asi = asi.next;
    }
    @ExprNode ce = s.case_exprs;
    while ce != null {
        rg_instantiate_expr_out_done = done;
        rg_instantiate_expr_out_new_stmts = new_stmts;
        rg_instantiate_expr(ce);
        done = rg_instantiate_expr_out_done;
        new_stmts = rg_instantiate_expr_out_new_stmts;
        ce = ce.next;
    }
    rg_instantiate_expr_out_done = done;
    rg_instantiate_expr_out_new_stmts = new_stmts;
    rg_instantiate_expr(s.array_len_expr);
    done = rg_instantiate_expr_out_done;
    new_stmts = rg_instantiate_expr_out_new_stmts;
    int line = s.var_line;
    if line == 0 {
        line = s.line;
    }
    int col = s.var_col;
    if col == 0 {
        col = s.col;
    }
    if s.nk == CALL_FUNC && s.targs != null {
        !!! Explicit `name(T)(args)` / `name(int, 5)(args)` used as a statement.
        rg_instantiate_template_explicit_out_done = done;
        rg_instantiate_template_explicit_out_new_stmts = new_stmts;
        str m = rg_instantiate_template_explicit(s.var_name, rgt_vt_of_targs(s.targs), s.targ_structs,
                                                 s.targ_exprs, s.targ_is_value, s.args,
                                                 line, col);
        done = rg_instantiate_template_explicit_out_done;
        new_stmts = rg_instantiate_template_explicit_out_new_stmts;
        if m != "" {
            s.var_name = m;
            s.targs = null;
            s.targ_structs = null;
            s.targ_exprs = null;
            s.targ_is_value = null;
        }
    } else if s.nk == CALL_FUNC && p_find_template_func(s.var_name) != null {
        rg_instantiate_template_call_out_done = done;
        rg_instantiate_template_call_out_new_stmts = new_stmts;
        str m2 = rg_instantiate_template_call(s.var_name, s.args, line, col);
        done = rg_instantiate_template_call_out_done;
        new_stmts = rg_instantiate_template_call_out_new_stmts;
        if m2 != "" {
            s.var_name = m2;
        }
    }
    !!! `true_body` is the `true_body` and the `children` at once.
    @StmtNode ss = s.true_body;
    while ss != null {
        rg_instantiate_stmt_out_done = done;
        rg_instantiate_stmt_out_new_stmts = new_stmts;
        rg_instantiate_stmt(ss);
        done = rg_instantiate_stmt_out_done;
        new_stmts = rg_instantiate_stmt_out_new_stmts;
        ss = ss.next;
    }
    @StmtNode fb = s.false_body;
    while fb != null {
        rg_instantiate_stmt_out_done = done;
        rg_instantiate_stmt_out_new_stmts = new_stmts;
        rg_instantiate_stmt(fb);
        done = rg_instantiate_stmt_out_done;
        new_stmts = rg_instantiate_stmt_out_new_stmts;
        fb = fb.next;
    }
    @StmtNode cb = s.case_bodies;
    while cb != null {
        rg_instantiate_stmt_out_done = done;
        rg_instantiate_stmt_out_new_stmts = new_stmts;
        rg_instantiate_stmt(cb);
        done = rg_instantiate_stmt_out_done;
        new_stmts = rg_instantiate_stmt_out_new_stmts;
        cb = cb.next;
    }
    @StmtNode ub = s.unmatch_body;
    while ub != null {
        rg_instantiate_stmt_out_done = done;
        rg_instantiate_stmt_out_new_stmts = new_stmts;
        rg_instantiate_stmt(ub);
        done = rg_instantiate_stmt_out_done;
        new_stmts = rg_instantiate_stmt_out_new_stmts;
        ub = ub.next;
    }
    rg_instantiate_stmt_out_done = done;
    rg_instantiate_stmt_out_new_stmts = new_stmts;
}

void rg_register_declare_locals -> @StmtNode s, str scope {
    if s == null {
        end;
    }
    if s.nk == DECLARE {
        if rg_vartypemap_find(rg_syms, s.var_name) == null {
            rg_syms = rg_vartypemap_set(rg_syms, s.var_name, s.decl_type);
            rg_sym_depth = rg_intmap_set(rg_sym_depth, s.var_name, s.ptr_depth);
            if s.struct_type != "" {
                rg_sym_struct_type = rg_strmap_set(rg_sym_struct_type, s.var_name, s.struct_type);
            }
            if s.is_array {
                rg_sym_is_array = rg_boolmap_set(rg_sym_is_array, s.var_name, true);
                if s.array_dims != null {
                    rg_sym_dims = rg_dimmap_set(rg_sym_dims, s.var_name, rgt_longchain(s.array_dims),
                                                rgt_intnode_n(s.array_dims));
                }
            }
            if s.decl_is_ref {
                rg_sym_is_ref = rg_boolmap_set(rg_sym_is_ref, s.var_name, true);
            }
        }
        if scope != "" {
            rg_non_global_syms = rg_set_add(rg_non_global_syms, s.var_name);
        }
    }
    !!! `true_body` is the `true_body` and the `children` at once.
    rg_register_declare_locals(s.true_body, scope);
    rg_register_declare_locals(s.false_body, scope);
    rg_register_declare_locals(s.case_bodies, scope);
    rg_register_declare_locals(s.unmatch_body, scope);
}

@RgLongNode rgt_longchain -> @IntNode head {
    @RgLongNode out = null;
    @IntNode e = head;
    while e != null {
        out = rg_longchain_append(out, (longlong)e.v);
        e = e.next;
    }
    return out;
}

int rgt_intnode_n -> @IntNode head {
    int n = 0;
    @IntNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

!!! The body of an instantiated generic struct is not part of the statement tree
!!! (its methods live in the StructDef), so a template call inside a method is
!!! instantiated here, with the method context that lets a template argument be
!!! deduced from a field (`twice(n)`).
void rgt_instantiate_struct_bodies -> @StructDef sd {
    str saved_var = rg_struct_method_var;
    str saved_type = rg_struct_method_type;
    @ExprNode saved_idx = rg_struct_method_idx;
    rg_struct_method_var = "__this";
    rg_struct_method_type = sd.name;
    rg_struct_method_idx = null;
    @StructMethod m = sd.methods;
    while m != null {
        if m.fn != null {
            rgt_instantiate_body(m.fn.true_body);
        }
        m = m.next;
    }
    if sd.init_func != null {
        rgt_instantiate_body(sd.init_func.true_body);
    }
    if sd.destruct_func != null {
        rgt_instantiate_body(sd.destruct_func.true_body);
    }
    rg_struct_method_var = saved_var;
    rg_struct_method_type = saved_type;
    rg_struct_method_idx = saved_idx;
}

void rgt_instantiate_body -> @StmtNode body {
    @StmtNode b = body;
    while b != null {
        rg_instantiate_stmt(b);
        b = b.next;
    }
}

!!! Instantiate every template call of the program, to a fixpoint: a cloned body may
!!! itself call a template, and the clone is placed right before the statement that
!!! first needed it (the backend resolves FUNC definitions in source order).
@StmtNode rg_instantiate_templates -> @StmtNode stmts {
    if p_template_funcs == null {
        return stmts;
    }
    @RgStrSet done = null;
    int round = 0;
    while round < 32 {
        bool any_new = false;
        @StmtNode out = null;
        @StmtNode out_tail = null;
        @StmtNode s = stmts;
        while s != null {
            @StmtNode nx = s.next;
            s.next = null;
            rg_instantiate_stmt_out_done = done;
            rg_instantiate_stmt_out_new_stmts = null;
            rg_instantiate_stmt(s);
            done = rg_instantiate_stmt_out_done;
            @StmtNode ns = rg_instantiate_stmt_out_new_stmts;
            !!! The body of an instantiated generic struct is not part of the statement
            !!! tree, so a template call inside one of its methods is instantiated
            !!! here. The clone is placed before the STRUCT_DEF, which emits the
            !!! method's own FUNC.
            if s.nk == STRUCT_DEF && rg_set_has(rg_struct_tmpl_done, s.var_name) {
                @StructDef sd = p_find_struct(s.var_name);
                if sd != null {
                    rg_instantiate_stmt_out_done = done;
                    rg_instantiate_stmt_out_new_stmts = ns;
                    rgt_instantiate_struct_bodies(sd);
                    done = rg_instantiate_stmt_out_done;
                    ns = rg_instantiate_stmt_out_new_stmts;
                }
            }
            !!! Each instantiation goes right before the statement that first needed it.
            @StmtNode n2 = ns;
            while n2 != null {
                @StmtNode nn = n2.next;
                n2.next = null;
                if out == null {
                    out = n2;
                } else {
                    out_tail.next = n2;
                }
                out_tail = n2;
                any_new = true;
                n2 = nn;
            }
            if out == null {
                out = s;
            } else {
                out_tail.next = s;
            }
            out_tail = s;
            s = nx;
        }
        stmts = out;
        if !any_new {
            skip;
        }
        round = round + 1;
    }
    return stmts;
}

!!! The names a template body may use: the type parameters, the parameters, the
!!! locals of the body, and - deliberately generously - everything the file declares,
!!! because a wrong report would reject a program that compiles today.
@RgStrSet rgt_ok;
@RgStrSet rgt_reported;

bool rgt_known -> str nm {
    if rg_set_has(rgt_ok, nm) {
        return true;
    }
    if rg_vartypemap_find(rg_syms, nm) != null || rg_intmap_find(rg_func_arity, nm) != null ||
       rg_overloadmap_find(rg_func_overloads, nm) != null {
        return true;
    }
    if p_find_template_func(nm) != null {
        return true;
    }
    if p_find_bapi(nm) != null {
        return true;
    }
    p_enum_value(nm);
    if p_enum_found {
        return true;
    }
    if p_find_struct(nm) != null {
        return true;
    }
    if rg_strlistmap_find(rg_pkg_short, nm) != null || rg_set_has(rg_used_members, nm) {
        return true;
    }
    if rg_is_builtin_func(nm) || rg_set_has(rg_extern_funcs, nm) {
        return true;
    }
    return false;
}

void rgt_visit_expr -> @ExprNode e {
    if e == null {
        end;
    }
    !!! A call with a receiver is a method call: the name belongs to the receiver's
    !!! type, which is only known at instantiation.
    bool is_call = (e.nk == FUNC_CALL && !e.has_receiver);
    bool is_name = (e.nk == VAR_REF || e.nk == ARRAY_ACCESS);
    if (is_call || is_name) {
        if e.var_name != "" && !rgt_known(e.var_name) {
            str key = (str)e.line + ":" + (str)e.col + ":" + e.var_name;
            if !rg_set_has(rgt_reported, key) {
                rgt_reported = rg_set_add(rgt_reported, key);
                str msg = "undeclared identifier '" + e.var_name + "'";
                if is_call {
                    msg = "undeclared function '" + e.var_name + "'";
                }
                rg_fmt_err(e.line, e.col, msg, pe_len(e.var_name), (str)null, 0, true);
                rg_has_errors = true;
            }
        }
    }
    rgt_visit_expr(e.left);
    rgt_visit_expr(e.right);
    @ExprNode a = e.args;
    while a != null {
        rgt_visit_expr(a);
        a = a.next;
    }
    @ExprNode ix = e.indices;
    while ix != null {
        rgt_visit_expr(ix);
        ix = ix.next;
    }
    !!! A lambda body is a scope of its own (its parameters and captures are not
    !!! visible from here), so it is left to the instantiation.
    if e.nk == LAMBDA {
        @LambdaRec rec = p_find_lambda(e.lambda_id);
        if rec != null {
            @ExprNode ia = rec.immediate_args;
            while ia != null {
                rgt_visit_expr(ia);
                ia = ia.next;
            }
        }
    }
}

void rgt_visit_body -> @StmtNode body {
    @StmtNode s = body;
    while s != null {
        rgt_visit_expr(s.expr);
        @ExprNode a = s.args;
        while a != null {
            rgt_visit_expr(a);
            a = a.next;
        }
        @ExprNode ai = s.array_init;
        while ai != null {
            rgt_visit_expr(ai);
            ai = ai.next;
        }
        rgt_visit_expr(s.array_len_expr);
        @ExprNode d = s.fparam_defaults;
        while d != null {
            rgt_visit_expr(d);
            d = d.next;
        }
        @ExprNode ce = s.case_exprs;
        while ce != null {
            rgt_visit_expr(ce);
            ce = ce.next;
        }
        rgt_visit_body(s.true_body);
        rgt_visit_body(s.false_body);
        rgt_visit_body(s.case_bodies);
        rgt_visit_body(s.unmatch_body);
        s = s.next;
    }
}

void rg_check_template_bodies {
    @TemplateFunc tf = p_template_funcs;
    while tf != null {
        @StmtNode fn = tf.fn;
        if fn != null && !fn.broken {
            bool skip_it = false;
            !!! An instantiated template was already walked with its concrete types, and
            !!! that walk reports the same errors with a function header.
            if rg_set_has(rg_instantiated_templates, fn.var_name) {
                skip_it = true;
            }
            @StrNode tp = tf.tparams;
            str tname = fn.var_name;
            if !skip_it {
                rgt_ok = null;
                @StrNode t = tf.tparams;
                while t != null {
                    rgt_ok = rg_set_add(rgt_ok, t.s);
                    t = t.next;
                }
                @StrNode p = fn.fparams;
                while p != null {
                    rgt_ok = rg_set_add(rgt_ok, p.s);
                    p = p.next;
                }
                rg_collect_declare_names_out = null;
                rg_collect_declare_names(fn.true_body);
                @StrNode loc = rg_collect_declare_names_out;
                while loc != null {
                    rgt_ok = rg_set_add(rgt_ok, loc.s);
                    loc = loc.next;
                }
                rgt_reported = null;
                rgt_visit_body(fn.true_body);
            }
        }
        tf = tf.next;
    }
}

!!! The explicit type arguments of a statement are TArg records; this converted
!!! instantiation call takes the type of each one, which is a VarTypeNode chain.
@VarTypeNode rgt_vt_of_targs -> @TArg head {
    @VarTypeNode out = null;
    @TArg e = head;
    while e != null {
        out = rg_vartypechain_append(out, e.ty);
        e = e.next;
    }
    return out;
}
