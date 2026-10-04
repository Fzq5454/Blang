#once
!~
 ~  bootstrap/frontend/rgen_rewrite_operators.b: this implementation of
 ~  - the overloaded operators lowered to method
 ~  calls, the converting constructors, the implicit conversions and the stores
 ~  written through a chain of subscripts.
 ~
 ~  `a + b` on a struct type becomes `a.op_add(b)`, an ordinary call, so the type
 ~  check, the argument handling and the code generator all work unchanged and the
 ~  backend never sees an overloaded operator. The `[]` operator is the harder case:
 ~  a value-returning `[]` has to read, store and write the element back, and one
 ~  that hands back a pointer stores through the returned address instead.
 ~
 ~  While a body is being rewritten its own declarations are consulted first
 ~  (`rg_op_body_types`, `rg_op_body_ptr`, `rg_op_body_array`, `rg_op_body_var_types`):
 ~  a local of that body is not in the flat tables yet, and the file-wide tables hold
 ~  the *first* declaration of a name, which may be a different body's.
 ~!

#head "rgen"

type RwPending {
    str ty;
    str recv;
    str ix;
    str tmp;
    @RwPending next;
};
stub int rw_vt_n -> @VarTypeNode head;
stub VarType rw_vt_at -> @VarTypeNode head, int i;
stub VarType rw_vt_last -> @VarTypeNode head;

!!! The local helpers below are used before their definitions.
stub @ExprNode rw_relink -> @ExprNode head, @ExprNode prev, @ExprNode nx, @ExprNode node;
stub void rwx_rewrite_expr_chain -> @ExprNode head;
stub str rwx_str_at -> @StrNode head, int i;
stub longlong rwx_long_at -> @RgLongNode head, int i;
stub @RwPending rwx_pending_reverse -> @RwPending head;
stub @ExprNode rwx_idx_at -> @ExprNode head, int i;
stub @ExprNode rwx_ref_at -> @RgExprRef head, int i;
stub int rgx_rw_expr_n -> @ExprNode head;
stub @StmtNode rgx_ow_stmt_add -> @StmtNode head, @StmtNode node;
stub int rgx_exprref_n -> @RgExprRef head;

!!! True when the expression is an address rather than an object: a plain name whose
!!! declared type is a pointer (`@T p`). Pointer arithmetic, pointer comparison and
!!! pointer subscripting are then not the struct's own operators.
bool rg_pointer_operand -> @ExprNode n {
    if n == null || n.nk != VAR_REF {
        return false;
    }
    return rg_pointer_operand_name(n.var_name);
}

!!! The same question for a name alone, where a statement carries the name instead of
!!! an expression node (`p[i] = v`).
bool rg_pointer_operand_name -> str name {
    if rg_var_is_struct_ptr(name) || rg_name_is_pointer(name) {
        return true;
    }
    !!! A local of the body being rewritten is not in the flat tables yet; the
    !!! declaration the body carries says whether it is a pointer.
    @RgBoolMap ot = rg_boolmap_find(rg_op_body_ptr, name);
    if ot != null && ot.v {
        return true;
    }
    @RgVarTypeMap vt = rg_vartypemap_find(rg_op_body_var_types, name);
    if vt != null && rg_is_at_type(vt.ty) {
        return true;
    }
    return false;
}

!!! Struct type of an expression for the operator rewrite. The declared type of a
!!! parameter or local of the body being rewritten wins over the file-wide table,
!!! which may hold the type of a same-named variable from another function.
str rg_operator_struct_type -> @ExprNode n {
    if n == null {
        return "";
    }
    if n.nk == VAR_REF {
        @RgStrMap it = rg_strmap_find(rg_op_body_types, n.var_name);
        if it != null {
            return it.v;
        }
        !!! Inside a struct method body a bare name that is not a parameter or a local
        !!! is a field of the enclosing struct, so the file-wide tables must not be
        !!! consulted.
        if rg_op_in_method_body {
            if rg_op_method_type == "" {
                return "";
            }
            rg_resolve_field_out_decl_type = "";
            @StructField f = rg_resolve_field(rg_op_method_type, n.var_name, true);
            if f == null || f.struct_ptr {
                return "";
            }
            return f.struct_type;
        }
    }
    return rg_expr_struct_type(n);
}

!!! Record the struct type of every declaration of one body ("" = not a struct) and
!!! the declared scalar type of the ones that are not structs.
void rg_collect_operator_body_types -> @StmtNode body {
    @StmtNode s = body;
    while s != null {
        bool descend = true;
        if s.nk == FUNCTION {
            !!! A function body is a scope of its own.
            descend = false;
        }
        if descend {
            if s.nk == DECLARE {
                rg_op_body_types = rg_strmap_set(rg_op_body_types, s.var_name, s.struct_type);
                !!! Whether the declaration is a pointer (`@T p`) as well, so `p[i]` and
                !!! `p + 1` are recognised as pointer subscripting and pointer
                !!! arithmetic while the body is being rewritten.
                rg_op_body_ptr = rg_boolmap_set(rg_op_body_ptr, s.var_name, s.ptr_depth > 0);
                rg_op_body_array = rg_boolmap_set(rg_op_body_array, s.var_name, s.is_array);
                if s.struct_type == "" && s.ptr_depth == 0 {
                    rg_op_body_var_types = rg_vartypemap_set(rg_op_body_var_types, s.var_name,
                                                             s.decl_type);
                }
            }
            rg_collect_operator_body_types(s.true_body);
            rg_collect_operator_body_types(s.false_body);
            rg_collect_operator_body_types(s.case_bodies);
            rg_collect_operator_body_types(s.unmatch_body);
        }
        s = s.next;
    }
}

!!! Generated function of the constructor of `type` that takes a `src` value, ""
!!! when the type declares none. The access level of that constructor - the `init`
!!! method it was declared as - is left in rg_find_ctor_func_out_access.
str rg_find_ctor_func -> str stype, VarType src {
    rg_find_ctor_func_out_access = 0;
    if stype == "" {
        return "";
    }
    @StructDef sd = p_find_struct(stype);
    if sd == null {
        return "";
    }
    @StructMethod m = sd.methods;
    while m != null {
        bool skip_it = false;
        if m.ctor_from == "" || m.fn == null || m.ctor_func == "" {
            skip_it = true;
        }
        if !skip_it && rgr_vt_n(m.fn.fparam_types) != 1 {
            skip_it = true;
        }
        if !skip_it && m.fn.fparam_struct != null && m.fn.fparam_struct.s != "" {
            !!! Built from another struct, not a scalar.
            skip_it = true;
        }
        if !skip_it && rgr_vt_at(m.fn.fparam_types, 0) == src {
            rg_find_ctor_func_out_access = m.access;
            return m.ctor_func;
        }
        m = m.next;
    }
    return "";
}

!!! Generated function of a constructor whose parameters are all `int`. Such a
!!! constructor is what an integer constant wider than one `int` fills: the value is
!!! split into its 32-bit parts. The number of parts is left in
!!! rg_find_ctor_limbs_out_count, and the access level of the constructor in
!!! rg_find_ctor_limbs_out_access.
str rg_find_ctor_limbs -> str stype {
    rg_find_ctor_limbs_out_count = 0;
    rg_find_ctor_limbs_out_access = 0;
    if stype == "" {
        return "";
    }
    @StructDef sd = p_find_struct(stype);
    if sd == null {
        return "";
    }
    @StructMethod m = sd.methods;
    while m != null {
        bool skip_it = false;
        if m.ctor_from == "" || m.fn == null || m.ctor_func == "" {
            skip_it = true;
        }
        int np = 0;
        if !skip_it {
            np = rgr_vt_n(m.fn.fparam_types);
            if np < 2 {
                skip_it = true;
            }
        }
        if !skip_it {
            int i = 0;
            while i < np {
                if rgr_vt_at(m.fn.fparam_types, i) != INT {
                    skip_it = true;
                    skip;
                }
                @StrNode ps = rgr_str_at(m.fn.fparam_struct, i);
                if ps != null && ps.s != "" {
                    skip_it = true;
                    skip;
                }
                i = i + 1;
            }
        }
        if !skip_it {
            rg_find_ctor_limbs_out_count = np;
            rg_find_ctor_limbs_out_access = m.access;
            return m.ctor_func;
        }
        m = m.next;
    }
    return "";
}

!!! Value of an integer constant as written, with a leading `-` included. The value
!!! is left in rg_int_literal_value_out_value.
bool rg_int_literal_value -> @ExprNode n {
    rg_int_literal_value_out_value = 0;
    @ExprNode lit = n;
    bool negated = false;
    if lit != null && lit.nk == UNARY && p_text_eq(lit.op, "-") && lit.left != null &&
       lit.left.nk == LIT_INT {
        negated = true;
        lit = lit.left;
    }
    if lit == null || lit.nk != LIT_INT {
        return false;
    }
    rg_int_literal_value_out_value = lit.int_val;
    if negated {
        rg_int_literal_value_out_value = 0 - lit.int_val;
    }
    return true;
}

!!! Does a constant fit the scalar type of a constructor parameter?
bool rgx_ctor_scalar_fits -> VarType param, longlong value {
    if param == INT {
        if value >= -2147483648 && value <= 2147483647 {
            return true;
        }
        return false;
    }
    if param == CHAR {
        if value >= -128 && value <= 255 {
            return true;
        }
        return false;
    }
    if param == BOOL {
        if value == 0 || value == 1 {
            return true;
        }
        return false;
    }
    return true;
}

!!! Declared scalar type of a value expression, used to pick the constructor. The
!!! operator rewrite runs before the subscripts and calls of an expression are
!!! lowered, so the type is read from the tables of the body being rewritten first;
!!! only the kinds whose own rewrite has already happened fall back to the ordinary
!!! resolution.
bool rg_op_value_type -> @ExprNode n {
    rg_op_value_type_out = INT;
    if n == null {
        return false;
    }
    if n.nk == LIT_INT {
        rg_op_value_type_out = INT;
        return true;
    }
    if n.nk == LIT_FLOAT {
        rg_op_value_type_out = FLOAT;
        return true;
    }
    if n.nk == LIT_STR {
        rg_op_value_type_out = STR;
        return true;
    }
    if n.nk == LIT_BOOL {
        rg_op_value_type_out = BOOL;
        return true;
    }
    if n.nk == LIT_CHAR {
        rg_op_value_type_out = CHAR;
        return true;
    }
    if n.nk == VAR_REF {
        @RgVarTypeMap it = rg_vartypemap_find(rg_op_body_var_types, n.var_name);
        if it != null {
            rg_op_value_type_out = it.ty;
            return true;
        }
        if rg_op_in_method_body && rg_op_method_type != "" {
            !!! A bare name in a method body is a field of the enclosing type unless
            !!! the body declares it.
            rg_resolve_field_out_decl_type = "";
            @StructField f = rg_resolve_field(rg_op_method_type, n.var_name, true);
            if f != null && f.struct_type == "" && !f.struct_ptr {
                rg_op_value_type_out = f.ty;
                return true;
            }
            return false;
        }
        @RgVarTypeMap sit = rg_vartypemap_find(rg_syms, n.var_name);
        if sit != null {
            rg_op_value_type_out = sit.ty;
            return true;
        }
        return false;
    }
    if n.nk == FUNC_CALL {
        if n.has_receiver && n.args != null {
            str st = rg_operator_struct_type(n.args);
            if st == "" {
                return false;
            }
            @StmtNode mf = rg_resolve_method_func(st, n.var_name, true);
            if mf == null || mf.ret_struct != "" || mf.ret_struct_ptr {
                return false;
            }
            rg_op_value_type_out = mf.func_ret_type;
            return true;
        }
        if rg_strmap_find(rg_func_ret_struct, n.var_name) == null && rg_op_in_method_body &&
           rg_op_method_type != "" {
            @StmtNode imf = rg_resolve_method_func(rg_op_method_type, n.var_name, true);
            if imf != null {
                if imf.ret_struct != "" || imf.ret_struct_ptr {
                    return false;
                }
                rg_op_value_type_out = imf.func_ret_type;
                return true;
            }
        }
        @RgVarTypeMap sit2 = rg_vartypemap_find(rg_syms, n.var_name);
        if sit2 != null && sit2.ty != VOID {
            rg_op_value_type_out = sit2.ty;
            return true;
        }
        return false;
    }
    !!! Subscripts, casts and operators of a value expression: their own rewrite has
    !!! already run, so the ordinary resolution is safe here.
    bool after = false;
    if n.nk == ARRAY_ACCESS || n.nk == FIELD_ELEM || n.nk == MEMBER_ACCESS || n.nk == BINOP ||
       n.nk == UNARY || n.nk == CAST || n.nk == SHL || n.nk == SHR || n.nk == BITNOT ||
       n.nk == TERNARY || n.nk == SIZE || n.nk == COUNT {
        after = true;
    }
    if !after {
        return false;
    }
    if !rg_resolve_expr_type(n) {
        return false;
    }
    rg_op_value_type_out = n.result_type;
    return true;
}

!!! `CAST` operator and method name of one conversion target.
str rw_cast_op;
str rw_cast_method;

bool rw_conversion_names -> str target {
    rw_cast_op = "";
    rw_cast_method = "";
    if p_text_eq(target, "str") {
        rw_cast_op = "toStr";
        rw_cast_method = "op_to_str";
        return true;
    }
    if p_text_eq(target, "int") {
        rw_cast_op = "toInt";
        rw_cast_method = "op_to_int";
        return true;
    }
    if p_text_eq(target, "float") {
        rw_cast_op = "toFloat";
        rw_cast_method = "op_to_float";
        return true;
    }
    if p_text_eq(target, "bool") {
        rw_cast_op = "toBool";
        rw_cast_method = "op_to_bool";
        return true;
    }
    if p_text_eq(target, "char") {
        rw_cast_op = "toChar";
        rw_cast_method = "op_to_char";
        return true;
    }
    return false;
}

