#once
!~
 ~  bootstrap/frontend/rgen_stmt_declare.b: the frontend/rgen_stmt_declare.
 ~
 ~  One DECLARE statement as .r. A struct variable becomes a single contiguous
 ~  object written by leaf fields (the inherited ones flattened first, bases in
 ~  order, each at its byte offset), which is the `DECLARED STRUCT T name, { ... }`
 ~  form; a `@T p` is an ordinary pointer and takes the scalar path instead. The
 ~  object is registered with the enclosing scope (note_struct_local) so its
 ~  `destruct` body runs when that scope ends, and the struct's `init` constructor
 ~  is inlined right after the field initialization.
 ~
 ~  the toolchain calls collect_leaf_fields with a fresh local vector and set; in this implementation
 ~  those are the out globals rg_collect_leaf_fields_out and
 ~  rg_collect_leaf_fields_out_visited, so they are cleared before the call - the
 ~  callee appends to them, exactly as the toolchain callee appends to the containers its
 ~  caller made.
 ~!

#head "rgen"
#head "rgen_heads"

!!! gen_stmt_declare: the statement. An `nf` of zero with an initializer list is
!!! the one shape the toolchain would divide by in `leafs[k % nf]`; that cannot be reached
!!! here either, since a declaration whose type the parser knows always has at least
!!! one leaf field.
void rg_gen_stmt_declare -> @StmtNode s {
    if !pe_eq(s.struct_type, "") && s.ptr_depth == 0 {
        !!! `@T p` holds the address of a T: it is an ordinary pointer, not the
        !!! object itself, and it takes the scalar path below.
        !!! Expand the struct variable into one contiguous object. Inherited fields
        !!! are flattened first, then the own ones.
        !!! Register the object with the enclosing scope so its `destruct` body runs
        !!! when that scope ends. (Struct arrays are not destroyed.)
        if !s.is_array {
            rg_note_struct_local(s.var_name, s.struct_type);
        }
        @StructDef sit = p_find_struct(s.struct_type);
        if sit != null {
            rg_collect_leaf_fields_out = null;
            rg_collect_leaf_fields_out_visited = null;
            !!! The answer of collect_leaf_fields is the byte size of the object,
            !!! which this caller does not ask for (the toolchain drops it too).
            rg_collect_leaf_fields(s.struct_type, 0);
            @FlatField leafs = rg_collect_leaf_fields_out;
            int nf = 0;
            @FlatField lc = leafs;
            while lc != null {
                nf = nf + 1;
                lc = lc.next;
            }
            !!! An initializer list gives one value per leaf, which cannot describe
            !!! the elements of an inline array field.
            if s.array_init != null {
                @FlatField lf = leafs;
                while lf != null {
                    if lf.field.array_dim > 0 && lf.field.ty != CHAR {
                        str msg = "initializer list cannot be used with the array field '"
                                + lf.field.name + "'; assign its elements one by one";
                        !!! `s->var_line ? s->var_line : s->line` and the same for the
                        !!! column: the position of the name when it has one.
                        int el = s.line;
                        if s.var_line != 0 {
                            el = s.var_line;
                        }
                        int ec = s.col;
                        if s.var_col != 0 {
                            ec = s.var_col;
                        }
                        !!! fmt_err(el, ec, msg.c_str(), (int)s->var_name.size())
                        rg_fmt_err(el, ec, msg, p_text_len(s.var_name), (str)null, 0, true);
                        rg_has_errors = true;
                        skip;
                    }
                    lf = lf.next;
                }
            }
            rg_rcode = rg_rcode + "DECLARED STRUCT " + s.struct_type + " " + s.var_name;
            if s.is_array {
                rg_rcode = rg_rcode + "{";
                if s.array_dims != null {
                    rg_rcode = rg_rcode + (str)s.array_dims.v;
                }
                rg_rcode = rg_rcode + "}";
            }
            rg_rcode = rg_rcode + " , {";
            int init_n = nf;
            if s.is_array {
                init_n = 0;
                @ExprNode ai0 = s.array_init;
                while ai0 != null {
                    init_n = init_n + 1;
                    ai0 = ai0.next;
                }
            }
            @ExprNode ai = s.array_init;
            int k = 0;
            while k < init_n {
                if k > 0 {
                    rg_rcode = rg_rcode + " , ";
                }
                if ai != null {
                    rg_rc_expr(ai);
                    ai = ai.next;
                } else if nf > 0 {
                    !!! `leafs[k % nf]`: the fields are cycled once the initializer
                    !!! list is used up, so the k-th slot is that leaf. A chain has
                    !!! no index, so it is walked to it.
                    @FlatField f = leafs;
                    int li = k % nf;
                    int lj = 0;
                    while lj < li {
                        f = f.next;
                        lj = lj + 1;
                    }
                    VarType ft = rg_field_eff_type(f.field);
                    if ft == INT || ft == FLOAT || ft == CHAR {
                        rg_rcode = rg_rcode + "0";
                    } else if ft == STR {
                        rg_rcode = rg_rcode + "\"\"";
                    } else if ft == BOOL {
                        rg_rcode = rg_rcode + "false";
                    } else {
                        rg_rcode = rg_rcode + "null";
                    }
                }
                k = k + 1;
            }
            rg_rcode = rg_rcode + "}\n";
            !!! `Inner q = p;`: a struct initialized from another struct value is
            !!! copied field by field (the declaration above zeroed it).
            rg_emit_struct_decl_copy(s);
            !!! Run the struct's `init` constructor (if any) after field
            !!! initialization. The init body sees fields as bare names via the
            !!! struct-method expansion context.
            @StmtNode initf = sit.init_func;
            if initf != null && initf.true_body != null && !s.is_array {
                str saved_var = rg_struct_method_var;
                str saved_type = rg_struct_method_type;
                @ExprNode saved_idx = rg_struct_method_idx;
                rg_struct_method_var = s.var_name;
                !!! `initf->struct_type.empty() ? s->struct_type : initf->struct_type`.
                rg_struct_method_type = s.struct_type;
                if !pe_eq(initf.struct_type, "") {
                    rg_struct_method_type = initf.struct_type;
                }
                rg_struct_method_idx = null;
                !!! The constructor body is its own scope: struct locals it declares
                !!! are destroyed when the constructor returns.
                rg_gen_scoped_body(initf.true_body);
                rg_struct_method_var = saved_var;
                rg_struct_method_type = saved_type;
                rg_struct_method_idx = saved_idx;
            }
        }
    } else {
        if !s.is_array && (s.decl_type == FUNC || s.decl_type == AT_FUNC) {
            rg_cur_func_closures = rg_strchain_append(rg_cur_func_closures, s.var_name);
        }
        rg_rcode = rg_rcode + "DECLARED " + rg_rtype_depth(s.decl_type, s.ptr_depth) + " " + s.var_name;
        if s.is_array {
            rg_rcode = rg_rcode + "{";
            if s.array_dims != null {
                @IntNode di = s.array_dims;
                bool first = true;
                while di != null {
                    if !first {
                        rg_rcode = rg_rcode + ", ";
                    }
                    first = false;
                    if di.v > 0 {
                        rg_rcode = rg_rcode + (str)di.v;
                    }
                    di = di.next;
                }
            } else if s.array_len_expr != null {
                rg_rc_expr(s.array_len_expr);
            }
            rg_rcode = rg_rcode + "}";
        }
        if s.is_array && s.array_init != null {
            rg_rcode = rg_rcode + " , {";
            @ExprNode ai2 = s.array_init;
            bool first2 = true;
            while ai2 != null {
                if !first2 {
                    rg_rcode = rg_rcode + ", ";
                }
                first2 = false;
                rg_rc_expr(ai2);
                ai2 = ai2.next;
            }
            rg_rcode = rg_rcode + "}";
        } else if !s.is_array {
            rg_rcode = rg_rcode + " , ";
            if s.expr != null && s.decl_is_ref {
                rg_rcode = rg_rcode + "(AT ";
                rg_rc_expr(s.expr);
                rg_rcode = rg_rcode + ")";
            } else if s.expr != null {
                rg_rc_expr(s.expr);
            } else {
                !!! The zero value of the declared type, which is the toolchain switch over
                !!! `s->decl_type`; VOID writes nothing at all.
                if s.decl_type == INT || s.decl_type == LONG || s.decl_type == FLOAT {
                    rg_rcode = rg_rcode + "0";
                } else if s.decl_type == STR {
                    rg_rcode = rg_rcode + "\"\"";
                } else if s.decl_type == BOOL {
                    rg_rcode = rg_rcode + "false";
                } else if s.decl_type == CHAR {
                    rg_rcode = rg_rcode + "0";
                } else if s.decl_type == VOID {
                    !!! nothing
                } else if s.decl_type == ANY {
                    rg_rcode = rg_rcode + "0";
                } else {
                    rg_rcode = rg_rcode + "null";
                }
            }
        }
        rg_rcode = rg_rcode + "\n";
    }
}
