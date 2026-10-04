#once
!~
 ~  bootstrap/frontend/preprocessor.b: the frontend/preprocessor.
 ~
 ~  The passes that run over the text before the tokenizer sees it: `#head` and
 ~  `#import` pull other files in, `#replace` rewrites names, `#export` publishes
 ~  them, `#newline` writes a line break where a string literal cannot hold one, and
 ~  `#if` decides which lines are read at all.
 ~
 ~  Two things about how the passes work here, because the language has no
 ~  containers:
 ~   * every table the toolchain version keeps in a name table or name table is a
 ~     chain searched by key (the source map, the replacement positions, the
 ~     defines, the exports);
 ~   * a position is an int and the two coordinates of a source are a record, so a
 ~     pass that walks the text carries them explicitly the way the toolchain lambdas
 ~     capture them.
 ~
 ~  This file is written in the order one: the path cleaner, the
 ~  replacements, the newline markers, the import expansion, the head expansion and
 ~  then the entry points.
 ~!

#head "fileio"
#head "preproc_env"
#head "preprocessor_heads"

!!! One `#replace` directive: the name it replaces, the text it stands for, where
!!! the directive itself was written and where the name stood where it was used:
!!! the record is ReplaceInfo, declared in preprocessor_heads.b with the rest of
!!! the pass's surface, and so are the source map and the replacement positions.

@ReplaceInfo pp_new_replace -> str from, str to, str filename, int line_to, int col_to,
                               str src_line {
    ReplaceInfo proto;
    @ReplaceInfo r;
    malloc(@r, size proto);
    r.from = from;
    r.to = to;
    r.filename = filename;
    r.line_to = line_to;
    r.col_to = col_to;
    r.src_line = src_line;
    r.line_from = 0;
    r.col_from = 0;
    r.src_line_from = "";
    r.next = null;
    return r;
}

!!! A copy of one replacement record: an occurrence carries the place it was found
!!! without changing the directive it came from.
@ReplaceInfo pp_copy_replace -> @ReplaceInfo r {
    @ReplaceInfo c = pp_new_replace(r.from, r.to, r.filename, r.line_to, r.col_to, r.src_line);
    c.line_from = r.line_from;
    c.col_from = r.col_from;
    c.src_line_from = r.src_line_from;
    return c;
}

!!! Fold "." and ".." segments so a header path shown in a diagnostic stays
!!! readable: BLANG_HOME points at <root>\bin, so the resolved header path is
!!! "<root>\bin\..\includes\bl\window" and should read "<root>\includes\bl\window".
str preprocess_clean_path -> str p {
    str prefix = "";
    int i = 0;
    int n = pe_len(p);
    if n >= 2 && p[1] == ':' {
        prefix = pe_sub(p, 0, 2);                 !!! drive letter, e.g. "C:"
        i = 2;
    } else if n >= 2 && (p[0] == '\\' || p[0] == '/') && (p[1] == '\\' || p[1] == '/') {
        prefix = pe_sub(p, 0, 2);                 !!! UNC server path
        i = 2;
    } else if n >= 1 && (p[0] == '\\' || p[0] == '/') {
        prefix = pe_sub(p, 0, 1);                 !!! rooted path
        i = 1;
    }
    @NameList parts = null;
    @NameList tail = null;
    while i < n {
        while i < n && (p[i] == '\\' || p[i] == '/') {
            i = i + 1;
        }
        int j = i;
        while j < n && p[j] != '\\' && p[j] != '/' {
            j = j + 1;
        }
        if j > i {
            str seg = pe_sub(p, i, j - i);
            if pe_eq(seg, "..") {
                if parts != null {
                    str lastp = pp_last_name(parts);
                    if !pe_eq(lastp, "..") {
                        parts = pp_drop_last(parts);
                        !!! The end of the chain follows the chain. `tail` still named the
                        !!! node that was just dropped, so every segment after this `..`
                        !!! was linked onto a node no reader reaches and fell out of the
                        !!! path: `...\bootstrap\bin\..\includes\bl\vector` came back as
                        !!! `...\bootstrap`. The path is what `#once` remembers a file by
                        !!! (pp_once_key), so every header found through that `..` carried
                        !!! one key, and the second of them was taken for a file already
                        !!! read and dropped - with `#once` on the headers of includes\bl
                        !!! that is every one of them but the first.
                        tail = parts;
                        while tail != null && tail.next != null {
                            tail = tail.next;
                        }
                    } else {
                        @NameList nn = p_namelist_add(null, seg);
                        if parts == null {
                            parts = nn;
                        } else {
                            tail.next = nn;
                        }
                        tail = nn;
                    }
                } else {
                    @NameList nn2 = p_namelist_add(null, seg);
                    if parts == null {
                        parts = nn2;
                    } else {
                        tail.next = nn2;
                    }
                    tail = nn2;
                }
            } else if !pe_eq(seg, ".") {
                @NameList nn3 = p_namelist_add(null, seg);
                if parts == null {
                    parts = nn3;
                } else {
                    tail.next = nn3;
                }
                tail = nn3;
            }
        }
        i = j;
    }
    str out = prefix;
    @NameList k = parts;
    while k != null {
        int ln = pe_len(out);
        if ln > 0 && out[ln - 1] != '\\' && out[ln - 1] != '/' {
            out = out + "\\";
        }
        out = out + k.name;
        k = k.next;
    }
    if out == "" {
        return p;
    }
    return out;
}

!!! The last entry of a name list.
str pp_last_name -> @NameList head {
    str s = "";
    @NameList n = head;
    while n != null {
        s = n.name;
        n = n.next;
    }
    return s;
}

!!! The list without its last entry.
@NameList pp_drop_last -> @NameList head {
    if head == null || head.next == null {
        return null;
    }
    @NameList n = head;
    while n.next != null && n.next.next != null {
        n = n.next;
    }
    n.next = null;
    return head;
}

!!! ---- the source map ----
!!!
!!! One entry per preprocessed line, as three blocks in ascending line order (see
!!! LineSrc). the toolchain holds the same thing in a name table, so a lookup and
!!! an insertion there cost nothing; here a lookup is the binary search below and
!!! an insertion is an append, which is what makes the passes over the text one
!!! walk each instead of one walk per line.

!!! Bytes one element of each block takes. `T proto; size proto` is how the vector
!!! include asks the same question.
int pp_int_bytes {
    int proto;
    return size proto;
}

int pp_str_bytes {
    str proto;
    return size proto;
}

!!! An empty map. A map is reached through a pointer, so it is made on the heap:
!!! the toolchain makes a fresh local unordered_map at each of these places.
@LineSrc pp_src_new {
    LineSrc proto;
    @LineSrc m;
    malloc(@m, size proto);
    m.lines = null;
    m.files = null;
    m.srcs = null;
    m.len = 0;
    m.cap = 0;
    return m;
}

void pp_src_grow -> @LineSrc map {
    int want = map.cap * 2;
    if want < 16 {
        want = 16;
    }
    @int lines = map.lines;
    @str files = map.files;
    @int srcs = map.srcs;
    @int nl;
    @str nf;
    @int ns;
    malloc(@nl, want * pp_int_bytes());
    malloc(@nf, want * pp_str_bytes());
    malloc(@ns, want * pp_int_bytes());
    int i = 0;
    while i < map.len {
        nl[i] = lines[i];
        nf[i] = files[i];
        ns[i] = srcs[i];
        i = i + 1;
    }
    if map.cap > 0 {
        unlink(@lines);
        unlink(@files);
        unlink(@srcs);
    }
    map.lines = nl;
    map.files = nf;
    map.srcs = ns;
    map.cap = want;
}

!!! The index of the entry for `line`, or -1. The blocks are in ascending line
!!! order, so this is a binary search.
int pp_src_find -> @LineSrc map, int line {
    if map == null {
        return -1;
    }
    @int lines = map.lines;
    int lo = 0;
    int hi = map.len - 1;
    !!! The middle is a shift: `/ 2` is an idiv, and this walk runs once per line
    !!! the preprocessor writes. lo + hi is never negative, so the two agree.
    while lo <= hi {
        int mid = (lo + hi) >> 1;
        int v = lines[mid];
        if v == line {
            return mid;
        }
        if v < line {
            lo = mid + 1;
        } else {
            hi = mid - 1;
        }
    }
    return -1;
}

!!! `map[line] = (file, src_line)`: the entry at that line is replaced, and a line
!!! that has no entry yet is put where its number belongs. An insertion in the
!!! middle moves the entries above it up one place, which is the shift `vector`
!!! makes in insertAt; a caller that writes its text line by line only ever appends.
void pp_src_put -> @LineSrc map, int line, str file, int src_line {
    int at = pp_src_find(map, line);
    if at >= 0 {
        @str files = map.files;
        @int srcs = map.srcs;
        files[at] = file;
        srcs[at] = src_line;
        end;
    }
    !!! Where the line belongs: before the first entry greater than it. The middle
    !!! is a shift, as in pp_src_find above.
    @int lines = map.lines;
    int lo = 0;
    int hi = map.len;
    while lo < hi {
        int mid = (lo + hi) >> 1;
        if lines[mid] < line {
            lo = mid + 1;
        } else {
            hi = mid;
        }
    }
    if map.len >= map.cap {
        pp_src_grow(map);
    }
    lines = map.lines;
    @str files2 = map.files;
    @int srcs2 = map.srcs;
    int k = map.len;
    while k > lo {
        lines[k] = lines[k - 1];
        files2[k] = files2[k - 1];
        srcs2[k] = srcs2[k - 1];
        k = k - 1;
    }
    lines[lo] = line;
    files2[lo] = file;
    srcs2[lo] = src_line;
    map.len = map.len + 1;
}

!!! Put a (file, line) in the source map, replacing what stood at that line. This
!!! is the map of the file being walked (`pp_map`), which every pass over a file
!!! writes once per line of its output.
void pp_map_put -> int line, str file, int src_line {
    pp_src_put(pp_map, line, file, src_line);
}

!!! Put a line back in the source map of a map the pass is building.
void pp_map_set -> @LineSrc map, int line, str file, int src_line {
    pp_src_put(map, line, file, src_line);
}

@RepPos pp_rep_add -> @RepPos head, int off, @ReplaceInfo info {
    RepPos proto;
    @RepPos n;
    malloc(@n, size proto);
    n.off = off;
    n.info = info;
    n.next = head;
    return n;
}

!!! Whether the character at `i` is one an identifier continues with: the toolchain
!!! replacement test uses `isalnum(c) || c == '_'`.
bool pp_word_char -> str s, int i {
    char c = s[i];
    if c >= '0' && c <= '9' {
        return true;
    }
    if c >= 'a' && c <= 'z' {
        return true;
    }
    if c >= 'A' && c <= 'Z' {
        return true;
    }
    return c == '_';
}

!!! Whether `needle` stands at `pos` in `src`.
bool pp_starts -> str src, int pos, str needle {
    int i = 0;
    while needle[i] != (char)0 {
        if src[pos + i] != needle[i] {
            return false;
        }
        i = i + 1;
    }
    return true;
}

!!! The offset of `needle` in `src` at or after `from`, or -1. `n` is the length of
!!! `src`, which the caller already knows: measuring it here means walking the whole
!!! text on every call, and the walks below ask once per line, so a pass over a file
!!! becomes quadratic in its size. the `src.find(needle, from)` reads
!!! `str::size()` for free, and this is this implementation standing in for it.
!!!
!!! A needle of one character - the "\n" every line walk looks for - is answered by
!!! a plain scan. Going through `pp_starts` costs a call per position, so a pass over
!!! a megabyte of text paid a million calls to look for one character.
int pp_find_from_n -> str src, int n, str needle, int from {
    char c0 = needle[0];
    if c0 != (char)0 && needle[1] == (char)0 {
        int j = from;
        if j < 0 {
            j = 0;
        }
        while j < n {
            if src[j] == c0 {
                return j;
            }
            j = j + 1;
        }
        return -1;
    }
    int m = pe_len(needle);
    int i = from;
    while i + m <= n {
        if pp_starts(src, i, needle) {
            return i;
        }
        i = i + 1;
    }
    return -1;
}

!!! The same search with the text measured here, for a caller that has no length of
!!! its own. A walk that asks once per line wants pp_find_from_n instead.
int pp_find_from -> str src, str needle, int from {
    return pp_find_from_n(src, pe_len(src), needle, from);
}

!!! One `#replace`: every whole occurrence of `from` becomes `to`. The position of
!!! each occurrence is remembered (the offset in the result, the line and column
!!! where the name stood, and the line as it was written before), so a diagnostic
!!! inside the replaced text is reported at the name.
!!!
!!! `pp_reps` is the table of directives and `pp_rep_map` the result; both are
!!! fields because a pass answers the text it built and nothing else.
str preprocess_replaces -> str src, str filename, @ReplaceInfo reps {
    pp_rep_map = null;
    if reps == null {
        return src;
    }
    !!! The text is built in a growing buffer: `result = result + part` on a `str`
    !!! copies the whole output again per append, which is quadratic (see text_buf.b).
    @TextBuf result = tx_new();
    int pos = 0;
    int n = pe_len(src);
    int line = 1;
    int col = 1;
    int line_start = 0;
    while pos < n {
        bool matched = false;
        @ReplaceInfo rp = reps;
        while rp != null {
            str from = rp.from;
            int fl = pe_len(from);
            if pos + fl <= n && pp_starts(src, pos, from) {
                !!! The occurrence has to be a word of its own: what stands before and
                !!! after it may not be a character an identifier continues with. The
                !!! test is `!isalnum(c) || c == '_'`, so an `_` beside the name
                !!! counts as a boundary and a letter or a digit does not.
                bool ok_before = true;
                if pos > 0 && pp_alnum_char(src, pos - 1) {
                    ok_before = false;
                }
                bool ok_after = true;
                if pos + fl < n && pp_alnum_char(src, pos + fl) {
                    ok_after = false;
                }
                if ok_before && ok_after {
                    @ReplaceInfo occ = pp_copy_replace(rp);
                    occ.line_from = line;
                    occ.col_from = col;
                    int le = pp_find_from_n(src, n, "\n", line_start);
                    if le < 0 {
                        le = n;
                    }
                    str sl = pe_sub(src, line_start, le - line_start);
                    occ.src_line_from = pp_trim_eol(sl);
                    pp_rep_map = pp_rep_add(pp_rep_map, result.len, occ);
                    tx_add(result, rp.to);
                    pos = pos + fl;
                    col = col + fl;
                    matched = true;
                    skip;
                }
            }
            rp = rp.next;
        }
        if !matched {
            char ch = src[pos];
            tx_add(result, pe_char(ch));
            pos = pos + 1;
            if ch == '\n' {
                line = line + 1;
                col = 1;
                line_start = pos;
            } else {
                col = col + 1;
            }
        }
    }
    return tx_text(result);
}

!!! The replacement positions of the text the last preprocess_replaces built.
@RepPos pp_rep_map;

