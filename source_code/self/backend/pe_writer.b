#once
!~
 ~  bootstrap/backend/pe_writer.b: the PE64+ writer.
 ~
 ~  It is the write64 and write64: the four section buffers, the
 ~  import and export tables, the section layout and the headers of the image.
 ~
 ~  the toolchain keeps the state in a PEWriter object reached through an opaque handle;
 ~  here cmp.exe is one program with one writer, so the same state is a set of
 ~  globals and the public functions API keep their names as `pw_*`.
 ~
 ~  The bytes are written with WriteFile rather than through the fileio runtime:
 ~  that one writes a text up to its NUL, and an image is full of NULs.
 ~!

#head "stdsrt"
#head "cmp_text"

!!! A growable block of bytes: the same shape as the emitter's buffer, but the
!!! writer keeps four of them and every function takes the one it works on. The
!!! type owns the bytes - `data`, `len` and `cap` are its state and the operations
!!! on it are its methods, declared here and defined under the type - while the
!!! `pb_*` names the rest of the writer calls stay as one-line forwarders.
!!! `data` and `len` are public because the writer reads them all over: a section
!!! buffer's bytes and its length are what the image is copied from. `cap` is the
!!! one piece of state nothing outside the type touches, so it is private.
type PEBuf {
    @char data;
    int len;
    private int cap;

    !!! A buffer that is declared starts empty and asks the heap for its block on the
    !!! first write. The fields of an `init` body are written with their bare names,
    !!! the way a method body names them (`name = "none";` in the language's own
    !!! regression test).
    init PEBuf {
        data = null;
        len = 0;
        cap = 0;
    }

    !!! A declared buffer gives its block back when it goes out of scope. A block that
    !!! came from `malloc` (`pw_new_buf`) has no lifetime of its own and is released by
    !!! the caller, and a buffer with no block yet has nothing to give back.
    destruct PEBuf {
        @char old = data;
        if cap > 0 {
            unlink(@old);
        }
    }

    !!! An empty buffer for a block that came from `malloc`, on which no initialiser of
    !!! the language runs.
    public stub void setup;

    !!! Room for `need` more bytes: the block is replaced by one that holds them.
    public stub void reserve -> int need;

    !!! One byte `v` appended.
    public stub void push -> int v;

    !!! One byte that is written as a character literal, which is the magic at the head
    !!! of a side file: `push` takes an int and a literal is a char.
    public stub void pushc -> char c;

    !!! Two bytes at `pos`, little-endian.
    public stub void put16 -> int pos, int v;

    !!! Four bytes at `pos`, little-endian.
    public stub void put32 -> int pos, int v;

    !!! Eight bytes at `pos`, little-endian.
    public stub void put64 -> int pos, longlong v;

    !!! Two bytes appended.
    public stub void add16 -> int v;

    !!! Four bytes appended.
    public stub void add32 -> int v;

    !!! Eight bytes appended.
    public stub void add64 -> longlong v;

    !!! Append `n` bytes read from `p`.
    public stub void add_raw -> @char p, int n;

    !!! Append a text and the NUL that ends it, which is what a name in a table is.
    public stub void add_str -> str s;
};

@PEBuf pw_new_buf {
    PEBuf proto;
    @PEBuf b;
    malloc(@b, size proto);
    b.setup();
    return b;
}

!!! The buffer is handed to the caller, which is the one that grows and releases it:
!!! the `malloc`/`unlink` pairing check of `stdsrt` reads the allocation here as an
!!! unpaired one. `NOWARN` keeps that report - and every other warning about this
!!! body - out of the build.
attribute pw_new_buf: NOWARN

!!! ---- the buffer's own methods ----

void PEBuf::setup {
    self.data = null;
    self.len = 0;
    self.cap = 0;
}

void PEBuf::reserve -> int need {
    if self.len + need <= self.cap {
        end;
    }
    int want = self.cap * 2;
    if want < self.len + need {
        want = self.len + need;
    }
    if want < 64 {
        want = 64;
    }
    @void cell;
    malloc(@cell, want);
    @char nb = (@char)cell;
    @char src = self.data;
    int i = 0;
    while i < self.len {
        nb[i] = src[i];
        i = i + 1;
    }
    @char old = self.data;
    if self.cap > 0 {
        unlink(@old);
    }
    self.data = nb;
    self.cap = want;
}

