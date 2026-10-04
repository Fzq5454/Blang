#once
!~
 ~  bootstrap/lexer.b: the tokenizer of the self-hosted front end.
 ~
 ~  This is the first module of the frontend/lexer to blang itself. It
 ~  keeps the same token kinds, the same keyword list and the same literal rules as
 ~  the toolchain version, so the .r its caller produces can be compared against what
 ~  bin/blang.exe writes today (`blang.exe x.b -R`).
 ~
 ~  One deliberate difference: the toolchain tokenizer copies every spelling into a
 ~  str, while this one keeps a span into the source (start/end byte
 ~  offsets) and materializes text only when it has to print something. That is
 ~  what a front end that later has to name template instances wants anyway, and it
 ~  keeps this module free of string allocation for now.
 ~
 ~  Build:
 ~    blang.exe bootstrap/lexer.b -o bootstrap/lexer.exe -dbrtm -dbprintf -system kernel32
 ~  Run (the path is typed, or piped in):
 ~    "hello.b" | bootstrap/lexer.exe
 ~!

#head "stdsrt"
#head "fileio"
#head "lexer_heads"
#head "preprocessor_heads"
#head "Chinese/chinese_heads"

!!! ---- token kinds (frontend/lexer, unchanged) ----

kind TokenKind {
    TK_EOF, TK_IDENT, TK_INTEGER, TK_FLOAT, TK_STRING,
    TK_COMMA, TK_LPAREN, TK_RPAREN, TK_SEMI, TK_ASSIGN, TK_DOT,
    TK_LBRACE, TK_RBRACE,
    TK_PLUS, TK_MINUS, TK_STAR, TK_SLASH,
    TK_EQ, TK_NE, TK_AND, TK_OR, TK_NOT,
    TK_LT, TK_GT, TK_LE, TK_GE,
    TK_KEYWORD, TK_CHAR, TK_SCOPE,
    TK_LBRACKET, TK_RBRACKET,
    TK_AT,
    TK_ELLIPSIS,
    TK_REF,
    TK_PLUS_PLUS, TK_MINUS_MINUS,
    TK_MOD,
    TK_QMARK, TK_COLON,
    TK_BITAND, TK_BITOR, TK_BITXOR, TK_BITNOT,
    TK_SHL, TK_SHR,
    TK_COMPOUND_ASSIGN,
    TK_ARROW
}

type Token {
    TokenKind tk;
    int start;
    int stop;
    int line;
    int col;
    bool is_long;
    longlong value;
};

!!! ---- the source being scanned ----

@char g_base;
@char g_p;
int g_left;
!!! The line is 1-based and so is the column: the compiler's diagnostics print
!!! `file:line:col`, and a diagnostic that says column 0 for the first character of
!!! a line would not be the same text as the compiler's.
int g_line;
int g_col;
int g_at;
int g_diags;
!!! Where each line of the source starts, in bytes from g_base. A diagnostic has to
!!! print the line an error is on, and the scanner is the only part that saw the
!!! text, so it records the offsets while it runs. The table grows with the source:
!!! it was a fixed array of 65536 entries, which is a limit a big file would have
!!! hit silently, and `vector` is what the runtime now offers for that.
#head "vector"

vector(int) g_line_off;
!!! The length of the whole source. `g_left` counts what is still ahead of the
!!! cursor and shrinks as the scanner runs, so it cannot bound a walk over a line
!!! that has already been passed: reading the text of line 2 while the parser
!!! stands in the middle of it stopped at the cursor instead of at the end of the
!!! line, and the diagnostic printed one blank character where the source line
!!! should be.
int g_src_len;
!!! The file the source came from. Every diagnostic names it, and the scanner is
!!! the part that knows where it is in the text - the toolchain tokenizer keeps the name
!!! per token because a `#head` file shifts the lines; with one file per scan the
!!! name belongs to the scan.
str g_file;

void adv {
    g_p = g_p + 1;
    g_left = g_left - 1;
    g_col = g_col + 1;
    g_at = g_at + 1;
}

char cur {
    return $g_p;
}

bool at_end {
    return g_left <= 0;
}

char peek -> int n {
    if n >= g_left {
        return (char)0;
    }
    return g_p[n];
}

bool is_digit -> char c {
    if c >= '0' && c <= '9' {
        return true;
    }
    return false;
}

bool is_hex_digit -> char c {
    if is_digit(c) {
        return true;
    }
    if c >= 'a' && c <= 'f' {
        return true;
    }
    if c >= 'A' && c <= 'F' {
        return true;
    }
    return false;
}

bool is_ident_start -> char c {
    if c >= 'a' && c <= 'z' {
        return true;
    }
    if c >= 'A' && c <= 'Z' {
        return true;
    }
    if c == '_' {
        return true;
    }
    return false;
}

