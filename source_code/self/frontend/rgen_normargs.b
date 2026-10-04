#once
!~
 ~  bootstrap/frontend/rgen_normargs.b: the frontend/rgen_normargs.
 ~
 ~  normalize_call_args: one call's argument list is put in the parameter order its
 ~  signature declares. The named arguments are matched to the parameter names and
 ~  moved to their positions, the omitted trailing ones are filled from the default
 ~  values (a copy of the default expression, never the node itself), and everything
 ~  before `arg_start` - the receiver of a method call - keeps its place.
 ~
 ~  the toolchain reorders five vectors in place; here they are the five
 ~  rg_normalize_call_args_out_* globals of rgen.b. The
 ~  caller puts the call's chains in them, calls, and reads the chains back, so a
 ~  path that reports an error and returns leaves them as they were.
 ~
 ~  Two shapes the language forces:
 ~   * the `resolved` vector is a chain of RgExprRef cells, one per
 ~     parameter, because a slot is written by index (a named argument lands in the
 ~     parameter it names) and a chain of expressions cannot be written out of order;
 ~   * the `filled` flags are not needed beside it: a slot holds the
 ~     argument node itself and a call argument is never null, so "is it filled" and
 ~     "does the cell hold a node" are the same question.
 ~!

#head "rgen"
#head "rgen_heads"

!!! The two RgExprRef readers below are used before their definitions.
stub int rgx_na_len_ref -> @RgExprRef head;
stub @ExprNode rgx_na_at_ref -> @RgExprRef head, int i;

!!! ---- reading a chain by index ----
!!!
!!! the toolchain addresses its vectors as `args[i]`, `c_names[i]`, `name_lines[i]`; the
!!! port walks the chain to the index. An accessor answers null (or 0) past the end
!!! of the chain, which is the `i < v.size()` guard of every one of those reads.

@ExprNode rgx_na_at_expr -> @ExprNode head, int i {
    @ExprNode e = head;
    int k = 0;
    while e != null {
        if k == i {
            return e;
        }
        e = e.next;
        k = k + 1;
    }
    return null;
}

@StrNode rgx_na_at_str -> @StrNode head, int i {
    @StrNode e = head;
    int k = 0;
    while e != null {
        if k == i {
            return e;
        }
        e = e.next;
        k = k + 1;
    }
    return null;
}

int rgx_na_at_int -> @IntNode head, int i {
    @IntNode e = head;
    int k = 0;
    while e != null {
        if k == i {
            return e.v;
        }
        e = e.next;
        k = k + 1;
    }
    return 0;
}

@RgExprRef rgx_na_ref_at -> @RgExprRef head, int i {
    @RgExprRef e = head;
    int k = 0;
    while e != null {
        if k == i {
            return e;
        }
        e = e.next;
        k = k + 1;
    }
    return null;
}

