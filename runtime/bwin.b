!~
 ~  runtime/bwin.b: the window runtime, written in blang.
 ~
 ~  This was lib/bwin.lib, machine code that blibobj3 emitted. `includes/bl/window`
 ~  reaches it through `__bcall`.
 ~
 ~  Build: blang.exe runtime/bwin.b '-CMP,--no-runtime' -system kernel32 -system user32
 ~         -system gdi32 -o bin/libbwin.dll
 ~
 ~  Contract, from the native version:
 ~    _createWin(@void win, int w, int h) -> bool
 ~    _showWin / _hideWin / _minWin / _maxWin / _closeWin(@void win)
 ~    _setWinTitle(@void win, str title)
 ~    _setWinTitleA(@void win, str title, int encoding)
 ~    _setWinSize(@void win, int w, int h) / _setWinPos(@void win, int x, int y)
 ~    _getWinW / _getWinH(@void win) -> int
 ~    _isWinOpen(@void win) -> bool
 ~    _nextMsgWin(@void win) / _drawAgainWin(@void win)
 ~    _isWinNeedDraw(@void win) -> bool
 ~    _getScreenW / _getScreenH -> int
 ~    _showMsgBox(@void win, str title, str content) -> bool
 ~    _showMsgBoxA(@void win, str title, str content, int encoding) -> bool
 ~    _regMsgBoxBtu(@void btu, str text, func fn)
 ~    _setFontWin(@void win, str font, int size, int quality)
 ~    _setFontBtu(@void btu, str font, int size, int quality)
 ~
 ~  The native window procedure handled no messages at all: it was a stub that
 ~  called DefWindowProcA. A class here is registered with the address of that
 ~  same function, asked of user32 itself, so no callback of ours has to exist
 ~  for a plain window to behave exactly as it did.
 ~
 ~  The message box is the one place with a window procedure of its own: it
 ~  answers WM_COMMAND by calling the registered button callback and WM_PAINT by
 ~  drawing the box text, the way the native one did.
 ~
 ~  The button registry is process wide and never reset, as the native table was:
 ~  eight entries, filled by _regMsgBoxBtu and read by _showMsgBox. The `btu...`
 ~  list of _showMsgBox is inert there as well, so only the registry decides
 ~  which buttons a box gets.
 ~
 ~  A pointer that has to live across calls (the scratch buffers, the content
 ~  pointer, the font) is held in a global of type str, because a str is a plain
 ~  pointer and a global keeps its value for the life of the process.
 ~!

#to type=dll

!~ ---------- the system calls this runtime makes ---------- ~!
!!! They are declared by the metas of the three DLLs this runtime links against
!!! (kernel32, user32, gdi32), which the build script names with -system: the
!!! signature a call is checked with is the one the DLL really exports, so the
!!! 64-bit parameters (WPARAM, LPARAM, LONG_PTR, SIZE_T) carry a pointer or a
!!! handle whole instead of being cut to the 32 bits an `int` holds.

int DllMain {
    !!! A str global is not null to begin with: the language gives it the empty
    !!! string, so a lazy "allocate it the first time it is null" guard would never
    !!! fire and the pointer would stay on the string literal, which is read only.
    g_content = (str)null;
    g_font = (str)null;
    g_btu_font = (str)null;
    g_btu_fonts = (str)null;
    g_btu_hwnds = (str)null;
    g_msgfont = (str)null;
    g_msg = (str)null;
    g_rect = (str)null;
    g_wide = (str)null;
    return 1;
}

