#once
!~
 ~  bootstrap/backend/codegen_binop.b: the binary operators.
 ~
 ~  the comparisons (integer and float, with
 ~  the float family reading only the flags ucomisd sets), the short-circuit forms
 ~  of `&&` and `||`, the bitwise operators, string concatenation and the arithmetic
 ~  ones, with pointer arithmetic scaled by what the pointer points at.
 ~!

#head "cg_heads"

!!! A bit pattern in the upper half of the 32-bit range: `0xC0000094` is written
!!! positively but stands for the int -1073741676. A literal below 2^31 or above
!!! 2^32-1 is a plain value and is left alone, so `-2147483648` (a unary minus, not a
!!! literal) and `0x7FF600000000` (an address) keep their meaning.
bool cg_narrow_int_literal -> @CmpExpr n {
    if n == null || n.nk != LIT_INT {
        return false;
    }
    if n.ptr_depth != 0 || n.result_type != INT {
        return false;
    }
    !!! The two bounds are held in a variable of their own. A literal of that range,
    !!! written beside a comparison, is read as the int bit pattern it spells -
    !!! that is what a comparison does with such a literal, so the constant is
    !!! sign-extended - and `>= 2147483648` came out as `>= -2147483648` while
    !!! `<= 4294967295` came out as `<= -1`: the test then only matched the bit
    !!! patterns that are already negative. the toolchain writes `2147483648LL` and
    !!! `4294967295LL`, which are the positive values.
    longlong lo = 2147483648;
    longlong hi = 4294967295;
    return n.int_val >= lo && n.int_val <= hi;
}

void cg_emit_narrow_int_literal -> @CmpExpr n {
    if !cg_narrow_int_literal(n) {
        end;
    }
    em_db(0x48);
    em_db(0x63);
    em_db(0xC0);
}

!!! The value `cg_small_int_literal` read.
int cg_small_int_literal_out;

!!! A right-hand side that fits in the 32-bit immediate of `cmp rax, imm32` and
!!! means the same as loading it: 0 through 2^31-1. `null`, `true`/`false` and a
!!! character literal are integers of the IR, so they are taken as well. Anything
!!! else - a negative value, which the immediate would sign-extend, and the
!!! 2147483648..4294967295 bit patterns cg_narrow_int_literal is about - keeps the
!!! temporary slot.
bool cg_small_int_literal -> @CmpExpr n {
    if n == null || n.ptr_depth != 0 {
        return false;
    }
    if n.nk == LIT_NULL {
        cg_small_int_literal_out = 0;
        return true;
    }
    if n.nk == LIT_BOOL {
        cg_small_int_literal_out = 0;
        if n.bool_val {
            cg_small_int_literal_out = 1;
        }
        return true;
    }
    if n.nk == LIT_CHAR {
        cg_small_int_literal_out = n.char_val;
        return true;
    }
    if n.nk != LIT_INT {
        return false;
    }
    if n.result_type != INT {
        return false;
    }
    if n.int_val < 0 || n.int_val > 2147483647 {
        return false;
    }
    cg_small_int_literal_out = (int)n.int_val;
    return true;
}

!!! Where the branch `cg_cmp_jump_false` wrote its jump, for the caller to patch.
int cg_cmp_jump_pos;

!!! Whether the right operand of a binary operation is a variable that can be read
!!! straight into rdx: a parameter or a local is one load wherever it is read, so
!!! evaluating it into rax first only to write it to the temporary slot and read it
!!! back costs two instructions for nothing. Anything else - a call, a field, an
!!! index - keeps the temporary slot, because reading it again would mean evaluating
!!! it again. Nothing is emitted here; cg_emit_right_rdx does that, and it has to run
!!! after the left operand, whose own evaluation may use rdx.
bool cg_right_rdx_ok -> @CmpExpr n {
    if n == null || n.nk != VAR_REF {
        return false;
    }
    if !pe_eq(cg_current_func, "") {
        @CgNameOff oit = cg_param_off(cg_current_func, n.var_name);
        if oit != null {
            !!! A float is read into xmm0 and not into a general register.
            return cg_param_type(cg_current_func, n.var_name) != FLOAT;
        }
    }
    @CgVarInfo it = cg_sym_find(n.var_name);
    if it == null {
        return false;
    }
    return it.ty != FLOAT;
}

