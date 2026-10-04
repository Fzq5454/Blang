#once
!~
 ~  bootstrap/backend/codegen_resolve.b: the type of an expression.
 ~
 ~  The parser types a name as int until
 ~  this pass looks the symbol up, so the result type of an operation is settled
 ~  here, bottom up: the width of a shift follows its operand, a pointer step keeps
 ~  the pointer type, and a call takes the declared return type of the function it
 ~  names (or the one the linked DLL's .bmeta gave).
 ~!

#head "cg_heads"

!!! The wider of two types: float beats str beats longlong beats int.
VarType cg_widen_type -> VarType a, VarType b {
    if a == FLOAT || b == FLOAT {
        return FLOAT;
    }
    if a == STR || b == STR {
        return STR;
    }
    if a == LONG || b == LONG {
        return LONG;
    }
    return INT;
}

!!! The `@X` of a value type.
VarType cg_at_of -> VarType t {
    if t == INT {
        return AT_INT;
    }
    if t == LONG {
        return AT_LONG;
    }
    if t == FLOAT {
        return AT_FLOAT;
    }
    if t == CHAR {
        return AT_CHAR;
    }
    if t == BOOL {
        return AT_BOOL;
    }
    if t == STR {
        return AT_STR;
    }
    if t == FUNC {
        return AT_FUNC;
    }
    return AT_INT;
}

!!! What a pointer points at, with the `default` answering int.
VarType cg_pointee_of -> VarType t {
    if t == AT_INT {
        return INT;
    }
    if t == AT_LONG {
        return LONG;
    }
    if t == AT_FLOAT {
        return FLOAT;
    }
    if t == AT_CHAR {
        return CHAR;
    }
    if t == AT_BOOL {
        return BOOL;
    }
    if t == AT_STR {
        return STR;
    }
    if t == AT_FUNC {
        return AT_FUNC;
    }
    return INT;
}

bool cg_resolve_types -> @CmpExpr n {
    if n == null {
        return true;
    }
    if n.nk == VAR_REF {
        @CgVarInfo it = cg_sym_find(n.var_name);
        if it == null {
            !!! cg_gen_call reports an undeclared call.
            n.result_type = INT;
            return true;
        }
        n.result_type = it.ty;
        n.ptr_depth = it.ptr_depth;
    }
    if n.nk == BINOP {
        !!! The unary `\` sets only the left child.
        if pe_eq(n.op, "\\") {
            if !cg_resolve_types(n.left) {
                return false;
            }
            n.result_type = BOOL;
            return true;
        }
        if !cg_resolve_types(n.left) {
            return false;
        }
        if !cg_resolve_types(n.right) {
            return false;
        }
        VarType lt = n.left.result_type;
        VarType rt = n.right.result_type;
        if pe_eq(n.op, "//") || pe_eq(n.op, "\\\\") || pe_eq(n.op, "<") ||
           pe_eq(n.op, ">") || pe_eq(n.op, "<//") || pe_eq(n.op, "//=") ||
           pe_eq(n.op, "&&") || pe_eq(n.op, "||") {
            n.result_type = BOOL;
        } else if (pe_eq(n.op, "+") || pe_eq(n.op, "-")) && vt_is_ptr(lt) {
            !!! A pointer plus an int keeps the pointer type.
            n.result_type = lt;
        } else {
            n.result_type = cg_widen_type(lt, rt);
        }
    }
    !!! Shifts and the bitwise complement keep the width of their operand, which is
    !!! only known once the operand itself is resolved.
    if n.nk == SHL || n.nk == SHR || n.nk == BITNOT {
        if !cg_resolve_types(n.left) {
            return false;
        }
        if n.nk == BITNOT {
            n.result_type = INT;
            if n.left.result_type == LONG {
                n.result_type = LONG;
            }
        } else {
            if !cg_resolve_types(n.right) {
                return false;
            }
            n.result_type = INT;
            if n.left.result_type == LONG {
                n.result_type = LONG;
            }
        }
    }
    if n.nk == TERNARY {
        if !cg_resolve_types(n.left) {
            return false;
        }
        if !cg_resolve_types(n.right) {
            return false;
        }
        @CmpExpr a = n.args;
        while a != null {
            if !cg_resolve_types(a) {
                return false;
            }
            a = a.next;
        }
        VarType t = n.right.result_type;
        VarType f = INT;
        if n.args != null {
            f = n.args.result_type;
        }
        n.result_type = cg_widen_type(t, f);
    }
    if n.nk == CAST {
        if !cg_resolve_types(n.left) {
            return false;
        }
        !!! The result type was set when the cast was parsed.
    }
    if n.nk == ARRAY_ACCESS {
        if !cg_resolve_types(n.left) {
            return false;
        }
        @CgVarInfo it = cg_sym_find(n.var_name);
        if it != null {
            if it.is_array {
                !!! `int a[3]`: the element is the declared type itself.
                n.result_type = it.ty;
            } else if it.ty == STR {
                !!! One character of a `str`.
                n.result_type = CHAR;
            } else {
                !!! `@int p`: the element is what the pointer points at, not the
                !!! pointer. Typing it as the pointer made `p[0] + 1` pointer
                !!! arithmetic and turned `(str)p[0]` into a reinterpretation.
                n.result_type = vt_pointee_type(it.ty);
                if it.ptr_depth > 0 {
                    n.ptr_depth = it.ptr_depth - 1;
                }
            }
        } else {
            n.result_type = INT;
        }
    }
    if n.nk == FUNC_CALL {
        @CmpExpr a = n.args;
        while a != null {
            if !cg_resolve_types(a) {
                return false;
            }
            a = a.next;
        }
        if pe_eq(n.var_name, "_toStr") {
            n.result_type = STR;
        } else if pe_eq(n.var_name, "_toInt") {
            n.result_type = INT;
        } else if pe_eq(n.var_name, "_toLong") {
            n.result_type = LONG;
        } else if pe_eq(n.var_name, "_toChar") {
            n.result_type = CHAR;
        } else if pe_eq(n.var_name, "_toFloat") {
            n.result_type = FLOAT;
        } else if pe_eq(n.var_name, "_toBool") {
            n.result_type = BOOL;
        } else {
            !!! A user function's declared result type decides where the value
            !!! lives: rax for INT/STR/..., xmm0 for FLOAT. Without this a FLOAT
            !!! result was read from rax and printed as 0.0.
            if cg_retype_has(n.var_name) {
                n.result_type = cg_retype_get(n.var_name);
            } else {
                !!! A function a linked DLL exports has no body in this file, so its
                !!! result type comes from the .bmeta the DLL was linked with.
                @CgDllImport dit = cg_dll_lookup(n.var_name);
                if dit != null {
                    n.result_type = dit.ret_type;
                }
            }
        }
    }
    if n.nk == ADDR {
        if !cg_resolve_types(n.left) {
            return false;
        }
        !!! The address of a function name is the raw code address.
        if n.left.nk == VAR_REF && cg_fmap_has(n.left.var_name) {
            n.result_type = AT_FUNC;
            return true;
        }
        n.ptr_depth = n.left.ptr_depth + 1;
        if n.left.ptr_depth >= 1 {
            !!! A pointer to a pointer keeps its `@X` spelling.
            n.result_type = n.left.result_type;
        } else {
            n.result_type = cg_at_of(n.left.result_type);
        }
    }
    if n.nk == DL {
        if !cg_resolve_types(n.left) {
            return false;
        }
        !!! DL dereferences one pointer level.
        n.ptr_depth = 0;
        if n.left.ptr_depth > 0 {
            n.ptr_depth = n.left.ptr_depth - 1;
        }
        if n.ptr_depth >= 1 {
            n.result_type = n.left.result_type;
        } else {
            n.result_type = cg_pointee_of(n.left.result_type);
        }
    }
    if n.nk == CLOSURE {
        @CmpExpr a = n.args;
        while a != null {
            if !cg_resolve_types(a) {
                return false;
            }
            a = a.next;
        }
        n.result_type = FUNC;
    }
    if n.nk == CLOSURE_CODE {
        if !cg_resolve_types(n.left) {
            return false;
        }
        n.result_type = AT_FUNC;
    }
    if n.nk == CLOSURE_FROM_PTR {
        if !cg_resolve_types(n.left) {
            return false;
        }
        n.result_type = FUNC;
    }
    if n.nk == CELL {
        if !cg_resolve_types(n.left) {
            return false;
        }
        n.result_type = AT_INT;
    }
    if n.nk == ICALL {
        if !cg_resolve_types(n.left) {
            return false;
        }
        @CmpExpr a = n.args;
        while a != null {
            if !cg_resolve_types(a) {
                return false;
            }
            a = a.next;
        }
        !!! The closure's own return type when it is known: a FLOAT result is in
        !!! xmm0, so typing every indirect call as INT lost it.
        n.result_type = INT;
        if n.left != null && n.left.nk == VAR_REF {
            if cg_retype_has(n.left.var_name) {
                n.result_type = cg_retype_get(n.left.var_name);
            }
        }
    }
    return true;
}
