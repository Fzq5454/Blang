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

    int operator == -> Point b {
        if x != b.x { return 0; }
        if y != b.y { return 0; }
        return 1;
    }
};

int main {
    Point a;
    Point b;
    Point c = a * b;
    return 0;
}
