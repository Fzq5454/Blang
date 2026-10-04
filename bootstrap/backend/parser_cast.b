#once
!~
 ~  bootstrap/backend/parser_cast.b: the CAST and EXIT statements.
 ~
 ~  `CAST <target>, <value>` writes a value
 ~  into a variable, a field or a block element, and `EXIT <code>` leaves the
 ~  program. A field target is written in parentheses (`CAST (FLD o 4 INT), 1`),
 ~  which is how the two shapes are told apart.
 ~!

#head "parser"

void cp_parse_cast {
    @CmpStmt s = cs_new(CAST_STMT);
    s.line = cp_cur.line;
    s.col = cp_cur.col;
    cp_advance();
    if cp_cur.tk == CT_LPAREN {
        s.field_target = cp_parse_expr();
        if s.field_target == null {
            end;
        }
        if cp_cur.tk == CT_COMMA {
            cp_advance();
            s.init_expr = cp_parse_expr();
        }
        cp_stmts = cs_add(cp_stmts, s);
        end;
    }
    if cp_cur.tk != CT_IDENT {
        cp_error("expected variable name");
        end;
    }
    s.var_name = cp_cur.text;
    cp_advance();
    if cp_cur.tk == CT_LBRACE {
        s.is_array = true;
        cp_advance();
        s.init_expr = cp_parse_expr();
        if cp_cur.tk != CT_RBRACE {
            cp_error("expected '}'");
            end;
        }
        cp_advance();
        if cp_cur.tk == CT_COMMA {
            cp_advance();
            s.array_init = ce_add(s.array_init, cp_parse_expr());
        }
    } else if cp_cur.tk == CT_COMMA {
        cp_advance();
        if cp_cur.tk == CT_LBRACE {
            s.is_array = true;
            cp_advance();
            while cp_cur.tk != CT_RBRACE && cp_cur.tk != CT_EOF {
                s.array_init = ce_add(s.array_init, cp_parse_expr());
                if cp_cur.tk == CT_COMMA {
                    cp_advance();
                }
            }
            if cp_cur.tk != CT_RBRACE {
                cp_error("expected '}'");
                end;
            }
            cp_advance();
        } else {
            s.init_expr = cp_parse_expr();
        }
    }
    cp_stmts = cs_add(cp_stmts, s);
}

void cp_parse_exit {
    @CmpStmt s = cs_new(EXIT);
    s.line = cp_cur.line;
    s.col = cp_cur.col;
    cp_advance();
    s.exit_expr = cp_parse_expr();
    if cp_has_error() {
        end;
    }
    cp_stmts = cs_add(cp_stmts, s);
}
