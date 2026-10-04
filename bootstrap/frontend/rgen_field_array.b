#once
!~
 ~  bootstrap/frontend/rgen_field_array.b: this implementation of
 ~  - the inline array struct fields (`int data[N]`):
 ~  layout lookup, element addresses, reads and the stores into one element.
 ~
 ~  An inline array field is not a pointer: its elements sit inside the struct, so
 ~  the address of one element is the address of the array plus the row-major linear
 ~  index times the element size. The byte offset goes through an `@void` cast so the
 ~  backend adds bytes instead of scaling by the pointee size. A heap array of a
 ~  local (`int a[3]`) is not a field and keeps the ordinary `var{index}` path, which
 ~  is what every `is_array` test here is about.
 ~
 ~  the `static bool split_field_elem` is a function here too; the `dims` and
 ~  `idx` vectors are chains (IntNode and ExprNode), and every `str& out` or
 ~  `const StructField**` parameter is the global rgen.b declares for it.
 ~!

#head "rgen"
stub @StrNode rgx_reverse_str -> @StrNode head;
stub int rgx_expr_count -> @ExprNode head;

!!! One expression emitted into a piece of its own, so it can be embedded in a
!!! larger .r expression (an element address needs the index text inline).
!!! The piece is taken as a slice of the buffer between two marks (rgen_out.b) and
!!! the buffer is cut back to the first of them: the toolchain copies the whole text,
!!! empties the buffer and assigns the copy back, which costs everything emitted so
!!! far for every expression captured.
str rg_capture_rc_expr -> @ExprNode n {
    int mark = rgx_out_mark();
    rg_rc_expr(n);
    str out = rgx_out_slice(mark);
    rgx_out_cut(mark);
    return out;
}

