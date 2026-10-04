!~
 ~  bootstrap/gn.b: the scheduler of the self-hosted toolchain.
 ~
 ~  The flow is the same
 ~  three programs: blang.exe parses the options and hands the work to gn.exe, gn.exe
 ~  runs the front end on the `.b` source and hands the `.r` text to cmp.exe, and
 ~  cmp.exe writes the PE image.
 ~
 ~  gn.exe is the stage that has the front end in it. blang.exe hands it the input
 ~  file and one argument that carries the output and, after a `;`, the links the
 ~  image needs:
 ~
 ~    gn.exe <input.b> "<output> ; --link=libbrtm.dll --system=kernel32.dll"
 ~
 ~  Two things do not fit in an argument and travel in the environment, which is how
 ~  the toolchain does it as well: BLANG_RIMP_FILE points at the list of
 ~  imported signatures (`extern=<name>:<type>`, one per function of every linked
 ~  DLL, tens of kilobytes for kernel32 alone), and BLANG_PREPROC carries the
 ~  preprocessor's environment - the -D/-U/-P names and the built-in conditions -
 ~  as the one-line encoding of preproc_env_encode. A run whose environment names
 ~  neither gets the compiler's own defaults, which is what a `.b` file handed
 ~  straight to gn.exe deserves.
 ~
 ~  Build:
 ~    bin\blang.exe bootstrap/gn.b -o bootstrap/bin/gn.exe ^
 ~        -P bootstrap/frontend -system kernel32 -dbrtm -dbfile -dbstr
 ~!

#head "stdsrt"
#head "text_buf"
#head "fileio"
#head "preproc_env"
#head "Chinese/chinese"
#head "lexer"
#head "builtins"
#head "struct_def"
#head "operator_table"
#head "parser"
#head "parser_error"
#head "parser_type"
#head "parser_expr"
#head "parser_primary"
#head "parser_call"
#head "parser_block"
#head "parser_declare"
#head "parser_assign"
#head "parser_stmt"
#head "parser_flow"
#head "parser_return"
#head "parser_throw"
#head "parser_try"
#head "parser_function"
#head "parser_enum"
#head "parser_bapi"
#head "parser_struct"
#head "parser_introduce"
#head "parser_package"
#head "clone"
#head "preprocessor"
#head "rgen_out"
#head "rgen_cache"
#head "rgen"
#head "rgen_helpers"
#head "rgen_sym"
#head "rgen_rtype"
#head "rgen_atypes"
#head "rgen_diag"
#head "rgen_type_note"
#head "rgen_emit"
#head "rgen_dtor"
#head "rgen_try"
#head "rgen_index"
#head "rgen_inheritance"
#head "rgen_walk"
#head "rgen_walk_scoped"
#head "rgen_freevars"
#head "rgen_lambda_gen"
#head "rgen_lambda"
#head "rgen_field_layout"
#head "rgen_field"
#head "rgen_field_chain"
#head "rgen_field_array"
#head "rgen_struct_method"
#head "rgen_struct_copy"
#head "rgen_params"
#head "rgen_normargs"
#head "rgen_declare"
#head "rgen_ctor"
#head "rgen_used"
#head "rgen_builtins"
#head "rgen_register_builtin"
#head "rgen_register"
#head "rgen_typecheck"
#head "rgen_check"
#head "rgen_check_call"
#head "rgen_check_expr"
#head "rgen_validate"
#head "rgen_static"
#head "rgen_package"
#head "rgen_resolve"
#head "rgen_resolve_varref"
#head "rgen_resolve_member"
#head "rgen_resolve_size"
#head "rgen_resolve_index"
#head "rgen_resolve_op"
#head "rgen_resolve_call"
#head "rgen_expr"
#head "rgen_stmt_struct"
#head "rgen_stmt_declare"
#head "rgen_stmt_call"
#head "rgen_stmt"
#head "rgen_bapi_emit"
#head "rgen_prepare_calls"
#head "rgen_rewrite_forward"
#head "rgen_overload"
#head "rgen_template"
#head "rgen_struct_template"
#head "rgen_generate"
#head "rgen_rewrite_operators"
#head "rgen_runtime"

!!! The pieces the two drivers share and the stage this one runs: the module
!!! directory and the way one program starts another, the front end on one file, and
!!! what cmp.exe is handed.
#head "driver_common"
#head "frontend_run"
#head "gn_stage"

