#once
!~
 ~  bootstrap/backend/codegen_flow.b: SWITCH, DREF and the subscript.
 ~
 ~  and
 ~
 ~  A switch is emitted as a one-trip loop: the value and an "already matched" flag
 ~  live in two temporary slots reserved for the whole switch, every arm compares
 ~  the value (unless an earlier arm matched, which is a fallthrough) and runs its
 ~  body, and `skip` leaves through the loop's own break stack.
 ~!

#head "cg_heads"

bool cg_gen_switch -> @CmpStmt s {
    !!! The scratch of the switch value and the matched flag, reserved for the whole
    !!! switch from the frame-relative temporary pool. Moving rsp by 16 bytes
    !!! instead shifted every temporary used inside an arm onto the function's own
    !!! locals, and a comparison inside a switch overwrote its own operand.
    int saved_nesting = cg_binop_nesting;
    int sw_value = cg_next_stack_offset + cg_binop_nesting * 8;
    int sw_matched = sw_value + 8;
    cg_binop_nesting = cg_binop_nesting + 2;

    cg_gen_expr(s.init_expr);
    !!! `switch (0xC0000094)` and `case 0xC0000094:` spell an int as a bit pattern;
    !!! narrowing it makes both sides compare as the value the program holds.
    cg_emit_narrow_int_literal(s.init_expr);
    em_st_rsp_rax(sw_value);
    em_mov_rax_imm64(0);
    em_st_rsp_rax(sw_matched);

    @CmpIntNode saved_breaks = cg_break_stack;
    cg_break_stack = null;
    int loop_start = em_tell();
    cg_continue_targets = cg_int_push(cg_continue_targets, loop_start);
    em_db(0x48);
    em_db(0xC7);
    em_db(0xC0);
    em_dd(1);
    em_test_rax_rax();
    int jz_end = em_jz_rel32();

    @CmpCaseBody arms = cs_cases_of(s);
    int n = cc_n(arms);
    int i = 0;
    while i < n {
        @CmpCaseBody arm = cc_at(arms, i);
        !!! An arm an earlier one already matched falls straight into its body.
        em_ld_rsp(sw_matched);
        em_test_rax_rax();
        int jnz_do_body = em_jnz_rel32();
        em_ld_rsp(sw_value);
        em_db(0x48);
        em_db(0x89);
        em_db(0xC3);
        @CmpExpr ce = ce_at(s.case_exprs, i);
        cg_gen_expr(ce);
        cg_emit_narrow_int_literal(ce);
        em_db(0x48);
        em_db(0x39);
        em_db(0xC3);
        int jne_skip_body = em_jne_rel32();
        em_mov_rax_imm64(1);
        em_st_rsp_rax(sw_matched);
        em_patch_jnz_rel32(jnz_do_body);
        if !cg_gen_block(arm.body) {
            cg_binop_nesting = saved_nesting;
            cg_break_stack = saved_breaks;
            return false;
        }
        int jmp_end_case = em_jmp_rel32();
        em_patch_jne_rel32(jne_skip_body);
        em_patch_jmp_rel32(jmp_end_case);
        i = i + 1;
    }

    if s.unmatch_body != null {
        em_ld_rsp(sw_matched);
        em_test_rax_rax();
        int jnz_skip_unmatch = em_jnz_rel32();
        if !cg_gen_block(s.unmatch_body) {
            cg_binop_nesting = saved_nesting;
            cg_break_stack = saved_breaks;
            return false;
        }
        em_patch_jnz_rel32(jnz_skip_unmatch);
    }

    !!! The END of the wrapper loop.
    int pos = em_jmp_rel32();
    cg_break_stack = cn_int(cg_break_stack, pos);
    em_patch_jz_rel32(jz_end);
    @CmpIntNode bp = cg_break_stack;
    while bp != null {
        em_patch_jmp_rel32((int)bp.v);
        bp = bp.next;
    }
    cg_break_stack = saved_breaks;
    cg_continue_targets = cg_int_pop(cg_continue_targets);
    cg_binop_nesting = saved_nesting;
    return true;
}

