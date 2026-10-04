#once
!~
 ~  bootstrap/frontend/rgen_prepare_calls.b: this implementation of
 ~  the hoisting of the struct values a call returns.
 ~
 ~  A struct-returning call hands back the address of a value inside the callee's own
 ~  frame. The next call made from the same place reuses that frame, so any value read
 ~  after another call - a method receiver, an argument of another call, an operand of
 ~  an operator - has to be copied into a local of the caller's frame first. The copy
 ~  is emitted at the start of the statement that needs it, before any of that
 ~  statement's own text is written, which is what makes the DECLARED lines land in
 ~  front of the statement instead of inside its expression.
 ~
 ~  the toolchain replaces a node through an `ExprNode*&` slot or a vector entry. A chain
 ~  entry here has no reference of its own, so the node that stands in one is
 ~  hoisted by writing the link that reaches it: rgx_hoist_in_chain does that, and
 ~  leaves the node that is in the slot afterwards in rgx_hoist_result.
 ~!

#head "rgen"

!!! The node that stands in a hoisted slot afterwards.
@ExprNode rgx_hoist_result;

!!! Hoist the node in one entry of a chain. `prev` is the entry before it (null when
!!! it is the head, which is then the answer), `array_too` asks for the heap-array
!!! element hoist as well. Writing the link back is harmless when nothing was
!!! replaced: it is the link that was there.
@ExprNode rgx_hoist_in_chain -> @ExprNode head, @ExprNode prev, @ExprNode node,
                                bool array_too {
    @ExprNode nx = node.next;
    @ExprNode cnode = node;
    if array_too {
        rg_hoist_array_element_address_out_child = cnode;
        rg_hoist_array_element_address();
        cnode = rg_hoist_array_element_address_out_child;
    }
    rg_hoist_struct_call_out_child = cnode;
    rg_hoist_struct_call();
    cnode = rg_hoist_struct_call_out_child;
    cnode.next = nx;
    rgx_hoist_result = cnode;
    if prev == null {
        return cnode;
    }
    prev.next = cnode;
    return head;
}

!!! Replace the node a `@ExprNode` slot holds when it is a call that returns a
!!! struct. The copy statements are written to rg_rcode at this point.
void rg_hoist_struct_call {
    @ExprNode child = rg_hoist_struct_call_out_child;
    if child == null {
        end;
    }
    !!! The innermost call first.
    rg_prepare_expr_calls(child);
    if child.nk != FUNC_CALL {
        rg_hoist_struct_call_out_child = child;
        end;
    }
    str st = rg_expr_struct_type(child);
    if st == "" {
        rg_hoist_struct_call_out_child = child;
        end;
    }
    !!! A call that answers a `@T` hands back a pointer, not the object: the block it
    !!! names is the one the value lives in, and copying the object into a temporary
    !!! of this frame would throw the pointer away - the temporary's address is what
    !!! the caller passes then, and two calls in one expression reuse the same slot,
    !!! so a chain built that way links a node to itself (the self-hosted parser did
    !!! exactly that with a `@Token`-returning helper). Only a struct handed back by
    !!! value lives in the callee's frame and has to be copied out.
    if rg_is_at_type(child.result_type) || child.ptr_depth > 0 {
        rg_hoist_struct_call_out_child = child;
        end;
    }
    str tmp = rg_materialize_struct_value(child, st);
    !!! The expression has just been emitted into the temporary's copy and is about
    !!! to leave the tree, so the names it reads are recorded here: the unused check
    !!! (-W-nused) walks the tree afterwards and would not see them any more - a
    !!! local read only inside an append (`buf = buf + f(x)`) was reported as an
    !!! identifier that is never used.
    rg_mark_used_expr(child);
    @ExprNode vref = p_new_expr(VAR_REF);
    vref.line = child.line;
    vref.col = child.col;
    vref.var_name = tmp;
    vref.tok_len = pe_len(tmp);
    vref.struct_type = st;
    vref.result_type = INT;
    rg_hoist_struct_call_out_child = vref;
}

