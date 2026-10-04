!!! Stray bytes on a line of their own, before a name, a number and a call: what
!!! comes after each one is a normal token again.
int twice -> int x {
    return x + x;
}

int main {
    int a = 1;
    \ a = 2;
    ` a = a + twice(3);
    a = a \ 4;
    return 0;
}
