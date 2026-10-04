!~
~  native/tprtdll.dll.b: the tprtdll.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/tprtdll.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/tprtdll.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `tprtdll.dll.b` is what produces `meta/tprtdll.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\tprtdll.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per tprtdll.dll export that the headers declare. The
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
!!! 89 declarations here, 0 kept from the hand-checked list above, 7 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub void AcquireSRWLockExclusive -> @void SRWLock;
stub void AcquireSRWLockShared -> @void SRWLock;
stub int CloseHandle -> @void hObject;
stub @void CreateEventW -> @void lpEventAttributes, int bManualReset, int bInitialState, @void lpName;
stub @void CreateSemaphoreExW -> @void lpSemaphoreAttributes, int lInitialCount, int lMaximumCount, @void lpName, utype int dwFlags, utype int dwDesiredAccess;
stub @void CreateSemaphoreW -> @void lpSemaphoreAttributes, int lInitialCount, int lMaximumCount, @void lpName;
stub @void CreateThread -> @void lpThreadAttributes, utype longlong dwStackSize, @func lpStartAddress, @void lpParameter, utype int dwCreationFlags, @int lpThreadId;
stub void DebugBreak;
stub void DeleteCriticalSection -> @void lpCriticalSection;
stub int DeleteSynchronizationBarrier -> @void lpBarrier;
stub int DuplicateHandle -> @void hSourceProcessHandle, @void hSourceHandle, @void hTargetProcessHandle, @void lpTargetHandle, utype int dwDesiredAccess, int bInheritHandle, utype int dwOptions;
stub void EnterCriticalSection -> @void lpCriticalSection;
stub int EnterSynchronizationBarrier -> @void lpBarrier, utype int dwFlags;
stub void ExitThread -> utype int dwExitCode;
stub @void GetCurrentProcess;
stub utype int GetCurrentProcessId;
stub @void GetCurrentThread;
stub utype int GetCurrentThreadId;
stub utype longlong GetEnabledXStateFeatures;
stub int GetExitCodeThread -> @void hThread, @int lpExitCode;
stub utype int GetLastError;
stub @void GetProcessHeap;
stub utype int GetThreadId -> @void Thread;
stub int GetXStateFeaturesMask -> @void Context, @longlong FeatureMask;
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
stub void InitializeSRWLock -> @void SRWLock;
stub int InitializeSynchronizationBarrier -> @void lpBarrier, int lTotalThreads, int lSpinCount;
stub @void InterlockedFlushSList -> @void ListHead;
stub @void InterlockedPushEntrySList -> @void ListHead, @void ListEntry;
stub void LeaveCriticalSection -> @void lpCriticalSection;
stub @void LocateXStateFeature -> @void Context, utype int FeatureId, @int Length;
stub int NtClose -> @void Handle;
stub void OutputDebugStringW -> @void lpOutputString;
stub int QueryPerformanceCounter -> @longlong lpPerformanceCount;
stub int QueryPerformanceFrequency -> @longlong lpFrequency;
stub void ReleaseSRWLockExclusive -> @void SRWLock;
stub void ReleaseSRWLockShared -> @void SRWLock;
stub int ReleaseSemaphore -> @void hSemaphore, int lReleaseCount, @int lpPreviousCount;
stub int ResetEvent -> @void hEvent;
stub @void RtlAllocateHeap -> @void HeapHandle, utype int Flags, utype longlong Size;
stub void RtlCaptureContext -> @void ContextRecord;
stub utype longlong RtlCompareMemory -> @void Source1, @void Source2, utype longlong Length;
stub @void RtlCreateHeap -> utype int Flags, @void HeapBase, utype longlong ReserveSize, utype longlong CommitSize, @void Lock, @void Parameters;
stub @void RtlDestroyHeap -> @void HeapHandle;
stub utype char RtlFreeHeap -> @void HeapHandle, utype int Flags, @void HeapBase;
stub void RtlInitUnicodeString -> @void DestinationString, @void SourceString;
stub void RtlInitializeSListHead -> @void ListHead;
stub @void RtlInterlockedFlushSList -> @void ListHead;
stub @void RtlInterlockedPopEntrySList -> @void ListHead;
stub @void RtlInterlockedPushEntrySList -> @void ListHead, @void ListEntry;
stub @void RtlLookupFunctionEntry -> utype longlong ControlPc, @longlong ImageBase, @void HistoryTable;
stub @void RtlPcToFileHeader -> @void PcValue, @void BaseOfImage;
stub utype int RtlQueryDepthSList -> @void ListHead;
stub void RtlUnwind -> @void TargetFrame, @void TargetIp, @void ExceptionRecord, @void ReturnValue;
stub void RtlUnwindEx -> @void TargetFrame, @void TargetIp, @void ExceptionRecord, @void ReturnValue, @void ContextRecord, @void HistoryTable;
stub @void RtlVirtualUnwind -> utype int HandlerType, utype longlong ImageBase, utype longlong ControlPc, @void FunctionEntry, @void ContextRecord, @void HandlerData, @longlong EstablisherFrame, @void ContextPointers;
stub utype int SetCriticalSectionSpinCount -> @void lpCriticalSection, utype int dwSpinCount;
stub int SetEvent -> @void hEvent;
stub void SetLastError -> utype int dwErrCode;
stub void Sleep -> utype int dwMilliseconds;
stub int TerminateProcess -> @void hProcess, utype int uExitCode;
stub int TerminateThread -> @void hThread, utype int dwExitCode;
stub utype int TlsAlloc;
stub int TlsFree -> utype int dwTlsIndex;
stub @void TlsGetValue -> utype int dwTlsIndex;
stub int TlsSetValue -> utype int dwTlsIndex, @void lpTlsValue;
stub utype char TryAcquireSRWLockExclusive -> @void SRWLock;
stub utype char TryAcquireSRWLockShared -> @void SRWLock;
stub int TryEnterCriticalSection -> @void lpCriticalSection;
stub @void VirtualAlloc -> @void lpAddress, utype longlong dwSize, utype int flAllocationType, utype int flProtect;
stub int VirtualFree -> @void lpAddress, utype longlong dwSize, utype int dwFreeType;
stub int VirtualProtect -> @void lpAddress, utype longlong dwSize, utype int flNewProtect, @int lpflOldProtect;
stub utype longlong VirtualQuery -> @void lpAddress, @void lpBuffer, utype longlong dwLength;
stub utype int WaitForMultipleObjects -> utype int nCount, @void lpHandles, int bWaitAll, utype int dwMilliseconds;
stub utype int WaitForSingleObject -> @void hHandle, utype int dwMilliseconds;
stub @void memcpy -> @void _Dst, @void _Src, utype longlong _Size;
stub @void memmove -> @void _Dst, @void _Src, utype longlong _Size;
stub @void memset -> @void _Dst, int _Val, utype longlong _Size;

!!! Declared by the headers, but with a type the language cannot write:
!!!   HeapQueryInformation
!!!   HeapSetInformation
!!!   NtQueryInformationProcess
!!!   NtQueryInformationThread
!!!   RtlQueryHeapInformation
!!!   RtlSetHeapInformation
!!!   __C_specific_handler

!!! No prototype in the headers this build saw. They are here so the
!!! list is complete; uncomment and give the real signature to use one.
!!! HeapQueryInformation
!!! HeapSetInformation
!!! NtQueryInformationProcess
!!! NtQueryInformationThread
!!! RtlQueryHeapInformation
!!! RtlSetHeapInformation
!!! __C_specific_handler
