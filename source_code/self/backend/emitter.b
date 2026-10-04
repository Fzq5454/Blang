#once
!~
 ~  bootstrap/backend/emitter.b: the x86-64 machine-code emitter.
 ~
 ~  It is the backend/x64_emitter, backend/x64_emitter,
 ~  and backend/x64_emitter_jmp: the byte buffer the
 ~  code is written into, the instruction writers, and the two ways a slot is
 ~  addressed inside a function.
 ~
 ~  the toolchain keeps the bytes in a a chain member of the emitter and the frame
 ~  base in two members. Here the buffer is a global that grows by doubling
 ~  (`CmpBuf`, the same shape as the frontend's TextBuf, which is its only user) and
 ~  the frame base is two globals as well.
 ~
 ~  A temporary slot is addressed off a base that never moves, because rsp is not
 ~  fixed while a statement is generated: call arguments are pushed one by one while
 ~  the remaining argument expressions are still being evaluated, and a switch keeps
 ~  scratch storage across its whole body. A temporary held at [rsp + n] would move
 ~  under the expression that uses it and land on the function's own locals.
 ~    em_temp_base 0 -> plain [rsp + n] (no frame active)
 ~    em_temp_base 1 -> [rbp + n + em_temp_bias] (inside a function body)
 ~    em_temp_base 2 -> [rip + em_globals_off + n + em_temp_bias] (entry scope)
 ~!

#head "stdsrt"
#head "cmp_text"

!!! The bytes written so far. `cmd` is the assembler of the project, so the
!!! instruction writers below name themselves after their mnemonic and the buffer
!!! is reached through the functions that take it.
type CmpBuf {
    @char data;
    int len;
    int cap;
};

@CmpBuf em_buf;

void em_buf_new {
    CmpBuf proto;
    @CmpBuf b;
    malloc(@b, size proto);
    b.data = null;
    b.len = 0;
    b.cap = 0;
    em_buf = b;
}

void em_reserve -> int need {
    if em_buf.len + need <= em_buf.cap {
        end;
    }
    int want = em_buf.cap * 2;
    if want < em_buf.len + need {
        want = em_buf.len + need;
    }
    if want < 64 {
        want = 64;
    }
    @void cell;
    malloc(@cell, want);
    @char nb = (@char)cell;
    @char src = em_buf.data;
    int i = 0;
    while i < em_buf.len {
        nb[i] = src[i];
        i = i + 1;
    }
    @char old = em_buf.data;
    if em_buf.cap > 0 {
        unlink(@old);
    }
    em_buf.data = nb;
    em_buf.cap = want;
}

!!! The block is the buffer's own storage: it is handed on to `em_buf` and released
!!! when the buffer grows again, so the `malloc`/`unlink` pairing check of `stdsrt`
!!! reads the allocation here as an unpaired one. `NOWARN` keeps that report - and
!!! every other warning about this body - out of the build.
attribute em_reserve: NOWARN

!!! The frame base a temporary slot is addressed off, and the distance from that
!!! base down to the frame base.
int em_temp_base;
int em_temp_bias;

!!! The image block the entry-scope slots live in, which the rip-relative form
!!! reaches without a base register. A base register would be module-private state
!!! in a shared register: the caller's entry prologue would set it for its own
!!! module, and a DLL called from an exe, or a callback user32 makes into a DLL,
!!! would then read the wrong block.
int em_globals_off;

int em_tell {
    return em_buf.len;
}

void em_db -> int v {
    !!! The room for one byte is checked here and the grow is asked for only when
    !!! there is none: every byte of the image costs this call, and asking
    !!! em_reserve first made it two calls for the same answer.
    if em_buf.len >= em_buf.cap {
        em_reserve(1);
    }
    @char d = em_buf.data;
    d[em_buf.len] = (char)v;
    em_buf.len = em_buf.len + 1;
}

!!! One byte at a position already written, for a rel8 displacement filled in by
!!! hand (the jump back to a loop label).
void em_put8 -> int pos, int v {
    @char d = em_buf.data;
    d[pos] = (char)v;
}

!!! Four bytes, little endian: what the `w32` writes.
void em_put32 -> int pos, int v {
    @char d = em_buf.data;
    d[pos] = (char)(v & 255);
    d[pos + 1] = (char)((v >> 8) & 255);
    d[pos + 2] = (char)((v >> 16) & 255);
    d[pos + 3] = (char)((v >> 24) & 255);
}

void em_dd -> int v {
    if em_buf.len + 4 > em_buf.cap {
        em_reserve(4);
    }
    em_put32(em_buf.len, v);
    em_buf.len = em_buf.len + 4;
}

!!! Eight bytes, little endian.
void em_dq -> longlong v {
    if em_buf.len + 8 > em_buf.cap {
        em_reserve(8);
    }
    @char d = em_buf.data;
    int pos = em_buf.len;
    int i = 0;
    while i < 8 {
        d[pos + i] = (char)((v >> (i * 8)) & 255);
        i = i + 1;
    }
    em_buf.len = pos + 8;
}

void em_patch_disp32 -> int pos, int target_rva, int instr_end_rva {
    em_put32(pos, target_rva - instr_end_rva);
}

!!! ---- the instructions ----

!!! A constant that fits in 32 bits is carried by the instruction itself: the
!!! `mov eax, imm32` form is five bytes and zero-extends, and `mov rax, imm32` is
!!! seven bytes and sign-extends, while the 64-bit form spends ten bytes on the
!!! same value. Constants are the most common operand there is - every length,
!!! type tag and small literal in the program - and every one of them was written
!!! as a full 64-bit immediate.
!!!
!!! The ranges are tested by shifting rather than against a literal bound: an
!!! integer literal above 2147483647 does not compare as the value it is written
!!! as in this front end (`v <= 4294967295` is false for every v), so the bound is
!!! `v >> 32 == 0` for 0..4294967295 and `v >> 31 == -1` for -2147483648..-1,
!!! which is the same test with nothing but a shift and a small constant.
void em_mov_rax_imm64 -> longlong v {
    if v >= 0 && (v >> 32) == 0 {
        em_db(0xB8);
        em_dd((int)v);
        end;
    }
    if (v >> 31) == -1 {
        em_db(0x48);
        em_db(0xC7);
        em_db(0xC0);
        em_dd((int)v);
        end;
    }
    em_db(0x48);
    em_db(0xB8);
    em_dq(v);
}

void em_mov_rax_mem_rsp_disp8 -> int d {
    em_db(0x48);
    em_db(0x8B);
    em_db(0x44);
    em_db(0x24);
    em_db(d);
}

void em_mov_mem_rsp_disp8_rax -> int d {
    em_db(0x48);
    em_db(0x89);
    em_db(0x44);
    em_db(0x24);
    em_db(d);
}

void em_mov_rcx_rax {
    em_db(0x48);
    em_db(0x89);
    em_db(0xC1);
}

void em_mov_rdx_rax {
    em_db(0x48);
    em_db(0x89);
    em_db(0xC2);
}

void em_push_rax {
    em_db(0x50);
}

void em_pop_rax {
    em_db(0x58);
}

void em_pop_rdx {
    em_db(0x5A);
}

void em_pop_rcx {
    em_db(0x59);
}

void em_add_rax_rdx {
    em_db(0x48);
    em_db(0x01);
    em_db(0xD0);
}

void em_sub_rax_rdx {
    em_db(0x48);
    em_db(0x29);
    em_db(0xD0);
}

void em_imul_rax_rdx {
    em_db(0x48);
    em_db(0x0F);
    em_db(0xAF);
    em_db(0xC2);
}

void em_cqo {
    em_db(0x48);
    em_db(0x99);
}

void em_idiv_rcx {
    em_db(0x48);
    em_db(0xF7);
    em_db(0xF9);
}

void em_cvtsi2sd_xmm0_rax {
    em_db(0xF2);
    em_db(0x48);
    em_db(0x0F);
    em_db(0x2A);
    em_db(0xC0);
}

void em_cvttsd2si_xmm0_rax {
    em_db(0xF2);
    em_db(0x48);
    em_db(0x0F);
    em_db(0x2C);
    em_db(0xC0);
}

void em_movsd_xmm1_xmm0 {
    em_db(0xF2);
    em_db(0x0F);
    em_db(0x10);
    em_db(0xC8);
}

void em_addsd_xmm0_xmm1 {
    em_db(0xF2);
    em_db(0x0F);
    em_db(0x58);
    em_db(0xC1);
}

void em_subsd_xmm0_xmm1 {
    em_db(0xF2);
    em_db(0x0F);
    em_db(0x5C);
    em_db(0xC1);
}

void em_mulsd_xmm0_xmm1 {
    em_db(0xF2);
    em_db(0x0F);
    em_db(0x59);
    em_db(0xC1);
}

void em_divsd_xmm0_xmm1 {
    em_db(0xF2);
    em_db(0x0F);
    em_db(0x5E);
    em_db(0xC1);
}

void em_movsd_mem_rsp_disp8_xmm0 -> int d {
    em_db(0xF2);
    em_db(0x0F);
    em_db(0x11);
    em_db(0x44);
    em_db(0x24);
    em_db(d);
}

void em_movsd_xmm0_mem_rsp_disp8 -> int d {
    em_db(0xF2);
    em_db(0x0F);
    em_db(0x10);
    em_db(0x44);
    em_db(0x24);
    em_db(d);
}

void em_movsd_xmm1_mem_rsp_disp8 -> int d {
    em_db(0xF2);
    em_db(0x0F);
    em_db(0x10);
    em_db(0x4C);
    em_db(0x24);
    em_db(d);
}

void em_mov_mem_rbp_disp8_rcx -> int d {
    em_db(0x48);
    em_db(0x89);
    em_db(0x4D);
    em_db(d);
}

void em_mov_mem_rbp_disp8_rdx -> int d {
    em_db(0x48);
    em_db(0x89);
    em_db(0x55);
    em_db(d);
}

void em_mov_mem_rbp_disp8_r8 -> int d {
    em_db(0x4C);
    em_db(0x89);
    em_db(0x45);
    em_db(d);
}

void em_mov_mem_rbp_disp8_r9 -> int d {
    em_db(0x4C);
    em_db(0x89);
    em_db(0x4D);
    em_db(d);
}

void em_mov_rcx_mem_rsp_disp8 -> int d {
    em_db(0x48);
    em_db(0x8B);
    em_db(0x4C);
    em_db(0x24);
    em_db(d);
}

void em_mov_rdx_mem_rsp_disp8 -> int d {
    em_db(0x48);
    em_db(0x8B);
    em_db(0x54);
    em_db(0x24);
    em_db(d);
}

void em_mov_r8_mem_rsp_disp8 -> int d {
    em_db(0x4C);
    em_db(0x8B);
    em_db(0x44);
    em_db(0x24);
    em_db(d);
}

void em_mov_r9_mem_rsp_disp8 -> int d {
    em_db(0x4C);
    em_db(0x8B);
    em_db(0x4C);
    em_db(0x24);
    em_db(d);
}

void em_mov_mem_rdx_disp8_rax -> int d {
    em_db(0x48);
    em_db(0x89);
    em_db(0x42);
    em_db(d);
}

void em_call_rax {
    em_db(0xFF);
    em_db(0xD0);
}

void em_sub_rsp_imm8 -> int v {
    em_db(0x48);
    em_db(0x83);
    em_db(0xEC);
    em_db(v);
}

void em_sub_rsp_imm32 -> int v {
    em_db(0x48);
    em_db(0x81);
    em_db(0xEC);
    em_dd(v);
}

void em_add_rsp_imm8 -> int v {
    em_db(0x48);
    em_db(0x83);
    em_db(0xC4);
    em_db(v);
}

void em_sub_rsp -> int n {
    if n == 0 {
        end;
    }
    if n > 0 && n <= 127 {
        em_sub_rsp_imm8(n);
        end;
    }
    if n > 127 {
        em_sub_rsp_imm32(n);
        end;
    }
    if n < 0 {
        int v = 0 - n;
        if v <= 127 {
            em_add_rsp_imm8(v);
        } else {
            em_db(0x48);
            em_db(0x81);
            em_db(0xC4);
            em_dd(v);
        }
    }
}

void em_ret {
    em_db(0xC3);
}

void em_mov_rcx_imm32 -> int v {
    em_db(0x48);
    em_db(0xC7);
    em_db(0xC1);
    em_dd(v);
}

!!! cmp rax, imm32: a comparison against a small constant keeps the constant in the
!!! instruction instead of writing it to a temporary slot and reading it back.
void em_cmp_rax_imm32 -> int v {
    em_db(0x48);
    em_db(0x3D);
    em_dd(v);
}

!!! The same for + and -: `x = x + 1` is a loop counter in most of the code, and
!!! loading the 1 into a temporary slot first costs three instructions.
void em_add_rax_imm32 -> int v {
    em_db(0x48);
    em_db(0x05);
    em_dd(v);
}

void em_sub_rax_imm32 -> int v {
    em_db(0x48);
    em_db(0x2D);
    em_dd(v);
}

void em_push_rbp {
    em_db(0x55);
}

void em_mov_rbp_rsp {
    em_db(0x48);
    em_db(0x89);
    em_db(0xE5);
}

void em_test_rax_rax {
    em_db(0x48);
    em_db(0x85);
    em_db(0xC0);
}

!!! ---- the frame-relative accessors ----

!!! `[rip + em_globals_off + d]`: the entry-scope slots live in an image block, so
!!! the instruction reaches them without a base register. The caller writes the
!!! prefixes, with REX.B clear, because rm 101 with REX.B set is r13 and not a
!!! rip-relative operand.
void em_alt_rip_disp -> int reg, int d {
    int target = em_globals_off + d;
    em_db(0x05 | (reg << 3));
    int disp = target - (em_buf.len + 4);
    em_dd(disp);
}

!!! Inside a function, `em_temp_base` 1 addresses `[rbp + d]`.
void em_alt_base_disp -> int reg, int d {
    if d >= -128 && d <= 127 {
        em_db(0x40 | (reg << 3) | 0x05);
        em_db(d);
    } else {
        em_db(0x80 | (reg << 3) | 0x05);
        em_dd(d);
    }
}

void em_alt_ld_rax -> int d {
    if em_temp_base == 2 {
        em_db(0x48);
        em_db(0x8B);
        em_alt_rip_disp(0, d);
        end;
    }
    em_db(0x48);
    em_db(0x8B);
    em_alt_base_disp(0, d);
}

void em_alt_ldsxd -> int d {
    if em_temp_base == 2 {
        em_db(0x48);
        em_db(0x63);
        em_alt_rip_disp(0, d);
        end;
    }
    em_db(0x48);
    em_db(0x63);
    em_alt_base_disp(0, d);
}

void em_ldsxd_rbp -> int d {
    if d >= -128 && d <= 127 {
        em_db(0x48);
        em_db(0x63);
        em_db(0x45);
        em_db(d);
    } else {
        em_db(0x48);
        em_db(0x63);
        em_db(0x85);
        em_dd(d);
    }
}

!!! The same loads into rdx, for a binary operation whose right operand is read
!!! where it lives instead of through a temporary slot (see cg_right_rdx_ok).
void em_ld_rbp_rdx -> int d {
    if d >= -128 && d <= 127 {
        em_db(0x48);
        em_db(0x8B);
        em_db(0x55);
        em_db(d);
    } else {
        em_db(0x48);
        em_db(0x8B);
        em_db(0x95);
        em_dd(d);
    }
}

!!! A call argument read straight into the register that carries it: `reg` is 1 for
!!! rcx, 2 for rdx, 8 for r8 and 9 for r9. The ModRM register field holds the low
!!! three bits and REX.R the fourth, which is the prefix's 0x04 - the 0x05 of the
!!! r/m field already has that bit set, so it never has to be added to the ModRM.
void em_ld_arg_disp -> int reg, int d {
    if reg >= 8 {
        em_db(0x4C);
    } else {
        em_db(0x48);
    }
    em_db(0x8B);
    int low = reg & 7;
    if d >= -128 && d <= 127 {
        em_db(0x40 | (low << 3) | 0x05);
        em_db(d);
    } else {
        em_db(0x80 | (low << 3) | 0x05);
        em_dd(d);
    }
}

void em_ldsxd_arg_disp -> int reg, int d {
    if reg >= 8 {
        em_db(0x4C);
    } else {
        em_db(0x48);
    }
    em_db(0x63);
    int low = reg & 7;
    if d >= -128 && d <= 127 {
        em_db(0x40 | (low << 3) | 0x05);
        em_db(d);
    } else {
        em_db(0x80 | (low << 3) | 0x05);
        em_dd(d);
    }
}

void em_mov_arg_imm32 -> int reg, int v {
    if reg >= 8 {
        em_db(0x41);
        em_db(0xB8 | (reg & 7));
    } else {
        em_db(0xB8 | reg);
    }
    em_dd(v);
}

void em_ldsxd_rbp_rdx -> int d {
    if d >= -128 && d <= 127 {
        em_db(0x48);
        em_db(0x63);
        em_db(0x55);
        em_db(d);
    } else {
        em_db(0x48);
        em_db(0x63);
        em_db(0x95);
        em_dd(d);
    }
}

void em_alt_ldsxd_rdx -> int d {
    if em_temp_base == 2 {
        em_db(0x48);
        em_db(0x63);
        em_alt_rip_disp(2, d);
        end;
    }
    em_db(0x48);
    em_db(0x63);
    em_alt_base_disp(2, d);
}

void em_ldsxd_rsp_rdx -> int d {
    if em_temp_base != 0 {
        em_alt_ldsxd_rdx(d + em_temp_bias);
        end;
    }
    if d >= -128 && d <= 127 {
        em_db(0x48);
        em_db(0x63);
        em_db(0x54);
        em_db(0x24);
        em_db(d);
    } else {
        em_db(0x48);
        em_db(0x63);
        em_db(0x94);
        em_db(0x24);
        em_dd(d);
    }
}

void em_ldsxd_rsp -> int d {
    if em_temp_base != 0 {
        em_alt_ldsxd(d + em_temp_bias);
        end;
    }
    if d >= -128 && d <= 127 {
        em_db(0x48);
        em_db(0x63);
        em_db(0x44);
        em_db(0x24);
        em_db(d);
    } else {
        em_db(0x48);
        em_db(0x63);
        em_db(0x84);
        em_db(0x24);
        em_dd(d);
    }
}

void em_alt_ld_rdx -> int d {
    if em_temp_base == 2 {
        em_db(0x48);
        em_db(0x8B);
        em_alt_rip_disp(2, d);
        end;
    }
    em_db(0x48);
    em_db(0x8B);
    em_alt_base_disp(2, d);
}

void em_alt_st_rax -> int d {
    if em_temp_base == 2 {
        em_db(0x48);
        em_db(0x89);
        em_alt_rip_disp(0, d);
        end;
    }
    em_db(0x48);
    em_db(0x89);
    em_alt_base_disp(0, d);
}

void em_alt_st_eax -> int d {
    if em_temp_base == 2 {
        em_db(0x89);
        em_alt_rip_disp(0, d);
        end;
    }
    em_db(0x89);
    em_alt_base_disp(0, d);
}

void em_alt_st_al -> int d {
    if em_temp_base == 2 {
        em_db(0x88);
        em_alt_rip_disp(0, d);
        end;
    }
    em_db(0x88);
    em_alt_base_disp(0, d);
}

void em_alt_lea -> int d {
    if em_temp_base == 2 {
        em_db(0x48);
        em_db(0x8D);
        em_alt_rip_disp(0, d);
        end;
    }
    em_db(0x48);
    em_db(0x8D);
    em_alt_base_disp(0, d);
}

void em_alt_ldsd -> int d {
    if em_temp_base == 2 {
        em_db(0xF2);
        em_db(0x0F);
        em_db(0x10);
        em_alt_rip_disp(0, d);
        end;
    }
    em_db(0xF2);
    em_db(0x0F);
    em_db(0x10);
    em_alt_base_disp(0, d);
}

void em_alt_stsd -> int d {
    if em_temp_base == 2 {
        em_db(0xF2);
        em_db(0x0F);
        em_db(0x11);
        em_alt_rip_disp(0, d);
        end;
    }
    em_db(0xF2);
    em_db(0x0F);
    em_db(0x11);
    em_alt_base_disp(0, d);
}

void em_alt_ldsd_xmm1 -> int d {
    if em_temp_base == 2 {
        em_db(0xF2);
        em_db(0x0F);
        em_db(0x10);
        em_alt_rip_disp(1, d);
        end;
    }
    em_db(0xF2);
    em_db(0x0F);
    em_db(0x10);
    em_alt_base_disp(1, d);
}

!!! `mov rax, [rbp+d]`
void em_ld_rbp -> int d {
    if d >= -128 && d <= 127 {
        em_db(0x48);
        em_db(0x8B);
        em_db(0x45);
        em_db(d);
    } else {
        em_db(0x48);
        em_db(0x8B);
        em_db(0x85);
        em_dd(d);
    }
}

!!! `mov [rbp+d], rax`
void em_st_rbp_rax -> int d {
    if d >= -128 && d <= 127 {
        em_db(0x48);
        em_db(0x89);
        em_db(0x45);
        em_db(d);
    } else {
        em_db(0x48);
        em_db(0x89);
        em_db(0x85);
        em_dd(d);
    }
}

void em_st_rbp_eax -> int d {
    if d >= -128 && d <= 127 {
        em_db(0x89);
        em_db(0x45);
        em_db(d);
    } else {
        em_db(0x89);
        em_db(0x85);
        em_dd(d);
    }
}

void em_st_rbp_al -> int d {
    if d >= -128 && d <= 127 {
        em_db(0x88);
        em_db(0x45);
        em_db(d);
    } else {
        em_db(0x88);
        em_db(0x85);
        em_dd(d);
    }
}

void em_ld_rsp -> int d {
    if em_temp_base != 0 {
        em_alt_ld_rax(d + em_temp_bias);
        end;
    }
    if d >= -128 && d <= 127 {
        em_db(0x48);
        em_db(0x8B);
        em_db(0x44);
        em_db(0x24);
        em_db(d);
    } else {
        em_db(0x48);
        em_db(0x8B);
        em_db(0x84);
        em_db(0x24);
        em_dd(d);
    }
}

void em_st_rsp_rax -> int d {
    if em_temp_base != 0 {
        em_alt_st_rax(d + em_temp_bias);
        end;
    }
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

void em_st_rsp_eax -> int d {
    if em_temp_base != 0 {
        em_alt_st_eax(d + em_temp_bias);
        end;
    }
    if d >= -128 && d <= 127 {
        em_db(0x89);
        em_db(0x44);
        em_db(0x24);
        em_db(d);
    } else {
        em_db(0x89);
        em_db(0x84);
        em_db(0x24);
        em_dd(d);
    }
}

void em_st_rsp_al -> int d {
    if em_temp_base != 0 {
        em_alt_st_al(d + em_temp_bias);
        end;
    }
    if d >= -128 && d <= 127 {
        em_db(0x88);
        em_db(0x44);
        em_db(0x24);
        em_db(d);
    } else {
        em_db(0x88);
        em_db(0x84);
        em_db(0x24);
        em_dd(d);
    }
}

void em_ldsd_rbp -> int d {
    if d >= -128 && d <= 127 {
        em_db(0xF2);
        em_db(0x0F);
        em_db(0x10);
        em_db(0x45);
        em_db(d);
    } else {
        em_db(0xF2);
        em_db(0x0F);
        em_db(0x10);
        em_db(0x85);
        em_dd(d);
    }
}

void em_stsd_rbp -> int d {
    if d >= -128 && d <= 127 {
        em_db(0xF2);
        em_db(0x0F);
        em_db(0x11);
        em_db(0x45);
        em_db(d);
    } else {
        em_db(0xF2);
        em_db(0x0F);
        em_db(0x11);
        em_db(0x85);
        em_dd(d);
    }
}

void em_ldsd_rsp -> int d {
    if em_temp_base != 0 {
        em_alt_ldsd(d + em_temp_bias);
        end;
    }
    if d >= -128 && d <= 127 {
        em_db(0xF2);
        em_db(0x0F);
        em_db(0x10);
        em_db(0x44);
        em_db(0x24);
        em_db(d);
    } else {
        em_db(0xF2);
        em_db(0x0F);
        em_db(0x10);
        em_db(0x84);
        em_db(0x24);
        em_dd(d);
    }
}

void em_stsd_rsp -> int d {
    if em_temp_base != 0 {
        em_alt_stsd(d + em_temp_bias);
        end;
    }
    if d >= -128 && d <= 127 {
        em_db(0xF2);
        em_db(0x0F);
        em_db(0x11);
        em_db(0x44);
        em_db(0x24);
        em_db(d);
    } else {
        em_db(0xF2);
        em_db(0x0F);
        em_db(0x11);
        em_db(0x84);
        em_db(0x24);
        em_dd(d);
    }
}

void em_ldsd_rsp_xmm1 -> int d {
    if em_temp_base != 0 {
        em_alt_ldsd_xmm1(d + em_temp_bias);
        end;
    }
    if d >= -128 && d <= 127 {
        em_db(0xF2);
        em_db(0x0F);
        em_db(0x10);
        em_db(0x4C);
        em_db(0x24);
        em_db(d);
    } else {
        em_db(0xF2);
        em_db(0x0F);
        em_db(0x10);
        em_db(0x8C);
        em_db(0x24);
        em_dd(d);
    }
}

void em_ld_rsp_rdx -> int d {
    if em_temp_base != 0 {
        em_alt_ld_rdx(d + em_temp_bias);
        end;
    }
    if d >= -128 && d <= 127 {
        em_db(0x48);
        em_db(0x8B);
        em_db(0x54);
        em_db(0x24);
        em_db(d);
    } else {
        em_db(0x48);
        em_db(0x8B);
        em_db(0x94);
        em_db(0x24);
        em_dd(d);
    }
}

void em_lea_rbp -> int d {
    if d >= -128 && d <= 127 {
        em_db(0x48);
        em_db(0x8D);
        em_db(0x45);
        em_db(d);
    } else {
        em_db(0x48);
        em_db(0x8D);
        em_db(0x85);
        em_dd(d);
    }
}

void em_lea_rsp -> int d {
    if em_temp_base != 0 {
        em_alt_lea(d + em_temp_bias);
        end;
    }
    if d >= -128 && d <= 127 {
        em_db(0x48);
        em_db(0x8D);
        em_db(0x44);
        em_db(0x24);
        em_db(d);
    } else {
        em_db(0x48);
        em_db(0x8D);
        em_db(0x84);
        em_db(0x24);
        em_dd(d);
    }
}

!!! ---- jumps, calls and the rip-relative forms ----

int em_jmp_rel32 {
    int p = em_tell();
    em_db(0xE9);
    em_dd(0);
    return p;
}

void em_patch_jmp_rel32 -> int pos {
    em_put32(pos + 1, em_buf.len - (pos + 5));
}

int em_lea_rdx_rip_disp32 {
    int p = em_tell();
    em_db(0x48);
    em_db(0x8D);
    em_db(0x15);
    em_dd(0);
    return p;
}

int em_lea_rax_rip_disp32 {
    int p = em_tell();
    em_db(0x48);
    em_db(0x8D);
    em_db(0x05);
    em_dd(0);
    return p;
}

int em_call_rel32 {
    int p = em_tell();
    em_db(0xE8);
    em_dd(0);
    return p;
}

void em_patch_call_rel32_at -> int pos, int target_rva, int instr_end_rva {
    em_put32(pos + 1, target_rva - instr_end_rva);
}

void em_patch_call_rel32 -> int pos, int target_rva {
    em_patch_call_rel32_at(pos, target_rva, pos + 5);
}

int em_jz_rel8 {
    int p = em_tell();
    em_db(0x74);
    em_db(0x00);
    return p;
}

!!! the toolchain asserts that the span fits in one byte, because a displacement that
!!! does not would silently jump to the wrong instruction. The span is written
!!! here all the same: the shape of the generated code is the toolchain shape, and a
!!! mismatch is found by comparing the two images rather than by an abort.
void em_patch_jz_rel8 -> int pos {
    int dist = em_buf.len - (pos + 2);
    @char d = em_buf.data;
    d[pos + 1] = (char)(dist & 255);
}

int em_jz_rel32 {
    int p = em_tell();
    em_db(0x0F);
    em_db(0x84);
    em_dd(0);
    return p;
}

void em_patch_jz_rel32 -> int pos {
    em_put32(pos + 2, em_buf.len - (pos + 6));
}

int em_jnz_rel32 {
    int p = em_tell();
    em_db(0x0F);
    em_db(0x85);
    em_dd(0);
    return p;
}

!!! The signed family, for a branch on a comparison: jl <, jge >=, jle <=, jg >.
int em_jl_rel32 {
    int p = em_tell();
    em_db(0x0F);
    em_db(0x8C);
    em_dd(0);
    return p;
}

int em_jge_rel32 {
    int p = em_tell();
    em_db(0x0F);
    em_db(0x8D);
    em_dd(0);
    return p;
}

int em_jle_rel32 {
    int p = em_tell();
    em_db(0x0F);
    em_db(0x8E);
    em_dd(0);
    return p;
}

int em_jg_rel32 {
    int p = em_tell();
    em_db(0x0F);
    em_db(0x8F);
    em_dd(0);
    return p;
}

int em_jne_rel32 {
    return em_jnz_rel32();
}

void em_patch_jnz_rel32 -> int pos {
    em_put32(pos + 2, em_buf.len - (pos + 6));
}

void em_patch_jne_rel32 -> int pos {
    em_patch_jnz_rel32(pos);
}
