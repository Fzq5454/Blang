#once
!~
 ~  bootstrap/frontend/rgen_used.b: the frontend/rgen_used.
 ~
 ~  The -W-nused tracking: which variables are read and which functions are called,
 ~  and the warnings for the declarations nothing reached.
 ~
 ~  the toolchain keeps four tables (used_vars, used_funcs, declared_vars,
 ~  declared_funcs); in this implementation they are the chains of rgen.b, so "insert a name"
 ~  is rg_set_add and every lookup is rg_set_has. A declaration of a `#head` file is
 ~  skipped, which is the `tok.get_source` plus `tok.is_head_source` pair of the
 ~  (lex_get_source and lex_is_head_source here).
 ~
 ~  The lambda record of a lambda literal is found by the id its node carries
 ~  (p_find_lambda): the immediate arguments and the body of a literal are not on
 ~  the expression node in this implementation, they are in that record.
 ~!

#head "rgen"
#head "rgen_heads"
#head "attributes"
#head "vector"

!!! mark_used_expr: every variable a name reads, every function a call names, and
!!! the same walk through the whole expression tree. `rg_read_skip` is true inside
!!! the operand of an increment, whose value is written and not read.
bool rg_read_skip;

!!! walk_receiver_type: the struct type a member access's receiver denotes, resolved
!!! from the declarations this walk has seen. `rg_expr_struct_type` cannot answer it:
!!! it asks the per-body tables, and by the time the warnings run those hold the last
!!! body that was emitted, not this one.
str rg_walk_receiver_type -> @ExprNode n {
    if n == null {
        return "";
    }
    if n.nk == VAR_REF || n.nk == ARRAY_ACCESS {
        !!! What the resolver left on the node first (it is still there when the
        !!! warnings run), then the declaration this walk has seen for the name.
        if n.struct_type != "" {
            return n.struct_type;
        }
        @RgStrMap bit = rg_strmap_find(rg_walk_var_types, n.var_name);
        if bit != null {
            return bit.v;
        }
        @RgStrMap git = rg_strmap_find(rg_walk_global_types, n.var_name);
        if git != null {
            return git.v;
        }
        !!! A bare field of the struct whose method body this is.
        if rg_walk_struct_type != "" && p_find_struct(rg_walk_struct_type) != null {
            @StructField f = rg_resolve_field(rg_walk_struct_type, n.var_name, true);
            if f != null && f.struct_type != "" {
                return f.struct_type;
            }
        }
        return rg_expr_struct_type(n);
    }
    if n.nk == MEMBER_ACCESS {
        !!! The chain's own type when the resolver left one that stands for a struct
        !!! value, and otherwise what the field before the last one holds: a `@T`
        !!! field keeps its pointee type here, which is what `lit.decl.struct_ptr`
        !!! needs (the node itself carries no struct type, because a `@T` field's
        !!! value is an address and not a struct).
        if n.struct_type != "" {
            return n.struct_type;
        }
        str base = rg_walk_receiver_type(n.left);
        if base == "" {
            return "";
        }
        @StructField f2 = rg_resolve_field(base, n.member_name, true);
        if f2 == null {
            return "";
        }
        return f2.struct_type;
    }
    if n.nk == FIELD_ELEM {
        return n.struct_type;
    }
    !!! A call that returns a struct, a cast, ...: the resolver knows those.
    return rg_expr_struct_type(n);
}

!!! A bare name inside the body of a method of `rg_walk_struct_type` is a field of
!!! that struct, or of one of its bases. The field is taken for used on any such
!!! name: telling a local of the same name apart is not worth a wrong warning, and a
!!! field wrongly taken for used only loses a warning. A read stands only when the
!!! method it is written in is reached by something, which is decided once the whole
!!! walk has seen every call (see rg_collect_struct_uses).
void rg_mark_this_field -> str name, bool read {
    if rg_walk_struct_type == "" || name == "" {
        end;
    }
    if p_find_struct(rg_walk_struct_type) == null {
        end;
    }
    @StructField f = rg_resolve_field(rg_walk_struct_type, name, true);
    if f == null {
        end;
    }
    str dt = rg_resolve_field_out_decl_type;
    rg_mark_member_used(dt, name, false);
    if !read {
        end;
    }
    if rg_walk_struct_method == "" {
        rg_mark_member_used(dt, name, true);
        end;
    }
    RgPendingRead proto;
    @RgPendingRead pr;
    malloc(@pr, size proto);
    pr.member = rgx_member_key(dt, name);
    pr.method = rg_walk_struct_method;
    pr.next = null;
    if rg_pending_member_reads == null {
        rg_pending_member_reads = pr;
        end;
    }
    @RgPendingRead t = rg_pending_member_reads;
    while t.next != null {
        t = t.next;
    }
    t.next = pr;
}

