#once
!~
 ~  bootstrap/frontend/rgen_heads.b: the declarations of frontend/rgen.
 ~
 ~  The surface of the RGenerator: the records its signatures need, the chain
 ~  records that stand for the toolchain containers, and one
 ~  `stub` line per method, grouped by the rgen_* file the method is
 ~  implemented in. The bodies live in rgen.b (the state and its helpers) and in
 ~  the rgen_*.b modules, one per rgen_* file, so this file answers "what does
 ~  the code generator offer?" the way parser_heads.b answers it for the parser.
 ~
 ~  Three things the toolchain header writes that blang cannot, and what is done here:
 ~
 ~   * a non-const reference or a pointer parameter the callee writes - a
 ~     `str& out`, an `int& off`, a `VarType& t`, an `ExprNode*& n`, a
 ~     `a chain of ...& out`, a `VarDecl& out` - is not a parameter of this converted
 ~     function. It is a module global named `rg_<method>_out[_<param>]`, so that
 ~     `effective_var_decl(name, out)` keeps its answer in
 ~     `rg_effective_var_decl_out`, the way the parser port keeps `p_eval_value`
 ~. Those globals are declared in rgen.b; the toolchain
 ~     parameter each one stands for is named in its comment there.
 ~   * a method that answers a struct value (`StubMismatch stub_proto_mismatch`)
 ~     answers a `bool` here and leaves the record in its `_out` global, which is
 ~     what this design asks for when a result carries more than one
 ~     answer.
 ~   * `function<...>` has no counterpart in the language. The walk that took
 ~     one applies the per-statement action its callers passed, named by an int
 ~     the comment under rg_walk_stmts spells out.
 ~
 ~  A record the toolchain holds by value is held through a pointer here, because a chain
 ~  node is a record of its own and a struct field can only name another record
 ~  through `@T`. The fields keep the toolchain names; a `int` is an `int`, an
 ~  `longlong` a `longlong`, a `a chain of T` a chain of T with a carried `n`
 ~  where the toolchain asks for `.size()`.
 ~
 ~  Three names the language keeps for itself are changed here, the same way ast.b
 ~  and struct_def.b change them:
 ~   * a parameter the toolchain calls `type` (the name of a struct type) is `stype`,
 ~     because `type` is one of the type keywords and cannot be read back;
 ~   * a field the toolchain calls `type` is `ty` (IndexChainLevel), one it calls `kind`
 ~     is `member_kind` (PkgMember, since `kind` declares an enum) and one it calls
 ~     `any` is `found` (StubMismatch, since `any` is a type);
 ~   * a parameter the toolchain calls `local` (the package-local table of
 ~     rewrite_pkg_refs_* / rename_package_member) is `lmap`, because `local`
 ~     introduces a local function.
 ~!

#head "lexer"
#head "ast"
#head "struct_def"
#head "types"
#head "clone"

!!! the chain records the containers become

!!! ---- the bucket index of a name table ----
!!!
!!! the toolchain tables are `name table`/`unordered_set`; this implementation keeps the
!!! nodes in the chain of this design and puts an index beside it. A node
!!! stays on the chain it was inserted into - every pass that walks a table still
!!! sees it, in insertion order - and gains a second link onto a bucket chain, so a
!!! lookup only touches the nodes that hash the same. On the compiler's own source
!!! the four tables below were walked a hundred and fourteen million nodes for
!!! seven hundred thousand lookups.
!!!
!!! One index serves every table: the fields it reads - `key`, `hash`, `next`,
!!! `hnext`, `idx` and `prev` - come first, in that order, in each of their records,
!!! so the index reaches a node as `@RgIdxLink` and finds them where it expects
!!! them, while the rest of the compiler reaches the node as the type it really is.
!!! The payload of each table follows them.
!!!
!!! The head node carries the index itself, so reaching it is a field read and not a
!!! walk of every index ever made.

!!! A bucket of an index: the head of the nodes that hash there.
type RgVoidBucket {
    @void head;
};

!!! The index of one table: the bucket table, and the last node of the chain it
!!! serves, so that adding a name is a link and not a walk to the end of the chain.
type RgIdx {
    vector(RgVoidBucket) bk;
    @void tail;
};

!!! The fields of a table node the index reads, in the order every indexed table
!!! declares them.
type RgIdxLink {
    str key;
    int hash;
    @void next;
    @void hnext;
    @RgIdx idx;
    !!! The node before this one on the chain of its table. It is what makes taking
    !!! a name out of a table a link and not a second walk to the node: the bucket
    !!! finds the node, and the node knows where it stands. Nodes are taken from the
    !!! zeroed heap, so a field never written is null.
    @void prev;
};

!!! A `unordered_set<str>`: every set in the class is a set of names,
!!! so one record serves them all. `rg_set_has` and `rg_set_add` in rgen.b are the
!!! two operations; the `insert(key).second` idiom reads as "add it when
!!! `rg_set_has` says it is not there yet".
type RgStrSet {
    str key;
    !!! The hash of `key` (rgx_lk_hash of rgen_cache.b): a lookup compares this number
    !!! before it compares the text, so walking a chain of thousands of names costs
    !!! one integer compare per node instead of a string compare.
    int hash;
    @RgStrSet next;
    @void hnext;
    @RgIdx idx;
    !!! The node before this one on the chain of its table. It is what makes taking
    !!! a name out of a table a link and not a second walk to the node: the bucket
    !!! finds the node, and the node knows where it stands. Nodes are taken from the
    !!! zeroed heap, so a field never written is null.
    @void prev;
};

!!! `name table<str, int>`: func_params_hl, func_decl_line,
!!! sym_depth, func_arity.
type RgIntMap {
    str key;
    int hash;
    @RgIntMap next;
    @void hnext;
    @RgIdx idx;
    !!! The node before this one on the chain of its table. It is what makes taking
    !!! a name out of a table a link and not a second walk to the node: the bucket
    !!! finds the node, and the node knows where it stands. Nodes are taken from the
    !!! zeroed heap, so a field never written is null.
    @void prev;
    int v;
};

