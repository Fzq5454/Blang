!~
~  native/ncrypt.dll.b: the ncrypt.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/ncrypt.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/ncrypt.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `ncrypt.dll.b` is what produces `meta/ncrypt.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\ncrypt.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per ncrypt.dll export that the headers declare. The
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
!!! 79 declarations here, 0 kept from the hand-checked list above, 1 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub int BCryptAddContextFunction -> utype int dwTable, @void pszContext, utype int dwInterface, @void pszFunction, utype int dwPosition;
stub int BCryptCloseAlgorithmProvider -> @void hAlgorithm, utype int dwFlags;
stub int BCryptConfigureContext -> utype int dwTable, @void pszContext, @void pConfig;
stub int BCryptConfigureContextFunction -> utype int dwTable, @void pszContext, utype int dwInterface, @void pszFunction, @void pConfig;
stub int BCryptCreateContext -> utype int dwTable, @void pszContext, @void pConfig;
stub int BCryptCreateHash -> @void hAlgorithm, @void phHash, @char pbHashObject, utype int cbHashObject, @char pbSecret, utype int cbSecret, utype int dwFlags;
stub int BCryptCreateMultiHash -> @void hAlgorithm, @void phHash, utype int nHashes, @char pbHashObject, utype int cbHashObject, @char pbSecret, utype int cbSecret, utype int dwFlags;
stub int BCryptDecrypt -> @void hKey, @char pbInput, utype int cbInput, @void pPaddingInfo, @char pbIV, utype int cbIV, @char pbOutput, utype int cbOutput, @int pcbResult, utype int dwFlags;
stub int BCryptDeleteContext -> utype int dwTable, @void pszContext;
stub int BCryptDeriveKey -> @void hSharedSecret, @void pwszKDF, @void pParameterList, @char pbDerivedKey, utype int cbDerivedKey, @int pcbResult, utype int dwFlags;
stub int BCryptDeriveKeyCapi -> @void hHash, @void hTargetAlg, @char pbDerivedKey, utype int cbDerivedKey, utype int dwFlags;
stub int BCryptDeriveKeyPBKDF2 -> @void hPrf, @char pbPassword, utype int cbPassword, @char pbSalt, utype int cbSalt, utype longlong cIterations, @char pbDerivedKey, utype int cbDerivedKey, utype int dwFlags;
stub int BCryptDestroyHash -> @void hHash;
stub int BCryptDestroyKey -> @void hKey;
stub int BCryptDestroySecret -> @void hSecret;
stub int BCryptDuplicateHash -> @void hHash, @void phNewHash, @char pbHashObject, utype int cbHashObject, utype int dwFlags;
stub int BCryptDuplicateKey -> @void hKey, @void phNewKey, @char pbKeyObject, utype int cbKeyObject, utype int dwFlags;
stub int BCryptEncrypt -> @void hKey, @char pbInput, utype int cbInput, @void pPaddingInfo, @char pbIV, utype int cbIV, @char pbOutput, utype int cbOutput, @int pcbResult, utype int dwFlags;
stub int BCryptEnumAlgorithms -> utype int dwAlgOperations, @int pAlgCount, @void ppAlgList, utype int dwFlags;
stub int BCryptEnumContextFunctionProviders -> utype int dwTable, @void pszContext, utype int dwInterface, @void pszFunction, @int pcbBuffer, @void ppBuffer;
stub int BCryptEnumContextFunctions -> utype int dwTable, @void pszContext, utype int dwInterface, @int pcbBuffer, @void ppBuffer;
stub int BCryptEnumContexts -> utype int dwTable, @int pcbBuffer, @void ppBuffer;
stub int BCryptEnumProviders -> @void pszAlgId, @int pImplCount, @void ppImplList, utype int dwFlags;
stub int BCryptEnumRegisteredProviders -> @int pcbBuffer, @void ppBuffer;
stub int BCryptExportKey -> @void hKey, @void hExportKey, @void pszBlobType, @char pbOutput, utype int cbOutput, @int pcbResult, utype int dwFlags;
stub int BCryptFinalizeKeyPair -> @void hKey, utype int dwFlags;
stub int BCryptFinishHash -> @void hHash, @char pbOutput, utype int cbOutput, utype int dwFlags;
stub void BCryptFreeBuffer -> @void pvBuffer;
stub int BCryptGenRandom -> @void hAlgorithm, @char pbBuffer, utype int cbBuffer, utype int dwFlags;
stub int BCryptGenerateKeyPair -> @void hAlgorithm, @void phKey, utype int dwLength, utype int dwFlags;
stub int BCryptGenerateSymmetricKey -> @void hAlgorithm, @void phKey, @char pbKeyObject, utype int cbKeyObject, @char pbSecret, utype int cbSecret, utype int dwFlags;
stub int BCryptGetFipsAlgorithmMode -> @char pfEnabled;
stub int BCryptGetProperty -> @void hObject, @void pszProperty, @char pbOutput, utype int cbOutput, @int pcbResult, utype int dwFlags;
stub int BCryptHash -> @void hAlgorithm, @char pbSecret, utype int cbSecret, @char pbInput, utype int cbInput, @char pbOutput, utype int cbOutput;
stub int BCryptHashData -> @void hHash, @char pbInput, utype int cbInput, utype int dwFlags;
stub int BCryptImportKey -> @void hAlgorithm, @void hImportKey, @void pszBlobType, @void phKey, @char pbKeyObject, utype int cbKeyObject, @char pbInput, utype int cbInput, utype int dwFlags;
stub int BCryptImportKeyPair -> @void hAlgorithm, @void hImportKey, @void pszBlobType, @void phKey, @char pbInput, utype int cbInput, utype int dwFlags;
stub int BCryptKeyDerivation -> @void hKey, @void pParameterList, @char pbDerivedKey, utype int cbDerivedKey, @int pcbResult, utype int dwFlags;
stub int BCryptOpenAlgorithmProvider -> @void phAlgorithm, @void pszAlgId, @void pszImplementation, utype int dwFlags;
stub int BCryptQueryContextConfiguration -> utype int dwTable, @void pszContext, @int pcbBuffer, @void ppBuffer;
stub int BCryptQueryContextFunctionConfiguration -> utype int dwTable, @void pszContext, utype int dwInterface, @void pszFunction, @int pcbBuffer, @void ppBuffer;
stub int BCryptQueryContextFunctionProperty -> utype int dwTable, @void pszContext, utype int dwInterface, @void pszFunction, @void pszProperty, @int pcbValue, @void ppbValue;
stub int BCryptQueryProviderRegistration -> @void pszProvider, utype int dwMode, utype int dwInterface, @int pcbBuffer, @void ppBuffer;
stub int BCryptRegisterConfigChangeNotify -> @void phEvent;
stub int BCryptRemoveContextFunction -> utype int dwTable, @void pszContext, utype int dwInterface, @void pszFunction;
stub int BCryptResolveProviders -> @void pszContext, utype int dwInterface, @void pszFunction, @void pszProvider, utype int dwMode, utype int dwFlags, @int pcbBuffer, @void ppBuffer;
stub int BCryptSecretAgreement -> @void hPrivKey, @void hPubKey, @void phAgreedSecret, utype int dwFlags;
stub int BCryptSetContextFunctionProperty -> utype int dwTable, @void pszContext, utype int dwInterface, @void pszFunction, @void pszProperty, utype int cbValue, @char pbValue;
stub int BCryptSetProperty -> @void hObject, @void pszProperty, @char pbInput, utype int cbInput, utype int dwFlags;
stub int BCryptSignHash -> @void hKey, @void pPaddingInfo, @char pbInput, utype int cbInput, @char pbOutput, utype int cbOutput, @int pcbResult, utype int dwFlags;
stub int BCryptUnregisterConfigChangeNotify -> @void hEvent;
stub int BCryptVerifySignature -> @void hKey, @void pPaddingInfo, @char pbHash, utype int cbHash, @char pbSignature, utype int cbSignature, utype int dwFlags;
stub int NCryptCreateClaim -> utype longlong hSubjectKey, utype longlong hAuthorityKey, utype int dwClaimType, @void pParameterList, @char pbClaimBlob, utype int cbClaimBlob, @int pcbResult, utype int dwFlags;
stub int NCryptCreatePersistedKey -> utype longlong hProvider, @longlong phKey, @void pszAlgId, @void pszKeyName, utype int dwLegacyKeySpec, utype int dwFlags;
stub int NCryptDecrypt -> utype longlong hKey, @char pbInput, utype int cbInput, @void pPaddingInfo, @char pbOutput, utype int cbOutput, @int pcbResult, utype int dwFlags;
stub int NCryptDeleteKey -> utype longlong hKey, utype int dwFlags;
stub int NCryptDeriveKey -> utype longlong hSharedSecret, @void pwszKDF, @void pParameterList, @char pbDerivedKey, utype int cbDerivedKey, @int pcbResult, utype int dwFlags;
stub int NCryptEncrypt -> utype longlong hKey, @char pbInput, utype int cbInput, @void pPaddingInfo, @char pbOutput, utype int cbOutput, @int pcbResult, utype int dwFlags;
stub int NCryptEnumAlgorithms -> utype longlong hProvider, utype int dwAlgOperations, @int pdwAlgCount, @void ppAlgList, utype int dwFlags;
stub int NCryptEnumKeys -> utype longlong hProvider, @void pszScope, @void ppKeyName, @void ppEnumState, utype int dwFlags;
stub int NCryptEnumStorageProviders -> @int pdwProviderCount, @void ppProviderList, utype int dwFlags;
stub int NCryptExportKey -> utype longlong hKey, utype longlong hExportKey, @void pszBlobType, @void pParameterList, @char pbOutput, utype int cbOutput, @int pcbResult, utype int dwFlags;
stub int NCryptFinalizeKey -> utype longlong hKey, utype int dwFlags;
stub int NCryptFreeBuffer -> @void pvInput;
stub int NCryptFreeObject -> utype longlong hObject;
stub int NCryptGetProperty -> utype longlong hObject, @void pszProperty, @char pbOutput, utype int cbOutput, @int pcbResult, utype int dwFlags;
stub int NCryptImportKey -> utype longlong hProvider, utype longlong hImportKey, @void pszBlobType, @void pParameterList, @longlong phKey, @char pbData, utype int cbData, utype int dwFlags;
stub int NCryptIsAlgSupported -> utype longlong hProvider, @void pszAlgId, utype int dwFlags;
stub int NCryptIsKeyHandle -> utype longlong hKey;
stub int NCryptKeyDerivation -> utype longlong hKey, @void pParameterList, @char pbDerivedKey, utype int cbDerivedKey, @int pcbResult, utype int dwFlags;
stub int NCryptNotifyChangeKey -> utype longlong hProvider, @void phEvent, utype int dwFlags;
stub int NCryptOpenKey -> utype longlong hProvider, @longlong phKey, @void pszKeyName, utype int dwLegacyKeySpec, utype int dwFlags;
stub int NCryptOpenStorageProvider -> @longlong phProvider, @void pszProviderName, utype int dwFlags;
stub int NCryptSecretAgreement -> utype longlong hPrivKey, utype longlong hPubKey, @longlong phAgreedSecret, utype int dwFlags;
stub int NCryptSetProperty -> utype longlong hObject, @void pszProperty, @char pbInput, utype int cbInput, utype int dwFlags;
stub int NCryptSignHash -> utype longlong hKey, @void pPaddingInfo, @char pbHashValue, utype int cbHashValue, @char pbSignature, utype int cbSignature, @int pcbResult, utype int dwFlags;
stub int NCryptTranslateHandle -> @longlong phProvider, @longlong phKey, utype longlong hLegacyProv, utype longlong hLegacyKey, utype int dwLegacyKeySpec, utype int dwFlags;
stub int NCryptVerifyClaim -> utype longlong hSubjectKey, utype longlong hAuthorityKey, utype int dwClaimType, @void pParameterList, @char pbClaimBlob, utype int cbClaimBlob, @void pOutput, utype int dwFlags;
stub int NCryptVerifySignature -> utype longlong hKey, @void pPaddingInfo, @char pbHashValue, utype int cbHashValue, @char pbSignature, utype int cbSignature, utype int dwFlags;

!!! Declared by the headers, but with a type the language cannot write:
!!!   BCryptProcessMultiOperations

!!! No prototype in the headers this build saw. They are here so the
!!! list is complete; uncomment and give the real signature to use one.
!!! BCryptProcessMultiOperations
