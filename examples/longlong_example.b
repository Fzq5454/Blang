!~
 ~  longlong_example.b: the 64-bit integer type, end to end.
 ~
 ~  `longlong` is a built-in type: 8 bytes, the whole value in one register, and
 ~  no header to include. `int` stays 4 bytes, so a value wider than 2^31 needs
 ~  this one. A constant that does not fit in an int is a longlong by itself, so
 ~  `longlong y = 6000000000;` needs no cast.
 ~
 ~  Build: blang.exe longlong_example.b -o longlong_example.exe
 ~!

#head "stdsrt"
#head "format"

!!! Return types, parameters and struct fields all take the type.
longlong addl -> longlong a, longlong b {
    return a + b;
}

type Counter {
    longlong hits;
    int tag;
};

int main {
    longlong x = 5;
    longlong y = 6000000000;                 !!! wider than an int
    longlong z = x + y;
    system.out("x=", x, " y=", y, " z=", z, "\n");

    !!! The arithmetic is 64-bit, so nothing wraps and `(str)` prints it whole.
    system.out("m=", y * 2, " neg=", -z, " div=", (str)(z / y), " mod=", (str)(z % y), "\n");
    system.out("bits=", (str)(y << 2), " ", (str)(y >> 3), " ", (str)~y, "\n");
    system.out("cmp=", z > y, " ", z == y, " ", z < y, "\n");

    !!! A pointer to one writes all 8 bytes; `@x` names the address.
    @longlong p = @x;
    $p = 42;
    system.out("through p: x=", x, "\n");

    !!! The conversions: int truncates to the low 32 bits, float is a double.
    system.out("cast=", (str)(longlong)3.9, " ", (str)(float)y, " ", (int)y, "\n");

    Counter c;
    c.hits = 1234567890123;
    c.tag = 9;
    system.out("field=", c.hits, " tag=", c.tag, "\n");

    !!! printf prints the 64-bit value with %l (`%ld` and `%lld` work as well).
    printf("printf: %l %ld %lld %d\n", y, z, c.hits, 7);
    return 0;
}
