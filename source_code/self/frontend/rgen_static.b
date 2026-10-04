#once
!~
 ~  bootstrap/frontend/rgen_static.b: the frontend/rgen_static.
 ~
 ~  `static` storage: one slot for the whole run. `static T x = v;` keeps the value
 ~  written the first time the declaration is reached, and a `static` parameter keeps
 ~  the argument of the first call. Both are one hidden global plus a hidden flag,
 ~  and the initialization is guarded:
 ~
 ~      if (__stfN_x == 0) { __stgN_x = <v>; __stfN_x = 1; }
 ~
 ~  The guard is what makes a later execution of the same declaration keep the value
 ~  instead of writing it again. `static T x;` needs no guard at all: its slot starts
 ~  at the type's zero value (a declaration without an initializer is emitted as one)
 ~  and that zero is the value it keeps. Every hidden global is declared at the front
 ~  of the file's statements, so the flag is zero before anything runs - a top-level
 ~  call that reaches the declaration is covered too.
 ~
 ~  the toolchain walks a `a chain of StmtNode*&` by index and replaces or erases the
 ~  entry a static declaration stood at. Here a body is a chain of statements, so the
 ~  walks below carry the node before the one they stand on: replacing it links the
 ~  guard in its place, erasing it links the next statement to the one before, and
 ~  the head is answered back so the caller can store it (a body that starts with a
 ~  `static T x;` loses its first node). `s->children` is `s->true_body` in this implementation
 ~  (parser_package.b), so the true_body walk already covers it.
 ~
 ~  The node builders (`new StmtNode{...}` / `new ExprNode{...}`) are the
 ~  makers of parser.b here, and the fields those makers leave unset - a chain that
 ~  was never written reads as junk and walking it is a crash - are cleared by
 ~  rgx_new_stmt / rgx_new_expr. A `ConstInfo` is a record of rgen_heads.b, so one is
 ~  made with rgx_static_const_info. Every helper this file adds carries the `rgx_`
 ~  prefix and stands in the report of this implementation.
 ~
 ~  The vector of hidden globals the toolchain passes down is the global
 ~  rg_materialize_static_in_func_out_new_globals; it is
 ~  cleared once by materialize_static_locals and appended to by every function.
 ~!

#head "rgen"
#head "rgen_heads"

!!! A fresh statement node with every field p_new_stmt leaves unset cleared. The
!!! blocks malloc hands out are not zeroed (parser.b), and an argument or dimension
!!! chain that was never written reads as junk, so a walk over it is a crash.
@StmtNode rgx_new_stmt -> StmtKind nk {
    @StmtNode s = p_new_stmt(nk);
    s.arg_names = null;
    s.arg_name_lines = null;
    s.arg_name_cols = null;
    s.arg_name_lens = null;
    s.targ_structs = null;
    s.targ_is_value = null;
    s.fparam_has_default = null;
    s.array_dims = null;
    return s;
}

!!! The same for an expression node (p_new_expr leaves the index list and the
!!! template argument lists unset).
@ExprNode rgx_new_expr -> ExprKind nk {
    @ExprNode e = p_new_expr(nk);
    e.indices = null;
    e.targs = null;
    e.targ_structs = null;
    e.targ_is_value = null;
    e.lambda_id = 0;
    return e;
}

!!! One const entry, read-only by construction: the hidden `static const` slots this
!!! pass registers so the const-write check reports a write to them.
@ConstInfo rgx_static_const_info -> int line, int col, int len {
    ConstInfo proto;
    @ConstInfo ci;
    malloc(@ci, size proto);
    ci.is_const = true;
    ci.line = line;
    ci.col = col;
    ci.len = len;
    return ci;
}

!!! ---- the nodes the pass builds ----

!!! static_scalar_ok: true for the scalar types a `static` slot can hold. A struct
!!! object, an array and a reference have storage of their own (a heap pointer, a
!!! field layout) that this pass would have to reproduce, so they are refused
!!! instead of half-supported.
bool rgx_static_scalar_ok -> VarType t, str struct_type, bool is_array, bool is_ref {
    if struct_type != "" || is_array || is_ref {
        return false;
    }
    return t == INT || t == LONG || t == FLOAT || t == BOOL || t == CHAR || t == STR;
}

!!! make_static_slot: the hidden slot (`__stgN_x`), zero initialized like a
!!! declaration without an initializer. The guard writes the real value on the first
!!! execution.
@StmtNode rgx_make_static_slot -> str name, VarType t, int line, int col {
    @StmtNode d = rgx_new_stmt(DECLARE);
    d.var_name = name;
    d.decl_type = t;
    d.line = line;
    d.col = col;
    d.var_line = line;
    d.var_col = col;
    d.type_col = col;
    return d;
}

