#once
!~
 ~  bootstrap/frontend/rgen_register.b: the frontend/rgen_register - the
 ~  function and BLANG_API registration (arity, parameter types, defaults, the
 ~  `stub` prototypes, the `reload` overload sets) and the generated wrappers of the
 ~  converting constructors.
 ~
 ~  A converting constructor `init T -> int v { ... }` declares the method
 ~  `op_init_int`, which fills `this`. Every conversion site (`T x = 5;`, `x = 5;`, a
 ~  `T` parameter called with `5`) calls a *generated* function instead, which
 ~  declares the object, runs the constructor on it and returns it as an ordinary
 ~  struct value - so the declaration, the assignment and the argument machinery all
 ~  handle a conversion with no special case of their own.
 ~
 ~  The per-statement half of register_funcs() is rg_register_funcs_stmt, declared by
 ~  the stub in rgen_walk.b (which has to stand before this module) and called by
 ~  rg_walk_stmts with action 1.
 ~!

#head "rgen"
#head "attributes"

!!! The local helpers below are used before their definitions.
stub str rgr_type_text -> VarType t, str sname;
stub int rgr_vt_n -> @VarTypeNode head;
stub VarType rgr_vt_at -> @VarTypeNode head, int i;
stub bool rgr_vt_same -> @VarTypeNode a, @VarTypeNode b;
stub bool rgr_str_same -> @StrNode a, @StrNode b;

!!! Reduce a type spelling to the characters an identifier may hold.
str rgr_ident_safe -> str s {
    str out = "";
    int i = 0;
    while i < pe_len(s) {
        char c = s[i];
        bool word = (c >= '0' && c <= '9') || (c >= 'a' && c <= 'z') ||
                    (c >= 'A' && c <= 'Z') || c == '_';
        if word {
            out = out + char_text(c);
        } else {
            out = out + "_";
        }
        i = i + 1;
    }
    return out;
}

!!! Name of the generated function of one constructor (`__ctor_long_int`) and of the
!!! local object it builds (`__cr_long`).
str rgr_wrapper_name -> str stype, str tag {
    return rgr_ident_safe("__ctor_" + stype + "_" + tag);
}

str rgr_local_name -> str stype {
    return rgr_ident_safe("__cr_" + stype);
}

!!! Body of that function: declare a local object of the type, call the constructor
!!! method on it and hand it back. The parameters are renamed, so a name written in
!!! the constructor cannot shadow a variable of the including program while the
!!! generated body is checked.
@StmtNode rgr_make_ctor_wrapper -> str stype, str mname, str wname, @StmtNode ctor {
    str obj_name = rgr_local_name(stype);
    @StmtNode w = p_new_stmt(FUNCTION);
    w.line = ctor.line;
    w.col = ctor.col;
    w.var_line = ctor.var_line;
    w.var_col = ctor.var_col;
    w.var_name = wname;
    !!! A struct return is carried by ret_struct, so the type is INT here.
    w.func_ret_type = INT;
    w.ret_struct = stype;
    w.ret_type_line = ctor.line;
    w.ret_type_col = ctor.col;
    w.ret_type_len = pe_len(stype);
    @StrNode pnames = null;
    int np = rgr_vt_n(ctor.fparam_types);
    int i = 0;
    while i < np {
        str pn = "__cp" + (str)(i + 1);
        pnames = rg_strchain_append(pnames, pn);
        w.fparams = rg_strchain_append(w.fparams, pn);
        w.fparam_types = rg_vartypechain_append(w.fparam_types, rgr_vt_at(ctor.fparam_types, i));
        str ps = "";
        @StrNode psn = rgr_str_at(ctor.fparam_struct, i);
        if psn != null {
            ps = psn.s;
        }
        w.fparam_struct = rg_strchain_append(w.fparam_struct, ps);
        i = i + 1;
    }

    @StmtNode obj = p_new_stmt(DECLARE);
    obj.line = ctor.line;
    obj.col = ctor.col;
    obj.var_line = ctor.line;
    obj.var_col = ctor.col;
    obj.var_name = obj_name;
    obj.decl_type = INT;
    obj.struct_type = stype;
    w.true_body = p_chain_stmt(w.true_body, obj);

    @StmtNode call = p_new_stmt(CALL_FUNC);
    call.line = ctor.line;
    call.col = ctor.col;
    call.var_line = ctor.var_line;
    call.var_col = ctor.var_col;
    call.var_name = mname;
    call.is_method_call = true;
    @ExprNode self = p_new_expr(VAR_REF);
    self.var_name = obj_name;
    self.line = ctor.line;
    self.col = ctor.col;
    call.args = p_chain_expr(call.args, self);
    call.nargs = 1;
    @StrNode pn2 = pnames;
    while pn2 != null {
        @ExprNode arg = p_new_expr(VAR_REF);
        arg.var_name = pn2.s;
        arg.line = ctor.line;
        arg.col = ctor.col;
        call.args = p_chain_expr(call.args, arg);
        call.nargs = call.nargs + 1;
        pn2 = pn2.next;
    }
    w.true_body = p_chain_stmt(w.true_body, call);

    @StmtNode ret = p_new_stmt(RETURN);
    ret.line = ctor.line;
    ret.col = ctor.col;
    @ExprNode backref = p_new_expr(VAR_REF);
    backref.var_name = obj_name;
    backref.line = ctor.line;
    backref.col = ctor.col;
    ret.expr = backref;
    w.true_body = p_chain_stmt(w.true_body, ret);
    return w;
}

