#once
!~
 ~  bootstrap/backend/parser_func.b: the FUNC and RET statements, and TRY/RAISE.
 ~
 ~  and backend/parser_try. `FUNC <name>
 ~  <rettype> ( <params> ) THEN ( <body> )` is the whole function shape of the .r
 ~  text: the return type is written before the parameter list and a struct return
 ~  is spelled `STRUCT <name>`. A parameter list carries `STRUCTPTR <name>` for a
 ~  `@T` parameter and `STRUCT <name>` for a struct passed by value.
 ~!

#head "parser"

void cp_parse_func {
    @CmpStmt s = cs_new(FUNC_STMT);
    s.line = cp_cur.line;
    s.col = cp_cur.col;
    cp_advance();
    if cp_cur.tk != CT_IDENT {
        cp_error("expected function name");
        end;
    }
    s.var_name = cp_cur.text;
    cp_advance();
    if cp_cur.tk == CT_IDENT {
        bool is_ret_type = false;
        if cp_is("STRUCT") {
            cp_advance();
            if cp_cur.tk != CT_IDENT {
                cp_error("expected struct name after STRUCT");
                end;
            }
            s.ret_struct = cp_cur.text;
            s.func_ret_type = AT_INT;
            is_ret_type = true;
        } else if cp_is("INT") {
            s.func_ret_type = INT;
            is_ret_type = true;
        } else if cp_is("LONG") {
            s.func_ret_type = LONG;
            is_ret_type = true;
        } else if cp_is("STR") {
            s.func_ret_type = STR;
            is_ret_type = true;
        } else if cp_is("FLOAT") {
            s.func_ret_type = FLOAT;
            is_ret_type = true;
        } else if cp_is("BOOL") {
            s.func_ret_type = BOOL;
            is_ret_type = true;
        } else if cp_is("CHAR") {
            s.func_ret_type = CHAR;
            is_ret_type = true;
        } else if cp_is("VOID") {
            s.func_ret_type = VOID;
            is_ret_type = true;
        } else if cp_is("AT_INT") {
            s.func_ret_type = AT_INT;
            is_ret_type = true;
        } else if cp_is("AT_FLOAT") {
            s.func_ret_type = AT_FLOAT;
            is_ret_type = true;
        } else if cp_is("AT_CHAR") {
            s.func_ret_type = AT_CHAR;
            is_ret_type = true;
        } else if cp_is("AT_STR") {
            s.func_ret_type = AT_STR;
            is_ret_type = true;
        } else if cp_is("AT_VOID") {
            s.func_ret_type = AT_VOID;
            is_ret_type = true;
        } else if cp_is("AT_BOOL") {
            s.func_ret_type = AT_BOOL;
            is_ret_type = true;
        } else if cp_is("AT_LONG") {
            s.func_ret_type = AT_LONG;
            is_ret_type = true;
        } else if cp_is("FUNC") {
            s.func_ret_type = FUNC;
            is_ret_type = true;
        } else if cp_is("AT_FUNC") {
            s.func_ret_type = AT_FUNC;
            is_ret_type = true;
        }
        if is_ret_type {
            cp_advance();
        }
    }
    if cp_cur.tk != CT_LPAREN {
        cp_error("expected '(' after function name");
        end;
    }
    cp_advance();
    while cp_cur.tk != CT_RPAREN && cp_cur.tk != CT_EOF {
        VarType pt = INT;
        str pstruct = "";
        bool pptr = false;
        if cp_is("STRUCTPTR") {
            cp_advance();
            if cp_cur.tk != CT_IDENT {
                cp_error("expected struct name after STRUCTPTR");
                end;
            }
            pstruct = cp_cur.text;
            pt = AT_INT;
            pptr = true;
        } else if cp_is("STRUCT") {
            cp_advance();
            if cp_cur.tk != CT_IDENT {
                cp_error("expected struct name after STRUCT");
                end;
            }
            pstruct = cp_cur.text;
            pt = AT_INT;
        } else if cp_is("INT") {
            pt = INT;
        } else if cp_is("LONG") {
            pt = LONG;
        } else if cp_is("STR") {
            pt = STR;
        } else if cp_is("FLOAT") {
            pt = FLOAT;
        } else if cp_is("BOOL") {
            pt = BOOL;
        } else if cp_is("CHAR") {
            pt = CHAR;
        } else if cp_is("AT_INT") {
            pt = AT_INT;
        } else if cp_is("AT_FLOAT") {
            pt = AT_FLOAT;
        } else if cp_is("AT_CHAR") {
            pt = AT_CHAR;
        } else if cp_is("AT_STR") {
            pt = AT_STR;
        } else if cp_is("AT_VOID") {
            pt = AT_VOID;
        } else if cp_is("AT_BOOL") {
            pt = AT_BOOL;
        } else if cp_is("AT_LONG") {
            pt = AT_LONG;
        } else if cp_is("FUNC") {
            pt = FUNC;
        } else if cp_is("AT_FUNC") {
            pt = AT_FUNC;
        } else if cp_is("ANY") {
            pt = ANY;
        } else {
            cp_error("expected type for parameter, got '" + cp_cur.text + "'");
            end;
        }
        cp_advance();
        if cp_cur.tk != CT_IDENT {
            cp_error("expected parameter name");
            end;
        }
        s.fparam_types = cn_type(s.fparam_types, pt);
        s.fparam_struct = cn_str(s.fparam_struct, pstruct);
        s.fparam_struct_ptr = cn_bool(s.fparam_struct_ptr, pptr);
        s.fparams = cn_str(s.fparams, cp_cur.text);
        cp_advance();
        bool is_arr = false;
        if cp_cur.tk == CT_LBRACE {
            @CmpToken nx = tk_peek();
            if nx.tk == CT_RBRACE {
                is_arr = true;
                cp_advance();
                cp_advance();
            }
        }
        s.fparam_is_array = cn_bool(s.fparam_is_array, is_arr);
        if cp_cur.tk == CT_ELLIPSIS {
            s.variadic = true;
            cp_advance();
        }
        if cp_cur.tk == CT_COMMA {
            cp_advance();
        }
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
    s.true_body = cp_block();
    cp_stmts = cs_add(cp_stmts, s);
}

void cp_parse_ret {
    @CmpStmt s = cs_new(RET);
    s.line = cp_cur.line;
    s.col = cp_cur.col;
    cp_advance();
    s.init_expr = cp_parse_expr();
    if cp_has_error() {
        end;
    }
    cp_stmts = cs_add(cp_stmts, s);
}

void cp_parse_raise {
    @CmpStmt s = cs_new(RAISE);
    s.line = cp_cur.line;
    s.col = cp_cur.col;
    cp_advance();
    s.init_expr = cp_parse_expr();
    if cp_has_error() {
        end;
    }
    cp_stmts = cs_add(cp_stmts, s);
}

void cp_parse_try {
    @CmpStmt s = cs_new(TRY_CATCH);
    s.line = cp_cur.line;
    s.col = cp_cur.col;
    cp_advance();
    s.true_body = cp_block();
    if cp_has_error() {
        end;
    }
    if !cp_is("CATCH") {
        cp_error("expected CATCH after TRY block, got '" + cp_cur.text + "'");
        end;
    }
    cp_advance();
    !!! The code is optional: `CATCH name ( ... )` hands it to the handler,
    !!! `CATCH ( ... )` runs the handler without it.
    if cp_cur.tk == CT_IDENT {
        s.var_name = cp_cur.text;
        cp_advance();
    }
    s.false_body = cp_block();
    if cp_has_error() {
        end;
    }
    cp_stmts = cs_add(cp_stmts, s);
}
