!~
 ~  bootstrap/blang.b: the driver of the self-hosted compiler.
 ~
 ~  It keeps the driver's behaviour:
 ~  the same options, the same messages, the same rules ("no input file", "file
 ~  format not recognized", "-R and -I cannot be used together", the -D/-U/-P and
 ~  --builtins of the self-hosted preprocessor, the flags forwarded to cmp with
 ~  -CMP,).
 ~
 ~  The command line is read with GetCommandLineA and split here, because the
 ~  language's entry point is a plain `int main { ... }` and the C runtime's argv
 ~  never reaches it. Splitting it here keeps the driver's behaviour the same; when
 ~  the language hands argv to main this goes away.
 ~
 ~  The pipeline grows as modules land: the preprocessor, lexer and parser are
 ~  reached through #head from bootstrap/frontend, and each stage is called only
 ~  once it exists. Until then the driver does what is there and says so, rather
 ~  than pretending to have built something.
 ~
 ~  Build (see bootstrap/build.ps1):
 ~    blang.exe bootstrap/blang.b -o bootstrap/bin/blang.exe ^
 ~        -P bootstrap/frontend -system kernel32 -dbrtm -dbfile
 ~  Run:
 ~    bootstrap/bin/blang.exe -h
 ~    bootstrap/bin/blang.exe -o demo.exe hello.b
 ~!

!!! The release this driver prints with `--version`: the number, the day it was
!!! built (YYYYMMDD) and the name it was built by. They are `#replace` macros -
!!! the driver writes them into its own text and nothing returns them - and they
!!! are constants rather than the day of the build: the two toolchains have to
!!! print the same text, and a self-hosted rebuild the same binary.
#replace BLANG_VERSION "1.0.0"
#replace BLANG_BUILD_DATE "20261004"
#replace BLANG_BUILD_AUTHOR "Fzq5454"

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

!!! The two modules the drivers share: the command line, the module directory and
!!! the messages, and the front end on one file. gn.exe is built on the same two,
!!! which is what makes the two programs read alike.
#head "driver_common"
#head "frontend_run"

