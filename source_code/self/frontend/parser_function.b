#once
!~
 ~  bootstrap/frontend/parser_function.b: the frontend/parser_function.
 ~
 ~  A function head is a type, a name and a parameter list with no parentheses:
 ~  `int f -> int a, str b { ... }`, and a stub is the same head ending in `;` with
 ~  no body. `local` marks a helper that only this file reaches, `reload` marks one
 ~  more version of a name that already has a prototype.
 ~
 ~  The parameter lists vectors are chains here, and the flags of a
 ~  parameter travel beside its type exactly as they do there: what a parameter is
 ~  (`ref`, `const`, `static`, `utype`, an array, the variadic tail) is a list of its
 ~  own, in declaration order.
 ~!

#head "parser"

!!! The name p_pack_group() read: a str cannot come back through a parameter, so
!!! the group reader leaves it here: p_pack_group(name, what) answers whether the
!!! group was read and the name it held is in this global.
str p_pack_group_out_name;

!!! The parameter list of a template function, written as two pack expansions:
!!!
!!!     -> (Y etc) (Args etc)
!!!
!!! `Y` names the type pack that gives the parameters their types and `Args` the
!!! argument pack the body reaches them through. Nothing is bound here: the
!!! instantiation builds one parameter per element of the type pack. Both groups
!!! are consumed, `)` included, and the caller goes on to read the body. Answers
!!! false (with the reason reported) when the list is not this shape.
bool p_parse_pack_params -> @StmtNode s {
    if !p_pack_group("type pack") {
        return false;
    }
    str types = p_pack_group_out_name;
    if !p_is(TK_LPAREN) {
        p_error_cur("missing '(' before the argument pack");
        return false;
    }
    if !p_pack_group("argument pack") {
        return false;
    }
    str names = p_pack_group_out_name;
    s.pack_ptypes = types;
    s.pack_pnames = names;
    s.params_from_pack = true;
    return true;
}

!!! One `( name etc )` group of that list, left in p_pack_group_out_name.
bool p_pack_group -> str what {
    p_adv();
    if !p_is(TK_IDENT) {
        p_error_cur("missing " + what + " name");
        return false;
    }
    p_pack_group_out_name = span_text(p_cur.start, p_cur.stop);
    p_adv();
    if !p_is_kw("etc") {
        p_error_cur("missing 'etc' after the " + what);
        return false;
    }
    p_adv();
    if !p_is(TK_RPAREN) {
        p_error_cur("missing ')'");
        return false;
    }
    p_adv();
    return true;
}

@BoolNode p_chain_bool -> @BoolNode head, @BoolNode node {
    if head == null {
        return node;
    }
    @BoolNode t = head;
    while t.next != null {
        t = t.next;
    }
    t.next = node;
    return head;
}

@BapiCallSeg p_chain_seg -> @BapiCallSeg head, @BapiCallSeg node {
    if head == null {
        return node;
    }
    @BapiCallSeg t = head;
    while t.next != null {
        t = t.next;
    }
    t.next = node;
    return head;
}

!!! A copy of a chain of names: a call segment keeps the parameters that were
!!! collected when it was written, so a directive that comes later cannot add to a
!!! call that already stands in the tree.
@StrNode p_copy_str_chain -> @StrNode src {
    @StrNode head = null;
    while src != null {
        head = p_chain_str(head, p_new_name(src.s, src.line, src.col));
        src = src.next;
    }
    return head;
}

!!! Set the value of the last node of a chain: `int a...` marks the parameter that
!!! came last as the one the dots belong to.
void p_set_last_bool -> @BoolNode head, bool v {
    if head == null {
        end;
    }
    @BoolNode t = head;
    while t.next != null {
        t = t.next;
    }
    t.v = v;
}

!!! Skip a whole `{ ... }` block, the braces included. A body that is not the one
!!! being parsed (a stub that grew one, a statement that made no sense) is stepped
!!! over as a whole, so the parse carries on after it.
void p_skip_block {
    if !p_is(TK_LBRACE) {
        end;
    }
    int depth = 1;
    p_adv();
    while depth > 0 && !p_is(TK_EOF) {
        if p_is(TK_LBRACE) {
            depth = depth + 1;
        } else if p_is(TK_RBRACE) {
            depth = depth - 1;
            if depth == 0 {
                p_adv();
                end;
            }
        }
        p_adv();
    }
}

@StmtNode p_stub_function {
    p_adv();
    return p_function(true);
}

@StmtNode p_local_function {
    p_adv();
    @StmtNode s = p_function(false);
    if s != null {
        s.is_local = true;
    }
    return s;
}

