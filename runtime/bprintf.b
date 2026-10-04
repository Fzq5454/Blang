!~
 ~  runtime/bprintf.b: the printf runtime, written in blang.
 ~
 ~  This was lib/bprintf.lib, machine code that blibobj4 emitted. `includes/bl/format`
 ~  reaches it through `__bcall`, and the `__get_format__` helper the compiler writes
 ~  parses the format string and emits one of these per piece.
 ~
 ~  Build: blang.exe runtime/bprintf.b '-CMP,--no-runtime' -system kernel32 -o bin/libbprintf.dll
 ~  Nothing from the other runtime is used here: every piece is written with
 ~  WriteFile, and a number becomes text through the conversion the compiler emits
 ~  into this image itself. That keeps this DLL dependent on nothing but kernel32.
 ~
 ~  Contract, from the native version:
 ~    _printf_s(str)               a NUL-terminated string
 ~    _printf_n(str, off, n)       n bytes of it from off (the literal runs)
 ~    _printf_d(int)               a decimal integer
 ~    _printf_l(longlong)          a decimal 64-bit integer
 ~    _printf_c(char)              one character
 ~    _printf_f(float, prec)       `prec` digits after the point
 ~    _printf_p(@void, prec)       "0x" and `prec` uppercase hex digits
 ~!

#to type=dll

int DllMain {
    return 1;
}

!~ ---------- writing ---------- ~!

!!! `n` bytes of `s`, with no terminator needed: WriteFile takes the length.
local void _put -> str s, int n {
    @void out = GetStdHandle(-11);
    @int written;
    WriteFile(out, s, n, @written, null);
}

local void _puts -> str s {
    _put(s, lstrlenA(s));
}

!!! One character, taken from the byte the value sits in.
local void _putc -> char c {
    @char p = @c;
    _put((str)p, 1);
}

local void _put_hex_digit -> int nib {
    int code = nib + 48;
    if nib > 9 {
        code = nib + 55;
    }
    _putc((char)code);
}

!~ ---------- the six the format helper calls ---------- ~!
!~ The value is an `any` because that is what the helper hands over: it keeps
!~ each argument in one raw 8-byte slot and calls with that, so a `str` or an
!~ `int` declared here would be rejected at the call. `(str)`/`(int)`/`(char)` on
!~ an `any` reinterpret the slot, which is exactly what the native code did by
!~ reading it as whatever the verb said. ~!

void _printf_s -> any s {
    _puts((str)s);
}

void _printf_n -> any s, int off, int n {
    @char p = (@char)(str)s;
    _put((str)(p + off), n);
}

void _printf_c -> any c {
    _putc((char)c);
}

void _printf_d -> any n {
    _puts((str)(int)n);
}

!!! The 64-bit decimal: `%l`, and the C spellings `%ld` / `%lld` reach it too.
!!! `%d` stays the 32-bit one, so a format written for an int keeps printing the
!!! int it was written for.
void _printf_l -> any n {
    _puts((str)(longlong)n);
}

!~ ---------- the unsigned verbs %u, %lu and %llu ---------- ~!
!~ A negative slot is the value 2^32 (or 2^64) more than it looks, which is what
!~ the unsigned verb prints. The division the hardware does is the signed one, so
!~ the 64-bit quotient is walked out bit by bit; the same routine lives in the
!~ runtime, which this DLL cannot call: a runtime DLL is built with no runtime
!~ behind it. ~!

local bool _uge64 -> longlong a, longlong b {
    if a < 0 {
        if b < 0 {
            return a >= b;
        }
        return true;
    }
    if b < 0 {
        return false;
    }
    return a >= b;
}

local longlong _udiv64 -> longlong a, longlong b {
    if b == 0 {
        return 0;
    }
    longlong one = 1;
    longlong q = 0;
    longlong r = 0;
    int i = 63;
    while i >= 0 {
        r = (r << 1) | ((a >> i) & 1);
        if _uge64(r, b) {
            r = r - b;
            q = q | (one << i);
        }
        i = i - 1;
    }
    return q;
}

local int _umod64 -> longlong v, int d {
    return (int)(v - _udiv64(v, d) * d);
}

!!! One unsigned decimal, most significant digit first: every digit but the last
!!! is written by the call that divided once more.
local void _put_unsigned -> longlong v {
    if _uge64(v, 10) {
        _put_unsigned(_udiv64(v, 10));
    }
    _putc((char)(_umod64(v, 10) + 48));
}

!!! `%u`: a 32-bit slot read as unsigned.
void _printf_u -> any n {
    longlong v = (longlong)(int)n;
    if v < 0 {
        v = v + 4294967296;
    }
    _put_unsigned(v);
}

!!! `%lu` / `%llu`: a 64-bit slot read as unsigned.
void _printf_ul -> any n {
    _put_unsigned((longlong)n);
}

void _printf_f -> float v, int prec {
    float f = v;
    if f < 0.0 {
        _puts("-");
        f = 0.0 - f;
    }
    int scale = 1;
    int i = 0;
    while i < prec {
        scale = scale * 10;
        i = i + 1;
    }
    !!! Rounding at the last wanted digit, then splitting the scaled value is
    !!! what gives exactly `prec` digits after the point.
    float scaled = f * (float)scale + 0.5;
    int all = (int)scaled;
    int whole = all / scale;
    int frac = all - whole * scale;
    _puts((str)whole);
    if prec > 0 {
        _puts(".");
        int div = scale / 10;
        i = 0;
        while i < prec {
            int d = frac / div;
            frac = frac - d * div;
            div = div / 10;
            _putc((char)(d + 48));
            i = i + 1;
        }
    }
}

void _printf_p -> any p, int prec {
    _puts("0x");
    !!! The pointer value read as two halves. `(int)p` reinterprets, it does not
    !!! touch memory, and storing it in an int keeps its low 32 bits; shifting it
    !!! is a 64-bit shift, so the high half comes out of the same value.
    int low = (int)p;
    int high = ((int)p) >> 32;
    int i = prec - 1;
    while i >= 0 {
        int nib = 0;
        if i < 8 {
            nib = (low >> (i * 4)) & 15;
        } else {
            nib = (high >> ((i - 8) * 4)) & 15;
        }
        _put_hex_digit(nib);
        i = i - 1;
    }
}
