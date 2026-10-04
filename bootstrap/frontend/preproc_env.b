#once
!~
 ~  bootstrap/frontend/preproc_env.b: the frontend/preproc_env.
 ~
 ~  What `#if` may ask about beyond the source text itself. Three things reach a
 ~  condition and none of them is in the file being compiled: the compiler's own
 ~  facts (`built_in(NAME)`), the names the driver defined (`-D`, asked for with
 ~  `defined(NAME)`) and the DLLs it linked (`linked(dll)`). The driver knows all
 ~  three, the preprocessor needs all three, and they travel between the two as one
 ~  string (`preproc_env_encode`), the way the other front-end options do.
 ~
 ~  the toolchain tables are a chain / name table / name table; here a built-in is a
 ~  record in a chain and a name/value table is a chain of a small record walked by
 ~  name. This module stands on its own: it is headed before the parser, so it
 ~  carries the few text helpers it needs.
 ~!

#head "types"

!!! The version of the compiler itself, which the `built_in` conditions report.
!!! `COMPILER_VERSION` is the three parts packed as major * 10000 + minor * 100 +
!!! patch, so a source file can write `#if built_in(COMPILER_VERSION) >= 10000` for
!!! "1.0.0 or newer". The three parts stand in BuiltinFacts (builtin_conditions),
!!! and the drivers print the same number in the same spelling (`blang.b` and
!!! `cmp.b` of this toolchain, next to the toolchain ones of preproc_env).

!!! ---- small text helpers (the module stands on its own) ----

!!! The length of a text. A null text is empty and not a fault: a field of a struct
!!! that was never written holds null, and the `str` it stands for is
!!! empty there. `pe_len(x) == 0` is how this implementation asks `x.empty()`.
int pe_len -> str s {
    g_n_pelen = g_n_pelen + 1;
    if s == null {
        return 0;
    }
    int n = 0;
    while s[n] != (char)0 {
        n = n + 1;
    }
    return n;
}

bool pe_eq -> str a, str b {
    if a == null {
        return b == null;
    }
    if b == null {
        return false;
    }
    int i = 0;
    while a[i] != (char)0 {
        if a[i] != b[i] {
            return false;
        }
        i = i + 1;
    }
    return b[i] == (char)0;
}

!!! How many pieces of text were cut out of another, which BLANG_TIME prints: every
!!! one of them is a block asked of the heap and copied into, so the number says how
!!! much of a stage is string churn.
int g_n_pesub;
!!! How many texts were asked their length, which BLANG_TIME prints.
int g_n_pelen;

!!! The first `len` characters of `s` from `from`, as a block of its own.
str pe_sub -> str s, int from, int len {
    g_n_pesub = g_n_pesub + 1;
    if len < 0 {
        len = 0;
    }
    @void cell;
    malloc(@cell, len + 1);
    @char d = (@char)cell;
    int i = 0;
    while i < len && s[from + i] != (char)0 {
        d[i] = s[from + i];
        i = i + 1;
    }
    d[i] = (char)0;
    return (str)cell;
}

!!! From `from` to the end.
str pe_sub_to_end -> str s, int from {
    return pe_sub(s, from, pe_len(s) - from);
}

!!! The offset of the first `c` in `s`, or -1.
int pe_find -> str s, char c {
    int i = 0;
    while s[i] != (char)0 {
        if s[i] == c {
            return i;
        }
        i = i + 1;
    }
    return -1;
}

!!! Whether `name` stands at `s[i]`.
bool pe_matches -> str s, int i, str name {
    int k = 0;
    while name[k] != (char)0 {
        if s[i + k] != name[k] {
            return false;
        }
        k = k + 1;
    }
    return true;
}

str pe_char -> char c {
    @void cell;
    malloc(@cell, 2);
    @char p = (@char)cell;
    $p = c;
    @char last = p + 1;
    $last = (char)0;
    return (str)cell;
}

!!! ---- the built-in conditions ----

!!! One built-in condition: the name `built_in(...)` takes, the value it has, and
!!! the line `--builtins` prints and an unknown name quotes.
type BuiltinCond {
    str name;
    longlong value;
    str what;
    @BuiltinCond next;
};

