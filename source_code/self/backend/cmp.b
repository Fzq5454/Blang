!~
 ~  bootstrap/cmp.b: the .r compiler of the self-hosted toolchain.
 ~
 ~  This is the .r compiler: it reads a .r file, builds the image the file
 ~  describes and writes it out. The backend modules are the ones under
 ~  bootstrap/backend, and this driver is cmp.b together with the two entry
 ~  points of the image writer.
 ~
 ~  Build:
 ~    bin\blang.exe bootstrap/cmp.b -o bootstrap/bin/cmp.exe ^
 ~        -P bootstrap/backend -system kernel32 -dbrtm -dbfile -dbstr
 ~!

!!! The release this driver prints with `--version`: the number, the day it was
!!! built (YYYYMMDD) and the name it was built by, the same three the driver of
!!! the compiler substitutes. They stand together so that a release is bumped in
!!! the same three lines in both drivers; the cmp line prints the number and the
!!! name. `#replace` is how a driver of this toolchain holds them, and they are
!!! constants: the two toolchains have to print the same text.
#replace BLANG_VERSION "1.0.0"
#replace BLANG_BUILD_DATE "20261004"
#replace BLANG_BUILD_AUTHOR "Fzq5454"

#head "stdsrt"
#head "fileio"
#head "cmp_types"
#head "cmp_arena"
#head "cmp_ir"
#head "cmp_text"
#head "cmp_index"
#head "cmp_file"
#head "emitter"
#head "pe_writer"
#head "cg_state"
#head "cg_tables"
#head "codegen_helpers"
#head "codegen_intern"
#head "codegen_diag"
#head "codegen_setters"
#head "codegen_mem"
#head "codegen_small"
#head "codegen_stack"
#head "codegen_emit_ref"
#head "codegen_loop"
#head "codegen_stmt"
#head "codegen_ret"
#head "codegen_public"
#head "codegen_resolve"
#head "codegen_declared"
#head "codegen_flow"
#head "codegen_binop"
#head "codegen_closure"
#head "codegen_bspread"
#head "codegen_args"
#head "codegen_call_gen"
#head "codegen_func_call"
#head "codegen_func"
#head "codegen_expr"
#head "codegen_cast"
#head "codegen_cast_expr"
#head "codegen_gen"
#head "codegen_blib"
#head "codegen_try"
#head "codegen_static"
#head "bmeta"
#head "tokenizer"
#head "parser"
#head "parser_type"
#head "parser_expr"
#head "parser_declared"
#head "parser_cast"
#head "parser_flow"
#head "parser_call"
#head "parser_func"
#head "vector"

!!! The arguments of the command line, the program name first, so the index of an
!!! argument is the `argv[]` index.
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
        cg_balloc(@cell, n + 1);
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

!!! ---- BLANG_HOME ----

!!! The directory the running compiler stands in, which is what BLANG_HOME means to
!!! the compiler : the metadata and library side files are looked
!!! for under it first, so the driver has to publish it whatever the working
!!! directory is. the toolchain sets it from the module path and leaves it in the
!!! environment for cmp.exe; this implementation does the same, so the two file helpers of
!!! cmp_file.b find the same files.
void cmp_setup_home {
    @void cell;
    cg_balloc(@cell, 1024);
    @char p = (@char)cell;
    int n = GetModuleFileNameA(null, (str)cell, 1024);
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
            SetEnvironmentVariableA("BLANG_HOME", pe_sub((str)cell, 0, slash));
        }
    }
}

!!! ---- the two names a DLL can be asked for by ----

!!! The name a system DLL is imported by: `-system kernel32` and
!!! `-system kernel32.dll` both mean kernel32.dll. A name whose last extension is
!!! not `dll` gets one, so a contract name like `api-ms-win-core-file-l1-1-0` works
!!! as well.
str cmp_lower -> str s {
    @void cell;
    cg_balloc(@cell, pe_len(s) + 1);
    @char d = (@char)cell;
    int i = 0;
    int n = pe_len(s);
    while i < n {
        char c = s[i];
        if c >= 'A' && c <= 'Z' {
            c = (char)((int)c + 32);
        }
        d[i] = c;
        i = i + 1;
    }
    d[n] = (char)0;
    return (str)cell;
}