!!! `name table<str, str>`: func_decl_file,
!!! sym_struct_type, display_names, func_ret_struct, _rimp_deferred, _capture_map,
!!! _op_body_types.
type RgStrMap {
    str key;
    int hash;
    @RgStrMap next;
    @void hnext;
    @RgIdx idx;
    !!! The node before this one on the chain of its table. It is what makes taking
    !!! a name out of a table a link and not a second walk to the node: the bucket
    !!! finds the node, and the node knows where it stands. Nodes are taken from the
    !!! zeroed heap, so a field never written is null.
    @void prev;
    str v;
};

!!! `name table<str, bool>`: sym_is_array, sym_is_ref,
!!! sym_is_unsigned, sym_struct_ptr, func_ret_is_unsigned, func_variadic,
!!! _capture_by_ref, _op_body_ptr, _op_body_array.
type RgBoolMap {
    str key;
    int hash;
    @RgBoolMap next;
    @void hnext;
    @RgIdx idx;
    !!! The node before this one on the chain of its table. It is what makes taking
    !!! a name out of a table a link and not a second walk to the node: the bucket
    !!! finds the node, and the node knows where it stands. Nodes are taken from the
    !!! zeroed heap, so a field never written is null.
    @void prev;
    bool v;
};

!!! `name table<str, pair<int,int>>`: func_params_pos,
!!! func_decl_pos, declared_vars, declared_funcs. The pair is (line, col).
type RgPosMap {
    str key;
    int hash;
    @RgPosMap next;
    @void hnext;
    @RgIdx idx;
    !!! The node before this one on the chain of its table. It is what makes taking
    !!! a name out of a table a link and not a second walk to the node: the bucket
    !!! finds the node, and the node knows where it stands. Nodes are taken from the
    !!! zeroed heap, so a field never written is null.
    @void prev;
    int a;
    int b;
};

!!! `a chain of longlong`: the dimensions of a declaration (sym_dims). The little
!!! IntNode of ast.b carries an int, and an longlong is a longlong, so a dimension
!!! keeps a record of its own.
type RgLongNode {
    longlong v;
    @RgLongNode next;
};

!!! `name table<str, a chain of longlong>`: sym_dims.
type RgDimsMap {
    str key;
    int hash;
    @RgDimsMap next;
    @void hnext;
    @RgIdx idx;
    !!! The node before this one on the chain of its table. It is what makes taking
    !!! a name out of a table a link and not a second walk to the node: the bucket
    !!! finds the node, and the node knows where it stands. Nodes are taken from the
    !!! zeroed heap, so a field never written is null.
    @void prev;
    @RgLongNode dims;
    int n;
};

!!! RGenerator::VarDecl: what one variable declaration means - its type plus
!!! everything the readers of the symbol tables ask about. `ty` is the `type`
!!! (the language keeps the word `type` for itself), and the `a chain of longlong`
!!! of dimensions is a chain with its length beside it.
type VarDecl {
    VarType ty;
    int ptr_depth;
    str struct_type;
    bool struct_ptr;
    bool is_array;
    bool is_ref;
    bool is_unsigned;
    @RgLongNode dims;
    int n;
    !!! `int b[n]`: the length expression the declaration was written with, so a
    !!! `count` of the name can answer with it. Null for every other array.
    @ExprNode len_expr;
};

!!! `name table<str, VarDecl>`: _local_decls, the declarations of
!!! the function body being type checked.
type RgVarDeclMap {
    str key;
    int hash;
    @RgVarDeclMap next;
    @void hnext;
    @RgIdx idx;
    !!! The node before this one on the chain of its table. It is what makes taking
    !!! a name out of a table a link and not a second walk to the node: the bucket
    !!! finds the node, and the node knows where it stands. Nodes are taken from the
    !!! zeroed heap, so a field never written is null.
    @void prev;
    @VarDecl decl;
};

!!! `name table<str, VarType>`: syms, sym_call_ret,
!!! extern_ret_types, _op_body_var_types.
type RgVarTypeMap {
    str key;
    int hash;
    @RgVarTypeMap next;
    @void hnext;
    @RgIdx idx;
    !!! The node before this one on the chain of its table. It is what makes taking
    !!! a name out of a table a link and not a second walk to the node: the bucket
    !!! finds the node, and the node knows where it stands. Nodes are taken from the
    !!! zeroed heap, so a field never written is null.
    @void prev;
    VarType ty;
};

!!! `name table<str, a chain of VarType>`: func_param_types.
type RgVarTypeListMap {
    str key;
    int hash;
    @RgVarTypeListMap next;
    @void hnext;
    @RgIdx idx;
    !!! The node before this one on the chain of its table. It is what makes taking
    !!! a name out of a table a link and not a second walk to the node: the bucket
    !!! finds the node, and the node knows where it stands. Nodes are taken from the
    !!! zeroed heap, so a field never written is null.
    @void prev;
    @VarTypeNode types;
    int n;
};

!!! `name table<str, a chain of bool>`: func_param_is_array,
!!! func_param_is_ref, func_param_is_unsigned.
type RgBoolListMap {
    str key;
    int hash;
    @RgBoolListMap next;
    @void hnext;
    @RgIdx idx;
    !!! The node before this one on the chain of its table. It is what makes taking
    !!! a name out of a table a link and not a second walk to the node: the bucket
    !!! finds the node, and the node knows where it stands. Nodes are taken from the
    !!! zeroed heap, so a field never written is null.
    @void prev;
    @BoolNode flags;
    int n;
};

!!! `name table<str, a chain of str>`:
!!! func_param_struct, func_param_names, _pkg_short.
type RgStrListMap {
    str key;
    int hash;
    @RgStrListMap next;
    @void hnext;
    @RgIdx idx;
    !!! The node before this one on the chain of its table. It is what makes taking
    !!! a name out of a table a link and not a second walk to the node: the bucket
    !!! finds the node, and the node knows where it stands. Nodes are taken from the
    !!! zeroed heap, so a field never written is null.
    @void prev;
    @StrNode names;
    int n;
};

!!! One entry of a `a chain of ExprNode*`. The nodes are linked by a record of
!!! their own and not by `ExprNode.next`: an expression node is already an entry of
!!! the list it was parsed in (a call's arguments, a subscript's indices), so
!!! appending it to a second chain would leave the two lists sharing a link.
!!!
!!! A "is this exact node in the chain" test has no `find` helper: the language
!!! rejects comparing two struct pointers, so a caller that has to tell one node
!!! from another tests a field of the node (the lambda id) instead.
type RgExprRef {
    @ExprNode e;
    @RgExprRef next;
};

