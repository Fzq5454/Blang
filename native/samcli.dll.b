!~
~  native/samcli.dll.b: the samcli.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/samcli.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/samcli.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `samcli.dll.b` is what produces `meta/samcli.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\samcli.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per samcli.dll export that the headers declare. The
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
!!! 34 declarations here, 0 kept from the hand-checked list above, 1 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub utype int NetGetDisplayInformationIndex -> @void ServerName, utype int Level, @void Prefix, @int Index;
stub utype int NetGroupAdd -> @void servername, utype int level, @char buf, @int parm_err;
stub utype int NetGroupAddUser -> @void servername, @void GroupName, @void username;
stub utype int NetGroupDel -> @void servername, @void groupname;
stub utype int NetGroupDelUser -> @void servername, @void GroupName, @void Username;
stub utype int NetGroupEnum -> @void servername, utype int level, @void bufptr, utype int prefmaxlen, @int entriesread, @int totalentries, @longlong resume_handle;
stub utype int NetGroupGetInfo -> @void servername, @void groupname, utype int level, @void bufptr;
stub utype int NetGroupGetUsers -> @void servername, @void groupname, utype int level, @void bufptr, utype int prefmaxlen, @int entriesread, @int totalentries, @longlong ResumeHandle;
stub utype int NetGroupSetInfo -> @void servername, @void groupname, utype int level, @char buf, @int parm_err;
stub utype int NetGroupSetUsers -> @void servername, @void groupname, utype int level, @char buf, utype int totalentries;
stub utype int NetLocalGroupAdd -> @void servername, utype int level, @char buf, @int parm_err;
stub utype int NetLocalGroupAddMember -> @void servername, @void groupname, @void membersid;
stub utype int NetLocalGroupAddMembers -> @void servername, @void groupname, utype int level, @char buf, utype int totalentries;
stub utype int NetLocalGroupDel -> @void servername, @void groupname;
stub utype int NetLocalGroupDelMember -> @void servername, @void groupname, @void membersid;
stub utype int NetLocalGroupDelMembers -> @void servername, @void groupname, utype int level, @char buf, utype int totalentries;
stub utype int NetLocalGroupEnum -> @void servername, utype int level, @void bufptr, utype int prefmaxlen, @int entriesread, @int totalentries, @longlong resumehandle;
stub utype int NetLocalGroupGetInfo -> @void servername, @void groupname, utype int level, @void bufptr;
stub utype int NetLocalGroupGetMembers -> @void servername, @void localgroupname, utype int level, @void bufptr, utype int prefmaxlen, @int entriesread, @int totalentries, @longlong resumehandle;
stub utype int NetLocalGroupSetInfo -> @void servername, @void groupname, utype int level, @char buf, @int parm_err;
stub utype int NetLocalGroupSetMembers -> @void servername, @void groupname, utype int level, @char buf, utype int totalentries;
stub utype int NetQueryDisplayInformation -> @void ServerName, utype int Level, utype int Index, utype int EntriesRequested, utype int PreferredMaximumLength, @int ReturnedEntryCount, @void SortedBuffer;
stub utype int NetUserAdd -> @void servername, utype int level, @char buf, @int parm_err;
stub utype int NetUserChangePassword -> @void domainname, @void username, @void oldpassword, @void newpassword;
stub utype int NetUserDel -> @void servername, @void username;
stub utype int NetUserEnum -> @void servername, utype int level, utype int filter, @void bufptr, utype int prefmaxlen, @int entriesread, @int totalentries, @int resume_handle;
stub utype int NetUserGetGroups -> @void servername, @void username, utype int level, @void bufptr, utype int prefmaxlen, @int entriesread, @int totalentries;
stub utype int NetUserGetInfo -> @void servername, @void username, utype int level, @void bufptr;
stub utype int NetUserGetLocalGroups -> @void servername, @void username, utype int level, utype int flags, @void bufptr, utype int prefmaxlen, @int entriesread, @int totalentries;
stub utype int NetUserModalsGet -> @void servername, utype int level, @void bufptr;
stub utype int NetUserModalsSet -> @void servername, utype int level, @char buf, @int parm_err;
stub utype int NetUserSetGroups -> @void servername, @void username, utype int level, @char buf, utype int num_entries;
stub utype int NetUserSetInfo -> @void servername, @void username, utype int level, @char buf, @int parm_err;
stub utype int NetValidatePasswordPolicyFree -> @void OutputArg;

!!! Declared by the headers, but with a type the language cannot write:
!!!   NetValidatePasswordPolicy

!!! No prototype in the headers this build saw. They are here so the
!!! list is complete; uncomment and give the real signature to use one.
!!! NetValidatePasswordPolicy
