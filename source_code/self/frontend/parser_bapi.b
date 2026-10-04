#once
!~
 ~  bootstrap/frontend/parser_bapi.b: the frontend/parser_bapi.
 ~
 ~  `BLANG_API int memory -> @void addr { __badd(addr); __bcall("_memory"); __bfree(); }`
 ~  is how the compiler is told what a function of a linked DLL is: the body names
 ~  the target the call goes to (__bcall), the parameters it is handed in order
 ~  (__badd), and when those parameters are given back (__bfree). The body produces
 ~  no code of its own - the BAPI statement is what the generator reads.
 ~
 ~  `__get_built_in_func<name> alias;` binds an alias to one of the compiler's own
 ~  builtins, which is the other half of this file in the toolchain version.
 ~!

#head "parser"

@StmtNode p_bapi_body -> @StmtNode s {
    if !p_is(TK_LBRACE) {
        p_error_cur("missing '{'");
        return s;
    }
    p_adv();
    !!! The names __badd has collected since the last __bfree, in order. the toolchain
    !!! parser keeps them in a a chain and copies it into each call segment; here
    !!! the list is a chain and each segment is given its own copy, so a directive
    !!! added later cannot change a call that was already written.
    @StrNode pending = null;
    while !p_is(TK_RBRACE) && !p_is(TK_EOF) {
        if p_is_kw("__badd") {
            p_adv();
            if !p_is(TK_LPAREN) {
                p_error_cur("missing '('");
                skip;
            }
            p_adv();
            @ExprNode arg = parse_expr(0);
            if arg == null {
                skip;
            }
            if arg.nk != VAR_REF {
                p_error_cur("__badd needs a parameter name");
                skip;
            }
            pending = p_chain_str(pending, p_new_name(arg.var_name, arg.line, arg.col));
            if !p_is(TK_RPAREN) {
                p_error_cur("missing ')'");
                skip;
            }
            p_adv();
            if p_is(TK_SEMI) {
                p_adv();
            }
            continue;
        }
        if p_is_kw("__bcall") {
            p_adv();
            if !p_is(TK_LPAREN) {
                p_error_cur("missing '('");
                skip;
            }
            p_adv();
            if !p_is(TK_STRING) {
                p_error_cur("missing string literal");
                skip;
            }
            BapiCallSeg proto;
            @BapiCallSeg seg;
            malloc(@seg, size proto);
            !!! The literal without its quotes: the token keeps the span the quotes are
            !!! part of.
            seg.target = span_text(p_cur.start + 1, p_cur.stop - 1);
            seg.arg_names = p_copy_str_chain(pending);
            seg.next = null;
            s.bapi_segs = p_chain_seg(s.bapi_segs, seg);
            s.call_target = seg.target;
            if !p_has_bcall(seg.target) {
                p_bcall_targets.add(seg.target);
                p_bcall_targets_h.add(rgx_lk_hash(seg.target));
            }
            p_adv();
            if !p_is(TK_RPAREN) {
                p_error_cur("missing ')'");
                skip;
            }
            p_adv();
            if p_is(TK_SEMI) {
                p_adv();
            }
            continue;
        }
        if p_is_kw("__bfree") {
            p_adv();
            if p_is(TK_LPAREN) {
                p_adv();
                if !p_is(TK_RPAREN) {
                    p_error_cur("missing ')'");
                    skip;
                }
                p_adv();
            }
            if p_is(TK_SEMI) {
                p_adv();
            }
            !!! The parameters named so far are released: the next __bcall starts a
            !!! new list.
            pending = null;
            continue;
        }
        !!! the toolchain writes this one with `add_error` at the current token, underlining
        !!! the token itself, which does not resync; every other message of the file
        !!! goes through error_at_cur.
        p_error_at(p_cur.line, p_cur.col, p_cur.stop - p_cur.start,
                   "meaningless token '" + span_text(p_cur.start, p_cur.stop) +
                   "' in BLANG_API");
        while !p_is(TK_RBRACE) && !p_is(TK_EOF) {
            p_adv();
        }
        skip;
    }
    if !p_is(TK_RBRACE) {
        p_error_cur("missing '}'");
        return s;
    }
    p_adv();
    return s;
}

