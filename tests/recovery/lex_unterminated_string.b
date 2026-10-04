!!! An unterminated string: the literal read so far is kept, so the tokens after
!!! it are still produced and the errors that follow are still found.
int main {
    str s = "abc;
    int a = 1;
    return 0;
}
