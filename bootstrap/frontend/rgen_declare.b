#once
!~
 ~  bootstrap/frontend/rgen_declare.b: the frontend/rgen_declare, the
 ~  first pass of the code generator - every declared variable is registered once,
 ~  with the scope it was declared in.
 ~
 ~  the toolchain keeps the set of declarations it has already seen inside
 ~  collect_declared_vars, because its per-statement action is a lambda capturing
 ~  it. The action is a function of its own here (rg_collect_declared_vars_stmt, the
 ~  lambda walk_stmts_scoped was given), so the set is a global the walk fills and
 ~  the entry point empties.
 ~
 ~  A scope key is text, and the toolchain joins its parts with the characters 1 and 2.
 ~  Those are written with char_text: the language's string escapes have no
 ~  hexadecimal form, so a literal `"\x01"` would be the three characters `x01`.
 ~  The scope of one struct method carries the method's own position instead of its
 ~  address (see rgen_walk_scoped.b for the same mapping).
 ~!

#head "rgen"
#head "rules"
#head "attributes"

!!! The declarations already seen, keyed "scope<1>name": a name declared twice in
!!! one scope is a redeclaration.
@RgStrSet rg_declared_var_keys;

!!! How many dimensions a chain holds.
int rgx_intchain_n -> @IntNode head {
    int n = 0;
    @IntNode e = head;
    while e != null {
        n = n + 1;
        e = e.next;
    }
    return n;
}

!!! The symbol table entries one declaration writes: its type and pointer depth,
!!! and - when it has them - its struct type and `@T` flag, its array flag and
!!! dimensions, and its ref and unsigned flags. the toolchain writes this block twice,
!!! once for the declaration and once for the `__global_` alias of a global, with
!!! the same fields both times.
void rgx_declare_sym -> str name, @StmtNode s {
    rg_syms = rg_vartypemap_set(rg_syms, name, s.decl_type);
    rg_sym_depth = rg_intmap_set(rg_sym_depth, name, s.ptr_depth);
    if s.struct_type != "" {
        rg_sym_struct_type = rg_strmap_set(rg_sym_struct_type, name, s.struct_type);
        !!! `@T p`: the variable holds an address of a T, not a T.
        if s.ptr_depth > 0 {
            rg_sym_struct_ptr = rg_boolmap_set(rg_sym_struct_ptr, name, true);
        }
    }
    if s.is_array {
        rg_sym_is_array = rg_boolmap_set(rg_sym_is_array, name, true);
        if s.array_dims != null {
            rg_sym_dims = rg_dimmap_set(rg_sym_dims, name, rg_longchain_of(s.array_dims), rgx_intchain_n(s.array_dims));
        }
    }
    if s.decl_is_ref {
        rg_sym_is_ref = rg_boolmap_set(rg_sym_is_ref, name, true);
    }
    if s.decl_is_unsigned {
        rg_sym_is_unsigned = rg_boolmap_set(rg_sym_is_unsigned, name, true);
    }
}

!!! One statement of the walk, with the scope it is written in.
void rg_collect_declared_vars_stmt -> @StmtNode s, str scope {
    if s.nk == TRY_CATCH {
        !!! `exception (e)`: e is the int the handler receives the code in, and it
        !!! exists only inside the handler body.
        if s.var_name != "" {
            !!! The type only when nothing declared the name yet; the scope is
            !!! recorded either way, or a library function that happens to use the
            !!! same local name would make this one invisible.
            if rg_vartypemap_find(rg_syms, s.var_name) == null {
                rg_syms = rg_vartypemap_set(rg_syms, s.var_name, INT);
                rg_sym_depth = rg_intmap_set(rg_sym_depth, s.var_name, 0);
            }
            if scope == "" {
                rg_global_names = rg_set_add(rg_global_names, s.var_name);
            } else {
                rg_non_global_syms = rg_set_add(rg_non_global_syms, s.var_name);
            }
        }
        end;
    }
    if s.nk == DECLARE {
        !!! A declaration the parser could not name is already reported there;
        !!! registering it would only add a follow-on error.
        if s.var_name == "" {
            end;
        }
        !!! A package-qualified type becomes the member's internal name here, so
        !!! every later pass sees a plain struct name.
        if s.struct_type != "" {
            str nm = s.struct_type;
            int tc = s.type_col;
            if tc == 0 {
                tc = s.col;
            }
            rg_package_resolve_out_name = nm;
            int pr = rg_package_resolve(s.line, tc, pe_len(s.struct_type));
            if pr == 1 {
                s.struct_type = rg_package_resolve_out_name;
            }
        }
        str key = scope + char_text(1) + s.var_name;
        if rg_set_has(rg_declared_var_keys, key) {
            rg_fmt_err(s.var_line, s.var_col, "redeclared to '" + s.var_name + "'",
                       pe_len(s.var_name), (str)null, 0, true);
            rg_has_errors = true;
            end;
        }
        rg_declared_var_keys = rg_set_add(rg_declared_var_keys, key);
        if rg_vartypemap_find(rg_syms, s.var_name) == null {
            rgx_declare_sym(s.var_name, s);
        }
        if scope == "" {
            rg_global_names = rg_set_add(rg_global_names, s.var_name);
            !!! The alias `::name` resolves to, so a function-local of the same name
            !!! cannot shadow the global slot.
            str alias = "__global_" + s.var_name;
            if rg_vartypemap_find(rg_syms, alias) == null {
                rgx_declare_sym(alias, s);
            }
        } else {
            rg_non_global_syms = rg_set_add(rg_non_global_syms, s.var_name);
        }
    }
}

