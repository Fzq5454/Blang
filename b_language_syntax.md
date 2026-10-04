# The b Language — Syntax Reference

The syntax of the **b** language: source text, declarations, statements and
expressions, as a language. It says nothing about the compiler, its flags, its
intermediate `.r` text or its metadata files — those are toolchain matters.

A program is one file plus the files it pulls in with `#head` / `#import`. Execution
starts at `int main { ... }`, and the value `main` returns is the process exit code.

---

## 1. Source text and comments

* A source file is UTF-8 text; statements are laid out over lines.
* A **block comment** is `!~ ... ~!` and may span lines.
* A **line comment** is `!!!` and runs to the end of the line.
* Comments are removed by the preprocessing: they never reach the grammar, and the
  line they were written on is kept.

```blang
!~ A block comment
   over two lines. ~!
!!! A line comment.
```

---

## 2. Lexical elements

**Identifiers**: a letter or `_`, then letters, digits or `_`.

**Keywords** (reserved):

```
int str float bool char longlong        true false null any void func
kind                                     if else elif while do switch case unmatch
skip continue return end back            try exception throw
local stub reload operator               ref const static utype
package use rcode etc                    introduce TYPENAME TEMPLATE ARGS
attribute rule                           BLANG_API __badd __bcall __bfree
                                         __get_built_in_func
```

Anything else — `public`, `private`, `protected`, `self`, `super`, `main`, the names
of the standard headers — is an ordinary identifier that means something in the one
place the grammar gives it a meaning.

**Integer literals**: decimal (`42`) and hexadecimal (`0x2A`); a leading `-` is the
operator, not part of the literal. A constant that does not fit in 32 bits is a
64-bit one.

**Float literals**: `1.5`, `0.25`, `3.0`.

**Character literals**: `'a'`, `'\n'`, `'\\'`, `'\''`.

**String literals**: `"text"`, `"line\n"`, `"\""`. The escapes are `\n`, `\t`, `\r`,
`\\`, `\"`, `\'`, `\0`, a hexadecimal byte as `\xHH`, and an octal byte as one to
three octal digits (`\033` is the escape character, `\101` is `A`). A string is a
block of bytes, `str`, so any byte may be written.

**Boolean and null literals**: `true`, `false`, `null`.

**Operators and punctuation**

```
+  -  *  /  %                 arithmetic
++ --                         increment, decrement (prefix and postfix)
== != < <= > >=               comparison
&& || !                       logical
& | ^ ~ << >>                 bitwise
=                             assignment (an expression, see §11)
? :                           conditional
.                             member access
::                            package member, and the owner in `Type::method`
( )                           grouping, calls, casts, lambda parameter list
[ ]                           indexing, and a lambda parameter list
{ }                           blocks, type bodies, initialiser lists
@ $                           "pointer to", "the object this pointer names"
->                            the parameter list of a declaration
=>                            the immediate call of a lambda
...                           a template pack
; ,                           statement end, separator
```

There are **no compound assignments**: `+=`, `-=`, `<<=` and the like are not part of
the language (`a = a + 1` is how that is written). They are still *tokenised*, so the
compiler can point at the operator and go on checking the rest of the file.

**Precedence**, loosest first:

| Level | Operators |
| --- | --- |
| 1 | `\|\|` |
| 2 | `&&` |
| 3 | `\|` |
| 4 | `^` |
| 5 | `&` |
| 6 | `==` `!=` `<` `>` `<=` `>=` |
| 7 | `+` `-` |
| 8 | `<<` `>>` |
| 9 | `*` `/` `%` |
| 10 | unary `!` `~` |

All six comparisons share one level, and `+`/`-` bind tighter than the shifts. `? :`
and `=` sit below the levels above.

**Member and method names may not be keywords**: a field called `size`, a method
called `count`, a type member named `back` are all rejected, because those words are
operators.

---

## 3. Preprocessor directives

A directive stands at the beginning of a line (`#to` may also stand, indented, inside
a body). A directive is consumed by the preprocessing: it leaves its line empty in the
preprocessed text and nothing in the program.