!!! A line without its ending, which is what the note under a diagnostic shows.
str pp_trim_eol -> str s {
    int n = pe_len(s);
    while n > 0 && (s[n - 1] == '\r' || s[n - 1] == '\n') {
        n = n - 1;
    }
    return pe_sub(s, 0, n);
}

!!! `#newline` (a line of its own) and `"#newline"` (anywhere in a line) stand for
!!! a line break where a line break cannot be written. `##newline` is the escape
!!! for the word itself, so `"##newline"` is the text `#newline` and not a break.
!!!
!!! The marker becomes '\n', so the text after it starts a new line; a marker alone
!!! on its line only empties that line, the way the other directives leave theirs.
!!! The source map gains an entry for every line the pass adds, and the offsets of
!!! the replacement positions are shifted by what the pass inserts.
str preprocess_newlines -> str src, str filename, @LineSrc source_map {
    !!! The three spellings this pass looks for cannot be written down as literals:
    !!! a source that holds one is exactly what the pass rewrites, quotes and all.
    !!! They are built from their pieces instead, so this file survives its own pass.
    str hash = "#";
    str quoted = char_text(34) + hash + "newline" + char_text(34);
    str bare = hash + "newline";
    str escaped = hash + hash + "newline";
    if pp_find_from(src, bare, 0) < 0 {
        !!! Nothing to rewrite. the toolchain takes the two maps by reference and returns
        !!! here without touching them, so what the passes above built is what its
        !!! caller goes on using; here they are answered back, because the caller
        !!! reads pp_new_map for the map of the text this pass handed it.
        pp_new_map = source_map;
        pp_new_rep = pp_rep_map;
        return src;
    }
    !!! The three things the pass builds live in fields while it runs (see pp_emit):
    !!! the text, the moved replacement positions and the new source map.
    pp_emit_out = "";
    pp_emit_rep = null;
    pp_emit_map = pp_src_new();
    pp_emit_out_line = 1;
    int in_line = 1;
    int in_off = 0;
    int n = pe_len(src);
    !!! One mark: where it stands, how long it is, and whether it is the escaped
    !!! spelling (which keeps the word where it stands).
    @IntNode marks = null;
    @IntNode mark_lens = null;
    @BoolNode mark_lit = null;
    while in_off < n {
        int line_end = pp_find_from_n(src, n, "\n", in_off);
        if line_end < 0 {
            line_end = n;
        }
        !!! The (file, line) this preprocessed line came from, which the map holds
        !!! for the lines the text before this pass stood on; a line it says
        !!! nothing about is a line of the file being compiled.
        int sof_at = pp_src_find(source_map, in_line);
        str sof_file = filename;
        int sof_line = in_line;
        if sof_at >= 0 {
            @str sof_files = source_map.files;
            @int sof_srcs = source_map.srcs;
            sof_file = sof_files[sof_at];
            sof_line = sof_srcs[sof_at];
        }
        marks = null;
        mark_lens = null;
        mark_lit = null;
        int at = in_off;
        while at < line_end {
            int q = pp_find_from_n(src, n, quoted, at);
            int b = pp_find_from_n(src, n, bare, at);
            int e = pp_find_from_n(src, n, escaped, at);
            if q >= 0 && q + pe_len(quoted) > line_end {
                q = -1;
            }
            if b >= 0 && b + pe_len(bare) > line_end {
                b = -1;
            }
            if e >= 0 && e + pe_len(escaped) > line_end {
                e = -1;
            }
            int m = -1;
            if q >= 0 {
                m = q;
            }
            if b >= 0 && (m < 0 || b < m) {
                m = b;
            }
            if e >= 0 && (m < 0 || e < m) {
                m = e;
            }
            if m < 0 {
                skip;
            }
            int len = pe_len(escaped);
            if m == q {
                len = pe_len(quoted);
            } else if m == b {
                len = pe_len(bare);
            }
            bool literal = (m == e);
            !!! The bare and the escaped spelling have to be the whole word:
            !!! `#newlines` is not a marker and neither is `##newlines`.
            if m != q && m + len < line_end && pp_word_char(src, m + len) {
                at = m + len;
                continue;
            }
            marks = p_chain_int(marks, p_new_int(m));
            mark_lens = p_chain_int(mark_lens, p_new_int(len));
            mark_lit = p_chain_bool(mark_lit, p_new_bool(literal));
            at = m + len;
        }
        !!! A marker alone on its line (with blank space around it) only empties it.
        !!! The escaped spelling is never such a marker: it is text, not a break.
        bool whole_line = false;
        if marks != null && marks.next == null {
            int only = marks.v;
            int only_len = mark_lens.v;
            bool blank_before = true;
            bool blank_after = true;
            int i = in_off;
            while i < only {
                if src[i] != ' ' && src[i] != '\t' && src[i] != '\r' {
                    blank_before = false;
                    skip;
                }
                i = i + 1;
            }
            int j = only + only_len;
            while j < line_end {
                if src[j] != ' ' && src[j] != '\t' && src[j] != '\r' {
                    blank_after = false;
                    skip;
                }
                j = j + 1;
            }
            if !mark_lit.v {
                whole_line = blank_before && blank_after;
            }
        }
        if marks == null || whole_line {
            if whole_line {
                pp_emit(src, in_off, marks.v, sof_file, sof_line, false);
                pp_emit(src, marks.v + mark_lens.v, line_end, sof_file, sof_line, true);
            } else {
                pp_emit(src, in_off, line_end, sof_file, sof_line, true);
            }
        } else {
            int pos = in_off;
            @IntNode mk = marks;
            @IntNode ml = mark_lens;
            @BoolNode mbool = mark_lit;
            while mk != null {
                if mbool.v {
                    !!! The escaped spelling keeps the word and breaks nothing: the
                    !!! escape's first `#` is dropped, so `"##newline"` stays one
                    !!! string whose text is `#newline`.
                    pp_emit(src, pos, mk.v, sof_file, sof_line, false);
                    pp_emit(src, mk.v + 1, mk.v + ml.v, sof_file, sof_line, false);
                    pos = mk.v + ml.v;
                } else {
                    pp_emit(src, pos, mk.v, sof_file, sof_line, true);
                    pos = mk.v + ml.v;
                }
                mk = mk.next;
                ml = ml.next;
                mbool = mbool.next;
            }
            pp_emit(src, pos, line_end, sof_file, sof_line, true);
        }
        in_off = line_end;
        if in_off < n && src[in_off] == '\n' {
            in_off = in_off + 1;
        } else if in_off < n && src[in_off] == '\r' {
            in_off = in_off + 1;
            if in_off < n && src[in_off] == '\n' {
                in_off = in_off + 1;
            }
        }
        in_line = in_line + 1;
    }
    !!! Anything left is past the last line the source has.
    @RepPos rest = pp_rep_map;
    while rest != null {
        if rest.off >= n {
            pp_emit_rep = pp_rep_add(pp_emit_rep, pe_len(pp_emit_out) + (rest.off - n), rest.info);
        }
        rest = rest.next;
    }
    pp_new_rep = pp_emit_rep;
    pp_new_map = pp_emit_map;
    return pp_emit_out;
}

!!! What the last preprocess_newlines pass built on the side, because a function
!!! answers one value: the shifted replacement positions and the source map.
@RepPos pp_new_rep;
@LineSrc pp_new_map;

!!! ---- small text helpers ----

!!! The text without the blanks at either end, which is what a directive argument
!!! is read as.
str pp_trim -> str s {
    int b = 0;
    int e = pe_len(s);
    while b < e && (s[b] == ' ' || s[b] == '\t' || s[b] == '\r') {
        b = b + 1;
    }
    while e > b && (s[e - 1] == ' ' || s[e - 1] == '\t' || s[e - 1] == '\r') {
        e = e - 1;
    }
    return pe_sub(s, b, e - b);
}

!!! The version the last pp_required_version read, packed the way
!!! blang_version_packed packs it.
longlong pp_req_value;

!!! `#require 1.1` / `#require 1.1.0` / `#require 10100`: the version a source needs,
!!! packed the way blang_version_packed packs it.
bool pp_required_version -> str a {
    pp_req_value = 0;
    if a == "" {
        return false;
    }
    if pe_find(a, '.') < 0 {
        p_parse_int(a);
        if !p_parse_int_ok || p_parse_int_value <= 0 {
            return false;
        }
        pp_req_value = p_parse_int_value;
        return true;
    }
    int parts0 = 0;
    int parts1 = 0;
    int parts2 = 0;
    int n = 0;
    int i = 0;
    int alen = pe_len(a);
    while i < alen && n < 3 {
        int dot = pp_find_from(a, ".", i);
        int stop = alen;
        if dot >= 0 {
            stop = dot;
        }
        str num = pe_sub(a, i, stop - i);
        if num == "" {
            return false;
        }
        int k = 0;
        while num[k] != (char)0 {
            if num[k] < '0' || num[k] > '9' {
                return false;
            }
            k = k + 1;
        }
        p_parse_int(num);
        if n == 0 {
            parts0 = (int)p_parse_int_value;
        } else if n == 1 {
            parts1 = (int)p_parse_int_value;
        } else {
            parts2 = (int)p_parse_int_value;
        }
        n = n + 1;
        if dot < 0 {
            skip;
        }
        i = dot + 1;
    }
    if n == 0 {
        return false;
    }
    pp_req_value = blang_version_packed(parts0, parts1, parts2);
    return true;
}

!!! A version written back as `1.1.0`, for the message of a version that is too old.
str pp_version_text -> longlong v {
    return (str)(v / 10000) + "." + (str)((v / 100) % 100) + "." + (str)(v % 100);
}

!!! The text inside a value that is written as a quoted string, with its escapes
!!! read; a value that is not quoted is taken as it stands.
str pp_unquote -> str t {
    int n = pe_len(t);
    if n < 2 || t[0] != '"' || t[n - 1] != '"' {
        return t;
    }
    str out = "";
    int i = 1;
    while i + 1 < n {
        if t[i] == '\\' && i + 2 < n {
            char c = t[i + 1];
            if c == 'n' {
                out = out + "\n";
            } else if c == 't' {
                out = out + "\t";
            } else if c == 'r' {
                out = out + "\r";
            } else {
                out = out + char_text(c);
            }
            i = i + 2;
            continue;
        }
        out = out + char_text(t[i]);
        i = i + 1;
    }
    return out;
}

!!! Whether `name` was taken back by a -U.
bool pp_env_undef -> @PreprocEnv env, str name {
    @NameList u = env.undefs;
    while u != null {
        if pe_eq(name, u.name) {
            return true;
        }
        u = u.next;
    }
    return false;
}

!!! Whether the character at `i` may start a name.
bool pp_alpha_char -> str s, int i {
    char c = s[i];
    if c >= 'a' && c <= 'z' {
        return true;
    }
    if c >= 'A' && c <= 'Z' {
        return true;
    }
    return c == '_';
}

!!! Whether the character at `i` is a letter or a digit. This is `isalnum`, which
!!! is not the same test as pp_word_char: a `_` is a word character but not an
!!! alphanumeric one, and the replacement pass treats the two differently.
bool pp_alnum_char -> str s, int i {
    char c = s[i];
    if c >= '0' && c <= '9' {
        return true;
    }
    if c >= 'a' && c <= 'z' {
        return true;
    }
    return c >= 'A' && c <= 'Z';
}

!!! ---- the `#if` expression language ----
!!!
!!! One condition is read by a cursor over its text, the way the toolchain CondEval reads
!!! it: the value is left in pp_c_out, the message of a failure in pp_c_err, and the
!!! descent below mirrors the toolchain methods one for one (`value`, `unary`, `mul`,
!!! `add`, `shift`, `relational`, `equality`, the three bit levels, `and_expr`,
!!! `or_expr`). The cursor and the table it reads live in fields because the
!!! language has no object to carry them, and because a #replace body is read by a
!!! nested call that saves and restores them.

str pp_c_s;              !!! the condition being read
int pp_c_i;              !!! the cursor
str pp_c_err;            !!! "" while the text is fine
bool pp_c_quiet;         !!! reading the side of a `&&` that is already false
@ReplaceInfo pp_c_reps;  !!! the #replace table as far as the walk has come
@PreprocEnv pp_c_env;
int pp_c_depth;          !!! a body that names another macro
longlong pp_c_out;       !!! the value of the piece just read
str pp_c_name;           !!! the name the last pp_c_ident read
str pp_c_txt;            !!! the text the last pp_c_str_operand read
str pp_c_arg;            !!! what the last parenthesized form held

!!! The levels of the descent call each other in a cycle, so their declarations
!!! stand in preprocessor_heads.b, which this file reads first.

void pp_c_skip_ws {
    str s = pp_c_s;
    int n = pe_len(s);
    while pp_c_i < n && (s[pp_c_i] == ' ' || s[pp_c_i] == '\t' || s[pp_c_i] == '\r') {
        pp_c_i = pp_c_i + 1;
    }
}

!!! Read one operator or punctuation text at the cursor, if it stands there.
bool pp_c_eat -> str op {
    pp_c_skip_ws();
    str s = pp_c_s;
    if pe_matches(s, pp_c_i, op) {
        pp_c_i = pp_c_i + pe_len(op);
        return true;
    }
    return false;
}

!!! Read one name. The text lands in pp_c_name.
bool pp_c_ident {
    pp_c_skip_ws();
    str s = pp_c_s;
    int n = pe_len(s);
    int b = pp_c_i;
    if pp_c_i < n && pp_alpha_char(s, pp_c_i) {
        while pp_c_i < n && pp_word_char(s, pp_c_i) {
            pp_c_i = pp_c_i + 1;
        }
        pp_c_name = pe_sub(s, b, pp_c_i - b);
        return true;
    }
    return false;
}

!!! The text inside the parentheses of `defined(...)` or `built_in(...)`, with the
!!! quotes or angle brackets that may surround it taken off. The text lands in
!!! pp_c_arg.
bool pp_c_parenthesized {
    pp_c_skip_ws();
    str s = pp_c_s;
    int n = pe_len(s);
    if pp_c_i >= n || s[pp_c_i] != '(' {
        return false;
    }
    pp_c_i = pp_c_i + 1;
    pp_c_skip_ws();
    int b = pp_c_i;
    if pp_c_i < n && (s[pp_c_i] == '"' || s[pp_c_i] == '<') {
        char close = '"';
        if s[pp_c_i] == '<' {
            close = '>';
        }
        pp_c_i = pp_c_i + 1;
        b = pp_c_i;
        while pp_c_i < n && s[pp_c_i] != close {
            pp_c_i = pp_c_i + 1;
        }
        pp_c_arg = pe_sub(s, b, pp_c_i - b);
        if pp_c_i < n {
            pp_c_i = pp_c_i + 1;
        }
    } else {
        while pp_c_i < n && s[pp_c_i] != ')' {
            pp_c_i = pp_c_i + 1;
        }
        pp_c_arg = pp_trim(pe_sub(s, b, pp_c_i - b));
    }
    pp_c_skip_ws();
    if pp_c_i < n && s[pp_c_i] == ')' {
        pp_c_i = pp_c_i + 1;
        return true;
    }
    return false;
}