void rg_mark_used_expr -> @ExprNode n {
    if n == null {
        end;
    }
    !!! An expression that *is* a struct mentions that struct: a value of the type
    !!! only exists because something asked for it.
    if n.struct_type != "" && p_find_struct(n.struct_type) != null {
        rg_mark_struct_used(n.struct_type);
    }
    !!! `(@Y)x`: the node carries the struct its pointer is read as, so Y is a view
    !!! over memory someone else owns.
    if n.struct_cast && n.struct_type != "" {
        rg_view_structs = rg_set_add(rg_view_structs, n.struct_type);
    }
    !!! `(@void)x`: the layout of X is handed to whoever takes the pointer, which in
    !!! this compiler is how a chain of one node type is read through another.
    if n.nk == CAST && p_text_eq(n.op, "@void") && n.left != null {
        str src = rg_walk_receiver_type(n.left);
        if src != "" {
            rg_cast_out_structs = rg_set_add(rg_cast_out_structs, src);
        }
    }
    if n.nk == VAR_REF || n.nk == ARRAY_ACCESS {
        rg_used_vars = rg_set_add(rg_used_vars, n.var_name);
        !!! The value stands here, so this is a read - unless it is the operand of an
        !!! increment, which writes it (see below).
        if !rg_read_skip {
            rg_read_vars = rg_set_add(rg_read_vars, n.var_name);
        }
        rg_mark_this_field(n.var_name, !rg_read_skip);
    } else if n.nk == FUNC_CALL {
        rg_used_funcs = rg_set_add(rg_used_funcs, n.var_name);
        !!! A plain call, and not a method of a receiver: -W-nbody-func is about the
        !!! functions of the file, and a method shares the name space of the type it
        !!! belongs to.
        if !n.has_receiver {
            rg_called_funcs = rg_set_add(rg_called_funcs, n.var_name);
        }
    } else if n.nk == SIZE {
        !!! `size X` names what is measured in var_name and keeps no operand node
        !!! (parser_primary.b): without this, every `X proto; malloc(@p, size proto);`
        !!! had its `proto` reported as an identifier that is never used. Such a
        !!! declaration carries no value of its own - it is there to name a type - so
        !!! it counts as a read as well, or -W-read-nused reported the dummy of every
        !!! `size` as a variable whose value is never read.
        rg_used_vars = rg_set_add(rg_used_vars, n.var_name);
        rg_read_vars = rg_set_add(rg_read_vars, n.var_name);
        !!! `size S` measures a struct: the type is what the program asked for, so the
        !!! struct counts as used.
        if p_find_struct(n.var_name) != null {
            rg_mark_struct_used(n.var_name);
        }
    } else if n.nk == COUNT {
        !!! `count a` names the array whose length is read: the name is used and
        !!! read, the way `size X` is. A variable-length array answers with the
        !!! length expression it was declared with, which is read here as well.
        rg_used_vars = rg_set_add(rg_used_vars, n.var_name);
        rg_read_vars = rg_set_add(rg_read_vars, n.var_name);
        if n.left != null {
            rg_mark_used_expr(n.left);
        }
    } else if n.nk == MEMBER_ACCESS {
        !!! `a.f` and `p.addr.city` read the field they name. The struct that
        !!! declares it is the one the receiver's own type resolves it in, which is a
        !!! base when the field comes from one. `self.f` written out in full is the
        !!! field `f` of the struct this method body belongs to: no variable is named
        !!! `self`, so the receiver's own type resolves to nothing and the field was
        !!! never counted - a field only a method touches was reported as never used.
        str st = rg_walk_receiver_type(n.left);
        if pe_eq(st, "") && n.left != null && n.left.nk == VAR_REF &&
           pe_eq(n.left.var_name, "self") && !pe_eq(rg_walk_struct_type, "") {
            st = rg_walk_struct_type;
        }
        if st != "" {
            @StructField f = rg_resolve_field(st, n.member_name, true);
            if f != null {
                str dt = rg_resolve_field_out_decl_type;
                rg_mark_member_used(dt, n.member_name, true);
            }
        }
    }
    !!! `x++` / `++x` writes x: -W-read-nused does not take it for a read of x, which
    !!! is the rule the toolchain warning follows. The operand is still walked, so what it
    !!! is made of (an index, a field) is marked as used.
    if n.nk == PRE_INCR || n.nk == POST_INCR {
        bool saved_skip = rg_read_skip;
        rg_read_skip = true;
        rg_mark_used_expr(n.left);
        rg_read_skip = saved_skip;
    } else {
        rg_mark_used_expr(n.left);
    }
    rg_mark_used_expr(n.right);
    @ExprNode a = n.args;
    while a != null {
        rg_mark_used_expr(a);
        a = a.next;
    }
    @ExprNode ix = n.indices;
    while ix != null {
        rg_mark_used_expr(ix);
        ix = ix.next;
    }
    !!! `for (auto* a : n->lambda_immediate_args) mark_used_expr(a);` and
    !!! `for (auto* b : n->lambda_body) mark_used_stmt(b);`: both lists stand in the
    !!! literal's record in this implementation, found by the lambda id.
    if n.nk == LAMBDA {
        @LambdaRec rec = p_find_lambda(n.lambda_id);
        if rec != null {
            @ExprNode ia = rec.immediate_args;
            while ia != null {
                rg_mark_used_expr(ia);
                ia = ia.next;
            }
            @StmtNode b = rec.body;
            while b != null {
                rg_mark_used_stmt(b);
                b = b.next;
            }
        }
    }
}

