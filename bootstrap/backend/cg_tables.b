#once
!~
 ~  bootstrap/backend/cg_tables.b: the name-keyed tables of the code generator.
 ~
 ~  the tables the code generator asks about a name - the functions
 ~  it defines and their arity, whether one is variadic, what a call hands back,
 ~  whether a name is a DLL import - over the index of cmp_index.b.
 ~
 ~  Each of these was a chain in this implementation and a name table in the toolchain, so a
 ~  lookup walked the chain while the toolchain probed a table. The chains are gone for
 ~  the tables whose entries are written out again (the functions a module defines,
 ~  and the imports whose stubs are emitted): a walk of those is a walk of the index
 ~  in registration order, which is the order the toolchain writes them in.
 ~
 ~  The tables whose value is a pointer keep the chain the pointer lives in - the
 ~  language cannot put one in an untyped slot and read it back - and ask the index
 ~  whether the name is there at all, which is the question asked at every call
 ~  site. The symbol table of the body being emitted is the same shape and stands in
 ~  cg_state.b, beside the pool of slots it is built from.
 ~!

#head "cg_heads"
#head "cmp_index"

!!! ---- the type a stored number stands for ----

!!! The VarType a stored number stands for. The language has no cast to an enum
!!! type - `(VarType)v` is not a form it knows - so the number is turned back by
!!! naming the member it is. INT is 0, which is also what "no type known" is read
!!! as, and that is exactly the toolchain default for a parameter whose type is absent.
VarType cg_vt_of -> int t {
    switch t {
        case FLOAT:
            return FLOAT;
        case STR:
            return STR;
        case BOOL:
            return BOOL;
        case CHAR:
            return CHAR;
        case VOID:
            return VOID;
        case ANY:
            return ANY;
        case FUNC:
            return FUNC;
        case AT_INT:
            return AT_INT;
        case AT_FLOAT:
            return AT_FLOAT;
        case AT_CHAR:
            return AT_CHAR;
        case AT_STR:
            return AT_STR;
        case AT_VOID:
            return AT_VOID;
        case AT_BOOL:
            return AT_BOOL;
        case AT_FUNC:
            return AT_FUNC;
        case LONG:
            return LONG;
        case AT_LONG:
            return AT_LONG;
    }
    !!! INT, which is the 0 an unknown type is stored as.
    return INT;
}

!!! The symbol table of the body being emitted lives in cg_state.b, because a slot
!!! of it is a value of the pool the table is built from. What is here is only the
!!! question the index answers about a name.

!!! ---- the functions a module defines ----

!!! The offset the code of `name` starts at, or 0 when the module defines no such
!!! function. A function body starts at the first byte of the code the generator
!!! wrote, which is never 0.
int cg_fmap_get -> str name {
    return ix_get(kIxFuncMap, name, 1);
}

bool cg_fmap_has -> str name {
    return ix_has(kIxFuncMap, name);
}

void cg_fmap_set -> str name, int off {
    ix_set(kIxFuncMap, name, off, 0, 0, 0, "");
}

!!! The first defined function of the walk over them, 0 when there is none, and
!!! the next one after `id`. The walk is in the order the bodies were emitted.
int cg_func_first {
    return ix_first(kIxFuncMap);
}

int cg_func_next -> int id {
    return ix_after(kIxFuncMap, id);
}

str cg_func_name -> int id {
    return ix_get_key(id);
}

int cg_func_off -> int id {
    return ix_get_v(id, 1);
}

!!! ---- the signature of a function ----

int cg_arity_get -> str name {
    return ix_get(kIxFuncArity, name, 1);
}

!!! Whether the arity of `name` is known at all: a function with no parameter has
!!! an arity of 0, so 0 alone does not say "unknown".
bool cg_arity_has -> str name {
    return ix_has(kIxFuncArity, name);
}

void cg_arity_set -> str name, int n {
    ix_set(kIxFuncArity, name, n, 0, 0, 0, "");
}

bool cg_variadic_get -> str name {
    return ix_get(kIxFuncVariadic, name, 1) != 0;
}

void cg_variadic_set -> str name, bool v {
    int n = 0;
    if v {
        n = 1;
    }
    ix_set(kIxFuncVariadic, name, n, 0, 0, 0, "");
}

