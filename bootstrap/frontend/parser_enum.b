#once
!~
 ~  bootstrap/frontend/parser_enum.b: the frontend/parser_enum.
 ~
 ~  `kind Name { A, B = 3, WARNING, ... }`: an enumerator is a named integer
 ~  constant. The names of the enum types and the values of the members are what the
 ~  rest of the front end asks for - a dimension written as a name (`int a[N]`) is
 ~  folded with the value, and a type spelled `Encoding` is the name of an enum and
 ~  not of a struct.
 ~
 ~  The values themselves are the table parser.b keeps (`enum_values` in the toolchain
 ~  parser), with the names of the enum types beside them.
 ~!

#head "parser"

@StmtNode p_enum {
    @StmtNode s = p_new_stmt(ENUM);
    p_adv();
    if !p_is(TK_IDENT) {
        p_error_cur("missing enum name");
        return s;
    }
    s.var_name = span_text(p_cur.start, p_cur.stop);
    s.var_line = p_cur.line;
    s.var_col = p_cur.col;
    !!! The name is a type from here on, so a parameter or a field written with it
    !!! is read as a builtin and not looked up as a struct.
    p_remember_enum(s.var_name);
    p_adv();
    if !p_is(TK_LBRACE) {
        p_error_cur("missing '{'");
        return s;
    }
    p_adv();

    longlong next_val = 0;
    while !p_is(TK_RBRACE) && !p_is(TK_EOF) {
        if !p_is(TK_IDENT) {
            p_error_cur("missing enum member name");
            p_adv();
            continue;
        }
        str member = span_text(p_cur.start, p_cur.stop);
        p_adv();
        !!! `= value` sets the value of this member; the ones after it count on from
        !!! there.
        if p_is(TK_ASSIGN) {
            p_adv();
            if p_is(TK_MINUS) {
                p_adv();
                if !p_is(TK_INTEGER) {
                    p_error_cur("missing integer value after '-'");
                    continue;
                }
                next_val = 0 - p_cur.value;
                p_adv();
            } else if p_is(TK_INTEGER) {
                next_val = p_cur.value;
                p_adv();
            } else {
                p_error_cur("missing integer value after '='");
                continue;
            }
        }
        !!! A member written twice keeps its first value unless the second one
        !!! disagrees, which is the toolchain rule.
        longlong old = p_enum_value(member);
        if p_enum_found && old != next_val {
            p_error_at(p_cur.line, p_cur.col, p_text_len(member),
                       "enum member '" + member + "' redefined with different value");
        } else {
            p_enum_set(member, next_val);
        }
        !!! The members travel in the node in the order they were written: the name
        !!! in the parameter list of the statement, the value behind it.
        s.fparams = p_chain_str(s.fparams, p_new_name(member, p_cur.line, p_cur.col));
        s.fparam_types = p_chain_type(s.fparam_types, p_new_type(INT));
        next_val = next_val + 1;
        if p_is(TK_COMMA) {
            p_adv();
        }
    }
    if !p_is(TK_RBRACE) {
        p_error_cur("missing '}'");
        return s;
    }
    p_adv();
    if p_is(TK_SEMI) {
        p_adv();
    }
    return s;
}
