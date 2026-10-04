#once
!~
 ~  bootstrap/frontend/rgen_check_call.b: the frontend/rgen_check_call.
 ~
 ~  The call check: a function has to be declared before it is called in the same
 ~  file (self-recursion is allowed, a definition later in the file is not), and the
 ~  arguments of a call have to fit the parameters of the function or the BLANG_API
 ~  it names - the arity, the reference binding, the array-as-pointer rule, the
 ~  `@void` wildcard and the conversions -Econversion allows.
 ~
 ~  Two things travel in globals here, because a reference parameter cannot be
 ~  one:
 ~   * `str& name` of resolve_global_ref / package_resolve is
 ~     rg_resolve_global_ref_out_name / rg_package_resolve_out_name: the caller
 ~     stores the name there, calls, and reads the rewritten name back (only
 ~     package_resolve writes it into the statement in this file);
 ~   * the argument and parameter chains are walked together with a cursor each, so
 ~     the `continue` loop is the `continue` below: both cursors move
 ~     before the body runs.
 ~
 ~  `s->args.size()` is the carried `nargs` of the statement and the parameter
 ~  vectors are chains, so the loops are over the chains themselves. The helpers
 ~  this file needs and rgen_helpers.b does not have carry the `rgx_` prefix.
 ~!

#head "rgen"
#head "rgen_heads"

!!! `it->second[idx]` with the toolchain bounds test `idx < it->second.size()`: the flag at
!!! that position of one of the per-parameter flag tables, false when the table does
!!! not know the function or the position is past its end. rg_is_ref_param in
!!! rgen_helpers.b answers the same question for one of the tables; this one is
!!! handed the table, because the loop below asks two of them.
bool rgx_param_flag -> @RgBoolListMap head, str fname, int idx {
    @RgBoolListMap it = rg_boollistmap_find(head, fname);
    if it == null || idx >= it.n {
        return false;
    }
    @BoolNode b = it.flags;
    int i = 0;
    while b != null {
        if i == idx {
            return b.v;
        }
        b = b.next;
        i = i + 1;
    }
    return false;
}

!!! The argument mismatch of a BLANG_API call: `"argument %zu missing '%s', got
!!! '%s'"` at the argument, with the "declared here" note under the BAPI. the toolchain
!!! writes the same three lines at each of its three sites; here they stand once.
void rgx_bapi_arg_error -> @StmtNode bapi, @ExprNode a, int ai, VarType missing,
                           VarType actual {
    str msg = "argument " + (str)(ai + 1) + " missing '" + rg_type_name(missing) +
              "', got '" + rg_type_name(actual) + "'";
    int hl = a.tok_len;
    if hl <= 0 {
        hl = pe_len(rg_type_name(actual));
    }
    rg_fmt_err(a.line, a.col, msg, hl, (str)null, 0, true);
    rg_fmt_note(bapi.var_line, bapi.var_col, "declared here", pe_len(bapi.var_name));
    rg_has_errors = true;
}

!!! The argument mismatch of a user function call: the same message, with the
!!! "declared here" note under the parameter list of the declaration
!!! (func_params_pos / func_params_hl). Again the toolchain writes it at three sites.
void rgx_arg_error -> @StmtNode s, @ExprNode a, int ai, VarType missing,
                      VarType actual {
    str msg = "argument " + (str)(ai + 1) + " missing '" + rg_type_name(missing) +
              "', got '" + rg_type_name(actual) + "'";
    int hl = a.tok_len;
    if hl <= 0 {
        hl = pe_len(rg_type_name(actual));
    }
    rg_fmt_err(a.line, a.col, msg, hl, (str)null, 0, true);
    @RgPosMap pit = rg_posmap_find(rg_func_params_pos, s.var_name);
    if pit != null {
        int hl2 = 0;
        @RgIntMap hit = rg_intmap_find(rg_func_params_hl, s.var_name);
        if hit != null {
            hl2 = hit.v;
        }
        rg_fmt_note(pit.a, pit.b, "declared here", hl2);
    }
    rg_has_errors = true;
}

!!! `for (auto* a : s->args) if (a && !resolve_expr_type(a)) has_errors = true;`,
!!! which the toolchain writes at each of the three "this is not an ordinary function
!!! call, but the arguments still have to be resolved" points below.
void rgx_resolve_args -> @StmtNode s {
    @ExprNode a = s.args;
    while a != null {
        if a != null && !rg_resolve_expr_type(a) {
            rg_has_errors = true;
        }
        a = a.next;
    }
}

