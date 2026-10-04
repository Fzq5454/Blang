#once
!~
 ~  bootstrap/frontend/rgen_struct_copy.b: this implementation of
 ~  - whole-struct copies (`o.in = p`,
 ~  `Inner q = p;`), emitted leaf by leaf.
 ~
 ~  A struct-typed field is not a storage leaf of the flattened layout, so it cannot
 ~  be written with one FLD store: the offsets only exist for the leaves, and the
 ~  store would write the source's address instead of its fields. The copy is
 ~  therefore one store per leaf field:
 ~
 ~    CAST (FLDP <target address> <leaf offset> TYPE), (FLDP <source address> <leaf offset> TYPE)
 ~
 ~  Both sides go through FLDP, so a nested target field and a source that is a
 ~  variable, another field chain or a struct-returning call are all handled the same
 ~  way. A `a chain of str` path is a chain of StrNode here, and the three
 ~  pointers the toolchain writes through (the lvalue address, the receiver address, the
 ~  source address) are the globals rgen.b declares for them.
 ~!

#head "rgen"

str rgx_strchain_last -> @StrNode head {
    str s = "";
    @StrNode e = head;
    while e != null {
        s = e.s;
        e = e.next;
    }
    return s;
}

!!! The `.r` expression that yields the address of a struct value being copied. A
!!! variable or field chain already has an address; a call returns the address of
!!! its heap block, so it is evaluated once into a hidden pointer first. False when
!!! the expression cannot be a struct value.
bool rg_emit_struct_source_address -> @ExprNode src {
    rg_emit_struct_source_address_out = "";
    if src == null {
        return false;
    }
    if src.nk == VAR_REF {
        !!! A plain variable has an address; a bare field name inside a method body
        !!! (`return who;`) is addressed through `this`, and a `@T` variable already
        !!! holds the address of the object.
        if rg_name_is_pointer(src.var_name) {
            rg_emit_struct_source_address_out = src.var_name;
            return true;
        }
        if rg_method_field_shadows(src.var_name) ||
           (rg_vartypemap_find(rg_syms, src.var_name) == null &&
            rg_strmap_find(rg_sym_struct_type, src.var_name) == null &&
            !rg_set_has(rg_method_locals, src.var_name)) {
            rg_emit_lvalue_address_out = "";
            if rg_emit_lvalue_address(src) {
                rg_emit_struct_source_address_out = rg_emit_lvalue_address_out;
                return true;
            }
        }
        rg_emit_struct_source_address_out = "(AT " + src.var_name + ")";
        return true;
    }
    if src.nk == UNARY && p_text_eq(src.op, "$") && src.left != null {
        !!! `$p` on a `@T`: the value is the object the pointer names, so its address
        !!! is what the pointer holds. `return $e;` in a T-returning function and
        !!! `T v = $e;` both copy the object from there.
        if rg_name_is_pointer(src.left.var_name) || rg_var_is_struct_ptr(src.left.var_name) ||
           rg_method_field_is_struct_ptr(src.left.var_name) {
            rg_emit_struct_source_address_out = rg_pointer_base_text(src.left.var_name);
            return true;
        }
        return false;
    }
    if src.nk == MEMBER_ACCESS || src.nk == FIELD_ELEM || src.nk == ARRAY_ACCESS {
        rg_emit_lvalue_address_out = "";
        if rg_emit_lvalue_address(src) {
            rg_emit_struct_source_address_out = rg_emit_lvalue_address_out;
            return true;
        }
        rg_emit_receiver_address_out = "";
        if rg_emit_receiver_address(src) {
            rg_emit_struct_source_address_out = rg_emit_receiver_address_out;
            return true;
        }
        return false;
    }
    if src.nk == FUNC_CALL {
        rg_tmp_var_counter = rg_tmp_var_counter + 1;
        str tmp = "__sc" + (str)rg_tmp_var_counter;
        rg_rcode = rg_rcode + "DECLARED " + rg_rtype(AT_VOID) + " " + tmp + " , ";
        rg_rc_expr(src);
        rg_rcode = rg_rcode + "\n";
        rg_emit_struct_source_address_out = tmp;
        return true;
    }
    return false;
}

