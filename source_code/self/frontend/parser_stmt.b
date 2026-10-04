#once
!~
 ~  bootstrap/frontend/parser_stmt.b: the frontend/parser_stmt.
 ~
 ~  The one place that decides what a statement is. It is all lookahead: a name
 ~  followed by `=` is an assignment, by `(` a call, by `[` a subscript that may be
 ~  either, and a type at the head of the statement is a declaration or a function
 ~  depending on what stands after the name. That is why the parser walks a token
 ~  list rather than a stream - the toolchain parser reads `tokens[pos + n]` for exactly
 ~  this, and this implementation reads `p_peek(n)`.
 ~!

#head "parser"
#head "attributes"
#head "rules"

!!! Whether the current token is the keyword `lit` (an identifier with that
!!! spelling is not a keyword here, which is what the toolchain is_kw tests).
bool p_is_kw -> str lit {
    return p_is(TK_KEYWORD) && p_name_is(lit);
}

!!! `attribute <object>: <NAME>[, <NAME>]*`.
!!!
!!! The statement says something about an object the compiler cannot work out on its
!!! own: that a name is used, that its value is read, that it is initialized, what
!!! its type is, or what is known about a function's body. The object is named the
!!! way the source names it - a plain name, a member of a struct (`S.f`, `S.m`) or a
!!! package member (`pkg::f`) - and the names after the `:` are the built-in ones in
!!! attributes.b.
!!!
!!! Nothing is emitted for the statement: what it says is recorded in `attr_uses` and
!!! the passes that the attribute speaks to read it there, so an attribute may stand
!!! before or after the declaration it talks about. the `Parser::parse_attribute`
!!! is the same step.
@StmtNode p_attribute {
    p_adv();
    str object = "";
    str owner = "";
    str member = "";
    bool scoped = false;
    if !p_is(TK_IDENT) {
        p_error("missing object name after 'attribute'");
        return null;
    }
    object = span_text(p_cur.start, p_cur.stop);
    p_adv();
    while p_is(TK_DOT) || p_is(TK_SCOPE) {
        if !p_peek_is(1, TK_IDENT) {
            skip;
        }
        bool dotted = p_is(TK_DOT);
        p_adv();
        if dotted {
            !!! The last `.` of the name is where the member begins: the passes key a
            !!! member by the struct and the member, and a `str` cannot be indexed
            !!! here, so the two halves are taken while the name is being read.
            owner = object;
            member = span_text(p_cur.start, p_cur.stop);
            object = object + ".";
        } else {
            object = object + "::";
            scoped = true;
        }
        object = object + span_text(p_cur.start, p_cur.stop);
        p_adv();
    }
    if !p_is(TK_COLON) {
        p_error("missing ':' after the object of 'attribute'");
        return null;
    }
    p_adv();
    while true {
        if !p_is(TK_IDENT) {
            p_error("missing attribute name after ':'");
            return null;
        }
        str nm = span_text(p_cur.start, p_cur.stop);
        if attr_kind(nm) == ATTR_KIND_NONE {
            !!! A name the compiler does not know is reported here, so a typo is not
            !!! quietly taken for a property the compiler does not have.
            p_error_at(p_cur.line, p_cur.col, p_cur.stop - p_cur.start,
                       "unknown attribute '" + nm + "'");
        } else {
            attr_use_add(object, nm, owner, member, scoped, p_cur.line, p_cur.col,
                         p_cur.stop - p_cur.start);
        }
        p_adv();
        if p_is(TK_COMMA) {
            p_adv();
            continue;
        }
        skip;
    }
    !!! The statement needs no ';': `attribute a: USED` stands on its own line the way
    !!! a directive does, and a ';' written after it is accepted.
    if p_is(TK_SEMI) {
        p_adv();
    }
    return null;
}

