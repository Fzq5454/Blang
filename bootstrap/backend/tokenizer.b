#once
!~
 ~  bootstrap/backend/tokenizer.b: the .r tokenizer, this implementation of
 ~  and backend/tokenizer_lit.
 ~
 ~  the toolchain reads the text through a pair of pointers and keeps the current line and
 ~  column; this implementation keeps the same state as an offset into the text it was handed.
 ~  `next` hands back one token, `peek` answers the next one without moving the
 ~  cursor, which is what the parser's one-token lookahead is built from.
 ~!

#head "cmp_types"
#head "cmp_text"

!!! The text being read, the cursor, the position it stands at, and the first error
!!! the tokenizer found (empty while there is none).
str tk_src;
int tk_pos;
int tk_end;
int tk_line;
int tk_col;
str tk_file;
str tk_err;

void tk_start -> str src, str fname {
    tk_src = src;
    tk_pos = 0;
    tk_end = pe_len(src);
    tk_line = 1;
    tk_col = 1;
    tk_file = fname;
    tk_err = "";
}

bool tk_has_error {
    return !pe_eq(tk_err, "");
}

str tk_get_error {
    return tk_err;
}

@CmpToken tk_new -> CmpTokKind k, str text, int line, int col {
    CmpToken proto;
    @CmpToken t;
    cg_balloc(@t, size proto);
    t.tk = k;
    t.text = text;
    t.line = line;
    t.col = col;
    return t;
}

char tk_at -> int i {
    if i < 0 || i >= tk_end {
        return (char)0;
    }
    return tk_src[i];
}

void tk_advance {
    if tk_pos < tk_end {
        tk_col = tk_col + 1;
        tk_pos = tk_pos + 1;
    }
}

!!! The whitespace between two tokens, with the line and column the walk keeps in
!!! step with it.
void tk_skip_ws {
    while tk_pos < tk_end {
        char c = tk_at(tk_pos);
        if c != ' ' && c != '\t' && c != '\r' && c != '\n' {
            end;
        }
        if c == '\n' {
            tk_line = tk_line + 1;
            tk_col = 1;
        } else if c != '\r' {
            tk_col = tk_col + 1;
        }
        tk_pos = tk_pos + 1;
    }
}

@CmpToken tk_here -> CmpTokKind k, str text {
    return tk_new(k, text, tk_line, tk_col);
}

@CmpToken tk_here_at -> CmpTokKind k, str text, int saved_col {
    return tk_new(k, text, tk_line, saved_col);
}

int tk_is_digit -> char c {
    if c >= '0' && c <= '9' {
        return 1;
    }
    return 0;
}

int tk_is_alpha -> char c {
    if c >= 'a' && c <= 'z' {
        return 1;
    }
    if c >= 'A' && c <= 'Z' {
        return 1;
    }
    return 0;
}

int tk_is_alnum -> char c {
    if tk_is_alpha(c) == 1 {
        return 1;
    }
    return tk_is_digit(c);
}

int tk_is_hex -> char c {
    if tk_is_digit(c) == 1 {
        return 1;
    }
    if c >= 'a' && c <= 'f' {
        return 1;
    }
    if c >= 'A' && c <= 'F' {
        return 1;
    }
    return 0;
}

!!! The value of one hexadecimal digit, for the `\xHH` of a literal.
int tk_hex_val -> char c {
    if c >= '0' && c <= '9' {
        return (int)c - 48;
    }
    if c >= 'a' && c <= 'f' {
        return (int)c - 87;
    }
    return (int)c - 55;
}

!!! The decimal text of a hexadecimal literal, which is what the toolchain answers with
!!! `strtoll(text, nullptr, 16)` and `to_string`: the token carries the number, not
!!! the spelling. The value is built in a longlong, so 64 bits are kept.
str tk_hex_to_dec -> str hex {
    longlong v = 0;
    int i = 2;
    int n = pe_len(hex);
    while i < n {
        char c = hex[i];
        int d = 0;
        if tk_is_digit(c) == 1 {
            d = (int)c - 48;
        } else if c >= 'a' && c <= 'f' {
            d = (int)c - 97 + 10;
        } else if c >= 'A' && c <= 'F' {
            d = (int)c - 65 + 10;
        }
        v = v * 16 + d;
        i = i + 1;
    }
    return (str)v;
}