int rgx_na_len_expr -> @ExprNode head {
    int n = 0;
    @ExprNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

int rgx_na_len_str -> @StrNode head {
    int n = 0;
    @StrNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

!!! ---- the reordering ----

void rg_normalize_call_args -> str fname, int err_line, int err_col, int err_len,
                               int arg_start, @StrNode method_params,
                               @ExprNode method_defaults {
    @ExprNode args = rg_normalize_call_args_out_args;
    @StrNode arg_names = rg_normalize_call_args_out_arg_names;
    @IntNode name_lines = rg_normalize_call_args_out_name_lines;
    @IntNode name_cols = rg_normalize_call_args_out_name_cols;
    @IntNode name_lens = rg_normalize_call_args_out_name_lens;

    @RgStrListMap nit = rg_strlistmap_find(rg_func_param_names, fname);
    @RgExprListMap dit = rg_exprlistmap_find(rg_func_param_defaults, fname);
    int nargs = rgx_na_len_expr(args);
    if arg_start > nargs {
        arg_start = nargs;
    }
    !!! A method call carries its receiver as args[0], which no parameter names, so
    !!! the argument list the signature applies to starts at arg_start. Everything
    !!! before that is put back unchanged when the list is written out again. The
    !!! signature comes from the method the receiver's type declares, which is not in
    !!! func_param_names (that table holds the free functions).
    @StrNode pnames = method_params;
    if pnames == null && nit != null {
        pnames = nit.names;
    }
    if pnames == null {
        !!! No signature (a BAPI, or a function a linked DLL exports): the call is
        !!! emitted positionally, so a named argument would silently land in the
        !!! parameter of that position instead. Report it instead of miscompiling.
        int i = arg_start;
        int nnames = rgx_na_len_str(arg_names);
        while i < nnames {
            @StrNode an = rgx_na_at_str(arg_names, i);
            if an != null && an.s != "" {
                int nl = rgx_na_at_int(name_lines, i);
                if nl == 0 {
                    nl = err_line;
                }
                int nc = rgx_na_at_int(name_cols, i);
                if nc == 0 {
                    nc = err_col;
                }
                int nlen = rgx_na_at_int(name_lens, i);
                if nlen == 0 {
                    nlen = pe_len(an.s);
                }
                str m = "named arguments are not supported for '" + fname + "'";
                rg_fmt_err(nl, nc, m, nlen, (str)null, 0, true);
                rg_has_errors = true;
                end;
            }
            i = i + 1;
        }
        end;
    }
    int nparams = rgx_na_len_str(pnames);
    !!! def_at(p): the default value of parameter p, or null. the toolchain vector holds a
    !!! null slot for a parameter without one; this implementation's chain holds only the
    !!! parameters that have one, and they are a suffix of the list (a parameter with
    !!! a default may not be followed by one without), so the first
    !!! `nparams - ndef` parameters have none. Which of the two sources answers is
    !!! what the `if (method_defaults) ... else ...` decides: a resolved method
    !!! is exactly the case `method_params` is not null.
    @RgExprRef defs = null;
    if method_params != null {
        defs = rg_exprref_of(method_defaults);
    } else if dit != null {
        defs = dit.exprs;
    }
    int ndef = rgx_na_len_ref(defs);
    int first_def = nparams - ndef;
    !!! A list of defaults longer than the parameter list (which a broken signature
    !!! could hold) then reads the way the dense vector reads: from the
    !!! first slot.
    if first_def < 0 {
        first_def = 0;
    }

    bool any_named = false;
    int ci = arg_start;
    int nnames2 = rgx_na_len_str(arg_names);
    while ci < nnames2 {
        @StrNode an2 = rgx_na_at_str(arg_names, ci);
        if an2 != null && an2.s != "" {
            any_named = true;
            skip;
        }
        ci = ci + 1;
    }

    !!! resolved[p], one cell per parameter; the cells stand in parameter order and
    !!! are filled below, which is what the toolchain vector of the same name is.
    @RgExprRef slots = null;
    int sp = 0;
    while sp < nparams {
        slots = rg_exprref_append(slots, null);
        sp = sp + 1;
    }

    if !any_named {
        !!! Fast path: purely positional args, so only the trailing defaults are
        !!! filled. A list that is already complete (or over-full, which the arity
        !!! check reports) is left alone.
        if nargs - arg_start >= nparams {
            end;
        }
        int k = arg_start;
        int p = 0;
        while k < nargs {
            @RgExprRef cell = rgx_na_ref_at(slots, p);
            cell.e = rgx_na_at_expr(args, k);
            k = k + 1;
            p = p + 1;
        }
    } else {
        !!! General path: reorder the named arguments, then fill the defaults.
        bool seen_named = false;
        int pos_idx = 0;
        int i = arg_start;
        while i < nargs {
            @ExprNode ai = rgx_na_at_expr(args, i);
            @StrNode ani = rgx_na_at_str(arg_names, i);
            str cname = "";
            if ani != null {
                cname = ani.s;
            }
            if cname == "" {
                if seen_named {
                    int hl = 1;
                    int el = err_line;
                    int ec = err_col;
                    if ai != null {
                        if ai.tok_len > 0 {
                            hl = ai.tok_len;
                        }
                        el = ai.line;
                        ec = ai.col;
                    }
                    rg_fmt_err(el, ec, "positional argument after named argument",
                               hl, (str)null, 0, true);
                    rg_has_errors = true;
                    end;
                }
                if pos_idx >= nparams {
                    end;
                }
                @RgExprRef pcell = rgx_na_ref_at(slots, pos_idx);
                pcell.e = ai;
                pos_idx = pos_idx + 1;
            } else {
                seen_named = true;
                int idx = nparams;
                int p2 = 0;
                @StrNode pn = pnames;
                while pn != null {
                    if p_text_eq(pn.s, cname) {
                        idx = p2;
                        skip;
                    }
                    p2 = p2 + 1;
                    pn = pn.next;
                }
                int nline = rgx_na_at_int(name_lines, i);
                if nline == 0 {
                    nline = err_line;
                }
                int ncol = rgx_na_at_int(name_cols, i);
                if ncol == 0 {
                    ncol = err_col;
                }
                int nlen = rgx_na_at_int(name_lens, i);
                if nlen == 0 {
                    nlen = pe_len(cname);
                }
                if idx == nparams {
                    str m = "unknown argument name '" + cname + "'";
                    rg_fmt_err(nline, ncol, m, nlen, (str)null, 0, true);
                    rg_has_errors = true;
                    end;
                }
                @RgExprRef ncell = rgx_na_ref_at(slots, idx);
                if ncell.e != null {
                    str m2 = "argument '" + cname + "' specified more than once";
                    rg_fmt_err(nline, ncol, m2, nlen, (str)null, 0, true);
                    rg_has_errors = true;
                    end;
                }
                ncell.e = ai;
            }
            i = i + 1;
        }
    }

    !!! Every parameter no argument named is filled from its default value. A
    !!! parameter with no default is left to the arity check of the caller.
    int p3 = 0;
    @RgExprRef cnode = slots;
    while cnode != null {
        if cnode.e == null {
            @ExprNode def = null;
            if p3 >= first_def && defs != null {
                def = rgx_na_at_ref(defs, p3 - first_def);
            }
            if def == null {
                end;
            }
            cnode.e = p_clone_expr(def);
        }
        p3 = p3 + 1;
        cnode = cnode.next;
    }

    !!! store: the receiver (or anything else before arg_start) keeps its place and
    !!! the names are dropped, because every caller downstream reads the arguments by
    !!! position. Each node is detached before it is appended: a node of the original
    !!! chain still carries its link, and appending it as it stands would re-link the
    !!! rest of that chain behind it.
    @ExprNode out_args = null;
    int h = 0;
    while h < arg_start {
        @ExprNode nd = rgx_na_at_expr(args, h);
        if nd != null {
            nd.next = null;
            out_args = p_chain_expr(out_args, nd);
        }
        h = h + 1;
    }
    @RgExprRef rc = slots;
    while rc != null {
        @ExprNode nd2 = rc.e;
        if nd2 != null {
            nd2.next = null;
            out_args = p_chain_expr(out_args, nd2);
        }
        rc = rc.next;
    }
    rg_normalize_call_args_out_args = out_args;
    !!! `arg_names.assign(arg_start, str())` and the three int vectors: the
    !!! positions before arg_start keep an empty entry each.
    @StrNode nh = null;
    @IntNode lh = null;
    @IntNode ch = null;
    @IntNode eh = null;
    int q = 0;
    while q < arg_start {
        nh = p_chain_str(nh, p_new_name("", 0, 0));
        lh = p_chain_int(lh, p_new_int(0));
        ch = p_chain_int(ch, p_new_int(0));
        eh = p_chain_int(eh, p_new_int(0));
        q = q + 1;
    }
    rg_normalize_call_args_out_arg_names = nh;
    rg_normalize_call_args_out_name_lines = lh;
    rg_normalize_call_args_out_name_cols = ch;
    rg_normalize_call_args_out_name_lens = eh;
}

!!! The same two reads over an RgExprRef chain, which is what the method
!!! default values are stored in (a node's own `next` is the list it was parsed in).
int rgx_na_len_ref -> @RgExprRef head {
    int n = 0;
    @RgExprRef e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

@ExprNode rgx_na_at_ref -> @RgExprRef head, int i {
    int k = 0;
    @RgExprRef e = head;
    while e != null {
        if k == i {
            return e.e;
        }
        k = k + 1;
        e = e.next;
    }
    return null;
}
