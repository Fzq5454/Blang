#once
!~
 ~  bootstrap/frontend/rgen_ctor.b: the frontend/rgen_ctor.
 ~
 ~  The constructor of the generator, the one place an error of the generator is
 ~  laid out (fmt_err) and the reader that turns the spelling of a type in a `-link`
 ~  flag back into the type itself.
 ~
 ~  the toolchain constructor binds the parser, the tokenizer and the driver's two buffers
 ~  by reference. There is no object to bind here - the parser and the tokenizer are
 ~  modules whose own globals are the state the generator reads (rgen.b) - so what is
 ~  left of the constructor is the -Rimp flag list it parses.
 ~
 ~  fmt_err keeps the shape one: `lex_show_pos` translates the position
 ~  the way every other diagnostic of the front end translates it, the "In function"
 ~  header is written once for the function the error is in, and the message itself
 ~  is laid out by libbstr through ux_error_buf. Three calls are not in the
 ~  language and what stands in their place is said where they stood: `head_file_banner`
 ~  (libbstr does not export it to blang, the same call rgen_diag.b leaves out).
 ~  The message and the two header formats go through zh_msg and zh_pick where the
 ~  calls them, so `-Chinese` prints the same text here as it does there.
 ~!

#head "rgen"
#head "rgen_heads"
#head "attributes"
#head "Chinese/chinese_heads"

!!! ---- the -link type spelling ----

!!! The two answers of extern_type_from_name. the toolchain writes them through
!!! `VarType& out` and `bool* is_unsigned`; a non-const reference is not a
!!! parameter of a function here, so they are module globals (this design section
!!! 3), and the flag is read only when the type resolved.
VarType rg_extern_type_from_name_out;
bool rg_extern_type_from_name_out_unsigned = false;

!!! The blang spelling of a type, the way the -link flags carry it, back to the
!!! type itself. Covers what a .bmeta can express; a name that is not one of these
!!! leaves the type alone, so an unreadable entry stays int rather than becoming
!!! something arbitrary.
bool rg_extern_type_from_name -> str s {
    !!! the toolchain clears `*is_unsigned` before anything else, so a name that does not
    !!! resolve never leaves a stale flag behind.
    rg_extern_type_from_name_out_unsigned = false;
    !!! The unsigned readings a .bmeta keeps for the Windows APIs that hand back a
    !!! value meant without a sign (DWORD, SIZE_T, BYTE). The type is the same
    !!! width as its signed spelling, so the argument bytes do not change; the flag
    !!! is what makes the call site print, divide and compare the value the
    !!! unsigned way.
    if p_text_eq(s, "utype int") {
        rg_extern_type_from_name_out = INT;
        rg_extern_type_from_name_out_unsigned = true;
        return true;
    }
    if p_text_eq(s, "utype longlong") {
        rg_extern_type_from_name_out = LONG;
        rg_extern_type_from_name_out_unsigned = true;
        return true;
    }
    if p_text_eq(s, "utype char") {
        rg_extern_type_from_name_out = CHAR;
        rg_extern_type_from_name_out_unsigned = true;
        return true;
    }
    if p_text_eq(s, "void") {
        rg_extern_type_from_name_out = VOID;
        return true;
    }
    if p_text_eq(s, "bool") {
        rg_extern_type_from_name_out = BOOL;
        return true;
    }
    if p_text_eq(s, "int") {
        rg_extern_type_from_name_out = INT;
        return true;
    }
    if p_text_eq(s, "longlong") {
        rg_extern_type_from_name_out = LONG;
        return true;
    }
    if p_text_eq(s, "str") {
        rg_extern_type_from_name_out = STR;
        return true;
    }
    if p_text_eq(s, "any") {
        rg_extern_type_from_name_out = ANY;
        return true;
    }
    if p_text_eq(s, "char") {
        rg_extern_type_from_name_out = CHAR;
        return true;
    }
    if p_text_eq(s, "float") {
        rg_extern_type_from_name_out = FLOAT;
        return true;
    }
    if p_text_eq(s, "func") {
        rg_extern_type_from_name_out = FUNC;
        return true;
    }
    if p_text_eq(s, "@int") {
        rg_extern_type_from_name_out = AT_INT;
        return true;
    }
    if p_text_eq(s, "@longlong") {
        rg_extern_type_from_name_out = AT_LONG;
        return true;
    }
    if p_text_eq(s, "@float") {
        rg_extern_type_from_name_out = AT_FLOAT;
        return true;
    }
    if p_text_eq(s, "@char") {
        rg_extern_type_from_name_out = AT_CHAR;
        return true;
    }
    if p_text_eq(s, "@str") {
        rg_extern_type_from_name_out = AT_STR;
        return true;
    }
    if p_text_eq(s, "@void") {
        rg_extern_type_from_name_out = AT_VOID;
        return true;
    }
    if p_text_eq(s, "@bool") {
        rg_extern_type_from_name_out = AT_BOOL;
        return true;
    }
    if p_text_eq(s, "@func") {
        rg_extern_type_from_name_out = AT_FUNC;
        return true;
    }
    return false;
}

