#once
!~
 ~  bootstrap/backend/codegen_gen.b: the entry point of the code generator.
 ~
 ~  the imports every image carries, the
 ~  runtime it is linked with, the region the entry jump steps over (library code,
 ~  embedded DLLs, the conversion ring, the exception runtime, the number-to-string
 ~  routines and the import thunks), the entry-scope storage, every function body,
 ~  the entry statements and the patching of the calls that were emitted before
 ~  their target was known.
 ~!

#head "cg_heads"

!!! Every function name an expression mentions. The set is a chain that grows at
!!! its head, so the walk hands the head it built back to its caller.
!!!
!!! The chain is built in a local and not in `out`: assigning to a struct-pointer
!!! parameter is miscompiled (the store goes through the pointer instead of into
!!! the parameter slot, which faults as soon as the value is null), so every walk
!!! here reads `out` once and works on a local of its own.
@CgStrBool cg_collect_names_expr -> @CmpExpr x, @CgStrBool out {
    @CgStrBool acc = out;
    if x == null {
        return acc;
    }
    if x.nk == FUNC_CALL && !pe_eq(x.var_name, "") {
        acc = cg_set_add(acc, x.var_name);
    }
    acc = cg_collect_names_expr(x.left, acc);
    acc = cg_collect_names_expr(x.right, acc);
    @CmpExpr a = x.args;
    while a != null {
        acc = cg_collect_names_expr(a, acc);
        a = a.next;
    }
    return acc;
}

@CgStrBool cg_collect_called_names -> @CmpStmt stmts, @CgStrBool out {
    @CgStrBool acc = out;
    @CmpStmt s = stmts;
    while s != null {
        if !pe_eq(s.call_name, "") {
            acc = cg_set_add(acc, s.call_name);
        }
        if !pe_eq(s.nested_call, "") {
            acc = cg_set_add(acc, s.nested_call);
        }
        acc = cg_collect_names_expr(s.init_expr, acc);
        acc = cg_collect_names_expr(s.exit_expr, acc);
        acc = cg_collect_names_expr(s.field_target, acc);
        acc = cg_collect_names_expr(s.array_len_expr, acc);
        @CmpExpr a = s.args;
        while a != null {
            acc = cg_collect_names_expr(a, acc);
            a = a.next;
        }
        a = s.nested_args;
        while a != null {
            acc = cg_collect_names_expr(a, acc);
            a = a.next;
        }
        a = s.array_init;
        while a != null {
            acc = cg_collect_names_expr(a, acc);
            a = a.next;
        }
        a = s.case_exprs;
        while a != null {
            acc = cg_collect_names_expr(a, acc);
            a = a.next;
        }
        acc = cg_collect_called_names(s.true_body, acc);
        acc = cg_collect_called_names(s.false_body, acc);
        @CmpCaseBody cb = cs_cases_of(s);
        while cb != null {
            acc = cg_collect_called_names(cb.body, acc);
            cb = cb.next;
        }
        acc = cg_collect_called_names(s.unmatch_body, acc);
        s = s.next;
    }
    return acc;
}

!!! A TRY anywhere pulls in the exception runtime, and a RAISE needs
!!! RaiseException whether or not a TRY is around it.
void cg_scan_exc -> @CmpStmt body {
    @CmpStmt s = body;
    while s != null {
        if s.nk == TRY_CATCH {
            cg_uses_try = true;
        }
        if s.nk == RAISE {
            cg_uses_raise = true;
        }
        cg_scan_exc(s.true_body);
        cg_scan_exc(s.false_body);
        @CmpCaseBody cb = cs_cases_of(s);
        while cb != null {
            cg_scan_exc(cb.body);
            cb = cb.next;
        }
        cg_scan_exc(s.unmatch_body);
        s = s.next;
    }
}

!!! The names a function body declares, for the shadowing the resolve pass needs.
!!! The chain is built in a local, for the reason given at cg_collect_names_expr.
@CmpStrNode cg_collect_declared_names -> @CmpStmt body, @CmpStrNode out {
    @CmpStrNode acc = out;
    @CmpStmt s = body;
    while s != null {
        if s.nk == DECLARED {
            acc = cn_str(acc, s.var_name);
        }
        acc = cg_collect_declared_names(s.true_body, acc);
        acc = cg_collect_declared_names(s.false_body, acc);
        @CmpCaseBody cb = cs_cases_of(s);
        while cb != null {
            acc = cg_collect_declared_names(cb.body, acc);
            cb = cb.next;
        }
        acc = cg_collect_declared_names(s.unmatch_body, acc);
        s = s.next;
    }
    return acc;
}

