#once
!~
 ~  bootstrap/frontend/parser_call.b: the frontend/parser_call.
 ~
 ~  A call written as a statement: `f(args)`, `obj.method(args)`, a chain of
 ~  methods (`a.add(b).show()`) and an explicit template instantiation
 ~  (`name(T1, T2)(args)`).
 ~
 ~  The receiver of a method call is rebuilt as an expression - a variable, a field
 ~  chain, an array element - so that the code generator can take its address. The
 ~  argument lists vectors are chains here, and the pieces of one
 ~  argument (its expression, the name it was written with, and where that name
 ~  stands) travel in fields, because a function answers one value.
 ~!

#head "parser"

!!! A `VAR_REF` for the head name of the statement: the receiver a method call or
!!! a subscript starts from.
@ExprNode p_head_ref -> @StmtNode s {
    @ExprNode h = p_new_expr(VAR_REF);
    h.var_name = s.var_name;
    h.line = s.line;
    h.col = s.col;
    h.tok_len = p_text_len(s.var_name);
    return h;
}

!!! The pieces of one call argument.
@ExprNode p_arg_expr;
str p_arg_name;
int p_arg_name_line;
int p_arg_name_col;
int p_arg_name_len;

!!! Read one argument. `name = expr` is a named argument; `arg etc` asks for the
!!! variadic pack to be spread into this call. A `=` still standing after the
!!! value means the source wrote an assignment where the call takes a value
!!! (`system.out(1 = "hello")`), and its target is not a name: that is reported
!!! as the invalid assignment it is, and the value behind the `=` is kept as the
!!! argument so the rest of the list is read the way a valid one would be. The
!!! `Parser::parse_arg_value` is the same step.
void p_parse_call_arg {
    p_arg_name = "";
    p_arg_name_line = 0;
    p_arg_name_col = 0;
    p_arg_name_len = 0;
    if p_is(TK_IDENT) && p_peek_is(1, TK_ASSIGN) {
        p_arg_name = span_text(p_cur.start, p_cur.stop);
        p_arg_name_line = p_cur.line;
        p_arg_name_col = p_cur.col;
        p_arg_name_len = p_cur.stop - p_cur.start;
        p_adv();
        p_adv();
    }
    p_arg_expr = parse_expr(0);
    if p_arg_expr != null && p_is(TK_ASSIGN) {
        !!! No `p_sync()` here: the parser stands right after the target and the
        !!! value behind the `=` is what the caller is waiting for.
        p_error_at(p_cur.line, p_cur.col, 1, "invalid assignment");
        p_adv();
        @ExprNode value = parse_expr(0);
        if value != null {
            p_arg_expr = value;
        }
    }
    if p_arg_expr != null && p_is(TK_KEYWORD) && p_name_is("etc") {
        p_arg_expr.spread = true;
        p_adv();
    }
}

!!! Append the argument just read (with its name and position) to a statement.
void p_stmt_add_arg -> @StmtNode s {
    s.args = p_chain_expr(s.args, p_arg_expr);
    s.arg_names = p_chain_str(s.arg_names, p_new_name(p_arg_name, p_arg_name_line, p_arg_name_col));
    s.arg_name_lines = p_chain_int(s.arg_name_lines, p_new_int(p_arg_name_line));
    s.arg_name_cols = p_chain_int(s.arg_name_cols, p_new_int(p_arg_name_col));
    s.arg_name_lens = p_chain_int(s.arg_name_lens, p_new_int(p_arg_name_len));
    s.nargs = s.nargs + 1;
}

!!! The same for a call expression (`a.add(b).show()`).
void p_expr_add_arg -> @ExprNode n {
    n.args = p_chain_expr(n.args, p_arg_expr);
    n.arg_names = p_chain_str(n.arg_names, p_new_name(p_arg_name, p_arg_name_line, p_arg_name_col));
    n.arg_name_lines = p_chain_int(n.arg_name_lines, p_new_int(p_arg_name_line));
    n.arg_name_cols = p_chain_int(n.arg_name_cols, p_new_int(p_arg_name_col));
    n.arg_name_lens = p_chain_int(n.arg_name_lens, p_new_int(p_arg_name_len));
    n.nargs = n.nargs + 1;
}