void PEBuf::push -> int v {
    !!! A bare call is a call to another method of this type: `push` reserves the
    !!! byte through `reserve` and never touches `cap` itself.
    reserve(1);
    @char d = self.data;
    d[self.len] = (char)v;
    self.len = self.len + 1;
}

void PEBuf::pushc -> char c {
    push((int)c);
}

void PEBuf::put16 -> int pos, int v {
    @char d = self.data;
    d[pos] = (char)(v & 255);
    d[pos + 1] = (char)((v >> 8) & 255);
}

void PEBuf::put32 -> int pos, int v {
    @char d = self.data;
    d[pos] = (char)(v & 255);
    d[pos + 1] = (char)((v >> 8) & 255);
    d[pos + 2] = (char)((v >> 16) & 255);
    d[pos + 3] = (char)((v >> 24) & 255);
}

void PEBuf::put64 -> int pos, longlong v {
    @char d = self.data;
    int i = 0;
    while i < 8 {
        d[pos + i] = (char)((v >> (i * 8)) & 255);
        i = i + 1;
    }
}

void PEBuf::add16 -> int v {
    reserve(2);
    put16(self.len, v);
    self.len = self.len + 2;
}

void PEBuf::add32 -> int v {
    reserve(4);
    put32(self.len, v);
    self.len = self.len + 4;
}

void PEBuf::add64 -> longlong v {
    reserve(8);
    put64(self.len, v);
    self.len = self.len + 8;
}

void PEBuf::add_raw -> @char p, int n {
    reserve(n);
    @char d = self.data;
    int i = 0;
    while i < n {
        d[self.len + i] = p[i];
        i = i + 1;
    }
    self.len = self.len + n;
}

void PEBuf::add_str -> str s {
    int n = pe_len(s);
    reserve(n + 1);
    @char d = self.data;
    int i = 0;
    while i < n {
        d[self.len + i] = s[i];
        i = i + 1;
    }
    d[self.len + n] = (char)0;
    self.len = self.len + n + 1;
}

!!! ---- the names the writer calls ----
!!! Every operation that used to be a free function taking `@PEBuf` keeps its name
!!! and its signature here, one line forwarding to the method of the type, so no
!!! call site outside this file changes.

void pb_reserve -> @PEBuf b, int need {
    b.reserve(need);
}

void pb_push -> @PEBuf b, int v {
    b.push(v);
}

void pb_pushc -> @PEBuf b, char c {
    b.pushc(c);
}

void pb_put16 -> @PEBuf b, int pos, int v {
    b.put16(pos, v);
}

void pb_put32 -> @PEBuf b, int pos, int v {
    b.put32(pos, v);
}

void pb_put64 -> @PEBuf b, int pos, longlong v {
    b.put64(pos, v);
}

void pb_add16 -> @PEBuf b, int v {
    b.add16(v);
}

void pb_add32 -> @PEBuf b, int v {
    b.add32(v);
}

void pb_add64 -> @PEBuf b, longlong v {
    b.add64(v);
}

void pb_add_raw -> @PEBuf b, @char p, int n {
    b.add_raw(p, n);
}

void pb_add_str -> @PEBuf b, str s {
    b.add_str(s);
}

!!! ---- the writer's state ----

!!! 0 console, 1 dll, 2 win.
int pw_type;

!!! A window program built without a console window: the subsystem field then says
!!! GUI, and the loader allocates no console for the program.
int pw_no_window_con;

@PEBuf pw_text;
@PEBuf pw_rdata;
@PEBuf pw_idata;
@PEBuf pw_edata;

type PEImport {
    str dll;
    str fname;
    int iat_rva;
    @PEImport next;
};

type PEExport {
    str name;
    int rva;
    @PEExport next;
};

@PEImport pw_imports;
@PEExport pw_exports;

!!! Where the sections land. They used to sit at fixed one-page addresses (.rdata
!!! 0x11000, .idata 0x12000, .edata 0x13000), which only holds while every section
!!! fits in a page. A signature file like kernel32's makes .idata tens of kilobytes,
!!! and then it ran into the sections after it: overlapping sections and a
!!! SizeOfImage too small for the last one, which the loader rejects with
!!! 0xC000007B. The layout is planned from the sizes as they stand, and the two
!!! sections that carry RVAs are built again once it is known.
int pw_text_vsize;
int pw_rdata_rva;
int pw_idata_rva;
int pw_edata_rva;

int PEW_TEXT_RVA;

