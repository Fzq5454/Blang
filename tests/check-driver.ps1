# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# tests/check-driver.ps1: the command line of the two compilers.
#
# The driver walks the input files it is given, one at a time, and the -o options
# answer for them by position: the first -o is the output of the first input, the
# second of the second, and an input no -o answered for keeps the name its mode
# gives it (a.exe, a.i or a.r). A .r input and a compiled one are both compiled and
# the walk goes on, while the three text modes (-I, -m and -R) write their one file
# and end the run.
#
# This script runs the seed compiler (bin\blang.exe, the one a release shipped) and
# the one this tree has just built (bootstrap\bin\blang.exe) over the same command
# lines and holds the two answers against each other: the exit code, the standard
# output and error (line endings taken out, so the CRLF of one and the LF of the
# other compare equal) and every
# file the run may write, byte for byte. A file that neither side wrote counts as
# the same answer, so a mode that has to stop after the first input is seen.
#
# Build the toolchain first (the seed goes into bin\, see README.md):
#   powershell -File build.ps1
# Then run from anywhere:
#   powershell -File tests\check-driver.ps1
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

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

$outDir = Join-Path $PSScriptRoot "out"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# The sources the cases compile, and one .r file built from the first of them: a .r
# input is handed straight to cmp.exe, which is the second half of the walk.
$srcA = Join-Path $outDir "mul_a.b"
$srcB = Join-Path $outDir "mul_b.b"
$srcO = Join-Path $outDir "reload_ovl.b"
$srcR = Join-Path $outDir "mul_a.r"
[IO.File]::WriteAllText($srcA, "int main {`r`n    return 0;`r`n}`r`n")
[IO.File]::WriteAllText($srcB, "int main {`r`n    return 1;`r`n}`r`n")
# A name with two `reload` versions: the call has to be rewritten to the version
# its argument types match, which is the one thing the two front ends resolve
# through an out parameter.
$overloadSrc = @'
int pick -> int a {
    return 1;
}

reload int pick -> str s {
    return 2;
}

int main {
    str t = "hi";
    return pick(1) + pick(t);
}
'@
[IO.File]::WriteAllText($srcO, (($overloadSrc -replace "`r`n", "`n") -replace "`n", "`r`n"))
& $reference -R -o $srcR $srcA
if ($LASTEXITCODE -ne 0) {
    Write-Error "the .r fixture could not be built with $reference"
}

# tag, the arguments, and the files the run may write (a file both sides leave
# alone is the same answer as one both sides write, so a case names the files a
# run would write if it did not stop where it should).
$cases = @(
    @{ tag = 'one_input_o_before'; args = @('-o', '_d1.exe', $srcA);                          files = @('_d1.exe') },
    @{ tag = 'one_input_o_after';  args = @($srcA, '-o', '_d2.exe');                          files = @('_d2.exe') },
    @{ tag = 'two_inputs_one_o';   args = @($srcA, $srcB, '-o', '_d3.exe');                   files = @('_d3.exe', 'a.exe') },
    @{ tag = 'two_inputs_default'; args = @($srcA, $srcB);                                    files = @('a.exe') },
    @{ tag = 'o_between_inputs';   args = @($srcA, '-o', '_d5a.exe', $srcB, '-o', '_d5b.exe'); files = @('_d5a.exe', '_d5b.exe') },
    @{ tag = 'two_o_one_input';    args = @('-o', '_d6a.exe', '-o', '_d6b.exe', $srcA);        files = @('_d6a.exe', '_d6b.exe') },
    @{ tag = 'missing_second';     args = @('-o', '_d7.exe', $srcA, (Join-Path $outDir 'no.b')); files = @('_d7.exe') },
    @{ tag = 'r_stops_after_one';  args = @('-R', '-o', '_d8.r', $srcA, $srcB);                files = @('_d8.r', 'a.r') },
    @{ tag = 'i_stops_after_one';  args = @('-I', '-o', '_d9.i', $srcA, $srcB);                files = @('_d9.i', 'a.i') },
    @{ tag = 'r_then_b';           args = @('-o', '_d10a.exe', '-o', '_d10b.exe', $srcA, $srcR); files = @('_d10a.exe', '_d10b.exe') },
    @{ tag = 'reload_overload';    args = @($srcO, '-o', '_d11.exe');                         files = @('_d11.exe') },
    @{ tag = 'r_and_i';            args = @('-R', '-I', $srcA);                               files = @('a.r', 'a.i') },
    @{ tag = 'o_last';             args = @('-o');                                            files = @() },
    @{ tag = 'link_last';          args = @('-link');                                         files = @() },
    @{ tag = 'system_last';        args = @('-system');                                       files = @() },
    @{ tag = 'D_last';             args = @('-D');                                            files = @() },
    @{ tag = 'U_last';             args = @('-U');                                            files = @() },
    @{ tag = 'P_last';             args = @('-P');                                            files = @() },
    @{ tag = 'l_last';             args = @('-l');                                            files = @() },
    @{ tag = 'unknown_option';     args = @('-Q');                                            files = @() },
    @{ tag = 'bad_extension';      args = @('nope.txt');                                      files = @() },
    @{ tag = 'no_arguments';       args = @();                                                files = @() }
)