!!! The fields a store writes, and the chain it writes through. Every field of the
!!! chain but the last names the value the next one is read from, so it counts as
!!! read; the last one is what the store writes - unless the store goes *through* the
!!! value (`a.data[i] = v`, `$p = v`), which reads it, exactly as the variable rule
!!! has it.
void rg_mark_store_members -> @StmtNode s {
    if s == null {
        end;
    }
    if s.member_name == "" && s.member_chain == null {
        !!! A bare name written inside a method body is a field of the struct whose
        !!! body this is (`_lo = v` in a method of `long`).
        rg_mark_this_field(s.var_name, false);
        end;
    }
    !!! Where the chain starts: the type of the variable it is written through, a
    !!! field of the enclosing method's struct (`addr.city = v` inside a method of the
    !!! struct that declares `addr`), or the declaration in effect. The name carries
    !!! the `__used` prefix: every declaration of a source is registered in the flat
    !!! symbol tables by its plain name, and a local called `cur` here answered for
    !!! the lexer's `char cur` in the tables the rest of the file reads - and the
    !!! call `cur()` in the lexer was typed with this local's `str` in turn
    !!! (-W-ntype-cmp reports the two).
    str __used_cur = "";
    if s.struct_type != "" && p_find_struct(s.struct_type) != null {
        __used_cur = s.struct_type;
    }
    if __used_cur == "" {
        @RgStrMap bit = rg_strmap_find(rg_walk_var_types, s.var_name);
        if bit != null {
            __used_cur = bit.v;
        } else {
            @RgStrMap git = rg_strmap_find(rg_walk_global_types, s.var_name);
            if git != null {
                __used_cur = git.v;
            }
        }
    }
    if __used_cur == "" && rg_walk_struct_type != "" && p_find_struct(rg_walk_struct_type) != null {
        @StructField rf = rg_resolve_field(rg_walk_struct_type, s.var_name, true);
        if rf != null {
            str rdt = rg_resolve_field_out_decl_type;
            rg_mark_member_used(rdt, s.var_name, true);
            if !rf.struct_ptr {
                __used_cur = rf.struct_type;
            }
        }
    }
    if __used_cur == "" {
        __used_cur = rg_struct_type_in_effect(s.var_name);
    }
    if __used_cur == "" || p_find_struct(__used_cur) == null {
        end;
    }
    !!! A store that goes through the value reads the last field as well.
    bool through_store = s.nk == DREF_ASSIGN || s.assign_indices != null ||
                         s.is_index_ptr_store || s.is_index_chain_store || s.is_array;
    int i = 0;
    @StrNode c = s.member_chain;
    while true {
        str fname;
        bool last;
        if c != null {
            fname = c.s;
            if c.next == null {
                last = true;
            } else {
                last = false;
            }
        } else if i == 0 && s.member_name != "" {
            fname = s.member_name;
            last = true;
        } else {
            end;
        }
        @StructField f = rg_resolve_field(__used_cur, fname, true);
        if f == null {
            end;
        }
        str dt = rg_resolve_field_out_decl_type;
        rg_mark_member_used(dt, fname, false);
        if !last || through_store {
            rg_mark_member_used(dt, fname, true);
        }
        if last {
            end;
        }
        if f.struct_ptr {
            end;
        }
        __used_cur = f.struct_type;
        if __used_cur == "" || p_find_struct(__used_cur) == null {
            end;
        }
        c = c.next;
        i = i + 1;
    }
}

