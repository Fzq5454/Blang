#once
!~
 ~  bootstrap/frontend/parser_expr.b: the frontend/parser_expr.
 ~
 ~  Expressions are read by precedence climbing: `parse_expr(min_prec)` reads a
 ~  primary, then keeps taking binary operators whose precedence is at least
 ~  `min_prec`, and the right operand of each is read with one level more, which is
 ~  what makes `a + b * c` group the way it does. the toolchain version gives `min_prec` a
 ~  default of 0; the call sites of this implementation pass the 0, because a default argument
 ~  is one more thing for the two compilers to agree on.
 ~
 ~  A lambda literal is read here too: `[type name, ...] { body }` becomes a closure
 ~  object, and `=> (args)` right after it calls it on the spot.
 ~!

#head "parser"

!!! The precedence of one binary operator, from the loosest to the tightest. A
!!! spelling that is not an operator answers 0, which is below every level.
!!!
!!! The first character narrows it to one or two candidates: an operator is one or
!!! two characters, so the comparison the toolchain runs against every spelling in turn
!!! is answered here after reading one byte. A call against the whole list was the
!!! parse stage's largest single cost on the compiler's own source - about twenty
!!! text comparisons for every `+` of the input.
stub int p_prec_one -> str op, int prec;
stub int p_prec_two -> str op, char c2, int prec;
stub int p_prec_len2 -> str op, int prec;

int p_prec -> str op {
    if op == null {
        return 0;
    }
    char c = op[0];
    if c == '+' || c == '-' {
        return p_prec_one(op, 7);
    }
    if c == '*' || c == '/' || c == '%' {
        return p_prec_one(op, 9);
    }
    if c == '^' {
        return p_prec_one(op, 4);
    }
    if c == '~' {
        return p_prec_one(op, 10);
    }
    if c == '|' {
        if op[1] == (char)0 {
            return 3;
        }
        return p_prec_two(op, '|', 1);
    }
    if c == '&' {
        if op[1] == (char)0 {
            return 5;
        }
        return p_prec_two(op, '&', 2);
    }
    if c == '!' {
        if op[1] == (char)0 {
            return 10;
        }
        return p_prec_two(op, '=', 6);
    }
    if c == '=' {
        return p_prec_two(op, '=', 6);
    }
    if c == '<' || c == '>' {
        if op[1] == (char)0 || op[1] == '=' {
            return p_prec_len2(op, 6);
        }
        if op[1] == c {
            return p_prec_len2(op, 8);
        }
        return 0;
    }
    return 0;
}

!!! The precedence of a one-character operator, and 0 for the longer spellings of
!!! the same first character.
int p_prec_one -> str op, int prec {
    if op[1] == (char)0 {
        return prec;
    }
    return 0;
}

!!! The precedence of the two-character operator `c2 <prec>`, and 0 for anything
!!! else that starts with the same character.
int p_prec_two -> str op, char c2, int prec {
    if op[1] == c2 && op[2] == (char)0 {
        return prec;
    }
    return 0;
}

!!! The precedence of a two-character comparison: `<prec>` and then the end of the
!!! text, whatever the second character was.
int p_prec_len2 -> str op, int prec {
    if op[2] == (char)0 {
        return prec;
    }
    return 0;
}

