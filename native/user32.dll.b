!~
~  native/user32.dll.b: the user32 functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/<dll>.bmeta, and that file
~  is generated from this one with `blang.exe native/user32.dll.b -m`: -m reads
~  the signatures out of the .r and writes meta/user32.dll.bmeta. The name has
~  to end in `.b` after the DLL name because -m strips only the last extension,
~  so `user32.dll.b` is what produces `meta/user32.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m stops after the
~  front end and writes meta/user32.dll.bmeta from the signatures, and in that
~  mode a stub writes its signature into the .r even though it has no body, so
~  this file declares what the DLL exports while carrying no code of its own.
~  Compiling it as ordinary source reports an undefined reference instead of
~  quietly handing out functions that return 0.
~
~  The declarations are generated from user32.dll's own export table and the
~  Windows headers: one `stub` per export the headers declare, with the types
~  the headers give it. WPARAM, LPARAM, LONG_PTR and ULONG_PTR are eight bytes
~  and the language's `longlong` is too, so a pointer or a handle travels
~  through one of them unchanged.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per user32.dll export that the headers declare. The
!!! signature is the one gcc resolved out of windows and the headers
!!! around it (sigdump.c, sigdump2, gen_dll regenerate this
!!! section); the parameter names are the ones the headers write, and a
!!! parameter they leave unnamed is a1, a2 and so on.
!!!
!!! Every line is a `stub`: a signature with no implementation. -m writes
!!! .bmeta from the FUNC lines of the .r, and in that mode a stub writes its
!!! signature, so this file declares what the DLL exports without carrying
!!! any code of its own.
!!!
!!! Types: a pointer to char is str (a byte buffer is @char), a pointer to a
!!! 32-bit integer is @int, a pointer to a 64-bit one is @longlong, a pointer
!!! to a double is @float, a function pointer is @func, and every other
!!! pointer (handles, structures, short, float, wchar_t) is @void. A 64-bit
!!! integer passed by value is longlong. A struct that is passed or returned
!!! by value has no blang equivalent and is left out: those names are listed
!!! at the end of this section.
!!!
!!! 720 declarations here, 0 kept from the hand-checked list above, 27 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub @void ActivateKeyboardLayout -> @void hkl, utype int Flags;
stub int AddClipboardFormatListener -> @void hwnd;
stub int AdjustWindowRect -> @void lpRect, utype int dwStyle, int bMenu;
stub int AdjustWindowRectEx -> @void lpRect, utype int dwStyle, int bMenu, utype int dwExStyle;
stub int AdjustWindowRectExForDpi -> @void lpRect, utype int dwStyle, int bMenu, utype int dwExStyle, utype int dpi;
stub int AllowSetForegroundWindow -> utype int dwProcessId;
stub int AnimateWindow -> @void hWnd, utype int dwTime, utype int dwFlags;
stub int AnyPopup;
stub int AppendMenuA -> @void hMenu, utype int uFlags, utype longlong uIDNewItem, str lpNewItem;
stub int AppendMenuW -> @void hMenu, utype int uFlags, utype longlong uIDNewItem, @void lpNewItem;
stub int AreDpiAwarenessContextsEqual -> @void dpiContextA, @void dpiContextB;
stub utype int ArrangeIconicWindows -> @void hWnd;
stub int AttachThreadInput -> utype int idAttach, utype int idAttachTo, int fAttach;
stub @void BeginDeferWindowPos -> int nNumWindows;
stub @void BeginPaint -> @void hWnd, @void lpPaint;
stub int BlockInput -> int fBlockIt;
stub int BringWindowToTop -> @void hWnd;
stub int BroadcastSystemMessageA -> utype int flags, @int lpInfo, utype int Msg, utype longlong wParam, longlong lParam;
stub int BroadcastSystemMessageExA -> utype int flags, @int lpInfo, utype int Msg, utype longlong wParam, longlong lParam, @void pbsmInfo;
stub int BroadcastSystemMessageExW -> utype int flags, @int lpInfo, utype int Msg, utype longlong wParam, longlong lParam, @void pbsmInfo;
stub int BroadcastSystemMessageW -> utype int flags, @int lpInfo, utype int Msg, utype longlong wParam, longlong lParam;
stub int CalculatePopupWindowPosition -> @void anchorPoint, @void windowSize, utype int flags, @void excludeRect, @void popupWindowPosition;
stub int CallMsgFilterA -> @void lpMsg, int nCode;
stub int CallMsgFilterW -> @void lpMsg, int nCode;
stub longlong CallNextHookEx -> @void hhk, int nCode, utype longlong wParam, longlong lParam;
stub longlong CallWindowProcA -> @func lpPrevWndFunc, @void hWnd, utype int Msg, utype longlong wParam, longlong lParam;
stub longlong CallWindowProcW -> @func lpPrevWndFunc, @void hWnd, utype int Msg, utype longlong wParam, longlong lParam;
stub int CancelShutdown;
stub utype int CascadeWindows -> @void hwndParent, utype int wHow, @void lpRect, utype int cKids, @void lpKids;
stub int ChangeClipboardChain -> @void hWndRemove, @void hWndNewNext;
stub int ChangeDisplaySettingsA -> @void lpDevMode, utype int dwFlags;
stub int ChangeDisplaySettingsExA -> str lpszDeviceName, @void lpDevMode, @void hwnd, utype int dwflags, @void lParam;
stub int ChangeDisplaySettingsExW -> @void lpszDeviceName, @void lpDevMode, @void hwnd, utype int dwflags, @void lParam;
stub int ChangeDisplaySettingsW -> @void lpDevMode, utype int dwFlags;
stub int ChangeMenuA -> @void hMenu, utype int cmd, str lpszNewItem, utype int cmdInsert, utype int flags;
stub int ChangeMenuW -> @void hMenu, utype int cmd, @void lpszNewItem, utype int cmdInsert, utype int flags;
stub int ChangeWindowMessageFilter -> utype int message, utype int dwFlag;
stub int ChangeWindowMessageFilterEx -> @void hwnd, utype int message, utype int action, @void pChangeFilterStruct;
stub str CharLowerA -> str lpsz;
stub utype int CharLowerBuffA -> str lpsz, utype int cchLength;
stub utype int CharLowerBuffW -> @void lpsz, utype int cchLength;
stub @void CharLowerW -> @void lpsz;
stub str CharNextA -> str lpsz;
stub str CharNextExA -> utype int CodePage, str lpCurrentChar, utype int dwFlags;
stub @void CharNextW -> @void lpsz;
stub str CharPrevA -> str lpszStart, str lpszCurrent;
stub str CharPrevExA -> utype int CodePage, str lpStart, str lpCurrentChar, utype int dwFlags;
stub @void CharPrevW -> @void lpszStart, @void lpszCurrent;
stub int CharToOemA -> str lpszSrc, str lpszDst;
stub int CharToOemBuffA -> str lpszSrc, str lpszDst, utype int cchDstLength;
stub int CharToOemBuffW -> @void lpszSrc, str lpszDst, utype int cchDstLength;
stub int CharToOemW -> @void lpszSrc, str lpszDst;
stub str CharUpperA -> str lpsz;
stub utype int CharUpperBuffA -> str lpsz, utype int cchLength;
stub utype int CharUpperBuffW -> @void lpsz, utype int cchLength;
stub @void CharUpperW -> @void String;
stub int CheckDlgButton -> @void hDlg, int nIDButton, utype int uCheck;
stub utype int CheckMenuItem -> @void hMenu, utype int uIDCheckItem, utype int uCheck;
stub int CheckMenuRadioItem -> @void hmenu, utype int first, utype int last, utype int check, utype int flags;
stub int CheckRadioButton -> @void hDlg, int nIDFirstButton, int nIDLastButton, int nIDCheckButton;
stub int ClientToScreen -> @void hWnd, @void lpPoint;
stub int ClipCursor -> @void lpRect;
stub int CloseClipboard;
stub int CloseDesktop -> @void hDesktop;
stub int CloseGestureInfoHandle -> @void hGestureInfo;
stub int CloseTouchInputHandle -> @void hTouchInput;
stub int CloseWindow -> @void hWnd;
stub int CloseWindowStation -> @void hWinSta;
stub int CopyAcceleratorTableA -> @void hAccelSrc, @void lpAccelDst, int cAccelEntries;
stub int CopyAcceleratorTableW -> @void hAccelSrc, @void lpAccelDst, int cAccelEntries;
stub @void CopyIcon -> @void pcur;
stub @void CopyImage -> @void h, utype int type_, int cx, int cy, utype int flags;
stub int CopyRect -> @void lprcDst, @void lprcSrc;
stub int CountClipboardFormats;
stub @void CreateAcceleratorTableA -> @void paccel, int cAccel;
stub @void CreateAcceleratorTableW -> @void paccel, int cAccel;
stub int CreateCaret -> @void hWnd, @void hBitmap, int nWidth, int nHeight;
stub @void CreateCursor -> @void hInst, int xHotSpot, int yHotSpot, int nWidth, int nHeight, @void pvANDPlane, @void pvXORPlane;
stub @void CreateDesktopA -> str lpszDesktop, str lpszDevice, @void pDevmode, utype int dwFlags, utype int dwDesiredAccess, @void lpsa;
stub @void CreateDesktopExA -> str lpszDesktop, str lpszDevice, @void pDevmode, utype int dwFlags, utype int dwDesiredAccess, @void lpsa, utype int ulHeapSize, @void pvoid;
stub @void CreateDesktopExW -> @void lpszDesktop, @void lpszDevice, @void pDevmode, utype int dwFlags, utype int dwDesiredAccess, @void lpsa, utype int ulHeapSize, @void pvoid;
stub @void CreateDesktopW -> @void lpszDesktop, @void lpszDevice, @void pDevmode, utype int dwFlags, utype int dwDesiredAccess, @void lpsa;
stub @void CreateDialogIndirectParamA -> @void hInstance, @void lpTemplate, @void hWndParent, @func lpDialogFunc, longlong dwInitParam;
stub @void CreateDialogIndirectParamW -> @void hInstance, @void lpTemplate, @void hWndParent, @func lpDialogFunc, longlong dwInitParam;
stub @void CreateDialogParamA -> @void hInstance, str lpTemplateName, @void hWndParent, @func lpDialogFunc, longlong dwInitParam;
stub @void CreateDialogParamW -> @void hInstance, @void lpTemplateName, @void hWndParent, @func lpDialogFunc, longlong dwInitParam;
stub @void CreateIcon -> @void hInstance, int nWidth, int nHeight, utype char cPlanes, utype char cBitsPixel, @char lpbANDbits, @char lpbXORbits;
stub @void CreateIconFromResource -> @char presbits, utype int dwResSize, int fIcon, utype int dwVer;
stub @void CreateIconFromResourceEx -> @char presbits, utype int dwResSize, int fIcon, utype int dwVer, int cxDesired, int cyDesired, utype int Flags;
stub @void CreateIconIndirect -> @void piconinfo;
stub @void CreateMDIWindowA -> str lpClassName, str lpWindowName, utype int dwStyle, int X, int Y, int nWidth, int nHeight, @void hWndParent, @void hInstance, longlong lParam;
stub @void CreateMDIWindowW -> @void lpClassName, @void lpWindowName, utype int dwStyle, int X, int Y, int nWidth, int nHeight, @void hWndParent, @void hInstance, longlong lParam;
stub @void CreateMenu;
stub @void CreatePopupMenu;
stub @void CreateWindowExA -> utype int dwExStyle, str lpClassName, str lpWindowName, utype int dwStyle, int X, int Y, int nWidth, int nHeight, @void hWndParent, @void hMenu, @void hInstance, @void lpParam;
stub @void CreateWindowExW -> utype int dwExStyle, @void lpClassName, @void lpWindowName, utype int dwStyle, int X, int Y, int nWidth, int nHeight, @void hWndParent, @void hMenu, @void hInstance, @void lpParam;
stub @void CreateWindowStationA -> str lpwinsta, utype int dwFlags, utype int dwDesiredAccess, @void lpsa;
stub @void CreateWindowStationW -> @void lpwinsta, utype int dwFlags, utype int dwDesiredAccess, @void lpsa;
stub int DdeAbandonTransaction -> utype int idInst, @void hConv, utype int idTransaction;
stub @char DdeAccessData -> @void hData, @int pcbDataSize;
stub @void DdeAddData -> @void hData, @char pSrc, utype int cb, utype int cbOff;
stub @void DdeClientTransaction -> @char pData, utype int cbData, @void hConv, @void hszItem, utype int wFmt, utype int wType, utype int dwTimeout, @int pdwResult;
stub int DdeCmpStringHandles -> @void hsz1, @void hsz2;
stub @void DdeConnect -> utype int idInst, @void hszService, @void hszTopic, @void pCC;
stub @void DdeConnectList -> utype int idInst, @void hszService, @void hszTopic, @void hConvList, @void pCC;
stub @void DdeCreateDataHandle -> utype int idInst, @char pSrc, utype int cb, utype int cbOff, @void hszItem, utype int wFmt, utype int afCmd;
stub @void DdeCreateStringHandleA -> utype int idInst, str psz, int iCodePage;
stub @void DdeCreateStringHandleW -> utype int idInst, @void psz, int iCodePage;
stub int DdeDisconnect -> @void hConv;
stub int DdeDisconnectList -> @void hConvList;
stub int DdeEnableCallback -> utype int idInst, @void hConv, utype int wCmd;
stub int DdeFreeDataHandle -> @void hData;
stub int DdeFreeStringHandle -> utype int idInst, @void hsz;
stub utype int DdeGetData -> @void hData, @char pDst, utype int cbMax, utype int cbOff;
stub utype int DdeGetLastError -> utype int idInst;
stub int DdeImpersonateClient -> @void hConv;
stub utype int DdeInitializeA -> @int pidInst, @func pfnCallback, utype int afCmd, utype int ulRes;
stub utype int DdeInitializeW -> @int pidInst, @func pfnCallback, utype int afCmd, utype int ulRes;
stub int DdeKeepStringHandle -> utype int idInst, @void hsz;
stub @void DdeNameService -> utype int idInst, @void hsz1, @void hsz2, utype int afCmd;
stub int DdePostAdvise -> utype int idInst, @void hszTopic, @void hszItem;
stub utype int DdeQueryConvInfo -> @void hConv, utype int idTransaction, @void pConvInfo;
stub @void DdeQueryNextServer -> @void hConvList, @void hConvPrev;
stub utype int DdeQueryStringA -> utype int idInst, @void hsz, str psz, utype int cchMax, int iCodePage;
stub utype int DdeQueryStringW -> utype int idInst, @void hsz, @void psz, utype int cchMax, int iCodePage;
stub @void DdeReconnect -> @void hConv;
stub int DdeSetQualityOfService -> @void hwndClient, @void pqosNew, @void pqosPrev;
stub int DdeSetUserHandle -> @void hConv, utype int id, utype longlong hUser;
stub int DdeUnaccessData -> @void hData;
stub int DdeUninitialize -> utype int idInst;
stub longlong DefDlgProcA -> @void hDlg, utype int Msg, utype longlong wParam, longlong lParam;
stub longlong DefDlgProcW -> @void hDlg, utype int Msg, utype longlong wParam, longlong lParam;
stub longlong DefFrameProcA -> @void hWnd, @void hWndMDIClient, utype int uMsg, utype longlong wParam, longlong lParam;
stub longlong DefFrameProcW -> @void hWnd, @void hWndMDIClient, utype int uMsg, utype longlong wParam, longlong lParam;
stub longlong DefMDIChildProcA -> @void hWnd, utype int uMsg, utype longlong wParam, longlong lParam;
stub longlong DefMDIChildProcW -> @void hWnd, utype int uMsg, utype longlong wParam, longlong lParam;
stub longlong DefRawInputProc -> @void paRawInput, int nInput, utype int cbSizeHeader;
stub longlong DefWindowProcA -> @void hWnd, utype int Msg, utype longlong wParam, longlong lParam;
stub longlong DefWindowProcW -> @void hWnd, utype int Msg, utype longlong wParam, longlong lParam;
stub @void DeferWindowPos -> @void hWinPosInfo, @void hWnd, @void hWndInsertAfter, int x, int y, int cx, int cy, utype int uFlags;
stub int DeleteMenu -> @void hMenu, utype int uPosition, utype int uFlags;
stub int DeregisterShellHookWindow -> @void hwnd;
stub int DestroyAcceleratorTable -> @void hAccel;
stub int DestroyCaret;
stub int DestroyCursor -> @void hCursor;
stub int DestroyIcon -> @void hIcon;
stub int DestroyMenu -> @void hMenu;
stub void DestroySyntheticPointerDevice -> @void device;
stub int DestroyWindow -> @void hWnd;
stub longlong DialogBoxIndirectParamA -> @void hInstance, @void hDialogTemplate, @void hWndParent, @func lpDialogFunc, longlong dwInitParam;
stub longlong DialogBoxIndirectParamW -> @void hInstance, @void hDialogTemplate, @void hWndParent, @func lpDialogFunc, longlong dwInitParam;
stub longlong DialogBoxParamA -> @void hInstance, str lpTemplateName, @void hWndParent, @func lpDialogFunc, longlong dwInitParam;
stub longlong DialogBoxParamW -> @void hInstance, @void lpTemplateName, @void hWndParent, @func lpDialogFunc, longlong dwInitParam;
stub void DisableProcessWindowsGhosting;
stub longlong DispatchMessageA -> @void lpMsg;
stub longlong DispatchMessageW -> @void lpMsg;
stub int DisplayConfigGetDeviceInfo -> @void requestPacket;
stub int DisplayConfigSetDeviceInfo -> @void setPacket;
stub int DlgDirListA -> @void hDlg, str lpPathSpec, int nIDListBox, int nIDStaticPath, utype int uFileType;
stub int DlgDirListComboBoxA -> @void hDlg, str lpPathSpec, int nIDComboBox, int nIDStaticPath, utype int uFiletype;
stub int DlgDirListComboBoxW -> @void hDlg, @void lpPathSpec, int nIDComboBox, int nIDStaticPath, utype int uFiletype;
stub int DlgDirListW -> @void hDlg, @void lpPathSpec, int nIDListBox, int nIDStaticPath, utype int uFileType;
stub int DlgDirSelectComboBoxExA -> @void hwndDlg, str lpString, int cchOut, int idComboBox;
stub int DlgDirSelectComboBoxExW -> @void hwndDlg, @void lpString, int cchOut, int idComboBox;
stub int DlgDirSelectExA -> @void hwndDlg, str lpString, int chCount, int idListBox;
stub int DlgDirSelectExW -> @void hwndDlg, @void lpString, int chCount, int idListBox;
stub utype int DragObject -> @void hwndParent, @void hwndFrom, utype int fmt, utype longlong data, @void hcur;
stub int DrawAnimatedRects -> @void hwnd, int idAni, @void lprcFrom, @void lprcTo;
stub int DrawCaption -> @void hwnd, @void hdc, @void lprect, utype int flags;
stub int DrawEdge -> @void hdc, @void qrc, utype int edge, utype int grfFlags;
stub int DrawFocusRect -> @void hDC, @void lprc;
stub int DrawFrameControl -> @void a1, @void a2, utype int a3, utype int a4;
stub int DrawIcon -> @void hDC, int X, int Y, @void hIcon;
stub int DrawIconEx -> @void hdc, int xLeft, int yTop, @void hIcon, int cxWidth, int cyWidth, utype int istepIfAniCur, @void hbrFlickerFreeDraw, utype int diFlags;
stub int DrawMenuBar -> @void hWnd;
stub int DrawStateA -> @void hdc, @void hbrFore, @func qfnCallBack, longlong lData, utype longlong wData, int x, int y, int cx, int cy, utype int uFlags;
stub int DrawStateW -> @void hdc, @void hbrFore, @func qfnCallBack, longlong lData, utype longlong wData, int x, int y, int cx, int cy, utype int uFlags;
stub int DrawTextA -> @void hdc, str lpchText, int cchText, @void lprc, utype int format;
stub int DrawTextExA -> @void hdc, str lpchText, int cchText, @void lprc, utype int format, @void lpdtp;
stub int DrawTextExW -> @void hdc, @void lpchText, int cchText, @void lprc, utype int format, @void lpdtp;
stub int DrawTextW -> @void hdc, @void lpchText, int cchText, @void lprc, utype int format;
stub int EmptyClipboard;
stub int EnableMenuItem -> @void hMenu, utype int uIDEnableItem, utype int uEnable;
stub int EnableMouseInPointer -> int fEnable;
stub int EnableNonClientDpiScaling -> @void hwnd;
stub int EnableScrollBar -> @void hWnd, utype int wSBflags, utype int wArrows;
stub int EnableWindow -> @void hWnd, int bEnable;
stub int EndDeferWindowPos -> @void hWinPosInfo;
stub int EndDialog -> @void hDlg, longlong nResult;
stub int EndMenu;
stub int EndPaint -> @void hWnd, @void lpPaint;
stub int EndTask -> @void hWnd, int fShutDown, int fForce;
stub int EnumChildWindows -> @void hWndParent, @func lpEnumFunc, longlong lParam;
stub utype int EnumClipboardFormats -> utype int format;
stub int EnumDesktopWindows -> @void hDesktop, @func lpfn, longlong lParam;
stub int EnumDesktopsA -> @void hwinsta, @func lpEnumFunc, longlong lParam;
stub int EnumDesktopsW -> @void hwinsta, @func lpEnumFunc, longlong lParam;
stub int EnumDisplayDevicesA -> str lpDevice, utype int iDevNum, @void lpDisplayDevice, utype int dwFlags;
stub int EnumDisplayDevicesW -> @void lpDevice, utype int iDevNum, @void lpDisplayDevice, utype int dwFlags;
stub int EnumDisplayMonitors -> @void hdc, @void lprcClip, @func lpfnEnum, longlong dwData;
stub int EnumDisplaySettingsA -> str lpszDeviceName, utype int iModeNum, @void lpDevMode;
stub int EnumDisplaySettingsExA -> str lpszDeviceName, utype int iModeNum, @void lpDevMode, utype int dwFlags;
stub int EnumDisplaySettingsExW -> @void lpszDeviceName, utype int iModeNum, @void lpDevMode, utype int dwFlags;
stub int EnumDisplaySettingsW -> @void lpszDeviceName, utype int iModeNum, @void lpDevMode;
stub int EnumPropsA -> @void hWnd, @func lpEnumFunc;
stub int EnumPropsExA -> @void hWnd, @func lpEnumFunc, longlong lParam;
stub int EnumPropsExW -> @void hWnd, @func lpEnumFunc, longlong lParam;
stub int EnumPropsW -> @void hWnd, @func lpEnumFunc;
stub int EnumThreadWindows -> utype int dwThreadId, @func lpfn, longlong lParam;
stub int EnumWindowStationsA -> @func lpEnumFunc, longlong lParam;
stub int EnumWindowStationsW -> @func lpEnumFunc, longlong lParam;
stub int EnumWindows -> @func lpEnumFunc, longlong lParam;
stub int EqualRect -> @void lprc1, @void lprc2;
stub int EvaluateProximityToPolygon -> utype int numVertices, @void controlPolygon, @void pHitTestingInput, @void pProximityEval;
stub int EvaluateProximityToRect -> @void controlBoundingBox, @void pHitTestingInput, @void pProximityEval;
stub int ExcludeUpdateRgn -> @void hDC, @void hWnd;
stub int ExitWindowsEx -> utype int uFlags, utype int dwReason;
stub int FillRect -> @void hDC, @void lprc, @void hbr;
stub @void FindWindowA -> str lpClassName, str lpWindowName;
stub @void FindWindowExA -> @void hWndParent, @void hWndChildAfter, str lpszClass, str lpszWindow;
stub @void FindWindowExW -> @void hWndParent, @void hWndChildAfter, @void lpszClass, @void lpszWindow;
stub @void FindWindowW -> @void lpClassName, @void lpWindowName;
stub int FlashWindow -> @void hWnd, int bInvert;
stub int FlashWindowEx -> @void pfwi;
stub int FrameRect -> @void hDC, @void lprc, @void hbr;
stub int FreeDDElParam -> utype int msg, longlong lParam;
stub @void GetActiveWindow;
stub int GetAltTabInfoA -> @void hwnd, int iItem, @void pati, str pszItemText, utype int cchItemText;
stub int GetAltTabInfoW -> @void hwnd, int iItem, @void pati, @void pszItemText, utype int cchItemText;
stub @void GetAncestor -> @void hwnd, utype int gaFlags;
stub int GetAsyncKeyState -> int vKey;
stub int GetAutoRotationState -> @void pState;
stub int GetCIMSSM -> @void inputMessageSource;
stub @void GetCapture;
stub utype int GetCaretBlinkTime;
stub int GetCaretPos -> @void lpPoint;
stub int GetClassInfoA -> @void hInstance, str lpClassName, @void lpWndClass;
stub int GetClassInfoExA -> @void hInstance, str lpszClass, @void lpwcx;
stub int GetClassInfoExW -> @void hInstance, @void lpszClass, @void lpwcx;
stub int GetClassInfoW -> @void hInstance, @void lpClassName, @void lpWndClass;
stub utype int GetClassLongA -> @void hWnd, int nIndex;
stub utype longlong GetClassLongPtrA -> @void hWnd, int nIndex;
stub utype longlong GetClassLongPtrW -> @void hWnd, int nIndex;
stub utype int GetClassLongW -> @void hWnd, int nIndex;
stub int GetClassNameA -> @void hWnd, str lpClassName, int nMaxCount;
stub int GetClassNameW -> @void hWnd, @void lpClassName, int nMaxCount;
stub utype int GetClassWord -> @void hWnd, int nIndex;
stub int GetClientRect -> @void hWnd, @void lpRect;
stub int GetClipCursor -> @void lpRect;
stub @void GetClipboardData -> utype int dwReserved;
stub int GetClipboardFormatNameA -> utype int format, str lpszFormatName, int cchMaxCount;
stub int GetClipboardFormatNameW -> utype int format, @void lpszFormatName, int cchMaxCount;
stub @void GetClipboardOwner;
stub utype int GetClipboardSequenceNumber;
stub @void GetClipboardViewer;
stub int GetComboBoxInfo -> @void hwndCombo, @void pcbi;
stub int GetCurrentInputMessageSource -> @void inputMessageSource;
stub @void GetCursor;
stub int GetCursorInfo -> @void pci;
stub int GetCursorPos -> @void lpPoint;
stub @void GetDC -> @void hWnd;
stub @void GetDCEx -> @void hWnd, @void hrgnClip, utype int flags;
stub @void GetDesktopWindow;
stub int GetDialogBaseUnits;
stub int GetDisplayAutoRotationPreferences -> @void pOrientation;
stub int GetDisplayConfigBufferSizes -> utype int flags, @int numPathArrayElements, @int numModeInfoArrayElements;
stub int GetDlgCtrlID -> @void hWnd;
stub @void GetDlgItem -> @void hDlg, int nIDDlgItem;
stub utype int GetDlgItemInt -> @void hDlg, int nIDDlgItem, @int lpTranslated, int bSigned;
stub utype int GetDlgItemTextA -> @void hDlg, int nIDDlgItem, str lpString, int cchMax;
stub utype int GetDlgItemTextW -> @void hDlg, int nIDDlgItem, @void lpString, int cchMax;
stub utype int GetDoubleClickTime;
stub utype int GetDpiForSystem;
stub utype int GetDpiForWindow -> @void hwnd;
stub utype int GetDpiFromDpiAwarenessContext -> @void value;
stub @void GetFocus;
stub @void GetForegroundWindow;
stub int GetGUIThreadInfo -> utype int idThread, @void pgui;
stub int GetGestureConfig -> @void hwnd, utype int dwReserved, utype int dwFlags, @int pcIDs, @void pGestureConfig, utype int cbSize;
stub int GetGestureExtraArgs -> @void hGestureInfo, utype int cbExtraArgs, @char pExtraArgs;
stub int GetGestureInfo -> @void hGestureInfo, @void pGestureInfo;
stub utype int GetGuiResources -> @void hProcess, utype int uiFlags;
stub int GetIconInfo -> @void hIcon, @void piconinfo;
stub int GetIconInfoExA -> @void hicon, @void piconinfo;
stub int GetIconInfoExW -> @void hicon, @void piconinfo;
stub int GetInputState;
stub utype int GetKBCodePage;
stub int GetKeyNameTextA -> int lParam, str lpString, int cchSize;
stub int GetKeyNameTextW -> int lParam, @void lpString, int cchSize;
stub int GetKeyState -> int nVirtKey;
stub @void GetKeyboardLayout -> utype int idThread;
stub int GetKeyboardLayoutList -> int nBuff, @void lpList;
stub int GetKeyboardLayoutNameA -> str pwszKLID;
stub int GetKeyboardLayoutNameW -> @void pwszKLID;
stub int GetKeyboardState -> @char lpKeyState;
stub int GetKeyboardType -> int nTypeFlag;
stub @void GetLastActivePopup -> @void hWnd;
stub int GetLastInputInfo -> @void plii;
stub int GetLayeredWindowAttributes -> @void hwnd, @int pcrKey, @char pbAlpha, @int pdwFlags;
stub utype int GetListBoxInfo -> @void hwnd;
stub @void GetMenu -> @void hWnd;
stub int GetMenuBarInfo -> @void hwnd, int idObject, int idItem, @void pmbi;
stub int GetMenuCheckMarkDimensions;
stub utype int GetMenuContextHelpId -> @void a1;
stub utype int GetMenuDefaultItem -> @void hMenu, utype int fByPos, utype int gmdiFlags;
stub int GetMenuInfo -> @void a1, @void a2;
stub int GetMenuItemCount -> @void hMenu;
stub utype int GetMenuItemID -> @void hMenu, int nPos;
stub int GetMenuItemInfoA -> @void hmenu, utype int item, int fByPosition, @void lpmii;
stub int GetMenuItemInfoW -> @void hmenu, utype int item, int fByPosition, @void lpmii;
stub int GetMenuItemRect -> @void hWnd, @void hMenu, utype int uItem, @void lprcItem;
stub utype int GetMenuState -> @void hMenu, utype int uId, utype int uFlags;
stub int GetMenuStringA -> @void hMenu, utype int uIDItem, str lpString, int cchMax, utype int flags;
stub int GetMenuStringW -> @void hMenu, utype int uIDItem, @void lpString, int cchMax, utype int flags;
stub int GetMessageA -> @void lpMsg, @void hWnd, utype int wMsgFilterMin, utype int wMsgFilterMax;
stub longlong GetMessageExtraInfo;
stub utype int GetMessagePos;
stub int GetMessageTime;
stub int GetMessageW -> @void lpMsg, @void hWnd, utype int wMsgFilterMin, utype int wMsgFilterMax;
stub int GetMonitorInfoA -> @void hMonitor, @void lpmi;
stub int GetMonitorInfoW -> @void hMonitor, @void lpmi;
stub int GetMouseMovePointsEx -> utype int cbSize, @void lppt, @void lpptBuf, int nBufPoints, utype int resolution;
stub @void GetNextDlgGroupItem -> @void hDlg, @void hCtl, int bPrevious;
stub @void GetNextDlgTabItem -> @void hDlg, @void hCtl, int bPrevious;
stub @void GetOpenClipboardWindow;
stub @void GetParent -> @void hWnd;
stub int GetPhysicalCursorPos -> @void lpPoint;
stub int GetPointerCursorId -> utype int pointerId, @int cursorId;
stub int GetPointerDevice -> @void device, @void pointerDevice;
stub int GetPointerDeviceCursors -> @void device, @int cursorCount, @void deviceCursors;
stub int GetPointerDeviceProperties -> @void device, @int propertyCount, @void pointerProperties;
stub int GetPointerDeviceRects -> @void device, @void pointerDeviceRect, @void displayRect;
stub int GetPointerDevices -> @int deviceCount, @void pointerDevices;
stub int GetPointerFrameInfo -> utype int pointerId, @int pointerCount, @void pointerInfo;
stub int GetPointerFrameInfoHistory -> utype int pointerId, @int entriesCount, @int pointerCount, @void pointerInfo;
stub int GetPointerFramePenInfo -> utype int pointerId, @int pointerCount, @void penInfo;
stub int GetPointerFramePenInfoHistory -> utype int pointerId, @int entriesCount, @int pointerCount, @void penInfo;
stub int GetPointerFrameTouchInfo -> utype int pointerId, @int pointerCount, @void touchInfo;
stub int GetPointerFrameTouchInfoHistory -> utype int pointerId, @int entriesCount, @int pointerCount, @void touchInfo;
stub int GetPointerInfo -> utype int pointerId, @void pointerInfo;
stub int GetPointerInfoHistory -> utype int pointerId, @int entriesCount, @void pointerInfo;
stub int GetPointerInputTransform -> utype int pointerId, utype int historyCount, @void inputTransform;
stub int GetPointerPenInfo -> utype int pointerId, @void penInfo;
stub int GetPointerPenInfoHistory -> utype int pointerId, @int entriesCount, @void penInfo;
stub int GetPointerTouchInfo -> utype int pointerId, @void touchInfo;
stub int GetPointerTouchInfoHistory -> utype int pointerId, @int entriesCount, @void touchInfo;
stub int GetPointerType -> utype int pointerId, @int pointerType;
stub int GetPriorityClipboardFormat -> @int paFormatPriorityList, int cFormats;
stub int GetProcessDefaultLayout -> @int pdwDefaultLayout;
stub @void GetProcessWindowStation;
stub @void GetPropA -> @void hWnd, str lpString;
stub @void GetPropW -> @void hWnd, @void lpString;
stub utype int GetQueueStatus -> utype int flags;
stub utype int GetRawInputBuffer -> @void pData, @int pcbSize, utype int cbSizeHeader;
stub utype int GetRawInputData -> @void hRawInput, utype int uiCommand, @void pData, @int pcbSize, utype int cbSizeHeader;
stub utype int GetRawInputDeviceInfoA -> @void hDevice, utype int uiCommand, @void pData, @int pcbSize;
stub utype int GetRawInputDeviceInfoW -> @void hDevice, utype int uiCommand, @void pData, @int pcbSize;
stub utype int GetRawInputDeviceList -> @void pRawInputDeviceList, @int puiNumDevices, utype int cbSize;
stub int GetRawPointerDeviceData -> utype int pointerId, utype int historyCount, utype int propertiesCount, @void pProperties, @int pValues;
stub utype int GetRegisteredRawInputDevices -> @void pRawInputDevices, @int puiNumDevices, utype int cbSize;
stub int GetScrollBarInfo -> @void hwnd, int idObject, @void psbi;
stub int GetScrollInfo -> @void hwnd, int nBar, @void lpsi;
stub int GetScrollPos -> @void hWnd, int nBar;
stub int GetScrollRange -> @void hWnd, int nBar, @int lpMinPos, @int lpMaxPos;
stub @void GetShellWindow;
stub @void GetSubMenu -> @void hMenu, int nPos;
stub utype int GetSysColor -> int nIndex;
stub @void GetSysColorBrush -> int nIndex;
stub utype int GetSystemDpiForProcess -> @void hProcess;
stub @void GetSystemMenu -> @void hWnd, int bRevert;
stub int GetSystemMetrics -> int nIndex;
stub int GetSystemMetricsForDpi -> int nIndex, utype int dpi;
stub utype int GetTabbedTextExtentA -> @void hdc, str lpString, int chCount, int nTabPositions, @int lpnTabStopPositions;
stub utype int GetTabbedTextExtentW -> @void hdc, @void lpString, int chCount, int nTabPositions, @int lpnTabStopPositions;
stub @void GetThreadDesktop -> utype int dwThreadId;
stub @void GetThreadDpiAwarenessContext;
stub int GetTitleBarInfo -> @void hwnd, @void pti;
stub @void GetTopWindow -> @void hWnd;
stub int GetTouchInputInfo -> @void hTouchInput, utype int cInputs, @void pInputs, int cbSize;
stub utype int GetUnpredictedMessagePos;
stub int GetUpdateRect -> @void hWnd, @void lpRect, int bErase;
stub int GetUpdateRgn -> @void hWnd, @void hRgn, int bErase;
stub int GetUpdatedClipboardFormats -> @int lpuiFormats, utype int cFormats, @int pcFormatsOut;
stub int GetUserObjectInformationA -> @void hObj, int nIndex, @void pvInfo, utype int nLength, @int lpnLengthNeeded;
stub int GetUserObjectInformationW -> @void hObj, int nIndex, @void pvInfo, utype int nLength, @int lpnLengthNeeded;
stub int GetUserObjectSecurity -> @void hObj, @int pSIRequested, @void pSID, utype int nLength, @int lpnLengthNeeded;
stub @void GetWindow -> @void rguidReason, utype int phwnd;
stub utype int GetWindowContextHelpId -> @void a1;
stub @void GetWindowDC -> @void hWnd;
stub int GetWindowDisplayAffinity -> @void hWnd, @int pdwAffinity;
stub @void GetWindowDpiAwarenessContext -> @void hwnd;
stub int GetWindowInfo -> @void hwnd, @void pwi;
stub int GetWindowLongA -> @void hWnd, int nIndex;
stub longlong GetWindowLongPtrA -> @void hWnd, int nIndex;
stub longlong GetWindowLongPtrW -> @void hWnd, int nIndex;
stub int GetWindowLongW -> @void hWnd, int nIndex;
stub utype int GetWindowModuleFileNameA -> @void hwnd, str pszFileName, utype int cchFileNameMax;
stub utype int GetWindowModuleFileNameW -> @void hwnd, @void pszFileName, utype int cchFileNameMax;
stub int GetWindowPlacement -> @void hWnd, @void lpwndpl;
stub int GetWindowRect -> @void hWnd, @void lpRect;
stub int GetWindowRgn -> @void hWnd, @void hRgn;
stub int GetWindowRgnBox -> @void hWnd, @void lprc;
stub int GetWindowTextA -> @void hWnd, str lpString, int nMaxCount;
stub int GetWindowTextLengthA -> @void hWnd;
stub int GetWindowTextLengthW -> @void hWnd;
stub int GetWindowTextW -> @void hWnd, @void lpString, int nMaxCount;
stub utype int GetWindowThreadProcessId -> @void hWnd, @int lpdwProcessId;
stub utype int GetWindowWord -> @void hWnd, int nIndex;
stub int GrayStringA -> @void hDC, @void hBrush, @func lpOutputFunc, longlong lpData, int nCount, int X, int Y, int nWidth, int nHeight;
stub int GrayStringW -> @void hDC, @void hBrush, @func lpOutputFunc, longlong lpData, int nCount, int X, int Y, int nWidth, int nHeight;
stub int HideCaret -> @void hWnd;
stub int HiliteMenuItem -> @void hWnd, @void hMenu, utype int uIDHiliteItem, utype int uHilite;
stub int ImpersonateDdeClientWindow -> @void hWndClient, @void hWndServer;
stub int InSendMessage;
stub utype int InSendMessageEx -> @void lpReserved;
stub int InflateRect -> @void lprc, int dx, int dy;
stub int InheritWindowMonitor -> @void hwnd, @void hwndInherit;
stub int InitializeTouchInjection -> utype int maxCount, utype int dwMode;
stub int InjectSyntheticPointerInput -> @void device, @void pointerInfo, utype int cnt;
stub int InjectTouchInput -> utype int cnt, @void contacts;
stub int InsertMenuA -> @void hMenu, utype int uPosition, utype int uFlags, utype longlong uIDNewItem, str lpNewItem;
stub int InsertMenuItemA -> @void hmenu, utype int item, int fByPosition, @void lpmi;
stub int InsertMenuItemW -> @void hmenu, utype int item, int fByPosition, @void lpmi;
stub int InsertMenuW -> @void hMenu, utype int uPosition, utype int uFlags, utype longlong uIDNewItem, @void lpNewItem;
stub int InternalGetWindowText -> @void hWnd, @void pString, int cchMaxCount;
stub int IntersectRect -> @void lprcDst, @void lprcSrc1, @void lprcSrc2;
stub int InvalidateRect -> @void hWnd, @void lpRect, int bErase;
stub int InvalidateRgn -> @void hWnd, @void hRgn, int bErase;
stub int InvertRect -> @void hDC, @void lprc;
stub int IsCharAlphaA -> char ch;
stub int IsCharAlphaNumericA -> char ch;
stub int IsCharLowerA -> char ch;
stub int IsCharUpperA -> char ch;
stub int IsChild -> @void hWndParent, @void hWnd;
stub int IsClipboardFormatAvailable -> utype int format;
stub int IsDialogMessageA -> @void hDlg, @void lpMsg;
stub int IsDialogMessageW -> @void hDlg, @void lpMsg;
stub utype int IsDlgButtonChecked -> @void hDlg, int nIDButton;
stub int IsGUIThread -> int bConvert;
stub int IsHungAppWindow -> @void hwnd;
stub int IsIconic -> @void hWnd;
stub int IsImmersiveProcess -> @void hProcess;
stub int IsMenu -> @void hMenu;
stub int IsMouseInPointerEnabled;
stub int IsProcessDPIAware;
stub int IsRectEmpty -> @void lprc;
stub int IsTouchWindow -> @void hwnd, @int pulFlags;
stub int IsValidDpiAwarenessContext -> @void value;
stub int IsWinEventHookInstalled -> utype int event;
stub int IsWindow -> @void hWnd;
stub int IsWindowArranged -> @void hwnd;
stub int IsWindowEnabled -> @void hWnd;
stub int IsWindowUnicode -> @void hWnd;
stub int IsWindowVisible -> @void hWnd;
stub int IsWow64Message;
stub int IsZoomed -> @void hWnd;
stub int KillTimer -> @void hWnd, utype longlong uIDEvent;
stub @void LoadAcceleratorsA -> @void hInstance, str lpTableName;
stub @void LoadAcceleratorsW -> @void hInstance, @void lpTableName;
stub @void LoadBitmapA -> @void hInstance, str lpBitmapName;
stub @void LoadBitmapW -> @void hInstance, @void lpBitmapName;
stub @void LoadCursorA -> @void hInstance, str lpCursorName;
stub @void LoadCursorFromFileA -> str lpFileName;
stub @void LoadCursorFromFileW -> @void lpFileName;
stub @void LoadCursorW -> @void hInstance, @void lpCursorName;
stub @void LoadIconA -> @void hInstance, str lpIconName;
stub @void LoadIconW -> @void hInstance, @void lpIconName;
stub @void LoadImageA -> @void hInst, str name, utype int type_, int cx, int cy, utype int fuLoad;
stub @void LoadImageW -> @void hInst, @void name, utype int type_, int cx, int cy, utype int fuLoad;
stub @void LoadKeyboardLayoutA -> str pwszKLID, utype int Flags;
stub @void LoadKeyboardLayoutW -> @void pwszKLID, utype int Flags;
stub @void LoadMenuA -> @void hInstance, str lpMenuName;
stub @void LoadMenuIndirectA -> @void lpMenuTemplate;
stub @void LoadMenuIndirectW -> @void lpMenuTemplate;
stub @void LoadMenuW -> @void hInstance, @void lpMenuName;
stub int LoadStringA -> @void hInstance, utype int uID, str lpBuffer, int cchBufferMax;
stub int LoadStringW -> @void hInstance, utype int uID, @void lpBuffer, int cchBufferMax;
stub int LockSetForegroundWindow -> utype int uLockCode;
stub int LockWindowUpdate -> @void hWndLock;
stub int LockWorkStation;
stub int LogicalToPhysicalPoint -> @void hWnd, @void lpPoint;
stub int LogicalToPhysicalPointForPerMonitorDPI -> @void hwnd, @void lpPoint;
stub int LookupIconIdFromDirectory -> @char presbits, int fIcon;
stub int LookupIconIdFromDirectoryEx -> @char presbits, int fIcon, int cxDesired, int cyDesired, utype int Flags;
stub int MapDialogRect -> @void hDlg, @void lpRect;
stub utype int MapVirtualKeyA -> utype int uCode, utype int uMapType;
stub utype int MapVirtualKeyExA -> utype int uCode, utype int uMapType, @void dwhkl;
stub utype int MapVirtualKeyExW -> utype int uCode, utype int uMapType, @void dwhkl;
stub utype int MapVirtualKeyW -> utype int uCode, utype int uMapType;
stub int MapWindowPoints -> @void hWndFrom, @void hWndTo, @void lpPoints, utype int cPoints;
stub int MessageBeep -> utype int uType;
stub int MessageBoxA -> @void hWnd, str lpText, str lpCaption, utype int uType;
stub int MessageBoxExA -> @void hWnd, str lpText, str lpCaption, utype int uType, utype int wLanguageId;
stub int MessageBoxExW -> @void hWnd, @void lpText, @void lpCaption, utype int uType, utype int wLanguageId;
stub int MessageBoxIndirectA -> @void lpmbp;
stub int MessageBoxIndirectW -> @void lpmbp;
stub int MessageBoxW -> @void hWnd, @void lpText, @void lpCaption, utype int uType;
stub int ModifyMenuA -> @void hMnu, utype int uPosition, utype int uFlags, utype longlong uIDNewItem, str lpNewItem;
stub int ModifyMenuW -> @void hMnu, utype int uPosition, utype int uFlags, utype longlong uIDNewItem, @void lpNewItem;
stub @void MonitorFromRect -> @void lprc, utype int dwFlags;
stub @void MonitorFromWindow -> @void hwnd, utype int dwFlags;
stub int MoveWindow -> @void hWnd, int X, int Y, int nWidth, int nHeight, int bRepaint;
stub utype int MsgWaitForMultipleObjects -> utype int nCount, @void pHandles, int fWaitAll, utype int dwMilliseconds, utype int dwWakeMask;
stub utype int MsgWaitForMultipleObjectsEx -> utype int nCount, @void pHandles, utype int dwMilliseconds, utype int dwWakeMask, utype int dwFlags;
stub void NotifyWinEvent -> utype int event, @void hwnd, int idObject, int idChild;
stub utype int OemKeyScan -> utype int wOemChar;
stub int OemToCharA -> str lpszSrc, str lpszDst;
stub int OemToCharBuffA -> str lpszSrc, str lpszDst, utype int cchDstLength;
stub int OemToCharBuffW -> str lpszSrc, @void lpszDst, utype int cchDstLength;
stub int OemToCharW -> str lpszSrc, @void lpszDst;
stub int OffsetRect -> @void lprc, int dx, int dy;
stub int OpenClipboard -> @void hWndNewOwner;
stub @void OpenDesktopA -> str lpszDesktop, utype int dwFlags, int fInherit, utype int dwDesiredAccess;
stub @void OpenDesktopW -> @void lpszDesktop, utype int dwFlags, int fInherit, utype int dwDesiredAccess;
stub int OpenIcon -> @void hWnd;
stub @void OpenInputDesktop -> utype int dwFlags, int fInherit, utype int dwDesiredAccess;
stub @void OpenWindowStationA -> str lpszWinSta, int fInherit, utype int dwDesiredAccess;
stub @void OpenWindowStationW -> @void lpszWinSta, int fInherit, utype int dwDesiredAccess;
stub longlong PackDDElParam -> utype int msg, utype longlong uiLo, utype longlong uiHi;
stub longlong PackTouchHitTestingProximityEvaluation -> @void pHitTestingInput, @void pProximityEval;
stub int PaintDesktop -> @void hdc;
stub int PeekMessageA -> @void lpMsg, @void hWnd, utype int wMsgFilterMin, utype int wMsgFilterMax, utype int wRemoveMsg;
stub int PeekMessageW -> @void lpMsg, @void hWnd, utype int wMsgFilterMin, utype int wMsgFilterMax, utype int wRemoveMsg;
stub int PhysicalToLogicalPoint -> @void hWnd, @void lpPoint;
stub int PhysicalToLogicalPointForPerMonitorDPI -> @void hwnd, @void lpPoint;
stub int PostMessageA -> @void hWnd, utype int Msg, utype longlong wParam, longlong lParam;
stub int PostMessageW -> @void hWnd, utype int Msg, utype longlong wParam, longlong lParam;
stub void PostQuitMessage -> int nExitCode;
stub int PostThreadMessageA -> utype int idThread, utype int Msg, utype longlong wParam, longlong lParam;
stub int PostThreadMessageW -> utype int idThread, utype int Msg, utype longlong wParam, longlong lParam;
stub int PrintWindow -> @void hwnd, @void hdcBlt, utype int nFlags;
stub utype int PrivateExtractIconsA -> str szFileName, int nIconIndex, int cxIcon, int cyIcon, @void phicon, @int piconid, utype int nIcons, utype int flags;
stub utype int PrivateExtractIconsW -> @void szFileName, int nIconIndex, int cxIcon, int cyIcon, @void phicon, @int piconid, utype int nIcons, utype int flags;
stub int QueryDisplayConfig -> utype int flags, @int numPathArrayElements, @void pathArray, @int numModeInfoArrayElements, @void modeInfoArray, @void currentTopologyId;
stub utype int RealGetWindowClassA -> @void hwnd, str ptszClassName, utype int cchClassNameMax;
stub utype int RealGetWindowClassW -> @void hwnd, @void ptszClassName, utype int cchClassNameMax;
stub int RedrawWindow -> @void hWnd, @void lprcUpdate, @void hrgnUpdate, utype int flags;
stub utype int RegisterClassA -> @void lpWndClass;
stub utype int RegisterClassExA -> @void WNDCLASSEXA;
stub utype int RegisterClassExW -> @void WNDCLASSEXW;
stub utype int RegisterClassW -> @void lpWndClass;
stub utype int RegisterClipboardFormatA -> str lpszFormat;
stub utype int RegisterClipboardFormatW -> @void lpszFormat;
stub @void RegisterDeviceNotificationA -> @void hRecipient, @void NotificationFilter, utype int Flags;
stub @void RegisterDeviceNotificationW -> @void hRecipient, @void NotificationFilter, utype int Flags;
stub int RegisterHotKey -> @void hWnd, int id, utype int fsModifiers, utype int vk;
stub int RegisterPointerDeviceNotifications -> @void window, int notifyRange;
stub int RegisterPointerInputTarget -> @void hwnd, utype int pointerType;
stub int RegisterPointerInputTargetEx -> @void hwnd, utype int pointerType, int fObserve;
stub @void RegisterPowerSettingNotification -> @void hRecipient, @void PowerSettingGuid, utype int Flags;
stub int RegisterRawInputDevices -> @void pRawInputDevices, utype int uiNumDevices, utype int cbSize;
stub int RegisterShellHookWindow -> @void hwnd;
stub @void RegisterSuspendResumeNotification -> @void hRecipient, utype int Flags;
stub int RegisterTouchHitTestingWindow -> @void hwnd, utype int value;
stub int RegisterTouchWindow -> @void hwnd, utype int ulFlags;
stub utype int RegisterWindowMessageA -> str lpString;
stub utype int RegisterWindowMessageW -> @void lpString;
stub int ReleaseCapture;
stub int ReleaseDC -> @void hWnd, @void hDC;
stub int RemoveClipboardFormatListener -> @void hwnd;
stub int RemoveMenu -> @void hMenu, utype int uPosition, utype int uFlags;
stub @void RemovePropA -> @void hWnd, str lpString;
stub @void RemovePropW -> @void hWnd, @void lpString;
stub int ReplyMessage -> longlong lResult;
stub longlong ReuseDDElParam -> longlong lParam, utype int msgIn, utype int msgOut, utype longlong uiLo, utype longlong uiHi;
stub int ScreenToClient -> @void hWnd, @void lpPoint;
stub int ScrollDC -> @void hDC, int dx, int dy, @void lprcScroll, @void lprcClip, @void hrgnUpdate, @void lprcUpdate;
stub int ScrollWindow -> @void hWnd, int XAmount, int YAmount, @void lpRect, @void lpClipRect;
stub int ScrollWindowEx -> @void hWnd, int dx, int dy, @void prcScroll, @void prcClip, @void hrgnUpdate, @void prcUpdate, utype int flags;
stub longlong SendDlgItemMessageA -> @void hDlg, int nIDDlgItem, utype int Msg, utype longlong wParam, longlong lParam;
stub longlong SendDlgItemMessageW -> @void hDlg, int nIDDlgItem, utype int Msg, utype longlong wParam, longlong lParam;
stub utype int SendInput -> utype int cInputs, @void pInputs, int cbSize;
stub longlong SendMessageA -> @void hWnd, utype int Msg, utype longlong wParam, longlong lParam;
stub int SendMessageCallbackA -> @void hWnd, utype int Msg, utype longlong wParam, longlong lParam, @func lpResultCallBack, utype longlong dwData;
stub int SendMessageCallbackW -> @void hWnd, utype int Msg, utype longlong wParam, longlong lParam, @func lpResultCallBack, utype longlong dwData;
stub longlong SendMessageTimeoutA -> @void hWnd, utype int Msg, utype longlong wParam, longlong lParam, utype int fuFlags, utype int uTimeout, @longlong lpdwResult;
stub longlong SendMessageTimeoutW -> @void hWnd, utype int Msg, utype longlong wParam, longlong lParam, utype int fuFlags, utype int uTimeout, @longlong lpdwResult;
stub longlong SendMessageW -> @void hWnd, utype int Msg, utype longlong wParam, longlong lParam;
stub int SendNotifyMessageA -> @void hWnd, utype int Msg, utype longlong wParam, longlong lParam;
stub int SendNotifyMessageW -> @void hWnd, utype int Msg, utype longlong wParam, longlong lParam;
stub @void SetActiveWindow -> @void hWnd;
stub @void SetCapture -> @void hWnd;
stub int SetCaretBlinkTime -> utype int uMSeconds;
stub int SetCaretPos -> int X, int Y;
stub utype int SetClassLongA -> @void hWnd, int nIndex, int dwNewLong;
stub utype longlong SetClassLongPtrA -> @void hWnd, int nIndex, longlong dwNewLong;
stub utype longlong SetClassLongPtrW -> @void hWnd, int nIndex, longlong dwNewLong;
stub utype int SetClassLongW -> @void hWnd, int nIndex, int dwNewLong;
stub utype int SetClassWord -> @void hWnd, int nIndex, utype int wNewWord;
stub @void SetClipboardData -> utype int uFormat, @void hMem;
stub @void SetClipboardViewer -> @void hWndNewViewer;
stub utype longlong SetCoalescableTimer -> @void hWnd, utype longlong nIDEvent, utype int uElapse, @func lpTimerFunc, utype int uToleranceDelay;
stub @void SetCursor -> @void hCursor;
stub int SetCursorPos -> int X, int Y;
stub void SetDebugErrorLevel -> utype int dwLevel;
stub int SetDisplayConfig -> utype int numPathArrayElements, @void pathArray, utype int numModeInfoArrayElements, @void modeInfoArray, utype int flags;
stub int SetDlgItemInt -> @void hDlg, int nIDDlgItem, utype int uValue, int bSigned;
stub int SetDlgItemTextA -> @void hDlg, int nIDDlgItem, str lpString;
stub int SetDlgItemTextW -> @void hDlg, int nIDDlgItem, @void lpString;
stub int SetDoubleClickTime -> utype int a1;
stub @void SetFocus -> @void hWnd;
stub int SetForegroundWindow -> @void hWnd;
stub int SetGestureConfig -> @void hwnd, utype int dwReserved, utype int cIDs, @void pGestureConfig, utype int cbSize;
stub int SetKeyboardState -> @char lpKeyState;
stub void SetLastErrorEx -> utype int dwErrCode, utype int dwType;
stub int SetLayeredWindowAttributes -> @void hwnd, utype int crKey, utype char bAlpha, utype int dwFlags;
stub int SetMenu -> @void hmenuShared, @void holemenu;
stub int SetMenuContextHelpId -> @void a1, utype int a2;
stub int SetMenuDefaultItem -> @void hMenu, utype int uItem, utype int fByPos;
stub int SetMenuInfo -> @void a1, @void a2;
stub int SetMenuItemBitmaps -> @void hMenu, utype int uPosition, utype int uFlags, @void hBitmapUnchecked, @void hBitmapChecked;
stub int SetMenuItemInfoA -> @void hmenu, utype int item, int fByPositon, @void lpmii;
stub int SetMenuItemInfoW -> @void hmenu, utype int item, int fByPositon, @void lpmii;
stub longlong SetMessageExtraInfo -> longlong lParam;
stub int SetMessageQueue -> int cMessagesMax;
stub @void SetParent -> @void hWndChild, @void hWndNewParent;
stub int SetPhysicalCursorPos -> int X, int Y;
stub int SetProcessDPIAware;
stub int SetProcessDefaultLayout -> utype int dwDefaultLayout;
stub int SetProcessDpiAwarenessContext -> @void value;
stub int SetProcessRestrictionExemption -> int fEnableExemption;
stub int SetProcessWindowStation -> @void hWinSta;
stub int SetPropA -> @void hWnd, str lpString, @void hData;
stub int SetPropW -> @void hWnd, @void lpString, @void hData;
stub int SetRect -> @void lprc, int xLeft, int yTop, int xRight, int yBottom;
stub int SetRectEmpty -> @void lprc;
stub int SetScrollInfo -> @void hwnd, int nBar, @void lpsi, int redraw;
stub int SetScrollPos -> @void hWnd, int nBar, int nPos, int bRedraw;
stub int SetScrollRange -> @void hWnd, int nBar, int nMinPos, int nMaxPos, int bRedraw;
stub int SetSysColors -> int cElements, @int lpaElements, @int lpaRgbValues;
stub int SetSystemCursor -> @void hcur, utype int id;
stub int SetThreadDesktop -> @void hDesktop;
stub @void SetThreadDpiAwarenessContext -> @void dpiContext;
stub utype longlong SetTimer -> @void hWnd, utype longlong nIDEvent, utype int uElapse, @func lpTimerFunc;
stub int SetUserObjectInformationA -> @void hObj, int nIndex, @void pvInfo, utype int nLength;
stub int SetUserObjectInformationW -> @void hObj, int nIndex, @void pvInfo, utype int nLength;
stub int SetUserObjectSecurity -> @void hObj, @int pSIRequested, @void pSID;
stub @void SetWinEventHook -> utype int eventMin, utype int eventMax, @void hmodWinEventProc, @func pfnWinEventProc, utype int idProcess, utype int idThread, utype int dwFlags;
stub int SetWindowContextHelpId -> @void a1, utype int a2;
stub int SetWindowDisplayAffinity -> @void hWnd, utype int dwAffinity;
stub int SetWindowLongA -> @void hWnd, int nIndex, int dwNewLong;
stub longlong SetWindowLongPtrA -> @void hWnd, int nIndex, longlong dwNewLong;
stub longlong SetWindowLongPtrW -> @void hWnd, int nIndex, longlong dwNewLong;
stub int SetWindowLongW -> @void hWnd, int nIndex, int dwNewLong;
stub int SetWindowPlacement -> @void hWnd, @void lpwndpl;
stub int SetWindowPos -> @void hWnd, @void hWndInsertAfter, int X, int Y, int cx, int cy, utype int uFlags;
stub int SetWindowRgn -> @void hWnd, @void hRgn, int bRedraw;
stub int SetWindowTextA -> @void hWnd, str lpString;
stub int SetWindowTextW -> @void hWnd, @void lpString;
stub utype int SetWindowWord -> @void hWnd, int nIndex, utype int wNewWord;
stub @void SetWindowsHookA -> int nFilterType, @func pfnFilterProc;
stub @void SetWindowsHookExA -> int idHook, @func lpfn, @void hmod, utype int dwThreadId;
stub @void SetWindowsHookExW -> int idHook, @func lpfn, @void hmod, utype int dwThreadId;
stub @void SetWindowsHookW -> int nFilterType, @func pfnFilterProc;
stub int ShowCaret -> @void hWnd;
stub int ShowCursor -> int bShow;
stub int ShowOwnedPopups -> @void hWnd, int fShow;
stub int ShowScrollBar -> @void hWnd, int wBar, int bShow;
stub int ShowWindow -> @void hWnd, int nCmdShow;
stub int ShowWindowAsync -> @void hWnd, int nCmdShow;
stub int ShutdownBlockReasonCreate -> @void hWnd, @void pwszReason;
stub int ShutdownBlockReasonDestroy -> @void hWnd;
stub int ShutdownBlockReasonQuery -> @void hWnd, @void pwszBuff, @int pcchBuff;
stub int SkipPointerFrameMessages -> utype int pointerId;
stub int SoundSentry;
stub int SubtractRect -> @void lprcDst, @void lprcSrc1, @void lprcSrc2;
stub int SwapMouseButton -> int fSwap;
stub int SwitchDesktop -> @void hDesktop;
stub void SwitchToThisWindow -> @void hwnd, int fUnknown;
stub int SystemParametersInfoA -> utype int uiAction, utype int uiParam, @void pvParam, utype int fWinIni;
stub int SystemParametersInfoForDpi -> utype int uiAction, utype int uiParam, @void pvParam, utype int fWinIni, utype int dpi;
stub int SystemParametersInfoW -> utype int uiAction, utype int uiParam, @void pvParam, utype int fWinIni;
stub int TabbedTextOutA -> @void hdc, int x, int y, str lpString, int chCount, int nTabPositions, @int lpnTabStopPositions, int nTabOrigin;
stub int TabbedTextOutW -> @void hdc, int x, int y, @void lpString, int chCount, int nTabPositions, @int lpnTabStopPositions, int nTabOrigin;
stub utype int TileWindows -> @void hwndParent, utype int wHow, @void lpRect, utype int cKids, @void lpKids;
stub int ToAscii -> utype int uVirtKey, utype int uScanCode, @char lpKeyState, @int lpChar, utype int uFlags;
stub int ToAsciiEx -> utype int uVirtKey, utype int uScanCode, @char lpKeyState, @int lpChar, utype int uFlags, @void dwhkl;
stub int ToUnicode -> utype int wVirtKey, utype int wScanCode, @char lpKeyState, @void pwszBuff, int cchBuff, utype int wFlags;
stub int ToUnicodeEx -> utype int wVirtKey, utype int wScanCode, @char lpKeyState, @void pwszBuff, int cchBuff, utype int wFlags, @void dwhkl;
stub int TrackMouseEvent -> @void lpEventTrack;
stub int TrackPopupMenu -> @void hMenu, utype int uFlags, int x, int y, int nReserved, @void hWnd, @void prcRect;
stub int TrackPopupMenuEx -> @void a1, utype int a2, int a3, int a4, @void a5, @void a6;
stub int TranslateAcceleratorA -> @void hWnd, @void hAccTable, @void lpMsg;
stub int TranslateAcceleratorW -> @void hWnd, @void hAccTable, @void lpMsg;
stub int TranslateMDISysAccel -> @void hWndClient, @void lpMsg;
stub int TranslateMessage -> @void lpMsg;
stub int UnhookWinEvent -> @void hWinEventHook;
stub int UnhookWindowsHook -> int nCode, @func pfnFilterProc;
stub int UnhookWindowsHookEx -> @void hhk;
stub int UnionRect -> @void lprcDst, @void lprcSrc1, @void lprcSrc2;
stub int UnloadKeyboardLayout -> @void hkl;
stub int UnpackDDElParam -> utype int msg, longlong lParam, @longlong puiLo, @longlong puiHi;
stub int UnregisterClassA -> str lpClassName, @void hInstance;
stub int UnregisterClassW -> @void lpClassName, @void hInstance;
stub int UnregisterDeviceNotification -> @void Handle;
stub int UnregisterHotKey -> @void hWnd, int id;
stub int UnregisterPointerInputTarget -> @void hwnd, utype int pointerType;
stub int UnregisterPointerInputTargetEx -> @void hwnd, utype int pointerType;
stub int UnregisterPowerSettingNotification -> @void Handle;
stub int UnregisterSuspendResumeNotification -> @void Handle;
stub int UnregisterTouchWindow -> @void hwnd;
stub int UpdateLayeredWindow -> @void hWnd, @void hdcDst, @void pptDst, @void psize, @void hdcSrc, @void pptSrc, utype int crKey, @void pblend, utype int dwFlags;
stub int UpdateLayeredWindowIndirect -> @void hWnd, @void pULWInfo;
stub int UpdateWindow -> @void hWnd;
stub int UserHandleGrantAccess -> @void hUserHandle, @void hJob, int bGrant;
stub int ValidateRect -> @void hWnd, @void lpRect;
stub int ValidateRgn -> @void hWnd, @void hRgn;
stub int VkKeyScanA -> char ch;
stub int VkKeyScanExA -> char ch, @void dwhkl;
stub utype int WaitForInputIdle -> @void hProcess, utype int dwMilliseconds;
stub int WaitMessage;
stub int WinHelpA -> @void hWndMain, str lpszHelp, utype int uCommand, utype longlong dwData;
stub int WinHelpW -> @void hWndMain, @void lpszHelp, utype int uCommand, utype longlong dwData;
stub @void WindowFromDC -> @void hDC;
stub void keybd_event -> utype char bVk, utype char bScan, utype int dwFlags, utype longlong dwExtraInfo;
stub void mouse_event -> utype int dwFlags, utype int dx, utype int dy, utype int dwData, utype longlong dwExtraInfo;
stub int wsprintfA -> str a1, str a2, int a3...;
stub int wsprintfW -> @void a1, @void a2, int a3...;
stub int wvsprintfA -> str a1, str a2, str arglist;
stub int wvsprintfW -> @void a1, @void a2, str arglist;

!!! Declared by the headers, but with a type the language cannot write:
!!!   ChildWindowFromPoint
!!!   ChildWindowFromPointEx
!!!   CreateSyntheticPointerDevice
!!!   DragDetect
!!!   GetAwarenessFromDpiAwarenessContext
!!!   GetDialogControlDpiChangeBehavior
!!!   GetDialogDpiChangeBehavior
!!!   GetThreadDpiHostingBehavior
!!!   GetWindowDpiHostingBehavior
!!!   GetWindowFeedbackSetting
!!!   IsCharAlphaNumericW
!!!   IsCharAlphaW
!!!   IsCharLowerW
!!!   IsCharUpperW
!!!   MenuItemFromPoint
!!!   MonitorFromPoint
!!!   PtInRect
!!!   RealChildWindowFromPoint
!!!   SetDialogControlDpiChangeBehavior
!!!   SetDialogDpiChangeBehavior
!!!   SetDisplayAutoRotationPreferences
!!!   SetThreadDpiHostingBehavior
!!!   SetWindowFeedbackSetting
!!!   VkKeyScanExW
!!!   VkKeyScanW
!!!   WindowFromPhysicalPoint
!!!   WindowFromPoint

!!! No prototype in the headers this build saw. They are here so the
!!! list is complete; uncomment and give the real signature to use one.
!!! ChildWindowFromPoint
!!! ChildWindowFromPointEx
!!! CreateSyntheticPointerDevice
!!! DragDetect
!!! GetAwarenessFromDpiAwarenessContext
!!! GetDialogControlDpiChangeBehavior
!!! GetDialogDpiChangeBehavior
!!! GetThreadDpiHostingBehavior
!!! GetWindowDpiHostingBehavior
!!! GetWindowFeedbackSetting
!!! IsCharAlphaNumericW
!!! IsCharAlphaW
!!! IsCharLowerW
!!! IsCharUpperW
!!! MenuItemFromPoint
!!! MonitorFromPoint
!!! PtInRect
!!! RealChildWindowFromPoint
!!! SetDialogControlDpiChangeBehavior
!!! SetDialogDpiChangeBehavior
!!! SetDisplayAutoRotationPreferences
!!! SetThreadDpiHostingBehavior
!!! SetWindowFeedbackSetting
!!! VkKeyScanExW
!!! VkKeyScanW
!!! WindowFromPhysicalPoint
!!! WindowFromPoint
