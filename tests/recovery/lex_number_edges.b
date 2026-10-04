!!! Numbers at the edge of what a literal holds: too many hex digits, and the
!!! largest value that still fits in an unsigned 32-bit int.
int main {
    utype longlong big = 0x1FFFFFFFFFFFFFFFF;
    utype longlong fits = 0xFFFFFFFF;
    int small = 0x7FFFFFFF;
    return 0;
}
