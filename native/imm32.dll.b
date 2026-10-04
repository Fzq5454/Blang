!~
~  native/imm32.dll.b: the imm32.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/imm32.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/imm32.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `imm32.dll.b` is what produces `meta/imm32.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\imm32.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per imm32.dll export that the headers declare. The
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
!!! 63 declarations here, 0 kept from the hand-checked list above, 0 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub @void ImmAssociateContext -> @void a1, @void a2;
stub int ImmAssociateContextEx -> @void a1, @void a2, utype int a3;
stub int ImmConfigureIMEA -> @void a1, @void a2, utype int a3, @void a4;
stub int ImmConfigureIMEW -> @void a1, @void a2, utype int a3, @void a4;
stub @void ImmCreateContext;
stub int ImmDestroyContext -> @void a1;
stub int ImmDisableIME -> utype int a1;
stub int ImmDisableTextFrameService -> utype int idThread;
stub int ImmEnumInputContext -> utype int idThread, @func lpfn, longlong lParam;
stub utype int ImmEnumRegisterWordA -> @void a1, @func a2, str lpszReading, utype int a4, str lpszRegister, @void a6;
stub utype int ImmEnumRegisterWordW -> @void a1, @func a2, @void lpszReading, utype int a4, @void lpszRegister, @void a6;
stub longlong ImmEscapeA -> @void a1, @void a2, utype int a3, @void a4;
stub longlong ImmEscapeW -> @void a1, @void a2, utype int a3, @void a4;
stub utype int ImmGetCandidateListA -> @void a1, utype int deIndex, @void a3, utype int dwBufLen;
stub utype int ImmGetCandidateListCountA -> @void a1, @int lpdwListCount;
stub utype int ImmGetCandidateListCountW -> @void a1, @int lpdwListCount;
stub utype int ImmGetCandidateListW -> @void a1, utype int deIndex, @void a3, utype int dwBufLen;
stub int ImmGetCandidateWindow -> @void a1, utype int a2, @void a3;
stub int ImmGetCompositionFontA -> @void a1, @void a2;
stub int ImmGetCompositionFontW -> @void a1, @void a2;
stub int ImmGetCompositionStringA -> @void a1, utype int a2, @void a3, utype int a4;
stub int ImmGetCompositionStringW -> @void a1, utype int a2, @void a3, utype int a4;
stub int ImmGetCompositionWindow -> @void a1, @void a2;
stub @void ImmGetContext -> @void a1;
stub utype int ImmGetConversionListA -> @void a1, @void a2, str a3, @void a4, utype int dwBufLen, utype int uFlag;
stub utype int ImmGetConversionListW -> @void a1, @void a2, @void a3, @void a4, utype int dwBufLen, utype int uFlag;
stub int ImmGetConversionStatus -> @void a1, @int a2, @int a3;
stub @void ImmGetDefaultIMEWnd -> @void a1;
stub utype int ImmGetDescriptionA -> @void a1, str a2, utype int uBufLen;
stub utype int ImmGetDescriptionW -> @void a1, @void a2, utype int uBufLen;
stub utype int ImmGetGuideLineA -> @void a1, utype int dwIndex, str a3, utype int dwBufLen;
stub utype int ImmGetGuideLineW -> @void a1, utype int dwIndex, @void a3, utype int dwBufLen;
stub utype int ImmGetIMEFileNameA -> @void a1, str a2, utype int uBufLen;
stub utype int ImmGetIMEFileNameW -> @void a1, @void a2, utype int uBufLen;
stub utype int ImmGetImeMenuItemsA -> @void a1, utype int a2, utype int a3, @void a4, @void a5, utype int a6;
stub utype int ImmGetImeMenuItemsW -> @void a1, utype int a2, utype int a3, @void a4, @void a5, utype int a6;
stub int ImmGetOpenStatus -> @void a1;
stub utype int ImmGetProperty -> @void a1, utype int a2;
stub utype int ImmGetRegisterWordStyleA -> @void a1, utype int nItem, @void a3;
stub utype int ImmGetRegisterWordStyleW -> @void a1, utype int nItem, @void a3;
stub int ImmGetStatusWindowPos -> @void a1, @void a2;
stub utype int ImmGetVirtualKey -> @void a1;
stub @void ImmInstallIMEA -> str lpszIMEFileName, str lpszLayoutText;
stub @void ImmInstallIMEW -> @void lpszIMEFileName, @void lpszLayoutText;
stub int ImmIsIME -> @void a1;
stub int ImmIsUIMessageA -> @void a1, utype int a2, utype longlong a3, longlong a4;
stub int ImmIsUIMessageW -> @void a1, utype int a2, utype longlong a3, longlong a4;
stub int ImmNotifyIME -> @void a1, utype int dwAction, utype int dwIndex, utype int dwValue;
stub int ImmRegisterWordA -> @void a1, str lpszReading, utype int a3, str lpszRegister;
stub int ImmRegisterWordW -> @void a1, @void lpszReading, utype int a3, @void lpszRegister;
stub int ImmReleaseContext -> @void a1, @void a2;
stub int ImmSetCandidateWindow -> @void a1, @void a2;
stub int ImmSetCompositionFontA -> @void a1, @void a2;
stub int ImmSetCompositionFontW -> @void a1, @void a2;
stub int ImmSetCompositionStringA -> @void a1, utype int dwIndex, @void lpComp, utype int a4, @void lpRead, utype int a6;
stub int ImmSetCompositionStringW -> @void a1, utype int dwIndex, @void lpComp, utype int a4, @void lpRead, utype int a6;
stub int ImmSetCompositionWindow -> @void a1, @void a2;
stub int ImmSetConversionStatus -> @void a1, utype int a2, utype int a3;
stub int ImmSetOpenStatus -> @void a1, int a2;
stub int ImmSetStatusWindowPos -> @void a1, @void a2;
stub int ImmSimulateHotKey -> @void a1, utype int a2;
stub int ImmUnregisterWordA -> @void a1, str lpszReading, utype int a3, str lpszUnregister;
stub int ImmUnregisterWordW -> @void a1, @void lpszReading, utype int a3, @void lpszUnregister;