!!! `name table<str, a chain of ExprNode*>`: func_param_defaults.
type RgExprListMap {
    str key;
    int hash;
    @RgExprRef exprs;
    @RgExprListMap next;
};

!!! RGenerator::OverloadVersion: one declared version of an overloaded name.
type OverloadVersion {
    str internal_name;
    @VarTypeNode param_types;
    @StrNode param_structs;
    int arity;
    bool variadic;
    @OverloadVersion next;
};

!!! `name table<str, a chain of OverloadVersion>`:
!!! func_overloads and method_overloads (the second keyed "<Type>\x01<method>").
type RgOverloadMap {
    str key;
    int hash;
    @OverloadVersion versions;
    int n;
    @RgOverloadMap next;
};

!!! RGenerator::StubProto: the prototype a `stub` introduced, which a later plain
!!! definition of the name has to match. The positions of the parameter types are
!!! chains of ints, as the toolchain vectors of int are.
type StubProto {
    VarType ret_type;
    str ret_struct;
    @VarTypeNode param_types;
    @StrNode param_structs;
    @BoolNode param_is_array;
    @BoolNode param_is_ref;
    bool variadic;
    int line;
    int col;
    int len;
    int ret_type_line;
    int ret_type_col;
    int ret_type_len;
    @IntNode ptype_lines;
    @IntNode ptype_cols;
    @IntNode ptype_lens;
};

!!! `name table<str, StubProto>`: _stub_protos.
type RgStubMap {
    str key;
    int hash;
    @StubProto proto;
    @RgStubMap next;
};

!!! RGenerator::StubMismatch: the first difference between a `stub` prototype and
!!! its implementation, with the source position of both sides so the diagnostic
!!! can point at the parameter (or return type) that does not agree. the toolchain flag
!!! named `any` is `found` here: `any` is one of the type keywords.
type StubMismatch {
    bool is_return;
    int param;
    str param_name;
    str proto_type;
    str impl_type;
    int impl_line;
    int impl_col;
    int impl_len;
    int proto_line;
    int proto_col;
    int proto_len;
};

!!! `name table<str, ExprNode*>`: _method_arg_map, the call
!!! argument of each method parameter name during an inline expansion.
type RgExprMap {
    str key;
    int hash;
    @ExprNode e;
    @RgExprMap next;
};

!!! RGenerator::ConstInfo: one name declared `const`, with where it was declared
!!! (for the note that points at it).
type ConstInfo {
    bool is_const;
    int line;
    int col;
    int len;
};

!!! `name table<str, ConstInfo>`: _static_const and one scope of
!!! _const_scopes.
type RgConstMap {
    str key;
    int hash;
    @ConstInfo info;
    @RgConstMap next;
};

!!! `a chain of name tables`: _const_scopes, the
!!! names in scope with the innermost scope last, so a lookup walks them backwards.
type RgConstScope {
    @RgConstMap entries;
    @RgConstScope next;
};

!!! One warning of -W-nused-struct / -W-read-nused-struct, in the order the
!!! declarations stand in the file.
type RgStructWarn {
    str shown;
    str what;
    int a;
    int b;
    int hl;
    @RgStructWarn next;
};

!!! A read of a field inside a method body, held until the walk has seen every call:
!!! `member` is the field key, `method` the key of the method it stands in.
type RgPendingRead {
    str member;
    str method;
    @RgPendingRead next;
};

!!! RGenerator::PkgMember: one member of a package: emitted under `internal`
!!! ("pkg__name"), reached from outside as "pkg::name" or by `name` once imported.
!!! `kind` is a word the language keeps for its own `kind` declarations, so the
!!! field by that name is `member_kind` here: 0 = variable, 1 = function,
!!! 2 = type.
type PkgMember {
    str pkg;
    str name;
    str internal;
    int member_kind;
    int line;
    int col;
    int len;
};

!!! `name table<str, PkgMember>`: _pkg_members, keyed "pkg::name".
type RgPkgMap {
    str key;
    int hash;
    @PkgMember m;
    @RgPkgMap next;
};

!!! RGenerator::FlatField: a leaf field (nested structs fully expanded) with its
!!! absolute byte offset. the toolchain fills a vector of these, so the record carries
!!! the link of that chain.
type FlatField {
    @StructField field;
    str decl_type;
    int abs_off;
    @FlatField next;
};

!!! One entry of the chain of `pair<const StructField*, str>` records
!!! collect_flat_fields fills: the field and the type that declares it (its
!!! storage name is inst_<decltype>_<field>).
type RgFlatPair {
    @StructField field;
    str decl_type;
    @RgFlatPair next;
};

!!! RGenerator::IndexChainLevel: one subscript of a store written through a chain.
!!! `ty` is the `type` (the language keeps the word `type` for itself, the
!!! rename ast.b and struct_def.b make).
type IndexChainLevel {
    str ty;
    str ret;
    bool ptr;
    @StmtNode setter;
    @IndexChainLevel next;
};

!!! RGenerator::IndexStorePlan: a store through a chain of subscripts, planned
!!! before anything is emitted. `idx` holds every index of the statement and
!!! `fields` the fields written inside the last element, both chains here.
type IndexStorePlan {
    bool heap_array;
    int dims;
    int first;
    str recv_type;
    @StrNode prefix;
    @RgExprRef idx;
    @IndexChainLevel levels;
    @StrNode fields;
};

!!! One entry of the chain of `pair<str,str>` records: a struct local
!!! of the scope being emitted, as (variable name, struct type).
type RgStructLocal {
    str var;
    str stype;
    @RgStructLocal next;
};

!!! One open scope of the function being emitted: _struct_scopes, a
!!! `a chain<a chain<pair<str,str>>>`.
type RgStructScope {
    @RgStructLocal locals;
    @RgStructScope next;
};

!!! RGenerator::ResolvedArg: one resolved BAPI argument, as (formal index, call
!!! argument index). The `a chain of ResolvedArg` resolve_bapi_seg answers with
!!! is this chain.
type ResolvedArg {
    int formal_idx;
    int call_idx;
    @ResolvedArg next;
};

