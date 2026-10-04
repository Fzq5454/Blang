!~
 ~  msg.b: the information window of test.c, in blang.
 ~
 ~  The C version registers a window class of its own, paints centred text in it
 ~  with a bold face, closes when it is clicked or when Esc/Enter is pressed, and
 ~  ends with its message loop. This is the same program, with the same window
 ~  class name, title, size, font and colours.
 ~
 ~  Every handle a Windows call hands back or takes (HWND, HDC, HFONT, HBRUSH,
 ~  HCURSOR, HINSTANCE, HMENU) is a @void: a handle is an opaque word, and the
 ~  language has no type for it. The structs Windows fills are `type`s with the
 ~  same field order, and the text goes through the wide interface, because a .b
 ~  source is UTF-8 and the A interface would read it as the system code page.
 ~
 ~  Build: blang.exe msg.b -o msg.exe -system kernel32 -system user32 -system gdi32
 ~         -CMP,--type=win
 ~!

#head "stdsrt"

!!! A WNDCLASSEXW, in the field order and at the offsets Windows reads: cbSize is
!!! 80, the 4-byte fields sit at 0, 4, 16 and 20 and the 8-byte ones at 8, 24, 32,
!!! 40, 48, 56, 64 and 72.
type WndClassEx {
    int cbSize;
    int style;
    @void wndProc;
    int clsExtra;
    int wndExtra;
    @void inst;
    @void icon;
    @void cursor;
    @void brush;
    @void menu;
    @void clsName;
    @void iconSm;
};

!!! A RECT: left, top, right, bottom.
type Rect {
    int left;
    int top;
    int right;
    int bottom;
};

!!! A PAINTSTRUCT, big enough for the 72 bytes BeginPaint fills in. Only its
!!! address is ever used.
type Paint {
    @void hdc;
    int erase;
    int l;
    int t;
    int r;
    int b;
    int restore;
    int inc;
    int pad0;
    int pad1;
    int pad2;
    int pad3;
    int pad4;
    int pad5;
    int pad6;
    int pad7;
    int pad8;
};

!!! A MSG, 64 bytes, which is more than the 48 the struct uses.
type Msg {
    longlong m0;
    longlong m1;
    longlong m2;
    longlong m3;
    longlong m4;
    longlong m5;
    longlong m6;
    longlong m7;
};

!!! Room for a wide copy of a short string: 64 bytes is 32 UTF-16 characters.
type Wide {
    longlong w0;
    longlong w1;
    longlong w2;
    longlong w3;
    longlong w4;
    longlong w5;
    longlong w6;
    longlong w7;
};

!!! The window procedure. What it draws comes from its own locals, and it reads no
!!! global: a callback user32 calls has user32's own r15, so the first global the
!!! callback touches would fault. That is why the C version's `L"..."` literals are
!!! built here, into stack buffers, on every paint.
longlong msg_wnd_proc -> @void hwnd, int msg, longlong wparam, longlong lparam {
    if msg == 15 {
        Paint ps;
        Rect rc;
        Wide face;
        Wide text;
        @void hdc = BeginPaint(hwnd, (@void)@ps);
        SetBkMode(hdc, 1);
        SetTextColor(hdc, 0x141414);
        MultiByteToWideChar(65001, 0, "微软雅黑", -1, (@void)@face, 32);
        MultiByteToWideChar(65001, 0, "这是一个信息窗口", -1, (@void)@text, 32);
        @void hfont = CreateFontW(-22, 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 5, 0, (@void)@face);
        @void holdfont = SelectObject(hdc, hfont);
        GetClientRect(hwnd, (@void)@rc);
        DrawTextW(hdc, (@void)@text, -1, (@void)@rc, 0x25);
        SelectObject(hdc, holdfont);
        DeleteObject(hfont);
        EndPaint(hwnd, (@void)@ps);
        return 0;
    }
    if msg == 0x201 {
        DestroyWindow(hwnd);
        return 0;
    }
    if msg == 0x100 {
        if wparam == 0x1B || wparam == 0x0D {
            DestroyWindow(hwnd);
        }
        return 0;
    }
    if msg == 2 {
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wparam, lparam);
}

int WinMain {
    SetProcessDPIAware();
    Wide cls;
    Wide title;
    Wide text;
    Wide caption;
    Msg msg;
    MultiByteToWideChar(65001, 0, "InfoWindowClass", -1, (@void)@cls, 32);
    MultiByteToWideChar(65001, 0, "信息", -1, (@void)@title, 32);

    WndClassEx wc;
    wc.cbSize = 80;
    wc.style = 0;
    wc.wndProc = (@void)((@func)msg_wnd_proc);
    wc.clsExtra = 0;
    wc.wndExtra = 0;
    wc.inst = GetModuleHandleA(null);
    wc.icon = null;
    wc.cursor = LoadCursorW(null, (@void)32512);
    wc.brush = GetSysColorBrush(5);
    wc.menu = null;
    wc.clsName = (@void)@cls;
    wc.iconSm = null;

    if RegisterClassExW((@void)@wc) == 0 {
        MultiByteToWideChar(65001, 0, "注册窗口类失败", -1, (@void)@text, 32);
        MultiByteToWideChar(65001, 0, "错误", -1, (@void)@caption, 32);
        MessageBoxW(null, (@void)@text, (@void)@caption, 0x10);
        return 1;
    }

    @void hwnd = CreateWindowExW(1, (@void)@cls, (@void)@title, 0x00C80000,
                                 0x80000000, 0x80000000, 420, 220,
                                 null, null, GetModuleHandleA(null), null);
    if hwnd == null {
        MultiByteToWideChar(65001, 0, "创建窗口失败", -1, (@void)@text, 32);
        MultiByteToWideChar(65001, 0, "错误", -1, (@void)@caption, 32);
        MessageBoxW(null, (@void)@text, (@void)@caption, 0x10);
        return 1;
    }

    ShowWindow(hwnd, 5);
    UpdateWindow(hwnd);

    while GetMessageW((@void)@msg, null, 0, 0) > 0 {
        TranslateMessage((@void)@msg);
        DispatchMessageW((@void)@msg);
    }
    return 0;
}
