!~
 ~  runtime/bstr.b: the compiler's utility library, written in blang.
 ~
 ~  This is the utility library the compiler is written with: the color switch and
 ~  the layout every diagnostic uses. Every message goes through libbstr.dll;
 ~  this DLL is the same API built from blang source, so the self-hosted compiler
 ~  can print the same text - "file:line:col: error: msg", the source line with the
 ~  span in bold red, the caret line under it - without the toolchain DLL behind it.
 ~
 ~  Build: blang.exe runtime/bstr.b '-CMP,--no-runtime' -system kernel32 -o bin/libbstr.dll
 ~  `-CMP,--no-runtime` matters for the same reason as in the other runtime DLLs:
 ~  without it this one would import a runtime while defining part of it. Nothing
 ~  here needs one anyway: the text is written with WriteFile and a number becomes
 ~  text through `(str)int` / `(str)longlong`, which the compiler writes into every
 ~  image itself.
 ~
 ~  The escapes are written as the ESC byte followed by its body ("[1m"), never as
 ~  one literal, because the language's string escapes have no octal form. The
 ~  buffer argument is a @char, so the caller's byte buffer is written directly.
 ~!

#to type=dll

int DllMain {
    return 1;
}

!~ ---------- state ---------- ~!

!!! 1 once the standard error took the virtual terminal codes. Every colored
!!! message checks it, exactly as the toolchain version checks str_vt_enabled.
int g_vt;

!!! Whether a diagnostic prints the source line and the caret under its header.
!!! The compiler turns it off for a program that came in on standard input
!!! (`... | blang.exe -stdin b -`): the message keeps its header - the file, the
!!! place and the text - and nothing stands below it. ux_source_shown answers the
!!! same question to the caller that lays out the blocks of a note itself (the
!!! notes that point at an unmatched bracket, the type note, the source block of a
!!! warning list).
int g_show_source = 1;

void ux_show_source -> bool on {
    if on {
        g_show_source = 1;
    } else {
        g_show_source = 0;
    }
}

bool ux_source_shown {
    return g_show_source == 1;
}

!!! The byte index a walk of a source line is left at. `_put_char` both appends a
!!! visual character and says where the next one starts, and a function has one
!!! result, so the index is left here.
int g_next;

!~ ---------- writing to the standard error ---------- ~!

local void _w -> str s, int n {
    @void err = GetStdHandle(-12);
    @int written;
    WriteFile(err, s, n, @written, null);
}

local void _ws -> str s {
    _w(s, lstrlenA(s));
}

local void _wc -> char c {
    @char p = @c;
    _w((str)p, 1);
}

!!! `n` as decimal text. The compiler's own conversion is used, so a number prints
!!! the way it prints in a program.
local void _wn -> int v {
    _ws((str)v);
}

!!! The ESC byte and one body ("[1m", "[0m", ...).
local void _esc -> str body {
    _wc((char)27);
    _ws(body);
}

!~ ---------- the color switch ---------- ~!

int ux_color_init {
    @void err = GetStdHandle(-12);
    @int mode;
    if GetConsoleMode(err, @mode) != 0 {
        SetConsoleMode(err, mode | 4);
        g_vt = 1;
        return 1;
    }
    return 0;
}

void ux_color -> str which {
    if g_vt == 0 {
        end;
    }
    if lstrcmpA(which, "bold") == 0 {
        _esc("[1m");
        end;
    }
    if lstrcmpA(which, "red") == 0 {
        _esc("[31m");
        end;
    }
    if lstrcmpA(which, "bold_red") == 0 {
        _esc("[1;31m");
        end;
    }
    if lstrcmpA(which, "green") == 0 {
        _esc("[32m");
        end;
    }
    if lstrcmpA(which, "reset") == 0 {
        _esc("[0m");
        end;
    }
}

