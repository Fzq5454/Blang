!~
~  native/crypt32.dll.b: the crypt32.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/crypt32.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/crypt32.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `crypt32.dll.b` is what produces `meta/crypt32.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\crypt32.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per crypt32.dll export that the headers declare. The
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
!!! 223 declarations here, 0 kept from the hand-checked list above, 1 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub int CertAddCRLContextToStore -> @void hCertStore, @void pCrlContext, utype int dwAddDisposition, @void ppStoreContext;
stub int CertAddCRLLinkToStore -> @void hCertStore, @void pCrlContext, utype int dwAddDisposition, @void ppStoreContext;
stub int CertAddCTLContextToStore -> @void hCertStore, @void pCtlContext, utype int dwAddDisposition, @void ppStoreContext;
stub int CertAddCTLLinkToStore -> @void hCertStore, @void pCtlContext, utype int dwAddDisposition, @void ppStoreContext;
stub int CertAddCertificateContextToStore -> @void hCertStore, @void pCertContext, utype int dwAddDisposition, @void ppStoreContext;
stub int CertAddCertificateLinkToStore -> @void hCertStore, @void pCertContext, utype int dwAddDisposition, @void ppStoreContext;
stub int CertAddEncodedCRLToStore -> @void hCertStore, utype int dwCertEncodingType, @char pbCrlEncoded, utype int cbCrlEncoded, utype int dwAddDisposition, @void ppCrlContext;
stub int CertAddEncodedCTLToStore -> @void hCertStore, utype int dwMsgAndCertEncodingType, @char pbCtlEncoded, utype int cbCtlEncoded, utype int dwAddDisposition, @void ppCtlContext;
stub int CertAddEncodedCertificateToStore -> @void hCertStore, utype int dwCertEncodingType, @char pbCertEncoded, utype int cbCertEncoded, utype int dwAddDisposition, @void ppCertContext;
stub int CertAddEncodedCertificateToSystemStoreA -> str szCertStoreName, @char pbCertEncoded, utype int cbCertEncoded;
stub int CertAddEncodedCertificateToSystemStoreW -> @void szCertStoreName, @char pbCertEncoded, utype int cbCertEncoded;
stub int CertAddEnhancedKeyUsageIdentifier -> @void pCertContext, str pszUsageIdentifier;
stub void CertAddRefServerOcspResponse -> @void hServerOcspResponse;
stub void CertAddRefServerOcspResponseContext -> @void pServerOcspResponseContext;
stub int CertAddSerializedElementToStore -> @void hCertStore, @char pbElement, utype int cbElement, utype int dwAddDisposition, utype int dwFlags, utype int dwContextTypeFlags, @int pdwContextType, @void ppvContext;
stub int CertAddStoreToCollection -> @void hCollectionStore, @void hSiblingStore, utype int dwUpdateFlags, utype int dwPriority;
stub str CertAlgIdToOID -> utype int dwAlgId;
stub void CertCloseServerOcspResponse -> @void hServerOcspResponse, utype int dwFlags;
stub int CertCloseStore -> @void hCertStore, utype int dwFlags;
stub int CertCompareCertificate -> utype int dwCertEncodingType, @void pCertId1, @void pCertId2;
stub int CertCompareCertificateName -> utype int dwCertEncodingType, @void pCertName1, @void pCertName2;
stub int CertCompareIntegerBlob -> @void pInt1, @void pInt2;
stub int CertComparePublicKeyInfo -> utype int dwCertEncodingType, @void pPublicKey1, @void pPublicKey2;
stub int CertControlStore -> @void hCertStore, utype int dwFlags, utype int dwCtrlType, @void pvCtrlPara;
stub @void CertCreateCRLContext -> utype int dwCertEncodingType, @char pbCrlEncoded, utype int cbCrlEncoded;
stub @void CertCreateCTLContext -> utype int dwMsgAndCertEncodingType, @char pbCtlEncoded, utype int cbCtlEncoded;
stub int CertCreateCTLEntryFromCertificateContextProperties -> @void pCertContext, utype int cOptAttr, @void rgOptAttr, utype int dwFlags, @void pvReserved, @void pCtlEntry, @int pcbCtlEntry;
stub int CertCreateCertificateChainEngine -> @void pConfig, @void phChainEngine;
stub @void CertCreateCertificateContext -> utype int dwCertEncodingType, @char pbCertEncoded, utype int cbCertEncoded;
stub @void CertCreateContext -> utype int dwContextType, utype int dwEncodingType, @char pbEncoded, utype int cbEncoded, utype int dwFlags, @void pCreatePara;
stub @void CertCreateSelfSignCertificate -> utype longlong hCryptProvOrNCryptKey, @void pSubjectIssuerBlob, utype int dwFlags, @void pKeyProvInfo, @void pSignatureAlgorithm, @void pStartTime, @void pEndTime, @void pExtensions;
stub int CertDeleteCRLFromStore -> @void pCrlContext;
stub int CertDeleteCTLFromStore -> @void pCtlContext;
stub int CertDeleteCertificateFromStore -> @void pCertContext;
stub @void CertDuplicateCRLContext -> @void pCrlContext;
stub @void CertDuplicateCTLContext -> @void pCtlContext;
stub @void CertDuplicateCertificateChain -> @void pChainContext;
stub @void CertDuplicateCertificateContext -> @void pCertContext;
stub @void CertDuplicateStore -> @void hCertStore;
stub utype int CertEnumCRLContextProperties -> @void pCrlContext, utype int dwPropId;
stub @void CertEnumCRLsInStore -> @void hCertStore, @void pPrevCrlContext;
stub utype int CertEnumCTLContextProperties -> @void pCtlContext, utype int dwPropId;
stub @void CertEnumCTLsInStore -> @void hCertStore, @void pPrevCtlContext;
stub utype int CertEnumCertificateContextProperties -> @void pCertContext, utype int dwPropId;
stub @void CertEnumCertificatesInStore -> @void hCertStore, @void pPrevCertContext;
stub int CertEnumPhysicalStore -> @void pvSystemStore, utype int dwFlags, @void pvArg, @func pfnEnum;
stub int CertEnumSubjectInSortedCTL -> @void pCtlContext, @void ppvNextSubject, @void pSubjectIdentifier, @void pEncodedAttributes;
stub int CertEnumSystemStore -> utype int dwFlags, @void pvSystemStoreLocationPara, @void pvArg, @func pfnEnum;
stub int CertEnumSystemStoreLocation -> utype int dwFlags, @void pvArg, @func pfnEnum;
stub @void CertFindAttribute -> str pszObjId, utype int cAttr, @void rgAttr;
stub @void CertFindCRLInStore -> @void hCertStore, utype int dwCertEncodingType, utype int dwFindFlags, utype int dwFindType, @void pvFindPara, @void pPrevCrlContext;
stub @void CertFindCTLInStore -> @void hCertStore, utype int dwMsgAndCertEncodingType, utype int dwFindFlags, utype int dwFindType, @void pvFindPara, @void pPrevCtlContext;
stub int CertFindCertificateInCRL -> @void pCert, @void pCrlContext, utype int dwFlags, @void pvReserved, @void ppCrlEntry;
stub @void CertFindCertificateInStore -> @void hCertStore, utype int dwCertEncodingType, utype int dwFindFlags, utype int dwFindType, @void pvFindPara, @void pPrevCertContext;
stub @void CertFindChainInStore -> @void hCertStore, utype int dwCertEncodingType, utype int dwFindFlags, utype int dwFindType, @void pvFindPara, @void pPrevChainContext;
stub @void CertFindExtension -> str pszObjId, utype int cExtensions, @void rgExtensions;
stub @void CertFindRDNAttr -> str pszObjId, @void pName;
stub @void CertFindSubjectInCTL -> utype int dwEncodingType, utype int dwSubjectType, @void pvSubject, @void pCtlContext, utype int dwFlags;
stub int CertFindSubjectInSortedCTL -> @void pSubjectIdentifier, @void pCtlContext, utype int dwFlags, @void pvReserved, @void pEncodedAttributes;
stub int CertFreeCRLContext -> @void pCrlContext;
stub int CertFreeCTLContext -> @void pCtlContext;
stub void CertFreeCertificateChain -> @void pChainContext;
stub void CertFreeCertificateChainEngine -> @void hChainEngine;
stub void CertFreeCertificateChainList -> @void prgpSelection;
stub int CertFreeCertificateContext -> @void pCertContext;
stub void CertFreeServerOcspResponseContext -> @void pServerOcspResponseContext;
stub int CertGetCRLContextProperty -> @void pCrlContext, utype int dwPropId, @void pvData, @int pcbData;
stub @void CertGetCRLFromStore -> @void hCertStore, @void pIssuerContext, @void pPrevCrlContext, @int pdwFlags;
stub int CertGetCTLContextProperty -> @void pCtlContext, utype int dwPropId, @void pvData, @int pcbData;
stub int CertGetCertificateChain -> @void hChainEngine, @void pCertContext, @void pTime, @void hAdditionalStore, @void pChainPara, utype int dwFlags, @void pvReserved, @void ppChainContext;
stub int CertGetCertificateContextProperty -> @void pCertContext, utype int dwPropId, @void pvData, @int pcbData;
stub int CertGetEnhancedKeyUsage -> @void pCertContext, utype int dwFlags, @void pUsage, @int pcbUsage;
stub int CertGetIntendedKeyUsage -> utype int dwCertEncodingType, @void pCertInfo, @char pbKeyUsage, utype int cbKeyUsage;
stub @void CertGetIssuerCertificateFromStore -> @void hCertStore, @void pSubjectContext, @void pPrevIssuerContext, @int pdwFlags;
stub utype int CertGetNameStringA -> @void pCertContext, utype int dwType, utype int dwFlags, @void pvTypePara, str pszNameString, utype int cchNameString;
stub utype int CertGetNameStringW -> @void pCertContext, utype int dwType, utype int dwFlags, @void pvTypePara, @void pszNameString, utype int cchNameString;
stub utype int CertGetPublicKeyLength -> utype int dwCertEncodingType, @void pPublicKey;
stub @void CertGetServerOcspResponseContext -> @void hServerOcspResponse, utype int dwFlags, @void pvReserved;
stub int CertGetStoreProperty -> @void hCertStore, utype int dwPropId, @void pvData, @int pcbData;
stub @void CertGetSubjectCertificateFromStore -> @void hCertStore, utype int dwCertEncodingType, @void pCertId;
stub int CertGetValidUsages -> utype int cCerts, @void rghCerts, @int cNumOIDs, @void rghOIDs, @int pcbOIDs;
stub int CertIsRDNAttrsInCertificateName -> utype int dwCertEncodingType, utype int dwFlags, @void pCertName, @void pRDN;
stub int CertIsStrongHashToSign -> @void pStrongSignPara, @void pwszCNGHashAlgid, @void pSigningCert;
stub int CertIsValidCRLForCertificate -> @void pCert, @void pCrl, utype int dwFlags, @void pvReserved;
stub int CertIsWeakHash -> utype int dwHashUseType, @void pwszCNGHashAlgid, utype int dwChainFlags, @void pSignerChainContext, @void pTimeStamp, @void pwszFileName;
stub utype int CertNameToStrA -> utype int dwCertEncodingType, @void pName, utype int dwStrType, str psz, utype int csz;
stub utype int CertNameToStrW -> utype int dwCertEncodingType, @void pName, utype int dwStrType, @void psz, utype int csz;
stub utype int CertOIDToAlgId -> str pszObjId;
stub @void CertOpenServerOcspResponse -> @void pChainContext, utype int dwFlags, @void pvReserved;
stub @void CertOpenStore -> str lpszStoreProvider, utype int dwEncodingType, utype longlong hCryptProv, utype int dwFlags, @void pvPara;
stub @void CertOpenSystemStoreA -> utype longlong hProv, str szSubsystemProtocol;
stub @void CertOpenSystemStoreW -> utype longlong hProv, @void szSubsystemProtocol;
stub utype int CertRDNValueToStrA -> utype int dwValueType, @void pValue, str psz, utype int csz;
stub utype int CertRDNValueToStrW -> utype int dwValueType, @void pValue, @void psz, utype int csz;
stub int CertRegisterPhysicalStore -> @void pvSystemStore, utype int dwFlags, @void pwszStoreName, @void pStoreInfo, @void pvReserved;
stub int CertRegisterSystemStore -> @void pvSystemStore, utype int dwFlags, @void pStoreInfo, @void pvReserved;
stub int CertRemoveEnhancedKeyUsageIdentifier -> @void pCertContext, str pszUsageIdentifier;
stub void CertRemoveStoreFromCollection -> @void hCollectionStore, @void hSiblingStore;
stub int CertResyncCertificateChainEngine -> @void hChainEngine;
stub int CertRetrieveLogoOrBiometricInfo -> @void pCertContext, str lpszLogoOrBiometricType, utype int dwRetrievalFlags, utype int dwTimeout, utype int dwFlags, @void pvReserved, @void ppbData, @int pcbData, @void ppwszMimeType;
stub int CertSaveStore -> @void hCertStore, utype int dwEncodingType, utype int dwSaveAs, utype int dwSaveTo, @void pvSaveToPara, utype int dwFlags;
stub int CertSelectCertificateChains -> @void pSelectionContext, utype int dwFlags, @void pChainParameters, utype int cCriteria, @void rgpCriteria, @void hStore, @int pcSelection, @void pprgpSelection;
stub int CertSerializeCRLStoreElement -> @void pCrlContext, utype int dwFlags, @char pbElement, @int pcbElement;
stub int CertSerializeCTLStoreElement -> @void pCtlContext, utype int dwFlags, @char pbElement, @int pcbElement;
stub int CertSerializeCertificateStoreElement -> @void pCertContext, utype int dwFlags, @char pbElement, @int pcbElement;
stub int CertSetCRLContextProperty -> @void pCrlContext, utype int dwPropId, utype int dwFlags, @void pvData;
stub int CertSetCTLContextProperty -> @void pCtlContext, utype int dwPropId, utype int dwFlags, @void pvData;
stub int CertSetCertificateContextPropertiesFromCTLEntry -> @void pCertContext, @void pCtlEntry, utype int dwFlags;
stub int CertSetCertificateContextProperty -> @void pCertContext, utype int dwPropId, utype int dwFlags, @void pvData;
stub int CertSetEnhancedKeyUsage -> @void pCertContext, @void pUsage;
stub int CertSetStoreProperty -> @void hCertStore, utype int dwPropId, utype int dwFlags, @void pvData;
stub int CertStrToNameA -> utype int dwCertEncodingType, str pszX500, utype int dwStrType, @void pvReserved, @char pbEncoded, @int pcbEncoded, @void ppszError;
stub int CertStrToNameW -> utype int dwCertEncodingType, @void pszX500, utype int dwStrType, @void pvReserved, @char pbEncoded, @int pcbEncoded, @void ppszError;
stub int CertUnregisterPhysicalStore -> @void pvSystemStore, utype int dwFlags, @void pwszStoreName;
stub int CertUnregisterSystemStore -> @void pvSystemStore, utype int dwFlags;
stub int CertVerifyCRLRevocation -> utype int dwCertEncodingType, @void pCertId, utype int cCrlInfo, @void rgpCrlInfo;
stub int CertVerifyCRLTimeValidity -> @void pTimeToVerify, @void pCrlInfo;
stub int CertVerifyCTLUsage -> utype int dwEncodingType, utype int dwSubjectType, @void pvSubject, @void pSubjectUsage, utype int dwFlags, @void pVerifyUsagePara, @void pVerifyUsageStatus;
stub int CertVerifyCertificateChainPolicy -> str pszPolicyOID, @void pChainContext, @void pPolicyPara, @void pPolicyStatus;
stub int CertVerifyRevocation -> utype int dwEncodingType, utype int dwRevType, utype int cContext, @void rgpvContext, utype int dwFlags, @void pRevPara, @void pRevStatus;
stub int CertVerifySubjectCertificateContext -> @void pSubject, @void pIssuer, @int pdwFlags;
stub int CertVerifyTimeValidity -> @void pTimeToVerify, @void pCertInfo;
stub int CertVerifyValidityNesting -> @void pSubjectInfo, @void pIssuerInfo;
stub int CryptAcquireCertificatePrivateKey -> @void pCert, utype int dwFlags, @void pvParameters, @longlong phCryptProvOrNCryptKey, @int pdwKeySpec, @int pfCallerFreeProvOrNCryptKey;
stub int CryptBinaryToStringA -> @char pbBinary, utype int cbBinary, utype int dwFlags, str pszString, @int pcchString;
stub int CryptBinaryToStringW -> @char pbBinary, utype int cbBinary, utype int dwFlags, @void pszString, @int pcchString;
stub int CryptCloseAsyncHandle -> @void hAsync;
stub int CryptCreateAsyncHandle -> utype int dwFlags, @void phAsync;
stub int CryptCreateKeyIdentifierFromCSP -> utype int dwCertEncodingType, str pszPubKeyOID, @void pPubKeyStruc, utype int cbPubKeyStruc, utype int dwFlags, @void pvReserved, @char pbHash, @int pcbHash;
stub int CryptDecodeMessage -> utype int dwMsgTypeFlags, @void pDecryptPara, @void pVerifyPara, utype int dwSignerIndex, @char pbEncodedBlob, utype int cbEncodedBlob, utype int dwPrevInnerContentType, @int pdwMsgType, @int pdwInnerContentType, @char pbDecoded, @int pcbDecoded, @void ppXchgCert, @void ppSignerCert;
stub int CryptDecodeObject -> utype int dwCertEncodingType, str lpszStructType, @char pbEncoded, utype int cbEncoded, utype int dwFlags, @void pvStructInfo, @int pcbStructInfo;
stub int CryptDecodeObjectEx -> utype int dwCertEncodingType, str lpszStructType, @char pbEncoded, utype int cbEncoded, utype int dwFlags, @void pDecodePara, @void pvStructInfo, @int pcbStructInfo;
stub int CryptDecryptAndVerifyMessageSignature -> @void pDecryptPara, @void pVerifyPara, utype int dwSignerIndex, @char pbEncryptedBlob, utype int cbEncryptedBlob, @char pbDecrypted, @int pcbDecrypted, @void ppXchgCert, @void ppSignerCert;
stub int CryptDecryptMessage -> @void pDecryptPara, @char pbEncryptedBlob, utype int cbEncryptedBlob, @char pbDecrypted, @int pcbDecrypted, @void ppXchgCert;
stub int CryptEncodeObject -> utype int dwCertEncodingType, str lpszStructType, @void pvStructInfo, @char pbEncoded, @int pcbEncoded;
stub int CryptEncodeObjectEx -> utype int dwCertEncodingType, str lpszStructType, @void pvStructInfo, utype int dwFlags, @void pEncodePara, @void pvEncoded, @int pcbEncoded;
stub int CryptEncryptMessage -> @void pEncryptPara, utype int cRecipientCert, @void rgpRecipientCert, @char pbToBeEncrypted, utype int cbToBeEncrypted, @char pbEncryptedBlob, @int pcbEncryptedBlob;
stub int CryptEnumKeyIdentifierProperties -> @void pKeyIdentifier, utype int dwPropId, utype int dwFlags, @void pwszComputerName, @void pvReserved, @void pvArg, @func pfnEnum;
stub int CryptEnumOIDFunction -> utype int dwEncodingType, str pszFuncName, str pszOID, utype int dwFlags, @void pvArg, @func pfnEnumOIDFunc;
stub int CryptEnumOIDInfo -> utype int dwGroupId, utype int dwFlags, @void pvArg, @func pfnEnumOIDInfo;
stub int CryptExportPKCS8 -> utype longlong hCryptProv, utype int dwKeySpec, str pszPrivateKeyObjId, utype int dwFlags, @void pvAuxInfo, @char pbPrivateKeyBlob, @int pcbPrivateKeyBlob;
stub int CryptExportPublicKeyInfo -> utype longlong hCryptProvOrNCryptKey, utype int dwKeySpec, utype int dwCertEncodingType, @void pInfo, @int pcbInfo;
stub int CryptExportPublicKeyInfoEx -> utype longlong hCryptProvOrNCryptKey, utype int dwKeySpec, utype int dwCertEncodingType, str pszPublicKeyObjId, utype int dwFlags, @void pvAuxInfo, @void pInfo, @int pcbInfo;
stub int CryptExportPublicKeyInfoFromBCryptKeyHandle -> @void hBCryptKey, utype int dwCertEncodingType, str pszPublicKeyObjId, utype int dwFlags, @void pvAuxInfo, @void pInfo, @int pcbInfo;
stub int CryptFindCertificateKeyProvInfo -> @void pCert, utype int dwFlags, @void pvReserved;
stub @void CryptFindLocalizedName -> @void pwszCryptName;
stub @void CryptFindOIDInfo -> utype int dwKeyType, @void pvKey, utype int dwGroupId;
stub int CryptFormatObject -> utype int dwCertEncodingType, utype int dwFormatType, utype int dwFormatStrType, @void pFormatStruct, str lpszStructType, @char pbEncoded, utype int cbEncoded, @void pbFormat, @int pcbFormat;
stub int CryptFreeOIDFunctionAddress -> @void hFuncAddr, utype int dwFlags;
stub int CryptGetAsyncParam -> @void hAsync, str pszParamOid, @void ppvParam, @void ppfnFree;
stub int CryptGetDefaultOIDDllList -> @void hFuncSet, utype int dwEncodingType, @void pwszDllList, @int pcchDllList;
stub int CryptGetDefaultOIDFunctionAddress -> @void hFuncSet, utype int dwEncodingType, @void pwszDll, utype int dwFlags, @void ppvFuncAddr, @void phFuncAddr;
stub int CryptGetKeyIdentifierProperty -> @void pKeyIdentifier, utype int dwPropId, utype int dwFlags, @void pwszComputerName, @void pvReserved, @void pvData, @int pcbData;
stub @void CryptGetMessageCertificates -> utype int dwMsgAndCertEncodingType, utype longlong hCryptProv, utype int dwFlags, @char pbSignedBlob, utype int cbSignedBlob;
stub int CryptGetMessageSignerCount -> utype int dwMsgEncodingType, @char pbSignedBlob, utype int cbSignedBlob;
stub int CryptGetOIDFunctionAddress -> @void hFuncSet, utype int dwEncodingType, str pszOID, utype int dwFlags, @void ppvFuncAddr, @void phFuncAddr;
stub int CryptGetOIDFunctionValue -> utype int dwEncodingType, str pszFuncName, str pszOID, @void pwszValueName, @int pdwValueType, @char pbValueData, @int pcbValueData;
stub int CryptHashCertificate -> utype longlong hCryptProv, utype int Algid, utype int dwFlags, @char pbEncoded, utype int cbEncoded, @char pbComputedHash, @int pcbComputedHash;
stub int CryptHashCertificate2 -> @void pwszCNGHashAlgid, utype int dwFlags, @void pvReserved, @char pbEncoded, utype int cbEncoded, @char pbComputedHash, @int pcbComputedHash;
stub int CryptHashMessage -> @void pHashPara, int fDetachedHash, utype int cToBeHashed, @void rgpbToBeHashed, @int rgcbToBeHashed, @char pbHashedBlob, @int pcbHashedBlob, @char pbComputedHash, @int pcbComputedHash;
stub int CryptHashPublicKeyInfo -> utype longlong hCryptProv, utype int Algid, utype int dwFlags, utype int dwCertEncodingType, @void pInfo, @char pbComputedHash, @int pcbComputedHash;
stub int CryptHashToBeSigned -> utype longlong hCryptProv, utype int dwCertEncodingType, @char pbEncoded, utype int cbEncoded, @char pbComputedHash, @int pcbComputedHash;
stub int CryptImportPublicKeyInfo -> utype longlong hCryptProv, utype int dwCertEncodingType, @void pInfo, @longlong phKey;
stub int CryptImportPublicKeyInfoEx -> utype longlong hCryptProv, utype int dwCertEncodingType, @void pInfo, utype int aiKeyAlg, utype int dwFlags, @void pvAuxInfo, @longlong phKey;
stub int CryptImportPublicKeyInfoEx2 -> utype int dwCertEncodingType, @void pInfo, utype int dwFlags, @void pvAuxInfo, @void phKey;
stub @void CryptInitOIDFunctionSet -> str pszFuncName, utype int dwFlags;
stub int CryptInstallDefaultContext -> utype longlong hCryptProv, utype int dwDefaultType, @void pvDefaultPara, utype int dwFlags, @void pvReserved, @void phDefaultContext;
stub int CryptInstallOIDFunctionAddress -> @void hModule, utype int dwEncodingType, str pszFuncName, utype int cFuncEntry, @void rgFuncEntry, utype int dwFlags;
stub @void CryptMemAlloc -> utype int cbSize;
stub void CryptMemFree -> @void pv;
stub @void CryptMemRealloc -> @void pv, utype int cbSize;
stub utype int CryptMsgCalculateEncodedLength -> utype int dwMsgEncodingType, utype int dwFlags, utype int dwMsgType, @void pvMsgEncodeInfo, str pszInnerContentObjID, utype int cbData;
stub int CryptMsgClose -> @void hCryptMsg;
stub int CryptMsgControl -> @void hCryptMsg, utype int dwFlags, utype int dwCtrlType, @void pvCtrlPara;
stub int CryptMsgCountersign -> @void hCryptMsg, utype int dwIndex, utype int cCountersigners, @void rgCountersigners;
stub int CryptMsgCountersignEncoded -> utype int dwEncodingType, @char pbSignerInfo, utype int cbSignerInfo, utype int cCountersigners, @void rgCountersigners, @char pbCountersignature, @int pcbCountersignature;
stub @void CryptMsgDuplicate -> @void hCryptMsg;
stub int CryptMsgEncodeAndSignCTL -> utype int dwMsgEncodingType, @void pCtlInfo, @void pSignInfo, utype int dwFlags, @char pbEncoded, @int pcbEncoded;
stub int CryptMsgGetAndVerifySigner -> @void hCryptMsg, utype int cSignerStore, @void rghSignerStore, utype int dwFlags, @void ppSigner, @int pdwSignerIndex;
stub int CryptMsgGetParam -> @void hCryptMsg, utype int dwParamType, utype int dwIndex, @void pvData, @int pcbData;
stub @void CryptMsgOpenToDecode -> utype int dwMsgEncodingType, utype int dwFlags, utype int dwMsgType, utype longlong hCryptProv, @void pRecipientInfo, @void pStreamInfo;
stub @void CryptMsgOpenToEncode -> utype int dwMsgEncodingType, utype int dwFlags, utype int dwMsgType, @void pvMsgEncodeInfo, str pszInnerContentObjID, @void pStreamInfo;
stub int CryptMsgSignCTL -> utype int dwMsgEncodingType, @char pbCtlContent, utype int cbCtlContent, @void pSignInfo, utype int dwFlags, @char pbEncoded, @int pcbEncoded;
stub int CryptMsgUpdate -> @void hCryptMsg, @char pbData, utype int cbData, int fFinal;
stub int CryptMsgVerifyCountersignatureEncoded -> utype longlong hCryptProv, utype int dwEncodingType, @char pbSignerInfo, utype int cbSignerInfo, @char pbSignerInfoCountersignature, utype int cbSignerInfoCountersignature, @void pciCountersigner;
stub int CryptMsgVerifyCountersignatureEncodedEx -> utype longlong hCryptProv, utype int dwEncodingType, @char pbSignerInfo, utype int cbSignerInfo, @char pbSignerInfoCountersignature, utype int cbSignerInfoCountersignature, utype int dwSignerType, @void pvSigner, utype int dwFlags, @void pvExtra;
stub int CryptProtectData -> @void pDataIn, @void szDataDescr, @void pOptionalEntropy, @void pvReserved, @void pPromptStruct, utype int dwFlags, @void pDataOut;
stub int CryptProtectMemory -> @void pDataIn, utype int cbDataIn, utype int dwFlags;
stub int CryptQueryObject -> utype int dwObjectType, @void pvObject, utype int dwExpectedContentTypeFlags, utype int dwExpectedFormatTypeFlags, utype int dwFlags, @int pdwMsgAndCertEncodingType, @int pdwContentType, @int pdwFormatType, @void phCertStore, @void phMsg, @void ppvContext;
stub int CryptRegisterDefaultOIDFunction -> utype int dwEncodingType, str pszFuncName, utype int dwIndex, @void pwszDll;
stub int CryptRegisterOIDFunction -> utype int dwEncodingType, str pszFuncName, str pszOID, @void pwszDll, str pszOverrideFuncName;
stub int CryptRegisterOIDInfo -> @void pInfo, utype int dwFlags;
stub int CryptRetrieveTimeStamp -> @void wszUrl, utype int dwRetrievalFlags, utype int dwTimeout, str pszHashId, @void pPara, @char pbData, utype int cbData, @void ppTsContext, @void ppTsSigner, @void phStore;
stub int CryptSetAsyncParam -> @void hAsync, str pszParamOid, @void pvParam, @func pfnFree;
stub int CryptSetKeyIdentifierProperty -> @void pKeyIdentifier, utype int dwPropId, utype int dwFlags, @void pwszComputerName, @void pvReserved, @void pvData;
stub int CryptSetOIDFunctionValue -> utype int dwEncodingType, str pszFuncName, str pszOID, @void pwszValueName, utype int dwValueType, @char pbValueData, utype int cbValueData;
stub int CryptSignAndEncodeCertificate -> utype longlong hCryptProvOrNCryptKey, utype int dwKeySpec, utype int dwCertEncodingType, str lpszStructType, @void pvStructInfo, @void pSignatureAlgorithm, @void pvHashAuxInfo, @char pbEncoded, @int pcbEncoded;
stub int CryptSignAndEncryptMessage -> @void pSignPara, @void pEncryptPara, utype int cRecipientCert, @void rgpRecipientCert, @char pbToBeSignedAndEncrypted, utype int cbToBeSignedAndEncrypted, @char pbSignedAndEncryptedBlob, @int pcbSignedAndEncryptedBlob;
stub int CryptSignCertificate -> utype longlong hCryptProvOrNCryptKey, utype int dwKeySpec, utype int dwCertEncodingType, @char pbEncodedToBeSigned, utype int cbEncodedToBeSigned, @void pSignatureAlgorithm, @void pvHashAuxInfo, @char pbSignature, @int pcbSignature;
stub int CryptSignMessage -> @void pSignPara, int fDetachedSignature, utype int cToBeSigned, @void rgpbToBeSigned, @int rgcbToBeSigned, @char pbSignedBlob, @int pcbSignedBlob;
stub int CryptSignMessageWithKey -> @void pSignPara, @char pbToBeSigned, utype int cbToBeSigned, @char pbSignedBlob, @int pcbSignedBlob;
stub int CryptStringToBinaryA -> str pszString, utype int cchString, utype int dwFlags, @char pbBinary, @int pcbBinary, @int pdwSkip, @int pdwFlags;
stub int CryptStringToBinaryW -> @void pszString, utype int cchString, utype int dwFlags, @char pbBinary, @int pcbBinary, @int pdwSkip, @int pdwFlags;
stub int CryptUninstallDefaultContext -> @void hDefaultContext, utype int dwFlags, @void pvReserved;
stub int CryptUnprotectData -> @void pDataIn, @void ppszDataDescr, @void pOptionalEntropy, @void pvReserved, @void pPromptStruct, utype int dwFlags, @void pDataOut;
stub int CryptUnprotectMemory -> @void pDataIn, utype int cbDataIn, utype int dwFlags;
stub int CryptUnregisterDefaultOIDFunction -> utype int dwEncodingType, str pszFuncName, @void pwszDll;
stub int CryptUnregisterOIDFunction -> utype int dwEncodingType, str pszFuncName, str pszOID;
stub int CryptUnregisterOIDInfo -> @void pInfo;
stub int CryptUpdateProtectedState -> @void pOldSid, @void pwszOldPassword, utype int dwFlags, @int pdwSuccessCount, @int pdwFailureCount;
stub int CryptVerifyCertificateSignature -> utype longlong hCryptProv, utype int dwCertEncodingType, @char pbEncoded, utype int cbEncoded, @void pPublicKey;
stub int CryptVerifyCertificateSignatureEx -> utype longlong hCryptProv, utype int dwCertEncodingType, utype int dwSubjectType, @void pvSubject, utype int dwIssuerType, @void pvIssuer, utype int dwFlags, @void pvExtra;
stub int CryptVerifyDetachedMessageHash -> @void pHashPara, @char pbDetachedHashBlob, utype int cbDetachedHashBlob, utype int cToBeHashed, @void rgpbToBeHashed, @int rgcbToBeHashed, @char pbComputedHash, @int pcbComputedHash;
stub int CryptVerifyDetachedMessageSignature -> @void pVerifyPara, utype int dwSignerIndex, @char pbDetachedSignBlob, utype int cbDetachedSignBlob, utype int cToBeSigned, @void rgpbToBeSigned, @int rgcbToBeSigned, @void ppSignerCert;
stub int CryptVerifyMessageHash -> @void pHashPara, @char pbHashedBlob, utype int cbHashedBlob, @char pbToBeHashed, @int pcbToBeHashed, @char pbComputedHash, @int pcbComputedHash;
stub int CryptVerifyMessageSignature -> @void pVerifyPara, utype int dwSignerIndex, @char pbSignedBlob, utype int cbSignedBlob, @char pbDecoded, @int pcbDecoded, @void ppSignerCert;
stub int CryptVerifyMessageSignatureWithKey -> @void pVerifyPara, @void pPublicKeyInfo, @char pbSignedBlob, utype int cbSignedBlob, @char pbDecoded, @int pcbDecoded;
stub int CryptVerifyTimeStampSignature -> @char pbTSContentInfo, utype int cbTSContentInfo, @char pbData, utype int cbData, @void hAdditionalStore, @void ppTsContext, @void ppTsSigner, @void phStore;
stub int PFXExportCertStore -> @void hStore, @void pPFX, @void szPassword, utype int dwFlags;
stub int PFXExportCertStoreEx -> @void hStore, @void pPFX, @void szPassword, @void pvPara, utype int dwFlags;
stub @void PFXImportCertStore -> @void pPFX, @void szPassword, utype int dwFlags;
stub int PFXIsPFXBlob -> @void pPFX;
stub int PFXVerifyPassword -> @void pPFX, @void szPassword, utype int dwFlags;

!!! Declared by the headers, but with a type the language cannot write:
!!!   CryptImportPKCS8

!!! No prototype in the headers this build saw. They are here so the
!!! list is complete; uncomment and give the real signature to use one.
!!! CryptImportPKCS8
