!~
~  native/vertdll.dll.b: the vertdll.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/vertdll.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/vertdll.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `vertdll.dll.b` is what produces `meta/vertdll.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\vertdll.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per vertdll.dll export that the headers declare. The
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
!!! 120 declarations here, 0 kept from the hand-checked list above, 5 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub void AcquireSRWLockExclusive -> @void SRWLock;
stub void AcquireSRWLockShared -> @void SRWLock;
stub int CloseHandle -> @void hObject;
stub void CloseThreadpoolTimer -> @void pti;
stub @void CreateEventW -> @void lpEventAttributes, int bManualReset, int bInitialState, @void lpName;
stub @void CreateThreadpoolTimer -> @func pfnti, @void pv, @void pcbe;
stub void DeleteCriticalSection -> @void lpCriticalSection;
stub int DeleteSynchronizationBarrier -> @void lpBarrier;
stub int DeviceIoControl -> @void hDevice, utype int dwIoControlCode, @void lpInBuffer, utype int nInBufferSize, @void lpOutBuffer, utype int nOutBufferSize, @int lpBytesReturned, @void lpOverlapped;
stub int DisableThreadLibraryCalls -> @void hLibModule;
stub void EnterCriticalSection -> @void lpCriticalSection;
stub int EnterSynchronizationBarrier -> @void lpBarrier, utype int dwFlags;
stub int FreeLibrary -> @void hLibModule;
stub @void GetCurrentProcess;
stub utype int GetCurrentProcessId;
stub @void GetCurrentThread;
stub utype int GetCurrentThreadId;
stub utype longlong GetEnabledXStateFeatures;
stub utype int GetLastError;
stub utype int GetModuleFileNameW -> @void hModule, @void lpFilename, utype int nSize;
stub int GetModuleHandleExW -> utype int dwFlags, @void lpModuleName, @void phModule;
stub @longlong GetProcAddress -> @void hModule, str lpProcName;
stub @void GetProcessHeap;
stub utype int GetProcessHeaps -> utype int NumberOfHeaps, @void ProcessHeaps;
stub utype int GetProcessId -> @void Process;
stub utype int GetSystemDirectoryW -> @void lpBuffer, utype int uSize;
stub void GetSystemInfo -> @void lpSystemInfo;
stub int GetXStateFeaturesMask -> @void Context, @longlong FeatureMask;
stub @void HeapAlloc -> @void hHeap, utype int dwFlags, utype longlong dwBytes;
stub utype longlong HeapCompact -> @void hHeap, utype int dwFlags;
stub @void HeapCreate -> utype int flOptions, utype longlong dwInitialSize, utype longlong dwMaximumSize;
stub int HeapDestroy -> @void hHeap;
stub int HeapFree -> @void hHeap, utype int dwFlags, @void lpMem;
stub int HeapLock -> @void hHeap;
stub @void HeapReAlloc -> @void hHeap, utype int dwFlags, @void lpMem, utype longlong dwBytes;
stub utype longlong HeapSize -> @void hHeap, utype int dwFlags, @void lpMem;
stub int HeapUnlock -> @void hHeap;
stub void InitializeConditionVariable -> @void ConditionVariable;
stub void InitializeCriticalSection -> @void lpCriticalSection;
stub int InitializeCriticalSectionAndSpinCount -> @void lpCriticalSection, utype int dwSpinCount;
stub int InitializeCriticalSectionEx -> @void lpCriticalSection, utype int dwSpinCount, utype int Flags;
stub void InitializeSListHead -> @void ListHead;
stub void InitializeSRWLock -> @void SRWLock;
stub int InitializeSynchronizationBarrier -> @void lpBarrier, int lTotalThreads, int lSpinCount;
stub @void InterlockedFlushSList -> @void ListHead;
stub @void InterlockedPopEntrySList -> @void ListHead;
stub @void InterlockedPushEntrySList -> @void ListHead, @void ListEntry;
stub @void InterlockedPushListSListEx -> @void ListHead, @void List, @void ListEnd, utype int Count;
stub int IsProcessorFeaturePresent -> utype int ProcessorFeature;
stub void LeaveCriticalSection -> @void lpCriticalSection;
stub @void LoadLibraryExW -> @void lpLibFileName, @void hFile, utype int dwFlags;
stub @void LoadLibraryW -> @void lpLibFileName;
stub @void LocalFree -> @void hMem;
stub @void LocateXStateFeature -> @void Context, utype int FeatureId, @int Length;
stub int MultiByteToWideChar -> utype int CodePage, utype int dwFlags, str lpMultiByteStr, int cbMultiByte, @void lpWideCharStr, int cchWideChar;
stub int NtClose -> @void Handle;
stub int NtDeviceIoControlFile -> @void FileHandle, @void Event, @func ApcRoutine, @void ApcContext, @void IoStatusBlock, utype int IoControlCode, @void InputBuffer, utype int InputBufferLength, @void OutputBuffer, utype int OutputBufferLength;
stub int NtOpenFile -> @void FileHandle, utype int DesiredAccess, @void ObjectAttributes, @void IoStatusBlock, utype int ShareAccess, utype int OpenOptions;
stub int OpenProcessToken -> @void ProcessHandle, utype int DesiredAccess, @void TokenHandle;
stub void OutputDebugStringW -> @void lpOutputString;
stub int PrivilegeCheck -> @void ClientToken, @void RequiredPrivileges, @int pfResult;
stub utype int QueryDepthSList -> @void ListHead;
stub int QueryFullProcessImageNameW -> @void hProcess, utype int dwFlags, @void lpExeName, @int lpdwSize;
stub int QueryPerformanceCounter -> @longlong lpPerformanceCount;
stub int QueryPerformanceFrequency -> @longlong lpFrequency;
stub void RaiseException -> utype int dwExceptionCode, utype int dwExceptionFlags, utype int nNumberOfArguments, @longlong lpArguments;
stub int RegCloseKey -> @void hKey;
stub int RegEnumKeyExW -> @void hKey, utype int dwIndex, @void lpName, @int lpcchName, @int lpReserved, @void lpClass, @int lpcchClass, @void lpftLastWriteTime;
stub int RegOpenKeyExW -> @void hKey, @void lpSubKey, utype int ulOptions, utype int samDesired, @void phkResult;
stub int RegQueryInfoKeyW -> @void hKey, @void lpClass, @int lpcchClass, @int lpReserved, @int lpcSubKeys, @int lpcbMaxSubKeyLen, @int lpcbMaxClassLen, @int lpcValues, @int lpcbMaxValueNameLen, @int lpcbMaxValueLen, @int lpcbSecurityDescriptor, @void lpftLastWriteTime;
stub int RegQueryValueExW -> @void hKey, @void lpValueName, @int lpReserved, @int lpType, @char lpData, @int lpcbData;
stub void ReleaseSRWLockExclusive -> @void SRWLock;
stub void ReleaseSRWLockShared -> @void SRWLock;
stub @void RtlAllocateHeap -> @void HeapHandle, utype int Flags, utype longlong Size;
stub void RtlCaptureContext -> @void ContextRecord;
stub utype char RtlFreeHeap -> @void HeapHandle, utype int Flags, @void HeapBase;
stub void RtlInitUnicodeString -> @void DestinationString, @void SourceString;
stub @void RtlLookupFunctionEntry -> utype longlong ControlPc, @longlong ImageBase, @void HistoryTable;
stub utype int RtlNtStatusToDosError -> int Status;
stub @void RtlPcToFileHeader -> @void PcValue, @void BaseOfImage;
stub void RtlUnwind -> @void TargetFrame, @void TargetIp, @void ExceptionRecord, @void ReturnValue;
stub void RtlUnwindEx -> @void TargetFrame, @void TargetIp, @void ExceptionRecord, @void ReturnValue, @void ContextRecord, @void HistoryTable;
stub @void RtlVirtualUnwind -> utype int HandlerType, utype longlong ImageBase, utype longlong ControlPc, @void FunctionEntry, @void ContextRecord, @void HandlerData, @longlong EstablisherFrame, @void ContextPointers;
stub utype int SetCriticalSectionSpinCount -> @void lpCriticalSection, utype int dwSpinCount;
stub void SetLastError -> utype int dwErrCode;
stub int SetThreadStackGuarantee -> @int StackSizeInBytes;
stub void SetThreadpoolTimer -> @void pti, @void pftDueTime, utype int msPeriod, utype int msWindowLength;
stub @void SetUnhandledExceptionFilter -> @func lpTopLevelExceptionFilter;
stub int SleepConditionVariableCS -> @void ConditionVariable, @void CriticalSection, utype int dwMilliseconds;
stub int SleepConditionVariableSRW -> @void ConditionVariable, @void SRWLock, utype int dwMilliseconds, utype int Flags;
stub int TerminateProcess -> @void hProcess, utype int uExitCode;
stub utype int TlsAlloc;
stub int TlsFree -> utype int dwTlsIndex;
stub @void TlsGetValue -> utype int dwTlsIndex;
stub @void TlsGetValue2 -> utype int dwTlsIndex;
stub int TlsSetValue -> utype int dwTlsIndex, @void lpTlsValue;
stub utype char TryAcquireSRWLockExclusive -> @void SRWLock;
stub utype char TryAcquireSRWLockShared -> @void SRWLock;
stub int TryEnterCriticalSection -> @void lpCriticalSection;
stub int UnregisterWaitEx -> @void WaitHandle, @void CompletionEvent;
stub @void VirtualAlloc -> @void lpAddress, utype longlong dwSize, utype int flAllocationType, utype int flProtect;
stub int VirtualFree -> @void lpAddress, utype longlong dwSize, utype int dwFreeType;
stub int VirtualProtect -> @void lpAddress, utype longlong dwSize, utype int flNewProtect, @int lpflOldProtect;
stub utype longlong VirtualQuery -> @void lpAddress, @void lpBuffer, utype longlong dwLength;
stub void WaitForThreadpoolTimerCallbacks -> @void pti, int fCancelPendingCallbacks;
stub int WaitOnAddress -> @void Address, @void CompareAddress, utype longlong AddressSize, utype int dwMilliseconds;
stub void WakeAllConditionVariable -> @void ConditionVariable;
stub void WakeByAddressAll -> @void Address;
stub void WakeByAddressSingle -> @void Address;
stub void WakeConditionVariable -> @void ConditionVariable;
stub int WideCharToMultiByte -> utype int CodePage, utype int dwFlags, @void lpWideCharStr, int cchWideChar, str lpMultiByteStr, int cbMultiByte, str lpDefaultChar, @int lpUsedDefaultChar;
stub int _wcsicmp -> @void _Str1, @void _Str2;
stub int _wcsnicmp -> @void _Str1, @void _Str2, utype longlong _MaxCount;
stub int memcmp -> @void _Buf1, @void _Buf2, utype longlong _Size;
stub @void memcpy -> @void _Dst, @void _Src, utype longlong _Size;
stub @void memmove -> @void _Dst, @void _Src, utype longlong _Size;
stub @void memset -> @void _Dst, int _Val, utype longlong _Size;
stub void qsort -> @void _Base, utype longlong _NumOfElements, utype longlong _SizeOfElements, @func a4;
stub int wcscmp -> @void _Str1, @void _Str2;
stub int wcsncmp -> @void _Str1, @void _Str2, utype longlong _MaxCount;

!!! Declared by the headers, but with a type the language cannot write:
!!!   NtQueryInformationProcess
!!!   __C_specific_handler

!!! No prototype in the headers this build saw. They are here so the
!!! list is complete; uncomment and give the real signature to use one.
!!! NtQueryInformationProcess
!!! __C_specific_handler
!!! _wsplitpath_s
!!! wcscpy_s
!!! wcsncpy_s
