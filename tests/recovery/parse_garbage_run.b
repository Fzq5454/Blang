!!! Statements that cannot start one, one after another. After the first failure
!!! the toolchain parser resyncs twice - `error_at_cur` syncs, and the block loop syncs
!!! again because the token it stops on is no longer a boundary - so the statement
!!! right after the broken one is stepped over without a word and the one after
!!! that is reported. Reporting with one sync only (which is what this implementation did)
!!! named every one of them.
int main {
    + +;
    | |;
    * /;
    zzz();
    int a = 1;
    return 0;
}