void pw_create {
    pw_text = pw_new_buf();
    pw_rdata = pw_new_buf();
    pw_idata = pw_new_buf();
    pw_edata = pw_new_buf();
    pw_imports = null;
    pw_exports = null;
    pw_type = 0;
    pw_no_window_con = 0;
    pw_text_vsize = 0x10000;
    pw_rdata_rva = 0x11000;
    pw_idata_rva = 0x12000;
    pw_edata_rva = 0x13000;
    PEW_TEXT_RVA = 0x1000;
}

void pw_set_type -> int t {
    pw_type = t;
}

void pw_set_no_window_con -> int on {
    pw_no_window_con = on;
}

!!! The code section, which the compiler has already patched against the planned
!!! layout. A copy of it is kept so the writer can be used on its own as well.
void pw_set_code -> @char d, int n {
    pw_text.len = 0;
    pb_add_raw(pw_text, d, n);
}

int pw_add_rdata_str -> str s {
    int rva = pw_rdata_rva + pw_rdata.len;
    pb_add_str(pw_rdata, s);
    return rva;
}

int pw_add_rdata_raw -> @char p, int n {
    int rva = pw_rdata_rva + pw_rdata.len;
    pb_add_raw(pw_rdata, p, n);
    return rva;
}

int pw_add_bytes_off -> @char p, int n {
    int off = pw_rdata.len;
    pb_add_raw(pw_rdata, p, n);
    return off;
}

int pw_rdata_base {
    return pw_rdata_rva;
}

@char pw_rdata_data {
    return pw_rdata.data;
}

int pw_rdata_size {
    return pw_rdata.len;
}