| Directive | Meaning |
| --- | --- |
| `#head "name"` | pull in a standard header: `stdsrt`, `long`, `vector`, `fileio`, `bprintf`, `bmath`, `bwin`, `bstr`, ... |
| `#import [*a, *b]` | take the named blocks other files published | 
| `#export *name` ... `#export *name` | publish the lines between the two directives under `name`; `#export name` on a line of its own publishes that one line |
| `#once` | the file is read the first time only |
| `#if <expr>` / `#ifdef NAME` / `#ifndef NAME` / `#elif` / `#else` / `#endif` | conditional compilation |
| `#replace FROM TO` | a textual macro: every whole `FROM` becomes `TO` |
| `#require <version>` | the compiler version this source needs: `1.0`, `1.0.0` or the packed number (`10000`); an older compiler reports an error |
| `#newline` and `"#newline"` | a line break where one cannot be written (a line of its own, or inside a line); `##newline` is the escape for the word itself |
| `#error "msg"` | report an error |
| `#warning "msg"` | report a warning and continue |
| `#to <flags>` | flags handed to the step that turns the program into an executable, for example `#to type=dll` |

`#if` takes an integer expression over the operators of §2, `defined(NAME)`,
`built_in(NAME)` — compiler and target facts such as `ARCH_X64`, `PTR_SIZE`,
`OS_WINDOWS`, `OUT_DLL`, `COMPILER_VERSION` — and `linked(name)`.

`#require` asks for a compiler at least as new as the version it names, so a source
that uses a feature of a later version says so and is not read by an older one. It
stands inside the conditional family: a `#require` in a branch that was not taken is
never looked at.

```blang
#head "stdsrt"
#if built_in(PTR_SIZE) == 8
#head "long"
#endif
#replace MAXN 64
#replace TRACE system.out("trace\n")
#to type=dll
```

`#replace` has no parameters: it is a whole-word textual substitution over the file.
A source that wants a line of its own written by a macro uses `"#newline"`.

---

## 4. Types

**Builtin types**

| Type | Meaning |
| --- | --- |
| `int` | 32-bit signed |
| `longlong` | 64-bit signed |
| `float` | floating point |
| `char` | one byte |
| `bool` | a truth value |
| `str` | a block of bytes |
| `void` | no value |
| `any` | a value whose type is only known at run time |
| `func` | a function value, a closure (§6, §11) |

**Pointers**: `@T` is a pointer to `T` — `@int`, `@char`, `@void`, `@Point`. `@char`
over a block of bytes is what a string is made of.

**Arrays**: `int a[4];` declares four `int`s; the length is written once, at the
declaration, and `count a` (§11) reads it back. An array used as a value is the
address of its first element, and an array parameter is passed that way.

**Struct types**: declared with `type` (§7).

**Enumerations**: `kind` declares named integer constants:

```blang
kind Color {
    RED,
    GREEN = 5,
    BLUE
};                       !~ the ';' is accepted and may be left out ~!
```

The members are used by their **bare name** (`RED`, `BLUE`), and the type name `Color`
may be used wherever a type may stand.

**`utype`**: `utype int`, `utype longlong`, `utype char` are the unsigned readings of
those widths.

---

## 5. Variables

```blang
int a = 5;
int b;                                 !~ uninitialised: it holds the slot's old bits ~!
@int p = null;
@char data = "hello";                  !~ the bytes of the string ~!
int grid[4] = { 1, 2, 3, 4 };          !~ an initialiser list ~!
Point origin;                          !~ the object itself; its constructor runs ~!
@Point r = malloc(null, size Point);   !~ storage without a lifetime ~!
any v = a;                             !~ a value of any type ~!
```

Qualifiers stand in front of the type:

| Qualifier | Meaning |
| --- | --- |
| `ref T x` | a second name for the same storage (a parameter, or a local binding) |
| `const T x` | written once, where it is declared, and never again |
| `static T x` | the storage exists for the whole program; inside a function it keeps its value between calls and its initialiser runs once |
| `utype int x` | the value is read and printed as unsigned |
| `local` | the declaration is private to its file (functions, §6) |

---

## 6. Functions

A function writes its return type, its name, then `->` and its parameters, each as
`type name`, then its body. **There are no parentheses around the parameter list.**

```blang
void hello {
    system.out("hello\n");
}

int add -> int a, int b {
    return a + b;
}

void set -> ref int target, int value {
    target = value;
}

int sum -> int values[4] {          !~ an array parameter arrives as an address ~!
    int t = 0;
    int i = 0;
    while i < count values {
        t = t + values[i];
        i = i + 1;
    }
    return t;
}

int with_default -> int a, int b = 10 {   !~ trailing parameters may have defaults ~!
    return a + b;
}
```

* `void` for "no value"; inside such a function `end;` returns early, and
  `return <expr>;` hands a value back from a function that has one.
* A parameter is visible only inside its own body, and two functions may reuse a name.
* An `any` parameter takes a value of any type.

