#once
!~
 ~  bootstrap/frontend/parser_error.b: the frontend/parser_error, with
 ~  the diagnostic body the toolchain parser keeps in parser's add_error.
 ~
 ~  Every message the front end prints goes through here and is laid out by libbstr -
 ~  `file:line:col: error: message`, the source line under it, the caret under the
 ~  span - because that is the layout the compiler prints, and writing it out
 ~  again here would be a second copy that has to stay the same by hand. The header
 ~  naming the function is printed once for the function the error is in, which is
 ~  what the toolchain parser does with `_func_header`.
 ~
 ~  Two things the toolchain add_error does are not here yet: the banner that names the
 ~  `#head` file a piece of text came from (libbstr's `head_file_banner`, which is
 ~  not exported to blang) and the note under text a `#replace` rewrote. The
 ~  positions themselves are translated: the tokenizer's source map and replacement
 ~  positions (see lexer.b, `lex_show_pos`) are what the file, line and column of
 ~  a diagnostic are read from, so a message about a line of a `#head` file names
 ~  that file.
 ~!

#head "parser"
#head "text_buf"
#head "Chinese/chinese_heads"

!!! One diagnostic at a position. `len` is how many bytes of the line are the
!!! subject; 1 is used when nothing better is known, so the caret always shows.
void p_error_msg -> int line, int col, int len, str msg, str suggestion, int sug_col,
                    bool show_tilde {
    if p_func_name != "" && !p_header_done {
        !!! The same header the toolchain parser writes, codes and all: the file in bold,
        !!! then "In function '", the return type, and the name in the orange the
        !!! compiler uses for it. The escape byte is written as a char because the
        !!! language's string escapes have no octal form.
        !!! The file is the one the function's own line stands in, which the toolchain
        !!! reads with `tok.get_source(_func_line)`: a function written in a `#head`
        !!! file is headed by that file and not by the one being compiled.
        lex_get_source(p_func_line);
        system.err((char)27, "[1m", g_src_file, (char)27, "[0m",
                   zh_pick(": In function '", ": 在函数 '"));
        system.err((char)27, "[1m", p_func_ret, (char)27, "[1m");
        system.err((char)27, "[38;2;244;164;96m ", p_func_name, (char)27, "[0m",
                   zh_pick("':\n", "' 中:\n"));
        !!! The header stands before every error of the function, not once for the
        !!! function: the toolchain parser clears `_func_header` as soon as it has
        !!! appended it, and the flag being down is what builds it again for the
        !!! error after this one. Leaving it up printed the first error of a
        !!! function with a header and every one after it without.
        p_header_done = false;
    }
    if len <= 0 {
        len = 1;
    }
    if col < 1 {
        col = 1;
    }
    !!! The position is a position in the preprocessed text: the source map and the
    !!! replacement positions say which file, which line, and which column of the
    !!! line as it was written, the problem really stands at. A `#head` file is
    !!! named by the position itself, so the file in the header is the one that
    !!! holds the text.
    lex_show_pos(line, col);
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
    !!! The message body first, the category word of the header last, which is what
    !!! the toolchain parser does with `zh_msg(msg)` and the driver does with
    !!! `zh_prefixes` over the whole block it collected.
    ux_error_buf(buf, 4096, g_show_file, g_show_line, g_show_col, zh_msg(msg), text, len,
                 suggestion, sug_col, show_tilde);
    !!! The banner naming the `#head` file the text came from, in front of the error
    !!! (the `if (tok.is_head_source(use_fname2)) err += head_file_banner(...)`).
    if lex_is_head_source(g_show_file) {
        system.err(lex_head_banner(g_show_file));
    }
    system.err(zh_prefixes(buf));
    unlink(@cell);
    unlink(@text);
    !!! The note under text a `#replace` rewrote: it points at the directive that
    !!! wrote the text (`if (sp.macro) err += macro_note(*sp.macro)`).
    @ReplaceInfo mi = g_show_macro;
    if mi != null {
        str mm = "macro '" + mi.from + "' expands to '" + mi.to + "'";
        @void ncell;
        malloc(@ncell, 1024);
        str nb = (str)ncell;
        ux_note_buf(nb, 1024, mi.filename, mi.line_to, mi.col_to, zh_msg(mm), mi.src_line,
                    pe_len(mi.to));
        if lex_is_head_source(mi.filename) {
            system.err(lex_head_banner(mi.filename));
        }
        system.err(zh_prefixes(nb));
        unlink(@ncell);
    }
    p_errors = p_errors + 1;
}

