#once
!~
 ~  bootstrap/frontend/parser_type.b: the frontend/parser_type.
 ~
 ~  Reading a type, and answering the two questions a statement asks about one:
 ~  "may a type stand here" and "is what follows the name a body or a value". Both
 ~  are answered by looking at the token list, which is why this implementation keeps the tokens
 ~  in a vector and walks it by index.
 ~
 ~  A function answers one value in this language, so the two things the toolchain parser
 ~  returns through out-parameters travel in module state instead: the pointer depth
 ~  and the flags of the type just read are the `p_last_*` fields parser.b declares
 ~  (exactly what the `_last_*` members are), the offset just past a spelling is
 ~  `p_spell_end`, and the argument list of a generic type is the `p_spell_args`
 ~  chain.
 ~!

#head "parser"

!!! The canonical spelling of a type argument list entry: the text the argument was
!!! written with, whether it is a constant expression rather than a type, whether it
!!! named a type the parser knows, whether it is a template name, and where it
!!! stands. The rgen reads the same entries when it builds the instantiation.
type TArgSpell {
    str spelling;
    bool is_value;
    bool known_type;
    int line;
    int col;
    int len;
    @TArgSpell next;
};

!!! What the spelling functions answer beside their text.
int p_spell_end;
int p_generic_spell_end;
@TArgSpell p_spell_args;

!!! The builtin type a keyword names. `p_take_builtin_kw` answers whether the token
!!! is one of them and leaves the VarType in the field above: a parameter is copied
!!! when it is passed, so a function cannot answer the type through one.
VarType p_last_builtin;

bool p_take_builtin_kw {
    if p_name_is("int") { p_last_builtin = INT; p_adv(); return true; }
    if p_name_is("longlong") { p_last_builtin = LONG; p_adv(); return true; }
    if p_name_is("str") { p_last_builtin = STR; p_adv(); return true; }
    if p_name_is("float") { p_last_builtin = FLOAT; p_adv(); return true; }
    if p_name_is("bool") { p_last_builtin = BOOL; p_adv(); return true; }
    if p_name_is("char") { p_last_builtin = CHAR; p_adv(); return true; }
    if p_name_is("void") { p_last_builtin = VOID; p_adv(); return true; }
    if p_name_is("any") { p_last_builtin = ANY; p_adv(); return true; }
    if p_name_is("func") { p_last_builtin = FUNC; p_adv(); return true; }
    return false;
}

!!! Whether `utype` can be written for a type: the unsigned reading is about a fixed
!!! width, so only int, longlong and char have one.
bool p_unsigned_ok -> VarType t {
    return t == INT || t == LONG || t == CHAR;
}

!!! Whether one of the `introduce TYPENAME T` names in scope is `name`.
int g_n_instrchain;
bool p_in_str_chain -> @StrNode head, str name {
    g_n_instrchain = g_n_instrchain + 1;
    @StrNode n = head;
    while n != null {
        if p_text_eq(n.s, name) {
            return true;
        }
        n = n.next;
    }
    return false;
}

bool p_is_cur_type_param -> str name {
    return p_in_str_chain(p_cur_type_params, name);
}

bool p_is_cur_template_param -> str name {
    return p_in_str_chain(p_cur_template_params, name);
}

bool p_is_cur_value_param -> str name {
    return p_in_str_chain(p_cur_value_params, name);
}

!!! Is `name` a template-template parameter (`TEMPLATE C`) of the introduce block
!!! being parsed?
bool p_is_template_param -> str name {
    return p_is_cur_template_param(name);
}

!!! Whether the spelling names a generic type (`Box(int)`) rather than a plain one:
!!! the toolchain test is the same, a parenthesis in the text.
bool p_is_generic_spelling -> str s {
    return p_str_has(s, '(');
}

bool p_builtin_type_kw -> Token t {
    if t.tk != TK_KEYWORD {
        return false;
    }
    return p_span_is(t, "int") || p_span_is(t, "str") || p_span_is(t, "float") ||
           p_span_is(t, "bool") || p_span_is(t, "char") || p_span_is(t, "void") ||
           p_span_is(t, "any") || p_span_is(t, "func") || p_span_is(t, "longlong");
}

