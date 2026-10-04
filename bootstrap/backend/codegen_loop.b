#once
!~
 ~  bootstrap/backend/codegen_loop.b: REPEAT, END and CONTINUE.
 ~
 ~  A loop keeps two stacks: where to jump
 ~  when it ends (every `skip` seen so far, patched once the body is behind it) and
 ~  where to jump when it goes round again. A nested loop saves the outer one, so a
 ~  `skip` always leaves the innermost loop it stands in.
 ~!

#head "cg_heads"

bool cg_gen_repeat -> @CmpStmt s {
    !!! The break stack of the enclosing loop, put aside for this one.
    @CmpIntNode saved_breaks = cg_break_stack;
    cg_break_stack = null;
    int loop_start = em_tell();
    cg_continue_targets = cg_int_push(cg_continue_targets, loop_start);
    !!! Evaluate the condition the long way, or branch on a comparison itself (see
    !!! cg_gen_if_else).
    int jz_end = 0;
    if !cg_cmp_jump_false(s.init_expr) {
        cg_gen_expr(s.init_expr);
        em_test_rax_rax();
        jz_end = em_jz_rel32();
    } else {
        jz_end = cg_cmp_jump_pos;
    }
    if !cg_gen_block(s.true_body) {
        return false;
    }
    !!! Back to the condition test.
    em_db(0xE9);
    em_dd(loop_start - (em_tell() + 4));
    !!! Every break seen in the body lands here, after the loop.
    em_patch_jz_rel32(jz_end);
    @CmpIntNode bp = cg_break_stack;
    while bp != null {
        em_patch_jmp_rel32((int)bp.v);
        bp = bp.next;
    }
    cg_break_stack = saved_breaks;
    cg_continue_targets = cg_int_pop(cg_continue_targets);
    return true;
}

bool cg_gen_end -> @CmpStmt s {
    !!! A break out of a loop also leaves every TRY body opened inside it.
    cg_emit_try_unlinks();
    int pos = em_jmp_rel32();
    cg_break_stack = cn_int(cg_break_stack, pos);
    return true;
}

bool cg_gen_continue -> @CmpStmt s {
    if cg_continue_targets == null {
        cg_stmt_err = cg_err_at(s.line, s.col, "continue outside of loop");
        return false;
    }
    !!! `continue` jumps to the loop test, which runs at the loop's own stack level,
    !!! so the TRY frames opened inside the body go away first.
    cg_emit_try_unlinks();
    int pos = em_jmp_rel32();
    int target = (int)cg_continue_targets.v;
    em_put32(pos + 1, target - (pos + 5));
    return true;
}
