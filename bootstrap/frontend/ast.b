!~
 ~  bootstrap/frontend/ast.b: the abstract syntax tree.
 ~
 ~  Three differences, all forced by the language, and
 ~  all noted where they happen:
 ~
 ~  1. A collection is a singly linked list, not a a chain: the parser only
 ~     appends while it parses and the generator only walks afterwards, so a node
 ~     carries the link of the list it is in (`next`) and no capacity is guessed.
 ~  2. A struct has to be declared before it is named, so the little list types and
 ~     the nodes are ordered by what they name, and the two template fields (the
 ~     type arguments of an explicit instantiation) arrive with the template
 ~     module, which is where the front end grows them too.
 ~  3. `children` (the nested-statement list the toolchain cloning walkers use) is gone:
 ~     the same statements are reachable by walking the bodies.
 ~
 ~  Names the language keeps for itself were changed: `kind` -> `nk`, `type` -> `ty`.
 ~!

#once
#head "types"

!!! ---- the small lists a node needs ----

type IntNode {
    int v;
    @IntNode next;
};

type StrNode {
    str s;
    int line;
    int col;
    int len;
    @StrNode next;
};

type VarTypeNode {
    VarType ty;
    @VarTypeNode next;
};

type BoolNode {
    bool v;
    @BoolNode next;
};

!!! ---- expressions ----

kind ExprKind {
    LIT_INT, LIT_FLOAT, LIT_STR, LIT_BOOL, LIT_CHAR, VAR_REF, BINOP, UNARY, CAST,
    ARRAY_ACCESS, FUNC_CALL, ADDR, PRE_INCR, POST_INCR, LIT_NULL, TERNARY, BITNOT,
    SHL, SHR, MEMBER_ACCESS, SIZE, COUNT, FOLD, LAMBDA, FIELD_ELEM, ASSIGN_EXPR
}

