#once
!~
 ~  bootstrap/frontend/rgen_bapi_emit.b: the frontend/rgen_bapi_emit,
 ~  the `BCALL` / `BCALL_EXPR` / `BSPREAD` text a BLANG_API call emits.
 ~
 ~  One BAPI statement holds the `__bcall("target")` segments of its body, each
 ~  with the formal parameter names the `__badd(...)` directives collected before
 ~  it. A segment is emitted as one `BCALL "target" arg, arg ...` line, and the
 ~  arguments are the call's own, in the order the segment named them: a formal
 ~  parameter that was never named by the segment is not passed, and the variadic
 ~  parameter expands to every trailing call argument.
 ~
 ~  A `a chain` is a chain here, so `.size()` is a walk (rgx_argc and friends)
 ~  and `.back()` is a walk to the last entry. The `any` tag of an argument is
 ~  built into `rg_rcode` and taken out again, which is what the toolchain does with a
 ~  saved copy of the text.
 ~!

#head "rgen"

int rgx_argc -> @ExprNode head {
    int n = 0;
    @ExprNode a = head;
    while a != null {
        n = n + 1;
        a = a.next;
    }
    return n;
}

@ExprNode rgx_arg_at -> @ExprNode head, int idx {
    int i = 0;
    @ExprNode a = head;
    while a != null {
        if i == idx {
            return a;
        }
        i = i + 1;
        a = a.next;
    }
    return null;
}

int rgx_strnode_n -> @StrNode head {
    int n = 0;
    @StrNode a = head;
    while a != null {
        n = n + 1;
        a = a.next;
    }
    return n;
}

str rgx_strnode_last -> @StrNode head {
    str s = "";
    @StrNode a = head;
    while a != null {
        s = a.s;
        a = a.next;
    }
    return s;
}

int rgx_vartypenode_n -> @VarTypeNode head {
    int n = 0;
    @VarTypeNode a = head;
    while a != null {
        n = n + 1;
        a = a.next;
    }
    return n;
}

VarType rgx_vartype_at -> @VarTypeNode head, int idx {
    int i = 0;
    @VarTypeNode a = head;
    while a != null {
        if i == idx {
            return a.ty;
        }
        i = i + 1;
        a = a.next;
    }
    return ANY;
}

@BapiCallSeg rgx_seg_last -> @BapiCallSeg head {
    @BapiCallSeg last = null;
    @BapiCallSeg a = head;
    while a != null {
        last = a;
        a = a.next;
    }
    return last;
}

@ResolvedArg rgx_resolved -> int formal_idx, int call_idx {
    ResolvedArg proto;
    @ResolvedArg r;
    malloc(@r, size proto);
    r.formal_idx = formal_idx;
    r.call_idx = call_idx;
    r.next = null;
    return r;
}

!!! The formal/call argument pairs one segment stands for, in the order the
!!! segment named its parameters. The variadic parameter expands to one entry per
!!! trailing call argument.
@ResolvedArg rg_resolve_bapi_seg -> @StmtNode bapi, @BapiCallSeg seg, int call_arg_count {
    @ResolvedArg out = null;
    int variadic_idx = -1;
    if bapi.variadic {
        variadic_idx = rgx_strnode_n(bapi.fparams) - 1;
    }
    @StrNode nm = seg.arg_names;
    while nm != null {
        int fi = -1;
        int i = 0;
        @StrNode p = bapi.fparams;
        while p != null {
            if p_text_eq(p.s, nm.s) {
                fi = i;
                skip;
            }
            i = i + 1;
            p = p.next;
        }
        if fi >= 0 {
            if bapi.variadic && fi == variadic_idx {
                int ci = variadic_idx;
                while ci < call_arg_count {
                    out = rg_resolvedarg_append(out, rgx_resolved(fi, ci));
                    ci = ci + 1;
                }
            } else {
                out = rg_resolvedarg_append(out, rgx_resolved(fi, fi));
            }
        }
        nm = nm.next;
    }
    return out;
}

