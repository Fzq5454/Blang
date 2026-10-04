#once
!~
 ~  bootstrap/frontend/parser_primary.b: the frontend/parser_primary.
 ~
 ~  One primary expression and everything that can hang off it: a literal, a name
 ~  with its subscripts, fields, methods and calls, a cast, `size`, and a
 ~  parenthesized expression.
 ~
 ~  Two shapes of this implementation are worth knowing while reading it:
 ~   * a member chain is a list of MEMBER_ACCESS nodes, each holding the one before
 ~     it, so the value the chain starts from stays the base of it;
 ~   * the call arguments vectors are chains, and the pieces of one
 ~     argument travel in the fields parser_call.b declares.
 ~!

#head "parser"

!!! The operators a pack may be folded with: any binary operator the language has.
bool p_is_fold_op -> TokenKind k {
    if k == TK_PLUS || k == TK_MINUS || k == TK_STAR || k == TK_SLASH || k == TK_MOD {
        return true;
    }
    if k == TK_AND || k == TK_OR || k == TK_BITAND || k == TK_BITOR || k == TK_BITXOR {
        return true;
    }
    if k == TK_SHL || k == TK_SHR {
        return true;
    }
    if k == TK_LT || k == TK_GT || k == TK_LE || k == TK_GE || k == TK_EQ || k == TK_NE {
        return true;
    }
    return false;
}

!!! `(Pack etc OP)` / `(OP Pack etc)` when the tokens at the parser's position are
!!! that shape, and null otherwise (the caller then reads an ordinary parenthesized
!!! expression). The `(`, the name, the `etc`, the operator and the `)` are all
!!! consumed by the fold.
@ExprNode p_try_fold {
    Token t1 = p_peek(1);
    Token t2 = p_peek(2);
    Token t3 = p_peek(3);
    Token t4 = p_peek(4);
    if t4.tk != TK_RPAREN {
        return null;
    }
    bool left = false;
    Token pack_tok = t1;
    Token op_tok = t3;
    if t1.tk == TK_IDENT && t2.tk == TK_KEYWORD && p_span_is(t2, "etc") && p_is_fold_op(t3.tk) {
        left = true;
    } else if p_is_fold_op(t1.tk) && t2.tk == TK_IDENT && t3.tk == TK_KEYWORD &&
              p_span_is(t3, "etc") {
        left = false;
        pack_tok = t2;
        op_tok = t1;
    } else {
        return null;
    }
    @ExprNode f = p_new_expr(FOLD);
    f.line = pack_tok.line;
    f.col = pack_tok.col;
    f.tok_len = pack_tok.stop - pack_tok.start;
    f.var_name = span_text(pack_tok.start, pack_tok.stop);
    f.op = span_text(op_tok.start, op_tok.stop);
    f.fold_right = !left;
    f.result_type = INT;
    p_adv();
    p_adv();
    p_adv();
    p_adv();
    p_adv();
    return f;
}

!!! `receiver.method(args)`. The receiver becomes argument 0 of the call, exactly
!!! as the `name(args)` form pushes a plain variable, so the code generator only
!!! has to look at args[0] to find the object the method acts on.
@ExprNode p_method_call_on -> @ExprNode receiver {
    p_adv();
    @ExprNode call = p_new_expr(FUNC_CALL);
    !!! The error position is the method name (the parser stands on it here), not
    !!! the receiver in args[0].
    call.line = p_cur.line;
    call.col = p_cur.col;
    call.var_name = span_text(p_cur.start, p_cur.stop);
    call.tok_len = p_cur.stop - p_cur.start;
    call.has_receiver = true;
    p_adv();
    p_adv();
    if receiver != null && receiver.nk == VAR_REF && p_text_eq(receiver.var_name, "super") {
        call.is_super = true;
    }
    call.args = p_chain_expr(call.args, receiver);
    !!! The receiver is not a declared parameter, so its entry in the name list stays
    !!! empty and the declared parameters line up behind it.
    call.arg_names = p_chain_str(call.arg_names, p_new_name("", 0, 0));
    call.arg_name_lines = p_chain_int(call.arg_name_lines, p_new_int(0));
    call.arg_name_cols = p_chain_int(call.arg_name_cols, p_new_int(0));
    call.arg_name_lens = p_chain_int(call.arg_name_lens, p_new_int(0));
    call.nargs = 1;
    if !p_is(TK_RPAREN) {
        p_parse_call_arg();
        if p_arg_expr == null {
            return null;
        }
        p_expr_add_arg(call);
        while p_is(TK_COMMA) {
            p_adv();
            p_parse_call_arg();
            if p_arg_expr == null {
                return null;
            }
            p_expr_add_arg(call);
        }
    }
    if !p_is(TK_RPAREN) {
        p_error("missing ')'");
        return null;
    }
    p_adv();
    call.result_type = INT;
    !!! A field or a method of the value the call answers: `a.add(b).mul(c)`,
    !!! `f().field`, and any longer chain after it.
    return p_member_chain_on(call);
}

