#once
!~
 ~  bootstrap/frontend/parser_flow.b: the frontend/parser_flow.
 ~
 ~  The statements that steer the run: if/elif/else, while, do/while, switch with
 ~  its cases and its unmatch arm, and the three that only make sense inside a loop
 ~  or a body (skip, continue, and the raw `rcode` text).
 ~
 ~  the toolchain parser appends to `stmts` and moves statements between the lists it
 ~  builds (each case body is a list of its own). Here a body is the chain of its
 ~  statements, and a switch keeps one entry per case: the type is in parser.b with
 ~  the rest of the statement node.
 ~!

#head "parser"

@StmtNode p_if {
    @StmtNode first = p_new_stmt(IF_ELSE);
    p_adv();
    first.expr = parse_expr(0);
    if first.expr == null {
        return first;
    }
    first.true_body = p_block();
    !!! `elif` chains on: the arm hangs off the false body of the arm before it,
    !!! which is how the toolchain nests its IF_ELSE statements too.
    @StmtNode chain = first;
    while true {
        if p_name_is("elif") {
            p_adv();
            @StmtNode inner = p_new_stmt(IF_ELSE);
            inner.expr = parse_expr(0);
            if inner.expr == null {
                return first;
            }
            inner.true_body = p_block();
            chain.false_body = p_chain_stmt(chain.false_body, inner);
            chain = inner;
            continue;
        }
        if p_name_is("else") {
            p_adv();
            chain.false_body = p_chain_stmt(chain.false_body, p_block());
            skip;
        }
        skip;
    }
    return first;
}

@StmtNode p_while {
    @StmtNode s = p_new_stmt(WHILE);
    p_adv();
    s.expr = parse_expr(0);
    if s.expr == null {
        return s;
    }
    s.true_body = p_block();
    return s;
}

@StmtNode p_do_while {
    @StmtNode s = p_new_stmt(DO_WHILE);
    p_adv();
    !!! The body runs first, so it is read before the condition.
    s.true_body = p_block();
    if !p_name_is("while") {
        p_error_cur("missing 'while' after do block");
        return s;
    }
    p_adv();
    s.expr = parse_expr(0);
    if p_is(TK_SEMI) {
        p_adv();
    }
    return s;
}

@StmtNode p_break {
    @StmtNode s = p_new_stmt(BREAK);
    p_adv();
    if p_is(TK_SEMI) {
        p_adv();
    } else {
        p_error_cur("missing ';' after skip");
    }
    return s;
}

@StmtNode p_continue {
    @StmtNode s = p_new_stmt(CONTINUE);
    p_adv();
    if p_is(TK_SEMI) {
        p_adv();
    } else {
        p_error_cur("missing ';' after continue");
    }
    return s;
}

@StmtNode p_rcode {
    @StmtNode s = p_new_stmt(RCODE);
    p_adv();
    if !p_is(TK_STRING) {
        p_error_cur("missing string literal after 'rcode'");
        return null;
    }
    s.rcode_text = span_text(p_cur.start + 1, p_cur.stop - 1);
    p_adv();
    if p_is(TK_SEMI) {
        p_adv();
    } else {
        p_error_prev_sug("missing ';'", ";");
    }
    return s;
}

@StmtNode p_switch {
    @StmtNode s = p_new_stmt(SWITCH);
    p_adv();
    s.expr = parse_expr(0);
    if s.expr == null {
        p_sync();
        return null;
    }
    if !p_is(TK_LBRACE) {
        p_error_cur("missing '{'");
        return null;
    }
    p_adv();

    int brace_depth = 1;
    while !p_is(TK_EOF) && brace_depth > 0 {
        if p_is(TK_LBRACE) {
            brace_depth = brace_depth + 1;
            p_adv();
            continue;
        }
        if p_is(TK_RBRACE) {
            brace_depth = brace_depth - 1;
            if brace_depth == 0 {
                p_adv();
                skip;
            }
            p_adv();
            continue;
        }
        if p_is(TK_KEYWORD) && p_name_is("case") {
            p_adv();
            s.case_exprs = p_chain_expr(s.case_exprs, parse_expr(0));
            if p_is(TK_COLON) {
                p_adv();
            }
            !!! The body of the case runs until the next case, the unmatch arm or
            !!! the closing brace. It starts a new mark in the body chain, so the
            !!! cases stay apart.
            @StmtNode mark = p_new_stmt(CASE_MARK);
            s.case_bodies = p_chain_stmt(s.case_bodies, mark);
            while !p_is(TK_EOF) && !p_is(TK_RBRACE) &&
                  !(p_is(TK_KEYWORD) && (p_name_is("case") || p_name_is("unmatch"))) {
                @StmtNode st = parse_stmt();
                if st == null {
                    continue;
                }
                s.case_bodies = p_chain_stmt(s.case_bodies, st);
            }
            continue;
        }
        if p_is(TK_KEYWORD) && p_name_is("unmatch") {
            p_adv();
            if p_is(TK_COLON) {
                p_adv();
            }
            while !p_is(TK_EOF) && !p_is(TK_RBRACE) &&
                  !(p_is(TK_KEYWORD) && p_name_is("case")) {
                @StmtNode st2 = parse_stmt();
                if st2 == null {
                    continue;
                }
                s.unmatch_body = p_chain_stmt(s.unmatch_body, st2);
            }
            continue;
        }
        p_error_cur("missing 'case' or 'unmatch'");
        p_adv();
    }
    if brace_depth > 0 && p_is(TK_EOF) {
        p_error_cur("missing '}'");
    }
    return s;
}
