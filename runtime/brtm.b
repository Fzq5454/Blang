!~
 ~  runtime/brtm.b: the blang runtime, written in blang.
 ~
 ~  This is the library the code the compiler generates calls into: joining and
 ~  releasing strings, indexing one, the heap the arrays are built on, the
 ~  printing behind `system.out`, and the console encoding behind
 ~  `system.setEncoding`. It used to be machine code that blibobj
 ~  emitted into lib/brtm.lib; here it is ordinary blang, compiled into
 ~  bin/libbrtm.dll and linked dynamically with `-dbrtm`.
 ~
 ~  Build: blang.exe runtime/brtm.b '-CMP,--no-runtime' -system kernel32 -o bin/libbrtm.dll
 ~  `-CMP,--no-runtime` matters: without it this DLL would import the very runtime
 ~  it is defining. A program imports libbrtm.dll by default, and -static-runtime
 ~  places this DLL's code into the program instead: that reads the side file
 ~  meta/libbrtm.dll.bst, which this build writes beside the .bmeta.
 ~
 ~  What it may not use is exactly what it provides: `system.out`, `+` on two
 ~  strings, `s[i]`. `(str)int` and `(str)float` are fine, because the compiler
 ~  writes those conversions into every image itself.
 ~
 ~  The calling conventions are the Windows ones: the compiler reaches a symbol
 ~  the generated code calls either directly or through a small thunk, and both
 ~  end up as rcx/rdx/r8/r9 (and the stack) like any other DLL function.
 ~!

#to type=dll

int DllMain {
    return 1;
}

!~ ---------- memory ---------- ~!

!!! The arrays keep their metadata just below the data pointer: the capacity at
!!! [ptr-16] and the element size at [ptr-12], both 32-bit. `addr` is the data
!!! pointer, so -4 and -3 ints back from it are those two fields.
int _memory -> @void addr {
    @int base = (@int)addr;
    @int cap = base - 4;
    @int esz = base - 3;
    return $cap * $esz;
}

!!! ---- the heap the compiler allocates from ----
!!!
!!! VirtualAlloc per allocation is a kernel call and a whole page for a record of
!!! thirty-two bytes. A self-hosted compile makes millions of those and frees
!!! almost none of them, so the allocator was most of the run. A block is asked
!!! for rarely here - a megabyte at a time - and a slice comes out of it with a
!!! pointer bump. Nothing is given back inside a block: this implementation frees almost
!!! nothing, and a block goes back to the system when the process ends.
!!!
!!! A request larger than a block gets a block of its own, so a machine-sized
!!! buffer (the .r text of a large file runs to megabytes) still works.

!!! The block in use and how much of it is left.
@char _pool_cur;
int _pool_left;

!!! How big the blocks are. A megabyte holds about thirty thousand records of the
!!! size the front end asks for, so the kernel is called once per thirty thousand
!!! allocations instead of once per allocation.
int _POOL_BLOCK = 1048576;

!!! A slice of the current block, or of a fresh one. Slices start on a 16-byte
!!! boundary: the records hold pointers and ints, and an aligned start keeps every
!!! one of them aligned.
local @void _pool_take -> int bytes {
    !!! Rounded up to a 16-byte boundary, and the rounding is a pair of shifts: the
    !!! `/ 16` this used to be is an idiv, which every array allocation paid for.
    int want = ((bytes + 15) >> 4) << 4;
    if want <= 0 {
        want = 16;
    }
    if _pool_left < want {
        int block = _POOL_BLOCK;
        if block < want {
            block = want;
        }
        @void fresh = VirtualAlloc(null, (longlong)block, 12288, 4);
        if fresh == null {
            return null;
        }
        _pool_cur = (@char)fresh;
        _pool_left = block;
    }
    @char p = _pool_cur;
    _pool_cur = _pool_cur + want;
    _pool_left = _pool_left - want;
    return (@void)p;
}

