#once
!~
 ~  bootstrap/backend/codegen_static.b: the static form of a DLL.
 ~
 ~  `-static-runtime` and `-static` place
 ~  the code of a DLL into the executable instead of importing it. cmp builds those
 ~  DLLs itself, so it writes what an embedder needs beside every DLL it produces,
 ~  as meta/<dll>.bst:
 ~
 ~    "BSTA" u16 version u16 reserved
 ~    u32 code_size        code bytes
 ~    u32 export_count     per export: u8 name_len, name, u32 .text offset
 ~    u32 import_count     per import: u32 disp_pos, u32 dll_len+NUL, dll,
 ~                                     u32 func_len+NUL, func
 ~    u32 rdata_size       rdata bytes
 ~    u32 reloc_count      per reloc: u32 disp_pos, u32 offset within .rdata
 ~
 ~  The code is copied into the image as it is. Everything inside it is addressed
 ~  relative to its own position, so it survives the move unchanged. Two things do
 ~  not, and that is what the last two tables are for: the calls the DLL makes to
 ~  its own imports go through an IAT that does not exist here, and references to
 ~  its .rdata are relative to the .rdata of the DLL.
 ~!

#head "cg_heads"
#head "cmp_file"

!!! The version the side file carries, and the one the reader accepts.
int kBstaVersion = 0x0100;

!!! Append one reference to the .rdata of the image being built, in the order the
!!! code generator made them. The tail is kept beside the head: the toolchain pushes
!!! onto a a chain, and a walk to the end for every one of the thousands of
!!! string references a compile makes is the quadratic cost that translation
!!! would otherwise carry.
void cg_rdata_ref_add -> int disp_pos, int rdata_off {
    CgEmbeddedRdataRef proto;
    @CgEmbeddedRdataRef r;
    cg_balloc(@r, size proto);
    r.disp_pos = disp_pos;
    r.rdata_off = rdata_off;
    r.next = null;
    if cg_rdata_refs == null {
        cg_rdata_refs = r;
    } else {
        cg_rdata_refs_tail.next = r;
    }
    cg_rdata_refs_tail = r;
}

!!! Append one embedded DLL, in the order they were loaded.
void cg_embedded_add -> @CgEmbeddedDll ed {
    if cg_embedded == null {
        cg_embedded = ed;
    } else {
        cg_embedded_tail.next = ed;
    }
    cg_embedded_tail = ed;
}

!!! The side file of the DLL just built, which is what -m writes and what a later
!!! -static-runtime reads.
bool cg_write_static_dll -> str out_path {
    cm_mkdir(cm_side_write_dir("meta"));
    str path = cm_side_write_path("meta", cm_base_name(out_path) + ".bst");
    if !cm_open_write(path) {
        return false;
    }
    cm_w8c('B');
    cm_w8c('S');
    cm_w8c('T');
    cm_w8c('A');
    cm_w16(kBstaVersion);
    cm_w16(0);

    @char code = cg_code_data();
    int code_len = cg_code_size();
    cm_w32(code_len);
    cm_wraw(code, code_len);

    !!! The exported names and where their code sits: the same set cmp puts in the
    !!! DLL's export table. A local function is not one of them. The walk is in the
    !!! order the bodies were emitted, which is the order the toolchain writes them in.
    int export_count = 0;
    int fid = cg_func_first();
    while fid != 0 {
        if !cg_is_local(cg_func_name(fid)) {
            export_count = export_count + 1;
        }
        fid = cg_func_next(fid);
    }
    cm_w32(export_count);
    fid = cg_func_first();
    while fid != 0 {
        str fname = cg_func_name(fid);
        if !cg_is_local(fname) {
            cm_w8(pe_len(fname));
            @char np = (@char)fname;
            cm_wraw(np, pe_len(fname));
            cm_w32(cg_func_off(fid));
        }
        fid = cg_func_next(fid);
    }

    !!! Every place the DLL's own code reaches one of its imports. Two shapes exist:
    !!! the calls cmp emitted itself (call [rip+disp32], disp at pos+2) and the
    !!! import stubs of the linked library code (same instruction, recorded at the
    !!! instruction instead of at the displacement).
    int import_count = 0;
    @CgCallPatch cp = cg_call_patches;
    while cp != null {
        import_count = import_count + 1;
        cp = cp.next;
    }
    @CgBlib b = cg_blibs;
    @CmpIntNode off = cg_blib_text_off_list;
    while b != null && off != null {
        @CgBlibImport bi = b.imports;
        while bi != null {
            import_count = import_count + 1;
            bi = bi.next;
        }
        b = b.next;
        off = off.next;
    }
    cm_w32(import_count);
    cp = cg_call_patches;
    while cp != null {
        cm_w32(cp.pos);
        cm_wstr(pw_import_dll(cp.import_idx));
        cm_wstr(pw_import_func(cp.import_idx));
        cp = cp.next;
    }
    b = cg_blibs;
    off = cg_blib_text_off_list;
    while b != null && off != null {
        @CgBlibImport bi2 = b.imports;
        while bi2 != null {
            cm_w32((int)off.v + bi2.off + 2);
            cm_wstr(bi2.dll);
            cm_wstr(bi2.fnc);
            bi2 = bi2.next;
        }
        b = b.next;
        off = off.next;
    }

    int rdata_size = pw_rdata_size();
    cm_w32(rdata_size);
    if rdata_size > 0 {
        cm_wraw(pw_rdata_data(), rdata_size);
    }

    int reloc_count = 0;
    @CgEmbeddedRdataRef rc = cg_rdata_refs;
    while rc != null {
        reloc_count = reloc_count + 1;
        rc = rc.next;
    }
    cm_w32(reloc_count);
    rc = cg_rdata_refs;
    while rc != null {
        cm_w32(rc.disp_pos);
        cm_w32(rc.rdata_off);
        rc = rc.next;
    }
    return true;
}

