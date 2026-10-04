#once
!~
 ~  bootstrap/backend/parser_declared.b: the DECLARED and STRUCT statements.
 ~
 ~  It is the backend/parser_declared and backend/parser_struct: a
 ~  variable declaration with its dimensions and its initializer, and the layout of
 ~  a struct the .r file writes out (`STRUCT <name> SIZE <n> ( ... )`), which is the
 ~  table the code generator reads its field offsets from.
 ~!

#head "parser"
#head "parser_type"

!!! The struct layouts the file declared, in the order they were read.
@CmpStructType cp_struct_types;

@CmpStructType cp_find_struct -> str name {
    @CmpStructType st = cp_struct_types;
    while st != null {
        if pe_eq(st.name, name) {
            return st;
        }
        st = st.next;
    }
    return null;
}

void cp_parse_declared {
    @CmpStmt s = cs_new(DECLARED);
    s.line = cp_cur.line;
    s.col = cp_cur.col;
    cp_advance();
    if cp_is("STRUCT") {
        cp_advance();
        if cp_cur.tk != CT_IDENT {
            cp_error("expected struct type name");
            end;
        }
        s.struct_type = cp_cur.text;
        cp_advance();
    } else {
        if !cp_parse_r_type() {
            cp_error("expected type, got '" + cp_cur.text + "'");
            end;
        }
        s.decl_type = cp_rtype_type;
        s.ptr_depth = cp_rtype_depth;
        cp_advance();
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
        if cp_cur.tk != CT_RBRACE {
            @CmpExpr dim0 = cp_parse_expr();
            if dim0 != null && dim0.nk == LIT_INT {
                s.array_dims = cn_int(s.array_dims, dim0.int_val);
            } else if dim0 != null {
                !!! The length only exists at run time (`int b[n]`): the declaration
                !!! keeps the expression and sizes the block with it. Dropping it
                !!! here left the block claiming no elements at all, so the array was
                !!! allocated empty and the first `b[i]` was already out of range.
                s.array_len_expr = dim0;
            }
            while cp_cur.tk == CT_COMMA {
                cp_advance();
                @CmpExpr d = cp_parse_expr();
                if d != null && d.nk == LIT_INT {
                    s.array_dims = cn_int(s.array_dims, d.int_val);
                } else {
                    s.array_dims = cn_int(s.array_dims, 1);
                }
            }
            if s.array_dims == null && s.array_len_expr == null {
                s.array_dims = cn_int(s.array_dims, 0);
            }
        }
        if cp_cur.tk != CT_RBRACE {
            cp_error("expected '}'");
            end;
        }
        cp_advance();
    }
    if cp_cur.tk == CT_COMMA {
        cp_advance();
        if (s.is_array || !pe_eq(s.struct_type, "")) && cp_cur.tk == CT_LBRACE {
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

void cp_parse_struct_decl {
    cp_advance();
    if cp_cur.tk != CT_IDENT {
        cp_error("expected struct name");
        end;
    }
    str name = cp_cur.text;
    cp_advance();
    cp_expect("SIZE");
    if cp_cur.tk != CT_INTEGER {
        cp_error("expected total size");
        end;
    }
    CmpStructType proto;
    @CmpStructType st;
    cg_balloc(@st, size proto);
    st.name = name;
    st.total_size = pe_atoi(cp_cur.text);
    st.fields = null;
    st.next = null;
    cp_advance();
    if cp_cur.tk != CT_LPAREN {
        cp_error("expected '('");
        end;
    }
    cp_advance();
    while cp_cur.tk != CT_RPAREN && cp_cur.tk != CT_EOF {
        if cp_cur.tk != CT_IDENT {
            cp_error("expected field name");
            end;
        }
        cp_advance();
        if cp_cur.tk != CT_INTEGER {
            cp_error("expected field offset");
            end;
        }
        int off = pe_atoi(cp_cur.text);
        cp_advance();
        if !cp_parse_r_type() {
            cp_error("expected field type");
            end;
        }
        VarType ft = cp_rtype_type;
        cp_advance();
        if cp_cur.tk != CT_INTEGER {
            cp_error("expected field size");
            end;
        }
        st.fields = cf_add(st.fields, cf_new(ft, off, pe_atoi(cp_cur.text)));
        cp_advance();
        if cp_cur.tk == CT_COMMA {
            cp_advance();
            continue;
        }
        skip;
    }
    if cp_cur.tk != CT_RPAREN {
        cp_error("expected ')'");
        end;
    }
    cp_advance();
    if cp_struct_types == null {
        cp_struct_types = st;
    } else {
        @CmpStructType t = cp_struct_types;
        while t.next != null {
            t = t.next;
        }
        t.next = st;
    }
}
