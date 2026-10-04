#once
!~
 ~  bootstrap/frontend/rgen_rewrite_forward.b: this implementation of
 ~  the pass that turns a bare reference to the
 ~  builtin of a wrapper function into a call forwarding that function's own
 ~  parameters.
 ~
 ~  `function <built-in> F -> ... { ... }` declares F as a wrapper of the builtin: a
 ~  plain `<built-in>` written in the body is not a value, it means "call the
 ~  builtin with F's parameters". The reference is rebuilt as a FUNC_CALL whose
 ~  arguments are F's parameter names, and the node keeps its address - which is
 ~  what the toolchain gets from `*n = *call`. Here a whole record assigned through a
 ~  pointer copies only its first leaf, so the fields are written one at a time.
 ~
 ~  this implementation's statement bodies are the chain in `true_body`: the toolchain keeps a
 ~  PACKAGE statement's members in `children`, which parser_package.b puts in
 ~  `true_body`, and a function body is `true_body` in both.
 ~!

#head "rgen"

!!! One VAR_REF per parameter name, in order: the arguments the rebuilt call
!!! forwards.
@ExprNode rg_forward_args -> @StrNode params, int line, int col {
    @ExprNode args = null;
    @StrNode p = params;
    while p != null {
        @ExprNode a = p_new_expr(VAR_REF);
        a.var_name = p.s;
        a.line = line;
        a.col = col;
        args = p_chain_expr(args, a);
        p = p.next;
    }
    return args;
}

void rg_rewrite_forward_expr -> @ExprNode n, str annot, @StrNode params {
    if n == null {
        end;
    }
    if n.nk == VAR_REF && p_text_eq(n.var_name, annot) {
        int line = n.line;
        int col = n.col;
        @ExprNode args = rg_forward_args(params, line, col);
        int nargs = 0;
        @ExprNode a = args;
        while a != null {
            nargs = nargs + 1;
            a = a.next;
        }
        n.nk = FUNC_CALL;
        n.var_name = annot;
        n.args = args;
        n.nargs = nargs;
        n.left = null;
        n.right = null;
        end;
    }
    rg_rewrite_forward_expr(n.left, annot, params);
    rg_rewrite_forward_expr(n.right, annot, params);
    @ExprNode a2 = n.args;
    while a2 != null {
        rg_rewrite_forward_expr(a2, annot, params);
        a2 = a2.next;
    }
    @ExprNode ix = n.indices;
    while ix != null {
        rg_rewrite_forward_expr(ix, annot, params);
        ix = ix.next;
    }
    !!! The immediate arguments of a lambda literal: the toolchain keeps them on the
    !!! expression node, this implementation in the literal's own record.
    if n.nk == LAMBDA {
        @LambdaRec rec = p_find_lambda(n.lambda_id);
        if rec != null {
            @ExprNode ia = rec.immediate_args;
            while ia != null {
                rg_rewrite_forward_expr(ia, annot, params);
                ia = ia.next;
            }
        }
    }
}

void rg_rewrite_forward_stmt -> @StmtNode s, str annot, @StrNode params {
    if s == null {
        end;
    }
    rg_rewrite_forward_expr(s.expr, annot, params);
    rg_rewrite_forward_expr(s.array_len_expr, annot, params);
    @ExprNode a = s.args;
    while a != null {
        rg_rewrite_forward_expr(a, annot, params);
        a = a.next;
    }
    @ExprNode i = s.array_init;
    while i != null {
        rg_rewrite_forward_expr(i, annot, params);
        i = i.next;
    }
    @ExprNode c = s.case_exprs;
    while c != null {
        rg_rewrite_forward_expr(c, annot, params);
        c = c.next;
    }
    @ExprNode d = s.fparam_defaults;
    while d != null {
        rg_rewrite_forward_expr(d, annot, params);
        d = d.next;
    }
    @StmtNode t = s.true_body;
    while t != null {
        rg_rewrite_forward_stmt(t, annot, params);
        t = t.next;
    }
    @StmtNode f = s.false_body;
    while f != null {
        rg_rewrite_forward_stmt(f, annot, params);
        f = f.next;
    }
    @StmtNode cb = s.case_bodies;
    while cb != null {
        rg_rewrite_forward_stmt(cb, annot, params);
        cb = cb.next;
    }
    @StmtNode u = s.unmatch_body;
    while u != null {
        rg_rewrite_forward_stmt(u, annot, params);
        u = u.next;
    }
}

!!! Every function declared with a builtin annotation: the body of each one is
!!! rewritten, so the builtin reference inside it becomes the forwarding call.
void rg_rewrite_builtin_forward -> @StmtNode stmts {
    @StmtNode s = stmts;
    while s != null {
        if s.nk == FUNCTION && !s.broken && s.builtin_annotation != "" {
            rg_rewrite_forward_stmt(s, s.builtin_annotation, s.fparams);
        }
        s = s.next;
    }
}
