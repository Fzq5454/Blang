!~
~  native/shell32.dll.b: the shell32.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/shell32.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/shell32.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `shell32.dll.b` is what produces `meta/shell32.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\shell32.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per shell32.dll export that the headers declare. The
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
!!! 65 declarations here, 0 kept from the hand-checked list above, 1 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub int AssocCreateForClasses -> @void rgClasses, utype int cClasses, @void riid, @void ppv;
stub @void CommandLineToArgvW -> @void lpCmdLine, @int pNumArgs;
stub utype int DoEnvironmentSubstA -> str pszSrc, utype int cchSrc;
stub utype int DoEnvironmentSubstW -> @void pszSrc, utype int cchSrc;
stub void DragAcceptFiles -> @void hWnd, int fAccept;
stub void DragFinish -> @void hDrop;
stub utype int DragQueryFileA -> @void hDrop, utype int iFile, str lpszFile, utype int cch;
stub utype int DragQueryFileW -> @void hDrop, utype int iFile, @void lpszFile, utype int cch;
stub int DragQueryPoint -> @void hDrop, @void ppt;
stub @void DuplicateIcon -> @void hInst, @void hIcon;
stub @void ExtractAssociatedIconA -> @void hInst, str pszIconPath, @int piIcon;
stub @void ExtractAssociatedIconExA -> @void hInst, str pszIconPath, @int piIconIndex, @int piIconId;
stub @void ExtractAssociatedIconExW -> @void hInst, @void pszIconPath, @int piIconIndex, @int piIconId;
stub @void ExtractAssociatedIconW -> @void hInst, @void pszIconPath, @int piIcon;
stub @void ExtractIconA -> @void hInst, str pszExeFileName, utype int nIconIndex;
stub utype int ExtractIconExA -> str lpszFile, int nIconIndex, @void phiconLarge, @void phiconSmall, utype int nIcons;
stub utype int ExtractIconExW -> @void lpszFile, int nIconIndex, @void phiconLarge, @void phiconSmall, utype int nIcons;
stub @void ExtractIconW -> @void hInst, @void pszExeFileName, utype int nIconIndex;
stub @void FindExecutableA -> str lpFile, str lpDirectory, str lpResult;
stub @void FindExecutableW -> @void lpFile, @void lpDirectory, @void lpResult;
stub int InitNetworkAddressControl;
stub int IsLFNDriveA -> str pszPath;
stub int IsLFNDriveW -> @void pszPath;
stub utype longlong SHAppBarMessage -> utype int dwMessage, @void pData;
stub int SHCreateProcessAsUserW -> @void pscpi;
stub int SHEmptyRecycleBinA -> @void hwnd, str pszRootPath, utype int dwFlags;
stub int SHEmptyRecycleBinW -> @void hwnd, @void pszRootPath, utype int dwFlags;
stub int SHEnumerateUnreadMailAccountsW -> @void hKeyUser, utype int dwIndex, @void pszMailAddress, int cchMailAddress;
stub int SHEvaluateSystemCommandTemplate -> @void pszCmdTemplate, @void ppszApplication, @void ppszCommandLine, @void ppszParameters;
stub int SHFileOperationA -> @void lpFileOp;
stub int SHFileOperationW -> @void lpFileOp;
stub void SHFreeNameMappings -> @void hNameMappings;
stub int SHGetDiskFreeSpaceExA -> str pszDirectoryName, @longlong pulFreeBytesAvailableToCaller, @longlong pulTotalNumberOfBytes, @longlong pulTotalNumberOfFreeBytes;
stub int SHGetDiskFreeSpaceExW -> @void pszDirectoryName, @longlong pulFreeBytesAvailableToCaller, @longlong pulTotalNumberOfBytes, @longlong pulTotalNumberOfFreeBytes;
stub int SHGetDriveMedia -> @void pszDrive, @int pdwMediaContent;
stub utype longlong SHGetFileInfoA -> str pszPath, utype int dwFileAttributes, @void psfi, utype int cbFileInfo, utype int uFlags;
stub utype longlong SHGetFileInfoW -> @void pszPath, utype int dwFileAttributes, @void psfi, utype int cbFileInfo, utype int uFlags;
stub int SHGetImageList -> int iImageList, @void riid, @void ppvObj;
stub int SHGetLocalizedName -> @void pszPath, @void pszResModule, utype int cch, @int pidsRes;
stub int SHGetNewLinkInfoA -> str pszLinkTo, str pszDir, str pszName, @int pfMustCopy, utype int uFlags;
stub int SHGetNewLinkInfoW -> @void pszLinkTo, @void pszDir, @void pszName, @int pfMustCopy, utype int uFlags;
stub int SHGetPropertyStoreForWindow -> @void hwnd, @void riid, @void ppv;
stub int SHGetUnreadMailCountW -> @void hKeyUser, @void pszMailAddress, @int pdwCount, @void pFileTime, @void pszShellExecuteCommand, int cchShellExecuteCommand;
stub int SHInvokePrinterCommandA -> @void hwnd, utype int uAction, str lpBuf1, str lpBuf2, int fModal;
stub int SHInvokePrinterCommandW -> @void hwnd, utype int uAction, @void lpBuf1, @void lpBuf2, int fModal;
stub int SHIsFileAvailableOffline -> @void pwszPath, @int pdwStatus;
stub int SHLoadNonloadedIconOverlayIdentifiers;
stub int SHQueryRecycleBinA -> str pszRootPath, @void pSHQueryRBInfo;
stub int SHQueryRecycleBinW -> @void pszRootPath, @void pSHQueryRBInfo;
stub int SHQueryUserNotificationState -> @void pquns;
stub int SHRemoveLocalizedName -> @void pszPath;
stub int SHSetLocalizedName -> @void pszPath, @void pszResModule, int idsRes;
stub int SHSetUnreadMailCountW -> @void pszMailAddress, utype int dwCount, @void pszShellExecuteCommand;
stub int SHTestTokenMembership -> @void hToken, utype int ulRID;
stub int ShellAboutA -> @void hWnd, str szApp, str szOtherStuff, @void hIcon;
stub int ShellAboutW -> @void hWnd, @void szApp, @void szOtherStuff, @void hIcon;
stub @void ShellExecuteA -> @void hwnd, str lpOperation, str lpFile, str lpParameters, str lpDirectory, int nShowCmd;
stub int ShellExecuteExA -> @void pExecInfo;
stub int ShellExecuteExW -> @void pExecInfo;
stub @void ShellExecuteW -> @void hwnd, @void lpOperation, @void lpFile, @void lpParameters, @void lpDirectory, int nShowCmd;
stub int ShellMessageBoxA -> @void a1, @void a2, str a3, str a4, utype int a5, int a6...;
stub int ShellMessageBoxW -> @void a1, @void a2, @void a3, @void a4, utype int a5, int a6...;
stub int Shell_NotifyIconA -> utype int dwMessage, @void lpData;
stub int Shell_NotifyIconGetRect -> @void identifier, @void iconLocation;
stub int Shell_NotifyIconW -> utype int dwMessage, @void lpData;

!!! Declared by the headers, but with a type the language cannot write:
!!!   SHGetStockIconInfo

!!! No prototype in the headers this build saw. They are here so the
!!! list is complete; uncomment and give the real signature to use one.
!!! SHGetStockIconInfo