!!! RGenerator::ParamSymFrame: the saved outer-scope symbol values of one function
!!! body's parameters. The saved tables are chains of their own, built while the
!!! body is walked, and `next` is the frame below this one in _param_sym_stack.
type ParamSymFrame {
    @StrNode params;
    @RgVarTypeMap saved;
    @RgStrMap saved_struct;
    @RgBoolMap saved_ref;
    @RgBoolMap saved_unsigned;
    @RgBoolMap saved_struct_ptr;
    @ParamSymFrame next;
    !!! The function takes a variadic tail (`T args...`): the last parameter is the
    !!! pack the caller built, the one array parameter whose length `count` may
    !!! read at run time.
    bool variadic;
};

!!! RGenerator::LocalSymFrame: the saved outer-scope symbol values of the local
!!! declarations of one body, for the same reason: a name may be declared with
!!! different types in different bodies.
type LocalSymFrame {
    @StrNode names;
    @RgBoolMap had_type;
    @RgVarTypeMap saved_type;
    @RgIntMap saved_depth;
    @RgStrMap saved_struct;
    @RgBoolMap saved_array;
    @RgDimsMap saved_dims;
    @RgBoolMap saved_ref;
    @RgBoolMap saved_unsigned;
    @LocalSymFrame next;
};

!!! the methods, one stub each, grouped by implementation file

!!! the free helper the header declares above the class, and the one-line
!!! setter written inside it. The setter is state work, so its body stands in
!!! rgen.b with the state it writes.
stub bool rg_expr_refs_any -> @ExprNode n, @RgStrSet names;
stub void rg_emit_stub_sigs -> bool on;

!!! the constructor and the error reporting.
!!! the toolchain constructor binds the parser, the tokenizer and the driver's two
!!! buffers by reference; in this implementation those are the modules' own globals, so what
!!! is left of it is the -Rimp flag list. An absent `suggestion` (a null pointer
!!! in the toolchain) is the empty text here, and an absent `sug_col` is 0.
stub void rg_rgenerator -> str rimp_flags;
stub void rg_fmt_err -> int line, int col, str msg, int highlight_len,
                       str suggestion, int sug_col, bool show_tilde;

!!! the address types, the unsigned reading of a value and the
!!! constant a `utype T` target can hold. wrap_unsigned_constant() rewrites the
!!! node it is given, so its `ExprNode*& e` is the global
!!! rg_wrap_unsigned_constant_out_e.
stub bool rg_is_unsigned_value -> @ExprNode n;
stub str rg_utype_str_helper -> @ExprNode n;
stub str rg_utype_op_helper -> str op, bool w64;
stub VarType rg_at_of -> VarType t;
stub VarType rg_deref_of -> VarType t;
stub void rg_wrap_unsigned_constant -> VarType t;

!!! the BAPI emission. resolve_bapi_seg() answers the
!!! a chain of ResolvedArg as a chain.
stub @ResolvedArg rg_resolve_bapi_seg -> @StmtNode bapi, @BapiCallSeg seg,
                                          int call_arg_count;
stub void rg_emit_bapi_arg -> @StmtNode bapi, @ResolvedArg r,
                              @ExprNode call_args, bool first;
stub void rg_emit_bapi_stmt -> @StmtNode bapi, @ExprNode call_args,
                               bool one_per_vararg;
stub void rg_emit_bapi_expr -> @StmtNode bapi, @ExprNode call_args;

!!! rgen_builtins
stub void rg_normalize_expr -> @ExprNode n;
stub @StmtNode rg_method_of_call -> @ExprNode receiver, str name;
stub void rg_normalize_stmt -> @StmtNode s;
stub @StrNode rg_builtin_param_names_of -> str name;

!!! the conversion tables and the self-reference test.
stub bool rg_has_self_ref -> @ExprNode n, str name;
stub bool rg_is_wconversion_allowed -> VarType from, VarType to;
stub bool rg_is_free_widening -> VarType from, VarType to;

!!! rgen_check_call
stub bool rg_check_forward_reference -> str name, int line, int col, int len;
stub void rg__check_call_types -> @StmtNode s;

!!! collect_call_sites has two overloads in the toolchain, one per
!!! tree it walks; the parameter kind names them here. `what` is the `const
!!! char*` spelling the position in the diagnostic ("size" or "index").
stub bool rg_check_expr -> @StmtNode d, @ExprNode n, VarType missing;
stub bool rg_check_return_type -> @StmtNode s;
stub bool rg_check_int_index -> @ExprNode e, str what;
stub void rg_gen_body -> @StmtNode body;

!!! rgen_declare
stub void rg_collect_declared_vars;

!!! the diagnostics, written with the libbstr layout the parser
!!! already uses. The list entries and the source blocks are the same text.
stub str rg_src_block -> int line, int col, int highlight_len;
stub void rg_fmt_list_item -> int index, str reason, int line, int col,
                              int highlight_len;
stub int rg_word_col -> int line, int from_col, str word;
stub int rg_operator_keyword_col -> int line, int sym_col;
stub void rg_fmt_note -> int line, int col, str msg, int highlight_len;
stub void rg_fmt_warn -> int line, int col, str msg, int highlight_len;
!!! -W-ntype-cmp: report a comparison of two operands of different types.
stub void rg_report_ntype_cmp -> @ExprNode n, VarType lt, VarType rt;
!!! -W-ntype-op: report an operation on two operands of different types. The span
!!! runs from the first operand through the second, so the whole `1 + "str"` is
!!! underlined and not the operator alone.
stub void rg_report_ntype_op -> @ExprNode n, VarType lt, VarType rt;
stub void rg_emit_rimp_note -> @StmtNode d, @ExprNode n, VarType missing,
                               VarType actual;

!!! the destructor scopes.
stub void rg_push_struct_scope;
stub void rg_note_struct_local -> str var, str stype;
stub void rg_emit_struct_dtor -> str var, str stype;
stub void rg_pop_struct_scope;
stub void rg_pop_all_struct_scopes;
stub void rg_gen_scoped_body -> @StmtNode body;

!!! rgen_emit
stub void rg_emit_r_code;

!!! rgen_expr
stub void rg_rc_expr -> @ExprNode n;

