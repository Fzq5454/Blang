!!! An operator declaration whose symbol is not one an operator can be written
!!! with.
type Box {
    int operator 123 -> int v {
        return v;
    }
}

int main {
    return 0;
}