!!! make_flag_test: `flag == 0`, the test that says the slot was never initialized.
@ExprNode rgx_make_flag_test -> str flag, int line, int col {
    @ExprNode v = rgx_new_expr(VAR_REF);
    v.var_name = flag;
    v.line = line;
    v.col = col;
    v.tok_len = 0;
    @ExprNode zero = rgx_new_expr(LIT_INT);
    zero.int_val = 0;
    zero.result_type = INT;
    zero.line = line;
    zero.col = col;
    zero.tok_len = 0;
    @ExprNode cmp = rgx_new_expr(BINOP);
    cmp.op = "==";
    cmp.left = v;
    cmp.right = zero;
    cmp.result_type = BOOL;
    cmp.line = line;
    cmp.col = col;
    cmp.tok_len = 0;
    return cmp;
}

!!! make_flag_store: `flag = 1`.
@StmtNode rgx_make_flag_store -> str flag, int line, int col {
    @StmtNode s = rgx_new_stmt(ASSIGN);
    s.var_name = flag;
    s.line = line;
    s.col = col;
    s.var_line = line;
    s.var_col = col;
    @ExprNode one = rgx_new_expr(LIT_INT);
    one.int_val = 1;
    one.result_type = INT;
    one.line = line;
    one.col = col;
    one.tok_len = 0;
    s.expr = one;
    return s;
}

!!! make_static_guard: `if (flag == 0) { slot = value; flag = 1; }`. The store is
!!! the one write a `static const` accepts, which is what static_init marks it as.
@StmtNode rgx_make_static_guard -> str slot, str flag, @ExprNode value, int line,
                                   int col {
    @StmtNode guard = rgx_new_stmt(IF_ELSE);
    guard.line = line;
    guard.col = col;
    guard.expr = rgx_make_flag_test(flag, line, col);
    guard.static_guard = true;
    if value != null {
        @StmtNode store = rgx_new_stmt(ASSIGN);
        store.var_name = slot;
        !!! Ownership moves into the guard.
        store.expr = value;
        store.line = line;
        store.col = col;
        store.var_line = line;
        store.var_col = col;
        store.static_init = true;
        guard.true_body = p_chain_stmt(guard.true_body, store);
    }
    guard.true_body = p_chain_stmt(guard.true_body, rgx_make_flag_store(flag, line, col));
    return guard;
}

!!! ---- the pass ----

!!! rename_static_uses: rename the references of a static inside its function body.
!!! The declaration itself is replaced by the guard, so only uses are renamed; a
!!! nested function body is a scope of its own and keeps its names.
void rg_rename_static_uses -> @StmtNode body, str from, str to {
    @StmtNode s = body;
    while s != null {
        if s != null && !s.static_guard && !s.static_init && s.nk != FUNCTION {
            if s.nk != DECLARE && pe_eq(s.var_name, from) {
                s.var_name = to;
            }
            rg_rename_var_expr(s.expr, from, to);
            rg_rename_var_expr(s.array_len_expr, from, to);
            @ExprNode a = s.args;
            while a != null {
                rg_rename_var_expr(a, from, to);
                a = a.next;
            }
            @ExprNode ai = s.array_init;
            while ai != null {
                rg_rename_var_expr(ai, from, to);
                ai = ai.next;
            }
            @ExprNode as = s.assign_indices;
            while as != null {
                rg_rename_var_expr(as, from, to);
                as = as.next;
            }
            @ExprNode ce = s.case_exprs;
            while ce != null {
                rg_rename_var_expr(ce, from, to);
                ce = ce.next;
            }
            rg_rename_static_uses(s.true_body, from, to);
            rg_rename_static_uses(s.false_body, from, to);
            !!! `for (auto& cb : s->case_bodies)`: the arms are one chain here.
            rg_rename_static_uses(s.case_bodies, from, to);
            rg_rename_static_uses(s.unmatch_body, from, to);
        }
        s = s.next;
    }
}