!!! the field and method lookups along the inheritance chain.
stub bool rg_resolve_field_decl -> str stype, str name, bool include_self;
stub @StructField rg_resolve_field -> str stype, str name, bool include_self;
!!! member access (public / protected / private): whether `derived` is `base` or
!!! derives from it, and the report for a member reached from outside the type.
stub bool rg_is_base_of_type -> str base, str derived;
stub bool rg_is_base_of_type_at -> str base, str derived, int depth;
stub void rg_check_member_access -> str decl_type, str name, int access, int line, int col;
stub void rg_check_member_chain_access -> str base_type, @StrNode chain, int line, int col;
!!! The name a guarded member is shown under in that report (an operator by its
!!! symbol, a converting constructor as `init`), and the report for the `destruct`
!!! of a struct parameter, which is a copy destroyed when the function returns.
stub str rg_member_show_name -> str decl_type, str name;
stub void rg_check_param_dtor_access -> @StmtNode f;
stub @StmtNode rg_resolve_method_func -> str stype, str name, bool include_self;
stub @StmtNode rg_resolve_bapi_method -> str stype, str name, bool include_self;

!!! the inline array fields (`int data[N]`). The three
!!! emit_this_field_elem overloads are told apart by their middle
!!! parameter: a list of indices, a single index, or an expression node.
stub str rg_capture_rc_expr -> @ExprNode n;
stub bool rg_resolve_array_base -> @ExprNode base, bool allow_char;
stub str rg_field_linear_index -> @IntNode dims, @ExprNode idx;
stub str rg_field_elem_address_of -> str arr, @StructField f, @ExprNode idx;
stub bool rg_emit_field_elem_address -> @ExprNode n;
stub bool rg_emit_this_field_elem_list -> str name, @ExprNode idx;
stub bool rg_emit_this_field_elem_index -> str name, @ExprNode index;
stub bool rg_emit_this_field_elem_node -> @ExprNode n;
stub bool rg_emit_lvalue_address -> @ExprNode n;
stub @StructField rg_stmt_array_field -> @StmtNode s;
stub void rg_emit_call_arg_value -> @ExprNode a;
stub bool rg_report_field_array_assign -> @StmtNode s;
stub bool rg_emit_field_array_store -> @StmtNode s;

!!! the member chains and everything they answer through
!!! their out-parameters (the leaf field, the absolute offset, the .r text).
stub str rg_emit_fld -> str instance, str stype, str field, bool super_access,
                        bool through_ptr, int line, int col;
stub bool rg_member_chain_type -> @ExprNode n, str base_type;
stub bool rg_resolve_member_chain -> @ExprNode n, str base_type;
stub int rg_struct_layout_size -> str stype;
stub str rg_pointer_base_text -> str name;
stub bool rg_method_field_block_info -> str name;
stub VarType rg_method_field_elem_type -> str name;
stub bool rg_member_chain_block_info -> @ExprNode base;
stub bool rg_pointer_element_address -> @ExprNode n;
stub int rg_pointer_step_size -> str name;
stub bool rg_pointer_field_elem_address -> @ExprNode n;
stub VarType rg_pointer_element_type -> str name;
stub bool rg_method_field_is_struct_ptr -> str name;
stub str rg_method_field_struct_type -> str name;
stub bool rg_emit_pointer_chain -> @ExprNode n;
stub bool rg_resolve_field_chain -> str base_type, @StrNode chain, int line, int col;
stub str rg_receiver_struct_type -> @ExprNode recv;
stub str rg_receiver_struct_type_of -> str name;
stub bool rg_receiver_info -> @ExprNode recv, bool report;
stub bool rg_emit_field_chain_address -> str base_var, str base_type,
                                         @StrNode chain;
stub bool rg_emit_receiver_address -> @ExprNode recv;
stub bool rg_chain_root_is_field_elem -> @ExprNode n;
stub str rg_expr_struct_type -> @ExprNode n;
stub bool rg_expr_definitely_not_struct -> @ExprNode n;
stub bool rg_rimp_is_allowed -> str pair;

!!! the flat and leaf field layouts. The `out` vectors and
!!! the `visited` set are the globals rg_collect_flat_fields_out,
!!! rg_collect_leaf_fields_out and both _out_visited sets in rgen.b.
stub void rg_collect_flat_fields -> str stype;
stub int rg_collect_leaf_fields -> str stype, int base_off;
stub str rg_field_ref_var -> str instance, str stype, str field, bool super_access;
stub VarType rg_field_eff_type -> @StructField f;
stub int rg_field_elem_size -> @StructField f;
stub int rg_field_byte_size -> @StructField f;
stub int rg_field_offset_in -> str stype, str field, str decl_type;
stub int rg_field_offset_of -> str stype, str field, str decl_type;

!!! the free-variable collection of the lambda support. The
!!! `out` and `seen` are globals (rg_..._out, rg_..._out_seen).
stub void rg_collect_free_vars_expr -> @ExprNode e;
stub void rg_collect_free_vars_stmts -> @StmtNode body;
stub void rg_resolve_body_stmts -> @StmtNode body;
stub void rg_collect_written_vars_stmts -> @StmtNode body;

!!! the pass order. The statement list it works on is
!!! rg_stmts in rgen.b (the toolchain reads parser.statements()).
stub str rg_generate;

!!! the small predicate helpers.
stub bool rg_is_builtin_func -> str name;
stub str rg_resolve_call_name -> str name;
stub bool rg_is_callable_var -> str name;
stub bool rg_is_ref_param -> str fname, int idx;
stub bool rg_is_ref_var -> str name;
stub str rg_cap_ref_name -> str name;

!!! the `any` runtime type tags and the linear index.
stub str rg_rc_any_tag -> @ExprNode n;
stub str rg_linear_index_expr -> str var_name, @ExprNode indices;

!!! rgen_inheritance
stub void rg_validate_inheritance;

!!! rgen_lambda
stub bool rg_resolve_lambda -> @ExprNode n;
stub void rg_resolve_body_lambdas -> @StmtNode body;
stub void rg_resolve_stmt_lambdas -> @StmtNode s;
stub void rg_resolve_expr_lambdas -> @ExprNode e;

!!! rgen_lambda_gen
stub void rg_gen_lambda_function -> @ExprNode n;

