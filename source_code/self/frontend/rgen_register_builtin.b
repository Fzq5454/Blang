#once
!~
 ~  bootstrap/frontend/rgen_register_builtin.b: this implementation of
 ~
 ~  Register the builtins and the `__get_built_in_func<B> alias;` bindings in the
 ~  function signature tables, so a call to one of them type checks like a call to
 ~  an ordinary function. The builtins themselves are the chain builtins.b builds
 ~  once (g_builtin_funcs); the bindings are the parser's table (p_builtin_binds),
 ~  read through p_find_bind elsewhere and walked here.
 ~
 ~  The parameter names of a builtin that has none of its own are made up the way
 ~  the toolchain makes them up: `p<i>` for every parameter the signature still has. The
 ~  chain the toolchain appends them to is handed to the tables as it stands, so the count
 ~  recorded beside it is the number of types, not the number of written names.
 ~!

#head "rgen"
#head "rgen_heads"

!!! The length of a chain of names, and of a chain of types: the `.size()` of the
!!! two vectors the toolchain walks with an index.
int rgx_blt_len_str -> @StrNode head {
    int n = 0;
    @StrNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

int rgx_blt_len_type -> @VarTypeNode head {
    int n = 0;
    @VarTypeNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

void rg_register_builtins -> @StmtNode stmts {
    builtins_init();
    @BuiltinFunc b = g_builtin_funcs;
    while b != null {
        @StrNode pnames = rg_builtin_param_names_of(b.name);
        int npt = rgx_blt_len_type(b.param_types);
        int np = rgx_blt_len_str(pnames);
        while np < npt {
            pnames = p_chain_str(pnames, p_new_name("p" + (str)np, 0, 0));
            np = np + 1;
        }
        rg_func_arity = rg_intmap_set(rg_func_arity, b.name, npt);
        rg_func_param_types = rg_vartypelistmap_set(rg_func_param_types, b.name,
                                                    b.param_types, npt);
        rg_func_variadic = rg_boolmap_set(rg_func_variadic, b.name, b.variadic);
        rg_func_param_names = rg_strlistmap_set(rg_func_param_names, b.name, pnames, npt);
        if rg_vartypemap_find(rg_syms, b.name) == null {
            rg_syms = rg_vartypemap_set(rg_syms, b.name, b.ret_type);
        }
        b = b.next;
    }
    !!! `__get_built_in_func<B> alias;`: the alias is callable under its own name,
    !!! with the signature the builtin it names was declared with.
    @NamePair kv = p_builtin_binds;
    while kv != null {
        @BuiltinFunc fb = find_builtin(kv.b);
        if fb == null {
            kv = kv.next;
            continue;
        }
        @StrNode pnames2 = rg_builtin_param_names_of(kv.b);
        int npt2 = rgx_blt_len_type(fb.param_types);
        int np2 = rgx_blt_len_str(pnames2);
        while np2 < npt2 {
            pnames2 = p_chain_str(pnames2, p_new_name("p" + (str)np2, 0, 0));
            np2 = np2 + 1;
        }
        rg_func_arity = rg_intmap_set(rg_func_arity, kv.a, npt2);
        rg_func_param_types = rg_vartypelistmap_set(rg_func_param_types, kv.a,
                                                    fb.param_types, npt2);
        rg_func_variadic = rg_boolmap_set(rg_func_variadic, kv.a, fb.variadic);
        rg_func_param_names = rg_strlistmap_set(rg_func_param_names, kv.a, pnames2, npt2);
        if rg_vartypemap_find(rg_syms, kv.a) == null {
            rg_syms = rg_vartypemap_set(rg_syms, kv.a, fb.ret_type);
        }
        kv = kv.next;
    }
}
