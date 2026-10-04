!~
~  native/winmmbase.dll.b: the winmmbase.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/winmmbase.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/winmmbase.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `winmmbase.dll.b` is what produces `meta/winmmbase.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\winmmbase.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per winmmbase.dll export that the headers declare. The
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
!!! 132 declarations here, 0 kept from the hand-checked list above, 0 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub longlong CloseDriver -> @void hDriver, longlong lParam1, longlong lParam2;
stub longlong DefDriverProc -> utype longlong dwDriverIdentifier, @void hdrvr, utype int uMsg, longlong lParam1, longlong lParam2;
stub int DriverCallback -> utype longlong dwCallback, utype int dwFlags, @void hDevice, utype int dwMsg, utype longlong dwUser, utype longlong dwParam1, utype longlong dwParam2;
stub @void DrvGetModuleHandle -> @void hDriver;
stub @void GetDriverModuleHandle -> @void hDriver;
stub @void OpenDriver -> @void szDriverName, @void szSectionName, longlong lParam2;
stub longlong SendDriverMessage -> @void hDriver, utype int message, longlong lParam1, longlong lParam2;
stub utype int auxGetDevCapsA -> utype longlong uDeviceID, @void pac, utype int cbac;
stub utype int auxGetDevCapsW -> utype longlong uDeviceID, @void pac, utype int cbac;
stub utype int auxGetNumDevs;
stub utype int auxGetVolume -> utype int uDeviceID, @int pdwVolume;
stub utype int auxOutMessage -> utype int uDeviceID, utype int uMsg, utype longlong dw1, utype longlong dw2;
stub utype int auxSetVolume -> utype int uDeviceID, utype int dwVolume;
stub utype int midiConnect -> @void hmi, @void hmo, @void pReserved;
stub utype int midiDisconnect -> @void hmi, @void hmo, @void pReserved;
stub utype int midiInAddBuffer -> @void hmi, @void pmh, utype int cbmh;
stub utype int midiInClose -> @void hmi;
stub utype int midiInGetDevCapsA -> utype longlong uDeviceID, @void pmic, utype int cbmic;
stub utype int midiInGetDevCapsW -> utype longlong uDeviceID, @void pmic, utype int cbmic;
stub utype int midiInGetErrorTextA -> utype int mmrError, str pszText, utype int cchText;
stub utype int midiInGetErrorTextW -> utype int mmrError, @void pszText, utype int cchText;
stub utype int midiInGetID -> @void hmi, @int puDeviceID;
stub utype int midiInGetNumDevs;
stub utype int midiInMessage -> @void hmi, utype int uMsg, utype longlong dw1, utype longlong dw2;
stub utype int midiInOpen -> @void phmi, utype int uDeviceID, utype longlong dwCallback, utype longlong dwInstance, utype int fdwOpen;
stub utype int midiInPrepareHeader -> @void hmi, @void pmh, utype int cbmh;
stub utype int midiInReset -> @void hmi;
stub utype int midiInStart -> @void hmi;
stub utype int midiInStop -> @void hmi;
stub utype int midiInUnprepareHeader -> @void hmi, @void pmh, utype int cbmh;
stub utype int midiOutCacheDrumPatches -> @void hmo, utype int uPatch, @int pwkya, utype int fuCache;
stub utype int midiOutCachePatches -> @void hmo, utype int uBank, @int pwpa, utype int fuCache;
stub utype int midiOutClose -> @void hmo;
stub utype int midiOutGetDevCapsA -> utype longlong uDeviceID, @void pmoc, utype int cbmoc;
stub utype int midiOutGetDevCapsW -> utype longlong uDeviceID, @void pmoc, utype int cbmoc;
stub utype int midiOutGetErrorTextA -> utype int mmrError, str pszText, utype int cchText;
stub utype int midiOutGetErrorTextW -> utype int mmrError, @void pszText, utype int cchText;
stub utype int midiOutGetID -> @void hmo, @int puDeviceID;
stub utype int midiOutGetNumDevs;
stub utype int midiOutGetVolume -> @void hmo, @int pdwVolume;
stub utype int midiOutLongMsg -> @void hmo, @void pmh, utype int cbmh;
stub utype int midiOutMessage -> @void hmo, utype int uMsg, utype longlong dw1, utype longlong dw2;
stub utype int midiOutOpen -> @void phmo, utype int uDeviceID, utype longlong dwCallback, utype longlong dwInstance, utype int fdwOpen;
stub utype int midiOutPrepareHeader -> @void hmo, @void pmh, utype int cbmh;
stub utype int midiOutReset -> @void hmo;
stub utype int midiOutSetVolume -> @void hmo, utype int dwVolume;
stub utype int midiOutShortMsg -> @void hmo, utype int dwMsg;
stub utype int midiOutUnprepareHeader -> @void hmo, @void pmh, utype int cbmh;
stub utype int midiStreamClose -> @void hms;
stub utype int midiStreamOpen -> @void phms, @int puDeviceID, utype int cMidi, utype longlong dwCallback, utype longlong dwInstance, utype int fdwOpen;
stub utype int midiStreamOut -> @void hms, @void pmh, utype int cbmh;
stub utype int midiStreamPause -> @void hms;
stub utype int midiStreamPosition -> @void hms, @void lpmmt, utype int cbmmt;
stub utype int midiStreamProperty -> @void hms, @char lppropdata, utype int dwProperty;
stub utype int midiStreamRestart -> @void hms;
stub utype int midiStreamStop -> @void hms;
stub utype int mixerClose -> @void hmx;
stub utype int mixerGetControlDetailsA -> @void hmxobj, @void pmxcd, utype int fdwDetails;
stub utype int mixerGetControlDetailsW -> @void hmxobj, @void pmxcd, utype int fdwDetails;
stub utype int mixerGetDevCapsA -> utype longlong uMxId, @void pmxcaps, utype int cbmxcaps;
stub utype int mixerGetDevCapsW -> utype longlong uMxId, @void pmxcaps, utype int cbmxcaps;
stub utype int mixerGetID -> @void hmxobj, @int puMxId, utype int fdwId;
stub utype int mixerGetLineControlsA -> @void hmxobj, @void pmxlc, utype int fdwControls;
stub utype int mixerGetLineControlsW -> @void hmxobj, @void pmxlc, utype int fdwControls;
stub utype int mixerGetLineInfoA -> @void hmxobj, @void pmxl, utype int fdwInfo;
stub utype int mixerGetLineInfoW -> @void hmxobj, @void pmxl, utype int fdwInfo;
stub utype int mixerGetNumDevs;
stub utype int mixerMessage -> @void hmx, utype int uMsg, utype longlong dwParam1, utype longlong dwParam2;
stub utype int mixerOpen -> @void phmx, utype int uMxId, utype longlong dwCallback, utype longlong dwInstance, utype int fdwOpen;
stub utype int mixerSetControlDetails -> @void hmxobj, @void pmxcd, utype int fdwDetails;
stub utype int mmDrvInstall -> @void hDriver, @void wszDrvEntry, @func drvMessage, utype int wFlags;
stub utype int mmioAdvance -> @void hmmio, @void pmmioinfo, utype int fuAdvance;
stub utype int mmioAscend -> @void hmmio, @void pmmcki, utype int fuAscend;
stub utype int mmioClose -> @void hmmio, utype int fuClose;
stub utype int mmioCreateChunk -> @void hmmio, @void pmmcki, utype int fuCreate;
stub utype int mmioDescend -> @void hmmio, @void pmmcki, @void pmmckiParent, utype int fuDescend;
stub utype int mmioFlush -> @void hmmio, utype int fuFlush;
stub utype int mmioGetInfo -> @void hmmio, @void pmmioinfo, utype int fuInfo;
stub @longlong mmioInstallIOProcA -> utype int fccIOProc, @func pIOProc, utype int dwFlags;
stub @longlong mmioInstallIOProcW -> utype int fccIOProc, @func pIOProc, utype int dwFlags;
stub @void mmioOpenA -> str pszFileName, @void pmmioinfo, utype int fdwOpen;
stub @void mmioOpenW -> @void pszFileName, @void pmmioinfo, utype int fdwOpen;
stub int mmioRead -> @void hmmio, str pch, int cch;
stub utype int mmioRenameA -> str pszFileName, str pszNewFileName, @void pmmioinfo, utype int fdwRename;
stub utype int mmioRenameW -> @void pszFileName, @void pszNewFileName, @void pmmioinfo, utype int fdwRename;
stub int mmioSeek -> @void hmmio, int lOffset, int iOrigin;
stub longlong mmioSendMessage -> @void hmmio, utype int uMsg, longlong lParam1, longlong lParam2;
stub utype int mmioSetBuffer -> @void hmmio, str pchBuffer, int cchBuffer, utype int fuBuffer;
stub utype int mmioSetInfo -> @void hmmio, @void pmmioinfo, utype int fuInfo;
stub utype int mmioStringToFOURCCA -> str sz, utype int uFlags;
stub utype int mmioStringToFOURCCW -> @void sz, utype int uFlags;
stub int mmioWrite -> @void hmmio, str pch, int cch;
stub int sndOpenSound -> @void EventName, @void AppName, int Flags, @void FileHandle;
stub utype int waveInAddBuffer -> @void hwi, @void pwh, utype int cbwh;
stub utype int waveInClose -> @void hwi;
stub utype int waveInGetDevCapsA -> utype longlong uDeviceID, @void pwic, utype int cbwic;
stub utype int waveInGetDevCapsW -> utype longlong uDeviceID, @void pwic, utype int cbwic;
stub utype int waveInGetErrorTextA -> utype int mmrError, str pszText, utype int cchText;
stub utype int waveInGetErrorTextW -> utype int mmrError, @void pszText, utype int cchText;
stub utype int waveInGetID -> @void hwi, @int puDeviceID;
stub utype int waveInGetNumDevs;
stub utype int waveInGetPosition -> @void hwi, @void pmmt, utype int cbmmt;
stub utype int waveInMessage -> @void hwi, utype int uMsg, utype longlong dw1, utype longlong dw2;
stub utype int waveInOpen -> @void phwi, utype int uDeviceID, @void pwfx, utype longlong dwCallback, utype longlong dwInstance, utype int fdwOpen;
stub utype int waveInPrepareHeader -> @void hwi, @void pwh, utype int cbwh;
stub utype int waveInReset -> @void hwi;
stub utype int waveInStart -> @void hwi;
stub utype int waveInStop -> @void hwi;
stub utype int waveInUnprepareHeader -> @void hwi, @void pwh, utype int cbwh;
stub utype int waveOutBreakLoop -> @void hwo;
stub utype int waveOutClose -> @void hwo;
stub utype int waveOutGetDevCapsA -> utype longlong uDeviceID, @void pwoc, utype int cbwoc;
stub utype int waveOutGetDevCapsW -> utype longlong uDeviceID, @void pwoc, utype int cbwoc;
stub utype int waveOutGetErrorTextA -> utype int mmrError, str pszText, utype int cchText;
stub utype int waveOutGetErrorTextW -> utype int mmrError, @void pszText, utype int cchText;
stub utype int waveOutGetID -> @void hwo, @int puDeviceID;
stub utype int waveOutGetNumDevs;
stub utype int waveOutGetPitch -> @void hwo, @int pdwPitch;
stub utype int waveOutGetPlaybackRate -> @void hwo, @int pdwRate;
stub utype int waveOutGetPosition -> @void hwo, @void pmmt, utype int cbmmt;
stub utype int waveOutGetVolume -> @void hwo, @int pdwVolume;
stub utype int waveOutMessage -> @void hwo, utype int uMsg, utype longlong dw1, utype longlong dw2;
stub utype int waveOutOpen -> @void phwo, utype int uDeviceID, @void pwfx, utype longlong dwCallback, utype longlong dwInstance, utype int fdwOpen;
stub utype int waveOutPause -> @void hwo;
stub utype int waveOutPrepareHeader -> @void hwo, @void pwh, utype int cbwh;
stub utype int waveOutReset -> @void hwo;
stub utype int waveOutRestart -> @void hwo;
stub utype int waveOutSetPitch -> @void hwo, utype int dwPitch;
stub utype int waveOutSetPlaybackRate -> @void hwo, utype int dwRate;
stub utype int waveOutSetVolume -> @void hwo, utype int dwVolume;
stub utype int waveOutUnprepareHeader -> @void hwo, @void pwh, utype int cbwh;
stub utype int waveOutWrite -> @void hwo, @void pwh, utype int cbwh;