bool is_ident_char -> char c {
    if is_ident_start(c) {
        return true;
    }
    return is_digit(c);
}

bool is_blank -> char c {
    if c == ' ' {
        return true;
    }
    if c == '\t' {
        return true;
    }
    if c == '\r' {
        return true;
    }
    if c == '\n' {
        return true;
    }
    return false;
}

!!! ---- spelling helpers: a token is a span, not a copy ----

bool span_eq -> int from, int to, str lit {
    @char a = g_base + from;
    @char q = (@char)lit;
    int i = from;
    while i < to {
        if $q == (char)0 {
            return false;
        }
        if $a != $q {
            return false;
        }
        a = a + 1;
        q = q + 1;
        i = i + 1;
    }
    return $q == (char)0;
}

int span_len -> str s {
    @char q = (@char)s;
    int n = 0;
    while $q != (char)0 {
        q = q + 1;
        n = n + 1;
    }
    return n;
}

!!! A copy of a span, as a string of its own. The tokenizer keeps spellings as
!!! spans and never copies one, but a name the parser has to remember (a variable,
!!! a field, the value of a string literal) has to be materialized somewhere: this
!!! is that place, and it is the only allocation the lexer makes.
str span_text -> int from, int to {
    int n = to - from;
    @void cell;
    malloc(@cell, n + 1);
    if cell == null {
        return (str)null;
    }
    @char d = (@char)cell;
    @char s = g_base + from;
    int i = 0;
    while i < n {
        d[i] = s[i];
        i = i + 1;
    }
    d[n] = (char)0;
    return (str)cell;
}

!!! ---- keywords (frontend/lexer, the same list) ----

!!! The list is one literal, walked word by word. Fifty separate literals made
!!! this program's image large enough to stop running, and a table costs one.
str kw_text = "int str float bool char longlong true false kind type any size count if else elif while skip do continue void return end null switch case unmatch func back local stub package use rcode etc reload operator ref const static utype introduce attribute rule TYPENAME TEMPLATE ARGS try exception throw BLANG_API __badd __bcall __bfree __get_built_in_func";

!!! The list read into a table the first time a keyword is looked for: where each
!!! word starts in the literal, how long it is and what it starts with. Reading the
!!! literal per identifier meant reading every keyword's spelling - fifty words of
!!! six characters, a scan of four hundred bytes - to answer a name that is not a
!!! keyword, and that is what most identifiers in a source file are. The length and
!!! the first character are what tells a word from a name: with them in the table,
!!! the bytes of a keyword are read only when an identifier can still match it.
@longlong kw_off;
@longlong kw_len;
@char kw_chr;
int kw_count;
bool kw_ready;

void kw_build {
    int cap = 96;
    @void cell;
    malloc(@cell, cap * 8);
    kw_off = (@longlong)cell;
    malloc(@cell, cap * 8);
    kw_len = (@longlong)cell;
    malloc(@cell, cap);
    kw_chr = (@char)cell;
    @char base = (@char)kw_text;
    @char q = base;
    while $q != (char)0 {
        if $q == ' ' {
            q = q + 1;
        } else {
            @char w = q;
            int len = 0;
            while $w != (char)0 && $w != ' ' {
                w = w + 1;
                len = len + 1;
            }
            if kw_count < cap {
                kw_off[kw_count] = (longlong)((int)q - (int)base);
                kw_len[kw_count] = (longlong)len;
                kw_chr[kw_count] = $q;
                kw_count = kw_count + 1;
            }
            q = w;
        }
    }
    kw_ready = true;
}

bool is_keyword -> int from, int to {
    if !kw_ready {
        kw_build();
    }
    int n = to - from;
    if n <= 0 {
        return false;
    }
    @char a = g_base + from;
    char c0 = a[0];
    int i = 0;
    while i < kw_count {
        if (int)kw_len[i] == n && kw_chr[i] == c0 {
            @char b = (@char)kw_text + (int)kw_off[i];
            int j = 0;
            while j < n {
                if a[j] != b[j] {
                    skip;
                }
                j = j + 1;
            }
            if j == n {
                return true;
            }
        }
        i = i + 1;
    }
    return false;
}

