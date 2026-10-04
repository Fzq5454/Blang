#once
!~
 ~  bootstrap/frontend/parser_struct.b: the frontend/parser_struct.
 ~
 ~  A `type` body: its bases, its fields, its methods, its overloaded operators,
 ~  its BLANG_API methods, its constructor and its destructor.
 ~
 ~  The definition is registered before the body is read, so the type can refer to
 ~  itself (`@Node next` inside Node). Inside an `introduce` block the same body is
 ~  a *generic* struct: only its name is registered, as a template, and the concrete
 ~  definition is built later for each instantiation.
 ~
 ~  The lists vectors are chains here, and a helper that answers through
 ~  an out-parameter leaves its answer in a field (`op_ok`, `op_target`,
 ~  `op_scalar`), because a function answers one value.
 ~!

#head "parser"
#head "operator_table"

!!! The characters an identifier may hold: a type spelling that names the source of
!!! a converting constructor becomes part of a method name, so anything else is
!!! replaced.
str p_ident_safe -> str s {
    if s == null {
        return "";
    }
    @void cell;
    malloc(@cell, p_text_len(s) + 1);
    @char d = (@char)cell;
    int i = 0;
    while s[i] != (char)0 {
        char c = s[i];
        bool ok = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
                  (c >= '0' && c <= '9') || c == '_';
        if ok {
            d[i] = c;
        } else {
            d[i] = '_';
        }
        i = i + 1;
    }
    d[i] = (char)0;
    return (str)cell;
}

!!! Skip a malformed `operator` declaration so the rest of the type body still
!!! parses: a body is skipped as a whole with its braces balanced, and a
!!! declaration without one stops at its ';'.
void p_skip_broken_operator_decl {
    int depth = 0;
    while !p_is(TK_EOF) {
        TokenKind k = p_cur.tk;
        if k == TK_LBRACE {
            depth = depth + 1;
            p_adv();
            continue;
        }
        if k == TK_RBRACE {
            if depth == 0 {
                end;
            }
            depth = depth - 1;
            p_adv();
            if depth == 0 {
                end;
            }
            continue;
        }
        if k == TK_SEMI && depth == 0 {
            p_adv();
            end;
        }
        p_adv();
    }
}

!!! The fields of a method head: its return type, its name, its parameters and
!!! the flags that go with them. Every method of a type - a plain one, an operator,
!!! a constructor - is a FUNCTION statement of this shape, so the three heads share
!!! this reader. `mline`/`mcol` are where the name stands (the toolchain passes them on to
!!! the diagnostic about a parameter without a default).
void p_struct_method_params -> @StmtNode fn {
    if p_is(TK_MINUS) && p_peek_is(1, TK_GT) {
        p_adv();
        p_adv();
        bool seen_default_before = false;
        while !p_is(TK_LBRACE) && !(fn.is_stub && p_is(TK_SEMI)) && !p_is(TK_EOF) {
            int ptl = p_cur.line;
            int ptc = p_cur.col;
            VarType pt = p_type();
            str psn = p_last_struct;
            if !p_is(TK_IDENT) {
                p_error_cur("missing parameter name");
                skip;
            }
            fn.fparam_types = p_chain_type(fn.fparam_types, p_new_type(pt));
            fn.fparam_struct = p_chain_str(fn.fparam_struct, p_new_name(psn, p_cur.line, p_cur.col));
            fn.fparam_is_ref = p_chain_bool(fn.fparam_is_ref, p_new_bool(p_last_is_ref));
            fn.fparam_is_const = p_chain_bool(fn.fparam_is_const, p_new_bool(p_last_is_const));
            fn.fparam_is_static = p_chain_bool(fn.fparam_is_static, p_new_bool(p_last_is_static));
            if p_last_is_unsigned && !p_unsigned_ok(pt) {
                p_error_at(ptl, ptc, 5, "utype is only for 'int', 'longlong' or 'char'");
                fn.fparam_is_unsigned = p_chain_bool(fn.fparam_is_unsigned, p_new_bool(false));
            } else {
                fn.fparam_is_unsigned = p_chain_bool(fn.fparam_is_unsigned,
                                                       p_new_bool(p_last_is_unsigned));
            }
            fn.fparams = p_chain_str(fn.fparams,
                                       p_new_span(p_cur.start, p_cur.stop, p_cur.line, p_cur.col));
            fn.nfparams = fn.nfparams + 1;
            p_adv();
            !!! A default value has to be a constant expression; a call that leaves
            !!! the argument out is given it here.
            if p_take(TK_ASSIGN) {
                @ExprNode def = parse_expr(0);
                if def == null {
                    skip;
                }
                if !p_is_const_expr(def) {
                    p_error_at(def.line, def.col, def.tok_len > 0 ? def.tok_len : 1,
                               "default argument must be a constant expression");
                } else {
                    fn.fparam_defaults = p_chain_expr(fn.fparam_defaults, def);
                    fn.fparam_has_default = p_chain_bool(fn.fparam_has_default, p_new_bool(true));
                    seen_default_before = true;
                    if p_is(TK_COMMA) {
                        p_adv();
                    }
                    continue;
                }
            }
            fn.fparam_has_default = p_chain_bool(fn.fparam_has_default, p_new_bool(false));
            !!! A parameter with a default may not be followed by one without: the
            !!! omitted ones are filled from the end, so a later one could never be
            !!! given.
            if seen_default_before {
                p_error_at(ptl, ptc, p_cur.stop - p_cur.start,
                           "parameter without a default value may not follow a parameter with one");
            }
            if p_is(TK_COMMA) {
                p_adv();
            }
        }
    }
}