!!! `reload` marks one more version of a function that already has a prototype;
!!! using it on the first definition of a name is an error the generator reports.
@StmtNode p_reload_function {
    int rline = p_cur.line;
    int rcol = p_cur.col;
    p_adv();
    @StmtNode s = p_function(false);
    if s != null && s.nk == FUNCTION {
        s.is_reload = true;
        s.reload_line = rline;
        s.reload_col = rcol;
        s.reload_len = 6;
    }
    return s;
}

@StmtNode p_function -> bool is_stub {
    @StmtNode s = p_new_stmt(FUNCTION);
    s.is_stub = is_stub;

    !!! The return type. `<builtin> name -> ...` is the one head whose return-type
    !!! slot holds a builtin object annotation rather than a type: the builtin has to
    !!! have been activated with `__get_built_in_func<...>` first.
    if p_is(TK_IDENT) {
        str bn = span_text(p_cur.start, p_cur.stop);
        @BuiltinFunc b = find_builtin(bn);
        if b != null && b.returns_object && p_in_str_chain(p_registered_builtins, bn) {
            s.builtin_annotation = bn;
            s.func_ret_type = b.ret_type;
            p_adv();
        }
    }
    if s.builtin_annotation == "" {
        int rtl = p_cur.line;
        int rtc = p_cur.col;
        s.func_ret_type = p_type();
        !!! `@T f` hands back the address and not the object: the flag decides both
        !!! how the function is emitted and how its result is read.
        s.ret_struct = p_last_struct;
        s.ret_struct_ptr = p_last_is_struct_ptr && p_last_struct != "";
        s.ret_ptr_depth = p_last_ptr_depth;
        s.ret_type_line = rtl;
        s.ret_type_col = rtc;
        s.ret_type_len = (p_prev.col + (p_prev.stop - p_prev.start)) - rtc;
        if s.ret_type_len <= 0 {
            s.ret_type_len = p_prev.stop - p_prev.start;
        }
        !!! `static int f`: a function has no storage of its own, so the qualifier
        !!! means nothing here and is refused instead of ignored.
        if p_last_is_static {
            p_error_at(rtl, rtc, 6, "static is not supported for a function");
        }
        !!! `utype int f`: the value the function hands back is unsigned.
        if p_last_is_unsigned {
            if !p_unsigned_ok(s.func_ret_type) {
                p_error_at(rtl, rtc, 5, "utype is only for 'int', 'longlong' or 'char'");
            } else {
                s.ret_is_unsigned = true;
            }
        }
    }

    if !p_is(TK_IDENT) {
        p_error_cur("missing function name");
        return s;
    }
    s.var_name = span_text(p_cur.start, p_cur.stop);
    s.var_line = p_cur.line;
    s.var_col = p_cur.col;
    p_adv();

    !!! A qualified name: `namespace::func`, or the type of a method defined out here
    !!! (`void Person::birth { ... }`): the name before `::` is read as a type when one
    !!! is declared with it, and the definition is given to that type's method at the
    !!! end of this declaration. A field of a record cannot be indexed here, so the two
    !!! halves are kept apart while the name is being read.
    str method_owner = "";
    str method_only = "";
    if p_is(TK_SCOPE) {
        str before = s.var_name;
        p_adv();
        if p_is(TK_IDENT) {
            method_only = span_text(p_cur.start, p_cur.stop);
            s.var_name = s.var_name + "::" + method_only;
            p_adv();
            if p_find_struct(before) != null {
                method_owner = before;
            }
        } else {
            p_error_cur("missing identifier after '::'");
            s.broken = true;
        }
    }

    !!! The parameter list has no parentheses: a stub ends it with ';', a body with
    !!! '{'.
    if p_is(TK_MINUS) && p_peek_is(1, TK_GT) {
        p_adv();
        p_adv();
        !!! `-> (Y etc) (Args etc)`: a template function whose parameter list is
        !!! built when the template is instantiated - one parameter per element of
        !!! the type pack Y - and whose body reaches the parameters through the
        !!! argument pack Args. The concrete `fparams` are left empty here.
        if p_is(TK_LPAREN) {
            s.params_line = p_cur.line;
            s.params_col = p_cur.col;
            if !p_parse_pack_params(s) {
                !!! A parameter list that is not the pack form: skip to the body so
                !!! the block is still consumed and the parse goes on.
                s.broken = true;
                while !p_is(TK_LBRACE) && !p_is(TK_SEMI) && !p_is(TK_EOF) {
                    p_adv();
                }
            }
        } else {
        if !p_is(TK_LBRACE) && !p_is(TK_SEMI) && !p_is(TK_EOF) {
            s.params_line = p_cur.line;
            s.params_col = p_cur.col;
        }
        !!! Whether a parameter with a default has already been read: the ones after
        !!! it may not leave it out.
        bool seen_default_before = false;
        while !p_is(TK_LBRACE) && !p_is(TK_SEMI) && !p_is(TK_EOF) {
            int ptl = p_cur.line;
            int ptc = p_cur.col;
            VarType pt = p_type();
            str psn = p_last_struct;
            if !p_is(TK_IDENT) {
                p_error_cur("missing parameter name");
                return s;
            }
            s.fparam_types = p_chain_type(s.fparam_types, p_new_type(pt));
            s.fparam_struct = p_chain_str(s.fparam_struct, p_new_name(psn, p_cur.line, p_cur.col));
            s.fparam_is_ref = p_chain_bool(s.fparam_is_ref, p_new_bool(p_last_is_ref));
            s.fparam_is_const = p_chain_bool(s.fparam_is_const, p_new_bool(p_last_is_const));
            s.fparam_is_static = p_chain_bool(s.fparam_is_static, p_new_bool(p_last_is_static));
            if p_last_is_unsigned && !p_unsigned_ok(pt) {
                p_error_at(ptl, ptc, 5, "utype is only for 'int', 'longlong' or 'char'");
                s.fparam_is_unsigned = p_chain_bool(s.fparam_is_unsigned, p_new_bool(false));
            } else {
                s.fparam_is_unsigned = p_chain_bool(s.fparam_is_unsigned,
                                                    p_new_bool(p_last_is_unsigned));
            }
            s.fparams = p_chain_str(s.fparams,
                                    p_new_span(p_cur.start, p_cur.stop, p_cur.line, p_cur.col));
            s.nfparams = s.nfparams + 1;
            p_adv();
            !!! A default value has to be a constant expression, so that a call that
            !!! leaves the argument out can be given it here. the toolchain list holds one
            !!! entry per parameter with a null for "no default"; a chain cannot hold
            !!! the null, so the flag travels in a chain of its own.
            if p_take(TK_ASSIGN) {
                @ExprNode def = parse_expr(0);
                if def == null {
                    return null;
                }
                s.fparam_defaults = p_chain_expr(s.fparam_defaults, def);
                s.fparam_has_default = p_chain_bool(s.fparam_has_default, p_new_bool(true));
                seen_default_before = true;
            } else {
                s.fparam_has_default = p_chain_bool(s.fparam_has_default, p_new_bool(false));
                !!! A parameter with a default may not be followed by one without.
                if seen_default_before {
                    p_error_at(ptl, ptc, p_cur.stop - p_cur.start + 0,
                               "parameter without a default value may not follow a parameter with one");
                    s.broken = true;
                }
            }
            !!! `int arr[]` is a parameter that is handed the address of a block.
            bool is_arr = false;
            if p_is(TK_LBRACKET) && p_peek_is(1, TK_RBRACKET) {
                is_arr = true;
                p_adv();
                p_adv();
            }
            s.fparam_is_array = p_chain_bool(s.fparam_is_array, p_new_bool(is_arr));
            !!! `int name...` is the variadic tail: it is the last parameter and no
            !!! other one may follow it.
            if p_is(TK_ELLIPSIS) {
                s.variadic = true;
                p_set_last_bool(s.fparam_is_array, true);
                p_adv();
                skip;
            }
            if !p_take(TK_COMMA) {
                skip;
            }
        }
        !!! The note under a call with the wrong number of arguments colours the
        !!! whole parameter list of the declaration and not the blanks before the
        !!! body: the length runs from the first parameter to the token that ends
        !!! the list, with the spaces at the end taken off again. Without this the
        !!! note pointed at one character of it (`void add -> int a` coloured only
        !!! the `i` of `int`, and no length at all when the list was empty).
        if s.params_col > 0 && p_cur.col > s.params_col {
            s.params_len = p_cur.col - s.params_col;
            str src_line = line_text(s.params_line);
            int ln = pe_len(src_line);
            int stop = s.params_col + s.params_len - 1;
            while stop >= s.params_col && stop - 1 < ln && src_line[stop - 1] == ' ' {
                stop = stop - 1;
                s.params_len = s.params_len - 1;
            }
            unlink(@src_line);
        }
        }
    } else if !is_stub && !p_is(TK_LBRACE) {
        !!! Something stands between the name and the body that belongs to neither a
        !!! parameter list nor a return type. The block is stepped over as a whole so
        !!! that what follows it is still read.
        p_error_cur("meaningless '" + span_text(p_cur.start, p_cur.stop) + "'; missing '->' or '{'");
        s.broken = true;
        while !p_is(TK_LBRACE) && !p_is(TK_RBRACE) && !p_is(TK_EOF) {
            p_adv();
        }
        if p_is(TK_LBRACE) {
            p_skip_block();
        }
        return s;
    }

    if is_stub {
        !!! A stub is the signature only: it ends with ';' and has no body.
        if p_is(TK_LBRACE) {
            p_error_cur("stub function must not have a body");
            s.broken = true;
            p_skip_block();
        } else if !p_is(TK_SEMI) {
            p_error_cur("missing ';' after stub declaration");
            s.broken = true;
        } else {
            p_adv();
        }
        return s;
    }

    if !p_is(TK_LBRACE) {
        !!! the toolchain has no message here: this is the `add_error` shape, which does
        !!! not resync.
        p_error("missing '{'");
        s.broken = true;
        return s;
    }

    !!! The body is read with this function in context, so a diagnostic inside it is
    !!! headed by the function it is in - the header parser, which
    !!! stands before every error of the body.
    str saved_name = p_func_name;
    str saved_ret = p_func_ret;
    bool saved_header = p_header_done;
    int saved_fline = p_func_line;
    p_func_name = s.var_name;
    p_func_ret = type_name(s.func_ret_type);
    !!! The line the function starts on, which is the line the "In function" header
    !!! takes its file from: a function written in a `#head` file is headed by that
    !!! file, not by the one being compiled (`_func_line = s->line` of the toolchain).
    p_func_line = s.line;
    p_header_done = false;
    s.true_body = p_block();
    !!! Where the body's `}` stood, which is where "must contain at least one
    !!! return statement" points (`parse_block`'s out_close_line / out_close_col).
    s.end_line = p_block_end_line;
    s.end_col = p_block_end_col;
    p_func_name = saved_name;
    p_func_ret = saved_ret;
    p_func_line = saved_fline;
    p_header_done = saved_header;
    s.has_return = true;

    !!! `void Person::birth { ... }`: the body is given to the method the type declared,
    !!! and the definition itself is not a function of the file - nothing is chained,
    !!! so null is the answer. The declaration is what every call was checked against,
    !!! so it keeps its symbol (the plain method name), its access and its default
    !!! arguments, and a definition that says something else is reported rather than
    !!! believed.
    if method_owner != "" {
        @StructDef owner_def = p_find_struct(method_owner);
        @StructMethod found = null;
        if owner_def != null {
            @StructMethod sm = owner_def.methods;
            while sm != null {
                if pe_eq(sm.name, method_only) {
                    found = sm;
                    skip;
                }
                sm = sm.next;
            }
        }
        if found == null || found.fn == null {
            p_error_at(s.var_line, s.var_col, p_text_len(method_only),
                       "struct '" + method_owner + "' has no method '" + method_only + "'");
            return null;
        }
        @StmtNode decl = found.fn;
        if decl.true_body != null {
            p_error_at(s.var_line, s.var_col, p_text_len(method_only),
                       "method '" + method_owner + "." + method_only + "' already has a body");
            return null;
        }
        bool same_ret = pe_eq(decl.ret_struct, s.ret_struct) &&
                        decl.ret_struct_ptr == s.ret_struct_ptr &&
                        decl.func_ret_type == s.func_ret_type;
        !!! The parameters are compared by type and by struct name. A marker the
        !!! declaration and the definition may spell differently (`ref`, an array
        !!! length, a default) is not compared: the definition writes the body, and
        !!! being forgiving about a spelling that does not change the call is safer
        !!! than rejecting a definition that is right.
        bool same_params = rgx_strnode_n(decl.fparams) == rgx_strnode_n(s.fparams);
        @VarTypeNode dt = decl.fparam_types;
        @VarTypeNode st = s.fparam_types;
        @StrNode dsn = decl.fparam_struct;
        @StrNode ssn = s.fparam_struct;
        while same_params && dt != null && st != null {
            if dt.ty != st.ty {
                same_params = false;
            }
            if dsn != null && ssn != null && !pe_eq(dsn.s, ssn.s) {
                same_params = false;
            }
            dt = dt.next;
            st = st.next;
            if dsn != null {
                dsn = dsn.next;
            }
            if ssn != null {
                ssn = ssn.next;
            }
        }
        if !same_ret || !same_params {
            p_error_at(s.var_line, s.var_col, p_text_len(method_only),
                       "the definition of '" + method_owner + "." + method_only +
                       "' does not match its declaration");
            return null;
        }
        !!! The declared parameter names and defaults are not copied over: the
        !!! definition writes its own, exactly as the body that uses them does.
        s.var_name = found.name;
        s.struct_type = method_owner;
        s.access = found.access;
        s.is_stub = false;
        found.fn = s;
        !!! The definition is not a function of the file: it is the body of the method
        !!! the type declared, and the emitter writes it from the type's own method
        !!! list.
        return null;
    }
    return s;
}