!!! The bindings this block replaces are put aside: what each of its names means
!!! here, or that the name was not in the table at all (then the block's own
!!! declaration is what the table holds, and it goes away with the block). The
!!! block itself is marked on the chain, so the end of it knows where to stop.
void cg_block_enter -> @CmpStmt body {
    CgBlockShadow proto;
    @CgBlockShadow mk;
    cg_balloc(@mk, size proto);
    mk.name = "";
    mk.had = null;
    mk.present = false;
    mk.mark = true;
    mk.next = cg_block_shadows;
    cg_block_shadows = mk;
    @CmpStrNode names = cg_collect_declared_names(body, null);
    while names != null {
        @CgVarInfo cur = cg_sym_find(names.s);
        @CgBlockShadow r;
        cg_balloc(@r, size proto);
        r.name = names.s;
        r.had = null;
        if cur != null {
            r.had = cg_var_copy(cur);
        }
        r.present = cur != null;
        r.mark = false;
        r.next = cg_block_shadows;
        cg_block_shadows = r;
        names = names.next;
    }
}

void cg_block_leave {
    while cg_block_shadows != null && !cg_block_shadows.mark {
        @CgBlockShadow r = cg_block_shadows;
        cg_block_shadows = r.next;
        if r.present {
            cg_sym_set(r.name, r.had);
        } else {
            cg_sym_drop(r.name);
        }
    }
    if cg_block_shadows != null {
        cg_block_shadows = cg_block_shadows.next;
    }
}

bool cg_gen_block -> @CmpStmt body {
    cg_block_enter(body);
    bool ok = true;
    @CmpStmt ss = body;
    while ss != null {
        if !cg_gen_stmt(ss) {
            ok = false;
            skip;
        }
        ss = ss.next;
    }
    cg_block_leave();
    return ok;
}

!!! The slot a function's own locals start at: every body is numbered from this
!!! base and the counter is put back afterwards, so a frame is as wide as the body
!!! it belongs to and not as wide as every local in the program.
int kFuncLocalBase;

!!! Register the slot of one DECLARED statement. A local declared inside a function
!!! always gets its own slot (it may shadow a global of the same name); an
!!! entry-scope variable keeps the slot assigned before.
void cg_resolve_declare -> @CmpStmt s, bool shadowing {
    @CgVarInfo vi = cg_var_new();
    vi.ty = s.decl_type;
    vi.ptr_depth = s.ptr_depth;
    vi.is_array = s.is_array;
    vi.dims = s.array_dims;
    vi.struct_type = s.struct_type;
    vi.stack_offset = cg_next_stack_offset;
    if !pe_eq(s.struct_type, "") {
        @CmpStructType st = cg_find_struct(s.struct_type);
        int sz = 8;
        if st != null {
            sz = st.total_size;
        }
        if s.is_array {
            cg_next_stack_offset = cg_next_stack_offset + 8;
        } else {
            cg_next_stack_offset = cg_next_stack_offset + sz;
        }
    } else {
        if s.is_array {
            cg_next_stack_offset = cg_next_stack_offset + 8;
        } else {
            cg_next_stack_offset = cg_next_stack_offset + vt_size(s.decl_type);
        }
    }
    cg_sym_set(s.var_name, vi);
    !!! The declaration keeps its own slot: a declaration of the same name in
    !!! another block must not answer for the uses of this one.
    s.local_offset = vi.stack_offset;
    s.local_has_slot = true;
    if shadowing {
        @CgStrNameOffs lit = cg_strnameoffs_find(cg_func_local_syms, cg_pass_func);
        if lit != null {
            lit.v = cg_nameoff_add(lit.v, s.var_name, vi.stack_offset, vi);
        }
    }
}

