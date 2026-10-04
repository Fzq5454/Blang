#once
!~
 ~  bootstrap/frontend/rgen_lambda.b: the frontend/rgen_lambda.
 ~
 ~  What a lambda literal becomes: a hidden `__lambda_N` function whose parameters
 ~  are the captures followed by the lambda's own parameters, and whose body is the
 ~  literal's body. resolve_lambda
 ~   * infers the closure's return type from the first `back`/`return` of the body,
 ~   * resolves the body, which is what registers the lambda literals nested in it,
 ~   * pushes the lambda's parameters into the symbol tables - and into the
 ~     declaration table of the body being checked - so the body resolves them,
 ~   * collects the free variables of the body and keeps the ones that are neither a
 ~     parameter of the lambda, nor a function name, nor a non-global symbol: those
 ~     are the captures,
 ~   * decides which capture needs a mutable heap cell: an immediate-call lambda
 ~     captures every variable by reference, an escaping one only what its body
 ~     writes,
 ~   * restores the symbols and the declaration table it shadowed,
 ~   * registers the hidden function's signature (arity, parameter types, parameter
 ~     names, not variadic) under the hidden name, and
 ~   * queues the literal in _lambdas so the emit pass writes the function, and
 ~     gives the literal its result type (FUNC, or the inferred type when the
 ~     literal is called on the spot).
 ~
 ~  A literal is recognized again by the id its node carries: the pieces of every
 ~  literal (parameters, body, captures, immediate arguments) live in a LambdaRec
 ~  reached through p_find_lambda, because the language cannot compare two node
 ~  addresses - the `if (l == n)` that keeps a lambda from being resolved twice
 ~  is a test of the lambda id here.
 ~
 ~  the toolchain also fills a `decl_added` vector in the push loop that nothing ever
 ~  reads; it has no counterpart.
 ~
 ~  The three walkers at the end reach the lambda literals of a body no resolve pass
 ~  walks. A struct method body is not part of the statement list, so a literal
 ~  written in it never reached resolve_expr_type and stayed unregistered: the
 ~  closure was emitted as `(CLOSURE )` with no function name at all. They walk such
 ~  a body for lambda literals only; the rest of the body keeps the treatment it had
 ~  before. A body is walked as a chain through `next`.
 ~!

#head "rgen"

