#once
!~
 ~  bootstrap/backend/codegen_blib.b: linked libraries, symbol lookup and the import
 ~  thunks.
 ~
 ~  together with the `has_lib_sym`,
 ~  `emit_call_lib` and `emit_import_thunks` of codegen. A `lib/<name>.lib` is the
 ~  machine code of a runtime library plus the names it defines and the native
 ~  functions it calls; a program links one with -l.
 ~
 ~  A thunk sits between two conventions: a linked symbol is entered with its
 ~  arguments on the stack (or in rax/rdx for the two older helpers) and the Windows
 ~  x64 ABI wants them in rcx/rdx/r8/r9 with 32 bytes of shadow space. The thunk is
 ~  generated once, in the region the entry jump steps over, so the same symbol can
 ~  come from a linked library or from a DLL without the call site knowing which.
 ~!

#head "cg_heads"
#head "cmp_file"

!!! Is `name` provided by something the program links against: the code of a
!!! loaded lib/<name>.lib, or a function of a DLL the program imports?
bool cg_has_lib_sym -> str name {
    if cg_resolve_sym(name) != 0 {
        return true;
    }
    return cg_strint_find(cg_import_thunks, name) != null;
}

!!! Call such a symbol with the argument convention the code the compiler writes by
!!! itself sets up. A library symbol is entered directly; an imported DLL function
!!! goes through the thunk generated for it. A name provided by neither emits
!!! nothing and answers false, so the caller can fall back to its own "undefined
!!! reference" handling.
bool cg_emit_call_lib -> str name {
    int off = cg_resolve_sym(name);
    if off == 0 {
        @CgStrInt tit = cg_strint_find(cg_import_thunks, name);
        if tit == null {
            return false;
        }
        off = tit.v;
    }
    cg_emit_call_text(off);
    return true;
}

!!! A runtime entry point the compiler calls by itself, with the Windows x64
!!! convention (the arguments already in rcx/rdx/r8/r9, 40 bytes reserved under
!!! the call). The runtime is an ordinary import, or code placed into this image
!!! by -static-runtime; a program that links no runtime at all has neither, and
!!! keeps the kernel call it used to make.
bool cg_can_call_native -> str name {
    if cg_embedded_text_off(name) != 0 {
        return true;
    }
    if cg_dll_has(name) {
        return true;
    }
    return cg_resolve_sym(name) != 0;
}

void cg_emit_call_native -> str name {
    int emb = cg_embedded_text_off(name);
    if emb != 0 {
        cg_emit_call_text(emb);
        end;
    }
    if cg_dll_has(name) {
        cg_emit_call_import(cg_import_index(name));
        end;
    }
    cg_emit_call_text(cg_resolve_sym(name));
}

void cg_emit_alloc_block -> longlong bytes {
    em_mov_rax_imm64(bytes);
    cg_emit_alloc_rax();
}

!!! rax = a block of the size rax holds. VirtualAlloc answers whole pages: an
!!! eight-byte capture cell cost four kilobytes, and a self-hosted compile makes
!!! millions of those, so the pages and the faults they take were half the run.
!!! The runtime's pool hands out slices of a megabyte block instead, and -nopt-asm
!!! asks for the plain VirtualAlloc the else branch has always been.
void cg_emit_alloc_rax {
    em_sub_rsp_imm8(40);
    if !cg_nopt_asm && cg_can_call_native("_alloc_small") {
        em_mov_rcx_rax();
        cg_emit_call_native("_alloc_small");
    } else {
        em_mov_rdx_rax();
        em_db(0x31);
        em_db(0xC9);
        em_db(0x41);
        em_db(0xB8);
        em_db(0x00);
        em_db(0x30);
        em_db(0x00);
        em_db(0x00);
        em_db(0x41);
        em_db(0xB9);
        em_db(0x04);
        em_db(0x00);
        em_db(0x00);
        em_db(0x00);
        cg_emit_call_import(cg_idx_virtualalloc);
    }
    em_add_rsp_imm8(40);
}

!!! Append one name and its offset to a library's export list.
@CgBlibSym cb_sym_add -> @CgBlibSym head, str name, int off {    CgBlibSym proto;
    @CgBlibSym n;
    cg_balloc(@n, size proto);
    n.name = name;
    n.off = off;
    n.next = head;
    return n;
}

