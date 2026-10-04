#once
!~
 ~  bootstrap/backend/codegen_try.b: TRY/CATCH and the exception runtime it needs.
 ~
 ~  The generated program installs one
 ~  vectored exception handler at startup. A TRY statement builds a frame record on
 ~  the stack and links it into a chain anchored by two slots in .text, so the
 ~  handler can find the innermost active frame, and the CATCH block it resumes in,
 ~  from the exception context alone:
 ~
 ~    frame +0   previous frame (0 = none)
 ~    frame +8   address to resume at (the CATCH block)
 ~    frame +16  rsp to resume with (the value before the frame was built)
 ~    frame +24  rbp
 ~    frame +32  rbx      +40 rsi      +48 rdi
 ~    frame +56  r12      +64 r13      +72 r14
 ~
 ~  The frame is built below rsp (`sub rsp, 96`), where nothing else is stored while
 ~  the TRY body runs. The four slots the runtime reads back - prev, handler, rsp
 ~  and rbp - are the lowest ones, at frame offsets 0..24, and every rsp-relative
 ~  slot the rest of the code generator uses starts at cg_next_stack_offset (>= 0x20),
 ~  so those four can never be overwritten by a temporary, a switch's scratch
 ~  storage or a pushed call argument.
 ~
 ~  On any hardware fault the handler stores the exception code in the second .text
 ~  slot, unlinks the frame, rewrites the exception context and returns
 ~  EXCEPTION_CONTINUE_EXECUTION: Windows then resumes in the CATCH block, with the
 ~  abandoned part of the TRY body skipped.
 ~!

#head "cg_heads"

!!! ---- the frame record ----
int kTryFrameSize = 96;
int kTryHandler = 8;
int kTryRsp = 16;
int kTryRbp = 24;
int kTryRbx = 32;
int kTryRsi = 40;
int kTryRdi = 48;
int kTryR12 = 56;
int kTryR13 = 64;
int kTryR14 = 72;

!!! ---- the Windows x64 CONTEXT offsets ----
int kCtxRbx = 0x90;
int kCtxRsp = 0x98;
int kCtxRbp = 0xA0;
int kCtxRsi = 0xA8;
int kCtxRdi = 0xB0;
int kCtxR12 = 0xD8;
int kCtxR13 = 0xE0;
int kCtxR14 = 0xE8;
int kCtxRip = 0xF8;

!!! `mov r10, [rax+frame_off]` then `mov [r9+ctx_off], r10`: one field of the frame
!!! record is copied into the context the dispatcher will resume from. the toolchain
!!! walks a table of these pairs; this implementation writes each pair as its own call.
void cg_emit_try_move -> int fo, int co {
    em_db(0x4C);
    em_db(0x8B);
    em_db(0x50);
    em_db(fo);
    em_db(0x4D);
    em_db(0x89);
    em_db(0x91);
    em_dd(co);
}

!!! ---- rip-relative access to the two shared .text slots ----

void cg_emit_load_rax_text -> int target {
    int pos = em_tell();
    em_db(0x48);
    em_db(0x8B);
    em_db(0x05);
    em_dd(0);
    em_patch_disp32(pos + 3, target, em_tell());
}

void cg_emit_store_rax_text -> int target {
    int pos = em_tell();
    em_db(0x48);
    em_db(0x89);
    em_db(0x05);
    em_dd(0);
    em_patch_disp32(pos + 3, target, em_tell());
}

!!! ---- leaving a TRY body ----

void cg_emit_try_chain_pop {
    em_db(0x48);
    em_db(0x8B);
    em_db(0x04);
    em_db(0x24);
    cg_emit_store_rax_text(cg_exc_head_off);
}

void cg_emit_try_unlink {
    cg_emit_try_chain_pop();
    em_add_rsp_imm8(kTryFrameSize);
}

void cg_emit_try_unlinks {
    !!! Innermost frame first: each one sits directly at the current rsp.
    int i = 0;
    while i < cg_try_depth {
        cg_emit_try_unlink();
        i = i + 1;
    }
}