void cg_emit_right_rdx -> @CmpExpr n {
    if !pe_eq(cg_current_func, "") {
        @CgNameOff oit = cg_param_off(cg_current_func, n.var_name);
        if oit != null {
            !!! A parameter is read with the same wide load cg_gen_expr gives it: the
            !!! caller pushed the whole 64-bit slot, and a four-byte load of it would
            !!! drop the half a pointer or a `longlong` lives in.
            em_ld_rbp_rdx(oit.off);
            end;
        }
    }
    @CgVarInfo it2 = cg_sym_find(n.var_name);
    if it2 != null {
        cg_load_var_rdx(it2.stack_offset, it2.ty, it2.is_array);
    }
}

!!! The operands of an integer comparison, ending in the `cmp` whose flags hold the
!!! answer. Both the comparison itself and a branch on it use this, so the two can
!!! never disagree about what was compared.
void cg_gen_int_cmp -> @CmpExpr n, int temp_off {
    !!! A right side that is a small constant is compared against directly: writing
    !!! it to a temporary slot and reading it back costs three instructions for an
    !!! operand that fits in the instruction itself. The answer is kept in a local of
    !!! its own, because generating the left side may ask about a constant of its own
    !!! and write the shared one.
    bool imm_ok = !cg_nopt_asm && cg_small_int_literal(n.right);
    int imm_val = cg_small_int_literal_out;
    bool rdx_ok = false;
    if !imm_ok && !cg_nopt_reg {
        rdx_ok = cg_right_rdx_ok(n.right);
    }
    if !imm_ok && !rdx_ok {
        cg_gen_expr(n.right);
        cg_emit_narrow_int_literal(n.right);
        em_st_rsp_rax(temp_off);
    }
    cg_gen_expr(n.left);
    cg_emit_narrow_int_literal(n.left);
    if imm_ok {
        em_cmp_rax_imm32(imm_val);
    } else {
        !!! The variable is read after the left operand: the left is what may have
        !!! used rdx, and a load of the right cannot disturb it.
        if rdx_ok {
            cg_emit_right_rdx(n.right);
        } else {
            em_ld_rsp_rdx(temp_off);
        }
        em_db(0x48);
        em_db(0x39);
        em_db(0xD0);
    }
}

!!! A branch on a comparison, answered as the position of the jump in
!!! `cg_cmp_jump_pos`. The flags the comparison left are still valid - `cmp` set
!!! them and nothing else has run since - so the branch is one `jcc` on the opposite
!!! condition instead of the 0/1 value, a test and a jump. False when `n` is not a
!!! comparison this is for, in which case nothing was emitted.
bool cg_cmp_jump_false -> @CmpExpr n {
    !!! -nopt-asm: the caller evaluates the comparison into 0/1 and tests it, which
    !!! is what it does for every condition this does not answer.
    if cg_nopt_asm {
        return false;
    }
    if n == null || n.nk != BINOP {
        return false;
    }
    !!! An operand can be missing: the IR carries a unary form as an operator with
    !!! one side empty, and cg_gen_expr knows how to emit that. Nothing is emitted
    !!! here for such a node, so the caller evaluates it the long way.
    if n.left == null || n.right == null {
        return false;
    }
    if !pe_eq(n.op, "//") && !pe_eq(n.op, "\\\\") && !pe_eq(n.op, "<") &&
       !pe_eq(n.op, ">") && !pe_eq(n.op, "<//") && !pe_eq(n.op, "//=") {
        return false;
    }
    VarType lt = n.left.result_type;
    VarType rt = n.right.result_type;
    if lt == FLOAT || rt == FLOAT {
        return false;
    }
    int temp_off = cg_next_stack_offset + cg_binop_nesting * 8;
    cg_binop_nesting = cg_binop_nesting + 1;
    cg_gen_int_cmp(n, temp_off);
    cg_binop_nesting = cg_binop_nesting - 1;
    if pe_eq(n.op, "//") {
        cg_cmp_jump_pos = em_jne_rel32();
    } else if pe_eq(n.op, "\\\\") {
        cg_cmp_jump_pos = em_jz_rel32();
    } else if pe_eq(n.op, "<") {
        cg_cmp_jump_pos = em_jge_rel32();
    } else if pe_eq(n.op, ">") {
        cg_cmp_jump_pos = em_jle_rel32();
    } else if pe_eq(n.op, "<//") {
        cg_cmp_jump_pos = em_jg_rel32();
    } else {
        cg_cmp_jump_pos = em_jl_rel32();
    }
    return true;
}

