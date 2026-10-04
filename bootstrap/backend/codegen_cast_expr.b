#once
!~
 ~  bootstrap/backend/codegen_cast_expr.b: cast expressions and the tostr runtime.
 ~
 ~  `(str)`, `(int)`, `(float)` and the
 ~  rest are emitted here, plus the number-to-string routines cmp writes into every
 ~  image, so a conversion does not depend on which library is linked.
 ~!

#head "cg_heads"

!!! The eight bytes of a double, read out through an `@float` block.
longlong cg_dbits -> float d {
    @void cell;
    cg_balloc(@cell, 8);
    @float fp = (@float)cell;
    fp[0] = d;
    @longlong q = (@longlong)cell;
    return q[0];
}

void cg_gen_cast_expr -> @CmpExpr n {
    cg_gen_expr(n.left);
    VarType src = n.left.result_type;

    if pe_eq(n.op, "_toBool") {
        if src == FLOAT {
            em_db(0x66);
            em_db(0x0F);
            em_db(0x2E);
            em_db(0xC0);
        }
        em_test_rax_rax();
        int jz_pos = 0;
        if src == STR {
            !!! A null pointer and an empty string are both false.
            jz_pos = em_jz_rel8();
            em_db(0x80);
            em_db(0x38);
            em_db(0x00);
        }
        em_db(0x0F);
        em_db(0x95);
        em_db(0xC0);
        em_db(0x0F);
        em_db(0xB6);
        em_db(0xC0);
        if src == STR {
            em_patch_jz_rel8(jz_pos);
        }
        end;
    }
    if pe_eq(n.op, "_toChar") {
        if src == FLOAT {
            em_cvttsd2si_xmm0_rax();
        }
        end;
    }
    if pe_eq(n.op, "_toFloat") {
        if src == INT || src == BOOL || src == CHAR || src == LONG {
            em_cvtsi2sd_xmm0_rax();
        }
        end;
    }
    if pe_eq(n.op, "_toInt") {
        if src == FLOAT {
            em_cvttsd2si_xmm0_rax();
        }
        end;
    }
    if pe_eq(n.op, "_toLong") {
        if src == FLOAT {
            em_cvttsd2si_xmm0_rax();
        } else if src == INT {
            em_db(0x48);
            em_db(0x63);
            em_db(0xC0);
        } else if src == CHAR || src == BOOL {
            em_db(0x0F);
            em_db(0xB6);
            em_db(0xC0);
        }
        end;
    }
    if pe_eq(n.op, "_toStr") {
        !!! A str is a pointer to char, so a value that already is a pointer (or an
        !!! `any`, whose slot holds one raw value) is the same thing.
        if src == STR || src == ANY || vt_is_ptr(src) {
            end;
        }
        if src == BOOL {
            em_test_rax_rax();
            int jnz_patch = em_tell();
            em_db(0x75);
            em_db(0x00);
            cg_emit_tostr_buffer_to_r10();
            em_db(0x4C);
            em_db(0x89);
            em_db(0xD7);
            em_db(0xC7);
            em_db(0x07);
            em_db(0x66);
            em_db(0x61);
            em_db(0x6C);
            em_db(0x73);
            em_db(0xC6);
            em_db(0x47);
            em_db(0x04);
            em_db(0x65);
            em_db(0xC6);
            em_db(0x47);
            em_db(0x05);
            em_db(0x00);
            em_db(0x48);
            em_db(0x89);
            em_db(0xF8);
            int jmp_end = em_tell();
            em_db(0xEB);
            em_db(0x00);
            em_put8(jnz_patch + 1, em_tell() - (jnz_patch + 2));
            cg_emit_tostr_buffer_to_r10();
            em_db(0x4C);
            em_db(0x89);
            em_db(0xD7);
            em_db(0xC7);
            em_db(0x07);
            em_db(0x74);
            em_db(0x72);
            em_db(0x75);
            em_db(0x65);
            em_db(0xC6);
            em_db(0x47);
            em_db(0x04);
            em_db(0x00);
            em_db(0x48);
            em_db(0x89);
            em_db(0xF8);
            em_put8(jmp_end + 1, em_tell() - (jmp_end + 2));
            end;
        }
        if src == CHAR {
            cg_emit_tostr_buffer_to_r10();
            em_db(0x41);
            em_db(0x88);
            em_db(0x02);
            em_db(0x41);
            em_db(0xC6);
            em_db(0x42);
            em_db(0x01);
            em_db(0x00);
            em_db(0x4C);
            em_db(0x89);
            em_db(0xD0);
            end;
        }
        cg_emit_tostr_buffer_to_r10();
        int entry = cg_tostr_int_off;
        if src == LONG {
            entry = cg_tostr_long_off;
        } else if src == FLOAT {
            entry = cg_tostr_float_off;
        }
        cg_emit_call_text(entry);
        end;
    }
    if pe_eq(n.op, "@void") || pe_eq(n.op, "@int") || pe_eq(n.op, "@float") ||
       pe_eq(n.op, "@char") || pe_eq(n.op, "@str") || pe_eq(n.op, "@bool") ||
       pe_eq(n.op, "@longlong") {
        end;
    }
}

