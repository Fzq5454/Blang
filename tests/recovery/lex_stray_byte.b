!!! A stray byte in an expression: the scan has to name it once and read the
!!! statement after it, not one message per character that follows.
int main {
    int a = 1;
    a = a \ 2;
    int b = a + 3;
    return 0;
}
