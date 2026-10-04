#once
!~
 ~  bootstrap/frontend/text_buf.b: a text that is built by appending.
 ~
 ~  the toolchain appends to a str, which is amortized constant because the buffer
 ~  grows by doubling. `s = s + part` on a blang `str` copies the whole text again on
 ~  every append instead, which is quadratic in the size of what is being built: the
 ~  preprocessor's own output (about a megabyte for the compiler's sources) took a
 ~  hundred seconds that way, and the code generator's .r the same.
 ~
 ~  `TextBuf` is that growing buffer as a type, with `operator +` doing the append,
 ~  so every `s = s + part` call site stays exactly as it is and each one appends
 ~  into a block that is reallocated only when it fills. It is included before both
 ~  the preprocessor and the code generator, which are its two users.
 ~!

#head "stdsrt"

!!! `n` bytes from `src` to `dst`, eight at a time with the tail a byte at a time.
!!! Every append and every growth of a buffer goes through here, and the .r of a
!!! compile is megabytes: a byte at a time was a megabyte of one-byte steps. The
!!! bounds are the caller's (`k + 8 <= n` never reads past the piece being copied).
void tx_copy_bytes -> @char dst, @char src, int n {
    int k = 0;
    while k + 8 <= n {
        @longlong w = (@longlong)(src + k);
        @longlong t = (@longlong)(dst + k);
        $t = $w;
        k = k + 8;
    }
    while k < n {
        dst[k] = src[k];
        k = k + 1;
    }
}

type TextBuf {
    @char data;
    int len;
    int cap;

    !!! `b = b + s`. The answer carries the block (possibly a new one) and the new
    !!! length back to the variable that was assigned, and the block itself is
    !!! written through, so the append is in place.
    TextBuf operator + -> str s {
        TextBuf r;
        r.data = data;
        r.len = len;
        r.cap = cap;
        int n = pe_len(s);
        if r.len + n + 1 > r.cap {
            int want = r.cap * 2;
            if want < r.len + n + 1 {
                want = r.len + n + 1;
            }
            @void cell;
            malloc(@cell, want);
            @char nb = (@char)cell;
            tx_copy_bytes(nb, r.data, r.len);
            !!! The block it grew out of goes back before the pointer is replaced,
            !!! so a long build holds one block and not one per doubling.
            @char old = r.data;
            if r.cap > 0 {
                unlink(@old);
            }
            r.data = nb;
            r.cap = want;
        }
        tx_copy_bytes(r.data + r.len, (@char)s, n);
        r.len = r.len + n;
        r.data[r.len] = (char)0;
        return r;
    }
};

!!! ---- the same buffer reached through a pointer ----
!!!
!!! A buffer that belongs to one function call (the preprocessor's own output, one
!!! per `#include` level) is allocated and addressed through a pointer: a local of
!!! the struct type has no slot the emitter indexes safely, while a pointer's block
!!! is an ordinary piece of memory. `tx_add` is the append, in place, which is what
!!! the `result += part` does.

@TextBuf tx_new {
    TextBuf proto;
    @TextBuf b;
    malloc(@b, size proto);
    b.data = null;
    b.len = 0;
    b.cap = 0;
    return b;
}

!!! Make room for `need` more bytes (the terminator included).
void tx_reserve -> @TextBuf b, int need {
    if b.len + need <= b.cap {
        end;
    }
    int want = b.cap * 2;
    if want < b.len + need {
        want = b.len + need;
    }
    @void cell;
    malloc(@cell, want);
    @char nb = (@char)cell;
    tx_copy_bytes(nb, b.data, b.len);
    @char old = b.data;
    if b.cap > 0 {
        unlink(@old);
    }
    b.data = nb;
    b.cap = want;
}

!!! Add `s` to the end of the text `b` holds.
void tx_add -> @TextBuf b, str s {
    int n = pe_len(s);
    tx_reserve(b, n + 1);
    tx_copy_bytes(b.data + b.len, (@char)s, n);
    b.len = b.len + n;
    @char d = b.data;
    d[b.len] = (char)0;
}