!!! register_global_decl (the `add(nm)` lambda of the toolchain): one hidden global in the
!!! symbol tables. A name the tables already hold is left alone - the tables of the
!!! declaration pass were filled before this pass ran.
void rgx_register_global_one -> @StmtNode s, str nm {
    if rg_vartypemap_find(rg_syms, nm) != null {
        end;
    }
    rg_syms = rg_vartypemap_set(rg_syms, nm, s.decl_type);
    rg_sym_depth = rg_intmap_set(rg_sym_depth, nm, s.ptr_depth);
    if s.struct_type != "" {
        rg_sym_struct_type = rg_strmap_set(rg_sym_struct_type, nm, s.struct_type);
        if s.ptr_depth > 0 {
            rg_sym_struct_ptr = rg_boolmap_set(rg_sym_struct_ptr, nm, true);
        }
    }
    if s.is_array {
        rg_sym_is_array = rg_boolmap_set(rg_sym_is_array, nm, true);
        if s.array_dims != null {
            rg_sym_dims = rg_dimmap_set(rg_sym_dims, nm, rg_longchain_of(s.array_dims), 1);
        }
    }
    if s.decl_is_ref {
        rg_sym_is_ref = rg_boolmap_set(rg_sym_is_ref, nm, true);
    }
    if s.decl_is_unsigned {
        rg_sym_is_unsigned = rg_boolmap_set(rg_sym_is_unsigned, nm, true);
    }
}

!!! register_global_decl: the hidden globals of one static, plus the registration
!!! they need: this pass runs after the declaration pass, so they are not in the
!!! tables that pass filled. The `::name` alias is registered the way a user-written
!!! global gets one.
void rg_register_global_decl -> @StmtNode s {
    if s == null || s.var_name == "" {
        end;
    }
    rgx_register_global_one(s, s.var_name);
    rg_global_names = rg_set_add(rg_global_names, s.var_name);
    rgx_register_global_one(s, "__global_" + s.var_name);
}

!!! static_walk_body: the `walk` of materialize_static_in_func, one body. Every
!!! `static` declaration it reaches becomes its hidden slot (and its guard), and the
!!! head of the body it answers has to be stored by the caller, because the first
!!! statement of a body may be the one that goes away. `fn` is the function being
!!! materialized, which is the body rename_static_uses is applied to.
@StmtNode rgx_static_walk_body -> @StmtNode body, @StmtNode fn {
    @StmtNode head = body;
    @StmtNode prev = null;
    @StmtNode cnode = body;
    while cnode != null {
        @StmtNode nxt = cnode.next;
        bool drop = false;
        @StmtNode repl = null;
        if cnode.nk == FUNCTION {
            !!! Its own scope, handled on its own.
        } else if cnode.nk != DECLARE || !cnode.decl_is_static {
            cnode.true_body = rgx_static_walk_body(cnode.true_body, fn);
            cnode.false_body = rgx_static_walk_body(cnode.false_body, fn);
            !!! `walk(s->children)` is the true_body walk above (parser_package.b).
            cnode.case_bodies = rgx_static_walk_body(cnode.case_bodies, fn);
            cnode.unmatch_body = rgx_static_walk_body(cnode.unmatch_body, fn);
        } else {
            cnode.decl_is_static = false;
            str name = cnode.var_name;
            int line = cnode.var_line;
            if line == 0 {
                line = cnode.line;
            }
            int col = cnode.var_col;
            if col == 0 {
                col = cnode.col;
            }
            int len = pe_len(name);
            if !rgx_static_scalar_ok(cnode.decl_type, cnode.struct_type, cnode.is_array,
                                     cnode.decl_is_ref) {
                str m = "static is only supported for a scalar variable, not '" + name + "'";
                rg_fmt_err(line, col, m, len > 0 ? len : 1, (str)null, 0, true);
                rg_has_errors = true;
                !!! It stays an ordinary local, so the body still compiles.
            } else {
                rg_static_seq = rg_static_seq + 1;
                str slot = "__stg" + (str)rg_static_seq + "_" + name;
                str flag = "__stf" + (str)rg_static_seq + "_" + name;
                @StmtNode sd = rgx_make_static_slot(slot, cnode.decl_type, line, col);
                sd.decl_is_unsigned = cnode.decl_is_unsigned;
                rg_register_global_decl(sd);
                rg_materialize_static_in_func_out_new_globals =
                    p_chain_stmt(rg_materialize_static_in_func_out_new_globals, sd);
                !!! The flag only exists when there is an initializer to guard; without
                !!! one the zero the slot starts at is the value kept.
                if cnode.expr != null {
                    @StmtNode fd = rgx_make_static_slot(flag, INT, line, col);
                    rg_register_global_decl(fd);
                    rg_materialize_static_in_func_out_new_globals =
                        p_chain_stmt(rg_materialize_static_in_func_out_new_globals, fd);
                }
                rg_display_names = rg_strmap_set(rg_display_names, slot, name);
                if cnode.decl_is_const {
                    !!! The slot is what a write in the body goes to, so the const-write
                    !!! pass has to know it is read-only.
                    rg_static_const = rg_constmap_set(rg_static_const, slot,
                        rgx_static_const_info(line, col, len));
                    if cnode.expr == null {
                        str m2 = "const '" + name + "' must be initialized";
                        rg_fmt_err(line, col, m2, len > 0 ? len : 1, (str)null, 0, true);
                        rg_has_errors = true;
                    }
                }
                rg_rename_static_uses(fn.true_body, name, slot);
                if cnode.expr != null {
                    @ExprNode value = cnode.expr;
                    !!! Ownership moves into the guard.
                    cnode.expr = null;
                    repl = rgx_make_static_guard(slot, flag, value, line, col);
                } else {
                    !!! No initializer: the zero the slot already holds is the value it
                    !!! keeps, so the guard is not needed at all.
                    drop = true;
                }
            }
        }
        !!! the toolchain replaces body[idx] with the guard or erases the entry; either way
        !!! the walk steps on to the statement that followed it.
        if repl != null {
            repl.next = nxt;
            if prev == null {
                head = repl;
            } else {
                prev.next = repl;
            }
            prev = repl;
        } else if drop {
            if prev == null {
                head = nxt;
            } else {
                prev.next = nxt;
            }
        } else {
            prev = cnode;
        }
        cnode = nxt;
    }
    return head;
}

