#once
!~
 ~  bootstrap/frontend/rgen_atypes.b: the frontend/rgen_atypes.
 ~
 ~  Everything about an address type in one place: which value reads as unsigned,
 ~  which runtime helper spells it and which one performs an operation on it, what
 ~  the address type of a value is and what an address type points at - and the one
 ~  rewrite here, the constant a `utype T` slot can hold.
 ~
 ~  `ExprNode*& e` of wrap_unsigned_constant is the global
 ~  rg_wrap_unsigned_constant_out_e: the caller puts the node
 ~  it wants looked at there and reads the node that came out back.
 ~!

#head "rgen"
#head "rgen_heads"

!!! is_unsigned_value: the value of a `utype T` declaration, and only for the three
!!! widths an unsigned one exists in - an unsigned `@int` is still a pointer.
bool rg_is_unsigned_value -> @ExprNode n {
    if n == null {
        return false;
    }
    if !n.is_unsigned {
        return false;
    }
    return n.result_type == INT || n.result_type == LONG || n.result_type == CHAR;
}

!!! utype_str_helper: the print helper of an unsigned value, which reads a 64-bit
!!! one with the long form.
str rg_utype_str_helper -> @ExprNode n {
    if n != null && n.result_type == LONG {
        return "_ustrl";
    }
    return "_ustr";
}

!!! utype_op_helper: the runtime helper of an unsigned operation, or null when the
!!! operation has none. `w64` selects the longlong form of it. the toolchain tests
!!! `op[0]` and `op[1]` (the second one is the terminator of a one-character
!!! spelling), so the same tests are written here.
str rg_utype_op_helper -> str op, bool w64 {
    if op == null {
        return (str)null;
    }
    if op[0] == '/' && op[1] == (char)0 {
        if w64 {
            return "_udivl";
        }
        return "_udiv";
    }
    if op[0] == '%' && op[1] == (char)0 {
        if w64 {
            return "_umodl";
        }
        return "_umod";
    }
    if op[0] == '>' && op[1] == '>' {
        if w64 {
            return "_ushrl";
        }
        return "_ushr";
    }
    if op[0] == '<' {
        if w64 {
            if op[1] == '=' {
                return "_ulel";
            }
            return "_ultl";
        }
        if op[1] == '=' {
            return "_ule";
        }
        return "_ult";
    }
    if op[0] == '>' {
        if w64 {
            if op[1] == '=' {
                return "_ugel";
            }
            return "_ugtl";
        }
        if op[1] == '=' {
            return "_uge";
        }
        return "_ugt";
    }
    return (str)null;
}

!!! at_of: the address type of a value. A type that already is an address one has
!!! none, which the toolchain answers with `@void`; a type no case names (any) is int.
VarType rg_at_of -> VarType t {
    if t == INT { return AT_INT; }
    if t == LONG { return AT_LONG; }
    if t == FLOAT { return AT_FLOAT; }
    if t == CHAR { return AT_CHAR; }
    if t == STR { return AT_STR; }
    if t == BOOL { return AT_BOOL; }
    if t == AT_INT || t == AT_LONG || t == AT_FLOAT || t == AT_CHAR ||
       t == AT_STR || t == AT_VOID || t == AT_BOOL || t == FUNC || t == AT_FUNC {
        return AT_VOID;
    }
    return AT_INT;
}

!!! deref_of: what an address type points at. A type that is not one of them is
!!! answered as it stands (the `default: return t`).
VarType rg_deref_of -> VarType t {
    if t == AT_INT { return INT; }
    if t == AT_LONG { return LONG; }
    if t == AT_FLOAT { return FLOAT; }
    if t == AT_CHAR { return CHAR; }
    if t == AT_STR { return STR; }
    if t == AT_BOOL { return BOOL; }
    if t == AT_VOID { return VOID; }
    if t == AT_FUNC { return FUNC; }
    return t;
}

!!! wrap_unsigned_constant: a constant that a `utype T` target can hold -
!!! `utype int u = 4294967295;` spells a value an int cannot, and that value is
!!! what the unsigned type is for. The constant is wrapped in the cast to the
!!! target, which is what the type check then accepts and what leaves the unsigned
!!! bits in the slot. A negative constant is left alone: it is the same bits either
!!! way, and the signed reading of it is what the writer meant.
void rg_wrap_unsigned_constant -> VarType t {
    @ExprNode e = rg_wrap_unsigned_constant_out_e;
    if e == null || e.nk != LIT_INT || e.int_val < 0 {
        end;
    }
    if t != INT && t != CHAR {
        end;
    }
    utype longlong limit = 4294967295;
    if t == CHAR {
        limit = 255;
    }
    if (utype longlong)e.int_val > limit {
        end;
    }
    if e.result_type == t {
        !!! already the target's own type
        end;
    }
    !!! `new ExprNode{ExprNode::CAST}`: a fresh node whose other fields are the
    !!! zero values, which is what the toolchain aggregate initialization gives. A block
    !!! from malloc is junk, so every field a later pass reads is written out, the
    !!! way p_new_expr writes them for the nodes the parser makes.
    ExprNode proto;
    @ExprNode cast;
    malloc(@cast, size proto);
    cast.nk = CAST;
    cast.int_val = 0;
    cast.lit_is_long = false;
    cast.float_val = 0.0;
    cast.str_val = "";
    cast.bool_val = false;
    cast.char_val = 0;
    cast.var_name = "";
    cast.var_name_start = 0;
    cast.var_name_stop = 0;
    cast.member_name = "";
    cast.op = "";
    cast.is_super = false;
    cast.has_receiver = false;
    cast.is_overload_call = false;
    cast.spread = false;
    cast.left = null;
    cast.right = null;
    cast.args = null;
    cast.next = null;
    cast.nargs = 0;
    cast.indices = null;
    cast.targs = null;
    cast.targ_exprs = null;
    cast.targ_structs = null;
    cast.targ_is_value = null;
    cast.arg_names = null;
    cast.arg_name_lines = null;
    cast.arg_name_cols = null;
    cast.arg_name_lens = null;
    cast.result_type = INT;
    cast.is_unsigned = false;
    cast.type_resolved = false;
    cast.address_type = INT;
    cast.struct_type = "";
    cast.cast_type_param = "";
    cast.ptr_depth = 0;
    cast.convert_to = ANY;
    cast.line = 0;
    cast.col = 0;
    !!! tok_len is 1 and not 0: that is the member initializer header
    !!! (`int tok_len = 1`), and a node the compiler built has no span of its own.
    cast.tok_len = 1;
    cast.op_line = 0;
    cast.op_col = 0;
    cast.lambda_id = 0;
    !!! The fields the toolchain sets after the node is made.
    cast.line = e.line;
    cast.col = e.col;
    if t == CHAR {
        cast.op = "toChar";
    } else {
        cast.op = "toInt";
    }
    cast.left = e;
    cast.result_type = t;
    cast.is_unsigned = true;
    cast.type_resolved = true;
    rg_wrap_unsigned_constant_out_e = cast;
}
