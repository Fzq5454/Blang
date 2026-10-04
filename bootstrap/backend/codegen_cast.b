#once
!~
 ~  bootstrap/backend/codegen_cast.b: the CAST statement.
 ~
 ~  `CAST <target>, <value>` writes into a
 ~  field of a struct pointer, a field of a struct object, an element of an array or
 ~  a string, a whole struct (copied field by field), a func variable (with its
 ~  reference count) or a plain variable.
 ~!

#head "cg_heads"

bool cg_gen_cast -> @CmpStmt s {
    !!! A struct field through a struct pointer: `CAST (FLDP ptr off TYPE), value`.
    if s.field_target != null && s.field_target.nk == FLDP {
        !!! A field set to a constant: the address is the pointer plus the offset
        !!! and the value fits in the instruction, so no temporary is needed:
        !!! `mov qword [rax+16], 0` is `n.next = null` in one instruction where
        !!! saving the address, evaluating the value and storing it is three. The
        !!! value test reads the node kind and not cg_small_int_literal (the two front
        !!! ends spell the pointer depth of a `null` literal differently), and the
        !!! width test follows the store below, which writes four bytes for a
        !!! four-byte field and eight for everything else.
        @CmpExpr cf = s.field_target;
        int cval = 0;
        int csz = vt_size(cf.result_type);
        bool cst = false;
        if cf.result_type != FLOAT {
            if csz != 1 {
                if s.init_expr != null {
                    if s.init_expr.nk == LIT_NULL {
                        cst = true;
                        cval = 0;
                    } else if s.init_expr.nk == LIT_INT {
                        if s.init_expr.int_val >= 0 && s.init_expr.int_val <= 2147483647 {
                            cst = true;
                            cval = (int)s.init_expr.int_val;
                        }
                    }
                }
            }
        }
        if cst {
            cg_gen_expr(cf.left);
            int foff = (int)cf.int_val;
            int cmodrm = 0x00;
            if foff != 0 {
                if foff > 0 && foff < 128 {
                    cmodrm = 0x40;
                } else {
                    cmodrm = 0x80;
                }
            }
            if csz == 4 {
                em_db(0xC7);
            } else {
                em_db(0x48);
                em_db(0xC7);
            }
            em_db(cmodrm);
            if foff != 0 {
                if cmodrm == 0x40 {
                    em_db(foff);
                } else {
                    em_dd(foff);
                }
            }
            em_dd(cval);
            return true;
        }
        @CmpExpr f = s.field_target;
        cg_gen_expr(f.left);
        int foff = (int)f.int_val;
        if foff != 0 {
            if foff < 128 {
                em_db(0x48);
                em_db(0x83);
                em_db(0xC0);
                em_db(foff);
            } else {
                em_db(0x48);
                em_db(0x05);
                em_dd(foff);
            }
        }
        int ptemp = cg_next_stack_offset + cg_binop_nesting * 8;
        cg_binop_nesting = cg_binop_nesting + 1;
        em_st_rsp_rax(ptemp);
        cg_gen_expr(s.init_expr);
        em_ld_rsp_rdx(ptemp);
        bool pisf = s.init_expr != null && s.init_expr.result_type == FLOAT;
        int psz = vt_size(f.result_type);
        if pisf {
            em_db(0xF2);
            em_db(0x0F);
            em_db(0x11);
            em_db(0x02);
        } else if psz == 1 {
            em_db(0x88);
            em_db(0x02);
        } else if psz == 4 {
            em_db(0x89);
            em_db(0x02);
        } else {
            em_db(0x48);
            em_db(0x89);
            em_db(0x02);
        }
        cg_binop_nesting = cg_binop_nesting - 1;
        return true;
    }

    !!! A field of a struct object (or of an element of a struct array).
    if s.field_target != null && s.field_target.nk == FLD {
        @CmpExpr f = s.field_target;
        @CgVarInfo fit = cg_sym_find(f.var_name);
        if fit == null {
            cg_stmt_err = cg_filename + ":" + (str)s.line + ":" + (str)s.col +
                          ": error: undeclared symbol '" + f.var_name + "'";
            return false;
        }
        if f.left != null {
            !!! `arr[i].x = v`: data + index * element size + field offset.
            int total = 8;
            if !pe_eq(fit.struct_type, "") {
                @CmpStructType stt = cg_find_struct(fit.struct_type);
                if stt != null {
                    total = stt.total_size;
                }
            }
            cg_load_var(fit.stack_offset, fit.ty, fit.is_array, false);
            int atemp = cg_next_stack_offset + cg_binop_nesting * 8;
            cg_binop_nesting = cg_binop_nesting + 1;
            em_st_rsp_rax(atemp);
            cg_gen_expr(f.left);
            em_db(0x48);
            em_db(0x69);
            em_db(0xC0);
            em_dd(total);
            em_db(0x48);
            em_db(0x89);
            em_db(0xC1);
            em_ld_rsp(atemp);
            em_db(0x48);
            em_db(0x01);
            em_db(0xC8);
            int aoff = (int)f.int_val;
            if aoff != 0 {
                if aoff < 128 {
                    em_db(0x48);
                    em_db(0x83);
                    em_db(0xC0);
                    em_db(aoff);
                } else {
                    em_db(0x48);
                    em_db(0x05);
                    em_dd(aoff);
                }
            }
            cg_binop_nesting = cg_binop_nesting - 1;
        } else if fit.struct_ptr {
            cg_load_var(fit.stack_offset, fit.ty, true, false);
            int foff = (int)f.int_val;
            if foff < 128 {
                em_db(0x48);
                em_db(0x83);
                em_db(0xC0);
                em_db(foff);
            } else {
                em_db(0x48);
                em_db(0x05);
                em_dd(foff);
            }
        } else {
            cg_lea_var(fit.stack_offset + (int)f.int_val);
        }
        int temp = cg_next_stack_offset + cg_binop_nesting * 8;
        cg_binop_nesting = cg_binop_nesting + 1;
        em_st_rsp_rax(temp);
        cg_gen_expr(s.init_expr);
        em_ld_rsp_rdx(temp);
        bool isf = s.init_expr != null && s.init_expr.result_type == FLOAT;
        int sz = vt_size(f.result_type);
        if isf {
            em_db(0xF2);
            em_db(0x0F);
            em_db(0x11);
            em_db(0x02);
        } else if sz == 1 {
            em_db(0x88);
            em_db(0x02);
        } else if sz == 4 {
            em_db(0x89);
            em_db(0x02);
        } else {
            em_db(0x48);
            em_db(0x89);
            em_db(0x02);
        }
        cg_binop_nesting = cg_binop_nesting - 1;
        return true;
    }

    !!! `a = b` on a whole struct value: the bytes are copied. A `@T` variable is
    !!! an address and not the object, so `p = q` on one of those stores the
    !!! pointer: without the struct_ptr test the two ends of a parameter
    !!! assignment were copied as `sizeof(T)` bytes taken from the source *slot*,
    !!! which for a T larger than the slot ran over the caller's locals (an
    !!! ExprNode parameter is 247 bytes).
    if s.init_expr != null && !s.is_array {
        @CgVarInfo tit = cg_sym_find(s.var_name);
        if tit != null && !pe_eq(tit.struct_type, "") && !tit.struct_ptr {
            @CmpStructType st = cg_find_struct(tit.struct_type);
            int ssize = 8;
            if st != null {
                ssize = st.total_size;
            }
            cg_lea_var(tit.stack_offset);
            bool did = false;
            if s.init_expr.nk == VAR_REF {
                @CgVarInfo sit = cg_sym_find(s.init_expr.var_name);
                if sit != null {
                    em_db(0x57);
                    em_db(0x48);
                    em_db(0x89);
                    em_db(0xC7);
                    cg_lea_var(sit.stack_offset);
                    em_db(0x56);
                    em_db(0x48);
                    em_db(0x89);
                    em_db(0xC6);
                    em_db(0xB9);
                    em_dd(ssize);
                    em_db(0xFC);
                    em_db(0xF3);
                    em_db(0xA4);
                    em_db(0x5E);
                    em_db(0x5F);
                    did = true;
                }
            } else if s.init_expr.nk == FUNC_CALL {
                !!! A struct-returning call answers a heap pointer.
                int temp = cg_next_stack_offset + cg_binop_nesting * 8;
                cg_binop_nesting = cg_binop_nesting + 1;
                em_st_rsp_rax(temp);
                cg_gen_expr(s.init_expr);
                em_ld_rsp_rdx(temp);
                em_db(0x48);
                em_db(0x89);
                em_db(0xD7);
                em_db(0x48);
                em_db(0x89);
                em_db(0xC6);
                em_db(0xB9);
                em_dd(ssize);
                em_db(0xFC);
                em_db(0xF3);
                em_db(0xA4);
                cg_binop_nesting = cg_binop_nesting - 1;
                did = true;
            }
            if did {
                return true;
            }
        }
    }

    !!! A parameter is rbp-based.
    bool is_param = false;
    int rbp_off = 0;
    VarType param_type = INT;
    if !pe_eq(cg_current_func, "") {
        @CgNameOff oit = cg_param_off(cg_current_func, s.var_name);
        if oit != null {
            is_param = true;
            rbp_off = oit.off;
            param_type = cg_param_type(cg_current_func, s.var_name);
        }
    }
    if is_param && !s.is_array {
        cg_gen_expr(s.init_expr);
        if param_type == INT {
            em_st_rbp_eax(rbp_off);
        } else if param_type == CHAR || param_type == BOOL {
            em_st_rbp_al(rbp_off);
        } else {
            em_st_rbp_rax(rbp_off);
        }
        return true;
    }

    @CgVarInfo it = cg_sym_find(s.var_name);
    !!! A `@T` parameter is not in `syms`: its value is in the parameter slot, and
    !!! an indexed store through it (`buf[i] = c`) reads that slot for the base.
    bool param_indexed = it == null && is_param && s.is_array;
    if it == null && !param_indexed {
        cg_stmt_err = cg_filename + ":" + (str)s.line + ":" + (str)s.col +
                      ": error: undeclared symbol '" + s.var_name + "'";
        return false;
    }
    VarType base_type = it.ty;
    bool base_is_array = it.is_array;
    str base_struct = it.struct_type;
    int off = it.stack_offset;
    if param_indexed {
        base_type = param_type;
        base_is_array = false;
        base_struct = "";
        off = rbp_off;
    }

    !!! An element of an array or of a string.
    if s.is_array && s.init_expr != null && s.array_init != null {
        !!! An element of an array of struct values is the object itself, so the
        !!! bytes are copied: a scalar store would only write the first field.
        bool struct_elem = false;
        if !pe_eq(base_struct, "") {
            @CmpExpr first = s.array_init;
            if first.nk == VAR_REF || first.nk == FUNC_CALL {
                struct_elem = true;
            }
        }
        if struct_elem {
            @CmpStructType st = cg_find_struct(base_struct);
            int esize = 8;
            if st != null {
                esize = st.total_size;
            }
            cg_binop_nesting = cg_binop_nesting + 1;
            int etemp = cg_next_stack_offset + (cg_binop_nesting - 1) * 8;
            if param_indexed {
                em_ld_rbp(off);
            } else {
                cg_load_var(off, base_type, base_is_array, false);
            }
            em_st_rsp_rax(etemp);
            cg_gen_expr(s.init_expr);
            if esize == 16 {
                em_db(0x48);
                em_db(0xC1);
                em_db(0xE0);
                em_db(0x04);
            } else if esize == 8 {
                em_db(0x48);
                em_db(0xC1);
                em_db(0xE0);
                em_db(0x03);
            } else if esize == 4 {
                em_db(0x48);
                em_db(0xC1);
                em_db(0xE0);
                em_db(0x02);
            }
            em_db(0x48);
            em_db(0x89);
            em_db(0xC1);
            em_ld_rsp(etemp);
            em_db(0x48);
            em_db(0x01);
            em_db(0xC8);
            em_st_rsp_rax(etemp);
            bool src_ok = false;
            @CmpExpr src = s.array_init;
            if src.nk == VAR_REF {
                @CgVarInfo sit = cg_sym_find(src.var_name);
                if sit != null {
                    cg_lea_var(sit.stack_offset);
                    src_ok = true;
                }
            } else {
                cg_gen_expr(src);
                src_ok = true;
            }
            if src_ok {
                em_ld_rsp_rdx(etemp);
                em_db(0x48);
                em_db(0x89);
                em_db(0xD7);
                em_db(0x48);
                em_db(0x89);
                em_db(0xC6);
                em_db(0xB9);
                em_dd(esize);
                em_db(0xFC);
                em_db(0xF3);
                em_db(0xA4);
                cg_binop_nesting = cg_binop_nesting - 1;
                return true;
            }
            cg_binop_nesting = cg_binop_nesting - 1;
        }
        cg_binop_nesting = cg_binop_nesting + 1;
        int temp = cg_next_stack_offset + (cg_binop_nesting - 1) * 8;
        if param_indexed {
            em_ld_rbp(off);
        } else {
            cg_load_var(off, base_type, base_is_array, false);
        }
        em_st_rsp_rax(temp);
        !!! `s[i] = 'x'`: a character of a string.
        if base_type == STR && !base_is_array {
            cg_gen_expr(s.init_expr);
            em_db(0x48);
            em_db(0x89);
            em_db(0xC1);
            em_ld_rsp(temp);
            em_db(0x48);
            em_db(0x01);
            em_db(0xC8);
            em_st_rsp_rax(temp);
            cg_gen_expr(s.array_init);
            em_ld_rsp_rdx(temp);
            em_db(0x88);
            em_db(0x02);
            cg_binop_nesting = cg_binop_nesting - 1;
            return true;
        }
        cg_gen_expr(s.init_expr);
        !!! The index is scaled by the element size: a raw pointer is subscripted by
        !!! what it points at, the way the read path does it.
        int es = 8;
        if base_is_array {
            es = vt_size(base_type);
        } else if base_type == AT_CHAR || base_type == AT_BOOL {
            es = 1;
        } else if base_type == AT_INT {
            es = 4;
        }
        if es == 16 {
            em_db(0x48);
            em_db(0xC1);
            em_db(0xE0);
            em_db(0x04);
        } else if es == 8 {
            em_db(0x48);
            em_db(0xC1);
            em_db(0xE0);
            em_db(0x03);
        } else if es == 4 {
            em_db(0x48);
            em_db(0xC1);
            em_db(0xE0);
            em_db(0x02);
        }
        em_db(0x48);
        em_db(0x89);
        em_db(0xC1);
        em_ld_rsp(temp);
        em_db(0x48);
        em_db(0x01);
        em_db(0xC8);
        em_st_rsp_rax(temp);
        @CmpExpr first2 = s.array_init;
        bool is_float_val = first2.result_type == FLOAT;
        cg_gen_expr(first2);
        em_ld_rsp_rdx(temp);
        if is_float_val {
            em_db(0xF2);
            em_db(0x0F);
            em_db(0x11);
            em_db(0x02);
        } else if es == 1 {
            em_db(0x88);
            em_db(0x02);
        } else if es == 4 {
            em_db(0x89);
            em_db(0x02);
        } else {
            em_db(0x48);
            em_db(0x89);
            em_db(0x02);
        }
        cg_binop_nesting = cg_binop_nesting - 1;
        return true;
    }

    !!! `CAST arr, {a, b, c}`: a fresh block, every element stored into it.
    if s.is_array && s.array_init != null && s.init_expr == null {
        int n = ce_n(s.array_init);
        !!! The new block comes from the runtime's pool.
        cg_emit_alloc_block(n * 8);
        cg_store_var(off, it.ty, true, false);
        em_db(0x48);
        em_db(0x89);
        em_db(0xC3);
        int i = 0;
        while i < n {
            cg_gen_expr(ce_at(s.array_init, i));
            if i * 8 < 128 {
                em_db(0x48);
                em_db(0x89);
                em_db(0x43);
                em_db(i * 8);
            } else {
                em_db(0x48);
                em_db(0x89);
                em_db(0x83);
                em_dd(i * 8);
            }
            i = i + 1;
        }
        return true;
    }

    if it.ty == FUNC {
        !!! Releasing the old closure and retaining the new one keeps the refcount
        !!! right when func values alias each other.
        cg_load_var(off, it.ty, it.is_array, false);
        cg_emit_release_closure_rax();
        cg_gen_expr(s.init_expr);
        if s.init_expr != null && s.init_expr.nk == VAR_REF &&
           s.init_expr.result_type == FUNC {
            cg_emit_retain_rax();
        }
        cg_store_var(off, it.ty, it.is_array, false);
        return true;
    }

    if it.ty == STR && !it.is_array {
        !!! A string reassignment: the new text first (the right side may read the
        !!! old one), then the old heap string goes when this variable owns it, and
        !!! the ownership is recorded again.
        cg_gen_expr(s.init_expr);
        cg_binop_nesting = cg_binop_nesting + 1;
        int temp = cg_next_stack_offset + (cg_binop_nesting - 1) * 8;
        em_st_rsp_rax(temp);
        if cg_set_has(cg_owned_strs, s.var_name) {
            cg_load_var(off, STR, false, false);
            cg_emit_str_free_rax();
        }
        em_ld_rsp(temp);
        cg_store_var(off, STR, false, false);
        cg_binop_nesting = cg_binop_nesting - 1;
        if cg_produces_owned_str(s.init_expr) {
            cg_owned_strs = cg_set_add(cg_owned_strs, s.var_name);
        } else {
            cg_owned_strs = cg_set_drop(cg_owned_strs, s.var_name);
        }
        return true;
    }

    cg_gen_expr(s.init_expr);
    cg_store_var(off, it.ty, it.is_array, false);
    return true;
}
