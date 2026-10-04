!!! A local variable declared twice in one body, and a name used before its
!!! declaration.
int main {
    int a = 1;
    int a = 2;
    a = later;
    int later = 3;
    return 0;
}