!!! mark_used_stmt: the declarations a body holds, what it writes and calls, then
!!! the same walk over its expressions and its bodies.
void rg_mark_used_stmt -> @StmtNode s {
    if s == null {
        end;
    }
    !!! A function body gets its own name -> struct type table: a local of another
    !!! body must not answer for a name written here, and a parameter of this one
    !!! must. The globals keep their own table, so a local stays a local and a global
    !!! is still found from inside every body.
    bool is_func = (s.nk == FUNCTION);
    @RgStrMap saved_types = null;
    bool saved_in_body = rg_walk_in_body;
    if is_func {
        saved_types = rg_walk_var_types;
        rg_walk_var_types = null;
        rg_walk_in_body = true;
        @StrNode pn = s.fparams;
        @StrNode ps = s.fparam_struct;
        while pn != null && ps != null {
            if ps.s != "" {
                rg_walk_var_types = rg_strmap_set(rg_walk_var_types, pn.s, ps.s);
            }
            pn = pn.next;
            ps = ps.next;
        }
    }
    if s.nk == DECLARE {
        !!! A declaration inside a struct method body is not a declaration of the
        !!! file: the struct walk reaches those bodies for their fields, and
        !!! -W-nused has never reported a local of a method.
        if rg_walk_struct_type == "" {
            int l = s.var_line;
            if l == 0 {
                l = s.line;
            }
            int c = s.var_col;
            if c == 0 {
                c = s.col;
            }
            rg_declared_vars = rg_posmap_set(rg_declared_vars, s.var_name, l, c);
        }
        !!! `S x;` mentions S, which is what "used" means for a struct. An
        !!! instantiation (`Box(int) b;`) names its mangled struct here too.
        if s.struct_type != "" && p_find_struct(s.struct_type) != null {
            rg_mark_struct_used(s.struct_type);
            if rg_walk_in_body {
                rg_walk_var_types = rg_strmap_set(rg_walk_var_types, s.var_name, s.struct_type);
            } else {
                rg_walk_global_types = rg_strmap_set(rg_walk_global_types, s.var_name, s.struct_type);
            }
        }
    } else if s.nk == FUNCTION {
        int l2 = s.var_line;
        if l2 == 0 {
            l2 = s.line;
        }
        int c2 = s.var_col;
        if c2 == 0 {
            c2 = s.col;
        }
        if rg_walk_struct_type == "" {
            rg_declared_funcs = rg_posmap_set(rg_declared_funcs, s.var_name, l2, c2);
        }
        !!! A stub has no body to call it from, so it is never "unused".
        if s.is_stub {
            rg_used_funcs = rg_set_add(rg_used_funcs, s.var_name);
        }
        !!! A declaration that kept no body, and the names a body was written for:
        !!! -W-nbody-func reports the first ones the program calls. Only the functions
        !!! of the file are recorded, not the methods of a type (the same guard the
        !!! declaration table above keeps).
        if rg_walk_struct_type == "" {
            if s.is_stub {
                rg_stub_decls = rg_posmap_set(rg_stub_decls, s.var_name, l2, c2);
            } else {
                rg_defined_funcs = rg_set_add(rg_defined_funcs, s.var_name);
            }
        }
        !!! A signature that names a struct mentions it, as a parameter or as the
        !!! result.
        @StrNode fp = s.fparam_struct;
        while fp != null {
            if fp.s != "" {
                rg_mark_struct_used(fp.s);
            }
            fp = fp.next;
        }
        if s.ret_struct != "" {
            rg_mark_struct_used(s.ret_struct);
        }
    } else if s.nk == ASSIGN || s.nk == INCR || s.nk == DREF_ASSIGN {
        rg_used_vars = rg_set_add(rg_used_vars, s.var_name);
        !!! A store that goes *through* the value reads it: what is written to is the
        !!! address the value holds (`p.next = r`, `a[i] = v`, `v[i][j] = x`,
        !!! `$p = v`). A plain `x = v` and an `x++` are writes and nothing more,
        !!! which is what -W-read-nused reports about.
        if s.nk == DREF_ASSIGN || s.assign_indices != null || s.is_index_ptr_store ||
           s.is_index_chain_store || s.is_array || s.member_name != "" ||
           s.member_chain != null {
            rg_read_vars = rg_set_add(rg_read_vars, s.var_name);
        }
        rg_mark_store_members(s);
    } else if s.nk == CALL_FUNC {
        rg_used_funcs = rg_set_add(rg_used_funcs, s.var_name);
        !!! A plain call, and not a method of a receiver: -W-nbody-func is about the
        !!! functions of the file, and a method shares the name space of the type it
        !!! belongs to.
        if !s.is_method_call {
            rg_called_funcs = rg_set_add(rg_called_funcs, s.var_name);
        }
    }
    rg_mark_used_expr(s.expr);
    rg_mark_used_expr(s.array_len_expr);
    @ExprNode a = s.args;
    while a != null {
        rg_mark_used_expr(a);
        a = a.next;
    }
    @ExprNode i = s.array_init;
    while i != null {
        rg_mark_used_expr(i);
        i = i.next;
    }
    @ExprNode e = s.case_exprs;
    while e != null {
        rg_mark_used_expr(e);
        e = e.next;
    }
    @ExprNode d = s.fparam_defaults;
    while d != null {
        rg_mark_used_expr(d);
        d = d.next;
    }
    @StmtNode cb = s.case_bodies;
    while cb != null {
        rg_mark_used_stmt(cb);
        cb = cb.next;
    }
    @StmtNode u = s.unmatch_body;
    while u != null {
        rg_mark_used_stmt(u);
        u = u.next;
    }
    @StmtNode t = s.true_body;
    while t != null {
        rg_mark_used_stmt(t);
        t = t.next;
    }
    @StmtNode f = s.false_body;
    while f != null {
        rg_mark_used_stmt(f);
        f = f.next;
    }
    !!! `for (auto* c : s->children) mark_used_stmt(c);` - the `children` list
    !!! does not exist in this implementation: a package's members and the body of a statement
    !!! are true_body (parser_package.b), which the loop above already walks.
    if is_func {
        rg_walk_var_types = saved_types;
        rg_walk_in_body = saved_in_body;
    }
}

!!! The keys of one table in the order the toolchain walks them. `declared_vars` and
!!! `declared_funcs` are name table's there, and the order a walk of one
!!! reads is not part of the standard. The warnings are therefore not emitted from
!!! the tables at all: `rgx_unused_before` puts them in the order the names are
!!! declared, which is an order both compilers can produce (the toolchain sorts the walk
!!! of its map by the same three keys).