!!! A string literal, with the escape sequences of the .r text resolved.
@CmpToken tk_read_string {
    int sc = tk_col;
    tk_advance();
    str val = "";
    while tk_pos < tk_end {
        char c = tk_at(tk_pos);
        if c == '"' || c == '\n' {
            skip;
        }
        if c == '\\' && tk_pos + 1 < tk_end {
            tk_advance();
            char e = tk_at(tk_pos);
            !!! `\xHH` first - one or more hexadecimal digits - and then `\ooo`: they
            !!! are the spellings the front end writes for a byte it cannot put in the
            !!! text, and `\0` is the one-digit case of the octal one.
            if e == 'x' && tk_is_hex(tk_at(tk_pos + 1)) {
                tk_advance();
                int xv = 0;
                while tk_pos < tk_end && tk_is_hex(tk_at(tk_pos)) {
                    xv = xv * 16 + tk_hex_val(tk_at(tk_pos));
                    tk_advance();
                }
                val = pe_add_ch(val, (char)(xv & 255));
                continue;
            }
            if e >= '0' && e <= '7' {
                int ov = 0;
                int on = 0;
                while tk_pos < tk_end && on < 3 && tk_at(tk_pos) >= '0' && tk_at(tk_pos) <= '7' {
                    ov = ov * 8 + ((int)tk_at(tk_pos) - 48);
                    tk_advance();
                    on = on + 1;
                }
                val = pe_add_ch(val, (char)ov);
                continue;
            }
            if e == 'n' {
                val = val + "\n";
            } else if e == 't' {
                val = val + "\t";
            } else if e == 'r' {
                val = val + "\r";
            } else if e == '\\' {
                val = pe_add_ch(val, '\\');
            } else if e == '"' {
                val = pe_add_ch(val, '"');
            } else {
                val = pe_add_ch(val, e);
            }
        } else {
            val = pe_add_ch(val, c);
        }
        tk_advance();
    }
    if tk_pos >= tk_end || tk_at(tk_pos) != '"' {
        tk_err = tk_file + ":" + (str)tk_line + ":" + (str)sc +
                 ": error: unterminated string literal";
        return tk_here(CT_EOF, "");
    }
    tk_advance();
    return tk_here_at(CT_STRING, val, sc);
}

!!! A character literal, which the token carries as its number in decimal.
@CmpToken tk_read_char {
    int sc = tk_col;
    tk_advance();
    int val = 0;
    if tk_pos >= tk_end {
        tk_err = tk_file + ":" + (str)tk_line + ":" + (str)sc +
                 ": error: unterminated char literal";
        return tk_here(CT_EOF, "");
    }
    char c = tk_at(tk_pos);
    if c == '\\' && tk_pos + 1 < tk_end {
        tk_advance();
        char e = tk_at(tk_pos);
        !!! `\xHH` first - one or more hexadecimal digits - and then `\ooo`: the front
        !!! end writes a character outside the printable range as `'\342'`, and reading
        !!! only the first digit took `3` and then left the rest of the escape standing
        !!! where the closing quote belongs.
        if e == 'x' && tk_is_hex(tk_at(tk_pos + 1)) {
            tk_advance();
            int xv = 0;
            while tk_pos < tk_end && tk_is_hex(tk_at(tk_pos)) {
                xv = xv * 16 + tk_hex_val(tk_at(tk_pos));
                tk_advance();
            }
            val = xv & 255;
        } else if e >= '0' && e <= '7' {
            int ov = 0;
            int on = 0;
            while tk_pos < tk_end && on < 3 && tk_at(tk_pos) >= '0' && tk_at(tk_pos) <= '7' {
                ov = ov * 8 + ((int)tk_at(tk_pos) - 48);
                tk_advance();
                on = on + 1;
            }
            val = ov;
        } else {
            if e == 'n' {
                val = 10;
            } else if e == 't' {
                val = 9;
            } else if e == 'r' {
                val = 13;
            } else if e == '\\' {
                val = 92;
            } else if e == '\'' {
                val = 39;
            } else {
                val = (int)e;
            }
            tk_advance();
        }
    } else {
        val = (int)c;
        if val < 0 {
            val = val + 256;
        }
        tk_advance();
    }
    if tk_pos >= tk_end || tk_at(tk_pos) != '\'' {
        tk_err = tk_file + ":" + (str)tk_line + ":" + (str)sc +
                 ": error: unterminated char literal";
        return tk_here(CT_EOF, "");
    }
    tk_advance();
    return tk_here_at(CT_CHAR, (str)val, sc);
}

