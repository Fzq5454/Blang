#once
!~
 ~  bootstrap/frontend/rgen.b: the state of RGenerator and its helpers.
 ~
 ~  The member variables class live here as `rg_`-prefixed globals, in
 ~  the order the header declares them and with the comment the header keeps above
 ~  each one. The chains the toolchain containers become live here too, with the two
 ~  operations every reader of such a table needs, and so do
 ~  the out-parameter globals of the methods: a `str& out`, `int& off`,
 ~  `VarType& t`, `ExprNode*& n`, `a chain of ...& out` or `VarDecl& out` is not a
 ~  parameter of this converted function, it is `rg_<method>_out[_<param>]` (this design
 ~  section 3). The passes themselves are in the rgen_*.b modules, one per
 ~  file.
 ~
 ~  Every helper body follows the same shape:
 ~   * `find` walks the chain and answers the record the key names, or null;
 ~   * `set` replaces the value of that record, or appends a new one at the tail,
 ~     so a chain keeps insertion order (the toolchain unordered_* has no order of its
 ~     own, so that is the order this implementation keeps);
 ~   * `has` / `add` are the same two things for a table that only ever asks
 ~     whether a name is there. the `insert(key).second` idiom reads as "add it
 ~     when `rg_set_has` says it is not there yet";
 ~   * `drop` is the `erase(key)`, for the tables the toolchain removes names from
 ~     again when a scope closes.
 ~!

#head "stdsrt"
#head "lexer"
#head "ast"
#head "struct_def"
#head "clone"
#head "parser_heads"
#head "rgen_heads"

!!! the state the toolchain class declares

!!! The constructor binds four things by reference: the Parser, its Tokenizer, the
!!! error buffer and the note buffer. There is no object to bind here - the parser
!!! and the lexer are modules whose own globals are the state the generator reads
!!! (p_cur, p_pos, p_struct_defs, p_bapi_defs and the p_find_* helpers in parser.b,
!!! g_base, g_line_off and the line/source helpers in lexer.b) - so only the two
!!! buffers are left. A null `str&` cannot appear, which is why they are
!!! plain texts here.

!!! str& err: the error buffer the driver owns and prints at the end.
str rg_err;
!!! str& notes: the notes/warnings buffer, flushed to stdout last.
str rg_notes;
bool rg_has_errors = false;
!!! parser.statements(): the top-level statement list. The driver puts the chain
!!! parse_program() answered here, and every pass that inserts statements (the
!!! constructor wrappers, the static locals, the template clones, the packages)
!!! writes the possibly-new head back.
@StmtNode rg_stmts;

!!! func_params_pos: where a function's parameter list was written.
@RgPosMap rg_func_params_pos;
!!! func_params_hl: the length to highlight in that parameter list.
@RgIntMap rg_func_params_hl;

!!! Function declaration position, used to reject forward references: calling a
!!! function before its definition is reported as "undeclared".
@RgStrMap rg_func_decl_file;   !!! func_decl_file: original file of the declaration.
@RgIntMap rg_func_decl_line;   !!! func_decl_line: original line of the declaration.
@RgPosMap rg_func_decl_pos;    !!! func_decl_pos: (preprocessed line, col) for the "declared here" note.

@RgVarTypeMap rg_syms;         !!! syms: var_name -> its type.
@RgIntMap rg_sym_depth;        !!! sym_depth: var_name -> pointer depth.
@RgVarTypeMap rg_sym_call_ret; !!! sym_call_ret: func/@func var -> return type when called.
@StrNode rg_cur_func_closures; !!! _cur_func_closures: func/@func locals of the current function (for release).
@RgStrSet rg_cur_func_released; !!! _cur_func_released: closures already RELEASE'd at a return point.
@RgStrMap rg_sym_struct_type;  !!! sym_struct_type: var_name -> struct type name (empty = not a struct).
@RgBoolMap rg_sym_is_array;    !!! sym_is_array: for ARRAY_ACCESS, array vs string index.
@RgBoolMap rg_sym_is_ref;      !!! sym_is_ref: var_name -> reference variable (auto-deref).
!!! sym_is_unsigned: var_name -> a `utype T` declaration: the value reads, prints
!!! and divides as an unsigned one of the same width.
@RgBoolMap rg_sym_is_unsigned;
@RgBoolMap rg_sym_struct_ptr;  !!! sym_struct_ptr: var_name -> `@Struct` pointer variable.
@RgDimsMap rg_sym_dims;        !!! sym_dims: the multi-D dimensions of a declaration.
@RgStrSet rg_non_global_syms;  !!! _non_global_syms: symbols not in global scope (params + func locals).
@RgStrSet rg_global_names;     !!! _global_names: names declared in the global scope.

!!! _local_decls: what one variable declaration of the body being type checked
!!! means. A function body is type checked with the declarations seen so far in
!!! that body, so two bodies (or two blocks of one body) can use a name for
!!! different things. The flat tables above stay authoritative for everything
!!! else: globals, package members, parameters and the bodies that are not walked
!!! as a function body here.
@RgVarDeclMap rg_local_decls;
bool rg_in_func_body = false;  !!! _in_func_body: the declaration table above is in use.
bool rg_track_locals = false;  !!! _track_locals: the walk being run is the type checking one.

@RgIntMap rg_func_arity;       !!! func_arity: function name -> arity.
!!! display_names: symbols stored under an internal name map back to the name the
!!! user wrote - an instantiated template `add` is stored as `add_int`, a package
!!! member `mypkg::f` as `mypkg__f`. Diagnostics show the source name.
@RgStrMap rg_display_names;
!!! _arity_reported: call sites that already reported an arity error, keyed by
!!! line:col:name, so the many resolve_expr_type() passes report each one once.
@RgStrSet rg_arity_reported;
!!! _deduce_reported: template deduction failures already reported (keyed by
!!! line:col:name), so the instantiation rounds do not repeat them.
@RgStrSet rg_deduce_reported;
!!! _index_reported: subscript diagnostics already reported (keyed by line:col),
!!! so the many resolve_expr_type() passes report each one once.
@RgStrSet rg_index_reported;
@RgVarTypeListMap rg_func_param_types;    !!! func_param_types: function name -> param types.
@RgBoolListMap rg_func_param_is_array;    !!! func_param_is_array: function name -> array-param flags.
!!! func_param_struct: function name -> struct name of each parameter ("" =
!!! non-struct). A struct parameter takes the struct value itself, never a
!!! converted scalar.
@RgStrListMap rg_func_param_struct;
@RgBoolListMap rg_func_param_is_ref;      !!! func_param_is_ref: function name -> ref-param flags.
!!! func_param_is_unsigned: function name -> unsigned-param flags, and
!!! func_ret_is_unsigned the return value's, which the call site and the type
!!! checking read the way they read the types.
@RgBoolListMap rg_func_param_is_unsigned;
@RgBoolMap rg_func_ret_is_unsigned;
@RgBoolMap rg_func_variadic;              !!! func_variadic: function name -> variadic flag.
@RgStrListMap rg_func_param_names;        !!! func_param_names: function name -> param names.
@RgExprListMap rg_func_param_defaults;    !!! func_param_defaults: function name -> default values.
!!! func_ret_struct: function name -> struct type it returns ("" = not a struct).
!!! Lets a call expression be recognised as a struct value (`o.in = make();`).
@RgStrMap rg_func_ret_struct;
!!! Overload sets: source name -> every declared version of that name. The first
!!! definition (written without `reload`) keeps the plain name; each `reload`
!!! version registers under a mangled internal name so the .r backend can tell the
!!! versions apart. resolve_overloads() rewrites each call site to the internal
!!! name matching the call's arguments.
@RgOverloadMap rg_func_overloads;
!!! method_overloads: the `reload` versions of one method, keyed
!!! "<Type>\x01<method name>". The first declaration of the name is the first
!!! version, every `reload` adds one.
@RgOverloadMap rg_method_overloads;

