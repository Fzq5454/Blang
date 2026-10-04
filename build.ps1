# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# build.ps1: build the blang toolchain from the b sources in this tree.
#
# This tree is the compiler written in b and nothing else. It is built with a
# compiler of a previous release - the seed - which is attached to the release
# and goes into bin\:
#
#     bin\blang.exe, bin\gn.exe, bin\cmp.exe
#     bin\libbrtm.dll, bin\libbprintf.dll, bin\libbfile.dll,
#     bin\libbmath.dll, bin\libbwin.dll, bin\libbstr.dll
#
# With those in place, run this script from the root of the tree:
#
#     powershell -File build.ps1
#
# What it does, in order:
#
#   1. the seed writes meta\<dll>.bmeta from every native\*.dll.b - the signature
#      of one system DLL. They are what makes `-system kernel32` and the calls the
#      runtime itself makes resolvable.
#   2. the runtime is built from runtime\*.b into bin\lib<name>.dll, each with the
#      side file (meta\lib<name>.dll.bst) a static build reads, and the DLLs are
#      copied next to the programs that will use them.
#   3. bootstrap\build.ps1 builds the three programs of the toolchain from
#      bootstrap\*.b into bootstrap\bin, this time with the seed compiler.
#   4. the fixed point is checked: the compiler built in step 3 rebuilds the whole
#      toolchain into a scratch directory, and the result has to be byte-identical
#      to what step 3 wrote. A self-hosting toolchain that cannot reproduce itself
#      fails here.
#
# The seed in bin\ is not built by this script. This tree has no C++ in it and no
# binary is committed, so a compiler has to come from somewhere: it comes from the
# release assets.
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$seed = "bin\blang.exe"
foreach ($f in @("bin\blang.exe", "bin\gn.exe", "bin\cmp.exe")) {
    if (-not (Test-Path $f)) {
        Write-Error "$f is missing: put the seed compiler of a release into bin\ first (see README.md)"
    }
}

# ---- 1. the signatures of the system DLLs ----
# `-m` stops after the front end and writes meta\<name>.bmeta; blang.exe strips
# only the last extension, so native\kernel32.dll.b gives meta\kernel32.dll.bmeta.
New-Item -ItemType Directory -Force -Path "meta" | Out-Null
foreach ($f in Get-ChildItem "native" -Filter *.b) {
    & $seed $f.FullName -m
    if ($LASTEXITCODE -ne 0) { Write-Error "blang.exe -m failed on $($f.Name)" }
}

# ---- 2. the runtime ----
# --no-runtime (through -CMP, which passes the argument to cmp as it is) is what a
# runtime DLL's own build needs: without it the DLL would import the very runtime
# it is defining. -system names the system DLLs the module calls, and libbwin also
# draws and makes windows, so it needs user32 and gdi32.
#
# The DLLs are written into a scratch directory and put into bin\ only after the
# last seed process has exited: the seed compiler has bin\lib<name>.dll loaded
# while it runs, and Windows does not let the child that writes the file replace an
# image another process has mapped.
$scratchRun = "stage0_rt"
if (Test-Path $scratchRun) { Remove-Item $scratchRun -Recurse -Force }
New-Item -ItemType Directory -Force -Path $scratchRun | Out-Null
foreach ($f in Get-ChildItem "runtime" -Filter *.b) {
    $name = $f.BaseName
    $out = "$scratchRun\lib$name.dll"
    if ($name -eq "bwin") {
        & $seed $f.FullName '-CMP,--no-runtime' -system kernel32 -system user32 -system gdi32 -o $out
    } else {
        & $seed $f.FullName '-CMP,--no-runtime' -system kernel32 -o $out
    }
    if ($LASTEXITCODE -ne 0) { Write-Error "blang.exe failed on $($f.Name)" }
}

New-Item -ItemType Directory -Force -Path "bin" | Out-Null
Copy-Item "$scratchRun\lib*.dll" "bin\" -Force
# A program finds its DLLs in the directory it is in, and a program is built next
# to its own source, so the runtime goes there as well.
Copy-Item "$scratchRun\lib*.dll" "." -Force
Remove-Item $scratchRun -Recurse -Force

# ---- 3. the toolchain ----
& powershell -File bootstrap\build.ps1
if ($LASTEXITCODE -ne 0) { Write-Error "bootstrap\build.ps1 failed" }

# ---- 4. the fixed point ----
$scratch = "stage2"
if (Test-Path $scratch) { Remove-Item $scratch -Recurse -Force }
New-Item -ItemType Directory -Force -Path $scratch | Out-Null
$stage1 = "bootstrap\bin\blang.exe"

& $stage1 bootstrap\blang.b -o "$scratch\blang.exe" -P bootstrap\frontend -system kernel32 -dbrtm -dbfile -dbstr -W-all
if ($LASTEXITCODE -ne 0) { Write-Error "the second-stage compiler did not build" }
& $stage1 bootstrap\gn.b -o "$scratch\gn.exe" -P bootstrap\frontend -system kernel32 -dbrtm -dbfile -dbstr -W-all
if ($LASTEXITCODE -ne 0) { Write-Error "the second-stage scheduler did not build" }
& $stage1 bootstrap\cmp.b -o "$scratch\cmp.exe" -P bootstrap\backend -system kernel32 -dbrtm -dbfile -dbstr -W-all
if ($LASTEXITCODE -ne 0) { Write-Error "the second-stage backend did not build" }

$different = 0
foreach ($f in @("blang.exe", "gn.exe", "cmp.exe")) {
    $a = (Get-FileHash "bootstrap\bin\$f" -Algorithm SHA256).Hash
    $b = (Get-FileHash "$scratch\$f" -Algorithm SHA256).Hash
    if ($a -eq $b) {
        Write-Host "fixed point: $f rebuilt identically"
    } else {
        Write-Host "fixed point: $f DIFFERS"
        $different = 1
    }
}
if ($different -ne 0) { Write-Error "the toolchain did not reproduce itself" }
Remove-Item $scratch -Recurse -Force

Write-Host ""
Write-Host "build complete: bootstrap\bin holds blang.exe, gn.exe and cmp.exe"
Write-Host "try it:  bootstrap\bin\blang.exe -o hello.exe hello.b   then   hello.exe"
