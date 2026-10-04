#once
!~
 ~  bootstrap/frontend/rgen_freevars.b: the frontend/rgen_freevars.
 ~
 ~  What one lambda body reads and writes outside itself. collect_free_vars_expr
 ~  and collect_free_vars_stmts gather the free variables of a body in the order
 ~  they are met - a lambda literal contributes the variables its own captures name,
 ~  because those reference the enclosing scope - and collect_written_vars_stmts
 ~  gathers the names the body assigns to or increments, which is what decides
 ~  whether an escaping closure needs a heap cell. resolve_body_stmts walks the same
 ~  tree and resolves every expression in it, which is what registers the lambdas
 ~  nested inside a lambda body.
 ~
 ~  the toolchain passes `out` and `seen` down the recursion by reference and the two
 ~  functions share them: collect_free_vars_stmts lends its pair to
 ~  collect_free_vars_expr for every expression it meets. rgen.b gives each function
 ~  the two globals its own out-parameters become, so the outermost
 ~  collect_free_vars_stmts call copies its pair into the expr pair, the walk
 ~  updates the expr pair all the way down, and the pair is copied back at the end.
 ~  `rgx_free_vars_depth` tells a nested stmts call - a descent into one of the
 ~  bodies of the very walk that lent the pair - that there is nothing to lend.
 ~
 ~  A statement body is a chain, and the statements of all the cases of a switch are
 ~  one chain opened by CASE_MARK statements (ast.b): a mark carries nothing to
 ~  collect, so walking the chain reaches exactly the statements the toolchain reaches by
 ~  walking each case's list. A chain never holds a null entry, so the toolchain
 ~  `if (!s) continue;` guard of a body walk has no counterpart here.
 ~!

#head "rgen"

!!! How deep the collect_free_vars_stmts recursion stands: 0 is the call a caller
!!! made, a deeper one is the same walk descending into a body of it, so only the
!!! outermost call lends its pair of globals to the expression walk and takes it
!!! back.
int rgx_free_vars_depth = 0;

!!! The free variables of one expression, in the order they are met. The answer
!!! text goes to rg_collect_free_vars_expr_out and the names already collected to
!!! rg_collect_free_vars_expr_out_seen, the two out-parameters of the toolchain.
void rg_collect_free_vars_expr -> @ExprNode e {
    if e == null {
        end;
    }
    if e.nk == VAR_REF {
        if !rg_set_has(rg_collect_free_vars_expr_out_seen, e.var_name) {
            rg_collect_free_vars_expr_out_seen =
                rg_set_add(rg_collect_free_vars_expr_out_seen, e.var_name);
            rg_collect_free_vars_expr_out =
                rg_strchain_append(rg_collect_free_vars_expr_out, e.var_name);
        }
        end;
    }
    if e.nk == LAMBDA {
        !!! A nested lambda's captures reference the enclosing scope, so they become
        !!! free variables of the enclosing lambda as well.
        @LambdaRec lr = p_find_lambda(e.lambda_id);
        if lr != null {
            @StrNode c = lr.captures;
            while c != null {
                if !rg_set_has(rg_collect_free_vars_expr_out_seen, c.s) {
                    rg_collect_free_vars_expr_out_seen =
                        rg_set_add(rg_collect_free_vars_expr_out_seen, c.s);
                    rg_collect_free_vars_expr_out =
                        rg_strchain_append(rg_collect_free_vars_expr_out, c.s);
                }
                c = c.next;
            }
            @ExprNode a = lr.immediate_args;
            while a != null {
                rg_collect_free_vars_expr(a);
                a = a.next;
            }
        }
        end;
    }
    rg_collect_free_vars_expr(e.left);
    rg_collect_free_vars_expr(e.right);
    @ExprNode a1 = e.args;
    while a1 != null {
        rg_collect_free_vars_expr(a1);
        a1 = a1.next;
    }
    @ExprNode a2 = e.indices;
    while a2 != null {
        rg_collect_free_vars_expr(a2);
        a2 = a2.next;
    }
    !!! The immediate arguments of a lambda literal are read in the LAMBDA arm above,
    !!! where the record that holds them is looked up: the toolchain field is empty on
    !!! every other node, and the pieces of a literal live in its LambdaRec here.
}

