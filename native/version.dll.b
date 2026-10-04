!~
~  native/version.dll.b: the version.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/version.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/version.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `version.dll.b` is what produces `meta/version.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\version.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per version.dll export that the headers declare. The
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
!!! 16 declarations here, 0 kept from the hand-checked list above, 0 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub int GetFileVersionInfoA -> str lptstrFilename, utype int dwHandle, utype int dwLen, @void lpData;
stub int GetFileVersionInfoExA -> utype int dwFlags, str lpwstrFilename, utype int dwHandle, utype int dwLen, @void lpData;
stub int GetFileVersionInfoExW -> utype int dwFlags, @void lpwstrFilename, utype int dwHandle, utype int dwLen, @void lpData;
stub utype int GetFileVersionInfoSizeA -> str lptstrFilename, @int lpdwHandle;
stub utype int GetFileVersionInfoSizeExA -> utype int dwFlags, str lpwstrFilename, @int lpdwHandle;
stub utype int GetFileVersionInfoSizeExW -> utype int dwFlags, @void lpwstrFilename, @int lpdwHandle;
stub utype int GetFileVersionInfoSizeW -> @void lptstrFilename, @int lpdwHandle;
stub int GetFileVersionInfoW -> @void lptstrFilename, utype int dwHandle, utype int dwLen, @void lpData;
stub utype int VerFindFileA -> utype int uFlags, str szFileName, str szWinDir, str szAppDir, str szCurDir, @int lpuCurDirLen, str szDestDir, @int lpuDestDirLen;
stub utype int VerFindFileW -> utype int uFlags, @void szFileName, @void szWinDir, @void szAppDir, @void szCurDir, @int lpuCurDirLen, @void szDestDir, @int lpuDestDirLen;
stub utype int VerInstallFileA -> utype int uFlags, str szSrcFileName, str szDestFileName, str szSrcDir, str szDestDir, str szCurDir, str szTmpFile, @int lpuTmpFileLen;
stub utype int VerInstallFileW -> utype int uFlags, @void szSrcFileName, @void szDestFileName, @void szSrcDir, @void szDestDir, @void szCurDir, @void szTmpFile, @int lpuTmpFileLen;
stub utype int VerLanguageNameA -> utype int wLang, str szLang, utype int nSize;
stub utype int VerLanguageNameW -> utype int wLang, @void szLang, utype int nSize;
stub int VerQueryValueA -> @void pBlock, str lpSubBlock, @void lplpBuffer, @int puLen;
stub int VerQueryValueW -> @void pBlock, @void lpSubBlock, @void lplpBuffer, @int puLen;