!!! Read `lib/<name>.lib`: the magic, the code size, the exported names with their
!!! offsets in that code, the native functions the code calls, and the code itself.
bool cg_load_blib -> str name {
    str data = cm_open_side("lib", name + ".lib");
    if data == null {
        return false;
    }
    if cm_len < 16 {
        return false;
    }
    cm_walk(data);
    if cm_u8() != 'B' || cm_u8() != 'L' || cm_u8() != 'I' || cm_u8() != 'B' {
        return false;
    }
    int cs = cm_u32();
    int ec = cm_u32();
    int ic = cm_u32();
    CgBlib proto;
    @CgBlib lib;
    cg_balloc(@lib, size proto);
    lib.code = pw_new_buf();
    lib.syms = null;
    lib.imports = null;
    lib.next = null;
    int i = 0;
    while i < ec {
        int nl = cm_u32();
        !!! The stored name carries its NUL, which is not part of it.
        str nm = cm_take(nl - 1);
        cm_pos = cm_pos + 1;
        int off = cm_u32();
        lib.syms = cb_sym_add(lib.syms, nm, off);
        i = i + 1;
    }
    @CgBlibImport tail = null;
    i = 0;
    while i < ic {
        int off = cm_u32();
        int dlen = cm_u32();
        str dll = cm_take(dlen - 1);
        cm_pos = cm_pos + 1;
        int flen = cm_u32();
        str fnc = cm_take(flen - 1);
        cm_pos = cm_pos + 1;
        CgBlibImport iproto;
        @CgBlibImport imp;
        cg_balloc(@imp, size iproto);
        imp.off = off;
        imp.dll = dll;
        imp.fnc = fnc;
        imp.next = null;
        if lib.imports == null {
            lib.imports = imp;
        } else {
            tail.next = imp;
        }
        tail = imp;
        i = i + 1;
    }
    pb_add_raw(lib.code, cm_at(cm_pos), cs);
    !!! The libraries are kept in the order they were linked: cg_resolve_sym reads
    !!! them side by side with the offsets of their code, and the toolchain pushes one at
    !!! the back.
    if cg_blibs == null {
        cg_blibs = lib;
    } else {
        @CgBlib t = cg_blibs;
        while t.next != null {
            t = t.next;
        }
        t.next = lib;
    }
    cg_loaded_libs = cn_str(cg_loaded_libs, name);
    return true;
}

!!! The offset in `.text` of `name`, or 0 when no loaded library defines it. The
!!! offset of a library's code within the region the entry jump steps over is the
!!! one recorded when that code was emitted, and the libraries are walked in the
!!! order they were emitted, so the two lists are read side by side.
int cg_resolve_sym -> str name {
    return ix_get(kIxLibSym, name, 1);
}