!!! _stub_protos: prototypes introduced by `stub`, keyed by function name. A later
!!! plain definition of that name is taken as the implementation and has to match
!!! the prototype exactly.
@RgStubMap rg_stub_protos;
!!! _stub_sigs: -m writes .bmeta out of the FUNC lines of the .r, and a linked-DLL
!!! declaration file is nothing but stubs, which normally write no FUNC line at
!!! all. With this on, a stub writes its signature and an empty body, so the
!!! signature can be harvested. The body stays empty, so nothing here can be taken
!!! for an implementation.
bool rg_stub_sigs = false;
!!! _tmp_var_counter: counter for hidden temporaries (`__sc<N>`) used when a
!!! struct value has to be evaluated once before it is copied leaf by leaf.
int rg_tmp_var_counter = 0;
!!! _emitted_structs and _emitted_funcs: definitions already written to the .r
!!! output. A repeated `#head` inclusion parses a type or a function twice, and
!!! emitting the second copy would give the backend two functions of one name
!!! whose bodies differ (the temporaries they use are numbered per emission).
@RgStrSet rg_emitted_structs;
@RgStrSet rg_emitted_funcs;
!!! rcode: the .r text being built. It is the growing buffer `rg_rcode` of
!!! rgen_out.b, which is where every `rg_rcode = rg_rcode + text` in this implementation
!!! appends without copying the text again.
@RgStrSet rg_rimp_allowed;     !!! rimp_allowed: "type1-type2" pairs from -Rimp flags.
bool rg_wconversion = false;   !!! Wconversion: -Econversion, enable safe implicit conversions.
bool rg_warn_unused = false;   !!! WarnUnused: -W-nused, warn about unused variables/functions.
!!! WarnReadUnused: -W-read-nused, warn about variables whose value is never read
!!! (the toolchain "set but not used"). A name that is written and never read is
!!! reported here even though -W-nused stays quiet about it.
bool rg_warn_read_unused = false;
@RgStrSet rg_extern_funcs;     !!! extern_funcs: "extern=func:type" from -link flags.
!!! extern_ret_types: return type of a function the program only imports (see
!!! extern_funcs). A name with no entry here is typed int, which is what every
!!! extern used to get; a DLL function returning a str has to say so or its result
!!! is printed as the pointer it actually is.
@RgVarTypeMap rg_extern_ret_types;
!!! extern_ret_unsigned: the imported functions whose .bmeta declared their result
!!! unsigned (`utype int`, `utype longlong`, `utype char`). A DLL hands back values
!!! Windows means without a sign - GetLastError is 0xFFFFFFFF, not -1 - so the call
!!! site has to know: the result is then printed, divided and compared the
!!! unsigned way, exactly as if the program had written utype itself.
@RgStrSet rg_extern_ret_unsigned;
@RgStrSet rg_used_vars;        !!! used_vars: variables referenced (read or written).
!!! read_vars: variables whose *value* was read, which -W-read-nused reports about.
!!! A write is not a read, and neither is an increment.
@RgStrSet rg_read_vars;
@RgStrSet rg_used_funcs;       !!! used_funcs: functions called / exported / entry points.
@RgPosMap rg_declared_vars;    !!! declared_vars: name -> (line,col).
@RgPosMap rg_declared_funcs;   !!! declared_funcs: name -> (line,col).
!!! -W-nused-struct: a struct nothing mentions, a member nothing reads or writes and
!!! a method nothing calls. -W-read-nused-struct: a member that is written and whose
!!! value is never read, the member form of -W-read-nused.
bool rg_warn_unused_struct = false;
bool rg_warn_read_unused_struct = false;
!!! -W-nbody-func: a function that is only declared (`stub`) is called and no
!!! definition of it follows. The backend reports it as an undefined reference in the
!!! temporary .r; this reports it where the declaration stands.
bool rg_warn_nbody_func = false;
!!! -W-ntype-cmp: a comparison (`==`, `!=`, `<`, `>`, `<=`, `>=`) whose two operands
!!! have different types. A comparison against `null`, or against the untyped
!!! `@void` the allocator hands back, is how the language spells those, so it is
!!! not reported.
bool rg_warn_ntype_cmp = false;
!!! -W-ntype-op: an arithmetic or bit operation (`+`, `-`, `*`, `/`, `&`, `|`, `^`,
!!! `<<`, `>>`) whose two operands have different types. The values are read as one
!!! type and the answer is not the one the reader had in mind (`1 + "str"`
!!! concatenates instead of adding). Pointer arithmetic (`p + 1`), which is a
!!! different type on purpose, is not reported.
bool rg_warn_ntype_op = false;
!!! -W-userdef: the report of a check a program wrote for itself and wrapped in
!!! `rule warn(...)`. The check runs either way; only the report waits for this
!!! switch, and it is always a warning, whatever level the rule inside named.
bool rg_warn_userdef = false;
!!! _stub_decls: the declarations that kept no body, name -> (line,col);
!!! _defined_funcs: the names a body was written for; _called_funcs: the names a
!!! plain (non-method) call reached.
@RgPosMap rg_stub_decls;
@RgStrSet rg_defined_funcs;
@RgStrSet rg_called_funcs;
!!! used_structs: struct types the program mentions; member_used / member_read: the
!!! fields read or written and the fields whose value is read; method_used: the
!!! methods the compiler reached. A member and a method are keyed
!!! "<struct>\x01<name>", the way the `reload` sets are.
@RgStrSet rg_used_structs;
@RgStrSet rg_member_used;
@RgStrSet rg_member_read;
@RgStrSet rg_method_used;
!!! The struct whose method bodies the walk is inside (a bare name there is a field
!!! of it), the method itself, and the declaration of every name the body has seen
!!! (the body being walked first, then the globals): the tables the rest of the
!!! compiler uses for that hold the last body it looked at, not this one.
str rg_walk_struct_type = "";
str rg_walk_struct_method = "";
@RgStrMap rg_walk_var_types;
@RgStrMap rg_walk_global_types;
bool rg_walk_in_body = false;
!!! The reads that stood in a method body, held until the walk has seen every call:
!!! a method nothing calls reads nothing.
@RgPendingRead rg_pending_member_reads;
!!! The structs a pointer is read as (`(@Y)x`) and the structs handed out as an
!!! opaque `@void` pointer. A chain node viewed through one link type is any of the
!!! structs that were passed into that `@void` slot, so a field of one of them
!!! counts as used when the view uses the same field - the index tables of this
!!! compiler are exactly that.
@RgStrSet rg_view_structs;
@RgStrSet rg_cast_out_structs;
!!! _access_reported: the member accesses already reported as private/protected, so
!!! later passes that resolve the same field again do not say it twice.
@RgStrSet rg_access_reported;
!!! _access_ctx: the type whose body is being walked where rg_struct_method_type is
!!! not the answer - the rewrite pass walks a struct's `init` / `destruct` bodies
!!! outside the method context, and a member of that same struct is still reachable
!!! from them. Empty means rg_struct_method_type is the one to use.
str rg_access_ctx;

@RgStrMap rg_rimp_deferred;    !!! _rimp_deferred: key -> formatted note, flushed at the end.
@RgExprRef rg_lambdas;         !!! _lambdas: collected lambda literals, in order.
@RgStrMap rg_capture_map;      !!! _capture_map: captured var -> hidden cap param name.
@RgBoolMap rg_capture_by_ref;  !!! _capture_by_ref: captured var -> by-reference (immediate).
str rg_cur_lambda_name;        !!! _cur_lambda_name: hidden function name being generated.
str rg_struct_method_var;      !!! struct_method_var: e.g. "Amy" when expanding Amy.birthday().
str rg_struct_method_type;     !!! struct_method_type: e.g. "Person".
!!! struct_method_idx: the index expression of an arr[i].method() expansion (null
!!! when the receiver is not an indexed element).
@ExprNode rg_struct_method_idx;
!!! _struct_scopes: one frame per open scope of the function currently being
!!! emitted. Each frame lists the struct locals declared in that scope as
!!! (variable name, struct type), in declaration order. When the scope closes they
!!! are destroyed in reverse order by inlining each type's `destruct` body.
@RgStructScope rg_struct_scopes;
!!! _method_arg_map: method param name -> call argument expression, valid during
!!! an inline expansion.
@RgExprMap rg_method_arg_map;
!!! _cur_func_name and _func_header: the function context for error headers.
str rg_cur_func_name;
VarType rg_cur_func_ret = VOID; !!! _cur_func_ret: the enclosing function's return type.
str rg_cur_func_ret_struct;     !!! _cur_func_ret_struct: the enclosing function returns a struct (pointer convention).
!!! _cur_func_ret_struct_ptr: the enclosing function returns `@T`: the value it
!!! returns already is the pointer, so no struct copy is made on the way out.
bool rg_cur_func_ret_struct_ptr = false;
int rg_func_line = 0;           !!! _func_line: the line the current function starts on.
str rg_func_header;             !!! _func_header: cached "In function" header.
!!! _cur_builtin_annotation and _cur_builtin_params: when generating a
!!! `function <built-in> F -> ...` body, a bare reference to `<built-in>` forwards
!!! F's own parameters, whose names are the chain.
str rg_cur_builtin_annotation;
@StrNode rg_cur_builtin_params;
!!! _method_locals: names declared as locals in the method body currently being
!!! emitted. A bare name inside a method is a field of `this` unless it is one of
!!! these, so a local (or a parameter) is not mistaken for a field.
@RgStrSet rg_method_locals;
!!! _param_sym_stack: stack of saved outer-scope symbol values for function
!!! params. A param may shadow an outer variable of the same name (a global
!!! declared in main); the old value is remembered here and restored when the
!!! function body is done, instead of erasing the outer variable.
@ParamSymFrame rg_param_sym_stack;
!!! _local_sym_stack: stack of saved outer-scope symbol values for the local
!!! variables of the body currently being generated. A name may be declared with
!!! different types in different bodies (`int r` in one function, a struct `r` in
!!! the next), so each body installs the types of its own declarations and
!!! restores the previous ones when it is done.
@LocalSymFrame rg_local_sym_stack;
!!! _instantiated_templates: source names of the function templates that were
!!! instantiated at least once. A template listed here already had its body
!!! resolved, so check_template_bodies() leaves it alone and its errors are
!!! reported once, with the function header.
@RgStrSet rg_instantiated_templates;
!!! _op_body_types: declared types of the body being rewritten (name -> struct
!!! type, "" = not a struct), so a local or parameter is never mistaken for a
!!! same-named struct variable of another function.
@RgStrMap rg_op_body_types;
@RgVarTypeMap rg_op_body_var_types;  !!! _op_body_var_types: the type of each such name.
@RgBoolMap rg_op_body_ptr;           !!! _op_body_ptr: whether a local of that body is a pointer (@T p).
@RgBoolMap rg_op_body_array;         !!! _op_body_array: whether a local of that body is an array (T a[N]).
!!! _op_in_method_body: set while a struct method body is rewritten: a bare name
!!! that is neither a parameter nor a local of that body is a field of the
!!! enclosing struct, so the file-wide tables must not be consulted.
bool rg_op_in_method_body = false;
str rg_op_method_type;               !!! _op_method_type: the struct of that method body.
!!! _const_scopes: names in scope, innermost scope last; a lookup walks them
!!! backwards, so a body that redeclares a name decides for itself.
@RgConstScope rg_const_scopes;
!!! _static_seq: the counter that keeps every hidden `static` slot name unique.
int rg_static_seq = 0;
!!! _static_const: the const entries of the hidden `static` globals, which are what
!!! the const-write pass reports a write to.
@RgConstMap rg_static_const;
!!! _struct_tmpl_done: concrete instantiations already built, keyed by their
!!! mangled struct name (`Box_int`), so each one is cloned and emitted once.
@RgStrSet rg_struct_tmpl_done;
@RgStrSet rg_struct_defs_resolved;   !!! _struct_defs_resolved: struct definitions whose type slots are already resolved.
!!! _overload_reported: call sites that already reported an overload problem,
!!! keyed by line:col:name, so repeated resolve passes report each one once.
@RgStrSet rg_overload_reported;
@RgPkgMap rg_pkg_members;      !!! _pkg_members: "pkg::name" -> its member.
@RgStrListMap rg_pkg_short;    !!! _pkg_short: name -> every "pkg::name" it may mean.
@RgStrSet rg_used_pkgs;        !!! _used_pkgs: packages named by `use pkg;`.
@RgStrSet rg_used_members;     !!! _used_members: members named by `use pkg::name;`.
@RgStrSet rg_pkg_reported;     !!! _pkg_reported: package diagnostics already written.