!!! ---- the helpers only this program uses ----
!!!
!!! The modules above are shared with gn.exe, and a helper no program calls is what
!!! -W-nused reports as never used. These six are the driver's own: the two fatal
!!! messages the toolchain blang raises, the temporary file the `.r` is written to
!!! before cmp.exe is handed it, the two front-end entry points that only an option
!!! asks for (-m wants the stubs' signatures, -I wants the preprocessed text), and
!!! the one-line encoding of the preprocessor environment that is handed to gn.exe
!!! through the environment (preproc_env_encode; gn.exe decodes it).

!!! The driver's fatal error. The layout and the colors are libbstr's - the program
!!! name in bold, "fatal error" in bold red, the message with the quoted parts in
!!! bold, and the line saying compilation stopped - so this is a call to the same
!!! `ux_fatal` the driver makes and not a copy of its text. Written out by hand
!!! it came out white, because the codes are what makes it a fatal error and not a
!!! plain line.
!!!
!!! The call goes through zh_fatal, which is ux_fatal itself while Chinese output
!!! is off, so a run without `-Chinese` prints byte for byte what it always did.
void fatal -> str msg {
    zh_fatal(g_prog_name, msg);
}

!!! The same message for text that names a file or an option. The pieces are joined
!!! here: `ux_fatal` takes one message, the way the driver builds one with `+`.
void fatal_file -> str prefix, str path, str suffix {
    zh_fatal(g_prog_name, prefix + path + suffix);
}

!!! The text of a `.r` written to a temporary file, which is what cmp.exe is
!!! handed: it reads a file, and text that came in on a pipe is not one. The
!!! caller removes the file as soon as cmp.exe has run.
str write_temp_r -> str text {
    str path = temp_r_path();
    @void f = getFile(path, "w");
    if f == null {
        return "";
    }
    writeFile(@f, text);
    CloseHandle(f);
    return path;
}

!!! rt_compile_b_stub_sigs: the front-end text of a source file, with the signature
!!! of every `stub` in it written out. -m reads the entries of a .bmeta from those
!!! lines.
str rt_compile_b_stub_sigs -> str src, str fname, str rimp, str preproc_spec,
                              bool verbose {
    return fe_run(src, fname, rimp, preproc_spec, verbose, false, true);
}

!!! rt_preprocess_b: the preprocessed text of one source file, which is all -I asks
!!! for and keeps the `#to` lines in it.
str rt_preprocess_b -> str src, str fname, str rimp, str preproc_spec, bool verbose {
    return fe_run(src, fname, rimp, preproc_spec, verbose, true, false);
}

!!! One record per line, `X<rest>`: D a -D, U a -U, P a -P directory, L a linked
!!! DLL, B a built-in as `B<name>=<value>`. A newline cannot appear in any of them,
!!! so a directory with spaces in its name survives the trip.
str preproc_env_encode -> @PreprocEnv env {
    str s = "";
    @NameVal d = env.defines;
    while d != null {
        s = s + "D" + d.name + "=" + d.value + "\n";
        d = d.next;
    }
    @NameList u = env.undefs;
    while u != null {
        s = s + "U" + u.name + "\n";
        u = u.next;
    }
    @NameList p = env.inc_dirs;
    while p != null {
        s = s + "P" + p.name + "\n";
        p = p.next;
    }
    @NameList l = env.linked;
    while l != null {
        s = s + "L" + l.name + "\n";
        l = l.next;
    }
    @BuiltinCond b = env.builtins;
    while b != null {
        s = s + "B" + b.name + "=" + (str)b.value + "\n";
        b = b.next;
    }
    return s;
}

!!! ---- the options, one argument at a time ----

bool arg_eq -> str a, str lit {
    int i = 0;
    int n = cmd_len(lit);
    while i < n {
        if a[i] == (char)0 {
            return false;
        }
        if a[i] != lit[i] {
            return false;
        }
        i = i + 1;
    }
    return a[i] == (char)0;
}

bool arg_starts -> str a, str lit {
    int i = 0;
    int n = cmd_len(lit);
    while i < n {
        if a[i] == (char)0 {
            return false;
        }
        if a[i] != lit[i] {
            return false;
        }
        i = i + 1;
    }
    return true;
}

bool ends_with -> str a, str lit {
    int la = cmd_len(a);
    int lb = cmd_len(lit);
    if lb > la {
        return false;
    }
    int i = 0;
    while i < lb {
        if a[la - lb + i] != lit[i] {
            return false;
        }
        i = i + 1;
    }
    return true;
}

!!! ---- messages ----

!!! The driver's own text - the help, the built-in table, the counts - is written
!!! to the process's standard output, not to `system.out`: what a tool prints has
!!! to be the output of the process, so that a redirection or a pipe carries it,
!!! and it must not move if the program's output channel ever does.
void puts_line -> str s {
    system.std_out(s);
    system.std_out("\n");
}

!!! The version line: the program name in #1E90FF, then "version <number>" in
!!! bold #00FFFF, then the release it was built as, the same bytes the driver's
!!! `printf` writes. The three values are the `#replace` macros at the head of this
!!! file, and the number is the one `built_in(COMPILER_VERSION)` reports.
void print_version {
    system.std_out("\033[38;2;30;144;255mblang.exe\033[0m ");
    system.std_out("\033[1;38;2;0;255;255mversion " + BLANG_VERSION + "\033[0m\n");
    system.std_out("Built at " + BLANG_BUILD_DATE + ", from " + BLANG_BUILD_AUTHOR + "\n");
}

!!! The help, in the language the run asked for: every line is a zh_pick of the
!!! two texts, which is what the driver's `puts(zh_pick(...))` does.
void print_help {
    puts_line(zh_pick("Usage: blang.exe [options] file...", "用法: blang.exe [选项] 文件..."));
    puts_line(zh_pick("Options:", "选项:"));
    puts_line(zh_pick("  -o <file>       Write output to <file>", "  -o <文件>       把输出写到 <文件>"));
    puts_line(zh_pick("  -R              Emit .r intermediate code (do not compile)", "  -R              只生成 .r 中间代码（不编译）"));
    puts_line(zh_pick("  -I              Emit preprocessed .b source (do not compile)", "  -I              只生成预处理后的 .b 源码（不编译）"));
    puts_line(zh_pick("  -m              Generate meta/<name>.bmeta from source", "  -m              由源码生成 meta/<名字>.bmeta"));
    puts_line(zh_pick("  -stdin b|r -    Read the program from standard input (b = blang source, r = .r code)",
                      "  -stdin b|r -    从标准输入读程序（b = blang 源码，r = .r 代码）"));
    puts_line(zh_pick("  -link <dll>     Link against a BLang DLL", "  -link <dll>     链接 BLang DLL"));
    puts_line(zh_pick("  -system <dll>   Import a system DLL, e.g. kernel32", "  -system <dll>   导入系统 DLL，例如 kernel32"));
    puts_line(zh_pick("  -l<name>        Link lib/<name>.lib", "  -l<名字>        链接 lib/<名字>.lib"));
    puts_line(zh_pick("  -d<name>        Dynamically link lib<name>.dll, e.g. -dbrtm", "  -d<名字>        动态链接 lib<名字>.dll，例如 -dbrtm"));
    puts_line(zh_pick("  -static-runtime Place the runtime into the output instead of importing it",
                      "  -static-runtime 把运行时放进输出而不是导入"));
    puts_line(zh_pick("  -static         Also place every -link / -d DLL into the output",
                      "  -static         并把每个 -link / -d 的 DLL 也放进输出"));
    puts_line(zh_pick("  -CMP,<arg1>,... Pass args directly to cmp linker", "  -CMP,<参数1>,... 把参数直接传给 cmp 链接器"));
    puts_line(zh_pick("  -D NAME[=VALUE] Define a name for #if defined(NAME)", "  -D 名字[=值]    为 #if defined(名字) 定义一个名字"));
    puts_line(zh_pick("  -U NAME         Undefine a name -D defined", "  -U 名字         取消 -D 定义的名字"));
    puts_line(zh_pick("  -P<dir>         Look for #head files in <dir> first", "  -P<目录>        先在 <目录> 里找 #head 文件"));
    puts_line(zh_pick("  --builtins      List the conditions #if built_in(NAME) knows", "  --builtins      列出 #if built_in(名字) 的所有条件"));
    puts_line(zh_pick("  -p, -process    Show verbose compilation process", "  -p, -process    显示详细的编译过程"));
    puts_line(zh_pick("  -d, -debug      Embed debug info (BSYM) into the output", "  -d, -debug      在输出中嵌入调试信息（BSYM）"));
    puts_line(zh_pick("  -Rimp-X-Y       Allow implicit conversion from type X to Y", "  -Rimp-X-Y       允许从类型 X 到 Y 的隐式转换"));
    puts_line(zh_pick("  -Econversion    Enable safe implicit conversions (see type compatibility table)", "  -Econversion    启用安全的隐式转换（见类型兼容表）"));
    puts_line(zh_pick("  -W-nused        Warn about unused variables and functions", "  -W-nused        对未使用的变量和函数给出警告"));
    puts_line(zh_pick("  -W-read-nused   Warn about variables whose value is never read", "  -W-read-nused   对只被赋值、从未读取其值的变量给出警告"));
    puts_line(zh_pick("  -W-nused-struct Warn about unused structs, members and methods", "  -W-nused-struct 对未使用的结构体、结构体成员和成员函数给出警告"));
    puts_line(zh_pick("  -W-read-nused-struct Warn about members whose value is never read", "  -W-read-nused-struct 对只被赋值、从未读取其值的结构体成员给出警告"));
    puts_line(zh_pick("  -W-nbody-func   Warn about functions that are called but never defined", "  -W-nbody-func   对只有声明、从未定义却被调用的函数给出警告"));
    puts_line(zh_pick("  -W-ntype-cmp    Warn about comparing values of two different types", "  -W-ntype-cmp    对比较两个不同类型的值给出警告"));
    puts_line(zh_pick("  -W-ntype-op     Warn about operating on values of two different types", "  -W-ntype-op     对两个不同类型的值进行运算给出警告"));
    puts_line(zh_pick("  -W-userdef      Warn about the checks a program wrote for itself (`rule warn(...)`); the rule runs either way, only the report waits for this switch", "  -W-userdef      对程序自己写的检查（`rule warn(...)`）给出警告；规则照常运行，只有报告等这个开关"));
    puts_line(zh_pick("  -W-all          Every warning above (-W-nused -W-read-nused -W-nused-struct -W-read-nused-struct -W-nbody-func -W-ntype-cmp -W-ntype-op -W-userdef)", "  -W-all          打开以上全部警告（等于 -W-nused -W-read-nused -W-nused-struct -W-read-nused-struct -W-nbody-func -W-ntype-cmp -W-ntype-op -W-userdef）"));
    puts_line(zh_pick("  -Chinese        Show every message in Chinese (错误/警告/提示)", "  -Chinese        所有信息用中文显示（错误/警告/提示）"));
    puts_line(zh_pick("  -v, --version   Display version information", "  -v, --version   显示版本信息"));
    puts_line(zh_pick("  --help          Display this information", "  --help          显示这份帮助"));
}

!!! One line of `--builtins`: the `printf("  %-24s %6lld   %s\n", ...)` - the
!!! name left aligned in 24 columns, the value right aligned in 6, and the
!!! description after three spaces.
void print_builtin_line -> str name, longlong value, str what {
    str line = "  " + name;
    int n = pe_len(name);
    while n < 24 {
        line = line + " ";
        n = n + 1;
    }
    str v = (str)value;
    line = line + " ";
    int d = pe_len(v);
    while d < 6 {
        line = line + " ";
        d = d + 1;
    }
    puts_line(line + v + "   " + what);
}

!!! The built-in conditions of the preprocessor, in the order the table has them,
!!! with the values this build has: the target is Windows x64 and none of the
!!! driver's switches is on. The table itself is preproc_env's, so a condition
!!! added there appears here without a second edit.
void print_builtins {
    puts_line(zh_pick("Built-in conditions for #if built_in(NAME):",
                      "可以在 #if built_in(名字) 里使用的内置条件:"));
    puts_line("");
    @BuiltinCond c = builtin_table();
    while c != null {
        print_builtin_line(c.name, c.value, zh_msg(c.what));
        c = c.next;
    }
    puts_line("");
    puts_line(zh_pick("  defined(NAME)   a name given with -D and not taken back with -U",
                      "  defined(名字)   用 -D 定义、且没有被 -U 取消的名字"));
    puts_line(zh_pick("  linked(dll)     a DLL this build names with -system, -link, -d<name> or -l<name>",
                      "  linked(dll)     本次编译用 -system/-link/-d<名字>/-l<名字> 指定的 DLL"));
}

!!! A driver message that stops one file but is not a fatal error lives in
!!! driver_common.b with the rest of what both drivers need.

!!! ---- driver state ----

!!! The inputs the command line names and the outputs -o names for them, in the
!!! order they were written. the driver keeps an `infiles` and an `outfiles`
!!! vector and compiles every input in turn, taking the output of input number `i`
!!! from the `i`-th -o; an input no -o answered for keeps the name its mode gives
!!! it, and `-` or `-stdin` names the one `<stdin>`.
vector(str) g_inputs;
vector(str) g_outs;

!!! The input being worked on, which is the index its -o is taken with.
int g_cur_input;

!!! Set once the input named `<stdin>` has been named: `-` and `-stdin` both name
!!! it, and naming it twice still names one input, which is what the toolchain does.
bool g_stdin_named;

!!! Set by the `r` language word: the input named `<stdin>` is intermediate code
!!! and goes straight to cmp.exe, the way a `.r` file does.
bool g_stdin_is_r;
str g_link_dlls;
str g_system_dlls;
str g_user_libs;
str g_linker_args;
str g_rimp_flags;
str g_defines;
str g_undefs;
str g_inc_dirs;
bool g_emit_r;
bool g_emit_i;
bool g_emit_m;
bool g_static_runtime;
bool g_static_all;
bool g_verbose;
bool g_debug;
bool g_show_builtins;

!!! The same options as lists, because one option may be given many times and the
!!! front end wants each one: `-D A -D B=2` is two defines and neither may be lost.
!!! They are kept in the order they were written, which is the order the front end
!!! reads them in.
@NameList g_define_names;
@NameList g_undef_names;
@NameList g_inc_dir_list;

bool want_version -> str a {
    if arg_eq(a, "--version") {
        return true;
    }
    return arg_eq(a, "-v");
}

bool want_help -> str a {
    if arg_eq(a, "--help") {
        return true;
    }
    return arg_eq(a, "-h");
}

!!! ---- the options, one argument at a time ----

bool is_option -> str a {
    return a[0] == '-';
}

bool file_ok -> str a {
    if ends_with(a, ".b") {
        return true;
    }
    if ends_with(a, ".r") {
        return true;
    }
    return ends_with(a, ".i");
}

int take_options {
    !!! Index 0 is the program name the command line starts with, so the options start
    !!! at 1: the same walk the driver does over argv[].
    int ai = 1;
    while ai < g_args.len {
        str s = g_args.get(ai);
        if !is_option(s) {
            !!! `b` and `r` on their own are the language of the input that comes in
            !!! on standard input, which `-stdin` (anywhere on the line) or `-`
            !!! declares:
            !!!
            !!!     type x.b | blang.exe -stdin b - -o x.exe   (a blang program)
            !!!     type x.r | blang.exe -stdin r - -o x.exe   (intermediate code)
            !!!
            !!! `b` is compiled the way a `.b` file is and `r` goes straight to
            !!! cmp.exe the way a `.r` file does; the input is named `<stdin>`, so
            !!! that is the file name every message of the compiler prints.
            if arg_eq(s, "b") || arg_eq(s, "r") {
                g_stdin_is_r = arg_eq(s, "r");
                ai = ai + 1;
                continue;
            }
            if !file_ok(s) {
                fatal_file("file format not recognized: ", s, "");
                return 1;
            }
            g_inputs.add(s);
            ai = ai + 1;
            continue;
        }
        if arg_eq(s, "-stdin") {
            !!! The program text comes in on standard input instead of from a file.
            !!! The option may stand anywhere on the command line; `-` is where the
            !!! input file would be, and the `b` or `r` word says which language the
            !!! text is in. The input is named `<stdin>`, so that is the file name
            !!! every message of the compiler prints.
            if !g_stdin_named {
                g_stdin_named = true;
                g_inputs.add(g_stdin_name);
            }
            ai = ai + 1;
            continue;
        }
        if arg_eq(s, "-") {
            !!! `-` is where the input file stands when the program is piped in; the
            !!! `b` or `r` word above says which language it is in, and without one
            !!! it is a blang program.
            if !g_stdin_named {
                g_stdin_named = true;
                g_inputs.add(g_stdin_name);
            }
            ai = ai + 1;
            continue;
        }
        if arg_eq(s, "-o") {
            ai = ai + 1;
            if ai >= g_args.len {
                fatal("option '-o' needs an output file");
                return 1;
            }
            g_outs.add(g_args.get(ai));
        } else if arg_eq(s, "-R") {
            g_emit_r = true;
        } else if arg_eq(s, "-I") {
            g_emit_i = true;
        } else if arg_eq(s, "-m") {
            g_emit_m = true;
        } else if arg_eq(s, "-link") {
            ai = ai + 1;
            if ai >= g_args.len {
                fatal("option '-link' needs a DLL name");
                return 1;
            }
            g_link_dlls = append_arg(g_link_dlls, g_args.get(ai));
        } else if arg_eq(s, "-system") {
            ai = ai + 1;
            if ai >= g_args.len {
                fatal("option '-system' needs a DLL name");
                return 1;
            }
            g_system_dlls = append_arg(g_system_dlls, g_args.get(ai));
        } else if arg_eq(s, "-static-runtime") {
            g_static_runtime = true;
        } else if arg_eq(s, "-static") {
            g_static_runtime = true;
            g_static_all = true;
        } else if arg_eq(s, "-d") || arg_eq(s, "-debug") {
            g_debug = true;
            !!! Debug information is a placement cmp is asked for, so the flag goes
            !!! into the arguments the linker is handed.
            g_linker_args = append_arg(g_linker_args, "-d");
        } else if arg_eq(s, "-p") || arg_eq(s, "-process") {
            g_verbose = true;
        } else if arg_starts(s, "-CMP,") {
            !!! `-CMP,arg1,arg2` hands cmp.exe one argument per comma-separated
            !!! piece, not the option as it was written.
            int cn = pe_len(s);
            int ci = 5;
            while ci < cn {
                while ci < cn && s[ci] == ',' {
                    ci = ci + 1;
                }
                if ci >= cn {
                    skip;
                }
                int cs = ci;
                while ci < cn && s[ci] != ',' {
                    ci = ci + 1;
                }
                g_linker_args = append_arg(g_linker_args, pe_sub(s, cs, ci - cs));
            }
        } else if arg_eq(s, "-Econversion") {
            g_rimp_flags = append_arg(g_rimp_flags, "-Econversion");
        } else if arg_eq(s, "-W-nused") {
            g_rimp_flags = append_arg(g_rimp_flags, "-W-nused");
        } else if arg_eq(s, "-W-read-nused") {
            g_rimp_flags = append_arg(g_rimp_flags, "-W-read-nused");
        } else if arg_eq(s, "-W-nused-struct") {
            g_rimp_flags = append_arg(g_rimp_flags, "-W-nused-struct");
        } else if arg_eq(s, "-W-read-nused-struct") {
            g_rimp_flags = append_arg(g_rimp_flags, "-W-read-nused-struct");
        } else if arg_eq(s, "-W-nbody-func") {
            g_rimp_flags = append_arg(g_rimp_flags, "-W-nbody-func");
        } else if arg_eq(s, "-W-ntype-cmp") {
            g_rimp_flags = append_arg(g_rimp_flags, "-W-ntype-cmp");
        } else if arg_eq(s, "-W-ntype-op") {
            g_rimp_flags = append_arg(g_rimp_flags, "-W-ntype-op");
        } else if arg_eq(s, "-W-userdef") {
            !!! The checks a program writes for itself (`rule warn(...)`): the report
            !!! is a warning of its own class, and -W-all asks for it like every other
            !!! one.
            g_rimp_flags = append_arg(g_rimp_flags, "-W-userdef");
        } else if arg_eq(s, "-W-all") {
            !!! Every warning the front end has, spelled out: the front end keeps no
            !!! "all" switch of its own, so what reaches it is the list a reader would
            !!! have written by hand.
            g_rimp_flags = append_arg(g_rimp_flags, "-W-nused");
            g_rimp_flags = append_arg(g_rimp_flags, "-W-read-nused");
            g_rimp_flags = append_arg(g_rimp_flags, "-W-nused-struct");
            g_rimp_flags = append_arg(g_rimp_flags, "-W-read-nused-struct");
            g_rimp_flags = append_arg(g_rimp_flags, "-W-nbody-func");
            g_rimp_flags = append_arg(g_rimp_flags, "-W-ntype-cmp");
            g_rimp_flags = append_arg(g_rimp_flags, "-W-ntype-op");
            g_rimp_flags = append_arg(g_rimp_flags, "-W-userdef");
        } else if arg_eq(s, "-Chinese") {
            !!! Already applied before this loop, which is the driver's
            !!! `continue;` here: the switch itself was flipped over the whole
            !!! command line before the first option was read, and gn.exe and
            !!! cmp.exe were told through BLANG_CHINESE.
            g_verbose = g_verbose;
        } else if arg_eq(s, "--builtins") {
            g_show_builtins = true;
        } else if want_version(s) {
            print_version();
            return 2;
        } else if want_help(s) {
            print_help();
            return 2;
        } else if arg_eq(s, "-D") {
            ai = ai + 1;
            if ai >= g_args.len {
                fatal("option '-D' needs a name");
                return 1;
            }
            g_defines = g_args.get(ai);
            g_define_names = pp_nl_append(g_define_names, g_defines);
        } else if arg_eq(s, "-U") {
            ai = ai + 1;
            if ai >= g_args.len {
                fatal("option '-U' needs a name");
                return 1;
            }
            g_undefs = g_args.get(ai);
            g_undef_names = pp_nl_append(g_undef_names, g_undefs);
        } else if arg_starts(s, "-P") {
            if arg_eq(s, "-P") {
                ai = ai + 1;
                if ai >= g_args.len {
                    fatal("option '-P' needs a directory");
                    return 1;
                }
                g_inc_dirs = g_args.get(ai);
            } else {
                g_inc_dirs = s;
            }
            !!! `-P<dir>` writes the directory without the option, so the front end is
            !!! given the path it looks in rather than the argument that named it.
            if arg_eq(s, "-P") {
                g_inc_dir_list = pp_nl_append(g_inc_dir_list, g_inc_dirs);
            } else {
                g_inc_dir_list = pp_nl_append(g_inc_dir_list, pe_sub_to_end(s, 2));
            }
        } else if arg_starts(s, "-Rimp-") {
            !!! `-Rimp-str-int` names the pair `str-int`, which is the spelling the
            !!! RGenerator reads; the option's own name is not part of it.
            g_rimp_flags = append_arg(g_rimp_flags, pe_sub_to_end(s, 6));
        } else if arg_eq(s, "-l") {
            !!! A bare `-l` names no library: it is the `-l<name>` form with an empty
            !!! name, which is reported rather than linked as one.
            fatal("option '-l' needs a name");
            return 1;
        } else if arg_starts(s, "-l") {
            g_user_libs = append_arg(g_user_libs, s);
        } else if arg_starts(s, "-d") {
            g_link_dlls = append_arg(g_link_dlls, s);
        } else {
            fatal_file("unrecognized command-line option '", s, "'");
            return 1;
        }
        ai = ai + 1;
    }
    return 0;
}

!!! ---- the preprocessor's diagnostics ----

!!! `g_home`, `setup_home` and the printers of the preprocessor's diagnostics stand
!!! in driver_common.b: the module directory is what both drivers need, and a `.b`
!!! file handed straight to gn.exe reports its preprocessor errors the same way this
!!! driver does.

!!! What `#if` may ask about, the -D/-U names, the -P directories and the DLLs this
!!! build links, built the way blang builds them for the front end.
void add_linked -> @PreprocEnv env, str list {
    if list == "" {
        end;
    }
    int i = 0;
    int n = pe_len(list);
    while i < n {
        while i < n && list[i] == ' ' {
            i = i + 1;
        }
        if i >= n {
            skip;
        }
        int s = i;
        while i < n && list[i] != ' ' {
            i = i + 1;
        }
        str dll = pe_sub(list, s, i - s);
        !!! `-dbrtm` and `-lstr` name a library that is written `libbrtm.dll` and
        !!! `libbstr.lib` on disk; the key is the bare name either way.
        if pe_matches(dll, 0, "-d") || pe_matches(dll, 0, "-l") {
            dll = pe_sub_to_end(dll, 2);
        }
        env.linked = p_namelist_add(env.linked, preproc_dll_key(dll));
    }
}

!!! ---- the .bmeta of a linked DLL ----
!!!
!!! A DLL this build links brings the names and the result types of its functions
!!! with it in meta/<dll>.bmeta, and the front end has to know them: a call to one
!!! of them is an undeclared function without that list. The signature file is read
!!! and the RGenerator is handed one `extern=<name>:<type>`
!!! entry per function; the same list is built here.
!!!
!!! The names are text, the file is not: it is read with readFileA, the reader that
!!! does not stop at a NUL byte (which is what tells a text file from a binary one),
!!! and walked by the record count in its header - the magic `BLMT`, the count at
!!! bytes 6 and 7, and the records from byte 12, each one a name length, the name,
!!! the result type, a parameter count and that many parameter entries.

!!! The file name of a DLL path: what stands after its last separator.
str dll_base_name -> str p {
    int last = -1;
    int i = 0;
    while p[i] != (char)0 {
        if p[i] == '\\' || p[i] == '/' {
            last = i;
        }
        i = i + 1;
    }
    if last >= 0 {
        return pe_sub_to_end(p, last + 1);
    }
    return p;
}

!!! `a` and `b` are the same text, letters compared without their case.
bool ci_eq -> str a, str b {
    int i = 0;
    while a[i] != (char)0 && b[i] != (char)0 {
        char ca = a[i];
        char cb = b[i];
        if ca >= 'A' && ca <= 'Z' {
            ca = (char)((int)ca + 32);
        }
        if cb >= 'A' && cb <= 'Z' {
            cb = (char)((int)cb + 32);
        }
        if ca != cb {
            return false;
        }
        i = i + 1;
    }
    return a[i] == b[i];
}

!!! The DLL a `-d<name>` option names: the project marks its DLLs with a `lib`
!!! prefix - `libbstr.dll` is the compiler's own - and a `.dll` extension. This is
!!! what `dyn_dll_name` builds.
str dyn_dll_name -> str name {
    str n = name;
    if pe_len(n) < 3 || !pe_matches(n, 0, "lib") {
        n = "lib" + n;
    }
    int l = pe_len(n);
    if l < 4 || !pe_matches(n, l - 4, ".dll") {
        n = n + ".dll";
    }
    return n;
}

!!! The name a system DLL is imported by: `-system kernel32` and
!!! `-system kernel32.dll` both mean kernel32.dll. This is system_dll_name of
!!! whose extension test is not case sensitive.
str system_dll_name -> str name {
    str n = name;
    int dot = -1;
    int i = 0;
    while n[i] != (char)0 {
        if n[i] == '.' {
            dot = i;
        }
        i = i + 1;
    }
    bool has_dll = false;
    if dot >= 0 {
        str ext = pe_sub_to_end(n, dot + 1);
        if pe_len(ext) == 3 && ci_eq(ext, "dll") {
            has_dll = true;
        }
    }
    if !has_dll {
        n = n + ".dll";
    }
    return n;
}

!!! The blang spelling of a .bmeta type byte, which is bmeta_type_name of
!!! the front end maps the spelling back to a type without knowing
!!! the encoding, so a byte that is none of these reads as int.
str bmeta_type_name -> int b {
    if b == 0 {
        return "void";
    }
    if b == 1 {
        return "bool";
    }
    if b == 2 {
        return "int";
    }
    if b == 3 {
        return "str";
    }
    if b == 4 {
        return "any";
    }
    if b == 5 {
        return "char";
    }
    if b == 6 {
        return "float";
    }
    if b == 7 {
        return "longlong";
    }
    if b == 8 {
        return "utype int";
    }
    if b == 9 {
        return "utype longlong";
    }
    if b == 10 {
        return "utype char";
    }
    if b == 16 {
        return "@int";
    }
    if b == 17 {
        return "@float";
    }
    if b == 18 {
        return "@char";
    }
    if b == 19 {
        return "@str";
    }
    if b == 20 {
        return "@void";
    }
    if b == 21 {
        return "@bool";
    }
    if b == 22 {
        return "func";
    }
    if b == 23 {
        return "@func";
    }
    if b == 24 {
        return "@longlong";
    }
    return "int";
}

!!! The whole file at `path` in one string, or null when it is not there. The
!!! binary reader is asked for it, so a NUL byte in the middle is kept: the
!!! signatures are text but the records around them are not.
str bmeta_open -> str path {
    @void f = getFile(path, "rb");
    if f == null {
        return (str)null;
    }
    return readFileA(@f, -1, -1);
}

!!! What a .bmeta that could not be read is reported with, empty when it was read.
str g_bmeta_error;

!!! The `name:rettype` list a DLL's .bmeta holds, or null when it cannot be read.
!!! the toolchain looks beside the compiler first (BLANG_HOME/meta), then one level up
!!! (BLANG_HOME/../meta, which is where a compiler in bin/ finds the install) and
!!! then in meta/ under the working directory.
str bmeta_signatures -> str dll {
    str base = dll_base_name(dll);
    g_bmeta_error = "";
    str data = bmeta_open(g_home + "\\meta\\" + base + ".bmeta");
    if data == null {
        data = bmeta_open(g_home + "\\..\\meta\\" + base + ".bmeta");
    }
    if data == null {
        data = bmeta_open("meta\\" + base + ".bmeta");
    }
    if data == null {
        g_bmeta_error = ": cannot open 'meta/" + base + ".bmeta': .bmeta not found";
        return (str)null;
    }
    if !pe_matches(data, 0, "BLMT") {
        g_bmeta_error = ": invalid .bmeta magic";
        return (str)null;
    }
    !!! The record count, little endian at bytes 6 and 7.
    int nrec = ((int)data[6] & 255) + (((int)data[7] & 255) * 256);
    !!! The list is built in a growing buffer. Appending one signature at a time
    !!! copied the whole list again per signature, and kernel32 alone is two
    !!! thousand functions: half a second per DLL against five hundredths for the
    !!!, and this is the fixed cost of every run that names a system DLL.
    @TextBuf b = tx_new();
    int off = 12;
    int i = 0;
    while i < nrec {
        int nl = (int)data[off] & 255;
        off = off + 1;
        !!! A length that cannot be a name means the walk has left the records. The
        !!! file is not read with a length, so this is what keeps a short one from
        !!! being walked past its end.
        if nl <= 0 || nl > 128 {
            skip;
        }
        str nm = pe_sub(data, off, nl);
        off = off + nl;
        int rt = (int)data[off] & 255;
        off = off + 1;
        int pc = (int)data[off] & 255;
        off = off + 1;
        if b.len > 0 {
            tx_add_ch(b, ' ');
        }
        tx_add(b, nm);
        tx_add_ch(b, ':');
        tx_add(b, bmeta_type_name(rt));
        int j = 0;
        while j < pc {
            off = off + 1;
            int pnl = (int)data[off] & 255;
            off = off + 1;
            if pnl > 128 {
                j = pc;
                skip;
            }
            off = off + pnl;
            j = j + 1;
        }
        i = i + 1;
    }
    return tx_text(b);
}

!!! The DLL file a `-link` or a `-d<name>` entry names: `-dbrtm` is libbrtm.dll,
!!! and a name `-link` gave is used exactly as it stands.
str link_dll_file -> str e {
    if pe_matches(e, 0, "-d") {
        return dyn_dll_name(pe_sub_to_end(e, 2));
    }
    return e;
}

!!! The `extern=` entries of one DLL, added to the flags the RGenerator is built
!!! with. A DLL whose .bmeta cannot be read is a fatal error, the way it is in the
!!! driver: without the list every call into it would be reported on its own.
bool add_externs_of -> str dll, str flag_name {
    str sigs = bmeta_signatures(dll);
    if sigs == null {
        fatal_file("", flag_name + dll, g_bmeta_error);
        return false;
    }
    !!! The entries of one DLL are built in a growing buffer and added to the flags
    !!! in one append. Appending one entry at a time copied the whole list again per
    !!! entry, and kernel32 alone is two thousand functions: the list is over a
    !!! hundred kilobytes by the end, and the copy was a hundred kilobytes each time
    !!! (half a second per DLL, measured, against five hundredths for the toolchain).
    @TextBuf b = tx_new();
    int i = 0;
    int n = pe_len(sigs);
    while i < n {
        while i < n && sigs[i] == ' ' {
            i = i + 1;
        }
        if i >= n {
            skip;
        }
        int s = i;
        while i < n && sigs[i] != ' ' {
            i = i + 1;
        }
        if b.len > 0 {
            tx_add_ch(b, ' ');
        }
        tx_add(b, "extern=");
        tx_add(b, pe_sub(sigs, s, i - s));
    }
    g_rimp_flags = append_arg(g_rimp_flags, tx_text(b));
    return true;
}

!!! The functions of every linked DLL. the toolchain asks for the -link and -system DLLs;
!!! a library named with -l<name> is a general library and is not asked.
bool collect_externs {
    int i = 0;
    int n = pe_len(g_link_dlls);
    while i < n {
        while i < n && g_link_dlls[i] == ' ' {
            i = i + 1;
        }
        if i >= n {
            skip;
        }
        int s = i;
        while i < n && g_link_dlls[i] != ' ' {
            i = i + 1;
        }
        if !add_externs_of(link_dll_file(pe_sub(g_link_dlls, s, i - s)), "-link ") {
            return false;
        }
    }
    int k = 0;
    int m = pe_len(g_system_dlls);
    while k < m {
        while k < m && g_system_dlls[k] == ' ' {
            k = k + 1;
        }
        if k >= m {
            skip;
        }
        int s2 = k;
        while k < m && g_system_dlls[k] != ' ' {
            k = k + 1;
        }
        if !add_externs_of(system_dll_name(pe_sub(g_system_dlls, s2, k - s2)), "-system ") {
            return false;
        }
    }
    return true;
}

!!! The file the output goes to: what -o named for this input, or the name the mode
!!! gives it (`a.i` for -I, `a.r` for -R and `a.exe` otherwise), which is what the
!!! driver resolves before it runs any stage. The -o of an input is the one of
!!! its own index, so the second -o answers for the second input.
str resolve_outfile {
    if g_cur_input < g_outs.len {
        return g_outs.get(g_cur_input);
    }
    if g_emit_i {
        return "a.i";
    }
    if g_emit_r {
        return "a.r";
    }
    return "a.exe";
}

void build_preproc_env -> @PreprocEnv env {
    @NameList d = g_define_names;
    while d != null {
        str spec = d.name;
        int eq = pe_find(spec, '=');
        if eq < 0 {
            env.defines = p_nameval_add(env.defines, spec, "1");
        } else {
            env.defines = p_nameval_add(env.defines, pe_sub(spec, 0, eq), pe_sub_to_end(spec, eq + 1));
        }
        d = d.next;
    }
    @NameList u = g_undef_names;
    while u != null {
        env.undefs = p_namelist_add(env.undefs, u.name);
        u = u.next;
    }
    @NameList p = g_inc_dir_list;
    while p != null {
        env.inc_dirs = pp_nl_append(env.inc_dirs, p.name);
        p = p.next;
    }
    add_linked(env, g_system_dlls);
    add_linked(env, g_link_dlls);
    add_linked(env, g_user_libs);
}

!!! ---- what the run is told about itself ----

!!! The preprocessor's environment as this command line describes it: the -D/-U/-P
!!! names, the linked DLLs, and the built-in conditions of the build the options ask
!!! for. the toolchain builds it once (blang) and encodes it for every entry point of
!!! the front end; this implementation does the same, and the encoded text is also what gn.exe
!!! reads out of BLANG_PREPROC when it runs the front end itself.
@PreprocEnv driver_env {
    @PreprocEnv env = env_new();
    BuiltinFacts facts = default_facts();
    facts.debug = g_debug;
    facts.meta_mode = g_emit_m;
    facts.preprocess_only = g_emit_i;
    facts.emit_r = g_emit_r;
    facts.runtime_static = g_static_runtime;
    facts.dlls_static = g_static_all;
    env.builtins = builtin_conditions(facts);
    build_preproc_env(env);
    return env;
}

!!! ---- the front end on the input ----

!!! The text of the file the driver was given, or null when it is not there: the toolchain
!!! checks the same way before it runs any stage. The input named `<stdin>` is not
!!! a file at all: its text is what was piped in.
str read_input -> str path {
    if pe_eq(path, g_stdin_name) {
        return read_stream(GetStdHandle(-10));
    }
    @void f = getFile(path, "r");
    if f == null {
        fatal_file("", path, ": no such file or directory");
        return (str)null;
    }
    str src = readFile(@f, -1, -1);
    CloseHandle(f);
    if src == null {
        fatal_file("", path, ": cannot read the input file");
        return (str)null;
    }
    return src;
}

!!! The text without the `#to` line at its head, which is what -R writes: the toolchain
!!! strips the line the same way before the text goes to the file, because the
!!! placement is not part of the code.
str strip_to_line -> str rtext {
    if !pe_matches(rtext, 0, "#to ") {
        return rtext;
    }
    int nl = pe_find(rtext, '\n');
    if nl < 0 {
        return "";
    }
    return pe_sub_to_end(rtext, nl + 1);
}

!!! ---- the .bmeta of a definition file ----
!!!
!!! -m reads a file of stubs and writes the signatures it declares into
!!! meta/<name>.bmeta, the file a program that links the DLL reads back
!!! (bmeta_signatures above). The entries are taken out of the `.r` text: the front
!!! end is asked for the signature of every stub (`rt_compile_b_stub_sigs`), and
!!! each FUNC line of that text is one of them. A LOCAL line is a function of the
!!! file itself and not of the DLL, so it is left out, and so are the compiler's
!!! own method and constructor implementations (`__m_*`, `__ctor_*`, `__dtor_*`):
!!! they belong to the struct definition a program includes, and an entry for one
!!! would make a call resolve to an import of a DLL that never exported it.
!!!
!!! the toolchain builds the bytes in a a chain and writes them in one go. Here they
!!! go to the file as they are built, byte by byte, because the text of the file
!!! is not a `str`: it carries the counts and the length bytes a `str` cannot hold.

type BmetaParam {
    str ptype;
    str pname;
    @BmetaParam next;
};

type BmetaFunc {
    str name;
    bool is_local;
    str ret_type;
    @BmetaParam params;
    @BmetaFunc next;
};

@BmetaParam bmeta_new_param -> str ptype, str pname {
    BmetaParam proto;
    @BmetaParam p;
    malloc(@p, size proto);
    p.ptype = ptype;
    p.pname = pname;
    p.next = null;
    return p;
}

@BmetaFunc bmeta_new_func -> str name, bool is_local, str ret_type, @BmetaParam params {
    BmetaFunc proto;
    @BmetaFunc f;
    malloc(@f, size proto);
    f.name = name;
    f.is_local = is_local;
    f.ret_type = ret_type;
    f.params = params;
    f.next = null;
    return f;
}

!!! Every FUNC line of a `.r` text, in the order they stand. The walk is the one of
!!! the toolchain reader: whitespace, an optional LOCAL, FUNC, the name, the return type
!!! and the parameter list, with the `{...}` of an array parameter and the `...` of
!!! a variadic one stepped over.
@BmetaFunc bmeta_parse_r -> str rtext {
    @BmetaFunc head = null;
    @BmetaFunc tail = null;
    int n = pe_len(rtext);
    int p = 0;
    while p < n {
        while p < n && (rtext[p] == ' ' || rtext[p] == '\n' || rtext[p] == '\r' ||
                        rtext[p] == '\t') {
            p = p + 1;
        }
        if p >= n {
            skip;
        }
        bool is_local = false;
        if pe_matches(rtext, p, "LOCAL ") {
            is_local = true;
            p = p + 6;
        }
        if !pe_matches(rtext, p, "FUNC ") {
            p = p + 1;
            continue;
        }
        p = p + 5;
        while p < n && rtext[p] == ' ' {
            p = p + 1;
        }
        int ns = p;
        while p < n && rtext[p] != ' ' && rtext[p] != '(' {
            p = p + 1;
        }
        if p >= n {
            skip;
        }
        str fname = pe_sub(rtext, ns, p - ns);
        if pe_matches(fname, 0, "__m_") || pe_matches(fname, 0, "__ctor_") ||
           pe_matches(fname, 0, "__dtor_") {
            while p < n && rtext[p] != '\n' {
                p = p + 1;
            }
            continue;
        }
        while p < n && rtext[p] == ' ' {
            p = p + 1;
        }
        int rs = p;
        while p < n && rtext[p] != ' ' && rtext[p] != '(' {
            p = p + 1;
        }
        if p >= n {
            skip;
        }
        str ret_type = pe_sub(rtext, rs, p - rs);
        while p < n && rtext[p] == ' ' {
            p = p + 1;
        }
        if p >= n || rtext[p] != '(' {
            continue;
        }
        p = p + 1;
        @BmetaParam ph = null;
        @BmetaParam pt = null;
        while p < n && rtext[p] != ')' {
            while p < n && (rtext[p] == ' ' || rtext[p] == ',') {
                p = p + 1;
            }
            if p >= n || rtext[p] == ')' {
                skip;
            }
            int ps = p;
            while p < n && rtext[p] != ' ' && rtext[p] != ')' && rtext[p] != ',' {
                p = p + 1;
            }
            str ptype = pe_sub(rtext, ps, p - ps);
            !!! A struct parameter is two words in the `.r`: `STRUCT name param` is
            !!! the object passed by value and `STRUCTPTR name param` its address.
            !!! What the DLL is handed is a pointer either way, so the parameter is
            !!! recorded as one (@void); the name only said what it points at.
            if pe_eq(ptype, "STRUCTPTR") || pe_eq(ptype, "STRUCT") {
                while p < n && rtext[p] == ' ' {
                    p = p + 1;
                }
                while p < n && rtext[p] != ' ' && rtext[p] != ')' && rtext[p] != ',' {
                    p = p + 1;
                }
                ptype = "AT_VOID";
            }
            while p < n && rtext[p] == ' ' {
                p = p + 1;
            }
            int pns = p;
            while p < n && rtext[p] != ' ' && rtext[p] != ')' && rtext[p] != ',' &&
                  rtext[p] != '{' {
                p = p + 1;
            }
            str pname = pe_sub(rtext, pns, p - pns);
            if pe_len(ptype) > 0 && pe_len(pname) > 0 {
                @BmetaParam np = bmeta_new_param(ptype, pname);
                if ph == null {
                    ph = np;
                } else {
                    pt.next = np;
                }
                pt = np;
            }
            if p < n && rtext[p] == '{' {
                while p < n && rtext[p] != '}' {
                    p = p + 1;
                }
                if p < n {
                    p = p + 1;
                }
            }
            if p + 2 < n && rtext[p] == '.' && rtext[p + 1] == '.' && rtext[p + 2] == '.' {
                p = p + 3;
            }
        }
        @BmetaFunc nf = bmeta_new_func(fname, is_local, ret_type, ph);
        if head == null {
            head = nf;
        } else {
            tail.next = nf;
        }
        tail = nf;
    }
    return head;
}

!!! The byte the file holds for a type spelling, which is what the reader above
!!! turns back (bmeta_type_name). A type this table does not name falls through to
!!! void, which is what the toolchain table does as well.
int bmeta_type_byte -> str t {
    !!! `AT2_INT` and `AT3_STR` are pointers to pointers: the file holds one pointer
    !!! byte and no depth, so the base pointer type is written.
    str n = t;
    int len = pe_len(n);
    if len > 4 && n[0] == 'A' && n[1] == 'T' && n[2] >= '0' && n[2] <= '9' {
        int d = 2;
        while d < len && n[d] >= '0' && n[d] <= '9' {
            d = d + 1;
        }
        if d < len && n[d] == '_' {
            n = "AT" + pe_sub_to_end(n, d + 1);
        }
    }
    if pe_eq(n, "VOID") { return 0; }
    if pe_eq(n, "BOOL") { return 1; }
    if pe_eq(n, "INT") { return 2; }
    if pe_eq(n, "STR") { return 3; }
    if pe_eq(n, "ANY") { return 4; }
    if pe_eq(n, "CHAR") { return 5; }
    if pe_eq(n, "FLOAT") { return 6; }
    if pe_eq(n, "LONG") { return 7; }
    if pe_eq(n, "UTYPE_INT") { return 8; }
    if pe_eq(n, "UTYPE_LONG") { return 9; }
    if pe_eq(n, "UTYPE_CHAR") { return 10; }
    if pe_eq(n, "AT_INT") { return 16; }
    if pe_eq(n, "AT_FLOAT") { return 17; }
    if pe_eq(n, "AT_CHAR") { return 18; }
    if pe_eq(n, "AT_STR") { return 19; }
    if pe_eq(n, "AT_VOID") { return 20; }
    if pe_eq(n, "AT_BOOL") { return 21; }
    if pe_eq(n, "FUNC") { return 22; }
    if pe_eq(n, "AT_FUNC") { return 23; }
    if pe_eq(n, "AT_LONG") { return 24; }
    return 0;
}

!!! The bytes of the file being built. They go into a block of their own and not
!!! into a `str`: the file is full of NULs (the counts and the length bytes), and
!!! a `str` ends at the first of them. A single `WriteFile` writes the block at the
!!! end; the API that writes one byte at a time (`writeFileByte`) is a BLANG_API
!!! function, whose arguments the DLL reads through the address it is handed, so a
!!! handle has to be given it through a variable of its own.
@char bmeta_out;
int bmeta_out_len;
int bmeta_out_cap;

void bmeta_out_init {
    bmeta_out_cap = 256;
    @void cell;
    malloc(@cell, bmeta_out_cap);
    bmeta_out = (@char)cell;
    bmeta_out_len = 0;
}

void bmeta_out_byte -> int v {
    if bmeta_out_len + 1 > bmeta_out_cap {
        int want = bmeta_out_cap * 2;
        @void ncell;
        malloc(@ncell, want);
        @char nd = (@char)ncell;
        int k = 0;
        while k < bmeta_out_len {
            nd[k] = bmeta_out[k];
            k = k + 1;
        }
        @char old = bmeta_out;
        unlink(@old);
        bmeta_out = nd;
        bmeta_out_cap = want;
    }
    bmeta_out[bmeta_out_len] = (char)(v & 255);
    bmeta_out_len = bmeta_out_len + 1;
}

!!! One byte, one little-endian 16-bit value and one 32-bit value, where the toolchain
!!! `w8` / `w16` / `w32` put them.
void bmeta_w8 -> int v {
    bmeta_out_byte(v);
}

void bmeta_w16 -> int v {
    bmeta_w8(v & 255);
    bmeta_w8((v >> 8) & 255);
}

void bmeta_w32 -> int v {
    bmeta_w16(v & 65535);
    bmeta_w16((v >> 16) & 65535);
}

!!! A length byte and the bytes of a name.
void bmeta_wstr -> str s {
    int n = pe_len(s);
    bmeta_w8(n);
    int i = 0;
    while i < n {
        bmeta_w8((int)s[i] & 255);
        i = i + 1;
    }
}

!!! The whole file: the magic, the version, how many functions are exported and
!!! then one entry per function, with its name, its return type and its parameters.
void bmeta_write -> @void f, @BmetaFunc funcs {
    bmeta_out_init();
    int nrec = 0;
    @BmetaFunc g = funcs;
    while g != null {
        if !g.is_local {
            nrec = nrec + 1;
        }
        g = g.next;
    }
    bmeta_w8((int)'B');
    bmeta_w8((int)'L');
    bmeta_w8((int)'M');
    bmeta_w8((int)'T');
    !!! 0x0100, the version the toolchain writes, byte for byte little endian.
    bmeta_w16(256);
    bmeta_w16(nrec);
    bmeta_w32(0);
    @BmetaFunc e = funcs;
    while e != null {
        if !e.is_local {
            bmeta_wstr(e.name);
            bmeta_w8(bmeta_type_byte(e.ret_type));
            int pc = 0;
            @BmetaParam q = e.params;
            while q != null {
                pc = pc + 1;
                q = q.next;
            }
            bmeta_w8(pc);
            q = e.params;
            while q != null {
                bmeta_w8(bmeta_type_byte(q.ptype));
                bmeta_wstr(q.pname);
                q = q.next;
            }
        }
        e = e.next;
    }
    int written = 0;
    WriteFile(f, (str)bmeta_out, bmeta_out_len, @written, null);
    @char old = bmeta_out;
    unlink(@old);
    bmeta_out = null;
    bmeta_out_len = 0;
    bmeta_out_cap = 0;
}

!!! `driver_leaf_name` stands below with the arguments gn.exe is handed; the name
!!! the .bmeta is written under is taken with it.
stub str driver_leaf_name -> str name;

!!! One file the driver was asked for. -I stops after the preprocessed text, -R
!!! after the .r text, and anything else is handed to gn.exe - the front end runs
!!! there and cmp.exe writes the image, which is the three-stage walk the toolchain
!!! toolchain has. This is the walk blang makes over its input files.
!!!
!!! `run_gn` stands below with the arguments gn.exe is handed, and it is declared
!!! here because this is where it is reached from.
stub int run_gn -> str infile, str outfile, str spec;

int run_frontend -> str path {
    str spec = preproc_env_encode(driver_env());
    if g_emit_i {
        !!! -I stops after preprocessing: the text the tokenizer would see is what the
        !!! option asks for, and it goes to the output file the mode names (`a.i` when
        !!! -o did not give one), the way the driver writes it.
        str src = read_input(path);
        if src == null {
            return 1;
        }
        str pre = rt_preprocess_b(src, path, g_rimp_flags, spec, g_verbose);
        if pre == null {
            return 1;
        }
        str outfile = resolve_outfile();
        @void of = getFile(outfile, "w");
        if of == null {
            file_error(g_prog_name, "cannot write '" + outfile + "'");
            return 1;
        }
        writeFile(@of, pre);
        CloseHandle(of);
        return 0;
    }
    if g_emit_m {
        !!! -m: the .bmeta of a definition file. The front end is asked for the
        !!! signature of every stub, and the FUNC lines of the text it answers
        !!! become the entries of the file - that is the whole reason -m has an
        !!! entry point of its own. `-o` is not read here: the file is named after
        !!! the input, meta/<name>.bmeta, which is where a program that links the
        !!! DLL looks for it.
        str src = read_input(path);
        if src == null {
            return 1;
        }
        str rtext = rt_compile_b_stub_sigs(src, path, g_rimp_flags, spec, g_verbose);
        if rtext == null {
            return 1;
        }
        @BmetaFunc funcs = bmeta_parse_r(rtext);
        !!! The name the file gets: the input without its directory and without the
        !!! extension of its last part, so `native/libbstr.dll.b` answers
        !!! meta/libbstr.dll.bmeta.
        str base = "";
        if pe_eq(path, g_stdin_name) {
            !!! An input that came from a pipe has no name to take one from, so it
            !!! gets the one the driver gives an output no -o named (`a`).
            base = "a";
        } else {
            base = driver_leaf_name(path);
            int dot = -1;
            int bi = 0;
            while base[bi] != (char)0 {
                if base[bi] == '.' {
                    dot = bi;
                }
                bi = bi + 1;
            }
            if dot >= 0 {
                base = pe_sub(base, 0, dot);
            }
        }
        !!! Where the .bmeta of a linked DLL is looked for: the meta directory of the
        !!! install, which is beside the compiler when it stands in bin/ and under
        !!! it otherwise - the same pair bmeta_signatures reads.
        str meta_dir = "meta";
        if pe_len(g_home) > 0 {
            if pe_eq(driver_leaf_name(g_home), "bin") {
                meta_dir = g_home + "\\..\\meta";
            } else {
                meta_dir = g_home + "\\meta";
            }
        }
        str out_path = meta_dir + "\\" + base + ".bmeta";
        CreateDirectoryA(meta_dir, null);
        @void bf = getFile(out_path, "w");
        if bf == null {
            file_error(g_prog_name, "cannot write '" + out_path + "'");
            return 1;
        }
        bmeta_write(bf, funcs);
        CloseHandle(bf);
        return 0;
    }
    if g_emit_r {
        str src = read_input(path);
        if src == null {
            return 1;
        }
        str rtext = rt_compile_b(src, path, g_rimp_flags, spec, g_verbose);
        if rtext == null {
            return 1;
        }
        !!! -R stops after the .r text, which goes to the output file the mode names
        !!! (`a.r` when -o did not give one).
        str rfile = resolve_outfile();
        @void rf = getFile(rfile, "w");
        if rf == null {
            file_error(g_prog_name, "cannot write '" + rfile + "'");
            return 1;
        }
        writeFile(@rf, strip_to_line(rtext));
        CloseHandle(rf);
        return 0;
    }
    !!! Everything else goes through gn.exe, which is what the driver does: the
    !!! two of them are the same program family, only the front end runs there.
    !!! gn.exe reads the input itself, so a text that came in on a pipe must not be
    !!! read here first: doing that took the whole program out of the pipe before
    !!! gn.exe could see it, and the front end then compiled an empty file. What is
    !!! checked here is only that the file is there, the same fopen the driver
    !!! makes before anything runs.
    if !pe_eq(path, g_stdin_name) {
        @void probe = getFile(path, "r");
        if probe == null {
            fatal_file("", path, ": no such file or directory");
            return 1;
        }
        CloseHandle(probe);
    }
    return run_gn(path, resolve_outfile(), spec);
}

!!! ---- the arguments gn.exe is handed ----

!!! Whether a file is there. The handle is closed again at once: this asks about
!!! the .bst side files, which are small and are only ever opened to be looked at.
bool driver_file_exists -> str path {
    @void f = getFile(path, "r");
    if f == null {
        return false;
    }
    CloseHandle(f);
    return true;
}

!!! The name of a file without the directory in front of it, so a DLL named with a
!!! path (`bootstrap\bin\libbrtm.dll`) is still found in meta\.
str driver_leaf_name -> str name {
    int n = pe_len(name);
    int slash = -1;
    int i = 0;
    while i < n {
        if name[i] == '\\' || name[i] == '/' {
            slash = i;
        }
        i = i + 1;
    }
    if slash < 0 {
        return name;
    }
    return pe_sub_to_end(name, slash + 1);
}

!!! Whether meta/<dll>.bst is there: the side file that makes a DLL placeable into
!!! an executable. It is looked for where cmp reads it - beside the compiler, one
!!! directory above it, and the working directory.
bool side_file_exists -> str dll {
    str leaf = driver_leaf_name(dll);
    if driver_file_exists(g_home + "\\meta\\" + leaf + ".bst") {
        return true;
    }
    if driver_file_exists(g_home + "\\..\\meta\\" + leaf + ".bst") {
        return true;
    }
    return driver_file_exists("meta\\" + leaf + ".bst");
}

!!! Set when a -static DLL has no side file: the fatal message has been printed by
!!! then, and the run stops before gn.exe is started.
bool g_static_error;

!!! Where the runtime and the linked DLLs go. `--static-runtime` is cmp's own flag;
!!! -static names every -link / -d DLL one by one so its code is placed into the
!!! output, and a named DLL with no side file is reported here, before anything is
!!! linked, which is where the driver reports it.
str static_args {
    str out = "";
    if g_static_runtime {
        out = "--static-runtime";
    }
    if !g_static_all {
        return out;
    }
    int n = pe_len(g_link_dlls);
    int i = 0;
    while i < n {
        while i < n && g_link_dlls[i] == ' ' {
            i = i + 1;
        }
        if i >= n {
            skip;
        }
        int s = i;
        while i < n && g_link_dlls[i] != ' ' {
            i = i + 1;
        }
        str dll = link_dll_file(pe_sub(g_link_dlls, s, i - s));
        if !side_file_exists(dll) {
            fatal_file("-static: no static form of '", dll, "' (meta/" + dll +
                       ".bst not found; build that DLL with this compiler)");
            g_static_error = true;
            return out;
        }
        out = append_arg(out, "--embed=" + dll);
    }
    return out;
}

!!! The libraries and DLLs the linker is told about, in the order the driver
!!! builds them: the `-l` libraries as they were written, the `-link` / `-d` DLLs as
!!! `--link=`, the `-system` DLLs as `--system=` under their real file name, and the
!!! `-CMP,` arguments verbatim. The -static part comes first.
str linker_args {
    str out = static_args();
    if g_static_error {
        return out;
    }
    int n = pe_len(g_user_libs);
    int i = 0;
    while i < n {
        while i < n && g_user_libs[i] == ' ' {
            i = i + 1;
        }
        if i >= n {
            skip;
        }
        int s = i;
        while i < n && g_user_libs[i] != ' ' {
            i = i + 1;
        }
        out = append_arg(out, pe_sub(g_user_libs, s, i - s));
    }
    n = pe_len(g_link_dlls);
    i = 0;
    while i < n {
        while i < n && g_link_dlls[i] == ' ' {
            i = i + 1;
        }
        if i >= n {
            skip;
        }
        int s = i;
        while i < n && g_link_dlls[i] != ' ' {
            i = i + 1;
        }
        out = append_arg(out, "--link=" + link_dll_file(pe_sub(g_link_dlls, s, i - s)));
    }
    n = pe_len(g_system_dlls);
    i = 0;
    while i < n {
        while i < n && g_system_dlls[i] == ' ' {
            i = i + 1;
        }
        if i >= n {
            skip;
        }
        int s = i;
        while i < n && g_system_dlls[i] != ' ' {
            i = i + 1;
        }
        out = append_arg(out, "--system=" + system_dll_name(pe_sub(g_system_dlls, s, i - s)));
    }
    if g_linker_args != "" {
        out = append_arg(out, g_linker_args);
    }
    return out;
}

!!! ---- handing the work to gn.exe ----

!!! The list of imported signatures in a file, which is how it reaches gn.exe: one
!!! `extern=<name>:<type>` per function of every signature file runs to tens of
!!! kilobytes for kernel32 alone and did not survive the trip through the
!!! environment - what arrived was cut short and every name past the cut looked like
!!! an undeclared function. The variable itself is set as well, the way the toolchain
!!! driver sets it, and the file is removed again once the run is over.
str write_rimp_file {
    if g_rimp_flags == "" {
        return "";
    }
    SetEnvironmentVariableA("BLANG_RIMP", g_rimp_flags);
    @void cell;
    malloc(@cell, 1024);
    int n = GetTempPathA(1024, (str)cell);
    str dir = "";
    if n > 0 {
        dir = pe_sub((str)cell, 0, n);
    }
    unlink(@cell);
    str path = dir + "blang_rimp_" + (str)GetCurrentProcessId() + ".txt";
    @void f = getFile(path, "w");
    if f == null {
        return "";
    }
    writeFile(@f, g_rimp_flags);
    CloseHandle(f);
    SetEnvironmentVariableA("BLANG_RIMP_FILE", path);
    return path;
}

!!! Run gn.exe on one file: the input and, in one argument, the output followed by
!!! the links after a `;`. The two things that do not fit in an argument - the
!!! imported signatures and the preprocessor's environment - go across in the
!!! environment. The exit code is gn.exe's, so a link that failed is a run that
!!! failed, and the temporary list of signatures is removed either way.
int run_gn -> str infile, str outfile, str spec {
    str rimp_file = write_rimp_file();
    if g_verbose {
        SetEnvironmentVariableA("BLANG_VERBOSE", "1");
    }
    if spec != "" {
        SetEnvironmentVariableA("BLANG_PREPROC", spec);
    }
    str args = linker_args();
    if g_static_error {
        if rimp_file != "" {
            DeleteFileA(rimp_file);
        }
        return 1;
    }
    !!! The links travel with the output, after a `;`, which is the one argument
    !!! gn.exe splits.
    str gn_out = outfile;
    if args != "" {
        gn_out = outfile + " ; " + args;
    }
    str gn_path = beside_exe("gn.exe");
    str cmd = "\"" + gn_path + "\" \"" + infile + "\" \"" + gn_out + "\"";
    if g_verbose {
        !!! The trace this stage prints in the toolchain: the source, the driver,
        !!! the arguments it read, and the program it runs.
        @void cell;
        malloc(@cell, 1024);
        int an = GetFullPathNameA(infile, 1024, (str)cell, null);
        if an > 0 && an < 1024 {
            system.std_out("SOURCE_FILE=", (str)cell, "\n");
        }
        @void cell2;
        malloc(@cell2, 1024);
        int n = GetModuleFileNameA(null, (str)cell2, 1024);
        if n > 0 && n < 1024 {
            system.std_out("COLLECT_CMPL=", (str)cell2, "\n");
        }
        if an > 0 && an < 1024 {
            system.std_out("TARGET=", (str)cell, "\n");
        }
        system.std_out(zh_pick("Parsed args: ", "参数: "));
        int ai = 1;
        while ai < g_args.len {
            if ai > 1 {
                system.std_out(" ");
            }
            system.std_out(g_args.get(ai));
            ai = ai + 1;
        }
        system.std_out("\n");
        system.std_out("CODE=", cmd, "\n");
        unlink(@cell);
        unlink(@cell2);
    }
    int ret = run_program(gn_path, cmd);
    if rimp_file != "" {
        DeleteFileA(rimp_file);
    }
    if ret != 0 {
        return 1;
    }
    if g_verbose {
        puts_line(zh_pick("Compilation completed.", "编译完成。"));
    }
    return 0;
}

!!! cmp.exe on one file the backend reads itself. A `.r` input is the one case the
!!! driver runs the linker on directly, without the front end and without
!!! gn.exe: the file already carries the `#to` line cmp reads for the placement, so
!!! no `--type=` is passed and no temporary copy is made.
int run_cmp_file -> str infile, str outfile {
    !!! The code of an input that came in on standard input is written out first:
    !!! cmp.exe reads a file, so the text has to be one. It is removed as soon as
    !!! cmp.exe has run.
    str temp = "";
    if pe_eq(infile, g_stdin_name) {
        temp = write_temp_r(read_stream(GetStdHandle(-10)));
        if temp == "" {
            fatal("cannot write temp file ''");
            return 1;
        }
        infile = temp;
    }
    str args = "";
    if g_verbose {
        args = "-p";
    }
    str links = linker_args();
    if g_static_error {
        return 1;
    }
    args = append_arg(args, links);
    str cmp_path = beside_exe("cmp.exe");
    str cmd = "\"" + cmp_path + "\" \"" + infile + "\" -o \"" + outfile + "\"";
    if args != "" {
        cmd = cmd + " " + args;
    }
    if g_verbose {
        @void cell;
        malloc(@cell, 1024);
        int an = GetFullPathNameA(infile, 1024, (str)cell, null);
        if an > 0 && an < 1024 {
            system.std_out("SOURCE_FILE=", (str)cell, "\n");
        }
        @void cell2;
        malloc(@cell2, 1024);
        int n = GetModuleFileNameA(null, (str)cell2, 1024);
        if n > 0 && n < 1024 {
            system.std_out("COLLECT_CMPL=", (str)cell2, "\n");
        }
        if an > 0 && an < 1024 {
            system.std_out("TARGET=", (str)cell, "\n");
        }
        system.std_out("CODE=", cmd, "\n");
        unlink(@cell);
        unlink(@cell2);
    }
    int ret = run_program(cmp_path, cmd);
    if temp != "" {
        DeleteFileA(temp);
    }
    if ret != 0 {
        return 1;
    }
    if g_verbose {
        puts_line(zh_pick("Compilation completed.", "编译完成。"));
    }
    return 0;
}

int main {
    !!! The module directory is what the `#head` search and the lookup of gn.exe /
    !!! cmp.exe both start from, so it is read before anything else - the toolchain calls
    !!! blang_setup_home() in the same place.
    setup_home();
    !!! The color codes of every diagnostic are libbstr's, so the terminal has to be
    !!! asked for them once, before the first message.
    ux_color_init();
    str cmd = GetCommandLineA();
    if cmd == null {
        fatal("cannot read the command line");
        return 1;
    }
    split_cmd(cmd);
    if g_args.len == 0 {
        fatal("no command line");
        return 1;
    }
    !!! `-Chinese` switches every diagnostic of this driver and of the front end it
    !!! starts (gn.exe reads the variable) to Chinese. The option is looked for
    !!! before the argument loop, because the loop itself reports fatal errors.
    int ci = 1;
    while ci < g_args.len {
        if arg_eq(g_args.get(ci), "-Chinese") {
            zh_enable(true);
            SetEnvironmentVariableA("BLANG_CHINESE", "1");
            ci = g_args.len;
        } else {
            ci = ci + 1;
        }
    }
    int rc = take_options();
    if rc == 2 {
        return 0;
    }
    if rc != 0 {
        return rc;
    }
    if g_show_builtins {
        print_builtins();
        return 0;
    }
    if g_inputs.len == 0 {
        fatal("no input file");
        return 1;
    }
    if g_emit_r && g_emit_i {
        fatal("-R and -I cannot be used together");
        return 1;
    }
    !!! Every input in turn, which is the walk blang makes over its input files.
    !!! The code of a `.r` input and of a compiled one is added up and the walk goes
    !!! on to the next file, while the three text modes (-I, -m and -R) write their
    !!! one file and end the run: each of them returns from the loop in blang.
    int total_rc = 0;
    int fi = 0;
    while fi < g_inputs.len {
        str input = g_inputs.get(fi);
        g_cur_input = fi;
        !!! A program that comes in on standard input is named `<stdin>` and has no
        !!! file whose line a message could quote: every diagnostic keeps its header
        !!! line - the file, the place and the text - and nothing stands below it. The
        !!! switch is set for every input, so a run over a file after one over a pipe
        !!! shows the file's lines again.
        ux_show_source(!pe_eq(input, g_stdin_name));
        !!! A `.r` input is compiled by cmp.exe directly, which is what the driver
        !!! does with it: the front end has nothing to add and the two text modes have
        !!! nothing to write. Intermediate code that came in on a pipe counts as one
        !!! (the `r` language word in front of the `-`).
        bool is_r = ends_with(input, ".r") || (pe_eq(input, g_stdin_name) && g_stdin_is_r);
        !!! An input that is a file of the machine has to be there. cmp.exe checks a
        !!! `.r` file itself, and an input that came in on standard input is not a
        !!! file at all, so only a `.b` file is opened for the check here.
        if !is_r && !pe_eq(input, g_stdin_name) {
            if !driver_file_exists(input) {
                fatal_file("", input, ": no such file or directory");
                return 1;
            }
        }
        if is_r {
            if g_emit_r {
                fatal("-R is meaningless for .r input files");
                return 1;
            }
            if g_emit_i {
                fatal("-I is meaningless for .r input files");
                return 1;
            }
            if run_cmp_file(input, resolve_outfile()) != 0 {
                total_rc = 1;
            }
            fi = fi + 1;
            continue;
        }
        !!! The functions of the DLLs this build links, read from their .bmeta and
        !!! added to the flags the code generator is built with. the toolchain reads them
        !!! after -I has answered (that mode stops before them) and before -m, -R and
        !!! the full compile, and a DLL whose .bmeta cannot be read stops the run.
        if !g_emit_i {
            if !collect_externs() {
                return 1;
            }
        }
        int rc = run_frontend(input);
        if g_emit_i || g_emit_m || g_emit_r {
            return rc;
        }
        if rc != 0 {
            total_rc = 1;
        }
        fi = fi + 1;
    }
    return total_rc;
}