str kind_name -> TokenKind k {
    !!! The names of the kinds in TokenKind order.
    if k == TK_EOF { return "EOF"; }
    if k == TK_IDENT { return "IDENT"; }
    if k == TK_INTEGER { return "INTEGER"; }
    if k == TK_FLOAT { return "FLOAT"; }
    if k == TK_STRING { return "STRING"; }
    if k == TK_COMMA { return "COMMA"; }
    if k == TK_LPAREN { return "LPAREN"; }
    if k == TK_RPAREN { return "RPAREN"; }
    if k == TK_SEMI { return "SEMI"; }
    if k == TK_ASSIGN { return "ASSIGN"; }
    if k == TK_DOT { return "DOT"; }
    if k == TK_LBRACE { return "LBRACE"; }
    if k == TK_RBRACE { return "RBRACE"; }
    if k == TK_PLUS { return "PLUS"; }
    if k == TK_MINUS { return "MINUS"; }
    if k == TK_STAR { return "STAR"; }
    if k == TK_SLASH { return "SLASH"; }
    if k == TK_EQ { return "EQ"; }
    if k == TK_NE { return "NE"; }
    if k == TK_AND { return "AND"; }
    if k == TK_OR { return "OR"; }
    if k == TK_NOT { return "NOT"; }
    if k == TK_LT { return "LT"; }
    if k == TK_GT { return "GT"; }
    if k == TK_LE { return "LE"; }
    if k == TK_GE { return "GE"; }
    if k == TK_KEYWORD { return "KEYWORD"; }
    if k == TK_CHAR { return "CHAR"; }
    if k == TK_SCOPE { return "SCOPE"; }
    if k == TK_LBRACKET { return "LBRACKET"; }
    if k == TK_RBRACKET { return "RBRACKET"; }
    if k == TK_AT { return "AT"; }
    if k == TK_ELLIPSIS { return "ELLIPSIS"; }
    if k == TK_REF { return "REF"; }
    if k == TK_PLUS_PLUS { return "PLUS_PLUS"; }
    if k == TK_MINUS_MINUS { return "MINUS_MINUS"; }
    if k == TK_MOD { return "MOD"; }
    if k == TK_QMARK { return "QMARK"; }
    if k == TK_COLON { return "COLON"; }
    if k == TK_BITAND { return "BITAND"; }
    if k == TK_BITOR { return "BITOR"; }
    if k == TK_BITXOR { return "BITXOR"; }
    if k == TK_BITNOT { return "BITNOT"; }
    if k == TK_SHL { return "SHL"; }
    if k == TK_SHR { return "SHR"; }
    if k == TK_COMPOUND_ASSIGN { return "COMPOUND_ASSIGN"; }
    return "ARROW";
}

!!! ---- comments ----

bool skip_line_comment {
    !!! Three bangs to the end of the line.
    if cur() == '!' && peek(1) == '!' && peek(2) == '!' {
        while !at_end() {
            if cur() == '\n' {
                return true;
            }
            adv();
        }
        return true;
    }
    return false;
}

bool skip_block_comment {
    !!! The !~ ... ~! form, as the archive files use.
    if cur() == '!' && peek(1) == '~' {
        adv();
        adv();
        while !at_end() {
            if cur() == '~' && peek(1) == '!' {
                adv();
                adv();
                return true;
            }
            if cur() == '\n' {
                g_line = g_line + 1;
                g_col = 0;
            }
            adv();
        }
        return true;
    }
    return false;
}

!!! ---- literals ----

!!! The digits of an integer. `sc` and `from` are where the whole spelling starts -
!!! for `0x1f` that is the `0`, not the first digit - because a message about it has
!!! to point at the constant the reader wrote.
longlong read_digits -> int base, int sc, int from {
    utype longlong v = 0;
    while !at_end() {
        char c = (char)cur();
        int d = -1;
        if is_digit(c) {
            d = (int)c - (int)'0';
        } else if base == 16 {
            if c >= 'a' && c <= 'f' {
                d = (int)c - (int)'a' + 10;
            } else if c >= 'A' && c <= 'F' {
                d = (int)c - (int)'A' + 10;
            }
        }
        if d < 0 {
            skip;
        }
        if d >= base {
            skip;
        }
        !!! The bits are what the constant is, and a spelling wider than 64 of them
        !!! saturates at all ones: that is what strtoull answers the toolchain reader and
        !!! the toolchain reader does not report it, so `0x1FFFFFFFFFFFFFFFF` is the -1
        !!! pattern like every other over-wide hex constant. The rest of the
        !!! spelling is still taken, so the tokens after the number start where
        !!! they should.
        utype longlong maxv = (utype longlong)0 - (utype longlong)1;
        if v > (maxv - (utype longlong)d) / (utype longlong)base {
            v = maxv;
            while !at_end() {
                char c2 = (char)cur();
                if is_hex_digit(c2) {
                    adv();
                    continue;
                }
                skip;
            }
            return (longlong)v;
        }
        v = v * (utype longlong)base + (utype longlong)d;
        adv();
    }
    return (longlong)v;
}