!!! Is `name` a #replace macro this compile has read? A name -U took back is not
!!! one, whatever defined it.
bool pp_c_has_macro -> str name {
    if pp_c_reps == null || pp_env_undef(pp_c_env, name) {
        return false;
    }
    @ReplaceInfo ri = pp_c_reps;
    while ri != null {
        if pe_eq(ri.from, name) {
            return true;
        }
        ri = ri.next;
    }
    return false;
}

!!! The value of a #replace macro: its body read as a condition (and that body may
!!! name another macro). The last definition wins, which is what reading the file
!!! top to bottom means.
bool pp_c_macro_value -> str name {
    if pp_c_reps == null || pp_env_undef(pp_c_env, name) {
        return false;
    }
    @ReplaceInfo found = null;
    @ReplaceInfo ri = pp_c_reps;
    while ri != null {
        if pe_eq(ri.from, name) {
            found = ri;
        }
        ri = ri.next;
    }
    if found == null {
        return false;
    }
    str text = pp_trim(found.to);
    if text == "" {
        !!! `#replace NAME` with no body is 1.
        pp_c_out = 1;
        return true;
    }
    if pp_c_depth > 8 {
        pp_c_err = "the #replace table nests too deeply at '" + name + "'";
        return false;
    }
    !!! The body is read by the same machinery, so its state is put aside and put
    !!! back: the cursor, the message, the quiet flag and the depth.
    str save_s = pp_c_s;
    int save_i = pp_c_i;
    str save_err = pp_c_err;
    bool save_quiet = pp_c_quiet;
    int save_depth = pp_c_depth;
    pp_c_s = text;
    pp_c_i = 0;
    pp_c_err = "";
    pp_c_depth = save_depth + 1;
    bool ok = pp_c_or_expr();
    longlong v = pp_c_out;
    bool whole = false;
    if ok {
        pp_c_skip_ws();
        whole = pp_c_i >= pe_len(pp_c_s);
    }
    pp_c_s = save_s;
    pp_c_i = save_i;
    pp_c_err = save_err;
    pp_c_quiet = save_quiet;
    pp_c_depth = save_depth;
    if whole {
        pp_c_out = v;
        return true;
    }
    if save_quiet {
        pp_c_out = 0;
        return true;
    }
    pp_c_err = "'" + name + "' is a #replace macro whose body is not a number: '" + text + "'";
    return false;
}

!!! One side of `str_eq`/`str_ne`: a string literal, a -D value or a #replace body.
!!! The text lands in pp_c_txt.
bool pp_c_str_operand {
    pp_c_skip_ws();
    str s = pp_c_s;
    int n = pe_len(s);
    if pp_c_i < n && s[pp_c_i] == '"' {
        pp_c_i = pp_c_i + 1;
        str out = "";
        while pp_c_i < n && s[pp_c_i] != '"' {
            if s[pp_c_i] == '\\' && pp_c_i + 1 < n {
                char c = s[pp_c_i + 1];
                if c == 'n' {
                    out = out + "\n";
                } else if c == 't' {
                    out = out + "\t";
                } else if c == 'r' {
                    out = out + "\r";
                } else {
                    out = out + char_text(c);
                }
                pp_c_i = pp_c_i + 2;
                continue;
            }
            out = out + char_text(s[pp_c_i]);
            pp_c_i = pp_c_i + 1;
        }
        if pp_c_i >= n {
            pp_c_err = "unterminated string in a condition";
            return false;
        }
        pp_c_i = pp_c_i + 1;
        pp_c_txt = out;
        return true;
    }
    if !pp_c_ident() {
        pp_c_err = "str_eq/str_ne compare a string or a name";
        return false;
    }
    str name = pp_c_name;
    @NameVal d = pp_c_env.defines;
    while d != null {
        if pe_eq(d.name, name) && !pp_env_undef(pp_c_env, name) {
            pp_c_txt = pp_unquote(d.value);
            return true;
        }
        d = d.next;
    }
    if pp_c_has_macro(name) {
        @ReplaceInfo found = null;
        @ReplaceInfo ri = pp_c_reps;
        while ri != null {
            if pe_eq(ri.from, name) {
                found = ri;
            }
            ri = ri.next;
        }
        if found != null {
            pp_c_txt = pp_unquote(pp_trim(found.to));
        } else {
            pp_c_txt = "";
        }
        return true;
    }
    if pp_c_quiet {
        pp_c_txt = "";
        return true;
    }
    pp_c_err = "unknown name '" + name + "' in a condition; a -D name is asked with defined(" + name +
               "), a compiler condition with built_in(" + name + ")";
    return false;
}

!!! The value of one operand: a number, a parenthesized condition, a name.
bool pp_c_value {
    if pp_c_err != "" {
        return false;
    }
    pp_c_skip_ws();
    str s = pp_c_s;
    int n = pe_len(s);
    if pp_c_i >= n {
        pp_c_err = "a condition ends before its value";
        return false;
    }
    if s[pp_c_i] == '(' {
        pp_c_i = pp_c_i + 1;
        if !pp_c_or_expr() {
            return false;
        }
        pp_c_skip_ws();
        if pp_c_i >= n || s[pp_c_i] != ')' {
            pp_c_err = "missing ')' in a condition";
            return false;
        }
        pp_c_i = pp_c_i + 1;
        return true;
    }
    if s[pp_c_i] >= '0' && s[pp_c_i] <= '9' {
        longlong v = 0;
        if s[pp_c_i] == '0' && pp_c_i + 1 < n && (s[pp_c_i + 1] == 'x' || s[pp_c_i + 1] == 'X') {
            pp_c_i = pp_c_i + 2;
            while pp_c_i < n {
                char c = s[pp_c_i];
                int d = -1;
                if c >= '0' && c <= '9' {
                    d = (int)c - 48;
                } else if c >= 'a' && c <= 'f' {
                    d = (int)c - 87;
                } else if c >= 'A' && c <= 'F' {
                    d = (int)c - 55;
                }
                if d < 0 {
                    skip;
                }
                v = v * 16 + d;
                pp_c_i = pp_c_i + 1;
            }
            pp_c_out = v;
            return true;
        }
        while pp_c_i < n && s[pp_c_i] >= '0' && s[pp_c_i] <= '9' {
            v = v * 10 + ((int)s[pp_c_i] - 48);
            pp_c_i = pp_c_i + 1;
        }
        pp_c_out = v;
        return true;
    }
    if !pp_c_ident() {
        pp_c_err = "cannot read the condition at '" + pe_sub(s, pp_c_i, 8) + "'";
        return false;
    }
    str name = pp_c_name;
    if pe_eq(name, "str_eq") || pe_eq(name, "str_ne") {
        !!! The one way to branch on text: str_eq(A, B) compares a string literal, a
        !!! -D value or a #replace body. Both sides are read as text, so
        !!! `#if str_eq(PLATFORM, "win")` works and so does
        !!! `#if str_ne(NAME_OF_TARGET, "debug")`.
        pp_c_skip_ws();
        if pp_c_i >= n || s[pp_c_i] != '(' {
            pp_c_err = name + "(A, B) needs parentheses";
            return false;
        }
        pp_c_i = pp_c_i + 1;
        if !pp_c_str_operand() {
            return false;
        }
        str a = pp_c_txt;
        pp_c_skip_ws();
        if pp_c_i >= n || s[pp_c_i] != ',' {
            pp_c_err = name + "(A, B) needs two values";
            return false;
        }
        pp_c_i = pp_c_i + 1;
        if !pp_c_str_operand() {
            return false;
        }
        str b = pp_c_txt;
        pp_c_skip_ws();
        if pp_c_i >= n || s[pp_c_i] != ')' {
            pp_c_err = name + "(A, B) needs a closing ')'";
            return false;
        }
        pp_c_i = pp_c_i + 1;
        bool eq = pe_eq(a, b);
        if pe_eq(name, "str_eq") {
            if eq { pp_c_out = 1; } else { pp_c_out = 0; }
        } else {
            if eq { pp_c_out = 0; } else { pp_c_out = 1; }
        }
        return true;
    }
    if pe_eq(name, "defined") || pe_eq(name, "built_in") || pe_eq(name, "linked") {
        if !pp_c_parenthesized() {
            pp_c_err = name + "(...) needs parentheses";
            return false;
        }
        str arg = pp_c_arg;
        if pe_eq(arg, "") {
            pp_c_err = name + "(...) needs a name";
            return false;
        }
        if pe_eq(name, "defined") {
            if pe_find(arg, '(') >= 0 || pe_find(arg, ')') >= 0 {
                if pp_c_quiet {
                    pp_c_out = 0;
                    return true;
                }
                pp_c_err = "defined(...) takes one name; a compiler condition is asked with built_in(NAME)";
                return false;
            }
            env_builtin(pp_c_env, arg);
            if env_builtin_found {
                if pp_c_quiet {
                    pp_c_out = 0;
                    return true;
                }
                pp_c_err = "defined(" + arg + ") is false for a built-in condition; ask it with built_in(" + arg + ")";
                return false;
            }
            if env_defined(pp_c_env, arg) || pp_c_has_macro(arg) {
                pp_c_out = 1;
            } else {
                pp_c_out = 0;
            }
            return true;
        }
        if pe_eq(name, "built_in") {
            env_builtin(pp_c_env, arg);
            if env_builtin_found {
                pp_c_out = env_builtin_value;
                return true;
            }
            if pp_c_quiet {
                pp_c_out = 0;
                return true;
            }
            if env_defined(pp_c_env, arg) {
                pp_c_err = "'" + arg + "' is a -D name; ask it with defined(" + arg + ") or use it as a value";
                return false;
            }
            pp_c_err = "unknown built-in condition '" + arg + "'; there are: " + builtin_name_list();
            return false;
        }
        if env_is_linked(pp_c_env, arg) {
            pp_c_out = 1;
        } else {
            pp_c_out = 0;
        }
        return true;
    }
    if env_defined(pp_c_env, name) {
        longlong v = env_define_value(pp_c_env, name);
        if !env_is_number {
            if pp_c_quiet {
                pp_c_out = 0;
                return true;
            }
            pp_c_err = "'" + name + "' is defined but is not a number";
            return false;
        }
        pp_c_out = v;
        return true;
    }
    !!! A #replace macro defined above this line is a value too, so a condition can
    !!! talk about the macros the file has already set.
    if pp_c_macro_value(name) {
        return true;
    }
    if pp_c_err != "" {
        return false;
    }
    if pp_c_quiet {
        pp_c_out = 0;
        return true;
    }
    str what = builtin_what(name);
    if !pe_eq(what, "") {
        pp_c_err = "'" + name + "' is a built-in condition (" + what + "); ask it with built_in(" + name + ")";
        return false;
    }
    pp_c_err = "unknown name '" + name + "' in a condition; a -D name is asked with defined(" + name +
               "), a compiler condition with built_in(" + name + ")";
    return false;
}

bool pp_c_unary {
    if pp_c_eat("!") {
        if !pp_c_unary() {
            return false;
        }
        if pp_c_out != 0 {
            pp_c_out = 0;
        } else {
            pp_c_out = 1;
        }
        return true;
    }
    if pp_c_eat("~") {
        if !pp_c_unary() {
            return false;
        }
        pp_c_out = ~pp_c_out;
        return true;
    }
    if pp_c_eat("-") {
        if !pp_c_unary() {
            return false;
        }
        pp_c_out = 0 - pp_c_out;
        return true;
    }
    if pp_c_eat("+") {
        return pp_c_unary();
    }
    return pp_c_value();
}

bool pp_c_mul {
    if !pp_c_unary() {
        return false;
    }
    while true {
        pp_c_skip_ws();
        str s = pp_c_s;
        char c = (char)0;
        if pp_c_i < pe_len(s) {
            c = s[pp_c_i];
        }
        if c != '*' && c != '/' && c != '%' {
            return true;
        }
        pp_c_i = pp_c_i + 1;
        longlong left = pp_c_out;
        if !pp_c_unary() {
            return false;
        }
        longlong right = pp_c_out;
        if (c == '/' || c == '%') && right == 0 {
            if pp_c_quiet {
                pp_c_out = 0;
                return true;
            }
            pp_c_err = "division by zero in a condition";
            return false;
        }
        if c == '*' {
            pp_c_out = left * right;
        } else if c == '/' {
            pp_c_out = left / right;
        } else {
            pp_c_out = left % right;
        }
    }
    return true;
}

bool pp_c_add {
    if !pp_c_mul() {
        return false;
    }
    while true {
        pp_c_skip_ws();
        str s = pp_c_s;
        int n = pe_len(s);
        char c = (char)0;
        if pp_c_i < n {
            c = s[pp_c_i];
        }
        if c != '+' && c != '-' {
            return true;
        }
        !!! `a - -b` is a subtraction: the second `-` belongs to the operand.
        if c == '-' && pp_c_i + 1 < n && s[pp_c_i + 1] == '-' {
            return true;
        }
        pp_c_i = pp_c_i + 1;
        longlong left = pp_c_out;
        if !pp_c_mul() {
            return false;
        }
        longlong right = pp_c_out;
        if c == '+' {
            pp_c_out = left + right;
        } else {
            pp_c_out = left - right;
        }
    }
    return true;
}

!!! `<<` and `>>` sit between `+ -` and the comparisons, the place C gives them, so
!!! `a << 2` cannot be read as `a < (< 2)`.
bool pp_c_shift {
    if !pp_c_add() {
        return false;
    }
    while true {
        pp_c_skip_ws();
        str s = pp_c_s;
        int n = pe_len(s);
        bool left = false;
        bool right = false;
        if pp_c_i + 1 < n && s[pp_c_i] == '<' && s[pp_c_i + 1] == '<' {
            left = true;
        }
        if pp_c_i + 1 < n && s[pp_c_i] == '>' && s[pp_c_i + 1] == '>' {
            right = true;
        }
        if !left && !right {
            return true;
        }
        pp_c_i = pp_c_i + 2;
        longlong base = pp_c_out;
        if !pp_c_add() {
            return false;
        }
        longlong amount = pp_c_out;
        if amount < 0 || amount > 63 {
            if pp_c_quiet {
                pp_c_out = 0;
                return true;
            }
            pp_c_err = "a shift of more than 63 bits in a condition";
            return false;
        }
        if left {
            pp_c_out = (longlong)((utype longlong)base << amount);
        } else {
            pp_c_out = base >> amount;
        }
    }
    return true;
}

