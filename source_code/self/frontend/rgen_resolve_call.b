#once
!~
 ~  bootstrap/frontend/rgen_resolve_call.b: this implementation of
 ~
 ~  The type of a call expression: `::name` and package members first, then the
 ~  overload and forward-reference checks, then a struct BAPI method (with its
 ~  argument-type and arity checks), a regular struct method (whose own return type
 ~  is the answer, so a float- or str-returning method is not typed int), an
 ~  indirect call through a func/@func variable, a plain user function (with the
 ~  arity check an expression call needs, reported once per call site), a BLANG_API
 ~  call with the -Econversion and widening rules, and finally a name the program
 ~  only imports.
 ~!

#head "rgen"

!!! resolve_call(): the type of one FUNC_CALL expression.
bool rg_resolve_call -> @ExprNode n {
    !!! `::name` - the global scope explicitly.
    rg_resolve_global_ref_out_name = n.var_name;
    int gr = rg_resolve_global_ref(n.line, n.col, n.tok_len);
    n.var_name = rg_resolve_global_ref_out_name;
    if gr == 2 {
        n.result_type = INT;
        return false;
    }
    !!! A package member call: `pkg::f()`, or `f()` once imported.
    rg_package_resolve_out_name = n.var_name;
    int pr = rg_package_resolve(n.line, n.col, n.tok_len);
    if pr == 1 {
        n.var_name = rg_package_resolve_out_name;
    } else if pr == 2 {
        n.result_type = INT;
        return false;
    }
    !!! An overload that could not be matched already reported this call.
    if rg_overload_error_reported(n.var_name, n.line, n.col) {
        n.result_type = INT;
        return false;
    }
    !!! A function used before its own definition (statement calls are covered by
    !!! _check_call_types, expression calls only here).
    if rg_check_forward_reference(n.var_name, n.line, n.col, n.tok_len) {
        n.result_type = INT;
        return false;
    }
    !!! Struct BAPI method call: type.method(...) / instance.method(...)
    if n.args != null && n.args.nk == VAR_REF {
        @StmtNode sbapi = rg_find_struct_bapi(n.var_name, n.args.var_name);
        if sbapi != null {
            n.result_type = sbapi.func_ret_type;
            !!! Resolve only the real args (args[0] is the struct type/var name).
            @ExprNode a = n.args.next;
            while a != null {
                if !rg_resolve_expr_type(a) {
                    rg_has_errors = true;
                }
                a = a.next;
            }
            !!! Arity check (`n->args.size()`: the chain is counted, since a node the
            !!! rgen built itself never counted its arguments).
            int nargs = rgx_na_len_expr(n.args) - 1;
            if sbapi.variadic {
                if nargs + 1 < sbapi.nfparams {
                    str msg = "function '" + n.var_name + "' needs at least " +
                              (str)(sbapi.nfparams - 1) + " argument(s), got " + (str)nargs;
                    rg_fmt_err(n.line, n.col, msg, pe_len(n.var_name), (str)null, 0, false);
                    rg_has_errors = true;
                }
            } else if nargs != sbapi.nfparams {
                str msg2 = "function '" + n.var_name + "' needs " + (str)sbapi.nfparams +
                           " argument(s), got " + (str)nargs;
                rg_fmt_err(n.line, n.col, msg2, pe_len(n.var_name), (str)null, 0, false);
                rg_has_errors = true;
            }
            !!! Argument type check. The declarations are walked beside the call
            !!! arguments, which is the indexed loop the toolchain writes.
            @ExprNode arg = n.args.next;
            @VarTypeNode ptc = sbapi.fparam_types;
            int ai = 1;
            while arg != null && ptc != null {
                VarType missing = ptc.ty;
                if missing == ANY {
                    arg = arg.next;
                    ptc = ptc.next;
                    ai = ai + 1;
                    continue;
                }
                if arg.result_type != missing {
                    str msg3 = "argument " + (str)ai + " missing '" + rg_type_name(missing) +
                               "', got '" + rg_type_name(arg.result_type) + "'";
                    int hl = arg.tok_len;
                    if hl <= 0 {
                        hl = pe_len(rg_type_name(arg.result_type));
                    }
                    rg_fmt_err(arg.line, arg.col, msg3, hl, (str)null, 0, false);
                    rg_has_errors = true;
                }
                arg = arg.next;
                ptc = ptc.next;
                ai = ai + 1;
            }
            return true;
        }
    }
    !!! Resolve args, look up the function return type.
    @ExprNode a2 = n.args;
    while a2 != null {
        rg_resolve_expr_type(a2);
        a2 = a2.next;
    }
    !!! Regular struct method call: instance.method(...), including a method on a
    !!! nested object (obj.field.method(...)). The result type is the method's own
    !!! return type; typing every method call as INT made a float- or str-returning
    !!! method pass its raw bits to `system.out`.
    if n.has_receiver && n.args != null &&
       (n.args.nk == VAR_REF || n.args.nk == MEMBER_ACCESS || n.args.nk == FIELD_ELEM ||
        n.args.nk == ARRAY_ACCESS || n.args.nk == FUNC_CALL) {
        str stype = "";
        str dt = "";
        rg_receiver_info_out_stype = "";
        rg_receiver_info_out_decl_type = "";
        bool ri = rg_receiver_info(n.args, false);
        if ri {
            stype = rg_receiver_info_out_stype;
            dt = rg_receiver_info_out_decl_type;
        }
        if ri && stype != "" {
            @StmtNode mf = rg_resolve_method_func(stype, n.var_name, true);
            if mf != null {
                rg_check_member_access(mf.struct_type, n.var_name, mf.access, n.line, n.col);
                n.result_type = mf.func_ret_type;
                n.is_unsigned = mf.ret_is_unsigned;
                n.struct_type = mf.ret_struct;
                return true;
            }
        }
    }
    !!! Indirect call through a func/@func variable: use the tracked return type if
    !!! known, otherwise default to INT.
    if rg_is_callable_var(n.var_name) {
        @RgVarTypeMap rit = rg_vartypemap_find(rg_sym_call_ret, n.var_name);
        if rit != null {
            n.result_type = rit.ty;
        } else {
            n.result_type = INT;
        }
        return true;
    }
    @RgVarTypeMap sit = rg_vartypemap_find(rg_syms, n.var_name);
    if sit != null {
        n.result_type = sit.ty;
        !!! `utype T f -> ...`: what the call hands back is unsigned.
        @RgBoolMap uit = rg_boolmap_find(rg_func_ret_is_unsigned, n.var_name);
        if uit != null {
            n.is_unsigned = uit.v;
        }
        !!! Arity check for a plain user function used as an expression, e.g.
        !!! `system.out(add(1), ...)`. Statement calls are checked by
        !!! _check_call_types(); without this a wrong argument count in an
        !!! expression only surfaced later in the backend, which has no source
        !!! position to report.
        @RgIntMap ait = rg_intmap_find(rg_func_arity, n.var_name);
        if ait != null {
            bool has_spread = false;
            @ExprNode sa = n.args;
            while sa != null {
                if sa.spread {
                    has_spread = true;
                }
                sa = sa.next;
            }
            bool is_var = false;
            @RgBoolMap vit = rg_boolmap_find(rg_func_variadic, n.var_name);
            if vit != null {
                is_var = vit.v;
            }
            int got = rgx_na_len_expr(n.args);
            bool wrong_count = false;
            if is_var {
                wrong_count = (got + 1 < ait.v);
            } else {
                wrong_count = (got != ait.v);
            }
            if !has_spread && wrong_count {
                str key = (str)n.line + ":" + (str)n.col + ":" + n.var_name;
                if !rg_set_has(rg_arity_reported, key) {
                    rg_arity_reported = rg_set_add(rg_arity_reported, key);
                    @RgStrMap dit = rg_strmap_find(rg_display_names, n.var_name);
                    str shown = n.var_name;
                    if dit != null {
                        shown = dit.v;
                    }
                    str msg = "";
                    if is_var {
                        msg = "function '" + shown + "' needs at least " + (str)(ait.v - 1) +
                              " argument(s), got " + (str)got;
                    } else {
                        msg = "function '" + shown + "' needs " + (str)ait.v +
                              " argument(s), got " + (str)got;
                    }
                    !!! Highlight the name as written in the source: for an
                    !!! instantiated template n->var_name is the mangled "add_int",
                    !!! which would underline too many columns.
                    rg_fmt_err(n.line, n.col, msg, pe_len(shown), (str)null, 0, false);
                    @RgPosMap pit = rg_posmap_find(rg_func_params_pos, n.var_name);
                    if pit != null {
                        int hl = 0;
                        @RgIntMap hit = rg_intmap_find(rg_func_params_hl, n.var_name);
                        if hit != null {
                            hl = hit.v;
                        }
                        rg_fmt_note(pit.a, pit.b, "declared here", hl);
                    }
                    rg_has_errors = true;
                }
            }
        }
    } else {
        !!! Check the BAPI definitions.
        @StmtNode bapi = p_find_bapi(n.var_name);
        if bapi != null {
            n.result_type = bapi.func_ret_type;
            n.is_unsigned = bapi.ret_is_unsigned;
            @VarTypeNode pt = bapi.fparam_types;
            !!! If args[0] is a struct type name, skip it (struct method call).
            int arg_start = 0;
            if n.args != null && n.args.nk == VAR_REF && p_find_struct(n.args.var_name) != null {
                arg_start = 1;
            }
            !!! A BAPI call written as an expression (`int a = f();`) needs the same
            !!! argument-count check a statement call gets. Without it a missing
            !!! argument passed checking and crashed emission, which made the
            !!! compiler exit silently with no diagnostic.
            int nargs2 = rgx_na_len_expr(n.args) - arg_start;
            int nformal = bapi.nfparams;
            bool wrong_count2 = false;
            if bapi.variadic {
                wrong_count2 = (nargs2 + 1 < nformal);
            } else {
                wrong_count2 = (nargs2 != nformal);
            }
            if wrong_count2 {
                str key2 = (str)n.line + ":" + (str)n.col + ":" + n.var_name;
                if !rg_set_has(rg_arity_reported, key2) {
                    rg_arity_reported = rg_set_add(rg_arity_reported, key2);
                    str msg4 = "";
                    if bapi.variadic {
                        msg4 = "function '" + n.var_name + "' needs at least " +
                               (str)(nformal - 1) + " argument(s), got " + (str)nargs2;
                    } else {
                        msg4 = "function '" + n.var_name + "' needs " + (str)nformal +
                               " argument(s), got " + (str)nargs2;
                    }
                    rg_fmt_err(n.line, n.col, msg4, pe_len(n.var_name), (str)null, 0, false);
                    rg_fmt_note(bapi.var_line, bapi.var_col, "declared here", pe_len(bapi.var_name));
                    rg_has_errors = true;
                }
            }
            @ExprNode arg2 = n.args;
            if arg_start == 1 && arg2 != null {
                arg2 = arg2.next;
            }
            @VarTypeNode ptc2 = pt;
            int ai2 = arg_start;
            while arg2 != null && ptc2 != null {
                VarType actual = INT;
                if arg2 != null {
                    actual = arg2.result_type;
                }
                VarType missing2 = ptc2.ty;
                if missing2 == ANY {
                    arg2 = arg2.next;
                    ptc2 = ptc2.next;
                    ai2 = ai2 + 1;
                    continue;
                }
                !!! -Econversion: allow safe implicit conversions, and the widening
                !!! the language allows on its own.
                bool conv_ok = false;
                if rg_wconversion && rg_is_wconversion_allowed(actual, missing2) {
                    conv_ok = true;
                }
                if conv_ok || rg_is_free_widening(actual, missing2) {
                    arg2.convert_to = missing2;
                    arg2 = arg2.next;
                    ptc2 = ptc2.next;
                    ai2 = ai2 + 1;
                    continue;
                }
                if rg_is_at_type(missing2) {
                    !!! @void <-> any address type bidirectional.
                    if (missing2 == AT_VOID && rg_is_at_type(actual)) ||
                       (actual == AT_VOID && rg_is_at_type(missing2)) {
                        arg2 = arg2.next;
                        ptc2 = ptc2.next;
                        ai2 = ai2 + 1;
                        continue;
                    }
                    !!! For @type params, allow ADDR or a matching AT_*.
                    if arg2.nk == ADDR {
                        VarType pointee = arg2.address_type;
                        VarType need = rg_pointee_of(missing2);
                        if pointee != need {
                            str msg5 = "argument " + (str)(ai2 + 1) + " missing '" +
                                       rg_type_name(missing2) + "', got '" +
                                       rg_type_name(actual) + "'";
                            int hl2 = arg2.tok_len;
                            if hl2 <= 0 {
                                hl2 = pe_len(rg_type_name(actual));
                            }
                            rg_fmt_err(arg2.line, arg2.col, msg5, hl2, (str)null, 0, false);
                            rg_fmt_note(bapi.var_line, bapi.var_col, "declared here",
                                        pe_len(bapi.var_name));
                            return false;
                        }
                    } else if actual != missing2 {
                        str msg6 = "argument " + (str)(ai2 + 1) + " missing '" +
                                   rg_type_name(missing2) + "', got '" +
                                   rg_type_name(actual) + "'";
                        int hl3 = arg2.tok_len;
                        if hl3 <= 0 {
                            hl3 = pe_len(rg_type_name(actual));
                        }
                        rg_fmt_err(arg2.line, arg2.col, msg6, hl3, (str)null, 0, false);
                        rg_fmt_note(bapi.var_line, bapi.var_col, "declared here",
                                    pe_len(bapi.var_name));
                        return false;
                    }
                } else if actual != missing2 {
                    str msg7 = "argument " + (str)(ai2 + 1) + " missing '" +
                               rg_type_name(missing2) + "', got '" +
                               rg_type_name(actual) + "'";
                    int hl4 = arg2.tok_len;
                    if hl4 <= 0 {
                        hl4 = pe_len(rg_type_name(actual));
                    }
                    rg_fmt_err(arg2.line, arg2.col, msg7, hl4, (str)null, 0, false);
                    rg_fmt_note(bapi.var_line, bapi.var_col, "declared here",
                                pe_len(bapi.var_name));
                    return false;
                }
                arg2 = arg2.next;
                ptc2 = ptc2.next;
                ai2 = ai2 + 1;
            }
        } else if rg_intmap_find(rg_func_arity, n.var_name) != null {
            n.result_type = INT;
        } else {
            !!! the toolchain looks the name up in the BAPI table a second time here; the
            !!! lookup stays so the two sides read the same way.
            @StmtNode bit2 = p_find_bapi(n.var_name);
            if bit2 != null {
                n.result_type = bit2.func_ret_type;
            } else if !rg_is_builtin_func(n.var_name) && !rg_set_has(rg_extern_funcs, n.var_name) {
                bool is_sm2 = false;
                if n.args != null && n.args.nk == VAR_REF {
                    is_sm2 = rg_is_struct_method(n.var_name, n.args.var_name);
                }
                !!! A method of the enclosing struct called without a receiver, like
                !!! `f()` inside another method of the same struct. The result type
                !!! is the method's own, so a str-returning method is not typed as
                !!! int.
                if !is_sm2 && rg_struct_method_var != "" {
                    @StmtNode imf = rg_resolve_method_func(rg_struct_method_type, n.var_name, true);
                    if imf != null {
                        rg_check_member_access(imf.struct_type, n.var_name, imf.access,
                                               n.line, n.col);
                        n.result_type = imf.func_ret_type;
                        n.struct_type = imf.ret_struct;
                        return true;
                    }
                }
                if !is_sm2 {
                    !!! The name is in no table this module knows: no body, no
                    !!! import, no method. An earlier pass has already reported it
                    !!! (rg_has_errors), so nothing is said here a second time - but
                    !!! the call is still untyped, and answering int made the
                    !!! declaration around it report a second problem that is only a
                    !!! consequence of the first: `str cmd = F();` came out as
                    !!! "undeclared function 'F'" plus a "type mismatch
                    !!! [-Rimp-str-int]" at the call. Answering false leaves the
                    !!! statement to the pass that knows why it is broken.
                    if !rg_has_errors {
                        str shown2 = rg_display_name(n.var_name);
                        str msg8 = "undeclared function '" + shown2 + "'";
                        rg_fmt_err(n.line, n.col, msg8, pe_len(shown2), (str)null, 0, false);
                    }
                    n.result_type = INT;
                    return false;
                }
                n.result_type = INT;
            } else {
                !!! A function the program imports: its return type comes from the
                !!! .bmeta of the DLL it is linked from.
                @RgVarTypeMap ert = rg_vartypemap_find(rg_extern_ret_types, n.var_name);
                if ert != null {
                    n.result_type = ert.ty;
                } else {
                    n.result_type = INT;
                }
                !!! A DLL that declared its result `utype` means the value without a
                !!! sign: GetLastError's 0xFFFFFFFF is 4294967295, not -1, wherever
                !!! the result is used.
                if rg_set_has(rg_extern_ret_unsigned, n.var_name) {
                    n.is_unsigned = true;
                }
            }
        }
    }
    return true;
}
