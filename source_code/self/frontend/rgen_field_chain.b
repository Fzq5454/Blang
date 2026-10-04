#once
!~
 ~  bootstrap/frontend/rgen_field_chain.b: the frontend/rgen_field_chain
 ~  - field and member chain resolution: `a.b.c`, the address of a field chain, the
 ~  struct type a receiver denotes, and the `.r` text of a pointer and of one element
 ~  of the block it holds.
 ~
 ~  Two forms of a field read come out of here: a chain that stays inside nested
 ~  struct *values* is the flat `(FLD var offset TYPE)`, and a chain that passes
 ~  through a `@T` pointer field (or starts from a pointer variable) switches to
 ~  `(FLDP <pointer> <offset> <TYPE>)` after the pointer is read. Offsets are applied
 ~  through an `@void` cast so the backend adds bytes instead of scaling by the
 ~  pointee size.
 ~
 ~  A `a chain of str` chain is a chain of StrNode here, and every
 ~  `str&`/`int&`/`VarType*` out-parameter is the global rgen.b declares for
 ~  it. `is_ptr`/`used_ptr` are local flags, and the "declaration in effect" lookups
 ~  come from rgen_params.b.
 ~!

#head "rgen"
stub int rgx_fc_n -> @StrNode head;
stub @StrNode rgx_fc_last -> @StrNode head;
stub @StrNode rgx_fc_reverse -> @StrNode head;
stub int rgx_fc_expr_n -> @ExprNode head;

str rg_emit_fld -> str instance, str stype, str field, bool super_access, bool through_ptr,
                   int line, int col {
    !!! `self.field` written out in full is the receiver's field: the object is the
    !!! pointer the method takes (`__this`) and the type is the one the method belongs
    !!! to. No variable is named `self`, so the lookup below would know no such type
    !!! and answer the flattened slot name (`self_base`), which is a symbol nothing
    !!! declares - the .r then failed at the linker with "undeclared symbol
    !!! 'self_base'".
    bool self_receiver = false;
    if !pe_eq(rg_struct_method_var, "") && pe_eq(instance, "self") {
        self_receiver = true;
    }
    str obj = instance;
    str ty = stype;
    if self_receiver {
        obj = rg_struct_method_var;
        if !pe_eq(rg_struct_method_type, "") {
            ty = rg_struct_method_type;
        }
    }
    rg_resolve_field_out_decl_type = "";
    @StructField f = rg_resolve_field(ty, field, !super_access);
    if f == null {
        !!! A field whose receiver has no known type cannot be resolved at all: no
        !!! struct was named, so nothing declares the flattened slot name this answers
        !!! below. That is a mistake in the program (a receiver the front end does not
        !!! know), and saying so here is what keeps a name nothing declares out of the
        !!! .r, where it used to surface as "undeclared symbol 'self_base'" at the
        !!! linker. A known type that does not declare the field keeps the flattened
        !!! name: that is how a struct value passed by value is written.
        if pe_eq(ty, "") {
            rg_fmt_err(line, col, "the receiver of field '" + field + "' has no known type",
                       p_text_len(field), (str)null, 0, true);
            rg_has_errors = true;
        }
        return instance + "_" + field;
    }
    str dt = rg_resolve_field_out_decl_type;
    !!! Every read and every write of a field passes through here, so this is where a
    !!! member the type keeps to itself is refused.
    rg_check_member_access(dt, field, f.access, line, col);
    int off = rg_field_offset_in(ty, field, dt);
    !!! A `@T` variable holds the address of the struct, a `T` one the struct itself:
    !!! FLDP reads at the address plus the offset, FLD reads the object.
    !!! `self` stands for the pointer a method is handed (`__this`) only inside a
    !!! method body; the same name inside an `init`/`destruct` body stands for the
    !!! object being built, which is a value: FLDP on it would read the object's first
    !!! field as an address. Everything else keeps the `through_ptr` the caller asked
    !!! for.
    bool self_ptr = false;
    if self_receiver && pe_eq(rg_struct_method_var, "__this") {
        self_ptr = true;
    }
    if through_ptr || self_ptr {
        return "(FLDP " + obj + " " + (str)off + " " + rg_rtype(rg_field_eff_type(f)) + ")";
    }
    return "(FLD " + obj + " " + (str)off + " " + rg_rtype(rg_field_eff_type(f)) + ")";
}

bool rg_member_chain_type -> @ExprNode n, str base_type {
    rg_member_chain_type_out = "";
    if n.nk == VAR_REF || n.nk == ARRAY_ACCESS {
        rg_member_chain_type_out = base_type;
        return true;
    }
    if n.nk == MEMBER_ACCESS {
        if n.is_super {
            return false;
        }
        if !rg_member_chain_type(n.left, base_type) {
            return false;
        }
        str lt = rg_member_chain_type_out;
        rg_resolve_field_out_decl_type = "";
        @StructField f = rg_resolve_field(lt, n.member_name, true);
        if f == null {
            return false;
        }
        rg_member_chain_type_out = f.struct_type;
        if rg_member_chain_type_out == "" {
            return false;
        }
        return true;
    }
    return false;
}