!!! `DREF ptr, value`: the value is stored where the pointer aims. A parameter
!!! lives at [rbp+off] and not in the symbol table.
bool cg_gen_dref -> @CmpStmt s {
    VarType addr_type = AT_INT;
    bool is_param = false;
    int rbp_off = 0;
    if !pe_eq(cg_current_func, "") {
        @CgNameOff po = cg_param_off(cg_current_func, s.var_name);
        if po != null {
            is_param = true;
            rbp_off = po.off;
            addr_type = cg_param_type(cg_current_func, s.var_name);
        }
    }
    if is_param {
        em_ld_rbp(rbp_off);
        em_push_rax();
        cg_gen_expr(s.init_expr);
        em_pop_rcx();
    } else {
        @CgVarInfo it = cg_sym_find(s.var_name);
        if it == null {
            cg_stmt_err = cg_err_at(s.line, s.col,
                                    "DREF: undefined variable '" + s.var_name + "'");
            return false;
        }
        addr_type = it.ty;
        cg_load_var(it.stack_offset, addr_type, it.is_array, false);
        em_push_rax();
        cg_gen_expr(s.init_expr);
        em_pop_rcx();
    }
    if addr_type == AT_FLOAT {
        em_db(0xF2);
        em_db(0x0F);
        em_db(0x11);
        em_db(0x01);
    } else if addr_type == AT_INT {
        em_db(0x89);
        em_db(0x01);
    } else if addr_type == AT_CHAR || addr_type == AT_BOOL {
        em_db(0x88);
        em_db(0x01);
    } else {
        em_db(0x48);
        em_db(0x89);
        em_db(0x01);
    }
    return true;
}

