!~
 ~  runtime/bmath.b: the math runtime, written in blang.
 ~
 ~  This was lib/bmath.lib, machine code that blibobj2 emitted. `includes/bl/bmath`
 ~  reaches it through `__bcall`.
 ~
 ~  Build: blang.exe runtime/bmath.b '-CMP,--no-runtime' -system kernel32 -o bin/libbmath.dll
 ~  Nothing outside the language is used, so this DLL depends on nothing else.
 ~
 ~  Contract, from the native version:
 ~    _pow(float x, float y) -> float      x raised to y
 ~    _sqrt(float x) -> float              square root, NaN when x < 0
 ~    _cbrt(float x) -> float              cube root, NaN when x < 0
 ~    _amrt(float x, float y) -> float     the y-th root of x
 ~    _ceil(float x) -> int                up
 ~    _floor(float x) -> int               down
 ~    _round(float x) -> int               halves away from zero
 ~    _abs(float x) -> float
 ~    _mod(float x, float y) -> float      C fmod, the sign follows x
 ~    _num(float x) -> int                 truncated toward zero
 ~    _prec(float x, int y) -> float       x rounded to y decimal places
 ~
 ~  The native library computed the powers and roots on the x87 unit with
 ~  fyl2x / f2xm1 / fscale, which the language cannot reach. The same values are
 ~  reached here with the two series below, ln and exp, plus Newton for the
 ~  square root, and the whole powers are exact by squaring.
 ~
 ~  Every local below carries its function's initials. The front end keeps one
 ~  table of names for the whole file, so a plain `t` declared as float in one
 ~  function turns a later `int t` in another into a float, and the mismatches
 ~  that follow are reported in the second function. Unique names avoid it.
 ~
 ~  One native bug is deliberately not copied. Its `_ceil` jumped two bytes
 ~  instead of three to skip its own `inc rax`, landing inside that instruction
 ~  and running off into `_floor` whenever trunc(x) >= x, which is every whole
 ~  number and every negative x. blibobj2 carries the fix, and here the
 ~  function is simply correct.
 ~!

#to type=dll

int DllMain {
    return 1;
}

!~ ---------- helpers ---------- ~!

!!! A quiet NaN, for the arguments the x87 unit used to reject.
local float _nan {
    float nz = 0.0;
    return nz / nz;
}

!!! Whether `x` holds a whole number, which is what makes an exact power
!!! possible.
local int _whole -> float x {
    float wf = (float)((int)x);
    if wf == x {
        return 1;
    }
    return 0;
}

!!! Natural logarithm: scale x into [1,2) by powers of two, then the atanh
!!! series ln(t) = 2 * (z + z^3/3 + z^5/5 + ...) with z = (t-1)/(t+1).
local float _ln -> float x {
    if x <= 0.0 {
        return _nan();
    }
    int ln_k = 0;
    float ln_t = x;
    while ln_t >= 2.0 {
        ln_t = ln_t / 2.0;
        ln_k = ln_k + 1;
    }
    while ln_t < 1.0 {
        ln_t = ln_t * 2.0;
        ln_k = ln_k - 1;
    }
    float ln_z = (ln_t - 1.0) / (ln_t + 1.0);
    float ln_zz = ln_z * ln_z;
    float ln_sum = 0.0;
    float ln_term = ln_z;
    int ln_n = 1;
    while ln_n <= 41 {
        ln_sum = ln_sum + ln_term / (float)ln_n;
        ln_term = ln_term * ln_zz;
        ln_n = ln_n + 2;
    }
    return 2.0 * ln_sum + (float)ln_k * 0.6931471805599453;
}

!!! e raised to x: reduce x to a remainder of at most half of ln 2, sum the
!!! Taylor series there, then scale by 2^k by squaring.
local float _exp -> float x {
    float ex_ln2 = 0.6931471805599453;
    float ex_half = 0.34657359027997264;
    int ex_k = 0;
    float ex_r = x;
    while ex_r > ex_half {
        ex_r = ex_r - ex_ln2;
        ex_k = ex_k + 1;
    }
    while ex_r < -ex_half {
        ex_r = ex_r + ex_ln2;
        ex_k = ex_k - 1;
    }
    float ex_term = 1.0;
    float ex_sum = 1.0;
    int ex_n = 1;
    while ex_n <= 20 {
        ex_term = ex_term * ex_r / (float)ex_n;
        ex_sum = ex_sum + ex_term;
        ex_n = ex_n + 1;
    }
    float ex_scale = 1.0;
    float ex_base = 2.0;
    int ex_e = ex_k;
    if ex_e < 0 {
        ex_e = -ex_e;
        ex_base = 0.5;
    }
    while ex_e > 0 {
        if (ex_e & 1) == 1 {
            ex_scale = ex_scale * ex_base;
        }
        ex_base = ex_base * ex_base;
        ex_e = ex_e >> 1;
    }
    return ex_sum * ex_scale;
}

