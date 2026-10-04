#once
!~
 ~  bootstrap/frontend/parser_declare.b: the frontend/parser_declare.
 ~
 ~  A variable declaration, with the array dimensions and the initializer that can
 ~  follow it. A dimension written as a name is folded here when the name is a
 ~  constant the file already declared (`const int N = 65536;`) or an enumerator,
 ~  because that value is what sizes the array.
 ~!

#head "parser"

@StmtNode p_declare {
    @StmtNode s = p_new_stmt(DECLARE);

    !!! Not a type at all: one error, and no statement. Building one anyway would
    !!! have every later pass see a declaration with no type and no name and report
    !!! a second diagnostic of its own.
    if !p_is_type() {
        p_error_cur("missing type");
        return null;
    }

    int save_type_col = p_cur.col;
    VarType vt = p_type();
    s.ptr_depth = p_last_ptr_depth;
    s.decl_is_ref = p_last_is_ref;
    s.decl_is_const = p_last_is_const;
    s.decl_is_static = p_last_is_static;
    !!! `utype` says the value is unsigned, and only a fixed-width integer can be
    !!! read as one: the width is what the unsigned reading is about.
    if p_last_is_unsigned {
        if !p_unsigned_ok(vt) {
            p_error_at(s.line, save_type_col, 5,
                       "utype is only for 'int', 'longlong' or 'char'");
        } else {
            s.decl_is_unsigned = true;
        }
    }
    if p_last_struct != "" {
        !!! A struct: `@T p` holds the address of a T, so its declared type is the
        !!! address type and it can be passed to a `@T` parameter or a `ref T`
        !!! binding. Without the pointer it is the object itself.
        s.struct_type = p_last_struct;
        if s.ptr_depth > 0 {
            s.decl_type = AT_INT;
        } else {
            s.decl_type = INT;
        }
        s.type_len = p_text_len(s.struct_type);
    } else if vt == INT || vt == LONG || vt == STR || vt == FLOAT || vt == BOOL || vt == CHAR {
        s.decl_type = vt;
        s.type_len = p_prev.stop - p_prev.start;
    } else if vt == VOID {
        p_error_cur("'void' is not valid for variable declaration");
        return s;
    } else {
        s.decl_type = vt;
        s.type_len = p_prev.stop - p_prev.start;
        !!! `@int` / `@float` / `@char` / `@str` / `@void` / `@bool` are `@` and the
        !!! type name, and parse_type read the two as one type: the token before
        !!! carries the name alone, so the span of the declaration's type is the
        !!! length of that name plus the `@` and what parse_type wrote between them.
        if vt == AT_INT || vt == AT_FLOAT || vt == AT_CHAR ||
           vt == AT_STR || vt == AT_VOID || vt == AT_BOOL {
            s.type_len = 2 + (p_prev.stop - p_prev.start);
        }
    }
    s.type_col = save_type_col;

    if !p_is(TK_IDENT) {
        !!! The name is missing: report it and drop the statement, so no pass sees an
        !!! anonymous declaration at line 0.
        p_error_cur("missing variable name");
        return null;
    }
    s.var_name = span_text(p_cur.start, p_cur.stop);
    s.var_line = p_cur.line;
    s.var_col = p_cur.col;
    p_adv();

    !!! `int name[3][3]` and `int name[]`: the dimensions, in the order they were
    !!! written. the toolchain keeps them in three parallel vectors; a chain of the
    !!! folded values is what the backend needs to size the block.
    while p_is(TK_LBRACKET) {
        s.is_array = true;
        p_adv();
        if !p_is(TK_RBRACKET) {
            @ExprNode dim = parse_expr(0);
            bool known = false;
            longlong dim_value = 0;
            if dim != null && dim.nk == LIT_INT {
                dim_value = dim.int_val;
                known = true;
            } else if dim != null && dim.nk == VAR_REF {
                int ci = 0;
                bool found = false;
                !!! A name of a `const` is looked up here for the dimension of every
                !!! declaration, and the table grows with the program: comparing the
                !!! hash each name carries first rejects an entry it cannot be in with
                !!! one integer compare instead of a text compare.
                int ch = rgx_lk_hash(dim.var_name);
                while ci < p_const_names.len {
                    if p_const_names_h.get(ci) == ch &&
                       p_text_eq(p_const_names.get(ci), dim.var_name) {
                        dim_value = p_const_values.get(ci);
                        found = true;
                        skip;
                    }
                    ci = ci + 1;
                }
                if found {
                    known = true;
                } else {
                    longlong ev = p_enum_value(dim.var_name);
                    if p_enum_found {
                        dim_value = ev;
                        known = true;
                    }
                }
            }
            !!! A dimension that only reached the expression left the list empty, the
            !!! array was allocated with zero elements and every element stored into it
            !!! was written past the end: the value is what matters here.
            if known {
                s.array_dims = p_chain_int(s.array_dims, p_new_int((int)dim_value));
            } else {
                s.array_len_expr = dim;
            }
            if dim == null {
                s.array_dims = p_chain_int(s.array_dims, p_new_int(0));
            }
        } else {
            !!! `int name[]`: the length is whatever the initializer holds.
            s.array_dims = p_chain_int(s.array_dims, p_new_int(0));
        }
        if !p_is(TK_RBRACKET) {
            p_error_cur("missing ']'");
            return s;
        }
        p_adv();
    }

    if p_is(TK_ASSIGN) {
        p_adv();
        if s.struct_type != "" && s.is_array && p_is(TK_LBRACE) {
            p_array_init(s);
        } else if s.struct_type != "" && p_is(TK_LBRACE) {
            p_array_init(s);
        } else if s.is_array && p_is(TK_LBRACE) {
            p_array_init(s);
        } else {
            s.expr = parse_expr(0);
            !!! A struct constructor call, `Person("name", 18)`: its arguments are
            !!! the field values, so they are kept as the initializer.
            if s.struct_type != "" && s.expr != null && s.expr.nk == FUNC_CALL &&
               p_text_eq(s.expr.var_name, s.struct_type) {
                !!! The call's argument chain is the field values, and the toolchain copies
                !!! the pointers of that chain into `array_init`, so this implementation shares
                !!! the chain. Appending the arguments one by one relinked a node that
                !!! was already linked to the next one: the second argument of
                !!! `Point(1, 2)` was made to point at itself, and the walk below -
                !!! and every later walk of the initializer - never ended.
                s.array_init = s.expr.args;
            }
        }
    }
    !!! A `const` whose value is a literal is remembered by name: an array dimension
    !!! written as that name is folded with it.
    if s.decl_is_const && !s.is_array && s.expr != null && s.expr.nk == LIT_INT {
        p_const_names.add(s.var_name);
        p_const_names_h.add(rgx_lk_hash(s.var_name));
        p_const_values.add(s.expr.int_val);
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

!!! An initializer: `{ a, b, c }`, and `{{1,2},{3,4}}` which is flattened into the
!!! same list (the nested braces are the grouping of a two-dimensional array).
void p_array_init -> @StmtNode s {
    if !p_is(TK_LBRACE) {
        end;
    }
    p_adv();
    while !p_is(TK_EOF) && !p_is(TK_RBRACE) {
        if p_is(TK_LBRACE) {
            p_array_init(s);
        } else {
            @ExprNode e = parse_expr(0);
            if e == null {
                p_adv();
                skip;
            }
            s.array_init = p_chain_expr(s.array_init, e);
        }
        if p_is(TK_COMMA) {
            p_adv();
        }
    }
    if !p_is(TK_RBRACE) {
        p_error_cur("missing '}'");
        end;
    }
    p_adv();
}