!!! `p[i]` and `s[i]`: the element of a block, with the index scaled by the size of
!!! what the pointer points at. A `str` is read inline: the byte at the string's
!!! address plus the index.
void cg_gen_array_access -> @CmpExpr n {
    bool is_param = false;
    int param_off = 0;
    VarType param_type = INT;
    if !pe_eq(cg_current_func, "") {
        @CgNameOff po = cg_param_off(cg_current_func, n.var_name);
        if po != null {
            is_param = true;
            param_off = po.off;
            param_type = cg_param_type(cg_current_func, n.var_name);
            if param_type == STR {
                !!! `s[i]`: the byte at the address the string starts at plus the
                !!! index, in line. It used to call the runtime's _str_idx, which
                !!! is a DLL call per character of every source file the compiler
                !!! reads - a tenth of the front end's time. -nopt-asm asks for that
                !!! call back, and the code it replaces is kept as it was for the
                !!! case where a program links no runtime and has no _str_idx.
                if cg_nopt_asm && cg_has_lib_sym("_str_idx") {
                    int temp = cg_next_stack_offset + cg_binop_nesting * 8;
                    cg_binop_nesting = cg_binop_nesting + 1;
                    em_ld_rbp(param_off);
                    em_st_rsp_rax(temp);
                    cg_gen_expr(n.left);
                    em_db(0x48);
                    em_db(0x89);
                    em_db(0xC2);
                    em_ld_rsp(temp);
                    cg_emit_call_lib("_str_idx");
                    cg_binop_nesting = cg_binop_nesting - 1;
                    end;
                }
                if !cg_nopt_asm {
                    int temp = cg_next_stack_offset + cg_binop_nesting * 8;
                    cg_binop_nesting = cg_binop_nesting + 1;
                    em_ld_rbp(param_off);
                    em_st_rsp_rax(temp);
                    cg_gen_expr(n.left);
                    em_ld_rsp_rdx(temp);
                    !!! movzx eax, byte [rdx+rax]: the runtime read the byte into a
                    !!! `char`, which the caller reads zero-extended.
                    em_db(0x0F);
                    em_db(0xB6);
                    em_db(0x04);
                    em_db(0x02);
                    cg_binop_nesting = cg_binop_nesting - 1;
                    end;
                }
            }
        }
    }

    @CgVarInfo it = cg_sym_find(n.var_name);
    !!! A `@T` parameter holds the address to subscript: `p[i]` through a `@char p`
    !!! parameter reads the byte at p + i. Only `{}` array parameters are in `syms`,
    !!! so a pointer parameter used to fall through to the missing-symbol default
    !!! and quietly return 0.
    bool param_ptr = is_param && vt_is_ptr(param_type);
    if it == null && !param_ptr {
        em_db(0x48);
        em_db(0x31);
        em_db(0xC0);
        end;
    }
    int off = it.stack_offset;
    VarType base_type = it.ty;
    bool base_is_array = it.is_array;
    if param_ptr {
        off = param_off;
        base_type = param_type;
        base_is_array = false;
    }

    int es = 8;
    if base_is_array {
        if base_type == CHAR || base_type == BOOL {
            es = 1;
        } else if base_type == INT {
            es = 4;
        } else if base_type == ANY {
            es = 16;
        }
    } else {
        !!! A raw pointer is subscripted by what it points at: `@char p; p[i]` has to
        !!! move one byte and load one byte, and `@int p; p[i]` moves four.
        if base_type == AT_CHAR || base_type == AT_BOOL {
            es = 1;
        } else if base_type == AT_INT {
            es = 4;
        }
    }

    if base_type == STR && !base_is_array {
        !!! String indexing: s[0] -> the byte at the string's address plus the
        !!! index, in line. It used to call the runtime's _str_idx, which is a DLL
        !!! call per character of every source file the compiler reads - a tenth
        !!! of the front end's time. -nopt-asm asks for the call back (see the
        !!! parameter case above).
        if cg_nopt_asm && cg_has_lib_sym("_str_idx") {
            int temp = cg_next_stack_offset + cg_binop_nesting * 8;
            cg_binop_nesting = cg_binop_nesting + 1;
            cg_load_var(off, base_type, false, false);
            em_st_rsp_rax(temp);
            cg_gen_expr(n.left);
            em_db(0x48);
            em_db(0x89);
            em_db(0xC2);
            em_ld_rsp(temp);
            cg_emit_call_lib("_str_idx");
            cg_binop_nesting = cg_binop_nesting - 1;
            end;
        }
        if !cg_nopt_asm {
            int temp = cg_next_stack_offset + cg_binop_nesting * 8;
            cg_binop_nesting = cg_binop_nesting + 1;
            cg_load_var(off, base_type, false, false);
            em_st_rsp_rax(temp);
            cg_gen_expr(n.left);
            em_ld_rsp_rdx(temp);
            !!! movzx eax, byte [rdx+rax]: the runtime read the byte into a `char`,
            !!! which the caller reads zero-extended.
            em_db(0x0F);
            em_db(0xB6);
            em_db(0x04);
            em_db(0x02);
            cg_binop_nesting = cg_binop_nesting - 1;
            end;
        }
    }

    int temp = cg_next_stack_offset + cg_binop_nesting * 8;
    cg_binop_nesting = cg_binop_nesting + 1;
    if param_ptr {
        em_ld_rbp(off);
    } else {
        cg_load_var(off, base_type, base_is_array, false);
    }
    em_st_rsp_rax(temp);
    cg_gen_expr(n.left);
    em_db(0x48);
    em_db(0x89);
    em_db(0xC1);
    !!! Bounds: an array carries its count at [data-8], and an index past it reads
    !!! through NULL so the fault is the program's own. A raw pointer has no header
    !!! (it came from malloc/VirtualAlloc), so there is nothing to compare against.
    bool is_raw_ptr = vt_is_ptr(base_type);
    if !is_raw_ptr {
        em_ld_rsp(temp);
        em_db(0x48);
        em_db(0x3B);
        em_db(0x48);
        em_db(0xF8);
        em_db(0x72);
        em_db(0x06);
        em_db(0x48);
        em_db(0x31);
        em_db(0xC0);
        em_db(0x48);
        em_db(0x8B);
        em_db(0x00);
    }
    em_ld_rsp(temp);
    if es == 16 {
        em_db(0x48);
        em_db(0xC1);
        em_db(0xE1);
        em_db(0x04);
    } else if es == 8 {
        em_db(0x48);
        em_db(0xC1);
        em_db(0xE1);
        em_db(0x03);
    } else if es == 4 {
        em_db(0x48);
        em_db(0xC1);
        em_db(0xE1);
        em_db(0x02);
    }
    em_db(0x48);
    em_db(0x01);
    em_db(0xC8);
    if es == 1 {
        em_db(0x0F);
        em_db(0xB6);
        em_db(0x00);
    } else if es == 4 {
        em_db(0x48);
        em_db(0x63);
        em_db(0x00);
    } else if base_is_array && base_type == FLOAT {
        em_db(0xF2);
        em_db(0x0F);
        em_db(0x10);
        em_db(0x00);
    } else {
        em_db(0x48);
        em_db(0x8B);
        em_db(0x00);
    }
    cg_binop_nesting = cg_binop_nesting - 1;
}
