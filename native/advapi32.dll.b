!~
~  native/advapi32.dll.b: the advapi32.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/advapi32.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/advapi32.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `advapi32.dll.b` is what produces `meta/advapi32.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\advapi32.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per advapi32.dll export that the headers declare. The
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
!!! 413 declarations here, 0 kept from the hand-checked list above, 53 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub int AbortSystemShutdownA -> str lpMachineName;
stub int AbortSystemShutdownW -> @void lpMachineName;
stub int AccessCheck -> @void pSecurityDescriptor, @void ClientToken, utype int DesiredAccess, @void GenericMapping, @void PrivilegeSet, @int PrivilegeSetLength, @int GrantedAccess, @int AccessStatus;
stub int AccessCheckAndAuditAlarmA -> str SubsystemName, @void HandleId, str ObjectTypeName, str ObjectName, @void SecurityDescriptor, utype int DesiredAccess, @void GenericMapping, int ObjectCreation, @int GrantedAccess, @int AccessStatus, @int pfGenerateOnClose;
stub int AccessCheckAndAuditAlarmW -> @void SubsystemName, @void HandleId, @void ObjectTypeName, @void ObjectName, @void SecurityDescriptor, utype int DesiredAccess, @void GenericMapping, int ObjectCreation, @int GrantedAccess, @int AccessStatus, @int pfGenerateOnClose;
stub int AccessCheckByType -> @void pSecurityDescriptor, @void PrincipalSelfSid, @void ClientToken, utype int DesiredAccess, @void ObjectTypeList, utype int ObjectTypeListLength, @void GenericMapping, @void PrivilegeSet, @int PrivilegeSetLength, @int GrantedAccess, @int AccessStatus;
stub int AccessCheckByTypeResultList -> @void pSecurityDescriptor, @void PrincipalSelfSid, @void ClientToken, utype int DesiredAccess, @void ObjectTypeList, utype int ObjectTypeListLength, @void GenericMapping, @void PrivilegeSet, @int PrivilegeSetLength, @int GrantedAccessList, @int AccessStatusList;
stub int AddAccessAllowedAce -> @void pAcl, utype int dwAceRevision, utype int AccessMask, @void pSid;
stub int AddAccessAllowedAceEx -> @void pAcl, utype int dwAceRevision, utype int AceFlags, utype int AccessMask, @void pSid;
stub int AddAccessAllowedObjectAce -> @void pAcl, utype int dwAceRevision, utype int AceFlags, utype int AccessMask, @void ObjectTypeGuid, @void InheritedObjectTypeGuid, @void pSid;
stub int AddAccessDeniedAce -> @void pAcl, utype int dwAceRevision, utype int AccessMask, @void pSid;
stub int AddAccessDeniedAceEx -> @void pAcl, utype int dwAceRevision, utype int AceFlags, utype int AccessMask, @void pSid;
stub int AddAccessDeniedObjectAce -> @void pAcl, utype int dwAceRevision, utype int AceFlags, utype int AccessMask, @void ObjectTypeGuid, @void InheritedObjectTypeGuid, @void pSid;
stub int AddAce -> @void pAcl, utype int dwAceRevision, utype int dwStartingAceIndex, @void pAceList, utype int nAceListLength;
stub int AddAuditAccessAce -> @void pAcl, utype int dwAceRevision, utype int dwAccessMask, @void pSid, int bAuditSuccess, int bAuditFailure;
stub int AddAuditAccessAceEx -> @void pAcl, utype int dwAceRevision, utype int AceFlags, utype int dwAccessMask, @void pSid, int bAuditSuccess, int bAuditFailure;
stub int AddAuditAccessObjectAce -> @void pAcl, utype int dwAceRevision, utype int AceFlags, utype int AccessMask, @void ObjectTypeGuid, @void InheritedObjectTypeGuid, @void pSid, int bAuditSuccess, int bAuditFailure;
stub int AddConditionalAce -> @void pAcl, utype int dwAceRevision, utype int AceFlags, utype char AceType, utype int AccessMask, @void pSid, @void ConditionStr, @int ReturnLength;
stub int AddMandatoryAce -> @void pAcl, utype int dwAceRevision, utype int AceFlags, utype int MandatoryPolicy, @void pLabelSid;
stub utype int AddUsersToEncryptedFile -> @void lpFileName, @void pUsers;
stub int AdjustTokenGroups -> @void TokenHandle, int ResetToDefault, @void NewState, utype int BufferLength, @void PreviousState, @int ReturnLength;
stub int AdjustTokenPrivileges -> @void TokenHandle, int DisableAllPrivileges, @void NewState, utype int BufferLength, @void PreviousState, @int ReturnLength;
stub int AllocateAndInitializeSid -> @void pIdentifierAuthority, utype char nSubAuthorityCount, utype int nSubAuthority0, utype int nSubAuthority1, utype int nSubAuthority2, utype int nSubAuthority3, utype int nSubAuthority4, utype int nSubAuthority5, utype int nSubAuthority6, utype int nSubAuthority7, @void pSid;
stub int AllocateLocallyUniqueId -> @void Luid;
stub int AreAllAccessesGranted -> utype int GrantedAccess, utype int DesiredAccess;
stub int AreAnyAccessesGranted -> utype int GrantedAccess, utype int DesiredAccess;
stub utype char AuditComputeEffectivePolicyBySid -> @void pSid, @void pSubCategoryGuids, utype int PolicyCount, @void ppAuditPolicy;
stub utype char AuditComputeEffectivePolicyByToken -> @void hTokenHandle, @void pSubCategoryGuids, utype int PolicyCount, @void ppAuditPolicy;
stub utype char AuditEnumerateCategories -> @void ppAuditCategoriesArray, @int pCountReturned;
stub utype char AuditEnumeratePerUserPolicy -> @void ppAuditSidArray;
stub utype char AuditEnumerateSubCategories -> @void pAuditCategoryGuid, utype char bRetrieveAllSubCategories, @void ppAuditSubCategoriesArray, @int pCountReturned;
stub void AuditFree -> @void Buffer;
stub utype char AuditLookupCategoryIdFromCategoryGuid -> @void pAuditCategoryGuid, @void pAuditCategoryId;
stub utype char AuditLookupCategoryNameA -> @void pAuditCategoryGuid, @void ppszCategoryName;
stub utype char AuditLookupCategoryNameW -> @void pAuditCategoryGuid, @void ppszCategoryName;
stub utype char AuditLookupSubCategoryNameA -> @void pAuditSubCategoryGuid, @void ppszSubCategoryName;
stub utype char AuditLookupSubCategoryNameW -> @void pAuditSubCategoryGuid, @void ppszSubCategoryName;
stub utype char AuditQueryGlobalSaclA -> str ObjectTypeName, @void Acl;
stub utype char AuditQueryGlobalSaclW -> @void ObjectTypeName, @void Acl;
stub utype char AuditQueryPerUserPolicy -> @void pSid, @void pSubCategoryGuids, utype int PolicyCount, @void ppAuditPolicy;
stub utype char AuditQuerySecurity -> utype int SecurityInformation, @void ppSecurityDescriptor;
stub utype char AuditQuerySystemPolicy -> @void pSubCategoryGuids, utype int PolicyCount, @void ppAuditPolicy;
stub utype char AuditSetGlobalSaclA -> str ObjectTypeName, @void Acl;
stub utype char AuditSetGlobalSaclW -> @void ObjectTypeName, @void Acl;
stub utype char AuditSetPerUserPolicy -> @void pSid, @void pAuditPolicy, utype int PolicyCount;
stub utype char AuditSetSecurity -> utype int SecurityInformation, @void pSecurityDescriptor;
stub utype char AuditSetSystemPolicy -> @void pAuditPolicy, utype int PolicyCount;
stub int BackupEventLogA -> @void hEventLog, str lpBackupFileName;
stub int BackupEventLogW -> @void hEventLog, @void lpBackupFileName;
stub void BuildImpersonateTrusteeA -> @void pTrustee, @void pImpersonateTrustee;
stub void BuildImpersonateTrusteeW -> @void pTrustee, @void pImpersonateTrustee;
stub utype int BuildSecurityDescriptorA -> @void pOwner, @void pGroup, utype int cCountOfAccessEntries, @void pListOfAccessEntries, utype int cCountOfAuditEntries, @void pListOfAuditEntries, @void pOldSD, @int pSizeNewSD, @void pNewSD;
stub utype int BuildSecurityDescriptorW -> @void pOwner, @void pGroup, utype int cCountOfAccessEntries, @void pListOfAccessEntries, utype int cCountOfAuditEntries, @void pListOfAuditEntries, @void pOldSD, @int pSizeNewSD, @void pNewSD;
stub void BuildTrusteeWithNameA -> @void pTrustee, str pName;
stub void BuildTrusteeWithNameW -> @void pTrustee, @void pName;
stub void BuildTrusteeWithObjectsAndSidA -> @void pTrustee, @void pObjSid, @void pObjectGuid, @void pInheritedObjectGuid, @void pSid;
stub void BuildTrusteeWithObjectsAndSidW -> @void pTrustee, @void pObjSid, @void pObjectGuid, @void pInheritedObjectGuid, @void pSid;
stub void BuildTrusteeWithSidA -> @void pTrustee, @void pSid;
stub void BuildTrusteeWithSidW -> @void pTrustee, @void pSid;
stub int ChangeServiceConfig2A -> @void hService, utype int dwInfoLevel, @void lpInfo;
stub int ChangeServiceConfig2W -> @void hService, utype int dwInfoLevel, @void lpInfo;
stub int ChangeServiceConfigA -> @void hService, utype int dwServiceType, utype int dwStartType, utype int dwErrorControl, str lpBinaryPathName, str lpLoadOrderGroup, @int lpdwTagId, str lpDependencies, str lpServiceStartName, str lpPassword, str lpDisplayName;
stub int ChangeServiceConfigW -> @void hService, utype int dwServiceType, utype int dwStartType, utype int dwErrorControl, @void lpBinaryPathName, @void lpLoadOrderGroup, @int lpdwTagId, @void lpDependencies, @void lpServiceStartName, @void lpPassword, @void lpDisplayName;
stub utype int CheckForHiberboot -> @char pHiberboot, utype char bClearFlag;
stub int CheckTokenMembership -> @void TokenHandle, @void SidToCheck, @int IsMember;
stub int ClearEventLogA -> @void hEventLog, str lpBackupFileName;
stub int ClearEventLogW -> @void hEventLog, @void lpBackupFileName;
stub void CloseEncryptedFileRaw -> @void pvContext;
stub int CloseEventLog -> @void hEventLog;
stub int CloseServiceHandle -> @void hSCObject;
stub int ControlService -> @void hService, utype int dwControl, @void lpServiceStatus;
stub int ControlServiceExA -> @void hService, utype int dwControl, utype int dwInfoLevel, @void pControlParams;
stub int ControlServiceExW -> @void hService, utype int dwControl, utype int dwInfoLevel, @void pControlParams;
stub int ConvertToAutoInheritPrivateObjectSecurity -> @void ParentDescriptor, @void CurrentSecurityDescriptor, @void NewSecurityDescriptor, @void ObjectType, utype char IsDirectoryObject, @void GenericMapping;
stub int CopySid -> utype int nDestinationSidLength, @void pDestinationSid, @void pSourceSid;
stub int CreatePrivateObjectSecurity -> @void ParentDescriptor, @void CreatorDescriptor, @void NewDescriptor, int IsDirectoryObject, @void Token, @void GenericMapping;
stub int CreatePrivateObjectSecurityEx -> @void ParentDescriptor, @void CreatorDescriptor, @void NewDescriptor, @void ObjectType, int IsContainerObject, utype int AutoInheritFlags, @void Token, @void GenericMapping;
stub int CreatePrivateObjectSecurityWithMultipleInheritance -> @void ParentDescriptor, @void CreatorDescriptor, @void NewDescriptor, @void ObjectTypes, utype int GuidCount, int IsContainerObject, utype int AutoInheritFlags, @void Token, @void GenericMapping;
stub int CreateProcessAsUserA -> @void hToken, str lpApplicationName, str lpCommandLine, @void lpProcessAttributes, @void lpThreadAttributes, int bInheritHandles, utype int dwCreationFlags, @void lpEnvironment, str lpCurrentDirectory, @void lpStartupInfo, @void lpProcessInformation;
stub int CreateProcessAsUserW -> @void hToken, @void lpApplicationName, @void lpCommandLine, @void lpProcessAttributes, @void lpThreadAttributes, int bInheritHandles, utype int dwCreationFlags, @void lpEnvironment, @void lpCurrentDirectory, @void lpStartupInfo, @void lpProcessInformation;
stub int CreateProcessWithLogonW -> @void lpUsername, @void lpDomain, @void lpPassword, utype int dwLogonFlags, @void lpApplicationName, @void lpCommandLine, utype int dwCreationFlags, @void lpEnvironment, @void lpCurrentDirectory, @void lpStartupInfo, @void lpProcessInformation;
stub int CreateProcessWithTokenW -> @void hToken, utype int dwLogonFlags, @void lpApplicationName, @void lpCommandLine, utype int dwCreationFlags, @void lpEnvironment, @void lpCurrentDirectory, @void lpStartupInfo, @void lpProcessInformation;
stub int CreateRestrictedToken -> @void ExistingTokenHandle, utype int Flags, utype int DisableSidCount, @void SidsToDisable, utype int DeletePrivilegeCount, @void PrivilegesToDelete, utype int RestrictedSidCount, @void SidsToRestrict, @void NewTokenHandle;
stub @void CreateServiceA -> @void hSCManager, str lpServiceName, str lpDisplayName, utype int dwDesiredAccess, utype int dwServiceType, utype int dwStartType, utype int dwErrorControl, str lpBinaryPathName, str lpLoadOrderGroup, @int lpdwTagId, str lpDependencies, str lpServiceStartName, str lpPassword;
stub @void CreateServiceW -> @void hSCManager, @void lpServiceName, @void lpDisplayName, utype int dwDesiredAccess, utype int dwServiceType, utype int dwStartType, utype int dwErrorControl, @void lpBinaryPathName, @void lpLoadOrderGroup, @int lpdwTagId, @void lpDependencies, @void lpServiceStartName, @void lpPassword;
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
stub int CveEventWrite -> @void CveId, @void AdditionalDetails;
stub int DecryptFileA -> str lpFileName, utype int dwReserved;
stub int DecryptFileW -> @void lpFileName, utype int dwReserved;
stub int DeleteAce -> @void pAcl, utype int dwAceIndex;
stub int DeleteService -> @void hService;
stub int DeregisterEventSource -> @void hEventLog;
stub int DestroyPrivateObjectSecurity -> @void ObjectDescriptor;
stub utype int DuplicateEncryptionInfoFile -> @void SrcFileName, @void DstFileName, utype int dwCreationDistribution, utype int dwAttributes, @void lpSecurityAttributes;
stub int EncryptFileA -> str lpFileName;
stub int EncryptFileW -> @void lpFileName;
stub int EncryptionDisable -> @void DirPath, int Disable;
stub int EnumDependentServicesA -> @void hService, utype int dwServiceState, @void lpServices, utype int cbBufSize, @int pcbBytesNeeded, @int lpServicesReturned;
stub int EnumDependentServicesW -> @void hService, utype int dwServiceState, @void lpServices, utype int cbBufSize, @int pcbBytesNeeded, @int lpServicesReturned;
stub utype int EnumDynamicTimeZoneInformation -> utype int dwIndex, @void lpTimeZoneInformation;
stub int EnumServicesStatusA -> @void hSCManager, utype int dwServiceType, utype int dwServiceState, @void lpServices, utype int cbBufSize, @int pcbBytesNeeded, @int lpServicesReturned, @int lpResumeHandle;
stub int EnumServicesStatusW -> @void hSCManager, utype int dwServiceType, utype int dwServiceState, @void lpServices, utype int cbBufSize, @int pcbBytesNeeded, @int lpServicesReturned, @int lpResumeHandle;
stub int EqualDomainSid -> @void pSid1, @void pSid2, @int pfEqual;
stub int EqualPrefixSid -> @void pSid1, @void pSid2;
stub int EqualSid -> @void pSid1, @void pSid2;
stub int FileEncryptionStatusA -> str lpFileName, @int lpStatus;
stub int FileEncryptionStatusW -> @void lpFileName, @int lpStatus;
stub int FindFirstFreeAce -> @void pAcl, @void pAce;
stub void FreeEncryptionCertificateHashList -> @void pHashes;
stub utype int FreeInheritedFromArray -> @void pInheritArray, utype int AceCnt, @void pfnArray;
stub @void FreeSid -> @void pSid;
stub int GetAce -> @void pAcl, utype int dwAceIndex, @void pAce;
stub utype int GetAuditedPermissionsFromAclA -> @void pacl, @void pTrustee, @int pSuccessfulAuditedRights, @int pFailedAuditRights;
stub utype int GetAuditedPermissionsFromAclW -> @void pacl, @void pTrustee, @int pSuccessfulAuditedRights, @int pFailedAuditRights;
stub int GetCurrentHwProfileA -> @void lpHwProfileInfo;
stub int GetCurrentHwProfileW -> @void lpHwProfileInfo;
stub utype int GetDynamicTimeZoneInformationEffectiveYears -> @void lpTimeZoneInformation, @int FirstYear, @int LastYear;
stub utype int GetEffectiveRightsFromAclA -> @void pacl, @void pTrustee, @int pAccessRights;
stub utype int GetEffectiveRightsFromAclW -> @void pacl, @void pTrustee, @int pAccessRights;
stub int GetEventLogInformation -> @void hEventLog, utype int dwInfoLevel, @void lpBuffer, utype int cbBufSize, @int pcbBytesNeeded;
stub utype int GetExplicitEntriesFromAclA -> @void pacl, @int pcCountOfExplicitEntries, @void pListOfExplicitEntries;
stub utype int GetExplicitEntriesFromAclW -> @void pacl, @int pcCountOfExplicitEntries, @void pListOfExplicitEntries;
stub int GetFileSecurityA -> str lpFileName, utype int RequestedInformation, @void pSecurityDescriptor, utype int nLength, @int lpnLengthNeeded;
stub int GetFileSecurityW -> @void lpFileName, utype int RequestedInformation, @void pSecurityDescriptor, utype int nLength, @int lpnLengthNeeded;
stub int GetKernelObjectSecurity -> @void Handle, utype int RequestedInformation, @void pSecurityDescriptor, utype int nLength, @int lpnLengthNeeded;
stub utype int GetLengthSid -> @void pSid;
stub @void GetMultipleTrusteeA -> @void pTrustee;
stub @void GetMultipleTrusteeW -> @void pTrustee;
stub int GetNumberOfEventLogRecords -> @void hEventLog, @int NumberOfRecords;
stub int GetOldestEventLogRecord -> @void hEventLog, @int OldestRecord;
stub int GetPrivateObjectSecurity -> @void ObjectDescriptor, utype int SecurityInformation, @void ResultantDescriptor, utype int DescriptorLength, @int ReturnLength;
stub int GetSecurityDescriptorControl -> @void pSecurityDescriptor, @int pControl, @int lpdwRevision;
stub int GetSecurityDescriptorDacl -> @void pSecurityDescriptor, @int lpbDaclPresent, @void pDacl, @int lpbDaclDefaulted;
stub int GetSecurityDescriptorGroup -> @void pSecurityDescriptor, @void pGroup, @int lpbGroupDefaulted;
stub utype int GetSecurityDescriptorLength -> @void pSecurityDescriptor;
stub int GetSecurityDescriptorOwner -> @void pSecurityDescriptor, @void pOwner, @int lpbOwnerDefaulted;
stub utype int GetSecurityDescriptorRMControl -> @void SecurityDescriptor, @char RMControl;
stub int GetSecurityDescriptorSacl -> @void pSecurityDescriptor, @int lpbSaclPresent, @void pSacl, @int lpbSaclDefaulted;
stub int GetServiceDisplayNameA -> @void hSCManager, str lpServiceName, str lpDisplayName, @int lpcchBuffer;
stub int GetServiceDisplayNameW -> @void hSCManager, @void lpServiceName, @void lpDisplayName, @int lpcchBuffer;
stub int GetServiceKeyNameA -> @void hSCManager, str lpDisplayName, str lpServiceName, @int lpcchBuffer;
stub int GetServiceKeyNameW -> @void hSCManager, @void lpDisplayName, @void lpServiceName, @int lpcchBuffer;
stub @void GetSidIdentifierAuthority -> @void pSid;
stub utype int GetSidLengthRequired -> utype char nSubAuthorityCount;
stub @int GetSidSubAuthority -> @void pSid, utype int nSubAuthority;
stub @char GetSidSubAuthorityCount -> @void pSid;
stub str GetTrusteeNameA -> @void pTrustee;
stub @void GetTrusteeNameW -> @void pTrustee;
stub int GetUserNameA -> str lpBuffer, @int pcbBuffer;
stub int GetUserNameW -> @void lpBuffer, @int pcbBuffer;
stub int GetWindowsAccountDomainSid -> @void pSid, @void pDomainSid, @int cbDomainSid;
stub int ImpersonateAnonymousToken -> @void ThreadHandle;
stub int ImpersonateLoggedOnUser -> @void hToken;
stub int ImpersonateNamedPipeClient -> @void hNamedPipe;
stub int InitializeAcl -> @void pAcl, utype int nAclLength, utype int dwAclRevision;
stub int InitializeSecurityDescriptor -> @void pSecurityDescriptor, utype int dwRevision;
stub int InitializeSid -> @void Sid, @void pIdentifierAuthority, utype char nSubAuthorityCount;
stub utype int InitiateShutdownA -> str lpMachineName, str lpMessage, utype int dwGracePeriod, utype int dwShutdownFlags, utype int dwReason;
stub utype int InitiateShutdownW -> @void lpMachineName, @void lpMessage, utype int dwGracePeriod, utype int dwShutdownFlags, utype int dwReason;
stub int InitiateSystemShutdownA -> str lpMachineName, str lpMessage, utype int dwTimeout, int bForceAppsClosed, int bRebootAfterShutdown;
stub int InitiateSystemShutdownExA -> str lpMachineName, str lpMessage, utype int dwTimeout, int bForceAppsClosed, int bRebootAfterShutdown, utype int dwReason;
stub int InitiateSystemShutdownExW -> @void lpMachineName, @void lpMessage, utype int dwTimeout, int bForceAppsClosed, int bRebootAfterShutdown, utype int dwReason;
stub int InitiateSystemShutdownW -> @void lpMachineName, @void lpMessage, utype int dwTimeout, int bForceAppsClosed, int bRebootAfterShutdown;
stub int IsTextUnicode -> @void lpv, int iSize, @int lpiResult;
stub int IsTokenRestricted -> @void TokenHandle;
stub int IsTokenUntrusted -> @void TokenHandle;
stub int IsValidAcl -> @void pAcl;
stub int IsValidSecurityDescriptor -> @void pSecurityDescriptor;
stub int IsValidSid -> @void pSid;
stub @void LockServiceDatabase -> @void hSCManager;
stub int LogonUserA -> str lpszUsername, str lpszDomain, str lpszPassword, utype int dwLogonType, utype int dwLogonProvider, @void phToken;
stub int LogonUserExA -> str lpszUsername, str lpszDomain, str lpszPassword, utype int dwLogonType, utype int dwLogonProvider, @void phToken, @void ppLogonSid, @void ppProfileBuffer, @int pdwProfileLength, @void pQuotaLimits;
stub int LogonUserExW -> @void lpszUsername, @void lpszDomain, @void lpszPassword, utype int dwLogonType, utype int dwLogonProvider, @void phToken, @void ppLogonSid, @void ppProfileBuffer, @int pdwProfileLength, @void pQuotaLimits;
stub int LogonUserW -> @void lpszUsername, @void lpszDomain, @void lpszPassword, utype int dwLogonType, utype int dwLogonProvider, @void phToken;
stub int LookupAccountNameA -> str lpSystemName, str lpAccountName, @void Sid, @int cbSid, str ReferencedDomainName, @int cchReferencedDomainName, @void peUse;
stub int LookupAccountNameW -> @void lpSystemName, @void lpAccountName, @void Sid, @int cbSid, @void ReferencedDomainName, @int cchReferencedDomainName, @void peUse;
stub int LookupAccountSidA -> str lpSystemName, @void Sid, str Name, @int cchName, str ReferencedDomainName, @int cchReferencedDomainName, @void peUse;
stub int LookupAccountSidW -> @void lpSystemName, @void Sid, @void Name, @int cchName, @void ReferencedDomainName, @int cchReferencedDomainName, @void peUse;
stub int LookupPrivilegeDisplayNameA -> str lpSystemName, str lpName, str lpDisplayName, @int cchDisplayName, @int lpLanguageId;
stub int LookupPrivilegeDisplayNameW -> @void lpSystemName, @void lpName, @void lpDisplayName, @int cchDisplayName, @int lpLanguageId;
stub int LookupPrivilegeNameA -> str lpSystemName, @void lpLuid, str lpName, @int cchName;
stub int LookupPrivilegeNameW -> @void lpSystemName, @void lpLuid, @void lpName, @int cchName;
stub int LookupPrivilegeValueA -> str lpSystemName, str lpName, @void lpLuid;
stub int LookupPrivilegeValueW -> @void lpSystemName, @void lpName, @void lpLuid;
stub utype int LookupSecurityDescriptorPartsA -> @void ppOwner, @void ppGroup, @int pcCountOfAccessEntries, @void ppListOfAccessEntries, @int pcCountOfAuditEntries, @void ppListOfAuditEntries, @void pSD;
stub utype int LookupSecurityDescriptorPartsW -> @void ppOwner, @void ppGroup, @int pcCountOfAccessEntries, @void ppListOfAccessEntries, @int pcCountOfAuditEntries, @void ppListOfAuditEntries, @void pSD;
stub int LsaAddAccountRights -> @void PolicyHandle, @void AccountSid, @void UserRights, utype int CountOfRights;
stub int LsaClose -> @void ObjectHandle;
stub int LsaCreateTrustedDomainEx -> @void PolicyHandle, @void TrustedDomainInformation, @void AuthenticationInformation, utype int DesiredAccess, @void TrustedDomainHandle;
stub int LsaDeleteTrustedDomain -> @void PolicyHandle, @void TrustedDomainSid;
stub int LsaEnumerateAccountRights -> @void PolicyHandle, @void AccountSid, @void UserRights, @int CountOfRights;
stub int LsaEnumerateAccountsWithUserRight -> @void PolicyHandle, @void UserRight, @void Buffer, @int CountReturned;
stub int LsaEnumerateTrustedDomains -> @void PolicyHandle, @int EnumerationContext, @void Buffer, utype int PreferedMaximumLength, @int CountReturned;
stub int LsaEnumerateTrustedDomainsEx -> @void PolicyHandle, @int EnumerationContext, @void Buffer, utype int PreferedMaximumLength, @int CountReturned;
stub int LsaFreeMemory -> @void Buffer;
stub int LsaGetAppliedCAPIDs -> @void SystemName, @void CAPIDs, @int CAPIDCount;
stub int LsaLookupNames -> @void PolicyHandle, utype int Count, @void Names, @void ReferencedDomains, @void Sids;
stub int LsaLookupNames2 -> @void PolicyHandle, utype int Flags, utype int Count, @void Names, @void ReferencedDomains, @void Sids;
stub int LsaLookupSids -> @void PolicyHandle, utype int Count, @void Sids, @void ReferencedDomains, @void Names;
stub int LsaLookupSids2 -> @void PolicyHandle, utype int LookupOptions, utype int Count, @void Sids, @void ReferencedDomains, @void Names;
stub utype int LsaNtStatusToWinError -> int Status;
stub int LsaOpenPolicy -> @void SystemName, @void ObjectAttributes, utype int DesiredAccess, @void PolicyHandle;
stub int LsaOpenTrustedDomainByName -> @void PolicyHandle, @void TrustedDomainName, utype int DesiredAccess, @void TrustedDomainHandle;
stub int LsaQueryCAPs -> @void CAPIDs, utype int CAPIDCount, @void CAPs, @int CAPCount;
stub int LsaQueryForestTrustInformation -> @void PolicyHandle, @void TrustedDomainName, @void ForestTrustInfo;
stub int LsaRemoveAccountRights -> @void PolicyHandle, @void AccountSid, utype char AllRights, @void UserRights, utype int CountOfRights;
stub int LsaRetrievePrivateData -> @void PolicyHandle, @void KeyName, @void PrivateData;
stub int LsaSetCAPs -> @void CAPDNs, utype int CAPDNCount, utype int Flags;
stub int LsaSetForestTrustInformation -> @void PolicyHandle, @void TrustedDomainName, @void ForestTrustInfo, utype char CheckOnly, @void CollisionInfo;
stub int LsaStorePrivateData -> @void PolicyHandle, @void KeyName, @void PrivateData;
stub int MakeAbsoluteSD -> @void pSelfRelativeSecurityDescriptor, @void pAbsoluteSecurityDescriptor, @int lpdwAbsoluteSecurityDescriptorSize, @void pDacl, @int lpdwDaclSize, @void pSacl, @int lpdwSaclSize, @void pOwner, @int lpdwOwnerSize, @void pPrimaryGroup, @int lpdwPrimaryGroupSize;
stub int MakeSelfRelativeSD -> @void pAbsoluteSecurityDescriptor, @void pSelfRelativeSecurityDescriptor, @int lpdwBufferLength;
stub void MapGenericMask -> @int AccessMask, @void GenericMapping;
stub int NotifyBootConfigStatus -> int BootAcceptable;
stub int NotifyChangeEventLog -> @void hEventLog, @void hEvent;
stub utype int NotifyServiceStatusChangeA -> @void hService, utype int dwNotifyMask, @void pNotifyBuffer;
stub utype int NotifyServiceStatusChangeW -> @void hService, utype int dwNotifyMask, @void pNotifyBuffer;
stub int ObjectCloseAuditAlarmA -> str SubsystemName, @void HandleId, int GenerateOnClose;
stub int ObjectCloseAuditAlarmW -> @void SubsystemName, @void HandleId, int GenerateOnClose;
stub int ObjectDeleteAuditAlarmA -> str SubsystemName, @void HandleId, int GenerateOnClose;
stub int ObjectDeleteAuditAlarmW -> @void SubsystemName, @void HandleId, int GenerateOnClose;
stub int ObjectOpenAuditAlarmA -> str SubsystemName, @void HandleId, str ObjectTypeName, str ObjectName, @void pSecurityDescriptor, @void ClientToken, utype int DesiredAccess, utype int GrantedAccess, @void Privileges, int ObjectCreation, int AccessGranted, @int GenerateOnClose;
stub int ObjectOpenAuditAlarmW -> @void SubsystemName, @void HandleId, @void ObjectTypeName, @void ObjectName, @void pSecurityDescriptor, @void ClientToken, utype int DesiredAccess, utype int GrantedAccess, @void Privileges, int ObjectCreation, int AccessGranted, @int GenerateOnClose;
stub int ObjectPrivilegeAuditAlarmA -> str SubsystemName, @void HandleId, @void ClientToken, utype int DesiredAccess, @void Privileges, int AccessGranted;
stub int ObjectPrivilegeAuditAlarmW -> @void SubsystemName, @void HandleId, @void ClientToken, utype int DesiredAccess, @void Privileges, int AccessGranted;
stub @void OpenBackupEventLogA -> str lpUNCServerName, str lpFileName;
stub @void OpenBackupEventLogW -> @void lpUNCServerName, @void lpFileName;
stub utype int OpenEncryptedFileRawA -> str lpFileName, utype int ulFlags, @void pvContext;
stub utype int OpenEncryptedFileRawW -> @void lpFileName, utype int ulFlags, @void pvContext;
stub @void OpenEventLogA -> str lpUNCServerName, str lpSourceName;
stub @void OpenEventLogW -> @void lpUNCServerName, @void lpSourceName;
stub int OpenProcessToken -> @void ProcessHandle, utype int DesiredAccess, @void TokenHandle;
stub @void OpenSCManagerA -> str lpMachineName, str lpDatabaseName, utype int dwDesiredAccess;
stub @void OpenSCManagerW -> @void lpMachineName, @void lpDatabaseName, utype int dwDesiredAccess;
stub @void OpenServiceA -> @void hSCManager, str lpServiceName, utype int dwDesiredAccess;
stub @void OpenServiceW -> @void hSCManager, @void lpServiceName, utype int dwDesiredAccess;
stub int OpenThreadToken -> @void ThreadHandle, utype int DesiredAccess, int OpenAsSelf, @void TokenHandle;
stub int OperationEnd -> @void OperationEndParams;
stub int OperationStart -> @void OperationStartParams;
stub int PrivilegeCheck -> @void ClientToken, @void RequiredPrivileges, @int pfResult;
stub int PrivilegedServiceAuditAlarmA -> str SubsystemName, str ServiceName, @void ClientToken, @void Privileges, int AccessGranted;
stub int PrivilegedServiceAuditAlarmW -> @void SubsystemName, @void ServiceName, @void ClientToken, @void Privileges, int AccessGranted;
stub utype int QueryRecoveryAgentsOnEncryptedFile -> @void lpFileName, @void pRecoveryAgents;
stub void QuerySecurityAccessMask -> utype int SecurityInformation, @int DesiredAccess;
stub int QueryServiceConfig2A -> @void hService, utype int dwInfoLevel, @char lpBuffer, utype int cbBufSize, @int pcbBytesNeeded;
stub int QueryServiceConfig2W -> @void hService, utype int dwInfoLevel, @char lpBuffer, utype int cbBufSize, @int pcbBytesNeeded;
stub int QueryServiceConfigA -> @void hService, @void lpServiceConfig, utype int cbBufSize, @int pcbBytesNeeded;
stub int QueryServiceConfigW -> @void hService, @void lpServiceConfig, utype int cbBufSize, @int pcbBytesNeeded;
stub int QueryServiceLockStatusA -> @void hSCManager, @void lpLockStatus, utype int cbBufSize, @int pcbBytesNeeded;
stub int QueryServiceLockStatusW -> @void hSCManager, @void lpLockStatus, utype int cbBufSize, @int pcbBytesNeeded;
stub int QueryServiceObjectSecurity -> @void hService, utype int dwSecurityInformation, @void lpSecurityDescriptor, utype int cbBufSize, @int pcbBytesNeeded;
stub int QueryServiceStatus -> @void hService, @void lpServiceStatus;
stub utype int QueryUsersOnEncryptedFile -> @void lpFileName, @void pUsers;
stub utype int ReadEncryptedFileRaw -> @func pfExportCallback, @void pvCallbackContext, @void pvContext;
stub int ReadEventLogA -> @void hEventLog, utype int dwReadFlags, utype int dwRecordOffset, @void lpBuffer, utype int nNumberOfBytesToRead, @int pnBytesRead, @int pnMinNumberOfBytesNeeded;
stub int ReadEventLogW -> @void hEventLog, utype int dwReadFlags, utype int dwRecordOffset, @void lpBuffer, utype int nNumberOfBytesToRead, @int pnBytesRead, @int pnMinNumberOfBytesNeeded;
stub int RegCloseKey -> @void hKey;
stub int RegConnectRegistryA -> str lpMachineName, @void hKey, @void phkResult;
stub int RegConnectRegistryExA -> str lpMachineName, @void hKey, utype int Flags, @void phkResult;
stub int RegConnectRegistryExW -> @void lpMachineName, @void hKey, utype int Flags, @void phkResult;
stub int RegConnectRegistryW -> @void lpMachineName, @void hKey, @void phkResult;
stub int RegCopyTreeA -> @void hKeySrc, str lpSubKey, @void hKeyDest;
stub int RegCopyTreeW -> @void hKeySrc, @void lpSubKey, @void hKeyDest;
stub int RegCreateKeyA -> @void hKey, str lpSubKey, @void phkResult;
stub int RegCreateKeyExA -> @void hKey, str lpSubKey, utype int Reserved, str lpClass, utype int dwOptions, utype int samDesired, @void lpSecurityAttributes, @void phkResult, @int lpdwDisposition;
stub int RegCreateKeyExW -> @void hKey, @void lpSubKey, utype int Reserved, @void lpClass, utype int dwOptions, utype int samDesired, @void lpSecurityAttributes, @void phkResult, @int lpdwDisposition;
stub int RegCreateKeyTransactedA -> @void hKey, str lpSubKey, utype int Reserved, str lpClass, utype int dwOptions, utype int samDesired, @void lpSecurityAttributes, @void phkResult, @int lpdwDisposition, @void hTransaction, @void pExtendedParemeter;
stub int RegCreateKeyTransactedW -> @void hKey, @void lpSubKey, utype int Reserved, @void lpClass, utype int dwOptions, utype int samDesired, @void lpSecurityAttributes, @void phkResult, @int lpdwDisposition, @void hTransaction, @void pExtendedParemeter;
stub int RegCreateKeyW -> @void hKey, @void lpSubKey, @void phkResult;
stub int RegDeleteKeyA -> @void hKey, str lpSubKey;
stub int RegDeleteKeyExA -> @void hKey, str lpSubKey, utype int samDesired, utype int Reserved;
stub int RegDeleteKeyExW -> @void hKey, @void lpSubKey, utype int samDesired, utype int Reserved;
stub int RegDeleteKeyTransactedA -> @void hKey, str lpSubKey, utype int samDesired, utype int Reserved, @void hTransaction, @void pExtendedParameter;
stub int RegDeleteKeyTransactedW -> @void hKey, @void lpSubKey, utype int samDesired, utype int Reserved, @void hTransaction, @void pExtendedParameter;
stub int RegDeleteKeyValueA -> @void hKey, str lpSubKey, str lpValueName;
stub int RegDeleteKeyValueW -> @void hKey, @void lpSubKey, @void lpValueName;
stub int RegDeleteKeyW -> @void hKey, @void lpSubKey;
stub int RegDeleteTreeA -> @void hKey, str lpSubKey;
stub int RegDeleteTreeW -> @void hKey, @void lpSubKey;
stub int RegDeleteValueA -> @void hKey, str lpValueName;
stub int RegDeleteValueW -> @void hKey, @void lpValueName;
stub int RegDisablePredefinedCache;
stub int RegDisablePredefinedCacheEx;
stub int RegDisableReflectionKey -> @void hBase;
stub int RegEnableReflectionKey -> @void hBase;
stub int RegEnumKeyA -> @void hKey, utype int dwIndex, str lpName, utype int cchName;
stub int RegEnumKeyExA -> @void hKey, utype int dwIndex, str lpName, @int lpcchName, @int lpReserved, str lpClass, @int lpcchClass, @void lpftLastWriteTime;
stub int RegEnumKeyExW -> @void hKey, utype int dwIndex, @void lpName, @int lpcchName, @int lpReserved, @void lpClass, @int lpcchClass, @void lpftLastWriteTime;
stub int RegEnumKeyW -> @void hKey, utype int dwIndex, @void lpName, utype int cchName;
stub int RegEnumValueA -> @void hKey, utype int dwIndex, str lpValueName, @int lpcchValueName, @int lpReserved, @int lpType, @char lpData, @int lpcbData;
stub int RegEnumValueW -> @void hKey, utype int dwIndex, @void lpValueName, @int lpcchValueName, @int lpReserved, @int lpType, @char lpData, @int lpcbData;
stub int RegFlushKey -> @void hKey;
stub int RegGetKeySecurity -> @void hKey, utype int SecurityInformation, @void pSecurityDescriptor, @int lpcbSecurityDescriptor;
stub int RegGetValueA -> @void hkey, str lpSubKey, str lpValue, utype int dwFlags, @int pdwType, @void pvData, @int pcbData;
stub int RegGetValueW -> @void hkey, @void lpSubKey, @void lpValue, utype int dwFlags, @int pdwType, @void pvData, @int pcbData;
stub int RegLoadAppKeyA -> str lpFile, @void phkResult, utype int samDesired, utype int dwOptions, utype int Reserved;
stub int RegLoadAppKeyW -> @void lpFile, @void phkResult, utype int samDesired, utype int dwOptions, utype int Reserved;
stub int RegLoadKeyA -> @void hKey, str lpSubKey, str lpFile;
stub int RegLoadKeyW -> @void hKey, @void lpSubKey, @void lpFile;
stub int RegLoadMUIStringA -> @void hKey, str pszValue, str pszOutBuf, utype int cbOutBuf, @int pcbData, utype int Flags, str pszDirectory;
stub int RegLoadMUIStringW -> @void hKey, @void pszValue, @void pszOutBuf, utype int cbOutBuf, @int pcbData, utype int Flags, @void pszDirectory;
stub int RegNotifyChangeKeyValue -> @void hKey, int bWatchSubtree, utype int dwNotifyFilter, @void hEvent, int fAsynchronous;
stub int RegOpenCurrentUser -> utype int samDesired, @void phkResult;
stub int RegOpenKeyA -> @void hKey, str lpSubKey, @void phkResult;
stub int RegOpenKeyExA -> @void hKey, str lpSubKey, utype int ulOptions, utype int samDesired, @void phkResult;
stub int RegOpenKeyExW -> @void hKey, @void lpSubKey, utype int ulOptions, utype int samDesired, @void phkResult;
stub int RegOpenKeyTransactedA -> @void hKey, str lpSubKey, utype int ulOptions, utype int samDesired, @void phkResult, @void hTransaction, @void pExtendedParameter;
stub int RegOpenKeyTransactedW -> @void hKey, @void lpSubKey, utype int ulOptions, utype int samDesired, @void phkResult, @void hTransaction, @void pExtendedParameter;
stub int RegOpenKeyW -> @void hKey, @void lpSubKey, @void phkResult;
stub int RegOpenUserClassesRoot -> @void hToken, utype int dwOptions, utype int samDesired, @void phkResult;
stub int RegOverridePredefKey -> @void hKey, @void hNewHKey;
stub int RegQueryInfoKeyA -> @void hKey, str lpClass, @int lpcchClass, @int lpReserved, @int lpcSubKeys, @int lpcbMaxSubKeyLen, @int lpcbMaxClassLen, @int lpcValues, @int lpcbMaxValueNameLen, @int lpcbMaxValueLen, @int lpcbSecurityDescriptor, @void lpftLastWriteTime;
stub int RegQueryInfoKeyW -> @void hKey, @void lpClass, @int lpcchClass, @int lpReserved, @int lpcSubKeys, @int lpcbMaxSubKeyLen, @int lpcbMaxClassLen, @int lpcValues, @int lpcbMaxValueNameLen, @int lpcbMaxValueLen, @int lpcbSecurityDescriptor, @void lpftLastWriteTime;
stub int RegQueryMultipleValuesA -> @void hKey, @void val_list, utype int num_vals, str lpValueBuf, @int ldwTotsize;
stub int RegQueryMultipleValuesW -> @void hKey, @void val_list, utype int num_vals, @void lpValueBuf, @int ldwTotsize;
stub int RegQueryReflectionKey -> @void hBase, @int bIsReflectionDisabled;
stub int RegQueryValueA -> @void hKey, str lpSubKey, str lpData, @int lpcbData;
stub int RegQueryValueExA -> @void hKey, str lpValueName, @int lpReserved, @int lpType, @char lpData, @int lpcbData;
stub int RegQueryValueExW -> @void hKey, @void lpValueName, @int lpReserved, @int lpType, @char lpData, @int lpcbData;
stub int RegQueryValueW -> @void hKey, @void lpSubKey, @void lpData, @int lpcbData;
stub int RegRenameKey -> @void hKey, @void lpSubKeyName, @void lpNewKeyName;
stub int RegReplaceKeyA -> @void hKey, str lpSubKey, str lpNewFile, str lpOldFile;
stub int RegReplaceKeyW -> @void hKey, @void lpSubKey, @void lpNewFile, @void lpOldFile;
stub int RegRestoreKeyA -> @void hKey, str lpFile, utype int dwFlags;
stub int RegRestoreKeyW -> @void hKey, @void lpFile, utype int dwFlags;
stub int RegSaveKeyA -> @void hKey, str lpFile, @void lpSecurityAttributes;
stub int RegSaveKeyExA -> @void hKey, str lpFile, @void lpSecurityAttributes, utype int Flags;
stub int RegSaveKeyExW -> @void hKey, @void lpFile, @void lpSecurityAttributes, utype int Flags;
stub int RegSaveKeyW -> @void hKey, @void lpFile, @void lpSecurityAttributes;
stub int RegSetKeySecurity -> @void hKey, utype int SecurityInformation, @void pSecurityDescriptor;
stub int RegSetKeyValueA -> @void hKey, str lpSubKey, str lpValueName, utype int dwType, @void lpData, utype int cbData;
stub int RegSetKeyValueW -> @void hKey, @void lpSubKey, @void lpValueName, utype int dwType, @void lpData, utype int cbData;
stub int RegSetValueA -> @void hKey, str lpSubKey, utype int dwType, str lpData, utype int cbData;
stub int RegSetValueExA -> @void hKey, str lpValueName, utype int Reserved, utype int dwType, @char lpData, utype int cbData;
stub int RegSetValueExW -> @void hKey, @void lpValueName, utype int Reserved, utype int dwType, @char lpData, utype int cbData;
stub int RegSetValueW -> @void hKey, @void lpSubKey, utype int dwType, @void lpData, utype int cbData;
stub int RegUnLoadKeyA -> @void hKey, str lpSubKey;
stub int RegUnLoadKeyW -> @void hKey, @void lpSubKey;
stub @void RegisterEventSourceA -> str lpUNCServerName, str lpSourceName;
stub @void RegisterEventSourceW -> @void lpUNCServerName, @void lpSourceName;
stub @void RegisterServiceCtrlHandlerA -> str lpServiceName, @func lpHandlerProc;
stub @void RegisterServiceCtrlHandlerExA -> str lpServiceName, @func lpHandlerProc, @void lpContext;
stub @void RegisterServiceCtrlHandlerExW -> @void lpServiceName, @func lpHandlerProc, @void lpContext;
stub @void RegisterServiceCtrlHandlerW -> @void lpServiceName, @func lpHandlerProc;
stub utype int RemoveUsersFromEncryptedFile -> @void lpFileName, @void pHashes;
stub int ReportEventA -> @void hEventLog, utype int wType, utype int wCategory, utype int dwEventID, @void lpUserSid, utype int wNumStrings, utype int dwDataSize, @void lpStrings, @void lpRawData;
stub int ReportEventW -> @void hEventLog, utype int wType, utype int wCategory, utype int dwEventID, @void lpUserSid, utype int wNumStrings, utype int dwDataSize, @void lpStrings, @void lpRawData;
stub int RevertToSelf;
stub utype int SetEntriesInAclA -> utype int cCountOfExplicitEntries, @void pListOfExplicitEntries, @void OldAcl, @void NewAcl;
stub utype int SetEntriesInAclW -> utype int cCountOfExplicitEntries, @void pListOfExplicitEntries, @void OldAcl, @void NewAcl;
stub int SetFileSecurityA -> str lpFileName, utype int SecurityInformation, @void pSecurityDescriptor;
stub int SetFileSecurityW -> @void lpFileName, utype int SecurityInformation, @void pSecurityDescriptor;
stub int SetKernelObjectSecurity -> @void Handle, utype int SecurityInformation, @void SecurityDescriptor;
stub int SetPrivateObjectSecurity -> utype int SecurityInformation, @void ModificationDescriptor, @void ObjectsSecurityDescriptor, @void GenericMapping, @void Token;
stub int SetPrivateObjectSecurityEx -> utype int SecurityInformation, @void ModificationDescriptor, @void ObjectsSecurityDescriptor, utype int AutoInheritFlags, @void GenericMapping, @void Token;
stub void SetSecurityAccessMask -> utype int SecurityInformation, @int DesiredAccess;
stub int SetSecurityDescriptorControl -> @void pSecurityDescriptor, utype int ControlBitsOfInterest, utype int ControlBitsToSet;
stub int SetSecurityDescriptorDacl -> @void pSecurityDescriptor, int bDaclPresent, @void pDacl, int bDaclDefaulted;
stub int SetSecurityDescriptorGroup -> @void pSecurityDescriptor, @void pGroup, int bGroupDefaulted;
stub int SetSecurityDescriptorOwner -> @void pSecurityDescriptor, @void pOwner, int bOwnerDefaulted;
stub utype int SetSecurityDescriptorRMControl -> @void SecurityDescriptor, @char RMControl;
stub int SetSecurityDescriptorSacl -> @void pSecurityDescriptor, int bSaclPresent, @void pSacl, int bSaclDefaulted;
stub int SetServiceObjectSecurity -> @void hService, utype int dwSecurityInformation, @void lpSecurityDescriptor;
stub int SetServiceStatus -> @void hServiceStatus, @void lpServiceStatus;
stub int SetThreadToken -> @void Thread, @void Token;
stub utype int SetUserFileEncryptionKey -> @void pEncryptionCertificate;
stub int StartServiceA -> @void hService, utype int dwNumServiceArgs, @void lpServiceArgVectors;
stub int StartServiceCtrlDispatcherA -> @void lpServiceStartTable;
stub int StartServiceCtrlDispatcherW -> @void lpServiceStartTable;
stub int StartServiceW -> @void hService, utype int dwNumServiceArgs, @void lpServiceArgVectors;
stub utype char SystemFunction036 -> @void a1, utype int a2;
stub int SystemFunction040 -> @void a1, utype int a2, utype int a3;
stub int SystemFunction041 -> @void a1, utype int a2, utype int a3;
stub int UnlockServiceDatabase -> @void ScLock;
stub utype int WriteEncryptedFileRaw -> @func pfImportCallback, @void pvCallbackContext, @void pvContext;

!!! Declared by the headers, but with a type the language cannot write:
!!!   AccessCheckByTypeAndAuditAlarmA
!!!   AccessCheckByTypeAndAuditAlarmW
!!!   AccessCheckByTypeResultListAndAuditAlarmA
!!!   AccessCheckByTypeResultListAndAuditAlarmByHandleA
!!!   AccessCheckByTypeResultListAndAuditAlarmByHandleW
!!!   AccessCheckByTypeResultListAndAuditAlarmW
!!!   AuditLookupCategoryGuidFromCategoryId
!!!   BuildExplicitAccessWithNameA
!!!   BuildExplicitAccessWithNameW
!!!   BuildImpersonateExplicitAccessWithNameA
!!!   BuildImpersonateExplicitAccessWithNameW
!!!   BuildTrusteeWithObjectsAndNameA
!!!   BuildTrusteeWithObjectsAndNameW
!!!   CreateWellKnownSid
!!!   DuplicateToken
!!!   DuplicateTokenEx
!!!   EnumServicesStatusExA
!!!   EnumServicesStatusExW
!!!   GetAclInformation
!!!   GetInheritanceSourceA
!!!   GetInheritanceSourceW
!!!   GetMultipleTrusteeOperationA
!!!   GetMultipleTrusteeOperationW
!!!   GetNamedSecurityInfoA
!!!   GetNamedSecurityInfoW
!!!   GetSecurityInfo
!!!   GetTokenInformation
!!!   GetTrusteeFormA
!!!   GetTrusteeFormW
!!!   GetTrusteeTypeA
!!!   GetTrusteeTypeW
!!!   ImpersonateSelf
!!!   IsWellKnownSid
!!!   LsaQueryDomainInformationPolicy
!!!   LsaQueryForestTrustInformation2
!!!   LsaQueryInformationPolicy
!!!   LsaQueryTrustedDomainInfo
!!!   LsaQueryTrustedDomainInfoByName
!!!   LsaSetDomainInformationPolicy
!!!   LsaSetForestTrustInformation2
!!!   LsaSetInformationPolicy
!!!   LsaSetTrustedDomainInfoByName
!!!   LsaSetTrustedDomainInformation
!!!   QueryServiceStatusEx
!!!   SetAclInformation
!!!   SetNamedSecurityInfoA
!!!   SetNamedSecurityInfoW
!!!   SetSecurityInfo
!!!   SetTokenInformation
!!!   TreeResetNamedSecurityInfoA
!!!   TreeResetNamedSecurityInfoW
!!!   TreeSetNamedSecurityInfoA
!!!   TreeSetNamedSecurityInfoW

!!! No prototype in the headers this build saw. They are here so the
!!! list is complete; uncomment and give the real signature to use one.
!!! AccessCheckByTypeAndAuditAlarmA
!!! AccessCheckByTypeAndAuditAlarmW
!!! AccessCheckByTypeResultListAndAuditAlarmA
!!! AccessCheckByTypeResultListAndAuditAlarmByHandleA
!!! AccessCheckByTypeResultListAndAuditAlarmByHandleW
!!! AccessCheckByTypeResultListAndAuditAlarmW
!!! AuditLookupCategoryGuidFromCategoryId
!!! BuildExplicitAccessWithNameA
!!! BuildExplicitAccessWithNameW
!!! BuildImpersonateExplicitAccessWithNameA
!!! BuildImpersonateExplicitAccessWithNameW
!!! BuildTrusteeWithObjectsAndNameA
!!! BuildTrusteeWithObjectsAndNameW
!!! CreateWellKnownSid
!!! DuplicateToken
!!! DuplicateTokenEx
!!! EnumServicesStatusExA
!!! EnumServicesStatusExW
!!! GetAclInformation
!!! GetInheritanceSourceA
!!! GetInheritanceSourceW
!!! GetMultipleTrusteeOperationA
!!! GetMultipleTrusteeOperationW
!!! GetNamedSecurityInfoA
!!! GetNamedSecurityInfoW
!!! GetSecurityInfo
!!! GetTokenInformation
!!! GetTrusteeFormA
!!! GetTrusteeFormW
!!! GetTrusteeTypeA
!!! GetTrusteeTypeW
!!! ImpersonateSelf
!!! IsWellKnownSid
!!! LsaQueryDomainInformationPolicy
!!! LsaQueryForestTrustInformation2
!!! LsaQueryInformationPolicy
!!! LsaQueryTrustedDomainInfo
!!! LsaQueryTrustedDomainInfoByName
!!! LsaSetDomainInformationPolicy
!!! LsaSetForestTrustInformation2
!!! LsaSetInformationPolicy
!!! LsaSetTrustedDomainInfoByName
!!! LsaSetTrustedDomainInformation
!!! QueryServiceStatusEx
!!! SetAclInformation
!!! SetNamedSecurityInfoA
!!! SetNamedSecurityInfoW
!!! SetSecurityInfo
!!! SetTokenInformation
!!! TreeResetNamedSecurityInfoA
!!! TreeResetNamedSecurityInfoW
!!! TreeSetNamedSecurityInfoA
!!! TreeSetNamedSecurityInfoW