!!! The facts only the driver knows, with the defaults of the target this compiler
!!! is built for.
type BuiltinFacts {
    bool arch_x64;
    bool arch_x86;
    bool arch_arm64;
    int ptr_size;
    bool endian_little;
    bool endian_big;
    bool os_windows;
    bool abi_win64;
    bool subsystem_gui;
    bool out_dll;
    bool runtime_static;
    bool dlls_static;
    bool debug;
    bool meta_mode;
    bool preprocess_only;
    bool emit_r;
    int version_major;
    int version_minor;
    int version_patch;
};

BuiltinFacts default_facts {
    BuiltinFacts f;
    f.arch_x64 = true;
    f.arch_x86 = false;
    f.arch_arm64 = false;
    f.ptr_size = 8;
    f.endian_little = true;
    f.endian_big = false;
    f.os_windows = true;
    f.abi_win64 = true;
    f.subsystem_gui = false;
    f.out_dll = false;
    f.runtime_static = false;
    f.dlls_static = false;
    f.debug = false;
    f.meta_mode = false;
    f.preprocess_only = false;
    f.emit_r = false;
    f.version_major = 1;
    f.version_minor = 0;
    f.version_patch = 0;
    return f;
}

longlong blang_version_packed -> int major, int minor, int patch {
    return (longlong)major * 10000 + (longlong)minor * 100 + (longlong)patch;
}

@BuiltinCond p_cond -> str name, longlong value, str what, @BuiltinCond next {
    BuiltinCond proto;
    @BuiltinCond c;
    malloc(@c, size proto);
    c.name = name;
    c.value = value;
    c.what = what;
    c.next = next;
    return c;
}

!!! The table of built-in conditions for a set of facts, in the order `--builtins`
!!! prints them. The chain is built from the back, so a walk reads them in that
!!! order.
@BuiltinCond builtin_conditions -> @BuiltinFacts f {
    @BuiltinCond c = null;
    c = p_cond("COMPILER_VERSION_PATCH", f.version_patch, "patch part of the compiler version", c);
    c = p_cond("COMPILER_VERSION_MINOR", f.version_minor, "minor part of the compiler version", c);
    c = p_cond("COMPILER_VERSION_MAJOR", f.version_major, "major part of the compiler version", c);
    c = p_cond("COMPILER_VERSION",
               blang_version_packed(f.version_major, f.version_minor, f.version_patch),
               "compiler version packed as major * 10000 + minor * 100 + patch", c);
    c = p_cond("COMPILER_BLANG", 1, "1 when the compiler is blang", c);
    c = p_cond("EMIT_R", f.emit_r ? 1 : 0, "1 when -R stops after writing the .r", c);
    c = p_cond("PREPROCESS_ONLY", f.preprocess_only ? 1 : 0,
               "1 when -I stops after preprocessing", c);
    c = p_cond("META_MODE", f.meta_mode ? 1 : 0,
               "1 when -m writes a .bmeta and compiles nothing", c);
    c = p_cond("DEBUG", f.debug ? 1 : 0, "1 when -d / -debug embeds debug info", c);
    c = p_cond("DLLS_STATIC", f.dlls_static ? 1 : 0,
               "1 when -static puts every linked DLL inside the output", c);
    c = p_cond("RUNTIME_STATIC", f.runtime_static ? 1 : 0,
               "1 when -static-runtime or -static puts the runtime inside the output", c);
    c = p_cond("OUT_DLL", f.out_dll ? 1 : 0,
               "1 when a DLL is being built instead of an executable", c);
    c = p_cond("SUBSYSTEM_CUI", f.subsystem_gui ? 0 : 1,
               "1 when the program is built as a console program", c);
    c = p_cond("SUBSYSTEM_GUI", f.subsystem_gui ? 1 : 0,
               "1 when the program is built as a windowed program (--type=win with -NO-WINDOW-CON)", c);
    c = p_cond("ABI_WIN64", f.abi_win64 ? 1 : 0,
               "1 when the target uses the Windows x64 calling convention", c);
    c = p_cond("OS_WINDOWS", f.os_windows ? 1 : 0, "1 when the target is Windows", c);
    c = p_cond("ENDIAN_BIG", f.endian_big ? 1 : 0, "1 when the target is big-endian", c);
    c = p_cond("ENDIAN_LITTLE", f.endian_little ? 1 : 0, "1 when the target is little-endian", c);
    c = p_cond("PTR_SIZE", f.ptr_size, "size of a pointer in bytes", c);
    c = p_cond("ARCH_ARM64", f.arch_arm64 ? 1 : 0, "1 when the target is 64-bit ARM", c);
    c = p_cond("ARCH_X86", f.arch_x86 ? 1 : 0, "1 when the target is 32-bit x86", c);
    c = p_cond("ARCH_X64", f.arch_x64 ? 1 : 0, "1 when the target is 64-bit x86", c);
    return c;
}