!!! `rule <NAME>(<expr>, <expr>, ...)`.
!!!
!!! The statement asks the compiler to run one of the built-in checks (rules.b) over
!!! the program. Its arguments are expressions: the strings a rule reports with, the
!!! names of the objects it looks at, and - for `pair` - a call of the rule helper
!!! `not_pair(a, b, ...)`, which is what carries the report.
!!!
!!! Like `attribute` it may stand anywhere a statement may, it emits nothing, and
!!! what it names has to be declared before it. the `Parser::parse_rule` is the
!!! same step.
@StmtNode p_rule {
    p_adv();
    if !p_is(TK_IDENT) {
        p_error("missing rule name after 'rule'");
        return null;
    }
    str rname = span_text(p_cur.start, p_cur.stop);
    int rline = p_cur.line;
    int rcol = p_cur.col;
    int rlen = p_cur.stop - p_cur.start;
    if rule_find(rname) == RULE_NONE {
        p_error_at(rline, rcol, rlen, "unknown rule '" + rname + "'");
    }
    p_adv();
    if !p_is(TK_LPAREN) {
        p_error("missing '(' after the rule name");
        return null;
    }
    p_adv();
    @ExprNode args = null;
    int nargs = 0;
    if !p_is(TK_RPAREN) {
        while true {
            @ExprNode a = parse_expr(0);
            if a == null {
                p_sync_to_rparen_or_semi();
                return null;
            }
            args = p_chain_expr(args, a);
            nargs = nargs + 1;
            if p_is(TK_COMMA) {
                p_adv();
                continue;
            }
            skip;
        }
    }
    if !p_is(TK_RPAREN) {
        p_error("missing ')'");
        p_unmatched_note(rline, rcol, '(');
        p_sync_to_rparen_or_semi();
        return null;
    }
    p_adv();
    if p_is(TK_SEMI) {
        p_adv();
    }
    if rule_find(rname) == RULE_NONE {
        !!! Reported above; the statement still runs nothing.
        return null;
    }
    rule_use_add(rname, args, nargs, rline, rcol, rlen);
    return null;
}

