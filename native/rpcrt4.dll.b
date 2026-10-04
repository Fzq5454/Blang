!~
~  native/rpcrt4.dll.b: the rpcrt4.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/rpcrt4.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/rpcrt4.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `rpcrt4.dll.b` is what produces `meta/rpcrt4.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\rpcrt4.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per rpcrt4.dll export that the headers declare. The
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
!!! 380 declarations here, 0 kept from the hand-checked list above, 10 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub int DceErrorInqTextA -> int RpcStatus, @char ErrorText;
stub int DceErrorInqTextW -> int RpcStatus, @int ErrorText;
stub utype int IUnknown_AddRef_Proxy -> @void This;
stub int IUnknown_QueryInterface_Proxy -> @void This, @void riid, @void ppvObject;
stub utype int IUnknown_Release_Proxy -> @void This;
stub @void I_RpcAllocate -> utype int Size;
stub int I_RpcAsyncAbortCall -> @void pAsync, utype int ExceptionCode;
stub int I_RpcAsyncSetHandle -> @void Message, @void pAsync;
stub int I_RpcBindingCopy -> @void SourceBinding, @void DestinationBinding;
stub int I_RpcBindingHandleToAsyncHandle -> @void Binding, @void AsyncHandle;
stub int I_RpcBindingInqDynamicEndpointA -> @void Binding, @void DynamicEndpoint;
stub int I_RpcBindingInqDynamicEndpointW -> @void Binding, @void DynamicEndpoint;
stub int I_RpcBindingInqLocalClientPID -> @void Binding, @int Pid;
stub int I_RpcBindingInqMarshalledTargetInfo -> @void Binding, @int MarshalledTargetInfoLength, @void MarshalledTargetInfo;
stub int I_RpcBindingInqSecurityContext -> @void Binding, @void SecurityContextHandle;
stub int I_RpcBindingInqTransportType -> @void Binding, @int Type;
stub int I_RpcBindingInqWireIdForSnego -> @void Binding, @char WireId;
stub int I_RpcBindingIsClientLocal -> @void BindingHandle, @int ClientLocalFlag;
stub int I_RpcBindingToStaticStringBindingW -> @void Binding, @void StringBinding;
stub void I_RpcClearMutex -> @void Mutex;
stub void I_RpcDeleteMutex -> @void Mutex;
stub int I_RpcExceptionFilter -> utype int ExceptionCode;
stub void I_RpcFree -> @void Object;
stub int I_RpcFreeBuffer -> @void Message;
stub int I_RpcFreePipeBuffer -> @void Message;
stub int I_RpcGetBuffer -> @void Message;
stub int I_RpcGetBufferWithObject -> @void Message, @void ObjectUuid;
stub @void I_RpcGetCurrentCallHandle;
stub int I_RpcGetExtendedError;
stub int I_RpcIfInqTransferSyntaxes -> @void RpcIfHandle, @void TransferSyntaxes, utype int TransferSyntaxSize, @int TransferSyntaxCount;
stub int I_RpcMapWin32Status -> int Status;
stub int I_RpcNegotiateTransferSyntax -> @void Message;
stub int I_RpcNsBindingSetEntryNameA -> @void Binding, utype int EntryNameSyntax, @char EntryName;
stub int I_RpcNsBindingSetEntryNameW -> @void Binding, utype int EntryNameSyntax, @int EntryName;
stub int I_RpcNsInterfaceExported -> utype int EntryNameSyntax, @int EntryName, @void RpcInterfaceInformation;
stub int I_RpcNsInterfaceUnexported -> utype int EntryNameSyntax, @int EntryName, @void RpcInterfaceInformation;
stub void I_RpcPauseExecution -> utype int Milliseconds;
stub int I_RpcReallocPipeBuffer -> @void Message, utype int NewSize;
stub int I_RpcReceive -> @void Message, utype int Size;
stub void I_RpcRecordCalloutFailure -> int RpcStatus, @void CallOutState, @int DllName;
stub void I_RpcRequestMutex -> @void Mutex;
stub int I_RpcSend -> @void Message;
stub int I_RpcSendReceive -> @void Message;
stub int I_RpcServerCheckClientRestriction -> @void Context;
stub int I_RpcServerInqLocalConnAddress -> @void Binding, @void Buffer, @int BufferSize, @int AddressFormat;
stub int I_RpcServerInqTransportType -> @int Type;
stub int I_RpcServerRegisterForwardFunction -> @func pForwardFunction;
stub int I_RpcServerSetAddressChangeFn -> @func pAddressChangeFn;
stub int I_RpcServerUseProtseq2A -> @char NetworkAddress, @char Protseq, utype int MaxCalls, @void SecurityDescriptor, @void Policy;
stub int I_RpcServerUseProtseq2W -> @int NetworkAddress, @int Protseq, utype int MaxCalls, @void SecurityDescriptor, @void Policy;
stub int I_RpcServerUseProtseqEp2A -> @char NetworkAddress, @char Protseq, utype int MaxCalls, @char Endpoint, @void SecurityDescriptor, @void Policy;
stub int I_RpcServerUseProtseqEp2W -> @int NetworkAddress, @int Protseq, utype int MaxCalls, @int Endpoint, @void SecurityDescriptor, @void Policy;
stub void I_RpcSessionStrictContextHandle;
stub void I_RpcSsDontSerializeContext;
stub int I_RpcTurnOnEEInfoPropagation;
stub int I_UuidCreate -> @void Uuid;
stub @void NDRCContextBinding -> @void CContext;
stub void NDRCContextMarshall -> @void CContext, @void pBuff;
stub void NDRCContextUnmarshall -> @void pCContext, @void hBinding, @void pBuff, utype int DataRepresentation;
stub void NDRSContextMarshall -> @void CContext, @void pBuff, @func userRunDownIn;
stub void NDRSContextMarshall2 -> @void BindingHandle, @void CContext, @void pBuff, @func userRunDownIn, @void CtxGuard, utype int Flags;
stub void NDRSContextMarshallEx -> @void BindingHandle, @void CContext, @void pBuff, @func userRunDownIn;
stub @void NDRSContextUnmarshall -> @void pBuff, utype int DataRepresentation;
stub @void NDRSContextUnmarshall2 -> @void BindingHandle, @void pBuff, utype int DataRepresentation, @void CtxGuard, utype int Flags;
stub @void NDRSContextUnmarshallEx -> @void BindingHandle, @void pBuff, utype int DataRepresentation;
stub void Ndr64AsyncServerCall64 -> @void pRpcMsg;
stub void Ndr64AsyncServerCallAll -> @void pRpcMsg;
stub int Ndr64DcomAsyncStubCall -> @void pThis, @void pChannel, @void pRpcMsg, @int pdwStubPhase;
stub @void NdrAllocate -> @void pStubMsg, utype longlong Len;
stub void NdrAsyncServerCall -> @void pRpcMsg;
stub void NdrByteCountPointerBufferSize -> @void pStubMsg, @char pMemory, @char pFormat;
stub void NdrByteCountPointerFree -> @void pStubMsg, @char pMemory, @char pFormat;
stub @char NdrByteCountPointerMarshall -> @void pStubMsg, @char pMemory, @char pFormat;
stub @char NdrByteCountPointerUnmarshall -> @void pStubMsg, @void ppMemory, @char pFormat, utype char fMustAlloc;
stub void NdrClearOutParameters -> @void pStubMsg, @char pFormat, @void ArgAddr;
stub void NdrClientContextMarshall -> @void pStubMsg, @void ContextHandle, int fCheck;
stub void NdrClientContextUnmarshall -> @void pStubMsg, @void pContextHandle, @void BindHandle;
stub void NdrClientInitialize -> @void pRpcMsg, @void pStubMsg, @void pStubDescriptor, utype int ProcNum;
stub void NdrClientInitializeNew -> @void pRpcMsg, @void pStubMsg, @void pStubDescriptor, utype int ProcNum;
stub void NdrComplexArrayBufferSize -> @void pStubMsg, @char pMemory, @char pFormat;
stub void NdrComplexArrayFree -> @void pStubMsg, @char pMemory, @char pFormat;
stub @char NdrComplexArrayMarshall -> @void pStubMsg, @char pMemory, @char pFormat;
stub utype int NdrComplexArrayMemorySize -> @void pStubMsg, @char pFormat;
stub @char NdrComplexArrayUnmarshall -> @void pStubMsg, @void ppMemory, @char pFormat, utype char fMustAlloc;
stub void NdrComplexStructBufferSize -> @void pStubMsg, @char pMemory, @char pFormat;
stub void NdrComplexStructFree -> @void pStubMsg, @char pMemory, @char pFormat;
stub @char NdrComplexStructMarshall -> @void pStubMsg, @char pMemory, @char pFormat;
stub utype int NdrComplexStructMemorySize -> @void pStubMsg, @char pFormat;
stub @char NdrComplexStructUnmarshall -> @void pStubMsg, @void ppMemory, @char pFormat, utype char fMustAlloc;
stub void NdrConformantArrayBufferSize -> @void pStubMsg, @char pMemory, @char pFormat;
stub void NdrConformantArrayFree -> @void pStubMsg, @char pMemory, @char pFormat;
stub @char NdrConformantArrayMarshall -> @void pStubMsg, @char pMemory, @char pFormat;
stub utype int NdrConformantArrayMemorySize -> @void pStubMsg, @char pFormat;
stub @char NdrConformantArrayUnmarshall -> @void pStubMsg, @void ppMemory, @char pFormat, utype char fMustAlloc;
stub void NdrConformantStringBufferSize -> @void pStubMsg, @char pMemory, @char pFormat;
stub @char NdrConformantStringMarshall -> @void pStubMsg, @char pMemory, @char pFormat;
stub utype int NdrConformantStringMemorySize -> @void pStubMsg, @char pFormat;
stub @char NdrConformantStringUnmarshall -> @void pStubMsg, @void ppMemory, @char pFormat, utype char fMustAlloc;
stub void NdrConformantStructBufferSize -> @void pStubMsg, @char pMemory, @char pFormat;
stub void NdrConformantStructFree -> @void pStubMsg, @char pMemory, @char pFormat;
stub @char NdrConformantStructMarshall -> @void pStubMsg, @char pMemory, @char pFormat;
stub utype int NdrConformantStructMemorySize -> @void pStubMsg, @char pFormat;
stub @char NdrConformantStructUnmarshall -> @void pStubMsg, @void ppMemory, @char pFormat, utype char fMustAlloc;
stub void NdrConformantVaryingArrayBufferSize -> @void pStubMsg, @char pMemory, @char pFormat;
stub void NdrConformantVaryingArrayFree -> @void pStubMsg, @char pMemory, @char pFormat;
stub @char NdrConformantVaryingArrayMarshall -> @void pStubMsg, @char pMemory, @char pFormat;
stub utype int NdrConformantVaryingArrayMemorySize -> @void pStubMsg, @char pFormat;
stub @char NdrConformantVaryingArrayUnmarshall -> @void pStubMsg, @void ppMemory, @char pFormat, utype char fMustAlloc;
stub void NdrConformantVaryingStructBufferSize -> @void pStubMsg, @char pMemory, @char pFormat;
stub void NdrConformantVaryingStructFree -> @void pStubMsg, @char pMemory, @char pFormat;
stub @char NdrConformantVaryingStructMarshall -> @void pStubMsg, @char pMemory, @char pFormat;
stub utype int NdrConformantVaryingStructMemorySize -> @void pStubMsg, @char pFormat;
stub @char NdrConformantVaryingStructUnmarshall -> @void pStubMsg, @void ppMemory, @char pFormat, utype char fMustAlloc;
stub @void NdrContextHandleInitialize -> @void pStubMsg, @char pFormat;
stub void NdrContextHandleSize -> @void pStubMsg, @char pMemory, @char pFormat;
stub void NdrConvert -> @void pStubMsg, @char pFormat;
stub void NdrConvert2 -> @void pStubMsg, @char pFormat, int NumberParams;
stub void NdrCorrelationFree -> @void pStubMsg;
stub void NdrCorrelationInitialize -> @void pStubMsg, @void pMemory, utype int CacheSize, utype int flags;
stub void NdrCorrelationPass -> @void pStubMsg;
stub int NdrCreateServerInterfaceFromStub -> @void pStub, @void pServerIf;
stub int NdrDcomAsyncStubCall -> @void pThis, @void pChannel, @void pRpcMsg, @int pdwStubPhase;
stub void NdrEncapsulatedUnionBufferSize -> @void pStubMsg, @char pMemory, @char pFormat;
stub void NdrEncapsulatedUnionFree -> @void pStubMsg, @char pMemory, @char pFormat;
stub @char NdrEncapsulatedUnionMarshall -> @void pStubMsg, @char pMemory, @char pFormat;
stub utype int NdrEncapsulatedUnionMemorySize -> @void pStubMsg, @char pFormat;
stub @char NdrEncapsulatedUnionUnmarshall -> @void pStubMsg, @void ppMemory, @char pFormat, utype char fMustAlloc;
stub void NdrFixedArrayBufferSize -> @void pStubMsg, @char pMemory, @char pFormat;
stub void NdrFixedArrayFree -> @void pStubMsg, @char pMemory, @char pFormat;
stub @char NdrFixedArrayMarshall -> @void pStubMsg, @char pMemory, @char pFormat;
stub utype int NdrFixedArrayMemorySize -> @void pStubMsg, @char pFormat;
stub @char NdrFixedArrayUnmarshall -> @void pStubMsg, @void ppMemory, @char pFormat, utype char fMustAlloc;
stub void NdrFreeBuffer -> @void pStubMsg;
stub int NdrFullPointerFree -> @void pXlatTables, @void Pointer;
stub void NdrFullPointerInsertRefId -> @void pXlatTables, utype int RefId, @void pPointer;
stub int NdrFullPointerQueryPointer -> @void pXlatTables, @void pPointer, utype char QueryType, @int pRefId;
stub int NdrFullPointerQueryRefId -> @void pXlatTables, utype int RefId, utype char QueryType, @void ppPointer;
stub void NdrFullPointerXlatFree -> @void pXlatTables;
stub @char NdrGetBuffer -> @void pStubMsg, utype int BufferLength, @void Handle;
stub int NdrGetDcomProtocolVersion -> @void pStubMsg, @void pVersion;
stub int NdrGetUserMarshalInfo -> @int pFlags, utype int InformationLevel, @void pMarshalInfo;
stub void NdrInterfacePointerBufferSize -> @void pStubMsg, @char pMemory, @char pFormat;
stub void NdrInterfacePointerFree -> @void pStubMsg, @char pMemory, @char pFormat;
stub @char NdrInterfacePointerMarshall -> @void pStubMsg, @char pMemory, @char pFormat;
stub utype int NdrInterfacePointerMemorySize -> @void pStubMsg, @char pFormat;
stub @char NdrInterfacePointerUnmarshall -> @void pStubMsg, @void ppMemory, @char pFormat, utype char fMustAlloc;
stub int NdrMapCommAndFaultStatus -> @void pStubMsg, @int pCommStatus, @int pFaultStatus, int Status;
stub void NdrNonConformantStringBufferSize -> @void pStubMsg, @char pMemory, @char pFormat;
stub @char NdrNonConformantStringMarshall -> @void pStubMsg, @char pMemory, @char pFormat;
stub utype int NdrNonConformantStringMemorySize -> @void pStubMsg, @char pFormat;
stub @char NdrNonConformantStringUnmarshall -> @void pStubMsg, @void ppMemory, @char pFormat, utype char fMustAlloc;
stub void NdrNonEncapsulatedUnionBufferSize -> @void pStubMsg, @char pMemory, @char pFormat;
stub void NdrNonEncapsulatedUnionFree -> @void pStubMsg, @char pMemory, @char pFormat;
stub @char NdrNonEncapsulatedUnionMarshall -> @void pStubMsg, @char pMemory, @char pFormat;
stub utype int NdrNonEncapsulatedUnionMemorySize -> @void pStubMsg, @char pFormat;
stub @char NdrNonEncapsulatedUnionUnmarshall -> @void pStubMsg, @void ppMemory, @char pFormat, utype char fMustAlloc;
stub @char NdrNsGetBuffer -> @void pStubMsg, utype int BufferLength, @void Handle;
stub @char NdrNsSendReceive -> @void pStubMsg, @char pBufferEnd, @void pAutoHandle;
stub @void NdrOleAllocate -> utype longlong Size;
stub void NdrOleFree -> @void NodeToFree;
stub void NdrPartialIgnoreClientBufferSize -> @void pStubMsg, @void pMemory;
stub void NdrPartialIgnoreClientMarshall -> @void pStubMsg, @void pMemory;
stub void NdrPartialIgnoreServerInitialize -> @void pStubMsg, @void ppMemory, @char pFormat;
stub void NdrPartialIgnoreServerUnmarshall -> @void pStubMsg, @void ppMemory;
stub void NdrPointerBufferSize -> @void pStubMsg, @char pMemory, @char pFormat;
stub void NdrPointerFree -> @void pStubMsg, @char pMemory, @char pFormat;
stub @char NdrPointerMarshall -> @void pStubMsg, @char pMemory, @char pFormat;
stub utype int NdrPointerMemorySize -> @void pStubMsg, @char pFormat;
stub @char NdrPointerUnmarshall -> @void pStubMsg, @void ppMemory, @char pFormat, utype char fMustAlloc;
stub @char NdrRangeUnmarshall -> @void pStubMsg, @void ppMemory, @char pFormat, utype char fMustAlloc;
stub @void NdrRpcSmClientAllocate -> utype longlong Size;
stub void NdrRpcSmClientFree -> @void NodeToFree;
stub void NdrRpcSmSetClientToOsf -> @void pMessage;
stub @void NdrRpcSsDefaultAllocate -> utype longlong Size;
stub void NdrRpcSsDefaultFree -> @void NodeToFree;
stub void NdrRpcSsDisableAllocate -> @void pMessage;
stub void NdrRpcSsEnableAllocate -> @void pMessage;
stub @char NdrSendReceive -> @void pStubMsg, @char pBufferEnd;
stub void NdrServerCall2 -> @void pRpcMsg;
stub void NdrServerCallAll -> @void pRpcMsg;
stub void NdrServerCallNdr64 -> @void pRpcMsg;
stub void NdrServerContextMarshall -> @void pStubMsg, @void ContextHandle, @func RundownRoutine;
stub void NdrServerContextNewMarshall -> @void pStubMsg, @void ContextHandle, @func RundownRoutine, @char pFormat;
stub @void NdrServerContextNewUnmarshall -> @void pStubMsg, @char pFormat;
stub @void NdrServerContextUnmarshall -> @void pStubMsg;
stub @char NdrServerInitialize -> @void pRpcMsg, @void pStubMsg, @void pStubDescriptor;
stub void NdrServerInitializeMarshall -> @void pRpcMsg, @void pStubMsg;
stub @char NdrServerInitializeNew -> @void pRpcMsg, @void pStubMsg, @void pStubDescriptor;
stub void NdrServerInitializePartial -> @void pRpcMsg, @void pStubMsg, @void pStubDescriptor, utype int RequestedBufferSize;
stub @char NdrServerInitializeUnmarshall -> @void pStubMsg, @void pStubDescriptor, @void pRpcMsg;
stub void NdrSimpleStructBufferSize -> @void pStubMsg, @char pMemory, @char pFormat;
stub void NdrSimpleStructFree -> @void pStubMsg, @char pMemory, @char pFormat;
stub @char NdrSimpleStructMarshall -> @void pStubMsg, @char pMemory, @char pFormat;
stub utype int NdrSimpleStructMemorySize -> @void pStubMsg, @char pFormat;
stub @char NdrSimpleStructUnmarshall -> @void pStubMsg, @void ppMemory, @char pFormat, utype char fMustAlloc;
stub void NdrSimpleTypeMarshall -> @void pStubMsg, @char pMemory, utype char FormatChar;
stub void NdrSimpleTypeUnmarshall -> @void pStubMsg, @char pMemory, utype char FormatChar;
stub int NdrStubCall2 -> @void pThis, @void pChannel, @void pRpcMsg, @int pdwStubPhase;
stub int NdrStubCall3 -> @void pThis, @void pChannel, @void pRpcMsg, @int pdwStubPhase;
stub void NdrUserMarshalBufferSize -> @void pStubMsg, @char pMemory, @char pFormat;
stub void NdrUserMarshalFree -> @void pStubMsg, @char pMemory, @char pFormat;
stub @char NdrUserMarshalMarshall -> @void pStubMsg, @char pMemory, @char pFormat;
stub utype int NdrUserMarshalMemorySize -> @void pStubMsg, @char pFormat;
stub @char NdrUserMarshalSimpleTypeConvert -> @int pFlags, @char pBuffer, utype char FormatChar;
stub @char NdrUserMarshalUnmarshall -> @void pStubMsg, @void ppMemory, @char pFormat, utype char fMustAlloc;
stub void NdrVaryingArrayBufferSize -> @void pStubMsg, @char pMemory, @char pFormat;
stub void NdrVaryingArrayFree -> @void pStubMsg, @char pMemory, @char pFormat;
stub @char NdrVaryingArrayMarshall -> @void pStubMsg, @char pMemory, @char pFormat;
stub utype int NdrVaryingArrayMemorySize -> @void pStubMsg, @char pFormat;
stub @char NdrVaryingArrayUnmarshall -> @void pStubMsg, @void ppMemory, @char pFormat, utype char fMustAlloc;
stub void NdrXmitOrRepAsBufferSize -> @void pStubMsg, @char pMemory, @char pFormat;
stub void NdrXmitOrRepAsFree -> @void pStubMsg, @char pMemory, @char pFormat;
stub @char NdrXmitOrRepAsMarshall -> @void pStubMsg, @char pMemory, @char pFormat;
stub utype int NdrXmitOrRepAsMemorySize -> @void pStubMsg, @char pFormat;
stub @char NdrXmitOrRepAsUnmarshall -> @void pStubMsg, @void ppMemory, @char pFormat, utype char fMustAlloc;
stub int RpcAsyncAbortCall -> @void pAsync, utype int ExceptionCode;
stub int RpcAsyncCancelCall -> @void pAsync, int fAbort;
stub int RpcAsyncCompleteCall -> @void pAsync, @void Reply;
stub int RpcAsyncGetCallStatus -> @void pAsync;
stub int RpcAsyncInitializeHandle -> @void pAsync, utype int Size;
stub int RpcAsyncRegisterInfo -> @void pAsync;
stub int RpcBindingBind -> @void pAsync, @void Binding, @void IfSpec;
stub int RpcBindingCopy -> @void SourceBinding, @void DestinationBinding;
stub int RpcBindingCreateA -> @void Template, @void Security, @void Options, @void Binding;
stub int RpcBindingCreateW -> @void Template, @void Security, @void Options, @void Binding;
stub int RpcBindingFree -> @void Binding;
stub int RpcBindingFromStringBindingA -> @char StringBinding, @void Binding;
stub int RpcBindingFromStringBindingW -> @int StringBinding, @void Binding;
stub int RpcBindingInqAuthClientA -> @void ClientBinding, @void Privs, @void ServerPrincName, @int AuthnLevel, @int AuthnSvc, @int AuthzSvc;
stub int RpcBindingInqAuthClientExA -> @void ClientBinding, @void Privs, @void ServerPrincName, @int AuthnLevel, @int AuthnSvc, @int AuthzSvc, utype int Flags;
stub int RpcBindingInqAuthClientExW -> @void ClientBinding, @void Privs, @void ServerPrincName, @int AuthnLevel, @int AuthnSvc, @int AuthzSvc, utype int Flags;
stub int RpcBindingInqAuthClientW -> @void ClientBinding, @void Privs, @void ServerPrincName, @int AuthnLevel, @int AuthnSvc, @int AuthzSvc;
stub int RpcBindingInqAuthInfoA -> @void Binding, @void ServerPrincName, @int AuthnLevel, @int AuthnSvc, @void AuthIdentity, @int AuthzSvc;
stub int RpcBindingInqAuthInfoExA -> @void Binding, @void ServerPrincName, @int AuthnLevel, @int AuthnSvc, @void AuthIdentity, @int AuthzSvc, utype int RpcQosVersion, @void SecurityQOS;
stub int RpcBindingInqAuthInfoExW -> @void Binding, @void ServerPrincName, @int AuthnLevel, @int AuthnSvc, @void AuthIdentity, @int AuthzSvc, utype int RpcQosVersion, @void SecurityQOS;
stub int RpcBindingInqAuthInfoW -> @void Binding, @void ServerPrincName, @int AuthnLevel, @int AuthnSvc, @void AuthIdentity, @int AuthzSvc;
stub int RpcBindingInqObject -> @void Binding, @void ObjectUuid;
stub int RpcBindingInqOption -> @void hBinding, utype int option, @longlong pOptionValue;
stub int RpcBindingReset -> @void Binding;
stub int RpcBindingServerFromClient -> @void ClientBinding, @void ServerBinding;
stub int RpcBindingSetAuthInfoA -> @void Binding, @char ServerPrincName, utype int AuthnLevel, utype int AuthnSvc, @void AuthIdentity, utype int AuthzSvc;
stub int RpcBindingSetAuthInfoExA -> @void Binding, @char ServerPrincName, utype int AuthnLevel, utype int AuthnSvc, @void AuthIdentity, utype int AuthzSvc, @void SecurityQos;
stub int RpcBindingSetAuthInfoExW -> @void Binding, @int ServerPrincName, utype int AuthnLevel, utype int AuthnSvc, @void AuthIdentity, utype int AuthzSvc, @void SecurityQOS;
stub int RpcBindingSetAuthInfoW -> @void Binding, @int ServerPrincName, utype int AuthnLevel, utype int AuthnSvc, @void AuthIdentity, utype int AuthzSvc;
stub int RpcBindingSetObject -> @void Binding, @void ObjectUuid;
stub int RpcBindingSetOption -> @void hBinding, utype int option, utype longlong optionValue;
stub int RpcBindingToStringBindingA -> @void Binding, @void StringBinding;
stub int RpcBindingToStringBindingW -> @void Binding, @void StringBinding;
stub int RpcBindingUnbind -> @void Binding;
stub int RpcBindingVectorFree -> @void BindingVector;
stub int RpcCancelThread -> @void Thread;
stub int RpcCancelThreadEx -> @void Thread, int Timeout;
stub int RpcEpRegisterA -> @void IfSpec, @void BindingVector, @void UuidVector, @char Annotation;
stub int RpcEpRegisterNoReplaceA -> @void IfSpec, @void BindingVector, @void UuidVector, @char Annotation;
stub int RpcEpRegisterNoReplaceW -> @void IfSpec, @void BindingVector, @void UuidVector, @int Annotation;
stub int RpcEpRegisterW -> @void IfSpec, @void BindingVector, @void UuidVector, @int Annotation;
stub int RpcEpResolveBinding -> @void Binding, @void IfSpec;
stub int RpcEpUnregister -> @void IfSpec, @void BindingVector, @void UuidVector;
stub int RpcErrorAddRecord -> @void ErrorInfo;
stub void RpcErrorClearInformation;
stub int RpcErrorEndEnumeration -> @void EnumHandle;
stub int RpcErrorGetNextRecord -> @void EnumHandle, int CopyStrings, @void ErrorInfo;
stub int RpcErrorGetNumberOfRecords -> @void EnumHandle, @int Records;
stub int RpcErrorLoadErrorInfo -> @void ErrorBlob, utype longlong BlobSize, @void EnumHandle;
stub int RpcErrorResetEnumeration -> @void EnumHandle;
stub int RpcErrorSaveErrorInfo -> @void EnumHandle, @void ErrorBlob, @longlong BlobSize;
stub int RpcErrorStartEnumeration -> @void EnumHandle;
stub int RpcFreeAuthorizationContext -> @void pAuthzClientContext;
stub int RpcIfIdVectorFree -> @void IfIdVector;
stub int RpcIfInqId -> @void RpcIfHandle, @void RpcIfId;
stub int RpcImpersonateClient -> @void BindingHandle;
stub int RpcMgmtEnableIdleCleanup;
stub int RpcMgmtEpEltInqBegin -> @void EpBinding, utype int InquiryType, @void IfId, utype int VersOption, @void ObjectUuid, @void InquiryContext;
stub int RpcMgmtEpEltInqDone -> @void InquiryContext;
stub int RpcMgmtEpEltInqNextA -> @void InquiryContext, @void IfId, @void Binding, @void ObjectUuid, @void Annotation;
stub int RpcMgmtEpEltInqNextW -> @void InquiryContext, @void IfId, @void Binding, @void ObjectUuid, @void Annotation;
stub int RpcMgmtEpUnregister -> @void EpBinding, @void IfId, @void Binding, @void ObjectUuid;
stub int RpcMgmtInqComTimeout -> @void Binding, @int Timeout;
stub int RpcMgmtInqDefaultProtectLevel -> utype int AuthnSvc, @int AuthnLevel;
stub int RpcMgmtInqIfIds -> @void Binding, @void IfIdVector;
stub int RpcMgmtInqServerPrincNameA -> @void Binding, utype int AuthnSvc, @void ServerPrincName;
stub int RpcMgmtInqServerPrincNameW -> @void Binding, utype int AuthnSvc, @void ServerPrincName;
stub int RpcMgmtInqStats -> @void Binding, @void Statistics;
stub int RpcMgmtIsServerListening -> @void Binding;
stub int RpcMgmtSetAuthorizationFn -> @func AuthorizationFn;
stub int RpcMgmtSetCancelTimeout -> int Timeout;
stub int RpcMgmtSetComTimeout -> @void Binding, utype int Timeout;
stub int RpcMgmtSetServerStackSize -> utype int ThreadStackSize;
stub int RpcMgmtStatsVectorFree -> @void StatsVector;
stub int RpcMgmtStopServerListening -> @void Binding;
stub int RpcMgmtWaitServerListen;
stub int RpcNetworkInqProtseqsA -> @void ProtseqVector;
stub int RpcNetworkInqProtseqsW -> @void ProtseqVector;
stub int RpcNetworkIsProtseqValidA -> @char Protseq;
stub int RpcNetworkIsProtseqValidW -> @int Protseq;
stub int RpcNsBindingInqEntryNameA -> @void Binding, utype int EntryNameSyntax, @void EntryName;
stub int RpcNsBindingInqEntryNameW -> @void Binding, utype int EntryNameSyntax, @void EntryName;
stub int RpcObjectInqType -> @void ObjUuid, @void TypeUuid;
stub int RpcObjectSetInqFn -> @func InquiryFn;
stub int RpcObjectSetType -> @void ObjUuid, @void TypeUuid;
stub int RpcProtseqVectorFreeA -> @void ProtseqVector;
stub int RpcProtseqVectorFreeW -> @void ProtseqVector;
stub void RpcRaiseException -> int exception_;
stub int RpcRevertToSelf;
stub int RpcRevertToSelfEx -> @void BindingHandle;
stub int RpcServerInqBindingHandle -> @void Binding;
stub int RpcServerInqBindings -> @void BindingVector;
stub int RpcServerInqCallAttributesA -> @void ClientBinding, @void RpcCallAttributes;
stub int RpcServerInqCallAttributesW -> @void ClientBinding, @void RpcCallAttributes;
stub int RpcServerInqDefaultPrincNameA -> utype int AuthnSvc, @void PrincName;
stub int RpcServerInqDefaultPrincNameW -> utype int AuthnSvc, @void PrincName;
stub int RpcServerInqIf -> @void IfSpec, @void MgrTypeUuid, @void MgrEpv;
stub int RpcServerListen -> utype int MinimumCallThreads, utype int MaxCalls, utype int DontWait;
stub int RpcServerRegisterAuthInfoA -> @char ServerPrincName, utype int AuthnSvc, @func GetKeyFn, @void Arg;
stub int RpcServerRegisterAuthInfoW -> @int ServerPrincName, utype int AuthnSvc, @func GetKeyFn, @void Arg;
stub int RpcServerRegisterIf -> @void IfSpec, @void MgrTypeUuid, @void MgrEpv;
stub int RpcServerRegisterIf2 -> @void IfSpec, @void MgrTypeUuid, @void MgrEpv, utype int Flags, utype int MaxCalls, utype int MaxRpcSize, @func IfCallbackFn;
stub int RpcServerRegisterIfEx -> @void IfSpec, @void MgrTypeUuid, @void MgrEpv, utype int Flags, utype int MaxCalls, @func IfCallback;
stub int RpcServerTestCancel -> @void BindingHandle;
stub int RpcServerUnregisterIf -> @void IfSpec, @void MgrTypeUuid, utype int WaitForCallsToComplete;
stub int RpcServerUnregisterIfEx -> @void IfSpec, @void MgrTypeUuid, int RundownContextHandles;
stub int RpcServerUseAllProtseqs -> utype int MaxCalls, @void SecurityDescriptor;
stub int RpcServerUseAllProtseqsEx -> utype int MaxCalls, @void SecurityDescriptor, @void Policy;
stub int RpcServerUseAllProtseqsIf -> utype int MaxCalls, @void IfSpec, @void SecurityDescriptor;
stub int RpcServerUseAllProtseqsIfEx -> utype int MaxCalls, @void IfSpec, @void SecurityDescriptor, @void Policy;
stub int RpcServerUseProtseqA -> @char Protseq, utype int MaxCalls, @void SecurityDescriptor;
stub int RpcServerUseProtseqEpA -> @char Protseq, utype int MaxCalls, @char Endpoint, @void SecurityDescriptor;
stub int RpcServerUseProtseqEpExA -> @char Protseq, utype int MaxCalls, @char Endpoint, @void SecurityDescriptor, @void Policy;
stub int RpcServerUseProtseqEpExW -> @int Protseq, utype int MaxCalls, @int Endpoint, @void SecurityDescriptor, @void Policy;
stub int RpcServerUseProtseqEpW -> @int Protseq, utype int MaxCalls, @int Endpoint, @void SecurityDescriptor;
stub int RpcServerUseProtseqExA -> @char Protseq, utype int MaxCalls, @void SecurityDescriptor, @void Policy;
stub int RpcServerUseProtseqExW -> @int Protseq, utype int MaxCalls, @void SecurityDescriptor, @void Policy;
stub int RpcServerUseProtseqIfA -> @char Protseq, utype int MaxCalls, @void IfSpec, @void SecurityDescriptor;
stub int RpcServerUseProtseqIfExA -> @char Protseq, utype int MaxCalls, @void IfSpec, @void SecurityDescriptor, @void Policy;
stub int RpcServerUseProtseqIfExW -> @int Protseq, utype int MaxCalls, @void IfSpec, @void SecurityDescriptor, @void Policy;
stub int RpcServerUseProtseqIfW -> @int Protseq, utype int MaxCalls, @void IfSpec, @void SecurityDescriptor;
stub int RpcServerUseProtseqW -> @int Protseq, utype int MaxCalls, @void SecurityDescriptor;
stub void RpcServerYield;
stub @void RpcSmAllocate -> utype longlong Size, @int pStatus;
stub int RpcSmClientFree -> @void pNodeToFree;
stub int RpcSmDestroyClientContext -> @void ContextHandle;
stub int RpcSmDisableAllocate;
stub int RpcSmEnableAllocate;
stub int RpcSmFree -> @void NodeToFree;
stub @void RpcSmGetThreadHandle -> @int pStatus;
stub int RpcSmSetClientAllocFree -> @func ClientAlloc, @func ClientFree;
stub int RpcSmSetThreadHandle -> @void Id;
stub int RpcSmSwapClientAllocFree -> @func ClientAlloc, @func ClientFree, utype longlong OldClientAlloc, @void OldClientFree;
stub @void RpcSsAllocate -> utype longlong Size;
stub int RpcSsContextLockExclusive -> @void ServerBindingHandle, @void UserContext;
stub int RpcSsContextLockShared -> @void ServerBindingHandle, @void UserContext;
stub void RpcSsDestroyClientContext -> @void ContextHandle;
stub void RpcSsDisableAllocate;
stub void RpcSsDontSerializeContext;
stub void RpcSsEnableAllocate;
stub void RpcSsFree -> @void NodeToFree;
stub int RpcSsGetContextBinding -> @void ContextHandle, @void Binding;
stub @void RpcSsGetThreadHandle;
stub void RpcSsSetClientAllocFree -> @func ClientAlloc, @func ClientFree;
stub void RpcSsSetThreadHandle -> @void Id;
stub void RpcSsSwapClientAllocFree -> @func ClientAlloc, @func ClientFree, utype longlong OldClientAlloc, @void OldClientFree;
stub int RpcStringBindingComposeA -> @char ObjUuid, @char Protseq, @char NetworkAddr, @char Endpoint, @char Options, @void StringBinding;
stub int RpcStringBindingComposeW -> @int ObjUuid, @int Protseq, @int NetworkAddr, @int Endpoint, @int Options, @void StringBinding;
stub int RpcStringBindingParseA -> @char StringBinding, @void ObjUuid, @void Protseq, @void NetworkAddr, @void Endpoint, @void NetworkOptions;
stub int RpcStringBindingParseW -> @int StringBinding, @void ObjUuid, @void Protseq, @void NetworkAddr, @void Endpoint, @void NetworkOptions;
stub int RpcStringFreeA -> @void String;
stub int RpcStringFreeW -> @void String;
stub int RpcTestCancel;
stub void RpcUserFree -> @void AsyncHandle, @void pBuffer;
stub int UuidCompare -> @void Uuid1, @void Uuid2, @int Status;
stub int UuidCreate -> @void Uuid;
stub int UuidCreateNil -> @void NilUuid;
stub int UuidCreateSequential -> @void Uuid;
stub int UuidEqual -> @void Uuid1, @void Uuid2, @int Status;
stub int UuidFromStringA -> @char StringUuid, @void Uuid;
stub int UuidFromStringW -> @int StringUuid, @void Uuid;
stub utype int UuidHash -> @void Uuid, @int Status;
stub int UuidIsNil -> @void Uuid, @int Status;
stub int UuidToStringA -> @void Uuid, @void StringUuid;
stub int UuidToStringW -> @void Uuid, @void StringUuid;

!!! Declared by the headers, but with a type the language cannot write:
!!!   Ndr64AsyncClientCall
!!!   Ndr64DcomAsyncClientCall
!!!   NdrAsyncClientCall
!!!   NdrClientCall2
!!!   NdrClientCall3
!!!   NdrDcomAsyncClientCall
!!!   NdrFullPointerXlatInit
!!!   RpcGetAuthorizationContextForClient
!!!   RpcServerSubscribeForNotification
!!!   RpcServerUnsubscribeForNotification

!!! No prototype in the headers this build saw. They are here so the
!!! list is complete; uncomment and give the real signature to use one.
!!! Ndr64AsyncClientCall
!!! Ndr64DcomAsyncClientCall
!!! NdrAsyncClientCall
!!! NdrClientCall2
!!! NdrClientCall3
!!! NdrDcomAsyncClientCall
!!! NdrFullPointerXlatInit
!!! RpcGetAuthorizationContextForClient
!!! RpcServerSubscribeForNotification
!!! RpcServerUnsubscribeForNotification
