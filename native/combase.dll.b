!~
~  native/combase.dll.b: the combase.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/combase.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/combase.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `combase.dll.b` is what produces `meta/combase.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\combase.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per combase.dll export that the headers declare. The
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
!!! 126 declarations here, 0 kept from the hand-checked list above, 3 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub void CLIPFORMAT_UserFree -> @int a1, @int a2;
stub @char CLIPFORMAT_UserMarshal -> @int a1, @char a2, @int a3;
stub utype int CLIPFORMAT_UserSize -> @int a1, utype int a2, @int a3;
stub @char CLIPFORMAT_UserUnmarshal -> @int a1, @char a2, @int a3;
stub int CLSIDFromProgID -> @void lpszProgID, @void lpclsid;
stub int CLSIDFromProgIDEx -> @void lpszProgID, @void lpclsid;
stub int CLSIDFromString -> @void lpsz, @void pclsid;
stub utype int CoAddRefServerProcess;
stub int CoAllowUnmarshalerCLSID -> @void clsid;
stub int CoCancelCall -> utype int dwThreadId, utype int ulTimeout;
stub int CoCopyProxy -> @void pProxy, @void ppCopy;
stub int CoCreateFreeThreadedMarshaler -> @void punkOuter, @void ppunkMarshal;
stub int CoCreateGuid -> @void pguid;
stub int CoCreateInstance -> @void rclsid, @void pUnkOuter, utype int dwClsContext, @void riid, @void ppv;
stub int CoCreateInstanceEx -> @void Clsid, @void punkOuter, utype int dwClsCtx, @void pServerInfo, utype int dwCount, @void pResults;
stub int CoCreateInstanceFromApp -> @void Clsid, @void punkOuter, utype int dwClsCtx, @void reserved, utype int dwCount, @void pResults;
stub int CoDecodeProxy -> utype int dwClientPid, utype longlong ui64ProxyAddress, @void pServerInformation;
stub int CoDecrementMTAUsage -> @void Cookie;
stub int CoDisableCallCancellation -> @void pReserved;
stub int CoDisconnectContext -> utype int dwTimeout;
stub int CoDisconnectObject -> @void pUnk, utype int dwReserved;
stub int CoEnableCallCancellation -> @void pReserved;
stub int CoFileTimeNow -> @void lpFileTime;
stub void CoFreeUnusedLibraries;
stub void CoFreeUnusedLibrariesEx -> utype int dwUnloadDelay, utype int dwReserved;
stub int CoGetApartmentType -> @void pAptType, @void pAptQualifier;
stub int CoGetCallContext -> @void riid, @void ppInterface;
stub int CoGetCallerTID -> @int lpdwTID;
stub int CoGetCancelObject -> utype int dwThreadId, @void iid, @void ppUnk;
stub int CoGetClassObject -> @void rclsid, utype int dwClsContext, @void pvReserved, @void riid, @void ppv;
stub int CoGetContextToken -> @longlong pToken;
stub int CoGetCurrentLogicalThreadId -> @void pguid;
stub utype int CoGetCurrentProcess;
stub int CoGetInstanceFromFile -> @void pServerInfo, @void pClsid, @void punkOuter, utype int dwClsCtx, utype int grfMode, @void pwszName, utype int dwCount, @void pResults;
stub int CoGetInstanceFromIStorage -> @void pServerInfo, @void pClsid, @void punkOuter, utype int dwClsCtx, @void pstg, utype int dwCount, @void pResults;
stub int CoGetInterfaceAndReleaseStream -> @void pStm, @void iid, @void ppv;
stub int CoGetMalloc -> utype int dwMemContext, @void ppMalloc;
stub int CoGetMarshalSizeMax -> @int pulSize, @void riid, @void pUnk, utype int dwDestContext, @void pvDestContext, utype int mshlflags;
stub int CoGetObjectContext -> @void riid, @void ppv;
stub int CoGetPSClsid -> @void riid, @void pClsid;
stub int CoGetStandardMarshal -> @void riid, @void pUnk, utype int dwDestContext, @void pvDestContext, utype int mshlflags, @void ppMarshal;
stub int CoGetStdMarshalEx -> @void pUnkOuter, utype int smexflags, @void ppUnkInner;
stub int CoGetTreatAsClass -> @void clsidOld, @void pClsidNew;
stub int CoImpersonateClient;
stub int CoIncrementMTAUsage -> @void pCookie;
stub int CoInitializeEx -> @void pvReserved, utype int dwCoInit;
stub int CoInitializeSecurity -> @void pSecDesc, int cAuthSvc, @void asAuthSvc, @void pReserved1, utype int dwAuthnLevel, utype int dwImpLevel, @void pAuthList, utype int dwCapabilities, @void pReserved3;
stub int CoInvalidateRemoteMachineBindings -> @void pszMachineName;
stub int CoIsHandlerConnected -> @void pUnk;
stub int CoIsOle1Class -> @void rclsid;
stub int CoLockObjectExternal -> @void pUnk, int fLock, int fLastUnlockReleases;
stub int CoMarshalHresult -> @void pstm, int hresult;
stub int CoMarshalInterThreadInterfaceInStream -> @void riid, @void pUnk, @void ppStm;
stub int CoMarshalInterface -> @void pStm, @void riid, @void pUnk, utype int dwDestContext, @void pvDestContext, utype int mshlflags;
stub int CoQueryAuthenticationServices -> @int pcAuthSvc, @void asAuthSvc;
stub int CoQueryClientBlanket -> @int pAuthnSvc, @int pAuthzSvc, @void pServerPrincName, @int pAuthnLevel, @int pImpLevel, @void pPrivs, @int pCapabilities;
stub int CoQueryProxyBlanket -> @void pProxy, @int pwAuthnSvc, @int pAuthzSvc, @void pServerPrincName, @int pAuthnLevel, @int pImpLevel, @void pAuthInfo, @int pCapabilites;
stub int CoRegisterClassObject -> @void rclsid, @void pUnk, utype int dwClsContext, utype int flags, @int lpdwRegister;
stub int CoRegisterInitializeSpy -> @void pSpy, @longlong puliCookie;
stub int CoRegisterMallocSpy -> @void pMallocSpy;
stub int CoRegisterMessageFilter -> @void lpMessageFilter, @void lplpMessageFilter;
stub int CoRegisterPSClsid -> @void riid, @void rclsid;
stub int CoRegisterSurrogate -> @void pSurrogate;
stub int CoReleaseMarshalData -> @void pStm;
stub utype int CoReleaseServerProcess;
stub int CoResumeClassObjects;
stub int CoRevertToSelf;
stub int CoRevokeClassObject -> utype int dwRegister;
stub int CoRevokeInitializeSpy -> utype longlong uliCookie;
stub int CoRevokeMallocSpy;
stub int CoSetCancelObject -> @void pUnk;
stub int CoSetProxyBlanket -> @void pProxy, utype int dwAuthnSvc, utype int dwAuthzSvc, @void pServerPrincName, utype int dwAuthnLevel, utype int dwImpLevel, @void pAuthInfo, utype int dwCapabilities;
stub int CoSuspendClassObjects;
stub int CoSwitchCallContext -> @void pNewObject, @void ppOldObject;
stub @void CoTaskMemAlloc -> utype longlong cb;
stub void CoTaskMemFree -> @void pv;
stub @void CoTaskMemRealloc -> @void pv, utype longlong cb;
stub int CoTestCancel;
stub int CoTreatAsClass -> @void clsidOld, @void clsidNew;
stub void CoUninitialize;
stub int CoUnmarshalHresult -> @void pstm, @int phresult;
stub int CoUnmarshalInterface -> @void pStm, @void riid, @void ppv;
stub int CoWaitForMultipleHandles -> utype int dwFlags, utype int dwTimeout, utype int cHandles, @void pHandles, @int lpdwindex;
stub int CoWaitForMultipleObjects -> utype int dwFlags, utype int dwTimeout, utype int cHandles, @void pHandles, @int lpdwindex;
stub int CreateErrorInfo -> @void pperrinfo;
stub int CreateStreamOnHGlobal -> @void hGlobal, int fDeleteOnRelease, @void ppstm;
stub int DcomChannelSetHResult -> @void pvReserved, @int pulReserved, int appsHR;
stub int FreePropVariantArray -> utype int cVariants, @void rgvars;
stub int GetErrorInfo -> utype int dwReserved, @void pperrinfo;
stub int GetHGlobalFromStream -> @void pstm, @void phglobal;
stub void HACCEL_UserFree -> @int a1, @void a2;
stub @char HACCEL_UserMarshal -> @int a1, @char a2, @void a3;
stub utype int HACCEL_UserSize -> @int a1, utype int a2, @void a3;
stub @char HACCEL_UserUnmarshal -> @int a1, @char a2, @void a3;
stub void HBITMAP_UserFree -> @int a1, @void a2;
stub @char HBITMAP_UserMarshal -> @int a1, @char a2, @void a3;
stub utype int HBITMAP_UserSize -> @int a1, utype int a2, @void a3;
stub @char HBITMAP_UserUnmarshal -> @int a1, @char a2, @void a3;
stub void HDC_UserFree -> @int a1, @void a2;
stub @char HDC_UserMarshal -> @int a1, @char a2, @void a3;
stub utype int HDC_UserSize -> @int a1, utype int a2, @void a3;
stub @char HDC_UserUnmarshal -> @int a1, @char a2, @void a3;
stub void HGLOBAL_UserFree -> @int a1, @void a2;
stub @char HGLOBAL_UserMarshal -> @int a1, @char a2, @void a3;
stub utype int HGLOBAL_UserSize -> @int a1, utype int a2, @void a3;
stub @char HGLOBAL_UserUnmarshal -> @int a1, @char a2, @void a3;
stub void HICON_UserFree -> @int a1, @void a2;
stub @char HICON_UserMarshal -> @int a1, @char a2, @void a3;
stub utype int HICON_UserSize -> @int a1, utype int a2, @void a3;
stub @char HICON_UserUnmarshal -> @int a1, @char a2, @void a3;
stub void HMENU_UserFree -> @int a1, @void a2;
stub @char HMENU_UserMarshal -> @int a1, @char a2, @void a3;
stub utype int HMENU_UserSize -> @int a1, utype int a2, @void a3;
stub @char HMENU_UserUnmarshal -> @int a1, @char a2, @void a3;
stub void HWND_UserFree -> @int a1, @void a2;
stub @char HWND_UserMarshal -> @int a1, @char a2, @void a3;
stub utype int HWND_UserSize -> @int a1, utype int a2, @void a3;
stub @char HWND_UserUnmarshal -> @int a1, @char a2, @void a3;
stub int IIDFromString -> @void lpsz, @void lpiid;
stub int ProgIDFromCLSID -> @void clsid, @void lplpszProgID;
stub int PropVariantClear -> @void pvar;
stub int PropVariantCopy -> @void pvarDest, @void pvarSrc;
stub int SetErrorInfo -> utype int dwReserved, @void perrinfo;
stub int StringFromCLSID -> @void rclsid, @void lplpsz;
stub int StringFromGUID2 -> @void rguid, @void lpsz, int cchMax;
stub int StringFromIID -> @void rclsid, @void lplpsz;

!!! Declared by the headers, but with a type the language cannot write:
!!!   CoGetDefaultContext
!!!   CoGetSystemSecurityPermissions
!!!   RoGetAgileReference

!!! No prototype in the headers this build saw. They are here so the
!!! list is complete; uncomment and give the real signature to use one.
!!! CoGetDefaultContext
!!! CoGetSystemSecurityPermissions
!!! RoGetAgileReference
