#once
!~
 ~  bootstrap/frontend/builtins.b: the frontend/builtins.
 ~
 ~  A built-in is a function the compiler itself knows how to emit (as a public .r
 ~  FUNC or as a stub). `__get_built_in_func<name> alias;` resolves against this
 ~  registry, which is categorized so that it stays extensible.
 ~
 ~  the toolchain version builds a a chain once and hands out pointers into it; a
 ~  BuiltinFunc here is a record with a chain of parameter types, and the table is a
 ~  chain of those records, which is the same thing without the vector.
 ~!

#head "types"
#head "ast"

type BuiltinFunc {
    str name;
    !!! The source-level result type the built-in exposes, used by the type checks.
    VarType ret_type;
    @VarTypeNode param_types;
    bool variadic;
    !!! True when the result is an opaque object type rather than a value.
    bool returns_object;
    @BuiltinFunc next;
};

!!! The registry. The names have to stay stable: `<...>` and `function <...> F`
!!! both look them up, and the emitter writes a matching public .r FUNC for each.
!!! The table is built once, on the first question asked of it, and the entries are
!!! put in front of the chain in the order the toolchain table lists them, so a walk reads
!!! them in that order.
@BuiltinFunc g_builtin_funcs;

bool bl_text_eq -> str a, str b {
    if a == null {
        return b == null;
    }
    if b == null {
        return false;
    }
    int i = 0;
    while a[i] != (char)0 {
        if a[i] != b[i] {
            return false;
        }
        i = i + 1;
    }
    return b[i] == (char)0;
}

@VarTypeNode bl_param -> VarType t {
    VarTypeNode proto;
    @VarTypeNode n;
    malloc(@n, size proto);
    n.ty = t;
    n.next = null;
    return n;
}

@VarTypeNode bl_params2 -> VarType a, VarType b {
    @VarTypeNode head = bl_param(a);
    head.next = bl_param(b);
    return head;
}

void builtins_init {
    if g_builtin_funcs != null {
        end;
    }
    BuiltinFunc proto;
    @BuiltinFunc second;
    malloc(@second, size proto);
    second.name = "__format_out__";
    second.ret_type = AT_VOID;
    second.param_types = bl_param(AT_VOID);
    second.variadic = false;
    second.returns_object = true;
    second.next = null;

    @BuiltinFunc first;
    malloc(@first, size proto);
    first.name = "__get_format__";
    first.ret_type = AT_VOID;
    first.param_types = bl_params2(STR, ANY);
    first.variadic = true;
    first.returns_object = true;
    first.next = second;

    g_builtin_funcs = first;
}

@BuiltinFunc find_builtin -> str name {
    builtins_init();
    @BuiltinFunc b = g_builtin_funcs;
    while b != null {
        if bl_text_eq(b.name, name) {
            return b;
        }
        b = b.next;
    }
    return null;
}
