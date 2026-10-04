#once
!~
 ~  bootstrap/backend/codegen_bspread.b: BSPREAD and the indirect call.
 ~
 ~  and backend/codegen_icall.
 ~
 ~  BSPREAD walks a variadic array and calls a single-argument builtin once per
 ~  element, with the value and its type tag pushed in the library's order. The
 ~  indirect call goes through a closure object: the captures are pushed after the
 ~  explicit arguments, and the code address is read out of the object.
 ~!

#head "cg_heads"

bool cg_gen_bspread -> @CmpStmt s {
    if !cg_has_lib_sym(s.call_name) {
        if s.line <= 0 || s.col <= 0 {
            cg_report_undefined_ref(s.call_name);
        } else {
            cg_link_errors = cn_str(cg_link_errors,
                                    cg_err_at(s.line, s.col,
                                              "undefined reference to '" + s.call_name + "'"));
        }
        if s.init_expr != null {
            cg_gen_expr(s.init_expr);
        }
        em_db(0x31);
        em_db(0xC0);
        return true;
    }
    if s.init_expr == null {
        cg_stmt_err = cg_err_at(s.line, s.col, "BSPREAD: missing array expression");
        return false;
    }
    em_db(0x53);
    em_db(0x56);
    em_db(0x41);
    em_db(0x54);
    cg_gen_expr(s.init_expr);
    em_db(0x48);
    em_db(0x89);
    em_db(0xC3);
    em_db(0x44);
    em_db(0x8B);
    em_db(0x63);
    em_db(0xF4);
    em_db(0x48);
    em_db(0x8B);
    em_db(0x73);
    em_db(0xF8);
    em_db(0x48);
    em_db(0x85);
    em_db(0xF6);
    int jz_done = em_jz_rel8();
    int loop = em_tell();
    em_db(0x48);
    em_db(0x8B);
    em_db(0x03);
    if s.spread_tag >= 0 {
        em_db(0x6A);
        em_db(s.spread_tag);
    } else {
        em_db(0x4C);
        em_db(0x8B);
        em_db(0x4B);
        em_db(0x08);
        em_db(0x41);
        em_db(0x51);
    }
    em_db(0x50);
    cg_emit_call_lib(s.call_name);
    em_db(0x48);
    em_db(0x83);
    em_db(0xC4);
    em_db(0x10);
    em_db(0x4C);
    em_db(0x01);
    em_db(0xE3);
    em_db(0x48);
    em_db(0xFF);
    em_db(0xCE);
    em_db(0x48);
    em_db(0x85);
    em_db(0xF6);
    int jnz_pos = em_tell();
    em_db(0x75);
    em_db(0x00);
    em_put8(jnz_pos + 1, loop - (jnz_pos + 2));
    em_patch_jz_rel8(jz_done);
    em_db(0x41);
    em_db(0x5C);
    em_db(0x5E);
    em_db(0x5B);
    return true;
}

!!! An indirect call through a closure object, or through a raw `@func` address.
void cg_emit_icall -> @CmpExpr target, @CmpExpr call_args {
    int M = ce_n(call_args);
    if target.result_type == AT_FUNC {
        cg_gen_expr(target);
        em_db(0x48);
        em_db(0x89);
        em_db(0xC3);
        em_db(0x56);
        em_db(0x57);
        em_db(0x31);
        em_db(0xF6);
        int i = M - 1;
        while i >= 0 {
            @CmpExpr a = ce_at(call_args, i);
            if a.nk == SPREAD {
                cg_emit_spread_push(a.left);
            } else {
                cg_gen_expr(a);
                if a.result_type == FLOAT {
                    em_sub_rsp_imm8(8);
                    em_movsd_mem_rsp_disp8_xmm0(0);
                } else {
                    em_push_rax();
                }
                em_db(0x48);
                em_db(0xFF);
                em_db(0xC6);
            }
            i = i - 1;
        }
        em_mov_rcx_mem_rsp_disp8(0);
        em_mov_rdx_mem_rsp_disp8(8);
        em_mov_r8_mem_rsp_disp8(16);
        em_mov_r9_mem_rsp_disp8(24);
        em_db(0x48);
        em_db(0x8B);
        em_db(0xC3);
        em_call_rax();
        em_db(0x48);
        em_db(0xC1);
        em_db(0xE6);
        em_db(0x03);
        em_db(0x48);
        em_db(0x01);
        em_db(0xF4);
        em_db(0x5F);
        em_db(0x5E);
        end;
    }
    cg_gen_expr(target);
    em_db(0x48);
    em_db(0x89);
    em_db(0xC3);
    em_db(0x56);
    em_db(0x57);
    em_db(0x31);
    em_db(0xF6);
    int i = M - 1;
    while i >= 0 {
        @CmpExpr a = ce_at(call_args, i);
        if a.nk == SPREAD {
            cg_emit_spread_push(a.left);
        } else {
            cg_gen_expr(a);
            if a.result_type == FLOAT {
                em_sub_rsp_imm8(8);
                em_movsd_mem_rsp_disp8_xmm0(0);
            } else {
                em_push_rax();
            }
            em_db(0x48);
            em_db(0xFF);
            em_db(0xC6);
        }
        i = i - 1;
    }
    !!! rcx = the capture count, rdx = the last capture slot.
    em_db(0x48);
    em_db(0x8B);
    em_db(0x4B);
    em_db(0x10);
    em_db(0x48);
    em_db(0x89);
    em_db(0xD8);
    em_db(0x48);
    em_db(0x89);
    em_db(0xC2);
    em_db(0x48);
    em_db(0x83);
    em_db(0xC2);
    em_db(0x18);
    em_db(0x48);
    em_db(0xC1);
    em_db(0xE1);
    em_db(0x03);
    em_db(0x48);
    em_db(0x01);
    em_db(0xCA);
    em_db(0x48);
    em_db(0x8B);
    em_db(0x4B);
    em_db(0x10);
    !!! The captures in reverse order, so the first one ends up on top.
    int loop_start = em_tell();
    em_db(0x48);
    em_db(0x85);
    em_db(0xC9);
    int jz_done = em_jz_rel32();
    em_db(0x48);
    em_db(0x8B);
    em_db(0x02);
    em_push_rax();
    em_db(0x48);
    em_db(0x83);
    em_db(0xEA);
    em_db(0x08);
    em_db(0x48);
    em_db(0xFF);
    em_db(0xC9);
    em_db(0xE9);
    em_dd(loop_start - (em_tell() + 4));
    em_patch_jz_rel32(jz_done);
    em_mov_rcx_mem_rsp_disp8(0);
    em_mov_rdx_mem_rsp_disp8(8);
    em_mov_r8_mem_rsp_disp8(16);
    em_mov_r9_mem_rsp_disp8(24);
    em_db(0x48);
    em_db(0x8B);
    em_db(0x43);
    em_db(0x08);
    em_call_rax();
    !!! Give the argument stack back: the captures plus the explicit arguments.
    em_db(0x48);
    em_db(0x8B);
    em_db(0x4B);
    em_db(0x10);
    em_db(0x48);
    em_db(0x01);
    em_db(0xF1);
    em_db(0x48);
    em_db(0xC1);
    em_db(0xE1);
    em_db(0x03);
    em_db(0x48);
    em_db(0x01);
    em_db(0xCC);
    em_db(0x5F);
    em_db(0x5E);
}

bool cg_gen_icall -> @CmpStmt s {
    cg_emit_icall(s.init_expr, s.args);
    return true;
}
