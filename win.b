#head "stdsrt"
#head "format"
#head "window"

int WinMain {
    @void win;
    if createWin(@win, 800, 600) {
        setWinTitle(@win, "Test Window");
        setWinPos(@win, (getScreenW() - getWinW(@win)) / 2, (getScreenH() - getWinH(@win)) / 2);
        showWin(@win);
    }
    while isWinOpen(@win) {
        nextMsgWin(@win);
        if isWinNeedDraw(@win) {
            drawAgainWin(@win);
        }
    }
    
    return 0;
}