!!! The code of `dll` and everything needed to place it into this image. A DLL
!!! already embedded is not read twice.
bool cg_load_embedded_dll -> str dll {
    @CgEmbeddedDll e = cg_embedded;
    while e != null {
        if pe_eq(e.dll, dll) {
            return true;
        }
        e = e.next;
    }
    str leaf = cm_base_name(dll);
    str data = cm_open_side("meta", leaf + ".bst");
    if data == null {
        return false;
    }
    cm_walk(data);
    if data[0] != 'B' || data[1] != 'S' || data[2] != 'T' || data[3] != 'A' {
        return false;
    }
    cm_pos = 4;
    int version = cm_u16();
    cm_u16();
    if (version != kBstaVersion) {
        return false;
    }

    CgEmbeddedDll proto;
    @CgEmbeddedDll ed;
    cg_balloc(@ed, size proto);
    ed.dll = leaf;
    ed.code = pw_new_buf();
    ed.syms = null;
    ed.imports = null;
    ed.rdata = pw_new_buf();
    ed.rdata_refs = null;
    ed.text_off = 0;
    ed.rdata_off = 0;
    ed.next = null;

    int code_size = cm_u32();
    pb_add_raw(ed.code, cm_at(cm_pos), code_size);
    cm_pos = cm_pos + code_size;

    int export_count = cm_u32();
    int i = 0;
    while i < export_count {
        int n = cm_u8();
        str name = cm_take(n);
        int off = cm_u32();
        CgBlibSym sproto;
        @CgBlibSym s;
        cg_balloc(@s, size sproto);
        s.name = name;
        s.off = off;
        s.next = ed.syms;
        ed.syms = s;
        i = i + 1;
    }

    int import_count = cm_u32();
    @CgEmbeddedImport tail = null;
    i = 0;
    while i < import_count {
        CgEmbeddedImport iproto;
        @CgEmbeddedImport im;
        cg_balloc(@im, size iproto);
        im.disp_pos = cm_u32();
        im.dll = cm_rstr();
        im.fnc = cm_rstr();
        im.next = null;
        if ed.imports == null {
            ed.imports = im;
        } else {
            tail.next = im;
        }
        tail = im;
        i = i + 1;
    }

    int rdata_size = cm_u32();
    pb_add_raw(ed.rdata, cm_at(cm_pos), rdata_size);
    cm_pos = cm_pos + rdata_size;

    int reloc_count = cm_u32();
    @CgEmbeddedRdataRef rtail = null;
    i = 0;
    while i < reloc_count {
        CgEmbeddedRdataRef rproto;
        @CgEmbeddedRdataRef r;
        cg_balloc(@r, size rproto);
        r.disp_pos = cm_u32();
        r.rdata_off = cm_u32();
        r.next = null;
        if ed.rdata_refs == null {
            ed.rdata_refs = r;
        } else {
            rtail.next = r;
        }
        rtail = r;
        i = i + 1;
    }

    !!! The imports of an embedded DLL belong to this image now. Which of them really
    !!! need an IAT slot is decided by cg_register_embedded_imports, once the whole
    !!! set of embedded DLLs is known: one that another embedded DLL provides is
    !!! called directly instead, and an import descriptor for it would keep a
    !!! dependency on that DLL alive in an image that no longer has one.
    cg_embedded_add(ed);
    return true;
}