@StmtNode parse_stmt {
    !!! A compound assignment operator (`+=`, `-=`, ...) is not part of the
    !!! language. The first one in this statement is reported and the rest of the
    !!! statement is stepped over, so the left-hand side does not turn into a
    !!! second, misleading error.
    int look = p_pos;
    while p_kind_at(look) != TK_EOF {
        TokenKind k = p_tok(look).tk;
        if k == TK_SEMI || k == TK_LBRACE || k == TK_RBRACE {
            skip;
        }
        if k == TK_COMPOUND_ASSIGN {
            p_error_at(p_tok(look).line, p_tok(look).col,
                       p_tok(look).stop - p_tok(look).start,
                       "invalid operator '" + span_text(p_tok(look).start, p_tok(look).stop) + "'");
            while !p_is(TK_EOF) && !p_is(TK_SEMI) && !p_is(TK_RBRACE) && !p_is(TK_LBRACE) {
                p_adv();
            }
            if p_is(TK_SEMI) {
                p_adv();
            }
            return null;
        }
        look = look + 1;
    }

    !!! A generic struct type at the start of a statement (`Box(int) b = {5};`) is a
    !!! declaration; the `name(...)` call rules below would read it as a call.
    if p_at_generic_type_head() {
        return p_decl_or_func();
    }
    !!! A package-qualified type at the start of a statement: `pkg::Type name;`.
    if p_is(TK_IDENT) && p_peek_is(1, TK_SCOPE) && p_peek_is(2, TK_IDENT) &&
       p_peek_is(3, TK_IDENT) {
        return p_declare();
    }

    if p_is_kw("type") { return p_struct_def(); }
    if p_is_kw("if") { return p_if(); }
    if p_is_kw("while") { return p_while(); }
    if p_is_kw("do") { return p_do_while(); }
    if p_is_kw("try") { return p_try(); }
    if p_is_kw("throw") { return p_throw(); }
    if p_is_kw("kind") { return p_enum(); }
    if p_is_kw("BLANG_API") { return p_bapi(); }
    if p_is_kw("skip") { return p_break(); }
    if p_is_kw("continue") { return p_continue(); }
    if p_is_kw("local") { return p_local_function(); }
    if p_is_kw("stub") { return p_stub_function(); }
    if p_is_kw("reload") { return p_reload_function(); }
    if p_is_kw("package") { return p_package(); }
    if p_is_kw("use") { return p_use(); }
    if p_is_kw("attribute") { return p_attribute(); }
    if p_is_kw("rule") { return p_rule(); }
    if p_is_kw("introduce") { return p_introduce(); }
    if p_is_kw("__get_built_in_func") { return p_builtin_bind(); }
    if p_is_kw("switch") { return p_switch(); }
    if p_is_kw("return") { return p_return(); }
    if p_is_kw("end") { return p_end(); }
    if p_is_kw("back") { return p_back(); }
    if p_is_kw("rcode") { return p_rcode(); }

    !!! `$ptr = expr`.
    if p_is(TK_REF) && p_peek_is(1, TK_IDENT) && p_peek_is(2, TK_ASSIGN) {
        return p_dref_assign();
    }
    !!! `name = expr`.
    if p_is(TK_IDENT) && p_peek_is(1, TK_ASSIGN) {
        return p_assign();
    }
    !!! `++name` and `--name`.
    if p_is(TK_PLUS_PLUS) || p_is(TK_MINUS_MINUS) {
        return p_incr();
    }
    !!! `name++` and `name--`.
    if p_is(TK_IDENT) && (p_peek_is(1, TK_PLUS_PLUS) || p_peek_is(1, TK_MINUS_MINUS)) {
        return p_incr();
    }
    !!! `name[ ... ] = ...` or `name[ ... ].method( ... )`.
    if p_is(TK_IDENT) && p_peek_is(1, TK_LBRACKET) {
        int depth = 0;
        int look2 = p_pos + 2;
        while p_kind_at(look2) != TK_RBRACKET || depth > 0 {
            if p_tok(look2).tk == TK_EOF {
                skip;
            }
            if p_tok(look2).tk == TK_LBRACKET {
                depth = depth + 1;
            } else if p_tok(look2).tk == TK_RBRACKET {
                depth = depth - 1;
            }
            look2 = look2 + 1;
        }
        if p_tok(look2).tk == TK_RBRACKET {
            look2 = look2 + 1;
        }
        if p_tok(look2).tk == TK_DOT && p_tok(look2 + 1).tk == TK_IDENT &&
           p_tok(look2 + 2).tk == TK_LPAREN {
            return p_func_call();
        }
        return p_assign();
    }
    !!! `name(...)`.
    if p_is(TK_IDENT) && p_peek_is(1, TK_LPAREN) {
        return p_func_call();
    }
    !!! `name.method(...)`.
    if p_is(TK_IDENT) && p_peek_is(1, TK_DOT) && p_peek_is(2, TK_IDENT) &&
       p_peek_is(3, TK_LPAREN) {
        return p_func_call();
    }
    !!! A member chain with at least two fields: an assignment or a call, and a
    !!! chain that ends in a subscript is decided by `chain_stmt_kind` below.
    if p_is(TK_IDENT) && p_peek_is(1, TK_DOT) && p_peek_is(2, TK_IDENT) &&
       p_peek_is(3, TK_DOT) && p_peek_is(4, TK_IDENT) {
        int look3 = p_pos + 2;
        while p_kind_at(look3 + 1) == TK_DOT && p_kind_at(look3 + 2) == TK_IDENT {
            look3 = look3 + 2;
        }
        TokenKind nk = p_tok(look3 + 1).tk;
        if nk == TK_ASSIGN {
            return p_assign();
        }
        if nk == TK_LPAREN {
            return p_func_call();
        }
        !!! The chain does not end at `=` or `(`: a subscript follows
        !!! (`o.in.data[2].a = 44;`), which the bracket-aware rule knows.
        int kind1 = p_chain_stmt_kind();
        if kind1 == 1 {
            return p_assign();
        }
        if kind1 == 2 {
            return p_func_call();
        }
        p_error_cur("meaningless '" + span_text(p_cur.start, p_cur.stop) + "'");
        return null;
    }
    !!! `name.field = ...`.
    if p_is(TK_IDENT) && p_peek_is(1, TK_DOT) && p_peek_is(2, TK_IDENT) &&
       p_peek_is(3, TK_ASSIGN) {
        return p_assign();
    }
    !!! `name.field(...)`.
    if p_is(TK_IDENT) && p_peek_is(1, TK_DOT) && p_peek_is(2, TK_IDENT) &&
       p_peek_is(3, TK_LPAREN) {
        return p_func_call();
    }
    if p_is_decl_or_func_start() {
        return p_decl_or_func();
    }
    !!! A member chain that contains a subscript (`b.data[0] = 10;`,
    !!! `o.people[i].name = "x";`) or a method on such a chain
    !!! (`o.data[i][j].set(1);`): the rules above only match chains without
    !!! brackets, so they are recognised here.
    int kind2 = p_chain_stmt_kind();
    if kind2 == 1 {
        return p_assign();
    }
    if kind2 == 2 {
        return p_func_call();
    }
    !!! An `=` the statement names no target for (`1 = "hello";`, `1 + 2 = 3;`) is
    !!! an assignment that cannot be written, not a meaningless statement: the two
    !!! are told apart here so that the message names the assignment, which is what
    !!! the source was trying to write. It is the same message the argument lists
    !!! report for `system.out(1 = "hello")`. the `Parser::stmt_assign_at` and
    !!! the branch above its dispatch are the same step.
    int at = p_stmt_assign_at();
    if at >= 0 {
        !!! The caret stands on the `=` and not on the token the statement starts
        !!! with, the way the argument list points at its own `=`.
        p_error_at(p_tok(at).line, p_tok(at).col, 1, "invalid assignment");
        p_sync();
        return null;
    }
    p_error_cur("meaningless '" + span_text(p_cur.start, p_cur.stop) + "'");
    return null;
}

