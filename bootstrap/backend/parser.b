#once
!~
 ~  bootstrap/backend/parser.b: the .r parser's state and statement dispatch.
 ~
 ~  It is the backend/parser and backend/parser_block: the cursor
 ~  the whole parser reads through, the diagnostics, the statement dispatch and the
 ~  parenthesised bodies a statement is built from.
 ~
 ~  the toolchain keeps the statements being built in a member vector and each body swaps
 ~  it aside. Here the chain being built is `cp_stmts` and a body saves it the same
 ~  way, so the two read alike.
 ~!

#head "cmp_ir"
#head "tokenizer"
#head "parser_heads"

!!! The cursor: the token the parser stands on, the first error it found, the file
!!! the diagnostics name, and the chain of statements being built.
@CmpToken cp_cur;
str cp_err;
str cp_file;
@CmpStmt cp_stmts;

void cp_error -> str msg {
    if pe_eq(cp_err, "") {
        cp_err = cp_file + ":" + (str)cp_cur.line + ":" + (str)cp_cur.col +
                 ": error: " + msg;
    }
}

bool cp_has_error {
    return !pe_eq(cp_err, "");
}

str cp_get_error {
    return cp_err;
}

void cp_advance {
    cp_cur = tk_next();
    if tk_has_error() && pe_eq(cp_err, "") {
        cp_err = tk_get_error();
    }
}

void cp_start -> str fname {
    cp_file = fname;
    cp_err = "";
    cp_stmts = null;
    cp_cur = tk_next();
}

bool cp_is -> str kw {
    if cp_cur.tk != CT_IDENT {
        return false;
    }
    return pe_eq(cp_cur.text, kw);
}

bool cp_at -> CmpTokKind k {
    return cp_cur.tk == k;
}

void cp_expect -> str kw {
    if !cp_is(kw) {
        cp_error("expected '" + kw + "', got '" + cp_cur.text + "'");
        end;
    }
    cp_advance();
}

void cp_expect_comma {
    if cp_cur.tk != CT_COMMA {
        cp_error("expected ',', got '" + cp_cur.text + "'");
        end;
    }
    cp_advance();
}

!!! The statements of one body: `( ... )`. The chain being built is put aside while
!!! the body is read, so a nested body does not mix its statements with the outer
!!! one, and it is put back afterwards.
@CmpStmt cp_block {
    if cp_cur.tk != CT_LPAREN {
        cp_error("expected '('");
        return null;
    }
    cp_advance();
    @CmpStmt saved = cp_stmts;
    cp_stmts = null;
    while !cp_has_error() && cp_cur.tk != CT_RPAREN && cp_cur.tk != CT_EOF {
        cp_parse_stmt();
    }
    @CmpStmt out = null;
    if !cp_has_error() {
        out = cp_stmts;
    }
    cp_stmts = saved;
    if cp_cur.tk == CT_RPAREN {
        cp_advance();
    }
    return out;
}

#head "cmp_index"

!!! The words that start a statement, with the code `cp_parse_stmt` dispatches on.
!!! They are put in the index once, in cp_start, and every question about a word is
!!! then one probe: the parser asks "is this a statement keyword?" at every
!!! argument it collects and "is this a cast?" at every parenthesis, so walking a
!!! list of two dozen spellings for each answer was a large part of parsing.
int kwDeclared = 1;
int kwCall = 2;
int kwBcall = 3;
int kwCast = 4;
int kwExit = 5;
int kwIf = 6;
int kwRepeat = 7;
int kwTry = 8;
int kwRaise = 9;
int kwSwitch = 10;
int kwContinue = 11;
int kwDref = 12;
int kwIcall = 13;
int kwRelease = 14;
int kwBspread = 15;
int kwLocal = 16;
int kwFunc = 17;
int kwRet = 18;
int kwEnd = 19;
int kwEnum = 20;
int kwStruct = 21;
!!! The words a statement never starts with but that still end an argument list:
!!! THEN/ELSE close the arms of an IF, CASE/UNMATCH the arms of a SWITCH, CATCH the
!!! body of a TRY. A word that is not listed is taken for the name of a nested
!!! call, which loses the statement that follows.
int kwThen = 22;
int kwElse = 23;
int kwCase = 24;
int kwUnmatch = 25;
int kwCatch = 26;

void cp_keyword_add -> str word, int code {
    ix_set(kIxKeyWord, word, code, 0, 0, 0, "");
}

