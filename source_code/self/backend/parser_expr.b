#once
!~
 ~  bootstrap/backend/parser_expr.b: the .r expression parser.
 ~
 ~  It is the backend/parser_expr. The .r language writes every
 ~  expression in prefix form: `(a, b, +)` is a sum, `(FLDP p 4 INT)` is a field of
 ~  the struct a pointer names, and a bare name is a variable. The shapes that start
 ~  with an identifier (`CALL_EXPR`, `FLDP`, `CLOSURE`, ...) are recognised by the
 ~  name the parenthesised form begins with, which is why the reader starts the same
 ~  way it reads a variable and then looks at what it read.
 ~!

#head "parser"
#head "parser_type"

!!! A ternary's result type is the widest of its two arms, and a binary operation
!!! takes the wider of its operands: float beats str beats longlong beats int.
VarType cp_widen -> VarType a, VarType b {
    if a == FLOAT || b == FLOAT {
        return FLOAT;
    }
    if a == STR || b == STR {
        return STR;
    }
    if a == LONG || b == LONG {
        return LONG;
    }
    return INT;
}

@CmpExpr cp_parse_expr {
    if cp_cur.tk == CT_OPERATOR && pe_eq(cp_cur.text, "?") {
        @CmpExpr n = ce_new(VAR_REF);
        n.line = cp_cur.line;
        n.col = cp_cur.col;
        n.result_type = INT;
        n.var_name = "?";
        cp_advance();
        return n;
    }
    if cp_cur.tk == CT_INTEGER {
        @CmpExpr n = ce_new(LIT_INT);
        n.line = cp_cur.line;
        n.col = cp_cur.col;
        n.result_type = INT;
        n.int_val = pe_atoll(cp_cur.text);
        cp_advance();
        return n;
    }
    if cp_cur.tk == CT_FLOAT {
        @CmpExpr n = ce_new(LIT_FLOAT);
        n.line = cp_cur.line;
        n.col = cp_cur.col;
        n.result_type = FLOAT;
        n.float_val = pe_atof(cp_cur.text);
        cp_advance();
        return n;
    }
    if cp_cur.tk == CT_STRING {
        @CmpExpr n = ce_new(LIT_STR);
        n.line = cp_cur.line;
        n.col = cp_cur.col;
        n.result_type = STR;
        n.str_val = cp_cur.text;
        cp_advance();
        return n;
    }
    if cp_cur.tk == CT_CHAR {
        @CmpExpr n = ce_new(LIT_CHAR);
        n.line = cp_cur.line;
        n.col = cp_cur.col;
        n.result_type = CHAR;
        n.char_val = pe_atoi(cp_cur.text);
        cp_advance();
        return n;
    }
    if cp_is("true") || cp_is("false") {
        @CmpExpr n = ce_new(LIT_BOOL);
        n.line = cp_cur.line;
        n.col = cp_cur.col;
        n.result_type = BOOL;
        n.bool_val = cp_is("true");
        n.int_val = 0;
        if n.bool_val {
            n.int_val = 1;
        }
        cp_advance();
        return n;
    }
    if cp_is("null") {
        @CmpExpr n = ce_new(LIT_NULL);
        n.line = cp_cur.line;
        n.col = cp_cur.col;
        n.result_type = AT_VOID;
        cp_advance();
        return n;
    }
    !!! `_toStr x` and the other conversion prefixes: a cast written without the
    !!! parentheses the operator form uses.
    if cp_cur.tk == CT_IDENT &&
       (pe_eq(cp_cur.text, "_toStr") || pe_eq(cp_cur.text, "_toInt") ||
        pe_eq(cp_cur.text, "_toLong") || pe_eq(cp_cur.text, "_toFloat") ||
        pe_eq(cp_cur.text, "_toBool") || pe_eq(cp_cur.text, "_toChar")) {
        str cast = cp_cur.text;
        int cline = cp_cur.line;
        int ccol = cp_cur.col;
        cp_advance();
        @CmpExpr inner = cp_parse_expr();
        if cp_has_error() {
            return null;
        }
        @CmpExpr n = ce_new(CAST);
        n.line = cline;
        n.col = ccol;
        n.left = inner;
        n.op = cast;
        if pe_eq(cast, "_toStr") {
            n.result_type = STR;
        } else if pe_eq(cast, "_toInt") {
            n.result_type = INT;
        } else if pe_eq(cast, "_toLong") {
            n.result_type = LONG;
        } else if pe_eq(cast, "_toFloat") {
            n.result_type = FLOAT;
        } else if pe_eq(cast, "_toBool") {
            n.result_type = BOOL;
        } else if pe_eq(cast, "_toChar") {
            n.result_type = CHAR;
        }
        return n;
    }
    !!! `@type expr`: the address form of a cast.
    if cp_cur.tk == CT_OPERATOR && pe_eq(cp_cur.text, "@") {
        int cline = cp_cur.line;
        int ccol = cp_cur.col;
        cp_advance();
        if cp_cur.tk == CT_IDENT {
            str type_name = cp_cur.text;
            if pe_eq(type_name, "void") || pe_eq(type_name, "int") ||
               pe_eq(type_name, "longlong") || pe_eq(type_name, "float") ||
               pe_eq(type_name, "char") || pe_eq(type_name, "str") ||
               pe_eq(type_name, "bool") {
                cp_advance();
                @CmpExpr inner = cp_parse_expr();
                if cp_has_error() {
                    return null;
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
                } else if pe_eq(type_name, "longlong") {
                    n.result_type = AT_LONG;
                } else if pe_eq(type_name, "float") {
                    n.result_type = AT_FLOAT;
                } else if pe_eq(type_name, "char") {
                    n.result_type = AT_CHAR;
                } else if pe_eq(type_name, "str") {
                    n.result_type = AT_STR;
                } else if pe_eq(type_name, "bool") {
                    n.result_type = AT_BOOL;
                }
                return n;
            }
        }
        cp_error("expected type name after @");
        return null;
    }
    !!! A bare name, and `name{index}` for an element of a block.
    if cp_cur.tk == CT_IDENT {
        @CmpExpr n = ce_new(VAR_REF);
        n.line = cp_cur.line;
        n.col = cp_cur.col;
        n.result_type = INT;
        n.var_name = cp_cur.text;
        cp_advance();
        if cp_cur.tk == CT_LBRACE {
            cp_advance();
            @CmpExpr idx = cp_parse_expr();
            if idx == null {
                return null;
            }
            if cp_cur.tk != CT_RBRACE {
                cp_error("expected '}'");
                return null;
            }
            cp_advance();
            @CmpExpr arr = ce_new(ARRAY_ACCESS);
            arr.line = n.line;
            arr.col = n.col;
            arr.var_name = n.var_name;
            arr.left = idx;
            return arr;
        }
        return n;
    }
    !!! The parenthesised forms. The head is read as an expression and what came
    !!! back decides which form it is: a plain variable is one of the shapes that
    !!! begin with an identifier, and anything else is a grouped expression or a
    !!! binary operation.
    if cp_cur.tk == CT_LPAREN {
        int bline = cp_cur.line;
        int bcol = cp_cur.col;
        cp_advance();
        @CmpExpr left = cp_parse_expr();
        if cp_has_error() {
            return null;
        }
        if left.nk == VAR_REF && pe_eq(left.var_name, "SPREAD") {
            @CmpExpr n = ce_new(SPREAD);
            n.line = bline;
            n.col = bcol;
            n.left = cp_parse_expr();
            if cp_has_error() {
                return null;
            }
            if cp_cur.tk != CT_RPAREN {
                cp_error("expected ')'");
                return null;
            }
            cp_advance();
            return n;
        }
        if left.nk == VAR_REF && pe_eq(left.var_name, "CALL_EXPR") {
            if cp_cur.tk != CT_IDENT {
                cp_error("expected function name after CALL_EXPR");
                return null;
            }
            @CmpExpr n = ce_new(FUNC_CALL);
            n.line = bline;
            n.col = bcol;
            n.var_name = cp_cur.text;
            cp_advance();
            while cp_cur.tk == CT_COMMA {
                cp_advance();
                n.args = ce_add(n.args, cp_parse_expr());
            }
            if cp_cur.tk != CT_RPAREN {
                cp_error("expected ')'");
                return null;
            }
            cp_advance();
            n.result_type = INT;
            if pe_eq(n.var_name, "_toStr") {
                n.result_type = STR;
            } else if pe_eq(n.var_name, "_toInt") {
                n.result_type = INT;
            } else if pe_eq(n.var_name, "_toLong") {
                n.result_type = LONG;
            } else if pe_eq(n.var_name, "_toChar") {
                n.result_type = CHAR;
            } else if pe_eq(n.var_name, "_toFloat") {
                n.result_type = FLOAT;
            } else if pe_eq(n.var_name, "_toBool") {
                n.result_type = BOOL;
            }
            return n;
        }
        if left.nk == VAR_REF && pe_eq(left.var_name, "BCALL_EXPR") {
            if cp_cur.tk != CT_STRING {
                cp_error("expected string after BCALL_EXPR");
                return null;
            }
            @CmpExpr n = ce_new(FUNC_CALL);
            n.line = bline;
            n.col = bcol;
            n.var_name = cp_cur.text;
            cp_advance();
            n.result_type = INT;
            if cp_cur.tk == CT_IDENT {
                if cp_is("VOID") {
                    n.result_type = VOID;
                } else if cp_is("INT") {
                    n.result_type = INT;
                } else if cp_is("LONG") {
                    n.result_type = LONG;
                } else if cp_is("FLOAT") {
                    n.result_type = FLOAT;
                } else if cp_is("BOOL") {
                    n.result_type = BOOL;
                } else if cp_is("CHAR") {
                    n.result_type = CHAR;
                } else if cp_is("STR") {
                    n.result_type = STR;
                } else if cp_is("AT_INT") {
                    n.result_type = AT_INT;
                } else if cp_is("AT_FLOAT") {
                    n.result_type = AT_FLOAT;
                } else if cp_is("AT_CHAR") {
                    n.result_type = AT_CHAR;
                } else if cp_is("AT_STR") {
                    n.result_type = AT_STR;
                } else if cp_is("AT_VOID") {
                    n.result_type = AT_VOID;
                } else if cp_is("AT_BOOL") {
                    n.result_type = AT_BOOL;
                } else if cp_is("AT_LONG") {
                    n.result_type = AT_LONG;
                }
                cp_advance();
            }
            while cp_cur.tk == CT_COMMA {
                cp_advance();
                n.args = ce_add(n.args, cp_parse_expr());
            }
            if cp_cur.tk != CT_RPAREN {
                cp_error("expected ')'");
                return null;
            }
            cp_advance();
            return n;
        }
        !!! `(FLDP <pointer-expr> <offset> <TYPE>)`: the field of the struct the
        !!! pointer expression points at. A `@T` field or variable reads through the
        !!! pointer, so address = *pointer + offset.
        if left.nk == VAR_REF && pe_eq(left.var_name, "FLDP") {
            @CmpExpr n = ce_new(FLDP);
            n.line = bline;
            n.col = bcol;
            n.left = cp_parse_expr();
            if n.left == null {
                cp_error("expected pointer expression after FLDP");
                return null;
            }
            if cp_cur.tk != CT_INTEGER {
                cp_error("expected field offset");
                return null;
            }
            n.int_val = pe_atoi(cp_cur.text);
            cp_advance();
            if !cp_parse_r_type() {
                cp_error("expected field type");
                return null;
            }
            cp_advance();
            n.result_type = cp_rtype_type;
            n.ptr_depth = cp_rtype_depth;
            if cp_cur.tk != CT_RPAREN {
                cp_error("expected ')'");
                return null;
            }
            cp_advance();
            return n;
        }
        !!! `(FLD <var> <offset> <TYPE> <index>)`: a field of a block named by a
        !!! variable. The index is there for an array element and is absent for a
        !!! plain field.
        if left.nk == VAR_REF && pe_eq(left.var_name, "FLD") {
            @CmpExpr n = ce_new(FLD);
            n.line = bline;
            n.col = bcol;
            if cp_cur.tk != CT_IDENT {
                cp_error("expected var name after FLD");
                return null;
            }
            n.var_name = cp_cur.text;
            cp_advance();
            if cp_cur.tk != CT_INTEGER {
                cp_error("expected field offset");
                return null;
            }
            n.int_val = pe_atoi(cp_cur.text);
            cp_advance();
            if !cp_parse_r_type() {
                cp_error("expected field type");
                return null;
            }
            cp_advance();
            n.result_type = cp_rtype_type;
            n.ptr_depth = cp_rtype_depth;
            n.left = null;
            if cp_cur.tk != CT_RPAREN {
                n.left = cp_parse_expr();
            }
            if cp_cur.tk != CT_RPAREN {
                cp_error("expected ')'");
                return null;
            }
            cp_advance();
            return n;
        }
        if left.nk == VAR_REF && pe_eq(left.var_name, "CLOSURE") {
            if cp_cur.tk != CT_IDENT {
                cp_error("expected function name after CLOSURE");
                return null;
            }
            @CmpExpr n = ce_new(CLOSURE);
            n.line = bline;
            n.col = bcol;
            n.var_name = cp_cur.text;
            cp_advance();
            while cp_cur.tk == CT_COMMA {
                cp_advance();
                n.args = ce_add(n.args, cp_parse_expr());
            }
            if cp_cur.tk != CT_RPAREN {
                cp_error("expected ')'");
                return null;
            }
            cp_advance();
            n.result_type = FUNC;
            return n;
        }
        if left.nk == VAR_REF && pe_eq(left.var_name, "ICALL") {
            @CmpExpr n = ce_new(ICALL);
            n.line = bline;
            n.col = bcol;
            n.left = cp_parse_expr();
            if n.left == null {
                return null;
            }
            while cp_cur.tk == CT_COMMA {
                cp_advance();
                n.args = ce_add(n.args, cp_parse_expr());
            }
            if cp_cur.tk != CT_RPAREN {
                cp_error("expected ')'");
                return null;
            }
            cp_advance();
            n.result_type = INT;
            return n;
        }
        if left.nk == VAR_REF && pe_eq(left.var_name, "CLOSURE_CODE") {
            @CmpExpr inner = cp_parse_expr();
            if inner == null {
                return null;
            }
            if cp_cur.tk != CT_RPAREN {
                cp_error("expected ')'");
                return null;
            }
            cp_advance();
            @CmpExpr n = ce_new(CLOSURE_CODE);
            n.line = bline;
            n.col = bcol;
            n.left = inner;
            n.result_type = AT_FUNC;
            return n;
        }
        if left.nk == VAR_REF && pe_eq(left.var_name, "CLOSURE_FROM_PTR") {
            @CmpExpr inner = cp_parse_expr();
            if inner == null {
                return null;
            }
            if cp_cur.tk != CT_RPAREN {
                cp_error("expected ')'");
                return null;
            }
            cp_advance();
            @CmpExpr n = ce_new(CLOSURE_FROM_PTR);
            n.line = bline;
            n.col = bcol;
            n.left = inner;
            n.result_type = FUNC;
            return n;
        }
        if left.nk == VAR_REF && pe_eq(left.var_name, "CELL") {
            @CmpExpr inner = cp_parse_expr();
            if inner == null {
                return null;
            }
            if cp_cur.tk != CT_RPAREN {
                cp_error("expected ')'");
                return null;
            }
            cp_advance();
            @CmpExpr n = ce_new(CELL);
            n.line = bline;
            n.col = bcol;
            n.left = inner;
            n.result_type = AT_INT;
            return n;
        }
        if left.nk == VAR_REF && pe_eq(left.var_name, "DL") {
            @CmpExpr inner = cp_parse_expr();
            if inner == null {
                return null;
            }
            if cp_cur.tk != CT_RPAREN {
                cp_error("expected ')'");
                return null;
            }
            cp_advance();
            @CmpExpr n = ce_new(DL);
            n.line = bline;
            n.col = bcol;
            n.left = inner;
            n.result_type = INT;
            return n;
        }
        if left.nk == VAR_REF &&
           (pe_eq(left.var_name, "PRE_INCR") || pe_eq(left.var_name, "POST_INCR")) {
            CmpExprKind inc_kind = POST_INCR;
            if pe_eq(left.var_name, "PRE_INCR") {
                inc_kind = PRE_INCR;
            }
            @CmpExpr inner = cp_parse_expr();
            if inner == null {
                return null;
            }
            if cp_cur.tk == CT_COMMA {
                cp_advance();
                if cp_cur.tk == CT_OPERATOR {
                    str op_text = cp_cur.text;
                    cp_advance();
                    if cp_cur.tk != CT_RPAREN {
                        cp_error("expected ')'");
                        return null;
                    }
                    cp_advance();
                    @CmpExpr n = ce_new(inc_kind);
                    n.line = bline;
                    n.col = bcol;
                    n.left = inner;
                    n.op = op_text;
                    n.result_type = INT;
                    return n;
                }
            }
            return null;
        }
        if left.nk == VAR_REF && pe_eq(left.var_name, "AT") {
            @CmpExpr inner = cp_parse_expr();
            if inner == null {
                return null;
            }
            if cp_cur.tk != CT_RPAREN {
                cp_error("expected ')'");
                return null;
            }
            cp_advance();
            @CmpExpr n = ce_new(ADDR);
            n.line = bline;
            n.col = bcol;
            n.left = inner;
            n.result_type = AT_INT;
            return n;
        }
        if left.nk == VAR_REF && pe_eq(left.var_name, "ATAG") {
            @CmpExpr inner = cp_parse_expr();
            if inner == null {
                return null;
            }
            if inner.nk != ARRAY_ACCESS {
                cp_error("ATAG expects an array access (var{idx})");
                return null;
            }
            if cp_cur.tk != CT_RPAREN {
                cp_error("expected ')'");
                return null;
            }
            cp_advance();
            @CmpExpr n = ce_new(ANY_TAG);
            n.line = bline;
            n.col = bcol;
            n.var_name = inner.var_name;
            n.left = inner.left;
            n.result_type = INT;
            return n;
        }
        if left.nk == VAR_REF && pe_eq(left.var_name, "?") {
            @CmpExpr cond = cp_parse_expr();
            if cond == null {
                return null;
            }
            cp_expect_comma();
            if cp_has_error() {
                return null;
            }
            @CmpExpr true_expr = cp_parse_expr();
            if true_expr == null {
                return null;
            }
            cp_expect_comma();
            if cp_has_error() {
                return null;
            }
            @CmpExpr false_expr = cp_parse_expr();
            if false_expr == null {
                return null;
            }
            if cp_cur.tk != CT_RPAREN {
                cp_error("expected ')'");
                return null;
            }
            cp_advance();
            @CmpExpr n = ce_new(TERNARY);
            n.line = bline;
            n.col = bcol;
            n.left = cond;
            n.right = true_expr;
            n.args = ce_add(n.args, false_expr);
            n.result_type = cp_widen(true_expr.result_type, false_expr.result_type);
            return n;
        }
        if cp_cur.tk == CT_RPAREN {
            cp_advance();
            return left;
        }
        cp_expect_comma();
        if cp_has_error() {
            return null;
        }
        !!! `(a, \)`: a boolean test of one value.
        if cp_cur.tk == CT_OPERATOR && pe_eq(cp_cur.text, "\\") {
            str op = cp_cur.text;
            cp_advance();
            if cp_cur.tk != CT_RPAREN {
                cp_error("expected ')'");
                return null;
            }
            cp_advance();
            @CmpExpr n = ce_new(BINOP);
            n.line = bline;
            n.col = bcol;
            n.left = left;
            n.op = op;
            n.result_type = BOOL;
            return n;
        }
        !!! `(a, ~)`: the bitwise complement, whose width follows its operand.
        if cp_cur.tk == CT_OPERATOR && pe_eq(cp_cur.text, "~") {
            str op = cp_cur.text;
            cp_advance();
            if cp_cur.tk != CT_RPAREN {
                cp_error("expected ')'");
                return null;
            }
            cp_advance();
            @CmpExpr n = ce_new(BITNOT);
            n.line = bline;
            n.col = bcol;
            n.left = left;
            n.op = op;
            n.result_type = INT;
            if left.result_type == LONG {
                n.result_type = LONG;
            }
            return n;
        }
        @CmpExpr right = cp_parse_expr();
        if cp_has_error() {
            return null;
        }
        cp_expect_comma();
        if cp_has_error() {
            return null;
        }
        if cp_cur.tk != CT_OPERATOR {
            cp_error("expected operator, got '" + cp_cur.text + "'");
            return null;
        }
        str op = cp_cur.text;
        cp_advance();
        if cp_cur.tk != CT_RPAREN {
            cp_error("expected ')'");
            return null;
        }
        cp_advance();
        @CmpExpr n = null;
        if pe_eq(op, "<<") {
            n = ce_new(SHL);
            n.left = left;
            n.right = right;
            n.op = op;
            n.result_type = INT;
            if left.result_type == LONG {
                n.result_type = LONG;
            }
        } else if pe_eq(op, ">>") {
            n = ce_new(SHR);
            n.left = left;
            n.right = right;
            n.op = op;
            n.result_type = INT;
            if left.result_type == LONG {
                n.result_type = LONG;
            }
        } else {
            n = ce_new(BINOP);
            n.left = left;
            n.right = right;
            n.op = op;
            n.result_type = cp_widen(left.result_type, right.result_type);
        }
        n.line = bline;
        n.col = bcol;
        return n;
    }
    cp_error("expected expression, got '" + cp_cur.text + "'");
    return null;
}
