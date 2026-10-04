#once
!~
 ~  bootstrap/frontend/rgen_resolve_varref.b: this implementation of
 ~
 ~  How a bare name is typed: `::name` against the global scope, a package member
 ~  through the package tables, a function name used as a value, a field of the
 ~  enclosing struct method body, and finally the declaration in effect where the
 ~  name is written (a local of this body first, the flat tables otherwise).
 ~
 ~  resolve_global_ref() rewrites the name it is given (`::x` -> `__global_x`), so
 ~  in this implementation the name travels in the global rg_resolve_global_ref_out_name: the
 ~  caller stores it there before the call and reads it back after (this design
 ~  section 3).
 ~!

#head "rgen"

!!! resolve_var_ref(): the type of one bare name.
bool rg_resolve_var_ref -> @ExprNode n {
    !!! `::name` - the global scope explicitly.
    rg_resolve_global_ref_out_name = n.var_name;
    int gr = rg_resolve_global_ref(n.line, n.col, n.tok_len);
    n.var_name = rg_resolve_global_ref_out_name;
    if gr == 2 {
        n.result_type = INT;
        return false;
    }
    !!! A package member: `pkg::name`, or the short name once imported.
    rg_package_resolve_out_name = n.var_name;
    int pr = rg_package_resolve(n.line, n.col, n.tok_len);
    if pr == 1 {
        n.var_name = rg_package_resolve_out_name;
    } else if pr == 2 {
        n.result_type = INT;
        return false;
    }
    !!! Function name used as a value -> a func object (function-as-value).
    if rg_intmap_find(rg_func_arity, n.var_name) != null {
        n.result_type = FUNC;
        return true;
    }
    !!! A bare field name of the enclosing struct method body. It wins over a
    !!! variable of the same name declared elsewhere in the file.
    if rg_method_field_shadows(n.var_name) {
        @StructField f = rg_resolve_field(rg_struct_method_type, n.var_name, true);
        !!! the toolchain dereferences the field without a check here (the shadow test
        !!! above already guaranteed it); this implementation keeps the check so a null answer
        !!! cannot crash the walk.
        if f != null {
            if f.ty == CHAR && f.array_dim > 0 {
                n.result_type = STR;
            } else {
                n.result_type = f.ty;
            }
            n.is_unsigned = f.is_unsigned;
            if f.struct_type != "" && !f.struct_ptr {
                n.struct_type = f.struct_type;
            }
        }
        return true;
    }
    !!! The declaration in effect here: a local of this body first, the flat tables
    !!! otherwise (globals, parameters, package members). The flat table knows the
    !!! name may exist only as a local of another function, in which case it is not
    !!! in scope here.
    if !rg_effective_var_decl(n.var_name) {
        !!! Struct field referenced inside a struct method body (implicit
        !!! `this.field`), e.g. `name` in `Person.sleep`.
        if rg_struct_method_var != "" {
            @StructField f2 = rg_resolve_field(rg_struct_method_type, n.var_name, true);
            if f2 != null {
                if f2.ty == CHAR && f2.array_dim > 0 {
                    n.result_type = STR;
                } else {
                    n.result_type = f2.ty;
                }
                return true;
            }
        }
        str c = rg_closest_symbol(n.var_name);
        str msg = "undeclared identifier '" + n.var_name + "'";
        str sug = "";
        if c != "" {
            msg = msg + "; did you mean '" + c + "'?";
            sug = c;
        }
        !!! fmt_err(n->line, n->col, msg, (int)n->var_name.size(), c.empty() ?
        !!! nullptr : sug, c.empty() ? 0 : n->col, false).
        if c == "" {
            rg_fmt_err(n.line, n.col, msg, pe_len(n.var_name), (str)null, 0, false);
        } else {
            rg_fmt_err(n.line, n.col, msg, pe_len(n.var_name), sug, n.col, false);
        }
        return false;
    }
    @VarDecl d = rg_effective_var_decl_out;
    n.result_type = d.ty;
    if d.struct_type != "" {
        n.struct_type = d.struct_type;
    }
    n.ptr_depth = d.ptr_depth;
    !!! Array variable referenced without [] or @ -> yields a heap pointer (the
    !!! address type of the element).
    if d.is_array {
        if d.ty == INT {
            n.result_type = AT_INT;
        } else if d.ty == FLOAT {
            n.result_type = AT_FLOAT;
        } else if d.ty == CHAR {
            n.result_type = AT_CHAR;
        } else if d.ty == STR {
            n.result_type = AT_STR;
        } else if d.ty == BOOL {
            n.result_type = AT_BOOL;
        } else if d.ty == ANY {
            !!! `any` is a wildcard: its array pointer is a generic @void.
            n.result_type = AT_VOID;
        }
    }
    !!! Reference variable: reads auto-dereference, so the expression's type is the
    !!! pointee type (INT), not the pointer type (@int).
    if d.is_ref {
        n.result_type = rg_deref_of(d.ty);
    }
    !!! `utype T x`: every read of x is an unsigned value of that width.
    n.is_unsigned = d.is_unsigned;
    return true;
}

!!! resolve_global_ref(): `::name` reaches the global scope explicitly: the name
!!! has to exist there, whether or not a function parameter or local of the same
!!! name is in scope. Answers 0 when the name is not written that way, 1 when it
!!! resolved (the rewritten name is left in rg_resolve_global_ref_out_name) and 2
!!! when it was reported as not being a global.
int rg_resolve_global_ref -> int line, int col, int len {
    str name = rg_resolve_global_ref_out_name;
    if pe_len(name) < 3 || name[0] != ':' || name[1] != ':' {
        return 0;
    }
    str bare = pe_sub(name, 2, pe_len(name) - 2);
    !!! _global_names.count(bare) || func_arity.count(bare) ||
    !!! parser.get_struct_defs().count(bare) || parser.get_bapi_defs().count(bare).
    bool exists = rg_set_has(rg_global_names, bare) ||
                  (rg_intmap_find(rg_func_arity, bare) != null) ||
                  (p_find_struct(bare) != null) ||
                  (p_find_bapi(bare) != null);
    if !exists {
        str key = (str)line + ":" + (str)col + ":global:" + bare;
        if !rg_set_has(rg_arity_reported, key) {
            rg_arity_reported = rg_set_add(rg_arity_reported, key);
            str m = "'" + bare + "' is not declared in the global scope";
            int hl = len;
            if hl <= 0 {
                hl = pe_len(name);
            }
            rg_fmt_err(line, col, m, hl, (str)null, 0, false);
            rg_has_errors = true;
        }
        rg_resolve_global_ref_out_name = bare;
        return 2;
    }
    !!! A variable is reached through an alias that no local can shadow; functions
    !!! are global by nature and keep their own name.
    if rg_set_has(rg_global_names, bare) {
        rg_resolve_global_ref_out_name = "__global_" + bare;
    } else {
        rg_resolve_global_ref_out_name = bare;
    }
    return 1;
}
