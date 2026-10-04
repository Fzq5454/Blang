#once
!~
 ~  bootstrap/frontend/rgen_builtins.b: the frontend/rgen_builtins.
 ~
 ~  The normalization walk: every call in the tree gets its named arguments put in
 ~  positional order and its omitted trailing arguments filled from the parameter
 ~  default values, which is what normalize_call_args does (rgen_normargs.b). A
 ~  method call carries its receiver as the first argument, so the signature applied
 ~  to it is the one the receiver's type declares, and that lookup is method_of_call.
 ~
 ~  The four vectors of normalize_call_args are the five
 ~  rg_normalize_call_args_out_* globals of rgen.b: the caller
 ~  puts the chain of the call in them, calls, and reads the reordered chain back.
 ~  `s->children` is `s.true_body` here (parser_package.b), so the walk of a
 ~  statement's bodies below covers it.
 ~!

#head "rgen"
#head "rgen_heads"

!!! normalize_expr: the arguments of every call expression of the tree.
void rg_normalize_expr -> @ExprNode n {
    if n == null {
        end;
    }
    rg_normalize_expr(n.left);
    rg_normalize_expr(n.right);
    @ExprNode a = n.args;
    while a != null {
        rg_normalize_expr(a);
        a = a.next;
    }
    @ExprNode ix = n.indices;
    while ix != null {
        rg_normalize_expr(ix);
        ix = ix.next;
    }
    if n.nk == FUNC_CALL {
        bool method = n.has_receiver && n.args != null;
        @StmtNode m = null;
        if method {
            m = rg_method_of_call(n.args, n.var_name);
        }
        @StrNode mp = null;
        @ExprNode md = null;
        if m != null {
            mp = m.fparams;
            md = m.fparam_defaults;
        }
        int arg_start = 0;
        if method {
            arg_start = 1;
        }
        rg_normalize_call_args_out_args = n.args;
        rg_normalize_call_args_out_arg_names = n.arg_names;
        rg_normalize_call_args_out_name_lines = n.arg_name_lines;
        rg_normalize_call_args_out_name_cols = n.arg_name_cols;
        rg_normalize_call_args_out_name_lens = n.arg_name_lens;
        rg_normalize_call_args(n.var_name, n.line, n.col, n.tok_len, arg_start, mp, md);
        n.args = rg_normalize_call_args_out_args;
        n.arg_names = rg_normalize_call_args_out_arg_names;
        n.arg_name_lines = rg_normalize_call_args_out_name_lines;
        n.arg_name_cols = rg_normalize_call_args_out_name_cols;
        n.arg_name_lens = rg_normalize_call_args_out_name_lens;
    }
}

!!! method_of_call: the method a `recv.name(...)` call reaches. The receiver's
!!! struct type is what the method is declared in, and resolve_method_func follows
!!! the bases the way a call does. A BAPI method of the type (`system.out`) is
!!! declared in the type's BAPI list instead of in `methods`, so that is the second
!!! place to look: its statement carries the formal parameter names a named
!!! argument is matched against.
@StmtNode rg_method_of_call -> @ExprNode receiver, str name {
    if receiver == null {
        return null;
    }
    !!! `system.out(...)` names the type where a value would stand, so the
    !!! receiver's own name is the type; otherwise the receiver's type is looked up.
    str st = "";
    if receiver.nk == VAR_REF && p_find_struct(receiver.var_name) != null {
        st = receiver.var_name;
    } else {
        st = rg_expr_struct_type(receiver);
    }
    if st == "" {
        return null;
    }
    @StmtNode m = rg_resolve_method_func(st, name, true);
    if m != null {
        return m;
    }
    return rg_resolve_bapi_method(st, name, true);
}

!!! normalize_stmt: the calls of a statement and of every body under it.
void rg_normalize_stmt -> @StmtNode s {
    if s == null {
        end;
    }
    rg_normalize_expr(s.expr);
    rg_normalize_expr(s.array_len_expr);
    @ExprNode a = s.args;
    while a != null {
        rg_normalize_expr(a);
        a = a.next;
    }
    @ExprNode i = s.array_init;
    while i != null {
        rg_normalize_expr(i);
        i = i.next;
    }
    @ExprNode e = s.case_exprs;
    while e != null {
        rg_normalize_expr(e);
        e = e.next;
    }
    @StmtNode t = s.true_body;
    while t != null {
        rg_normalize_stmt(t);
        t = t.next;
    }
    @StmtNode f = s.false_body;
    while f != null {
        rg_normalize_stmt(f);
        f = f.next;
    }
    @StmtNode cb = s.case_bodies;
    while cb != null {
        rg_normalize_stmt(cb);
        cb = cb.next;
    }
    @StmtNode u = s.unmatch_body;
    while u != null {
        rg_normalize_stmt(u);
        u = u.next;
    }
    if s.nk == CALL_FUNC {
        bool method = s.is_method_call && s.args != null;
        @StmtNode m = null;
        if method {
            m = rg_method_of_call(s.args, s.var_name);
        }
        @StrNode mp = null;
        @ExprNode md = null;
        if m != null {
            mp = m.fparams;
            md = m.fparam_defaults;
        }
        int arg_start = 0;
        if method {
            arg_start = 1;
        }
        int el = s.var_line;
        if el == 0 {
            el = s.line;
        }
        int ec = s.var_col;
        if ec == 0 {
            ec = s.col;
        }
        rg_normalize_call_args_out_args = s.args;
        rg_normalize_call_args_out_arg_names = s.arg_names;
        rg_normalize_call_args_out_name_lines = s.arg_name_lines;
        rg_normalize_call_args_out_name_cols = s.arg_name_cols;
        rg_normalize_call_args_out_name_lens = s.arg_name_lens;
        rg_normalize_call_args(s.var_name, el, ec, pe_len(s.var_name), arg_start, mp, md);
        s.args = rg_normalize_call_args_out_args;
        s.arg_names = rg_normalize_call_args_out_arg_names;
        s.arg_name_lines = rg_normalize_call_args_out_name_lines;
        s.arg_name_cols = rg_normalize_call_args_out_name_cols;
        s.arg_name_lens = rg_normalize_call_args_out_name_lens;
    }
}

!!! builtin_param_names_of: the parameter names a builtin is declared with, the way
!!! the public .r FUNC of it is written. the toolchain answers a vector; the chain of
!!! names is what rgen.b's tables carry.
@StrNode rg_builtin_param_names_of -> str name {
    if p_text_eq(name, "__get_format__") {
        @StrNode h = p_new_name("fmt", 0, 0);
        h.next = p_new_name("rest", 0, 0);
        return h;
    }
    if p_text_eq(name, "__format_out__") {
        return p_new_name("obj", 0, 0);
    }
    return null;
}