!!! The power of ten that a number of decimal places stands for.
local float _pow10 -> int digits {
    float p10_s = 1.0;
    int p10_i = 0;
    if digits >= 0 {
        while p10_i < digits {
            p10_s = p10_s * 10.0;
            p10_i = p10_i + 1;
        }
    } else {
        while p10_i < -digits {
            p10_s = p10_s / 10.0;
            p10_i = p10_i + 1;
        }
    }
    return p10_s;
}

!~ ---------- powers and roots ---------- ~!

float _pow -> float x, float y {
    if x == 0.0 {
        if y > 0.0 {
            return 0.0;
        }
        return _nan();
    }
    if x < 0.0 {
        return _nan();
    }
    if _whole(y) == 1 {
        int pw_e = (int)y;
        if pw_e >= -4096 {
            if pw_e <= 4096 {
                float pw_base = x;
                float pw_acc = 1.0;
                int pw_n = pw_e;
                if pw_n < 0 {
                    pw_n = -pw_n;
                }
                while pw_n > 0 {
                    if (pw_n & 1) == 1 {
                        pw_acc = pw_acc * pw_base;
                    }
                    pw_base = pw_base * pw_base;
                    pw_n = pw_n >> 1;
                }
                if pw_e < 0 {
                    return 1.0 / pw_acc;
                }
                return pw_acc;
            }
        }
    }
    return _exp(y * _ln(x));
}

float _sqrt -> float x {
    if x < 0.0 {
        return _nan();
    }
    if x == 0.0 {
        return 0.0;
    }
    float sq_g = x;
    if sq_g < 1.0 {
        sq_g = 1.0;
    }
    int sq_i = 0;
    while sq_i < 60 {
        sq_g = (sq_g + x / sq_g) / 2.0;
        sq_i = sq_i + 1;
    }
    return sq_g;
}

float _cbrt -> float x {
    if x < 0.0 {
        return _nan();
    }
    if x == 0.0 {
        return 0.0;
    }
    !!! x^(1/3) from the series, then one Newton step to square the error away
    float cb_g = _exp(_ln(x) / 3.0);
    float cb_g2 = cb_g * cb_g;
    cb_g = cb_g - (cb_g2 * cb_g - x) / (3.0 * cb_g2);
    return cb_g;
}

float _amrt -> float x, float y {
    if y == 0.0 {
        return _nan();
    }
    return _pow(x, 1.0 / y);
}

!~ ---------- rounding ---------- ~!

int _ceil -> float x {
    int ce_t = (int)x;
    float ce_f = (float)((ce_t));
    if ce_f < x {
        ce_t = ce_t + 1;
    }
    return ce_t;
}

int _floor -> float x {
    int fl_t = (int)x;
    float fl_f = (float)((fl_t));
    if fl_f > x {
        fl_t = fl_t - 1;
    }
    return fl_t;
}

int _round -> float x {
    if x >= 0.0 {
        return (int)(x + 0.5);
    }
    return (int)(x - 0.5);
}

int _num -> float x {
    return (int)x;
}

float _abs -> float x {
    if x < 0.0 {
        return -x;
    }
    return x;
}

float _mod -> float x, float y {
    if y == 0.0 {
        return _nan();
    }
    float md_q = x / y;
    return x - (float)((int)md_q) * y;
}

float _prec -> float x, int digits {
    float pr_s = _pow10(digits);
    float pr_t = x * pr_s;
    int pr_r = (int)(pr_t + 0.5);
    if pr_t < 0.0 {
        pr_r = (int)(pr_t - 0.5);
    }
    return (float)((pr_r)) / pr_s;
}