bool pp_c_relational {
    if !pp_c_shift() {
        return false;
    }
    while true {
        pp_c_skip_ws();
        longlong base = pp_c_out;
        if pp_c_eat("<=") {
            if !pp_c_shift() {
                return false;
            }
            if base <= pp_c_out { pp_c_out = 1; } else { pp_c_out = 0; }
        } else if pp_c_eat(">=") {
            if !pp_c_shift() {
                return false;
            }
            if base >= pp_c_out { pp_c_out = 1; } else { pp_c_out = 0; }
        } else if pp_c_eat("<") {
            if !pp_c_shift() {
                return false;
            }
            if base < pp_c_out { pp_c_out = 1; } else { pp_c_out = 0; }
        } else if pp_c_eat(">") {
            if !pp_c_shift() {
                return false;
            }
            if base > pp_c_out { pp_c_out = 1; } else { pp_c_out = 0; }
        } else {
            pp_c_out = base;
            return true;
        }
    }
    return true;
}

bool pp_c_equality {
    if !pp_c_relational() {
        return false;
    }
    while true {
        pp_c_skip_ws();
        longlong base = pp_c_out;
        if pp_c_eat("==") {
            if !pp_c_relational() {
                return false;
            }
            if base == pp_c_out { pp_c_out = 1; } else { pp_c_out = 0; }
        } else if pp_c_eat("!=") {
            if !pp_c_relational() {
                return false;
            }
            if base != pp_c_out { pp_c_out = 1; } else { pp_c_out = 0; }
        } else {
            pp_c_out = base;
            return true;
        }
    }
    return true;
}

!!! A single `&` must not swallow `&&` (nor `|` a `||`): the doubled forms are the
!!! logical operators and are left for pp_c_and_expr/pp_c_or_expr.
bool pp_c_eat_bit -> char c, char doubled {
    pp_c_skip_ws();
    str s = pp_c_s;
    int n = pe_len(s);
    if pp_c_i < n && s[pp_c_i] == c && (pp_c_i + 1 >= n || s[pp_c_i + 1] != doubled) {
        pp_c_i = pp_c_i + 1;
        return true;
    }
    return false;
}

bool pp_c_bit_and {
    if !pp_c_equality() {
        return false;
    }
    while pp_c_eat_bit('&', '&') {
        longlong base = pp_c_out;
        if !pp_c_equality() {
            return false;
        }
        pp_c_out = base & pp_c_out;
    }
    return true;
}

bool pp_c_bit_xor {
    if !pp_c_bit_and() {
        return false;
    }
    while pp_c_eat_bit('^', '^') {
        longlong base = pp_c_out;
        if !pp_c_bit_and() {
            return false;
        }
        pp_c_out = base ^ pp_c_out;
    }
    return true;
}

bool pp_c_bit_or {
    if !pp_c_bit_xor() {
        return false;
    }
    while pp_c_eat_bit('|', '|') {
        longlong base = pp_c_out;
        if !pp_c_bit_xor() {
            return false;
        }
        pp_c_out = base | pp_c_out;
    }
    return true;
}

!!! The right-hand side of a `&&` that is already false (of a `||` already true) is
!!! still read, so the text parses, but nothing in it can be wrong: an unknown name
!!! over there is not reported. That is what makes
!!! `#if defined(NAME) && NAME == 7` work when NAME was never given.
bool pp_c_and_expr {
    if !pp_c_bit_or() {
        return false;
    }
    while true {
        pp_c_skip_ws();
        if !pp_c_eat("&&") {
            return true;
        }
        longlong left = pp_c_out;
        bool saved = pp_c_quiet;
        if left == 0 {
            pp_c_quiet = true;
        }
        bool ok = pp_c_bit_or();
        pp_c_quiet = saved;
        if !ok {
            return false;
        }
        longlong right = pp_c_out;
        if left != 0 && right != 0 { pp_c_out = 1; } else { pp_c_out = 0; }
    }
    return true;
}

bool pp_c_or_expr {
    if !pp_c_and_expr() {
        return false;
    }
    while true {
        pp_c_skip_ws();
        if !pp_c_eat("||") {
            return true;
        }
        longlong left = pp_c_out;
        bool saved = pp_c_quiet;
        if left != 0 {
            pp_c_quiet = true;
        }
        bool ok = pp_c_and_expr();
        pp_c_quiet = saved;
        if !ok {
            return false;
        }
        longlong right = pp_c_out;
        if left != 0 || right != 0 { pp_c_out = 1; } else { pp_c_out = 0; }
    }
    return true;
}

!!! One whole condition: the value is left in pp_c_out and the message of a failure
!!! in pp_c_err.
bool pp_eval_condition -> str expr, @PreprocEnv env, @ReplaceInfo reps {
    pp_c_s = expr;
    pp_c_i = 0;
    pp_c_err = "";
    pp_c_quiet = false;
    pp_c_reps = reps;
    pp_c_env = env;
    pp_c_depth = 0;
    pp_c_out = 0;
    if !pp_c_or_expr() {
        if pp_c_err == "" {
            pp_c_err = "cannot read the condition";
        }
        return false;
    }
    pp_c_skip_ws();
    if pp_c_i < pe_len(pp_c_s) {
        pp_c_err = "unexpected '" + pe_sub(pp_c_s, pp_c_i, 8) + "' after the condition";
        return false;
    }
    return true;
}

!!! The text `pp_emit` is building, the replacement positions it has moved so far,
!!! the source map it has written and the line the next output line gets. They are
!!! fields for the same reason the toolchain lambda captures them by reference: the
!!! helper is called many times and keeps building the same three things.
str pp_emit_out;
@RepPos pp_emit_rep;
@LineSrc pp_emit_map;
int pp_emit_out_line;

!!! Copy `[from, to)` of the source into the text being built, moving the
!!! replacement positions it contains; with `newline` a line break follows and the
!!! preprocessed line it starts is recorded against the source line it came from.
void pp_emit -> str src, int from, int to, str sof_file, int sof_line, bool newline {
    @RepPos r = pp_rep_map;
    while r != null {
        if r.off >= from && r.off < to {
            pp_emit_rep = pp_rep_add(pp_emit_rep, pe_len(pp_emit_out) + (r.off - from), r.info);
        }
        r = r.next;
    }
    pp_emit_out = pp_emit_out + pe_sub(src, from, to - from);
    if newline {
        pp_emit_out = pp_emit_out + "\n";
        pp_src_put(pp_emit_map, pp_emit_out_line, sof_file, sof_line);
        pp_emit_out_line = pp_emit_out_line + 1;
    }
}

!!! ---- the state the walk over the files keeps ----

!!! Options on the command line that reach the source: `#to <flags>`, one list.
@NameList pp_to_flags;

!!! The name of an export block being read, and what it holds so far, with where
!!! the `#export` line stood (a mismatched close points there).
str pp_capturing;
str pp_capture_buf;
int pp_capture_line;
int pp_capture_col;
int pp_capture_len;

!!! The `#export` blocks of the compile and the `function -> #to` flags of the
!!! modules read: both are a name and a text, so both are a chain of NameVal.
@NameVal pp_exports;
@NameVal pp_func_to_flags;

!!! The names already seen under `#once`, folded to one case and one separator.
@NameList pp_once_seen;

!!! The `#replace` directives read so far, in the order they were read: the first
!!! match is the one that rewrites a name and the last one is the body a condition
!!! sees, which is what reading a file top to bottom means.
@ReplaceInfo pp_reps;

!!! The error a pass stopped on, as `line:col:len:message`, and the warnings.
str pp_error;
@NameList pp_warnings;

!!! The source map being built: preprocessed line -> (file, line).
@LineSrc pp_map;

!!! The line of the preprocessed text the next line of output is.
int pp_cur_line;

@NameVal pp_nv_find -> @NameVal head, str name {
    @NameVal n = head;
    while n != null {
        if pe_eq(n.name, name) {
            return n;
        }
        n = n.next;
    }
    return null;
}

!!! Put a name and its text in a chain of NameVal: the text is replaced when the
!!! name is already there, which is what `exports[name] = content` does.
@NameVal pp_nv_set -> @NameVal head, str name, str value {
    @NameVal found = pp_nv_find(head, name);
    if found != null {
        found.value = value;
        return head;
    }
    NameVal proto;
    @NameVal n;
    malloc(@n, size proto);
    n.name = name;
    n.value = value;
    n.next = head;
    return n;
}

!!! Whether the name already stands in a chain of NameList.
bool pp_nl_has -> @NameList head, str name {
    @NameList n = head;
    while n != null {
        if pe_eq(n.name, name) {
            return true;
        }
        n = n.next;
    }
    return false;
}

!!! Append at the tail, so a chain of replacements stays in reading order.
@ReplaceInfo pp_rep_append -> @ReplaceInfo head, @ReplaceInfo node {
    if head == null {
        return node;
    }
    @ReplaceInfo t = head;
    while t.next != null {
        t = t.next;
    }
    t.next = node;
    return head;
}

!!! ---- the `#if` family, a line at a time ----
!!!
!!! One open conditional is a CondFrame, declared in preprocessor_heads.b with the
!!! rest of the pass's surface.

@CondFrame pp_cond_stack;
bool pp_cond_consumed;
str pp_word_arg;

!!! The frame on top decides: with no frame at all, everything is read.
bool pp_cond_active {
    if pp_cond_stack == null {
        return true;
    }
    return pp_cond_stack.active;
}

void pp_cond_push -> bool parent_active, bool active, bool taken, int line, str file {
    CondFrame proto;
    @CondFrame f;
    malloc(@f, size proto);
    f.parent_active = parent_active;
    f.active = active;
    f.taken = taken;
    f.seen_else = false;
    f.line = line;
    f.file = file;
    f.next = pp_cond_stack;
    pp_cond_stack = f;
}

void pp_cond_pop {
    if pp_cond_stack != null {
        pp_cond_stack = pp_cond_stack.next;
    }
}

!!! Push one frame on a stack of the pass's own: the prescan of the exports keeps
!!! its own, because it resolves the conditions before any `#replace` is read, and
!!! the walk below keeps the compile-wide one.
@CondFrame pp_pc_push -> @CondFrame st, bool parent_active, bool active, bool taken, int line {
    CondFrame proto;
    @CondFrame f;
    malloc(@f, size proto);
    f.parent_active = parent_active;
    f.active = active;
    f.taken = taken;
    f.seen_else = false;
    f.line = line;
    f.file = "";
    f.next = st;
    return f;
}

void pp_cond_fail -> int src_line, int col, int hl, str msg {
    pp_error = (str)src_line + ":" + (str)col + ":" + (str)hl + ":" + msg;
}

!!! Whether the directive word `w` stands at `b`, with the blank or `(` that has to
!!! follow it, and its argument read into pp_word_arg.
bool pp_word_is -> str src, int b, int text_end, str w {
    int n = pe_len(w);
    if b + n > text_end || !pe_matches(src, b, w) {
        return false;
    }
    if b + n < text_end {
        char c = src[b + n];
        if c != ' ' && c != '\t' && c != '\r' && c != '(' {
            return false;
        }
    }
    pp_word_arg = pp_trim(pe_sub(src, b + n, text_end - (b + n)));
    return true;
}

!!! One line of the `#if` family, as the walk over a file reads it: `ds` is where
!!! the `#` stands, `text_end` the end of the line without its ending, `col` the
!!! column the `#` stands at and `src_line` the line it is on. True comes back when
!!! the line was such a directive (pp_cond_consumed is then true: the line leaves
!!! nothing behind but its line break) and false when it is some other directive.
!!! The condition is only evaluated when its answer is still needed - a branch that
!!! was not taken is never examined, so an unknown name inside one is not an error.
bool pp_cond_line -> str src, int ds, int text_end, int col, str filename, int src_line, @PreprocEnv env {
    pp_cond_consumed = false;
    int b = ds + 1;
    int we = b;
    while we < text_end && pp_alpha_char(src, we) {
        we = we + 1;
    }
    int hl = we - ds;
    str arg = "";
    if pp_word_is(src, b, text_end, "if") || pp_word_is(src, b, text_end, "ifdef") ||
       pp_word_is(src, b, text_end, "ifndef") {
        arg = pp_word_arg;
        pp_cond_consumed = true;
        bool is_if = pe_matches(src, b, "if") &&
                     (b + 2 == text_end || src[b + 2] == ' ' || src[b + 2] == '\t' ||
                      src[b + 2] == '\r' || src[b + 2] == '(');
        if !pp_cond_active() {
            !!! Nothing in a branch that was not taken is evaluated, so an unknown
            !!! name over there is not an error.
            pp_cond_push(false, false, true, src_line, filename);
        } else if is_if {
            if pe_eq(arg, "") {
                pp_cond_fail(src_line, col, hl, "#if needs a condition");
                return true;
            }
            if !pp_eval_condition(arg, env, pp_reps) {
                pp_cond_fail(src_line, col, hl, pp_c_err);
                return true;
            }
            bool v = false;
            if pp_c_out != 0 {
                v = true;
            }
            pp_cond_push(true, v, v, src_line, filename);
        } else {
            if pe_eq(arg, "") {
                pp_cond_fail(src_line, col, hl, "#ifdef needs a name");
                return true;
            }
            if pe_find(arg, '(') >= 0 || pe_find(arg, ' ') >= 0 {
                pp_cond_fail(src_line, col, hl,
                             "#ifdef and #ifndef take one name; a compiler condition is asked with #if built_in(NAME)");
                return true;
            }
            str what = builtin_what(arg);
            if !pe_eq(what, "") {
                pp_cond_fail(src_line, col, hl, "'" + arg + "' is a built-in condition (" + what +
                             "); ask it with #if built_in(" + arg + ")");
                return true;
            }
            bool d = env_defined(env, arg);
            if !d && !pp_env_undef(env, arg) {
                @ReplaceInfo ri = pp_reps;
                while ri != null {
                    if pe_eq(ri.from, arg) {
                        d = true;
                        skip;
                    }
                    ri = ri.next;
                }
            }
            bool vb = d;
            if !pe_matches(src, b, "ifdef") {
                vb = !d;
            }
            pp_cond_push(true, vb, vb, src_line, filename);
        }
        return true;
    }
    if pp_word_is(src, b, text_end, "elif") {
        arg = pp_word_arg;
        pp_cond_consumed = true;
        if pp_cond_stack == null {
            pp_cond_fail(src_line, col, hl, "#elif without #if");
            return true;
        }
        @CondFrame ef = pp_cond_stack;
        if ef.seen_else {
            pp_cond_fail(src_line, col, hl, "#elif after #else");
            return true;
        }
        if !ef.parent_active || ef.taken {
            ef.active = false;
        } else {
            if pe_eq(arg, "") {
                pp_cond_fail(src_line, col, hl, "#elif needs a condition");
                return true;
            }
            if !pp_eval_condition(arg, env, pp_reps) {
                pp_cond_fail(src_line, col, hl, pp_c_err);
                return true;
            }
            bool v3 = false;
            if pp_c_out != 0 {
                v3 = true;
            }
            ef.active = v3;
            if v3 {
                ef.taken = true;
            }
        }
        return true;
    }
    if pp_word_is(src, b, text_end, "else") {
        arg = pp_word_arg;
        pp_cond_consumed = true;
        if pp_cond_stack == null {
            pp_cond_fail(src_line, col, hl, "#else without #if");
            return true;
        }
        @CondFrame lf = pp_cond_stack;
        if lf.seen_else {
            pp_cond_fail(src_line, col, hl, "#else after #else");
            return true;
        }
        if !pe_eq(arg, "") {
            pp_cond_fail(src_line, col, hl, "nothing may follow #else");
            return true;
        }
        lf.seen_else = true;
        bool on = lf.parent_active && !lf.taken;
        lf.active = on;
        if on {
            lf.taken = true;
        }
        return true;
    }
    if pp_word_is(src, b, text_end, "endif") {
        arg = pp_word_arg;
        pp_cond_consumed = true;
        if pp_cond_stack == null {
            pp_cond_fail(src_line, col, hl, "#endif without #if");
            return true;
        }
        if !pe_eq(arg, "") {
            pp_cond_fail(src_line, col, hl, "nothing may follow #endif");
            return true;
        }
        pp_cond_pop();
        return true;
    }
    if pp_word_is(src, b, text_end, "require") {
        arg = pp_word_arg;
        pp_cond_consumed = true;
        if pp_cond_active() {
            if !pp_required_version(arg) {
                pp_cond_fail(src_line, col, hl, "#require needs a version, like #require 1.1 or #require 10100");
                return true;
            }
            longlong need = pp_req_value;
            env_builtin(env, "COMPILER_VERSION");
            longlong have = env_builtin_value;
            if have < need {
                pp_cond_fail(src_line, col, hl, "this source needs blang " + pp_version_text(need) +
                             " or newer, and this compiler is " + pp_version_text(have));
            }
        }
        return true;
    }
    return false;
}