@CmpToken tk_read_ident {
    int sc = tk_col;
    !!! The run is measured first and copied into one block.
    !!!
    !!! Adding the characters one at a time built the whole text again for every
    !!! character it took (`s + c` copies what is already there), so reading a name
    !!! was quadratic in its length and the tokenizer was most of the parse. On
    !!! bootstrap/blang.b: 332k tokens, 800k character appends.
    int start = tk_pos;
    int n = 0;
    while tk_pos < tk_end {
        char c = tk_at(tk_pos);
        if tk_is_alnum(c) == 0 && c != '_' {
            skip;
        }
        tk_advance();
        n = n + 1;
    }
    @void cell;
    cg_balloc(@cell, n + 1);
    @char d = (@char)cell;
    int i = 0;
    while i < n {
        d[i] = tk_src[start + i];
        i = i + 1;
    }
    d[n] = (char)0;
    return tk_here_at(CT_IDENT, (str)cell, sc);
}

@CmpToken tk_read_hex {
    int sc = tk_col;
    tk_advance();
    tk_advance();
    str val = "0x";
    while tk_pos < tk_end && tk_is_hex(tk_at(tk_pos)) == 1 {
        val = pe_add_ch(val, tk_at(tk_pos));
        tk_advance();
    }
    return tk_here_at(CT_INTEGER, tk_hex_to_dec(val), sc);
}

@CmpToken tk_read_number {
    int sc = tk_col;
    bool negative = false;
    if tk_at(tk_pos) == '-' {
        negative = true;
        tk_advance();
    }
    bool isf = false;
    str val = "";
    while tk_pos < tk_end {
        char c = tk_at(tk_pos);
        if tk_is_digit(c) == 0 && c != '.' {
            skip;
        }
        if c == '.' {
            if isf {
                skip;
            }
            isf = true;
        }
        val = pe_add_ch(val, c);
        tk_advance();
    }
    !!! Exponent: `1e+18`, `2.5E-3`. A number spelled with one is a float even when
    !!! it has no '.', which is how the frontend writes a value that would need too
    !!! many digits otherwise (`%.17g`).
    char ec = tk_at(tk_pos);
    if (ec == 'e' || ec == 'E') && val != "" {
        int q = tk_pos + 1;
        char qc = tk_at(q);
        if qc == '+' || qc == '-' {
            q = q + 1;
            qc = tk_at(q);
        }
        if tk_is_digit(qc) == 1 {
            isf = true;
            val = pe_add_ch(val, 'e');
            tk_advance();
            char sc2 = tk_at(tk_pos);
            if sc2 == '+' || sc2 == '-' {
                val = pe_add_ch(val, sc2);
                tk_advance();
            }
            while tk_pos < tk_end && tk_is_digit(tk_at(tk_pos)) == 1 {
                val = pe_add_ch(val, tk_at(tk_pos));
                tk_advance();
            }
        }
    }
    CmpTokKind k = CT_INTEGER;
    if isf {
        k = CT_FLOAT;
    }
    str text = val;
    if negative {
        text = "-" + val;
    }
    return tk_here_at(k, text, sc);
}