!!! ---- the constructor ----

!!! the toolchain constructor binds the parser, the tokenizer, the error buffer and the
!!! note buffer; the buffers are rg_err/rg_notes, the parser and the tokenizer are
!!! modules, so the body left here is the -Rimp list: space separated pairs like
!!! "str-int str-float", the two switches the code generator reads, and
!!! "extern=func:type" entries the driver added for a linked DLL.
void rg_rgenerator -> str rimp_flags {
    if rimp_flags == null || rimp_flags[0] == (char)0 {
    end;
    }
    int n = pe_len(rimp_flags);
    int pos = 0;
    while pos < n {
        while pos < n && rimp_flags[pos] == ' ' {
            pos = pos + 1;
        }
        !!! `int stop = flags.find(' ', pos); if (stop == npos) stop = flags.size();`
        int stop = pos;
        while stop < n && rimp_flags[stop] != ' ' {
            stop = stop + 1;
        }
        if stop > pos {
            str p = pe_sub(rimp_flags, pos, stop - pos);
            if pe_matches(p, 0, "extern=") {
                !!! "name:type"; the type is absent when the .bmeta did not say
                !!! one, and int is what an extern is then.
                str ent = pe_sub_to_end(p, 7);
                int colon = pe_find(ent, ':');
                str fname = ent;
                if colon >= 0 {
                    fname = pe_sub(ent, 0, colon);
                }
                rg_extern_funcs = rg_set_add(rg_extern_funcs, fname);
                if colon >= 0 {
                    !!! The entry is recorded only when the reader knows the
                    !!! spelling, so an unreadable type leaves the function int.
                    if rg_extern_type_from_name(pe_sub_to_end(ent, colon + 1)) {
                        rg_extern_ret_types = rg_vartypemap_set(rg_extern_ret_types, fname,
                                                                rg_extern_type_from_name_out);
                        if rg_extern_type_from_name_out_unsigned {
                            rg_extern_ret_unsigned = rg_set_add(rg_extern_ret_unsigned, fname);
                        }
                    }
                }
            } else if p_text_eq(p, "-Econversion") {
                rg_wconversion = true;
            } else if p_text_eq(p, "-W-nused") {
                rg_warn_unused = true;
            } else if p_text_eq(p, "-W-read-nused") {
                rg_warn_read_unused = true;
            } else if p_text_eq(p, "-W-nused-struct") {
                rg_warn_unused_struct = true;
            } else if p_text_eq(p, "-W-read-nused-struct") {
                rg_warn_read_unused_struct = true;
            } else if p_text_eq(p, "-W-nbody-func") {
                rg_warn_nbody_func = true;
            } else if p_text_eq(p, "-W-ntype-cmp") {
                rg_warn_ntype_cmp = true;
            } else if p_text_eq(p, "-W-ntype-op") {
                rg_warn_ntype_op = true;
            } else if p_text_eq(p, "-W-userdef") {
                rg_warn_userdef = true;
            } else {
                !!! Also accept the reversed order: the pair is recorded both ways
                !!! round, so a conversion allowed one way is allowed the other.
                int dash = pe_find(p, '-');
                if dash >= 0 {
                    str rev = pe_sub_to_end(p, dash + 1) + "-" + pe_sub(p, 0, dash);
                    rg_rimp_allowed = rg_set_add(rg_rimp_allowed, p);
                    rg_rimp_allowed = rg_set_add(rg_rimp_allowed, rev);
                }
            }
        }
        pos = stop + 1;
    }
    !!! `attribute f: INT` (and the other type names) on an external function: the
    !!! type the .bmeta did not say, or the one it got wrong. A declaration that
    !!! already has a different type is a conflict and is reported, the way the toolchain
    !!! `RGenerator::apply_attributes` reports it. That pass also answers the
    !!! declarations of this file, which it walks (see `rg_apply_attr_decl`).
    @AttrUse tu = attr_uses;
    while tu != null {
        if rg_set_has(rg_extern_funcs, tu.object) && attr_kind(tu.name) == ATTR_KIND_TYPE {
            VarType ety = attr_type_of(tu.name);
            @RgVarTypeMap have = rg_vartypemap_find(rg_extern_ret_types, tu.object);
            if have != null && have.ty != ety {
                rg_fmt_err(tu.line, tu.col, "type attribute '" + tu.name +
                           "' does not match the declared type of '" + tu.object + "'",
                           tu.len, (str)null, 0, true);
                rg_has_errors = true;
            } else {
                rg_extern_ret_types = rg_vartypemap_set(rg_extern_ret_types, tu.object, ety);
                if attr_is_unsigned(tu.name) {
                    rg_extern_ret_unsigned = rg_set_add(rg_extern_ret_unsigned, tu.object);
                }
            }
        }
        tu = tu.next;
    }
}