!~ ---------- appending into a caller's buffer ---------- ~!
!!! Every appender copies at most up to sz - 1 bytes and keeps the buffer
!!! terminated, which is what the toolchain version gets from snprintf. Each returns the
!!! new length, so they chain.

local int _app -> @char buf, int sz, int n, str s {
    @char p = (@char)s;
    int i = 0;
    while p[i] != (char)0 && n < sz - 1 {
        buf[n] = p[i];
        n = n + 1;
        i = i + 1;
    }
    buf[n] = (char)0;
    return n;
}

local int _appc -> @char buf, int sz, int n, char c {
    if n < sz - 1 {
        buf[n] = c;
        n = n + 1;
        buf[n] = (char)0;
    }
    return n;
}

local int _appn -> @char buf, int sz, int n, int v {
    return _app(buf, sz, n, (str)v);
}

!!! A color, appended only when the terminal took the codes: the toolchain version
!!! selects between the escape and an empty string, and appending nothing is the
!!! same thing.
local int _app_color -> @char buf, int sz, int n, str body {
    if g_vt == 0 {
        return n;
    }
    n = _appc(buf, sz, n, (char)27);
    return _app(buf, sz, n, body);
}

!!! How many digits the decimal text of `v` has: the width the line number takes
!!! before the " | " of the source line, which the caret line lines up with.
local int _digits -> int v {
    longlong x = (longlong)v;
    if x < 0 {
        x = 0 - x;
    }
    int d = 1;
    while x >= 10 {
        x = x / 10;
        d = d + 1;
    }
    return d;
}

!~ ---------- '...' in bold ---------- ~!

!!! The message with everything between quotes bold, the quotes themselves not.
!!! The same text the toolchain version builds in sn_bold_quoted.
local int _bold_quoted -> @char buf, int sz, int n, str msg {
    @char p = (@char)msg;
    int i = 0;
    while p[i] != (char)0 && n < sz - 1 {
        if p[i] == '\'' {
            n = _appc(buf, sz, n, '\'');
            i = i + 1;
            n = _app_color(buf, sz, n, "[1m");
            while p[i] != (char)0 && p[i] != '\'' && n < sz - 1 {
                n = _appc(buf, sz, n, p[i]);
                i = i + 1;
            }
            n = _app_color(buf, sz, n, "[0m");
            if p[i] == '\'' && n < sz - 1 {
                n = _appc(buf, sz, n, p[i]);
                i = i + 1;
            }
        } else {
            n = _appc(buf, sz, n, p[i]);
            i = i + 1;
        }
    }
    buf[n] = (char)0;
    return n;
}

!!! The same, printed straight to the standard error.
local void _puts_bold_quoted -> str msg {
    @char p = (@char)msg;
    int i = 0;
    while p[i] != (char)0 {
        if p[i] == '\'' {
            _wc('\'');
            i = i + 1;
            ux_color("bold");
            while p[i] != (char)0 && p[i] != '\'' {
                _wc(p[i]);
                i = i + 1;
            }
            ux_color("reset");
            if p[i] == '\'' {
                _wc('\'');
                i = i + 1;
            }
        } else {
            _wc(p[i]);
            i = i + 1;
        }
    }
}

!~ ---------- visual columns ---------- ~!
!!! A tab is a jump to the next multiple of eight, a UTF-8 lead byte and the bytes
!!! after it are two columns wide, and a stray continuation byte takes no room.
!!! The caret line is placed by visual columns, so a line using tabs or CJK still
!!! gets its caret under the right character.

!!! The byte at `i` as a value from 0 to 255. A char read is signed, so a byte with
!!! the high bit set arrives as a negative number; adding 256 is what the toolchain
!!! version's `unsigned char` cast does. The value is kept in an int because an
!!! unsigned comparison would call the runtime, and a runtime DLL is built with no
!!! runtime behind it.
local int _byte -> @char line, int i {
    int c = (int)line[i];
    if c < 0 {
        return c + 256;
    }
    return c;
}