**`stub`** declares a name and its signature with no body; the body is written
elsewhere — another module, or a linked library:

```blang
stub int foreign -> int x;
```

**`reload`** declares one more version of an existing prototype, so a name may have
several versions picked by argument types; it also does this for a method inside a
type (§7).

**`local`** keeps a function (or a type) to the file it is written in.

**Function values and lambdas.** `func` is a value that holds a function or a
closure. A lambda is written `[parameters] { body }`, its parameters are `type name`
pairs separated by commas, and `back <expr>;` is how a lambda hands a value back
(§10):

```blang
func twice = [int x] { back x * 2; };
int y = twice(21);

int z = [int x] { back x + 1; } => (41);   !~ written and called at once ~!
```

A lambda captures the variables of the scope it is written in; a variable the lambda
writes to is captured by reference, so the write is seen outside it.

**Templates** are written with `introduce` (§9) and may take packs:
`introduce TYPENAME Y, ARGS A... { int f -> (Y etc) (A etc) { ... } }` builds one
parameter per element of the pack.

---

## 7. Structs

```blang
type Point {
    int x;                     !~ fields ~!
    int y;

    int sum {                  !~ a method, written inside the type ~!
        return x + y;          !~ a bare name is a field of the object ~!
    }

    void move -> int dx, int dy {
        self.x = self.x + dx;  !~ `self` is the object; both spellings are the same ~!
        self.y = self.y + dy;
    }

    stub void reset;           !~ declared here, defined outside ~!

    init Point {               !~ the constructor without parameters ~!
        x = 0;
        y = 0;
    }

    destruct Point {           !~ the destructor ~!
        ...                    !~ runs when a declared object goes out of scope ~!
    }
};

void Point::reset {            !~ the definition of a stub method, outside the type ~!
    self.x = 0;
    self.y = 0;
}

Point origin;                  !~ a global object: its constructor runs at startup ~!
```

* The type declaration ends with `};`; the semicolon is required.
* **Fields** are the object's storage: a scalar, a nested struct, an array or a
  pointer.
* **Methods** are functions whose first, hidden parameter is the object. Inside a
  method a bare field name means a field of that object, and `self` is the object
  itself.
* **`stub` methods** are declared in the type and defined outside it as
  `Type::method`. The definition has to match the declaration — return type, number
  of parameters, and the type of each. A declared method with no definition is an
  unresolved name, reported where it is called.
* **Access**: `public`, `private` and `protected` may stand before a member, or
  before a `{ ... }` block whose members take that level. Outside the type only the
  public members may be used. Sections do not nest: a section's `}` returns to
  public. A member written before any of the three is public.
* **`init T { ... }`** is the constructor without parameters; it runs on every
  declared object of the type before it is first used. **`init T -> params { ... }`**
  is a *converting* constructor: a value of the parameter's type may be written where
  the struct is expected, as if the constructor had been called.
* **`destruct T { ... }`** runs when a declared object goes out of scope. Storage that
  came from `malloc` has no lifetime, so it has no destructor.
* **Operator overloading**: the method's name is `operator` and the symbol follows,
  with the return type written in front like any other method. `int operator ==;`
  compares every field. `int operator [] -> int i { ... }` and
  `operator []= -> int i, int v { ... }` give a type a subscript, and
  `str operator str;` (or `int`, `float`, `bool`, `char`) gives it a conversion.
  `==` and `!=` return `int` or `bool`.
* **`reload` on a method** declares one more version of a method or operator that the
  type already has.
* **Inheritance**: `type Derived : Base { ... }` puts the base at offset 0; several
  bases may be listed, separated by commas. `super.method(...)` reaches a method of
  the base, and `is super` asks for the base's version in the same call.

```blang
type Shape {
    int x;
    int area { return 0; }
};

type Box : Shape {
    int w;
    int h;
    int area { return w * h; }
};
```

---

## 8. Packages

A package groups names under a prefix, and its members are reached with `::`:

```blang
package math {
    int abs -> int v {
        if v < 0 { return -v; }
        return v;
    }
}

int main {
    return math::abs(-3);
}
```

**`use`** brings a package's names — or one of them — into the file, so they may be
written without the prefix:

```blang
use math;          !~ every member of math ~!
use math::abs;     !~ just abs ~!
```

---

## 9. Generics

`introduce` opens a template. The parameter list holds:

