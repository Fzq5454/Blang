#once
!~
 ~  bootstrap/frontend/rgen_resolve_op.b: the frontend/rgen_resolve_op.
 ~
 ~  The type of an operator expression: a binary operation (pointer arithmetic keeps
 ~  the pointer type, the arithmetic kinds widen to float/str/longlong, comparisons
 ~  are bool, bit operations keep the left operand's width), a unary `!`, `-` or `$`
 ~  dereference, `@` (address-of, which adds one pointer level), a `toX`/`@X` cast,
 ~  the conditional operator, `~` and the shifts.
 ~
 ~  The unsigned flag is carried along: an operation is unsigned when one of its
 ~  operands is, the way C converts a signed one; a shift is the exception, since
 ~  its result is the type of the value being shifted.
 ~!

#head "rgen"

!!! resolve_operator(): the type of one operator expression.
bool rg_resolve_operator -> @ExprNode n {
    if n.nk == BINOP {
        if !rg_resolve_expr_type(n.left) || !rg_resolve_expr_type(n.right) {
            return false;
        }
        VarType lt = n.left.result_type;
        VarType rt = n.right.result_type;
        str op = n.op;
        !!! An operator is compared by text: `==` on two `str` values compares the
        !!! blocks they point at, and the text of an operator is a block of its own.
        if pe_eq(op, "+") || pe_eq(op, "-") || pe_eq(op, "*") || pe_eq(op, "/") {
            !!! A pointer operand keeps its type through `+`/`-`: is_at_type covers
            !!! the whole AT_* block and @longlong, which sits outside it.
            bool lt_at = rg_is_at_type(lt) || lt == AT_FUNC;
            bool ptr_arith = (pe_eq(op, "+") || pe_eq(op, "-")) && lt_at;
            if ptr_arith {
                !!! pointer + int keeps the pointer type.
                n.result_type = lt;
            } else if lt == FLOAT || rt == FLOAT {
                n.result_type = FLOAT;
            } else if lt == STR || rt == STR {
                n.result_type = STR;
            } else if lt == LONG || rt == LONG {
                n.result_type = LONG;
            } else {
                n.result_type = INT;
            }
            !!! -W-ntype-op: the two operands hold values of different types and the
            !!! answer is not the one the reader had in mind (`1 + "str"` concatenates
            !!! instead of adding). Walking a pointer (`p + 1`) is a different type on
            !!! purpose, so it is left alone.
            if rg_warn_ntype_op && !ptr_arith {
                rg_report_ntype_op(n, lt, rt);
            }
        } else if pe_eq(op, "&&") || pe_eq(op, "||") || pe_eq(op, "==") || pe_eq(op, "!=") ||
                  pe_eq(op, "<") || pe_eq(op, ">") || pe_eq(op, "<=") || pe_eq(op, ">=") {
            !!! -W-ntype-cmp: the two operands of a comparison have to hold values of
            !!! one type; `x < y` on an int and a str compares the number with a
            !!! pointer and is a mistake far more often than it is meant.
            if rg_warn_ntype_cmp && !pe_eq(op, "&&") && !pe_eq(op, "||") {
                rg_report_ntype_cmp(n, lt, rt);
            }
            n.result_type = BOOL;
        } else if pe_eq(op, "<<") || pe_eq(op, ">>") || pe_eq(op, "&") || pe_eq(op, "|") ||
                  pe_eq(op, "^") || pe_eq(op, "~") {
            !!! Bit operations keep the width of their left operand.
            if lt == LONG {
                n.result_type = LONG;
            } else {
                n.result_type = INT;
            }
            !!! -W-ntype-op covers the bit operations as well: `mask & 1.5` or
            !!! `bits << "n"` reads one of the two as the other.
            if rg_warn_ntype_op {
                rg_report_ntype_op(n, lt, rt);
            }
        }
        !!! The operation is unsigned when one of its operands is, the way C
        !!! converts a signed one to unsigned. A shift is the exception: its result
        !!! is the type of the value being shifted, so only the left operand
        !!! decides. A comparison carries the flag too, so the comparison itself is
        !!! made unsigned at the point it is emitted.
        if pe_eq(op, "<<") || pe_eq(op, ">>") {
            n.is_unsigned = n.left.is_unsigned;
        } else if !pe_eq(op, "&&") && !pe_eq(op, "||") {
            n.is_unsigned = n.left.is_unsigned || n.right.is_unsigned;
        }
        return true;
    }
    if n.nk == UNARY {
        if pe_eq(n.op, "!") {
            rg_resolve_expr_type(n.left);
            n.result_type = BOOL;
        }
        if pe_eq(n.op, "-") {
            !!! Unary minus keeps the operand's type (a struct keeps its struct
            !!! type, which is what the operator rewrite looks at).
            if !rg_resolve_expr_type(n.left) {
                return false;
            }
            n.result_type = n.left.result_type;
            n.ptr_depth = n.left.ptr_depth;
            n.is_unsigned = n.left.is_unsigned;
        }
        if pe_eq(n.op, "$") {
            rg_resolve_expr_type(n.left);
            !!! $ dereferences one pointer level.
            if n.left.ptr_depth > 0 {
                n.ptr_depth = n.left.ptr_depth - 1;
            } else {
                n.ptr_depth = 0;
            }
            !!! If still a pointer, keep the pointer type; else decay to the pointee.
            if n.ptr_depth >= 1 {
                n.result_type = n.left.result_type;
            } else {
                n.result_type = rg_pointee_of(n.left.result_type);
            }
        }
        return true;
    }
    if n.nk == ADDR {
        if !rg_resolve_expr_type(n.left) {
            return false;
        }
        !!! @ adds one pointer level. The single-pointer type becomes the pointee's
        !!! pointer type (AT_*), and the depth tracks extra levels.
        n.ptr_depth = n.left.ptr_depth + 1;
        if n.left.ptr_depth >= 1 {
            !!! pointer to a pointer: keep AT_X.
            n.result_type = n.left.result_type;
        } else if n.left.result_type == INT {
            n.result_type = AT_INT;
        } else if n.left.result_type == LONG {
            n.result_type = AT_LONG;
        } else if n.left.result_type == FLOAT {
            n.result_type = AT_FLOAT;
        } else if n.left.result_type == CHAR {
            n.result_type = AT_CHAR;
        } else if n.left.result_type == STR {
            n.result_type = AT_STR;
        } else if n.left.result_type == BOOL {
            n.result_type = AT_BOOL;
        } else if n.left.result_type == FUNC {
            n.result_type = AT_FUNC;
        } else {
            n.result_type = AT_INT;
        }
        !!! pointee type.
        n.address_type = n.left.result_type;
        return true;
    }
    if n.nk == CAST {
        rg_resolve_expr_type(n.left);
        if pe_eq(n.op, "toStr") {
            n.result_type = STR;
        } else if pe_eq(n.op, "toInt") {
            n.result_type = INT;
        } else if pe_eq(n.op, "toLong") {
            n.result_type = LONG;
        } else if pe_eq(n.op, "toFloat") {
            n.result_type = FLOAT;
        } else if pe_eq(n.op, "toBool") {
            n.result_type = BOOL;
        } else if pe_eq(n.op, "toChar") {
            n.result_type = CHAR;
        } else if pe_eq(n.op, "@void") {
            n.result_type = AT_VOID;
        } else if pe_eq(n.op, "@int") {
            n.result_type = AT_INT;
        } else if pe_eq(n.op, "@longlong") {
            n.result_type = AT_LONG;
        } else if pe_eq(n.op, "@float") {
            n.result_type = AT_FLOAT;
        } else if pe_eq(n.op, "@char") {
            n.result_type = AT_CHAR;
        } else if pe_eq(n.op, "@str") {
            n.result_type = AT_STR;
        } else if pe_eq(n.op, "toFunc") {
            n.result_type = FUNC;
        } else if pe_eq(n.op, "toAtFunc") {
            n.result_type = AT_FUNC;
        }
        !!! `(utype T)x` casts to an unsigned one of the same width, which is the
        !!! cast the type above already is; only the flag survives. Any other target
        !!! has no unsigned reading.
        if !(n.result_type == INT || n.result_type == LONG || n.result_type == CHAR) {
            n.is_unsigned = false;
        }
        return true;
    }
    if n.nk == TERNARY {
        if !rg_resolve_expr_type(n.left) {
            return false;
        }
        if !rg_resolve_expr_type(n.right) {
            return false;
        }
        if !rg_resolve_expr_type(n.args) {
            return false;
        }
        VarType t = n.right.result_type;
        VarType f = n.args.result_type;
        if t == FLOAT || f == FLOAT {
            n.result_type = FLOAT;
        } else if t == STR || f == STR {
            n.result_type = STR;
        } else if t == LONG || f == LONG {
            n.result_type = LONG;
        } else {
            n.result_type = INT;
        }
        n.is_unsigned = n.right.is_unsigned || n.args.is_unsigned;
        return true;
    }
    if n.nk == BITNOT {
        if !rg_resolve_expr_type(n.left) {
            return false;
        }
        !!! A 64-bit operand keeps its width: `~x` of a longlong is a longlong.
        if n.left.result_type == LONG {
            n.result_type = LONG;
        } else {
            n.result_type = INT;
        }
        n.is_unsigned = n.left.is_unsigned;
        return true;
    }
    if n.nk == SHL || n.nk == SHR {
        if !rg_resolve_expr_type(n.left) || !rg_resolve_expr_type(n.right) {
            return false;
        }
        !!! Shifting a longlong shifts all 64 bits, so the result stays a longlong.
        if n.left.result_type == LONG {
            n.result_type = LONG;
        } else {
            n.result_type = INT;
        }
        n.is_unsigned = n.left.is_unsigned;
        return true;
    }
    return true;
}

