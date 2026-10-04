!!! Garbage inside a nested block: the recovery has to leave the block and read
!!! the statement after it.
int main {
    int a = 1;
    while true {
        + ;
        a = 2;
    }
    return 0;
}
