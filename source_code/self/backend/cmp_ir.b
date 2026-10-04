#once
!~
 ~  bootstrap/backend/cmp_ir.b: the intermediate representation of the .r compiler.
 ~
 ~  It is the backend/ir: the two node shapes the .r parser builds
 ~  (CmpExpr and CmpStmt), the chain nodes the toolchain keeps in a chain, and the
 ~  layout of a struct the .r file declares.
 ~
 ~  Field names avoid the language's keywords: `kind`, `type`, `size`, `end`, `func`,
 ~  `ref` and `local` can be written as a field but not read back as one, so the
 ~  node kind is `nk`, a type is `ty` and a size is `sz`.
 ~!

!!! ExprNode::Kind.
kind CmpExprKind {
    LIT_INT, LIT_FLOAT, LIT_STR, LIT_BOOL, LIT_CHAR, VAR_REF, BINOP, CAST,
    ARRAY_ACCESS, FUNC_CALL, ADDR, PRE_INCR, POST_INCR, LIT_NULL, TERNARY,
    BITNOT, SHL, SHR, DL, CLOSURE, ICALL, CLOSURE_CODE, CLOSURE_FROM_PTR,
    CELL, ANY_TAG, FLD, FLDP, SPREAD
}

!!! One expression of the .r text. The arguments of a call are the `next` chain
!!! hanging off the first one, which is the `a chain of ExprNode* args`.
type CmpExpr {
    CmpExprKind nk;
    longlong int_val;
    float float_val;
    bool bool_val;
    int char_val;
    str str_val;
    str var_name;
    str op;
    @CmpExpr left;
    @CmpExpr right;
    @CmpExpr args;
    VarType result_type;
    int ptr_depth;
    int line;
    int col;
    @CmpExpr next;
};

!!! StmtNode::Kind. The language keeps every enum member in one namespace, so the
!!! three names that the expression kinds already use are spelled with `_STMT`:
!!! CAST, FUNC and ICALL.
kind CmpStmtKind {
    DECLARED, CALL, CAST_STMT, EXIT, IF_ELSE, REPEAT, END, FUNC_STMT, RET, FOR,
    DO_WHILE, CONTINUE, SWITCH, DREF, ICALL_STMT, RELEASE, BSPREAD, TRY_CATCH, RAISE
}

!!! A chain of names, of types, of flags and of ints: the toolchain
!!! `a chain of str`, `<VarType>`, `<bool>` and `<longlong>`.
type CmpStrNode {
    str s;
    @CmpStrNode next;
};

type CmpTypeNode {
    VarType ty;
    @CmpTypeNode next;
};

type CmpBoolNode {
    bool v;
    @CmpBoolNode next;
};

type CmpIntNode {
    longlong v;
    @CmpIntNode next;
};

!!! One statement of the .r text. `true_body` and `false_body` are the two arms of
!!! an if, the body of a repeat and the body of a function; a chain of statements
!!! is linked through `next`.
type CmpStmt {
    CmpStmtKind nk;
    VarType decl_type;
    int ptr_depth;
    str var_name;
    str struct_type;
    str call_name;
    @CmpExpr init_expr;
    @CmpExpr field_target;
    @CmpExpr args;
    @CmpExpr exit_expr;
    @CmpStmt true_body;
    @CmpStmt false_body;
    int line;
    int col;
    !!! FUNC-specific.
    @CmpStrNode fparams;
    @CmpTypeNode fparam_types;
    @CmpStrNode fparam_struct;
    @CmpBoolNode fparam_struct_ptr;
    @CmpBoolNode fparam_is_array;
    bool variadic;
    bool is_local;
    VarType func_ret_type;
    str ret_struct;
    !!! CALL: a nested function call used as an argument.
    str nested_call;
    @CmpExpr nested_args;
    !!! Array support.
    bool is_array;
    @CmpExpr array_len_expr;
    @CmpExpr array_init;
    @CmpIntNode array_dims;
    !!! The stack slot the resolve pass gave this declaration. A name can be
    !!! declared more than once in one function - an inner block shadowing a
    !!! variable of an outer one, which is what this converted front end does itself
    !!! (`str et` next to a `VarType et` in one body) - and every declaration has a
    !!! slot of its own. A table keyed by name alone answered the *other*
    !!! declaration's type and slot, so a `str` local was stored and read as four
    !!! bytes and the pointer lost its top half.
    int local_offset;
    bool local_has_slot;
    !!! BSPREAD: per-element variadic spread into a single-argument builtin.
    int spread_tag;
    !!! SWITCH support.
    @CmpExpr case_exprs;
    @CmpStmt unmatch_body;
    @CmpStmt next;
};

