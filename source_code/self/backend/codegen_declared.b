#once
!~
 ~  bootstrap/backend/codegen_declared.b: the DECLARED statement.
 ~
 ~  It is three declarations in one: an
 ~  array of structs (a heap block of elements, each one's fields written in turn),
 ~  a plain array (a heap block with a 16-byte header: capacity, element size and
 ~  count, with the data pointer the variable holds pointing past it), and a struct
 ~  object, whose fields are written at their offsets inside the object itself.
 ~!

#head "cg_heads"

bool cg_gen_declared -> @CmpStmt s {
    !!! The slot and the type of *this* declaration. The same name may be
    !!! declared twice in one function (an inner block shadowing an outer
    !!! variable) and each declaration has a slot of its own; looking the name up
    !!! in the one table keyed by name answered the other declaration's slot and
    !!! type, so a `str` local next to an `int` of the same name was stored and
    !!! read as four bytes and its pointer lost the top half. The resolve pass
    !!! recorded this declaration's slot on the statement, and the binding is
    !!! installed here so the uses that follow in this block see it.
    @CgVarInfo vi = null;
    if s.local_has_slot {
        vi = cg_var_new();
        vi.ty = s.decl_type;
        vi.ptr_depth = s.ptr_depth;
        vi.is_array = s.is_array;
        vi.dims = s.array_dims;
        vi.struct_type = s.struct_type;
        vi.stack_offset = s.local_offset + cg_local_bias;
        cg_sym_set(s.var_name, vi);
    } else {
        !!! A variable of the entry scope keeps the slot the resolve pass gave it
        !!! before the body, which carries the entry frame's bias.
        vi = cg_sym_find(s.var_name);
        if vi == null {
            vi = cg_var_new();
            vi.ty = s.decl_type;
            vi.ptr_depth = s.ptr_depth;
            vi.is_array = s.is_array;
            vi.dims = s.array_dims;
            vi.struct_type = s.struct_type;
            vi.stack_offset = 0;
            cg_sym_set(s.var_name, vi);
        }
    }
    int off = vi.stack_offset;

    !!! A struct array: one heap block of `total_elems` elements, with the same
    !!! 16-byte header, and every field of every element written.
    if s.is_array && !pe_eq(vi.struct_type, "") {
        @CmpStructType st = cg_find_struct(vi.struct_type);
        if st == null {
            cg_stmt_err = cg_err_at(s.line, s.col,
                                    "unknown struct type '" + vi.struct_type + "'");
            return false;
        }
        int nf = cf_count(st.fields);
        longlong total_elems = 0;
        if s.array_dims != null && s.array_dims.v > 0 {
            total_elems = s.array_dims.v;
        } else {
            if nf > 0 {
                total_elems = ce_n(s.array_init) / nf;
            }
        }
        longlong es = st.total_size;
        em_mov_rax_imm64(total_elems);
        em_db(0x48);
        em_db(0xC7);
        em_db(0xC2);
        em_dd((int)es);
        em_db(0x48);
        em_db(0x0F);
        em_db(0xAF);
        em_db(0xC2);
        em_db(0x48);
        em_db(0x83);
        em_db(0xC0);
        em_db(0x10);
        !!! The element block comes from the runtime's pool.
        cg_emit_alloc_rax();
        em_db(0xC7);
        em_db(0x00);
        em_dd((int)total_elems);
        em_db(0xC7);
        em_db(0x40);
        em_db(0x04);
        em_dd((int)es);
        em_db(0x48);
        em_db(0xC7);
        em_db(0x40);
        em_db(0x08);
        em_dd((int)total_elems);
        em_db(0x48);
        em_db(0x83);
        em_db(0xC0);
        em_db(0x10);
        cg_store_var(off, vi.ty, vi.is_array, false);
        !!! Every element's fields, at their offsets. The data pointer is reloaded
        !!! from the variable slot each time, because the value expression may use
        !!! the scratch registers.
        longlong i = 0;
        while i < total_elems {
            int fi = 0;
            while fi < nf {
                longlong idx = i * nf + fi;
                if idx >= ce_n(s.array_init) {
                    skip;
                }
                @CmpFieldInfo f = cf_at(st.fields, fi);
                longlong fieldoff = i * es + f.off;
                cg_load_var(off, vi.ty, vi.is_array, false);
                em_db(0x48);
                em_db(0x05);
                em_dd((int)fieldoff);
                int temp = cg_next_stack_offset + cg_binop_nesting * 8;
                cg_binop_nesting = cg_binop_nesting + 1;
                em_st_rsp_rax(temp);
                @CmpExpr val = ce_at(s.array_init, (int)idx);
                cg_gen_expr(val);
                bool isf = val.result_type == FLOAT;
                em_ld_rsp_rdx(temp);
                if isf {
                    em_db(0xF2);
                    em_db(0x0F);
                    em_db(0x11);
                    em_db(0x02);
                } else if f.sz == 1 {
                    em_db(0x88);
                    em_db(0x02);
                } else if f.sz == 4 {
                    em_db(0x89);
                    em_db(0x02);
                } else {
                    em_db(0x48);
                    em_db(0x89);
                    em_db(0x02);
                }
                cg_binop_nesting = cg_binop_nesting - 1;
                fi = fi + 1;
            }
            i = i + 1;
        }
        return true;
    }

    if s.is_array {
        int init_count = ce_n(s.array_init);
        longlong total_elements = init_count;
        if s.array_dims != null && s.array_dims.v > 0 {
            total_elements = 1;
            @CmpIntNode d = s.array_dims;
            while d != null {
                total_elements = total_elements * d.v;
                d = d.next;
            }
        }
        longlong elem_size = vt_size(vi.ty);
        if !pe_eq(vi.struct_type, "") {
            @CmpStructType stt = cg_find_struct(vi.struct_type);
            if stt != null {
                elem_size = stt.total_size;
            }
        }
        !!! A run-time length stands in front of the folded dimensions the same
        !!! declaration wrote (`int c[m][4]`): the count is the expression times
        !!! them.
        longlong dims_factor = 1;
        if s.array_len_expr != null && s.array_dims != null {
            @CmpIntNode df = s.array_dims;
            while df != null {
                if df.v > 0 {
                    dims_factor = dims_factor * df.v;
                }
                df = df.next;
            }
        }
        !!! The count is kept in a temporary as well: the metadata block records the
        !!! length the array really has, which for `int b[n]` only exists at run
        !!! time. Writing the folded `total_elements` there left such an array
        !!! claiming no elements at all, and the bounds check of every `b[i]` then
        !!! refused the access: the array was allocated with n elements and
        !!! immediately treated as empty.
        int count_slot = cg_next_stack_offset + cg_binop_nesting * 8;
        cg_binop_nesting = cg_binop_nesting + 1;
        if s.array_len_expr != null {
            cg_gen_expr(s.array_len_expr);
            if dims_factor > 1 {
                !!! imul rax, rax, dims_factor
                em_db(0x48);
                em_db(0x69);
                em_db(0xC0);
                em_dd((int)dims_factor);
            }
        } else {
            em_mov_rax_imm64(total_elements);
        }
        em_st_rsp_rax(count_slot);
        if elem_size == 8 {
            em_db(0x48);
            em_db(0xC1);
            em_db(0xE0);
            em_db(0x03);
        } else if elem_size == 4 {
            em_db(0x48);
            em_db(0xC1);
            em_db(0xE0);
            em_db(0x02);
        }
        em_db(0x48);
        em_db(0x83);
        em_db(0xC0);
        em_db(0x10);
        !!! The block comes from the runtime's pool.
        cg_emit_alloc_rax();
        !!! The block: capacity, element size and count in the first 16 bytes, the
        !!! elements behind them; the variable holds the data pointer. Capacity and
        !!! count are the element count this declaration asked for, read back from
        !!! the temporary: the size the allocation used and the length the bounds
        !!! check believes have to be the same number.
        em_ld_rsp_rdx(count_slot);
        em_db(0x89);
        em_db(0x10);
        em_db(0xC7);
        em_db(0x40);
        em_db(0x04);
        em_dd((int)elem_size);
        em_db(0x48);
        em_db(0x89);
        em_db(0x50);
        em_db(0x08);
        cg_binop_nesting = cg_binop_nesting - 1;
        em_db(0x48);
        em_db(0x83);
        em_db(0xC0);
        em_db(0x10);
        cg_store_var(off, vi.ty, vi.is_array, false);
        em_db(0x48);
        em_db(0x89);
        em_db(0xC3);
        !!! A large initializer becomes one `rep movsb` out of a blob in .rdata;
        !!! a small one is written element by element.
        bool use_inline_data = init_count * elem_size > 256;
        if use_inline_data {
            @PEBuf blob = pw_new_buf();
            int i = 0;
            while i < init_count {
                @CmpExpr val = ce_at(s.array_init, i);
                longlong v = 0;
                if val.nk == LIT_INT || val.nk == LIT_CHAR {
                    v = val.int_val;
                }
                if elem_size <= 1 {
                    pb_push(blob, (int)v);
                } else if elem_size <= 4 {
                    int b4 = 0;
                    while b4 < 4 {
                        pb_push(blob, (int)((v >> (b4 * 8)) & 255));
                        b4 = b4 + 1;
                    }
                } else {
                    int b8 = 0;
                    while b8 < 8 {
                        pb_push(blob, (int)((v >> (b8 * 8)) & 255));
                        b8 = b8 + 1;
                    }
                }
                i = i + 1;
            }
            int rdata_rva = pw_add_rdata_raw(blob.data, blob.len);
            em_db(0x48);
            em_db(0x8D);
            em_db(0x35);
            em_dd(0);
            int lea_pos = em_tell() - 4;
            int instr_end_rva = PEW_TEXT_RVA + em_tell();
            em_put32(lea_pos, rdata_rva - instr_end_rva);
            cg_note_rdata_ref(lea_pos, rdata_rva);
            em_db(0x48);
            em_db(0x89);
            em_db(0xDF);
            em_db(0x48);
            em_db(0xC7);
            em_db(0xC1);
            em_dd((int)(init_count * elem_size));
            em_db(0xF3);
            em_db(0xA4);
        } else {
            int i2 = 0;
            while i2 < init_count {
                @CmpExpr val = ce_at(s.array_init, i2);
                cg_gen_expr(val);
                longlong offset = i2 * elem_size;
                if elem_size == 1 {
                    if offset < 128 {
                        em_db(0x88);
                        em_db(0x43);
                        em_db((int)offset);
                    } else {
                        em_db(0x88);
                        em_db(0x83);
                        em_dd((int)offset);
                    }
                } else if elem_size == 4 {
                    if offset < 128 {
                        em_db(0x89);
                        em_db(0x43);
                        em_db((int)offset);
                    } else {
                        em_db(0x89);
                        em_db(0x83);
                        em_dd((int)offset);
                    }
                } else if val.result_type == FLOAT {
                    if offset < 128 {
                        em_db(0xF2);
                        em_db(0x0F);
                        em_db(0x11);
                        em_db(0x43);
                        em_db((int)offset);
                    } else {
                        em_db(0xF2);
                        em_db(0x0F);
                        em_db(0x11);
                        em_db(0x83);
                        em_dd((int)offset);
                    }
                } else {
                    if offset < 128 {
                        em_db(0x48);
                        em_db(0x89);
                        em_db(0x43);
                        em_db((int)offset);
                    } else {
                        em_db(0x48);
                        em_db(0x89);
                        em_db(0x83);
                        em_dd((int)offset);
                    }
                }
                i2 = i2 + 1;
            }
        }
        return true;
    }

    !!! A struct object: every field is written at its byte offset inside the object.
    if !pe_eq(vi.struct_type, "") {
        @CmpStructType st = cg_find_struct(vi.struct_type);
        if st != null {
            int nf = cf_count(st.fields);
            int fi = 0;
            while fi < nf {
                @CmpFieldInfo f = cf_at(st.fields, fi);
                int foff = off + f.off;
                cg_lea_var(foff);
                int temp = cg_next_stack_offset + cg_binop_nesting * 8;
                cg_binop_nesting = cg_binop_nesting + 1;
                em_st_rsp_rax(temp);
                if fi < ce_n(s.array_init) {
                    @CmpExpr val = ce_at(s.array_init, fi);
                    cg_gen_expr(val);
                    bool isf = val != null && val.result_type == FLOAT;
                    em_ld_rsp_rdx(temp);
                    if f.sz > 8 {
                        !!! An inline array field takes one value for its first
                        !!! element: the rest of the field is zeroed first, because
                        !!! a single eight byte store would leave its tail
                        !!! uninitialized.
                        if !isf {
                            em_db(0x50);
                        }
                        em_db(0x57);
                        em_db(0x48);
                        em_db(0x89);
                        em_db(0xD7);
                        em_db(0x31);
                        em_db(0xC0);
                        em_db(0xB9);
                        em_dd(f.sz);
                        em_db(0xFC);
                        em_db(0xF3);
                        em_db(0xAA);
                        em_db(0x5F);
                        if !isf {
                            em_db(0x58);
                        }
                        int esz = vt_size(f.ty);
                        if isf {
                            em_db(0xF2);
                            em_db(0x0F);
                            em_db(0x11);
                            em_db(0x02);
                        } else if esz == 1 {
                            em_db(0x88);
                            em_db(0x02);
                        } else if esz == 4 {
                            em_db(0x89);
                            em_db(0x02);
                        } else {
                            em_db(0x48);
                            em_db(0x89);
                            em_db(0x02);
                        }
                    } else if isf {
                        em_db(0xF2);
                        em_db(0x0F);
                        em_db(0x11);
                        em_db(0x02);
                    } else if f.sz == 1 {
                        em_db(0x88);
                        em_db(0x02);
                    } else if f.sz == 4 {
                        em_db(0x89);
                        em_db(0x02);
                    } else {
                        em_db(0x48);
                        em_db(0x89);
                        em_db(0x02);
                    }
                } else {
                    !!! No initializer: the field is zeroed.
                    em_db(0x31);
                    em_db(0xC0);
                    em_ld_rsp_rdx(temp);
                    if f.sz == 1 {
                        em_db(0x88);
                        em_db(0x02);
                    } else if f.sz == 4 {
                        em_db(0x89);
                        em_db(0x02);
                    } else if f.sz > 8 {
                        em_db(0x57);
                        em_db(0x48);
                        em_db(0x89);
                        em_db(0xD7);
                        em_db(0xB9);
                        em_dd(f.sz);
                        em_db(0xFC);
                        em_db(0xF3);
                        em_db(0xAA);
                        em_db(0x5F);
                    } else {
                        em_db(0x48);
                        em_db(0x89);
                        em_db(0x02);
                    }
                }
                cg_binop_nesting = cg_binop_nesting - 1;
                fi = fi + 1;
            }
            return true;
        }
    }

    cg_gen_expr(s.init_expr);
    if vi.ty == FUNC && s.init_expr != null && s.init_expr.nk == VAR_REF &&
       s.init_expr.result_type == FUNC {
        !!! `b = a` copies the closure pointer; both now own a reference.
        cg_emit_retain_rax();
    }
    cg_store_var(off, vi.ty, vi.is_array, false);
    if vi.ty == STR && !vi.is_array {
        if cg_produces_owned_str(s.init_expr) {
            cg_owned_strs = cg_set_add(cg_owned_strs, s.var_name);
        } else {
            cg_owned_strs = cg_set_drop(cg_owned_strs, s.var_name);
        }
    }
    return true;
}
