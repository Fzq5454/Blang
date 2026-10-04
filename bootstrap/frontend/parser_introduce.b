#once
!~
 ~  bootstrap/frontend/parser_introduce.b: the frontend/parser_introduce.
 ~
 ~  `introduce TYPENAME T, int N, TEMPLATE C { ... }` declares a block of templated
 ~  functions - and generic structs, which `type` reads inside such a block. The
 ~  three kinds of parameter are the `template <typename T, int N, template
 ~  <typename> class C>` trio, spelled without angle brackets.
 ~
 ~  The functions parsed inside the block are not ordinary ones: they are stored as
 ~  templates and monomorphized at their call sites, so they are taken out of the
 ~  statement list the toolchain keeps and put in `template_funcs`. Here the statements of
 ~  the block are answered one by one, and a FUNCTION that is not broken becomes a
 ~  template instead of being linked in.
 ~!

#head "parser"

@StmtNode p_introduce {
    p_adv();
    @StrNode tparams = null;
    @StrNode type_param_names = null;
    @StrNode value_param_names = null;
    @StrNode template_param_names = null;
    @BoolNode tparam_is_value = null;
    @BoolNode tparam_is_template = null;
    @VarTypeNode tparam_types = null;
    !!! `TYPENAME Y...`: a pack, which takes a variable number of the
    !!! instantiation's type arguments instead of exactly one. `ARGS A...` names an
    !!! argument pack instead: it binds no type argument, it is the pack a template
    !!! function's parameter list is expanded from.
    @BoolNode tparam_is_pack = null;
    @StrNode arg_pack_names = null;

    while true {
        if p_is_kw("TYPENAME") {
            p_adv();
            if !p_is(TK_IDENT) {
                p_error_cur("missing type parameter name after TYPENAME");
                return null;
            }
            str nm = span_text(p_cur.start, p_cur.stop);
            tparams = p_chain_str(tparams, p_new_name(nm, p_cur.line, p_cur.col));
            type_param_names = p_chain_str(type_param_names, p_new_name(nm, p_cur.line, p_cur.col));
            tparam_is_value = p_chain_bool(tparam_is_value, p_new_bool(false));
            tparam_is_template = p_chain_bool(tparam_is_template, p_new_bool(false));
            tparam_types = p_chain_type(tparam_types, p_new_type(INT));
            p_adv();
            bool pack = false;
            if p_is(TK_ELLIPSIS) {
                pack = true;
                p_adv();
            }
            tparam_is_pack = p_chain_bool(tparam_is_pack, p_new_bool(pack));
        } else if p_is_kw("ARGS") {
            !!! `ARGS A...`: the pack of arguments a template function's parameter
            !!! list expands from. It names no type argument, so it is not part of
            !!! the template's type parameter list.
            p_adv();
            if !p_is(TK_IDENT) {
                p_error_cur("missing argument pack name after ARGS");
                return null;
            }
            str apn = span_text(p_cur.start, p_cur.stop);
            arg_pack_names = p_chain_str(arg_pack_names, p_new_name(apn, p_cur.line, p_cur.col));
            p_adv();
            if !p_is(TK_ELLIPSIS) {
                p_error_cur("ARGS needs '...' after the name");
                return null;
            }
            p_adv();
        } else if p_is_kw("TEMPLATE") {
            p_adv();
            if !p_is(TK_IDENT) {
                p_error_cur("missing template parameter name after TEMPLATE");
                return null;
            }
            str nm2 = span_text(p_cur.start, p_cur.stop);
            tparams = p_chain_str(tparams, p_new_name(nm2, p_cur.line, p_cur.col));
            template_param_names = p_chain_str(template_param_names,
                                               p_new_name(nm2, p_cur.line, p_cur.col));
            tparam_is_value = p_chain_bool(tparam_is_value, p_new_bool(false));
            tparam_is_template = p_chain_bool(tparam_is_template, p_new_bool(true));
            tparam_types = p_chain_type(tparam_types, p_new_type(INT));
            p_adv();
            bool pack2 = false;
            if p_is(TK_ELLIPSIS) {
                pack2 = true;
                p_adv();
            }
            tparam_is_pack = p_chain_bool(tparam_is_pack, p_new_bool(pack2));
        } else if p_is_kw("int") || p_is_kw("bool") || p_is_kw("char") ||
                  p_is_kw("float") || p_is_kw("str") {
            VarType vt = p_type();
            if !p_is(TK_IDENT) {
                p_error_cur("missing value parameter name");
                return null;
            }
            str nm3 = span_text(p_cur.start, p_cur.stop);
            tparams = p_chain_str(tparams, p_new_name(nm3, p_cur.line, p_cur.col));
            tparam_is_value = p_chain_bool(tparam_is_value, p_new_bool(true));
            tparam_is_template = p_chain_bool(tparam_is_template, p_new_bool(false));
            tparam_types = p_chain_type(tparam_types, p_new_type(vt));
            value_param_names = p_chain_str(value_param_names,
                                            p_new_name(nm3, p_cur.line, p_cur.col));
            p_adv();
            bool pack3 = false;
            if p_is(TK_ELLIPSIS) {
                pack3 = true;
                p_adv();
            }
            tparam_is_pack = p_chain_bool(tparam_is_pack, p_new_bool(pack3));
        } else {
            skip;
        }
        if p_is(TK_COMMA) {
            p_adv();
        } else {
            skip;
        }
    }
    if !p_is(TK_LBRACE) {
        p_error_cur("missing '{' after introduce type parameters");
        return null;
    }
    p_adv();

    !!! The parameters in scope while the body is read. Only TYPENAME entries are
    !!! types; a value parameter like `int N` is an ordinary identifier inside the
    !!! body - but it may be used as a constant template argument (`f(N - 1)()`), so
    !!! it is tracked as well.
    @StrNode saved_type = p_cur_type_params;
    @StrNode saved_val = p_cur_value_params;
    @StrNode saved_tmpl = p_cur_template_params;
    @StrNode saved_all = p_cur_tparams;
    @BoolNode saved_all_v = p_cur_tparam_is_value;
    @BoolNode saved_all_t = p_cur_tparam_is_template;
    @VarTypeNode saved_all_ty = p_cur_tparam_types;
    @StrNode saved_arg_packs = p_cur_arg_packs;
    p_cur_type_params = type_param_names;
    p_cur_value_params = value_param_names;
    p_cur_template_params = template_param_names;
    p_cur_tparams = tparams;
    p_cur_tparam_is_value = tparam_is_value;
    p_cur_tparam_is_template = tparam_is_template;
    p_cur_tparam_types = tparam_types;
    p_cur_arg_packs = arg_pack_names;
    p_in_introduce = p_in_introduce + 1;

    while !p_is(TK_EOF) && !p_is(TK_RBRACE) {
        int saved = p_pos;
        @StmtNode fn = parse_stmt();
        if !p_at_stmt_boundary() {
            p_sync();
        }
        if p_pos == saved {
            p_adv();
        }
        !!! A function inside the block is a template and not an ordinary function:
        !!! it is kept in the template table under its name, and the call site that
        !!! instantiates it finds it there. A generic `type` inside the block was
        !!! already stored as a template by the struct parser.
        if fn != null && fn.nk == FUNCTION && !fn.broken {
            @TemplateFunc tf;
            TemplateFunc proto;
            malloc(@tf, size proto);
            tf.tparams = tparams;
            tf.tparam_is_value = tparam_is_value;
            tf.tparam_types = tparam_types;
            tf.tparam_is_template = tparam_is_template;
            tf.tparam_is_pack = tparam_is_pack;
            tf.fn = fn;
            tf.next = p_template_funcs;
            p_template_funcs = tf;
        }
    }
    p_in_introduce = p_in_introduce - 1;
    p_cur_type_params = saved_type;
    p_cur_value_params = saved_val;
    p_cur_template_params = saved_tmpl;
    p_cur_tparams = saved_all;
    p_cur_tparam_is_value = saved_all_v;
    p_cur_tparam_is_template = saved_all_t;
    p_cur_tparam_types = saved_all_ty;
    p_cur_arg_packs = saved_arg_packs;

    if !p_is(TK_RBRACE) {
        p_error_cur("missing '}'");
        return null;
    }
    p_adv();
    return null;
}