!!! the `args`, `arg_names`, `name_lines`, `name_cols` and
!!! `name_lens` vectors are reordered in place; in this implementation they are
!!! the five rg_normalize_call_args_out_* globals. `method_params` and
!!! `method_defaults` are the optional vectors of the toolchain, so a null chain means
!!! "the caller could not resolve them".
stub void rg_normalize_call_args -> str fname, int err_line, int err_col,
                                    int err_len, int arg_start,
                                    @StrNode method_params,
                                    @ExprNode method_defaults;

!!! the `reload` overload sets, functions and methods.
stub str rg_overload_mangle -> @StmtNode f;
stub str rg_overload_signature -> @StmtNode f;
stub bool rg_pick_overload -> str name, @ExprNode args, int line, int col,
                              int tok_len;
stub bool rg_pick_from_versions -> @OverloadVersion versions, str name,
                                   @ExprNode args, int line, int col, int tok_len;
stub bool rg_pick_method_overload -> str stype, str name, @ExprNode args,
                                     int line, int col, int tok_len;
stub void rg_resolve_method_overload_expr -> @ExprNode n;
stub void rg_resolve_method_overload_stmt -> @StmtNode s;
stub void rg_resolve_overloads_expr -> @ExprNode n;
stub void rg_resolve_overloads_stmt -> @StmtNode s;
stub void rg_resolve_overloads -> @StmtNode stmts;
stub bool rg_overload_error_reported -> str name, int line, int col;

!!! the package expansion. The `local` table of
!!! collect_package_member is filled by it, so it is a global; the one
!!! rename_package_member and the rewrite helpers read is a chain parameter.
stub void rg_rewrite_pkg_refs_expr -> @ExprNode n, @RgStrMap lmap;
stub void rg_rewrite_pkg_refs_stmt -> @StmtNode s, @RgStrMap lmap;
stub void rg_collect_package_member -> str pkg, @StmtNode m;
stub void rg_rename_package_member -> str pkg, @StmtNode m, @RgStrMap lmap;
stub @StmtNode rg_expand_packages -> @StmtNode stmts;
stub void rg_report_pkg_member -> @PkgMember m, str name, int line, int col,
                                  int len;
stub int rg_package_resolve -> int line, int col, int len;

!!! the parameter and local variable scopes. The `name` of
!!! resolve_global_ref-style in-out parameters is not here: `this_field_address`
!!! answers through rg_this_field_address_out.
stub bool rg_is_func_param -> str name;
stub bool rg_method_field_shadows -> str name;
stub bool rg_name_is_pointer -> str name;
stub bool rg_this_field_address -> str name;
stub void rg_push_func_params -> @StmtNode s;
stub void rg_pop_func_params;
stub void rg_push_local_decls -> @StmtNode body;
stub void rg_pop_local_decls;

!!! the hoisting of struct values a call returns. Both
!!! hoist helpers replace the child node they are given, so that node travels in
!!! rg_hoist_struct_call_out_child / rg_hoist_array_element_address_out_child.
stub void rg_hoist_struct_call;
stub void rg_hoist_array_element_address;
stub void rg_prepare_expr_calls -> @ExprNode n;
stub void rg_prepare_stmt_struct_calls -> @StmtNode s;

!!! materialize_ctor_wrappers() inserts the generated
!!! constructor functions in front of the statement list, so it answers the new
!!! head the way this design asks (the toolchain assigns to its vector).
stub @StmtNode rg_materialize_ctor_wrappers -> @StmtNode stmts;
stub bool rg_stub_proto_mismatch -> @StubProto p, @StmtNode s;
stub void rg_register_funcs;

!!! The generated store helpers of the assignments written as expressions: the tag
!!! and the name of one, the function itself, and the point the resolver asks for it
!!! (see rg_resolve_assign).
stub str rg_assign_helper_tag -> @ExprNode target;
stub str rg_assign_helper_name -> @ExprNode target, bool seq;
stub void rg_ensure_assign_helper -> @ExprNode target, bool seq;

!!! rgen_prepare_calls.b: the lowering of an assignment written as an expression
!!! into a call of its helper.
stub @ExprNode rg_clone_assign_target -> @ExprNode t;
stub @ExprNode rg_build_assign_call -> @ExprNode n;
stub @ExprNode rgx_lower_assign_chain -> @ExprNode head;
stub void rg_lower_assign_in;
stub void rg_lower_assign_exprs -> @StmtNode s;

!!! rgen_check_expr.b: the type of an assignment written as a value.
stub bool rg_resolve_assign -> @ExprNode n;

!!! rgen_register_builtin
stub void rg_register_builtins -> @StmtNode stmts;

!!! resolve_expr_type marks the node resolved, the per-kind
!!! bodies do the work.
stub bool rg_resolve_expr_type -> @ExprNode n;
stub bool rg_resolve_expr_type_body -> @ExprNode n;

!!! rgen_resolve_call
stub bool rg_resolve_call -> @ExprNode n;

!!! rgen_resolve_index
stub bool rg_resolve_array_access -> @ExprNode n;
stub bool rg_resolve_field_elem -> @ExprNode n;

!!! rgen_resolve_member
stub bool rg_resolve_member -> @ExprNode n;

!!! rgen_resolve_op
stub bool rg_resolve_operator -> @ExprNode n;

!!! rgen_resolve_size
stub bool rg_resolve_size -> @ExprNode n;
stub bool rg_resolve_count -> @ExprNode n;

!!! `name` is the in-out parameter of resolve_global_ref,
!!! so it is the global rg_resolve_global_ref_out_name.
stub bool rg_resolve_var_ref -> @ExprNode n;
stub int rg_resolve_global_ref -> int line, int col, int len;

!!! rgen_rewrite_forward
stub void rg_rewrite_forward_expr -> @ExprNode n, str annot, @StrNode params;
stub void rg_rewrite_forward_stmt -> @StmtNode s, str annot, @StrNode params;
stub void rg_rewrite_builtin_forward -> @StmtNode stmts;