!!! the out-parameters of the methods
!!!
!!! Every parameter listed below is a non-const reference or a pointer the
!!! callee writes. It is not a parameter of this converted function: the caller stores
!!! the value it would have passed in the global, calls, and reads the global back.
!!! The comment names the method and the toolchain parameter, so the toolchain source still
!!! reads next to this implementation.

@ExprNode rg_wrap_unsigned_constant_out_e;      !!! wrap_unsigned_constant(VarType t, ExprNode*& e): the rewritten node.
@ExprNode rg_hoist_struct_call_out_child;       !!! hoist_struct_call(ExprNode*& child): the replacement node.
@ExprNode rg_hoist_array_element_address_out_child; !!! hoist_array_element_address(ExprNode*& child): the replacement node.
@ExprNode rg_wrap_ctor_out_slot;                !!! wrap_ctor(ExprNode*& slot, ...): the rewritten slot.
@ExprNode rg_wrap_conversion_out_slot;          !!! wrap_conversion(ExprNode*& slot, ...): the rewritten slot.
@ExprNode rg_rewrite_operator_expr_out_n;       !!! rewrite_operator_expr(ExprNode*& n): the rewritten node.
@ExprNode rg_rewrite_binary_operator_out_n;     !!! rewrite_binary_operator(ExprNode*& n): the rewritten node.
@ExprNode rg_rewrite_unary_operator_out_n;      !!! rewrite_unary_operator(ExprNode*& n): the rewritten node.
@ExprNode rg_rewrite_subscript_out_n;           !!! rewrite_subscript(ExprNode*& n): the rewritten node.
@ExprNode rg_rewrite_conversion_out_n;          !!! rewrite_conversion(ExprNode*& n): the rewritten node.
@ExprNode rg_normalize_call_args_out_args; !!! normalize_call_args(..., a chain of ExprNode*& args, ...): reordered arguments.
@StrNode rg_normalize_call_args_out_arg_names; !!! normalize_call_args(..., a chain of str& arg_names, ...).
@IntNode rg_normalize_call_args_out_name_lines; !!! normalize_call_args(..., a chain of int& name_lines, ...).
@IntNode rg_normalize_call_args_out_name_cols; !!! normalize_call_args(..., a chain of int& name_cols, ...).
@IntNode rg_normalize_call_args_out_name_lens; !!! normalize_call_args(..., a chain of int& name_lens, ...).
@VarDecl rg_effective_var_decl_out; !!! effective_var_decl(const str& name, VarDecl& out).
str rg_this_field_address_out; !!! this_field_address(const str& name, str& out).
str rg_member_chain_type_out; !!! member_chain_type(..., str& out).
@StructField rg_resolve_member_chain_out_leaf;  !!! resolve_member_chain(..., const StructField** leaf, ...).
int rg_resolve_member_chain_out_abs_off;        !!! resolve_member_chain(..., int* abs_off).
@StructField rg_resolve_field_chain_out_leaf;   !!! resolve_field_chain(..., const StructField** leaf, ...).
int rg_resolve_field_chain_out_abs_off;         !!! resolve_field_chain(..., int* abs_off).
str rg_pointer_element_address_out; !!! pointer_element_address(ExprNode* n, str& out).
str rg_pointer_field_elem_address_out; !!! pointer_field_elem_address(..., str& out, ...).
str rg_pointer_field_elem_address_out_struct; !!! pointer_field_elem_address(..., str& out_struct).
VarType rg_pointer_field_elem_address_out_elem; !!! ... its element type (VarType* out_elem).
str rg_member_chain_block_info_out_base; !!! member_chain_block_info(..., str& out_base, ...).
str rg_member_chain_block_info_out_struct; !!! member_chain_block_info(..., str& out_struct, ...).
int rg_member_chain_block_info_out_step;        !!! member_chain_block_info(..., int& step, ...).
VarType rg_member_chain_block_info_out_elem; !!! member_chain_block_info(..., VarType* out_elem). A null pointer in the toolchain is "not asked for"; this implementation fills it either way and the callers that do not care ignore it.
str rg_method_field_block_info_out_struct_type; !!! method_field_block_info(..., str& struct_type, ...).
int rg_method_field_block_info_out_step;        !!! method_field_block_info(..., int& step).
str rg_emit_pointer_chain_out; !!! emit_pointer_chain(..., str& out).
str rg_receiver_info_out_stype; !!! receiver_info(..., str& stype, ...).
str rg_receiver_info_out_decl_type; !!! receiver_info(..., str& decl_type, ...).
str rg_emit_field_chain_address_out; !!! emit_field_chain_address(..., str& out).
str rg_emit_receiver_address_out; !!! emit_receiver_address(..., str& out).
str rg_emit_struct_source_address_out; !!! emit_struct_source_address(..., str& out).
str rg_resolve_field_decl_out_decl_type; !!! resolve_field_decl(..., str* decl_type, ...).
str rg_resolve_field_out_decl_type; !!! resolve_field(..., str* decl_type, ...).
int rg_find_ctor_func_out_access;               !!! find_ctor_func(..., int* access): the access level of the constructor found.
int rg_find_ctor_limbs_out_access;              !!! find_ctor_limbs(..., int* access): the access level of the constructor found.
@StubMismatch rg_stub_proto_mismatch_out; !!! stub_proto_mismatch(const StubProto& p, const StmtNode* s): the difference found (the toolchain answers the record by value).
@RgFlatPair rg_collect_flat_fields_out; !!! collect_flat_fields(..., a chain<pair<const StructField*, str>>& out, ...).
@FlatField rg_collect_leaf_fields_out; !!! collect_leaf_fields(..., a chain of FlatField& out, ...).
@RgStrSet rg_collect_flat_fields_out_visited; !!! collect_flat_fields(..., name table<str>& visited).
@RgStrSet rg_collect_leaf_fields_out_visited; !!! collect_leaf_fields(..., name table<str>& visited).
@StrNode rg_collect_free_vars_expr_out; !!! collect_free_vars_expr(..., a chain of str& out, ...).
@RgStrSet rg_collect_free_vars_expr_out_seen; !!! collect_free_vars_expr(..., unordered_set<str>& seen).
@StrNode rg_collect_free_vars_stmts_out; !!! collect_free_vars_stmts(..., a chain of str& out, ...).
@RgStrSet rg_collect_free_vars_stmts_out_seen; !!! collect_free_vars_stmts(..., unordered_set<str>& seen).
@RgStrSet rg_collect_written_vars_stmts_out; !!! collect_written_vars_stmts(..., unordered_set<str>& out).
@StrNode rg_collect_declare_names_out; !!! collect_declare_names(const a chain of StmtNode*& body, a chain of str& out).
@StrNode rg_collect_struct_def_names_out; !!! collect_struct_def_names(..., a chain of str& out).
@StructField rg_resolve_array_base_out_field;   !!! resolve_array_base(..., const StructField** field, ...).
str rg_resolve_array_base_out_addr; !!! resolve_array_base(..., str& addr, ...).
str rg_emit_field_elem_address_out; !!! emit_field_elem_address(..., str& out, ...).
@StructField rg_emit_field_elem_address_out_field; !!! emit_field_elem_address(..., const StructField** field).
str rg_emit_this_field_elem_list_out; !!! emit_this_field_elem(name, const a chain of ExprNode*& idx, str& out, ...).
@StructField rg_emit_this_field_elem_list_out_field;
str rg_emit_this_field_elem_node_out; !!! emit_this_field_elem(const ExprNode* n, str& out, ...).
@StructField rg_emit_this_field_elem_node_out_field;
str rg_emit_lvalue_address_out; !!! emit_lvalue_address(..., str& out).
str rg_index_field_layout_out_receiver_type; !!! index_field_layout(..., str& receiver_type, ...).
str rg_index_field_layout_out_elem; !!! index_field_layout(..., str& elem, ...).
@StrNode rg_index_field_layout_out_prefix; !!! index_field_layout(..., a chain of str& prefix, ...).
int rg_index_field_layout_out_off;              !!! index_field_layout(..., int& off, ...).
@StructField rg_index_field_layout_out_leaf;    !!! index_field_layout(..., const StructField** leaf).
@StrNode rg_index_store_receiver_type_out_prefix; !!! index_store_receiver_type(StmtNode* s, a chain of str& prefix).
@IndexStorePlan rg_plan_index_store_out_plan;   !!! plan_index_store(StmtNode* s, IndexStorePlan& plan).
int rg_find_ctor_limbs_out_count; !!! find_ctor_limbs(const str& type, int& nlimbs).
longlong rg_int_literal_value_out_value; !!! int_literal_value(const ExprNode* n, longlong& value).
VarType rg_op_value_type_out;                   !!! op_value_type(const ExprNode* n, VarType& out).
@VarTypeNode rg_callee_param_types_out; !!! callee_param_types(..., a chain of VarType& out, ...).
@BoolNode rg_callee_param_types_out_variadic;   !!! callee_param_types(..., bool& variadic, ...).
@StrNode rg_callee_param_types_out_structs; !!! callee_param_types(..., a chain of str* out_structs). A null pointer is "not asked for"; this implementation fills the chain either way.
str rg_pick_from_versions_out; !!! pick_from_versions(..., str& out).
str rg_pick_method_overload_out; !!! pick_method_overload(..., str& out).
str rg_pick_overload_out; !!! pick_overload(..., str& out).
str rg_resolve_global_ref_out_name; !!! resolve_global_ref(str& name, ...): the rewritten name.
str rg_package_resolve_out_name; !!! package_resolve(str& name, ...): the rewritten name.
@RgStrMap rg_collect_package_member_out_lmap; !!! collect_package_member(..., name table<str, str>& local): the package's own members, which this implementation calls `lmap` because `local` is a keyword.
str rg_resolve_struct_type_slot_out_name; !!! resolve_struct_type_slot(str& name, ...).
VarType rg_resolve_struct_type_slot_out_vt;     !!! resolve_struct_type_slot(..., VarType& vt, ...).
@StmtNode rg_materialize_static_in_func_out_new_globals; !!! materialize_static_in_func(..., a chain of StmtNode*& new_globals).
@StmtNode rg_resolve_struct_definition_out_defs; !!! resolve_struct_definition(const str& name, a chain of StmtNode*& defs).
@StmtNode rg_resolve_struct_spelling_out_defs; !!! resolve_struct_spelling(..., a chain of StmtNode*& defs, ...).
@StmtNode rg_resolve_struct_types_stmt_out_defs; !!! resolve_struct_types_stmt(..., a chain of StmtNode*& defs, ...).
@StmtNode rg_materialize_struct_template_out_defs; !!! materialize_struct_template(..., a chain of StmtNode*& defs).
@RgStrSet rg_instantiate_template_call_out_done; !!! instantiate_template_call(..., unordered_set<str>& done, ...).
@StmtNode rg_instantiate_template_call_out_new_stmts; !!! instantiate_template_call(..., a chain of StmtNode*& new_stmts, ...).
@RgStrSet rg_materialize_template_out_done; !!! materialize_template(..., unordered_set<str>& done, ...).
@StmtNode rg_materialize_template_out_new_stmts; !!! materialize_template(..., a chain of StmtNode*& new_stmts).
@RgStrSet rg_instantiate_template_explicit_out_done; !!! instantiate_template_explicit(..., unordered_set<str>& done, ...).
@StmtNode rg_instantiate_template_explicit_out_new_stmts; !!! instantiate_template_explicit(..., a chain of StmtNode*& new_stmts).
@RgStrSet rg_instantiate_expr_out_done; !!! instantiate_expr(..., unordered_set<str>& done, ...).
@StmtNode rg_instantiate_expr_out_new_stmts; !!! instantiate_expr(..., a chain of StmtNode*& new_stmts).
@RgStrSet rg_instantiate_stmt_out_done; !!! instantiate_stmt(..., unordered_set<str>& done, ...).
@StmtNode rg_instantiate_stmt_out_new_stmts; !!! instantiate_stmt(..., a chain of StmtNode*& new_stmts).

