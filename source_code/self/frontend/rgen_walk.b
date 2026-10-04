#once
!~
 ~  bootstrap/frontend/rgen_walk.b: the frontend/rgen_walk.
 ~
 ~  The statement-tree walk the whole-program passes run: walk_stmts applies one
 ~  per-statement action to a statement and then walks every body inside it - both
 ~  arms of an if/else, the body of a while, both bodies of a do/while, every case
 ~  and the unmatch arm of a switch, both bodies of a try, and the body of a
 ~  function that was not left broken. The parameters of such a body are entered
 ~  into the symbol scopes around it and taken out again, and while the type
 ~  checking walk runs the body also gets a declaration table of its own.
 ~
 ~  the toolchain takes the action as a `function<void(StmtNode*)>`. The language has
 ~  no function values, so the action is the int `action` (the scheme the comment
 ~  under the stub in rgen_heads.b explains), and its values are exactly the four
 ~  lambdas the callers in the toolchain passed:
 ~   * action 1 is the collect of register_funcs() (rgen_register): the lambda
 ~     that opens `walk_stmts(parser.statements(), [&](StmtNode* s) {` in that
 ~     function and ends at its `});` - the registration of one FUNCTION statement:
 ~     its `stub` prototype, its name (and the internal name of a `reload` version
 ~     or a package member), its arity, parameter types, structs, array and
 ~     reference markers, unsigned markers, return type, defaults and declaration
 ~     position. It is the function rg_register_funcs_stmt in rgen_register.b.
 ~   * action 2 is the check of typecheck_pass() (rgen_typecheck): the lambda
 ~     passed to the same walk at the top of that function. The BAPI call check,
 ~     the struct method/BAPI call check, the per-kind expression resolution, and
 ~     the record of what each DECLARE leaves in scope for the statements after it.
 ~     It is rg_typecheck_pass_stmt in rgen_typecheck.b.
 ~   * action 3 and action 4 are the two walks of apply_rules() (rgen_declare):
 ~     the first notes where every declaration of the program stands, the second
 ~     notes every call in the order it is written. They are rg_rule_decl_stmt and
 ~     rg_rule_call_stmt in rgen_declare.b.
 ~   * action 5 is the walk apply_attributes() (rgen_declare) makes for the
 ~     names a plain object of an attribute can stand for; it is rg_attr_decl_stmt
 ~     in rgen_declare.b.
 ~  Each lambda stands next to the method it belongs to in its own file, so
 ~  each body is a function of the module that ports that file; the two stub lines
 ~  below declare them here, the way parser_heads.b declares the functions
 ~  parser_error.b implements.
 ~
 ~  A body here is a chain of statements walked through `next`; it is never entered
 ~  through `next` of the statement the walk stands on, or the statements after it
 ~  would be visited again and again.
 ~
 ~  A switch keeps the statements of all its cases in one chain, each case opened by
 ~  a CASE_MARK statement (see ast.b), where the toolchain keeps one list per case. A mark
 ~  is not a statement the toolchain has, so it never gets the action: the walk skips it
 ~  and applies the action to the statements of every case in the order they were
 ~  written, which is what walking each case's list does in the toolchain.
 ~!

#head "rgen"

!!! The per-statement action of each caller, declared so this module may call it.
!!! The bodies stand next to the methods they belong to: rg_register_funcs_stmt in
!!! rgen_register.b (action 1) and rg_typecheck_pass_stmt in rgen_typecheck.b
!!! (action 2).
stub void rg_register_funcs_stmt -> @StmtNode s;
stub void rg_typecheck_pass_stmt -> @StmtNode s;
!!! The two actions of apply_rules() (rgen_declare), whose bodies stand in
!!! rgen_declare.b with the method they belong to: 3 fills the line of every
!!! declaration, 4 notes every call of the program in the order it is written.
stub void rg_rule_decl_stmt -> @StmtNode s;
stub void rg_rule_call_stmt -> @StmtNode s;
!!! The one action of apply_attributes() (rgen_declare) that needs the walk:
!!! 5 fills the line of every declaration a plain object name can stand for, which
!!! is the `by_name` map the checks of that method read (rg_attr_decl_stmt in
!!! rgen_declare.b).
stub void rg_attr_decl_stmt -> @StmtNode s;

