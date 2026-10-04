#once
!~
 ~  bootstrap/backend/codegen_call_gen.b: a statement-level call.
 ~
 ~  a call to a function of this module
 ~  (with the arity check, the variadic pack, a nested call and the closure
 ~  temporaries it owns), a call to a function a linked DLL exports (the Windows x64
 ~  ABI, with the frame aligned by hand because a call inside an argument list runs
 ~  with an odd number of pushes behind it), and a builtin call.
 ~!

#head "cg_heads"

!!! `mov [rsp+d], rax`, addressed off rsp itself rather than through the
!!! temporary-slot base the surrounding body may have set.
void cg_store_rax_at_rsp -> int d {
    if d >= -128 && d <= 127 {
        em_db(0x48);
        em_db(0x89);
        em_db(0x44);
        em_db(0x24);
        em_db(d);
    } else {
        em_db(0x48);
        em_db(0x89);
        em_db(0x84);
        em_db(0x24);
        em_dd(d);
    }
}

!!! `mov rsp, [rsp+d]`.
void cg_load_rsp_from_rsp -> int d {
    if d >= -128 && d <= 127 {
        em_db(0x48);
        em_db(0x8B);
        em_db(0x64);
        em_db(0x24);
        em_db(d);
    } else {
        em_db(0x48);
        em_db(0x8B);
        em_db(0xA4);
        em_db(0x24);
        em_dd(d);
    }
}

bool cg_gen_call -> @CmpStmt s {
    int fit_off = cg_fmap_get(s.call_name);
    !!! A function the module defines further down the file is a user function too.
    bool forward_user = fit_off == 0 && cg_is_declared(s.call_name);
    if fit_off != 0 || forward_user {
        int expected = cg_arity_get(s.call_name);
        int nargs = ce_n(s.args);
        if !pe_eq(s.nested_call, "") {
            nargs = nargs + 1;
        }
        bool is_var = cg_variadic_get(s.call_name);
        bool has_spread = false;
        @CmpExpr a = s.args;
        while a != null {
            if a.nk == SPREAD {
                has_spread = true;
            }
            a = a.next;
        }
        if !has_spread {
            if is_var {
                if nargs + 1 < expected {
                    cg_stmt_err = cg_err_at(s.line, s.col,
                                            "function '" + s.call_name +
                                            "' expects at least " + (str)(expected - 1) +
                                            " argument(s), got " + (str)nargs);
                    return false;
                }
            } else if nargs != expected {
                cg_stmt_err = cg_err_at(s.line, s.col,
                                        "function '" + s.call_name + "' expects " +
                                        (str)expected + " argument(s), got " + (str)nargs);
                return false;
            }
        }
        if has_spread && pe_eq(s.nested_call, "") {
            return cg_gen_func_call(s.call_name, s.args, s.line, s.col);
        }
        !!! The closure temporaries this call owns, released once the callee is done.
        @CmpIntNode temp_closures = null;
        int ci = 0;
        @CmpExpr ca = s.args;
        while ca != null {
            bool is_closure_temp = ca.nk == CLOSURE || ca.nk == CLOSURE_FROM_PTR;
            if !is_closure_temp && ca.nk == FUNC_CALL {
                if cg_retype_has(ca.var_name) && cg_retype_get(ca.var_name) == FUNC {
                    is_closure_temp = true;
                }
            }
            if is_closure_temp {
                temp_closures = cn_int(temp_closures, ci);
            }
            ca = ca.next;
            ci = ci + 1;
        }
        int nstack = 0;
        if is_var {
            !!! The trailing arguments are packed into one heap array passed as the
            !!! last parameter.
            int fixed_n = expected - 1;
            int va_count = ce_n(s.args) - fixed_n;
            VarType va_type = INT;
            if cg_ptypes_count(s.call_name) > 0 {
                va_type = cg_vt_of(cg_ptype_last(s.call_name));
            }
            cg_emit_build_variadic_array(s.args, fixed_n, va_count, va_type);
            em_push_rax();
            int i = fixed_n - 1;
            while i >= 0 {
                @CmpExpr aa = ce_at(s.args, i);
                cg_gen_expr(aa);
                cg_spill_arg(aa, cg_param_type_of(s.call_name, i));
                i = i - 1;
            }
            nstack = fixed_n + 1;
        } else {
            !!! `j` and not `i` again: the two arms of one if/else share a declaration
            !!! scope, so a second `i` there is a redeclaration.
            int j = ce_n(s.args) - 1;
            while j >= 0 {
                @CmpExpr aa = ce_at(s.args, j);
                cg_gen_expr(aa);
                cg_spill_arg(aa, cg_param_type_of(s.call_name, j));
                j = j - 1;
            }
            nstack = ce_n(s.args);
        }
        if !pe_eq(s.nested_call, "") {
            if !cg_gen_func_call(s.nested_call, s.nested_args, s.line, s.col) {
                return false;
            }
            em_push_rax();
            nstack = nstack + 1;
        }
        cg_load_reg_args(nstack);
        int call_patch = em_call_rel32();
        if forward_user {
            cg_pending_call_add(call_patch, s.call_name, s.line, s.col);
        } else {
            em_patch_call_rel32(call_patch, fit_off);
        }
        !!! Release the closure temporaries now that the callee is done with them.
        if temp_closures != null && !is_var {
            int base = 1;
            if pe_eq(s.nested_call, "") {
                base = 0;
            }
            @CmpIntNode tc = temp_closures;
            while tc != null {
                !!! This reads the pushed argument block, not a temporary slot.
                int tb = em_temp_base;
                int tbf = em_temp_bias;
                em_temp_base = 0;
                em_ld_rsp((base + (int)tc.v) * 8);
                em_temp_base = tb;
                em_temp_bias = tbf;
                cg_emit_release_closure_rax();
                tc = tc.next;
            }
        }
        if nstack > 0 {
            em_sub_rsp(0 - nstack * 8);
        }
        return true;
    }

    if cg_dll_has(s.call_name) {
        return cg_gen_dll_import_call(s.call_name, s.args, s.line, s.col);
    }

    int func_off = cg_resolve_sym(s.call_name);
    if func_off == 0 {
        if s.line <= 0 || s.col <= 0 {
            cg_report_undefined_ref(s.call_name);
        } else {
            cg_link_errors = cn_str(cg_link_errors,
                                    cg_err_at(s.line, s.col,
                                              "undefined reference to '" + s.call_name + "'"));
        }
        int i = ce_n(s.args) - 1;
        while i >= 0 {
            cg_gen_expr(ce_at(s.args, i));
            i = i - 1;
        }
        em_db(0x31);
        em_db(0xC0);
        return true;
    }
    int i = ce_n(s.args) - 1;
    while i >= 0 {
        @CmpExpr aa = ce_at(s.args, i);
        cg_gen_expr(aa);
        if aa.result_type == FLOAT {
            em_sub_rsp_imm8(8);
            em_movsd_mem_rsp_disp8_xmm0(0);
        } else {
            em_push_rax();
        }
        i = i - 1;
    }
    cg_emit_call_text(func_off);
    if s.args != null {
        em_sub_rsp(0 - ce_n(s.args) * 8);
    }
    return true;
}

