#once
!~
 ~  bootstrap/frontend/rgen_sym.b: the frontend/rgen_sym.
 ~
 ~  The symbol questions the rest of the generator asks about a name, and the
 ~  spelling suggestion a misspelled one gets:
 ~
 ~   * effective_var_decl - the declaration in effect at this point. The body being
 ~     type checked keeps its own declarations (_local_decls), so the same name can
 ~     mean different things in two bodies without the first declaration deciding
 ~     for the second; everything else (globals, package members, parameters) comes
 ~     from the flat tables.
 ~   * struct_type_in_effect - the struct a name names, if any.
 ~   * var_is_struct_ptr - whether a name holds the address of a struct rather than
 ~     a struct value.
 ~   * closest_symbol / edit_distance - the "did you mean 'x'?" suggestion, over the
 ~     names that could actually be written at that point.
 ~
 ~  the `VarDecl& out` of effective_var_decl is the global
 ~  rg_effective_var_decl_out: the answer is a fresh record
 ~  the global is pointed at, because the struct a local declaration holds must not
 ~  be handed out itself - a caller that wrote through it would write the table.
 ~!

#head "rgen"
#head "rgen_heads"

!!! effective_var_decl: the declaration of `name` at this point, left in
!!! rg_effective_var_decl_out. A local declaration of the body being walked wins,
!!! then a name that is not visible in that body is refused, and only then do the
!!! flat tables answer. the toolchain builds `out` field by field (`out = VarDecl{}`,
!!! then every table that has an entry for the name), which is the shape below.
!!! How many times the declaration of a name was asked for, which BLANG_TIME prints:
!!! the emitter asks this for every name it writes, and each answer is several table
!!! walks and two records made on the heap.
int g_n_effdecl;

bool rg_effective_var_decl -> str name {
    g_n_effdecl = g_n_effdecl + 1;
    @RgVarDeclMap lit = rg_vardeclmap_find(rg_local_decls, name);
    if lit != null {
        !!! the toolchain copies the whole record (`out = lit->second`), so the answer is
        !!! a record of its own and not the one the declaration table holds.
        VarDecl proto;
        @VarDecl d;
        malloc(@d, size proto);
        d.ty = lit.decl.ty;
        d.ptr_depth = lit.decl.ptr_depth;
        d.struct_type = lit.decl.struct_type;
        d.struct_ptr = lit.decl.struct_ptr;
        d.is_array = lit.decl.is_array;
        d.is_ref = lit.decl.is_ref;
        d.is_unsigned = lit.decl.is_unsigned;
        d.dims = lit.decl.dims;
        d.n = lit.decl.n;
        d.len_expr = lit.decl.len_expr;
        rg_effective_var_decl_out = d;
        return true;
    }
    if rg_in_func_body && !rg_symbol_visible_here(name) {
        return false;
    }
    @RgVarTypeMap it = rg_vartypemap_find(rg_syms, name);
    if it == null {
        return false;
    }
    !!! The second record carries a name of its own: the toolchain fills the one `out` it
    !!! was given from whichever table answered, while this implementation writes a record per
    !!! branch and keeps one local of a name per function.
    VarDecl proto2;
    @VarDecl d2;
    malloc(@d2, size proto2);
    d2.ty = it.ty;
    d2.ptr_depth = 0;
    d2.struct_type = "";
    d2.struct_ptr = false;
    d2.is_array = false;
    d2.is_ref = false;
    d2.is_unsigned = false;
    d2.dims = null;
    d2.n = 0;
    d2.len_expr = null;
    @RgStrMap stit = rg_strmap_find(rg_sym_struct_type, name);
    if stit != null {
        d2.struct_type = stit.v;
    }
    @RgIntMap dit = rg_intmap_find(rg_sym_depth, name);
    if dit != null {
        d2.ptr_depth = dit.v;
    }
    @RgBoolMap ait = rg_boolmap_find(rg_sym_is_array, name);
    if ait != null {
        d2.is_array = ait.v;
    }
    @RgBoolMap rit = rg_boolmap_find(rg_sym_is_ref, name);
    if rit != null {
        d2.is_ref = rit.v;
    }
    @RgBoolMap uit = rg_boolmap_find(rg_sym_is_unsigned, name);
    if uit != null {
        d2.is_unsigned = uit.v;
    }
    @RgDimsMap mit = rg_dimmap_find(rg_sym_dims, name);
    if mit != null {
        d2.dims = mit.dims;
        d2.n = mit.n;
    }
    rg_effective_var_decl_out = d2;
    return true;
}

!!! struct_type_in_effect: the struct type of a name. The body being walked
!!! declares it - that declaration decides, even when it says the name is not a
!!! struct at all - then the body being rewritten, then the struct definitions, and
!!! last the flat symbol table.
str rg_struct_type_in_effect -> str name {
    @RgVarDeclMap lit = rg_vardeclmap_find(rg_local_decls, name);
    if lit != null {
        return lit.decl.struct_type;
    }
    @RgStrMap ot = rg_strmap_find(rg_op_body_types, name);
    if ot != null {
        return ot.v;
    }
    if rg_in_func_body && !rg_symbol_visible_here(name) {
        return "";
    }
    if p_find_struct(name) != null {
        return name;
    }
    @RgStrMap st = rg_strmap_find(rg_sym_struct_type, name);
    if st != null {
        return st.v;
    }
    return "";
}