str cmp_system_dll_name -> str name {
    int dot = -1;
    int i = 0;
    int n = pe_len(name);
    while i < n {
        if name[i] == '.' {
            dot = i;
        }
        i = i + 1;
    }
    str ext = "";
    if dot != -1 {
        ext = cmp_lower(pe_sub(name, dot + 1, n - dot - 1));
    }
    if !pe_eq(ext, "dll") {
        return name + ".dll";
    }
    return name;
}

!!! The DLL a `-d<name>` option names. The project marks its DLLs with a `lib`
!!! prefix - `libbstr.dll` is the compiler's own - so `-dbrtm` is libbrtm.dll. A
!!! name that already carries the prefix or the extension is left alone.
str cmp_dyn_dll_name -> str name {
    str n = name;
    if pe_len(n) < 3 || !pe_eq(pe_sub(n, 0, 3), "lib") {
        n = "lib" + n;
    }
    int len = pe_len(n);
    if len < 4 || !pe_eq(pe_sub(n, len - 4, 4), ".dll") {
        n = n + ".dll";
    }
    return n;
}

!!! Whether `s` starts with `p`.
bool cmp_prefix -> str s, str p {
    int n = pe_len(p);
    if pe_len(s) < n {
        return false;
    }
    return pe_eq(pe_sub(s, 0, n), p);
}

!!! The rest of `s` after the first `n` characters.
str cmp_rest -> str s, int n {
    return pe_sub(s, n, pe_len(s) - n);
}

!!! ---- the options ----

str g_infile = "";
str g_outfile = "a.exe";
str g_user_libs = "";
str g_link_dlls = "";
str g_embed_dlls = "";
str g_system_dlls = "";
bool g_no_runtime = false;
bool g_static_runtime = false;
int g_pe_type = 0;
int g_no_window_con = 0;
bool g_verbose = false;
bool g_debug_info = false;

!!! What a failed compile reports.
str g_error = "";

!!! A space-separated list grows by one name.
str cmp_list_add -> str list, str item {
    if pe_eq(list, "") {
        return item;
    }
    return list + " " + item;
}

!!! `cmp.exe: error: <msg>`, the prefix every diagnostic of the driver carries.
void cmp_fail -> str msg {
    system.err("cmp.exe: ");
    ux_color("red");
    system.err("error: ");
    ux_color("reset");
    system.err(msg, "\n");
}

void cmp_help {
    system.out("Usage: cmp.exe [options] <input.r>\n");
    system.out("\n");
    system.out("Options:\n");
    system.out("  -o <file>         Write output to <file> (default: a.exe)\n");
    system.out("  -l<name>          Link lib/<name>.lib (may repeat)\n");
    system.out("  -d<name>          Dynamically link lib<name>.dll (may repeat)\n");
    system.out("                    e.g. -dbrtm is libbrtm.dll\n");
    system.out("  --embed=<dll>     Place the code of that DLL into the output instead of\n");
    system.out("                    importing it (may repeat). Needs meta/<dll>.bst, the\n");
    system.out("                    side file written when the DLL was built.\n");
    system.out("  --static-runtime  Place the runtime (libbrtm.dll) into the output.\n");
    system.out("  --type=<type>     Set PE type: console, dll, win (default: console)\n");
    system.out("                    type=<type> is the same thing, which is how a `#to` line\n");
    system.out("                    names it (the line's text is passed on as it was written)\n");
    system.out("  -NO-WINDOW-CON    A window program (--type=win) is written as a GUI\n");
    system.out("                    program and gets no console window. Only valid with\n");
    system.out("                    --type=win: a console program cannot be built without\n");
    system.out("                    one, and saying this for anything else is an error.\n");
    system.out("  --link=<dll>      Link against a BLang DLL (may repeat)\n");
    system.out("  --system=<dll>    Import a system DLL, e.g. kernel32 (may repeat).\n");
    system.out("                    The .dll extension is added when it is missing.\n");
    system.out("  -system <dll>     Same as --system=<dll>\n");
    system.out("  --no-runtime      Link no runtime at all: what a runtime DLL's own build\n");
    system.out("                    needs. blang.exe no longer passes this; it is reached\n");
    system.out("                    through -CMP,--no-runtime.\n");
    system.out("  -nopt-reg         Do not use the register shortcuts: an operand that can\n");
    system.out("                    be read straight into the register an operation wants\n");
    system.out("                    goes through a temporary stack slot instead.\n");
    system.out("  -nopt-asm         Do not use the instruction-level shortcuts: a small\n");
    system.out("                    constant stays out of the instruction, a branch on a\n");
    system.out("                    comparison goes through 0/1, `s[i]` calls the runtime\n");
    system.out("                    and an allocation calls VirtualAlloc.\n");
    system.out("  -nopt             Both of the above. A program built this way behaves\n");
    system.out("                    the same; it is the code the back end writes before any\n");
    system.out("                    of those shortcuts, which is what a wrong result that\n");
    system.out("                    only appears with them is measured against.\n");
    system.out("  -p, -process      Show verbose compilation process\n");
    system.out("  -d, -debug        Embed debug info (BSYM) into the output\n");
    system.out("  -v, --version     Show version information\n");
    system.out("  --help            Show this help message\n");
    !!! the toolchain ends the help with `puts("\n")`, which writes two newlines: the blank
    !!! line after the last entry is the one the help ends with in both toolchains.
    system.out("\n\n");
}