!!! The window class structure, in the field order and at the offsets Windows
!!! reads: cbSize is 80, the 4-byte fields sit at 0, 4, 16 and 20, and the
!!! 8-byte ones at 8, 24, 32, 40, 48, 56, 64 and 72. The two text fields are
!!! plain pointers rather than `str`, so the struct holds no string the language
!!! would want to release when the helper returns.
type WndClass {
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

!!! A RECT, left top right bottom.
type Rect {
    int left;
    int top;
    int right;
    int bottom;
};

!!! A PAINTSTRUCT, big enough for the 72 bytes BeginPaint fills in. Only its
!!! address is ever used, but a window procedure cannot keep it in a global:
!!! see the note on _msgbox_wndproc.
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

!~ ---------- state ---------- ~!

int btn_count = 0;
str btn_t0;
str btn_t1;
str btn_t2;
str btn_t3;
str btn_t4;
str btn_t5;
str btn_t6;
str btn_t7;
func btn_f0;
func btn_f1;
func btn_f2;
func btn_f3;
func btn_f4;
func btn_f5;
func btn_f6;
func btn_f7;
str g_content;
str g_font;
str g_btu_font;
str g_btu_fonts;
str g_btu_hwnds;
str g_msgfont;
str g_msg;
str g_rect;
str g_ps;
str g_wide;

!~ ---------- helpers ---------- ~!

!!! Register a window class. The procedure is a plain code address, and the
!!! brush is the number Windows uses for a built-in one.
local void _reg_class -> str name, @void brush, @void proc {
    WndClass wc;
    wc.cbSize = 80;
    wc.style = 3;
    wc.wndProc = proc;
    wc.clsExtra = 0;
    wc.wndExtra = 80;
    wc.inst = GetModuleHandleA(null);
    wc.icon = null;
    wc.cursor = LoadCursorA(null, (@str)32512);
    wc.brush = brush;
    wc.menu = (@void)"";
    wc.clsName = (@void)name;
    wc.iconSm = null;
    RegisterClassExA((@void)@wc);
}

!!! The text of a registered button.
local str _btn_text -> int i {
    if i == 0 { return btn_t0; }
    if i == 1 { return btn_t1; }
    if i == 2 { return btn_t2; }
    if i == 3 { return btn_t3; }
    if i == 4 { return btn_t4; }
    if i == 5 { return btn_t5; }
    if i == 6 { return btn_t6; }
    if i == 7 { return btn_t7; }
    return "";
}

!!! The buffers the message calls need, allocated once: a MSG, a RECT and a wide
!!! buffer. The native code had them on the stack; a global keeps them off the
!!! stack and out of the way of the painted window.
local void _scratch {
    if g_msg == null {
        g_msg = (str)VirtualAlloc(null, 64, 12288, 4);
        g_rect = (str)VirtualAlloc(null, 16, 12288, 4);
        g_wide = (str)VirtualAlloc(null, 1024, 12288, 4);
    }
}

!!! A wide copy of `text` read as the code page `cp`: the A interface cannot carry
!!! text a code page other than the system's spells, and a .b source is UTF-8, so
!!! every string it draws goes through here. The caller owns the buffer; it is
!!! sized for the worst case, since no code page turns one byte into more than two
!!! wide characters.
local str _wide_of -> str text, int cp {
    int bytes = lstrlenA(text);
    str w = (str)VirtualAlloc(null, (longlong)(bytes * 2 + 4), 12288, 4);
    if w == null {
        return (str)null;
    }
    MultiByteToWideChar(cp, 0, text, -1, (@void)w, bytes + 1);
    return w;
}

!!! The Windows code page of an `Encoding` value. The numbers are the native
!!! table, in its order: CP1250 to CP1258, the CJK and DOS pages, UTF-8 and the
!!! UCS forms, the ISO pages, the Macintosh pages, the EBCDIC pages and CP1140
!!! to CP1149.
local int _codepage -> int enc {
    if enc == 0 { return 1250; }
    elif enc == 1 { return 1251; }
    elif enc == 2 { return 1252; }
    elif enc == 3 { return 1253; }
    elif enc == 4 { return 1254; }
    elif enc == 5 { return 1255; }
    elif enc == 6 { return 1256; }
    elif enc == 7 { return 1257; }
    elif enc == 8 { return 1258; }
    elif enc == 9 { return 936; }
    elif enc == 10 { return 949; }
    elif enc == 11 { return 950; }
    elif enc == 12 { return 932; }
    elif enc == 13 { return 874; }
    elif enc == 14 { return 20866; }
    elif enc == 15 { return 21866; }
    elif enc == 16 { return 437; }
    elif enc == 17 { return 737; }
    elif enc == 18 { return 775; }
    elif enc == 19 { return 850; }
    elif enc == 20 { return 852; }
    elif enc == 21 { return 855; }
    elif enc == 22 { return 857; }
    elif enc == 23 { return 858; }
    elif enc == 24 { return 860; }
    elif enc == 25 { return 861; }
    elif enc == 26 { return 862; }
    elif enc == 27 { return 863; }
    elif enc == 28 { return 864; }
    elif enc == 29 { return 865; }
    elif enc == 30 { return 866; }
    elif enc == 31 { return 869; }
    elif enc == 32 { return 65001; }
    elif enc == 33 { return 1200; }
    elif enc == 34 { return 1200; }
    elif enc == 35 { return 1201; }
    elif enc == 36 { return 12000; }
    elif enc == 37 { return 12000; }
    elif enc == 38 { return 12001; }
    elif enc == 39 { return 1200; }
    elif enc == 40 { return 28591; }
    elif enc == 41 { return 28592; }
    elif enc == 42 { return 28593; }
    elif enc == 43 { return 28594; }
    elif enc == 44 { return 28595; }
    elif enc == 45 { return 28596; }
    elif enc == 46 { return 28597; }
    elif enc == 47 { return 28598; }
    elif enc == 48 { return 28599; }
    elif enc == 49 { return 28600; }
    elif enc == 50 { return 28601; }
    elif enc == 51 { return 28603; }
    elif enc == 52 { return 28604; }
    elif enc == 53 { return 28605; }
    elif enc == 54 { return 28606; }
    elif enc == 55 { return 10000; }
    elif enc == 56 { return 10004; }
    elif enc == 57 { return 10006; }
    elif enc == 58 { return 10007; }
    elif enc == 59 { return 10010; }
    elif enc == 60 { return 10017; }
    elif enc == 61 { return 10029; }
    elif enc == 62 { return 10079; }
    elif enc == 63 { return 10081; }
    elif enc == 64 { return 10082; }
    elif enc == 65 { return 37; }
    elif enc == 66 { return 273; }
    elif enc == 67 { return 277; }
    elif enc == 68 { return 278; }
    elif enc == 69 { return 280; }
    elif enc == 70 { return 284; }
    elif enc == 71 { return 285; }
    elif enc == 72 { return 297; }
    elif enc == 73 { return 420; }
    elif enc == 74 { return 423; }
    elif enc == 75 { return 424; }
    elif enc == 76 { return 500; }
    elif enc == 77 { return 871; }
    elif enc == 78 { return 875; }
    elif enc == 79 { return 880; }
    elif enc == 80 { return 905; }
    elif enc == 81 { return 924; }
    elif enc == 82 { return 1026; }
    elif enc == 83 { return 1047; }
    elif enc == 84 { return 1140; }
    elif enc == 85 { return 1141; }
    elif enc == 86 { return 1142; }
    elif enc == 87 { return 1143; }
    elif enc == 88 { return 1144; }
    elif enc == 89 { return 1145; }
    elif enc == 90 { return 1146; }
    elif enc == 91 { return 1147; }
    elif enc == 92 { return 1148; }
    elif enc == 93 { return 1149; }
    return 0;
}

!~ ---------- creating and showing ---------- ~!

!!! The window procedure of a plain window. The native one was a stub of three
!!! instructions that forwarded everything to DefWindowProcA and handled nothing
!!! else, and this is that same stub. It has to be a real function here: asking
!!! user32 for the address of its own DefWindowProcA would need the module handle
!!! of user32, not of this DLL, and a null procedure makes CreateWindowExA fail.
longlong _wndproc -> @void hwnd, int msg, longlong wparam, longlong lparam {
    return DefWindowProcA(hwnd, msg, wparam, lparam);
}

!!! The brush a class paints its background with. The native code used the system
!!! colours directly, `(HBRUSH)(COLOR_WINDOW+1)` for a window and
!!! `(HBRUSH)(COLOR_BTNFACE+1)` for a message box; GetSysColorBrush returns those
!!! same brushes, which the language can ask for without turning a number into a
!!! pointer. COLOR_WINDOW is 5 and COLOR_BTNFACE is 15.
local @void _win_brush {
    return GetSysColorBrush(5);
}

local @void _box_brush {
    return GetSysColorBrush(15);
}

bool _createWin -> @void win, int w, int h {
    _reg_class("BLangWin", _win_brush(), (@void)((@func)_wndproc));
    @void hwnd = CreateWindowExA(0, "BLangWin", "", 0x00CF0000, 0, 0, w, h, null, 0, GetModuleHandleA(null), null);
    $win = hwnd;
    if hwnd == null {
        return false;
    }
    return true;
}

void _showWin -> @void win {
    ShowWindow((@void)$win, 5);
}

void _hideWin -> @void win {
    ShowWindow((@void)$win, 0);
}

void _minWin -> @void win {
    ShowWindow((@void)$win, 6);
}

void _maxWin -> @void win {
    ShowWindow((@void)$win, 3);
}

void _closeWin -> @void win {
    DestroyWindow((@void)$win);
}

bool _isWinOpen -> @void win {
    int r = IsWindow((@void)$win);
    if r == 0 {
        return false;
    }
    return true;
}

!!! The window title. The text is read as UTF-8, the encoding a .b source is
!!! written in, and handed to the wide interface; `_setWinTitleA` takes any other
!!! code page.
void _setWinTitle -> @void win, str title {
    str w = _wide_of(title, 65001);
    if w == null {
        end;
    }
    SetWindowTextW((@void)$win, (@void)w);
    VirtualFree((@void)w, 0, 0x8000);
}

!!! The same title through the wide interface, with the code page the encoding
!!! value names. Out of range does nothing, as the native one did.
void _setWinTitleA -> @void win, str title, int encoding {
    if encoding >= 0 {
        if encoding <= 93 {
            _scratch();
            int cp = _codepage(encoding);
            MultiByteToWideChar(cp, 0, title, -1, (@void)g_wide, 512);
            SetWindowTextW((@void)$win, (@void)g_wide);
        }
    }
}

void _setWinSize -> @void win, int w, int h {
    SetWindowPos((@void)$win, null, 0, 0, w, h, 6);
}

void _setWinPos -> @void win, int x, int y {
    SetWindowPos((@void)$win, null, x, y, 0, 0, 5);
}

int _getWinW -> @void win {
    Rect rc;
    GetWindowRect((@void)$win, (@void)@rc);
    return rc.right - rc.left;
}

int _getWinH -> @void win {
    Rect rc;
    GetWindowRect((@void)$win, (@void)@rc);
    return rc.bottom - rc.top;
}

void _drawAgainWin -> @void win {
    InvalidateRect((@void)$win, null, 1);
}

bool _isWinNeedDraw -> @void win {
    int r = GetUpdateRect((@void)$win, null, 0);
    if r == 0 {
        return false;
    }
    return true;
}

int _getScreenW {
    return GetSystemMetrics(0);
}

int _getScreenH {
    return GetSystemMetrics(1);
}

!!! Pump one message for this window. The native one returned whatever
!!! DispatchMessageA left behind, which is 0 for most messages, so nothing here
!!! depends on the result either.
void _nextMsgWin -> @void win {
    _scratch();
    if PeekMessageA((@void)g_msg, (@void)$win, 0, 0, 1) != 0 {
        TranslateMessage((@void)g_msg);
        DispatchMessageA((@void)g_msg);
    }
}

!~ ---------- fonts ---------- ~!

!!! The height CreateFontA wants for a point size: the negative em height at the
!!! screen's DPI (96 DPI turns one point into 4/3 of a pixel).
local int _font_height -> int pts {
    @void hdc = GetDC(null);
    int dpi = 96;
    if hdc != null {
        dpi = GetDeviceCaps(hdc, 90);
        ReleaseDC(null, hdc);
    }
    if dpi <= 0 {
        dpi = 96;
    }
    return 0 - (pts * dpi) / 72;
}

!!! A font handle for a face, a point size and a quality: 1 keeps the system
!!! default, 2 antialiases, 3 uses ClearType and 4 or more ClearType natural.
local @void _make_font -> str font, int pts, int quality {
    int q = 0;
    if quality == 2 {
        q = 4;
    } elif quality == 3 {
        q = 5;
    } elif quality >= 4 {
        q = 6;
    }
    return CreateFontA(_font_height(pts), 0, 0, 0, 400, 0, 0, 0, 1, 0, 0, q, 0, font);
}

!!! The shell's UI font, built once: the one a real message box draws with. The
!!! font Windows hands a control nobody set one for is the old bitmap one, which
!!! is what made the text look jagged, so this is the fallback a box uses when the
!!! program asked for no font of its own.
local @void _msg_font {
    if g_msgfont != null {
        return (@void)g_msgfont;
    }
    str lf = (str)VirtualAlloc(null, 128, 12288, 4);
    if lf != null {
        !!! SPI_GETICONTITLELOGFONT fills a LOGFONTA at the front of the buffer.
        if SystemParametersInfoA(0x1F, 92, (@void)lf, 0) != 0 {
            @void hf = CreateFontIndirectA((@void)lf);
            if hf != null {
                g_msgfont = (str)hf;
                return hf;
            }
        }
    }
    g_msgfont = (str)_make_font("Segoe UI", 9, 3);
    return (@void)g_msgfont;
}

!!! The font of the window's text. The size is a point size and the quality is
!!! the one _make_font takes.
void _setFontWin -> @void win, str font, int pts, int quality {
    @void hfont = _make_font(font, pts, quality);
    g_font = (str)hfont;
    SendMessageA((@void)$win, 48, (longlong)hfont, 1);
}

!!! The font of one button, or of every button when the variable holds null.
!!!
!!! `btu` is the address of the caller's variable, the one _regMsgBoxBtu filled in
!!! (the call is `setFontBtu(@btu1, ...)`), and the number in it is the slot of a
!!! button that only exists once the box is shown, so the font waits in the
!!! registry until then. A button window handle in that variable takes the font at
!!! once instead, which is how a box that is up can be re-fonted. A button with no
!!! font of its own uses the one _setFontWin gave the box, and the system's
!!! message font when that was never called.
void _setFontBtu -> @void btu, str font, int pts, int quality {
    @void hfont = _make_font(font, pts, quality);
    if hfont == null {
        end;
    }
    if btu == null {
        g_btu_font = (str)hfont;
        end;
    }
    @void handle = (@void)$btu;
    if handle == null {
        g_btu_font = (str)hfont;
        end;
    }
    int slot = (int)handle;
    if slot >= 1 {
        if slot <= 8 {
            if g_btu_fonts == null {
                g_btu_fonts = (str)VirtualAlloc(null, 64, 12288, 4);
            }
            @longlong cell = (@longlong)(g_btu_fonts + (slot - 1) * 8);
            $cell = (longlong)hfont;
            if g_btu_hwnds != null {
                @longlong hcell = (@longlong)(g_btu_hwnds + (slot - 1) * 8);
                @void btn = (@void)$hcell;
                if btn != null {
                    SendMessageA(btn, 48, (longlong)hfont, 1);
                }
            }
            end;
        }
    }
    !!! Not a registry slot: the handle of a button window of its own.
    SendMessageA(handle, 48, (longlong)hfont, 1);
}

!~ ---------- message boxes ---------- ~!

!!! Put one button in the registry and hand the caller its number, counting
!!! from one. The ninth and later registrations are ignored, as they were before.
void _regMsgBoxBtu -> @void btu, str text, func fn {
    if btn_count < 8 {
        if btn_count == 0 {
            btn_t0 = text;
            btn_f0 = fn;
        } elif btn_count == 1 {
            btn_t1 = text;
            btn_f1 = fn;
        } elif btn_count == 2 {
            btn_t2 = text;
            btn_f2 = fn;
        } elif btn_count == 3 {
            btn_t3 = text;
            btn_f3 = fn;
        } elif btn_count == 4 {
            btn_t4 = text;
            btn_f4 = fn;
        } elif btn_count == 5 {
            btn_t5 = text;
            btn_f5 = fn;
        } elif btn_count == 6 {
            btn_t6 = text;
            btn_f6 = fn;
        } elif btn_count == 7 {
            btn_t7 = text;
            btn_f7 = fn;
        }
        int handle = btn_count + 1;
        $btu = (@void)handle;
        btn_count = btn_count + 1;
    }
}

!!! Copy the registered callbacks into the window itself, as raw code pointers.
local void _save_btns -> @void hwnd {
    if btn_count > 0 { SetWindowLongPtrA(hwnd, 16, (longlong)((@func)btn_f0)); }
    if btn_count > 1 { SetWindowLongPtrA(hwnd, 24, (longlong)((@func)btn_f1)); }
    if btn_count > 2 { SetWindowLongPtrA(hwnd, 32, (longlong)((@func)btn_f2)); }
    if btn_count > 3 { SetWindowLongPtrA(hwnd, 40, (longlong)((@func)btn_f3)); }
    if btn_count > 4 { SetWindowLongPtrA(hwnd, 48, (longlong)((@func)btn_f4)); }
    if btn_count > 5 { SetWindowLongPtrA(hwnd, 56, (longlong)((@func)btn_f5)); }
    if btn_count > 6 { SetWindowLongPtrA(hwnd, 64, (longlong)((@func)btn_f6)); }
    if btn_count > 7 { SetWindowLongPtrA(hwnd, 72, (longlong)((@func)btn_f7)); }
}

!!! The window procedure of a message box.
!!!
!!! It reads everything it needs out of the window (bytes 0 and 8 hold the text
!!! and the font, 16 and up one code pointer per button) and touches no global.
!!! The reason is how this compiler reaches a global: through r15, which the
!!! entry function sets to its own frame and every callee inherits. A call that
!!! comes from user32 instead - a window procedure, or any other callback - has
!!! whatever r15 user32 was using, so the first global an exported callback reads
!!! faults. Keeping the callbacks as raw code pointers in the window and calling
!!! them through a 0-capture func object is what avoids that.
int _msgbox_wndproc -> @void hwnd, int msg, longlong wparam, longlong lparam {
    if msg == 2 {
        !!! The wide copy of the text was made for this box only.
        @void wide = (@void)GetWindowLongPtrA(hwnd, 0);
        if wide != null {
            VirtualFree(wide, 0, 0x8000);
        }
        return 0;
    }
    if msg == 0x111 {
        int id = (int)wparam & 0xFFFF;
        if id >= 1 {
            if id <= 8 {
                @void raw = (@void)GetWindowLongPtrA(hwnd, 8 + id * 8);
                if raw != null {
                    func fn = (func)raw;
                    fn();
                }
            }
        }
        return 0;
    }
    if msg == 15 {
        Paint ps;
        Rect rc;
        GetClientRect(hwnd, (@void)@rc);
        rc.left = 16;
        rc.top = 16;
        rc.right = rc.right - 16;
        rc.bottom = rc.bottom - 48;
        @void hdc = BeginPaint(hwnd, (@void)@ps);
        SetBkMode(hdc, 1);
        @void font = (@void)GetWindowLongPtrA(hwnd, 8);
        if font == null {
            SelectObject(hdc, GetStockObject(17));
        } else {
            SelectObject(hdc, font);
        }
        str content = (str)(@void)GetWindowLongPtrA(hwnd, 0);
        DrawTextW(hdc, (@void)content, -1, (@void)@rc, 0x810);
        EndPaint(hwnd, (@void)@ps);
        return 0;
    }
    int dflt = (int)DefWindowProcA(hwnd, msg, wparam, lparam);
    return dflt;
}

!!! Show a box: measure the text, size and centre the window, then give it one
!!! BUTTON per registry entry, all in one row. hwnd goes back through the
!!! caller's variable.
!!!
!!! The title, the text and the button labels are read as the code page `cp` and
!!! drawn through the wide interface: a .b source is UTF-8, so the A interface
!!! would read its text as the system's own code page instead and draw nonsense.
!!! The wide copy of the box text is kept in the window for the paint handler and
!!! freed when the window is destroyed.
local bool _show_box -> @void win, str title, str content, int cp {
    _reg_class("BLangMsgBox", _box_brush(), (@void)((@func)_msgbox_wndproc));
    str wtitle = _wide_of(title, cp);
    str wcontent = _wide_of(content, cp);
    str wclass = _wide_of("BLangMsgBox", cp);
    str wbutton = _wide_of("BUTTON", cp);
    g_content = wcontent;
    _scratch();
    str rb = g_rect;
    @int rl = (@int)rb;
    @int rt = (@int)(rb + 4);
    @int rr = (@int)(rb + 8);
    @int rbot = (@int)(rb + 12);
    $rl = 0;
    $rt = 0;
    $rr = 0;
    $rbot = 0;
    @void hdc = GetDC(null);
    !!! Measure with the font the text is drawn with: measuring with another one
    !!! sizes the window for the wrong string.
    @void textfont = (@void)g_font;
    if textfont == null {
        textfont = _msg_font();
    }
    SelectObject(hdc, textfont);
    DrawTextW(hdc, (@void)wcontent, -1, (@void)g_rect, 0xC00);
    ReleaseDC(null, hdc);
    int text_w = $rr;
    int text_h = $rbot;
    int win_w = text_w + 40;
    if win_w < 200 {
        win_w = 200;
    }
    int win_h = text_h + 80;
    int x = (GetSystemMetrics(0) - win_w - 16) / 2;
    int y = (GetSystemMetrics(1) - win_h - 39) / 2;
    @void hwnd = CreateWindowExW(1, (@void)wclass, (@void)wtitle, 0x00C80000, x, y, win_w + 16, win_h + 39, null, 0, GetModuleHandleA(null), null);
    if hwnd != null {
        if g_btu_fonts == null {
            g_btu_fonts = (str)VirtualAlloc(null, 64, 12288, 4);
        }
        if g_btu_hwnds == null {
            g_btu_hwnds = (str)VirtualAlloc(null, 64, 12288, 4);
        }
        Rect client;
        GetClientRect(hwnd, (@void)@client);
        int btn_y = client.bottom - 40;
        int i = 0;
        while i < btn_count {
            int col_w = (client.right - client.left) / btn_count;
            str wtext = _wide_of(_btn_text(i), cp);
            @void hbtn = CreateWindowExW(0, (@void)wbutton, (@void)wtext, 0x50000000, i * col_w, btn_y, col_w, 24, hwnd, (@void)(i + 1), GetModuleHandleA(null), null);
            if wtext != null {
                VirtualFree((@void)wtext, 0, 0x8000);
            }
            @longlong hcell = (@longlong)(g_btu_hwnds + i * 8);
            $hcell = (longlong)hbtn;
            !!! The font of this button, else the one every button shares, else the
            !!! font of the box's own text.
            @longlong cell = (@longlong)(g_btu_fonts + i * 8);
            @void hfont = (@void)$cell;
            if hfont == null {
                hfont = (@void)g_btu_font;
            }
            if hfont == null {
                hfont = textfont;
            }
            if hbtn != null {
                SendMessageA(hbtn, 48, (longlong)hfont, 1);
            }
            i = i + 1;
        }
        !!! The window keeps the wide text for its paint handler; the copies the
        !!! calls above only read are free again.
        SetWindowLongPtrA(hwnd, 0, (longlong)(@void)wcontent);
        SetWindowLongPtrA(hwnd, 8, (longlong)textfont);
        SendMessageA(hwnd, 48, (longlong)textfont, 1);
        if wtitle != null {
            VirtualFree((@void)wtitle, 0, 0x8000);
        }
        if wclass != null {
            VirtualFree((@void)wclass, 0, 0x8000);
        }
        if wbutton != null {
            VirtualFree((@void)wbutton, 0, 0x8000);
        }
        _save_btns(hwnd);
        ShowWindow(hwnd, 5);
    }
    $win = hwnd;
    if hwnd == null {
        return false;
    }
    return true;
}

!!! The box a .b program gets: its text is UTF-8, the encoding a source is written
!!! in.
bool _showMsgBox -> @void win, str title, str content {
    return _show_box(win, title, content, 65001);
}

!!! The same box with the code page the encoding value names, for text that is not
!!! written in UTF-8. Out of range falls back to the system code page.
bool _showMsgBoxA -> @void win, str title, str content, int encoding {
    return _show_box(win, title, content, _codepage(encoding));
}