!!! The message for an `#if` that was never closed, reported once the whole walk is
!!! over: it can be left open across a `#head` boundary, so no single file can tell.
str pp_unclosed_message -> @CondFrame st {
    if st == null {
        return "";
    }
    str f = st.file;
    return (str)st.line + ":1:4:#if on line " + (str)st.line + " of " + f + " has no #endif";
}

!!! Remove the comments from a source before anything else reads it: an `!!!` line
!!! becomes blanks, a `!~ ... ~!` block becomes blanks with its line breaks kept,
!!! and a string or character literal is copied through, escapes and all, so a `!`
!!! or a `~` inside one is not a comment.
str pp_strip_comments -> str src {
    !!! Built in a growing buffer: appending one character at a time to a `str`
    !!! copies the whole text again per character, which is quadratic over a whole
    !!! source file (see text_buf.b).
    @TextBuf out = tx_new();
    int i = 0;
    int n = pe_len(src);
    while i < n {
        char c = src[i];
        if c == '"' {
            tx_add(out, "\"");
            i = i + 1;
            while i < n {
                tx_add_ch(out, src[i]);
                if src[i] == '\\' && i + 1 < n {
                    tx_add_ch(out, src[i + 1]);
                    i = i + 2;
                    continue;
                }
                if src[i] == '"' || src[i] == '\n' {
                    i = i + 1;
                    skip;
                }
                i = i + 1;
            }
            continue;
        }
        if c == (char)39 {
            tx_add(out, "'");
            i = i + 1;
            while i < n {
                tx_add_ch(out, src[i]);
                if src[i] == '\\' && i + 1 < n {
                    tx_add_ch(out, src[i + 1]);
                    i = i + 2;
                    continue;
                }
                if src[i] == (char)39 || src[i] == '\n' {
                    i = i + 1;
                    skip;
                }
                i = i + 1;
            }
            continue;
        }
        if c == '!' && i + 2 < n && src[i + 1] == '!' && src[i + 2] == '!' {
            while i < n && src[i] != '\n' {
                tx_add(out, " ");
                i = i + 1;
            }
            continue;
        }
        if c == '!' && i + 1 < n && src[i + 1] == '~' {
            tx_add(out, "  ");
            i = i + 2;
            while i < n {
                if src[i] == '~' && i + 1 < n && src[i + 1] == '!' {
                    tx_add(out, "  ");
                    i = i + 2;
                    skip;
                }
                if src[i] == '\n' {
                    tx_add(out, "\n");
                } else {
                    tx_add(out, " ");
                }
                i = i + 1;
            }
            continue;
        }
        tx_add_ch(out, c);
        i = i + 1;
    }
    return tx_text(out);
}

!!! Collect the `#export *NAME ... #export *NAME` blocks of a source, so `#import`
!!! can resolve a name written after the line that imports it. The text of a block
!!! ends with a line break, and the first block of a name is the one that counts.
void pp_prescan_exports -> str src {
    int n = pe_len(src);
    int pos = 0;
    while pos < n {
        int line_start = pos;
        while line_start < n && (src[line_start] == ' ' || src[line_start] == '\t') {
            line_start = line_start + 1;
        }
        int line_end = pp_find_from_n(src, n, "\n", line_start);
        if line_end < 0 {
            line_end = n;
        }
        if line_start < n && src[line_start] == '#' && pe_matches(src, line_start, "#export ") {
            int nstart = line_start + 8;
            while nstart < line_end && src[nstart] == ' ' {
                nstart = nstart + 1;
            }
            int nend = line_end;
            while nend > nstart && (src[nend - 1] == '\r' || src[nend - 1] == ' ') {
                nend = nend - 1;
            }
            str name = pe_sub(src, nstart, nend - nstart);
            if name != "" && src[nstart] == '*' {
                str closing = "#export " + name;
                int search_pos = line_end + 1;
                bool found_closing = false;
                while search_pos < n {
                    int nl = pp_find_from_n(src, n, "\n", search_pos);
                    if nl < 0 {
                        nl = n;
                    }
                    int ls = search_pos;
                    while ls < nl && (src[ls] == ' ' || src[ls] == '\t') {
                        ls = ls + 1;
                    }
                    if ls < nl && src[ls] == '#' && pe_matches(src, ls, closing) {
                        int content_start = line_end + 1;
                        int content_end = ls;
                        while content_end > content_start && src[content_end - 1] != '\n' {
                            content_end = content_end - 1;
                        }
                        str content = pp_trim_eol(pe_sub(src, content_start, content_end - content_start));
                        if content != "" {
                            content = content + "\n";
                        }
                        if pp_nv_find(pp_exports, name) == null {
                            pp_exports = pp_nv_set(pp_exports, name, content);
                        }
                        found_closing = true;
                        skip;
                    }
                    search_pos = nl + 1;
                }
                !!! With no closing #export the block reaches the end of the file.
                if !found_closing && pp_nv_find(pp_exports, name) == null {
                    int cs = line_end + 1;
                    if cs < n {
                        str content2 = pp_trim_eol(pe_sub_to_end(src, cs));
                        if content2 != "" {
                            content2 = content2 + "\n";
                        }
                        pp_exports = pp_nv_set(pp_exports, name, content2);
                    }
                }
            }
            pos = line_end;
            if pos < n && src[pos] == '\n' {
                pos = pos + 1;
            }
        } else {
            pos = line_end;
            if pos < n && src[pos] == '\n' {
                pos = pos + 1;
            }
        }
    }
}

!!! The files being read right now, so a `#head` that comes back to a file already
!!! open is reported instead of looping forever.
@NameList pp_visited;

!!! The environment of the compile: the -D and -U names, the built-in facts, the
!!! -P directories and the linked DLLs.
@PreprocEnv pp_env;

!!! The directory the driver resolved BLANG_HOME to, and the path a header was
!!! actually found at (a name is tried with `.b` appended, so the two differ).
str pp_home;
str pp_actual_path;

!!! Whether a name stands in a chain, and the chain without it.
@NameList pp_nl_remove -> @NameList head, str name {
    if head == null {
        return null;
    }
    if pe_eq(head.name, name) {
        return head.next;
    }
    @NameList n = head;
    while n.next != null {
        if pe_eq(n.next.name, name) {
            n.next = n.next.next;
            return head;
        }
        n = n.next;
    }
    return head;
}

!!! Append at the tail, so warnings come out in the order the files were read.
@NameList pp_nl_append -> @NameList head, str name {
    NameList proto;
    @NameList node;
    malloc(@node, size proto);
    node.name = name;
    node.next = null;
    if head == null {
        return node;
    }
    @NameList t = head;
    while t.next != null {
        t = t.next;
    }
    t.next = node;
    return head;
}

!!! The key a file is remembered under for `#once`: the same file named with either
!!! separator and in either case on Windows is one file, so the path is cleaned and
!!! then folded.
str pp_once_key -> str p {
    str c = preprocess_clean_path(p);
    str out = "";
    int i = 0;
    while c[i] != (char)0 {
        char ch = c[i];
        if ch == '/' {
            ch = '\\';
        }
        if ch >= 'A' && ch <= 'Z' {
            ch = (char)((int)ch + 32);
        }
        out = out + char_text(ch);
        i = i + 1;
    }
    return out;
}

!!! Whether `cand` or `cand.b` can be opened. The path it was found at is left in
!!! pp_actual_path and the handle is the answer, or null.
@void pp_try_open -> str cand {
    @void f = getFile(cand, "rb");
    if f != null {
        pp_actual_path = cand;
        return f;
    }
    str alt = cand + ".b";
    f = getFile(alt, "rb");
    if f != null {
        pp_actual_path = alt;
        return f;
    }
    return null;
}


!!! Second pass over the import lines: an `#import [*A, *B]` whose block the first
!!! walk did not have yet - a block written below the line that imports it - is
!!! expanded now that every `#export` of the compile has been read. `inject_into_body`
!!! is what -I mode asks for: the `#to` line of a stubbed function goes into the
!!! body, next to the declaration, instead of to the top of the file.
str expand_imports_pass2 -> str src, bool inject_into_body {
    !!! The text is built in a growing buffer: `result = result + part` on a `str`
    !!! copies the whole output again per append, which is quadratic (see text_buf.b).
    @TextBuf result = tx_new();
    @LineSrc new_src_map = pp_src_new();
    int in_line = 1;
    int out_line = 1;
    int pos = 0;
    int n = pe_len(src);
    while pos < n {
        int line_start = pos;
        while line_start < n && (src[line_start] == ' ' || src[line_start] == '\t') {
            line_start = line_start + 1;
        }
        int line_end = pp_find_from_n(src, n, "\n", pos);
        if line_end < 0 {
            line_end = n;
        }
        if line_start < n && src[line_start] == '#' && pe_matches(src, line_start, "#import ") {
            str indent = pe_sub(src, pos, line_start - pos);
            int expanded_line_count = 0;
            int bstart = line_start + 8;
            while bstart < line_end && src[bstart] == ' ' {
                bstart = bstart + 1;
            }
            if bstart < line_end && src[bstart] == '[' {
                int bend = pp_find_from_n(src, n, "]", bstart);
                if bend >= 0 && bend < line_end {
                    str list = pe_sub(src, bstart + 1, bend - bstart - 1);
                    str expanded = "";
                    int lp = 0;
                    while lp < pe_len(list) {
                        while lp < pe_len(list) && (list[lp] == ' ' || list[lp] == ',') {
                            lp = lp + 1;
                        }
                        int le = lp;
                        while le < pe_len(list) && list[le] != ' ' && list[le] != ',' {
                            le = le + 1;
                        }
                        if le > lp {
                            str iname = pe_sub(list, lp, le - lp);
                            @NameVal eit = pp_nv_find(pp_exports, iname);
                            if eit != null && eit.value != "" {
                                str exp_content = eit.value;
                                !!! To compile, the `#to` of every stubbed function of
                                !!! the block is collected as a line of its own at the
                                !!! top of the expansion.
                                str top_to_lines = "";
                                if !inject_into_body {
                                    int ts = 0;
                                    int en = pe_len(exp_content);
                                    while ts < en {
                                        int fn = pp_find_from_n(exp_content, en, "function ", ts);
                                        if fn < 0 {
                                            skip;
                                        }
                                        int brace = pp_find_from_n(exp_content, en, "{", fn);
                                        if brace < 0 {
                                            skip;
                                        }
                                        int p = fn + 9;
                                        while p < brace && exp_content[p] == ' ' {
                                            p = p + 1;
                                        }
                                        while p < brace && exp_content[p] != ' ' && exp_content[p] != '\t' &&
                                              exp_content[p] != '\n' && exp_content[p] != '{' {
                                            p = p + 1;
                                        }
                                        while p < brace && (exp_content[p] == ' ' || exp_content[p] == '\t') {
                                            p = p + 1;
                                        }
                                        int ns = p;
                                        while p < brace && exp_content[p] != ' ' && exp_content[p] != '\t' &&
                                              exp_content[p] != '\n' && exp_content[p] != '(' && exp_content[p] != '{' {
                                            p = p + 1;
                                        }
                                        str fname = pe_sub(exp_content, ns, p - ns);
                                        @NameVal fit = pp_nv_find(pp_func_to_flags, fname);
                                        if fit != null {
                                            top_to_lines = top_to_lines + "#to " + fit.value + "\n";
                                        }
                                        ts = brace + 1;
                                    }
                                }
                                !!! Every function head of the block is copied, and the
                                !!! `#to` of a stub goes into the body right after its `{`.
                                int scan = 0;
                                int en2 = pe_len(exp_content);
                                while scan < en2 {
                                    int fnk = pp_find_from_n(exp_content, en2, "function ", scan);
                                    if fnk < 0 {
                                        expanded = expanded + pe_sub_to_end(exp_content, scan);
                                        skip;
                                    }
                                    int append_start = scan;
                                    int exlen = pe_len(expanded);
                                    if exlen > 0 && expanded[exlen - 1] == '\n' {
                                        while append_start < fnk && (exp_content[append_start] == ' ' ||
                                                                     exp_content[append_start] == '\t') {
                                            append_start = append_start + 1;
                                        }
                                    }
                                    expanded = expanded + pe_sub(exp_content, append_start, fnk - append_start);
                                    int brace2 = pp_find_from_n(exp_content, en2, "{", fnk);
                                    if brace2 < 0 {
                                        expanded = expanded + pe_sub_to_end(exp_content, fnk);
                                        skip;
                                    }
                                    int p2 = fnk + 9;
                                    while p2 < brace2 && exp_content[p2] == ' ' {
                                        p2 = p2 + 1;
                                    }
                                    while p2 < brace2 && exp_content[p2] != ' ' && exp_content[p2] != '\t' &&
                                          exp_content[p2] != '\n' && exp_content[p2] != '{' {
                                        p2 = p2 + 1;
                                    }
                                    while p2 < brace2 && (exp_content[p2] == ' ' || exp_content[p2] == '\t') {
                                        p2 = p2 + 1;
                                    }
                                    int ns2 = p2;
                                    while p2 < brace2 && exp_content[p2] != ' ' && exp_content[p2] != '\t' &&
                                          exp_content[p2] != '\n' && exp_content[p2] != '(' && exp_content[p2] != '{' {
                                        p2 = p2 + 1;
                                    }
                                    str fname2 = pe_sub(exp_content, ns2, p2 - ns2);
                                    expanded = expanded + pe_sub(exp_content, fnk, brace2 - fnk + 1);
                                    if inject_into_body {
                                        @NameVal fit2 = pp_nv_find(pp_func_to_flags, fname2);
                                        if fit2 != null {
                                            expanded = expanded + "\n    #to " + fit2.value + "\n";
                                        }
                                    }
                                    scan = brace2 + 1;
                                }
                                int explen = pe_len(exp_content);
                                if explen > 0 && exp_content[explen - 1] != '\n' {
                                    expanded = expanded + "\n";
                                }
                                tx_add(result, top_to_lines);
                                int k = 0;
                                int ttl = pe_len(top_to_lines);
                                while k < ttl {
                                    if top_to_lines[k] == '\n' {
                                        expanded_line_count = expanded_line_count + 1;
                                    }
                                    k = k + 1;
                                }
                            }
                        }
                        lp = le;
                    }
                    !!! Every line of the expansion is written with the indentation of
                    !!! the `#import` line it stands for, so a block imported inside a
                    !!! namespace stays inside it.
                    int elp = 0;
                    int en3 = pe_len(expanded);
                    while elp < en3 {
                        int ele = pp_find_from_n(expanded, en3, "\n", elp);
                        if ele < 0 {
                            ele = en3;
                        }
                        if ele > elp {
                            str seg = pe_sub(expanded, elp, ele - elp);
                            str clean = "";
                            int r = 0;
                            int seg_n = pe_len(seg);
                            while r < seg_n {
                                if seg[r] != '\r' {
                                    clean = clean + char_text(seg[r]);
                                }
                                r = r + 1;
                            }
                            tx_add(result, indent);
                        tx_add(result, clean);
                        tx_add(result, "\n");
                            expanded_line_count = expanded_line_count + 1;
                        }
                        elp = ele;
                        if elp < en3 && expanded[elp] == '\n' {
                            elp = elp + 1;
                        } else if elp < en3 && expanded[elp] == '\r' {
                            elp = elp + 1;
                            if elp < en3 && expanded[elp] == '\n' {
                                elp = elp + 1;
                            }
                        }
                    }
                }
            }
            !!! The `#import` line is gone, and the lines it made carry no entry of
            !!! their own: only what came before it keeps its (file, line). the toolchain
            !!! walks its whole map here and keeps the entries below the line; the
            !!! map is in ascending line order, so an index reaches them.
            @int ml = pp_map.lines;
            @str mf = pp_map.files;
            @int ms = pp_map.srcs;
            int mi = 0;
            while mi < pp_map.len {
                if ml[mi] < in_line {
                    pp_map_set(new_src_map, ml[mi], mf[mi], ms[mi]);
                }
                mi = mi + 1;
            }
            in_line = in_line + 1;
            out_line = out_line + expanded_line_count;
        } else {
            tx_add(result, pe_sub(src, pos, line_end - pos));
            if line_end < n {
                tx_add(result, "\n");
            }
            !!! The entry this input line has, `src_map->find(in_line)`: a lookup by
            !!! line, which is a binary search and not a walk of the map.
            int m2 = pp_src_find(pp_map, in_line);
            if m2 >= 0 {
                @str m2f = pp_map.files;
                @int m2s = pp_map.srcs;
                pp_map_set(new_src_map, out_line, m2f[m2], m2s[m2]);
            }
            in_line = in_line + 1;
            out_line = out_line + 1;
        }
        pos = line_end;
        if pos < n && src[pos] == '\n' {
            pos = pos + 1;
        } else if pos < n && src[pos] == '\r' {
            pos = pos + 1;
            if pos < n && src[pos] == '\n' {
                pos = pos + 1;
            }
        }
    }
    pp_map = new_src_map;
    return tx_text(result);
}

