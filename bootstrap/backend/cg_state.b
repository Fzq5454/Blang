#once
!~
 ~  bootstrap/backend/cg_state.b: the state of the code generator.
 ~
 ~  It is the CodeGenerator members of backend/codegen: the symbol
 ~  table, the function tables, the import tables, the buffer offsets and the
 ~  counters the modules of backend/codegen_* read and write.
 ~
 ~  the toolchain keeps all of it in one object; cmp.exe generates one module, so the same
 ~  state is a set of globals named `cg_*` and the methods become
 ~  functions of the same name. Every name table becomes a table of the
 ~  port: the ones asked about at every expression are the index of cmp_index.b (one
 ~  probe), the symbol table below is a hash table of its own, and the operations a
 ~  module does not use are not written until they are needed.
 ~!

#head "cmp_ir"
#head "cmp_text"
#head "cmp_arena"
#head "emitter"
#head "pe_writer"
#head "vector"

!!! Offsets of entry-scope variables (globals, package variables) carry this bias,
!!! so a raw stack offset alone tells whether the slot lives in the entry frame
!!! (reached through r15) or in the frame of the function being generated.
int kGlobalBase;

!!! Bytes reserved above the locals for expression temporaries. The addresses are
!!! next_stack_offset + nesting * 8, so this is the deepest nesting one body may
!!! reach: 512 bytes is 64 slots.
int kTempSlotBytes;

!!! Slots in the conversion ring (see cg_tostr_buf_off). A conversion result is a
!!! pointer into it, so a value a program keeps stays correct only until the ring
!!! comes back around to its slot.
int kTostrSlots;

!!! ---- the machine-code optimizations -nopt asks to leave out ----
!!!
!!! cmp.exe sets these from -nopt-reg / -nopt-asm / -nopt (see cmp.b). They are
!!! read where the back end would otherwise write the shorter form, and each of
!!! those places already has the plain form it uses when the optimization does not
!!! apply, so turning one off chooses the code that was there before it.
!!!
!!!   cg_nopt_reg  no register shortcuts: an operand that can be read straight into
!!!                the register an operation wants (the right side of a binary
!!!                operation into rdx, a call argument into its register) goes
!!!                through a temporary stack slot instead.
!!!   cg_nopt_asm  no instruction-level shortcuts: a small constant stays out of the
!!!                instruction, a branch on a comparison goes through 0/1, a `s[i]`
!!!                calls the runtime and an allocation calls VirtualAlloc.
bool cg_nopt_reg;
bool cg_nopt_asm;

!!! ---- one variable of the symbol table ----

type CgVarInfo {
    VarType ty;
    int stack_offset;
    int ptr_depth;
    bool is_array;
    @CmpIntNode dims;
    str struct_type;
    bool struct_ptr;
    !!! A variable declared in the entry scope: its slot lives in the entry frame,
    !!! which functions reach through r15 (set up once by the entry prologue).
    bool is_global;
};

@CgVarInfo cg_var_new {
    CgVarInfo proto;
    @CgVarInfo v;
    cg_balloc(@v, size proto);
    v.ty = INT;
    v.stack_offset = 0;
    v.ptr_depth = 0;
    v.is_array = false;
    v.dims = null;
    v.struct_type = "";
    v.struct_ptr = false;
    v.is_global = false;
    return v;
}

@CgVarInfo cg_var_copy -> @CgVarInfo s {
    @CgVarInfo v = cg_var_new();
    v.ty = s.ty;
    v.stack_offset = s.stack_offset;
    v.ptr_depth = s.ptr_depth;
    v.is_array = s.is_array;
    v.dims = s.dims;
    v.struct_type = s.struct_type;
    v.struct_ptr = s.struct_ptr;
    v.is_global = s.is_global;
    return v;
}

