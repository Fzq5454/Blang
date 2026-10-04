#once
!~
 ~  bootstrap/frontend/parser_return.b: the frontend/parser_return.
 ~
 ~  The three statements that leave a body: `return <value>;` hands a value back,
 ~  `end;` leaves a void function, and `back <value>;` leaves with the value the
 ~  enclosing call answers - which is how a `local` helper reports a result.
 ~!

#head "parser"

@StmtNode p_return {
    @StmtNode s = p_new_stmt(RETURN);
    p_adv();
    s.expr = parse_expr(0);
    if p_is(TK_SEMI) {
        p_adv();
    } else {
        p_error_cur("missing ';' after return");
    }
    return s;
}

@StmtNode p_end {
    @StmtNode s = p_new_stmt(END);
    p_adv();
    if p_is(TK_SEMI) {
        p_adv();
    } else {
        p_error_cur("missing ';' after end");
    }
    return s;
}

@StmtNode p_back {
    @StmtNode s = p_new_stmt(BACK);
    p_adv();
    s.expr = parse_expr(0);
    if p_is(TK_SEMI) {
        p_adv();
    } else {
        p_error_cur("missing ';' after back");
    }
    return s;
}
