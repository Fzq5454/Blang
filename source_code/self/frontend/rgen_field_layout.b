#once
!~
 ~  bootstrap/frontend/rgen_field_layout.b: the frontend/rgen_field_layout.
 ~
 ~  Where the fields of a struct sit in memory and how big they are, which is what
 ~  every field access compiles to.
 ~
 ~   * collect_flat_fields lists every field of a type and of its bases, in
 ~     declaration order, each with the type that declares it. Bases come first, so
 ~     the offsets of the derived fields follow them.
 ~   * collect_leaf_fields lists the storage leaves instead: a field that is a nested
 ~     struct VALUE is flattened into the object that holds it, and everything else -
 ~     a scalar, a `char[N]`, an inline array, a `@Struct` pointer - is one leaf. It
 ~     answers the total size of the object from `base_off`.
 ~   * field_byte_size / field_elem_size give the size of a field and of one element
 ~     of an array field, and field_offset_of / field_offset_in the offset of a
 ~     field, the second one asking the leaf list first.
 ~
 ~  The out lists and the two `visited` sets are the four globals rgen.b
 ~  declares (rg_collect_flat_fields_out / _out_visited and
 ~  rg_collect_leaf_fields_out / _out_visited), so a caller that wants a list of its
 ~  own empties them first, exactly as the toolchain passes a fresh local vector and set.
 ~
 ~  One thing the toolchain does with those containers and this implementation has to spell out: the
 ~  nested-struct-value branch of collect_leaf_fields hands the recursion a COPY of
 ~  the visited set, so what the nested walk marks is not marked outside it (that is
 ~  what stops a self-containing struct). this implementation saves the chain, installs a copy
 ~  of it for the descent and puts the saved one back.
 ~!

#head "rgen"

!!! The flat field list of a type: its bases first, then its own fields, each with
!!! the type that declares it. The answer accumulates in
!!! rg_collect_flat_fields_out and the types already expanded are remembered in
!!! rg_collect_flat_fields_out_visited, the two out-parameters of the toolchain.
void rg_collect_flat_fields -> str stype {
    @StructDef sit = p_find_struct(stype);
    if sit == null {
        end;
    }
    if rg_set_has(rg_collect_flat_fields_out_visited, stype) {
        end;
    }
    rg_collect_flat_fields_out_visited =
        rg_set_add(rg_collect_flat_fields_out_visited, stype);
    @StrNode b = sit.bases;
    while b != null {
        rg_collect_flat_fields(b.s);
        b = b.next;
    }
    @StructField f = sit.fields;
    while f != null {
        rg_collect_flat_fields_out =
            rg_flatpair_append(rg_collect_flat_fields_out, f, stype);
        f = f.next;
    }
}

!!! The leaf list of a type, and the size of the object it describes from
!!! `base_off`. The answer accumulates in rg_collect_leaf_fields_out.
int rg_collect_leaf_fields -> str stype, int base_off {
    @StructDef sit = p_find_struct(stype);
    if sit == null {
        return 0;
    }
    if rg_set_has(rg_collect_leaf_fields_out_visited, stype) {
        return 0;
    }
    rg_collect_leaf_fields_out_visited =
        rg_set_add(rg_collect_leaf_fields_out_visited, stype);
    int cnode = base_off;
    @StrNode b = sit.bases;
    while b != null {
        cnode = cnode + rg_collect_leaf_fields(b.s, cnode);
        b = b.next;
    }
    @StructField f = sit.fields;
    while f != null {
        if f.struct_type != "" && !f.struct_ptr && f.array_dim == 0 {
            !!! Nested struct VALUE: flattened into this object. The visited set is
            !!! copied for the descent, so a self-containing struct stops instead of
            !!! recursing forever (a direct self-reference is rejected by the parser).
            !!! the toolchain copies the name table and hands the copy down; here the chain is
            !!! saved, a copy of it is installed, and the saved one comes back, so what
            !!! the nested walk marked is not marked here.
            @RgStrSet saved_vis = rg_collect_leaf_fields_out_visited;
            @RgStrSet nv = null;
            @RgStrSet ve = saved_vis;
            while ve != null {
                nv = rg_set_add(nv, ve.key);
                ve = ve.next;
            }
            rg_collect_leaf_fields_out_visited = nv;
            cnode = cnode + rg_collect_leaf_fields(f.struct_type, cnode);
            rg_collect_leaf_fields_out_visited = saved_vis;
        } else {
            !!! Scalars, char[N], inline arrays and `@Struct` pointers are leaves; an
            !!! array field keeps its elements back to back.
            int sz = rg_field_byte_size(f);
            rg_collect_leaf_fields_out =
                rg_flatchain_append(rg_collect_leaf_fields_out, f, stype, cnode);
            cnode = cnode + sz;
        }
        f = f.next;
    }
    return cnode - base_off;
}

