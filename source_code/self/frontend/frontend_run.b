#once
!~
 ~  bootstrap/frontend/frontend_run.b: the front end on one file.
 ~
 ~  `rt_compile_b` is the
 ~  entry blang.exe and gn.exe both call to turn a `.b` text into `.r` text, and
 ~  `rt_preprocess_b` is the one -I calls, which stops after preprocessing. the toolchain
 ~  puts both in the library the two drivers link; this implementation includes this module in
 ~  both of them, after the front-end modules it drives.
 ~
 ~  What the front end has to be told travels as text, exactly as it does between
 ~  blang.exe and gn.exe: `rimp` is the `extern=<name>:<type>` list of every linked
 ~  DLL, and `preproc_spec` is the preprocessor's environment - the -D/-U/-P names,
 ~  the linked DLLs and the built-in conditions - encoded by preproc_env_encode. A
 ~  caller that passes nothing (gn.exe compiling a `.b` file on its own) gets the
 ~  compiler's own defaults, which is what gn.exe gets too.
 ~
 ~  The answer is the text, or null when a stage reported something: the messages
 ~  have been printed by then.
 ~!

#head "Chinese/chinese_heads"

!!! The `#to` flags the preprocessor collected, in front of the .r text.
!!!
!!! the generator writes the line into the text itself; this implementation keeps the flags
!!! in a list, so the same line is rebuilt here. The callers read it and take it off
!!! again - gn.exe reads the placement off it, -R writes the text without it - so
!!! what cmp.exe is handed and what -R writes are what the toolchain produces.
str fe_to_line -> str rtext {
    if pp_to_flags == null {
        return rtext;
    }
    str line = "#to";
    @NameList f = pp_to_flags;
    while f != null {
        line = line + " " + f.name;
        f = f.next;
    }
    return line + "\n" + rtext;
}