!!! Point r10 at the next slot of the ring the conversions write into: the index
!!! is read, masked and advanced, so two conversions whose results are both still
!!! needed no longer share one address.
void cg_emit_tostr_buffer_to_r10 {
    int idx_rva = PEW_TEXT_RVA + cg_tostr_idx_off;
    int buf_rva = PEW_TEXT_RVA + cg_tostr_buf_off;
    em_db(0x44);
    em_db(0x8B);
    em_db(0x1D);
    em_dd(0);
    em_put32(em_tell() - 4, idx_rva - (PEW_TEXT_RVA + em_tell()));
    em_db(0x41);
    em_db(0x83);
    em_db(0xE3);
    em_db(kTostrSlots - 1);
    em_db(0x41);
    em_db(0xC1);
    em_db(0xE3);
    em_db(5);
    em_db(0x4C);
    em_db(0x8D);
    em_db(0x15);
    em_dd(0);
    em_put32(em_tell() - 4, buf_rva - (PEW_TEXT_RVA + em_tell()));
    em_db(0x4D);
    em_db(0x01);
    em_db(0xDA);
    em_db(0xFF);
    em_db(0x05);
    em_dd(0);
    em_put32(em_tell() - 4, idx_rva - (PEW_TEXT_RVA + em_tell()));
}

!!! A forward conditional jump whose displacement is patched once the target is
!!! known. Every jump in the runtime below is rel32, so nothing is counted by hand.
int cg_jcc_fwd -> int op2 {
    em_db(0x0F);
    em_db(op2);
    int at = em_tell();
    em_dd(0);
    return at;
}

void cg_patch_here -> int at {
    em_put32(at, em_tell() - (at + 4));
}

void cg_jcc_back -> int op2, int target {
    em_db(0x0F);
    em_db(op2);
    int at = em_tell();
    em_dd(0);
    em_put32(at, target - (at + 4));
}

void cg_jmp_back -> int target {
    em_db(0xE9);
    int at = em_tell();
    em_dd(0);
    em_put32(at, target - (at + 4));
}