!!! The decimal spelling of a number, which was already consumed, re-read from its
!!! span. A value that needs more than 64 bits is reported and read as 0, the way
!!! the toolchain reader treats the constant whose conversion overflowed.
longlong read_number_decimal -> int from, int to, int sc {
    utype longlong v = 0;
    @char a = g_base + from;
    int i = from;
    bool too_big = false;
    while i < to {
        utype longlong d = (utype longlong)((int)$a - (int)'0');
        utype longlong maxv = (utype longlong)0 - (utype longlong)1;
        if v > (maxv - d) / 10 {
            too_big = true;
            v = 0;
            skip;
        }
        v = v * 10 + d;
        a = a + 1;
        i = i + 1;
    }
    if too_big {
        lex_error_at(g_line, sc, to - from, "integer constant is too large");
    }
    return (longlong)v;
}

Token read_number {
    Token t;
    int sc = g_col;
    int from = g_at;
    if cur() == '0' && (peek(1) == 'x' || peek(1) == 'X') {
        adv();
        adv();
        utype longlong uv = (utype longlong)read_digits(16, sc, from);
        int to = g_at;
        t.tk = TK_INTEGER;
        t.start = from;
        t.stop = to;
        t.line = g_line;
        t.col = sc;
        !!! A hex constant that needs more than 32 bits keeps all 64 of them; one
        !!! that fits in 32 is the int that pattern spells read as signed.
        !!!
        !!! The bound is 2^32 and it is held in a variable of its own. Written
        !!! beside the comparison instead, both spellings go wrong: `4294967295` is
        !!! the int -1 as a bit pattern, so `uv > -1` is false for every uv and the
        !!! top half of `0x140000000` was dropped, and `4294967296` is narrowed to
        !!! its low 32 bits by the cast a comparison of `utype` operands makes, so
        !!! `uv >= 0` is true for every uv. the toolchain writes `0xFFFFFFFFULL`, which
        !!! has no such reading to worry about.
        utype longlong two32 = 4294967296;
        t.is_long = uv >= two32;
        if t.is_long {
            t.value = (longlong)uv;
        } else {
            !!! A hex constant is a bit pattern: 32 bits of it read as the int they
            !!! spell, so 0xC0000040 is -1073741760 and 0xFFFFFFFF is -1.
            t.value = (longlong)(int)uv;
        }
        return t;
    }
    bool is_float = false;
    while !at_end() {
        if cur() == '.' {
            if is_float {
                skip;
            }
            is_float = true;
            adv();
            continue;
        }
        if is_digit(cur()) {
            adv();
            continue;
        }
        skip;
    }
    int to = g_at;
    t.tk = TK_INTEGER;
    if is_float {
        t.tk = TK_FLOAT;
    }
    t.start = from;
    t.stop = to;
    t.line = g_line;
    t.col = sc;
    if !is_float {
        utype longlong uv = (utype longlong)read_number_decimal(from, to, sc);
        t.value = (longlong)uv;
        t.is_long = uv > 2147483647;
    }
    return t;
}

Token read_string {
    Token t;
    int sc = g_col;
    int from = g_at;
    adv();
    bool closed = false;
    while !at_end() {
        char c = (char)cur();
        if c == '\\' {
            adv();
            if at_end() {
                skip;
            }
            adv();
            continue;
        }
        if c == '"' {
            adv();
            closed = true;
            skip;
        }
        if c == '\n' {
            skip;
        }
        adv();
    }
    if !closed {
        lex_error_at(g_line, sc, 1, "unterminated string");
    }
    t.tk = TK_STRING;
    t.start = from;
    t.stop = g_at;
    t.line = g_line;
    t.col = sc;
    return t;
}

Token read_char {
    Token t;
    int sc = g_col;
    int from = g_at;
    adv();
    if !at_end() && cur() == '\\' {
        adv();
        if !at_end() {
            !!! `\xHH` - one or more hexadecimal digits - and `\ooo` - up to three
            !!! octal ones - belong to the escape, the way the toolchain reader takes them.
            !!! Skipping one character left the remaining digits standing where the
            !!! closing quote belongs, so `'\x41'` and `'\033'` - how a character
            !!! outside the printable range is written - were reported as unterminated.
            if cur() == 'x' && is_hex_digit(peek(1)) {
                adv();
                while !at_end() && is_hex_digit(cur()) {
                    adv();
                }
            } else if cur() >= '0' && cur() <= '7' {
                int on = 0;
                while !at_end() && on < 3 && cur() >= '0' && cur() <= '7' {
                    adv();
                    on = on + 1;
                }
            } else {
                adv();
            }
        }
    } else if !at_end() {
        adv();
    }
    if at_end() || cur() != '\'' {
        lex_error_at(g_line, sc, 1, "unterminated char literal");
    } else {
        adv();
    }
    t.tk = TK_CHAR;
    t.start = from;
    t.stop = g_at;
    t.line = g_line;
    t.col = sc;
    return t;
}

