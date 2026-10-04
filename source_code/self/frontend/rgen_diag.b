#once
!~
 ~  bootstrap/frontend/rgen_diag.b: the frontend/rgen_diag.
 ~
 ~  The diagnostics of the code generator: the two lines that place a span in the
 ~  source (the line itself with the span in color, and the `^~~~` underline under
 ~  it), the entry of an operator list, the column a word stands at, and the note
 ~  that says an implicit conversion would make an error go away.
 ~
 ~  The messages and the category word of a header go through zh_msg and zh_pick
 ~  exactly where the toolchain calls them, so `-Chinese` prints the same text here as it
 ~  does there. Two things the toolchain uses here are not in the language, and what
 ~  stands in their place is written at each call: `bold_quotes` (libbstr bolds the
 ~  quoted names itself inside the layout functions) and `head_file_banner` (the
 ~  banner naming a `#head` file, which libbstr does not export to blang). The
 ~  position itself is translated the way the parser's diagnostics translate it:
 ~  `lex_show_pos` and `lex_get_source` are `tok.show_pos` and `tok.get_source`, so
 ~  a message about text a `#replace` produced is shown where the macro name stands.
 ~
 ~  The small helpers this file needs and rgen.b does not have carry the `rgx_`
 ~  prefix, so they can be moved next to the shared ones later.
 ~!

#head "rgen"
#head "rgen_heads"
#head "attributes"
#head "Chinese/chinese_heads"

!!! The small helpers this file needs, which rgen.b does not have.

!!! `while (!src.empty() && (src.back() == '\n' || src.back() == '\r'))`: the line
!!! without the ending it was read with.
int rgx_trim_eol -> str s {
    int n = pe_len(s);
    while n > 0 && (s[n - 1] == '\n' || s[n - 1] == '\r') {
        n = n - 1;
    }
    return n;
}

!!! The line a diagnostic shows at `line`, with lex_show_pos already run: the text
!!! the replacement table kept when a `#replace` produced this position (`str a =
!!! 0;`, not `int1 a = 0;`), the line itself otherwise. The block line_text made is
!!! not handed back - the two answers are not told apart here, and the text of a
!!! line is left standing the way the other modules of this implementation leave it.
str rgx_line_text -> int line {
    if g_show_src != "" {
        return g_show_src;
    }
    return line_text(line);
}

!!! The visual column of byte `pos`: a tab jumps to the next multiple of eight.
!!! This is the `vis_col` lambda of src_block.
int rgx_vis_col -> str s, int pos {
    int vc = 0;
    int i = 0;
    while i < pos && s[i] != (char)0 {
        if s[i] == '\t' {
            vc = (vc + 8) - (vc % 8);
        } else {
            vc = vc + 1;
        }
        i = i + 1;
    }
    return vc;
}

!!! `k` blanks, which is the padding a diagnostic block needs to reach a visual
!!! column. A negative count is no blanks at all, which is what a span that starts
!!! further left than the one before it asks for.
str rgx_spaces -> int k {
    str out = "";
    int i = 0;
    while i < k {
        out = out + " ";
        i = i + 1;
    }
    return out;
}

!!! The decimal spelling of `v` as `snprintf(buf, n, "%d", v)` counts it: how many
!!! characters the line number of the source block takes.
int rgx_digits -> int v {
    int x = v;
    int d = 1;
    if x < 0 {
        d = 2;
        x = 0 - x;
    }
    while x >= 10 {
        x = x / 10;
        d = d + 1;
    }
    return d;
}

!!! `isalnum((unsigned char)c)` under the C locale: a letter or a digit of ASCII,
!!! and false for every byte above 127. A character and a byte value are the same
!!! number to the language, so the tests are the ones the toolchain uses.
bool rgx_alnum -> char c {
    if c >= '0' && c <= '9' {
        return true;
    }
    if c >= 'a' && c <= 'z' {
        return true;
    }
    return c >= 'A' && c <= 'Z';
}

!!! `isspace((unsigned char)c)`, the same way.
bool rgx_space -> char c {
    if c == ' ' || c == '\t' || c == '\n' {
        return true;
    }
    !!! 11 is the vertical tab and 12 the form feed, written as numbers because the
    !!! language's string escapes have no form for them.
    if c == (char)11 || c == (char)12 || c == '\r' {
        return true;
    }
    return false;
}

!!! `src.find(needle, from)`: the offset of `needle` in `s` at or after `from`, or
!!! -1.
int rgx_find_from -> str s, str needle, int from {
    int n = pe_len(s);
    int m = pe_len(needle);
    int i = from;
    while i + m <= n {
        if pe_matches(s, i, needle) {
            return i;
        }
        i = i + 1;
    }
    return -1;
}