!!! Whether the name (`al`, `ac`, `ak`) is declared before (`bl`, `bc`, `bk`): the
!!! preprocessed line, then the column, then the text of the name. str's `<`
!!! compares the bytes of the two names without a sign, which is what the `& 255`
!!! here gives.
bool rgx_unused_before -> int al, int ac, str ak, int bl, int bc, str bk {
    if al != bl {
        return al < bl;
    }
    if ac != bc {
        return ac < bc;
    }
    int i = 0;
    while ak[i] != (char)0 && bk[i] != (char)0 {
        int ca = (int)ak[i] & 255;
        int cb = (int)bk[i] & 255;
        if ca != cb {
            return ca < cb;
        }
        i = i + 1;
    }
    return (int)ak[i] == 0 && bk[i] != (char)0;
}

!!! Whether a name is one of the compiler's own generated functions: a method, a
!!! constructor or a destructor of a struct (`__m_long_add`, `__ctor_long_int`,
!!! `__dtor_long`). The front end writes them out of the struct's declaration and no
!!! source line names one, so "function '__ctor_long_int_int' never used" is a
!!! warning about a function that does not exist - `long a = 0x12345678;` got one for
!!! the two-int constructor of `long`. blang.b lists the same three prefixes to keep
!!! them out of a DLL's export table.
bool rgx_generated_name -> str n {
    if pe_matches(n, 0, "__m_") {
        return true;
    }
    if pe_matches(n, 0, "__ctor_") {
        return true;
    }
    if pe_matches(n, 0, "__asg_") {
        !!! The store helper an assignment written as an expression is lowered to.
        return true;
    }
    return pe_matches(n, 0, "__dtor_");
}

!!! One entry of the list the warnings come from.
type RgUnused {
    str key;
    int a;
    int b;
    @RgUnused next;
};

!!! `key` inserted where it belongs, so the list stays in declaration order. The
!!! tables hold a few dozen names and the list is built once per compile.
@RgUnused rgx_unused_insert -> @RgUnused list, str key, int a, int b {
    RgUnused proto;
    @RgUnused n;
    malloc(@n, size proto);
    n.key = key;
    n.a = a;
    n.b = b;
    n.next = null;
    if list == null || rgx_unused_before(a, b, key, list.a, list.b, list.key) {
        n.next = list;
        return n;
    }
    @RgUnused t = list;
    while t.next != null && !rgx_unused_before(a, b, key, t.next.a, t.next.b, t.next.key) {
        t = t.next;
    }
    n.next = t.next;
    t.next = n;
    return list;
}

!!! `shown`/`what` inserted where it belongs, so the struct warnings come out in the
!!! order the declarations stand in the file - the same three keys the names of the
!!! file are put in.
@RgStructWarn rgx_structwarn_insert -> @RgStructWarn list, str shown, str what,
                                       int a, int b, int hl {
    RgStructWarn proto;
    @RgStructWarn n;
    malloc(@n, size proto);
    n.shown = shown;
    n.what = what;
    n.a = a;
    n.b = b;
    n.hl = hl;
    n.next = null;
    if list == null || rgx_unused_before(a, b, shown, list.a, list.b, list.shown) {
        n.next = list;
        return n;
    }
    @RgStructWarn t = list;
    while t.next != null && !rgx_unused_before(a, b, shown, t.next.a, t.next.b, t.next.shown) {
        t = t.next;
    }
    n.next = t.next;
    t.next = n;
    return list;
}

!!! The parameters and the result of a declaration, which mention the structs they
!!! name.
void rgx_signature_uses -> @StmtNode fn {
    if fn == null {
        end;
    }
    @StrNode ps = fn.fparam_struct;
    while ps != null {
        if ps.s != "" {
            rg_mark_struct_used(ps.s);
        }
        ps = ps.next;
    }
    if fn.ret_struct != "" {
        rg_mark_struct_used(fn.ret_struct);
    }
}