int pw_import_count {
    int n = 0;
    @PEImport e = pw_imports;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

!!! A DLL function imported twice (a signature file and a linked library can both
!!! name it) shares one IAT slot, so the table has one entry per function rather
!!! than one per request.
int pw_add_import -> str dll, str fnc {
    @PEImport e = pw_imports;
    int i = 0;
    while e != null {
        if pe_eq(e.dll, dll) && pe_eq(e.fname, fnc) {
            return i;
        }
        e = e.next;
        i = i + 1;
    }
    PEImport proto;
    @PEImport n;
    malloc(@n, size proto);
    n.dll = dll;
    n.fname = fnc;
    n.iat_rva = 0;
    n.next = null;
    int idx = pw_import_count();
    if pw_imports == null {
        pw_imports = n;
    } else {
        @PEImport t = pw_imports;
        while t.next != null {
            t = t.next;
        }
        t.next = n;
    }
    return idx;
}

int pw_get_iat -> int idx {
    @PEImport e = pw_imports;
    int i = 0;
    while e != null {
        if i == idx {
            return e.iat_rva;
        }
        e = e.next;
        i = i + 1;
    }
    return 0;
}

@PEImport pw_import_at -> int idx {
    @PEImport e = pw_imports;
    int i = 0;
    while e != null {
        if i == idx {
            return e;
        }
        e = e.next;
        i = i + 1;
    }
    return null;
}

str pw_import_dll -> int idx {
    @PEImport e = pw_import_at(idx);
    if e == null {
        return "";
    }
    return e.dll;
}

str pw_import_func -> int idx {
    @PEImport e = pw_import_at(idx);
    if e == null {
        return "";
    }
    return e.fname;
}

void pw_add_export -> str name, int rva {
    PEExport proto;
    @PEExport n;
    malloc(@n, size proto);
    n.name = name;
    n.rva = rva;
    n.next = null;
    if pw_exports == null {
        pw_exports = n;
    } else {
        @PEExport t = pw_exports;
        while t.next != null {
            t = t.next;
        }
        t.next = n;
    }
}

int pw_export_count {
    int n = 0;
    @PEExport e = pw_exports;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

!!! `a < b` over two texts, the comparison the `sort` uses.
bool pw_str_lt -> str a, str b {
    int i = 0;
    while true {
        char ca = a[i];
        char cb = b[i];
        if ca == (char)0 {
            return cb != (char)0;
        }
        if cb == (char)0 {
            return false;
        }
        if ca != cb {
            return ca < cb;
        }
        i = i + 1;
    }
    return false;
}

!!! The exports sorted by name. The name pointer table of the export directory has
!!! to be sorted: the loader looks an exported name up with a binary search over it,
!!! so an unsorted table makes every lookup that does not happen to land on a
!!! searched midpoint fail - the DLL still loads, but the import cannot be resolved
!!! and the process dies before its entry point with 0xC0000139. the toolchain sorts a
!!! vector; here the chain is sorted by inserting each export into a new chain in
!!! place, which is the insertion sort over a list.
@PEExport pw_exports_sorted {
    @PEExport out = null;
    @PEExport e = pw_exports;
    while e != null {
        @PEExport nx = e.next;
        e.next = null;
        if out == null {
            out = e;
        } else if pw_str_lt(e.name, out.name) {
            e.next = out;
            out = e;
        } else {
            @PEExport t = out;
            while t.next != null && !pw_str_lt(e.name, t.next.name) {
                t = t.next;
            }
            e.next = t.next;
            t.next = e;
        }
        e = nx;
    }
    return out;
}

!!! The export directory, in .edata:
!!!   IMAGE_EXPORT_DIRECTORY (40 bytes)
!!!   Export Address Table  [RVA x N]
!!!   Name Pointer Table    [RVA x N]
!!!   Ordinal Table         [WORD x N]
!!!   Name strings
void pw_finalize_exports {
    if pw_exports == null {
        end;
    }
    pw_edata.len = 0;
    @PEExport sorted = pw_exports_sorted();
    int n = pw_export_count();
    int dir_sz = 40;
    int eat_off = dir_sz;
    int eat_sz = n * 4;
    int npt_off = eat_off + eat_sz;
    int npt_sz = n * 4;
    int ot_off = npt_off + npt_sz;
    int ot_sz = n * 2;
    int str_off = ot_off + ot_sz;

    @PEBuf strings = pw_new_buf();
    @CmpIntNode str_rvas = null;
    @PEExport e = sorted;
    while e != null {
        str_rvas = cn_int(str_rvas, pw_edata_rva + str_off + strings.len);
        pb_add_str(strings, e.name);
        e = e.next;
    }

    pb_add32(pw_edata, 0);
    pb_add32(pw_edata, 0);
    pb_add16(pw_edata, 0);
    pb_add16(pw_edata, 0);
    pb_add32(pw_edata, 0);
    pb_add32(pw_edata, 1);
    pb_add32(pw_edata, n);
    pb_add32(pw_edata, n);
    pb_add32(pw_edata, pw_edata_rva + eat_off);
    pb_add32(pw_edata, pw_edata_rva + npt_off);
    pb_add32(pw_edata, pw_edata_rva + ot_off);

    e = sorted;
    while e != null {
        pb_add32(pw_edata, e.rva);
        e = e.next;
    }
    @CmpIntNode sr = str_rvas;
    while sr != null {
        pb_add32(pw_edata, (int)sr.v);
        sr = sr.next;
    }
    int i = 0;
    while i < n {
        pb_add16(pw_edata, i);
        i = i + 1;
    }
    pb_add_raw(pw_edata, strings.data, strings.len);
}

!!! The functions of one group, as a chain of references to the import entries
!!! themselves: the IAT address the writer hands back is written through the
!!! reference, so it has to name the entry and not a copy of it.
type PEImportRef {
    @PEImport fn;
    int hn_rva;
    @PEImportRef next;
};

int pw_ref_count -> @PEImportRef head {
    int n = 0;
    @PEImportRef e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

!!! The import table: one descriptor per DLL, then the lookup tables, the address
!!! tables and the strings. The groups are kept in the order the DLLs were first
!!! named, which is what the toolchain map iteration by first insertion gives.
type PEImportGroup {
    str dll;
    @PEImportRef fns;
    int dll_rva;
    int ilt_rva;
    int iat_rva;
    @PEImportGroup next;
};

@PEImportGroup pw_groups;

int pw_group_count {
    int n = 0;
    @PEImportGroup g = pw_groups;
    while g != null {
        n = n + 1;
        g = g.next;
    }
    return n;
}

void pw_finalize_imports {
    pw_idata.len = 0;
    if pw_imports == null {
        int i = 0;
        while i < 20 {
            pb_push(pw_idata, 0);
            i = i + 1;
        }
        end;
    }
    !!! Group by DLL.
    pw_groups = null;
    @PEImport im = pw_imports;
    while im != null {
        @PEImportGroup g = pw_groups;
        @PEImportGroup found = null;
        while g != null {
            if pe_eq(g.dll, im.dll) {
                found = g;
                skip;
            }
            g = g.next;
        }
        if found == null {
            PEImportGroup proto;
            @PEImportGroup ng;
            malloc(@ng, size proto);
            ng.dll = im.dll;
            ng.fns = null;
            ng.dll_rva = 0;
            ng.ilt_rva = 0;
            ng.iat_rva = 0;
            ng.next = null;
            if pw_groups == null {
                pw_groups = ng;
            } else {
                @PEImportGroup t = pw_groups;
                while t.next != null {
                    t = t.next;
                }
                t.next = ng;
            }
            found = ng;
        }
        !!! The functions of one group keep the order they were first named in. The
        !!! reference is `rf`: `ref` is the keyword of a by-reference parameter.
        PEImportRef proto2;
        @PEImportRef rf;
        malloc(@rf, size proto2);
        rf.fn = im;
        rf.hn_rva = 0;
        rf.next = null;
        if found.fns == null {
            found.fns = rf;
        } else {
            @PEImportRef t2 = found.fns;
            while t2.next != null {
                t2 = t2.next;
            }
            t2.next = rf;
        }
        im = im.next;
    }

    int ngrps = pw_group_count();
    int idt_total = (ngrps + 1) * 20;
    int cur_off = idt_total;
    @PEImportGroup g2 = pw_groups;
    while g2 != null {
        g2.ilt_rva = pw_idata_rva + cur_off;
        cur_off = cur_off + (pw_ref_count(g2.fns) + 1) * 8;
        g2.iat_rva = pw_idata_rva + cur_off;
        cur_off = cur_off + (pw_ref_count(g2.fns) + 1) * 8;
        g2 = g2.next;
    }
    int strings_off = cur_off;

    @PEBuf strings = pw_new_buf();
    !!! Every hint/name entry first, then every DLL name, in two runs: the toolchain
    !!! writes them in two loops as well, and the offsets the descriptors carry have
    !!! to be the same numbers. Writing a group's names next to its own DLL name
    !!! instead put every DLL name at a different offset.
    @PEImportGroup g3 = pw_groups;
    while g3 != null {
        @PEImportRef r = g3.fns;
        while r != null {
            int rva = pw_idata_rva + strings_off + strings.len;
            pb_push(strings, 0);
            pb_push(strings, 0);
            pb_add_str(strings, r.fn.fname);
            r.hn_rva = rva;
            r = r.next;
        }
        g3 = g3.next;
    }
    g3 = pw_groups;
    while g3 != null {
        g3.dll_rva = pw_idata_rva + strings_off + strings.len;
        pb_add_str(strings, g3.dll);
        g3 = g3.next;
    }

    !!! The descriptors.
    @PEImportGroup g4 = pw_groups;
    while g4 != null {
        pb_add32(pw_idata, g4.ilt_rva);
        pb_add32(pw_idata, 0);
        pb_add32(pw_idata, 0);
        pb_add32(pw_idata, g4.dll_rva);
        pb_add32(pw_idata, g4.iat_rva);
        g4 = g4.next;
    }
    int k = 0;
    while k < 5 {
        pb_add32(pw_idata, 0);
        k = k + 1;
    }
    !!! The lookup table and the address table of every DLL, and the IAT address of
    !!! every function as it is written.
    @PEImportGroup g5 = pw_groups;
    while g5 != null {
        @PEImportRef r2 = g5.fns;
        while r2 != null {
            pb_add64(pw_idata, r2.hn_rva);
            r2 = r2.next;
        }
        pb_add64(pw_idata, 0);
        int fi = 0;
        @PEImportRef r3 = g5.fns;
        while r3 != null {
            pb_add64(pw_idata, r3.hn_rva);
            r3.fn.iat_rva = g5.iat_rva + fi * 8;
            fi = fi + 1;
            r3 = r3.next;
        }
        pb_add64(pw_idata, 0);
        g5 = g5.next;
    }
    pb_add_raw(pw_idata, strings.data, strings.len);
}

!!! The PE constants the headers are built from.
int pw_align_200 -> int v {
    return (v + 0x1FF) & (0 - 512);
}

int pw_align_1000 -> int v {
    return (v + 0xFFF) & (0 - 4096);
}

!!! Where the sections land, from the sizes as they stand. It is called once the
!!! code and every .rdata byte are in place, and again (identically) from pw_write.
!!! That is the whole point: the machine code reaches .rdata and .idata through
!!! displacements worked out from these numbers, so the numbers have to be final
!!! before the code is patched. Planning them only inside pw_write left the code
!!! patched for the assumed .rdata base (0x11000); as soon as .text passed 64 KiB
!!! this moved .rdata and .idata and every one of those references pointed into the
!!! middle of the code - an image that linked and then faulted at its entry.
!!! `code_size` is the length of the code about to be set (the code is patched
!!! against the layout before it is handed over), 0 to use the code already held.
void pw_plan_layout -> int code_size {
    !!! A zero-size .rdata section (VirtualSize=0, SizeOfRawData=0) makes the
    !!! Windows loader reject the image (0xC000007B). Keep it non-empty.
    if pw_rdata.len == 0 {
        pb_push(pw_rdata, 0);
    }
    int code_bytes = code_size;
    if code_bytes == 0 {
        code_bytes = pw_text.len;
    }
    pw_text_vsize = 0x10000;
    if code_bytes + PEW_TEXT_RVA > pw_text_vsize {
        pw_text_vsize = pw_align_1000(code_bytes + PEW_TEXT_RVA);
    }
    pw_rdata_rva = PEW_TEXT_RVA + pw_text_vsize;
    pw_idata_rva = pw_align_1000(pw_rdata_rva + pw_rdata.len);
    pw_idata.len = 0;
    pw_finalize_imports();
    !!! .edata follows the rounded size of the .idata that was just built, not of
    !!! the table as it stood before.
    pw_edata_rva = pw_align_1000(pw_idata_rva + pw_idata.len);
    if pw_type == 1 {
        pw_edata.len = 0;
        pw_finalize_exports();
    }
}

!!! Copy `n` bytes of `src` into `dst` at `off`.
void pw_copy_into -> @PEBuf dst, int off, @char src, int n {
    @char d = dst.data;
    int i = 0;
    while i < n {
        d[off + i] = src[i];
        i = i + 1;
    }
}

!!! The headers of the image, written into `buf` at the offsets the PE format
!!! fixes. The DOS header, the DOS stub, the NT signature, the optional header and
!!! the section table.
void pw_build_headers -> @PEBuf buf, int hdr_sz, int t_raw, int r_raw, int i_raw,
                        int e_raw, int t_ofs, int r_ofs, int i_ofs, int e_ofs,
                        bool has_edata {
    int last_rva = pw_idata_rva;
    int last_sz = pw_idata.len;
    if has_edata {
        last_rva = pw_edata_rva;
        last_sz = pw_edata.len;
    }
    int img_end = pw_align_1000(last_rva + last_sz);

    pb_put16(buf, 0x00, 0x5A4D);
    pb_put16(buf, 0x02, 0x90);
    pb_put16(buf, 0x04, 3);
    pb_put16(buf, 0x08, 4);
    pb_put16(buf, 0x0A, 0);
    pb_put16(buf, 0x0C, 0xFFFF);
    pb_put16(buf, 0x10, 0xB8);
    pb_put16(buf, 0x18, 0x40);
    pb_put32(buf, 0x3C, 0x80);
    !!! The "This program cannot be run in DOS mode" stub, byte for byte from
    !!! 0x40: it cannot be a string literal, because the language's escapes have no
    !!! hexadecimal form and the stub carries bytes a text cannot hold. It is built
    !!! in a buffer of its own and copied in, because the header buffer is already
    !!! sized and appending to it would write past the headers.
    @PEBuf dosstub = pw_new_buf();
    pb_push(dosstub, 0x0E);
    pb_push(dosstub, 0x1F);
    pb_push(dosstub, 0xBA);
    pb_push(dosstub, 0x0E);
    pb_push(dosstub, 0x00);
    pb_push(dosstub, 0xB4);
    pb_push(dosstub, 0x09);
    pb_push(dosstub, 0xCD);
    pb_push(dosstub, 0x21);
    pb_push(dosstub, 0xB8);
    pb_push(dosstub, 0x01);
    pb_push(dosstub, 0x4C);
    pb_push(dosstub, 0xCD);
    pb_push(dosstub, 0x21);
    pb_push(dosstub, 0x54);
    pb_push(dosstub, 0x68);
    pb_push(dosstub, 0x69);
    pb_push(dosstub, 0x73);
    pb_push(dosstub, 0x20);
    pb_push(dosstub, 0x70);
    pb_push(dosstub, 0x72);
    pb_push(dosstub, 0x6F);
    pb_push(dosstub, 0x67);
    pb_push(dosstub, 0x72);
    pb_push(dosstub, 0x61);
    pb_push(dosstub, 0x6D);
    pb_push(dosstub, 0x20);
    pb_push(dosstub, 0x63);
    pb_push(dosstub, 0x61);
    pb_push(dosstub, 0x6E);
    pb_push(dosstub, 0x6E);
    pb_push(dosstub, 0x6F);
    pb_push(dosstub, 0x74);
    pb_push(dosstub, 0x20);
    pb_push(dosstub, 0x62);
    pb_push(dosstub, 0x65);
    pb_push(dosstub, 0x20);
    pb_push(dosstub, 0x72);
    pb_push(dosstub, 0x75);
    pb_push(dosstub, 0x6E);
    pb_push(dosstub, 0x20);
    pb_push(dosstub, 0x69);
    pb_push(dosstub, 0x6E);
    pb_push(dosstub, 0x20);
    pb_push(dosstub, 0x44);
    pb_push(dosstub, 0x4F);
    pb_push(dosstub, 0x53);
    pb_push(dosstub, 0x20);
    pb_push(dosstub, 0x6D);
    pb_push(dosstub, 0x6F);
    pb_push(dosstub, 0x64);
    pb_push(dosstub, 0x65);
    pb_push(dosstub, 0x2E);
    pb_push(dosstub, 0x0D);
    pb_push(dosstub, 0x0D);
    pb_push(dosstub, 0x0A);
    pb_push(dosstub, 0x24);
    pb_push(dosstub, 0x00);
    pb_push(dosstub, 0x00);
    pb_push(dosstub, 0x00);
    pb_push(dosstub, 0x00);
    pb_push(dosstub, 0x00);
    pb_push(dosstub, 0x00);
    pb_push(dosstub, 0x00);
    pw_copy_into(buf, 0x40, dosstub.data, dosstub.len);

    pb_put32(buf, 0x80, 0x00004550);
    pb_put16(buf, 0x84, 0x8664);
    pb_put16(buf, 0x86, 3);
    if has_edata {
        pb_put16(buf, 0x86, 4);
    }
    pb_put16(buf, 0x94, 0xF0);
    int file_chars = 0x0002 | 0x0020 | 0x0004 | 0x0008;
    if pw_type == 1 {
        file_chars = file_chars | 0x2000;
    }
    pb_put16(buf, 0x96, file_chars);

    int o = 0x98;
    pb_put16(buf, o, 0x020B);
    pb_put32(buf, o + 16, PEW_TEXT_RVA);
    pb_put32(buf, o + 20, PEW_TEXT_RVA);
    int x = o + 24;
    pb_put64(buf, x + 0, 0x140000000);
    pb_put32(buf, x + 8, 0x1000);
    pb_put32(buf, x + 12, 0x200);
    pb_put16(buf, x + 16, 6);
    pb_put16(buf, x + 18, 0);
    pb_put16(buf, x + 20, 0);
    pb_put16(buf, x + 22, 0);
    pb_put16(buf, x + 24, 6);
    pb_put16(buf, x + 26, 0);
    pb_put32(buf, x + 32, img_end);
    pb_put32(buf, x + 36, hdr_sz);
    !!! A window program that asked for no console is marked as a GUI one: that is
    !!! the field Windows reads to decide whether to allocate a console. Anything
    !!! else stays a console image.
    int subsys = 3;
    if pw_no_window_con != 0 && pw_type == 2 {
        subsys = 2;
    }
    pb_put16(buf, x + 44, subsys);
    int dll_flags = 0x0040 | 0x0020;
    if pw_type == 1 {
        dll_flags = dll_flags | 0x2000;
    } else {
        dll_flags = dll_flags | 0x0100;
    }
    pb_put16(buf, x + 46, dll_flags);
    !!! SizeOfStackReserve / SizeOfStackCommit (x + 48 and x + 56), then
    !!! SizeOfHeapReserve / SizeOfHeapCommit (x + 64 and x + 72). The 64-bit
    !!! optional header keeps 8 bytes for each, and the stack pair comes first:
    !!! writing the heap sizes at the stack offsets left SizeOfStackReserve and its
    !!! commit zero, and an image whose stack cannot grow dies as soon as a frame is
    !!! deeper than the first page. One page is committed and the rest is reserved:
    !!! the loader commits more on demand, and a reserve costs address space, not
    !!! memory. The reserve is what a program that walks a tree recursively may use,
    !!! so it is generous: this compiler compiles itself, and its own statement
    !!! walkers go one frame deeper for every nested `if` of the file they read. A
    !!! megabyte ran out on a function with ninety `elif` arms (runtime/bwin.b
    !!! writes one), which is why the reserve is 32 of them.
    pb_put64(buf, x + 48, 0x2000000);
    pb_put64(buf, x + 56, 0x1000);
    pb_put64(buf, x + 64, 0x100000);
    pb_put64(buf, x + 72, 0x1000);
    pb_put32(buf, x + 84, 16);

    if has_edata {
        pb_put32(buf, 0x108, pw_edata_rva);
        pb_put32(buf, 0x10C, pw_edata.len);
    }
    pb_put32(buf, 0x110, pw_idata_rva);
    pb_put32(buf, 0x114, pw_idata.len);

    int s = 0x188;
    pb_put32(buf, s, 0x7865742E);
    pb_put32(buf, s + 4, 0x00000074);
    pb_put32(buf, s + 8, pw_rdata_rva - PEW_TEXT_RVA);
    pb_put32(buf, s + 12, PEW_TEXT_RVA);
    pb_put32(buf, s + 16, t_raw);
    pb_put32(buf, s + 20, t_ofs);
    pb_put32(buf, s + 36, 0xE0000020);
    s = s + 40;
    pb_put32(buf, s, 0x6164722E);
    pb_put32(buf, s + 4, 0x00006174);
    pb_put32(buf, s + 8, pw_rdata.len);
    pb_put32(buf, s + 12, pw_rdata_rva);
    pb_put32(buf, s + 16, r_raw);
    pb_put32(buf, s + 20, r_ofs);
    pb_put32(buf, s + 36, 0x40000040);
    s = s + 40;
    pb_put32(buf, s, 0x6164692E);
    pb_put32(buf, s + 4, 0x00006174);
    pb_put32(buf, s + 8, pw_idata.len);
    pb_put32(buf, s + 12, pw_idata_rva);
    pb_put32(buf, s + 16, i_raw);
    pb_put32(buf, s + 20, i_ofs);
    pb_put32(buf, s + 36, 0xC0000040);
    s = s + 40;
    if has_edata {
        pb_put32(buf, s, 0x6164652E);
        pb_put32(buf, s + 4, 0x00006174);
        pb_put32(buf, s + 8, pw_edata.len);
        pb_put32(buf, s + 12, pw_edata_rva);
        pb_put32(buf, s + 16, e_raw);
        pb_put32(buf, s + 20, e_ofs);
        pb_put32(buf, s + 36, 0x40000040);
    }
}

!!! The image, written to `path`. 0 on success.
int pw_write -> str path {
    if pw_idata.len == 0 {
        pw_finalize_imports();
    }
    if pw_type == 1 {
        pw_finalize_exports();
    }
    !!! The layout the code was patched against: recomputed here so a writer called
    !!! on its own still lays the sections out the same way.
    pw_plan_layout(0);

    bool has_edata = pw_edata.len != 0;
    int nsec = 3;
    if has_edata {
        nsec = 4;
    }
    int hdr_sz = pw_align_200(0x200 + nsec * 40);
    int t_raw = pw_align_200(pw_text.len);
    int r_raw = pw_align_200(pw_rdata.len);
    int i_raw = pw_align_200(pw_idata.len);
    int e_raw = 0;
    if has_edata {
        e_raw = pw_align_200(pw_edata.len);
    }
    int t_ofs = hdr_sz;
    int r_ofs = t_ofs + t_raw;
    int i_ofs = r_ofs + r_raw;
    int e_ofs = i_ofs + i_raw;

    @PEBuf buf = pw_new_buf();
    int total = hdr_sz + t_raw + r_raw + i_raw + e_raw;
    pb_reserve(buf, total);
    @char bd = buf.data;
    int i = 0;
    while i < total {
        bd[i] = (char)0;
        i = i + 1;
    }
    buf.len = total;
    pw_build_headers(buf, hdr_sz, t_raw, r_raw, i_raw, e_raw, t_ofs, r_ofs, i_ofs,
                     e_ofs, has_edata);
    pw_copy_into(buf, t_ofs, pw_text.data, pw_text.len);
    pw_copy_into(buf, r_ofs, pw_rdata.data, pw_rdata.len);
    pw_copy_into(buf, i_ofs, pw_idata.data, pw_idata.len);
    if has_edata {
        pw_copy_into(buf, e_ofs, pw_edata.data, pw_edata.len);
    }

    @void f = getFile(path, "w");
    if f == null {
        return 1;
    }
    int written;
    WriteFile(f, (str)buf.data, buf.len, @written, null);
    CloseHandle(f);
    return 0;
}