!!! ---- registering the DLLs the program links against ----

!!! Every function the DLLs in `dlls` (a space-separated list) export is
!!! registered, so a call to one of them is emitted as an import. `system_names`
!!! adds the `.dll` fallback to each name, which is how a system DLL is named.
!!! `flag` is the option the list came from, so a failure says which one to look
!!! at. The signatures come from meta/<dll>.bmeta.
bool cmp_register_dlls -> str dlls, str flag, bool system_names {
    if pe_eq(dlls, "") {
        return true;
    }
    int p = 0;
    int n = pe_len(dlls);
    while p < n {
        while p < n && dlls[p] == ' ' {
            p = p + 1;
        }
        if p >= n {
            skip;
        }
        int start = p;
        while p < n && dlls[p] != ' ' {
            p = p + 1;
        }
        str dll = pe_sub(dlls, start, p - start);
        if system_names {
            dll = cmp_system_dll_name(dll);
        }
        @CgBmetaFunc bfs = cg_read_bmeta(dll);
        if bfs == null {
            g_error = dll + ": error: " + flag + ": cannot open 'meta/" +
                      cm_base_name(dll) + ".bmeta': .bmeta not found. Compile the DLL first with 'blang <src> -o <dll> [-m]'";
            return false;
        }
        @CgBmetaFunc bf = bfs;
        while bf != null {
            cg_register_dll_import(dll, bf.name, bf.param_types, bf.ret_type);
            bf = bf.next;
        }
    }
    return true;
}

!!! The DLLs whose code this image carries instead of importing it
!!! (--embed / --static-runtime). Their signatures come from the same .bmeta a
!!! -link DLL uses; what is read here is the side file with the code, the imports
!!! and the .rdata.
bool cmp_load_embedded -> str dlls {
    if pe_eq(dlls, "") {
        return true;
    }
    int p = 0;
    int n = pe_len(dlls);
    while p < n {
        while p < n && dlls[p] == ' ' {
            p = p + 1;
        }
        if p >= n {
            skip;
        }
        int start = p;
        while p < n && dlls[p] != ' ' {
            p = p + 1;
        }
        str dll = pe_sub(dlls, start, p - start);
        if !cg_load_embedded_dll(dll) {
            g_error = dll + ": error: no static form of '" + dll + "': meta/" +
                      cm_base_name(dll) + ".bst not found. It is written when the DLL is built with this compiler";
            return false;
        }
    }
    return true;
}

!!! ---- the BSYM debug block ----

