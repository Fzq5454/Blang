#once
!~
 ~  bootstrap/frontend/parser_assign.b: the frontend/parser_assign.
 ~
 ~  Assignment, assignment through a pointer (`$p = ...`) and the two increments.
 ~  the toolchain version appends its statement to `stmts` and the caller keeps it; here
 ~  the statement is answered and the caller links it, which is the shape every
 ~  parse function of this implementation has.
 ~
 ~  A list the toolchain holds in a a chain is a chain: the member chain of an
 ~  assignment, the indices of an indexed store, and the values of an array
 ~  initializer.
 ~!

#head "parser"

@StmtNode p_dref_assign {
    !!! `$ptr = expr`: the store goes through the pointer.
    @StmtNode s = p_new_stmt(DREF_ASSIGN);
    p_adv();
    if !p_is(TK_IDENT) {
        p_error_cur("missing variable name");
        return s;
    }
    s.var_name = span_text(p_cur.start, p_cur.stop);
    s.var_line = p_cur.line;
    s.var_col = p_cur.col;
    p_adv();
    if !p_is(TK_ASSIGN) {
        p_error_cur("missing '='");
        return s;
    }
    p_adv();
    s.expr = parse_expr(0);
    if p_is(TK_SEMI) {
        p_adv();
    } else {
        p_error_prev_sug("missing ';'", ";");
    }
    return s;
}

!!! One `name.field.field ...` chain, read into the statement. Both the plain and
!!! the indexed form collect it, which is why it is written once.
void p_assign_members -> @StmtNode s {
    while p_is(TK_DOT) && p_peek_is(1, TK_IDENT) {
        p_adv();
        if s.member_chain == null {
            s.member_line = p_cur.line;
            s.member_col = p_cur.col;
        }
        s.member_chain = p_chain_str(s.member_chain,
                                     p_new_span(p_cur.start, p_cur.stop, p_cur.line, p_cur.col));
        p_adv();
    }
    if s.member_chain != null {
        s.member_name = s.member_chain.s;
    }
}

@StmtNode p_assign {
    @StmtNode s = p_new_stmt(ASSIGN);
    s.var_name = span_text(p_cur.start, p_cur.stop);
    s.var_line = p_cur.line;
    s.var_col = p_cur.col;
    p_adv();
    !!! `s->var_name == "super"`: the name that was just read decides, not the
    !!! token standing after it. Asking the current token left `super.name = "Amy"`
    !!! an ordinary member write of a variable called `super`, which the emitter
    !!! then spelled `super_name`.
    if p_text_eq(s.var_name, "super") {
        s.is_super = true;
    }
    p_assign_members(s);

    if p_is(TK_LBRACKET) {
        !!! `arr[i][j] = v` and `arr[i].field = v`: the fields collected so far are
        !!! the receiver the index applies to.
        s.is_array = true;
        s.members_before_index = p_chain_len(s.member_chain);
        @ExprNode idxs = null;
        while p_is(TK_LBRACKET) {
            p_adv();
            @ExprNode idx = parse_expr(0);
            if idx == null {
                return s;
            }
            if !p_is(TK_RBRACKET) {
                p_error_cur("missing ']'");
                return s;
            }
            p_adv();
            idxs = p_chain_expr(idxs, idx);
        }
        !!! A struct array member: `arr[i].field[.field...] = v`.
        p_assign_members(s);
        if !p_is(TK_ASSIGN) {
            p_error_cur("missing '='");
            return s;
        }
        p_adv();
        s.array_init = p_chain_expr(s.array_init, parse_expr(0));
        s.assign_indices = idxs;
        s.expr = idxs;
        !!! Only one index: the statement keeps it in `expr`, the way the toolchain copy
        !!! does when `idxs` has a single entry.
        if idxs != null && idxs.next != null {
            s.expr = null;
        }
    } else {
        if !p_is(TK_ASSIGN) {
            p_error_cur("missing '='");
            return s;
        }
        p_adv();
        if p_is(TK_LBRACE) {
            !!! `arr = { a, b, c }`.
            s.is_array = true;
            p_adv();
            while !p_is(TK_EOF) && !p_is(TK_RBRACE) {
                if p_is(TK_LBRACE) {
                    !!! A nested initializer (`arr = {{1,2},{3,4}}`) cannot be
                    !!! represented here: the group is skipped so the parse carries
                    !!! on instead of spinning on the brace.
                    p_error_at(p_cur.line, p_cur.col, 1, "nested initializer is not supported here");
                    int depth = 0;
                    while !p_is(TK_EOF) {
                        if p_is(TK_LBRACE) {
                            depth = depth + 1;
                        } else if p_is(TK_RBRACE) {
                            depth = depth - 1;
                        }
                        p_adv();
                        if depth <= 0 {
                            skip;
                        }
                    }
                    if p_is(TK_COMMA) {
                        p_adv();
                    }
                    continue;
                }
                @ExprNode e = parse_expr(0);
                if e == null {
                    p_adv();
                    skip;
                }
                s.array_init = p_chain_expr(s.array_init, e);
                if p_is(TK_COMMA) {
                    p_adv();
                }
            }
            if !p_is(TK_RBRACE) {
                p_error_cur("missing '}'");
                return s;
            }
            p_adv();
        } else {
            s.expr = parse_expr(0);
        }
    }
    if p_is(TK_SEMI) {
        p_adv();
        return s;
    }
    p_error_prev_sug("missing ';'", ";");
    if p_is(TK_SEMI) {
        p_adv();
    }
    return s;
}

!!! `++a`, `--a`, `a++`, `a--`. A prefix increment stands on the operator, a
!!! postfix one on the name.
@StmtNode p_incr {
    @StmtNode s = p_new_stmt(INCR);
    if p_is(TK_PLUS_PLUS) || p_is(TK_MINUS_MINUS) {
        s.incr_op = span_text(p_cur.start, p_cur.stop);
        s.incr_prefix = true;
        p_adv();
        if !p_is(TK_IDENT) {
            p_error_cur("missing variable name");
            return s;
        }
        s.var_name = span_text(p_cur.start, p_cur.stop);
        p_adv();
    } else if p_is(TK_IDENT) {
        s.var_name = span_text(p_cur.start, p_cur.stop);
        p_adv();
        if !p_is(TK_PLUS_PLUS) && !p_is(TK_MINUS_MINUS) {
            p_error_cur("missing '++' or '--'");
            return s;
        }
        s.incr_op = span_text(p_cur.start, p_cur.stop);
        s.incr_prefix = false;
        p_adv();
    }
    if p_is(TK_SEMI) {
        p_adv();
        return s;
    }
    p_error_prev_sug("missing ';'", ";");
    if p_is(TK_SEMI) {
        p_adv();
    }
    return s;
}
