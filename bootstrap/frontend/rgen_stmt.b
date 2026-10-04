#once
!~
 ~  bootstrap/frontend/rgen_stmt.b: the frontend/rgen_stmt.
 ~
 ~  One statement as .r: the switch the toolchain writes over `StmtNode::kind`, in the
 ~  same order, with the same messages and the same emitted text. The three stores
 ~  that need the whole statement (a store through a `[]` that returns `@T`, one
 ~  written through a chain of subscripts, and the read-modify-write of a field of a
 ~  value-returning `[]`) are decided first, before the kind is looked at; so are the
 ~  struct values a call returns, which are hoisted into locals of the frame being
 ~  emitted (prepare_stmt_struct_calls).
 ~
 ~  A struct-variable ASSIGN is the one long case: the target's `.r` name is built
 ~  from the variable (or the `this` field it names), the inline-array element store
 ~  writes the element address out by hand, and the value is either a cast, a
 ~  whole-struct leaf copy, or a reference write-through.
 ~
 ~  Text comparison goes through pe_eq(): the `==` on a str compares the
 ~  contents, and blang's `==` on two `str` values compares the pointers (which is
 ~  the reason pe_eq exists at all), so a name test written with `==` would answer
 ~  the wrong thing for a computed text.
 ~!

#head "rgen"
#head "rgen_heads"

!!! scalar_literal_expr: a literal can never be a struct value, so a struct target
!!! that receives one is reported; an expression whose struct-ness cannot be
!!! resolved is left alone. (the toolchain keeps this as a static helper of the file.)
bool rgx_scalar_literal_expr -> @ExprNode n {
    if n == null {
        return false;
    }
    if n.nk == LIT_INT || n.nk == LIT_FLOAT || n.nk == LIT_STR ||
       n.nk == LIT_BOOL || n.nk == LIT_CHAR {
        return true;
    }
    return false;
}