void cg_gen_binop -> @CmpExpr n {
    VarType lt = n.left.result_type;
    VarType rt = n.right.result_type;

    !!! The comparisons.
    if pe_eq(n.op, "//") || pe_eq(n.op, "\\\\") || pe_eq(n.op, "<") ||
       pe_eq(n.op, ">") || pe_eq(n.op, "<//") || pe_eq(n.op, "//=") {
        bool use_float_cmp = lt == FLOAT || rt == FLOAT;
        int temp_off = cg_next_stack_offset + cg_binop_nesting * 8;
        cg_binop_nesting = cg_binop_nesting + 1;
        if use_float_cmp {
            cg_gen_expr(n.right);
            if rt != FLOAT {
                em_cvtsi2sd_xmm0_rax();
            }
            em_stsd_rsp(temp_off);
            cg_gen_expr(n.left);
            if lt != FLOAT {
                em_cvtsi2sd_xmm0_rax();
            }
            em_ldsd_rsp_xmm1(temp_off);
            em_db(0x66);
            em_db(0x0F);
            em_db(0x2E);
            em_db(0xC1);
        } else {
            cg_gen_int_cmp(n, temp_off);
        }
        !!! After ucomisd only ZF, PF and CF hold the answer: SF and OF are cleared.
        !!! The signed family reads SF and OF, so on a float it is constant, which
        !!! turns `while x >= 2.0` into a loop that never ends. The unsigned family
        !!! below reads CF and folds the unordered case in with setp/setnp.
        if use_float_cmp {
            if pe_eq(n.op, "//") {
                em_db(0x0F);
                em_db(0x94);
                em_db(0xC0);
                em_db(0x0F);
                em_db(0x9B);
                em_db(0xC1);
                em_db(0x20);
                em_db(0xC8);
            } else if pe_eq(n.op, "\\\\") {
                em_db(0x0F);
                em_db(0x95);
                em_db(0xC0);
                em_db(0x0F);
                em_db(0x9A);
                em_db(0xC1);
                em_db(0x08);
                em_db(0xC8);
            } else if pe_eq(n.op, "<") {
                em_db(0x0F);
                em_db(0x92);
                em_db(0xC0);
                em_db(0x0F);
                em_db(0x9B);
                em_db(0xC1);
                em_db(0x20);
                em_db(0xC8);
            } else if pe_eq(n.op, ">") {
                em_db(0x0F);
                em_db(0x97);
                em_db(0xC0);
            } else if pe_eq(n.op, "<//") {
                em_db(0x0F);
                em_db(0x96);
                em_db(0xC0);
                em_db(0x0F);
                em_db(0x9B);
                em_db(0xC1);
                em_db(0x20);
                em_db(0xC8);
            } else if pe_eq(n.op, "//=") {
                em_db(0x0F);
                em_db(0x93);
                em_db(0xC0);
            }
        } else {
            if pe_eq(n.op, "//") {
                em_db(0x0F);
                em_db(0x94);
                em_db(0xC0);
            } else if pe_eq(n.op, "\\\\") {
                em_db(0x0F);
                em_db(0x95);
                em_db(0xC0);
            } else if pe_eq(n.op, "<") {
                em_db(0x0F);
                em_db(0x9C);
                em_db(0xC0);
            } else if pe_eq(n.op, ">") {
                em_db(0x0F);
                em_db(0x9F);
                em_db(0xC0);
            } else if pe_eq(n.op, "<//") {
                em_db(0x0F);
                em_db(0x9E);
                em_db(0xC0);
            } else if pe_eq(n.op, "//=") {
                em_db(0x0F);
                em_db(0x9D);
                em_db(0xC0);
            }
        }
        em_db(0x0F);
        em_db(0xB6);
        em_db(0xC0);
        cg_binop_nesting = cg_binop_nesting - 1;
        end;
    }

    !!! The short-circuit forms. The jump over the right operand has to be a rel32
    !!! one: the operand can expand to far more than the 127 bytes a rel8 reaches.
    if pe_eq(n.op, "&&") {
        cg_binop_nesting = cg_binop_nesting + 1;
        cg_gen_expr(n.left);
        em_test_rax_rax();
        int jz_zero = em_jz_rel32();
        cg_gen_expr(n.right);
        em_test_rax_rax();
        em_db(0x0F);
        em_db(0x95);
        em_db(0xC0);
        em_db(0x0F);
        em_db(0xB6);
        em_db(0xC0);
        int jmp_end = em_jmp_rel32();
        em_patch_jz_rel32(jz_zero);
        em_mov_rax_imm64(0);
        em_patch_jmp_rel32(jmp_end);
        cg_binop_nesting = cg_binop_nesting - 1;
        end;
    }
    if pe_eq(n.op, "||") {
        cg_binop_nesting = cg_binop_nesting + 1;
        cg_gen_expr(n.left);
        em_test_rax_rax();
        int jnz_true = em_jnz_rel32();
        cg_gen_expr(n.right);
        em_test_rax_rax();
        em_db(0x0F);
        em_db(0x95);
        em_db(0xC0);
        em_db(0x0F);
        em_db(0xB6);
        em_db(0xC0);
        int jmp_end2 = em_jmp_rel32();
        em_patch_jnz_rel32(jnz_true);
        em_mov_rax_imm64(1);
        em_patch_jmp_rel32(jmp_end2);
        cg_binop_nesting = cg_binop_nesting - 1;
        end;
    }

    !!! The bitwise operators.
    if pe_eq(n.op, "&") || pe_eq(n.op, "|") || pe_eq(n.op, "^") {
        cg_binop_nesting = cg_binop_nesting + 1;
        cg_gen_expr(n.right);
        em_st_rsp_rax(cg_next_stack_offset + (cg_binop_nesting - 1) * 8);
        cg_gen_expr(n.left);
        em_ld_rsp_rdx(cg_next_stack_offset + (cg_binop_nesting - 1) * 8);
        if pe_eq(n.op, "&") {
            em_db(0x48);
            em_db(0x21);
            em_db(0xD0);
        } else if pe_eq(n.op, "|") {
            em_db(0x48);
            em_db(0x09);
            em_db(0xD0);
        } else if pe_eq(n.op, "^") {
            em_db(0x48);
            em_db(0x31);
            em_db(0xD0);
        }
        cg_binop_nesting = cg_binop_nesting - 1;
        end;
    }

    !!! String concatenation goes through the library.
    if pe_eq(n.op, "+") && lt == STR && rt == STR {
        cg_gen_expr(n.right);
        em_push_rax();
        cg_gen_expr(n.left);
        em_push_rax();
        cg_emit_call_lib("_str_concat");
        em_add_rsp_imm8(16);
        end;
    }

    int temp_off = cg_next_stack_offset + cg_binop_nesting * 8;
    cg_binop_nesting = cg_binop_nesting + 1;
    bool use_float = lt == FLOAT || rt == FLOAT;
    if use_float {
        cg_gen_expr(n.right);
        if rt != FLOAT {
            em_cvtsi2sd_xmm0_rax();
        }
        em_stsd_rsp(temp_off);
        cg_gen_expr(n.left);
        if lt != FLOAT {
            em_cvtsi2sd_xmm0_rax();
        }
        em_ldsd_rsp_xmm1(temp_off);
        if pe_eq(n.op, "+") {
            em_addsd_xmm0_xmm1();
        } else if pe_eq(n.op, "-") {
            em_subsd_xmm0_xmm1();
        } else if pe_eq(n.op, "*") {
            em_mulsd_xmm0_xmm1();
        } else if pe_eq(n.op, "/") {
            em_divsd_xmm0_xmm1();
        }
    } else {
        !!! `x = x + 1` and `x = x - 1` are loop counters and index steps almost
        !!! everywhere, and a small constant on the right is an operand of the
        !!! instruction itself: loading it into a temporary slot first costs three
        !!! instructions of the five the whole statement needs. A pointer on the
        !!! left is left out, because the operand would have to be scaled by the
        !!! pointee size the pointer names.
        bool imm_arith_ok = false;
        int imm_arith = 0;
        if !cg_nopt_asm && (pe_eq(n.op, "+") || pe_eq(n.op, "-")) {
            if !vt_is_ptr(lt) {
                imm_arith_ok = cg_small_int_literal(n.right);
                imm_arith = cg_small_int_literal_out;
            }
        }
        if imm_arith_ok {
            cg_gen_expr(n.left);
            cg_emit_narrow_int_literal(n.left);
            if pe_eq(n.op, "+") {
                em_add_rax_imm32(imm_arith);
            } else {
                em_sub_rax_imm32(imm_arith);
            }
            cg_binop_nesting = cg_binop_nesting - 1;
            end;
        }
        !!! A right side that is a variable is read into rdx where it lives: the
        !!! temporary slot it would otherwise go through is two instructions of
        !!! nothing on every `x + y`, `i * n` and `p + off` of the input. The read
        !!! comes after the left operand, whose own evaluation may use rdx.
        if !cg_nopt_reg && cg_right_rdx_ok(n.right) {
            cg_gen_expr(n.left);
            cg_emit_right_rdx(n.right);
            if (pe_eq(n.op, "+") || pe_eq(n.op, "-")) && vt_is_ptr(lt) {
                int ps2 = vt_pointee_size(lt);
                if ps2 == 8 {
                    em_db(0x48);
                    em_db(0xC1);
                    em_db(0xE2);
                    em_db(0x03);
                } else if ps2 == 4 {
                    em_db(0x48);
                    em_db(0xC1);
                    em_db(0xE2);
                    em_db(0x02);
                }
            }
            if pe_eq(n.op, "+") {
                em_add_rax_rdx();
            } else if pe_eq(n.op, "-") {
                em_sub_rax_rdx();
            } else if pe_eq(n.op, "*") {
                em_imul_rax_rdx();
            } else if pe_eq(n.op, "/") || pe_eq(n.op, "%") {
                em_db(0x48);
                em_db(0x87);
                em_db(0xC2);
                em_mov_rcx_rax();
                em_db(0x48);
                em_db(0x87);
                em_db(0xC2);
                em_cqo();
                em_idiv_rcx();
                if pe_eq(n.op, "%") {
                    em_db(0x48);
                    em_db(0x89);
                    em_db(0xD0);
                }
            }
            cg_binop_nesting = cg_binop_nesting - 1;
            end;
        }
        cg_gen_expr(n.right);
        em_st_rsp_rax(temp_off);
        cg_gen_expr(n.left);
        em_ld_rsp_rdx(temp_off);
        !!! Pointer arithmetic scales the index by what the pointer points at.
        if (pe_eq(n.op, "+") || pe_eq(n.op, "-")) && vt_is_ptr(lt) {
            int ps = vt_pointee_size(lt);
            if ps == 8 {
                em_db(0x48);
                em_db(0xC1);
                em_db(0xE2);
                em_db(0x03);
            } else if ps == 4 {
                em_db(0x48);
                em_db(0xC1);
                em_db(0xE2);
                em_db(0x02);
            }
        }
        if pe_eq(n.op, "+") {
            em_add_rax_rdx();
        } else if pe_eq(n.op, "-") {
            em_sub_rax_rdx();
        } else if pe_eq(n.op, "*") {
            em_imul_rax_rdx();
        } else if pe_eq(n.op, "/") {
            em_db(0x48);
            em_db(0x87);
            em_db(0xC2);
            em_mov_rcx_rax();
            em_db(0x48);
            em_db(0x87);
            em_db(0xC2);
            em_cqo();
            em_idiv_rcx();
        } else if pe_eq(n.op, "%") {
            em_db(0x48);
            em_db(0x87);
            em_db(0xC2);
            em_mov_rcx_rax();
            em_db(0x48);
            em_db(0x87);
            em_db(0xC2);
            em_cqo();
            em_idiv_rcx();
            em_db(0x48);
            em_db(0x89);
            em_db(0xD0);
        }
    }
    cg_binop_nesting = cg_binop_nesting - 1;
}