local int _vis_col -> @char line, int pos {
    int vc = 0;
    int i = 0;
    while i < pos && line[i] != (char)0 {
        int c = _byte(line, i);
        if c == 9 {
            vc = (vc + 8) - (vc % 8);
            i = i + 1;
            continue;
        }
        if c < 128 {
            vc = vc + 1;
            i = i + 1;
            continue;
        }
        if c < 192 {
            i = i + 1;
            continue;
        }
        vc = vc + 2;
        i = i + 1;
        while line[i] != (char)0 && _byte(line, i) >= 128 && _byte(line, i) < 192 {
            i = i + 1;
        }
    }
    return vc;
}

!!! One visual character of the line at byte `i`: a tab becomes the spaces up to
!!! the next stop, a multi-byte character is copied whole, a stray continuation
!!! byte is dropped. The byte after it is left in g_next. Returns the new length.
local int _put_char -> @char buf, int sz, int n, @char line, int i {
    int c = _byte(line, i);
    if c == 9 {
        int k = 0;
        while k < 8 {
            n = _appc(buf, sz, n, ' ');
            k = k + 1;
        }
        g_next = i + 1;
        return n;
    }
    if c < 128 {
        n = _appc(buf, sz, n, line[i]);
        g_next = i + 1;
        return n;
    }
    if c < 192 {
        g_next = i + 1;
        return n;
    }
    int len = 1;
    while line[i + len] != (char)0 && (_byte(line, i + len) & 192) == 128 {
        len = len + 1;
    }
    int k = 0;
    while k < len && n < sz - 1 {
        n = _appc(buf, sz, n, line[i + k]);
        k = k + 1;
    }
    g_next = i + len;
    return n;
}

!~ ---------- the shared layout of error and note ---------- ~!
!!! `label` names the category and `color` paints it and the highlighted span; the
!!! rest of the layout is the same, which is why both categories share this body.

!!! End the text with the NUL byte every reader of the buffer expects: the block
!!! is handed on as a C string, so a missing terminator makes the reader run on
!!! into whatever the buffer held past the message.
local void _msg_term -> @char buf, int sz, int n {
    if n > sz - 1 {
        n = sz - 1;
    }
    buf[n] = (char)0;
}