!!! Attach the receiver and the arguments of one step of a method chain to a
!!! statement: the receiver first, under an empty name (it is not a parameter),
!!! then every argument under the name it was written with. The same thing the
!!! does where the last step of a chain becomes the statement.
!!!
!!! A statement whose argument list broke off is built by the same function: the
!!! call as far as it could be read still names what it was called on, and a
!!! receiver dropped there took the use of the name it holds with it -
!!! `system.out(a b)` came out as `struct 'system' never used` beside the syntax
!!! error.
void p_attach_call_args -> @StmtNode s, @ExprNode cur_recv, @ExprNode step_args,
                           @StrNode step_names, @IntNode step_nl, @IntNode step_nc,
                           @IntNode step_nlen {
    s.args = p_chain_expr(s.args, cur_recv);
    s.arg_names = p_chain_str(s.arg_names, p_new_name("", 0, 0));
    s.arg_name_lines = p_chain_int(s.arg_name_lines, p_new_int(0));
    s.arg_name_cols = p_chain_int(s.arg_name_cols, p_new_int(0));
    s.arg_name_lens = p_chain_int(s.arg_name_lens, p_new_int(0));
    s.nargs = 1;
    @ExprNode sa = step_args;
    @StrNode sn = step_names;
    @IntNode sl = step_nl;
    @IntNode sc = step_nc;
    @IntNode sk = step_nlen;
    while sa != null {
        !!! The node is taken out of the list it is in before it is appended to the
        !!! other: appending it while its own link is still set would join the whole
        !!! rest of the list again, and the second round would walk a chain that
        !!! runs in a ring.
        @ExprNode sa_next = sa.next;
        sa.next = null;
        s.args = p_chain_expr(s.args, sa);
        !!! The name belongs to this argument and is taken out of its own chain the
        !!! same way: every one of the four is advanced to its next with the
        !!! argument.
        @StrNode sn_next = null;
        if sn != null {
            sn_next = sn.next;
            sn.next = null;
        }
        @IntNode sl_next = null;
        if sl != null {
            sl_next = sl.next;
            sl.next = null;
        }
        @IntNode sc_next = null;
        if sc != null {
            sc_next = sc.next;
            sc.next = null;
        }
        @IntNode sk_next = null;
        if sk != null {
            sk_next = sk.next;
            sk.next = null;
        }
        s.arg_names = p_chain_str(s.arg_names, sn);
        s.arg_name_lines = p_chain_int(s.arg_name_lines, sl);
        s.arg_name_cols = p_chain_int(s.arg_name_cols, sc);
        s.arg_name_lens = p_chain_int(s.arg_name_lens, sk);
        s.nargs = s.nargs + 1;
        sa = sa_next;
        sn = sn_next;
        sl = sl_next;
        sc = sc_next;
        sk = sk_next;
    }
}

!!! Append one more index to an ARRAY_ACCESS node: the first index lives in `left`
!!! and the rest in `indices`, which is the shape the toolchain reader builds too.
void p_array_access_add_index -> @ExprNode e, @ExprNode idx {
    if e.indices == null && e.left != null {
        e.indices = p_chain_expr(e.indices, e.left);
        e.left = null;
    }
    e.indices = p_chain_expr(e.indices, idx);
}