!!! `src.rfind(needle, before)`: the greatest offset at or before `before` where
!!! `needle` stands, or -1.
int rgx_rfind_from -> str s, str needle, int before {
    int n = pe_len(s);
    int m = pe_len(needle);
    int p = before;
    if p > n {
        p = n;
    }
    if p > n - m {
        p = n - m;
    }
    while p >= 0 {
        if pe_matches(s, p, needle) {
            return p;
        }
        p = p - 1;
    }
    return -1;
}

!!! One piece of a source line with its tabs written out, which is what the
!!! colored excerpt of src_block is built from.
str rgx_expand -> str s, int from, int to {
    str out = "";
    int i = from;
    while i < to {
        if s[i] == '\t' {
            out = out + "        ";
        } else {
            out = out + char_text(s[i]);
        }
        i = i + 1;
    }
    return out;
}

!!! src_block: the line itself, with the span written in the color libbstr uses for
!!! a note, and the `^~~~` underline under it, both in visual columns so a tab or a
!!! CJK character still lines the caret up. This is the block the toolchain fmt_note
!!! prints under its header, and the block an operator-list entry appends bare.
str rg_src_block -> int line, int col, int highlight_len {
    !!! Tokenizer::ShowPos sp = tok.show_pos(line, col); and
    !!! auto [fname, orig_line] = tok.get_source(line);
    lex_show_pos(line, col);
    lex_get_source(line);
    int show_line = g_show_line;
    int show_col = g_show_col;
    int show_hl = highlight_len;
    if g_show_hl > 0 {
        show_hl = g_show_hl;
    }
    !!! `sp.src_line.empty() ? tok.get_line(line) : sp.src_line`, with the ending
    !!! taken off.
    str raw = rgx_line_text(line);
    str src = pe_sub(raw, 0, rgx_trim_eol(raw));
    int slen = pe_len(src);
    !!! The three colors: B bold, C bold cyan, R reset.
    str esc = char_text((char)27);
    str B = esc + "[1m";
    str C = esc + "[1;36m";
    str R = esc + "[0m";
    !!! The underline, placed by visual columns.
    int vis_col_start = rgx_vis_col(src, show_col - 1);
    str underline = "";
    int i = 0;
    while i < vis_col_start {
        underline = underline + " ";
        i = i + 1;
    }
    underline = underline + B + C + "^";
    i = 1;
    while i < show_hl {
        underline = underline + "~";
        i = i + 1;
    }
    underline = underline + R;
    !!! A note without a usable position must not index before the line.
    int hl_start = show_col - 1;
    if hl_start < 0 {
        hl_start = 0;
    }
    if hl_start > slen {
        hl_start = slen;
    }
    int hl_end = hl_start + show_hl;
    if hl_end > slen {
        hl_end = slen;
    }
    !!! The line around the span: what stands before it plain, the span in the
    !!! note's color, what stands after it plain again. A tab is eight blanks here,
    !!! which is what the toolchain appends (`colored_src.append(8, ' ')`).
    str colored_src = rgx_expand(src, 0, hl_start);
    colored_src = colored_src + B + C;
    colored_src = colored_src + rgx_expand(src, hl_start, hl_end);
    colored_src = colored_src + R;
    colored_src = colored_src + rgx_expand(src, hl_end, slen);
    !!! The ` N | ` prefix of the source line and the blanks that line the `|` of
    !!! the underline up with it: `digits + 2` of them.
    str sprefix = "";
    i = 0;
    while i < rgx_digits(show_line) + 2 {
        sprefix = sprefix + " ";
        i = i + 1;
    }
    return " " + (str)show_line + " | " + colored_src + "\n" + sprefix + "| " +
           underline + "\n";
}

!!! The entry of an operator list.

!!! bold_quotes: the text inside single quotes is bold, so every note that quotes a
!!! name or a type stands out the same way. The escapes are the bytes the toolchain writes
!!! (`\033[1m` and `\033[0m`), and the quoting is closed at the end of the text when
!!! it was left open.
str rgx_bold_quotes -> str msg {
    str esc = char_text((char)27);
    str bold = esc + "[1m";
    str reset = esc + "[0m";
    str out = "";
    bool in_quote = false;
    int n = pe_len(msg);
    int i = 0;
    while i < n {
        char c = msg[i];
        if c == (char)39 {
            if in_quote {
                out = out + reset + "'";
            } else {
                out = out + "'" + bold;
            }
            in_quote = !in_quote;
        } else {
            out = out + char_text(c);
        }
        i = i + 1;
    }
    if in_quote {
        out = out + reset;
    }
    return out;
}

