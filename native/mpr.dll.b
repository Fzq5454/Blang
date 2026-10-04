!~
~  native/mpr.dll.b: the mpr.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/mpr.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/mpr.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `mpr.dll.b` is what produces `meta/mpr.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\mpr.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per mpr.dll export that the headers declare. The
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
!!! 42 declarations here, 0 kept from the hand-checked list above, 0 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub utype int MultinetGetConnectionPerformanceA -> @void lpNetResource, @void lpNetConnectInfoStruct;
stub utype int MultinetGetConnectionPerformanceW -> @void lpNetResource, @void lpNetConnectInfoStruct;
stub utype int WNetAddConnection2A -> @void lpNetResource, str lpPassword, str lpUserName, utype int dwFlags;
stub utype int WNetAddConnection2W -> @void lpNetResource, @void lpPassword, @void lpUserName, utype int dwFlags;
stub utype int WNetAddConnection3A -> @void hwndOwner, @void lpNetResource, str lpPassword, str lpUserName, utype int dwFlags;
stub utype int WNetAddConnection3W -> @void hwndOwner, @void lpNetResource, @void lpPassword, @void lpUserName, utype int dwFlags;
stub utype int WNetAddConnectionA -> str lpRemoteName, str lpPassword, str lpLocalName;
stub utype int WNetAddConnectionW -> @void lpRemoteName, @void lpPassword, @void lpLocalName;
stub utype int WNetCancelConnection2A -> str lpName, utype int dwFlags, int fForce;
stub utype int WNetCancelConnection2W -> @void lpName, utype int dwFlags, int fForce;
stub utype int WNetCancelConnectionA -> str lpName, int fForce;
stub utype int WNetCancelConnectionW -> @void lpName, int fForce;
stub utype int WNetCloseEnum -> @void hEnum;
stub utype int WNetConnectionDialog -> @void hwnd, utype int dwType;
stub utype int WNetConnectionDialog1A -> @void lpConnDlgStruct;
stub utype int WNetConnectionDialog1W -> @void lpConnDlgStruct;
stub utype int WNetDisconnectDialog -> @void hwnd, utype int dwType;
stub utype int WNetDisconnectDialog1A -> @void lpConnDlgStruct;
stub utype int WNetDisconnectDialog1W -> @void lpConnDlgStruct;
stub utype int WNetEnumResourceA -> @void hEnum, @int lpcCount, @void lpBuffer, @int lpBufferSize;
stub utype int WNetEnumResourceW -> @void hEnum, @int lpcCount, @void lpBuffer, @int lpBufferSize;
stub utype int WNetGetConnectionA -> str lpLocalName, str lpRemoteName, @int lpnLength;
stub utype int WNetGetConnectionW -> @void lpLocalName, @void lpRemoteName, @int lpnLength;
stub utype int WNetGetLastErrorA -> @int lpError, str lpErrorBuf, utype int nErrorBufSize, str lpNameBuf, utype int nNameBufSize;
stub utype int WNetGetLastErrorW -> @int lpError, @void lpErrorBuf, utype int nErrorBufSize, @void lpNameBuf, utype int nNameBufSize;
stub utype int WNetGetNetworkInformationA -> str lpProvider, @void lpNetInfoStruct;
stub utype int WNetGetNetworkInformationW -> @void lpProvider, @void lpNetInfoStruct;
stub utype int WNetGetProviderNameA -> utype int dwNetType, str lpProviderName, @int lpBufferSize;
stub utype int WNetGetProviderNameW -> utype int dwNetType, @void lpProviderName, @int lpBufferSize;
stub utype int WNetGetResourceInformationA -> @void lpNetResource, @void lpBuffer, @int lpcbBuffer, @void lplpSystem;
stub utype int WNetGetResourceInformationW -> @void lpNetResource, @void lpBuffer, @int lpcbBuffer, @void lplpSystem;
stub utype int WNetGetResourceParentA -> @void lpNetResource, @void lpBuffer, @int lpcbBuffer;
stub utype int WNetGetResourceParentW -> @void lpNetResource, @void lpBuffer, @int lpcbBuffer;
stub utype int WNetGetUniversalNameA -> str lpLocalPath, utype int dwInfoLevel, @void lpBuffer, @int lpBufferSize;
stub utype int WNetGetUniversalNameW -> @void lpLocalPath, utype int dwInfoLevel, @void lpBuffer, @int lpBufferSize;
stub utype int WNetGetUserA -> str lpName, str lpUserName, @int lpnLength;
stub utype int WNetGetUserW -> @void lpName, @void lpUserName, @int lpnLength;
stub utype int WNetOpenEnumA -> utype int dwScope, utype int dwType, utype int dwUsage, @void lpNetResource, @void lphEnum;
stub utype int WNetOpenEnumW -> utype int dwScope, utype int dwType, utype int dwUsage, @void lpNetResource, @void lphEnum;
stub utype int WNetRestoreSingleConnectionW -> @void hwndParent, @void lpDevice, int fUseUI;
stub utype int WNetUseConnectionA -> @void hwndOwner, @void lpNetResource, str lpPassword, str lpUserID, utype int dwFlags, str lpAccessName, @int lpBufferSize, @int lpResult;
stub utype int WNetUseConnectionW -> @void hwndOwner, @void lpNetResource, @void lpPassword, @void lpUserID, utype int dwFlags, @void lpAccessName, @int lpBufferSize, @int lpResult;