!!! An integer constant the constructor's parameter cannot hold, e.g.
!!! `long x = 6000000000;` where the parameter is an `int`. Storing the low 32 bits
!!! would be a silent wrong value, which is exactly what the constructor is meant to
!!! prevent, so it is reported.
bool rg_ctor_literal_fits -> @ExprNode slot, VarType param {
    if !rg_int_literal_value(slot) {
        !!! Not a plain constant.
        return true;
    }
    return rgx_ctor_scalar_fits(param, rg_int_literal_value_out_value);
}

!!! Wrap a value in the converting constructor of `type` when the target is a struct
!!! and the value is not: `long a = 5;` becomes `long a = __ctor_long_int(5);`. False
!!! when the type declares no constructor for the value. The rewritten node is left in
!!! rg_wrap_ctor_out_slot.
bool rg_wrap_ctor -> str stype {
    @ExprNode slot = rg_wrap_ctor_out_slot;
    if slot == null || stype == "" {
        return false;
    }
    if rg_operator_struct_type(slot) != "" {
        !!! Already a struct value.
        return false;
    }
    if !rg_op_value_type(slot) {
        return false;
    }
    VarType src = rg_op_value_type_out;
    bool is_lit = rg_int_literal_value(slot);
    longlong value = rg_int_literal_value_out_value;
    str w = rg_find_ctor_func(stype, src);
    int acc = rg_find_ctor_func_out_access;
    !!! An integer constant that one `int` parameter cannot hold, or a type whose only
    !!! constructor takes several: both are filled by splitting the value into its
    !!! 32-bit parts.
    if is_lit && (w == "" || !rgx_ctor_scalar_fits(src, value)) {
        rg_find_ctor_limbs_out_count = 0;
        str lw = rg_find_ctor_limbs(stype);
        int limbs = rg_find_ctor_limbs_out_count;
        if lw != "" {
            !!! The constructor is applied here, so an `init` the type keeps to itself
            !!! cannot be run for a value built outside it.
            rg_check_member_access(stype, "init", rg_find_ctor_limbs_out_access,
                                   slot.line, slot.col);
            @ExprNode call = p_new_expr(FUNC_CALL);
            call.line = slot.line;
            call.col = slot.col;
            call.tok_len = slot.tok_len;
            call.var_name = lw;
            call.result_type = INT;
            call.struct_type = stype;
            int i = 0;
            while i < limbs {
                @ExprNode part = p_new_expr(LIT_INT);
                part.line = slot.line;
                part.col = slot.col;
                part.tok_len = slot.tok_len;
                part.result_type = INT;
                !!! The low 32 bits first, then the parts above them. The shift of a
                !!! negative value keeps the sign, and a part past the value's own
                !!! width is that sign alone.
                if i == 0 {
                    part.int_val = (longlong)(int)value;
                } else if 32 * i >= 64 {
                    if value < 0 {
                        part.int_val = -1;
                    } else {
                        part.int_val = 0;
                    }
                } else {
                    part.int_val = (longlong)(int)(value >> (32 * i));
                }
                call.args = p_chain_expr(call.args, part);
                i = i + 1;
            }
            rg_wrap_ctor_out_slot = call;
            return true;
        }
    }
    if w == "" {
        return false;
    }
    !!! The constructor is applied here, so an `init` the type keeps to itself cannot
    !!! be run for a value built outside it.
    rg_check_member_access(stype, "init", acc, slot.line, slot.col);
    if !rg_ctor_literal_fits(slot, src) {
        !!! Reported, but the call is still built so the value is not reported a second
        !!! time as a type mismatch; no code is emitted after an error.
        str msg = "literal " + (str)value + " does not fit in '" + rg_type_name(src) +
                  "', the constructor parameter of '" + stype + "'";
        int hl = slot.tok_len;
        if hl <= 0 {
            hl = 1;
        }
        rg_fmt_err(slot.line, slot.col, msg, hl, (str)null, 0, true);
        rg_has_errors = true;
    }
    @ExprNode call2 = p_new_expr(FUNC_CALL);
    call2.line = slot.line;
    call2.col = slot.col;
    call2.tok_len = slot.tok_len;
    call2.var_name = w;
    call2.result_type = INT;
    call2.struct_type = stype;
    call2.args = p_chain_expr(call2.args, slot);
    rg_wrap_ctor_out_slot = call2;
    return true;
}

!!! Which conversion an `any` argument uses when several are declared.
str rg_pick_any_conversion -> str st {
    if st == "" {
        return "";
    }
    int i = 0;
    while i < 5 {
        str t = "char";
        if i == 0 {
            t = "str";
        } else if i == 1 {
            t = "int";
        } else if i == 2 {
            t = "float";
        } else if i == 3 {
            t = "bool";
        }
        if rw_conversion_names(t) {
            if rg_resolve_method_func(st, rw_cast_method, true) != null {
                return t;
            }
        }
        i = i + 1;
    }
    return "";
}

!!! Wrap a struct expression in a conversion of `target`, when the type declares one.
!!! The CAST node is then lowered to the operator call by the normal rewrite. The
!!! rewritten node is left in rg_wrap_conversion_out_slot.
bool rg_wrap_conversion -> str target {
    @ExprNode slot = rg_wrap_conversion_out_slot;
    if slot == null {
        return false;
    }
    if !rw_conversion_names(target) {
        return false;
    }
    str st = rg_operator_struct_type(slot);
    if st == "" {
        return false;
    }
    if rg_resolve_method_func(st, rw_cast_method, true) == null {
        return false;
    }
    @ExprNode cast = p_new_expr(CAST);
    cast.line = slot.line;
    cast.col = slot.col;
    cast.tok_len = slot.tok_len;
    cast.op = rw_cast_op;
    cast.left = slot;
    rg_wrap_conversion_out_slot = cast;
    return true;
}

!!! Parameter types of a call, so an `any` parameter is recognised. False when the
!!! callee is not a user function or a BAPI. The types are left in
!!! rg_callee_param_types_out, the struct names in _out_structs and the variadic flag
!!! in the single-node chain _out_variadic.
bool rg_callee_param_types -> str name, bool has_receiver, @ExprNode receiver, bool resolved {
    rg_callee_param_types_out = null;
    rg_callee_param_types_out_structs = null;
    rg_callee_param_types_out_variadic = p_new_bool(false);
    if has_receiver && receiver != null {
        !!! `system.out(...)`: the receiver is a type name, `v.f(...)`: a value.
        str st = "";
        if receiver.nk == VAR_REF {
            st = rg_operator_name_struct_type(receiver.var_name);
        } else {
            st = rg_operator_struct_type(receiver);
        }
        if st == "" {
            return false;
        }
        @StmtNode bm = rg_resolve_bapi_method(st, name, true);
        if bm != null {
            rg_callee_param_types_out = bm.fparam_types;
            rg_callee_param_types_out_structs = bm.fparam_struct;
            rg_callee_param_types_out_variadic.v = bm.variadic;
            return true;
        }
        !!! Several versions of the method: which parameter types apply is only known
        !!! once the arguments picked one, so the conversions are applied after
        !!! overload resolution (rg_wrap_overload_args).
        if !resolved {
            str key = st + char_text(1) + name;
            @RgOverloadMap mot = rg_overloadmap_find(rg_method_overloads, key);
            if mot != null && mot.n > 1 {
                return false;
            }
        }
        @StmtNode mf = rg_resolve_method_func(st, name, true);
        if mf != null {
            rg_callee_param_types_out = mf.fparam_types;
            rg_callee_param_types_out_structs = mf.fparam_struct;
            rg_callee_param_types_out_variadic.v = mf.variadic;
            return true;
        }
        return false;
    }
    @StmtNode bit = p_find_bapi(name);
    if bit != null {
        rg_callee_param_types_out = bit.fparam_types;
        rg_callee_param_types_out_structs = bit.fparam_struct;
        rg_callee_param_types_out_variadic.v = bit.variadic;
        return true;
    }
    if !resolved {
        @RgOverloadMap ov = rg_overloadmap_find(rg_func_overloads, name);
        if ov != null && ov.n > 1 {
            return false;
        }
    }
    !!! An implicit method call inside a method body: the callee is a method of the
    !!! enclosing type.
    if rg_struct_method_type != "" {
        @StmtNode imf = rg_resolve_method_func(rg_struct_method_type, name, true);
        if imf != null {
            rg_callee_param_types_out = imf.fparam_types;
            rg_callee_param_types_out_structs = imf.fparam_struct;
            rg_callee_param_types_out_variadic.v = imf.variadic;
            return true;
        }
    }
    @RgVarTypeListMap pit = rg_vartypelistmap_find(rg_func_param_types, name);
    if pit != null {
        rg_callee_param_types_out = pit.types;
        @RgStrListMap sit = rg_strlistmap_find(rg_func_param_struct, name);
        if sit != null {
            rg_callee_param_types_out_structs = sit.names;
        }
        @RgBoolMap vit = rg_boolmap_find(rg_func_variadic, name);
        if vit != null {
            rg_callee_param_types_out_variadic.v = vit.v;
        }
        return true;
    }
    return false;
}

!!! The arguments of one call: a struct that declares a conversion is passed as the
!!! converted scalar, both for an `any` parameter (where the conversion also gives the
!!! value its type tag) and for a concrete scalar parameter.
void rg_wrap_arguments -> str callee, @ExprNode args, int first_param, bool has_receiver,
                          @ExprNode receiver, int line, int col, int tok_len, bool resolved {
    if rgx_rw_expr_n(args) <= first_param {
        end;
    }
    if !rg_callee_param_types(callee, has_receiver, receiver, resolved) {
        end;
    }
    @VarTypeNode ptypes = rg_callee_param_types_out;
    @StrNode pstructs = rg_callee_param_types_out_structs;
    bool variadic = rg_callee_param_types_out_variadic.v;
    @ExprNode a = args;
    int i = 0;
    !!! The argument before the one being looked at, so a rewritten node can be put
    !!! back where it stood. It belongs to the walk and not to one step of it.
    @ExprNode prev = null;
    while a != null {
        if i >= first_param {
            int pi = i - first_param;
            @StrNode ps = rw_str_at(pstructs, pi);
            @ExprNode nx = a.next;
            !!! The slot is rewritten in place: the node the caller holds is what has to
            !!! change, so the rewritten node is written back into the chain.
            if ps != null && ps.s != "" {
                !!! A parameter declared as a struct takes the struct value itself; only
                !!! a scalar parameter takes a conversion.
                str ast = rg_operator_struct_type(a);
                if ast != "" && !p_text_eq(ast, ps.s) {
                    str msg = "argument " + (str)(pi + 1) + " missing '" + ps.s + "', got '" +
                              ast + "'";
                    int hl = a.tok_len;
                    if hl <= 0 {
                        hl = 1;
                    }
                    rg_fmt_err(a.line, a.col, msg, hl, (str)null, 0, true);
                    rg_has_errors = true;
                } else if ast == "" {
                    !!! A value where the parameter is a struct: the type's converting
                    !!! constructor builds the value.
                    rg_wrap_ctor_out_slot = a;
                    if rg_wrap_ctor(ps.s) {
                        a = rg_wrap_ctor_out_slot;
                        args = rw_relink(args, prev, nx, a);
                    }
                }
            } else {
                VarType want = INT;
                bool have = false;
                if pi < rw_vt_n(ptypes) {
                    want = rw_vt_at(ptypes, pi);
                    have = true;
                } else if variadic && ptypes != null {
                    want = rw_vt_last(ptypes);
                    have = true;
                }
                if have {
                    str st = rg_operator_struct_type(a);
                    if st != "" {
                        if want == ANY {
                            str target = rg_pick_any_conversion(st);
                            if target == "" {
                                str msg = "type '" + st + "' has no conversion for an 'any' argument";
                                int hl = a.tok_len;
                                if hl <= 0 {
                                    hl = 1;
                                }
                                rg_fmt_err(a.line, a.col, msg, hl, (str)null, 0, true);
                                @StructDef dit = p_find_struct(st);
                                if dit != null {
                                    rg_fmt_note(dit.line, dit.col, "type is declared here", 4);
                                }
                                rg_has_errors = true;
                            } else {
                                rg_wrap_conversion_out_slot = a;
                                if rg_wrap_conversion(target) {
                                    a = rg_wrap_conversion_out_slot;
                                    args = rw_relink(args, prev, nx, a);
                                }
                                rg_rewrite_conversion_out_n = a;
                                rg_rewrite_conversion();
                                a = rg_rewrite_conversion_out_n;
                                args = rw_relink(args, prev, nx, a);
                            }
                        } else {
                            !!! A concrete scalar parameter: the argument has to declare
                            !!! that conversion.
                            bool is_scalar = scalar_type_name(want);
                            str target2 = op_scalar;
                            if is_scalar {
                                rg_wrap_conversion_out_slot = a;
                                if rg_wrap_conversion(target2) {
                                    a = rg_wrap_conversion_out_slot;
                                    args = rw_relink(args, prev, nx, a);
                                    rg_rewrite_conversion_out_n = a;
                                    rg_rewrite_conversion();
                                    a = rg_rewrite_conversion_out_n;
                                    args = rw_relink(args, prev, nx, a);
                                } else {
                                    str msg = "argument " + (str)(pi + 1) + " missing '" +
                                              target2 + "', got '" + st + "'";
                                    int hl = a.tok_len;
                                    if hl <= 0 {
                                        hl = 1;
                                    }
                                    rg_fmt_err(a.line, a.col, msg, hl, (str)null, 0, true);
                                    rg_has_errors = true;
                                }
                            }
                        }
                    }
                }
            }
            prev = a;
        }
        a = a.next;
        !!! The next argument is parameter `pi + 1`: the toolchain counts with the index of
        !!! its loop, and without this every argument was checked against the first
        !!! parameter of the callee.
        i = i + 1;
    }
}