type ExprNode {
    ExprKind nk;
    longlong int_val;
    !!! LIT_INT: the constant needs 64 bits. Its value may be the bit pattern of an
    !!! unsigned 64-bit one, which as a signed value looks like a small int, so the
    !!! width cannot be worked out from the value again.
    bool lit_is_long;
    float float_val;
    str str_val;
    !!! LIT_STR: where the text of the literal stands in the source, between the
    !!! quotes. The `.r` text of a string is what the toolchain writes after it has
    !!! decoded the escapes and escaped the bytes again, and a value with a NUL in
    !!! it (`"\033"`, which C reads as NUL and then `33`) has no reading as a
    !!! `str`: it ends at that byte. The span is what lets the emitter walk the
    !!! written text once and write the `.r` form of every byte of it without ever
    !!! holding the NUL. Zero when the node was built by a pass and not read from
    !!! the source, and the value is emitted as it stands then.
    int str_from;
    int str_to;
    bool bool_val;
    int char_val;
    str var_name;
    !!! Where the name was written, so a later pass can compare it as a span
    !!! instead of building a string for every identifier.
    int var_name_start;
    int var_name_stop;
    str member_name;
    str op;
    bool is_super;
    bool has_receiver;
    bool is_overload_call;
    bool spread;
    @ExprNode left;
    @ExprNode right;
    !!! Arguments of a call, entries of an initializer or the indices of a
    !!! subscript, as the list this node is an entry of.
    @ExprNode args;
    @ExprNode next;
    int nargs;
    !!! A multi-dimensional subscript `m[i][j]`: the first index stays in `left` and
    !!! the rest are here, in the order they were written.
    @ExprNode indices;
    !!! The constant expression of each explicit value argument, and the struct name
    !!! (or empty for a builtin), the type and the value flag of each type argument.
    !!! `targs` is a chain of VarTypes and not of TArg records: TArg is declared with
    !!! the statements, below this node.
    @VarTypeNode targs;
    @ExprNode targ_exprs;
    @StrNode targ_structs;
    @BoolNode targ_is_value;
    !!! Named arguments: the name of each and where it was written.
    @StrNode arg_names;
    @IntNode arg_name_lines;
    @IntNode arg_name_cols;
    @IntNode arg_name_lens;
    VarType result_type;
    !!! The value is unsigned: it reads, prints and divides as an unsigned one of
    !!! the same width. A variable keeps the flag of its declaration, an operation
    !!! takes it from its operands the way C does.
    bool is_unsigned;
    !!! Set once type checking has resolved this expression, so a later pass does
    !!! not resolve it again through the flat symbol tables.
    bool type_resolved;
    VarType address_type;
    str struct_type;
    str cast_type_param;
    int ptr_depth;
    !!! `(@T)expr`: the bits are a pointer either way and nothing is emitted, only
    !!! what the front end knows about them changes. The node keeps the struct and
    !!! the depth the cast wrote even when a later pass resolves the expression
    !!! again from the tables (a call's return type, for one).
    bool struct_cast;
    !!! `count a`: the number of elements of the array `a`. An array whose length is
    !!! known here (`int a[4]`, a stack array with no block of its own) is answered
    !!! with that number and the flag says so; every other array - a variadic pack,
    !!! or the heap array a declaration built - carries the number in the metadata
    !!! block in front of its data, which the emitter reads at run time.
    bool count_folded;
    !!! FOLD: a template pack folded with one operator. `var_name` is the pack,
    !!! `op` the operator, and `fold_right` says which side the operator was
    !!! written on: `(Args etc +)` folds left, `(+ Args etc)` folds right.
    bool fold_right;
    VarType convert_to;
    int line;
    int col;
    int tok_len;
    int op_line;
    int op_col;
    !!! The LAMBDA fields (`[params] { body }`). A lambda body is a list of
    !!! statements and StmtNode is declared below this node, so the pieces live in a
    !!! `LambdaRec` of their own (declared after StmtNode) and the node carries the
    !!! id the record is found by: `lambda_id` -> p_lambda_rec(id).
    int lambda_id;
};

!!! ---- statements ----

kind StmtKind {
    DECLARE, ASSIGN, IF_ELSE, WHILE, BREAK, FUNCTION, RETURN, BACK, CALL_FUNC, INCR,
    DO_WHILE, CONTINUE, SWITCH, ENUM, BAPI, STRUCT_DEF, STRUCT_INIT, DREF_ASSIGN,
    RCODE, END, PACKAGE, USE, TRY_CATCH, THROW,
    !!! SWITCH: the mark that opens one case's statements in the body chain. the toolchain
    !!! keeps the statements of a case in a list of its own and has no need of it.
    CASE_MARK
}

!!! One named type argument of an explicit instantiation: the builtin type, the
!!! struct name when the argument named a struct, or - for a non-type parameter -
!!! the constant it was bound to (the value, the float or the string, whichever the
!!! declared type selects). A template-template argument names another template
!!! instead of a type.
type TArg {
    VarType ty;
    str struct_name;
    bool is_value;
    longlong value;
    float fvalue;
    str svalue;
    bool is_template;
    str tname;
    !!! A pack binding (`TYPENAME Y...` / `ARGS A...`): the elements it stands for,
    !!! in order. A pack is what the instantiation's parameter list is built from.
    bool is_pack;
    @TArg pack;
    !!! The next element of that pack (the toolchain holds a a chain of TArg; here it is
    !!! a chain of its own, so the explicit type-argument chain in `next` is not
    !!! disturbed).
    @TArg next_pack;
    @TArg next;
};

!!! A template's type parameters bound to their arguments, by name: the map the
!!! clone helpers of clone.b pass around (the toolchain version is an
!!! unordered_map<str, TArg>).
type TArgMap {
    str name;
    @TArg arg;
    @TArgMap next;
};

!!! One `__bcall("target")` inside a BLANG_API body, with the formal parameter
!!! names collected by the preceding `__badd(...)` directives, in order.
type BapiCallSeg {
    str target;
    @StrNode arg_names;
    @BapiCallSeg next;
};

type StmtNode {
    StmtKind nk;
    VarType decl_type;
    int ptr_depth;
    bool decl_is_ref;
    bool decl_is_const;
    bool decl_is_static;
    bool decl_is_unsigned;
    !!! Statements the compiler built for `static`: the guard that initializes the
    !!! slot on first execution, and the store inside it.
    bool static_guard;
    bool static_init;
    str var_name;
    @ExprNode expr;
    @ExprNode args;
    int nargs;
    !!! CALL_FUNC named arguments: the name each argument was written with (empty
    !!! when it is positional) and where that name stands.
    @StrNode arg_names;
    @IntNode arg_name_lines;
    @IntNode arg_name_cols;
    @IntNode arg_name_lens;
    !!! The next statement of the body list, or of the switch body, this one is in.
    @StmtNode next;
    @TArg targs;
    @ExprNode targ_exprs;
    @StrNode targ_structs;
    @BoolNode targ_is_value;
    @StmtNode true_body;
    @StmtNode false_body;
    int line;
    int col;
    int var_line;
    int var_col;
    int type_col;
    int type_len;
    !!! INCR: the operation, and whether it is written prefix (++a) or postfix (a++).
    str incr_op;
    bool incr_prefix;
    !!! FUNCTION-specific.
    @StrNode fparams;
    @VarTypeNode fparam_types;
    @StrNode fparam_struct;
    @BoolNode fparam_is_array;
    @BoolNode fparam_is_ref;
    @BoolNode fparam_is_const;
    @BoolNode fparam_is_static;
    @BoolNode fparam_is_unsigned;
    @ExprNode fparam_defaults;
    !!! One entry per parameter: whether it was given a default value. the toolchain list
    !!! of defaults holds a null for "no default", which a chain cannot hold, so the
    !!! flag travels beside it.
    @BoolNode fparam_has_default;
    int nfparams;
    int ret_type_line;
    int ret_type_col;
    int ret_type_len;
    bool variadic;
    !!! `-> (Y etc) (Args etc)`: a template function whose parameter list comes from
    !!! a type pack and a value pack. `fparams` stays empty here; the instantiation
    !!! builds one parameter per element of the type pack named `pack_ptypes`, and
    !!! the body reaches them through the pack `pack_pnames`.
    bool params_from_pack;
    str pack_ptypes;
    str pack_pnames;
    VarType func_ret_type;
    bool ret_is_unsigned;
    str ret_struct;
    bool ret_struct_ptr;
    int ret_ptr_depth;
    bool has_return;
    str call_target;
    @BapiCallSeg bapi_segs;
    str builtin_annotation;
    int end_line;
    int end_col;
    bool broken;
    bool is_local;
    bool is_reload;
    bool is_stub;
    str synth_op;
    int reload_line;
    int reload_col;
    int reload_len;
    int params_line;
    int params_col;
    int params_len;
    str struct_type;
    !!! A FUNCTION that is a struct method: 0 = public, 1 = protected, 2 = private, as
    !!! the `public { ... }` section (or the `private int x;` prefix) the declaration
    !!! stood in asked. A call site reads it here, so no lookup of the owning type is
    !!! needed to check the access.
    int access;
    str member_name;
    @StrNode member_chain;
    int members_before_index;
    bool is_method_call;
    bool is_overload_call;
    int member_line;
    int member_col;
    bool is_super;
    !!! ASSIGN: `a[i] = v` where `[]` returns `@T`, so the store goes through the
    !!! address; and a store written through a chain of subscripts.
    bool is_index_ptr_store;
    bool is_index_chain_store;
    bool is_array;
    !!! The dimensions of an array declaration, folded to constants, in the order
    !!! they were written, and the first dimension that could not be folded (which
    !!! the backend sizes instead when it is the only one).
    @IntNode array_dims;
    @ExprNode array_len_expr;
    @ExprNode array_init;
    @ExprNode assign_indices;
    !!! SWITCH support: the expressions of the cases, the body of each case and the
    !!! unmatch arm. the toolchain keeps a vector of vectors for the bodies; here the
    !!! statements of every case are one chain, each case opened by a CASE_MARK
    !!! statement, and `case_exprs` holds the expressions in the same order - a case
    !!! is the mark and the statements up to the next one.
    @ExprNode case_exprs;
    @StmtNode case_bodies;
    @StmtNode unmatch_body;
    !!! RCODE: raw .r text inserted verbatim at this position.
    str rcode_text;
};

!!! A lambda literal `[params] { body }`: the parameters, the body, what the body
!!! captures (with the type each capture has and whether it is written through), the
!!! type `back` hands out, whether the literal is called on the spot, and the id of
!!! the hidden `__lambda_N` function it becomes. It stands after StmtNode because it
!!! names one, and an expression reaches it by the id it carries.
type LambdaRec {
    int id;
    @StrNode params;
    @VarTypeNode param_types;
    @BoolNode param_is_array;
    @StmtNode body;
    @StrNode captures;
    @VarTypeNode capture_types;
    @BoolNode capture_by_ref;
    @ExprNode immediate_args;
    VarType ret_type;
    bool immediate;
    !!! Whether the hidden function of this literal has been written out yet. The
    !!! keeps a set of the node pointers it emitted; this implementation kept a set of the
    !!! ids as text, and the text was built through the int-to-string conversion
    !!! ring, so a lookup after the next conversion compared against a key that had
    !!! been overwritten - the literal was emitted a second time, and the second
    !!! copy of a hidden function is a duplicate definition the back end sees as a
    !!! different body. A flag on the record cannot go stale.
    bool emitted;
    @LambdaRec next;
};

!!! A function template: `introduce TYPENAME T, ... { ... }` declares one or more
!!! type parameters and a block of templated functions.
!!!
!!! The statement is `fn` rather than `func`: `func` is one of the type keywords,
!!! so it can be declared as a field but not read back as one (`t.func` reads as the
!!! keyword and not as a member).
type TemplateFunc {
    @StrNode tparams;
    @BoolNode tparam_is_value;
    @VarTypeNode tparam_types;
    @BoolNode tparam_is_template;
    !!! true = the parameter is a pack (`TYPENAME Y...` / `ARGS A...`): it takes a
    !!! variable number of the instantiation's arguments instead of exactly one.
    @BoolNode tparam_is_pack;
    @StmtNode fn;
    @TemplateFunc next;
};
