!!! A call that is missing its `)`: the scan has to hand the parser the tokens
!!! after the mistake, so the call is reported as well as the `)`.
int main {
    f(1, 2;
    return 0;
}
