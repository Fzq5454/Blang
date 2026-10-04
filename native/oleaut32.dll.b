!~
~  native/oleaut32.dll.b: the oleaut32.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/oleaut32.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/oleaut32.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `oleaut32.dll.b` is what produces `meta/oleaut32.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\oleaut32.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per oleaut32.dll export that the headers declare. The
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
!!! 343 declarations here, 0 kept from the hand-checked list above, 34 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub void BSTR_UserFree -> @int a1, @void a2;
stub @char BSTR_UserMarshal -> @int a1, @char a2, @void a3;
stub utype int BSTR_UserSize -> @int a1, utype int a2, @void a3;
stub @char BSTR_UserUnmarshal -> @int a1, @char a2, @void a3;
stub int BstrFromVector -> @void psa, @void pbstr;
stub void ClearCustData -> @void pCustData;
stub int CreateDispTypeInfo -> @void pidata, utype int lcid, @void pptinfo;
stub int CreateErrorInfo -> @void pperrinfo;
stub int CreateStdDispatch -> @void punkOuter, @void pvThis, @void ptinfo, @void ppunkStdDisp;
stub int DispGetIDsOfNames -> @void ptinfo, @void rgszNames, utype int cNames, @int rgdispid;
stub int DispGetParam -> @void pdispparams, utype int position, utype int vtTarg, @void pvarResult, @int puArgErr;
stub int DispInvoke -> @void _this, @void ptinfo, int dispidMember, utype int wFlags, @void pparams, @void pvarResult, @void pexcepinfo, @int puArgErr;
stub int DosDateTimeToVariantTime -> utype int wDosDate, utype int wDosTime, @float pvtime;
stub int GetActiveObject -> @void rclsid, @void pvReserved, @void ppunk;
stub int GetAltMonthNames -> utype int lcid, @void prgp;
stub int GetErrorInfo -> utype int dwReserved, @void pperrinfo;
stub int GetRecordInfoFromGuids -> @void rGuidTypeLib, utype int uVerMajor, utype int uVerMinor, utype int lcid, @void rGuidTypeInfo, @void ppRecInfo;
stub int GetRecordInfoFromTypeInfo -> @void pTypeInfo, @void ppRecInfo;
stub void HWND_UserFree -> @int a1, @void a2;
stub @char HWND_UserMarshal -> @int a1, @char a2, @void a3;
stub utype int HWND_UserSize -> @int a1, utype int a2, @void a3;
stub @char HWND_UserUnmarshal -> @int a1, @char a2, @void a3;
stub void LPSAFEARRAY_UserFree -> @int a1, @void a2;
stub @char LPSAFEARRAY_UserMarshal -> @int a1, @char a2, @void a3;
stub utype int LPSAFEARRAY_UserSize -> @int a1, utype int a2, @void a3;
stub @char LPSAFEARRAY_UserUnmarshal -> @int a1, @char a2, @void a3;
stub int LoadRegTypeLib -> @void rguid, utype int wVerMajor, utype int wVerMinor, utype int lcid, @void pptlib;
stub int LoadTypeLib -> @void szFile, @void pptlib;
stub utype int OaBuildVersion;
stub int QueryPathOfRegTypeLib -> @void guid, utype int wMaj, utype int wMin, utype int lcid, @void lpbstrPathName;
stub int RegisterActiveObject -> @void punk, @void rclsid, utype int dwFlags, @int pdwRegister;
stub int RegisterTypeLib -> @void ptlib, @void szFullPath, @void szHelpDir;
stub int RevokeActiveObject -> utype int dwRegister, @void pvReserved;
stub int SafeArrayAccessData -> @void psa, @void ppvData;
stub int SafeArrayAllocData -> @void psa;
stub int SafeArrayAllocDescriptor -> utype int cDims, @void ppsaOut;
stub int SafeArrayAllocDescriptorEx -> utype int vt, utype int cDims, @void ppsaOut;
stub int SafeArrayCopy -> @void psa, @void ppsaOut;
stub int SafeArrayCopyData -> @void psaSource, @void psaTarget;
stub @void SafeArrayCreate -> utype int vt, utype int cDims, @void rgsabound;
stub @void SafeArrayCreateEx -> utype int vt, utype int cDims, @void rgsabound, @void pvExtra;
stub @void SafeArrayCreateVector -> utype int vt, int lLbound, utype int cElements;
stub @void SafeArrayCreateVectorEx -> utype int vt, int lLbound, utype int cElements, @void pvExtra;
stub int SafeArrayDestroy -> @void psa;
stub int SafeArrayDestroyData -> @void psa;
stub int SafeArrayDestroyDescriptor -> @void psa;
stub utype int SafeArrayGetDim -> @void psa;
stub int SafeArrayGetElement -> @void psa, @int rgIndices, @void pv;
stub utype int SafeArrayGetElemsize -> @void psa;
stub int SafeArrayGetIID -> @void psa, @void pguid;
stub int SafeArrayGetLBound -> @void psa, utype int nDim, @int plLbound;
stub int SafeArrayGetRecordInfo -> @void psa, @void prinfo;
stub int SafeArrayGetUBound -> @void psa, utype int nDim, @int plUbound;
stub int SafeArrayGetVartype -> @void psa, @int pvt;
stub int SafeArrayLock -> @void psa;
stub int SafeArrayPtrOfIndex -> @void psa, @int rgIndices, @void ppvData;
stub int SafeArrayPutElement -> @void psa, @int rgIndices, @void pv;
stub int SafeArrayRedim -> @void psa, @void psaboundNew;
stub int SafeArraySetIID -> @void psa, @void guid;
stub int SafeArraySetRecordInfo -> @void psa, @void prinfo;
stub int SafeArrayUnaccessData -> @void psa;
stub int SafeArrayUnlock -> @void psa;
stub int SetErrorInfo -> utype int dwReserved, @void perrinfo;
stub @void SysAllocString -> @void OLECHAR;
stub @void SysAllocStringByteLen -> str psz, utype int len;
stub @void SysAllocStringLen -> @void OLECHAR, utype int a2;
stub void SysFreeString -> @void a1;
stub int SysReAllocString -> @void a1, @void OLECHAR;
stub int SysReAllocStringLen -> @void a1, @void OLECHAR, utype int a3;
stub utype int SysStringByteLen -> @void bstr;
stub utype int SysStringLen -> @void a1;
stub int SystemTimeToVariantTime -> @void lpSystemTime, @float pvtime;
stub void VARIANT_UserFree -> @int a1, @void a2;
stub @char VARIANT_UserMarshal -> @int a1, @char a2, @void a3;
stub utype int VARIANT_UserSize -> @int a1, utype int a2, @void a3;
stub @char VARIANT_UserUnmarshal -> @int a1, @char a2, @void a3;
stub int VarAbs -> @void pvarIn, @void pvarResult;
stub int VarAdd -> @void pvarLeft, @void pvarRight, @void pvarResult;
stub int VarAnd -> @void pvarLeft, @void pvarRight, @void pvarResult;
stub int VarBoolFromDate -> float dateIn, @int pboolOut;
stub int VarBoolFromDec -> @void pdecIn, @int pboolOut;
stub int VarBoolFromDisp -> @void pdispIn, utype int lcid, @int pboolOut;
stub int VarBoolFromI1 -> char cIn, @int pboolOut;
stub int VarBoolFromI2 -> int sIn, @int pboolOut;
stub int VarBoolFromI4 -> int lIn, @int pboolOut;
stub int VarBoolFromI8 -> longlong i64In, @int pboolOut;
stub int VarBoolFromR4 -> float fltIn, @int pboolOut;
stub int VarBoolFromR8 -> float dblIn, @int pboolOut;
stub int VarBoolFromStr -> @void strIn, utype int lcid, utype int dwFlags, @int pboolOut;
stub int VarBoolFromUI1 -> utype char bIn, @int pboolOut;
stub int VarBoolFromUI2 -> utype int uiIn, @int pboolOut;
stub int VarBoolFromUI4 -> utype int ulIn, @int pboolOut;
stub int VarBoolFromUI8 -> utype longlong i64In, @int pboolOut;
stub int VarBstrCat -> @void bstrLeft, @void bstrRight, @void pbstrResult;
stub int VarBstrCmp -> @void bstrLeft, @void bstrRight, utype int lcid, utype int dwFlags;
stub int VarBstrFromBool -> int boolIn, utype int lcid, utype int dwFlags, @void pbstrOut;
stub int VarBstrFromDate -> float dateIn, utype int lcid, utype int dwFlags, @void pbstrOut;
stub int VarBstrFromDec -> @void pdecIn, utype int lcid, utype int dwFlags, @void pbstrOut;
stub int VarBstrFromDisp -> @void pdispIn, utype int lcid, utype int dwFlags, @void pbstrOut;
stub int VarBstrFromI1 -> char cIn, utype int lcid, utype int dwFlags, @void pbstrOut;
stub int VarBstrFromI2 -> int iVal, utype int lcid, utype int dwFlags, @void pbstrOut;
stub int VarBstrFromI4 -> int lIn, utype int lcid, utype int dwFlags, @void pbstrOut;
stub int VarBstrFromI8 -> longlong i64In, utype int lcid, utype int dwFlags, @void pbstrOut;
stub int VarBstrFromR4 -> float fltIn, utype int lcid, utype int dwFlags, @void pbstrOut;
stub int VarBstrFromR8 -> float dblIn, utype int lcid, utype int dwFlags, @void pbstrOut;
stub int VarBstrFromUI1 -> utype char bVal, utype int lcid, utype int dwFlags, @void pbstrOut;
stub int VarBstrFromUI2 -> utype int uiIn, utype int lcid, utype int dwFlags, @void pbstrOut;
stub int VarBstrFromUI4 -> utype int ulIn, utype int lcid, utype int dwFlags, @void pbstrOut;
stub int VarBstrFromUI8 -> utype longlong ui64In, utype int lcid, utype int dwFlags, @void pbstrOut;
stub int VarCat -> @void pvarLeft, @void pvarRight, @void pvarResult;
stub int VarCyFromBool -> int boolIn, @void pcyOut;
stub int VarCyFromDate -> float dateIn, @void pcyOut;
stub int VarCyFromDec -> @void pdecIn, @void pcyOut;
stub int VarCyFromDisp -> @void pdispIn, utype int lcid, @void pcyOut;
stub int VarCyFromI1 -> char cIn, @void pcyOut;
stub int VarCyFromI2 -> int sIn, @void pcyOut;
stub int VarCyFromI4 -> int lIn, @void pcyOut;
stub int VarCyFromI8 -> longlong i64In, @void pcyOut;
stub int VarCyFromR4 -> float fltIn, @void pcyOut;
stub int VarCyFromR8 -> float dblIn, @void pcyOut;
stub int VarCyFromStr -> @void strIn, utype int lcid, utype int dwFlags, @void pcyOut;
stub int VarCyFromUI1 -> utype char bIn, @void pcyOut;
stub int VarCyFromUI2 -> utype int uiIn, @void pcyOut;
stub int VarCyFromUI4 -> utype int ulIn, @void pcyOut;
stub int VarCyFromUI8 -> utype longlong ui64In, @void pcyOut;
stub int VarDateFromBool -> int boolIn, @float pdateOut;
stub int VarDateFromDec -> @void pdecIn, @float pdateOut;
stub int VarDateFromDisp -> @void pdispIn, utype int lcid, @float pdateOut;
stub int VarDateFromI1 -> char cIn, @float pdateOut;
stub int VarDateFromI2 -> int sIn, @float pdateOut;
stub int VarDateFromI4 -> int lIn, @float pdateOut;
stub int VarDateFromI8 -> longlong i64In, @float pdateOut;
stub int VarDateFromR4 -> float fltIn, @float pdateOut;
stub int VarDateFromR8 -> float dblIn, @float pdateOut;
stub int VarDateFromStr -> @void strIn, utype int lcid, utype int dwFlags, @float pdateOut;
stub int VarDateFromUI1 -> utype char bIn, @float pdateOut;
stub int VarDateFromUI2 -> utype int uiIn, @float pdateOut;
stub int VarDateFromUI4 -> utype int ulIn, @float pdateOut;
stub int VarDateFromUI8 -> utype longlong ui64In, @float pdateOut;
stub int VarDateFromUdate -> @void pudateIn, utype int dwFlags, @float pdateOut;
stub int VarDateFromUdateEx -> @void pudateIn, utype int lcid, utype int dwFlags, @float pdateOut;
stub int VarDecAbs -> @void pdecIn, @void pdecResult;
stub int VarDecAdd -> @void pdecLeft, @void pdecRight, @void pdecResult;
stub int VarDecCmp -> @void pdecLeft, @void pdecRight;
stub int VarDecCmpR8 -> @void pdecLeft, float dblRight;
stub int VarDecDiv -> @void pdecLeft, @void pdecRight, @void pdecResult;
stub int VarDecFix -> @void pdecIn, @void pdecResult;
stub int VarDecFromBool -> int boolIn, @void pdecOut;
stub int VarDecFromDate -> float dateIn, @void pdecOut;
stub int VarDecFromDisp -> @void pdispIn, utype int lcid, @void pdecOut;
stub int VarDecFromI1 -> char cIn, @void pdecOut;
stub int VarDecFromI2 -> int uiIn, @void pdecOut;
stub int VarDecFromI4 -> int lIn, @void pdecOut;
stub int VarDecFromI8 -> longlong i64In, @void pdecOut;
stub int VarDecFromR4 -> float fltIn, @void pdecOut;
stub int VarDecFromR8 -> float dblIn, @void pdecOut;
stub int VarDecFromStr -> @void strIn, utype int lcid, utype int dwFlags, @void pdecOut;
stub int VarDecFromUI1 -> utype char bIn, @void pdecOut;
stub int VarDecFromUI2 -> utype int uiIn, @void pdecOut;
stub int VarDecFromUI4 -> utype int ulIn, @void pdecOut;
stub int VarDecFromUI8 -> utype longlong ui64In, @void pdecOut;
stub int VarDecInt -> @void pdecIn, @void pdecResult;
stub int VarDecMul -> @void pdecLeft, @void pdecRight, @void pdecResult;
stub int VarDecNeg -> @void pdecIn, @void pdecResult;
stub int VarDecRound -> @void pdecIn, int cDecimals, @void pdecResult;
stub int VarDecSub -> @void pdecLeft, @void pdecRight, @void pdecResult;
stub int VarDiv -> @void pvarLeft, @void pvarRight, @void pvarResult;
stub int VarEqv -> @void pvarLeft, @void pvarRight, @void pvarResult;
stub int VarFix -> @void pvarIn, @void pvarResult;
stub int VarFormat -> @void pvarIn, @void pstrFormat, int iFirstDay, int iFirstWeek, utype int dwFlags, @void pbstrOut;
stub int VarFormatCurrency -> @void pvarIn, int iNumDig, int iIncLead, int iUseParens, int iGroup, utype int dwFlags, @void pbstrOut;
stub int VarFormatDateTime -> @void pvarIn, int iNamedFormat, utype int dwFlags, @void pbstrOut;
stub int VarFormatFromTokens -> @void pvarIn, @void pstrFormat, @char pbTokCur, utype int dwFlags, @void pbstrOut, utype int lcid;
stub int VarFormatNumber -> @void pvarIn, int iNumDig, int iIncLead, int iUseParens, int iGroup, utype int dwFlags, @void pbstrOut;
stub int VarFormatPercent -> @void pvarIn, int iNumDig, int iIncLead, int iUseParens, int iGroup, utype int dwFlags, @void pbstrOut;
stub int VarI1FromBool -> int boolIn, str pcOut;
stub int VarI1FromDate -> float dateIn, str pcOut;
stub int VarI1FromDec -> @void pdecIn, str pcOut;
stub int VarI1FromDisp -> @void pdispIn, utype int lcid, str pcOut;
stub int VarI1FromI2 -> int uiIn, str pcOut;
stub int VarI1FromI4 -> int lIn, str pcOut;
stub int VarI1FromI8 -> longlong i64In, str pcOut;
stub int VarI1FromR4 -> float fltIn, str pcOut;
stub int VarI1FromR8 -> float dblIn, str pcOut;
stub int VarI1FromStr -> @void strIn, utype int lcid, utype int dwFlags, str pcOut;
stub int VarI1FromUI1 -> utype char bIn, str pcOut;
stub int VarI1FromUI2 -> utype int uiIn, str pcOut;
stub int VarI1FromUI4 -> utype int ulIn, str pcOut;
stub int VarI1FromUI8 -> utype longlong i64In, str pcOut;
stub int VarI2FromBool -> int boolIn, @int psOut;
stub int VarI2FromDate -> float dateIn, @int psOut;
stub int VarI2FromDec -> @void pdecIn, @int psOut;
stub int VarI2FromDisp -> @void pdispIn, utype int lcid, @int psOut;
stub int VarI2FromI1 -> char cIn, @int psOut;
stub int VarI2FromI4 -> int lIn, @int psOut;
stub int VarI2FromI8 -> longlong i64In, @int psOut;
stub int VarI2FromR4 -> float fltIn, @int psOut;
stub int VarI2FromR8 -> float dblIn, @int psOut;
stub int VarI2FromStr -> @void strIn, utype int lcid, utype int dwFlags, @int psOut;
stub int VarI2FromUI1 -> utype char bIn, @int psOut;
stub int VarI2FromUI2 -> utype int uiIn, @int psOut;
stub int VarI2FromUI4 -> utype int ulIn, @int psOut;
stub int VarI2FromUI8 -> utype longlong ui64In, @int psOut;
stub int VarI4FromBool -> int boolIn, @int plOut;
stub int VarI4FromDate -> float dateIn, @int plOut;
stub int VarI4FromDec -> @void pdecIn, @int plOut;
stub int VarI4FromDisp -> @void pdispIn, utype int lcid, @int plOut;
stub int VarI4FromI1 -> char cIn, @int plOut;
stub int VarI4FromI2 -> int sIn, @int plOut;
stub int VarI4FromI8 -> longlong i64In, @int plOut;
stub int VarI4FromR4 -> float fltIn, @int plOut;
stub int VarI4FromR8 -> float dblIn, @int plOut;
stub int VarI4FromStr -> @void strIn, utype int lcid, utype int dwFlags, @int plOut;
stub int VarI4FromUI1 -> utype char bIn, @int plOut;
stub int VarI4FromUI2 -> utype int uiIn, @int plOut;
stub int VarI4FromUI4 -> utype int ulIn, @int plOut;
stub int VarI4FromUI8 -> utype longlong ui64In, @int plOut;
stub int VarI8FromBool -> int boolIn, @longlong pi64Out;
stub int VarI8FromDate -> float dateIn, @longlong pi64Out;
stub int VarI8FromDec -> @void pdecIn, @longlong pi64Out;
stub int VarI8FromDisp -> @void pdispIn, utype int lcid, @longlong pi64Out;
stub int VarI8FromI1 -> char cIn, @longlong pi64Out;
stub int VarI8FromI2 -> int sIn, @longlong pi64Out;
stub int VarI8FromR4 -> float fltIn, @longlong pi64Out;
stub int VarI8FromR8 -> float dblIn, @longlong pi64Out;
stub int VarI8FromStr -> @void strIn, utype int lcid, utype int dwFlags, @longlong pi64Out;
stub int VarI8FromUI1 -> utype char bIn, @longlong pi64Out;
stub int VarI8FromUI2 -> utype int uiIn, @longlong pi64Out;
stub int VarI8FromUI4 -> utype int ulIn, @longlong pi64Out;
stub int VarI8FromUI8 -> utype longlong ui64In, @longlong pi64Out;
stub int VarIdiv -> @void pvarLeft, @void pvarRight, @void pvarResult;
stub int VarImp -> @void pvarLeft, @void pvarRight, @void pvarResult;
stub int VarInt -> @void pvarIn, @void pvarResult;
stub int VarMod -> @void pvarLeft, @void pvarRight, @void pvarResult;
stub int VarMonthName -> int iMonth, int fAbbrev, utype int dwFlags, @void pbstrOut;
stub int VarMul -> @void pvarLeft, @void pvarRight, @void pvarResult;
stub int VarNeg -> @void pvarIn, @void pvarResult;
stub int VarNot -> @void pvarIn, @void pvarResult;
stub int VarNumFromParseNum -> @void pnumprs, @char rgbDig, utype int dwVtBits, @void pvar;
stub int VarOr -> @void pvarLeft, @void pvarRight, @void pvarResult;
stub int VarParseNumFromStr -> @void strIn, utype int lcid, utype int dwFlags, @void pnumprs, @char rgbDig;
stub int VarPow -> @void pvarLeft, @void pvarRight, @void pvarResult;
stub int VarR4CmpR8 -> float fltLeft, float dblRight;
stub int VarR4FromBool -> int boolIn, @void pfltOut;
stub int VarR4FromDate -> float dateIn, @void pfltOut;
stub int VarR4FromDec -> @void pdecIn, @void pfltOut;
stub int VarR4FromDisp -> @void pdispIn, utype int lcid, @void pfltOut;
stub int VarR4FromI1 -> char cIn, @void pfltOut;
stub int VarR4FromI2 -> int sIn, @void pfltOut;
stub int VarR4FromI4 -> int lIn, @void pfltOut;
stub int VarR4FromI8 -> longlong i64In, @void pfltOut;
stub int VarR4FromR8 -> float dblIn, @void pfltOut;
stub int VarR4FromStr -> @void strIn, utype int lcid, utype int dwFlags, @void pfltOut;
stub int VarR4FromUI1 -> utype char bIn, @void pfltOut;
stub int VarR4FromUI2 -> utype int uiIn, @void pfltOut;
stub int VarR4FromUI4 -> utype int ulIn, @void pfltOut;
stub int VarR4FromUI8 -> utype longlong ui64In, @void pfltOut;
stub int VarR8FromBool -> int boolIn, @float pdblOut;
stub int VarR8FromDate -> float dateIn, @float pdblOut;
stub int VarR8FromDec -> @void pdecIn, @float pdblOut;
stub int VarR8FromDisp -> @void pdispIn, utype int lcid, @float pdblOut;
stub int VarR8FromI1 -> char cIn, @float pdblOut;
stub int VarR8FromI2 -> int sIn, @float pdblOut;
stub int VarR8FromI4 -> int lIn, @float pdblOut;
stub int VarR8FromI8 -> longlong i64In, @float pdblOut;
stub int VarR8FromR4 -> float fltIn, @float pdblOut;
stub int VarR8FromStr -> @void strIn, utype int lcid, utype int dwFlags, @float pdblOut;
stub int VarR8FromUI1 -> utype char bIn, @float pdblOut;
stub int VarR8FromUI2 -> utype int uiIn, @float pdblOut;
stub int VarR8FromUI4 -> utype int ulIn, @float pdblOut;
stub int VarR8FromUI8 -> utype longlong ui64In, @float pdblOut;
stub int VarR8Pow -> float dblLeft, float dblRight, @float pdblResult;
stub int VarR8Round -> float dblIn, int cDecimals, @float pdblResult;
stub int VarRound -> @void pvarIn, int cDecimals, @void pvarResult;
stub int VarSub -> @void pvarLeft, @void pvarRight, @void pvarResult;
stub int VarTokenizeFormatString -> @void pstrFormat, @char rgbTok, int cbTok, int iFirstDay, int iFirstWeek, utype int lcid, @int pcbActual;
stub int VarUI1FromBool -> int boolIn, @char pbOut;
stub int VarUI1FromDate -> float dateIn, @char pbOut;
stub int VarUI1FromDec -> @void pdecIn, @char pbOut;
stub int VarUI1FromDisp -> @void pdispIn, utype int lcid, @char pbOut;
stub int VarUI1FromI1 -> char cIn, @char pbOut;
stub int VarUI1FromI2 -> int sIn, @char pbOut;
stub int VarUI1FromI4 -> int lIn, @char pbOut;
stub int VarUI1FromI8 -> longlong i64In, @char pbOut;
stub int VarUI1FromR4 -> float fltIn, @char pbOut;
stub int VarUI1FromR8 -> float dblIn, @char pbOut;
stub int VarUI1FromStr -> @void strIn, utype int lcid, utype int dwFlags, @char pbOut;
stub int VarUI1FromUI2 -> utype int uiIn, @char pbOut;
stub int VarUI1FromUI4 -> utype int ulIn, @char pbOut;
stub int VarUI1FromUI8 -> utype longlong ui64In, @char pbOut;
stub int VarUI2FromBool -> int boolIn, @int puiOut;
stub int VarUI2FromDate -> float dateIn, @int puiOut;
stub int VarUI2FromDec -> @void pdecIn, @int puiOut;
stub int VarUI2FromDisp -> @void pdispIn, utype int lcid, @int puiOut;
stub int VarUI2FromI1 -> char cIn, @int puiOut;
stub int VarUI2FromI2 -> int uiIn, @int puiOut;
stub int VarUI2FromI4 -> int lIn, @int puiOut;
stub int VarUI2FromI8 -> longlong i64In, @int puiOut;
stub int VarUI2FromR4 -> float fltIn, @int puiOut;
stub int VarUI2FromR8 -> float dblIn, @int puiOut;
stub int VarUI2FromStr -> @void strIn, utype int lcid, utype int dwFlags, @int puiOut;
stub int VarUI2FromUI1 -> utype char bIn, @int puiOut;
stub int VarUI2FromUI4 -> utype int ulIn, @int puiOut;
stub int VarUI2FromUI8 -> utype longlong i64In, @int puiOut;
stub int VarUI4FromBool -> int boolIn, @int pulOut;
stub int VarUI4FromDate -> float dateIn, @int pulOut;
stub int VarUI4FromDec -> @void pdecIn, @int pulOut;
stub int VarUI4FromDisp -> @void pdispIn, utype int lcid, @int pulOut;
stub int VarUI4FromI1 -> char cIn, @int pulOut;
stub int VarUI4FromI2 -> int uiIn, @int pulOut;
stub int VarUI4FromI4 -> int lIn, @int pulOut;
stub int VarUI4FromI8 -> longlong i64In, @int plOut;
stub int VarUI4FromR4 -> float fltIn, @int pulOut;
stub int VarUI4FromR8 -> float dblIn, @int pulOut;
stub int VarUI4FromStr -> @void strIn, utype int lcid, utype int dwFlags, @int pulOut;
stub int VarUI4FromUI1 -> utype char bIn, @int pulOut;
stub int VarUI4FromUI2 -> utype int uiIn, @int pulOut;
stub int VarUI4FromUI8 -> utype longlong ui64In, @int plOut;
stub int VarUI8FromBool -> int boolIn, @longlong pi64Out;
stub int VarUI8FromDate -> float dateIn, @longlong pi64Out;
stub int VarUI8FromDec -> @void pdecIn, @longlong pi64Out;
stub int VarUI8FromDisp -> @void pdispIn, utype int lcid, @longlong pi64Out;
stub int VarUI8FromI1 -> char cIn, @longlong pi64Out;
stub int VarUI8FromI2 -> int sIn, @longlong pi64Out;
stub int VarUI8FromI8 -> longlong ui64In, @longlong pi64Out;
stub int VarUI8FromR4 -> float fltIn, @longlong pi64Out;
stub int VarUI8FromR8 -> float dblIn, @longlong pi64Out;
stub int VarUI8FromStr -> @void strIn, utype int lcid, utype int dwFlags, @longlong pi64Out;
stub int VarUI8FromUI1 -> utype char bIn, @longlong pi64Out;
stub int VarUI8FromUI2 -> utype int uiIn, @longlong pi64Out;
stub int VarUI8FromUI4 -> utype int ulIn, @longlong pi64Out;
stub int VarUdateFromDate -> float dateIn, utype int dwFlags, @void pudateOut;
stub int VarWeekdayName -> int iWeekday, int fAbbrev, int iFirstDay, utype int dwFlags, @void pbstrOut;
stub int VarXor -> @void pvarLeft, @void pvarRight, @void pvarResult;
stub int VariantChangeType -> @void pvargDest, @void pvarSrc, utype int wFlags, utype int vt;
stub int VariantChangeTypeEx -> @void pvargDest, @void pvarSrc, utype int lcid, utype int wFlags, utype int vt;
stub int VariantClear -> @void pvarg;
stub int VariantCopy -> @void pvargDest, @void pvargSrc;
stub int VariantCopyInd -> @void pvarDest, @void pvargSrc;
stub void VariantInit -> @void pvarg;
stub int VariantTimeToDosDateTime -> float vtime, @int pwDosDate, @int pwDosTime;
stub int VariantTimeToSystemTime -> float vtime, @void lpSystemTime;
stub int VectorFromBstr -> @void bstr, @void ppsa;

!!! Declared by the headers, but with a type the language cannot write:
!!!   CreateTypeLib
!!!   CreateTypeLib2
!!!   DispCallFunc
!!!   LHashValOfNameSys
!!!   LHashValOfNameSysA
!!!   LoadTypeLibEx
!!!   UnRegisterTypeLib
!!!   VarBoolFromCy
!!!   VarBstrFromCy
!!!   VarCyAbs
!!!   VarCyAdd
!!!   VarCyCmp
!!!   VarCyCmpR8
!!!   VarCyFix
!!!   VarCyInt
!!!   VarCyMul
!!!   VarCyMulI4
!!!   VarCyMulI8
!!!   VarCyNeg
!!!   VarCyRound
!!!   VarCySub
!!!   VarDateFromCy
!!!   VarDecFromCy
!!!   VarI1FromCy
!!!   VarI2FromCy
!!!   VarI4FromCy
!!!   VarI8FromCy
!!!   VarR4FromCy
!!!   VarR8FromCy
!!!   VarUI1FromCy
!!!   VarUI2FromCy
!!!   VarUI4FromCy
!!!   VarUI8FromCy

!!! No prototype in the headers this build saw. They are here so the
!!! list is complete; uncomment and give the real signature to use one.
!!! CreateTypeLib
!!! CreateTypeLib2
!!! DispCallFunc
!!! LHashValOfNameSys
!!! LHashValOfNameSysA
!!! LoadTypeLibEx
!!! UnRegisterTypeLib
!!! VarBoolFromCy
!!! VarBstrFromCy
!!! VarCmp
!!! VarCyAbs
!!! VarCyAdd
!!! VarCyCmp
!!! VarCyCmpR8
!!! VarCyFix
!!! VarCyInt
!!! VarCyMul
!!! VarCyMulI4
!!! VarCyMulI8
!!! VarCyNeg
!!! VarCyRound
!!! VarCySub
!!! VarDateFromCy
!!! VarDecFromCy
!!! VarI1FromCy
!!! VarI2FromCy
!!! VarI4FromCy
!!! VarI8FromCy
!!! VarR4FromCy
!!! VarR8FromCy
!!! VarUI1FromCy
!!! VarUI2FromCy
!!! VarUI4FromCy
!!! VarUI8FromCy
