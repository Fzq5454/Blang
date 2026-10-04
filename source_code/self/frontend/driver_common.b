#once
!~
 ~  bootstrap/frontend/driver_common.b: what the two drivers of the self-hosted
 ~  toolchain both need.
 ~
 ~  the toolchain is three programs - blang.exe parses the options and hands the
 ~  work to gn.exe, gn.exe runs the front end and hands the .r text to cmp.exe, and
 ~  cmp.exe writes the image - and the two that run the front end (blang.exe and
 ~  gn.exe) share a small library: the module directory, the fatal
 ~  diagnostics (libbstr), and the way one program starts another. Those pieces stand
 ~  here so that blang.b and gn.b can both be built on them, the way the toolchain builds
 ~  both on the runtime and libbstr.
 ~
 ~  Nothing here belongs to the language or to the image: it is the driver's own
 ~  furniture, and it is included after the front-end modules (which name the
 ~  preprocessor's home) and before the driver's options.
 ~!

#head "stdsrt"
#head "fileio"
#head "vector"
#head "Chinese/chinese_heads"

!!! The name the driver's own messages carry. the toolchain writes "blang.exe" into the
!!! messages of the front-end driver and "gn" into the ones gn.exe prints about its
!!! own work; this implementation keeps one name per program here instead, and each main sets
!!! it before the first message can be printed.
str g_prog_name = "blang.exe";

!!! ---- the command line ----

!!! The arguments, in order, the program name first, so the index of an argument is
!!! the `argv[]` index. A `vector(str)` is all a command line needs: the number of
!!! arguments is its length, and the pool of fixed nodes this used to build (256 of
!!! them) was both a ceiling and a linked list walked by hand. blang has no argv
!!! yet - the language's entry point is a plain `int main { ... }` - so both drivers
!!! read the command line into this and index it the way the toolchain indexes argv[].
vector(str) g_args;

int cmd_len -> str s {
    int n = 0;
    @char p = (@char)s;
    while p[n] != (char)0 {
        n = n + 1;
    }
    return n;
}

!!! Split the command line into arguments, the way the C runtime does: whitespace
!!! separates them, a `"` quotes a run (so a path with spaces survives), and the
!!! program name comes first and is kept, so the indexes match argv[].
void split_cmd -> str cmd {
    g_args.release();
    int n = cmd_len(cmd);
    int i = 0;
    while i < n {
        while i < n && (cmd[i] == ' ' || cmd[i] == '\t') {
            i = i + 1;
        }
        if i >= n {
            skip;
        }
        @void cell;
        malloc(@cell, n + 1);
        @char buf = (@char)cell;
        int o = 0;
        bool quoted = false;
        if cmd[i] == '"' {
            quoted = true;
            i = i + 1;
        }
        while i < n {
            if quoted {
                if cmd[i] == '"' {
                    i = i + 1;
                    skip;
                }
            } else if cmd[i] == ' ' || cmd[i] == '\t' {
                skip;
            }
            buf[o] = cmd[i];
            o = o + 1;
            i = i + 1;
        }
        buf[o] = (char)0;
        g_args.add((str)cell);
    }
}

!!! ---- the environment the two drivers talk through ----

!!! What a name in the environment holds, empty when it is not there. The size is
!!! asked for first, because the list of imported signatures runs to tens of
!!! kilobytes and a fixed buffer silently cut it short (see gn.b).
str env_get -> str name {
    int n = GetEnvironmentVariableA(name, null, 0);
    if n <= 0 {
        return "";
    }
    @void cell;
    malloc(@cell, n + 1);
    GetEnvironmentVariableA(name, (str)cell, n + 1);
    str v = pe_sub((str)cell, 0, n);
    unlink(@cell);
    return v;
}

!!! ---- the module directory ----

!!! The directory the running compiler stands in, which is what BLANG_HOME means to
!!! the compiler (see blang_home): the standard headers are looked for under
!!! <home>\includes\bl and <home>\..\includes\bl, and cmd.exe / gn.exe / cmp.exe are
!!! looked for beside it. the toolchain reads it out of the environment and puts it there;
!!! this implementation hands the same directory to the preprocessor and to the two programs it
!!! starts, because the answer is the module of the executable either way.
str g_home;

void setup_home {
    @void cell;
    malloc(@cell, 1024);
    @char p = (@char)cell;
    @void mod = null;
    int n = GetModuleFileNameA(mod, (str)cell, 1024);
    if n > 0 && n < 1024 {
        int slash = -1;
        int i = 0;
        while i < n {
            if p[i] == '\\' || p[i] == '/' {
                slash = i;
            }
            i = i + 1;
        }
        if slash > 0 {
            g_home = pe_sub((str)cell, 0, slash);
        }
    }
    pp_home = g_home;
    unlink(@cell);
}

!!! The path of the program `name` beside the running one: that is where the toolchain
!!! looks for gn.exe and cmp.exe (BLANG_HOME/<name>).
str beside_exe -> str name {
    if pe_len(g_home) == 0 {
        return name;
    }
    return g_home + "\\" + name;
}

!!! ---- messages ----

!!! A driver message that stops one file but is not a fatal error: "prog: error:
!!! msg" on the standard error, which is what the driver prints when it cannot
!!! write the file it was asked for (zh_file_error).
void file_error -> str prog, str msg {
    system.err(zh_file_error(prog, msg) + "\n");
}

!!! ---- small text helpers ----

!!! One more argument on a space-separated list, which is how the driver keeps the
!!! options it has to hand on: `-l` names, DLL names, `-CMP,` arguments.
str append_arg -> str cnode, str add {
    if cnode == "" {
        return add;
    }
    return cnode + " " + add;
}

!!! ---- the preprocessor's diagnostics ----

!!! The four numbers a diagnostic text carries: `line:col:len:message`, which is how
!!! the front end's passes hand a position back to the driver.
int hdr_line;
int hdr_col;
int hdr_len;
str hdr_msg;

void split_header -> str text {
    hdr_line = 1;
    hdr_col = 1;
    hdr_len = 0;
    hdr_msg = text;
    int n = pe_len(text);
    int seen = 0;
    int i = 0;
    int cnode = 0;
    bool has_any = false;
    while i < n {
        char c = text[i];
        if c >= '0' && c <= '9' {
            cnode = cnode * 10 + ((int)c - 48);
            has_any = true;
            i = i + 1;
            continue;
        }
        if c == ':' && seen < 3 {
            if seen == 0 {
                hdr_line = cnode;
            } else if seen == 1 {
                hdr_col = cnode;
            } else {
                hdr_len = cnode;
            }
            seen = seen + 1;
            cnode = 0;
            has_any = false;
            i = i + 1;
            continue;
        }
        skip;
    }
    if seen >= 3 {
        int c3 = 0;
        int s = 0;
        int j = 0;
        while j < n {
            if text[j] == ':' {
                s = s + 1;
                if s == 3 {
                    c3 = j + 1;
                    skip;
                }
            }
            j = j + 1;
        }
        hdr_msg = pe_sub_to_end(text, c3);
    }
    if !has_any && seen == 0 {
        hdr_msg = text;
    }
    while hdr_msg[0] == ' ' {
        hdr_msg = pe_sub_to_end(hdr_msg, 1);
    }
}

!!! One preprocessor error, printed the way every other diagnostic is: libbstr lays
!!! out `file:line:col: error: message`, the source line and the caret. The positions
!!! a pass reports are positions in the file as it was written, so the line table of
!!! that text is what the line under them is read from. `fname` is the file the text
!!! came from: the toolchain entry point is handed the same name and puts it in the
!!! message, so a run of gn.exe names the `.b` file and not the driver's input.
void print_pp_error -> str src, str fname {
    lex_start(src);
    split_header(pp_error);
    if hdr_len <= 0 {
        hdr_len = 1;
    }
    str text = line_text(hdr_line);
    @void cell;
    malloc(@cell, 4096);
    str buf = (str)cell;
    !!! The message goes through zh_msg before the layout is written, which is what
    !!! the toolchain entry point does, and the category word of the header is left to
    !!! zh_prefixes - so the excerpt, the caret and the suggestion cannot shift.
    ux_error_buf(buf, 4096, fname, hdr_line, hdr_col, zh_msg(hdr_msg), text, hdr_len,
                 (str)null, 0, true);
    system.err(zh_prefixes(buf));
    unlink(@cell);
    unlink(@text);
}

!!! The `#warning` lines the walk collected, in the order the files were read. Each
!!! one is `file\nline:col:len:message\nsource line`, which is what the driver
!!! pushes and prints the same way.
void print_pp_warnings {
    @NameList w = pp_warnings;
    while w != null {
        str entry = w.name;
        int nl1 = pp_find_from(entry, "\n", 0);
        if nl1 >= 0 {
            int nl2 = pp_find_from(entry, "\n", nl1 + 1);
            str wfile = pe_sub(entry, 0, nl1);
            str header = "";
            str body = "";
            if nl2 >= 0 {
                header = pe_sub(entry, nl1 + 1, nl2 - nl1 - 1);
                body = pe_sub_to_end(entry, nl2 + 1);
            } else {
                header = pe_sub_to_end(entry, nl1 + 1);
            }
            split_header(header);
            @void cell;
            malloc(@cell, 4096);
            str buf = (str)cell;
            ux_warning_buf(buf, 4096, wfile, hdr_line, hdr_col, zh_msg(hdr_msg), body,
                           hdr_len > 0 ? hdr_len : 1);
            system.err(zh_prefixes(buf));
            unlink(@cell);
        }
        w = w.next;
    }
}

!!! ---- the standard input ----

!!! The name an input that comes in on a pipe is given: what `-` names on the
!!! command line and what every message of the compiler then names the file. No
!!! file of the machine can be called that - `<` and `>` cannot be written in a
!!! file name on Windows - so the marker cannot be taken for one of them.
str g_stdin_name = "<stdin>";

!!! Everything a stream holds, as text. It is read in binary and to its end, so a
!!! program piped in is the bytes that were piped in - what a file would have
!!! given - and a pipe longer than one buffer is read whole. The empty stream is
!!! the empty text, which is what an empty file reads as.
str read_stream -> @void handle {
    int cap = 65536;
    @void cell;
    malloc(@cell, cap);
    @char d = (@char)cell;
    int len = 0;
    bool more = true;
    while more {
        if len + 4097 > cap {
            int want = cap * 2;
            @void ncell;
            malloc(@ncell, want);
            @char nd = (@char)ncell;
            int k = 0;
            while k < len {
                nd[k] = d[k];
                k = k + 1;
            }
            @char old = d;
            unlink(@old);
            d = nd;
            cap = want;
        }
        !!! The count comes back through the address of a plain int: `@int got;`
        !!! would be a pointer of its own, uninitialized, and `$got` would read
        !!! whatever it happens to hold (`bfile.b` reads a file the same way).
        int got = 0;
        int ok = ReadFile(handle, (@void)(d + len), 4096, @got, null);
        int n = got;
        if ok == 0 || n <= 0 {
            more = false;
        } else {
            len = len + n;
        }
    }
    d[len] = (char)0;
    return (str)d;
}

!!! The name of a temporary .r file: four letters and four digits, which is the
!!! shape gn.exe gives one. `seed` is chopped down first so the multiply below
!!! cannot overflow, and the two ends of the name are taken from different bits of
!!! the new value.
str temp_r_name -> int seed {
    seed = seed % 65536;
    if seed < 0 {
        seed = 0 - seed;
    }
    @void cell;
    malloc(@cell, 16);
    @char d = (@char)cell;
    int i = 0;
    while i < 4 {
        seed = (seed * 1103 + 12345) % 2147483647;
        if seed % 2 == 1 {
            d[i * 2] = (char)(65 + seed % 26);
        } else {
            d[i * 2] = (char)(97 + seed % 26);
        }
        seed = (seed * 1103 + 12345) % 2147483647;
        d[i * 2 + 1] = (char)(48 + seed % 10);
        i = i + 1;
    }
    d[8] = (char)0;
    str name = pe_sub((str)cell, 0, 8);
    unlink(@cell);
    return name;
}

!!! The path of a temporary .r file: the directory GetTempPathA names (it ends
!!! with the backslash) and a name of the shape above.
str temp_r_path {
    @void cell;
    malloc(@cell, 512);
    int n = GetTempPathA(512, (str)cell);
    str dir = "";
    if n > 0 {
        dir = pe_sub((str)cell, 0, n);
    }
    str path = dir + temp_r_name((int)GetTickCount64() + (int)GetCurrentProcessId()) + ".r";
    unlink(@cell);
    return path;
}

!!! ---- starting the next program ----

!!! Start one program and wait for it: the two handles of the child land in a
!!! PROCESS_INFORMATION and the exit code of the run is the one that comes back.
!!! A STARTUPINFO that names no standard handles leaves the child on the console
!!! this compiler was started from, which is where the `system()` call puts it.
int run_program -> str app, str cmd {
    @void si;
    malloc(@si, 128);
    @void pi;
    malloc(@pi, 32);
    @char z = (@char)si;
    int i = 0;
    while i < 128 {
        z[i] = (char)0;
        i = i + 1;
    }
    z = (@char)pi;
    i = 0;
    while i < 32 {
        z[i] = (char)0;
        i = i + 1;
    }
    !!! cb is the size of the structure and stands first in it.
    @int cb = (@int)si;
    cb[0] = 104;
    !!! The standard handles are handed on when any of the three is not the
    !!! console: a compiler that is piped into (`type x.b | blang.exe b -`) has to
    !!! let gn.exe read the same input, and the C runtime's system() - which the
    !!! driver starts its children with - passes the handles it was given for
    !!! exactly that reason. With all three on the console nothing changes: the
    !!! child gets the console the usual way. dwFlags stands at offset 60
    !!! (STARTF_USESTDHANDLES) and the three handles at 80, 88 and 96, so the
    !!! block is written through a @longlong for those.
    @void h_in = GetStdHandle(-10);
    @void h_out = GetStdHandle(-11);
    @void h_err = GetStdHandle(-12);
    bool handed_on = GetFileType(h_in) != 2 || GetFileType(h_out) != 2 ||
                     GetFileType(h_err) != 2;
    if handed_on {
        cb[15] = 256;
        @longlong sh = (@longlong)si;
        sh[10] = (longlong)h_in;
        sh[11] = (longlong)h_out;
        sh[12] = (longlong)h_err;
    }
    int ok = CreateProcessA(app, cmd, null, null, handed_on ? 1 : 0, 0, null, null, si, pi);
    if ok == 0 {
        file_error(g_prog_name, "cannot run '" + app + "'");
        return 1;
    }
    !!! The handles are eight bytes each, so the block is read through a @longlong.
    @longlong h = (@longlong)pi;
    @void hp = (@void)h[0];
    WaitForSingleObject(hp, 4294967295);
    @void rc;
    malloc(@rc, 8);
    @int rp = (@int)rc;
    rp[0] = 0;
    GetExitCodeProcess(hp, rp);
    int code = rp[0];
    CloseHandle(hp);
    CloseHandle((@void)h[1]);
    unlink(@rc);
    return code;
}
