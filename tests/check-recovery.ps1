# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# tests/check-recovery.ps1: run the error-recovery cases through both compilers.
#
# A compiler owes its caller every error in a file, not just the first one: after
# a mistake it has to get back in step and read on, or one stray byte buries the
# output in messages about the characters that follow it. The cases in
# tests\recovery\ are files written to be wrong in one way each - a stray byte, a
# missing `)`, an unterminated literal, a broken declaration - and this script
# runs every one of them through the seed compiler (bin\blang.exe, from the
# release) and the one this tree has just built (bootstrap\bin\blang.exe) and holds
# the two answers against each other:
#
#   * the exit code,
#   * the standard output and the standard error (line endings and the random
#     name of a temporary .r file taken out, see below),
#   * the .r text, byte for byte.
#
# A case passes only when all of them agree. The first line that differs is
# printed for a case that fails, and -Show prints both texts whole.
#
# Build the toolchain first (the seed goes into bin\, see README.md):
#   powershell -File build.ps1
# Then run from anywhere:
#   powershell -File tests\check-recovery.ps1
#   powershell -File tests\check-recovery.ps1 -Show          (whole texts)
#   powershell -File tests\check-recovery.ps1 -Case lex_dots  (one case)
#   powershell -File tests\check-recovery.ps1 -Chinese        (with -Chinese)
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

param(
    [switch]$Show,
    [string]$Case = "",
    [switch]$Chinese
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$reference = "bin\blang.exe"
$port = "bootstrap\bin\blang.exe"
foreach ($exe in @($reference, $port)) {
    if (-not (Test-Path -LiteralPath $exe)) {
        Write-Error "$exe is missing: build it first (powershell -File build.ps1)"
    }
}

$caseDir = Join-Path $PSScriptRoot "recovery"
$outDir = Join-Path $PSScriptRoot "out"
if (Test-Path -LiteralPath $outDir) { Remove-Item -LiteralPath $outDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function Run-Tool {
    param([string]$Exe, [string[]]$ArgList, [string]$Out, [string]$Err)
    $p = Start-Process -FilePath $Exe -ArgumentList $ArgList -NoNewWindow -Wait -PassThru `
                       -RedirectStandardOutput $Out -RedirectStandardError $Err
    return $p.ExitCode
}

# The text of a stream, with the two things that are not a difference in what the
# compiler said taken out: a CRLF is a line ending like a LF, and the name of the
# temporary .r file a `#to`-less run hands cmp.exe is a fresh one every time.
function Read-Text {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return "<none>" }
    $t = [IO.File]::ReadAllText($Path, [Text.Encoding]::UTF8) -replace "`r`n", "`n"
    return ($t -replace '\\Temp\\[A-Za-z0-9]+\.r', '\Temp\NAME.r')
}

function Same-File {
    param([string]$A, [string]$B)
    $ea = Test-Path -LiteralPath $A
    $eb = Test-Path -LiteralPath $B
    if (-not $ea -and -not $eb) { return $true }
    if (-not $ea -or -not $eb) { return $false }
    return [Linq.Enumerable]::SequenceEqual([byte[]][IO.File]::ReadAllBytes($A),
                                            [byte[]][IO.File]::ReadAllBytes($B))
}

function First-Difference {
    param([string]$A, [string]$B)
    $al = @($A -split "`n")
    $bl = @($B -split "`n")
    for ($i = 0; $i -lt [Math]::Max($al.Count, $bl.Count); $i++) {
        $x = if ($i -lt $al.Count) { $al[$i] } else { "<end of text>" }
        $y = if ($i -lt $bl.Count) { $bl[$i] } else { "<end of text>" }
        if ($x -ne $y) {
            return "    line $($i + 1)`n      reference: $x`n      port:      $y"
        }
    }
    return "    (the same lines, a different length)"
}

$cases = @(Get-ChildItem -LiteralPath $caseDir -File -Filter *.b | Sort-Object Name)
if ($Case -ne "") {
    $cases = @($cases | Where-Object { $_.BaseName -like "*$Case*" })
    if ($cases.Count -eq 0) { Write-Error "no case matches '$Case'" }
}

$failed = 0
foreach ($c in $cases) {
    $name = $c.BaseName
    $refOut = Join-Path $outDir "$name.ref.out"
    $refErr = Join-Path $outDir "$name.ref.err"
    $portOut = Join-Path $outDir "$name.port.out"
    $portErr = Join-Path $outDir "$name.port.err"
    $refR = Join-Path $outDir "$name.ref.r"
    $portR = Join-Path $outDir "$name.port.r"

    $flags = @($c.FullName, "-R", "-o", $refR)
    if ($Chinese) { $flags += "-Chinese" }
    $rcRef = Run-Tool $reference $flags $refOut $refErr

    $flags = @($c.FullName, "-R", "-o", $portR)
    if ($Chinese) { $flags += "-Chinese" }
    $rcPort = Run-Tool $port $flags $portOut $portErr

    $problems = @()
    if ($rcRef -ne $rcPort) { $problems += "exit code $rcRef against $rcPort" }
    $refText = Read-Text $refErr
    $portText = Read-Text $portErr
    if ($refText -ne $portText) { $problems += "standard error" }
    if ((Read-Text $refOut) -ne (Read-Text $portOut)) { $problems += "standard output" }
    if (-not (Same-File $refR $portR)) { $problems += "the .r text" }
    # A case the compiler could not even read would compare equal on both sides
    # and pass without testing anything, so it is a failure of this script.
    if ($refText -match "no such file or directory") {
        $problems += "the case was not read at all"
    }

    if ($problems.Count -eq 0) {
        Write-Host ("pass  {0}" -f $name)
        continue
    }

    $failed++
    Write-Host ("FAIL  {0}: {1}" -f $name, ($problems -join ", "))
    if ($problems -contains "standard error") {
        Write-Host (First-Difference $refText $portText)
    }
    if ($Show) {
        Write-Host "  ---- reference standard error ----"
        Write-Host $refText
        Write-Host "  ---- port standard error ----"
        Write-Host $portText
    }
}

Write-Host ""
Write-Host ("{0} cases, {1} failed" -f $cases.Count, $failed)
if ($failed -ne 0) {
    Write-Host "the outputs are in tests\out\"
    exit 1
}