local int _message_buf -> @char buf, int sz, str label, str color,
                          str filename, int line, int col, str msg, str src_line,
                          int highlight_len, str suggestion, int suggestion_col,
                          bool show_tilde {
    @char src = (@char)src_line;
    int n = 0;
    !!! Line 1: [bold]filename:line:col: [colored]label:[reset] msg
    n = _app_color(buf, sz, n, "[1m");
    n = _app(buf, sz, n, filename);
    n = _appc(buf, sz, n, ':');
    n = _appn(buf, sz, n, line);
    n = _appc(buf, sz, n, ':');
    n = _appn(buf, sz, n, col);
    n = _app(buf, sz, n, ": ");
    n = _app_color(buf, sz, n, color);
    n = _app(buf, sz, n, label);
    n = _appc(buf, sz, n, ':');
    n = _app_color(buf, sz, n, "[0m");
    n = _appc(buf, sz, n, ' ');
    n = _bold_quoted(buf, sz, n, msg);
    n = _appc(buf, sz, n, '\n');
    !!! The header is the whole message when the source line is not shown: what
    !!! follows below it is the line itself and the caret under the place the
    !!! message names, and a program that came in on standard input has no file
    !!! whose line could be put there.
    if g_show_source == 0 {
        !!! The block is a C string to every caller (`err += buf`), so the byte after
        !!! the text is written here: without it the reader runs on into whatever
        !!! the buffer held, and the diagnostic carries a few bytes of it.
        _msg_term(buf, sz, n);
        return n;
    }

    int slen = lstrlenA(src_line);
    if highlight_len <= 0 {
        highlight_len = 1;
    }
    int hl_start = col - 1;
    if hl_start > slen {
        hl_start = slen;
    }
    int hl_end = hl_start + highlight_len;
    if hl_end > slen {
        hl_end = slen;
    }

    int vis_hl_start = _vis_col(src, hl_start);
    int vis_hl_end = _vis_col(src, hl_end);

    !!! Line 2: the source line, the highlighted span in the label's color
    n = _app(buf, sz, n, " ");
    n = _appn(buf, sz, n, line);
    n = _app(buf, sz, n, " | ");
    int i = 0;
    while i < hl_start {
        n = _put_char(buf, sz, n, src, i);
        i = g_next;
    }
    if hl_end > hl_start {
        n = _app_color(buf, sz, n, color);
        i = hl_start;
        while i < hl_end && n < sz - 1 {
            n = _put_char(buf, sz, n, src, i);
            i = g_next;
        }
        n = _app_color(buf, sz, n, "[0m");
    }
    i = hl_end;
    while i < slen && n < sz - 1 {
        n = _put_char(buf, sz, n, src, i);
        i = g_next;
    }
    n = _appc(buf, sz, n, '\n');

    !!! Line 3: the caret, aligned by the visual column of the span
    int pad = _digits(line);
    int k = 0;
    while k < pad + 2 && n < sz - 1 {
        n = _appc(buf, sz, n, ' ');
        k = k + 1;
    }
    n = _app(buf, sz, n, "| ");
    n = _app_color(buf, sz, n, color);
    k = 0;
    while k < vis_hl_start && n < sz - 1 {
        n = _appc(buf, sz, n, ' ');
        k = k + 1;
    }
    int vis_len = vis_hl_end - vis_hl_start;
    if vis_len <= 0 {
        vis_len = 1;
    }
    n = _appc(buf, sz, n, '^');
    k = 1;
    while k < vis_len && n < sz - 1 {
        n = _appc(buf, sz, n, '~');
        k = k + 1;
    }
    n = _app_color(buf, sz, n, "[0m");
    n = _appc(buf, sz, n, '\n');

    !!! Lines 4 and 5: the suggestion in green, with the tildes under it when the
    !!! diagnostic asked for them
    if suggestion != (str)null {
        int sl = lstrlenA(suggestion);
        int vis_sc = _vis_col(src, suggestion_col > 0 ? suggestion_col - 1 : 0);
        k = 0;
        while k < pad + 2 && n < sz - 1 {
            n = _appc(buf, sz, n, ' ');
            k = k + 1;
        }
        n = _app(buf, sz, n, "| ");
        k = 0;
        while k < vis_sc && n < sz - 1 {
            n = _appc(buf, sz, n, ' ');
            k = k + 1;
        }
        n = _app_color(buf, sz, n, "[32m");
        n = _app(buf, sz, n, suggestion);
        n = _app_color(buf, sz, n, "[0m");
        n = _appc(buf, sz, n, '\n');
        if show_tilde {
            k = 0;
            while k < pad + 2 && n < sz - 1 {
                n = _appc(buf, sz, n, ' ');
                k = k + 1;
            }
            n = _app(buf, sz, n, "| ");
            k = 0;
            while k < vis_sc && n < sz - 1 {
                n = _appc(buf, sz, n, ' ');
                k = k + 1;
            }
            n = _app_color(buf, sz, n, "[32m");
            k = 0;
            while k < sl && n < sz - 1 {
                n = _appc(buf, sz, n, '~');
                k = k + 1;
            }
            n = _app_color(buf, sz, n, "[0m");
            n = _appc(buf, sz, n, '\n');
        }
    }

    _msg_term(buf, sz, n);
    return n;
}

!~ ---------- the three layouts ---------- ~!

int ux_error_buf -> @char buf, int buf_size, str filename, int line, int col,
                    str msg, str src_line, int highlight_len,
                    str suggestion, int suggestion_col, bool show_tilde {
    return _message_buf(buf, buf_size, "error", "[1;31m", filename, line, col,
                        msg, src_line, highlight_len, suggestion, suggestion_col,
                        show_tilde);
}