!!! the chain helpers

!!! How many nodes the map and set lookups walked, and how many lookups there
!!! were. BLANG_TIME prints them: a table whose chains are long is the reason the
!!! emitter spends its time comparing names.
longlong g_n_chain_nodes;
int g_n_set_has;
int g_n_strmap_find;
int g_n_boolmap_find;
int g_n_vartypemap_find;

!!! The bucket index the four hottest tables share: the records are in
!!! rgen_heads.b and the bodies are in the block below. It is declared here
!!! because the set helpers come first and a call is only answered for a function
!!! this implementation has already read.
stub @RgVoidBucket rg_idx_bucket -> @RgIdx idx, int h;
stub @RgIdx rg_idx_new;
stub @RgIdx rg_idx_of -> @void head;
stub @void rg_idx_hit -> @RgIdx idx, int h, str key;
stub void rg_idx_append -> @RgIdx idx, @void n, int h;
stub @void rg_idx_drop -> @RgIdx idx, @void head, int h, str key;

!!! The names already seen under `#once`-style use: whether the key is there
!!! (`extern_funcs.count(name)`, `_global_names.count(name)`, ...). This is the
!!! hottest lookup in the whole generator - every name of every expression is asked
!!! about here - so it compares the hash each node carries before the text.
bool rg_set_has -> @RgStrSet head, str key {
    !!! One hash, not two: the second call walked the key again for an answer the
    !!! first one already had.
    g_n_set_has = g_n_set_has + 1;
    int h = rgx_lk_hash(key);
    @RgIdx idx = rg_idx_of((@void)head);
    if idx == null {
        return false;
    }
    return rg_idx_hit(idx, h, key) != null;
}

!!! Add a key to such a set, at the tail so insertion order is kept. the toolchain
!!! `insert(key).second` reads as `if !rg_set_has(head, key) { head =
!!! rg_set_add(head, key); ... }` (`_arity_reported.insert(key).second`).
@RgStrSet rg_set_add -> @RgStrSet head, str key {
    int h = rgx_lk_hash(key);
    @RgIdx idx = rg_idx_of((@void)head);
    if idx != null && rg_idx_hit(idx, h, key) != null {
        return head;
    }
    RgStrSet proto;
    @RgStrSet n;
    malloc(@n, size proto);
    n.key = key;
    n.hash = h;
    n.next = null;
    n.hnext = null;
    n.idx = null;
    if idx == null {
        return n;
    }
    rg_idx_append(idx, (@void)n, h);
    return head;
}

!!! Remove a key from a set: the `_non_global_syms.erase(p)` (rgen_lambda)
!!! and `visiting.erase(t)` (rgen_inheritance). A set of names has this helper
!!! beside rg_set_has/rg_set_add, so no module has to grow one of its own.
@RgStrSet rg_set_drop -> @RgStrSet head, str key {
    @RgIdx idx = rg_idx_of((@void)head);
    if idx == null {
        return head;
    }
    return (@RgStrSet)rg_idx_drop(idx, (@void)head, rgx_lk_hash(key), key);
}

!!! ---- the hash index a table's lookups walk ----
!!!
!!! The chain is what every reader walks and the insertion order is what the output
!!! is written in, so the chain stays as it is. What a lookup gets is an index
!!! beside it: the buckets a hash falls into, each holding the nodes of that table
!!! that hash there. A lookup walks its bucket instead of the chain - on the
!!! compiler's own source the tables were walked a hundred and ninety million nodes,
!!! and a bucket is about a hundredth of that.
!!!
!!! The bucket of a hash is reached through the block a `vector` holds and not
!!! through its `get`/`put`: a method call per lookup was what made an earlier try
!!! at this cost more than the walk it saved. `@data[i]` is the address of the
!!! bucket record, which is the same expression the vector's own `at` answers.

!!! How many buckets a table has. A power of two, so it is the low bits of a hash.
int rg_idx_buckets = 256;

!!! ---- the int tables ----
!!!
!!! func_arity, func_params_hl, func_decl_line and sym_depth have the same shape as
!!! the name tables and share their index: every node carries `key, hash, next,
!!! hnext, idx` first, and one set of helpers serves them all.

!!! func_arity.find(name) and func_arity.count(name).
@RgIntMap rg_intmap_find -> @RgIntMap head, str key {
    if head == null {
        return null;
    }
    int h = rgx_lk_hash(key);
    @RgIdx idx = rg_idx_of((@void)head);
    if idx == null {
        return null;
    }
    return (@RgIntMap)rg_idx_hit(idx, h, key);
}

!!! func_arity[name] = arity (also func_params_hl, func_decl_line, sym_depth).
@RgIntMap rg_intmap_set -> @RgIntMap head, str key, int v {
    int h = rgx_lk_hash(key);
    @RgIdx idx = rg_idx_of((@void)head);
    if idx != null {
        @RgIntMap hit = (@RgIntMap)rg_idx_hit(idx, h, key);
        if hit != null {
            hit.v = v;
            return head;
        }
    }
    RgIntMap proto;
    @RgIntMap n;
    malloc(@n, size proto);
    n.key = key;
    n.hash = h;
    n.v = v;
    n.next = null;
    n.hnext = null;
    n.idx = null;
    if idx == null {
        !!! The table was empty: the new node heads it, and the index over the chain
        !!! it now starts is made by the first lookup that asks for one.
        return n;
    }
    rg_idx_append(idx, (@void)n, h);
    return head;
}

!!! sym_depth.erase(nm) and the other int tables a scope takes a name out of.
@RgIntMap rg_intmap_drop -> @RgIntMap head, str key {
    if head == null {
        return null;
    }
    @RgIdx idx = rg_idx_of((@void)head);
    if idx == null {
        return head;
    }
    return (@RgIntMap)rg_idx_drop(idx, (@void)head, rgx_lk_hash(key), key);
}

!!! display_names.find(name), display_names.count(name), display_names[name] = v.
!!! ---- a bucket index for a name table ----
!!!
!!! The records and the reason for the index are in rgen_heads.b. What stands here
!!! is the index itself: it reads the node fields through `@RgIdxLink`, the record
!!! of the fields every indexed table puts first (see RgIdxLink), so one set of
!!! helpers serves the string tables, the variable type tables, the bool tables and
!!! the name sets, and a caller reaches the node it really wanted by casting the
!!! answer back.

