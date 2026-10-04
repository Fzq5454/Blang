#once
!~
 ~  bootstrap/frontend/parser_heads.b: the parser of this implementation.
 ~
 ~  A recursive-descent parser is mutually recursive (an expression contains a
 ~  primary, a primary contains an argument list, an argument is an expression) and
 ~  the language wants a function before it is called. `stub` is exactly that
 ~  declaration: the definition in parser.b or in the parser_*.b module that stands
 ~  next to it - the way parser_* stands next to parser - is taken as its
 ~  implementation.
 ~
 ~  Every declaration of the parser lives here and nowhere else, so the modules
 ~  below carry the bodies only, and one file answers "what does the parser
 ~  offer?". Each of them reads this module through `#head "parser_heads"` (or
 ~  through parser.b, which reads it first).
 ~!

#head "lexer"
#head "ast"
#head "struct_def"

!!! `bapi_defs[name]`: the BLANG_API statement declared under that name. the toolchain
!!! keeps a map here; this implementation keeps a chain of records. The statement itself cannot
!!! be the chain: the parser links every statement it returns into the program
!!! chain, so a table of those nodes walks into the whole program and answers a
!!! FUNCTION that happens to share the name (bootstrap/_probe_tmpl.b).
type PBapiDef {
    str name;
    @StmtNode stmt;
    @PBapiDef next;
};

!!! the diagnostics. The layout is libbstr's, the one every
!!! message compiler is written with: "file:line:col: error: msg", then
!!! the source line with the span in bold red and the caret line under it, in color
!!! where the terminal takes the codes.
stub void p_error_msg -> int line, int col, int len, str msg, str suggestion,
                         int sug_col, bool show_tilde;
stub void p_error_at -> int line, int col, int len, str msg;
stub void p_error_at_sug -> int line, int col, int len, str msg, str sug, int sug_col;
stub void p_error -> str msg;
stub void p_error_cur -> str msg;
stub void p_error_prev -> str msg;
stub void p_error_prev_sug -> str msg, str sug;

!!! The note that points at the '(' a missing ')' belongs to, and the one that
!!! points at the '{' a missing '}' belongs to.
stub void p_unmatched_paren_note -> int lparen_line, int lparen_col;
stub void p_unmatched_brace_note -> int lbrace_line, int lbrace_col;

!!! parser_expr
stub @ExprNode parse_expr -> int min_prec;
stub @ExprNode p_primary;
stub @ExprNode p_lambda;
stub int p_prec -> str op;
stub bool p_is_binary_op;

!!! parser_primary
stub @ExprNode p_member_chain_on -> @ExprNode base;
stub @ExprNode p_method_call_on -> @ExprNode receiver;
stub @ExprNode p_field_elem -> @ExprNode base;

!!! parser_call
stub @StmtNode p_func_call;
stub void p_parse_call_arg;
stub void p_stmt_add_arg -> @StmtNode s;
stub void p_expr_add_arg -> @ExprNode n;
stub void p_array_access_add_index -> @ExprNode e, @ExprNode idx;
stub @ExprNode p_head_ref -> @StmtNode s;
stub void p_sync_to_rparen_or_semi;

!!! parser_stmt
stub @StmtNode parse_stmt;
stub bool p_is_kw -> str lit;
stub int p_chain_stmt_kind;
stub int p_stmt_assign_at;
stub bool p_assignable_target -> @ExprNode n;
stub bool p_at_stmt_boundary;
stub void p_sync;

!!! parser_block
stub @StmtNode p_block;
stub void p_array_init -> @StmtNode s;

!!! parser_declare
stub @StmtNode p_declare;

!!! parser_assign
stub @StmtNode p_assign;
stub @StmtNode p_dref_assign;
stub @StmtNode p_incr;