!!! fmt_list_item: one entry of the `-> operator N: <reason>` list. There is
!!! deliberately no `file:line:col: note:` prefix - the entry belongs to the list
!!! the note above it introduced - and the block below shows the declaration the
!!! reason is about. the toolchain writes the text through `zh_msg` and `bold_quotes`; the
!!! header is built here rather than by ux_note_buf, so the quoted names are bolded
!!! here as well.
void rg_fmt_list_item -> int index, str reason, int line, int col, int highlight_len {
    str text = reason;
    if text == null {
        text = "";
    }
    text = rgx_bold_quotes(zh_msg(text));
    !!! `"   \xE2\x86\x92 operator %d: %s\n"`: the marker is three UTF-8 bytes.
    str arrow = char_text((char)226) + char_text((char)134) + char_text((char)146);
    rg_err = rg_err + "   " + arrow + " operator " + (str)index + ": " + text + "\n";
    if ux_source_shown() {
        rg_err = rg_err + rg_src_block(line, col, highlight_len);
    }
}

!!! The column a word or the `operator` keyword stands at.

!!! word_col: the column `word` stands at, searched from `from_col` on, or 0. The
!!! word has to be a word of its own: the character before and the one after it may
!!! not be a letter, a digit or an `_`.
int rg_word_col -> int line, int from_col, str word {
    if line <= 0 || word == "" {
        return 0;
    }
    str raw = line_text(line);
    str src = pe_sub(raw, 0, rgx_trim_eol(raw));
    int slen = pe_len(src);
    if slen <= 0 {
        return 0;
    }
    int wl = pe_len(word);
    int at = 0;
    if from_col > 1 {
        at = from_col - 1;
    }
    while at + wl <= slen {
        int p = rgx_find_from(src, word, at);
        if p < 0 {
            return 0;
        }
        bool left = true;
        if p != 0 {
            if rgx_alnum(src[p - 1]) || src[p - 1] == '_' {
                left = false;
            }
        }
        int e = p + wl;
        bool right = true;
        if e < slen {
            if rgx_alnum(src[e]) || src[e] == '_' {
                right = false;
            }
        }
        if left && right {
            return p + 1;
        }
        at = p + 1;
    }
    return 0;
}

!!! operator_keyword_col: the column the `operator` keyword stands at on the line
!!! of a symbol, or 0. The keyword has to be the word right before the symbol -
!!! only whitespace may stand between them - so an `operator` inside a comment
!!! cannot be taken for it.
int rg_operator_keyword_col -> int line, int sym_col {
    if line <= 0 || sym_col <= 1 {
        return 0;
    }
    str raw = line_text(line);
    str src = pe_sub(raw, 0, rgx_trim_eol(raw));
    int slen = pe_len(src);
    if slen <= 0 {
        return 0;
    }
    !!! The 0-based column of the symbol.
    int before = sym_col - 1;
    int p = rgx_rfind_from(src, "operator", before);
    if p < 0 {
        return 0;
    }
    if p + 8 > before {
        return 0;
    }
    int i = p + 8;
    while i < before {
        if !rgx_space(src[i]) {
            return 0;
        }
        i = i + 1;
    }
    if p > 0 {
        if rgx_alnum(src[p - 1]) || src[p - 1] == '_' {
            return 0;
        }
    }
    return p + 1;
}

!!! The notes and the warnings.

!!! fmt_note: a note, laid out the way every other note of the front end is. The
!!! builds the header itself (`zh_pick`) and appends `src_block` under it; the
!!! port calls ux_note_buf instead, the libbstr layout the parser writes its notes
!!! with, which draws that same header - quoted names in bold - with the source
!!! line and the caret under it. The block is not appended a second time: the one
!!! src_block builds is the source line and the caret ux_note_buf has drawn.
void rg_fmt_note -> int line, int col, str msg, int highlight_len {
    !!! Tokenizer::ShowPos sp = tok.show_pos(line, col); and
    !!! auto [fname, orig_line] = tok.get_source(line);
    !!! A position a caller left empty must not index before the line, which is the
    !!! clamp the parser's own diagnostics make.
    if col < 1 {
        col = 1;
    }
    lex_show_pos(line, col);
    int use_line = g_show_line;
    int use_col = g_show_col;
    str m = msg;
    if m == null {
        m = "";
    }
    !!! The header is built here and not by ux_note_buf: the toolchain writes this one
    !!! itself, so its bold and cyan escapes are written whether or not the output
    !!! is a terminal, while libbstr's layout drops them when it is not. Quoted names
    !!! and types are bold in every note, which is `bold_quotes`.
    str esc = char_text((char)27);
    !!! The banner naming the `#head` file the note came from, in front of the note
    !!! (the `if (tok.is_head_source(mfname)) err += head_file_banner(...)`).
    if lex_is_head_source(g_show_file) {
        rg_err = rg_err + lex_head_banner(g_show_file);
    }
    rg_err = rg_err + esc + "[1m" + g_show_file + ":" + (str)use_line + ":" +
             (str)use_col + ": " + esc + "[1;36m" + zh_pick("note:", "提示:") +
             esc + "[0m " + rgx_bold_quotes(zh_msg(m)) + "\n";
    !!! The source line and its caret are the block a program that came in on
    !!! standard input does not have shown.
    if ux_source_shown() {
        rg_err = rg_err + rg_src_block(line, col, highlight_len);
    }
}