bool p_builtin_ptr_kw -> Token t {
    if t.tk != TK_KEYWORD {
        return false;
    }
    return p_span_is(t, "int") || p_span_is(t, "float") || p_span_is(t, "char") ||
           p_span_is(t, "str") || p_span_is(t, "void") || p_span_is(t, "bool") ||
           p_span_is(t, "func") || p_span_is(t, "longlong");
}

!!! type_at(): whether a type stands at token offset k. the toolchain version is the same
!!! walk; what it adds over reading a type is that nothing is consumed.
bool p_type_at -> int k {
    Token t = p_tok(k);
    if t.tk == TK_EOF {
        return false;
    }
    !!! `const T` / `static T` / `utype T`: the qualifier comes before the type and
    !!! is not part of it, so a statement may start with it wherever a type may.
    if t.tk == TK_KEYWORD &&
       (p_span_is(t, "const") || p_span_is(t, "static") || p_span_is(t, "utype")) {
        return p_type_at(k + 1);
    }
    if p_builtin_type_kw(t) {
        return true;
    }
    !!! `@int`, `@@int`, ... and `@StructName`.
    if t.tk == TK_AT {
        int j = k;
        while p_kind_at(j) == TK_AT {
            j = j + 1;
        }
        if p_tok(j).tk == TK_IDENT {
            str nm = span_text(p_tok(j).start, p_tok(j).stop);
            if p_is_struct_name(nm) || p_find_template(nm) != null ||
               p_is_template_param(nm) || p_is_cur_type_param(nm) {
                return true;
            }
        }
        return p_builtin_ptr_kw(p_tok(j));
    }
    !!! `ref T`: a reference to a builtin or to a struct.
    if t.tk == TK_KEYWORD && p_span_is(t, "ref") {
        Token r = p_tok(k + 1);
        if p_builtin_ptr_kw(r) {
            return true;
        }
        if r.tk == TK_IDENT {
            str nm = span_text(r.start, r.stop);
            return p_is_struct_name(nm) || p_find_template(nm) != null ||
                   p_is_template_param(nm) || p_is_cur_type_param(nm);
        }
        return false;
    }
    !!! `pkg::Type`, a package-qualified struct type.
    if t.tk == TK_IDENT && p_tok(k + 1).tk == TK_SCOPE && p_tok(k + 2).tk == TK_IDENT {
        return true;
    }
    if t.tk == TK_IDENT {
        str nm = span_text(t.start, t.stop);
        if p_is_struct_name(nm) || p_is_enum_name(nm) {
            return true;
        }
        if p_find_template(nm) != null || p_is_template_param(nm) {
            return true;
        }
        if p_is_cur_type_param(nm) || p_is_cur_template_param(nm) {
            return true;
        }
    }
    return false;
}

bool p_is_type {
    return p_type_at(p_pos);
}

!!! skip_type_at(): the offset just past the type starting at k, mirroring what
!!! reading it would consume.
int p_skip_type_at -> int k {
    !!! `pkg::Type` is one type.
    if p_tok(k).tk == TK_IDENT && p_tok(k + 1).tk == TK_SCOPE && p_tok(k + 2).tk == TK_IDENT {
        return k + 3;
    }
    while p_kind_at(k) == TK_KEYWORD &&
          (p_tok_is(k, "const") || p_tok_is(k, "static") || p_tok_is(k, "utype")) {
        k = k + 1;
    }
    if p_tok(k).tk == TK_KEYWORD && p_span_is(p_tok(k), "ref") {
        k = k + 1;
    }
    while p_kind_at(k) == TK_AT {
        k = k + 1;
    }
    !!! A generic struct carries its argument list: `Box(int)` is one type.
    if p_tok(k).tk == TK_IDENT {
        str nm = span_text(p_tok(k).start, p_tok(k).stop);
        if p_find_template(nm) != null || p_is_template_param(nm) {
            int j = k + 1;
            if p_tok(j).tk == TK_LPAREN {
                int depth = 0;
                while p_kind_at(j) != TK_EOF {
                    if p_tok(j).tk == TK_LPAREN {
                        depth = depth + 1;
                        j = j + 1;
                        continue;
                    }
                    if p_tok(j).tk == TK_RPAREN {
                        depth = depth - 1;
                        j = j + 1;
                        if depth == 0 {
                            skip;
                        }
                        continue;
                    }
                    j = j + 1;
                }
                return j;
            }
        }
    }
    return k + 1;
}