Token read_ident {
    Token t;
    int sc = g_col;
    int from = g_at;
    while !at_end() && is_ident_char(cur()) {
        adv();
    }
    int to = g_at;
    t.start = from;
    t.stop = to;
    t.line = g_line;
    t.col = sc;
    if is_keyword(from, to) {
        t.tk = TK_KEYWORD;
    } else {
        t.tk = TK_IDENT;
    }
    return t;
}

!!! ---- operators, longest match first ----

Token make -> TokenKind k, int from, int sc {
    Token t;
    t.tk = k;
    t.start = from;
    t.stop = g_at;
    t.line = g_line;
    t.col = sc;
    return t;
}

bool eat -> char c {
    if at_end() {
        return false;
    }
    if cur() != c {
        return false;
    }
    adv();
    return true;
}

!!! One operator, or a single character that is not one. A character that matches
!!! nothing is reported and stepped over here, and the token that comes back for it
!!! is the end-of-file token with no text at all - next_token reads that as
!!! "nothing here, look again", which is what the toolchain tokenizer's loop does. A file
!!! with a stray byte in it therefore still yields every token after the byte.
Token read_operator_one {
    int sc = g_col;
    int from = g_at;
    char c = (char)cur();
    if c == '.' {
        !!! `...` is one token, and every other dot is the dot itself: the toolchain
        !!! tokenizer reads `.` and `...` before the number reader is reached at
        !!! all, so `.5` is a dot and then the number 5 and `..` is two dots.
        !!! Reading the point into the number here made the two tokenizers
        !!! disagree about what the file says.
        if peek(1) == '.' && peek(2) == '.' {
            adv();
            adv();
            adv();
            return make(TK_ELLIPSIS, from, sc);
        }
        adv();
        return make(TK_DOT, from, sc);
    }
    if c == ':' {
        adv();
        if eat(':') {
            return make(TK_SCOPE, from, sc);
        }
        return make(TK_COLON, from, sc);
    }
    if c == '=' {
        adv();
        if eat('=') {
            return make(TK_EQ, from, sc);
        }
        if eat('>') {
            return make(TK_ARROW, from, sc);
        }
        return make(TK_ASSIGN, from, sc);
    }
    if c == '!' {
        adv();
        if eat('=') {
            return make(TK_NE, from, sc);
        }
        return make(TK_NOT, from, sc);
    }
    if c == '&' {
        adv();
        if eat('&') {
            return make(TK_AND, from, sc);
        }
        if eat('=') {
            return make(TK_COMPOUND_ASSIGN, from, sc);
        }
        return make(TK_BITAND, from, sc);
    }
    if c == '|' {
        adv();
        if eat('|') {
            return make(TK_OR, from, sc);
        }
        if eat('=') {
            return make(TK_COMPOUND_ASSIGN, from, sc);
        }
        return make(TK_BITOR, from, sc);
    }
    if c == '^' {
        adv();
        if eat('=') {
            return make(TK_COMPOUND_ASSIGN, from, sc);
        }
        return make(TK_BITXOR, from, sc);
    }
    if c == '~' {
        adv();
        return make(TK_BITNOT, from, sc);
    }
    if c == '<' {
        adv();
        if eat('<') {
            if eat('=') {
                return make(TK_COMPOUND_ASSIGN, from, sc);
            }
            return make(TK_SHL, from, sc);
        }
        if eat('=') {
            return make(TK_LE, from, sc);
        }
        return make(TK_LT, from, sc);
    }
    if c == '>' {
        adv();
        if eat('>') {
            if eat('=') {
                return make(TK_COMPOUND_ASSIGN, from, sc);
            }
            return make(TK_SHR, from, sc);
        }
        if eat('=') {
            return make(TK_GE, from, sc);
        }
        return make(TK_GT, from, sc);
    }
    if c == '+' {
        adv();
        if eat('+') {
            return make(TK_PLUS_PLUS, from, sc);
        }
        if eat('=') {
            return make(TK_COMPOUND_ASSIGN, from, sc);
        }
        return make(TK_PLUS, from, sc);
    }
    if c == '-' {
        adv();
        if eat('-') {
            return make(TK_MINUS_MINUS, from, sc);
        }
        if eat('=') {
            return make(TK_COMPOUND_ASSIGN, from, sc);
        }
        return make(TK_MINUS, from, sc);
    }
    if c == '*' {
        adv();
        if eat('=') {
            return make(TK_COMPOUND_ASSIGN, from, sc);
        }
        return make(TK_STAR, from, sc);
    }
    if c == '/' {
        adv();
        if eat('=') {
            return make(TK_COMPOUND_ASSIGN, from, sc);
        }
        return make(TK_SLASH, from, sc);
    }
    if c == '%' {
        adv();
        if eat('=') {
            return make(TK_COMPOUND_ASSIGN, from, sc);
        }
        return make(TK_MOD, from, sc);
    }
    if c == '?' {
        adv();
        return make(TK_QMARK, from, sc);
    }
    if c == '$' {
        adv();
        return make(TK_REF, from, sc);
    }
    if c == '@' {
        adv();
        return make(TK_AT, from, sc);
    }
    if c == ',' {
        adv();
        return make(TK_COMMA, from, sc);
    }
    if c == '(' {
        adv();
        return make(TK_LPAREN, from, sc);
    }
    if c == ')' {
        adv();
        return make(TK_RPAREN, from, sc);
    }
    if c == '{' {
        adv();
        return make(TK_LBRACE, from, sc);
    }
    if c == '}' {
        adv();
        return make(TK_RBRACE, from, sc);
    }
    if c == '[' {
        adv();
        return make(TK_LBRACKET, from, sc);
    }
    if c == ']' {
        adv();
        return make(TK_RBRACKET, from, sc);
    }
    if c == ';' {
        adv();
        return make(TK_SEMI, from, sc);
    }
    !!! Nothing matched. The character is named and stepped over, and the answer is
    !!! the empty end-of-file token the wrapper recognises.
    adv();
    lex_error_at(g_line, sc, 1, "meaningless character '" + char_text(c) + "'");
    Token none;
    none.tk = TK_EOF;
    none.start = from;
    none.stop = from;
    none.line = g_line;
    none.col = sc;
    return none;
}