!!! The array an element expression indexes, plus the `.r` address of its first
!!! element. Handles `o.data` (a field of a struct variable) and `data` (a field of
!!! the enclosing method's struct). A heap array of a local is not a field, so this
!!! answers false and the ordinary `var{index}` path handles it.
bool rg_resolve_array_base -> @ExprNode base, bool allow_char {
    rg_resolve_array_base_out_field = null;
    rg_resolve_array_base_out_addr = "";
    if base == null {
        return false;
    }
    if base.nk == VAR_REF {
        @RgBoolMap ait = rg_boolmap_find(rg_sym_is_array, base.var_name);
        if ait != null && ait.v {
            return false;
        }
        if rg_vartypemap_find(rg_syms, base.var_name) != null {
            return false;
        }
        if rg_struct_method_var == "" {
            return false;
        }
        rg_resolve_field_out_decl_type = "";
        @StructField f = rg_resolve_field(rg_struct_method_type, base.var_name, true);
        if f == null || f.array_dim <= 0 || (!allow_char && f.ty == CHAR) {
            return false;
        }
        str dt = rg_resolve_field_out_decl_type;
        int off = rg_field_offset_of(rg_struct_method_type, base.var_name, dt);
        if off < 0 {
            return false;
        }
        if off != 0 {
            rg_resolve_array_base_out_addr = "((@void " + rg_struct_method_var + ") , " +
                                             (str)off + " , +)";
        } else {
            rg_resolve_array_base_out_addr = rg_struct_method_var;
        }
        rg_resolve_array_base_out_field = f;
        return true;
    }
    if base.nk != MEMBER_ACCESS {
        return false;
    }
    @ExprNode root = base;
    while root.nk == MEMBER_ACCESS && root.left != null {
        root = root.left;
    }
    if root == null || root.nk != VAR_REF {
        return false;
    }
    !!! The member names from the root outwards: the chain is built from the
    !!! outermost member back to the root, so it is reversed.
    @StrNode chain = null;
    @ExprNode c = base;
    while c != null && c.nk == MEMBER_ACCESS {
        chain = rg_strchain_append(chain, c.member_name);
        c = c.left;
    }
    chain = rgx_reverse_str(chain);
    str root_type = rg_struct_type_in_effect(root.var_name);
    if root_type == "" {
        return false;
    }
    rg_resolve_field_chain_out_leaf = null;
    rg_resolve_field_chain_out_abs_off = 0;
    if !rg_resolve_field_chain(root_type, chain, base.line, base.col) {
        return false;
    }
    @StructField leaf = rg_resolve_field_chain_out_leaf;
    if leaf == null || leaf.array_dim <= 0 || (!allow_char && leaf.ty == CHAR) {
        return false;
    }
    rg_emit_field_chain_address_out = "";
    if !rg_emit_field_chain_address(root.var_name, root_type, chain) {
        return false;
    }
    rg_resolve_array_base_out_addr = rg_emit_field_chain_address_out;
    rg_resolve_array_base_out_field = leaf;
    return true;
}

!!! reverse over a chain of names, and over a chain of expressions: the walk
!!! that collects them produces the outermost member first, and resolve_field_chain
!!! reads a member list from the base out. The nodes are relinked in place, so
!!! nothing is allocated and no node keeps its old link. Appending every name in the
!!! order it was read - which is what stood here - left the order alone, and a chain
!!! through a struct pointer field came out with its two offsets swapped.
@StrNode rgx_reverse_str -> @StrNode head {
    @StrNode out = null;
    @StrNode e = head;
    while e != null {
        @StrNode nx = e.next;
        e.next = out;
        out = e;
        e = nx;
    }
    return out;
}

@ExprNode rgx_reverse_expr -> @ExprNode head {
    @ExprNode out = null;
    @ExprNode e = head;
    while e != null {
        @ExprNode nx = e.next;
        e.next = out;
        out = e;
        e = nx;
    }
    return out;
}

int rgx_int_at -> @IntNode head, int i {
    int k = 0;
    @IntNode e = head;
    while e != null {
        if k == i {
            return e.v;
        }
        k = k + 1;
        e = e.next;
    }
    return 0;
}

int rgx_int_n -> @IntNode head {
    int n = 0;
    @IntNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

!!! Row-major linear index for a multi-dimensional element access:
!!! `m[i][j]` of `int m[2][3]` becomes `((i, 3, *), j, +)`.
str rg_field_linear_index -> @IntNode dims, @ExprNode idx {
    str flat = rg_capture_rc_expr(idx);
    int k = 1;
    @ExprNode e = idx;
    if e != null {
        e = e.next;
    }
    while e != null {
        int d = 1;
        if k < rgx_int_n(dims) {
            int dv = rgx_int_at(dims, k);
            if dv > 0 {
                d = dv;
            }
        }
        flat = "((" + flat + " , " + (str)d + " , *) , " + rg_capture_rc_expr(e) + " , +)";
        k = k + 1;
        e = e.next;
    }
    return flat;
}

!!! Address of one element of `field`: the array start plus the (row-major) linear
!!! index times the element size.
str rg_field_elem_address_of -> str arr, @StructField f, @ExprNode idx {
    int es = rg_field_elem_size(f);
    if es <= 0 {
        es = 1;
    }
    return "((@void " + arr + ") , (" + rg_field_linear_index(f.dims, idx) + " , " +
           (str)es + " , *) , +)";
}

!!! Split `o.m[i][j]` into the array it indexes and the index expressions, in order.
!!! Nested element nodes (one per dimension) are flattened. The base is left in
!!! rgx_split_base and the indices in rgx_split_idx.
@ExprNode rgx_split_base;
@ExprNode rgx_split_idx;

bool rgx_split_field_elem -> @ExprNode n {
    rgx_split_idx = null;
    @ExprNode cnode = n;
    while cnode != null && cnode.nk == FIELD_ELEM {
        if cnode.right == null {
            return false;
        }
        rgx_split_idx = p_chain_expr(rgx_split_idx, cnode.right);
        cnode = cnode.left;
    }
    rgx_split_idx = rgx_reverse_expr(rgx_split_idx);
    rgx_split_base = cnode;
    if rgx_split_base == null || rgx_split_idx == null {
        return false;
    }
    return true;
}

bool rg_emit_field_elem_address -> @ExprNode n {
    rg_emit_field_elem_address_out = "";
    rg_emit_field_elem_address_out_field = null;
    if n == null || n.nk != FIELD_ELEM {
        return false;
    }
    if !rgx_split_field_elem(n) {
        return false;
    }
    @ExprNode base = rgx_split_base;
    @ExprNode idx = rgx_split_idx;
    rg_resolve_array_base_out_field = null;
    rg_resolve_array_base_out_addr = "";
    if !rg_resolve_array_base(base, false) {
        return false;
    }
    @StructField f = rg_resolve_array_base_out_field;
    rg_emit_field_elem_address_out = rg_field_elem_address_of(rg_resolve_array_base_out_addr, f, idx);
    rg_emit_field_elem_address_out_field = f;
    return true;
}

!!! `data[i][j]` inside a method body, where `data` is an array field of `this`.
bool rg_emit_this_field_elem_list -> str name, @ExprNode idx {
    rg_emit_this_field_elem_list_out = "";
    rg_emit_this_field_elem_list_out_field = null;
    if idx == null {
        return false;
    }
    @RgBoolMap ait = rg_boolmap_find(rg_sym_is_array, name);
    if ait != null && ait.v {
        !!! A local array wins over the field.
        return false;
    }
    if rg_vartypemap_find(rg_syms, name) != null {
        return false;
    }
    if rg_set_has(rg_method_locals, name) {
        return false;
    }
    if rg_struct_method_var == "" {
        return false;
    }
    rg_resolve_field_out_decl_type = "";
    @StructField f = rg_resolve_field(rg_struct_method_type, name, true);
    if f == null || f.array_dim <= 0 || f.ty == CHAR {
        return false;
    }
    str dt = rg_resolve_field_out_decl_type;
    int off = rg_field_offset_of(rg_struct_method_type, name, dt);
    if off < 0 {
        return false;
    }
    str arr = rg_struct_method_var;
    if off != 0 {
        arr = "((@void " + rg_struct_method_var + ") , " + (str)off + " , +)";
    }
    rg_emit_this_field_elem_list_out = rg_field_elem_address_of(arr, f, idx);
    rg_emit_this_field_elem_list_out_field = f;
    return true;
}

bool rg_emit_this_field_elem_index -> str name, @ExprNode index {
    if index == null {
        return false;
    }
    !!! One index is a list of one: the list version does the work, and its answer is
    !!! read from the globals of the list version by the caller below.
    return rg_emit_this_field_elem_list(name, index);
}

bool rg_emit_this_field_elem_node -> @ExprNode n {
    if n == null || n.nk != ARRAY_ACCESS {
        return false;
    }
    !!! A multi-dimensional access keeps its indices in `indices`, a single one in
    !!! `left`.
    bool ok = false;
    if n.indices != null {
        ok = rg_emit_this_field_elem_list(n.var_name, n.indices);
    } else {
        ok = rg_emit_this_field_elem_index(n.var_name, n.left);
    }
    if !ok {
        return false;
    }
    rg_emit_this_field_elem_node_out = rg_emit_this_field_elem_list_out;
    rg_emit_this_field_elem_node_out_field = rg_emit_this_field_elem_list_out_field;
    return true;
}

!!! `.r` address of an lvalue: a variable, a field chain, a field of the enclosing
!!! method's struct, or an array element (including a field of one).
bool rg_emit_lvalue_address -> @ExprNode n {
    rg_emit_lvalue_address_out = "";
    if n == null {
        return false;
    }
    if n.nk == FIELD_ELEM {
        !!! An element of a block a field holds, reached through a member chain
        !!! (`c.data[i]`): the block is the pointer that chain ends in.
        rg_pointer_field_elem_address_out = "";
        rg_pointer_field_elem_address_out_struct = "";
        if rg_pointer_field_elem_address(n) {
            rg_emit_lvalue_address_out = rg_pointer_field_elem_address_out;
            return true;
        }
        !!! the toolchain hands `emit_field_elem_address` the caller's own `out` string and
        !!! the helper writes into it; here each helper has an out global of its own,
        !!! so the address has to be carried over. Without it the answer was true with
        !!! an empty address, and every reader built its text out of that empty string
        !!! (`o.people[i].name` emitted no expression at all, which the reader of the
        !!! .r then reported as a malformed one).
        rg_emit_field_elem_address_out = "";
        rg_emit_field_elem_address_out_field = null;
        if !rg_emit_field_elem_address(n) {
            return false;
        }
        rg_emit_lvalue_address_out = rg_emit_field_elem_address_out;
        return true;
    }
    if n.nk == ARRAY_ACCESS {
        !!! `p[i]` where p is a `@T`: the element's address, scaled by the layout size
        !!! of the struct. This is also what `@p[i]` needs, which is how a block of
        !!! pooled nodes is reached.
        rg_pointer_element_address_out = "";
        if rg_pointer_element_address(n) {
            rg_emit_lvalue_address_out = rg_pointer_element_address_out;
            return true;
        }
        !!! An element of an inline array field of the enclosing method's struct
        !!! (`people[0]` inside a method body, where `people` is a field).
        rg_emit_this_field_elem_node_out = "";
        rg_emit_this_field_elem_node_out_field = null;
        if rg_emit_this_field_elem_node(n) && rg_emit_this_field_elem_node_out_field != null {
            rg_emit_lvalue_address_out = rg_emit_this_field_elem_node_out;
            return true;
        }
        !!! An element of a heap-allocated struct array: the data pointer plus
        !!! index * element size.
        str st = rg_struct_type_in_effect(n.var_name);
        if st == "" {
            return false;
        }
        int es = 0;
        if p_find_struct(st) != null {
            rg_collect_flat_fields_out = null;
            rg_collect_flat_fields_out_visited = null;
            rg_collect_flat_fields(st);
            @RgFlatPair pr = rg_collect_flat_fields_out;
            while pr != null {
                es = es + rg_field_byte_size(pr.field);
                pr = pr.next;
            }
        }
        if es <= 0 {
            return false;
        }
        !!! The slot of an array variable holds the heap pointer, so the element
        !!! address is `pointer + index * element size`; `(AT v)` would be the address
        !!! of the slot itself. Several indices are flattened row by row.
        str lin = "";
        if n.indices == null {
            lin = rg_capture_rc_expr(n.left);
        } else {
            lin = rg_linear_index_expr(n.var_name, n.indices);
        }
        if lin == "" {
            return false;
        }
        rg_emit_lvalue_address_out = "((@void " + n.var_name + ") , (" + lin + " , " +
                                     (str)es + " , *) , +)";
        return true;
    }
    if n.nk == VAR_REF {
        !!! A bare field of the enclosing method's struct: its address is inside
        !!! `this`. A local or a parameter of that name wins over the field.
        if rg_set_has(rg_method_locals, n.var_name) {
            return false;
        }
        rg_this_field_address_out = "";
        if !rg_this_field_address(n.var_name) {
            return false;
        }
        rg_emit_lvalue_address_out = rg_this_field_address_out;
        return true;
    }
    if n.nk != MEMBER_ACCESS {
        return false;
    }
    @ExprNode root = n;
    while root.nk == MEMBER_ACCESS && root.left != null {
        root = root.left;
    }
    @StrNode chain = null;
    @ExprNode c = n;
    while c != null && c.nk == MEMBER_ACCESS {
        chain = rg_strchain_append(chain, c.member_name);
        c = c.left;
    }
    chain = rgx_reverse_str(chain);
    if root != null && root.nk == ARRAY_ACCESS {
        !!! `arr[i].f1.f2`: the element of a heap array followed by fields. The element
        !!! address plus the absolute offset of the leaf field.
        str st = rg_struct_type_in_effect(root.var_name);
        if st == "" {
            return false;
        }
        rg_resolve_member_chain_out_leaf = null;
        rg_resolve_member_chain_out_abs_off = 0;
        if !rg_resolve_member_chain(n, st) {
            return false;
        }
        int off = rg_resolve_member_chain_out_abs_off;
        rg_emit_lvalue_address_out = "";
        if !rg_emit_lvalue_address(root) {
            return false;
        }
        str ea = rg_emit_lvalue_address_out;
        if off != 0 {
            rg_emit_lvalue_address_out = "((@void " + ea + ") , " + (str)off + " , +)";
        } else {
            rg_emit_lvalue_address_out = ea;
        }
        return true;
    }
    if root != null && root.nk == VAR_REF {
        bool is_var = rg_vartypemap_find(rg_syms, root.var_name) != null ||
                      rg_strmap_find(rg_sym_struct_type, root.var_name) != null;
        if !is_var && rg_struct_method_var != "" {
            !!! The chain starts at a field of the enclosing method's struct: offsets
            !!! are then absolute within `this`.
            @StrNode full = rg_strchain_append(null, root.var_name);
            @StrNode m = chain;
            while m != null {
                full = rg_strchain_append(full, m.s);
                m = m.next;
            }
            rg_resolve_field_chain_out_leaf = null;
            rg_resolve_field_chain_out_abs_off = 0;
            if !rg_resolve_field_chain(rg_struct_method_type, full, n.line, n.col) {
                return false;
            }
            int off2 = rg_resolve_field_chain_out_abs_off;
            if off2 != 0 {
                rg_emit_lvalue_address_out = "((@void " + rg_struct_method_var + ") , " +
                                             (str)off2 + " , +)";
            } else {
                rg_emit_lvalue_address_out = rg_struct_method_var;
            }
            return true;
        }
        str base_type = rg_struct_type_in_effect(root.var_name);
        rg_emit_field_chain_address_out = "";
        if !rg_emit_field_chain_address(root.var_name, base_type, chain) {
            return false;
        }
        rg_emit_lvalue_address_out = rg_emit_field_chain_address_out;
        return true;
    }
    !!! A chain hanging off an array element (`o.people[i].name`): the base is the
    !!! element's address and the members are offsets inside the element. An element
    !!! declared `@T` is a pointer, so its members are reached through the pointer the
    !!! element holds.
    if root != null && root.nk == FIELD_ELEM {
        rg_emit_lvalue_address_out = "";
        if !rg_emit_lvalue_address(root) {
            return false;
        }
        str base_addr = rg_emit_lvalue_address_out;
        if rg_is_at_type(root.result_type) {
            base_addr = "(FLDP " + base_addr + " 0 " + rg_rtype(AT_VOID) + ")";
        }
        str cur_type = root.struct_type;
        if cur_type == "" {
            return false;
        }
        int off3 = 0;
        @StrNode m2 = chain;
        while m2 != null {
            rg_resolve_field_out_decl_type = "";
            @StructField f2 = rg_resolve_field(cur_type, m2.s, true);
            if f2 == null {
                return false;
            }
            str dt2 = rg_resolve_field_out_decl_type;
            off3 = off3 + rg_field_offset_of(cur_type, m2.s, dt2);
            cur_type = f2.struct_type;
            m2 = m2.next;
        }
        if off3 != 0 {
            rg_emit_lvalue_address_out = "((@void " + base_addr + ") , " + (str)off3 + " , +)";
        } else {
            rg_emit_lvalue_address_out = base_addr;
        }
        return true;
    }
    return false;
}

!!! The base type and path one array store starts from, shared by the three
!!! store helpers: a struct variable, or the enclosing method's struct.
str rgx_store_base_type;
@StrNode rgx_store_path;
bool rgx_store_base_is_this;

!!! The declaration in effect where the name is written decides; a name that is not
!!! a variable and is not a struct is a field of `this` inside a method body.
bool rgx_store_base -> @StmtNode s {
    rgx_store_base_type = "";
    rgx_store_path = s.member_chain;
    rgx_store_base_is_this = false;
    if rg_effective_var_decl(s.var_name) {
        rgx_store_base_type = rg_effective_var_decl_out.struct_type;
    } else if p_find_struct(s.var_name) != null {
        rgx_store_base_type = s.var_name;
    }
    if rgx_store_base_type == "" {
        if rg_struct_method_var == "" {
            return false;
        }
        rgx_store_base_type = rg_struct_method_type;
        rgx_store_base_is_this = true;
        @StrNode p = rg_strchain_append(null, s.var_name);
        @StrNode m = s.member_chain;
        while m != null {
            p = rg_strchain_append(p, m.s);
            m = m.next;
        }
        rgx_store_path = p;
    }
    return true;
}

!!! The array field an assignment statement stores *into the element* of
!!! (`o.data[i] = v`, `data[i] = v` inside a method). Null when the statement
!!! targets a member of an element or is not a field array store.
@StructField rg_stmt_array_field -> @StmtNode s {
    if s == null || s.nk != ASSIGN || !s.is_array {
        return null;
    }
    if s.array_init == null {
        return null;
    }
    if s.assign_indices == null && s.expr == null {
        return null;
    }
    @RgBoolMap ait = rg_boolmap_find(rg_sym_is_array, s.var_name);
    if ait != null && ait.v {
        return null;
    }
    if !rgx_store_base(s) {
        return null;
    }
    str cur_type = rgx_store_base_type;
    @StrNode e = rgx_store_path;
    @StrNode prev = null;
    while e != null {
        rg_resolve_field_out_decl_type = "";
        @StructField f = rg_resolve_field(cur_type, e.s, true);
        if f == null {
            return null;
        }
        if f.array_dim > 0 && f.ty != CHAR {
            !!! Only the element itself, not a member of it.
            if e.next == null {
                return f;
            }
            return null;
        }
        if f.struct_ptr {
            return null;
        }
        cur_type = f.struct_type;
        prev = e;
        e = e.next;
    }
    return null;
}

!!! Emit one call argument. A struct value is passed by address, and a struct that
!!! lives in a field or an array element has no variable name to take the address
!!! of, so its address is computed directly.
void rg_emit_call_arg_value -> @ExprNode a {
    if a == null {
        end;
    }
    if a.spread {
        rg_rcode = rg_rcode + "(SPREAD ";
        rg_rc_expr(a);
        rg_rcode = rg_rcode + ")";
        end;
    }
    !!! A struct value is passed by address. The argument's own cached type may not
    !!! have been resolved yet (a plain variable of a struct type is enough to know),
    !!! so the declared type is consulted as well.
    if a.struct_type == "" && a.nk == VAR_REF && a.ptr_depth == 0 {
        str st = rg_receiver_struct_type(a);
        if st != "" {
            a.struct_type = st;
        }
    }
    !!! A field chain denotes a struct value as well; the chain is resolved from the
    !!! declarations, so an unresolved node is not treated as a scalar.
    if a.struct_type == "" && a.nk != VAR_REF {
        str st2 = rg_expr_struct_type(a);
        if st2 != "" {
            a.struct_type = st2;
        }
    }
    if a.struct_type == "" {
        rg_rc_expr(a);
        end;
    }
    if a.nk == VAR_REF {
        !!! A variable that holds the object itself is passed by its address; one that
        !!! already holds the address (a `@T` or `@int` variable) is passed as it is,
        !!! and a field of the enclosing method's struct has its address inside
        !!! `this`.
        if a.ptr_depth > 0 || rg_name_is_pointer(a.var_name) {
            rg_rcode = rg_rcode + a.var_name;
        } else {
            rg_this_field_address_out = "";
            if rg_this_field_address(a.var_name) {
                rg_rcode = rg_rcode + rg_this_field_address_out;
            } else {
                rg_rcode = rg_rcode + "(AT " + a.var_name + ")";
            }
        }
        end;
    }
    !!! A struct returned by a call (or any other expression) already holds the
    !!! address of its object; only an object that lives in a variable, a field or an
    !!! array element needs its address computed.
    if a.nk == MEMBER_ACCESS || a.nk == FIELD_ELEM || a.nk == ARRAY_ACCESS {
        rg_emit_lvalue_address_out = "";
        if rg_emit_lvalue_address(a) {
            rg_rcode = rg_rcode + rg_emit_lvalue_address_out;
            end;
        }
    }
    rg_rc_expr(a);
}

!!! `g.m = {1, 2, 3};` / `data = {...};` inside a method: an initializer list has no
!!! index to store into, so an inline array field cannot be assigned as a whole.
!!! True when the statement was recognised and reported.
bool rg_report_field_array_assign -> @StmtNode s {
    if s == null || s.nk != ASSIGN || !s.is_array {
        return false;
    }
    if s.array_init == null || s.expr != null || s.assign_indices != null {
        return false;
    }
    @RgBoolMap ait = rg_boolmap_find(rg_sym_is_array, s.var_name);
    if ait != null && ait.v {
        !!! A heap array.
        return false;
    }
    !!! The same path the element store walks, to find the array field.
    if !rgx_store_base(s) {
        return false;
    }
    if rgx_store_base_is_this && rg_set_has(rg_method_locals, s.var_name) {
        return false;
    }
    str cur_type = rgx_store_base_type;
    @StrNode e = rgx_store_path;
    while e != null {
        rg_resolve_field_out_decl_type = "";
        @StructField f = rg_resolve_field(cur_type, e.s, true);
        if f == null {
            return false;
        }
        if f.array_dim > 0 && f.ty != CHAR {
            str msg = "cannot assign an initializer list to array field '" + f.name +
                      "'; assign its elements one by one";
            rg_fmt_err(s.line, s.col, msg, pe_len(f.name), (str)null, 0, true);
            rg_has_errors = true;
            return true;
        }
        if f.struct_ptr {
            return false;
        }
        cur_type = f.struct_type;
        e = e.next;
    }
    return false;
}

!!! Store into an array field element: `o.data[i] = v`, `o.people[i].name = v`,
!!! `data[i] = v` and `data[i].name = v` (the last two inside a method body, where
!!! the base is `this`). The path from the base object to the target is walked to
!!! find the array field; anything after it is an offset inside the element, so a
!!! field of an element is stored directly, and a struct target is copied leaf by
!!! leaf.
bool rg_emit_field_array_store -> @StmtNode s {
    if s == null || s.nk != ASSIGN || !s.is_array {
        return false;
    }
    !!! One index per dimension: a single one lives in `expr`, several (a
    !!! multi-dimensional access) in `assign_indices`.
    @ExprNode idx = null;
    if s.assign_indices != null {
        idx = s.assign_indices;
    } else if s.expr != null {
        idx = p_chain_expr(null, s.expr);
    }
    @ExprNode value = s.array_init;
    if idx == null || value == null {
        return false;
    }
    !!! A local heap array is handled by the ordinary `var{index}` path.
    @RgBoolMap ait = rg_boolmap_find(rg_sym_is_array, s.var_name);
    if ait != null && ait.v {
        return false;
    }
    if !rgx_store_base(s) {
        return false;
    }
    if rgx_store_path == null {
        return false;
    }
    !!! Find the array field in the path and the offset of everything before it.
    str cur_type = rgx_store_base_type;
    int arr_off = 0;
    @StructField af = null;
    @StrNode ai = rgx_store_path;
    @StrNode prefix = null;
    while ai != null {
        rg_resolve_field_out_decl_type = "";
        @StructField f = rg_resolve_field(cur_type, ai.s, true);
        if f == null {
            return false;
        }
        str dt = rg_resolve_field_out_decl_type;
        int fo = rg_field_offset_of(cur_type, ai.s, dt);
        if fo < 0 {
            return false;
        }
        !!! The prefix is the chain from the base object through the array field
        !!! itself: it is what the address the store starts from is built out of
        !!! (`o.inner.data[i]` needs `inner` and `data`), and the toolchain takes it as
        !!! `path.begin()` to `begin() + ai` with `ai` already stepped past the array
        !!! field. Appending it only for the fields before the array left the chain
        !!! empty for `o.data[i] = v` - a bare `o.g[i][j] = v` reached
        !!! rg_emit_field_chain_address with no chain at all, which fails, and the
        !!! store was then written as a plain field write of the array.
        prefix = rg_strchain_append(prefix, ai.s);
        if f.array_dim > 0 && f.ty != CHAR {
            af = f;
            arr_off = arr_off + fo;
            ai = ai.next;
            skip;
        }
        if f.struct_ptr {
            !!! A pointer step is not addressable here.
            return false;
        }
        arr_off = arr_off + fo;
        cur_type = f.struct_type;
        ai = ai.next;
    }
    if af == null {
        return false;
    }
    !!! Every dimension needs one index; a partial access (a row of a 2-D array) is
    !!! not a single element.
    int need = rgx_int_n(af.dims);
    int got = rgx_expr_count(idx);
    if need > 0 && got != need {
        str msg = "array field '" + af.name + "' needs " + (str)need + " index(es), got " +
                  (str)got;
        rg_fmt_err(s.line, s.col, msg, pe_len(af.name), (str)null, 0, true);
        rg_has_errors = true;
        return true;
    }
    !!! The address of the array itself.
    str arr = "";
    if rgx_store_base_is_this {
        if arr_off != 0 {
            arr = "((@void " + rg_struct_method_var + ") , " + (str)arr_off + " , +)";
        } else {
            arr = rg_struct_method_var;
        }
    } else {
        rg_emit_field_chain_address_out = "";
        if !rg_emit_field_chain_address(s.var_name, rgx_store_base_type, prefix) {
            return false;
        }
        arr = rg_emit_field_chain_address_out;
    }
    str elem_addr = rg_field_elem_address_of(arr, af, idx);
    !!! The members after the array field live inside the element.
    str elem_type = af.struct_type;
    int rest_off = 0;
    @StructField leaf = af;
    @StrNode k = ai;
    while k != null {
        if elem_type == "" {
            return false;
        }
        rg_resolve_field_out_decl_type = "";
        @StructField f2 = rg_resolve_field(elem_type, k.s, true);
        if f2 == null {
            return false;
        }
        str dt2 = rg_resolve_field_out_decl_type;
        int fo2 = rg_field_offset_of(elem_type, k.s, dt2);
        if fo2 < 0 {
            return false;
        }
        rest_off = rest_off + fo2;
        elem_type = f2.struct_type;
        leaf = f2;
        k = k.next;
    }
    str tp = rg_rtype(rg_field_eff_type(leaf));
    if leaf.struct_type == "" || leaf.struct_ptr {
        rg_rcode = rg_rcode + "CAST (FLDP " + elem_addr + " " + (str)rest_off + " " + tp + ") , ";
        rg_rc_expr(value);
        rg_rcode = rg_rcode + "\n";
        return true;
    }
    str dst = elem_addr;
    if rest_off != 0 {
        dst = "((@void " + elem_addr + ") , " + (str)rest_off + " , +)";
    }
    rg_emit_struct_source_address_out = "";
    if !rg_emit_struct_source_address(value) {
        return false;
    }
    rg_emit_struct_leaf_copy(dst, leaf.struct_type, rg_emit_struct_source_address_out);
    return true;
}

int rgx_expr_count -> @ExprNode head {
    int n = 0;
    @ExprNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}
