#once
!~
 ~  bootstrap/backend/codegen_ret.b: the RET statement.
 ~
 ~  A function that returns a struct copies it
 ~  into a heap block and answers that pointer, which is what the frontend's
 ~  `STRUCT` return is. Either way the return is taken through the function's own
 ~  prologue: rsp is put back on rbp and the four saved registers are popped before
 ~  the ret, so a return from the middle of a body leaves the frame the way the
 ~  prologue built it.
 ~!

#head "cg_heads"

bool cg_gen_ret -> @CmpStmt s {
    !!! A struct return: the value is copied into a heap block of its own.
    str rs = cg_ret_struct_get(cg_current_func);
    if !pe_eq(rs, "") && s.init_expr != null {
        @CmpStructType st = cg_find_struct(rs);
        int S = 8;
        if st != null {
            S = st.total_size;
        }
        if s.init_expr.nk == VAR_REF {
            @CgVarInfo sit = cg_sym_find(s.init_expr.var_name);
            if sit != null {
                !!! The returned copy comes from the runtime's pool.
                cg_emit_alloc_block(S);
                em_push_rax();
                em_db(0x48);
                em_db(0x89);
                em_db(0xC7);
                cg_lea_var(sit.stack_offset);
                em_db(0x48);
                em_db(0x89);
                em_db(0xC6);
                em_db(0xB9);
                em_dd(S);
                em_db(0xFC);
                em_db(0xF3);
                em_db(0xA4);
                em_pop_rax();
                !!! Leaving the function abandons every active TRY body: unlink the
                !!! frames so a later exception cannot resume in a function that
                !!! already returned.
                cg_emit_try_unlinks();
                em_db(0x48);
                em_db(0x89);
                em_db(0xEC);
                em_db(0x48);
                em_db(0x83);
                em_db(0xEC);
                em_db(0x18);
                em_db(0x5F);
                em_db(0x5E);
                em_db(0x5B);
                em_db(0x5D);
                em_ret();
                return true;
            }
        }
    }
    cg_gen_expr(s.init_expr);
    !!! See above: a return leaves the TRY bodies.
    cg_emit_try_unlinks();
    em_db(0x48);
    em_db(0x89);
    em_db(0xEC);
    em_db(0x48);
    em_db(0x83);
    em_db(0xEC);
    em_db(0x18);
    em_db(0x5F);
    em_db(0x5E);
    em_db(0x5B);
    em_db(0x5D);
    em_ret();
    return true;
}