int ux_note_buf -> @char buf, int buf_size, str filename, int line, int col,
                   str msg, str src_line, int highlight_len {
    return _message_buf(buf, buf_size, "note", "[1;36m", filename, line, col,
                        msg, src_line, highlight_len, (str)null, 0, false);
}

!!! A warning paints the span magenta and does not bold the quoted parts, which
!!! is why it has a body of its own instead of the shared one.
int ux_warning_buf -> @char buf, int buf_size, str filename, int line, int col,
                      str msg, str src_line, int highlight_len {
    @char src = (@char)src_line;
    int slen = lstrlenA(src_line);
    if highlight_len <= 0 {
        highlight_len = 1;
    }
    int hl_start = col - 1;
    if hl_start < 0 {
        hl_start = 0;
    }
    if hl_start > slen {
        hl_start = slen;
    }
    int hl_end = hl_start + highlight_len;
    if hl_end > slen {
        hl_end = slen;
    }

    int n = 0;
    n = _app_color(buf, buf_size, n, "[1m");
    n = _app(buf, buf_size, n, filename);
    n = _appc(buf, buf_size, n, ':');
    n = _appn(buf, buf_size, n, line);
    n = _appc(buf, buf_size, n, ':');
    n = _appn(buf, buf_size, n, col);
    n = _app(buf, buf_size, n, ": ");
    n = _app_color(buf, buf_size, n, "[1;38;2;218;112;214m");
    n = _app(buf, buf_size, n, "warning:");
    n = _app_color(buf, buf_size, n, "[0m");
    n = _appc(buf, buf_size, n, ' ');
    n = _app(buf, buf_size, n, msg);
    n = _appc(buf, buf_size, n, '\n');
    !!! The header is the whole warning when the source line is not shown.
    if g_show_source == 0 {
        _msg_term(buf, buf_size, n);
        return n;
    }

    n = _app(buf, buf_size, n, " ");
    n = _appn(buf, buf_size, n, line);
    n = _app(buf, buf_size, n, " | ");
    int i = 0;
    while i < hl_start && n < buf_size - 1 {
        n = _appc(buf, buf_size, n, src[i]);
        i = i + 1;
    }
    if hl_end > hl_start {
        n = _app_color(buf, buf_size, n, "[1;38;2;218;112;214m");
        i = hl_start;
        while i < hl_end && n < buf_size - 1 {
            n = _appc(buf, buf_size, n, src[i]);
            i = i + 1;
        }
        n = _app_color(buf, buf_size, n, "[0m");
    }
    i = hl_end;
    while i < slen && n < buf_size - 1 {
        n = _appc(buf, buf_size, n, src[i]);
        i = i + 1;
    }
    n = _appc(buf, buf_size, n, '\n');

    int pad = _digits(line);
    int k = 0;
    while k < pad + 2 && n < buf_size - 1 {
        n = _appc(buf, buf_size, n, ' ');
        k = k + 1;
    }
    n = _app(buf, buf_size, n, "| ");
    n = _app_color(buf, buf_size, n, "[1;38;2;218;112;214m");
    k = 0;
    while k < col - 1 && n < buf_size - 1 {
        n = _appc(buf, buf_size, n, ' ');
        k = k + 1;
    }
    n = _appc(buf, buf_size, n, '^');
    k = 1;
    while k < highlight_len && n < buf_size - 1 {
        n = _appc(buf, buf_size, n, '~');
        k = k + 1;
    }
    n = _app_color(buf, buf_size, n, "[0m");
    n = _appc(buf, buf_size, n, '\n');
    _msg_term(buf, buf_size, n);
    return n;
}

!~ ---------- the two that print straight away ---------- ~!