void cmp_bsym_w32 -> @PEBuf b, int v {
    pb_push(b, v & 255);
    pb_push(b, (v >> 8) & 255);
    pb_push(b, (v >> 16) & 255);
    pb_push(b, (v >> 24) & 255);
}

!!! A text and the NUL that ends it, which is how a name in the block is stored.
void cmp_bsym_str -> @PEBuf b, str s {
    cmp_bsym_w32(b, pe_len(s) + 1);
    @char p = (@char)s;
    pb_add_raw(b, p, pe_len(s));
    pb_push(b, 0);
}

!!! The symbol table the debugger reads, appended to .rdata before the layout is
!!! planned: every function with its address, the source file, the variables of
!!! each function and the signature of each for the decompiler.
void cmp_embed_bsym {
    @PEBuf bsym = pw_new_buf();
    pb_pushc(bsym, 'B');
    pb_pushc(bsym, 'S');
    pb_pushc(bsym, 'Y');
    pb_pushc(bsym, 'M');
    int fcount = 0;
    int fid = cg_func_first();
    while fid != 0 {
        fcount = fcount + 1;
        fid = cg_func_next(fid);
    }
    cmp_bsym_w32(bsym, fcount);
    !!! In the order the bodies were emitted, which is the order the toolchain writes the
    !!! same table in.
    fid = cg_func_first();
    while fid != 0 {
        cmp_bsym_str(bsym, cg_func_name(fid));
        cmp_bsym_w32(bsym, cg_func_off(fid));
        fid = cg_func_next(fid);
    }
    !!! The source file, after the entries, which is where the reader expects it.
    cmp_bsym_str(bsym, g_infile);
    !!! The variables of each function, for the debugger.
    int vcount = 0;
    @CgStrNameOffs fv = cg_func_vars;
    while fv != null {
        vcount = vcount + 1;
        fv = fv.next;
    }
    cmp_bsym_w32(bsym, vcount);
    fv = cg_func_vars;
    while fv != null {
        cmp_bsym_str(bsym, fv.key);
        int nlocals = 0;
        @CgNameOff v = fv.v;
        while v != null {
            nlocals = nlocals + 1;
            v = v.next;
        }
        cmp_bsym_w32(bsym, nlocals);
        v = fv.v;
        while v != null {
            cmp_bsym_str(bsym, v.name);
            cmp_bsym_w32(bsym, v.off);
            v = v.next;
        }
        fv = fv.next;
    }
    !!! The signature of each function, for the decompiler: the return type and
    !!! every parameter with its name and its type.
    int scount = 0;
    @CgFuncSig sg = cg_func_signatures;
    while sg != null {
        scount = scount + 1;
        sg = sg.next;
    }
    cmp_bsym_w32(bsym, scount);
    sg = cg_func_signatures;
    while sg != null {
        cmp_bsym_str(bsym, sg.name);
        pb_push(bsym, cg_vbmeta_type(sg.ret_type));
        cmp_bsym_w32(bsym, cn_str_n(sg.param_names));
        @CmpStrNode pn = sg.param_names;
        @CmpTypeNode pt = sg.param_types;
        while pn != null {
            cmp_bsym_str(bsym, pn.s);
            if pt != null {
                pb_push(bsym, cg_vbmeta_type(pt.ty));
                pt = pt.next;
            } else {
                pb_push(bsym, 0);
            }
            pn = pn.next;
        }
        sg = sg.next;
    }
    pw_add_rdata_raw(bsym.data, bsym.len);
}

!!! ---- the compile ----

