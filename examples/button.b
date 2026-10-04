#head "stdsrt"
#head "window"

void yes { system.out("yes\n"); }
void no { system.out("no\n"); }

int WinMain {
    @void win;
    @void btu1;
    @void btu2;
    setFontWin(@win, "微软雅黑", 9, 6);
    setFontBtu(@btu1, "Arial", 9, 6);
    regMsgBoxBtu(@btu1, "OK", yes);
    regMsgBoxBtu(@btu2, "Cancel", no);
    if showMsgBox(@win, "你好", "你好", @btu1, @btu2) {
        while isWinOpen(@win) {
            nextMsgWin(@win);
            if isWinNeedDraw(@win) {
                drawAgainWin(@win);
            }
        }
    }
    return 0;
}