#once
!~
 ~  bootstrap/backend/parser_heads.b: the parser functions of every module.
 ~
 ~  The modules of the parser call each other in both directions (`cp_parse_stmt`
 ~  dispatches to `cp_parse_declared`, which reads expressions), and a function has
 ~  to be declared before the file that uses it: these stubs are that declaration.
 ~  The bodies live in the module named in the comment above each group.
 ~!

!!! parser.b
stub void cp_error -> str msg;
stub bool cp_has_error;
stub str cp_get_error;
stub void cp_advance;
stub void cp_start -> str fname;
stub bool cp_is -> str kw;
stub bool cp_at -> CmpTokKind k;
stub void cp_expect -> str kw;
stub void cp_expect_comma;
stub @CmpStmt cp_block;
stub bool cp_parse;
stub void cp_parse_stmt;
stub @CmpStmt cp_last_stmt;

!!! parser_type.b
stub void cp_parse_enum;
stub bool cp_parse_r_type;

!!! parser_expr.b
stub @CmpExpr cp_parse_expr;
stub VarType cp_widen -> VarType a, VarType b;

!!! parser_declared.b
stub void cp_parse_declared;
stub void cp_parse_struct_decl;
stub @CmpStructType cp_find_struct -> str name;

!!! parser_cast.b
stub void cp_parse_cast;
stub void cp_parse_exit;

!!! parser_flow.b
stub void cp_parse_if;
stub void cp_parse_switch;
stub void cp_parse_repeat;
stub @CmpStmt cp_take_last;

!!! parser_call.b
stub void cp_parse_call;
stub void cp_parse_bcall;
stub void cp_parse_dref;
stub void cp_parse_icall;
stub void cp_parse_release;
stub void cp_parse_bspread;

!!! parser_func.b
stub void cp_parse_func;
stub void cp_parse_ret;
stub void cp_parse_raise;
stub void cp_parse_try;