!!! The pass: the whole statement tree, then the bodies the tree does not hold -
!!! the constructor, the destructor and the methods of every struct, which are
!!! records of the StructDef rather than statements of the program.
void rg_collect_declared_vars {
    rg_declared_var_keys = null;
    rg_walk_stmts_scoped(rg_stmts, "");
    !!! A struct method body is not part of the statement list, so it is walked here
    !!! as well: a `T u;` declared inside a method has to be known as a struct before
    !!! the method body is expanded.
    @StructDef sd = p_struct_defs;
    while sd != null {
        !!! Every member body is a declaration scope of its own: methods of one
        !!! struct (or overloads of one method name) have to be able to use the same
        !!! local names.
        if sd.init_func != null {
            rg_walk_stmts_scoped(sd.init_func.true_body, sd.name + char_text(2) + "init");
        }
        if sd.destruct_func != null {
            rg_walk_stmts_scoped(sd.destruct_func.true_body, sd.name + char_text(2) + "dtor");
        }
        @StructMethod m = sd.methods;
        while m != null {
            if m.fn != null && !m.fn.broken {
                rg_walk_stmts_scoped(m.fn.true_body,
                                     sd.name + char_text(2) + (str)m.fn.line + ":" + (str)m.fn.col);
            }
            m = m.next;
        }
        sd = sd.next;
    }
}

!!! `rule <NAME>(...)` - the built-in check the program asked for.
!!!
!!! The statement writes nothing: it is a diagnostic over the program the compiler
!!! has already read, which is why it runs after the statements have been rewritten
!!! and their types resolved. `pair` is the rule there is for now: the calls of the
!!! functions it names are counted, the first half of the list against the second,
!!! and the first call left over is reported at its own position with the level
!!! ("error", "warning", "note") and the message the statement gives. A rule speaks
!!! about the declarations above it, so a name that is declared after the statement
!!! is an error rather than an answer.
!!!
!!! the `RGenerator::apply_rules` walks the statement vector twice with two
!!! lambdas of its own, so its two per-statement actions are the two stubs below,
!!! selected as actions 3 and 4 of rg_walk_stmts (rgen_walk.b): 3 fills the line of
!!! every declaration, 4 notes every call in the order it is written.

!!! Where every declaration of this file stands, by the name the source writes.
@RgIntMap rg_rule_decl_lines;

!!! One call of the program: the name it calls and where the name stands, so the
!!! call left over can be reported at its own position. `klass` is the half the
!!! rule's function list puts it in (0 for the first, 1 for the second, -1 for a
!!! function the rule does not name), worked out once per rule that is applied.
type RuleCall {
    str name;
    int line;
    int col;
    int len;
    int klass;
    @RuleCall next;
};

!!! Every call of the program, in the order it is written.
@RuleCall rg_rule_calls;

@RuleCall rg_rule_calls_tail;

