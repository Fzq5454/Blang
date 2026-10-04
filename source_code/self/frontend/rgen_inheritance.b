#once
!~
 ~  bootstrap/frontend/rgen_inheritance.b: the frontend/rgen_inheritance.
 ~
 ~  The inheritance check: a base named by `type X : B` must be a defined type, and
 ~  the bases must not form a cycle. validate_inheritance is a depth-first walk of
 ~  the base graph - `visiting` holds the types on the path being followed and
 ~  `visited` the types already finished with - so meeting a type that is still
 ~  `visiting` is a cycle, reported at the edge that closed it.
 ~
 ~  the toolchain keeps the two sets and the recursive lambda inside the method; this implementation
 ~  makes the recursion a function of its own (rgx_validate_inheritance_dfs) with
 ~  the two sets beside it, because the language has no function values and the walk
 ~  has to call itself. The sets are RgStrSet chains, and `visiting.erase(t)` is
 ~  rg_set_drop. That function and the two globals are the only things this module
 ~  adds.
 ~
 ~  The walk starts at every defined type the depth-first walk has not reached yet.
 ~  the toolchain iterates its unordered_map of definitions; this implementation iterates the chain
 ~  of definitions the parser keeps, which is the reverse of the declaration order.
 ~  An unordered_map has no order in the toolchain either, so any order is as good: the
 ~  one thing it can change is which of two independent cycles is reported first in
 ~  a file that holds both.
 ~!

#head "rgen"

!!! The types on the path the depth-first walk follows and the types it has already
!!! finished with. They are module globals because the recursion is a function of
!!! its own here (the toolchain keeps both sets in the method and captures them in its
!!! lambda).
@RgStrSet rgx_inh_visiting;
@RgStrSet rgx_inh_visited;

!!! The depth-first walk from one type. True comes back when that type closes a
!!! cycle, which is what the toolchain lambda answers; the diagnostic of a base that is
!!! missing or that closes the cycle is written here, at the position of that base.
bool rgx_validate_inheritance_dfs -> str t {
    if rg_set_has(rgx_inh_visiting, t) {
        return true;
    }
    if rg_set_has(rgx_inh_visited, t) {
        return false;
    }
    rgx_inh_visiting = rg_set_add(rgx_inh_visiting, t);
    @StructDef sit = p_find_struct(t);
    if sit != null {
        @StrNode b = sit.bases;
        @IntNode bl = sit.bases_line;
        @IntNode bc = sit.bases_col;
        while b != null {
            !!! `bases_line[bi]` and `bases_col[bi]`: a base that carries no position
            !!! of its own is reported at the position of the whole definition.
            int line = sit.line;
            int col = sit.col;
            if bl != null {
                line = bl.v;
            }
            if bc != null {
                col = bc.v;
            }
            if p_find_struct(b.s) == null {
                rg_fmt_err(line, col,
                           "base type '" + b.s + "' of type '" + t + "' is not defined",
                           pe_len(b.s), (str)null, 0, true);
                rg_has_errors = true;
            } else if rgx_validate_inheritance_dfs(b.s) {
                rg_fmt_err(line, col,
                           "inheritance cycle detected involving type '" + t + "'",
                           pe_len(b.s), (str)null, 0, true);
                rg_has_errors = true;
                rgx_inh_visiting = rg_set_drop(rgx_inh_visiting, t);
                return true;
            }
            b = b.next;
            if bl != null {
                bl = bl.next;
            }
            if bc != null {
                bc = bc.next;
            }
        }
    }
    rgx_inh_visiting = rg_set_drop(rgx_inh_visiting, t);
    rgx_inh_visited = rg_set_add(rgx_inh_visited, t);
    return false;
}

!!! The whole check: both sets start empty, and every defined type walks once.
void rg_validate_inheritance {
    rgx_inh_visiting = null;
    rgx_inh_visited = null;
    @StructDef d = p_struct_defs;
    while d != null {
        if !rg_set_has(rgx_inh_visited, d.name) && !rg_set_has(rgx_inh_visiting, d.name) {
            rgx_validate_inheritance_dfs(d.name);
        }
        d = d.next;
    }
}