void rg_emit_bapi_arg -> @StmtNode bapi, @ResolvedArg r, @ExprNode call_args, bool first {
    !!! A call with too few arguments is reported by the checking passes; guard the
    !!! indexing here so no missed path can crash the compiler.
    int argc = rgx_argc(call_args);
    if r.call_idx >= argc {
        end;
    }
    @ExprNode arg = rgx_arg_at(call_args, r.call_idx);
    if arg == null {
        end;
    }
    if !first {
        rg_rcode = rg_rcode + " ,";
    }
    rg_rcode = rg_rcode + " ";
    VarType ft = ANY;
    if r.formal_idx < rgx_vartypenode_n(bapi.fparam_types) {
        ft = rgx_vartype_at(bapi.fparam_types, r.formal_idx);
    }
    !!! Resolve an `any` argument before emitting it: it may be a call whose own
    !!! arguments include a struct, and a struct argument is only passed by address
    !!! once its type is known. A node type checking already resolved keeps that
    !!! answer: resolving it again here looked the name up in the flat tables,
    !!! where the first declaration of a shadowed name won, and tagged the value
    !!! with the wrong type.
    if ft == ANY && !arg.type_resolved {
        rg_resolve_expr_type(arg);
    }
    !!! The `any` tag has to be computed before the expression is emitted: emitting
    !!! a call re-enters type resolution and can leave a different result_type
    !!! behind, which would tag the value as the wrong type.
    str tag = "";
    if ft == ANY {
        tag = rg_rc_any_tag(arg);
    }
    !!! An unsigned value is printed as unsigned, and the printing an `any`
    !!! argument goes through knows only the signed kinds: it is handed the text of
    !!! the value instead, which is what an unsigned conversion makes.
    if ft == ANY && rg_is_unsigned_value(arg) {
        bool w64 = (arg.result_type == LONG);
        rg_rcode = rg_rcode + " (CALL_EXPR ";
        rg_rcode = rg_rcode + rg_utype_str_helper(arg);
        rg_rcode = rg_rcode + " , ";
        if w64 {
            rg_rcode = rg_rcode + "_toLong ";
        } else {
            rg_rcode = rg_rcode + "_toInt ";
        }
        rg_rc_expr(arg);
        rg_rcode = rg_rcode + ")";
        rg_rcode = rg_rcode + " , 1";
        end;
    }
    rg_rc_expr(arg);
    if ft == ANY {
        rg_rcode = rg_rcode + tag;
    }
}

void rg_emit_bapi_stmt -> @StmtNode bapi, @ExprNode call_args, bool one_per_vararg {
    str var_param = "";
    int variadic_idx = -1;
    int nf = rgx_strnode_n(bapi.fparams);
    if bapi.variadic {
        var_param = rgx_strnode_last(bapi.fparams);
        variadic_idx = nf - 1;
    }
    !!! A single `arg etc` bound to the variadic parameter unpacks at runtime, so a
    !!! per-element BSPREAD loop is emitted instead of static one-per-arg BCALLs.
    int argc = rgx_argc(call_args);
    @ExprNode spread_arg = null;
    if bapi.variadic && argc == nf && variadic_idx < argc {
        @ExprNode va = rgx_arg_at(call_args, variadic_idx);
        if va != null && va.spread {
            spread_arg = va;
        }
    }
    bool first_bcall = true;
    @BapiCallSeg seg = bapi.bapi_segs;
    while seg != null {
        @ResolvedArg resolved = rg_resolve_bapi_seg(bapi, seg, argc);
        if resolved != null {
            bool refs_var = false;
            @StrNode nm = seg.arg_names;
            while nm != null {
                if p_text_eq(nm.s, var_param) {
                    refs_var = true;
                    skip;
                }
                nm = nm.next;
            }
            if spread_arg != null && refs_var {
                !!! Spread the variadic array element by element into this builtin.
                !!! The `any` tag is per element for an `any` pack, otherwise it is
                !!! the pack's static element type (STR, say).
                int tag = -1;
                if spread_arg.nk == VAR_REF {
                    @RgVarTypeMap sit = rg_vartypemap_find(rg_syms, spread_arg.var_name);
                    if sit != null && sit.ty != ANY {
                        tag = (int)sit.ty;
                    }
                }
                if !first_bcall {
                    rg_rcode = rg_rcode + "\n";
                }
                rg_rcode = rg_rcode + "BSPREAD \"" + seg.target + "\" ";
                rg_rc_expr(spread_arg);
                rg_rcode = rg_rcode + " , " + (str)tag;
                first_bcall = false;
            } else if one_per_vararg && refs_var {
                @ResolvedArg k = resolved;
                while k != null {
                    if !first_bcall {
                        rg_rcode = rg_rcode + "\n";
                    }
                    rg_rcode = rg_rcode + "BCALL \"" + seg.target + "\"";
                    rg_emit_bapi_arg(bapi, k, call_args, true);
                    first_bcall = false;
                    k = k.next;
                }
            } else {
                if !first_bcall {
                    rg_rcode = rg_rcode + "\n";
                }
                rg_rcode = rg_rcode + "BCALL \"" + seg.target + "\"";
                @ResolvedArg k2 = resolved;
                bool first_arg = true;
                while k2 != null {
                    rg_emit_bapi_arg(bapi, k2, call_args, first_arg);
                    first_arg = false;
                    k2 = k2.next;
                }
                first_bcall = false;
            }
        }
        seg = seg.next;
    }
}

void rg_emit_bapi_expr -> @StmtNode bapi, @ExprNode call_args {
    if bapi.bapi_segs == null {
        end;
    }
    @BapiCallSeg seg = rgx_seg_last(bapi.bapi_segs);
    @ResolvedArg resolved = rg_resolve_bapi_seg(bapi, seg, rgx_argc(call_args));
    rg_rcode = rg_rcode + "(BCALL_EXPR \"" + seg.target + "\" " + rg_rtype(bapi.func_ret_type);
    @ResolvedArg k = resolved;
    while k != null {
        rg_emit_bapi_arg(bapi, k, call_args, false);
        k = k.next;
    }
    rg_rcode = rg_rcode + ")";
}
