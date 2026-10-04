#once
!~
 ~  bootstrap/frontend/rgen_emit.b: the frontend/rgen_emit.
 ~
 ~  The third pass: the .r text itself. Everything the passes before it decided is
 ~  written out here, in the order the back end needs to read it.
 ~
 ~  the toolchain takes the per-statement action as a lambda (`emit_new_lambdas`) and
 ~  sort()s `_lambdas` by `lambda_id` in place; the language has neither, so
 ~  the round is the three `rgx_` helpers below: the sort is an ordered rebuild of
 ~  the chain (each node is detached and inserted where its id belongs, so the
 ~  result is the descending order the toolchain comparator asks for), and lambda identity
 ~  is the id the node carries rather than its address, because two struct pointers
 ~  cannot be compared (see the note on RgExprRef in rgen_heads.b). The chain is
 ~  rebuilt in `rg_lambdas` itself, so the second round sees the same order the
 ~  first one left, exactly as the `_lambdas` does.
 ~!

#head "rgen"
#head "rgen_heads"

!!! One node of a lambda chain, put where it belongs in a chain sorted by
!!! descending `lambda_id`. The caller has already detached it (`next` is null).
@RgExprRef rgx_lambda_insert -> @RgExprRef sorted, @RgExprRef node {
    if sorted == null {
        return node;
    }
    @ExprNode ne = node.e;
    @ExprNode se = sorted.e;
    if ne.lambda_id > se.lambda_id {
        node.next = sorted;
        return node;
    }
    @RgExprRef prev = sorted;
    while prev.next != null {
        @ExprNode pe = prev.next.e;
        if pe.lambda_id <= ne.lambda_id {
            skip;
        }
        prev = prev.next;
    }
    node.next = prev.next;
    prev.next = node;
    return sorted;
}

!!! sort(_lambdas.begin(), _lambdas.end(), [](a, b) { return a->lambda_id >
!!! b->lambda_id; }): the same descending order, built by inserting every node of
!!! the chain into an ordered one. A node already linked to the rest of the chain is
!!! detached first, so the insert owns the link it writes.
@RgExprRef rgx_sort_lambdas -> @RgExprRef head {
    @RgExprRef sorted = null;
    @RgExprRef cnode = head;
    while cnode != null {
        @RgExprRef nx = cnode.next;
        cnode.next = null;
        sorted = rgx_lambda_insert(sorted, cnode);
        cnode = nx;
    }
    return sorted;
}

!!! The `emit_new_lambdas` lambda round: sort `_lambdas`, then emit every
!!! lambda that has not been emitted yet. `emitted` is the set of lambda ids already
!!! written - the toolchain keeps the node pointers, this implementation keeps the id each node
!!! carries, because that is what tells two nodes apart here. The possibly-new set
!!! is answered back, since the toolchain lambda captured its caller's set by reference.
@RgStrSet rgx_emit_new_lambdas -> @RgStrSet emitted {
    rg_lambdas = rgx_sort_lambdas(rg_lambdas);
    @RgExprRef l = rg_lambdas;
    while l != null {
        @ExprNode le = l.e;
        !!! The record carries whether this literal's hidden function was written.
        !!! the toolchain asks its set of emitted nodes; asking it by the id as text went
        !!! through the conversion ring, and the text of a key was overwritten by
        !!! the next conversion the emission itself ran - so the second round emitted
        !!! the same literal again.
        @LambdaRec rec = p_find_lambda(le.lambda_id);
        if rec != null && !rec.emitted {
            rec.emitted = true;
            rg_gen_lambda_function(le);
        }
        l = l.next;
    }
    return emitted;
}

!!! emit_r_code: the statements of the program, in the order the back end resolves
!!! them. The public .r FUNCs of the builtins come first, then the hidden lambda
!!! functions - deeper (nested) ones before their enclosing one, so a nested
!!! closure's name is already registered when the enclosing body references it.
!!! ENUMs are emitted before every other statement, then the rest; lambdas
!!! discovered while those were emitted (an `any` argument of a builtin call is
!!! resolved as it is emitted, so a lambda literal can appear then) are picked up by
!!! a second round. A later definition is fine: the back end knows every FUNC
!!! signature before it generates a body, so a name used before its definition is
!!! patched afterwards.
void rg_emit_r_code {
    int t = time_now();
    rg_emit_builtin_runtime();
    time_print("    builtin runtime", time_now() - t);

    t = time_now();
    @RgStrSet emitted_lambdas = null;
    emitted_lambdas = rgx_emit_new_lambdas(emitted_lambdas);

    @StmtNode s = rg_stmts;
    while s != null {
        if s.nk == ENUM {
            rg_gen_stmt(s);
        }
        s = s.next;
    }
    time_print("    lambdas and enums", time_now() - t);

    t = time_now();
    s = rg_stmts;
    while s != null {
        if s.nk != ENUM {
            rg_gen_stmt(s);
        }
        s = s.next;
    }
    time_print("    statements", time_now() - t);

    t = time_now();
    emitted_lambdas = rgx_emit_new_lambdas(emitted_lambdas);
    time_print("    late lambdas", time_now() - t);

    !!! The unused-variable/function warnings (-W-nused).
    t = time_now();
    rg_check_unused();
    time_print("    unused check", time_now() - t);

    !!! Flush the deferred rimp notes, after all warnings.
    t = time_now();
    @RgStrMap kv = rg_rimp_deferred;
    while kv != null {
        rg_notes = rg_notes + kv.v;
        kv = kv.next;
    }
    time_print("    notes", time_now() - t);

    !!! The two numbers are counts and not milliseconds, so they do not go through
    !!! time_print: what a stage costs is not only how long it took but how many of
    !!! the operations it is made of were done.
    if g_time_on {
        system.err("[count] effective_var_decl calls: ", g_n_effdecl, "\n");
        system.err("[count] pe_sub calls: ", g_n_pesub, "\n");
        system.err("[count] pe_len calls: ", g_n_pelen, "\n");
        system.err("[count] text_eq calls: ", g_n_texteq, "\n");
        system.err("[count] hash calls: ", g_n_hash, "\n");
        system.err("[count] map lookups: set=", g_n_set_has, " str=", g_n_strmap_find,
                   " bool=", g_n_boolmap_find, " vartype=", g_n_vartypemap_find, "\n");
        system.err("[count] chain nodes walked: ", g_n_chain_nodes, "\n");
        system.err("[count] text_text calls: ", g_n_txttext, "\n");
        system.err("[count] p_find_struct calls: ", g_n_findstruct, "\n");
        system.err("[count] p_find_template calls: ", g_n_findtpl, "\n");
        system.err("[count] p_find_template_func calls: ", g_n_findtplfunc, "\n");
        system.err("[count] p_in_str_chain calls: ", g_n_instrchain, "\n");
        system.err("[count] p_adv calls: ", g_n_adv, "\n");
        system.err("[count] p_is calls: ", g_n_is, "\n");
        system.err("[count] p_expect calls: ", g_n_expect, "\n");
        system.err("[count] p_tok calls: ", g_n_tok, "\n");
        system.err("[count] p_name_is calls: ", g_n_nameis, "\n");
    }
}
