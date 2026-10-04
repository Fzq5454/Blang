!~
~  native/wsock32.dll.b: the wsock32.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/wsock32.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/wsock32.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `wsock32.dll.b` is what produces `meta/wsock32.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\wsock32.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per wsock32.dll export that the headers declare. The
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
!!! 50 declarations here, 0 kept from the hand-checked list above, 1 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub int AcceptEx -> utype longlong sListenSocket, utype longlong sAcceptSocket, @void lpOutputBuffer, utype int dwReceiveDataLength, utype int dwLocalAddressLength, utype int dwRemoteAddressLength, @int lpdwBytesReceived, @void lpOverlapped;
stub void GetAcceptExSockaddrs -> @void lpOutputBuffer, utype int dwReceiveDataLength, utype int dwLocalAddressLength, utype int dwRemoteAddressLength, @void LocalSockaddr, @int LocalSockaddrLength, @void RemoteSockaddr, @int RemoteSockaddrLength;
stub int TransmitFile -> utype longlong hSocket, @void hFile, utype int nNumberOfBytesToWrite, utype int nNumberOfBytesPerSend, @void lpOverlapped, @void lpTransmitBuffers, utype int dwReserved;
stub @void WSAAsyncGetHostByAddr -> @void hWnd, utype int wMsg, str addr, int len, int type_, str buf, int buflen;
stub @void WSAAsyncGetHostByName -> @void hWnd, utype int wMsg, str name, str buf, int buflen;
stub @void WSAAsyncGetProtoByName -> @void hWnd, utype int wMsg, str name, str buf, int buflen;
stub @void WSAAsyncGetProtoByNumber -> @void hWnd, utype int wMsg, int number, str buf, int buflen;
stub @void WSAAsyncGetServByName -> @void hWnd, utype int wMsg, str name, str proto, str buf, int buflen;
stub @void WSAAsyncGetServByPort -> @void hWnd, utype int wMsg, int port, str proto, str buf, int buflen;
stub int WSAAsyncSelect -> utype longlong s, @void hWnd, utype int wMsg, int lEvent;
stub int WSACancelAsyncRequest -> @void hAsyncTaskHandle;
stub int WSACancelBlockingCall;
stub int WSACleanup;
stub int WSAGetLastError;
stub int WSAIsBlocking;
stub int WSARecvEx -> utype longlong s, str buf, int len, @int flags;
stub @longlong WSASetBlockingHook -> @func lpBlockFunc;
stub void WSASetLastError -> int iError;
stub int WSAStartup -> utype int wVersionRequested, @void lpWSAData;
stub int WSAUnhookBlockingHook;
stub int __WSAFDIsSet -> utype longlong fd, @void set;
stub utype longlong accept -> utype longlong s, @void addr, @int addrlen;
stub int bind -> utype longlong s, @void name, int namelen;
stub int closesocket -> utype longlong s;
stub int connect -> utype longlong s, @void name, int namelen;
stub @void gethostbyaddr -> str addr, int len, int type_;
stub @void gethostbyname -> str name;
stub int gethostname -> str name, int namelen;
stub int getpeername -> utype longlong s, @void name, @int namelen;
stub @void getprotobyname -> str name;
stub @void getprotobynumber -> int number;
stub @void getservbyname -> str name, str proto;
stub @void getservbyport -> int port, str proto;
stub int getsockname -> utype longlong s, @void name, @int namelen;
stub int getsockopt -> utype longlong s, int level, int optname, str optval, @int optlen;
stub utype int htonl -> utype int hostlong;
stub utype int htons -> utype int hostshort;
stub utype int inet_addr -> str cp;
stub int ioctlsocket -> utype longlong s, int cmd, @int argp;
stub int listen -> utype longlong s, int backlog;
stub utype int ntohl -> utype int netlong;
stub utype int ntohs -> utype int netshort;
stub int recv -> utype longlong s, str buf, int len, int flags;
stub int recvfrom -> utype longlong s, str buf, int len, int flags, @void from, @int fromlen;
stub int select -> int nfds, @void readfds, @void writefds, @void exceptfds, @void timeout;
stub int send -> utype longlong s, str buf, int len, int flags;
stub int sendto -> utype longlong s, str buf, int len, int flags, @void to, int tolen;
stub int setsockopt -> utype longlong s, int level, int optname, str optval, int optlen;
stub int shutdown -> utype longlong s, int how;
stub utype longlong socket -> int af, int type_, int protocol;

!!! Declared by the headers, but with a type the language cannot write:
!!!   inet_ntoa

!!! No prototype in the headers this build saw. They are here so the
!!! list is complete; uncomment and give the real signature to use one.
!!! inet_ntoa
