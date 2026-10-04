#once
!~
 ~  bootstrap/backend/codegen_func_call.b: a call to a function of this module.
 ~
 ~  The arguments are pushed right to
 ~  left and their runtime count is kept in rsi, so a spread argument and a variadic
 ~  pack give the callee the count it needs. A name this module defines further down
 ~  the file is called through a rel32 that is patched once every body is known.
 ~!

#head "cg_heads"

bool cg_gen_func_call -> str name, @CmpExpr call_args, int line, int col {
    int argc = ce_n(call_args);
    int target = cg_fmap_get(name);
    if target == 0 {
        !!! A function a linked DLL exports goes through the import table instead of
        !!! a body in this file. A function this module defines wins over an export
        !!! of the same name.
        if cg_dll_has(name) {
            return cg_gen_dll_import_call(name, call_args, line, col);
        }
        !!! A function the module defines further down the file is called normally
        !!! and patched later. Anything else never resolves to an implementation;
        !!! where that is reported depends on who emitted the call.
        if !cg_is_declared(name) {
            if line <= 0 || col <= 0 {
                cg_report_undefined_ref(name);
            } else {
                cg_link_errors = cn_str(cg_link_errors,
                                        cg_err_at(line, col,
                                                  "undefined reference to '" + name + "'"));
            }
            !!! The arguments still run, for their side effects.
            int saved_binop = cg_binop_nesting;
            int i = argc - 1;
            while i >= 0 {
                cg_gen_expr(ce_at(call_args, i));
                i = i - 1;
            }
            em_db(0x31);
            em_db(0xC0);
            cg_binop_nesting = saved_binop;
            return true;
        }
    }
    bool known = cg_arity_has(name);
    int expected = cg_arity_get(name);
    bool is_var = cg_variadic_get(name);
    !!! A pack spread into the variadic parameter itself (`f(fmt, rest etc)`) *is*
    !!! that parameter: the callee takes one array pointer, so the pack is passed on
    !!! as it stands. Spreading the elements one by one is for the fixed parameters
    !!! of a callee that has no pack (`add2(xs etc)`).
    bool spread_is_pack = false;
    if is_var && known && expected > 0 && argc == expected && argc > 0 {
        @CmpExpr last_p = ce_at(call_args, argc - 1);
        if last_p != null && last_p.nk == SPREAD && last_p.left != null {
            spread_is_pack = true;
        }
    }
    bool has_spread = false;
    int si = 0;
    while si < argc {
        @CmpExpr a = ce_at(call_args, si);
        if a != null && a.nk == SPREAD && !(spread_is_pack && si + 1 == argc) {
            has_spread = true;
        }
        si = si + 1;
    }
    if !has_spread && known {
        if is_var {
            if argc + 1 < expected {
                cg_stmt_err = cg_err_at(line, col,
                                        "function '" + name + "' expects at least " +
                                        (str)(expected - 1) + " argument(s), got " + (str)argc);
                return false;
            }
        } else if argc != expected {
            cg_stmt_err = cg_err_at(line, col,
                                    "function '" + name + "' expects " + (str)expected +
                                    " argument(s), got " + (str)argc);
            return false;
        }
    }
    int saved_binop = cg_binop_nesting;
    !!! The number of argument slots is a compile-time constant unless a spread
    !!! argument makes it a runtime value, and only a spread needs the two
    !!! registers the dynamic path keeps it in (rsi for the count, rdi for the data
    !!! pointer). Those are nonvolatile, so the dynamic path has to save and
    !!! restore them around every call, count each argument with an increment, and
    !!! give the stack back with shift/add/pop/pop - twelve instructions of
    !!! bookkeeping for a call with one argument, on a construct that appears on
    !!! nearly every line of the generated code. Without a spread the same gives
    !!! back exactly `add rsp, n*8`, and the registers are left alone. The dynamic
    !!! path still has to exist for `f(xs...)`, where only the runtime knows how
    !!! many slots were pushed.
    bool dynamic_args = has_spread;
    int static_slots = -1;
    if dynamic_args {
        em_db(0x56);
        em_db(0x57);
        em_db(0x31);
        em_db(0xF6);
    }
    !!! A variadic parameter arrives as one heap array holding the arguments it
    !!! packs. The one argument that must not be packed is a pack the caller passes
    !!! on: wrapping that array pointer into a one-element pack made the format
    !!! parser read the pointer as the value of the first conversion.
    bool pack_forwarded = false;
    if is_var && known && argc == expected && argc > 0 {
        @CmpExpr last = ce_at(call_args, argc - 1);
        !!! `f(rest etc)` passes the same pack the plain `f(rest)` does.
        if last != null && last.nk == SPREAD {
            last = last.left;
        }
        if last != null && last.nk == VAR_REF {
            @CgVarInfo arr_it = cg_sym_find(last.var_name);
            if arr_it != null && arr_it.is_array {
                pack_forwarded = true;
            }
        }
    }
    !!! Which of the first four arguments is read straight into its register (see
    !!! cg_arg_direct_ok). Only when every argument is a variable or a literal: those
    !!! are pure loads, so which of them is read first cannot be observed. An
    !!! argument that calls something is evaluated in the order written, and the
    !!! registers an earlier one was loaded into are then up for grabs.
    bool d0 = false;
    bool d1 = false;
    bool d2 = false;
    bool d3 = false;
    if !dynamic_args && argc > 0 && !cg_nopt_reg {
        bool all_direct = true;
        int ai = 0;
        while ai < argc {
            @CmpExpr aa = ce_at(call_args, ai);
            if aa == null || aa.nk == SPREAD {
                all_direct = false;
                ai = argc;
                skip;
            }
            if cg_param_type_of(name, ai) == FLOAT {
                all_direct = false;
                ai = argc;
                skip;
            }
            if !cg_arg_direct_ok(aa) {
                all_direct = false;
                ai = argc;
                skip;
            }
            ai = ai + 1;
        }
        !!! The variadic path builds its pack first and does not use these.
        if all_direct && !(is_var && !has_spread && !pack_forwarded && known && expected > 0) {
            if argc > 0 {
                d0 = true;
            }
            if argc > 1 {
                d1 = true;
            }
            if argc > 2 {
                d2 = true;
            }
            if argc > 3 {
                d3 = true;
            }
        }
    }
    if is_var && !has_spread && !pack_forwarded && known && expected > 0 {
        int fixed_n = expected - 1;
        if fixed_n > argc {
            fixed_n = argc;
        }
        int va_count = argc - fixed_n;
        VarType va_type = INT;
        if cg_ptypes_count(name) > 0 {
            va_type = cg_vt_of(cg_ptype_last(name));
        }
        cg_emit_build_variadic_array(call_args, fixed_n, va_count, va_type);
        em_push_rax();
        static_slots = fixed_n + 1;
        int fi = fixed_n - 1;
        while fi >= 0 {
            @CmpExpr ca = ce_at(call_args, fi);
            cg_gen_expr(ca);
            cg_spill_arg(ca, cg_param_type_of(name, fi));
            fi = fi - 1;
        }
    } else {
        int i = argc - 1;
        while i >= 0 {
            @CmpExpr ca = ce_at(call_args, i);
            if ca.nk == SPREAD {
                if spread_is_pack && i + 1 == argc {
                    !!! The pack is the variadic parameter itself: pass the array
                    !!! pointer the callee reads its pack from.
                    cg_gen_expr(ca.left);
                    cg_spill_arg(ca.left, cg_param_type_of(name, i));
                } else {
                    cg_emit_spread_push(ca.left);
                }
            } else {
                if (i == 0 && d0) || (i == 1 && d1) || (i == 2 && d2) || (i == 3 && d3) {
                    !!! The value travels in the register: only the slot of the
                    !!! argument is reserved, because the four slots are the callee's
                    !!! shadow space and the stack arguments sit above them. `continue`
                    !!! and not `skip`: `skip` leaves the whole loop, which reserved one
                    !!! slot of the four and left the stack 24 bytes out.
                    em_sub_rsp_imm8(8);
                    i = i - 1;
                    continue;
                }
                cg_gen_expr(ca);
                cg_spill_arg(ca, cg_param_type_of(name, i));
                if dynamic_args {
                    em_db(0x48);
                    em_db(0xFF);
                    em_db(0xC6);
                }
            }
            i = i - 1;
        }
        if !dynamic_args {
            static_slots = argc;
        }
    }
    !!! Load the first four arguments into rcx/rdx/r8/r9 (the callee's prologue
    !!! saves them into its parameter slots). Only the registers that actually
    !!! carry an argument are loaded: the fixed four loaded three slots of whatever
    !!! the frame happened to hold for a call with one argument, and the load is a
    !!! memory access in the middle of every call site.
    int nreg = 4;
    if static_slots >= 0 {
        nreg = static_slots;
    }
    if nreg > 4 {
        nreg = 4;
    }
    if nreg > 0 {
        if d0 {
            cg_load_arg_direct(ce_at(call_args, 0), 1);
        } else {
            em_mov_rcx_mem_rsp_disp8(0);
        }
    }
    if nreg > 1 {
        if d1 {
            cg_load_arg_direct(ce_at(call_args, 1), 2);
        } else {
            em_mov_rdx_mem_rsp_disp8(8);
        }
    }
    if nreg > 2 {
        if d2 {
            cg_load_arg_direct(ce_at(call_args, 2), 8);
        } else {
            em_mov_r8_mem_rsp_disp8(16);
        }
    }
    if nreg > 3 {
        if d3 {
            cg_load_arg_direct(ce_at(call_args, 3), 9);
        } else {
            em_mov_r9_mem_rsp_disp8(24);
        }
    }
    int call_patch = em_call_rel32();
    if target == 0 {
        cg_pending_call_add(call_patch, name, line, col);
    } else {
        em_patch_call_rel32(call_patch, target);
    }
    !!! Give the argument stack back. The dynamic path counts in rsi (eight bytes
    !!! per slot), the static one is a single immediate - and an immediate above
    !!! 127 has to take the imm32 form, since the imm8 form sign-extends and
    !!! `add rsp, -128` would move the stack the wrong way.
    if dynamic_args {
        em_db(0x48);
        em_db(0xC1);
        em_db(0xE6);
        em_db(0x03);
        em_db(0x48);
        em_db(0x01);
        em_db(0xF4);
        em_db(0x5F);
        em_db(0x5E);
    } else if static_slots > 0 {
        em_sub_rsp(0 - static_slots * 8);
    }
    cg_binop_nesting = saved_binop;
    return true;
}
