#once
!~
 ~  bootstrap/backend/parser_call.b: the call statements.
 ~
 ~  and backend/parser_bcall: `CALL` with
 ~  its arguments (a nested call among them is kept aside, which is how the backend
 ~  hoists a struct-returning call out of an argument list), `BCALL` for a builtin,
 ~  and the four statements that go with them - DREF, ICALL, RELEASE and BSPREAD.
 ~!

#head "parser"

void cp_parse_call {
    @CmpStmt s = cs_new(CALL);
    s.line = cp_cur.line;
    s.col = cp_cur.col;
    cp_advance();
    if cp_cur.tk != CT_IDENT {
        cp_error("expected function name");
        end;
    }
    s.call_name = cp_cur.text;
    cp_advance();
    while cp_cur.tk != CT_EOF {
        if cp_cur.tk == CT_IDENT && cp_is_stmt_keyword(cp_cur.text) {
            skip;
        }
        if cp_cur.tk == CT_RPAREN {
            skip;
        }
        !!! Literal keywords are not variable names: `CALL printf "%p", null` has to
        !!! reach cp_parse_expr, which turns null / true / false into literals. The
        !!! identifier branch below would build a VAR_REF and the name would then be
        !!! reported as undeclared.
        if cp_is("null") || cp_is("true") || cp_is("false") {
            s.args = ce_add(s.args, cp_parse_expr());
            if cp_has_error() {
                end;
            }
            if cp_cur.tk == CT_COMMA {
                cp_advance();
            } else {
                skip;
            }
            continue;
        }
        if cp_cur.tk == CT_IDENT {
            str name = cp_cur.text;
            if cp_is_cast(name) {
                int cline = cp_cur.line;
                int ccol = cp_cur.col;
                cp_advance();
                @CmpExpr inner = cp_parse_expr();
                if cp_has_error() {
                    end;
                }
                @CmpExpr n = ce_new(CAST);
                n.line = cline;
                n.col = ccol;
                n.left = inner;
                n.op = name;
                if pe_eq(name, "_toStr") {
                    n.result_type = STR;
                } else if pe_eq(name, "_toInt") {
                    n.result_type = INT;
                } else if pe_eq(name, "_toLong") {
                    n.result_type = LONG;
                } else if pe_eq(name, "_toFloat") {
                    n.result_type = FLOAT;
                } else if pe_eq(name, "_toBool") {
                    n.result_type = BOOL;
                } else if pe_eq(name, "_toChar") {
                    n.result_type = CHAR;
                }
                s.args = ce_add(s.args, n);
                if cp_cur.tk == CT_COMMA {
                    cp_advance();
                }
                continue;
            }
            cp_advance();
            if cp_cur.tk == CT_LBRACE {
                cp_advance();
                @CmpExpr idx = cp_parse_expr();
                if idx == null {
                    end;
                }
                if cp_cur.tk != CT_RBRACE {
                    cp_error("expected '}'");
                    end;
                }
                cp_advance();
                @CmpExpr arr = ce_new(ARRAY_ACCESS);
                arr.line = cp_cur.line;
                arr.col = cp_cur.col;
                arr.var_name = name;
                arr.left = idx;
                s.args = ce_add(s.args, arr);
                if cp_cur.tk == CT_COMMA {
                    cp_advance();
                }
                continue;
            }
            bool next_is_expr = cp_cur.tk == CT_INTEGER || cp_cur.tk == CT_FLOAT ||
                                cp_cur.tk == CT_STRING || cp_cur.tk == CT_IDENT ||
                                cp_cur.tk == CT_LPAREN || cp_cur.tk == CT_LBRACE;
            bool next_is_kw = cp_cur.tk == CT_IDENT && cp_is_stmt_keyword(cp_cur.text);
            if cp_is_stmt_keyword(name) || !next_is_expr || next_is_kw {
                @CmpExpr e = ce_new(VAR_REF);
                e.line = cp_cur.line;
                e.col = cp_cur.col;
                e.var_name = name;
                s.args = ce_add(s.args, e);
                if cp_cur.tk == CT_COMMA {
                    cp_advance();
                }
                continue;
            }
            !!! A nested call: `CALL f CALL g x, y, z`. Its arguments are kept
            !!! aside so the code generator can call `g` first and hand the result
            !!! on.
            s.nested_call = name;
            s.nested_args = ce_add(s.nested_args, cp_parse_expr());
            if cp_has_error() {
                end;
            }
            while cp_cur.tk == CT_COMMA {
                cp_advance();
                s.nested_args = ce_add(s.nested_args, cp_parse_expr());
                if cp_has_error() {
                    end;
                }
            }
            if cp_cur.tk == CT_COMMA {
                cp_advance();
            }
            skip;
        }
        if cp_cur.tk == CT_OPERATOR && pe_eq(cp_cur.text, "@") {
            int cline = cp_cur.line;
            int ccol = cp_cur.col;
            cp_advance();
            if cp_cur.tk != CT_IDENT {
                cp_error("expected type after @");
                end;
            }
            str type_name = cp_cur.text;
            if !pe_eq(type_name, "void") && !pe_eq(type_name, "int") &&
               !pe_eq(type_name, "float") && !pe_eq(type_name, "char") &&
               !pe_eq(type_name, "str") && !pe_eq(type_name, "bool") {
                cp_error("expected type after @");
                end;
            }
            cp_advance();
            @CmpExpr inner = cp_parse_expr();
            if cp_has_error() {
                end;
            }
            @CmpExpr n = ce_new(CAST);
            n.line = cline;
            n.col = ccol;
            n.left = inner;
            n.op = "@" + type_name;
            if pe_eq(type_name, "void") {
                n.result_type = AT_VOID;
            } else if pe_eq(type_name, "int") {
                n.result_type = AT_INT;
            } else if pe_eq(type_name, "float") {
                n.result_type = AT_FLOAT;
            } else if pe_eq(type_name, "char") {
                n.result_type = AT_CHAR;
            } else if pe_eq(type_name, "str") {
                n.result_type = AT_STR;
            } else if pe_eq(type_name, "bool") {
                n.result_type = AT_BOOL;
            }
            s.args = ce_add(s.args, n);
            if cp_cur.tk == CT_COMMA {
                cp_advance();
            }
            continue;
        }
        s.args = ce_add(s.args, cp_parse_expr());
        if cp_has_error() {
            end;
        }
        if cp_cur.tk == CT_COMMA {
            cp_advance();
        } else {
            skip;
        }
    }
    cp_stmts = cs_add(cp_stmts, s);
}

