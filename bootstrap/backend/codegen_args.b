#once
!~
 ~  bootstrap/backend/codegen_args.b: the call arguments.
 ~
 ~  the first four arguments go into
 ~  rcx/rdx/r8/r9 (the callee's prologue saves them into the parameter slots), an
 ~  argument is spilled as a double when either side is a float, a variadic pack is
 ~  built as one heap array, and a spread array is pushed element by element.
 ~!

#head "cg_heads"

void cg_load_reg_args -> int n {
    if n > 0 {
        em_mov_rcx_mem_rsp_disp8(0);
    }
    if n > 1 {
        em_mov_rdx_mem_rsp_disp8(8);
    }
    if n > 2 {
        em_mov_r8_mem_rsp_disp8(16);
    }
    if n > 3 {
        em_mov_r9_mem_rsp_disp8(24);
    }
}

!!! Whether argument `a` can be read straight into the register that carries it
!!! instead of being pushed to a slot and read back out of it. A variable or a small
!!! integer literal is one load wherever it is read, and the four argument slots of a
!!! call are reserved either way: they are the shadow space the callee's prologue
!!! spills rcx/rdx/r8/r9 into, and the stack arguments sit above them. Anything else
!!! keeps the slot, because its value would have to be evaluated again (or it
!!! travels in xmm0).
bool cg_arg_direct_ok -> @CmpExpr a {
    if a == null {
        return false;
    }
    if a.result_type == FLOAT {
        return false;
    }
    if a.nk == LIT_INT || a.nk == LIT_CHAR || a.nk == LIT_BOOL || a.nk == LIT_NULL {
        if !cg_small_int_literal(a) {
            return false;
        }
        !!! A character of 128..255 is stored sign-extended by the literal path, and
        !!! `mov reg32, imm32` would zero-extend it instead.
        if a.nk == LIT_CHAR && cg_small_int_literal_out < 0 {
            return false;
        }
        return true;
    }
    if a.nk != VAR_REF {
        return false;
    }
    !!! The argument registers are loaded out of the frame, so this is for the code
    !!! of a body: the entry scope addresses its slots off rsp.
    if pe_eq(cg_current_func, "") {
        return false;
    }
    @CgNameOff poit = cg_param_off(cg_current_func, a.var_name);
    if poit != null {
        return cg_param_type(cg_current_func, a.var_name) != FLOAT;
    }
    @CgVarInfo it = cg_sym_find(a.var_name);
    if it == null {
        return false;
    }
    if it.is_array {
        return false;
    }
    if it.ty == FLOAT {
        return false;
    }
    !!! A char or a bool is read out of its slot with an extension cg_load_var adds
    !!! and a wide load of the slot would leave the bits above the byte as they were.
    if it.ty == CHAR || it.ty == BOOL {
        return false;
    }
    return true;
}

!!! The load itself: `reg` is 1 for rcx, 2 for rdx, 8 for r8 and 9 for r9.
void cg_load_arg_direct -> @CmpExpr a, int reg {
    if a.nk != VAR_REF {
        cg_small_int_literal(a);
        em_mov_arg_imm32(reg, cg_small_int_literal_out);
        end;
    }
    if !pe_eq(cg_current_func, "") {
        @CgNameOff poit = cg_param_off(cg_current_func, a.var_name);
        if poit != null {
            !!! A parameter slot holds the whole 64-bit value the caller pushed,
            !!! whatever its declared type.
            em_ld_arg_disp(reg, poit.off);
            end;
        }
    }
    @CgVarInfo it2 = cg_sym_find(a.var_name);
    if it2 != null {
        cg_load_var_arg(it2.stack_offset, it2.ty, reg);
    }
}

!!! The declared type of parameter `idx` of a user function, or INT when it is not
!!! known (a builtin target). A FLOAT parameter is read as a double, so an integer
!!! argument has to be converted before it is spilled. The types come from the
!!! index as one byte each, so an argument costs one probe and not a walk of the
!!! function table.
VarType cg_param_type_of -> str fname, int idx {
    return cg_vt_of(cg_ptype_at(fname, idx));
}

!!! One argument onto the stack in the form the callee expects.
void cg_spill_arg -> @CmpExpr a, VarType want {
    if a.result_type == FLOAT {
        em_sub_rsp_imm8(8);
        em_movsd_mem_rsp_disp8_xmm0(0);
    } else if want == FLOAT {
        em_cvtsi2sd_xmm0_rax();
        em_sub_rsp_imm8(8);
        em_movsd_mem_rsp_disp8_xmm0(0);
    } else {
        em_push_rax();
    }
}

!!! The heap array one variadic call packs: `any` elements are 16 bytes (a value
!!! and its type tag), the other types are their own width.
void cg_emit_build_variadic_array -> @CmpExpr args, int start, int n, VarType elem_type {
    bool is_any = elem_type == ANY;
    int elem_size = vt_size(elem_type);
    if is_any {
        elem_size = 16;
    }
    !!! The base has to survive the argument expressions below. rbx is not usable
    !!! for that: an indirect call through a func variable, a closure release and a
    !!! nested variadic build all write rbx, so the element stores landed on
    !!! whatever address was left there. The base lives in a frame-relative
    !!! temporary and is loaded into rdx right before each store.
    int saved_nesting = cg_binop_nesting;
    int base_slot = cg_next_stack_offset + cg_binop_nesting * 8;
    cg_binop_nesting = cg_binop_nesting + 1;
    em_mov_rax_imm64(n);
    if elem_size == 16 {
        em_db(0x48);
        em_db(0xC1);
        em_db(0xE0);
        em_db(0x04);
    } else if elem_size == 8 {
        em_db(0x48);
        em_db(0xC1);
        em_db(0xE0);
        em_db(0x03);
    } else if elem_size == 4 {
        em_db(0x48);
        em_db(0xC1);
        em_db(0xE0);
        em_db(0x02);
    }
    em_db(0x48);
    em_db(0x83);
    em_db(0xC0);
    em_db(0x10);
    !!! The pack comes from the runtime's pool.
    cg_emit_alloc_rax();
    em_db(0xC7);
    em_db(0x00);
    em_dd(n);
    em_db(0xC7);
    em_db(0x40);
    em_db(0x04);
    em_dd(elem_size);
    em_db(0x48);
    em_db(0xC7);
    em_db(0x40);
    em_db(0x08);
    em_dd(n);
    em_db(0x48);
    em_db(0x83);
    em_db(0xC0);
    em_db(0x10);
    em_st_rsp_rax(base_slot);

    if is_any {
        int i = 0;
        while i < n {
            @CmpExpr a = ce_at(args, start + i);
            int voff = i * 16;
            cg_gen_expr(a);
            em_ld_rsp_rdx(base_slot);
            if a.result_type == FLOAT {
                em_db(0xF2);
                em_db(0x0F);
                em_db(0x11);
                if voff < 128 {
                    em_db(0x42);
                    em_db(voff);
                } else {
                    em_db(0x82);
                    em_dd(voff);
                }
            } else {
                em_db(0x48);
                em_db(0x89);
                if voff < 128 {
                    em_db(0x42);
                    em_db(voff);
                } else {
                    em_db(0x82);
                    em_dd(voff);
                }
            }
            em_mov_rax_imm64((int)a.result_type);
            int toff = voff + 8;
            em_db(0x48);
            em_db(0x89);
            if toff < 128 {
                em_db(0x42);
                em_db(toff);
            } else {
                em_db(0x82);
                em_dd(toff);
            }
            i = i + 1;
        }
    } else {
        int i2 = 0;
        while i2 < n {
            cg_gen_expr(ce_at(args, start + i2));
            em_ld_rsp_rdx(base_slot);
            int off = i2 * elem_size;
            if elem_size == 1 {
                em_db(0x88);
                if off < 128 {
                    em_db(0x42);
                    em_db(off);
                } else {
                    em_db(0x82);
                    em_dd(off);
                }
            } else if elem_size == 4 {
                em_db(0x89);
                if off < 128 {
                    em_db(0x42);
                    em_db(off);
                } else {
                    em_db(0x82);
                    em_dd(off);
                }
            } else {
                em_db(0x48);
                em_db(0x89);
                if off < 128 {
                    em_db(0x42);
                    em_db(off);
                } else {
                    em_db(0x82);
                    em_dd(off);
                }
            }
            i2 = i2 + 1;
        }
    }
    em_ld_rsp(base_slot);
    cg_binop_nesting = saved_nesting;
}

!!! A spread array into the outgoing argument stack: the elements are pushed last
!!! to first, so the first one ends up as the first argument. The stride comes from
!!! the array metadata, so an `any` pack (16-byte cells) and a typed one work alike.
void cg_emit_spread_push -> @CmpExpr arr {
    cg_gen_expr(arr);
    em_db(0x48);
    em_db(0x89);
    em_db(0xC7);
    em_db(0x44);
    em_db(0x8B);
    em_db(0x47);
    em_db(0xF4);
    em_db(0x48);
    em_db(0x8B);
    em_db(0x4F);
    em_db(0xF8);
    em_db(0x48);
    em_db(0x01);
    em_db(0xCE);
    em_db(0x48);
    em_db(0x85);
    em_db(0xC9);
    int jz_done0 = em_jz_rel8();
    int loop = em_tell();
    em_db(0x48);
    em_db(0xFF);
    em_db(0xC9);
    em_db(0x48);
    em_db(0x89);
    em_db(0xCA);
    em_db(0x49);
    em_db(0x0F);
    em_db(0xAF);
    em_db(0xD0);
    em_db(0x48);
    em_db(0x8B);
    em_db(0x04);
    em_db(0x17);
    em_push_rax();
    em_db(0x48);
    em_db(0x85);
    em_db(0xC9);
    int jz_done = em_jz_rel8();
    em_db(0xE9);
    em_dd(loop - (em_tell() + 4));
    em_patch_jz_rel8(jz_done);
    em_patch_jz_rel8(jz_done0);
}
