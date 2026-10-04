#once
!~
 ~  bootstrap/frontend/rgen_package.b: the frontend/rgen_package.
 ~
 ~  `package name { ... }` groups declarations under a name. A member is emitted
 ~  under `<pkg>__<name>`, so the .r backend sees a plain identifier, and outside
 ~  code reaches it either as `pkg::name` or, once `use pkg;` / `use pkg::name;` has
 ~  imported it, by its short name.
 ~
 ~  Two things this implementation does differently, both from the contract:
 ~   * the toolchain takes the package's own name map by reference (`local`), which is the
 ~     global rg_collect_package_member_out_lmap here, and the in-out name of
 ~     package_resolve is rg_package_resolve_out_name;
 ~   * the members of a package are the statement's `true_body` (the toolchain keeps them
 ~     in `children`, which this implementation does not have), and expand_packages answers the
 ~     possibly-new top-level chain instead of assigning to the vector it was given.
 ~!

#head "rgen"

!!! One name rewritten through a package's own map: the `sub` lambda of
!!! rewrite_pkg_refs_expr / rewrite_pkg_refs_stmt, which takes the name by
!!! reference. A text cannot be passed by reference here, so the answer is the
!!! return value.
str rgx_pkg_sub -> @RgStrMap lmap, str name {
    @RgStrMap e = rg_strmap_find(lmap, name);
    if e != null {
        return e.v;
    }
    return name;
}

!!! `_pkg_short[orig].push_back(key)`: every qualified name a short name may mean,
!!! in the order the packages were read.
void rgx_pkg_short_add -> str orig, str key {
    @RgStrListMap sl = rg_strlistmap_find(rg_pkg_short, orig);
    if sl == null {
        rg_pkg_short = rg_strlistmap_set(rg_pkg_short, orig, rg_strchain_append(null, key), 1);
        end;
    }
    int before = sl.n;
    sl.names = rg_strchain_append(sl.names, key);
    sl.n = before + 1;
}

void rg_rewrite_pkg_refs_expr -> @ExprNode n, @RgStrMap lmap {
    if n == null {
        end;
    }
    if n.nk == VAR_REF || n.nk == FUNC_CALL {
        n.var_name = rgx_pkg_sub(lmap, n.var_name);
    }
    if n.struct_type != "" {
        n.struct_type = rgx_pkg_sub(lmap, n.struct_type);
    }
    @StrNode ts = n.targ_structs;
    while ts != null {
        ts.s = rgx_pkg_sub(lmap, ts.s);
        ts = ts.next;
    }
    rg_rewrite_pkg_refs_expr(n.left, lmap);
    rg_rewrite_pkg_refs_expr(n.right, lmap);
    @ExprNode a = n.args;
    while a != null {
        rg_rewrite_pkg_refs_expr(a, lmap);
        a = a.next;
    }
    @ExprNode ix = n.indices;
    while ix != null {
        rg_rewrite_pkg_refs_expr(ix, lmap);
        ix = ix.next;
    }
    @ExprNode tx = n.targ_exprs;
    while tx != null {
        rg_rewrite_pkg_refs_expr(tx, lmap);
        tx = tx.next;
    }
    !!! The immediate arguments and the body of a lambda literal: the toolchain keeps them
    !!! on the expression node, this implementation in the literal's own record (p_find_lambda).
    if n.nk == LAMBDA {
        @LambdaRec rec = p_find_lambda(n.lambda_id);
        if rec != null {
            @ExprNode ia = rec.immediate_args;
            while ia != null {
                rg_rewrite_pkg_refs_expr(ia, lmap);
                ia = ia.next;
            }
            @StmtNode lb = rec.body;
            while lb != null {
                rg_rewrite_pkg_refs_stmt(lb, lmap);
                lb = lb.next;
            }
        }
    }
}

