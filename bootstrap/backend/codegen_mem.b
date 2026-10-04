#once
!~
 ~  bootstrap/backend/codegen_mem.b: the raw memory accessors.
 ~
 ~  the stack slots of the body being generated
 ~  and the entry-scope block, which is reached through the instruction's own
 ~  rip-relative displacement.
 ~
 ~  the toolchain keeps the displacement of an entry-scope access in `gdisp(globals_off,
 ~  end_off, d)`. A base register cannot be used for that block: it is one register
 ~  shared by every module, so the caller's entry prologue would set it for its own
 ~  module and a DLL called from an exe - or a callback user32 makes into a DLL -
 ~  would end up reading the caller's block instead of its own.
 ~!

#head "cg_heads"

!!! Where the displacement is written: `globals_off + d - end_off`, `end_off` being
!!! the offset the displacement field ends at.
int cg_gdisp -> int d {
    return cg_globals_off + d - (em_tell() + 4);
}

!!! `mov rax, [slot]`. Answers whether the rbp form was used.
bool cg_ld8 -> int d {
    if !pe_eq(cg_current_func, "") {
        em_ld_rbp(d + 16);
        return true;
    }
    em_ld_rsp(d);
    return false;
}

void cg_st8 -> int d {
    if !pe_eq(cg_current_func, "") {
        em_st_rbp_rax(d + 16);
    } else {
        em_st_rsp_rax(d);
    }
}

void cg_st4 -> int d {
    if !pe_eq(cg_current_func, "") {
        em_st_rbp_eax(d + 16);
    } else {
        em_st_rsp_eax(d);
    }
}

!!! `movsxd rax, dword [slot]`: the load an `int` is read with. An `int` is
!!! stored with four bytes, and a wide load of a narrow store cannot be forwarded
!!! by the load/store unit, so every read of an int variable waited for the store
!!! to reach the cache. The four-byte load has the width of the store, so it is
!!! forwarded.
bool cg_ld4sxd -> int d {
    if !pe_eq(cg_current_func, "") {
        em_ldsxd_rbp(d + 16);
        return true;
    }
    em_ldsxd_rsp(d);
    return false;
}

!!! ---- the entry-frame accesses ----

!!! The two loads above into rdx, for a binary operation whose right operand is a
!!! variable that is read where it lives instead of through a temporary slot.
void cg_ld8_rdx -> int d {
    if !pe_eq(cg_current_func, "") {
        em_ld_rbp_rdx(d + 16);
    } else {
        em_ld_rsp_rdx(d);
    }
}

void cg_ld4sxd_rdx -> int d {
    if !pe_eq(cg_current_func, "") {
        em_ldsxd_rbp_rdx(d + 16);
    } else {
        em_ldsxd_rsp_rdx(d);
    }
}

bool cg_ld8_g -> int d {
    em_db(0x48);
    em_db(0x8B);
    em_db(0x05);
    em_dd(cg_gdisp(d));
    return true;
}

!!! The same load for an `int` global: four bytes, sign-extended.
bool cg_ld4sxd_g -> int d {
    em_db(0x48);
    em_db(0x63);
    em_db(0x05);
    em_dd(cg_gdisp(d));
    return true;
}

void cg_ld8_g_rdx -> int d {
    em_db(0x48);
    em_db(0x8B);
    em_db(0x15);
    em_dd(cg_gdisp(d));
}

void cg_ld4sxd_g_rdx -> int d {
    em_db(0x48);
    em_db(0x63);
    em_db(0x15);
    em_dd(cg_gdisp(d));
}

!!! A call argument read straight into the register that carries it (`reg`: 1 rcx,
!!! 2 rdx, 8 r8, 9 r9). Only the two shapes the callee reads as a plain 64-bit slot
!!! are handled - a four-byte signed load for an int and a wide one for everything
!!! else - which is what cg_load_var does for the same slot. The stack form is for
!!! the body of a function; the entry scope addresses its slots off rsp and the
!!! caller's push path covers it.
void cg_load_var_arg -> int off, VarType ty, int reg {
    if off >= kGlobalBase {
        int d = off - kGlobalBase;
        !!! REX.R carries the fourth bit of the register and belongs in the prefix;
        !!! the ModRM reg field holds only the low three.
        if reg >= 8 {
            em_db(0x4C);
        } else {
            em_db(0x48);
        }
        if ty == INT {
            em_db(0x63);
        } else {
            em_db(0x8B);
        }
        em_db(0x05 | ((reg & 7) << 3));
        em_dd(cg_gdisp(d));
        end;
    }
    int d2 = off + 16;
    if ty == INT {
        em_ldsxd_arg_disp(reg, d2);
    } else {
        em_ld_arg_disp(reg, d2);
    }
}

void cg_st8_g -> int d {
    em_db(0x48);
    em_db(0x89);
    em_db(0x05);
    em_dd(cg_gdisp(d));
}

void cg_st4_g -> int d {
    em_db(0x89);
    em_db(0x05);
    em_dd(cg_gdisp(d));
}

void cg_st1_g -> int d {
    em_db(0x88);
    em_db(0x05);
    em_dd(cg_gdisp(d));
}

void cg_ldsd_g -> int d {
    em_db(0xF2);
    em_db(0x0F);
    em_db(0x10);
    em_db(0x05);
    em_dd(cg_gdisp(d));
}

void cg_stsd_g -> int d {
    em_db(0xF2);
    em_db(0x0F);
    em_db(0x11);
    em_db(0x05);
    em_dd(cg_gdisp(d));
}

void cg_lea_g -> int d {
    em_db(0x48);
    em_db(0x8D);
    em_db(0x05);
    em_dd(cg_gdisp(d));
}

!!! `lea rax, [the slot of a variable]`: an entry-scope slot goes through the
!!! image block, a local through rbp (inside a function) or rsp (the entry code).
void cg_lea_var -> int off {
    if off >= kGlobalBase {
        cg_lea_g(off - kGlobalBase);
        end;
    }
    if !pe_eq(cg_current_func, "") {
        em_lea_rbp(off + 16);
    } else {
        em_lea_rsp(off);
    }
}