void cp_keywords_init {
    cp_keyword_add("DECLARED", kwDeclared);
    cp_keyword_add("CALL", kwCall);
    cp_keyword_add("BCALL", kwBcall);
    cp_keyword_add("CAST", kwCast);
    cp_keyword_add("EXIT", kwExit);
    cp_keyword_add("IF", kwIf);
    cp_keyword_add("REPEAT", kwRepeat);
    cp_keyword_add("TRY", kwTry);
    cp_keyword_add("RAISE", kwRaise);
    cp_keyword_add("SWITCH", kwSwitch);
    cp_keyword_add("CONTINUE", kwContinue);
    cp_keyword_add("DREF", kwDref);
    cp_keyword_add("ICALL", kwIcall);
    cp_keyword_add("RELEASE", kwRelease);
    cp_keyword_add("BSPREAD", kwBspread);
    cp_keyword_add("LOCAL", kwLocal);
    cp_keyword_add("FUNC", kwFunc);
    cp_keyword_add("RET", kwRet);
    cp_keyword_add("END", kwEnd);
    cp_keyword_add("ENUM", kwEnum);
    cp_keyword_add("STRUCT", kwStruct);
    cp_keyword_add("THEN", kwThen);
    cp_keyword_add("ELSE", kwElse);
    cp_keyword_add("CASE", kwCase);
    cp_keyword_add("UNMATCH", kwUnmatch);
    cp_keyword_add("CATCH", kwCatch);
    ix_set(kIxCastWord, "_toStr", 1, 0, 0, 0, "");
    ix_set(kIxCastWord, "_toInt", 1, 0, 0, 0, "");
    ix_set(kIxCastWord, "_toLong", 1, 0, 0, 0, "");
    ix_set(kIxCastWord, "_toFloat", 1, 0, 0, 0, "");
    ix_set(kIxCastWord, "_toBool", 1, 0, 0, 0, "");
    ix_set(kIxCastWord, "_toChar", 1, 0, 0, 0, "");
    ix_set(kIxCastWord, "@void", 1, 0, 0, 0, "");
    ix_set(kIxCastWord, "@int", 1, 0, 0, 0, "");
    ix_set(kIxCastWord, "@longlong", 1, 0, 0, 0, "");
    ix_set(kIxCastWord, "@float", 1, 0, 0, 0, "");
    ix_set(kIxCastWord, "@char", 1, 0, 0, 0, "");
    ix_set(kIxCastWord, "@str", 1, 0, 0, 0, "");
    ix_set(kIxCastWord, "@bool", 1, 0, 0, 0, "");
}

bool cp_is_stmt_keyword -> str s {
    return ix_has(kIxKeyWord, s);
}

bool cp_is_cast -> str s {
    return ix_has(kIxCastWord, s);
}


!!! The program: statements until the end of the text.
bool cp_parse {
    while cp_cur.tk != CT_EOF && !cp_has_error() {
        cp_parse_stmt();
    }
    return !cp_has_error();
}

!!! The statement that was added last, which is the one `LOCAL FUNC` has to mark.
@CmpStmt cp_last_stmt {
    @CmpStmt t = cp_stmts;
    if t == null {
        return null;
    }
    while t.next != null {
        t = t.next;
    }
    return t;
}

!!! One statement, by the keyword it starts with. The keyword is one probe of the
!!! index and the dispatch is a switch: the chain of `cp_is` calls this used to be
!!! compared the word with two dozen spellings in turn.
void cp_parse_stmt {
    int kw = 0;
    if cp_cur.tk == CT_IDENT {
        kw = ix_get(kIxKeyWord, cp_cur.text, 1);
    }
    switch kw {
        case kwDeclared:
            cp_parse_declared();
            skip;
        case kwCall:
            cp_parse_call();
            skip;
        case kwBcall:
            cp_parse_bcall();
            skip;
        case kwCast:
            cp_parse_cast();
            skip;
        case kwExit:
            cp_parse_exit();
            skip;
        case kwIf:
            cp_parse_if();
            skip;
        case kwRepeat:
            cp_parse_repeat();
            skip;
        case kwTry:
            cp_parse_try();
            skip;
        case kwRaise:
            cp_parse_raise();
            skip;
        case kwSwitch:
            cp_parse_switch();
            skip;
        case kwContinue:
            @CmpStmt s = cs_new(CONTINUE);
            s.line = cp_cur.line;
            s.col = cp_cur.col;
            cp_advance();
            cp_stmts = cs_add(cp_stmts, s);
            skip;
        case kwDref:
            cp_parse_dref();
            skip;
        case kwIcall:
            cp_parse_icall();
            skip;
        case kwRelease:
            cp_parse_release();
            skip;
        case kwBspread:
            cp_parse_bspread();
            skip;
        case kwLocal:
            cp_advance();
            if !cp_is("FUNC") {
                cp_error("expected FUNC after LOCAL");
                end;
            }
            cp_parse_func();
            @CmpStmt f = cp_last_stmt();
            if f != null {
                f.is_local = true;
            }
            skip;
        case kwFunc:
            cp_parse_func();
            skip;
        case kwRet:
            cp_parse_ret();
            skip;
        case kwEnd:
            @CmpStmt e = cs_new(END);
            e.line = cp_cur.line;
            e.col = cp_cur.col;
            cp_advance();
            cp_stmts = cs_add(cp_stmts, e);
            skip;
        case kwEnum:
            cp_parse_enum();
            skip;
        case kwStruct:
            cp_parse_struct_decl();
            skip;
        unmatch:
            cp_error("unexpected token '" + cp_cur.text + "'");
    }
}