!!! var_in_scope: whether a variable of this name is in scope where the expression
!!! stands. The declaration of the body being emitted, then the parameters of the
!!! functions it stands in, then the variables declared at the top level. A function
!!! of the same name is a separate name space and does not decide.
bool rg_var_in_scope -> str name {
    if rg_vardeclmap_find(rg_local_decls, name) != null {
        return true;
    }
    @LocalSymFrame fr = rg_local_sym_stack;
    while fr != null {
        if rg_vartypemap_find(fr.saved_type, name) != null {
            return true;
        }
        fr = fr.next;
    }
    @ParamSymFrame pf = rg_param_sym_stack;
    while pf != null {
        @StrNode p = pf.params;
        while p != null {
            if p_text_eq(p.s, name) {
                return true;
            }
            p = p.next;
        }
        pf = pf.next;
    }
    return rg_set_has(rg_global_names, name);
}

!!! var_is_struct_ptr: a variable that holds the address of a struct (`@T p`), as
!!! opposed to a struct value. The body being walked declares it, so its own
!!! declaration decides; the flat table answers for globals, parameters and the
!!! passes that walk no body.
!!!
!!! The flat flag is only believed while the declaration behind it really is an
!!! address. The tables are flat and keyed by name alone, so the flag of a `@T p`
!!! declaration stays there for the whole file: a plain `str s` parameter of another
!!! body then read as a struct pointer, and `s[k]` was emitted as an index through a
!!! pointer instead of the `s{k}` a string takes. the toolchain never sees this because
!!! pushing a body's parameters erases the flag of every parameter that is not
!!! one - with no body pushed, the declaration's own type has to answer, and a
!!! value type is not an address.
bool rg_var_is_struct_ptr -> str name {
    @RgVarDeclMap lit = rg_vardeclmap_find(rg_local_decls, name);
    if lit != null {
        return lit.decl.struct_ptr || lit.decl.ptr_depth > 0;
    }
    !!! The flat flag answers for a global, a parameter and the passes that walk no
    !!! body, and the walks keep it honest: pushing a body's parameters sets it for a
    !!! `@T` and erases it for every other parameter, and popping puts back what
    !!! stood there (rg_push_func_params). The extra test this used to carry -
    !!! believing the flag only while the symbol table still showed an address - was
    !!! a workaround for the statements that set it being skipped by the parser, and
    !!! it read a `@T` parameter as the struct value it points at.
    @RgBoolMap it = rg_boolmap_find(rg_sym_struct_ptr, name);
    return it != null && it.v;
}

!!! closest_symbol: the symbol within an edit distance of three that `name` looks
!!! like it meant. the toolchain walks the whole syms table, so an unordered_map has no
!!! order to keep; this implementation walks the chain in insertion order and keeps the first
!!! name that is closest, which is the `d < best_d` test (equal
!!! distances leave the earlier name standing). A function name is skipped - it is
!!! not usable as a value - and so is a name that is not visible here.
str rg_closest_symbol -> str name {
    str best = "";
    int best_d = 4;
    @RgVarTypeMap kv = rg_syms;
    while kv != null {
        str k = kv.key;
        if pe_eq(k, name) {
            kv = kv.next;
            continue;
        }
        if rg_intmap_find(rg_func_arity, k) != null {
            kv = kv.next;
            continue;
        }
        if !rg_symbol_visible_here(k) {
            kv = kv.next;
            continue;
        }
        int d = rg_edit_distance(name, k);
        if d < best_d {
            best_d = d;
            best = k;
        }
        kv = kv.next;
    }
    return best;
}

!!! edit_distance: the Levenshtein distance between two names, which is the simple
!!! DP (`dp[i][j]`, insert/delete/substitute). the toolchain keeps it in a
!!! fixed `int dp[64][64]` on the stack; here the table is a block of ints from the
!!! heap, sized by the two names, so a name longer than 63 characters is answered
!!! instead of writing past the end of the array.
int rg_edit_distance -> str a, str b {
    int na = pe_len(a);
    int nb = pe_len(b);
    int w = nb + 1;
    @int dp;
    malloc(@dp, (na + 1) * w * 4);
    int i = 0;
    while i <= na {
        dp[i * w] = i;
        i = i + 1;
    }
    int j = 0;
    while j <= nb {
        dp[j] = j;
        j = j + 1;
    }
    i = 1;
    while i <= na {
        j = 1;
        while j <= nb {
            int best = 0;
            if a[i - 1] == b[j - 1] {
                best = dp[(i - 1) * w + (j - 1)];
            } else {
                !!! `1 + min({dp[i-1][j], dp[i][j-1], dp[i-1][j-1]})`, with the
                !!! third answer spelled out because the language has no min.
                best = dp[(i - 1) * w + j];
                int left = dp[i * w + (j - 1)];
                if left < best {
                    best = left;
                }
                int diag = dp[(i - 1) * w + (j - 1)];
                if diag < best {
                    best = diag;
                }
                best = best + 1;
            }
            dp[i * w + j] = best;
            j = j + 1;
        }
        i = i + 1;
    }
    int answer = dp[na * w + nb];
    unlink(@dp);
    return answer;
}