!!! The plain form: a message with no suggestion, which is the shape most of the
!!! parser's messages have.
void p_error_at -> int line, int col, int len, str msg {
    p_error_msg(line, col, len, msg, (str)null, 0, false);
}

!!! The same with a suggestion: a green replacement line and the tildes under it,
!!! which is how the toolchain parser points at the text a name should have been.
void p_error_at_sug -> int line, int col, int len, str msg, str sug, int sug_col {
    p_error_msg(line, col, len, msg, sug, sug_col, true);
}

!!! The diagnostic for the token the parser is standing on, with the length the
!!! `add_error(line, col, msg)` leaves at its default: zero, which libbstr draws
!!! as a single caret. Taking the token's own spelling here marked one character
!!! of a longer token (`missing ')'` underlining `etc` three characters wide).
void p_error -> str msg {
    p_error_at(p_cur.line, p_cur.col, 0, msg);
}

!!! error_at_cur: the same, with the position of the token that ended the file taken
!!! from the token before it, so a message about an unexpected end of file points at
!!! the last thing that was there.
!!!
!!! The reporting helpers end with `sync()` (`parser_error`, both
!!! error_at_cur and error_at_prev), so the statement that failed is left behind
!!! before the caller gets control again: the block loop then sees a token that is
!!! no longer a statement boundary where the reader left off and syncs a second
!!! time, which is what steps over the statement after the broken one. A reporting
!!! helper that does not sync here therefore reports one error too many (a `+ +;`
!!! followed by another statement that cannot start one buried the output in
!!! messages about every character of it).
void p_error_cur -> str msg {
    int line = p_cur.line;
    int col = p_cur.col;
    int hlen = p_cur.stop - p_cur.start;
    if line == 0 && p_pos > 0 {
        Token prev = p_tok(p_pos - 1);
        line = prev.line;
        col = prev.col + (prev.stop - prev.start);
        hlen = 0;
    }
    p_error_at(line, col, hlen, msg);
    p_sync();
}

!!! error_at_prev: the message belongs to the token that was consumed last, and a
!!! suggestion stands right after it.
!!!
!!! The width is the room the token takes in the source, which is what
!!! `stop - start` already is: a string literal carries its two quotes in that
!!! span, so two were added to a length that had them, and the underline reached
!!! past the literal. the `Parser::error_at_prev` takes the same length from
!!! `Token::src_len`.
void p_error_prev -> str msg {
    int hlen = p_prev.stop - p_prev.start;
    p_error_at(p_prev.line, p_prev.col, hlen, msg);
    p_sync();
}

void p_error_prev_sug -> str msg, str sug {
    int hlen = p_prev.stop - p_prev.start;
    p_error_at_sug(p_prev.line, p_prev.col, hlen, msg, sug, p_prev.col + hlen);
    p_sync();
}

