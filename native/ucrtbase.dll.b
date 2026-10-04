!~
~  native/ucrtbase.dll.b: the ucrtbase.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/ucrtbase.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/ucrtbase.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `ucrtbase.dll.b` is what produces `meta/ucrtbase.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\ucrtbase.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per ucrtbase.dll export that the headers declare. The
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
!!! 329 declarations here, 0 kept from the hand-checked list above, 62 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub void _Exit -> int a1;
stub int ___mb_cur_max_func;
stub @int __doserrno;
stub int __isascii -> int _C;
stub int __iscsym -> int _C;
stub int __iscsymf -> int _C;
stub int __iswcsym -> utype int _C;
stub int __iswcsymf -> utype int _C;
stub @int __p___argc;
stub @void __p___argv;
stub @void __p___wargv;
stub @void __p__environ;
stub @int __p__fmode;
stub @void __p__pgmptr;
stub @void __p__wenviron;
stub @void __p__wpgmptr;
stub @void __pctype_func;
stub @void __pwctype_func;
stub @void __sys_errlist;
stub @int __sys_nerr;
stub utype longlong __threadhandle;
stub utype int __threadid;
stub int __toascii -> int _C;
stub @void __wcserror -> @void _Str;
stub longlong _abs64 -> longlong x;
stub void _aligned_free -> @void _Memory;
stub @void _aligned_malloc -> utype longlong _Size, utype longlong _Alignment;
stub utype longlong _aligned_msize -> @void _Memory, utype longlong _Alignment, utype longlong _Offset;
stub @void _aligned_offset_malloc -> utype longlong _Size, utype longlong _Alignment, utype longlong _Offset;
stub @void _aligned_offset_realloc -> @void _Memory, utype longlong _Size, utype longlong _Alignment, utype longlong _Offset;
stub @void _aligned_offset_recalloc -> @void _Memory, utype longlong _Count, utype longlong _Size, utype longlong _Alignment, utype longlong _Offset;
stub @void _aligned_realloc -> @void _Memory, utype longlong _Size, utype longlong _Alignment;
stub @void _aligned_recalloc -> @void _Memory, utype longlong _Count, utype longlong _Size, utype longlong _Alignment;
stub int _atodbl -> @void _Result, str _Str;
stub int _atodbl_l -> @void _Result, str _Str, @void _Locale;
stub float _atof_l -> str _String, @void _Locale;
stub int _atoflt -> @void _Result, str _Str;
stub int _atoflt_l -> @void _Result, str _Str, @void _Locale;
stub longlong _atoi64 -> str _String;
stub longlong _atoi64_l -> str _String, @void _Locale;
stub int _atoi_l -> str _Str, @void _Locale;
stub int _atol_l -> str _Str, @void _Locale;
stub int _atoldbl -> @void _Result, str _Str;
stub int _atoldbl_l -> @void _Result, str _Str, @void _Locale;
stub void _beep -> utype int _Frequency, utype int _Duration;
stub utype longlong _byteswap_uint64 -> utype longlong _Int64;
stub utype int _byteswap_ulong -> utype int _Long;
stub utype int _byteswap_ushort -> utype int _Short;
stub int _dupenv_s -> @void _PBuffer, @longlong _PBufferSizeInBytes, str _VarName;
stub str _ecvt -> float _Val, int _NumOfDigits, @int _PtDec, @int _PtSign;
stub int _ecvt_s -> str _DstBuf, utype longlong _Size, float _Val, int _NumOfDights, @int _PtDec, @int _PtSign;
stub @int _errno;
stub void _exit -> int _Code;
stub @void _expand -> @void _Memory, utype longlong _NewSize;
stub str _fcvt -> float _Val, int _NumOfDec, @int _PtDec, @int _PtSign;
stub int _fcvt_s -> str _DstBuf, utype longlong _Size, float _Val, int _NumOfDec, @int _PtDec, @int _PtSign;
stub str _fullpath -> str _FullPath, str _Path, utype longlong _SizeInBytes;
stub str _gcvt -> float _Val, int _NumOfDigits, str _DstBuf;
stub int _gcvt_s -> str _DstBuf, utype longlong _Size, float _Val, int _NumOfDigits;
stub int _get_doserrno -> @int _Value;
stub int _get_errno -> @int _Value;
stub int _get_fmode -> @int _PMode;
stub longlong _get_heap_handle;
stub @void _get_invalid_parameter_handler;
stub int _get_pgmptr -> @void _Value;
stub @void _get_purecall_handler;
stub int _get_wpgmptr -> @void _Value;
stub int _heapchk;
stub int _heapmin;
stub int _heapwalk -> @void _EntryInfo;
stub str _i64toa -> longlong _Val, str _DstBuf, int _Radix;
stub int _i64toa_s -> longlong _Val, str _DstBuf, utype longlong _Size, int _Radix;
stub @void _i64tow -> longlong _Val, @void _DstBuf, int _Radix;
stub int _i64tow_s -> longlong _Val, @void _DstBuf, utype longlong _SizeInWords, int _Radix;
stub void _invalid_parameter_noinfo;
stub void _invalid_parameter_noinfo_noreturn;
stub void _invoke_watson -> @void expression, @void function_name, @void file_name, utype int line_number, utype longlong reserved;
stub int _isalnum_l -> int _C, @void _Locale;
stub int _isalpha_l -> int _C, @void _Locale;
stub int _isblank_l -> int _C, @void _Locale;
stub int _iscntrl_l -> int _C, @void _Locale;
stub int _isctype -> int _C, int _Type;
stub int _isctype_l -> int _C, int _Type, @void _Locale;
stub int _isdigit_l -> int _C, @void _Locale;
stub int _isgraph_l -> int _C, @void _Locale;
stub int _isleadbyte_l -> int _C, @void _Locale;
stub int _islower_l -> int _C, @void _Locale;
stub int _isprint_l -> int _C, @void _Locale;
stub int _ispunct_l -> int _C, @void _Locale;
stub int _isspace_l -> int _C, @void _Locale;
stub int _isupper_l -> int _C, @void _Locale;
stub int _iswalnum_l -> utype int _C, @void _Locale;
stub int _iswalpha_l -> utype int _C, @void _Locale;
stub int _iswblank_l -> utype int _C, @void _Locale;
stub int _iswcntrl_l -> utype int _C, @void _Locale;
stub int _iswctype_l -> utype int _C, utype int _Type, @void _Locale;
stub int _iswdigit_l -> utype int _C, @void _Locale;
stub int _iswgraph_l -> utype int _C, @void _Locale;
stub int _iswlower_l -> utype int _C, @void _Locale;
stub int _iswprint_l -> utype int _C, @void _Locale;
stub int _iswpunct_l -> utype int _C, @void _Locale;
stub int _iswspace_l -> utype int _C, @void _Locale;
stub int _iswupper_l -> utype int _C, @void _Locale;
stub int _iswxdigit_l -> utype int _C, @void _Locale;
stub int _isxdigit_l -> int _C, @void _Locale;
stub str _itoa -> int _Value, str _Dest, int _Radix;
stub @void _itow -> int _Value, @void _Dest, int _Radix;
stub str _ltoa -> int _Value, str _Dest, int _Radix;
stub @void _ltow -> int _Value, @void _Dest, int _Radix;
stub void _makepath -> str _Path, str _Drive, str _Dir, str _Filename, str _Ext;
stub int _mblen_l -> str _Ch, utype longlong _MaxCount, @void _Locale;
stub utype longlong _mbstowcs_l -> @void _Dest, str _Source, utype longlong _MaxCount, @void _Locale;
stub utype longlong _mbstrlen -> str _Str;
stub utype longlong _mbstrlen_l -> str _Str, @void _Locale;
stub int _mbtowc_l -> @void _DstCh, str _SrcCh, utype longlong _SrcSizeInBytes, @void _Locale;
stub @void _memccpy -> @void _Dst, @void _Src, int _Val, utype longlong _MaxCount;
stub int _memicmp -> @void _Buf1, @void _Buf2, utype longlong _Size;
stub int _memicmp_l -> @void _Buf1, @void _Buf2, utype longlong _Size, @void _Locale;
stub utype longlong _msize -> @void _Memory;
stub int _putenv -> str _EnvString;
stub int _putenv_s -> str _Name, str _Value;
stub @void _recalloc -> @void _Memory, utype longlong _Count, utype longlong _Size;
stub int _resetstkoflw;
stub utype int _rotl -> utype int _Val, int _Shift;
stub utype longlong _rotl64 -> utype longlong _Val, int _Shift;
stub utype int _rotr -> utype int _Val, int _Shift;
stub utype longlong _rotr64 -> utype longlong Value, int Shift;
stub void _searchenv -> str _Filename, str _EnvVar, str _ResultPath;
stub int _searchenv_s -> str _Filename, str _EnvVar, str _ResultPath, utype longlong _SizeInBytes;
stub utype int _set_abort_behavior -> utype int _Flags, utype int _Mask;
stub int _set_doserrno -> utype int _Value;
stub int _set_errno -> int _Value;
stub int _set_error_mode -> int _Mode;
stub int _set_fmode -> int _Mode;
stub @void _set_invalid_parameter_handler -> @func _Handler;
stub @void _set_purecall_handler -> @func _Handler;
stub void _seterrormode -> int _Mode;
stub void _sleep -> utype int _Duration;
stub void _splitpath -> str _FullPath, str _Drive, str _Dir, str _Filename, str _Ext;
stub int _strcoll_l -> str _Str1, str _Str2, @void _Locale;
stub str _strdup -> str _Src;
stub str _strerror -> str _ErrMsg;
stub int _stricmp -> str _Str1, str _Str2;
stub int _stricmp_l -> str _Str1, str _Str2, @void _Locale;
stub int _stricoll -> str _Str1, str _Str2;
stub int _stricoll_l -> str _Str1, str _Str2, @void _Locale;
stub str _strlwr -> str _String;
stub int _strncoll -> str _Str1, str _Str2, utype longlong _MaxCount;
stub int _strncoll_l -> str _Str1, str _Str2, utype longlong _MaxCount, @void _Locale;
stub int _strnicmp -> str _Str1, str _Str2, utype longlong _MaxCount;
stub int _strnicmp_l -> str _Str1, str _Str2, utype longlong _MaxCount, @void _Locale;
stub int _strnicoll -> str _Str1, str _Str2, utype longlong _MaxCount;
stub int _strnicoll_l -> str _Str1, str _Str2, utype longlong _MaxCount, @void _Locale;
stub str _strnset -> str _Str, int _Val, utype longlong _MaxCount;
stub str _strrev -> str _Str;
stub str _strset -> str _Str, int _Val;
stub float _strtod_l -> str _Str, @void _EndPtr, @void _Locale;
stub float _strtof_l -> str _Str, @void _EndPtr, @void _Locale;
stub longlong _strtoi64 -> str _String, @void _EndPtr, int _Radix;
stub longlong _strtoi64_l -> str _String, @void _EndPtr, int _Radix, @void _Locale;
stub int _strtol_l -> str _Str, @void _EndPtr, int _Radix, @void _Locale;
stub utype longlong _strtoui64 -> str _String, @void _EndPtr, int _Radix;
stub utype longlong _strtoui64_l -> str _String, @void _EndPtr, int _Radix, @void _Locale;
stub utype int _strtoul_l -> str _Str, @void _EndPtr, int _Radix, @void _Locale;
stub str _strupr -> str _String;
stub str _strupr_l -> str _String, @void _Locale;
stub utype longlong _strxfrm_l -> str _Dst, str _Src, utype longlong _MaxCount, @void _Locale;
stub void _swab -> str _Buf1, str _Buf2, int _SizeInBytes;
stub int _tolower -> int _C;
stub int _tolower_l -> int _C, @void _Locale;
stub int _toupper -> int _C;
stub int _toupper_l -> int _C, @void _Locale;
stub utype int _towlower_l -> utype int _C, @void _Locale;
stub utype int _towupper_l -> utype int _C, @void _Locale;
stub str _ui64toa -> utype longlong _Val, str _DstBuf, int _Radix;
stub int _ui64toa_s -> utype longlong _Val, str _DstBuf, utype longlong _Size, int _Radix;
stub @void _ui64tow -> utype longlong _Val, @void _DstBuf, int _Radix;
stub int _ui64tow_s -> utype longlong _Val, @void _DstBuf, utype longlong _SizeInWords, int _Radix;
stub str _ultoa -> utype int _Value, str _Dest, int _Radix;
stub @void _ultow -> utype int _Value, @void _Dest, int _Radix;
stub int _wcscoll_l -> @void _Str1, @void _Str2, @void _Locale;
stub @void _wcsdup -> @void _Str;
stub @void _wcserror -> int _ErrNum;
stub int _wcsicmp -> @void _Str1, @void _Str2;
stub int _wcsicmp_l -> @void _Str1, @void _Str2, @void _Locale;
stub int _wcsicoll -> @void _Str1, @void _Str2;
stub int _wcsicoll_l -> @void _Str1, @void _Str2, @void _Locale;
stub @void _wcslwr -> @void _String;
stub @void _wcslwr_l -> @void _String, @void _Locale;
stub int _wcsncoll -> @void _Str1, @void _Str2, utype longlong _MaxCount;
stub int _wcsncoll_l -> @void _Str1, @void _Str2, utype longlong _MaxCount, @void _Locale;
stub int _wcsnicmp -> @void _Str1, @void _Str2, utype longlong _MaxCount;
stub int _wcsnicmp_l -> @void _Str1, @void _Str2, utype longlong _MaxCount, @void _Locale;
stub int _wcsnicoll -> @void _Str1, @void _Str2, utype longlong _MaxCount;
stub int _wcsnicoll_l -> @void _Str1, @void _Str2, utype longlong _MaxCount, @void _Locale;
stub @void _wcsrev -> @void _Str;
stub float _wcstod_l -> @void _Str, @void _EndPtr, @void _Locale;
stub float _wcstof_l -> @void _Str, @void _EndPtr, @void _Locale;
stub longlong _wcstoi64 -> @void _Str, @void _EndPtr, int _Radix;
stub longlong _wcstoi64_l -> @void _Str, @void _EndPtr, int _Radix, @void _Locale;
stub int _wcstol_l -> @void _Str, @void _EndPtr, int _Radix, @void _Locale;
stub utype longlong _wcstombs_l -> str _Dest, @void _Source, utype longlong _MaxCount, @void _Locale;
stub utype longlong _wcstoui64 -> @void _Str, @void _EndPtr, int _Radix;
stub utype longlong _wcstoui64_l -> @void _Str, @void _EndPtr, int _Radix, @void _Locale;
stub utype int _wcstoul_l -> @void _Str, @void _EndPtr, int _Radix, @void _Locale;
stub @void _wcsupr -> @void _String;
stub @void _wcsupr_l -> @void _String, @void _Locale;
stub utype longlong _wcsxfrm_l -> @void _Dst, @void _Src, utype longlong _MaxCount, @void _Locale;
stub int _wdupenv_s -> @void _Buffer, @longlong _BufferSizeInWords, @void _VarName;
stub @void _wfullpath -> @void _FullPath, @void _Path, utype longlong _SizeInWords;
stub @void _wgetenv -> @void _VarName;
stub void _wmakepath -> @void _ResultPath, @void _Drive, @void _Dir, @void _Filename, @void _Ext;
stub void _wperror -> @void _ErrMsg;
stub int _wputenv -> @void _EnvString;
stub int _wputenv_s -> @void _Name, @void _Value;
stub void _wsearchenv -> @void _Filename, @void _EnvVar, @void _ResultPath;
stub void _wsplitpath -> @void _FullPath, @void _Drive, @void _Dir, @void _Filename, @void _Ext;
stub int _wsystem -> @void _Command;
stub float _wtof -> @void _Str;
stub float _wtof_l -> @void _Str, @void _Locale;
stub int _wtoi -> @void _Str;
stub longlong _wtoi64 -> @void _Str;
stub longlong _wtoi64_l -> @void _Str, @void _Locale;
stub int _wtoi_l -> @void _Str, @void _Locale;
stub int _wtol -> @void _Str;
stub int _wtol_l -> @void _Str, @void _Locale;
stub void abort;
stub float atof -> str _String;
stub int atoi -> str _Str;
stub int atol -> str _Str;
stub longlong atoll -> str a1;
stub @void bsearch -> @void _Key, @void _Base, utype longlong _NumOfElements, utype longlong _SizeOfElements, @func a5;
stub @void bsearch_s -> @void _Key, @void _Base, utype longlong _NumOfElements, utype longlong _SizeOfElements, @func a5, @void _Context;
stub @void calloc -> utype longlong _NumOfElements, utype longlong _SizeOfElements;
stub void exit -> int _Code;
stub void free -> @void _Memory;
stub str getenv -> str _VarName;
stub int is_wctype -> utype int _C, utype int _Type;
stub int isalnum -> int _C;
stub int isalpha -> int _C;
stub int isblank -> int _C;
stub int iscntrl -> int _C;
stub int isdigit -> int _C;
stub int isgraph -> int _C;
stub int isleadbyte -> int _C;
stub int islower -> int _C;
stub int isprint -> int _C;
stub int ispunct -> int _C;
stub int isspace -> int _C;
stub int isupper -> int _C;
stub int iswalnum -> utype int _C;
stub int iswalpha -> utype int _C;
stub int iswascii -> utype int _C;
stub int iswblank -> utype int _C;
stub int iswcntrl -> utype int _C;
stub int iswctype -> utype int _C, utype int _Type;
stub int iswdigit -> utype int _C;
stub int iswgraph -> utype int _C;
stub int iswlower -> utype int _C;
stub int iswprint -> utype int _C;
stub int iswpunct -> utype int _C;
stub int iswspace -> utype int _C;
stub int iswupper -> utype int _C;
stub int iswxdigit -> utype int _C;
stub int isxdigit -> int _C;
stub int labs -> int _X;
stub longlong llabs -> longlong _j;
stub @void malloc -> utype longlong _Size;
stub int mblen -> str _Ch, utype longlong _MaxCount;
stub utype longlong mbstowcs -> @void _Dest, str _Source, utype longlong _MaxCount;
stub int mbtowc -> @void _DstCh, str _SrcCh, utype longlong _SrcSizeInBytes;
stub int memcmp -> @void _Buf1, @void _Buf2, utype longlong _Size;
stub @void memcpy -> @void _Dst, @void _Src, utype longlong _Size;
stub int memcpy_s -> @void _dest, utype longlong _numberOfElements, @void _src, utype longlong _count;
stub @void memmove -> @void _Dst, @void _Src, utype longlong _Size;
stub int memmove_s -> @void _dest, utype longlong _numberOfElements, @void _src, utype longlong _count;
stub @void memset -> @void _Dst, int _Val, utype longlong _Size;
stub void perror -> str _ErrMsg;
stub void qsort -> @void _Base, utype longlong _NumOfElements, utype longlong _SizeOfElements, @func a4;
stub void qsort_s -> @void _Base, utype longlong _NumOfElements, utype longlong _SizeOfElements, @func a4, @void _Context;
stub int rand;
stub @void realloc -> @void _Memory, utype longlong _NewSize;
stub void srand -> utype int _Seed;
stub str strcat -> str _Dest, str _Source;
stub int strcmp -> str _Str1, str _Str2;
stub int strcoll -> str _Str1, str _Str2;
stub str strcpy -> str _Dest, str _Source;
stub utype longlong strcspn -> str _Str, str _Control;
stub str strerror -> int a1;
stub utype longlong strlen -> str _Str;
stub str strncat -> str _Dest, str _Source, utype longlong _Count;
stub int strncmp -> str _Str1, str _Str2, utype longlong _MaxCount;
stub str strncpy -> str _Dest, str _Source, utype longlong _Count;
stub utype longlong strnlen -> str _Str, utype longlong _MaxCount;
stub utype longlong strspn -> str _Str, str _Control;
stub float strtod -> str _Str, @void _EndPtr;
stub float strtof -> str _Str, @void _EndPtr;
stub str strtok -> str _Str, str _Delim;
stub str strtok_s -> str _Str, str _Delim, @void _Context;
stub int strtol -> str _Str, @void _EndPtr, int _Radix;
stub float strtold -> str a1, @void a2;
stub longlong strtoll -> str a1, @void a2, int a3;
stub utype int strtoul -> str _Str, @void _EndPtr, int _Radix;
stub utype longlong strtoull -> str a1, @void a2, int a3;
stub utype longlong strxfrm -> str _Dst, str _Src, utype longlong _MaxCount;
stub int system -> str _Command;
stub int tolower -> int _C;
stub int toupper -> int _C;
stub utype int towlower -> utype int _C;
stub utype int towupper -> utype int _C;
stub @void wcscat -> @void _Dest, @void _Source;
stub int wcscmp -> @void _Str1, @void _Str2;
stub int wcscoll -> @void _Str1, @void _Str2;
stub @void wcscpy -> @void _Dest, @void _Source;
stub utype longlong wcscspn -> @void _Str, @void _Control;
stub utype longlong wcslen -> @void _Str;
stub @void wcsncat -> @void _Dest, @void _Source, utype longlong _Count;
stub int wcsncmp -> @void _Str1, @void _Str2, utype longlong _MaxCount;
stub @void wcsncpy -> @void _Dest, @void _Source, utype longlong _Count;
stub utype longlong wcsnlen -> @void _Src, utype longlong _MaxCount;
stub utype longlong wcsspn -> @void _Str, @void _Control;
stub float wcstod -> @void _Str, @void _EndPtr;
stub float wcstof -> @void _Str, @void _EndPtr;
stub @void wcstok_s -> @void _Str, @void _Delim, @void _Context;
stub int wcstol -> @void _Str, @void _EndPtr, int _Radix;
stub float wcstold -> @void a1, @void a2;
stub utype longlong wcstombs -> str _Dest, @void _Source, utype longlong _MaxCount;
stub utype int wcstoul -> @void _Str, @void _EndPtr, int _Radix;
stub utype longlong wcsxfrm -> @void _Dst, @void _Src, utype longlong _MaxCount;

!!! Declared by the headers, but with a type the language cannot write:
!!!   __C_specific_handler
!!!   _wcsnset
!!!   _wcsset
!!!   _wctomb_l
!!!   _wctomb_s_l
!!!   ldiv
!!!   lldiv
!!!   wctomb
!!!   wctomb_s

!!! No prototype in the headers this build saw. They are here so the
!!! list is complete; uncomment and give the real signature to use one.
!!! __C_specific_handler
!!! __wcserror_s
!!! _itoa_s
!!! _itow_s
!!! _ltoa_s
!!! _ltow_s
!!! _makepath_s
!!! _mbstowcs_s_l
!!! _splitpath_s
!!! _strerror_s
!!! _strlwr_s
!!! _strlwr_s_l
!!! _strnset_s
!!! _strset_s
!!! _strupr_s
!!! _strupr_s_l
!!! _ultoa_s
!!! _ultow_s
!!! _wcserror_s
!!! _wcslwr_s
!!! _wcslwr_s_l
!!! _wcsnset
!!! _wcsnset_s
!!! _wcsset
!!! _wcsset_s
!!! _wcstombs_s_l
!!! _wcsupr_s
!!! _wcsupr_s_l
!!! _wctomb_l
!!! _wctomb_s_l
!!! _wgetenv_s
!!! _wmakepath_s
!!! _wsearchenv_s
!!! _wsplitpath_s
!!! abs
!!! div
!!! getenv_s
!!! ldiv
!!! lldiv
!!! mbstowcs_s
!!! memchr
!!! strcat_s
!!! strchr
!!! strcpy_s
!!! strerror_s
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
!!! wcstok
!!! wcstombs_s
!!! wctomb
!!! wctomb_s
