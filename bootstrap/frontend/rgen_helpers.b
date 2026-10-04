#once
!~
 ~  bootstrap/frontend/rgen_helpers.b: the frontend/rgen_helpers.
 ~
 ~  The small predicates the rest of the code generator asks about a name: whether
 ~  the parser knows it as a BLANG_API function or a `__bcall` target, which builtin
 ~  an alias stands for, whether the name is a `func`/`@func` value rather than a
 ~  function, whether one parameter of a function is passed by reference, and the
 ~  hidden parameter name a captured variable travels under.
 ~
 ~  Every table the toolchain reads is a chain in rgen.b, so a lookup is the
 ~  `rg_<kind>_find` helper of this design and "count(name)" is "the find
 ~  answered something". The parser's own tables are read through the p_ helpers
 ~  parser.b answers with, the same way.
 ~!

#head "rgen"
#head "rgen_heads"

!!! is_builtin_func: parser.get_bapi_defs().count(name) or
!!! parser.get_bcall_targets().count(name) > 0 - a name the parser saw a BLANG_API
!!! definition for, or one a `__bcall("name")` named.
bool rg_is_builtin_func -> str name {
    if p_find_bapi(name) != null {
        return true;
    }
    return p_has_bcall(name);
}

!!! resolve_call_name: builtin_binds[name] when the name is an alias of a builtin,
!!! the name itself otherwise.
str rg_resolve_call_name -> str name {
    str bound = p_find_bind(name);
    if bound != null {
        return bound;
    }
    return name;
}

!!! is_callable_var: a real function is not a callable variable, and a name the
!!! symbol table does not hold is not one either; what is left is a `func`/`@func`
!!! value.
bool rg_is_callable_var -> str name {
    if rg_intmap_find(rg_func_arity, name) != null {
        return false;
    }
    @RgVarTypeMap it = rg_vartypemap_find(rg_syms, name);
    if it == null {
        return false;
    }
    return it.ty == FUNC || it.ty == AT_FUNC;
}

!!! is_ref_param: func_param_is_ref[fname][idx]. the toolchain test is
!!! `idx < it->second.size() && it->second[idx]`, so an index past the end of the
!!! flag chain (and a function the table does not know) is false.
bool rg_is_ref_param -> str fname, int idx {
    @RgBoolListMap it = rg_boollistmap_find(rg_func_param_is_ref, fname);
    if it == null {
        return false;
    }
    if idx >= it.n {
        return false;
    }
    @BoolNode b = it.flags;
    int i = 0;
    while b != null {
        if i == idx {
            return b.v;
        }
        b = b.next;
        i = i + 1;
    }
    return false;
}

!!! is_ref_var: sym_is_ref[name].
bool rg_is_ref_var -> str name {
    @RgBoolMap it = rg_boolmap_find(rg_sym_is_ref, name);
    if it == null {
        return false;
    }
    return it.v;
}

!!! cap_ref_name: the hidden capture parameter of a by-reference capture, empty
!!! when the name is not captured that way. the toolchain test is
!!! `_capture_map.count(name) && _capture_by_ref.count(name) && _capture_by_ref[name]`,
!!! which is the two lookups below.
str rg_cap_ref_name -> str name {
    @RgStrMap cit = rg_strmap_find(rg_capture_map, name);
    if cit == null {
        return "";
    }
    @RgBoolMap br = rg_boolmap_find(rg_capture_by_ref, name);
    if br != null && br.v {
        return cit.v;
    }
    return "";
}