void ux_error -> str filename, int line, int col, str msg, str src_line,
                 int highlight_len, str suggestion, int suggestion_col, bool show_tilde {
    @char src = (@char)src_line;
    ux_color("bold");
    _ws(filename);
    _wc(':');
    _wn(line);
    _wc(':');
    _wn(col);
    _ws(": ");
    ux_color("bold_red");
    _ws("error: ");
    ux_color("reset");
    _puts_bold_quoted(msg);
    _wc('\n');

    int slen = lstrlenA(src_line);
    if highlight_len <= 0 {
        highlight_len = 1;
    }
    int hl_start = col - 1;
    if hl_start < 0 {
        hl_start = 0;
    }
    if hl_start > slen {
        hl_start = slen;
    }
    int hl_end = hl_start + highlight_len;
    if hl_end > slen {
        hl_end = slen;
    }
    int pad = _digits(line);

    _ws(" ");
    _wn(line);
    _ws(" | ");
    int i = 0;
    while i < hl_start {
        _wc(src[i]);
        i = i + 1;
    }
    if hl_end > hl_start {
        ux_color("bold_red");
        i = hl_start;
        while i < hl_end {
            _wc(src[i]);
            i = i + 1;
        }
        ux_color("reset");
    }
    i = hl_end;
    while src[i] != (char)0 {
        _wc(src[i]);
        i = i + 1;
    }
    _wc('\n');

    int k = 0;
    while k < pad + 2 {
        _wc(' ');
        k = k + 1;
    }
    _ws("| ");
    ux_color("bold_red");
    k = 0;
    while k < col - 1 {
        _wc(' ');
        k = k + 1;
    }
    _wc('^');
    k = 1;
    while k < highlight_len {
        _wc('~');
        k = k + 1;
    }
    ux_color("reset");
    _wc('\n');

    if suggestion != (str)null {
        int sl = lstrlenA(suggestion);
        int sc = suggestion_col - 1;
        k = 0;
        while k < pad + 2 {
            _wc(' ');
            k = k + 1;
        }
        _ws("| ");
        k = 0;
        while k < sc {
            _wc(' ');
            k = k + 1;
        }
        ux_color("green");
        _ws(suggestion);
        ux_color("reset");
        _wc('\n');
        if show_tilde {
            k = 0;
            while k < pad + 2 {
                _wc(' ');
                k = k + 1;
            }
            _ws("| ");
            k = 0;
            while k < sc {
                _wc(' ');
                k = k + 1;
            }
            ux_color("green");
            k = 0;
            while k < sl {
                _wc('~');
                k = k + 1;
            }
            ux_color("reset");
            _wc('\n');
        }
    }
}

void ux_fatal -> str prog, str msg {
    ux_color("bold");
    _ws(prog);
    _ws(": ");
    ux_color("reset");
    ux_color("bold_red");
    _ws("fatal error: ");
    ux_color("reset");
    _puts_bold_quoted(msg);
    _wc('\n');
    _ws("compilation terminated.\n");
}

!~ ---------- reading a file ---------- ~!

!!! A whole file in one heap block, with its size written through sz, or null when
!!! it cannot be read. The block comes from VirtualAlloc, so the caller gives it
!!! back with `unlink` - it is not a `malloc` block, which is what the toolchain version
!!! handed out and why a blang caller cannot mix the two.
str ux_read_file -> str path, @int sz {
    $sz = 0;
    @void h = CreateFileA(path, 2147483648, 1, null, 3, 128, null);
    if h == null {
        return (str)null;
    }
    @int high;
    utype int nbytes = GetFileSize(h, @high);
    if high != 0 {
        CloseHandle(h);
        return (str)null;
    }
    @void cell;
    VirtualAlloc(@cell, (longlong)nbytes + 1, 12288, 4);
    if cell == null {
        CloseHandle(h);
        return (str)null;
    }
    @int got;
    ReadFile(h, cell, nbytes, @got, null);
    CloseHandle(h);
    @char p = (@char)cell;
    p[(int)got] = (char)0;
    $sz = (int)got;
    return (str)cell;
}
