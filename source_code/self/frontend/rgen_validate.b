#once
!~
 ~  bootstrap/frontend/rgen_validate.b: the frontend/rgen_validate.
 ~
 ~  The control-flow validation (`skip` only inside a loop, `return expr` only
 ~  outside a void function, `end` only inside one, and a non-void function that has
 ~  to contain at least one return) and the const-write check.
 ~
 ~  `const` means the value is written once, where it is declared (or bound, for a
 ~  parameter), and never written again. The second pass reports every later write:
 ~  an assignment (`x = v`, `x[i] = v`, `o.field = v` on the const object), `++`/`--`
 ~  and a `ref` binding, which would hand out a name the value can be written
 ~  through. Only the scopes that enclose the statement are consulted, innermost
 ~  first, so an inner scope that redeclares the name decides for itself.
 ~
 ~  Two things the toolchain keeps that this implementation has to say differently:
 ~   * `validate_stmts` is a function that calls itself; it is a recursive
 ~     function of its own here (rgx_validate_stmts), because the language has no
 ~     function values;
 ~   * a `const` entry is a record of rgen_heads.b, so one is made with
 ~     rgx_const_info before it is put in a scope;
 ~   * a parameter position is read from the StrNode of the parameter name (the
 ~     chain carries the position, the way the toolchain fparam_lines/cols/lens do), and
 ~     `s->children` is `s->true_body` here (parser_package.b), so the true_body
 ~     walk already covers the `children` walk of the toolchain.
 ~!

#head "rgen"
#head "rgen_heads"
#head "attributes"

!!! One ConstInfo: whether the name is read-only, and where it was declared, which
!!! is what the note under a write points at.
@ConstInfo rgx_const_info -> bool is_const, int line, int col, int len {
    ConstInfo proto;
    @ConstInfo ci;
    malloc(@ci, size proto);
    ci.is_const = is_const;
    ci.line = line;
    ci.col = col;
    ci.len = len;
    return ci;
}

!!! One frame of the const scope stack: an empty table of names.
@RgConstScope rgx_const_scope_new {
    RgConstScope proto;
    @RgConstScope sc;
    malloc(@sc, size proto);
    sc.entries = null;
    sc.next = null;
    return sc;
}

!!! validate_stmts: the recursive walk of validate_control_flow(). `depth` is how
!!! many loops enclose this body (0 at file level) and `func_ret` the return type of
!!! the function it belongs to, which a nested body inherits.
void rgx_validate_stmts -> @StmtNode body, int depth, VarType func_ret {
    @StmtNode s = body;
    while s != null {
        if s.nk == BREAK {
            if depth == 0 {
                rg_fmt_err(s.line, s.col, "'skip' outside of a loop", 4, (str)null, 0, true);
                rg_has_errors = true;
            }
        } else if s.nk == RETURN {
            if func_ret == VOID && s.expr != null {
                rg_fmt_err(s.line, s.col,
                           "return statement in void function is not allowed", 6, (str)null, 0, true);
                rg_has_errors = true;
            }
        } else if s.nk == END {
            if func_ret != VOID {
                rg_fmt_err(s.line, s.col, "'end' is only allowed in void functions", 3,
                           (str)null, 0, true);
                rg_has_errors = true;
            }
        } else if s.nk == WHILE {
            rgx_validate_stmts(s.true_body, depth + 1, func_ret);
        } else if s.nk == IF_ELSE {
            rgx_validate_stmts(s.true_body, depth, func_ret);
            rgx_validate_stmts(s.false_body, depth, func_ret);
        } else if s.nk == TRY_CATCH {
            !!! The handler runs outside the try body, but neither is a loop.
            rgx_validate_stmts(s.true_body, depth, func_ret);
            rgx_validate_stmts(s.false_body, depth, func_ret);
        } else if s.nk == FUNCTION {
            !!! A stub has no body, so it has nothing to validate.
            if !s.broken && !s.is_stub {
                !!! Add params to syms (restore outer values on exit).
                rg_push_func_params(s);
                !!! Set function context for accurate error headers.
                str saved_fn = rg_cur_func_name;
                VarType saved_rt = rg_cur_func_ret;
                !!! A package member or an instantiated template is stored under its
                !!! internal name; the message must show what the user wrote.
                str shown = rg_display_name(s.var_name);
                rg_cur_func_name = shown;
                rg_cur_func_ret = s.func_ret_type;
                bool has_ret = false;
                @StmtNode bs = s.true_body;
                while bs != null {
                    if bs.nk == RETURN || bs.nk == THROW {
                        has_ret = true;
                    }
                    bs = bs.next;
                }
                !!! `parser.get_error().empty()`: the parser reports no error by
                !!! itself, which is the p_errors count of this implementation.
                !!! `attribute f: EXTERN` (the body is defined elsewhere) and
                !!! `attribute f: NORETURN` (it does not come back) both say the
                !!! missing `return` is not missing, so neither is reported here.
                if s.func_ret_type != VOID && !has_ret && p_errors == 0 &&
                   !attr_has_effect(s.var_name, ATTR_EFFECT_NOBODY) {
                    int el = s.end_line;
                    if el == 0 {
                        el = s.line;
                    }
                    int ec = s.end_col;
                    if ec == 0 {
                        ec = s.col;
                    }
                    rg_fmt_err(el, ec, "function '" + shown +
                               "' must contain at least one return statement",
                               0, (str)null, 0, true);
                    rg_has_errors = true;
                }
                rgx_validate_stmts(s.true_body, depth, s.func_ret_type);
                rg_cur_func_name = saved_fn;
                rg_cur_func_ret = saved_rt;
                !!! Restore symbols shadowed by params.
                rg_pop_func_params();
            }
        }
        s = s.next;
    }
}