!!! ---- the runtime: two .text slots and the vectored exception handler ----

void cg_emit_try_runtime {
    !!! Head of the active frame chain and the code being handled. Both live in the
    !!! code section, which the PE writer marks writable (the conversion ring is a
    !!! static slot there as well).
    cg_exc_head_off = em_tell();
    int i = 0;
    while i < 8 {
        em_db(0x00);
        i = i + 1;
    }
    cg_exc_code_off = em_tell();
    i = 0;
    while i < 8 {
        em_db(0x00);
        i = i + 1;
    }

    !!! LONG CALLBACK veh(EXCEPTION_POINTERS* ep)   rcx = ep
    cg_veh_off = em_tell();
    cg_emit_load_rax_text(cg_exc_head_off);
    em_db(0x48);
    em_db(0x85);
    em_db(0xC0);
    int jz_search = em_jz_rel32();
    em_db(0x48);
    em_db(0x8B);
    em_db(0x11);
    em_db(0x8B);
    em_db(0x12);
    !!! Remember the code for the CATCH block.
    int code_disp = em_tell();
    em_db(0x89);
    em_db(0x15);
    em_dd(0);
    em_patch_disp32(code_disp + 2, cg_exc_code_off, em_tell());
    !!! The frame is taken: unlink it before the handler runs.
    em_db(0x4C);
    em_db(0x8B);
    em_db(0x00);
    em_db(0x4C);
    em_db(0x89);
    em_db(0x05);
    int head_disp = em_tell();
    em_dd(0);
    em_patch_disp32(head_disp, cg_exc_head_off, em_tell());
    !!! Rewrite the context: resume at the handler with the try site's stack.
    em_db(0x4C);
    em_db(0x8B);
    em_db(0x49);
    em_db(0x08);
    cg_emit_try_move(kTryHandler, kCtxRip);
    cg_emit_try_move(kTryRsp, kCtxRsp);
    cg_emit_try_move(kTryRbp, kCtxRbp);
    cg_emit_try_move(kTryRbx, kCtxRbx);
    cg_emit_try_move(kTryRsi, kCtxRsi);
    cg_emit_try_move(kTryRdi, kCtxRdi);
    cg_emit_try_move(kTryR12, kCtxR12);
    cg_emit_try_move(kTryR13, kCtxR13);
    cg_emit_try_move(kTryR14, kCtxR14);
    em_db(0xB8);
    em_dd(0xFFFFFFFF);
    em_ret();
    !!! No frame: nothing in this program is watching for exceptions.
    em_patch_jz_rel32(jz_search);
    em_db(0x31);
    em_db(0xC0);
    em_ret();
}

