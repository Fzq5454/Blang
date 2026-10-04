#once
!~
 ~  bootstrap/frontend/rgen_check.b: the frontend/rgen_check.
 ~
 ~  The three small questions the type check asks before it reports anything:
 ~  whether an initializer references the variable it initializes (so `int x = x;`
 ~  is an error rather than a read of an uninitialized slot), whether -Econversion
 ~  may convert one type to another, and whether one integer type widens into
 ~  another with nothing to lose (which needs no flag and no cast).
 ~
 ~  the `from == to` and `from == VarType::X` tests are the `==` of the type
 ~  kind here (types.b names the members without the `VarType::` prefix), and
 ~  `is_at_type` is the rg_is_at_type of rgen_rtype.b.
 ~!

#head "rgen"
#head "rgen_heads"

!!! has_self_ref: does this expression tree read the name? Used on the initializer
!!! of a declaration, so `int x = x;` is reported instead of reading the slot that
!!! is being declared. A null node is not a reference, the toolchain tests that first.
bool rg_has_self_ref -> @ExprNode n, str name {
    if n == null {
        return false;
    }
    if n.nk == VAR_REF && pe_eq(n.var_name, name) {
        return true;
    }
    !!! `has_self_ref(n->left, name) || has_self_ref(n->right, name)`, kept
    !!! short-circuited: the right subtree is walked only when the left one has no
    !!! reference in it.
    if rg_has_self_ref(n.left, name) {
        return true;
    }
    return rg_has_self_ref(n.right, name);
}

!!! is_wconversion_allowed: whether -Econversion may convert `from` to `to`. The
!!! list is the toolchain one in the same order, so the answer is the same one. The last
!!! two branches the toolchain writes (a second `to == FLOAT` and a second `to == BOOL`)
!!! are unreachable there as well: the first pair above them answers both.
bool rg_is_wconversion_allowed -> VarType from, VarType to {
    if from == to {
        return true;
    }
    !!! 'any' is the variadic wildcard type: the runtime value is already a
    !!! pointer/word, so under -Econversion allow it to be passed to any pointer
    !!! parameter (e.g. memory(rest) where rest is `any ...`).
    if from == ANY && rg_is_at_type(to) {
        return true;
    }
    !!! Normal type conversions.
    if to == INT {
        return from == CHAR || from == BOOL || from == FLOAT;
    }
    if to == FLOAT {
        return from == INT || from == CHAR || from == BOOL;
    }
    if to == BOOL {
        return from == INT || from == FLOAT || from == CHAR || from == STR;
    }
    if to == CHAR {
        return from == INT;
    }
    if to == LONG {
        return from == INT || from == CHAR || from == BOOL || from == FLOAT;
    }
    !!! The repeated FLOAT and BOOL branches (they stand after the ones
    !!! above, so no type reaches them).
    if to == FLOAT {
        return from == INT || from == CHAR || from == BOOL || from == LONG;
    }
    if to == BOOL {
        return from == INT || from == FLOAT || from == CHAR || from == STR ||
               from == LONG;
    }
    return false;
}

!!! is_free_widening: the conversions that are always allowed because nothing can
!!! be lost by them. A 64-bit integer takes every 32-bit one as it is: nothing to
!!! lose, so this one needs neither a cast nor -Econversion. The way back narrows
!!! and has to be written as `(int)x`.
bool rg_is_free_widening -> VarType from, VarType to {
    if from == to {
        return true;
    }
    if to == LONG {
        return from == INT || from == CHAR || from == BOOL;
    }
    return false;
}