!!! `#if` and its family resolved over a whole source, for the pass that collects
!!! the `#export` blocks before anything is expanded: a block inside a branch that
!!! was not taken must not be collected. This early pass has no `#replace` table to
!!! read, so a condition it cannot answer is not an error here - the caller keeps
!!! the unfiltered text and the walk below decides.
str preprocess_conditionals -> str src, @PreprocEnv env {
    @CondFrame st = null;
    !!! A growing buffer (see text_buf.b): the text is built a line at a time.
    @TextBuf out = tx_new();
    int pos = 0;
    int line = 1;
    int n = pe_len(src);
    while pos <= n {
        int line_end = pp_find_from_n(src, n, "\n", pos);
        bool has_nl = true;
        if line_end < 0 {
            has_nl = false;
            line_end = n;
        }
        int text_end = line_end;
        if text_end > pos && src[text_end - 1] == '\r' {
            text_end = text_end - 1;
        }
        int ds = pos;
        while ds < text_end && (src[ds] == ' ' || src[ds] == '\t') {
            ds = ds + 1;
        }
        bool consumed = false;
        if ds < text_end && src[ds] == '#' {
            int b = ds + 1;
            int we = b;
            while we < text_end && pp_alpha_char(src, we) {
                we = we + 1;
            }
            int col = (ds - pos) + 1;
            int hl = we - ds;
            str arg = "";
            if pp_word_is(src, b, text_end, "if") || pp_word_is(src, b, text_end, "ifdef") ||
               pp_word_is(src, b, text_end, "ifndef") {
                arg = pp_word_arg;
                consumed = true;
                bool is_if = pe_matches(src, b, "if") &&
                             (b + 2 == text_end || src[b + 2] == ' ' || src[b + 2] == '\t' ||
                              src[b + 2] == '\r' || src[b + 2] == '(');
                bool on = true;
                if st != null {
                    on = st.active;
                }
                if !on {
                    st = pp_pc_push(st, false, false, true, line);
                } else if is_if {
                    if pe_eq(arg, "") {
                        pp_cond_fail(line, col, hl, "#if needs a condition");
                        return "";
                    }
                    if !pp_eval_condition(arg, env, null) {
                        pp_cond_fail(line, col, hl, pp_c_err);
                        return "";
                    }
                    bool v = false;
                    if pp_c_out != 0 {
                        v = true;
                    }
                    st = pp_pc_push(st, true, v, v, line);
                } else {
                    if pe_eq(arg, "") {
                        pp_cond_fail(line, col, hl, "#ifdef needs a name");
                        return "";
                    }
                    if pe_find(arg, '(') >= 0 || pe_find(arg, ' ') >= 0 {
                        pp_cond_fail(line, col, hl,
                                     "#ifdef and #ifndef take one name; a compiler condition is asked with #if built_in(NAME)");
                        return "";
                    }
                    str what = builtin_what(arg);
                    if !pe_eq(what, "") {
                        pp_cond_fail(line, col, hl, "'" + arg + "' is a built-in condition (" + what +
                                     "); ask it with #if built_in(" + arg + ")");
                        return "";
                    }
                    bool d = env_defined(env, arg);
                    bool vb = d;
                    if !pe_matches(src, b, "ifdef") {
                        vb = !d;
                    }
                    st = pp_pc_push(st, true, vb, vb, line);
                }
            } else if pp_word_is(src, b, text_end, "elif") {
                arg = pp_word_arg;
                consumed = true;
                if st == null {
                    pp_cond_fail(line, col, hl, "#elif without #if");
                    return "";
                }
                if st.seen_else {
                    pp_cond_fail(line, col, hl, "#elif after #else");
                    return "";
                }
                if !st.parent_active || st.taken {
                    st.active = false;
                } else {
                    if pe_eq(arg, "") {
                        pp_cond_fail(line, col, hl, "#elif needs a condition");
                        return "";
                    }
                    if !pp_eval_condition(arg, env, null) {
                        pp_cond_fail(line, col, hl, pp_c_err);
                        return "";
                    }
                    bool v2 = false;
                    if pp_c_out != 0 {
                        v2 = true;
                    }
                    st.active = v2;
                    if v2 {
                        st.taken = true;
                    }
                }
            } else if pp_word_is(src, b, text_end, "else") {
                arg = pp_word_arg;
                consumed = true;
                if st == null {
                    pp_cond_fail(line, col, hl, "#else without #if");
                    return "";
                }
                if st.seen_else {
                    pp_cond_fail(line, col, hl, "#else after #else");
                    return "";
                }
                if !pe_eq(arg, "") {
                    pp_cond_fail(line, col, hl, "nothing may follow #else");
                    return "";
                }
                st.seen_else = true;
                bool on2 = st.parent_active && !st.taken;
                st.active = on2;
                if on2 {
                    st.taken = true;
                }
            } else if pp_word_is(src, b, text_end, "endif") {
                arg = pp_word_arg;
                consumed = true;
                if st == null {
                    pp_cond_fail(line, col, hl, "#endif without #if");
                    return "";
                }
                if !pe_eq(arg, "") {
                    pp_cond_fail(line, col, hl, "nothing may follow #endif");
                    return "";
                }
                st = st.next;
            } else if pp_word_is(src, b, text_end, "require") {
                arg = pp_word_arg;
                consumed = true;
                bool on3 = true;
                if st != null {
                    on3 = st.active;
                }
                if on3 {
                    if !pp_required_version(arg) {
                        pp_cond_fail(line, col, hl, "#require needs a version, like #require 1.1 or #require 10100");
                        return "";
                    }
                    longlong need = pp_req_value;
                    env_builtin(env, "COMPILER_VERSION");
                    longlong have = env_builtin_value;
                    if have < need {
                        pp_cond_fail(line, col, hl, "this source needs blang " + pp_version_text(need) +
                                     " or newer, and this compiler is " + pp_version_text(have));
                        return "";
                    }
                }
            }
        }
        bool keep = true;
        if st != null {
            keep = st.active;
        }
        if !consumed && keep {
            tx_add(out, pe_sub(src, pos, text_end - pos));
        }
        if has_nl {
            tx_add_ch(out, '\n');
        }
        if !has_nl {
            skip;
        }
        pos = line_end + 1;
        line = line + 1;
    }
    if st != null {
        pp_error = (str)st.line + ":1:4:#if on line " + (str)st.line + " has no #endif";
        return "";
    }
    return tx_text(out);
}