bool rg_resolve_member_chain -> @ExprNode n, str base_type {
    if n.nk == VAR_REF || n.nk == ARRAY_ACCESS {
        rg_resolve_member_chain_out_leaf = null;
        rg_resolve_member_chain_out_abs_off = 0;
        return true;
    }
    if n.nk == MEMBER_ACCESS {
        if n.is_super {
            rg_resolve_field_out_decl_type = "";
            @StructField f = rg_resolve_field(rg_struct_method_type, n.member_name, false);
            if f == null {
                return false;
            }
            str dt = rg_resolve_field_out_decl_type;
            rg_check_member_access(dt, n.member_name, f.access, n.line, n.col);
            rg_resolve_member_chain_out_leaf = f;
            rg_resolve_member_chain_out_abs_off =
                rg_field_offset_of(rg_struct_method_type, n.member_name, dt);
            return true;
        }
        rg_member_chain_type_out = "";
        if !rg_member_chain_type(n.left, base_type) {
            return false;
        }
        str lt = rg_member_chain_type_out;
        rg_resolve_field_out_decl_type = "";
        @StructField f2 = rg_resolve_field(lt, n.member_name, true);
        if f2 == null {
            return false;
        }
        str dt2 = rg_resolve_field_out_decl_type;
        rg_check_member_access(dt2, n.member_name, f2.access, n.line, n.col);
        if !rg_resolve_member_chain(n.left, base_type) {
            return false;
        }
        int sub_off = rg_resolve_member_chain_out_abs_off;
        rg_resolve_member_chain_out_leaf = f2;
        rg_resolve_member_chain_out_abs_off = sub_off + rg_field_offset_of(lt, n.member_name, dt2);
        return true;
    }
    return false;
}

!!! Bytes the emitted layout of one struct occupies: the leaves back to back, which
!!! is what `STRUCT ... SIZE n` is written with.
int rg_struct_layout_size -> str stype {
    rg_collect_leaf_fields_out = null;
    rg_collect_leaf_fields_out_visited = null;
    return rg_collect_leaf_fields(stype, 0);
}

!!! `.r` text of the pointer a name holds where it is written: the name itself when
!!! the body declares it, takes it as a parameter or it is a global, and otherwise
!!! the value of a `@T` field of the enclosing method's struct, read through `this`.
str rg_pointer_base_text -> str name {
    if rg_vardeclmap_find(rg_local_decls, name) != null || rg_is_func_param(name) ||
       rg_set_has(rg_global_names, name) {
        return name;
    }
    if rg_struct_method_type == "" {
        return name;
    }
    rg_resolve_field_out_decl_type = "";
    @StructField f = rg_resolve_field(rg_struct_method_type, name, true);
    if f != null && (f.struct_ptr || rg_is_at_type(f.ty)) {
        !!! Through the pointer: a field of `this` is reached at [this+off], and the
        !!! pointer the field holds is what is read. No source position is known
        !!! here, so the field's own declaration is the one the report points at.
        return rg_emit_fld(rg_struct_method_var, rg_struct_method_type, name, false, true,
                           f.line, f.col);
    }
    return name;
}

!!! What a pointer field of the enclosing method's struct is a block *of*: the struct
!!! type of its elements (empty when they are builtins) and the byte step between
!!! them. False when the field is not a pointer at all.
bool rg_method_field_block_info -> str name {
    rg_method_field_block_info_out_struct_type = "";
    rg_method_field_block_info_out_step = 0;
    if rg_struct_method_type == "" {
        return false;
    }
    rg_resolve_field_out_decl_type = "";
    @StructField f = rg_resolve_field(rg_struct_method_type, name, true);
    if f == null {
        return false;
    }
    if f.struct_ptr && f.struct_type != "" {
        rg_method_field_block_info_out_struct_type = f.struct_type;
        rg_method_field_block_info_out_step = rg_struct_layout_size(f.struct_type);
        return true;
    }
    VarType t = f.ty;
    if f.struct_ptr {
        t = rg_field_eff_type(f);
    }
    if !rg_is_at_type(t) {
        return false;
    }
    if t == AT_CHAR || t == AT_BOOL {
        rg_method_field_block_info_out_step = 1;
    } else if t == AT_INT {
        rg_method_field_block_info_out_step = 4;
    } else {
        rg_method_field_block_info_out_step = 8;
    }
    return true;
}

!!! The element type of the block a `@T` field of the enclosing method's struct
!!! holds: `@char data` gives char, `@int data` gives int. The store path needs it
!!! because the *field* name is no symbol rg_pointer_element_type can look up, and
!!! that lookup answered the default INT for every one of them.
VarType rg_method_field_elem_type -> str name {
    if rg_struct_method_type == "" {
        return INT;
    }
    rg_resolve_field_out_decl_type = "";
    @StructField f = rg_resolve_field(rg_struct_method_type, name, true);
    if f == null {
        return INT;
    }
    VarType t = f.ty;
    if f.struct_ptr {
        t = rg_field_eff_type(f);
    }
    if !rg_is_at_type(t) {
        return INT;
    }
    return rg_deref_of(t);
}