!!! One constant-expression template argument (a non-type parameter): literals and
!!! operators only, so `5`, `-3` and `1 << 4` qualify while a variable reference or
!!! a call does not. `p_spell_end` receives the offset just past the entry.
bool p_const_entry_at -> int k {
    int depth = 0;
    bool saw_lit = false;
    int j = k;
    while p_kind_at(j) != TK_EOF {
        Token t = p_tok(j);
        if depth == 0 && (t.tk == TK_COMMA || t.tk == TK_RPAREN) {
            skip;
        }
        if t.tk == TK_LPAREN {
            depth = depth + 1;
            j = j + 1;
            continue;
        }
        if t.tk == TK_RPAREN {
            if depth == 0 {
                skip;
            }
            depth = depth - 1;
            j = j + 1;
            continue;
        }
        if t.tk == TK_INTEGER || t.tk == TK_FLOAT || t.tk == TK_CHAR || t.tk == TK_STRING {
            saw_lit = true;
            j = j + 1;
            continue;
        }
        !!! `true` / `false` are read as keywords; other literal constants are
        !!! literals or identifiers.
        if (t.tk == TK_IDENT || t.tk == TK_KEYWORD) &&
           (p_span_is(t, "true") || p_span_is(t, "false")) {
            saw_lit = true;
            j = j + 1;
            continue;
        }
        !!! A non-type template parameter of the enclosing template may appear in the
        !!! argument (`f(N - 1)()`), which is how recursive instantiation is written.
        if t.tk == TK_IDENT && p_is_cur_value_param(span_text(t.start, t.stop)) {
            saw_lit = true;
            j = j + 1;
            continue;
        }
        !!! The operators allowed inside a constant expression.
        if t.tk == TK_PLUS || t.tk == TK_MINUS || t.tk == TK_STAR || t.tk == TK_SLASH ||
           t.tk == TK_MOD || t.tk == TK_SHL || t.tk == TK_SHR || t.tk == TK_BITAND ||
           t.tk == TK_BITOR || t.tk == TK_BITXOR || t.tk == TK_BITNOT {
            j = j + 1;
            continue;
        }
        return false;
    }
    if !saw_lit || depth != 0 {
        return false;
    }
    p_spell_end = j;
    return true;
}

!!! Canonical spelling of the type starting at token offset k. A generic struct is
!!! kept as `Name(args)` text: its arguments may still mention the template
!!! parameters of the enclosing `introduce` block, so the concrete class is only
!!! built once those are bound. The offset just past it is left in p_spell_end.
str p_type_spelling_at -> int k {
    p_spell_end = k;
    if p_tok(k).tk == TK_EOF {
        return "";
    }
    str out = "";
    !!! A leading `const` / `static` is a qualifier, never part of the type name.
    while p_kind_at(k) == TK_KEYWORD &&
          (p_tok_is(k, "const") || p_tok_is(k, "static") || p_tok_is(k, "utype")) {
        k = k + 1;
    }
    if p_tok(k).tk == TK_KEYWORD && p_span_is(p_tok(k), "ref") {
        out = out + "ref ";
        k = k + 1;
    }
    while p_kind_at(k) == TK_AT {
        k = k + 1;
    }
    if p_tok(k).tk == TK_EOF {
        return "";
    }
    Token t = p_tok(k);
    if p_builtin_type_kw(t) {
        p_spell_end = k + 1;
        return out + span_text(t.start, t.stop);
    }
    if t.tk == TK_IDENT {
        str nm = span_text(t.start, t.stop);
        int e = k + 1;
        if p_tok(e).tk == TK_LPAREN &&
           (p_find_template(nm) != null || p_is_template_param(nm)) {
            str inner = p_generic_spelling_at(k);
            if inner == "" {
                return "";
            }
            p_spell_end = p_generic_spell_end;
            return out + inner;
        }
        if p_is_struct_name(nm) || p_is_enum_name(nm) || p_is_template_param(nm) ||
           p_is_cur_type_param(nm) || p_find_template(nm) != null {
            p_spell_end = e;
            return out + nm;
        }
        return "";
    }
    return "";
}

