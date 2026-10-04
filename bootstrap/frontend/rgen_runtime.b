#once
!~
 ~  bootstrap/frontend/rgen_runtime.b: the frontend/rgen_runtime, the
 ~  builtin runtime written as .r source.
 ~
 ~  `__get_format__` parses a format string plus an `any` variadic array and returns
 ~  an object; `__format_out__` walks that object and calls the printing builtins.
 ~  The object is an @void array (8-byte slots): {0} is the item count, {1} the
 ~  format pointer, then the items at {3+i*3} = (value, kind, precision), where kind
 ~  0 = literal, 1 = int, 2 = str, 3 = char, 4 = bool, 5 = float, 6 = ptr, 7 = long,
 ~  8 = unsigned int, 9 = unsigned long.
 ~
 ~  the toolchain holds both texts in one raw string literal each and appends them to
 ~  `rcode` only when the builtin was activated by a `__get_built_in_func<...>`
 ~  binding (`parser.get_registered_builtins()`), which is the `p_registered_builtins`
 ~  chain of parser.b here. The text is written out one line at a time through
 ~  rgx_rt: the characters of a line are exactly the characters the toolchain raw string
 ~  holds, because the backend reads this text verbatim. A backslash and a double
 ~  quote inside a line are written `\\` and `\"`, which is how a blang literal spells
 ~  those two characters.
 ~!

#head "rgen"

!!! One line of the runtime text and the line break after it.
str rgx_rt -> str text, str line {
    return text + line + "\n";
}

!!! `parser.get_registered_builtins().count(name)`: whether a builtin was activated
!!! by a `__get_built_in_func<...>` binding, which is what decides whether its
!!! public .r FUNC is written at all.
bool rgx_builtin_registered -> str name {
    @StrNode b = p_registered_builtins;
    while b != null {
        if p_text_eq(b.s, name) {
            return true;
        }
        b = b.next;
    }
    return false;
}

