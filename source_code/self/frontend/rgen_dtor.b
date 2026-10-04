#once
!~
 ~  bootstrap/frontend/rgen_dtor.b: the frontend/rgen_dtor.
 ~
 ~  The struct destructor (`destruct`) expansion. A struct local is destroyed when
 ~  the scope that declares it ends: at the end of the enclosing block, or at a
 ~  return that leaves the function. The scope stack below tracks which struct
 ~  locals belong to which scope, and the `destruct` body of each type is inlined at
 ~  the destruction point, so the body sees the object's fields as bare names
 ~  exactly like `init` does.
 ~
 ~  the toolchain keeps `_struct_scopes` as a a chain and pushes an empty frame on it;
 ~  this implementation keeps it as a chain of RgStructScope with the innermost scope first
 ~  (rg_struct_scope_push in rgen.b), so `.back()` is the head of the chain and the
 ~  pop is rg_struct_scope_drop. A frame's locals are appended in declaration order
 ~  and destroyed in reverse, which for a singly linked chain means the frame is
 ~  turned round first - the toolchain walks its vector backwards.
 ~!

#head "rgen"
#head "rgen_heads"

!!! push_struct_scope: `_struct_scopes.push_back({})`, one fresh empty frame.
void rg_push_struct_scope {
    RgStructScope proto;
    @RgStructScope sc;
    malloc(@sc, size proto);
    sc.locals = null;
    sc.next = null;
    rg_struct_scope_push(sc);
}

!!! note_struct_local: remember a struct local in the scope that is open, as
!!! (variable name, struct type). A name or a type that is empty is not a struct
!!! object and nothing is remembered for it.
void rg_note_struct_local -> str var, str stype {
    if rg_struct_scopes == null || pe_eq(var, "") || pe_eq(stype, "") {
        end;
    }
    rg_struct_scopes.locals = rg_structlocal_append(rg_struct_scopes.locals, var, stype);
}

!!! emit_struct_dtor: inline the `destruct` body of `stype` for the object `var`.
!!! The struct-method expansion context is set to that object, so a bare name in
!!! the body is a field of it - the same thing `init` does when the object is
!!! constructed.
void rg_emit_struct_dtor -> str var, str stype {
    @StructDef sit = p_find_struct(stype);
    if sit == null {
        end;
    }
    @StmtNode df = sit.destruct_func;
    if df == null || df.true_body == null {
        end;
    }
    str saved_var = rg_struct_method_var;
    str saved_type = rg_struct_method_type;
    @ExprNode saved_idx = rg_struct_method_idx;
    rg_struct_method_var = var;
    !!! `df->struct_type.empty() ? stype : df->struct_type`: the destructor body's
    !!! own struct when it has one, the type being destroyed otherwise.
    rg_struct_method_type = stype;
    if !pe_eq(df.struct_type, "") {
        rg_struct_method_type = df.struct_type;
    }
    rg_struct_method_idx = null;
    !!! The destructor body is its own scope, so struct locals declared inside it
    !!! are destroyed when the destructor finishes (nested destruction).
    rg_push_struct_scope();
    rg_gen_body(df.true_body);
    rg_pop_struct_scope();
    rg_struct_method_var = saved_var;
    rg_struct_method_type = saved_type;
    rg_struct_method_idx = saved_idx;
}

!!! pop_struct_scope: close the innermost scope and destroy the struct locals it
!!! holds in reverse declaration order, like . The frame is taken off the stack
!!! first, so the destructor bodies it runs open scopes of their own on an empty
!!! stack.
void rg_pop_struct_scope {
    if rg_struct_scopes == null {
        end;
    }
    @RgStructLocal frame = rg_struct_scopes.locals;
    rg_struct_scope_drop();
    !!! Reverse the frame: a chain is walked forwards, and the toolchain destroys from the
    !!! last declaration back to the first.
    @RgStructLocal rev = null;
    @RgStructLocal cnode = frame;
    while cnode != null {
        @RgStructLocal nx = cnode.next;
        cnode.next = null;
        cnode.next = rev;
        rev = cnode;
        cnode = nx;
    }
    while rev != null {
        rg_emit_struct_dtor(rev.var, rev.stype);
        rev = rev.next;
    }
}

!!! pop_all_struct_scopes: every open scope of the function being left, innermost
!!! first, because a return destroys what the scopes it exits declared.
void rg_pop_all_struct_scopes {
    while rg_struct_scopes != null {
        rg_pop_struct_scope();
    }
}

!!! gen_scoped_body: a body of its own scope. The callers that emit a block (`if`,
!!! `while`, a case arm, a destructor body) all go through here, so the struct
!!! locals of the block are destroyed exactly where the block ends.
void rg_gen_scoped_body -> @StmtNode body {
    rg_push_struct_scope();
    rg_gen_body(body);
    rg_pop_struct_scope();
}
