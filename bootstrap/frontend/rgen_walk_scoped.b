#once
!~
 ~  bootstrap/frontend/rgen_walk_scoped.b: the frontend/rgen_walk_scoped.
 ~
 ~  The same walk as rgen_walk.b, carrying one more thing: the scope of the
 ~  enclosing function or block. Its only caller is collect_declared_vars()
 ~  (rgen_declare), whose lambda is the per-statement action, and that lambda
 ~  stands next to the method in its own file: rg_collect_declared_vars_stmt in
 ~  rgen_declare.b, declared by the stub below. There is no action selector here -
 ~  the walk has one caller, so it calls that one collect.
 ~
 ~  The scope key of a nested block is the `block_scope(outer, s)`: the outer
 ~  key, a separator and the identity of the block's statement. the toolchain writes the
 ~  address of that node; the language cannot read an address, so the line and the
 ~  column of the statement stand in for it. That keeps exactly the sharing the toolchain
 ~  has, because it is the same node that is passed for every block_scope() call of
 ~  one statement: the two arms of an if/else, the two bodies of a do/while, both
 ~  bodies of a try and every case of one switch all get one and the same key -
 ~  which is why a name declared in both arms of one if/else is a redeclaration
 ~  there and is one here. Two different statements can never start at the same line
 ~  and column, so no two blocks that the toolchain tells apart share a key.
 ~
 ~  At the top level the key stays empty: a declaration written there is a global,
 ~  which is what the entry scope (and `::name`) expects.
 ~
 ~  A body is a chain walked through `next`; the walk never enters a body through
 ~  the `next` of the statement it stands on. A switch keeps the statements of all
 ~  its cases in one chain, each case opened by a CASE_MARK statement (ast.b); the
 ~  keeps one list per case and hands every one of them the key of the switch
 ~  node, so walking the whole chain with that one key is the same walk, and the
 ~  marks themselves are skipped the way the toolchain has no node for them.
 ~!

#head "rgen"

!!! The per-statement action of the only caller, declared so this module may call
!!! it: the body of the `collect` lambda collect_declared_vars() passes to
!!! walk_stmts_scoped, which stands next to rg_collect_declared_vars in
!!! rgen_declare.b.
stub void rg_collect_declared_vars_stmt -> @StmtNode s, str scope;

!!! The scope key of a nested block: the outer key, the separator the toolchain
!!! block_scope() writes (the character 3) and the identity of the block's own
!!! statement. the toolchain puts the address of the node there; the language cannot read
!!! an address, so the line and the column of the statement take its place. That is
!!! what makes two block_scope() calls with the same node agree on a key - the two
!!! arms of one if/else, the two bodies of one do/while, both bodies of one try,
!!! every case of one switch - exactly as the same address makes them agree in the
!!!, while two different statements never share a position.
str rgx_block_scope -> str outer, @StmtNode s {
    if outer == "" || s == null {
        return outer;
    }
    return outer + char_text(3) + (str)s.line + ":" + (str)s.col;
}

!!! The walk: every statement of `stmts` with the scope it is written in, then every
!!! body inside it with the scope that body opens.
void rg_walk_stmts_scoped -> @StmtNode stmts, str scope {
    @StmtNode s = stmts;
    while s != null {
        if s.nk != CASE_MARK {
            rg_collect_declared_vars_stmt(s, scope);
            if s.nk == IF_ELSE {
                !!! One key for both arms: the toolchain calls block_scope(scope, s) with
                !!! the same if node for each of them, so a name declared in both
                !!! arms is a redeclaration there and is one here.
                str block = rgx_block_scope(scope, s);
                rg_walk_stmts_scoped(s.true_body, block);
                rg_walk_stmts_scoped(s.false_body, block);
            }
            if s.nk == WHILE {
                rg_walk_stmts_scoped(s.true_body, rgx_block_scope(scope, s));
            }
            if s.nk == FUNCTION {
                !!! Each function body is its own declaration scope. The scope name is
                !!! only a key for the redeclaration check, so the identity of the
                !!! node is appended: two overloads of one name (or several methods
                !!! of a struct) must not share a scope, or a local of one of them
                !!! would look like a redeclaration of a local of another.
                if !s.broken {
                    rg_walk_stmts_scoped(s.true_body,
                                         s.var_name + char_text(2) +
                                         (str)s.line + ":" + (str)s.col);
                }
            }
            if s.nk == DO_WHILE {
                str block2 = rgx_block_scope(scope, s);
                rg_walk_stmts_scoped(s.true_body, block2);
                rg_walk_stmts_scoped(s.false_body, block2);
            }
            if s.nk == SWITCH {
                !!! Every case body of one switch carries the key of the switch node,
                !!! which is the key the toolchain builds for each of them in its loop.
                str block3 = rgx_block_scope(scope, s);
                rg_walk_stmts_scoped(s.case_bodies, block3);
                rg_walk_stmts_scoped(s.unmatch_body, block3);
            }
            if s.nk == TRY_CATCH {
                !!! Both bodies are blocks of their own: the exception variable and
                !!! the try body's locals must not leak into the handler.
                str block4 = rgx_block_scope(scope, s);
                rg_walk_stmts_scoped(s.true_body, block4);
                rg_walk_stmts_scoped(s.false_body, block4);
            }
        }
        s = s.next;
    }
}