!!! Canonical spelling of the constant expression starting at k, used as a non-type
!!! template argument (`3`, `-2`, `N - 1`, `"abc"`). A string literal is re-quoted so
!!! the argument list can be split on commas unambiguously.
str p_const_spelling_at -> int k {
    p_spell_end = k;
    str out = "";
    int depth = 0;
    int j = k;
    while p_kind_at(j) != TK_EOF {
        Token t = p_tok(j);
        if depth == 0 && (t.tk == TK_COMMA || t.tk == TK_RPAREN) {
            skip;
        }
        if t.tk == TK_LPAREN {
            depth = depth + 1;
            out = out + "(";
            j = j + 1;
            continue;
        }
        if t.tk == TK_RPAREN {
            depth = depth - 1;
            out = out + ")";
            j = j + 1;
            continue;
        }
        if t.tk == TK_STRING {
            out = out + "\"";
            int c = t.start + 1;
            while c < t.stop - 1 {
                char ch = g_base[c];
                if ch == '\\' || ch == '"' {
                    out = out + "\\";
                    out = out + char_text(ch);
                } else if ch == '\n' {
                    out = out + "\\n";
                } else if ch == '\t' {
                    out = out + "\\t";
                } else {
                    out = out + char_text(ch);
                }
                c = c + 1;
            }
            out = out + "\"";
            j = j + 1;
            continue;
        }
        if t.tk == TK_CHAR || t.tk == TK_INTEGER || t.tk == TK_FLOAT ||
           t.tk == TK_IDENT || t.tk == TK_KEYWORD {
            out = out + span_text(t.start, t.stop);
            j = j + 1;
            continue;
        }
        if t.tk == TK_PLUS || t.tk == TK_MINUS || t.tk == TK_STAR || t.tk == TK_SLASH ||
           t.tk == TK_MOD || t.tk == TK_SHL || t.tk == TK_SHR || t.tk == TK_BITAND ||
           t.tk == TK_BITOR || t.tk == TK_BITXOR || t.tk == TK_BITNOT {
            out = out + span_text(t.start, t.stop);
            j = j + 1;
            continue;
        }
        return "";
    }
    if depth != 0 || out == "" {
        return "";
    }
    p_spell_end = j;
    return out;
}

