#once
!~
 ~  bootstrap/backend/codegen_closure.b: the closure reference count.
 ~
 ~  a closure object keeps its reference
 ~  count in its first eight bytes, the count of captures at +16 and a bit per
 ~  capture at +24 saying whether that capture is a heap cell. Releasing the last
 ~  reference frees the cells and then the object itself.
 ~!

#head "cg_heads"

!!! Add one reference to the closure rax names.
void cg_emit_retain_rax {
    em_test_rax_rax();
    int jz = em_jz_rel32();
    em_db(0x48);
    em_db(0xFF);
    em_db(0x00);
    em_patch_jz_rel32(jz);
}

!!! Give one reference back; the object goes when the count reaches zero.
void cg_emit_release_closure_rax {
    em_test_rax_rax();
    int jz_done = em_jz_rel32();
    em_db(0x48);
    em_db(0xFF);
    em_db(0x08);
    em_db(0x48);
    em_db(0x83);
    em_db(0x38);
    em_db(0x00);
    int jnz_done = em_jnz_rel32();
    !!! The object and its capture cells come from the runtime's pool, and a slice
    !!! of a block is never given back on its own - the block is released when the
    !!! process ends. Freeing one would be worse than useless: a slice that happens
    !!! to sit at the base of its block would take the whole block with it, and
    !!! every other object in it with that. So when the runtime is there to ask,
    !!! the release is only the refcount above. A program that links no runtime
    !!! still allocates pages and still has to return them.
    if cg_nopt_asm || !cg_can_call_native("_alloc_small") {
    !!! The captured heap cells first. rbx is the base, which the calls keep.
    em_db(0x48);
    em_db(0x89);
    em_db(0xC3);
    em_db(0x48);
    em_db(0x8B);
    em_db(0x4B);
    em_db(0x10);
    em_db(0x48);
    em_db(0x8B);
    em_db(0x53);
    em_db(0x18);
    em_db(0x48);
    em_db(0x89);
    em_db(0xD8);
    em_db(0x48);
    em_db(0x83);
    em_db(0xC0);
    em_db(0x20);
    em_db(0x48);
    em_db(0x85);
    em_db(0xC9);
    int cells_done = em_jz_rel32();
    int cell_loop = em_tell();
    em_db(0x48);
    em_db(0xF7);
    em_db(0xC2);
    em_dd(1);
    int not_cell = em_jz_rel32();
    em_db(0x51);
    em_db(0x52);
    em_push_rax();
    em_db(0x48);
    em_db(0x8B);
    em_db(0x08);
    em_db(0x48);
    em_db(0x85);
    em_db(0xC9);
    int skip_free = em_jz_rel32();
    em_db(0x31);
    em_db(0xD2);
    em_db(0x41);
    em_db(0xB8);
    em_db(0x00);
    em_db(0x80);
    em_db(0x00);
    em_db(0x00);
    em_sub_rsp_imm8(40);
    cg_emit_call_import(cg_idx_virtualfree);
    em_add_rsp_imm8(40);
    em_patch_jz_rel32(skip_free);
    em_pop_rax();
    em_pop_rdx();
    em_pop_rcx();
    em_patch_jz_rel32(not_cell);
    em_db(0x48);
    em_db(0xD1);
    em_db(0xEA);
    em_db(0x48);
    em_db(0x83);
    em_db(0xC0);
    em_db(0x08);
    em_db(0x48);
    em_db(0xFF);
    em_db(0xC9);
    em_db(0x0F);
    em_db(0x85);
    em_dd(cell_loop - (em_tell() + 4));
    em_patch_jz_rel32(cells_done);
    !!! The object itself.
    em_db(0x48);
    em_db(0x89);
    em_db(0xD9);
    em_db(0x31);
    em_db(0xD2);
    em_db(0x41);
    em_db(0xB8);
    em_db(0x00);
    em_db(0x80);
    em_db(0x00);
    em_db(0x00);
    em_sub_rsp_imm8(40);
    cg_emit_call_import(cg_idx_virtualfree);
    em_add_rsp_imm8(40);
    }
    em_patch_jnz_rel32(jnz_done);
    em_patch_jz_rel32(jz_done);
}
