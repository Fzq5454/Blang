#once
!~
 ~  bootstrap/frontend/rgen_stmt_struct.b: the frontend/rgen_stmt_struct.
 ~
 ~  One STRUCT_DEF statement as .r: the object layout, then every method as a real
 ~  function whose first parameter is a struct pointer `this` (STRUCTPTR).
 ~
 ~  A method body is not part of the statement list, so the context the body needs
 ~  is installed around it and taken back afterwards: the expansion context
 ~  (`__this` and the struct's name), the parameters, the names the body declares
 ~  (so a bare name is a field of `this` only when it is not a local), the return
 ~  type, the closure sets, and its own declaration table. Each of those is the same
 ~  save/clear/restore the toolchain does with a copy and a swap; a chain is shared, so the
 ~  port saves the head and puts it back - which is the same thing here because the
 ~  body only ever appends to the chains it is handed.
 ~
 ~  A repeated `#head` inclusion parses the type twice. The methods of the second
 ~  copy would be written again with different temporaries, and the back end cannot
 ~  resolve two functions of one name whose bodies differ, so the first definition
 ~  is the one that is emitted (`_emitted_structs`).
 ~!

#head "rgen"
#head "rgen_heads"

!!! gen_stmt_struct: the layout line first (leaf fields in storage order, bases and
!!! nested structs fully expanded, with absolute offsets), then the methods.
void rg_gen_stmt_struct -> @StmtNode s {
    if rg_set_has(rg_emitted_structs, s.var_name) {
        end;
    }
    rg_emitted_structs = rg_set_add(rg_emitted_structs, s.var_name);
    rg_collect_leaf_fields_out = null;
    rg_collect_leaf_fields_out_visited = null;
    int total = rg_collect_leaf_fields(s.var_name, 0);
    @FlatField leafs = rg_collect_leaf_fields_out;
    rg_rcode = rg_rcode + "STRUCT " + s.var_name + " SIZE " + (str)total + " (";
    @FlatField lf = leafs;
    bool first = true;
    while lf != null {
        int sz = rg_field_byte_size(lf.field);
        if !first {
            rg_rcode = rg_rcode + " , ";
        }
        first = false;
        rg_rcode = rg_rcode + lf.field.name + " " + (str)lf.abs_off + " "
                  + rg_rtype(rg_field_eff_type(lf.field)) + " " + (str)sz;
        lf = lf.next;
    }
    rg_rcode = rg_rcode + " )\n";

    @StructDef sit = p_find_struct(s.var_name);
    if sit != null {
        @StructMethod m = sit.methods;
        while m != null {
            @StmtNode mf = m.fn;
            if mf == null || mf.broken {
                m = m.next;
                continue;
            }
            !!! A `stub` method has no body here: the body is the definition written
            !!! outside the type, and a stub no definition follows stays an unresolved
            !!! name - a call to it is reported by the linker, the way a `stub`
            !!! function's call is.
            if mf.is_stub && mf.true_body == null {
                m = m.next;
                continue;
            }
            !!! The internal name carries the parameter types of a `reload` version,
            !!! so two versions do not collide.
            str mname = mf.var_name;
            if pe_eq(mname, "") {
                mname = m.name;
            }
            str fname = "__m_" + s.var_name + "_" + mname;
            rg_rcode = rg_rcode + "FUNC " + fname + " ";
            if mf.ret_struct_ptr {
                !!! `@T` return: the caller gets a pointer, not the object.
                rg_rcode = rg_rcode + rg_rtype(AT_VOID) + " (";
            } else if !pe_eq(mf.ret_struct, "") {
                rg_rcode = rg_rcode + "STRUCT " + mf.ret_struct + " (";
            } else {
                rg_rcode = rg_rcode + rg_rtype(mf.func_ret_type) + " (";
            }
            rg_rcode = rg_rcode + "STRUCTPTR " + s.var_name + " __this";
            @StrNode pn = mf.fparams;
            @VarTypeNode pt = mf.fparam_types;
            @StrNode ps = mf.fparam_struct;
            while pn != null {
                rg_rcode = rg_rcode + ", ";
                if ps != null && !pe_eq(ps.s, "") {
                    rg_rcode = rg_rcode + "STRUCT " + ps.s + " " + pn.s;
                } else if pt != null {
                    rg_rcode = rg_rcode + rg_rtype(pt.ty) + " " + pn.s;
                } else {
                    !!! the toolchain reads `fparam_types[i]` unconditionally; a chain that
                    !!! ran out is guarded here rather than read past its end.
                    rg_rcode = rg_rcode + rg_rtype(INT) + " " + pn.s;
                }
                pn = pn.next;
                if pt != null {
                    pt = pt.next;
                }
                if ps != null {
                    ps = ps.next;
                }
            }
            rg_rcode = rg_rcode + ") THEN (\n";

            str saved_var = rg_struct_method_var;
            str saved_type = rg_struct_method_type;
            rg_struct_method_var = "__this";
            rg_struct_method_type = s.var_name;
            !!! Register the method's parameters, so the body can tell a struct
            !!! parameter from a plain value (`who = x`).
            rg_push_func_params(mf);
            !!! A method body is not part of the statement list, so its parameter
            !!! names never reached the non-global set the lambda capture analysis
            !!! reads. Mark them here, the way rg_register_funcs does for a plain
            !!! function's parameters.
            @StrNode pn2 = mf.fparams;
            while pn2 != null {
                rg_non_global_syms = rg_set_add(rg_non_global_syms, pn2.s);
                pn2 = pn2.next;
            }
            !!! Remember which names the body declares: a bare name is a field of
            !!! `this` only when it is not a local.
            @RgStrSet saved_locals = rg_method_locals;
            rg_method_locals = null;
            rg_collect_declare_names_out = null;
            rg_collect_declare_names(mf.true_body);
            @StrNode ln = rg_collect_declare_names_out;
            while ln != null {
                rg_method_locals = rg_set_add(rg_method_locals, ln.s);
                ln = ln.next;
            }
            !!! The method's own return type, so `return <field>;` knows which
            !!! struct it has to return.
            VarType saved_ret = rg_cur_func_ret;
            str saved_ret_struct = rg_cur_func_ret_struct;
            bool saved_ret_struct_ptr = rg_cur_func_ret_struct_ptr;
            rg_cur_func_ret = mf.func_ret_type;
            rg_cur_func_ret_struct = mf.ret_struct;
            rg_cur_func_ret_struct_ptr = mf.ret_struct_ptr;
            !!! Local closures are tracked per body. A method body does not go
            !!! through the FUNC statement path that clears these sets, so without
            !!! this a closure of the previous method was still listed and its
            !!! RELEASE was written into a body that never declared it.
            @StrNode saved_closures = rg_cur_func_closures;
            @RgStrSet saved_released = rg_cur_func_released;
            rg_cur_func_closures = null;
            rg_cur_func_released = null;
            !!! A method body is its own scope for declarations as well: the locals
            !!! of the body emitted before it must not decide the types this one
            !!! reads, so its table starts empty and the enclosing one is put back
            !!! when the method ends.
            @RgVarDeclMap saved_decls = rg_local_decls;
            rg_local_decls = null;
            if !pe_eq(mf.synth_op, "") {
                !!! `int operator ==;` with no body: every field of the type is
                !!! compared, one leaf at a time.
                str other = "b";
                if mf.fparams != null {
                    other = mf.fparams.s;
                }
                rg_emit_synth_comparison(s.var_name, other, mf.synth_op);
            } else {
                !!! The body never went through the resolve passes (it is not in the
                !!! statement list), so a lambda literal in it was never registered:
                !!! register the body's lambdas here, with the method's scope in
                !!! place, so their hidden functions are emitted with the others.
                rg_resolve_body_lambdas(mf.true_body);
                !!! Method body is its own scope: struct locals declared in it are
                !!! destroyed before the method returns.
                rg_gen_scoped_body(mf.true_body);
            }
            rg_local_decls = saved_decls;
            rg_cur_func_ret = saved_ret;
            rg_cur_func_ret_struct = saved_ret_struct;
            rg_cur_func_ret_struct_ptr = saved_ret_struct_ptr;
            rg_method_locals = saved_locals;
            rg_pop_func_params();
            rg_struct_method_var = saved_var;
            rg_struct_method_type = saved_type;
            if mf.func_ret_type == VOID {
                !!! A void method cannot hand a closure back, so whatever local
                !!! closure it still owns is released before it returns.
                @StrNode c = rg_cur_func_closures;
                while c != null {
                    if !rg_set_has(rg_cur_func_released, c.s) {
                        rg_rcode = rg_rcode + "RELEASE " + c.s + "\n";
                    }
                    c = c.next;
                }
                rg_rcode = rg_rcode + "RET 0\n";
            }
            rg_cur_func_closures = saved_closures;
            rg_cur_func_released = saved_released;
            rg_rcode = rg_rcode + ")\n";
            m = m.next;
        }
    }
}
