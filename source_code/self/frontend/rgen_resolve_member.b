#once
!~
 ~  bootstrap/frontend/rgen_resolve_member.b: this implementation of
 ~
 ~  How `a.b` is typed: `super.b` resolves in the base types only, a chain
 ~  (`p.addr.city`, `a[i].pos.x`, `o.people[i].name`) resolves as a whole through
 ~  the member-chain helpers, a field of a struct a call returned through
 ~  expr_struct_type, and a plain variable or array element through the declaration
 ~  in effect where the name is written - never through the flat table, which keeps
 ~  the first use of a name in the whole file.
 ~!

#head "rgen"

!!! resolve_member(): the type of one member access.
bool rg_resolve_member -> @ExprNode n {
    n.result_type = INT;
    if n.is_super {
        !!! super.field: resolve in the parent types only.
        @StructField f = rg_resolve_field(rg_struct_method_type, n.member_name, false);
        if f != null {
            rg_check_member_access(rg_resolve_field_out_decl_type, n.member_name, f.access,
                                   n.line, n.col);
            if f.ty == CHAR && f.array_dim > 0 {
                n.result_type = STR;
            } else {
                n.result_type = f.ty;
            }
            n.is_unsigned = f.is_unsigned;
        } else {
            str msg = "super has no member '" + n.member_name + "'";
            rg_fmt_err(n.line, n.col, msg, pe_len(n.member_name), (str)null, 0, false);
            return false;
        }
        return true;
    }
    !!! Resolve the left side (the struct value), then look the field up along the
    !!! inheritance chain.
    if !rg_resolve_expr_type(n.left) {
        return false;
    }
    if n.left.nk == MEMBER_ACCESS {
        !!! Chained member access: p.addr.city.
        @ExprNode root = n.left;
        while root != null && root.nk == MEMBER_ACCESS && root.left != null {
            root = root.left;
        }
        !!! The chain may also hang off a call that returns a struct by value
        !!! (`a[i].pos.x` once `[]` became `op_index(...)`).
        bool call_root = root != null && root.nk == FUNC_CALL;
        if root != null && (root.nk == VAR_REF || root.nk == ARRAY_ACCESS || call_root) {
            str stype = "";
            if call_root {
                stype = rg_expr_struct_type(root);
            } else {
                !!! The declaration in effect here, not the flat table: a local named
                !!! like a local of an earlier body must answer with its own struct
                !!! type.
                stype = rg_struct_type_in_effect(root.var_name);
            }
            if stype != "" {
                rg_resolve_member_chain_out_leaf = null;
                rg_resolve_member_chain_out_abs_off = 0;
                bool ok = rg_resolve_member_chain(n, stype);
                @StructField leaf = rg_resolve_member_chain_out_leaf;
                if ok && leaf != null {
                    if leaf.ty == CHAR && leaf.array_dim > 0 {
                        n.result_type = STR;
                    } else {
                        n.result_type = leaf.ty;
                    }
                    n.is_unsigned = leaf.is_unsigned;
                    if !leaf.struct_ptr && leaf.struct_type != "" {
                        n.struct_type = leaf.struct_type;
                    }
                } else {
                    str msg = "struct '" + stype + "' has no member '" + n.member_name + "'";
                    rg_fmt_err(n.line, n.col, msg, pe_len(n.member_name), (str)null, 0, false);
                    return false;
                }
            }
        }
        return true;
    }
    if n.left.nk == FUNC_CALL {
        !!! A field of a struct a call returned by value (`a[i].tag`, `mk().tag`).
        str bt = rg_expr_struct_type(n.left);
        if bt != "" {
            @StructField f2 = rg_resolve_field(bt, n.member_name, true);
            if f2 == null {
                str msg2 = "struct '" + bt + "' has no member '" + n.member_name + "'";
                rg_fmt_err(n.line, n.col, msg2, pe_len(n.member_name), (str)null, 0, false);
                return false;
            }
            rg_check_member_access(rg_resolve_field_out_decl_type, n.member_name, f2.access,
                                   n.line, n.col);
            n.result_type = rg_field_eff_type(f2);
            n.is_unsigned = f2.is_unsigned;
            if !f2.struct_ptr && f2.struct_type != "" {
                n.struct_type = f2.struct_type;
            }
        }
        return true;
    }
    if n.left.nk == FIELD_ELEM {
        !!! A field of an array element (`o.people[i].name`).
        str et = n.left.struct_type;
        if et == "" {
            str msg3 = "element is not a struct";
            rg_fmt_err(n.line, n.col, msg3, pe_len(n.member_name), (str)null, 0, false);
            return false;
        }
        @StructField f3 = rg_resolve_field(et, n.member_name, true);
        if f3 == null {
            str msg4 = "struct '" + et + "' has no member '" + n.member_name + "'";
            rg_fmt_err(n.line, n.col, msg4, pe_len(n.member_name), (str)null, 0, false);
            return false;
        }
        rg_check_member_access(rg_resolve_field_out_decl_type, n.member_name, f3.access,
                               n.line, n.col);
        n.result_type = rg_field_eff_type(f3);
        n.is_unsigned = f3.is_unsigned;
        n.struct_type = f3.struct_type;
        return true;
    }
    if n.left.nk == VAR_REF || n.left.nk == ARRAY_ACCESS {
        !!! The declaration in effect here, as above: the flat table keeps the first
        !!! use of a name in the whole file.
        str stype2 = rg_struct_type_in_effect(n.left.var_name);
        if stype2 != "" {
            @StructField f4 = rg_resolve_field(stype2, n.member_name, true);
            if f4 != null {
                rg_check_member_access(rg_resolve_field_out_decl_type, n.member_name, f4.access,
                                       n.line, n.col);
                if f4.ty == CHAR && f4.array_dim > 0 {
                    n.result_type = STR;
                } else {
                    n.result_type = f4.ty;
                }
                !!! `utype int f` / `utype longlong f`: every read of the field is an
                !!! unsigned value of that width.
                n.is_unsigned = f4.is_unsigned;
                !!! A struct *value* field is passed by address, so callers have to
                !!! know that this expression denotes a struct
                !!! (`showInner(o.in)`).
                if !f4.struct_ptr && f4.struct_type != "" {
                    n.struct_type = f4.struct_type;
                }
            } else {
                str msg5 = "struct '" + stype2 + "' has no member '" + n.member_name + "'";
                rg_fmt_err(n.line, n.col, msg5, pe_len(n.member_name), (str)null, 0, false);
                return false;
            }
        }
    }
    return true;
}
