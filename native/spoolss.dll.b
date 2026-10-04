!~
~  native/spoolss.dll.b: the spoolss.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/spoolss.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/spoolss.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `spoolss.dll.b` is what produces `meta/spoolss.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\spoolss.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per spoolss.dll export that the headers declare. The
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
!!! 65 declarations here, 0 kept from the hand-checked list above, 1 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub int AbortPrinter -> @void hPrinter;
stub int AddFormW -> @void hPrinter, utype int Level, @char pForm;
stub int AddJobW -> @void hPrinter, utype int Level, @char pData, utype int cbBuf, @int pcbNeeded;
stub int AddMonitorW -> @void pName, utype int Level, @char pMonitorInfo;
stub int AddPortW -> @void pName, @void hWnd, @void pMonitorName;
stub int AddPrintProcessorW -> @void pName, @void pEnvironment, @void pPathName, @void pPrintProcessorName;
stub int AddPrintProvidorW -> @void pName, utype int level, @char pProvidorInfo;
stub int AddPrinterConnectionW -> @void pName;
stub int AddPrinterDriverExW -> @void pName, utype int Level, @char pDriverInfo, utype int dwFileCopyFlags;
stub int AddPrinterDriverW -> @void pName, utype int Level, @char pDriverInfo;
stub @void AddPrinterW -> @void pName, utype int Level, @char pPrinter;
stub int ClosePrinter -> @void hPrinter;
stub int ConfigurePortW -> @void pName, @void hWnd, @void pPortName;
stub int DeleteFormW -> @void hPrinter, @void pFormName;
stub int DeleteMonitorW -> @void pName, @void pEnvironment, @void pMonitorName;
stub int DeletePortW -> @void pName, @void hWnd, @void pPortName;
stub int DeletePrintProcessorW -> @void pName, @void pEnvironment, @void pPrintProcessorName;
stub int DeletePrintProvidorW -> @void pName, @void pEnvironment, @void pPrintProvidorName;
stub int DeletePrinter -> @void hPrinter;
stub int DeletePrinterConnectionW -> @void pName;
stub utype int DeletePrinterDataExW -> @void hPrinter, @void pKeyName, @void pValueName;
stub utype int DeletePrinterDataW -> @void hPrinter, @void pValueName;
stub int DeletePrinterDriverExW -> @void pName, @void pEnvironment, @void pDriverName, utype int dwDeleteFlag, utype int dwVersionFlag;
stub int DeletePrinterDriverW -> @void pName, @void pEnvironment, @void pDriverName;
stub utype int DeletePrinterKeyW -> @void hPrinter, @void pKeyName;
stub int EndDocPrinter -> @void hPrinter;
stub int EndPagePrinter -> @void hPrinter;
stub int EnumFormsW -> @void hPrinter, utype int Level, @char pForm, utype int cbBuf, @int pcbNeeded, @int pcReturned;
stub int EnumJobsW -> @void hPrinter, utype int FirstJob, utype int NoJobs, utype int Level, @char pJob, utype int cbBuf, @int pcbNeeded, @int pcReturned;
stub int EnumMonitorsW -> @void pName, utype int Level, @char pMonitor, utype int cbBuf, @int pcbNeeded, @int pcReturned;
stub int EnumPortsW -> @void pName, utype int Level, @char pPorts, utype int cbBuf, @int pcbNeeded, @int pcReturned;
stub int EnumPrintProcessorDatatypesW -> @void pName, @void pPrintProcessorName, utype int Level, @char pDatatypes, utype int cbBuf, @int pcbNeeded, @int pcReturned;
stub int EnumPrintProcessorsW -> @void pName, @void pEnvironment, utype int Level, @char pPrintProcessorInfo, utype int cbBuf, @int pcbNeeded, @int pcReturned;
stub utype int EnumPrinterDataExW -> @void hPrinter, @void pKeyName, @char pEnumValues, utype int cbEnumValues, @int pcbEnumValues, @int pnEnumValues;
stub utype int EnumPrinterDataW -> @void hPrinter, utype int dwIndex, @void pValueName, utype int cbValueName, @int pcbValueName, @int pType, @char pData, utype int cbData, @int pcbData;
stub int EnumPrinterDriversW -> @void pName, @void pEnvironment, utype int Level, @char pDriverInfo, utype int cbBuf, @int pcbNeeded, @int pcReturned;
stub utype int EnumPrinterKeyW -> @void hPrinter, @void pKeyName, @void pSubkey, utype int cbSubkey, @int pcbSubkey;
stub int EnumPrintersW -> utype int Flags, @void Name, utype int Level, @char pPrinterEnum, utype int cbBuf, @int pcbNeeded, @int pcReturned;
stub int FindClosePrinterChangeNotification -> @void hChange;
stub int FlushPrinter -> @void hPrinter, @void pBuf, utype int cbBuf, @int pcWritten, utype int cSleep;
stub int GetFormW -> @void hPrinter, @void pFormName, utype int Level, @char pForm, utype int cbBuf, @int pcbNeeded;
stub int GetJobW -> @void hPrinter, utype int JobId, utype int Level, @char pJob, utype int cbBuf, @int pcbNeeded;
stub int GetPrintProcessorDirectoryW -> @void pName, @void pEnvironment, utype int Level, @char pPrintProcessorInfo, utype int cbBuf, @int pcbNeeded;
stub utype int GetPrinterDataExW -> @void hPrinter, @void pKeyName, @void pValueName, @int pType, @char pData, utype int nSize, @int pcbNeeded;
stub utype int GetPrinterDataW -> @void hPrinter, @void pValueName, @int pType, @char pData, utype int nSize, @int pcbNeeded;
stub int GetPrinterDriverDirectoryW -> @void pName, @void pEnvironment, utype int Level, @char pDriverDirectory, utype int cbBuf, @int pcbNeeded;
stub int GetPrinterDriverW -> @void hPrinter, @void pEnvironment, utype int Level, @char pDriverInfo, utype int cbBuf, @int pcbNeeded;
stub int GetPrinterW -> @void hPrinter, utype int Level, @char pPrinter, utype int cbBuf, @int pcbNeeded;
stub int OpenPrinter2W -> @void pPrinterName, @void phPrinter, @void pDefault, @void pOptions;
stub int OpenPrinterW -> @void pPrinterName, @void phPrinter, @void pDefault;
stub utype int PrinterMessageBoxW -> @void hPrinter, utype int Error, @void hWnd, @void pText, @void pCaption, utype int dwType;
stub int ReadPrinter -> @void hPrinter, @void pBuf, utype int cbBuf, @int pNoBytesRead;
stub int ResetPrinterW -> @void hPrinter, @void pDefault;
stub int ScheduleJob -> @void hPrinter, utype int JobId;
stub int SetFormW -> @void hPrinter, @void pFormName, utype int Level, @char pForm;
stub int SetJobW -> @void hPrinter, utype int JobId, utype int Level, @char pJob, utype int Command;
stub int SetPortW -> @void pName, @void pPortName, utype int dwLevel, @char pPortInfo;
stub utype int SetPrinterDataExW -> @void hPrinter, @void pKeyName, @void pValueName, utype int Type, @char pData, utype int cbData;
stub utype int SetPrinterDataW -> @void hPrinter, @void pValueName, utype int Type, @char pData, utype int cbData;
stub int SetPrinterW -> @void hPrinter, utype int Level, @char pPrinter, utype int Command;
stub utype int StartDocPrinterW -> @void hPrinter, utype int Level, @char pDocInfo;
stub int StartPagePrinter -> @void hPrinter;
stub utype int WaitForPrinterChange -> @void hPrinter, utype int Flags;
stub int WritePrinter -> @void hPrinter, @void pBuf, utype int cbBuf, @int pcWritten;
stub int XcvDataW -> @void hXcv, @void pszDataName, @char pInputData, utype int cbInputData, @char pOutputData, utype int cbOutputData, @int pcbOutputNeeded, @int pdwStatus;

!!! Declared by the headers, but with a type the language cannot write:
!!!   ReportJobProcessingProgress

!!! No prototype in the headers this build saw. They are here so the
!!! list is complete; uncomment and give the real signature to use one.
!!! ReportJobProcessingProgress
