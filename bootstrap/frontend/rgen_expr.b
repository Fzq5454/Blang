#once
!~
 ~  bootstrap/frontend/rgen_expr.b: the frontend/rgen_expr.
 ~
 ~  One expression as .r text. rc_expr() is the emitter: a literal, a bare name
 ~  (with its builtin-annotation, lambda-capture, method-argument, struct-field,
 ~  function-value, reference and unsigned-char forms), a binary operation (with
 ~  compile-time string concatenation, pointer arithmetic and the unsigned runtime
 ~  helpers), a unary operation, a cast, a member access through its many shapes
 ~  (field of an array element, chain rooted at a name or at an element, pointer
 ~  chains), `size`, a subscript, a field element, a call (struct BAPI method, struct
 ~  method, implicit method, BLANG_API, indirect and plain), `@`, the increments, the
 ~  conditional operator and a lambda literal.
 ~
 ~  Two static helpers file (chain_root_kind, chain_root_struct_type) and
 ~  the two lambdas rc_expr uses for a lambda capture name stand here with the
 ~  `rgx_expr_` prefix, because rgen.b has no such helper.
 ~
 ~  Every append to `rcode` is written `rg_rcode = rg_rcode + text` here:
 ~  compound assignment is not part of the language (parser_stmt.b reports it as an
 ~  invalid operator). A `break` out of the switch is `end;`, because rc_expr
 ~  has nothing after the switch, so leaving the switch and leaving the function
 ~  are the same thing.
 ~!

#head "rgen"

!!! ---- the text of a float literal ----
!!!
!!! the toolchain hands the value to snprintf("%.17g"), which prints the exact value of
!!! the double rounded to seventeen significant digits. The language has no such
!!! conversion to call: `(str)float` prints six digits after the point, which turns
!!! 0.0000001 into 0.000000 and 4294967296.0 into 4294967296.000000 - a literal
!!! that no longer means what it said. The digits are therefore computed here, from
!!! the way a double is built: every double is m * 2^e with m a whole number below
!!! 2^53, so its value is either m * 2^e (e >= 0), a whole number, or m * 5^-e
!!! divided by 10^-e (e < 0). Both are a whole number over a power of ten, and that
!!! whole number is built limb by limb in base 10^9, so the seventeenth digit comes
!!! out the way printf rounds it - `3.9` prints as 3.8999999999999999, because that
!!! is what the double the source wrote really holds.

!!! One byte as `ooo`: three octal digits, the spelling the `.r` carries a character
!!! outside the printable range in and the one the backend reads back.
str rgx_octal3 -> int v {
    int a = v / 64;
    int b = (v % 64) / 8;
    int c = v % 8;
    return char_text((char)(48 + a)) + char_text((char)(48 + b)) + char_text((char)(48 + c));
}

!!! One byte of a string literal as the `.r` format writes it: the escapes of the
!!! language written back out, everything else as it stands. This is the switch of
!!! the toolchain emitter (rgen_expr), case for case: `\n`, `\r`, `\t`, a NUL as
!!! `\0`, a backslash and a quote doubled, and any other byte - a control byte an
!!! escape named, such as the 7 of `\a` - written as it is.
str rgx_r_escape -> char chc {
    if chc == '\n' {
        return "\\n";
    }
    if chc == '\r' {
        return "\\r";
    }
    if chc == '\t' {
        return "\\t";
    }
    if chc == (char)0 {
        return "\\0";
    }
    if chc == '\\' {
        return "\\\\";
    }
    if chc == '"' {
        return "\\\"";
    }
    return char_text(chc);
}

!!! One limb (below 10^9) as text, with no leading zeros and no sign.
str rgx_ft_limb_text -> longlong v {
    if v == 0 {
        return "0";
    }
    str out = "";
    while v > 0 {
        int d = (int)(v % 10);
        out = (str)d + out;
        v = v / 10;
    }
    return out;
}

!!! `limbs = limbs * f` in base 10^9, answering the new limb count. Only small
!!! factors (2 and 5) are ever needed.
int rgx_ft_mul -> @longlong limbs, int n, int f {
    longlong carry = 0;
    int i = 0;
    while i < n {
        longlong t = limbs[i] * (longlong)f + carry;
        limbs[i] = t % 1000000000;
        carry = t / 1000000000;
        i = i + 1;
    }
    while carry > 0 {
        limbs[n] = carry % 1000000000;
        carry = carry / 1000000000;
        n = n + 1;
    }
    return n;
}

!!! One more, added to a string of decimal digits: "39" -> "40", and "99" -> "100"
!!! (one digit longer, which the caller has to notice).
str rgx_ft_digits_add_one -> str s {
    int n = pe_len(s);
    str out = "";
    int i = n - 1;
    bool carry = true;
    while i >= 0 {
        int d = (int)s[i] - (int)'0';
        if carry {
            d = d + 1;
        }
        if d >= 10 {
            d = 0;
        } else {
            carry = false;
        }
        out = (str)d + out;
        i = i - 1;
    }
    if carry {
        out = "1" + out;
    }
    return out;
}

!!! The exponent of a `%g` number as text: `e+20`, `e-08`. The sign is always
!!! written and the number is at least two digits, which is what printf does.
str rgx_ft_exp_text -> int e {
    str sign = "+";
    int a = e;
    if e < 0 {
        sign = "-";
        a = 0 - e;
    }
    !!! `+ ""` copies the text out of the conversion ring (see rg_emit_struct_leaf_copy).
    str t = (str)a + "";
    if pe_len(t) < 2 {
        t = "0" + t;
    }
    return "e" + sign + t;
}

