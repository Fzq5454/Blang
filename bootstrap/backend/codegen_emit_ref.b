#once
!~
 ~  bootstrap/backend/codegen_emit_ref.b: the call and .rdata reference emitters.
 ~
 ~  a direct call into .text (library
 ~  code), a call through an import slot (its displacement is patched once the
 ~  import table has its RVAs), and the two instructions that name an address in
 ~  .rdata.
 ~!

#head "cg_heads"

void cg_emit_call_text -> int text_off {
    int pos = em_tell();
    em_db(0xE8);
    em_dd(0);
    int next_rva = PEW_TEXT_RVA + em_tell();
    int tgt_rva = PEW_TEXT_RVA + text_off;
    em_put32(pos + 1, tgt_rva - next_rva);
}

void cg_emit_call_import -> int import_idx {
    int pos = em_tell();
    em_db(0xFF);
    em_db(0x15);
    em_dd(0);
    CgCallPatch proto;
    @CgCallPatch cp;
    cg_balloc(@cp, size proto);
    cp.pos = pos + 2;
    cp.import_idx = import_idx;
    cp.next = cg_call_patches;
    cg_call_patches = cp;
}

void cg_emit_lea_rax_rdata -> int rdata_rva {
    int pos = em_tell();
    em_db(0x48);
    em_db(0x8D);
    em_db(0x05);
    em_dd(0);
    int instr_end_rva = PEW_TEXT_RVA + em_tell();
    em_put32(pos + 3, rdata_rva - instr_end_rva);
    cg_note_rdata_ref(pos + 3, rdata_rva);
}

void cg_emit_movsd_xmm0_rdata -> int rdata_rva {
    int pos = em_tell();
    em_db(0xF2);
    em_db(0x0F);
    em_db(0x10);
    em_db(0x05);
    em_dd(0);
    int instr_end_rva = PEW_TEXT_RVA + em_tell();
    em_put32(pos + 4, rdata_rva - instr_end_rva);
    cg_note_rdata_ref(pos + 4, rdata_rva);
}
