#once
!~
 ~  bootstrap/backend/codegen_public.b: what -p prints about the module.
 ~
 ~  the verbose half of backend/codegen_public: the imports the
 ~  generated code really reached, the libraries that were linked in, and the
 ~  functions the module defines.
 ~
 ~  The names are walked in registration order and a DLL keeps the place it was
 ~  first named in, which is the order the toolchain writes them in as well: it keeps a
 ~  list of its own for the same reason. A hash order is not reproducible, so
 ~  neither compiler lets one reach the report.
 ~!

#head "cg_heads"

@CgNameStr cg_namestr_find -> @CgNameStr head, str name {
    @CgNameStr e = head;
    while e != null {
        if pe_eq(e.name, name) {
            return e;
        }
        e = e.next;
    }
    return null;
}

str cg_get_verbose_info {
    str info = "";
    !!! Imports, grouped by DLL: only the functions the generated code reached got
    !!! an import, and those are the ones the image really imports.
    @CgNameStr groups = null;
    @CgNameStr tail = null;
    int import_count = 0;
    int kid = cg_dll_first();
    while kid != 0 {
        str nm = cg_dll_name(kid);
        @CgDllImport imp = cg_dll_lookup(nm);
        if imp != null && imp.registered {
            @CgNameStr g = cg_namestr_find(groups, imp.dll);
            if g == null {
                CgNameStr proto;
                @CgNameStr n;
                cg_balloc(@n, size proto);
                n.name = imp.dll;
                n.v = nm;
                n.next = null;
                if groups == null {
                    groups = n;
                } else {
                    tail.next = n;
                }
                tail = n;
            } else {
                g.v = g.v + ", " + nm;
            }
            import_count = import_count + 1;
        }
        kid = cg_dll_next(kid);
    }
    if import_count > 0 {
        info = info + "cmp.exe: import " + (str)import_count + ": ";
        bool first_dll = true;
        @CgNameStr g2 = groups;
        while g2 != null {
            if !first_dll {
                info = info + "; ";
            }
            first_dll = false;
            info = info + g2.v + " in " + g2.name;
            g2 = g2.next;
        }
        info = info + "\n";
    }
    int lib_count = 0;
    @CmpStrNode l = cg_loaded_libs;
    while l != null {
        lib_count = lib_count + 1;
        l = l.next;
    }
    if lib_count > 0 {
        info = info + "cmp.exe: lib " + (str)lib_count + ": ";
        int i = 0;
        l = cg_loaded_libs;
        while l != null {
            if i > 0 {
                info = info + ", ";
            }
            info = info + l.s + ".lib";
            i = i + 1;
            l = l.next;
        }
        info = info + "\n";
    }
    !!! The functions the module defines, which are the ones no library provides.
    int func_count = 0;
    int fid = cg_func_first();
    while fid != 0 {
        if cg_resolve_sym(cg_func_name(fid)) == 0 {
            func_count = func_count + 1;
        }
        fid = cg_func_next(fid);
    }
    if func_count > 0 {
        info = info + "cmp.exe: function " + (str)func_count + ": ";
        bool first = true;
        fid = cg_func_first();
        while fid != 0 {
            str fname = cg_func_name(fid);
            if cg_resolve_sym(fname) == 0 {
                if !first {
                    info = info + ", ";
                }
                first = false;
                info = info + fname;
            }
            fid = cg_func_next(fid);
        }
        info = info + "\n";
    }
    return info;
}
