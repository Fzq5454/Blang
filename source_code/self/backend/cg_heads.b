#once
!~
 ~  bootstrap/backend/cg_heads.b: the functions of the code generator.
 ~
 ~  the toolchain declares them in one class and the definitions are spread over
 ~  a function has to be declared before the file that uses
 ~  it, so the declarations stand here, in the order of codegen.
 ~
 ~  the toolchain hands a diagnostic back through a `str& error` parameter. The
 ~  port keeps it in `cg_stmt_err` (the error of the statement being generated),
 ~  which the callee writes and the caller reads after a false answer.
 ~!

#head "cg_state"

str cg_stmt_err;

stub bool cg_produces_owned_str -> @CmpExpr n;
stub int cg_intern_str -> str s;
stub str cg_err_at -> int line, int col, str msg;
stub void cg_report_undefined_ref -> str name;
stub str cg_hex_upper -> int v;

stub void cg_set_no_runtime -> bool v;
stub void cg_set_static_runtime -> bool v;
stub void cg_set_user_libs -> str libs;
stub void cg_set_pe_type -> int t;
stub void cg_set_debug_info -> bool v;
stub void cg_set_struct_types -> @CmpStructType st;
stub bool cg_get_debug_info;
stub @char cg_code_data;
stub int cg_code_size;
stub bool cg_is_func_local -> str name;
stub int cg_get_pe_type;
stub void cg_register_dll_import -> str dll, str func_name, @CmpTypeNode param_types,
                                    VarType ret_type;
stub int cg_import_index -> str name;
stub bool cg_can_call_native -> str name;
stub void cg_emit_call_native -> str name;
stub void cg_emit_alloc_block -> longlong bytes;
stub void cg_emit_alloc_rax;
stub @CgBmetaFunc cg_read_bmeta -> str dll;
stub int cg_vbmeta_type -> VarType t;
stub bool cg_write_bmeta -> str out_path;
stub void cg_resolve_pending_calls;

stub bool cg_ld8 -> int d;
stub void cg_st8 -> int d;
stub void cg_st4 -> int d;
stub bool cg_ld8_g -> int d;
stub void cg_st8_g -> int d;
stub void cg_st4_g -> int d;
stub void cg_st1_g -> int d;
stub void cg_ldsd_g -> int d;
stub void cg_stsd_g -> int d;
stub void cg_lea_g -> int d;
stub void cg_lea_var -> int off;
stub void cg_load_var -> int off, VarType ty, bool is_array, bool is_global;
!!! The same load into rdx, for the right operand of a binary operation that is read
!!! where it lives instead of through a temporary slot.
stub void cg_load_var_rdx -> int off, VarType ty, bool is_array;
stub void cg_ld8_rdx -> int d;
stub void cg_ld4sxd_rdx -> int d;
stub void cg_ld4sxd_g_rdx -> int d;
stub void cg_store_var -> int off, VarType ty, bool is_array, bool is_global;
stub void cg_emit_call_text -> int off;
stub bool cg_has_lib_sym -> str name;
stub bool cg_emit_call_lib -> str name;
stub void cg_emit_call_import -> int idx;
stub void cg_emit_lea_rax_rdata -> int rva;
stub void cg_emit_movsd_xmm0_rdata -> int rva;
stub void cg_emit_tostr_runtime;
stub bool cg_resolve_types -> @CmpExpr n;
stub bool cg_gen_stmt -> @CmpStmt s;
!!! One statement chain that is a block of its own: its declarations are put in
!!! place for it and the bindings they replaced come back when it ends.
stub bool cg_gen_block -> @CmpStmt body;
stub bool cg_gen_if_else -> @CmpStmt s;
!!! The operands of an integer comparison, ending in the `cmp` whose flags hold the
!!! answer, and a branch on those flags: a condition that is a comparison does not
!!! have to become a 0/1 value first.
stub void cg_gen_int_cmp -> @CmpExpr n, int temp_off;
!!! Whether the right operand of a binary operation is a variable that can be read
!!! into rdx where it lives, and the load itself (which has to run after the left).
stub bool cg_right_rdx_ok -> @CmpExpr n;
stub void cg_emit_right_rdx -> @CmpExpr n;
stub bool cg_cmp_jump_false -> @CmpExpr n;
stub bool cg_gen_switch -> @CmpStmt s;
stub bool cg_gen_repeat -> @CmpStmt s;
stub bool cg_gen_end -> @CmpStmt s;
stub bool cg_gen_continue -> @CmpStmt s;
stub bool cg_gen_try_catch -> @CmpStmt s;
stub bool cg_gen_raise -> @CmpStmt s;
stub void cg_emit_try_runtime;
stub void cg_emit_try_install;
stub void cg_emit_load_rax_text -> int target;
stub void cg_emit_store_rax_text -> int target;
stub void cg_emit_try_chain_pop;
stub void cg_emit_try_unlink;
stub void cg_emit_try_unlinks;
stub bool cg_gen_func -> @CmpStmt s;
stub bool cg_gen_ret -> @CmpStmt s;
stub void cg_load_reg_args -> int n;
!!! Whether a call argument can be read straight into its register, and the load.
stub bool cg_arg_direct_ok -> @CmpExpr a;
stub void cg_load_arg_direct -> @CmpExpr a, int reg;
stub void cg_load_var_arg -> int off, VarType ty, int reg;
stub VarType cg_param_type_of -> str fname, int idx;
stub void cg_spill_arg -> @CmpExpr a, VarType want;
stub void cg_emit_build_variadic_array -> @CmpExpr args, int start, int n,
                                          VarType elem_type;
stub void cg_emit_spread_push -> @CmpExpr arr;
stub bool cg_gen_bspread -> @CmpStmt s;
stub bool cg_gen_func_call -> str name, @CmpExpr args, int line, int col;
stub bool cg_gen_dll_import_call -> str name, @CmpExpr args, int line, int col;
stub bool cg_gen_declared -> @CmpStmt s;
stub bool cg_gen_call -> @CmpStmt s;
stub bool cg_gen_dref -> @CmpStmt s;
stub void cg_emit_retain_rax;
stub void cg_emit_release_closure_rax;
stub bool cg_gen_release -> @CmpStmt s;
stub bool cg_gen_cast -> @CmpStmt s;
stub bool cg_gen_exit -> @CmpStmt s;
stub void cg_emit_icall -> @CmpExpr target, @CmpExpr args;
stub bool cg_gen_icall -> @CmpStmt s;
stub void cg_gen_expr -> @CmpExpr n;
stub void cg_gen_not -> @CmpExpr n;
stub void cg_gen_cast_expr -> @CmpExpr n;
stub void cg_gen_array_access -> @CmpExpr n;
stub void cg_gen_binop -> @CmpExpr n;
stub bool cg_generate -> @CmpStmt stmts;
stub bool cg_narrow_int_literal -> @CmpExpr n;
stub void cg_emit_narrow_int_literal -> @CmpExpr n;
stub void cg_patch_calls;
stub void cg_patch_blib_imports;
stub bool cg_load_blib -> str name;
stub int cg_resolve_sym -> str name;
stub void cg_index_lib_syms;
stub bool cg_load_embedded_dll -> str dll;
stub int cg_embedded_text_off -> str name;
stub bool cg_write_static_dll -> str out_path;
stub void cg_patch_embedded;
stub void cg_register_embedded_imports;
stub void cg_note_rdata_ref -> int disp_pos, int rdata_rva;
stub void cg_emit_import_thunks -> @CgStrBool used;
stub void cg_emit_tostr_buffer_to_r10;
stub str cg_get_verbose_info;