!!! ---- the error layout ----

!!! fmt_err: one error of the code generator. The position is translated by the
!!! tokenizer's source map and replacement positions (`lex_show_pos`), the header
!!! naming the function is written once, and libbstr lays the message out.
void rg_fmt_err -> int line, int col, str msg, int highlight_len, str suggestion,
                   int sug_col, bool show_tilde {
    !!! Tokenizer::ShowPos sp = tok.show_pos(line, col);
    lex_show_pos(line, col);
    int use_line = g_show_line;
    int use_col = g_show_col;
    str use_fname = g_show_file;
    !!! str sl = sp.src_line.empty() ? tok.get_line(line) : sp.src_line;
    str sl = g_show_src;
    if sl == "" {
        sl = line_text(line);
    }
    int use_hl = highlight_len;
    if g_show_hl > 0 {
        use_hl = g_show_hl;
    }
    !!! If inside a function, emit the "In function" header once. the toolchain builds it
    !!! with zh_pick, so the Chinese text is what -Chinese asks for and the English
    !!! format is what it writes otherwise.
    if rg_cur_func_name != "" && rg_func_header == "" {
        !!! auto [hfname, hline] = tok.get_source(_func_line);
        lex_get_source(rg_func_line);
        str hfname = g_src_file;
        !!! A function returning a struct object is shown with that struct's name,
        !!! and the return type otherwise.
        str tn = rg_cur_func_ret_struct;
        if tn == "" {
            tn = type_name(rg_cur_func_ret);
        }
        rg_func_header = char_text((char)27) + "[1m" + hfname + char_text((char)27) +
                         "[0m" + zh_pick(": In function '", ": 在函数 '") +
                         char_text((char)27) + "[1m" + tn +
                         char_text((char)27) + "[1m" + char_text((char)27) +
                         "[38;2;244;164;96m " + rg_cur_func_name + char_text((char)27) +
                         "[0m" + zh_pick("':\n", "' 中:\n");
    }
    if rg_func_header != "" {
        rg_err = rg_err + rg_func_header;
        rg_func_header = "";
    }
    str m = msg;
    if m == null {
        m = "";
    }
    @void cell;
    malloc(@cell, 4096);
    str buf = (str)cell;
    !!! the toolchain writes `zh_msg(msg ? msg : "")`.
    ux_error_buf(buf, 4096, use_fname, use_line, use_col, zh_msg(m), sl, use_hl,
                 suggestion, sug_col, show_tilde);
    !!! The banner naming the `#head` file the text came from, in front of the error
    !!! (the `if (tok.is_head_source(use_fname)) err += head_file_banner(...)`).
    if lex_is_head_source(use_fname) {
        rg_err = rg_err + lex_head_banner(use_fname);
    }
    rg_err = rg_err + buf;
    unlink(@cell);
    !!! `macro 'str' expands to 'int1'`, pointing at the directive that wrote the
    !!! text the error was found in.
    @ReplaceInfo mi = g_show_macro;
    if mi != null {
        str mm = "macro '" + mi.from + "' expands to '" + mi.to + "'";
        @void ncell;
        malloc(@ncell, 1024);
        str nb = (str)ncell;
        ux_note_buf(nb, 1024, mi.filename, mi.line_to, mi.col_to, zh_msg(mm), mi.src_line,
                    pe_len(mi.to));
        if lex_is_head_source(mi.filename) {
            rg_err = rg_err + lex_head_banner(mi.filename);
        }
        rg_err = rg_err + nb;
        unlink(@ncell);
    }
}
