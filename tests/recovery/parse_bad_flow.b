!!! `end` in a function that answers a value, and `skip` outside a loop: two
!!! messages that must not stop the statements after them.
int f {
    end;
}

int main {
    skip;
    return f();
}