Token next_token {
    while !at_end() {
        char c = (char)cur();
        if is_blank(c) {
            if c == '\n' {
                g_line = g_line + 1;
                !!! The column of the character after the newline is 1, and adv()
                !!! below counts the newline itself: setting 1 here made the next
                !!! line start at column 2.
                g_col = 0;
            }
            adv();
            continue;
        }
        if c == '!' {
            if skip_line_comment() {
                continue;
            }
            if skip_block_comment() {
                continue;
            }
        }
        if is_digit(c) {
            return read_number();
        }
        if is_ident_start(c) {
            return read_ident();
        }
        if c == '"' {
            return read_string();
        }
        if c == '\'' {
            return read_char();
        }
        Token t = read_operator_one();
        if t.tk == TK_EOF && t.start == t.stop {
            !!! The character names nothing: read_operator_one named it, reported it
            !!! and stepped over it. The scan starts over at the top, which is what
            !!! the toolchain tokenizer's single loop does - the blank, the name, the
            !!! number or the operator that stands next is read the way it is read
            !!! anywhere else. Carrying on inside the operator reader instead made
            !!! every byte after a stray one a meaningless character of its own: a
            !!! single `\` in test.b buried the file in fifteen of them.
            continue;
        }
        return t;
    }
    Token eof;
    eof.tk = TK_EOF;
    eof.start = g_at;
    eof.stop = g_at;
    eof.line = g_line;
    eof.col = g_col;
    return eof;
}

!!! The text of one line, without its ending, as its own heap block: the caller
!!! gives it back with unlink. A diagnostic prints the line under the position it
!!! names, and this is that text. A line past the end of the source is empty.
str line_text -> int line {
    @void cell;
    if line < 1 || line > g_line_off.len {
        malloc(@cell, 1);
        @char z = (@char)cell;
        $z = (char)0;
        return (str)cell;
    }
    int from = g_line_off.get(line - 1);
    int i = from;
    while i < g_src_len {
        char c = g_base[i];
        if c == '\n' {
            skip;
        }
        if c == '\r' {
            skip;
        }
        i = i + 1;
    }
    int n = i - from;
    malloc(@cell, n + 1);
    @char d = (@char)cell;
    int k = 0;
    while k < n {
        d[k] = g_base[from + k];
        k = k + 1;
    }
    d[n] = (char)0;
    return (str)cell;
}

!!! ---- where a position of the preprocessed text came from ----
!!!
!!! The tokenizer reads the preprocessed text, whose lines shift as soon as a
!!! `#head` file is inlined and whose text a `#replace` rewrote. Two maps the
!!! preprocessor built say where a position really stands: the source map
!!! (`preprocessed line -> (file, line)`) and the replacement positions
!!! (`byte offset -> the occurrence that was written there`). Both are handed over
!!! before the scan, and every diagnostic reads them, which is what makes the two
!!! compilers print the same place for the same problem.

@LineSrc g_line_map;
@RepPos g_rep_map;

void lex_set_maps -> @LineSrc map, @RepPos rep {
    g_line_map = map;
    g_rep_map = rep;
}

!!! The (file, line) a preprocessed line belongs to, left in g_src_file/g_src_line.
!!! A line the map says nothing about is a line of the file being compiled.
str g_src_file;
int g_src_line;

void lex_get_source -> int line {
    g_src_file = g_file;
    g_src_line = line;
    !!! `line_source.find(line)`: the map is in ascending line order, so this is the
    !!! binary search of pp_src_find. A diagnostic asks for a line once, and a walk
    !!! of the map here would be one walk per diagnostic over a map with an entry
    !!! for every line of the file.
    int at = pp_src_find(g_line_map, line);
    if at >= 0 {
        @str files = g_line_map.files;
        @int srcs = g_line_map.srcs;
        g_src_file = files[at];
        g_src_line = srcs[at];
    }
}

!!! Whether a mapped file is a `#head` file rather than the one being compiled: the
!!! banner that names it is printed in front of a diagnostic that came from there.
bool lex_is_head_source -> str f {
    if f == null || f == "" {
        return false;
    }
    return !pe_eq(f, g_file);
}

!!! The banner itself (frontend/lexer's `head_file_banner`): a reset first, so
!!! the banner is uncolored whatever the diagnostic above it left behind, then the
!!! bullet, the words and the file name alone. the toolchain reaches the file name with
!!! source_file_name and the words with zh_pick; the bullet is the UTF-8 bytes the
!!! writes, which is the character itself in this source.
str lex_head_banner -> str f {
    int cut = -1;
    int i = 0;
    while f[i] != (char)0 {
        if f[i] == '\\' || f[i] == '/' {
            cut = i;
        }
        i = i + 1;
    }
    str name = "";
    int j = cut + 1;
    while f[j] != (char)0 {
        name = name + char_text(f[j]);
        j = j + 1;
    }
    str esc = char_text((char)27);
    return esc + "[0m" + "• " +
           zh_pick("From head file '" + esc + "[1m", "来自头文件 '" + esc + "[1m") +
           name + esc + "[0m':\n";
}

!!! The `#replace` occurrence whose replacement text covers this position of the
!!! preprocessed source, or null. the toolchain looks the offset up in a name table and
!!! steps back one entry, which is the occurrence with the greatest offset at or
!!! before it; the chain is searched for that same one.
@ReplaceInfo lex_replace_at -> int line, int col {
    if line < 1 || line > g_line_off.len {
        return null;
    }
    int off = g_line_off.get(line - 1) + (col > 0 ? col - 1 : 0);
    int best = -1;
    @ReplaceInfo found = null;
    @RepPos r = g_rep_map;
    while r != null {
        int to_len = pe_len(r.info.to);
        if r.off <= off && off < r.off + to_len && r.off > best {
            best = r.off;
            found = r.info;
        }
        r = r.next;
    }
    return found;
}

!!! Where a diagnostic found at `line`/`col` should be shown. Text a `#replace`
!!! produced is reported where the macro name stands, with the line as it was
!!! written before the replacement (so `str a = 0;` is shown, not `int1 a = 0;`),
!!! and the occurrence is left in g_show_macro so a note can point at the directive.
str g_show_file;
int g_show_line;
int g_show_col;
str g_show_src;
int g_show_hl;
@ReplaceInfo g_show_macro;

void lex_show_pos -> int line, int col {
    lex_get_source(line);
    g_show_file = g_src_file;
    g_show_line = g_src_line;
    g_show_col = col;
    g_show_src = "";
    g_show_hl = 0;
    g_show_macro = null;
    @ReplaceInfo ri = lex_replace_at(line, col);
    if ri != null && ri.line_from > 0 {
        g_show_col = ri.col_from;
        g_show_src = ri.src_line_from;
        g_show_hl = pe_len(ri.from);
        g_show_macro = ri;
    }
}

!!! ---- the diagnostics ----

!!! One character as a string of its own. `(str)c` is the number-to-text
!!! conversion - a char is a number to it - and a message that names the character
!!! it found needs the character, so the byte is put in a block of its own.
str char_text -> char c {
    @void cell;
    malloc(@cell, 2);
    @char p = (@char)cell;
    $p = c;
    @char last = p + 1;
    $last = (char)0;
    return (str)cell;
}

!!! One diagnostic, laid out by libbstr the way every other message of the compiler
!!! is: `file:line:col: error: message`, the source line under it and the caret
!!! under the span. Laying the text out here instead would be a second copy of a
!!! layout that has to stay the same as the compiler's, and it would have no
!!! color: the codes are libbstr's, and `ux_color_init` is what turns them on.
void lex_error_at -> int line, int col, int len, str msg {
    if len <= 0 {
        len = 1;
    }
    if col < 1 {
        col = 1;
    }
    !!! The position is a position in the preprocessed text; the source map and the
    !!! replacement positions say which file and line, and which column of the line
    !!! as it was written, the problem really stands at.
    lex_show_pos(line, col);
    int show_line = g_show_line;
    int show_col = g_show_col;
    if g_show_hl > 0 {
        len = g_show_hl;
    }
    !!! The text under the position: the line as it was written before a `#replace`
    !!! rewrote it when there is one, and the preprocessed line otherwise. Either
    !!! way it is a block of its own, because the caller gives it back.
    str text = "";
    if g_show_src != "" {
        text = pe_sub_to_end(g_show_src, 0);
    } else {
        text = line_text(line);
    }
    @void cell;
    malloc(@cell, 4096);
    str buf = (str)cell;
    !!! There is no suggestion, so the last argument is false; it is a named bool
    !!! because a `bool` parameter does not take the literal.
    bool no_tilde = false;
    !!! The message body is translated before the layout is written and the category
    !!! word afterwards, which is the two steps the toolchain entry point takes
    !!! (`zh_msg(d.msg)` into ux_error_buf, `zh_prefixes` over the whole block).
    ux_error_buf(buf, 4096, g_show_file, show_line, show_col, zh_msg(msg), text, len,
                 (str)null, 0, no_tilde);
    system.err(zh_prefixes(buf));
    unlink(@cell);
    unlink(@text);
    g_diags = g_diags + 1;
}

!!! ---- the two entry points the driver uses ----

!!! Point the scanner at a source text. A str is a char array, so the text is taken
!!! at its first character and the length is the walk to the terminator. The line
!!! starts are recorded here, once, so a later diagnostic can print the line it
!!! points at: `file:line:col` is useless without the text under it.
void lex_start -> str src {
    g_base = (@char)src;
    g_p = g_base;
    g_left = span_len(src);
    g_src_len = g_left;
    g_line = 1;
    g_col = 1;
    g_at = 0;
    !!! The table starts over for this source: `release` hands the old block back, so
    !!! a second file does not grow the table of the first.
    g_line_off.release();
    g_line_off.add(0);
    int i = 0;
    while i < g_left {
        char c = g_p[i];
        if c == '\n' {
            g_line_off.add(i + 1);
        }
        i = i + 1;
    }
    !!! The entries above are the lines a newline starts. The text after the last
    !!! newline is a line too - a file that does not end with one has a last line
    !!! without an ending - so the table gets one more entry, which is also what
    !!! `line_text` needs to print that line.
    if g_src_len > 0 {
        g_line_off.add(g_src_len);
    }
} 

!!! ---- the whole file as a token vector ----
!!!
!!! The parser has to look ahead: whether a statement is a declaration or a call
!!! depends on the token after the name, an `->` is two tokens, and the toolchain parser
!!! asks `tokens[pos + n]` all over the place. A stream cannot answer that, so the
!!! tokens of the whole file are read once into a vector and the parser walks it by
!!! index: the same list the toolchain parser keeps, with the number of tokens being the
!!! vector's length instead of a capacity that has to be guessed.
!!!
!!! The list is held through a pointer to a block from the heap, not as a global
!!! object of its own. A global `vector(Token)` - a global whose fields are written
!!! by `add` - makes this compiler's own output jump into the entry-scope block
!!! (bootstrap/_vg4.b is the four-line reproduction), while the same three fields in
!!! a heap block reached through a global pointer work. The block is made once, on
!!! the first file, and handed back before the next one.
@vector(Token) g_tokens;

void lex_tokens_init {
    if g_tokens != null {
        end;
    }
    vector(Token) proto;
    malloc(@g_tokens, size proto);
    g_tokens.data = null;
    g_tokens.len = 0;
    g_tokens.cap = 0;
}

!!! Read every token of the source into the vector, the end of the file included:
!!! the parser's tests are all "is the current token X", and the end of the file is
!!! one of the answers. Returns how many tokens were read, not counting that one.
int lex_all {
    lex_tokens_init();
    g_tokens.release();
    int n = 0;
    while true {
        Token t = next_token();
        g_tokens.add(t);
        if t.tk == TK_EOF {
            skip;
        }
        n = n + 1;
    }
    return n;
}

!!! Name the tokens in the vector, up to `limit` of them. This is the tool's own
!!! output, so it goes to the process's standard output.
int dump_tokens -> int limit {
    int n = 0;
    while n < limit && n < g_tokens.len {
        Token t = g_tokens.get(n);
        if t.tk == TK_EOF {
            return n;
        }
        system.std_out(t.line, ":", t.col, "  ", kind_name(t.tk));
        if t.tk == TK_IDENT || t.tk == TK_INTEGER || t.tk == TK_FLOAT ||
           t.tk == TK_STRING || t.tk == TK_CHAR || t.tk == TK_KEYWORD {
            system.std_out("  ", span_text(t.start, t.stop));
        }
        system.std_out("\n");
        n = n + 1;
    }
    return n;
}

