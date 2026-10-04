# source_code: a reading copy of the compiler's sources

Every `.b` file the compiler is built from, in one place and in the order it is
worth reading, split by stage:

    source_code/
      self/                  the self-hosted toolchain: blang written in blang
        frontend/            blang.b, gn.b and the front-end modules (.b)
        backend/             cmp.b and the .r backend modules (.b)
        include/bl/          the `#head` standard headers the front end inlines
        build.ps1            the self-hosted build

167 files in all. Every one of them is a byte-for-byte copy of its file elsewhere
in the repository; nothing was edited while copying, and no build output is
included.

## The three programs, and what builds each one

    program     sources
    blang.exe   frontend/blang.b + frontend/*
    gn.exe      frontend/gn.b + frontend/*
    cmp.exe     backend/cmp.b + backend/*

The front end is one set of modules and each program includes the ones it needs
through `#head`; `bootstrap\build.ps1` is what builds all three, and the root
`build.ps1` is what builds the toolchain around them.

## How to read it

Start with `frontend/blang.b`: it is the driver, and it shows the shape of a
compile - the options, `-R` / `-I` / `-m`, the list of imported signatures, and the
hand-over to the scheduler. `frontend/gn.b` runs the front end and gives the `.r`
text to the backend; `backend/cmp.b` reads that text and writes the image.

From there:

* the front end proper is `frontend/lexer.b`, the `frontend/parser*.b` modules, and
  the `frontend/rgen*.b` modules that generate the `.r` text;
* the declarations a compiler keeps in headers are modules of their own here
  (`*_heads.b`, `frontend/ast.b`, `frontend/struct_def.b`);
* the diagnostics are `frontend/parser_error.b` and
  `frontend/Chinese/chinese.b` (the message table, the matcher, and `-Chinese`);
* the backend is `backend/tokenizer.b` for the `.r` text, the `backend/parser*.b`
  modules for its grammar, the `backend/codegen*.b` modules for the x64 code, and
  `backend/emitter.b` and `backend/pe_writer.b` for the machine code and the PE
  file both written by hand;
* the runtime the compiled programs call is `runtime/*.b` at the root of the
  repository, and `native/*.dll.b` holds the signature of every system DLL.

## Building

These copies are for reading; `build.ps1` in the root of the repository builds from
the real files, not from here:

    powershell -File build.ps1