void rg_emit_builtin_runtime {
    !!! All internal names carry a `__gf_` / `__fo_` prefix so they never collide
    !!! with user symbols or with each other across the flat .r scope.
    str get_format = "\n";
    get_format = rgx_rt(get_format, "FUNC __get_format__ AT_VOID (STR __gf_fmt, ANY __gf_rest{}...) THEN (");
    get_format = rgx_rt(get_format, "DECLARED AT_VOID __gf_obj{768}");
    get_format = rgx_rt(get_format, "DECLARED INT __gf_p , 0");
    get_format = rgx_rt(get_format, "DECLARED INT __gf_ai , 0");
    get_format = rgx_rt(get_format, "DECLARED INT __gf_count , 0");
    get_format = rgx_rt(get_format, "DECLARED INT __gf_idx , 0");
    get_format = rgx_rt(get_format, "DECLARED INT __gf_lit_start , 0");
    get_format = rgx_rt(get_format, "DECLARED INT __gf_in_lit , 0");
    get_format = rgx_rt(get_format, "DECLARED INT __gf_prec , 0");
    get_format = rgx_rt(get_format, "DECLARED INT __gf_lu , 0");
    get_format = rgx_rt(get_format, "DECLARED CHAR __gf_spec , 0");
    get_format = rgx_rt(get_format, "DECLARED AT_VOID __gf_cell , null");
    get_format = rgx_rt(get_format, "REPEAT ((__gf_fmt{__gf_p} , '\\0' , \\\\)) THEN (");
    get_format = rgx_rt(get_format, "IF ((__gf_fmt{__gf_p} , '%' , //)) THEN (");
    get_format = rgx_rt(get_format, "IF ((__gf_in_lit , 0 , \\\\)) THEN (");
    get_format = rgx_rt(get_format, "CAST __gf_idx , ((__gf_count , 3 , *) , 3 , +)");
    get_format = rgx_rt(get_format, "CAST __gf_obj{__gf_idx} , __gf_lit_start");
    get_format = rgx_rt(get_format, "CAST __gf_obj{(__gf_idx , 1 , +)} , 0");
    get_format = rgx_rt(get_format, "CAST __gf_obj{(__gf_idx , 2 , +)} , (__gf_p , __gf_lit_start , -)");
    get_format = rgx_rt(get_format, "CAST __gf_count , (__gf_count , 1 , +)");
    get_format = rgx_rt(get_format, "CAST __gf_in_lit , 0");
    get_format = rgx_rt(get_format, ") ELSE ()");
    get_format = rgx_rt(get_format, "IF ((__gf_fmt{(__gf_p , 1 , +)} , '%' , //)) THEN (");
    get_format = rgx_rt(get_format, "CAST __gf_idx , ((__gf_count , 3 , *) , 3 , +)");
    get_format = rgx_rt(get_format, "CAST __gf_obj{__gf_idx} , __gf_p");
    get_format = rgx_rt(get_format, "CAST __gf_obj{(__gf_idx , 1 , +)} , 0");
    get_format = rgx_rt(get_format, "CAST __gf_obj{(__gf_idx , 2 , +)} , 1");
    get_format = rgx_rt(get_format, "CAST __gf_count , (__gf_count , 1 , +)");
    get_format = rgx_rt(get_format, "CAST __gf_p , (__gf_p , 2 , +)");
    get_format = rgx_rt(get_format, ") ELSE (");
    get_format = rgx_rt(get_format, "CAST __gf_spec , __gf_fmt{(__gf_p , 1 , +)}");
    get_format = rgx_rt(get_format, "CAST __gf_p , (__gf_p , 2 , +)");
    get_format = rgx_rt(get_format, "IF ((__gf_spec , 'p' , //)) THEN (");
    get_format = rgx_rt(get_format, "CAST __gf_prec , 16");
    get_format = rgx_rt(get_format, ") ELSE (");
    get_format = rgx_rt(get_format, "CAST __gf_prec , 6");
    get_format = rgx_rt(get_format, ")");
    get_format = rgx_rt(get_format, "IF ((((__gf_spec , 'f' , //) , (__gf_spec , 'p' , //) , ||) , (__gf_fmt{__gf_p} , '.' , //) , &&)) THEN (");
    get_format = rgx_rt(get_format, "CAST __gf_p , (__gf_p , 1 , +)");
    get_format = rgx_rt(get_format, "CAST __gf_prec , 0");
    get_format = rgx_rt(get_format, "REPEAT (((__gf_fmt{__gf_p} , '0' , //=) , (__gf_fmt{__gf_p} , '9' , <//) , &&)) THEN (");
    get_format = rgx_rt(get_format, "CAST __gf_prec , ((__gf_prec , 10 , *) , (__gf_fmt{__gf_p} , '0' , -) , +)");
    get_format = rgx_rt(get_format, "CAST __gf_p , (__gf_p , 1 , +)");
    get_format = rgx_rt(get_format, ")");
    get_format = rgx_rt(get_format, ") ELSE ()");
    get_format = rgx_rt(get_format, "SWITCH (__gf_spec) THEN (");
    get_format = rgx_rt(get_format, "CASE 'd':");
    get_format = rgx_rt(get_format, "CAST __gf_idx , ((__gf_count , 3 , *) , 3 , +)");
    get_format = rgx_rt(get_format, "CAST __gf_obj{__gf_idx} , __gf_rest{__gf_ai}");
    get_format = rgx_rt(get_format, "CAST __gf_obj{(__gf_idx , 1 , +)} , 1");
    get_format = rgx_rt(get_format, "CAST __gf_obj{(__gf_idx , 2 , +)} , 0");
    get_format = rgx_rt(get_format, "CAST __gf_count , (__gf_count , 1 , +)");
    get_format = rgx_rt(get_format, "CAST __gf_ai , (__gf_ai , 1 , +)");
    get_format = rgx_rt(get_format, "END");
    get_format = rgx_rt(get_format, "CASE 'u':");
    get_format = rgx_rt(get_format, "CAST __gf_idx , ((__gf_count , 3 , *) , 3 , +)");
    get_format = rgx_rt(get_format, "CAST __gf_obj{__gf_idx} , __gf_rest{__gf_ai}");
    get_format = rgx_rt(get_format, "CAST __gf_obj{(__gf_idx , 1 , +)} , 8");
    get_format = rgx_rt(get_format, "CAST __gf_obj{(__gf_idx , 2 , +)} , 0");
    get_format = rgx_rt(get_format, "CAST __gf_count , (__gf_count , 1 , +)");
    get_format = rgx_rt(get_format, "CAST __gf_ai , (__gf_ai , 1 , +)");
    get_format = rgx_rt(get_format, "END");
    get_format = rgx_rt(get_format, "CASE 'l':");
    get_format = rgx_rt(get_format, "CAST __gf_lu , 0");
    get_format = rgx_rt(get_format, "IF ((__gf_fmt{__gf_p} , 'u' , //)) THEN (");
    get_format = rgx_rt(get_format, "CAST __gf_lu , 1");
    get_format = rgx_rt(get_format, ") ELSE ()");
    get_format = rgx_rt(get_format, "REPEAT ((__gf_fmt{__gf_p} , 'l' , //)) THEN (");
    get_format = rgx_rt(get_format, "IF ((__gf_fmt{(__gf_p , 1 , +)} , 'u' , //)) THEN (");
    get_format = rgx_rt(get_format, "CAST __gf_lu , 1");
    get_format = rgx_rt(get_format, ") ELSE ()");
    get_format = rgx_rt(get_format, "CAST __gf_p , (__gf_p , 1 , +)");
    get_format = rgx_rt(get_format, ")");
    get_format = rgx_rt(get_format, "CAST __gf_idx , ((__gf_count , 3 , *) , 3 , +)");
    get_format = rgx_rt(get_format, "CAST __gf_obj{__gf_idx} , __gf_rest{__gf_ai}");
    get_format = rgx_rt(get_format, "IF ((__gf_lu , 0 , //)) THEN (");
    get_format = rgx_rt(get_format, "CAST __gf_obj{(__gf_idx , 1 , +)} , 7");
    get_format = rgx_rt(get_format, ") ELSE (");
    get_format = rgx_rt(get_format, "CAST __gf_obj{(__gf_idx , 1 , +)} , 9");
    get_format = rgx_rt(get_format, ")");
    get_format = rgx_rt(get_format, "CAST __gf_obj{(__gf_idx , 2 , +)} , 0");
    get_format = rgx_rt(get_format, "CAST __gf_count , (__gf_count , 1 , +)");
    get_format = rgx_rt(get_format, "CAST __gf_ai , (__gf_ai , 1 , +)");
    get_format = rgx_rt(get_format, "REPEAT ((((__gf_fmt{__gf_p} , 'l' , //) , (__gf_fmt{__gf_p} , 'd' , //) , ||) , (__gf_fmt{__gf_p} , 'u' , //) , ||)) THEN (");
    get_format = rgx_rt(get_format, "CAST __gf_p , (__gf_p , 1 , +)");
    get_format = rgx_rt(get_format, ")");
    get_format = rgx_rt(get_format, "END");
    get_format = rgx_rt(get_format, "CASE 's':");
    get_format = rgx_rt(get_format, "CAST __gf_idx , ((__gf_count , 3 , *) , 3 , +)");
    get_format = rgx_rt(get_format, "CAST __gf_obj{__gf_idx} , __gf_rest{__gf_ai}");
    get_format = rgx_rt(get_format, "CAST __gf_obj{(__gf_idx , 1 , +)} , 2");
    get_format = rgx_rt(get_format, "CAST __gf_obj{(__gf_idx , 2 , +)} , 0");
    get_format = rgx_rt(get_format, "CAST __gf_count , (__gf_count , 1 , +)");
    get_format = rgx_rt(get_format, "CAST __gf_ai , (__gf_ai , 1 , +)");
    get_format = rgx_rt(get_format, "END");
    get_format = rgx_rt(get_format, "CASE 'c':");
    get_format = rgx_rt(get_format, "CAST __gf_idx , ((__gf_count , 3 , *) , 3 , +)");
    get_format = rgx_rt(get_format, "CAST __gf_obj{__gf_idx} , __gf_rest{__gf_ai}");
    get_format = rgx_rt(get_format, "CAST __gf_obj{(__gf_idx , 1 , +)} , 3");
    get_format = rgx_rt(get_format, "CAST __gf_obj{(__gf_idx , 2 , +)} , 0");
    get_format = rgx_rt(get_format, "CAST __gf_count , (__gf_count , 1 , +)");
    get_format = rgx_rt(get_format, "CAST __gf_ai , (__gf_ai , 1 , +)");
    get_format = rgx_rt(get_format, "END");
    get_format = rgx_rt(get_format, "CASE 'b':");
    get_format = rgx_rt(get_format, "CAST __gf_idx , ((__gf_count , 3 , *) , 3 , +)");
    get_format = rgx_rt(get_format, "CAST __gf_obj{__gf_idx} , __gf_rest{__gf_ai}");
    get_format = rgx_rt(get_format, "CAST __gf_obj{(__gf_idx , 1 , +)} , 4");
    get_format = rgx_rt(get_format, "CAST __gf_obj{(__gf_idx , 2 , +)} , 0");
    get_format = rgx_rt(get_format, "CAST __gf_count , (__gf_count , 1 , +)");
    get_format = rgx_rt(get_format, "CAST __gf_ai , (__gf_ai , 1 , +)");
    get_format = rgx_rt(get_format, "END");
    get_format = rgx_rt(get_format, "CASE 'f':");
    get_format = rgx_rt(get_format, "BCALL \"_malloc\" (AT __gf_cell) , 8");
    get_format = rgx_rt(get_format, "DREF __gf_cell , __gf_rest{__gf_ai}");
    get_format = rgx_rt(get_format, "CAST __gf_idx , ((__gf_count , 3 , *) , 3 , +)");
    get_format = rgx_rt(get_format, "CAST __gf_obj{__gf_idx} , __gf_cell");
    get_format = rgx_rt(get_format, "CAST __gf_obj{(__gf_idx , 1 , +)} , 5");
    get_format = rgx_rt(get_format, "CAST __gf_obj{(__gf_idx , 2 , +)} , __gf_prec");
    get_format = rgx_rt(get_format, "CAST __gf_count , (__gf_count , 1 , +)");
    get_format = rgx_rt(get_format, "CAST __gf_ai , (__gf_ai , 1 , +)");
    get_format = rgx_rt(get_format, "END");
    get_format = rgx_rt(get_format, "CASE 'p':");
    get_format = rgx_rt(get_format, "CAST __gf_idx , ((__gf_count , 3 , *) , 3 , +)");
    get_format = rgx_rt(get_format, "CAST __gf_obj{__gf_idx} , __gf_rest{__gf_ai}");
    get_format = rgx_rt(get_format, "CAST __gf_obj{(__gf_idx , 1 , +)} , 6");
    get_format = rgx_rt(get_format, "CAST __gf_obj{(__gf_idx , 2 , +)} , __gf_prec");
    get_format = rgx_rt(get_format, "CAST __gf_count , (__gf_count , 1 , +)");
    get_format = rgx_rt(get_format, "CAST __gf_ai , (__gf_ai , 1 , +)");
    get_format = rgx_rt(get_format, "END");
    get_format = rgx_rt(get_format, "UNMATCH:");
    get_format = rgx_rt(get_format, "END");
    get_format = rgx_rt(get_format, ")");
    get_format = rgx_rt(get_format, ")");
    get_format = rgx_rt(get_format, ") ELSE (");
    get_format = rgx_rt(get_format, "IF ((__gf_in_lit , 0 , //)) THEN (");
    get_format = rgx_rt(get_format, "CAST __gf_in_lit , 1");
    get_format = rgx_rt(get_format, "CAST __gf_lit_start , __gf_p");
    get_format = rgx_rt(get_format, ") ELSE ()");
    get_format = rgx_rt(get_format, "CAST __gf_p , (__gf_p , 1 , +)");
    get_format = rgx_rt(get_format, ")");
    get_format = rgx_rt(get_format, ")");
    get_format = rgx_rt(get_format, "IF ((__gf_in_lit , 0 , \\\\)) THEN (");
    get_format = rgx_rt(get_format, "CAST __gf_idx , ((__gf_count , 3 , *) , 3 , +)");
    get_format = rgx_rt(get_format, "CAST __gf_obj{__gf_idx} , __gf_lit_start");
    get_format = rgx_rt(get_format, "CAST __gf_obj{(__gf_idx , 1 , +)} , 0");
    get_format = rgx_rt(get_format, "CAST __gf_obj{(__gf_idx , 2 , +)} , (__gf_p , __gf_lit_start , -)");
    get_format = rgx_rt(get_format, "CAST __gf_count , (__gf_count , 1 , +)");
    get_format = rgx_rt(get_format, ") ELSE ()");
    get_format = rgx_rt(get_format, "CAST __gf_obj{0} , __gf_count");
    get_format = rgx_rt(get_format, "CAST __gf_obj{1} , __gf_fmt");
    get_format = rgx_rt(get_format, "RET __gf_obj");
    get_format = rgx_rt(get_format, ")");

    str format_out = "\n";
    format_out = rgx_rt(format_out, "FUNC __format_out__ AT_VOID (AT_VOID __fo_obj{}) THEN (");
    format_out = rgx_rt(format_out, "DECLARED INT __fo_count , __fo_obj{0}");
    format_out = rgx_rt(format_out, "DECLARED STR __fo_fmt , null");
    format_out = rgx_rt(format_out, "CAST __fo_fmt , __fo_obj{1}");
    format_out = rgx_rt(format_out, "DECLARED INT __fo_i , 0");
    format_out = rgx_rt(format_out, "DECLARED INT __fo_idx , 0");
    format_out = rgx_rt(format_out, "DECLARED INT __fo_k , 0");
    format_out = rgx_rt(format_out, "DECLARED AT_VOID __fo_val , null");
    format_out = rgx_rt(format_out, "DECLARED INT __fo_prec , 0");
    format_out = rgx_rt(format_out, "DECLARED INT __fo_off , 0");
    format_out = rgx_rt(format_out, "REPEAT ((__fo_i , __fo_count , <)) THEN (");
    format_out = rgx_rt(format_out, "CAST __fo_idx , ((__fo_i , 3 , *) , 3 , +)");
    format_out = rgx_rt(format_out, "CAST __fo_val , __fo_obj{__fo_idx}");
    format_out = rgx_rt(format_out, "CAST __fo_k , __fo_obj{(__fo_idx , 1 , +)}");
    format_out = rgx_rt(format_out, "CAST __fo_prec , __fo_obj{(__fo_idx , 2 , +)}");
    format_out = rgx_rt(format_out, "SWITCH (__fo_k) THEN (");
    format_out = rgx_rt(format_out, "CASE 0:");
    format_out = rgx_rt(format_out, "CAST __fo_off , __fo_val");
    format_out = rgx_rt(format_out, "BCALL \"_printf_n\" __fo_fmt , __fo_off , __fo_prec");
    format_out = rgx_rt(format_out, "END");
    format_out = rgx_rt(format_out, "CASE 1:");
    format_out = rgx_rt(format_out, "BCALL \"_printf_d\" __fo_val");
    format_out = rgx_rt(format_out, "END");
    format_out = rgx_rt(format_out, "CASE 7:");
    format_out = rgx_rt(format_out, "BCALL \"_printf_l\" __fo_val");
    format_out = rgx_rt(format_out, "END");
    format_out = rgx_rt(format_out, "CASE 8:");
    format_out = rgx_rt(format_out, "BCALL \"_printf_u\" __fo_val");
    format_out = rgx_rt(format_out, "END");
    format_out = rgx_rt(format_out, "CASE 9:");
    format_out = rgx_rt(format_out, "BCALL \"_printf_ul\" __fo_val");
    format_out = rgx_rt(format_out, "END");
    format_out = rgx_rt(format_out, "CASE 2:");
    format_out = rgx_rt(format_out, "BCALL \"_printf_s\" __fo_val");
    format_out = rgx_rt(format_out, "END");
    format_out = rgx_rt(format_out, "CASE 3:");
    format_out = rgx_rt(format_out, "BCALL \"_printf_c\" __fo_val");
    format_out = rgx_rt(format_out, "END");
    format_out = rgx_rt(format_out, "CASE 4:");
    format_out = rgx_rt(format_out, "IF ((__fo_val , 0 , //)) THEN (");
    format_out = rgx_rt(format_out, "BCALL \"_printf_s\" \"false\"");
    format_out = rgx_rt(format_out, ") ELSE (");
    format_out = rgx_rt(format_out, "BCALL \"_printf_s\" \"true\"");
    format_out = rgx_rt(format_out, ")");
    format_out = rgx_rt(format_out, "END");
    format_out = rgx_rt(format_out, "CASE 5:");
    format_out = rgx_rt(format_out, "BCALL \"_printf_f\" (DL @float __fo_val) , __fo_prec");
    format_out = rgx_rt(format_out, "END");
    format_out = rgx_rt(format_out, "CASE 6:");
    format_out = rgx_rt(format_out, "BCALL \"_printf_p\" __fo_val , __fo_prec");
    format_out = rgx_rt(format_out, "END");
    format_out = rgx_rt(format_out, "UNMATCH:");
    format_out = rgx_rt(format_out, "END");
    format_out = rgx_rt(format_out, ")");
    format_out = rgx_rt(format_out, "CAST __fo_i , (__fo_i , 1 , +)");
    format_out = rgx_rt(format_out, ")");
    format_out = rgx_rt(format_out, "RET __fo_obj");
    format_out = rgx_rt(format_out, ")");

    !!! The public .r FUNCs are emitted on demand: only when a builtin has been
    !!! activated does its FUNC go into rcode.
    if rgx_builtin_registered("__get_format__") {
        rg_rcode = rg_rcode + get_format;
    }
    if rgx_builtin_registered("__format_out__") {
        rg_rcode = rg_rcode + format_out;
    }
}