!!! The walk over one file. Every line is looked at: the directives that pull text
!!! in or take it out are answered here and what is left is what the tokenizer
!!! sees. `#if` is answered first, so a `#head` inside a branch that was not taken
!!! is never even opened. The maps and the `#to` list the walk fills live in the
!!! fields above, because the recursion hands the same ones down the levels, and
!!! only the line the output stands on is a local that comes back out at the end.
str preprocess_includes -> str src, str filename {
    !!! The files being read right now: a file that comes back to itself is told so
    !!! instead of read forever.
    if pp_nl_has(pp_visited, filename) {
        pp_error = "circular include: '" + filename + "'";
        return "";
    }
    pp_visited = p_namelist_add(pp_visited, filename);

    !!! `#once` at the top of a file means "read me the first time only": a module
    !!! that two other modules both include (the self-hosted front end is built that
    !!! way) would otherwise declare everything twice. Five characters, not six: the
    !!! first line is `#once` followed by the line ending, and comparing six would
    !!! compare the `\r` against nothing.
    bool has_once = pe_matches(src, 0, "#once") || pp_find_from(src, "\n#once", 0) >= 0;
    if has_once {
        str key = pp_once_key(filename);
        if pp_nl_has(pp_once_seen, key) {
            pp_visited = pp_nl_remove(pp_visited, filename);
            return "";
        }
        pp_once_seen = p_namelist_add(pp_once_seen, key);
    }

    !!! The comments go first, so the preprocessed text is comment-free, and the
    !!! `#if` family is answered inside the walk below a line at a time: that is what
    !!! lets a condition read the `#replace` table as far as the walk has come.
    src = pp_strip_comments(src);

    !!! The text is built in a growing buffer: `result = result + part` on a `str`
    !!! copies the whole output again per append, which is quadratic (see text_buf.b).
    @TextBuf result = tx_new();
    int pos = 0;
    int cur_out_line = pp_cur_line;
    int src_line = 1;
    int n = pe_len(src);
    while pos < n {
        int line_start = pos;
        while line_start < n && (src[line_start] == ' ' || src[line_start] == '\t') {
            line_start = line_start + 1;
        }
        int line_nl = pp_find_from_n(src, n, "\n", line_start);
        int text_end = n;
        if line_nl >= 0 {
            text_end = line_nl;
        }
        if text_end > line_start && src[text_end - 1] == '\r' {
            text_end = text_end - 1;
        }
        !!! The `#if` family comes before every other directive, and a line inside a
        !!! branch that was not taken is dropped whole, whatever it is: a `#head`
        !!! over there is never opened and a `#replace` over there is never
        !!! collected. What is dropped leaves an empty line behind - and its
        !!! (file, line) entry in the map - so every line number after it is still
        !!! the one the source wrote.
        bool consumed = false;
        if line_start < n && src[line_start] == '#' {
            if pe_matches(src, line_start, "#once") &&
               (line_start + 5 >= text_end || src[line_start + 5] == ' ' ||
                src[line_start + 5] == '\t' || src[line_start + 5] == '\r') {
                !!! `#once` was answered when the file was opened, so the line itself
                !!! is just taken out of the text.
                consumed = true;
            } else {
                pp_error = "";
                if pp_cond_line(src, line_start, text_end, (line_start - pos) + 1, filename,
                                src_line, pp_env) {
                    if pp_error != "" {
                        return "";
                    }
                }
                consumed = pp_cond_consumed;
            }
        }
        if consumed || !pp_cond_active() {
            if pp_capturing == "" && line_nl >= 0 {
                tx_add(result, "\n");
                pp_map_put(cur_out_line, filename, src_line);
                cur_out_line = cur_out_line + 1;
            }
            pos = n;
            if line_nl >= 0 {
                pos = line_nl + 1;
            }
            src_line = src_line + 1;
            continue;
        }
        bool is_hash = (line_start < n && src[line_start] == '#');
        if is_hash && pe_matches(src, line_start, "#error") {
            int line_end = pp_find_from_n(src, n, "\n", line_start);
            if line_end < 0 {
                line_end = n;
            }
            int msg_start = line_start + 6;
            while msg_start < line_end && (src[msg_start] == ' ' || src[msg_start] == '\t') {
                msg_start = msg_start + 1;
            }
            str errmsg = pp_trim_eol(pe_sub(src, msg_start, line_end - msg_start));
            pp_error = (str)src_line + ":" + (str)((line_start - pos) + 1) + ":" +
                       (str)(line_end - line_start) + ":" + errmsg;
            return "";
        }
        if is_hash && pe_matches(src, line_start, "#warning") {
            int line_end = pp_find_from_n(src, n, "\n", line_start);
            if line_end < 0 {
                line_end = n;
            }
            int msg_start = line_start + 8;
            while msg_start < line_end && (src[msg_start] == ' ' || src[msg_start] == '\t') {
                msg_start = msg_start + 1;
            }
            str warnmsg = pp_trim_eol(pe_sub(src, msg_start, line_end - msg_start));
            str shown = pp_trim_eol(pe_sub(src, pos, line_end - pos));
            pp_warnings = pp_nl_append(pp_warnings, filename + "\n" + (str)src_line + ":" +
                                       (str)((line_start - pos) + 1) + ":" +
                                       (str)(line_end - line_start) + ":" + warnmsg + "\n" + shown);
            pos = line_end;
            if pos < n && src[pos] == '\n' {
                pos = pos + 1;
                src_line = src_line + 1;
            }
            continue;
        }
        if is_hash && pe_matches(src, line_start, "#head ") {
            int line_end = pp_find_from_n(src, n, "\n", line_start);
            if line_end < 0 {
                line_end = n;
            }
            int qstart = line_start + 6;
            while qstart < line_end && src[qstart] == ' ' {
                qstart = qstart + 1;
            }
            char open_delim = (char)0;
            if qstart < line_end {
                open_delim = src[qstart];
            }
            char close_delim = '"';
            if open_delim == '<' {
                close_delim = '>';
            }
            if qstart >= line_end || (open_delim != '"' && open_delim != '<') {
                int le = line_end;
                if le < n && src[le] == '\n' {
                    le = le + 1;
                }
                tx_add(result, pe_sub(src, pos, le - pos));
                pp_map_put(cur_out_line, filename, src_line);
                int ci = pos;
                while ci < le {
                    if src[ci] == '\n' {
                        cur_out_line = cur_out_line + 1;
                        src_line = src_line + 1;
                    }
                    ci = ci + 1;
                }
                pos = le;
                continue;
            }
            int qend = qstart + 1;
            while qend < line_end && src[qend] != close_delim {
                qend = qend + 1;
            }
            if qend >= line_end || src[qend] != close_delim {
                int le2 = line_end;
                if le2 < n && src[le2] == '\n' {
                    le2 = le2 + 1;
                }
                tx_add(result, pe_sub(src, pos, le2 - pos));
                pp_map_put(cur_out_line, filename, src_line);
                int ci2 = pos;
                while ci2 < le2 {
                    if src[ci2] == '\n' {
                        cur_out_line = cur_out_line + 1;
                        src_line = src_line + 1;
                    }
                    ci2 = ci2 + 1;
                }
                pos = le2;
                continue;
            }
            str path = pe_sub(src, qstart + 1, qend - qstart - 1);
            str incl_path = "includes\\bl\\" + path;
            str actual_path = incl_path;
            @void f = null;
            bool opened = false;
            !!! A `-P<dir>` directory is looked in first, so a project can carry its
            !!! own copy of a header, or keep headers of its own in a directory the
            !!! standard one never sees.
            @NameList dirs = pp_env.inc_dirs;
            while dirs != null && !opened {
                str dir = dirs.name;
                if dir != "" {
                    int dl = pe_len(dir);
                    str cand = dir;
                    if dir[dl - 1] != '\\' && dir[dl - 1] != '/' {
                        cand = cand + "\\";
                    }
                    cand = cand + path;
                    f = pp_try_open(cand);
                    if f != null {
                        opened = true;
                        actual_path = pp_actual_path;
                    }
                }
                dirs = dirs.next;
            }
            !!! Then the two install layouts under BLANG_HOME: the exe next to
            !!! includes/, and the exe in bin/ with includes/ beside it.
            if !opened && pp_home != "" {
                f = pp_try_open(pp_home + "\\includes\\bl\\" + path);
                if f != null {
                    opened = true;
                    actual_path = pp_actual_path;
                }
                if !opened {
                    f = pp_try_open(pp_home + "\\..\\includes\\bl\\" + path);
                    if f != null {
                        opened = true;
                        actual_path = pp_actual_path;
                    }
                }
            }
            if !opened {
                f = pp_try_open(incl_path);
                if f != null {
                    opened = true;
                    actual_path = pp_actual_path;
                }
            }
            if !opened {
                f = pp_try_open(path);
                if f != null {
                    opened = true;
                    actual_path = pp_actual_path;
                }
            }
            actual_path = preprocess_clean_path(actual_path);
            if !opened || f == null {
                pp_error = (str)src_line + ":" + (str)((qstart - pos) + 1) + ":" +
                           (str)(qend - qstart + 1) + ":cannot open head file '" + path + "'";
                return "";
            }
            str content = readFile(@f, -1, -1);
            if content == null {
                pp_error = (str)src_line + ":" + (str)((qstart - pos) + 1) + ":" +
                           (str)(qend - qstart + 1) + ":cannot open head file '" + path + "'";
                return "";
            }
            tx_add(result, "\n");
            cur_out_line = cur_out_line + 1;
            pp_prescan_exports(content);
            !!! An export block of the included file must not end up in the block of
            !!! the file that includes it, so the capture in progress is put aside and
            !!! the one the included file leaves behind is folded into the table.
            str saved_capturing = pp_capturing;
            str saved_buf = pp_capture_buf;
            int saved_line = pp_capture_line;
            int saved_col = pp_capture_col;
            int saved_len = pp_capture_len;
            pp_capturing = "";
            pp_capture_buf = "";
            pp_capture_line = 0;
            pp_capture_col = 1;
            pp_capture_len = 0;
            !!! The included file's lines are numbered where the `#head` line stood, in
            !!! the same map: the toolchain hands its line counter to the recursive call by
            !!! reference, and pp_cur_line is what stands in for that reference here.
            !!! The call answers with the counter past the last line it wrote, so the
            !!! walk of this file goes on from there.
            pp_cur_line = cur_out_line;
            str included = preprocess_includes(content, actual_path);
            cur_out_line = pp_cur_line;
            if pp_error != "" {
                return "";
            }
            if pp_capturing != "" {
                if pp_capture_buf != "" {
                    str body = pp_trim_eol(pp_capture_buf);
                    if body != "" {
                        body = body + "\n";
                    }
                    pp_exports = pp_nv_set(pp_exports, pp_capturing, body);
                    pp_capturing = "";
                    pp_capture_buf = "";
                }
                if pp_capturing != "" {
                    pp_capture_buf = saved_buf;
                }
            } else {
                pp_capturing = saved_capturing;
                pp_capture_buf = saved_buf;
                pp_capture_line = saved_line;
                pp_capture_col = saved_col;
                pp_capture_len = saved_len;
            }
            tx_add(result, included);
            tx_add(result, "\n");
            cur_out_line = cur_out_line + 1;
            pos = line_end;
            if pos < n && src[pos] == '\n' {
                pos = pos + 1;
                src_line = src_line + 1;
            }
            continue;
        }
        if is_hash && pe_matches(src, line_start, "#replace ") {
            int line_end = pp_find_from_n(src, n, "\n", line_start);
            if line_end < 0 {
                line_end = n;
            }
            int rpos = line_start + 9;
            while rpos < line_end && src[rpos] == ' ' {
                rpos = rpos + 1;
            }
            int from_start = rpos;
            while rpos < line_end && src[rpos] != ' ' && src[rpos] != '\r' {
                rpos = rpos + 1;
            }
            str from = pe_sub(src, from_start, rpos - from_start);
            while rpos < line_end && src[rpos] == ' ' {
                rpos = rpos + 1;
            }
            int to_start = rpos;
            while rpos < line_end && src[rpos] != '\r' {
                rpos = rpos + 1;
            }
            str to = pe_sub(src, to_start, rpos - to_start);
            if from != "" {
                @ReplaceInfo ri = pp_new_replace(from, to, filename, src_line,
                                                 (to_start - line_start) + 1,
                                                 pp_trim_eol(pe_sub(src, line_start, line_end - line_start)));
                pp_reps = pp_rep_append(pp_reps, ri);
            }
            pos = line_end;
            if pos < n && src[pos] == '\n' {
                pos = pos + 1;
                src_line = src_line + 1;
            }
            continue;
        }
        if is_hash && pe_matches(src, line_start, "#to ") {
            int line_end = pp_find_from_n(src, n, "\n", line_start);
            if line_end < 0 {
                line_end = n;
            }
            if line_start == pos {
                int fstart = line_start + 4;
                while fstart < line_end && src[fstart] == ' ' {
                    fstart = fstart + 1;
                }
                int fend = line_end;
                while fend > fstart && (src[fend - 1] == '\r' || src[fend - 1] == ' ') {
                    fend = fend - 1;
                }
                if fend > fstart {
                    pp_to_flags = pp_nl_append(pp_to_flags, pe_sub(src, fstart, fend - fstart));
                }
            }
            if pp_capturing != "" {
                pp_capture_buf = pp_capture_buf + pe_sub(src, pos, line_end - pos) + "\n";
            }
            !!! An indented `#to` stands inside a function body: it is the stub flag of
            !!! that function, so the name of the function it belongs to is read back
            !!! from the text above it.
            if line_start != pos && pp_capturing == "" {
                int search = pos;
                while search > 0 {
                    search = search - 1;
                    if search + 8 < n && pe_matches(src, search, "function ") {
                        bool at_line_start = true;
                        int si = search;
                        while si > 0 {
                            si = si - 1;
                            if src[si] == '\n' {
                                skip;
                            }
                            if src[si] != ' ' && src[si] != '\t' {
                                at_line_start = false;
                                skip;
                            }
                        }
                        if at_line_start {
                            int p = search + 9;
                            while p < pos && src[p] == ' ' {
                                p = p + 1;
                            }
                            while p < pos && src[p] != ' ' && src[p] != '\t' && src[p] != '\n' &&
                                  src[p] != '{' {
                                p = p + 1;
                            }
                            while p < pos && (src[p] == ' ' || src[p] == '\t') {
                                p = p + 1;
                            }
                            int ns = p;
                            while p < pos && src[p] != ' ' && src[p] != '\t' && src[p] != '\n' &&
                                  src[p] != '(' && src[p] != '{' {
                                p = p + 1;
                            }
                            str fname = pe_sub(src, ns, p - ns);
                            if fname != "" {
                                int fs = line_start + 4;
                                while fs < line_end && src[fs] == ' ' {
                                    fs = fs + 1;
                                }
                                int fe = line_end;
                                while fe > fs && (src[fe - 1] == '\r' || src[fe - 1] == ' ') {
                                    fe = fe - 1;
                                }
                                pp_func_to_flags = pp_nv_set(pp_func_to_flags, fname,
                                                             pe_sub(src, fs, fe - fs));
                            }
                        }
                        skip;
                    }
                }
            }
            pos = line_end;
            if pos < n && src[pos] == '\n' {
                pos = pos + 1;
                src_line = src_line + 1;
            }
            continue;
        }
        if is_hash && pe_matches(src, line_start, "#export ") {
            int line_end = pp_find_from_n(src, n, "\n", line_start);
            if line_end < 0 {
                line_end = n;
            }
            int line_begin = line_start;
            while line_begin > 0 && src[line_begin - 1] != '\n' {
                line_begin = line_begin - 1;
            }
            int nstart = line_start + 8;
            while nstart < line_end && src[nstart] == ' ' {
                nstart = nstart + 1;
            }
            int nend = line_end;
            while nend > nstart && (src[nend - 1] == '\r' || src[nend - 1] == ' ') {
                nend = nend - 1;
            }
            str name = pe_sub(src, nstart, nend - nstart);
            if name == "" || src[nstart] != '*' {
                pp_error = (str)src_line + ":" + (str)((nstart - line_begin) + 1) +
                           ":0: #export name must start with '*'";
                return "";
            }
            if pp_capturing == "" {
                pp_capturing = name;
                pp_capture_line = src_line;
                pp_capture_col = (nstart - line_begin) + 1;
                pp_capture_len = pe_len(name);
                pp_capture_buf = "";
            } else if pe_eq(pp_capturing, name) {
                pp_exports = pp_nv_set(pp_exports, name, pp_capture_buf);
                pp_capturing = "";
                pp_capture_buf = "";
            } else {
                pp_error = (str)src_line + ":" + (str)((nstart - line_begin) + 1) + ":" +
                           (str)pe_len(name) + ": mismatched #export '" + name +
                           "', expecting '#export " + pp_capturing + "'";
                return "";
            }
            pos = line_end;
            if pos < n && src[pos] == '\n' {
                pos = pos + 1;
                src_line = src_line + 1;
            }
            continue;
        }
        if is_hash && pe_matches(src, line_start, "#import ") {
            int line_end = pp_find_from_n(src, n, "\n", line_start);
            if line_end < 0 {
                line_end = n;
            }
            int line_begin2 = line_start;
            while line_begin2 > 0 && src[line_begin2 - 1] != '\n' {
                line_begin2 = line_begin2 - 1;
            }
            int bstart = line_start + 8;
            while bstart < line_end && src[bstart] == ' ' {
                bstart = bstart + 1;
            }
            if bstart >= line_end || src[bstart] != '[' {
                pp_error = (str)src_line + ":" + (str)((bstart - line_begin2) + 1) +
                           ":0: #import missing '['";
                return "";
            }
            int bend = pp_find_from_n(src, n, "]", bstart);
            if bend < 0 || bend >= line_end {
                pp_error = (str)src_line + ":" + (str)((bstart - line_begin2) + 1) +
                           ":0: #import missing ']'";
                return "";
            }
            str list = pe_sub(src, bstart + 1, bend - bstart - 1);
            int lp = 0;
            int list_n = pe_len(list);
            bool any_expanded = false;
            while lp < list_n {
                while lp < list_n && (list[lp] == ' ' || list[lp] == ',') {
                    lp = lp + 1;
                }
                int le = lp;
                while le < list_n && list[le] != ' ' && list[le] != ',' {
                    le = le + 1;
                }
                if le > lp {
                    str iname = pe_sub(list, lp, le - lp);
                    if iname == "" || list[lp] != '*' {
                        pp_error = (str)src_line + ":" +
                                   (str)(bstart + 1 + lp - line_begin2 + 1) +
                                   ":0: #import name must start with '*'";
                        return "";
                    }
                    @NameVal eit = pp_nv_find(pp_exports, iname);
                    if eit != null && eit.value != "" {
                        any_expanded = true;
                        str exp_content = eit.value;
                        int fn_start = pp_find_from(exp_content, "function ", 0);
                        if fn_start >= 0 {
                            int fn_after = fn_start + 9;
                            int en = pe_len(exp_content);
                            while fn_after < en && exp_content[fn_after] != ' ' &&
                                  exp_content[fn_after] != '\n' {
                                fn_after = fn_after + 1;
                            }
                            while fn_after < en && exp_content[fn_after] == ' ' {
                                fn_after = fn_after + 1;
                            }
                            int fn_end = fn_after;
                            while fn_end < en && exp_content[fn_end] != ' ' && exp_content[fn_end] != '\n' &&
                                  exp_content[fn_end] != '(' && exp_content[fn_end] != '{' {
                                fn_end = fn_end + 1;
                            }
                            str func_name = pe_sub(exp_content, fn_after, fn_end - fn_after);
                            if func_name != "" {
                                !!! The stub of that function carries the `#to` flags the
                                !!! module asked for, and the flags are put at the top of
                                !!! the text so the driver sees them.
                                str func_pat = "function void " + func_name;
                                int sp = 0;
                                while sp < n {
                                    int fp = pp_find_from_n(src, n, func_pat, sp);
                                    if fp < 0 {
                                        skip;
                                    }
                                    int brace = pp_find_from_n(src, n, "{", fp);
                                    if brace < 0 {
                                        skip;
                                    }
                                    int depth = 1;
                                    int cb = brace + 1;
                                    while cb < n && depth > 0 {
                                        if src[cb] == '{' {
                                            depth = depth + 1;
                                        } else if src[cb] == '}' {
                                            depth = depth - 1;
                                        }
                                        cb = cb + 1;
                                    }
                                    int tp = pp_find_from_n(src, n, "#to ", brace);
                                    if tp >= 0 && tp < cb {
                                        int fs = tp + 4;
                                        while fs < cb && src[fs] == ' ' {
                                            fs = fs + 1;
                                        }
                                        int fe = fs;
                                        while fe < cb && src[fe] != '\n' && src[fe] != '\r' {
                                            fe = fe + 1;
                                        }
                                        if fe > fs {
                                            tx_add(result, "#to ");
                                            tx_add(result, pe_sub(src, fs, fe - fs));
                                            tx_add(result, "\n");
                                            cur_out_line = cur_out_line + 1;
                                        }
                                    }
                                    skip;
                                }
                            }
                        }
                        tx_add(result, eit.value);
                        !!! The text is taken into a local before it is walked: a str
                        !!! that is a *field* cannot be subscripted.
                        str ev = eit.value;
                        int k = 0;
                        int ev_n = pe_len(ev);
                        while k < ev_n {
                            if ev[k] == '\n' {
                                cur_out_line = cur_out_line + 1;
                            }
                            k = k + 1;
                        }
                        int evl = ev_n;
                        if evl > 0 && ev[evl - 1] != '\n' {
                            tx_add(result, "\n");
                            cur_out_line = cur_out_line + 1;
                        }
                    }
                }
                lp = le;
            }
            if !any_expanded {
                tx_add(result, pe_sub(src, pos, line_end - pos));
                pp_map_put(cur_out_line, filename, src_line);
                tx_add(result, "\n");
                cur_out_line = cur_out_line + 1;
            }
            pos = line_end;
            if pos < n && src[pos] == '\n' {
                pos = pos + 1;
                src_line = src_line + 1;
            }
            continue;
        }
        !!! Anything else is a line of the program.
        int le3 = pp_find_from_n(src, n, "\n", pos);
        if le3 < 0 {
            le3 = n;
        }
        if pp_capturing != "" {
            pp_capture_buf = pp_capture_buf + pe_sub(src, pos, le3 - pos) + "\n";
        } else {
            tx_add(result, pe_sub(src, pos, le3 - pos));
            pp_map_put(cur_out_line, filename, src_line);
        }
        pos = le3;
        if pos < n && src[pos] == '\n' {
            if pp_capturing != "" {
                pos = pos + 1;
                src_line = src_line + 1;
            } else {
                tx_add(result, "\n");
                cur_out_line = cur_out_line + 1;
                pos = pos + 1;
                src_line = src_line + 1;
            }
        }
    }
    pp_visited = pp_nl_remove(pp_visited, filename);
    pp_cur_line = cur_out_line;
    return tx_text(result);
}

