#once
!~
 ~  bootstrap/frontend/rgen_type_note.b: the frontend/rgen_type_note.
 ~
 ~  The note under a type mismatch: it names the type the position needs and the
 ~  type that stands there, and it draws both places of the line - the declaration's
 ~  type in blue and the value's expression in green - with a caret under each and a
 ~  label line naming the two types under those carets.
 ~
 ~  the toolchain builds the whole block with snprintf, and so does this: the header, the
 ~  colored source line, the two marker lines and the label line are ordinary text,
 ~  and every escape in it is written whether or not the output is a terminal.
 ~!
 
#head "rgen"
#head "rgen_heads"
#head "Chinese/chinese_heads"

!!! emit_type_note: the note that says the declaration has one type and the value
!!! another. `lc`/`ll` are the position and the length of the span the note points
!!! at, `rc`/`rl` the ones of the expression; a missing position must not index
!!! before the line, which is what the two clamps do.
void rg_emit_type_note -> @StmtNode d, @ExprNode n, VarType missing, VarType actual {
    str sn = rg_type_name(missing);
    str sa = rg_type_name(actual);
    int lc = 0;
    int ll = 0;
    int note_line = d.line;
    if d.nk == DECLARE {
        lc = d.type_col - 1;
        ll = d.type_len;
    } else {
        lc = d.var_col - 1;
        ll = pe_len(d.var_name);
    }
    if lc < 0 {
        lc = 0;
    }
    !!! `str src = tok.get_line(note_line)`: the line as it was read, with the
    !!! line ending it was read with - that ending is what closes the source line of
    !!! the block below.
    str src = line_text(note_line);
    int slen = pe_len(src);
    int rc = n.col - 1;
    if rc < 0 {
        rc = 0;
    }
    if rc > slen {
        rc = slen;
    }
    int rl = n.tok_len;
    !!! auto [fname, orig_line] = tok.get_source(note_line);
    lex_get_source(note_line);
    int orig_line = g_src_line;
    !!! The visual columns of the two spans - a tab jumps to the next multiple of
    !!! eight - and the widths the marker and label lines are drawn with. A span of
    !!! no width still gets a caret.
    int vlc = rgx_vis_col(src, lc);
    int vll = rgx_vis_col(src, lc + ll) - vlc;
    int vrc = rgx_vis_col(src, rc);
    int vrl = rgx_vis_col(src, rc + rl) - vrc;
    if vll <= 0 {
        vll = 1;
    }
    if vrl <= 0 {
        vrl = 1;
    }
    str esc = char_text((char)27);
    str B = esc + "[1m";
    str R = esc + "[0m";
    str NC = esc + "[1;36m";
    str BL = esc + "[1;34m";
    str GB = esc + "[1;92m";
    !!! The blanks in front of the bar every line but the first starts with: the
    !!! width of the line number plus two.
    str bar = rgx_spaces(rgx_digits(orig_line) + 2) + "| ";
    str tildes = "";
    int ti = 1;
    while ti < vll {
        tildes = tildes + "~";
        ti = ti + 1;
    }
    !!! The banner naming the `#head` file the position came from, in front of the
    !!! note. the toolchain adds head_file_banner on both paths (the one that shows the
    !!! source line and the one that does not), and the header below is where the
    !!! note starts either way.
    if lex_is_head_source(g_src_file) {
        rg_err = rg_err + lex_head_banner(g_src_file);
    }
    !!! The header: `zh_pick("%s%s:%d:%d: %snote:%s has '%s%s%s' and '%s%s%s'\n")`.
    rg_err = rg_err + B + g_src_file + ":" + (str)orig_line + ":" + (str)(lc + 1) +
             ": " + NC + zh_pick("note:", "提示:") + R +
             zh_pick(" has '", " 需要 '") + B + sn + R +
             zh_pick("' and '", "'，而这里是 '") + B + sa + R + "'\n";
    !!! The block under it - the source line, the two carets and the two names - is
    !!! what a program that came in on standard input does not have shown: there is
    !!! no file whose line could be put there.
    if !ux_source_shown() {
        end;
    }
    rg_err = rg_err +
        !!! The source line, the declaration's span in blue and the expression's in
        !!! green, every tab written as eight blanks.
        " " + (str)orig_line + " | " +
        rgx_expand(src, 0, lc) + BL + rgx_expand(src, lc, lc + ll) + R +
        rgx_expand(src, lc + ll, rc) + GB + rgx_expand(src, rc, rc + rl) + R +
        rgx_expand(src, rc + rl, slen) + "\n" +
        !!! The caret of the declaration, then the bar of the expression.
        bar + rgx_spaces(vlc) + BL + "^" + tildes + R +
        rgx_spaces(vrc - (vlc + vll)) + GB + "|" + R + "\n" +
        !!! The two bars meeting: the declaration's drops to the label line and the
        !!! expression's falls to the name under it.
        bar + rgx_spaces(vlc) + BL + "|" + R +
        rgx_spaces(vrc - (vlc + 1)) + GB + "|" + R + "\n" +
        !!! The two type names.
        bar + rgx_spaces(vlc) + BL + sn + R +
        rgx_spaces(vrc - (vlc + pe_len(sn))) + GB + sa + R + "\n";
}