void cg_register_embedded_imports {
    @CgEmbeddedDll ed = cg_embedded;
    while ed != null {
        @CgEmbeddedImport im = ed.imports;
        while im != null {
            !!! A function provided inside this image is called directly.
            if cg_embedded_text_off(im.fnc) == 0 {
                str key = im.dll + "!" + im.fnc;
                if cg_strint_find(cg_blib_import_idx, key) == null {
                    cg_blib_import_idx = cg_strint_set(cg_blib_import_idx, key,
                                                       pw_add_import(im.dll, im.fnc));
                }
            }
            im = im.next;
        }
        ed = ed.next;
    }
}

!!! Where the code of `name` sits in this image, or 0 when no embedded DLL defines
!!! it. The offset is the one recorded when that DLL's code was emitted.
int cg_embedded_text_off -> str name {
    @CgEmbeddedDll e = cg_embedded;
    while e != null {
        @CgBlibSym s = e.syms;
        while s != null {
            if pe_eq(s.name, name) {
                return e.text_off + s.off;
            }
            s = s.next;
        }
        e = e.next;
    }
    return 0;
}

void cg_note_rdata_ref -> int disp_pos, int rdata_rva {
    !!! The side file wants the offset inside .rdata, not the RVA: that is what
    !!! survives being placed at a different address in another image.
    cg_rdata_ref_add(disp_pos, rdata_rva - pw_rdata_base());
}

void cg_patch_embedded {
    !!! The code of this image. Every reference it made into .rdata was registered
    !!! with its offset inside that section, so it can be rewritten against the base
    !!! the layout ended up at. Without this the references kept the displacement of
    !!! the assumed base and a .text over 64 KiB moved .rdata out from under them,
    !!! which sent them into the middle of the code.
    @CgEmbeddedRdataRef r = cg_rdata_refs;
    while r != null {
        int target = pw_rdata_base() + r.rdata_off;
        int disp_rva = PEW_TEXT_RVA + r.disp_pos;
        em_put32(r.disp_pos, target - (disp_rva + 4));
        r = r.next;
    }
    @CgEmbeddedDll ed = cg_embedded;
    while ed != null {
        !!! Calls the embedded code makes to its own imports.
        @CgEmbeddedImport im = ed.imports;
        while im != null {
            int target = cg_embedded_text_off(im.fnc);
            if target != 0 {
                !!! The function is in this image as well, so call it directly: an
                !!! embedded DLL that was built against the runtime DLL imports the
                !!! runtime, and going through an IAT slot there would put the DLL
                !!! back as a load-time dependency. `call [rip+disp32]` is six bytes
                !!! and `call rel32` five, so the sixth becomes a nop.
                int site = ed.text_off + im.disp_pos - 2;
                em_put8(site, 0xE8);
                em_put32(site + 1, target - (site + 5));
                em_put8(site + 5, 0x90);
                im = im.next;
                continue;
            }
            @CgStrInt it = cg_strint_find(cg_blib_import_idx, im.dll + "!" + im.fnc);
            if it != null {
                int iat_rva = pw_get_iat(it.v);
                int disp_rva = PEW_TEXT_RVA + ed.text_off + im.disp_pos;
                em_put32(ed.text_off + im.disp_pos, iat_rva - (disp_rva + 4));
            }
            im = im.next;
        }
        !!! References into the .rdata that travelled with the code.
        @CgEmbeddedRdataRef er = ed.rdata_refs;
        while er != null {
            int target = pw_rdata_base() + ed.rdata_off + er.rdata_off;
            int disp_rva = PEW_TEXT_RVA + ed.text_off + er.disp_pos;
            em_put32(ed.text_off + er.disp_pos, target - (disp_rva + 4));
            er = er.next;
        }
        ed = ed.next;
    }
}