!!! validate_control_flow: the whole program, at file level, where no loop encloses
!!! anything and the "function" the file itself stands for returns int.
void rg_validate_control_flow {
    rgx_validate_stmts(rg_stmts, 0, INT);
}

!!! const_info_of: the const entry of a name, read from the scopes that enclose the
!!! statement, innermost first. `_const_scopes.rbegin()` is the head of
!!! the chain here, because rg_const_scope_push puts the innermost scope in front.
@ConstInfo rg_const_info_of -> str name {
    @RgConstScope sc = rg_const_scopes;
    while sc != null {
        @RgConstMap f = rg_constmap_find(sc.entries, name);
        if f != null {
            return f.info;
        }
        sc = sc.next;
    }
    return null;
}

!!! check_const_body: one body in a scope of its own. A declaration made by this
!!! body is visible from here on; the scopes of the bodies it contains are pushed as
!!! they are walked. One case arm of a switch is a frame in the toolchain; this implementation's case
!!! arms are one chain (ast.b), so they share the frame this body opens.
void rg_check_const_body -> @StmtNode body {
    rg_const_scope_push(rgx_const_scope_new());
    @StmtNode s = body;
    while s != null {
        if s != null && s.nk == DECLARE {
            int line = s.var_line;
            if line == 0 {
                line = s.line;
            }
            int col = s.var_col;
            if col == 0 {
                col = s.col;
            }
            @ConstInfo ci = rgx_const_info(s.decl_is_const, line, col, pe_len(s.var_name));
            rg_const_scopes.entries =
                rg_constmap_set(rg_const_scopes.entries, s.var_name, ci);
            !!! `ref T r = x` hands out a second name for x that can be written
            !!! through, so x has to be writable itself. This holds for a plain `ref`
            !!! as well, so it is checked before the const case below.
            if s.decl_is_ref && s.expr != null && s.expr.nk == VAR_REF {
                @ConstInfo src = rg_const_info_of(s.expr.var_name);
                if src != null && src.is_const {
                    str srcname = rg_display_name(s.expr.var_name);
                    str m = "cannot bind 'ref' to const '" + srcname + "'";
                    int hl = s.expr.tok_len;
                    if hl <= 0 {
                        hl = pe_len(srcname);
                    }
                    rg_fmt_err(s.expr.line, s.expr.col, m, hl, (str)null, 0, true);
                    int sl = src.len;
                    if sl <= 0 {
                        sl = 1;
                    }
                    rg_fmt_note(src.line, src.col, "declared const here", sl);
                    rg_has_errors = true;
                }
            }
            if s.decl_is_const {
                !!! A const that is never given a value is a name that nothing can use.
                !!! A struct object is left alone: its `init` body is where it is filled,
                !!! and `attribute k: INIT` says the same about a value that comes from
                !!! somewhere this compiler cannot see.
                if s.struct_type == "" && !s.is_array && s.expr == null &&
                   !attr_has_effect(s.var_name, ATTR_EFFECT_INIT) {
                    str shown = rg_display_name(s.var_name);
                    rg_fmt_err(ci.line, ci.col,
                               "const '" + shown + "' must be initialized",
                               pe_len(shown), (str)null, 0, true);
                    rg_has_errors = true;
                }
            }
        }
        s = s.next;
    }
    @StmtNode s2 = body;
    while s2 != null {
        rg_check_const_stmt(s2);
        s2 = s2.next;
    }
    rg_const_scope_drop();
}