!!! The bucket `h` falls into, as the record that holds its head.
@RgVoidBucket rg_idx_bucket -> @RgIdx idx, int h {
    vector(RgVoidBucket) bk = idx.bk;
    @RgVoidBucket data = bk.data;
    return @data[h & (rg_idx_buckets - 1)];
}

!!! A fresh index, with no node in it and no chain end known yet.
@RgIdx rg_idx_new {
    RgIdx proto;
    @RgIdx one;
    malloc(@one, size proto);
    !!! The buckets are one zeroed block and not 256 appends: an append is a call and
    !!! the vector grows by doubling on the way to 256, and a table asks for its index
    !!! the first time it is looked up - for the operator bodies and the lambdas of
    !!! the compiler's own source that happens tens of thousands of times. `malloc`
    !!! answers zeroed memory, so every bucket starts empty.
    RgVoidBucket bproto;
    @void cell;
    malloc(@cell, (int)size bproto * rg_idx_buckets);
    vector(RgVoidBucket) bk;
    bk.data = (@RgVoidBucket)cell;
    bk.len = rg_idx_buckets;
    bk.cap = rg_idx_buckets;
    one.bk = bk;
    one.tail = null;
    return one;
}

!!! The index of the table `head` leads, made (and filled from the chain) when it
!!! is not there yet. Every node carries it and not only the head: a chain handed
!!! on from a node in the middle of another one - a drop answers the rest of the
!!! chain - would otherwise be indexed a second time, and a second pass over nodes
!!! that are already on a bucket chain rewrites their links under the index that
!!! owns them, which leaves that index walking in a circle.
@RgIdx rg_idx_of -> @void head {
    if head == null {
        return null;
    }
    @RgIdxLink h = (@RgIdxLink)head;
    if h.idx != null {
        return h.idx;
    }
    !!! A table that was filled before the index was asked about has to be in it
    !!! too: every node of the chain goes onto its bucket, and the walk remembers
    !!! the last node, which is what lets an append be one step instead of a walk.
    @RgIdx idx = rg_idx_new();
    @RgIdxLink s = h;
    @void last = null;
    while s != null {
        @RgVoidBucket rec = rg_idx_bucket(idx, s.hash);
        s.hnext = rec.head;
        rec.head = (@void)s;
        s.idx = idx;
        s.prev = last;
        last = (@void)s;
        s = (@RgIdxLink)s.next;
    }
    idx.tail = last;
    return idx;
}

!!! The node of the table `idx` serves whose key is `key`, null when there is none.
@void rg_idx_hit -> @RgIdx idx, int h, str key {
    @RgVoidBucket rec = rg_idx_bucket(idx, h);
    @RgIdxLink e = (@RgIdxLink)rec.head;
    while e != null {
        g_n_chain_nodes = g_n_chain_nodes + 1;
        if e.hash == h && p_text_eq(e.key, key) {
            return (@void)e;
        }
        e = (@RgIdxLink)e.hnext;
    }
    return null;
}

!!! `n`, which is not in the table yet, onto the end of the chain `idx` serves and
!!! onto its bucket. The head of the chain is the caller's, so nothing is answered.
void rg_idx_append -> @RgIdx idx, @void n, int h {
    @RgIdxLink nn = (@RgIdxLink)n;
    @RgIdxLink last = (@RgIdxLink)idx.tail;
    last.next = n;
    idx.tail = n;
    nn.idx = idx;
    nn.prev = (@void)last;
    @RgVoidBucket rec = rg_idx_bucket(idx, h);
    nn.hnext = rec.head;
    rec.head = n;
}

!!! Take the node whose key is `key` out of the chain `idx` serves and out of its
!!! bucket, and answer the head of the chain. A node left on a bucket chain would
!!! still be found after the table stopped holding it, so it leaves both. The node
!!! that heads the chain after this carries the index like every other node of it
!!! (see rg_idx_of), so the next lookup is a field read again.
@void rg_idx_drop -> @RgIdx idx, @void head, int h, str key {
    !!! A name the table does not hold is the common case: every local of every body
    !!! is taken out of the tables it was never put in. The bucket answers that in one
    !!! step, while reading the whole chain would find nothing.
    @RgIdxLink e = (@RgIdxLink)rg_idx_hit(idx, h, key);
    if e == null {
        return head;
    }
    !!! The node the bucket answered, and not a walk to it: the table the whole
    !!! program shares has a chain of thousands of names, and walking it again for
    !!! every removal read every key on the way. The node remembers the name before
    !!! it (RgIdxLink), so taking it out of the chain is a link.
    @RgIdxLink prev = (@RgIdxLink)e.prev;
    @void nh = (@void)head;
    if prev == null {
        !!! What the caller gets back: the rest of the chain when the node that
        !!! headed it is the one taken out, and the same head when any other node
        !!! is. Answering the successor of the node either way threw the whole
        !!! table away on every removal that was not its first node.
        nh = e.next;
        @RgIdxLink nhn = (@RgIdxLink)nh;
        if nhn != null {
            nhn.prev = null;
        }
    } else {
        prev.next = e.next;
        @RgIdxLink en = (@RgIdxLink)e.next;
        if en != null {
            en.prev = (@void)prev;
        }
    }
    !!! The end of the chain follows the chain. A node taken out of the end of a
    !!! table whose end was remembered would leave the next name linked after a
    !!! node no reader reaches - that name then stands in the old index only,
    !!! and the table answers nothing once its head changes and a fresh index is
    !!! built over the chain without it.
    @RgIdxLink t = (@RgIdxLink)idx.tail;
    if t != null && t.hash == h && p_text_eq(t.key, key) {
        idx.tail = (@void)prev;
    }
    @RgVoidBucket rec = rg_idx_bucket(idx, h);
    !!! ... and out of its bucket, so a name that was taken out of the table
    !!! is not answered by the index afterwards. Two pointers cannot be
    !!! compared in this language, so the node is found by the key it was
    !!! found by on the chain: a bucket holds the nodes of one table only,
    !!! and a table holds a key once.
    @RgIdxLink p = (@RgIdxLink)rec.head;
    @RgIdxLink bprev = null;
    bool vdone = false;
    while p != null && !vdone {
        if p.hash == h && p_text_eq(p.key, key) {
            if bprev == null {
                rec.head = p.hnext;
            } else {
                bprev.hnext = p.hnext;
            }
            vdone = true;
        } else {
            bprev = p;
            p = (@RgIdxLink)p.hnext;
        }
    }
    return nh;
}

!!! display_names.find(name) and display_names.count(name).
@RgStrMap rg_strmap_find -> @RgStrMap head, str key {
    g_n_strmap_find = g_n_strmap_find + 1;
    int h = rgx_lk_hash(key);
    @RgIdx idx = rg_idx_of((@void)head);
    if idx == null {
        return null;
    }
    return (@RgStrMap)rg_idx_hit(idx, h, key);
}

!!! display_names[name] = value (also sym_struct_type, func_decl_file,
!!! func_ret_struct, _rimp_deferred, _capture_map, _op_body_types).
@RgStrMap rg_strmap_set -> @RgStrMap head, str key, str v {
    !!! One hash, not two: the second call walked the key again for an answer the
    !!! first one already had.
    int h = rgx_lk_hash(key);
    !!! The bucket, not the chain: a set that walked every node cost as much as a
    !!! lookup, and the table the whole program shares has a long chain.
    @RgIdx idx = rg_idx_of((@void)head);
    if idx != null {
        @RgStrMap hit = (@RgStrMap)rg_idx_hit(idx, h, key);
        if hit != null {
            hit.v = v;
            return head;
        }
    }
    RgStrMap proto;
    @RgStrMap n;
    malloc(@n, size proto);
    n.key = key;
    n.hash = h;
    n.v = v;
    n.next = null;
    n.hnext = null;
    n.idx = null;
    if idx == null {
        !!! The table was empty: the new node heads it, and the index over the chain
        !!! it now starts is made by the first lookup that asks for one.
        return n;
    }
    !!! Onto the end of the chain and onto its bucket: a lookup after this one sees
    !!! it, and every pass that walks the table still sees it in insertion order.
    rg_idx_append(idx, (@void)n, h);
    return head;
}

!!! sym_struct_type.erase(nm) (also the other string tables a scope clears).
@RgStrMap rg_strmap_drop -> @RgStrMap head, str key {
    @RgIdx idx = rg_idx_of((@void)head);
    if idx == null {
        return head;
    }
    return (@RgStrMap)rg_idx_drop(idx, (@void)head, rgx_lk_hash(key), key);
}

!!! sym_is_array.count(name) and the other bool tables.
@RgBoolMap rg_boolmap_find -> @RgBoolMap head, str key {
    !!! One hash, not two (see rg_set_has).
    g_n_boolmap_find = g_n_boolmap_find + 1;
    int h = rgx_lk_hash(key);
    @RgIdx idx = rg_idx_of((@void)head);
    if idx == null {
        return null;
    }
    return (@RgBoolMap)rg_idx_hit(idx, h, key);
}

