!~
 ~  static_example.b: `static` storage - one slot for the whole run.
 ~
 ~  A local `static T x = v;` is initialized the first time execution reaches the
 ~  declaration and keeps that value afterwards, so the initializer runs exactly
 ~  once (it may be any expression, a function call included).
 ~
 ~  `static T p` of a parameter keeps the argument of the first call. The parameter
 ~  is still passed on every call, but only the first value stays.
 ~
 ~  `static const T x = v;` is both: written by the first initialization and never
 ~  written again.
 ~
 ~  Build: blang.exe static_example.b -o static_example.exe
 ~!

#head "stdsrt"

int bump {
    static int n = 0;
    n = n + 1;
    return n;
}

int keep -> static int first, int v {
    return first;
}

type Counter {
    int total;
    int step -> static int by {
        by = by + 1;
        return by;
    }
};

int main {
    system.out("bump: ", bump(), " ", bump(), " ", bump(), "\n");
    system.out("keep: ", keep(7, 0), " ", keep(9, 0), "\n");
    Counter c;
    system.out("step: ", c.step(0), " ", c.step(0), " ", c.step(0), "\n");
    return 0;
}