@StmtNode p_struct_def {
    bool in_generic = p_in_introduce > 0;
    @StmtNode s = p_new_stmt(STRUCT_DEF);
    p_adv();

    if !p_is(TK_IDENT) {
        p_error_cur("missing struct name");
        return s;
    }
    s.var_name = span_text(p_cur.start, p_cur.stop);
    s.var_line = p_cur.line;
    s.var_col = p_cur.col;
    p_adv();

    !!! A generic struct is a template and is registered as one below; its name is
    !!! not a type of its own, so it goes in neither of the tables a plain struct
    !!! is in (see p_new_struct_def).
    @StructDef def;
    if in_generic {
        def = p_new_struct_def(s.var_name, s.line, s.col);
    } else {
        def = p_add_struct(s.var_name, s.line, s.col);
    }
    def.line = s.line;
    def.col = s.col;
    def.name_line = s.var_line;
    def.name_col = s.var_col;
    !!! A generic struct is registered as a template instead: instantiation clones
    !!! its body, and the template keeps the parameter list of the introduce block.
    if in_generic {
        @StructTemplate tmpl = p_find_template(s.var_name);
        if tmpl == null {
            StructTemplate proto;
            malloc(@tmpl, size proto);
            tmpl.tparams = p_cur_tparams;
            tmpl.tparam_is_value = p_cur_tparam_is_value;
            tmpl.tparam_types = p_cur_tparam_types;
            tmpl.tparam_is_template = p_cur_tparam_is_template;
            tmpl.def = null;
            tmpl.next = p_struct_templates;
            p_struct_templates = tmpl;
        }
        tmpl.def = def;
    }

    !!! Inheritance: `type A : B, C { ... }`.
    if p_is(TK_COLON) {
        p_adv();
        while !p_is(TK_EOF) && !p_is(TK_LBRACE) {
            if !p_is(TK_IDENT) {
                p_error_cur("missing base type name after ':'");
                while !p_is(TK_EOF) && !p_is(TK_LBRACE) && !p_is(TK_RBRACE) {
                    p_adv();
                }
                skip;
            }
            def.bases = p_chain_str(def.bases,
                                    p_new_span(p_cur.start, p_cur.stop, p_cur.line, p_cur.col));
            def.bases_line = p_chain_int(def.bases_line, p_new_int(p_cur.line));
            def.bases_col = p_chain_int(def.bases_col, p_new_int(p_cur.col));
            p_adv();
            if p_is(TK_COMMA) {
                p_adv();
                continue;
            }
            skip;
        }
    }

    if !p_is(TK_LBRACE) {
        p_error_cur("missing '{'");
        return s;
    }
    p_adv();

    int offset = 0;
    !!! The access level a member gets: 0 public (also what a member written outside
    !!! any section is), 1 protected, 2 private. `public { ... }` and the one-member
    !!! form `private int x;` both set it; sections do not nest, so one level and one
    !!! depth are all the state there is.
    int cur_access = 0;
    int section_depth = 0;
    while !p_is(TK_EOF) {
        if p_is(TK_RBRACE) {
            if section_depth > 0 {
                p_adv(); !!! the section's }
                section_depth = section_depth - 1;
                cur_access = 0;
                continue;
            }
            skip; !!! the type's own }
        }
        !!! A BLANG_API body consumes the type's own '}', and the ';' after it is the
        !!! one that closes the type: the body ends here.
        if p_is(TK_SEMI) {
            skip;
        }
        !!! `public` / `private` / `protected` before a member, or before a `{ ... }`
        !!! block that makes the level the default for what it holds. The three words
        !!! are not reserved: they mean something only here, where a member starts and
        !!! an identifier cannot stand on its own.
        int item_access = cur_access;
        if p_is(TK_IDENT) && (p_name_is("public") || p_name_is("protected") || p_name_is("private")) {
            if p_name_is("public") {
                item_access = 0;
            } else if p_name_is("protected") {
                item_access = 1;
            } else {
                item_access = 2;
            }
            p_adv();
            if p_is(TK_LBRACE) {
                p_adv(); !!! {
                section_depth = section_depth + 1;
                cur_access = item_access;
                continue;
            }
        }
        !!! `reload` in front of a declaration adds one more version of a method or
        !!! operator that already exists in this type.
        bool is_reload_decl = false;
        int reload_line = 0;
        int reload_col = 0;
        if p_is_kw("reload") {
            is_reload_decl = true;
            reload_line = p_cur.line;
            reload_col = p_cur.col;
            p_adv();
        }
        if p_is_kw("operator") {
            !!! `operator` needs the return type in front of it, like every other
            !!! method: `Vec operator + -> Vec b { ... }`.
            p_error_cur("missing return type before 'operator'");
            p_skip_broken_operator_decl();
            continue;
        }
        !!! `stub` in front of a method: the signature only, with the body written
        !!! outside the type (`void Person::birth { ... }`, parser_function.b). What
        !!! follows has to be a method declaration - a field cannot be a stub.
        bool is_stub_method = false;
        if p_is_kw("stub") {
            int stub_line0 = p_cur.line;
            int stub_col0 = p_cur.col;
            p_adv();
            !!! What a stub declares is `void birth;` or `int grow -> int by;`: a return
            !!! type and a method name. `p_peek_is_function` wants a `{` or a `->` after
            !!! the name, which a stub without parameters does not have, so the head is
            !!! read here.
            bool is_method_head = false;
            if p_is_type() && p_peek_is(1, TK_IDENT) {
                is_method_head = true;
            }
            if !is_method_head {
                p_error_at(stub_line0, stub_col0, 4, "stub is only for a method declaration");
                while !p_is(TK_EOF) && !p_is(TK_RBRACE) && !p_is(TK_SEMI) {
                    p_adv();
                }
                if p_is(TK_SEMI) {
                    p_adv();
                }
                continue;
            }
            is_stub_method = true;
        }
        if p_is_type() && (p_peek_is(1, TK_KEYWORD) && p_span_is(p_peek(1), "operator") ||
                           p_is_ptr_operator_decl()) {
            !!! An overloaded operator is an ordinary method whose name is fixed by
            !!! the symbol and the parameter count. A pointer return
            !!! (`@Vec operator []`) puts the `operator` keyword behind the pointer
            !!! tokens.
            int kline = p_cur.line;
            int kcol = p_cur.col;
            VarType ret_type = p_type();
            str ret_struct = p_last_struct;
            bool ret_is_struct_ptr = p_last_is_struct_ptr && ret_struct != "";
            int ret_depth = p_last_ptr_depth;
            p_adv();
            bool sym_ok = false;
            if p_is(TK_PLUS) || p_is(TK_MINUS) || p_is(TK_STAR) || p_is(TK_SLASH) ||
               p_is(TK_MOD) || p_is(TK_EQ) || p_is(TK_NE) || p_is(TK_LT) ||
               p_is(TK_GT) || p_is(TK_LE) || p_is(TK_GE) || p_is(TK_BITAND) ||
               p_is(TK_BITOR) || p_is(TK_BITXOR) || p_is(TK_BITNOT) || p_is(TK_SHL) ||
               p_is(TK_SHR) || p_is(TK_NOT) {
                sym_ok = true;
            }
            !!! A conversion operator: the symbol is the target type name.
            if !sym_ok && (p_is_kw("str") || p_is_kw("int") || p_is_kw("float") ||
                           p_is_kw("bool") || p_is_kw("char")) {
                sym_ok = true;
            }
            !!! The subscript operator: `[]` reads, `[]=` writes.
            bool subscript = false;
            if !sym_ok && p_is(TK_LBRACKET) && p_peek_is(1, TK_RBRACKET) {
                subscript = true;
            }
            if !sym_ok && !subscript {
                p_error_cur("expected an overloadable operator symbol after 'operator'");
                p_skip_broken_operator_decl();
                continue;
            }
            str sym = span_text(p_cur.start, p_cur.stop);
            if subscript {
                sym = "[]";
            }
            int sym_line = p_cur.line;
            int sym_col = p_cur.col;
            int sym_len = p_text_len(sym);
            if subscript {
                p_adv();
                p_adv();
                if p_is(TK_ASSIGN) {
                    sym = "[]=";
                    p_adv();
                }
            } else {
                p_adv();
            }

            @StmtNode fn2 = p_new_stmt(FUNCTION);
            fn2.line = kline;
            fn2.col = kcol;
            fn2.var_line = sym_line;
            fn2.var_col = sym_col;
            fn2.struct_type = def.name;
            fn2.is_reload = is_reload_decl;
            fn2.reload_line = reload_line;
            fn2.reload_col = reload_col;
            fn2.reload_len = 6;
            fn2.func_ret_type = ret_type;
            fn2.ret_struct = ret_struct;
            fn2.ret_struct_ptr = ret_is_struct_ptr;
            fn2.ret_ptr_depth = ret_depth;
            fn2.ret_type_line = kline;
            fn2.ret_type_col = kcol;
            fn2.ret_type_len = p_text_len(ret_struct);
            p_struct_method_params(fn2);
            if p_is(TK_LBRACE) {
                str saved_n = p_func_name;
                str saved_r = p_func_ret;
                bool saved_h = p_header_done;
                p_func_name = sym;
                p_func_ret = type_name(ret_type);
                p_header_done = false;
                fn2.true_body = p_block();
                p_func_name = saved_n;
                p_func_ret = saved_r;
                p_header_done = saved_h;
            } else if p_is(TK_SEMI) && (p_text_eq(sym, "==") || p_text_eq(sym, "!=")) {
                !!! `int operator ==;` has no body: the compiler compares every field
                !!! of the type. The parameter is the type itself.
                fn2.synth_op = sym;
                if fn2.fparams == null {
                    fn2.fparam_types = p_chain_type(fn2.fparam_types, p_new_type(INT));
                    fn2.fparam_struct = p_chain_str(fn2.fparam_struct,
                                                     p_new_name(def.name, sym_line, sym_col));
                    fn2.fparams = p_chain_str(fn2.fparams, p_new_name("b", sym_line, sym_col));
                    fn2.nfparams = 1;
                }
            } else {
                p_error_cur("missing '{' after operator declaration");
            }
            str mname = operator_method_name(sym, fn2.nfparams);
            if !op_ok {
                p_error_at(sym_line, sym_col, sym_len,
                           "operator '" + sym + "' takes " +
                           (fn2.nfparams == 0 ? "one parameter"
                                               : (str)fn2.nfparams + " parameter(s)"));
            } else if operator_needs_bool_result(sym) &&
                      (fn2.ret_struct != "" ||
                       (fn2.func_ret_type != INT && fn2.func_ret_type != BOOL)) {
                p_error_at(sym_line, sym_col, sym_len,
                           "operator '" + sym + "' must return 'int' or 'bool'");
            } else if operator_conversion_target(sym) {
                !!! A conversion operator has to return the type it converts to.
                VarType want = INT;
                if p_text_eq(op_target, "str") { want = STR; }
                else if p_text_eq(op_target, "float") { want = FLOAT; }
                else if p_text_eq(op_target, "bool") { want = BOOL; }
                else if p_text_eq(op_target, "char") { want = CHAR; }
                if fn2.ret_struct != "" || fn2.func_ret_type != want {
                    p_error_at(sym_line, sym_col, sym_len,
                               "operator '" + sym + "' must return '" + op_target + "'");
                }
            }
            !!! A repeated operator is an error; the first declaration stays in
            !!! effect. A `reload` declaration adds another version instead.
            if !is_reload_decl {
                @StructMethod other = def.methods;
                while other != null {
                    if p_text_eq(other.op, sym) {
                        if other.fn == null || other.fn.nfparams == fn2.nfparams {
                            p_error_at(sym_line, sym_col, sym_len,
                                       "operator '" + sym + "' is already declared for type '" +
                                       def.name + "'");
                            skip;
                        }
                    }
                    other = other.next;
                }
            }
            if op_ok {
                fn2.var_name = mname;
                @StructMethod m;
                StructMethod proto;
                malloc(@m, size proto);
                m.name = mname;
                m.fn = fn2;
                fn2.access = item_access;
                m.access = item_access;
                m.op = sym;
                m.ctor_from = "";
                m.ctor_func = "";
                m.next = null;
                def.methods = p_chain_method(def.methods, m);
            }
            if p_is(TK_SEMI) {
                p_adv();
            } else if p_is(TK_COMMA) {
                p_adv();
            }
        } else if p_is_type() && (p_peek_is_function() || is_stub_method) {
            !!! A plain method: `int grow -> int by { ... }`.
            VarType ret = p_type();
            str sn = p_last_struct;
            @StmtNode fn2 = p_new_stmt(FUNCTION);
            fn2.line = p_cur.line;
            fn2.col = p_cur.col;
            fn2.var_name = span_text(p_cur.start, p_cur.stop);
            int mline = p_cur.line;
            int mcol = p_cur.col;
            p_adv();
            fn2.var_line = mline;
            fn2.var_col = mcol;
            fn2.func_ret_type = ret;
            fn2.ret_struct = sn;
            !!! `@T m` returns the address, exactly as a plain function does.
            fn2.ret_struct_ptr = p_last_is_struct_ptr && sn != "";
            fn2.ret_ptr_depth = p_last_ptr_depth;
            fn2.struct_type = def.name;
            fn2.is_reload = is_reload_decl;
            fn2.reload_line = reload_line;
            fn2.reload_col = reload_col;
            fn2.reload_len = 6;
            fn2.is_stub = is_stub_method;
            p_struct_method_params(fn2);
            if is_stub_method {
                !!! A stub declares the signature only: it ends with ';' and the body
                !!! is the definition written outside the type.
                if p_is(TK_LBRACE) {
                    !!! Reported without resynchronising: the block is skipped here, and
                    !!! a sync would already have moved past it.
                    p_error("stub method must not have a body");
                    fn2.broken = true;
                    p_skip_block();
                } else if !p_is(TK_SEMI) {
                    p_error_cur("missing ';' after stub declaration");
                    fn2.broken = true;
                } else {
                    p_adv();
                }
            } else if p_is(TK_LBRACE) {
                str saved_n2 = p_func_name;
                str saved_r2 = p_func_ret;
                bool saved_h2 = p_header_done;
                p_func_name = fn2.var_name;
                p_func_ret = type_name(ret);
                p_header_done = false;
                fn2.true_body = p_block();
                p_func_name = saved_n2;
                p_func_ret = saved_r2;
                p_header_done = saved_h2;
            }
            @StructMethod m2;
            StructMethod proto2;
            malloc(@m2, size proto2);
            m2.name = fn2.var_name;
            m2.fn = fn2;
            fn2.access = item_access;
            m2.access = item_access;
            m2.op = "";
            m2.ctor_from = "";
            m2.ctor_func = "";
            m2.next = null;
            def.methods = p_chain_method(def.methods, m2);
            if p_is(TK_SEMI) {
                p_adv();
            } else if p_is(TK_COMMA) {
                p_adv();
            }
        } else if is_reload_decl {
            !!! `reload` has to be followed by a method or an operator declaration.
            p_error_cur("expected a method or operator declaration after 'reload'");
            while !p_is(TK_EOF) && !p_is(TK_RBRACE) && !p_is(TK_SEMI) {
                p_adv();
            }
            if p_is(TK_SEMI) {
                p_adv();
            }
            continue;
        } else if p_is_kw("BLANG_API") {
            !!! A BLANG_API method inside a type: it is kept with the type and
            !!! expanded at its call sites, not in the global table.
            int bapi_line = p_cur.line;
            int bapi_col = p_cur.col;
            p_adv();
            VarType ret2 = p_type();
            int name_line = p_cur.line;
            int name_col = p_cur.col;
            str mname2 = span_text(p_cur.start, p_cur.stop);
            p_adv();

            @StmtNode bapi = p_new_stmt(BAPI);
            bapi.line = bapi_line;
            bapi.col = bapi_col;
            bapi.var_name = mname2;
            bapi.var_line = name_line;
            bapi.var_col = name_col;
            bapi.func_ret_type = ret2;

            if p_is(TK_MINUS) && p_peek_is(1, TK_GT) {
                p_adv();
                p_adv();
                while !p_is(TK_LBRACE) && !p_is(TK_EOF) {
                    VarType pt2 = p_type();
                    if !p_is(TK_IDENT) {
                        p_error_cur("missing parameter name");
                        skip;
                    }
                    bapi.fparam_types = p_chain_type(bapi.fparam_types, p_new_type(pt2));
                    bapi.fparams = p_chain_str(bapi.fparams,
                                               p_new_span(p_cur.start, p_cur.stop, p_cur.line, p_cur.col));
                    bapi.nfparams = bapi.nfparams + 1;
                    p_adv();
                    if p_is(TK_ELLIPSIS) {
                        bapi.variadic = true;
                        p_set_last_bool(bapi.fparam_is_array, true);
                        p_adv();
                    }
                    if p_is(TK_COMMA) {
                        p_adv();
                    }
                }
            }
            p_bapi_body(bapi);

            @StructBapiMethod bm;
            StructBapiMethod bproto;
            malloc(@bm, size bproto);
            bm.name = mname2;
            bm.bapi = bapi;
            bm.next = null;
            def.bapi_methods = p_chain_bapi(def.bapi_methods, bm);
            if p_is(TK_COMMA) {
                p_adv();
            }
        } else if p_is(TK_IDENT) && p_name_is("init") {
            !!! `init <name> { ... }` runs automatically when an instance is
            !!! declared; `init <name> -> T v { ... }` builds a value of this type out
            !!! of the values it takes, which is what makes `Vec x = 5;`, `x = 5;` and
            !!! a `Vec` parameter called with `5` work.
            int init_line = p_cur.line;
            int init_col = p_cur.col;
            p_adv();
            if !p_is(TK_IDENT) {
                p_error_cur("missing init name");
                while !p_is(TK_EOF) && !p_is(TK_LBRACE) && !p_is(TK_RBRACE) {
                    p_adv();
                }
                if p_is(TK_LBRACE) {
                    p_skip_block();
                }
                continue;
            }
            str init_name = span_text(p_cur.start, p_cur.stop);
            p_adv();

            @StmtNode func2 = p_new_stmt(FUNCTION);
            func2.line = init_line;
            func2.col = init_col;
            func2.var_line = init_line;
            func2.var_col = init_col;
            func2.func_ret_type = VOID;
            func2.struct_type = def.name;
            p_struct_method_params(func2);
            if p_is(TK_LBRACE) {
                str saved_n3 = p_func_name;
                str saved_r3 = p_func_ret;
                bool saved_h3 = p_header_done;
                p_func_name = init_name;
                p_func_ret = "void";
                p_header_done = false;
                func2.true_body = p_block();
                p_func_name = saved_n3;
                p_func_ret = saved_r3;
                p_header_done = saved_h3;
            }

            if func2.nfparams == 0 {
                !!! The plain constructor: no parameters, run on every declaration of
                !!! the type.
                func2.var_name = init_name;
                def.init_func = func2;
                def.init_line = init_line;
                def.init_col = init_col;
                func2.access = item_access;
                def.init_access = item_access;
            } else {
                !!! A converting constructor is a method; the name carries the source
                !!! types, so a type may declare one constructor per set of them
                !!! without any overload resolution.
                str tag = "";
                bool tag_ok = true;
                int pi = 0;
                @VarTypeNode ptv = func2.fparam_types;
                @StrNode psv = func2.fparam_struct;
                while ptv != null {
                    str seed = "";
                    if (psv == null || psv.s == "") && !scalar_type_name(ptv.ty) {
                        p_error_at(init_line, init_col, p_text_len(init_name),
                                   "parameter " + (str)(pi + 1) +
                                   " of a converting constructor must be a scalar or the value of another type");
                        tag_ok = false;
                        skip;
                    }
                    if psv != null && psv.s != "" {
                        seed = psv.s;
                    } else {
                        seed = op_scalar;
                    }
                    if tag != "" {
                        tag = tag + "_";
                    }
                    tag = tag + p_ident_safe(seed);
                    ptv = ptv.next;
                    if psv != null {
                        psv = psv.next;
                    }
                    pi = pi + 1;
                }
                str mname3 = "op_init_" + tag;
                bool ok3 = tag_ok;
                if ok3 {
                    @StructMethod other3 = def.methods;
                    while other3 != null {
                        if other3.ctor_from != "" && p_text_eq(other3.ctor_from, tag) {
                            p_error_at(init_line, init_col, p_text_len(init_name),
                                       "a converting constructor from '" + tag +
                                       "' is already declared for type '" + def.name + "'");
                            ok3 = false;
                            skip;
                        }
                        other3 = other3.next;
                    }
                }
                if ok3 {
                    func2.var_name = mname3;
                    @StructMethod m3;
                    StructMethod proto3;
                    malloc(@m3, size proto3);
                    m3.name = mname3;
                    m3.fn = func2;
                    func2.access = item_access;
                    m3.access = item_access;
                    m3.op = "init";
                    m3.ctor_from = tag;
                    m3.ctor_func = "";
                    m3.next = null;
                    def.methods = p_chain_method(def.methods, m3);
                }
            }
            if p_is(TK_SEMI) {
                p_adv();
            } else if p_is(TK_COMMA) {
                p_adv();
            }
        } else if p_is(TK_IDENT) && p_name_is("destruct") {
            !!! `destruct <name> { ... }` runs automatically when an instance goes
            !!! out of scope.
            int dtor_line = p_cur.line;
            int dtor_col = p_cur.col;
            p_adv();
            if !p_is(TK_IDENT) {
                p_error_cur("missing destruct name");
                while !p_is(TK_EOF) && !p_is(TK_LBRACE) && !p_is(TK_RBRACE) {
                    p_adv();
                }
                if p_is(TK_LBRACE) {
                    p_skip_block();
                }
                continue;
            }
            str dtor_name = span_text(p_cur.start, p_cur.stop);
            p_adv();
            !!! A destructor takes no parameters.
            if p_is(TK_MINUS) && p_peek_is(1, TK_GT) {
                p_error_at(p_cur.line, p_cur.col, p_cur.stop - p_cur.start,
                           "destruct cannot have parameters");
                p_adv();
                p_adv();
                while !p_is(TK_EOF) && !p_is(TK_LBRACE) {
                    p_adv();
                }
            }
            @StmtNode dfunc = p_new_stmt(FUNCTION);
            dfunc.line = dtor_line;
            dfunc.col = dtor_col;
            dfunc.var_name = dtor_name;
            dfunc.var_line = dtor_line;
            dfunc.var_col = dtor_col;
            dfunc.func_ret_type = VOID;
            dfunc.struct_type = def.name;
            if p_is(TK_LBRACE) {
                str saved_n4 = p_func_name;
                str saved_r4 = p_func_ret;
                bool saved_h4 = p_header_done;
                p_func_name = dtor_name;
                p_func_ret = "void";
                p_header_done = false;
                dfunc.true_body = p_block();
                p_func_name = saved_n4;
                p_func_ret = saved_r4;
                p_header_done = saved_h4;
            }
            def.destruct_func = dfunc;
            def.destruct_line = dtor_line;
            def.destruct_col = dtor_col;
            dfunc.access = item_access;
            def.destruct_access = item_access;
            if p_is(TK_SEMI) {
                p_adv();
            } else if p_is(TK_COMMA) {
                p_adv();
            }
        } else if p_is_type() {
            !!! A field.
            VarType ft = p_type();
            str fn = p_last_struct;
            bool is_sptr = p_last_is_struct_ptr;
            !!! A field has no single initialization point the way a local does, so
            !!! `const` cannot be honoured here and is refused instead of quietly
            !!! ignored; and a field is a slot inside every object, so there is no
            !!! storage that could live for the whole run either.
            if p_last_is_const {
                p_error_at(p_cur.line, p_cur.col, p_cur.stop - p_cur.start,
                           "const is not supported for a struct field");
            }
            if p_last_is_static {
                p_error_at(p_cur.line, p_cur.col, p_cur.stop - p_cur.start,
                           "static is not supported for a struct field");
            }
            if p_last_is_unsigned && !p_unsigned_ok(ft) {
                p_error_at(p_cur.line, p_cur.col, p_cur.stop - p_cur.start,
                           "utype is only for 'int', 'longlong' or 'char' on a struct field");
            }
            int fname_line = p_cur.line;
            int fname_col = p_cur.col;
            str fname = span_text(p_cur.start, p_cur.stop);
            p_adv();

            @StructField field;
            StructField fproto;
            malloc(@field, size fproto);
            field.name = fname;
            field.ty = ft;
            field.offset = offset;
            field.line = fname_line;
            field.col = fname_col;
            field.access = item_access;
            field.array_dim = 0;
            field.dims = null;
            field.dim_exprs = null;
            field.struct_type = fn;
            field.struct_ptr = is_sptr;
            field.is_unsigned = p_last_is_unsigned && p_unsigned_ok(ft);
            field.next = null;
            !!! A struct cannot contain itself by value (infinite size): the
            !!! self-reference has to go through `@T`.
            if !is_sptr && p_text_eq(fn, def.name) {
                p_error_at(fname_line, fname_col, p_text_len(fname),
                           "struct cannot contain itself by value");
            }

            !!! An inline array field, one bracket group per dimension:
            !!! `int data[4];`, `int m[2][3];`, `int data[N];`.
            while p_is(TK_LBRACKET) {
                p_adv();
                if p_is(TK_INTEGER) {
                    field.dims = p_chain_int(field.dims, p_new_int((int)p_cur.value));
                    field.dim_exprs = p_chain_expr(field.dim_exprs, null);
                    p_adv();
                } else if !p_is(TK_RBRACKET) {
                    !!! `int data[N]`: the dimension is a constant expression - it may
                    !!! use a template value parameter - and is folded when the struct
                    !!! is instantiated.
                    @ExprNode dim = parse_expr(0);
                    if dim != null {
                        p_eval_const_int(dim);
                        int v = (int)p_eval_value;
                        if p_const_ok && v > 0 {
                            field.dims = p_chain_int(field.dims, p_new_int(v));
                            field.dim_exprs = p_chain_expr(field.dim_exprs, null);
                        } else {
                            field.dims = p_chain_int(field.dims, p_new_int(0));
                            field.dim_exprs = p_chain_expr(field.dim_exprs, dim);
                        }
                    }
                } else {
                    p_error_cur("array size required inside '[]'");
                }
                if !p_is(TK_RBRACKET) {
                    p_error_cur("missing ']'");
                    return s;
                }
                p_adv();
            }
            !!! The total element count, 0 while a dimension is still symbolic.
            int total = 1;
            @IntNode dp = field.dims;
            while dp != null {
                if dp.v <= 0 {
                    total = 0;
                    skip;
                }
                total = total * dp.v;
                dp = dp.next;
            }
            if field.dims == null {
                field.array_dim = 0;
            } else {
                field.array_dim = total;
            }

            int field_size = 8;
            if field.array_dim > 0 {
                field_size = field.array_dim * 8;
            }
            offset = offset + field_size;
            def.fields = p_chain_field(def.fields, field);
            if p_is(TK_SEMI) {
                p_adv();
            } else if p_is(TK_COMMA) {
                p_adv();
            }
        } else {
            p_error_cur("missing field type or 'function'");
            p_adv();
        }
    }

    !!! The type closes with either `}` or `;` (when a BLANG_API body consumed the
    !!! `}`).
    if p_is(TK_SEMI) {
        p_adv();
    } else {
        if !p_is(TK_RBRACE) {
            p_error_cur("missing '}'");
            return s;
        }
        p_adv();
        if !p_is(TK_SEMI) {
            !!! the toolchain hands the missing `;` in as a suggestion right after the `}`
            !!! the message points at (`add_error(..., ";", prev_tok.col +
            !!! prev_tok.text.size(), true)`), so the layout shows the line the
            !!! semicolon belongs on.
            p_error_at_sug(p_prev.line, p_prev.col, p_prev.stop - p_prev.start,
                           "missing ';' after struct definition", ";",
                           p_prev.col + (p_prev.stop - p_prev.start));
        } else {
            p_adv();
        }
    }

    def.total_size = offset;
    if in_generic {
        !!! A generic body is a template: it is cloned for each concrete
        !!! instantiation (`Box(int) b;`) and never emitted on its own.
        @StructTemplate tmpl2 = p_find_template(def.name);
        if tmpl2 != null {
            tmpl2.def = def;
        }
        return null;
    }
    return s;
}
