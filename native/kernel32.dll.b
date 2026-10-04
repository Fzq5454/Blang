!~
~  native/kernel32.dll.b: the kernel32 functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/<dll>.bmeta, and that file
~  is generated from this one with `blang.exe native/kernel32.dll.b -m`: -m reads
~  the signatures out of the .r and writes meta/kernel32.dll.bmeta. The name has
~  to end in `.b` after the DLL name because -m strips only the last extension,
~  so `kernel32.dll.b` is what produces `meta/kernel32.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m stops after the
~  front end and writes meta/kernel32.dll.bmeta from the signatures, and in that
~  mode a stub writes its signature into the .r even though it has no body, so
~  this file declares what the DLL exports while carrying no code of its own.
~  Compiling it as ordinary source reports an undefined reference instead of
~  quietly handing out functions that return 0.
~
~  The declarations below are generated: the names are kernel32.dll's own
~  exports, the signatures are what the Windows headers declare, and the
~  parameter names are the headers' too (gen_sysdlls, gen_paramnames,
~  and gen_dll produce all of it).
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per kernel32.dll export that the headers declare. The
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
!!! 1222 declarations here, 0 kept from the hand-checked list above, 65 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub void AcquireSRWLockExclusive -> @void SRWLock;
stub void AcquireSRWLockShared -> @void SRWLock;
stub int ActivateActCtx -> @void hActCtx, @longlong lpCookie;
stub utype int AddAtomA -> str lpString;
stub utype int AddAtomW -> @void lpString;
stub int AddConsoleAliasA -> str source, str target, str exe_name;
stub int AddConsoleAliasW -> @void source, @void target, @void exe_name;
stub @void AddDllDirectory -> @void NewDirectory;
stub int AddIntegrityLabelToBoundaryDescriptor -> @void BoundaryDescriptor, @void IntegrityLabel;
stub void AddRefActCtx -> @void hActCtx;
stub int AddResourceAttributeAce -> @void pAcl, utype int dwAceRevision, utype int AceFlags, utype int AccessMask, @void pSid, @void pAttributeInfo, @int pReturnLength;
stub int AddSIDToBoundaryDescriptor -> @void BoundaryDescriptor, @void RequiredSid;
stub int AddScopedPolicyIDAce -> @void pAcl, utype int dwAceRevision, utype int AceFlags, utype int AccessMask, @void pSid;
stub int AddSecureMemoryCacheCallback -> @func pfnCallBack;
stub @void AddVectoredContinueHandler -> utype int First, @func Handler;
stub @void AddVectoredExceptionHandler -> utype int First, @func Handler;
stub int AllocConsole;
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
stub void ApplicationRecoveryFinished -> int bSuccess;
stub int ApplicationRecoveryInProgress -> @int pbCancelled;
stub int AreFileApisANSI;
stub int AssignProcessToJobObject -> @void hJob, @void hProcess;
stub int AttachConsole -> utype int process_id;
stub int BackupRead -> @void hFile, @char lpBuffer, utype int nNumberOfBytesToRead, @int lpNumberOfBytesRead, int bAbort, int bProcessSecurity, @void lpContext;
stub int BackupSeek -> @void hFile, utype int dwLowBytesToSeek, utype int dwHighBytesToSeek, @int lpdwLowByteSeeked, @int lpdwHighByteSeeked, @void lpContext;
stub int BackupWrite -> @void hFile, @char lpBuffer, utype int nNumberOfBytesToWrite, @int lpNumberOfBytesWritten, int bAbort, int bProcessSecurity, @void lpContext;
stub int Beep -> utype int dwFreq, utype int dwDuration;
stub @void BeginUpdateResourceA -> str pFileName, int bDeleteExistingResources;
stub @void BeginUpdateResourceW -> @void pFileName, int bDeleteExistingResources;
stub int BindIoCompletionCallback -> @void FileHandle, @func Function, utype int Flags;
stub int BuildCommDCBA -> str lpDef, @void lpDCB;
stub int BuildCommDCBAndTimeoutsA -> str lpDef, @void lpDCB, @void lpCommTimeouts;
stub int BuildCommDCBAndTimeoutsW -> @void lpDef, @void lpDCB, @void lpCommTimeouts;
stub int BuildCommDCBW -> @void lpDef, @void lpDCB;
stub int CallNamedPipeA -> str lpNamedPipeName, @void lpInBuffer, utype int nInBufferSize, @void lpOutBuffer, utype int nOutBufferSize, @int lpBytesRead, utype int nTimeOut;
stub int CallNamedPipeW -> @void lpNamedPipeName, @void lpInBuffer, utype int nInBufferSize, @void lpOutBuffer, utype int nOutBufferSize, @int lpBytesRead, utype int nTimeOut;
stub int CallbackMayRunLong -> @void pci;
stub int CancelDeviceWakeupRequest -> @void hDevice;
stub int CancelIo -> @void hFile;
stub int CancelIoEx -> @void hFile, @void lpOverlapped;
stub int CancelSynchronousIo -> @void hThread;
stub void CancelThreadpoolIo -> @void pio;
stub int CancelTimerQueueTimer -> @void TimerQueue, @void Timer;
stub int CancelWaitableTimer -> @void hTimer;
stub int ChangeTimerQueueTimer -> @void TimerQueue, @void Timer, utype int DueTime, utype int Period;
stub int CheckNameLegalDOS8Dot3A -> str lpName, str lpOemName, utype int OemNameSize, @int pbNameContainsSpaces, @int pbNameLegal;
stub int CheckNameLegalDOS8Dot3W -> @void lpName, str lpOemName, utype int OemNameSize, @int pbNameContainsSpaces, @int pbNameLegal;
stub int CheckRemoteDebuggerPresent -> @void hProcess, @int pbDebuggerPresent;
stub int CheckTokenCapability -> @void TokenHandle, @void CapabilitySidToCheck, @int HasCapability;
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
stub int CommConfigDialogA -> str lpszName, @void hWnd, @void lpCC;
stub int CommConfigDialogW -> @void lpszName, @void hWnd, @void lpCC;
stub int CompareFileTime -> @void lpFileTime1, @void lpFileTime2;
stub int CompareStringA -> utype int Locale, utype int dwCmpFlags, str lpString1, int cchCount1, str lpString2, int cchCount2;
stub int CompareStringEx -> @void lpLocaleName, utype int dwCmpFlags, @void lpString1, int cchCount1, @void lpString2, int cchCount2, @void lpVersionInformation, @void lpReserved, longlong lParam;
stub int CompareStringOrdinal -> @void lpString1, int cchCount1, @void lpString2, int cchCount2, int bIgnoreCase;
stub int CompareStringW -> utype int Locale, utype int dwCmpFlags, @void lpString1, int cchCount1, @void lpString2, int cchCount2;
stub int ConnectNamedPipe -> @void hNamedPipe, @void lpOverlapped;
stub int ContinueDebugEvent -> utype int dwProcessId, utype int dwThreadId, utype int dwContinueStatus;
stub utype int ConvertDefaultLocale -> utype int Locale;
stub int ConvertFiberToThread;
stub @void ConvertThreadToFiber -> @void lpParameter;
stub @void ConvertThreadToFiberEx -> @void lpParameter, utype int dwFlags;
stub int CopyContext -> @void Destination, utype int ContextFlags, @void Source;
stub int CopyFile2 -> @void pwszExistingFileName, @void pwszNewFileName, @void pExtendedParameters;
stub int CopyFileA -> str lpExistingFileName, str lpNewFileName, int bFailIfExists;
stub int CopyFileExA -> str lpExistingFileName, str lpNewFileName, @func lpProgressRoutine, @void lpData, @int pbCancel, utype int dwCopyFlags;
stub int CopyFileExW -> @void lpExistingFileName, @void lpNewFileName, @func lpProgressRoutine, @void lpData, @int pbCancel, utype int dwCopyFlags;
stub int CopyFileTransactedA -> str lpExistingFileName, str lpNewFileName, @func lpProgressRoutine, @void lpData, @int pbCancel, utype int dwCopyFlags, @void hTransaction;
stub int CopyFileTransactedW -> @void lpExistingFileName, @void lpNewFileName, @func lpProgressRoutine, @void lpData, @int pbCancel, utype int dwCopyFlags, @void hTransaction;
stub int CopyFileW -> @void lpExistingFileName, @void lpNewFileName, int bFailIfExists;
stub int CopyLZFile -> int a1, int a2;
stub @void CreateActCtxA -> @void pActCtx;
stub @void CreateActCtxW -> @void pActCtx;
stub @void CreateBoundaryDescriptorA -> str Name, utype int Flags;
stub @void CreateBoundaryDescriptorW -> @void Name, utype int Flags;
stub @void CreateConsoleScreenBuffer -> utype int desired_access, utype int share_mode, @void security_attributes, utype int flags, @void screen_buffer_data;
stub int CreateDirectoryA -> str lpPathName, @void lpSecurityAttributes;
stub int CreateDirectoryExA -> str lpTemplateDirectory, str lpNewDirectory, @void lpSecurityAttributes;
stub int CreateDirectoryExW -> @void lpTemplateDirectory, @void lpNewDirectory, @void lpSecurityAttributes;
stub int CreateDirectoryTransactedA -> str lpTemplateDirectory, str lpNewDirectory, @void lpSecurityAttributes, @void hTransaction;
stub int CreateDirectoryTransactedW -> @void lpTemplateDirectory, @void lpNewDirectory, @void lpSecurityAttributes, @void hTransaction;
stub int CreateDirectoryW -> @void lpPathName, @void lpSecurityAttributes;
stub @void CreateEventA -> @void lpEventAttributes, int bManualReset, int bInitialState, str lpName;
stub @void CreateEventExA -> @void lpEventAttributes, str lpName, utype int dwFlags, utype int dwDesiredAccess;
stub @void CreateEventExW -> @void lpEventAttributes, @void lpName, utype int dwFlags, utype int dwDesiredAccess;
stub @void CreateEventW -> @void lpEventAttributes, int bManualReset, int bInitialState, @void lpName;
stub @void CreateFiber -> utype longlong dwStackSize, @func lpStartAddress, @void lpParameter;
stub @void CreateFiberEx -> utype longlong dwStackCommitSize, utype longlong dwStackReserveSize, utype int dwFlags, @func lpStartAddress, @void lpParameter;
stub @void CreateFile2 -> @void lpFileName, utype int dwDesiredAccess, utype int dwShareMode, utype int dwCreationDisposition, @void pCreateExParams;
stub @void CreateFileA -> str lpFileName, utype int dwDesiredAccess, utype int dwShareMode, @void lpSecurityAttributes, utype int dwCreationDisposition, utype int dwFlagsAndAttributes, @void hTemplateFile;
stub @void CreateFileMappingA -> @void hFile, @void lpFileMappingAttributes, utype int flProtect, utype int dwMaximumSizeHigh, utype int dwMaximumSizeLow, str lpName;
stub @void CreateFileMappingFromApp -> @void hFile, @void SecurityAttributes, utype int PageProtection, utype longlong MaximumSize, @void Name;
stub @void CreateFileMappingNumaA -> @void hFile, @void lpFileMappingAttributes, utype int flProtect, utype int dwMaximumSizeHigh, utype int dwMaximumSizeLow, str lpName, utype int nndPreferred;
stub @void CreateFileMappingNumaW -> @void hFile, @void lpFileMappingAttributes, utype int flProtect, utype int dwMaximumSizeHigh, utype int dwMaximumSizeLow, @void lpName, utype int nndPreferred;
stub @void CreateFileMappingW -> @void hFile, @void lpFileMappingAttributes, utype int flProtect, utype int dwMaximumSizeHigh, utype int dwMaximumSizeLow, @void lpName;
stub @void CreateFileTransactedA -> str lpFileName, utype int dwDesiredAccess, utype int dwShareMode, @void lpSecurityAttributes, utype int dwCreationDisposition, utype int dwFlagsAndAttributes, @void hTemplateFile, @void hTransaction, @int pusMiniVersion, @void lpExtendedParameter;
stub @void CreateFileTransactedW -> @void lpFileName, utype int dwDesiredAccess, utype int dwShareMode, @void lpSecurityAttributes, utype int dwCreationDisposition, utype int dwFlagsAndAttributes, @void hTemplateFile, @void hTransaction, @int pusMiniVersion, @void lpExtendedParameter;
stub @void CreateFileW -> @void lpFileName, utype int dwDesiredAccess, utype int dwShareMode, @void lpSecurityAttributes, utype int dwCreationDisposition, utype int dwFlagsAndAttributes, @void hTemplateFile;
stub int CreateHardLinkA -> str lpFileName, str lpExistingFileName, @void lpSecurityAttributes;
stub int CreateHardLinkTransactedA -> str lpFileName, str lpExistingFileName, @void lpSecurityAttributes, @void hTransaction;
stub int CreateHardLinkTransactedW -> @void lpFileName, @void lpExistingFileName, @void lpSecurityAttributes, @void hTransaction;
stub int CreateHardLinkW -> @void lpFileName, @void lpExistingFileName, @void lpSecurityAttributes;
stub @void CreateIoCompletionPort -> @void FileHandle, @void ExistingCompletionPort, utype longlong CompletionKey, utype int NumberOfConcurrentThreads;
stub @void CreateJobObjectA -> @void lpJobAttributes, str lpName;
stub @void CreateJobObjectW -> @void lpJobAttributes, @void lpName;
stub int CreateJobSet -> utype int NumJob, @void UserJobSet, utype int Flags;
stub @void CreateMailslotA -> str lpName, utype int nMaxMessageSize, utype int lReadTimeout, @void lpSecurityAttributes;
stub @void CreateMailslotW -> @void lpName, utype int nMaxMessageSize, utype int lReadTimeout, @void lpSecurityAttributes;
stub @void CreateMutexA -> @void lpMutexAttributes, int bInitialOwner, str lpName;
stub @void CreateMutexExA -> @void lpMutexAttributes, str lpName, utype int dwFlags, utype int dwDesiredAccess;
stub @void CreateMutexExW -> @void lpMutexAttributes, @void lpName, utype int dwFlags, utype int dwDesiredAccess;
stub @void CreateMutexW -> @void lpMutexAttributes, int bInitialOwner, @void lpName;
stub @void CreateNamedPipeA -> str lpName, utype int dwOpenMode, utype int dwPipeMode, utype int nMaxInstances, utype int nOutBufferSize, utype int nInBufferSize, utype int nDefaultTimeOut, @void lpSecurityAttributes;
stub @void CreateNamedPipeW -> @void lpName, utype int dwOpenMode, utype int dwPipeMode, utype int nMaxInstances, utype int nOutBufferSize, utype int nInBufferSize, utype int nDefaultTimeOut, @void lpSecurityAttributes;
stub int CreatePipe -> @void hReadPipe, @void hWritePipe, @void lpPipeAttributes, utype int nSize;
stub @void CreatePrivateNamespaceA -> @void lpPrivateNamespaceAttributes, @void lpBoundaryDescriptor, str lpAliasPrefix;
stub @void CreatePrivateNamespaceW -> @void lpPrivateNamespaceAttributes, @void lpBoundaryDescriptor, @void lpAliasPrefix;
stub int CreateProcessA -> str lpApplicationName, str lpCommandLine, @void lpProcessAttributes, @void lpThreadAttributes, int bInheritHandles, utype int dwCreationFlags, @void lpEnvironment, str lpCurrentDirectory, @void lpStartupInfo, @void lpProcessInformation;
stub int CreateProcessAsUserA -> @void hToken, str lpApplicationName, str lpCommandLine, @void lpProcessAttributes, @void lpThreadAttributes, int bInheritHandles, utype int dwCreationFlags, @void lpEnvironment, str lpCurrentDirectory, @void lpStartupInfo, @void lpProcessInformation;
stub int CreateProcessAsUserW -> @void hToken, @void lpApplicationName, @void lpCommandLine, @void lpProcessAttributes, @void lpThreadAttributes, int bInheritHandles, utype int dwCreationFlags, @void lpEnvironment, @void lpCurrentDirectory, @void lpStartupInfo, @void lpProcessInformation;
stub int CreateProcessW -> @void lpApplicationName, @void lpCommandLine, @void lpProcessAttributes, @void lpThreadAttributes, int bInheritHandles, utype int dwCreationFlags, @void lpEnvironment, @void lpCurrentDirectory, @void lpStartupInfo, @void lpProcessInformation;
stub @void CreateRemoteThread -> @void hProcess, @void lpThreadAttributes, utype longlong dwStackSize, @func lpStartAddress, @void lpParameter, utype int dwCreationFlags, @int lpThreadId;
stub @void CreateRemoteThreadEx -> @void hProcess, @void lpThreadAttributes, utype longlong dwStackSize, @func lpStartAddress, @void lpParameter, utype int dwCreationFlags, @void lpAttributeList, @int lpThreadId;
stub @void CreateSemaphoreA -> @void lpSemaphoreAttributes, int lInitialCount, int lMaximumCount, str lpName;
stub @void CreateSemaphoreExA -> @void lpSemaphoreAttributes, int lInitialCount, int lMaximumCount, str lpName, utype int dwFlags, utype int dwDesiredAccess;
stub @void CreateSemaphoreExW -> @void lpSemaphoreAttributes, int lInitialCount, int lMaximumCount, @void lpName, utype int dwFlags, utype int dwDesiredAccess;
stub @void CreateSemaphoreW -> @void lpSemaphoreAttributes, int lInitialCount, int lMaximumCount, @void lpName;
stub utype char CreateSymbolicLinkA -> str lpSymlinkFileName, str lpTargetFileName, utype int dwFlags;
stub utype char CreateSymbolicLinkTransactedA -> str lpSymlinkFileName, str lpTargetFileName, utype int dwFlags, @void hTransaction;
stub utype char CreateSymbolicLinkTransactedW -> @void lpSymlinkFileName, @void lpTargetFileName, utype int dwFlags, @void hTransaction;
stub utype char CreateSymbolicLinkW -> @void lpSymlinkFileName, @void lpTargetFileName, utype int dwFlags;
stub utype int CreateTapePartition -> @void hDevice, utype int dwPartitionMethod, utype int dwCount, utype int dwSize;
stub @void CreateThread -> @void lpThreadAttributes, utype longlong dwStackSize, @func lpStartAddress, @void lpParameter, utype int dwCreationFlags, @int lpThreadId;
stub @void CreateThreadpool -> @void reserved;
stub @void CreateThreadpoolCleanupGroup;
stub @void CreateThreadpoolIo -> @void fl, @func pfnio, @void pv, @void pcbe;
stub @void CreateThreadpoolTimer -> @func pfnti, @void pv, @void pcbe;
stub @void CreateThreadpoolWait -> @func pfnwa, @void pv, @void pcbe;
stub @void CreateThreadpoolWork -> @func pfnwk, @void pv, @void pcbe;
stub @void CreateTimerQueue;
stub int CreateTimerQueueTimer -> @void phNewTimer, @void TimerQueue, @func Callback, @void Parameter, utype int DueTime, utype int Period, utype int Flags;
stub int CreateUmsCompletionList -> @void UmsCompletionList;
stub int CreateUmsThreadContext -> @void lpUmsThread;
stub @void CreateWaitableTimerA -> @void lpTimerAttributes, int bManualReset, str lpTimerName;
stub @void CreateWaitableTimerExA -> @void lpTimerAttributes, str lpTimerName, utype int dwFlags, utype int dwDesiredAccess;
stub @void CreateWaitableTimerExW -> @void lpTimerAttributes, @void lpTimerName, utype int dwFlags, utype int dwDesiredAccess;
stub @void CreateWaitableTimerW -> @void lpTimerAttributes, int bManualReset, @void lpTimerName;
stub int DeactivateActCtx -> utype int dwFlags, utype longlong ulCookie;
stub int DebugActiveProcess -> utype int dwProcessId;
stub int DebugActiveProcessStop -> utype int dwProcessId;
stub void DebugBreak;
stub int DebugBreakProcess -> @void Process;
stub int DebugSetProcessKillOnExit -> int KillOnExit;
stub @void DecodePointer -> @void Ptr;
stub @void DecodeSystemPointer -> @void Ptr;
stub int DefineDosDeviceA -> utype int dwFlags, str lpDeviceName, str lpTargetPath;
stub int DefineDosDeviceW -> utype int dwFlags, @void lpDeviceName, @void lpTargetPath;
stub utype int DeleteAtom -> utype int nAtom;
stub void DeleteBoundaryDescriptor -> @void BoundaryDescriptor;
stub void DeleteCriticalSection -> @void lpCriticalSection;
stub void DeleteFiber -> @void lpFiber;
stub int DeleteFileA -> str lpFileName;
stub int DeleteFileTransactedA -> str lpFileName, @void hTransaction;
stub int DeleteFileTransactedW -> @void lpFileName, @void hTransaction;
stub int DeleteFileW -> @void lpFileName;
stub void DeleteProcThreadAttributeList -> @void lpAttributeList;
stub int DeleteSynchronizationBarrier -> @void lpBarrier;
stub int DeleteTimerQueue -> @void TimerQueue;
stub int DeleteTimerQueueEx -> @void TimerQueue, @void CompletionEvent;
stub int DeleteTimerQueueTimer -> @void TimerQueue, @void Timer, @void CompletionEvent;
stub int DeleteUmsCompletionList -> @void UmsCompletionList;
stub int DeleteUmsThreadContext -> @void UmsThread;
stub int DeleteVolumeMountPointA -> str lpszVolumeMountPoint;
stub int DeleteVolumeMountPointW -> @void lpszVolumeMountPoint;
stub int DequeueUmsCompletionListItems -> @void UmsCompletionList, utype int WaitTimeOut, @void UmsThreadList;
stub int DeviceIoControl -> @void hDevice, utype int dwIoControlCode, @void lpInBuffer, utype int nInBufferSize, @void lpOutBuffer, utype int nOutBufferSize, @int lpBytesReturned, @void lpOverlapped;
stub int DisableThreadLibraryCalls -> @void hLibModule;
stub utype int DisableThreadProfiling -> @void PerformanceDataHandle;
stub void DisassociateCurrentThreadFromCallback -> @void pci;
stub utype int DiscardVirtualMemory -> @void VirtualAddress, utype longlong Size;
stub int DisconnectNamedPipe -> @void hNamedPipe;
stub int DnsHostnameToComputerNameA -> str Hostname, str ComputerName, @int nSize;
stub int DnsHostnameToComputerNameW -> @void Hostname, @void ComputerName, @int nSize;
stub int DosDateTimeToFileTime -> utype int wFatDate, utype int wFatTime, @void lpFileTime;
stub int DuplicateHandle -> @void hSourceProcessHandle, @void hSourceHandle, @void hTargetProcessHandle, @void lpTargetHandle, utype int dwDesiredAccess, int bInheritHandle, utype int dwOptions;
stub utype int EnableThreadProfiling -> @void ThreadHandle, utype int Flags, utype longlong HardwareCounters, @void PerformanceDataHandle;
stub @void EncodePointer -> @void Ptr;
stub @void EncodeSystemPointer -> @void Ptr;
stub int EndUpdateResourceA -> @void hUpdate, int fDiscard;
stub int EndUpdateResourceW -> @void hUpdate, int fDiscard;
stub void EnterCriticalSection -> @void lpCriticalSection;
stub int EnterSynchronizationBarrier -> @void lpBarrier, utype int dwFlags;
stub int EnterUmsSchedulingMode -> @void SchedulerStartupInfo;
stub int EnumCalendarInfoA -> @func lpCalInfoEnumProc, utype int Locale, utype int Calendar, utype int CalType;
stub int EnumCalendarInfoExA -> @func lpCalInfoEnumProcEx, utype int Locale, utype int Calendar, utype int CalType;
stub int EnumCalendarInfoExEx -> @func pCalInfoEnumProcExEx, @void lpLocaleName, utype int Calendar, @void lpReserved, utype int CalType, longlong lParam;
stub int EnumCalendarInfoExW -> @func lpCalInfoEnumProcEx, utype int Locale, utype int Calendar, utype int CalType;
stub int EnumCalendarInfoW -> @func lpCalInfoEnumProc, utype int Locale, utype int Calendar, utype int CalType;
stub int EnumDateFormatsA -> @func lpDateFmtEnumProc, utype int Locale, utype int dwFlags;
stub int EnumDateFormatsExA -> @func lpDateFmtEnumProcEx, utype int Locale, utype int dwFlags;
stub int EnumDateFormatsExEx -> @func lpDateFmtEnumProcExEx, @void lpLocaleName, utype int dwFlags, longlong lParam;
stub int EnumDateFormatsExW -> @func lpDateFmtEnumProcEx, utype int Locale, utype int dwFlags;
stub int EnumDateFormatsW -> @func lpDateFmtEnumProc, utype int Locale, utype int dwFlags;
stub int EnumLanguageGroupLocalesA -> @func lpLangGroupLocaleEnumProc, utype int LanguageGroup, utype int dwFlags, longlong lParam;
stub int EnumLanguageGroupLocalesW -> @func lpLangGroupLocaleEnumProc, utype int LanguageGroup, utype int dwFlags, longlong lParam;
stub int EnumResourceLanguagesA -> @void hModule, str lpType, str lpName, @func lpEnumFunc, longlong lParam;
stub int EnumResourceLanguagesExA -> @void hModule, str lpType, str lpName, @func lpEnumFunc, longlong lParam, utype int dwFlags, utype int LangId;
stub int EnumResourceLanguagesExW -> @void hModule, @void lpType, @void lpName, @func lpEnumFunc, longlong lParam, utype int dwFlags, utype int LangId;
stub int EnumResourceLanguagesW -> @void hModule, @void lpType, @void lpName, @func lpEnumFunc, longlong lParam;
stub int EnumResourceNamesA -> @void hModule, str lpType, @func lpEnumFunc, longlong lParam;
stub int EnumResourceNamesExA -> @void hModule, str lpType, @func lpEnumFunc, longlong lParam, utype int dwFlags, utype int LangId;
stub int EnumResourceNamesExW -> @void hModule, @void lpType, @func lpEnumFunc, longlong lParam, utype int dwFlags, utype int LangId;
stub int EnumResourceNamesW -> @void hModule, @void lpType, @func lpEnumFunc, longlong lParam;
stub int EnumResourceTypesA -> @void hModule, @func lpEnumFunc, longlong lParam;
stub int EnumResourceTypesExA -> @void hModule, @func lpEnumFunc, longlong lParam, utype int dwFlags, utype int LangId;
stub int EnumResourceTypesExW -> @void hModule, @func lpEnumFunc, longlong lParam, utype int dwFlags, utype int LangId;
stub int EnumResourceTypesW -> @void hModule, @func lpEnumFunc, longlong lParam;
stub int EnumSystemCodePagesA -> @func lpCodePageEnumProc, utype int dwFlags;
stub int EnumSystemCodePagesW -> @func lpCodePageEnumProc, utype int dwFlags;
stub utype int EnumSystemFirmwareTables -> utype int FirmwareTableProviderSignature, @void pFirmwareTableEnumBuffer, utype int BufferSize;
stub int EnumSystemGeoID -> utype int GeoClass, int ParentGeoId, @func lpGeoEnumProc;
stub int EnumSystemGeoNames -> utype int geoClass, @func geoEnumProc, longlong data;
stub int EnumSystemLanguageGroupsA -> @func lpLanguageGroupEnumProc, utype int dwFlags, longlong lParam;
stub int EnumSystemLanguageGroupsW -> @func lpLanguageGroupEnumProc, utype int dwFlags, longlong lParam;
stub int EnumSystemLocalesA -> @func lpLocaleEnumProc, utype int dwFlags;
stub int EnumSystemLocalesEx -> @func lpLocaleEnumProcEx, utype int dwFlags, longlong lParam, @void lpReserved;
stub int EnumSystemLocalesW -> @func lpLocaleEnumProc, utype int dwFlags;
stub int EnumTimeFormatsA -> @func lpTimeFmtEnumProc, utype int Locale, utype int dwFlags;
stub int EnumTimeFormatsEx -> @func lpTimeFmtEnumProcEx, @void lpLocaleName, utype int dwFlags, longlong lParam;
stub int EnumTimeFormatsW -> @func lpTimeFmtEnumProc, utype int Locale, utype int dwFlags;
stub int EnumUILanguagesA -> @func lpUILanguageEnumProc, utype int dwFlags, longlong lParam;
stub int EnumUILanguagesW -> @func lpUILanguageEnumProc, utype int dwFlags, longlong lParam;
stub utype int EraseTape -> @void hDevice, utype int dwEraseType, int bImmediate;
stub int EscapeCommFunction -> @void hFile, utype int dwFunc;
stub int ExecuteUmsThread -> @void UmsThread;
stub void ExitProcess -> utype int uExitCode;
stub void ExitThread -> utype int dwExitCode;
stub utype int ExpandEnvironmentStringsA -> str lpSrc, str lpDst, utype int nSize;
stub utype int ExpandEnvironmentStringsW -> @void lpSrc, @void lpDst, utype int nSize;
stub void ExpungeConsoleCommandHistoryA -> str exe_name;
stub void ExpungeConsoleCommandHistoryW -> @void exe_name;
stub void FatalAppExitA -> utype int uAction, str lpMessageText;
stub void FatalAppExitW -> utype int uAction, @void lpMessageText;
stub void FatalExit -> int ExitCode;
stub int FileTimeToDosDateTime -> @void lpFileTime, @int lpFatDate, @int lpFatTime;
stub int FileTimeToLocalFileTime -> @void lpFileTime, @void lpLocalFileTime;
stub int FileTimeToSystemTime -> @void lpFileTime, @void lpSystemTime;
stub int FindActCtxSectionGuid -> utype int dwFlags, @void lpExtensionGuid, utype int ulSectionId, @void lpGuidToFind, @void ReturnedData;
stub int FindActCtxSectionStringA -> utype int dwFlags, @void lpExtensionGuid, utype int ulSectionId, str lpStringToFind, @void ReturnedData;
stub int FindActCtxSectionStringW -> utype int dwFlags, @void lpExtensionGuid, utype int ulSectionId, @void lpStringToFind, @void ReturnedData;
stub utype int FindAtomA -> str lpString;
stub utype int FindAtomW -> @void lpString;
stub int FindClose -> @void hFindFile;
stub int FindCloseChangeNotification -> @void hChangeHandle;
stub @void FindFirstChangeNotificationA -> str lpPathName, int bWatchSubtree, utype int dwNotifyFilter;
stub @void FindFirstChangeNotificationW -> @void lpPathName, int bWatchSubtree, utype int dwNotifyFilter;
stub @void FindFirstFileA -> str lpFileName, @void lpFindFileData;
stub @void FindFirstFileNameTransactedW -> @void lpFileName, utype int dwFlags, @int StringLength, @void LinkName, @void hTransaction;
stub @void FindFirstFileNameW -> @void lpFileName, utype int dwFlags, @int StringLength, @void LinkName;
stub @void FindFirstFileW -> @void lpFileName, @void lpFindFileData;
stub @void FindFirstVolumeA -> str lpszVolumeName, utype int cchBufferLength;
stub @void FindFirstVolumeMountPointA -> str lpszRootPathName, str lpszVolumeMountPoint, utype int cchBufferLength;
stub @void FindFirstVolumeMountPointW -> @void lpszRootPathName, @void lpszVolumeMountPoint, utype int cchBufferLength;
stub @void FindFirstVolumeW -> @void lpszVolumeName, utype int cchBufferLength;
stub int FindNLSString -> utype int Locale, utype int dwFindNLSStringFlags, @void lpStringSource, int cchSource, @void lpStringValue, int cchValue, @int pcchFound;
stub int FindNLSStringEx -> @void lpLocaleName, utype int dwFindNLSStringFlags, @void lpStringSource, int cchSource, @void lpStringValue, int cchValue, @int pcchFound, @void lpVersionInformation, @void lpReserved, longlong sortHandle;
stub int FindNextChangeNotification -> @void hChangeHandle;
stub int FindNextFileA -> @void hFindFile, @void lpFindFileData;
stub int FindNextFileNameW -> @void hFindStream, @int StringLength, @void LinkName;
stub int FindNextFileW -> @void hFindFile, @void lpFindFileData;
stub int FindNextStreamW -> @void hFindStream, @void lpFindStreamData;
stub int FindNextVolumeA -> @void hFindVolume, str lpszVolumeName, utype int cchBufferLength;
stub int FindNextVolumeMountPointA -> @void hFindVolumeMountPoint, str lpszVolumeMountPoint, utype int cchBufferLength;
stub int FindNextVolumeMountPointW -> @void hFindVolumeMountPoint, @void lpszVolumeMountPoint, utype int cchBufferLength;
stub int FindNextVolumeW -> @void hFindVolume, @void lpszVolumeName, utype int cchBufferLength;
stub int FindPackagesByPackageFamily -> @void packageFamilyName, utype int packageFilters, @int cnt, @void packageFullNames, @int bufferLength, @void buffer, @int packageProperties;
stub @void FindResourceA -> @void hModule, str lpName, str lpType;
stub @void FindResourceExA -> @void hModule, str lpType, str lpName, utype int wLanguage;
stub @void FindResourceExW -> @void hModule, @void lpType, @void lpName, utype int wLanguage;
stub @void FindResourceW -> @void hModule, @void lpName, @void lpType;
stub int FindStringOrdinal -> utype int dwFindStringOrdinalFlags, @void lpStringSource, int cchSource, @void lpStringValue, int cchValue, int bIgnoreCase;
stub int FindVolumeClose -> @void hFindVolume;
stub int FindVolumeMountPointClose -> @void hFindVolumeMountPoint;
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
stub int FoldStringA -> utype int dwMapFlags, str lpSrcStr, int cchSrc, str lpDestStr, int cchDest;
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
stub int FreeUserPhysicalPages -> @void hProcess, @longlong NumberOfPages, @longlong PageArray;
stub int GenerateConsoleCtrlEvent -> utype int ctrl_event, utype int process_group_id;
stub utype int GetACP;
stub utype int GetActiveProcessorCount -> utype int GroupNumber;
stub utype int GetActiveProcessorGroupCount;
stub int GetAppContainerAce -> @void Acl, utype int StartingAceIndex, @void AppContainerAce, @int AppContainerAceIndex;
stub int GetAppContainerNamedObjectPath -> @void Token, @void AppContainerSid, utype int ObjectPathLength, @void ObjectPath, @int ReturnLength;
stub int GetApplicationRecoveryCallback -> @void hProcess, @void pRecoveryCallback, @void ppvParameter, @int pdwPingInterval, @int pdwFlags;
stub int GetApplicationRestartSettings -> @void hProcess, @void pwzCommandline, @int pcchSize, @int pdwFlags;
stub int GetApplicationUserModelId -> @void hProcess, @int applicationUserModelIdLength, @void applicationUserModelId;
stub utype int GetAtomNameA -> utype int nAtom, str lpBuffer, int nSize;
stub utype int GetAtomNameW -> utype int nAtom, @void lpBuffer, int nSize;
stub int GetBinaryTypeA -> str lpApplicationName, @int lpBinaryType;
stub int GetBinaryTypeW -> @void lpApplicationName, @int lpBinaryType;
stub int GetCPInfo -> utype int CodePage, @void lpCPInfo;
stub int GetCPInfoExA -> utype int CodePage, utype int dwFlags, @void lpCPInfoEx;
stub int GetCPInfoExW -> utype int CodePage, utype int dwFlags, @void lpCPInfoEx;
stub int GetCachedSigningLevel -> @void File, @int Flags, @int SigningLevel, @char Thumbprint, @int ThumbprintSize, @int ThumbprintAlgorithm;
stub int GetCalendarInfoA -> utype int Locale, utype int Calendar, utype int CalType, str lpCalData, int cchData, @int lpValue;
stub int GetCalendarInfoEx -> @void lpLocaleName, utype int Calendar, @void lpReserved, utype int CalType, @void lpCalData, int cchData, @int lpValue;
stub int GetCalendarInfoW -> utype int Locale, utype int Calendar, utype int CalType, @void lpCalData, int cchData, @int lpValue;
stub int GetCommConfig -> @void hCommDev, @void lpCC, @int lpdwSize;
stub int GetCommMask -> @void hFile, @int lpEvtMask;
stub int GetCommModemStatus -> @void hFile, @int lpModemStat;
stub int GetCommProperties -> @void hFile, @void lpCommProp;
stub int GetCommState -> @void hFile, @void lpDCB;
stub int GetCommTimeouts -> @void hFile, @void lpCommTimeouts;
stub str GetCommandLineA;
stub @void GetCommandLineW;
stub utype int GetCompressedFileSizeA -> str lpFileName, @int lpFileSizeHigh;
stub utype int GetCompressedFileSizeTransactedA -> str lpFileName, @int lpFileSizeHigh, @void hTransaction;
stub utype int GetCompressedFileSizeTransactedW -> @void lpFileName, @int lpFileSizeHigh, @void hTransaction;
stub utype int GetCompressedFileSizeW -> @void lpFileName, @int lpFileSizeHigh;
stub int GetComputerNameA -> str lpBuffer, @int nSize;
stub int GetComputerNameW -> @void lpBuffer, @int nSize;
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
stub int GetCurrencyFormatA -> utype int Locale, utype int dwFlags, str lpValue, @void lpFormat, str lpCurrencyStr, int cchCurrency;
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
stub @void GetCurrentUmsThread;
stub int GetDateFormatA -> utype int Locale, utype int dwFlags, @void lpDate, str lpFormat, str lpDateStr, int cchDate;
stub int GetDateFormatEx -> @void lpLocaleName, utype int dwFlags, @void lpDate, @void lpFormat, @void lpDateStr, int cchDate, @void lpCalendar;
stub int GetDateFormatW -> utype int Locale, utype int dwFlags, @void lpDate, @void lpFormat, @void lpDateStr, int cchDate;
stub int GetDefaultCommConfigA -> str lpszName, @void lpCC, @int lpdwSize;
stub int GetDefaultCommConfigW -> @void lpszName, @void lpCC, @int lpdwSize;
stub int GetDevicePowerState -> @void hDevice, @int pfOn;
stub int GetDiskFreeSpaceA -> str lpRootPathName, @int lpSectorsPerCluster, @int lpBytesPerSector, @int lpNumberOfFreeClusters, @int lpTotalNumberOfClusters;
stub int GetDiskFreeSpaceExA -> str lpDirectoryName, @longlong lpFreeBytesAvailableToCaller, @longlong lpTotalNumberOfBytes, @longlong lpTotalNumberOfFreeBytes;
stub int GetDiskFreeSpaceExW -> @void lpDirectoryName, @longlong lpFreeBytesAvailableToCaller, @longlong lpTotalNumberOfBytes, @longlong lpTotalNumberOfFreeBytes;
stub int GetDiskFreeSpaceW -> @void lpRootPathName, @int lpSectorsPerCluster, @int lpBytesPerSector, @int lpNumberOfFreeClusters, @int lpTotalNumberOfClusters;
stub int GetDiskSpaceInformationA -> str rootPath, @void diskSpaceInfo;
stub int GetDiskSpaceInformationW -> @void rootPath, @void diskSpaceInfo;
stub utype int GetDllDirectoryA -> utype int nBufferLength, str lpBuffer;
stub utype int GetDllDirectoryW -> utype int nBufferLength, @void lpBuffer;
stub utype int GetDriveTypeA -> str lpRootPathName;
stub utype int GetDriveTypeW -> @void lpRootPathName;
stub int GetDurationFormat -> utype int Locale, utype int dwFlags, @void lpDuration, utype longlong ullDuration, @void lpFormat, @void lpDurationStr, int cchDuration;
stub int GetDurationFormatEx -> @void lpLocaleName, utype int dwFlags, @void lpDuration, utype longlong ullDuration, @void lpFormat, @void lpDurationStr, int cchDuration;
stub utype int GetDynamicTimeZoneInformation -> @void pTimeZoneInformation;
stub utype longlong GetEnabledXStateFeatures;
stub str GetEnvironmentStrings;
stub @void GetEnvironmentStringsW;
stub utype int GetEnvironmentVariableA -> str lpName, str lpBuffer, utype int nSize;
stub utype int GetEnvironmentVariableW -> @void lpName, @void lpBuffer, utype int nSize;
stub utype int GetErrorMode;
stub int GetExitCodeProcess -> @void hProcess, @int lpExitCode;
stub int GetExitCodeThread -> @void hThread, @int lpExitCode;
stub int GetExpandedNameA -> str a1, str a2;
stub int GetExpandedNameW -> @void a1, @void a2;
stub utype int GetFileAttributesA -> str lpFileName;
stub utype int GetFileAttributesW -> @void lpFileName;
stub int GetFileBandwidthReservation -> @void hFile, @int lpPeriodMilliseconds, @int lpBytesPerPeriod, @int pDiscardable, @int lpTransferSize, @int lpNumOutstandingRequests;
stub int GetFileInformationByHandle -> @void hFile, @void lpFileInformation;
stub int GetFileMUIInfo -> utype int dwFlags, @void pcwszFilePath, @void pFileMUIInfo, @int pcbFileMUIInfo;
stub int GetFileMUIPath -> utype int dwFlags, @void pcwszFilePath, @void pwszLanguage, @int pcchLanguage, @void pwszFileMUIPath, @int pcchFileMUIPath, @longlong pululEnumerator;
stub utype int GetFileSize -> @void hFile, @int lpFileSizeHigh;
stub int GetFileSizeEx -> @void hFile, @longlong lpFileSize;
stub int GetFileTime -> @void hFile, @void lpCreationTime, @void lpLastAccessTime, @void lpLastWriteTime;
stub utype int GetFileType -> @void hFile;
stub utype int GetFinalPathNameByHandleA -> @void hFile, str lpszFilePath, utype int cchFilePath, utype int dwFlags;
stub utype int GetFinalPathNameByHandleW -> @void hFile, @void lpszFilePath, utype int cchFilePath, utype int dwFlags;
stub utype int GetFirmwareEnvironmentVariableA -> str lpName, str lpGuid, @void pBuffer, utype int nSize;
stub utype int GetFirmwareEnvironmentVariableExA -> str lpName, str lpGuid, @void pBuffer, utype int nSize, @int pdwAttribubutes;
stub utype int GetFirmwareEnvironmentVariableExW -> @void lpName, @void lpGuid, @void pBuffer, utype int nSize, @int pdwAttribubutes;
stub utype int GetFirmwareEnvironmentVariableW -> @void lpName, @void lpGuid, @void pBuffer, utype int nSize;
stub int GetFirmwareType -> @void FirmwareType;
stub utype int GetFullPathNameA -> str lpFileName, utype int nBufferLength, str lpBuffer, @void lpFilePart;
stub utype int GetFullPathNameTransactedA -> str lpFileName, utype int nBufferLength, str lpBuffer, @void lpFilePart, @void hTransaction;
stub utype int GetFullPathNameTransactedW -> @void lpFileName, utype int nBufferLength, @void lpBuffer, @void lpFilePart, @void hTransaction;
stub utype int GetFullPathNameW -> @void lpFileName, utype int nBufferLength, @void lpBuffer, @void lpFilePart;
stub int GetGeoInfoA -> int Location, utype int GeoType, str lpGeoData, int cchData, utype int LangId;
stub int GetGeoInfoEx -> @void location, utype int geoType, @void geoData, int geoDataCount;
stub int GetGeoInfoW -> int Location, utype int GeoType, @void lpGeoData, int cchData, utype int LangId;
stub int GetHandleInformation -> @void hObject, @int lpdwFlags;
stub utype longlong GetLargePageMinimum;
stub utype int GetLastError;
stub void GetLocalTime -> @void lpSystemTime;
stub int GetLocaleInfoA -> utype int Locale, utype int LCType, str lpLCData, int cchData;
stub int GetLocaleInfoEx -> @void lpLocaleName, utype int LCType, @void lpLCData, int cchData;
stub int GetLocaleInfoW -> utype int Locale, utype int LCType, @void lpLCData, int cchData;
stub utype int GetLogicalDriveStringsA -> utype int nBufferLength, str lpBuffer;
stub utype int GetLogicalDriveStringsW -> utype int nBufferLength, @void lpBuffer;
stub utype int GetLogicalDrives;
stub int GetLogicalProcessorInformation -> @void Buffer, @int ReturnedLength;
stub utype int GetLongPathNameA -> str lpszShortPath, str lpszLongPath, utype int cchBuffer;
stub utype int GetLongPathNameTransactedA -> str lpszShortPath, str lpszLongPath, utype int cchBuffer, @void hTransaction;
stub utype int GetLongPathNameTransactedW -> @void lpszShortPath, @void lpszLongPath, utype int cchBuffer, @void hTransaction;
stub utype int GetLongPathNameW -> @void lpszShortPath, @void lpszLongPath, utype int cchBuffer;
stub int GetMachineTypeAttributes -> utype int Machine, @void MachineTypeAttributes;
stub int GetMailslotInfo -> @void hMailslot, @int lpMaxMessageSize, @int lpNextSize, @int lpMessageCount, @int lpReadTimeout;
stub utype int GetMaximumProcessorCount -> utype int GroupNumber;
stub utype int GetMaximumProcessorGroupCount;
stub int GetMemoryErrorHandlingCapabilities -> @int Capabilities;
stub utype int GetModuleFileNameA -> @void hModule, str lpFilename, utype int nSize;
stub utype int GetModuleFileNameW -> @void hModule, @void lpFilename, utype int nSize;
stub @void GetModuleHandleA -> str lpModuleName;
stub int GetModuleHandleExA -> utype int dwFlags, str lpModuleName, @void phModule;
stub int GetModuleHandleExW -> utype int dwFlags, @void lpModuleName, @void phModule;
stub @void GetModuleHandleW -> @void lpModuleName;
stub int GetNLSVersion -> utype int Function, utype int Locale, @void lpVersionInformation;
stub int GetNLSVersionEx -> utype int function, @void lpLocaleName, @void lpVersionInformation;
stub int GetNamedPipeClientComputerNameA -> @void Pipe, str ClientComputerName, utype int ClientComputerNameLength;
stub int GetNamedPipeClientComputerNameW -> @void Pipe, @void ClientComputerName, utype int ClientComputerNameLength;
stub int GetNamedPipeClientProcessId -> @void Pipe, @int ClientProcessId;
stub int GetNamedPipeClientSessionId -> @void Pipe, @int ClientSessionId;
stub int GetNamedPipeHandleStateA -> @void hNamedPipe, @int lpState, @int lpCurInstances, @int lpMaxCollectionCount, @int lpCollectDataTimeout, str lpUserName, utype int nMaxUserNameSize;
stub int GetNamedPipeHandleStateW -> @void hNamedPipe, @int lpState, @int lpCurInstances, @int lpMaxCollectionCount, @int lpCollectDataTimeout, @void lpUserName, utype int nMaxUserNameSize;
stub int GetNamedPipeInfo -> @void hNamedPipe, @int lpFlags, @int lpOutBufferSize, @int lpInBufferSize, @int lpMaxInstances;
stub int GetNamedPipeServerProcessId -> @void Pipe, @int ServerProcessId;
stub int GetNamedPipeServerSessionId -> @void Pipe, @int ServerSessionId;
stub void GetNativeSystemInfo -> @void lpSystemInfo;
stub @void GetNextUmsListItem -> @void UmsContext;
stub int GetNumaAvailableMemoryNode -> utype char Node, @longlong AvailableBytes;
stub int GetNumaAvailableMemoryNodeEx -> utype int Node, @longlong AvailableBytes;
stub int GetNumaHighestNodeNumber -> @int HighestNodeNumber;
stub int GetNumaNodeNumberFromHandle -> @void hFile, @int NodeNumber;
stub int GetNumaNodeProcessorMask -> utype char Node, @longlong ProcessorMask;
stub int GetNumaNodeProcessorMaskEx -> utype int Node, @void ProcessorMask;
stub int GetNumaProcessorNode -> utype char Processor, @char NodeNumber;
stub int GetNumaProcessorNodeEx -> @void Processor, @int NodeNumber;
stub int GetNumaProximityNode -> utype int ProximityId, @char NodeNumber;
stub int GetNumaProximityNodeEx -> utype int ProximityId, @int NodeNumber;
stub int GetNumberFormatA -> utype int Locale, utype int dwFlags, str lpValue, @void lpFormat, str lpNumberStr, int cchNumber;
stub int GetNumberFormatEx -> @void lpLocaleName, utype int dwFlags, @void lpValue, @void lpFormat, @void lpNumberStr, int cchNumber;
stub int GetNumberFormatW -> utype int Locale, utype int dwFlags, @void lpValue, @void lpFormat, @void lpNumberStr, int cchNumber;
stub int GetNumberOfConsoleInputEvents -> @void console_input, @int number_of_events;
stub int GetNumberOfConsoleMouseButtons -> @int number_of_mouse_buttons;
stub utype int GetOEMCP;
stub int GetOverlappedResult -> @void hFile, @void lpOverlapped, @int lpNumberOfBytesTransferred, int bWait;
stub int GetOverlappedResultEx -> @void hFile, @void lpOverlapped, @int lpNumberOfBytesTransferred, utype int dwMilliseconds, int bAlertable;
stub int GetPackageFamilyName -> @void hProcess, @int packageFamilyNameLength, @void packageFamilyName;
stub int GetPackageFullName -> @void hProcess, @int packageFullNameLength, @void packageFullName;
stub int GetPackageId -> @void hProcess, @int bufferLength, @char buffer;
stub int GetPackagePath -> @void packageId, utype int reserved, @int pathLength, @void path;
stub int GetPackagePathByFullName -> @void packageFullName, @int pathLength, @void path;
stub int GetPackagesByPackageFamily -> @void packageFamilyName, @int cnt, @void packageFullNames, @int bufferLength, @void buffer;
stub int GetPhysicallyInstalledSystemMemory -> @longlong TotalMemoryInKilobytes;
stub utype int GetPriorityClass -> @void hProcess;
stub utype int GetPrivateProfileIntA -> str lpAppName, str lpKeyName, int nDefault, str lpFileName;
stub utype int GetPrivateProfileIntW -> @void lpAppName, @void lpKeyName, int nDefault, @void lpFileName;
stub utype int GetPrivateProfileSectionA -> str lpAppName, str lpReturnedString, utype int nSize, str lpFileName;
stub utype int GetPrivateProfileSectionNamesA -> str lpszReturnBuffer, utype int nSize, str lpFileName;
stub utype int GetPrivateProfileSectionNamesW -> @void lpszReturnBuffer, utype int nSize, @void lpFileName;
stub utype int GetPrivateProfileSectionW -> @void lpAppName, @void lpReturnedString, utype int nSize, @void lpFileName;
stub utype int GetPrivateProfileStringA -> str lpAppName, str lpKeyName, str lpDefault, str lpReturnedString, utype int nSize, str lpFileName;
stub utype int GetPrivateProfileStringW -> @void lpAppName, @void lpKeyName, @void lpDefault, @void lpReturnedString, utype int nSize, @void lpFileName;
stub int GetPrivateProfileStructA -> str lpszSection, str lpszKey, @void lpStruct, utype int uSizeStruct, str szFile;
stub int GetPrivateProfileStructW -> @void lpszSection, @void lpszKey, @void lpStruct, utype int uSizeStruct, @void szFile;
stub @longlong GetProcAddress -> @void hModule, str lpProcName;
stub int GetProcessAffinityMask -> @void hProcess, @longlong lpProcessAffinityMask, @longlong lpSystemAffinityMask;
stub int GetProcessDEPPolicy -> @void hProcess, @int lpFlags, @int lpPermanent;
stub int GetProcessDefaultCpuSetMasks -> @void Process, @void CpuSetMasks, utype int CpuSetMaskCount, @int RequiredMaskCount;
stub int GetProcessDefaultCpuSets -> @void Process, @int CpuSetIds, utype int CpuSetIdCount, @int RequiredIdCount;
stub int GetProcessGroupAffinity -> @void hProcess, @int GroupCount, @int GroupArray;
stub int GetProcessHandleCount -> @void hProcess, @int pdwHandleCount;
stub @void GetProcessHeap;
stub utype int GetProcessHeaps -> utype int NumberOfHeaps, @void ProcessHeaps;
stub utype int GetProcessId -> @void Process;
stub utype int GetProcessIdOfThread -> @void Thread;
stub int GetProcessIoCounters -> @void hProcess, @void lpIoCounters;
stub int GetProcessPreferredUILanguages -> utype int dwFlags, @int pulNumLanguages, @void pwszLanguagesBuffer, @int pcchLanguagesBuffer;
stub int GetProcessPriorityBoost -> @void hProcess, @int pDisablePriorityBoost;
stub int GetProcessShutdownParameters -> @int lpdwLevel, @int lpdwFlags;
stub int GetProcessTimes -> @void hProcess, @void lpCreationTime, @void lpExitTime, @void lpKernelTime, @void lpUserTime;
stub utype int GetProcessVersion -> utype int ProcessId;
stub int GetProcessWorkingSetSize -> @void hProcess, @longlong lpMinimumWorkingSetSize, @longlong lpMaximumWorkingSetSize;
stub int GetProcessWorkingSetSizeEx -> @void hProcess, @longlong lpMinimumWorkingSetSize, @longlong lpMaximumWorkingSetSize, @int Flags;
stub int GetProcessorSystemCycleTime -> utype int Group, @void Buffer, @int ReturnedLength;
stub int GetProductInfo -> utype int dwOSMajorVersion, utype int dwOSMinorVersion, utype int dwSpMajorVersion, utype int dwSpMinorVersion, @int pdwReturnedProductType;
stub utype int GetProfileIntA -> str lpAppName, str lpKeyName, int nDefault;
stub utype int GetProfileIntW -> @void lpAppName, @void lpKeyName, int nDefault;
stub utype int GetProfileSectionA -> str lpAppName, str lpReturnedString, utype int nSize;
stub utype int GetProfileSectionW -> @void lpAppName, @void lpReturnedString, utype int nSize;
stub utype int GetProfileStringA -> str lpAppName, str lpKeyName, str lpDefault, str lpReturnedString, utype int nSize;
stub utype int GetProfileStringW -> @void lpAppName, @void lpKeyName, @void lpDefault, @void lpReturnedString, utype int nSize;
stub int GetQueuedCompletionStatus -> @void CompletionPort, @int lpNumberOfBytesTransferred, @longlong lpCompletionKey, @void lpOverlapped, utype int dwMilliseconds;
stub int GetQueuedCompletionStatusEx -> @void CompletionPort, @void lpCompletionPortEntries, utype int ulCount, @int ulNumEntriesRemoved, utype int dwMilliseconds, int fAlertable;
stub utype int GetShortPathNameA -> str lpszLongPath, str lpszShortPath, utype int cchBuffer;
stub utype int GetShortPathNameW -> @void lpszLongPath, @void lpszShortPath, utype int cchBuffer;
stub int GetStagedPackagePathByFullName -> @void packageFullName, @int pathLength, @void path;
stub void GetStartupInfoA -> @void lpStartupInfo;
stub void GetStartupInfoW -> @void lpStartupInfo;
stub @void GetStdHandle -> utype int nStdHandle;
stub int GetStringScripts -> utype int dwFlags, @void lpString, int cchString, @void lpScripts, int cchScripts;
stub int GetStringTypeA -> utype int Locale, utype int dwInfoType, str lpSrcStr, int cchSrc, @int lpCharType;
stub int GetStringTypeExA -> utype int Locale, utype int dwInfoType, str lpSrcStr, int cchSrc, @int lpCharType;
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
stub int GetSystemPowerStatus -> @void lpSystemPowerStatus;
stub int GetSystemPreferredUILanguages -> utype int dwFlags, @int pulNumLanguages, @void pwszLanguagesBuffer, @int pcchLanguagesBuffer;
stub int GetSystemRegistryQuota -> @int pdwQuotaAllowed, @int pdwQuotaUsed;
stub void GetSystemTime -> @void lpSystemTime;
stub int GetSystemTimeAdjustment -> @int lpTimeAdjustment, @int lpTimeIncrement, @int lpTimeAdjustmentDisabled;
stub void GetSystemTimeAsFileTime -> @void lpSystemTimeAsFileTime;
stub void GetSystemTimePreciseAsFileTime -> @void lpSystemTimeAsFileTime;
stub int GetSystemTimes -> @void lpIdleTime, @void lpKernelTime, @void lpUserTime;
stub utype int GetSystemWindowsDirectoryA -> str lpBuffer, utype int uSize;
stub utype int GetSystemWindowsDirectoryW -> @void lpBuffer, utype int uSize;
stub utype int GetSystemWow64DirectoryA -> str lpBuffer, utype int uSize;
stub utype int GetSystemWow64DirectoryW -> @void lpBuffer, utype int uSize;
stub utype int GetTapeParameters -> @void hDevice, utype int dwOperation, @int lpdwSize, @void lpTapeInformation;
stub utype int GetTapePosition -> @void hDevice, utype int dwPositionType, @int lpdwPartition, @int lpdwOffsetLow, @int lpdwOffsetHigh;
stub utype int GetTapeStatus -> @void hDevice;
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
stub int GetThreadSelectorEntry -> @void hThread, utype int dwSelector, @void lpSelectorEntry;
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
stub int GetUmsCompletionListEvent -> @void UmsCompletionList, @void UmsCompletionEvent;
stub int GetUmsSystemThreadInformation -> @void ThreadHandle, @void SystemThreadInfo;
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
stub int GetVolumeNameForVolumeMountPointA -> str lpszVolumeMountPoint, str lpszVolumeName, utype int cchBufferLength;
stub int GetVolumeNameForVolumeMountPointW -> @void lpszVolumeMountPoint, @void lpszVolumeName, utype int cchBufferLength;
stub int GetVolumePathNameA -> str lpszFileName, str lpszVolumePathName, utype int cchBufferLength;
stub int GetVolumePathNameW -> @void lpszFileName, @void lpszVolumePathName, utype int cchBufferLength;
stub int GetVolumePathNamesForVolumeNameA -> str lpszVolumeName, str lpszVolumePathNames, utype int cchBufferLength, @int lpcchReturnLength;
stub int GetVolumePathNamesForVolumeNameW -> @void lpszVolumeName, @void lpszVolumePathNames, utype int cchBufferLength, @int lpcchReturnLength;
stub utype int GetWindowsDirectoryA -> str lpBuffer, utype int uSize;
stub utype int GetWindowsDirectoryW -> @void lpBuffer, utype int uSize;
stub utype int GetWriteWatch -> utype int dwFlags, @void lpBaseAddress, utype longlong dwRegionSize, @void lpAddresses, @longlong lpdwCount, @int lpdwGranularity;
stub int GetXStateFeaturesMask -> @void Context, @longlong FeatureMask;
stub utype int GlobalAddAtomA -> str lpString;
stub utype int GlobalAddAtomExA -> str lpString, utype int Flags;
stub utype int GlobalAddAtomExW -> @void lpString, utype int Flags;
stub utype int GlobalAddAtomW -> @void lpString;
stub @void GlobalAlloc -> utype int uFlags, utype longlong dwBytes;
stub utype longlong GlobalCompact -> utype int dwMinFree;
stub utype int GlobalDeleteAtom -> utype int nAtom;
stub utype int GlobalFindAtomA -> str lpString;
stub utype int GlobalFindAtomW -> @void lpString;
stub void GlobalFix -> @void w;
stub utype int GlobalFlags -> @void hMem;
stub @void GlobalFree -> @void hMem;
stub utype int GlobalGetAtomNameA -> utype int nAtom, str lpBuffer, int nSize;
stub utype int GlobalGetAtomNameW -> utype int nAtom, @void lpBuffer, int nSize;
stub @void GlobalHandle -> @void pMem;
stub @void GlobalLock -> @void hMem;
stub void GlobalMemoryStatus -> @void lpBuffer;
stub int GlobalMemoryStatusEx -> @void lpBuffer;
stub @void GlobalReAlloc -> @void hMem, utype longlong dwBytes, utype int uFlags;
stub utype longlong GlobalSize -> @void hMem;
stub int GlobalUnWire -> @void hMem;
stub void GlobalUnfix -> @void w;
stub int GlobalUnlock -> @void hMem;
stub @void GlobalWire -> @void hMem;
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
stub int InitAtomTable -> utype int nSize;
stub int InitOnceBeginInitialize -> @void lpInitOnce, utype int dwFlags, @int fPending, @void lpContext;
stub int InitOnceComplete -> @void lpInitOnce, utype int dwFlags, @void lpContext;
stub int InitOnceExecuteOnce -> @void InitOnce, @func InitFn, @void Parameter, @void Context;
stub void InitOnceInitialize -> @void InitOnce;
stub void InitializeConditionVariable -> @void ConditionVariable;
stub int InitializeContext -> @void Buffer, utype int ContextFlags, @void Context, @int ContextLength;
stub int InitializeContext2 -> @void Buffer, utype int ContextFlags, @void Context, @int ContextLength, utype longlong XStateCompactionMask;
stub void InitializeCriticalSection -> @void lpCriticalSection;
stub int InitializeCriticalSectionAndSpinCount -> @void lpCriticalSection, utype int dwSpinCount;
stub int InitializeCriticalSectionEx -> @void lpCriticalSection, utype int dwSpinCount, utype int Flags;
stub int InitializeProcThreadAttributeList -> @void lpAttributeList, utype int dwAttributeCount, utype int dwFlags, @longlong lpSize;
stub void InitializeSListHead -> @void ListHead;
stub void InitializeSRWLock -> @void SRWLock;
stub int InitializeSynchronizationBarrier -> @void lpBarrier, int lTotalThreads, int lSpinCount;
stub @void InterlockedFlushSList -> @void ListHead;
stub @void InterlockedPopEntrySList -> @void ListHead;
stub @void InterlockedPushEntrySList -> @void ListHead, @void ListEntry;
stub @void InterlockedPushListSListEx -> @void ListHead, @void List, @void ListEnd, utype int Count;
stub int IsBadCodePtr -> @func lpfn;
stub int IsBadHugeReadPtr -> @void lp, utype longlong ucb;
stub int IsBadHugeWritePtr -> @void lp, utype longlong ucb;
stub int IsBadReadPtr -> @void lp, utype longlong ucb;
stub int IsBadStringPtrA -> str lpsz, utype longlong ucchMax;
stub int IsBadStringPtrW -> @void lpsz, utype longlong ucchMax;
stub int IsBadWritePtr -> @void lp, utype longlong ucb;
stub int IsDBCSLeadByte -> utype char TestChar;
stub int IsDBCSLeadByteEx -> utype int CodePage, utype char TestChar;
stub int IsDebuggerPresent;
stub int IsNLSDefinedString -> utype int Function, utype int dwFlags, @void lpVersionInformation, @void lpString, int cchStr;
stub int IsNativeVhdBoot -> @int NativeVhdBoot;
stub int IsProcessInJob -> @void ProcessHandle, @void JobHandle, @int Result;
stub int IsProcessorFeaturePresent -> utype int ProcessorFeature;
stub int IsSystemResumeAutomatic;
stub int IsThreadAFiber;
stub int IsThreadpoolTimerSet -> @void pti;
stub int IsValidCodePage -> utype int CodePage;
stub int IsValidLanguageGroup -> utype int LanguageGroup, utype int dwFlags;
stub int IsValidLocale -> utype int Locale, utype int dwFlags;
stub int IsValidLocaleName -> @void lpLocaleName;
stub utype int IsValidNLSVersion -> utype int function, @void lpLocaleName, @void lpVersionInformation;
stub int IsWow64GuestMachineSupported -> utype int WowGuestMachine, @int MachineIsSupported;
stub int IsWow64Process -> @void hProcess, @int Wow64Process;
stub int IsWow64Process2 -> @void hProcess, @int pProcessMachine, @int pNativeMachine;
stub int LCIDToLocaleName -> utype int Locale, @void lpName, int cchName, utype int dwFlags;
stub int LCMapStringA -> utype int Locale, utype int dwMapFlags, str lpSrcStr, int cchSrc, str lpDestStr, int cchDest;
stub int LCMapStringEx -> @void lpLocaleName, utype int dwMapFlags, @void lpSrcStr, int cchSrc, @void lpDestStr, int cchDest, @void lpVersionInformation, @void lpReserved, longlong sortHandle;
stub int LCMapStringW -> utype int Locale, utype int dwMapFlags, @void lpSrcStr, int cchSrc, @void lpDestStr, int cchDest;
stub void LZClose -> int a1;
stub int LZCopy -> int a1, int a2;
stub void LZDone;
stub int LZInit -> int a1;
stub int LZOpenFileA -> str a1, @void a2, utype int a3;
stub int LZOpenFileW -> @void a1, @void a2, utype int a3;
stub int LZRead -> int a1, str a2, int a3;
stub int LZSeek -> int a1, int a2, int a3;
stub int LZStart;
stub void LeaveCriticalSection -> @void lpCriticalSection;
stub void LeaveCriticalSectionWhenCallbackReturns -> @void pci, @void pcs;
stub @void LoadLibraryA -> str lpLibFileName;
stub @void LoadLibraryExA -> str lpLibFileName, @void hFile, utype int dwFlags;
stub @void LoadLibraryExW -> @void lpLibFileName, @void hFile, utype int dwFlags;
stub @void LoadLibraryW -> @void lpLibFileName;
stub utype int LoadModule -> str lpModuleName, @void lpParameterBlock;
stub @void LoadPackagedLibrary -> @void lpwLibFileName, utype int Reserved;
stub @void LoadResource -> @void hModule, @void hResInfo;
stub @void LocalAlloc -> utype int uFlags, utype longlong uBytes;
stub utype longlong LocalCompact -> utype int uMinFree;
stub int LocalFileTimeToFileTime -> @void lpLocalFileTime, @void lpFileTime;
stub utype int LocalFlags -> @void hMem;
stub @void LocalFree -> @void hMem;
stub @void LocalHandle -> @void pMem;
stub @void LocalLock -> @void hMem;
stub @void LocalReAlloc -> @void hMem, utype longlong uBytes, utype int uFlags;
stub utype longlong LocalShrink -> @void hMem, utype int cbNewSize;
stub utype longlong LocalSize -> @void hMem;
stub int LocalUnlock -> @void hMem;
stub utype int LocaleNameToLCID -> @void lpName, utype int dwFlags;
stub @void LocateXStateFeature -> @void Context, utype int FeatureId, @int Length;
stub int LockFile -> @void hFile, utype int dwFileOffsetLow, utype int dwFileOffsetHigh, utype int nNumberOfBytesToLockLow, utype int nNumberOfBytesToLockHigh;
stub int LockFileEx -> @void hFile, utype int dwFlags, utype int dwReserved, utype int nNumberOfBytesToLockLow, utype int nNumberOfBytesToLockHigh, @void lpOverlapped;
stub @void LockResource -> @void hResData;
stub int MapUserPhysicalPages -> @void VirtualAddress, utype longlong NumberOfPages, @longlong PageArray;
stub int MapUserPhysicalPagesScatter -> @void VirtualAddresses, utype longlong NumberOfPages, @longlong PageArray;
stub @void MapViewOfFile -> @void hFileMappingObject, utype int dwDesiredAccess, utype int dwFileOffsetHigh, utype int dwFileOffsetLow, utype longlong dwNumberOfBytesToMap;
stub @void MapViewOfFileEx -> @void hFileMappingObject, utype int dwDesiredAccess, utype int dwFileOffsetHigh, utype int dwFileOffsetLow, utype longlong dwNumberOfBytesToMap, @void lpBaseAddress;
stub @void MapViewOfFileExNuma -> @void hFileMappingObject, utype int dwDesiredAccess, utype int dwFileOffsetHigh, utype int dwFileOffsetLow, utype longlong dwNumberOfBytesToMap, @void lpBaseAddress, utype int nndPreferred;
stub @void MapViewOfFileFromApp -> @void hFileMappingObject, utype int DesiredAccess, utype longlong FileOffset, utype longlong NumberOfBytesToMap;
stub int MoveFileA -> str lpExistingFileName, str lpNewFileName;
stub int MoveFileExA -> str lpExistingFileName, str lpNewFileName, utype int dwFlags;
stub int MoveFileExW -> @void lpExistingFileName, @void lpNewFileName, utype int dwFlags;
stub int MoveFileTransactedA -> str lpExistingFileName, str lpNewFileName, @func lpProgressRoutine, @void lpData, utype int dwFlags, @void hTransaction;
stub int MoveFileTransactedW -> @void lpExistingFileName, @void lpNewFileName, @func lpProgressRoutine, @void lpData, utype int dwFlags, @void hTransaction;
stub int MoveFileW -> @void lpExistingFileName, @void lpNewFileName;
stub int MoveFileWithProgressA -> str lpExistingFileName, str lpNewFileName, @func lpProgressRoutine, @void lpData, utype int dwFlags;
stub int MoveFileWithProgressW -> @void lpExistingFileName, @void lpNewFileName, @func lpProgressRoutine, @void lpData, utype int dwFlags;
stub int MulDiv -> int nNumber, int nNumerator, int nDenominator;
stub int MultiByteToWideChar -> utype int CodePage, utype int dwFlags, str lpMultiByteStr, int cbMultiByte, @void lpWideCharStr, int cchWideChar;
stub int NeedCurrentDirectoryForExePathA -> str ExeName;
stub int NeedCurrentDirectoryForExePathW -> @void ExeName;
stub int NotifyUILanguageChange -> utype int dwFlags, @void pcwstrNewLanguage, @void pcwstrPreviousLanguage, utype int dwReserved, @int pdwStatusRtrn;
stub @void OpenEventA -> utype int dwDesiredAccess, int bInheritHandle, str lpName;
stub @void OpenEventW -> utype int dwDesiredAccess, int bInheritHandle, @void lpName;
stub int OpenFile -> str lpFileName, @void lpReOpenBuff, utype int uStyle;
stub @void OpenFileById -> @void hVolumeHint, @void lpFileId, utype int dwDesiredAccess, utype int dwShareMode, @void lpSecurityAttributes, utype int dwFlagsAndAttributes;
stub @void OpenFileMappingA -> utype int dwDesiredAccess, int bInheritHandle, str lpName;
stub @void OpenFileMappingW -> utype int dwDesiredAccess, int bInheritHandle, @void lpName;
stub @void OpenJobObjectA -> utype int dwDesiredAccess, int bInheritHandle, str lpName;
stub @void OpenJobObjectW -> utype int dwDesiredAccess, int bInheritHandle, @void lpName;
stub @void OpenMutexA -> utype int dwDesiredAccess, int bInheritHandle, str lpName;
stub @void OpenMutexW -> utype int dwDesiredAccess, int bInheritHandle, @void lpName;
stub int OpenPackageInfoByFullName -> @void packageFullName, utype int reserved, @void packageInfoReference;
stub @void OpenPrivateNamespaceA -> @void lpBoundaryDescriptor, str lpAliasPrefix;
stub @void OpenPrivateNamespaceW -> @void lpBoundaryDescriptor, @void lpAliasPrefix;
stub @void OpenProcess -> utype int dwDesiredAccess, int bInheritHandle, utype int dwProcessId;
stub int OpenProcessToken -> @void ProcessHandle, utype int DesiredAccess, @void TokenHandle;
stub @void OpenSemaphoreA -> utype int dwDesiredAccess, int bInheritHandle, str lpName;
stub @void OpenSemaphoreW -> utype int dwDesiredAccess, int bInheritHandle, @void lpName;
stub @void OpenThread -> utype int dwDesiredAccess, int bInheritHandle, utype int dwThreadId;
stub int OpenThreadToken -> @void ThreadHandle, utype int DesiredAccess, int OpenAsSelf, @void TokenHandle;
stub @void OpenWaitableTimerA -> utype int dwDesiredAccess, int bInheritHandle, str lpTimerName;
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
stub @void PowerCreateRequest -> @void Context;
stub int PrefetchVirtualMemory -> @void hProcess, utype longlong NumberOfEntries, @void VirtualAddresses, utype int Flags;
stub utype int PrepareTape -> @void hDevice, utype int dwOperation, int bImmediate;
stub int ProcessIdToSessionId -> utype int dwProcessId, @int pSessionId;
stub int PulseEvent -> @void hEvent;
stub int PurgeComm -> @void hFile, utype int dwFlags;
stub int QueryActCtxSettingsW -> utype int dwFlags, @void hActCtx, @void settingsNameSpace, @void settingName, @void pvBuffer, utype longlong dwBuffer, @longlong pdwWrittenOrRequired;
stub int QueryActCtxW -> utype int dwFlags, @void hActCtx, @void pvSubInstance, utype int ulInfoClass, @void pvBuffer, utype longlong cbBuffer, @longlong pcbWrittenOrRequired;
stub utype int QueryDepthSList -> @void ListHead;
stub utype int QueryDosDeviceA -> str lpDeviceName, str lpTargetPath, utype int ucchMax;
stub utype int QueryDosDeviceW -> @void lpDeviceName, @void lpTargetPath, utype int ucchMax;
stub int QueryFullProcessImageNameA -> @void hProcess, utype int dwFlags, str lpExeName, @int lpdwSize;
stub int QueryFullProcessImageNameW -> @void hProcess, utype int dwFlags, @void lpExeName, @int lpdwSize;
stub int QueryIdleProcessorCycleTime -> @int BufferLength, @longlong ProcessorIdleCycleTime;
stub int QueryIdleProcessorCycleTimeEx -> utype int Group, @int BufferLength, @longlong ProcessorIdleCycleTime;
stub int QueryMemoryResourceNotification -> @void ResourceNotificationHandle, @int ResourceState;
stub int QueryPerformanceCounter -> @longlong lpPerformanceCount;
stub int QueryPerformanceFrequency -> @longlong lpFrequency;
stub int QueryProcessAffinityUpdateMode -> @void hProcess, @int lpdwFlags;
stub int QueryProcessCycleTime -> @void ProcessHandle, @longlong CycleTime;
stub int QueryProtectedPolicy -> @void PolicyGuid, @longlong PolicyValue;
stub int QueryThreadCycleTime -> @void ThreadHandle, @longlong CycleTime;
stub utype int QueryThreadProfiling -> @void ThreadHandle, @char Enabled;
stub int QueryThreadpoolStackInformation -> @void ptpp, @void ptpsi;
stub int QueryUnbiasedInterruptTime -> @longlong UnbiasedTime;
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
stub utype int ReadThreadProfilingData -> @void PerformanceDataHandle, utype int Flags, @void PerformanceData;
stub utype int ReclaimVirtualMemory -> @void VirtualAddress, utype longlong Size;
stub int RegCloseKey -> @void hKey;
stub int RegCopyTreeW -> @void hKeySrc, @void lpSubKey, @void hKeyDest;
stub int RegCreateKeyExA -> @void hKey, str lpSubKey, utype int Reserved, str lpClass, utype int dwOptions, utype int samDesired, @void lpSecurityAttributes, @void phkResult, @int lpdwDisposition;
stub int RegCreateKeyExW -> @void hKey, @void lpSubKey, utype int Reserved, @void lpClass, utype int dwOptions, utype int samDesired, @void lpSecurityAttributes, @void phkResult, @int lpdwDisposition;
stub int RegDeleteKeyExA -> @void hKey, str lpSubKey, utype int samDesired, utype int Reserved;
stub int RegDeleteKeyExW -> @void hKey, @void lpSubKey, utype int samDesired, utype int Reserved;
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
stub int RegQueryValueExA -> @void hKey, str lpValueName, @int lpReserved, @int lpType, @char lpData, @int lpcbData;
stub int RegQueryValueExW -> @void hKey, @void lpValueName, @int lpReserved, @int lpType, @char lpData, @int lpcbData;
stub int RegRestoreKeyA -> @void hKey, str lpFile, utype int dwFlags;
stub int RegRestoreKeyW -> @void hKey, @void lpFile, utype int dwFlags;
stub int RegSaveKeyExA -> @void hKey, str lpFile, @void lpSecurityAttributes, utype int Flags;
stub int RegSaveKeyExW -> @void hKey, @void lpFile, @void lpSecurityAttributes, utype int Flags;
stub int RegSetKeySecurity -> @void hKey, utype int SecurityInformation, @void pSecurityDescriptor;
stub int RegSetValueExA -> @void hKey, str lpValueName, utype int Reserved, utype int dwType, @char lpData, utype int cbData;
stub int RegSetValueExW -> @void hKey, @void lpValueName, utype int Reserved, utype int dwType, @char lpData, utype int cbData;
stub int RegUnLoadKeyA -> @void hKey, str lpSubKey;
stub int RegUnLoadKeyW -> @void hKey, @void lpSubKey;
stub int RegisterApplicationRecoveryCallback -> @func pRecoveyCallback, @void pvParameter, utype int dwPingInterval, utype int dwFlags;
stub int RegisterApplicationRestart -> @void pwzCommandline, utype int dwFlags;
stub @void RegisterBadMemoryNotification -> @func Callback;
stub int RegisterWaitForSingleObject -> @void phNewWaitObject, @void hObject, @func Callback, @void Context, utype int dwMilliseconds, utype int dwFlags;
stub void ReleaseActCtx -> @void hActCtx;
stub int ReleaseMutex -> @void hMutex;
stub void ReleaseMutexWhenCallbackReturns -> @void pci, @void mut;
stub void ReleaseSRWLockExclusive -> @void SRWLock;
stub void ReleaseSRWLockShared -> @void SRWLock;
stub int ReleaseSemaphore -> @void hSemaphore, int lReleaseCount, @int lpPreviousCount;
stub void ReleaseSemaphoreWhenCallbackReturns -> @void pci, @void sem, utype int crel;
stub int RemoveDirectoryA -> str lpPathName;
stub int RemoveDirectoryTransactedA -> str lpPathName, @void hTransaction;
stub int RemoveDirectoryTransactedW -> @void lpPathName, @void hTransaction;
stub int RemoveDirectoryW -> @void lpPathName;
stub int RemoveDllDirectory -> @void Cookie;
stub int RemoveSecureMemoryCacheCallback -> @func pfnCallBack;
stub utype int RemoveVectoredContinueHandler -> @void Handle;
stub utype int RemoveVectoredExceptionHandler -> @void Handle;
stub int ReplaceFileA -> str lpReplacedFileName, str lpReplacementFileName, str lpBackupFileName, utype int dwReplaceFlags, @void lpExclude, @void lpReserved;
stub int ReplaceFileW -> @void lpReplacedFileName, @void lpReplacementFileName, @void lpBackupFileName, utype int dwReplaceFlags, @void lpExclude, @void lpReserved;
stub int ReplacePartitionUnit -> @void TargetPartition, @void SparePartition, utype int Flags;
stub int RequestDeviceWakeup -> @void hDevice;
stub int ResetEvent -> @void hEvent;
stub utype int ResetWriteWatch -> @void lpBaseAddress, utype longlong dwRegionSize;
stub int ResolveLocaleName -> @void lpNameToResolve, @void lpLocaleName, int cchLocaleName;
stub utype int ResumeThread -> @void hThread;
stub utype char RtlAddFunctionTable -> @void FunctionTable, utype int EntryCount, utype longlong BaseAddress;
stub void RtlCaptureContext -> @void ContextRecord;
stub utype int RtlCaptureStackBackTrace -> utype int FramesToSkip, utype int FramesToCapture, @void BackTrace, @int BackTraceHash;
stub utype longlong RtlCompareMemory -> @void Source1, @void Source2, utype longlong Length;
stub utype char RtlDeleteFunctionTable -> @void FunctionTable;
stub utype char RtlInstallFunctionTableCallback -> utype longlong TableIdentifier, utype longlong BaseAddress, utype int Length, @func TargetGp, @void Callback, @void Context;
stub utype char RtlIsEcCode -> utype longlong CodePointer;
stub @void RtlLookupFunctionEntry -> utype longlong ControlPc, @longlong ImageBase, @void HistoryTable;
stub @void RtlPcToFileHeader -> @void PcValue, @void BaseOfImage;
stub void RtlRestoreContext -> @void ContextRecord, @void ExceptionRecord;
stub void RtlUnwind -> @void TargetFrame, @void TargetIp, @void ExceptionRecord, @void ReturnValue;
stub void RtlUnwindEx -> @void TargetFrame, @void TargetIp, @void ExceptionRecord, @void ReturnValue, @void ContextRecord, @void HistoryTable;
stub @void RtlVirtualUnwind -> utype int HandlerType, utype longlong ImageBase, utype longlong ControlPc, @void FunctionEntry, @void ContextRecord, @void HandlerData, @longlong EstablisherFrame, @void ContextPointers;
stub utype int SearchPathA -> str lpPath, str lpFileName, str lpExtension, utype int nBufferLength, str lpBuffer, @void lpFilePart;
stub utype int SearchPathW -> @void lpPath, @void lpFileName, @void lpExtension, utype int nBufferLength, @void lpBuffer, @void lpFilePart;
stub int SetCachedSigningLevel -> @void SourceFiles, utype int SourceFileCount, utype int Flags, @void TargetFile;
stub int SetCalendarInfoA -> utype int Locale, utype int Calendar, utype int CalType, str lpCalData;
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
stub int SetDefaultCommConfigA -> str lpszName, @void lpCC, utype int dwSize;
stub int SetDefaultCommConfigW -> @void lpszName, @void lpCC, utype int dwSize;
stub int SetDefaultDllDirectories -> utype int DirectoryFlags;
stub int SetDllDirectoryA -> str lpPathName;
stub int SetDllDirectoryW -> @void lpPathName;
stub int SetDynamicTimeZoneInformation -> @void lpTimeZoneInformation;
stub int SetEndOfFile -> @void hFile;
stub int SetEnvironmentStringsA -> str NewEnvironment;
stub int SetEnvironmentStringsW -> @void NewEnvironment;
stub int SetEnvironmentVariableA -> str lpName, str lpValue;
stub int SetEnvironmentVariableW -> @void lpName, @void lpValue;
stub utype int SetErrorMode -> utype int uMode;
stub int SetEvent -> @void hEvent;
stub void SetEventWhenCallbackReturns -> @void pci, @void evt;
stub void SetFileApisToANSI;
stub void SetFileApisToOEM;
stub int SetFileAttributesA -> str lpFileName, utype int dwFileAttributes;
stub int SetFileAttributesTransactedA -> str lpFileName, utype int dwFileAttributes, @void hTransaction;
stub int SetFileAttributesTransactedW -> @void lpFileName, utype int dwFileAttributes, @void hTransaction;
stub int SetFileAttributesW -> @void lpFileName, utype int dwFileAttributes;
stub int SetFileBandwidthReservation -> @void hFile, utype int nPeriodMilliseconds, utype int nBytesPerPeriod, int bDiscardable, @int lpTransferSize, @int lpNumOutstandingRequests;
stub int SetFileCompletionNotificationModes -> @void FileHandle, utype char Flags;
stub int SetFileIoOverlappedRange -> @void FileHandle, @char OverlappedRangeStart, utype int Length;
stub utype int SetFilePointer -> @void hFile, int lDistanceToMove, @int lpDistanceToMoveHigh, utype int dwMoveMethod;
stub int SetFilePointerEx -> @void hFile, longlong liDistanceToMove, @longlong lpNewFilePointer, utype int dwMoveMethod;
stub int SetFileShortNameA -> @void hFile, str lpShortName;
stub int SetFileShortNameW -> @void hFile, @void lpShortName;
stub int SetFileTime -> @void hFile, @void lpCreationTime, @void lpLastAccessTime, @void lpLastWriteTime;
stub int SetFileValidData -> @void hFile, longlong ValidDataLength;
stub int SetFirmwareEnvironmentVariableA -> str lpName, str lpGuid, @void pValue, utype int nSize;
stub int SetFirmwareEnvironmentVariableExA -> str lpName, str lpGuid, @void pValue, utype int nSize, utype int dwAttributes;
stub int SetFirmwareEnvironmentVariableExW -> @void lpName, @void lpGuid, @void pValue, utype int nSize, utype int dwAttributes;
stub int SetFirmwareEnvironmentVariableW -> @void lpName, @void lpGuid, @void pValue, utype int nSize;
stub utype int SetHandleCount -> utype int uNumber;
stub int SetHandleInformation -> @void hObject, utype int dwMask, utype int dwFlags;
stub void SetLastError -> utype int dwErrCode;
stub int SetLocalTime -> @void lpSystemTime;
stub int SetLocaleInfoA -> utype int Locale, utype int LCType, str lpLCData;
stub int SetLocaleInfoW -> utype int Locale, utype int LCType, @void lpLCData;
stub int SetMailslotInfo -> @void hMailslot, utype int lReadTimeout;
stub int SetMessageWaitingIndicator -> @void hMsgIndicator, utype int ulMsgCount;
stub int SetNamedPipeHandleState -> @void hNamedPipe, @int lpMode, @int lpMaxCollectionCount, @int lpCollectDataTimeout;
stub int SetPriorityClass -> @void hProcess, utype int dwPriorityClass;
stub int SetProcessAffinityMask -> @void hProcess, utype longlong dwProcessAffinityMask;
stub int SetProcessAffinityUpdateMode -> @void hProcess, utype int dwFlags;
stub int SetProcessDEPPolicy -> utype int dwFlags;
stub int SetProcessDefaultCpuSetMasks -> @void Process, @void CpuSetMasks, utype int CpuSetMaskCount;
stub int SetProcessDefaultCpuSets -> @void Process, @int CpuSetIds, utype int CpuSetIdCount;
stub int SetProcessPreferredUILanguages -> utype int dwFlags, @void pwszLanguagesBuffer, @int pulNumLanguages;
stub int SetProcessPriorityBoost -> @void hProcess, int bDisablePriorityBoost;
stub int SetProcessShutdownParameters -> utype int dwLevel, utype int dwFlags;
stub int SetProcessWorkingSetSize -> @void hProcess, utype longlong dwMinimumWorkingSetSize, utype longlong dwMaximumWorkingSetSize;
stub int SetProcessWorkingSetSizeEx -> @void hProcess, utype longlong dwMinimumWorkingSetSize, utype longlong dwMaximumWorkingSetSize, utype int Flags;
stub int SetProtectedPolicy -> @void PolicyGuid, utype longlong PolicyValue, @longlong OldPolicyValue;
stub int SetSearchPathMode -> utype int Flags;
stub int SetStdHandle -> utype int nStdHandle, @void hHandle;
stub int SetStdHandleEx -> utype int nStdHandle, @void hHandle, @void phPrevValue;
stub int SetSystemFileCacheSize -> utype longlong MinimumFileCacheSize, utype longlong MaximumFileCacheSize, utype int Flags;
stub int SetSystemPowerState -> int fSuspend, int fForce;
stub int SetSystemTime -> @void lpSystemTime;
stub int SetSystemTimeAdjustment -> utype int dwTimeAdjustment, int bTimeAdjustmentDisabled;
stub utype int SetTapeParameters -> @void hDevice, utype int dwOperation, @void lpTapeInformation;
stub utype int SetTapePosition -> @void hDevice, utype int dwPositionMethod, utype int dwPartition, utype int dwOffsetLow, utype int dwOffsetHigh, int bImmediate;
stub utype longlong SetThreadAffinityMask -> @void hThread, utype longlong dwThreadAffinityMask;
stub int SetThreadContext -> @void hThread, @void lpContext;
stub int SetThreadDescription -> @void hThread, @void lpThreadDescription;
stub int SetThreadErrorMode -> utype int dwNewMode, @int lpOldMode;
stub utype int SetThreadExecutionState -> utype int esFlags;
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
stub @void SetTimerQueueTimer -> @void TimerQueue, @func Callback, @void Parameter, utype int DueTime, utype int Period, int PreferIo;
stub @void SetUnhandledExceptionFilter -> @func lpTopLevelExceptionFilter;
stub int SetUserGeoID -> int GeoId;
stub int SetUserGeoName -> @void geoName;
stub int SetVolumeLabelA -> str lpRootPathName, str lpVolumeName;
stub int SetVolumeLabelW -> @void lpRootPathName, @void lpVolumeName;
stub int SetVolumeMountPointA -> str lpszVolumeMountPoint, str lpszVolumeName;
stub int SetVolumeMountPointW -> @void lpszVolumeMountPoint, @void lpszVolumeName;
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
stub int TerminateJobObject -> @void hJob, utype int uExitCode;
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
stub int UmsThreadYield -> @void SchedulerParam;
stub int UnhandledExceptionFilter -> @void ExceptionInfo;
stub int UnlockFile -> @void hFile, utype int dwFileOffsetLow, utype int dwFileOffsetHigh, utype int nNumberOfBytesToUnlockLow, utype int nNumberOfBytesToUnlockHigh;
stub int UnlockFileEx -> @void hFile, utype int dwReserved, utype int nNumberOfBytesToUnlockLow, utype int nNumberOfBytesToUnlockHigh, @void lpOverlapped;
stub int UnmapViewOfFile -> @void lpBaseAddress;
stub int UnmapViewOfFileEx -> @void BaseAddress, utype int UnmapFlags;
stub int UnregisterApplicationRecoveryCallback;
stub int UnregisterApplicationRestart;
stub int UnregisterBadMemoryNotification -> @void RegistrationHandle;
stub int UnregisterWait -> @void WaitHandle;
stub int UnregisterWaitEx -> @void WaitHandle, @void CompletionEvent;
stub int UpdateProcThreadAttribute -> @void lpAttributeList, utype int dwFlags, utype longlong Attribute, @void lpValue, utype longlong cbSize, @void lpPreviousValue, @longlong lpReturnSize;
stub int UpdateResourceA -> @void hUpdate, str lpType, str lpName, utype int wLanguage, @void lpData, utype int cb;
stub int UpdateResourceW -> @void hUpdate, @void lpType, @void lpName, utype int wLanguage, @void lpData, utype int cb;
stub utype int VerLanguageNameA -> utype int wLang, str szLang, utype int nSize;
stub utype int VerLanguageNameW -> utype int wLang, @void szLang, utype int nSize;
stub utype longlong VerSetConditionMask -> utype longlong ConditionMask, utype int TypeMask, utype char Condition;
stub int VerifyScripts -> utype int dwFlags, @void lpLocaleScripts, int cchLocaleScripts, @void lpTestScripts, int cchTestScripts;
stub int VerifyVersionInfoA -> @void lpVersionInformation, utype int dwTypeMask, utype longlong dwlConditionMask;
stub int VerifyVersionInfoW -> @void lpVersionInformation, utype int dwTypeMask, utype longlong dwlConditionMask;
stub @void VirtualAlloc -> @void lpAddress, utype longlong dwSize, utype int flAllocationType, utype int flProtect;
stub @void VirtualAllocEx -> @void hProcess, @void lpAddress, utype longlong dwSize, utype int flAllocationType, utype int flProtect;
stub @void VirtualAllocExNuma -> @void hProcess, @void lpAddress, utype longlong dwSize, utype int flAllocationType, utype int flProtect, utype int nndPreferred;
stub int VirtualFree -> @void lpAddress, utype longlong dwSize, utype int dwFreeType;
stub int VirtualFreeEx -> @void hProcess, @void lpAddress, utype longlong dwSize, utype int dwFreeType;
stub int VirtualLock -> @void lpAddress, utype longlong dwSize;
stub int VirtualProtect -> @void lpAddress, utype longlong dwSize, utype int flNewProtect, @int lpflOldProtect;
stub int VirtualProtectEx -> @void hProcess, @void lpAddress, utype longlong dwSize, utype int flNewProtect, @int lpflOldProtect;
stub utype longlong VirtualQuery -> @void lpAddress, @void lpBuffer, utype longlong dwLength;
stub utype longlong VirtualQueryEx -> @void hProcess, @void lpAddress, @void lpBuffer, utype longlong dwLength;
stub int VirtualUnlock -> @void lpAddress, utype longlong dwSize;
stub utype int WTSGetActiveConsoleSessionId;
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
stub int WaitNamedPipeA -> str lpNamedPipeName, utype int nTimeOut;
stub int WaitNamedPipeW -> @void lpNamedPipeName, utype int nTimeOut;
stub void WakeAllConditionVariable -> @void ConditionVariable;
stub void WakeConditionVariable -> @void ConditionVariable;
stub int WideCharToMultiByte -> utype int CodePage, utype int dwFlags, @void lpWideCharStr, int cchWideChar, str lpMultiByteStr, int cbMultiByte, str lpDefaultChar, @int lpUsedDefaultChar;
stub utype int WinExec -> str lpCmdLine, utype int uCmdShow;
stub int Wow64DisableWow64FsRedirection -> @void OldValue;
stub utype char Wow64EnableWow64FsRedirection -> utype char Wow64FsEnableRedirection;
stub int Wow64GetThreadContext -> @void hThread, @void lpContext;
stub int Wow64GetThreadSelectorEntry -> @void hThread, utype int dwSelector, @void lpSelectorEntry;
stub int Wow64RevertWow64FsRedirection -> @void OlValue;
stub int Wow64SetThreadContext -> @void hThread, @void lpContext;
stub utype int Wow64SuspendThread -> @void hThread;
stub int WriteConsoleA -> @void console_output, @void buffer, utype int number_of_chars_to_write, @int number_of_chars_written, @void reserved;
stub int WriteConsoleInputA -> @void console_input, @void buffer, utype int length, @int number_of_events_written;
stub int WriteConsoleInputW -> @void console_input, @void buffer, utype int length, @int number_of_events_written;
stub int WriteConsoleW -> @void console_output, @void buffer, utype int number_of_chars_to_write, @int number_of_chars_written, @void reserved;
stub int WriteFile -> @void hFile, @void lpBuffer, utype int nNumberOfBytesToWrite, @int lpNumberOfBytesWritten, @void lpOverlapped;
stub int WriteFileEx -> @void hFile, @void lpBuffer, utype int nNumberOfBytesToWrite, @void lpOverlapped, @func lpCompletionRoutine;
stub int WriteFileGather -> @void hFile, @void aSegmentArray, utype int nNumberOfBytesToWrite, @int lpReserved, @void lpOverlapped;
stub int WritePrivateProfileSectionA -> str lpAppName, str lpString, str lpFileName;
stub int WritePrivateProfileSectionW -> @void lpAppName, @void lpString, @void lpFileName;
stub int WritePrivateProfileStringA -> str lpAppName, str lpKeyName, str lpString, str lpFileName;
stub int WritePrivateProfileStringW -> @void lpAppName, @void lpKeyName, @void lpString, @void lpFileName;
stub int WritePrivateProfileStructA -> str lpszSection, str lpszKey, @void lpStruct, utype int uSizeStruct, str szFile;
stub int WritePrivateProfileStructW -> @void lpszSection, @void lpszKey, @void lpStruct, utype int uSizeStruct, @void szFile;
stub int WriteProcessMemory -> @void hProcess, @void lpBaseAddress, @void lpBuffer, utype longlong nSize, @longlong lpNumberOfBytesWritten;
stub int WriteProfileSectionA -> str lpAppName, str lpString;
stub int WriteProfileSectionW -> @void lpAppName, @void lpString;
stub int WriteProfileStringA -> str lpAppName, str lpKeyName, str lpString;
stub int WriteProfileStringW -> @void lpAppName, @void lpKeyName, @void lpString;
stub utype int WriteTapemark -> @void hDevice, utype int dwTapemarkType, utype int dwTapemarkCount, int bImmediate;
stub int ZombifyActCtx -> @void hActCtx;
stub int _hread -> int hFile, @void lpBuffer, int lBytes;
stub int _hwrite -> int hFile, str lpBuffer, int lBytes;
stub int _lclose -> int hFile;
stub int _lcreat -> str lpPathName, int iAttribute;
stub int _llseek -> int hFile, int lOffset, int iOrigin;
stub int _lopen -> str lpPathName, int iReadWrite;
stub utype int _lread -> int hFile, @void lpBuffer, utype int uBytes;
stub utype int _lwrite -> int hFile, str lpBuffer, utype int uBytes;
stub str lstrcatA -> str lpString1, str lpString2;
stub @void lstrcatW -> @void lpString1, @void lpString2;
stub int lstrcmpA -> str lpString1, str lpString2;
stub int lstrcmpW -> @void String1, @void String2;
stub int lstrcmpiA -> str lpString1, str lpString2;
stub int lstrcmpiW -> @void String1, @void String2;
stub str lstrcpyA -> str lpString1, str lpString2;
stub @void lstrcpyW -> @void lpString1, @void lpString2;
stub str lstrcpynA -> str lpString1, str lpString2, int iMaxLength;
stub @void lstrcpynW -> @void lpString1, @void lpString2, int iMaxLength;
stub int lstrlenA -> str lpString;
stub int lstrlenW -> @void String;
stub utype int timeBeginPeriod -> utype int uPeriod;
stub utype int timeEndPeriod -> utype int uPeriod;
stub utype int timeGetDevCaps -> @void ptc, utype int cbtc;
stub utype int timeGetSystemTime -> @void pmmt, utype int cbmmt;
stub utype int timeGetTime;
stub int uaw_lstrcmpW -> @void String1, @void String2;
stub int uaw_lstrcmpiW -> @void String1, @void String2;
stub int uaw_lstrlenW -> @void String;
stub @void uaw_wcscpy -> @void Destination, @void Source;
stub int uaw_wcsicmp -> @void String1, @void String2;
stub utype longlong uaw_wcslen -> @void String;

!!! Declared by the headers, but with a type the language cannot write:
!!!   ClosePackageInfo
!!!   CreateMemoryResourceNotification
!!!   CreatePseudoConsole
!!!   FillConsoleOutputAttribute
!!!   FillConsoleOutputCharacterA
!!!   FillConsoleOutputCharacterW
!!!   FindFirstFileExA
!!!   FindFirstFileExW
!!!   FindFirstFileTransactedA
!!!   FindFirstFileTransactedW
!!!   FindFirstStreamTransactedW
!!!   FindFirstStreamW
!!!   GetComputerNameExA
!!!   GetComputerNameExW
!!!   GetConsoleFontSize
!!!   GetFileAttributesExA
!!!   GetFileAttributesExW
!!!   GetFileAttributesTransactedA
!!!   GetFileAttributesTransactedW
!!!   GetFileInformationByHandleEx
!!!   GetLargestConsoleWindowSize
!!!   GetLogicalProcessorInformationEx
!!!   GetPackageApplicationIds
!!!   GetPackageInfo
!!!   GetProcessInformation
!!!   GetProcessMitigationPolicy
!!!   GetSystemDEPPolicy
!!!   GetThreadInformation
!!!   HeapQueryInformation
!!!   HeapSetInformation
!!!   IsNormalizedString
!!!   NormalizeString
!!!   OfferVirtualMemory
!!!   PowerClearRequest
!!!   PowerSetRequest
!!!   QueryInformationJobObject
!!!   QueryUmsThreadInformation
!!!   ReadConsoleOutputA
!!!   ReadConsoleOutputAttribute
!!!   ReadConsoleOutputCharacterA
!!!   ReadConsoleOutputCharacterW
!!!   ReadConsoleOutputW
!!!   ReadDirectoryChangesExW
!!!   RequestWakeupLatency
!!!   ResizePseudoConsole
!!!   ScrollConsoleScreenBufferA
!!!   ScrollConsoleScreenBufferW
!!!   SetComputerNameExA
!!!   SetComputerNameExW
!!!   SetConsoleCursorPosition
!!!   SetConsoleScreenBufferSize
!!!   SetFileInformationByHandle
!!!   SetInformationJobObject
!!!   SetProcessInformation
!!!   SetProcessMitigationPolicy
!!!   SetThreadInformation
!!!   SetUmsThreadInformation
!!!   WriteConsoleOutputA
!!!   WriteConsoleOutputAttribute
!!!   WriteConsoleOutputCharacterA
!!!   WriteConsoleOutputCharacterW
!!!   WriteConsoleOutputW
!!!   __C_specific_handler
!!!   uaw_wcschr
!!!   uaw_wcsrchr

!!! No prototype in the headers this build saw. They are here so the
!!! list is complete; uncomment and give the real signature to use one.
!!! ClosePackageInfo
!!! CreateMemoryResourceNotification
!!! CreatePseudoConsole
!!! FillConsoleOutputAttribute
!!! FillConsoleOutputCharacterA
!!! FillConsoleOutputCharacterW
!!! FindFirstFileExA
!!! FindFirstFileExW
!!! FindFirstFileTransactedA
!!! FindFirstFileTransactedW
!!! FindFirstStreamTransactedW
!!! FindFirstStreamW
!!! GetComputerNameExA
!!! GetComputerNameExW
!!! GetConsoleFontSize
!!! GetFileAttributesExA
!!! GetFileAttributesExW
!!! GetFileAttributesTransactedA
!!! GetFileAttributesTransactedW
!!! GetFileInformationByHandleEx
!!! GetLargestConsoleWindowSize
!!! GetLogicalProcessorInformationEx
!!! GetPackageApplicationIds
!!! GetPackageInfo
!!! GetProcessInformation
!!! GetProcessMitigationPolicy
!!! GetSystemDEPPolicy
!!! GetThreadInformation
!!! HeapQueryInformation
!!! HeapSetInformation
!!! IsNormalizedString
!!! NormalizeString
!!! OfferVirtualMemory
!!! PowerClearRequest
!!! PowerSetRequest
!!! QueryInformationJobObject
!!! QueryUmsThreadInformation
!!! ReadConsoleOutputA
!!! ReadConsoleOutputAttribute
!!! ReadConsoleOutputCharacterA
!!! ReadConsoleOutputCharacterW
!!! ReadConsoleOutputW
!!! ReadDirectoryChangesExW
!!! RequestWakeupLatency
!!! ResizePseudoConsole
!!! ScrollConsoleScreenBufferA
!!! ScrollConsoleScreenBufferW
!!! SetComputerNameExA
!!! SetComputerNameExW
!!! SetConsoleCursorPosition
!!! SetConsoleScreenBufferSize
!!! SetFileInformationByHandle
!!! SetInformationJobObject
!!! SetProcessInformation
!!! SetProcessMitigationPolicy
!!! SetThreadInformation
!!! SetUmsThreadInformation
!!! WriteConsoleOutputA
!!! WriteConsoleOutputAttribute
!!! WriteConsoleOutputCharacterA
!!! WriteConsoleOutputCharacterW
!!! WriteConsoleOutputW
!!! __C_specific_handler
!!! uaw_wcschr
!!! uaw_wcsrchr
