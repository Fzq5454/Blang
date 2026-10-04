#once
!~
 ~  bootstrap/backend/cmp_types.b: the type system of the .r compiler.
 ~
 ~  It is the backend/types together with the token kinds of
 ~  the VarType the whole backend switches on, the sizes those
 ~  types have, and CmpToken, the one token shape the .r parser reads. The enum
 ~  keeps the order enum, because the backend compares the pointer types
 ~  by range (`is_ptr_type`).
 ~!

!!! The types of the .r language: the six value types, the pointer spellings, and
!!! the remaining names after them.
kind VarType {
    INT, STR, FLOAT, BOOL, CHAR, VOID,
    AT_INT, AT_FLOAT, AT_CHAR, AT_STR, AT_VOID, AT_BOOL,
    ANY, FUNC, AT_FUNC, LONG, AT_LONG
}

!!! C-style type sizes in bytes, which is what the emitter reserves for a value.
int vt_size -> VarType t {
    if t == CHAR || t == BOOL {
        return 1;
    }
    if t == INT {
        return 4;
    }
    if t == LONG || t == FLOAT {
        return 8;
    }
    return 8;
}

!!! Size of the object a pointer points to, for pointer arithmetic `p + n`.
int vt_pointee_size -> VarType t {
    if t == AT_INT {
        return 4;
    }
    if t == AT_FLOAT || t == AT_STR || t == AT_FUNC || t == AT_LONG {
        return 8;
    }
    if t == AT_CHAR || t == AT_BOOL {
        return 1;
    }
    return 1;
}

!!! The type a pointer points at. `$p` and `p[i]` give the object itself, so the
!!! element of an `@int p` is an int and not the pointer: typing it as the pointer
!!! made `p[0] + 1` pointer arithmetic and `(str)p[0]` a reinterpretation instead of
!!! the number-to-text conversion.
VarType vt_pointee_type -> VarType t {
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
    if t == AT_STR {
        return STR;
    }
    if t == AT_BOOL {
        return BOOL;
    }
    if t == AT_FUNC {
        return AT_FUNC;
    }
    return INT;
}

!!! Whether a type is one of the `@T` spellings. the toolchain ranges over the enum
!!! (`AT_INT .. AT_BOOL`) and adds AT_LONG and AT_FUNC, which stand after it.
bool vt_is_ptr -> VarType t {
    if t == AT_INT || t == AT_FLOAT || t == AT_CHAR || t == AT_STR ||
       t == AT_VOID || t == AT_BOOL || t == AT_LONG || t == AT_FUNC {
        return true;
    }
    return false;
}

!!! The name of a type in a diagnostic.
str vt_name -> VarType t {
    if t == VOID {
        return "void";
    }
    if t == BOOL {
        return "bool";
    }
    if t == INT {
        return "int";
    }
    if t == LONG {
        return "longlong";
    }
    if t == STR {
        return "str";
    }
    if t == FLOAT {
        return "float";
    }
    if t == CHAR {
        return "char";
    }
    if t == ANY {
        return "any";
    }
    if t == AT_INT {
        return "@int";
    }
    if t == AT_FLOAT {
        return "@float";
    }
    if t == AT_CHAR {
        return "@char";
    }
    if t == AT_STR {
        return "@str";
    }
    if t == AT_VOID {
        return "@void";
    }
    if t == AT_BOOL {
        return "@bool";
    }
    if t == AT_LONG {
        return "@longlong";
    }
    if t == FUNC {
        return "func";
    }
    if t == AT_FUNC {
        return "@func";
    }
    return "unknown";
}

!!! The .r tokens, in the order enum TokenKind.
kind CmpTokKind {
    CT_EOF, CT_IDENT, CT_INTEGER, CT_FLOAT, CT_STRING, CT_CHAR,
    CT_COMMA, CT_LPAREN, CT_RPAREN, CT_LBRACE, CT_RBRACE,
    CT_OPERATOR, CT_ELLIPSIS
}

!!! One token of the .r text. the toolchain returns it by value and the parser keeps the
!!! last two; this implementation allocates one per read, the way the frontend lexer does. The
!!! kind is `tk` and not `kind`: `kind` is the keyword that declares an enum, so it
!!! can be written as a field but not read back as one.
type CmpToken {
    CmpTokKind tk;
    str text;
    int line;
    int col;
};