!!! A struct value that lives in a heap array element is passed as the address of
!!! the element, which is a compound expression (`pointer + index * size`). The
!!! backend's argument setup loses such a value, so the address is stored in a local
!!! pointer of this frame first and the local is passed instead.
void rg_hoist_array_element_address {
    @ExprNode child = rg_hoist_array_element_address_out_child;
    if child == null {
        end;
    }
    if child.nk != ARRAY_ACCESS {
        end;
    }
    @RgBoolMap ait = rg_boolmap_find(rg_sym_is_array, child.var_name);
    if ait == null || !ait.v {
        rg_hoist_array_element_address_out_child = child;
        end;
    }
    str st = rg_expr_struct_type(child);
    if st == "" {
        rg_hoist_array_element_address_out_child = child;
        end;
    }
    rg_emit_lvalue_address_out = "";
    if !rg_emit_lvalue_address(child) {
        rg_hoist_array_element_address_out_child = child;
        end;
    }
    str addr = rg_emit_lvalue_address_out;
    rg_tmp_var_counter = rg_tmp_var_counter + 1;
    str tmp = "__ar" + (str)rg_tmp_var_counter;
    rg_rcode = rg_rcode + "DECLARED AT_VOID " + tmp + " , " + addr + "\n";
    !!! The address has been emitted into the temporary and the expression leaves the
    !!! tree, so what it reads is recorded here (see the hoist above).
    rg_mark_used_expr(child);
    @ExprNode vref = p_new_expr(VAR_REF);
    vref.line = child.line;
    vref.col = child.col;
    vref.var_name = tmp;
    vref.tok_len = pe_len(tmp);
    !!! The type it points at, and the pointer depth of a pointer to that object.
    vref.struct_type = st;
    vref.ptr_depth = 1;
    vref.result_type = INT;
    rg_hoist_array_element_address_out_child = vref;
    rg_syms = rg_vartypemap_set(rg_syms, tmp, INT);
    rg_sym_depth = rg_intmap_set(rg_sym_depth, tmp, 1);
    rg_sym_struct_type = rg_strmap_set(rg_sym_struct_type, tmp, st);
    !!! Passed as its value, not as its address.
    rg_sym_struct_ptr = rg_boolmap_set(rg_sym_struct_ptr, tmp, true);
}

void rg_prepare_expr_calls -> @ExprNode n {
    if n == null {
        end;
    }
    if n.nk == FUNC_CALL {
        !!! args[0] of `receiver.method(...)` is the receiver; the rest are
        !!! arguments. Both are read by the call being made here, so a struct value a
        !!! nested call returned must already be in this frame.
        if n.has_receiver && n.args != null {
            n.args = rgx_hoist_in_chain(n.args, null, n.args, true);
        } else {
            @ExprNode prev = null;
            @ExprNode a = n.args;
            while a != null {
                @ExprNode nx = a.next;
                n.args = rgx_hoist_in_chain(n.args, prev, a, true);
                prev = rgx_hoist_result;
                a = nx;
            }
        }
        !!! Every argument from the second one on is hoisted for a struct value as
        !!! well (the toolchain runs the same hoist over the list from index 1).
        @ExprNode prev2 = n.args;
        @ExprNode b = null;
        if n.args != null {
            b = n.args.next;
        }
        while b != null {
            @ExprNode nx2 = b.next;
            n.args = rgx_hoist_in_chain(n.args, prev2, b, false);
            prev2 = rgx_hoist_result;
            b = nx2;
        }
        rg_prepare_expr_calls(n.left);
        end;
    }
    if n.nk == BINOP || n.nk == SHL || n.nk == SHR || n.nk == BITNOT || n.nk == UNARY ||
       n.nk == CAST || n.nk == MEMBER_ACCESS || n.nk == ARRAY_ACCESS || n.nk == FIELD_ELEM {
        rg_hoist_struct_call_out_child = n.left;
        rg_hoist_struct_call();
        n.left = rg_hoist_struct_call_out_child;
        rg_hoist_struct_call_out_child = n.right;
        rg_hoist_struct_call();
        n.right = rg_hoist_struct_call_out_child;
        @ExprNode prev = null;
        @ExprNode a = n.indices;
        while a != null {
            @ExprNode nx = a.next;
            n.indices = rgx_hoist_in_chain(n.indices, prev, a, false);
            prev = rgx_hoist_result;
            a = nx;
        }
        end;
    }
    if n.nk == TERNARY {
        rg_hoist_struct_call_out_child = n.left;
        rg_hoist_struct_call();
        n.left = rg_hoist_struct_call_out_child;
        rg_hoist_struct_call_out_child = n.right;
        rg_hoist_struct_call();
        n.right = rg_hoist_struct_call_out_child;
        @ExprNode prev = null;
        @ExprNode a = n.args;
        while a != null {
            @ExprNode nx = a.next;
            n.args = rgx_hoist_in_chain(n.args, prev, a, false);
            prev = rgx_hoist_result;
            a = nx;
        }
        end;
    }
    if n.nk == LAMBDA {
        @LambdaRec rec = p_find_lambda(n.lambda_id);
        if rec != null {
            @ExprNode prev = null;
            @ExprNode a = rec.immediate_args;
            while a != null {
                @ExprNode nx = a.next;
                rec.immediate_args = rgx_hoist_in_chain(rec.immediate_args, prev, a, false);
                prev = rgx_hoist_result;
                a = nx;
            }
        }
        @ExprNode prev2 = null;
        @ExprNode b = n.args;
        while b != null {
            @ExprNode nx2 = b.next;
            n.args = rgx_hoist_in_chain(n.args, prev2, b, false);
            prev2 = rgx_hoist_result;
            b = nx2;
        }
        end;
    }
    if n.nk == ADDR {
        rg_prepare_expr_calls(n.left);
        end;
    }
    rg_prepare_expr_calls(n.left);
    rg_prepare_expr_calls(n.right);
    @ExprNode a = n.args;
    while a != null {
        rg_prepare_expr_calls(a);
        a = a.next;
    }
    @ExprNode i = n.indices;
    while i != null {
        rg_prepare_expr_calls(i);
        i = i.next;
    }
}