!!! `addr` is a cell that receives the address, `bytes` how many to reserve.
bool _malloc -> @void addr, int bytes {
    @void p = _pool_take(bytes);
    $addr = p;
    return p != null;
}

!!! The block the generated code needs for an object of its own: the copy of a
!!! struct returned by value, a capture cell, a closure object, a variadic
!!! argument pack. The compiler used to write a `VirtualAlloc` for each of those,
!!! and VirtualAlloc answers whole pages: an eight-byte capture cell cost four
!!! kilobytes, and a self-hosted compile makes millions of them - the pages, and
!!! faulting them in, were half the run. The pool hands out slices of a megabyte
!!! block instead, so one of these costs the bytes it asks for.
!!!
!!! The size arrives in rcx and the block leaves in rax: the call site is an
!!! expression the compiler writes itself and the values are already in the
!!! registers the Windows x64 convention wants, which is the same shape the
!!! VirtualAlloc call had (the size went in rdx there, because the first three
!!! arguments are the address, the flags and the protection).
!!!
!!! The block is cleared before it is handed out. VirtualAlloc answered zeroed
!!! pages and the call sites are written for that: an array declaration whose
!!! initializer names fewer elements than the array holds leaves the rest at zero,
!!! and a struct return copies only the fields the struct has. A slice of a pool
!!! block holds whatever the object before it left there, so the same promise has
!!! to be kept here.
@void _alloc_small -> int bytes {
    !!! The bump is done here instead of through _malloc and _pool_take: those are
    !!! two calls with their arguments pushed on the stack, and they stood between
    !!! every capture cell, closure object and struct copy a program makes and the
    !!! pool. The rounding is a pair of shifts rather than the idiv `/ 16` was.
    int want = ((bytes + 15) >> 4) << 4;
    if want <= 0 {
        want = 16;
    }
    @char cur = _pool_cur;
    int left = _pool_left;
    if left < want {
        int block = _POOL_BLOCK;
        if block < want {
            block = want;
        }
        @void fresh = VirtualAlloc(null, (longlong)block, 12288, 4);
        if fresh == null {
            return null;
        }
        cur = (@char)fresh;
        left = block;
    }
    _pool_cur = cur + want;
    _pool_left = left - want;
    @char p = cur;
    int i = 0;
    while i + 8 <= bytes {
        @longlong w = (@longlong)(p + i);
        $w = 0;
        i = i + 8;
    }
    while i < bytes {
        p[i] = (char)0;
        i = i + 1;
    }
    return (@void)cur;
}

!!! A slice of a block is not given back on its own - the block is released when
!!! the process ends - so this does nothing. It is kept because every caller that
!!! frees a buffer reads the same, and because the A pair below is the one that
!!! hands memory to the system allocator and takes it back.
void _unlink -> @void addr {
}

!!! The A pair is the same idea on the process heap, which the system allocator
!!! can hand back out. A block from one pair has to go back through the other.
bool _mallocA -> @void addr, int bytes {
    @void h = GetProcessHeap();
    @void p = HeapAlloc(h, 0, (longlong)bytes);
    $addr = p;
    return p != null;
}

void _unlinkA -> @void addr {
    @void h = GetProcessHeap();
    @void p = (@void)$addr;
    HeapFree(h, 0, p);
}

!~ ---------- strings ---------- ~!

!!! Copy `n` bytes from `src` to `dst`. Internal: `local` keeps it out of the
!!! export table, which holds only what the compiler calls.
!!!
!!! Eight bytes at a time, with the tail a byte at a time. The byte loop this used
!!! to be is the copy under every string join and every _str_concat, and a
!!! self-hosted compile copies megabytes through it.
local void _copy -> @char dst, @char src, int n {
    @char d = dst;
    @char s = src;
    int left = n;
    while left >= 8 {
        @longlong w = (@longlong)s;
        @longlong t = (@longlong)d;
        $t = $w;
        d = d + 8;
        s = s + 8;
        left = left - 8;
    }
    while left > 0 {
        $d = $s;
        d = d + 1;
        s = s + 1;
        left = left - 1;
    }
}