!!! A `func` value passed where the DLL declares `@func`: the code pointer sits at
!!! [object+8], the same load `(@func)f` emits.
void cg_func_code_if_needed -> @CgDllImport d, @CmpExpr args, int i {
    @CmpTypeNode pt = d.param_types;
    int k = 0;
    while pt != null {
        if k == i {
            if pt.ty == AT_FUNC {
                @CmpExpr a = ce_at(args, i);
                if a != null && a.result_type == FUNC {
                    em_db(0x48);
                    em_db(0x8B);
                    em_db(0x40);
                    em_db(0x08);
                }
            }
            !!! `end;` and not `return;`: this function hands nothing back.
            end;
        }
        pt = pt.next;
        k = k + 1;
    }
}

!!! A function a linked DLL exports: the first four arguments in rcx/rdx/r8/r9,
!!! the rest on the stack above 32 bytes of shadow space. Every argument is
!!! evaluated first and parked in the shadow space, because evaluating the next one
!!! would clobber the registers the previous one was loaded into.
bool cg_gen_dll_import_call -> str name, @CmpExpr args, int line, int col {
    @CgDllImport d = cg_dll_lookup(name);
    if d == null {
        return true;
    }
    int nargs = ce_n(args);
    int expected = 0;
    @CmpTypeNode pt = d.param_types;
    while pt != null {
        expected = expected + 1;
        pt = pt.next;
    }
    if nargs != expected {
        cg_stmt_err = cg_filename + ":" + (str)line + ":" + (str)col +
                      ": error: function '" + name + "' expects " + (str)expected +
                      " argument(s), but " + (str)nargs + " were provided";
        return false;
    }
    int i = 0;
    while i < nargs {
        @CmpExpr a = ce_at(args, i);
        VarType got = a.result_type;
        VarType expect = INT;
        @CmpTypeNode pe = d.param_types;
        int k = 0;
        while pe != null {
            if k == i {
                expect = pe.ty;
            }
            pe = pe.next;
            k = k + 1;
        }
        bool ok = false;
        !!! `any` takes a value of any type, and `null` (or a literal 0) is the null
        !!! pointer constant for whichever pointer type is wanted.
        if expect == ANY {
            ok = true;
        } else if a.nk == LIT_NULL && (vt_is_ptr(expect) || expect == STR) {
            ok = true;
        } else if a.nk == LIT_INT && a.int_val == 0 &&
                   (vt_is_ptr(expect) || expect == STR) {
            ok = true;
        } else if (vt_is_ptr(got) || got == STR) && (vt_is_ptr(expect) || expect == STR) {
            !!! One pointer in place of another: they are the same to the callee.
            ok = true;
        } else if a.nk == LIT_INT && expect == LONG {
            !!! An integer literal is written as the whole immediate.
            ok = true;
        } else if a.nk == LIT_INT && expect == BOOL &&
                   (a.int_val == 0 || a.int_val == 1) {
            ok = true;
        } else if got == FUNC && expect == AT_FUNC {
            ok = true;
        } else if got == expect {
            ok = true;
        }
        if !ok {
            cg_stmt_err = cg_filename + ":" + (str)line + ":" + (str)col +
                          ": error: function '" + name + "' parameter " + (str)(i + 1) +
                          ": expected '" + vt_name(expect) + "', but got '" +
                          vt_name(got) + "'";
            return false;
        }
        i = i + 1;
    }
    int stack_slots = 0;
    if nargs > 4 {
        stack_slots = nargs - 4;
    }
    !!! Shadow space plus the stack arguments, rounded up to a multiple of 16.
    int total_stack = (32 + stack_slots * 8 + 15) & (0 - 16);
    !!! rsp is not necessarily aligned here: a call written inside an argument list
    !!! runs while an odd number of the surrounding arguments have been pushed. The
    !!! frame is aligned by hand, and the rsp to go back to is parked in the padding
    !!! above the shadow space.
    em_db(0x48);
    em_db(0x89);
    em_db(0xE0);
    em_sub_rsp(total_stack + 16);
    em_db(0x48);
    em_db(0x83);
    em_db(0xE4);
    em_db(0xF0);
    cg_store_rax_at_rsp(total_stack + 8);
    !!! The stack arguments, right to left. A float travels as the eight bytes of
    !!! the double.
    i = nargs - 1;
    while i >= 4 {
        @CmpExpr a = ce_at(args, i);
        cg_gen_expr(a);
        cg_func_code_if_needed(d, args, i);
        int tb = em_temp_base;
        int tbf = em_temp_bias;
        em_temp_base = 0;
        int slot = 32 + (i - 4) * 8;
        if a.result_type == FLOAT {
            em_movsd_mem_rsp_disp8_xmm0(slot);
        } else {
            em_st_rsp_rax(slot);
        }
        em_temp_base = tb;
        em_temp_bias = tbf;
        i = i - 1;
    }
    !!! The register arguments, left to right into the shadow space, so that
    !!! evaluating one does not clobber the register of the one before.
    int nreg = nargs;
    if nreg > 4 {
        nreg = 4;
    }
    i = 0;
    while i < nreg {
        @CmpExpr a = ce_at(args, i);
        cg_gen_expr(a);
        cg_func_code_if_needed(d, args, i);
        if a.result_type == FLOAT {
            em_movsd_mem_rsp_disp8_xmm0(i * 8);
        } else {
            em_mov_mem_rsp_disp8_rax(i * 8);
        }
        i = i + 1;
    }
    !!! The first four arguments travel in the integer registers and a float also in
    !!! the SSE register the ABI names for that position, which is where a system
    !!! DLL looks for it.
    i = 0;
    while i < nreg {
        @CmpExpr a = ce_at(args, i);
        if a.result_type == FLOAT {
            if i == 0 {
                em_movsd_xmm0_mem_rsp_disp8(0);
            } else if i == 1 {
                em_movsd_xmm1_mem_rsp_disp8(8);
            } else if i == 2 {
                em_db(0xF2);
                em_db(0x0F);
                em_db(0x10);
                em_db(0x54);
                em_db(0x24);
                em_db(16);
            } else {
                em_db(0xF2);
                em_db(0x0F);
                em_db(0x10);
                em_db(0x5C);
                em_db(0x24);
                em_db(24);
            }
        }
        if i == 0 {
            em_mov_rax_mem_rsp_disp8(0);
            em_mov_rcx_rax();
        } else if i == 1 {
            em_mov_rax_mem_rsp_disp8(8);
            em_mov_rdx_rax();
        } else if i == 2 {
            em_mov_rax_mem_rsp_disp8(16);
            em_db(0x49);
            em_db(0x89);
            em_db(0xC0);
        } else {
            em_mov_rax_mem_rsp_disp8(24);
            em_db(0x49);
            em_db(0x89);
            em_db(0xC1);
        }
        i = i + 1;
    }
    !!! A function of an embedded DLL is entered exactly like an imported one; only
    !!! the call itself goes straight to its code.
    int embedded_off = cg_embedded_text_off(name);
    if embedded_off != 0 {
        cg_emit_call_text(embedded_off);
    } else {
        cg_emit_call_import(cg_import_index(name));
    }
    cg_load_rsp_from_rsp(total_stack + 8);
    return true;
}
