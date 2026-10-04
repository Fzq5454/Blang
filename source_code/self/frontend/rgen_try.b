#once
!~
 ~  bootstrap/frontend/rgen_try.b: the frontend/rgen_try.
 ~
 ~  `try { } exception (e) { }` and `throw expr;`, the two statements the back end
 ~  does the work for: it builds an exception frame around the try body, runs a
 ~  vectored exception handler that catches any fault and resumes in the CATCH
 ~  block. The code reaches the handler through the variable `CATCH` names, when the
 ~  source asked for one - the variable is optional, so `CATCH ( ... )` runs the
 ~  handler without one.
 ~
 ~  Both bodies are emitted through gen_scoped_body (rgen_dtor.b), so the struct
 ~  locals a body declares are destroyed when the body ends.
 ~!

#head "rgen"
#head "rgen_heads"

!!! gen_try_catch: the .r `TRY ( ... ) CATCH [code] ( ... )` form. The handler's
!!! variable name is written only when the source declared one.
void rg_gen_try_catch -> @StmtNode s {
    rg_rcode = rg_rcode + "TRY (\n";
    rg_gen_scoped_body(s.true_body);
    rg_rcode = rg_rcode + ") CATCH";
    if !pe_eq(s.var_name, "") {
        rg_rcode = rg_rcode + " " + s.var_name;
    }
    rg_rcode = rg_rcode + " (\n";
    rg_gen_scoped_body(s.false_body);
    rg_rcode = rg_rcode + ")\n";
}

!!! gen_throw: `throw expr;` -> .r `RAISE expr`. The back end raises the code at
!!! runtime, which the innermost TRY around it catches.
void rg_gen_throw -> @StmtNode s {
    rg_rcode = rg_rcode + "RAISE ";
    rg_rc_expr(s.expr);
    rg_rcode = rg_rcode + "\n";
}
