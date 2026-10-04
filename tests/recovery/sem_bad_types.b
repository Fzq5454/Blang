!!! Values of the wrong type in three places: every one of them has to be named.
int takes_int -> int a {
    return a;
}

int main {
    str s = 1;
    int a = takes_int("x");
    float f = s;
    return 0;
}
