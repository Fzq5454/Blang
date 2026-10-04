!~
~  native/cryptsp.dll.b: the cryptsp.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/cryptsp.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/cryptsp.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `cryptsp.dll.b` is what produces `meta/cryptsp.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\cryptsp.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per cryptsp.dll export that the headers declare. The
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
!!! 39 declarations here, 0 kept from the hand-checked list above, 0 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub int CryptAcquireContextA -> @longlong phProv, str szContainer, str szProvider, utype int dwProvType, utype int dwFlags;
stub int CryptAcquireContextW -> @longlong phProv, @void szContainer, @void szProvider, utype int dwProvType, utype int dwFlags;
stub int CryptContextAddRef -> utype longlong hProv, @int pdwReserved, utype int dwFlags;
stub int CryptCreateHash -> utype longlong hProv, utype int Algid, utype longlong hKey, utype int dwFlags, @longlong phHash;
stub int CryptDecrypt -> utype longlong hKey, utype longlong hHash, int Final, utype int dwFlags, @char pbData, @int pdwDataLen;
stub int CryptDeriveKey -> utype longlong hProv, utype int Algid, utype longlong hBaseData, utype int dwFlags, @longlong phKey;
stub int CryptDestroyHash -> utype longlong hHash;
stub int CryptDestroyKey -> utype longlong hKey;
stub int CryptDuplicateHash -> utype longlong hHash, @int pdwReserved, utype int dwFlags, @longlong phHash;
stub int CryptDuplicateKey -> utype longlong hKey, @int pdwReserved, utype int dwFlags, @longlong phKey;
stub int CryptEncrypt -> utype longlong hKey, utype longlong hHash, int Final, utype int dwFlags, @char pbData, @int pdwDataLen, utype int dwBufLen;
stub int CryptEnumProviderTypesA -> utype int dwIndex, @int pdwReserved, utype int dwFlags, @int pdwProvType, str szTypeName, @int pcbTypeName;
stub int CryptEnumProviderTypesW -> utype int dwIndex, @int pdwReserved, utype int dwFlags, @int pdwProvType, @void szTypeName, @int pcbTypeName;
stub int CryptEnumProvidersA -> utype int dwIndex, @int pdwReserved, utype int dwFlags, @int pdwProvType, str szProvName, @int pcbProvName;
stub int CryptEnumProvidersW -> utype int dwIndex, @int pdwReserved, utype int dwFlags, @int pdwProvType, @void szProvName, @int pcbProvName;
stub int CryptExportKey -> utype longlong hKey, utype longlong hExpKey, utype int dwBlobType, utype int dwFlags, @char pbData, @int pdwDataLen;
stub int CryptGenKey -> utype longlong hProv, utype int Algid, utype int dwFlags, @longlong phKey;
stub int CryptGenRandom -> utype longlong hProv, utype int dwLen, @char pbBuffer;
stub int CryptGetDefaultProviderA -> utype int dwProvType, @int pdwReserved, utype int dwFlags, str pszProvName, @int pcbProvName;
stub int CryptGetDefaultProviderW -> utype int dwProvType, @int pdwReserved, utype int dwFlags, @void pszProvName, @int pcbProvName;
stub int CryptGetHashParam -> utype longlong hHash, utype int dwParam, @char pbData, @int pdwDataLen, utype int dwFlags;
stub int CryptGetKeyParam -> utype longlong hKey, utype int dwParam, @char pbData, @int pdwDataLen, utype int dwFlags;
stub int CryptGetProvParam -> utype longlong hProv, utype int dwParam, @char pbData, @int pdwDataLen, utype int dwFlags;
stub int CryptGetUserKey -> utype longlong hProv, utype int dwKeySpec, @longlong phUserKey;
stub int CryptHashData -> utype longlong hHash, @char pbData, utype int dwDataLen, utype int dwFlags;
stub int CryptHashSessionKey -> utype longlong hHash, utype longlong hKey, utype int dwFlags;
stub int CryptImportKey -> utype longlong hProv, @char pbData, utype int dwDataLen, utype longlong hPubKey, utype int dwFlags, @longlong phKey;
stub int CryptReleaseContext -> utype longlong hProv, utype int dwFlags;
stub int CryptSetHashParam -> utype longlong hHash, utype int dwParam, @char pbData, utype int dwFlags;
stub int CryptSetKeyParam -> utype longlong hKey, utype int dwParam, @char pbData, utype int dwFlags;
stub int CryptSetProvParam -> utype longlong hProv, utype int dwParam, @char pbData, utype int dwFlags;
stub int CryptSetProviderA -> str pszProvName, utype int dwProvType;
stub int CryptSetProviderExA -> str pszProvName, utype int dwProvType, @int pdwReserved, utype int dwFlags;
stub int CryptSetProviderExW -> @void pszProvName, utype int dwProvType, @int pdwReserved, utype int dwFlags;
stub int CryptSetProviderW -> @void pszProvName, utype int dwProvType;
stub int CryptSignHashA -> utype longlong hHash, utype int dwKeySpec, str szDescription, utype int dwFlags, @char pbSignature, @int pdwSigLen;
stub int CryptSignHashW -> utype longlong hHash, utype int dwKeySpec, @void szDescription, utype int dwFlags, @char pbSignature, @int pdwSigLen;
stub int CryptVerifySignatureA -> utype longlong hHash, @char pbSignature, utype int dwSigLen, utype longlong hPubKey, str szDescription, utype int dwFlags;
stub int CryptVerifySignatureW -> utype longlong hHash, @char pbSignature, utype int dwSigLen, utype longlong hPubKey, @void szDescription, utype int dwFlags;