| Written | Meaning |
| --- | --- |
| `TYPENAME T` | a type parameter |
| `int N` (also `bool`, `char`, `float`, `str`) | a value parameter, an ordinary constant of the body |
| `TEMPLATE C` | a template parameter |
| `T...`, `C...`, `int N...` | a pack: the parameter takes a list instead of one |
| `ARGS A...` | the argument pack a template function's parameter list is built from |

```blang
introduce TYPENAME T {
    type Box {
        T value;

        T get { return value; }
        void set -> T v { value = v; }
    }
}

introduce TYPENAME T, int N {
    int capacity -> T items[N] { return count items; }
}

introduce TYPENAME Y { ... -> (Y etc) (A etc) { ... } }   !~ one parameter per argument ~!
```

An instance is written by giving the arguments in parentheses after the name:
`Box(int) b;` is a `Box` whose `T` is `int`, and a template function is called the
same way. A value argument must be a constant.

---

## 10. Statements

```blang
if a < b {
    ...
} elif a == b {
    ...
} else {
    ...
}

while i < n {
    i = i + 1;
}

do {
    i = i + 1;
} while i < n

switch x {
    case 1:
        ...
    case 2:
        ...
    unmatch:
        ...
}

skip;              !~ leave the innermost loop ~!
continue;          !~ next turn of the innermost loop ~!
return v;          !~ hand a value back from the function ~!
end;               !~ early return from a void function ~!
back v;            !~ hand a value back from a lambda ~!

throw code;        !~ raise an exception ~!

try {
    ...
} exception (e) {
    system.out("code ", (str)e, "\n");
}

rcode "TEXT"       !~ raw intermediate text, written where the statement stands ~!
```

* The body of an `if`, `elif`, `else`, `while`, `do` and `try` is a `{ ... }` block.
  `while` and `if` take their condition with no parentheses.
* `do { ... } while <cond>` runs the body first and asks afterwards; the `;` after
  it is optional.
* `switch <expr> { ... }` holds `case <expr>` arms and at most one `unmatch` arm; the
  `:` after a `case` (or after `unmatch`) is optional. An arm runs from its label to
  the next label, and `unmatch` runs when no case matched.
* `skip;` is only valid inside a loop and `continue;` too: `skip` leaves the loop,
  `continue` starts the next turn. Both need their `;`.
* `return <expr>;` returns from a function, `end;` returns from a void function, and
  `back <expr>;` returns from a lambda.
* `throw <code>;` raises the code — an `int`-like value the runtime compares, such as
  a constant of a `kind` — and everything after it in the `try` body is abandoned.
* `try { ... } exception (e) { ... }` catches it: `e` is an `int` holding the code,
  and the parameter list is optional (`exception ()`, or a bare `exception { ... }`
  when the code is not needed). A `try` has exactly one handler.
* `use pkg;`, `use pkg::name;`, `attribute ...`, `rule ...` and every declaration are
  statements as well, so they may stand where a statement may.
* A declaration inside a block, a loop body or a handler belongs to that block only.

---

## 11. Expressions

```blang
a + b * c                !~ * and / bind tighter than + and - ~!
a < b && c != d          !~ && and || are the loosest ~!
!ok
p1.x + p2.y              !~ member access ~!
arr[i]                   !~ indexing ~!
m[i][j]                  !~ a subscript of a subscript ~!
f(1, 2)                  !~ a call ~!
f(a = 1, b = 2)          !~ named arguments, in any order ~!
$p                       !~ the object the pointer p names ~!
@v                       !~ the address of v ~!
(int)x                   !~ a cast ~!
(@Point)p                !~ a cast that says what a pointer points at ~!
size Point               !~ the number of bytes one Point occupies ~!
size data                !~ the byte size of what data is ~!
count arr                !~ the number of elements of arr ~!
a > b ? a : b            !~ the conditional operator ~!
i = j = 0                !~ assignment is an expression and chains ~!
(a = 1) = 2              !~ the result of an assignment is the object it wrote ~!
```

`size` and `count` are written without parentheses and take a name.

Pointer arithmetic (`p + 1`, `p[i]`) steps by the size of the object the pointer
points at. `+` on two strings joins them. Comparing a pointer with `null` is how a
failed allocation is recognised.

**Conversions.** An `int`, `longlong`, `float`, `char` or `bool` value becomes a
struct with a converting constructor (`init T -> <type> { ... }`, §7) where the struct
is what the position expects. A pointer becomes another pointer type with `(@T)p`, and
`(@void)p` makes it a plain pointer. Casting a scalar to `str` uses the type's own
conversion when it has one.

