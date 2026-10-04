#once
!~
 ~  bootstrap/frontend/types.b: the front end type system.
 ~
 ~  It is the VarType enum the whole front end
 ~  shares, member for member in the same order as the toolchain one (and as the back
 ~  end's, which the two sides only have to agree on by spelling, since they talk
 ~  through the .r text).
 ~!

kind VarType {
    INT, STR, FLOAT, BOOL, CHAR, VOID,
    AT_INT, AT_FLOAT, AT_CHAR, AT_STR, AT_VOID, AT_BOOL,
    ANY, FUNC, AT_FUNC, LONG, AT_LONG
}

!!! The type of an integer constant: one that does not fit in an int is a longlong.
!!! The tokenizer keeps the whole value, so `longlong x = 6000000000;` is typed from
!!! the value and not assumed to be an int, which would drop the top half.
VarType int_literal_type -> longlong v {
    if v > 2147483647 || v < -2147483648 {
        return LONG;
    }
    return INT;
}

VarType pointer_to -> VarType t {
    if t == INT { return AT_INT; }
    if t == FLOAT { return AT_FLOAT; }
    if t == CHAR { return AT_CHAR; }
    if t == STR { return AT_STR; }
    if t == BOOL { return AT_BOOL; }
    if t == LONG { return AT_LONG; }
    !!! `@func` is the address of a function, a type of its own: reading it as
    !!! `@void` made `(@func)f` emit the plain address of `f` where the toolchain emits
    !!! the closure-object form `(CLOSURE_CODE (CLOSURE f))`, and the two images
    !!! differ in what runtime/bwin.b builds.
    if t == FUNC { return AT_FUNC; }
    return AT_VOID;
}

!!! The spelling of a type in a diagnostic, and the .r token the back end reads.
str type_name -> VarType t {
    if t == INT { return "int"; }
    if t == STR { return "str"; }
    if t == FLOAT { return "float"; }
    if t == BOOL { return "bool"; }
    if t == CHAR { return "char"; }
    if t == VOID { return "void"; }
    if t == ANY { return "any"; }
    if t == FUNC { return "func"; }
    if t == LONG { return "longlong"; }
    if t == AT_INT { return "@int"; }
    if t == AT_FLOAT { return "@float"; }
    if t == AT_CHAR { return "@char"; }
    if t == AT_STR { return "@str"; }
    if t == AT_VOID { return "@void"; }
    if t == AT_BOOL { return "@bool"; }
    if t == AT_FUNC { return "@func"; }
    return "@longlong";
}