!!! check_const_stmt: the writes one statement makes, and the bodies under it in
!!! scopes of their own.
!!! The expression the walk of the assignments inside an expression is standing on.
@ExprNode rg_check_const_expr_out;

!!! One expression: an assignment standing inside it writes its target the way
!!! `k = 1;` does, so a `const` target is reported with the same message. the toolchain
!!! walks the same expressions with a lambda in `check_const_stmt`.
void rg_check_const_expr_one {
    @ExprNode n = rg_check_const_expr_out;
    if n == null {
        end;
    }
    if n.nk == ASSIGN_EXPR && n.left != null {
        @ExprNode t = n.left;
        while t != null && t.nk == ASSIGN_EXPR {
            t = t.left;
        }
        str nm = "";
        if t != null && t.nk == VAR_REF {
            nm = t.var_name;
        } else if t != null && t.nk == UNARY && p_text_eq(t.op, "$") && t.left != null {
            nm = t.left.var_name;
        }
        if nm != "" {
            @ConstInfo ci2 = rg_const_info_of(nm);
            if ci2 != null && ci2.is_const {
                str shown2 = rg_display_name(nm);
                int hl2 = pe_len(shown2);
                if hl2 <= 0 {
                    hl2 = 1;
                }
                rg_fmt_err(t.line, t.col, "cannot assign to const '" + shown2 + "'", hl2,
                           (str)null, 0, true);
                int cl2 = ci2.len;
                if cl2 <= 0 {
                    cl2 = 1;
                }
                rg_fmt_note(ci2.line, ci2.col, "declared const here", cl2);
                rg_has_errors = true;
            }
        }
    }
    rg_check_const_expr_out = n.left;
    rg_check_const_expr_one();
    rg_check_const_expr_out = n.right;
    rg_check_const_expr_one();
    @ExprNode a2 = n.args;
    while a2 != null {
        rg_check_const_expr_out = a2;
        rg_check_const_expr_one();
        a2 = a2.next;
    }
    @ExprNode i2 = n.indices;
    while i2 != null {
        rg_check_const_expr_out = i2;
        rg_check_const_expr_one();
        i2 = i2.next;
    }
    @ExprNode t3 = n.targ_exprs;
    while t3 != null {
        rg_check_const_expr_out = t3;
        rg_check_const_expr_one();
        t3 = t3.next;
    }
}

!!! Every expression of one statement, walked for the assignments standing in them.
void rg_check_const_exprs -> @StmtNode s {
    if s == null {
        end;
    }
    rg_check_const_expr_out = s.expr;
    rg_check_const_expr_one();
    @ExprNode a = s.args;
    while a != null {
        rg_check_const_expr_out = a;
        rg_check_const_expr_one();
        a = a.next;
    }
    @ExprNode ai = s.array_init;
    while ai != null {
        rg_check_const_expr_out = ai;
        rg_check_const_expr_one();
        ai = ai.next;
    }
    @ExprNode ix = s.assign_indices;
    while ix != null {
        rg_check_const_expr_out = ix;
        rg_check_const_expr_one();
        ix = ix.next;
    }
    @ExprNode ce = s.case_exprs;
    while ce != null {
        rg_check_const_expr_out = ce;
        rg_check_const_expr_one();
        ce = ce.next;
    }
    rg_check_const_expr_out = s.array_len_expr;
    rg_check_const_expr_one();
}

