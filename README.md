# blang

A compiler for the **b** language on 64-bit Windows, written in b itself.

blang turns a `.b` source file into a native Windows `.exe` or `.dll` with no
assembler, no linker and no C runtime behind it: the front end parses the source
into an intermediate text (`.r`), and the back end writes the x64 machine code and
the PE file itself. The compiler is self-hosting: the sources in this tree are the
ones that build the compiler, and the build checks that it reproduces itself byte
for byte.

```
.b source  ->  b front end  ->  .r intermediate  ->  x64 code + PE  ->  .exe / .dll
```

* Version: 1.0.0
* Platform: Windows 10/11, x64 only
* License: MIT (see `LICENSE`)

## Building it

There is no C++ in this tree and no binary is committed, so a compiler has to come
from somewhere: it comes from the release assets. Download the **seed** of a release
— `blang.exe`, `gn.exe`, `cmp.exe` and the six `lib*.dll` of the runtime — put the
files into `bin\` (create the directory if it is not there), and run the build:

```
bin\blang.exe                     the seed compiler
bin\gn.exe, bin\cmp.exe           its two other programs
bin\libbrtm.dll, libbprintf.dll, libbfile.dll,
bin\libbmath.dll, libbwin.dll, libbstr.dll        the runtime

powershell -File build.ps1
```

`build.ps1` writes the signatures of the system DLLs into `meta\`, builds the
runtime from `runtime\*.b` into `bin\`, builds the toolchain from `bootstrap\*.b`
into `bootstrap\bin\`, and then checks the fixed point: the compiler it has just
built rebuilds the whole toolchain, and the result has to be byte-identical to what
it produced a moment earlier. That is the test of a self-hosting compiler, and the
build fails if it does not hold.

Requirements: Windows 10/11 x64 and PowerShell 5.1 or later. Nothing else — no C++
toolchain, no assembler, no linker.

## Using it

Write a program — a structure with a field, a constructor, a destructor and a
method — and save it as `hello.b`:

```blang
#head "stdsrt"

type Person {
    str name;

    init Person {
        name = "world";
    }

    destruct Person {
        system.out(name, " is gone\n");
    }

    void greet {
        system.out("hello, ", name, "\n");
    }
};

int main {
    Person p;
    p.greet();
    return 0;
}
```

Compile and run it with the toolchain that was just built:

```
bootstrap\bin\blang.exe -o hello.exe hello.b
hello.exe
```

which prints

```
hello, world
world is gone
```

Without `-o` the output is `a.exe`.

The toolchain is three programs. `blang.exe` is the compiler: it runs the front end
and hands the intermediate code on. `gn.exe` is the driver it calls, and `cmp.exe`
is the back end that writes the image.

```
blang.exe hello.b                 compile and link
blang.exe -R -o hello.r hello.b   stop after the intermediate code
blang.exe -I hello.b              print the preprocessed source
blang.exe -m hello.b              write meta\hello.bmeta (signatures only)
blang.exe hello.r                 a .r input goes straight to the back end
blang.exe -stdin b -              read the program from standard input
blang.exe -o hello.exe hello.b    choose the output name
blang.exe -v, --version           the version of the toolchain
blang.exe --help                  every option

cmp.exe -o hello.exe hello.r      the back end on its own
cmp.exe --type=dll -o mydll.dll mydll.r
cmp.exe -v, --version
cmp.exe --help
```

Linking and placement are chosen with `-link <dll>` (a b DLL), `-system <dll>`
(a system DLL), `-l<name>` (`lib\<name>.lib`), `-d<name>` (`lib<name>.dll`),
`-static-runtime` and `-static`. A source may also name what it needs itself, with
`#head`, `#import` and `#to` — `#to type=dll` builds a DLL instead of an
executable.

Two of the shapes worth trying on your own program: a structure with an
out-of-line method (`stub` plus `void Person::birth { ... }`), and a window
program, which is built with the DLLs it calls
(`-system kernel32 -system user32 -system gdi32`).

## Repository layout

| Path | What it holds |
| --- | --- |
| `bootstrap/` | the compiler in b: `blang.b`, `gn.b`, `cmp.b`, `build.ps1` |
| `bootstrap/frontend/` | the front end as modules: lexer, parser, AST, the `.r` generator, messages, builtins, attributes and rules |
| `bootstrap/backend/` | the `.r` reader and the x64 code generator |
| `bootstrap/includes/bl/` | the standard headers `#head` pulls in while the compiler itself is built |
| `runtime/` | the runtime of compiled programs, written in b (`brtm`, `bprintf`, `bfile`, `bmath`, `bwin`, `bstr`) |
| `includes/bl/` | the same standard headers for the programs you compile (`stdsrt`, `long`, `bmath`, `bstr`, `vector`, `fileio`, `format`, `window`, `thread`, `autotype`, `exception`) |
| `native/` | one signature file per Windows system DLL (`stub` declarations, no code) |
| `lib/` | the import libraries a program links with `-l<name>` (`brtm`, `bprintf`, `bfile`, `bmath`, `bwin`) |
| `ppinc/` | preprocessor include fragments |
| `source_code/self/` | a byte-for-byte reading copy of the compiler's sources; see `source_code/README.md` |
| `tests/` | the PowerShell test suites |
| `vsex/blang/` | the VS Code extension for `.b` files (sources; pack it with `vsce package`) |
| `bin/`, `bootstrap/bin/`, `meta/` | build output, not committed |

## Tests

The suites hold the compiler this tree built against the seed it was built from:
the same command lines and the same sources through both, and the two answers have
to agree.

```
powershell -File tests\check-driver.ps1      the command line and driver behaviour (22 cases)
powershell -File tests\check-stdin.ps1       the standard-input paths (15 cases)
powershell -File tests\check-recovery.ps1    error recovery: every diagnostic and the parse that follows it (35 cases)
powershell -File tests\bench-front.ps1       front-end benchmark
```

All three suites report `0 failed`.

## Documentation

* `b_language_syntax.md` — the syntax of the b language, as a language: comments,
  keywords, literals, operator precedence, the preprocessor directives, types,
  declarations, functions and closures, structs, packages, generics, statements,
  expressions, `attribute` / `rule`, and the runtime interface.
* `source_code/README.md` — how the sources are laid out, and where to start
  reading.

## Contributing

Issues and pull requests are welcome. The rule that matters most here is the one the
build checks: the toolchain has to reproduce itself. Change a module and the fixed
point still has to hold, the test suites still have to pass, and the compiler in
`bootstrap\bin` still has to be able to build the compiler you are looking at. Code
comments are in English; user-facing messages are written in English and translated
in `bootstrap/frontend/Chinese/chinese.b`.

## License

MIT. See `LICENSE`.

Copyright (c) 2026 Fzq5454