!!! Whether a name may be referenced from the body being walked: this body declared
!!! it (`_local_decls`), it is a parameter of one of the open bodies
!!! (`_param_sym_stack`), or it is a global (`_global_names`). While no function
!!! body is being walked - the passes that resolve method and template bodies - the
!!! flat tables answer instead, which is what they did before.
bool rg_symbol_visible_here -> str name {
    if !rg_in_func_body {
        return true;
    }
    if rg_vardeclmap_find(rg_local_decls, name) != null {
        return true;
    }
    @ParamSymFrame fr = rg_param_sym_stack;
    while fr != null {
        @StrNode p = fr.params;
        while p != null {
            if p_text_eq(p.s, name) {
                return true;
            }
            p = p.next;
        }
        fr = fr.next;
    }
    return rg_set_has(rg_global_names, name);
}

!!! The walk: every statement of `stmts`, then every body inside each one, in the
!!! order the toolchain visits them. `action` names the per-statement action (1 = the
!!! collect of register_funcs(), 2 = the check of typecheck_pass(), 3 and 4 = the
!!! declaration-line and call-site walks of apply_rules(), 5 = the declaration-line
!!! walk of the attribute checks of apply_attributes()).
void rg_walk_stmts -> @StmtNode stmts, int action {
    @StmtNode s = stmts;
    while s != null {
        !!! A case mark opens a case; it has no node and never gets the action.
        if s.nk != CASE_MARK {
            if action == 1 {
                rg_register_funcs_stmt(s);
            } else if action == 2 {
                rg_typecheck_pass_stmt(s);
            } else if action == 3 {
                rg_rule_decl_stmt(s);
            } else if action == 4 {
                rg_rule_call_stmt(s);
            } else if action == 5 {
                rg_attr_decl_stmt(s);
            }
            if s.nk == IF_ELSE {
                rg_walk_stmts(s.true_body, action);
                rg_walk_stmts(s.false_body, action);
            }
            if s.nk == WHILE {
                rg_walk_stmts(s.true_body, action);
            }
            if s.nk == FUNCTION {
                if !s.broken {
                    !!! Parameters are visible only inside their own body. Scoping
                    !!! them here is what lets two functions reuse a parameter name
                    !!! with different types - which overloads do by design.
                    rg_push_func_params(s);
                    !!! Each body gets its own declaration table: a local of another
                    !!! body must not decide this one's types. Only the type checking
                    !!! walk keeps one (rg_track_locals), so the table in effect is
                    !!! put aside, an empty one is installed, and the old one comes
                    !!! back when the body is done. the toolchain swaps the two maps and
                    !!! clears the one that comes back; here the table in effect is
                    !!! held in `saved_decls` and the global is emptied.
                    @RgVarDeclMap saved_decls = null;
                    bool saved_in_body = rg_in_func_body;
                    if rg_track_locals {
                        saved_decls = rg_local_decls;
                        rg_local_decls = null;
                        rg_in_func_body = true;
                    }
                    rg_walk_stmts(s.true_body, action);
                    if rg_track_locals {
                        rg_local_decls = saved_decls;
                        rg_in_func_body = saved_in_body;
                    }
                    rg_pop_func_params();
                }
            }
            if s.nk == DO_WHILE {
                rg_walk_stmts(s.true_body, action);
                rg_walk_stmts(s.false_body, action);
            }
            if s.nk == SWITCH {
                !!! The statements of every case are one chain here (ast.b), so the
                !!! whole chain is walked as the toolchain walks each case's list; the
                !!! marks that open the cases are skipped above.
                rg_walk_stmts(s.case_bodies, action);
                rg_walk_stmts(s.unmatch_body, action);
            }
            if s.nk == TRY_CATCH {
                rg_walk_stmts(s.true_body, action);
                rg_walk_stmts(s.false_body, action);
            }
        }
        s = s.next;
    }
}