!!! `Name(a, b)` for the generic type whose head is at k. Each entry is either a
!!! type (a bare template name included) or a constant expression, in the order the
!!! template declares its parameters. The entries are left in `p_spell_args` and the
!!! offset just past the ')' in `p_generic_spell_end`.
str p_generic_spelling_at -> int k {
    p_generic_spell_end = k;
    p_spell_args = null;
    if p_tok(k).tk != TK_IDENT {
        return "";
    }
    if p_tok(k + 1).tk != TK_LPAREN {
        return "";
    }
    str out = span_text(p_tok(k).start, p_tok(k).stop) + "(";
    int j = k + 2;
    bool first = true;
    @TArgSpell head = null;
    @TArgSpell tail = null;
    while p_kind_at(j) != TK_RPAREN && p_kind_at(j) != TK_EOF {
        TArgSpell proto;
        @TArgSpell e;
        malloc(@e, size proto);
        e.line = p_tok(j).line;
        e.col = p_tok(j).col;
        e.len = p_tok(j).stop - p_tok(j).start;
        e.is_value = false;
        e.known_type = false;
        e.spelling = "";
        e.next = null;
        if p_type_at(j) {
            e.known_type = true;
            e.spelling = p_type_spelling_at(j);
            if e.spelling == "" {
                return "";
            }
            j = p_spell_end;
        } else {
            if p_const_entry_at(j) {
                e.is_value = true;
                e.spelling = p_const_spelling_at(j);
                if e.spelling == "" {
                    return "";
                }
                j = p_spell_end;
            } else if p_tok(j).tk == TK_IDENT {
                !!! An unknown (or not yet visible) type name: kept as a type
                !!! argument, so the code generator reports the missing type instead
                !!! of a misleading "missing ')'".
                e.spelling = span_text(p_tok(j).start, p_tok(j).stop);
                j = j + 1;
            } else {
                return "";
            }
        }
        if !first {
            out = out + ",";
        }
        out = out + e.spelling;
        first = false;
        if head == null {
            head = e;
        } else {
            tail.next = e;
        }
        tail = e;
        if p_tok(j).tk == TK_COMMA {
            j = j + 1;
            continue;
        }
        skip;
    }
    if p_tok(j).tk != TK_RPAREN {
        return "";
    }
    p_generic_spell_end = j + 1;
    p_spell_args = head;
    return out + ")";
}

!!! The declared type of a value parameter, for a diagnostic.
str p_tparam_type_name -> VarType t {
    if t == BOOL {
        return "bool";
    }
    if t == FLOAT {
        return "float";
    }
    if t == STR {
        return "str";
    }
    if t == CHAR {
        return "char";
    }
    return "int";
}

@BoolNode p_chain_bool_at -> @BoolNode head, int i {
    @BoolNode n = head;
    int k = 0;
    while n != null {
        if k == i {
            return n;
        }
        n = n.next;
        k = k + 1;
    }
    return null;
}

@VarTypeNode p_chain_vt_at -> @VarTypeNode head, int i {
    @VarTypeNode n = head;
    int k = 0;
    while n != null {
        if k == i {
            return n;
        }
        n = n.next;
        k = k + 1;
    }
    return null;
}

int p_chain_len -> @StrNode head {
    int n = 0;
    @StrNode p = head;
    while p != null {
        n = n + 1;
        p = p.next;
    }
    return n;
}

!!! validate_struct_targs(): check `Box(int, 3)` against the template's own
!!! parameter list, so a wrong count or a type where a constant belongs is reported
!!! at the use site.
bool p_validate_struct_targs -> str tname, int line, int col, int hlen {
    @StructTemplate tmpl = p_find_template(tname);
    if tmpl == null {
        return true;
    }
    int want_n = p_chain_len(tmpl.tparams);
    int got_n = 0;
    @TArgSpell e = p_spell_args;
    while e != null {
        got_n = got_n + 1;
        e = e.next;
    }
    if want_n != got_n {
        !!! The two counts are joined into the message the way the toolchain snprintf does
        !!! it: a message is one string here, and `(str)int` is the conversion the
        !!! language's own number-to-text uses.
        str msg = "generic struct '" + tname + "' needs " + (str)want_n +
                  " type argument(s), got " + (str)got_n;
        p_error_at(line, col, hlen, msg);
        return false;
    }
    bool ok = true;
    e = p_spell_args;
    int i = 0;
    while e != null {
        @BoolNode wt = p_chain_bool_at(tmpl.tparam_is_template, i);
        @BoolNode wv = p_chain_bool_at(tmpl.tparam_is_value, i);
        @VarTypeNode wty = p_chain_vt_at(tmpl.tparam_types, i);
        bool want_tmpl = wt != null && wt.v;
        bool want_val = wv != null && wv.v;
        VarType want = INT;
        if wty != null {
            want = wty.ty;
        }
        str num = (str)(i + 1) + " of '" + tname + "'";
        if want_tmpl {
            if e.is_value || p_is_generic_spelling(e.spelling) {
                p_error_at(e.line, e.col, e.len, "argument " + num + " must be a template name");
                ok = false;
            } else if p_find_template(e.spelling) == null && !p_is_template_param(e.spelling) {
                p_error_at(e.line, e.col, e.len, "unknown generic struct '" + e.spelling + "'");
                ok = false;
            }
        } else if want_val {
            if !e.is_value {
                p_error_at(e.line, e.col, e.len,
                           "argument " + num + " must be a constant " +
                           p_tparam_type_name(want) + " expression");
                ok = false;
            }
        } else {
            if e.is_value {
                p_error_at(e.line, e.col, e.len, "argument " + num + " must be a type, got a value");
                ok = false;
            } else if p_find_template(e.spelling) != null && !p_is_generic_spelling(e.spelling) {
                p_error_at(e.line, e.col, e.len,
                           "argument " + num + " must be a type, got the template '" +
                           e.spelling + "'");
                ok = false;
            } else if !e.known_type && !p_is_generic_spelling(e.spelling) &&
                       p_find_template(e.spelling) == null {
                p_error_at(e.line, e.col, e.len, "undeclared type '" + e.spelling + "'");
                ok = false;
            }
        }
        e = e.next;
        i = i + 1;
    }
    return ok;
}

