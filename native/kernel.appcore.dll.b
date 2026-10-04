!~
~  native/kernel.appcore.dll.b: the kernel.appcore.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/kernel.appcore.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/kernel.appcore.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `kernel.appcore.dll.b` is what produces `meta/kernel.appcore.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\kernel.appcore.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per kernel.appcore.dll export that the headers declare. The
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
!!! 42 declarations here, 0 kept from the hand-checked list above, 3 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub int AppPolicyGetClrCompat -> @void processToken, @void policy;
stub int AppPolicyGetCreateFileAccess -> @void processToken, @void policy;
stub int AppPolicyGetLifecycleManagement -> @void processToken, @void policy;
stub int AppPolicyGetMediaFoundationCodecLoading -> @void processToken, @void policy;
stub int AppPolicyGetProcessTerminationMethod -> @void processToken, @void policy;
stub int AppPolicyGetShowDeveloperDiagnostic -> @void processToken, @void policy;
stub int AppPolicyGetThreadInitializationType -> @void processToken, @void policy;
stub int AppPolicyGetWindowingModel -> @void processToken, @void policy;
stub int CheckIsMSIXPackage -> @void packageFullName, @int isMSIXPackage;
stub int FindPackagesByPackageFamily -> @void packageFamilyName, utype int packageFilters, @int cnt, @void packageFullNames, @int bufferLength, @void buffer, @int packageProperties;
stub int FormatApplicationUserModelId -> @void packageFamilyName, @void packageRelativeApplicationId, @int applicationUserModelIdLength, @void applicationUserModelId;
stub int GetApplicationUserModelId -> @void hProcess, @int applicationUserModelIdLength, @void applicationUserModelId;
stub int GetApplicationUserModelIdFromToken -> @void token, @int applicationUserModelIdLength, @void applicationUserModelId;
stub int GetCurrentApplicationUserModelId -> @int applicationUserModelIdLength, @void applicationUserModelId;
stub int GetCurrentPackageFamilyName -> @int packageFamilyNameLength, @void packageFamilyName;
stub int GetCurrentPackageFullName -> @int packageFullNameLength, @void packageFullName;
stub int GetCurrentPackageId -> @int bufferLength, @char buffer;
stub int GetCurrentPackageInfo -> utype int flags, @int bufferLength, @char buffer, @int cnt;
stub int GetCurrentPackagePath -> @int pathLength, @void path;
stub int GetPackageFamilyName -> @void hProcess, @int packageFamilyNameLength, @void packageFamilyName;
stub int GetPackageFamilyNameFromToken -> @void token, @int packageFamilyNameLength, @void packageFamilyName;
stub int GetPackageFullName -> @void hProcess, @int packageFullNameLength, @void packageFullName;
stub int GetPackageFullNameFromToken -> @void token, @int packageFullNameLength, @void packageFullName;
stub int GetPackageId -> @void hProcess, @int bufferLength, @char buffer;
stub int GetPackagePath -> @void packageId, utype int reserved, @int pathLength, @void path;
stub int GetPackagePathByFullName -> @void packageFullName, @int pathLength, @void path;
stub int GetPackagesByPackageFamily -> @void packageFamilyName, @int cnt, @void packageFullNames, @int bufferLength, @void buffer;
stub int GetStagedPackageOrigin -> @void packageFullName, @void origin;
stub int GetStagedPackagePathByFullName -> @void packageFullName, @int pathLength, @void path;
stub int OpenPackageInfoByFullName -> @void packageFullName, utype int reserved, @void packageInfoReference;
stub int OpenPackageInfoByFullNameForUser -> @void userSid, @void packageFullName, utype int reserved, @void packageInfoReference;
stub int PackageFamilyNameFromFullName -> @void packageFullName, @int packageFamilyNameLength, @void packageFamilyName;
stub int PackageFamilyNameFromId -> @void packageId, @int packageFamilyNameLength, @void packageFamilyName;
stub int PackageFullNameFromId -> @void packageId, @int packageFullNameLength, @void packageFullName;
stub int PackageIdFromFullName -> @void packageFullName, utype int flags, @int bufferLength, @char buffer;
stub int PackageNameAndPublisherIdFromFamilyName -> @void packageFamilyName, @int packageNameLength, @void packageName, @int packagePublisherIdLength, @void packagePublisherId;
stub int ParseApplicationUserModelId -> @void applicationUserModelId, @int packageFamilyNameLength, @void packageFamilyName, @int packageRelativeApplicationIdLength, @void packageRelativeApplicationId;
stub int VerifyApplicationUserModelId -> @void applicationUserModelId;
stub int VerifyPackageFamilyName -> @void packageFamilyName;
stub int VerifyPackageFullName -> @void packageFullName;
stub int VerifyPackageId -> @void packageId;
stub int VerifyPackageRelativeApplicationId -> @void packageRelativeApplicationId;

!!! Declared by the headers, but with a type the language cannot write:
!!!   ClosePackageInfo
!!!   GetPackageApplicationIds
!!!   GetPackageInfo

!!! No prototype in the headers this build saw. They are here so the
!!! list is complete; uncomment and give the real signature to use one.
!!! ClosePackageInfo
!!! GetPackageApplicationIds
!!! GetPackageInfo