!!! -W-ntype-cmp: `==`, `!=`, `<`, `>`, `<=` and `>=` on two operands of different
!!! types. The comparison is a mistake far more often than it is meant: the two
!!! values are read as one type and the answer says nothing about the program the
!!! reader had in mind (`x < y` on an int and a str compares a number with a
!!! pointer). Two cases are the language spelling something on purpose and are left
!!! alone: comparing with `null`, and comparing with the untyped `@void` a block of
!!! memory comes back as. The numeric kinds are one family as well - the language
!!! compares an int with a longlong, a char or a float by converting, the way C
!!! does, and `n == 0` on a count that happens to be a longlong is not a mistake.
bool rgx_numeric_kind -> VarType t {
    if t == INT || t == LONG || t == FLOAT || t == CHAR || t == BOOL {
        return true;
    }
    return false;
}

void rg_report_ntype_cmp -> @ExprNode n, VarType lt, VarType rt {
    if lt == rt {
        end;
    }
    if lt == AT_VOID || rt == AT_VOID {
        end;
    }
    if rgx_numeric_kind(lt) && rgx_numeric_kind(rt) {
        end;
    }
    if n.left != null && n.left.nk == LIT_NULL {
        end;
    }
    if n.right != null && n.right.nk == LIT_NULL {
        end;
    }
    str msg = "comparison between '" + rg_type_name(lt) + "' and '" + rg_type_name(rt) + "'";
    int hl = n.tok_len;
    if hl <= 0 {
        hl = 1;
    }
    rg_fmt_warn(n.line, n.col, msg, hl);
}

