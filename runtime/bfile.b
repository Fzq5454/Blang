!~
 ~  runtime/bfile.b: the file runtime, written in blang.
 ~
 ~  This was lib/bfile.lib, machine code that blibobj5 emitted. `includes/bl/fileio`
 ~  reaches it through `__bcall`.
 ~
 ~  Build: blang.exe runtime/bfile.b '-CMP,--no-runtime' -system kernel32 -o bin/libbfile.dll
 ~  Only kernel32 is used, so this DLL depends on nothing else.
 ~
 ~  A file is treated as a grid: rows are lines split by '\n', columns are
 ~  character offsets inside a line, and a -1 for either means "all of it".
 ~
 ~  Contract, from the native version:
 ~    _getFile(str path, str mode) -> @void       a handle, null when it fails
 ~    _readFile(@void h, int rows, int cols) -> str       the region, up to a NUL
 ~    _readFileA(@void h, int rows, int cols) -> str      the same, NULs and all
 ~    _readFileChar(@void h, int row, int col) -> char    one character
 ~    _writeFile(@void h, str content)                    write a string
 ~    _writeFileByte(@void h, int data)                   write one byte
 ~
 ~  `h` is a cell holding the handle, because the head passes `@handle`. It is
 ~  dereferenced on entry, as the native code did.
 ~
 ~  The native library also exported `_file_read` and `_file_select`, but those
 ~  were its own helpers: `_file_read` returned a buffer in rax and its size in
 ~  rdx, which one blang value cannot carry. They are `local` here.
 ~!

#to type=dll

int DllMain {
    return 1;
}

!~ ---------- opening ---------- ~!

!!! The mode is the C spelling: an `r`, `w` or `a` for the access and the
!!! disposition, with `+` asking for reading as well.
@void _getFile -> str path, str mode {
    int access = 0;
    int disp = 0;
    @char p = (@char)mode;
    char ch = $p;
    while ch != (char)0 {
        if ch == 'r' {
            access = access | (1 << 31);
            if disp == 0 {
                disp = 3;
            }
        } else if ch == 'w' {
            access = access | (1 << 30);
            disp = 2;
        } else if ch == 'a' {
            access = access | 4;
            disp = 4;
        } else if ch == '+' {
            access = access | (1 << 31);
        }
        p = p + 1;
        ch = $p;
    }
    if access == 0 {
        access = (1 << 31);
    }
    if disp == 0 {
        disp = 3;
    }
    @void f = CreateFileA(path, access, 3, null, disp, 128, null);
    if f == null {
        return null;
    }
    if (int)f == -1 {
        return null;
    }
    return f;
}

!~ ---------- reading ---------- ~!

!!! The whole file from the start, in a buffer one byte longer than it and
!!! terminated at the end. `size` receives the length. Null when it cannot be
!!! read.
local @void _raw_read -> @void h, @int total {
    int n = SetFilePointer(h, 0, null, 2);
    SetFilePointer(h, 0, null, 0);
    $total = 0;
    !!! A file of no bytes was read: it answers the empty text and not null. Only a
    !!! size that could not be read at all is a failure
    !!! (`INVALID_SET_FILE_POINTER`, which is -1 as an int). Returning null for an
    !!! empty file made the compiler refuse a file it had just opened - blang.exe
    !!! read an empty `hello.b` and reported "cannot read the input file", while
    !!! the driver reads the same file as an empty text and compiles it.
    if n < 0 {
        return null;
    }
    @void buf = VirtualAlloc(null, (longlong)(n + 1), 12288, 4);
    if buf == null {
        return null;
    }
    @int got;
    ReadFile(h, (str)buf, n, @got, null);
    @char tail = (@char)buf;
    tail = tail + n;
    $tail = (char)0;
    $total = n;
    return buf;
}

!!! The rows/cols region of a raw buffer, in a fresh string. `null_stop` stops
!!! at the first NUL, which is what tells a text file from a binary one.
local str _select -> @void buf, int total, int rows, int cols, int null_stop {
    @void out = VirtualAlloc(null, (longlong)(total + 1), 12288, 4);
    @char dst = (@char)out;
    @char src = (@char)buf;
    int row = 0;
    int col = 0;
    int i = 0;
    while i < total {
        char ch = $src;
        if null_stop == 1 {
            if ch == (char)0 {
                skip;
            }
        }
        if ch == '\n' {
            row = row + 1;
            if rows != -1 {
                if row >= rows {
                    skip;
                }
            }
            $dst = '\n';
            dst = dst + 1;
            col = 0;
        } else {
            if cols == -1 {
                $dst = ch;
                dst = dst + 1;
            } else {
                if col < cols {
                    $dst = ch;
                    dst = dst + 1;
                }
            }
            col = col + 1;
        }
        src = src + 1;
        i = i + 1;
    }
    $dst = (char)0;
    return (str)out;
}

str _readFile -> @void h, int rows, int cols {
    @void hh = (@void)$h;
    int total;
    @void buf = _raw_read(hh, @total);
    if buf == null {
        return (str)null;
    }
    str out = _select(buf, total, rows, cols, 1);
    VirtualFree(buf, 0, 32768);
    return out;
}

str _readFileA -> @void h, int rows, int cols {
    @void hh = (@void)$h;
    int total;
    @void buf = _raw_read(hh, @total);
    if buf == null {
        return (str)null;
    }
    str out = _select(buf, total, rows, cols, 0);
    VirtualFree(buf, 0, 32768);
    return out;
}

!!! The character at [row][col], or 0 when the row ends before that column.
char _readFileChar -> @void h, int row, int col {
    @void hh = (@void)$h;
    int total;
    @void buf = _raw_read(hh, @total);
    if buf == null {
        return (char)0;
    }
    int n = total;
    @char p = (@char)buf;
    int r = 0;
    int c = 0;
    int i = 0;
    char found = (char)0;
    int hit = 0;
    while i < n {
        char ch = $p;
        if ch == '\n' {
            if r == row {
                skip;
            }
            r = r + 1;
            c = 0;
        } else {
            if r == row {
                if c == col {
                    found = ch;
                    hit = 1;
                    skip;
                }
            }
            c = c + 1;
        }
        p = p + 1;
        i = i + 1;
    }
    VirtualFree(buf, 0, 32768);
    if hit == 1 {
        return found;
    }
    return (char)0;
}

!~ ---------- writing ---------- ~!

void _writeFile -> @void h, str content {
    @void hh = (@void)$h;
    int written;
    WriteFile(hh, content, lstrlenA(content), @written, null);
}

void _writeFileByte -> @void h, int data {
    @void hh = (@void)$h;
    int written;
    char b = (char)data;
    @char p = @b;
    WriteFile(hh, (str)p, 1, @written, null);
}
