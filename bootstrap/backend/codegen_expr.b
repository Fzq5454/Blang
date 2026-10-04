#once
!~
 ~  bootstrap/backend/codegen_expr.b: the expression code generator.
 ~
 ~  Every expression answers its value in rax
 ~  (xmm0 for a float), and a temporary slot is taken from the frame's pool by
 ~  counting the nesting the expression is generated at, so a value kept across a
 ~  nested expression stays where it was put.
 ~!

#head "cg_heads"

void cg_gen_expr -> @CmpExpr n {
    if n == null {
        end;
    }
    CmpExprKind k = n.nk;

    if k == SPREAD {
        cg_gen_expr(n.left);
        end;
    }
    if k == LIT_INT {
        em_mov_rax_imm64(n.int_val);
        end;
    }
    if k == LIT_FLOAT {
        !!! The bit pattern of the double goes into .rdata and is loaded from
        !!! there: writing it through an `@float` block is how this implementation reads those
        !!! eight bytes without a numeric conversion.
        @void cell;
        cg_balloc(@cell, 8);
        @float fp = (@float)cell;
        fp[0] = n.float_val;
        @longlong q = (@longlong)cell;
        int rva = pw_add_rdata_raw((@char)cell, 8);
        cg_emit_movsd_xmm0_rdata(rva);
        end;
    }
    if k == LIT_STR {
        cg_emit_lea_rax_rdata(cg_intern_str(n.str_val));
        end;
    }
    if k == LIT_BOOL {
        em_mov_rax_imm64(0);
        if n.bool_val {
            em_mov_rax_imm64(1);
        }
        end;
    }
    if k == LIT_CHAR {
        em_mov_rax_imm64(n.char_val);
        end;
    }
    if k == LIT_NULL {
        em_mov_rax_imm64(0);
        end;
    }
    if k == FLDP {
        !!! A field through a struct pointer: address = *pointer + offset, and the
        !!! offset is part of the load. `add rax, 8` followed by `mov rax, [rax]` is
        !!! two instructions where `mov rax, [rax+8]` is one, and a field of a struct
        !!! is read on almost every line of the front end. The displacement is
        !!! signed, so only a non-negative offset goes in the one-byte form; zero
        !!! takes no displacement at all, which is the shortest form and the one a
        !!! first field uses.
        cg_gen_expr(n.left);
        int off = (int)n.int_val;
        bool no_disp = off == 0;
        bool d8 = off > 0 && off < 128;
        int modrm = 0x00;
        if !no_disp {
            if d8 {
                modrm = 0x40;
            } else {
                modrm = 0x80;
            }
        }
        if n.result_type == FLOAT {
            em_db(0xF2);
            em_db(0x0F);
            em_db(0x10);
            em_db(modrm);
        } else {
            int sz = vt_size(n.result_type);
            if sz == 1 {
                em_db(0x0F);
                em_db(0xB6);
                em_db(modrm);
            } else if sz == 4 {
                em_db(0x48);
                em_db(0x63);
                em_db(modrm);
            } else {
                em_db(0x48);
                em_db(0x8B);
                em_db(modrm);
            }
        }
        if !no_disp {
            if d8 {
                em_db(off);
            } else {
                em_dd(off);
            }
        }
        end;
    }
    if k == FLD {
        @CgVarInfo fit = cg_sym_find(n.var_name);
        if fit == null {
            em_db(0x48);
            em_db(0x31);
            em_db(0xC0);
            end;
        }
        int sz = vt_size(n.result_type);
        if n.left != null {
            !!! An element of a struct array: base + idx*total + offset.
            int total = 8;
            if !pe_eq(fit.struct_type, "") {
                @CmpStructType stt = cg_find_struct(fit.struct_type);
                if stt != null {
                    total = stt.total_size;
                }
            }
            cg_load_var(fit.stack_offset, fit.ty, fit.is_array, false);
            int temp = cg_next_stack_offset + cg_binop_nesting * 8;
            cg_binop_nesting = cg_binop_nesting + 1;
            em_st_rsp_rax(temp);
            cg_gen_expr(n.left);
            em_db(0x48);
            em_db(0x69);
            em_db(0xC0);
            em_dd(total);
            em_db(0x48);
            em_db(0x89);
            em_db(0xC1);
            em_ld_rsp(temp);
            em_db(0x48);
            em_db(0x01);
            em_db(0xC8);
            em_db(0x48);
            em_db(0x83);
            em_db(0xC0);
            em_db((int)n.int_val);
            cg_binop_nesting = cg_binop_nesting - 1;
        } else if fit.struct_ptr {
            !!! A struct pointer (a method's `this`): the pointer, plus the offset.
            cg_load_var(fit.stack_offset, fit.ty, true, false);
            int off = (int)n.int_val;
            if off < 128 {
                em_db(0x48);
                em_db(0x83);
                em_db(0xC0);
                em_db(off);
            } else {
                em_db(0x48);
                em_db(0x05);
                em_dd(off);
            }
        } else {
            cg_lea_var(fit.stack_offset + (int)n.int_val);
        }
        if n.result_type == FLOAT {
            em_db(0xF2);
            em_db(0x0F);
            em_db(0x10);
            em_db(0x00);
            end;
        }
        if sz == 1 {
            em_db(0x0F);
            em_db(0xB6);
            em_db(0x00);
        } else if sz == 4 {
            em_db(0x48);
            em_db(0x63);
            em_db(0x00);
        } else {
            em_db(0x48);
            em_db(0x8B);
            em_db(0x00);
        }
        end;
    }
    if k == VAR_REF {
        !!! A parameter is rbp-based and read out of its own slot. A FLOAT one is
        !!! passed as a double, so it has to be read into xmm0: reading its raw bits
        !!! into rax left the caller's xmm0 in place.
        if !pe_eq(cg_current_func, "") {
            @CgNameOff oit = cg_param_off(cg_current_func, n.var_name);
            if oit != null {
                VarType pt = cg_param_type(cg_current_func, n.var_name);
                if pt == FLOAT {
                    em_ldsd_rbp(oit.off);
                } else {
                    em_ld_rbp(oit.off);
                }
                end;
            }
        }
        !!! One lookup and not two: both branches reported the same
        !!! "undeclared symbol", and a variable reference is the most common
        !!! expression there is.
        @CgVarInfo it = cg_sym_find(n.var_name);
        if it == null {
            cg_gen_error = cg_err_at(n.line, n.col, "undeclared symbol '" + n.var_name + "'");
            end;
        }
        cg_load_var(it.stack_offset, it.ty, it.is_array, false);
        end;
    }
    if k == BINOP {
        if pe_eq(n.op, "\\") {
            cg_gen_not(n);
            end;
        }
        cg_gen_binop(n);
        end;
    }
    if k == BITNOT {
        cg_gen_expr(n.left);
        em_db(0x48);
        em_db(0xF7);
        em_db(0xD0);
        end;
    }
    if k == SHL || k == SHR {
        cg_gen_expr(n.right);
        em_mov_rcx_rax();
        cg_gen_expr(n.left);
        if k == SHL {
            em_db(0x48);
            em_db(0xD3);
            em_db(0xE0);
        } else {
            em_db(0x48);
            em_db(0xD3);
            em_db(0xF8);
        }
        end;
    }
    if k == CAST {
        cg_gen_cast_expr(n);
        end;
    }
    if k == ARRAY_ACCESS {
        cg_gen_array_access(n);
        end;
    }
    if k == FUNC_CALL {
        str nm = n.var_name;
        !!! A conversion written with parentheses around its operand is the same
        !!! thing as the prefix spelling: both go through the cast code.
        if pe_eq(nm, "_toStr") || pe_eq(nm, "_toInt") || pe_eq(nm, "_toLong") ||
           pe_eq(nm, "_toChar") || pe_eq(nm, "_toBool") || pe_eq(nm, "_toFloat") {
            if n.args != null {
                @CmpExpr cast = ce_new(CAST);
                cast.op = nm;
                cast.left = n.args;
                cast.result_type = n.result_type;
                cg_gen_cast_expr(cast);
            }
            end;
        }
        int func_off = cg_resolve_sym(nm);
        if func_off != 0 {
            int na = ce_n(n.args);
            int i = na - 1;
            while i >= 0 {
                @CmpExpr a = ce_at(n.args, i);
                cg_gen_expr(a);
                if a.result_type == FLOAT {
                    em_sub_rsp_imm8(8);
                    em_movsd_mem_rsp_disp8_xmm0(0);
                } else {
                    em_push_rax();
                }
                i = i - 1;
            }
            cg_emit_call_text(func_off);
            if na > 0 {
                em_sub_rsp(0 - na * 8);
            }
        } else {
            cg_gen_func_call(nm, n.args, n.line, n.col);
        }
        end;
    }
    if k == ADDR {
        !!! The address of a function name is the raw code address.
        if n.left.nk == VAR_REF {
            int fit_off = cg_fmap_get(n.left.var_name);
            if fit_off != 0 {
                int lea_pos = em_lea_rax_rip_disp32();
                int code_rva = PEW_TEXT_RVA + fit_off;
                int instr_end = PEW_TEXT_RVA + em_tell();
                em_put32(lea_pos + 3, code_rva - instr_end);
                end;
            }
        }
        !!! `@arr` is the heap data pointer, not the slot's address.
        if n.left.nk == VAR_REF {
            @CgVarInfo it = cg_sym_find(n.left.var_name);
            if it != null && it.is_array {
                cg_load_var(it.stack_offset, it.ty, true, false);
                end;
            }
        }
        if n.left.nk == VAR_REF {
            !!! A parameter is addressed off rbp; it does not have to be in syms.
            if !pe_eq(cg_current_func, "") {
                @CgNameOff oit = cg_param_off(cg_current_func, n.left.var_name);
                if oit != null {
                    em_lea_rbp(oit.off);
                    end;
                }
            }
            @CgVarInfo it = cg_sym_find(n.left.var_name);
            if it != null {
                cg_lea_var(it.stack_offset);
            }
        } else {
            cg_gen_error = cg_err_at(n.line, n.col,
                                     "@ can only be applied to a variable");
            end;
        }
        end;
    }
    if k == DL {
        cg_gen_expr(n.left);
        VarType addr_type = n.left.result_type;
        !!! A parameter is not visited by the resolve pass, so the type it carries
        !!! there is the default: the symbol table, and for a parameter the
        !!! function's own table, have the real one.
        if n.left.nk == VAR_REF {
            @CgVarInfo dit = cg_sym_find(n.left.var_name);
            if dit != null && !dit.is_array {
                addr_type = dit.ty;
            } else if !pe_eq(cg_current_func, "") {
                addr_type = cg_param_type(cg_current_func, n.left.var_name);
            }
        }
        int depth = n.left.ptr_depth;
        if depth > 1 {
            em_db(0x48);
            em_db(0x8B);
            em_db(0x00);
        } else if addr_type == AT_FLOAT {
            em_db(0xF2);
            em_db(0x0F);
            em_db(0x10);
            em_db(0x00);
        } else if addr_type == AT_INT {
            em_db(0x48);
            em_db(0x63);
            em_db(0x00);
        } else if addr_type == AT_CHAR || addr_type == AT_BOOL {
            em_db(0x0F);
            em_db(0xB6);
            em_db(0x00);
        } else {
            em_db(0x48);
            em_db(0x8B);
            em_db(0x00);
        }
        end;
    }
    if k == PRE_INCR {
        @CgVarInfo it = cg_sym_find(n.left.var_name);
        if it == null {
            cg_gen_error = cg_err_at(n.line, n.col,
                                     "undeclared symbol '" + n.left.var_name + "'");
            end;
        }
        cg_load_var(it.stack_offset, it.ty, it.is_array, false);
        int delta = 0 - 1;
        if pe_eq(n.op, "++") {
            delta = 1;
        }
        em_db(0x48);
        em_db(0x83);
        em_db(0xC0);
        em_db(delta & 255);
        cg_store_var(it.stack_offset, it.ty, it.is_array, false);
        end;
    }
    if k == POST_INCR {
        @CgVarInfo it = cg_sym_find(n.left.var_name);
        if it == null {
            cg_gen_error = cg_err_at(n.line, n.col,
                                     "undeclared symbol '" + n.left.var_name + "'");
            end;
        }
        cg_load_var(it.stack_offset, it.ty, it.is_array, false);
        em_push_rax();
        em_db(0x48);
        em_db(0x8B);
        em_db(0x04);
        em_db(0x24);
        int delta = 0 - 1;
        if pe_eq(n.op, "++") {
            delta = 1;
        }
        em_db(0x48);
        em_db(0x83);
        em_db(0xC0);
        em_db(delta & 255);
        cg_store_var(it.stack_offset, it.ty, it.is_array, false);
        em_pop_rax();
        end;
    }
    if k == CLOSURE {
        !!! A closure object: [0]=refcount, [8]=code_ptr, [16]=capture_count,
        !!! [24]=cell_flags, [32..]=captures.
        int K = ce_n(n.args);
        int temp = cg_next_stack_offset + cg_binop_nesting * 8;
        cg_binop_nesting = cg_binop_nesting + 2;
        !!! A lambda object of 32 + captures*8 bytes, from the pool.
        cg_emit_alloc_block(32 + K * 8);
        em_st_rsp_rax(temp);
        em_ld_rsp(temp);
        em_mov_rdx_rax();
        em_mov_rax_imm64(1);
        em_mov_mem_rdx_disp8_rax(0);
        !!! The address of the hidden function, patched later when it is defined
        !!! further down the file.
        int lea_pos = em_lea_rax_rip_disp32();
        int fit_off = cg_fmap_get(n.var_name);
        if fit_off != 0 {
            int code_rva = PEW_TEXT_RVA + fit_off;
            int instr_end = PEW_TEXT_RVA + em_tell();
            em_put32(lea_pos + 3, code_rva - instr_end);
        } else {
            cg_pending_addr_add(lea_pos + 3, em_tell(), n.var_name, n.line, n.col);
        }
        em_st_rsp_rax(temp + 8);
        em_ld_rsp(temp);
        em_mov_rdx_rax();
        em_ld_rsp(temp + 8);
        em_mov_mem_rdx_disp8_rax(8);
        em_ld_rsp(temp);
        em_mov_rdx_rax();
        em_mov_rax_imm64(K);
        em_mov_mem_rdx_disp8_rax(16);
        !!! The flags marking the captures that hold a heap cell.
        longlong cell_flags = 0;
        int ci = 0;
        while ci < K {
            @CmpExpr ca = ce_at(n.args, ci);
            if ca.nk == CELL {
                cell_flags = cell_flags | (1 << ci);
            }
            ci = ci + 1;
        }
        em_ld_rsp(temp);
        em_mov_rdx_rax();
        em_mov_rax_imm64(cell_flags);
        em_mov_mem_rdx_disp8_rax(24);
        int i = 0;
        while i < K {
            @CmpExpr a = ce_at(n.args, i);
            cg_gen_expr(a);
            if a.result_type == FLOAT {
                em_stsd_rsp(temp + 8);
            } else {
                em_st_rsp_rax(temp + 8);
            }
            em_ld_rsp(temp);
            em_mov_rdx_rax();
            int off = 32 + i * 8;
            if a.result_type == FLOAT {
                em_ldsd_rsp(temp + 8);
                if off < 128 {
                    em_db(0xF2);
                    em_db(0x0F);
                    em_db(0x11);
                    em_db(0x42);
                    em_db(off);
                }
            } else {
                em_ld_rsp(temp + 8);
                if off < 128 {
                    em_mov_mem_rdx_disp8_rax(off);
                } else {
                    em_db(0x48);
                    em_db(0x89);
                    em_db(0x82);
                    em_dd(off);
                }
            }
            i = i + 1;
        }
        em_ld_rsp(temp);
        cg_binop_nesting = cg_binop_nesting - 2;
        end;
    }
    if k == CLOSURE_CODE {
        cg_gen_expr(n.left);
        em_db(0x48);
        em_db(0x8B);
        em_db(0x40);
        em_db(0x08);
        end;
    }
    if k == CLOSURE_FROM_PTR {
        cg_gen_expr(n.left);
        int temp = cg_next_stack_offset + cg_binop_nesting * 8;
        cg_binop_nesting = cg_binop_nesting + 2;
        em_st_rsp_rax(temp + 8);
        !!! A 32-byte closure object from the runtime's pool.
        cg_emit_alloc_block(32);
        em_st_rsp_rax(temp);
        em_ld_rsp(temp);
        em_mov_rdx_rax();
        em_mov_rax_imm64(1);
        em_mov_mem_rdx_disp8_rax(0);
        em_ld_rsp(temp);
        em_mov_rdx_rax();
        em_ld_rsp(temp + 8);
        em_mov_mem_rdx_disp8_rax(8);
        em_ld_rsp(temp);
        em_mov_rdx_rax();
        em_mov_rax_imm64(0);
        em_mov_mem_rdx_disp8_rax(16);
        em_ld_rsp(temp);
        em_mov_rdx_rax();
        em_mov_rax_imm64(0);
        em_mov_mem_rdx_disp8_rax(24);
        em_ld_rsp(temp);
        cg_binop_nesting = cg_binop_nesting - 2;
        end;
    }
    if k == CELL {
        !!! An eight-byte heap cell holding the value, for a mutable capture.
        cg_gen_expr(n.left);
        int temp = cg_next_stack_offset + cg_binop_nesting * 8;
        cg_binop_nesting = cg_binop_nesting + 2;
        bool is_float = n.left.result_type == FLOAT;
        if is_float {
            em_stsd_rsp(temp + 8);
        } else {
            em_st_rsp_rax(temp + 8);
        }
        !!! An 8-byte capture cell from the runtime's pool.
        cg_emit_alloc_block(8);
        em_st_rsp_rax(temp);
        if is_float {
            em_ldsd_rsp(temp + 8);
            em_ld_rsp(temp);
            em_db(0xF2);
            em_db(0x0F);
            em_db(0x11);
            em_db(0x00);
        } else {
            em_ld_rsp(temp + 8);
            em_mov_rdx_rax();
            em_ld_rsp(temp);
            em_db(0x48);
            em_db(0x89);
            em_db(0x10);
        }
        em_ld_rsp(temp);
        cg_binop_nesting = cg_binop_nesting - 2;
        end;
    }
    if k == ANY_TAG {
        !!! The runtime type tag of an `any` element: [value @ idx*16, tag @ +8].
        @CgVarInfo it = cg_sym_find(n.var_name);
        if it == null {
            em_db(0x48);
            em_db(0x31);
            em_db(0xC0);
            end;
        }
        int temp = cg_next_stack_offset + cg_binop_nesting * 8;
        cg_binop_nesting = cg_binop_nesting + 1;
        cg_load_var(it.stack_offset, it.ty, it.is_array, false);
        em_st_rsp_rax(temp);
        cg_gen_expr(n.left);
        em_db(0x48);
        em_db(0xC1);
        em_db(0xE0);
        em_db(0x04);
        em_ld_rsp_rdx(temp);
        em_db(0x48);
        em_db(0x01);
        em_db(0xD0);
        em_db(0x48);
        em_db(0x8B);
        em_db(0x40);
        em_db(0x08);
        cg_binop_nesting = cg_binop_nesting - 1;
        end;
    }
    if k == ICALL {
        cg_emit_icall(n.left, n.args);
        end;
    }
    if k == TERNARY {
        cg_gen_expr(n.left);
        em_test_rax_rax();
        !!! The long form: an arm can be many instructions, which a rel8 cannot
        !!! reach.
        int jz_false = em_jz_rel32();
        cg_gen_expr(n.right);
        int jmp_end = em_jmp_rel32();
        em_patch_jz_rel32(jz_false);
        cg_gen_expr(n.args);
        em_patch_jmp_rel32(jmp_end);
        end;
    }
}
