#once
!~
 ~  bootstrap/frontend/rgen_resolve_index.b: this implementation of
 ~
 ~  How a subscript is typed. resolve_array_access() covers `s[0]` on a str, an
 ~  inline array or a pointer variable (`p[i]` is the pointee), an element of an
 ~  array field of `this` inside a method body, and the block a pointer field of
 ~  the enclosing method's struct holds. resolve_field_elem() covers the elements of
 ~  an inline array field (`o.data[i]`, `o.m[i][j]`), where the indices of a
 ~  multi-dimensional access are one chain and the check runs once for the whole
 ~  access.
 ~!

#head "rgen"

!!! resolve_array_access(): the type of `name[...]`.
bool rg_resolve_array_access -> @ExprNode n {
    !!! `n->indices.size() > 1`: ast.b keeps only the multi-index shape in
    !!! `indices` (a single index lives in `left`, which is the shape the parser
    !!! builds), so a non-null chain is two indices or more.
    if n.indices != null {
        @ExprNode idx = n.indices;
        while idx != null {
            rg_resolve_expr_type(idx);
            rg_check_int_index(idx, "index");
            idx = idx.next;
        }
    } else {
        rg_resolve_expr_type(n.left);
        if n.left != null {
            rg_check_int_index(n.left, "index");
        }
    }
    !!! `data[i]` / `data[i][j]` inside a method body: an array field of `this` (a
    !!! local array of the same name wins, and is handled below).
    rg_emit_this_field_elem_node_out = "";
    rg_emit_this_field_elem_node_out_field = null;
    if rg_emit_this_field_elem_node(n) {
        @StructField ff = rg_emit_this_field_elem_node_out_field;
        if ff != null {
            if ff.struct_type != "" && !ff.struct_ptr {
                n.result_type = INT;
                n.struct_type = ff.struct_type;
            } else {
                n.result_type = rg_field_eff_type(ff);
                n.struct_type = "";
            }
            return true;
        }
    }
    !!! `data[i]` where `data` is a pointer field of the enclosing method's struct
    !!! (`@T data`, `@int data`): the element is the object the pointer at
    !!! `data + i * step` names. Without this the name was looked up as a variable
    !!! and reported undeclared, which is what a generic container's own body ran
    !!! into (its block is a field).
    rg_method_field_block_info_out_struct_type = "";
    rg_method_field_block_info_out_step = 0;
    if rg_method_field_block_info(n.var_name) {
        str bt = rg_method_field_block_info_out_struct_type;
        if bt != "" {
            n.result_type = INT;
            !!! a struct element is that struct value.
            n.struct_type = bt;
        } else {
            @StructField f = rg_resolve_field(rg_struct_method_type, n.var_name, true);
            if f != null {
                if f.struct_ptr {
                    n.result_type = rg_deref_of(rg_field_eff_type(f));
                } else {
                    n.result_type = rg_deref_of(f.ty);
                }
            } else {
                n.result_type = INT;
            }
            n.struct_type = "";
        }
        return true;
    }
    !!! The array the subscript applies to, as this scope declares it.
    if rg_effective_var_decl(n.var_name) {
        @VarDecl d = rg_effective_var_decl_out;
        !!! String indexing: s[0] -> char.
        if d.ty == STR && !d.is_array {
            n.result_type = CHAR;
        } else if d.is_array {
            !!! An inline array gives its element type; a pointer (`@int p`, and
            !!! `@longlong` too, which sits outside the contiguous AT_* block)
            !!! gives what it points at, so `p[0]` is a value and not a pointer.
            n.result_type = d.ty;
        } else {
            n.result_type = rg_deref_of(d.ty);
        }
        !!! An element of a struct array denotes a struct value, so a call has to
        !!! pass its address (`showInner(arr[i])`).
        if d.is_array && d.struct_type != "" {
            n.struct_type = d.struct_type;
        }
    } else {
        str c = rg_closest_symbol(n.var_name);
        str msg = "undeclared identifier '" + n.var_name + "'";
        if c != "" {
            msg = msg + "; did you mean '" + c + "'?";
        }
        !!! fmt_err(n->line, n->col, msg, (int)n->var_name.size(), c.empty() ?
        !!! nullptr : c, c.empty() ? 0 : n->col, false).
        if c == "" {
            rg_fmt_err(n.line, n.col, msg, pe_len(n.var_name), (str)null, 0, false);
        } else {
            rg_fmt_err(n.line, n.col, msg, pe_len(n.var_name), c, n.col, false);
        }
        !!! fallback.
        n.result_type = INT;
        return false;
    }
    return true;
}