!!! gen_stmt: the statement. `BAPI` (a BLANG_API definition is type-only, no .r
!!! output), `STRUCT_INIT` (the declaration writes the initializer), `PACKAGE` and
!!! `USE` (the packages are flattened into ordinary declarations before code
!!! generation, see rgen_package) emit nothing, so no branch below matches
!!! them; the toolchain cases are empty for the same reason.
void rg_gen_stmt -> @StmtNode s {
    !!! Values a call returns live in the callee's frame, which the next call
    !!! reuses; the ones this statement still needs are copied into locals of this
    !!! frame first, while rcode still ends at the previous statement.
    rg_prepare_stmt_struct_calls(s);
    !!! An assignment written inside one of this statement's expressions becomes a
    !!! call of its store helper, so the value is where the expression reads it.
    rg_lower_assign_exprs(s);
    !!! `a[i] = v` / `a[i].field = v` through a pointer-returning `[]`: the store
    !!! goes straight through the address the getter returned.
    if rg_emit_index_ptr_store(s) {
        end;
    }
    !!! A store written through a chain of subscripts (`v[i][j] = x`).
    if rg_emit_index_chain_store(s) {
        end;
    }
    !!! `a[i].field = v` on a value-returning `[]`: emitted as a
    !!! read-modify-write, after the values it reads are in this frame.
    if rg_emit_index_field_assign(s) {
        end;
    }

    if s.nk == DECLARE {
        rg_gen_stmt_declare(s);
        !!! Record it for the statements that follow, exactly as the type checking
        !!! walk does: an argument that is only resolved while it is emitted (a
        !!! builtin's `any` argument) then sees the declaration in scope instead of
        !!! the first one with that name.
        if !pe_eq(s.var_name, "") {
            VarDecl proto;
            @VarDecl d;
            malloc(@d, size proto);
            d.ty = s.decl_type;
            d.ptr_depth = s.ptr_depth;
            d.struct_type = s.struct_type;
            !!! the toolchain default-constructs the record here, which leaves
            !!! struct_ptr false and dims empty.
            d.struct_ptr = false;
            d.is_array = s.is_array;
            d.is_ref = s.decl_is_ref;
            d.is_unsigned = s.decl_is_unsigned;
            d.dims = rg_longchain_of(s.array_dims);
            int nd = 0;
            @IntNode di = s.array_dims;
            while di != null {
                nd = nd + 1;
                di = di.next;
            }
            d.n = nd;
            d.len_expr = s.array_len_expr;
            rg_local_decls = rg_vardeclmap_set(rg_local_decls, s.var_name, d);
        }
    } else if s.nk == ASSIGN {
        !!! `g.m = {1, 2, 3};`: an initializer list cannot be assigned to an inline
        !!! array field.
        if rg_report_field_array_assign(s) {
            end;
        }
        !!! `o.data[i] = v` / `data[i] = v` inside a method: one element of an
        !!! inline array field.
        if rg_emit_field_array_store(s) {
            end;
        }
        !!! Whole-struct copy into a struct-valued field (`o.in = p`): the field is
        !!! not a storage leaf, so it is copied leaf by leaf.
        if rg_emit_struct_field_copy(s) {
            end;
        }
        !!! Write through a mutable capture cell (by-reference captured var).
        str cref = rg_cap_ref_name(s.var_name);
        if !pe_eq(cref, "") && pe_eq(s.member_name, "") && !s.is_array {
            rg_rcode = rg_rcode + "DREF " + cref + " , ";
            rg_rc_expr(s.expr);
            rg_rcode = rg_rcode + "\n";
            end;
        }
        !!! The effective variable name (accounting for struct method expansion).
        !!! A copy (`+ ""`) and not an alias: the name is what the target of the
        !!! write is called while the branches below replace `vname` with the .r
        !!! text of that target, and assigning to a `str` variable frees the heap
        !!! string it owned (backend/codegen_cast). Aliased, that free took the
        !!! block `s.var_name` points at with it, and the next read of the field
        !!! walked a freed string (bootstrap/_probe_tmpl.b / operator_example.b).
        str vname = s.var_name + "";

        !!! One element of a `@T` block, written and read as an object: the element
        !!! sits at the pointer plus the index scaled by the layout size of the
        !!! struct. `p{i}` cannot express that (the back end scales it by the size
        !!! it knows for the symbol, and a raw pointer has none), so the address is
        !!! written out here: for a whole element the object is copied leaf by
        !!! leaf, for a field of it the field is stored.
        !!! A pointer field of this struct is a pointer even when its elements are
        !!! builtins (`@int data`), and it is not a symbol the `p{i}` form could
        !!! name.
        bool ptr_base = rg_var_is_struct_ptr(s.var_name);
        if !ptr_base {
            ptr_base = rg_name_is_pointer(s.var_name);
        }
        if !ptr_base {
            !!! method_field_block_info(s->var_name, probe_t, probe_step): the toolchain
            !!! keeps the two out values in locals it never reads again, so only the
            !!! answer is used here.
            ptr_base = rg_method_field_block_info(s.var_name);
        }
        str chain_base = "";
        str chain_struct = "";
        int chain_step = 0;
        bool chain_block = false;
        !!! One element of that block. The store used to ask
        !!! rg_pointer_element_type(s.var_name) for it, and a *field* name is no
        !!! symbol that lookup can find, so it answered the default INT for every
        !!! builtin element: `data[i] = c` on a `@char data` then wrote four bytes
        !!! into a one-byte element and ran past the end of the block (the emitter's
        !!! own output buffer, whose block ends on a page boundary, faulted on it).
        !!! The block's own declaration is what answers, the way the read path
        !!! already does it.
        VarType chain_elem = INT;
        if !ptr_base && s.members_before_index > 0 && s.member_chain != null {
            !!! The chain the index applies to, as a throw-away node.
            @ExprNode root = p_new_expr(VAR_REF);
            root.var_name = s.var_name;
            root.line = s.line;
            root.col = s.col;
            @ExprNode head = root;
            @StrNode mc = s.member_chain;
            int ci = 0;
            while ci < s.members_before_index && mc != null {
                @ExprNode mm = p_new_expr(MEMBER_ACCESS);
                mm.member_name = mc.s;
                mm.left = head;
                !!! `s->member_line ? s->member_line : s->line` (and the column): the
                !!! member's own position when it has one.
                mm.line = s.line;
                if s.member_line != 0 {
                    mm.line = s.member_line;
                }
                mm.col = s.col;
                if s.member_col != 0 {
                    mm.col = s.member_col;
                }
                head = mm;
                mc = mc.next;
                ci = ci + 1;
            }
            chain_block = rg_member_chain_block_info(head);
            chain_base = rg_member_chain_block_info_out_base;
            chain_struct = rg_member_chain_block_info_out_struct;
            chain_step = rg_member_chain_block_info_out_step;
            chain_elem = rg_member_chain_block_info_out_elem;
            !!! `delete head`: the synthetic chain is dropped; nothing here gives a
            !!! block back.
            if chain_block {
                ptr_base = true;
            }
        }
        if s.is_array && ptr_base && s.array_init != null {
            str stx = rg_struct_type_in_effect(s.var_name);
            int step = 0;
            if !pe_eq(stx, "") {
                step = rg_struct_layout_size(stx);
            }
            !!! A field is not a symbol the `p{i}` form can name, so it goes through
            !!! the address even when its elements are builtins; a plain `@int p`
            !!! variable keeps that form, which the back end scales itself.
            bool mf_block = false;
            if chain_block {
                stx = chain_struct;
                step = chain_step;
            } else if step == 0 {
                if rg_method_field_block_info(s.var_name) {
                    stx = rg_method_field_block_info_out_struct_type;
                    step = rg_method_field_block_info_out_step;
                    mf_block = true;
                } else if !pe_eq(stx, "") {
                    step = rg_struct_layout_size(stx);
                } else if rg_var_is_struct_ptr(s.var_name) || rg_name_is_pointer(s.var_name) {
                    !!! A plain pointer variable (`@int p`): the element address is
                    !!! written out here too, with the same step the read path uses,
                    !!! so the two cannot disagree on the stride.
                    step = rg_pointer_step_size(s.var_name);
                }
            }
            str base_text = rg_pointer_base_text(s.var_name);
            if chain_block {
                base_text = chain_base;
            }
            int off = 0;
            !!! The member written is the one after the index, if any: the members
            !!! before it named the block itself. the toolchain copies the tail of the
            !!! member vector into a vector of its own; this implementation reads the tail of
            !!! the member chain, which holds the same names in the same order.
            @StrNode after = s.member_chain;
            int cidx = 0;
            while after != null && cidx < s.members_before_index {
                after = after.next;
                cidx = cidx + 1;
            }
            str idx = "";
            if s.assign_indices != null {
                idx = rg_linear_index_expr(s.var_name, s.assign_indices);
            } else if s.expr != null {
                idx = rg_capture_rc_expr(s.expr);
            }
            @StructField leaf = null;
            !!! `s->member_line ? s->member_line : s->line`: the position of the member
            !!! written is the one the statement carries when it has one.
            int ml0 = s.member_line;
            if ml0 == 0 {
                ml0 = s.line;
            }
            int mc0 = s.member_col;
            if mc0 == 0 {
                mc0 = s.col;
            }
            if after != null {
                if !pe_eq(stx, "") {
                    if rg_resolve_field_chain(stx, after, ml0, mc0) {
                        leaf = rg_resolve_field_chain_out_leaf;
                        off = rg_resolve_field_chain_out_abs_off;
                    }
                }
            }
            if step > 0 && !pe_eq(idx, "") && (after == null || leaf != null) {
                str ea = "((@void " + base_text + ") , (" + idx + " , " + (str)step + " , *) , +)";
                if after == null && !pe_eq(stx, "") {
                    if rg_emit_struct_source_address(s.array_init) {
                        str src = rg_emit_struct_source_address_out;
                        rg_emit_struct_leaf_copy(ea, stx, src);
                        rg_rcode = rg_rcode + "\n";
                        end;
                    }
                } else if after == null {
                    !!! A builtin element: the address holds the value, and the
                    !!! element's own type comes from the declaration of the block
                    !!! (see the note where chain_elem is declared).
                    VarType et = INT;
                    if chain_block {
                        et = chain_elem;
                    } else if mf_block {
                        et = rg_method_field_elem_type(s.var_name);
                    } else {
                        et = rg_pointer_element_type(s.var_name);
                    }
                    rg_rcode = rg_rcode + "CAST (FLDP " + ea + " 0 "
                              + rg_rtype(et) + ") , ";
                    rg_rc_expr(s.array_init);
                    rg_rcode = rg_rcode + "\n";
                    end;
                } else {
                    rg_rcode = rg_rcode + "CAST (FLDP " + ea + " " + (str)off + " "
                              + rg_rtype(rg_field_eff_type(leaf)) + ") , ";
                    rg_rc_expr(s.array_init);
                    rg_rcode = rg_rcode + "\n";
                    end;
                }
            }
        }

        if s.is_super {
            int ml1 = s.member_line;
            if ml1 == 0 {
                ml1 = s.line;
            }
            int mc1 = s.member_col;
            if mc1 == 0 {
                mc1 = s.col;
            }
            vname = rg_emit_fld(rg_struct_method_var, rg_struct_method_type, s.member_name,
                                true, false, ml1, mc1);
        } else if !pe_eq(s.member_name, "") {
            !!! A `@T` field of the enclosing method's struct: the write goes through
            !!! the pointer the field holds, and the struct is the one it points at -
            !!! not the pointer field's own slot.
            bool field_ptr = rg_method_field_is_struct_ptr(s.var_name);
            str stype = "";
            if field_ptr {
                stype = rg_method_field_struct_type(s.var_name);
            } else {
                stype = rg_receiver_struct_type_of(s.var_name);
            }
            if pe_eq(stype, "") && p_find_struct(s.var_name) != null {
                stype = s.var_name;
            }
            !!! A chain rooted at a bare field of the enclosing method's struct
            !!! (`n.v = x` inside a method): the field is addressed inside `this`, so
            !!! its members are written through that address.
            str root_addr = "";
            !!! A `@T` field of this struct is not written at its own slot: the
            !!! pointer it holds is what `data[i].a = v` writes through, so the
            !!! field-address path below must not take the write over.
            bool root_is_this_field = false;
            if !field_ptr {
                if rg_this_field_address(s.var_name) {
                    root_addr = rg_this_field_address_out;
                    root_is_this_field = true;
                }
            }
            bool base_is_ptr = rg_var_is_struct_ptr(s.var_name)
                               || rg_name_is_pointer(s.var_name) || field_ptr;
            bool handled = false;
            int mcount = 0;
            @StrNode mcn = s.member_chain;
            while mcn != null {
                mcount = mcount + 1;
                mcn = mcn.next;
            }
            !!! A write into one element of a `@T` block (`p[i].a = v`): the
            !!! synthetic chain below carries the index as an ARRAY_ACCESS root, so
            !!! the element address is built with the scale of the struct. Written as
            !!! a bare `p.a` chain it used the pointer itself as the object and then
            !!! appended `{i}` to a form with no place for it.
            if !pe_eq(stype, "") && !root_is_this_field && (mcount > 1 || base_is_ptr) {
                !!! Pointer-aware write: `p.v = x` / `a.next.v = x` / `p[i].v = x`.
                !!! Build a throw-away chain so the same emitter as a read can be
                !!! reused.
                @ExprNode root2 = p_new_expr(VAR_REF);
                root2.var_name = s.var_name;
                root2.line = s.line;
                root2.col = s.col;
                @ExprNode head2 = root2;
                @StrNode mc2 = s.member_chain;
                while mc2 != null {
                    @ExprNode mm2 = p_new_expr(MEMBER_ACCESS);
                    mm2.member_name = mc2.s;
                    mm2.left = head2;
                    !!! `s->member_line ? s->member_line : s->line` (and the column).
                    mm2.line = s.line;
                    if s.member_line != 0 {
                        mm2.line = s.member_line;
                    }
                    mm2.col = s.col;
                    if s.member_col != 0 {
                        mm2.col = s.member_col;
                    }
                    head2 = mm2;
                    mc2 = mc2.next;
                }
                if rg_emit_pointer_chain(head2) {
                    vname = rg_emit_pointer_chain_out;
                    handled = true;
                }
                !!! `delete head2`: the synthetic chain is dropped.
            }
            !!! A write into one element of a `@T` block (`p[i].a = v`) is done
            !!! above: the index has to be scaled by the layout size of the struct,
            !!! and the chain reads the field from the pointer itself, which is the
            !!! element only at index 0.
            if !handled {
                !!! `s->member_line ? s->member_line : s->line` (and the column).
                int ml2 = s.member_line;
                if ml2 == 0 {
                    ml2 = s.line;
                }
                int mc2b = s.member_col;
                if mc2b == 0 {
                    mc2b = s.col;
                }
                if s.member_chain != null && !pe_eq(stype, "") {
                    !!! A field (or a chain of them) of the target: the write goes
                    !!! through its absolute offset, from the object's own address
                    !!! (`this` plus the root field's offset for a bare field).
                    @StructField leaf2 = null;
                    int off2 = 0;
                    bool ok2 = false;
                    if rg_resolve_field_chain(stype, s.member_chain, ml2, mc2b) {
                        ok2 = true;
                        leaf2 = rg_resolve_field_chain_out_leaf;
                        off2 = rg_resolve_field_chain_out_abs_off;
                    }
                    if ok2 && leaf2 != null {
                        if root_is_this_field {
                            vname = "(FLDP " + root_addr + " " + (str)off2 + " "
                                  + rg_rtype(rg_field_eff_type(leaf2)) + ")";
                        } else if mcount > 1 {
                            vname = "(FLD " + s.var_name + " " + (str)off2 + " "
                                  + rg_rtype(rg_field_eff_type(leaf2)) + ")";
                        } else {
                            vname = rg_emit_fld(s.var_name, stype, s.member_name, false, false,
                                                ml2, mc2b);
                        }
                    } else {
                        vname = rg_emit_fld(s.var_name, stype, s.member_name, false, false,
                                            ml2, mc2b);
                    }
                } else {
                    vname = rg_emit_fld(s.var_name, stype, s.member_name, false, false, ml2, mc2b);
                }
            }
        } else if rg_method_field_shadows(s.var_name) {
            vname = rg_emit_fld(rg_struct_method_var, rg_struct_method_type, s.var_name, false,
                                false, s.line, s.col);
        }

        if s.is_array && s.expr != null {
            !!! A field of a heap array element (`arr[i].x = v`): the index belongs
            !!! inside the FLD, which the back end offsets by the element size,
            !!! exactly like the read of the same field.
            str itxt = rg_capture_rc_expr(s.expr);
            int vl = pe_len(vname);
            if vl > 5 && pe_matches(vname, 0, "(FLD ") && vname[vl - 1] == ')' {
                rg_rcode = rg_rcode + "CAST " + pe_sub(vname, 0, vl - 1) + " " + itxt + ") , ";
            } else {
                rg_rcode = rg_rcode + "CAST " + vname + "{" + itxt + "} , ";
            }
            rg_rc_expr(s.array_init);
        } else if s.is_array && s.assign_indices != null {
            !!! Multi-D element write: m[i][j] = v. A field target keeps the index
            !!! inside the FLD, the way the single index case does.
            str lin = rg_linear_index_expr(s.var_name, s.assign_indices);
            int vl2 = pe_len(vname);
            if vl2 > 5 && pe_matches(vname, 0, "(FLD ") && vname[vl2 - 1] == ')' {
                rg_rcode = rg_rcode + "CAST " + pe_sub(vname, 0, vl2 - 1) + " " + lin + ") , ";
            } else {
                rg_rcode = rg_rcode + "CAST " + vname + "{" + lin + "} , ";
            }
            rg_rc_expr(s.array_init);
        } else if s.is_array && s.array_init != null && s.expr == null {
            rg_rcode = rg_rcode + "CAST " + vname + " , {";
            @ExprNode ai = s.array_init;
            bool first_init = true;
            while ai != null {
                if !first_init {
                    rg_rcode = rg_rcode + ", ";
                }
                first_init = false;
                rg_rc_expr(ai);
                ai = ai.next;
            }
            rg_rcode = rg_rcode + "}";
        } else if rg_is_ref_var(s.var_name) && s.member_chain == null && !s.is_array
                  && pe_eq(rg_struct_method_var, "") && !s.is_super {
            !!! Reference write-through: x = v -> DREF x, v
            rg_rcode = rg_rcode + "DREF " + s.var_name + " , ";
            rg_rc_expr(s.expr);
        } else {
            str tstruct = rg_struct_type_in_effect(vname);
            str sstruct = "";
            if s.expr != null && !pe_eq(tstruct, "") {
                sstruct = rg_expr_struct_type(s.expr);
            }
            bool cond1 = !pe_eq(tstruct, "");
            bool cond2 = s.expr != null;
            if cond1 && cond2 &&
               s.expr.nk != UNARY && s.expr.nk != ADDR {
                !!! The value has to be that struct: another struct type, or a
                !!! literal, would copy the wrong object into it. An expression
                !!! whose struct-ness is unknown is left to the ordinary checks.
                bool definite = !pe_eq(sstruct, "") || rgx_scalar_literal_expr(s.expr);
                if definite && !pe_eq(sstruct, tstruct) {
                    str got = sstruct;
                    if pe_eq(got, "") {
                        got = rg_type_name(s.expr.result_type);
                    }
                    str msg = "cannot assign a '" + got + "' value to '" + tstruct + "'";
                    !!! fmt_err(s->line, s->col, msg.c_str(), (int)s->var_name.size())
                    rg_fmt_err(s.line, s.col, msg, p_text_len(s.var_name), (str)null, 0, true);
                    rg_has_errors = true;
                    end;
                }
            }
            !!! A whole struct is copied leaf by leaf only when the target holds the
            !!! object. `head = s` for two `@StmtNode` variables is one address
            !!! written into another, and copying the leaf fields of the struct the
            !!! address names would write hundreds of bytes into the eight that hold
            !!! it.
            if !rg_var_is_struct_ptr(s.var_name) && !pe_eq(sstruct, "")
               && pe_eq(sstruct, tstruct) && s.expr.nk != FUNC_CALL {
                if rg_emit_struct_source_address(s.expr) {
                    str src2 = rg_emit_struct_source_address_out;
                    rg_emit_struct_leaf_copy("(AT " + vname + ")", tstruct, src2);
                    rg_rcode = rg_rcode + "\n";
                    end;
                }
            }
            rg_rcode = rg_rcode + "CAST " + vname + " , ";
            rg_rc_expr(s.expr);
        }
        rg_rcode = rg_rcode + "\n";
    } else if s.nk == INCR {
        !!! Write through a mutable capture cell (by-reference captured var).
        str cref2 = rg_cap_ref_name(s.var_name);
        if !pe_eq(cref2, "") {
            !!! `(s->incr_op == "++") ? "+" : "-"`.
            str r_op = "-";
            if pe_eq(s.incr_op, "++") {
                r_op = "+";
            }
            rg_rcode = rg_rcode + "DREF " + cref2 + " , ((DL " + cref2 + ") , 1 , " + r_op + ")\n";
            end;
        }
        !!! Reference variable increment: x++ -> DREF x, ((DL x), 1, +)
        if rg_is_ref_var(s.var_name) && pe_eq(rg_struct_method_var, "")
           && rg_struct_method_idx == null {
            str r_op2 = "-";
            if pe_eq(s.incr_op, "++") {
                r_op2 = "+";
            }
            rg_rcode = rg_rcode + "DREF " + s.var_name + " , ((DL " + s.var_name + ") , 1 , " + r_op2 + ")\n";
            end;
        }
        !!! ++a -> CAST a, (a, 1, +)   (no _toInt for array compat)
        str r_op3 = "-";
        if pe_eq(s.incr_op, "++") {
            r_op3 = "+";
        }
        str vname2 = s.var_name;
        if !pe_eq(rg_struct_method_var, "") {
            vname2 = rg_emit_fld(rg_struct_method_var, rg_struct_method_type, s.var_name,
                                 false, false, s.line, s.col);
        }
        rg_rcode = rg_rcode + "CAST " + vname2;
        if rg_struct_method_idx != null {
            rg_rcode = rg_rcode + "{";
            rg_rc_expr(rg_struct_method_idx);
            rg_rcode = rg_rcode + "}";
        }
        rg_rcode = rg_rcode + " , (" + vname2;
        if rg_struct_method_idx != null {
            rg_rcode = rg_rcode + "{";
            rg_rc_expr(rg_struct_method_idx);
            rg_rcode = rg_rcode + "}";
        }
        rg_rcode = rg_rcode + " , 1 , " + r_op3 + ")\n";
    } else if s.nk == CALL_FUNC {
        rg_gen_stmt_call(s);
    } else if s.nk == DREF_ASSIGN {
        !!! $ptr = expr -> DREF ptr, expr
        rg_rcode = rg_rcode + "DREF ";
        rg_rcode = rg_rcode + s.var_name;
        rg_rcode = rg_rcode + " , ";
        rg_rc_expr(s.expr);
        rg_rcode = rg_rcode + "\n";
    } else if s.nk == IF_ELSE {
        rg_rcode = rg_rcode + "IF (";
        rg_rc_expr(s.expr);
        rg_rcode = rg_rcode + ") THEN (\n";
        rg_gen_scoped_body(s.true_body);
        rg_rcode = rg_rcode + ") ELSE (\n";
        rg_gen_scoped_body(s.false_body);
        rg_rcode = rg_rcode + ")\n";
    } else if s.nk == WHILE {
        rg_rcode = rg_rcode + "REPEAT ";
        rg_rc_expr(s.expr);
        rg_rcode = rg_rcode + " THEN (\n";
        rg_gen_scoped_body(s.true_body);
        rg_rcode = rg_rcode + ")\n";
    } else if s.nk == TRY_CATCH {
        rg_gen_try_catch(s);
        !!! The handler's variable, for the statements after it (see the DECLARE
        !!! case). the toolchain default-constructs the record, which is INT and the
        !!! zero values of everything else.
        if !pe_eq(s.var_name, "") {
            VarDecl proto2;
            @VarDecl d2;
            malloc(@d2, size proto2);
            d2.ty = INT;
            d2.ptr_depth = 0;
            d2.struct_type = "";
            d2.struct_ptr = false;
            d2.is_array = false;
            d2.is_ref = false;
            d2.is_unsigned = false;
            d2.dims = null;
            d2.n = 0;
            d2.len_expr = null;
            rg_local_decls = rg_vardeclmap_set(rg_local_decls, s.var_name, d2);
        }
    } else if s.nk == THROW {
        rg_gen_throw(s);
    } else if s.nk == DO_WHILE {
        !!! do { body } while cond -> emit body once, then REPEAT
        rg_gen_scoped_body(s.true_body);
        rg_rcode = rg_rcode + "REPEAT ";
        rg_rc_expr(s.expr);
        rg_rcode = rg_rcode + " THEN (\n";
        rg_gen_scoped_body(s.true_body);
        rg_rcode = rg_rcode + ")\n";
    } else if s.nk == BREAK {
        rg_rcode = rg_rcode + "END\n";
    } else if s.nk == CONTINUE {
        rg_rcode = rg_rcode + "CONTINUE\n";
    } else if s.nk == FUNCTION {
        if s.broken {
            end;
        }
        !!! A stub is a declaration only: no body and no declaration statement is
        !!! emitted, so a call that is never implemented is reported by the back end
        !!! as an undefined reference. In the -m mode of a declaration file the
        !!! signature still has to reach the .r, because .bmeta is harvested from
        !!! its FUNC lines.
        if s.is_stub && !rg_stub_sigs {
            end;
        }
        !!! A repeated `#head` inclusion parses a function twice. Writing it twice
        !!! would give the back end two functions of one name whose bodies differ
        !!! (their temporaries are numbered per emission), so the first definition
        !!! is the one that is emitted.
        if rg_set_has(rg_emitted_funcs, s.var_name) {
            end;
        }
        rg_emitted_funcs = rg_set_add(rg_emitted_funcs, s.var_name);
        !!! Function context for the error headers.
        rg_cur_func_name = rg_display_name(s.var_name);
        rg_cur_func_ret = s.func_ret_type;
        rg_cur_func_ret_struct = s.ret_struct;
        rg_cur_func_ret_struct_ptr = s.ret_struct_ptr;
        rg_func_line = s.line;
        rg_func_header = "";
        !!! LOCAL prefix for local functions.
        if s.is_local {
            rg_rcode = rg_rcode + "LOCAL ";
        }
        rg_rcode = rg_rcode + "FUNC " + s.var_name + " ";
        !!! A stub's signature is harvested into .bmeta by the -m mode, and that file
        !!! is the only place the unsigned reading of a Windows value can be kept:
        !!! the type codes have separate entries for `utype int`, `utype longlong`
        !!! and `utype char`. Only the stub signatures of a -m run use those
        !!! spellings - a stub that is compiled normally emits nothing, and the back
        !!! end knows only the signed types.
        bool sig_unsigned = s.is_stub && rg_stub_sigs;
        if s.ret_struct_ptr {
            !!! `@T` return: the caller gets the address the function names, not a
            !!! copy of an object, so the STRUCT marker - which asks the back end to
            !!! copy the object out - must not be written. The method emitter has
            !!! always done this; the plain function path did not, and a
            !!! `@T`-returning function handed back a copy of the pointer slot
            !!! instead of the pointer.
            rg_rcode = rg_rcode + rg_rtype(AT_VOID) + " (";
        } else if !pe_eq(s.ret_struct, "") {
            rg_rcode = rg_rcode + "STRUCT " + s.ret_struct + " (";
        } else if sig_unsigned {
            rg_rcode = rg_rcode + rg_rustype(s.func_ret_type, s.ret_is_unsigned) + " (";
        } else {
            rg_rcode = rg_rcode + rg_rtype(s.func_ret_type) + " (";
        }
        @StrNode pp = s.fparams;
        @VarTypeNode ppt = s.fparam_types;
        @StrNode pps = s.fparam_struct;
        @BoolNode ppa = s.fparam_is_array;
        @BoolNode ppu = s.fparam_is_unsigned;
        bool first_param = true;
        while pp != null {
            if !first_param {
                rg_rcode = rg_rcode + ", ";
            }
            first_param = false;
            !!! `T n` is the object itself and is passed by value; `@T n` is a
            !!! pointer, so its parameter is the address type and the struct name
            !!! only says what it points at.
            bool param_is_ptr = ppt != null && rg_is_at_type(ppt.ty)
                                && pps != null && !pe_eq(pps.s, "");
            if pps != null && !pe_eq(pps.s, "") {
                !!! The .r spells the two apart: STRUCT is the object, STRUCTPTR is
                !!! an address of one. Writing AT_INT for a pointer used to lose the
                !!! struct name, and the body then read the pointer value as if it
                !!! were the object.
                if param_is_ptr {
                    rg_rcode = rg_rcode + "STRUCTPTR ";
                } else {
                    rg_rcode = rg_rcode + "STRUCT ";
                }
                rg_rcode = rg_rcode + pps.s + " " + pp.s;
            } else {
                bool param_unsigned = ppu != null && ppu.v;
                if ppt == null {
                    !!! the toolchain reads `fparam_types[i]` unguarded; a chain that ran
                    !!! out is answered as int here rather than read past its end.
                    rg_rcode = rg_rcode + rg_rtype(INT) + " " + pp.s;
                } else if sig_unsigned {
                    rg_rcode = rg_rcode + rg_rustype(ppt.ty, param_unsigned) + " " + pp.s;
                } else {
                    rg_rcode = rg_rcode + rg_rtype(ppt.ty) + " " + pp.s;
                }
            }
            if ppa != null && ppa.v {
                rg_rcode = rg_rcode + "{}";
            }
            if s.variadic && pp.next == null {
                rg_rcode = rg_rcode + "...";
            }
            pp = pp.next;
            if ppt != null {
                ppt = ppt.next;
            }
            if pps != null {
                pps = pps.next;
            }
            if ppa != null {
                ppa = ppa.next;
            }
            if ppu != null {
                ppu = ppu.next;
            }
        }
        rg_rcode = rg_rcode + ") THEN (\n";
        !!! A stub in -m mode stops here: its signature is the whole declaration, and
        !!! the empty body only keeps the .r well formed.
        if s.is_stub {
            rg_rcode = rg_rcode + ")\n";
            end;
        }
        !!! Re-add the params to syms for code generation (restore the outer values
        !!! on exit).
        rg_cur_func_closures = null;
        rg_cur_func_released = null;
        rg_push_func_params(s);
        !!! Builtin-wrapper forwarding context.
        str saved_annotation = rg_cur_builtin_annotation;
        @StrNode saved_ann_params = rg_cur_builtin_params;
        rg_cur_builtin_annotation = s.builtin_annotation;
        rg_cur_builtin_params = s.fparams;
        !!! Struct locals (and copied struct parameters) of this function live in
        !!! its own scope stack and are destroyed in reverse order when the body
        !!! ends. Parameters are noted first so they are destroyed last (after the
        !!! locals declared in the body).
        @RgStructScope saved_struct_scopes = rg_struct_scopes;
        rg_struct_scopes = null;
        rg_push_struct_scope();
        @StrNode ps2 = s.fparam_struct;
        @StrNode pn3 = s.fparams;
        while pn3 != null {
            if ps2 != null && !pe_eq(ps2.s, "") {
                rg_note_struct_local(pn3.s, ps2.s);
            }
            pn3 = pn3.next;
            if ps2 != null {
                ps2 = ps2.next;
            }
        }
        !!! The parameters are destroyed when the function returns (see
        !!! rg_check_param_dtor_access), which is also where a `destruct` the type
        !!! keeps to itself is refused.
        rg_check_param_dtor_access(s);
        !!! The body gets its own declaration table. Values are resolved while they
        !!! are emitted, so a name that this body declares must win over the
        !!! declaration another body made first: the table of the enclosing scope is
        !!! put aside and restored when the body ends, exactly as the type checking
        !!! walk does it. `_in_func_body` stays off here - emission must not turn a
        !!! name that the type checker accepted into a new "undeclared" error.
        @RgVarDeclMap saved_emit_decls = rg_local_decls;
        rg_local_decls = null;
        rg_gen_body(s.true_body);
        rg_local_decls = saved_emit_decls;
        rg_pop_struct_scope();
        rg_struct_scopes = saved_struct_scopes;
        rg_cur_builtin_annotation = saved_annotation;
        rg_cur_builtin_params = saved_ann_params;
        !!! Restore the symbols shadowed by params.
        rg_pop_func_params();
        if s.func_ret_type == VOID {
            !!! Release local closure objects before returning (void functions
            !!! cannot return a closure, so this is always safe).
            @StrNode cn = rg_cur_func_closures;
            while cn != null {
                if !rg_set_has(rg_cur_func_released, cn.s) {
                    rg_rcode = rg_rcode + "RELEASE " + cn.s + "\n";
                }
                cn = cn.next;
            }
            rg_rcode = rg_rcode + "RET 0\n";
        }
        rg_rcode = rg_rcode + ")\n";
        rg_cur_func_name = "";
        rg_cur_func_ret = VOID;
    } else if s.nk == RETURN {
        !!! Release local closures before returning, unless the return value is (or
        !!! still reads) one of them. Ownership of a returned closure transfers to
        !!! the caller, so it must not be released here. A closure the return
        !!! expression only *calls* is released by the caller of that expression,
        !!! so it has to stay alive as well: the release used to be emitted before
        !!! `RET f(x)` and freed the object the call was about to use.
        str ret_var = "";
        if s.expr != null && s.expr.nk == VAR_REF {
            ret_var = s.expr.var_name;
        }
        @StrNode rc = rg_cur_func_closures;
        while rc != null {
            if !pe_eq(rc.s, ret_var) && !rg_set_has(rg_cur_func_released, rc.s) {
                @RgStrSet one = rg_set_add(null, rc.s);
                if !rg_expr_refs_any(s.expr, one) {
                    rg_rcode = rg_rcode + "RELEASE " + rc.s + "\n";
                    rg_cur_func_released = rg_set_add(rg_cur_func_released, rc.s);
                }
            }
            rc = rc.next;
        }
        !!! Leaving the function destroys the struct locals of every scope it
        !!! exits, innermost first, before the value is returned.
        rg_pop_all_struct_scopes();
        !!! Returning a struct that lives in a field or an array element: its value
        !!! is an address, so copy it into a temporary that the caller copies the
        !!! object out of.
        if s.expr != null && !pe_eq(rg_cur_func_ret_struct, "")
           && !rg_cur_func_ret_struct_ptr {
            str st = rg_expr_struct_type(s.expr);
            !!! Only a value that definitely is not that struct is reported; an
            !!! expression whose struct-ness is unknown is left alone.
            if !pe_eq(st, rg_cur_func_ret_struct)
               && (!pe_eq(st, "") || rgx_scalar_literal_expr(s.expr)) {
                str got2 = st;
                if pe_eq(got2, "") {
                    got2 = rg_type_name(s.expr.result_type);
                }
                str msg2 = "cannot return a '" + got2 + "' value from a function returning '"
                         + rg_cur_func_ret_struct + "'";
                !!! fmt_err(s->line, s->col, msg.c_str(), 6)
                rg_fmt_err(s.line, s.col, msg2, 6, (str)null, 0, true);
                rg_has_errors = true;
                end;
            }
        }
        if s.expr != null && !pe_eq(rg_cur_func_ret_struct, "")
           && !rg_cur_func_ret_struct_ptr
           && pe_eq(rg_expr_struct_type(s.expr), rg_cur_func_ret_struct) {
            bool plain_name = false;
            if s.expr.nk == VAR_REF {
                if rg_vartypemap_find(rg_syms, s.expr.var_name) != null
                   || rg_strmap_find(rg_sym_struct_type, s.expr.var_name) != null {
                    plain_name = true;
                }
            }
            if !plain_name {
                rg_tmp_var_counter = rg_tmp_var_counter + 1;
                str tmp = "__rt" + (str)rg_tmp_var_counter;
                rg_rcode = rg_rcode + "DECLARED STRUCT " + rg_cur_func_ret_struct + " " + tmp + " , {}\n";
                if rg_emit_struct_source_address(s.expr) {
                    str src3 = rg_emit_struct_source_address_out;
                    rg_emit_struct_leaf_copy("(AT " + tmp + ")", rg_cur_func_ret_struct, src3);
                    rg_rcode = rg_rcode + "RET " + tmp + "\n";
                    end;
                }
            }
        }
        !!! A struct returned from a function whose return type is a scalar has to
        !!! be converted explicitly (`return (int)v;`); the conversion itself is
        !!! emitted where it is written.
        if s.expr != null && pe_eq(rg_cur_func_ret_struct, "")
           && rg_cur_func_ret != VOID {
            str st2 = rg_expr_struct_type(s.expr);
            if !pe_eq(st2, "") {
                str msg3 = "cannot return a '" + st2 + "' value from a function returning '"
                         + rg_type_name(rg_cur_func_ret) + "'; convert it explicitly";
                !!! fmt_err(s->line, s->col, msg.c_str(), 6)
                rg_fmt_err(s.line, s.col, msg3, 6, (str)null, 0, true);
                rg_has_errors = true;
                end;
            }
        }
        rg_rcode = rg_rcode + "RET ";
        rg_rc_expr(s.expr);
        rg_rcode = rg_rcode + "\n";
    } else if s.nk == BACK {
        !!! `back expr;` is a lambda return; emitted as RET in the .r body.
        if s.expr != null {
            rg_rcode = rg_rcode + "RET ";
            rg_rc_expr(s.expr);
            rg_rcode = rg_rcode + "\n";
        } else {
            rg_rcode = rg_rcode + "RET 0\n";
        }
    } else if s.nk == END {
        !!! `end;` - early void return (empty return).
        rg_pop_all_struct_scopes();
        rg_rcode = rg_rcode + "RET 0\n";
    } else if s.nk == SWITCH {
        rg_rcode = rg_rcode + "SWITCH (";
        rg_rc_expr(s.expr);
        rg_rcode = rg_rcode + ") THEN (\n";
        !!! the toolchain walks a vector of case bodies with the case expressions beside
        !!! it; this implementation's `case_bodies` is one chain opened by a CASE_MARK
        !!! statement for every arm, so the expressions are walked in step and the
        !!! statements of one arm are the run between two marks. The run is cut out
        !!! of the chain for the call and spliced back, so the destructor scope
        !!! gen_scoped_body opens wraps exactly that arm (the toolchain call is
        !!! gen_scoped_body(s->case_bodies[i])).
        @ExprNode ce = s.case_exprs;
        @StmtNode cnode = s.case_bodies;
        while cnode != null {
            if cnode.nk == CASE_MARK {
                rg_rcode = rg_rcode + "CASE ";
                rg_rc_expr(ce);
                rg_rcode = rg_rcode + ":\n";
                !!! the toolchain indexes `case_exprs[i]`; the two chains are built in step,
                !!! and a chain that ran out is left where it is.
                if ce != null {
                    ce = ce.next;
                }
                @StmtNode run = cnode.next;
                @StmtNode tail = null;
                @StmtNode t = run;
                while t != null && t.nk != CASE_MARK {
                    tail = t;
                    t = t.next;
                }
                if tail == null {
                    !!! An arm with no statements, or a mark that ends the chain:
                    !!! there is nothing for a scope to hold, so the walk goes on at
                    !!! whatever follows the mark.
                    cnode = run;
                    continue;
                }
                @StmtNode afterarm = tail.next;
                tail.next = null;
                rg_gen_scoped_body(run);
                tail.next = afterarm;
                cnode = afterarm;
                continue;
            }
            cnode = cnode.next;
        }
        if s.unmatch_body != null {
            rg_rcode = rg_rcode + "UNMATCH:\n";
            rg_gen_scoped_body(s.unmatch_body);
        }
        rg_rcode = rg_rcode + ")\n";
    } else if s.nk == ENUM {
        !!! ENUM TypeName ( MEM1 val1 MEM2 val2 ... )
        rg_rcode = rg_rcode + "ENUM " + s.var_name + " (\n";
        @StrNode ev = s.fparams;
        while ev != null {
            rg_rcode = rg_rcode + "    " + ev.s;
            longlong eval = p_enum_value(ev.s);
            if p_enum_found {
                rg_rcode = rg_rcode + " " + (str)eval;
            }
            if ev.next != null {
                rg_rcode = rg_rcode + "\n";
            }
            ev = ev.next;
        }
        rg_rcode = rg_rcode + "\n)\n";
    } else if s.nk == STRUCT_DEF {
        rg_gen_stmt_struct(s);
    } else if s.nk == RCODE {
        !!! Raw .r text injected verbatim at this position. The text is copied into
        !!! a local first: a `str` field cannot be subscripted, and the last
        !!! character is what the `rcode_text.back()` asks for.
        str rtext = s.rcode_text;
        rg_rcode = rg_rcode + rtext;
        if !pe_eq(rtext, "") && rtext[pe_len(rtext) - 1] != '\n' {
            rg_rcode = rg_rcode + "\n";
        }
    }
}
