#head "stdsrt"

type Person {
    str name;

    init Person {
        name = "world";
    }

    destruct Person {
        system.out(name, " is gone\n");
    }

    void greet {
        system.out("hello, ", name, "\n");
    }
};

int main {
    Person p;
    p.greet();
    return 0;
}
