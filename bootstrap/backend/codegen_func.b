#once
!~
 ~  bootstrap/backend/codegen_func.b: the FUNC statement.
 ~
 ~  the prologue (saved rbp and callee-saved
 ~  registers, the frame with its temporary allowance and the 16-byte alignment the
 ~  ABI wants), the parameter slots, the copy of every struct parameter into a local
 ~  of the callee, the locals shadowing the globals while the body runs, and the
 ~  epilogue when the body did not end in a return of its own.
 ~!

#head "cg_heads"

bool cg_gen_func -> @CmpStmt s {
    !!! The string ownership of a body is its own.
    cg_owned_strs = null;
    !!! The temporary-slot counter belongs to the body being emitted. It was only
    !!! ever saved and restored in the toolchain, never cleared, so it kept the depth the
    !!! previous function ended with and grew with every statement of the program;
    !!! past the frame's allowance the temporaries are written into the caller's
    !!! frame, which is a silent corruption.
    cg_binop_nesting = 0;
    int saved_try_depth = cg_try_depth;
    cg_try_depth = 0;

    int off = em_tell();
    cg_fmap_set(s.var_name, off);
    cg_arity_set(s.var_name, cn_str_n(s.fparams));
    cg_variadic_set(s.var_name, s.variadic);
    cg_ptypes_set(s.var_name, s.fparam_types, cn_str_n(s.fparams));
    cg_retype_set(s.var_name, s.func_ret_type);
    if s.is_local {
        cg_mark_local(s.var_name);
    }
    cg_sig_add(s.var_name, s.func_ret_type, s.fparam_types, s.fparams, s.is_local,
               s.variadic);

    !!! The locals of the body so far, for the debugger information. The list is
    !!! only ever read by the debug block, which is written when -d was given, so
    !!! it is only built then: walking the whole symbol table for every function
    !!! and making a pair for each of its names is work a normal compile does not
    !!! want.
    @CgNameOff vars = null;
    if cg_debug_info {
        int si = 0;
        while si < cg_sym_slots.len {
            @CgSymSlot slot = cg_sym_slot(si + 1);
            if !slot.dead {
                vars = cg_nameoff_push(vars, slot.key, slot.v.stack_offset, slot.v);
            }
            si = si + 1;
        }
    }
    cg_func_vars = cg_strnameoffs_set(kIxFnVars, cg_func_vars, s.var_name, vars);

    cg_ret_struct_set(s.var_name, s.ret_struct);
    cg_func_param_struct_names = cg_strnamestrs_set(kIxFnParamStruct,
                                                    cg_func_param_struct_names,
                                                    s.var_name, null);

    !!! A local copy slot for every struct parameter: the callee copies the
    !!! caller's struct into its own frame. The offset is reserved before the frame
    !!! size is computed below.
    int nparams = cn_str_n(s.fparams);
    @CmpIntNode param_copy_off = null;
    int pi = 0;
    while pi < nparams {
        param_copy_off = cn_int(param_copy_off, -1);
        pi = pi + 1;
    }
    @CgNameStr pstruct_map = null;
    @CmpStrNode sn = s.fparam_struct;
    pi = 0;
    while sn != null && pi < nparams {
        if !pe_eq(sn.s, "") {
            bool is_ptr = false;
            @CmpBoolNode pb = s.fparam_struct_ptr;
            int k = 0;
            while pb != null {
                if k == pi {
                    is_ptr = pb.v;
                }
                pb = pb.next;
                k = k + 1;
            }
            if !is_ptr {
                @CmpStructType st = cg_find_struct(sn.s);
                int S = 8;
                if st != null {
                    S = st.total_size;
                }
                @CmpStrNode pn = s.fparams;
                int j = 0;
                while pn != null && j < pi {
                    pn = pn.next;
                    j = j + 1;
                }
                if pn != null {
                    pstruct_map = cg_namestr_add(pstruct_map, pn.s, sn.s);
                }
                cn_int_set(param_copy_off, pi, cg_next_stack_offset);
                cg_next_stack_offset = cg_next_stack_offset + S;
            }
        }
        sn = sn.next;
        pi = pi + 1;
    }
    cg_func_param_struct_names = cg_strnamestrs_set(kIxFnParamStruct,
                                                    cg_func_param_struct_names,
                                                    s.var_name, pstruct_map);

    !!! The prologue.
    em_push_rbp();
    em_mov_rbp_rsp();
    em_db(0x53);
    em_db(0x56);
    em_db(0x57);
    !!! push rbp + rbx/rsi/rdi is 32 bytes, a multiple of 16, so the frame itself
    !!! has to be 8 mod 16: the body then keeps rsp 16-byte aligned, as the Windows
    !!! x64 ABI requires at every call site.
    int frame = ((cg_next_stack_offset + kTempSlotBytes + 15) & (0 - 16)) + 8;
    if frame < 0x88 {
        frame = 0x88;
    }
    em_sub_rsp(frame);
    !!! A caller that pushed an odd number of argument slots leaves the stack 8
    !!! bytes out of line, so align here: the exception dispatcher builds a CONTEXT
    !!! with an aligned store, and ntdll faults on a misaligned one.
    em_db(0x48);
    em_db(0x83);
    em_db(0xE4);
    em_db(0xF0);

    !!! Locals and struct-parameter copies belong to this frame, below the temporary
    !!! slots. A slot `k` is addressed as [rbp + 16 + off], so the bias puts it at
    !!! [rsp + k]; allocating them at the positive counter value put them above rbp,
    !!! which is the caller's frame.
    int local_bias = 0 - (40 + frame);
    int saved_local_bias = cg_local_bias;
    cg_local_bias = local_bias;
    @CgStrNameOffs lit_locals = cg_strnameoffs_find(cg_func_local_syms, s.var_name);
    if lit_locals != null {
        @CgNameOff lv = lit_locals.v;
        while lv != null {
            lv.off = lv.off + local_bias;
            !!! The variable record itself carries the offset the body addresses the
            !!! slot with, and it is the one installed into the symbol table below.
            !!! the toolchain keeps one `VarInfo` per local, so biasing it there biases
            !!! what the body reads; this implementation keeps the offset twice (beside the
            !!! record and inside it), so the record has to move with it. Without
            !!! this every local of every function was addressed above rbp - in the
            !!! caller's frame - instead of below it in its own.
            if lv.info != null {
                lv.info.stack_offset = lv.info.stack_offset + local_bias;
            }
            lv = lv.next;
        }
    }
    !!! The temporaries of this body live in its own frame, above the locals.
    int saved_temp_base = em_temp_base;
    int saved_temp_bias = em_temp_bias;
    em_temp_base = 1;
    em_temp_bias = 0 - (24 + frame);

    !!! The register parameters into their shadow space. Only as many as there are
    !!! parameters: saving more would overwrite the caller's stack slots above the
    !!! pushed arguments.
    if nparams >= 1 {
        em_mov_mem_rbp_disp8_rcx(0x10);
    }
    if nparams >= 2 {
        em_mov_mem_rbp_disp8_rdx(0x18);
    }
    if nparams >= 3 {
        em_mov_mem_rbp_disp8_r8(0x20);
    }
    if nparams >= 4 {
        em_mov_mem_rbp_disp8_r9(0x28);
    }

    !!! [rbp+0] is the saved rbp, [rbp+8] the return address and [rbp+16] the first
    !!! argument.
    @CgNameOff params = null;
    @CgNameType param_types = null;
    @CmpIntNode param_offs = null;
    int qi = 0;
    @CmpStrNode qn = s.fparams;
    @CmpStrNode qs = s.fparam_struct;
    @CmpTypeNode qt = s.fparam_types;
    while qn != null && qi < nparams {
        bool is_struct = qs != null && !pe_eq(qs.s, "");
        if !is_struct {
            params = cg_nameoff_push(params, qn.s, 16 + qi * 8, null);
        }
        if qt != null {
            param_types = cg_nametype_set(param_types, qn.s, qt.ty);
        }
        param_offs = cn_int(param_offs, 16 + qi * 8);
        qn = qn.next;
        if qs != null {
            qs = qs.next;
        }
        if qt != null {
            qt = qt.next;
        }
        qi = qi + 1;
    }
    cg_func_params = cg_strnameoffs_set(kIxFnParams, cg_func_params, s.var_name, params);
    cg_func_param_types = cg_strnametypes_set(kIxFnParamTypes, cg_func_param_types,
                                              s.var_name, param_types);
    cg_func_param_offsets = cg_strints_set(kIxFnParamOffsets, cg_func_param_offsets,
                                           s.var_name, param_offs);

    str saved_func = cg_current_func;
    cg_current_func = s.var_name;

    !!! The struct parameters into their reserved local slots: the incoming slot
    !!! holds a pointer to the caller's struct.
    int ri = 0;
    @CmpStrNode rs = s.fparam_struct;
    while rs != null && ri < nparams {
        if cn_int_at(param_copy_off, ri) >= 0 && !pe_eq(rs.s, "") {
            @CmpStructType st = cg_find_struct(rs.s);
            int S = 8;
            if st != null {
                S = st.total_size;
            }
            em_lea_rbp((int)cn_int_at(param_copy_off, ri) + 16 + local_bias);
            em_db(0x57);
            em_db(0x48);
            em_db(0x89);
            em_db(0xC7);
            em_ld_rbp(16 + ri * 8);
            em_db(0x56);
            em_db(0x48);
            em_db(0x89);
            em_db(0xC6);
            em_db(0xB9);
            em_dd(S);
            em_db(0xFC);
            em_db(0xF3);
            em_db(0xA4);
            em_db(0x5E);
            em_db(0x5F);
        }
        rs = rs.next;
        ri = ri + 1;
    }

    !!! Registering the parameters below shadows a same-named local or global, and
    !!! what stood there is restored after the body.
    @CgStrVar saved_param_syms = null;
    @CmpStrNode saved_param_names = null;
    @CmpStrNode wn = s.fparams;
    while wn != null {
        saved_param_names = cn_str(saved_param_names, wn.s);
        @CgVarInfo pit = cg_sym_find(wn.s);
        if pit != null {
            saved_param_syms = cg_strvar_set(saved_param_syms, wn.s,
                                             cg_var_copy(pit));
        }
        wn = wn.next;
    }
    !!! The locals of this function get their own slots; the resolve pass recorded
    !!! them. The parameters are installed after them, so a parameter of the same
    !!! name wins.
    @CgStrVar saved_local_syms = null;
    @CmpStrNode saved_local_names = null;
    if lit_locals != null {
        @CgNameOff lv = lit_locals.v;
        while lv != null {
            !!! The *first* declaration of a name is the one in effect at the top of
            !!! the body. A name declared again in an inner block is installed by its
            !!! own DECLARED statement (cg_gen_declared) and the binding it replaced
            !!! comes back when that block ends, so this entry has to be the outer
            !!! one: with the last declaration here the code after a shadowing block
            !!! read the inner variable.
            bool saw_name = false;
            @CmpStrNode scn = saved_local_names;
            while scn != null {
                if pe_eq(scn.s, lv.name) {
                    saw_name = true;
                }
                scn = scn.next;
            }
            if !saw_name {
                saved_local_names = cn_str(saved_local_names, lv.name);
                @CgVarInfo pit = cg_sym_find(lv.name);
                if pit != null {
                    saved_local_syms = cg_strvar_set(saved_local_syms, lv.name,
                                                     cg_var_copy(pit));
                }
                cg_sym_set(lv.name, lv.info);
            }
            lv = lv.next;
        }
    }
    !!! The array parameters, so the subscript knows them. The offsets are 0-based:
    !!! the loader adds the 16 the rbp-based form wants.
    int ai = 0;
    @CmpStrNode apn = s.fparams;
    @CmpBoolNode ab = s.fparam_is_array;
    @CmpTypeNode apt = s.fparam_types;
    while apn != null && ai < nparams {
        if ab != null && ab.v {
            @CgVarInfo vi = cg_var_new();
            if apt != null {
                vi.ty = apt.ty;
            }
            vi.is_array = true;
            vi.stack_offset = ai * 8;
            cg_sym_set(apn.s, vi);
        }
        apn = apn.next;
        if ab != null {
            ab = ab.next;
        }
        if apt != null {
            apt = apt.next;
        }
        ai = ai + 1;
    }
    !!! The struct parameters point at their copy.
    int si = 0;
    @CmpStrNode spn = s.fparams;
    @CmpStrNode ssn = s.fparam_struct;
    while spn != null && ssn != null && si < nparams {
        if cn_int_at(param_copy_off, si) >= 0 && !pe_eq(ssn.s, "") {
            @CgVarInfo vi = cg_var_new();
            vi.ty = INT;
            vi.struct_type = ssn.s;
            vi.stack_offset = (int)cn_int_at(param_copy_off, si) + local_bias;
            cg_sym_set(spn.s, vi);
        }
        spn = spn.next;
        ssn = ssn.next;
        si = si + 1;
    }
    !!! The struct-pointer parameters (a method's `this`): the incoming slot holds
    !!! the pointer itself and the field access goes through it.
    int ti = 0;
    @CmpStrNode tpn = s.fparams;
    @CmpStrNode tsn = s.fparam_struct;
    @CmpBoolNode tpb = s.fparam_struct_ptr;
    while tpn != null && ti < nparams {
        if tpb != null && tpb.v {
            @CgVarInfo vi = cg_var_new();
            vi.ty = AT_INT;
            if tsn != null {
                vi.struct_type = tsn.s;
            }
            vi.struct_ptr = true;
            vi.stack_offset = ti * 8;
            cg_sym_set(tpn.s, vi);
        }
        tpn = tpn.next;
        if tsn != null {
            tsn = tsn.next;
        }
        if tpb != null {
            tpb = tpb.next;
        }
        ti = ti + 1;
    }

    @CmpStmt ss = s.true_body;
    while ss != null {
        if !cg_gen_stmt(ss) {
            em_temp_base = saved_temp_base;
            em_temp_bias = saved_temp_bias;
            cg_current_func = saved_func;
            cg_try_depth = saved_try_depth;
            cg_local_bias = saved_local_bias;
            return false;
        }
        ss = ss.next;
    }

    !!! Put back what the parameters shadowed, and then what the locals did.
    !!! Two names of their own for the two walks: a name declared twice in one body
    !!! keeps one type, and `pit` above is an entry of the symbol table.
    @CmpStrNode nm = saved_param_names;
    while nm != null {
        @CgStrVar prev = cg_strvar_find(saved_param_syms, nm.s);
        if prev != null {
            cg_sym_set(nm.s, prev.v);
        } else {
            cg_sym_drop(nm.s);
        }
        nm = nm.next;
    }
    nm = saved_local_names;
    while nm != null {
        @CgStrVar prior = cg_strvar_find(saved_local_syms, nm.s);
        if prior != null {
            cg_sym_set(nm.s, prior.v);
        } else {
            cg_sym_drop(nm.s);
        }
        nm = nm.next;
    }

    cg_current_func = saved_func;
    em_temp_base = saved_temp_base;
    em_temp_bias = saved_temp_bias;
    cg_try_depth = saved_try_depth;
    cg_local_bias = saved_local_bias;

    !!! The epilogue only when the body did not end in a return of its own.
    bool ends_with_ret = false;
    if s.true_body != null {
        @CmpStmt last = cs_at(s.true_body, cs_n(s.true_body) - 1);
        if last != null && last.nk == RET {
            ends_with_ret = true;
        }
    }
    if !ends_with_ret {
        em_db(0x48);
        em_db(0x89);
        em_db(0xEC);
        em_db(0x48);
        em_db(0x83);
        em_db(0xEC);
        em_db(0x18);
        em_db(0x5F);
        em_db(0x5E);
        em_db(0x5B);
        em_db(0x5D);
        em_ret();
    }
    return true;
}