int rw_vt_n -> @VarTypeNode head {
    int n = 0;
    @VarTypeNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

VarType rw_vt_at -> @VarTypeNode head, int i {
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

VarType rw_vt_last -> @VarTypeNode head {
    VarType t = INT;
    @VarTypeNode e = head;
    while e != null {
        t = e.ty;
        e = e.next;
    }
    return t;
}

@StrNode rw_str_at -> @StrNode head, int i {
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

int rgx_rw_expr_n -> @ExprNode head {
    int n = 0;
    @ExprNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

!!! The rewritten node stands where the old one stood: the link that reaches the slot
!!! is written to the replacement (and the new node keeps the old one's `next`).
!!! The answer is the head of the chain, because the slot the toolchain rewrites through its
!!! reference may be the first one: with `prev` null nothing else can reach the
!!! replacement, so the caller has to take the new head back (`args = rw_relink(...)`).
@ExprNode rw_relink -> @ExprNode head, @ExprNode prev, @ExprNode nx, @ExprNode node {
    node.next = nx;
    if prev != null {
        prev.next = node;
        return head;
    }
    return node;
}

!!! Implicit conversions of a call whose callee had several versions: the argument
!!! types picked the version, so only now is it known which conversions apply. The
!!! call sites rg_resolve_overloads rewrote carry `is_overload_call`.
void rg_wrap_overload_args_expr -> @ExprNode n {
    if n == null {
        end;
    }
    rg_wrap_overload_args_expr(n.left);
    rg_wrap_overload_args_expr(n.right);
    @ExprNode a = n.args;
    while a != null {
        rg_wrap_overload_args_expr(a);
        a = a.next;
    }
    @ExprNode i = n.indices;
    while i != null {
        rg_wrap_overload_args_expr(i);
        i = i.next;
    }
    if n.nk == LAMBDA {
        @LambdaRec rec = p_find_lambda(n.lambda_id);
        if rec != null {
            @StmtNode lb = rec.body;
            while lb != null {
                rg_wrap_overload_args_stmt(lb);
                lb = lb.next;
            }
        }
    }
    if n.nk != FUNC_CALL || !n.is_overload_call {
        end;
    }
    if n.has_receiver && n.args != null {
        rg_wrap_arguments(n.var_name, n.args, 1, true, n.args, n.line, n.col, n.tok_len, true);
    } else {
        rg_wrap_arguments(n.var_name, n.args, 0, false, null, n.line, n.col, n.tok_len, true);
    }
}

void rg_wrap_overload_args_stmt -> @StmtNode s {
    if s == null {
        end;
    }
    if s.nk == CALL_FUNC && s.is_overload_call {
        if s.is_method_call && s.args != null {
            rg_wrap_arguments(s.var_name, s.args, 1, true, s.args, s.line, s.col, 1, true);
        } else {
            rg_wrap_arguments(s.var_name, s.args, 0, false, null, s.line, s.col, 1, true);
        }
    }
    rg_wrap_overload_args_expr(s.expr);
    rg_wrap_overload_args_expr(s.array_len_expr);
    @ExprNode a = s.args;
    while a != null {
        rg_wrap_overload_args_expr(a);
        a = a.next;
    }
    @ExprNode t = s.targ_exprs;
    while t != null {
        rg_wrap_overload_args_expr(t);
        t = t.next;
    }
    @ExprNode ai = s.array_init;
    while ai != null {
        rg_wrap_overload_args_expr(ai);
        ai = ai.next;
    }
    @ExprNode asi = s.assign_indices;
    while asi != null {
        rg_wrap_overload_args_expr(asi);
        asi = asi.next;
    }
    @ExprNode ce = s.case_exprs;
    while ce != null {
        rg_wrap_overload_args_expr(ce);
        ce = ce.next;
    }
    !!! `true_body` is the `true_body` and the `children` at once.
    @StmtNode b = s.true_body;
    while b != null {
        rg_wrap_overload_args_stmt(b);
        b = b.next;
    }
    @StmtNode fb = s.false_body;
    while fb != null {
        rg_wrap_overload_args_stmt(fb);
        fb = fb.next;
    }
    @StmtNode cb = s.case_bodies;
    while cb != null {
        rg_wrap_overload_args_stmt(cb);
        cb = cb.next;
    }
    @StmtNode ub = s.unmatch_body;
    while ub != null {
        rg_wrap_overload_args_stmt(ub);
        ub = ub.next;
    }
}

void rg_wrap_overload_args -> @StmtNode stmts {
    @StmtNode s = stmts;
    while s != null {
        if s.nk == FUNCTION {
            rg_push_func_params(s);
        }
        rg_wrap_overload_args_stmt(s);
        if s.nk == FUNCTION {
            rg_pop_func_params();
        }
        s = s.next;
    }
    @StructDef sd = p_struct_defs;
    while sd != null {
        @StructMethod m = sd.methods;
        while m != null {
            if m.fn != null {
                rg_push_func_params(m.fn);
                rg_wrap_overload_args_stmt(m.fn);
                rg_pop_func_params();
            }
            m = m.next;
        }
        if sd.init_func != null {
            rg_push_func_params(sd.init_func);
            rg_wrap_overload_args_stmt(sd.init_func);
            rg_pop_func_params();
        }
        if sd.destruct_func != null {
            rg_push_func_params(sd.destruct_func);
            rg_wrap_overload_args_stmt(sd.destruct_func);
            rg_pop_func_params();
        }
        sd = sd.next;
    }
}

!!! Declared struct type of a plain name, from the body being rewritten: the
!!! declarations of that body win over the file-wide tables, which may hold the type
!!! of a same-named variable of another function.
str rgx_wsc_target_struct -> str name {
    @RgStrMap it = rg_strmap_find(rg_op_body_types, name);
    if it != null {
        return it.v;
    }
    if rg_op_in_method_body {
        if rg_op_method_type == "" {
            return "";
        }
        rg_resolve_field_out_decl_type = "";
        @StructField f = rg_resolve_field(rg_op_method_type, name, true);
        if f == null || f.struct_ptr {
            return "";
        }
        return f.struct_type;
    }
    return rg_operator_name_struct_type(name);
}

!!! Assignment and initialization to a scalar from a struct value, and to a struct
!!! from a value the type has a converting constructor for.
void rg_wrap_stmt_conversions -> @StmtNode s {
    if s == null {
        end;
    }
    if s.nk == DECLARE && s.expr != null {
        if s.struct_type == "" && s.ptr_depth == 0 {
            bool is_scalar = scalar_type_name(s.decl_type);
            str target = op_scalar;
            if is_scalar {
                str st = rg_operator_struct_type(s.expr);
                if st != "" {
                    rg_wrap_conversion_out_slot = s.expr;
                    if !rg_wrap_conversion(target) {
                        str msg = "cannot initialize '" + target + "' with a '" + st + "' value";
                        int hl = s.expr.tok_len;
                        if hl <= 0 {
                            hl = 1;
                        }
                        rg_fmt_err(s.expr.line, s.expr.col, msg, hl, (str)null, 0, true);
                        rg_has_errors = true;
                        end;
                    }
                    s.expr = rg_wrap_conversion_out_slot;
                }
                rg_rewrite_conversion_out_n = s.expr;
                rg_rewrite_conversion();
                s.expr = rg_rewrite_conversion_out_n;
            }
        } else if s.struct_type != "" && !s.is_array && s.array_init == null {
            !!! `T x = <value>;`: the target is a struct, the value is not.
            rg_wrap_ctor_out_slot = s.expr;
            if rg_wrap_ctor(s.struct_type) {
                s.expr = rg_wrap_ctor_out_slot;
            }
        }
        end;
    }
    if s.nk == ASSIGN && s.expr != null && !s.is_array {
        if s.member_name == "" {
            !!! The target's declared type comes from the body being rewritten.
            @RgVarTypeMap it = rg_vartypemap_find(rg_op_body_var_types, s.var_name);
            if it != null {
                bool is_scalar2 = scalar_type_name(it.ty);
                str target2 = op_scalar;
                if is_scalar2 {
                    rg_wrap_conversion_out_slot = s.expr;
                    if rg_wrap_conversion(target2) {
                        s.expr = rg_wrap_conversion_out_slot;
                        rg_rewrite_conversion_out_n = s.expr;
                        rg_rewrite_conversion();
                        s.expr = rg_rewrite_conversion_out_n;
                    }
                    end;
                }
            }
            str tst = rgx_wsc_target_struct(s.var_name);
            if tst != "" {
                rg_wrap_ctor_out_slot = s.expr;
                if rg_wrap_ctor(tst) {
                    s.expr = rg_wrap_ctor_out_slot;
                }
            }
            end;
        }
        !!! `o.field = <value>`: the field decides which constructor applies.
        str base = rgx_wsc_target_struct(s.var_name);
        if base == "" {
            end;
        }
        rg_resolve_field_out_decl_type = "";
        @StructField f = rg_resolve_field(base, s.member_name, true);
        if f == null || f.struct_ptr || f.struct_type == "" {
            end;
        }
        rg_wrap_ctor_out_slot = s.expr;
        if rg_wrap_ctor(f.struct_type) {
            s.expr = rg_wrap_ctor_out_slot;
        }
    }
}

!!! How the declaration spells one of its parameters, for the reason text: the struct
!!! name it was declared with, or the scalar type's own name.
str rg_op_param_spelling -> @StmtNode f, int i {
    @StrNode ps = rgr_str_at(f.fparam_struct, i);
    if ps != null && ps.s != "" {
        return ps.s;
    }
    if i < rgr_vt_n(f.fparam_types) {
        return rg_type_name(rgr_vt_at(f.fparam_types, i));
    }
    return "?";
}

!!! Why one declared operator cannot be used for this expression: it is a different
!!! symbol, it takes the other number of operands, or its parameter does not accept
!!! the operand that would be passed to it.
str rw_reject_reason -> @StructMethod m, str sym, int want_params, str arg_type, str param_type {
    @StmtNode f = m.fn;
    str spelling = "operator " + m.op;
    if !p_text_eq(m.op, sym) {
        return "it is '" + spelling + "'";
    }
    int nparams = 0;
    if f != null {
        nparams = rgr_str_n(f.fparams);
    }
    if nparams != want_params {
        return "it takes " + (str)nparams + " argument(s), this use needs " + (str)want_params;
    }
    if arg_type == "" {
        return "it does not accept this use";
    }
    return "it expects '" + param_type + "', got '" + arg_type + "'";
}

!!! The note that names the type and lists the operator overloads it declares, one
!!! numbered entry each with the reason it cannot take this use and the source block
!!! of the declaration. A type the headers describe has no declaration to point at
!!! and no overloads of its own, so the error stands alone.
void rg_emit_operator_list -> str stype, str sym, int want_params, str arg_type {
    @StructDef def = p_find_struct(stype);
    if def == null {
        end;
    }
    !!! The overloads are counted first and the type's method chain is walked a second
    !!! time to write the entries. the toolchain collects the pointers into a vector and
    !!! never touches the list; building a chain out of the same nodes here relinks
    !!! the type's own method list, whose tail then points at itself, and both this
    !!! walk and every later one over the type's methods never end.
    int nops = 0;
    @StructMethod m = def.methods;
    while m != null {
        !!! A constructor is not an operator.
        if m.op != "" && !p_text_eq(m.op, "init") {
            nops = nops + 1;
        }
        m = m.next;
    }
    !!! `type Point {`: point at the name, not at the keyword in front of it.
    int ncol = rg_word_col(def.line, def.col, def.name);
    if ncol == 0 {
        ncol = def.col;
    }
    int nlen = pe_len(def.name);
    if nlen <= 0 {
        nlen = 1;
    }
    if nops == 0 {
        str head = "'" + stype + "' declares no operator overloads";
        rg_fmt_note(def.line, ncol, head, nlen);
        end;
    }
    str head2 = "'" + stype + "' declares " + (str)nops + " operator overloads, they are:";
    if nops == 1 {
        head2 = "'" + stype + "' declares one operator overload:";
    }
    rg_fmt_note(def.line, ncol, head2, nlen);
    m = def.methods;
    int i = 0;
    while m != null {
        if m.op != "" && !p_text_eq(m.op, "init") {
            @StmtNode f = m.fn;
            if f != null {
                int line = f.var_line;
                if line <= 0 {
                    line = f.line;
                }
                int col = f.var_col;
                if col <= 0 {
                    col = f.col;
                }
                int len = pe_len(m.op);
                if len <= 0 {
                    len = 1;
                }
                !!! `operator <symbol>` is what the entry underlines, so the caret starts
                !!! at the keyword and covers the symbol with it.
                int kcol = rg_operator_keyword_col(line, col);
                if kcol > 0 && kcol <= col {
                    len = col + len - kcol;
                    col = kcol;
                }
                str reason = rw_reject_reason(m, sym, want_params, arg_type,
                                              rg_op_param_spelling(f, 0));
                rg_fmt_list_item(i + 1, reason, line, col, len);
            }
            i = i + 1;
        }
        m = m.next;
    }
}

!!! No operator of the two operands matches: the error points at the symbol and names
!!! both operand types, and the note lists what the receiver type declares.
void rg_report_no_operator -> @ExprNode n, str sym {
    str ls = "";
    if n != null && n.left != null {
        ls = rg_operator_struct_type(n.left);
    }
    str rs = "";
    if n != null && n.right != null {
        rs = rg_operator_struct_type(n.right);
    }
    str lname = ls;
    if ls == "" {
        if n != null && n.left != null {
            lname = rg_type_name(n.left.result_type);
        } else {
            lname = "?";
        }
    }
    str rname = rs;
    if rs == "" {
        if n != null && n.right != null {
            rname = rg_type_name(n.right.result_type);
        } else {
            rname = "";
        }
    }
    str msg = "no matching 'operator" + sym + "' for '" + lname + "'";
    if n != null && n.right != null {
        msg = msg + " and '" + rname + "'";
    }
    int eline = 0;
    int ecol = 1;
    int elen = 1;
    if n != null {
        eline = n.line;
        ecol = n.col;
        elen = n.tok_len;
        if elen <= 0 {
            elen = 1;
        }
        if n.op_line > 0 {
            eline = n.op_line;
            ecol = n.op_col;
            elen = pe_len(sym);
        }
    }
    rg_fmt_err(eline, ecol, msg, elen, (str)null, 0, true);
    !!! One operand is the receiver and the other is the argument; the entry's
    !!! parameter is compared against the argument of the use.
    str recv = ls;
    if ls == "" {
        recv = rs;
    }
    bool is_binary = (n != null && n.right != null);
    !!! `!ls.empty() ? rname : lname`: the argument is the operand that is not the
    !!! receiver, so it is the right one when the receiver is the left.
    str arg_type = "";
    if is_binary {
        arg_type = lname;
        if ls != "" {
            arg_type = rname;
        }
    }
    int want = 0;
    if is_binary {
        want = 1;
    }
    rg_emit_operator_list(recv, sym, want, arg_type);
    rg_has_errors = true;
}

!!! The same list for an operator written without an operand pair (`[]`, `[]=`).
void rg_report_no_operator_at -> str stype, str sym, int line, int col, int len {
    str msg = "type '" + stype + "' has no operator '" + sym + "'";
    int hl = len;
    if hl <= 0 {
        hl = 1;
    }
    rg_fmt_err(line, col, msg, hl, (str)null, 0, true);
    !!! `[]` is written with the index alone, `[]=` with the index and the value.
    int want = 1;
    if p_text_eq(sym, "[]=") {
        want = 2;
    }
    rg_emit_operator_list(stype, sym, want, "");
    rg_has_errors = true;
}

!!! Struct type declared for a plain name in the body being rewritten.
str rg_operator_name_struct_type -> str name {
    @RgStrMap it = rg_strmap_find(rg_op_body_types, name);
    if it != null {
        return it.v;
    }
    @RgStrMap sit = rg_strmap_find(rg_sym_struct_type, name);
    if sit != null {
        return sit.v;
    }
    if p_find_struct(name) != null {
        return name;
    }
    return "";
}

!!! Indices of an array access: several are kept in `indices`, a single one in `left`
!!! (the two shapes the parser produces). They land in rw_idx.
@ExprNode rw_idx;

void rw_collect_array_indices -> @ExprNode n {
    rw_idx = null;
    if n == null {
        end;
    }
    if n.indices != null {
        !!! The indices already are a chain, so it is handed back as it stands. Copying
        !!! it link by link built a chain out of nodes whose own `next` still linked
        !!! them: `p_chain_expr` walks to the tail before appending, so the last node
        !!! was made to point at itself and the walk feeding it never ended.
        rw_idx = n.indices;
        end;
    }
    if n.left != null {
        rw_idx = n.left;
    }
}

!!! `name[idx[0]]...[idx[dims-1]]`: the element `name` is selected by the leading
!!! indices of a longer access. The index nodes are moved into the new node.
@ExprNode rw_make_element_access -> str name, int line, int col, int tok_len, int dims, str elem {
    @ExprNode arr = p_new_expr(ARRAY_ACCESS);
    arr.line = line;
    arr.col = col;
    arr.tok_len = tok_len;
    arr.var_name = name;
    arr.struct_type = elem;
    if dims <= 1 {
        arr.left = rw_idx;
        if arr.left != null {
            arr.left.next = null;
        }
    } else {
        @ExprNode i = rw_idx;
        int k = 0;
        while i != null && k < dims {
            @ExprNode nx = i.next;
            i.next = null;
            arr.indices = p_chain_expr(arr.indices, i);
            i = nx;
            k = k + 1;
        }
    }
    return arr;
}

!!! Declared dimension count of an array variable, 0 when it is unknown.
int rg_array_var_dims -> str name {
    @RgDimsMap dit = rg_dimmap_find(rg_sym_dims, name);
    if dit != null && dit.dims != null {
        return dit.n;
    }
    return 0;
}

void rg_report_too_many_indices -> str name, int dims, int got, int line, int col, int len {
    str msg = "array '" + name + "' has " + (str)dims + " dimension(s), got " + (str)got +
              " index(es)";
    int hl = len;
    if hl <= 0 {
        hl = 1;
    }
    rg_fmt_err(line, col, msg, hl, (str)null, 0, true);
    rg_has_errors = true;
}

!!! The `[]` of `type` hands back a pointer to the element (`@T operator []`): the
!!! caller gets the address of the element itself, so a store through it is a real
!!! lvalue store and no `[]=` is involved.
bool rg_index_getter_is_pointer -> str stype {
    @StmtNode getter = rg_resolve_method_func(stype, "op_index", true);
    if getter == null {
        return false;
    }
    if getter.ret_struct_ptr {
        !!! `@T` for a struct.
        return true;
    }
    return rg_is_at_type(getter.func_ret_type);
}

!!! Receiver type an index-store statement applies its subscript to: the variable's
!!! type, or the type reached through the fields that come before the index. The
!!! fields walked are left in rg_index_store_receiver_type_out_prefix.
str rg_index_store_receiver_type -> @StmtNode s {
    rg_index_store_receiver_type_out_prefix = null;
    str cnode = rg_operator_name_struct_type(s.var_name);
    if cnode == "" {
        return "";
    }
    int npre = s.members_before_index;
    if npre < 0 {
        npre = 0;
    }
    int i = 0;
    @StrNode mc = s.member_chain;
    while i < npre && mc != null {
        rg_resolve_field_out_decl_type = "";
        @StructField f = rg_resolve_field(cnode, mc.s, true);
        if f == null || f.struct_type == "" {
            return "";
        }
        rg_index_store_receiver_type_out_prefix =
            rg_strchain_append(rg_index_store_receiver_type_out_prefix, mc.s);
        cnode = f.struct_type;
        mc = mc.next;
        i = i + 1;
    }
    return cnode;
}

!!! Mark `a[i] = v` / `a[i].field = v` as a store through the address a
!!! pointer-returning `[]` hands back.
bool rg_mark_index_ptr_store -> @StmtNode s {
    if s == null || s.nk != ASSIGN || !s.is_array {
        return false;
    }
    if s.expr == null || s.assign_indices != null {
        !!! One index only.
        return false;
    }
    if s.array_init == null {
        return false;
    }
    str recv_type = rg_index_store_receiver_type(s);
    if recv_type == "" || !rg_index_getter_is_pointer(recv_type) {
        return false;
    }
    s.is_index_ptr_store = true;
    return true;
}

!!! `@int operator []` returns a pointer; reading `a[i]` yields the value it points
!!! at, so the call is dereferenced. A struct element needs no dereference: its value
!!! already is its address. The call is the global rw_sub_call, which this replaces.
@ExprNode rw_sub_call;

void rw_deref_pointer_subscript -> @StmtNode getter {
    @ExprNode call = rw_sub_call;
    if call == null || getter == null || getter.ret_struct_ptr {
        end;
    }
    if !rg_is_at_type(getter.func_ret_type) {
        !!! Not a pointer.
        end;
    }
    @ExprNode deref = p_new_expr(UNARY);
    deref.line = call.line;
    deref.col = call.col;
    deref.tok_len = call.tok_len;
    deref.op = "$";
    deref.left = call;
    deref.result_type = rg_deref_of(getter.func_ret_type);
    rw_sub_call = deref;
}

!!! Rewrite one binary operator node when an operand is a struct that declares it. The
!!! node is the global rg_rewrite_binary_operator_out_n, which this replaces.
void rg_rewrite_binary_operator {
    @ExprNode n = rg_rewrite_binary_operator_out_n;
    str sym = n.op;
    str mname = operator_method_name(sym, 1);
    if !op_ok {
        !!! Not an overloadable binary operator.
        end;
    }
    str ls = rg_operator_struct_type(n.left);
    str rs = rg_operator_struct_type(n.right);
    if ls == "" && rs == "" {
        !!! A plain scalar operator.
        end;
    }
    !!! A `@T` is an address, not the object: `p + 1` walks the block by T's size and
    !!! `p == q` compares two addresses, so neither is a use of T's own operator.
    if ls != "" && rg_pointer_operand(n.left) {
        ls = "";
    }
    if rs != "" && rg_pointer_operand(n.right) {
        rs = "";
    }
    if ls == "" && rs == "" {
        end;
    }
    !!! A pointer compared with the null literal is a pointer comparison, not a use of
    !!! the struct's own `operator ==`.
    if p_text_eq(sym, "==") || p_text_eq(sym, "!=") {
        bool left_nullish = false;
        if n.left != null {
            if n.left.nk == LIT_NULL || n.left.result_type == AT_VOID {
                left_nullish = true;
            }
        }
        bool right_nullish = false;
        if n.right != null {
            if n.right.nk == LIT_NULL || n.right.result_type == AT_VOID {
                right_nullish = true;
            }
        }
        if left_nullish || right_nullish {
            end;
        }
    }
    !!! The left operand first, then the right one (so `2 * vec` works too). The method
    !!! each side resolves to is kept: it is the one the operator is applied through,
    !!! so its access level is the one that decides.
    @StmtNode left_m = null;
    if ls != "" {
        left_m = rg_resolve_method_func(ls, mname, true);
    }
    @StmtNode right_m = null;
    if rs != "" {
        right_m = rg_resolve_method_func(rs, mname, true);
    }
    bool left_ok = left_m != null;
    bool right_ok = right_m != null;
    if !left_ok && !right_ok {
        rg_report_no_operator(n, sym);
        end;
    }
    @ExprNode recv = null;
    @ExprNode arg = null;
    @StmtNode chosen = null;
    str call_name = mname;
    if left_ok {
        chosen = left_m;
        recv = n.left;
        arg = n.right;
    } else {
        !!! The struct is the right operand (`5 + v`, `5 < v`). Only the operators whose
        !!! meaning does not depend on the order can be written this way: the
        !!! commutative ones are kept, the comparisons are mirrored, and the rest would
        !!! silently compute the wrong thing.
        str mirror = "";
        bool bad = false;
        if p_text_eq(sym, "+") || p_text_eq(sym, "*") || p_text_eq(sym, "&") ||
           p_text_eq(sym, "|") || p_text_eq(sym, "^") || p_text_eq(sym, "==") ||
           p_text_eq(sym, "!=") {
            mirror = "";
        } else if p_text_eq(sym, "<") {
            mirror = ">";
        } else if p_text_eq(sym, ">") {
            mirror = "<";
        } else if p_text_eq(sym, "<=") {
            mirror = ">=";
        } else if p_text_eq(sym, ">=") {
            mirror = "<=";
        } else {
            bad = true;
        }
        if bad {
            str msg = "operator '" + sym + "' of type '" + rs +
                      "' cannot be written with a value on its left";
            int hl = n.tok_len;
            if hl <= 0 {
                hl = 1;
            }
            rg_fmt_err(n.line, n.col, msg, hl, (str)null, 0, true);
            rg_has_errors = true;
            end;
        }
        if mirror != "" {
            str mm = operator_method_name(mirror, 1);
            if !op_ok {
                rg_report_no_operator(n, sym);
                end;
            }
            @StmtNode mirror_m = null;
            if rs != "" {
                mirror_m = rg_resolve_method_func(rs, mm, true);
            }
            if mirror_m == null {
                rg_report_no_operator(n, sym);
                end;
            }
            call_name = mm;
            chosen = mirror_m;
        } else {
            chosen = right_m;
        }
        recv = n.right;
        arg = n.left;
    }
    !!! The operator is applied here, so one the type keeps to itself may not be
    !!! reached: the type that declares the chosen version decides.
    if chosen != null {
        rg_check_member_access(chosen.struct_type, call_name, chosen.access, n.line, n.col);
    }
    @ExprNode call = p_new_expr(FUNC_CALL);
    call.line = n.line;
    call.col = n.col;
    call.tok_len = n.tok_len;
    call.var_name = call_name;
    call.has_receiver = true;
    call.args = p_chain_expr(call.args, recv);
    call.args = p_chain_expr(call.args, arg);
    rg_rewrite_binary_operator_out_n = call;
    !!! The operand that is not a struct is a value: when the operator's parameter is a
    !!! struct, the type's converting constructor builds it.
    rg_wrap_arguments(call_name, call.args, 1, true, call.args, call.line, call.col,
                      call.tok_len, false);
}

!!! The same for a unary operator: the operand becomes the receiver of a call with no
!!! further arguments.
void rg_rewrite_unary_operator {
    @ExprNode n = rg_rewrite_unary_operator_out_n;
    str sym = n.op;
    str mname = operator_method_name(sym, 0);
    if !op_ok {
        end;
    }
    str ls = rg_operator_struct_type(n.left);
    if ls == "" {
        end;
    }
    @StmtNode um = rg_resolve_method_func(ls, mname, true);
    if um == null {
        rg_report_no_operator(n, sym);
        end;
    }
    !!! The operator is applied here, so its own access level decides.
    rg_check_member_access(um.struct_type, mname, um.access, n.line, n.col);
    @ExprNode recv = n.left;
    @ExprNode call = p_new_expr(FUNC_CALL);
    call.line = n.line;
    call.col = n.col;
    call.tok_len = n.tok_len;
    call.var_name = mname;
    call.has_receiver = true;
    call.args = p_chain_expr(call.args, recv);
    rg_rewrite_unary_operator_out_n = call;
}

!!! `a[i]` on a struct type that declares `[]` becomes `a.op_index(i)`; several
!!! indices chain one call per subscript. The receiver may also be a struct-valued
!!! field (`o.vec[i]`), which arrives as a FIELD_ELEM node.
void rg_rewrite_subscript {
    @ExprNode n = rg_rewrite_subscript_out_n;
    if n.nk == FIELD_ELEM {
        str st = rg_expr_struct_type(n.left);
        if st == "" {
            end;
        }
        !!! Without `[]` this is an element of an inline array field, which the
        !!! ordinary path handles.
        @StmtNode getter = rg_resolve_method_func(st, "op_index", true);
        if getter == null {
            end;
        }
        @ExprNode recv = n.left;
        @ExprNode idx = n.right;
        @ExprNode call = p_new_expr(FUNC_CALL);
        call.line = n.line;
        call.col = n.col;
        call.tok_len = n.tok_len;
        call.var_name = "op_index";
        call.has_receiver = true;
        call.args = p_chain_expr(call.args, recv);
        call.args = p_chain_expr(call.args, idx);
        rw_sub_call = call;
        rw_deref_pointer_subscript(getter);
        rg_rewrite_subscript_out_n = rw_sub_call;
        end;
    }
    if n.nk != ARRAY_ACCESS {
        end;
    }
    !!! A heap array is indexed by the ordinary array path, never by a subscript
    !!! operator: `P arr[3]; arr[0]` is an element of `arr`, not `arr[0]` on `P`. One
    !!! index past the array's own dimensions is a subscript on the element itself:
    !!! `Vec v[2]; v[0][1]` becomes `v[0].op_index(1)`.
    @RgBoolMap ait = rg_boolmap_find(rg_sym_is_array, n.var_name);
    if ait != null && ait.v {
        rw_collect_array_indices(n);
        !!! the toolchain keeps these pointers in a vector; here they go into a chain of
        !!! RgExprRef cells, because `rw_make_element_access` below unlinks the leading
        !!! indices and a walk over the nodes' own `next` would then lose the rest.
        @RgExprRef idx2 = null;
        @ExprNode ic = rw_idx;
        while ic != null {
            @ExprNode icn = ic.next;
            idx2 = rg_exprref_append(idx2, ic);
            ic = icn;
        }
        int got = rgx_exprref_n(idx2);
        int dims = rg_array_var_dims(n.var_name);
        if dims <= 0 || got <= dims {
            !!! An ordinary access.
            end;
        }
        str elem = rg_operator_name_struct_type(n.var_name);
        !!! One call per extra index: the first selects the element, every further one
        !!! is a subscript on the previous result. Each level has to hand back a struct
        !!! for the next one to index.
        @StmtNode getters = null;
        int ng = 0;
        str cur_type = elem;
        int k = dims;
        while k < got {
            @StmtNode g = null;
            if cur_type != "" {
                g = rg_resolve_method_func(cur_type, "op_index", true);
            }
            if g == null {
                skip;
            }
            getters = rgx_ow_stmt_add(getters, g);
            ng = ng + 1;
            cur_type = g.ret_struct;
            k = k + 1;
        }
        if ng > 0 && ng == got - dims {
            @ExprNode cnode = rw_make_element_access(n.var_name, n.line, n.col, n.tok_len, dims,
                                                   elem);
            !!! The moved indices are owned by `cnode` now.
            n.indices = null;
            n.left = null;
            @StmtNode gl = getters;
            k = dims;
            while k < got {
                @ExprNode c2 = p_new_expr(FUNC_CALL);
                c2.line = n.line;
                c2.col = n.col;
                c2.tok_len = n.tok_len;
                c2.var_name = "op_index";
                c2.has_receiver = true;
                c2.args = p_chain_expr(c2.args, cnode);
                @ExprNode ik = rwx_ref_at(idx2, k);
                !!! The index is detached before it is appended: a node still linked to
                !!! the index that follows it would drag that one into the argument
                !!! chain as a third argument of this call.
                if ik != null {
                    ik.next = null;
                }
                c2.args = p_chain_expr(c2.args, ik);
                cnode = c2;
                if k + 1 == got {
                    rw_sub_call = cnode;
                    rw_deref_pointer_subscript(gl);
                    cnode = rw_sub_call;
                }
                gl = gl.next;
                k = k + 1;
            }
            rg_rewrite_subscript_out_n = cnode;
            end;
        }
        !!! Nothing can use the extra indices: the element has no subscript.
        rg_report_too_many_indices(n.var_name, dims, got, n.line, n.col, n.tok_len);
        end;
    }
    str st2 = rg_operator_name_struct_type(n.var_name);
    if st2 == "" {
        end;
    }
    !!! An indexed `@T` name is pointer subscripting - the element at index i - and an
    !!! indexed array name is plain array subscripting: only a struct *value* hands its
    !!! subscripting to an operator.
    bool indexed_plain = rg_pointer_operand_name(n.var_name);
    if !indexed_plain {
        if rg_effective_var_decl(n.var_name) {
            indexed_plain = rg_effective_var_decl_out.is_array;
        } else {
            @RgBoolMap ait2 = rg_boolmap_find(rg_sym_is_array, n.var_name);
            if ait2 != null && ait2.v {
                indexed_plain = true;
            }
            @RgBoolMap oa = rg_boolmap_find(rg_op_body_array, n.var_name);
            if oa != null && oa.v {
                indexed_plain = true;
            }
        }
    }
    if indexed_plain {
        end;
    }
    @StmtNode getter3 = rg_resolve_method_func(st2, "op_index", true);
    if getter3 == null {
        rg_report_no_operator_at(st2, "[]", n.line, n.col, n.tok_len);
        end;
    }
    rw_collect_array_indices(n);
    @ExprNode idx3 = rw_idx;
    if idx3 == null {
        end;
    }
    @ExprNode base = p_new_expr(VAR_REF);
    base.line = n.line;
    base.col = n.col;
    base.var_name = n.var_name;
    base.tok_len = pe_len(n.var_name);
    @ExprNode cur3 = base;
    @ExprNode ik3 = idx3;
    while ik3 != null {
        @ExprNode ik3n = ik3.next;
        @ExprNode c3 = p_new_expr(FUNC_CALL);
        c3.line = n.line;
        c3.col = n.col;
        c3.tok_len = n.tok_len;
        c3.var_name = "op_index";
        c3.has_receiver = true;
        c3.args = p_chain_expr(c3.args, cur3);
        !!! The index is detached first, so the argument chain is the receiver and this
        !!! index alone (a node still linked to the next index would add it as well).
        ik3.next = null;
        c3.args = p_chain_expr(c3.args, ik3);
        cur3 = c3;
        ik3 = ik3n;
    }
    n.left = null;
    n.indices = null;
    rw_sub_call = cur3;
    rw_deref_pointer_subscript(getter3);
    rg_rewrite_subscript_out_n = rw_sub_call;
}

@ExprNode rwx_idx_at -> @ExprNode head, int i {
    int k = 0;
    @ExprNode e = head;
    while e != null {
        if k == i {
            return e;
        }
        k = k + 1;
        e = e.next;
    }
    return null;
}

!!! The same read over the chain of RgExprRef cells that stands in for the toolchain vector
!!! of index pointers: `rwx_idx_at` cannot be used once `rw_make_element_access` has
!!! unlinked the leading indices from the chain they came in on.
@ExprNode rwx_ref_at -> @RgExprRef head, int i {
    int k = 0;
    @RgExprRef e = head;
    while e != null {
        if k == i {
            return e.e;
        }
        k = k + 1;
        e = e.next;
    }
    return null;
}

@StmtNode rgx_ow_stmt_add -> @StmtNode head, @StmtNode node {
    if head == null {
        return node;
    }
    @StmtNode t = head;
    while t.next != null {
        t = t.next;
    }
    t.next = node;
    return head;
}

!!! Bytes of the flattened leaves of a struct (0 when it is not a struct).
int rg_struct_flat_size -> str stype {
    if stype == "" || p_find_struct(stype) == null {
        return 0;
    }
    rg_collect_flat_fields_out = null;
    rg_collect_flat_fields_out_visited = null;
    rg_collect_flat_fields(stype);
    int es = 0;
    @RgFlatPair pr = rg_collect_flat_fields_out;
    while pr != null {
        es = es + rg_field_byte_size(pr.field);
        pr = pr.next;
    }
    return es;
}

!!! Pointee type of the element pointer a `[]` hands back.
VarType rg_index_pointer_pointee -> str stype {
    @StmtNode g = rg_resolve_method_func(stype, "op_index", true);
    if g == null {
        return INT;
    }
    if !rg_is_at_type(g.func_ret_type) {
        return INT;
    }
    return rg_deref_of(g.func_ret_type);
}

!!! Store `value` at the element address `addr`: the whole element, or the field named
!!! by `fields` inside it.
bool rg_emit_store_at_pointer -> str addr, str elem, str owner, @StrNode fields, @ExprNode value {
    if fields == null {
        if elem == "" {
            !!! A scalar element: only the pointed-to value fits.
            rg_rcode = rg_rcode + "CAST (FLDP " + addr + " 0 " + rg_rtype(rg_index_pointer_pointee(owner)) +
                       ") , ";
            rg_rc_expr(value);
            rg_rcode = rg_rcode + "\n";
            return true;
        }
        rg_emit_struct_source_address_out = "";
        if !rg_emit_struct_source_address(value) {
            return false;
        }
        rg_emit_struct_leaf_copy(addr, elem, rg_emit_struct_source_address_out);
        return true;
    }
    str t = elem;
    int off = 0;
    @StructField leaf = null;
    @StrNode fn = fields;
    while fn != null {
        if t == "" {
            return false;
        }
        rg_resolve_field_out_decl_type = "";
        @StructField f = rg_resolve_field(t, fn.s, true);
        if f == null {
            return false;
        }
        str dt = rg_resolve_field_out_decl_type;
        int fo = rg_field_offset_in(t, fn.s, dt);
        if fo < 0 {
            return false;
        }
        off = off + fo;
        t = f.struct_type;
        leaf = f;
        fn = fn.next;
    }
    if leaf == null {
        return false;
    }
    if leaf.struct_type == "" || leaf.struct_ptr {
        rg_rcode = rg_rcode + "CAST (FLDP " + addr + " " + (str)off + " " +
                   rg_rtype(rg_field_eff_type(leaf)) + ") , ";
        rg_rc_expr(value);
        rg_rcode = rg_rcode + "\n";
        return true;
    }
    rg_emit_struct_source_address_out = "";
    if !rg_emit_struct_source_address(value) {
        return false;
    }
    str dst = addr;
    if off != 0 {
        dst = "((@void " + addr + ") , " + (str)off + " , +)";
    }
    rg_emit_struct_leaf_copy(dst, leaf.struct_type, rg_emit_struct_source_address_out);
    return true;
}

!!! One subscript level waiting for its changed copy to be written back (`[]=`).

@RwPending rwx_pending_add -> @RwPending head, str ty, str recv, str ix, str tmp {
    RwPending proto;
    @RwPending n;
    malloc(@n, size proto);
    n.ty = ty;
    n.recv = recv;
    n.ix = ix;
    n.tmp = tmp;
    n.next = null;
    if head == null {
        return n;
    }
    @RwPending t = head;
    while t.next != null {
        t = t.next;
    }
    t.next = n;
    return head;
}

!!! Plan a store written through a chain of subscripts. The leading `dims` indices
!!! select an element of a heap array when the receiver is one; every further index is
!!! a subscript on a struct value, and each of those but the last reads its element by
!!! value, so it needs `[]=` to write the changed copy back. A subscript whose `[]`
!!! hands back a pointer is an lvalue and is written through directly.
bool rg_plan_index_store -> @StmtNode s {
    IndexStorePlan proto;
    @IndexStorePlan plan;
    malloc(@plan, size proto);
    plan.heap_array = false;
    plan.dims = 0;
    plan.first = 0;
    plan.recv_type = "";
    plan.prefix = null;
    plan.idx = null;
    plan.levels = null;
    plan.fields = null;
    rg_plan_index_store_out_plan = plan;
    if s == null || s.nk != ASSIGN || !s.is_array {
        return false;
    }
    if s.array_init == null {
        return false;
    }
    if s.assign_indices != null {
        @ExprNode i = s.assign_indices;
        while i != null {
            plan.idx = rg_exprref_append(plan.idx, i);
            i = i.next;
        }
    } else if s.expr != null {
        plan.idx = rg_exprref_append(plan.idx, s.expr);
    } else {
        return false;
    }
    int npre = s.members_before_index;
    if npre < 0 {
        npre = 0;
    }
    str recv_type = rg_operator_name_struct_type(s.var_name);
    if recv_type == "" {
        return false;
    }
    int i2 = 0;
    @StrNode mc = s.member_chain;
    while i2 < npre && mc != null {
        rg_resolve_field_out_decl_type = "";
        @StructField f = rg_resolve_field(recv_type, mc.s, true);
        if f == null || f.struct_type == "" {
            return false;
        }
        plan.prefix = rg_strchain_append(plan.prefix, mc.s);
        recv_type = f.struct_type;
        mc = mc.next;
        i2 = i2 + 1;
    }
    while mc != null {
        plan.fields = rg_strchain_append(plan.fields, mc.s);
        mc = mc.next;
    }
    int nidx = rgx_exprref_n(plan.idx);
    @RgBoolMap ait = rg_boolmap_find(rg_sym_is_array, s.var_name);
    if npre == 0 && ait != null && ait.v {
        plan.heap_array = true;
        plan.dims = rg_array_var_dims(s.var_name);
        if plan.dims <= 0 {
            return false;
        }
        if nidx <= plan.dims {
            !!! A plain element store.
            return false;
        }
        plan.first = plan.dims;
    } else {
        plan.dims = 0;
        plan.first = 0;
    }
    if plan.first >= nidx {
        return false;
    }
    plan.recv_type = recv_type;
    str cnode = recv_type;
    int k = plan.first;
    while k < nidx {
        bool last = (k + 1 == nidx);
        @StmtNode getter = rg_resolve_method_func(cnode, "op_index", true);
        if getter == null {
            return false;
        }
        IndexChainLevel proto2;
        @IndexChainLevel lv;
        malloc(@lv, size proto2);
        lv.ty = cnode;
        lv.ret = getter.ret_struct;
        lv.ptr = rg_index_getter_is_pointer(cnode);
        lv.setter = null;
        lv.next = null;
        if lv.ptr {
            !!! A pointer is the address of the element; a scalar pointer can only store
            !!! the whole element.
            if lv.ret == "" && (!last || plan.fields != null) {
                return false;
            }
        } else {
            lv.setter = rg_resolve_method_func(cnode, "op_index_set", true);
            if lv.setter == null {
                return false;
            }
            if !last && lv.ret == "" {
                return false;
            }
        }
        !!! The fields written inside the last element have to exist.
        if last && plan.fields != null {
            if lv.ret == "" {
                return false;
            }
            str t = lv.ret;
            @StrNode fn = plan.fields;
            while fn != null {
                rg_resolve_field_out_decl_type = "";
                @StructField f2 = rg_resolve_field(t, fn.s, true);
                if f2 == null {
                    return false;
                }
                t = f2.struct_type;
                fn = fn.next;
            }
        }
        plan.levels = rg_chainlevel_append(plan.levels, lv);
        if last {
            skip;
        }
        cnode = lv.ret;
        if cnode == "" {
            return false;
        }
        k = k + 1;
    }
    if plan.levels == null {
        return false;
    }
    return true;
}

int rgx_exprref_n -> @RgExprRef head {
    int n = 0;
    @RgExprRef e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

!!! A subscript store into an element of a heap array that cannot be expressed: say
!!! which subscript operator is missing.
void rg_report_index_store_unsupported -> @StmtNode s {
    @ExprNode idx = null;
    if s.assign_indices != null {
        !!! The indices are the chain already (see rw_collect_array_indices): copying
        !!! them link by link made the last node point at itself.
        idx = s.assign_indices;
    } else if s.expr != null {
        idx = s.expr;
    }
    int got = rgx_rw_expr_n(idx);
    int dims = rg_array_var_dims(s.var_name);
    str cnode = rg_operator_name_struct_type(s.var_name);
    if cnode == "" || rg_resolve_method_func(cnode, "op_index", true) == null {
        rg_report_too_many_indices(s.var_name, dims, got, s.line, s.col, 1);
        end;
    }
    int k = dims;
    while k < got {
        @StmtNode getter = rg_resolve_method_func(cnode, "op_index", true);
        if getter == null {
            rg_report_no_operator_at(cnode, "[]", s.line, s.col, 1);
            end;
        }
        if !rg_index_getter_is_pointer(cnode) {
            if rg_resolve_method_func(cnode, "op_index_set", true) == null {
                rg_report_no_operator_at(cnode, "[]=", s.line, s.col, 1);
                end;
            }
        }
        cnode = getter.ret_struct;
        if cnode == "" && k + 1 < got {
            str msg = "assignment through '[]' of an array element is not supported";
            rg_fmt_err(s.line, s.col, msg, 1, (str)null, 0, true);
            rg_has_errors = true;
            end;
        }
        k = k + 1;
    }
    str msg2 = "assignment through '[]' of an array element is not supported; read the " +
               "element, change the copy and store it back";
    rg_fmt_err(s.line, s.col, msg2, 1, (str)null, 0, true);
    rg_has_errors = true;
}

!!! Emit the store a plan describes.
bool rg_emit_index_chain_store -> @StmtNode s {
    if s == null || !s.is_index_chain_store {
        return false;
    }
    if !rg_plan_index_store(s) {
        return false;
    }
    @IndexStorePlan plan = rg_plan_index_store_out_plan;
    @ExprNode value = s.array_init;
    !!! Every index is evaluated once, before anything is stored.
    @StrNode ixs = null;
    @RgExprRef e = plan.idx;
    while e != null {
        rg_tmp_var_counter = rg_tmp_var_counter + 1;
        str ix = "__ix" + (str)rg_tmp_var_counter;
        rg_rcode = rg_rcode + "DECLARED INT " + ix + " , ";
        rg_rc_expr(e.e);
        rg_rcode = rg_rcode + "\n";
        rg_syms = rg_vartypemap_set(rg_syms, ix, INT);
        rg_sym_depth = rg_intmap_set(rg_sym_depth, ix, 0);
        ixs = rg_strchain_append(ixs, ix);
        e = e.next;
    }
    !!! The receiver of the first subscript.
    str recv = "";
    if plan.heap_array {
        int esz = rg_struct_flat_size(plan.recv_type);
        if esz <= 0 {
            return false;
        }
        !!! The element the leading indices select: one index is the element offset
        !!! itself, several are flattened row by row (`m[i][j]` -> i * dims[1] + j).
        str lin = rwx_str_at(ixs, 0);
        @RgDimsMap dit = rg_dimmap_find(rg_sym_dims, s.var_name);
        int k = 1;
        while k < plan.first {
            longlong d = 1;
            if dit != null && dit.n > k {
                d = rwx_long_at(dit.dims, k);
            }
            if d <= 0 {
                d = 1;
            }
            lin = "((" + lin + " , " + (str)d + " , *) , " + rwx_str_at(ixs, k) + " , +)";
            k = k + 1;
        }
        recv = "((@void " + s.var_name + ") , (" + lin + " , " + (str)esz + " , *) , +)";
    } else if plan.prefix == null {
        recv = "(AT " + s.var_name + ")";
    } else {
        rg_emit_field_chain_address_out = "";
        if !rg_emit_field_chain_address(s.var_name,
                                        rg_operator_name_struct_type(s.var_name), plan.prefix) {
            return false;
        }
        recv = rg_emit_field_chain_address_out;
    }
    !!! An address that has to be computed cannot be passed as a call argument directly
    !!! (the argument setup loses a scaled expression), so it goes into a pointer local
    !!! first.
    if pp_find_from(recv, "*", 0) >= 0 {
        rg_tmp_var_counter = rg_tmp_var_counter + 1;
        str pr = "__ar" + (str)rg_tmp_var_counter;
        rg_rcode = rg_rcode + "DECLARED AT_VOID " + pr + " , " + recv + "\n";
        rg_syms = rg_vartypemap_set(rg_syms, pr, INT);
        rg_sym_depth = rg_intmap_set(rg_sym_depth, pr, 1);
        recv = pr;
    }
    @RwPending pending = null;
    int nidx = rgx_exprref_n(plan.idx);
    k = plan.first;
    while k < nidx {
        @IndexChainLevel lv = rwx_level_at(plan.levels, k - plan.first);
        !!! The subscript is applied here: the getter always, the setter only when the
        !!! store writes through it. Either may be one the type keeps to itself, and
        !!! then it cannot be reached from here.
        @StmtNode lvg = rg_resolve_method_func(lv.ty, "op_index", true);
        if lvg != null {
            rg_check_member_access(lvg.struct_type, "op_index", lvg.access, s.line, s.col);
        }
        if !lv.ptr {
            @StmtNode lvs = rg_resolve_method_func(lv.ty, "op_index_set", true);
            if lvs != null {
                rg_check_member_access(lvs.struct_type, "op_index_set", lvs.access,
                                       s.line, s.col);
            }
        }
        str ix = rwx_str_at(ixs, k);
        bool last = (k + 1 == nidx);
        if lv.ptr {
            rg_tmp_var_counter = rg_tmp_var_counter + 1;
            str px = "__px" + (str)rg_tmp_var_counter;
            rg_rcode = rg_rcode + "DECLARED AT_VOID " + px + " , (CALL_EXPR __m_" + lv.ty +
                       "_op_index , " + recv + " , " + ix + ")\n";
            rg_syms = rg_vartypemap_set(rg_syms, px, INT);
            rg_sym_depth = rg_intmap_set(rg_sym_depth, px, 1);
            if last {
                return rg_emit_store_at_pointer(px, lv.ret, lv.ty, plan.fields, value);
            }
            recv = px;
            k = k + 1;
            continue;
        }
        str tmp = "";
        if !last || plan.fields != null {
            !!! The element this subscript selects, read into a copy.
            if lv.ret == "" {
                return false;
            }
            rg_tmp_var_counter = rg_tmp_var_counter + 1;
            tmp = "__ie" + (str)rg_tmp_var_counter;
            rg_rcode = rg_rcode + "DECLARED STRUCT " + lv.ret + " " + tmp + " , {}\n";
            rg_rcode = rg_rcode + "CAST " + tmp + " , (CALL_EXPR __m_" + lv.ty + "_op_index , " +
                       recv + " , " + ix + ")\n";
            rg_syms = rg_vartypemap_set(rg_syms, tmp, INT);
            rg_sym_struct_type = rg_strmap_set(rg_sym_struct_type, tmp, lv.ret);
            rg_sym_depth = rg_intmap_set(rg_sym_depth, tmp, 0);
        }
        if !last {
            !!! The element is a copy: remember to write the changed copy back.
            pending = rwx_pending_add(pending, lv.ty, recv, ix, tmp);
            recv = "(AT " + tmp + ")";
            k = k + 1;
            continue;
        }
        if plan.fields == null {
            rg_rcode = rg_rcode + "CALL __m_" + lv.ty + "_op_index_set " + recv + " , " + ix + " , ";
            rg_emit_call_arg_value(value);
            rg_rcode = rg_rcode + "\n";
        } else {
            if !rg_emit_store_at_pointer("(AT " + tmp + ")", lv.ret, lv.ty, plan.fields, value) {
                return false;
            }
            rg_rcode = rg_rcode + "CALL __m_" + lv.ty + "_op_index_set " + recv + " , " + ix +
                       " , (AT " + tmp + ")\n";
        }
        k = k + 1;
    }
    !!! The changed copies are written back innermost first: the list is walked to its
    !!! end and back, which the toolchain does with a reverse iteration.
    pending = rwx_pending_reverse(pending);
    @RwPending p = pending;
    while p != null {
        rg_rcode = rg_rcode + "CALL __m_" + p.ty + "_op_index_set " + p.recv + " , " + p.ix +
                   " , (AT " + p.tmp + ")\n";
        p = p.next;
    }
    return true;
}

@RwPending rwx_pending_reverse -> @RwPending head {
    @RwPending out = null;
    @RwPending e = head;
    while e != null {
        @RwPending nx = e.next;
        e.next = out;
        out = e;
        e = nx;
    }
    return out;
}

str rwx_str_at -> @StrNode head, int i {
    int k = 0;
    @StrNode e = head;
    while e != null {
        if k == i {
            return e.s;
        }
        k = k + 1;
        e = e.next;
    }
    return "";
}

longlong rwx_long_at -> @RgLongNode head, int i {
    int k = 0;
    @RgLongNode e = head;
    while e != null {
        if k == i {
            return e.v;
        }
        k = k + 1;
        e = e.next;
    }
    return 1;
}

@IndexChainLevel rwx_level_at -> @IndexChainLevel head, int i {
    int k = 0;
    @IndexChainLevel e = head;
    while e != null {
        if k == i {
            return e;
        }
        k = k + 1;
        e = e.next;
    }
    return null;
}

!!! `a[i] = v` on a struct type that declares `[]=` becomes `a.op_index_set(i, v)`. The
!!! receiver may be a struct-valued field (`o.vec[0] = v`). A single index is stored on
!!! the statement as `expr`, several as `assign_indices`, and the value as the first
!!! initializer entry.
bool rg_rewrite_subscript_assign -> @StmtNode s {
    if s.nk != ASSIGN || !s.is_array {
        return false;
    }
    if s.array_init == null {
        return false;
    }
    @ExprNode idx = null;
    if s.assign_indices != null {
        !!! The indices are the chain already (see rw_collect_array_indices). The loop
        !!! that copied them link by link relinked the last node's own `next` onto the
        !!! end of the chain it was being copied into, which made the chain a ring and
        !!! hung this pass on every store with two subscripts.
        idx = s.assign_indices;
    } else if s.expr != null {
        idx = s.expr;
    } else {
        return false;
    }
    int nidx = rgx_rw_expr_n(idx);
    int npre = s.members_before_index;
    if npre < 0 {
        npre = 0;
    }
    !!! A field written after the index belongs to the element, not to the receiver
    !!! (`a[i].field = v`): the read-modify-write path handles it. A heap array indexed
    !!! past its own dimensions (`Vec v[2]; v[0][1] = 11`) or with a field written
    !!! after those subscripts (`arr[i][j].x = v`): the leading indices select the
    !!! element and the rest are subscripts on the element itself, emitted as a chain
    !!! of subscript stores.
    if npre == 0 {
        @RgBoolMap ait = rg_boolmap_find(rg_sym_is_array, s.var_name);
        if ait != null && ait.v {
            int dims = rg_array_var_dims(s.var_name);
            if dims > 0 && nidx > dims {
                if rg_plan_index_store(s) {
                    s.is_index_chain_store = true;
                    return true;
                }
                rg_report_index_store_unsupported(s);
                !!! Reported: no ordinary multi-index store.
                return true;
            }
        }
    }
    !!! A heap array is indexed by the ordinary array path, never by a subscript
    !!! operator (`P arr[3]; arr[0] = p`).
    if npre == 0 {
        @RgBoolMap ait2 = rg_boolmap_find(rg_sym_is_array, s.var_name);
        if ait2 != null && ait2.v {
            return false;
        }
    }
    !!! The receiver: the variable itself, or a chain of struct-valued fields.
    @ExprNode base = p_new_expr(VAR_REF);
    base.line = s.line;
    base.col = s.col;
    base.var_name = s.var_name;
    base.tok_len = pe_len(s.var_name);
    @ExprNode recv = base;
    int mi = 0;
    @StrNode mc = s.member_chain;
    while mi < npre && mc != null {
        @ExprNode m = p_new_expr(MEMBER_ACCESS);
        if s.member_line != 0 {
            m.line = s.member_line;
        } else {
            m.line = s.line;
        }
        if s.member_col != 0 {
            m.col = s.member_col;
        } else {
            m.col = s.col;
        }
        m.tok_len = pe_len(mc.s);
        m.left = recv;
        m.member_name = mc.s;
        m.var_name = mc.s;
        recv = m;
        mc = mc.next;
        mi = mi + 1;
    }
    if !rg_receiver_info(recv, false) || rg_receiver_info_out_stype == "" {
        return false;
    }
    str st = rg_receiver_info_out_stype;
    if rg_resolve_method_func(st, "op_index_set", true) == null {
        !!! A type with `[]` but no `[]=` is a subscript that cannot be written through;
        !!! a type with neither is an ordinary array, which the ordinary store handles
        !!! (`o.data[i] = v` on an inline array field).
        if rg_resolve_method_func(st, "op_index", true) == null {
            return false;
        }
        rg_report_no_operator_at(st, "[]=", s.line, s.col, 1);
        return true;
    }
    @ExprNode value = s.array_init;
    !!! The statement becomes the call, exactly like a written `a.op_index_set(i, v)`.
    s.nk = CALL_FUNC;
    s.is_array = false;
    s.is_method_call = true;
    s.var_line = s.line;
    s.var_col = s.col;
    s.var_name = "op_index_set";
    s.expr = null;
    s.assign_indices = null;
    s.member_chain = null;
    s.member_name = "";
    s.array_init = null;
    s.args = p_chain_expr(s.args, recv);
    @ExprNode i2 = idx;
    while i2 != null {
        @ExprNode nx = i2.next;
        i2.next = null;
        s.args = p_chain_expr(s.args, i2);
        i2 = nx;
    }
    s.args = p_chain_expr(s.args, value);
    return true;
}

!!! `a[i].field = v` where `[]` returns the element by value: the element is read into
!!! a temporary, the field is stored in the copy and the copy is written back with
!!! `[]=`. The layout is left in the globals rgen.b declares for it.
bool rg_index_field_layout -> @StmtNode s {
    rg_index_field_layout_out_receiver_type = "";
    rg_index_field_layout_out_elem = "";
    rg_index_field_layout_out_prefix = null;
    rg_index_field_layout_out_off = 0;
    rg_index_field_layout_out_leaf = null;
    if s == null || s.nk != ASSIGN || !s.is_array {
        return false;
    }
    if s.member_chain == null || s.array_init == null {
        return false;
    }
    if s.expr == null || s.assign_indices != null {
        !!! One index only.
        return false;
    }
    int npre = s.members_before_index;
    if npre < 0 {
        npre = 0;
    }
    int nmem = rgx_fc_n(s.member_chain);
    if npre >= nmem {
        !!! No field after the index.
        return false;
    }
    str cnode = rg_operator_name_struct_type(s.var_name);
    if cnode == "" {
        return false;
    }
    @StrNode mc = s.member_chain;
    int i = 0;
    while i < npre && mc != null {
        rg_resolve_field_out_decl_type = "";
        @StructField f = rg_resolve_field(cnode, mc.s, true);
        if f == null || f.struct_type == "" {
            return false;
        }
        rg_index_field_layout_out_prefix = rg_strchain_append(rg_index_field_layout_out_prefix, mc.s);
        cnode = f.struct_type;
        mc = mc.next;
        i = i + 1;
    }
    rg_index_field_layout_out_receiver_type = cnode;
    @StmtNode getter = rg_resolve_method_func(cnode, "op_index", true);
    if getter == null || getter.ret_struct == "" {
        !!! The element must be a struct.
        return false;
    }
    rg_index_field_layout_out_elem = getter.ret_struct;
    !!! The fields after the index are the path from the element to the field.
    str t = getter.ret_struct;
    int off = 0;
    @StructField leaf = null;
    while mc != null {
        rg_resolve_field_out_decl_type = "";
        @StructField f2 = rg_resolve_field(t, mc.s, true);
        if f2 == null {
            return false;
        }
        str dt = rg_resolve_field_out_decl_type;
        int fo = rg_field_offset_in(t, mc.s, dt);
        if fo < 0 {
            return false;
        }
        off = off + fo;
        t = f2.struct_type;
        leaf = f2;
        mc = mc.next;
    }
    if leaf == null {
        return false;
    }
    rg_index_field_layout_out_off = off;
    rg_index_field_layout_out_leaf = leaf;
    return true;
}

bool rg_is_index_field_assign -> @StmtNode s {
    if !rg_index_field_layout(s) {
        return false;
    }
    str recv_type = rg_index_field_layout_out_receiver_type;
    if rg_index_getter_is_pointer(recv_type) {
        !!! A direct store.
        return true;
    }
    if rg_resolve_method_func(recv_type, "op_index_set", true) != null {
        return true;
    }
    return false;
}

!!! `a[i] = v` / `a[i].field = v` where `[]` returns `@T`: the getter hands back the
!!! address of the element, so the store is written straight through it. No copy of the
!!! element is made and no `[]=` is needed.
bool rg_emit_index_ptr_store -> @StmtNode s {
    if s == null || !s.is_index_ptr_store {
        return false;
    }
    if s.array_init == null {
        return false;
    }
    rg_index_store_receiver_type_out_prefix = null;
    str recv_type = rg_index_store_receiver_type(s);
    if recv_type == "" {
        return false;
    }
    @StmtNode getter = rg_resolve_method_func(recv_type, "op_index", true);
    if getter == null || !rg_index_getter_is_pointer(recv_type) {
        return false;
    }
    !!! The getter is applied here, so one the type keeps to itself cannot be reached
    !!! from this store.
    rg_check_member_access(getter.struct_type, "op_index", getter.access, s.line, s.col);
    str elem = getter.ret_struct;
    !!! Fields after the index name the field inside the element; without one the whole
    !!! element is stored. Resolved before anything is written.
    int npre = s.members_before_index;
    if npre < 0 {
        npre = 0;
    }
    str t = elem;
    int off = 0;
    @StructField leaf = null;
    @StrNode mc = s.member_chain;
    int i = 0;
    while mc != null {
        if i >= npre {
            if t == "" {
                !!! A scalar element has no fields.
                return false;
            }
            rg_resolve_field_out_decl_type = "";
            @StructField f = rg_resolve_field(t, mc.s, true);
            if f == null {
                return false;
            }
            str dt = rg_resolve_field_out_decl_type;
            int fo = rg_field_offset_in(t, mc.s, dt);
            if fo < 0 {
                return false;
            }
            off = off + fo;
            t = f.struct_type;
            leaf = f;
        }
        mc = mc.next;
        i = i + 1;
    }
    !!! The receiver is passed by address, exactly like a struct call argument.
    str recv = "";
    if rg_index_store_receiver_type_out_prefix == null {
        recv = "(AT " + s.var_name + ")";
    } else {
        rg_emit_field_chain_address_out = "";
        if !rg_emit_field_chain_address(s.var_name,
                                        rg_operator_name_struct_type(s.var_name),
                                        rg_index_store_receiver_type_out_prefix) {
            return false;
        }
        recv = rg_emit_field_chain_address_out;
    }
    !!! Index once, then the element address the getter returns.
    rg_tmp_var_counter = rg_tmp_var_counter + 1;
    str ix = "__ix" + (str)rg_tmp_var_counter;
    rg_rcode = rg_rcode + "DECLARED INT " + ix + " , ";
    rg_rc_expr(s.expr);
    rg_rcode = rg_rcode + "\n";
    rg_tmp_var_counter = rg_tmp_var_counter + 1;
    str px = "__px" + (str)rg_tmp_var_counter;
    rg_rcode = rg_rcode + "DECLARED AT_VOID " + px + " , (CALL_EXPR __m_" + recv_type +
               "_op_index , " + recv + " , " + ix + ")\n";
    rg_syms = rg_vartypemap_set(rg_syms, ix, INT);
    rg_sym_depth = rg_intmap_set(rg_sym_depth, ix, 0);
    rg_syms = rg_vartypemap_set(rg_syms, px, INT);
    rg_sym_depth = rg_intmap_set(rg_sym_depth, px, 1);
    @ExprNode value = s.array_init;
    if leaf == null {
        if elem == "" {
            !!! A scalar element (`@int operator []`): store the pointed-to value.
            VarType pointee = INT;
            if rg_is_at_type(getter.func_ret_type) {
                pointee = rg_deref_of(getter.func_ret_type);
            }
            rg_rcode = rg_rcode + "CAST (FLDP " + px + " 0 " + rg_rtype(pointee) + ") , ";
            rg_rc_expr(value);
            rg_rcode = rg_rcode + "\n";
            return true;
        }
        rg_emit_struct_source_address_out = "";
        if !rg_emit_struct_source_address(value) {
            return false;
        }
        rg_emit_struct_leaf_copy(px, elem, rg_emit_struct_source_address_out);
        return true;
    }
    str fields = "";
    if leaf.struct_type == "" || leaf.struct_ptr {
        rg_rcode = rg_rcode + "CAST (FLDP " + px + " " + (str)off + " " +
                   rg_rtype(rg_field_eff_type(leaf)) + ") , ";
        rg_rc_expr(value);
        rg_rcode = rg_rcode + "\n";
        return true;
    }
    rg_emit_struct_source_address_out = "";
    if !rg_emit_struct_source_address(value) {
        return false;
    }
    str dst = px;
    if off != 0 {
        dst = "((@void " + px + ") , " + (str)off + " , +)";
    }
    rg_emit_struct_leaf_copy(dst, leaf.struct_type, rg_emit_struct_source_address_out);
    return true;
}

!!! Emit the read-modify-write for `a[i].field = v`.
bool rg_emit_index_field_assign -> @StmtNode s {
    if !rg_index_field_layout(s) {
        return false;
    }
    str receiver_type = rg_index_field_layout_out_receiver_type;
    str elem = rg_index_field_layout_out_elem;
    int off = rg_index_field_layout_out_off;
    @StructField leaf = rg_index_field_layout_out_leaf;
    @StmtNode fset = rg_resolve_method_func(receiver_type, "op_index_set", true);
    if fset == null {
        return false;
    }
    !!! A read-modify-write through the subscript: both the getter and the setter are
    !!! applied here, so either may be one the type keeps to itself.
    @StmtNode fget = rg_resolve_method_func(receiver_type, "op_index", true);
    if fget != null {
        rg_check_member_access(fget.struct_type, "op_index", fget.access, s.line, s.col);
    }
    rg_check_member_access(fset.struct_type, "op_index_set", fset.access, s.line, s.col);
    !!! The receiver is passed by address, exactly like a struct call argument.
    str recv = "";
    if rg_index_field_layout_out_prefix == null {
        recv = "(AT " + s.var_name + ")";
    } else {
        rg_emit_field_chain_address_out = "";
        if !rg_emit_field_chain_address(s.var_name,
                                        rg_operator_name_struct_type(s.var_name),
                                        rg_index_field_layout_out_prefix) {
            return false;
        }
        recv = rg_emit_field_chain_address_out;
    }
    !!! The index is evaluated once, into a temporary.
    rg_tmp_var_counter = rg_tmp_var_counter + 1;
    str ix = "__ix" + (str)rg_tmp_var_counter;
    rg_rcode = rg_rcode + "DECLARED INT " + ix + " , ";
    rg_rc_expr(s.expr);
    rg_rcode = rg_rcode + "\n";
    !!! Read the element, store the field, write the element back.
    rg_tmp_var_counter = rg_tmp_var_counter + 1;
    str tmp = "__ie" + (str)rg_tmp_var_counter;
    rg_rcode = rg_rcode + "DECLARED STRUCT " + elem + " " + tmp + " , {}\n";
    rg_rcode = rg_rcode + "CAST " + tmp + " , (CALL_EXPR __m_" + receiver_type + "_op_index , " +
               recv + " , " + ix + ")\n";
    rg_rcode = rg_rcode + "CAST (FLD " + tmp + " " + (str)off + " " +
               rg_rtype(rg_field_eff_type(leaf)) + ") , ";
    rg_rc_expr(s.array_init);
    rg_rcode = rg_rcode + "\n";
    rg_rcode = rg_rcode + "CALL __m_" + receiver_type + "_op_index_set " + recv + " , " + ix +
               " , (AT " + tmp + ")\n";
    rg_syms = rg_vartypemap_set(rg_syms, tmp, INT);
    rg_sym_struct_type = rg_strmap_set(rg_sym_struct_type, tmp, elem);
    rg_sym_depth = rg_intmap_set(rg_sym_depth, tmp, 0);
    return true;
}

!!! `(str)v` on a struct type that declares `operator str` becomes `v.op_to_str()`.
void rg_rewrite_conversion {
    @ExprNode n = rg_rewrite_conversion_out_n;
    if n.nk != CAST {
        end;
    }
    str mname = "";
    if p_text_eq(n.op, "toStr") {
        mname = "op_to_str";
    } else if p_text_eq(n.op, "toInt") {
        mname = "op_to_int";
    } else if p_text_eq(n.op, "toFloat") {
        mname = "op_to_float";
    } else if p_text_eq(n.op, "toBool") {
        mname = "op_to_bool";
    } else if p_text_eq(n.op, "toChar") {
        mname = "op_to_char";
    } else {
        end;
    }
    str ls = rg_operator_struct_type(n.left);
    if ls == "" {
        !!! An ordinary builtin conversion.
        end;
    }
    @StmtNode cm = rg_resolve_method_func(ls, mname, true);
    if cm == null {
        str target = pe_sub_to_end(mname, 6);
        str msg = "type '" + ls + "' has no conversion to '" + target + "'";
        int hl = n.tok_len;
        if hl <= 0 {
            hl = 1;
        }
        rg_fmt_err(n.line, n.col, msg, hl, (str)null, 0, true);
        rg_has_errors = true;
        end;
    }
    !!! The conversion operator is applied here, so its own access level decides.
    rg_check_member_access(cm.struct_type, mname, cm.access, n.line, n.col);
    @ExprNode recv = n.left;
    @ExprNode call = p_new_expr(FUNC_CALL);
    call.line = n.line;
    call.col = n.col;
    call.tok_len = n.tok_len;
    call.var_name = mname;
    call.has_receiver = true;
    call.args = p_chain_expr(call.args, recv);
    rg_rewrite_conversion_out_n = call;
}

void rg_rewrite_operator_expr {
    @ExprNode n = rg_rewrite_operator_expr_out_n;
    if n == null {
        end;
    }
    !!! Operands first: an inner operator turns into a call before the operator around
    !!! it is looked at.
    rg_rewrite_operator_expr_out_n = n.left;
    rg_rewrite_operator_expr();
    n.left = rg_rewrite_operator_expr_out_n;
    rg_rewrite_operator_expr_out_n = n.right;
    rg_rewrite_operator_expr();
    n.right = rg_rewrite_operator_expr_out_n;
    @ExprNode a = n.args;
    @ExprNode prev = null;
    while a != null {
        @ExprNode nx = a.next;
        rg_rewrite_operator_expr_out_n = a;
        rg_rewrite_operator_expr();
        @ExprNode rep = rg_rewrite_operator_expr_out_n;
        rep.next = nx;
        if prev == null {
            n.args = rep;
        } else {
            prev.next = rep;
        }
        prev = rep;
        a = nx;
    }
    @ExprNode i = n.indices;
    prev = null;
    while i != null {
        @ExprNode nx2 = i.next;
        rg_rewrite_operator_expr_out_n = i;
        rg_rewrite_operator_expr();
        @ExprNode rep2 = rg_rewrite_operator_expr_out_n;
        rep2.next = nx2;
        if prev == null {
            n.indices = rep2;
        } else {
            prev.next = rep2;
        }
        prev = rep2;
        i = nx2;
    }
    if n.nk == LAMBDA {
        @LambdaRec rec = p_find_lambda(n.lambda_id);
        if rec != null {
            @StmtNode lb = rec.body;
            while lb != null {
                rg_rewrite_operator_stmt(lb);
                lb = lb.next;
            }
        }
    }
    if n.nk == BINOP || n.nk == SHL || n.nk == SHR {
        rg_rewrite_binary_operator_out_n = n;
        rg_rewrite_binary_operator();
        rg_rewrite_operator_expr_out_n = rg_rewrite_binary_operator_out_n;
        end;
    }
    if n.nk == UNARY || n.nk == BITNOT {
        rg_rewrite_unary_operator_out_n = n;
        rg_rewrite_unary_operator();
        rg_rewrite_operator_expr_out_n = rg_rewrite_unary_operator_out_n;
        end;
    }
    if n.nk == ARRAY_ACCESS || n.nk == FIELD_ELEM {
        rg_rewrite_subscript_out_n = n;
        rg_rewrite_subscript();
        rg_rewrite_operator_expr_out_n = rg_rewrite_subscript_out_n;
        end;
    }
    if n.nk == CAST {
        rg_rewrite_conversion_out_n = n;
        rg_rewrite_conversion();
        rg_rewrite_operator_expr_out_n = rg_rewrite_conversion_out_n;
        end;
    }
    if n.nk == FUNC_CALL {
        !!! `system.out(v)` and `printf("%d", v)`: a struct argument of an `any`
        !!! parameter is passed as its own conversion.
        if n.has_receiver && n.args != null {
            rg_wrap_arguments(n.var_name, n.args, 1, true, n.args, n.line, n.col, n.tok_len, false);
        } else {
            rg_wrap_arguments(n.var_name, n.args, 0, false, null, n.line, n.col, n.tok_len, false);
        }
    }
    rg_rewrite_operator_expr_out_n = n;
}

!!! `int operator ==;` has no body: every field of `type` is compared against the same
!!! field of `other`, one storage leaf at a time. Nested struct values are flattened
!!! into leaves, inline array fields are compared element by element.
void rg_emit_synth_comparison -> str stype, str other, str sym {
    rg_collect_leaf_fields_out = null;
    rg_collect_leaf_fields_out_visited = null;
    rg_collect_leaf_fields(stype, 0);
    bool is_eq = p_text_eq(sym, "==");
    str join = "|";
    str cmp = "\\\\";
    str init = "0";
    if is_eq {
        join = "&";
        cmp = "//";
        init = "1";
    }
    !!! `.r` spells equality `//` and inequality `\\`.
    rg_rcode = rg_rcode + "DECLARED INT __cmp , " + init + "\n";
    @FlatField lf = rg_collect_leaf_fields_out;
    while lf != null {
        VarType et = rg_field_eff_type(lf.field);
        str ty = rg_rtype(et);
        !!! An inline array field keeps its elements back to back.
        int elems = 1;
        if lf.field.array_dim > 0 && lf.field.ty != CHAR {
            elems = lf.field.array_dim;
        }
        int es = 0;
        if elems > 1 {
            es = rg_field_elem_size(lf.field);
        }
        int k = 0;
        while k < elems {
            int off = lf.abs_off + k * es;
            rg_rcode = rg_rcode + "CAST __cmp , (__cmp , ((FLD __this " + (str)off + " " + ty +
                       ") , (FLD " + other + " " + (str)off + " " + ty + ") , " + cmp + ") , " +
                       join + ")\n";
            k = k + 1;
        }
        lf = lf.next;
    }
    rg_rcode = rg_rcode + "RET __cmp\n";
}

void rg_rewrite_operator_stmt -> @StmtNode s {
    if s == null {
        end;
    }
    !!! A struct local begins and ends its life here: its `init` runs where it is
    !!! declared and its `destruct` where the scope that declares it ends. This pass
    !!! walks every body - the ones of the methods included, which no type checking
    !!! pass visits - so an `init` or a `destruct` the type keeps to itself is refused
    !!! here, before any emission begins.
    if s.nk == DECLARE && s.struct_type != "" && s.ptr_depth == 0 && !s.is_array {
        @StructDef dsit = p_find_struct(s.struct_type);
        if dsit != null {
            int dl = s.var_line;
            if dl == 0 {
                dl = s.line;
            }
            int dc = s.var_col;
            if dc == 0 {
                dc = s.col;
            }
            if dsit.init_func != null && dsit.init_func.true_body != null {
                rg_check_member_access(s.struct_type, "init", dsit.init_access, dl, dc);
            }
            rg_check_member_access(s.struct_type, "destruct", dsit.destruct_access, dl, dc);
        }
    }
    !!! A store written through a chain of subscripts keeps its ASSIGN form and is
    !!! emitted by rg_emit_index_chain_store; only its expressions are rewritten.
    if s.is_index_chain_store {
        rg_rewrite_operator_expr_out_n = s.expr;
        rg_rewrite_operator_expr();
        s.expr = rg_rewrite_operator_expr_out_n;
        rwx_rewrite_expr_chain(s.array_init);
        rwx_rewrite_expr_chain(s.assign_indices);
        end;
    }
    !!! `a[i] = v` / `a[i].field = v` through a `@T operator []`: the address the getter
    !!! returns is a real lvalue, so the statement stays an ASSIGN and the store is
    !!! emitted through that address.
    if rg_mark_index_ptr_store(s) {
        rg_rewrite_operator_expr_out_n = s.expr;
        rg_rewrite_operator_expr();
        s.expr = rg_rewrite_operator_expr_out_n;
        rwx_rewrite_expr_chain(s.array_init);
        end;
    }
    !!! `a[i].field = v` is emitted as a read-modify-write; only its index and value
    !!! expressions are rewritten here.
    if rg_is_index_field_assign(s) {
        rg_rewrite_operator_expr_out_n = s.expr;
        rg_rewrite_operator_expr();
        s.expr = rg_rewrite_operator_expr_out_n;
        rwx_rewrite_expr_chain(s.array_init);
        end;
    }
    !!! `a[i] = v` is a whole statement, not just an expression.
    if rg_rewrite_subscript_assign(s) {
        !!! The indices and the value the rewrite produced may use operators themselves
        !!! (`a[i] = b + c`), so they are rewritten here too.
        rwx_rewrite_expr_chain(s.args);
        if s.nk == CALL_FUNC {
            if s.is_method_call && s.args != null {
                rg_wrap_arguments(s.var_name, s.args, 1, true, s.args, s.line, s.col, 1, false);
            } else {
                rg_wrap_arguments(s.var_name, s.args, 0, false, null, s.line, s.col, 1, false);
            }
        }
        end;
    }
    rg_rewrite_operator_expr_out_n = s.expr;
    rg_rewrite_operator_expr();
    s.expr = rg_rewrite_operator_expr_out_n;
    rwx_rewrite_expr_chain(s.args);
    rwx_rewrite_expr_chain(s.targ_exprs);
    rwx_rewrite_expr_chain(s.array_init);
    rwx_rewrite_expr_chain(s.assign_indices);
    rwx_rewrite_expr_chain(s.case_exprs);
    !!! Implicit conversions last: the operands are calls by now, so the type of what is
    !!! converted is known (`a[0]` is the index result, not the struct).
    rg_wrap_stmt_conversions(s);
    !!! A call statement: BAPI methods (`system.out(v)`) and user functions with an `any`
    !!! parameter take the conversion of a struct argument.
    if s.nk == CALL_FUNC {
        if s.is_method_call && s.args != null {
            rg_wrap_arguments(s.var_name, s.args, 1, true, s.args, s.line, s.col, 1, false);
        } else {
            rg_wrap_arguments(s.var_name, s.args, 0, false, null, s.line, s.col, 1, false);
        }
    }
}

!!! Every expression of one chain rewritten in place, the slot of each link written
!!! back through the link that reaches it.
void rwx_rewrite_expr_chain -> @ExprNode head {
    @ExprNode prev = null;
    @ExprNode a = head;
    while a != null {
        @ExprNode nx = a.next;
        rg_rewrite_operator_expr_out_n = a;
        rg_rewrite_operator_expr();
        @ExprNode rep = rg_rewrite_operator_expr_out_n;
        rep.next = nx;
        if prev != null {
            prev.next = rep;
        }
        prev = rep;
        a = nx;
    }
}

void rg_rewrite_operators -> @StmtNode stmts {
    rg_op_body_types = null;
    rg_op_body_var_types = null;
    rg_op_body_ptr = null;
    rg_op_body_array = null;
    !!! Entry scope: its declarations are known exactly, so the rewrite runs with them.
    rg_collect_operator_body_types(stmts);
    rg_rewrite_operator_stmt_body(stmts);
    rg_op_body_types = null;
    rg_op_body_var_types = null;
    rg_op_body_ptr = null;
    rg_op_body_array = null;
    !!! Struct method bodies are stored in the struct definition, not in the statement
    !!! tree, so they are rewritten here as well.
    @StructDef sd = p_struct_defs;
    while sd != null {
        @StructMethod m = sd.methods;
        while m != null {
            if m.fn != null && !m.fn.broken {
                rg_begin_operator_body_types(m.fn);
                rg_op_in_method_body = true;
                rg_op_method_type = sd.name;
                !!! The body belongs to `sd`, so a name that is a field of it (`data[i]`,
                !!! `size proto`, a bare field name) resolves through `this` here as well.
                str saved_method_type = rg_struct_method_type;
                str saved_method_var = rg_struct_method_var;
                rg_struct_method_type = sd.name;
                rg_struct_method_var = "__this";
                rg_check_param_dtor_access(m.fn);
                rg_rewrite_operator_stmt_body(m.fn.true_body);
                rg_struct_method_type = saved_method_type;
                rg_struct_method_var = saved_method_var;
                rg_op_in_method_body = false;
                rg_op_method_type = "";
                rg_op_body_types = null;
                rg_op_body_var_types = null;
                rg_op_body_ptr = null;
                rg_op_body_array = null;
            }
            m = m.next;
        }
        if sd.init_func != null && !sd.init_func.broken {
            rg_begin_operator_body_types(sd.init_func);
            !!! The body belongs to `sd`, and the pass walks it outside the method
            !!! context, so the type is named where the access check reads it.
            str saved_access_ctx = rg_access_ctx;
            rg_access_ctx = sd.name;
            rg_rewrite_operator_stmt_body(sd.init_func.true_body);
            rg_access_ctx = saved_access_ctx;
            rg_op_body_types = null;
            rg_op_body_var_types = null;
            rg_op_body_ptr = null;
            rg_op_body_array = null;
        }
        if sd.destruct_func != null && !sd.destruct_func.broken {
            rg_begin_operator_body_types(sd.destruct_func);
            str saved_access_ctx2 = rg_access_ctx;
            rg_access_ctx = sd.name;
            rg_rewrite_operator_stmt_body(sd.destruct_func.true_body);
            rg_access_ctx = saved_access_ctx2;
            rg_op_body_types = null;
            rg_op_body_var_types = null;
            rg_op_body_ptr = null;
            rg_op_body_array = null;
        }
        sd = sd.next;
    }
}

!!! Parameter and local types of one function body.
void rg_begin_operator_body_types -> @StmtNode fn {
    rg_op_body_types = null;
    rg_op_body_var_types = null;
    rg_op_body_ptr = null;
    rg_op_body_array = null;
    if fn == null {
        end;
    }
    !!! An error found while rewriting this body belongs to the function it is in, so
    !!! rg_fmt_err prints the same `In function ...` header every other diagnostic
    !!! carries.
    rg_cur_func_name = rg_display_name(fn.var_name);
    rg_cur_func_ret = fn.func_ret_type;
    rg_cur_func_ret_struct = fn.ret_struct;
    rg_func_line = fn.line;
    @StrNode p = fn.fparams;
    int i = 0;
    while p != null {
        str st = "";
        @StrNode ps = rgr_str_at(fn.fparam_struct, i);
        if ps != null {
            st = ps.s;
        }
        rg_op_body_types = rg_strmap_set(rg_op_body_types, p.s, st);
        !!! The declared scalar type of a non-struct parameter, so a value it receives
        !!! can be matched against a converting constructor.
        if st == "" && i < rgr_vt_n(fn.fparam_types) {
            rg_op_body_var_types = rg_vartypemap_set(rg_op_body_var_types, p.s,
                                                     rgr_vt_at(fn.fparam_types, i));
        }
        p = p.next;
        i = i + 1;
    }
    rg_collect_operator_body_types(fn.true_body);
}

void rg_rewrite_operator_stmt_body -> @StmtNode body {
    @StmtNode s = body;
    while s != null {
        if s.nk == FUNCTION {
            !!! A nested function has its own scope: its parameters and locals replace
            !!! whatever the enclosing body declared, and the enclosing ones come back
            !!! when it is done.
            rg_check_param_dtor_access(s);
            @RgStrMap saved = rg_op_body_types;
            @RgVarTypeMap saved_vars = rg_op_body_var_types;
            @RgBoolMap saved_ptr = rg_op_body_ptr;
            @RgBoolMap saved_arr = rg_op_body_array;
            rg_begin_operator_body_types(s);
            rg_rewrite_operator_stmt_body(s.true_body);
            rg_op_body_types = saved;
            rg_op_body_var_types = saved_vars;
            rg_op_body_ptr = saved_ptr;
            rg_op_body_array = saved_arr;
        } else {
            rg_rewrite_operator_stmt(s);
            !!! `true_body` is the `true_body` and the `children` at once.
            rg_rewrite_operator_stmt_body(s.true_body);
            rg_rewrite_operator_stmt_body(s.false_body);
            rg_rewrite_operator_stmt_body(s.case_bodies);
            rg_rewrite_operator_stmt_body(s.unmatch_body);
        }
        s = s.next;
    }
}
