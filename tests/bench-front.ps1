# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# tests/bench-front.ps1: how the two front ends scale with the shape of a file.
#
# The front end's speed depends on the shape of the file it reads, and a single
# number says nothing about where the time goes. This script builds files of one
# shape each - many functions, many statements, many
# expressions, many calls - at growing sizes and times `-R` (the front end alone,
# no back end) with the seed compiler and with the one this tree built, so a shape
# that pays too much shows up as the file grows.
#
# Build the toolchain first (the seed goes into bin\, see README.md):
#   powershell -File build.ps1
# Then run from anywhere:
#   powershell -File tests\bench-front.ps1
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

$dir = Join-Path $PSScriptRoot "out\bench"
New-Item -ItemType Directory -Force -Path $dir | Out-Null

$flags = @('-P', 'bootstrap\frontend', '-system', 'kernel32')

# The shapes: a name, a function of `n` that writes the source, and the sizes.
$shapes = @(
    @{ name = 'tiny'; n = 1; make = { param($n) "int main {`r`n    return 0;`r`n}`r`n" } },
    @{ name = 'funcs'; n = 400; make = {
            param($n)
            $t = ""
            for ($i = 0; $i -lt $n; $i++) { $t += "int f$i {`r`n    return $i;`r`n}`r`n" }
            $t + "int main {`r`n    return f0;`r`n}`r`n"
        } },
    @{ name = 'stmts'; n = 2000; make = {
            param($n)
            $t = "int main {`r`n"
            for ($i = 0; $i -lt $n; $i++) { $t += "    int v$i;`r`n    v$i = $i;`r`n" }
            $t + "    return 0;`r`n}`r`n"
        } },
    @{ name = 'exprs'; n = 2000; make = {
            param($n)
            $t = "int main {`r`n    int a;`r`n    a = 1;`r`n"
            for ($i = 0; $i -lt $n; $i++) { $t += "    a = a + $i * 2 - 3;`r`n" }
            $t + "    return a;`r`n}`r`n"
        } },
    @{ name = 'calls'; n = 2000; make = {
            param($n)
            $t = "int pick -> int a, int b {`r`n    return a;`r`n}`r`nint main {`r`n    int a;`r`n    a = 0;`r`n"
            for ($i = 0; $i -lt $n; $i++) { $t += "    a = pick(a, $i);`r`n" }
            $t + "    return a;`r`n}`r`n"
        } },
    @{ name = 'strings'; n = 2000; make = {
            param($n)
            $t = "int main {`r`n"
            for ($i = 0; $i -lt $n; $i++) { $t += "    system.std_out(`"line $i`");`r`n" }
            $t + "    return 0;`r`n}`r`n"
        } }
)

function Time-Run {
    param([string]$Exe, [string[]]$Arguments)
    $argline = ($Arguments | ForEach-Object { "`"$_`"" }) -join ' '
    # Every case is run five times and the middle run is the answer: a single run of
    # this machine varies by about a fifth either way, which is more than the
    # differences a change to the front end makes.
    $times = @()
    for ($i = 0; $i -lt 5; $i++) {
        $sw = [Diagnostics.Stopwatch]::StartNew()
        cmd /c "`"$Exe`" $argline 1> nul 2> nul"
        $sw.Stop()
        if ($LASTEXITCODE -ne 0) { return -1 }
        $times += $sw.Elapsed.TotalSeconds
    }
    $sorted = $times | Sort-Object
    return $sorted[2]
}

Write-Host ("{0,-10} {1,10} {2,10} {3,10} {4,8}" -f "shape", "bytes", "ref", "port", "ratio")
foreach ($s in $shapes) {
    foreach ($mult in @(1, 2)) {
        $n = $s.n * $mult
        $src = Join-Path $dir "$($s.name)_$n.b"
        [IO.File]::WriteAllText($src, (& $s.make $n))
        $bytes = (Get-Item $src).Length
        $outRef = Join-Path $dir "$($s.name)_$n.ref.r"
        $outPort = Join-Path $dir "$($s.name)_$n.port.r"
        $tr = Time-Run $reference (@('-R', '-o', $outRef, $src) + $flags)
        $tp = Time-Run $port (@('-R', '-o', $outPort, $src) + $flags)
        $same = if ((Test-Path $outRef) -and (Test-Path $outPort)) {
            [Linq.Enumerable]::SequenceEqual([byte[]][IO.File]::ReadAllBytes($outRef),
                                             [byte[]][IO.File]::ReadAllBytes($outPort))
        } else { $false }
        $ratio = if ($tr -gt 0) { $tp / $tr } else { 0 }
        $tag = "$($s.name)_$n"
        Write-Host ("{0,-10} {1,10} {2,10:N2} {3,10:N2} {4,8:N1} {5}" -f `
            $tag, $bytes, $tr, $tp, $ratio, $(if ($same) { "" } else { " .r DIFFERS" }))
    }
}
