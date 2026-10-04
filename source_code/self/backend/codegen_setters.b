#once
!~
 ~  bootstrap/backend/codegen_setters.b: the settings of the code generator and the
 ~  import registration.
 ~
 ~  what the driver tells the generator
 ~  before it runs (-no-runtime, -static-runtime, -l, --type, -d), how the code
 ~  section is read back, and the two functions that turn a declared DLL function
 ~  into an import when the generated code first reaches it.
 ~!

#head "cg_heads"
#head "cg_tables"

void cg_set_no_runtime -> bool v {
    cg_no_runtime = v;
}

void cg_set_static_runtime -> bool v {
    cg_static_runtime = v;
}

void cg_set_user_libs -> str libs {
    if libs != null {
        cg_user_libs = libs;
    }
}

void cg_set_pe_type -> int t {
    cg_pe_type = t;
}

void cg_set_debug_info -> bool v {
    cg_debug_info = v;
}

void cg_set_struct_types -> @CmpStructType st {
    cg_struct_types = st;
}

bool cg_get_debug_info {
    return cg_debug_info;
}

@char cg_code_data {
    return em_buf.data;
}

int cg_code_size {
    return em_buf.len;
}

bool cg_is_func_local -> str name {
    return cg_is_local(name);
}

int cg_get_pe_type {
    return cg_pe_type;
}

!!! A -link / -system signature file declares every function the DLL exports. The
!!! declaration is all that is recorded here: the import itself is created by
!!! cg_import_index the first time the generated code reaches the function, so
!!! linking a signature file with a thousand names in it (kernel32, user32) does
!!! not put a thousand import descriptors into every image.
void cg_register_dll_import -> str dll, str func_name, @CmpTypeNode param_types,
                               VarType ret_type {
    CgDllImport proto;
    @CgDllImport d;
    cg_balloc(@d, size proto);
    d.dll = dll;
    d.idx = 0;
    d.param_types = param_types;
    d.ret_type = ret_type;
    d.registered = false;
    cg_dll_imports = cg_strdll_set(cg_dll_imports, func_name, d);
    !!! The index records that this name is an import at all, and the order it
    !!! appeared in: the answer to "is this call a DLL import?" is asked at every
    !!! call site, and the chain of imports holds every name of every signature
    !!! file.
    cg_dll_note(func_name);
}

int cg_import_index -> str name {
    if !cg_dll_has(name) {
        return 0;
    }
    @CgStrDllImport it = cg_strdll_find(cg_dll_imports, name);
    if it == null {
        return 0;
    }
    @CgDllImport imp = it.v;
    if !imp.registered {
        imp.idx = pw_add_import(imp.dll, name);
        imp.registered = true;
    }
    return imp.idx;
}