!!! A new string with `a` and `b` joined. The heap block is what the caller owns
!!! from then on, and _str_free gives it back.
str _str_concat -> str a, str b {
    int la = lstrlenA(a);
    int lb = lstrlenA(b);
    @void cell;
    _malloc(@cell, la + lb + 1);
    @char p = (@char)cell;
    _copy(p, (@char)a, la);
    _copy(p + la, (@char)b, lb);
    @char last = p + la + lb;
    $last = (char)0;
    return (str)cell;
}

void _str_free -> str p {
    !!! A string is a slice of a block like every other allocation, so there is
    !!! nothing to give back here; see the heap above.
}

!!! One character of a string.
char _str_idx -> str s, int i {
    @char p = (@char)s;
    p = p + i;
    return $p;
}

!~ ---------- printing ---------- ~!

local void _write_text -> @void h, str s {
    @int written;
    WriteFile(h, s, lstrlenA(s), @written, null);
}

!!! The tag says what the value is: 0 int, 1 str, 2 float, 3 bool, 4 char, 15
!!! longlong. It is the type tag the compiler attaches to an `any` argument, so
!!! the value itself is one raw 8-byte slot that only the tag says how to read.
local void _out_value -> @void h, any v, int tag {
    str s = (str)v;
    if tag == 2 {
        @float fp = (@float)(@v);
        float f = $fp;
        s = (str)f;
    } else if tag == 3 {
        bool b = (bool)v;
        s = (str)b;
    } else if tag == 4 {
        char c = (char)v;
        s = (str)c;
    } else if tag == 15 {
        longlong n = (longlong)v;
        s = (str)n;
    } else if tag == 0 {
        int i = (int)v;
        s = (str)i;
    }
    _write_text(h, s);
}

void _system_out -> any v, int tag {
    @void out = GetStdHandle(-11);
    _out_value(out, v, tag);
}

!!! The process's standard output: what a tool prints goes to the output of the
!!! process itself, so a redirection or a pipe of the program carries it. It is
!!! its own export - and writes through the handle itself rather than calling
!!! _system_out - because the two are different promises: `system.out` is the
!!! output of the program, which the runtime is free to route elsewhere (a window
!!! runtime could capture it), while this one stays the standard output whatever
!!! happens to that. The value is formatted by the same helper, so a value printed
!!! either way reads the same.
void _system_std_out -> any v, int tag {
    @void out = GetStdHandle(-11);
    _out_value(out, v, tag);
}

void _system_err -> any v, int tag {
    @void err = GetStdHandle(-12);
    _out_value(err, v, tag);
}

!!! Print the prompt, then read one line and return it without the ending.
str _system_in -> str prt {
    @void out = GetStdHandle(-11);
    _write_text(out, prt);
    @void in = GetStdHandle(-10);
    @void cell;
    _malloc(@cell, 512);
    @char p = (@char)cell;
    @int got;
    ReadFile(in, (str)cell, 511, @got, null);
    int n = (int)got;
    @char q = p;
    int i = 0;
    while i < n {
        int ch = (int)$q;
        if ch == 10 {
            $q = (char)0;
            return (str)cell;
        }
        if ch == 13 {
            $q = (char)0;
            return (str)cell;
        }
        i = i + 1;
        q = q + 1;
    }
    $q = (char)0;
    return (str)cell;
}

!~ ---------- console encoding ---------- ~!