void rg_rewrite_pkg_refs_stmt -> @StmtNode s, @RgStrMap lmap {
    if s == null {
        end;
    }
    if s.nk == CALL_FUNC || s.nk == DECLARE || s.nk == ASSIGN || s.nk == DREF_ASSIGN {
        s.var_name = rgx_pkg_sub(lmap, s.var_name);
    }
    if s.struct_type != "" {
        s.struct_type = rgx_pkg_sub(lmap, s.struct_type);
    }
    if s.ret_struct != "" {
        s.ret_struct = rgx_pkg_sub(lmap, s.ret_struct);
    }
    @StrNode fs = s.fparam_struct;
    while fs != null {
        fs.s = rgx_pkg_sub(lmap, fs.s);
        fs = fs.next;
    }
    @StrNode ts = s.targ_structs;
    while ts != null {
        ts.s = rgx_pkg_sub(lmap, ts.s);
        ts = ts.next;
    }
    rg_rewrite_pkg_refs_expr(s.expr, lmap);
    rg_rewrite_pkg_refs_expr(s.array_len_expr, lmap);
    @ExprNode a = s.args;
    while a != null {
        rg_rewrite_pkg_refs_expr(a, lmap);
        a = a.next;
    }
    @ExprNode i = s.array_init;
    while i != null {
        rg_rewrite_pkg_refs_expr(i, lmap);
        i = i.next;
    }
    @ExprNode c = s.case_exprs;
    while c != null {
        rg_rewrite_pkg_refs_expr(c, lmap);
        c = c.next;
    }
    @ExprNode ai = s.assign_indices;
    while ai != null {
        rg_rewrite_pkg_refs_expr(ai, lmap);
        ai = ai.next;
    }
    @ExprNode d = s.fparam_defaults;
    while d != null {
        rg_rewrite_pkg_refs_expr(d, lmap);
        d = d.next;
    }
    !!! `true_body` is the `true_body` and the `children` at once: a
    !!! package's members and a function's body both live there in this implementation.
    @StmtNode b = s.true_body;
    while b != null {
        rg_rewrite_pkg_refs_stmt(b, lmap);
        b = b.next;
    }
    @StmtNode fb = s.false_body;
    while fb != null {
        rg_rewrite_pkg_refs_stmt(fb, lmap);
        fb = fb.next;
    }
    @StmtNode cb = s.case_bodies;
    while cb != null {
        rg_rewrite_pkg_refs_stmt(cb, lmap);
        cb = cb.next;
    }
    @StmtNode u = s.unmatch_body;
    while u != null {
        rg_rewrite_pkg_refs_stmt(u, lmap);
        u = u.next;
    }
}

!!! One member of a package: a variable, a function or a type. Its internal name is
!!! `<pkg>__<name>`, its own name map gets the short name, and the package's table
!!! gets the qualified one.
void rg_collect_package_member -> str pkg, @StmtNode m {
    str orig = "";
    int mkind = -1;
    if m.nk == FUNCTION && !m.broken {
        orig = m.var_name;
        mkind = 1;
    } else if m.nk == DECLARE {
        orig = m.var_name;
        mkind = 0;
    } else if m.nk == STRUCT_DEF {
        orig = m.var_name;
        mkind = 2;
    }
    if mkind < 0 || orig == "" {
        end;
    }
    PkgMember proto;
    @PkgMember pm;
    malloc(@pm, size proto);
    pm.pkg = pkg;
    pm.name = orig;
    pm.internal = pkg + "__" + orig;
    pm.member_kind = mkind;
    pm.line = m.var_line;
    if pm.line == 0 {
        pm.line = m.line;
    }
    pm.col = m.var_col;
    if pm.col == 0 {
        pm.col = m.col;
    }
    pm.len = pe_len(orig);
    rg_collect_package_member_out_lmap =
        rg_strmap_set(rg_collect_package_member_out_lmap, orig, pm.internal);
    str key = pkg + "::" + orig;
    rg_pkg_members = rg_pkgmap_set(rg_pkg_members, key, pm);
    rgx_pkg_short_add(orig, key);
}

void rg_rename_package_member -> str pkg, @StmtNode m, @RgStrMap lmap {
    str orig = "";
    if m.nk == FUNCTION || m.nk == DECLARE || m.nk == STRUCT_DEF {
        orig = m.var_name;
    } else {
        end;
    }
    @RgStrMap e = rg_strmap_find(lmap, orig);
    if e == null {
        end;
    }
    str internal = e.v;
    if m.nk == STRUCT_DEF {
        !!! The parser registered the struct under its short name; move it to the
        !!! package-qualified internal name as well. the toolchain erases the map entry and
        !!! inserts a copy under the new key; this implementation's table is a chain searched by
        !!! the name field, so renaming that field is the whole move.
        @StructDef d = p_find_struct(orig);
        if d != null {
            d.name = internal;
        }
    }
    !!! Every member kind, so diagnostics keep naming it the way it was written
    !!! (`mypkg::f`, `mypkg::a`, `mypkg::T`) instead of the internal name.
    rg_display_names = rg_strmap_set(rg_display_names, internal, pkg + "::" + orig);
    m.var_name = internal;
    !!! References between members of the same package use the short names.
    rg_rewrite_pkg_refs_stmt(m, lmap);
}