@ExprNode parse_expr -> int min_prec {
    @ExprNode left = p_primary();
    if left == null {
        return null;
    }

    !!! An immediate call on a lambda literal: `[params] { body } => (args)`.
    if left.nk == LAMBDA && p_is(TK_ARROW) {
        @LambdaRec lr = p_find_lambda(left.lambda_id);
        int aline = p_cur.line;
        int acol = p_cur.col;
        p_adv();
        if !p_is(TK_LPAREN) {
            p_error_at(aline, acol, 0, "missing '(' after '=>'");
            return null;
        }
        p_adv();
        if lr != null {
            lr.immediate = true;
            if !p_is(TK_RPAREN) {
                lr.immediate_args = p_chain_expr(lr.immediate_args, parse_expr(0));
                while p_is(TK_COMMA) {
                    p_adv();
                    lr.immediate_args = p_chain_expr(lr.immediate_args, parse_expr(0));
                }
            }
        }
        if !p_is(TK_RPAREN) {
            p_error("missing ')'");
            return null;
        }
        p_adv();
    }

    while !p_is(TK_EOF) && p_is_binary_op() {
        !!! The spelling is read once: asking the precedence of a second copy of it
        !!! was one heap block per operator of the input.
        str op = span_text(p_cur.start, p_cur.stop);
        int prec = p_prec(op);
        if prec < min_prec {
            skip;
        }
        int opline = p_cur.line;
        int opcol = p_cur.col;
        p_adv();
        @ExprNode right = parse_expr(prec + 1);
        if right == null {
            return null;
        }
        ExprKind nk = BINOP;
        if op[0] == '<' && op[1] == '<' {
            nk = SHL;
        } else if op[0] == '>' && op[1] == '>' {
            nk = SHR;
        }
        @ExprNode n = p_new_expr(nk);
        !!! The node spans the whole expression, not just the operator: an error on
        !!! `a + b` has to underline `a + b`. The leftmost operand gives the start
        !!! and the right operand's own span the end, so nested binary expressions
        !!! compose.
        n.line = left.line;
        n.col = left.col;
        int endc = right.col + (right.tok_len > 0 ? right.tok_len : 1);
        if right.line == n.line && endc > n.col {
            n.tok_len = endc - n.col;
        } else {
            n.tok_len = left.tok_len > 0 ? left.tok_len : 1;
        }
        n.left = left;
        n.right = right;
        n.op = op;
        n.op_line = opline;
        n.op_col = opcol;
        left = n;
    }

    !!! The conditional operator is the loosest level, so it is only taken at the
    !!! top of an expression.
    if min_prec <= 0 && p_is(TK_QMARK) {
        p_adv();
        @ExprNode true_expr = parse_expr(1);
        if true_expr == null {
            return null;
        }
        if !p_is(TK_COLON) {
            p_error("missing ':'");
            return null;
        }
        p_adv();
        @ExprNode false_expr = parse_expr(1);
        if false_expr == null {
            return null;
        }
        @ExprNode n2 = p_new_expr(TERNARY);
        n2.line = left.line;
        n2.col = left.col;
        int tend = false_expr.col + (false_expr.tok_len > 0 ? false_expr.tok_len : 1);
        if false_expr.line == n2.line && tend > n2.col {
            n2.tok_len = tend - n2.col;
        } else {
            n2.tok_len = left.tok_len > 0 ? left.tok_len : 1;
        }
        n2.left = left;
        n2.right = true_expr;
        !!! The false arm travels in `args`, the way the toolchain node reuses args[0] for
        !!! it.
        n2.args = p_chain_expr(n2.args, false_expr);
        n2.nargs = 1;
        left = n2;
    }
    !!! `a = b`: the assignment is an expression whose value is the object it wrote
    !!! (`int b = (a = 1);` takes 1, and `(a = 1) = 2` stores into `a` again). It
    !!! stands below the conditional, the precedence C gives it, and it is read to
    !!! the right: `a = b = c` assigns `c` to `b` and then to `a`. the toolchain
    !!! `Parser::parse_expr` takes the same step.
    if min_prec <= 0 && p_is(TK_ASSIGN) {
        int aline = p_cur.line;
        int acol = p_cur.col;
        p_adv();
        @ExprNode avalue = parse_expr(0);
        if avalue == null {
            return null;
        }
        if !p_assignable_target(left) {
            !!! `1 = v`, `(a + b) = v`: the target is not something a value can be
            !!! stored in, which is what the error says. The value behind the `=`
            !!! is what the expression is worth.
            p_error_at(aline, acol, 1, "invalid assignment");
            return avalue;
        }
        @ExprNode na = p_new_expr(ASSIGN_EXPR);
        na.line = left.line;
        na.col = left.col;
        int aend = avalue.col + (avalue.tok_len > 0 ? avalue.tok_len : 1);
        if avalue.line == na.line && aend > na.col {
            na.tok_len = aend - na.col;
        } else {
            na.tok_len = left.tok_len > 0 ? left.tok_len : 1;
        }
        na.left = left;
        na.right = avalue;
        na.op = "=";
        na.op_line = aline;
        na.op_col = acol;
        left = na;
    }
    return left;
}