!!! sym_is_array[name] = true (also sym_is_ref, sym_is_unsigned, sym_struct_ptr,
!!! func_ret_is_unsigned, func_variadic, _capture_by_ref, _op_body_ptr,
!!! _op_body_array).
@RgBoolMap rg_boolmap_set -> @RgBoolMap head, str key, bool v {
    int h = rgx_lk_hash(key);
    @RgIdx idx = rg_idx_of((@void)head);
    if idx != null {
        @RgBoolMap hit = (@RgBoolMap)rg_idx_hit(idx, h, key);
        if hit != null {
            hit.v = v;
            return head;
        }
    }
    RgBoolMap proto;
    @RgBoolMap n;
    malloc(@n, size proto);
    n.key = key;
    n.hash = h;
    n.v = v;
    n.next = null;
    n.hnext = null;
    n.idx = null;
    if idx == null {
        return n;
    }
    rg_idx_append(idx, (@void)n, h);
    return head;
}

!!! sym_is_ref.erase(nm) and the other bool tables a scope takes a name out of.
@RgBoolMap rg_boolmap_drop -> @RgBoolMap head, str key {
    @RgIdx idx = rg_idx_of((@void)head);
    if idx == null {
        return head;
    }
    return (@RgBoolMap)rg_idx_drop(idx, (@void)head, rgx_lk_hash(key), key);
}

!!! declared_vars.find(name) and the other (line,col) tables.
@RgPosMap rg_posmap_find -> @RgPosMap head, str key {
    int h = rgx_lk_hash(key);
    @RgIdx idx = rg_idx_of((@void)head);
    if idx == null {
        return null;
    }
    return (@RgPosMap)rg_idx_hit(idx, h, key);
}

!!! declared_vars[name] = (line,col) (also declared_funcs, func_params_pos,
!!! func_decl_pos).
@RgPosMap rg_posmap_set -> @RgPosMap head, str key, int a, int b {
    int h = rgx_lk_hash(key);
    @RgIdx idx = rg_idx_of((@void)head);
    if idx != null {
        @RgPosMap hit = (@RgPosMap)rg_idx_hit(idx, h, key);
        if hit != null {
            hit.a = a;
            hit.b = b;
            return head;
        }
    }
    RgPosMap proto;
    @RgPosMap n;
    malloc(@n, size proto);
    n.key = key;
    n.hash = h;
    n.a = a;
    n.b = b;
    n.next = null;
    n.hnext = null;
    n.idx = null;
    if idx == null {
        return n;
    }
    rg_idx_append(idx, (@void)n, h);
    return head;
}

!!! syms.find(name), syms.count(name) and the other type tables.
@RgVarTypeMap rg_vartypemap_find -> @RgVarTypeMap head, str key {
    g_n_vartypemap_find = g_n_vartypemap_find + 1;
    int h = rgx_lk_hash(key);
    @RgIdx idx = rg_idx_of((@void)head);
    if idx == null {
        return null;
    }
    return (@RgVarTypeMap)rg_idx_hit(idx, h, key);
}

!!! syms[name] = type (also sym_call_ret, extern_ret_types, _op_body_var_types).
@RgVarTypeMap rg_vartypemap_set -> @RgVarTypeMap head, str key, VarType ty {
    int h = rgx_lk_hash(key);
    @RgIdx idx = rg_idx_of((@void)head);
    if idx != null {
        @RgVarTypeMap hit = (@RgVarTypeMap)rg_idx_hit(idx, h, key);
        if hit != null {
            hit.ty = ty;
            return head;
        }
    }
    RgVarTypeMap proto;
    @RgVarTypeMap n;
    malloc(@n, size proto);
    n.key = key;
    n.hash = h;
    n.ty = ty;
    n.next = null;
    n.hnext = null;
    n.idx = null;
    if idx == null {
        return n;
    }
    rg_idx_append(idx, (@void)n, h);
    return head;
}

!!! syms.erase(nm): taking a name out of the symbol table again.
@RgVarTypeMap rg_vartypemap_drop -> @RgVarTypeMap head, str key {
    @RgIdx idx = rg_idx_of((@void)head);
    if idx == null {
        return head;
    }
    return (@RgVarTypeMap)rg_idx_drop(idx, (@void)head, rgx_lk_hash(key), key);
}

!!! sym_dims.find(name) and sym_dims.count(name).
@RgDimsMap rg_dimmap_find -> @RgDimsMap head, str key {
    int h = rgx_lk_hash(key);
    @RgIdx idx = rg_idx_of((@void)head);
    if idx == null {
        return null;
    }
    return (@RgDimsMap)rg_idx_hit(idx, h, key);
}

!!! sym_dims[name] = dims.
@RgDimsMap rg_dimmap_set -> @RgDimsMap head, str key, @RgLongNode dims, int n {
    int h = rgx_lk_hash(key);
    @RgIdx idx = rg_idx_of((@void)head);
    if idx != null {
        @RgDimsMap hit = (@RgDimsMap)rg_idx_hit(idx, h, key);
        if hit != null {
            hit.dims = dims;
            hit.n = n;
            return head;
        }
    }
    RgDimsMap proto;
    @RgDimsMap m;
    malloc(@m, size proto);
    m.key = key;
    m.hash = h;
    m.dims = dims;
    m.n = n;
    m.next = null;
    m.hnext = null;
    m.idx = null;
    if idx == null {
        return m;
    }
    rg_idx_append(idx, (@void)m, h);
    return head;
}

!!! sym_dims.erase(nm).
@RgDimsMap rg_dimmap_drop -> @RgDimsMap head, str key {
    @RgIdx idx = rg_idx_of((@void)head);
    if idx == null {
        return head;
    }
    return (@RgDimsMap)rg_idx_drop(idx, (@void)head, rgx_lk_hash(key), key);
}

!!! _local_decls.find(name) and _local_decls.count(name).
@RgVarDeclMap rg_vardeclmap_find -> @RgVarDeclMap head, str key {
    int h = rgx_lk_hash(key);
    @RgIdx idx = rg_idx_of((@void)head);
    if idx == null {
        return null;
    }
    return (@RgVarDeclMap)rg_idx_hit(idx, h, key);
}

!!! _local_decls[name] = decl.
@RgVarDeclMap rg_vardeclmap_set -> @RgVarDeclMap head, str key, @VarDecl decl {
    int h = rgx_lk_hash(key);
    @RgIdx idx = rg_idx_of((@void)head);
    if idx != null {
        @RgVarDeclMap hit = (@RgVarDeclMap)rg_idx_hit(idx, h, key);
        if hit != null {
            hit.decl = decl;
            return head;
        }
    }
    RgVarDeclMap proto;
    @RgVarDeclMap m;
    malloc(@m, size proto);
    m.key = key;
    m.hash = h;
    m.decl = decl;
    m.next = null;
    m.hnext = null;
    m.idx = null;
    if idx == null {
        return m;
    }
    rg_idx_append(idx, (@void)m, h);
    return head;
}

!!! func_param_types.find(name): the parameter types of a function.
@RgVarTypeListMap rg_vartypelistmap_find -> @RgVarTypeListMap head, str key {
    int h = rgx_lk_hash(key);
    @RgIdx idx = rg_idx_of((@void)head);
    if idx == null {
        return null;
    }
    return (@RgVarTypeListMap)rg_idx_hit(idx, h, key);
}

!!! func_param_types[name] = s->fparam_types (the toolchain copies the vector; the
!!! chain it copies is the one the statement carries).
@RgVarTypeListMap rg_vartypelistmap_set -> @RgVarTypeListMap head, str key,
                                           @VarTypeNode types, int n {
    int h = rgx_lk_hash(key);
    @RgIdx idx = rg_idx_of((@void)head);
    if idx != null {
        @RgVarTypeListMap hit = (@RgVarTypeListMap)rg_idx_hit(idx, h, key);
        if hit != null {
            hit.types = types;
            hit.n = n;
            return head;
        }
    }
    RgVarTypeListMap proto;
    @RgVarTypeListMap m;
    malloc(@m, size proto);
    m.key = key;
    m.hash = h;
    m.types = types;
    m.n = n;
    m.next = null;
    m.hnext = null;
    m.idx = null;
    if idx == null {
        return m;
    }
    rg_idx_append(idx, (@void)m, h);
    return head;
}

!!! func_param_is_array.find(name) and the other bool-list tables.
@RgBoolListMap rg_boollistmap_find -> @RgBoolListMap head, str key {
    int h = rgx_lk_hash(key);
    @RgIdx idx = rg_idx_of((@void)head);
    if idx == null {
        return null;
    }
    return (@RgBoolListMap)rg_idx_hit(idx, h, key);
}

!!! func_param_is_array[name] = s->fparam_is_array (also
!!! func_param_is_ref, func_param_is_unsigned).
@RgBoolListMap rg_boollistmap_set -> @RgBoolListMap head, str key,
                                      @BoolNode flags, int n {
    int h = rgx_lk_hash(key);
    @RgIdx idx = rg_idx_of((@void)head);
    if idx != null {
        @RgBoolListMap hit = (@RgBoolListMap)rg_idx_hit(idx, h, key);
        if hit != null {
            hit.flags = flags;
            hit.n = n;
            return head;
        }
    }
    RgBoolListMap proto;
    @RgBoolListMap m;
    malloc(@m, size proto);
    m.key = key;
    m.hash = h;
    m.flags = flags;
    m.n = n;
    m.next = null;
    m.hnext = null;
    m.idx = null;
    if idx == null {
        return m;
    }
    rg_idx_append(idx, (@void)m, h);
    return head;
}

!!! func_param_struct.find(name) and the other string-list tables.
@RgStrListMap rg_strlistmap_find -> @RgStrListMap head, str key {
    int h = rgx_lk_hash(key);
    @RgIdx idx = rg_idx_of((@void)head);
    if idx == null {
        return null;
    }
    return (@RgStrListMap)rg_idx_hit(idx, h, key);
}

