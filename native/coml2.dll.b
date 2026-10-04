!~
~  native/coml2.dll.b: the coml2.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/coml2.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/coml2.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `coml2.dll.b` is what produces `meta/coml2.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\coml2.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per coml2.dll export that the headers declare. The
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
!!! 21 declarations here, 0 kept from the hand-checked list above, 0 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub int CreateILockBytesOnHGlobal -> @void hGlobal, int fDeleteOnRelease, @void pplkbyt;
stub int FmtIdToPropStgName -> @void pfmtid, @void oszName;
stub int GetConvertStg -> @void pStg;
stub int GetHGlobalFromILockBytes -> @void plkbyt, @void phglobal;
stub int PropStgNameToFmtId -> @void oszName, @void pfmtid;
stub int ReadClassStg -> @void pStg, @void pclsid;
stub int ReadClassStm -> @void pStm, @void pclsid;
stub int StgCreateDocfile -> @void pwcsName, utype int grfMode, utype int reserved, @void ppstgOpen;
stub int StgCreateDocfileOnILockBytes -> @void plkbyt, utype int grfMode, utype int reserved, @void ppstgOpen;
stub int StgCreatePropSetStg -> @void pStorage, utype int dwReserved, @void ppPropSetStg;
stub int StgCreatePropStg -> @void pUnk, @void fmtid, @void pclsid, utype int grfFlags, utype int dwReserved, @void ppPropStg;
stub int StgCreateStorageEx -> @void pwcsName, utype int grfMode, utype int stgfmt, utype int grfAttrs, @void pStgOptions, @void pSecurityDescriptor, @void riid, @void ppObjectOpen;
stub int StgIsStorageFile -> @void pwcsName;
stub int StgIsStorageILockBytes -> @void plkbyt;
stub int StgOpenPropStg -> @void pUnk, @void fmtid, utype int grfFlags, utype int dwReserved, @void ppPropStg;
stub int StgOpenStorage -> @void pwcsName, @void pstgPriority, utype int grfMode, @void snbExclude, utype int reserved, @void ppstgOpen;
stub int StgOpenStorageEx -> @void pwcsName, utype int grfMode, utype int stgfmt, utype int grfAttrs, @void pStgOptions, @void pSecurityDescriptor, @void riid, @void ppObjectOpen;
stub int StgOpenStorageOnILockBytes -> @void plkbyt, @void pstgPriority, utype int grfMode, @void snbExclude, utype int reserved, @void ppstgOpen;
stub int StgSetTimes -> @void lpszName, @void pctime, @void patime, @void pmtime;
stub int WriteClassStg -> @void pStg, @void rclsid;
stub int WriteClassStm -> @void pStm, @void rclsid;