!!! at_explicit_type_args(): true when the token on the parser opens a template
!!! argument list followed by '(' - the head of `name(T1, 5)(args)`.
bool p_at_explicit_type_args {
    if !p_is(TK_LPAREN) {
        return false;
    }
    int k = p_pos + 1;
    if p_tok(k).tk == TK_RPAREN || p_tok(k).tk == TK_EOF {
        return false;
    }
    while true {
        if p_type_at(k) {
            k = p_skip_type_at(k);
        } else {
            if !p_const_entry_at(k) {
                return false;
            }
            k = p_spell_end;
        }
        if p_tok(k).tk == TK_COMMA {
            k = k + 1;
            continue;
        }
        skip;
    }
    if p_tok(k).tk != TK_RPAREN {
        return false;
    }
    k = k + 1;
    return p_tok(k).tk == TK_LPAREN;
}

!!! at_generic_type_head(): `Box(int)` / `C(T)` at the start of a type - a struct
!!! template or a template-template parameter followed by an argument list.
bool p_at_generic_type_head {
    if !p_is(TK_IDENT) {
        return false;
    }
    if !p_peek_is(1, TK_LPAREN) {
        return false;
    }
    str nm = span_text(p_cur.start, p_cur.stop);
    return p_find_template(nm) != null || p_is_template_param(nm);
}

!!! is_ptr_operator_decl(): true when the type starting here is followed by the
!!! `operator` keyword, which `@Vec operator []` puts behind the pointer tokens.
bool p_is_ptr_operator_decl {
    int k = p_pos;
    if p_tok(k).tk != TK_AT {
        return false;
    }
    while p_kind_at(k) == TK_AT {
        k = k + 1;
    }
    if p_tok(k).tk == TK_KEYWORD || p_tok(k).tk == TK_IDENT {
        k = k + 1;
    } else {
        return false;
    }
    !!! A generic argument list such as `@Box(int)`.
    if p_tok(k).tk == TK_LPAREN {
        int depth = 0;
        while p_kind_at(k) != TK_EOF {
            if p_tok(k).tk == TK_LPAREN {
                depth = depth + 1;
                k = k + 1;
                continue;
            }
            if p_tok(k).tk == TK_RPAREN {
                depth = depth - 1;
                k = k + 1;
                if depth == 0 {
                    skip;
                }
                continue;
            }
            k = k + 1;
        }
    }
    return p_tok(k).tk == TK_KEYWORD && p_span_is(p_tok(k), "operator");
}