!!! Collect the top-level `#to` lines of a fully preprocessed text: each one is a
!!! flag the driver needs and is taken out of the program, because it is not code.
str pp_collect_to -> str text {
    !!! A growing buffer (see text_buf.b): the text is built a line at a time.
    @TextBuf filtered = tx_new();
    int pp = 0;
    int n = pe_len(text);
    while pp < n {
        int le = pp_find_from_n(text, n, "\n", pp);
        if le < 0 {
            le = n;
        }
        if le - pp >= 4 && pe_matches(text, pp, "#to ") {
            int fs = pp + 4;
            while fs < le && text[fs] == ' ' {
                fs = fs + 1;
            }
            int fe = le;
            while fe > fs && (text[fe - 1] == '\r' || text[fe - 1] == ' ') {
                fe = fe - 1;
            }
            if fe > fs {
                pp_to_flags = pp_nl_append(pp_to_flags, pe_sub(text, fs, fe - fs));
            }
        } else {
            tx_add_span(filtered, text, pp, le);
            tx_add_ch(filtered, '\n');
        }
        pp = le;
        if pp < n && text[pp] == '\n' {
            pp = pp + 1;
        } else if pp < n && text[pp] == '\r' {
            pp = pp + 1;
            if pp < n && text[pp] == '\n' {
                pp = pp + 1;
            }
        }
    }
    return tx_text(filtered);
}

!!! The same walk for `-I`, where the `#to` lines are kept in the text: the option
!!! writes the source the tokenizer would read, and a `#to` line is part of what the
!!! reader of that text may want to see. The flags are collected the same way.
str pp_collect_to_keep -> str text {
    !!! A growing buffer (see text_buf.b): the text is built a line at a time.
    @TextBuf kept = tx_new();
    int pp = 0;
    int n = pe_len(text);
    while pp < n {
        int le = pp_find_from_n(text, n, "\n", pp);
        if le < 0 {
            le = n;
        }
        if le - pp >= 4 && pe_matches(text, pp, "#to ") {
            int fs = pp + 4;
            while fs < le && text[fs] == ' ' {
                fs = fs + 1;
            }
            int fe = le;
            while fe > fs && (text[fe - 1] == '\r' || text[fe - 1] == ' ') {
                fe = fe - 1;
            }
            if fe > fs {
                pp_to_flags = pp_nl_append(pp_to_flags, pe_sub(text, fs, fe - fs));
            }
        }
        !!! The newline stands between two lines, and a buffer that is still empty
        !!! has nothing to separate. That is the rule the toolchain post-pass of
        !!! rt_preprocess_b follows (`if (!filtered.empty()) filtered += '\n';`),
        !!! and it is what keeps the empty lines at the head of the text out of the
        !!! answer and leaves the answer without a newline at the end: adding one
        !!! after every line cost -I two bytes more than the toolchain writes.
        if kept.len > 0 {
            tx_add_ch(kept, '\n');
        }
        tx_add(kept, pe_sub(text, pp, le - pp));
        pp = le;
        if pp < n && text[pp] == '\n' {
            pp = pp + 1;
        } else if pp < n && text[pp] == '\r' {
            pp = pp + 1;
            if pp < n && text[pp] == '\n' {
                pp = pp + 1;
            }
        }
    }
    return tx_text(kept);
}

!!! The same for the text the second import pass produced: here the source map is
!!! rebuilt as well, because a line that leaves the text moves every entry after it.
str pp_collect_to_map -> str text {
    !!! A growing buffer (see text_buf.b): the text is built a line at a time.
    @TextBuf filtered = tx_new();
    @LineSrc new_map = pp_src_new();
    int pp = 0;
    int old_line = 1;
    int new_line = 1;
    int n = pe_len(text);
    while pp < n {
        int le = pp_find_from_n(text, n, "\n", pp);
        if le < 0 {
            le = n;
        }
        if le - pp >= 4 && pe_matches(text, pp, "#to ") {
            int fs = pp + 4;
            while fs < le && text[fs] == ' ' {
                fs = fs + 1;
            }
            int fe = le;
            while fe > fs && (text[fe - 1] == '\r' || text[fe - 1] == ' ') {
                fe = fe - 1;
            }
            if fe > fs {
                pp_to_flags = pp_nl_append(pp_to_flags, pe_sub(text, fs, fe - fs));
            }
        } else {
            tx_add_span(filtered, text, pp, le);
            tx_add_ch(filtered, '\n');
            !!! The entry this line has in the map the text stood on, by line rather
            !!! than by walking the map once per line.
            int m = pp_src_find(pp_map, old_line);
            if m >= 0 {
                @str mf = pp_map.files;
                @int ms = pp_map.srcs;
                pp_map_set(new_map, new_line, mf[m], ms[m]);
            }
            new_line = new_line + 1;
        }
        old_line = old_line + 1;
        pp = le;
        if pp < n && text[pp] == '\n' {
            pp = pp + 1;
        } else if pp < n && text[pp] == '\r' {
            pp = pp + 1;
            if pp < n && text[pp] == '\n' {
                pp = pp + 1;
            }
        }
    }
    pp_map = new_map;
    return tx_text(filtered);
}

!!! The preprocessed text of the compile, the map of its lines and whether the pass
!!! stopped. They are fields because a pass answers one value.
str pp_out;
bool pp_run_error;

!!! The whole preprocessor for one source: the prescan of the `#export` blocks, the
!!! walk over the files and their `#head`s, the imports the walk could not answer
!!! yet, the `#to` flags, the replacements and finally the newline markers - the
!!! order the driver calls them in, and the reason the last pass sees the line
!!! numbers every earlier one moved.
str preprocess_source -> str src, str filename, @PreprocEnv env {
    pp_out = "";
    pp_run_error = false;
    pp_error = "";
    pp_warnings = null;
    pp_to_flags = null;
    pp_map = pp_src_new();
    pp_cur_line = 1;
    pp_reps = null;
    pp_cond_stack = null;
    pp_visited = null;
    pp_capturing = "";
    pp_capture_buf = "";
    pp_capture_line = 0;
    pp_capture_col = 1;
    pp_capture_len = 0;
    pp_env = env;

    !!! The exports are collected before anything is expanded, so `#import` can
    !!! resolve a forward reference. The conditionals are resolved here only to keep
    !!! a block inside a branch that was not taken out of that list: a condition this
    !!! early pass cannot read is not an error here, it just is not filtered.
    int t = time_now();
    str prescan_src = preprocess_conditionals(src, env);
    time_print("    pp conditionals", time_now() - t);
    if pp_error != "" {
        prescan_src = src;
        pp_error = "";
    }
    t = time_now();
    pp_prescan_exports(prescan_src);
    time_print("    pp prescan", time_now() - t);

    t = time_now();
    str preprocessed = preprocess_includes(src, filename);
    time_print("    pp includes", time_now() - t);
    if pp_error == "" {
        pp_error = pp_unclosed_message(pp_cond_stack);
    }
    if pp_error != "" {
        pp_run_error = true;
        return "";
    }
    !!! A block that was opened and never closed holds everything to the end of the
    !!! file it was opened in.
    if pp_capturing != "" {
        str body = pp_trim_eol(pp_capture_buf);
        if body != "" {
            body = body + "\n";
        }
        pp_exports = pp_nv_set(pp_exports, pp_capturing, body);
        pp_capturing = "";
        pp_capture_buf = "";
    }

    t = time_now();
    preprocessed = pp_collect_to(preprocessed);
    time_print("    pp collect_to", time_now() - t);

    !!! The second pass expands the imports the walk had no block for, and its lines
    !!! are numbered as they come out of it, so the map is rebuilt with them.
    t = time_now();
    preprocessed = expand_imports_pass2(preprocessed, false);
    time_print("    pp imports2", time_now() - t);
    t = time_now();
    preprocessed = pp_collect_to_map(preprocessed);
    time_print("    pp collect_map", time_now() - t);

    t = time_now();
    preprocessed = preprocess_replaces(preprocessed, filename, pp_reps);
    time_print("    pp replaces", time_now() - t);
    if pp_error != "" {
        pp_run_error = true;
        return "";
    }
    t = time_now();
    preprocessed = preprocess_newlines(preprocessed, filename, pp_map);
    time_print("    pp newlines", time_now() - t);
    pp_map = pp_new_map;

    pp_out = preprocessed;
    return pp_out;
}

!!! The same walk for `-I`, which is not the same program: the option asks for the
!!! text the tokenizer would read, so the `#to` lines stay in it and the flags they
!!! name are written in front of it as one more `#to` line. The two passes that move
!!! text around also run in the order this path runs them in the toolchain - the
!!! replacements before the second import pass, and that one with the flags put
!!! inside a function body rather than at the top of the file.
str pp_out_i;

str preprocess_only_source -> str src, str filename, @PreprocEnv env {
    pp_out_i = "";
    pp_run_error = false;
    pp_error = "";
    pp_warnings = null;
    pp_to_flags = null;
    pp_map = pp_src_new();
    pp_cur_line = 1;
    pp_reps = null;
    pp_cond_stack = null;
    pp_visited = null;
    pp_capturing = "";
    pp_capture_buf = "";
    pp_capture_line = 0;
    pp_capture_col = 1;
    pp_capture_len = 0;
    pp_env = env;

    str prescan_src = preprocess_conditionals(src, env);
    if pp_error != "" {
        prescan_src = src;
        pp_error = "";
    }
    pp_prescan_exports(prescan_src);

    str preprocessed = preprocess_includes(src, filename);
    if pp_error == "" {
        pp_error = pp_unclosed_message(pp_cond_stack);
    }
    if pp_error != "" {
        pp_run_error = true;
        return "";
    }
    if pp_capturing != "" {
        str body = pp_trim_eol(pp_capture_buf);
        if body != "" {
            body = body + "\n";
        }
        pp_exports = pp_nv_set(pp_exports, pp_capturing, body);
        pp_capturing = "";
        pp_capture_buf = "";
    }

    preprocessed = pp_collect_to_keep(preprocessed);
    preprocessed = preprocess_replaces(preprocessed, filename, pp_reps);
    if pp_error != "" {
        pp_run_error = true;
        return "";
    }
    preprocessed = expand_imports_pass2(preprocessed, true);
    preprocessed = preprocess_newlines(preprocessed, filename, pp_map);

    !!! Every `#to` line out of the .i. What such a line names is read while the text
    !!! is preprocessed and it reaches the backend by another road: a compile hands it
    !!! to cmp in front of the .r text (fe_to_line, frontend_run.b), and gn.exe takes
    !!! it off again there. Nothing of it belongs in the preprocessed source -I
    !!! writes, which is source text and not a build instruction. The line is emptied
    !!! rather than dropped so the .i still counts the lines of the source it came
    !!! from: a diagnostic that points at one of them points at the same place.
    str kept = "";
    int sp = 0;
    int sp_len = pe_len(preprocessed);
    while sp < sp_len {
        int le = pp_find_from_n(preprocessed, sp_len, "\n", sp);
        if le < 0 {
            le = sp_len;
        }
        int first = sp;
        while first < le && (preprocessed[first] == ' ' || preprocessed[first] == '\t') {
            first = first + 1;
        }
        bool is_to = (le - first) >= 4 && pe_matches(preprocessed, first, "#to ");
        if pe_len(kept) > 0 {
            kept = kept + "\n";
        }
        if !is_to {
            kept = kept + pe_sub(preprocessed, sp, le - sp);
        }
        sp = le;
        if sp < sp_len && preprocessed[sp] == '\n' {
            sp = sp + 1;
        } else if sp < sp_len && preprocessed[sp] == '\r' {
            sp = sp + 1;
            if sp < sp_len && preprocessed[sp] == '\n' {
                sp = sp + 1;
            }
        }
    }
    preprocessed = kept;
    pp_out_i = preprocessed;
    return pp_out_i;
}
