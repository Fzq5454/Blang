#once
!~
 ~  bootstrap/frontend/rgen_typecheck.b: the frontend/rgen_typecheck.
 ~
 ~  The second pass: every statement of the program is resolved and checked with the
 ~  declarations that stand before it in its own body. The walk is rg_walk_stmts
 ~  with action 2 (rgen_walk.b), and the per-statement body is
 ~  rg_typecheck_pass_stmt() below - the lambda rgen_typecheck passes to
 ~  walk_stmts. The lambda captures nothing that has to live between statements, so
 ~  no part of it became a module global.
 ~
 ~  The pass keeps a per-body declaration table (`_track_locals` -> rg_track_locals,
 ~  `_local_decls` -> rg_local_decls), so a local of another body cannot answer for a
 ~  name used here; the walk saves and restores that table around every function
 ~  body. Everything else the toolchain carries in a local - the `struct_bapi_checked`
 ~  flag, the expected type, the struct types - is a local here too.
 ~
 ~  the toolchain compares nodes by address in one place (the call-argument loop skips
 ~  `s->args[0]`), which the language rejects for two struct pointers; this implementation walks
 ~  the argument chain with a `first` flag, which says the same thing.
 ~  `rg_resolve_field*`, `rg_index_field_layout` and `rg_plan_index_store` answer
 ~  through the `_out` globals of rgen.b, so the leaf and plan globals are cleared
 ~  before the call that fills them - the toolchain passes a fresh local each time.
 ~!

#head "rgen"
#head "rgen_heads"

!!! A fresh VarDecl: the `VarDecl d;` value-initializes every member, and a
!!! block from malloc is junk, so all of them are written out. The fields the
!!! callers below set are the ones the toolchain sets; `struct_ptr` and `n` are the
!!! carried answers a `a chain` would give on its own.
@VarDecl rgx_new_vardecl {
    VarDecl proto;
    @VarDecl d;
    malloc(@d, size proto);
    d.ty = INT;
    d.ptr_depth = 0;
    d.struct_type = "";
    d.struct_ptr = false;
    d.is_array = false;
    d.is_ref = false;
    d.is_unsigned = false;
    d.dims = null;
    d.n = 0;
    d.len_expr = null;
    return d;
}