function Read-Text {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return "<none>" }
    $t = [IO.File]::ReadAllText($Path, [Text.Encoding]::UTF8) -replace "`r`n", "`n"
    return ($t -replace '\\Temp\\[A-Za-z0-9]+\.r', '\Temp\NAME.r')
}

function Same-File {
    param([string]$A, [string]$B)
    $ea = ($A -ne "") -and (Test-Path -LiteralPath $A)
    $eb = ($B -ne "") -and (Test-Path -LiteralPath $B)
    if (-not $ea -and -not $eb) { return $true }
    if (-not $ea -or -not $eb) { return $false }
    return [Linq.Enumerable]::SequenceEqual([byte[]][IO.File]::ReadAllBytes($A),
                                            [byte[]][IO.File]::ReadAllBytes($B))
}

$failed = 0
foreach ($c in $cases) {
    $results = @{}
    foreach ($side in @("ref", "port")) {
        $exe = if ($side -eq "ref") { $reference } else { $port }
        $o = Join-Path $outDir "$($c.tag).$side.out"
        $e = Join-Path $outDir "$($c.tag).$side.err"
        # No case names the same file twice, so one path per side is enough: the two
        # compilers stand in different directories but write where the case says.
        $copies = @{}
        foreach ($f in $c.files) {
            Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue
        }
        $argline = ($c.args | ForEach-Object { "`"$_`"" }) -join ' '
        cmd /c "`"$exe`" $argline 1> `"$o`" 2> `"$e`""
        $rc = $LASTEXITCODE
        $i = 0
        foreach ($f in $c.files) {
            $copy = ""
            if (Test-Path -LiteralPath $f) {
                $copy = Join-Path $outDir "_t_$($c.tag).$i.$side$([IO.Path]::GetExtension($f))"
                Copy-Item -LiteralPath $f -Destination $copy -Force
                Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue
            }
            $copies[$i] = $copy
            $i = $i + 1
        }
        $results[$side] = @{ rc = $rc; out = $o; err = $e; copies = $copies }
    }
    $r = $results["ref"]; $p = $results["port"]
    $problems = @()
    if ($r.rc -ne $p.rc) { $problems += "exit code $($r.rc) against $($p.rc)" }
    if ((Read-Text $r.out) -ne (Read-Text $p.out)) { $problems += "standard output" }
    if ((Read-Text $r.err) -ne (Read-Text $p.err)) { $problems += "standard error" }
    for ($i = 0; $i -lt $c.files.Count; $i++) {
        if (-not (Same-File $r.copies[$i] $p.copies[$i])) { $problems += "the file $($c.files[$i])" }
    }
    if ($problems.Count -eq 0) {
        Write-Host ("pass  {0}" -f $c.tag)
    } else {
        $failed++
        Write-Host ("FAIL  {0}: {1}" -f $c.tag, ($problems -join ", "))
        Write-Host ("      reference: {0}" -f ((Read-Text $r.err) -split "`n" | Select-Object -First 1))
        Write-Host ("      port:      {0}" -f ((Read-Text $p.err) -split "`n" | Select-Object -First 1))
    }
}

Write-Host ""
Write-Host ("{0} cases, {1} failed" -f $cases.Count, $failed)
if ($failed -ne 0) {
    Write-Host "the outputs are in tests\out\"
    exit 1
}
