!~
~  native/kernelbase.dll.b: the kernelbase.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/kernelbase.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/kernelbase.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `kernelbase.dll.b` is what produces `meta/kernelbase.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\kernelbase.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per kernelbase.dll export that the headers declare. The
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
!!! 1051 declarations here, 0 kept from the hand-checked list above, 67 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub int AccessCheck -> @void pSecurityDescriptor, @void ClientToken, utype int DesiredAccess, @void GenericMapping, @void PrivilegeSet, @int PrivilegeSetLength, @int GrantedAccess, @int AccessStatus;
stub int AccessCheckAndAuditAlarmW -> @void SubsystemName, @void HandleId, @void ObjectTypeName, @void ObjectName, @void SecurityDescriptor, utype int DesiredAccess, @void GenericMapping, int ObjectCreation, @int GrantedAccess, @int AccessStatus, @int pfGenerateOnClose;
stub int AccessCheckByType -> @void pSecurityDescriptor, @void PrincipalSelfSid, @void ClientToken, utype int DesiredAccess, @void ObjectTypeList, utype int ObjectTypeListLength, @void GenericMapping, @void PrivilegeSet, @int PrivilegeSetLength, @int GrantedAccess, @int AccessStatus;
stub int AccessCheckByTypeResultList -> @void pSecurityDescriptor, @void PrincipalSelfSid, @void ClientToken, utype int DesiredAccess, @void ObjectTypeList, utype int ObjectTypeListLength, @void GenericMapping, @void PrivilegeSet, @int PrivilegeSetLength, @int GrantedAccessList, @int AccessStatusList;
stub void AcquireSRWLockExclusive -> @void SRWLock;
stub void AcquireSRWLockShared -> @void SRWLock;
stub int ActivateActCtx -> @void hActCtx, @longlong lpCookie;
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
stub int AddConsoleAliasA -> str source, str target, str exe_name;
stub int AddConsoleAliasW -> @void source, @void target, @void exe_name;
stub @void AddDllDirectory -> @void NewDirectory;
stub int AddMandatoryAce -> @void pAcl, utype int dwAceRevision, utype int AceFlags, utype int MandatoryPolicy, @void pLabelSid;
stub void AddRefActCtx -> @void hActCtx;
stub int AddResourceAttributeAce -> @void pAcl, utype int dwAceRevision, utype int AceFlags, utype int AccessMask, @void pSid, @void pAttributeInfo, @int pReturnLength;
stub int AddSIDToBoundaryDescriptor -> @void BoundaryDescriptor, @void RequiredSid;
stub int AddScopedPolicyIDAce -> @void pAcl, utype int dwAceRevision, utype int AceFlags, utype int AccessMask, @void pSid;
stub @void AddVectoredContinueHandler -> utype int First, @func Handler;
stub @void AddVectoredExceptionHandler -> utype int First, @func Handler;
stub int AdjustTokenGroups -> @void TokenHandle, int ResetToDefault, @void NewState, utype int BufferLength, @void PreviousState, @int ReturnLength;
stub int AdjustTokenPrivileges -> @void TokenHandle, int DisableAllPrivileges, @void NewState, utype int BufferLength, @void PreviousState, @int ReturnLength;
stub int AllocConsole;
stub int AllocateAndInitializeSid -> @void pIdentifierAuthority, utype char nSubAuthorityCount, utype int nSubAuthority0, utype int nSubAuthority1, utype int nSubAuthority2, utype int nSubAuthority3, utype int nSubAuthority4, utype int nSubAuthority5, utype int nSubAuthority6, utype int nSubAuthority7, @void pSid;
stub int AllocateLocallyUniqueId -> @void Luid;
stub int AllocateUserPhysicalPages -> @void hProcess, @longlong NumberOfPages, @longlong PageArray;
stub int AllocateUserPhysicalPagesNuma -> @void hProcess, @longlong NumberOfPages, @longlong PageArray, utype int nndPreferred;
stub int AppPolicyGetClrCompat -> @void processToken, @void policy;
stub int AppPolicyGetCreateFileAccess -> @void processToken, @void policy;
stub int AppPolicyGetLifecycleManagement -> @void processToken, @void policy;
stub int AppPolicyGetMediaFoundationCodecLoading -> @void processToken, @void policy;
stub int AppPolicyGetProcessTerminationMethod -> @void processToken, @void policy;
stub int AppPolicyGetShowDeveloperDiagnostic -> @void processToken, @void policy;
stub int AppPolicyGetThreadInitializationType -> @void processToken, @void policy;
stub int AppPolicyGetWindowingModel -> @void processToken, @void policy;
stub int AreAllAccessesGranted -> utype int GrantedAccess, utype int DesiredAccess;
stub int AreAnyAccessesGranted -> utype int GrantedAccess, utype int DesiredAccess;
stub int AreFileApisANSI;
stub int AttachConsole -> utype int process_id;
stub int Beep -> utype int dwFreq, utype int dwDuration;
stub int CallNamedPipeW -> @void lpNamedPipeName, @void lpInBuffer, utype int nInBufferSize, @void lpOutBuffer, utype int nOutBufferSize, @int lpBytesRead, utype int nTimeOut;
stub int CallbackMayRunLong -> @void pci;
stub int CancelIo -> @void hFile;
stub int CancelIoEx -> @void hFile, @void lpOverlapped;
stub int CancelSynchronousIo -> @void hThread;
stub void CancelThreadpoolIo -> @void pio;
stub int CancelWaitableTimer -> @void hTimer;
stub int ChangeTimerQueueTimer -> @void TimerQueue, @void Timer, utype int DueTime, utype int Period;
stub str CharLowerA -> str lpsz;
stub utype int CharLowerBuffA -> str lpsz, utype int cchLength;
stub utype int CharLowerBuffW -> @void lpsz, utype int cchLength;
stub @void CharLowerW -> @void lpsz;
stub str CharNextA -> str lpsz;
stub str CharNextExA -> utype int CodePage, str lpCurrentChar, utype int dwFlags;
stub @void CharNextW -> @void lpsz;
stub str CharPrevA -> str lpszStart, str lpszCurrent;
stub str CharPrevExA -> utype int CodePage, str lpStart, str lpCurrentChar, utype int dwFlags;
stub @void CharPrevW -> @void lpszStart, @void lpszCurrent;
stub str CharUpperA -> str lpsz;
stub utype int CharUpperBuffA -> str lpsz, utype int cchLength;
stub utype int CharUpperBuffW -> @void lpsz, utype int cchLength;
stub @void CharUpperW -> @void String;
stub int CheckIsMSIXPackage -> @void packageFullName, @int isMSIXPackage;
stub int CheckRemoteDebuggerPresent -> @void hProcess, @int pbDebuggerPresent;
stub int CheckTokenCapability -> @void TokenHandle, @void CapabilitySidToCheck, @int HasCapability;
stub int CheckTokenMembership -> @void TokenHandle, @void SidToCheck, @int IsMember;
stub int CheckTokenMembershipEx -> @void TokenHandle, @void SidToCheck, utype int Flags, @int IsMember;
stub int ClearCommBreak -> @void hFile;
stub int ClearCommError -> @void hFile, @int lpErrors, @void lpStat;
stub int CloseHandle -> @void hObject;
stub utype char ClosePrivateNamespace -> @void Handle, utype int Flags;
stub void ClosePseudoConsole -> @void pc;
stub void CloseThreadpool -> @void ptpp;
stub void CloseThreadpoolCleanupGroup -> @void ptpcg;
stub void CloseThreadpoolCleanupGroupMembers -> @void ptpcg, int fCancelPendingCallbacks, @void pvCleanupContext;
stub void CloseThreadpoolIo -> @void pio;
stub void CloseThreadpoolTimer -> @void pti;
stub void CloseThreadpoolWait -> @void pwa;
stub void CloseThreadpoolWork -> @void pwk;
stub @void CommandLineToArgvW -> @void lpCmdLine, @int pNumArgs;
stub int CompareFileTime -> @void lpFileTime1, @void lpFileTime2;
stub int CompareObjectHandles -> @void hFirstObjectHandle, @void hSecondObjectHandle;
stub int CompareStringA -> utype int Locale, utype int dwCmpFlags, str lpString1, int cchCount1, str lpString2, int cchCount2;
stub int CompareStringEx -> @void lpLocaleName, utype int dwCmpFlags, @void lpString1, int cchCount1, @void lpString2, int cchCount2, @void lpVersionInformation, @void lpReserved, longlong lParam;
stub int CompareStringOrdinal -> @void lpString1, int cchCount1, @void lpString2, int cchCount2, int bIgnoreCase;
stub int CompareStringW -> utype int Locale, utype int dwCmpFlags, @void lpString1, int cchCount1, @void lpString2, int cchCount2;
stub int ConnectNamedPipe -> @void hNamedPipe, @void lpOverlapped;
stub int ContinueDebugEvent -> utype int dwProcessId, utype int dwThreadId, utype int dwContinueStatus;
stub int ConvertAuxiliaryCounterToPerformanceCounter -> utype longlong ullAuxiliaryCounterValue, @longlong lpPerformanceCounterValue, @longlong lpConversionError;
stub utype int ConvertDefaultLocale -> utype int Locale;
stub int ConvertFiberToThread;
stub int ConvertPerformanceCounterToAuxiliaryCounter -> utype longlong ullPerformanceCounterValue, @longlong lpAuxiliaryCounterValue, @longlong lpConversionError;
stub @void ConvertThreadToFiber -> @void lpParameter;
stub @void ConvertThreadToFiberEx -> @void lpParameter, utype int dwFlags;
stub int ConvertToAutoInheritPrivateObjectSecurity -> @void ParentDescriptor, @void CurrentSecurityDescriptor, @void NewSecurityDescriptor, @void ObjectType, utype char IsDirectoryObject, @void GenericMapping;
stub int CopyContext -> @void Destination, utype int ContextFlags, @void Source;
stub int CopyFile2 -> @void pwszExistingFileName, @void pwszNewFileName, @void pExtendedParameters;
stub int CopyFileExW -> @void lpExistingFileName, @void lpNewFileName, @func lpProgressRoutine, @void lpData, @int pbCancel, utype int dwCopyFlags;
stub int CopyFileW -> @void lpExistingFileName, @void lpNewFileName, int bFailIfExists;
stub int CopySid -> utype int nDestinationSidLength, @void pDestinationSid, @void pSourceSid;
stub @void CreateActCtxW -> @void pActCtx;
stub @void CreateBoundaryDescriptorW -> @void Name, utype int Flags;
stub @void CreateConsoleScreenBuffer -> utype int desired_access, utype int share_mode, @void security_attributes, utype int flags, @void screen_buffer_data;
stub int CreateDirectoryA -> str lpPathName, @void lpSecurityAttributes;
stub int CreateDirectoryExW -> @void lpTemplateDirectory, @void lpNewDirectory, @void lpSecurityAttributes;
stub int CreateDirectoryW -> @void lpPathName, @void lpSecurityAttributes;
stub @void CreateEventA -> @void lpEventAttributes, int bManualReset, int bInitialState, str lpName;
stub @void CreateEventExA -> @void lpEventAttributes, str lpName, utype int dwFlags, utype int dwDesiredAccess;
stub @void CreateEventExW -> @void lpEventAttributes, @void lpName, utype int dwFlags, utype int dwDesiredAccess;
stub @void CreateEventW -> @void lpEventAttributes, int bManualReset, int bInitialState, @void lpName;
stub @void CreateFiber -> utype longlong dwStackSize, @func lpStartAddress, @void lpParameter;
stub @void CreateFiberEx -> utype longlong dwStackCommitSize, utype longlong dwStackReserveSize, utype int dwFlags, @func lpStartAddress, @void lpParameter;
stub @void CreateFile2 -> @void lpFileName, utype int dwDesiredAccess, utype int dwShareMode, utype int dwCreationDisposition, @void pCreateExParams;
stub @void CreateFileA -> str lpFileName, utype int dwDesiredAccess, utype int dwShareMode, @void lpSecurityAttributes, utype int dwCreationDisposition, utype int dwFlagsAndAttributes, @void hTemplateFile;
stub @void CreateFileMapping2 -> @void File, @void SecurityAttributes, utype int DesiredAccess, utype int PageProtection, utype int AllocationAttributes, utype longlong MaximumSize, @void Name, @void ExtendedParameters, utype int ParameterCount;
stub @void CreateFileMappingFromApp -> @void hFile, @void SecurityAttributes, utype int PageProtection, utype longlong MaximumSize, @void Name;
stub @void CreateFileMappingNumaW -> @void hFile, @void lpFileMappingAttributes, utype int flProtect, utype int dwMaximumSizeHigh, utype int dwMaximumSizeLow, @void lpName, utype int nndPreferred;
stub @void CreateFileMappingW -> @void hFile, @void lpFileMappingAttributes, utype int flProtect, utype int dwMaximumSizeHigh, utype int dwMaximumSizeLow, @void lpName;
stub @void CreateFileW -> @void lpFileName, utype int dwDesiredAccess, utype int dwShareMode, @void lpSecurityAttributes, utype int dwCreationDisposition, utype int dwFlagsAndAttributes, @void hTemplateFile;
stub int CreateHardLinkA -> str lpFileName, str lpExistingFileName, @void lpSecurityAttributes;
stub int CreateHardLinkW -> @void lpFileName, @void lpExistingFileName, @void lpSecurityAttributes;
stub @void CreateIoCompletionPort -> @void FileHandle, @void ExistingCompletionPort, utype longlong CompletionKey, utype int NumberOfConcurrentThreads;
stub @void CreateMutexA -> @void lpMutexAttributes, int bInitialOwner, str lpName;
stub @void CreateMutexExA -> @void lpMutexAttributes, str lpName, utype int dwFlags, utype int dwDesiredAccess;
stub @void CreateMutexExW -> @void lpMutexAttributes, @void lpName, utype int dwFlags, utype int dwDesiredAccess;
stub @void CreateMutexW -> @void lpMutexAttributes, int bInitialOwner, @void lpName;
stub @void CreateNamedPipeW -> @void lpName, utype int dwOpenMode, utype int dwPipeMode, utype int nMaxInstances, utype int nOutBufferSize, utype int nInBufferSize, utype int nDefaultTimeOut, @void lpSecurityAttributes;
stub int CreatePipe -> @void hReadPipe, @void hWritePipe, @void lpPipeAttributes, utype int nSize;
stub @void CreatePrivateNamespaceW -> @void lpPrivateNamespaceAttributes, @void lpBoundaryDescriptor, @void lpAliasPrefix;
stub int CreatePrivateObjectSecurity -> @void ParentDescriptor, @void CreatorDescriptor, @void NewDescriptor, int IsDirectoryObject, @void Token, @void GenericMapping;
stub int CreatePrivateObjectSecurityEx -> @void ParentDescriptor, @void CreatorDescriptor, @void NewDescriptor, @void ObjectType, int IsContainerObject, utype int AutoInheritFlags, @void Token, @void GenericMapping;
stub int CreatePrivateObjectSecurityWithMultipleInheritance -> @void ParentDescriptor, @void CreatorDescriptor, @void NewDescriptor, @void ObjectTypes, utype int GuidCount, int IsContainerObject, utype int AutoInheritFlags, @void Token, @void GenericMapping;
stub int CreateProcessA -> str lpApplicationName, str lpCommandLine, @void lpProcessAttributes, @void lpThreadAttributes, int bInheritHandles, utype int dwCreationFlags, @void lpEnvironment, str lpCurrentDirectory, @void lpStartupInfo, @void lpProcessInformation;
stub int CreateProcessAsUserA -> @void hToken, str lpApplicationName, str lpCommandLine, @void lpProcessAttributes, @void lpThreadAttributes, int bInheritHandles, utype int dwCreationFlags, @void lpEnvironment, str lpCurrentDirectory, @void lpStartupInfo, @void lpProcessInformation;
stub int CreateProcessAsUserW -> @void hToken, @void lpApplicationName, @void lpCommandLine, @void lpProcessAttributes, @void lpThreadAttributes, int bInheritHandles, utype int dwCreationFlags, @void lpEnvironment, @void lpCurrentDirectory, @void lpStartupInfo, @void lpProcessInformation;
stub int CreateProcessW -> @void lpApplicationName, @void lpCommandLine, @void lpProcessAttributes, @void lpThreadAttributes, int bInheritHandles, utype int dwCreationFlags, @void lpEnvironment, @void lpCurrentDirectory, @void lpStartupInfo, @void lpProcessInformation;
stub @void CreateRemoteThread -> @void hProcess, @void lpThreadAttributes, utype longlong dwStackSize, @func lpStartAddress, @void lpParameter, utype int dwCreationFlags, @int lpThreadId;
stub @void CreateRemoteThreadEx -> @void hProcess, @void lpThreadAttributes, utype longlong dwStackSize, @func lpStartAddress, @void lpParameter, utype int dwCreationFlags, @void lpAttributeList, @int lpThreadId;
stub int CreateRestrictedToken -> @void ExistingTokenHandle, utype int Flags, utype int DisableSidCount, @void SidsToDisable, utype int DeletePrivilegeCount, @void PrivilegesToDelete, utype int RestrictedSidCount, @void SidsToRestrict, @void NewTokenHandle;
stub @void CreateSemaphoreExW -> @void lpSemaphoreAttributes, int lInitialCount, int lMaximumCount, @void lpName, utype int dwFlags, utype int dwDesiredAccess;
stub @void CreateSemaphoreW -> @void lpSemaphoreAttributes, int lInitialCount, int lMaximumCount, @void lpName;
stub utype char CreateSymbolicLinkW -> @void lpSymlinkFileName, @void lpTargetFileName, utype int dwFlags;
stub @void CreateThread -> @void lpThreadAttributes, utype longlong dwStackSize, @func lpStartAddress, @void lpParameter, utype int dwCreationFlags, @int lpThreadId;
stub @void CreateThreadpool -> @void reserved;
stub @void CreateThreadpoolCleanupGroup;
stub @void CreateThreadpoolIo -> @void fl, @func pfnio, @void pv, @void pcbe;
stub @void CreateThreadpoolTimer -> @func pfnti, @void pv, @void pcbe;
stub @void CreateThreadpoolWait -> @func pfnwa, @void pv, @void pcbe;
stub @void CreateThreadpoolWork -> @func pfnwk, @void pv, @void pcbe;
stub @void CreateTimerQueue;
stub int CreateTimerQueueTimer -> @void phNewTimer, @void TimerQueue, @func Callback, @void Parameter, utype int DueTime, utype int Period, utype int Flags;
stub @void CreateWaitableTimerExW -> @void lpTimerAttributes, @void lpTimerName, utype int dwFlags, utype int dwDesiredAccess;
stub @void CreateWaitableTimerW -> @void lpTimerAttributes, int bManualReset, @void lpTimerName;
stub int CveEventWrite -> @void CveId, @void AdditionalDetails;
stub int DeactivateActCtx -> utype int dwFlags, utype longlong ulCookie;
stub int DebugActiveProcess -> utype int dwProcessId;
stub int DebugActiveProcessStop -> utype int dwProcessId;
stub void DebugBreak;
stub @void DecodePointer -> @void Ptr;
stub @void DecodeSystemPointer -> @void Ptr;
stub int DefineDosDeviceW -> utype int dwFlags, @void lpDeviceName, @void lpTargetPath;
stub int DeleteAce -> @void pAcl, utype int dwAceIndex;
stub void DeleteBoundaryDescriptor -> @void BoundaryDescriptor;
stub void DeleteCriticalSection -> @void lpCriticalSection;
stub void DeleteFiber -> @void lpFiber;
stub int DeleteFileA -> str lpFileName;
stub int DeleteFileW -> @void lpFileName;
stub void DeleteProcThreadAttributeList -> @void lpAttributeList;
stub int DeleteSynchronizationBarrier -> @void lpBarrier;
stub int DeleteTimerQueue -> @void TimerQueue;
stub int DeleteTimerQueueEx -> @void TimerQueue, @void CompletionEvent;
stub int DeleteTimerQueueTimer -> @void TimerQueue, @void Timer, @void CompletionEvent;
stub int DeleteVolumeMountPointW -> @void lpszVolumeMountPoint;
stub int DeriveCapabilitySidsFromName -> @void CapName, @void CapabilityGroupSids, @int CapabilityGroupSidCount, @void CapabilitySids, @int CapabilitySidCount;
stub int DestroyPrivateObjectSecurity -> @void ObjectDescriptor;
stub int DeviceIoControl -> @void hDevice, utype int dwIoControlCode, @void lpInBuffer, utype int nInBufferSize, @void lpOutBuffer, utype int nOutBufferSize, @int lpBytesReturned, @void lpOverlapped;
stub int DisableThreadLibraryCalls -> @void hLibModule;
stub void DisassociateCurrentThreadFromCallback -> @void pci;
stub utype int DiscardVirtualMemory -> @void VirtualAddress, utype longlong Size;
stub int DisconnectNamedPipe -> @void hNamedPipe;
stub int DuplicateHandle -> @void hSourceProcessHandle, @void hSourceHandle, @void hTargetProcessHandle, @void lpTargetHandle, utype int dwDesiredAccess, int bInheritHandle, utype int dwOptions;
stub @void EncodePointer -> @void Ptr;
stub @void EncodeSystemPointer -> @void Ptr;
stub void EnterCriticalSection -> @void lpCriticalSection;
stub int EnterSynchronizationBarrier -> @void lpBarrier, utype int dwFlags;
stub int EnumCalendarInfoExEx -> @func pCalInfoEnumProcExEx, @void lpLocaleName, utype int Calendar, @void lpReserved, utype int CalType, longlong lParam;
stub int EnumCalendarInfoExW -> @func lpCalInfoEnumProcEx, utype int Locale, utype int Calendar, utype int CalType;
stub int EnumCalendarInfoW -> @func lpCalInfoEnumProc, utype int Locale, utype int Calendar, utype int CalType;
stub int EnumDateFormatsExEx -> @func lpDateFmtEnumProcExEx, @void lpLocaleName, utype int dwFlags, longlong lParam;
stub int EnumDateFormatsExW -> @func lpDateFmtEnumProcEx, utype int Locale, utype int dwFlags;
stub int EnumDateFormatsW -> @func lpDateFmtEnumProc, utype int Locale, utype int dwFlags;
stub utype int EnumDynamicTimeZoneInformation -> utype int dwIndex, @void lpTimeZoneInformation;
stub int EnumLanguageGroupLocalesW -> @func lpLangGroupLocaleEnumProc, utype int LanguageGroup, utype int dwFlags, longlong lParam;
stub int EnumResourceLanguagesExA -> @void hModule, str lpType, str lpName, @func lpEnumFunc, longlong lParam, utype int dwFlags, utype int LangId;
stub int EnumResourceLanguagesExW -> @void hModule, @void lpType, @void lpName, @func lpEnumFunc, longlong lParam, utype int dwFlags, utype int LangId;
stub int EnumResourceNamesA -> @void hModule, str lpType, @func lpEnumFunc, longlong lParam;
stub int EnumResourceNamesExA -> @void hModule, str lpType, @func lpEnumFunc, longlong lParam, utype int dwFlags, utype int LangId;
stub int EnumResourceNamesExW -> @void hModule, @void lpType, @func lpEnumFunc, longlong lParam, utype int dwFlags, utype int LangId;
stub int EnumResourceNamesW -> @void hModule, @void lpType, @func lpEnumFunc, longlong lParam;
stub int EnumResourceTypesExA -> @void hModule, @func lpEnumFunc, longlong lParam, utype int dwFlags, utype int LangId;
stub int EnumResourceTypesExW -> @void hModule, @func lpEnumFunc, longlong lParam, utype int dwFlags, utype int LangId;
stub int EnumSystemCodePagesW -> @func lpCodePageEnumProc, utype int dwFlags;
stub utype int EnumSystemFirmwareTables -> utype int FirmwareTableProviderSignature, @void pFirmwareTableEnumBuffer, utype int BufferSize;
stub int EnumSystemGeoID -> utype int GeoClass, int ParentGeoId, @func lpGeoEnumProc;
stub int EnumSystemGeoNames -> utype int geoClass, @func geoEnumProc, longlong data;
stub int EnumSystemLanguageGroupsW -> @func lpLanguageGroupEnumProc, utype int dwFlags, longlong lParam;
stub int EnumSystemLocalesA -> @func lpLocaleEnumProc, utype int dwFlags;
stub int EnumSystemLocalesEx -> @func lpLocaleEnumProcEx, utype int dwFlags, longlong lParam, @void lpReserved;
stub int EnumSystemLocalesW -> @func lpLocaleEnumProc, utype int dwFlags;
stub int EnumTimeFormatsEx -> @func lpTimeFmtEnumProcEx, @void lpLocaleName, utype int dwFlags, longlong lParam;
stub int EnumTimeFormatsW -> @func lpTimeFmtEnumProc, utype int Locale, utype int dwFlags;
stub int EnumUILanguagesW -> @func lpUILanguageEnumProc, utype int dwFlags, longlong lParam;
stub int EqualDomainSid -> @void pSid1, @void pSid2, @int pfEqual;
stub int EqualPrefixSid -> @void pSid1, @void pSid2;
stub int EqualSid -> @void pSid1, @void pSid2;
stub int EscapeCommFunction -> @void hFile, utype int dwFunc;
stub void ExitProcess -> utype int uExitCode;
stub void ExitThread -> utype int dwExitCode;
stub utype int ExpandEnvironmentStringsA -> str lpSrc, str lpDst, utype int nSize;
stub utype int ExpandEnvironmentStringsW -> @void lpSrc, @void lpDst, utype int nSize;
stub void ExpungeConsoleCommandHistoryA -> str exe_name;
stub void ExpungeConsoleCommandHistoryW -> @void exe_name;
stub void FatalAppExitA -> utype int uAction, str lpMessageText;
stub void FatalAppExitW -> utype int uAction, @void lpMessageText;
stub int FileTimeToLocalFileTime -> @void lpFileTime, @void lpLocalFileTime;
stub int FileTimeToSystemTime -> @void lpFileTime, @void lpSystemTime;
stub int FindActCtxSectionGuid -> utype int dwFlags, @void lpExtensionGuid, utype int ulSectionId, @void lpGuidToFind, @void ReturnedData;
stub int FindActCtxSectionStringW -> utype int dwFlags, @void lpExtensionGuid, utype int ulSectionId, @void lpStringToFind, @void ReturnedData;
stub int FindClose -> @void hFindFile;
stub int FindCloseChangeNotification -> @void hChangeHandle;
stub @void FindFirstChangeNotificationA -> str lpPathName, int bWatchSubtree, utype int dwNotifyFilter;
stub @void FindFirstChangeNotificationW -> @void lpPathName, int bWatchSubtree, utype int dwNotifyFilter;
stub @void FindFirstFileA -> str lpFileName, @void lpFindFileData;
stub @void FindFirstFileNameW -> @void lpFileName, utype int dwFlags, @int StringLength, @void LinkName;
stub @void FindFirstFileW -> @void lpFileName, @void lpFindFileData;
stub int FindFirstFreeAce -> @void pAcl, @void pAce;
stub @void FindFirstVolumeW -> @void lpszVolumeName, utype int cchBufferLength;
stub int FindNLSString -> utype int Locale, utype int dwFindNLSStringFlags, @void lpStringSource, int cchSource, @void lpStringValue, int cchValue, @int pcchFound;
stub int FindNLSStringEx -> @void lpLocaleName, utype int dwFindNLSStringFlags, @void lpStringSource, int cchSource, @void lpStringValue, int cchValue, @int pcchFound, @void lpVersionInformation, @void lpReserved, longlong sortHandle;
stub int FindNextChangeNotification -> @void hChangeHandle;
stub int FindNextFileA -> @void hFindFile, @void lpFindFileData;
stub int FindNextFileNameW -> @void hFindStream, @int StringLength, @void LinkName;
stub int FindNextFileW -> @void hFindFile, @void lpFindFileData;
stub int FindNextStreamW -> @void hFindStream, @void lpFindStreamData;
stub int FindNextVolumeW -> @void hFindVolume, @void lpszVolumeName, utype int cchBufferLength;
stub int FindPackagesByPackageFamily -> @void packageFamilyName, utype int packageFilters, @int cnt, @void packageFullNames, @int bufferLength, @void buffer, @int packageProperties;
stub @void FindResourceExW -> @void hModule, @void lpType, @void lpName, utype int wLanguage;
stub @void FindResourceW -> @void hModule, @void lpName, @void lpType;
stub int FindStringOrdinal -> utype int dwFindStringOrdinalFlags, @void lpStringSource, int cchSource, @void lpStringValue, int cchValue, int bIgnoreCase;
stub int FindVolumeClose -> @void hFindVolume;
stub utype int FlsAlloc -> @func lpCallback;
stub int FlsFree -> utype int dwFlsIndex;
stub @void FlsGetValue -> utype int dwFlsIndex;
stub @void FlsGetValue2 -> utype int dwTlsIndex;
stub int FlsSetValue -> utype int dwFlsIndex, @void lpFlsData;
stub int FlushConsoleInputBuffer -> @void console_input;
stub int FlushFileBuffers -> @void hFile;
stub int FlushInstructionCache -> @void hProcess, @void lpBaseAddress, utype longlong dwSize;
stub void FlushProcessWriteBuffers;
stub int FlushViewOfFile -> @void lpBaseAddress, utype longlong dwNumberOfBytesToFlush;
stub int FoldStringW -> utype int dwMapFlags, @void lpSrcStr, int cchSrc, @void lpDestStr, int cchDest;
stub int FormatApplicationUserModelId -> @void packageFamilyName, @void packageRelativeApplicationId, @int applicationUserModelIdLength, @void applicationUserModelId;
stub utype int FormatMessageA -> utype int dwFlags, @void lpSource, utype int dwMessageId, utype int dwLanguageId, str lpBuffer, utype int nSize, @void Arguments;
stub utype int FormatMessageW -> utype int dwFlags, @void lpSource, utype int dwMessageId, utype int dwLanguageId, @void lpBuffer, utype int nSize, @void Arguments;
stub int FreeConsole;
stub int FreeEnvironmentStringsA -> str penv;
stub int FreeEnvironmentStringsW -> @void penv;
stub int FreeLibrary -> @void hLibModule;
stub void FreeLibraryAndExitThread -> @void hLibModule, utype int dwExitCode;
stub void FreeLibraryWhenCallbackReturns -> @void pci, @void mod;
stub int FreeResource -> @void hResData;
stub @void FreeSid -> @void pSid;
stub int FreeUserPhysicalPages -> @void hProcess, @longlong NumberOfPages, @longlong PageArray;
stub int GenerateConsoleCtrlEvent -> utype int ctrl_event, utype int process_group_id;
stub utype int GetACP;
stub int GetAce -> @void pAcl, utype int dwAceIndex, @void pAce;
stub int GetAppContainerAce -> @void Acl, utype int StartingAceIndex, @void AppContainerAce, @int AppContainerAceIndex;
stub int GetAppContainerNamedObjectPath -> @void Token, @void AppContainerSid, utype int ObjectPathLength, @void ObjectPath, @int ReturnLength;
stub int GetApplicationRecoveryCallback -> @void hProcess, @void pRecoveryCallback, @void ppvParameter, @int pdwPingInterval, @int pdwFlags;
stub int GetApplicationRestartSettings -> @void hProcess, @void pwzCommandline, @int pcchSize, @int pdwFlags;
stub int GetApplicationUserModelId -> @void hProcess, @int applicationUserModelIdLength, @void applicationUserModelId;
stub int GetApplicationUserModelIdFromToken -> @void token, @int applicationUserModelIdLength, @void applicationUserModelId;
stub int GetCPInfo -> utype int CodePage, @void lpCPInfo;
stub int GetCPInfoExW -> utype int CodePage, utype int dwFlags, @void lpCPInfoEx;
stub int GetCachedSigningLevel -> @void File, @int Flags, @int SigningLevel, @char Thumbprint, @int ThumbprintSize, @int ThumbprintAlgorithm;
stub int GetCalendarInfoEx -> @void lpLocaleName, utype int Calendar, @void lpReserved, utype int CalType, @void lpCalData, int cchData, @int lpValue;
stub int GetCalendarInfoW -> utype int Locale, utype int Calendar, utype int CalType, @void lpCalData, int cchData, @int lpValue;
stub int GetCommConfig -> @void hCommDev, @void lpCC, @int lpdwSize;
stub int GetCommMask -> @void hFile, @int lpEvtMask;
stub int GetCommModemStatus -> @void hFile, @int lpModemStat;
stub utype int GetCommPorts -> @int lpPortNumbers, utype int uPortNumbersCount, @int puPortNumbersFound;
stub int GetCommProperties -> @void hFile, @void lpCommProp;
stub int GetCommState -> @void hFile, @void lpDCB;
stub int GetCommTimeouts -> @void hFile, @void lpCommTimeouts;
stub str GetCommandLineA;
stub @void GetCommandLineW;
stub utype int GetCompressedFileSizeA -> str lpFileName, @int lpFileSizeHigh;
stub utype int GetCompressedFileSizeW -> @void lpFileName, @int lpFileSizeHigh;
stub utype int GetConsoleAliasA -> str source, str target_buffer, utype int target_buffer_length, str exe_name;
stub utype int GetConsoleAliasExesA -> str exe_name_buffer, utype int exe_name_buffer_length;
stub utype int GetConsoleAliasExesLengthA;
stub utype int GetConsoleAliasExesLengthW;
stub utype int GetConsoleAliasExesW -> @void exe_name_buffer, utype int exe_name_buffer_length;
stub utype int GetConsoleAliasW -> @void source, @void target_buffer, utype int target_buffer_length, @void exe_name;
stub utype int GetConsoleAliasesA -> str alias_buffer, utype int alias_buffer_length, str exe_name;
stub utype int GetConsoleAliasesLengthA -> str exe_name;
stub utype int GetConsoleAliasesLengthW -> @void exe_name;
stub utype int GetConsoleAliasesW -> @void alias_buffer, utype int alias_buffer_length, @void exe_name;
stub utype int GetConsoleCP;
stub utype int GetConsoleCommandHistoryA -> str commands, utype int command_buffer_length, str exe_name;
stub utype int GetConsoleCommandHistoryLengthA -> str exe_name;
stub utype int GetConsoleCommandHistoryLengthW -> @void exe_name;
stub utype int GetConsoleCommandHistoryW -> @void commands, utype int command_buffer_length, @void exe_name;
stub int GetConsoleCursorInfo -> @void console_output, @void console_cursor_info;
stub int GetConsoleDisplayMode -> @int mode_flags;
stub int GetConsoleHistoryInfo -> @void console_history_info;
stub int GetConsoleMode -> @void console_handle, @int mode;
stub utype int GetConsoleOriginalTitleA -> str console_title, utype int size_;
stub utype int GetConsoleOriginalTitleW -> @void console_title, utype int size_;
stub utype int GetConsoleOutputCP;
stub utype int GetConsoleProcessList -> @int process_list, utype int process_count;
stub int GetConsoleScreenBufferInfo -> @void console_output, @void console_screen_buffer_info;
stub int GetConsoleScreenBufferInfoEx -> @void console_output, @void console_screen_buffer_info_ex;
stub int GetConsoleSelectionInfo -> @void console_selection_info;
stub utype int GetConsoleTitleA -> str console_title, utype int size_;
stub utype int GetConsoleTitleW -> @void console_title, utype int size_;
stub @void GetConsoleWindow;
stub int GetCurrencyFormatEx -> @void lpLocaleName, utype int dwFlags, @void lpValue, @void lpFormat, @void lpCurrencyStr, int cchCurrency;
stub int GetCurrencyFormatW -> utype int Locale, utype int dwFlags, @void lpValue, @void lpFormat, @void lpCurrencyStr, int cchCurrency;
stub int GetCurrentActCtx -> @void lphActCtx;
stub int GetCurrentApplicationUserModelId -> @int applicationUserModelIdLength, @void applicationUserModelId;
stub int GetCurrentConsoleFont -> @void console_output, int maximum_window, @void console_current_font;
stub int GetCurrentConsoleFontEx -> @void console_output, int maximum_window, @void console_current_font_ex;
stub utype int GetCurrentDirectoryA -> utype int nBufferLength, str lpBuffer;
stub utype int GetCurrentDirectoryW -> utype int nBufferLength, @void lpBuffer;
stub int GetCurrentPackageFamilyName -> @int packageFamilyNameLength, @void packageFamilyName;
stub int GetCurrentPackageFullName -> @int packageFullNameLength, @void packageFullName;
stub int GetCurrentPackageId -> @int bufferLength, @char buffer;
stub int GetCurrentPackageInfo -> utype int flags, @int bufferLength, @char buffer, @int cnt;
stub int GetCurrentPackagePath -> @int pathLength, @void path;
stub @void GetCurrentProcess;
stub utype int GetCurrentProcessId;
stub utype int GetCurrentProcessorNumber;
stub void GetCurrentProcessorNumberEx -> @void ProcNumber;
stub @void GetCurrentThread;
stub utype int GetCurrentThreadId;
stub void GetCurrentThreadStackLimits -> @longlong LowLimit, @longlong HighLimit;
stub int GetDateFormatA -> utype int Locale, utype int dwFlags, @void lpDate, str lpFormat, str lpDateStr, int cchDate;
stub int GetDateFormatEx -> @void lpLocaleName, utype int dwFlags, @void lpDate, @void lpFormat, @void lpDateStr, int cchDate, @void lpCalendar;
stub int GetDateFormatW -> utype int Locale, utype int dwFlags, @void lpDate, @void lpFormat, @void lpDateStr, int cchDate;
stub int GetDiskFreeSpaceA -> str lpRootPathName, @int lpSectorsPerCluster, @int lpBytesPerSector, @int lpNumberOfFreeClusters, @int lpTotalNumberOfClusters;
stub int GetDiskFreeSpaceExA -> str lpDirectoryName, @longlong lpFreeBytesAvailableToCaller, @longlong lpTotalNumberOfBytes, @longlong lpTotalNumberOfFreeBytes;
stub int GetDiskFreeSpaceExW -> @void lpDirectoryName, @longlong lpFreeBytesAvailableToCaller, @longlong lpTotalNumberOfBytes, @longlong lpTotalNumberOfFreeBytes;
stub int GetDiskFreeSpaceW -> @void lpRootPathName, @int lpSectorsPerCluster, @int lpBytesPerSector, @int lpNumberOfFreeClusters, @int lpTotalNumberOfClusters;
stub int GetDiskSpaceInformationA -> str rootPath, @void diskSpaceInfo;
stub int GetDiskSpaceInformationW -> @void rootPath, @void diskSpaceInfo;
stub utype int GetDriveTypeA -> str lpRootPathName;
stub utype int GetDriveTypeW -> @void lpRootPathName;
stub int GetDurationFormatEx -> @void lpLocaleName, utype int dwFlags, @void lpDuration, utype longlong ullDuration, @void lpFormat, @void lpDurationStr, int cchDuration;
stub utype int GetDynamicTimeZoneInformation -> @void pTimeZoneInformation;
stub utype int GetDynamicTimeZoneInformationEffectiveYears -> @void lpTimeZoneInformation, @int FirstYear, @int LastYear;
stub utype longlong GetEnabledXStateFeatures;
stub str GetEnvironmentStrings;
stub @void GetEnvironmentStringsW;
stub utype int GetEnvironmentVariableA -> str lpName, str lpBuffer, utype int nSize;
stub utype int GetEnvironmentVariableW -> @void lpName, @void lpBuffer, utype int nSize;
stub utype int GetErrorMode;
stub int GetExitCodeProcess -> @void hProcess, @int lpExitCode;
stub int GetExitCodeThread -> @void hThread, @int lpExitCode;
stub utype int GetFileAttributesA -> str lpFileName;
stub utype int GetFileAttributesW -> @void lpFileName;
stub int GetFileInformationByHandle -> @void hFile, @void lpFileInformation;
stub int GetFileMUIInfo -> utype int dwFlags, @void pcwszFilePath, @void pFileMUIInfo, @int pcbFileMUIInfo;
stub int GetFileMUIPath -> utype int dwFlags, @void pcwszFilePath, @void pwszLanguage, @int pcchLanguage, @void pwszFileMUIPath, @int pcchFileMUIPath, @longlong pululEnumerator;
stub int GetFileSecurityW -> @void lpFileName, utype int RequestedInformation, @void pSecurityDescriptor, utype int nLength, @int lpnLengthNeeded;
stub utype int GetFileSize -> @void hFile, @int lpFileSizeHigh;
stub int GetFileSizeEx -> @void hFile, @longlong lpFileSize;
stub int GetFileTime -> @void hFile, @void lpCreationTime, @void lpLastAccessTime, @void lpLastWriteTime;
stub utype int GetFileType -> @void hFile;
stub int GetFileVersionInfoA -> str lptstrFilename, utype int dwHandle, utype int dwLen, @void lpData;
stub int GetFileVersionInfoExA -> utype int dwFlags, str lpwstrFilename, utype int dwHandle, utype int dwLen, @void lpData;
stub int GetFileVersionInfoExW -> utype int dwFlags, @void lpwstrFilename, utype int dwHandle, utype int dwLen, @void lpData;
stub utype int GetFileVersionInfoSizeA -> str lptstrFilename, @int lpdwHandle;
stub utype int GetFileVersionInfoSizeExA -> utype int dwFlags, str lpwstrFilename, @int lpdwHandle;
stub utype int GetFileVersionInfoSizeExW -> utype int dwFlags, @void lpwstrFilename, @int lpdwHandle;
stub utype int GetFileVersionInfoSizeW -> @void lptstrFilename, @int lpdwHandle;
stub int GetFileVersionInfoW -> @void lptstrFilename, utype int dwHandle, utype int dwLen, @void lpData;
stub utype int GetFinalPathNameByHandleA -> @void hFile, str lpszFilePath, utype int cchFilePath, utype int dwFlags;
stub utype int GetFinalPathNameByHandleW -> @void hFile, @void lpszFilePath, utype int cchFilePath, utype int dwFlags;
stub utype int GetFullPathNameA -> str lpFileName, utype int nBufferLength, str lpBuffer, @void lpFilePart;
stub utype int GetFullPathNameW -> @void lpFileName, utype int nBufferLength, @void lpBuffer, @void lpFilePart;
stub int GetGeoInfoEx -> @void location, utype int geoType, @void geoData, int geoDataCount;
stub int GetGeoInfoW -> int Location, utype int GeoType, @void lpGeoData, int cchData, utype int LangId;
stub int GetHandleInformation -> @void hObject, @int lpdwFlags;
stub int GetKernelObjectSecurity -> @void Handle, utype int RequestedInformation, @void pSecurityDescriptor, utype int nLength, @int lpnLengthNeeded;
stub utype longlong GetLargePageMinimum;
stub utype int GetLastError;
stub utype int GetLengthSid -> @void pSid;
stub void GetLocalTime -> @void lpSystemTime;
stub int GetLocaleInfoA -> utype int Locale, utype int LCType, str lpLCData, int cchData;
stub int GetLocaleInfoEx -> @void lpLocaleName, utype int LCType, @void lpLCData, int cchData;
stub int GetLocaleInfoW -> utype int Locale, utype int LCType, @void lpLCData, int cchData;
stub utype int GetLogicalDriveStringsW -> utype int nBufferLength, @void lpBuffer;
stub utype int GetLogicalDrives;
stub int GetLogicalProcessorInformation -> @void Buffer, @int ReturnedLength;
stub utype int GetLongPathNameA -> str lpszShortPath, str lpszLongPath, utype int cchBuffer;
stub utype int GetLongPathNameW -> @void lpszShortPath, @void lpszLongPath, utype int cchBuffer;
stub int GetMachineTypeAttributes -> utype int Machine, @void MachineTypeAttributes;
stub int GetMemoryErrorHandlingCapabilities -> @int Capabilities;
stub utype int GetModuleFileNameA -> @void hModule, str lpFilename, utype int nSize;
stub utype int GetModuleFileNameW -> @void hModule, @void lpFilename, utype int nSize;
stub @void GetModuleHandleA -> str lpModuleName;
stub int GetModuleHandleExA -> utype int dwFlags, str lpModuleName, @void phModule;
stub int GetModuleHandleExW -> utype int dwFlags, @void lpModuleName, @void phModule;
stub @void GetModuleHandleW -> @void lpModuleName;
stub int GetNLSVersion -> utype int Function, utype int Locale, @void lpVersionInformation;
stub int GetNLSVersionEx -> utype int function, @void lpLocaleName, @void lpVersionInformation;
stub int GetNamedPipeClientComputerNameW -> @void Pipe, @void ClientComputerName, utype int ClientComputerNameLength;
stub int GetNamedPipeHandleStateW -> @void hNamedPipe, @int lpState, @int lpCurInstances, @int lpMaxCollectionCount, @int lpCollectDataTimeout, @void lpUserName, utype int nMaxUserNameSize;
stub int GetNamedPipeInfo -> @void hNamedPipe, @int lpFlags, @int lpOutBufferSize, @int lpInBufferSize, @int lpMaxInstances;
stub void GetNativeSystemInfo -> @void lpSystemInfo;
stub int GetNumaHighestNodeNumber -> @int HighestNodeNumber;
stub int GetNumaNodeProcessorMaskEx -> utype int Node, @void ProcessorMask;
stub int GetNumaProximityNodeEx -> utype int ProximityId, @int NodeNumber;
stub int GetNumberFormatEx -> @void lpLocaleName, utype int dwFlags, @void lpValue, @void lpFormat, @void lpNumberStr, int cchNumber;
stub int GetNumberFormatW -> utype int Locale, utype int dwFlags, @void lpValue, @void lpFormat, @void lpNumberStr, int cchNumber;
stub int GetNumberOfConsoleInputEvents -> @void console_input, @int number_of_events;
stub int GetNumberOfConsoleMouseButtons -> @int number_of_mouse_buttons;
stub utype int GetOEMCP;
stub int GetOsSafeBootMode -> @int Flags;
stub int GetOverlappedResult -> @void hFile, @void lpOverlapped, @int lpNumberOfBytesTransferred, int bWait;
stub int GetOverlappedResultEx -> @void hFile, @void lpOverlapped, @int lpNumberOfBytesTransferred, utype int dwMilliseconds, int bAlertable;
stub int GetPackageFamilyName -> @void hProcess, @int packageFamilyNameLength, @void packageFamilyName;
stub int GetPackageFamilyNameFromToken -> @void token, @int packageFamilyNameLength, @void packageFamilyName;
stub int GetPackageFullName -> @void hProcess, @int packageFullNameLength, @void packageFullName;
stub int GetPackageFullNameFromToken -> @void token, @int packageFullNameLength, @void packageFullName;
stub int GetPackageId -> @void hProcess, @int bufferLength, @char buffer;
stub int GetPackagePath -> @void packageId, utype int reserved, @int pathLength, @void path;
stub int GetPackagePathByFullName -> @void packageFullName, @int pathLength, @void path;
stub int GetPackagesByPackageFamily -> @void packageFamilyName, @int cnt, @void packageFullNames, @int bufferLength, @void buffer;
stub int GetPhysicallyInstalledSystemMemory -> @longlong TotalMemoryInKilobytes;
stub utype int GetPriorityClass -> @void hProcess;
stub int GetPrivateObjectSecurity -> @void ObjectDescriptor, utype int SecurityInformation, @void ResultantDescriptor, utype int DescriptorLength, @int ReturnLength;
stub @longlong GetProcAddress -> @void hModule, str lpProcName;
stub int GetProcessDefaultCpuSetMasks -> @void Process, @void CpuSetMasks, utype int CpuSetMaskCount, @int RequiredMaskCount;
stub int GetProcessDefaultCpuSets -> @void Process, @int CpuSetIds, utype int CpuSetIdCount, @int RequiredIdCount;
stub int GetProcessGroupAffinity -> @void hProcess, @int GroupCount, @int GroupArray;
stub int GetProcessHandleCount -> @void hProcess, @int pdwHandleCount;
stub @void GetProcessHeap;
stub utype int GetProcessHeaps -> utype int NumberOfHeaps, @void ProcessHeaps;
stub utype int GetProcessId -> @void Process;
stub utype int GetProcessIdOfThread -> @void Thread;
stub int GetProcessPreferredUILanguages -> utype int dwFlags, @int pulNumLanguages, @void pwszLanguagesBuffer, @int pcchLanguagesBuffer;
stub int GetProcessPriorityBoost -> @void hProcess, @int pDisablePriorityBoost;
stub int GetProcessShutdownParameters -> @int lpdwLevel, @int lpdwFlags;
stub int GetProcessTimes -> @void hProcess, @void lpCreationTime, @void lpExitTime, @void lpKernelTime, @void lpUserTime;
stub utype int GetProcessVersion -> utype int ProcessId;
stub int GetProcessWorkingSetSize -> @void hProcess, @longlong lpMinimumWorkingSetSize, @longlong lpMaximumWorkingSetSize;
stub int GetProcessWorkingSetSizeEx -> @void hProcess, @longlong lpMinimumWorkingSetSize, @longlong lpMaximumWorkingSetSize, @int Flags;
stub int GetProcessorSystemCycleTime -> utype int Group, @void Buffer, @int ReturnedLength;
stub int GetProductInfo -> utype int dwOSMajorVersion, utype int dwOSMinorVersion, utype int dwSpMajorVersion, utype int dwSpMinorVersion, @int pdwReturnedProductType;
stub int GetQueuedCompletionStatus -> @void CompletionPort, @int lpNumberOfBytesTransferred, @longlong lpCompletionKey, @void lpOverlapped, utype int dwMilliseconds;
stub int GetQueuedCompletionStatusEx -> @void CompletionPort, @void lpCompletionPortEntries, utype int ulCount, @int ulNumEntriesRemoved, utype int dwMilliseconds, int fAlertable;
stub int GetSecurityDescriptorControl -> @void pSecurityDescriptor, @int pControl, @int lpdwRevision;
stub int GetSecurityDescriptorDacl -> @void pSecurityDescriptor, @int lpbDaclPresent, @void pDacl, @int lpbDaclDefaulted;
stub int GetSecurityDescriptorGroup -> @void pSecurityDescriptor, @void pGroup, @int lpbGroupDefaulted;
stub utype int GetSecurityDescriptorLength -> @void pSecurityDescriptor;
stub int GetSecurityDescriptorOwner -> @void pSecurityDescriptor, @void pOwner, @int lpbOwnerDefaulted;
stub utype int GetSecurityDescriptorRMControl -> @void SecurityDescriptor, @char RMControl;
stub int GetSecurityDescriptorSacl -> @void pSecurityDescriptor, @int lpbSaclPresent, @void pSacl, @int lpbSaclDefaulted;
stub utype int GetShortPathNameW -> @void lpszLongPath, @void lpszShortPath, utype int cchBuffer;
stub @void GetSidIdentifierAuthority -> @void pSid;
stub utype int GetSidLengthRequired -> utype char nSubAuthorityCount;
stub @int GetSidSubAuthority -> @void pSid, utype int nSubAuthority;
stub @char GetSidSubAuthorityCount -> @void pSid;
stub int GetStagedPackageOrigin -> @void packageFullName, @void origin;
stub int GetStagedPackagePathByFullName -> @void packageFullName, @int pathLength, @void path;
stub void GetStartupInfoW -> @void lpStartupInfo;
stub @void GetStdHandle -> utype int nStdHandle;
stub int GetStringScripts -> utype int dwFlags, @void lpString, int cchString, @void lpScripts, int cchScripts;
stub int GetStringTypeA -> utype int Locale, utype int dwInfoType, str lpSrcStr, int cchSrc, @int lpCharType;
stub int GetStringTypeExW -> utype int Locale, utype int dwInfoType, @void lpSrcStr, int cchSrc, @int lpCharType;
stub int GetStringTypeW -> utype int dwInfoType, @void lpSrcStr, int cchSrc, @int lpCharType;
stub int GetSystemCpuSetInformation -> @void Information, utype int BufferLength, @int ReturnedLength, @void Process, utype int Flags;
stub utype int GetSystemDefaultLCID;
stub utype int GetSystemDefaultLangID;
stub int GetSystemDefaultLocaleName -> @void lpLocaleName, int cchLocaleName;
stub utype int GetSystemDefaultUILanguage;
stub utype int GetSystemDirectoryA -> str lpBuffer, utype int uSize;
stub utype int GetSystemDirectoryW -> @void lpBuffer, utype int uSize;
stub int GetSystemFileCacheSize -> @longlong lpMinimumFileCacheSize, @longlong lpMaximumFileCacheSize, @int lpFlags;
stub utype int GetSystemFirmwareTable -> utype int FirmwareTableProviderSignature, utype int FirmwareTableID, @void pFirmwareTableBuffer, utype int BufferSize;
stub void GetSystemInfo -> @void lpSystemInfo;
stub int GetSystemPreferredUILanguages -> utype int dwFlags, @int pulNumLanguages, @void pwszLanguagesBuffer, @int pcchLanguagesBuffer;
stub void GetSystemTime -> @void lpSystemTime;
stub int GetSystemTimeAdjustment -> @int lpTimeAdjustment, @int lpTimeIncrement, @int lpTimeAdjustmentDisabled;
stub void GetSystemTimeAsFileTime -> @void lpSystemTimeAsFileTime;
stub void GetSystemTimePreciseAsFileTime -> @void lpSystemTimeAsFileTime;
stub int GetSystemTimes -> @void lpIdleTime, @void lpKernelTime, @void lpUserTime;
stub utype int GetSystemWindowsDirectoryA -> str lpBuffer, utype int uSize;
stub utype int GetSystemWindowsDirectoryW -> @void lpBuffer, utype int uSize;
stub utype int GetSystemWow64Directory2A -> str lpBuffer, utype int uSize, utype int ImageFileMachineType;
stub utype int GetSystemWow64Directory2W -> @void lpBuffer, utype int uSize, utype int ImageFileMachineType;
stub utype int GetSystemWow64DirectoryA -> str lpBuffer, utype int uSize;
stub utype int GetSystemWow64DirectoryW -> @void lpBuffer, utype int uSize;
stub utype int GetTempFileNameA -> str lpPathName, str lpPrefixString, utype int uUnique, str lpTempFileName;
stub utype int GetTempFileNameW -> @void lpPathName, @void lpPrefixString, utype int uUnique, @void lpTempFileName;
stub utype int GetTempPathA -> utype int nBufferLength, str lpBuffer;
stub utype int GetTempPathW -> utype int nBufferLength, @void lpBuffer;
stub int GetThreadContext -> @void hThread, @void lpContext;
stub int GetThreadDescription -> @void hThread, @void ppszThreadDescription;
stub utype int GetThreadErrorMode;
stub int GetThreadGroupAffinity -> @void hThread, @void GroupAffinity;
stub int GetThreadIOPendingFlag -> @void hThread, @int lpIOIsPending;
stub utype int GetThreadId -> @void Thread;
stub int GetThreadIdealProcessorEx -> @void hThread, @void lpIdealProcessor;
stub utype int GetThreadLocale;
stub int GetThreadPreferredUILanguages -> utype int dwFlags, @int pulNumLanguages, @void pwszLanguagesBuffer, @int pcchLanguagesBuffer;
stub int GetThreadPriority -> @void hThread;
stub int GetThreadPriorityBoost -> @void hThread, @int pDisablePriorityBoost;
stub int GetThreadSelectedCpuSetMasks -> @void Thread, @void CpuSetMasks, utype int CpuSetMaskCount, @int RequiredMaskCount;
stub int GetThreadSelectedCpuSets -> @void Thread, @int CpuSetIds, utype int CpuSetIdCount, @int RequiredIdCount;
stub int GetThreadTimes -> @void hThread, @void lpCreationTime, @void lpExitTime, @void lpKernelTime, @void lpUserTime;
stub utype int GetThreadUILanguage;
stub utype int GetTickCount;
stub utype longlong GetTickCount64;
stub int GetTimeFormatA -> utype int Locale, utype int dwFlags, @void lpTime, str lpFormat, str lpTimeStr, int cchTime;
stub int GetTimeFormatEx -> @void lpLocaleName, utype int dwFlags, @void lpTime, @void lpFormat, @void lpTimeStr, int cchTime;
stub int GetTimeFormatW -> utype int Locale, utype int dwFlags, @void lpTime, @void lpFormat, @void lpTimeStr, int cchTime;
stub utype int GetTimeZoneInformation -> @void lpTimeZoneInformation;
stub int GetTimeZoneInformationForYear -> utype int wYear, @void pdtzi, @void ptzi;
stub int GetUILanguageInfo -> utype int dwFlags, @void pwmszLanguage, @void pwszFallbackLanguages, @int pcchFallbackLanguages, @int pAttributes;
stub int GetUserDefaultGeoName -> @void geoName, int geoNameCount;
stub utype int GetUserDefaultLCID;
stub utype int GetUserDefaultLangID;
stub int GetUserDefaultLocaleName -> @void lpLocaleName, int cchLocaleName;
stub utype int GetUserDefaultUILanguage;
stub int GetUserGeoID -> utype int GeoClass;
stub int GetUserPreferredUILanguages -> utype int dwFlags, @int pulNumLanguages, @void pwszLanguagesBuffer, @int pcchLanguagesBuffer;
stub utype int GetVersion;
stub int GetVersionExA -> @void lpVersionInformation;
stub int GetVersionExW -> @void lpVersionInformation;
stub int GetVolumeInformationA -> str lpRootPathName, str lpVolumeNameBuffer, utype int nVolumeNameSize, @int lpVolumeSerialNumber, @int lpMaximumComponentLength, @int lpFileSystemFlags, str lpFileSystemNameBuffer, utype int nFileSystemNameSize;
stub int GetVolumeInformationByHandleW -> @void hFile, @void lpVolumeNameBuffer, utype int nVolumeNameSize, @int lpVolumeSerialNumber, @int lpMaximumComponentLength, @int lpFileSystemFlags, @void lpFileSystemNameBuffer, utype int nFileSystemNameSize;
stub int GetVolumeInformationW -> @void lpRootPathName, @void lpVolumeNameBuffer, utype int nVolumeNameSize, @int lpVolumeSerialNumber, @int lpMaximumComponentLength, @int lpFileSystemFlags, @void lpFileSystemNameBuffer, utype int nFileSystemNameSize;
stub int GetVolumeNameForVolumeMountPointW -> @void lpszVolumeMountPoint, @void lpszVolumeName, utype int cchBufferLength;
stub int GetVolumePathNameW -> @void lpszFileName, @void lpszVolumePathName, utype int cchBufferLength;
stub int GetVolumePathNamesForVolumeNameW -> @void lpszVolumeName, @void lpszVolumePathNames, utype int cchBufferLength, @int lpcchReturnLength;
stub int GetWindowsAccountDomainSid -> @void pSid, @void pDomainSid, @int cbDomainSid;
stub utype int GetWindowsDirectoryA -> str lpBuffer, utype int uSize;
stub utype int GetWindowsDirectoryW -> @void lpBuffer, utype int uSize;
stub utype int GetWriteWatch -> utype int dwFlags, @void lpBaseAddress, utype longlong dwRegionSize, @void lpAddresses, @longlong lpdwCount, @int lpdwGranularity;
stub int GetXStateFeaturesMask -> @void Context, @longlong FeatureMask;
stub @void GlobalAlloc -> utype int uFlags, utype longlong dwBytes;
stub utype int GlobalFlags -> @void hMem;
stub @void GlobalFree -> @void hMem;
stub @void GlobalHandle -> @void pMem;
stub @void GlobalLock -> @void hMem;
stub int GlobalMemoryStatusEx -> @void lpBuffer;
stub @void GlobalReAlloc -> @void hMem, utype longlong dwBytes, utype int uFlags;
stub utype longlong GlobalSize -> @void hMem;
stub int GlobalUnlock -> @void hMem;
stub @void HeapAlloc -> @void hHeap, utype int dwFlags, utype longlong dwBytes;
stub utype longlong HeapCompact -> @void hHeap, utype int dwFlags;
stub @void HeapCreate -> utype int flOptions, utype longlong dwInitialSize, utype longlong dwMaximumSize;
stub int HeapDestroy -> @void hHeap;
stub int HeapFree -> @void hHeap, utype int dwFlags, @void lpMem;
stub int HeapLock -> @void hHeap;
stub @void HeapReAlloc -> @void hHeap, utype int dwFlags, @void lpMem, utype longlong dwBytes;
stub utype longlong HeapSize -> @void hHeap, utype int dwFlags, @void lpMem;
stub int HeapSummary -> @void hHeap, utype int dwFlags, @void lpSummary;
stub int HeapUnlock -> @void hHeap;
stub int HeapValidate -> @void hHeap, utype int dwFlags, @void lpMem;
stub int HeapWalk -> @void hHeap, @void lpEntry;
stub int IdnToAscii -> utype int dwFlags, @void lpUnicodeCharStr, int cchUnicodeChar, @void lpASCIICharStr, int cchASCIIChar;
stub int IdnToNameprepUnicode -> utype int dwFlags, @void lpUnicodeCharStr, int cchUnicodeChar, @void lpNameprepCharStr, int cchNameprepChar;
stub int IdnToUnicode -> utype int dwFlags, @void lpASCIICharStr, int cchASCIIChar, @void lpUnicodeCharStr, int cchUnicodeChar;
stub int ImpersonateAnonymousToken -> @void ThreadHandle;
stub int ImpersonateLoggedOnUser -> @void hToken;
stub int ImpersonateNamedPipeClient -> @void hNamedPipe;
stub int InitOnceBeginInitialize -> @void lpInitOnce, utype int dwFlags, @int fPending, @void lpContext;
stub int InitOnceComplete -> @void lpInitOnce, utype int dwFlags, @void lpContext;
stub int InitOnceExecuteOnce -> @void InitOnce, @func InitFn, @void Parameter, @void Context;
stub void InitOnceInitialize -> @void InitOnce;
stub int InitializeAcl -> @void pAcl, utype int nAclLength, utype int dwAclRevision;
stub void InitializeConditionVariable -> @void ConditionVariable;
stub int InitializeContext -> @void Buffer, utype int ContextFlags, @void Context, @int ContextLength;
stub int InitializeContext2 -> @void Buffer, utype int ContextFlags, @void Context, @int ContextLength, utype longlong XStateCompactionMask;
stub void InitializeCriticalSection -> @void lpCriticalSection;
stub int InitializeCriticalSectionAndSpinCount -> @void lpCriticalSection, utype int dwSpinCount;
stub int InitializeCriticalSectionEx -> @void lpCriticalSection, utype int dwSpinCount, utype int Flags;
stub int InitializeProcThreadAttributeList -> @void lpAttributeList, utype int dwAttributeCount, utype int dwFlags, @longlong lpSize;
stub void InitializeSListHead -> @void ListHead;
stub void InitializeSRWLock -> @void SRWLock;
stub int InitializeSecurityDescriptor -> @void pSecurityDescriptor, utype int dwRevision;
stub int InitializeSid -> @void Sid, @void pIdentifierAuthority, utype char nSubAuthorityCount;
stub int InitializeSynchronizationBarrier -> @void lpBarrier, int lTotalThreads, int lSpinCount;
stub @void InterlockedFlushSList -> @void ListHead;
stub @void InterlockedPopEntrySList -> @void ListHead;
stub @void InterlockedPushEntrySList -> @void ListHead, @void ListEntry;
stub @void InterlockedPushListSListEx -> @void ListHead, @void List, @void ListEnd, utype int Count;
stub int IsCharAlphaA -> char ch;
stub int IsCharAlphaNumericA -> char ch;
stub int IsCharLowerA -> char ch;
stub int IsCharUpperA -> char ch;
stub int IsDBCSLeadByte -> utype char TestChar;
stub int IsDBCSLeadByteEx -> utype int CodePage, utype char TestChar;
stub int IsDebuggerPresent;
stub int IsNLSDefinedString -> utype int Function, utype int dwFlags, @void lpVersionInformation, @void lpString, int cchStr;
stub int IsProcessInJob -> @void ProcessHandle, @void JobHandle, @int Result;
stub int IsProcessorFeaturePresent -> utype int ProcessorFeature;
stub int IsThreadAFiber;
stub int IsThreadpoolTimerSet -> @void pti;
stub int IsTokenRestricted -> @void TokenHandle;
stub int IsValidAcl -> @void pAcl;
stub int IsValidCodePage -> utype int CodePage;
stub int IsValidLanguageGroup -> utype int LanguageGroup, utype int dwFlags;
stub int IsValidLocale -> utype int Locale, utype int dwFlags;
stub int IsValidLocaleName -> @void lpLocaleName;
stub utype int IsValidNLSVersion -> utype int function, @void lpLocaleName, @void lpVersionInformation;
stub int IsValidSecurityDescriptor -> @void pSecurityDescriptor;
stub int IsValidSid -> @void pSid;
stub int IsWow64GuestMachineSupported -> utype int WowGuestMachine, @int MachineIsSupported;
stub int IsWow64Process -> @void hProcess, @int Wow64Process;
stub int IsWow64Process2 -> @void hProcess, @int pProcessMachine, @int pNativeMachine;
stub int LCIDToLocaleName -> utype int Locale, @void lpName, int cchName, utype int dwFlags;
stub int LCMapStringA -> utype int Locale, utype int dwMapFlags, str lpSrcStr, int cchSrc, str lpDestStr, int cchDest;
stub int LCMapStringEx -> @void lpLocaleName, utype int dwMapFlags, @void lpSrcStr, int cchSrc, @void lpDestStr, int cchDest, @void lpVersionInformation, @void lpReserved, longlong sortHandle;
stub int LCMapStringW -> utype int Locale, utype int dwMapFlags, @void lpSrcStr, int cchSrc, @void lpDestStr, int cchDest;
stub void LeaveCriticalSection -> @void lpCriticalSection;
stub void LeaveCriticalSectionWhenCallbackReturns -> @void pci, @void pcs;
stub @void LoadLibraryA -> str lpLibFileName;
stub @void LoadLibraryExA -> str lpLibFileName, @void hFile, utype int dwFlags;
stub @void LoadLibraryExW -> @void lpLibFileName, @void hFile, utype int dwFlags;
stub @void LoadLibraryW -> @void lpLibFileName;
stub @void LoadPackagedLibrary -> @void lpwLibFileName, utype int Reserved;
stub @void LoadResource -> @void hModule, @void hResInfo;
stub int LoadStringA -> @void hInstance, utype int uID, str lpBuffer, int cchBufferMax;
stub int LoadStringByReference -> utype int Flags, @void Language, @void SourceString, @void Buffer, utype int cchBuffer, @void Directory, @int pcchBufferOut;
stub int LoadStringW -> @void hInstance, utype int uID, @void lpBuffer, int cchBufferMax;
stub @void LocalAlloc -> utype int uFlags, utype longlong uBytes;
stub int LocalFileTimeToFileTime -> @void lpLocalFileTime, @void lpFileTime;
stub utype int LocalFlags -> @void hMem;
stub @void LocalFree -> @void hMem;
stub @void LocalLock -> @void hMem;
stub @void LocalReAlloc -> @void hMem, utype longlong uBytes, utype int uFlags;
stub utype longlong LocalSize -> @void hMem;
stub int LocalUnlock -> @void hMem;
stub utype int LocaleNameToLCID -> @void lpName, utype int dwFlags;
stub @void LocateXStateFeature -> @void Context, utype int FeatureId, @int Length;
stub int LockFile -> @void hFile, utype int dwFileOffsetLow, utype int dwFileOffsetHigh, utype int nNumberOfBytesToLockLow, utype int nNumberOfBytesToLockHigh;
stub int LockFileEx -> @void hFile, utype int dwFlags, utype int dwReserved, utype int nNumberOfBytesToLockLow, utype int nNumberOfBytesToLockHigh, @void lpOverlapped;
stub @void LockResource -> @void hResData;
stub int MakeAbsoluteSD -> @void pSelfRelativeSecurityDescriptor, @void pAbsoluteSecurityDescriptor, @int lpdwAbsoluteSecurityDescriptorSize, @void pDacl, @int lpdwDaclSize, @void pSacl, @int lpdwSaclSize, @void pOwner, @int lpdwOwnerSize, @void pPrimaryGroup, @int lpdwPrimaryGroupSize;
stub int MakeSelfRelativeSD -> @void pAbsoluteSecurityDescriptor, @void pSelfRelativeSecurityDescriptor, @int lpdwBufferLength;
stub void MapGenericMask -> @int AccessMask, @void GenericMapping;
stub int MapUserPhysicalPages -> @void VirtualAddress, utype longlong NumberOfPages, @longlong PageArray;
stub @void MapViewOfFile -> @void hFileMappingObject, utype int dwDesiredAccess, utype int dwFileOffsetHigh, utype int dwFileOffsetLow, utype longlong dwNumberOfBytesToMap;
stub @void MapViewOfFile3 -> @void FileMapping, @void Process, @void BaseAddress, utype longlong Offset, utype longlong ViewSize, utype int AllocationType, utype int PageProtection, @void ExtendedParameters, utype int ParameterCount;
stub @void MapViewOfFile3FromApp -> @void FileMapping, @void Process, @void BaseAddress, utype longlong Offset, utype longlong ViewSize, utype int AllocationType, utype int PageProtection, @void ExtendedParameters, utype int ParameterCount;
stub @void MapViewOfFileEx -> @void hFileMappingObject, utype int dwDesiredAccess, utype int dwFileOffsetHigh, utype int dwFileOffsetLow, utype longlong dwNumberOfBytesToMap, @void lpBaseAddress;
stub @void MapViewOfFileExNuma -> @void hFileMappingObject, utype int dwDesiredAccess, utype int dwFileOffsetHigh, utype int dwFileOffsetLow, utype longlong dwNumberOfBytesToMap, @void lpBaseAddress, utype int nndPreferred;
stub @void MapViewOfFileFromApp -> @void hFileMappingObject, utype int DesiredAccess, utype longlong FileOffset, utype longlong NumberOfBytesToMap;
stub @void MapViewOfFileNuma2 -> @void FileMappingHandle, @void ProcessHandle, utype longlong Offset, @void BaseAddress, utype longlong ViewSize, utype int AllocationType, utype int PageProtection, utype int PreferredNode;
stub int MoveFileExW -> @void lpExistingFileName, @void lpNewFileName, utype int dwFlags;
stub int MoveFileWithProgressW -> @void lpExistingFileName, @void lpNewFileName, @func lpProgressRoutine, @void lpData, utype int dwFlags;
stub int MulDiv -> int nNumber, int nNumerator, int nDenominator;
stub int MultiByteToWideChar -> utype int CodePage, utype int dwFlags, str lpMultiByteStr, int cbMultiByte, @void lpWideCharStr, int cchWideChar;
stub int NeedCurrentDirectoryForExePathA -> str ExeName;
stub int NeedCurrentDirectoryForExePathW -> @void ExeName;
stub int ObjectCloseAuditAlarmW -> @void SubsystemName, @void HandleId, int GenerateOnClose;
stub int ObjectDeleteAuditAlarmW -> @void SubsystemName, @void HandleId, int GenerateOnClose;
stub int ObjectOpenAuditAlarmW -> @void SubsystemName, @void HandleId, @void ObjectTypeName, @void ObjectName, @void pSecurityDescriptor, @void ClientToken, utype int DesiredAccess, utype int GrantedAccess, @void Privileges, int ObjectCreation, int AccessGranted, @int GenerateOnClose;
stub int ObjectPrivilegeAuditAlarmW -> @void SubsystemName, @void HandleId, @void ClientToken, utype int DesiredAccess, @void Privileges, int AccessGranted;
stub @void OpenCommPort -> utype int uPortNumber, utype int dwDesiredAccess, utype int dwFlagsAndAttributes;
stub @void OpenEventA -> utype int dwDesiredAccess, int bInheritHandle, str lpName;
stub @void OpenEventW -> utype int dwDesiredAccess, int bInheritHandle, @void lpName;
stub @void OpenFileById -> @void hVolumeHint, @void lpFileId, utype int dwDesiredAccess, utype int dwShareMode, @void lpSecurityAttributes, utype int dwFlagsAndAttributes;
stub @void OpenFileMappingFromApp -> utype int DesiredAccess, int InheritHandle, @void Name;
stub @void OpenFileMappingW -> utype int dwDesiredAccess, int bInheritHandle, @void lpName;
stub @void OpenMutexW -> utype int dwDesiredAccess, int bInheritHandle, @void lpName;
stub int OpenPackageInfoByFullName -> @void packageFullName, utype int reserved, @void packageInfoReference;
stub int OpenPackageInfoByFullNameForUser -> @void userSid, @void packageFullName, utype int reserved, @void packageInfoReference;
stub @void OpenPrivateNamespaceW -> @void lpBoundaryDescriptor, @void lpAliasPrefix;
stub @void OpenProcess -> utype int dwDesiredAccess, int bInheritHandle, utype int dwProcessId;
stub int OpenProcessToken -> @void ProcessHandle, utype int DesiredAccess, @void TokenHandle;
stub @void OpenSemaphoreW -> utype int dwDesiredAccess, int bInheritHandle, @void lpName;
stub @void OpenThread -> utype int dwDesiredAccess, int bInheritHandle, utype int dwThreadId;
stub int OpenThreadToken -> @void ThreadHandle, utype int DesiredAccess, int OpenAsSelf, @void TokenHandle;
stub @void OpenWaitableTimerW -> utype int dwDesiredAccess, int bInheritHandle, @void lpTimerName;
stub void OutputDebugStringA -> str lpOutputString;
stub void OutputDebugStringW -> @void lpOutputString;
stub int PackageFamilyNameFromFullName -> @void packageFullName, @int packageFamilyNameLength, @void packageFamilyName;
stub int PackageFamilyNameFromId -> @void packageId, @int packageFamilyNameLength, @void packageFamilyName;
stub int PackageFullNameFromId -> @void packageId, @int packageFullNameLength, @void packageFullName;
stub int PackageIdFromFullName -> @void packageFullName, utype int flags, @int bufferLength, @char buffer;
stub int PackageNameAndPublisherIdFromFamilyName -> @void packageFamilyName, @int packageNameLength, @void packageName, @int packagePublisherIdLength, @void packagePublisherId;
stub int ParseApplicationUserModelId -> @void applicationUserModelId, @int packageFamilyNameLength, @void packageFamilyName, @int packageRelativeApplicationIdLength, @void packageRelativeApplicationId;
stub int PeekConsoleInputA -> @void console_input, @void buffer, utype int length, @int number_of_events_read;
stub int PeekConsoleInputW -> @void console_input, @void buffer, utype int length, @int number_of_events_read;
stub int PeekNamedPipe -> @void hNamedPipe, @void lpBuffer, utype int nBufferSize, @int lpBytesRead, @int lpTotalBytesAvail, @int lpBytesLeftThisMessage;
stub int PostQueuedCompletionStatus -> @void CompletionPort, utype int dwNumberOfBytesTransferred, utype longlong dwCompletionKey, @void lpOverlapped;
stub int PrefetchVirtualMemory -> @void hProcess, utype longlong NumberOfEntries, @void VirtualAddresses, utype int Flags;
stub int PrivilegeCheck -> @void ClientToken, @void RequiredPrivileges, @int pfResult;
stub int PrivilegedServiceAuditAlarmW -> @void SubsystemName, @void ServiceName, @void ClientToken, @void Privileges, int AccessGranted;
stub int ProcessIdToSessionId -> utype int dwProcessId, @int pSessionId;
stub int PulseEvent -> @void hEvent;
stub int PurgeComm -> @void hFile, utype int dwFlags;
stub int QueryActCtxSettingsW -> utype int dwFlags, @void hActCtx, @void settingsNameSpace, @void settingName, @void pvBuffer, utype longlong dwBuffer, @longlong pdwWrittenOrRequired;
stub int QueryActCtxW -> utype int dwFlags, @void hActCtx, @void pvSubInstance, utype int ulInfoClass, @void pvBuffer, utype longlong cbBuffer, @longlong pcbWrittenOrRequired;
stub int QueryAuxiliaryCounterFrequency -> @longlong lpAuxiliaryCounterFrequency;
stub utype int QueryDepthSList -> @void ListHead;
stub utype int QueryDosDeviceW -> @void lpDeviceName, @void lpTargetPath, utype int ucchMax;
stub int QueryFullProcessImageNameA -> @void hProcess, utype int dwFlags, str lpExeName, @int lpdwSize;
stub int QueryFullProcessImageNameW -> @void hProcess, utype int dwFlags, @void lpExeName, @int lpdwSize;
stub int QueryIdleProcessorCycleTime -> @int BufferLength, @longlong ProcessorIdleCycleTime;
stub int QueryIdleProcessorCycleTimeEx -> utype int Group, @int BufferLength, @longlong ProcessorIdleCycleTime;
stub void QueryInterruptTime -> @longlong lpInterruptTime;
stub void QueryInterruptTimePrecise -> @longlong lpInterruptTimePrecise;
stub int QueryMemoryResourceNotification -> @void ResourceNotificationHandle, @int ResourceState;
stub int QueryOptionalDelayLoadedAPI -> @void CallerModule, str lpDllName, str lpProcName, utype int Reserved;
stub int QueryPerformanceCounter -> @longlong lpPerformanceCount;
stub int QueryPerformanceFrequency -> @longlong lpFrequency;
stub int QueryProcessAffinityUpdateMode -> @void hProcess, @int lpdwFlags;
stub int QueryProcessCycleTime -> @void ProcessHandle, @longlong CycleTime;
stub int QueryProtectedPolicy -> @void PolicyGuid, @longlong PolicyValue;
stub void QuerySecurityAccessMask -> utype int SecurityInformation, @int DesiredAccess;
stub int QueryThreadCycleTime -> @void ThreadHandle, @longlong CycleTime;
stub int QueryThreadpoolStackInformation -> @void ptpp, @void ptpsi;
stub int QueryUnbiasedInterruptTime -> @longlong UnbiasedTime;
stub void QueryUnbiasedInterruptTimePrecise -> @longlong lpUnbiasedInterruptTimePrecise;
stub utype int QueueUserAPC -> @func pfnAPC, @void hThread, utype longlong dwData;
stub int QueueUserWorkItem -> @func Function, @void Context, utype int Flags;
stub void RaiseException -> utype int dwExceptionCode, utype int dwExceptionFlags, utype int nNumberOfArguments, @longlong lpArguments;
stub void RaiseFailFastException -> @void pExceptionRecord, @void pContextRecord, utype int dwFlags;
stub @void ReOpenFile -> @void hOriginalFile, utype int dwDesiredAccess, utype int dwShareMode, utype int dwFlagsAndAttributes;
stub int ReadConsoleA -> @void console_input, @void buffer, utype int number_of_chars_to_read, @int number_of_chars_read, @void input_control;
stub int ReadConsoleInputA -> @void console_input, @void buffer, utype int length, @int number_of_events_read;
stub int ReadConsoleInputW -> @void console_input, @void buffer, utype int length, @int number_of_events_read;
stub int ReadConsoleW -> @void console_input, @void buffer, utype int number_of_chars_to_read, @int number_of_chars_read, @void input_control;
stub int ReadDirectoryChangesW -> @void hDirectory, @void lpBuffer, utype int nBufferLength, int bWatchSubtree, utype int dwNotifyFilter, @int lpBytesReturned, @void lpOverlapped, @func lpCompletionRoutine;
stub int ReadFile -> @void hFile, @void lpBuffer, utype int nNumberOfBytesToRead, @int lpNumberOfBytesRead, @void lpOverlapped;
stub int ReadFileEx -> @void hFile, @void lpBuffer, utype int nNumberOfBytesToRead, @void lpOverlapped, @func lpCompletionRoutine;
stub int ReadFileScatter -> @void hFile, @void aSegmentArray, utype int nNumberOfBytesToRead, @int lpReserved, @void lpOverlapped;
stub int ReadProcessMemory -> @void hProcess, @void lpBaseAddress, @void lpBuffer, utype longlong nSize, @longlong lpNumberOfBytesRead;
stub utype int ReclaimVirtualMemory -> @void VirtualAddress, utype longlong Size;
stub int RegCloseKey -> @void hKey;
stub int RegCopyTreeW -> @void hKeySrc, @void lpSubKey, @void hKeyDest;
stub int RegCreateKeyExA -> @void hKey, str lpSubKey, utype int Reserved, str lpClass, utype int dwOptions, utype int samDesired, @void lpSecurityAttributes, @void phkResult, @int lpdwDisposition;
stub int RegCreateKeyExW -> @void hKey, @void lpSubKey, utype int Reserved, @void lpClass, utype int dwOptions, utype int samDesired, @void lpSecurityAttributes, @void phkResult, @int lpdwDisposition;
stub int RegDeleteKeyExA -> @void hKey, str lpSubKey, utype int samDesired, utype int Reserved;
stub int RegDeleteKeyExW -> @void hKey, @void lpSubKey, utype int samDesired, utype int Reserved;
stub int RegDeleteKeyValueA -> @void hKey, str lpSubKey, str lpValueName;
stub int RegDeleteKeyValueW -> @void hKey, @void lpSubKey, @void lpValueName;
stub int RegDeleteTreeA -> @void hKey, str lpSubKey;
stub int RegDeleteTreeW -> @void hKey, @void lpSubKey;
stub int RegDeleteValueA -> @void hKey, str lpValueName;
stub int RegDeleteValueW -> @void hKey, @void lpValueName;
stub int RegDisablePredefinedCacheEx;
stub int RegEnumKeyExA -> @void hKey, utype int dwIndex, str lpName, @int lpcchName, @int lpReserved, str lpClass, @int lpcchClass, @void lpftLastWriteTime;
stub int RegEnumKeyExW -> @void hKey, utype int dwIndex, @void lpName, @int lpcchName, @int lpReserved, @void lpClass, @int lpcchClass, @void lpftLastWriteTime;
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
stub int RegOpenKeyExA -> @void hKey, str lpSubKey, utype int ulOptions, utype int samDesired, @void phkResult;
stub int RegOpenKeyExW -> @void hKey, @void lpSubKey, utype int ulOptions, utype int samDesired, @void phkResult;
stub int RegOpenUserClassesRoot -> @void hToken, utype int dwOptions, utype int samDesired, @void phkResult;
stub int RegQueryInfoKeyA -> @void hKey, str lpClass, @int lpcchClass, @int lpReserved, @int lpcSubKeys, @int lpcbMaxSubKeyLen, @int lpcbMaxClassLen, @int lpcValues, @int lpcbMaxValueNameLen, @int lpcbMaxValueLen, @int lpcbSecurityDescriptor, @void lpftLastWriteTime;
stub int RegQueryInfoKeyW -> @void hKey, @void lpClass, @int lpcchClass, @int lpReserved, @int lpcSubKeys, @int lpcbMaxSubKeyLen, @int lpcbMaxClassLen, @int lpcValues, @int lpcbMaxValueNameLen, @int lpcbMaxValueLen, @int lpcbSecurityDescriptor, @void lpftLastWriteTime;
stub int RegQueryMultipleValuesA -> @void hKey, @void val_list, utype int num_vals, str lpValueBuf, @int ldwTotsize;
stub int RegQueryMultipleValuesW -> @void hKey, @void val_list, utype int num_vals, @void lpValueBuf, @int ldwTotsize;
stub int RegQueryValueExA -> @void hKey, str lpValueName, @int lpReserved, @int lpType, @char lpData, @int lpcbData;
stub int RegQueryValueExW -> @void hKey, @void lpValueName, @int lpReserved, @int lpType, @char lpData, @int lpcbData;
stub int RegRestoreKeyA -> @void hKey, str lpFile, utype int dwFlags;
stub int RegRestoreKeyW -> @void hKey, @void lpFile, utype int dwFlags;
stub int RegSaveKeyExA -> @void hKey, str lpFile, @void lpSecurityAttributes, utype int Flags;
stub int RegSaveKeyExW -> @void hKey, @void lpFile, @void lpSecurityAttributes, utype int Flags;
stub int RegSetKeySecurity -> @void hKey, utype int SecurityInformation, @void pSecurityDescriptor;
stub int RegSetKeyValueA -> @void hKey, str lpSubKey, str lpValueName, utype int dwType, @void lpData, utype int cbData;
stub int RegSetKeyValueW -> @void hKey, @void lpSubKey, @void lpValueName, utype int dwType, @void lpData, utype int cbData;
stub int RegSetValueExA -> @void hKey, str lpValueName, utype int Reserved, utype int dwType, @char lpData, utype int cbData;
stub int RegSetValueExW -> @void hKey, @void lpValueName, utype int Reserved, utype int dwType, @char lpData, utype int cbData;
stub int RegUnLoadKeyA -> @void hKey, str lpSubKey;
stub int RegUnLoadKeyW -> @void hKey, @void lpSubKey;
stub int RegisterApplicationRestart -> @void pwzCommandline, utype int dwFlags;
stub @void RegisterBadMemoryNotification -> @func Callback;
stub void ReleaseActCtx -> @void hActCtx;
stub int ReleaseMutex -> @void hMutex;
stub void ReleaseMutexWhenCallbackReturns -> @void pci, @void mut;
stub void ReleaseSRWLockExclusive -> @void SRWLock;
stub void ReleaseSRWLockShared -> @void SRWLock;
stub int ReleaseSemaphore -> @void hSemaphore, int lReleaseCount, @int lpPreviousCount;
stub void ReleaseSemaphoreWhenCallbackReturns -> @void pci, @void sem, utype int crel;
stub int RemoveDirectoryA -> str lpPathName;
stub int RemoveDirectoryW -> @void lpPathName;
stub int RemoveDllDirectory -> @void Cookie;
stub utype int RemoveVectoredContinueHandler -> @void Handle;
stub utype int RemoveVectoredExceptionHandler -> @void Handle;
stub int ReplaceFileW -> @void lpReplacedFileName, @void lpReplacementFileName, @void lpBackupFileName, utype int dwReplaceFlags, @void lpExclude, @void lpReserved;
stub int ResetEvent -> @void hEvent;
stub utype int ResetWriteWatch -> @void lpBaseAddress, utype longlong dwRegionSize;
stub int ResolveLocaleName -> @void lpNameToResolve, @void lpLocaleName, int cchLocaleName;
stub utype int ResumeThread -> @void hThread;
stub int RevertToSelf;
stub utype int SearchPathA -> str lpPath, str lpFileName, str lpExtension, utype int nBufferLength, str lpBuffer, @void lpFilePart;
stub utype int SearchPathW -> @void lpPath, @void lpFileName, @void lpExtension, utype int nBufferLength, @void lpBuffer, @void lpFilePart;
stub int SetCachedSigningLevel -> @void SourceFiles, utype int SourceFileCount, utype int Flags, @void TargetFile;
stub int SetCalendarInfoW -> utype int Locale, utype int Calendar, utype int CalType, @void lpCalData;
stub int SetCommBreak -> @void hFile;
stub int SetCommConfig -> @void hCommDev, @void lpCC, utype int dwSize;
stub int SetCommMask -> @void hFile, utype int dwEvtMask;
stub int SetCommState -> @void hFile, @void lpDCB;
stub int SetCommTimeouts -> @void hFile, @void lpCommTimeouts;
stub int SetComputerNameA -> str lpComputerName;
stub int SetComputerNameW -> @void lpComputerName;
stub int SetConsoleActiveScreenBuffer -> @void console_output;
stub int SetConsoleCP -> utype int code_page_id;
stub int SetConsoleCtrlHandler -> @func handler_routine, int add;
stub int SetConsoleCursorInfo -> @void console_output, @void console_cursor_info;
stub int SetConsoleDisplayMode -> @void console_output, utype int flags, @void new_screen_buffer_dimensions;
stub int SetConsoleHistoryInfo -> @void console_history_info;
stub int SetConsoleMode -> @void console_handle, utype int mode;
stub int SetConsoleNumberOfCommandsA -> utype int number, str exe_name;
stub int SetConsoleNumberOfCommandsW -> utype int number, @void exe_name;
stub int SetConsoleOutputCP -> utype int code_page_id;
stub int SetConsoleScreenBufferInfoEx -> @void console_output, @void console_screen_buffer_info_ex;
stub int SetConsoleTextAttribute -> @void console_output, utype int attributes;
stub int SetConsoleTitleA -> str console_title;
stub int SetConsoleTitleW -> @void console_title;
stub int SetConsoleWindowInfo -> @void console_output, int absolute, @void console_window;
stub utype int SetCriticalSectionSpinCount -> @void lpCriticalSection, utype int dwSpinCount;
stub int SetCurrentConsoleFontEx -> @void console_output, int maximum_window, @void console_current_font_ex;
stub int SetCurrentDirectoryA -> str lpPathName;
stub int SetCurrentDirectoryW -> @void lpPathName;
stub int SetDefaultDllDirectories -> utype int DirectoryFlags;
stub int SetDynamicTimeZoneInformation -> @void lpTimeZoneInformation;
stub int SetEndOfFile -> @void hFile;
stub int SetEnvironmentStringsW -> @void NewEnvironment;
stub int SetEnvironmentVariableA -> str lpName, str lpValue;
stub int SetEnvironmentVariableW -> @void lpName, @void lpValue;
stub utype int SetErrorMode -> utype int uMode;
stub int SetEvent -> @void hEvent;
stub void SetEventWhenCallbackReturns -> @void pci, @void evt;
stub void SetFileApisToANSI;
stub void SetFileApisToOEM;
stub int SetFileAttributesA -> str lpFileName, utype int dwFileAttributes;
stub int SetFileAttributesW -> @void lpFileName, utype int dwFileAttributes;
stub int SetFileIoOverlappedRange -> @void FileHandle, @char OverlappedRangeStart, utype int Length;
stub utype int SetFilePointer -> @void hFile, int lDistanceToMove, @int lpDistanceToMoveHigh, utype int dwMoveMethod;
stub int SetFilePointerEx -> @void hFile, longlong liDistanceToMove, @longlong lpNewFilePointer, utype int dwMoveMethod;
stub int SetFileSecurityW -> @void lpFileName, utype int SecurityInformation, @void pSecurityDescriptor;
stub int SetFileTime -> @void hFile, @void lpCreationTime, @void lpLastAccessTime, @void lpLastWriteTime;
stub int SetFileValidData -> @void hFile, longlong ValidDataLength;
stub utype int SetHandleCount -> utype int uNumber;
stub int SetHandleInformation -> @void hObject, utype int dwMask, utype int dwFlags;
stub int SetKernelObjectSecurity -> @void Handle, utype int SecurityInformation, @void SecurityDescriptor;
stub void SetLastError -> utype int dwErrCode;
stub int SetLocalTime -> @void lpSystemTime;
stub int SetLocaleInfoW -> utype int Locale, utype int LCType, @void lpLCData;
stub int SetNamedPipeHandleState -> @void hNamedPipe, @int lpMode, @int lpMaxCollectionCount, @int lpCollectDataTimeout;
stub int SetPriorityClass -> @void hProcess, utype int dwPriorityClass;
stub int SetPrivateObjectSecurity -> utype int SecurityInformation, @void ModificationDescriptor, @void ObjectsSecurityDescriptor, @void GenericMapping, @void Token;
stub int SetPrivateObjectSecurityEx -> utype int SecurityInformation, @void ModificationDescriptor, @void ObjectsSecurityDescriptor, utype int AutoInheritFlags, @void GenericMapping, @void Token;
stub int SetProcessAffinityUpdateMode -> @void hProcess, utype int dwFlags;
stub int SetProcessDefaultCpuSetMasks -> @void Process, @void CpuSetMasks, utype int CpuSetMaskCount;
stub int SetProcessDefaultCpuSets -> @void Process, @int CpuSetIds, utype int CpuSetIdCount;
stub int SetProcessGroupAffinity -> @void hProcess, @void GroupAffinity, @void PreviousGroupAffinity;
stub int SetProcessPreferredUILanguages -> utype int dwFlags, @void pwszLanguagesBuffer, @int pulNumLanguages;
stub int SetProcessPriorityBoost -> @void hProcess, int bDisablePriorityBoost;
stub int SetProcessShutdownParameters -> utype int dwLevel, utype int dwFlags;
stub int SetProcessValidCallTargets -> @void hProcess, @void VirtualAddress, utype longlong RegionSize, utype int NumberOfOffsets, @void OffsetInformation;
stub int SetProcessValidCallTargetsForMappedView -> @void Process, @void VirtualAddress, utype longlong RegionSize, utype int NumberOfOffsets, @void OffsetInformation, @void Section, utype longlong ExpectedFileOffset;
stub int SetProcessWorkingSetSize -> @void hProcess, utype longlong dwMinimumWorkingSetSize, utype longlong dwMaximumWorkingSetSize;
stub int SetProcessWorkingSetSizeEx -> @void hProcess, utype longlong dwMinimumWorkingSetSize, utype longlong dwMaximumWorkingSetSize, utype int Flags;
stub int SetProtectedPolicy -> @void PolicyGuid, utype longlong PolicyValue, @longlong OldPolicyValue;
stub void SetSecurityAccessMask -> utype int SecurityInformation, @int DesiredAccess;
stub int SetSecurityDescriptorControl -> @void pSecurityDescriptor, utype int ControlBitsOfInterest, utype int ControlBitsToSet;
stub int SetSecurityDescriptorDacl -> @void pSecurityDescriptor, int bDaclPresent, @void pDacl, int bDaclDefaulted;
stub int SetSecurityDescriptorGroup -> @void pSecurityDescriptor, @void pGroup, int bGroupDefaulted;
stub int SetSecurityDescriptorOwner -> @void pSecurityDescriptor, @void pOwner, int bOwnerDefaulted;
stub utype int SetSecurityDescriptorRMControl -> @void SecurityDescriptor, @char RMControl;
stub int SetSecurityDescriptorSacl -> @void pSecurityDescriptor, int bSaclPresent, @void pSacl, int bSaclDefaulted;
stub int SetStdHandle -> utype int nStdHandle, @void hHandle;
stub int SetStdHandleEx -> utype int nStdHandle, @void hHandle, @void phPrevValue;
stub int SetSystemFileCacheSize -> utype longlong MinimumFileCacheSize, utype longlong MaximumFileCacheSize, utype int Flags;
stub int SetSystemTime -> @void lpSystemTime;
stub int SetSystemTimeAdjustment -> utype int dwTimeAdjustment, int bTimeAdjustmentDisabled;
stub int SetThreadContext -> @void hThread, @void lpContext;
stub int SetThreadDescription -> @void hThread, @void lpThreadDescription;
stub int SetThreadErrorMode -> utype int dwNewMode, @int lpOldMode;
stub int SetThreadGroupAffinity -> @void hThread, @void GroupAffinity, @void PreviousGroupAffinity;
stub utype int SetThreadIdealProcessor -> @void hThread, utype int dwIdealProcessor;
stub int SetThreadIdealProcessorEx -> @void hThread, @void lpIdealProcessor, @void lpPreviousIdealProcessor;
stub int SetThreadLocale -> utype int Locale;
stub int SetThreadPreferredUILanguages -> utype int dwFlags, @void pwszLanguagesBuffer, @int pulNumLanguages;
stub int SetThreadPriority -> @void hThread, int nPriority;
stub int SetThreadPriorityBoost -> @void hThread, int bDisablePriorityBoost;
stub int SetThreadSelectedCpuSetMasks -> @void Thread, @void CpuSetMasks, utype int CpuSetMaskCount;
stub int SetThreadSelectedCpuSets -> @void Thread, @int CpuSetIds, utype int CpuSetIdCount;
stub int SetThreadStackGuarantee -> @int StackSizeInBytes;
stub int SetThreadToken -> @void Thread, @void Token;
stub utype int SetThreadUILanguage -> utype int LangId;
stub int SetThreadpoolStackInformation -> @void ptpp, @void ptpsi;
stub void SetThreadpoolThreadMaximum -> @void ptpp, utype int cthrdMost;
stub int SetThreadpoolThreadMinimum -> @void ptpp, utype int cthrdMic;
stub void SetThreadpoolTimer -> @void pti, @void pftDueTime, utype int msPeriod, utype int msWindowLength;
stub int SetThreadpoolTimerEx -> @void pti, @void pftDueTime, utype int msPeriod, utype int msWindowLength;
stub void SetThreadpoolWait -> @void pwa, @void h, @void pftTimeout;
stub int SetThreadpoolWaitEx -> @void pwa, @void h, @void pftTimeout, @void Reserved;
stub int SetTimeZoneInformation -> @void lpTimeZoneInformation;
stub @void SetUnhandledExceptionFilter -> @func lpTopLevelExceptionFilter;
stub int SetUserGeoID -> int GeoId;
stub int SetUserGeoName -> @void geoName;
stub int SetWaitableTimer -> @void hTimer, @void lpDueTime, int lPeriod, @func pfnCompletionRoutine, @void lpArgToCompletionRoutine, int fResume;
stub int SetWaitableTimerEx -> @void hTimer, @void lpDueTime, int lPeriod, @func pfnCompletionRoutine, @void lpArgToCompletionRoutine, @void WakeContext, utype int TolerableDelay;
stub int SetXStateFeaturesMask -> @void Context, utype longlong FeatureMask;
stub int SetupComm -> @void hFile, utype int dwInQueue, utype int dwOutQueue;
stub utype int SignalObjectAndWait -> @void hObjectToSignal, @void hObjectToWaitOn, utype int dwMilliseconds, int bAlertable;
stub utype int SizeofResource -> @void hModule, @void hResInfo;
stub void Sleep -> utype int dwMilliseconds;
stub int SleepConditionVariableCS -> @void ConditionVariable, @void CriticalSection, utype int dwMilliseconds;
stub int SleepConditionVariableSRW -> @void ConditionVariable, @void SRWLock, utype int dwMilliseconds, utype int Flags;
stub utype int SleepEx -> utype int dwMilliseconds, int bAlertable;
stub void StartThreadpoolIo -> @void pio;
stub void SubmitThreadpoolWork -> @void pwk;
stub utype int SuspendThread -> @void hThread;
stub void SwitchToFiber -> @void lpFiber;
stub int SwitchToThread;
stub int SystemTimeToFileTime -> @void lpSystemTime, @void lpFileTime;
stub int SystemTimeToTzSpecificLocalTime -> @void lpTimeZoneInformation, @void lpUniversalTime, @void lpLocalTime;
stub int SystemTimeToTzSpecificLocalTimeEx -> @void lpTimeZoneInformation, @void lpUniversalTime, @void lpLocalTime;
stub int TerminateProcess -> @void hProcess, utype int uExitCode;
stub int TerminateThread -> @void hThread, utype int dwExitCode;
stub utype int TlsAlloc;
stub int TlsFree -> utype int dwTlsIndex;
stub @void TlsGetValue -> utype int dwTlsIndex;
stub @void TlsGetValue2 -> utype int dwTlsIndex;
stub int TlsSetValue -> utype int dwTlsIndex, @void lpTlsValue;
stub int TransactNamedPipe -> @void hNamedPipe, @void lpInBuffer, utype int nInBufferSize, @void lpOutBuffer, utype int nOutBufferSize, @int lpBytesRead, @void lpOverlapped;
stub int TransmitCommChar -> @void hFile, char cChar;
stub utype char TryAcquireSRWLockExclusive -> @void SRWLock;
stub utype char TryAcquireSRWLockShared -> @void SRWLock;
stub int TryEnterCriticalSection -> @void lpCriticalSection;
stub int TrySubmitThreadpoolCallback -> @func pfns, @void pv, @void pcbe;
stub int TzSpecificLocalTimeToSystemTime -> @void lpTimeZoneInformation, @void lpLocalTime, @void lpUniversalTime;
stub int TzSpecificLocalTimeToSystemTimeEx -> @void lpTimeZoneInformation, @void lpLocalTime, @void lpUniversalTime;
stub int UnhandledExceptionFilter -> @void ExceptionInfo;
stub int UnlockFile -> @void hFile, utype int dwFileOffsetLow, utype int dwFileOffsetHigh, utype int nNumberOfBytesToUnlockLow, utype int nNumberOfBytesToUnlockHigh;
stub int UnlockFileEx -> @void hFile, utype int dwReserved, utype int nNumberOfBytesToUnlockLow, utype int nNumberOfBytesToUnlockHigh, @void lpOverlapped;
stub int UnmapViewOfFile -> @void lpBaseAddress;
stub int UnmapViewOfFile2 -> @void Process, @void BaseAddress, utype int UnmapFlags;
stub int UnmapViewOfFileEx -> @void BaseAddress, utype int UnmapFlags;
stub int UnregisterApplicationRestart;
stub int UnregisterBadMemoryNotification -> @void RegistrationHandle;
stub int UnregisterWaitEx -> @void WaitHandle, @void CompletionEvent;
stub int UpdateProcThreadAttribute -> @void lpAttributeList, utype int dwFlags, utype longlong Attribute, @void lpValue, utype longlong cbSize, @void lpPreviousValue, @longlong lpReturnSize;
stub utype int VerFindFileA -> utype int uFlags, str szFileName, str szWinDir, str szAppDir, str szCurDir, @int lpuCurDirLen, str szDestDir, @int lpuDestDirLen;
stub utype int VerFindFileW -> utype int uFlags, @void szFileName, @void szWinDir, @void szAppDir, @void szCurDir, @int lpuCurDirLen, @void szDestDir, @int lpuDestDirLen;
stub utype int VerLanguageNameA -> utype int wLang, str szLang, utype int nSize;
stub utype int VerLanguageNameW -> utype int wLang, @void szLang, utype int nSize;
stub int VerQueryValueA -> @void pBlock, str lpSubBlock, @void lplpBuffer, @int puLen;
stub int VerQueryValueW -> @void pBlock, @void lpSubBlock, @void lplpBuffer, @int puLen;
stub utype longlong VerSetConditionMask -> utype longlong ConditionMask, utype int TypeMask, utype char Condition;
stub int VerifyApplicationUserModelId -> @void applicationUserModelId;
stub int VerifyPackageFamilyName -> @void packageFamilyName;
stub int VerifyPackageFullName -> @void packageFullName;
stub int VerifyPackageId -> @void packageId;
stub int VerifyPackageRelativeApplicationId -> @void packageRelativeApplicationId;
stub int VerifyScripts -> utype int dwFlags, @void lpLocaleScripts, int cchLocaleScripts, @void lpTestScripts, int cchTestScripts;
stub @void VirtualAlloc -> @void lpAddress, utype longlong dwSize, utype int flAllocationType, utype int flProtect;
stub @void VirtualAlloc2 -> @void Process, @void BaseAddress, utype longlong Size, utype int AllocationType, utype int PageProtection, @void ExtendedParameters, utype int ParameterCount;
stub @void VirtualAlloc2FromApp -> @void Process, @void BaseAddress, utype longlong Size, utype int AllocationType, utype int PageProtection, @void ExtendedParameters, utype int ParameterCount;
stub @void VirtualAllocEx -> @void hProcess, @void lpAddress, utype longlong dwSize, utype int flAllocationType, utype int flProtect;
stub @void VirtualAllocExNuma -> @void hProcess, @void lpAddress, utype longlong dwSize, utype int flAllocationType, utype int flProtect, utype int nndPreferred;
stub @void VirtualAllocFromApp -> @void BaseAddress, utype longlong Size, utype int AllocationType, utype int Protection;
stub int VirtualFree -> @void lpAddress, utype longlong dwSize, utype int dwFreeType;
stub int VirtualFreeEx -> @void hProcess, @void lpAddress, utype longlong dwSize, utype int dwFreeType;
stub int VirtualLock -> @void lpAddress, utype longlong dwSize;
stub int VirtualProtect -> @void lpAddress, utype longlong dwSize, utype int flNewProtect, @int lpflOldProtect;
stub int VirtualProtectEx -> @void hProcess, @void lpAddress, utype longlong dwSize, utype int flNewProtect, @int lpflOldProtect;
stub int VirtualProtectFromApp -> @void lpAddress, utype longlong dwSize, utype int flNewProtect, @int lpflOldProtect;
stub utype longlong VirtualQuery -> @void lpAddress, @void lpBuffer, utype longlong dwLength;
stub utype longlong VirtualQueryEx -> @void hProcess, @void lpAddress, @void lpBuffer, utype longlong dwLength;
stub int VirtualUnlock -> @void lpAddress, utype longlong dwSize;
stub int VirtualUnlockEx -> @void Process, @void Address, utype longlong Size;
stub utype int WTSGetServiceSessionId;
stub utype char WTSIsServerContainer;
stub int WaitCommEvent -> @void hFile, @int lpEvtMask, @void lpOverlapped;
stub int WaitForDebugEvent -> @void lpDebugEvent, utype int dwMilliseconds;
stub int WaitForDebugEventEx -> @void lpDebugEvent, utype int dwMilliseconds;
stub utype int WaitForMultipleObjects -> utype int nCount, @void lpHandles, int bWaitAll, utype int dwMilliseconds;
stub utype int WaitForMultipleObjectsEx -> utype int nCount, @void lpHandles, int bWaitAll, utype int dwMilliseconds, int bAlertable;
stub utype int WaitForSingleObject -> @void hHandle, utype int dwMilliseconds;
stub utype int WaitForSingleObjectEx -> @void hHandle, utype int dwMilliseconds, int bAlertable;
stub void WaitForThreadpoolIoCallbacks -> @void pio, int fCancelPendingCallbacks;
stub void WaitForThreadpoolTimerCallbacks -> @void pti, int fCancelPendingCallbacks;
stub void WaitForThreadpoolWaitCallbacks -> @void pwa, int fCancelPendingCallbacks;
stub void WaitForThreadpoolWorkCallbacks -> @void pwk, int fCancelPendingCallbacks;
stub int WaitNamedPipeW -> @void lpNamedPipeName, utype int nTimeOut;
stub int WaitOnAddress -> @void Address, @void CompareAddress, utype longlong AddressSize, utype int dwMilliseconds;
stub void WakeAllConditionVariable -> @void ConditionVariable;
stub void WakeByAddressAll -> @void Address;
stub void WakeByAddressSingle -> @void Address;
stub void WakeConditionVariable -> @void ConditionVariable;
stub int WideCharToMultiByte -> utype int CodePage, utype int dwFlags, @void lpWideCharStr, int cchWideChar, str lpMultiByteStr, int cbMultiByte, str lpDefaultChar, @int lpUsedDefaultChar;
stub int Wow64DisableWow64FsRedirection -> @void OldValue;
stub utype char Wow64EnableWow64FsRedirection -> utype char Wow64FsEnableRedirection;
stub int Wow64GetThreadContext -> @void hThread, @void lpContext;
stub int Wow64RevertWow64FsRedirection -> @void OlValue;
stub int Wow64SetThreadContext -> @void hThread, @void lpContext;
stub utype int Wow64SetThreadDefaultGuestMachine -> utype int Machine;
stub utype int Wow64SuspendThread -> @void hThread;
stub int WriteConsoleA -> @void console_output, @void buffer, utype int number_of_chars_to_write, @int number_of_chars_written, @void reserved;
stub int WriteConsoleInputA -> @void console_input, @void buffer, utype int length, @int number_of_events_written;
stub int WriteConsoleInputW -> @void console_input, @void buffer, utype int length, @int number_of_events_written;
stub int WriteConsoleW -> @void console_output, @void buffer, utype int number_of_chars_to_write, @int number_of_chars_written, @void reserved;
stub int WriteFile -> @void hFile, @void lpBuffer, utype int nNumberOfBytesToWrite, @int lpNumberOfBytesWritten, @void lpOverlapped;
stub int WriteFileEx -> @void hFile, @void lpBuffer, utype int nNumberOfBytesToWrite, @void lpOverlapped, @func lpCompletionRoutine;
stub int WriteFileGather -> @void hFile, @void aSegmentArray, utype int nNumberOfBytesToWrite, @int lpReserved, @void lpOverlapped;
stub int WriteProcessMemory -> @void hProcess, @void lpBaseAddress, @void lpBuffer, utype longlong nSize, @longlong lpNumberOfBytesWritten;
stub int ZombifyActCtx -> @void hActCtx;
stub void _exit -> int _Code;
stub @void _onexit -> @func _Func;
stub int atexit -> @func a1;
stub void exit -> int _Code;
stub int lstrcmpA -> str lpString1, str lpString2;
stub int lstrcmpW -> @void String1, @void String2;
stub int lstrcmpiA -> str lpString1, str lpString2;
stub int lstrcmpiW -> @void String1, @void String2;
stub str lstrcpynA -> str lpString1, str lpString2, int iMaxLength;
stub @void lstrcpynW -> @void lpString1, @void lpString2, int iMaxLength;
stub int lstrlenA -> str lpString;
stub int lstrlenW -> @void String;

!!! Declared by the headers, but with a type the language cannot write:
!!!   AccessCheckByTypeAndAuditAlarmW
!!!   AccessCheckByTypeResultListAndAuditAlarmByHandleW
!!!   AccessCheckByTypeResultListAndAuditAlarmW
!!!   ClosePackageInfo
!!!   CreateMemoryResourceNotification
!!!   CreatePseudoConsole
!!!   CreateWellKnownSid
!!!   DuplicateToken
!!!   DuplicateTokenEx
!!!   FillConsoleOutputAttribute
!!!   FillConsoleOutputCharacterA
!!!   FillConsoleOutputCharacterW
!!!   FindFirstFileExA
!!!   FindFirstFileExW
!!!   FindFirstStreamW
!!!   GetAclInformation
!!!   GetComputerNameExA
!!!   GetComputerNameExW
!!!   GetConsoleFontSize
!!!   GetFileAttributesExA
!!!   GetFileAttributesExW
!!!   GetFileInformationByHandleEx
!!!   GetLargestConsoleWindowSize
!!!   GetLogicalProcessorInformationEx
!!!   GetPackageApplicationIds
!!!   GetPackageInfo
!!!   GetProcessInformation
!!!   GetProcessMitigationPolicy
!!!   GetThreadInformation
!!!   GetTokenInformation
!!!   HeapQueryInformation
!!!   HeapSetInformation
!!!   ImpersonateSelf
!!!   IsCharAlphaNumericW
!!!   IsCharAlphaW
!!!   IsCharLowerW
!!!   IsCharUpperW
!!!   IsNormalizedString
!!!   IsWellKnownSid
!!!   NormalizeString
!!!   OfferVirtualMemory
!!!   QueryVirtualMemoryInformation
!!!   ReadConsoleOutputA
!!!   ReadConsoleOutputAttribute
!!!   ReadConsoleOutputCharacterA
!!!   ReadConsoleOutputCharacterW
!!!   ReadConsoleOutputW
!!!   ReadDirectoryChangesExW
!!!   ResizePseudoConsole
!!!   ScrollConsoleScreenBufferA
!!!   ScrollConsoleScreenBufferW
!!!   SetAclInformation
!!!   SetComputerNameExA
!!!   SetComputerNameExW
!!!   SetConsoleCursorPosition
!!!   SetConsoleScreenBufferSize
!!!   SetFileInformationByHandle
!!!   SetProcessInformation
!!!   SetProcessMitigationPolicy
!!!   SetThreadInformation
!!!   SetTokenInformation
!!!   WriteConsoleOutputA
!!!   WriteConsoleOutputAttribute
!!!   WriteConsoleOutputCharacterA
!!!   WriteConsoleOutputCharacterW
!!!   WriteConsoleOutputW
!!!   __C_specific_handler

!!! No prototype in the headers this build saw. They are here so the
!!! list is complete; uncomment and give the real signature to use one.
!!! AccessCheckByTypeAndAuditAlarmW
!!! AccessCheckByTypeResultListAndAuditAlarmByHandleW
!!! AccessCheckByTypeResultListAndAuditAlarmW
!!! ClosePackageInfo
!!! CreateMemoryResourceNotification
!!! CreatePseudoConsole
!!! CreateWellKnownSid
!!! DuplicateToken
!!! DuplicateTokenEx
!!! FillConsoleOutputAttribute
!!! FillConsoleOutputCharacterA
!!! FillConsoleOutputCharacterW
!!! FindFirstFileExA
!!! FindFirstFileExW
!!! FindFirstStreamW
!!! GetAclInformation
!!! GetComputerNameExA
!!! GetComputerNameExW
!!! GetConsoleFontSize
!!! GetFileAttributesExA
!!! GetFileAttributesExW
!!! GetFileInformationByHandleEx
!!! GetLargestConsoleWindowSize
!!! GetLogicalProcessorInformationEx
!!! GetPackageApplicationIds
!!! GetPackageInfo
!!! GetProcessInformation
!!! GetProcessMitigationPolicy
!!! GetThreadInformation
!!! GetTokenInformation
!!! HeapQueryInformation
!!! HeapSetInformation
!!! ImpersonateSelf
!!! IsCharAlphaNumericW
!!! IsCharAlphaW
!!! IsCharLowerW
!!! IsCharUpperW
!!! IsNormalizedString
!!! IsWellKnownSid
!!! NormalizeString
!!! OfferVirtualMemory
!!! QueryVirtualMemoryInformation
!!! ReadConsoleOutputA
!!! ReadConsoleOutputAttribute
!!! ReadConsoleOutputCharacterA
!!! ReadConsoleOutputCharacterW
!!! ReadConsoleOutputW
!!! ReadDirectoryChangesExW
!!! ResizePseudoConsole
!!! ScrollConsoleScreenBufferA
!!! ScrollConsoleScreenBufferW
!!! SetAclInformation
!!! SetComputerNameExA
!!! SetComputerNameExW
!!! SetConsoleCursorPosition
!!! SetConsoleScreenBufferSize
!!! SetFileInformationByHandle
!!! SetProcessInformation
!!! SetProcessMitigationPolicy
!!! SetThreadInformation
!!! SetTokenInformation
!!! WriteConsoleOutputA
!!! WriteConsoleOutputAttribute
!!! WriteConsoleOutputCharacterA
!!! WriteConsoleOutputCharacterW
!!! WriteConsoleOutputW
!!! __C_specific_handler