!!! A block reached through a member chain: `c.data[i]`, `o.in.data[i]`. The last
!!! member of `base` is the pointer that holds the block, the ones before it are
!!! struct values walked by offset.
bool rg_member_chain_block_info -> @ExprNode base {
    rg_member_chain_block_info_out_base = "";
    rg_member_chain_block_info_out_struct = "";
    rg_member_chain_block_info_out_step = 0;
    rg_member_chain_block_info_out_elem = INT;
    if base == null || base.nk != MEMBER_ACCESS {
        return false;
    }
    @ExprNode root = base;
    while root.nk == MEMBER_ACCESS && root.left != null {
        root = root.left;
    }
    if root == null || root.nk != VAR_REF {
        return false;
    }
    str cnode = rg_struct_type_in_effect(root.var_name);
    if cnode == "" {
        cnode = rg_method_field_struct_type(root.var_name);
    }
    if cnode == "" {
        return false;
    }
    !!! The member names from the root outwards.
    @StrNode chain = null;
    @ExprNode c = base;
    while c != null && c.nk == MEMBER_ACCESS {
        chain = rg_strchain_append(chain, c.member_name);
        c = c.left;
    }
    if chain == null {
        return false;
    }
    chain = rgx_fc_reverse(chain);
    int nch = rgx_fc_n(chain);
    !!! Every member before the last has to be a struct *value*: the walk keeps one
    !!! base and adds the offsets to it.
    int k = 0;
    @StrNode e = chain;
    while e != null && k + 1 < nch {
        rg_resolve_field_out_decl_type = "";
        @StructField f = rg_resolve_field(cnode, e.s, true);
        if f == null || f.struct_type == "" || f.struct_ptr {
            return false;
        }
        cnode = f.struct_type;
        e = e.next;
        k = k + 1;
    }
    @StrNode last = rgx_fc_last(chain);
    rg_resolve_field_out_decl_type = "";
    @StructField f2 = rg_resolve_field(cnode, last.s, true);
    if f2 == null {
        return false;
    }
    if f2.struct_ptr {
        rg_member_chain_block_info_out_struct = f2.struct_type;
        if rg_member_chain_block_info_out_struct == "" {
            rg_member_chain_block_info_out_step = 8;
        } else {
            rg_member_chain_block_info_out_step =
                rg_struct_layout_size(rg_member_chain_block_info_out_struct);
        }
        rg_member_chain_block_info_out_elem = INT;
    } else if rg_is_at_type(f2.ty) {
        if f2.ty == AT_CHAR || f2.ty == AT_BOOL {
            rg_member_chain_block_info_out_step = 1;
        } else if f2.ty == AT_INT {
            rg_member_chain_block_info_out_step = 4;
        } else {
            rg_member_chain_block_info_out_step = 8;
        }
        rg_member_chain_block_info_out_elem = rg_deref_of(f2.ty);
    } else {
        return false;
    }
    !!! The value of that field, read from the object: the member reader builds it for
    !!! a pointer field, and a plain offset read is what is left.
    rg_emit_pointer_chain_out = "";
    if rg_emit_pointer_chain(base) {
        rg_member_chain_block_info_out_base = rg_emit_pointer_chain_out;
        return true;
    }
    @StrNode one = rg_strchain_append(null, last.s);
    rg_resolve_field_chain_out_leaf = null;
    rg_resolve_field_chain_out_abs_off = 0;
    if !rg_resolve_field_chain(cnode, one, base.line, base.col) {
        return false;
    }
    @StructField leaf = rg_resolve_field_chain_out_leaf;
    if leaf == null {
        return false;
    }
    int off = rg_resolve_field_chain_out_abs_off;
    rg_member_chain_block_info_out_base = "(FLD " + root.var_name + " " + (str)off + " " +
                                          rg_rtype(rg_field_eff_type(leaf)) + ")";
    return true;
}