void rg_prepare_stmt_struct_calls -> @StmtNode s {
    if s == null {
        end;
    }
    !!! A method statement (`v[0].sum();`) passes its receiver exactly like the same
    !!! call inside an expression does. Only the heap-array element hoist is done
    !!! here, the way the `prepare_stmt_struct_calls` does it: the receiver that
    !!! is itself a struct-returning call is left standing, and `prepare_expr_calls`
    !!! reaches it through the receiver of the call being made, not through this.
    !!! Doing the struct-value hoist here as well copied the value into a temporary
    !!! the toolchain does not make, so `s.two(2, 7).show(1);` came out with a
    !!! `DECLARED STRUCT S __ov1` in front of it that the reference does not write
    !!! (and the numbering of every later temporary moved with it).
    if s.nk == CALL_FUNC && s.is_method_call && s.args != null {
        rg_hoist_array_element_address_out_child = s.args;
        rg_hoist_array_element_address();
        s.args = rg_hoist_array_element_address_out_child;
    }
    rg_prepare_expr_calls(s.expr);
    @ExprNode a = s.args;
    while a != null {
        rg_prepare_expr_calls(a);
        a = a.next;
    }
    @ExprNode t = s.targ_exprs;
    while t != null {
        rg_prepare_expr_calls(t);
        t = t.next;
    }
    @ExprNode ai = s.array_init;
    while ai != null {
        rg_prepare_expr_calls(ai);
        ai = ai.next;
    }
    @ExprNode ix = s.assign_indices;
    while ix != null {
        rg_prepare_expr_calls(ix);
        ix = ix.next;
    }
    @ExprNode ce = s.case_exprs;
    while ce != null {
        rg_prepare_expr_calls(ce);
        ce = ce.next;
    }
}

!!! The store helper of an assignment written as an expression. The .r has no
!!! assignment that answers a value (`i++` is the one store it can spell inside an
!!! expression, and only for a plain variable), so the front end lowers the
!!! assignment to a call of a generated function that stores through a pointer and
!!! hands the value back:
!!!
!!!     FUNC __asg_int INT (AT_INT __a0, INT __a1) THEN (
!!!     DREF __a0, __a1
!!!     RET __a1
!!!     )
!!!
!!! The call answers the value that was stored, so `int b = (a = 1);` takes it and
!!! `(a = 1) = 2` goes on storing into `a`: the target of the outer assignment is the
!!! one the inner one wrote, and the inner store runs first because its call is
!!! passed as the ignored parameter of the sequencing version (arguments are
!!! evaluated right to left). the `RGenerator::build_assign_call` is the same
!!! step.

!!! A fresh copy of the target an assignment's call is handed the address of. The
!!! same object is written by every store of a chain (`(a = 1) = 2` writes `a`
!!! twice), and each call owns the nodes it is given.
@ExprNode rg_clone_assign_target -> @ExprNode t {
    if t == null {
        return null;
    }
    if t.nk == UNARY && p_text_eq(t.op, "$") && t.left != null {
        @ExprNode inner = rg_clone_assign_target(t.left);
        @ExprNode u = p_new_expr(UNARY);
        u.line = t.line;
        u.col = t.col;
        u.tok_len = t.tok_len;
        u.op = t.op;
        u.result_type = t.result_type;
        u.left = inner;
        return u;
    }
    @ExprNode c = p_new_expr(VAR_REF);
    c.line = t.line;
    c.col = t.col;
    c.tok_len = t.tok_len;
    c.var_name = t.var_name;
    c.result_type = t.result_type;
    c.struct_type = t.struct_type;
    c.ptr_depth = t.ptr_depth;
    c.type_resolved = t.type_resolved;
    return c;
}

!!! The node that stands in a slot afterwards: a function answers one value.
@ExprNode rg_lower_assign_in_out;