!!! -W-ntype-op: an arithmetic (`+`, `-`, `*`, `/`) or bit (`&`, `|`, `^`, `<<`,
!!! `>>`) operation whose two operands hold values of different types. One of the
!!! two is read as the other and the answer is not the one the reader had in mind:
!!! `1 + "str"` concatenates instead of adding, `1 + true` adds one. The types are
!!! the ones the operands resolved to, which is what tells `1 + 'a'` (an int and a
!!! char) apart from `'a' + 'b'`.
!!!
!!! The span runs from the first operand through the second one, so the reader sees
!!! the whole `1 + "str"` and not the operator alone. A span that would run past the
!!! end of that line is cut at it: the block under the warning is one line of source
!!! with the caret under it.
void rg_report_ntype_op -> @ExprNode n, VarType lt, VarType rt {
    if lt == rt {
        end;
    }
    if lt == AT_VOID || rt == AT_VOID {
        end;
    }
    !!! An int and a longlong are one kind of value at two widths, which is what
    !!! every `v * 10 + 1` of this source does; the difference this warning is about
    !!! is the one between kinds (`1 + "str"`, `1 + true`).
    if lt == INT && rt == LONG {
        end;
    }
    if lt == LONG && rt == INT {
        end;
    }
    @ExprNode l = n.left;
    @ExprNode r = n.right;
    if l == null || r == null {
        end;
    }
    int hl = n.tok_len;
    if hl <= 0 {
        hl = 1;
    }
    if l.line == r.line && r.col >= l.col {
        int rlen = r.tok_len;
        if rlen <= 0 {
            rlen = 1;
        }
        hl = (r.col + rlen) - l.col;
        if hl <= 0 {
            hl = 1;
        }
    }
    !!! The caret is drawn under one line of source, so a span that reaches past the
    !!! end of it stops there.
    str line_src = rgx_line_text(l.line);
    int ln = p_text_len(line_src);
    while ln > 0 && (line_src[ln - 1] == '\n' || line_src[ln - 1] == '\r') {
        ln = ln - 1;
    }
    if l.col - 1 < ln {
        int max_hl = ln - (l.col - 1);
        if hl > max_hl {
            hl = max_hl;
        }
    }
    str msg = "operation between '" + rg_type_name(lt) + "' and '" + rg_type_name(rt) + "'";
    rg_fmt_warn(l.line, l.col, msg, hl);
}