!!! The storage name of one field: `instance_<declaring type>_<field>`, or
!!! `instance_<field>` when the field is not found. `super_access` asks for the
!!! field of the type itself only (`include_self` is the other way round).
str rg_field_ref_var -> str instance, str stype, str field, bool super_access {
    bool found = rg_resolve_field_decl(stype, field, !super_access);
    if found {
        str dt = rg_resolve_field_decl_out_decl_type;
        return instance + "_" + dt + "_" + field;
    }
    return instance + "_" + field;
}

!!! The type a field is read as: a `@Struct` pointer is an eight-byte address, and a
!!! `char[N]` field keeps the old mapping to `str`.
VarType rg_field_eff_type -> @StructField f {
    if f.struct_ptr {
        return AT_INT;
    }
    if f.ty == CHAR && f.array_dim > 0 {
        return STR;
    }
    return f.ty;
}

!!! Byte size of one element of an array field. A nested struct value takes the size
!!! of its flat field list; `char[N]` is not laid out inline at all (`field_byte_size`
!!! keeps it a `str`), so only the other element types land here.
int rg_field_elem_size -> @StructField f {
    if f.struct_ptr {
        return 8;
    }
    if f.struct_type != "" {
        @StructDef sit = p_find_struct(f.struct_type);
        if sit != null {
            rg_collect_flat_fields_out = null;
            rg_collect_flat_fields_out_visited = null;
            rg_collect_flat_fields(f.struct_type);
            int total = 0;
            @RgFlatPair pr = rg_collect_flat_fields_out;
            while pr != null {
                total = total + rg_field_byte_size(pr.field);
                pr = pr.next;
            }
            return total;
        }
    }
    VarType t = rg_field_eff_type(f);
    if t == CHAR || t == BOOL {
        return 1;
    }
    if t == INT {
        return 4;
    }
    return 8;   !!! FLOAT, STR and every pointer type: eight bytes
}

!!! Byte size of one field of an object. An inline array field occupies its elements
!!! back to back; an array of `@Struct` pointers holds one address per element.
int rg_field_byte_size -> @StructField f {
    if f.array_dim > 0 && f.ty != CHAR {
        return f.array_dim * rg_field_elem_size(f);
    }
    if f.struct_ptr {
        return 8;   !!! a pointer: one address
    }
    if f.struct_type != "" {
        @StructDef sit = p_find_struct(f.struct_type);
        if sit != null {
            rg_collect_flat_fields_out = null;
            rg_collect_flat_fields_out_visited = null;
            rg_collect_flat_fields(f.struct_type);
            int total = 0;
            @RgFlatPair pr = rg_collect_flat_fields_out;
            while pr != null {
                total = total + rg_field_byte_size(pr.field);
                pr = pr.next;
            }
            return total;
        }
    }
    VarType t = rg_field_eff_type(f);
    if t == CHAR || t == BOOL {
        return 1;
    }
    if t == INT {
        return 4;
    }
    return 8;   !!! FLOAT, STR and every pointer/ref type: eight bytes
}

!!! The absolute offset of the leaf `field` declared by `decl_type` in `stype`.
int rg_field_offset_in -> str stype, str field, str decl_type {
    rg_collect_leaf_fields_out = null;
    rg_collect_leaf_fields_out_visited = null;
    rg_collect_leaf_fields(stype, 0);
    @FlatField lf = rg_collect_leaf_fields_out;
    while lf != null {
        if p_text_eq(lf.field.name, field) && p_text_eq(lf.decl_type, decl_type) {
            return lf.abs_off;
        }
        lf = lf.next;
    }
    !!! A struct-valued field is not a storage leaf, so the leaf list has no entry for
    !!! it: its own offset is the position of the sub-object, which the flat field
    !!! list gives.
    return rg_field_offset_of(stype, field, decl_type);
}

!!! The offset of `field` (declared by `decl_type`) in the flat field list of
!!! `stype`, walking the fields in storage order and adding each one's size, or -1
!!! when the type has no such field.
int rg_field_offset_of -> str stype, str field, str decl_type {
    rg_collect_flat_fields_out = null;
    rg_collect_flat_fields_out_visited = null;
    rg_collect_flat_fields(stype);
    int off = 0;
    @RgFlatPair pr = rg_collect_flat_fields_out;
    while pr != null {
        if p_text_eq(pr.field.name, field) && p_text_eq(pr.decl_type, decl_type) {
            return off;
        }
        off = off + rg_field_byte_size(pr.field);
        pr = pr.next;
    }
    return -1;
}
