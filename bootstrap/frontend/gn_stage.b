#once
!~
 ~  bootstrap/frontend/gn_stage.b: the stage that turns .r text into an image.
 ~
 ~  It is the gn's work after the front end has run: the `#to` line at the
 ~  head of the text carries what cmp.exe is asked for, the text without that line goes
 ~  to a temporary file under %TEMP%, cmp.exe is run on it with that text passed on as
 ~  command-line arguments exactly as it was written plus the arguments the driver
 ~  forwarded, and the file is removed again. The exit code is cmp's, so a link that
 ~  failed is a run that failed.
 ~
 ~  gn.exe runs this, and nothing else does: blang.exe hands the work to gn.exe the
 ~  way the toolchain does, and the .r input path runs cmp.exe on the file it was given
 ~  without a temporary copy at all, which is blang.b's own business.
 ~!

#head "driver_common"

!!! ---- the `#to` line and what it asks for ----

!!! The text of a `#to` line without the blank space around it, which is what is handed
!!! to cmp.exe as arguments.
str gn_trim -> str text {
    int b = 0;
    int e = pe_len(text);
    while b < e && (text[b] == ' ' || text[b] == '\t' || text[b] == '\r') {
        b = b + 1;
    }
    while e > b && (text[e - 1] == ' ' || text[e - 1] == '\t' || text[e - 1] == '\r') {
        e = e - 1;
    }
    return pe_sub(text, b, e - b);
}

!!! ---- running cmp.exe ----

!!! The .r text goes to cmp.exe: the `#to` line is read and taken off the head, what
!!! is left is written to a temporary file, and the text the line carried is handed to
!!! cmp as command-line arguments exactly as it was written - so `#to type=dll` asks
!!! cmp for a DLL the way cmp spells it, `#to --type=dll` says the same in cmp's
!!! option spelling, and any other flag reaches cmp unchanged. The linker arguments
!!! the driver forwarded come after them, and the exit code is cmp's, so a link that
!!! failed is a run that failed.
int gn_run_cmp -> str rtext, str outfile, str cmp_args, bool verbose {
    str code = rtext;
    str to_args = "";
    if pe_matches(rtext, 0, "#to ") {
        int nl = pe_find(rtext, '\n');
        if nl >= 0 {
            to_args = gn_trim(pe_sub(rtext, 4, nl - 4));
            code = pe_sub_to_end(rtext, nl + 1);
        } else {
            to_args = gn_trim(pe_sub_to_end(rtext, 4));
        }
    }
    !!! The name of the temporary .r file comes from driver_common.b, which is
    !!! where blang.exe finds it too: an input that came in on a pipe is written to
    !!! one before cmp.exe is handed it.
    str tmp = temp_r_path();
    @void tf = getFile(tmp, "w");
    if tf == null {
        !!! The message gn.exe prints when it cannot write its temporary file.
        system.err(zh_msg("gn: cannot write temp file '" + tmp + "'"), "\n");
        return 1;
    }
    writeFile(@tf, code);
    CloseHandle(tf);

    !!! Pass -p to cmp.exe when the run is verbose, which is what gn.exe does with
    !!! BLANG_VERBOSE.
    str args = cmp_args;
    if verbose {
        args = append_arg(args, "-p");
    }
    !!! cmp.exe stands beside the compiler, which is where the toolchain looks for it
    !!! (BLANG_HOME/cmp.exe).
    str cmp_path = beside_exe("cmp.exe");
    str cmd = "\"" + cmp_path + "\" \"" + tmp + "\" -o \"" + outfile + "\"";
    if to_args != "" {
        cmd = cmd + " " + to_args;
    }
    if args != "" {
        cmd = cmd + " " + args;
    }
    if verbose {
        !!! The trace gn.exe prints in the toolchain: its own module, the .r it
        !!! wrote, the placement the `#to` line named, and the command line cmp.exe
        !!! is handed.
        @void cell;
        malloc(@cell, 1024);
        int n = GetModuleFileNameA(null, (str)cell, 1024);
        if n > 0 && n < 1024 {
            system.std_out("COLLECT_CMPL=", (str)cell, "\n");
        }
        system.std_out("TARGET=", tmp, "\n");
        if to_args != "" {
            system.std_out("gn.exe: #to ", to_args, "\n");
        }
        system.std_out("CODE=", cmd, "\n");
        unlink(@cell);
    }
    int ret = run_program(cmp_path, cmd);
    DeleteFileA(tmp);
    if ret != 0 {
        return 1;
    }
    return 0;
}
