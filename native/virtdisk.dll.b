!~
~  native/virtdisk.dll.b: the virtdisk.dll functions blang code may call.
~
~  A linked DLL is described to the compiler by meta/virtdisk.dll.bmeta, and
~  that file is generated from this one with `blang.exe native/virtdisk.dll.b -m`.
~  The name has to end in `.b` after the DLL name because -m strips only the
~  last extension, so `virtdisk.dll.b` is what produces `meta/virtdisk.dll.bmeta`.
~
~  Every line below is a `stub`: a signature and nothing else. -m writes the
~  signatures into the .r even though a stub has no body, so this file declares
~  what the DLL exports while carrying no code of its own. Compiling it as
~  ordinary source reports an undefined reference instead of quietly handing
~  out functions that return 0.
~
~  The names are the exports of the DLL itself (C:\Windows\System32\virtdisk.dll),
~  matched against the prototypes windows and the headers it includes declare:
~  lists the exports, gen_names.exe keeps the ones with a
~  prototype, sigdump2 resolves the type sees, gen_dll writes this
~  file. A name the headers do not declare is left out rather than guessed.
~!

!!! ---- generated from the Windows headers below this line ----
!!!
!!! One declaration per virtdisk.dll export that the headers declare. The
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
!!! 10 declarations here, 0 kept from the hand-checked list above, 15 names
!!! have no prototype in these headers and are listed as comments below.
!!!

stub utype int AddVirtualDiskParent -> @void VirtualDiskHandle, @void ParentPath;
stub utype int BreakMirrorVirtualDisk -> @void VirtualDiskHandle;
stub utype int DeleteVirtualDiskMetadata -> @void VirtualDiskHandle, @void Item;
stub utype int EnumerateVirtualDiskMetadata -> @void VirtualDiskHandle, @int NumberOfItems, @void Items;
stub utype int GetVirtualDiskInformation -> @void VirtualDiskHandle, @int VirtualDiskInfoSize, @void VirtualDiskInfo, @int SizeUsed;
stub utype int GetVirtualDiskMetadata -> @void VirtualDiskHandle, @void Item, @int MetaDataSize, @void MetaData;
stub utype int GetVirtualDiskOperationProgress -> @void VirtualDiskHandle, @void Overlapped, @void Progress;
stub utype int GetVirtualDiskPhysicalPath -> @void VirtualDiskHandle, @int DiskPathSizeInBytes, @void DiskPath;
stub utype int SetVirtualDiskInformation -> @void VirtualDiskHandle, @void VirtualDiskInfo;
stub utype int SetVirtualDiskMetadata -> @void VirtualDiskHandle, @void Item, utype int MetaDataSize, @void MetaData;

!!! Declared by the headers, but with a type the language cannot write:
!!!   ApplySnapshotVhdSet
!!!   AttachVirtualDisk
!!!   CompactVirtualDisk
!!!   CreateVirtualDisk
!!!   DeleteSnapshotVhdSet
!!!   DetachVirtualDisk
!!!   ExpandVirtualDisk
!!!   GetStorageDependencyInformation
!!!   MergeVirtualDisk
!!!   MirrorVirtualDisk
!!!   ModifyVhdSet
!!!   OpenVirtualDisk
!!!   QueryChangesVirtualDisk
!!!   ResizeVirtualDisk
!!!   TakeSnapshotVhdSet

!!! No prototype in the headers this build saw. They are here so the
!!! list is complete; uncomment and give the real signature to use one.
!!! ApplySnapshotVhdSet
!!! AttachVirtualDisk
!!! CompactVirtualDisk
!!! CreateVirtualDisk
!!! DeleteSnapshotVhdSet
!!! DetachVirtualDisk
!!! ExpandVirtualDisk
!!! GetStorageDependencyInformation
!!! MergeVirtualDisk
!!! MirrorVirtualDisk
!!! ModifyVhdSet
!!! OpenVirtualDisk
!!! QueryChangesVirtualDisk
!!! ResizeVirtualDisk
!!! TakeSnapshotVhdSet