void cg_resolve_stmts -> @CmpStmt body {
    @CmpStmt s = body;
    while s != null {
        if s.nk == DECLARED {
            if !cg_resolve_types(s.init_expr) {
                end;
            }
            @CmpExpr e = s.array_init;
            while e != null {
                if !cg_resolve_types(e) {
                    end;
                }
                e = e.next;
            }
            bool shadowing = !pe_eq(cg_pass_func, "");
            if cg_sym_find(s.var_name) == null || shadowing {
                cg_resolve_declare(s, shadowing);
            }
            s = s.next;
            continue;
        }
        if s.nk == CAST_STMT {
            if !cg_resolve_types(s.init_expr) {
                end;
            }
        }
        if s.nk == CALL {
            @CmpExpr a = s.args;
            while a != null {
                cg_resolve_types(a);
                a = a.next;
            }
            a = s.nested_args;
            while a != null {
                cg_resolve_types(a);
                a = a.next;
            }
        }
        if s.nk == ICALL_STMT {
            cg_resolve_types(s.init_expr);
            @CmpExpr a = s.args;
            while a != null {
                cg_resolve_types(a);
                a = a.next;
            }
        }
        if s.nk == BSPREAD {
            cg_resolve_types(s.init_expr);
        }
        if s.nk == EXIT {
            if !cg_resolve_types(s.exit_expr) {
                end;
            }
        }
        if s.nk == IF_ELSE {
            if !cg_resolve_types(s.init_expr) {
                end;
            }
            cg_block_enter(s.true_body);
            cg_resolve_stmts(s.true_body);
            cg_block_leave();
            cg_block_enter(s.false_body);
            cg_resolve_stmts(s.false_body);
            cg_block_leave();
        }
        if s.nk == REPEAT {
            if !cg_resolve_types(s.init_expr) {
                end;
            }
            cg_block_enter(s.true_body);
            cg_resolve_stmts(s.true_body);
            cg_block_leave();
        }
        if s.nk == FOR || s.nk == DO_WHILE {
            if s.init_expr != null && !cg_resolve_types(s.init_expr) {
                end;
            }
            cg_block_enter(s.true_body);
            cg_resolve_stmts(s.true_body);
            cg_block_leave();
            cg_block_enter(s.false_body);
            cg_resolve_stmts(s.false_body);
            cg_block_leave();
        }
        if s.nk == SWITCH {
            if !cg_resolve_types(s.init_expr) {
                end;
            }
            @CmpExpr ce = s.case_exprs;
            while ce != null {
                if !cg_resolve_types(ce) {
                    end;
                }
                ce = ce.next;
            }
            @CmpCaseBody cb = cs_cases_of(s);
            while cb != null {
                cg_block_enter(cb.body);
                cg_resolve_stmts(cb.body);
                cg_block_leave();
                cb = cb.next;
            }
            cg_block_enter(s.unmatch_body);
            cg_resolve_stmts(s.unmatch_body);
            cg_block_leave();
        }
        if s.nk == RAISE {
            if !cg_resolve_types(s.init_expr) {
                end;
            }
        }
        if s.nk == TRY_CATCH {
            !!! `CATCH name` declares the variable that receives the exception code.
            if !pe_eq(s.var_name, "") && cg_sym_find(s.var_name) == null {
                @CgVarInfo vi = cg_var_new();
                vi.ty = INT;
                vi.stack_offset = cg_next_stack_offset;
                cg_next_stack_offset = cg_next_stack_offset + vt_size(INT);
                cg_sym_set(s.var_name, vi);
                if !pe_eq(cg_pass_func, "") {
                    @CgStrNameOffs lit = cg_strnameoffs_find(cg_func_local_syms, cg_pass_func);
                    if lit != null {
                        lit.v = cg_nameoff_add(lit.v, s.var_name, vi.stack_offset, vi);
                    }
                }
            }
            cg_block_enter(s.true_body);
            cg_resolve_stmts(s.true_body);
            cg_block_leave();
            cg_block_enter(s.false_body);
            cg_resolve_stmts(s.false_body);
            cg_block_leave();
        }
        if s.nk == FUNC_STMT {
            !!! The parameters and locals of this function shadow globals of the same
            !!! name, so what they replace is saved and put back afterwards.
            @CmpStrNode shadowed = cg_collect_declared_names(s.true_body, null);
            @CmpStrNode pn = s.fparams;
            while pn != null {
                shadowed = cn_str(shadowed, pn.s);
                pn = pn.next;
            }
            @CgStrVar saved = null;
            @CmpStrNode nm = shadowed;
            while nm != null {
                @CgVarInfo pit = cg_sym_find(nm.s);
                if pit != null {
                    saved = cg_strvar_set(saved, nm.s, cg_var_copy(pit));
                }
                nm = nm.next;
            }
            !!! The parameters, for the type resolution of the body.
            int pi = 0;
            @CmpStrNode fp = s.fparams;
            @CmpTypeNode ft = s.fparam_types;
            @CmpBoolNode fa = s.fparam_is_array;
            while fp != null {
                @CgVarInfo vi = cg_var_new();
                if ft != null {
                    vi.ty = ft.ty;
                }
                vi.is_array = fa != null && fa.v;
                vi.stack_offset = 16 + pi * 8;
                cg_sym_set(fp.s, vi);
                fp = fp.next;
                if ft != null {
                    ft = ft.next;
                }
                if fa != null {
                    fa = fa.next;
                }
                pi = pi + 1;
            }
            !!! The locals of this body are numbered from a base of their own, and the
            !!! counter keeps the widest body seen rather than the sum of all of them:
            !!! one counter shared by all functions made every frame as wide as the
            !!! whole program's locals.
            int saved_scope_offset = cg_next_stack_offset;
            cg_next_stack_offset = kFuncLocalBase;
            cg_func_local_syms = cg_strnameoffs_set(kIxFnLocalSyms, cg_func_local_syms,
                                                    s.var_name, null);
            str saved_pass_func = cg_pass_func;
            cg_pass_func = s.var_name;
            cg_resolve_stmts(s.true_body);
            cg_pass_func = saved_pass_func;
            if cg_next_stack_offset < saved_scope_offset {
                cg_next_stack_offset = saved_scope_offset;
            }
            nm = shadowed;
            while nm != null {
                @CgStrVar sit = cg_strvar_find(saved, nm.s);
                if sit != null {
                    cg_sym_set(nm.s, sit.v);
                } else {
                    cg_sym_drop(nm.s);
                }
                nm = nm.next;
            }
        }
        if s.nk == RET {
            if !cg_resolve_types(s.init_expr) {
                end;
            }
        }
        s = s.next;
    }
}