int rgr_vt_n -> @VarTypeNode head {
    int n = 0;
    @VarTypeNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

VarType rgr_vt_at -> @VarTypeNode head, int i {
    int k = 0;
    @VarTypeNode e = head;
    while e != null {
        if k == i {
            return e.ty;
        }
        k = k + 1;
        e = e.next;
    }
    return VOID;
}

@StrNode rgr_str_at -> @StrNode head, int i {
    int k = 0;
    @StrNode e = head;
    while e != null {
        if k == i {
            return e;
        }
        k = k + 1;
        e = e.next;
    }
    return null;
}

@BoolNode rgr_bool_at -> @BoolNode head, int i {
    int k = 0;
    @BoolNode e = head;
    while e != null {
        if k == i {
            return e;
        }
        k = k + 1;
        e = e.next;
    }
    return null;
}

int rgr_str_n -> @StrNode head {
    int n = 0;
    @StrNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

int rgr_bool_n -> @BoolNode head {
    int n = 0;
    @BoolNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

int rgr_int_n -> @IntNode head {
    int n = 0;
    @IntNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

int rgr_int_at -> @IntNode head, int i {
    int k = 0;
    @IntNode e = head;
    while e != null {
        if k == i {
            return e.v;
        }
        k = k + 1;
        e = e.next;
    }
    return 0;
}

@StructMethod rgr_structmethod_add -> @StructMethod head, @StructMethod node {
    if head == null {
        return node;
    }
    @StructMethod t = head;
    while t.next != null {
        t = t.next;
    }
    t.next = node;
    return head;
}

@OverloadVersion rgr_ver_new -> @StmtNode f {
    OverloadVersion proto;
    @OverloadVersion v;
    malloc(@v, size proto);
    v.internal_name = f.var_name;
    v.param_types = f.fparam_types;
    v.param_structs = f.fparam_struct;
    v.arity = rgr_str_n(f.fparams);
    v.variadic = f.variadic;
    v.next = null;
    return v;
}

!!! `func_overloads[name].push_back(version)`: the version is added at the end of the
!!! name's set, so the first declaration stays the first version.
void rgr_overload_add -> str name, @StmtNode f {
    @RgOverloadMap it = rg_overloadmap_find(rg_func_overloads, name);
    if it == null {
        rg_func_overloads = rg_overloadmap_set(rg_func_overloads, name, rgr_ver_new(f), 1);
        end;
    }
    it.versions = rg_overloadver_append(it.versions, rgr_ver_new(f));
    it.n = it.n + 1;
}

void rgr_method_overload_add -> str key, @StmtNode f {
    @RgOverloadMap it = rg_overloadmap_find(rg_method_overloads, key);
    if it == null {
        rg_method_overloads = rg_overloadmap_set(rg_method_overloads, key, rgr_ver_new(f), 1);
        end;
    }
    it.versions = rg_overloadver_append(it.versions, rgr_ver_new(f));
    it.n = it.n + 1;
}

!!! Whether one version of a name has this exact parameter list (a redefinition, not
!!! a second overload).
bool rgr_same_params -> @OverloadVersion v, @StmtNode s {
    @OverloadVersion e = v;
    while e != null {
        if e.arity == rgr_str_n(s.fparams) && e.variadic == s.variadic {
            if rgr_vt_same(e.param_types, s.fparam_types) && rgr_str_same(e.param_structs, s.fparam_struct) {
                return true;
            }
        }
        e = e.next;
    }
    return false;
}

bool rgr_vt_same -> @VarTypeNode a, @VarTypeNode b {
    @VarTypeNode x = a;
    @VarTypeNode y = b;
    while x != null && y != null {
        if x.ty != y.ty {
            return false;
        }
        x = x.next;
        y = y.next;
    }
    return x == null && y == null;
}

bool rgr_str_same -> @StrNode a, @StrNode b {
    @StrNode x = a;
    @StrNode y = b;
    while x != null && y != null {
        if !p_text_eq(x.s, y.s) {
            return false;
        }
        x = x.next;
        y = y.next;
    }
    return x == null && y == null;
}

!!! One generated function per converting constructor, placed right after the type
!!! definition so the constructor method it calls comes first.
!!! One declaration of the statement list, and what `attribute` says about it.
!!!
!!! A `NOWARN` function contributes the line range its warnings are dropped in (see
!!! `attr_in_nowarn`), and a type attribute (`INT`, `STR`, ...) becomes the type of
!!! the declaration when the declaration does not say one - an `any` object, or a
!!! function a `.bmeta` gave no type for. A declaration that already says something
!!! else is reported rather than quietly rewritten, and a struct cannot be given a
!!! scalar type at all. the `RGenerator::apply_attributes` is the same step.
!!! The statement list is walked twice (the wrapper pass runs before the template
!!! instantiation and again after it), so the one diagnostic an attribute can make is
!!! reported the first time only: applying what it says again costs nothing.
@RgStrSet rg_attr_err_seen;

bool rgx_attr_err_once -> int line, int col {
    str key = (str)line + ":" + (str)col;
    if rg_set_has(rg_attr_err_seen, key) {
        return false;
    }
    rg_attr_err_seen = rg_set_add(rg_attr_err_seen, key);
    return true;
}

!!! Whether an attribute of the source names this declaration from below it: such an
!!! attribute is not applied, the way the toolchain returns from apply_object() without
!!! applying what it says. The diagnostic itself is made by rg_apply_attr_checks
!!! (rgen_declare.b), which asks the same question before this pass runs.
bool rgx_attr_order_check -> @StmtNode s {
    if s.var_name == "" {
        return false;
    }
    str shown = rg_display_name(s.var_name);
    int dline = s.var_line;
    if dline == 0 {
        dline = s.line;
    }
    @AttrUse u = attr_uses;
    while u != null {
        if u.member == "" && pe_eq(u.object, shown) && dline > u.line {
            return true;
        }
        u = u.next;
    }
    return false;
}

void rg_apply_attr_decl -> @StmtNode s {
    if s == null {
        end;
    }
    !!! A rule and an attribute speak about the declarations above them, so one that
    !!! names a declaration written below it is reported rather than applied. The
    !!! compares the position of the declaration it found for the name
    !!! (`by_name`) with the position of the attribute; here the statement itself is
    !!! that declaration, so its own position is compared.
    if rgx_attr_order_check(s) {
        end;
    }
    if s.nk == FUNCTION && attr_has_effect(s.var_name, ATTR_EFFECT_NOWARN) {
        int hi = s.end_line;
        if hi == 0 {
            hi = s.line;
        }
        attr_range_add(s.line, hi);
    }
    @AttrUse tu = attr_type_use_of(s.var_name);
    if tu == null {
        end;
    }
    VarType ty = attr_type_of(tu.name);
    bool uns = attr_is_unsigned(tu.name);
    if s.nk == FUNCTION {
        if s.ret_struct != "" {
            if rgx_attr_err_once(tu.line, tu.col) {
                rg_fmt_err(tu.line, tu.col, "a type attribute cannot be used on a struct '" +
                           s.ret_struct + "'", tu.len, (str)null, 0, true);
            }
            rg_has_errors = true;
            end;
        }
        if s.func_ret_type != ANY && s.func_ret_type != ty {
            if rgx_attr_err_once(tu.line, tu.col) {
                rg_fmt_err(tu.line, tu.col, "type attribute '" + tu.name +
                           "' does not match the declared type of '" + s.var_name + "'",
                           tu.len, (str)null, 0, true);
            }
            rg_has_errors = true;
            end;
        }
        s.func_ret_type = ty;
        s.ret_is_unsigned = uns;
        end;
    }
    if s.nk == DECLARE {
        if s.struct_type != "" {
            if rgx_attr_err_once(tu.line, tu.col) {
                rg_fmt_err(tu.line, tu.col, "a type attribute cannot be used on a struct '" +
                           s.struct_type + "'", tu.len, (str)null, 0, true);
            }
            rg_has_errors = true;
            end;
        }
        if s.decl_type != ANY && s.decl_type != ty {
            if rgx_attr_err_once(tu.line, tu.col) {
                rg_fmt_err(tu.line, tu.col, "type attribute '" + tu.name +
                           "' does not match the declared type of '" + s.var_name + "'",
                           tu.len, (str)null, 0, true);
            }
            rg_has_errors = true;
            end;
        }
        s.decl_type = ty;
        s.decl_is_unsigned = uns;
    }
}

@StmtNode rg_materialize_ctor_wrappers -> @StmtNode stmts {
    @StmtNode out = null;
    @StmtNode out_tail = null;
    @StmtNode s = stmts;
    while s != null {
        @StmtNode nx = s.next;
        s.next = null;
        if out == null {
            out = s;
        } else {
            out_tail.next = s;
        }
        out_tail = s;
        !!! What `attribute` says about this declaration, applied while the statement
        !!! list is walked for the first time: the type of a declaration that does not
        !!! say one, and the line range whose warnings a `NOWARN` function asked not
        !!! to hear. the `RGenerator::apply_attributes` is the same step.
        rg_apply_attr_decl(s);
        if s.nk == STRUCT_DEF {
            @StructDef sd = p_find_struct(s.var_name);
            if sd != null {
                @StructMethod m = sd.methods;
                while m != null {
                    bool do_it = true;
                    if m.ctor_from == "" || m.fn == null {
                        do_it = false;
                    }
                    if m.ctor_func != "" {
                        !!! Already generated.
                        do_it = false;
                    }
                    if do_it && rgr_vt_n(m.fn.fparam_types) != rgr_str_n(m.fn.fparams) {
                        do_it = false;
                    }
                    if do_it {
                        m.ctor_func = rgr_wrapper_name(s.var_name, m.ctor_from);
                        @StmtNode w = rgr_make_ctor_wrapper(s.var_name, m.name, m.ctor_func, m.fn);
                        w.next = null;
                        if out_tail == null {
                            out = w;
                        } else {
                            out_tail.next = w;
                        }
                        out_tail = w;
                        !!! The generated function takes part in every later pass like a
                        !!! written one, so it is registered here.
                        int nfp = rgr_str_n(w.fparams);
                        rg_func_arity = rg_intmap_set(rg_func_arity, w.var_name, nfp);
                        rg_func_param_types = rg_vartypelistmap_set(rg_func_param_types, w.var_name,
                                                                    w.fparam_types,
                                                                    rgr_vt_n(w.fparam_types));
                        rg_func_param_struct = rg_strlistmap_set(rg_func_param_struct, w.var_name,
                                                                 w.fparam_struct,
                                                                 rgr_str_n(w.fparam_struct));
                        rg_func_param_names = rg_strlistmap_set(rg_func_param_names, w.var_name,
                                                                w.fparams, nfp);
                        rg_func_variadic = rg_boolmap_set(rg_func_variadic, w.var_name, false);
                        rg_func_ret_struct = rg_strmap_set(rg_func_ret_struct, w.var_name, w.ret_struct);
                        rg_func_decl_pos = rg_posmap_set(rg_func_decl_pos, w.var_name, w.line, w.col);
                        !!! The definition position, so register_funcs skips this function when it
                        !!! walks the statements again: it is already registered.
                        int dl = w.var_line;
                        if dl == 0 {
                            dl = w.line;
                        }
                        lex_get_source(dl);
                        rg_func_decl_file = rg_strmap_set(rg_func_decl_file, w.var_name, g_src_file);
                        rg_func_decl_line = rg_intmap_set(rg_func_decl_line, w.var_name, g_src_line);
                        if rg_vartypemap_find(rg_syms, w.var_name) == null {
                            rg_syms = rg_vartypemap_set(rg_syms, w.var_name, w.func_ret_type);
                        }
                        rgr_overload_add(w.var_name, w);
                        str lname = rgr_local_name(s.var_name);
                        if rg_vartypemap_find(rg_syms, lname) == null {
                            rg_syms = rg_vartypemap_set(rg_syms, lname, INT);
                            rg_sym_depth = rg_intmap_set(rg_sym_depth, lname, 0);
                            rg_sym_struct_type = rg_strmap_set(rg_sym_struct_type, lname, s.var_name);
                        }
                        rg_non_global_syms = rg_set_add(rg_non_global_syms, lname);
                    }
                    m = m.next;
                }
            }
        }
        s = nx;
    }
    return out;
}

!!! A definition is only accepted as the implementation of a `stub` prototype when
!!! its whole signature is the one that was declared. The answer says whether one
!!! differs, and the record is left in rg_stub_proto_mismatch_out with the source
!!! position of both sides.
bool rg_stub_proto_mismatch -> @StubProto p, @StmtNode s {
    StubMismatch proto;
    @StubMismatch m;
    malloc(@m, size proto);
    m.is_return = false;
    m.param = 0;
    m.param_name = "";
    m.proto_type = "";
    m.impl_type = "";
    m.impl_line = 0;
    m.impl_col = 0;
    m.impl_len = 0;
    m.proto_line = 0;
    m.proto_col = 0;
    m.proto_len = 0;
    rg_stub_proto_mismatch_out = m;
    if p.ret_type != s.func_ret_type || !p_text_eq(p.ret_struct, s.ret_struct) {
        m.is_return = true;
        m.proto_type = rgr_type_text(p.ret_type, p.ret_struct);
        m.impl_type = rgr_type_text(s.func_ret_type, s.ret_struct);
        m.impl_line = s.ret_type_line;
        m.impl_col = s.ret_type_col;
        m.impl_len = s.ret_type_len;
        m.proto_line = p.ret_type_line;
        m.proto_col = p.ret_type_col;
        m.proto_len = p.ret_type_len;
        return true;
    }
    int np = rgr_vt_n(s.fparam_types);
    int i = 0;
    while i < np {
        bool missing = (i >= rgr_vt_n(p.param_types));
        VarType pt = VOID;
        if !missing {
            pt = rgr_vt_at(p.param_types, i);
        }
        str psn = "";
        @StrNode ps = rgr_str_at(p.param_structs, i);
        if ps != null {
            psn = ps.s;
        }
        str ssn = "";
        @StrNode ss = rgr_str_at(s.fparam_struct, i);
        if ss != null {
            ssn = ss.s;
        }
        bool differs = false;
        if missing || pt != rgr_vt_at(s.fparam_types, i) || !p_text_eq(psn, ssn) {
            differs = true;
        }
        if !differs && i < rgr_bool_n(p.param_is_array) && i < rgr_bool_n(s.fparam_is_array) {
            @BoolNode a1 = rgr_bool_at(p.param_is_array, i);
            @BoolNode a2 = rgr_bool_at(s.fparam_is_array, i);
            if a1.v != a2.v {
                differs = true;
            }
        }
        if !differs && i < rgr_bool_n(p.param_is_ref) && i < rgr_bool_n(s.fparam_is_ref) {
            @BoolNode r1 = rgr_bool_at(p.param_is_ref, i);
            @BoolNode r2 = rgr_bool_at(s.fparam_is_ref, i);
            if r1.v != r2.v {
                differs = true;
            }
        }
        if differs {
            m.param = i;
            if missing {
                m.proto_type = "void";
            } else {
                m.proto_type = rgr_type_text(pt, psn);
            }
            m.impl_type = rgr_type_text(rgr_vt_at(s.fparam_types, i), ssn);
                m.impl_line = s.var_line;
                m.impl_col = s.var_col;
                m.impl_len = pe_len(s.var_name);
            if i < rgr_int_n(p.ptype_lines) {
                m.proto_line = rgr_int_at(p.ptype_lines, i);
                m.proto_col = rgr_int_at(p.ptype_cols, i);
                m.proto_len = rgr_int_at(p.ptype_lens, i);
            } else {
                m.proto_line = p.line;
                m.proto_col = p.col;
                m.proto_len = p.len;
            }
            @StrNode pname = rgr_str_at(s.fparams, i);
            if pname != null {
                m.param_name = pname.s;
            }
            return true;
        }
        i = i + 1;
    }
    if p.variadic != s.variadic {
        m.param = np;
        m.proto_type = "(not variadic)";
        if p.variadic {
            m.proto_type = "...";
        }
        m.impl_type = "(not variadic)";
        if s.variadic {
            m.impl_type = "...";
        }
        m.impl_line = s.var_line;
        m.impl_col = s.var_col;
        m.impl_len = pe_len(s.var_name);
        m.proto_line = p.line;
        m.proto_col = p.col;
        m.proto_len = p.len;
        return true;
    }
    return false;
}

str rgr_type_text -> VarType t, str sname {
    if sname != "" {
        return sname;
    }
    return rg_type_name(t);
}

@StubProto rgr_stub_proto_new -> @StmtNode s, str orig_name {
    StubProto proto;
    @StubProto sp;
    malloc(@sp, size proto);
    sp.ret_type = s.func_ret_type;
    sp.ret_struct = s.ret_struct;
    sp.param_types = s.fparam_types;
    sp.param_structs = s.fparam_struct;
    sp.param_is_array = s.fparam_is_array;
    sp.param_is_ref = s.fparam_is_ref;
    sp.variadic = s.variadic;
    sp.line = s.var_line;
    if sp.line == 0 {
        sp.line = s.line;
    }
    sp.col = s.var_col;
    if sp.col == 0 {
        sp.col = s.col;
    }
    sp.len = pe_len(orig_name);
    sp.ret_type_line = s.ret_type_line;
    sp.ret_type_col = s.ret_type_col;
    sp.ret_type_len = s.ret_type_len;
        sp.ptype_lines = null;
        sp.ptype_cols = null;
        sp.ptype_lens = null;
    return sp;
}

!!! The name the source wrote, with where it stands: `var_line` when the parser set
!!! it, `line` otherwise.
int rgr_at_line -> @StmtNode s {
    int l = s.var_line;
    if l == 0 {
        l = s.line;
    }
    return l;
}

int rgr_at_col -> @StmtNode s {
    int c = s.var_col;
    if c == 0 {
        c = s.col;
    }
    return c;
}

!!! The per-statement half of register_funcs(), called by rg_walk_stmts with the
!!! action selector 1.
void rg_register_funcs_stmt -> @StmtNode s {
    if s.nk == FUNCTION {
        if s.broken {
            end;
        }
        str orig_name = s.var_name;
        !!! A `stub` first, because it is the declaration: the prototype a later
        !!! definition has to match is recorded here, and the name is made callable
        !!! right away. Registering that only along the definition path made a call
        !!! written before the definition an "undeclared function", which is what any
        !!! pair of functions that call each other needs.
        if s.is_stub {
            rg_stub_protos = rg_stubmap_set(rg_stub_protos, orig_name,
                                            rgr_stub_proto_new(s, orig_name));
            int nfp = rgr_str_n(s.fparams);
            rg_func_arity = rg_intmap_set(rg_func_arity, s.var_name, nfp);
            rg_func_param_types = rg_vartypelistmap_set(rg_func_param_types, s.var_name,
                                                        s.fparam_types, rgr_vt_n(s.fparam_types));
            rg_func_param_struct = rg_strlistmap_set(rg_func_param_struct, s.var_name,
                                                     s.fparam_struct, rgr_str_n(s.fparam_struct));
            rg_func_param_is_array = rg_boollistmap_set(rg_func_param_is_array, s.var_name,
                                                        s.fparam_is_array,
                                                        rgr_bool_n(s.fparam_is_array));
            rg_func_param_is_ref = rg_boollistmap_set(rg_func_param_is_ref, s.var_name,
                                                      s.fparam_is_ref,
                                                      rgr_bool_n(s.fparam_is_ref));
            rg_func_param_is_unsigned = rg_boollistmap_set(rg_func_param_is_unsigned, s.var_name,
                                                           s.fparam_is_unsigned,
                                                           rgr_bool_n(s.fparam_is_unsigned));
            rg_func_ret_is_unsigned = rg_boolmap_set(rg_func_ret_is_unsigned, s.var_name,
                                                     s.ret_is_unsigned);
            rg_func_variadic = rg_boolmap_set(rg_func_variadic, s.var_name, s.variadic);
            rg_func_param_names = rg_strlistmap_set(rg_func_param_names, s.var_name, s.fparams, nfp);
            rg_func_param_defaults = rg_exprlistmap_set(rg_func_param_defaults, s.var_name,
                                                        rg_exprref_of(s.fparam_defaults));
            rg_func_ret_struct = rg_strmap_set(rg_func_ret_struct, s.var_name, s.ret_struct);
            rg_func_decl_line = rg_intmap_set(rg_func_decl_line, s.var_name, rgr_at_line(s));
            rg_func_decl_pos = rg_posmap_set(rg_func_decl_pos, s.var_name, rgr_at_line(s),
                                             rgr_at_col(s));
            end;
        }
        !!! A definition written as `pkg::func { ... }` implements the function that
        !!! package declared: it registers under the member's internal name, and the
        !!! prototype check below still applies.
        if !s.is_stub && !s.is_reload {
            @RgPkgMap pmit = rg_pkgmap_find(rg_pkg_members, orig_name);
            if pmit != null && pmit.m.member_kind == 1 {
                s.var_name = pmit.m.internal;
                !!! Diagnostics must name the member the way the source did
                !!! (`mypkg::get3`), not the internal `mypkg__get3`.
                rg_display_names = rg_strmap_set(rg_display_names, s.var_name, orig_name);
            } else if pp_find_from(orig_name, "::", 0) >= 0 {
                !!! `pkg::name` for a package (or a member) that does not exist.
                str msg = "'" + orig_name + "' is not a member of any package";
                rg_fmt_err(rgr_at_line(s), rgr_at_col(s), msg, pe_len(orig_name), (str)null, 0, true);
                rg_has_errors = true;
                s.broken = true;
                end;
            }
        }
        if s.is_reload {
            !!! `reload` adds one more version of a function that already has a
            !!! prototype. On the first definition of a name there is no prototype to
            !!! reload, which is an error.
            if rg_intmap_find(rg_func_decl_line, orig_name) == null {
                str msg = "no prototype of function '" + orig_name + "'";
                int el = s.reload_line;
                if el == 0 {
                    el = rgr_at_line(s);
                }
                int ec = s.reload_col;
                if ec == 0 {
                    ec = rgr_at_col(s);
                }
                int hl = s.reload_len;
                if hl <= 0 {
                    hl = pe_len(orig_name);
                }
                rg_fmt_err(el, ec, msg, hl, (str)null, 0, true);
                rg_has_errors = true;
                s.broken = true;
                end;
            }
            @RgOverloadMap it = rg_overloadmap_find(rg_func_overloads, orig_name);
            if it != null && rgr_same_params(it.versions, s) {
                str msg = "redefinition of function '" + orig_name + "'";
                rg_fmt_err(rgr_at_line(s), rgr_at_col(s), msg, pe_len(orig_name), (str)null, 0, true);
                @RgPosMap pit = rg_posmap_find(rg_func_decl_pos, s.var_name);
                if pit != null {
                    rg_fmt_note(pit.a, pit.b, "previous definition is here", pe_len(orig_name));
                }
                rg_has_errors = true;
                s.broken = true;
                end;
            }
            !!! The version gets its own internal name; everything below registers it
            !!! like any other function.
            str mangled = rg_overload_mangle(s);
            rg_display_names = rg_strmap_set(rg_display_names, mangled, orig_name);
            s.var_name = mangled;
        }
        !!! A second definition of the same name is a redefinition - unless it is the
        !!! *same* definition at the *same* source position (a repeated `#head`
        !!! inclusion), or the earlier one was only a `stub` prototype and this is its
        !!! implementation.
        bool is_stub_impl = false;
        if rg_intmap_find(rg_func_decl_line, s.var_name) != null {
            lex_get_source(rgr_at_line(s));
            !!! The recorded declaration is read into locals first: a field of a call
            !!! result cannot be taken in one expression (the .r text would be
            !!! `(CALL_EXPR ...)_v`, which the backend cannot read).
            @RgStrMap df_rec = rg_strmap_find(rg_func_decl_file, s.var_name);
            str decl_file = "";
            if df_rec != null {
                decl_file = df_rec.v;
            }
            @RgIntMap dl_rec = rg_intmap_find(rg_func_decl_line, s.var_name);
            int decl_line = 0;
            if dl_rec != null {
                decl_line = dl_rec.v;
            }
            bool same_site = p_text_eq(g_src_file, decl_file) && g_src_line == decl_line;
            if same_site {
                !!! Already registered.
                end;
            }
            @RgStubMap spit = rg_stubmap_find(rg_stub_protos, s.var_name);
            if !s.is_stub && spit != null {
                !!! Implementation of a stub prototype: the signature must be the one
                !!! that was declared.
                if rg_stub_proto_mismatch(spit.proto, s) {
                    @StubMismatch mm = rg_stub_proto_mismatch_out;
                    str what = "parameter " + (str)(mm.param + 1);
                    if mm.is_return {
                        what = "return type";
                    } else if mm.param_name != "" {
                        what = "parameter " + (str)(mm.param + 1) + " '" + mm.param_name + "'";
                    }
                    str msg = what + " is '" + mm.impl_type + "', but the prototype declares '" +
                              mm.proto_type + "'";
                    int el = mm.impl_line;
                    if el == 0 {
                        el = rgr_at_line(s);
                    }
                    int ec = mm.impl_col;
                    if ec == 0 {
                        ec = rgr_at_col(s);
                    }
                    int hl = mm.impl_len;
                    if hl <= 0 {
                        hl = pe_len(orig_name);
                    }
                    rg_fmt_err(el, ec, msg, hl, (str)null, 0, true);
                    str what_note = "parameter " + (str)(mm.param + 1);
                    if mm.is_return {
                        what_note = "return type";
                    } else if mm.param_name != "" {
                        what_note = "parameter " + (str)(mm.param + 1) + " '" + mm.param_name + "'";
                    }
                    str nmsg = what_note + " declared here as '" + mm.proto_type + "'";
                    int nhl = mm.proto_len;
                    if nhl <= 0 {
                        nhl = pe_len(orig_name);
                    }
                    rg_fmt_note(mm.proto_line, mm.proto_col, nmsg, nhl);
                    rg_has_errors = true;
                    s.broken = true;
                    end;
                }
                !!! Matching prototype: this definition takes its place. The prototype
                !!! stays the recorded declaration, so calls written between the
                !!! prototype and the definition are not reported as forward references.
                rg_stub_protos = rg_stubmap_drop(rg_stub_protos, s.var_name);
                is_stub_impl = true;
            } else {
                str msg = "redefinition of function '" + orig_name + "'";
                rg_fmt_err(rgr_at_line(s), rgr_at_col(s), msg, pe_len(orig_name), (str)null, 0, true);
                @RgPosMap pit2 = rg_posmap_find(rg_func_decl_pos, s.var_name);
                if pit2 != null {
                    rg_fmt_note(pit2.a, pit2.b, "previous definition is here", pe_len(orig_name));
                }
                rg_has_errors = true;
                !!! The duplicate's body is skipped in the later passes, so it does not
                !!! produce follow-on errors against the first signature.
                s.broken = true;
                end;
            }
        }
        int nfp2 = rgr_str_n(s.fparams);
        rg_func_arity = rg_intmap_set(rg_func_arity, s.var_name, nfp2);
        rg_func_param_types = rg_vartypelistmap_set(rg_func_param_types, s.var_name,
                                                    s.fparam_types, rgr_vt_n(s.fparam_types));
        rg_func_param_struct = rg_strlistmap_set(rg_func_param_struct, s.var_name,
                                                 s.fparam_struct, rgr_str_n(s.fparam_struct));
        rg_func_param_is_array = rg_boollistmap_set(rg_func_param_is_array, s.var_name,
                                                    s.fparam_is_array,
                                                    rgr_bool_n(s.fparam_is_array));
        rg_func_param_is_ref = rg_boollistmap_set(rg_func_param_is_ref, s.var_name,
                                                  s.fparam_is_ref, rgr_bool_n(s.fparam_is_ref));
        rg_func_param_is_unsigned = rg_boollistmap_set(rg_func_param_is_unsigned, s.var_name,
                                                       s.fparam_is_unsigned,
                                                       rgr_bool_n(s.fparam_is_unsigned));
        rg_func_ret_is_unsigned = rg_boolmap_set(rg_func_ret_is_unsigned, s.var_name,
                                                 s.ret_is_unsigned);
        rg_func_variadic = rg_boolmap_set(rg_func_variadic, s.var_name, s.variadic);
        rg_func_param_names = rg_strlistmap_set(rg_func_param_names, s.var_name, s.fparams, nfp2);
        rg_func_param_defaults = rg_exprlistmap_set(rg_func_param_defaults, s.var_name,
                                                    rg_exprref_of(s.fparam_defaults));
        rg_func_ret_struct = rg_strmap_set(rg_func_ret_struct, s.var_name, s.ret_struct);
        !!! The declaration position, mapped to the original file and line. The
        !!! implementation of a `stub` prototype keeps the prototype's position: that
        !!! is where the function became declared.
        if !is_stub_impl {
            lex_get_source(rgr_at_line(s));
            rg_func_decl_file = rg_strmap_set(rg_func_decl_file, s.var_name, g_src_file);
            rg_func_decl_line = rg_intmap_set(rg_func_decl_line, s.var_name, g_src_line);
            rg_func_decl_pos = rg_posmap_set(rg_func_decl_pos, s.var_name, rgr_at_line(s),
                                             rgr_at_col(s));
        }
        if s.params_line > 0 {
            rg_func_params_pos = rg_posmap_set(rg_func_params_pos, s.var_name, s.params_line,
                                               s.params_col);
            rg_func_params_hl = rg_intmap_set(rg_func_params_hl, s.var_name, s.params_len);
        }
        !!! Allow recursive calls: the function name is added to syms, without
        !!! overwriting a variable of that name.
        if rg_vartypemap_find(rg_syms, s.var_name) == null {
            rg_syms = rg_vartypemap_set(rg_syms, s.var_name, s.func_ret_type);
        }
        int pi = 0;
        @StrNode p = s.fparams;
        while p != null {
            rg_non_global_syms = rg_set_add(rg_non_global_syms, p.s);
            @BoolNode arr = rgr_bool_at(s.fparam_is_array, pi);
            if arr != null && arr.v {
                rg_sym_is_array = rg_boolmap_set(rg_sym_is_array, p.s, true);
            }
            p = p.next;
            pi = pi + 1;
        }
        if s.is_stub {
            !!! The declared prototype is remembered: a later definition has to match
            !!! it, and a call that never gets one stays undefined.
            rg_stub_protos = rg_stubmap_set(rg_stub_protos, orig_name,
                                            rgr_stub_proto_new(s, orig_name));
        } else {
            rgr_overload_add(orig_name, s);
        }
        end;
    }
    if s.nk == BAPI {
        !!! Register the BLANG_API parameter names and defaults so call sites can fill
        !!! omitted trailing arguments from their default values.
        if s.broken {
            end;
        }
        rg_func_param_names = rg_strlistmap_set(rg_func_param_names, s.var_name, s.fparams,
                                                rgr_str_n(s.fparams));
        rg_func_param_defaults = rg_exprlistmap_set(rg_func_param_defaults, s.var_name,
                                                    rg_exprref_of(s.fparam_defaults));
    }
}

void rg_register_funcs {
    rg_walk_stmts(rg_stmts, 1);

    !!! `reload` methods: one more version of a method of the same type. The first
    !!! declaration of a name is the prototype a `reload` needs, and its own
    !!! parameters become the first version of the overload set.
    @StructDef sd = p_struct_defs;
    while sd != null {
        @StructMethod m = sd.methods;
        while m != null {
            @StmtNode f = m.fn;
            bool skip_it = false;
            if f == null || f.broken {
                skip_it = true;
            }
            if !skip_it {
                str base = m.name;
                str key = sd.name + char_text(1) + base;
                @RgOverloadMap versions = rg_overloadmap_find(rg_method_overloads, key);
                if f.is_reload {
                    int nver = 0;
                    if versions != null {
                        nver = versions.n;
                    }
                    if nver == 0 {
                        str msg = "no prototype of method '" + base + "' in type '" + sd.name + "'";
                        int el = f.reload_line;
                        if el == 0 {
                            el = rgr_at_line(f);
                        }
                        int ec = f.reload_col;
                        if ec == 0 {
                            ec = rgr_at_col(f);
                        }
                        rg_fmt_err(el, ec, msg, 6, (str)null, 0, true);
                        rg_has_errors = true;
                        f.broken = true;
                        skip_it = true;
                    } else if rgr_same_params(versions.versions, f) {
                        str msg = "redefinition of method '" + base + "' in type '" + sd.name + "'";
                        rg_fmt_err(rgr_at_line(f), rgr_at_col(f), msg, pe_len(base), (str)null, 0, true);
                        rg_has_errors = true;
                        f.broken = true;
                        skip_it = true;
                    } else {
                        str mname = rg_overload_mangle(f);
                        rg_display_names = rg_strmap_set(rg_display_names, mname, base);
                        f.var_name = mname;
                    }
                } else if f.var_name != "" {
                    rg_display_names = rg_strmap_set(rg_display_names, f.var_name, base);
                }
                if !skip_it {
                    rgr_method_overload_add(key, f);
                }
            }
            m = m.next;
        }
        sd = sd.next;
    }

    !!! A derived type that declares no comparison of its own inherits the body-less
    !!! one of its base. That comparison is generated per type, so the inherited one
    !!! would compare only the base fields: the derived type gets its own generated
    !!! version, which covers every field of the derived object. A fixed point over
    !!! the hierarchy also covers deeper derivations.
    int round = 0;
    while round < 8 {
        bool added = false;
        @StructDef d2 = p_struct_defs;
        while d2 != null {
            int si = 0;
            while si < 2 {
                str sym = "==";
                str nm = "op_eq";
                if si == 1 {
                    sym = "!=";
                    nm = "op_ne";
                }
                bool own = false;
                @StructMethod m2 = d2.methods;
                while m2 != null {
                    if p_text_eq(m2.name, nm) || (m2.fn != null && p_text_eq(m2.fn.var_name, nm)) {
                        own = true;
                        skip;
                    }
                    m2 = m2.next;
                }
                if !own {
                    @StmtNode proto_fn = null;
                    @StrNode b = d2.bases;
                    while b != null {
                        @StmtNode bm = rg_resolve_method_func(b.s, nm, true);
                        if bm != null && bm.synth_op != "" {
                            proto_fn = bm;
                            skip;
                        }
                        b = b.next;
                    }
                    if proto_fn != null {
                        @StmtNode f2 = p_new_stmt(FUNCTION);
                        f2.line = d2.line;
                        f2.col = d2.col;
                        f2.var_name = nm;
                        !!! The enclosing type.
                        f2.struct_type = d2.name;
                        f2.synth_op = sym;
                        f2.func_ret_type = proto_fn.func_ret_type;
                        f2.ret_struct = proto_fn.ret_struct;
                        f2.fparams = rg_strchain_append(f2.fparams, "b");
                        f2.fparam_types = rg_vartypechain_append(f2.fparam_types, INT);
                        f2.fparam_struct = rg_strchain_append(f2.fparam_struct, d2.name);
                        StructMethod proto3;
                        @StructMethod sm;
                        malloc(@sm, size proto3);
                        sm.name = nm;
                        sm.fn = f2;
                        sm.op = sym;
                        sm.ctor_from = "";
                        sm.ctor_func = "";
                        sm.next = null;
                        d2.methods = rgr_structmethod_add(d2.methods, sm);
                        added = true;
                    }
                }
                si = si + 1;
            }
            d2 = d2.next;
        }
        if !added {
            skip;
        }
        round = round + 1;
    }

    !!! Methods of one struct share a name space as well: a later definition would
    !!! silently replace the earlier one (the lookup takes the first). `reload`
    !!! versions have their own internal name, so they are compared by that name and
    !!! count as more versions of the same method instead.
    @RgStrSet reported = null;
    @StructDef d3 = p_struct_defs;
    while d3 != null {
        !!! The table is the struct's own: two types may declare the same method name.
        @RgIntMap seen_line = null;
        @RgIntMap seen_col = null;
        @StructMethod m3 = d3.methods;
        while m3 != null {
            if m3.fn != null && !m3.fn.broken {
                str iname = m3.fn.var_name;
                if iname == "" {
                    iname = m3.name;
                }
                @RgIntMap it3 = rg_intmap_find(seen_line, iname);
                if it3 == null {
                    seen_line = rg_intmap_set(seen_line, iname, rgr_at_line(m3.fn));
                    @RgIntMap cur_col = rg_intmap_find(seen_col, iname);
                    if cur_col == null {
                        seen_col = rg_intmap_set(seen_col, iname, rgr_at_col(m3.fn));
                    }
                } else {
                    int prev_line = it3.v;
                    int prev_col = rgr_at_col(m3.fn);
                    @RgIntMap pc = rg_intmap_find(seen_col, iname);
                    if pc != null {
                        prev_col = pc.v;
                    }
                    int er = rgr_at_line(m3.fn);
                    int ec = rgr_at_col(m3.fn);
                    str key = (str)er + ":" + (str)ec + ":" + iname;
                    !!! Each source definition is reported once (a generic struct is
                    !!! cloned per instantiation).
                    if !rg_set_has(reported, key) {
                        reported = rg_set_add(reported, key);
                        str msg = "redefinition of method '" + m3.name + "'";
                        rg_fmt_err(er, ec, msg, pe_len(m3.name), (str)null, 0, true);
                        rg_fmt_note(prev_line, prev_col, "previous definition is here",
                                    pe_len(m3.name));
                        rg_has_errors = true;
                    }
                }
            }
            m3 = m3.next;
        }
        d3 = d3.next;
    }
}

!!! The tag that names the store helper of one target type: `int`, `long`, `float`,
!!! `char`, `bool`, `str`, `at_<T>` for a pointer whose pointee is `<T>`, and the
!!! struct's own name for an object. Empty when an assignment to that type cannot be
!!! written as a value, which the caller reports. the `assign_helper_tag` is the
!!! same step.
str rg_assign_helper_tag -> @ExprNode target {
    if target == null {
        return "";
    }
    if target.struct_type != "" {
        return target.struct_type;
    }
    VarType t = target.result_type;
    if t == INT {
        return "int";
    }
    if t == LONG {
        return "long";
    }
    if t == FLOAT {
        return "float";
    }
    if t == CHAR {
        return "char";
    }
    if t == BOOL {
        return "bool";
    }
    if t == STR {
        return "str";
    }
    if t == AT_INT {
        return "at_int";
    }
    if t == AT_LONG {
        return "at_long";
    }
    if t == AT_FLOAT {
        return "at_float";
    }
    if t == AT_CHAR {
        return "at_char";
    }
    if t == AT_STR {
        return "at_str";
    }
    if t == AT_BOOL {
        return "at_bool";
    }
    if t == AT_VOID {
        return "at_void";
    }
    return "";
}

!!! The name of that function: `__asg_<tag>` and `__asg_<tag>_seq`. The tag of a
!!! struct is its own name, which may hold the characters of an instantiation
!!! (`Box(int)`), so it is made into an identifier the way a generated constructor's
!!! name is.
str rg_assign_helper_name -> @ExprNode target, bool seq {
    str tag = rg_assign_helper_tag(target);
    if pe_eq(tag, "") {
        return "";
    }
    str n = "__asg_" + rgr_ident_safe(tag);
    if seq {
        n = n + "_seq";
    }
    return n;
}

!!! The generated function of one store helper. `__asg_int` stores an int through a
!!! pointer and answers the value it stored; `__asg_int_seq` takes one more value it
!!! does not look at, which is where the inner assignment of `(a = 1) = 2` goes: the
!!! arguments of a call are evaluated right to left, so that one runs before the
!!! value that follows it. the `make_assign_helper` builds the same function.
@StmtNode rg_make_assign_helper -> str name, bool seq, @ExprNode target {
    str stype = target.struct_type;
    bool is_struct = stype != "";
    bool is_ptr = false;
    if !is_struct && rg_is_at_type(target.result_type) {
        is_ptr = true;
    }
    VarType value_type = target.result_type;
    if is_struct {
        value_type = INT;
    }
    @StmtNode w = p_new_stmt(FUNCTION);
    w.line = target.line;
    w.col = target.col;
    w.var_line = target.line;
    w.var_col = target.col;
    w.var_name = name;
    !!! A struct answer is carried by ret_struct, so the type is INT there.
    w.ret_struct = stype;
    w.func_ret_type = target.result_type;
    if is_struct {
        w.func_ret_type = INT;
    }
    w.ret_type_line = target.line;
    w.ret_type_col = target.col;
    w.ret_type_len = pe_len(name);
    !!! The destination: the address of the object the value is stored in. A pointer
    !!! target is addressed through a `@void`, which is the one spelling of "a
    !!! pointer to something" the two front ends share; the store's width comes from
    !!! the target's own type, which the value parameter carries.
    VarType dst_type = target.result_type;
    str dst_struct = "";
    if is_struct {
        dst_type = AT_VOID;
        dst_struct = stype;
    } else if is_ptr {
        dst_type = AT_VOID;
    } else if target.result_type == INT {
        dst_type = AT_INT;
    } else if target.result_type == LONG {
        dst_type = AT_LONG;
    } else if target.result_type == FLOAT {
        dst_type = AT_FLOAT;
    } else if target.result_type == CHAR {
        dst_type = AT_CHAR;
    } else if target.result_type == BOOL {
        dst_type = AT_BOOL;
    } else if target.result_type == STR {
        dst_type = AT_STR;
    }
    w.fparams = rg_strchain_append(w.fparams, "__a0");
    w.fparam_types = rg_vartypechain_append(w.fparam_types, dst_type);
    w.fparam_struct = rg_strchain_append(w.fparam_struct, dst_struct);
    w.fparams = rg_strchain_append(w.fparams, "__a1");
    w.fparam_types = rg_vartypechain_append(w.fparam_types, value_type);
    w.fparam_struct = rg_strchain_append(w.fparam_struct, stype);
    if seq {
        w.fparams = rg_strchain_append(w.fparams, "__a2");
        w.fparam_types = rg_vartypechain_append(w.fparam_types, value_type);
        w.fparam_struct = rg_strchain_append(w.fparam_struct, stype);
    }
    !!! the toolchain also records where each parameter name and type stands. this implementation
    !!! keeps no such chains, and a generated parameter is never pointed at by a
    !!! diagnostic, so there is nothing to record here.
    !!! The body: store the value where the address points, then answer it.
    @StmtNode store = p_new_stmt(DREF_ASSIGN);
    store.line = target.line;
    store.col = target.col;
    store.var_line = target.line;
    store.var_col = target.col;
    store.var_name = "__a0";
    @ExprNode val = p_new_expr(VAR_REF);
    val.line = target.line;
    val.col = target.col;
    val.var_name = "__a1";
    val.tok_len = 4;
    store.expr = val;
    w.true_body = p_chain_stmt(w.true_body, store);
    @StmtNode ret = p_new_stmt(RETURN);
    ret.line = target.line;
    ret.col = target.col;
    @ExprNode retv = p_new_expr(VAR_REF);
    retv.line = target.line;
    retv.col = target.col;
    retv.var_name = "__a1";
    retv.tok_len = 4;
    ret.expr = retv;
    w.true_body = p_chain_stmt(w.true_body, ret);
    return w;
}

!!! One generated store helper per type a program assigns a value to. The target's
!!! type is only known once the types are checked, which is where this is reached
!!! from (`rg_resolve_assign`); the function is registered like a written one and put
!!! at the end of the statement list, so the two front ends write the generated
!!! functions in the same order.
void rg_ensure_assign_helper -> @ExprNode target, bool seq {
    str name = rg_assign_helper_name(target, seq);
    if pe_eq(name, "") {
        end;
    }
    if rg_intmap_find(rg_func_arity, name) != null {
        end;
    }
    @StmtNode w = rg_make_assign_helper(name, seq, target);
    w.next = null;
    rg_func_arity = rg_intmap_set(rg_func_arity, name, rgr_str_n(w.fparams));
    rg_func_param_types = rg_vartypelistmap_set(rg_func_param_types, name, w.fparam_types,
                                                rgr_vt_n(w.fparam_types));
    rg_func_param_struct = rg_strlistmap_set(rg_func_param_struct, name, w.fparam_struct,
                                             rgr_str_n(w.fparam_struct));
    rg_func_param_names = rg_strlistmap_set(rg_func_param_names, name, w.fparams,
                                            rgr_str_n(w.fparams));
    rg_func_variadic = rg_boolmap_set(rg_func_variadic, name, false);
    rg_func_ret_struct = rg_strmap_set(rg_func_ret_struct, name, w.ret_struct);
    rg_func_decl_pos = rg_posmap_set(rg_func_decl_pos, name, w.line, w.col);
    lex_get_source(w.line);
    rg_func_decl_file = rg_strmap_set(rg_func_decl_file, name, g_src_file);
    rg_func_decl_line = rg_intmap_set(rg_func_decl_line, name, g_src_line);
    if rg_vartypemap_find(rg_syms, name) == null {
        rg_syms = rg_vartypemap_set(rg_syms, name, w.func_ret_type);
    }
    rg_sym_depth = rg_intmap_set(rg_sym_depth, name, 0);
    if w.ret_struct != "" {
        rg_sym_struct_type = rg_strmap_set(rg_sym_struct_type, name, w.ret_struct);
    }
    rgr_overload_add(name, w);
    !!! The body is written by hand, so its expressions are typed here: the code
    !!! generator reads the type of the value it stores.
    rg_push_func_params(w);
    rg_resolve_expr_type(w.true_body.expr);
    rg_resolve_expr_type(w.true_body.next.expr);
    rg_pop_func_params();
    rg_stmts = p_chain_stmt(rg_stmts, w);
}