!!! is_decl_or_func_start(): a statement that starts with a type, or with a
!!! builtin-object annotation (`__get_format__ printf -> ...`).
bool p_is_decl_or_func_start {
    if p_is_type() {
        return true;
    }
    if p_is(TK_IDENT) {
        str nm = span_text(p_cur.start, p_cur.stop);
        @BuiltinFunc b = find_builtin(nm);
        if b != null && b.returns_object && p_in_str_chain(p_registered_builtins, nm) {
            return true;
        }
    }
    return false;
}

!!! peek_is_function(): whether the statement in front of the parser is a function
!!! (`type name {` or `type name -> ...`) rather than a value declaration
!!! (`type name ;`, `type name = ...`, `type name [...]`).
bool p_peek_is_function {
    int look = p_pos;
    while p_kind_at(look) == TK_AT {
        look = look + 1;
    }
    !!! Qualifiers in front of the type: `const int f { ... }` and `ref int f { ... }`
    !!! are function heads, not declarations.
    while p_kind_at(look) == TK_KEYWORD &&
          (p_tok_is(look, "ref") || p_tok_is(look, "const") ||
           p_tok_is(look, "static") || p_tok_is(look, "utype")) {
        look = look + 1;
    }
    !!! A generic struct type carries its argument list: `Box(int) make { ... }`.
    bool generic = false;
    if p_tok(look).tk == TK_IDENT {
        str nm = span_text(p_tok(look).start, p_tok(look).stop);
        if (p_find_template(nm) != null || p_is_template_param(nm)) &&
           p_tok(look + 1).tk == TK_LPAREN {
            generic = true;
        }
    }
    if generic {
        int depth = 0;
        while p_kind_at(look) != TK_EOF {
            if p_tok(look).tk == TK_LPAREN {
                depth = depth + 1;
            } else if p_tok(look).tk == TK_RPAREN {
                depth = depth - 1;
                if depth == 0 {
                    look = look + 1;
                    skip;
                }
            }
            look = look + 1;
        }
    } else {
        look = look + 1;
    }
    if p_tok(look).tk == TK_IDENT {
        look = look + 1;
        !!! A qualified function name: `name::name`.
        while p_kind_at(look) == TK_SCOPE && p_kind_at(look + 1) == TK_IDENT {
            look = look + 2;
        }
    }
    if p_tok(look).tk == TK_LBRACE {
        return true;
    }
    if p_tok(look).tk == TK_MINUS && p_tok(look + 1).tk == TK_GT {
        return true;
    }
    return false;
}

!!! parse_decl_or_func(): a statement that starts with a type is one or the other.
@StmtNode p_decl_or_func {
    if p_peek_is_function() {
        return p_function(false);
    }
    return p_declare();
}