!!! The `%.17g` text of one double, without the `.0` the caller adds when the text
!!! carries no point: 0, 3.8999999999999999, 4294967296, 9.9999999999999995e-08.
str rgx_float_text -> float value {
    if value == 0.0 {
        return "0";
    }
    bool neg = false;
    float x = value;
    if x < 0.0 {
        neg = true;
        x = 0.0 - x;
    }
    !!! m * 2^e2 == x, with 2^52 <= m < 2^53. Halving and doubling are exact, so m
    !!! is the mantissa itself and not an approximation of it.
    int e2 = 0;
    while x >= 9007199254740992.0 {
        x = x / 2.0;
        e2 = e2 + 1;
    }
    while x < 4503599627370496.0 {
        x = x * 2.0;
        e2 = e2 - 1;
    }
    longlong m = (longlong)x;
    !!! The whole number the value is that many places above: m * 2^e2 when e2 >= 0,
    !!! and m * 5^-e2 with the point `shift` places in from the right otherwise.
    int shift = 0;
    if e2 < 0 {
        shift = 0 - e2;
    }
    !!! 5^1074, the widest a double reaches, has 751 digits: 128 limbs hold 1152.
    @longlong limbs;
    malloc(@limbs, 128 * 8);
    limbs[0] = m % 1000000000;
    limbs[1] = m / 1000000000;
    int n = 2;
    int k = 0;
    if e2 >= 0 {
        while k < e2 {
            n = rgx_ft_mul(limbs, n, 2);
            k = k + 1;
        }
    } else {
        while k < shift {
            n = rgx_ft_mul(limbs, n, 5);
            k = k + 1;
        }
    }
    int top = n - 1;
    while top > 0 && limbs[top] == 0 {
        top = top - 1;
    }
    !!! The digit count of the whole number, and the exponent `%g` counts from: the
    !!! first digit stands 10^(digits - 1 - shift) high.
    str top_text = rgx_ft_limb_text(limbs[top]);
    int digits = top * 9 + pe_len(top_text);
    int e10 = digits - 1 - shift;
    !!! Eighteen digits are enough to round the seventeenth: the top limb holds at
    !!! most nine, so one whole limb below it always completes them.
    str all_digits = top_text;
    int li = top - 1;
    while pe_len(all_digits) < 18 && li >= 0 {
        str lt = rgx_ft_limb_text(limbs[li]);
        while pe_len(lt) < 9 {
            lt = "0" + lt;
        }
        all_digits = all_digits + lt;
        li = li - 1;
    }
    !!! A whole number below 10^17 is written out with the zeros that follow it.
    while pe_len(all_digits) < 18 {
        all_digits = all_digits + "0";
    }
    str d17 = pe_sub(all_digits, 0, 17);
    int next_digit = (int)all_digits[17] - (int)'0';
    if next_digit >= 5 {
        str bumped = rgx_ft_digits_add_one(d17);
        if pe_len(bumped) > 17 {
            !!! 999... rolled over into 1000...: one place higher, and the digits are
            !!! the first seventeen of the longer answer.
            bumped = pe_sub(bumped, 0, 17);
            e10 = e10 + 1;
        }
        d17 = bumped;
    }
    !!! `%g` writes no trailing zeros, which is what makes 4294967296 read back as
    !!! an integer and 1.0 as `1`.
    while pe_len(d17) > 1 && d17[pe_len(d17) - 1] == '0' {
        d17 = pe_sub(d17, 0, pe_len(d17) - 1);
    }
    int sig = pe_len(d17);
    str out = "";
    if e10 < -4 || e10 >= 17 {
        !!! The exponent form: one digit, the rest, then the exponent.
        out = pe_sub(d17, 0, 1);
        if sig > 1 {
            out = out + "." + pe_sub(d17, 1, sig - 1);
        }
        out = out + rgx_ft_exp_text(e10);
    } else if e10 < 0 {
        !!! Below one: `0.`, the zeros that come first, then every digit.
        str zeros = "";
        int zi = 0;
        while zi < 0 - e10 - 1 {
            zeros = zeros + "0";
            zi = zi + 1;
        }
        out = "0." + zeros + d17;
    } else {
        !!! At or above one: the digits up to the point, then the rest. A value whose
        !!! digits ran out early takes zeros in place of the missing ones.
        int ip = e10 + 1;
        str intpart = d17;
        if sig > ip {
            intpart = pe_sub(d17, 0, ip);
        }
        while pe_len(intpart) < ip {
            intpart = intpart + "0";
        }
        out = intpart;
        if sig > ip {
            out = out + "." + pe_sub(d17, ip, sig - ip);
        }
    }
    unlink(@limbs);
    if neg {
        return "-" + out;
    }
    return out;
}

!!! chain_root_kind(): the kind of the innermost node of a member-access chain
!!! (`o.people[i].name` roots at a FIELD_ELEM).
ExprKind rgx_expr_chain_root_kind -> @ExprNode n {
    @ExprNode r = n;
    while r != null && r.nk == MEMBER_ACCESS && r.left != null {
        r = r.left;
    }
    if r == null {
        return VAR_REF;
    }
    return r.nk;
}

!!! chain_root_struct_type(): the struct type of that innermost node.
str rgx_expr_chain_root_struct_type -> @ExprNode n {
    @ExprNode r = n;
    while r != null && r.nk == MEMBER_ACCESS && r.left != null {
        r = r.left;
    }
    if r == null {
        return "";
    }
    return r.struct_type;
}

!!! reverse over a chain of names: resolve_field_chain reads a member list
!!! from the base out, while the walk that collects it produces the outermost
!!! member first. The nodes are linked backwards in place, so nothing is allocated
!!! and no node keeps its old link (which would re-link the rest of the chain).
@StrNode rgx_expr_strchain_reverse -> @StrNode head {
    @StrNode out = null;
    @StrNode e = head;
    while e != null {
        @StrNode nx = e.next;
        e.next = null;
        e.next = out;
        out = e;
        e = nx;
    }
    return out;
}

!!! The `capname` lambda of rc_expr: a capture name rewritten through the active
!!! capture map, so a lambda nested inside another lambda captures the outer
!!! lambda's capture parameter instead of the original, out-of-scope name.
str rgx_expr_lambda_cap_name -> str c {
    @RgStrMap cit = rg_strmap_find(rg_capture_map, c);
    if cit != null {
        return cit.v;
    }
    return c;
}

!!! The `capvalue` lambda of rc_expr: the same, dereferenced when the capture is
!!! by reference.
str rgx_expr_lambda_cap_value -> str c {
    @RgStrMap cit = rg_strmap_find(rg_capture_map, c);
    if cit != null {
        @RgBoolMap bit = rg_boolmap_find(rg_capture_by_ref, c);
        if bit != null && bit.v {
            return "(DL " + cit.v + ")";
        }
        return cit.v;
    }
    return c;
}

