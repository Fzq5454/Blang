#once
!~
 ~  bootstrap/frontend/struct_def.b: the frontend/struct_def.
 ~
 ~  What a `type` declaration leaves behind: the fields with their offsets, the
 ~  methods, the BLANG_API methods, the constructor and destructor, and the total
 ~  size. A generic struct keeps the same shape inside a StructTemplate, next to the
 ~  parameter list it is instantiated with.
 ~
 ~  A field keeps the name the toolchain one has, except `type`, which the language keeps
 ~  for itself: it is `ty` here, the same renaming ast.b does.
 ~
 ~  The lists are chains, not vectors: the parser only ever appends to them, and a
 ~  chain can be carried by a node and passed around without the object's length
 ~  being copied away (see ast.b).
 ~!

#head "types"
#head "ast"

type StructField {
    str name;
    VarType ty;
    !!! Byte offset within the struct.
    int offset;
    !!! Where the field name stands, for the warnings about a member nothing uses
    !!! (-W-nused-struct / -W-read-nused-struct).
    int line;
    int col;
    !!! Who may reach it: 0 = public (the default, and what a member written outside
    !!! any `public { ... }` section is), 1 = protected, 2 = private.
    int access;
    !!! Inline array field: `array_dim` is how many elements there are in total (0 =
    !!! not an array) and `dims` holds the individual dimensions in declaration
    !!! order, so `int m[2][3]` has dims {2,3} and array_dim 6.
    int array_dim;
    @IntNode dims;
    !!! Dimensions written as constant expressions (`int data[N]`), folded when the
    !!! struct is instantiated; a dimension that already folded keeps no entry.
    @ExprNode dim_exprs;
    !!! Non-empty when the field is itself a struct.
    str struct_type;
    !!! `@T name`: an eight-byte pointer to a struct T, not a value.
    bool struct_ptr;
    !!! `utype int name`: the value is unsigned wherever the field is read or written.
    bool is_unsigned;
    @StructField next;
};

type StructMethod {
    str name;
    !!! 0 = public, 1 = protected, 2 = private (see StructField).
    int access;
    !!! The FUNCTION statement. It is `fn` and not `func`: `func` is one of the type
    !!! keywords, so it can be declared as a field but not read back as one.
    @StmtNode fn;
    !!! Non-empty when the method was declared as `operator <symbol>`: the symbol as
    !!! written. The name above is the method name either way.
    str op;
    !!! Non-empty when the method is a converting constructor written as
    !!! `init <name> -> T v { ... }`: the source type it builds the value from and
    !!! the generated function that returns the object (`__ctor_T_int`), which is
    !!! what a conversion site calls.
    str ctor_from;
    str ctor_func;
    @StructMethod next;
};

type StructBapiMethod {
    str name;
    !!! The BAPI statement, with its call target, arguments and parameter types.
    @StmtNode bapi;
    @StructBapiMethod next;
};

type StructDef {
    str name;
    !!! The hash of `name` (rgx_lk_hash of rgen_cache.b): the emitter and the type
    !!! checker ask for a struct name for every mention of one, and the walk of the
    !!! chain rejects a node with one integer compare instead of a string compare.
    int hash;
    !!! Base type names, in declaration order, each with where it was written.
    @StrNode bases;
    @IntNode bases_line;
    @IntNode bases_col;
    @StructField fields;
    @StructMethod methods;
    @StructBapiMethod bapi_methods;
    !!! `init <name> { ... }`, the constructor without parameters, and where its
    !!! keyword stands.
    @StmtNode init_func;
    int init_line;
    int init_col;
    !!! Who may run it (see StructField).
    int init_access;
    !!! `destruct <name> { ... }`, the destructor, and where its keyword stands.
    @StmtNode destruct_func;
    int destruct_line;
    int destruct_col;
    !!! Who may run it (see StructField).
    int destruct_access;
    int total_size;
    int line;
    int col;
    !!! Where the name itself stands. `line`/`col` above are the start of the whole
    !!! `type ...` statement, which is the `type` keyword: a warning about the type
    !!! has to point at its name, not at the keyword in front of it.
    int name_line;
    int name_col;
    !!! The next definition of the chain the parser keeps its table in (the toolchain
    !!! version is an unordered_map, so a definition there has no link of its own).
    @StructDef next;
    !!! The next definition of the same bucket of the parser's index over that
    !!! chain (see p_find_struct). The chain above keeps every definition in
    !!! declaration order and this one only ties together the definitions that
    !!! hash alike, which is what turns a lookup into a bucket probe.
    @StructDef hnext;
};

!!! One bucket of the parser's index over that chain (see p_find_struct): the head
!!! of the definitions whose name hashes into it. It stands here and not beside the
!!! parser because a type a function body names has to be declared before the stub
!!! that declares the function.
type PStructBucket {
    @StructDef head;
};

!!! A generic struct: `introduce TYPENAME T { type Box { T v ... } }`. The body is
!!! kept generic and cloned into a concrete StructDef for each instantiation.
type StructTemplate {
    @StrNode tparams;
    @BoolNode tparam_is_value;
    @VarTypeNode tparam_types;
    !!! True for a TEMPLATE parameter, one that names a generic struct rather than a
    !!! type.
    @BoolNode tparam_is_template;
    @StructDef def;
    @StructTemplate next;
};