VarType cg_retype_get -> str name {
    return cg_vt_of(ix_get(kIxFuncRetType, name, 1));
}

bool cg_retype_has -> str name {
    return ix_has(kIxFuncRetType, name);
}

void cg_retype_set -> str name, VarType t {
    ix_set(kIxFuncRetType, name, (int)t, 0, 0, 0, "");
}

str cg_ret_struct_get -> str name {
    return ix_get_s(kIxRetStruct, name, "");
}

void cg_ret_struct_set -> str name, str st {
    ix_set(kIxRetStruct, name, 0, 0, 0, 0, st);
}

!!! ---- the parameter types ----

!!! The parameter types of a function, one byte each, as text. the toolchain keeps a
!!! a chain of VarType; this implementation cannot put the chain of CmpTypeNode in the index
!!! (an entry holds numbers and one text, not a pointer), so the types are packed
!!! into the text. `cg_param_type_of` is asked for an argument at every call site,
!!! which is why this is indexed at all.
str cg_ptypes_pack -> @CmpTypeNode types, int n {
    if n <= 0 {
        return "";
    }
    @void cell;
    cg_balloc(@cell, n + 1);
    @char d = (@char)cell;
    @CmpTypeNode t = types;
    int i = 0;
    while i < n {
        if t == null {
            d[i] = (char)0;
        } else {
            d[i] = (char)((int)t.ty);
            t = t.next;
        }
        i = i + 1;
    }
    d[n] = (char)0;
    return (str)cell;
}

void cg_ptypes_set -> str name, @CmpTypeNode types, int n {
    ix_set(kIxParamTypes, name, n, 0, 0, 0, cg_ptypes_pack(types, n));
}

int cg_ptypes_count -> str name {
    return ix_get(kIxParamTypes, name, 1);
}

!!! The type of parameter `idx`, or VOID (0) past the end.
int cg_ptype_at -> str name, int idx {
    if idx < 0 || idx >= ix_get(kIxParamTypes, name, 1) {
        return 0;
    }
    str packed = ix_get_s(kIxParamTypes, name, "");
    return (int)packed[idx] & 255;
}

!!! The last parameter type, which is the element type of a variadic pack.
int cg_ptype_last -> str name {
    int n = ix_get(kIxParamTypes, name, 1);
    if n <= 0 {
        return 0;
    }
    str packed = ix_get_s(kIxParamTypes, name, "");
    return (int)packed[n - 1] & 255;
}

!!! ---- what the module declares ----

!!! Every function the module defines, known before any body is emitted, so a call
!!! to a function that is only defined further down the file can be emitted and its
!!! target patched afterwards.
bool cg_is_declared -> str name {
    return ix_has(kIxDeclared, name);
}

void cg_declare -> str name {
    ix_set(kIxDeclared, name, 1, 0, 0, 0, "");
}

bool cg_is_local -> str name {
    return ix_has(kIxLocalFunc, name);
}

void cg_mark_local -> str name {
    ix_set(kIxLocalFunc, name, 1, 0, 0, 0, "");
}

!!! ---- the DLL imports ----

!!! Whether `name` is a function a linked DLL exports. The chain of imports holds
!!! every name of every signature file - kernel32 alone declares thousands - and
!!! this question is asked at every call site, so it is answered from the index.
bool cg_dll_has -> str name {
    return ix_has(kIxDll, name);
}

void cg_dll_note -> str name {
    ix_set(kIxDll, name, 0, 0, 0, 0, "");
}

!!! The import `name` names, or null when no linked DLL exports it.
@CgDllImport cg_dll_lookup -> str name {
    if !ix_has(kIxDll, name) {
        return null;
    }
    @CgStrDllImport it = cg_strdll_find(cg_dll_imports, name);
    if it == null {
        return null;
    }
    return it.v;
}

!!! The imports in the order they were registered, which is the order their stubs
!!! are emitted in.
int cg_dll_first {
    return ix_first(kIxDll);
}

int cg_dll_next -> int id {
    return ix_after(kIxDll, id);
}

str cg_dll_name -> int id {
    return ix_get_key(id);
}
