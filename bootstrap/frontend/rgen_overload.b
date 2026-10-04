#once
!~
 ~  bootstrap/frontend/rgen_overload.b: the frontend/rgen_overload, the
 ~  `reload` overload sets of functions and of methods - their names and the call
 ~  matching that rewrites a call site to the version its arguments fit.
 ~
 ~  A `reload` version is emitted under "<name>__<T1>_<T2>...": a struct parameter
 ~  uses the struct name, and every character that is not valid inside an identifier
 ~  (the `@` of `@void`) becomes `_`. The versions of one name are a chain
 ~  (RgOverloadMap, rgen_heads.b) and are scored against the call's argument types:
 ~  an exact match is worth two points, a widening conversion one, so `f(int)` wins
 ~  over `f(float)` for an int argument.
 ~
 ~  Method overload sets are keyed "<Type>" + character 1 + "<method>": the key is
 ~  written with char_text because a string literal has no hexadecimal escape. The
 ~  indexes the parameter lists by number; this implementation walks them
 ~  (rgx_vt_at/rgx_str_at) so the same `i` reads the same entry.
 ~!

#head "rgen"

VarType rgx_vt_at -> @VarTypeNode head, int i {
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

int rgx_vt_n -> @VarTypeNode head {
    int n = 0;
    @VarTypeNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

@StrNode rgx_str_at -> @StrNode head, int i {
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

@ExprNode rgx_expr_at -> @ExprNode head, int i {
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

int rgx_expr_n -> @ExprNode head {
    int n = 0;
    @ExprNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

str rg_overload_mangle -> @StmtNode f {
    str m = f.var_name + "__";
    int n = rgx_vt_n(f.fparam_types);
    int i = 0;
    while i < n {
        if i != 0 {
            m = m + "_";
        }
        str t = "";
        @StrNode ps = rgx_str_at(f.fparam_struct, i);
        if ps != null && ps.s != "" {
            t = ps.s;
        } else {
            t = rg_type_name(rgx_vt_at(f.fparam_types, i));
        }
        str clean = "";
        int k = 0;
        while k < pe_len(t) {
            char c = t[k];
            bool word = (c >= '0' && c <= '9') || (c >= 'a' && c <= 'z') ||
                        (c >= 'A' && c <= 'Z') || c == '_';
            if word {
                clean = clean + char_text(c);
            } else {
                clean = clean + "_";
            }
            k = k + 1;
        }
        m = m + clean;
        i = i + 1;
    }
    return m;
}

!!! The canonical parameter list of one version, used to tell two versions apart.
str rg_overload_signature -> @StmtNode f {
    str s = "";
    int n = rgx_vt_n(f.fparam_types);
    int i = 0;
    while i < n {
        if i != 0 {
            s = s + ",";
        }
        @StrNode ps = rgx_str_at(f.fparam_struct, i);
        if ps != null && ps.s != "" {
            s = s + ps.s;
        } else {
            s = s + rg_type_name(rgx_vt_at(f.fparam_types, i));
        }
        i = i + 1;
    }
    if f.variadic {
        s = s + ",...";
    }
    return s;
}

!!! Pick the version matching the call's argument count and types. False (and one
!!! report per call site) when nothing matches or two versions score the same.
bool rg_pick_overload -> str name, @ExprNode args, int line, int col, int tok_len {
    @RgOverloadMap it = rg_overloadmap_find(rg_func_overloads, name);
    if it == null {
        return false;
    }
    @OverloadVersion versions = it.versions;
    if it.n == 1 {
        rg_pick_overload_out = versions.internal_name;
        return true;
    }
    !!! the toolchain hands `out` down to pick_from_versions, so the name the scoring picked
    !!! has to reach the caller's own out.
    if !rg_pick_from_versions(versions, name, args, line, col, tok_len) {
        return false;
    }
    rg_pick_overload_out = rg_pick_from_versions_out;
    return true;
}

!!! Score every version against the argument types and take the best one.
bool rg_pick_from_versions -> @OverloadVersion versions, str name, @ExprNode args,
                              int line, int col, int tok_len {
    int argc = rgx_expr_n(args);
    int i = 0;
    while i < argc {
        @ExprNode a = rgx_expr_at(args, i);
        if a != null {
            rg_resolve_expr_type(a);
        }
        i = i + 1;
    }

    @OverloadVersion best = null;
    int best_score = -1;
    bool ambiguous = false;
    @OverloadVersion v = versions;
    while v != null {
        bool fits = true;
        if v.variadic {
            if argc + 1 < v.arity {
                fits = false;
            }
        } else if argc != v.arity {
            fits = false;
        }
        if fits {
            int score = 0;
            bool ok = true;
            int k = 0;
            int vn = rgx_vt_n(v.param_types);
            while k < argc && k < vn {
                str want_struct = "";
                @StrNode ps = rgx_str_at(v.param_structs, k);
                if ps != null {
                    want_struct = ps.s;
                }
                @ExprNode arg = rgx_expr_at(args, k);
                str astruct = "";
                VarType atype = VOID;
                if arg != null {
                    astruct = arg.struct_type;
                    atype = arg.result_type;
                }
                if want_struct != "" {
                    if p_text_eq(astruct, want_struct) {
                        score = score + 2;
                        k = k + 1;
                        continue;
                    }
                    ok = false;
                    skip;
                }
                VarType want = rgx_vt_at(v.param_types, k);
                if want == ANY {
                    score = score + 1;
                    k = k + 1;
                    continue;
                }
                !!! A struct argument only matches a parameter declared as that
                !!! struct; without this an overload taking an int scored the same as
                !!! the one taking the struct. It also matches a scalar parameter when
                !!! the struct declares the conversion to it, one point below an exact
                !!! match.
                if astruct != "" {
                    bool is_scalar = scalar_type_name(want);
                    if is_scalar && rg_resolve_method_func(astruct, "op_to_" + op_scalar, true) != null {
                        score = score + 1;
                        k = k + 1;
                        continue;
                    }
                    ok = false;
                    skip;
                }
                if atype == want {
                    score = score + 2;
                    k = k + 1;
                    continue;
                }
                if rg_is_wconversion_allowed(atype, want) || rg_is_free_widening(atype, want) {
                    score = score + 1;
                    k = k + 1;
                    continue;
                }
                ok = false;
                skip;
            }
            if ok {
                if score > best_score {
                    best_score = score;
                    best = v;
                    ambiguous = false;
                } else if score == best_score {
                    ambiguous = true;
                }
            }
        }
        v = v.next;
    }

    if best != null && !ambiguous {
        rg_pick_from_versions_out = best.internal_name;
        return true;
    }
    str key = (str)line + ":" + (str)col + ":" + name;
    if !rg_set_has(rg_overload_reported, key) {
        rg_overload_reported = rg_set_add(rg_overload_reported, key);
        str shown = rg_display_name(name);
        str msg = "no matching overload for function '" + shown + "'";
        if ambiguous {
            msg = "ambiguous call to overloaded function '" + shown + "'";
        }
        int hl = tok_len;
        if hl <= 0 {
            hl = pe_len(shown);
        }
        rg_fmt_err(line, col, msg, hl, (str)null, 0, true);
        rg_has_errors = true;
    }
    return false;
}

!!! Pick the version matching a method call's arguments. `args` are the call's
!!! parameters, without the receiver.
bool rg_pick_method_overload -> str stype, str name, @ExprNode args, int line, int col,
                                int tok_len {
    str key = stype + char_text(1) + name;
    @RgOverloadMap it = rg_overloadmap_find(rg_method_overloads, key);
    if it == null {
        return false;
    }
    @OverloadVersion versions = it.versions;
    if it.n == 1 {
        rg_pick_method_overload_out = versions.internal_name;
        return true;
    }
    !!! Same as pick_overload: the scoring writes rg_pick_from_versions_out, and the
    !!! caller reads the out of this method.
    if !rg_pick_from_versions(versions, name, args, line, col, tok_len) {
        return false;
    }
    rg_pick_method_overload_out = rg_pick_from_versions_out;
    return true;
}

!!! One method call: the receiver decides which type's overload set applies.
void rg_resolve_method_overload_expr -> @ExprNode n {
    if n == null || n.nk != FUNC_CALL {
        end;
    }
    if !n.has_receiver {
        !!! An implicit call inside a method body: `this` is the receiver.
        if rg_struct_method_type == "" {
            end;
        }
        str key = rg_struct_method_type + char_text(1) + n.var_name;
        @RgOverloadMap it = rg_overloadmap_find(rg_method_overloads, key);
        if it == null || it.n < 2 {
            end;
        }
        rg_pick_method_overload_out = "";
        if rg_pick_method_overload(rg_struct_method_type, n.var_name, n.args, n.line, n.col, n.tok_len) {
            n.var_name = rg_pick_method_overload_out;
            n.is_overload_call = true;
        }
        end;
    }
    if n.args == null {
        end;
    }
    !!! The receiver's own type, without resolving it as an expression: for
    !!! `Type.method(...)` the receiver is a type name, not a variable.
    str st = rg_expr_struct_type(n.args);
    if st == "" {
        end;
    }
    str key2 = st + char_text(1) + n.var_name;
    @RgOverloadMap it2 = rg_overloadmap_find(rg_method_overloads, key2);
    if it2 == null || it2.n < 2 {
        end;
    }
    rg_pick_method_overload_out = "";
    if rg_pick_method_overload(st, n.var_name, n.args.next, n.line, n.col, n.tok_len) {
        n.var_name = rg_pick_method_overload_out;
        n.is_overload_call = true;
    }
}

void rg_resolve_method_overload_stmt -> @StmtNode s {
    if s == null || s.nk != CALL_FUNC || !s.is_method_call || s.args == null {
        end;
    }
    !!! The receiver's own type, without resolving it as an expression.
    str st = rg_expr_struct_type(s.args);
    if st == "" {
        end;
    }
    str key = st + char_text(1) + s.var_name;
    @RgOverloadMap it = rg_overloadmap_find(rg_method_overloads, key);
    if it == null || it.n < 2 {
        end;
    }
    int line = s.var_line;
    if line == 0 {
        line = s.line;
    }
    int col = s.var_col;
    if col == 0 {
        col = s.col;
    }
    rg_pick_method_overload_out = "";
    if rg_pick_method_overload(st, s.var_name, s.args.next, line, col, pe_len(s.var_name)) {
        s.var_name = rg_pick_method_overload_out;
        s.is_overload_call = true;
    }
}

void rg_resolve_overloads_expr -> @ExprNode n {
    if n == null {
        end;
    }
    rg_resolve_overloads_expr(n.left);
    rg_resolve_overloads_expr(n.right);
    @ExprNode a = n.args;
    while a != null {
        rg_resolve_overloads_expr(a);
        a = a.next;
    }
    @ExprNode ix = n.indices;
    while ix != null {
        rg_resolve_overloads_expr(ix);
        ix = ix.next;
    }
    if n.nk == LAMBDA {
        @LambdaRec rec = p_find_lambda(n.lambda_id);
        if rec != null {
            @ExprNode ia = rec.immediate_args;
            while ia != null {
                rg_resolve_overloads_expr(ia);
                ia = ia.next;
            }
        }
    }
    if n.nk != FUNC_CALL {
        end;
    }
    !!! A method call whose receiver has several versions of that name.
    if n.has_receiver {
        rg_resolve_method_overload_expr(n);
    }
    !!! Only names that actually have several versions are rewritten; every other
    !!! call keeps its name and the ordinary checks apply.
    @RgOverloadMap it = rg_overloadmap_find(rg_func_overloads, n.var_name);
    if it == null || it.n < 2 {
        end;
    }
    rg_pick_overload_out = "";
    if rg_pick_overload(n.var_name, n.args, n.line, n.col, n.tok_len) {
        n.var_name = rg_pick_overload_out;
        n.is_overload_call = true;
    }
}

void rg_resolve_overloads_stmt -> @StmtNode s {
    if s == null {
        end;
    }
    !!! Function parameters are only visible inside their own body, so the body is
    !!! walked under its own parameter scope.
    if s.nk == FUNCTION {
        @ExprNode d = s.fparam_defaults;
        while d != null {
            rg_resolve_overloads_expr(d);
            d = d.next;
        }
        if s.broken {
            end;
        }
        rg_push_func_params(s);
        @StmtNode ss = s.true_body;
        while ss != null {
            rg_resolve_overloads_stmt(ss);
            ss = ss.next;
        }
        rg_pop_func_params();
        end;
    }
    rg_resolve_overloads_expr(s.expr);
    rg_resolve_overloads_expr(s.array_len_expr);
    @ExprNode a = s.args;
    while a != null {
        rg_resolve_overloads_expr(a);
        a = a.next;
    }
    @ExprNode ai = s.array_init;
    while ai != null {
        rg_resolve_overloads_expr(ai);
        ai = ai.next;
    }
    @ExprNode ce = s.case_exprs;
    while ce != null {
        rg_resolve_overloads_expr(ce);
        ce = ce.next;
    }
    @ExprNode asi = s.assign_indices;
    while asi != null {
        rg_resolve_overloads_expr(asi);
        asi = asi.next;
    }
    @ExprNode fd = s.fparam_defaults;
    while fd != null {
        rg_resolve_overloads_expr(fd);
        fd = fd.next;
    }
    !!! `true_body` is the `true_body` and the `children` at once.
    @StmtNode tb = s.true_body;
    while tb != null {
        rg_resolve_overloads_stmt(tb);
        tb = tb.next;
    }
    @StmtNode fb = s.false_body;
    while fb != null {
        rg_resolve_overloads_stmt(fb);
        fb = fb.next;
    }
    @StmtNode cb = s.case_bodies;
    while cb != null {
        rg_resolve_overloads_stmt(cb);
        cb = cb.next;
    }
    @StmtNode ub = s.unmatch_body;
    while ub != null {
        rg_resolve_overloads_stmt(ub);
        ub = ub.next;
    }
    !!! A statement call (`add(1, 2);`) carries its arguments on the statement.
    if s.nk != CALL_FUNC {
        end;
    }
    if s.is_method_call {
        rg_resolve_method_overload_stmt(s);
        end;
    }
    @RgOverloadMap it = rg_overloadmap_find(rg_func_overloads, s.var_name);
    if it == null || it.n < 2 {
        end;
    }
    int line = s.var_line;
    if line == 0 {
        line = s.line;
    }
    int col = s.var_col;
    if col == 0 {
        col = s.col;
    }
    rg_pick_overload_out = "";
    if rg_pick_overload(s.var_name, s.args, line, col, pe_len(s.var_name)) {
        s.var_name = rg_pick_overload_out;
        s.is_overload_call = true;
    }
}

!!! One struct method body: its calls are resolved with the method's own type as the
!!! implicit receiver.
void rgx_resolve_overload_body -> str stype, @StmtNode f {
    if f == null || f.broken {
        end;
    }
    rg_struct_method_type = stype;
    rg_struct_method_var = "__this";
    rg_push_func_params(f);
    @StmtNode ss = f.true_body;
    while ss != null {
        rg_resolve_overloads_stmt(ss);
        ss = ss.next;
    }
    rg_pop_func_params();
}

void rg_resolve_overloads -> @StmtNode stmts {
    @StmtNode s = stmts;
    while s != null {
        rg_resolve_overloads_stmt(s);
        s = s.next;
    }
    !!! Struct method bodies are not part of the statement tree, so their calls are
    !!! resolved with the method's own type as the implicit receiver.
    str saved_type = rg_struct_method_type;
    str saved_var = rg_struct_method_var;
    @StructDef sd = p_struct_defs;
    while sd != null {
        @StructMethod m = sd.methods;
        while m != null {
            rgx_resolve_overload_body(sd.name, m.fn);
            m = m.next;
        }
        rgx_resolve_overload_body(sd.name, sd.init_func);
        rgx_resolve_overload_body(sd.name, sd.destruct_func);
        sd = sd.next;
    }
    rg_struct_method_type = saved_type;
    rg_struct_method_var = saved_var;
}

bool rg_overload_error_reported -> str name, int line, int col {
    str key = (str)line + ":" + (str)col + ":" + name;
    return rg_set_has(rg_overload_reported, key);
}