@StmtNode p_bapi {
    @StmtNode s = p_new_stmt(BAPI);
    p_adv();
    !!! The return type, and then the name. The API function name may be written as
    !!! a keyword (`in`, `out`, `err`): the language's own words are the names of the
    !!! runtime's, so both are accepted here.
    s.func_ret_type = p_type();
    s.ret_struct = p_last_struct;
    s.ret_ptr_depth = p_last_ptr_depth;
    if !p_is(TK_IDENT) && !p_is(TK_KEYWORD) {
        p_error_cur("missing API function name");
        return s;
    }
    s.var_name = span_text(p_cur.start, p_cur.stop);
    s.var_line = p_cur.line;
    s.var_col = p_cur.col;
    p_adv();

    !!! `-> type name, type name, ...`.
    if p_is(TK_MINUS) && p_peek_is(1, TK_GT) {
        p_adv();
        p_adv();
        while !p_is(TK_LBRACE) && !p_is(TK_EOF) {
            VarType pt = p_type();
            str psn = p_last_struct;
            if !p_is(TK_IDENT) {
                p_error_cur("missing parameter name");
                return s;
            }
            s.fparam_types = p_chain_type(s.fparam_types, p_new_type(pt));
            s.fparam_struct = p_chain_str(s.fparam_struct, p_new_name(psn, p_cur.line, p_cur.col));
            s.fparams = p_chain_str(s.fparams,
                                    p_new_span(p_cur.start, p_cur.stop, p_cur.line, p_cur.col));
            s.nfparams = s.nfparams + 1;
            p_adv();
            !!! A default value has to be a constant expression.
            if p_take(TK_ASSIGN) {
                s.fparam_defaults = p_chain_expr(s.fparam_defaults, parse_expr(0));
                s.fparam_has_default = p_chain_bool(s.fparam_has_default, p_new_bool(true));
            } else {
                s.fparam_has_default = p_chain_bool(s.fparam_has_default, p_new_bool(false));
            }
            if p_is(TK_ELLIPSIS) {
                s.variadic = true;
                p_set_last_bool(s.fparam_is_array, true);
                p_adv();
            }
            if p_take(TK_COMMA) {
                continue;
            }
        }
    }
    s = p_bapi_body(s);
    !!! The table keeps a record of its own and not the statement: the parser links
    !!! the statement it returned into the program chain, which would make the table
    !!! walk into the whole program and answer the first FUNCTION of that name.
    PBapiDef proto;
    @PBapiDef e;
    malloc(@e, size proto);
    e.name = s.var_name;
    e.stmt = s;
    e.next = null;
    if p_bapi_defs == null {
        p_bapi_defs = e;
    } else {
        @PBapiDef t = p_bapi_defs;
        while t.next != null {
            t = t.next;
        }
        t.next = e;
    }
    return s;
}

!!! `__get_built_in_func<name> alias;` binds the alias to the builtin, and marks the
!!! builtin as active: only an active one may stand in the return-type slot of a
!!! function head.
@StmtNode p_builtin_bind {
    p_adv();
    if !p_is(TK_LT) {
        p_error_cur("missing '<' after __get_built_in_func");
        return null;
    }
    p_adv();
    if !p_is(TK_IDENT) {
        p_error_cur("missing builtin function name inside <...>");
        return null;
    }
    str bname = span_text(p_cur.start, p_cur.stop);
    int bl = p_cur.line;
    int bc = p_cur.col;
    p_adv();
    if !p_is(TK_GT) {
        p_error_cur("missing '>' after builtin name");
        return null;
    }
    p_adv();
    if !p_is(TK_IDENT) {
        p_error_cur("missing alias name after >");
        return null;
    }
    str alias = span_text(p_cur.start, p_cur.stop);
    p_adv();
    if p_is(TK_SEMI) {
        p_adv();
    }

    @BuiltinFunc b = find_builtin(bname);
    if b == null {
        p_error_at(bl, bc, p_text_len(bname), "unknown builtin function '" + bname + "'");
        return null;
    }
    p_bind_builtin(alias, bname);
    if !p_in_str_chain(p_registered_builtins, bname) {
        p_registered_builtins = p_chain_str(p_registered_builtins,
                                            p_new_name(bname, bl, bc));
    }
    return null;
}