!!! check_forward_reference: a user function has to be declared before it is called
!!! in the same file (self-recursion is allowed, a definition later in the file is
!!! not). Returns true when the call was reported, so the caller can stop.
bool rg_check_forward_reference -> str name, int line, int col, int len {
    @RgStrMap dit = rg_strmap_find(rg_func_decl_file, name);
    if dit == null {
        return false;
    }
    !!! `auto src = tok.get_source(line);` leaves the file and the source line in
    !!! g_src_file / g_src_line.
    lex_get_source(line);
    if !pe_eq(dit.v, g_src_file) {
        return false;
    }
    @RgIntMap lit = rg_intmap_find(rg_func_decl_line, name);
    if lit == null || lit.v <= g_src_line {
        return false;
    }
    str key = (str)line + ":" + (str)col + ":" + name;
    !!! `if (!_arity_reported.insert(key).second) { has_errors = true; return true; }`:
    !!! a call already reported under this key is not reported again, but it is still
    !!! a reported call, so the answer stays true.
    bool first = !rg_set_has(rg_arity_reported, key);
    rg_arity_reported = rg_set_add(rg_arity_reported, key);
    if !first {
        rg_has_errors = true;
        return true;
    }
    str shown = rg_display_name(name);
    str m = "undeclared function '" + shown + "'";
    int hl = len;
    if hl <= 0 {
        hl = pe_len(shown);
    }
    rg_fmt_err(line, col, m, hl, (str)null, 0, true);
    @RgPosMap pit = rg_posmap_find(rg_func_decl_pos, name);
    if pit != null {
        str nm = "declared here; function '" + shown + "' used before declared";
        rg_fmt_note(pit.a, pit.b, nm, pe_len(shown));
    }
    rg_has_errors = true;
    return true;
}

