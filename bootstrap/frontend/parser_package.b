#once
!~
 ~  bootstrap/frontend/parser_package.b: the frontend/parser_package.
 ~
 ~  `package name { <variables, functions, types> }` groups declarations under a
 ~  name; outside the block they are reached as `name::member`, and only after the
 ~  package has been imported with `use name;` (or `use name::member;`).
 ~
 ~  the toolchain keeps the members in the statement's `children` list, which this implementation
 ~  does not have: the members are the statement's own body here, the same chain a
 ~  function body or a block uses.
 ~!

#head "parser"

@StmtNode p_package {
    int pline = p_cur.line;
    int pcol = p_cur.col;
    p_adv();
    if !p_is(TK_IDENT) {
        p_error_cur("missing package name");
        return null;
    }
    @StmtNode s = p_new_stmt(PACKAGE);
    s.var_name = span_text(p_cur.start, p_cur.stop);
    s.var_line = p_cur.line;
    s.var_col = p_cur.col;
    s.line = pline;
    s.col = pcol;
    p_adv();
    if !p_is(TK_LBRACE) {
        p_error_cur("missing '{' after package name");
        return null;
    }
    p_adv();
    str saved_pkg = p_cur_package;
    p_cur_package = s.var_name;
    while !p_is(TK_EOF) && !p_is(TK_RBRACE) {
        @StmtNode st = parse_stmt();
        if st == null {
            continue;
        }
        s.true_body = p_chain_stmt(s.true_body, st);
    }
    p_cur_package = saved_pkg;
    if !p_is(TK_RBRACE) {
        p_error_cur("missing '}' at the end of the package");
        return s;
    }
    p_adv();
    return s;
}

!!! `use name;` imports every member of the package, `use name::member;` a single
!!! one. Both make the members usable from this file.
@StmtNode p_use {
    int uline = p_cur.line;
    int ucol = p_cur.col;
    p_adv();
    @StmtNode s = p_new_stmt(USE);
    s.line = uline;
    s.col = ucol;
    if !p_is(TK_IDENT) {
        p_error_cur("missing package name");
        return null;
    }
    s.var_name = span_text(p_cur.start, p_cur.stop);
    s.var_line = p_cur.line;
    s.var_col = p_cur.col;
    p_adv();
    if p_is(TK_SCOPE) {
        p_adv();
        if !p_is(TK_IDENT) {
            p_error_cur("missing object name after '::'");
            return null;
        }
        !!! A single member is imported: its name travels in struct_type, which is
        !!! the field the toolchain parser writes it to.
        s.struct_type = span_text(p_cur.start, p_cur.stop);
        s.member_line = p_cur.line;
        s.member_col = p_cur.col;
        p_adv();
    }
    if !p_is(TK_SEMI) {
        p_error_cur("missing ';' after use");
        return s;
    }
    p_adv();
    return s;
}