!!! Every struct the program mentions, and the body of every method walked with the
!!! struct in hand: a bare name inside one of those bodies is a field of it.
void rg_collect_struct_uses {
    @StructDef d = p_struct_defs;
    while d != null {
        !!! A base is named by the declaration that derives from it, a field type by
        !!! the struct that holds it: both are mentions of those structs.
        @StrNode b = d.bases;
        while b != null {
            if b.s != "" {
                rg_mark_struct_used(b.s);
            }
            b = b.next;
        }
        !!! The struct's own name is not a mention: a definition is not a use.
        @StructField f = d.fields;
        while f != null {
            if f.struct_type != "" {
                rg_mark_struct_used(f.struct_type);
            }
            f = f.next;
        }
        !!! init and destruct run with the instance they belong to, so a field they
        !!! read is read whatever else the program does with the type.
        rgx_signature_uses(d.init_func);
        rgx_signature_uses(d.destruct_func);
        @StructMethod m = d.methods;
        while m != null {
            if m.fn != null {
                rgx_signature_uses(m.fn);
                !!! The body is walked under this struct, so a bare field name in it
                !!! resolves to a member of this struct (or of a base of it), and
                !!! under this method, so a read only a method nothing calls performs
                !!! can be told from a read a live one does.
                str saved = rg_walk_struct_type;
                str saved_m = rg_walk_struct_method;
                rg_walk_struct_type = d.name;
                rg_walk_struct_method = rgx_member_key(d.name, m.name);
                rg_mark_used_stmt(m.fn);
                rg_walk_struct_type = saved;
                rg_walk_struct_method = saved_m;
            }
            m = m.next;
        }
        str saved2 = rg_walk_struct_type;
        str saved_m2 = rg_walk_struct_method;
        rg_walk_struct_type = d.name;
        rg_walk_struct_method = "";
        if d.init_func != null {
            rg_mark_used_stmt(d.init_func);
        }
        if d.destruct_func != null {
            rg_mark_used_stmt(d.destruct_func);
        }
        rg_walk_struct_type = saved2;
        rg_walk_struct_method = saved_m2;
        d = d.next;
    }
    !!! The reads that stood in a method body: they count when the method is one the
    !!! program reaches. Every call, every operator rewrite and every implicit form
    !!! went through rg_resolve_method_func, so the set is complete by now.
    @RgPendingRead pr = rg_pending_member_reads;
    while pr != null {
        if rg_set_has(rg_method_used, pr.method) {
            rg_member_read = rg_set_add(rg_member_read, pr.member);
        }
        pr = pr.next;
    }
    rg_pending_member_reads = null;
}

!!! The name a method is shown under: its own name, an operator by its symbol, a
!!! converting constructor as the type it builds from. The versions of a `reload`
!!! method share the name the source spells, so the parameter list is what tells one
!!! warning from the next.
str rgx_method_display -> str ty, @StructMethod m {
    str n = m.name;
    if m.op != "" {
        if p_text_eq(m.op, "init") {
            n = "init " + m.ctor_from;
        } else {
            n = "operator " + m.op;
        }
    } else if m.fn != null && !p_text_eq(m.fn.var_name, m.name) {
        n = n + "(" + rg_overload_signature(m.fn) + ")";
    }
    return ty + "." + n;
}

!!! -W-nused-struct / -W-read-nused-struct: the structs nothing mentions, the members
!!! nothing reads or writes and the methods nothing calls, and the members that are
!!! written and whose value is never read.
void rg_check_struct_unused {
    if !rg_warn_unused_struct && !rg_warn_read_unused_struct {
        end;
    }
    !!! The field names some struct is used and read through a `(@Y)` view of. A
    !!! struct handed out as `@void` shares its layout with that view, so one of its
    !!! fields of the same name is the same memory.
    @RgStrSet view_used = null;
    @RgStrSet view_read = null;
    @RgStrSet vs = rg_view_structs;
    while vs != null {
        @StructDef vd = p_find_struct(vs.key);
        if vd != null {
            @StructField vf = vd.fields;
            while vf != null {
                if rgx_member_used(vs.key, vf.name) {
                    view_used = rg_set_add(view_used, vf.name);
                }
                if rgx_member_read(vs.key, vf.name) {
                    view_read = rg_set_add(view_read, vf.name);
                }
                vf = vf.next;
            }
        }
        vs = vs.next;
    }
    @RgStructWarn recs = null;
    @StructDef d = p_struct_defs;
    while d != null {
        !!! A concrete struct cloned out of a template is one instantiation of one
        !!! generic body: a member it does not use here may be what another
        !!! instantiation is for, so the generic body is not reported per clone.
        bool is_clone = rg_set_has(rg_struct_tmpl_done, d.name);
        if !is_clone && !rg_set_has(rg_used_structs, d.name) {
            !!! Nothing mentions the struct at all. Its members and its methods are
            !!! not reported one by one: they are dead with it, and a library type
            !!! would fill the output with them.
            if rg_warn_unused_struct {
                int nl = d.name_line;
                if nl == 0 {
                    nl = d.line;
                }
                int nc = d.name_col;
                if nc == 0 {
                    nc = d.col;
                }
                recs = rgx_structwarn_insert(recs, d.name, "struct", nl, nc,
                                             pe_len(d.name));
            }
        } else if !is_clone && !attr_has_effect(d.name, ATTR_EFFECT_USED) {
            !!! The layout is shared with the view types when the struct is ever
            !!! handed out as an opaque pointer.
            bool shared = rg_set_has(rg_cast_out_structs, d.name);
            @StructField f = d.fields;
            while f != null {
                bool f_used = rgx_member_used(d.name, f.name);
                bool f_read = rgx_member_read(d.name, f.name);
                if shared {
                    if rg_set_has(view_used, f.name) {
                        f_used = true;
                    }
                    if rg_set_has(view_read, f.name) {
                        f_read = true;
                    }
                }
                int fl = f.line;
                if fl == 0 {
                    fl = d.line;
                }
                int fc = f.col;
                if fc == 0 {
                    fc = d.col;
                }
                if !f_used {
                    if rg_warn_unused_struct {
                        recs = rgx_structwarn_insert(recs, d.name + "." + f.name,
                                                     "member", fl, fc, pe_len(f.name));
                    }
                } else if rg_warn_read_unused_struct && !f_read {
                    recs = rgx_structwarn_insert(recs, d.name + "." + f.name,
                                                 "member-read", fl, fc, pe_len(f.name));
                }
                f = f.next;
            }
            if rg_warn_unused_struct {
                @StructMethod m = d.methods;
                while m != null {
                    !!! A stub has no body, and a body-less `operator ==` is the
                    !!! prototype the compiler synthesizes the comparisons of the
                    !!! derived types from: neither is a method the source could call.
                    if m.fn == null || m.fn.is_stub || m.fn.synth_op != "" {
                        m = m.next;
                        continue;
                    }
                    !!! A converting constructor is reached through the wrapper the
                    !!! compiler writes for it (`__ctor_S_int`), not by its own name:
                    !!! the wrapper exists for every one of them, so only a call of
                    !!! the wrapper means a conversion site used this constructor.
                    !!! Any other method is used when the lookup reached it, and the
                    !!! internal name is what tells the versions of a `reload` method
                    !!! apart.
                    bool used;
                    if m.ctor_func != "" {
                        used = rg_set_has(rg_used_funcs, m.ctor_func);
                    } else {
                        used = rg_set_has(rg_method_used,
                                          rgx_member_key(d.name, m.fn.var_name));
                    }
                    if !used {
                        str shown = rgx_method_display(d.name, m);
                        int ml = m.fn.var_line;
                        if ml == 0 {
                            ml = m.fn.line;
                        }
                        int mc = m.fn.var_col;
                        if mc == 0 {
                            mc = m.fn.col;
                        }
                        int hl = pe_len(m.name);
                        if m.op != "" {
                            if p_text_eq(m.op, "init") {
                                hl = 4;
                            } else {
                                hl = pe_len(m.op);
                            }
                        }
                        recs = rgx_structwarn_insert(recs, shown, "method", ml, mc, hl);
                    }
                    m = m.next;
                }
            }
        }
        d = d.next;
    }
    str esc2 = char_text((char)27);
    str B2 = esc2 + "[1m";
    str R2 = esc2 + "[0m";
    @RgStructWarn r = recs;
    while r != null {
        str msg;
        if p_text_eq(r.what, "struct") {
            msg = "struct '" + B2 + r.shown + R2 + "' never used";
        } else if p_text_eq(r.what, "method") {
            msg = "method '" + B2 + r.shown + R2 + "' never used";
        } else {
            msg = "member '" + B2 + r.shown + R2 + "'";
            if p_text_eq(r.what, "member") {
                msg = msg + " never used";
            } else {
                msg = msg + " never read";
            }
        }
        int hl2 = r.hl;
        if hl2 <= 0 {
            hl2 = 1;
        }
        rg_fmt_warn(r.a, r.b, msg, hl2);
        r = r.next;
    }
}