!!! func_param_struct[name] = s->fparam_struct (also func_param_names; _pkg_short
!!! appends to its chain instead, see rg_strchain_append).
@RgStrListMap rg_strlistmap_set -> @RgStrListMap head, str key,
                                    @StrNode names, int n {
    int h = rgx_lk_hash(key);
    @RgIdx idx = rg_idx_of((@void)head);
    if idx != null {
        @RgStrListMap hit = (@RgStrListMap)rg_idx_hit(idx, h, key);
        if hit != null {
            hit.names = names;
            hit.n = n;
            return head;
        }
    }
    RgStrListMap proto;
    @RgStrListMap m;
    malloc(@m, size proto);
    m.key = key;
    m.hash = h;
    m.names = names;
    m.n = n;
    m.next = null;
    m.hnext = null;
    m.idx = null;
    if idx == null {
        return m;
    }
    rg_idx_append(idx, (@void)m, h);
    return head;
}

!!! func_param_defaults.find(name).
@RgExprListMap rg_exprlistmap_find -> @RgExprListMap head, str key {
    @RgExprListMap e = head;
    int hx = rgx_lk_hash(key);
    while e != null {
        if e.hash == hx && p_text_eq(e.key, key) {
            return e;
        }
        e = e.next;
    }
    return null;
}

!!! func_param_defaults[name] = s->fparam_defaults.
@RgExprListMap rg_exprlistmap_set -> @RgExprListMap head, str key,
                                      @RgExprRef exprs {
    @RgExprListMap last = null;
    @RgExprListMap e = head;
    int hx = rgx_lk_hash(key);
    while e != null {
        if e.hash == hx && p_text_eq(e.key, key) {
            e.exprs = exprs;
            return head;
        }
        last = e;
        e = e.next;
    }
    RgExprListMap proto;
    @RgExprListMap m;
    malloc(@m, size proto);
    m.key = key;
    m.hash = rgx_lk_hash(key);
    m.exprs = exprs;
    m.next = null;
    if last == null {
        return m;
    }
    last.next = m;
    return head;
}

!!! func_overloads.find(name) (also method_overloads.find(type_and_name)).
@RgOverloadMap rg_overloadmap_find -> @RgOverloadMap head, str key {
    @RgOverloadMap e = head;
    int hx = rgx_lk_hash(key);
    while e != null {
        if e.hash == hx && p_text_eq(e.key, key) {
            return e;
        }
        e = e.next;
    }
    return null;
}

!!! func_overloads[name] = versions, and the set that puts a first version in
!!! (`func_overloads[n].push_back(ov)` reads as `e.versions =
!!! rg_overloadver_append(e.versions, ov)` after this).
@RgOverloadMap rg_overloadmap_set -> @RgOverloadMap head, str key,
                                      @OverloadVersion versions, int n {
    @RgOverloadMap last = null;
    @RgOverloadMap e = head;
    int hx = rgx_lk_hash(key);
    while e != null {
        if e.hash == hx && p_text_eq(e.key, key) {
            e.versions = versions;
            e.n = n;
            return head;
        }
        last = e;
        e = e.next;
    }
    RgOverloadMap proto;
    @RgOverloadMap m;
    malloc(@m, size proto);
    m.key = key;
    m.hash = rgx_lk_hash(key);
    m.versions = versions;
    m.n = n;
    m.next = null;
    if last == null {
        return m;
    }
    last.next = m;
    return head;
}

!!! _stub_protos.find(name) and _stub_protos.count(name).
@RgStubMap rg_stubmap_find -> @RgStubMap head, str key {
    @RgStubMap e = head;
    int hx = rgx_lk_hash(key);
    while e != null {
        if e.hash == hx && p_text_eq(e.key, key) {
            return e;
        }
        e = e.next;
    }
    return null;
}

!!! _stub_protos[orig_name] = sp.
@RgStubMap rg_stubmap_set -> @RgStubMap head, str key, @StubProto proto {
    @RgStubMap last = null;
    @RgStubMap e = head;
    int hx = rgx_lk_hash(key);
    while e != null {
        if e.hash == hx && p_text_eq(e.key, key) {
            e.proto = proto;
            return head;
        }
        last = e;
        e = e.next;
    }
    RgStubMap proto_rec;
    @RgStubMap m;
    malloc(@m, size proto_rec);
    m.key = key;
    m.hash = rgx_lk_hash(key);
    m.proto = proto;
    m.next = null;
    if last == null {
        return m;
    }
    last.next = m;
    return head;
}

!!! _stub_protos.erase(spit): a definition that turned out to be the
!!! implementation of the prototype takes the prototype out again.
@RgStubMap rg_stubmap_drop -> @RgStubMap head, str key {
    @RgStubMap prev = null;
    @RgStubMap e = head;
    int hx = rgx_lk_hash(key);
    while e != null {
        if e.hash == hx && p_text_eq(e.key, key) {
            if prev == null {
                return e.next;
            }
            prev.next = e.next;
            return head;
        }
        prev = e;
        e = e.next;
    }
    return head;
}

!!! _method_arg_map.find(name) and _method_arg_map[name] = expr.
@RgExprMap rg_exprmap_find -> @RgExprMap head, str key {
    @RgExprMap e = head;
    int hx = rgx_lk_hash(key);
    while e != null {
        if e.hash == hx && p_text_eq(e.key, key) {
            return e;
        }
        e = e.next;
    }
    return null;
}

!!! _static_const.find(name) and one scope of _const_scopes: the const entry of a
!!! name (`ci.is_const`, and where it was declared).
@RgConstMap rg_constmap_find -> @RgConstMap head, str key {
    @RgConstMap e = head;
    int hx = rgx_lk_hash(key);
    while e != null {
        if e.hash == hx && p_text_eq(e.key, key) {
            return e;
        }
        e = e.next;
    }
    return null;
}

!!! _const_scopes.back()[s->var_name] = ci (and every entry of _static_const).
@RgConstMap rg_constmap_set -> @RgConstMap head, str key, @ConstInfo info {
    @RgConstMap last = null;
    @RgConstMap e = head;
    int hx = rgx_lk_hash(key);
    while e != null {
        if e.hash == hx && p_text_eq(e.key, key) {
            e.info = info;
            return head;
        }
        last = e;
        e = e.next;
    }
    RgConstMap proto;
    @RgConstMap m;
    malloc(@m, size proto);
    m.key = key;
    m.hash = rgx_lk_hash(key);
    m.info = info;
    m.next = null;
    if last == null {
        return m;
    }
    last.next = m;
    return head;
}

!!! _pkg_members.find("pkg::name").
@RgPkgMap rg_pkgmap_find -> @RgPkgMap head, str key {
    @RgPkgMap e = head;
    int hx = rgx_lk_hash(key);
    while e != null {
        if e.hash == hx && p_text_eq(e.key, key) {
            return e;
        }
        e = e.next;
    }
    return null;
}

!!! _pkg_members["pkg::name"] = member.
@RgPkgMap rg_pkgmap_set -> @RgPkgMap head, str key, @PkgMember m {
    @RgPkgMap last = null;
    @RgPkgMap e = head;
    int hx = rgx_lk_hash(key);
    while e != null {
        if e.hash == hx && p_text_eq(e.key, key) {
            e.m = m;
            return head;
        }
        last = e;
        e = e.next;
    }
    RgPkgMap proto;
    @RgPkgMap n;
    malloc(@n, size proto);
    n.key = key;
    n.m = m;
    n.next = null;
    if last == null {
        return n;
    }
    last.next = n;
    return head;
}

!!! the vector-shaped members

!!! _cur_func_closures.push_back(name) and _cur_builtin_params,
!!! func_param_names values, _pkg_short values, plan.prefix / plan.fields:
!!! appending a name to the tail of a chain of StrNode.
@StrNode rg_strchain_append -> @StrNode head, str s {
    @StrNode last = null;
    @StrNode e = head;
    while e != null {
        last = e;
        e = e.next;
    }
    StrNode proto;
    @StrNode n;
    malloc(@n, size proto);
    n.s = s;
    n.line = 0;
    n.col = 0;
    n.len = 0;
    n.next = null;
    if last == null {
        return n;
    }
    last.next = n;
    return head;
}

!!! ptype_lines / ptype_cols / ptype_lens of a StubProto: appending an int.
@IntNode rg_intchain_append -> @IntNode head, int v {
    @IntNode last = null;
    @IntNode e = head;
    while e != null {
        last = e;
        e = e.next;
    }
    IntNode proto;
    @IntNode n;
    malloc(@n, size proto);
    n.v = v;
    n.next = null;
    if last == null {
        return n;
    }
    last.next = n;
    return head;
}

!!! _cur_tparam_types-shaped vectors and the param_types of an OverloadVersion:
!!! appending one VarType to a chain.
@VarTypeNode rg_vartypechain_append -> @VarTypeNode head, VarType ty {
    @VarTypeNode last = null;
    @VarTypeNode e = head;
    while e != null {
        last = e;
        e = e.next;
    }
    VarTypeNode proto;
    @VarTypeNode n;
    malloc(@n, size proto);
    n.ty = ty;
    n.next = null;
    if last == null {
        return n;
    }
    last.next = n;
    return head;
}

!!! A vector<bool> value and the flags of a parameter: appending one flag.
@BoolNode rg_boolchain_append -> @BoolNode head, bool v {
    @BoolNode last = null;
    @BoolNode e = head;
    while e != null {
        last = e;
        e = e.next;
    }
    BoolNode proto;
    @BoolNode n;
    malloc(@n, size proto);
    n.v = v;
    n.next = null;
    if last == null {
        return n;
    }
    last.next = n;
    return head;
}