void rg_check_const_stmt -> @StmtNode s {
    if s == null {
        end;
    }
    !!! An assignment written inside an expression writes its target the way `a = v;`
    !!! does, so a `const` target is reported here too.
    rg_check_const_exprs(s);
    bool was_function = false;
    if s.nk == ASSIGN {
        !!! The store the `static` guard makes is the one initialization a
        !!! `static const` allows, not a write to report.
        if !s.static_init {
            !!! The variable a chain of members and subscripts starts from is the one
            !!! that has to be writable: `p.x = 1`, `a[0] = 1` and `p.x.y = 1` all
            !!! write into `p` or `a`.
            @ConstInfo ci = rg_const_info_of(s.var_name);
            if ci != null && ci.is_const {
                int el = s.var_line;
                if el == 0 {
                    el = s.line;
                }
                int ec = s.var_col;
                if ec == 0 {
                    ec = s.col;
                }
                str shown = rg_display_name(s.var_name);
                int hl = pe_len(shown);
                if hl <= 0 {
                    hl = 1;
                }
                rg_fmt_err(el, ec, "cannot assign to const '" + shown + "'", hl, (str)null, 0, true);
                int cl = ci.len;
                if cl <= 0 {
                    cl = 1;
                }
                rg_fmt_note(ci.line, ci.col, "declared const here", cl);
                rg_has_errors = true;
            }
        }
    } else if s.nk == INCR {
        @ConstInfo ci2 = rg_const_info_of(s.var_name);
        if ci2 != null && ci2.is_const {
            int el2 = s.var_line;
            if el2 == 0 {
                el2 = s.line;
            }
            int ec2 = s.var_col;
            if ec2 == 0 {
                ec2 = s.col;
            }
            str shown2 = rg_display_name(s.var_name);
            int hl2 = pe_len(shown2);
            if hl2 <= 0 {
                hl2 = 1;
            }
            rg_fmt_err(el2, ec2, "cannot modify const '" + shown2 + "'", hl2, (str)null, 0, true);
            int cl2 = ci2.len;
            if cl2 <= 0 {
                cl2 = 1;
            }
            rg_fmt_note(ci2.line, ci2.col, "declared const here", cl2);
            rg_has_errors = true;
        }
    } else if s.nk == FUNCTION {
        was_function = true;
        if !s.broken && !s.is_stub {
            !!! The body is reported inside this function, so the `In function '...'`
            !!! header names the one the write is in and not whatever function the
            !!! previous pass visited last.
            str saved_fn = rg_cur_func_name;
            VarType saved_rt = rg_cur_func_ret;
            str saved_rs = rg_cur_func_ret_struct;
            int saved_fl = rg_func_line;
            rg_cur_func_name = rg_display_name(s.var_name);
            rg_cur_func_ret = s.func_ret_type;
            rg_cur_func_ret_struct = s.ret_struct;
            rg_func_line = s.line;
            rg_func_header = "";
            rg_const_scope_push(rgx_const_scope_new());
            !!! Every parameter in order; the ones declared `const` are read-only in
            !!! the body. The position of each name travels in the name's own node in
            !!! this implementation (the toolchain keeps fparam_lines/cols/lens beside the names).
            @StrNode pn = s.fparams;
            @BoolNode pc = s.fparam_is_const;
            int i = 0;
            while pn != null && i < s.nfparams {
                bool is_c = false;
                if pc != null {
                    is_c = pc.v;
                }
                if is_c {
                    int ln = pn.line;
                    if ln == 0 {
                        ln = s.line;
                    }
                    int cl = pn.col;
                    if cl == 0 {
                        cl = s.col;
                    }
                    int le = pn.len;
                    if le <= 0 {
                        le = pe_len(pn.s);
                    }
                    @ConstInfo pci = rgx_const_info(true, ln, cl, le);
                    rg_const_scopes.entries =
                        rg_constmap_set(rg_const_scopes.entries, pn.s, pci);
                }
                pn = pn.next;
                if pc != null {
                    pc = pc.next;
                }
                i = i + 1;
            }
            !!! Locals of the body are collected by check_const_body(), which pushes
            !!! the scope they live in and walks every nested body.
            rg_check_const_body(s.true_body);
            rg_const_scope_drop();
            rg_cur_func_name = saved_fn;
            rg_cur_func_ret = saved_rt;
            rg_cur_func_ret_struct = saved_rs;
            rg_func_line = saved_fl;
        }
    }
    !!! A function body was already walked above, inside its own context; every other
    !!! enclosing body of this statement is walked with its own scope, so a name
    !!! declared inside one of them shadows what it encloses.
    if was_function {
        end;
    }
    if s.true_body != null {
        rg_check_const_body(s.true_body);
    }
    if s.false_body != null {
        rg_check_const_body(s.false_body);
    }
    !!! `for (auto& cb : s->case_bodies)`: the case arms are one chain in this implementation.
    if s.case_bodies != null {
        rg_check_const_body(s.case_bodies);
    }
    if s.unmatch_body != null {
        rg_check_const_body(s.unmatch_body);
    }
    !!! `if (!s->children.empty()) check_const_body(s->children);` - a PACKAGE's
    !!! members are `true_body` here, so the walk above already covered them.
}

