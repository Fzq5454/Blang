!!! Statements that cannot start a statement: the parser has to say so once for
!!! each and go on to the statements after them.
int main {
    + +;
    * /;
    int a = 1;
    return 0;
}
