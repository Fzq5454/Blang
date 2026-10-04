!~
~  native/ntdll.dll.b: the ntdll.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/ntdll.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/ntdll.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `ntdll.dll.b` is what produces `meta/ntdll.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\ntdll.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per ntdll.dll export that the headers declare. The
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
!!! 170 declarations here, 0 kept from the hand-checked list above, 50 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub int NtClose -> @void Handle;
stub int NtCreateFile -> @void FileHandle, utype int DesiredAccess, @void ObjectAttributes, @void IoStatusBlock, @longlong AllocationSize, utype int FileAttributes, utype int ShareAccess, utype int CreateDisposition, utype int CreateOptions, @void EaBuffer, utype int EaLength;
stub int NtDeviceIoControlFile -> @void FileHandle, @void Event, @func ApcRoutine, @void ApcContext, @void IoStatusBlock, utype int IoControlCode, @void InputBuffer, utype int InputBufferLength, @void OutputBuffer, utype int OutputBufferLength;
stub int NtFsControlFile -> @void FileHandle, @void Event, @func ApcRoutine, @void ApcContext, @void IoStatusBlock, utype int IoControlCode, @void InputBuffer, utype int InputBufferLength, @void OutputBuffer, utype int OutputBufferLength;
stub int NtNotifyChangeMultipleKeys -> @void MasterKeyHandle, utype int Count, @void SubordinateObjects, @void Event, @func ApcRoutine, @void ApcContext, @void IoStatusBlock, utype int CompletionFilter, utype char WatchTree, @void Buffer, utype int BufferSize, utype char Asynchronous;
stub int NtOpenFile -> @void FileHandle, utype int DesiredAccess, @void ObjectAttributes, @void IoStatusBlock, utype int ShareAccess, utype int OpenOptions;
stub int NtQueryMultipleValueKey -> @void KeyHandle, @void ValueEntries, utype int EntryCount, @void ValueBuffer, @int BufferLength, @int RequiredBufferLength;
stub int NtQuerySystemTime -> @longlong SystemTime;
stub int NtQueryTimerResolution -> @int MaximumTime, @int MinimumTime, @int CurrentTime;
stub int NtRenameKey -> @void KeyHandle, @void NewName;
stub int NtWaitForSingleObject -> @void Handle, utype char Alertable, @longlong Timeout;
stub utype char RtlAddFunctionTable -> @void FunctionTable, utype int EntryCount, utype longlong BaseAddress;
stub utype int RtlAddGrowableFunctionTable -> @void DynamicTable, @void FunctionTable, utype int EntryCount, utype int MaximumEntryCount, utype longlong RangeBase, utype longlong RangeEnd;
stub @void RtlAllocateHeap -> @void HeapHandle, utype int Flags, utype longlong Size;
stub int RtlAnsiStringToUnicodeString -> @void DestinationString, @void SourceString, utype char AllocateDestinationString;
stub void RtlApplicationVerifierStop -> utype longlong Code, str Message, utype longlong Param1, str Description1, utype longlong Param2, str Description2, utype longlong Param3, str Description3, utype longlong Param4, str Description4;
stub void RtlCaptureContext -> @void ContextRecord;
stub utype int RtlCaptureStackBackTrace -> utype int FramesToSkip, utype int FramesToCapture, @void BackTrace, @int BackTraceHash;
stub int RtlCharToInteger -> str String, utype int Base, @int Value;
stub utype longlong RtlCompareMemory -> @void Source1, @void Source2, utype longlong Length;
stub int RtlConvertSidToUnicodeString -> @void UnicodeString, @void Sid, utype char AllocateDestinationString;
stub utype int RtlCrc32 -> @void Buffer, utype longlong Size, utype int InitialCrc;
stub utype longlong RtlCrc64 -> @void Buffer, utype longlong Size, utype longlong InitialCrc;
stub @void RtlCreateHeap -> utype int Flags, @void HeapBase, utype longlong ReserveSize, utype longlong CommitSize, @void Lock, @void Parameters;
stub utype char RtlCreateUnicodeStringFromAsciiz -> @void target, str src;
stub utype char RtlDeleteFunctionTable -> @void FunctionTable;
stub void RtlDeleteGrowableFunctionTable -> @void DynamicTable;
stub @void RtlDestroyHeap -> @void HeapHandle;
stub int RtlDosPathNameToNtPathName_U -> @void DosPathName, @void NtPathName, @void NtFileNamePart, @void DirectoryInfo;
stub @void RtlFirstEntrySList -> @void ListHead;
stub void RtlFreeAnsiString -> @void AnsiString;
stub utype char RtlFreeHeap -> @void HeapHandle, utype int Flags, @void HeapBase;
stub void RtlFreeOemString -> @void OemString;
stub void RtlFreeUnicodeString -> @void UnicodeString;
stub utype char RtlGetProductInfo -> utype int OSMajorVersion, utype int OSMinorVersion, utype int SpMajorVersion, utype int SpMinorVersion, @int ReturnedProductType;
stub void RtlGrowFunctionTable -> @void DynamicTable, utype int NewEntryCount;
stub void RtlInitAnsiString -> @void DestinationString, str SourceString;
stub int RtlInitAnsiStringEx -> @void DestinationString, str SourceString;
stub void RtlInitString -> @void DestinationString, str SourceString;
stub int RtlInitStringEx -> @void DestinationString, str SourceString;
stub void RtlInitUnicodeString -> @void DestinationString, @void SourceString;
stub void RtlInitializeSListHead -> @void ListHead;
stub utype char RtlInstallFunctionTableCallback -> utype longlong TableIdentifier, utype longlong BaseAddress, utype int Length, @func TargetGp, @void Callback, @void Context;
stub @void RtlInterlockedFlushSList -> @void ListHead;
stub @void RtlInterlockedPopEntrySList -> @void ListHead;
stub @void RtlInterlockedPushEntrySList -> @void ListHead, @void ListEntry;
stub @void RtlInterlockedPushListSListEx -> @void ListHead, @void List, @void ListEnd, utype int Count;
stub utype char RtlIsEcCode -> utype longlong CodePointer;
stub utype char RtlIsNameLegalDOS8Dot3 -> @void Name, @void OemName, @char NameContainsSpaces;
stub int RtlLocalTimeToSystemTime -> @longlong LocalTime, @longlong SystemTime;
stub @void RtlLookupFunctionEntry -> utype longlong ControlPc, @longlong ImageBase, @void HistoryTable;
stub utype int RtlMultipleAllocateHeap -> @void HeapHandle, utype int Flags, utype longlong Size, utype int Count, @void Array;
stub utype int RtlMultipleFreeHeap -> @void HeapHandle, utype int Flags, utype int Count, @void Array;
stub utype int RtlNtStatusToDosError -> int Status;
stub @void RtlPcToFileHeader -> @void PcValue, @void BaseOfImage;
stub utype char RtlPrefixUnicodeString -> @void String1, @void String2, utype char CaseInSensitive;
stub utype int RtlQueryDepthSList -> @void ListHead;
stub void RtlRestoreContext -> @void ContextRecord, @void ExceptionRecord;
stub utype char RtlTimeToSecondsSince1970 -> @longlong Time, @int ElapsedSeconds;
stub int RtlUnicodeStringToAnsiString -> @void DestinationString, @void SourceString, utype char AllocateDestinationString;
stub int RtlUnicodeStringToOemString -> @void DestinationString, @void SourceString, utype char AllocateDestinationString;
stub int RtlUnicodeToMultiByteSize -> @int BytesInMultiByteString, @void UnicodeString, utype int BytesInUnicodeString;
stub utype int RtlUniform -> @int Seed;
stub void RtlUnwind -> @void TargetFrame, @void TargetIp, @void ExceptionRecord, @void ReturnValue;
stub void RtlUnwindEx -> @void TargetFrame, @void TargetIp, @void ExceptionRecord, @void ReturnValue, @void ContextRecord, @void HistoryTable;
stub @void RtlVirtualUnwind -> utype int HandlerType, utype longlong ImageBase, utype longlong ControlPc, @void FunctionEntry, @void ContextRecord, @void HandlerData, @longlong EstablisherFrame, @void ContextPointers;
stub utype longlong VerSetConditionMask -> utype longlong ConditionMask, utype int TypeMask, utype char Condition;
stub int __isascii -> int _C;
stub int __iscsym -> int _C;
stub int __iscsymf -> int _C;
stub int __toascii -> int _C;
stub longlong _atoi64 -> str _String;
stub @int _errno;
stub str _i64toa -> longlong _Val, str _DstBuf, int _Radix;
stub int _i64toa_s -> longlong _Val, str _DstBuf, utype longlong _Size, int _Radix;
stub @void _i64tow -> longlong _Val, @void _DstBuf, int _Radix;
stub int _i64tow_s -> longlong _Val, @void _DstBuf, utype longlong _SizeInWords, int _Radix;
stub str _itoa -> int _Value, str _Dest, int _Radix;
stub @void _itow -> int _Value, @void _Dest, int _Radix;
stub str _ltoa -> int _Value, str _Dest, int _Radix;
stub @void _ltow -> int _Value, @void _Dest, int _Radix;
stub @void _memccpy -> @void _Dst, @void _Src, int _Val, utype longlong _MaxCount;
stub int _memicmp -> @void _Buf1, @void _Buf2, utype longlong _Size;
stub void _splitpath -> str _FullPath, str _Drive, str _Dir, str _Filename, str _Ext;
stub int _strcmpi -> str _Str1, str _Str2;
stub int _stricmp -> str _Str1, str _Str2;
stub str _strlwr -> str _String;
stub int _strnicmp -> str _Str1, str _Str2, utype longlong _MaxCount;
stub str _strupr -> str _String;
stub str _ui64toa -> utype longlong _Val, str _DstBuf, int _Radix;
stub int _ui64toa_s -> utype longlong _Val, str _DstBuf, utype longlong _Size, int _Radix;
stub @void _ui64tow -> utype longlong _Val, @void _DstBuf, int _Radix;
stub int _ui64tow_s -> utype longlong _Val, @void _DstBuf, utype longlong _SizeInWords, int _Radix;
stub str _ultoa -> utype int _Value, str _Dest, int _Radix;
stub @void _ultow -> utype int _Value, @void _Dest, int _Radix;
stub int _wcsicmp -> @void _Str1, @void _Str2;
stub @void _wcslwr -> @void _String;
stub int _wcsnicmp -> @void _Str1, @void _Str2, utype longlong _MaxCount;
stub longlong _wcstoi64 -> @void _Str, @void _EndPtr, int _Radix;
stub utype longlong _wcstoui64 -> @void _Str, @void _EndPtr, int _Radix;
stub @void _wcsupr -> @void _String;
stub int _wtoi -> @void _Str;
stub longlong _wtoi64 -> @void _Str;
stub int _wtol -> @void _Str;
stub int atoi -> str _Str;
stub int atol -> str _Str;
stub @void bsearch -> @void _Key, @void _Base, utype longlong _NumOfElements, utype longlong _SizeOfElements, @func a5;
stub @void bsearch_s -> @void _Key, @void _Base, utype longlong _NumOfElements, utype longlong _SizeOfElements, @func a5, @void _Context;
stub int isalnum -> int _C;
stub int isalpha -> int _C;
stub int iscntrl -> int _C;
stub int isdigit -> int _C;
stub int isgraph -> int _C;
stub int islower -> int _C;
stub int isprint -> int _C;
stub int ispunct -> int _C;
stub int isspace -> int _C;
stub int isupper -> int _C;
stub int iswalnum -> utype int _C;
stub int iswalpha -> utype int _C;
stub int iswascii -> utype int _C;
stub int iswctype -> utype int _C, utype int _Type;
stub int iswdigit -> utype int _C;
stub int iswgraph -> utype int _C;
stub int iswlower -> utype int _C;
stub int iswprint -> utype int _C;
stub int iswspace -> utype int _C;
stub int iswxdigit -> utype int _C;
stub int isxdigit -> int _C;
stub int labs -> int _X;
stub utype longlong mbstowcs -> @void _Dest, str _Source, utype longlong _MaxCount;
stub int memcmp -> @void _Buf1, @void _Buf2, utype longlong _Size;
stub @void memcpy -> @void _Dst, @void _Src, utype longlong _Size;
stub int memcpy_s -> @void _dest, utype longlong _numberOfElements, @void _src, utype longlong _count;
stub @void memmove -> @void _Dst, @void _Src, utype longlong _Size;
stub int memmove_s -> @void _dest, utype longlong _numberOfElements, @void _src, utype longlong _count;
stub @void memset -> @void _Dst, int _Val, utype longlong _Size;
stub void qsort -> @void _Base, utype longlong _NumOfElements, utype longlong _SizeOfElements, @func a4;
stub void qsort_s -> @void _Base, utype longlong _NumOfElements, utype longlong _SizeOfElements, @func a4, @void _Context;
stub str strcat -> str _Dest, str _Source;
stub int strcmp -> str _Str1, str _Str2;
stub str strcpy -> str _Dest, str _Source;
stub utype longlong strcspn -> str _Str, str _Control;
stub utype longlong strlen -> str _Str;
stub str strncat -> str _Dest, str _Source, utype longlong _Count;
stub int strncmp -> str _Str1, str _Str2, utype longlong _MaxCount;
stub str strncpy -> str _Dest, str _Source, utype longlong _Count;
stub utype longlong strnlen -> str _Str, utype longlong _MaxCount;
stub utype longlong strspn -> str _Str, str _Control;
stub str strtok_s -> str _Str, str _Delim, @void _Context;
stub int strtol -> str _Str, @void _EndPtr, int _Radix;
stub utype int strtoul -> str _Str, @void _EndPtr, int _Radix;
stub int tolower -> int _C;
stub int toupper -> int _C;
stub utype int towlower -> utype int _C;
stub utype int towupper -> utype int _C;
stub @void wcscat -> @void _Dest, @void _Source;
stub int wcscmp -> @void _Str1, @void _Str2;
stub @void wcscpy -> @void _Dest, @void _Source;
stub utype longlong wcscspn -> @void _Str, @void _Control;
stub utype longlong wcslen -> @void _Str;
stub @void wcsncat -> @void _Dest, @void _Source, utype longlong _Count;
stub int wcsncmp -> @void _Str1, @void _Str2, utype longlong _MaxCount;
stub @void wcsncpy -> @void _Dest, @void _Source, utype longlong _Count;
stub utype longlong wcsnlen -> @void _Src, utype longlong _MaxCount;
stub utype longlong wcsspn -> @void _Str, @void _Control;
stub @void wcstok_s -> @void _Str, @void _Delim, @void _Context;
stub int wcstol -> @void _Str, @void _EndPtr, int _Radix;
stub utype longlong wcstombs -> str _Dest, @void _Source, utype longlong _MaxCount;
stub utype int wcstoul -> @void _Str, @void _EndPtr, int _Radix;

!!! Declared by the headers, but with a type the language cannot write:
!!!   NtQueryInformationFile
!!!   NtQueryInformationProcess
!!!   NtQueryInformationThread
!!!   NtQueryObject
!!!   NtQuerySystemInformation
!!!   NtQueryVolumeInformationFile
!!!   NtSetInformationFile
!!!   NtSetInformationKey
!!!   NtSetInformationProcess
!!!   NtSetInformationThread
!!!   NtSetVolumeInformationFile
!!!   RtlQueryHeapInformation
!!!   RtlSetHeapInformation
!!!   __C_specific_handler

!!! No prototype in the headers this build saw. They are here so the
!!! list is complete; uncomment and give the real signature to use one.
!!! NtQueryInformationFile
!!! NtQueryInformationProcess
!!! NtQueryInformationThread
!!! NtQueryObject
!!! NtQuerySystemInformation
!!! NtQueryVolumeInformationFile
!!! NtSetInformationFile
!!! NtSetInformationKey
!!! NtSetInformationProcess
!!! NtSetInformationThread
!!! NtSetVolumeInformationFile
!!! RtlQueryHeapInformation
!!! RtlSetHeapInformation
!!! __C_specific_handler
!!! _itoa_s
!!! _itow_s
!!! _ltoa_s
!!! _ltow_s
!!! _makepath_s
!!! _splitpath_s
!!! _strlwr_s
!!! _strnset_s
!!! _strset_s
!!! _strupr_s
!!! _ultoa_s
!!! _ultow_s
!!! _wcslwr_s
!!! _wcsnset_s
!!! _wcsset_s
!!! _wcsupr_s
!!! _wmakepath_s
!!! _wsplitpath_s
!!! abs
!!! memchr
!!! strcat_s
!!! strchr
!!! strcpy_s
!!! strncat_s
!!! strncpy_s
!!! strpbrk
!!! strrchr
!!! strstr
!!! wcscat_s
!!! wcschr
!!! wcscpy_s
!!! wcsncat_s
!!! wcsncpy_s
!!! wcspbrk
!!! wcsrchr
!!! wcsstr