!!! The code page that belongs to one `Encoding` index, in the order the kind in
!!! stdsrt lists them. The native runtime carried the same 94 entries as a table
!!! beside its code (blibobj, build_system_set_encoding), and this switch is
!!! that table written out. 0 means the index names no encoding, which sets
!!! nothing.
local int _encoding_page -> int index {
	switch (index) {

		!!! ---- CP1250 to CP1258 ----
		case 0: return 1250;
		case 1: return 1251;
		case 2: return 1252;
		case 3: return 1253;
		case 4: return 1254;
		case 5: return 1255;
		case 6: return 1256;
		case 7: return 1257;
		case 8: return 1258;

		!!! ---- CP936 to CP850 ----
		case 9: return 936;
		case 10: return 949;
		case 11: return 950;
		case 12: return 932;
		case 13: return 874;
		case 14: return 20866;
		case 15: return 21866;
		case 16: return 437;
		case 17: return 737;
		case 18: return 775;
		case 19: return 850;

		!!! ---- CP852 to CP869 ----
		case 20: return 852;
		case 21: return 855;
		case 22: return 857;
		case 23: return 858;
		case 24: return 860;
		case 25: return 861;
		case 26: return 862;
		case 27: return 863;
		case 28: return 864;
		case 29: return 865;
		case 30: return 866;
		case 31: return 869;

		!!! ---- UTF-8, UTF-16, UTF-32, UCS-2 ----
		case 32: return 65001;
		case 33: return 1200;
		case 34: return 1200;
		case 35: return 1201;
		case 36: return 12000;
		case 37: return 12000;
		case 38: return 12001;
		case 39: return 1200;

		!!! ---- ISO-8859-1 to ISO-8859-9 ----
		case 40: return 28591;
		case 41: return 28592;
		case 42: return 28593;
		case 43: return 28594;
		case 44: return 28595;
		case 45: return 28596;
		case 46: return 28597;
		case 47: return 28598;
		case 48: return 28599;

		!!! ---- ISO-8859-10 to ISO-8859-16 (there is no 12) ----
		case 49: return 28600;
		case 50: return 28601;
		case 51: return 28603;
		case 52: return 28604;
		case 53: return 28605;
		case 54: return 28606;

		!!! ---- CP10000 to CP10082 ----
		case 55: return 10000;
		case 56: return 10004;
		case 57: return 10006;
		case 58: return 10007;
		case 59: return 10010;
		case 60: return 10017;
		case 61: return 10029;
		case 62: return 10079;
		case 63: return 10081;
		case 64: return 10082;

		!!! ---- CP037 to CP880 ----
		case 65: return 37;
		case 66: return 273;
		case 67: return 277;
		case 68: return 278;
		case 69: return 280;
		case 70: return 284;
		case 71: return 285;
		case 72: return 297;
		case 73: return 420;
		case 74: return 423;
		case 75: return 424;
		case 76: return 500;
		case 77: return 871;
		case 78: return 875;
		case 79: return 880;

		!!! ---- CP905 to CP1047 ----
		case 80: return 905;
		case 81: return 924;
		case 82: return 1026;
		case 83: return 1047;

		!!! ---- CP1140 to CP1149 ----
		case 84: return 1140;
		case 85: return 1141;
		case 86: return 1142;
		case 87: return 1143;
		case 88: return 1144;
		case 89: return 1145;
		case 90: return 1146;
		case 91: return 1147;
		case 92: return 1148;
		case 93: return 1149;

		unmatch: return 0;
	}
	return 0;
}

!!! system.setEncoding: a console reads and writes in one code page, so both
!!! halves are given the same one. An index past the end of the list leaves the
!!! console as it was, which is what the native runtime did.
void _system_set_encoding -> int index {
	int page = _encoding_page(index);
	if page != 0 {
		SetConsoleCP(page);
		SetConsoleOutputCP(page);
	}
}

!~ ---------- unsigned values ---------- ~!

!!! The operations of a `utype T` value whose machine instruction is the signed
!!! one, so the compiler hands them to these instead: `/`, `%`, `>>` and the four
!!! order comparisons. A 32-bit unsigned value is widened first - a negative int is
!!! 2^32 more than it looks - and then the signed instruction does the unsigned
!!! thing. A 64-bit one cannot be widened, so the comparisons look at the sign bits
!!! and the division walks the bits one at a time.