!!! Copy the struct a call returns into a caller-owned temporary and answer the name
!!! of that temporary. The value lives in the callee's frame, which the next call
!!! from the same point reuses, so the copy has to happen before anything else is
!!! called: this is only reached at the start of a statement.
str rg_materialize_struct_value -> @ExprNode call, str stype {
    rg_tmp_var_counter = rg_tmp_var_counter + 1;
    str tmp = "__ov" + (str)rg_tmp_var_counter;
    rg_rcode = rg_rcode + "DECLARED STRUCT " + stype + " " + tmp + " , {}\n";
    rg_rcode = rg_rcode + "CAST " + tmp + " , ";
    rg_rc_expr(call);
    rg_rcode = rg_rcode + "\n";
    rg_syms = rg_vartypemap_set(rg_syms, tmp, INT);
    rg_sym_struct_type = rg_strmap_set(rg_sym_struct_type, tmp, stype);
    rg_sym_depth = rg_intmap_set(rg_sym_depth, tmp, 0);
    return tmp;
}

!!! Copy the leaves of the struct `target_type` from the object at `src_addr` into
!!! the object at `dst_addr`.
void rg_emit_struct_leaf_copy -> str dst_addr, str target_type, str src_addr {
    rg_collect_leaf_fields_out = null;
    rg_collect_leaf_fields_out_visited = null;
    rg_collect_leaf_fields(target_type, 0);
    @FlatField lf = rg_collect_leaf_fields_out;
    while lf != null {
        str tp = rg_rtype(rg_field_eff_type(lf.field));
        !!! `+ ""` copies the number's text out of the conversion ring: a converted
        !!! number is a pointer into a shared buffer, so a later conversion (the
        !!! field offsets this very line converts next) refills the slot and the
        !!! name would read that text instead.
        str o = (str)lf.abs_off + "";
        rg_rcode = rg_rcode + "CAST (FLDP " + dst_addr + " " + o + " " + tp + ") , (FLDP " +
                   src_addr + " " + o + " " + tp + ")\n";
        lf = lf.next;
    }
}

