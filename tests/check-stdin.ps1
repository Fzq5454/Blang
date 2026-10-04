# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# tests/check-stdin.ps1: the standard-input interface of the two compilers.
#
# A program can be piped straight into the compiler instead of being written to a
# file first:
#
#     type x.b | blang.exe -stdin b - -o x.exe      (a blang program)
#     type x.r | blang.exe -stdin r - -o x.exe      (intermediate code)
#
# `-stdin` may stand anywhere on the command line, `b` and `r` say which language
# the text is in (`b` by default), and `-` is where the input file would be. Every
# message the compiler prints names the input `<stdin>`.
#
# `-m` is checked here too, because a piped input has no name and its .bmeta is then
# `meta\a.bmeta`. The two compilers stand in different directories (`bin` and
# `bootstrap\bin`) and the .bmeta of a run goes to the meta\ of the tree the compiler
# is built in, so the two sides of such a case write two different paths: that is what
# the `outport` of a case names.
#
# This script pipes the same text into the seed compiler (bin\blang.exe) and the
# one this tree has just built (bootstrap\bin\blang.exe) and holds the two answers
# against each other: the exit code, the standard output and error (line endings and the
# random name of a temporary .r taken out) and the file the run wrote.
#
# Build the toolchain first (the seed goes into bin\, see README.md):
#   powershell -File build.ps1
# Then run from anywhere:
#   powershell -File tests\check-stdin.ps1
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
$inFile = Join-Path $outDir "stdin_program.txt"

# What is piped in: a program that compiles, and one that does not.
$good = "int main {`r`n    return 0;`r`n}`r`n"
$bad = "int main {`r`n    undefined_call();`r`n    return 0;`r`n}`r`n"

# tag, what is piped in, the arguments, the file the run writes (empty: none),
# and how the text reaches the compiler ('file' = `< in`, 'pipe' = `type | in`).
$cases = @(
    @{ tag = 'err_r_file';     text = $bad;  cli = '-stdin b - -R -o _t.r';      out = '_t.r';   how = 'file' },
    @{ tag = 'ok_r_file';      text = $good; cli = '-stdin b - -R -o _t.r';      out = '_t.r';   how = 'file' },
    @{ tag = 'ok_compile';     text = $good; cli = '-stdin b - -o _t.exe';       out = '_t.exe'; how = 'file' },
    @{ tag = 'ok_compile_pipe';text = $good; cli = '-stdin b - -o _t.exe';       out = '_t.exe'; how = 'pipe' },
    @{ tag = 'ok_i';           text = $good; cli = '-stdin b - -I -o _t.i';      out = '_t.i';   how = 'file' },
    @{ tag = 'err_pipe';       text = $bad;  cli = '-stdin b - -R -o _t.r';      out = '_t.r';   how = 'pipe' },
    @{ tag = 'option_first';   text = $bad;  cli = '-o _t.r -stdin b - -R';      out = '_t.r';   how = 'file' },
    @{ tag = 'language_last';  text = $bad;  cli = '-stdin -R -o _t.r b -';      out = '_t.r';   how = 'file' },
    @{ tag = 'without_dash';   text = $good; cli = '-stdin b -R -o _t.r';        out = '_t.r';   how = 'file' },
    @{ tag = 'chinese';        text = $bad;  cli = '-stdin b - -R -o _t.r -Chinese'; out = '_t.r'; how = 'file' },
    @{ tag = 'r_of_source';    text = $bad;  cli = '-stdin r - -R -o _t.r';      out = '_t.r';   how = 'file' },
    @{ tag = 'r_of_code';      text = $good; cli = '-o _t.exe -stdin r -';       out = '_t.exe'; how = 'pipe' },
    @{ tag = 'ok_m_pipe';      text = $good; cli = '-stdin b - -m';              out = 'meta\a.bmeta'; outport = 'bootstrap\meta\a.bmeta'; how = 'pipe' },
    @{ tag = 'ok_m_file';      text = $good; cli = '-stdin b - -m';              out = 'meta\a.bmeta'; outport = 'bootstrap\meta\a.bmeta'; how = 'file' },
    @{ tag = 'err_m_missing';  text = $good; cli = '-m _nope.b';                 out = '';       how = 'file' }
)

function Read-Text {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return "<none>" }
    $t = [IO.File]::ReadAllText($Path, [Text.Encoding]::UTF8) -replace "`r`n", "`n"
    return ($t -replace '\\Temp\\[A-Za-z0-9]+\.r', '\Temp\NAME.r')
}

function Same-File {
    param([string]$A, [string]$B)
    # A run that failed writes nothing, and its copy is the empty string: no file
    # on both sides is the same answer.
    $ea = ($A -ne "") -and (Test-Path -LiteralPath $A)
    $eb = ($B -ne "") -and (Test-Path -LiteralPath $B)
    if (-not $ea -and -not $eb) { return $true }
    if (-not $ea -or -not $eb) { return $false }
    return [Linq.Enumerable]::SequenceEqual([byte[]][IO.File]::ReadAllBytes($A),
                                            [byte[]][IO.File]::ReadAllBytes($B))
}

$failed = 0
foreach ($c in $cases) {
    [IO.File]::WriteAllText($inFile, $c.text)
    $results = @{}
    foreach ($side in @("ref", "port")) {
        $exe = if ($side -eq "ref") { $reference } else { $port }
        $o = Join-Path $outDir "$($c.tag).$side.out"
        $e = Join-Path $outDir "$($c.tag).$side.err"
        $run = if ($c.how -eq "pipe") { "type `"$inFile`" | $exe $($c.cli)" }
               else { "$exe $($c.cli) < `"$inFile`"" }
        # The file the side writes, which the port keeps under its own meta\ when a
        # case names an `outport`, and which is removed before the run so that a run
        # that writes nothing is told apart from one that wrote its file long ago.
        $outArg = if ($side -eq "port" -and $c.ContainsKey("outport")) { $c.outport } else { $c.out }
        if ($outArg -ne "") {
            Remove-Item -LiteralPath $outArg -Force -ErrorAction SilentlyContinue
        }
        cmd /c "$run 1> `"$o`" 2> `"$e`""
        $copy = ""
        if ($outArg -ne "" -and (Test-Path -LiteralPath $outArg)) {
            $copy = Join-Path $outDir "$($c.tag).$side.written$([IO.Path]::GetExtension($outArg))"
            Copy-Item -LiteralPath $outArg -Destination $copy -Force
            Remove-Item -LiteralPath $outArg -Force -ErrorAction SilentlyContinue
        }
        $results[$side] = @{ rc = $LASTEXITCODE; out = $o; err = $e; written = $copy }
    }
    $r = $results["ref"]; $p = $results["port"]
    $problems = @()
    if ($r.rc -ne $p.rc) { $problems += "exit code $($r.rc) against $($p.rc)" }
    if ((Read-Text $r.out) -ne (Read-Text $p.out)) { $problems += "standard output" }
    if ((Read-Text $r.err) -ne (Read-Text $p.err)) { $problems += "standard error" }
    if (-not (Same-File $r.written $p.written)) { $problems += "the file the run wrote" }
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
