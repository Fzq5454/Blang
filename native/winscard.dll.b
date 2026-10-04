!~
~  native/winscard.dll.b: the winscard.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/winscard.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/winscard.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `winscard.dll.b` is what produces `meta/winscard.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\winscard.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per winscard.dll export that the headers declare. The
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
!!! 61 declarations here, 0 kept from the hand-checked list above, 0 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub @void SCardAccessStartedEvent;
stub int SCardAddReaderToGroupA -> utype longlong hContext, str szReaderName, str szGroupName;
stub int SCardAddReaderToGroupW -> utype longlong hContext, @void szReaderName, @void szGroupName;
stub int SCardBeginTransaction -> utype longlong hCard;
stub int SCardCancel -> utype longlong hContext;
stub int SCardConnectA -> utype longlong hContext, str szReader, utype int dwShareMode, utype int dwPreferredProtocols, @longlong phCard, @int pdwActiveProtocol;
stub int SCardConnectW -> utype longlong hContext, @void szReader, utype int dwShareMode, utype int dwPreferredProtocols, @longlong phCard, @int pdwActiveProtocol;
stub int SCardControl -> utype longlong hCard, utype int dwControlCode, @void lpInBuffer, utype int nInBufferSize, @void lpOutBuffer, utype int nOutBufferSize, @int lpBytesReturned;
stub int SCardDisconnect -> utype longlong hCard, utype int dwDisposition;
stub int SCardEndTransaction -> utype longlong hCard, utype int dwDisposition;
stub int SCardEstablishContext -> utype int dwScope, @void pvReserved1, @void pvReserved2, @longlong phContext;
stub int SCardForgetCardTypeA -> utype longlong hContext, str szCardName;
stub int SCardForgetCardTypeW -> utype longlong hContext, @void szCardName;
stub int SCardForgetReaderA -> utype longlong hContext, str szReaderName;
stub int SCardForgetReaderGroupA -> utype longlong hContext, str szGroupName;
stub int SCardForgetReaderGroupW -> utype longlong hContext, @void szGroupName;
stub int SCardForgetReaderW -> utype longlong hContext, @void szReaderName;
stub int SCardFreeMemory -> utype longlong hContext, @void pvMem;
stub int SCardGetAttrib -> utype longlong hCard, utype int dwAttrId, @char pbAttr, @int pcbAttrLen;
stub int SCardGetCardTypeProviderNameA -> utype longlong hContext, str szCardName, utype int dwProviderId, str szProvider, @int pcchProvider;
stub int SCardGetCardTypeProviderNameW -> utype longlong hContext, @void szCardName, utype int dwProviderId, @void szProvider, @int pcchProvider;
stub int SCardGetProviderIdA -> utype longlong hContext, str szCard, @void pguidProviderId;
stub int SCardGetProviderIdW -> utype longlong hContext, @void szCard, @void pguidProviderId;
stub int SCardGetStatusChangeA -> utype longlong hContext, utype int dwTimeout, @void rgReaderStates, utype int cReaders;
stub int SCardGetStatusChangeW -> utype longlong hContext, utype int dwTimeout, @void rgReaderStates, utype int cReaders;
stub int SCardGetTransmitCount -> utype longlong hCard, @int pcTransmitCount;
stub int SCardIntroduceCardTypeA -> utype longlong hContext, str szCardName, @void pguidPrimaryProvider, @void rgguidInterfaces, utype int dwInterfaceCount, @char pbAtr, @char pbAtrMask, utype int cbAtrLen;
stub int SCardIntroduceCardTypeW -> utype longlong hContext, @void szCardName, @void pguidPrimaryProvider, @void rgguidInterfaces, utype int dwInterfaceCount, @char pbAtr, @char pbAtrMask, utype int cbAtrLen;
stub int SCardIntroduceReaderA -> utype longlong hContext, str szReaderName, str szDeviceName;
stub int SCardIntroduceReaderGroupA -> utype longlong hContext, str szGroupName;
stub int SCardIntroduceReaderGroupW -> utype longlong hContext, @void szGroupName;
stub int SCardIntroduceReaderW -> utype longlong hContext, @void szReaderName, @void szDeviceName;
stub int SCardIsValidContext -> utype longlong hContext;
stub int SCardListCardsA -> utype longlong hContext, @char pbAtr, @void rgquidInterfaces, utype int cguidInterfaceCount, str mszCards, @int pcchCards;
stub int SCardListCardsW -> utype longlong hContext, @char pbAtr, @void rgquidInterfaces, utype int cguidInterfaceCount, @void mszCards, @int pcchCards;
stub int SCardListInterfacesA -> utype longlong hContext, str szCard, @void pguidInterfaces, @int pcguidInterfaces;
stub int SCardListInterfacesW -> utype longlong hContext, @void szCard, @void pguidInterfaces, @int pcguidInterfaces;
stub int SCardListReaderGroupsA -> utype longlong hContext, str mszGroups, @int pcchGroups;
stub int SCardListReaderGroupsW -> utype longlong hContext, @void mszGroups, @int pcchGroups;
stub int SCardListReadersA -> utype longlong hContext, str mszGroups, str mszReaders, @int pcchReaders;
stub int SCardListReadersW -> utype longlong hContext, @void mszGroups, @void mszReaders, @int pcchReaders;
stub int SCardLocateCardsA -> utype longlong hContext, str mszCards, @void rgReaderStates, utype int cReaders;
stub int SCardLocateCardsByATRA -> utype longlong hContext, @void rgAtrMasks, utype int cAtrs, @void rgReaderStates, utype int cReaders;
stub int SCardLocateCardsByATRW -> utype longlong hContext, @void rgAtrMasks, utype int cAtrs, @void rgReaderStates, utype int cReaders;
stub int SCardLocateCardsW -> utype longlong hContext, @void mszCards, @void rgReaderStates, utype int cReaders;
stub int SCardReadCacheA -> utype longlong hContext, @void CardIdentifier, utype int FreshnessCounter, str LookupName, @char Data, @int DataLen;
stub int SCardReadCacheW -> utype longlong hContext, @void CardIdentifier, utype int FreshnessCounter, @void LookupName, @char Data, @int DataLen;
stub int SCardReconnect -> utype longlong hCard, utype int dwShareMode, utype int dwPreferredProtocols, utype int dwInitialization, @int pdwActiveProtocol;
stub int SCardReleaseContext -> utype longlong hContext;
stub void SCardReleaseStartedEvent;
stub int SCardRemoveReaderFromGroupA -> utype longlong hContext, str szReaderName, str szGroupName;
stub int SCardRemoveReaderFromGroupW -> utype longlong hContext, @void szReaderName, @void szGroupName;
stub int SCardSetAttrib -> utype longlong hCard, utype int dwAttrId, @char pbAttr, utype int cbAttrLen;
stub int SCardSetCardTypeProviderNameA -> utype longlong hContext, str szCardName, utype int dwProviderId, str szProvider;
stub int SCardSetCardTypeProviderNameW -> utype longlong hContext, @void szCardName, utype int dwProviderId, @void szProvider;
stub int SCardState -> utype longlong hCard, @int pdwState, @int pdwProtocol, @char pbAtr, @int pcbAtrLen;
stub int SCardStatusA -> utype longlong hCard, str szReaderName, @int pcchReaderLen, @int pdwState, @int pdwProtocol, @char pbAtr, @int pcbAtrLen;
stub int SCardStatusW -> utype longlong hCard, @void szReaderName, @int pcchReaderLen, @int pdwState, @int pdwProtocol, @char pbAtr, @int pcbAtrLen;
stub int SCardTransmit -> utype longlong hCard, @void pioSendPci, @char pbSendBuffer, utype int cbSendLength, @void pioRecvPci, @char pbRecvBuffer, @int pcbRecvLength;
stub int SCardWriteCacheA -> utype longlong hContext, @void CardIdentifier, utype int FreshnessCounter, str LookupName, @char Data, utype int DataLen;
stub int SCardWriteCacheW -> utype longlong hContext, @void CardIdentifier, utype int FreshnessCounter, @void LookupName, @char Data, utype int DataLen;