!!! Whether a name in the environment is set to something, and the whole file a
!!! name points at. They stand here and not in driver_common.b, which blang.exe,
!!! gn.exe and cmp.exe all include: this scheduler is the only one that reads
!!! either - BLANG_VERBOSE, and the file BLANG_RIMP_FILE names when the imported
!!! signatures are too large for the environment - and a helper no program uses is
!!! what -W-nused reports as never used.
bool env_has -> str name {
    return pe_len(env_get(name)) > 0;
}

str env_file -> str name {
    str path = env_get(name);
    if path == "" {
        return "";
    }
    @void f = getFile(path, "rb");
    if f == null {
        return "";
    }
    str data = readFileA(@f, -1, -1);
    CloseHandle(f);
    if data == null {
        return "";
    }
    return data;
}

!!! What the source of one file is, read as text: the front end works on the text,
!!! the way gn.exe reads the whole file before it compiles it. The input
!!! named `<stdin>` is not a file: blang.exe hands that name over for `-` (with the
!!! `b` or `r` word in front of it), so the text is what was piped in.
str gn_read_source -> str path {
    if pe_eq(path, g_stdin_name) {
        return read_stream(GetStdHandle(-10));
    }
    @void f = getFile(path, "r");
    if f == null {
        return (str)null;
    }
    str src = readFile(@f, -1, -1);
    CloseHandle(f);
    return src;
}

!!! The output and the links out of `argv[2]`, which is
!!! `"<output> ; <argument> <argument> ..."`: the text before the `;` is the output
!!! (with the spaces before it taken off) and the rest is handed to cmp.exe as it
!!! stands. Without a `;` the whole argument is the output and cmp is handed no
!!! link arguments, which is how gn.exe reads it.
str gn_outfile;
str gn_cmp_args;

void gn_split_args -> str spec {
    gn_outfile = spec;
    gn_cmp_args = "";
    int semi = pe_find(spec, ';');
    if semi < 0 {
        end;
    }
    int e = semi;
    while e > 0 && spec[e - 1] == ' ' {
        e = e - 1;
    }
    gn_outfile = pe_sub(spec, 0, e);
    int rest = semi + 1;
    while spec[rest] == ' ' {
        rest = rest + 1;
    }
    gn_cmp_args = pe_sub_to_end(spec, rest);
}

int main {
    !!! The module directory is what the preprocessor's `#head` search and the
    !!! lookup of cmp.exe both start from, so it is read before anything else, the
    !!! way both drivers call blang_setup_home() first.
    setup_home();
    !!! Every message this program prints about its own work carries "gn", which is
    !!! what gn.exe writes.
    g_prog_name = "gn.exe";
    str cmd = GetCommandLineA();
    if cmd == null {
        system.err(zh_msg("gn: internal error"), "\n");
        return 1;
    }
    split_cmd(cmd);
    !!! argv[1] is the source and argv[2] the output with the links; anything from
    !!! argv[3] on is more of the same, which the toolchain appends to the link arguments.
    if g_args.len < 3 {
        system.err(zh_msg("gn: internal error"), "\n");
        return 1;
    }
    str infile = g_args.get(1);
    !!! A program that comes in on standard input is named `<stdin>` and has no file
    !!! whose line a message could quote: every diagnostic keeps its header line and
    !!! nothing stands below it. This program runs the front end, so the switch is
    !!! set here for the same reason blang.exe sets it for its own modes.
    if pe_eq(infile, g_stdin_name) {
        ux_show_source(false);
    }
    gn_split_args(g_args.get(2));
    int ai = 3;
    while ai < g_args.len {
        gn_cmp_args = append_arg(gn_cmp_args, g_args.get(ai));
        ai = ai + 1;
    }

    str src = gn_read_source(infile);
    if src == null {
        system.err(zh_msg("gn: cannot read '" + infile + "'"), "\n");
        return 1;
    }

    !!! The imported signatures blang.exe handed over: a file when they are large
    !!! enough that the environment would cut them short, the variable itself
    !!! otherwise. BLANG_VERBOSE is what -p sets, and BLANG_PREPROC is the
    !!! preprocessor's environment.
    str rimp = env_file("BLANG_RIMP_FILE");
    if rimp == "" {
        rimp = env_get("BLANG_RIMP");
    }
    bool verbose = env_has("BLANG_VERBOSE");
    str preproc = env_get("BLANG_PREPROC");

    !!! The front end, in this process: the .r text comes back with the `#to` line
    !!! at its head when the source asked for a placement.
    str rtext = rt_compile_b(src, infile, rimp, preproc, verbose);
    if rtext == null {
        return 1;
    }

    !!! And the stage cmp.exe is run by, which is the rest of what gn.exe is.
    return gn_run_cmp(rtext, gn_outfile, gn_cmp_args, verbose);
}