!!! check_const_writes: the whole-program const check. File-level declarations are
!!! visible in every body, and so are the hidden `static` slots the static pass
!!! registered in rg_static_const.
void rg_check_const_writes {
    rg_const_scopes = null;
    !!! File-level declarations are visible in every body.
    rg_const_scope_push(rgx_const_scope_new());
    !!! A `static const` has its storage in a hidden global, so it is registered from
    !!! the pass that built that global (materialize_static_locals) instead of from a
    !!! declaration statement of its own.
    @RgConstMap kv = rg_static_const;
    while kv != null {
        rg_const_scopes.entries =
            rg_constmap_set(rg_const_scopes.entries, kv.key, kv.info);
        kv = kv.next;
    }
    @StmtNode s = rg_stmts;
    while s != null {
        if s != null && s.nk == DECLARE && s.decl_is_const {
            int line = s.var_line;
            if line == 0 {
                line = s.line;
            }
            int col = s.var_col;
            if col == 0 {
                col = s.col;
            }
            @ConstInfo ci = rgx_const_info(true, line, col, pe_len(s.var_name));
            rg_const_scopes.entries =
                rg_constmap_set(rg_const_scopes.entries, s.var_name, ci);
            if s.struct_type == "" && !s.is_array && s.expr == null &&
               !attr_has_effect(s.var_name, ATTR_EFFECT_INIT) {
                str shown = rg_display_name(s.var_name);
                rg_fmt_err(ci.line, ci.col, "const '" + shown + "' must be initialized",
                           pe_len(shown), (str)null, 0, true);
                rg_has_errors = true;
            }
        }
        s = s.next;
    }
    @StmtNode s2 = rg_stmts;
    while s2 != null {
        if s2 != null {
            if s2.nk == FUNCTION {
                rg_check_const_stmt(s2);
            } else if s2.true_body != null || s2.false_body != null ||
                      s2.unmatch_body != null {
                !!! A body at file level (a `type` is not one). the toolchain also tests
                !!! `!s->children.empty()`, which is the same chain here.
                rg_check_const_body(s2.true_body);
            }
        }
        s2 = s2.next;
    }
    !!! A method body is declared inside a `type`, so it is not in the statement list:
    !!! walk every type's methods and its `init` / `destruct` bodies.
    @StructDef sd = p_struct_defs;
    while sd != null {
        @StructMethod m = sd.methods;
        while m != null {
            if m.fn != null {
                rg_check_const_stmt(m.fn);
            }
            m = m.next;
        }
        if sd.init_func != null {
            rg_check_const_stmt(sd.init_func);
        }
        if sd.destruct_func != null {
            rg_check_const_stmt(sd.destruct_func);
        }
        sd = sd.next;
    }
    rg_const_scopes = null;
}
