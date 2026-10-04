!~
~  native/urlmon.dll.b: the urlmon.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/urlmon.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/urlmon.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `urlmon.dll.b` is what produces `meta/urlmon.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\urlmon.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per urlmon.dll export that the headers declare. The
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
!!! 68 declarations here, 0 kept from the hand-checked list above, 9 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub int AsyncInstallDistributionUnit -> @void szDistUnit, @void szTYPE, @void szExt, utype int dwFileVersionMS, utype int dwFileVersionLS, @void szURL, @void pbc, @void pvReserved, utype int flags;
stub int CoGetClassObjectFromURL -> @void rCLASSID, @void szCODE, utype int dwFileVersionMS, utype int dwFileVersionLS, @void szTYPE, @void pBindCtx, utype int dwClsContext, @void pvReserved, @void riid, @void ppv;
stub int CoInstall -> @void pbc, utype int dwFlags, @void pClassSpec, @void pQuery, @void pszCodeBase;
stub int CoInternetCombineIUri -> @void pBaseUri, @void pRelativeUri, utype int dwCombineFlags, @void ppCombinedUri, utype longlong dwReserved;
stub int CoInternetCombineUrl -> @void pwzBaseUrl, @void pwzRelativeUrl, utype int dwCombineFlags, @void pszResult, utype int cchResult, @int pcchResult, utype int dwReserved;
stub int CoInternetCombineUrlEx -> @void pBaseUri, @void pwzRelativeUrl, utype int dwCombineFlags, @void ppCombinedUri, utype longlong dwReserved;
stub int CoInternetCompareUrl -> @void pwzUrl1, @void pwzUrl2, utype int dwFlags;
stub int CoInternetCreateSecurityManager -> @void pSP, @void ppSM, utype int dwReserved;
stub int CoInternetCreateZoneManager -> @void pSP, @void ppZM, utype int dwReserved;
stub int CoInternetGetProtocolFlags -> @void pwzUrl, @int pdwFlags, utype int dwReserved;
stub int CoInternetGetSession -> utype int dwSessionMode, @void ppIInternetSession, utype int dwReserved;
stub int CoInternetIsFeatureZoneElevationEnabled -> @void szFromURL, @void szToURL, @void pSecMgr, utype int dwFlags;
stub int CompareSecurityIds -> @char pbSecurityId1, utype int dwLen1, @char pbSecurityId2, utype int dwLen2, utype int dwReserved;
stub int CompatFlagsFromClsid -> @void pclsid, @int pdwCompatFlags, @int pdwMiscStatusFlags;
stub int CopyBindInfo -> @void pcbiSrc, @void pbiDest;
stub int CopyStgMedium -> @void pcstgmedSrc, @void pstgmedDest;
stub int CreateAsyncBindCtx -> utype int reserved, @void pBSCb, @void pEFetc, @void ppBC;
stub int CreateAsyncBindCtxEx -> @void pbc, utype int dwOptions, @void pBSCb, @void pEnum, @void ppBC, utype int reserved;
stub int CreateFormatEnumerator -> utype int cfmtetc, @void rgfmtetc, @void ppenumfmtetc;
stub int CreateIUriBuilder -> @void pIUri, utype int dwFlags, utype longlong dwReserved, @void ppIUriBuilder;
stub int CreateURLMoniker -> @void pMkCtx, @void szURL, @void ppmk;
stub int CreateURLMonikerEx -> @void pMkCtx, @void szURL, @void ppmk, utype int dwFlags;
stub int CreateURLMonikerEx2 -> @void pMkCtx, @void pUri, @void ppmk, utype int dwFlags;
stub int CreateUri -> @void pwzURI, utype int dwFlags, utype longlong dwReserved, @void ppURI;
stub int CreateUriFromMultiByteString -> str pszANSIInputUri, utype int dwEncodingFlags, utype int dwCodePage, utype int dwCreateFlags, utype longlong dwReserved, @void ppUri;
stub int CreateUriWithFragment -> @void pwzURI, @void pwzFragment, utype int dwFlags, utype longlong dwReserved, @void ppURI;
stub int FaultInIEFeature -> @void hWnd, @void pClassSpec, @void pQuery, utype int dwFlags;
stub int FindMediaType -> str rgszTypes, @int rgcfTypes;
stub int FindMediaTypeClass -> @void pBC, str szType, @void pclsID, utype int reserved;
stub int FindMimeFromData -> @void pBC, @void pwzUrl, @void pBuffer, utype int cbSize, @void pwzMimeProposed, utype int dwMimeFlags, @void ppwzMimeOut, utype int dwReserved;
stub int GetClassFileOrMime -> @void pBC, @void szFilename, @void pBuffer, utype int cbSize, @void szMime, utype int dwReserved, @void pclsid;
stub int GetClassURL -> @void szURL, @void pClsID;
stub int GetComponentIDFromCLSSPEC -> @void pClassspec, @void ppszComponentID;
stub int GetSoftwareUpdateInfo -> @void szDistUnit, @void psdi;
stub int HlinkGoBack -> @void pUnk;
stub int HlinkGoForward -> @void pUnk;
stub int HlinkNavigateMoniker -> @void pUnk, @void pmkTarget;
stub int HlinkNavigateString -> @void pUnk, @void szTarget;
stub int HlinkSimpleNavigateToMoniker -> @void pmkTarget, @void szLocation, @void szTargetFrameName, @void pUnk, @void pbc, @void a6, utype int grfHLNF, utype int dwReserved;
stub int HlinkSimpleNavigateToString -> @void szTarget, @void szLocation, @void szTargetFrameName, @void pUnk, @void pbc, @void a6, utype int grfHLNF, utype int dwReserved;
stub int IEInstallScope -> @int pdwScope;
stub int IsAsyncMoniker -> @void pmk;
stub int IsLoggingEnabledA -> str pszUrl;
stub int IsLoggingEnabledW -> @void pwszUrl;
stub int IsValidURL -> @void pBC, @void szURL, utype int dwReserved;
stub int MkParseDisplayNameEx -> @void pbc, @void szDisplayName, @int pchEaten, @void ppmk;
stub int ObtainUserAgentString -> utype int dwOption, str pszUAOut, @int cbSize;
stub int RegisterBindStatusCallback -> @void pBC, @void pBSCb, @void ppBSCBPrev, utype int dwReserved;
stub int RegisterFormatEnumerator -> @void pBC, @void pEFetc, utype int reserved;
stub int RegisterMediaTypeClass -> @void pBC, utype int ctypes, @void rgszTypes, @void rgclsID, utype int reserved;
stub int RegisterMediaTypes -> utype int ctypes, @void rgszTypes, @int rgcfTypes;
stub void ReleaseBindInfo -> @void pbindinfo;
stub int RevokeBindStatusCallback -> @void pBC, @void pBSCb;
stub int RevokeFormatEnumerator -> @void pBC, @void pEFetc;
stub int SetSoftwareUpdateAdvertisementState -> @void szDistUnit, utype int dwAdState, utype int dwAdvertisedVersionMS, utype int dwAdvertisedVersionLS;
stub int URLDownloadToCacheFileA -> @void a1, str a2, str a3, utype int a4, utype int a5, @void a6;
stub int URLDownloadToCacheFileW -> @void a1, @void a2, @void a3, utype int a4, utype int a5, @void a6;
stub int URLDownloadToFileA -> @void a1, str a2, str a3, utype int a4, @void a5;
stub int URLDownloadToFileW -> @void a1, @void a2, @void a3, utype int a4, @void a5;
stub int URLOpenBlockingStreamA -> @void a1, str a2, @void a3, utype int a4, @void a5;
stub int URLOpenBlockingStreamW -> @void a1, @void a2, @void a3, utype int a4, @void a5;
stub int URLOpenPullStreamA -> @void a1, str a2, utype int a3, @void a4;
stub int URLOpenPullStreamW -> @void a1, @void a2, utype int a3, @void a4;
stub int URLOpenStreamA -> @void a1, str a2, utype int a3, @void a4;
stub int URLOpenStreamW -> @void a1, @void a2, utype int a3, @void a4;
stub int UrlMkGetSessionOption -> utype int dwOption, @void pBuffer, utype int dwBufferLength, @int pdwBufferLengthOut, utype int dwReserved;
stub int UrlMkSetSessionOption -> utype int dwOption, @void pBuffer, utype int dwBufferLength, utype int dwReserved;
stub int WriteHitLogging -> @void lpLogginginfo;

!!! Declared by the headers, but with a type the language cannot write:
!!!   CoInternetGetSecurityUrl
!!!   CoInternetGetSecurityUrlEx
!!!   CoInternetIsFeatureEnabled
!!!   CoInternetIsFeatureEnabledForIUri
!!!   CoInternetIsFeatureEnabledForUrl
!!!   CoInternetParseIUri
!!!   CoInternetParseUrl
!!!   CoInternetQueryInfo
!!!   CoInternetSetFeatureEnabled

!!! No prototype in the headers this build saw. They are here so the
!!! list is complete; uncomment and give the real signature to use one.
!!! CoInternetGetSecurityUrl
!!! CoInternetGetSecurityUrlEx
!!! CoInternetIsFeatureEnabled
!!! CoInternetIsFeatureEnabledForIUri
!!! CoInternetIsFeatureEnabledForUrl
!!! CoInternetParseIUri
!!! CoInternetParseUrl
!!! CoInternetQueryInfo
!!! CoInternetSetFeatureEnabled