!!! the overloaded operators, the converting
!!! constructors and the stores through a chain of subscripts. The `ExprNode*&`
!!! slots the rewriters replace (rewrite_operator_expr, rewrite_binary_operator,
!!! rewrite_unary_operator, rewrite_subscript, rewrite_conversion, wrap_ctor,
!!! wrap_conversion) are the rg_..._out_slot / rg_..._out_n globals of rgen.b.
!!! The `int* access` out-parameter of find_ctor_func / find_ctor_limbs is the
!!! rg_find_ctor_func_out_access / rg_find_ctor_limbs_out_access global.
stub bool rg_pointer_operand -> @ExprNode n;
stub bool rg_pointer_operand_name -> str name;
stub str rg_operator_struct_type -> @ExprNode n;
stub void rg_collect_operator_body_types -> @StmtNode body;
stub str rg_find_ctor_func -> str stype, VarType src;
stub str rg_find_ctor_limbs -> str stype;
stub bool rg_int_literal_value -> @ExprNode n;
stub bool rg_op_value_type -> @ExprNode n;
stub bool rg_ctor_literal_fits -> @ExprNode slot, VarType param;
stub bool rg_wrap_ctor -> str stype;
stub str rg_pick_any_conversion -> str st;
stub bool rg_wrap_conversion -> str target;
stub bool rg_callee_param_types -> str name, bool has_receiver,
                                   @ExprNode receiver, bool resolved;
stub void rg_wrap_arguments -> str callee, @ExprNode args, int first_param,
                               bool has_receiver, @ExprNode receiver,
                               int line, int col, int tok_len, bool resolved;
stub void rg_wrap_overload_args_expr -> @ExprNode n;
stub void rg_wrap_overload_args_stmt -> @StmtNode s;
stub void rg_wrap_overload_args -> @StmtNode stmts;
stub void rg_wrap_stmt_conversions -> @StmtNode s;
stub str rg_op_param_spelling -> @StmtNode f, int i;
stub void rg_emit_operator_list -> str stype, str sym, int want_params,
                                   str arg_type;
stub void rg_report_no_operator -> @ExprNode n, str sym;
stub void rg_report_no_operator_at -> str stype, str sym, int line, int col,
                                      int len;
stub void rg_rewrite_binary_operator;
stub void rg_rewrite_unary_operator;
stub str rg_operator_name_struct_type -> str name;
stub int rg_array_var_dims -> str name;
stub void rg_report_too_many_indices -> str name, int dims, int got, int line,
                                       int col, int len;
stub bool rg_index_getter_is_pointer -> str stype;
stub str rg_index_store_receiver_type -> @StmtNode s;
stub bool rg_mark_index_ptr_store -> @StmtNode s;
stub void rg_rewrite_subscript;
stub int rg_struct_flat_size -> str stype;
stub VarType rg_index_pointer_pointee -> str stype;
stub bool rg_emit_store_at_pointer -> str addr, str elem, str owner,
                                      @StrNode fields, @ExprNode value;
stub bool rg_plan_index_store -> @StmtNode s;
stub void rg_report_index_store_unsupported -> @StmtNode s;
stub bool rg_emit_index_chain_store -> @StmtNode s;
stub bool rg_rewrite_subscript_assign -> @StmtNode s;
stub bool rg_index_field_layout -> @StmtNode s;
stub bool rg_is_index_field_assign -> @StmtNode s;
stub bool rg_emit_index_ptr_store -> @StmtNode s;
stub bool rg_emit_index_field_assign -> @StmtNode s;
stub void rg_rewrite_conversion;
stub void rg_rewrite_operator_expr;
stub void rg_emit_synth_comparison -> str stype, str other, str sym;
stub void rg_rewrite_operator_stmt -> @StmtNode s;
stub void rg_rewrite_operators -> @StmtNode stmts;
stub void rg_begin_operator_body_types -> @StmtNode fn;
stub void rg_rewrite_operator_stmt_body -> @StmtNode body;

!!! the .r spelling of a type. `type_name` returns a `const char*`
!!! in the toolchain, which is a `str` here.
stub str rg_rtype -> VarType t;
stub str rg_rustype -> VarType t, bool is_unsigned;
stub str rg_rtype_depth -> VarType t, int depth;
stub str rg_type_name -> VarType t;
stub bool rg_is_at_type -> VarType t;
stub VarType rg_pointee_of -> VarType t;

!!! the public .r FUNCs of the builtins.
stub void rg_emit_builtin_runtime;

!!! the symbol lookups and the spelling suggestion.
stub bool rg_effective_var_decl -> str name;
stub str rg_struct_type_in_effect -> str name;
!!! Whether a variable of this name is in scope where the expression stands. A
!!! variable shadows a function of the same name: `cur` is a local of one body and
!!! a method of the lexer in another, and the local was read as the closure object
!!! of the method.
stub bool rg_var_in_scope -> str name;
stub bool rg_var_is_struct_ptr -> str name;
stub str rg_closest_symbol -> str name;
stub int rg_edit_distance -> str a, str b;

!!! the `static` locals. materialize_static_in_func() fills the
!!! vector of hidden globals it adds (the global
!!! rg_materialize_static_in_func_out_new_globals) and materialize_static_locals()
!!! puts them in front of the statement list, so it answers the new head.
stub void rg_rename_static_uses -> @StmtNode body, str from, str to;
stub void rg_register_global_decl -> @StmtNode s;
stub void rg_materialize_static_in_func -> @StmtNode fn;
stub @StmtNode rg_materialize_static_locals -> @StmtNode stmts;

!!! rgen_stmt
stub void rg_gen_stmt -> @StmtNode s;

!!! rgen_stmt_call
stub void rg_gen_stmt_call -> @StmtNode s;

!!! rgen_stmt_declare
stub void rg_gen_stmt_declare -> @StmtNode s;

!!! rgen_stmt_struct
stub void rg_gen_stmt_struct -> @StmtNode s;

!!! the whole-struct field copies.
stub bool rg_emit_struct_source_address -> @ExprNode src;
stub str rg_materialize_struct_value -> @ExprNode call, str stype;
stub void rg_emit_struct_leaf_copy -> str dst_addr, str target_type,
                                      str src_addr;
stub bool rg_emit_struct_field_copy -> @StmtNode s;
stub bool rg_emit_struct_decl_copy -> @StmtNode s;

!!! the BLANG_API struct methods.
stub bool rg_is_struct_method -> str func_name, str struct_var;
stub @StmtNode rg_find_struct_bapi -> str func_name, str struct_var;