!!! Add one character. The string form of this builds a one-character string on the
!!! heap first (`char_text`), and a loop over a whole source file - the comment
!!! stripper is one - would then allocate once per character of it.
void tx_add_ch -> @TextBuf b, char c {
    tx_reserve(b, 2);
    @char d = b.data;
    d[b.len] = c;
    b.len = b.len + 1;
    d[b.len] = (char)0;
}

!!! Add `s[from..to)` to the end of the text `b`. A walk that rebuilds a file line by
!!! line has the piece in hand already, so `pe_sub` would copy it onto the heap only
!!! for `tx_add` to copy it again into the buffer.
void tx_add_span -> @TextBuf b, str s, int from, int to {
    int n = to - from;
    if n <= 0 {
        end;
    }
    tx_reserve(b, n + 1);
    @char d = b.data;
    tx_copy_bytes(d + b.len, (@char)s + from, n);
    b.len = b.len + n;
    d[b.len] = (char)0;
}

!!! The text built so far (the block is already NUL-terminated, so nothing copies).
str tx_text -> @TextBuf b {
    if b.data == null {
        return "";
    }
    return (str)b.data;
}

!!! A copy of the text, for a caller that keeps it while more is appended.
str tx_copy -> @TextBuf b {
    return pe_sub(tx_text(b), 0, b.len);
}

!!! How many times the text of a buffer was asked for, which BLANG_TIME prints.
int g_n_txttext;

!!! How long the text of `b` is.
!!!
!!! `b = b + a + c` appends into the block but writes the length back only when the
!!! whole chain is assigned to `b`, so in the middle of such a chain `b.len` stands
!!! behind the text by exactly what the chain has appended so far: `b + a` and
!!! `that + c` carry the growing length in the temporaries the backend makes of them.
!!! The block is NUL-terminated at the end of the text, so the length of the tail
!!! from the recorded length is the rest of it.
int txt_len -> TextBuf b {
    if b.data == null {
        return 0;
    }
    @char d = b.data;
    return b.len + pe_len((str)(d + b.len));
}

!!! The text built so far. The block is NUL-terminated already, so nothing is
!!! copied - this is what a caller hands on as an ordinary string.
str txt_text -> TextBuf b {
    g_n_txttext = g_n_txttext + 1;
    if b.data == null {
        return "";
    }
    return (str)b.data;
}

!!! A copy of the text from `from` on. The block is NUL-terminated at its end, so
!!! the piece is a string of its own that a caller may keep while more is appended.
!!! The end of the text is measured (txt_len) rather than read from the recorded
!!! length, because the emitter that captures a piece calls this in the middle of a
!!! `b = b + a + c` chain, whose length is still in its temporaries.
str txt_slice -> TextBuf b, int from {
    int n = txt_len(b);
    if from < 0 {
        from = 0;
    }
    if from >= n {
        return "";
    }
    @char d = b.data;
    return pe_sub((str)(d + from), 0, n - from);
}

!!! Cut the text back to `len`, dropping what was appended after it. This is the
!!! other half of txt_slice for an emitter that puts the text aside, writes
!!! something else and then goes on where it was: the toolchain saves the whole
!!! str, clears it and assigns it back, which on a megabyte of output is a
!!! megabyte copied for every expression it captures.
void txt_cut -> @TextBuf b, int len {
    if len < 0 {
        len = 0;
    }
    if len >= b.len || b.data == null {
        end;
    }
    b.len = len;
    @char d = b.data;
    d[len] = (char)0;
}

!!! Empty the buffer and keep the block.
void txt_reset -> @TextBuf b {
    b.len = 0;
    !!! The block goes into a local pointer first: indexing a field of a struct
    !!! *pointer* (`b.data[0]`) is not a form the emitter writes yet, while an
    !!! index on a local pointer is.
    @char d = b.data;
    if d != null {
        d[0] = (char)0;
    }
}

!!! Record `len` as the length of the text `b` holds. The block is already
!!! NUL-terminated there, so only the recorded length changes. A caller that measured
!!! the text itself - `rgx_out_mark`, which cannot trust the length a half finished
!!! `b = b + a + c` chain left behind - puts the two back in step with this.
void txt_set_len -> @TextBuf b, int len {
    b.len = len;
}
