#once
!~
 ~  bootstrap/frontend/rgen_index.b: the frontend/rgen_index.
 ~
 ~  Two helpers of the array machinery:
 ~   * rc_any_tag writes the runtime type tag of one argument of an `any` value. An
 ~     element of an array of `any` hands over the tag it carries at run time
 ~     (`(ATAG arr{index})`), every other value is tagged with its resolved type;
 ~     the type is resolved before the argument is emitted, so a call used directly
 ~     as an `any` argument tags its own return type.
 ~   * linear_index_expr folds a multi-dimensional subscript into the one flat index
 ~     the backend reads, using the dimensions the declaration recorded.
 ~
 ~  the toolchain writes that resolved tag as `(int)result_type`, the number of the
 ~  VarType member. The language does not read the number behind a `kind` member, so
 ~  the table is spelled out as rgx_var_type_tag, in the order types declares its
 ~  members - the order the backend's own runtime tag uses as well, since the two
 ~  sides only talk through the .r text. That is the one helper this module adds.
 ~
 ~  Building the flat index runs the expression generator on one index at a time,
 ~  so the text of the output built so far is put aside in `saved` and each piece is
 ~  read out of the text just written, which is the `rcode.clear()` with a copy
 ~  of `rcode`.
 ~!

#head "rgen"

!!! The number of a VarType member, which is the runtime tag of an `any`. types
!!! declares INT, STR, FLOAT, BOOL, CHAR, VOID, AT_INT, AT_FLOAT, AT_CHAR, AT_STR,
!!! AT_VOID, AT_BOOL, ANY, FUNC, AT_FUNC, LONG, AT_LONG in that order, and this implementation
!!! keeps that order (types.b), so the number of each member is the `(int)` of
!!! it.
int rgx_var_type_tag -> VarType t {
    if t == INT { return 0; }
    if t == STR { return 1; }
    if t == FLOAT { return 2; }
    if t == BOOL { return 3; }
    if t == CHAR { return 4; }
    if t == VOID { return 5; }
    if t == AT_INT { return 6; }
    if t == AT_FLOAT { return 7; }
    if t == AT_CHAR { return 8; }
    if t == AT_STR { return 9; }
    if t == AT_VOID { return 10; }
    if t == AT_BOOL { return 11; }
    if t == ANY { return 12; }
    if t == FUNC { return 13; }
    if t == AT_FUNC { return 14; }
    if t == LONG { return 15; }
    return 16;
}

!!! The type tag of one argument of an `any`: an element of an array of `any` asks
!!! the runtime for the tag it carries, every other value is tagged with its own
!!! resolved type. the toolchain appends the text to `rcode` and reads it back out of it
!!! again; here it is answered as a text of its own, so the text the caller had
!!! built is never taken apart (assigning to a `str` variable frees the heap string
!!! it owned: backend/codegen_cast, the STR reassignment path).
str rg_rc_any_tag -> @ExprNode n {
    if n.nk == ARRAY_ACCESS && n.result_type == ANY {
        str idx = rg_capture_rc_expr(n.left);
        return " , (ATAG " + n.var_name + "{" + idx + "})";
    }
    return " , " + (str)rgx_var_type_tag(n.result_type);
}

!!! The one flat index of a multi-dimensional subscript `var_name[i][j]...`. With no
!!! index the answer is the empty text; with no known dimensions - or fewer of them
!!! than the subscript has indices - the first index is taken as the flat one
!!! (best-effort); otherwise each further index is multiplied by the dimension that
!!! follows it into `((flat, dim, *), index, +)`.
str rg_linear_index_expr -> str var_name, @ExprNode indices {
    if indices == null {
        return "";
    }
    !!! The piece of text the indices emitted is a slice between two marks of the
    !!! buffer and the buffer is cut back to the first (rgen_out.b): the toolchain saves
    !!! the whole text, empties the buffer and assigns the copy back, which costs
    !!! everything emitted so far for every index expression.
    int mark = rgx_out_mark();
    rg_rc_expr(indices);
    str flat = rgx_out_slice(mark);
    int nidx = 0;
    @ExprNode ic = indices;
    while ic != null {
        nidx = nidx + 1;
        ic = ic.next;
    }
    @RgDimsMap dit = rg_dimmap_find(rg_sym_dims, var_name);
    if dit == null || dit.n < nidx {
        rgx_out_cut(mark);
        return flat;
    }
    int k = 1;
    @ExprNode ix = indices.next;
    while ix != null {
        !!! `dit->second[k]`: the dimension that follows the index in the subscript.
        longlong d = 1;
        @RgLongNode dn = dit.dims;
        int di = 0;
        while dn != null && di < k {
            dn = dn.next;
            di = di + 1;
        }
        if dn != null {
            d = dn.v;
        }
        if d <= 0 {
            d = 1;
        }
        int mark2 = rgx_out_mark();
        rg_rc_expr(ix);
        flat = "((" + flat + " , " + (str)d + " , *) , " + rgx_out_slice(mark2) + " , +)";
        rgx_out_cut(mark2);
        ix = ix.next;
        k = k + 1;
    }
    rgx_out_cut(mark);
    return flat;
}
