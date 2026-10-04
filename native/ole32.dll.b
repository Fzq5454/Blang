!~
~  native/ole32.dll.b: the ole32.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/ole32.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/ole32.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `ole32.dll.b` is what produces `meta/ole32.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\ole32.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per ole32.dll export that the headers declare. The
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
!!! 249 declarations here, 0 kept from the hand-checked list above, 3 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub int BindMoniker -> @void pmk, utype int grfOpt, @void iidResult, @void ppvResult;
stub void CLIPFORMAT_UserFree -> @int a1, @int a2;
stub @char CLIPFORMAT_UserMarshal -> @int a1, @char a2, @int a3;
stub utype int CLIPFORMAT_UserSize -> @int a1, utype int a2, @int a3;
stub @char CLIPFORMAT_UserUnmarshal -> @int a1, @char a2, @int a3;
stub int CLSIDFromProgID -> @void lpszProgID, @void lpclsid;
stub int CLSIDFromProgIDEx -> @void lpszProgID, @void lpclsid;
stub int CLSIDFromString -> @void lpsz, @void pclsid;
stub utype int CoAddRefServerProcess;
stub int CoAllowSetForegroundWindow -> @void pUnk, @void lpvReserved;
stub int CoAllowUnmarshalerCLSID -> @void clsid;
stub utype int CoBuildVersion;
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
stub int CoDosDateTimeToFileTime -> utype int nDosDate, utype int nDosTime, @void lpFileTime;
stub int CoEnableCallCancellation -> @void pReserved;
stub int CoFileTimeNow -> @void lpFileTime;
stub int CoFileTimeToDosDateTime -> @void lpFileTime, @int lpDosDate, @int lpDosTime;
stub void CoFreeAllLibraries;
stub void CoFreeLibrary -> @void hInst;
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
stub int CoGetObject -> @void pszName, @void pBindOptions, @void riid, @void ppv;
stub int CoGetObjectContext -> @void riid, @void ppv;
stub int CoGetPSClsid -> @void riid, @void pClsid;
stub int CoGetStandardMarshal -> @void riid, @void pUnk, utype int dwDestContext, @void pvDestContext, utype int mshlflags, @void ppMarshal;
stub int CoGetStdMarshalEx -> @void pUnkOuter, utype int smexflags, @void ppUnkInner;
stub int CoGetTreatAsClass -> @void clsidOld, @void pClsidNew;
stub int CoImpersonateClient;
stub int CoIncrementMTAUsage -> @void pCookie;
stub int CoInitialize -> @void pvReserved;
stub int CoInitializeEx -> @void pvReserved, utype int dwCoInit;
stub int CoInitializeSecurity -> @void pSecDesc, int cAuthSvc, @void asAuthSvc, @void pReserved1, utype int dwAuthnLevel, utype int dwImpLevel, @void pAuthList, utype int dwCapabilities, @void pReserved3;
stub int CoInstall -> @void pbc, utype int dwFlags, @void pClassSpec, @void pQuery, @void pszCodeBase;
stub int CoInvalidateRemoteMachineBindings -> @void pszMachineName;
stub int CoIsHandlerConnected -> @void pUnk;
stub int CoIsOle1Class -> @void rclsid;
stub @void CoLoadLibrary -> @void lpszLibName, int bAutoFree;
stub int CoLockObjectExternal -> @void pUnk, int fLock, int fLastUnlockReleases;
stub int CoMarshalHresult -> @void pstm, int hresult;
stub int CoMarshalInterThreadInterfaceInStream -> @void riid, @void pUnk, @void ppStm;
stub int CoMarshalInterface -> @void pStm, @void riid, @void pUnk, utype int dwDestContext, @void pvDestContext, utype int mshlflags;
stub int CoQueryAuthenticationServices -> @int pcAuthSvc, @void asAuthSvc;
stub int CoQueryClientBlanket -> @int pAuthnSvc, @int pAuthzSvc, @void pServerPrincName, @int pAuthnLevel, @int pImpLevel, @void pPrivs, @int pCapabilities;
stub int CoQueryProxyBlanket -> @void pProxy, @int pwAuthnSvc, @int pAuthzSvc, @void pServerPrincName, @int pAuthnLevel, @int pImpLevel, @void pAuthInfo, @int pCapabilites;
stub int CoRegisterChannelHook -> @void ExtensionUuid, @void pChannelHook;
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
stub int CreateAntiMoniker -> @void ppmk;
stub int CreateBindCtx -> utype int reserved, @void ppbc;
stub int CreateClassMoniker -> @void rclsid, @void ppmk;
stub int CreateDataAdviseHolder -> @void ppDAHolder;
stub int CreateDataCache -> @void pUnkOuter, @void rclsid, @void iid, @void ppv;
stub int CreateErrorInfo -> @void pperrinfo;
stub int CreateFileMoniker -> @void lpszPathName, @void ppmk;
stub int CreateGenericComposite -> @void pmkFirst, @void pmkRest, @void ppmkComposite;
stub int CreateILockBytesOnHGlobal -> @void hGlobal, int fDeleteOnRelease, @void pplkbyt;
stub int CreateItemMoniker -> @void lpszDelim, @void lpszItem, @void ppmk;
stub int CreateObjrefMoniker -> @void punk, @void ppmk;
stub int CreateOleAdviseHolder -> @void ppOAHolder;
stub int CreatePointerMoniker -> @void punk, @void ppmk;
stub int CreateStdProgressIndicator -> @void hwndParent, @void pszTitle, @void pIbscCaller, @void ppIbsc;
stub int CreateStreamOnHGlobal -> @void hGlobal, int fDeleteOnRelease, @void ppstm;
stub int DcomChannelSetHResult -> @void pvReserved, @int pulReserved, int appsHR;
stub int DoDragDrop -> @void pDataObj, @void pDropSource, utype int dwOKEffects, @int pdwEffect;
stub int FmtIdToPropStgName -> @void pfmtid, @void oszName;
stub int FreePropVariantArray -> utype int cVariants, @void rgvars;
stub int GetClassFile -> @void szFilename, @void pclsid;
stub int GetConvertStg -> @void pStg;
stub int GetErrorInfo -> utype int dwReserved, @void pperrinfo;
stub int GetHGlobalFromILockBytes -> @void plkbyt, @void phglobal;
stub int GetHGlobalFromStream -> @void pstm, @void phglobal;
stub int GetRunningObjectTable -> utype int reserved, @void pprot;
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
stub int IsAccelerator -> @void hAccel, int cAccelEntries, @void lpMsg, @int lpwCmd;
stub int MkParseDisplayName -> @void pbc, @void szUserName, @int pchEaten, @void ppmk;
stub int MonikerCommonPrefixWith -> @void pmkThis, @void pmkOther, @void ppmkCommon;
stub int MonikerRelativePathTo -> @void pmkSrc, @void pmkDest, @void ppmkRelPath, int dwReserved;
stub utype int OleBuildVersion;
stub int OleConvertIStorageToOLESTREAM -> @void pstg, @void lpolestream;
stub int OleConvertIStorageToOLESTREAMEx -> @void pstg, utype int cfFormat, int lWidth, int lHeight, utype int dwSize, @void pmedium, @void polestm;
stub int OleConvertOLESTREAMToIStorage -> @void lpolestream, @void pstg, @void ptd;
stub int OleConvertOLESTREAMToIStorageEx -> @void polestm, @void pstg, @int pcfFormat, @int plwWidth, @int plHeight, @int pdwSize, @void pmedium;
stub int OleCreate -> @void rclsid, @void riid, utype int renderopt, @void pFormatEtc, @void pClientSite, @void pStg, @void ppvObj;
stub int OleCreateDefaultHandler -> @void clsid, @void pUnkOuter, @void riid, @void lplpObj;
stub int OleCreateEmbeddingHelper -> @void clsid, @void pUnkOuter, utype int flags, @void pCF, @void riid, @void lplpObj;
stub int OleCreateEx -> @void rclsid, @void riid, utype int dwFlags, utype int renderopt, utype int cFormats, @int rgAdvf, @void rgFormatEtc, @void lpAdviseSink, @int rgdwConnection, @void pClientSite, @void pStg, @void ppvObj;
stub int OleCreateFromData -> @void pSrcDataObj, @void riid, utype int renderopt, @void pFormatEtc, @void pClientSite, @void pStg, @void ppvObj;
stub int OleCreateFromDataEx -> @void pSrcDataObj, @void riid, utype int dwFlags, utype int renderopt, utype int cFormats, @int rgAdvf, @void rgFormatEtc, @void lpAdviseSink, @int rgdwConnection, @void pClientSite, @void pStg, @void ppvObj;
stub int OleCreateFromFile -> @void rclsid, @void lpszFileName, @void riid, utype int renderopt, @void lpFormatEtc, @void pClientSite, @void pStg, @void ppvObj;
stub int OleCreateFromFileEx -> @void rclsid, @void lpszFileName, @void riid, utype int dwFlags, utype int renderopt, utype int cFormats, @int rgAdvf, @void rgFormatEtc, @void lpAdviseSink, @int rgdwConnection, @void pClientSite, @void pStg, @void ppvObj;
stub int OleCreateLink -> @void pmkLinkSrc, @void riid, utype int renderopt, @void lpFormatEtc, @void pClientSite, @void pStg, @void ppvObj;
stub int OleCreateLinkEx -> @void pmkLinkSrc, @void riid, utype int dwFlags, utype int renderopt, utype int cFormats, @int rgAdvf, @void rgFormatEtc, @void lpAdviseSink, @int rgdwConnection, @void pClientSite, @void pStg, @void ppvObj;
stub int OleCreateLinkFromData -> @void pSrcDataObj, @void riid, utype int renderopt, @void pFormatEtc, @void pClientSite, @void pStg, @void ppvObj;
stub int OleCreateLinkFromDataEx -> @void pSrcDataObj, @void riid, utype int dwFlags, utype int renderopt, utype int cFormats, @int rgAdvf, @void rgFormatEtc, @void lpAdviseSink, @int rgdwConnection, @void pClientSite, @void pStg, @void ppvObj;
stub int OleCreateLinkToFile -> @void lpszFileName, @void riid, utype int renderopt, @void lpFormatEtc, @void pClientSite, @void pStg, @void ppvObj;
stub int OleCreateLinkToFileEx -> @void lpszFileName, @void riid, utype int dwFlags, utype int renderopt, utype int cFormats, @int rgAdvf, @void rgFormatEtc, @void lpAdviseSink, @int rgdwConnection, @void pClientSite, @void pStg, @void ppvObj;
stub @void OleCreateMenuDescriptor -> @void hmenuCombined, @void lpMenuWidths;
stub int OleCreateStaticFromData -> @void pSrcDataObj, @void iid, utype int renderopt, @void pFormatEtc, @void pClientSite, @void pStg, @void ppvObj;
stub int OleDestroyMenuDescriptor -> @void holemenu;
stub int OleDoAutoConvert -> @void pStg, @void pClsidNew;
stub int OleDraw -> @void pUnknown, utype int dwAspect, @void hdcDraw, @void lprcBounds;
stub @void OleDuplicateData -> @void hSrc, utype int cfFormat, utype int uiFlags;
stub int OleFlushClipboard;
stub int OleGetAutoConvert -> @void clsidOld, @void pClsidNew;
stub int OleGetClipboard -> @void ppDataObj;
stub @void OleGetIconOfClass -> @void rclsid, @void lpszLabel, int fUseTypeAsLabel;
stub @void OleGetIconOfFile -> @void lpszPath, int fUseFileAsLabel;
stub int OleInitialize -> @void pvReserved;
stub int OleIsCurrentClipboard -> @void pDataObj;
stub int OleIsRunning -> @void pObject;
stub int OleLoad -> @void pStg, @void riid, @void pClientSite, @void ppvObj;
stub int OleLoadFromStream -> @void pStm, @void iidInterface, @void ppvObj;
stub int OleLockRunning -> @void pUnknown, int fLock, int fLastUnlockCloses;
stub @void OleMetafilePictFromIconAndLabel -> @void hIcon, @void lpszLabel, @void lpszSourceFile, utype int iIconIndex;
stub int OleNoteObjectVisible -> @void pUnknown, int fVisible;
stub int OleQueryCreateFromData -> @void pSrcDataObject;
stub int OleQueryLinkFromData -> @void pSrcDataObject;
stub int OleRegEnumFormatEtc -> @void clsid, utype int dwDirection, @void ppenum;
stub int OleRegEnumVerbs -> @void clsid, @void ppenum;
stub int OleRegGetMiscStatus -> @void clsid, utype int dwAspect, @int pdwStatus;
stub int OleRegGetUserType -> @void clsid, utype int dwFormOfType, @void pszUserType;
stub int OleRun -> @void pUnknown;
stub int OleSave -> @void pPS, @void pStg, int fSameAsLoad;
stub int OleSaveToStream -> @void pPStm, @void pStm;
stub int OleSetAutoConvert -> @void clsidOld, @void clsidNew;
stub int OleSetClipboard -> @void pDataObj;
stub int OleSetContainedObject -> @void pUnknown, int fContained;
stub int OleSetMenuDescriptor -> @void holemenu, @void hwndFrame, @void hwndActiveObject, @void lpFrame, @void lpActiveObj;
stub int OleTranslateAccelerator -> @void lpFrame, @void lpFrameInfo, @void lpmsg;
stub void OleUninitialize;
stub int ProgIDFromCLSID -> @void clsid, @void lplpszProgID;
stub int PropStgNameToFmtId -> @void oszName, @void pfmtid;
stub int PropVariantClear -> @void pvar;
stub int PropVariantCopy -> @void pvarDest, @void pvarSrc;
stub int ReadClassStg -> @void pStg, @void pclsid;
stub int ReadClassStm -> @void pStm, @void pclsid;
stub int ReadFmtUserTypeStg -> @void pstg, @int pcf, @void lplpszUserType;
stub int RegisterDragDrop -> @void hwnd, @void pDropTarget;
stub void ReleaseStgMedium -> @void a1;
stub int RevokeDragDrop -> @void hwnd;
stub void SNB_UserFree -> @int a1, @void a2;
stub @char SNB_UserMarshal -> @int a1, @char a2, @void a3;
stub utype int SNB_UserSize -> @int a1, utype int a2, @void a3;
stub @char SNB_UserUnmarshal -> @int a1, @char a2, @void a3;
stub void STGMEDIUM_UserFree -> @int a1, @void a2;
stub @char STGMEDIUM_UserMarshal -> @int a1, @char a2, @void a3;
stub utype int STGMEDIUM_UserSize -> @int a1, utype int a2, @void a3;
stub @char STGMEDIUM_UserUnmarshal -> @int a1, @char a2, @void a3;
stub int SetConvertStg -> @void pStg, int fConvert;
stub int SetErrorInfo -> utype int dwReserved, @void perrinfo;
stub @void StgConvertVariantToProperty -> @void pvar, utype int CodePage, @void pprop, @int pcb, utype int pid, utype char fReserved, @int pcIndirect;
stub int StgCreateDocfile -> @void pwcsName, utype int grfMode, utype int reserved, @void ppstgOpen;
stub int StgCreateDocfileOnILockBytes -> @void plkbyt, utype int grfMode, utype int reserved, @void ppstgOpen;
stub int StgCreatePropSetStg -> @void pStorage, utype int dwReserved, @void ppPropSetStg;
stub int StgCreatePropStg -> @void pUnk, @void fmtid, @void pclsid, utype int grfFlags, utype int dwReserved, @void ppPropStg;
stub int StgCreateStorageEx -> @void pwcsName, utype int grfMode, utype int stgfmt, utype int grfAttrs, @void pStgOptions, @void pSecurityDescriptor, @void riid, @void ppObjectOpen;
stub int StgGetIFillLockBytesOnFile -> @void pwcsName, @void ppflb;
stub int StgGetIFillLockBytesOnILockBytes -> @void pilb, @void ppflb;
stub int StgIsStorageFile -> @void pwcsName;
stub int StgIsStorageILockBytes -> @void plkbyt;
stub int StgOpenAsyncDocfileOnIFillLockBytes -> @void pflb, utype int grfMode, utype int asyncFlags, @void ppstgOpen;
stub int StgOpenPropStg -> @void pUnk, @void fmtid, utype int grfFlags, utype int dwReserved, @void ppPropStg;
stub int StgOpenStorage -> @void pwcsName, @void pstgPriority, utype int grfMode, @void snbExclude, utype int reserved, @void ppstgOpen;
stub int StgOpenStorageEx -> @void pwcsName, utype int grfMode, utype int stgfmt, utype int grfAttrs, @void pStgOptions, @void pSecurityDescriptor, @void riid, @void ppObjectOpen;
stub int StgOpenStorageOnILockBytes -> @void plkbyt, @void pstgPriority, utype int grfMode, @void snbExclude, utype int reserved, @void ppstgOpen;
stub int StgSetTimes -> @void lpszName, @void pctime, @void patime, @void pmtime;
stub int StringFromCLSID -> @void rclsid, @void lplpsz;
stub int StringFromGUID2 -> @void rguid, @void lpsz, int cchMax;
stub int StringFromIID -> @void rclsid, @void lplpsz;
stub int WriteClassStg -> @void pStg, @void rclsid;
stub int WriteClassStm -> @void pStm, @void rclsid;
stub int WriteFmtUserTypeStg -> @void pstg, utype int cf, @void lpszUserType;

!!! Declared by the headers, but with a type the language cannot write:
!!!   CoGetDefaultContext
!!!   CoGetSystemSecurityPermissions
!!!   RoGetAgileReference

!!! No prototype in the headers this build saw. They are here so the
!!! list is complete; uncomment and give the real signature to use one.
!!! CoGetDefaultContext
!!! CoGetSystemSecurityPermissions
!!! RoGetAgileReference
