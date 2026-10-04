#once
!~
 ~  bootstrap/frontend/rgen_resolve_size.b: this implementation of
 ~
 ~  `size X` folds to a constant. X is a type keyword, a declared variable (the
 ~  declaration in effect where the name is written, then a field of the enclosing
 ~  method's struct, then the symbol table), or a struct name - and a name that
 ~  denotes a struct is answered with the size of the layout that is emitted for
 ~  that struct (the leaf fields back to back), never with a padded total, because
 ~  an array of the struct is stepped by this number.
 ~!

#head "rgen"

!!! resolve_size(): fold `size X` into int_val and type the node INT.
bool rg_resolve_size -> @ExprNode n {
    !!! the toolchain leaves `target` unset until one of the branches below assigns it;
    !!! every path that reaches the size table assigns it first, so the value it
    !!! starts with is never read.
    VarType target = INT;
    str name = n.var_name;
    !!! Whether the name is a type keyword. The text is compared, not the block:
    !!! `==` on two `str` values compares the addresses they point at, and the name a
    !!! node carries is a block of its own.
    if pe_eq(name, "int") {
        target = INT;
    } else if pe_eq(name, "longlong") {
        target = LONG;
    } else if pe_eq(name, "float") {
        target = FLOAT;
    } else if pe_eq(name, "str") {
        target = STR;
    } else if pe_eq(name, "char") {
        target = CHAR;
    } else if pe_eq(name, "bool") {
        target = BOOL;
    } else if pe_eq(name, "void") {
        target = VOID;
    } else {
        !!! The declaration in effect where the name is written comes first, the way
        !!! every other reader of a variable's type asks for it: the flat table
        !!! alone does not have a local of the body being generated, nor a field of
        !!! the enclosing method's struct, and `size` of either came back as zero.
        if rg_effective_var_decl(name) {
            @VarDecl d = rg_effective_var_decl_out;
            if d.struct_type != "" {
                n.int_val = rg_struct_layout_size(d.struct_type);
                n.result_type = INT;
                return true;
            }
            target = d.ty;
        } else if rg_struct_method_type != "" {
            !!! A field of the enclosing method's struct.
            @StructField f = rg_resolve_field(rg_struct_method_type, name, true);
            if f != null {
                if f.struct_type != "" && !f.struct_ptr {
                    n.int_val = rg_struct_layout_size(f.struct_type);
                    n.result_type = INT;
                    return true;
                }
                if f.struct_ptr {
                    target = rg_field_eff_type(f);
                } else {
                    target = f.ty;
                }
            } else {
                @RgVarTypeMap it2 = rg_vartypemap_find(rg_syms, name);
                if it2 == null {
                    str msg = "undeclared struct type '" + name + "'";
                    rg_fmt_err(n.line, n.col, msg, pe_len(name), (str)null, 0, false);
                    return false;
                }
                target = it2.ty;
            }
        } else {
            @RgVarTypeMap it = rg_vartypemap_find(rg_syms, name);
            if it == null {
                str msg2 = "undeclared struct type '" + name + "'";
                rg_fmt_err(n.line, n.col, msg2, pe_len(name), (str)null, 0, false);
                return false;
            }
            target = it.ty;
        }
        !!! A variable of a struct type is asked for the size of that struct: the
        !!! symbol table only knows it as a value of some builtin kind, so `size` on
        !!! a struct-typed variable used to answer four bytes for every struct,
        !!! which is what a heap node of this converted front end cannot use. The answer
        !!! is the size of the layout that is emitted for the struct - the leaf
        !!! fields back to back, the way `STRUCT ... SIZE n` is written - not a
        !!! padded total: an array of the struct is stepped by this number, so a
        !!! different one would make `size v` disagree with the storage.
        str sname = rg_receiver_struct_type_of(name);
        if sname != "" {
            if p_find_struct(sname) != null {
                !!! collect_leaf_fields(sname, leafs, seen, 0) with a fresh vector and
                !!! set: the two are the out globals of the call, so they are cleared
                !!! here the way the toolchain passes fresh containers.
                rg_collect_leaf_fields_out = null;
                rg_collect_leaf_fields_out_visited = null;
                n.int_val = rg_collect_leaf_fields(sname, 0);
                n.result_type = INT;
                return true;
            }
        }
    }
    if rg_is_at_type(target) {
        n.int_val = 8;
    } else if target == INT {
        n.int_val = 4;
    } else if target == LONG {
        n.int_val = 8;
    } else if target == FLOAT {
        n.int_val = 8;
    } else if target == STR {
        n.int_val = 8;
    } else if target == BOOL {
        n.int_val = 1;
    } else if target == CHAR {
        n.int_val = 1;
    } else {
        n.int_val = 0;
    }
    n.result_type = INT;
    return true;
}

!!! `count a`: the number of elements of the array `a`.
!!!
!!!  * an array whose length is known here - a stack array and the like
!!!    (`int a[4]`, a `const N` dimension, an enumerator) - is answered with that
!!!    number, multiplied out for a multi-dimensional one;
!!!  * `int b[n]`, whose length only exists at run time, is answered with the
!!!    length expression the declaration was written with, evaluated where the
!!!    `count` stands. The backend sizes that array from the expression and writes
!!!    no block in front of its data, so reading the metadata was reading whatever
!!!    happened to lie there;
!!!  * an auto-sized array (`int a[] = {...}`) and a variadic pack do carry the
!!!    metadata block (capacity, element size and count at -16, -12 and -8 from the
!!!    data pointer, the layout rg_emit_build_variadic_array and the array a
!!!    declaration builds both write), so the emitter reads `[a-8]` at run time;
!!!  * an array parameter (`int f -> int a[]`) is only the address of the first
!!!    element: neither a declared length nor a block is reachable from here, so it
!!!    is refused instead of answering with junk.
bool rg_resolve_count -> @ExprNode n {
    n.result_type = INT;
    !!! The node was answered already: a later pass resolving the same expression
    !!! again keeps the answer.
    if n.count_folded || n.left != null {
        return true;
    }
    if !rg_effective_var_decl(n.var_name) {
        str msg = "undeclared identifier '" + n.var_name + "'";
        rg_fmt_err(n.line, n.col, msg, p_text_len(n.var_name), (str)null, 0, true);
        rg_has_errors = true;
        return false;
    }
    @VarDecl d = rg_effective_var_decl_out;
    if !d.is_array {
        str msg2 = "'" + n.var_name + "' is not an array";
        rg_fmt_err(n.line, n.col, msg2, p_text_len(n.var_name), (str)null, 0, true);
        rg_has_errors = true;
        return false;
    }
    !!! The length of a stack array is fixed where it is declared; the element count
    !!! of a multi-dimensional one is what an iteration would walk.
    longlong total = 1;
    @RgLongNode dl = d.dims;
    int dim_n = 0;
    while dl != null {
        total = total * dl.v;
        dim_n = dim_n + 1;
        dl = dl.next;
    }
    !!! `int b[n]`: the count is the length expression the declaration was written
    !!! with, so it is emitted where the `count` stands. The folded dimensions of a
    !!! partly variable one (`int b[n][4]`) stand beside it and the count of the
    !!! whole array is the expression times those.
    if d.len_expr != null {
        !!! The names here carry the `__vla` prefix: every declaration of a source
        !!! is registered in the flat symbol tables by its plain name, and a local
        !!! of this helper called `len` made the `int len` field of the runtime's
        !!! `vector` resolve as a pointer - `len = len - 1` was emitted as pointer
        !!! arithmetic and every vector in the compiler went wrong.
        @ExprNode vla_len = p_clone_expr(d.len_expr);
        if total > 1 {
            @ExprNode vla_mul = p_new_expr(BINOP);
            vla_mul.op = "*";
            vla_mul.line = n.line;
            vla_mul.col = n.col;
            vla_mul.left = vla_len;
            @ExprNode vla_lit = p_new_expr(LIT_INT);
            vla_lit.int_val = total;
            vla_lit.result_type = INT;
            vla_mul.right = vla_lit;
            vla_mul.result_type = INT;
            vla_len = vla_mul;
        }
        n.left = vla_len;
        return true;
    }
    if dim_n > 0 && total > 0 {
        n.int_val = total;
        n.count_folded = true;
        return true;
    }
    !!! An auto-sized array carries the count in its metadata block.
    if dim_n > 0 {
        return true;
    }
    !!! The variadic tail of the enclosing function carries one too: the caller
    !!! built it. Every other array parameter has no length to read. The names of
    !!! this scan carry the `__vla` prefix for the reason above: a plain name of a
    !!! declaration becomes part of the flat symbol tables of this very source.
    bool __vla_variadic = false;
    @ParamSymFrame __vla_fr = rg_param_sym_stack;
    while __vla_fr != null {
        @StrNode __vla_pn = __vla_fr.params;
        bool __vla_here = false;
        while __vla_pn != null {
            if p_text_eq(__vla_pn.s, n.var_name) {
                __vla_here = true;
            }
            __vla_pn = __vla_pn.next;
        }
        if __vla_here {
            @StrNode __vla_last = __vla_fr.params;
            @StrNode __vla_q = __vla_fr.params;
            while __vla_q != null {
                __vla_last = __vla_q;
                __vla_q = __vla_q.next;
            }
            if __vla_fr.variadic && __vla_last != null &&
               p_text_eq(__vla_last.s, n.var_name) {
                __vla_variadic = true;
            }
            skip;
        }
        __vla_fr = __vla_fr.next;
    }
    if __vla_variadic {
        return true;
    }
    str msg3 = "the length of the array parameter '" + n.var_name + "' is not known here";
    rg_fmt_err(n.line, n.col, msg3, p_text_len(n.var_name), (str)null, 0, true);
    rg_has_errors = true;
    return false;
}