!!! Parse one type. The VarType of the value is answered and everything else it
!!! carried - the pointer depth, `ref`/`const`/`static`/`utype`, and the name of the
!!! struct it names - is left in the `p_last_*` fields.
VarType p_type {
    p_last_ptr_depth = 0;
    p_last_is_ref = false;
    p_last_is_struct_ptr = false;
    p_last_is_const = false;
    p_last_is_static = false;
    p_last_is_unsigned = false;
    p_last_struct = "";
    !!! `const T`, `static T` and `utype T` sit in front of the type and mean the
    !!! same in either order, which is why the walk is a loop.
    while p_is(TK_KEYWORD) &&
          (p_name_is("const") || p_name_is("static") || p_name_is("utype")) {
        if p_name_is("const") {
            p_last_is_const = true;
        } else if p_name_is("static") {
            p_last_is_static = true;
        } else {
            p_last_is_unsigned = true;
        }
        p_adv();
    }
    !!! `ref T` is a pointer in the shape it is handed around with: the value is the
    !!! address of the argument, and a use of the name reads through it.
    if p_is(TK_KEYWORD) && p_name_is("ref") {
        p_adv();
        p_last_is_ref = true;
        p_last_ptr_depth = 1;
        if p_is(TK_KEYWORD) && p_take_builtin_kw() {
            return pointer_to(p_last_builtin);
        }
        if p_is(TK_IDENT) {
            p_last_struct = span_text(p_cur.start, p_cur.stop);
            p_last_is_struct_ptr = true;
            p_adv();
            return AT_INT;
        }
        p_error_cur("missing type after 'ref'");
        return AT_INT;
    }
    if p_is(TK_AT) {
        int depth = 0;
        while p_is(TK_AT) {
            p_adv();
            depth = depth + 1;
        }
        p_last_ptr_depth = depth;
        !!! `@StructName`: the address of a struct, which is what makes a
        !!! self-referential type possible.
        if p_is(TK_IDENT) {
            str nm = span_text(p_cur.start, p_cur.stop);
            if p_is_struct_name(nm) {
                p_last_struct = nm;
                p_last_is_struct_ptr = true;
                p_adv();
                return AT_INT;
            }
            !!! `@Box(int)`: a pointer to an instantiated generic struct.
            if p_at_generic_type_head() {
                str sp = p_generic_spelling_at(p_pos);
                if sp != "" {
                    if !p_validate_struct_targs(nm, p_cur.line, p_cur.col,
                                                p_cur.stop - p_cur.start) {
                        return AT_INT;
                    }
                    p_pos = p_generic_spell_end;
                    p_cur = g_tokens.get(p_pos);
                    p_last_struct = sp;
                    p_last_is_struct_ptr = true;
                    return AT_INT;
                }
            }
            !!! `@Box` inside the generic struct's own body: a pointer to the
            !!! instantiation being built, the injected class name.
            if p_find_template(nm) != null {
                p_last_struct = nm;
                p_last_is_struct_ptr = true;
                p_adv();
                return AT_INT;
            }
            !!! `@T`: a pointer to a type parameter. The name travels like the
            !!! value form, and instantiation replaces it with the concrete type.
            if p_is_template_param(nm) || p_is_cur_type_param(nm) {
                p_last_struct = nm;
                p_last_is_struct_ptr = true;
                p_adv();
                return AT_INT;
            }
        }
        if p_is(TK_KEYWORD) && p_take_builtin_kw() {
            return pointer_to(p_last_builtin);
        }
        p_error_cur("missing type after '@'");
        return AT_INT;
    }
    if p_is(TK_KEYWORD) && p_take_builtin_kw() {
        return p_last_builtin;
    }
    !!! A package-qualified type name: `pkg::Type`.
    if p_is(TK_IDENT) && p_peek_is(1, TK_SCOPE) && p_peek_is(2, TK_IDENT) {
        str nm = span_text(p_cur.start, p_cur.stop) + "::" +
                 span_text(p_peek(2).start, p_peek(2).stop);
        p_adv();
        p_adv();
        p_adv();
        p_last_struct = nm;
        return INT;
    }
    !!! A struct type name, a generic struct written with its arguments, a generic
    !!! struct named without them (the injected class name inside its own body), an
    !!! enum name, or a type parameter of the introduce block being parsed.
    if p_is(TK_IDENT) {
        str nm = span_text(p_cur.start, p_cur.stop);
        if p_is_struct_name(nm) {
            p_last_struct = nm;
            p_adv();
            return INT;
        }
        if p_at_generic_type_head() {
            str sp = p_generic_spelling_at(p_pos);
            if sp == "" {
                p_error_cur("missing ')' in template argument list");
                return INT;
            }
            if !p_validate_struct_targs(nm, p_cur.line, p_cur.col, p_cur.stop - p_cur.start) {
                return INT;
            }
            p_pos = p_generic_spell_end;
            p_cur = g_tokens.get(p_pos);
            p_last_struct = sp;
            return INT;
        }
        if p_find_template(nm) != null {
            p_last_struct = nm;
            p_adv();
            return INT;
        }
        if p_is_enum_name(nm) {
            p_adv();
            return INT;
        }
        if p_is_template_param(nm) || p_is_cur_type_param(nm) {
            p_last_struct = nm;
            p_adv();
            return INT;
        }
    }
    p_error_cur("missing type");
    return INT;
}