@CmpToken tk_next {
    tk_skip_ws();
    if tk_pos >= tk_end {
        return tk_here(CT_EOF, "");
    }
    char c = tk_at(tk_pos);
    if c == '{' {
        int sc = tk_col;
        tk_advance();
        return tk_here_at(CT_LBRACE, "{", sc);
    }
    if c == '}' {
        int sc = tk_col;
        tk_advance();
        return tk_here_at(CT_RBRACE, "}", sc);
    }
    if c == ',' {
        int sc = tk_col;
        tk_advance();
        return tk_here_at(CT_COMMA, ",", sc);
    }
    if c == '(' {
        int sc = tk_col;
        tk_advance();
        return tk_here_at(CT_LPAREN, "(", sc);
    }
    if c == ')' {
        int sc = tk_col;
        tk_advance();
        return tk_here_at(CT_RPAREN, ")", sc);
    }
    !!! `...` before the individual operators.
    if c == '.' && tk_at(tk_pos + 1) == '.' && tk_at(tk_pos + 2) == '.' {
        int sc = tk_col;
        tk_advance();
        tk_advance();
        tk_advance();
        return tk_here_at(CT_ELLIPSIS, "...", sc);
    }
    !!! The multi-character operators, longest match first.
    if c == '<' && tk_at(tk_pos + 1) == '/' && tk_at(tk_pos + 2) == '/' {
        int sc = tk_col;
        tk_advance();
        tk_advance();
        tk_advance();
        return tk_here_at(CT_OPERATOR, "<//", sc);
    }
    if c == '/' && tk_at(tk_pos + 1) == '/' {
        if tk_at(tk_pos + 2) == '=' {
            int sc = tk_col;
            tk_advance();
            tk_advance();
            tk_advance();
            return tk_here_at(CT_OPERATOR, "//=", sc);
        }
        int sc = tk_col;
        tk_advance();
        tk_advance();
        return tk_here_at(CT_OPERATOR, "//", sc);
    }
    if c == '\\' && tk_at(tk_pos + 1) == '\\' {
        int sc = tk_col;
        tk_advance();
        tk_advance();
        return tk_here_at(CT_OPERATOR, "\\\\", sc);
    }
    if c == '&' && tk_at(tk_pos + 1) == '&' {
        int sc = tk_col;
        tk_advance();
        tk_advance();
        return tk_here_at(CT_OPERATOR, "&&", sc);
    }
    if c == '&' {
        int sc = tk_col;
        tk_advance();
        return tk_here_at(CT_OPERATOR, "&", sc);
    }
    if c == '|' && tk_at(tk_pos + 1) == '|' {
        int sc = tk_col;
        tk_advance();
        tk_advance();
        return tk_here_at(CT_OPERATOR, "||", sc);
    }
    if c == '\\' {
        int sc = tk_col;
        tk_advance();
        return tk_here_at(CT_OPERATOR, "\\", sc);
    }
    if c == '<' && tk_at(tk_pos + 1) == '<' {
        int sc = tk_col;
        tk_advance();
        tk_advance();
        return tk_here_at(CT_OPERATOR, "<<", sc);
    }
    if c == '>' && tk_at(tk_pos + 1) == '>' {
        int sc = tk_col;
        tk_advance();
        tk_advance();
        return tk_here_at(CT_OPERATOR, ">>", sc);
    }
    if c == '<' || c == '>' {
        int sc = tk_col;
        tk_advance();
        return tk_here_at(CT_OPERATOR, pe_char(c), sc);
    }
    if c == '+' && tk_at(tk_pos + 1) == '+' {
        int sc = tk_col;
        tk_advance();
        tk_advance();
        return tk_here_at(CT_OPERATOR, "++", sc);
    }
    if c == '+' && tk_at(tk_pos + 1) == '=' {
        int sc = tk_col;
        tk_advance();
        tk_advance();
        return tk_here_at(CT_OPERATOR, "+=", sc);
    }
    if c == '-' && tk_at(tk_pos + 1) == '-' {
        int sc = tk_col;
        tk_advance();
        tk_advance();
        return tk_here_at(CT_OPERATOR, "--", sc);
    }
    if c == '-' && tk_at(tk_pos + 1) == '=' {
        int sc = tk_col;
        tk_advance();
        tk_advance();
        return tk_here_at(CT_OPERATOR, "-=", sc);
    }
    if c == '*' && tk_at(tk_pos + 1) == '=' {
        int sc = tk_col;
        tk_advance();
        tk_advance();
        return tk_here_at(CT_OPERATOR, "*=", sc);
    }
    if c == '/' && tk_at(tk_pos + 1) == '=' {
        int sc = tk_col;
        tk_advance();
        tk_advance();
        return tk_here_at(CT_OPERATOR, "/=", sc);
    }
    if c == '%' {
        int sc = tk_col;
        tk_advance();
        return tk_here_at(CT_OPERATOR, "%", sc);
    }
    if c == '|' {
        int sc = tk_col;
        tk_advance();
        return tk_here_at(CT_OPERATOR, "|", sc);
    }
    if c == '^' {
        int sc = tk_col;
        tk_advance();
        return tk_here_at(CT_OPERATOR, "^", sc);
    }
    if c == '~' {
        int sc = tk_col;
        tk_advance();
        return tk_here_at(CT_OPERATOR, "~", sc);
    }
    if c == '$' {
        int sc = tk_col;
        tk_advance();
        return tk_here_at(CT_OPERATOR, "$", sc);
    }
    !!! A negative number literal: -0.5, -3, -0x1A.
    if c == '-' && (tk_is_digit(tk_at(tk_pos + 1)) == 1 || tk_at(tk_pos + 1) == '.') {
        if tk_at(tk_pos + 1) == '0' {
            char c2 = tk_at(tk_pos + 2);
            if c2 == 'x' || c2 == 'X' {
                tk_advance();
                @CmpToken t = tk_read_hex();
                t.text = "-" + t.text;
                return t;
            }
        }
        return tk_read_number();
    }
    if c == '+' || c == '-' || c == '*' || c == '/' || c == '=' {
        int sc = tk_col;
        tk_advance();
        return tk_here_at(CT_OPERATOR, pe_char(c), sc);
    }
    if c == '@' {
        int sc = tk_col;
        tk_advance();
        return tk_here_at(CT_OPERATOR, "@", sc);
    }
    if c == '?' {
        int sc = tk_col;
        tk_advance();
        return tk_here_at(CT_OPERATOR, "?", sc);
    }
    if c == ':' && tk_at(tk_pos + 1) == ':' {
        int sc = tk_col;
        tk_advance();
        tk_advance();
        return tk_here_at(CT_OPERATOR, "::", sc);
    }
    if c == ':' {
        int sc = tk_col;
        tk_advance();
        return tk_here_at(CT_OPERATOR, ":", sc);
    }
    if c == '"' {
        return tk_read_string();
    }
    if c == '\'' {
        return tk_read_char();
    }
    if tk_is_alpha(c) == 1 || c == '_' {
        return tk_read_ident();
    }
    if c == '0' {
        char c2 = tk_at(tk_pos + 1);
        if c2 == 'x' || c2 == 'X' {
            return tk_read_hex();
        }
    }
    if tk_is_digit(c) == 1 || (c == '.' && tk_is_digit(tk_at(tk_pos + 1)) == 1) {
        return tk_read_number();
    }
    tk_err = tk_file + ":" + (str)tk_line + ":" + (str)tk_col +
             ": error: unexpected character '" + pe_char(c) + "'";
    return tk_here(CT_EOF, "");
}

!!! The next token without moving the cursor: the state is saved, the token is read
!!! and the state is put back.
@CmpToken tk_peek {
    int sp = tk_pos;
    int sl = tk_line;
    int sc = tk_col;
    str se = tk_err;
    @CmpToken t = tk_next();
    tk_pos = sp;
    tk_line = sl;
    tk_col = sc;
    tk_err = se;
    return t;
}
