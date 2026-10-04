#once
!~
 ~  bootstrap/backend/codegen_stmt.b: the statement dispatch.
 ~
 ~  one statement goes to the function that
 ~  emits it. An expression that ran into an error reports it through cg_gen_error,
 ~  which wins over the answer of the statement itself - that is how a call fails
 ~  for a reason found while its arguments were generated.
 ~!

#head "cg_heads"

bool cg_gen_stmt -> @CmpStmt s {
    cg_gen_error = "";
    bool ok = false;
    switch s.nk {
        case DECLARED:
            ok = cg_gen_declared(s);
            skip;
        case CALL:
            ok = cg_gen_call(s);
            skip;
        case CAST_STMT:
            ok = cg_gen_cast(s);
            skip;
        case DREF:
            ok = cg_gen_dref(s);
            skip;
        case ICALL_STMT:
            ok = cg_gen_icall(s);
            skip;
        case RELEASE:
            ok = cg_gen_release(s);
            skip;
        case BSPREAD:
            ok = cg_gen_bspread(s);
            skip;
        case EXIT:
            ok = cg_gen_exit(s);
            skip;
        case IF_ELSE:
            ok = cg_gen_if_else(s);
            skip;
        case REPEAT:
            ok = cg_gen_repeat(s);
            skip;
        case END:
            ok = cg_gen_end(s);
            skip;
        case CONTINUE:
            ok = cg_gen_continue(s);
            skip;
        case FUNC_STMT:
            ok = cg_gen_func(s);
            skip;
        case RET:
            ok = cg_gen_ret(s);
            skip;
        case SWITCH:
            ok = cg_gen_switch(s);
            skip;
        case TRY_CATCH:
            ok = cg_gen_try_catch(s);
            skip;
        case RAISE:
            ok = cg_gen_raise(s);
            skip;
        unmatch:
            cg_stmt_err = cg_err_at(s.line, s.col, "unknown statement kind");
            return false;
    }
    if !pe_eq(cg_gen_error, "") && ok {
        cg_stmt_err = cg_gen_error;
        cg_gen_error = "";
        return false;
    }
    return ok;
}