void rg_rule_note_call -> str name, int line, int col, int len {
    int use_len = len;
    if use_len <= 0 {
        use_len = pe_len(name);
    }
    RuleCall proto;
    @RuleCall c;
    malloc(@c, size proto);
    c.name = rg_display_name(name);
    c.line = line;
    c.col = col;
    c.len = use_len;
    c.klass = -1;
    c.next = null;
    if rg_rule_calls_tail == null {
        rg_rule_calls = c;
    } else {
        rg_rule_calls_tail.next = c;
    }
    rg_rule_calls_tail = c;
}

!!! action 3: the line of every declaration of the program, the first one that
!!! declares a name. the toolchain fills an unordered_map the same way.
void rg_rule_decl_stmt -> @StmtNode s {
    if s.var_name == "" {
        end;
    }
    str shown = rg_display_name(s.var_name);
    if rg_intmap_find(rg_rule_decl_lines, shown) != null {
        end;
    }
    int ln = s.var_line;
    if ln == 0 {
        ln = s.line;
    }
    rg_rule_decl_lines = rg_intmap_set(rg_rule_decl_lines, shown, ln);
}

!!! Every call inside one expression, the node itself first and then its parts, in
!!! the order the toolchain visit lambda reads them.
void rg_rule_walk_expr -> @ExprNode n {
    if n == null {
        end;
    }
    if n.nk == FUNC_CALL && n.var_name != "" {
        rg_rule_note_call(n.var_name, n.line, n.col, n.tok_len);
    }
    rg_rule_walk_expr(n.left);
    rg_rule_walk_expr(n.right);
    @ExprNode a = n.args;
    while a != null {
        rg_rule_walk_expr(a);
        a = a.next;
    }
    @ExprNode ix = n.indices;
    while ix != null {
        rg_rule_walk_expr(ix);
        ix = ix.next;
    }
    @ExprNode te = n.targ_exprs;
    while te != null {
        rg_rule_walk_expr(te);
        te = te.next;
    }
}

!!! action 4: every call of the program, in the order it is written. A call is a
!!! statement (`f(x);`) or an expression, so both are read here.
void rg_rule_call_stmt -> @StmtNode s {
    if s.nk == CALL_FUNC && s.var_name != "" {
        int ln = s.var_line;
        if ln == 0 {
            ln = s.line;
        }
        int cl = s.var_col;
        if cl == 0 {
            cl = s.col;
        }
        rg_rule_note_call(s.var_name, ln, cl, pe_len(s.var_name));
    }
    rg_rule_walk_expr(s.expr);
    @ExprNode a = s.args;
    while a != null {
        rg_rule_walk_expr(a);
        a = a.next;
    }
    @ExprNode ai = s.array_init;
    while ai != null {
        rg_rule_walk_expr(ai);
        ai = ai.next;
    }
    @ExprNode ix = s.assign_indices;
    while ix != null {
        rg_rule_walk_expr(ix);
        ix = ix.next;
    }
    @ExprNode ce = s.case_exprs;
    while ce != null {
        rg_rule_walk_expr(ce);
        ce = ce.next;
    }
}

!!! The argument written at position `i` of a rule (0 is the first), or null when
!!! the rule has fewer arguments. A call expression's arguments are a chain of their
!!! own, which is what the rule a `msg_en_zh` names is read through.
@ExprNode rg_rule_expr_arg -> @ExprNode args, int i {
    @ExprNode a = args;
    int k = 0;
    while a != null {
        if k == i {
            return a;
        }
        k = k + 1;
        a = a.next;
    }
    return null;
}

@ExprNode rg_rule_arg -> @RuleUse u, int i {
    return rg_rule_expr_arg(u.args, i);
}

!!! Which half of the rule's function list a call belongs to: 0 for the first
!!! half, 1 for the second, -1 for a function the rule does not name.
int rg_rule_class -> str name, @StrNode fns, int half {
    int k = 0;
    @StrNode f = fns;
    while f != null {
        if pe_eq(f.s, name) {
            if k < half {
                return 0;
            }
            return 1;
        }
        k = k + 1;
        f = f.next;
    }
    return -1;
}