!!! The closure return types: a `func` variable is called indirectly, and the
!!! result of a FLOAT closure lives in xmm0. The .r has no return type for the
!!! variable, so it comes from the hidden function its `(CLOSURE f)` names.
void cg_record_closure_rets -> @CmpStmt body {
    @CmpStmt s = body;
    while s != null {
        if s.nk == DECLARED && s.init_expr != null && s.init_expr.nk == CLOSURE &&
           !pe_eq(s.init_expr.var_name, "") &&
           !cg_retype_has(s.var_name) {
            if cg_retype_has(s.init_expr.var_name) {
                cg_retype_set(s.var_name, cg_retype_get(s.init_expr.var_name));
            }
        }
        cg_record_closure_rets(s.true_body);
        cg_record_closure_rets(s.false_body);
        @CmpCaseBody cb = cs_cases_of(s);
        while cb != null {
            cg_record_closure_rets(cb.body);
            cb = cb.next;
        }
        cg_record_closure_rets(s.unmatch_body);
        s = s.next;
    }
}

bool cg_generate -> @CmpStmt stmts {
    kFuncLocalBase = 0x20;
    cg_scan_exc(stmts);

    !!! The imports every image carries: kernel32 and the runtime's own calls. Only
    !!! the ones whose index a later lookup reads are kept in a global.
    pw_add_import("kernel32.dll", "GetStdHandle");
    pw_add_import("kernel32.dll", "WriteFile");
    cg_idx_exitprocess = pw_add_import("kernel32.dll", "ExitProcess");
    cg_idx_virtualalloc = pw_add_import("kernel32.dll", "VirtualAlloc");
    cg_idx_virtualfree = pw_add_import("kernel32.dll", "VirtualFree");
    pw_add_import("kernel32.dll", "GetProcessHeap");
    pw_add_import("kernel32.dll", "HeapAlloc");
    pw_add_import("kernel32.dll", "HeapFree");
    pw_add_import("kernel32.dll", "SetConsoleCP");
    pw_add_import("kernel32.dll", "SetConsoleOutputCP");
    pw_add_import("kernel32.dll", "ReadFile");
    pw_add_import("kernel32.dll", "CreateFileA");
    pw_add_import("kernel32.dll", "SetFilePointer");
    if cg_uses_try {
        cg_idx_addveh = pw_add_import("kernel32.dll", "AddVectoredExceptionHandler");
    }
    if cg_uses_raise {
        cg_idx_raiseexception = pw_add_import("kernel32.dll", "RaiseException");
    }

    !!! The runtime: libbrtm.dll by default, placed into the image with -static.
    if !cg_no_runtime {
        if cg_static_runtime && !cg_load_embedded_dll("libbrtm.dll") {
            cg_stmt_err = cg_err_at(0, 0, "cannot embed libbrtm.dll");
            return false;
        }
        @CgBmetaFunc bfs = cg_read_bmeta("libbrtm.dll");
        if bfs == null {
            cg_stmt_err = cg_err_at(0, 0, "cannot read meta/libbrtm.dll.bmeta");
            return false;
        }
        @CgBmetaFunc bf = bfs;
        while bf != null {
            cg_register_dll_import("libbrtm.dll", bf.name, bf.param_types, bf.ret_type);
            bf = bf.next;
        }
    }
    if !pe_eq(cg_user_libs, "") {
        int p = 0;
        int n = pe_len(cg_user_libs);
        while p < n {
            while p < n && cg_user_libs[p] == ' ' {
                p = p + 1;
            }
            if p >= n {
                skip;
            }
            int start = p;
            while p < n && cg_user_libs[p] != ' ' {
                p = p + 1;
            }
            str lname = pe_sub(cg_user_libs, start, p - start);
            if !cg_load_blib(lname) {
                cg_stmt_err = cg_err_at(0, 0, "cannot load lib/" + lname + ".lib");
                return false;
            }
        }
    }
    !!! Every native function the loaded libraries call, keyed "dll!func", so
    !!! cg_patch_blib_imports can resolve any of them.
    @CgBlib lib = cg_blibs;
    while lib != null {
        @CgBlibImport imp = lib.imports;
        while imp != null {
            str key = imp.dll + "!" + imp.fnc;
            if cg_strint_find(cg_blib_import_idx, key) == null {
                cg_blib_import_idx = cg_strint_set(cg_blib_import_idx, key,
                                                   pw_add_import(imp.dll, imp.fnc));
            }
            imp = imp.next;
        }
        lib = lib.next;
    }

    !!! The region the entry jump steps over: library code, the code of every
    !!! embedded DLL, the conversion ring, the exception runtime and the
    !!! number-to-string routines.
    int jmp_over = em_jmp_rel32();
    cg_blib_text_off_list = null;
    lib = cg_blibs;
    while lib != null {
        cg_blib_text_off_list = cn_int(cg_blib_text_off_list, em_tell());
        @char cd = lib.code.data;
        int ci = 0;
        while ci < lib.code.len {
            em_db((int)cd[ci]);
            ci = ci + 1;
        }
        lib = lib.next;
    }
    @CgEmbeddedDll ed = cg_embedded;
    while ed != null {
        ed.text_off = em_tell();        @char ec = ed.code.data;
        int ei = 0;
        while ei < ed.code.len {
            em_db((int)ec[ei]);
            ei = ei + 1;
        }
        if ed.rdata.len > 0 {
            ed.rdata_off = pw_add_bytes_off(ed.rdata.data, ed.rdata.len);
        }
        ed = ed.next;
    }
    !!! The symbols of every linked library, with the offsets their code ended up
    !!! at: from here on a name is one probe of the index instead of a walk.
    cg_index_lib_syms();

    cg_tostr_buf_off = em_tell();
    cg_tostr_idx_off = cg_tostr_buf_off + kTostrSlots * 32;
    int zi = 0;
    while zi < kTostrSlots * 32 + 4 {
        em_db(0x00);
        zi = zi + 1;
    }
    if cg_uses_try {
        cg_emit_try_runtime();
    }
    cg_emit_tostr_runtime();

    !!! The set of names the thunks are built for, and the return types the resolve
    !!! pass needs, are read off the whole statement chain. They are collected
    !!! before the func/main split below, because that split hangs the statements on
    !!! two chains of their own and the original one is no longer walkable.
    @CgStrBool used = null;
    used = cg_collect_called_names(stmts, used);
    !!! Names the code generator reaches for by itself, which never appear in the
    !!! source: the string join behind `+`, the string release, and the
    !!! number-to-string conversion. String indexing is not in this list while the
    !!! backend reads the byte in line; -nopt-asm puts the call back, so the thunk
    !!! has to be there for it.
    used = cg_set_add(used, "_str_concat");
    used = cg_set_add(used, "_str_free");
    used = cg_set_add(used, "itoa");
    if cg_nopt_asm {
        used = cg_set_add(used, "_str_idx");
    }

    !!! Names declared anywhere inside a function body are needed for the shadowing
    !!! of the resolve pass, so they are collected from the whole chain too.
    @CmpStmt s = stmts;
    !!! The return types have to be known before cg_resolve_types runs: it decides
    !!! where a call's result lives (rax for INT/STR, xmm0 for FLOAT). gen_func
    !!! fills them later, so register them up front from the FUNC nodes. Without
    !!! this a FLOAT result was read from rax.
    while s != null {
        if s.nk == FUNC_STMT && !pe_eq(s.var_name, "") {
            cg_retype_set(s.var_name, s.func_ret_type);
            if !pe_eq(s.ret_struct, "") {
                cg_ret_struct_set(s.var_name, s.ret_struct);
            }
            !!! The signature of every function is known up front as well: a call to a
            !!! function defined further down the file still needs its arity and
            !!! parameter types to emit the arguments correctly.
            cg_declare(s.var_name);
            cg_arity_set(s.var_name, cn_str_n(s.fparams));
            cg_variadic_set(s.var_name, s.variadic);
            cg_ptypes_set(s.var_name, s.fparam_types, cn_str_n(s.fparams));
        }
        s = s.next;
    }
    cg_record_closure_rets(stmts);

    !!! The function bodies and the entry statements, in two chains of their own.
    !!! The statements are relinked by hand rather than through cs_add: that helper
    !!! cuts the node it appends free of whatever chain it stood in (`s.next =
    !!! null`), so appending the second statement here truncated the chain being
    !!! walked and only the first two functions were ever generated.
    @CmpStmt func_stmts = null;
    @CmpStmt func_tail = null;
    @CmpStmt main_stmts = null;
    @CmpStmt main_tail = null;
    !!! A walker of its own, and started from the head again: `s` was left at the end
    !!! of the chain by the loop above, and a split that never ran left both chains
    !!! empty - the image came out with no function in it at all.
    @CmpStmt cur = stmts;
    while cur != null {
        @CmpStmt nx = cur.next;
        if cur.nk == FUNC_STMT {
            if func_stmts == null {
                func_stmts = cur;
            } else {
                func_tail.next = cur;
            }
            func_tail = cur;
        } else {
            if main_stmts == null {
                main_stmts = cur;
            } else {
                main_tail.next = cur;
            }
            main_tail = cur;
        }
        cur = nx;
    }
    if func_tail != null {
        func_tail.next = null;
    }
    if main_tail != null {
        main_tail.next = null;
    }

    !!! The thunks of the imported DLL functions, in the same region: they are only
    !!! reached by a call, and only the imports this program names get one.
    cg_emit_import_thunks(used);

    !!! The locals live at [rbp+offset+16], above the parameters: the base is sized
    !!! from the widest parameter list.
    int max_params = 0;
    s = stmts;
    while s != null {
        if s.nk == FUNC_STMT && cn_str_n(s.fparams) > max_params {
            max_params = cn_str_n(s.fparams);
        }
        s = s.next;
    }
    cg_next_stack_offset = max_params * 8;
    if cg_next_stack_offset < 0x20 {
        cg_next_stack_offset = 0x20;
    }

    !!! The entry-scope variables: every function reaches them through the image
    !!! block, so their offsets carry the kGlobalBase bias.
    int global_bytes = 0;
    s = main_stmts;
    while s != null {
        if s.nk == DECLARED {
            if cg_sym_find(s.var_name) != null {
                cg_stmt_err = cg_err_at(s.line, s.col,
                                        "symbol '" + s.var_name + "' already declared");
                return false;
            }
            @CgVarInfo vi = cg_var_new();
            vi.ty = s.decl_type;
            vi.ptr_depth = s.ptr_depth;
            vi.is_array = s.is_array;
            vi.dims = s.array_dims;
            vi.struct_type = s.struct_type;
            vi.is_global = true;
            vi.stack_offset = kGlobalBase + global_bytes;
            if !pe_eq(s.struct_type, "") {
                @CmpStructType st = cg_find_struct(s.struct_type);
                int sz = 8;
                if st != null {
                    sz = st.total_size;
                }
                !!! A heap array stores an 8-byte pointer, a struct variable its own
                !!! object.
                if s.is_array {
                    global_bytes = global_bytes + 8;
                } else {
                    global_bytes = global_bytes + sz;
                }
            } else {
                if s.is_array {
                    global_bytes = global_bytes + 8;
                } else {
                    global_bytes = global_bytes + vt_size(s.decl_type);
                }
            }
            cg_sym_set(s.var_name, vi);
            !!! The alias `::name` resolves to.
            cg_sym_set("__global_" + s.var_name, vi);
        }
        s = s.next;
    }
    if cg_next_stack_offset < global_bytes {
        cg_next_stack_offset = global_bytes;
    }

    cg_resolve_stmts(main_stmts);
    cg_resolve_stmts(func_stmts);
    if !pe_eq(cg_stmt_err, "") {
        return false;
    }

    !!! The entry-scope storage, in the image and inside the region the entry jump
    !!! steps over. The block is written here, so the number it is sized with has to
    !!! be the one the entry code will address with: it is frozen now and put back
    !!! before the entry statements are generated.
    cg_globals_off = em_tell();
    em_globals_off = cg_globals_off;
    int entry_scope_bytes = cg_next_stack_offset;
    int gsize = (entry_scope_bytes + kTempSlotBytes + 15) & (0 - 16);
    int gi = 0;
    while gi < gsize {
        em_db(0x00);
        gi = gi + 1;
    }

    s = func_stmts;
    while s != null {
        if !cg_gen_stmt(s) {
            return false;
        }
        s = s.next;
    }

    em_patch_jmp_rel32(jmp_over);

    !!! 16-byte stack alignment for the entry code.
    int total_stack = cg_next_stack_offset + kTempSlotBytes;
    int misalign = (total_stack + 8) % 16;
    if misalign != 0 {
        total_stack = total_stack + (16 - misalign);
    }
    em_sub_rsp(total_stack);
    if cg_uses_try {
        cg_emit_try_install();
    }
    !!! The entry temporaries are reached relative to the instruction that reads
    !!! them, so the same slot is the same address in every function.
    em_temp_base = 2;
    em_temp_bias = 0;
    cg_owned_strs = null;
    cg_next_stack_offset = entry_scope_bytes;
    cg_binop_nesting = 0;
    s = main_stmts;
    while s != null {
        if !cg_gen_stmt(s) {
            return false;
        }
        s = s.next;
    }

    !!! The entry point, by the type of image being built.
    str entry_name = "main";
    if cg_pe_type == 1 {
        entry_name = "DllMain";
    } else if cg_pe_type == 2 {
        entry_name = "WinMain";
    }
    if !cg_gen_func_call(entry_name, null, 0, 0) {
        return false;
    }
    cg_resolve_pending_calls();
    if cg_link_errors != null {
        str all = "";
        @CmpStrNode le = cg_link_errors;
        while le != null {
            if !pe_eq(all, "") {
                all = all + "\n";
            }
            all = all + le.s;
            le = le.next;
        }
        cg_stmt_err = all;
        return false;
    }
    if cg_pe_type == 1 {
        em_sub_rsp(0 - total_stack);
        em_ret();
    } else {
        em_db(0x89);
        em_db(0xC1);
        cg_emit_call_import(cg_idx_exitprocess);
    }
    cg_register_embedded_imports();
    return true;
}