**Function values.** A lambda or a function name may be stored in a `func` and called
through it; `f(...)` on a `func` value calls what the value holds.

**`self`.** Inside a method `self` is the object the method was called on, the same
object a bare field name refers to.

---

## 12. `attribute` and `rule`

These two statements tell the compiler something about the program, or ask it to check
something. They emit nothing, they may stand anywhere a statement may, and what they
name has to be declared **above** them.

**`attribute <object>: <NAME>[, <NAME>]...`** — the object is a plain name, a struct
member (`S.f`, `S.m`) or a package member (`pkg::f`). The `;` is optional. The
built-in names are:

| Name | Meaning |
| --- | --- |
| `USED` | the name counts as used, which silences the unused-name warning |
| `READ` | the value counts as read as well |
| `INIT` | the object counts as initialised |
| `EXTERN` | the body of this function is not checked here |
| `NORETURN` | the function never returns normally |
| `NOWARN`, `SILENT` | the warnings of that function's body are not reported |
| `INT`, `LONG`, `LONGLONG`, `FLOAT`, `STR`, `CHAR`, `BOOL`, `VOID`, `FUNC`, and the `UTYPE_*` spellings | what the type of a declaration is, when the declaration does not say |

```blang
void helper { ... }
int later_var;

attribute helper: USED
attribute helper: NORETURN, NOWARN
attribute later_var: INT
```

A name the compiler does not know is reported, so a typo is not quietly ignored.

**`rule <NAME>(<arg>, ...)`** runs one of the built-in checks. Its arguments are
expressions: strings, names, and rule calls. Three rules exist:

| Rule | Written as |
| --- | --- |
| `pair` | `pair(not_pair(a, b, ...), "<level>", "<message>", <function>, <function>, ...)` |
| `msg_en_zh` | `msg_en_zh(<rule>, "<english>", "<chinese>")` |
| `warn` | `warn(<rule>)` |

* `pair` counts the calls of the first group of functions against the second group
  over the whole file, in source order and without caring about nesting: `a1 b1 a2 b2`
  and `a1 a2 b1 b2` are both paired, and a call left without a partner is reported at
  its own position, with the given level (`"error"`, `"warning"` or `"note"`) and
  message.
* `not_pair(...)` is what a `pair` statement hands its report through: it names the
  functions the report is about.
* `msg_en_zh` runs the check of the rule it names and reports it with the English
  message, or with the Chinese one when the compiler is asked for Chinese.
* `warn` runs the check of the rule it names as a `-W-userdef` warning: nothing is
  reported until that warning is switched on, and whatever level the inner rule wrote
  becomes a warning.

```blang
rule pair(not_pair(false_alloc, false_free), "error", "alloc and free are not match",
          false_alloc, false_free)

rule msg_en_zh(pair(not_pair(false_alloc, false_free), "error", "alloc and free are not match",
                    false_alloc, false_free),
               "alloc and free are not match", "alloc 和 free 不匹配")

rule warn(pair(not_pair(malloc, unlink), "warning", "malloc and free are not match",
               malloc, unlink))
```

---

## 13. Talking to the runtime

A standard header declares its own functions and types in b, so a call such as
`system.out(...)` or `malloc(null, size Point)` is an ordinary call to a function the
header declared:

| Header | What it gives |
| --- | --- |
| `stdsrt` | `system` (console in, out, err), `malloc` / `unlink`, strings and conversions |
| `long` | the 64-bit helper type and its operators |
| `vector` | the generic vector `NewVector(T)` |
| `fileio` | files |
| `bprintf` | formatted output |
| `bmath` | arithmetic helpers |
| `bwin` | windows |
| `bstr` | strings |

`BLANG_API` declares a function the runtime implements. Its body is not b code but a
binding, made of three calls:

```blang
BLANG_API int system_out -> str s {
    __badd(s);
    __bcall("system.out");
    __bfree();
}
```

`__badd(x)` names a parameter that is passed on, `__bcall("target")` names the runtime
entry point, `__bfree()` ends the argument list. A builtin function is bound to a name
with `__get_built_in_func`, so the name may be called like any other function:

```blang
__get_built_in_func<name> alias;
```

---

## 14. Not part of the language

Compiler flags (`-W-...`, `-I`, `-R`, `-o`, `-P`, `-link`, ...), the intermediate `.r`
text, the `.bmeta` side files, the module search path and the build scripts are
toolchain matters. What a source may say about the build is `#head`, `#import` /
`#export`, `#to` and `attribute`.