!!! The level a rule statement writes, which is one of its three words: the level of
!!! the statement itself, or - for `msg_en_zh` - the level of the rule it names, which
!!! is where a `pair(...)` head writes it. An empty answer means the text was not a
!!! level, and that has been reported. the `rule_level` lambda is the same step.
str rg_rule_level -> @ExprNode args, int at, @RuleUse u {
    str level = "";
    @ExprNode a = rg_rule_expr_arg(args, at);
    if a != null && a.nk == LIT_STR {
        level = a.str_val;
    }
    if pe_eq(level, "error") || pe_eq(level, "warning") || pe_eq(level, "note") {
        return level;
    }
    rg_fmt_err(u.line, u.col, "the level of a rule is \"error\", \"warning\" or \"note\"",
               u.len, (str)null, 0, true);
    rg_has_errors = true;
    return "";
}

!!! The report of `not_pair(...)`, which is what a rule that counts calls needs of
!!! the statement: its own first argument, or the first argument of the rule a
!!! `msg_en_zh` names. the `rule_payload` lambda is the same step.
bool rg_rule_payload -> @ExprNode args, @RuleUse u {
    @ExprNode payload = args;
    if payload != null && payload.nk == FUNC_CALL &&
       pe_eq(rg_display_name(payload.var_name), "not_pair") {
        return true;
    }
    rg_fmt_err(u.line, u.col,
               "the first argument of 'pair' is the report of 'not_pair(...)'",
               u.len, (str)null, 0, true);
    rg_has_errors = true;
    return false;
}

!!! The count `pair` is: the functions from `first` on are the two halves, the calls
!!! of each are counted, and the first call left over is reported at its own position
!!! with `level` and `msg`. `msg_en_zh` and `warn` run this same count over the
!!! functions of the rule statement they name, which is why the argument chain the
!!! functions are read from is an argument here. the `pair_check` lambda is the
!!! same step.
void rg_apply_pair_check -> @RuleUse u, @ExprNode args, int nargs, int first,
                             str level, str msg, bool report {
    !!! The function names, in the order they were written. A name that is not a
    !!! plain name of the file is reported, and the rule is not applied.
    @StrNode fns = null;
    int nfn = 0;
    bool ok = true;
    int i = first;
    while i < nargs {
        @ExprNode a = rg_rule_expr_arg(args, i);
        str fn = "";
        if a != null && a.nk == VAR_REF {
            fn = rg_display_name(a.var_name);
        }
        if fn == "" {
            rg_fmt_err(u.line, u.col,
                       "the objects a rule checks are written as plain names",
                       u.len, (str)null, 0, true);
            rg_has_errors = true;
            ok = false;
        } else {
            @RgIntMap dit = rg_intmap_find(rg_rule_decl_lines, fn);
            if dit == null {
                rg_fmt_err(u.line, u.col,
                           "'" + fn + "' is not declared before this rule",
                           u.len, (str)null, 0, true);
                rg_has_errors = true;
                ok = false;
            } else if dit.v > u.line {
                rg_fmt_err(u.line, u.col, "'" + fn + "' is declared after this rule",
                           u.len, (str)null, 0, true);
                rg_has_errors = true;
                ok = false;
            }
            fns = rg_strchain_append(fns, fn);
            nfn = nfn + 1;
        }
        i = i + 1;
    }
    if nfn < 2 || nfn % 2 != 0 {
        rg_fmt_err(u.line, u.col,
                   "the functions of 'pair' are read as two halves of the same size",
                   u.len, (str)null, 0, true);
        rg_has_errors = true;
        end;
    }
    if !ok {
        end;
    }
    !!! The two halves, and the calls of each: the calls are counted, and the
    !!! (paired + 1)-th call of the class that has more of them is the one left over.
    int half = nfn / 2;
    int nfirst = 0;
    int nsecond = 0;
    @RuleCall c = rg_rule_calls;
    while c != null {
        c.klass = rg_rule_class(c.name, fns, half);
        if c.klass == 0 {
            nfirst = nfirst + 1;
        }
        if c.klass == 1 {
            nsecond = nsecond + 1;
        }
        c = c.next;
    }
    int paired = nfirst;
    if nsecond < paired {
        paired = nsecond;
    }
    int majority = -1;
    if nfirst > paired {
        majority = 0;
    } else if nsecond > paired {
        majority = 1;
    }
    if majority < 0 {
        end;
    }
    @RuleCall extra = null;
    int seen = 0;
    c = rg_rule_calls;
    while c != null {
        if c.klass == majority {
            seen = seen + 1;
            if seen == paired + 1 {
                extra = c;
                skip;
            }
        }
        c = c.next;
    }
    if extra == null {
        end;
    }
    !!! `report` is what a wrapper asks for: the check still runs - a name nothing
    !!! declares and a list that is not two equal halves are errors either way - and
    !!! only the report of a call left over waits for it.
    if !report {
        end;
    }
    if pe_eq(level, "error") {
        rg_fmt_err(extra.line, extra.col, msg, extra.len, (str)null, 0, true);
        rg_has_errors = true;
        end;
    }
    if pe_eq(level, "warning") {
        rg_fmt_warn(extra.line, extra.col, msg, extra.len);
        end;
    }
    rg_fmt_note(extra.line, extra.col, msg, extra.len);
}

