#once
!~
 ~  bootstrap/backend/parser_flow.b: the IF, SWITCH and REPEAT statements.
 ~
 ~  the toolchain builds a case body by taking the
 ~  statement a nested `parse_stmt()` just pushed off the end of the statement
 ~  vector; here the statement chain being built is `cp_stmts` and the last link is
 ~  taken off the same way, which is what `cp_take_last` does.
 ~!

#head "parser"

!!! The statement that was added last, taken off the chain being built.
@CmpStmt cp_take_last {
    if cp_stmts == null {
        return null;
    }
    if cp_stmts.next == null {
        @CmpStmt only = cp_stmts;
        cp_stmts = null;
        return only;
    }
    @CmpStmt prev = cp_stmts;
    @CmpStmt t = cp_stmts.next;
    while t.next != null {
        prev = t;
        t = t.next;
    }
    prev.next = null;
    return t;
}

void cp_parse_if {
    @CmpStmt s = cs_new(IF_ELSE);
    s.line = cp_cur.line;
    s.col = cp_cur.col;
    cp_advance();
    if cp_cur.tk != CT_LPAREN {
        cp_error("expected '(' after IF");
        end;
    }
    cp_advance();
    s.init_expr = cp_parse_expr();
    if cp_has_error() {
        end;
    }
    if cp_cur.tk != CT_RPAREN {
        cp_error("expected ')' after condition");
        end;
    }
    cp_advance();
    if !cp_is("THEN") {
        cp_error("expected THEN");
        end;
    }
    cp_advance();
    s.true_body = cp_block();
    if cp_is("ELSE") {
        cp_advance();
        s.false_body = cp_block();
    }
    cp_stmts = cs_add(cp_stmts, s);
}

void cp_parse_switch {
    @CmpStmt s = cs_new(SWITCH);
    s.line = cp_cur.line;
    s.col = cp_cur.col;
    cp_advance();
    if cp_cur.tk != CT_LPAREN {
        cp_error("expected '(' after SWITCH");
        end;
    }
    cp_advance();
    s.init_expr = cp_parse_expr();
    if cp_has_error() {
        end;
    }
    if cp_cur.tk != CT_RPAREN {
        cp_error("expected ')'");
        end;
    }
    cp_advance();
    if !cp_is("THEN") {
        cp_error("expected THEN");
        end;
    }
    cp_advance();
    if cp_cur.tk != CT_LPAREN {
        cp_error("expected '(' after THEN");
        end;
    }
    cp_advance();
    @CmpCaseBody arms = null;
    while !cp_has_error() && cp_cur.tk != CT_RPAREN && cp_cur.tk != CT_EOF {
        if cp_is("CASE") {
            cp_advance();
            s.case_exprs = ce_add(s.case_exprs, cp_parse_expr());
            if cp_has_error() {
                skip;
            }
            if cp_cur.tk == CT_OPERATOR && pe_eq(cp_cur.text, ":") {
                cp_advance();
            }
            @CmpStmt body = null;
            while !cp_has_error() && cp_cur.tk != CT_RPAREN && cp_cur.tk != CT_EOF &&
                  !cp_is("CASE") && !cp_is("UNMATCH") {
                cp_parse_stmt();
                body = cs_add(body, cp_take_last());
            }
            arms = cc_add(arms, body);
        } else if cp_is("UNMATCH") {
            cp_advance();
            if cp_cur.tk == CT_OPERATOR && pe_eq(cp_cur.text, ":") {
                cp_advance();
            }
            while !cp_has_error() && cp_cur.tk != CT_RPAREN && cp_cur.tk != CT_EOF &&
                  !cp_is("CASE") {
                cp_parse_stmt();
                s.unmatch_body = cs_add(s.unmatch_body, cp_take_last());
            }
        } else {
            cp_error("expected CASE or UNMATCH, got '" + cp_cur.text + "'");
            cp_advance();
        }
    }
    if cp_cur.tk != CT_RPAREN {
        cp_error("expected ')' after SWITCH");
    } else {
        cp_advance();
    }
    cs_set_cases(s, arms);
    cp_stmts = cs_add(cp_stmts, s);
}

void cp_parse_repeat {
    @CmpStmt s = cs_new(REPEAT);
    s.line = cp_cur.line;
    s.col = cp_cur.col;
    cp_advance();
    s.init_expr = cp_parse_expr();
    if cp_has_error() {
        end;
    }
    if !cp_is("THEN") {
        cp_error("expected THEN");
        end;
    }
    cp_advance();
    s.true_body = cp_block();
    cp_stmts = cs_add(cp_stmts, s);
}
