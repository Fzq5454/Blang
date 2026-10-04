#once
!~
 ~  bootstrap/frontend/rgen_out.b: the text the code generator builds.
 ~
 ~  The buffer itself is `TextBuf` (text_buf.b) and the append is its `operator +`,
 ~  so every `rg_rcode = rg_rcode + text` call site in this implementation stays exactly as it
 ~  is and each one appends into a block that is reallocated only when it fills: a
 ~  str append is amortized constant, while copying the whole text per
 ~  append is quadratic. That one pass took 94% of the time on a small file, and on
 ~  the whole front end (a .r of 1.1 MB) it never finished.
 ~
 ~  `rg_rcode` lives here rather than in rgen.b because the type has to be declared
 ~  before the variable, and this module is included first.
 ~!

#head "rgen_heads"

TextBuf rg_rcode;

!!! The text built so far, as a string. The block is NUL-terminated, so nothing is
!!! copied: this is the .r the driver writes out.
str rgx_out_text {
    return txt_text(rg_rcode);
}

!!! How long the text built so far is. It is measured (txt_len) and not read from
!!! `rg_rcode.len`, which a half finished `rg_rcode = rg_rcode + a + b` chain has not
!!! written back yet: the emitters that capture a piece of the text run in the middle
!!! of such a chain, where the recorded length stands before the text the chain has
!!! already appended.
int rgx_out_len {
    return txt_len(rg_rcode);
}

!!! Mark where the text stands now. An emitter that has to put the buffer aside
!!! marks it here, emits, takes the piece from the mark and cuts back to it, which
!!! copies only the piece and not everything emitted before it. the toolchain saves the
!!! whole str and assigns it back, which costs the whole .r for every
!!! expression it captures - on the compiler's own source that alone was most of
!!! the emitter's time.
int rgx_out_mark {
    int len = rgx_out_len();
    !!! The buffer is told its own length before anything is emitted at the mark:
    !!! every append reads `rg_rcode.len`, so with the length a half finished chain
    !!! left behind the index would be written over the text that chain has already
    !!! appended, and the piece taken from the mark would be that text.
    txt_set_len(@rg_rcode, len);
    return len;
}

!!! The text from `from` on, as a string of its own.
str rgx_out_slice -> int from {
    return txt_slice(rg_rcode, from);
}

!!! Cut the text back to `mark`, dropping what was emitted after it.
void rgx_out_cut -> int mark {
    txt_cut(@rg_rcode, mark);
}

!!! Empty the buffer, keeping the block: the driver empties it before a
!!! generation, because a run reports its .r once.
void rgx_out_reset {
    txt_reset(@rg_rcode);
}