!!! The rule call a wrapper (`msg_en_zh`, `warn`) names, read into the things a check
!!! needs: the level it reports at, the message it reports, and the argument chain the
!!! functions are counted from with where they begin. Both kinds of rule a wrapper may
!!! name are read here, so a wrapper can name another wrapper
!!! (`warn(msg_en_zh(pair(...), "en", "zh"))`). The answers are the globals below,
!!! because a function here answers one value only; the `read_report` lambda is the
!!! same step.
@ExprNode rg_rule_report_args;
int rg_rule_report_nargs;
int rg_rule_report_first;
str rg_rule_report_level;
str rg_rule_report_msg;

bool rg_rule_read_report -> @ExprNode call, @RuleUse u, str wrapper {
    rg_rule_report_args = null;
    rg_rule_report_nargs = 0;
    rg_rule_report_first = 0;
    rg_rule_report_level = "";
    rg_rule_report_msg = "";
    int inner_rule = RULE_NONE;
    if call != null && call.nk == FUNC_CALL {
        inner_rule = rule_find(rg_display_name(call.var_name));
    }
    if !rule_reports(inner_rule) {
        rg_fmt_err(u.line, u.col,
                   "the first argument of '" + wrapper + "' is the rule to check with",
                   u.len, (str)null, 0, true);
        rg_has_errors = true;
        return false;
    }
    if inner_rule == RULE_PAIR {
        !!! `pair(<report>, "<level>", "<message>", <function>, ...)`.
        if rgx_na_len_expr(call.args) < 4 {
            rg_fmt_err(u.line, u.col,
                       "rule 'pair' needs a report, a level, a message and two functions",
                       u.len, (str)null, 0, true);
            rg_has_errors = true;
            return false;
        }
        if !rg_rule_payload(call.args, u) {
            return false;
        }
        str level = rg_rule_level(call.args, 1, u);
        if level == "" {
            return false;
        }
        @ExprNode msg_e = rg_rule_expr_arg(call.args, 2);
        if msg_e == null || msg_e.nk != LIT_STR {
            rg_fmt_err(u.line, u.col, "the message of a rule is a string",
                       u.len, (str)null, 0, true);
            rg_has_errors = true;
            return false;
        }
        rg_rule_report_args = call.args;
        rg_rule_report_nargs = rgx_na_len_expr(call.args);
        rg_rule_report_first = 3;
        rg_rule_report_level = level;
        rg_rule_report_msg = msg_e.str_val;
        return true;
    }
    !!! `msg_en_zh(<rule>, "<english>", "<chinese>")`: the two messages replace the one
    !!! the rule inside wrote.
    if rgx_na_len_expr(call.args) != 3 {
        rg_fmt_err(u.line, u.col,
                   "rule 'msg_en_zh' needs a rule and two messages",
                   u.len, (str)null, 0, true);
        rg_has_errors = true;
        return false;
    }
    @ExprNode inner = rg_rule_expr_arg(call.args, 0);
    if !rg_rule_read_report(inner, u, "msg_en_zh") {
        return false;
    }
    str level2 = rg_rule_report_level;
    @ExprNode args2 = rg_rule_report_args;
    int nargs2 = rg_rule_report_nargs;
    int first2 = rg_rule_report_first;
    @ExprNode en_e = rg_rule_expr_arg(call.args, 1);
    @ExprNode zh_e = rg_rule_expr_arg(call.args, 2);
    if en_e == null || en_e.nk != LIT_STR || zh_e == null || zh_e.nk != LIT_STR {
        rg_fmt_err(u.line, u.col, "the messages of 'msg_en_zh' are two strings",
                   u.len, (str)null, 0, true);
        rg_has_errors = true;
        return false;
    }
    rg_rule_report_args = args2;
    rg_rule_report_nargs = nargs2;
    rg_rule_report_first = first2;
    rg_rule_report_level = level2;
    rg_rule_report_msg = zh_pick(en_e.str_val, zh_e.str_val);
    return true;
}