!!! One case arm of a switch: its body, which is the toolchain
!!! `a chain of chains of StmtNode* case_bodies`. The arms hang off a chain of
!!! their own and the switch they belong to finds them through the table below: an
!!! arm holds statements and a statement holds arms, and the language wants a type
!!! to be known before a pointer to it is written, so the two cannot point at each
!!! other and the arms are reached by a lookup instead of by a field.
type CmpCaseBody {
    @CmpStmt body;
    @CmpCaseBody next;
};

!!! The case arms of one switch statement, looked up by the statement itself.
type CmpSwitchCases {
    @CmpStmt sw;
    @CmpCaseBody bodies;
    @CmpSwitchCases next;
};

!!! The layout of one field of a struct, and of the struct itself: the toolchain
!!! StructFieldInfo and StructTypeInfo.
type CmpFieldInfo {
    VarType ty;
    int off;
    int sz;
    @CmpFieldInfo next;
};

type CmpStructType {
    str name;
    int total_size;
    @CmpFieldInfo fields;
    @CmpStructType next;
};

!!! ---- building the chains ----

@CmpExpr ce_new -> CmpExprKind k {
    CmpExpr proto;
    @CmpExpr e;
    cg_balloc(@e, size proto);
    e.nk = k;
    e.int_val = 0;
    e.float_val = 0.0;
    e.bool_val = false;
    e.char_val = 0;
    e.str_val = "";
    e.var_name = "";
    e.op = "";
    e.left = null;
    e.right = null;
    e.args = null;
    e.result_type = INT;
    e.ptr_depth = 0;
    e.line = 0;
    e.col = 0;
    e.next = null;
    return e;
}

@CmpStmt cs_new -> CmpStmtKind k {
    CmpStmt proto;
    @CmpStmt s;
    cg_balloc(@s, size proto);
    s.nk = k;
    s.decl_type = INT;
    s.ptr_depth = 0;
    s.var_name = "";
    s.struct_type = "";
    s.call_name = "";
    s.init_expr = null;
    s.field_target = null;
    s.args = null;
    s.exit_expr = null;
    s.true_body = null;
    s.false_body = null;
    s.line = 0;
    s.col = 0;
    s.fparams = null;
    s.fparam_types = null;
    s.fparam_struct = null;
    s.fparam_struct_ptr = null;
    s.fparam_is_array = null;
    s.variadic = false;
    s.is_local = false;
    s.func_ret_type = VOID;
    s.ret_struct = "";
    s.nested_call = "";
    s.nested_args = null;
    s.is_array = false;
    s.array_len_expr = null;
    s.array_init = null;
    s.array_dims = null;
    s.local_offset = 0;
    s.local_has_slot = false;
    s.spread_tag = -1;
    s.case_exprs = null;
    s.unmatch_body = null;
    s.next = null;
    return s;
}

!!! The case arms of the switch statements of the file, filled by the parser.
@CmpSwitchCases cmp_switch_cases;

void cs_set_cases -> @CmpStmt sw, @CmpCaseBody bodies {
    CmpSwitchCases proto;
    @CmpSwitchCases e;
    cg_balloc(@e, size proto);
    e.sw = sw;
    e.bodies = bodies;
    e.next = cmp_switch_cases;
    cmp_switch_cases = e;
}

@CmpCaseBody cs_cases_of -> @CmpStmt sw {
    @CmpSwitchCases e = cmp_switch_cases;
    while e != null {
        !!! The two are addresses of statements: `==` on the struct type itself is
        !!! not defined, so the comparison goes through `@void`.
        if (@void)e.sw == (@void)sw {
            return e.bodies;
        }
        e = e.next;
    }
    return null;
}

!!! Append to a chain of expressions and answer the head, which is what
!!! `a chain::push_back` does for the toolchain.
@CmpExpr ce_add -> @CmpExpr head, @CmpExpr e {
    if e == null {
        return head;
    }
    if head == null {
        return e;
    }
    @CmpExpr t = head;
    while t.next != null {
        t = t.next;
    }
    t.next = e;
    e.next = null;
    return head;
}

@CmpStmt cs_add -> @CmpStmt head, @CmpStmt s {
    if s == null {
        return head;
    }
    if head == null {
        return s;
    }
    @CmpStmt t = head;
    while t.next != null {
        t = t.next;
    }
    t.next = s;
    s.next = null;
    return head;
}