!!! materialize_static_in_func: every `static` of one function. A `static` parameter
!!! keeps the argument of the first call: the parameter itself stays in the signature
!!! (the caller still passes a value); only the body reads the hidden slot, and the
!!! guard copies the incoming value in.
void rg_materialize_static_in_func -> @StmtNode fn {
    if fn == null || fn.broken || fn.is_stub {
        end;
    }
    !!! The messages of this pass belong to the function they are in.
    str saved_fn = rg_cur_func_name;
    VarType saved_rt = rg_cur_func_ret;
    str saved_rs = rg_cur_func_ret_struct;
    int saved_fl = rg_func_line;
    rg_cur_func_name = rg_display_name(fn.var_name);
    rg_cur_func_ret = fn.func_ret_type;
    rg_cur_func_ret_struct = fn.ret_struct;
    rg_func_line = fn.line;
    rg_func_header = "";
    @StmtNode param_guards = null;
    !!! The parameter lists are parallel chains; the cursors are moved before the body
    !!! of the loop runs, so the `continue` below is the `continue` loop.
    @StrNode pn = fn.fparams;
    @VarTypeNode ptt = fn.fparam_types;
    @StrNode pss = fn.fparam_struct;
    @BoolNode parr = fn.fparam_is_array;
    @BoolNode pref = fn.fparam_is_ref;
    @BoolNode pc = fn.fparam_is_const;
    @BoolNode pst = fn.fparam_is_static;
    while pn != null && pst != null {
        @StrNode name_node = pn;
        @BoolNode st_node = pst;
        VarType pt = INT;
        if ptt != null {
            pt = ptt.ty;
        }
        str pstruct = "";
        if pss != null {
            pstruct = pss.s;
        }
        bool p_is_arr = false;
        if parr != null {
            p_is_arr = parr.v;
        }
        bool p_is_ref = false;
        if pref != null {
            p_is_ref = pref.v;
        }
        bool p_is_const = false;
        if pc != null {
            p_is_const = pc.v;
        }
        bool was_static = st_node.v;
        int pline = name_node.line;
        if pline == 0 {
            pline = fn.line;
        }
        int pcol = name_node.col;
        if pcol == 0 {
            pcol = fn.col;
        }
        int plen = name_node.len;
        if plen <= 0 {
            plen = pe_len(name_node.s);
        }
        pn = pn.next;
        if ptt != null {
            ptt = ptt.next;
        }
        if pss != null {
            pss = pss.next;
        }
        if parr != null {
            parr = parr.next;
        }
        if pref != null {
            pref = pref.next;
        }
        if pc != null {
            pc = pc.next;
        }
        pst = pst.next;
        if !was_static {
            continue;
        }
        !!! Materialized once.
        st_node.v = false;
        if !rgx_static_scalar_ok(pt, pstruct, p_is_arr, p_is_ref) {
            str m = "static is only supported for a scalar parameter, not '" +
                    name_node.s + "'";
            rg_fmt_err(pline, pcol, m, plen > 0 ? plen : 1, (str)null, 0, true);
            rg_has_errors = true;
            continue;
        }
        rg_static_seq = rg_static_seq + 1;
        str slot = "__stg" + (str)rg_static_seq + "_" + name_node.s;
        str flag = "__stf" + (str)rg_static_seq + "_" + name_node.s;
        @StmtNode sd = rgx_make_static_slot(slot, pt, pline, pcol);
        @StmtNode fd = rgx_make_static_slot(flag, INT, pline, pcol);
        rg_register_global_decl(sd);
        rg_register_global_decl(fd);
        rg_materialize_static_in_func_out_new_globals =
            p_chain_stmt(rg_materialize_static_in_func_out_new_globals, sd);
        rg_materialize_static_in_func_out_new_globals =
            p_chain_stmt(rg_materialize_static_in_func_out_new_globals, fd);
        rg_display_names = rg_strmap_set(rg_display_names, slot, name_node.s);
        if p_is_const {
            rg_static_const = rg_constmap_set(rg_static_const, slot,
                rgx_static_const_info(pline, pcol, plen));
        }
        !!! Body uses read the slot; the guard below still reads the parameter, so it
        !!! is built after the rename.
        rg_rename_static_uses(fn.true_body, name_node.s, slot);
        @ExprNode arg = rgx_new_expr(VAR_REF);
        arg.var_name = name_node.s;
        arg.line = pline;
        arg.col = pcol;
        arg.tok_len = plen;
        param_guards = p_chain_stmt(param_guards,
            rgx_make_static_guard(slot, flag, arg, pline, pcol));
    }
    !!! The guards go in front of the body, in parameter order.
    if param_guards != null {
        @StmtNode tail = param_guards;
        while tail.next != null {
            tail = tail.next;
        }
        tail.next = fn.true_body;
        fn.true_body = param_guards;
    }
    !!! A `static` local is initialized where it is written, the first time execution
    !!! reaches it.
    fn.true_body = rgx_static_walk_body(fn.true_body, fn);
    rg_cur_func_name = saved_fn;
    rg_cur_func_ret = saved_rt;
    rg_cur_func_ret_struct = saved_rs;
    rg_func_line = saved_fl;
}