!!! The one implementation behind the two entry points below, which is the shape
!!! s `compile_b` has.
str fe_run -> str src, str fname, str rimp, str preproc_spec, bool verbose,
              bool preprocess_only, bool stub_sigs {
    !!! The color codes of every diagnostic belong to libbstr, so the terminal has to
    !!! be asked for them once. the toolchain entry point does it in the same place.
    ux_color_init();
    time_check();
    @PreprocEnv env = preproc_env_decode(preproc_spec);

    int t_pp = time_now();

    !!! The preprocessor runs over the file as it was written: it resolves the
    !!! `#head`s, the `#if` family, the replacements and the newline markers, and the
    !!! tokenizer below is handed its text with the line map it built. `-I` asks for
    !!! that text on its own and leaves the `#to` lines in it, which is the walk the
    !!! compiler has a second entry point for.
    str pre = "";
    if preprocess_only {
        pre = preprocess_only_source(src, fname, env);
    } else {
        pre = preprocess_source(src, fname, env);
    }
    if pp_run_error {
        print_pp_error(src, fname);
        return (str)null;
    }
    print_pp_warnings();
    time_print("preprocess", time_now() - t_pp);
    if preprocess_only {
        return pre;
    }
    !!! The scanner names the file in every diagnostic it prints, so it is told
    !!! which file this text came from before the first token is read, and it is
    !!! given the two maps the preprocessor built: the line map and the replacement
    !!! positions are what turn a position of this text back into the place in the
    !!! source a diagnostic names.
    g_file = fname;
    lex_set_maps(pp_map, pp_new_rep);
    int t_lex = time_now();
    lex_start(pre);
    !!! The tokens of the whole file are read once into a vector: the parser walks
    !!! that list by index, so it can look at the token after the one it stands on
    !!! (a declaration and a function head differ only there) and the scanner never
    !!! has to run twice over the same text. The dump is what -p asks for.
    int tokens = lex_all();
    time_print("lex", time_now() - t_lex);
    if verbose {
        dump_tokens(tokens);
    }
    p_start();
    p_errors = 0;
    p_nodes = 0;
    p_stmts = 0;
    !!! The parse runs even when the scan reported something, which is what the toolchain
    !!! driver does: a bad character in one statement does not stop the rest of the
    !!! file from being read, and the two sets of messages belong together.
    int t_parse = time_now();
    @StmtNode program = parse_program();
    time_print("parse", time_now() - t_parse);
    if verbose {
        !!! The token and statement counts are what the driver prints with -p.
        system.std_out("tokens: ", tokens, "  problems: ", g_diags, "\n");
        system.std_out("statements: ", count_stmts(program), "  nodes: ", p_nodes,
                       "  problems: ", p_errors, "\n");
    }
    !!! The code generator runs over the statement chain the parser built even when
    !!! the scan or the parse reported something: the driver reads the whole
    !!! file, generates, and only then prints the messages of the tokenizer, the
    !!! parser and the generator as one block. Stopping here instead hid every
    !!! error the generator would have found after a parse error, and those
    !!! follow-on errors are the point of recovering from the first one. A tree the
    !!! parser left broken is what the `broken` flag is for, and the generator's
    !!! passes skip those statements the way the toolchain ones do.
    !!!
    !!! `rimp` is what it was built with: one `extern=` entry per function of every
    !!! linked DLL, plus the -Rimp- pairs and -Econversion, without which a call
    !!! into a linked DLL would be an undeclared function. The notes collected by
    !!! the parser come before the generator's own (the driver seeds `notes`
    !!! with `parser.get_block_notes()` before the RGenerator is built).
    rg_err = "";
    rg_notes = p_block_notes;
    int t_gen = time_now();
    rg_rgenerator(rimp);
    rg_stmts = program;
    rgx_out_reset();
    !!! -m asks for the signature of every `stub` to be written into the `.r` text,
    !!! which is what the reader of the .bmeta harvests its entries from; an
    !!! ordinary build writes no stub signature, because a stub is a declaration
    !!! that no code implements there.
    rg_emit_stub_sigs(stub_sigs);
    str rtext = rg_generate();
    time_print("generate", time_now() - t_gen);
    !!! the driver decides on the *text* of the diagnostics, not on a flag the
    !!! generator set: a file that only declares stubs (pkg.b) generates no error and
    !!! no .r text at all, and the empty .r is written and the run succeeds.
    !!!
    !!! Warnings and the deferred notes are printed the way the toolchain entry point
    !!! prints them: they follow the errors in the same block when there are
    !!! errors, and stand on their own - without failing the run - when there are
    !!! none. A warning that was never printed is a diagnostic the compiler owes its
    !!! caller, so the block is built here rather than dropped.
    if !pe_eq(rg_err, "") {
        str all = rg_err;
        if !pe_eq(rg_notes, "") {
            if all[pe_len(all) - 1] != '\n' {
                all = all + "\n";
            }
            all = all + rg_notes;
        }
        !!! The category word of every `file:line:col: error:` header in the block
        !!! is translated here, which is where the driver does it
        !!! (`fputs(zh_prefixes(all_err).c_str(), stderr)`); the message bodies were
        !!! translated where they were built.
        system.err(zh_prefixes(all));
    } else if !pe_eq(rg_notes, "") {
        system.err(zh_prefixes(rg_notes));
    }
    !!! The tokenizer's and the parser's messages were printed where they were
    !!! found, and the generator's are printed above: any of the three reported
    !!! something, so the run stops where the driver stops (it answers nullptr
    !!! as soon as all_err is not empty).
    if g_diags > 0 || p_errors > 0 || !pe_eq(rg_err, "") {
        return (str)null;
    }
    return fe_to_line(rtext);
}

!!! rt_compile_b: the `.r` text of one source file.
str rt_compile_b -> str src, str fname, str rimp, str preproc_spec, bool verbose {
    return fe_run(src, fname, rimp, preproc_spec, verbose, false, false);
}