!!! `o.in = p` and `who = x` (inside a method body): the target is a field that is
!!! itself a struct value. False when the assignment is something else, so the
!!! caller keeps its ordinary path.
bool rg_emit_struct_field_copy -> @StmtNode s {
    if s == null || s.is_array || s.expr == null {
        return false;
    }
    !!! The path from the base object to the field. The base is either the assigned
    !!! variable or the enclosing method's struct (`this`).
    @StrNode path = null;
    str base_type = "";
    bool base_is_this = false;
    !!! The declaration in effect where the name is written decides. Only a name this
    !!! body declares, a parameter or a global is a variable here; a name that merely
    !!! appears as a local of another body is not, and the flat table would answer
    !!! with that first declaration for the whole file.
    bool is_var_here = rg_vardeclmap_find(rg_local_decls, s.var_name) != null ||
                       rg_is_func_param(s.var_name) ||
                       rg_set_has(rg_global_names, s.var_name);
    if is_var_here {
        if rg_effective_var_decl(s.var_name) {
            base_type = rg_effective_var_decl_out.struct_type;
        }
    } else if p_find_struct(s.var_name) != null {
        base_type = s.var_name;
    }
    if base_type != "" {
        if s.member_name == "" {
            return false;
        }
        if s.member_chain == null {
            path = rg_strchain_append(null, s.member_name);
        } else {
            !!! The chain is read only from here on, so the statement's own list is
            !!! the path (the toolchain copies the vector).
            path = s.member_chain;
        }
    } else {
        !!! A bare field name (or a field of a field) of the method's struct.
        if rg_struct_method_var == "" || is_var_here {
            return false;
        }
        base_type = rg_struct_method_type;
        base_is_this = true;
        path = rg_strchain_append(path, s.var_name);
        @StrNode mc = s.member_chain;
        while mc != null {
            path = rg_strchain_append(path, mc.s);
            mc = mc.next;
        }
    }
    if path == null || path.s == "" {
        return false;
    }
    rg_resolve_field_chain_out_leaf = null;
    rg_resolve_field_chain_out_abs_off = 0;
    if !rg_resolve_field_chain(base_type, path, s.line, s.col) {
        return false;
    }
    @StructField leaf = rg_resolve_field_chain_out_leaf;
    int off = rg_resolve_field_chain_out_abs_off;
    if leaf == null || leaf.struct_type == "" || leaf.struct_ptr {
        return false;
    }
    str target_type = leaf.struct_type;
    str field_name = rgx_strchain_last(path);
    !!! The source has to be a struct value of the very same type.
    str src_type = rg_expr_struct_type(s.expr);
    if !p_text_eq(src_type, target_type) {
        str msg = "";
        if src_type == "" {
            msg = "cannot assign a '" + rg_type_name(s.expr.result_type) + "' value to field '" +
                  field_name + "' of type '" + target_type + "'";
        } else {
            msg = "cannot assign a '" + src_type + "' value to field '" + field_name +
                  "' of type '" + target_type + "'";
        }
        int el = s.member_line;
        if el == 0 {
            el = s.line;
        }
        int ec = s.member_col;
        if ec == 0 {
            ec = s.col;
        }
        rg_fmt_err(el, ec, msg, pe_len(field_name), (str)null, 0, true);
        rg_has_errors = true;
        !!! Handled: there is no scalar store for a struct field.
        return true;
    }
    str dst = "";
    if base_is_this {
        if off != 0 {
            dst = "((@void " + rg_struct_method_var + ") , " + (str)off + " , +)";
        } else {
            dst = rg_struct_method_var;
        }
    } else {
        rg_emit_field_chain_address_out = "";
        if !rg_emit_field_chain_address(s.var_name, base_type, path) {
            return false;
        }
        dst = rg_emit_field_chain_address_out;
    }
    rg_emit_struct_source_address_out = "";
    if !rg_emit_struct_source_address(s.expr) {
        return false;
    }
    rg_emit_struct_leaf_copy(dst, target_type, rg_emit_struct_source_address_out);
    return true;
}

!!! `Inner q = p;` / `Inner q = makeInner(3);`: a struct object initialized from a
!!! struct value of the same type. The declaration itself writes the default field
!!! values, so the copy is appended after it.
bool rg_emit_struct_decl_copy -> @StmtNode s {
    if s == null || s.nk != DECLARE || s.struct_type == "" {
        return false;
    }
    if s.is_array || s.expr == null || s.array_init != null {
        return false;
    }
    str src_type = rg_expr_struct_type(s.expr);
    if src_type == "" {
        !!! The initializer is not a struct value at all: a scalar cannot initialize a
        !!! struct object. A dereference is left to the ordinary path.
        if s.expr.nk != UNARY && s.expr.nk != ADDR {
            str msg = "cannot initialize '" + s.struct_type + "' with a value of type '" +
                      rg_type_name(s.expr.result_type) + "'";
            int el = s.var_line;
            if el == 0 {
                el = s.line;
            }
            int ec = s.var_col;
            if ec == 0 {
                ec = s.col;
            }
            rg_fmt_err(el, ec, msg, pe_len(s.var_name), (str)null, 0, true);
            rg_has_errors = true;
            !!! Reported: no copy is emitted.
            return true;
        }
        !!! Not a struct value: the ordinary initialization path.
        return false;
    }
    if !p_text_eq(src_type, s.struct_type) {
        str msg = "cannot initialize '" + s.struct_type + "' with a value of type '" + src_type + "'";
        int el = s.var_line;
        if el == 0 {
            el = s.line;
        }
        int ec = s.var_col;
        if ec == 0 {
            ec = s.col;
        }
        rg_fmt_err(el, ec, msg, pe_len(s.var_name), (str)null, 0, true);
        rg_has_errors = true;
        return true;
    }
    rg_emit_struct_source_address_out = "";
    if !rg_emit_struct_source_address(s.expr) {
        return false;
    }
    rg_emit_struct_leaf_copy("(AT " + s.var_name + ")", s.struct_type,
                             rg_emit_struct_source_address_out);
    return true;
}