!!! Can `n` be the target of an assignment? A name, a field of one, an element of an
!!! array (`a[i]`, `o.people[i]`), the object a pointer names (`$p`), and an
!!! assignment itself: `a = 1` answers with the object it wrote, so `(a = 1) = 2`
!!! stores into `a` again, the way the result of an assignment is an lvalue.
bool p_assignable_target -> @ExprNode n {
    if n == null {
        return false;
    }
    if n.nk == VAR_REF || n.nk == MEMBER_ACCESS || n.nk == ARRAY_ACCESS ||
       n.nk == FIELD_ELEM || n.nk == ASSIGN_EXPR {
        return true;
    }
    if n.nk == UNARY {
        return p_text_eq(n.op, "$") && n.left != null && n.left.nk == VAR_REF;
    }
    return false;
}

!!! Whether the token the parser is on is one of the binary operators. The kind is
!!! read from the token here and not through `p_is`: a call per spelling asked the
!!! same question up to eighteen times for every operator the parser looked at.
bool p_is_binary_op {
    TokenKind k = p_cur.tk;
    if k == TK_PLUS || k == TK_MINUS || k == TK_STAR || k == TK_SLASH || k == TK_MOD {
        return true;
    }
    if k == TK_EQ || k == TK_NE || k == TK_AND || k == TK_OR {
        return true;
    }
    if k == TK_LT || k == TK_GT || k == TK_LE || k == TK_GE {
        return true;
    }
    if k == TK_BITAND || k == TK_BITOR || k == TK_BITXOR {
        return true;
    }
    return k == TK_SHL || k == TK_SHR;
}

!!! `[type name, ...] { body }`. The parameters may carry the `name[]` marker of an
!!! array parameter, and the body is read with `parse_block`, so `back <value>;`
!!! inside it is what the closure hands out.
@ExprNode p_lambda {
    int line = p_cur.line;
    int col = p_cur.col;
    p_adv();

    @ExprNode n = p_new_expr(LAMBDA);
    n.line = line;
    n.col = col;
    p_lambda_counter = p_lambda_counter + 1;
    n.lambda_id = p_lambda_counter;
    @LambdaRec rec = p_new_lambda(n.lambda_id);

    while !p_is(TK_EOF) && !p_is(TK_RBRACKET) {
        VarType pt = p_type();
        if !p_is(TK_IDENT) {
            p_error("missing parameter name in lambda");
            return null;
        }
        rec.param_types = p_chain_type(rec.param_types, p_new_type(pt));
        rec.params = p_chain_str(rec.params,
                                 p_new_span(p_cur.start, p_cur.stop, p_cur.line, p_cur.col));
        p_adv();
        !!! The optional marker of an array parameter: `name[]`.
        bool arr = false;
        if p_is(TK_LBRACKET) && p_peek_is(1, TK_RBRACKET) {
            arr = true;
            p_adv();
            p_adv();
        }
        rec.param_is_array = p_chain_bool(rec.param_is_array, p_new_bool(arr));
        if p_is(TK_COMMA) {
            p_adv();
        } else if !p_is(TK_RBRACKET) {
            p_error("missing ',' or ']' in lambda parameters");
            return null;
        }
    }
    if !p_is(TK_RBRACKET) {
        p_error("missing ']'");
        return null;
    }
    p_adv();

    if !p_is(TK_LBRACE) {
        p_error("missing '{' after lambda parameters");
        return null;
    }
    str saved_name = p_func_name;
    str saved_ret = p_func_ret;
    bool saved_header = p_header_done;
    p_func_name = "";
    p_func_ret = "";
    p_header_done = true;
    rec.body = p_block();
    p_func_name = saved_name;
    p_func_ret = saved_ret;
    p_header_done = saved_header;

    n.result_type = FUNC;
    n.tok_len = 1;
    return n;
}
