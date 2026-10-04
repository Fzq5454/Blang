!~
~  native/iumsdk.dll.b: the iumsdk.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/iumsdk.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/iumsdk.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `iumsdk.dll.b` is what produces `meta/iumsdk.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\iumsdk.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per iumsdk.dll export that the headers declare. The
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
!!! 125 declarations here, 0 kept from the hand-checked list above, 7 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub void AcquireSRWLockExclusive -> @void SRWLock;
stub void AcquireSRWLockShared -> @void SRWLock;
stub int CloseHandle -> @void hObject;
stub void CloseThreadpoolIo -> @void pio;
stub void CloseThreadpoolTimer -> @void pti;
stub void CloseThreadpoolWait -> @void pwa;
stub void CloseThreadpoolWork -> @void pwk;
stub @void CreateEventW -> @void lpEventAttributes, int bManualReset, int bInitialState, @void lpName;
stub @void CreateSemaphoreW -> @void lpSemaphoreAttributes, int lInitialCount, int lMaximumCount, @void lpName;
stub @void CreateThread -> @void lpThreadAttributes, utype longlong dwStackSize, @func lpStartAddress, @void lpParameter, utype int dwCreationFlags, @int lpThreadId;
stub @void CreateThreadpoolIo -> @void fl, @func pfnio, @void pv, @void pcbe;
stub @void CreateThreadpoolTimer -> @func pfnti, @void pv, @void pcbe;
stub @void CreateThreadpoolWait -> @func pfnwa, @void pv, @void pcbe;
stub @void CreateThreadpoolWork -> @func pfnwk, @void pv, @void pcbe;
stub void DebugBreak;
stub void DeleteCriticalSection -> @void lpCriticalSection;
stub int DuplicateHandle -> @void hSourceProcessHandle, @void hSourceHandle, @void hTargetProcessHandle, @void lpTargetHandle, utype int dwDesiredAccess, int bInheritHandle, utype int dwOptions;
stub void EnterCriticalSection -> @void lpCriticalSection;
stub void ExitProcess -> utype int uExitCode;
stub void ExitThread -> utype int dwExitCode;
stub int FileTimeToSystemTime -> @void lpFileTime, @void lpSystemTime;
stub int FreeLibrary -> @void hLibModule;
stub void FreeLibraryWhenCallbackReturns -> @void pci, @void mod;
stub @void GetCommandLineW;
stub @void GetCurrentProcess;
stub utype int GetCurrentProcessId;
stub @void GetCurrentThread;
stub utype int GetCurrentThreadId;
stub @void GetEnvironmentStringsW;
stub utype int GetEnvironmentVariableW -> @void lpName, @void lpBuffer, utype int nSize;
stub int GetExitCodeThread -> @void hThread, @int lpExitCode;
stub utype int GetLastError;
stub void GetLocalTime -> @void lpSystemTime;
stub @void GetModuleHandleW -> @void lpModuleName;
stub @longlong GetProcAddress -> @void hModule, str lpProcName;
stub @void GetProcessHeap;
stub void GetStartupInfoW -> @void lpStartupInfo;
stub utype int GetSystemFirmwareTable -> utype int FirmwareTableProviderSignature, utype int FirmwareTableID, @void pFirmwareTableBuffer, utype int BufferSize;
stub void GetSystemInfo -> @void lpSystemInfo;
stub void GetSystemTime -> @void lpSystemTime;
stub void GetSystemTimeAsFileTime -> @void lpSystemTimeAsFileTime;
stub utype int GetThreadId -> @void Thread;
stub int GetThreadPriority -> @void hThread;
stub utype int GetTickCount;
stub utype longlong GetTickCount64;
stub @void HeapAlloc -> @void hHeap, utype int dwFlags, utype longlong dwBytes;
stub @void HeapCreate -> utype int flOptions, utype longlong dwInitialSize, utype longlong dwMaximumSize;
stub int HeapDestroy -> @void hHeap;
stub int HeapFree -> @void hHeap, utype int dwFlags, @void lpMem;
stub int HeapLock -> @void hHeap;
stub @void HeapReAlloc -> @void hHeap, utype int dwFlags, @void lpMem, utype longlong dwBytes;
stub utype longlong HeapSize -> @void hHeap, utype int dwFlags, @void lpMem;
stub int HeapUnlock -> @void hHeap;
stub int HeapValidate -> @void hHeap, utype int dwFlags, @void lpMem;
stub void InitializeCriticalSection -> @void lpCriticalSection;
stub int InitializeCriticalSectionAndSpinCount -> @void lpCriticalSection, utype int dwSpinCount;
stub int InitializeCriticalSectionEx -> @void lpCriticalSection, utype int dwSpinCount, utype int Flags;
stub void InitializeSListHead -> @void ListHead;
stub void InitializeSRWLock -> @void SRWLock;
stub int IsDebuggerPresent;
stub int IsProcessorFeaturePresent -> utype int ProcessorFeature;
stub void LeaveCriticalSection -> @void lpCriticalSection;
stub void LeaveCriticalSectionWhenCallbackReturns -> @void pci, @void pcs;
stub @void LoadLibraryExW -> @void lpLibFileName, @void hFile, utype int dwFlags;
stub @void MapViewOfFile -> @void hFileMappingObject, utype int dwDesiredAccess, utype int dwFileOffsetHigh, utype int dwFileOffsetLow, utype longlong dwNumberOfBytesToMap;
stub void NdrServerCall2 -> @void pRpcMsg;
stub void NdrServerCallAll -> @void pRpcMsg;
stub @void OpenEventW -> utype int dwDesiredAccess, int bInheritHandle, @void lpName;
stub void OutputDebugStringW -> @void lpOutputString;
stub int QueryPerformanceCounter -> @longlong lpPerformanceCount;
stub int QueryPerformanceFrequency -> @longlong lpFrequency;
stub int QueryThreadCycleTime -> @void ThreadHandle, @longlong CycleTime;
stub void RaiseException -> utype int dwExceptionCode, utype int dwExceptionFlags, utype int nNumberOfArguments, @longlong lpArguments;
stub void RaiseFailFastException -> @void pExceptionRecord, @void pContextRecord, utype int dwFlags;
stub void ReleaseSRWLockExclusive -> @void SRWLock;
stub void ReleaseSRWLockShared -> @void SRWLock;
stub int ReleaseSemaphore -> @void hSemaphore, int lReleaseCount, @int lpPreviousCount;
stub void ReleaseSemaphoreWhenCallbackReturns -> @void pci, @void sem, utype int crel;
stub int ResetEvent -> @void hEvent;
stub int RpcMgmtStopServerListening -> @void Binding;
stub int RpcMgmtWaitServerListen;
stub int RpcServerInqCallAttributesW -> @void ClientBinding, @void RpcCallAttributes;
stub int RpcServerListen -> utype int MinimumCallThreads, utype int MaxCalls, utype int DontWait;
stub int RpcServerRegisterIf -> @void IfSpec, @void MgrTypeUuid, @void MgrEpv;
stub int RpcServerUnregisterIf -> @void IfSpec, @void MgrTypeUuid, utype int WaitForCallsToComplete;
stub int RpcServerUseProtseqEpW -> @int Protseq, utype int MaxCalls, @int Endpoint, @void SecurityDescriptor;
stub void RtlCaptureContext -> @void ContextRecord;
stub void RtlInitUnicodeString -> @void DestinationString, @void SourceString;
stub @void RtlLookupFunctionEntry -> utype longlong ControlPc, @longlong ImageBase, @void HistoryTable;
stub utype int RtlNtStatusToDosError -> int Status;
stub @void RtlVirtualUnwind -> utype int HandlerType, utype longlong ImageBase, utype longlong ControlPc, @void FunctionEntry, @void ContextRecord, @void HandlerData, @longlong EstablisherFrame, @void ContextPointers;
stub int SetEnvironmentVariableW -> @void lpName, @void lpValue;
stub int SetEvent -> @void hEvent;
stub void SetEventWhenCallbackReturns -> @void pci, @void evt;
stub void SetLastError -> utype int dwErrCode;
stub void SetThreadpoolTimer -> @void pti, @void pftDueTime, utype int msPeriod, utype int msWindowLength;
stub int SetThreadpoolTimerEx -> @void pti, @void pftDueTime, utype int msPeriod, utype int msWindowLength;
stub void SetThreadpoolWait -> @void pwa, @void h, @void pftTimeout;
stub @void SetUnhandledExceptionFilter -> @func lpTopLevelExceptionFilter;
stub void Sleep -> utype int dwMilliseconds;
stub void StartThreadpoolIo -> @void pio;
stub int SystemTimeToFileTime -> @void lpSystemTime, @void lpFileTime;
stub int TerminateProcess -> @void hProcess, utype int uExitCode;
stub int TerminateThread -> @void hThread, utype int dwExitCode;
stub utype int TlsAlloc;
stub int TlsFree -> utype int dwTlsIndex;
stub @void TlsGetValue -> utype int dwTlsIndex;
stub int TlsSetValue -> utype int dwTlsIndex, @void lpTlsValue;
stub utype char TryAcquireSRWLockExclusive -> @void SRWLock;
stub utype char TryAcquireSRWLockShared -> @void SRWLock;
stub int UnhandledExceptionFilter -> @void ExceptionInfo;
stub int UnmapViewOfFile -> @void lpBaseAddress;
stub int UuidCreate -> @void Uuid;
stub @void VirtualAlloc -> @void lpAddress, utype longlong dwSize, utype int flAllocationType, utype int flProtect;
stub int VirtualFree -> @void lpAddress, utype longlong dwSize, utype int dwFreeType;
stub int VirtualProtect -> @void lpAddress, utype longlong dwSize, utype int flNewProtect, @int lpflOldProtect;
stub utype longlong VirtualQuery -> @void lpAddress, @void lpBuffer, utype longlong dwLength;
stub utype int WaitForMultipleObjects -> utype int nCount, @void lpHandles, int bWaitAll, utype int dwMilliseconds;
stub utype int WaitForSingleObject -> @void hHandle, utype int dwMilliseconds;
stub utype int WaitForSingleObjectEx -> @void hHandle, utype int dwMilliseconds, int bAlertable;
stub void WaitForThreadpoolIoCallbacks -> @void pio, int fCancelPendingCallbacks;
stub void WaitForThreadpoolTimerCallbacks -> @void pti, int fCancelPendingCallbacks;
stub void WaitForThreadpoolWaitCallbacks -> @void pwa, int fCancelPendingCallbacks;
stub void WaitForThreadpoolWorkCallbacks -> @void pwk, int fCancelPendingCallbacks;
stub int WideCharToMultiByte -> utype int CodePage, utype int dwFlags, @void lpWideCharStr, int cchWideChar, str lpMultiByteStr, int cbMultiByte, str lpDefaultChar, @int lpUsedDefaultChar;

!!! Declared by the headers, but with a type the language cannot write:
!!!   HeapQueryInformation
!!!   HeapSetInformation
!!!   NdrClientCall3
!!!   NtQueryInformationProcess
!!!   NtQueryInformationThread
!!!   NtSetInformationProcess
!!!   NtSetInformationThread

!!! No prototype in the headers this build saw. They are here so the
!!! list is complete; uncomment and give the real signature to use one.
!!! HeapQueryInformation
!!! HeapSetInformation
!!! NdrClientCall3
!!! NtQueryInformationProcess
!!! NtQueryInformationThread
!!! NtSetInformationProcess
!!! NtSetInformationThread