!!! The 32-bit value as a 64-bit number: what the sign bit was hiding is added back.
longlong _uwiden -> int v {
	longlong x = (longlong)v;
	if x < 0 {
		x = x + 4294967296;
	}
	return x;
}

bool _ult -> int a, int b {
	return _uwiden(a) < _uwiden(b);
}

bool _ule -> int a, int b {
	return _uwiden(a) <= _uwiden(b);
}

bool _ugt -> int a, int b {
	return _uwiden(a) > _uwiden(b);
}

bool _uge -> int a, int b {
	return _uwiden(a) >= _uwiden(b);
}

int _udiv -> int a, int b {
	if b == 0 {
		return 0;
	}
	return (int)(_uwiden(a) / _uwiden(b));
}

int _umod -> int a, int b {
	if b == 0 {
		return 0;
	}
	return (int)(_uwiden(a) % _uwiden(b));
}

int _ushr -> int a, int n {
	longlong x = _uwiden(a);
	int i = 0;
	while i < n {
		x = x / 2;
		i = i + 1;
	}
	return (int)x;
}

!!! Two unsigned 64-bit values compare as their sign bits say: the negative one is
!!! the larger, and two of the same sign compare the signed way.
bool _ultl -> longlong a, longlong b {
	if a < 0 {
		if b < 0 {
			return a < b;
		}
		return false;
	}
	if b < 0 {
		return true;
	}
	return a < b;
}

bool _ulel -> longlong a, longlong b {
	if a < 0 {
		if b < 0 {
			return a <= b;
		}
		return false;
	}
	if b < 0 {
		return true;
	}
	return a <= b;
}

bool _ugtl -> longlong a, longlong b {
	return _ultl(b, a);
}

bool _ugel -> longlong a, longlong b {
	return _ulel(b, a);
}

!!! The quotient of two unsigned 64-bit values: the hardware instruction divides
!!! signed, so the bits are walked from the top instead.
longlong _udivl -> longlong a, longlong b {
	if b == 0 {
		return 0;
	}
	longlong one = 1;
	longlong q = 0;
	longlong r = 0;
	int i = 63;
	while i >= 0 {
		r = (r << 1) | ((a >> i) & 1);
		if _ugel(r, b) {
			r = r - b;
			q = q | (one << i);
		}
		i = i - 1;
	}
	return q;
}

!!! The remainder of two unsigned 64-bit values, from the quotient.
longlong _umodl -> longlong a, longlong b {
	if b == 0 {
		return 0;
	}
	return a - _udivl(a, b) * b;
}

!!! A logical right shift: the bits shifted in are zeros, not a copy of the sign.
longlong _ushrl -> longlong a, longlong n {
	if n <= 0 {
		return a;
	}
	if n >= 64 {
		return 0;
	}
	longlong one = 1;
	longlong m = (one << (64 - n)) - 1;
	return (a >> n) & m;
}

!!! The decimal text of an unsigned value. A 32-bit one is its widened form; a
!!! 64-bit one is written a digit at a time, because `(str)` of a negative longlong
!!! spells the signed number.
str _ustr -> int v {
	return (str)_uwiden(v);
}

str _ustrl -> longlong v {
	if v >= 0 {
		return (str)v;
	}
	!!! The digits come out from the least significant one, so each is put in front
	!!! of what is already there. _str_concat is the join the `+` operator reaches,
	!!! called directly so the digit conversion buffer cannot be joined instead.
	str out = "";
	int digits = 0;
	while v != 0 {
		str d = (str)(int)_umodl(v, 10);
		out = _str_concat(d, out);
		v = _udivl(v, 10);
		digits = digits + 1;
	}
	if digits == 0 {
		return "0";
	}
	return out;
}