!!! A field or a method of the value an expression denotes, repeatedly:
!!! `f().field`, `f().next()`, `a.m().x`, `arr[i].field.sub`. The chain is built on
!!! the expression itself, so the value it denotes stays the base of the chain.
@ExprNode p_member_chain_on -> @ExprNode base {
    @ExprNode cur_expr = base;
    while p_is(TK_DOT) && p_peek_is(1, TK_IDENT) {
        if p_peek_is(2, TK_LPAREN) {
            @ExprNode call = p_method_call_on(cur_expr);
            if call == null {
                return null;
            }
            cur_expr = call;
            continue;
        }
        p_adv();
        @ExprNode member = p_new_expr(MEMBER_ACCESS);
        member.line = p_cur.line;
        member.col = p_cur.col;
        member.tok_len = p_cur.stop - p_cur.start;
        member.left = cur_expr;
        member.member_name = span_text(p_cur.start, p_cur.stop);
        member.var_name = member.member_name;
        member.result_type = INT;
        p_adv();
        cur_expr = member;
    }
    return cur_expr;
}

!!! One element of an array field: `o.people[i]`, and a field or a method of that
!!! element (`o.people[i].name`, `o.people[i].grow()`).
@ExprNode p_field_elem -> @ExprNode base {
    @ExprNode cur_expr = base;
    !!! One node per dimension.
    while p_is(TK_LBRACKET) {
        int lb_line = p_cur.line;
        int lb_col = p_cur.col;
        p_adv();
        if p_is(TK_RBRACKET) {
            p_error_at(p_cur.line, p_cur.col, 0, "index required inside '[]'");
            p_adv();
            return null;
        }
        @ExprNode idx = parse_expr(0);
        if idx == null {
            return null;
        }
        if !p_is(TK_RBRACKET) {
            p_error_at(p_cur.line, p_cur.col, p_cur.stop - p_cur.start, "missing ']'");
            return null;
        }
        p_adv();
        @ExprNode e = p_new_expr(FIELD_ELEM);
        e.line = lb_line;
        e.col = lb_col;
        e.left = cur_expr;
        e.right = idx;
        e.result_type = INT;
        e.tok_len = 1;
        cur_expr = e;
    }
    while p_is(TK_DOT) && p_peek_is(1, TK_IDENT) {
        if p_peek_is(2, TK_LPAREN) {
            @ExprNode call = p_method_call_on(cur_expr);
            if call == null {
                return null;
            }
            cur_expr = call;
            continue;
        }
        p_adv();
        @ExprNode m = p_new_expr(MEMBER_ACCESS);
        m.line = p_cur.line;
        m.col = p_cur.col;
        m.tok_len = p_cur.stop - p_cur.start;
        m.left = cur_expr;
        m.member_name = span_text(p_cur.start, p_cur.stop);
        m.var_name = m.member_name;
        m.result_type = INT;
        p_adv();
        cur_expr = m;
    }
    return cur_expr;
}

!!! The character an escape stands for, which is the toolchain char_escape: every escape
!!! C has is here, and an escape that is none of them still stands for itself.
char p_char_escape -> char c {
    if c == 'n' { return (char)10; }
    if c == 't' { return (char)9; }
    if c == 'r' { return (char)13; }
    if c == '0' { return (char)0; }
    if c == 'a' { return (char)7; }
    if c == 'b' { return (char)8; }
    if c == 'f' { return (char)12; }
    if c == 'v' { return (char)11; }
    if c == '\\' { return '\\'; }
    if c == '\'' { return '\''; }
    if c == '"' { return '"'; }
    return c;
}

!!! The value of one hexadecimal digit, for the `\xHH` of a literal.
int p_hex_val -> char c {
    if c >= '0' && c <= '9' {
        return (int)c - 48;
    }
    if c >= 'a' && c <= 'f' {
        return (int)c - 87;
    }
    return (int)c - 55;
}