!!! The two entry points of the back end, in one: read the .r, parse it, generate the
!!! code, settle the layout, patch the code against it and write the image.
bool cmp_compile {
    !!! The index the parser's keyword table lives in, and the tables of the code
    !!! generator, are started before anything reads them.
    ix_init();
    @void f = getFile(g_infile, "rb");
    if f == null {
        g_error = g_infile + ": error: no such file or directory";
        return false;
    }
    str src = readFile(@f, -1, -1);
    tk_start(src, g_infile);
    cp_keywords_init();
    cp_start(g_infile);
    if !cp_parse() {
        g_error = cp_get_error();
        return false;
    }
    if tk_has_error() {
        g_error = tk_get_error();
        return false;
    }

    pw_create();
    !!! The generator's own state and its code buffer. the toolchain creates both with
    !!! the CodeGenerator (`CodeGenerator gen(pew, file)`); without this the
    !!! constants the code generator works with (the global bias, the temporary
    !!! allowance, the conversion ring) stay zero and the first instruction written
    !!! reads a buffer that was never allocated.
    cg_state_init(g_infile);
    em_buf_new();
    cg_set_no_runtime(g_no_runtime);
    cg_set_static_runtime(g_static_runtime);
    cg_set_user_libs(g_user_libs);
    cg_set_pe_type(g_pe_type);
    cg_set_debug_info(g_debug_info);

    !!! The linked DLLs: project ones from --link and system ones from --system,
    !!! then the ones whose code this image carries.
    if !cmp_register_dlls(g_link_dlls, "-link", false) {
        return false;
    }
    if !cmp_register_dlls(g_system_dlls, "-system", true) {
        return false;
    }
    if !cmp_load_embedded(g_embed_dlls) {
        return false;
    }

    cg_set_struct_types(cp_struct_types);
    if !cg_generate(cp_stmts) {
        g_error = cg_stmt_err;
        return false;
    }

    if g_verbose {
        system.out(cg_get_verbose_info());
    }

    !!! The import tables are built and the IAT RVAs assigned before the layout is
    !!! planned, because the code is patched against them.
    pw_finalize_imports();

    !!! The debug block goes into .rdata before the layout is planned: it adds bytes
    !!! to that section, and the planning has to see the final sizes.
    if cg_get_debug_info() {
        cmp_embed_bsym();
    }

    !!! Settle where the sections land now that the code and every .rdata byte are in
    !!! place, and only then patch: every displacement the code carries points into
    !!! .rdata or .idata, so it has to be written against the final layout.
    pw_plan_layout(cg_code_size());
    cg_patch_calls();
    cg_patch_blib_imports();
    cg_patch_embedded();

    pw_set_code(cg_code_data(), cg_code_size());
    pw_set_type(cg_get_pe_type());
    pw_set_no_window_con(g_no_window_con);
    !!! A DLL exports every function that is not local. The export table sorts the
    !!! names before it is written, so the order they are added in does not show.
    if cg_get_pe_type() == 1 {
        int kv = cg_func_first();
        while kv != 0 {
            str kname = cg_func_name(kv);
            if !cg_is_local(kname) {
                pw_add_export(kname, PEW_TEXT_RVA + cg_func_off(kv));
            }
            kv = cg_func_next(kv);
        }
    }
    if pw_write(g_outfile) != 0 {
        g_error = g_infile + ": error: failed to write '" + g_outfile + "'";
        return false;
    }

    !!! A DLL also writes its signatures and the side file that lets another image
    !!! place its code into itself (--embed / --static-runtime).
    if cg_get_pe_type() == 1 {
        cg_write_bmeta(g_outfile);
        cg_write_static_dll(g_outfile);
    }
    return true;
}