!!! The number of entries of a chain of dimensions: `s->array_dims.size()`.
int rgx_chain_int_len -> @IntNode head {
    int n = 0;
    @IntNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

!!! The last entry of a chain of index levels: `chain_plan.levels.back()`.
@IndexChainLevel rgx_last_level -> @IndexChainLevel head {
    @IndexChainLevel e = head;
    if e == null {
        return null;
    }
    while e.next != null {
        e = e.next;
    }
    return e;
}

!!! typecheck_pass: the whole program, with the per-body declaration table in use.
void rg_typecheck_pass {
    !!! This walk is the one that keeps a per-body declaration table, so a local of
    !!! another body cannot answer for a name used here (see effective_var_decl).
    rg_track_locals = true;
    rg_walk_stmts(rg_stmts, 2);
    rg_track_locals = false;
}

!!! One statement of the pass: the body of the lambda typecheck_pass() passes to
!!! walk_stmts. `struct_bapi_checked` says the arguments of this call were already
!!! resolved by the struct method check below, so they are not resolved twice.
void rg_typecheck_pass_stmt -> @StmtNode s {
    bool struct_bapi_checked = false;
    !!! The position of the call itself, used by the struct method diagnostics.
    int eline = s.var_line;
    if eline == 0 {
        eline = s.line;
    }
    int ecol = s.var_col;
    if ecol == 0 {
        ecol = s.col;
    }
    !!! ---- BAPI function type check (must run first) ----
    if s.nk == CALL_FUNC {
        rg__check_call_types(s);
    }
    !!! Catch undefined struct type in type.method() calls. Only when the call target
    !!! is NOT a known regular function/BAPI/builtin - otherwise the first arg is an
    !!! ordinary (possibly undefined) argument.
    if s.nk == CALL_FUNC && s.args != null && s.args.nk == VAR_REF &&
       rg_intmap_find(rg_func_arity, s.var_name) == null &&
       !rg_is_builtin_func(s.var_name) &&
       !rg_set_has(rg_extern_funcs, s.var_name) &&
       p_find_bapi(s.var_name) == null &&
       !rg_is_callable_var(s.var_name) {
        str tname = s.args.var_name;
        !!! A variable, a type name, or a bare field of the enclosing method's struct
        !!! (`total.method()`), which the file-wide tables cannot see.
        str stype = rg_receiver_struct_type(s.args);
        if stype == "" && rg_vartypemap_find(rg_syms, tname) == null &&
           !rg_method_field_shadows(tname) {
            str msg = "undeclared struct type '" + tname + "'";
            rg_fmt_err(s.args.line, s.args.col, msg, pe_len(tname), (str)null, 0, true);
            rg_has_errors = true;
        }
        !!! Check struct BAPI method existence & arg types (inheritance-aware).
        if stype != "" {
            @StmtNode bapi = rg_resolve_bapi_method(stype, s.var_name, true);
            if bapi != null {
                struct_bapi_checked = true;
                int nargs = rgx_na_len_expr(s.args) - 1;
                if bapi.variadic {
                    if nargs + 1 < bapi.nfparams {
                        str msg = "function '" + s.var_name + "' needs at least " +
                                  (str)(bapi.nfparams - 1) + " argument(s), got " +
                                  (str)nargs;
                        rg_fmt_err(eline, ecol, msg, pe_len(s.var_name), (str)null, 0, true);
                        rg_has_errors = true;
                    }
                } else if nargs != bapi.nfparams {
                    str msg = "function '" + s.var_name + "' needs " +
                              (str)bapi.nfparams + " argument(s), got " + (str)nargs;
                    rg_fmt_err(eline, ecol, msg, pe_len(s.var_name), (str)null, 0, true);
                    rg_has_errors = true;
                }
                !!! The arguments from the second one on (the first is the receiver).
                @ExprNode a = s.args.next;
                @VarTypeNode t = bapi.fparam_types;
                int ai = 1;
                while a != null && t != null {
                    @ExprNode cnode = a;
                    VarType missing = t.ty;
                    a = a.next;
                    t = t.next;
                    int aindex = ai;
                    ai = ai + 1;
                    if cnode == null || !rg_resolve_expr_type(cnode) {
                        rg_has_errors = true;
                        continue;
                    }
                    if missing != ANY && cnode.result_type != missing {
                        str msg = "argument " + (str)aindex + " missing '" +
                                  rg_type_name(missing) + "', got '" +
                                  rg_type_name(cnode.result_type) + "'";
                        int hl = cnode.tok_len;
                        if hl <= 0 {
                            hl = pe_len(rg_type_name(cnode.result_type));
                        }
                        rg_fmt_err(cnode.line, cnode.col, msg, hl, (str)null, 0, true);
                        rg_fmt_note(bapi.var_line, bapi.var_col, "declared here",
                                    pe_len(bapi.var_name));
                        rg_has_errors = true;
                    }
                }
            } else {
                @StmtNode mf = rg_resolve_method_func(stype, s.var_name, true);
                if mf != null {
                    !!! Regular method: check arity + argument types.
                    int nargs = rgx_na_len_expr(s.args) - 1;
                    if nargs != mf.nfparams {
                        str msg = "function '" + s.var_name + "' needs " +
                                  (str)mf.nfparams + " argument(s), got " + (str)nargs;
                        rg_fmt_err(eline, ecol, msg, pe_len(s.var_name), (str)null, 0, true);
                        rg_has_errors = true;
                    }
                    @ExprNode a2 = s.args.next;
                    @VarTypeNode t2 = mf.fparam_types;
                    int ai2 = 1;
                    while a2 != null && t2 != null {
                        @ExprNode cur2 = a2;
                        VarType missing2 = t2.ty;
                        a2 = a2.next;
                        t2 = t2.next;
                        int aindex2 = ai2;
                        ai2 = ai2 + 1;
                        if cur2 == null || !rg_resolve_expr_type(cur2) {
                            rg_has_errors = true;
                            continue;
                        }
                        if missing2 != ANY && cur2.result_type != missing2 {
                            str msg = "argument " + (str)aindex2 + " missing '" +
                                      rg_type_name(missing2) + "', got '" +
                                      rg_type_name(cur2.result_type) + "'";
                            int hl2 = cur2.tok_len;
                            if hl2 <= 0 {
                                hl2 = pe_len(rg_type_name(cur2.result_type));
                            }
                            rg_fmt_err(cur2.line, cur2.col, msg, hl2, (str)null, 0, true);
                            rg_has_errors = true;
                        }
                    }
                } else {
                    str msg = "type '" + tname + "' has no method '" + s.var_name + "'";
                    rg_fmt_err(eline, ecol, msg, pe_len(s.var_name), (str)null, 0, true);
                    rg_has_errors = true;
                }
            }
        }
    }
    !!! Method call on a nested object: `obj.field.method(...)`. The receiver is a
    !!! field chain instead of a variable, so the struct type comes from the chain;
    !!! the rest of the check (existence, arity, argument types) is the same as for
    !!! `obj.method(...)`.
    if s.nk == CALL_FUNC && s.is_method_call && s.args != null &&
       (s.args.nk == MEMBER_ACCESS || s.args.nk == FIELD_ELEM ||
        s.args.nk == ARRAY_ACCESS || s.args.nk == FUNC_CALL) &&
       rg_intmap_find(rg_func_arity, s.var_name) == null &&
       !rg_is_builtin_func(s.var_name) &&
       !rg_set_has(rg_extern_funcs, s.var_name) &&
       p_find_bapi(s.var_name) == null {
        rg_receiver_info_out_stype = "";
        rg_receiver_info_out_decl_type = "";
        bool rok = rg_receiver_info(s.args, true);
        str stype2 = rg_receiver_info_out_stype;
        if rok && stype2 != "" {
            @StmtNode mf2 = rg_resolve_method_func(stype2, s.var_name, true);
            if mf2 != null {
                int nargs2 = rgx_na_len_expr(s.args) - 1;
                if nargs2 != mf2.nfparams {
                    str msg = "function '" + s.var_name + "' needs " +
                              (str)mf2.nfparams + " argument(s), got " + (str)nargs2;
                    rg_fmt_err(eline, ecol, msg, pe_len(s.var_name), (str)null, 0, true);
                    rg_has_errors = true;
                }
                @ExprNode a3 = s.args.next;
                @VarTypeNode t3 = mf2.fparam_types;
                int ai3 = 1;
                while a3 != null && t3 != null {
                    @ExprNode cur3 = a3;
                    VarType missing3 = t3.ty;
                    a3 = a3.next;
                    t3 = t3.next;
                    int aindex3 = ai3;
                    ai3 = ai3 + 1;
                    if cur3 == null || !rg_resolve_expr_type(cur3) {
                        rg_has_errors = true;
                        continue;
                    }
                    if missing3 != ANY && cur3.result_type != missing3 {
                        str msg = "argument " + (str)aindex3 + " missing '" +
                                  rg_type_name(missing3) + "', got '" +
                                  rg_type_name(cur3.result_type) + "'";
                        int hl3 = cur3.tok_len;
                        if hl3 <= 0 {
                            hl3 = pe_len(rg_type_name(cur3.result_type));
                        }
                        rg_fmt_err(cur3.line, cur3.col, msg, hl3, (str)null, 0, true);
                        rg_has_errors = true;
                    }
                }
            } else {
                str msg = "type '" + stype2 + "' has no method '" + s.var_name + "'";
                rg_fmt_err(eline, ecol, msg, pe_len(s.var_name), (str)null, 0, true);
                rg_has_errors = true;
            }
        }
    }
    !!! A whole-object assignment or initialization: the value has to be that struct.
    !!! A different struct, or a value that is definitely not a struct, would copy
    !!! the wrong bits into the object.
    if (s.nk == DECLARE || s.nk == ASSIGN) && s.expr != null &&
       s.member_name == "" && !s.is_array && s.array_init == null {
        !!! The struct type in effect: the statement's own declaration for a DECLARE,
        !!! the declaration in effect here for an ASSIGN, and only then the flat
        !!! table, which keeps the first use of a name in the whole file and would
        !!! otherwise answer for another body.
        str tst = s.struct_type;
        !!! A DECLARE that carries no struct type says the name is *not* a struct
        !!! here, and that answer is final: falling through to the flat table let
        !!! `str t = ...` be read as the `Token t` of an earlier body's local and
        !!! reported as a struct assignment.
        if tst == "" && s.nk != DECLARE {
            @RgVarDeclMap lit_o = rg_vardeclmap_find(rg_local_decls, s.var_name);
            if lit_o != null {
                tst = lit_o.decl.struct_type;
            } else {
                @RgStrMap st_o = rg_strmap_find(rg_sym_struct_type, s.var_name);
                if st_o != null {
                    tst = st_o.v;
                }
            }
        }
        if tst == "" && p_find_struct(s.var_name) != null {
            tst = s.var_name;
        }
        if tst != "" {
            str st = rg_expr_struct_type(s.expr);
            !!! The struct names are compared as text: `==`/`!=` on two `str` values
            !!! compares the blocks they point at, and a name read out of a table is
            !!! a block of its own.
            if !pe_eq(st, tst) && (st != "" || rg_expr_definitely_not_struct(s.expr)) {
                str shown = st;
                if shown == "" {
                    shown = rg_type_name(s.expr.result_type);
                }
                str msg = "cannot assign a '" + shown + "' value to '" + tst + "'";
                rg_fmt_err(s.line, s.col, msg, pe_len(s.var_name), (str)null, 0, true);
                rg_has_errors = true;
            }
        }
    }
    !!! Set function context when entering a function body.
    if s.nk == FUNCTION && !s.broken {
        !!! Report the source name: an instantiated template is stored as `add_int`
        !!! and a package member as `mypkg__f`, but the user only ever wrote
        !!! `add` / `mypkg::f`.
        rg_cur_func_name = rg_display_name(s.var_name);
        rg_cur_func_ret = s.func_ret_type;
        rg_cur_func_ret_struct = s.ret_struct;
        rg_func_line = s.line;
        rg_func_header = "";
    }
    if s.nk == DECLARE || s.nk == ASSIGN {
        VarType expected_type = s.decl_type;
        !!! `ref T r = expr` binds r to expr by reference: check the initializer
        !!! against the pointee type T, not the pointer @T.
        if s.nk == DECLARE && s.decl_is_ref {
            expected_type = rg_deref_of(expected_type);
        }
        if s.nk == ASSIGN {
            if s.is_super {
                rg_resolve_field_out_decl_type = "";
                @StructField f = rg_resolve_field(rg_struct_method_type, s.member_name, false);
                if f != null {
                    expected_type = f.ty;
                } else {
                    str msg = "super has no member '" + s.member_name + "'";
                    int ml = s.member_line;
                    if ml == 0 {
                        ml = s.line;
                    }
                    int mc = s.member_col;
                    if mc == 0 {
                        mc = s.col;
                    }
                    rg_fmt_err(ml, mc, msg, pe_len(s.member_name), (str)null, 0, true);
                    rg_has_errors = true;
                }
            } else if s.member_name != "" {
                !!! Struct member assignment: look up the field type
                !!! (inheritance-aware). The declaration in effect here comes first,
                !!! so a struct local of this body is not decided by a scalar of the
                !!! same name in an earlier body, nor the other way round.
                str stype3 = "";
                @RgVarDeclMap lit_m = rg_vardeclmap_find(rg_local_decls, s.var_name);
                if lit_m != null {
                    stype3 = lit_m.decl.struct_type;
                } else {
                    @RgStrMap sm3 = rg_strmap_find(rg_sym_struct_type, s.var_name);
                    if sm3 != null {
                        stype3 = sm3.v;
                    }
                }
                if stype3 == "" && p_find_struct(s.var_name) != null {
                    stype3 = s.var_name;
                }
                !!! `a[i].field = v` through a value-returning `[]`: the fields after
                !!! the index are read from the element, not from `a`. A store through
                !!! a chain of subscripts writes the fields of the element the last
                !!! subscript selects.
                bool handled = false;
                if s.is_index_chain_store {
                    rg_plan_index_store_out_plan = null;
                    if rg_plan_index_store(s) {
                        @IndexStorePlan plan = rg_plan_index_store_out_plan;
                        if plan != null && plan.levels != null && plan.fields != null {
                            @IndexChainLevel lv = rgx_last_level(plan.levels);
                            str t4 = "";
                            if lv != null {
                                t4 = lv.ret;
                            }
                            @StructField leaf = null;
                            @StrNode fn = plan.fields;
                            while fn != null {
                                if t4 == "" {
                                    skip;
                                }
                                rg_resolve_field_out_decl_type = "";
                                leaf = rg_resolve_field(t4, fn.s, true);
                                if leaf != null {
                                    !!! The position of the member written, which is
                                    !!! the one the statement carries when it has one.
                                    int al = s.member_line;
                                    if al == 0 {
                                        al = s.line;
                                    }
                                    int ac = s.member_col;
                                    if ac == 0 {
                                        ac = s.col;
                                    }
                                    rg_check_member_access(rg_resolve_field_out_decl_type, fn.s,
                                                           leaf.access, al, ac);
                                    t4 = leaf.struct_type;
                                }
                                fn = fn.next;
                            }
                            if leaf != null {
                                expected_type = rg_field_eff_type(leaf);
                            }
                            handled = true;
                        }
                    }
                }
                if !handled && stype3 != "" {
                    rg_index_field_layout_out_leaf = null;
                    if rg_index_field_layout(s) && rg_index_field_layout_out_leaf != null {
                        expected_type = rg_field_eff_type(rg_index_field_layout_out_leaf);
                        handled = true;
                    }
                }
                if !handled && stype3 != "" {
                    int chain_n = 0;
                    @StrNode mc2 = s.member_chain;
                    while mc2 != null {
                        chain_n = chain_n + 1;
                        mc2 = mc2.next;
                    }
                    if chain_n > 1 {
                        !!! Chained: resolve p.addr.city to the leaf field type.
                        !!! `s->member_line ? s->member_line : s->line` (and the column),
                        !!! the position the check below reports at.
                        int al4 = s.member_line;
                        if al4 == 0 {
                            al4 = s.line;
                        }
                        int ac4 = s.member_col;
                        if ac4 == 0 {
                            ac4 = s.col;
                        }
                        rg_resolve_field_chain_out_leaf = null;
                        rg_resolve_field_chain_out_abs_off = 0;
                        bool cok = rg_resolve_field_chain(stype3, s.member_chain, al4, ac4);
                        @StructField leaf2 = rg_resolve_field_chain_out_leaf;
                        if cok && leaf2 != null {
                            int al2 = s.member_line;
                            if al2 == 0 {
                                al2 = s.line;
                            }
                            int ac2 = s.member_col;
                            if ac2 == 0 {
                                ac2 = s.col;
                            }
                            rg_check_member_chain_access(stype3, s.member_chain, al2, ac2);
                            expected_type = rg_field_eff_type(leaf2);
                        } else {
                            str msg = "struct '" + stype3 + "' has no member chain '" +
                                      s.member_name + "'";
                            int ml2 = s.member_line;
                            if ml2 == 0 {
                                ml2 = s.line;
                            }
                            int mc3 = s.member_col;
                            if mc3 == 0 {
                                mc3 = s.col;
                            }
                            rg_fmt_err(ml2, mc3, msg, pe_len(s.member_name), (str)null, 0, true);
                            rg_has_errors = true;
                        }
                    } else {
                        rg_resolve_field_out_decl_type = "";
                        @StructField f2 = rg_resolve_field(stype3, s.member_name, true);
                        if f2 != null {
                            int al3 = s.member_line;
                            if al3 == 0 {
                                al3 = s.line;
                            }
                            int ac3 = s.member_col;
                            if ac3 == 0 {
                                ac3 = s.col;
                            }
                            rg_check_member_access(rg_resolve_field_out_decl_type, s.member_name,
                                                   f2.access, al3, ac3);
                            !!! `field_eff_type` so a `char[N]` field (stored as a
                            !!! str) expects a string value.
                            expected_type = rg_field_eff_type(f2);
                        } else {
                            str msg = "struct '" + stype3 + "' has no member '" +
                                      s.member_name + "'";
                            int ml3 = s.member_line;
                            if ml3 == 0 {
                                ml3 = s.line;
                            }
                            int mc4 = s.member_col;
                            if mc4 == 0 {
                                mc4 = s.col;
                            }
                            rg_fmt_err(ml3, mc4, msg, pe_len(s.member_name), (str)null, 0, true);
                            rg_has_errors = true;
                        }
                    }
                }
            } else {
                !!! The declaration in effect at this point. The body being checked
                !!! keeps its own in rg_local_decls, so a name declared `int t` here
                !!! is not answered by the `float t` of an earlier function, which is
                !!! all the flat table could offer: it keeps the first declaration of
                !!! a name in the whole file.
                @RgVarDeclMap lit = rg_vardeclmap_find(rg_local_decls, s.var_name);
                if lit != null {
                    expected_type = lit.decl.ty;
                    if lit.decl.is_ref {
                        expected_type = rg_deref_of(expected_type);
                    }
                } else {
                    @RgVarTypeMap sm4 = rg_vartypemap_find(rg_syms, s.var_name);
                    !!! `syms[name]` inserts a default entry when the name
                    !!! is not there, and the default of the type is INT.
                    if sm4 != null {
                        expected_type = sm4.ty;
                    } else {
                        expected_type = INT;
                    }
                    !!! Reference variable: the RHS is checked against the referenced
                    !!! (pointee) type, not the pointer type.
                    if rg_is_ref_var(s.var_name) {
                        expected_type = rg_deref_of(expected_type);
                    }
                }
            }
        }
        !!! For array subscript assign: p[0] = val - index must be INT, value must
        !!! match the dereferenced type (e.g. @int -> int).
        if s.is_array {
            if s.expr != null && !rg_check_int_index(s.expr, "index") {
                rg_has_errors = true;
            }
            !!! A store through `@T operator []` or through a chain of subscripts
            !!! writes the element itself: the value is not compared against a scalar
            !!! element type.
            if s.is_index_ptr_store || s.is_index_chain_store {
                @ExprNode e = s.array_init;
                while e != null {
                    if e != null {
                        rg_resolve_expr_type(e);
                    }
                    e = e.next;
                }
            } else {
                VarType elem_type = expected_type;
                !!! An inline array *field* stores its own element type; only a
                !!! pointer array variable (`@int a`) has its element dereferenced.
                @StructField af = rg_stmt_array_field(s);
                if af != null {
                    elem_type = rg_field_eff_type(af);
                } else {
                    elem_type = rg_deref_of(elem_type);
                }
                @ExprNode e2 = s.array_init;
                while e2 != null {
                    if e2 != null && !rg_check_expr(s, e2, elem_type) {
                        rg_has_errors = true;
                    }
                    e2 = e2.next;
                }
            }
        } else {
            !!! An unsigned target takes the constants it is for: `utype int u =
            !!! 4294967295;` is a value an int cannot hold, and `utype char c = 200;`
            !!! a byte the signed char reads as negative.
            bool target_unsigned = (s.nk == DECLARE) && s.decl_is_unsigned;
            if s.nk == ASSIGN {
                if rg_effective_var_decl(s.var_name) {
                    target_unsigned = rg_effective_var_decl_out.is_unsigned;
                }
                !!! A field carries its own flag: `o.n = 4294967295;` is the value the
                !!! unsigned field is for, so the field is looked up for it the way
                !!! the expected type above was.
                if !target_unsigned && s.member_name != "" {
                    str ftype = "";
                    if rg_effective_var_decl(s.var_name) {
                        ftype = rg_effective_var_decl_out.struct_type;
                    }
                    if ftype == "" && p_find_struct(s.var_name) != null {
                        ftype = s.var_name;
                    }
                    @StructField ff = null;
                    rg_resolve_field_out_decl_type = "";
                    if ftype != "" {
                        ff = rg_resolve_field(ftype, s.member_name, true);
                    } else if rg_struct_method_type != "" {
                        ff = rg_resolve_field(rg_struct_method_type, s.var_name, true);
                    }
                    if ff != null {
                        target_unsigned = ff.is_unsigned;
                    }
                }
            }
            if target_unsigned && s.expr != null && s.expr.nk == LIT_INT &&
               expected_type != LONG {
                rg_wrap_unsigned_constant_out_e = s.expr;
                rg_wrap_unsigned_constant(expected_type);
                s.expr = rg_wrap_unsigned_constant_out_e;
            }
            if s.expr != null && !rg_check_expr(s, s.expr, expected_type) {
                rg_has_errors = true;
            }
            !!! Validate array initializer elements.
            @ExprNode e3 = s.array_init;
            while e3 != null {
                if e3 != null && !rg_check_expr(s, e3, s.decl_type) {
                    rg_has_errors = true;
                }
                e3 = e3.next;
            }
        }
        !!! Array size must be an integer: `int a["x"]` is not allowed.
        if s.array_len_expr != null && !rg_check_int_index(s.array_len_expr, "size") {
            rg_has_errors = true;
        }
    }
    if s.nk == CALL_FUNC {
        !!! Skip struct method calls (already handled above).
        bool sm = false;
        if s.args != null && s.args.nk == VAR_REF {
            if p_find_struct(s.args.var_name) != null ||
               rg_is_struct_method(s.var_name, s.args.var_name) {
                sm = true;
            }
        }
        if !sm {
            !!! BAPI functions already handled by _check_call_types above. Always
            !!! resolve args to catch undeclared symbols (skip struct type names and
            !!! the receiver of the call).
            if !struct_bapi_checked && p_find_bapi(s.var_name) == null {
                @ExprNode a4 = s.args;
                bool first = true;
                while a4 != null {
                    bool skip_this = false;
                    !!! Skip args that are struct type references (e.g. "system" in
                    !!! system.out(...)).
                    if a4.nk == VAR_REF && p_find_struct(a4.var_name) != null {
                        skip_this = true;
                    }
                    !!! Skip args[0] of CALL_FUNC - struct type name, already checked
                    !!! above. the toolchain compares the node address (`a == s->args[0]`);
                    !!! this implementation knows the head by its place in the walk.
                    if first && a4.nk == VAR_REF {
                        skip_this = true;
                    }
                    if !skip_this {
                        if !rg_resolve_expr_type(a4) {
                            rg_has_errors = true;
                        }
                    }
                    first = false;
                    a4 = a4.next;
                }
            }
        }
    }
    if s.nk == IF_ELSE {
        if s.expr != null && !rg_resolve_expr_type(s.expr) {
            rg_has_errors = true;
        }
    }
    if s.nk == WHILE {
        if s.expr != null && !rg_resolve_expr_type(s.expr) {
            rg_has_errors = true;
        }
    }
    if s.nk == RETURN {
        if s.expr != null {
            if !rg_resolve_expr_type(s.expr) {
                rg_has_errors = true;
            } else if !rg_check_return_type(s) {
                rg_has_errors = true;
            }
        }
    }
    if s.nk == THROW {
        if s.expr != null && !rg_resolve_expr_type(s.expr) {
            rg_has_errors = true;
        }
        !!! A thrown value is an exception code: a whole number, not text or a float.
        if s.expr != null {
            VarType got = s.expr.result_type;
            if got != INT && got != CHAR && got != BOOL {
                str msg = "throw needs an exception code, got '" + rg_type_name(got) + "'";
                rg_fmt_err(s.expr.line, s.expr.col, msg, s.expr.tok_len, (str)null, 0, true);
                rg_has_errors = true;
            }
        }
    }
    if s.nk == SWITCH {
        if s.expr != null && !rg_resolve_expr_type(s.expr) {
            rg_has_errors = true;
        }
        @ExprNode ce = s.case_exprs;
        while ce != null {
            if ce != null && !rg_resolve_expr_type(ce) {
                rg_has_errors = true;
            }
            ce = ce.next;
        }
    }
    !!! Record what this statement declares, for the statements after it: walk_stmts
    !!! visits them in order, so this is exactly the set of names in effect at each
    !!! point, the way the backend resolves them. The initializer was resolved above,
    !!! before the name existed here, so `int x = x;` still sees the outer x.
    if s.nk == DECLARE && s.var_name != "" {
        @VarDecl d = rgx_new_vardecl();
        d.ty = s.decl_type;
        d.ptr_depth = s.ptr_depth;
        d.struct_type = s.struct_type;
        d.is_array = s.is_array;
        d.is_ref = s.decl_is_ref;
        d.is_unsigned = s.decl_is_unsigned;
        d.dims = rg_longchain_of(s.array_dims);
        d.n = rgx_chain_int_len(s.array_dims);
        d.len_expr = s.array_len_expr;
        if rg_in_func_body {
            rg_local_decls = rg_vardeclmap_set(rg_local_decls, s.var_name, d);
        }
    }
    if s.nk == TRY_CATCH && s.var_name != "" && rg_in_func_body {
        @VarDecl d2 = rgx_new_vardecl();
        d2.ty = INT;
        rg_local_decls = rg_vardeclmap_set(rg_local_decls, s.var_name, d2);
    }
}