!!! check_unused: one warning for every declared name nothing used. Entry points are
!!! implicitly used. A declaration in a `#head` file is reported like any other: it
!!! used to be skipped, on the grounds that including a library is not a promise to
!!! call every function it offers - but the modules of a program written in blang are
!!! `#head` files too, and the self-hosted compiler's own sources went unwarned while
!!! the toolchain ones did not.
!!!
!!! -W-read-nused adds the toolchain "set but not used": a name that is written and whose
!!! value is never read. A name that is never used at all is never read either, so
!!! one warning is enough for it, and the message says which of the two it is.
!!! -W-nbody-func: a function the program calls whose declaration kept no body, and
!!! no definition of it follows anywhere. The backend reaches it as an undefined
!!! reference in the temporary .r - a position the reader has to map back by hand - so
!!! the warning says it here, where the declaration stands.
void rg_check_no_body_func {
    if !rg_warn_nbody_func {
        end;
    }
    @RgUnused recs = null;
    @RgPosMap sd = rg_stub_decls;
    while sd != null {
        !!! A name a body was written for is defined, however the declaration spelled
        !!! it; one the program imports from a DLL is not empty at all.
        if !rg_set_has(rg_defined_funcs, sd.key) && !rg_set_has(rg_extern_funcs, sd.key) &&
           rg_set_has(rg_called_funcs, sd.key) {
            recs = rgx_unused_insert(recs, sd.key, sd.a, sd.b);
        }
        sd = sd.next;
    }
    str esc3 = char_text((char)27);
    str B3 = esc3 + "[1m";
    str R3 = esc3 + "[0m";
    @RgUnused r = recs;
    while r != null {
        str shown = rg_display_name(r.key);
        str msg = "empty body for function '" + B3 + shown + R3 + "'";
        rg_fmt_warn(r.a, r.b, msg, pe_len(shown));
        r = r.next;
    }
}