!!! A a chain of longlong (the dimensions of a declaration): appending one
!!! dimension.
@RgLongNode rg_longchain_append -> @RgLongNode head, longlong v {
    @RgLongNode last = null;
    @RgLongNode e = head;
    while e != null {
        last = e;
        e = e.next;
    }
    RgLongNode proto;
    @RgLongNode n;
    malloc(@n, size proto);
    n.v = v;
    n.next = null;
    if last == null {
        return n;
    }
    last.next = n;
    return head;
}

!!! _lambdas.push_back(n), func_param_defaults values, plan.idx: appending an
!!! expression node to a chain of RgExprRef (never to the node's own `next`).
@RgExprRef rg_exprref_append -> @RgExprRef head, @ExprNode e {
    @RgExprRef last = null;
    @RgExprRef cnode = head;
    while cnode != null {
        last = cnode;
        cnode = cnode.next;
    }
    RgExprRef proto;
    @RgExprRef n;
    malloc(@n, size proto);
    n.e = e;
    n.next = null;
    if last == null {
        return n;
    }
    last.next = n;
    return head;
}

!!! collect_flat_fields' out.push_back({&f, type}).
@RgFlatPair rg_flatpair_append -> @RgFlatPair head, @StructField field,
                                  str decl_type {
    @RgFlatPair last = null;
    @RgFlatPair e = head;
    while e != null {
        last = e;
        e = e.next;
    }
    RgFlatPair proto;
    @RgFlatPair n;
    malloc(@n, size proto);
    n.field = field;
    n.decl_type = decl_type;
    n.next = null;
    if last == null {
        return n;
    }
    last.next = n;
    return head;
}

!!! collect_leaf_fields' out.push_back({&f, type, cnode}).
@FlatField rg_flatchain_append -> @FlatField head, @StructField field,
                                  str decl_type, int abs_off {
    @FlatField last = null;
    @FlatField e = head;
    while e != null {
        last = e;
        e = e.next;
    }
    FlatField proto;
    @FlatField n;
    malloc(@n, size proto);
    n.field = field;
    n.decl_type = decl_type;
    n.abs_off = abs_off;
    n.next = null;
    if last == null {
        return n;
    }
    last.next = n;
    return head;
}

!!! func_overloads[name].push_back(ov): one more version of a name.
@OverloadVersion rg_overloadver_append -> @OverloadVersion head,
                                          @OverloadVersion node {
    if head == null {
        return node;
    }
    @OverloadVersion e = head;
    while e.next != null {
        e = e.next;
    }
    e.next = node;
    return head;
}

!!! plan.levels.push_back(level): one more subscript of a store chain.
@IndexChainLevel rg_chainlevel_append -> @IndexChainLevel head,
                                         @IndexChainLevel node {
    if head == null {
        return node;
    }
    @IndexChainLevel e = head;
    while e.next != null {
        e = e.next;
    }
    e.next = node;
    return head;
}

!!! _struct_scopes.back().push_back({var, stype}): one more struct local of the
!!! scope that is open.
@RgStructLocal rg_structlocal_append -> @RgStructLocal head, str var, str stype {
    @RgStructLocal last = null;
    @RgStructLocal e = head;
    while e != null {
        last = e;
        e = e.next;
    }
    RgStructLocal proto;
    @RgStructLocal n;
    malloc(@n, size proto);
    n.var = var;
    n.stype = stype;
    n.next = null;
    if last == null {
        return n;
    }
    last.next = n;
    return head;
}

!!! resolve_bapi_seg's out.push_back({fi, ci}): one more resolved BAPI argument.
@ResolvedArg rg_resolvedarg_append -> @ResolvedArg head, @ResolvedArg node {
    if head == null {
        return node;
    }
    @ResolvedArg e = head;
    while e.next != null {
        e = e.next;
    }
    e.next = node;
    return head;
}

!!! the stacks the toolchain keeps in vectors

!!! _param_sym_stack.push_back(frame) and .pop_back() (push_func_params writes
!!! the frame it pushed, so it reads it back through rg_param_frame_top).
void rg_param_frame_push -> @ParamSymFrame fr {
    fr.next = rg_param_sym_stack;
    rg_param_sym_stack = fr;
}

@ParamSymFrame rg_param_frame_top {
    return rg_param_sym_stack;
}

void rg_param_frame_drop {
    if rg_param_sym_stack == null {
        end;
    }
    rg_param_sym_stack = rg_param_sym_stack.next;
}

!!! _local_sym_stack.push_back(frame) and .pop_back().
void rg_local_frame_push -> @LocalSymFrame fr {
    fr.next = rg_local_sym_stack;
    rg_local_sym_stack = fr;
}

@LocalSymFrame rg_local_frame_top {
    return rg_local_sym_stack;
}

void rg_local_frame_drop {
    if rg_local_sym_stack == null {
        end;
    }
    rg_local_sym_stack = rg_local_sym_stack.next;
}

!!! _struct_scopes.push_back({}) and .pop_back() (pop_struct_scope reads the
!!! frame it drops, so it takes it out itself through the chain head).
void rg_struct_scope_push -> @RgStructScope sc {
    sc.next = rg_struct_scopes;
    rg_struct_scopes = sc;
}

void rg_struct_scope_drop {
    if rg_struct_scopes == null {
        end;
    }
    rg_struct_scopes = rg_struct_scopes.next;
}

!!! _const_scopes.push_back({}) and .pop_back() (const_info_of walks the scopes
!!! from the innermost out through the chain head, the toolchain
!!! `_const_scopes.rbegin()`).
void rg_const_scope_push -> @RgConstScope sc {
    sc.next = rg_const_scopes;
    rg_const_scopes = sc;
}

void rg_const_scope_drop {
    if rg_const_scopes == null {
        end;
    }
    rg_const_scopes = rg_const_scopes.next;
}

!!! The dimensions of a declaration are an IntNode chain in the statements and an
!!! RgLongNode chain in sym_dims, because a dimension is a 64-bit value there.
@RgLongNode rg_longchain_of -> @IntNode head {
    @RgLongNode out = null;
    @IntNode e = head;
    while e != null {
        out = rg_longchain_append(out, (longlong)e.v);
        e = e.next;
    }
    return out;
}

!!! The expression-vector maps keep a chain of RgExprRef, because a node's own
!!! `next` is the list it was parsed in. This is the conversion of a plain chain.
@RgExprRef rg_exprref_of -> @ExprNode head {
    @RgExprRef out = null;
    @ExprNode e = head;
    while e != null {
        out = rg_exprref_append(out, e);
        e = e.next;
    }
    return out;
}

!!! resolve_struct_type_slot(..., a chain of StmtNode*& defs, ...): a new
!!! instantiation is queued in `defs`, so the queue is a global like the name and
!!! the type the same call rewrites.
@StmtNode rg_resolve_struct_type_slot_out_defs;

!!! emit_stub_sigs: `_stub_sigs = on;`, the flag that makes a stub body be emitted
!!! as a signature instead of being skipped.
void rg_emit_stub_sigs -> bool on {
    rg_stub_sigs = on;
}

!!! expr_refs_any: does this expression tree reference any name in `names`? Used to
!!! avoid releasing a closure before a `return` that still reads it.
bool rg_expr_refs_any -> @ExprNode n, @RgStrSet names {
    if n == null {
        return false;
    }
    if n.nk == VAR_REF && rg_set_has(names, n.var_name) {
        return true;
    }
    !!! Calling a func variable (`f(x)`) names the callee in var_name, not in a
    !!! child node: without this the closure was released before the call and the
    !!! call ran on freed memory.
    if n.nk == FUNC_CALL && rg_set_has(names, n.var_name) {
        return true;
    }
    if rg_expr_refs_any(n.left, names) {
        return true;
    }
    if rg_expr_refs_any(n.right, names) {
        return true;
    }
    @ExprNode a = n.args;
    while a != null {
        if rg_expr_refs_any(a, names) {
            return true;
        }
        a = a.next;
    }
    @ExprNode ix = n.indices;
    while ix != null {
        if rg_expr_refs_any(ix, names) {
            return true;
        }
        ix = ix.next;
    }
    !!! `for (auto* a : n->lambda_immediate_args)` and the captured names: both live
    !!! in the literal's record in this implementation, found by the lambda id.
    if n.nk == LAMBDA {
        @LambdaRec rec = p_find_lambda(n.lambda_id);
        if rec != null {
            @ExprNode ia = rec.immediate_args;
            while ia != null {
                if rg_expr_refs_any(ia, names) {
                    return true;
                }
                ia = ia.next;
            }
            @StrNode c = rec.captures;
            while c != null {
                if rg_set_has(names, c.s) {
                    return true;
                }
                c = c.next;
            }
        }
    }
    return false;
}

!!! "<struct>\x01<member>": the key a member and a method are marked and looked up
!!! under. The separator cannot stand in a blang name, so a struct whose name ends
!!! where a member's begins cannot make two keys collide.
str rgx_member_key -> str ty, str name {
    return ty + char_text((char)1) + name;
}

void rg_mark_member_used -> str ty, str name, bool read {
    rg_member_used = rg_set_add(rg_member_used, rgx_member_key(ty, name));
    if read {
        rg_member_read = rg_set_add(rg_member_read, rgx_member_key(ty, name));
    }
}

bool rgx_member_used -> str ty, str name {
    return rg_set_has(rg_member_used, rgx_member_key(ty, name));
}

bool rgx_member_read -> str ty, str name {
    return rg_set_has(rg_member_read, rgx_member_key(ty, name));
}

void rg_mark_method_used -> str ty, str name {
    rg_method_used = rg_set_add(rg_method_used, rgx_member_key(ty, name));
}

void rg_mark_struct_used -> str name {
    if name != "" {
        rg_used_structs = rg_set_add(rg_used_structs, name);
    }
}
