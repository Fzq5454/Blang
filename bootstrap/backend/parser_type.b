#once
!~
 ~  bootstrap/backend/parser_type.b: the .r type spelling and the ENUM statement.
 ~
 ~  It is the backend/parser_enum. the toolchain answers the type through two
 ~  reference parameters; here the answer stands in the two globals below, and the
 ~  caller advances past the token the way the toolchain does.
 ~!

#head "parser"

!!! What `cp_parse_r_type` answers: the type and the pointer depth it read.
VarType cp_rtype_type;
int cp_rtype_depth;

!!! ENUM <name> ( ... ): the enumerators are counted by the frontend, so the
!!! backend only has to step over them.
void cp_parse_enum {
    cp_advance();
    if cp_cur.tk != CT_IDENT {
        cp_error("expected enum name");
        end;
    }
    cp_advance();
    if cp_cur.tk != CT_LPAREN {
        cp_error("expected '('");
        end;
    }
    cp_advance();
    while cp_cur.tk != CT_EOF && cp_cur.tk != CT_RPAREN {
        cp_advance();
    }
    if cp_cur.tk != CT_RPAREN {
        cp_error("expected ')'");
        end;
    }
    cp_advance();
}

!!! A type of the .r language: `INT`, `AT_INT`, `AT2_INT` (two pointer levels) and
!!! the rest of the spellings the frontend writes. `AT` and the digits after it are
!!! the depth; without digits it is one.
bool cp_parse_r_type {
    cp_rtype_depth = 0;
    str t = cp_cur.text;
    int n = pe_len(t);
    if n >= 2 && t[0] == 'A' && t[1] == 'T' {
        int pos = 2;
        int depth = 0;
        while pos < n && tk_is_digit(t[pos]) == 1 {
            depth = depth * 10 + ((int)t[pos] - 48);
            pos = pos + 1;
        }
        if depth == 0 {
            depth = 1;
        }
        str base = t;
        if pos < n && t[pos] == '_' {
            base = pe_sub_to_end(t, pos + 1);
        } else {
            base = pe_sub_to_end(t, pos);
        }
        cp_rtype_depth = depth;
        if pe_eq(base, "INT") {
            cp_rtype_type = AT_INT;
        } else if pe_eq(base, "LONG") {
            cp_rtype_type = AT_LONG;
        } else if pe_eq(base, "FLOAT") {
            cp_rtype_type = AT_FLOAT;
        } else if pe_eq(base, "CHAR") {
            cp_rtype_type = AT_CHAR;
        } else if pe_eq(base, "STR") {
            cp_rtype_type = AT_STR;
        } else if pe_eq(base, "VOID") {
            cp_rtype_type = AT_VOID;
        } else if pe_eq(base, "BOOL") {
            cp_rtype_type = AT_BOOL;
        } else if pe_eq(base, "FUNC") {
            cp_rtype_type = AT_FUNC;
        } else {
            return false;
        }
        return true;
    }
    if pe_eq(t, "INT") {
        cp_rtype_type = INT;
    } else if pe_eq(t, "LONG") {
        cp_rtype_type = LONG;
    } else if pe_eq(t, "STR") {
        cp_rtype_type = STR;
    } else if pe_eq(t, "FLOAT") {
        cp_rtype_type = FLOAT;
    } else if pe_eq(t, "BOOL") {
        cp_rtype_type = BOOL;
    } else if pe_eq(t, "CHAR") {
        cp_rtype_type = CHAR;
    } else if pe_eq(t, "VOID") {
        cp_rtype_type = VOID;
    } else if pe_eq(t, "ANY") {
        cp_rtype_type = ANY;
    } else if pe_eq(t, "FUNC") {
        cp_rtype_type = FUNC;
    } else {
        return false;
    }
    return true;
}
