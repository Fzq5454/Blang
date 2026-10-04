#head "stdsrt"

type Neg {
    int x;

    Neg operator - {
        Neg r;
        r.x = 0 - x;
        return r;
    }
};

type Less {
    int x;

    int operator < -> Less b {
        if x < b.x { return 1; }
        return 0;
    }
};

type Idx {
    int v[4];

    int operator [] -> int i {
        return v[i];
    }
};

int main {
    Neg n1;
    Neg n2;
    n1 = n1 - n2;

    Less l1;
    int c = 5 < l1;

    Idx a;
    a[0] = 7;
    return c;
}
