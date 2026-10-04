!!! Garbage between two calls: the calls on either side are read the way they are
!!! read anywhere else, and the error of the statement after the broken one is the
!!! one the double resync steps over.
int main {
    zzz();
    + +;
    yyy();
    return 0;
}
