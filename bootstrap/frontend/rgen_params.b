#once
!~
 ~  bootstrap/frontend/rgen_params.b: the frontend/rgen_params.
 ~
 ~  The parameter and local-variable scopes of the bodies being generated. A
 ~  parameter (or a local of the body) may shadow an outer variable of the same
 ~  name, so the values the flat symbol tables hold are saved on a stack frame when
 ~  the body starts and put back when it ends, instead of erasing the outer name.
 ~
 ~  The two stacks are the chains of rgen.b (rg_param_sym_stack, rg_local_sym_stack):
 ~  rg_param_frame_push/drop and rg_local_frame_push/drop push and pop them, and the
 ~  frame that was pushed is the record this file fills.
 ~
 ~  `this_field_address` answers through rg_this_field_address_out, the global the
 ~  `str& out` parameter became (rgen.b, this design).
 ~!

#head "rgen"
#head "rgen_heads"

!!! ---- reading the parameter chains by index ----
!!!
!!! the toolchain indexes fparam_types/fparam_struct/fparam_is_ref/fparam_is_unsigned the
!!! way it indexes fparams; this implementation walks each chain. An accessor answers VOID,
!!! null or false past the end, which is the `pi < v.size()` half of every bounds
!!! test in push_func_params.

VarType rgx_param_at_type -> @VarTypeNode head, int i {
    @VarTypeNode e = head;
    int k = 0;
    while e != null {
        if k == i {
            return e.ty;
        }
        e = e.next;
        k = k + 1;
    }
    return VOID;
}

@StrNode rgx_param_at_str -> @StrNode head, int i {
    @StrNode e = head;
    int k = 0;
    while e != null {
        if k == i {
            return e;
        }
        e = e.next;
        k = k + 1;
    }
    return null;
}

bool rgx_param_at_bool -> @BoolNode head, int i {
    @BoolNode e = head;
    int k = 0;
    while e != null {
        if k == i {
            return e.v;
        }
        e = e.next;
        k = k + 1;
    }
    return false;
}