!!! The free variables of a statement body. The answer goes to
!!! rg_collect_free_vars_stmts_out and rg_collect_free_vars_stmts_out_seen; the
!!! walk lends that pair to the expression walk while it runs.
void rg_collect_free_vars_stmts -> @StmtNode body {
    bool outermost = false;
    if rgx_free_vars_depth == 0 {
        outermost = true;
    }
    if outermost {
        rg_collect_free_vars_expr_out = rg_collect_free_vars_stmts_out;
        rg_collect_free_vars_expr_out_seen = rg_collect_free_vars_stmts_out_seen;
    }
    rgx_free_vars_depth = rgx_free_vars_depth + 1;
    @StmtNode s = body;
    while s != null {
        rg_collect_free_vars_expr(s.expr);
        @ExprNode a = s.args;
        while a != null {
            rg_collect_free_vars_expr(a);
            a = a.next;
        }
        @ExprNode ai = s.array_init;
        while ai != null {
            rg_collect_free_vars_expr(ai);
            ai = ai.next;
        }
        rg_collect_free_vars_expr(s.array_len_expr);
        @ExprNode d = s.fparam_defaults;
        while d != null {
            rg_collect_free_vars_expr(d);
            d = d.next;
        }
        rg_collect_free_vars_stmts(s.true_body);
        rg_collect_free_vars_stmts(s.false_body);
        @ExprNode ce = s.case_exprs;
        while ce != null {
            rg_collect_free_vars_expr(ce);
            ce = ce.next;
        }
        rg_collect_free_vars_stmts(s.case_bodies);
        rg_collect_free_vars_stmts(s.unmatch_body);
        s = s.next;
    }
    rgx_free_vars_depth = rgx_free_vars_depth - 1;
    if outermost {
        rg_collect_free_vars_stmts_out = rg_collect_free_vars_expr_out;
        rg_collect_free_vars_stmts_out_seen = rg_collect_free_vars_expr_out_seen;
    }
}

!!! Resolve every expression of a statement body: the statement's own expression,
!!! its arguments, its initializer, its array length, its parameter defaults, the
!!! expressions of its cases, and the same for every body inside it. A nested lambda
!!! literal is registered by this, because resolving the expression that is the
!!! literal is what calls resolve_lambda.
void rg_resolve_body_stmts -> @StmtNode body {
    @StmtNode s = body;
    while s != null {
        if s.expr != null {
            rg_resolve_expr_type(s.expr);
        }
        @ExprNode a = s.args;
        while a != null {
            rg_resolve_expr_type(a);
            a = a.next;
        }
        @ExprNode ai = s.array_init;
        while ai != null {
            rg_resolve_expr_type(ai);
            ai = ai.next;
        }
        if s.array_len_expr != null {
            rg_resolve_expr_type(s.array_len_expr);
        }
        @ExprNode d = s.fparam_defaults;
        while d != null {
            rg_resolve_expr_type(d);
            d = d.next;
        }
        rg_resolve_body_stmts(s.true_body);
        rg_resolve_body_stmts(s.false_body);
        @ExprNode ce = s.case_exprs;
        while ce != null {
            rg_resolve_expr_type(ce);
            ce = ce.next;
        }
        rg_resolve_body_stmts(s.case_bodies);
        rg_resolve_body_stmts(s.unmatch_body);
        s = s.next;
    }
}

!!! The names a statement body writes: the target of a plain assignment (not a
!!! field write and not an array element) and the target of an increment. The names
!!! land in rg_collect_written_vars_stmts_out, the toolchain out-parameter.
void rg_collect_written_vars_stmts -> @StmtNode body {
    @StmtNode s = body;
    while s != null {
        if s.nk == ASSIGN && s.member_name == "" && !s.is_array {
            rg_collect_written_vars_stmts_out =
                rg_set_add(rg_collect_written_vars_stmts_out, s.var_name);
        } else if s.nk == INCR {
            rg_collect_written_vars_stmts_out =
                rg_set_add(rg_collect_written_vars_stmts_out, s.var_name);
        }
        rg_collect_written_vars_stmts(s.true_body);
        rg_collect_written_vars_stmts(s.false_body);
        rg_collect_written_vars_stmts(s.case_bodies);
        rg_collect_written_vars_stmts(s.unmatch_body);
        s = s.next;
    }
}
