#once
!~
 ~  bootstrap/frontend/rgen_generate.b: the frontend/rgen_generate.
 ~
 ~  The entry point of the whole code generator and the order of its passes. It
 ~  reads `rg_stmts`, the top-level statement chain the driver put the parsed
 ~  program in (the toolchain reads `parser.statements()`), and answers the .r text in
 ~  `rg_rcode`.
 ~
 ~  the toolchain holds one live reference to the statement vector, so every pass that
 ~  inserted statements into it (the packages, the generic structs, the converting
 ~  constructor wrappers, the template clones, the hidden `static` globals) was seen
 ~  by the loops and the passes that come after it. this implementation keeps the same
 ~  contract: a pass that can insert answers the possibly-new head of the
 ~  chain, and every such call writes it back to `rg_stmts`, so the passes that only
 ~  rewrite nodes in place - and rg_emit_r_code, which reads `rg_stmts` again - see
 ~  the same chain the toolchain reference gave them. The chain below is therefore never
 ~  cached in a local across a pass that can insert.
 ~!

#head "rgen"
#head "rgen_heads"

!!! generate: the passes, in the order the toolchain runs them. Each comment names the
!!! pass and why it stands where it does; the file it lives in is the module of the
!!! same name.
str rg_generate {
    rg_has_errors = false;
    int t = time_now();

    !!! Packages are flattened first: their members have to be ordinary top-level
    !!! declarations before any other pass looks at them.
    rg_stmts = rg_expand_packages(rg_stmts);
    time_print("  packages", time_now() - t);

    !!! `attribute <object>: <NAME>`: what the source told the compiler, checked
    !!! here and applied before the declarations are collected so a type attribute
    !!! is on the declaration whose type is being recorded.
    rg_apply_attr_checks();

    !!! Generic structs are instantiated first: their concrete names have to be in
    !!! the type slots before variables and functions are collected.
    t = time_now();
    rg_stmts = rg_materialize_struct_templates(rg_stmts);
    !!! The generated function of every converting constructor, before the
    !!! declarations are collected so its local object is known as a struct.
    rg_stmts = rg_materialize_ctor_wrappers(rg_stmts);
    rg_validate_inheritance();
    rg_collect_declared_vars();
    rg_register_funcs();
    time_print("  structs and registration", time_now() - t);

    t = time_now();
    rg_stmts = rg_instantiate_templates(rg_stmts);
    !!! Cloned template bodies may themselves use a generic struct (`Box(T)` inside
    !!! a function template), which the second round resolves.
    rg_stmts = rg_materialize_struct_templates(rg_stmts);
    !!! A struct the second round instantiated may declare a converting constructor
    !!! of its own.
    rg_stmts = rg_materialize_ctor_wrappers(rg_stmts);
    time_print("  templates", time_now() - t);

    !!! `a + b` on a struct type becomes a method call before any later pass looks
    !!! at the expression, so the call machinery handles it unchanged.
    t = time_now();
    rg_rewrite_operators(rg_stmts);
    time_print("  operators", time_now() - t);

    t = time_now();
    rg_register_builtins(rg_stmts);
    @StmtNode s = rg_stmts;
    while s != null {
        rg_normalize_stmt(s);
        s = s.next;
    }
    time_print("  builtins and normalize", time_now() - t);

    t = time_now();
    rg_rewrite_builtin_forward(rg_stmts);
    !!! Names with several `reload` versions are resolved to the matching version
    !!! before anything looks at arity or parameter types.
    rg_resolve_overloads(rg_stmts);
    !!! The chosen version is known now, so an argument that is a struct with a
    !!! conversion for a scalar parameter is passed as the converted value.
    rg_wrap_overload_args(rg_stmts);
    time_print("  overloads", time_now() - t);

    !!! `static` storage is materialized here: every function of the file exists by
    !!! now (an instantiated template included), and the guard the pass builds is
    !!! then type checked and emitted like any other statement. What it needs from
    !!! the passes above is already done: the initializer expression was rewritten
    !!! and its arguments normalized while it was still a declaration.
    t = time_now();
    rg_stmts = rg_materialize_static_locals(rg_stmts);
    time_print("  static locals", time_now() - t);

    !!! An `introduce` body is only resolved on instantiation, so a name in a
    !!! template that no instantiation resolved was never checked. Running after
    !!! every instantiation round keeps a resolved template out of the check, so its
    !!! errors are reported once, with the instantiated function header.
    t = time_now();
    rg_check_template_bodies();
    time_print("  template bodies", time_now() - t);

    t = time_now();
    rg_typecheck_pass();
    time_print("  typecheck", time_now() - t);
    !!! `_param_sym_stack.empty()`: the check drains the stack of saved parameter
    !!! symbol values before the passes that follow read the symbol tables.
    while rg_param_sym_stack != null {
        rg_pop_func_params();
    }
    !!! `rule <NAME>(...)`: the checks the program asked for, run once what the
    !!! statements call is settled (the passes above have rewritten the
    !!! expressions) and before the rest of the validation reports on them.
    rg_apply_rules();
    !!! `const` is a promise about the rest of the program, so it is checked after
    !!! the types are known and before anything is emitted.
    t = time_now();
    rg_check_const_writes();
    rg_validate_control_flow();
    time_print("  const and control flow", time_now() - t);

    if rg_has_errors {
        !!! The program is not emitted, but the warnings about the names nothing
        !!! uses are still given: a diagnostic does not hide another one, and a rule
        !!! that reported a call reports it about a program that still has its own
        !!! warnings to make. rg_check_unused walks the statements itself, so the
        !!! warnings are the ones the emission below would have given.
        rg_check_unused();
        return "";
    }

    t = time_now();
    rg_emit_r_code();
    time_print("  emit", time_now() - t);
    return rgx_out_text();
}