void cp_parse_bcall {
    @CmpStmt s = cs_new(CALL);
    s.line = cp_cur.line;
    s.col = cp_cur.col;
    cp_advance();
    if cp_cur.tk != CT_STRING {
        cp_error("expected quoted builtin name");
        end;
    }
    s.call_name = cp_cur.text;
    cp_advance();
    while cp_cur.tk != CT_EOF {
        if cp_cur.tk == CT_IDENT && cp_is_stmt_keyword(cp_cur.text) {
            skip;
        }
        if cp_cur.tk == CT_RPAREN {
            skip;
        }
        s.args = ce_add(s.args, cp_parse_expr());
        if cp_has_error() {
            end;
        }
        if cp_cur.tk == CT_COMMA {
            cp_advance();
        }
    }
    cp_stmts = cs_add(cp_stmts, s);
}

void cp_parse_dref {
    @CmpStmt s = cs_new(DREF);
    s.line = cp_cur.line;
    s.col = cp_cur.col;
    cp_advance();
    if cp_cur.tk != CT_IDENT {
        cp_error("expected variable name after DREF");
        end;
    }
    s.var_name = cp_cur.text;
    cp_advance();
    if cp_cur.tk != CT_COMMA {
        cp_error("expected ','");
        end;
    }
    cp_advance();
    s.init_expr = cp_parse_expr();
    if cp_has_error() {
        end;
    }
    cp_stmts = cs_add(cp_stmts, s);
}

void cp_parse_icall {
    @CmpStmt s = cs_new(ICALL_STMT);
    s.line = cp_cur.line;
    s.col = cp_cur.col;
    cp_advance();
    s.init_expr = cp_parse_expr();
    if cp_has_error() {
        end;
    }
    while cp_cur.tk == CT_COMMA {
        cp_advance();
        s.args = ce_add(s.args, cp_parse_expr());
    }
    cp_stmts = cs_add(cp_stmts, s);
}

void cp_parse_release {
    @CmpStmt s = cs_new(RELEASE);
    s.line = cp_cur.line;
    s.col = cp_cur.col;
    cp_advance();
    if cp_cur.tk != CT_IDENT {
        cp_error("expected variable name after RELEASE");
        end;
    }
    s.var_name = cp_cur.text;
    cp_advance();
    cp_stmts = cs_add(cp_stmts, s);
}

void cp_parse_bspread {
    @CmpStmt s = cs_new(BSPREAD);
    s.line = cp_cur.line;
    s.col = cp_cur.col;
    cp_advance();
    if cp_cur.tk != CT_STRING {
        cp_error("expected quoted builtin name after BSPREAD");
        end;
    }
    s.call_name = cp_cur.text;
    cp_advance();
    s.init_expr = cp_parse_expr();
    if cp_has_error() {
        end;
    }
    if cp_cur.tk == CT_COMMA {
        cp_advance();
        if cp_cur.tk == CT_INTEGER {
            s.spread_tag = pe_atoi(cp_cur.text);
            cp_advance();
        }
    }
    cp_stmts = cs_add(cp_stmts, s);
}