!!! fmt_warn: a warning, which is the libbstr call the toolchain makes itself
!!! (`ux_warning_buf`), so the layout is the same one.
void rg_fmt_warn -> int line, int col, str msg, int highlight_len {
    !!! `attribute f: NOWARN` keeps the warnings of that function's body out of the
    !!! output: the range is the function's own lines, which is where every warning
    !!! about it and about what it holds stands.
    if attr_in_nowarn(line) {
        end;
    }
    if col < 1 {
        col = 1;
    }
    lex_show_pos(line, col);
    lex_get_source(line);
    int hl = highlight_len;
    if g_show_hl > 0 {
        hl = g_show_hl;
    }
    str m = msg;
    if m == null {
        m = "";
    }
    str text = rgx_line_text(line);
    @void cell;
    malloc(@cell, 2048);
    str buf = (str)cell;
    !!! Quoted names and types are bold in a warning too, the way they are in a
    !!! note (`bold_quotes`): a diagnostic that quotes a type reads the same
    !!! wherever it stands.
    ux_warning_buf(buf, 2048, g_show_file, g_show_line, g_show_col,
                   rgx_bold_quotes(zh_msg(m)), text, hl);
    !!! The banner naming the `#head` file, as in fmt_note (the toolchain
    !!! `if (tok.is_head_source(mfname)) notes += head_file_banner(...)`).
    if lex_is_head_source(g_show_file) {
        rg_notes = rg_notes + lex_head_banner(g_show_file);
    }
    rg_notes = rg_notes + buf;
    unlink(@cell);
}

!!! emit_rimp_note: the deferred note that says the error disappears for each type
!!! cast from one type to the other. Keyed by the statement's line and the two
!!! types, so the many passes that reach the same mismatch record it once, and
!!! stored in rg_rimp_deferred (the `_rimp_deferred`) for the driver to flush
!!! at the end. The header is the `zh_pick` of the toolchain, written here because the
!!! escapes in it are unconditional: no source line stands under it, since the toolchain
!!! writes the header alone and nothing reads the line it names.
void rg_emit_rimp_note -> @StmtNode d, @ExprNode n, VarType missing, VarType actual {
    str sn = rg_type_name(missing);
    str sa = rg_type_name(actual);
    str key = (str)d.line + ":" + sn + "-" + sa;
    if rg_strmap_find(rg_rimp_deferred, key) != null {
        !!! already recorded
        end;
    }
    int note_line = d.var_line;
    int note_col = d.var_col;
    if d.nk == DECLARE {
        note_line = d.line;
        note_col = d.type_col;
    }
    !!! A note without a usable position must not index before the line.
    if note_col < 1 {
        note_col = 1;
    }
    !!! auto [fname, orig_line] = tok.get_source(note_line);
    lex_get_source(note_line);
    str esc = char_text((char)27);
    !!! The banner of the `#head` file the position came from, in front of the note
    !!! (the `if (tok.is_head_source(fname)) note += head_file_banner(...)`).
    str head_banner = "";
    if lex_is_head_source(g_src_file) {
        head_banner = lex_head_banner(g_src_file);
    }
    !!! `error disappears for each type cast from '<b>sn</b>' to '<b>sa</b>'`.
    rg_rimp_deferred = rg_strmap_set(rg_rimp_deferred, key,
        head_banner +
        esc + "[1m" + g_src_file + ":" + (str)g_src_line + ":" + (str)note_col + ": " +
        esc + "[1;36m" + zh_pick("note:", "提示:") + esc + "[0m" +
        zh_pick(" error disappears for each type cast from '", " 每次从 '") +
        esc + "[1m" + sn + esc + "[0m" +
        zh_pick("' to '", "' 到 '") +
        esc + "[1m" + sa + esc + "[0m" +
        zh_pick("'\n", "' 的类型转换都会让这个错误消失\n"));
}
