#once
!~
 ~  bootstrap/frontend/rgen_resolve.b: the frontend/rgen_resolve.
 ~
 ~  Dispatch expression type resolution by node kind. resolve_expr_type() marks the
 ~  node it resolved (`type_resolved`), so a later pass that resolves the same node
 ~  again never looks the name up in the flat tables, where the first declaration of
 ~  a shadowed name wins - which tagged a value with the wrong type.
 ~
 ~  The per-kind bodies live in rgen_resolve_varref.b, rgen_resolve_op.b,
 ~  rgen_resolve_call.b, rgen_resolve_index.b, rgen_resolve_member.b,
 ~  rgen_resolve_size.b and rgen_lambda.b, exactly as the toolchain files do.
 ~!

#head "rgen"

!!! resolve_expr_type(): resolve the node and remember that its type is known.
bool rg_resolve_expr_type -> @ExprNode n {
    if n == null {
        return true;
    }
    !!! Remember that this node carries a resolved type. The checking pass resolves
    !!! every expression it walks, and a later pass that resolves the same node
    !!! again would look names up in the flat tables, where the first declaration of
    !!! a shadowed name wins.
    bool ok = rg_resolve_expr_type_body(n);
    if ok {
        n.type_resolved = true;
    }
    return ok;
}

!!! resolve_expr_type_body(): the per-kind part, one branch per expression kind.
!!! the toolchain switch and the if chain below are the same dispatch: PRE_INCR and
!!! POST_INCR are not listed in the toolchain and fall through to the default.
bool rg_resolve_expr_type_body -> @ExprNode n {
    if n.nk == LIT_INT {
        !!! A constant the tokenizer read as a 64-bit one keeps that width: the
        !!! value of `18446744073709551615` is -1 as bits, which the type of the
        !!! value alone would call an int.
        if n.lit_is_long {
            n.result_type = LONG;
        } else {
            n.result_type = int_literal_type(n.int_val);
        }
        return true;
    }
    if n.nk == LIT_FLOAT {
        n.result_type = FLOAT;
        return true;
    }
    if n.nk == LIT_STR {
        n.result_type = STR;
        return true;
    }
    if n.nk == LIT_BOOL {
        n.result_type = BOOL;
        return true;
    }
    if n.nk == LIT_CHAR {
        n.result_type = CHAR;
        return true;
    }
    if n.nk == LIT_NULL {
        n.result_type = AT_VOID;
        return true;
    }
    if n.nk == VAR_REF {
        return rg_resolve_var_ref(n);
    }
    if n.nk == BINOP || n.nk == UNARY || n.nk == ADDR || n.nk == CAST ||
       n.nk == TERNARY || n.nk == BITNOT || n.nk == SHL || n.nk == SHR {
        return rg_resolve_operator(n);
    }
    if n.nk == FUNC_CALL {
        !!! A call under a `(@T)` cast keeps the type the cast gave it - the pointer
        !!! is the same bits - while the call itself still resolves, because its
        !!! arguments are typed here.
        if n.struct_cast {
            VarType keep_rt = n.result_type;
            str keep_st = n.struct_type;
            int keep_pd = n.ptr_depth;
            bool ok = rg_resolve_call(n);
            n.result_type = keep_rt;
            n.struct_type = keep_st;
            n.ptr_depth = keep_pd;
            return ok;
        }
        return rg_resolve_call(n);
    }
    if n.nk == ARRAY_ACCESS {
        return rg_resolve_array_access(n);
    }
    if n.nk == FIELD_ELEM {
        return rg_resolve_field_elem(n);
    }
    if n.nk == MEMBER_ACCESS {
        return rg_resolve_member(n);
    }
    if n.nk == SIZE {
        return rg_resolve_size(n);
    }
    if n.nk == COUNT {
        return rg_resolve_count(n);
    }
    if n.nk == LAMBDA {
        return rg_resolve_lambda(n);
    }
    if n.nk == ASSIGN_EXPR {
        return rg_resolve_assign(n);
    }
    return true;
}
