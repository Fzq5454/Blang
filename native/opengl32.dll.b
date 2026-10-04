!~
~  native/opengl32.dll.b: the opengl32.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/opengl32.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/opengl32.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `opengl32.dll.b` is what produces `meta/opengl32.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\opengl32.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per opengl32.dll export that the headers declare. The
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
!!! 19 declarations here, 0 kept from the hand-checked list above, 0 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub int wglCopyContext -> @void a1, @void a2, utype int a3;
stub @void wglCreateContext -> @void a1;
stub @void wglCreateLayerContext -> @void a1, int a2;
stub int wglDeleteContext -> @void a1;
stub int wglDescribeLayerPlane -> @void a1, int a2, int a3, utype int a4, @void a5;
stub @void wglGetCurrentContext;
stub @void wglGetCurrentDC;
stub int wglGetLayerPaletteEntries -> @void a1, int a2, int a3, int a4, @int a5;
stub @longlong wglGetProcAddress -> str a1;
stub int wglMakeCurrent -> @void a1, @void a2;
stub int wglRealizeLayerPalette -> @void a1, int a2, int a3;
stub int wglSetLayerPaletteEntries -> @void a1, int a2, int a3, int a4, @int COLORREF;
stub int wglShareLists -> @void a1, @void a2;
stub int wglSwapLayerBuffers -> @void a1, utype int a2;
stub utype int wglSwapMultipleBuffers -> utype int a1, @void WGLSWAP;
stub int wglUseFontBitmapsA -> @void a1, utype int a2, utype int a3, utype int a4;
stub int wglUseFontBitmapsW -> @void a1, utype int a2, utype int a3, utype int a4;
stub int wglUseFontOutlinesA -> @void a1, utype int a2, utype int a3, utype int a4, float a5, float a6, int a7, @void a8;
stub int wglUseFontOutlinesW -> @void a1, utype int a2, utype int a3, utype int a4, float a5, float a6, int a7, @void a8;