!!! One `rule pair(...)` statement applied: its arguments checked, then the count.
void rg_apply_one_rule -> @RuleUse u {
    if u.nargs < 4 {
        rg_fmt_err(u.line, u.col,
                   "rule 'pair' needs a report, a level, a message and two functions",
                   u.len, (str)null, 0, true);
        rg_has_errors = true;
        end;
    }
    if !rg_rule_payload(u.args, u) {
        end;
    }
    str level = rg_rule_level(u.args, 1, u);
    if level == "" {
        end;
    }
    @ExprNode msg_e = rg_rule_arg(u, 2);
    if msg_e == null || msg_e.nk != LIT_STR {
        rg_fmt_err(u.line, u.col, "the message of a rule is a string",
                   u.len, (str)null, 0, true);
        rg_has_errors = true;
        end;
    }
    rg_apply_pair_check(u, u.args, u.nargs, 3, level, msg_e.str_val, true);
}

!!! One `rule msg_en_zh(...)` statement applied: the rule statement inside it says
!!! which check runs, at which level, and over which functions; the check is reported
!!! with the English message, and with the Chinese one when the compiler speaks
!!! Chinese. The message the rule inside wrote is the one the two replace.
void rg_apply_msg_en_zh_rule -> @RuleUse u {
    if u.nargs != 3 {
        rg_fmt_err(u.line, u.col,
                   "rule 'msg_en_zh' needs a rule and two messages",
                   u.len, (str)null, 0, true);
        rg_has_errors = true;
        end;
    }
    if !rg_rule_read_report(rg_rule_arg(u, 0), u, "msg_en_zh") {
        end;
    }
    !!! The two messages of `msg_en_zh` replace the one the rule inside wrote - the
    !!! rule a wrapper names is a rule statement of its own, so its message is the one
    !!! this statement's strings stand in for.
    @ExprNode en_e = rg_rule_arg(u, 1);
    @ExprNode zh_e = rg_rule_arg(u, 2);
    if en_e == null || en_e.nk != LIT_STR || zh_e == null || zh_e.nk != LIT_STR {
        rg_fmt_err(u.line, u.col, "the messages of 'msg_en_zh' are two strings",
                   u.len, (str)null, 0, true);
        rg_has_errors = true;
        end;
    }
    str msg = zh_pick(en_e.str_val, zh_e.str_val);
    rg_apply_pair_check(u, rg_rule_report_args, rg_rule_report_nargs, rg_rule_report_first,
                        rg_rule_report_level, msg, true);
}

!!! One `rule warn(...)` statement applied: the check of the rule it names, reported as
!!! a warning of the -W-userdef class. Nothing is reported until the switch is given,
!!! and the level the rule inside wrote is not the level of the report: every one of
!!! them is a warning, because a check a program writes for itself does not decide that
!!! the build fails.
void rg_apply_warn_rule -> @RuleUse u {
    if u.nargs != 1 {
        rg_fmt_err(u.line, u.col, "rule 'warn' needs a rule",
                   u.len, (str)null, 0, true);
        rg_has_errors = true;
        end;
    }
    if !rg_rule_read_report(rg_rule_arg(u, 0), u, "warn") {
        end;
    }
    rg_apply_pair_check(u, rg_rule_report_args, rg_rule_report_nargs, rg_rule_report_first,
                        "warning", rg_rule_report_msg, rg_warn_userdef);
}

!!! apply_rules: every `rule` statement of the source, applied once the statements
!!! have been rewritten and their types resolved. the `RGenerator::apply_rules`
!!! is the same step.
void rg_apply_rules {
    if rule_uses == null {
        end;
    }
    rg_rule_decl_lines = null;
    rg_rule_calls = null;
    rg_rule_calls_tail = null;
    rg_walk_stmts(rg_stmts, 3);
    rg_walk_stmts(rg_stmts, 4);
    @RuleUse u = rule_uses;
    while u != null {
        int which = rule_find(u.name);
        if which == RULE_MSG_EN_ZH {
            rg_apply_msg_en_zh_rule(u);
        } else if which == RULE_WARN {
            rg_apply_warn_rule(u);
        } else if which == RULE_PAIR {
            rg_apply_one_rule(u);
        }
        u = u.next;
    }
    rg_rule_decl_lines = null;
    rg_rule_calls = null;
    rg_rule_calls_tail = null;
}