!!! The number-to-string conversions. Both entry points take the buffer to fill in
!!! r10 and leave it in rax, and both keep rdi and r10 as well as everything they do
!!! not touch, because the expression around a conversion may still hold those. Only
!!! the volatile scratch registers rax, rcx, rdx, r9 and r11 change.
void cg_emit_tostr_runtime {
    !!! tostr_digits: rax (>= 0) written at [rdi], rdi advanced. No terminator: the
    !!! callers add one. The digits come out of a divide loop backwards, so they are
    !!! collected at the scratch end and copied forward.
    cg_tostr_digits_off = em_tell();
    em_db(0x41);
    em_db(0x53);
    em_db(0x48);
    em_db(0x85);
    em_db(0xC0);
    int d_zero = cg_jcc_fwd(0x84);
    em_db(0x4C);
    em_db(0x8D);
    em_db(0x4F);
    em_db(0x18);
    em_db(0x4D);
    em_db(0x89);
    em_db(0xCB);
    int d_loop = em_tell();
    em_db(0x31);
    em_db(0xD2);
    em_db(0xB9);
    em_dd(10);
    em_db(0x48);
    em_db(0xF7);
    em_db(0xF1);
    em_db(0x80);
    em_db(0xC2);
    em_db(0x30);
    em_db(0x49);
    em_db(0xFF);
    em_db(0xC9);
    em_db(0x41);
    em_db(0x88);
    em_db(0x11);
    em_db(0x48);
    em_db(0x85);
    em_db(0xC0);
    cg_jcc_back(0x85, d_loop);
    int d_copy = em_tell();
    em_db(0x4D);
    em_db(0x39);
    em_db(0xD9);
    int d_done = cg_jcc_fwd(0x83);
    em_db(0x41);
    em_db(0x8A);
    em_db(0x01);
    em_db(0x88);
    em_db(0x07);
    em_db(0x48);
    em_db(0xFF);
    em_db(0xC7);
    em_db(0x49);
    em_db(0xFF);
    em_db(0xC1);
    cg_jmp_back(d_copy);
    cg_patch_here(d_done);
    em_db(0x41);
    em_db(0x5B);
    em_ret();
    cg_patch_here(d_zero);
    em_db(0xC6);
    em_db(0x07);
    em_db(0x30);
    em_db(0x48);
    em_db(0xFF);
    em_db(0xC7);
    em_db(0x41);
    em_db(0x5B);
    em_ret();

    !!! tostr_int: rax = value, r10 = buffer. Two entries, one body: the 32-bit one
    !!! sign-extends what it is given, the 64-bit one leaves rax as it stands.
    cg_tostr_int_off = em_tell();
    em_db(0x57);
    em_db(0x48);
    em_db(0x63);
    em_db(0xC0);
    em_db(0xE9);
    int i_jmp = em_tell();
    em_dd(0);
    cg_tostr_long_off = em_tell();
    em_db(0x57);
    em_put32(i_jmp, em_tell() - (i_jmp + 4));
    em_db(0x4C);
    em_db(0x89);
    em_db(0xD7);
    em_db(0x48);
    em_db(0x85);
    em_db(0xC0);
    int i_pos = cg_jcc_fwd(0x89);
    em_db(0xC6);
    em_db(0x07);
    em_db(0x2D);
    em_db(0x48);
    em_db(0xFF);
    em_db(0xC7);
    em_db(0x48);
    em_db(0xF7);
    em_db(0xD8);
    cg_patch_here(i_pos);
    cg_emit_call_text(cg_tostr_digits_off);
    em_db(0xC6);
    em_db(0x07);
    em_db(0x00);
    em_db(0x4C);
    em_db(0x89);
    em_db(0xD0);
    em_db(0x5F);
    em_ret();

    !!! tostr_float: xmm0 = value, r10 = buffer. |value| * 10^6 + 0.5 becomes an
    !!! integer, which rounds it to six fraction digits in one step.
    cg_tostr_float_off = em_tell();
    em_db(0x57);
    em_db(0x4C);
    em_db(0x89);
    em_db(0xD7);
    em_db(0x66);
    em_db(0x0F);
    em_db(0x57);
    em_db(0xC9);
    em_db(0x66);
    em_db(0x0F);
    em_db(0x2E);
    em_db(0xC8);
    int f_abs = cg_jcc_fwd(0x86);
    em_db(0xC6);
    em_db(0x07);
    em_db(0x2D);
    em_db(0x48);
    em_db(0xFF);
    em_db(0xC7);
    em_db(0x66);
    em_db(0x48);
    em_db(0x0F);
    em_db(0x7E);
    em_db(0xC0);
    em_db(0x48);
    em_db(0xBA);
    em_dq(cg_dbits(0.0) | (0 - 9223372036854775808));
    em_db(0x48);
    em_db(0x31);
    em_db(0xD0);
    em_db(0x66);
    em_db(0x48);
    em_db(0x0F);
    em_db(0x6E);
    em_db(0xC0);
    cg_patch_here(f_abs);
    !!! A value this large scaled by 10^6 would not fit an integer.
    em_mov_rax_imm64(cg_dbits(9223372036854.775808));
    em_db(0x66);
    em_db(0x48);
    em_db(0x0F);
    em_db(0x6E);
    em_db(0xD0);
    em_db(0x66);
    em_db(0x0F);
    em_db(0x2E);
    em_db(0xC2);
    int f_plain = cg_jcc_fwd(0x83);
    em_mov_rax_imm64(cg_dbits(1000000.0));
    em_db(0x66);
    em_db(0x48);
    em_db(0x0F);
    em_db(0x6E);
    em_db(0xC8);
    em_db(0xF2);
    em_db(0x0F);
    em_db(0x59);
    em_db(0xC1);
    em_mov_rax_imm64(cg_dbits(0.5));
    em_db(0x66);
    em_db(0x48);
    em_db(0x0F);
    em_db(0x6E);
    em_db(0xC8);
    em_db(0xF2);
    em_db(0x0F);
    em_db(0x58);
    em_db(0xC1);
    em_db(0xF2);
    em_db(0x48);
    em_db(0x0F);
    em_db(0x2C);
    em_db(0xC0);
    em_cqo();
    em_db(0x48);
    em_db(0xC7);
    em_db(0xC1);
    em_dd(1000000);
    em_db(0x48);
    em_db(0xF7);
    em_db(0xF9);
    em_db(0x49);
    em_db(0x89);
    em_db(0xD3);
    cg_emit_call_text(cg_tostr_digits_off);
    em_db(0xC6);
    em_db(0x07);
    em_db(0x2E);
    em_db(0x48);
    em_db(0xFF);
    em_db(0xC7);
    em_db(0x4C);
    em_db(0x89);
    em_db(0xD8);
    em_db(0xB9);
    em_dd(6);
    em_db(0x4C);
    em_db(0x8D);
    em_db(0x4F);
    em_db(0x06);
    em_db(0x49);
    em_db(0xC7);
    em_db(0xC3);
    em_dd(10);
    int f_frac = em_tell();
    em_db(0x31);
    em_db(0xD2);
    em_db(0x49);
    em_db(0xF7);
    em_db(0xF3);
    em_db(0x80);
    em_db(0xC2);
    em_db(0x30);
    em_db(0x49);
    em_db(0xFF);
    em_db(0xC9);
    em_db(0x41);
    em_db(0x88);
    em_db(0x11);
    em_db(0xFF);
    em_db(0xC9);
    cg_jcc_back(0x85, f_frac);
    em_db(0x48);
    em_db(0x83);
    em_db(0xC7);
    em_db(0x06);
    em_db(0xC6);
    em_db(0x07);
    em_db(0x00);
    em_db(0x4C);
    em_db(0x89);
    em_db(0xD0);
    em_db(0x5F);
    em_ret();
    cg_patch_here(f_plain);
    em_db(0xF2);
    em_db(0x48);
    em_db(0x0F);
    em_db(0x2C);
    em_db(0xC0);
    cg_emit_call_text(cg_tostr_digits_off);
    em_db(0xC6);
    em_db(0x07);
    em_db(0x00);
    em_db(0x4C);
    em_db(0x89);
    em_db(0xD0);
    em_db(0x5F);
    em_ret();
}