!!! Calls written before their target was known, and the code addresses of hidden
!!! closure functions defined after the literal that points at them.
void cg_resolve_pending_calls {
    @CgPendingCall pc = cg_pending_calls;
    while pc != null {
        int off = cg_fmap_get(pc.name);
        if off != 0 {
            em_patch_call_rel32(pc.patch_pos, off);
        } else if pc.line <= 0 || pc.col <= 0 {
            cg_report_undefined_ref(pc.name);
        } else {
            cg_link_errors = cn_str(cg_link_errors,
                                    cg_err_at(pc.line, pc.col,
                                              "undefined reference to '" + pc.name + "'"));
        }
        pc = pc.next;
    }
    cg_pending_calls = null;

    @CgPendingCodeAddr pr = cg_pending_code_addrs;
    while pr != null {
        int off = cg_fmap_get(pr.name);
        if off != 0 {
            em_put32(pr.disp_pos, off - pr.instr_end);
        } else if pr.line <= 0 || pr.col <= 0 {
            cg_report_undefined_ref(pr.name);
        } else {
            cg_link_errors = cn_str(cg_link_errors,
                                    cg_err_at(pr.line, pr.col,
                                              "closure references undeclared function '" +
                                              pr.name + "'"));
        }
        pr = pr.next;
    }
    cg_pending_code_addrs = null;
}