!!! the generic structs. `name`, `vt`, `tmap` and
!!! `defs` travel in the globals rg_resolve_struct_type_slot_out_name /
!!! _out_vt (the toolchain rewrites both) and rg_..._out_defs; a new instantiation is
!!! queued in `defs`, so each function that queues one answers the new chain
!!! through its own global.
stub @StmtNode rg_materialize_struct_templates -> @StmtNode stmts;
stub void rg_collect_struct_def_names -> @StmtNode s;
stub void rg_resolve_struct_definition -> str name;
stub void rg_resolve_struct_type_slot -> @TArgMap tmap, int line, int col;
stub str rg_resolve_struct_spelling -> str sp, @TArgMap tmap, int line, int col;
stub void rg_materialize_struct_template -> str tname, str mangled,
                                            @TArgMap tmap;
stub void rg_resolve_struct_types_stmt -> @StmtNode s, @TArgMap tmap,
                                          str self_name, str mangled;

!!! the function templates. instantiate_templates() inserts the
!!! clones in front of the statement list, so it answers the new head. The `done`
!!! set and the `new_stmts` vector the toolchain shares down the descent are globals
!!! per method (rg_<method>_out_done / _out_new_stmts).
stub str rg_instantiate_template_call -> str name, @ExprNode args, int line,
                                         int col;
stub str rg_targ_display -> @TArg a;
!!! The type argument one call argument gives, for the parameters an explicit type
!!! list does not cover.
stub bool rg_targ_from_arg -> @ExprNode arg, @TArg out;
stub bool rgt_bool_any -> @BoolNode head;
stub int rgt_targ_n -> @TArg head;
!!! Whether an instantiation the template never mentions has to give a parameter:
!!! a body that names it, or a return type that is it.
stub bool rg_tparam_used_in -> @StmtNode body, str name;
stub bool rg_tparam_used_in_expr -> @ExprNode n, str name;
!!! Building one instantiated parameter list from a type pack: the parameters, and
!!! the rewriting of the body that reaches them through the argument pack.
stub void rg_expand_pack_params -> @StmtNode inst, @TArgMap tmap, int line, int col;
stub void rg_expand_pack_stmt -> @StmtNode body, str pack, @StrNode names, int line, int col;
stub @ExprNode rg_expand_pack_chain -> @ExprNode head, str pack, @StrNode names,
                                       int line, int col;
stub @ExprNode rg_expand_pack_expr -> @ExprNode n, str pack, @StrNode names,
                                      int line, int col;
stub @ExprNode rg_expand_pack_args -> @ExprNode head, str pack, @StrNode names;
stub @ExprNode rg_pack_fold -> str op, @StrNode names, bool right, @ExprNode from;
stub @ExprNode rg_pack_var_ref -> str name, @ExprNode from;
stub void rg_report_missing_targ -> str name, str tparam, int line, int col;
stub str rg_display_name -> str name;
stub void rg_report_value_needed -> str name, str tparam, int line, int col;
stub void rg_rename_var_expr -> @ExprNode n, str from, str to;
stub void rg_rename_var_stmts -> @StmtNode body, str from, str to;
stub void rg_collect_declare_names -> @StmtNode body;
stub void rg_rename_declared_local -> @StmtNode body, str from, str to;
stub str rg_materialize_template -> str name, str mangled, @TArgMap tmap,
                                    int line, int col;
stub str rg_instantiate_template_explicit -> str name, @VarTypeNode targs,
                                             @StrNode targ_structs,
                                             @ExprNode targ_exprs,
                                             @BoolNode targ_is_value,
                                             @ExprNode call_args,
                                             int line, int col;
stub void rg_instantiate_expr -> @ExprNode n;
stub void rg_instantiate_stmt -> @StmtNode s;
stub void rg_register_declare_locals -> @StmtNode s, str scope;
stub @StmtNode rg_instantiate_templates -> @StmtNode stmts;
stub void rg_check_template_bodies;

!!! `try { } exception (e) { }` and `throw`.
stub void rg_gen_try_catch -> @StmtNode s;
stub void rg_gen_throw -> @StmtNode s;

!!! rgen_type_note
stub void rg_emit_type_note -> @StmtNode d, @ExprNode n, VarType missing,
                               VarType actual;

!!! the argument chains, counted and rebuilt.
stub int rgx_na_len_expr -> @ExprNode head;

!!! rgen_typecheck
stub void rg_typecheck_pass;

!!! `rule <NAME>(...)`, the built-in checks the program asked
!!! for. It runs once what the statements call is settled, before the rest of the
!!! validation reports on them (see rg_generate.b).
stub void rg_apply_rules;

!!! The two diagnostics of apply_attributes() (rgen_declare) - the object of an
!!! attribute is declared, and it is declared above the attribute. What an
!!! attribute says is applied by rg_apply_attr_decl and rg_apply_attr_used, so this
!!! pass is the checks alone, at the place the toolchain makes them (see rg_generate.b).
stub void rg_apply_attr_checks;

!!! the -W-nused tracking.
stub void rg_mark_used_expr -> @ExprNode n;
stub void rg_mark_used_stmt -> @StmtNode s;
stub void rg_check_unused;

!!! the control-flow and const-write passes. const_info_of()
!!! answers a `const ConstInfo*` in the toolchain, which is an `@ConstInfo` here.
stub void rg_validate_control_flow;
stub @ConstInfo rg_const_info_of -> str name;
stub void rg_check_const_body -> @StmtNode body;
stub void rg_check_const_stmt -> @StmtNode s;
stub void rg_check_const_writes;

!!! the statement-tree walk. the toolchain takes the per-statement
!!! action as a `function<void(StmtNode*)>`; the language has no function
!!! values, so the action is named by `action`, an int selecting what the walk
!!! applies to every statement it visits: 1 is the collect of register_funcs()
!!! (rgen_register), 2 the type check of typecheck_pass() (rgen_typecheck)
!!! - the only two callers in the toolchain, and each passed a lambda that stands next
!!! to the method in its own file. The chain of statements the callback was
!!! applied to is the walk's subject, rg_stmts or a body of it.
stub bool rg_symbol_visible_here -> str name;
stub void rg_walk_stmts -> @StmtNode stmts, int action;

!!! the same walk with the enclosing function's scope. Its
!!! only caller is collect_declared_vars() (rgen_declare), whose lambda is the
!!! action, so no selector is needed: this implementation calls the collect there.
stub void rg_walk_stmts_scoped -> @StmtNode stmts, str scope;
