!~
 ~  writefile_example.b: write values to the console with WriteFile.
 ~
 ~  Build: blang.exe examples/writefile_example.b -system kernel32 -o writefile.exe
 ~
 ~  `system.out` is the usual way to print; this is the same thing by hand, and
 ~  it is what a program does when it wants to decide the exact bytes that leave
 ~  it. A value becomes text with `(str)`, and that text goes to the kernel
 ~  through WriteFile.
 ~
 ~  WriteFile takes a length, not a terminator, so `lstrlenA` supplies the byte
 ~  count and the text does not have to end with a NUL. The fourth parameter is
 ~  an out parameter that receives how many bytes were written; the fifth is the
 ~  overlapped pointer, null for a console write.
 ~
 ~  Build: blang.exe writefile_example.b -o writefile_example.exe -system kernel32
 ~!

!!! The handle of standard output (-11) and of standard error (-12).
local @void _stdout {
    return GetStdHandle(-11);
}

local @void _stderr {
    return GetStdHandle(-12);
}

!!! One piece of text, exactly as it is.
void write_text -> @void h, str s {
    @int written;
    WriteFile(h, s, lstrlenA(s), @written, null);
}

!!! One int: `(str)v` is the number-to-text conversion, so the bytes written are
!!! its decimal digits. The text lives in a buffer the compiler owns and reuses
!!! for every later conversion, so it is written before the next `(str)`.
void write_int -> @void h, int v {
    write_text(h, (str)v);
}

!!! A 64-bit value, printed whole: `(str)` of a longlong carries all 8 bytes
!!! through the conversion instead of the low 32 bits of an int.
void write_longlong -> @void h, longlong v {
    write_text(h, (str)v);
}

!!! The language's float is a C double, so `(str)` gives its decimal form.
void write_float -> @void h, float v {
    write_text(h, (str)v);
}

int main {
    @void out = _stdout();

    write_text(out, "count = ");
    write_int(out, 42);
    write_text(out, "\n");

    write_text(out, "neg   = ");
    write_int(out, -7);
    write_text(out, "\n");

    longlong big = 9000000000;
    write_text(out, "big   = ");
    write_longlong(out, big);
    write_text(out, "\n");

    write_text(out, "sum   = ");
    write_longlong(out, big + 5);
    write_text(out, "\n");

    write_text(out, "float = ");
    write_float(out, 2.5);
    write_text(out, "\n");

    !!! A whole line in one call. WriteFile returns 0 when it failed, which is
    !!! the one thing `system.out` cannot report.
    str line = "done\n";
    @int written;
    int ok = WriteFile(out, line, lstrlenA(line), @written, null);
    if ok == 0 {
        write_text(_stderr(), "write failed\n");
    }
    return 0;
}