!!! `attribute <object>: USED` (or `READ`) says a name is used, or that its value is
!!! read, whatever the rest of the file does with it. The name is put in the same
!!! tables the warnings come from - the three of them, because which one the object
!!! belongs to is decided by the tables the warning itself reads, and a name in a
!!! table it is not reported from costs nothing. the toolchain
!!! `RGenerator::apply_attributes` is the same step; what it reports about the
!!! object of a use is made by rg_apply_attr_checks (rgen_declare.b).
void rg_apply_attr_used {
    @AttrUse u = attr_uses;
    while u != null {
        !!! An attribute whose object is declared after it was reported and is not
        !!! applied (see attr_is_skipped): the toolchain never reaches the part of
        !!! apply_attributes that marks a name.
        if attr_is_skipped(u.line, u.col) {
            u = u.next;
            continue;
        }
        bool marks = attr_has_effect(u.object, ATTR_EFFECT_USED) ||
                     attr_has_effect(u.object, ATTR_EFFECT_READ);
        if u.member != "" {
            !!! A member of a struct: `S.f` (a field) or `S.m` (a method). Both kinds
            !!! live in the member tables, which are keyed the way the toolchain keys them
            !!! (`S` + '\x01' + `f`). Whether the struct exists is checked with the
            !!! other diagnostics of the attributes, by rg_apply_attr_checks.
            if marks && p_find_struct(u.owner) != null {
                rg_used_members = rg_set_add(rg_used_members, rgx_member_key(u.owner, u.member));
                if attr_has_effect(u.object, ATTR_EFFECT_READ) {
                    rg_member_read = rg_set_add(rg_member_read, rgx_member_key(u.owner, u.member));
                }
            }
        } else {
            !!! `pkg::f` is stored as `pkg__f`: the tables the warnings read hold the
            !!! internal spelling, while the toolchain matches the name the reader sees
            !!! (`display_name`). A name in a table it does not belong to costs
            !!! nothing, and a name nothing declares was reported when the
            !!! attributes were checked.
            str mark_name = attr_table_name(u.object, u.scoped);
            if marks {
                rg_used_vars = rg_set_add(rg_used_vars, mark_name);
                rg_used_funcs = rg_set_add(rg_used_funcs, mark_name);
                rg_used_structs = rg_set_add(rg_used_structs, mark_name);
                if attr_has_effect(u.object, ATTR_EFFECT_READ) {
                    rg_read_vars = rg_set_add(rg_read_vars, mark_name);
                }
            }
        }
        u = u.next;
    }
}

void rg_check_unused {
    rg_apply_attr_used();
    if !rg_warn_unused && !rg_warn_read_unused && !rg_warn_unused_struct &&
       !rg_warn_read_unused_struct && !rg_warn_nbody_func {
        end;
    }
    rg_used_funcs = rg_set_add(rg_used_funcs, "main");
    rg_used_funcs = rg_set_add(rg_used_funcs, "WinMain");
    rg_used_funcs = rg_set_add(rg_used_funcs, "DllMain");

    @StmtNode s = rg_stmts;
    while s != null {
        rg_mark_used_stmt(s);
        s = s.next;
    }
    rg_collect_struct_uses();

    !!! `const char* B = "\033[1m"; const char* R = "\033[0m";`
    str esc = char_text((char)27);
    str B = esc + "[1m";
    str R = esc + "[0m";
    !!! The names nothing used, each table put in declaration order (the toolchain sorts
    !!! the walk of its unordered_map by the same keys).
    @RgUnused uv = null;
    @RgPosMap dv = rg_declared_vars;
    while dv != null {
        if !rg_set_has(rg_used_vars, dv.key) {
            if rg_warn_unused {
                uv = rgx_unused_insert(uv, dv.key, dv.a, dv.b);
            } else if rg_warn_read_unused {
                uv = rgx_unused_insert(uv, dv.key, dv.a, dv.b);
            }
        } else if rg_warn_read_unused && !rg_set_has(rg_read_vars, dv.key) {
            uv = rgx_unused_insert(uv, dv.key, dv.a, dv.b);
        }
        dv = dv.next;
    }
    @RgUnused uf = null;
    @RgPosMap df = rg_declared_funcs;
    while df != null {
        if rg_warn_unused && !rg_set_has(rg_used_funcs, df.key) && !rgx_generated_name(df.key) {
            uf = rgx_unused_insert(uf, df.key, df.a, df.b);
        }
        df = df.next;
    }
    @RgUnused u = uv;
    while u != null {
        !!! A package member is stored as `mypkg__a`; the warning must name it the
        !!! way the source did. A name nothing used says so; one that is written and
        !!! never read says that instead.
        str shown = rg_display_name(u.key);
        str what = " never used";
        if rg_set_has(rg_used_vars, u.key) {
            what = " never read";
        } else if !rg_warn_unused {
            what = " never read";
        }
        str msg = "identifier '" + B + shown + R + "'" + what;
        rg_fmt_warn(u.a, u.b, msg, pe_len(shown));
        u = u.next;
    }
    @RgUnused v = uf;
    while v != null {
        str shown2 = rg_display_name(v.key);
        str msg2 = "function '" + B + shown2 + R + "' never used";
        rg_fmt_warn(v.a, v.b, msg2, pe_len(shown2));
        v = v.next;
    }

    !!! The struct warnings come after the variable and function ones: the flags are
    !!! separate, and a run that turns on both reads the names of the file first and
    !!! the members of its types after them.
    rg_check_struct_unused();
    rg_check_no_body_func();
}