!!! resolve_field_elem(): `o.data[i]`, `o.m[i][j]` / `o.people[i]`: type check and
!!! element type. The nested element nodes of a multi-dimensional access are
!!! flattened, so the check runs once for the whole access.
bool rg_resolve_field_elem -> @ExprNode n {
    n.result_type = INT;
    !!! Collect the indices of this access and resolve them; the inner element
    !!! nodes of a multi-dimensional access are part of this chain, not separate
    !!! expressions. the toolchain collects them outermost first and reverses the vector;
    !!! the chain here is built by putting each one in front, which gives the same
    !!! order.
    @RgExprRef idx = null;
    int idx_n = 0;
    @ExprNode base = n;
    while base != null && base.nk == FIELD_ELEM {
        if base.right != null {
            RgExprRef proto;
            @RgExprRef node;
            malloc(@node, size proto);
            node.e = base.right;
            node.next = idx;
            idx = node;
            idx_n = idx_n + 1;
        }
        base = base.left;
    }
    @RgExprRef ie = idx;
    while ie != null {
        rg_resolve_expr_type(ie.e);
        if !rg_check_int_index(ie.e, "index") {
            rg_has_errors = true;
        }
        ie = ie.next;
    }
    @StructField f = null;
    !!! `c.data[i]` / `o.in.data[i]`: the block is the pointer field the chain
    !!! before the index ends in, so the element is what that pointer points at - a
    !!! struct value when the field is `@T`, a builtin when it is `@int`. The array
    !!! path below only knows inline array fields.
    if base != null && base.nk == MEMBER_ACCESS {
        rg_member_chain_block_info_out_base = "";
        rg_member_chain_block_info_out_struct = "";
        rg_member_chain_block_info_out_step = 0;
        rg_member_chain_block_info_out_elem = INT;
        if rg_member_chain_block_info(base) {
            str elem_struct = rg_member_chain_block_info_out_struct;
            if elem_struct != "" {
                n.result_type = INT;
                n.struct_type = elem_struct;
            } else {
                n.result_type = rg_member_chain_block_info_out_elem;
                n.struct_type = "";
            }
            return true;
        }
    }
    bool rb = false;
    if base != null {
        rg_resolve_array_base_out_field = null;
        rg_resolve_array_base_out_addr = "";
        rb = rg_resolve_array_base(base, false);
        f = rg_resolve_array_base_out_field;
    }
    if base == null || !rb || f == null {
        !!! A char array field is stored as a str, so its elements have no address;
        !!! explain that instead of a generic "not an array".
        @StructField cf = null;
        bool cb = false;
        if base != null {
            rg_resolve_array_base_out_field = null;
            rg_resolve_array_base_out_addr = "";
            cb = rg_resolve_array_base(base, true);
            cf = rg_resolve_array_base_out_field;
        }
        if base != null && cb && cf != null && cf.ty == CHAR {
            str msgc = "char array field '" + cf.name +
                       "' is stored as a str and cannot be indexed element by element";
            rg_fmt_err(n.line, n.col, msgc, n.tok_len, (str)null, 0, false);
            rg_has_errors = true;
            return false;
        }
        str what = "";
        if base != null && base.nk == MEMBER_ACCESS {
            what = base.member_name;
        }
        str msg = "";
        if what == "" {
            msg = "element access needs an array field";
        } else {
            msg = "field '" + what + "' is not an array";
        }
        rg_fmt_err(n.line, n.col, msg, n.tok_len, (str)null, 0, false);
        rg_has_errors = true;
        return false;
    }
    !!! `f->dims` is the declared dimension count of the field, as a chain here.
    int want_n = 0;
    @IntNode dn = f.dims;
    while dn != null {
        want_n = want_n + 1;
        dn = dn.next;
    }
    if f.dims != null && idx_n != want_n {
        str msg2 = "array field '" + f.name + "' needs " + (str)want_n +
                   " index(es), got " + (str)idx_n;
        rg_fmt_err(n.line, n.col, msg2, n.tok_len, (str)null, 0, false);
        rg_has_errors = true;
        return false;
    }
    VarType elem_type = INT;
    str elem_struct2 = "";
    if f.struct_type != "" {
        !!! A struct element is a value (its "value" is its address); an element
        !!! declared `@T` is a pointer, so its members are reached through it.
        if f.struct_ptr {
            elem_type = AT_INT;
        } else {
            elem_type = INT;
        }
        elem_struct2 = f.struct_type;
    } else {
        elem_type = rg_field_eff_type(f);
    }
    !!! Give every node of the chain the element type, so an outer field or method
    !!! access sees the right one.
    @ExprNode cnode = n;
    while cnode != null && cnode.nk == FIELD_ELEM {
        cnode.result_type = elem_type;
        cnode.struct_type = elem_struct2;
        cnode = cnode.left;
    }
    return true;
}