void cg_emit_try_install {
    !!! 32 bytes of shadow space, no more: the stack is 16-byte aligned at a
    !!! statement, so this keeps it aligned for the call, which the callee's own
    !!! aligned spills (and the exception dispatcher's CONTEXT) require.
    em_sub_rsp_imm8(32);
    em_mov_rcx_imm32(1);
    int hdisp = em_lea_rdx_rip_disp32();
    em_patch_disp32(hdisp + 3, cg_veh_off, em_tell());
    cg_emit_call_import(cg_idx_addveh);
    em_add_rsp_imm8(32);
}

!!! ---- the statements ----

!!! `RAISE expr`: hand the code to Windows. The vectored handler above catches it
!!! and resumes in the CATCH block of the innermost TRY, which is the same path a
!!! hardware fault takes; with no TRY around it no handler exists, so the process
!!! ends with this code, exactly as an uncaught fault does. The flags stay 0
!!! (continuable), which is what makes resuming in the CATCH block legal.
bool cg_gen_raise -> @CmpStmt s {
    cg_gen_expr(s.init_expr);
    em_mov_rcx_rax();
    em_db(0x31);
    em_db(0xD2);
    em_db(0x45);
    em_db(0x31);
    em_db(0xC0);
    em_db(0x45);
    em_db(0x31);
    em_db(0xC9);
    !!! 32 bytes of shadow space, no more: the stack is 16-byte aligned at a
    !!! statement, so this keeps it aligned for the call. Reserving 40 (32 plus an
    !!! extra 8) leaves the callee's frame 8 bytes out of line, and the CONTEXT the
    !!! exception dispatcher builds on that stack is then misaligned: ntdll's
    !!! RtlCaptureContext faults on it with an aligned store.
    em_sub_rsp_imm8(32);
    cg_emit_call_import(cg_idx_raiseexception);
    em_add_rsp_imm8(32);
    return true;
}

bool cg_gen_try_catch -> @CmpStmt s {
    !!! `CATCH name` gives the handler the code; `CATCH (` leaves it out and the
    !!! handler only learns that something failed.
    bool have_var = !pe_eq(s.var_name, "");
    @CgVarInfo cv = null;
    if have_var {
        @CgVarInfo vit = cg_sym_find(s.var_name);
        if vit == null {
            cg_stmt_err = cg_err_at(s.line, s.col,
                                    "no variable '" + s.var_name + "' declared for CATCH");
            return false;
        }
        cv = vit;
    }

    !!! Build the frame at [rsp] and publish it.
    em_sub_rsp(kTryFrameSize);
    cg_emit_load_rax_text(cg_exc_head_off);
    em_db(0x48);
    em_db(0x89);
    em_db(0x04);
    em_db(0x24);
    em_db(0x48);
    em_db(0x8D);
    em_db(0x84);
    em_db(0x24);
    em_dd(kTryFrameSize);
    em_db(0x48);
    em_db(0x89);
    em_db(0x44);
    em_db(0x24);
    em_db(kTryRsp);
    !!! The scratch registers the handler has to put back: rbp, rbx, rsi, rdi, then
    !!! the four extended ones.
    em_db(0x48);
    em_db(0x89);
    em_db(0x6C);
    em_db(0x24);
    em_db(kTryRbp);
    em_db(0x48);
    em_db(0x89);
    em_db(0x5C);
    em_db(0x24);
    em_db(kTryRbx);
    em_db(0x48);
    em_db(0x89);
    em_db(0x74);
    em_db(0x24);
    em_db(kTryRsi);
    em_db(0x48);
    em_db(0x89);
    em_db(0x7C);
    em_db(0x24);
    em_db(kTryRdi);
    em_db(0x4C);
    em_db(0x89);
    em_db(0x64);
    em_db(0x24);
    em_db(kTryR12);
    em_db(0x4C);
    em_db(0x89);
    em_db(0x6C);
    em_db(0x24);
    em_db(kTryR13);
    em_db(0x4C);
    em_db(0x89);
    em_db(0x74);
    em_db(0x24);
    em_db(kTryR14);
    int hdisp = em_lea_rax_rip_disp32();
    em_db(0x48);
    em_db(0x89);
    em_db(0x44);
    em_db(0x24);
    em_db(kTryHandler);
    em_db(0x48);
    em_db(0x8D);
    em_db(0x04);
    em_db(0x24);
    cg_emit_store_rax_text(cg_exc_head_off);

    cg_try_depth = cg_try_depth + 1;
    if !cg_gen_block(s.true_body) {
        cg_try_depth = cg_try_depth - 1;
        return false;
    }
    !!! Normal exit: unlink the frame and step over the CATCH block.
    cg_emit_try_unlink();
    int jmp_after = em_jmp_rel32();

    !!! CATCH: reached only when the runtime resumed here, which already unlinked
    !!! the frame.
    cg_try_depth = cg_try_depth - 1;
    em_patch_disp32(hdisp + 3, em_tell(), hdisp + 7);
    if have_var {
        cg_emit_load_rax_text(cg_exc_code_off);
        cg_store_var(cv.stack_offset, INT, false, cv.is_global);
    }
    if !cg_gen_block(s.false_body) {
        return false;
    }
    em_patch_jmp_rel32(jmp_after);
    return true;
}
