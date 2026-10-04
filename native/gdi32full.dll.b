!~
~  native/gdi32full.dll.b: the gdi32full.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/gdi32full.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/gdi32full.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `gdi32full.dll.b` is what produces `meta/gdi32full.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\gdi32full.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per gdi32full.dll export that the headers declare. The
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
!!! 317 declarations here, 0 kept from the hand-checked list above, 1 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub int AbortPath -> @void hdc;
stub @void AddFontMemResourceEx -> @void pFileView, utype int cjSize, @void pvResrved, @int pNumFonts;
stub int AddFontResourceA -> str a1;
stub int AddFontResourceExA -> str name, utype int fl, @void res;
stub int AddFontResourceExW -> @void name, utype int fl, @void res;
stub int AngleArc -> @void hdc, int x, int y, utype int r, float StartAngle, float SweepAngle;
stub int AnimatePalette -> @void hPal, utype int iStartIndex, utype int cEntries, @void ppe;
stub int Arc -> @void hdc, int x1, int y1, int x2, int y2, int x3, int y3, int x4, int y4;
stub int ArcTo -> @void hdc, int left, int top, int right, int bottom, int xr1, int yr1, int xr2, int yr2;
stub int BeginPath -> @void hdc;
stub int BitBlt -> @void hdc, int x, int y, int cx, int cy, @void hdcSrc, int x1, int y1, utype int rop;
stub int CancelDC -> @void hdc;
stub int CheckColorsInGamut -> @void hdc, @void lpRGBTriple, @void dlpBuffer, utype int nCount;
stub int ChoosePixelFormat -> @void hdc, @void ppfd;
stub int Chord -> @void hdc, int x1, int y1, int x2, int y2, int x3, int y3, int x4, int y4;
stub @void CloseEnhMetaFile -> @void hdc;
stub int CloseFigure -> @void hdc;
stub @void CloseMetaFile -> @void hdc;
stub int ColorCorrectPalette -> @void hdc, @void hPal, utype int deFirst, utype int num;
stub int ColorMatchToTarget -> @void hdc, @void hdcTarget, utype int action;
stub int CombineTransform -> @void lpxfOut, @void lpxf1, @void lpxf2;
stub @void CopyEnhMetaFileA -> @void hEnh, str lpFileName;
stub @void CopyEnhMetaFileW -> @void hEnh, @void lpFileName;
stub @void CopyMetaFileA -> @void a1, str a2;
stub @void CopyMetaFileW -> @void a1, @void a2;
stub @void CreateBitmap -> int nWidth, int nHeight, utype int nPlanes, utype int nBitCount, @void lpBits;
stub @void CreateBitmapIndirect -> @void pbm;
stub @void CreateBrushIndirect -> @void plbrush;
stub @void CreateColorSpaceA -> @void lplcs;
stub @void CreateColorSpaceW -> @void lplcs;
stub @void CreateCompatibleBitmap -> @void hdc, int cx, int cy;
stub @void CreateCompatibleDC -> @void hdc;
stub @void CreateDCA -> str pwszDriver, str pwszDevice, str pszPort, @void pdm;
stub @void CreateDCW -> @void pwszDriver, @void pwszDevice, @void pszPort, @void pdm;
stub @void CreateDIBPatternBrush -> @void h, utype int iUsage;
stub @void CreateDIBPatternBrushPt -> @void lpPackedDIB, utype int iUsage;
stub @void CreateDIBSection -> @void hdc, @void lpbmi, utype int usage, @void ppvBits, @void hSection, utype int offset;
stub @void CreateDIBitmap -> @void hdc, @void pbmih, utype int flInit, @void pjBits, @void pbmi, utype int iUsage;
stub @void CreateDiscardableBitmap -> @void hdc, int cx, int cy;
stub @void CreateEllipticRgn -> int x1, int y1, int x2, int y2;
stub @void CreateEllipticRgnIndirect -> @void lprect;
stub @void CreateEnhMetaFileA -> @void hdc, str lpFilename, @void lprc, str lpDesc;
stub @void CreateEnhMetaFileW -> @void hdc, @void lpFilename, @void lprc, @void lpDesc;
stub @void CreateFontA -> int cHeight, int cWidth, int cEscapement, int cOrientation, int cWeight, utype int bItalic, utype int bUnderline, utype int bStrikeOut, utype int iCharSet, utype int iOutPrecision, utype int iClipPrecision, utype int iQuality, utype int iPitchAndFamily, str pszFaceName;
stub @void CreateFontIndirectA -> @void lplf;
stub @void CreateFontIndirectExA -> @void ENUMLOGFONTEXDVA;
stub @void CreateFontIndirectExW -> @void ENUMLOGFONTEXDVW;
stub @void CreateFontIndirectW -> @void lplf;
stub @void CreateFontW -> int cHeight, int cWidth, int cEscapement, int cOrientation, int cWeight, utype int bItalic, utype int bUnderline, utype int bStrikeOut, utype int iCharSet, utype int iOutPrecision, utype int iClipPrecision, utype int iQuality, utype int iPitchAndFamily, @void pszFaceName;
stub @void CreateHalftonePalette -> @void hdc;
stub @void CreateHatchBrush -> int iHatch, utype int color;
stub @void CreateICA -> str pszDriver, str pszDevice, str pszPort, @void pdm;
stub @void CreateICW -> @void pszDriver, @void pszDevice, @void pszPort, @void pdm;
stub @void CreateMetaFileA -> str pszFile;
stub @void CreateMetaFileW -> @void pszFile;
stub @void CreatePalette -> @void plpal;
stub @void CreatePatternBrush -> @void hbm;
stub @void CreatePen -> int iStyle, int cWidth, utype int color;
stub @void CreatePenIndirect -> @void plpen;
stub @void CreatePolyPolygonRgn -> @void pptl, @int pc, int cPoly, int iMode;
stub @void CreateRectRgn -> int x1, int y1, int x2, int y2;
stub @void CreateRoundRectRgn -> int x1, int y1, int x2, int y2, int w, int h;
stub int CreateScalableFontResourceA -> utype int fdwHidden, str lpszFont, str lpszFile, str lpszPath;
stub @void CreateSolidBrush -> utype int color;
stub int DPtoLP -> @void hdc, @void lppt, int c;
stub int DeleteColorSpace -> @void hcs;
stub int DeleteDC -> @void hdc;
stub int DeleteEnhMetaFile -> @void hmf;
stub int DeleteMetaFile -> @void hmf;
stub int DescribePixelFormat -> @void hdc, int iPixelFormat, utype int nBytes, @void ppfd;
stub int DrawEscape -> @void hdc, int iEscape, int cjIn, str lpIn;
stub int Ellipse -> @void hdc, int left, int top, int right, int bottom;
stub int EndDoc -> @void hdc;
stub int EndPage -> @void hdc;
stub int EndPath -> @void hdc;
stub int EnumEnhMetaFile -> @void hdc, @void hmf, @func lpProc, @void lpParam, @void lpRect;
stub int EnumFontFamiliesA -> @void hdc, str lpLogfont, @func lpProc, longlong lParam;
stub int EnumFontFamiliesExA -> @void hdc, @void lpLogfont, @func lpProc, longlong lParam, utype int dwFlags;
stub int EnumFontFamiliesExW -> @void hdc, @void lpLogfont, @func lpProc, longlong lParam, utype int dwFlags;
stub int EnumFontFamiliesW -> @void hdc, @void lpLogfont, @func lpProc, longlong lParam;
stub int EnumFontsA -> @void hdc, str lpLogfont, @func lpProc, longlong lParam;
stub int EnumFontsW -> @void hdc, @void lpLogfont, @func lpProc, longlong lParam;
stub int EnumICMProfilesA -> @void hdc, @func lpProc, longlong lParam;
stub int EnumICMProfilesW -> @void hdc, @func lpProc, longlong lParam;
stub int EnumMetaFile -> @void hdc, @void hmf, @func lpProc, longlong lParam;
stub int EnumObjects -> @void hdc, int nType, @func lpFunc, longlong lParam;
stub int ExcludeClipRect -> @void hdc, int left, int top, int right, int bottom;
stub @void ExtCreatePen -> utype int iPenStyle, utype int cWidth, @void plbrush, utype int cStyle, @int pstyle;
stub int ExtFloodFill -> @void hdc, int x, int y, utype int color, utype int type_;
stub int ExtTextOutA -> @void hdc, int x, int y, utype int options, @void lprect, str lpString, utype int c, @int lpDx;
stub int ExtTextOutW -> @void hdc, int x, int y, utype int options, @void lprect, @void lpString, utype int c, @int lpDx;
stub int FillPath -> @void hdc;
stub int FillRgn -> @void hdc, @void hrgn, @void hbr;
stub int FixBrushOrgEx -> @void hdc, int x, int y, @void ptl;
stub int FlattenPath -> @void hdc;
stub int FloodFill -> @void hdc, int x, int y, utype int color;
stub int FrameRgn -> @void hdc, @void hrgn, @void hbr, int w, int h;
stub int GdiComment -> @void hdc, utype int nSize, @char lpData;
stub int GdiFlush;
stub utype int GdiGetBatchLimit;
stub int GdiGradientFill -> @void hdc, @void pVertex, utype int nVertex, @void pMesh, utype int nMesh, utype int ulMode;
stub utype int GdiSetBatchLimit -> utype int dw;
stub int GdiTransparentBlt -> @void hdcDest, int xoriginDest, int yoriginDest, int wDest, int hDest, @void hdcSrc, int xoriginSrc, int yoriginSrc, int wSrc, int hSrc, utype int crTransparent;
stub int GetArcDirection -> @void hdc;
stub int GetAspectRatioFilterEx -> @void hdc, @void lpsize;
stub int GetBitmapBits -> @void hbit, int cb, @void lpvBits;
stub int GetBitmapDimensionEx -> @void hbit, @void lpsize;
stub utype int GetBkColor -> @void hdc;
stub int GetBkMode -> @void hdc;
stub utype int GetBoundsRect -> @void hdc, @void lprect, utype int flags;
stub int GetBrushOrgEx -> @void hdc, @void lppt;
stub int GetCharABCWidthsA -> @void hdc, utype int wFirst, utype int wLast, @void lpABC;
stub int GetCharABCWidthsFloatA -> @void hdc, utype int iFirst, utype int iLast, @void lpABC;
stub int GetCharABCWidthsFloatW -> @void hdc, utype int iFirst, utype int iLast, @void lpABC;
stub int GetCharABCWidthsI -> @void hdc, utype int giFirst, utype int cgi, @int pgi, @void pabc;
stub int GetCharABCWidthsW -> @void hdc, utype int wFirst, utype int wLast, @void lpABC;
stub int GetCharWidth32A -> @void hdc, utype int iFirst, utype int iLast, @int lpBuffer;
stub int GetCharWidth32W -> @void hdc, utype int iFirst, utype int iLast, @int lpBuffer;
stub int GetCharWidthA -> @void hdc, utype int iFirst, utype int iLast, @int lpBuffer;
stub int GetCharWidthFloatA -> @void hdc, utype int iFirst, utype int iLast, @void lpBuffer;
stub int GetCharWidthFloatW -> @void hdc, utype int iFirst, utype int iLast, @void lpBuffer;
stub int GetCharWidthI -> @void hdc, utype int giFirst, utype int cgi, @int pgi, @int piWidths;
stub int GetCharWidthW -> @void hdc, utype int iFirst, utype int iLast, @int lpBuffer;
stub utype int GetCharacterPlacementA -> @void hdc, str lpString, int nCount, int nMexExtent, @void lpResults, utype int dwFlags;
stub utype int GetCharacterPlacementW -> @void hdc, @void lpString, int nCount, int nMexExtent, @void lpResults, utype int dwFlags;
stub int GetClipBox -> @void hdc, @void lprect;
stub int GetClipRgn -> @void hdc, @void hrgn;
stub int GetColorAdjustment -> @void hdc, @void lpca;
stub @void GetColorSpace -> @void hdc;
stub @void GetCurrentObject -> @void hdc, utype int type_;
stub int GetCurrentPositionEx -> @void hdc, @void lppt;
stub utype int GetDCBrushColor -> @void hdc;
stub int GetDCOrgEx -> @void hdc, @void lppt;
stub utype int GetDCPenColor -> @void hdc;
stub utype int GetDIBColorTable -> @void hdc, utype int iStart, utype int cEntries, @void prgbq;
stub int GetDIBits -> @void hdc, @void hbm, utype int start, utype int cLines, @void lpvBits, @void lpbmi, utype int usage;
stub int GetDeviceCaps -> @void hdc, int index;
stub int GetDeviceGammaRamp -> @void hdc, @void lpRamp;
stub @void GetEnhMetaFileA -> str lpName;
stub utype int GetEnhMetaFileBits -> @void hEMF, utype int nSize, @char lpData;
stub utype int GetEnhMetaFileDescriptionA -> @void hemf, utype int cchBuffer, str lpDescription;
stub utype int GetEnhMetaFileDescriptionW -> @void hemf, utype int cchBuffer, @void lpDescription;
stub utype int GetEnhMetaFileHeader -> @void hemf, utype int nSize, @void lpEnhMetaHeader;
stub utype int GetEnhMetaFilePaletteEntries -> @void hemf, utype int nNumEntries, @void lpPaletteEntries;
stub utype int GetEnhMetaFilePixelFormat -> @void hemf, utype int cbBuffer, @void ppfd;
stub @void GetEnhMetaFileW -> @void lpName;
stub utype int GetFontData -> @void hdc, utype int dwTable, utype int dwOffset, @void pvBuffer, utype int cjBuffer;
stub utype int GetFontLanguageInfo -> @void hdc;
stub utype int GetFontUnicodeRanges -> @void hdc, @void lpgs;
stub utype int GetGlyphIndicesA -> @void hdc, str lpstr, int c, @int pgi, utype int fl;
stub utype int GetGlyphIndicesW -> @void hdc, @void lpstr, int c, @int pgi, utype int fl;
stub utype int GetGlyphOutlineA -> @void hdc, utype int uChar, utype int fuFormat, @void lpgm, utype int cjBuffer, @void pvBuffer, @void lpmat2;
stub utype int GetGlyphOutlineW -> @void hdc, utype int uChar, utype int fuFormat, @void lpgm, utype int cjBuffer, @void pvBuffer, @void lpmat2;
stub int GetGraphicsMode -> @void hdc;
stub int GetICMProfileA -> @void hdc, @int pBufSize, str pszFilename;
stub int GetICMProfileW -> @void hdc, @int pBufSize, @void pszFilename;
stub utype int GetKerningPairsA -> @void hdc, utype int nPairs, @void lpKernPair;
stub utype int GetKerningPairsW -> @void hdc, utype int nPairs, @void lpKernPair;
stub utype int GetLayout -> @void hdc;
stub int GetLogColorSpaceA -> @void hColorSpace, @void lpBuffer, utype int nSize;
stub int GetLogColorSpaceW -> @void hColorSpace, @void lpBuffer, utype int nSize;
stub int GetMapMode -> @void hdc;
stub @void GetMetaFileA -> str lpName;
stub utype int GetMetaFileBitsEx -> @void hMF, utype int cbBuffer, @void lpData;
stub @void GetMetaFileW -> @void lpName;
stub int GetMetaRgn -> @void hdc, @void hrgn;
stub int GetMiterLimit -> @void hdc, @void plimit;
stub utype int GetNearestColor -> @void hdc, utype int color;
stub utype int GetNearestPaletteIndex -> @void h, utype int color;
stub int GetObjectA -> @void h, int c, @void pv;
stub utype int GetObjectType -> @void h;
stub int GetObjectW -> @void h, int c, @void pv;
stub utype int GetOutlineTextMetricsA -> @void hdc, utype int cjCopy, @void potm;
stub utype int GetOutlineTextMetricsW -> @void hdc, utype int cjCopy, @void potm;
stub utype int GetPaletteEntries -> @void hpal, utype int iStart, utype int cEntries, @void pPalEntries;
stub int GetPath -> @void hdc, @void apt, @char aj, int cpt;
stub utype int GetPixel -> @void hdc, int x, int y;
stub int GetPixelFormat -> @void hdc;
stub int GetPolyFillMode -> @void hdc;
stub int GetROP2 -> @void hdc;
stub int GetRandomRgn -> @void hdc, @void hrgn, int i;
stub int GetRasterizerCaps -> @void lpraststat, utype int cjBytes;
stub utype int GetRegionData -> @void hrgn, utype int nCount, @void lpRgnData;
stub int GetRgnBox -> @void hrgn, @void lprc;
stub @void GetStockObject -> int i;
stub int GetStretchBltMode -> @void hdc;
stub utype int GetSystemPaletteEntries -> @void hdc, utype int iStart, utype int cEntries, @void pPalEntries;
stub utype int GetSystemPaletteUse -> @void hdc;
stub utype int GetTextAlign -> @void hdc;
stub int GetTextCharacterExtra -> @void hdc;
stub int GetTextCharset -> @void hdc;
stub int GetTextCharsetInfo -> @void hdc, @void lpSig, utype int dwFlags;
stub utype int GetTextColor -> @void hdc;
stub int GetTextExtentExPointA -> @void hdc, str lpszString, int cchString, int nMaxExtent, @int lpnFit, @int lpnDx, @void lpSize;
stub int GetTextExtentExPointI -> @void hdc, @int lpwszString, int cwchString, int nMaxExtent, @int lpnFit, @int lpnDx, @void lpSize;
stub int GetTextExtentExPointW -> @void hdc, @void lpszString, int cchString, int nMaxExtent, @int lpnFit, @int lpnDx, @void lpSize;
stub int GetTextExtentPoint32A -> @void hdc, str lpString, int c, @void psizl;
stub int GetTextExtentPoint32W -> @void hdc, @void lpString, int c, @void psizl;
stub int GetTextExtentPointA -> @void hdc, str lpString, int c, @void lpsz;
stub int GetTextExtentPointI -> @void hdc, @int pgiIn, int cgi, @void psize;
stub int GetTextExtentPointW -> @void hdc, @void lpString, int c, @void lpsz;
stub int GetTextFaceA -> @void hdc, int c, str lpName;
stub int GetTextFaceW -> @void hdc, int c, @void lpName;
stub int GetTextMetricsA -> @void hdc, @void lptm;
stub int GetTextMetricsW -> @void hdc, @void lptm;
stub int GetViewportExtEx -> @void hdc, @void lpsize;
stub int GetViewportOrgEx -> @void hdc, @void lppoint;
stub utype int GetWinMetaFileBits -> @void hemf, utype int cbData16, @char pData16, int iMapMode, @void hdcRef;
stub int GetWindowExtEx -> @void hdc, @void lpsize;
stub int GetWindowOrgEx -> @void hdc, @void lppoint;
stub int GetWorldTransform -> @void hdc, @void lpxf;
stub int IntersectClipRect -> @void hdc, int left, int top, int right, int bottom;
stub int InvertRgn -> @void hdc, @void hrgn;
stub int LPtoDP -> @void hdc, @void lppt, int c;
stub int LineDDA -> int xStart, int yStart, int xEnd, int yEnd, @func lpProc, longlong data;
stub int LineTo -> @void hdc, int x, int y;
stub int MaskBlt -> @void hdcDest, int xDest, int yDest, int width, int height, @void hdcSrc, int xSrc, int ySrc, @void hbmMask, int xMask, int yMask, utype int rop;
stub int ModifyWorldTransform -> @void hdc, @void lpxf, utype int mode;
stub int MoveToEx -> @void hdc, int x, int y, @void lppt;
stub int OffsetClipRgn -> @void hdc, int x, int y;
stub int OffsetViewportOrgEx -> @void hdc, int x, int y, @void lppt;
stub int OffsetWindowOrgEx -> @void hdc, int x, int y, @void lppt;
stub int PaintRgn -> @void hdc, @void hrgn;
stub int PatBlt -> @void hdc, int x, int y, int w, int h, utype int rop;
stub @void PathToRegion -> @void hdc;
stub int Pie -> @void hdc, int left, int top, int right, int bottom, int xr1, int yr1, int xr2, int yr2;
stub int PlayEnhMetaFile -> @void hdc, @void hmf, @void lprect;
stub int PlayEnhMetaFileRecord -> @void hdc, @void pht, @void pmr, utype int cht;
stub int PlayMetaFile -> @void hdc, @void hmf;
stub int PlayMetaFileRecord -> @void hdc, @void lpHandleTable, @void lpMR, utype int noObjs;
stub int PlgBlt -> @void hdcDest, @void lpPoint, @void hdcSrc, int xSrc, int ySrc, int width, int height, @void hbmMask, int xMask, int yMask;
stub int PolyBezier -> @void hdc, @void apt, utype int cpt;
stub int PolyBezierTo -> @void hdc, @void apt, utype int cpt;
stub int PolyPolygon -> @void hdc, @void apt, @int asz, int csz;
stub int PolyPolyline -> @void hdc, @void apt, @int asz, utype int csz;
stub int PolyTextOutA -> @void hdc, @void ppt, int nstrings;
stub int PolyTextOutW -> @void hdc, @void ppt, int nstrings;
stub int Polygon -> @void hdc, @void apt, int cpt;
stub int Polyline -> @void hdc, @void apt, int cpt;
stub int PtInRegion -> @void hrgn, int x, int y;
stub int PtVisible -> @void hdc, int x, int y;
stub utype int RealizePalette -> @void hdc;
stub int RectVisible -> @void hdc, @void lprect;
stub int Rectangle -> @void hdc, int left, int top, int right, int bottom;
stub int RemoveFontMemResourceEx -> @void h;
stub int RemoveFontResourceA -> str lpFileName;
stub int RemoveFontResourceExA -> str name, utype int fl, @void pdv;
stub int RemoveFontResourceExW -> @void name, utype int fl, @void pdv;
stub @void ResetDCA -> @void hdc, @void lpdm;
stub int ResizePalette -> @void hpal, utype int n;
stub int RestoreDC -> @void hdc, int nSavedDC;
stub int RoundRect -> @void hdc, int left, int top, int right, int bottom, int width, int height;
stub int SaveDC -> @void hdc;
stub int ScaleViewportExtEx -> @void hdc, int xn, int dx, int yn, int yd, @void lpsz;
stub int ScaleWindowExtEx -> @void hdc, int xn, int xd, int yn, int yd, @void lpsz;
stub int SelectClipPath -> @void hdc, int mode;
stub int SelectClipRgn -> @void hdc, @void hrgn;
stub @void SelectObject -> @void hdc, @void h;
stub @void SelectPalette -> @void hdc, @void hPal, int bForceBkgd;
stub int SetAbortProc -> @void hdc, @func lpProc;
stub int SetArcDirection -> @void hdc, int dir;
stub int SetBitmapBits -> @void hbm, utype int cb, @void pvBits;
stub int SetBitmapDimensionEx -> @void hbm, int w, int h, @void lpsz;
stub utype int SetBkColor -> @void hdc, utype int color;
stub int SetBkMode -> @void hdc, int mode;
stub utype int SetBoundsRect -> @void hdc, @void lprect, utype int flags;
stub int SetBrushOrgEx -> @void hdc, int x, int y, @void lppt;
stub int SetColorAdjustment -> @void hdc, @void lpca;
stub @void SetColorSpace -> @void hdc, @void hcs;
stub utype int SetDCBrushColor -> @void hdc, utype int color;
stub utype int SetDCPenColor -> @void hdc, utype int color;
stub utype int SetDIBColorTable -> @void hdc, utype int iStart, utype int cEntries, @void prgbq;
stub int SetDIBits -> @void hdc, @void hbm, utype int start, utype int cLines, @void lpBits, @void lpbmi, utype int ColorUse;
stub int SetDIBitsToDevice -> @void hdc, int xDest, int yDest, utype int w, utype int h, int xSrc, int ySrc, utype int StartScan, utype int cLines, @void lpvBits, @void lpbmi, utype int ColorUse;
stub int SetDeviceGammaRamp -> @void hdc, @void lpRamp;
stub @void SetEnhMetaFileBits -> utype int nSize, @char pb;
stub int SetGraphicsMode -> @void hdc, int iMode;
stub int SetICMProfileA -> @void hdc, str lpFileName;
stub int SetICMProfileW -> @void hdc, @void lpFileName;
stub utype int SetLayout -> @void hdc, utype int l;
stub int SetMapMode -> @void hdc, int iMode;
stub utype int SetMapperFlags -> @void hdc, utype int flags;
stub @void SetMetaFileBitsEx -> utype int cbBuffer, @char lpData;
stub int SetMetaRgn -> @void hdc;
stub utype int SetPaletteEntries -> @void hpal, utype int iStart, utype int cEntries, @void pPalEntries;
stub utype int SetPixel -> @void hdc, int x, int y, utype int color;
stub int SetPixelFormat -> @void hdc, int format, @void ppfd;
stub int SetPixelV -> @void hdc, int x, int y, utype int color;
stub int SetPolyFillMode -> @void hdc, int mode;
stub int SetROP2 -> @void hdc, int rop2;
stub int SetStretchBltMode -> @void hdc, int mode;
stub utype int SetSystemPaletteUse -> @void hdc, utype int use_;
stub utype int SetTextAlign -> @void hdc, utype int align;
stub int SetTextCharacterExtra -> @void hdc, int extra;
stub utype int SetTextColor -> @void hdc, utype int color;
stub int SetTextJustification -> @void hdc, int extra, int cnt;
stub int SetViewportExtEx -> @void hdc, int x, int y, @void lpsz;
stub int SetViewportOrgEx -> @void hdc, int x, int y, @void lppt;
stub @void SetWinMetaFileBits -> utype int nSize, @char lpMeta16Data, @void hdcRef, @void lpMFP;
stub int SetWindowExtEx -> @void hdc, int x, int y, @void lpsz;
stub int SetWindowOrgEx -> @void hdc, int x, int y, @void lppt;
stub int SetWorldTransform -> @void hdc, @void lpxf;
stub int StartDocA -> @void hdc, @void lpdi;
stub int StartDocW -> @void hdc, @void lpdi;
stub int StartPage -> @void hdc;
stub int StretchBlt -> @void hdcDest, int xDest, int yDest, int wDest, int hDest, @void hdcSrc, int xSrc, int ySrc, int wSrc, int hSrc, utype int rop;
stub int StretchDIBits -> @void hdc, int xDest, int yDest, int DestWidth, int DestHeight, int xSrc, int ySrc, int SrcWidth, int SrcHeight, @void lpBits, @void lpbmi, utype int iUsage, utype int rop;
stub int StrokeAndFillPath -> @void hdc;
stub int SwapBuffers -> @void a1;
stub int TextOutA -> @void hdc, int x, int y, str lpString, int c;
stub int TextOutW -> @void hdc, int x, int y, @void lpString, int c;
stub int TranslateCharsetInfo -> @int lpSrc, @void lpCs, utype int dwFlags;
stub int UnrealizeObject -> @void h;
stub int UpdateColors -> @void hdc;
stub int UpdateICMRegKeyA -> utype int reserved, str lpszCMID, str lpszFileName, utype int command;
stub int UpdateICMRegKeyW -> utype int reserved, @void lpszCMID, @void lpszFileName, utype int command;
stub int WidenPath -> @void hdc;

!!! Declared by the headers, but with a type the language cannot write:
!!!   GdiAlphaBlend

!!! No prototype in the headers this build saw. They are here so the
!!! list is complete; uncomment and give the real signature to use one.
!!! GdiAlphaBlend
