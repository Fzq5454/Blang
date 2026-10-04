#once
!~
 ~  bootstrap/backend/cmp_text.b: the text helpers the .r compiler needs.
 ~
 ~  cmp.exe is a program of its own, so it does not reach across to the frontend's
 ~  preproc_env.b: the handful of helpers it uses - a length, an equality, a
 ~  substring and the offset of a character - stand here with the same names and the
 ~  same behaviour.
 ~!

!!! The length of a text. A null text is empty and not a fault: a field of a struct
!!! that was never written holds null, and the `str` it stands for is
!!! empty there. `pe_len(x) == 0` is how this implementation asks `x.empty()`.
int pe_len -> str s {
    if s == null {
        return 0;
    }
    int n = 0;
    while s[n] != (char)0 {
        n = n + 1;
    }
    return n;
}

bool pe_eq -> str a, str b {
    if a == null {
        return b == null;
    }
    if b == null {
        return false;
    }
    int i = 0;
    while a[i] != (char)0 {
        if a[i] != b[i] {
            return false;
        }
        i = i + 1;
    }
    return b[i] == (char)0;
}

!!! The first `len` characters of `s` from `from`, as a block of its own.
str pe_sub -> str s, int from, int len {
    if len < 0 {
        len = 0;
    }
    @void cell;
    cg_balloc(@cell, len + 1);
    @char d = (@char)cell;
    int i = 0;
    while i < len && s[from + i] != (char)0 {
        d[i] = s[from + i];
        i = i + 1;
    }
    d[i] = (char)0;
    return (str)cell;
}

!!! From `from` to the end.
str pe_sub_to_end -> str s, int from {
    return pe_sub(s, from, pe_len(s) - from);
}

!!! One character as a text of its own.
str pe_char -> char c {
    @void cell;
    cg_balloc(@cell, 2);
    @char d = (@char)cell;
    d[0] = c;
    d[1] = (char)0;
    return (str)cell;
}

!!! Append one character to a text: `s += c`, which the language does not have.
str pe_add_ch -> str s, char c {
    int n = pe_len(s);
    @void cell;
    cg_balloc(@cell, n + 2);
    @char d = (@char)cell;
    int i = 0;
    while i < n {
        d[i] = s[i];
        i = i + 1;
    }
    d[n] = c;
    d[n + 1] = (char)0;
    return (str)cell;
}

!!! ---- reading a number out of a token ----

!!! `strtoll(s, null, 10)`: whitespace, an optional sign and the decimal digits that
!!! follow. A `.r` carries its integer literals as text, so every one of them is
!!! read back with this; `(longlong)s` would be the address of the text.
longlong pe_atoll -> str s {
    int n = pe_len(s);
    int i = 0;
    while i < n && (s[i] == ' ' || s[i] == '\t' || s[i] == '\n' || s[i] == '\r') {
        i = i + 1;
    }
    bool neg = false;
    if i < n && (s[i] == '+' || s[i] == '-') {
        if s[i] == '-' {
            neg = true;
        }
        i = i + 1;
    }
    longlong v = 0;
    while i < n && s[i] >= '0' && s[i] <= '9' {
        v = v * 10 + (longlong)((int)s[i] - 48);
        i = i + 1;
    }
    if neg {
        return 0 - v;
    }
    return v;
}

!!! `atoi(s)`: the same reader, narrowed to the int the field offsets, array
!!! dimensions, spread tags and character codes are.
int pe_atoi -> str s {
    return (int)pe_atoll(s);
}

!!! One power of ten as a float. Up to 10^22 every power is a value a double holds
!!! exactly, so the reader below multiplies exact values by exact ones; past that
!!! the text has more digits than a double has, and this is as close as strtod
!!! without strtod can be.
float pe_pow10 -> int n {
    float r = 1.0;
    while n >= 22 {
        r = r * 10000000000000000000000.0;
        n = n - 22;
    }
    while n > 0 {
        r = r * 10.0;
        n = n - 1;
    }
    return r;
}

!!! `strtod(s, null)`: the double nearest to the decimal the text names. the toolchain
!!! hands the text to strtod; this implementation collects the digits into a whole number and
!!! then moves the point with one multiplication or one division by a power of ten.
!!! Reading the fraction digit by digit instead (`v = v + d * scale`,
!!! `scale = scale * 0.1`) accumulated the error of every 0.1 in the answer, which
!!! is why the front end's p_float_value reads it this way too.
float pe_atof -> str s {
    int n = pe_len(s);
    longlong man = 0;
    int expo = 0;
    int i = 0;
    bool neg = false;
    if i < n && (s[i] == '+' || s[i] == '-') {
        if s[i] == '-' {
            neg = true;
        }
        i = i + 1;
    }
    !!! The whole part: digits past the nineteenth are beyond what a double can put
    !!! back, so they only make the number bigger by a power of ten. The digit is
    !!! only added while the answer still fits: `man * 10 + digit` passes 2^63-1 as
    !!! soon as man is above 922337203685477579, and the wrap turns the value
    !!! negative. The same bound stands in the front end's p_float_value.
    while i < n && s[i] >= '0' && s[i] <= '9' {
        if man <= 922337203685477579 {
            man = man * 10 + (longlong)((int)s[i] - 48);
        } else {
            expo = expo + 1;
        }
        i = i + 1;
    }
    if i < n && s[i] == '.' {
        i = i + 1;
        while i < n && s[i] >= '0' && s[i] <= '9' {
            if man <= 922337203685477579 {
                man = man * 10 + (longlong)((int)s[i] - 48);
                expo = expo - 1;
            }
            i = i + 1;
        }
    }
    if i < n && (s[i] == 'e' || s[i] == 'E') {
        i = i + 1;
        int esign = 1;
        if i < n && (s[i] == '+' || s[i] == '-') {
            if s[i] == '-' {
                esign = 0 - 1;
            }
            i = i + 1;
        }
        int ex = 0;
        while i < n && s[i] >= '0' && s[i] <= '9' {
            ex = ex * 10 + ((int)s[i] - 48);
            i = i + 1;
        }
        expo = expo + esign * ex;
    }
    float v = (float)man;
    if expo >= 0 {
        v = v * pe_pow10(expo);
    } else {
        v = v / pe_pow10(0 - expo);
    }
    if neg {
        v = 0.0 - v;
    }
    return v;
}