!!! The table of names and descriptions, which does not depend on the facts.
@BuiltinCond builtin_table {
    BuiltinFacts f = default_facts();
    return builtin_conditions(f);
}

!!! What a name means, for the error an unknown or misplaced name produces; empty
!!! when the name is not a built-in at all.
str builtin_what -> str name {
    @BuiltinCond c = builtin_table();
    while c != null {
        if pe_eq(name, c.name) {
            return c.what;
        }
        c = c.next;
    }
    return "";
}

!!! The names in table order, joined by ", ".
str builtin_name_list {
    str s = "";
    @BuiltinCond c = builtin_table();
    while c != null {
        if s != "" {
            s = s + ", ";
        }
        s = s + c.name;
        c = c.next;
    }
    return s;
}

!!! How `linked()` names a DLL and how the driver records one: lower case, no
!!! directory, no `.dll` or `.lib` suffix and no leading `lib`.
str preproc_dll_key -> str in {
    str s = in;
    int last = -1;
    int i = 0;
    while s[i] != (char)0 {
        if s[i] == '\\' || s[i] == '/' {
            last = i;
        }
        i = i + 1;
    }
    if last >= 0 {
        s = pe_sub_to_end(s, last + 1);
    }
    str low = "";
    int k = 0;
    while s[k] != (char)0 {
        char c = s[k];
        if c >= 'A' && c <= 'Z' {
            low = low + pe_char((char)((int)c + 32));
        } else {
            low = low + pe_char(c);
        }
        k = k + 1;
    }
    s = low;
    int n = pe_len(s);
    if n > 4 {
        str tail = pe_sub_to_end(s, n - 4);
        if pe_eq(tail, ".dll") || pe_eq(tail, ".lib") {
            s = pe_sub(s, 0, n - 4);
        }
    }
    n = pe_len(s);
    if n > 3 && pe_matches(s, 0, "lib") {
        s = pe_sub_to_end(s, 3);
    }
    return s;
}

!!! ---- the environment ----

type NameVal {
    str name;
    str value;
    @NameVal next;
};

type NameList {
    str name;
    @NameList next;
};

!!! Everything a condition may ask beyond the source text. The type owns the state
!!! and the questions asked of it: the operations are its methods, declared here and
!!! defined under the type, while the `env_*` names the preprocessor calls stay as
!!! one-line forwarders.
!!! The five fields stay public because the driver builds the environment field by
!!! field and `preproc_env_encode` walks them (blang.b), and the preprocessor reads
!!! several of them as well; only this module's own methods would let them be
!!! private, and no call site outside it may change.
type PreprocEnv {
    @BuiltinCond builtins;
    @NameVal defines;
    @NameList undefs;
    @NameList inc_dirs;
    @NameList linked;

    !!! The empty environment: the state a fresh one starts from, before a record of
    !!! the encoded text is read into it. `env_new` hands back a block asked of
    !!! `malloc`, on which no initialiser of the language runs, so this is a method.
    public stub void setup;

    !!! The value a built-in name has for these facts; `env_builtin_found` says
    !!! whether the name is one at all.
    public stub void builtin -> str name;

    !!! A name is defined when -D named it and -U did not. A built-in is not a define:
    !!! `defined(ARCH_X64)` is false, `built_in(ARCH_X64)` is 1.
    public stub bool defined -> str name;

    !!! The value of a define, and whether it is a number at all: a name defined
    !!! without a value is 1, one defined with text is 0.
    public stub longlong define_value -> str name;

    !!! Whether a DLL was linked, by the name `linked()` uses.
    public stub bool is_linked -> str name;

    !!! One record of the encoded environment read into the state: a -D, a -U, a -P
    !!! directory, a linked DLL, and a B record of the built-in table. They are what
    !!! `preproc_env_decode` reads the text with, and each one prepends its record
    !!! the way the chains were built before.
    public stub void add_define -> str name, str value;
    public stub void add_undef -> str name;
    public stub void add_inc_dir -> str name;
    public stub void add_linked -> str name;
    public stub void add_builtin -> str name, str num;

    !!! The built-in table of the default facts, for an environment whose text
    !!! carried no B record.
    public stub void use_default_builtins;
};

