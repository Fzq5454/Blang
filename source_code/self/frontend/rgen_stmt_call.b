#once
!~
 ~  bootstrap/frontend/rgen_stmt_call.b: the frontend/rgen_stmt_call.
 ~
 ~  One CALL_FUNC statement as .r. Four shapes reach here and each is emitted its
 ~  own way: `super.method()`, a method call on a nested object
 ~  (`this.field.method(...)`, the receiver's address becoming the hidden `this`),
 ~  a method call on a name that is a struct (a variable, a type name for
 ~  `Type.method()`, or a bare field of the enclosing method's struct), and
 ~  everything left - an implicit `this.method()` inside a method body, a BLANG_API
 ~  call, an indirect call through a `func`/`@func` value, and a plain `CALL`.
 ~
 ~  The receiver of every method call is the first entry of `s->args` in the toolchain; in
 ~  this implementation that is the head of the `s.args` chain, and the call arguments are the
 ~  tail of the same chain. the toolchain copies them into a fresh vector for
 ~  emit_bapi_stmt; this implementation hands that function the tail, which it only reads.
 ~!

#head "rgen"
#head "rgen_heads"

!!! gen_stmt_call: the CALL_FUNC statement. The one thing all four shapes have in
!!! common is the newline the toolchain writes once, after the whole decision.
void rg_gen_stmt_call -> @StmtNode s {
    if s.is_super {
        !!! super.method(): resolve against the parent types only.
        @StmtNode mf = rg_resolve_method_func(rg_struct_method_type, s.var_name, false);
        if mf != null {
            !!! The base method is reached through the object being built or used: the
            !!! base sub-object stands at offset 0 of it, so its address is the
            !!! object's own. A method of the base that the base keeps to itself may
            !!! not be reached from a derived type.
            !!! `mf->struct_type.empty() ? struct_method_type : mf->struct_type`.
            str mdt = rg_struct_method_type;
            if !pe_eq(mf.struct_type, "") {
                mdt = mf.struct_type;
            }
            int sacc_line = s.line;
            if s.var_line != 0 {
                sacc_line = s.var_line;
            }
            int sacc_col = s.col;
            if s.var_col != 0 {
                sacc_col = s.var_col;
            }
            rg_check_member_access(mdt, s.var_name, mf.access, sacc_line, sacc_col);
            if mf.fparams != null {
                !!! A method that takes parameters is called. Expanding its body in
                !!! place left the parameter names dangling in the `.r` -
                !!! `super.setName("Amy")` emitted the body with `newName` written
                !!! and nothing bound to it.
                !!! `__this` is the STRUCTPTR the method body is given; any other name
                !!! is the object itself - an init or destruct body inlined where the
                !!! object was declared - so the address of it is what the call takes.
                str self = "(AT " + rg_struct_method_var + ")";
                if pe_eq(rg_struct_method_var, "__this") {
                    self = rg_struct_method_var;
                }
                rg_rcode = rg_rcode + "CALL __m_" + mdt + "_" + mf.var_name + " " + self;
                @ExprNode sa = s.args;
                if sa != null {
                    sa = sa.next;
                }
                while sa != null {
                    rg_rcode = rg_rcode + " , ";
                    rg_emit_call_arg_value(sa);
                    sa = sa.next;
                }
            } else {
                !!! A method that takes none is expanded in place, which is what this
                !!! path always did.
                str saved = rg_struct_method_type;
                rg_struct_method_type = mdt;
                rg_gen_body(mf.true_body);
                rg_struct_method_type = saved;
            }
        } else {
            @StmtNode bm = rg_resolve_bapi_method(rg_struct_method_type, s.var_name, false);
            if bm != null {
                @ExprNode ca = null;
                if s.args != null {
                    ca = s.args.next;
                }
                rg_emit_bapi_stmt(bm, ca, true);
            } else {
                str msg = "super has no method '" + s.var_name + "'";
                !!! fmt_err(s->var_line ? s->var_line : s->line,
                !!!         s->var_col ? s->var_col : s->col, msg.c_str(),
                !!!         (int)s->var_name.size()): the defaults are
                !!!         "no suggestion, column 0, show the tilde".
                int err_line = s.line;
                if s.var_line != 0 {
                    err_line = s.var_line;
                }
                int err_col = s.col;
                if s.var_col != 0 {
                    err_col = s.var_col;
                }
                rg_fmt_err(err_line, err_col, msg, p_text_len(s.var_name), (str)null, 0, true);
                rg_has_errors = true;
            }
        }
    } else if s.is_method_call && s.args != null &&
              (s.args.nk == MEMBER_ACCESS || s.args.nk == FIELD_ELEM ||
               s.args.nk == ARRAY_ACCESS || s.args.nk == FUNC_CALL) {
        !!! Method call on a nested object: `this.field.method(...)` /
        !!! `obj.field.field.method(...)`. The receiver's address becomes the hidden
        !!! `this` argument.
        bool have_recv = rg_receiver_info(s.args, false);
        str stype = rg_receiver_info_out_stype;
        if have_recv && !pe_eq(stype, "") {
            @StmtNode mf = rg_resolve_method_func(stype, s.var_name, true);
            if mf != null {
                if rg_emit_receiver_address(s.args) {
                    str self = rg_emit_receiver_address_out;
                    !!! `mf->struct_type.empty() ? stype : mf->struct_type`.
                    str mdt = stype;
                    if !pe_eq(mf.struct_type, "") {
                        mdt = mf.struct_type;
                    }
                    rg_rcode = rg_rcode + "CALL __m_" + mdt + "_" + mf.var_name + " " + self;
                    @ExprNode a = s.args.next;
                    while a != null {
                        rg_rcode = rg_rcode + " , ";
                        rg_emit_call_arg_value(a);
                        a = a.next;
                    }
                }
            } else {
                !!! BLANG_API method: it expands into direct calls, so it does not
                !!! need the receiver's address.
                @StmtNode bm = rg_resolve_bapi_method(stype, s.var_name, true);
                if bm != null {
                    @ExprNode ca = s.args.next;
                    rg_emit_bapi_stmt(bm, ca, true);
                }
            }
        }
    } else if s.is_method_call && s.args != null && s.args.nk == VAR_REF &&
              (rg_is_struct_method(s.var_name, s.args.var_name) ||
               !pe_eq(rg_receiver_struct_type(s.args), "")) {
        str sv = s.args.var_name;
        !!! The receiver's struct type: a variable of the type, the type name itself,
        !!! or a bare field of the enclosing method's struct.
        str stype = rg_receiver_struct_type(s.args);
        if pe_eq(stype, "") {
            stype = sv;
        }
        if !pe_eq(stype, "") {
            !!! Regular method, walking the inheritance chain.
            @StmtNode mf = rg_resolve_method_func(stype, s.var_name, true);
            if mf != null {
                !!! fmt_err(s->var_line ? s->var_line : s->line,
                !!!         s->var_col ? s->var_col : s->col, ...): the position of the
                !!!         call is the one the receiver carries when it has one.
                int acc_line = s.line;
                if s.var_line != 0 {
                    acc_line = s.var_line;
                }
                int acc_col = s.col;
                if s.var_col != 0 {
                    acc_col = s.var_col;
                }
                rg_check_member_access(mf.struct_type, s.var_name, mf.access, acc_line, acc_col);
                !!! A call to the method's hidden function.
                !!! `mf->struct_type.empty() ? stype : mf->struct_type`.
                str dt = stype;
                if !pe_eq(mf.struct_type, "") {
                    dt = mf.struct_type;
                }
                str fname = "__m_" + dt + "_" + mf.var_name;
                !!! A bare field of the enclosing method's struct has no variable of
                !!! its own: its address is inside `this`. A `@T` receiver already
                !!! holds the address and is passed on as it stands.
                str self = "";
                if s.args.ptr_depth > 0 || rg_name_is_pointer(sv) {
                    self = sv;
                } else if rg_this_field_address(sv) {
                    self = rg_this_field_address_out;
                } else {
                    self = "(AT " + sv + ")";
                }
                rg_rcode = rg_rcode + "CALL " + fname + " " + self;
                @ExprNode a = s.args.next;
                while a != null {
                    rg_rcode = rg_rcode + " , ";
                    rg_emit_call_arg_value(a);
                    a = a.next;
                }
            } else {
                !!! BAPI method, walking the inheritance chain.
                @StmtNode bm = rg_resolve_bapi_method(stype, s.var_name, true);
                if bm != null {
                    @ExprNode ca = s.args.next;
                    rg_emit_bapi_stmt(bm, ca, true);
                }
            }
        }
    } else {
        bool handled = false;
        !!! Implicit method call inside a method body: a bare `method()` is
        !!! `this.method()`.
        if !pe_eq(rg_struct_method_var, "") {
            @StmtNode imf = rg_resolve_method_func(rg_struct_method_type, s.var_name, true);
            if imf != null {
                int acc_line2 = s.line;
                if s.var_line != 0 {
                    acc_line2 = s.var_line;
                }
                int acc_col2 = s.col;
                if s.var_col != 0 {
                    acc_col2 = s.var_col;
                }
                rg_check_member_access(imf.struct_type, s.var_name, imf.access, acc_line2, acc_col2);
                !!! `imf->struct_type.empty() ? struct_method_type : imf->struct_type`.
                str dt = rg_struct_method_type;
                if !pe_eq(imf.struct_type, "") {
                    dt = imf.struct_type;
                }
                str fname = "__m_" + dt + "_" + imf.var_name;
                rg_rcode = rg_rcode + "CALL " + fname + " " + rg_struct_method_var;
                @ExprNode a0 = s.args;
                while a0 != null {
                    rg_rcode = rg_rcode + " , ";
                    rg_emit_call_arg_value(a0);
                    a0 = a0.next;
                }
                handled = true;
            }
        }
        if !handled {
            !!! A BLANG_API function of the parser's table, an indirect call through
            !!! a `func`/`@func` value, or a plain call.
            @StmtNode bdef = p_find_bapi(s.var_name);
            if bdef != null {
                rg_emit_bapi_stmt(bdef, s.args, false);
            } else if rg_is_callable_var(s.var_name) {
                rg_rcode = rg_rcode + "ICALL " + s.var_name;
                @ExprNode ai = s.args;
                while ai != null {
                    rg_rcode = rg_rcode + " , ";
                    rg_emit_call_arg_value(ai);
                    ai = ai.next;
                }
            } else {
                rg_rcode = rg_rcode + "CALL " + rg_resolve_call_name(s.var_name);
                int i = 0;
                @ExprNode a2 = s.args;
                while a2 != null {
                    rg_rcode = rg_rcode + " ";
                    if a2.spread {
                        rg_rcode = rg_rcode + "(SPREAD ";
                        rg_rc_expr(a2);
                        rg_rcode = rg_rcode + ")";
                    } else if !pe_eq(a2.struct_type, "") {
                        rg_emit_call_arg_value(a2);
                    } else if rg_is_ref_param(s.var_name, i) {
                        if a2.nk == VAR_REF && rg_is_ref_var(a2.var_name) {
                            !!! already a reference (pointer)
                            rg_rcode = rg_rcode + a2.var_name;
                        } else {
                            rg_rcode = rg_rcode + "(AT ";
                            rg_rc_expr(a2);
                            rg_rcode = rg_rcode + ")";
                        }
                    } else {
                        rg_rc_expr(a2);
                    }
                    if a2.next != null {
                        rg_rcode = rg_rcode + " ,";
                    }
                    a2 = a2.next;
                    i = i + 1;
                }
            }
        }
    }
    rg_rcode = rg_rcode + "\n";
}