!!! Move every package's members into the top-level statement list under their
!!! internal names, and record the `use` imports. An import statement itself
!!! produces no code, and the package statement is emptied once its members are
!!! ordinary top-level declarations.
@StmtNode rg_expand_packages -> @StmtNode stmts {
    bool found_any = false;
    @StmtNode s = stmts;
    while s != null {
        if s.nk == USE || s.nk == PACKAGE {
            found_any = true;
            skip;
        }
        s = s.next;
    }
    if !found_any {
        return stmts;
    }
    @StmtNode out = null;
    @StmtNode out_tail = null;
    s = stmts;
    while s != null {
        !!! The chain is rebuilt, so the link of the statement being moved is put
        !!! aside first: a node that still has `next` set would carry the rest of
        !!! the old list into the new one.
        @StmtNode nx = s.next;
        s.next = null;
        if s.nk == USE {
            if s.struct_type == "" {
                rg_used_pkgs = rg_set_add(rg_used_pkgs, s.var_name);
            } else {
                rg_used_members = rg_set_add(rg_used_members, s.var_name + "::" + s.struct_type);
            }
            s = nx;
            continue;
        }
        if s.nk != PACKAGE {
            if out == null {
                out = s;
            } else {
                out_tail.next = s;
            }
            out_tail = s;
            s = nx;
            continue;
        }
        str pkg = s.var_name;
        !!! The name map is the package's own: one is built per package.
        rg_collect_package_member_out_lmap = null;
        @StmtNode m = s.true_body;
        while m != null {
            rg_collect_package_member(pkg, m);
            m = m.next;
        }
        m = s.true_body;
        while m != null {
            @StmtNode mn = m.next;
            m.next = null;
            rg_rename_package_member(pkg, m, rg_collect_package_member_out_lmap);
            if out == null {
                out = m;
            } else {
                out_tail.next = m;
            }
            out_tail = m;
            m = mn;
        }
        !!! The members became ordinary top-level statements; the package statement
        !!! holds nothing any more.
        s.true_body = null;
        s = nx;
    }
    return out;
}

void rg_report_pkg_member -> @PkgMember m, str name, int line, int col, int len {
    str key = (str)line + ":" + (str)col + ":" + name;
    rg_has_errors = true;
    if rg_set_has(rg_pkg_reported, key) {
        end;
    }
    rg_pkg_reported = rg_set_add(rg_pkg_reported, key);
    str msg = "'" + name + "' is not imported";
    int hl = len;
    if hl <= 0 {
        hl = pe_len(name);
    }
    rg_fmt_err(line, col, msg, hl, (str)null, 0, true);
    str kw = "variable";
    if m.member_kind == 1 {
        kw = "function";
    } else if m.member_kind == 2 {
        kw = "struct";
    }
    str nmsg = kw + " '" + m.name + "' is defined in package '" + m.pkg + "'";
    int nhl = m.len;
    if nhl <= 0 {
        nhl = pe_len(m.name);
    }
    rg_fmt_note(m.line, m.col, nmsg, nhl);
}

!!! 0 when the name has nothing to do with packages, 1 when it was replaced by the
!!! internal name (left in rg_package_resolve_out_name), 2 when the member exists
!!! but its package was not imported (already reported).
int rg_package_resolve -> int line, int col, int len {
    if rg_pkg_members == null {
        return 0;
    }
    str name = rg_package_resolve_out_name;
    !!! The qualified form `pkg::name`: naming the package is enough, no import is
    !!! needed.
    @RgPkgMap it = rg_pkgmap_find(rg_pkg_members, name);
    if it != null {
        rg_package_resolve_out_name = it.m.internal;
        return 1;
    }
    !!! The short form `name`: only usable once the package was imported.
    @RgStrListMap sit = rg_strlistmap_find(rg_pkg_short, name);
    if sit == null {
        return 0;
    }
    @StrNode e = sit.names;
    while e != null {
        @RgPkgMap mit = rg_pkgmap_find(rg_pkg_members, e.s);
        if mit != null {
            @PkgMember pm = mit.m;
            if rg_set_has(rg_used_pkgs, pm.pkg) || rg_set_has(rg_used_members, e.s) {
                rg_package_resolve_out_name = pm.internal;
                return 1;
            }
        }
        e = e.next;
    }
    !!! Nothing imported the name: the first member that answers to it is what the
    !!! diagnostic names.
    if sit.names != null {
        @RgPkgMap f = rg_pkgmap_find(rg_pkg_members, sit.names.s);
        if f != null {
            rg_report_pkg_member(f.m, name, line, col, len);
        }
    }
    return 2;
}