@ExprNode rg_build_assign_call -> @ExprNode n {
    !!! The object that is written: the target of the innermost assignment of a
    !!! chain, which is the one every store of it names.
    @ExprNode base = n.left;
    while base != null && base.nk == ASSIGN_EXPR {
        base = base.left;
    }
    !!! The stores of the assignments standing as this one's target run first, and
    !!! their calls are passed as the ignored parameter (see the sequencing version).
    @ExprNode nested = null;
    if n.left != null && n.left.nk == ASSIGN_EXPR {
        nested = rg_build_assign_call(n.left);
    }
    if n.right != null {
        rg_lower_assign_in_out = n.right;
        rg_lower_assign_in();
        n.right = rg_lower_assign_in_out;
    }
    str name = rg_assign_helper_name(base, nested != null);
    if pe_eq(name, "") {
        !!! Reported while the types were checked.
        return n;
    }
    @ExprNode call = p_new_expr(FUNC_CALL);
    call.line = n.line;
    call.col = n.col;
    call.tok_len = n.tok_len;
    call.var_name = name;
    call.result_type = base.result_type;
    call.struct_type = base.struct_type;
    call.ptr_depth = base.ptr_depth;
    !!! The destination. A name is addressed with `(AT name)`; `$p = v` already
    !!! holds the address in `p`, so the pointer itself is passed.
    @ExprNode target = rg_clone_assign_target(base);
    @ExprNode addr = null;
    if target.nk == UNARY && p_text_eq(target.op, "$") && target.left != null {
        addr = target.left;
        target.left = null;
    } else {
        addr = p_new_expr(ADDR);
        addr.line = target.line;
        addr.col = target.col;
        addr.tok_len = target.tok_len;
        addr.result_type = AT_INT;
        addr.left = target;
    }
    call.args = p_chain_expr(call.args, addr);
    call.args = p_chain_expr(call.args, n.right);
    call.nargs = 2;
    if nested != null {
        call.args = p_chain_expr(call.args, nested);
        call.nargs = 3;
    }
    return call;
}

!!! The same over one entry of a chain of arguments: the entry is rebuilt with the
!!! assignment inside it lowered.
@ExprNode rgx_lower_assign_chain -> @ExprNode head {
    @ExprNode out = null;
    @ExprNode out_tail = null;
    @ExprNode a = head;
    while a != null {
        @ExprNode nx = a.next;
        a.next = null;
        rg_lower_assign_in_out = a;
        rg_lower_assign_in();
        @ExprNode r = rg_lower_assign_in_out;
        if out == null {
            out = r;
        } else {
            out_tail.next = r;
        }
        out_tail = r;
        a = nx;
    }
    return out;
}

void rg_lower_assign_in {
    @ExprNode n = rg_lower_assign_in_out;
    if n == null {
        end;
    }
    if n.nk == ASSIGN_EXPR {
        rg_lower_assign_in_out = rg_build_assign_call(n);
        end;
    }
    rg_lower_assign_in_out = n.left;
    rg_lower_assign_in();
    n.left = rg_lower_assign_in_out;
    rg_lower_assign_in_out = n.right;
    rg_lower_assign_in();
    n.right = rg_lower_assign_in_out;
    n.args = rgx_lower_assign_chain(n.args);
    n.indices = rgx_lower_assign_chain(n.indices);
    n.targ_exprs = rgx_lower_assign_chain(n.targ_exprs);
    if n.nk == LAMBDA {
        @LambdaRec rec = p_find_lambda(n.lambda_id);
        if rec != null {
            rec.immediate_args = rgx_lower_assign_chain(rec.immediate_args);
        }
    }
    !!! The node itself is what the caller is left with: the recursive calls above
    !!! leave their own child in the slot.
    rg_lower_assign_in_out = n;
}

!!! Every assignment inside this statement's expressions, replaced by its helper
!!! call. Before anything of the statement is written, so the calls stand inside the
!!! expression they belong to and the value is there where it is read. the toolchain
!!! `RGenerator::lower_assign_exprs` is the same step.
void rg_lower_assign_exprs -> @StmtNode s {
    if s == null {
        end;
    }
    rg_lower_assign_in_out = s.expr;
    rg_lower_assign_in();
    s.expr = rg_lower_assign_in_out;
    s.args = rgx_lower_assign_chain(s.args);
    s.array_init = rgx_lower_assign_chain(s.array_init);
    s.assign_indices = rgx_lower_assign_chain(s.assign_indices);
    s.case_exprs = rgx_lower_assign_chain(s.case_exprs);
    s.targ_exprs = rgx_lower_assign_chain(s.targ_exprs);
    s.fparam_defaults = rgx_lower_assign_chain(s.fparam_defaults);
    rg_lower_assign_in_out = s.array_len_expr;
    rg_lower_assign_in();
    s.array_len_expr = rg_lower_assign_in_out;
}