@PreprocEnv env_new {
    PreprocEnv proto;
    @PreprocEnv e;
    malloc(@e, size proto);
    e.setup();
    return e;
}

@NameVal p_nameval_add -> @NameVal head, str name, str value {
    NameVal proto;
    @NameVal n;
    malloc(@n, size proto);
    n.name = name;
    n.value = value;
    n.next = head;
    return n;
}

@NameList p_namelist_add -> @NameList head, str name {
    NameList proto;
    @NameList n;
    malloc(@n, size proto);
    n.name = name;
    n.next = head;
    return n;
}

!!! Append at the tail, so the order of the records is the order they were read.
@BuiltinCond p_cond_append -> @BuiltinCond head, @BuiltinCond node {
    if head == null {
        return node;
    }
    @BuiltinCond t = head;
    while t.next != null {
        t = t.next;
    }
    t.next = node;
    return head;
}

!!! Whether the last p_parse_int read a number, and the number it read.
bool p_parse_int_ok;
longlong p_parse_int_value;

!!! A whole string as a number: `0`, `-12`, `0x20`. Anything else does not count,
!!! which is the toolchain strtoll test ("did the whole text get read?").
void p_parse_int -> str t {
    p_parse_int_ok = false;
    p_parse_int_value = 0;
    int i = 0;
    int neg = 0;
    if t[0] == '-' {
        neg = 1;
        i = 1;
    } else if t[0] == '+' {
        i = 1;
    }
    int base = 10;
    if t[i] == '0' && (t[i + 1] == 'x' || t[i + 1] == 'X') {
        base = 16;
        i = i + 2;
    }
    longlong v = 0;
    int digits = 0;
    while t[i] != (char)0 {
        char c = t[i];
        int d = -1;
        if c >= '0' && c <= '9' {
            d = (int)c - (int)'0';
        } else if base == 16 && c >= 'a' && c <= 'f' {
            d = (int)c - (int)'a' + 10;
        } else if base == 16 && c >= 'A' && c <= 'F' {
            d = (int)c - (int)'A' + 10;
        }
        if d < 0 || d >= base {
            end;
        }
        v = v * base + d;
        digits = digits + 1;
        i = i + 1;
    }
    if digits == 0 {
        end;
    }
    if neg {
        v = 0 - v;
    }
    p_parse_int_value = v;
    p_parse_int_ok = true;
}

!!! ---- the environment's own methods ----
!!! The state belongs to the type, so every record of the encoded text is read into
!!! it through one of these, and the questions are asked of it through the methods
!!! that follow them.

void PreprocEnv::setup {
    self.builtins = null;
    self.defines = null;
    self.undefs = null;
    self.inc_dirs = null;
    self.linked = null;
}

void PreprocEnv::add_define -> str name, str value {
    self.defines = p_nameval_add(self.defines, name, value);
}

void PreprocEnv::add_undef -> str name {
    self.undefs = p_namelist_add(self.undefs, name);
}

void PreprocEnv::add_inc_dir -> str name {
    self.inc_dirs = p_namelist_add(self.inc_dirs, name);
}

void PreprocEnv::add_linked -> str name {
    self.linked = p_namelist_add(self.linked, name);
}

!!! A B record of the encoded environment: the name is looked up in the built-in
!!! table, and the name and the description of the record come from there, so they
!!! stay valid even though the environment is copied around. A name the table does
!!! not know adds nothing.
void PreprocEnv::add_builtin -> str name, str num {
    @BuiltinCond c = builtin_table();
    while c != null {
        if pe_eq(name, c.name) {
            p_parse_int(num);
            self.builtins = p_cond_append(self.builtins,
                                          p_cond(c.name, p_parse_int_value, c.what, null));
            end;
        }
        c = c.next;
    }
}