!!! ---- the symbol table ----
!!!
!!! the toolchain keeps `syms` in a name table, so a name is found with one
!!! probe. this implementation kept a chain in the order the names were last asked for, which
!!! is a few hundred entries long: every entry-scope variable of the module is in
!!! it for the whole compile, and a body asks for names that are scattered over it.
!!! Measured on bootstrap/blang.b: 82k lookups walked 15.2M entries, and that walk
!!! was most of the compile time. Nothing about the table is read by position (the
!!! walks an unordered_map for the one list that reads it, so even the debug
!!! block cannot be depended on for an order), so the chain is replaced here by an
!!! open hash table: one bucket array and one pool of slots.
!!!
!!! A slot is named by its number rather than by a pointer, because a lookup hands
!!! its caller the `@CgVarInfo` the name stands for and the language cannot turn a
!!! number back into a struct pointer. `cg_sym_slot` answers the address of the
!!! slot itself (the vector's `at`), which is what a field of it is read and
!!! written through.
!!!
!!! Shadowing is unchanged: a name has one slot, a body that redeclares it saves
!!! what stood there and sets it back (or drops it) afterwards.
type CgSymSlot {
    str key;
    @CgVarInfo v;
    int next;
    bool dead;
};

vector(CgSymSlot) cg_sym_slots;
vector(int) cg_sym_bucket;
int cg_sym_mask;
int cg_sym_live;

!!! The bucket a name falls in. Any spread works - nothing outside this table sees
!!! it - and it is djb2, the same one the name index of cmp_index.b uses.
int cg_sym_hash -> str key {
    int h = 5381;
    int n = pe_len(key);
    int i = 0;
    while i < n {
        h = h * 33 + ((int)key[i] & 255);
        i = i + 1;
    }
    return h;
}

!!! The slot a number names. The address is the element of the pool itself.
@CgSymSlot cg_sym_slot -> int id {
    return cg_sym_slots.at(id - 1);
}

!!! Twice as many buckets and every live slot put back. The slots are walked in
!!! pool order, which is the order they were made in.
void cg_sym_rehash {
    cg_sym_mask = cg_sym_mask * 2 + 1;
    cg_sym_bucket.clear();
    int b = 0;
    while b < cg_sym_mask + 1 {
        cg_sym_bucket.add(0);
        b = b + 1;
    }
    int n = cg_sym_slots.len;
    int i = 0;
    while i < n {
        @CgSymSlot s = cg_sym_slot(i + 1);
        if !s.dead {
            int h = cg_sym_hash(s.key) & cg_sym_mask;
            s.next = cg_sym_bucket.get(h);
            cg_sym_bucket.put(h, i + 1);
        }
        i = i + 1;
    }
}

void cg_sym_init {
    cg_sym_slots.release();
    cg_sym_bucket.release();
    cg_sym_mask = 1023;
    cg_sym_live = 0;
    int b = 0;
    while b < cg_sym_mask + 1 {
        cg_sym_bucket.add(0);
        b = b + 1;
    }
}

!!! The variable `name` names, or null.
@CgVarInfo cg_sym_find -> str name {
    int id = cg_sym_bucket.get(cg_sym_hash(name) & cg_sym_mask);
    while id != 0 {
        @CgSymSlot s = cg_sym_slot(id);
        if pe_eq(s.key, name) {
            return s.v;
        }
        id = s.next;
    }
    return null;
}

!!! Put a value under a name, or replace the value it already has.
void cg_sym_set -> str name, @CgVarInfo v {
    int h = cg_sym_hash(name) & cg_sym_mask;
    int id = cg_sym_bucket.get(h);
    while id != 0 {
        @CgSymSlot s = cg_sym_slot(id);
        if pe_eq(s.key, name) {
            s.v = v;
            end;
        }
        id = s.next;
    }
    CgSymSlot fresh;
    fresh.key = name;
    fresh.v = v;
    fresh.next = cg_sym_bucket.get(h);
    fresh.dead = false;
    cg_sym_slots.add(fresh);
    cg_sym_bucket.put(h, cg_sym_slots.len);
    cg_sym_live = cg_sym_live + 1;
    if cg_sym_live * 4 > (cg_sym_mask + 1) * 3 {
        cg_sym_rehash();
    }
}

!!! Take a name out of the table. The slot stays in the pool and is marked, so the
!!! debug walk knows it is gone.
void cg_sym_drop -> str name {
    int h = cg_sym_hash(name) & cg_sym_mask;
    int id = cg_sym_bucket.get(h);
    int prev = 0;
    while id != 0 {
        @CgSymSlot s = cg_sym_slot(id);
        if pe_eq(s.key, name) {
            if prev == 0 {
                cg_sym_bucket.put(h, s.next);
            } else {
                @CgSymSlot p = cg_sym_slot(prev);
                p.next = s.next;
            }
            s.dead = true;
            cg_sym_live = cg_sym_live - 1;
            end;
        }
        prev = id;
        id = s.next;
    }
}

!!! ---- the sequence of the code generator ----

int cg_next_stack_offset;
int cg_binop_nesting;
int cg_pe_type;
bool cg_debug_info;
bool cg_no_runtime;
bool cg_static_runtime;
str cg_user_libs;
str cg_current_func;
str cg_pass_func;
str cg_gen_error;
str cg_filename;

!!! TRY/CATCH: hardware exception catching.
bool cg_uses_try;
bool cg_uses_raise;
int cg_exc_head_off;
int cg_exc_code_off;
int cg_veh_off;
int cg_try_depth;
!!! Where the body's local slots sit relative to the frame base. The resolve pass
!!! numbers a function's locals from zero; the prologue moves them into the frame
!!! it just made, and a DECLARED statement that carries its own slot (cg_gen_declared)
!!! needs the same bias the entry install applies.
int cg_local_bias;

!!! The bindings a nested block shadows, put aside for the length of that block.
!!! The symbol table is one map keyed by name, so a declaration inside a block
!!! replaced the outer variable of the same name for the rest of the function:
!!! `str t = "outer"; if c { int t = 5; } system.out(t);` printed the inner int.
!!! A record whose `mark` is set starts a block; the records under it are what that
!!! block's declarations replaced, `present` saying whether the name was in the
!!! table at all (a name only the block declares is dropped again when it ends).
type CgBlockShadow {
    str name;
    @CgVarInfo had;
    bool present;
    bool mark;
    @CgBlockShadow next;
};
@CgBlockShadow cg_block_shadows;

!!! The conversion ring and the entry block.
int cg_tostr_buf_off;
int cg_tostr_idx_off;
int cg_globals_off;
int cg_tostr_digits_off;
int cg_tostr_int_off;
int cg_tostr_long_off;
int cg_tostr_float_off;

!!! Import indices of the runtime's own calls.
int cg_idx_exitprocess;
int cg_idx_virtualalloc;
int cg_idx_virtualfree;
int cg_idx_addveh;
int cg_idx_raiseexception;

void cg_state_init -> str fname {
    kGlobalBase = 0x100000;
    kTempSlotBytes = 512;
    kTostrSlots = 64;
    cg_sym_init();
    cg_next_stack_offset = 0x20;
    cg_binop_nesting = 0;
    cg_pe_type = 0;
    cg_debug_info = false;
    cg_no_runtime = false;
    cg_static_runtime = false;
    cg_user_libs = "";
    cg_current_func = "";
    cg_pass_func = "";
    cg_gen_error = "";
    cg_filename = fname;
    cg_uses_try = false;
    cg_uses_raise = false;
    cg_exc_head_off = 0;
    cg_exc_code_off = 0;
    cg_veh_off = 0;
    cg_try_depth = 0;
    cg_tostr_buf_off = 0;
    cg_tostr_idx_off = 0;
    cg_globals_off = 0;
    cg_tostr_digits_off = 0;
    cg_tostr_int_off = 0;
    cg_tostr_long_off = 0;
    cg_tostr_float_off = 0;
    cg_idx_exitprocess = 0;
    cg_idx_virtualalloc = 0;
    cg_idx_virtualfree = 0;
    cg_idx_addveh = 0;
    cg_idx_raiseexception = 0;
}

!!! ---- name -> one value, the shape most of the tables have ----

type CgStrInt {
    str key;
    int v;
    @CgStrInt next;
};

type CgStrBool {
    str key;
    bool v;
    @CgStrBool next;
};

type CgStrVar {
    str key;
    @CgVarInfo v;
    @CgStrVar next;
};

!!! name -> a chain of ints (the `a chain of int`).
type CgStrInts {
    str key;
    @CgStrInts next;
};

!!! name -> a chain of (name, offset) pairs: `func_vars`, `_func_local_syms`.
type CgNameOff {
    str name;
    int off;
    @CgVarInfo info;
    @CgNameOff next;
};

type CgStrNameOffs {
    str key;
    @CgNameOff v;
    @CgStrNameOffs next;
};

!!! name -> a chain of (param, type): `_func_param_types`.
type CgNameType {
    str name;
    VarType ty;
    @CgNameType next;
};

type CgStrNameTypes {
    str key;
    @CgNameType v;
    @CgStrNameTypes next;
};

!!! ---- the tables ----

@CmpStructType cg_struct_types;
@CgStrBool cg_owned_strs;
@CgStrInt cg_blib_import_idx;
@CgStrInt cg_import_thunks;
@CgStrNameOffs cg_func_params;
@CgStrNameTypes cg_func_param_types;
@CgStrNameOffs cg_func_vars;
@CgStrNameOffs cg_func_local_syms;
@CgStrInts cg_func_param_offsets;

!!! A function a linked DLL exports. A signature file declares every function its
!!! DLL exports, but a program calls a handful of them, and an import descriptor
!!! costs .idata space in the image. So registering a declaration only records the
!!! signature; the IAT slot (idx) is asked for the first time the generated code
!!! reaches the function, and `registered` tells whether that has happened yet.
type CgDllImport {
    str dll;
    int idx;
    @CmpTypeNode param_types;
    VarType ret_type;
    bool registered;
};

type CgStrDllImport {
    str key;
    @CgDllImport v;
    @CgStrDllImport next;
};

@CgStrDllImport cg_dll_imports;

!!! The import `key` names, moved to the front of the chain once it is found.
!!!
!!! A call site asks for the import of the function it calls, and the chain holds
!!! every name of every signature file - kernel32 alone declares thousands - so the
!!! walk was long. The order of this chain is read by nothing (the stubs are
!!! emitted over the index of cmp_index.b, which is the registration order), so the
!!! entry that was just asked for goes to the front: a program calls a handful of
!!! imported functions, and after the first call each of them is found at once.
!!! The import `key` names, with the entry that was found moved to the front.
!!!
!!! A call site asks for the import of the function it calls, and the chain holds
!!! every name of every signature file - kernel32 alone declares thousands - so the
!!! walk was long. Nothing reads this chain in order (the stubs are emitted over the
!!! index of cmp_index.b, which is the registration order), so the entry that was
!!! asked for takes the place of the head and the head takes its - the pointers the
!!! two nodes are held by do not move, only what they carry does. A program calls a
!!! handful of imported functions, so after the first call each of them is found at
!!! once.
@CgStrDllImport cg_strdll_find -> @CgStrDllImport head, str key {
    if head == null {
        return null;
    }
    if pe_eq(head.key, key) {
        return head;
    }
    @CgStrDllImport e = head.next;
    while e != null {
        if pe_eq(e.key, key) {
            str tk = head.key;
            @CgDllImport tv = head.v;
            head.key = e.key;
            head.v = e.v;
            e.key = tk;
            e.v = tv;
            return head;
        }
        e = e.next;
    }
    return null;
}

!!! Record one import, replacing what the name already carries.
!!!
!!! The chain is only walked when the index says the name is in it: a signature
!!! file registers every function it declares, so the walk that looked for a name
!!! that was not there yet made registering a whole DLL quadratic (measured: 0.8M
!!! steps for kernel32 and the runtime together).
@CgStrDllImport cg_strdll_set -> @CgStrDllImport head, str key, @CgDllImport v {
    if ix_has(kIxDllImport, key) {
        @CgStrDllImport e = head;
        while e != null {
            if pe_eq(e.key, key) {
                e.v = v;
                return head;
            }
            e = e.next;
        }
    } else {
        ix_set(kIxDllImport, key, 1, 0, 0, 0, "");
    }
    CgStrDllImport proto;
    @CgStrDllImport n;
    cg_balloc(@n, size proto);
    n.key = key;
    n.v = v;
    n.next = head;
    return n;
}

!!! name -> one type: the tables the index does not hold.

!!! A call whose target is not known yet: a function the module defines further
!!! down the file. The rel32 operand is patched once every body has been generated.
type CgPendingCall {
    int patch_pos;
    str name;
    int line;
    int col;
    @CgPendingCall next;
};

!!! A closure object stores the address of its hidden function as a rip-relative
!!! `lea`, and that function may be defined later in the file.
type CgPendingCodeAddr {
    int disp_pos;
    int instr_end;
    str name;
    int line;
    int col;
    @CgPendingCodeAddr next;
};

@CgPendingCall cg_pending_calls;
@CgPendingCodeAddr cg_pending_code_addrs;

void cg_pending_call_add -> int pos, str name, int line, int col {
    CgPendingCall proto;
    @CgPendingCall p;
    cg_balloc(@p, size proto);
    p.patch_pos = pos;
    p.name = name;
    p.line = line;
    p.col = col;
    p.next = cg_pending_calls;
    cg_pending_calls = p;
}

void cg_pending_addr_add -> int disp_pos, int instr_end, str name, int line, int col {
    CgPendingCodeAddr proto;
    @CgPendingCodeAddr p;
    cg_balloc(@p, size proto);
    p.disp_pos = disp_pos;
    p.instr_end = instr_end;
    p.name = name;
    p.line = line;
    p.col = col;
    p.next = cg_pending_code_addrs;
    cg_pending_code_addrs = p;
}

!!! One function's signature, for the `.bmeta` a DLL build writes.
type CgFuncSig {
    str name;
    VarType ret_type;
    @CmpTypeNode param_types;
    @CmpStrNode param_names;
    bool is_local;
    @CgFuncSig next;
};

@CgFuncSig cg_func_signatures;
@CgFuncSig cg_func_signatures_tail;

void cg_sig_add -> str name, VarType ret_type, @CmpTypeNode param_types,
                    @CmpStrNode param_names, bool is_local, bool variadic {
    CgFuncSig proto;
    @CgFuncSig g;
    cg_balloc(@g, size proto);
    g.name = name;
    g.ret_type = ret_type;
    g.param_types = param_types;
    g.param_names = param_names;
    g.is_local = is_local;
    g.next = null;
    !!! Appended through the tail the same way the toolchain push_back does: this implementation
    !!! wrote this as a walk to the end, which is quadratic over the functions of
    !!! a module.
    if cg_func_signatures == null {
        cg_func_signatures = g;
    } else {
        cg_func_signatures_tail.next = g;
    }
    cg_func_signatures_tail = g;
}

!!! name -> (param -> struct name): `_func_param_struct`.
type CgNameStr {
    str name;
    str v;
    @CgNameStr next;
};

type CgStrNameStrs {
    str key;
    @CgStrNameStrs next;
};

@CgStrNameStrs cg_func_param_struct_names;

@CgStrNameStrs cg_strnamestrs_set -> int tbl, @CgStrNameStrs head, str key, @CgNameStr v {
    if ix_has(tbl, key) {
        @CgStrNameStrs e = head;
        while e != null {
            if pe_eq(e.key, key) {
                return head;
            }
            e = e.next;
        }
    } else {
        ix_set(tbl, key, 1, 0, 0, 0, "");
    }
    CgStrNameStrs proto;
    @CgStrNameStrs n;
    cg_balloc(@n, size proto);
    n.key = key;
    n.next = head;
    return n;
}

@CgNameStr cg_namestr_add -> @CgNameStr head, str name, str v {
    CgNameStr proto;
    @CgNameStr n;
    cg_balloc(@n, size proto);
    n.name = name;
    n.v = v;
    n.next = null;
    if head == null {
        return n;
    }
    @CgNameStr t = head;
    while t.next != null {
        t = t.next;
    }
    t.next = n;
    return head;
}

!!! ---- the chain operations ----

!!! The layout of one struct by name, out of the table the parser built.
@CmpStructType cg_find_struct -> str name {
    @CmpStructType st = cg_struct_types;
    while st != null {
        if pe_eq(st.name, name) {
            return st;
        }
        st = st.next;
    }
    return null;
}

!!! One `call [rip+disp32]` whose displacement is filled in once the import table
!!! has its RVAs.
type CgCallPatch {
    int pos;
    int import_idx;
    @CgCallPatch next;
};

!!! One function of a `.bmeta` signature file, as the reader of bmeta.b hands it
!!! back. the toolchain carries the parameter names as well and only the types are ever
!!! used, so this implementation keeps the types alone.
type CgBmetaFunc {
    str name;
    VarType ret_type;
    @CmpTypeNode param_types;
    @CgBmetaFunc next;
};

!!! The code of one linked library (`lib/<name>.lib`), the names it defines with
!!! their offsets in that code, and the native functions it calls.
type CgBlibImport {
    int off;
    str dll;
    !!! `fnc` and not `func`: `func` is a type keyword, so it can be declared as a
    !!! field but not read back as one.
    str fnc;
    @CgBlibImport next;
};

type CgBlibSym {
    str name;
    int off;
    @CgBlibSym next;
};

type CgBlib {
    @PEBuf code;
    @CgBlibSym syms;
    @CgBlibImport imports;
    @CgBlib next;
};

!!! A DLL whose code has been placed into this image instead of being imported
!!! (-static-runtime / -static). The side file cmp writes beside every DLL it builds
!!! (meta/<dll>.bst) carries what that needs: the code, the exported names with
!!! their offsets, the DLL's own import call sites, its .rdata, and the places in
!!! its code that refer to that .rdata.
type CgEmbeddedImport {
    int disp_pos;
    str dll;
    str fnc;
    @CgEmbeddedImport next;
};

type CgEmbeddedRdataRef {
    int disp_pos;
    int rdata_off;
    @CgEmbeddedRdataRef next;
};

type CgEmbeddedDll {
    str dll;
    @PEBuf code;
    @CgBlibSym syms;
    @CgEmbeddedImport imports;
    @PEBuf rdata;
    @CgEmbeddedRdataRef rdata_refs;
    int text_off;
    int rdata_off;
    @CgEmbeddedDll next;
};


!!! The accumulated link errors and the two stacks of pending jump positions. The
!!! keeps them in a chain; the ints are positions in .text.
@CmpStrNode cg_link_errors;
@CmpIntNode cg_break_stack;
@CmpIntNode cg_continue_targets;
@CmpStrNode cg_loaded_libs;
@CgCallPatch cg_call_patches;
@CgBlib cg_blibs;
@CmpIntNode cg_blib_text_off_list;
@CgEmbeddedDll cg_embedded;
@CgEmbeddedDll cg_embedded_tail;
@CgEmbeddedRdataRef cg_rdata_refs;
@CgEmbeddedRdataRef cg_rdata_refs_tail;

@CgStrInt cg_strint_find -> @CgStrInt head, str key {
    @CgStrInt e = head;
    while e != null {
        if pe_eq(e.key, key) {
            return e;
        }
        e = e.next;
    }
    return null;
}

@CgStrInt cg_strint_set -> @CgStrInt head, str key, int v {
    @CgStrInt e = head;
    while e != null {
        if pe_eq(e.key, key) {
            e.v = v;
            return head;
        }
        e = e.next;
    }
    CgStrInt proto;
    @CgStrInt n;
    cg_balloc(@n, size proto);
    n.key = key;
    n.v = v;
    n.next = head;
    return n;
}

@CgStrBool cg_strbool_find -> @CgStrBool head, str key {
    @CgStrBool e = head;
    while e != null {
        if pe_eq(e.key, key) {
            return e;
        }
        e = e.next;
    }
    return null;
}

bool cg_set_has -> @CgStrBool head, str key {
    @CgStrBool e = cg_strbool_find(head, key);
    return e != null && e.v;
}

@CgStrBool cg_strbool_set -> @CgStrBool head, str key, bool v {
    @CgStrBool e = head;
    while e != null {
        if pe_eq(e.key, key) {
            e.v = v;
            return head;
        }
        e = e.next;
    }
    CgStrBool proto;
    @CgStrBool n;
    cg_balloc(@n, size proto);
    n.key = key;
    n.v = v;
    n.next = head;
    return n;
}

@CgStrBool cg_set_add -> @CgStrBool head, str key {
    return cg_strbool_set(head, key, true);
}

@CgStrBool cg_set_drop -> @CgStrBool head, str key {
    @CgStrBool prev = null;
    @CgStrBool e = head;
    while e != null {
        if pe_eq(e.key, key) {
            if prev == null {
                return e.next;
            }
            prev.next = e.next;
            return head;
        }
        prev = e;
        e = e.next;
    }
    return head;
}

@CgStrVar cg_strvar_find -> @CgStrVar head, str key {
    @CgStrVar e = head;
    while e != null {
        if pe_eq(e.key, key) {
            return e;
        }
        e = e.next;
    }
    return null;
}

@CgStrVar cg_strvar_set -> @CgStrVar head, str key, @CgVarInfo v {
    @CgStrVar prev = null;
    @CgStrVar e = head;
    while e != null {
        if pe_eq(e.key, key) {
            e.v = v;
            !!! The entry that was written goes to the front, the same way a lookup
            !!! moves the entry it found: a body declares and names the same handful
            !!! of variables over and over, so the walk stays short. Nothing reads
            !!! the symbol table by position.
            if prev != null {
                prev.next = e.next;
                e.next = head;
                return e;
            }
            return head;
        }
        prev = e;
        e = e.next;
    }
    CgStrVar proto;
    @CgStrVar n;
    cg_balloc(@n, size proto);
    n.key = key;
    n.v = v;
    n.next = head;
    return n;
}

@CgStrNameOffs cg_strnameoffs_find -> @CgStrNameOffs head, str key {
    @CgStrNameOffs e = head;
    while e != null {
        if pe_eq(e.key, key) {
            return e;
        }
        e = e.next;
    }
    return null;
}

!!! One more entry under a name. The index of cmp_index.b answers whether the name
!!! is in the table at all, which is what keeps a table that is written once per
!!! function (a signature, the variables of a body) from being quadratic: the walk
!!! below then only runs for a name that really is there.
@CgStrNameOffs cg_strnameoffs_set -> int tbl, @CgStrNameOffs head, str key, @CgNameOff v {
    if ix_has(tbl, key) {
        @CgStrNameOffs e = head;
        while e != null {
            if pe_eq(e.key, key) {
                e.v = v;
                return head;
            }
            e = e.next;
        }
    } else {
        ix_set(tbl, key, 1, 0, 0, 0, "");
    }
    CgStrNameOffs proto;
    @CgStrNameOffs n;
    cg_balloc(@n, size proto);
    n.key = key;
    n.v = v;
    n.next = head;
    return n;
}

!!! One more (name, offset) pair at the END of the chain.
!!!
!!! The order matters for the list of a function's locals: a body that declares the
!!! same name twice (both arms of an `if` are one walk) puts two entries under it,
!!! and installing the list sets the symbol table to the last one - which is the
!!! entry the toolchain ends up with as well, because it appends in the same order. This
!!! is why the list that installs into the symbol table appends while the debug
!!! lists (a whole symbol table per function) prepend: appending them would make
!!! building one quadratic, and nothing reads them by position.
@CgNameOff cg_nameoff_add -> @CgNameOff head, str name, int off, @CgVarInfo info {
    CgNameOff proto;
    @CgNameOff n;
    cg_balloc(@n, size proto);
    n.name = name;
    n.off = off;
    n.info = info;
    n.next = null;
    if head == null {
        return n;
    }
    @CgNameOff t = head;
    while t.next != null {
        t = t.next;
    }
    t.next = n;
    return head;
}

!!! One more (name, offset) pair at the HEAD of the chain: the same list built in
!!! one step, for the lists whose order is not read.
@CgNameOff cg_nameoff_push -> @CgNameOff head, str name, int off, @CgVarInfo info {
    CgNameOff proto;
    @CgNameOff n;
    cg_balloc(@n, size proto);
    n.name = name;
    n.off = off;
    n.info = info;
    n.next = head;
    return n;
}

!!! ---- the stack of loop positions ----

!!! Push one position onto a stack (`cg_continue_targets`): where a loop goes round
!!! again, innermost last. A stack is built at its head, which is what makes the
!!! pop one step; `cn_int` appends, and using it left the newest entry behind and
!!! dropped the outermost one instead - a `continue` in an outer loop, after an
!!! inner loop had closed, jumped back into the inner loop.
@CmpIntNode cg_int_push -> @CmpIntNode head, int v {
    CmpIntNode proto;
    @CmpIntNode n;
    cg_balloc(@n, size proto);
    n.v = v;
    n.next = head;
    return n;
}

@CmpIntNode cg_int_pop -> @CmpIntNode head {
    if head == null {
        return null;
    }
    return head.next;
}

@CgNameOff cg_nameoff_find -> @CgNameOff head, str name {
    @CgNameOff e = head;
    while e != null {
        if pe_eq(e.name, name) {
            return e;
        }
        e = e.next;
    }
    return null;
}

@CgStrNameTypes cg_strnametypes_find -> @CgStrNameTypes head, str key {
    @CgStrNameTypes e = head;
    while e != null {
        if pe_eq(e.key, key) {
            return e;
        }
        e = e.next;
    }
    return null;
}

@CgNameType cg_nametype_set -> @CgNameType head, str name, VarType ty {
    @CgNameType e = head;
    while e != null {
        if pe_eq(e.name, name) {
            e.ty = ty;
            return head;
        }
        e = e.next;
    }
    CgNameType proto;
    @CgNameType n;
    cg_balloc(@n, size proto);
    n.name = name;
    n.ty = ty;
    n.next = head;
    return n;
}

@CgStrNameTypes cg_strnametypes_set -> int tbl, @CgStrNameTypes head, str key, @CgNameType v {
    if ix_has(tbl, key) {
        @CgStrNameTypes e = head;
        while e != null {
            if pe_eq(e.key, key) {
                e.v = v;
                return head;
            }
            e = e.next;
        }
    } else {
        ix_set(tbl, key, 1, 0, 0, 0, "");
    }
    CgStrNameTypes proto;
    @CgStrNameTypes n;
    cg_balloc(@n, size proto);
    n.key = key;
    n.v = v;
    n.next = head;
    return n;
}

@CgStrInts cg_strints_set -> int tbl, @CgStrInts head, str key, @CmpIntNode v {
    if ix_has(tbl, key) {
        @CgStrInts e = head;
        while e != null {
            if pe_eq(e.key, key) {
                return head;
            }
            e = e.next;
        }
    } else {
        ix_set(tbl, key, 1, 0, 0, 0, "");
    }
    CgStrInts proto;
    @CgStrInts n;
    cg_balloc(@n, size proto);
    n.key = key;
    n.next = head;
    return n;
}

!!! The entry of one parameter of one function in `cg_func_params`, and the type
!!! `cg_func_param_types` holds for it. Both read the tables the function walk
!!! fills, so they stand after the chain helpers they use.
@CgNameOff cg_param_off -> str fname, str pname {
    @CgStrNameOffs m = cg_strnameoffs_find(cg_func_params, fname);
    if m == null {
        return null;
    }
    return cg_nameoff_find(m.v, pname);
}

VarType cg_param_type -> str fname, str pname {
    @CgStrNameTypes m = cg_strnametypes_find(cg_func_param_types, fname);
    if m == null {
        return INT;
    }
    @CgNameType e = m.v;
    while e != null {
        if pe_eq(e.name, pname) {
            return e.ty;
        }
        e = e.next;
    }
    return INT;
}
