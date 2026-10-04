#once
!~
 ~  bootstrap/backend/codegen_small.b: the small statements and helpers of the code
 ~  generator.
 ~
 ~  codegen_str_free,
 ~  codegen_if and codegen_patch: EXIT, the logical
 ~  not, the heap-string release, RELEASE, IF/ELSE and the two patchers that fill in
 ~  the import displacements once the layout is known.
 ~!

#head "cg_heads"

!!! EXIT <code>: ExitProcess(code).
bool cg_gen_exit -> @CmpStmt s {
    cg_gen_expr(s.exit_expr);
    em_mov_rcx_rax();
    cg_emit_call_import(cg_idx_exitprocess);
    return true;
}

!!! `!x`: 1 when the value is zero, 0 otherwise.
void cg_gen_not -> @CmpExpr n {
    cg_gen_expr(n.left);
    em_test_rax_rax();
    em_db(0x0F);
    em_db(0x94);
    em_db(0xC0);
    em_db(0x0F);
    em_db(0xB6);
    em_db(0xC0);
}

!!! Free rax when it is a non-null heap string.
void cg_emit_str_free_rax {
    em_test_rax_rax();
    int jz = em_jz_rel8();
    em_push_rax();
    cg_emit_call_lib("_str_free");
    em_add_rsp_imm8(8);
    em_patch_jz_rel8(jz);
}

!!! RELEASE var: decrement the closure's refcount and free the object at 0.
!!! Closure layout: [0]=refcount, [8]=code_ptr, [16]=capture_count, [24]=cell_flags,
!!! [32..]=captures.
bool cg_gen_release -> @CmpStmt s {
    @CgVarInfo it = cg_sym_find(s.var_name);
    if it == null {
        cg_stmt_err = cg_err_at(s.line, s.col, "RELEASE: undefined variable '" + s.var_name + "'");
        return false;
    }
    int off = it.stack_offset;
    cg_load_var(off, it.ty, it.is_array, false);
    cg_emit_release_closure_rax();
    !!! Clear the variable slot: this reference is given back.
    em_mov_rax_imm64(0);
    cg_store_var(off, it.ty, it.is_array, false);
    return true;
}

!!! IF (cond) THEN ( true ) ELSE ( false ).
bool cg_gen_if_else -> @CmpStmt s {
    !!! A condition that is a comparison branches on the comparison's own flags:
    !!! producing the 0/1 value first (setcc, movzx) and testing it again costs
    !!! three instructions per branch, and a branch is everywhere. Anything else is
    !!! evaluated the long way.
    int jz_false = 0;
    if !cg_cmp_jump_false(s.init_expr) {
        cg_gen_expr(s.init_expr);
        em_test_rax_rax();
        jz_false = em_jz_rel32();
    } else {
        jz_false = cg_cmp_jump_pos;
    }
    if !cg_gen_block(s.true_body) {
        return false;
    }
    if s.false_body != null {
        int jmp_end = em_jmp_rel32();
        em_patch_jz_rel32(jz_false);
        if !cg_gen_block(s.false_body) {
            return false;
        }
        em_patch_jmp_rel32(jmp_end);
    } else {
        em_patch_jz_rel32(jz_false);
    }
    return true;
}

!!! Every displacement here comes from pw_get_iat, so this has to run after the
!!! layout is planned: the IAT RVA moves with the size of .text, and a site patched
!!! against the assumed layout pointed into the code as soon as .text passed 64 KiB.
void cg_patch_calls {
    @CgCallPatch cp = cg_call_patches;
    while cp != null {
        int iat_rva = pw_get_iat(cp.import_idx);
        int next_rva = PEW_TEXT_RVA + (cp.pos + 4);
        em_put32(cp.pos, iat_rva - next_rva);
        cp = cp.next;
    }
}

!!! Library code calls native functions through `call *0(%rip)` slots that need
!!! their displacement filled in. The index comes from the library's own import
!!! table, so every function any linked library uses resolves, not only the ones
!!! that used to be listed here by name.
void cg_patch_blib_imports {
    @CgBlib b = cg_blibs;
    @CmpIntNode off = cg_blib_text_off_list;
    while b != null && off != null {
        int base = (int)off.v;
        @CgBlibImport imp = b.imports;
        while imp != null {
            @CgStrInt it = cg_strint_find(cg_blib_import_idx, imp.dll + "!" + imp.fnc);
            if it != null {
                int iat_rva = pw_get_iat(it.v);
                int instr_rva = PEW_TEXT_RVA + base + imp.off;
                int next_rva = instr_rva + 6;
                em_put32(base + imp.off + 2, iat_rva - next_rva);
            }
            imp = imp.next;
        }
        b = b.next;
        off = off.next;
    }
}
