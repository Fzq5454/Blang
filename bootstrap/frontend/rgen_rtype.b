#once
!~
 ~  bootstrap/frontend/rgen_rtype.b: the frontend/rgen_rtype.
 ~
 ~  How a VarType is written out: the .r token the back end reads (rtype, the
 ~  unsigned form of it, the `AT<n>_` form of a pointer depth), the spelling a
 ~  diagnostic uses (type_name), and the three questions the rest of the generator
 ~  asks about one - is it an address type, what does it point at, and what is the
 ~  address type of a value.
 ~
 ~  the toolchain switch covers every member of the enum and then answers a default, so
 ~  each one is an if below, in the order the toolchain writes them. `is_at_type` is the
 ~  range test `t >= AT_INT && t <= AT_BOOL` of the toolchain; the six members of that
 ~  range are written out by name because the language gives a kind no order.
 ~!

#head "rgen"
#head "rgen_heads"

!!! rtype: the .r token of a type. The last answer is the `default`, which no
!!! member of the enum reaches.
str rg_rtype -> VarType t {
    if t == INT { return "INT"; }
    if t == LONG { return "LONG"; }
    if t == STR { return "STR"; }
    if t == FLOAT { return "FLOAT"; }
    if t == BOOL { return "BOOL"; }
    if t == CHAR { return "CHAR"; }
    if t == VOID { return "VOID"; }
    if t == ANY { return "ANY"; }
    if t == AT_INT { return "AT_INT"; }
    if t == AT_LONG { return "AT_LONG"; }
    if t == AT_FLOAT { return "AT_FLOAT"; }
    if t == AT_CHAR { return "AT_CHAR"; }
    if t == AT_STR { return "AT_STR"; }
    if t == AT_VOID { return "AT_VOID"; }
    if t == AT_BOOL { return "AT_BOOL"; }
    if t == FUNC { return "FUNC"; }
    if t == AT_FUNC { return "AT_FUNC"; }
    return "INT";
}

!!! rustype: the token of a `utype T` value, for the three widths an unsigned one
!!! exists in; every other type is the plain token.
str rg_rustype -> VarType t, bool is_unsigned {
    if is_unsigned {
        if t == INT { return "UTYPE_INT"; }
        if t == LONG { return "UTYPE_LONG"; }
        if t == CHAR { return "UTYPE_CHAR"; }
    }
    return rg_rtype(t);
}

!!! rtype_depth: `AT_` is stripped first, so `@str` at depth 1 is `AT_STR` and not
!!! `AT_AT_STR`, and a depth above one is spelled `AT2_STR`, `AT3_STR`, ...
str rg_rtype_depth -> VarType t, int depth {
    str base = rg_rtype(t);
    if pe_matches(base, 0, "AT_") {
        base = pe_sub_to_end(base, 3);
    }
    if depth <= 0 {
        return base;
    }
    if depth == 1 {
        return "AT_" + base;
    }
    return "AT" + (str)depth + "_" + base;
}

!!! type_name: how a type is named in a message. It is the same spelling the free
!!! type_name of types.b answers, which is what the two ports have to agree on.
str rg_type_name -> VarType t {
    if t == VOID { return "void"; }
    if t == BOOL { return "bool"; }
    if t == INT { return "int"; }
    if t == LONG { return "longlong"; }
    if t == STR { return "str"; }
    if t == FLOAT { return "float"; }
    if t == CHAR { return "char"; }
    if t == ANY { return "any"; }
    if t == AT_INT { return "@int"; }
    if t == AT_LONG { return "@longlong"; }
    if t == AT_FLOAT { return "@float"; }
    if t == AT_CHAR { return "@char"; }
    if t == AT_STR { return "@str"; }
    if t == AT_VOID { return "@void"; }
    if t == AT_BOOL { return "@bool"; }
    if t == FUNC { return "func"; }
    if t == AT_FUNC { return "@func"; }
    return "int";
}

!!! is_at_type: one of the address types. the toolchain writes the first six as the enum
!!! range `AT_INT .. AT_BOOL` and adds AT_LONG, which stands after them in the
!!! enum; this implementation names all seven.
bool rg_is_at_type -> VarType t {
    if t == AT_INT || t == AT_FLOAT || t == AT_CHAR || t == AT_STR ||
       t == AT_VOID || t == AT_BOOL || t == AT_LONG {
        return true;
    }
    return false;
}

!!! pointee_of: what an address type points at. A type that is not one of them is
!!! the `default`, which answers int like the other unknown cases.
VarType rg_pointee_of -> VarType t {
    if t == AT_INT { return INT; }
    if t == AT_LONG { return LONG; }
    if t == AT_FLOAT { return FLOAT; }
    if t == AT_CHAR { return CHAR; }
    if t == AT_STR { return STR; }
    if t == AT_VOID { return VOID; }
    if t == AT_BOOL { return BOOL; }
    return INT;
}
