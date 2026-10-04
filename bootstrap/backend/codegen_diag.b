#once
!~
 ~  bootstrap/backend/codegen_diag.b: the diagnostics of the code generator.
 ~
 ~  the one format every backend error uses,
 ~  and the report of a call that never resolved to an implementation.
 ~!

#head "cg_heads"

!!! A 32-bit value in upper-case hexadecimal, the way `%llX` writes it.
str cg_hex_upper -> int v {
    str digits = "0123456789ABCDEF";
    if v == 0 {
        return "0";
    }
    @void cell;
    cg_balloc(@cell, 24);
    @char d = (@char)cell;
    int n = 0;
    int x = v;
    while x > 0 {
        d[n] = digits[x & 15];
        n = n + 1;
        x = (x >> 4) & 0x0FFFFFFF;
    }
    @char out = (@char)cell + 12;
    int i = 0;
    while i < n {
        out[i] = d[n - 1 - i];
        i = i + 1;
    }
    out[n] = (char)0;
    return (str)out;
}

!!! "<file>:<line>:<col>: error: <msg>". A diagnostic with no meaningful source
!!! position - the statement was synthesised by the generator rather than written in
!!! the source - is reported without file, line or column.
str cg_err_at -> int line, int col, str msg {
    if line <= 0 || col <= 0 {
        return "cmp.exe: error: " + msg;
    }
    return cg_filename + ":" + (str)line + ":" + (str)col + ": error: " + msg;
}

!!! A call that has no source position (the generator emitted it itself, an entry
!!! point for instance) is located by its offset in the code section.
void cg_report_undefined_ref -> str name {
    int pos = em_tell();
    cg_link_errors = cn_str(cg_link_errors,
                            "cmp.exe: (.text+" + cg_hex_upper(pos) +
                            "): undefined reference '" + name + "'");
}