!!! `attribute <object>: <NAME>` - the object it names.
!!!
!!! the `RGenerator::apply_attributes` does two things in one loop over the
!!! uses: it reports what is wrong with the object a use names, and it applies what
!!! the attribute says. Here the two are apart: what an attribute says about a
!!! declaration is applied by rg_apply_attr_decl (rgen_register.b, while the
!!! declarations are collected) and what it says about a name being used by
!!! rg_apply_attr_used (rgen_used.b, before the unused warnings), so this pass
!!! holds the two diagnostics and nothing else, at the place the toolchain makes them:
!!! before the passes that follow, so a name that is not declared, or that is
!!! declared below the attribute, is reported the same way in both compilers.
!!!
!!! An attribute and a rule speak about the declarations above them, so a use of a
!!! name that is declared below it is reported rather than applied. That is what
!!! rgx_attr_order_check (rgen_register.b) answers while the type is applied: it
!!! asks the same question and leaves the declaration alone.
!!!
!!! Where the declarations of this file stand, by the name the source writes. The
!!! keeps the statement it found (`by_name`), which is the same thing for the
!!! question asked here: the position of the first declaration of that name. The
!!! fills it from FUNCTION and DECLARE statements only, because a call
!!! statement carries a name of its own and is not a declaration.
@RgIntMap rg_attr_by_name;

!!! action 5: the line of every declaration a plain object name can stand for.
void rg_attr_decl_stmt -> @StmtNode s {
    if s.nk != FUNCTION && s.nk != DECLARE {
        end;
    }
    if s.var_name == "" {
        end;
    }
    str shown = rg_display_name(s.var_name);
    if rg_intmap_find(rg_attr_by_name, shown) != null {
        end;
    }
    int ln = s.var_line;
    if ln == 0 {
        ln = s.line;
    }
    rg_attr_by_name = rg_intmap_set(rg_attr_by_name, shown, ln);
}

!!! Every `attribute` statement of the source, checked: the object it names is a
!!! struct, a function, a variable or a member of a struct, it is declared, and it
!!! is declared above the attribute. A name nothing declares is a typo, and saying
!!! so is what the toolchain does while it applies the attributes.
void rg_apply_attr_checks {
    if attr_uses == null {
        end;
    }
    attr_skips = null;
    rg_attr_by_name = null;
    rg_walk_stmts(rg_stmts, 5);
    @AttrUse u = attr_uses;
    while u != null {
        if u.member != "" {
            !!! A member of a struct: `S.f` (a field) or `S.m` (a method). Both kinds
            !!! need the struct the member belongs to, and a member is not checked
            !!! against the position of the attribute: a struct's members are
            !!! declared with it.
            if p_find_struct(u.owner) == null {
                rg_fmt_err(u.line, u.col,
                           "attribute names an object that is not declared: '" + u.object + "'",
                           u.len, (str)null, 0, true);
                rg_has_errors = true;
            }
        } else if p_find_struct(u.object) != null {
            @StructDef sd = p_find_struct(u.object);
            if sd.line > u.line {
                rg_fmt_err(u.line, u.col,
                           "'" + u.object + "' is declared after this attribute",
                           u.len, (str)null, 0, true);
                rg_has_errors = true;
                attr_skip_add(u.line, u.col);
            }
        } else {
            @RgIntMap hit = rg_intmap_find(rg_attr_by_name, u.object);
            bool is_extern = rg_set_has(rg_extern_funcs, attr_table_name(u.object, u.scoped));
            if hit == null && !is_extern {
                rg_fmt_err(u.line, u.col,
                           "attribute names an object that is not declared: '" + u.object + "'",
                           u.len, (str)null, 0, true);
                rg_has_errors = true;
            } else if hit != null && hit.v > u.line {
                rg_fmt_err(u.line, u.col,
                           "'" + u.object + "' is declared after this attribute",
                           u.len, (str)null, 0, true);
                rg_has_errors = true;
                attr_skip_add(u.line, u.col);
            }
        }
        u = u.next;
    }
    rg_attr_by_name = null;
}