!!! Resolve one lambda literal, and answer false only when its body could not be
!!! resolved - or when the node carries no LambdaRec at all, which the parser never
!!! produces, so that a broken literal stays unresolved instead of being taken for
!!! an empty one.
bool rg_resolve_lambda -> @ExprNode n {
    !!! Avoid re-resolving the same lambda (it may be visited by multiple
    !!! type-check passes), which would duplicate the hidden function.
    @RgExprRef l = rg_lambdas;
    while l != null {
        if l.e != null && l.e.lambda_id == n.lambda_id {
            return true;
        }
        l = l.next;
    }
    @LambdaRec rec = p_find_lambda(n.lambda_id);
    if rec == null {
        return false;
    }
    str fname = "__lambda_" + (str)n.lambda_id;
    n.var_name = fname;

    !!! Push lambda params into scope so body references resolve to them. Mark them
    !!! non-global so nested lambdas can capture them. They join the declaration
    !!! table of the body they are written in, so a parameter that shadows an outer
    !!! name of the same body resolves to the parameter.
    @RgVarTypeMap saved = null;
    @RgStrSet added_non_global = null;
    @RgVarDeclMap saved_decls = null;
    @StrNode p = rec.params;
    @VarTypeNode ptin = rec.param_types;
    @BoolNode pain = rec.param_is_array;
    while p != null {
        str pname = p.s;
        @RgVarTypeMap old = rg_vartypemap_find(rg_syms, pname);
        if old != null {
            saved = rg_vartypemap_set(saved, pname, old.ty);
        }
        VarType pty = INT;
        if ptin != null {
            pty = ptin.ty;
        }
        rg_syms = rg_vartypemap_set(rg_syms, pname, pty);
        if !rg_set_has(rg_non_global_syms, pname) {
            rg_non_global_syms = rg_set_add(rg_non_global_syms, pname);
            added_non_global = rg_set_add(added_non_global, pname);
        }
        if rg_in_func_body {
            @RgVarDeclMap dit = rg_vardeclmap_find(rg_local_decls, pname);
            if dit != null {
                saved_decls = rg_vardeclmap_set(saved_decls, pname, dit.decl);
            }
            !!! `VarDecl d;` of the toolchain: every field is written out, because the
            !!! block `malloc` hands out is only read as what was put there.
            VarDecl proto;
            @VarDecl d;
            malloc(@d, size proto);
            d.ty = pty;
            d.ptr_depth = 0;
            d.struct_type = "";
            d.struct_ptr = false;
            d.is_array = false;
            if pain != null {
                d.is_array = pain.v;
            }
            d.is_ref = false;
            d.is_unsigned = false;
            d.dims = null;
            d.n = 0;
            d.len_expr = null;
            rg_local_decls = rg_vardeclmap_set(rg_local_decls, pname, d);
        }
        p = p.next;
        if ptin != null {
            ptin = ptin.next;
        }
        if pain != null {
            pain = pain.next;
        }
    }

    !!! Infer return type from the first return statement. Both spellings are
    !!! accepted: `back` and `return` are the same statement to the emitter, and
    !!! looking only for `back` typed every `return`-based lambda as VOID (so
    !!! `float h = half(3.0);` was rejected and a float result was read from the
    !!! integer register).
    VarType ret = VOID;
    @StmtNode bs = rec.body;
    while bs != null {
        if bs.nk == BACK || bs.nk == RETURN {
            if bs.expr != null {
                if rg_resolve_expr_type(bs.expr) {
                    ret = bs.expr.result_type;
                }
            } else {
                ret = VOID;
            }
            skip;
        }
        bs = bs.next;
    }
    rec.ret_type = ret;

    !!! Resolve all body expressions (this resolves nested lambdas too).
    rg_resolve_body_stmts(rec.body);

    !!! Compute captures: free vars that are non-global and not lambda params. The
    !!! hands the two containers down the recursion; here
    !!! rg_collect_free_vars_stmts keeps its answer in the globals rgen.b declared
    !!! for it, so they are emptied before the walk and read right after it.
    rg_collect_free_vars_stmts_out = null;
    rg_collect_free_vars_stmts_out_seen = null;
    rg_collect_free_vars_stmts(rec.body);
    @StrNode frees = rg_collect_free_vars_stmts_out;
    @RgStrSet params = null;
    @StrNode pp = rec.params;
    while pp != null {
        params = rg_set_add(params, pp.s);
        pp = pp.next;
    }
    @StrNode caps = null;
    @StrNode fv = frees;
    while fv != null {
        str fvn = fv.s;
        bool take = true;
        if rg_set_has(params, fvn) {
            take = false;
        }
        !!! A function name used as a value: the error is reported elsewhere.
        if rg_intmap_find(rg_func_arity, fvn) != null {
            take = false;
        }
        if take && rg_set_has(rg_non_global_syms, fvn) {
            caps = rg_strchain_append(caps, fvn);
        }
        fv = fv.next;
    }
    rec.captures = caps;

    !!! Decide which captures need a mutable heap cell. Immediate-call lambdas
    !!! capture every variable by reference; escaping closures only capture a
    !!! variable by cell when it is written inside the body.
    rg_collect_written_vars_stmts_out = null;
    rg_collect_written_vars_stmts(rec.body);
    @RgStrSet written = rg_collect_written_vars_stmts_out;
    rec.capture_by_ref = null;
    @StrNode cp = caps;
    while cp != null {
        bool byref = rec.immediate;
        if rg_set_has(written, cp.s) {
            byref = true;
        }
        rec.capture_by_ref = rg_boolchain_append(rec.capture_by_ref, byref);
        cp = cp.next;
    }

    !!! Restore shadowed symbols and non-global markers.
    @StrNode p2 = rec.params;
    while p2 != null {
        str rn = p2.s;
        @RgVarTypeMap old2 = rg_vartypemap_find(saved, rn);
        if old2 != null {
            rg_syms = rg_vartypemap_set(rg_syms, rn, old2.ty);
        } else {
            rg_syms = rg_vartypemap_drop(rg_syms, rn);
        }
        if rg_set_has(added_non_global, rn) {
            rg_non_global_syms = rg_set_drop(rg_non_global_syms, rn);
        }
        p2 = p2.next;
    }
    !!! ... and the body's declaration table, so a lambda parameter does not stay in
    !!! scope after the lambda it belongs to.
    if rg_in_func_body {
        @StrNode p3 = rec.params;
        while p3 != null {
            str rn2 = p3.s;
            @RgVarDeclMap sit = rg_vardeclmap_find(saved_decls, rn2);
            if sit != null {
                rg_local_decls = rg_vardeclmap_set(rg_local_decls, rn2, sit.decl);
            } else {
                !!! `_local_decls.erase(p)`: rgen.b has a drop for the map tables and
                !!! none for the declaration table, so the record is unlinked here.
                @RgVarDeclMap prev = null;
                @RgVarDeclMap cnode = rg_local_decls;
                while cnode != null && !p_text_eq(cnode.key, rn2) {
                    prev = cnode;
                    cnode = cnode.next;
                }
                if cnode != null {
                    if prev == null {
                        rg_local_decls = cnode.next;
                    } else {
                        prev.next = cnode.next;
                    }
                }
            }
            p3 = p3.next;
        }
    }

    !!! Resolve immediate-call arguments (=> args) against the enclosing scope.
    @ExprNode ia = rec.immediate_args;
    while ia != null {
        if !rg_resolve_expr_type(ia) {
            return false;
        }
        ia = ia.next;
    }

    !!! Build the hidden function signature: the captures first (by reference - an
    !!! address - or by value), then the lambda's own parameters.
    @VarTypeNode pt = null;
    @StrNode pn = null;
    int ptn = 0;
    int pnn = 0;
    @StrNode cap = caps;
    @BoolNode cbr = rec.capture_by_ref;
    int ci = 0;
    while cap != null {
        VarType ct = INT;
        @RgVarTypeMap sm = rg_vartypemap_find(rg_syms, cap.s);
        if sm != null {
            ct = sm.ty;
        }
        rec.capture_types = rg_vartypechain_append(rec.capture_types, ct);
        pn = rg_strchain_append(pn, "__cap_" + (str)ci);
        pnn = pnn + 1;
        bool byref = rec.immediate;
        if cbr != null {
            byref = cbr.v;
        }
        if byref {
            pt = rg_vartypechain_append(pt, rg_at_of(ct));
        } else {
            pt = rg_vartypechain_append(pt, ct);
        }
        ptn = ptn + 1;
        cap = cap.next;
        if cbr != null {
            cbr = cbr.next;
        }
        ci = ci + 1;
    }
    @StrNode lp = rec.params;
    @VarTypeNode lpt = rec.param_types;
    while lp != null {
        VarType lpty = INT;
        if lpt != null {
            lpty = lpt.ty;
        }
        pt = rg_vartypechain_append(pt, lpty);
        pn = rg_strchain_append(pn, lp.s);
        ptn = ptn + 1;
        pnn = pnn + 1;
        lp = lp.next;
        if lpt != null {
            lpt = lpt.next;
        }
    }
    rg_func_arity = rg_intmap_set(rg_func_arity, fname, ptn);
    rg_func_param_types = rg_vartypelistmap_set(rg_func_param_types, fname, pt, ptn);
    rg_func_param_names = rg_strlistmap_set(rg_func_param_names, fname, pn, pnn);
    rg_func_variadic = rg_boolmap_set(rg_func_variadic, fname, false);

    rg_lambdas = rg_exprref_append(rg_lambdas, n);

    if rec.immediate {
        n.result_type = ret;
    } else {
        n.result_type = FUNC;
    }
    return true;
}

