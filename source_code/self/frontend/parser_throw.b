#once
!~
 ~  bootstrap/frontend/parser_throw.b: the frontend/parser_throw.
 ~
 ~  `throw <exception code>;` hands the code to the innermost enclosing `try`.
 ~  Nothing after the throw runs: the exception abandons the rest of the try body.
 ~!

#head "parser"

@StmtNode p_throw {
    @StmtNode s = p_new_stmt(THROW);
    p_adv();
    s.expr = parse_expr(0);
    if s.expr == null {
        !!! parse_expr(0) reported the reason; the statement is still answered so the
        !!! rest of the file keeps parsing.
        return s;
    }
    if p_is(TK_SEMI) {
        p_adv();
    } else {
        p_error_prev_sug("missing ';' after throw", ";");
    }
    return s;
}
