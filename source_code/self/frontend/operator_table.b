#once
!~
 ~  bootstrap/frontend/operator_table.b: the frontend/operator_table.
 ~
 ~  An operator is declared inside a `type` body as
 ~
 ~      operator + -> Vec b { ... }      !!! binary: one parameter
 ~      operator - { ... }               !!! unary: no parameter
 ~
 ~  and is emitted as an ordinary method, so the whole method machinery (mangling,
 ~  inheritance lookup, generics) applies unchanged. The symbol as written and the
 ~  declared parameter count decide the name the method is emitted under.
 ~
 ~  A function answers one value, so the two answers the toolchain helpers give through an
 ~  out-parameter travel in fields here: `op_ok` says whether the symbol and count
 ~  fit, and `op_target` is the target of a conversion operator.
 ~!

#head "types"

!!! Whether the last operator_method_name found a name for the symbol and count.
bool op_ok;
!!! The target type of a conversion operator, when there is one.
str op_target;

!!! Whether two spellings are the same text. The operator names come from the source
!!! as spans, so they are compared byte by byte, the same way the parser compares
!!! every other name. It stands first because everything below asks it.
bool p_op_eq -> str a, str b {
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

str operator_method_name -> str sym, int nparams {
    op_ok = true;
    if nparams == 1 {
        if p_op_eq(sym, "+") { return "op_add"; }
        if p_op_eq(sym, "-") { return "op_sub"; }
        if p_op_eq(sym, "*") { return "op_mul"; }
        if p_op_eq(sym, "/") { return "op_div"; }
        if p_op_eq(sym, "%") { return "op_mod"; }
        if p_op_eq(sym, "==") { return "op_eq"; }
        if p_op_eq(sym, "!=") { return "op_ne"; }
        if p_op_eq(sym, "<") { return "op_lt"; }
        if p_op_eq(sym, ">") { return "op_gt"; }
        if p_op_eq(sym, "<=") { return "op_le"; }
        if p_op_eq(sym, ">=") { return "op_ge"; }
        if p_op_eq(sym, "&") { return "op_band"; }
        if p_op_eq(sym, "|") { return "op_bor"; }
        if p_op_eq(sym, "^") { return "op_bxor"; }
        if p_op_eq(sym, "<<") { return "op_shl"; }
        if p_op_eq(sym, ">>") { return "op_shr"; }
        if p_op_eq(sym, "[]") { return "op_index"; }
        op_ok = false;
        return "";
    }
    if nparams == 2 {
        !!! `a[i] = v` writes through the two-parameter form, written `[]=` or `[]`.
        if p_op_eq(sym, "[]=") || p_op_eq(sym, "[]") { return "op_index_set"; }
        op_ok = false;
        return "";
    }
    if nparams == 0 {
        if p_op_eq(sym, "-") { return "op_neg"; }
        if p_op_eq(sym, "!") { return "op_not"; }
        if p_op_eq(sym, "~") { return "op_bnot"; }
        !!! A conversion operator: `(str)v`, `(int)v`, ...
        if p_op_eq(sym, "str") { return "op_to_str"; }
        if p_op_eq(sym, "int") { return "op_to_int"; }
        if p_op_eq(sym, "float") { return "op_to_float"; }
        if p_op_eq(sym, "bool") { return "op_to_bool"; }
        if p_op_eq(sym, "char") { return "op_to_char"; }
        op_ok = false;
        return "";
    }
    op_ok = false;
    return "";
}

!!! The operators whose result has to be a condition: `int` or `bool`.
bool operator_needs_bool_result -> str sym {
    return p_op_eq(sym, "==") || p_op_eq(sym, "!=") || p_op_eq(sym, "<") ||
           p_op_eq(sym, ">") || p_op_eq(sym, "<=") || p_op_eq(sym, ">=") ||
           p_op_eq(sym, "!");
}

!!! A conversion operator: the declared return type has to be the target type.
!!! Answers false when the symbol is not a conversion operator at all.
bool operator_conversion_target -> str sym {
    op_target = "";
    if p_op_eq(sym, "str") || p_op_eq(sym, "int") || p_op_eq(sym, "float") ||
       p_op_eq(sym, "bool") || p_op_eq(sym, "char") {
        op_target = sym;
        return true;
    }
    return false;
}

!!! The name of a scalar type as a conversion writes it. False for a struct or a
!!! pointer type; the name is left in `op_scalar`.
str op_scalar;

bool scalar_type_name -> VarType t {
    op_scalar = "";
    if t == STR { op_scalar = "str"; return true; }
    if t == INT { op_scalar = "int"; return true; }
    if t == FLOAT { op_scalar = "float"; return true; }
    if t == BOOL { op_scalar = "bool"; return true; }
    if t == CHAR { op_scalar = "char"; return true; }
    return false;
}