!!! Put every symbol of every loaded library in the index, with the offset its
!!! code ended up at. It has to run once the code is emitted (that is when the
!!! offset of a library's code is known) and before anything asks for a symbol:
!!! resolving a name by walking the libraries was done for every string operation
!!! the generated code performs.
void cg_index_lib_syms {
    @CgBlib b = cg_blibs;
    @CmpIntNode base = cg_blib_text_off_list;
    while b != null && base != null {
        @CgBlibSym s = b.syms;
        while s != null {
            !!! The first library that defines a name is the one that answers, which
            !!! is what walking them in this order did.
            if !ix_has(kIxLibSym, s.name) {
                ix_set(kIxLibSym, s.name, (int)base.v + s.off, 0, 0, 0, "");
            }
            s = s.next;
        }
        b = b.next;
        base = base.next;
    }
}

!!! Most linked library symbols take every argument on the stack: the caller pushes
!!! them right to left, so the callee reads arg1 at [rsp+8], arg2 at [rsp+16], and
!!! so on. Two older helpers were written to take their arguments in registers
!!! instead, and the code that calls them sets rax and rdx rather than pushing. A
!!! thunk for one of those has to read them from there.
bool cb_args_in_registers -> str name {
    return pe_eq(name, "itoa") || pe_eq(name, "_str_idx");
}

!!! One thunk per imported DLL function the program can reach.
void cg_emit_import_thunks -> @CgStrBool used {
    if cg_dll_imports == null {
        end;
    }
    !!! A thunk reads and writes the argument area relative to rsp, so the
    !!! frame-based temporary slots the surrounding body may have selected must not
    !!! apply here.
    int saved_temp_base = em_temp_base;
    int saved_temp_bias = em_temp_bias;
    em_temp_base = 0;
    em_temp_bias = 0;

    !!! The imports in the order they were registered, which is the order the toolchain
    !!! walks its own list in: the chain above is in reverse registration order and
    !!! a hash order is not reproducible, so the order the stubs (and the import
    !!! table they reach) are written in comes from the index.
    int kid = cg_dll_first();
    while kid != 0 {
        str kname = cg_dll_name(kid);
        !!! Only the imports the program actually reaches get a thunk. This used to be
        !!! every name in every linked signature file, which for kernel32 meant a thunk
        !!! for each of its thousands of declarations.
        if cg_set_has(used, kname) {
            @CgDllImport imp = cg_dll_lookup(kname);
            cg_import_thunks = cg_strint_set(cg_import_thunks, kname, em_tell());
            if cb_args_in_registers(kname) {
                !!! rax = arg1 and rdx = arg2, which is already where the ABI wants the
                !!! second one, so only the first has to move. 40 bytes: 32 of shadow
                !!! space and 8 of padding, because entering the thunk rsp is 8 bytes
                !!! off a 16-byte boundary.
                em_mov_rcx_rax();
                em_sub_rsp(40);
                !!! An embedded DLL's code is called directly; an imported one through
                !!! its IAT slot.
                int emb = cg_embedded_text_off(kname);
                if emb != 0 {
                    cg_emit_call_text(emb);
                } else {
                    cg_emit_call_import(cg_import_index(kname));
                }
                em_sub_rsp(0 - 40);
                em_ret();
                kid = cg_dll_next(kid);
                continue;
            }
            int n = cn_type_n(imp.param_types);
            int slots = 0;
            if n > 4 {
                slots = n - 4;
            }
            !!! Shadow space plus the stack arguments plus the 8 bytes of padding that
            !!! keeps rsp 16-byte aligned at the call.
            int frame = 40 + slots * 8;
            em_sub_rsp(frame);
            !!! The first four arguments, from their stack slots to the registers.
            int nreg = n;
            if nreg > 4 {
                nreg = 4;
            }
            int i = 0;
            while i < nreg {
                int src = frame + 8 + i * 8;
                VarType pt = cn_type_of(imp.param_types, i);
                if pt == FLOAT {
                    em_ldsd_rsp(src);
                    if i == 1 {
                        em_movsd_xmm1_xmm0();
                    } else if i == 2 {
                        em_db(0xF2);
                        em_db(0x0F);
                        em_db(0x10);
                        em_db(0xD0);
                    } else if i == 3 {
                        em_db(0xF2);
                        em_db(0x0F);
                        em_db(0x10);
                        em_db(0xD8);
                    }
                } else {
                    em_ld_rsp(src);
                    if i == 0 {
                        em_mov_rcx_rax();
                    } else if i == 1 {
                        em_mov_rdx_rax();
                    } else if i == 2 {
                        em_db(0x49);
                        em_db(0x89);
                        em_db(0xC0);
                    } else {
                        em_db(0x49);
                        em_db(0x89);
                        em_db(0xC1);
                    }
                }
                i = i + 1;
            }
            !!! The remaining arguments move up into the shadow-space layout the callee
            !!! expects. The source slots are above the space just reserved, so the two
            !!! areas cannot overlap.
            i = 4;
            while i < n {
                em_ld_rsp(frame + 8 + i * 8);
                em_st_rsp_rax(32 + (i - 4) * 8);
                i = i + 1;
            }
            int emb2 = cg_embedded_text_off(kname);
            if emb2 != 0 {
                cg_emit_call_text(emb2);
            } else {
                cg_emit_call_import(cg_import_index(kname));
            }
            em_sub_rsp(0 - frame);
            em_ret();
        }
        kid = cg_dll_next(kid);
    }

    em_temp_base = saved_temp_base;
    em_temp_bias = saved_temp_bias;
}
