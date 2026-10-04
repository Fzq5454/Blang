#once
!~
 ~  bootstrap/frontend/rgen_field.b: the frontend/rgen_field.
 ~
 ~  The four lookups along a struct's inheritance chain: a field of a name, the
 ~  method function of a name, and the BLANG_API (struct BAPI) method of a name.
 ~  Each searches the type itself - when the caller asks for that - and then every
 ~  base, depth first in the order the bases were written, so the nearest
 ~  declaration wins.
 ~
 ~  `resolve_field_decl` is the `bool` form of the field lookup, and the two
 ~  answer through the out-parameter globals rgen.b declares:
 ~  rg_resolve_field_out_decl_type carries the type that declared the field (the toolchain
 ~  `str* decl_type`), and `decl` copies it into
 ~  rg_resolve_field_decl_out_decl_type, which is the same answer under the name its
 ~  own method gives it. A lookup that finds nothing leaves that global as it was,
 ~  exactly as the toolchain pointer stays untouched.
 ~
 ~  A method is found by its source name or by the internal name of its `reload`
 ~  version (`m.name` or the function statement's var_name), so both spellings find
 ~  their own version.
 ~!

#head "rgen"

!!! The field of `name` in `stype` (and, when `include_self` is set, in the type
!!! itself before its bases). True when there is one; the type that declared it is
!!! left in rg_resolve_field_decl_out_decl_type.
bool rg_resolve_field_decl -> str stype, str name, bool include_self {
    @StructField f = rg_resolve_field(stype, name, include_self);
    if f == null {
        return false;
    }
    rg_resolve_field_decl_out_decl_type = rg_resolve_field_out_decl_type;
    return true;
}

!!! The field itself, or null. The declaring type lands in
!!! rg_resolve_field_out_decl_type (rg_resolve_field_decl copies it into its own).
@StructField rg_resolve_field -> str stype, str name, bool include_self {
    @StructDef sit = p_find_struct(stype);
    if sit == null {
        return null;
    }
    if include_self {
        @StructField f = sit.fields;
        while f != null {
            if p_text_eq(f.name, name) {
                rg_resolve_field_out_decl_type = stype;
                return f;
            }
            f = f.next;
        }
    }
    @StrNode b = sit.bases;
    while b != null {
        @StructField r = rg_resolve_field(b.s, name, true);
        if r != null {
            return r;
        }
        b = b.next;
    }
    return null;
}

!!! The FUNCTION statement of the method `name` of `stype`, or null.
@StmtNode rg_resolve_method_func -> str stype, str name, bool include_self {
    @StructDef sit = p_find_struct(stype);
    if sit == null {
        return null;
    }
    if include_self {
        @StructMethod m = sit.methods;
        while m != null {
            if m.fn != null {
                !!! A `reload` version is registered under its own internal name, so
                !!! both spellings find their version.
                if p_text_eq(m.name, name) || p_text_eq(m.fn.var_name, name) {
                    !!! The method is reached by the compiler here, which is what being
                    !!! called means for it: every call of a method, the operator
                    !!! rewrites that turn into one, and the implicit forms all pass
                    !!! through this lookup. Both spellings are marked, so a `reload`
                    !!! version is one method however the source named it.
                    rg_mark_method_used(stype, m.name);
                    rg_mark_method_used(stype, m.fn.var_name);
                    rg_mark_method_used(stype, name);
                    rg_mark_struct_used(stype);
                    return m.fn;
                }
            }
            m = m.next;
        }
    }
    @StrNode b = sit.bases;
    while b != null {
        @StmtNode r = rg_resolve_method_func(b.s, name, true);
        if r != null {
            return r;
        }
        b = b.next;
    }
    return null;
}

!!! The BLANG_API statement of the struct method `name` of `stype`, or null.
@StmtNode rg_resolve_bapi_method -> str stype, str name, bool include_self {
    @StructDef sit = p_find_struct(stype);
    if sit == null {
        return null;
    }
    if include_self {
        @StructBapiMethod bm = sit.bapi_methods;
        while bm != null {
            if p_text_eq(bm.name, name) && bm.bapi != null {
                !!! A BAPI method is written in, not in blang, so it is never
                !!! reported; the type it belongs to is still named.
                rg_mark_struct_used(stype);
                return bm.bapi;
            }
            bm = bm.next;
        }
    }
    @StrNode b2 = sit.bases;
    while b2 != null {
        @StmtNode r2 = rg_resolve_bapi_method(b2.s, name, true);
        if r2 != null {
            return r2;
        }
        b2 = b2.next;
    }
    return null;
}

!!! The type `derived` is `base` or derives from it. The depth limit is what keeps a
!!! cycle (reported by the inheritance checks) from walking forever here.
bool rg_is_base_of_type -> str base, str derived {
    if base == "" || derived == "" {
        return false;
    }
    if p_text_eq(base, derived) {
        return true;
    }
    return rg_is_base_of_type_at(base, derived, 0);
}

!!! The same walk, one base down, for the recursion the toolchain overload carries: the
!!! parameter the toolchain spells `depth` names the level here.
bool rg_is_base_of_type_at -> str base, str derived, int depth {
    if depth > 64 {
        return false;
    }
    @StructDef it = p_find_struct(derived);
    if it == null {
        return false;
    }
    @StrNode b = it.bases;
    while b != null {
        if p_text_eq(b.s, base) {
            return true;
        }
        if rg_is_base_of_type_at(base, b.s, depth + 1) {
            return true;
        }
        b = b.next;
    }
    return false;
}

!!! The access checks of one member chain: every field of `chain` is looked up in the
!!! type the one before it names, and each that is guarded is reported. A chain that
!!! stops being resolvable - or reaches a field reached through a pointer - ends the
!!! walk, exactly as the toolchain loop returns.
void rg_check_member_chain_access -> str base_type, @StrNode chain, int line, int col {
    !!! The name carries the `__chain` prefix: every declaration of a source is
    !!! registered in the flat symbol tables by its plain name, and a local called
    !!! `cur` here answered for the lexer's `char cur` in the tables the rest of the
    !!! file reads - and the call `cur()` in the lexer was typed with this local's
    !!! `str` in turn (-W-ntype-cmp reports the two).
    str __chain_cur = base_type;
    @StrNode c = chain;
    while c != null {
        if __chain_cur == "" {
            end;
        }
        @StructField f = rg_resolve_field(__chain_cur, c.s, true);
        if f == null {
            end;
        }
        str dt = rg_resolve_field_out_decl_type;
        rg_check_member_access(dt, c.s, f.access, line, col);
        if f.struct_ptr {
            end;
        }
        __chain_cur = f.struct_type;
        c = c.next;
    }
}

!!! Whether a member may be reached where it is written. Public reaches everyone;
!!! the default of a member written outside every `public { ... }` section and of
!!! every type that declares no section at all. The body being generated decides who
!!! is asking: rg_struct_method_type is the type it belongs to, and an empty one is a
!!! free function, a global initializer or a compiler pass that walks no body, all of
!!! which stand outside the type. A pass that knows the type but does not keep it in
!!! rg_struct_method_type (the `init` / `destruct` bodies of the rewrite pass) names
!!! it in rg_access_ctx instead.
void rg_check_member_access -> str decl_type, str name, int access, int line, int col {
    if access == 0 || decl_type == "" || name == "" {
        end;
    }
    str ctx = rg_access_ctx;
    if ctx == "" {
        ctx = rg_struct_method_type;
    }
    if ctx != "" {
        !!! The type's own methods reach everything it declares.
        if p_text_eq(ctx, decl_type) {
            end;
        }
        !!! A protected member is also reachable from a derived type's methods.
        if access == 1 && rg_is_base_of_type(decl_type, ctx) {
            end;
        }
    }
    str key = decl_type + char_text(1) + name + char_text(1) + (str)line + ":" + (str)col;
    if rg_set_has(rg_access_reported, key) {
        end;
    }
    rg_access_reported = rg_set_add(rg_access_reported, key);
    str what = "private";
    if access != 2 {
        what = "protected";
    }
    !!! The name a lookup uses is the internal one; the report shows what the source
    !!! wrote, so an operator reads as `operator []` and not as `op_index`.
    str shown = rg_member_show_name(decl_type, name);
    rg_fmt_err(line, col, "member '" + shown + "' is " + what + " in type '" + decl_type + "'",
               pe_len(name), (str)null, 0, true);
    rg_has_errors = true;
}

!!! The name a guarded member is shown under in that report: an operator by the
!!! symbol the source wrote (`operator []`), a converting constructor as `init`,
!!! every other member by the name that was looked up. The name a lookup uses is
!!! the internal one (`op_index`), which is not what the source says.
str rg_member_show_name -> str decl_type, str name {
    @StructDef sit = p_find_struct(decl_type);
    if sit == null {
        return name;
    }
    @StructMethod m = sit.methods;
    while m != null {
        if m.fn != null && (p_text_eq(m.name, name) || p_text_eq(m.fn.var_name, name)) {
            !!! A converting constructor is the `init` the source wrote.
            if p_text_eq(m.op, "init") {
                return "init";
            }
            !!! Any other operator is shown by its symbol.
            if m.op != "" {
                return "operator " + m.op;
            }
            skip;
        }
        m = m.next;
    }
    return name;
}

!!! A struct parameter is a copy of its own, destroyed when the function that takes
!!! it returns: a `destruct` the type keeps to itself cannot be run for it there.
!!! Each parameter name carries its own position in this implementation, so the report points
!!! at the name where the toolchain points at fparam_lines/fparam_cols.
void rg_check_param_dtor_access -> @StmtNode f {
    if f == null {
        end;
    }
    @StrNode nm = f.fparams;
    @StrNode ps = f.fparam_struct;
    while nm != null && ps != null {
        if ps.s != "" {
            @StructDef sd = p_find_struct(ps.s);
            if sd != null {
                int ln = ps.line;
                if ln == 0 {
                    ln = f.line;
                }
                int cl = ps.col;
                if cl == 0 {
                    cl = f.col;
                }
                rg_check_member_access(ps.s, "destruct", sd.destruct_access, ln, cl);
            }
        }
        nm = nm.next;
        ps = ps.next;
    }
}