int main {
    ux_color_init();
    cmp_setup_home();
    str cmd = GetCommandLineA();
    if cmd == null {
        cmp_fail("cannot read the command line");
        return 1;
    }
    split_cmd(cmd);
    int argc = g_args.len;
    int i = 1;
    while i < argc {
        str a = g_args.get(i);
        if pe_eq(a, "--version") || pe_eq(a, "-v") {
            !!! Plain text, no color: the back end is driven by blang.exe and its
            !!! output is read next to the driver's messages. The number and the
            !!! name are the `#replace` macros at the head of this file.
            system.out("cmp.exe " + BLANG_VERSION + " from " + BLANG_BUILD_AUTHOR + "\n");
            return 0;
        } else if pe_eq(a, "--help") {
            cmp_help();
            return 0;
        } else if pe_eq(a, "-o") && i + 1 < argc {
            i = i + 1;
            g_outfile = g_args.get(i);
        } else if pe_eq(a, "--no-runtime") {
            g_no_runtime = true;
        } else if pe_eq(a, "-nopt") {
            !!! Both kinds of shortcut off: the code the back end wrote before any of
            !!! them, for measuring a result that only appears with them.
            cg_nopt_reg = true;
            cg_nopt_asm = true;
        } else if pe_eq(a, "-nopt-reg") {
            cg_nopt_reg = true;
        } else if pe_eq(a, "-nopt-asm") {
            cg_nopt_asm = true;
        } else if pe_eq(a, "--static-runtime") {
            !!! The runtime is embedded by the code generator itself, once, so the
            !!! driver only records the flag: adding it to the embed list here would
            !!! place it before the DLLs --embed names.
            g_static_runtime = true;
        } else if cmp_prefix(a, "--embed=") {
            g_embed_dlls = cmp_list_add(g_embed_dlls, cmp_rest(a, 8));
        } else if cmp_prefix(a, "-l") {
            g_user_libs = cmp_list_add(g_user_libs, cmp_rest(a, 2));
        } else if cmp_prefix(a, "--type=") || cmp_prefix(a, "type=") {
            !!! `type=dll` is how a `#to` line names the placement, and the line is
            !!! handed to this program as it was written (see gn_stage.b): the bare
            !!! spelling and the `--type=` one ask for the same thing.
            int nskip = 5;
            if cmp_prefix(a, "--type=") {
                nskip = 7;
            }
            str t = cmp_rest(a, nskip);
            if pe_eq(t, "console") {
                g_pe_type = 0;
            } else if pe_eq(t, "dll") {
                g_pe_type = 1;
            } else if pe_eq(t, "win") {
                g_pe_type = 2;
            } else {
                cmp_fail("unknown type '" + t + "'");
                return 1;
            }
        } else if pe_eq(a, "-NO-WINDOW-CON") {
            g_no_window_con = 1;
        } else if pe_eq(a, "-p") || pe_eq(a, "-process") {
            g_verbose = true;
        } else if pe_eq(a, "-d") || pe_eq(a, "-debug") {
            g_debug_info = true;
        } else if cmp_prefix(a, "-d") {
            !!! -d<name>: dynamically link lib<name>.dll. The same as
            !!! --link=lib<name>.dll, spelled the way the project names its DLLs.
            g_link_dlls = cmp_list_add(g_link_dlls, cmp_dyn_dll_name(cmp_rest(a, 2)));
        } else if cmp_prefix(a, "--link=") {
            g_link_dlls = cmp_list_add(g_link_dlls, cmp_rest(a, 7));
        } else if cmp_prefix(a, "--system=") {
            g_system_dlls = cmp_list_add(g_system_dlls, cmp_rest(a, 9));
        } else if pe_eq(a, "-system") && i + 1 < argc {
            i = i + 1;
            g_system_dlls = cmp_list_add(g_system_dlls, g_args.get(i));
        } else if pe_len(a) > 0 && a[0] == '-' {
            cmp_fail("unknown option '" + a + "'");
            return 1;
        } else {
            g_infile = a;
        }
        i = i + 1;
    }

    if pe_eq(g_infile, "") {
        cmp_fail("no input file");
        return 1;
    }

    !!! A console is only in the way of a window program: the flag says the output
    !!! must not get one, and a console program cannot be built without one. The
    !!! check is here and not at the flag, because --type may come after it.
    if g_no_window_con != 0 && g_pe_type != 2 {
        cmp_fail("-NO-WINDOW-CON is only for a window program (--type=win)");
        return 1;
    }

    if g_verbose {
        @void cell;
        cg_balloc(@cell, 1024);
        int n = GetModuleFileNameA(null, (str)cell, 1024);
        if n > 0 && n < 1024 {
            system.out("COLLECT_CMPL=", (str)cell, "\n");
        }
        @void cell2;
        cg_balloc(@cell2, 1024);
        int an = GetFullPathNameA(g_infile, 1024, (str)cell2, null);
        if an > 0 && an < 1024 {
            system.out("TARGET=", (str)cell2, "\n");
        }
    }

    if !cmp_compile() {
        system.err(g_error, "\n");
        return 1;
    }
    return 0;
}