int rgx_param_len_type -> @VarTypeNode head {
    int n = 0;
    @VarTypeNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

int rgx_param_len_str -> @StrNode head {
    int n = 0;
    @StrNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

int rgx_param_len_bool -> @BoolNode head {
    int n = 0;
    @BoolNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

int rgx_param_len_int -> @IntNode head {
    int n = 0;
    @IntNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

!!! ---- the predicates ----

!!! is_func_param: true when a parameter of a function body currently being
!!! generated has this name. the toolchain walks the stack from the top down; this implementation's
!!! frame chain has the top first, and an existence test does not care about the
!!! order.
bool rg_is_func_param -> str name {
    @ParamSymFrame fr = rg_param_sym_stack;
    while fr != null {
        @StrNode p = fr.params;
        while p != null {
            if p_text_eq(p.s, name) {
                return true;
            }
            p = p.next;
        }
        fr = fr.next;
    }
    return false;
}

!!! method_field_shadows: true when a bare name in a struct method body is a field
!!! of the enclosing struct. A parameter or a local of that body shadows the field;
!!! a variable of the same name declared elsewhere in the file does not.
bool rg_method_field_shadows -> str name {
    if rg_struct_method_var == "" || rg_struct_method_type == "" {
        return false;
    }
    if rg_set_has(rg_method_locals, name) {
        return false;
    }
    if rg_is_func_param(name) {
        return false;
    }
    return rg_resolve_field_decl(rg_struct_method_type, name, true);
}

!!! name_is_pointer: true when a plain name holds an address instead of the value
!!! itself. A parameter keeps its address type in the symbol table, a declaration
!!! its pointer depth, and a hoisted struct value its own marker.
bool rg_name_is_pointer -> str name {
    !!! The declaration in effect where the name is written comes first: the flat
    !!! tables keep only the first declaration of a name for the whole file.
    if rg_effective_var_decl(name) {
        @VarDecl d = rg_effective_var_decl_out;
        if d.ptr_depth > 0 {
            return true;
        }
        return rg_is_at_type(d.ty);
    }
    @RgBoolMap st = rg_boolmap_find(rg_sym_struct_ptr, name);
    if st != null && st.v {
        return true;
    }
    @RgIntMap dt = rg_intmap_find(rg_sym_depth, name);
    if dt != null && dt.v > 0 {
        return true;
    }
    @RgVarTypeMap it = rg_vartypemap_find(rg_syms, name);
    return it != null && rg_is_at_type(it.ty);
}

!!! this_field_address: the .r address of a field of the enclosing method's struct,
!!! reached through the hidden `this` pointer. The field is an object inside that
!!! struct, so its address is `this` plus its offset; a struct-valued field's value
!!! is that address and not the `(FLD ...)` a scalar field is read with. The answer
!!! is left in rg_this_field_address_out.
bool rg_this_field_address -> str name {
    rg_this_field_address_out = "";
    if rg_struct_method_var == "" || rg_struct_method_type == "" {
        return false;
    }
    if rg_set_has(rg_method_locals, name) {
        return false;
    }
    if rg_is_func_param(name) {
        return false;
    }
    @StructField rfld = rg_resolve_field(rg_struct_method_type, name, true);
    if rfld == null {
        return false;
    }
    str dt = rg_resolve_field_out_decl_type;
    int off = rg_field_offset_of(rg_struct_method_type, name, dt);
    if off < 0 {
        return false;
    }
    if off != 0 {
        rg_this_field_address_out = "((@void " + rg_struct_method_var + ") , " +
                                    (str)off + " , +)";
    } else {
        rg_this_field_address_out = rg_struct_method_var;
    }
    return true;
}

!!! ---- the parameter scope ----

void rg_push_func_params -> @StmtNode s {
    ParamSymFrame proto;
    @ParamSymFrame fr;
    malloc(@fr, size proto);
    fr.params = s.fparams;
    !!! The function takes a variadic tail (`T args...`): the last parameter is the
    !!! pack the caller built, the one array parameter whose length can be read.
    fr.variadic = s.variadic;
    fr.saved = null;
    fr.saved_struct = null;
    fr.saved_ref = null;
    fr.saved_unsigned = null;
    fr.saved_struct_ptr = null;
    fr.next = null;
    rg_param_frame_push(fr);
    int ntypes = rgx_param_len_type(s.fparam_types);
    int nstruct = rgx_param_len_str(s.fparam_struct);
    int nref = rgx_param_len_bool(s.fparam_is_ref);
    int nuns = rgx_param_len_bool(s.fparam_is_unsigned);
    int pi = 0;
    @StrNode pn = s.fparams;
    while pn != null {
        str nm = pn.s;
        @RgVarTypeMap it = rg_vartypemap_find(rg_syms, nm);
        if it != null {
            fr.saved = rg_vartypemap_set(fr.saved, nm, it.ty);
        }
        rg_syms = rg_vartypemap_set(rg_syms, nm, rgx_param_at_type(s.fparam_types, pi));
        !!! Track struct-typed params so p.field resolves to the struct type. The
        !!! previous value (which may be an outer variable of the same name) is
        !!! remembered for every parameter, so restoring it never erases an unrelated
        !!! variable's struct type.
        str prev_struct = "";
        @RgStrMap sit = rg_strmap_find(rg_sym_struct_type, nm);
        if sit != null {
            prev_struct = sit.v;
        }
        fr.saved_struct = rg_strmap_set(fr.saved_struct, nm, prev_struct);
        str ps = "";
        if pi < nstruct {
            @StrNode psn = rgx_param_at_str(s.fparam_struct, pi);
            if psn != null {
                ps = psn.s;
            }
        }
        if ps != "" {
            rg_sym_struct_type = rg_strmap_set(rg_sym_struct_type, nm, ps);
        } else {
            rg_sym_struct_type = rg_strmap_drop(rg_sym_struct_type, nm);
        }
        !!! Track reference params (ref T x) for auto-dereference.
        @RgBoolMap rit = rg_boolmap_find(rg_sym_is_ref, nm);
        if rit != null {
            fr.saved_ref = rg_boolmap_set(fr.saved_ref, nm, rit.v);
        }
        bool is_ref = false;
        if pi < nref {
            is_ref = rgx_param_at_bool(s.fparam_is_ref, pi);
        }
        if is_ref {
            rg_sym_is_ref = rg_boolmap_set(rg_sym_is_ref, nm, true);
        } else {
            rg_sym_is_ref = rg_boolmap_drop(rg_sym_is_ref, nm);
        }
        !!! A `@T` parameter holds an address: the body reads its fields through the
        !!! pointer, and an assignment to it writes the address itself. The
        !!! declaration stands in the parameter's own scope: the language has no
        !!! `{ ... }` block of its own, and the one this used to be written in was
        !!! skipped whole by the parser.
        @RgBoolMap pit = rg_boolmap_find(rg_sym_struct_ptr, nm);
        bool had_ptr = false;
        if pit != null && pit.v {
            had_ptr = true;
        }
        fr.saved_struct_ptr = rg_boolmap_set(fr.saved_struct_ptr, nm, had_ptr);
        bool param_is_ptr = pi < ntypes && rg_is_at_type(rgx_param_at_type(s.fparam_types, pi)) && ps != "";
        if param_is_ptr {
            rg_sym_struct_ptr = rg_boolmap_set(rg_sym_struct_ptr, nm, true);
        } else {
            rg_sym_struct_ptr = rg_boolmap_drop(rg_sym_struct_ptr, nm);
        }
        !!! Track unsigned params (utype T x) the same way.
        @RgBoolMap uit = rg_boolmap_find(rg_sym_is_unsigned, nm);
        if uit != null {
            fr.saved_unsigned = rg_boolmap_set(fr.saved_unsigned, nm, uit.v);
        }
        bool is_uns = false;
        if pi < nuns {
            is_uns = rgx_param_at_bool(s.fparam_is_unsigned, pi);
        }
        if is_uns {
            rg_sym_is_unsigned = rg_boolmap_set(rg_sym_is_unsigned, nm, true);
        } else {
            rg_sym_is_unsigned = rg_boolmap_drop(rg_sym_is_unsigned, nm);
        }
        pi = pi + 1;
        pn = pn.next;
    }
}

void rg_pop_func_params {
    if rg_param_sym_stack == null {
        end;
    }
    @ParamSymFrame fr = rg_param_frame_top();
    rg_param_frame_drop();
    @StrNode nm = fr.params;
    while nm != null {
        str n = nm.s;
        @RgVarTypeMap sit = rg_vartypemap_find(fr.saved, n);
        if sit != null {
            rg_syms = rg_vartypemap_set(rg_syms, n, sit.ty);
        } else {
            rg_syms = rg_vartypemap_drop(rg_syms, n);
        }
        @RgStrMap sst = rg_strmap_find(fr.saved_struct, n);
        if sst != null {
            if sst.v == "" {
                rg_sym_struct_type = rg_strmap_drop(rg_sym_struct_type, n);
            } else {
                rg_sym_struct_type = rg_strmap_set(rg_sym_struct_type, n, sst.v);
            }
        }
        @RgBoolMap srt = rg_boolmap_find(fr.saved_ref, n);
        if srt != null {
            rg_sym_is_ref = rg_boolmap_set(rg_sym_is_ref, n, srt.v);
        } else {
            rg_sym_is_ref = rg_boolmap_drop(rg_sym_is_ref, n);
        }
        @RgBoolMap sut = rg_boolmap_find(fr.saved_unsigned, n);
        if sut != null {
            rg_sym_is_unsigned = rg_boolmap_set(rg_sym_is_unsigned, n, sut.v);
        } else {
            rg_sym_is_unsigned = rg_boolmap_drop(rg_sym_is_unsigned, n);
        }
        @RgBoolMap spt = rg_boolmap_find(fr.saved_struct_ptr, n);
        if spt != null {
            if spt.v {
                rg_sym_struct_ptr = rg_boolmap_set(rg_sym_struct_ptr, n, true);
            } else {
                rg_sym_struct_ptr = rg_boolmap_drop(rg_sym_struct_ptr, n);
            }
        }
        nm = nm.next;
    }
}

!!! ---- the local declaration scope ----

!!! The lambda `walk` of push_local_decls is a function of its own here, because
!!! the language has no function values. It looks at one body chain and follows the
!!! same bodies the toolchain lambda follows: the two branches of an if, the body of a
!!! while, the cases and the unmatch arm of a switch, and the two bodies of a
!!! try/catch.
void rgx_param_push_local_walk -> @LocalSymFrame fr, @StmtNode list {
    @StmtNode s = list;
    while s != null {
        if s.nk == DECLARE {
            str nm = s.var_name;
            !!! A repeated name inside one body is an error reported elsewhere; the
            !!! first declaration is the one in effect.
            if rg_vartypemap_find(fr.saved_type, nm) == null {
                @RgVarTypeMap it = rg_vartypemap_find(rg_syms, nm);
                bool had = it != null;
                fr.had_type = rg_boolmap_set(fr.had_type, nm, had);
                VarType sv = VOID;
                if had {
                    sv = it.ty;
                }
                fr.saved_type = rg_vartypemap_set(fr.saved_type, nm, sv);
                @RgIntMap dt = rg_intmap_find(rg_sym_depth, nm);
                int dv = 0;
                if dt != null {
                    dv = dt.v;
                }
                fr.saved_depth = rg_intmap_set(fr.saved_depth, nm, dv);
                @RgStrMap st = rg_strmap_find(rg_sym_struct_type, nm);
                str stv = "";
                if st != null {
                    stv = st.v;
                }
                fr.saved_struct = rg_strmap_set(fr.saved_struct, nm, stv);
                @RgBoolMap ar = rg_boolmap_find(rg_sym_is_array, nm);
                bool av = false;
                if ar != null && ar.v {
                    av = true;
                }
                fr.saved_array = rg_boolmap_set(fr.saved_array, nm, av);
                @RgDimsMap dm = rg_dimmap_find(rg_sym_dims, nm);
                @RgLongNode dmv = null;
                int dmn = 0;
                if dm != null {
                    dmv = dm.dims;
                    dmn = dm.n;
                }
                fr.saved_dims = rg_dimmap_set(fr.saved_dims, nm, dmv, dmn);
                @RgBoolMap rf = rg_boolmap_find(rg_sym_is_ref, nm);
                bool rv = false;
                if rf != null && rf.v {
                    rv = true;
                }
                fr.saved_ref = rg_boolmap_set(fr.saved_ref, nm, rv);
                @RgBoolMap uf = rg_boolmap_find(rg_sym_is_unsigned, nm);
                bool uv = false;
                if uf != null && uf.v {
                    uv = true;
                }
                fr.saved_unsigned = rg_boolmap_set(fr.saved_unsigned, nm, uv);
                fr.names = rg_strchain_append(fr.names, nm);
                rg_syms = rg_vartypemap_set(rg_syms, nm, s.decl_type);
                rg_sym_depth = rg_intmap_set(rg_sym_depth, nm, s.ptr_depth);
                if s.struct_type != "" {
                    rg_sym_struct_type = rg_strmap_set(rg_sym_struct_type, nm, s.struct_type);
                } else {
                    rg_sym_struct_type = rg_strmap_drop(rg_sym_struct_type, nm);
                }
                if s.is_array {
                    rg_sym_is_array = rg_boolmap_set(rg_sym_is_array, nm, true);
                    if s.array_dims != null {
                        rg_sym_dims = rg_dimmap_set(rg_sym_dims, nm, rg_longchain_of(s.array_dims),
                                                    rgx_param_len_int(s.array_dims));
                    }
                } else {
                    rg_sym_is_array = rg_boolmap_drop(rg_sym_is_array, nm);
                    rg_sym_dims = rg_dimmap_drop(rg_sym_dims, nm);
                }
                if s.decl_is_ref {
                    rg_sym_is_ref = rg_boolmap_set(rg_sym_is_ref, nm, true);
                } else {
                    rg_sym_is_ref = rg_boolmap_drop(rg_sym_is_ref, nm);
                }
                if s.decl_is_unsigned {
                    rg_sym_is_unsigned = rg_boolmap_set(rg_sym_is_unsigned, nm, true);
                } else {
                    rg_sym_is_unsigned = rg_boolmap_drop(rg_sym_is_unsigned, nm);
                }
            }
        }
        if s.nk == IF_ELSE {
            rgx_param_push_local_walk(fr, s.true_body);
            rgx_param_push_local_walk(fr, s.false_body);
        } else if s.nk == WHILE || s.nk == DO_WHILE {
            rgx_param_push_local_walk(fr, s.true_body);
            rgx_param_push_local_walk(fr, s.false_body);
        } else if s.nk == SWITCH {
            rgx_param_push_local_walk(fr, s.case_bodies);
            rgx_param_push_local_walk(fr, s.unmatch_body);
        } else if s.nk == TRY_CATCH {
            rgx_param_push_local_walk(fr, s.true_body);
            rgx_param_push_local_walk(fr, s.false_body);
        }
        s = s.next;
    }
}

void rg_push_local_decls -> @StmtNode body {
    LocalSymFrame proto;
    @LocalSymFrame fr;
    malloc(@fr, size proto);
    fr.names = null;
    fr.had_type = null;
    fr.saved_type = null;
    fr.saved_depth = null;
    fr.saved_struct = null;
    fr.saved_array = null;
    fr.saved_dims = null;
    fr.saved_ref = null;
    fr.saved_unsigned = null;
    fr.next = null;
    rg_local_frame_push(fr);
    rgx_param_push_local_walk(fr, body);
}

void rg_pop_local_decls {
    if rg_local_sym_stack == null {
        end;
    }
    @LocalSymFrame fr = rg_local_frame_top();
    rg_local_frame_drop();
    @StrNode nm = fr.names;
    while nm != null {
        str n = nm.s;
        @RgBoolMap ht = rg_boolmap_find(fr.had_type, n);
        bool had = false;
        if ht != null && ht.v {
            had = true;
        }
        if had {
            @RgVarTypeMap sv = rg_vartypemap_find(fr.saved_type, n);
            if sv != null {
                rg_syms = rg_vartypemap_set(rg_syms, n, sv.ty);
            }
        } else {
            rg_syms = rg_vartypemap_drop(rg_syms, n);
        }
        @RgIntMap dt = rg_intmap_find(fr.saved_depth, n);
        if dt != null {
            rg_sym_depth = rg_intmap_set(rg_sym_depth, n, dt.v);
        } else {
            rg_sym_depth = rg_intmap_drop(rg_sym_depth, n);
        }
        @RgStrMap st = rg_strmap_find(fr.saved_struct, n);
        if st != null {
            if st.v == "" {
                rg_sym_struct_type = rg_strmap_drop(rg_sym_struct_type, n);
            } else {
                rg_sym_struct_type = rg_strmap_set(rg_sym_struct_type, n, st.v);
            }
        }
        @RgBoolMap ar = rg_boolmap_find(fr.saved_array, n);
        if ar != null {
            if ar.v {
                rg_sym_is_array = rg_boolmap_set(rg_sym_is_array, n, true);
            } else {
                rg_sym_is_array = rg_boolmap_drop(rg_sym_is_array, n);
            }
        }
        @RgDimsMap dm = rg_dimmap_find(fr.saved_dims, n);
        if dm != null {
            if dm.dims == null {
                rg_sym_dims = rg_dimmap_drop(rg_sym_dims, n);
            } else {
                rg_sym_dims = rg_dimmap_set(rg_sym_dims, n, dm.dims, dm.n);
            }
        }
        @RgBoolMap rf = rg_boolmap_find(fr.saved_ref, n);
        if rf != null {
            if rf.v {
                rg_sym_is_ref = rg_boolmap_set(rg_sym_is_ref, n, true);
            } else {
                rg_sym_is_ref = rg_boolmap_drop(rg_sym_is_ref, n);
            }
        }
        @RgBoolMap uf = rg_boolmap_find(fr.saved_unsigned, n);
        if uf != null {
            if uf.v {
                rg_sym_is_unsigned = rg_boolmap_set(rg_sym_is_unsigned, n, true);
            } else {
                rg_sym_is_unsigned = rg_boolmap_drop(rg_sym_is_unsigned, n);
            }
        }
        nm = nm.next;
    }
}
