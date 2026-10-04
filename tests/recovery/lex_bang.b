!!! A single `!` is the not operator and not the start of a comment; `!!!` starts
!!! a comment and the rest of the line is not read.
int main {
    bool b = true;
    b = !b;
    b = b ! b;
    !!! this line is a comment
    return 0;
}
