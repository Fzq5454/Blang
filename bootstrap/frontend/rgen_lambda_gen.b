#once
!~
 ~  bootstrap/frontend/rgen_lambda_gen.b: the frontend/rgen_lambda_gen.
 ~
 ~  The .r text of one hidden lambda function: the FUNC line with the capture
 ~  parameters first - a capture that is written through is handed the address of
 ~  the variable (at_of), a snapshot the value itself - then the lambda's own
 ~  parameters, where an array parameter carries the `{}` marker, then `THEN (`, the
 ~  body produced by the ordinary body generator, and the closing `)`. A closure
 ~  whose body hands nothing back writes `RET 0` before the close.
 ~
 ~  While the body is generated the capture tables say what a captured name means
 ~  inside it: _capture_map maps the captured variable to its `__cap_N` parameter
 ~  and _capture_by_ref says whether that parameter is an address. The tables that
 ~  were in effect (those of an enclosing lambda) are put aside and come back
 ~  afterwards, which is why the two chains are saved and restored around the body.
 ~
 ~  The pieces of the literal are read from its LambdaRec (p_find_lambda), the way
 ~  ast.b keeps them: a lambda body is a statement list and an expression node
 ~  cannot name one. The record of a registered literal always exists, so the guard
 ~  below cannot fire; it keeps a node without one from writing a half signature.
 ~!

#head "rgen"

void rg_gen_lambda_function -> @ExprNode n {
    @LambdaRec rec = p_find_lambda(n.lambda_id);
    if rec == null {
        end;
    }
    str fname = n.var_name;
    rg_rcode = rg_rcode + "FUNC " + fname + " " + rg_rtype(rec.ret_type) + " (";
    bool first = true;
    @StrNode cap = rec.captures;
    @VarTypeNode ct = rec.capture_types;
    @BoolNode cbr = rec.capture_by_ref;
    int ci = 0;
    while cap != null {
        if !first {
            rg_rcode = rg_rcode + ", ";
        }
        first = false;
        VarType cty = INT;
        if ct != null {
            cty = ct.ty;
        }
        bool byref = rec.immediate;
        if cbr != null {
            byref = cbr.v;
        }
        VarType pt = cty;
        if byref {
            pt = rg_at_of(cty);
        }
        rg_rcode = rg_rcode + rg_rtype(pt) + " __cap_" + (str)ci;
        cap = cap.next;
        if ct != null {
            ct = ct.next;
        }
        if cbr != null {
            cbr = cbr.next;
        }
        ci = ci + 1;
    }
    @StrNode lp = rec.params;
    @VarTypeNode lpt = rec.param_types;
    @BoolNode lpa = rec.param_is_array;
    while lp != null {
        if !first {
            rg_rcode = rg_rcode + ", ";
        }
        first = false;
        VarType pty = INT;
        if lpt != null {
            pty = lpt.ty;
        }
        rg_rcode = rg_rcode + rg_rtype(pty) + " " + lp.s;
        if lpa != null && lpa.v {
            rg_rcode = rg_rcode + "{}";
        }
        lp = lp.next;
        if lpt != null {
            lpt = lpt.next;
        }
        if lpa != null {
            lpa = lpa.next;
        }
    }
    rg_rcode = rg_rcode + ") THEN (\n";

    !!! Save/restore the active capture map around body generation.
    @RgStrMap saved_map = rg_capture_map;
    @RgBoolMap saved_ref = rg_capture_by_ref;
    rg_capture_map = null;
    rg_capture_by_ref = null;
    @StrNode cap2 = rec.captures;
    @BoolNode cbr2 = rec.capture_by_ref;
    int ci2 = 0;
    while cap2 != null {
        rg_capture_map = rg_strmap_set(rg_capture_map, cap2.s, "__cap_" + (str)ci2);
        bool cref = rec.immediate;
        if cbr2 != null {
            cref = cbr2.v;
        }
        rg_capture_by_ref = rg_boolmap_set(rg_capture_by_ref, cap2.s, cref);
        cap2 = cap2.next;
        if cbr2 != null {
            cbr2 = cbr2.next;
        }
        ci2 = ci2 + 1;
    }
    str saved_lambda = rg_cur_lambda_name;
    rg_cur_lambda_name = fname;

    rg_gen_body(rec.body);

    rg_capture_map = saved_map;
    rg_capture_by_ref = saved_ref;
    rg_cur_lambda_name = saved_lambda;

    if rec.ret_type == VOID {
        rg_rcode = rg_rcode + "RET 0\n";
    }
    rg_rcode = rg_rcode + ")\n";
}