!!! lambda literals in a body no resolve pass walks

void rg_resolve_body_lambdas -> @StmtNode body {
    @StmtNode s = body;
    while s != null {
        rg_resolve_stmt_lambdas(s);
        s = s.next;
    }
}

void rg_resolve_stmt_lambdas -> @StmtNode s {
    if s == null {
        end;
    }
    rg_resolve_expr_lambdas(s.expr);
    @ExprNode a = s.args;
    while a != null {
        rg_resolve_expr_lambdas(a);
        a = a.next;
    }
    @ExprNode ai = s.array_init;
    while ai != null {
        rg_resolve_expr_lambdas(ai);
        ai = ai.next;
    }
    rg_resolve_expr_lambdas(s.array_len_expr);
    @ExprNode d = s.fparam_defaults;
    while d != null {
        rg_resolve_expr_lambdas(d);
        d = d.next;
    }
    @ExprNode ce = s.case_exprs;
    while ce != null {
        rg_resolve_expr_lambdas(ce);
        ce = ce.next;
    }
    rg_resolve_body_lambdas(s.true_body);
    rg_resolve_body_lambdas(s.false_body);
    rg_resolve_body_lambdas(s.case_bodies);
    rg_resolve_body_lambdas(s.unmatch_body);
}

void rg_resolve_expr_lambdas -> @ExprNode e {
    if e == null {
        end;
    }
    if e.nk == LAMBDA {
        !!! resolve_lambda() also resolves the body, so a lambda nested in a lambda
        !!! is registered here as well.
        rg_resolve_lambda(e);
        end;
    }
    rg_resolve_expr_lambdas(e.left);
    rg_resolve_expr_lambdas(e.right);
    @ExprNode a = e.args;
    while a != null {
        rg_resolve_expr_lambdas(a);
        a = a.next;
    }
    @ExprNode ix = e.indices;
    while ix != null {
        rg_resolve_expr_lambdas(ix);
        ix = ix.next;
    }
    !!! The `lambda_immediate_args` are read in its LAMBDA arm and inside
    !!! resolve_lambda; the field is empty on every other node.
}
