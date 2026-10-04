#head "stdsrt"

type Person {
    stub void birth;
};

void Person::birth{
    system.out("Person is born!\n");
}

int main {
    Person p;
    p.birth();
    return 0;
}