!!! _check_call_types: the whole call check of one call statement. the toolchain returns
!!! early at each "this call is something else" point; this implementation ends there.
void rg__check_call_types -> @StmtNode s {
    int el = s.var_line;
    if el == 0 {
        el = s.line;
    }
    int ec = s.var_col;
    if ec == 0 {
        ec = s.col;
    }
    !!! `::name` - the global scope explicitly. The rewritten name is not written
    !!! back here (the toolchain drops the local it passed); only the "not a global" answer
    !!! stops the check.
    rg_resolve_global_ref_out_name = s.var_name;
    int gr = rg_resolve_global_ref(el, ec, pe_len(s.var_name));
    if gr == 2 {
        end;
    }
    !!! A statement call to a package member: `pkg::f(...);` / `f(...);`.
    rg_package_resolve_out_name = s.var_name;
    int pr = rg_package_resolve(el, ec, pe_len(s.var_name));
    if pr == 1 {
        s.var_name = rg_package_resolve_out_name;
    } else if pr == 2 {
        end;
    }
    !!! An overload that could not be matched already reported this call; the ordinary
    !!! arity check would only repeat it against one version.
    if rg_overload_error_reported(s.var_name, el, ec) {
        end;
    }
    !!! Dot-syntax method calls (obj.method(...)) are checked by the struct method
    !!! check of the type check pass, so the ordinary function checks are skipped.
    if s.is_method_call {
        end;
    }
    !!! Skip struct method calls (e.g. system.out(...)) - handled separately. Only
    !!! skip when args[0] is a TYPE name (Type.method) or an instance whose struct
    !!! actually declares `name` as a method. A plain function call with a struct
    !!! variable as its first argument (e.g. showAge(p)) must NOT be skipped, or its
    !!! args would never be resolved.
    if s.args != null && s.args.nk == VAR_REF {
        str tn = s.args.var_name;
        if p_find_struct(tn) != null {
            end;
        }
        if rg_strmap_find(rg_sym_struct_type, tn) != null &&
           rg_is_struct_method(s.var_name, tn) {
            end;
        }
    }
    @StmtNode bapi = p_find_bapi(s.var_name);
    if bapi != null {
        int arg_start = 0;
        if s.args != null && s.args.nk == VAR_REF &&
           p_find_struct(s.args.var_name) != null {
            arg_start = 1;
        }
        !!! `s->args.size()`: the chain is counted rather than read from `nargs`,
        !!! because a call node the rgen built itself (a converting constructor's
        !!! wrapper) never counted its arguments.
        int nargs = rgx_na_len_expr(s.args) - arg_start;
        if bapi.variadic {
            if nargs + 1 < bapi.nfparams {
                str m = "function '" + s.var_name + "' needs at least " +
                        (str)(bapi.nfparams - 1) + " argument(s), got " + (str)nargs;
                rg_fmt_err(el, ec, m, pe_len(s.var_name), (str)null, 0, true);
                rg_fmt_note(bapi.var_line, bapi.var_col, "declared here",
                            pe_len(bapi.var_name));
                rg_has_errors = true;
            }
        } else if nargs != bapi.nfparams {
            str m = "function '" + s.var_name + "' needs " + (str)bapi.nfparams +
                    " argument(s), got " + (str)nargs;
            rg_fmt_err(el, ec, m, pe_len(s.var_name), (str)null, 0, true);
            rg_has_errors = true;
        }
        !!! The arguments from arg_start on against the parameter types, both chains
        !!! walked together with the cursors moved before the body, so `continue`
        !!! matches the `continue`.
        @ExprNode a = s.args;
        int skipped = 0;
        while a != null && skipped < arg_start {
            a = a.next;
            skipped = skipped + 1;
        }
        @VarTypeNode t = bapi.fparam_types;
        int ai = arg_start;
        while a != null && t != null {
            @ExprNode cnode = a;
            VarType missing = t.ty;
            a = a.next;
            t = t.next;
            int aindex = ai;
            ai = ai + 1;
            if cnode == null || !rg_resolve_expr_type(cnode) {
                rg_has_errors = true;
                continue;
            }
            VarType actual = cnode.result_type;
            if missing == ANY {
                continue;
            }
            !!! -Econversion: allow safe implicit conversions.
            if (rg_wconversion && rg_is_wconversion_allowed(actual, missing)) ||
               rg_is_free_widening(actual, missing) {
                cnode.convert_to = missing;
                continue;
            }
            bool ptr_like = missing == AT_CHAR || missing == AT_INT ||
                            missing == AT_FLOAT || missing == AT_STR ||
                            missing == AT_VOID || missing == AT_BOOL;
            if ptr_like {
                if (missing == AT_VOID && rg_is_at_type(actual)) ||
                   (actual == AT_VOID && rg_is_at_type(missing)) {
                    continue;
                }
                if cnode.nk == ADDR {
                    VarType pt = cnode.address_type;
                    VarType need_pt = INT;
                    if missing == AT_CHAR {
                        need_pt = CHAR;
                    } else if missing == AT_BOOL {
                        need_pt = BOOL;
                    } else if missing == AT_INT {
                        need_pt = INT;
                    } else if missing == AT_FLOAT {
                        need_pt = FLOAT;
                    } else if missing == AT_STR {
                        need_pt = STR;
                    }
                    if pt != need_pt {
                        rgx_bapi_arg_error(bapi, cnode, aindex, missing, actual);
                    }
                } else if actual != missing {
                    rgx_bapi_arg_error(bapi, cnode, aindex, missing, actual);
                }
            } else if actual != missing {
                rgx_bapi_arg_error(bapi, cnode, aindex, missing, actual);
            }
        }
        end;
    }
    !!! Skip struct method calls (e.g. system.out(...)).
    if s.args != null && s.args.nk == VAR_REF &&
       rg_is_struct_method(s.var_name, s.args.var_name) {
        rgx_resolve_args(s);
        end;
    }
    !!! Also skip if args[0] is a known type name (not a variable).
    if s.args != null && s.args.nk == VAR_REF &&
       p_find_struct(s.args.var_name) != null {
        rgx_resolve_args(s);
        end;
    }
    !!! Indirect call through a func/@func variable: no static target to check.
    if rg_is_callable_var(s.var_name) {
        rgx_resolve_args(s);
        end;
    }
    @RgIntMap ait = rg_intmap_find(rg_func_arity, s.var_name);
    if ait == null && !rg_is_builtin_func(s.var_name) &&
       !rg_set_has(rg_extern_funcs, s.var_name) {
        str shown = rg_display_name(s.var_name);
        str m = "undeclared function '" + shown + "'";
        rg_fmt_err(el, ec, m, pe_len(shown), (str)null, 0, true);
        rg_has_errors = true;
        end;
    }
    !!! Forward-reference check: a user function must be declared before it is called
    !!! in the same file (self-recursion is allowed, cross-file defs are not).
    if rg_check_forward_reference(s.var_name, el, ec, pe_len(s.var_name)) {
        end;
    }
    !!! Spread calls have a runtime argument count; skip static arity/type checks.
    bool has_spread = false;
    @ExprNode sp = s.args;
    while sp != null {
        if sp.spread {
            has_spread = true;
        }
        sp = sp.next;
    }
    if has_spread {
        end;
    }
    if ait != null {
        bool isv = false;
        @RgBoolMap vit = rg_boolmap_find(rg_func_variadic, s.var_name);
        if vit != null {
            isv = vit.v;
        }
        str shown2 = s.var_name;
        @RgStrMap dnit = rg_strmap_find(rg_display_names, s.var_name);
        if dnit != null {
            shown2 = dnit.v;
        }
        !!! The two reports (the variadic "at least" and the plain arity)
        !!! differ in the message only, so they are built here and reported once.
        str msg = "";
        int nargs_c = rgx_na_len_expr(s.args);
        if isv {
            if nargs_c + 1 < ait.v {
                msg = "function '" + shown2 + "' needs at least " +
                      (str)(ait.v - 1) + " argument(s), got " + (str)nargs_c;
            }
        } else if nargs_c != ait.v {
            msg = "function '" + shown2 + "' needs " + (str)ait.v +
                  " argument(s), got " + (str)nargs_c;
        }
        if msg != "" {
            rg_fmt_err(el, ec, msg, pe_len(shown2), (str)null, 0, true);
            @RgPosMap pit = rg_posmap_find(rg_func_params_pos, s.var_name);
            if pit != null {
                int hl = 0;
                @RgIntMap hit = rg_intmap_find(rg_func_params_hl, s.var_name);
                if hit != null {
                    hl = hit.v;
                }
                rg_fmt_note(pit.a, pit.b, "declared here", hl);
            }
            rg_has_errors = true;
        }
    }
    !!! The parameter types. `resolved_n` is where the two chains stop
    !!! agreeing, which the parallel walk below reaches on its own; the arguments
    !!! past it are resolved without a type to compare them against. That last walk
    !!! stands outside the `if` in the toolchain too: a call to a function whose parameter
    !!! types are not known here - one a `.bmeta` gave no types for - has every one
    !!! of its arguments resolved this way.
    @RgVarTypeListMap ptit = rg_vartypelistmap_find(rg_func_param_types, s.var_name);
    @ExprNode a5 = s.args;
    if ptit != null {
        @VarTypeNode t = ptit.types;
        int ai = 0;
        while a5 != null && t != null {
            @ExprNode cnode = a5;
            VarType e = t.ty;
            a5 = a5.next;
            t = t.next;
            int aindex = ai;
            ai = ai + 1;
            if cnode == null || !rg_resolve_expr_type(cnode) {
                rg_has_errors = true;
                continue;
            }
            if e == ANY {
                continue;
            }
            VarType actual = cnode.result_type;
            !!! Array params are passed as pointers: expect the pointer type (@int), not
            !!! the element type (int). A variadic parameter is the last one and is
            !!! checked against the *element* type (str), not the pointer type (@str),
            !!! so the at_of() conversion is skipped for it.
            @RgBoolListMap ait2 = rg_boollistmap_find(rg_func_param_is_array, s.var_name);
            if ait2 != null && aindex < ait2.n &&
               rgx_param_flag(rg_func_param_is_array, s.var_name, aindex) {
                bool variadic = false;
                @RgBoolMap vit2 = rg_boolmap_find(rg_func_variadic, s.var_name);
                if vit2 != null {
                    variadic = vit2.v;
                }
                bool is_variadic_param = variadic && aindex == ait2.n - 1;
                if !is_variadic_param {
                    e = rg_at_of(e);
                }
            }
            !!! Reference params (`ref T x`) auto-bind: the argument is passed by
            !!! reference, so it is checked against the pointee type (T), not the
            !!! pointer type (@T).
            bool is_ref = false;
            @RgBoolListMap rit = rg_boollistmap_find(rg_func_param_is_ref, s.var_name);
            if rit != null && aindex < rit.n &&
               rgx_param_flag(rg_func_param_is_ref, s.var_name, aindex) {
                is_ref = true;
            }
            if is_ref {
                VarType base = rg_deref_of(e);
                if actual != base && !(base == VOID && rg_is_at_type(actual)) {
                    rgx_arg_error(s, cnode, aindex, base, actual);
                }
            } else if actual != e &&
                      !((e == AT_VOID && rg_is_at_type(actual)) ||
                        (actual == AT_VOID && rg_is_at_type(e))) {
                if (rg_wconversion && rg_is_wconversion_allowed(actual, e)) ||
                   rg_is_free_widening(actual, e) {
                    cnode.convert_to = e;
                } else {
                    rgx_arg_error(s, cnode, aindex, e, actual);
                }
            }
        }
    }
    !!! The arguments the walk of the parameter types did not reach, resolved
    !!! without a type to compare them against: the toolchain writes this loop after the
    !!! `if`, so a call to a function whose parameter types are not known here has
    !!! all of its arguments resolved by it.
    while a5 != null {
        if a5 != null && !rg_resolve_expr_type(a5) {
            rg_has_errors = true;
        }
        a5 = a5.next;
    }
}
