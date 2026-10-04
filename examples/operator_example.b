!~
 ~  operator_example.b: the simplest operator overloading.
 ~
 ~  A struct declares `T operator + -> T other { ... }` and `a + b` then calls it.
 ~  The receiver (this) is the left value, so `x` is `a.x`; the parameter is the
 ~  right value, so `b.x` is the x of b.
 ~
 ~  Build: blang.exe operator_example.b -o operator_example.exe
 ~!

#head "stdsrt"

type Point {
    int x;
    int y;

    Point operator + -> Point b {
        Point r;
        r.x = x + b.x;
        r.y = y + b.y;
        return r;
    }
};

int main {
    Point a;
    a.x = 3;
    a.y = 4;

    Point b;
    b.x = 10;
    b.y = 20;

    Point c = a + b;

    system.out(c.x, " ", c.y, "\n");
    return 0;
}