bool p_is_hex -> char c {
    if c >= '0' && c <= '9' {
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

!!! The value of a string literal. The tokenizer keeps the span and not the value,
!!! so the text is taken here with its escapes decoded, which is what the toolchain
!!! reader does while it reads: a `"\n"` in the source is one newline in the
!!! literal, not a backslash and an `n`.
!!!
!!! `\xHH` - one or more hexadecimal digits - and `\ooo` - up to three octal ones -
!!! come first, the way C reads them: `\xE2\x86\x92` is an arrow in UTF-8 and `\033`
!!! is the ASCII escape. A spelling that is neither is the letter table below.
str p_string_value -> int from, int to {
    str out = "";
    int i = from;
    while i < to {
        char c = g_base[i];
        if c == '\\' && i + 1 < to {
            i = i + 1;
            char ev = g_base[i];
            if ev == 'x' && i + 1 < to && p_is_hex(g_base[i + 1]) {
                i = i + 1;
                int hv = 0;
                while i < to && p_is_hex(g_base[i]) {
                    hv = hv * 16 + p_hex_val(g_base[i]);
                    i = i + 1;
                }
                out = out + char_text((char)(hv & 255));
                continue;
            }
            if ev >= '0' && ev <= '7' {
                int v = 0;
                int n = 0;
                while i < to && n < 3 && g_base[i] >= '0' && g_base[i] <= '7' {
                    v = v * 8 + ((int)g_base[i] - 48);
                    i = i + 1;
                    n = n + 1;
                }
                out = out + char_text((char)v);
                continue;
            }
            out = out + char_text(p_char_escape(ev));
        } else {
            out = out + char_text(c);
        }
        i = i + 1;
    }
    return out;
}

!!! The value of a character literal. The tokenizer keeps the span and not the
!!! value, so the byte is taken here: `'x'` is the character after the quote, and a
!!! backslash introduces the escape the toolchain reader decodes.
int p_char_value -> Token t {
    if t.stop - t.start >= 3 {
        char c = g_base[t.start + 1];
        if c != '\\' {
            return (int)c;
        }
        int i = t.start + 2;
        if i < t.stop && g_base[i] == 'x' && i + 1 < t.stop && p_is_hex(g_base[i + 1]) {
            i = i + 1;
            int hv = 0;
            while i < t.stop && p_is_hex(g_base[i]) {
                hv = hv * 16 + p_hex_val(g_base[i]);
                i = i + 1;
            }
            return hv & 255;
        }
        if i < t.stop && g_base[i] >= '0' && g_base[i] <= '7' {
            int v = 0;
            int n = 0;
            while i < t.stop && n < 3 && g_base[i] >= '0' && g_base[i] <= '7' {
                v = v * 8 + ((int)g_base[i] - 48);
                i = i + 1;
                n = n + 1;
            }
            return v;
        }
        return (int)p_char_escape(g_base[i]);
    }
    return 0;
}

!!! One power of ten as a float. Up to 10^22 every power is a value a double holds
!!! exactly, so the loop below multiplies exact values by exact ones; past that the
!!! text has more digits than a double has, and the reader is as close as strtod
!!! without strtod can be.
float p_pow10 -> int n {
    float r = 1.0;
    while n >= 22 {
        r = r * 10000000000000000000000.0;
        n = n - 22;
    }
    while n > 0 {
        r = r * 10.0;
        n = n - 1;
    }
    return r;
}

!!! The value of a floating-point literal, read from its span. the toolchain hands the
!!! text to strtod, which answers the double nearest to the decimal it names. The
!!! port collects the digits into a whole number and then moves the point with one
!!! multiplication or one division by a power of ten. Reading the fraction digit by
!!! digit instead (`v = v + d * scale`, `scale = scale * 0.1`) accumulated the error
!!! of every 0.1 in the answer: 0.0000001 came out as 1.0000000000000005e-07
!!! instead of 9.9999999999999995e-08, and that wrong value was what the .r of
!!! every source with a small literal carried.
float p_float_value -> int from, int to {
    longlong man = 0;
    int expo = 0;
    int i = from;
    bool neg = false;
    if i < to && (g_base[i] == '+' || g_base[i] == '-') {
        if g_base[i] == '-' {
            neg = true;
        }
        i = i + 1;
    }
    !!! The whole part: digits past the nineteenth are beyond what a double can put
    !!! back, so they only make the number bigger by a power of ten. The digit is
    !!! only added while the answer still fits: `man * 10 + digit` passes 2^63-1 as
    !!! soon as man is above 922337203685477579, and the wrap turns the number
    !!! negative - `9223372036854.775808` came out as -9223372036854.7754 because
    !!! the mantissa reached 922337203685477580 and the last 8 was added anyway.
    while i < to && g_base[i] >= '0' && g_base[i] <= '9' {
        if man <= 922337203685477579 {
            man = man * 10 + (longlong)((int)g_base[i] - (int)'0');
        } else {
            expo = expo + 1;
        }
        i = i + 1;
    }
    if i < to && g_base[i] == '.' {
        i = i + 1;
        while i < to && g_base[i] >= '0' && g_base[i] <= '9' {
            if man <= 922337203685477579 {
                man = man * 10 + (longlong)((int)g_base[i] - (int)'0');
                expo = expo - 1;
            }
            i = i + 1;
        }
    }
    if i < to && (g_base[i] == 'e' || g_base[i] == 'E') {
        i = i + 1;
        int esign = 1;
        if i < to && (g_base[i] == '+' || g_base[i] == '-') {
            if g_base[i] == '-' {
                esign = -1;
            }
            i = i + 1;
        }
        int ex = 0;
        while i < to && g_base[i] >= '0' && g_base[i] <= '9' {
            ex = ex * 10 + ((int)g_base[i] - (int)'0');
            i = i + 1;
        }
        expo = expo + esign * ex;
    }
    float v = (float)man;
    if expo >= 0 {
        v = v * p_pow10(expo);
    } else {
        v = v / p_pow10(0 - expo);
    }
    if neg {
        v = 0.0 - v;
    }
    return v;
}

!!! The `cast_op` spelling of a cast target, which is the token the .r carries.
str p_cast_op -> VarType target {
    if target == STR { return "toStr"; }
    if target == INT { return "toInt"; }
    if target == LONG { return "toLong"; }
    if target == FLOAT { return "toFloat"; }
    if target == BOOL { return "toBool"; }
    if target == CHAR { return "toChar"; }
    if target == AT_VOID { return "@void"; }
    if target == AT_INT { return "@int"; }
    if target == AT_LONG { return "@longlong"; }
    if target == AT_FLOAT { return "@float"; }
    if target == AT_CHAR { return "@char"; }
    if target == AT_STR { return "@str"; }
    if target == AT_BOOL { return "@bool"; }
    if target == FUNC { return "toFunc"; }
    if target == AT_FUNC { return "toAtFunc"; }
    return "toInt";
}

@ExprNode p_primary {
    if p_is(TK_EOF) {
        p_error_at(1, 1, 1, "missing expression");
        return null;
    }

    !!! `::name` names the global scope: the marker is folded into the name so the
    !!! code generator looks it up there only, and the position stays on the `::` so
    !!! the whole `::name` is highlighted.
    str scope_prefix = "";
    int scope_line = 0;
    int scope_col = 0;
    if p_is(TK_SCOPE) && p_peek_is(1, TK_IDENT) {
        scope_line = p_cur.line;
        scope_col = p_cur.col;
        p_adv();
        scope_prefix = "::";
    }

    !!! A lambda literal: `[params] { body }`.
    if p_is(TK_LBRACKET) {
        return p_lambda();
    }

    if p_is(TK_NOT) {
        int uline = p_cur.line;
        int ucol = p_cur.col;
        p_adv();
        @ExprNode inner = p_primary();
        if inner == null {
            return null;
        }
        @ExprNode n = p_new_expr(UNARY);
        n.line = uline;
        n.col = ucol;
        n.op = "!";
        n.left = inner;
        n.result_type = BOOL;
        return n;
    }

    if p_is(TK_PLUS_PLUS) || p_is(TK_MINUS_MINUS) {
        int uline = p_cur.line;
        int ucol = p_cur.col;
        str op_text = span_text(p_cur.start, p_cur.stop);
        p_adv();
        @ExprNode inner2 = p_primary();
        if inner2 == null {
            return null;
        }
        if inner2.nk != VAR_REF {
            p_error_at(uline, ucol, 1, "++/-- can only be applied to a variable");
            !!! A zero stands in for the expression that could not be built, so the
            !!! rest of the statement still reads and does not report a second time.
            @ExprNode ph = p_new_expr(LIT_INT);
            ph.line = uline;
            ph.col = ucol;
            ph.int_val = 0;
            ph.result_type = INT;
            return ph;
        }
        @ExprNode n2 = p_new_expr(PRE_INCR);
        n2.line = uline;
        n2.col = ucol;
        n2.op = op_text;
        n2.left = inner2;
        n2.result_type = INT;
        return n2;
    }

    if p_is(TK_REF) {
        int uline2 = p_cur.line;
        int ucol2 = p_cur.col;
        p_adv();
        @ExprNode inner3 = p_primary();
        if inner3 == null {
            return null;
        }
        @ExprNode n3 = p_new_expr(UNARY);
        n3.line = uline2;
        n3.col = ucol2;
        n3.op = "$";
        n3.left = inner3;
        n3.result_type = INT;
        return n3;
    }

    if p_is(TK_BITNOT) {
        int uline3 = p_cur.line;
        int ucol3 = p_cur.col;
        p_adv();
        @ExprNode inner4 = p_primary();
        if inner4 == null {
            return null;
        }
        @ExprNode n4 = p_new_expr(BITNOT);
        n4.line = uline3;
        n4.col = ucol3;
        n4.op = "~";
        n4.left = inner4;
        n4.result_type = INT;
        return n4;
    }

    if p_is(TK_MINUS) {
        int uline4 = p_cur.line;
        int ucol4 = p_cur.col;
        p_adv();
        @ExprNode inner5 = p_primary();
        if inner5 == null {
            return null;
        }
        !!! Kept as a unary node and not as `0 - x`, so an operator overload can tell
        !!! a negation from a subtraction; the .r output is `0 - x` either way.
        @ExprNode n5 = p_new_expr(UNARY);
        n5.line = uline4;
        n5.col = ucol4;
        n5.op = "-";
        n5.left = inner5;
        n5.result_type = inner5.result_type;
        n5.ptr_depth = inner5.ptr_depth;
        return n5;
    }

    if p_is(TK_AT) {
        int uline5 = p_cur.line;
        int ucol5 = p_cur.col;
        p_adv();
        @ExprNode inner6 = p_primary();
        if inner6 == null {
            return null;
        }
        if inner6.nk != VAR_REF && inner6.nk != ARRAY_ACCESS {
            p_error_at(uline5, ucol5, 1, "@ can only be applied to a variable or array element");
            @ExprNode ph2 = p_new_expr(LIT_INT);
            ph2.line = uline5;
            ph2.col = ucol5;
            ph2.int_val = 0;
            ph2.result_type = AT_INT;
            return ph2;
        }
        @ExprNode n6 = p_new_expr(ADDR);
        n6.line = uline5;
        n6.col = ucol5;
        n6.tok_len = 1 + inner6.tok_len;
        n6.left = inner6;
        n6.result_type = inner6.result_type;
        return n6;
    }

    !!! `size <type or variable>` is the byte count of one.
    if p_name_is("size") {
        int sline = p_cur.line;
        int scol = p_cur.col;
        p_adv();
        if p_is(TK_EOF) {
            p_error_at(sline, scol, 1, "missing type or variable after 'size'");
            return null;
        }
        str target_name = "";
        if p_is(TK_KEYWORD) {
            if p_name_is("int") || p_name_is("longlong") || p_name_is("float") ||
               p_name_is("str") || p_name_is("char") || p_name_is("bool") ||
               p_name_is("void") {
                target_name = span_text(p_cur.start, p_cur.stop);
            }
        } else if p_is(TK_IDENT) {
            target_name = span_text(p_cur.start, p_cur.stop);
        }
        if target_name == "" {
            p_error_at(sline, scol, 1, "missing type or variable after 'size'");
            return null;
        }
        int nline = p_cur.line;
        int ncol = p_cur.col;
        p_adv();
        @ExprNode ns = p_new_expr(SIZE);
        ns.line = nline;
        ns.col = ncol;
        ns.var_name = target_name;
        ns.tok_len = p_text_len(target_name);
        ns.result_type = INT;
        return ns;
    }

    !!! count expression: count arr_or_pack -> the number of elements of the array
    if p_name_is("count") {
        int cline = p_cur.line;
        int ccol = p_cur.col;
        p_adv();
        if !p_is(TK_IDENT) {
            p_error_at(cline, ccol, 0, "missing array name after 'count'");
            return null;
        }
        int cnline = p_cur.line;
        int cncol = p_cur.col;
        str counted = span_text(p_cur.start, p_cur.stop);
        p_adv();
        @ExprNode nc = p_new_expr(COUNT);
        nc.line = cnline;
        nc.col = cncol;
        nc.var_name = counted;
        nc.tok_len = p_text_len(counted);
        nc.result_type = INT;
        return nc;
    }

    if p_is(TK_INTEGER) {
        @ExprNode n = p_new_expr(LIT_INT);
        n.line = p_cur.line;
        n.col = p_cur.col;
        n.int_val = p_cur.value;
        !!! A hex literal is highlighted with the length of its own spelling: the
        !!! token keeps the span, and `0x...` is what was written.
        n.tok_len = p_cur.stop - p_cur.start;
        !!! The tokenizer decided whether the constant needs 64 bits: the value of one
        !!! above the signed range is the bit pattern of the unsigned value, which the
        !!! value test would read as a small int.
        n.lit_is_long = p_cur.is_long;
        if n.lit_is_long {
            n.result_type = LONG;
        } else {
            n.result_type = int_literal_type(n.int_val);
        }
        p_adv();
        return n;
    }
    if p_is(TK_FLOAT) {
        @ExprNode n = p_new_expr(LIT_FLOAT);
        n.line = p_cur.line;
        n.col = p_cur.col;
        n.float_val = p_float_value(p_cur.start, p_cur.stop);
        n.tok_len = p_cur.stop - p_cur.start;
        n.result_type = FLOAT;
        p_adv();
        return n;
    }
    if p_is(TK_STRING) {
        @ExprNode n = p_new_expr(LIT_STR);
        n.line = p_cur.line;
        n.col = p_cur.col;
        n.str_val = p_string_value(p_cur.start + 1, p_cur.stop - 1);
        !!! Where that text stands: the emitter walks the written text for a byte
        !!! the value cannot hold (a NUL), so the span travels with the node.
        n.str_from = p_cur.start + 1;
        n.str_to = p_cur.stop - 1;
        !!! `(int)t.text.size() + 2`: the toolchain highlights the value it read plus the
        !!! two quotes, so an escape counts as the one character it denotes and not
        !!! as the two it was written with - the same answer as the reference.
        n.tok_len = p_text_len(n.str_val) + 2;
        n.result_type = STR;
        p_adv();
        return n;
    }
    if p_is(TK_CHAR) {
        @ExprNode n = p_new_expr(LIT_CHAR);
        n.line = p_cur.line;
        n.col = p_cur.col;
        n.char_val = p_char_value(p_cur);
        n.int_val = n.char_val;
        n.tok_len = 3;
        n.result_type = CHAR;
        p_adv();
        return n;
    }
    if p_name_is("true") || p_name_is("false") {
        @ExprNode n = p_new_expr(LIT_BOOL);
        n.line = p_cur.line;
        n.col = p_cur.col;
        n.bool_val = p_name_is("true");
        if n.bool_val {
            n.int_val = 1;
        } else {
            n.int_val = 0;
        }
        n.tok_len = p_cur.stop - p_cur.start;
        n.result_type = BOOL;
        p_adv();
        return n;
    }

    if p_is(TK_IDENT) || scope_prefix != "" {
        !!! An enumerator is a named constant: it becomes the integer it stands for.
        if scope_prefix == "" && p_is(TK_IDENT) {
            longlong ev = p_enum_value(span_text(p_cur.start, p_cur.stop));
            if p_enum_found {
                @ExprNode n = p_new_expr(LIT_INT);
                n.line = p_cur.line;
                n.col = p_cur.col;
                n.int_val = ev;
                n.result_type = INT;
                n.tok_len = p_cur.stop - p_cur.start;
                p_adv();
                return n;
            }
        }

        @ExprNode n = p_new_expr(VAR_REF);
        if scope_prefix == "" {
            n.line = p_cur.line;
            n.col = p_cur.col;
        } else {
            n.line = scope_line;
            n.col = scope_col;
        }
        n.var_name = scope_prefix + span_text(p_cur.start, p_cur.stop);
        n.tok_len = p_text_len(n.var_name);
        p_adv();
        !!! A package-qualified member: `pkg::name`.
        if scope_prefix == "" && p_is(TK_SCOPE) && p_peek_is(1, TK_IDENT) {
            p_adv();
            n.var_name = n.var_name + "::" + span_text(p_cur.start, p_cur.stop);
            n.tok_len = n.tok_len + 2 + (p_cur.stop - p_cur.start);
            p_adv();
        }
        !!! `ident[i][j]...`, one index after another.
        if p_is(TK_LBRACKET) {
            @ExprNode idxs = null;
            while p_is(TK_LBRACKET) {
                p_adv();
                if p_is(TK_RBRACKET) {
                    p_error_at(p_cur.line, p_cur.col, 0, "index required inside '[]'");
                    p_adv();
                    return null;
                }
                @ExprNode idx = parse_expr(0);
                if idx == null {
                    return null;
                }
                if !p_is(TK_RBRACKET) {
                    p_error_at(p_cur.line, p_cur.col, p_cur.stop - p_cur.start, "missing ']'");
                    return null;
                }
                p_adv();
                idxs = p_chain_expr(idxs, idx);
            }
            !!! The whole `name[idx]...` is highlighted, from the name through the
            !!! closing bracket.
            int name_col = n.col;
            int full_len = (p_prev.col + (p_prev.stop - p_prev.start)) - name_col;
            if full_len < 1 {
                full_len = 1;
            }
            @ExprNode arr = p_new_expr(ARRAY_ACCESS);
            arr.line = n.line;
            arr.col = n.col;
            arr.tok_len = full_len;
            arr.var_name = n.var_name;
            if idxs != null && idxs.next == null {
                !!! One index: the first index lives in `left`, the way the toolchain node
                !!! keeps it.
                arr.left = idxs;
            } else {
                arr.indices = idxs;
            }
            !!! A field or a method of the element, repeatedly: `arr[i].field`,
            !!! `arr[i].field.sub`, `arr[i].grow()`.
            @ExprNode cur_arr = arr;
            while p_is(TK_DOT) && p_peek_is(1, TK_IDENT) {
                if p_peek_is(2, TK_LPAREN) {
                    @ExprNode call = p_method_call_on(cur_arr);
                    if call == null {
                        return null;
                    }
                    cur_arr = call;
                    continue;
                }
                p_adv();
                @ExprNode member = p_new_expr(MEMBER_ACCESS);
                member.line = p_cur.line;
                member.col = p_cur.col;
                member.tok_len = p_cur.stop - p_cur.start;
                member.left = cur_arr;
                member.member_name = span_text(p_cur.start, p_cur.stop);
                member.var_name = member.member_name;
                member.result_type = INT;
                p_adv();
                cur_arr = member;
            }
            return cur_arr;
        }

        !!! A struct field: `var.field`, chained as far as it goes.
        if p_is(TK_DOT) && p_peek_is(1, TK_IDENT) && !p_peek_is(2, TK_LPAREN) {
            p_adv();
            @ExprNode member = p_new_expr(MEMBER_ACCESS);
            member.line = p_cur.line;
            member.col = p_cur.col;
            member.tok_len = p_cur.stop - p_cur.start;
            if n.nk == VAR_REF && p_text_eq(n.var_name, "super") {
                !!! `super.field` reads the base part of the object, which the code
                !!! generator resolves against the parent type: the node carries no
                !!! receiver of its own.
                member.is_super = true;
            } else {
                member.left = n;
            }
            member.member_name = span_text(p_cur.start, p_cur.stop);
            member.var_name = member.member_name;
            member.result_type = INT;
            p_adv();
            @ExprNode chain = member;
            while p_is(TK_DOT) && p_peek_is(1, TK_IDENT) && !p_peek_is(2, TK_LPAREN) {
                p_adv();
                @ExprNode m2 = p_new_expr(MEMBER_ACCESS);
                m2.line = p_cur.line;
                m2.col = p_cur.col;
                m2.tok_len = p_cur.stop - p_cur.start;
                m2.left = chain;
                m2.member_name = span_text(p_cur.start, p_cur.stop);
                m2.var_name = m2.member_name;
                m2.result_type = INT;
                p_adv();
                chain = m2;
            }
            !!! `obj.field.method(...)`: the receiver is the chain itself.
            if p_is(TK_DOT) && p_peek_is(1, TK_IDENT) && p_peek_is(2, TK_LPAREN) {
                return p_method_call_on(chain);
            }
            !!! `obj.data[i]`: an element of an array field.
            if p_is(TK_LBRACKET) {
                return p_field_elem(chain);
            }
            return chain;
        }
        !!! `ident.method(args)`.
        if p_is(TK_DOT) && p_peek_is(1, TK_IDENT) && p_peek_is(2, TK_LPAREN) {
            return p_method_call_on(n);
        }
        !!! `ident(args)`.
        if p_is(TK_LPAREN) {
            @ExprNode call = p_new_expr(FUNC_CALL);
            call.line = n.line;
            call.col = n.col;
            call.var_name = n.var_name;
            call.tok_len = n.tok_len;
            int lparen_line = p_cur.line;
            int lparen_col = p_cur.col;
            !!! An explicit template instantiation: `name(T1, T2)(args)`. The first
            !!! list names the type arguments, the second holds the call arguments.
            bool explicit_targs = p_at_explicit_type_args();
            p_adv();
            if explicit_targs {
                while !p_is(TK_RPAREN) && !p_is(TK_EOF) {
                    if p_type_at(p_pos) {
                        VarType tv = p_type();
                        call.targs = p_chain_type(call.targs, p_new_type(tv));
                        call.targ_structs = p_chain_str(call.targ_structs,
                                                        p_new_name(p_last_struct, p_cur.line, p_cur.col));
                        call.targ_exprs = p_chain_expr(call.targ_exprs, p_new_expr(LIT_NULL));
                        call.targ_is_value = p_chain_bool(call.targ_is_value, p_new_bool(false));
                    } else {
                        @ExprNode ve = parse_expr(0);
                        if ve == null {
                            return null;
                        }
                        call.targs = p_chain_type(call.targs, p_new_type(INT));
                        call.targ_structs = p_chain_str(call.targ_structs,
                                                        p_new_name("", p_cur.line, p_cur.col));
                        call.targ_exprs = p_chain_expr(call.targ_exprs, ve);
                        call.targ_is_value = p_chain_bool(call.targ_is_value, p_new_bool(true));
                    }
                    if p_is(TK_COMMA) {
                        p_adv();
                    } else {
                        skip;
                    }
                }
                if !p_is(TK_RPAREN) {
                    p_error("missing ')' after template type arguments");
                    return null;
                }
                p_adv();
                lparen_line = p_cur.line;
                lparen_col = p_cur.col;
                p_adv();
            }
            if !p_is(TK_RPAREN) {
                p_parse_call_arg();
                if p_arg_expr == null {
                    return null;
                }
                p_expr_add_arg(call);
                while p_is(TK_COMMA) {
                    p_adv();
                    p_parse_call_arg();
                    if p_arg_expr == null {
                        return null;
                    }
                    p_expr_add_arg(call);
                }
            }
            if !p_is(TK_RPAREN) {
                p_error("missing ')'");
                p_unmatched_paren_note(lparen_line, lparen_col);
                return null;
            }
            p_adv();
            !!! A BLANG_API declaration answers its own return type; anything else is
            !!! refined by the type checker.
            @StmtNode bd = p_find_bapi(call.var_name);
            if bd != null {
                call.result_type = bd.func_ret_type;
            } else {
                call.result_type = INT;
            }
            return p_member_chain_on(call);
        }
        !!! `a++` / `a--`.
        if p_is(TK_PLUS_PLUS) || p_is(TK_MINUS_MINUS) {
            str op_text = span_text(p_cur.start, p_cur.stop);
            p_adv();
            @ExprNode inc = p_new_expr(POST_INCR);
            inc.line = n.line;
            inc.col = n.col;
            inc.op = op_text;
            inc.left = n;
            inc.result_type = INT;
            return inc;
        }
        return n;
    }

    !!! `(type)expr` and a parenthesized expression.
    if p_is(TK_LPAREN) {
        !!! `(Pack etc OP)` folds the pack left, `(OP Pack etc)` folds it right:
        !!! which side the operator stands on says which end the fold starts from.
        !!! A template's argument pack is turned into one value this way.
        @ExprNode fold_n = p_try_fold();
        if fold_n != null {
            return fold_n;
        }
        bool is_cast = false;
        bool cast_to_tparam = false;
        bool cast_to_struct_ptr = false;
        Token nt = p_peek(1);
        !!! `(utype T)expr`: the qualifier sits where the type does, so the token
        !!! after it is the one that names the type.
        if nt.tk == TK_KEYWORD && p_span_is(nt, "utype") {
            nt = p_peek(2);
        }
        if p_builtin_type_kw(nt) {
            is_cast = true;
        } else if nt.tk == TK_AT {
            !!! `(@Name)expr` is a cast only when Name really names a type there: a
            !!! builtin pointer type (`(@float)x`) or a type parameter of the
            !!! template being parsed. `(@v)` is the address of the variable `v`
            !!! inside parentheses, which is what runtime/brtm.b writes, and
            !!! reading it as a cast made the type after '@' missing.
            Token nt2 = p_peek(2);
            if nt2.tk == TK_KEYWORD {
                if p_builtin_ptr_kw(nt2) {
                    is_cast = true;
                }
            } else if nt2.tk == TK_IDENT {
                str nm2 = span_text(nt2.start, nt2.stop);
                if p_is_cur_type_param(nm2) {
                    is_cast = true;
                } else if p_is_struct_name(nm2) {
                    !!! `(@Node)p` reads the pointer as one that points at that
                    !!! struct. The bits do not change, only what the front end
                    !!! knows about them, which is what a field access through the
                    !!! pointer needs. A name that is not a struct stays what it
                    !!! was: `(@v)` is the address of the variable `v`.
                    is_cast = true;
                    cast_to_struct_ptr = true;
                }
            }
        } else if nt.tk == TK_IDENT {
            !!! `(T)expr` where T is a template type parameter: the concrete type is
            !!! only known when the template is instantiated, so the cast is recorded
            !!! and resolved when the body is cloned.
            if p_is_cur_type_param(span_text(nt.start, nt.stop)) {
                is_cast = true;
                cast_to_tparam = true;
            }
        }
        if is_cast {
            int cline = p_cur.line;
            int ccol = p_cur.col;
            p_adv();
            VarType target = p_type();
            str cast_name = p_last_struct;
            bool cast_unsigned = p_last_is_unsigned;
            if cast_unsigned && !p_unsigned_ok(target) {
                p_error_at(cline, ccol, 5, "utype is only for 'int', 'longlong' or 'char'");
                cast_unsigned = false;
            }
            if !p_is(TK_RPAREN) {
                p_error_at(p_cur.line, p_cur.col, 0, "missing ')' after type");
                return null;
            }
            p_adv();
            @ExprNode inner = p_primary();
            if inner == null {
                return null;
            }
            !!! `(@Node)ptr`: the pointer keeps its bits and reads as one that points
            !!! at `Node`. Nothing is emitted for it - a pointer is a pointer - so the
            !!! inner expression is answered with the struct written on it, which is
            !!! what a field access through it reads.
            if cast_to_struct_ptr {
                inner.result_type = AT_INT;
                inner.struct_type = cast_name;
                inner.ptr_depth = 1;
                inner.struct_cast = true;
                return inner;
            }
            @ExprNode n = p_new_expr(CAST);
            n.line = cline;
            n.col = ccol;
            n.left = inner;
            n.op = p_cast_op(target);            !!! `(utype T)x` keeps the same bits, but from here on the value reads,
            !!! prints and divides as an unsigned one of that width.
            n.is_unsigned = cast_unsigned;
            if cast_to_tparam {
                n.cast_type_param = cast_name;
            }
            return n;
        }
        int lparen_line2 = p_cur.line;
        int lparen_col2 = p_cur.col;
        p_adv();
        @ExprNode n2 = parse_expr(0);
        if n2 == null {
            return null;
        }
        if !p_is(TK_RPAREN) {
            p_error("missing ')'");
            p_unmatched_paren_note(lparen_line2, lparen_col2);
            return null;
        }
        p_adv();
        !!! A method called on a parenthesized expression: `(a + b).norm()`.
        if p_is(TK_DOT) && p_peek_is(1, TK_IDENT) && p_peek_is(2, TK_LPAREN) {
            return p_method_call_on(n2);
        }
        return n2;
    }

    if p_name_is("null") {
        @ExprNode n = p_new_expr(LIT_NULL);
        n.line = p_cur.line;
        n.col = p_cur.col;
        n.result_type = AT_VOID;
        n.tok_len = 4;
        p_adv();
        return n;
    }

    p_error("missing expression");
    return null;
}