@StmtNode p_func_call {
    @StmtNode s = p_new_stmt(CALL_FUNC);
    s.var_name = span_text(p_cur.start, p_cur.stop);
    p_adv();

    !!! The receiver while it is still made of field reads and subscripts. A null
    !!! one means the receiver is the bare head name.
    @ExprNode recv = null;
    bool is_method = false;
    while true {
        if p_is(TK_DOT) && p_peek_is(1, TK_IDENT) {
            if p_peek_is(2, TK_LPAREN) {
                is_method = true;
                skip;
            }
            @ExprNode base = recv;
            if base == null {
                base = p_head_ref(s);
            }
            p_adv();
            @ExprNode m = p_new_expr(MEMBER_ACCESS);
            m.left = base;
            m.member_name = span_text(p_cur.start, p_cur.stop);
            m.var_name = m.member_name;
            m.result_type = INT;
            m.line = p_cur.line;
            m.col = p_cur.col;
            m.tok_len = p_cur.stop - p_cur.start;
            p_adv();
            recv = m;
            continue;
        }
        if p_is(TK_LBRACKET) {
            !!! `arr[i]` of a variable is a heap array element; `o.data[i]` of a field
            !!! chain is an element of an array field. Further subscripts extend the
            !!! same node.
            @ExprNode base2 = recv;
            if base2 == null {
                base2 = p_head_ref(s);
            }
            p_adv();
            if p_is(TK_RBRACKET) {
                p_error_at(p_cur.line, p_cur.col, 0, "index required inside '[]'");
                p_adv();
                return null;
            }
            @ExprNode idx = parse_expr(0);
            if idx == null {
                return null;
            }
            if !p_is(TK_RBRACKET) {
                p_error_at(p_cur.line, p_cur.col, p_cur.stop - p_cur.start, "missing ']'");
                return null;
            }
            p_adv();
            if base2.nk == ARRAY_ACCESS && p_text_eq(base2.var_name, s.var_name) {
                p_array_access_add_index(base2, idx);
                recv = base2;
            } else if recv == null {
                @ExprNode e = p_new_expr(ARRAY_ACCESS);
                e.line = s.line;
                e.col = s.col;
                e.var_name = s.var_name;
                e.left = idx;
                e.result_type = INT;
                recv = e;
            } else {
                @ExprNode e2 = p_new_expr(FIELD_ELEM);
                e2.line = base2.line;
                e2.col = base2.col;
                e2.left = base2;
                e2.right = idx;
                e2.result_type = INT;
                recv = e2;
            }
            continue;
        }
        skip;
    }

    if is_method {
        !!! The whole `recv.m1(a).m2(b)...` chain: the receiver of every step is the
        !!! call the step before it built.
        @ExprNode cur_recv = recv;
        if cur_recv == null {
            cur_recv = p_head_ref(s);
        }
        if cur_recv.var_name != null && p_text_eq(cur_recv.var_name, "super") {
            s.is_super = true;
        }
        @ExprNode step_args = null;
        !!! The name every step argument was written with, and where it stands:
        !!! kept per argument, the way the toolchain keeps `step_names`/`step_nl`/... .
        !!! Reading them from the `p_arg_name` fields only after the list was read
        !!! left the name of the *last* argument on every argument, so a call
        !!! written with names in another order (`s.go(b = 2, a = 1)`) came out in
        !!! source order here and reordered in the toolchain.
        @StrNode step_names = null;
        @IntNode step_nl = null;
        @IntNode step_nc = null;
        @IntNode step_nlen = null;
        while true {
            p_adv();
            str method = span_text(p_cur.start, p_cur.stop);
            int mline = p_cur.line;
            int mcol = p_cur.col;
            p_adv();
            !!! The statement is this method call from here on, not the head name: an
            !!! error inside the argument list then reports against the method
            !!! (`out`) instead of looking the receiver (`system`) up as a function.
            s.var_name = method;
            s.var_line = mline;
            s.var_col = mcol;
            s.is_method_call = true;
            p_adv();
            step_args = null;
            step_names = null;
            step_nl = null;
            step_nc = null;
            step_nlen = null;
            if !p_is(TK_RPAREN) {
                p_parse_call_arg();
                if p_arg_expr == null {
                    p_attach_call_args(s, cur_recv, step_args, step_names, step_nl, step_nc, step_nlen);
                    return s;
                }
                step_args = p_chain_expr(step_args, p_arg_expr);
                step_names = p_chain_str(step_names, p_new_name(p_arg_name, p_arg_name_line, p_arg_name_col));
                step_nl = p_chain_int(step_nl, p_new_int(p_arg_name_line));
                step_nc = p_chain_int(step_nc, p_new_int(p_arg_name_col));
                step_nlen = p_chain_int(step_nlen, p_new_int(p_arg_name_len));
                while p_is(TK_COMMA) {
                    p_adv();
                    p_parse_call_arg();
                    if p_arg_expr == null {
                        p_attach_call_args(s, cur_recv, step_args, step_names, step_nl, step_nc, step_nlen);
                        return s;
                    }
                    step_args = p_chain_expr(step_args, p_arg_expr);
                    step_names = p_chain_str(step_names, p_new_name(p_arg_name, p_arg_name_line, p_arg_name_col));
                    step_nl = p_chain_int(step_nl, p_new_int(p_arg_name_line));
                    step_nc = p_chain_int(step_nc, p_new_int(p_arg_name_col));
                    step_nlen = p_chain_int(step_nlen, p_new_int(p_arg_name_len));
                }
            }
            if !p_is(TK_RPAREN) {
                p_error_cur("missing ')'");
                p_attach_call_args(s, cur_recv, step_args, step_names, step_nl, step_nc, step_nlen);
                return s;
            }
            p_adv();
            if p_is(TK_DOT) && p_peek_is(1, TK_IDENT) && p_peek_is(2, TK_LPAREN) {
                @ExprNode inner = p_new_expr(FUNC_CALL);
                inner.line = mline;
                inner.col = mcol;
                inner.var_name = method;
                inner.tok_len = p_text_len(method);
                inner.has_receiver = true;
                inner.result_type = INT;
                inner.args = p_chain_expr(inner.args, cur_recv);
                inner.arg_names = p_chain_str(inner.arg_names, p_new_name("", 0, 0));
                inner.arg_name_lines = p_chain_int(inner.arg_name_lines, p_new_int(0));
                inner.arg_name_cols = p_chain_int(inner.arg_name_cols, p_new_int(0));
                inner.arg_name_lens = p_chain_int(inner.arg_name_lens, p_new_int(0));
                inner.nargs = 1;
                @ExprNode sa = step_args;
                @StrNode sn2 = step_names;
                @IntNode sl2 = step_nl;
                @IntNode sc2 = step_nc;
                @IntNode sk2 = step_nlen;
                while sa != null {
                    !!! The node is taken out of the list it is in before it is
                    !!! appended to the other: appending it while its own link is
                    !!! still set would join the whole rest of the list again, and
                    !!! the second round would walk a chain that runs in a ring.
                    @ExprNode sa_next = sa.next;
                    sa.next = null;
                    @StrNode sn2_next = null;
                    if sn2 != null {
                        sn2_next = sn2.next;
                        sn2.next = null;
                    }
                    @IntNode sl2_next = null;
                    if sl2 != null {
                        sl2_next = sl2.next;
                        sl2.next = null;
                    }
                    @IntNode sc2_next = null;
                    if sc2 != null {
                        sc2_next = sc2.next;
                        sc2.next = null;
                    }
                    @IntNode sk2_next = null;
                    if sk2 != null {
                        sk2_next = sk2.next;
                        sk2.next = null;
                    }
                    inner.args = p_chain_expr(inner.args, sa);
                    inner.arg_names = p_chain_str(inner.arg_names, sn2);
                    inner.arg_name_lines = p_chain_int(inner.arg_name_lines, sl2);
                    inner.arg_name_cols = p_chain_int(inner.arg_name_cols, sc2);
                    inner.arg_name_lens = p_chain_int(inner.arg_name_lens, sk2);
                    inner.nargs = inner.nargs + 1;
                    sa = sa_next;
                    sn2 = sn2_next;
                    sl2 = sl2_next;
                    sc2 = sc2_next;
                    sk2 = sk2_next;
                }
                cur_recv = inner;
                continue;
            }
            !!! The last step: the statement is this call.
            p_attach_call_args(s, cur_recv, step_args, step_names, step_nl, step_nc, step_nlen);
            skip;
        }
        if p_is(TK_SEMI) {
            p_adv();
        } else {
            p_error_prev_sug("missing ';'", ";");
        }
        return s;
    }

    !!! An explicit template instantiation: `name(T1, T2)(args)`.
    bool explicit_targs = p_at_explicit_type_args();
    p_adv();
    if explicit_targs {
        while !p_is(TK_RPAREN) && !p_is(TK_EOF) {
            if p_type_at(p_pos) {
                @TArg t;
                TArg proto;
                malloc(@t, size proto);
                t.ty = p_type();
                t.struct_name = p_last_struct;
                t.is_value = false;
                t.next = null;
                s.targs = p_chain_targ(s.targs, t);
                !!! The type arguments of the call, in the shape the instantiation
                !!! reads (`rgt_expr_at` and `rgt_bool_at`): a type entry carries no
                !!! expression of its own, so it stands as a `null` placeholder. The
                !!! pushes a null pointer into its vector; here the chain has to
                !!! hold a node, or the slot would not exist at all and every value
                !!! argument behind it would sit one place too early.
                s.targ_structs = p_chain_str(s.targ_structs,
                                            p_new_name(p_last_struct, p_cur.line, p_cur.col));
                s.targ_exprs = p_chain_expr(s.targ_exprs, p_new_expr(LIT_NULL));
                s.targ_is_value = p_chain_bool(s.targ_is_value, p_new_bool(false));
            } else {
                !!! A non-type argument: the expression is kept and folded later
                !!! against the parameter's declared type.
                @ExprNode ve = parse_expr(0);
                if ve == null {
                    return s;
                }
                @TArg t2;
                TArg proto2;
                malloc(@t2, size proto2);
                t2.ty = INT;
                t2.struct_name = "";
                t2.is_value = true;
                t2.next = null;
                s.targ_structs = p_chain_str(s.targ_structs, p_new_name("", p_cur.line, p_cur.col));
                s.targ_exprs = p_chain_expr(s.targ_exprs, ve);
                s.targ_is_value = p_chain_bool(s.targ_is_value, p_new_bool(true));
                s.targs = p_chain_targ(s.targs, t2);
            }
            if p_is(TK_COMMA) {
                p_adv();
            } else {
                skip;
            }
        }
        if !p_is(TK_RPAREN) {
            p_error_cur("missing ')' after template type arguments");
            return s;
        }
        p_adv();
        p_adv();
    }

    if !p_is(TK_RPAREN) {
        p_parse_call_arg();
        if p_arg_expr == null {
            return null;
        }
        p_stmt_add_arg(s);
        while p_is(TK_COMMA) {
            p_adv();
            p_parse_call_arg();
            if p_arg_expr == null {
                return null;
            }
            p_stmt_add_arg(s);
        }
    }
    if !p_is(TK_RPAREN) {
        p_error_cur("missing ')'");
        return s;
    }
    p_adv();
    if p_is(TK_SEMI) {
        p_adv();
    } else {
        p_error_prev_sug("missing ';'", ";");
    }
    return s;
}

!!! Step over what is left of an argument list that could not be read.
void p_sync_to_rparen_or_semi {
    while !p_is(TK_EOF) && !p_is(TK_RPAREN) && !p_is(TK_SEMI) {
        p_adv();
    }
    if p_is(TK_RPAREN) {
        p_adv();
    }
    if p_is(TK_SEMI) {
        p_adv();
    }
}
