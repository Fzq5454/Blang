#once
!~
 ~  bootstrap/frontend/parser_try.b: the frontend/parser_try.
 ~
 ~  `try { ... } exception (e) { ... }`. The caught value is the code of the
 ~  exception that ended the try body and reaches the handler as an integer: the
 ~  name in the parentheses is an `int` of the handler's own. The name is optional -
 ~  `exception ()`, or a bare `exception {`, runs the handler and throws the code
 ~  away, for when the program only needs to know that it failed.
 ~!

#head "parser"

@StmtNode p_try {
    @StmtNode s = p_new_stmt(TRY_CATCH);
    p_adv();
    s.true_body = p_block();

    if !p_name_is("exception") {
        p_error_cur("expected 'exception' after the try block");
        p_sync();
        return null;
    }
    p_adv();

    if p_is(TK_LPAREN) {
        p_adv();
        if p_is(TK_IDENT) {
            s.var_name = span_text(p_cur.start, p_cur.stop);
            s.var_line = p_cur.line;
            s.var_col = p_cur.col;
            p_adv();
        } else if !p_is(TK_RPAREN) {
            p_error_cur("expected the name of the exception variable");
            p_sync();
            return null;
        }
        if !p_is(TK_RPAREN) {
            p_error_cur("expected ')' after the exception variable");
            p_sync();
            return null;
        }
        p_adv();
    }

    s.false_body = p_block();
    return s;
}