!!! The note under a "missing ')'", pointing at the '(' it belongs to:
!!!
!!!     3 |     f(a, b;
!!!       |     ^ note: unmatched this '('
!!!
!!! the toolchain writes it where the parser found the mistake and hands it to the
!!! driver through `block_notes`, which the driver prints after the errors of the
!!! file; it is collected in p_block_notes here for the same reason. The position
!!! is a visual column: a tab counts to the next multiple of eight, which is what
!!! the toolchain version computes by expanding the tabs of the line, and the line
!!! itself is highlighted around the bracket the same way.
!!!
!!! The `{` of a block nothing closed is drawn by the same layout with another
!!! character, which is the one thing that differs between the two blocks of the
!!! (`parser` for the paren, `parser_block` for the brace), so the two
!!! wrappers below share this body.
void p_unmatched_note -> int note_line, int note_col, char br {
    str esc = char_text((char)27);
    !!! The line the bracket was written on, not the line it stands on once `#head`
    !!! and `#replace` expanded the text. the toolchain asks `tok.get_source` for the
    !!! (file, line) the preprocessed line came from; naming the expanded line put
    !!! the note at line 102 of a nine line file.
    lex_get_source(note_line);
    str shown_file = g_src_file;
    int shown_line = g_src_line;
    str src = line_text(note_line);
    int slen = pe_len(src);
    int vcol = 0;
    int i = 0;
    while i < note_col - 1 && i < slen {
        if src[i] == '\t' {
            vcol = (vcol + 8) - (vcol % 8);
        } else {
            vcol = vcol + 1;
        }
        i = i + 1;
    }
    !!! A position a caller left empty must not index before the line, and one past
    !!! the end of it has nothing to mark.
    int hl = note_col - 1;
    if hl < 0 {
        hl = 0;
    }
    if hl > slen {
        hl = slen;
    }
    !!! The source line, with the bracket in bold cyan and every tab written out.
    @TextBuf colored = tx_new();
    int k = 0;
    while k < hl {
        if src[k] == '\t' {
            tx_add(colored, "        ");
        } else {
            tx_add_ch(colored, src[k]);
        }
        k = k + 1;
    }
    tx_add(colored, esc + "[1m" + esc + "[1;36m");
    if hl < slen {
        if src[hl] == '\t' {
            tx_add(colored, " ");
        } else {
            tx_add_ch(colored, src[hl]);
        }
    }
    tx_add(colored, esc + "[0m");
    k = hl + 1;
    while k < slen {
        if src[k] == '\t' {
            tx_add(colored, "        ");
        } else {
            tx_add_ch(colored, src[k]);
        }
        k = k + 1;
    }
    !!! The line of the caret: the padding that lines the '|' up with the number
    !!! above, then the visual column, then the caret.
    int digits = 1;
    int lv = shown_line;
    while lv >= 10 {
        digits = digits + 1;
        lv = lv / 10;
    }
    @TextBuf pad = tx_new();
    int p2 = 0;
    while p2 < digits + 2 {
        tx_add_ch(pad, ' ');
        p2 = p2 + 1;
    }
    @TextBuf ul = tx_new();
    int s2 = 0;
    while s2 < vcol {
        tx_add_ch(ul, ' ');
        s2 = s2 + 1;
    }
    tx_add(ul, esc + "[1m" + esc + "[1;36m^" + esc + "[0m");
    !!! The banner that names the `#head` file the bracket came from, in front of
    !!! the note (the `if (tok.is_head_source(fname)) block_notes +=
    !!! head_file_banner(*fname)`).
    if lex_is_head_source(shown_file) {
        p_block_notes = p_block_notes + lex_head_banner(shown_file);
    }
    !!! The note itself, in the shape the `snprintf` gives it: the file and the
    !!! position stay inside the bold the note opens, so no reset stands between
    !!! them (`"%s%s:%d:%d: %snote:%s ..."` with B, file, line, col, C, R).
    p_block_notes = p_block_notes + esc + "[1m" + shown_file + ":" +
                    (str)shown_line + ":" + (str)note_col + ": " + esc + "[1;36m" +
                    zh_pick("note:", "提示:") + esc + "[0m" +
                    zh_pick(" unmatched this '", " 此处未匹配的 '") + esc + "[1m" +
                    char_text(br) + esc + "[0m" + "'\n";
    !!! The line under it and the caret are the block a program that came in on
    !!! standard input does not have shown: the note is its header alone.
    if ux_source_shown() {
        p_block_notes = p_block_notes + " " + (str)shown_line + " | " +
                        tx_copy(colored) + "\n" +
                        tx_copy(pad) + "| " + tx_copy(ul) + "\n";
    }
}

!!! The note under a "missing ')'": the `(` no `)` closed.
void p_unmatched_paren_note -> int lparen_line, int lparen_col {
    p_unmatched_note(lparen_line, lparen_col, '(');
}

!!! The note under a "meaningless EOF; missing '}'": the `{` no `}` closed.
void p_unmatched_brace_note -> int lbrace_line, int lbrace_col {
    p_unmatched_note(lbrace_line, lbrace_col, '{');
}