!!! reverse over such a chain. The member names of a member access chain are
!!! collected from the outermost member inwards, and every walk over them goes from
!!! the base outwards, so the order has to be turned round. The chain was built by
!!! the caller for this one use, so the nodes are relinked rather than copied: the
!!! copy that stood here appended every name in the order it was read and so left
!!! the order alone, and a chain through a struct pointer field (`r.info.to`)
!!! resolved `to` in the type of `r` itself and stopped.
@StrNode rgx_fc_reverse -> @StrNode head {
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

int rgx_fc_n -> @StrNode head {
    int n = 0;
    @StrNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

@StrNode rgx_fc_last -> @StrNode head {
    @StrNode last = null;
    @StrNode e = head;
    while e != null {
        last = e;
        e = e.next;
    }
    return last;
}

int rgx_fc_expr_n -> @ExprNode head {
    int n = 0;
    @ExprNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

!!! The address of one element of a `@T` block: the pointer plus the index scaled by
!!! the layout size of T. This is the form a raw pointer needs, which has no symbol
!!! the backend could take the size from.
bool rg_pointer_element_address -> @ExprNode n {
    rg_pointer_element_address_out = "";
    if n == null || n.nk != ARRAY_ACCESS {
        return false;
    }
    str idx = "";
    if rgx_fc_expr_n(n.indices) > 1 {
        idx = rg_linear_index_expr(n.var_name, n.indices);
    } else {
        idx = rg_capture_rc_expr(n.left);
    }
    if idx == "" {
        return false;
    }
    !!! The base is a member chain (`c.data[i]`): the block is the pointer field that
    !!! chain ends in, and the index applies to the field, not to the object.
    if n.left != null && n.left.nk == MEMBER_ACCESS {
        rg_member_chain_block_info_out_base = "";
        rg_member_chain_block_info_out_struct = "";
        rg_member_chain_block_info_out_step = 0;
        rg_member_chain_block_info_out_elem = INT;
        if rg_member_chain_block_info(n.left) {
            rg_pointer_element_address_out =
                "((@void " + rg_member_chain_block_info_out_base + ") , (" + idx + " , " +
                (str)rg_member_chain_block_info_out_step + " , *) , +)";
            return true;
        }
    }
    int step = 0;
    str st = rg_struct_type_in_effect(n.var_name);
    if st != "" {
        step = rg_struct_layout_size(st);
    }
    if step == 0 {
        rg_method_field_block_info_out_struct_type = "";
        rg_method_field_block_info_out_step = 0;
        if rg_method_field_block_info(n.var_name) {
            step = rg_method_field_block_info_out_step;
        }
    }
    if step == 0 && (rg_var_is_struct_ptr(n.var_name) || rg_name_is_pointer(n.var_name)) {
        step = rg_pointer_step_size(n.var_name);
    }
    if step == 0 {
        return false;
    }
    rg_pointer_element_address_out = "((@void " + rg_pointer_base_text(n.var_name) + ") , (" +
                                     idx + " , " + (str)step + " , *) , +)";
    return true;
}

!!! Bytes a pointer variable steps by when it is written `p + 1` or `p[i]`: the
!!! layout size of the struct it points at, or the width of the builtin pointee. The
!!! .r `+` moves any pointer by eight, so the frontend scales the index itself for
!!! every pointer whose element is not eight bytes wide.
int rg_pointer_step_size -> str name {
    str st = rg_struct_type_in_effect(name);
    if st == "" {
        st = rg_method_field_struct_type(name);
    }
    if st != "" {
        return rg_struct_layout_size(st);
    }
    VarType t = AT_VOID;
    int depth = 0;
    if rg_effective_var_decl(name) {
        t = rg_effective_var_decl_out.ty;
        depth = rg_effective_var_decl_out.ptr_depth;
    }
    !!! `@T x`: the declaration carries the pointee type and the pointer depth
    !!! separately, so the step is the width of the pointee.
    if !rg_is_at_type(t) && depth > 0 {
        if t == CHAR || t == BOOL {
            return 1;
        }
        if t == INT {
            return 4;
        }
        return 8;
    }
    if t == AT_CHAR || t == AT_BOOL {
        return 1;
    }
    if t == AT_INT {
        return 4;
    }
    return 8;
}

!!! The address of one element of a block a *field* holds, reached through a member
!!! chain: `c.data[i]`, `o.in.data[i]`.
bool rg_pointer_field_elem_address -> @ExprNode n {
    rg_pointer_field_elem_address_out = "";
    rg_pointer_field_elem_address_out_struct = "";
    rg_pointer_field_elem_address_out_elem = INT;
    if n == null || n.nk != FIELD_ELEM || n.left == null {
        return false;
    }
    if n.left.nk != MEMBER_ACCESS {
        return false;
    }
    rg_member_chain_block_info_out_base = "";
    rg_member_chain_block_info_out_struct = "";
    rg_member_chain_block_info_out_step = 0;
    rg_member_chain_block_info_out_elem = INT;
    if !rg_member_chain_block_info(n.left) {
        return false;
    }
    str idx = rg_capture_rc_expr(n.right);
    if idx == "" {
        return false;
    }
    rg_pointer_field_elem_address_out = "((@void " + rg_member_chain_block_info_out_base + ") , (" +
                                        idx + " , " +
                                        (str)rg_member_chain_block_info_out_step + " , *) , +)";
    rg_pointer_field_elem_address_out_struct = rg_member_chain_block_info_out_struct;
    !!! The element's own type, which the caller needs to read or write the right
    !!! number of bytes: the emitter used the node's resolved type, and a field of a
    !!! *local* struct value inside a method never got one, so it read four bytes of
    !!! a one-byte element (`r.data[i]` in the emitter's own buffer type).
    rg_pointer_field_elem_address_out_elem = rg_member_chain_block_info_out_elem;
    return true;
}

!!! The type of one element of the block a pointer name holds: the struct element is
!!! an INT slot holding its address, a builtin element is the pointee type.
VarType rg_pointer_element_type -> str name {
    str st = rg_struct_type_in_effect(name);
    if st == "" {
        st = rg_method_field_struct_type(name);
    }
    if st != "" {
        return INT;
    }
    if rg_effective_var_decl(name) {
        return rg_deref_of(rg_effective_var_decl_out.ty);
    }
    if rg_struct_method_type != "" {
        rg_resolve_field_out_decl_type = "";
        @StructField f = rg_resolve_field(rg_struct_method_type, name, true);
        if f != null {
            if f.struct_ptr {
                return rg_deref_of(rg_field_eff_type(f));
            }
            return rg_deref_of(f.ty);
        }
    }
    return INT;
}

bool rg_method_field_is_struct_ptr -> str name {
    if rg_struct_method_type == "" {
        return false;
    }
    rg_resolve_field_out_decl_type = "";
    @StructField f = rg_resolve_field(rg_struct_method_type, name, true);
    if f != null && f.struct_ptr {
        return true;
    }
    return false;
}

str rg_method_field_struct_type -> str name {
    if rg_struct_method_type == "" {
        return "";
    }
    rg_resolve_field_out_decl_type = "";
    @StructField f = rg_resolve_field(rg_struct_method_type, name, true);
    if f != null && f.struct_ptr {
        return f.struct_type;
    }
    return "";
}

!!! Emit a member access chain that passes through a struct pointer field (`a.next.v`)
!!! or starts from a pointer variable (`p.v`). Emission accumulates the field offset
!!! within the current object and switches to the FLDP form after dereferencing a
!!! pointer. False when the chain stays inside plain nested struct values.
bool rg_emit_pointer_chain -> @ExprNode n {
    rg_emit_pointer_chain_out = "";
    if n == null || n.nk != MEMBER_ACCESS || n.is_super {
        return false;
    }
    @ExprNode root = n;
    while root.nk == MEMBER_ACCESS && root.left != null {
        root = root.left;
    }
    bool elem_root = false;
    if root != null && root.nk == ARRAY_ACCESS {
        elem_root = true;
    }
    if root == null || (root.nk != VAR_REF && !elem_root) {
        return false;
    }
    !!! The declaration in effect here, not the flat table: the same name can be a
    !!! different struct in another body. A `@T` field of the enclosing method's
    !!! struct is the third case: its value is the base, read through `this`.
    str cur_type = rg_struct_type_in_effect(root.var_name);
    if cur_type == "" {
        cur_type = rg_method_field_struct_type(root.var_name);
    }
    bool is_ptr = rg_var_is_struct_ptr(root.var_name) || rg_name_is_pointer(root.var_name) ||
                  rg_method_field_is_struct_ptr(root.var_name);
    str base = rg_pointer_base_text(root.var_name);
    if cur_type == "" {
        return false;
    }
    @StrNode chain = null;
    @ExprNode c = n;
    while c != null && c.nk == MEMBER_ACCESS {
        chain = rg_strchain_append(chain, c.member_name);
        c = c.left;
    }
    chain = rgx_fc_reverse(chain);

    bool used_ptr = is_ptr;
    if elem_root {
        !!! `p[i].field`: the element's address is the base the fields are read from,
        !!! and it is an address, so the first field goes through FLDP.
        rg_pointer_element_address_out = "";
        if !rg_pointer_element_address(root) {
            return false;
        }
        base = rg_pointer_element_address_out;
        is_ptr = true;
        used_ptr = true;
        !!! When the block is a pointer *field* (`c.data[i].a`) the elements are the
        !!! struct that field points at, not the struct the receiver is.
        if root.left != null && root.left.nk == MEMBER_ACCESS {
            rg_member_chain_block_info_out_base = "";
            rg_member_chain_block_info_out_struct = "";
            rg_member_chain_block_info_out_step = 0;
            rg_member_chain_block_info_out_elem = INT;
            if rg_member_chain_block_info(root.left) &&
               rg_member_chain_block_info_out_struct != "" {
                cur_type = rg_member_chain_block_info_out_struct;
            }
        }
    }
    str expr = base + "";
    !!! A copy and not an alias: `expr` is replaced below with the .r text of the
    !!! field while `base` still names the object the field is read from, and
    !!! assigning to a `str` variable frees the heap string it held
    !!! (backend/codegen_cast). Aliased (`str expr = base;`) the first
    !!! assignment freed the block `base` points at - which is the name the caller
    !!! passed in, so the caller's own string came back empty and its fallback
    !!! emitted `(FLD  0 AT_CHAR)` with no name at all.
    int pending = 0;
    @StrNode m = chain;
    while m != null {
        rg_resolve_field_out_decl_type = "";
        @StructField f = rg_resolve_field(cur_type, m.s, true);
        if f == null {
            return false;
        }
        str dt = rg_resolve_field_out_decl_type;
        pending = pending + rg_field_offset_of(cur_type, m.s, dt);
        str type_spelling = rg_rtype(rg_field_eff_type(f));
        if is_ptr {
            expr = "(FLDP " + base + " " + (str)pending + " " + type_spelling + ")";
        } else {
            expr = "(FLD " + base + " " + (str)pending + " " + type_spelling + ")";
        }
        if f.struct_ptr {
            !!! The field holds an address: continue through it.
            base = expr;
            is_ptr = true;
            used_ptr = true;
            pending = 0;
            cur_type = f.struct_type;
        } else if f.struct_type != "" {
            !!! Inline nested struct: keep accumulating offsets in the same base.
            cur_type = f.struct_type;
        } else {
            cur_type = "";
        }
        m = m.next;
    }
    if !used_ptr {
        return false;
    }
    rg_emit_pointer_chain_out = expr;
    return true;
}

bool rg_resolve_field_chain -> str base_type, @StrNode chain, int line, int col {
    str cur_type = base_type;
    int off = 0;
    @StructField f = null;
    @StrNode e = chain;
    while e != null {
        rg_resolve_field_out_decl_type = "";
        f = rg_resolve_field(cur_type, e.s, true);
        if f == null {
            return false;
        }
        str dt = rg_resolve_field_out_decl_type;
        !!! Every level of the chain is reached to read the one after it, so every
        !!! level is checked, the last one written and the earlier ones read to get
        !!! there.
        rg_check_member_access(dt, e.s, f.access, line, col);
        off = off + rg_field_offset_of(cur_type, e.s, dt);
        cur_type = f.struct_type;
        e = e.next;
    }
    rg_resolve_field_chain_out_leaf = f;
    rg_resolve_field_chain_out_abs_off = off;
    return true;
}

str rg_receiver_struct_type -> @ExprNode recv {
    if recv == null || recv.nk != VAR_REF {
        return "";
    }
    return rg_receiver_struct_type_of(recv.var_name);
}

str rg_receiver_struct_type_of -> str name {
    !!! A bare name in a method body is a field of the enclosing struct when the body
    !!! neither declares it nor takes it as a parameter.
    if rg_method_field_shadows(name) {
        rg_resolve_field_out_decl_type = "";
        @StructField f = rg_resolve_field(rg_struct_method_type, name, true);
        if f != null && !f.struct_ptr {
            return f.struct_type;
        }
        return "";
    }
    !!! The declaration in effect where the name is written comes first: two bodies
    !!! may declare the same name with different types.
    if rg_effective_var_decl(name) && rg_effective_var_decl_out.struct_type != "" {
        return rg_effective_var_decl_out.struct_type;
    }
    @RgStrMap it = rg_strmap_find(rg_sym_struct_type, name);
    if it != null {
        return it.v;
    }
    if p_find_struct(name) != null {
        return name;
    }
    return "";
}

!!! Struct type a method-call receiver denotes: it walks field chains (`w.inner`,
!!! `a.next`) and struct array elements, so a method can be called on a nested object.
!!! `decl_type` receives the type that declares the last member.
bool rg_receiver_info -> @ExprNode recv, bool report {
    rg_receiver_info_out_stype = "";
    rg_receiver_info_out_decl_type = "";
    if recv == null {
        return false;
    }
    if recv.nk == VAR_REF {
        if rg_effective_var_decl(recv.var_name) && rg_effective_var_decl_out.struct_type != "" {
            rg_receiver_info_out_stype = rg_effective_var_decl_out.struct_type;
            return true;
        }
        @RgStrMap it = rg_strmap_find(rg_sym_struct_type, recv.var_name);
        if it != null && it.v != "" {
            rg_receiver_info_out_stype = it.v;
            return true;
        }
        if p_find_struct(recv.var_name) != null {
            rg_receiver_info_out_stype = recv.var_name;
            return true;
        }
        !!! A bare field of the enclosing method's struct (`total.method()`).
        rg_receiver_info_out_stype = rg_receiver_struct_type(recv);
        if rg_receiver_info_out_stype != "" {
            return true;
        }
        if report {
            str msg = "undeclared struct type '" + recv.var_name + "'";
            rg_fmt_err(recv.line, recv.col, msg, pe_len(recv.var_name), (str)null, 0, true);
            rg_has_errors = true;
        }
        return false;
    }
    if recv.nk == FIELD_ELEM {
        !!! Element of an inline array field (`o.people[i].grow()`).
        if recv.struct_type == "" {
            return false;
        }
        rg_receiver_info_out_stype = recv.struct_type;
        return true;
    }
    if recv.nk == FUNC_CALL {
        !!! A method called on the result of a call: `a.add(b).mul(c)`. The struct
        !!! type is the called function's declared return struct.
        rg_receiver_info_out_stype = rg_expr_struct_type(recv);
        if rg_receiver_info_out_stype == "" {
            return false;
        }
        return true;
    }
    if recv.nk == ARRAY_ACCESS {
        if rg_effective_var_decl(recv.var_name) && rg_effective_var_decl_out.struct_type != "" {
            rg_receiver_info_out_stype = rg_effective_var_decl_out.struct_type;
            return true;
        }
        @RgStrMap it2 = rg_strmap_find(rg_sym_struct_type, recv.var_name);
        if it2 != null && it2.v != "" {
            rg_receiver_info_out_stype = it2.v;
            return true;
        }
        return false;
    }
    if recv.nk != MEMBER_ACCESS {
        return false;
    }
    !!! The chain is walked from its root variable, following struct fields.
    @ExprNode root = recv;
    while root.nk == MEMBER_ACCESS && root.left != null {
        root = root.left;
    }
    if root != null && root.nk == FIELD_ELEM {
        !!! A chain above an array element (`o.people[i].addr.city`).
        if !rg_receiver_info(root, report) {
            return false;
        }
        str base = rg_receiver_info_out_stype;
        if base == "" {
            return false;
        }
        @StrNode chain = null;
        @ExprNode c = recv;
        while c != null && c.nk == MEMBER_ACCESS {
            chain = rg_strchain_append(chain, c.member_name);
            c = c.left;
        }
        chain = rgx_fc_reverse(chain);
        str cnode = base;
        @StrNode m = chain;
        while m != null {
            rg_resolve_field_out_decl_type = "";
            @StructField f = rg_resolve_field(cnode, m.s, true);
            if f == null {
                return false;
            }
            str d2 = rg_resolve_field_out_decl_type;
            cnode = f.struct_type;
            rg_receiver_info_out_decl_type = d2;
            m = m.next;
        }
        if cnode == "" {
            return false;
        }
        rg_receiver_info_out_stype = cnode;
        return true;
    }
    if root == null || (root.nk != VAR_REF && root.nk != FUNC_CALL) {
        return false;
    }
    @StrNode chain2 = null;
    @ExprNode c2 = recv;
    while c2 != null && c2.nk == MEMBER_ACCESS {
        chain2 = rg_strchain_append(chain2, c2.member_name);
        c2 = c2.left;
    }
    chain2 = rgx_fc_reverse(chain2);
    str cur2 = "";
    if root.nk == FUNC_CALL {
        cur2 = rg_expr_struct_type(root);
        if cur2 == "" {
            return false;
        }
    } else {
        cur2 = rg_struct_type_in_effect(root.var_name);
        if cur2 == "" {
            if report {
                str msg = "undeclared struct type '" + root.var_name + "'";
                rg_fmt_err(root.line, root.col, msg, pe_len(root.var_name), (str)null, 0, true);
                rg_has_errors = true;
            }
            return false;
        }
    }
    @StrNode m2 = chain2;
    while m2 != null {
        rg_resolve_field_out_decl_type = "";
        @StructField f = rg_resolve_field(cur2, m2.s, true);
        if f == null {
            if report {
                str msg = "struct '" + cur2 + "' has no member '" + m2.s + "'";
                rg_fmt_err(recv.line, recv.col, msg, pe_len(m2.s), (str)null, 0, true);
                rg_has_errors = true;
            }
            return false;
        }
        if f.struct_type == "" {
            if report {
                str msg = "member '" + m2.s + "' of struct '" + cur2 + "' is not a struct";
                rg_fmt_err(recv.line, recv.col, msg, pe_len(m2.s), (str)null, 0, true);
                rg_has_errors = true;
            }
            return false;
        }
        str dt = rg_resolve_field_out_decl_type;
        cur2 = f.struct_type;
        rg_receiver_info_out_decl_type = dt;
        m2 = m2.next;
    }
    rg_receiver_info_out_stype = cur2;
    return true;
}

!!! Address of a field chain rooted at a variable, as an `.r` expression. Nested
!!! struct *values* are addressed by adding their byte offset to the object's address,
!!! while `@T` pointer fields are dereferenced first.
bool rg_emit_field_chain_address -> str base_var, str base_type, @StrNode chain {
    rg_emit_field_chain_address_out = "";
    str cur_type = base_type;
    if cur_type == "" {
        cur_type = rg_struct_type_in_effect(base_var);
    }
    if cur_type == "" || chain == null {
        return false;
    }
    bool is_ptr = rg_var_is_struct_ptr(base_var);
    str base = base_var;
    int pending = 0;
    @StrNode m = chain;
    while m != null {
        rg_resolve_field_out_decl_type = "";
        @StructField f = rg_resolve_field(cur_type, m.s, true);
        if f == null {
            return false;
        }
        str dt = rg_resolve_field_out_decl_type;
        int foff = rg_field_offset_of(cur_type, m.s, dt);
        if foff < 0 {
            return false;
        }
        if f.array_dim > 0 && f.ty != CHAR {
            !!! An inline array field: `base + offset` is the address of its first
            !!! element. An array of `@T` elements is not itself a pointer, so it is
            !!! not dereferenced here.
            pending = pending + foff;
            cur_type = "";
        } else if f.struct_ptr {
            !!! The pointer stored in the field is read and the walk continues through
            !!! it.
            str vp = rg_rtype(AT_VOID);
            if is_ptr {
                base = "(FLDP " + base + " " + (str)(pending + foff) + " " + vp + ")";
            } else {
                base = "(FLD " + base + " " + (str)(pending + foff) + " " + vp + ")";
            }
            is_ptr = true;
            pending = 0;
            cur_type = f.struct_type;
        } else if f.struct_type != "" {
            pending = pending + foff;
            cur_type = f.struct_type;
        } else {
            pending = pending + foff;
            cur_type = "";
        }
        m = m.next;
    }
    if is_ptr {
        if pending != 0 {
            rg_emit_field_chain_address_out = "((@void " + base + ") , " + (str)pending + " , +)";
        } else {
            rg_emit_field_chain_address_out = base;
        }
    } else {
        if pending != 0 {
            rg_emit_field_chain_address_out = "((@void (AT " + base + ")) , " + (str)pending +
                                              " , +)";
        } else {
            rg_emit_field_chain_address_out = "(AT " + base + ")";
        }
    }
    return true;
}

bool rg_emit_receiver_address -> @ExprNode recv {
    rg_emit_receiver_address_out = "";
    if recv == null {
        return false;
    }
    if recv.nk == VAR_REF {
        !!! A variable holding the object is addressed with AT; one that already holds
        !!! the address of the object passes that pointer on unchanged. A bare field of
        !!! the enclosing method's struct is addressed inside `this`.
        if recv.ptr_depth > 0 || rg_name_is_pointer(recv.var_name) {
            rg_emit_receiver_address_out = recv.var_name;
            return true;
        }
        rg_this_field_address_out = "";
        if rg_this_field_address(recv.var_name) {
            rg_emit_receiver_address_out = rg_this_field_address_out;
            return true;
        }
        rg_emit_receiver_address_out = "(AT " + recv.var_name + ")";
        return true;
    }
    if recv.nk == FUNC_CALL {
        !!! Such a receiver is hoisted into a local before the statement is emitted
        !!! (rg_prepare_stmt_struct_calls), so its value is already in this frame; the
        !!! call itself is the address of the object.
        if rg_expr_struct_type(recv) == "" {
            return false;
        }
        rg_emit_receiver_address_out = rg_capture_rc_expr(recv);
        if rg_emit_receiver_address_out == "" {
            return false;
        }
        return true;
    }
    !!! An array element (or a chain above one) is addressed by its lvalue address;
    !!! an element declared `@T` holds the address itself.
    if recv.nk == FIELD_ELEM || recv.nk == ARRAY_ACCESS ||
       (recv.nk == MEMBER_ACCESS && rg_chain_root_is_field_elem(recv)) {
        rg_emit_lvalue_address_out = "";
        if !rg_emit_lvalue_address(recv) {
            return false;
        }
        rg_emit_receiver_address_out = rg_emit_lvalue_address_out;
        if recv.nk == FIELD_ELEM && rg_is_at_type(recv.result_type) {
            rg_emit_receiver_address_out = "(FLDP " + rg_emit_receiver_address_out + " 0 " +
                                           rg_rtype(AT_VOID) + ")";
        }
        return true;
    }
    if recv.nk == MEMBER_ACCESS {
        @ExprNode root = recv;
        while root.nk == MEMBER_ACCESS && root.left != null {
            root = root.left;
        }
        if root != null && root.nk == ARRAY_ACCESS {
            if !rg_emit_lvalue_address(recv) {
                return false;
            }
            rg_emit_receiver_address_out = rg_emit_lvalue_address_out;
            return true;
        }
        if root == null || root.nk != VAR_REF {
            return false;
        }
        @StrNode chain = null;
        @ExprNode c = recv;
        while c != null && c.nk == MEMBER_ACCESS {
            chain = rg_strchain_append(chain, c.member_name);
            c = c.left;
        }
        chain = rgx_fc_reverse(chain);
        str base_type = "";
        @RgStrMap it = rg_strmap_find(rg_sym_struct_type, root.var_name);
        if it != null {
            base_type = it.v;
        }
        rg_emit_field_chain_address_out = "";
        if !rg_emit_field_chain_address(root.var_name, base_type, chain) {
            return false;
        }
        rg_emit_receiver_address_out = rg_emit_field_chain_address_out;
        return true;
    }
    return false;
}

bool rg_chain_root_is_field_elem -> @ExprNode n {
    @ExprNode r = n;
    while r != null && r.nk == MEMBER_ACCESS && r.left != null {
        r = r.left;
    }
    if r != null && r.nk == FIELD_ELEM {
        return true;
    }
    return false;
}

!!! Struct type an expression denotes, when it denotes a struct value at all.
str rg_expr_struct_type -> @ExprNode n {
    if n == null {
        return "";
    }
    !!! `(@T)e` says what the value points at, and a later pass that resolved the
    !!! expression again cannot talk it out of it: the cast is what the reader of
    !!! the expression asked for, and the bits are the same either way.
    if n.struct_cast && n.struct_type != "" {
        return n.struct_type;
    }
    if n.nk == UNARY {
        !!! `$p` on a `@T`: the value the pointer names is that struct, so `return $e;`
        !!! in a function returning T and `T v = $e;` are struct values.
        if p_text_eq(n.op, "$") && n.left != null {
            str st = rg_struct_type_in_effect(n.left.var_name);
            if st == "" {
                st = rg_method_field_struct_type(n.left.var_name);
            }
            return st;
        }
        return "";
    }
    if n.nk == FIELD_ELEM {
        !!! An element of an inline array field of structs (`w.people[i]`).
        return n.struct_type;
    }
    if n.nk == ASSIGN_EXPR {
        !!! `o = make(9)` is worth the object that was written: the type is the
        !!! target's, which the resolver left on the node.
        return n.struct_type;
    }
    if n.nk == VAR_REF || n.nk == ARRAY_ACCESS {
        !!! An element of a struct array carries its element type already.
        if n.struct_type != "" {
            return n.struct_type;
        }
        !!! A bare field name of the enclosing struct method body comes first: a
        !!! variable of the same name elsewhere in the file is not it.
        if rg_method_field_shadows(n.var_name) {
            rg_resolve_field_out_decl_type = "";
            @StructField f = rg_resolve_field(rg_struct_method_type, n.var_name, true);
            if f != null && !f.struct_ptr {
                return f.struct_type;
            }
            return "";
        }
        return rg_struct_type_in_effect(n.var_name);
    }
    if n.nk == MEMBER_ACCESS {
        if rg_receiver_info(n, false) {
            return rg_receiver_info_out_stype;
        }
        return "";
    }
    if n.nk == FUNC_CALL {
        !!! Method call: the declared return struct of the method.
        if n.has_receiver && n.args != null {
            @ExprNode r0 = n.args;
            if r0.nk == VAR_REF || r0.nk == MEMBER_ACCESS || r0.nk == FIELD_ELEM ||
               r0.nk == FUNC_CALL {
                if rg_receiver_info(r0, false) && rg_receiver_info_out_stype != "" {
                    @StmtNode mf = rg_resolve_method_func(rg_receiver_info_out_stype, n.var_name, true);
                    if mf != null {
                        return mf.ret_struct;
                    }
                }
            }
        }
        @RgStrMap it = rg_strmap_find(rg_func_ret_struct, n.var_name);
        if it != null {
            return it.v;
        }
        !!! A method of the enclosing struct called without a receiver.
        if rg_struct_method_type != "" {
            @StmtNode imf = rg_resolve_method_func(rg_struct_method_type, n.var_name, true);
            if imf != null {
                return imf.ret_struct;
            }
        }
        return "";
    }
    return "";
}

!!! True when an expression can be shown not to be a struct value.
bool rg_expr_definitely_not_struct -> @ExprNode n {
    if n == null {
        return false;
    }
    if rg_expr_struct_type(n) != "" {
        return false;
    }
    if n.nk == LIT_INT || n.nk == LIT_FLOAT || n.nk == LIT_STR || n.nk == LIT_BOOL ||
       n.nk == LIT_CHAR {
        return true;
    }
    if n.nk == VAR_REF {
        if rg_strmap_find(rg_sym_struct_type, n.var_name) != null {
            return false;
        }
        if rg_method_field_shadows(n.var_name) {
            return false;
        }
        if rg_vartypemap_find(rg_syms, n.var_name) != null {
            return true;
        }
        return false;
    }
    if n.nk == FUNC_CALL {
        if n.has_receiver && n.args != null {
            @ExprNode r0 = n.args;
            if rg_receiver_info(r0, false) && rg_receiver_info_out_stype != "" {
                @StmtNode mf = rg_resolve_method_func(rg_receiver_info_out_stype, n.var_name, true);
                if mf != null {
                    if mf.ret_struct == "" {
                        return true;
                    }
                    return false;
                }
                return false;
            }
            return false;
        }
        @RgStrMap it = rg_strmap_find(rg_func_ret_struct, n.var_name);
        if it != null {
            if it.v == "" {
                return true;
            }
            return false;
        }
        if rg_struct_method_type != "" {
            @StmtNode imf = rg_resolve_method_func(rg_struct_method_type, n.var_name, true);
            if imf != null {
                if imf.ret_struct == "" {
                    return true;
                }
                return false;
            }
        }
        return false;
    }
    return false;
}

bool rg_rimp_is_allowed -> str pair {
    return rg_set_has(rg_rimp_allowed, pair);
}
