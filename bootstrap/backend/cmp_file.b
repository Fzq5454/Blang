#once
!~
 ~  bootstrap/backend/cmp_file.b: the side files cmp reads.
 ~
 ~  the binary readers in backend/bmeta, backend/codegen_blib and
 ~  A signature file, a linked library and the side file
 ~  of an embedded DLL all carry bytes, so they are read whole with the binary
 ~  reader of the runtime: the text reader stops at the first NUL and the type byte
 ~  of a `void` is one.
 ~
 ~  Each reader then walks its block with the cursor below, which is what the toolchain
 ~  does with `fread` and a file offset it advances by hand.
 ~!

#head "fileio"
#head "cmp_types"
#head "cmp_text"

!!! The block being walked, how many bytes it holds, and the byte the walk stands
!!! on. The reader of the runtime answers the block alone, so the length is asked
!!! of the file itself: without it a corrupt side file would be walked past its end.
str cm_data;
int cm_len;
int cm_pos;

!!! BLANG_HOME, which is where the toolchain readers look for the `meta` and `lib`
!!! directories first. Empty when it is not set, and the caller then falls back to
!!! the working directory alone.
str cm_home {
    @void cell;
    cg_balloc(@cell, 1024);
    @char p = (@char)cell;
    p[0] = (char)0;
    int n = GetEnvironmentVariableA("BLANG_HOME", (str)cell, 1024);
    if n <= 0 || n >= 1024 {
        return "";
    }
    return (str)cell;
}

!!! The leaf name of a path, which is the one a side file is named after: a DLL
!!! asked for as `\path\to\libbrtm.dll` keeps its signatures in `libbrtm.dll.bmeta`.
str cm_base_name -> str path {
    int slash = -1;
    int i = 0;
    int n = pe_len(path);
    while i < n {
        if path[i] == '\\' || path[i] == '/' {
            slash = i;
        }
        i = i + 1;
    }
    return pe_sub(path, slash + 1, n - slash - 1);
}

!!! The whole file at `path`, or null when it is not there. An .exe finds a side
!!! file beside itself the way it finds a DLL beside itself, so the three
!!! candidates are the ones the toolchain tries.
str cm_open_binary -> str path {
    @void f = getFile(path, "rb");
    if f == null {
        return (str)null;
    }
    cm_len = SetFilePointer(f, 0, null, 2);
    SetFilePointer(f, 0, null, 0);
    str data = readFileA(@f, -1, -1);
    if data == null {
        cm_len = 0;
    }
    return data;
}

!!! The side file `leaf` of the install, looked for under BLANG_HOME, one level up
!!! from it (where a compiler in bin/ finds the install) and under the working
!!! directory. `dir` is `meta` or `lib`.
str cm_open_side -> str dir, str leaf {
    str home = cm_home();
    str data = (str)null;
    if !pe_eq(home, "") {
        data = cm_open_binary(home + "\\" + dir + "\\" + leaf);
        if data == null {
            data = cm_open_binary(home + "\\..\\" + dir + "\\" + leaf);
        }
    }
    if data == null {
        data = cm_open_binary(dir + "\\" + leaf);
    }
    return data;
}

!!! The directory a side file is written into: BLANG_HOME when the compiler stands
!!! anywhere but a bin subdirectory, one level up from it when it does (a compiler
!!! in bin/ keeps its install one level up, which is where the readers look), and
!!! the working directory when BLANG_HOME is not set at all.
str cm_side_write_dir -> str dir {
    str home = cm_home();
    if pe_eq(home, "") {
        return dir;
    }
    if pe_eq(cm_base_name(home), "bin") {
        return home + "\\..\\" + dir;
    }
    return home + "\\" + dir;
}

str cm_side_write_path -> str dir, str leaf {
    return cm_side_write_dir(dir) + "\\" + leaf;
}

!!! Create `dir` when it is not there, which is what the `_mkdir` does before
!!! writing a side file: a compiler run from a fresh install has to be able to
!!! write into <install>/meta even when nothing created it yet.
void cm_mkdir -> str dir {
    if !pe_eq(dir, "") {
        CreateDirectoryA(dir, null);
    }
}

!!! ---- writing a side file, one `fwrite` at a time ----

@void cm_out;

!!! Open `path` for writing, or answer false.
bool cm_open_write -> str path {
    cm_out = getFile(path, "wb");
    if cm_out == null {
        return false;
    }
    return true;
}

void cm_w8 -> int v {
    int written;
    char b = (char)v;
    @char p = @b;
    WriteFile(cm_out, (str)p, 1, @written, null);
}

!!! One byte that is written as a character literal, which is the magic at the head
!!! of a side file: `cm_w8` takes an int and a literal is a char.
void cm_w8c -> char c {
    cm_w8((int)c);
}

void cm_w16 -> int v {
    cm_w8(v & 255);
    cm_w8((v >> 8) & 255);
}

void cm_w32 -> int v {
    cm_w8(v & 255);
    cm_w8((v >> 8) & 255);
    cm_w8((v >> 16) & 255);
    cm_w8((v >> 24) & 255);
}

!!! `n` bytes from `p`: a whole section written in one call, which is what makes
!!! writing the code of a DLL one `WriteFile` instead of one per byte.
void cm_wraw -> @char p, int n {
    if n <= 0 {
        end;
    }
    int written;
    WriteFile(cm_out, (str)p, n, @written, null);
}

!!! A text and the NUL that ends it, which is how a name in a table is stored.
void cm_wstr -> str s {
    int n = pe_len(s);
    cm_w32(n + 1);
    @char p = (@char)s;
    cm_wraw(p, n);
    cm_w8(0);
}

!!! Start a walk over `data`. False when there is nothing to walk.
bool cm_walk -> str data {
    cm_data = data;
    cm_pos = 0;
    if data == null {
        return false;
    }
    return true;
}

!!! One unsigned byte, and the four bytes of a little-endian 32-bit number.
int cm_u8 {
    int v = (int)cm_data[cm_pos] & 255;
    cm_pos = cm_pos + 1;
    return v;
}

int cm_u16 {
    int v = ((int)cm_data[cm_pos] & 255) | (((int)cm_data[cm_pos + 1] & 255) << 8);
    cm_pos = cm_pos + 2;
    return v;
}

int cm_u32 {
    int v = ((int)cm_data[cm_pos] & 255) |
            (((int)cm_data[cm_pos + 1] & 255) << 8) |
            (((int)cm_data[cm_pos + 2] & 255) << 16) |
            (((int)cm_data[cm_pos + 3] & 255) << 24);
    cm_pos = cm_pos + 4;
    return v;
}

!!! `n` bytes of the block as a text, which is how a length-prefixed list of name
!!! bytes is read back.
str cm_take -> int n {
    if n <= 0 {
        return "";
    }
    str s = pe_sub(cm_data, cm_pos, n);
    cm_pos = cm_pos + n;
    return s;
}

!!! A length-prefixed text: a `u32` count that includes the NUL, then the bytes.
!!! That is how cmp stores a name in its side files.
str cm_rstr {
    int n = cm_u32();
    if n == 0 {
        return "";
    }
    str s = cm_take(n - 1);
    cm_pos = cm_pos + 1;
    return s;
}

!!! The bytes `[off, off+n)` of the block as a pointer, for a copy into a buffer.
@char cm_at -> int off {
    @char p = (@char)cm_data;
    return p + off;
}
