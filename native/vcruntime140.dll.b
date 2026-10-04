!~
~  native/vcruntime140.dll.b: the vcruntime140.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/vcruntime140.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/vcruntime140.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `vcruntime140.dll.b` is what produces `meta/vcruntime140.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\vcruntime140.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per vcruntime140.dll export that the headers declare. The
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
!!! 6 declarations here, 0 kept from the hand-checked list above, 8 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub @void _get_purecall_handler;
stub @void _set_purecall_handler -> @func _Handler;
stub int memcmp -> @void _Buf1, @void _Buf2, utype longlong _Size;
stub @void memcpy -> @void _Dst, @void _Src, utype longlong _Size;
stub @void memmove -> @void _Dst, @void _Src, utype longlong _Size;
stub @void memset -> @void _Dst, int _Val, utype longlong _Size;

!!! Declared by the headers, but with a type the language cannot write:
!!!   __C_specific_handler

!!! No prototype in the headers this build saw. They are here so the
!!! list is complete; uncomment and give the real signature to use one.
!!! __C_specific_handler
!!! memchr
!!! strchr
!!! strrchr
!!! strstr
!!! wcschr
!!! wcsrchr
!!! wcsstr
