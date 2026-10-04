# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# bootstrap/build.ps1: build the self-hosted compiler.
#
# The stage-0 compiler (bin\blang.exe, built by "mingw32-make -f Makefile")
# compiles bootstrap\blang.b with the modules in bootstrap\frontend on the #head
# search path. The result is a stage-1 compiler that replaces the stage-0 one as
# more of the front end and the backend are ported.
#
# The toolchain is three programs, the way the C++ one is: blang.exe parses the
# options and hands the work to gn.exe, gn.exe runs the front end and hands the .r
# text to cmp.exe, and cmp.exe writes the image. All three are built here, and the
# two that run the front end read the same modules under bootstrap\frontend.
#
# Run from the repository root:  powershell -File bootstrap\build.ps1
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$stage0 = "bin\blang.exe"
if (-not (Test-Path $stage0)) {
    Write-Error "$stage0 is missing: build it first with 'mingw32-make -f Makefile'"
}

$out = "bootstrap\bin\blang.exe"
New-Item -ItemType Directory -Force -Path "bootstrap\bin" | Out-Null

# The modules are reached through #head, so bootstrap\frontend is a -P directory.
# -dbrtm and -dbfile declare the runtime and file API the driver calls, and -dbstr
# is libbstr.dll: the compiler's own utility library (colors and the diagnostic
# layout), built from runtime/bstr.b instead of the C++ libstr.
# -W-nused asks the front end for the unused variable and function warnings, so the
# self-hosted compiler is built with the warnings the C++ compiler is built with.
& $stage0 bootstrap\blang.b -o $out -P bootstrap\frontend -system kernel32 -dbrtm -dbfile -dbstr -W-all
if ($LASTEXITCODE -ne 0) {
    Write-Error "the stage-1 compiler did not build"
}

# An .exe finds its DLLs next to itself, and the runtime lives in bin\.
foreach ($dll in @("libbrtm.dll", "libbprintf.dll", "libbfile.dll", "libbwin.dll", "libbmath.dll", "libbstr.dll")) {
    if (Test-Path "bin\$dll") { Copy-Item "bin\$dll" "bootstrap\bin\" -Force }
}

# The side files go with the DLLs. A side file is looked for beside the compiler
# first (bootstrap\bin\meta), one directory above it next (bootstrap\meta) and only
# then in the meta\ of the working directory, which is the order the C++ readers
# use. A side file left in bootstrap\meta by an older runtime therefore hides the
# fresh one there, and the self-hosted compiler then cannot see a declaration the
# runtime it links really exports: an export added to runtime\bstr.b broke the
# build of bootstrap\gn.b and bootstrap\cmp.b that way. They are kept in step here,
# from the meta\ the build of this checkout just wrote.
New-Item -ItemType Directory -Force -Path "bootstrap\meta" | Out-Null
foreach ($f in Get-ChildItem "meta" -File) {
    Copy-Item $f.FullName "bootstrap\meta\" -Force
}

# The stage-1 compiler runs the rest of the toolchain the way the C++ driver does:
# it looks for gn.exe and cmp.exe beside itself and hands them the work. Both are
# the C++ ones for now, and libstr.dll goes with cmp.exe.
foreach ($f in @("gn.exe", "cmp.exe", "libstr.dll")) {
    if (Test-Path "bin\$f") { Copy-Item "bin\$f" "bootstrap\bin\" -Force }
}

# ... and then both of them are built from bootstrap\gn.b and bootstrap\cmp.b, so
# the toolchain stands on its own: from here on blang.exe, gn.exe and cmp.exe are
# all the port, and the C++ ones stay in bin\ as the reference they are compared
# against.
#
# It is built with the stage-0 compiler and not with the stage-1 one: the stage-1
# compiler runs the backend beside itself, which is the very file this writes, and
# Windows will not let a process overwrite the image it is running. The two front
# ends are byte-identical, so it does not matter which of them does the build.
& $stage0 bootstrap\gn.b -o bootstrap\bin\gn.exe -P bootstrap\frontend -system kernel32 -dbrtm -dbfile -dbstr -W-all
if ($LASTEXITCODE -ne 0) {
    Write-Error "the self-hosted scheduler did not build"
}

& $stage0 bootstrap\cmp.b -o bootstrap\bin\cmp.exe -P bootstrap\backend -system kernel32 -dbrtm -dbfile -dbstr -W-all
if ($LASTEXITCODE -ne 0) {
    Write-Error "the self-hosted backend did not build"
}

$size = (Get-Item $out).Length
Write-Host "built $out ($size bytes)"
Write-Host "built bootstrap\bin\gn.exe ($((Get-Item bootstrap\bin\gn.exe).Length) bytes)"
Write-Host "built bootstrap\bin\cmp.exe ($((Get-Item bootstrap\bin\cmp.exe).Length) bytes)"