@CmpStrNode cn_str -> @CmpStrNode head, str s {
    CmpStrNode proto;
    @CmpStrNode n;
    cg_balloc(@n, size proto);
    n.s = s;
    n.next = null;
    if head == null {
        return n;
    }
    @CmpStrNode t = head;
    while t.next != null {
        t = t.next;
    }
    t.next = n;
    return head;
}

@CmpTypeNode cn_type -> @CmpTypeNode head, VarType t {
    CmpTypeNode proto;
    @CmpTypeNode n;
    cg_balloc(@n, size proto);
    n.ty = t;
    n.next = null;
    if head == null {
        return n;
    }
    @CmpTypeNode e = head;
    while e.next != null {
        e = e.next;
    }
    e.next = n;
    return head;
}

@CmpBoolNode cn_bool -> @CmpBoolNode head, bool v {
    CmpBoolNode proto;
    @CmpBoolNode n;
    cg_balloc(@n, size proto);
    n.v = v;
    n.next = null;
    if head == null {
        return n;
    }
    @CmpBoolNode e = head;
    while e.next != null {
        e = e.next;
    }
    e.next = n;
    return head;
}

@CmpIntNode cn_int -> @CmpIntNode head, longlong v {
    CmpIntNode proto;
    @CmpIntNode n;
    cg_balloc(@n, size proto);
    n.v = v;
    n.next = null;
    if head == null {
        return n;
    }
    @CmpIntNode e = head;
    while e.next != null {
        e = e.next;
    }
    e.next = n;
    return head;
}

@CmpCaseBody cc_add -> @CmpCaseBody head, @CmpStmt body {
    CmpCaseBody proto;
    @CmpCaseBody c;
    cg_balloc(@c, size proto);
    c.body = body;
    c.next = null;
    if head == null {
        return c;
    }
    @CmpCaseBody e = head;
    while e.next != null {
        e = e.next;
    }
    e.next = c;
    return head;
}

@CmpFieldInfo cf_new -> VarType t, int off, int sz {
    CmpFieldInfo proto;
    @CmpFieldInfo f;
    cg_balloc(@f, size proto);
    f.ty = t;
    f.off = off;
    f.sz = sz;
    f.next = null;
    return f;
}

@CmpFieldInfo cf_add -> @CmpFieldInfo head, @CmpFieldInfo f {
    if head == null {
        return f;
    }
    @CmpFieldInfo e = head;
    while e.next != null {
        e = e.next;
    }
    e.next = f;
    return head;
}

!!! the toolchain indexes a `a chain`: how many it holds, and the one at `i`.
int cf_count -> @CmpFieldInfo head {
    int n = 0;
    @CmpFieldInfo e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

@CmpFieldInfo cf_at -> @CmpFieldInfo head, int i {
    @CmpFieldInfo e = head;
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

int ce_n -> @CmpExpr head {
    int n = 0;
    @CmpExpr e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

@CmpExpr ce_at -> @CmpExpr head, int i {
    @CmpExpr e = head;
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

int cs_n -> @CmpStmt head {
    int n = 0;
    @CmpStmt e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

@CmpStmt cs_at -> @CmpStmt head, int i {
    @CmpStmt e = head;
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

int cn_type_n -> @CmpTypeNode head {
    int n = 0;
    @CmpTypeNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

!!! The `i`th type of a chain, which is the `param_types[i]`. A position past
!!! the end reads as `void`, the way an out-of-range read vector was
!!! reported rather than faulted on.
@CmpTypeNode cn_type_at -> @CmpTypeNode head, int i {
    @CmpTypeNode e = head;
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

VarType cn_type_of -> @CmpTypeNode head, int i {
    @CmpTypeNode e = cn_type_at(head, i);
    if e == null {
        return VOID;
    }
    return e.ty;
}

!!! the toolchain keeps a `a chain of int` it also writes into (`param_copy_off[i]`).
void cn_int_set -> @CmpIntNode head, int i, longlong v {
    @CmpIntNode e = head;
    int k = 0;
    while e != null {
        if k == i {
            e.v = v;
            end;
        }
        e = e.next;
        k = k + 1;
    }
}

int cn_str_n -> @CmpStrNode head {
    int n = 0;
    @CmpStrNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

longlong cn_int_at -> @CmpIntNode head, int i {
    @CmpIntNode e = head;
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

int cc_n -> @CmpCaseBody head {
    int n = 0;
    @CmpCaseBody e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

@CmpCaseBody cc_at -> @CmpCaseBody head, int i {
    @CmpCaseBody e = head;
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