!!! rc_expr(): append the .r text of one expression to rg_rcode.
void rg_rc_expr -> @ExprNode n {
    if n == null {
        end;
    }
    !!! Handle the -Econversion implicit conversion wrapping.
    if n.convert_to != ANY && n.result_type != n.convert_to {
        str conv = "";
        VarType to = n.convert_to;
        if to == INT {
            conv = "_toInt";
        } else if to == LONG {
            conv = "_toLong";
        } else if to == FLOAT {
            conv = "_toFloat";
        } else if to == BOOL {
            conv = "_toBool";
        } else if to == CHAR {
            conv = "_toChar";
        } else if to == STR {
            conv = "_toStr";
        }
        if conv != "" {
            rg_rcode = rg_rcode + "(" + conv + " ";
            !!! prevent double-wrapping.
            n.convert_to = ANY;
            rg_rc_expr(n);
            rg_rcode = rg_rcode + ")";
            end;
        }
    }
    if n.nk == LIT_INT {
        rg_rcode = rg_rcode + (str)n.int_val;
    } else if n.nk == LIT_FLOAT {
        !!! `%.17g` (rgx_float_text), and a `.0` is added when the text has
        !!! no point or exponent, so the backend reads the value as a float and not
        !!! as an int.
        str fbuf = rgx_float_text(n.float_val);
        bool has_dot = false;
        int fi = 0;
        while fbuf[fi] != (char)0 {
            if fbuf[fi] == '.' || fbuf[fi] == 'e' || fbuf[fi] == 'E' {
                has_dot = true;
                skip;
            }
            fi = fi + 1;
        }
        if !has_dot {
            fbuf = fbuf + ".0";
        }
        rg_rcode = rg_rcode + fbuf;
    } else if n.nk == LIT_STR {
        !!! Escape for the .r format, the way the toolchain emitter writes it: every byte
        !!! of the literal is escaped on its own (`\n`, `\r`, `\t`, a NUL as `\0`,
        !!! a backslash and a quote doubled). The text is walked where it was
        !!! written when the node carries its span - a value cannot hold the NUL
        !!! that `"\033"` stands for (C reads it as NUL and then `33`), and the toolchain
        !!! keeps it, so the span is what makes the two agree byte for byte - and
        !!! the decoded value is walked otherwise, for a node a pass built.
        rg_rcode = rg_rcode + "\"";
        if n.str_from > 0 && n.str_to >= n.str_from {
            int i = n.str_from;
            while i < n.str_to {
                char chc = g_base[i];
                if chc == '\\' && i + 1 < n.str_to {
                    i = i + 1;
                    char ev = g_base[i];
                    if ev == 'x' && i + 1 < n.str_to && p_is_hex(g_base[i + 1]) {
                        !!! `\xHH`: one or more hexadecimal digits, which is how the toolchain
                        !!! reader decodes it: `\xE2\x86\x92` is an arrow in UTF-8.
                        i = i + 1;
                        int xv = 0;
                        while i < n.str_to && p_is_hex(g_base[i]) {
                            xv = xv * 16 + p_hex_val(g_base[i]);
                            i = i + 1;
                        }
                        rg_rcode = rg_rcode + rgx_r_escape((char)(xv & 255));
                        continue;
                    }
                    if ev >= '0' && ev <= '7' {
                        !!! `\ooo`: up to three octal digits, which is how the toolchain
                        !!! reader decodes it: `\033` is the ASCII escape, and the
                        !!! two digits after a `\0` are not part of the escape.
                        int ov = 0;
                        int on = 0;
                        while i < n.str_to && on < 3 && g_base[i] >= '0' && g_base[i] <= '7' {
                            ov = ov * 8 + ((int)g_base[i] - 48);
                            i = i + 1;
                            on = on + 1;
                        }
                        rg_rcode = rg_rcode + rgx_r_escape((char)ov);
                        continue;
                    }
                    chc = p_char_escape(ev);
                }
                rg_rcode = rg_rcode + rgx_r_escape(chc);
                i = i + 1;
            }
        } else {
            str sv = n.str_val;
            int si = 0;
            while sv[si] != (char)0 {
                rg_rcode = rg_rcode + rgx_r_escape(sv[si]);
                si = si + 1;
            }
        }
        rg_rcode = rg_rcode + "\"";
    } else if n.nk == LIT_BOOL {
        !!! `.r` booleans are 0 and 1. A bare `true` is only understood where a
        !!! declaration expects it, not as an expression: passing one to a call
        !!! (`printf("%b", true)`) failed with "undeclared symbol 'true'".
        if n.bool_val {
            rg_rcode = rg_rcode + "1";
        } else {
            rg_rcode = rg_rcode + "0";
        }
    } else if n.nk == LIT_CHAR {
        !!! The char literal syntax the backend parses (e.g. 'A', '\n').
        int cv = n.char_val;
        rg_rcode = rg_rcode + "'";
        if cv == '\n' {
            rg_rcode = rg_rcode + "\\n";
        } else if cv == '\t' {
            rg_rcode = rg_rcode + "\\t";
        } else if cv == '\r' {
            rg_rcode = rg_rcode + "\\r";
        } else if cv == '\\' {
            rg_rcode = rg_rcode + "\\\\";
        } else if cv == (char)39 {
            rg_rcode = rg_rcode + "\\'";
        } else if cv >= 32 && cv < 127 {
            rg_rcode = rg_rcode + char_text((char)cv);
        } else {
            !!! A byte outside the printable range goes out as `\ooo`, the octal the
            !!! backend reads back (and the spelling C uses for the same bytes). It
            !!! was written as a decimal here, which the backend read as the first
            !!! digit and then choked on - the two agreed only while no source had a
            !!! character outside 32..126.
            int uv = cv;
            if uv < 0 {
                uv = uv + 256;
            }
            rg_rcode = rg_rcode + "\\" + rgx_octal3(uv);
        }
        rg_rcode = rg_rcode + "'";
    } else if n.nk == LIT_NULL {
        rg_rcode = rg_rcode + "null";
    } else if n.nk == VAR_REF {
        !!! A bare reference to the enclosing function's builtin annotation:
        !!! forward this function's parameters to the builtin (inside
        !!! `function __get_format__ printf -> ...`, a bare `__get_format__`
        !!! becomes `__get_format__(fmt, rest)`).
        if rg_cur_builtin_annotation != "" && n.var_name == rg_cur_builtin_annotation {
            rg_rcode = rg_rcode + "(CALL_EXPR " + n.var_name;
            @StrNode bp = rg_cur_builtin_params;
            while bp != null {
                rg_rcode = rg_rcode + " , " + bp.s;
                bp = bp.next;
            }
            rg_rcode = rg_rcode + ")";
            end;
        }
        !!! A captured variable inside a lambda body: rewrite to the hidden capture
        !!! parameter (dereferenced when captured by reference).
        @RgStrMap cit = rg_strmap_find(rg_capture_map, n.var_name);
        if cit != null {
            @RgBoolMap cbr = rg_boolmap_find(rg_capture_by_ref, n.var_name);
            if cbr != null && cbr.v {
                rg_rcode = rg_rcode + "(DL " + cit.v + ")";
            } else {
                rg_rcode = rg_rcode + cit.v;
            }
            end;
        }
        !!! A method parameter during an inline expansion: substitute the call
        !!! argument expression (parameters shadow fields with the same name).
        @RgExprMap mit = rg_exprmap_find(rg_method_arg_map, n.var_name);
        if mit != null && mit.e != null {
            rg_rc_expr(mit.e);
            end;
        }
        !!! Struct field access inside a struct method (implicit `this.field`).
        if rg_method_field_shadows(n.var_name) {
            @StructField f = rg_resolve_field(rg_struct_method_type, n.var_name, true);
            if f != null {
                !!! A struct-valued field is an object of its own, so its value is
                !!! its address inside `this`; `(FLD ...)` would read its first
                !!! bytes instead.
                if f.struct_type != "" && !f.struct_ptr && rg_struct_method_idx == null {
                    rg_this_field_address_out = "";
                    if rg_this_field_address(n.var_name) {
                        rg_rcode = rg_rcode + rg_this_field_address_out;
                        end;
                    }
                }
                rg_rcode = rg_rcode + rg_emit_fld(rg_struct_method_var, rg_struct_method_type,
                                                  n.var_name, false, false, n.line, n.col);
                if rg_struct_method_idx != null {
                    rg_rcode = rg_rcode + "{";
                    rg_rc_expr(rg_struct_method_idx);
                    rg_rcode = rg_rcode + "}";
                }
                end;
            }
        }
        !!! A function name used as a value -> build a closure object. A variable of
        !!! the same name in scope is the variable: a local `cur` beside a lexer
        !!! method named `cur` read the method's code address and compared closures.
        if rg_intmap_find(rg_func_arity, n.var_name) != null && !rg_var_in_scope(n.var_name) {
            rg_rcode = rg_rcode + "(CLOSURE " + n.var_name + ")";
            end;
        }
        !!! A reference variable: auto-dereference on read.
        if rg_is_ref_var(n.var_name) {
            rg_rcode = rg_rcode + "(DL " + n.var_name + ")";
            end;
        }
        !!! A `utype char` is a byte read as an unsigned one: the load sign extends
        !!! it, so the low eight bits are what the value is.
        if n.is_unsigned && n.result_type == CHAR {
            rg_rcode = rg_rcode + "(" + n.var_name + " , 255 , &)";
            end;
        }
        rg_rcode = rg_rcode + n.var_name;
    } else if n.nk == BINOP {
        !!! Compile-time string concatenation for literals.
        if pe_eq(n.op, "+") && n.left.nk == LIT_STR && n.right.nk == LIT_STR {
            rg_rcode = rg_rcode + "\"" + n.left.str_val + n.right.str_val + "\"";
            end;
        }
        !!! `@T p; p + n` / `p - n` steps by the size of what p points at. The .r
        !!! `+` adds the index as it stands - it is a byte addition, not a scaled
        !!! pointer one - so the index is scaled here for every pointer, including
        !!! the eight-byte ones. `(@void p)` keeps the sum on the byte scale, the
        !!! same form an array element address uses.
        if (pe_eq(n.op, "+") || pe_eq(n.op, "-")) && rg_pointer_operand(n.left) {
            int step = rg_pointer_step_size(n.left.var_name);
            rg_rcode = rg_rcode + "((@void ";
            rg_rc_expr(n.left);
            rg_rcode = rg_rcode + ") , (";
            rg_rc_expr(n.right);
            rg_rcode = rg_rcode + " , " + (str)step + " , *) , " + n.op + ")";
            end;
        }
        !!! The unsigned reading of an operation the .r operator spells the signed
        !!! way: `/` and `%` divide (idiv against div), and the order comparisons
        !!! set the flags for a signed comparison. Each goes through the runtime
        !!! helper that does it unsigned instead.
        if rg_is_unsigned_value(n.left) || rg_is_unsigned_value(n.right) {
            bool w64 = (n.left != null && n.left.result_type == LONG) ||
                       (n.right != null && n.right.result_type == LONG);
            str helper = rg_utype_op_helper(n.op, w64);
            !!! `if (helper)` of the toolchain: the answer is a *null* string when the
            !!! operation has no helper, and `!= ""` is a pointer comparison here,
            !!! for which null and "" differ - which took this branch and wrote a
            !!! call with no name at all (`(CALL_EXPR , ...)`).
            if helper != null {
                !!! The helper's signature says which width its arguments are, so
                !!! the operands are cast to it: `utype char` reads as an int, and a
                !!! 32-bit value in a 64-bit operation widens.
                rg_rcode = rg_rcode + "(CALL_EXPR " + helper + " , ";
                if w64 {
                    rg_rcode = rg_rcode + "_toLong ";
                } else {
                    rg_rcode = rg_rcode + "_toInt ";
                }
                rg_rc_expr(n.left);
                rg_rcode = rg_rcode + " , ";
                if w64 {
                    rg_rcode = rg_rcode + "_toLong ";
                } else {
                    rg_rcode = rg_rcode + "_toInt ";
                }
                rg_rc_expr(n.right);
                rg_rcode = rg_rcode + ")";
                end;
            }
        }
        !!! The operator is compared by text: `==` on two `str` values compares the
        !!! blocks they point at, and the text of an operator is a block of its own.
        str r_op = n.op;
        if pe_eq(n.op, "==") {
            r_op = "//";
        } else if pe_eq(n.op, "!=") {
            r_op = "\\\\";
        } else if pe_eq(n.op, "<=") {
            r_op = "<//";
        } else if pe_eq(n.op, ">=") {
            r_op = "//=";
        } else if pe_eq(n.op, "<") {
            r_op = "<";
        } else if pe_eq(n.op, ">") {
            r_op = ">";
        } else if pe_eq(n.op, "&&") {
            r_op = "&&";
        } else if pe_eq(n.op, "||") {
            r_op = "||";
        }
        rg_rcode = rg_rcode + "(";
        rg_rc_expr(n.left);
        rg_rcode = rg_rcode + " , ";
        rg_rc_expr(n.right);
        rg_rcode = rg_rcode + " , " + r_op + ")";
    } else if n.nk == UNARY {
        if pe_eq(n.op, "!") {
            rg_rcode = rg_rcode + "(";
            rg_rc_expr(n.left);
            rg_rcode = rg_rcode + " , \\)";
        } else if pe_eq(n.op, "-") {
            !!! Unary minus is subtraction from zero in .r terms.
            rg_rcode = rg_rcode + "(0 , ";
            rg_rc_expr(n.left);
            rg_rcode = rg_rcode + " , -)";
        } else if pe_eq(n.op, "$") {
            !!! $ dereference -> (DL ptr).
            rg_rcode = rg_rcode + "(DL ";
            rg_rc_expr(n.left);
            rg_rcode = rg_rcode + ")";
        }
    } else if n.nk == BITNOT {
        rg_rcode = rg_rcode + "(";
        rg_rc_expr(n.left);
        rg_rcode = rg_rcode + " , ~)";
    } else if n.nk == SHL {
        rg_rcode = rg_rcode + "(";
        rg_rc_expr(n.left);
        rg_rcode = rg_rcode + " , ";
        rg_rc_expr(n.right);
        rg_rcode = rg_rcode + " , <<)";
    } else if n.nk == SHR {
        !!! An unsigned right shift fills with zeros: `>>` fills with the sign bit,
        !!! so the runtime helper shifts the unsigned way.
        if rg_is_unsigned_value(n.left) {
            bool w64s = (n.left.result_type == LONG);
            rg_rcode = rg_rcode + "(CALL_EXPR ";
            if w64s {
                rg_rcode = rg_rcode + "_ushrl , ";
            } else {
                rg_rcode = rg_rcode + "_ushr , ";
            }
            if w64s {
                rg_rcode = rg_rcode + "_toLong ";
            } else {
                rg_rcode = rg_rcode + "_toInt ";
            }
            rg_rc_expr(n.left);
            rg_rcode = rg_rcode + " , ";
            if w64s {
                rg_rcode = rg_rcode + "_toLong ";
            } else {
                rg_rcode = rg_rcode + "_toInt ";
            }
            rg_rc_expr(n.right);
            rg_rcode = rg_rcode + ")";
            end;
        }
        rg_rcode = rg_rcode + "(";
        rg_rc_expr(n.left);
        rg_rcode = rg_rcode + " , ";
        rg_rc_expr(n.right);
        rg_rcode = rg_rcode + " , >>)";
    } else if n.nk == MEMBER_ACCESS {
        !!! var.field -> (FLD var offset TYPE).
        if n.is_super {
            rg_rcode = rg_rcode + rg_emit_fld(rg_struct_method_var, rg_struct_method_type,
                                              n.member_name, true, false, n.line, n.col);
            end;
        }
        if n.left != null && n.left.nk == FIELD_ELEM {
            !!! A field of an array element (`o.people[i].name`).
            rg_emit_lvalue_address_out = "";
            if rg_emit_lvalue_address(n) {
                str ea = rg_emit_lvalue_address_out;
                str et = n.left.struct_type;
                @StructField leaf = null;
                bool ok = false;
                if et != "" {
                    @StrNode ch = rg_strchain_append(null, n.member_name);
                    rg_resolve_field_chain_out_leaf = null;
                    rg_resolve_field_chain_out_abs_off = 0;
                    ok = rg_resolve_field_chain(et, ch, n.line, n.col);
                    leaf = rg_resolve_field_chain_out_leaf;
                }
                if et != "" && ok && leaf != null {
                    rg_rcode = rg_rcode + "(FLDP " + ea + " 0 " +
                               rg_rtype(rg_field_eff_type(leaf)) + ")";
                } else {
                    rg_rcode = rg_rcode + ea;
                }
            } else {
                rg_rcode = rg_rcode + "0";
            }
            end;
        }
        if n.left != null && n.left.nk == VAR_REF {
            !!! `who.age` inside a method body: the chain starts at a field of `this`
            !!! instead of a variable.
            if rg_vartypemap_find(rg_syms, n.left.var_name) == null &&
               rg_strmap_find(rg_sym_struct_type, n.left.var_name) == null &&
               rg_struct_method_var != "" &&
               rg_resolve_field(rg_struct_method_type, n.left.var_name, true) != null {
                rg_emit_lvalue_address_out = "";
                if rg_emit_lvalue_address(n) {
                    !!! The chain starts at that field of `this`.
                    str ea2 = rg_emit_lvalue_address_out;
                    @StrNode mems = rg_strchain_append(null, n.left.var_name);
                    @ExprNode c = n;
                    while c != null && c.nk == MEMBER_ACCESS {
                        mems = rg_strchain_append(mems, c.member_name);
                        c = c.left;
                    }
                    @StructField leaf2 = null;
                    rg_resolve_field_chain_out_leaf = null;
                    rg_resolve_field_chain_out_abs_off = 0;
                    bool ok2 = rg_resolve_field_chain(rg_struct_method_type, mems, n.line, n.col);
                    leaf2 = rg_resolve_field_chain_out_leaf;
                    if ok2 && leaf2 != null {
                        rg_rcode = rg_rcode + "(FLDP " + ea2 + " 0 " +
                                   rg_rtype(rg_field_eff_type(leaf2)) + ")";
                    } else {
                        rg_rcode = rg_rcode + ea2;
                    }
                    end;
                }
            }
            !!! The declaration in effect here, not the flat table: the same name
            !!! can be a different struct in another body.
            str stype = rg_struct_type_in_effect(n.left.var_name);
            !!! `p.field` where p is a `@T` (the struct's address) reads through the
            !!! pointer, as the write path already did.
            rg_rcode = rg_rcode + rg_emit_fld(n.left.var_name, stype, n.member_name,
                                              false, rg_name_is_pointer(n.left.var_name),
                                              n.line, n.col);
            end;
        }
        if n.left != null && n.left.nk == ARRAY_ACCESS {
            !!! `data[i].field` where `data` is a pointer - a variable (`p[i].a`) or
            !!! a field of the enclosing method's struct (`data[i].a`): the
            !!! element's address is the pointer plus the scaled index, and the
            !!! field is read from there. The chain emitter builds exactly that,
            !!! and it has to be tried before the inline-array path below, which
            !!! only knows fields of `this`.
            rg_emit_pointer_chain_out = "";
            if rg_emit_pointer_chain(n) {
                rg_rcode = rg_rcode + rg_emit_pointer_chain_out;
                end;
            }
            !!! `data[i].field` inside a method body: an element of an array field
            !!! of `this`.
            rg_emit_this_field_elem_node_out = "";
            rg_emit_this_field_elem_node_out_field = null;
            if rg_emit_this_field_elem_node(n.left) {
                @StructField af = rg_emit_this_field_elem_node_out_field;
                str ea3 = rg_emit_this_field_elem_node_out;
                if af != null && af.struct_type != "" {
                    @StructField mfield = rg_resolve_field(af.struct_type, n.member_name, true);
                    if mfield != null {
                        str dt2 = rg_resolve_field_out_decl_type;
                        int moff = rg_field_offset_of(af.struct_type, n.member_name, dt2);
                        if moff >= 0 {
                            rg_rcode = rg_rcode + "(FLDP " + ea3 + " " + (str)moff + " " +
                                       rg_rtype(rg_field_eff_type(mfield)) + ")";
                            end;
                        }
                    }
                }
            }
            str stype3 = rg_struct_type_in_effect(n.left.var_name);
            @StructField f3 = rg_resolve_field(stype3, n.member_name, true);
            if f3 != null {
                str dt3 = rg_resolve_field_out_decl_type;
                int off3 = rg_field_offset_in(stype3, n.member_name, dt3);
                !!! Several indices name the element row by row.
                str lin = "";
                if n.left.indices == null {
                    lin = rg_capture_rc_expr(n.left.left);
                } else {
                    lin = rg_linear_index_expr(n.left.var_name, n.left.indices);
                }
                if lin != "" {
                    rg_rcode = rg_rcode + "(FLD " + n.left.var_name + " " + (str)off3 + " " +
                               rg_rtype(rg_field_eff_type(f3)) + " " + lin + ")";
                } else {
                    rg_rcode = rg_rcode + rg_emit_fld(n.left.var_name, stype3, n.member_name,
                                                      false, false, n.line, n.col);
                }
            } else {
                rg_rcode = rg_rcode + rg_emit_fld(n.left.var_name, stype3, n.member_name,
                                                  false, false, n.line, n.col);
                rg_rcode = rg_rcode + "{";
                rg_rc_expr(n.left.left);
                rg_rcode = rg_rcode + "}";
            }
            end;
        }
        if n.left != null && n.left.nk == MEMBER_ACCESS &&
           rgx_expr_chain_root_kind(n) == FIELD_ELEM {
            !!! A chain rooted at an array element (`o.people[i].name`). The address
            !!! helper walks the element and the members for us.
            rg_emit_lvalue_address_out = "";
            if rg_emit_lvalue_address(n) {
                str ea4 = rg_emit_lvalue_address_out;
                @StructField leaf4 = null;
                @StrNode mems2 = null;
                @ExprNode c2 = n;
                while c2 != null && c2.nk == MEMBER_ACCESS {
                    mems2 = rg_strchain_append(mems2, c2.member_name);
                    c2 = c2.left;
                }
                !!! reverse: resolve_field_chain reads the members from the
                !!! base out.
                mems2 = rgx_expr_strchain_reverse(mems2);
                str et4 = rgx_expr_chain_root_struct_type(n);
                bool ok4 = false;
                if et4 != "" {
                    rg_resolve_field_chain_out_leaf = null;
                    rg_resolve_field_chain_out_abs_off = 0;
                    ok4 = rg_resolve_field_chain(et4, mems2, n.line, n.col);
                    leaf4 = rg_resolve_field_chain_out_leaf;
                }
                if et4 != "" && ok4 && leaf4 != null {
                    rg_rcode = rg_rcode + "(FLDP " + ea4 + " 0 " +
                               rg_rtype(rg_field_eff_type(leaf4)) + ")";
                } else {
                    rg_rcode = rg_rcode + ea4;
                }
            } else {
                rg_rcode = rg_rcode + "0";
            }
            end;
        }
        if n.left != null && n.left.nk == MEMBER_ACCESS {
            !!! Chained member access: p.addr.city, or through a struct pointer
            !!! (`a.next.v` / `p.next.v`).
            rg_emit_pointer_chain_out = "";
            if rg_emit_pointer_chain(n) {
                rg_rcode = rg_rcode + rg_emit_pointer_chain_out;
                end;
            }
            @ExprNode root = n.left;
            while root != null && root.nk == MEMBER_ACCESS && root.left != null {
                root = root.left;
            }
            if root != null && root.nk == ARRAY_ACCESS {
                !!! `arr[i].f1.f2`: an element of a heap array followed by a field
                !!! chain. A single indexed FLD covers the whole chain, so the
                !!! fields are not appended to the element expression.
                str et5 = rg_struct_type_in_effect(root.var_name);
                @StructField leaf5 = null;
                bool ok5 = false;
                if et5 != "" {
                    rg_resolve_member_chain_out_leaf = null;
                    rg_resolve_member_chain_out_abs_off = 0;
                    ok5 = rg_resolve_member_chain(n, et5);
                    leaf5 = rg_resolve_member_chain_out_leaf;
                }
                if et5 != "" && ok5 && leaf5 != null {
                    str lin5 = "";
                    if root.indices == null {
                        lin5 = rg_capture_rc_expr(root.left);
                    } else {
                        lin5 = rg_linear_index_expr(root.var_name, root.indices);
                    }
                    if lin5 != "" {
                        int off5 = rg_resolve_member_chain_out_abs_off;
                        rg_rcode = rg_rcode + "(FLD " + root.var_name + " " + (str)off5 + " " +
                                   rg_rtype(rg_field_eff_type(leaf5)) + " " + lin5 + ")";
                        end;
                    }
                }
            }
            if root != null && root.nk == VAR_REF {
                str stype5 = rg_struct_type_in_effect(root.var_name);
                @StructField leaf6 = null;
                bool ok6 = false;
                if stype5 != "" {
                    rg_resolve_member_chain_out_leaf = null;
                    rg_resolve_member_chain_out_abs_off = 0;
                    ok6 = rg_resolve_member_chain(n, stype5);
                    leaf6 = rg_resolve_member_chain_out_leaf;
                }
                if stype5 != "" && ok6 && leaf6 != null {
                    int off6 = rg_resolve_member_chain_out_abs_off;
                    rg_rcode = rg_rcode + "(FLD " + root.var_name + " " + (str)off6 + " " +
                               rg_rtype(rg_field_eff_type(leaf6)) + ")";
                } else {
                    rg_rc_expr(n.left);
                    rg_rcode = rg_rcode + "_" + n.member_name;
                }
            } else {
                rg_rc_expr(n.left);
                rg_rcode = rg_rcode + "_" + n.member_name;
            }
            end;
        }
        rg_rc_expr(n.left);
        rg_rcode = rg_rcode + "_" + n.member_name;
    } else if n.nk == SIZE {
        !!! A `size` that came back as zero is asked again here, where the body being
        !!! generated is the one in scope: a method body is walked before its locals
        !!! are in the table, so `size` of a local or of a field of the enclosing
        !!! struct was answered with nothing and the zero was kept on the node. No
        !!! type has a layout of no bytes, so zero always means "not answered yet".
        if n.int_val == 0 {
            !!! Only where the name has a meaning in this body: the body of a generic
            !!! block is also walked before it is instantiated, and there a field of
            !!! the not-yet-materialized struct cannot be answered - asking then
            !!! reported it as an undeclared type.
            bool have = rg_effective_var_decl(n.var_name);
            bool shadows = false;
            if !have {
                shadows = rg_method_field_shadows(n.var_name);
            }
            if have || shadows || rg_struct_method_type != "" {
                n.type_resolved = false;
                rg_resolve_expr_type(n);
            }
        }
        rg_rcode = rg_rcode + (str)n.int_val;
    } else if n.nk == COUNT {
        !!! `count a`: the number a stack array was declared with, the length
        !!! expression a variable-length one was declared with, or the count the
        !!! array's metadata block holds at `[a-8]` (see rg_resolve_count). FLDP
        !!! reads a field at an address plus an offset, which is exactly that load.
        if n.count_folded {
            rg_rcode = rg_rcode + (str)n.int_val;
        } else if n.left != null {
            rg_rc_expr(n.left);
        } else {
            rg_rcode = rg_rcode + "(FLDP " + n.var_name + " -8 INT)";
        }
    } else if n.nk == CAST {
        !!! func <-> @func conversions use closure-object helpers.
        if pe_eq(n.op, "toFunc") {
            rg_rcode = rg_rcode + "(CLOSURE_FROM_PTR ";
            rg_rc_expr(n.left);
            rg_rcode = rg_rcode + ")";
            end;
        }
        if pe_eq(n.op, "toAtFunc") {
            rg_rcode = rg_rcode + "(CLOSURE_CODE ";
            rg_rc_expr(n.left);
            rg_rcode = rg_rcode + ")";
            end;
        }
        !!! A cast to the type the value already has is nothing to do, and the prefix
        !!! form of a 64-bit literal is read back as a 32-bit one by the backend:
        !!! `(utype longlong)9223372036854775807` stays the literal itself.
        if n.left != null && n.left.nk == LIT_INT && n.left.result_type == n.result_type {
            rg_rc_expr(n.left);
            end;
        }
        !!! Map to _toStr / _toInt / @void / @int / ...
        str rcast = "";
        if pe_eq(n.op, "toStr") {
            rcast = "_toStr";
        } else if pe_eq(n.op, "toInt") {
            rcast = "_toInt";
        } else if pe_eq(n.op, "toLong") {
            rcast = "_toLong";
        } else if pe_eq(n.op, "toFloat") {
            rcast = "_toFloat";
        } else if pe_eq(n.op, "toBool") {
            rcast = "_toBool";
        } else if pe_eq(n.op, "toChar") {
            rcast = "_toChar";
        } else if pe_eq(n.op, "@void") {
            rcast = "@void";
        } else if pe_eq(n.op, "@int") {
            rcast = "@int";
        } else if pe_eq(n.op, "@longlong") {
            rcast = "@longlong";
        } else if pe_eq(n.op, "@float") {
            rcast = "@float";
        } else if pe_eq(n.op, "@char") {
            rcast = "@char";
        } else if pe_eq(n.op, "@str") {
            rcast = "@str";
        }
        !!! `(str)` of an unsigned value spells its unsigned number: the built-in
        !!! conversion would print the signed one.
        if pe_eq(n.op, "toStr") && rg_is_unsigned_value(n.left) {
            bool w64c = (n.left.result_type == LONG);
            !!! A call, not the prefix form the built-in casts use: this is a runtime
            !!! function, and `.r` reads a bare name in front of a value as another
            !!! argument.
            rg_rcode = rg_rcode + "(CALL_EXPR " + rg_utype_str_helper(n.left) + " , ";
            if w64c {
                rg_rcode = rg_rcode + "_toLong ";
            } else {
                rg_rcode = rg_rcode + "_toInt ";
            }
            rg_rc_expr(n.left);
            rg_rcode = rg_rcode + ")";
            end;
        }
        rg_rcode = rg_rcode + rcast + " ";
        rg_rc_expr(n.left);
    } else if n.nk == ARRAY_ACCESS {
        !!! `p[i]` over a `@T` block: the element sits at the pointer plus the index
        !!! scaled by the layout size of the struct, and a struct element is denoted
        !!! by that address. A scalar element keeps the `p{i}` form below, which
        !!! loads the value and is scaled by the backend.
        rg_pointer_element_address_out = "";
        if rg_pointer_element_address(n) {
            str pea = rg_pointer_element_address_out;
            if n.struct_type != "" {
                !!! a struct element is its address.
                rg_rcode = rg_rcode + pea;
            } else {
                !!! A builtin element is read from that address. The type is taken
                !!! from the pointer's own declaration - or from the field the member
                !!! chain ends in - and not from the node: a node whose type was
                !!! never resolved emits the default, which read four bytes of an
                !!! eight-byte `str` element and lost the first element of a grown
                !!! vector(str).
                VarType et = n.result_type;
                if n.left != null && n.left.nk == MEMBER_ACCESS {
                    rg_member_chain_block_info_out_base = "";
                    rg_member_chain_block_info_out_struct = "";
                    rg_member_chain_block_info_out_step = 0;
                    rg_member_chain_block_info_out_elem = INT;
                    if rg_member_chain_block_info(n.left) {
                        et = rg_member_chain_block_info_out_elem;
                    }
                } else {
                    !!! `data[i]` where `data` is a `@T` field of the enclosing
                    !!! method's struct: the element's type is the field's own. The
                    !!! left child of an ARRAY_ACCESS is the *index*, so the member
                    !!! chain above never saw this shape, and
                    !!! rg_pointer_element_type(name) answered the default INT for a
                    !!! field name - not a symbol it can look up - which read four
                    !!! bytes of a one-byte element (`r.data[i]`).
                    rg_method_field_block_info_out_struct_type = "";
                    rg_method_field_block_info_out_step = 0;
                    if rg_method_field_block_info(n.var_name) {
                        if pe_eq(rg_method_field_block_info_out_struct_type, "") {
                            et = rg_method_field_elem_type(n.var_name);
                        } else {
                            et = INT;
                        }
                    } else {
                        et = rg_pointer_element_type(n.var_name);
                    }
                }
                rg_rcode = rg_rcode + "(FLDP " + pea + " 0 " + rg_rtype(et) + ")";
            }
            end;
        }
        !!! `data[i]` inside a method body: an element of an array field of `this`
        !!! (a local heap array of the same name wins).
        rg_emit_this_field_elem_node_out = "";
        rg_emit_this_field_elem_node_out_field = null;
        if rg_emit_this_field_elem_node(n) {
            @StructField ff = rg_emit_this_field_elem_node_out_field;
            if ff != null {
                str ea6 = rg_emit_this_field_elem_node_out;
                if ff.struct_type != "" && !ff.struct_ptr {
                    !!! a struct value is its address.
                    rg_rcode = rg_rcode + ea6;
                } else {
                    rg_rcode = rg_rcode + "(FLDP " + ea6 + " 0 " +
                               rg_rtype(rg_field_eff_type(ff)) + ")";
                }
                end;
            }
        }
        if n.indices != null {
            rg_rcode = rg_rcode + n.var_name + "{" +
                       rg_linear_index_expr(n.var_name, n.indices) + "}";
        } else {
            rg_rcode = rg_rcode + n.var_name + "{";
            rg_rc_expr(n.left);
            rg_rcode = rg_rcode + "}";
        }
    } else if n.nk == FIELD_ELEM {
        !!! `o.data[i]`: one element of an inline array field - or, when the field is
        !!! a pointer reached through a member chain, the element the pointer at
        !!! `data + i * step` names.
        rg_pointer_field_elem_address_out = "";
        rg_pointer_field_elem_address_out_struct = "";
        rg_pointer_field_elem_address_out_elem = INT;
        if rg_pointer_field_elem_address(n) {
            str pea2 = rg_pointer_field_elem_address_out;
            str es2 = rg_pointer_field_elem_address_out_struct;
            if es2 != "" {
                !!! a struct element is its address.
                rg_rcode = rg_rcode + pea2;
            } else {
                rg_rcode = rg_rcode + "(FLDP " + pea2 + " 0 " +
                           rg_rtype(rg_pointer_field_elem_address_out_elem) + ")";
            }
        } else {
            rg_emit_field_elem_address_out = "";
            rg_emit_field_elem_address_out_field = null;
            if !rg_emit_field_elem_address(n) {
                rg_rcode = rg_rcode + "0";
            } else {
                @StructField fel = rg_emit_field_elem_address_out_field;
                str ea7 = rg_emit_field_elem_address_out;
                if fel == null {
                    rg_rcode = rg_rcode + "0";
                } else if fel.struct_type != "" && !fel.struct_ptr {
                    !!! a struct value is its address.
                    rg_rcode = rg_rcode + ea7;
                } else {
                    rg_rcode = rg_rcode + "(FLDP " + ea7 + " 0 " +
                               rg_rtype(rg_field_eff_type(fel)) + ")";
                }
            }
        }
    } else if n.nk == FUNC_CALL {
        !!! super.method(...) as an expression: resolve in the base types only, and
        !!! pass the object's own address as the receiver. args[0] is the `super`
        !!! receiver and not an argument, so the arguments start behind it. Without
        !!! this the implicit-call branch below treated `super` itself as an argument
        !!! and emitted the call one argument too wide (`__m_A_m __this super 2`).
        if n.is_super {
            @StmtNode sm = rg_resolve_method_func(rg_struct_method_type, n.var_name, false);
            if sm != null {
                str mdt = rg_struct_method_type;
                if !pe_eq(sm.struct_type, "") {
                    mdt = sm.struct_type;
                }
                rg_check_member_access(mdt, n.var_name, sm.access, n.line, n.col);
                !!! `__this` is the STRUCTPTR the method body is given; any other name
                !!! is the object itself, so its address is taken.
                str srcv = "(AT " + rg_struct_method_var + ")";
                if pe_eq(rg_struct_method_var, "__this") {
                    srcv = rg_struct_method_var;
                }
                rg_rcode = rg_rcode + "(CALL_EXPR __m_" + mdt + "_" + sm.var_name + " , " + srcv;
                @ExprNode sa2 = n.args;
                if sa2 != null {
                    sa2 = sa2.next;
                }
                while sa2 != null {
                    rg_rcode = rg_rcode + " , ";
                    rg_emit_call_arg_value(sa2);
                    sa2 = sa2.next;
                }
                rg_rcode = rg_rcode + ")";
                end;
            }
            @StmtNode sbm = rg_resolve_bapi_method(rg_struct_method_type, n.var_name, false);
            if sbm != null {
                @ExprNode ca2 = n.args;
                if ca2 != null {
                    ca2 = ca2.next;
                }
                rg_emit_bapi_expr(sbm, ca2);
                end;
            }
        }
        !!! Struct BAPI method call: type.method(...) / instance.method(...).
        if n.args != null && n.args.nk == VAR_REF {
            @StmtNode sbapi = rg_find_struct_bapi(n.var_name, n.args.var_name);
            if sbapi != null {
                !!! the toolchain copies the arguments after the receiver into a vector;
                !!! here the tail of the chain is handed over (it is only read).
                @ExprNode ca = n.args.next;
                rg_emit_bapi_expr(sbapi, ca);
                end;
            }
        }
        !!! Regular struct method call as an expression: instance.method(...) or a
        !!! method on a nested object (obj.field.method(...)).
        if n.has_receiver && n.args != null &&
           (n.args.nk == VAR_REF || n.args.nk == MEMBER_ACCESS || n.args.nk == FIELD_ELEM ||
            n.args.nk == ARRAY_ACCESS || n.args.nk == FUNC_CALL) {
            str sv = n.args.var_name;
            str stype = "";
            str recv_addr = "";
            str dt = "";
            if n.args.nk == VAR_REF {
                stype = rg_receiver_struct_type(n.args);
                if stype != "" {
                    !!! A bare field of the enclosing method's struct has no variable
                    !!! of its own: its address is inside `this`, which
                    !!! this_field_address already produced. A `@T` receiver holds
                    !!! the address itself.
                    if n.args.ptr_depth > 0 || rg_name_is_pointer(sv) {
                        recv_addr = sv;
                    } else {
                        rg_this_field_address_out = "";
                        if !rg_this_field_address(sv) {
                            recv_addr = "(AT " + sv + ")";
                        } else {
                            recv_addr = rg_this_field_address_out;
                        }
                    }
                }
            } else {
                rg_receiver_info_out_stype = "";
                rg_receiver_info_out_decl_type = "";
                if rg_receiver_info(n.args, false) {
                    stype = rg_receiver_info_out_stype;
                    dt = rg_receiver_info_out_decl_type;
                    rg_emit_receiver_address_out = "";
                    rg_emit_receiver_address(n.args);
                    recv_addr = rg_emit_receiver_address_out;
                }
            }
            if stype != "" && recv_addr != "" {
                @StmtNode mf = rg_resolve_method_func(stype, n.var_name, true);
                if mf != null {
                    if mf.struct_type == "" {
                        dt = stype;
                    } else {
                        dt = mf.struct_type;
                    }
                    rg_rcode = rg_rcode + "(CALL_EXPR __m_" + dt + "_" + mf.var_name +
                               " , " + recv_addr;
                    @ExprNode a3 = n.args.next;
                    while a3 != null {
                        rg_rcode = rg_rcode + " , ";
                        rg_emit_call_arg_value(a3);
                        a3 = a3.next;
                    }
                    rg_rcode = rg_rcode + ")";
                    end;
                }
                @StmtNode bm = rg_resolve_bapi_method(stype, n.var_name, true);
                if bm != null {
                    @ExprNode ca2 = n.args.next;
                    rg_emit_bapi_expr(bm, ca2);
                    end;
                }
            }
        }
        !!! Implicit method call inside a method body: bare method(...) ->
        !!! this.method(...).
        if rg_struct_method_var != "" {
            @StmtNode imf = rg_resolve_method_func(rg_struct_method_type, n.var_name, true);
            if imf != null {
                str dtb = rg_struct_method_type;
                if imf.struct_type != "" {
                    dtb = imf.struct_type;
                }
                rg_rcode = rg_rcode + "(CALL_EXPR __m_" + dtb + "_" + imf.var_name +
                           " , " + rg_struct_method_var;
                @ExprNode a4 = n.args;
                while a4 != null {
                    rg_rcode = rg_rcode + " , ";
                    rg_emit_call_arg_value(a4);
                    a4 = a4.next;
                }
                rg_rcode = rg_rcode + ")";
                end;
            }
        }
        !!! Check the BAPI definitions.
        @StmtNode bdef = p_find_bapi(n.var_name);
        if bdef != null {
            rg_emit_bapi_expr(bdef, n.args);
        } else if rg_is_callable_var(n.var_name) {
            rg_rcode = rg_rcode + "(ICALL " + n.var_name;
            @ExprNode a5 = n.args;
            while a5 != null {
                rg_rcode = rg_rcode + " , ";
                rg_emit_call_arg_value(a5);
                a5 = a5.next;
            }
            rg_rcode = rg_rcode + ")";
        } else {
            rg_rcode = rg_rcode + "(CALL_EXPR " + rg_resolve_call_name(n.var_name);
            @ExprNode a6 = n.args;
            while a6 != null {
                rg_rcode = rg_rcode + " , ";
                rg_emit_call_arg_value(a6);
                a6 = a6.next;
            }
            rg_rcode = rg_rcode + ")";
        }
    } else if n.nk == ADDR {
        !!! The address of a function name -> a raw code address (@func), not the
        !!! heap-allocated closure object.
        if n.left != null && n.left.nk == VAR_REF &&
           rg_intmap_find(rg_func_arity, n.left.var_name) != null {
            rg_rcode = rg_rcode + "(AT " + n.left.var_name + ")";
        } else {
            !!! An address that has to be computed (a field of the enclosing struct,
            !!! a struct-valued field, an array element) cannot be built by taking
            !!! the address of the value expression.
            rg_emit_lvalue_address_out = "";
            if rg_emit_lvalue_address(n.left) {
                rg_rcode = rg_rcode + rg_emit_lvalue_address_out;
            } else {
                !!! Always generate (AT expr) to get the address.
                rg_rcode = rg_rcode + "(AT ";
                rg_rc_expr(n.left);
                rg_rcode = rg_rcode + ")";
            }
        }
    } else if n.nk == PRE_INCR {
        rg_rcode = rg_rcode + "(PRE_INCR ";
        rg_rc_expr(n.left);
        rg_rcode = rg_rcode + " , " + n.op + ")";
    } else if n.nk == POST_INCR {
        rg_rcode = rg_rcode + "(POST_INCR ";
        rg_rc_expr(n.left);
        rg_rcode = rg_rcode + " , " + n.op + ")";
    } else if n.nk == TERNARY {
        rg_rcode = rg_rcode + "(? ";
        rg_rc_expr(n.left);
        rg_rcode = rg_rcode + " , ";
        rg_rc_expr(n.right);
        rg_rcode = rg_rcode + " , ";
        rg_rc_expr(n.args);
        rg_rcode = rg_rcode + ")";
    } else if n.nk == LAMBDA {
        !!! Rewrite a capture name through the active capture map, so a lambda
        !!! nested inside another lambda captures the outer lambda's capture
        !!! parameter rather than the (out-of-scope) original name. The pieces of
        !!! the literal live in the LambdaRec its id names (ast.b).
        @LambdaRec lr = p_find_lambda(n.lambda_id);
        bool immediate = false;
        if lr != null {
            immediate = lr.immediate;
        }
        !!! Immediate call: lambda => (args) -> a direct call of the hidden function
        !!! with the capture addresses + the explicit arguments.
        if immediate {
            rg_rcode = rg_rcode + "(CALL_EXPR " + n.var_name;
            @StrNode lc = null;
            if lr != null {
                lc = lr.captures;
            }
            while lc != null {
                rg_rcode = rg_rcode + " , (AT " + rgx_expr_lambda_cap_name(lc.s) + ")";
                lc = lc.next;
            }
            @ExprNode lia = null;
            if lr != null {
                lia = lr.immediate_args;
            }
            while lia != null {
                rg_rcode = rg_rcode + " , ";
                rg_rc_expr(lia);
                lia = lia.next;
            }
            rg_rcode = rg_rcode + ")";
        } else {
            !!! Lambda as a value: build a closure object pointing at the hidden
            !!! function. Read-only captures store the value; mutable captures store
            !!! a pointer to a freshly allocated heap cell.
            rg_rcode = rg_rcode + "(CLOSURE " + n.var_name;
            @StrNode lc2 = null;
            @BoolNode lbr = null;
            if lr != null {
                lc2 = lr.captures;
                lbr = lr.capture_by_ref;
            }
            while lc2 != null {
                !!! `ci < n->lambda_capture_by_ref.size() && ...`: the flag chain
                !!! may be shorter than the capture list, which the null test
                !!! covers while both are walked together.
                bool byref = false;
                if lbr != null {
                    byref = lbr.v;
                }
                rg_rcode = rg_rcode + " , ";
                if byref {
                    rg_rcode = rg_rcode + "(CELL " + rgx_expr_lambda_cap_value(lc2.s) + ")";
                } else {
                    rg_rcode = rg_rcode + rgx_expr_lambda_cap_name(lc2.s);
                }
                lc2 = lc2.next;
                if lbr != null {
                    lbr = lbr.next;
                }
            }
            rg_rcode = rg_rcode + ")";
        }
    }
}