!!! The `=` standing at the top level of the statement the parser is looking at,
!!! or -1 when the statement has none. Only the tokens outside any bracket are
!!! looked at, so an `=` inside an argument list or a subscript is not one of them,
!!! and the scan stops at the `;` that ends the statement.
int p_stmt_assign_at {
    int depth = 0;
    int j = p_pos;
    while p_kind_at(j) != TK_EOF {
        TokenKind k = p_kind_at(j);
        if k == TK_LPAREN || k == TK_LBRACKET {
            depth = depth + 1;
        } else if k == TK_RPAREN || k == TK_RBRACKET {
            if depth == 0 {
                return -1;
            }
            depth = depth - 1;
        } else if depth == 0 && k == TK_ASSIGN {
            return j;
        } else if depth == 0 && (k == TK_SEMI || k == TK_LBRACE || k == TK_RBRACE) {
            return -1;
        }
        j = j + 1;
    }
    return -1;
}

!!! Whether an identifier could still be a variable of a declared struct type.
!!! (A builtin-object annotation is a statement head of its own.)
int p_chain_stmt_kind {
    if !p_is(TK_IDENT) {
        return 0;
    }
    int j = p_pos + 1;
    bool chain = false;
    while p_kind_at(j) != TK_EOF {
        if p_tok(j).tk == TK_DOT && p_tok(j + 1).tk == TK_IDENT {
            !!! A method call on the chain seen so far (`o.data[i][j].set(1)`).
            if p_tok(j + 2).tk == TK_LPAREN {
                if chain {
                    return 2;
                }
                return 0;
            }
            chain = true;
            j = j + 2;
            continue;
        }
        if p_tok(j).tk == TK_LBRACKET {
            int depth = 0;
            while p_kind_at(j) != TK_EOF {
                if p_tok(j).tk == TK_LBRACKET {
                    depth = depth + 1;
                } else if p_tok(j).tk == TK_RBRACKET {
                    depth = depth - 1;
                    j = j + 1;
                    if depth == 0 {
                        skip;
                    }
                    continue;
                }
                j = j + 1;
            }
            chain = true;
            continue;
        }
        skip;
    }
    if !chain || p_tok(j).tk == TK_EOF {
        return 0;
    }
    TokenKind k = p_tok(j).tk;
    if k == TK_ASSIGN {
        return 1;
    }
    !!! A method call on the chain (`o.data[i][j].set(1);`).
    if k == TK_DOT && p_tok(j + 1).tk == TK_IDENT && p_tok(j + 2).tk == TK_LPAREN {
        return 2;
    }
    return 0;
}