!!! static_walk_file: the `walk` of materialize_static_locals, over the file's
!!! statement chain. Every function is materialized, a file-level `static` is
!!! reported (a file-level variable already lives for the whole run), and every other
!!! statement's bodies are walked. Nothing is inserted or erased here, so the chain
!!! is not rebuilt.
void rgx_static_walk_file -> @StmtNode body {
    @StmtNode s = body;
    while s != null {
        if s != null {
            if s.nk == FUNCTION {
                rg_materialize_static_in_func(s);
            } else if s.nk == DECLARE && s.decl_is_static {
                !!! A file-level variable already lives for the whole run, so `static`
                !!! adds nothing there.
                int line = s.var_line;
                if line == 0 {
                    line = s.line;
                }
                int col = s.var_col;
                if col == 0 {
                    col = s.col;
                }
                str m = "static is only allowed for a local variable, not '" +
                        s.var_name + "'";
                !!! the toolchain clears the function context so the message carries no
                !!! "In function" header.
                str saved = rg_cur_func_name;
                rg_cur_func_name = "";
                rg_func_header = "";
                rg_fmt_err(line, col, m, pe_len(s.var_name), (str)null, 0, true);
                rg_cur_func_name = saved;
                s.decl_is_static = false;
                rg_has_errors = true;
            } else {
                rgx_static_walk_file(s.true_body);
                rgx_static_walk_file(s.false_body);
                !!! `walk(s->children)` is the true_body walk above (parser_package.b).
                rgx_static_walk_file(s.case_bodies);
                rgx_static_walk_file(s.unmatch_body);
            }
        }
        s = s.next;
    }
}

!!! materialize_static_locals: the whole program. Every function of the file is
!!! materialized - a top-level one, a `local` one nested in a body, or a method (a
!!! method body is not part of the statement list) - and the hidden globals they
!!! asked for go in front of the statement list, so every flag is zero before the
!!! first statement of the program runs (a top-level call included).
@StmtNode rg_materialize_static_locals -> @StmtNode stmts {
    rg_materialize_static_in_func_out_new_globals = null;
    rgx_static_walk_file(stmts);
    @StructDef sd = p_struct_defs;
    while sd != null {
        if sd.init_func != null {
            rg_materialize_static_in_func(sd.init_func);
        }
        if sd.destruct_func != null {
            rg_materialize_static_in_func(sd.destruct_func);
        }
        @StructMethod m = sd.methods;
        while m != null {
            if m.fn != null {
                rg_materialize_static_in_func(m.fn);
            }
            m = m.next;
        }
        sd = sd.next;
    }
    @StmtNode ng = rg_materialize_static_in_func_out_new_globals;
    if ng != null {
        @StmtNode tail = ng;
        while tail.next != null {
            tail = tail.next;
        }
        tail.next = stmts;
        return ng;
    }
    return stmts;
}
