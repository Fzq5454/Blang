!!! A function defined twice, and a value returned from the wrong kind of
!!! function.
int f -> int a {
    return a;
}

int f -> int a {
    return a;
}

@void g {
    return 1;
}

int main {
    return f(1);
}
