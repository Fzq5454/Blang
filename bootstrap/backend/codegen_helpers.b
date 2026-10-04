#once
!~
 ~  bootstrap/backend/codegen_helpers.b: the owned-string classification.
 ~
 ~  `produces_owned_str` says whether an
 ~  expression answers a heap block this program allocated, which is what decides
 ~  whether a string variable owns its text and has to give it back when it is
 ~  written again.
 ~!

#head "cg_heads"

bool cg_produces_owned_str -> @CmpExpr n {
    if n == null {
        return false;
    }
    if n.nk == LIT_STR {
        !!! A literal lives in .rdata.
        return false;
    }
    if n.nk == VAR_REF {
        !!! `x = y` is one address written into another: the two names share the
        !!! block and only the one that produced it may give it back. Answering
        !!! "owned" here made both free it - the second free was of memory the first
        !!! had already released.
        return false;
    }
    if n.nk == BINOP {
        return pe_eq(n.op, "+") && n.result_type == STR;
    }
    if n.nk == CAST {
        !!! `(str)` writes into the shared conversion ring.
        return false;
    }
    return false;
}