void PreprocEnv::use_default_builtins {
    if self.builtins == null {
        BuiltinFacts f = default_facts();
        self.builtins = builtin_conditions(f);
    }
}

!!! The value a built-in name has for these facts; `env_builtin_found` says
!!! whether the name is one at all.
longlong env_builtin_value;
bool env_builtin_found;

void PreprocEnv::builtin -> str name {
    env_builtin_found = false;
    env_builtin_value = 0;
    @BuiltinCond c = self.builtins;
    while c != null {
        if pe_eq(name, c.name) {
            env_builtin_found = true;
            env_builtin_value = c.value;
            end;
        }
        c = c.next;
    }
}

!!! The old name, kept as a one-line forwarder.
void env_builtin -> @PreprocEnv env, str name {
    env.builtin(name);
}

!!! A name is defined when -D named it and -U did not. A built-in is not a define:
!!! `defined(ARCH_X64)` is false, `built_in(ARCH_X64)` is 1.
bool PreprocEnv::defined -> str name {
    @NameList u = self.undefs;
    while u != null {
        if pe_eq(name, u.name) {
            return false;
        }
        u = u.next;
    }
    @NameVal d = self.defines;
    while d != null {
        if pe_eq(name, d.name) {
            return true;
        }
        d = d.next;
    }
    return false;
}

!!! The old name, kept as a one-line forwarder.
bool env_defined -> @PreprocEnv env, str name {
    return env.defined(name);
}

!!! The value of a define, and whether it is a number at all: a name defined
!!! without a value is 1, one defined with text is 0.
longlong PreprocEnv::define_value -> str name {
    env_is_number = false;
    @NameVal d = self.defines;
    while d != null {
        if pe_eq(name, d.name) {
            str t = d.value;
            if t == "" {
                env_is_number = true;
                return 1;
            }
            p_parse_int(t);
            if p_parse_int_ok {
                env_is_number = true;
                return p_parse_int_value;
            }
            return 0;
        }
        d = d.next;
    }
    return 0;
}

!!! The old name, kept as a one-line forwarder.
longlong env_define_value -> @PreprocEnv env, str name {
    return env.define_value(name);
}

bool env_is_number;

bool PreprocEnv::is_linked -> str name {
    str want = preproc_dll_key(name);
    @NameList l = self.linked;
    while l != null {
        if pe_eq(preproc_dll_key(l.name), want) {
            return true;
        }
        l = l.next;
    }
    return false;
}

!!! The old name, kept as a one-line forwarder.
bool env_is_linked -> @PreprocEnv env, str name {
    return env.is_linked(name);
}

!!! The factory stays a free function: it reads the encoded text one record at a
!!! time and hands every record to a method of the environment it builds, so no
!!! field of the type is touched from out here.
@PreprocEnv preproc_env_decode -> str spec {
    @PreprocEnv env = env_new();
    int pos = 0;
    int n = pe_len(spec);
    while pos < n {
        int eol = pos;
        while eol < n && spec[eol] != '\n' {
            eol = eol + 1;
        }
        str rec = pe_sub(spec, pos, eol - pos);
        pos = eol + 1;
        if pe_len(rec) < 2 {
            continue;
        }
        char rec_kind = rec[0];
        str rest = pe_sub_to_end(rec, 1);
        if rec_kind == 'D' {
            str nm = rest;
            str val = "1";
            int eq = pe_find(rest, '=');
            if eq >= 0 {
                nm = pe_sub(rest, 0, eq);
                val = pe_sub_to_end(rest, eq + 1);
            }
            env.add_define(nm, val);
        } else if rec_kind == 'U' {
            env.add_undef(rest);
        } else if rec_kind == 'P' {
            env.add_inc_dir(rest);
        } else if rec_kind == 'L' {
            env.add_linked(rest);
        } else if rec_kind == 'B' {
            int eq2 = pe_find(rest, '=');
            if eq2 >= 0 {
                env.add_builtin(pe_sub(rest, 0, eq2), pe_sub_to_end(rest, eq2 + 1));
            }
        }
    }
    !!! The built-in table of the default facts is what an environment keeps when
    !!! none of its records named one.
    env.use_default_builtins();
    return env;
}
