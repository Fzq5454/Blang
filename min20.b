#head "stdsrt"

function int get20 -> int a, int b, int c, int d, int e, int f, int g, int h, int i, int j, int k, int l, int m, int n, int o, int p, int q, int r, int s, int t {
    new int x = t;
    return x;
}

function void main {
    new int res = get20(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20);
    system.out("res=", res, "\n");
}
