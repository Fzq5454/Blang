#once
!~
 ~  bootstrap/frontend/rgen_struct_template.b: this implementation of
 ~  - the generic structs (class templates):
 ~  `introduce TYPENAME T { type Box { T v; } }` and `Box(int) b;`.
 ~
 ~  A generic struct is kept generic in the StructTemplate of parser.b and cloned
 ~  into a concrete StructDef for each instantiation: `Box(int)` becomes `Box_int`,
 ~  with every `T` replaced by its bound type, a nested `Box(Vec(3))` instantiated
 ~  first, and a `@T` field turned into a plain pointer when the argument was a
 ~  builtin. The concrete StructDef is queued in `defs`, and the statement that
 ~  needed it is emitted after it because the backend resolves definitions in source
 ~  order.
 ~
 ~  the toolchain has four static helpers above the methods (the type spelling of a builtin,
 ~  trimming, splitting `Name(a, b)`, undoing the parser's escaping) and they are
 ~  functions here, with the `rst_` prefix. The in-out `name`/`vt` of
 ~  resolve_struct_type_slot and the `defs` list every queuing function fills are the
 ~  globals rgen.b declares for them; each caller reads its back after the call.
 ~!

#head "rgen"
stub void rst_parse_float -> str t;
stub @StructField rgx_flatchain_add -> @StructField head, @StructField node;
stub @StructMethod rgx_structmethod_add -> @StructMethod head, @StructMethod node;
stub int rst_targ_n -> @TArg head;
stub VarType rst_targ_ty -> @TArg head, int i;
stub void rst_targ_set_ty -> @TArg head, int i, VarType ty;

!!! The expression walk below is used before its definition.
stub void rg_resolve_types_expr -> @ExprNode n, @TArgMap tmap, str self_name, str mangled;

VarType rst_vt;

!!! A builtin type spelled as a type argument, so a nested instantiation (`Box(int)`)
!!! and a parameter bound to a builtin can be recognised again.
bool rst_vt_of_spell -> str s {
    rst_vt = INT;
    if p_text_eq(s, "int") { rst_vt = INT; return true; }
    if p_text_eq(s, "longlong") { rst_vt = LONG; return true; }
    if p_text_eq(s, "str") { rst_vt = STR; return true; }
    if p_text_eq(s, "float") { rst_vt = FLOAT; return true; }
    if p_text_eq(s, "bool") { rst_vt = BOOL; return true; }
    if p_text_eq(s, "char") { rst_vt = CHAR; return true; }
    if p_text_eq(s, "void") { rst_vt = VOID; return true; }
    if p_text_eq(s, "any") { rst_vt = ANY; return true; }
    if p_text_eq(s, "func") { rst_vt = FUNC; return true; }
    if p_text_eq(s, "@int") { rst_vt = AT_INT; return true; }
    if p_text_eq(s, "@longlong") { rst_vt = AT_LONG; return true; }
    if p_text_eq(s, "@str") { rst_vt = AT_STR; return true; }
    if p_text_eq(s, "@float") { rst_vt = AT_FLOAT; return true; }
    if p_text_eq(s, "@bool") { rst_vt = AT_BOOL; return true; }
    if p_text_eq(s, "@char") { rst_vt = AT_CHAR; return true; }
    if p_text_eq(s, "@void") { rst_vt = AT_VOID; return true; }
    if p_text_eq(s, "@func") { rst_vt = AT_FUNC; return true; }
    return false;
}

str rst_trim -> str s {
    int b = 0;
    int e = pe_len(s);
    while b < e && (s[b] == ' ' || s[b] == '\t') {
        b = b + 1;
    }
    while e > b && (s[e - 1] == ' ' || s[e - 1] == '\t') {
        e = e - 1;
    }
    return pe_sub(s, b, e - b);
}

!!! The top-level arguments of `Name(a, b)`, in order, left in rst_args. A nested
!!! instantiation (`Box(int, Vec(3))`) and a quoted string stay in one piece.
@StrNode rst_args;

bool rst_split_args -> str s {
    rst_args = null;
    int n = pe_len(s);
    int lp = pp_find_from(s, "(", 0);
    if lp < 0 || n == 0 || s[n - 1] != ')' {
        return false;
    }
    int depth = 0;
    bool in_str = false;
    str cnode = "";
    int i = lp + 1;
    while i + 1 < n {
        char c = s[i];
        if in_str {
            cnode = cnode + char_text(c);
            if c == '"' && s[i - 1] != '\\' {
                in_str = false;
            }
            i = i + 1;
            continue;
        }
        if c == '"' {
            in_str = true;
            cnode = cnode + char_text(c);
            i = i + 1;
            continue;
        }
        if c == '(' {
            depth = depth + 1;
        } else if c == ')' {
            depth = depth - 1;
        }
        if c == ',' && depth == 0 {
            rst_args = rg_strchain_append(rst_args, rst_trim(cnode));
            cnode = "";
            i = i + 1;
            continue;
        }
        cnode = cnode + char_text(c);
        i = i + 1;
    }
    if depth != 0 || in_str {
        return false;
    }
    str last = rst_trim(cnode);
    if last != "" || rst_args != null {
        rst_args = rg_strchain_append(rst_args, last);
    }
    return true;
}

!!! Undo the escaping the parser applied to a string argument spelling.
str rst_unescape -> str s {
    str out = "";
    int i = 0;
    int n = pe_len(s);
    while i < n {
        if s[i] == '\\' && i + 1 < n {
            i = i + 1;
            char c = s[i];
            if c == 'n' {
                out = out + "\n";
            } else if c == 't' {
                out = out + "\t";
            } else if c == '0' {
                out = out + char_text(0);
            } else {
                out = out + char_text(c);
            }
        } else {
            out = out + char_text(s[i]);
        }
        i = i + 1;
    }
    return out;
}

!!! One non-type template argument written as a constant expression, or null.
@TArg rst_value_arg -> str text, VarType want {
    TArg proto;
    @TArg a;
    malloc(@a, size proto);
    a.ty = want;
    a.struct_name = "";
    a.is_value = true;
    a.value = 0;
    a.fvalue = 0.0;
    a.svalue = "";
    a.is_template = false;
    a.tname = "";
    a.next = null;
    if want == STR {
        int n = pe_len(text);
        if n < 2 || text[0] != '"' || text[n - 1] != '"' {
            return null;
        }
        a.svalue = rst_unescape(pe_sub(text, 1, n - 2));
        return a;
    }
    if want == FLOAT {
        rst_parse_float(text);
        if !rst_float_ok {
            return null;
        }
        a.fvalue = rst_float_value;
        return a;
    }
    p_parse_int(text);
    if !p_parse_int_ok {
        return null;
    }
    a.value = p_parse_int_value;
    return a;
}

!!! A float written as text, which is what the toolchain gets from strtod. There is no
!!! such function to call in the language, so the digits, the point and the
!!! exponent are read here; anything else makes the answer false.
bool rst_float_ok;
float rst_float_value;

void rst_parse_float -> str t {
    rst_float_ok = false;
    rst_float_value = 0.0;
    int n = pe_len(t);
    if n == 0 {
        end;
    }
    int i = 0;
    bool neg = false;
    if t[i] == '-' {
        neg = true;
        i = i + 1;
    } else if t[i] == '+' {
        i = i + 1;
    }
    !!! The digits become one whole number and the point is moved with a single
    !!! multiplication or division, the way p_float_value reads a literal: adding
    !!! each fraction digit times its own 0.1 accumulated an error, and 0.1 came out
    !!! as 0.10000000000000002 instead of the double strtod answers.
    longlong man = 0;
    int expo = 0;
    int digits = 0;
    while i < n && t[i] >= '0' && t[i] <= '9' {
        if man < 1000000000000000000 {
            man = man * 10 + (longlong)((int)t[i] - 48);
        } else {
            expo = expo + 1;
        }
        digits = digits + 1;
        i = i + 1;
    }
    if i < n && t[i] == '.' {
        i = i + 1;
        while i < n && t[i] >= '0' && t[i] <= '9' {
            if man < 1000000000000000000 {
                man = man * 10 + (longlong)((int)t[i] - 48);
                expo = expo - 1;
            }
            digits = digits + 1;
            i = i + 1;
        }
    }
    if digits == 0 {
        end;
    }
    if i < n && (t[i] == 'e' || t[i] == 'E') {
        i = i + 1;
        bool eneg = false;
        if i < n && t[i] == '-' {
            eneg = true;
            i = i + 1;
        } else if i < n && t[i] == '+' {
            i = i + 1;
        }
        int exp = 0;
        int ed = 0;
        while i < n && t[i] >= '0' && t[i] <= '9' {
            exp = exp * 10 + ((int)t[i] - 48);
            ed = ed + 1;
            i = i + 1;
        }
        if ed == 0 {
            end;
        }
        if eneg {
            expo = expo - exp;
        } else {
            expo = expo + exp;
        }
    }
    if i != n {
        end;
    }
    float v = (float)man;
    if expo >= 0 {
        v = v * p_pow10(expo);
    } else {
        v = v / p_pow10(0 - expo);
    }
    if neg {
        v = 0.0 - v;
    }
    rst_float_value = v;
    rst_float_ok = true;
}

@StrNode rst_str_at -> @StrNode head, int i {
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

int rst_str_n -> @StrNode head {
    int n = 0;
    @StrNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

int rst_vt_n -> @VarTypeNode head {
    int n = 0;
    @VarTypeNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

int rst_int_n -> @IntNode head {
    int n = 0;
    @IntNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

int rst_int_at -> @IntNode head, int i {
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

VarType rst_vt_at -> @VarTypeNode head, int i {
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

bool rst_bool_at -> @BoolNode head, int i {
    int k = 0;
    @BoolNode e = head;
    while e != null {
        if k == i {
            return e.v;
        }
        k = k + 1;
        e = e.next;
    }
    return false;
}

void rst_str_set -> @StrNode head, int i, str to {
    int k = 0;
    @StrNode e = head;
    while e != null {
        if k == i {
            e.s = to;
            end;
        }
        k = k + 1;
        e = e.next;
    }
}

void rst_vt_set -> @VarTypeNode head, int i, VarType to {
    int k = 0;
    @VarTypeNode e = head;
    while e != null {
        if k == i {
            e.ty = to;
            end;
        }
        k = k + 1;
        e = e.next;
    }
}

void rst_int_set -> @IntNode head, int i, int to {
    int k = 0;
    @IntNode e = head;
    while e != null {
        if k == i {
            e.v = to;
            end;
        }
        k = k + 1;
        e = e.next;
    }
}

!!! A fresh StructDef record with every field written: malloc hands out junk, and
!!! the toolchain gets its zero values from the member initializers.
@StructDef rst_struct_new -> str name, int line, int col {
    StructDef proto;
    @StructDef d;
    malloc(@d, size proto);
    d.name = name;
    d.hash = rgx_lk_hash(name);
    d.bases = null;
    d.bases_line = null;
    d.bases_col = null;
    d.fields = null;
    d.methods = null;
    d.bapi_methods = null;
    d.init_func = null;
    d.init_line = 0;
    d.init_col = 0;
    d.destruct_func = null;
    d.destruct_line = 0;
    d.destruct_col = 0;
    d.total_size = 0;
    d.line = line;
    d.col = col;
    d.next = null;
    return d;
}

!!! `parser.struct_defs_mut()[name] = def`: the definition is put at the head of the
!!! chain, so the lookup finds it before an older entry of the same name. It goes
!!! onto the bucket its hash names as well, which is the index `p_find_struct`
!!! reads: a definition the index never saw is one no lookup can reach.
void rst_struct_put -> @StructDef d {
    d.next = p_struct_defs;
    p_struct_defs = d;
    p_index_struct(d);
}

@StmtNode rg_materialize_struct_templates -> @StmtNode stmts {
    if p_struct_templates == null {
        return stmts;
    }
    @StmtNode out = null;
    @StmtNode out_tail = null;
    @StmtNode s = stmts;
    while s != null {
        @StmtNode nx = s.next;
        s.next = null;
        @StmtNode defs = null;
        rg_resolve_struct_types_stmt_out_defs = null;
        rg_resolve_struct_types_stmt(s, null, "", "");
        defs = rg_resolve_struct_types_stmt_out_defs;
        !!! A generic struct can also appear in a plain struct's fields or method
        !!! bodies (`type Pair { Box(int) a; }`); those slots belong to the StructDef,
        !!! so the definitions this statement defines are resolved here and the
        !!! instantiations they need are emitted before it.
        rg_collect_struct_def_names_out = null;
        rg_collect_struct_def_names(s);
        @StrNode nm = rg_collect_struct_def_names_out;
        while nm != null {
            rg_resolve_struct_definition_out_defs = defs;
            rg_resolve_struct_definition(nm.s);
            defs = rg_resolve_struct_definition_out_defs;
            nm = nm.next;
        }
        !!! A concrete struct must be defined before the statement that uses it.
        @StmtNode d = defs;
        while d != null {
            @StmtNode dn = d.next;
            d.next = null;
            if out == null {
                out = d;
            } else {
                out_tail.next = d;
            }
            out_tail = d;
            d = dn;
        }
        if out == null {
            out = s;
        } else {
            out_tail.next = s;
        }
        out_tail = s;
        s = nx;
    }
    return out;
}

void rg_collect_struct_def_names -> @StmtNode s {
    if s == null {
        end;
    }
    if s.nk == STRUCT_DEF && s.var_name != "" {
        rg_collect_struct_def_names_out =
            rg_strchain_append(rg_collect_struct_def_names_out, s.var_name);
    }
    !!! The recursive calls append to the same list, so the caller reads the whole
    !!! one back out of the global when it is done.
    rg_collect_struct_def_names(s.true_body);
    rg_collect_struct_def_names(s.false_body);
    rg_collect_struct_def_names(s.case_bodies);
    rg_collect_struct_def_names(s.unmatch_body);
}

void rg_resolve_struct_definition -> str name {
    if rg_set_has(rg_struct_defs_resolved, name) {
        end;
    }
    rg_struct_defs_resolved = rg_set_add(rg_struct_defs_resolved, name);
    @StructDef sd = p_find_struct(name);
    if sd == null {
        end;
    }
    !!! The definition is worked on in place: materializing an instantiation may add
    !!! entries to the chain, which the toolchain guards against by copying out of its map.
    @StrNode b = sd.bases;
    int bi = 0;
    while b != null {
        VarType vt = INT;
        int bl = sd.line;
        if bi < rst_int_n(sd.bases_line) {
            bl = rst_int_at(sd.bases_line, bi);
        }
        int bc = sd.col;
        if bi < rst_int_n(sd.bases_col) {
            bc = rst_int_at(sd.bases_col, bi);
        }
        rg_resolve_struct_type_slot_out_name = b.s;
        rg_resolve_struct_type_slot_out_vt = vt;
        rg_resolve_struct_type_slot_out_defs = rg_resolve_struct_definition_out_defs;
        rg_resolve_struct_type_slot(null, bl, bc);
        rg_resolve_struct_definition_out_defs = rg_resolve_struct_type_slot_out_defs;
        rst_str_set(sd.bases, bi, rg_resolve_struct_type_slot_out_name);
        b = b.next;
        bi = bi + 1;
    }
    @StructField f = sd.fields;
    while f != null {
        rg_resolve_struct_type_slot_out_name = f.struct_type;
        rg_resolve_struct_type_slot_out_vt = f.ty;
        rg_resolve_struct_type_slot_out_defs = rg_resolve_struct_definition_out_defs;
        rg_resolve_struct_type_slot(null, sd.line, sd.col);
        rg_resolve_struct_definition_out_defs = rg_resolve_struct_type_slot_out_defs;
        f.struct_type = rg_resolve_struct_type_slot_out_name;
        f.ty = rg_resolve_struct_type_slot_out_vt;
        !!! A dimension that is still symbolic cannot be folded here: only a generic
        !!! struct instantiation can resolve a value parameter.
        @ExprNode de = f.dim_exprs;
        int di = 0;
        while de != null {
            if di >= rst_int_n(f.dims) || rst_int_at(f.dims, di) <= 0 {
                str msg = "array size of field '" + f.name +
                          "' must be a constant integer expression";
                rg_fmt_err(sd.line, sd.col, msg, pe_len(f.name), (str)null, 0, true);
                rg_has_errors = true;
                skip;
            }
            de = de.next;
            di = di + 1;
        }
        f = f.next;
    }
    @StructMethod m = sd.methods;
    while m != null {
        if m.fn != null {
            rg_resolve_struct_types_stmt_out_defs = rg_resolve_struct_definition_out_defs;
            rg_resolve_struct_types_stmt(m.fn, null, "", "");
            rg_resolve_struct_definition_out_defs = rg_resolve_struct_types_stmt_out_defs;
        }
        m = m.next;
    }
    if sd.init_func != null {
        rg_resolve_struct_types_stmt_out_defs = rg_resolve_struct_definition_out_defs;
        rg_resolve_struct_types_stmt(sd.init_func, null, "", "");
        rg_resolve_struct_definition_out_defs = rg_resolve_struct_types_stmt_out_defs;
    }
    if sd.destruct_func != null {
        rg_resolve_struct_types_stmt_out_defs = rg_resolve_struct_definition_out_defs;
        rg_resolve_struct_types_stmt(sd.destruct_func, null, "", "");
        rg_resolve_struct_definition_out_defs = rg_resolve_struct_types_stmt_out_defs;
    }
}

!!! One type slot: a template parameter bound in `tmap`, a generic spelling
!!! `Box(int)`, or a plain struct/builtin name. The (possibly rewritten) name and
!!! type are left in rg_resolve_struct_type_slot_out_name / _out_vt.
void rg_resolve_struct_type_slot -> @TArgMap tmap, int line, int col {
    str name = rg_resolve_struct_type_slot_out_name;
    VarType vt = rg_resolve_struct_type_slot_out_vt;
    if name == "" {
        end;
    }
    !!! A package-qualified type resolves to the member's internal name.
    rg_package_resolve_out_name = name;
    int pr = rg_package_resolve(line, col, pe_len(name));
    if pr == 1 {
        name = rg_package_resolve_out_name;
    } else if pr == 2 {
        rg_resolve_struct_type_slot_out_name = "";
        end;
    }
    !!! 1) A parameter of the generic struct currently being materialized.
    @TArg a = p_map_find(tmap, name);
    if a != null {
        if a.is_value {
            str msg = "'" + name + "' is a value parameter, not a type";
            rg_fmt_err(line, col, msg, pe_len(name), (str)null, 0, true);
            rg_has_errors = true;
            rg_resolve_struct_type_slot_out_name = "";
            end;
        }
        if a.is_template {
            str msg = "template parameter '" + name + "' must be instantiated, e.g. '" +
                      name + "(int)'";
            rg_fmt_err(line, col, msg, pe_len(name), (str)null, 0, true);
            rg_has_errors = true;
            rg_resolve_struct_type_slot_out_name = "";
            end;
        }
        if a.struct_name == "" {
            !!! Bound to a builtin type: the slot becomes a plain builtin.
            rg_resolve_struct_type_slot_out_name = "";
            rg_resolve_struct_type_slot_out_vt = a.ty;
            end;
        }
        rg_resolve_struct_type_slot_out_name = a.struct_name;
        !!! Same rule as the generic spelling below: `@T x` stays a pointer to the
        !!! concrete struct, `T x` stays the object.
        if !rg_is_at_type(vt) {
            rg_resolve_struct_type_slot_out_vt = INT;
        }
        end;
    }
    !!! 2) A generic spelling: `Box(int)` / `C(T)`.
    if p_is_generic_spelling(name) {
        rg_resolve_struct_spelling_out_defs = rg_resolve_struct_type_slot_out_defs;
        str concrete = rg_resolve_struct_spelling(name, tmap, line, col);
        rg_resolve_struct_type_slot_out_defs = rg_resolve_struct_spelling_out_defs;
        if concrete == "" {
            rg_resolve_struct_type_slot_out_name = "";
            rg_resolve_struct_type_slot_out_vt = vt;
            end;
        }
        rg_resolve_struct_type_slot_out_name = concrete;
        !!! The slot keeps the shape it was written with: `@Box(int) p` is a pointer
        !!! to the instantiation and `Box(int) v` is the object itself. The parser
        !!! records the address type for the first and leaves the placeholder INT on
        !!! the second, so only the placeholder is turned into the value form.
        !!! Setting INT unconditionally turned `@Box(int) p` into a value: every
        !!! write through `p` then went into its own eight bytes, and a method call
        !!! passed the address of the slot instead of the address it held.
        !!! The type is written back here rather than left where the call above put
        !!! it: instantiating the generic struct walks the statements of its body,
        !!! and every declaration that walk resolves leaves its own type in this
        !!! variable. the toolchain hands the type to the slot by reference and a nested
        !!! call cannot touch it; here it is a global, so `@vector(int) g_tokens`
        !!! came back as a plain `int` and the global was read as the object instead
        !!! of through the address it holds.
        rg_resolve_struct_type_slot_out_vt = vt;
        if !rg_is_at_type(vt) {
            rg_resolve_struct_type_slot_out_vt = INT;
        }
        end;
    }
    !!! 3) A bare name: a generic struct used without arguments is an error unless it
    !!! was already rewritten to the concrete instantiation.
    if p_find_template(name) != null {
        str msg = "generic struct '" + name + "' needs type arguments, e.g. '" + name + "(int)'";
        rg_fmt_err(line, col, msg, pe_len(name), (str)null, 0, true);
        rg_has_errors = true;
        rg_resolve_struct_type_slot_out_name = "";
        end;
    }
    !!! A builtin spelling (`int`, `@float`) turned back into a plain type.
    if rst_vt_of_spell(name) {
        rg_resolve_struct_type_slot_out_vt = rst_vt;
        rg_resolve_struct_type_slot_out_name = "";
        end;
    }
    if p_find_struct(name) == null && !rg_set_has(rg_struct_tmpl_done, name) {
        str msg = "undeclared type '" + name + "'";
        rg_fmt_err(line, col, msg, pe_len(name), (str)null, 0, true);
        rg_has_errors = true;
    }
}

str rg_resolve_struct_spelling -> str sp, @TArgMap tmap, int line, int col {
    str s = p_subst_type_spelling(sp, tmap);
    int lp = pp_find_from(s, "(", 0);
    str head = s;
    if lp >= 0 {
        head = pe_sub(s, 0, lp);
    }
    if !rst_split_args(s) {
        str msg = "malformed template argument list in type '" + sp + "'";
        rg_fmt_err(line, col, msg, pe_len(sp), (str)null, 0, true);
        rg_has_errors = true;
        return "";
    }
    @StrNode args = rst_args;
    @StructTemplate tmpl = p_find_template(head);
    if tmpl == null {
        str msg = "undeclared generic struct '" + head + "'";
        rg_fmt_err(line, col, msg, pe_len(head), (str)null, 0, true);
        rg_has_errors = true;
        return "";
    }
    int na = rst_str_n(args);
    int np = rst_str_n(tmpl.tparams);
    if na != np {
        str msg = "generic struct '" + head + "' needs " + (str)np + " type argument(s), got " +
                  (str)na;
        rg_fmt_err(line, col, msg, pe_len(head), (str)null, 0, true);
        rg_has_errors = true;
        return "";
    }
    @TArgMap amap = null;
    str mangled = head;
    @StrNode ai = args;
    int i = 0;
    while ai != null {
        bool want_tmpl = rst_bool_at(tmpl.tparam_is_template, i);
        bool want_val = rst_bool_at(tmpl.tparam_is_value, i);
        TArg proto;
        @TArg a;
        malloc(@a, size proto);
        a.ty = INT;
        a.struct_name = "";
        a.is_value = false;
        a.value = 0;
        a.fvalue = 0.0;
        a.svalue = "";
        a.is_template = false;
        a.tname = "";
        a.next = null;
        if want_tmpl {
            a.is_template = true;
            a.tname = rst_trim(ai.s);
            if p_find_template(a.tname) == null {
                str msg = "unknown generic struct '" + a.tname + "'";
                rg_fmt_err(line, col, msg, pe_len(a.tname), (str)null, 0, true);
                rg_has_errors = true;
                return "";
            }
        } else if want_val {
            VarType want = INT;
            if i < rst_vt_n(tmpl.tparam_types) {
                want = rst_vt_at(tmpl.tparam_types, i);
            }
            @TArg va = rst_value_arg(rst_trim(ai.s), want);
            if va == null {
                str msg = "argument " + (str)(i + 1) + " of '" + head +
                          "' must be a constant expression";
                rg_fmt_err(line, col, msg, pe_len(head), (str)null, 0, true);
                rg_has_errors = true;
                return "";
            }
            a = va;
        } else {
            str text = rst_trim(ai.s);
            if rst_vt_of_spell(text) {
                a.ty = rst_vt;
            } else if p_is_generic_spelling(text) {
                !!! A nested instantiation: it is built first, so the inner struct is
                !!! defined before the one that contains it.
                rg_resolve_struct_spelling_out_defs = rg_resolve_struct_type_slot_out_defs;
                str inner = rg_resolve_struct_spelling(text, null, line, col);
                rg_resolve_struct_type_slot_out_defs = rg_resolve_struct_spelling_out_defs;
                if inner == "" {
                    return "";
                }
                a.ty = INT;
                a.struct_name = inner;
            } else if p_find_struct(text) != null {
                a.ty = INT;
                a.struct_name = text;
            } else {
                str msg = "undeclared type '" + text + "'";
                rg_fmt_err(line, col, msg, pe_len(text), (str)null, 0, true);
                rg_has_errors = true;
                return "";
            }
        }
        @StrNode tp = rst_str_at(tmpl.tparams, i);
        amap = p_map_add(amap, tp.s, a);
        mangled = mangled + "_" + p_targ_ident(a);
        ai = ai.next;
        i = i + 1;
    }
    if !rg_set_has(rg_struct_tmpl_done, mangled) {
        !!! The definitions this function carries are the chain
        !!! `rg_resolve_struct_spelling_out_defs` holds - that is the field its caller
        !!! reads the answer out of - so the materializer is handed that one. Handing
        !!! it `rg_resolve_struct_type_slot_out_defs` instead (which the caller only
        !!! uses to set the spelling's input) dropped every definition the
        !!! instantiation made on the floor: the concrete struct was never emitted.
        rg_materialize_struct_template_out_defs = rg_resolve_struct_spelling_out_defs;
        rg_materialize_struct_template(head, mangled, amap);
        rg_resolve_struct_spelling_out_defs = rg_materialize_struct_template_out_defs;
        rg_resolve_struct_type_slot_out_defs = rg_resolve_struct_spelling_out_defs;
    }
    return mangled;
}

void rg_materialize_struct_template -> str tname, str mangled, @TArgMap tmap {
    rg_struct_tmpl_done = rg_set_add(rg_struct_tmpl_done, mangled);
    @StructTemplate tmpl = p_find_template(tname);
    if tmpl == null {
        end;
    }
    @StructDef tdef = tmpl.def;
    if tdef == null {
        end;
    }
    @StructDef def = rst_struct_new(mangled, tdef.line, tdef.col);
    !!! The (still empty) definition is registered first, so a self-reference inside
    !!! the body (`@Box next`, a method returning the enclosing type) resolves.
    rst_struct_put(def);
    !!! Bases: inherited fields are flattened into the object, exactly like an
    !!! ordinary struct.
    @StrNode b = tdef.bases;
    int bi = 0;
    while b != null {
        str bn = b.s;
        VarType bvt = INT;
        rg_resolve_struct_type_slot_out_name = bn;
        rg_resolve_struct_type_slot_out_vt = bvt;
        rg_resolve_struct_type_slot_out_defs = rg_materialize_struct_template_out_defs;
        rg_resolve_struct_type_slot(tmap, def.line, def.col);
        rg_materialize_struct_template_out_defs = rg_resolve_struct_type_slot_out_defs;
        bn = rg_resolve_struct_type_slot_out_name;
        if bn != "" {
            def.bases = rg_strchain_append(def.bases, bn);
            int bl = def.line;
            if bi < rst_int_n(tdef.bases_line) {
                bl = rst_int_at(tdef.bases_line, bi);
            }
            int bc = def.col;
            if bi < rst_int_n(tdef.bases_col) {
                bc = rst_int_at(tdef.bases_col, bi);
            }
            def.bases_line = rg_intchain_append(def.bases_line, bl);
            def.bases_col = rg_intchain_append(def.bases_col, bc);
        }
        b = b.next;
        bi = bi + 1;
    }
    !!! Fields: a type parameter becomes its concrete type, a generic field type
    !!! (`Box(T) v`) becomes the instantiated struct.
    @StructField f = tdef.fields;
    while f != null {
        StructField proto;
        @StructField nf;
        malloc(@nf, size proto);
        nf.name = f.name;
        nf.ty = f.ty;
        nf.offset = f.offset;
        nf.array_dim = f.array_dim;
        nf.dims = f.dims;
        nf.dim_exprs = f.dim_exprs;
        nf.struct_type = f.struct_type;
        nf.struct_ptr = f.struct_ptr;
        nf.is_unsigned = f.is_unsigned;
        nf.next = null;
        if p_text_eq(nf.struct_type, tname) {
            !!! `@Box next`
            nf.struct_type = mangled;
        }
        rg_resolve_struct_type_slot_out_name = nf.struct_type;
        rg_resolve_struct_type_slot_out_vt = nf.ty;
        rg_resolve_struct_type_slot_out_defs = rg_materialize_struct_template_out_defs;
        rg_resolve_struct_type_slot(tmap, def.line, def.col);
        rg_materialize_struct_template_out_defs = rg_resolve_struct_type_slot_out_defs;
        nf.struct_type = rg_resolve_struct_type_slot_out_name;
        nf.ty = rg_resolve_struct_type_slot_out_vt;
        !!! A `@T` field: the parameter was just replaced by its concrete spelling.
        !!! Bound to a struct the field stays a struct pointer; bound to a builtin
        !!! there is no struct of that name to point at, so the field becomes a plain
        !!! pointer to that builtin (`@int`, `@str`, ...) and the struct name goes
        !!! away, which is what `Vec(int)` needs for its element block.
        if nf.struct_ptr && nf.struct_type == "" {
            nf.ty = rg_at_of(nf.ty);
            nf.struct_ptr = false;
        }
        !!! `int data[N]`: every dimension is folded now that the value parameters of
        !!! the template are bound, then the total element count is computed.
        if nf.dim_exprs != null {
            bool ok = true;
            int total = 1;
            @ExprNode de = nf.dim_exprs;
            int di = 0;
            int nd = rst_int_n(nf.dims);
            while de != null {
                if di < nd && rst_int_at(nf.dims, di) > 0 {
                    total = total * rst_int_at(nf.dims, di);
                    de = de.next;
                    di = di + 1;
                    continue;
                }
                @ExprNode dim = p_clone_expr_t(de, tmap);
                bool folded = false;
                if dim != null {
                    p_eval_const_int(dim);
                    if p_const_ok && p_eval_value > 0 {
                        if di < nd {
                            rst_int_set(nf.dims, di, (int)p_eval_value);
                        }
                        total = total * (int)p_eval_value;
                        folded = true;
                    }
                }
                if !folded {
                    str msg = "array size of field '" + nf.name +
                              "' must be a constant integer expression";
                    rg_fmt_err(def.line, def.col, msg, pe_len(nf.name), (str)null, 0, true);
                    rg_has_errors = true;
                    ok = false;
                }
                de = de.next;
                di = di + 1;
            }
            if ok {
                nf.array_dim = total;
            }
        }
        def.fields = rgx_flatchain_add(def.fields, nf);
        f = f.next;
    }
    !!! The fields are in place now, and the method bodies that follow are resolved
    !!! against them (`size proto`, `data[i]`, a bare field name): the definition
    !!! registered before this point was still empty, so a field lookup during the
    !!! method walk found nothing and a `size` on a field was reported as an
    !!! undeclared type.
    @StructMethod m = tdef.methods;
    while m != null {
        StructMethod proto2;
        @StructMethod nm;
        malloc(@nm, size proto2);
        nm.name = m.name;
        nm.fn = p_clone_stmt(m.fn, tmap);
        nm.op = m.op;
        nm.ctor_from = m.ctor_from;
        nm.ctor_func = m.ctor_func;
        nm.access = m.access;
        nm.next = null;
        !!! The body belongs to the concrete struct, so a name that is a field of it
        !!! (`size proto`, `data[i]`) resolves through `this` while its types are
        !!! rewritten.
        str saved_method_type = rg_struct_method_type;
        str saved_method_var = rg_struct_method_var;
        rg_struct_method_type = mangled;
        rg_struct_method_var = "__this";
        rg_resolve_struct_types_stmt_out_defs = rg_materialize_struct_template_out_defs;
        rg_resolve_struct_types_stmt(nm.fn, tmap, tname, mangled);
        rg_materialize_struct_template_out_defs = rg_resolve_struct_types_stmt_out_defs;
        rg_struct_method_type = saved_method_type;
        rg_struct_method_var = saved_method_var;
        def.methods = rgx_structmethod_add(def.methods, nm);
        m = m.next;
    }
    if tdef.init_func != null {
        def.init_func = p_clone_stmt(tdef.init_func, tmap);
        str sv = rg_struct_method_var;
        str st = rg_struct_method_type;
        rg_struct_method_type = mangled;
        rg_struct_method_var = "__this";
        rg_resolve_struct_types_stmt_out_defs = rg_materialize_struct_template_out_defs;
        rg_resolve_struct_types_stmt(def.init_func, tmap, tname, mangled);
        rg_materialize_struct_template_out_defs = rg_resolve_struct_types_stmt_out_defs;
        rg_struct_method_type = st;
        rg_struct_method_var = sv;
        def.init_line = tdef.init_line;
        def.init_col = tdef.init_col;
        def.init_access = tdef.init_access;
    }
    if tdef.destruct_func != null {
        def.destruct_func = p_clone_stmt(tdef.destruct_func, tmap);
        rg_resolve_struct_types_stmt_out_defs = rg_materialize_struct_template_out_defs;
        rg_resolve_struct_types_stmt(def.destruct_func, tmap, tname, mangled);
        rg_materialize_struct_template_out_defs = rg_resolve_struct_types_stmt_out_defs;
        def.destruct_line = tdef.destruct_line;
        def.destruct_col = tdef.destruct_col;
        def.destruct_access = tdef.destruct_access;
    }
    !!! BLANG_API methods name a fixed runtime target, so they are shared with every
    !!! instantiation as it stands.
    def.bapi_methods = tdef.bapi_methods;
    def.total_size = tdef.total_size;
    def.name_line = tdef.name_line;
    def.name_col = tdef.name_col;

    @StmtNode sd = p_new_stmt(STRUCT_DEF);
    sd.var_name = mangled;
    sd.line = tdef.line;
    sd.col = tdef.col;
    sd.var_line = tdef.name_line;
    sd.var_col = tdef.name_col;
    rg_materialize_struct_template_out_defs =
        p_chain_stmt(rg_materialize_struct_template_out_defs, sd);
}

@StructField rgx_flatchain_add -> @StructField head, @StructField node {
    if head == null {
        return node;
    }
    @StructField t = head;
    while t.next != null {
        t = t.next;
    }
    t.next = node;
    return head;
}

@StructMethod rgx_structmethod_add -> @StructMethod head, @StructMethod node {
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

void rg_resolve_struct_types_stmt -> @StmtNode s, @TArgMap tmap, str self_name, str mangled {
    if s == null {
        end;
    }
    !!! An explicit function-template call (`wrap(Box)(x)`) is bound by the template
    !!! instantiation, which is what turns a template-name argument into a concrete
    !!! instantiation. Its argument list is left untouched.
    bool pending_tpl = false;
    if s.nk == CALL_FUNC && s.targ_structs != null && p_find_template_func(s.var_name) != null {
        pending_tpl = true;
    }
    !!! The injected class name inside the generic struct's own body refers to the
    !!! concrete instantiation (`Box` -> `Box_int`).
    if self_name != "" {
        if p_text_eq(s.struct_type, self_name) {
            s.struct_type = mangled;
        }
        if p_text_eq(s.ret_struct, self_name) {
            s.ret_struct = mangled;
        }
        @StrNode fs = s.fparam_struct;
        int fi = 0;
        while fs != null {
            if p_text_eq(fs.s, self_name) {
                rst_str_set(s.fparam_struct, fi, mangled);
            }
            fs = fs.next;
            fi = fi + 1;
        }
        @StrNode ts = s.targ_structs;
        int ti = 0;
        while ts != null {
            if p_text_eq(ts.s, self_name) {
                rst_str_set(s.targ_structs, ti, mangled);
            }
            ts = ts.next;
            ti = ti + 1;
        }
    }
    rg_resolve_struct_type_slot_out_name = s.struct_type;
    rg_resolve_struct_type_slot_out_vt = s.decl_type;
    rg_resolve_struct_type_slot_out_defs = rg_resolve_struct_types_stmt_out_defs;
    rg_resolve_struct_type_slot(tmap, s.line, s.col);
    rg_resolve_struct_types_stmt_out_defs = rg_resolve_struct_type_slot_out_defs;
    s.struct_type = rg_resolve_struct_type_slot_out_name;
    s.decl_type = rg_resolve_struct_type_slot_out_vt;
    !!! A cloned template body is registered in the symbol tables before its generic
    !!! types are resolved, so they are kept in step with the rewritten declaration.
    if s.nk == DECLARE {
        if s.struct_type == "" {
            rg_sym_struct_type = rg_strmap_drop(rg_sym_struct_type, s.var_name);
        } else {
            rg_sym_struct_type = rg_strmap_set(rg_sym_struct_type, s.var_name, s.struct_type);
            !!! `@T p`: the declaration says the variable holds an address of the
            !!! struct, not the struct itself. This walk runs before
            !!! collect_declared_vars and registers the declaration, so that pass
            !!! finds the name already in rg_syms and never sets this one: without
            !!! it every assignment to the variable was emitted as a whole-struct
            !!! copy into the eight bytes of the pointer.
            if s.ptr_depth > 0 {
                rg_sym_struct_ptr = rg_boolmap_set(rg_sym_struct_ptr, s.var_name, true);
            }
        }
        !!! The declaration is added, not only updated: a local of the cloned body was
        !!! never in the flat table, and `size` of it - the element size a generic
        !!! container asks for - was reported as an undeclared type because of that.
        rg_syms = rg_vartypemap_set(rg_syms, s.var_name, s.decl_type);
    }
    rg_resolve_struct_type_slot_out_name = s.ret_struct;
    rg_resolve_struct_type_slot_out_vt = s.func_ret_type;
    rg_resolve_struct_type_slot_out_defs = rg_resolve_struct_types_stmt_out_defs;
    rg_resolve_struct_type_slot(tmap, s.line, s.col);
    rg_resolve_struct_types_stmt_out_defs = rg_resolve_struct_type_slot_out_defs;
    s.ret_struct = rg_resolve_struct_type_slot_out_name;
    s.func_ret_type = rg_resolve_struct_type_slot_out_vt;
    int nfs = rst_str_n(s.fparam_struct);
    int i = 0;
    while i < nfs {
        VarType vt = INT;
        if i < rst_vt_n(s.fparam_types) {
            vt = rst_vt_at(s.fparam_types, i);
        }
        @StrNode fs2 = rst_str_at(s.fparam_struct, i);
        rg_resolve_struct_type_slot_out_name = fs2.s;
        rg_resolve_struct_type_slot_out_vt = vt;
        rg_resolve_struct_type_slot_out_defs = rg_resolve_struct_types_stmt_out_defs;
        rg_resolve_struct_type_slot(tmap, s.line, s.col);
        rg_resolve_struct_types_stmt_out_defs = rg_resolve_struct_type_slot_out_defs;
        rst_str_set(s.fparam_struct, i, rg_resolve_struct_type_slot_out_name);
        if i < rst_vt_n(s.fparam_types) {
            rst_vt_set(s.fparam_types, i, rg_resolve_struct_type_slot_out_vt);
        }
        i = i + 1;
    }
    int nts = rst_str_n(s.targ_structs);
    int k = 0;
    while k < nts && !pending_tpl {
        VarType vt2 = INT;
        if k < rst_targ_n(s.targs) {
            vt2 = rst_targ_ty(s.targs, k);
        }
        @StrNode ts2 = rst_str_at(s.targ_structs, k);
        rg_resolve_struct_type_slot_out_name = ts2.s;
        rg_resolve_struct_type_slot_out_vt = vt2;
        rg_resolve_struct_type_slot_out_defs = rg_resolve_struct_types_stmt_out_defs;
        rg_resolve_struct_type_slot(tmap, s.line, s.col);
        rg_resolve_struct_types_stmt_out_defs = rg_resolve_struct_type_slot_out_defs;
        rst_str_set(s.targ_structs, k, rg_resolve_struct_type_slot_out_name);
        if k < rst_targ_n(s.targs) {
            rst_targ_set_ty(s.targs, k, rg_resolve_struct_type_slot_out_vt);
        }
        k = k + 1;
    }
    rg_resolve_types_expr(s.expr, tmap, self_name, mangled);
    rg_resolve_types_expr(s.array_len_expr, tmap, self_name, mangled);
    @ExprNode a = s.args;
    while a != null {
        rg_resolve_types_expr(a, tmap, self_name, mangled);
        a = a.next;
    }
    @ExprNode ai = s.array_init;
    while ai != null {
        rg_resolve_types_expr(ai, tmap, self_name, mangled);
        ai = ai.next;
    }
    @ExprNode asi = s.assign_indices;
    while asi != null {
        rg_resolve_types_expr(asi, tmap, self_name, mangled);
        asi = asi.next;
    }
    @ExprNode ce = s.case_exprs;
    while ce != null {
        rg_resolve_types_expr(ce, tmap, self_name, mangled);
        ce = ce.next;
    }
    @ExprNode fd = s.fparam_defaults;
    while fd != null {
        rg_resolve_types_expr(fd, tmap, self_name, mangled);
        fd = fd.next;
    }
    !!! `true_body` is the `true_body` and the `children` at once.
    @StmtNode b = s.true_body;
    while b != null {
        rg_resolve_struct_types_stmt(b, tmap, self_name, mangled);
        b = b.next;
    }
    @StmtNode fb = s.false_body;
    while fb != null {
        rg_resolve_struct_types_stmt(fb, tmap, self_name, mangled);
        fb = fb.next;
    }
    @StmtNode cb = s.case_bodies;
    while cb != null {
        rg_resolve_struct_types_stmt(cb, tmap, self_name, mangled);
        cb = cb.next;
    }
    @StmtNode ub = s.unmatch_body;
    while ub != null {
        rg_resolve_struct_types_stmt(ub, tmap, self_name, mangled);
        ub = ub.next;
    }
}

!!! Expressions carry a struct type only after type resolution, but the explicit
!!! template arguments of a nested call are written in the source.
void rg_resolve_types_expr -> @ExprNode n, @TArgMap tmap, str self_name, str mangled {
    if n == null {
        end;
    }
    bool pending_call = false;
    if n.targ_structs != null && n.nk == FUNC_CALL && p_find_template_func(n.var_name) != null {
        pending_call = true;
    }
    int nt = rst_str_n(n.targ_structs);
    int i = 0;
    while i < nt && !pending_call {
        VarType vt = INT;
        if i < rst_vt_n(n.targs) {
            vt = rst_vt_at(n.targs, i);
        }
        @StrNode ts = rst_str_at(n.targ_structs, i);
        if self_name != "" && p_text_eq(ts.s, self_name) {
            rst_str_set(n.targ_structs, i, mangled);
        }
        @StrNode ts2 = rst_str_at(n.targ_structs, i);
        rg_resolve_struct_type_slot_out_name = ts2.s;
        rg_resolve_struct_type_slot_out_vt = vt;
        rg_resolve_struct_type_slot_out_defs = rg_resolve_struct_types_stmt_out_defs;
        rg_resolve_struct_type_slot(tmap, n.line, n.col);
        rg_resolve_struct_types_stmt_out_defs = rg_resolve_struct_type_slot_out_defs;
        rst_str_set(n.targ_structs, i, rg_resolve_struct_type_slot_out_name);
        if i < rst_vt_n(n.targs) {
            rst_vt_set(n.targs, i, rg_resolve_struct_type_slot_out_vt);
        }
        i = i + 1;
    }
    !!! `size v` was answered while the template was still generic, where the type of
    !!! a `T` is not known yet, and the answer is kept on the node. The instantiated
    !!! body has the concrete type, so the node is asked again - but only where the
    !!! name means something here: the body of the generic block is walked once
    !!! before it is materialized, and asking there reported a field of the
    !!! not-yet-existing struct as an undeclared type, which then abandoned the whole
    !!! instantiation.
    if n.nk == SIZE || n.nk == COUNT {
        if rg_effective_var_decl(n.var_name) || rg_method_field_shadows(n.var_name) ||
           rg_struct_method_type != "" {
            n.type_resolved = false;
            rg_resolve_expr_type(n);
        }
    }
    rg_resolve_types_expr(n.left, tmap, self_name, mangled);
    rg_resolve_types_expr(n.right, tmap, self_name, mangled);
    @ExprNode a = n.args;
    while a != null {
        rg_resolve_types_expr(a, tmap, self_name, mangled);
        a = a.next;
    }
    @ExprNode ix = n.indices;
    while ix != null {
        rg_resolve_types_expr(ix, tmap, self_name, mangled);
        ix = ix.next;
    }
    @ExprNode tx = n.targ_exprs;
    while tx != null {
        rg_resolve_types_expr(tx, tmap, self_name, mangled);
        tx = tx.next;
    }
    if n.nk == LAMBDA {
        @LambdaRec rec = p_find_lambda(n.lambda_id);
        if rec != null {
            @ExprNode ia = rec.immediate_args;
            while ia != null {
                rg_resolve_types_expr(ia, tmap, self_name, mangled);
                ia = ia.next;
            }
            @StmtNode lb = rec.body;
            while lb != null {
                rg_resolve_struct_types_stmt(lb, tmap, self_name, mangled);
                lb = lb.next;
            }
        }
    }
}

!!! The explicit type arguments of a statement or expression are TArg records, so
!!! the type of one of them is read from its `ty` field.
int rst_targ_n -> @TArg head {
    int n = 0;
    @TArg e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

VarType rst_targ_ty -> @TArg head, int i {
    int k = 0;
    @TArg e = head;
    while e != null {
        if k == i {
            return e.ty;
        }
        k = k + 1;
        e = e.next;
    }
    return VOID;
}

void rst_targ_set_ty -> @TArg head, int i, VarType ty {
    int k = 0;
    @TArg e = head;
    while e != null {
        if k == i {
            e.ty = ty;
            end;
        }
        k = k + 1;
        e = e.next;
    }
}
