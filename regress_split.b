#head "stdsrt"

type Person {
    str name;
    int age;
    init NewPerson {
        name = "none";
        age = 0;
    }
    int grow -> int by {
        age = age + by;
        return age;
    }
};

introduce TYPENAME T {
    T id -> T x {
        return x;
    }
}

int add -> int a, int b {
    return a + b;
}

int main {
    bool ddd;
    Person p;
    int r = p.grow(7);
    int s = id(9);
    system.out(r, " ", s, " ", add(1, add(2, 3)), "\n");
    return 0;
}
