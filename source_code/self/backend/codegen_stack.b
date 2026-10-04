#once
!~
 ~  bootstrap/backend/codegen_stack.b: the variable load and store.
 ~
 ~  a slot is loaded into rax (or xmm0 for a
 ~  float) and stored back, with the truncation the declared type asks for. An array
 ~  slot holds a heap pointer whatever its element type, and an entry-scope slot is
 ~  reached through the image block.
 ~!

#head "cg_heads"

void cg_load_var -> int off, VarType ty, bool is_array, bool is_global {
    if off >= kGlobalBase {
        off = off - kGlobalBase;
        is_global = true;
    }
    if is_array {
        if is_global {
            cg_ld8_g(off);
        } else {
            cg_ld8(off);
        }
        end;
    }
    if ty == FLOAT {
        if is_global {
            cg_ldsd_g(off);
            end;
        }
        if !pe_eq(cg_current_func, "") {
            em_ldsd_rbp(off + 16);
        } else {
            em_ldsd_rsp(off);
        }
        end;
    }
    !!! An `int` is read with a four-byte signed load: the store and the load have
    !!! the same width, so the load/store unit can forward one to the other. A wide
    !!! load of a narrow store cannot be forwarded, and the load had to wait for
    !!! the store to reach the cache on every read of an int variable.
    if ty == INT {
        if is_global {
            cg_ld4sxd_g(off);
        } else {
            cg_ld4sxd(off);
        }
        end;
    }
    if is_global {
        cg_ld8_g(off);
    } else {
        cg_ld8(off);
    }
    if ty == CHAR || ty == BOOL {
        em_db(0x0F);
        em_db(0xB6);
        em_db(0xC0);
    }
}

!!! The same load into rdx, for the right operand of a binary operation: a variable
!!! is one load wherever it is read, so evaluating it into rax first only to write it
!!! to a temporary slot and read it back costs two instructions for nothing.
void cg_load_var_rdx -> int off, VarType ty, bool is_array {
    bool is_global = false;
    if off >= kGlobalBase {
        off = off - kGlobalBase;
        is_global = true;
    }
    if is_array {
        if is_global {
            cg_ld8_g_rdx(off);
        } else {
            cg_ld8_rdx(off);
        }
        end;
    }
    if ty == INT {
        if is_global {
            cg_ld4sxd_g_rdx(off);
        } else {
            cg_ld4sxd_rdx(off);
        }
        end;
    }
    if is_global {
        cg_ld8_g_rdx(off);
    } else {
        cg_ld8_rdx(off);
    }
    if ty == CHAR || ty == BOOL {
        em_db(0x0F);
        em_db(0xB6);
        em_db(0xD2);
    }
}

void cg_store_var -> int off, VarType ty, bool is_array, bool is_global {
    if off >= kGlobalBase {
        off = off - kGlobalBase;
        is_global = true;
    }
    if is_array {
        if is_global {
            cg_st8_g(off);
        } else {
            cg_st8(off);
        }
        end;
    }
    if ty == FLOAT {
        if is_global {
            cg_stsd_g(off);
            end;
        }
        if !pe_eq(cg_current_func, "") {
            em_stsd_rbp(off + 16);
        } else {
            em_stsd_rsp(off);
        }
        end;
    }
    if ty == INT {
        if is_global {
            cg_st4_g(off);
        } else {
            cg_st4(off);
        }
        end;
    }
    if ty == CHAR || ty == BOOL {
        if is_global {
            cg_st1_g(off);
            end;
        }
        if !pe_eq(cg_current_func, "") {
            em_st_rbp_al(off + 16);
        } else {
            em_st_rsp_al(off);
        }
        end;
    }
    if is_global {
        cg_st8_g(off);
    } else {
        cg_st8(off);
    }
}
