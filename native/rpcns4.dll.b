!~
~  native/rpcns4.dll.b: the rpcns4.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/rpcns4.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/rpcns4.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `rpcns4.dll.b` is what produces `meta/rpcns4.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\rpcns4.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per rpcns4.dll export that the headers declare. The
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

stub int I_RpcNsGetBuffer -> @void Message;
stub void I_RpcNsRaiseException -> @void Message, int Status;
stub int I_RpcNsSendReceive -> @void Message, @void Handle;
stub int I_RpcReBindBuffer -> @void Message;
stub int RpcIfIdVectorFree -> @void IfIdVector;
stub int RpcNsBindingExportA -> utype int EntryNameSyntax, @char EntryName, @void IfSpec, @void BindingVec, @void ObjectUuidVec;
stub int RpcNsBindingExportPnPA -> utype int EntryNameSyntax, @char EntryName, @void IfSpec, @void ObjectVector;
stub int RpcNsBindingExportPnPW -> utype int EntryNameSyntax, @int EntryName, @void IfSpec, @void ObjectVector;
stub int RpcNsBindingExportW -> utype int EntryNameSyntax, @int EntryName, @void IfSpec, @void BindingVec, @void ObjectUuidVec;
stub int RpcNsBindingImportBeginA -> utype int EntryNameSyntax, @char EntryName, @void IfSpec, @void ObjUuid, @void ImportContext;
stub int RpcNsBindingImportBeginW -> utype int EntryNameSyntax, @int EntryName, @void IfSpec, @void ObjUuid, @void ImportContext;
stub int RpcNsBindingImportDone -> @void ImportContext;
stub int RpcNsBindingImportNext -> @void ImportContext, @void Binding;
stub int RpcNsBindingLookupBeginA -> utype int EntryNameSyntax, @char EntryName, @void IfSpec, @void ObjUuid, utype int BindingMaxCount, @void LookupContext;
stub int RpcNsBindingLookupBeginW -> utype int EntryNameSyntax, @int EntryName, @void IfSpec, @void ObjUuid, utype int BindingMaxCount, @void LookupContext;
stub int RpcNsBindingLookupDone -> @void LookupContext;
stub int RpcNsBindingLookupNext -> @void LookupContext, @void BindingVec;
stub int RpcNsBindingSelect -> @void BindingVec, @void Binding;
stub int RpcNsBindingUnexportA -> utype int EntryNameSyntax, @char EntryName, @void IfSpec, @void ObjectUuidVec;
stub int RpcNsBindingUnexportPnPA -> utype int EntryNameSyntax, @char EntryName, @void IfSpec, @void ObjectVector;
stub int RpcNsBindingUnexportPnPW -> utype int EntryNameSyntax, @int EntryName, @void IfSpec, @void ObjectVector;
stub int RpcNsBindingUnexportW -> utype int EntryNameSyntax, @int EntryName, @void IfSpec, @void ObjectUuidVec;
stub int RpcNsEntryExpandNameA -> utype int EntryNameSyntax, @char EntryName, @void ExpandedName;
stub int RpcNsEntryExpandNameW -> utype int EntryNameSyntax, @int EntryName, @void ExpandedName;
stub int RpcNsEntryObjectInqBeginA -> utype int EntryNameSyntax, @char EntryName, @void InquiryContext;
stub int RpcNsEntryObjectInqBeginW -> utype int EntryNameSyntax, @int EntryName, @void InquiryContext;
stub int RpcNsEntryObjectInqDone -> @void InquiryContext;
stub int RpcNsEntryObjectInqNext -> @void InquiryContext, @void ObjUuid;
stub int RpcNsGroupDeleteA -> utype int GroupNameSyntax, @char GroupName;
stub int RpcNsGroupDeleteW -> utype int GroupNameSyntax, @int GroupName;
stub int RpcNsGroupMbrAddA -> utype int GroupNameSyntax, @char GroupName, utype int MemberNameSyntax, @char MemberName;
stub int RpcNsGroupMbrAddW -> utype int GroupNameSyntax, @int GroupName, utype int MemberNameSyntax, @int MemberName;
stub int RpcNsGroupMbrInqBeginA -> utype int GroupNameSyntax, @char GroupName, utype int MemberNameSyntax, @void InquiryContext;
stub int RpcNsGroupMbrInqBeginW -> utype int GroupNameSyntax, @int GroupName, utype int MemberNameSyntax, @void InquiryContext;
stub int RpcNsGroupMbrInqDone -> @void InquiryContext;
stub int RpcNsGroupMbrInqNextA -> @void InquiryContext, @void MemberName;
stub int RpcNsGroupMbrInqNextW -> @void InquiryContext, @void MemberName;
stub int RpcNsGroupMbrRemoveA -> utype int GroupNameSyntax, @char GroupName, utype int MemberNameSyntax, @char MemberName;
stub int RpcNsGroupMbrRemoveW -> utype int GroupNameSyntax, @int GroupName, utype int MemberNameSyntax, @int MemberName;
stub int RpcNsMgmtBindingUnexportA -> utype int EntryNameSyntax, @char EntryName, @void IfId, utype int VersOption, @void ObjectUuidVec;
stub int RpcNsMgmtBindingUnexportW -> utype int EntryNameSyntax, @int EntryName, @void IfId, utype int VersOption, @void ObjectUuidVec;
stub int RpcNsMgmtEntryCreateA -> utype int EntryNameSyntax, @char EntryName;
stub int RpcNsMgmtEntryCreateW -> utype int EntryNameSyntax, @int EntryName;
stub int RpcNsMgmtEntryDeleteA -> utype int EntryNameSyntax, @char EntryName;
stub int RpcNsMgmtEntryDeleteW -> utype int EntryNameSyntax, @int EntryName;
stub int RpcNsMgmtEntryInqIfIdsA -> utype int EntryNameSyntax, @char EntryName, @void IfIdVec;
stub int RpcNsMgmtEntryInqIfIdsW -> utype int EntryNameSyntax, @int EntryName, @void IfIdVec;
stub int RpcNsMgmtHandleSetExpAge -> @void NsHandle, utype int ExpirationAge;
stub int RpcNsMgmtInqExpAge -> @int ExpirationAge;
stub int RpcNsMgmtSetExpAge -> utype int ExpirationAge;
stub int RpcNsProfileDeleteA -> utype int ProfileNameSyntax, @char ProfileName;
stub int RpcNsProfileDeleteW -> utype int ProfileNameSyntax, @int ProfileName;
stub int RpcNsProfileEltAddA -> utype int ProfileNameSyntax, @char ProfileName, @void IfId, utype int MemberNameSyntax, @char MemberName, utype int Priority, @char Annotation;
stub int RpcNsProfileEltAddW -> utype int ProfileNameSyntax, @int ProfileName, @void IfId, utype int MemberNameSyntax, @int MemberName, utype int Priority, @int Annotation;
stub int RpcNsProfileEltInqBeginA -> utype int ProfileNameSyntax, @char ProfileName, utype int InquiryType, @void IfId, utype int VersOption, utype int MemberNameSyntax, @char MemberName, @void InquiryContext;
stub int RpcNsProfileEltInqBeginW -> utype int ProfileNameSyntax, @int ProfileName, utype int InquiryType, @void IfId, utype int VersOption, utype int MemberNameSyntax, @int MemberName, @void InquiryContext;
stub int RpcNsProfileEltInqDone -> @void InquiryContext;
stub int RpcNsProfileEltInqNextA -> @void InquiryContext, @void IfId, @void MemberName, @int Priority, @void Annotation;
stub int RpcNsProfileEltInqNextW -> @void InquiryContext, @void IfId, @void MemberName, @int Priority, @void Annotation;
stub int RpcNsProfileEltRemoveA -> utype int ProfileNameSyntax, @char ProfileName, @void IfId, utype int MemberNameSyntax, @char MemberName;
stub int RpcNsProfileEltRemoveW -> utype int ProfileNameSyntax, @int ProfileName, @void IfId, utype int MemberNameSyntax, @int MemberName;