!!! parser_function
stub @StmtNode p_function -> bool is_stub;
!!! The `(Y etc) (Args etc)` parameter list of a template function.
stub bool p_parse_pack_params -> @StmtNode s;
stub bool p_pack_group -> str what;
!!! `(Pack etc OP)` / `(OP Pack etc)`, and the operator kinds a pack may fold with.
stub @ExprNode p_try_fold;
stub bool p_is_fold_op -> TokenKind k;
stub @StmtNode p_stub_function;
stub @StmtNode p_local_function;
stub @StmtNode p_reload_function;
stub void p_struct_method_params -> @StmtNode fn;
stub void p_skip_block;
stub @BoolNode p_chain_bool -> @BoolNode head, @BoolNode node;
stub @BapiCallSeg p_chain_seg -> @BapiCallSeg head, @BapiCallSeg node;
stub void p_set_last_bool -> @BoolNode head, bool v;
stub @StrNode p_copy_str_chain -> @StrNode src;

!!! parser_type
stub VarType p_type;
stub bool p_is_type;
stub bool p_unsigned_ok -> VarType t;
stub bool p_type_at -> int k;
stub int p_skip_type_at -> int k;
stub bool p_at_generic_type_head;
stub bool p_is_template_param -> str name;
stub bool p_is_cur_type_param -> str name;
stub bool p_is_cur_value_param -> str name;
stub bool p_in_str_chain -> @StrNode head, str name;
stub bool p_builtin_type_kw -> Token t;
stub bool p_builtin_ptr_kw -> Token t;
stub str p_type_spelling_at -> int k;
stub str p_const_spelling_at -> int k;
stub str p_generic_spelling_at -> int k;
stub bool p_validate_struct_targs -> str tname, int line, int col, int hlen;
stub bool p_const_entry_at -> int k;
stub bool p_at_explicit_type_args;
stub bool p_is_ptr_operator_decl;
stub bool p_is_decl_or_func_start;
stub bool p_peek_is_function;
stub @StmtNode p_decl_or_func;
stub bool p_take_builtin_kw;

!!! parser_flow
stub @StmtNode p_if;
stub @StmtNode p_while;
stub @StmtNode p_do_while;
stub @StmtNode p_switch;
stub @StmtNode p_break;
stub @StmtNode p_continue;
stub @StmtNode p_rcode;
stub @StmtNode p_back;
stub @StmtNode p_end;

!!! parser_return
stub @StmtNode p_return;

!!! parser_throw
stub @StmtNode p_throw;

!!! parser_try
stub @StmtNode p_try;

!!! parser_package
stub @StmtNode p_package;
stub @StmtNode p_use;

!!! parser_introduce
stub @StmtNode p_introduce;

!!! parser_struct
stub @StmtNode p_struct_def;
stub void p_skip_broken_operator_decl;

!!! parser_enum
stub @StmtNode p_enum;

!!! parser_bapi
stub @StmtNode p_bapi;
stub @StmtNode p_bapi_body -> @StmtNode s;
stub @StmtNode p_builtin_bind;

!!! The generic-struct template tables, read by the type reader and filled by the
!!! introduce and struct parsers.
stub @StructTemplate p_find_template -> str name;
stub @StructDef p_find_struct -> str name;
stub @StructDef p_add_struct -> str name, int line, int col;

!!! clone.b (clone): the AST helpers every later pass uses. The bodies live in
!!! clone.b; the fold results travel in fields there, because a function answers one
!!! value.
stub bool p_is_const_expr -> @ExprNode n;
stub void p_eval_const_int -> @ExprNode n;
stub str p_vt_spell -> VarType t;
stub str p_targ_ident -> @TArg a;
stub str p_targ_spell -> @TArg a;
stub str p_spell_const -> @TArg a;
stub str p_cast_op_for_type -> VarType t;
stub void p_eval_const_arg -> @ExprNode n, VarType want;
stub @TArg p_map_find -> @TArgMap m, str name;
stub @TArgMap p_map_add -> @TArgMap m, str name, @TArg arg;
stub @TArg p_new_arg;
stub bool p_ident_char -> char c;
stub str p_subst_type_spelling -> str sp, @TArgMap tmap;
stub @ExprNode p_clone_expr -> @ExprNode n;
stub @ExprNode p_clone_expr_t -> @ExprNode n, @TArgMap tmap;
stub @StmtNode p_clone_stmt -> @StmtNode s, @TArgMap tmap;
