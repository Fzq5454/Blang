!~
~  native/sechost.dll.b: the sechost.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/sechost.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/sechost.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `sechost.dll.b` is what produces `meta/sechost.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\sechost.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per sechost.dll export that the headers declare. The
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
!!! 67 declarations here, 0 kept from the hand-checked list above, 4 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub utype char AuditComputeEffectivePolicyBySid -> @void pSid, @void pSubCategoryGuids, utype int PolicyCount, @void ppAuditPolicy;
stub utype char AuditEnumerateCategories -> @void ppAuditCategoriesArray, @int pCountReturned;
stub utype char AuditEnumeratePerUserPolicy -> @void ppAuditSidArray;
stub utype char AuditEnumerateSubCategories -> @void pAuditCategoryGuid, utype char bRetrieveAllSubCategories, @void ppAuditSubCategoriesArray, @int pCountReturned;
stub void AuditFree -> @void Buffer;
stub utype char AuditLookupCategoryNameW -> @void pAuditCategoryGuid, @void ppszCategoryName;
stub utype char AuditLookupSubCategoryNameW -> @void pAuditSubCategoryGuid, @void ppszSubCategoryName;
stub utype char AuditQueryGlobalSaclW -> @void ObjectTypeName, @void Acl;
stub utype char AuditQueryPerUserPolicy -> @void pSid, @void pSubCategoryGuids, utype int PolicyCount, @void ppAuditPolicy;
stub utype char AuditQuerySecurity -> utype int SecurityInformation, @void ppSecurityDescriptor;
stub utype char AuditQuerySystemPolicy -> @void pSubCategoryGuids, utype int PolicyCount, @void ppAuditPolicy;
stub utype char AuditSetGlobalSaclW -> @void ObjectTypeName, @void Acl;
stub utype char AuditSetPerUserPolicy -> @void pSid, @void pAuditPolicy, utype int PolicyCount;
stub utype char AuditSetSecurity -> utype int SecurityInformation, @void pSecurityDescriptor;
stub utype char AuditSetSystemPolicy -> @void pAuditPolicy, utype int PolicyCount;
stub int ChangeServiceConfig2A -> @void hService, utype int dwInfoLevel, @void lpInfo;
stub int ChangeServiceConfig2W -> @void hService, utype int dwInfoLevel, @void lpInfo;
stub int ChangeServiceConfigA -> @void hService, utype int dwServiceType, utype int dwStartType, utype int dwErrorControl, str lpBinaryPathName, str lpLoadOrderGroup, @int lpdwTagId, str lpDependencies, str lpServiceStartName, str lpPassword, str lpDisplayName;
stub int ChangeServiceConfigW -> @void hService, utype int dwServiceType, utype int dwStartType, utype int dwErrorControl, @void lpBinaryPathName, @void lpLoadOrderGroup, @int lpdwTagId, @void lpDependencies, @void lpServiceStartName, @void lpPassword, @void lpDisplayName;
stub int CloseServiceHandle -> @void hSCObject;
stub int ControlService -> @void hService, utype int dwControl, @void lpServiceStatus;
stub int ControlServiceExA -> @void hService, utype int dwControl, utype int dwInfoLevel, @void pControlParams;
stub int ControlServiceExW -> @void hService, utype int dwControl, utype int dwInfoLevel, @void pControlParams;
stub @void CreateServiceA -> @void hSCManager, str lpServiceName, str lpDisplayName, utype int dwDesiredAccess, utype int dwServiceType, utype int dwStartType, utype int dwErrorControl, str lpBinaryPathName, str lpLoadOrderGroup, @int lpdwTagId, str lpDependencies, str lpServiceStartName, str lpPassword;
stub @void CreateServiceW -> @void hSCManager, @void lpServiceName, @void lpDisplayName, utype int dwDesiredAccess, utype int dwServiceType, utype int dwStartType, utype int dwErrorControl, @void lpBinaryPathName, @void lpLoadOrderGroup, @int lpdwTagId, @void lpDependencies, @void lpServiceStartName, @void lpPassword;
stub int DeleteService -> @void hService;
stub int EnumDependentServicesW -> @void hService, utype int dwServiceState, @void lpServices, utype int cbBufSize, @int pcbBytesNeeded, @int lpServicesReturned;
stub int GetServiceDisplayNameW -> @void hSCManager, @void lpServiceName, @void lpDisplayName, @int lpcchBuffer;
stub int GetServiceKeyNameW -> @void hSCManager, @void lpDisplayName, @void lpServiceName, @int lpcchBuffer;
stub int LookupAccountNameLocalA -> str lpAccountName, @void Sid, @int cbSid, str ReferencedDomainName, @int cchReferencedDomainName, @void peUse;
stub int LookupAccountNameLocalW -> @void lpAccountName, @void Sid, @int cbSid, @void ReferencedDomainName, @int cchReferencedDomainName, @void peUse;
stub int LookupAccountSidLocalA -> @void Sid, str Name, @int cchName, str ReferencedDomainName, @int cchReferencedDomainName, @void peUse;
stub int LookupAccountSidLocalW -> @void Sid, @void Name, @int cchName, @void ReferencedDomainName, @int cchReferencedDomainName, @void peUse;
stub int LsaAddAccountRights -> @void PolicyHandle, @void AccountSid, @void UserRights, utype int CountOfRights;
stub int LsaClose -> @void ObjectHandle;
stub int LsaEnumerateAccountRights -> @void PolicyHandle, @void AccountSid, @void UserRights, @int CountOfRights;
stub int LsaEnumerateAccountsWithUserRight -> @void PolicyHandle, @void UserRight, @void Buffer, @int CountReturned;
stub int LsaFreeMemory -> @void Buffer;
stub int LsaLookupNames2 -> @void PolicyHandle, utype int Flags, utype int Count, @void Names, @void ReferencedDomains, @void Sids;
stub int LsaLookupSids -> @void PolicyHandle, utype int Count, @void Sids, @void ReferencedDomains, @void Names;
stub int LsaLookupSids2 -> @void PolicyHandle, utype int LookupOptions, utype int Count, @void Sids, @void ReferencedDomains, @void Names;
stub int LsaOpenPolicy -> @void SystemName, @void ObjectAttributes, utype int DesiredAccess, @void PolicyHandle;
stub int LsaRemoveAccountRights -> @void PolicyHandle, @void AccountSid, utype char AllRights, @void UserRights, utype int CountOfRights;
stub int LsaRetrievePrivateData -> @void PolicyHandle, @void KeyName, @void PrivateData;
stub int LsaStorePrivateData -> @void PolicyHandle, @void KeyName, @void PrivateData;
stub utype int NotifyServiceStatusChangeA -> @void hService, utype int dwNotifyMask, @void pNotifyBuffer;
stub utype int NotifyServiceStatusChangeW -> @void hService, utype int dwNotifyMask, @void pNotifyBuffer;
stub @void OpenSCManagerA -> str lpMachineName, str lpDatabaseName, utype int dwDesiredAccess;
stub @void OpenSCManagerW -> @void lpMachineName, @void lpDatabaseName, utype int dwDesiredAccess;
stub @void OpenServiceA -> @void hSCManager, str lpServiceName, utype int dwDesiredAccess;
stub @void OpenServiceW -> @void hSCManager, @void lpServiceName, utype int dwDesiredAccess;
stub int QueryServiceConfig2A -> @void hService, utype int dwInfoLevel, @char lpBuffer, utype int cbBufSize, @int pcbBytesNeeded;
stub int QueryServiceConfig2W -> @void hService, utype int dwInfoLevel, @char lpBuffer, utype int cbBufSize, @int pcbBytesNeeded;
stub int QueryServiceConfigA -> @void hService, @void lpServiceConfig, utype int cbBufSize, @int pcbBytesNeeded;
stub int QueryServiceConfigW -> @void hService, @void lpServiceConfig, utype int cbBufSize, @int pcbBytesNeeded;
stub int QueryServiceObjectSecurity -> @void hService, utype int dwSecurityInformation, @void lpSecurityDescriptor, utype int cbBufSize, @int pcbBytesNeeded;
stub int QueryServiceStatus -> @void hService, @void lpServiceStatus;
stub @void RegisterServiceCtrlHandlerA -> str lpServiceName, @func lpHandlerProc;
stub @void RegisterServiceCtrlHandlerExA -> str lpServiceName, @func lpHandlerProc, @void lpContext;
stub @void RegisterServiceCtrlHandlerExW -> @void lpServiceName, @func lpHandlerProc, @void lpContext;
stub @void RegisterServiceCtrlHandlerW -> @void lpServiceName, @func lpHandlerProc;
stub int SetServiceObjectSecurity -> @void hService, utype int dwSecurityInformation, @void lpSecurityDescriptor;
stub int SetServiceStatus -> @void hServiceStatus, @void lpServiceStatus;
stub int StartServiceA -> @void hService, utype int dwNumServiceArgs, @void lpServiceArgVectors;
stub int StartServiceCtrlDispatcherA -> @void lpServiceStartTable;
stub int StartServiceCtrlDispatcherW -> @void lpServiceStartTable;
stub int StartServiceW -> @void hService, utype int dwNumServiceArgs, @void lpServiceArgVectors;

!!! Declared by the headers, but with a type the language cannot write:
!!!   EnumServicesStatusExW
!!!   LsaQueryInformationPolicy
!!!   LsaSetInformationPolicy
!!!   QueryServiceStatusEx

!!! No prototype in the headers this build saw. They are here so the
!!! list is complete; uncomment and give the real signature to use one.
!!! EnumServicesStatusExW
!!! LsaQueryInformationPolicy
!!! LsaSetInformationPolicy
!!! QueryServiceStatusEx
