#once
!~
 ~  bootstrap/frontend/parser.b: the recursive-descent parser.
 ~
 ~  and its parser_* family; the sections below
 ~  are marked with the file each one comes from, so splitting this into
 ~  parser_declare.b, parser_stmt.b and so on is mechanical.
 ~
 ~  Three things about how it works here:
 ~   * a token's text is a span in the source, so a name is copied once (through
 ~     span_text) only when the tree has to remember it;
 ~   * a node comes from the heap, measured with `size` of a prototype variable: a
 ~     StmtNode is 648 bytes and a body would not fit on the stack;
 ~   * the language has no forward declarations, so mutually recursive helpers are
 ~     folded into one function (a block is parsed where it is met) instead of being
 ~     declared twice the way the toolchain headers did it.
 ~!

#head "stdsrt"
#head "lexer"
#head "ast"
#head "parser_heads"
#head "vector"

!!! ---- parser: state ----

Token p_cur;
!!! Counters of the parser's per-token work, printed with BLANG_TIME: what a parse
!!! costs per token is the question these answer.
int g_n_adv;
int g_n_is;
int g_n_expect;
int g_n_tok;
int g_n_nameis;
!!! Where the current token sits in the token list. The parser walks that list by
!!! index, which is what makes looking ahead possible at all.
int p_pos;
!!! The token before the current one. A type or a name reports the length of what
!!! was just read (`type_len` is what draws the tilde under a type in a diagnostic),
!!! and that is the token that was current a step ago - the toolchain parser keeps the
!!! same thing as `prev_tok`.
Token p_prev;
int p_errors;
int p_nodes;
int p_stmts;

!!! The names a type may be spelled with besides the builtin keywords: the struct
!!! and enum types this file has already declared. A name that is in neither table
!!! and is not a type keyword is not a type, which is what makes `missing type`
!!! come out for it. the toolchain parser keeps the same two tables (struct_defs and
!!! enum_type_names) as maps; here they are two vectors of names and the lookup is
!!! a walk.
vector(str) p_struct_names;
vector(str) p_enum_type_names;
!!! The hashes of the names in those two tables, in the same order. A name is
!!! looked up in them for every type mention the parser meets, and the tables grow
!!! with the program, so a lookup that compared the text of every entry walked most
!!! of the table on the compiler's own source. Comparing the number first rejects an
!!! entry it cannot be in with one integer compare.
vector(int) p_struct_names_h;
vector(int) p_enum_type_names_h;

!!! What the type last read by `p_type` carried besides its VarType: the pointer
!!! depth of its `@`s, the `ref`/`const`/`static`/`utype` in front of it, and the
!!! name of the struct it names. the toolchain parser keeps these in `_last_*` members
!!! for the same reason: a function answers one value.
int p_last_ptr_depth;
bool p_last_is_ref;
!!! True when the type just read was `@StructType`: the value is the address of a
!!! struct, not the struct itself, and both the layout and every read of it differ.
bool p_last_is_struct_ptr;
bool p_last_is_const;
bool p_last_is_static;
bool p_last_is_unsigned;
str p_last_struct;

!!! ---- parser_error: the diagnostics ----
!!!
!!! The bodies are in parser_error.b, next to the file they come from; the
!!! signatures stand in parser_heads.b with the rest of the parser's surface.

!!! The function whose body the error is in (empty at the top level). The file a
!!! diagnostic names comes from the line it stands on (lex_get_source), the way the
!!! asks tok.get_source, so the parser keeps no file of its own.
str p_func_name;
str p_func_ret;
bool p_header_done;
!!! The line the function whose body is being read starts on (`_func_line` of the
!!! parser): the "In function" header names the file that line stands in, so a
!!! function written in a `#head` file is headed by that file.
int p_func_line;

!!! The notes the parser collects for the driver to print after the errors of the
!!! file: `block_notes` in the toolchain, which holds the "unmatched this '('" and
!!! "unmatched this '{'" notes of a bracket nothing closed. A note explains an
!!! error, so it stands under all of them and not in the middle of the block; the
!!! driver adds them (see frontend_run.b, `rg_notes = p_block_notes`).
str p_block_notes;

!!! ---- node pools ----
!!!
!!! A node is a heap block of its own. The tree keeps addresses (`@ExprNode e`), so
!!! a node must not move once it is built: a pool of struct values was used for that
!!! first, but a pool is a fixed array (4096 expressions, 2048 statements, ...) and
!!! a file that needs more simply ran out, while growing one would move every node
!!! already handed out. One `malloc` per node keeps each address valid for as long
!!! as the node is used and puts no ceiling on the file. The size comes from `size`
!!! of a prototype variable, so nothing about a node is hard-coded here.
!!!
!!! The blocks are not given back: a compiler reads one file, writes one program and
!!! ends, and the process exit returns them. Only `p_free_all` used to reset the
!!! pools, and it has nothing left to reset.

!!! A node that is only partly filled in is read as whatever the block held before.
!!! The makers below set the interesting fields, and every field a later pass reads
!!! has to be set here as well: a list that was never written (the BAPI call
!!! segments, the case bodies, a parameter chain) reads as a chain of junk, and
!!! walking it is an endless loop or a crash. the toolchain nodes get this from their
!!! member initializers; here every field is written out, so nothing depends on what
!!! `malloc` handed out.
!!!
!!! (`$e = zeroed_node` would be one statement instead of the list, but a whole
!!! struct assigned through a pointer copies only its first leaf today: see
!!! _zerocopy.b.)

@ExprNode p_new_expr -> ExprKind nk {
    ExprNode proto;
    @ExprNode e;
    malloc(@e, size proto);
    e.nk = nk;
    e.int_val = 0;
    e.lit_is_long = false;
    e.float_val = 0.0;
    e.str_val = "";
    e.str_from = 0;
    e.str_to = 0;
    e.bool_val = false;
    e.char_val = 0;
    e.var_name = "";
    e.var_name_start = 0;
    e.var_name_stop = 0;
    e.member_name = "";
    e.op = "";
    e.is_super = false;
    e.has_receiver = false;
    e.is_overload_call = false;
    e.spread = false;
    e.left = null;
    e.right = null;
    e.args = null;
    e.next = null;
    e.nargs = 0;
    !!! Every field is written: malloc answers a block that may hold what was there
    !!! before, so a field left out is read as rubbish. `indices` in particular is
    !!! walked by the pack expansion of a template body on every node it visits.
    e.indices = null;
    e.targs = null;
    e.targ_exprs = null;
    e.targ_structs = null;
    e.targ_is_value = null;
    e.arg_names = null;
    e.arg_name_lines = null;
    e.arg_name_cols = null;
    e.arg_name_lens = null;
    e.result_type = INT;
    e.is_unsigned = false;
    e.type_resolved = false;
    e.address_type = INT;
    e.struct_type = "";
    e.cast_type_param = "";
    e.ptr_depth = 0;
    e.struct_cast = false;
    e.count_folded = false;
    e.fold_right = false;
    e.convert_to = ANY;
    e.line = p_cur.line;
    e.col = p_cur.col;
    e.tok_len = p_cur.stop - p_cur.start;
    e.op_line = 0;
    e.op_col = 0;
    e.lambda_id = 0;
    p_nodes = p_nodes + 1;
    return e;
}

@StmtNode p_new_stmt -> StmtKind nk {
    StmtNode proto;
    @StmtNode s;
    malloc(@s, size proto);
    s.nk = nk;
    s.decl_type = INT;
    s.ptr_depth = 0;
    s.decl_is_ref = false;
    s.decl_is_const = false;
    s.decl_is_static = false;
    s.decl_is_unsigned = false;
    s.static_guard = false;
    s.static_init = false;
    s.var_name = "";
    s.expr = null;
    s.args = null;
    s.nargs = 0;
    s.arg_names = null;
    s.arg_name_lines = null;
    s.arg_name_cols = null;
    s.arg_name_lens = null;
    s.next = null;
    s.targs = null;
    s.targ_exprs = null;
    s.targ_structs = null;
    s.targ_is_value = null;
    s.true_body = null;
    s.false_body = null;
    s.line = p_cur.line;
    s.col = p_cur.col;
    s.var_line = 0;
    s.var_col = 0;
    s.type_col = 0;
    s.type_len = 0;
    s.incr_op = "";
    s.incr_prefix = false;
    s.fparams = null;
    s.fparam_types = null;
    s.fparam_struct = null;
    s.fparam_is_array = null;
    s.fparam_is_ref = null;
    s.fparam_is_const = null;
    s.fparam_is_static = null;
    s.fparam_is_unsigned = null;
    s.fparam_defaults = null;
    s.fparam_has_default = null;
    s.nfparams = 0;
    s.ret_type_line = 0;
    s.ret_type_col = 0;
    s.ret_type_len = 0;
    s.variadic = false;
    !!! `-> (Y etc) (Args etc)`: the pack parameter list a template instantiation
    !!! builds its `fparams` from.
    s.params_from_pack = false;
    s.pack_ptypes = "";
    s.pack_pnames = "";
    s.func_ret_type = INT;
    s.ret_is_unsigned = false;
    s.ret_struct = "";
    s.ret_struct_ptr = false;
    s.ret_ptr_depth = 0;
    s.has_return = false;
    s.call_target = "";
    s.bapi_segs = null;
    s.builtin_annotation = "";
    s.end_line = 0;
    s.end_col = 0;
    s.broken = false;
    s.is_local = false;
    s.is_reload = false;
    s.is_stub = false;
    s.synth_op = "";
    s.reload_line = 0;
    s.reload_col = 0;
    s.reload_len = 0;
    s.params_line = 0;
    s.params_col = 0;
    s.params_len = 0;
    s.struct_type = "";
    !!! The access section a struct member was declared in (0 public, 1 protected,
    !!! 2 private): a fresh statement is public but not rubbish.
    s.access = 0;
    s.member_name = "";
    s.member_chain = null;
    s.members_before_index = 0;
    s.is_method_call = false;
    s.is_overload_call = false;
    s.member_line = 0;
    s.member_col = 0;
    s.is_super = false;
    s.is_index_ptr_store = false;
    s.is_index_chain_store = false;
    s.is_array = false;
    s.array_dims = null;
    s.array_len_expr = null;
    s.array_init = null;
    s.assign_indices = null;
    s.case_exprs = null;
    s.case_bodies = null;
    s.unmatch_body = null;
    s.rcode_text = "";
    p_stmts = p_stmts + 1;
    return s;
}

!!! The same, with the position the name was written at instead of the token the
!!! parser is standing on: a name read a step earlier keeps its own line and column
!!! in the tree, the way the toolchain parser's fparam_lines/fparam_cols do.
@StrNode p_new_span -> int from, int to, int line, int col {
    StrNode proto;
    @StrNode n;
    malloc(@n, size proto);
    n.s = span_text(from, to);
    n.line = line;
    n.col = col;
    n.len = to - from;
    n.next = null;
    return n;
}

!!! A node for text that is already a str: the contents of a string literal, which
!!! is not a span of the source (`__bcall("_memory")` names the target without its
!!! quotes).
@StrNode p_new_name -> str s, int line, int col {
    StrNode proto;
    @StrNode n;
    malloc(@n, size proto);
    n.s = s;
    n.line = line;
    n.col = col;
    n.len = 0;
    n.next = null;
    return n;
}

@VarTypeNode p_new_type -> VarType t {
    VarTypeNode proto;
    @VarTypeNode n;
    malloc(@n, size proto);
    n.ty = t;
    n.next = null;
    return n;
}

!!! ---- the chains ----
!!!
!!! A list in the tree is a chain of nodes, and the parser only ever appends to one,
!!! so appending answers the head of the chain it was handed: a chain that is still
!!! empty becomes the node itself. A `vector` cannot be passed to a helper for this:
!!! the object is copied when it is passed, so a helper would grow its own length
!!! and the caller's would stay where it was.

@StrNode p_chain_str -> @StrNode head, @StrNode node {
    if head == null {
        return node;
    }
    @StrNode t = head;
    while t.next != null {
        t = t.next;
    }
    t.next = node;
    return head;
}

@VarTypeNode p_chain_type -> @VarTypeNode head, @VarTypeNode node {
    if head == null {
        return node;
    }
    @VarTypeNode t = head;
    while t.next != null {
        t = t.next;
    }
    t.next = node;
    return head;
}

@ExprNode p_chain_expr -> @ExprNode head, @ExprNode node {
    if head == null {
        return node;
    }
    @ExprNode t = head;
    while t.next != null {
        t = t.next;
    }
    t.next = node;
    return head;
}

@IntNode p_new_int -> int v {
    IntNode proto;
    @IntNode n;
    malloc(@n, size proto);
    n.v = v;
    n.next = null;
    return n;
}

!!! The node is handed to the caller, so its release is the caller's: the
!!! `malloc`/`unlink` pairing check of `stdsrt` counts the allocation here and the
!!! `unlink` somewhere else, and reports what it reads as an unpaired `malloc`.
!!! `NOWARN` keeps that report - and every other warning about this body - out of
!!! the build. The same holds for `p_new_bool` below.
attribute p_new_int: NOWARN

@BoolNode p_new_bool -> bool v {
    BoolNode proto;
    @BoolNode n;
    malloc(@n, size proto);
    n.v = v;
    n.next = null;
    return n;
}

void p_adv {
    g_n_adv = g_n_adv + 1;
    p_prev = p_cur;
    p_pos = p_pos + 1;
    if p_pos >= g_tokens.len {
        p_pos = g_tokens.len - 1;
    }
    p_cur = g_tokens.get(p_pos);
}

!!! ---- looking ahead ----
!!!
!!! The parser is written over the token list, not over a stream: the token `k`
!!! ahead of the current one is what a decision about the statement in front of it
!!! is made with (`int x` is a declaration, `int x(` a function), and the toolchain
!!! parser reads `tokens[pos + k]` the same way. The end of the file answers every
!!! question with the end of the file, so a look that runs off the list is safe.
Token p_peek -> int k {
    int j = p_pos + k;
    if j < 0 {
        j = 0;
    }
    if j >= g_tokens.len {
        j = g_tokens.len - 1;
    }
    return g_tokens.get(j);
}

bool p_peek_is -> int k, TokenKind t {
    return p_peek(k).tk == t;
}

!!! Stand at the first token of the file.
void p_start {
    p_pos = 0;
    p_prev = g_tokens.get(0);
    p_cur = g_tokens.get(0);
    p_block_notes = "";
}

!!! ---- the tables the parser keeps (parser) ----
!!!
!!! the toolchain parser keeps these as unordered_map, unordered_set and a chain. A
!!! hash table is not something the language has and not something a compiler of
!!! this size needs: a name is looked up by walking a list of the names declared so
!!! far, and there are never many. A table that is only ever appended to is a chain
!!! (the same shape a node list has, see ast.b); a table that is also read by
!!! position is a pair of vectors walked together, or two chains read side by side.
!!!
!!! The struct and template tables hold definitions, and a definition is reached
!!! through a pointer - `struct_defs[name]` in is `p_find_struct(name)` here.

!!! `const int N = 65536;`: the name and the value, so a dimension written as that
!!! name has a length the backend can size the array with.
vector(str) p_const_names;
!!! The hashes of the names in `p_const_names`, in the same order.
vector(int) p_const_names_h;
vector(longlong) p_const_values;

!!! `__get_built_in_func<B> alias;`: the alias and the builtin it names.
type NamePair {
    str a;
    str b;
    @NamePair next;
};

!!! The names used in `__bcall("name")`, one entry per name.
vector(str) p_bcall_targets;
!!! The hashes of the names in `p_bcall_targets`, in the same order.
vector(int) p_bcall_targets_h;

!!! The BLANG_API definitions, by name: the BAPI statement is the definition.
@PBapiDef p_bapi_defs;

!!! The struct definitions and the generic ones, by name.
@StructDef p_struct_defs;
@StructTemplate p_struct_templates;

!!! The alias -> builtin bindings, and the builtins that were activated.
@NamePair p_builtin_binds;
@StrNode p_registered_builtins;

!!! The function templates: `introduce TYPENAME T { ... }` blocks.
@TemplateFunc p_template_funcs;

!!! Whether a `type` is being read inside an `introduce` block, and the package
!!! whose body is being parsed (empty = the global scope).
int p_in_introduce;
str p_cur_package;

!!! The type parameters in scope while an introduce block is parsed: `TYPENAME T`
!!! names, non-type (value) parameters, and template-template parameters. Every
!!! parameter of the block is also kept in declaration order, so a generic struct
!!! declared inside it keeps the same parameter list.
@StrNode p_cur_type_params;
@StrNode p_cur_value_params;
@StrNode p_cur_template_params;
@StrNode p_cur_tparams;
@BoolNode p_cur_tparam_is_value;
@BoolNode p_cur_tparam_is_template;
@VarTypeNode p_cur_tparam_types;
!!! The names declared with `ARGS A...` in the introduce block being parsed: the
!!! argument packs a template function's parameter list is expanded from.
@StrNode p_cur_arg_packs;

!!! The counter behind the hidden `__lambda_N` functions a lambda literal becomes.
int p_lambda_counter;
!!! The pieces of every lambda literal, found by the id its node carries: a lambda
!!! body is a statement list and an expression node cannot name one (see ast.b).
@LambdaRec p_lambdas;

@LambdaRec p_new_lambda -> int id {
    LambdaRec proto;
    @LambdaRec r;
    malloc(@r, size proto);
    r.id = id;
    r.params = null;
    r.param_types = null;
    r.param_is_array = null;
    r.body = null;
    r.captures = null;
    r.capture_types = null;
    r.capture_by_ref = null;
    r.immediate_args = null;
    r.ret_type = VOID;
    r.immediate = false;
    r.emitted = false;
    r.next = p_lambdas;
    p_lambdas = r;
    return r;
}

@LambdaRec p_find_lambda -> int id {
    @LambdaRec r = p_lambdas;
    while r != null {
        if r.id == id {
            return r;
        }
        r = r.next;
    }
    return null;
}

!!! The forward declarations of the parser stand in parser_heads.b, which is
!!! read at the top of this file: a recursive-descent parser is mutually
!!! recursive (an expression contains a primary, a primary contains an
!!! argument list, an argument is an expression) and the language wants a
!!! function before it is called. This module carries the bodies.

!!! The fold results travel in fields, because a function answers one value.
longlong p_eval_value;
float p_eval_dbl;
bool p_const_ok;
bool p_dbl_ok;
@TArg p_arg_out;
bool p_arg_ok;

bool p_is -> TokenKind k {
    g_n_is = g_n_is + 1;
    return p_cur.tk == k;
}

bool p_take -> TokenKind k {
    if p_cur.tk == k {
        p_adv();
        return true;
    }
    return false;
}

!!! Whether the current token is the keyword or identifier `lit`.
bool p_name_is -> str lit {
    g_n_nameis = g_n_nameis + 1;
    if p_cur.tk != TK_IDENT && p_cur.tk != TK_KEYWORD {
        return false;
    }
    return span_eq(p_cur.start, p_cur.stop, lit);
}

!!! ---- the name tables and the text helpers ----
!!!
!!! Reading a type, and the two questions a statement asks about one, are in
!!! parser_type.b, next to the parser_type they come from. What stands here is
!!! the state they read: the names of the types declared so far, the struct and
!!! generic-struct definitions behind them, and the text helpers every module uses.

!!! Whether two names are the same text. The names in the tables were built with
!!! `span_text`, so they are separate blocks of their own and have to be compared
!!! byte by byte.
!!! How many texts were compared, which BLANG_TIME prints.
int g_n_texteq;

bool p_text_eq -> str a, str b {
    g_n_texteq = g_n_texteq + 1;
    if a == null {
        return b == null;
    }
    if b == null {
        return false;
    }
    int i = 0;
    while a[i] != (char)0 {
        if a[i] != b[i] {
            return false;
        }
        i = i + 1;
    }
    return b[i] == (char)0;
}

!!! Whether the text holds the character `c`: the toolchain spelling tests are
!!! `s.find('(')`, and that is what this answers.
bool p_str_has -> str s, char c {
    if s == null {
        return false;
    }
    int i = 0;
    while s[i] != (char)0 {
        if s[i] == c {
            return true;
        }
        i = i + 1;
    }
    return false;
}

!!! The length of a name, for a diagnostic that draws a tilde under it.
int p_text_len -> str s {
    int n = 0;
    while s[n] != (char)0 {
        n = n + 1;
    }
    return n;
}

bool p_is_struct_name -> str name {
    int h = rgx_lk_hash(name);
    !!! The hash block is indexed directly: a `vector.get` is a call, and this walk
    !!! runs over every type name of the program for every type the input mentions.
    @int hashes = p_struct_names_h.data;
    int i = 0;
    while i < p_struct_names.len {
        if hashes[i] == h && p_text_eq(p_struct_names.get(i), name) {
            return true;
        }
        i = i + 1;
    }
    return false;
}

bool p_is_enum_name -> str name {
    int h = rgx_lk_hash(name);
    @int hashes = p_enum_type_names_h.data;
    int i = 0;
    while i < p_enum_type_names.len {
        if hashes[i] == h && p_text_eq(p_enum_type_names.get(i), name) {
            return true;
        }
        i = i + 1;
    }
    return false;
}

!!! The name of a struct or an enum type is kept the moment it is declared, so a
!!! later type mentions it by name and the two agree. The hash goes in beside the
!!! name, which is what keeps the two tables the lookups walk in step.
void p_remember_struct -> str name {
    p_struct_names.add(name);
    p_struct_names_h.add(rgx_lk_hash(name));
}

void p_remember_enum -> str name {
    p_enum_type_names.add(name);
    p_enum_type_names_h.add(rgx_lk_hash(name));
}

!!! `struct_defs[name]`: the definition behind a struct name, or null.
!!!
!!! The bucket heads of an index over p_struct_defs, keyed by the hash of the name.
!!! the `struct_defs` is an unordered_map and finds a definition with one
!!! probe; this implementation walked a chain of every struct the program declares, and the
!!! chain is in reverse declaration order, so the types a body names most are the
!!! ones at its far end. The definitions stay on the chain as they were - every
!!! pass that walks them still sees them in the same order - and each one carries
!!! the second link (`hnext`) that ties a bucket's definitions together.
!!!
!!! The block is asked for on the first lookup and every bucket in it is empty:
!!! malloc answers zeroed memory. Nothing ever leaves the chain, so a bucket needs
!!! no removal path.

int g_n_findstruct;
int kStructBuckets = 512;
@PStructBucket p_struct_buckets;

@StructDef p_find_struct -> str name {
    g_n_findstruct = g_n_findstruct + 1;
    int h = rgx_lk_hash(name);
    if p_struct_buckets == null {
        PStructBucket proto;
        @void cell;
        malloc(@cell, (int)size proto * kStructBuckets);
        p_struct_buckets = (@PStructBucket)cell;
    }
    @PStructBucket b = @p_struct_buckets[h & (kStructBuckets - 1)];
    @StructDef d = b.head;
    while d != null {
        if d.hash == h && p_text_eq(d.name, name) {
            return d;
        }
        d = d.hnext;
    }
    return null;
}

!!! `n` onto the bucket its hash names, which is where a lookup finds it. The
!!! caller has already put it on p_struct_defs, or keeps it out of that chain on
!!! purpose (`p_new_struct_def`): what stands here is the index alone.
void p_index_struct -> @StructDef d {
    if p_struct_buckets == null {
        PStructBucket proto;
        @void cell;
        malloc(@cell, (int)size proto * kStructBuckets);
        p_struct_buckets = (@PStructBucket)cell;
    }
    @PStructBucket b = @p_struct_buckets[d.hash & (kStructBuckets - 1)];
    d.hnext = b.head;
    b.head = d;
}

!!! `struct_defs[name] = def`, the first time and every time after: the toolchain
!!! operator[] creates the entry when it is missing, and the struct parser relies
!!! on that while it is still filling the definition in.
@StructDef p_add_struct -> str name, int line, int col {
    @StructDef d = p_find_struct(name);
    if d != null {
        return d;
    }
    StructDef proto;
    malloc(@d, size proto);
    d.name = name;
    d.hash = rgx_lk_hash(name);
    d.bases = null;
    d.bases_line = null;
    d.bases_col = null;
    d.fields = null;
    d.methods = null;
    d.bapi_methods = null;
    d.init_func = null;
    d.init_line = 0;
    d.init_col = 0;
    d.destruct_func = null;
    d.destruct_line = 0;
    d.destruct_col = 0;
    d.total_size = 0;
    d.line = line;
    d.col = col;
    d.next = p_struct_defs;
    p_struct_defs = d;
    p_index_struct(d);
    p_remember_struct(name);
    return d;
}

!!! A definition that is registered in neither table: the body of a generic struct
!!! is a template and the toolchain keeps it out of struct_defs (`if (!in_generic)`), so
!!! the name is not a type of its own. `Box(int)` is, and that is answered from
!!! struct_templates. Registering the name here as well made `Box(int) b;` stop at
!!! `Box` - it read as a plain struct type name with the argument list left over -
!!! and the variable name that was expected stood on the `(`.
@StructDef p_new_struct_def -> str name, int line, int col {
    StructDef proto;
    @StructDef d;
    malloc(@d, size proto);
    d.name = name;
    d.hash = rgx_lk_hash(name);
    d.bases = null;
    d.bases_line = null;
    d.bases_col = null;
    d.fields = null;
    d.methods = null;
    d.bapi_methods = null;
    d.init_func = null;
    d.init_line = 0;
    d.init_col = 0;
    d.destruct_func = null;
    d.destruct_line = 0;
    d.destruct_col = 0;
    d.total_size = 0;
    d.line = line;
    d.col = col;
    d.next = null;
    return d;
}

!!! The struct definition is handed to the caller and lives as long as the program
!!! does, so nothing unlinks it here: see `p_new_int` above.
attribute p_new_struct_def: NOWARN

!!! `struct_templates[name]`: the generic struct of that name, or null.
int g_n_findtpl;
@StructTemplate p_find_template -> str name {
    g_n_findtpl = g_n_findtpl + 1;
    @StructTemplate t = p_struct_templates;
    while t != null {
        if p_text_eq(t.def.name, name) {
            return t;
        }
        t = t.next;
    }
    return null;
}

!!! `template_funcs[name]`: the function template of that name, or null. the toolchain
!!! table is keyed by the name; here the name is the one the body carries, so the
!!! chain has nothing extra to keep.
int g_n_findtplfunc;
@TemplateFunc p_find_template_func -> str name {
    g_n_findtplfunc = g_n_findtplfunc + 1;
    @TemplateFunc t = p_template_funcs;
    while t != null {
        if t.fn != null && p_text_eq(t.fn.var_name, name) {
            return t;
        }
        t = t.next;
    }
    return null;
}

!!! `bapi_defs[name]`: the BLANG_API statement declared under that name, or null.
@StmtNode p_find_bapi -> str name {
    @PBapiDef e = p_bapi_defs;
    while e != null {
        if p_text_eq(e.name, name) {
            return e.stmt;
        }
        e = e.next;
    }
    return null;
}

!!! `bcall_targets.insert(name)`: whether a `__bcall("name")` was already seen.
bool p_has_bcall -> str name {
    int i = 0;
    int bh = rgx_lk_hash(name);
    @int hashes = p_bcall_targets_h.data;
    while i < p_bcall_targets.len {
        if hashes[i] == bh && p_text_eq(p_bcall_targets.get(i), name) {
            return true;
        }
        i = i + 1;
    }
    return false;
}

!!! `builtin_binds[alias] = name`.
void p_bind_builtin -> str alias, str name {
    NamePair proto;
    @NamePair n;
    malloc(@n, size proto);
    n.a = alias;
    n.b = name;
    n.next = p_builtin_binds;
    p_builtin_binds = n;
}

!!! `builtin_binds[alias]`, or null when the alias was never bound.
str p_find_bind -> str alias {
    @NamePair n = p_builtin_binds;
    while n != null {
        if p_text_eq(n.a, alias) {
            return n.b;
        }
        n = n.next;
    }
    return (str)null;
}

!!! ---- the enum table (parser_enum) ----
!!!
!!! The value of every enumerator, by name, and the names of the enum types. The
!!! parser keeps the values in an unordered_map; here they are three vectors
!!! walked together, the names, their hashes and the values in the same order.
!!!
!!! The hash beside each name is what keeps the walk cheap: an enumerator is looked
!!! up for every `TYPE.MEMBER` of the input, and comparing the whole name against
!!! every enumerator of the program was the parse stage's largest single cost - on
!!! the compiler's own source, seven million text comparisons.

vector(str) p_enum_names;
vector(int) p_enum_names_h;
vector(longlong) p_enum_values;

!!! Whether the last p_enum_value found the name.
bool p_enum_found;

longlong p_enum_value -> str name {
    p_enum_found = false;
    int h = rgx_lk_hash(name);
    !!! The hash block is indexed directly: a `vector.get` is a call, and this walk
    !!! is over every enumerator of the program.
    @int hashes = p_enum_names_h.data;
    int i = 0;
    while i < p_enum_names.len {
        if hashes[i] == h && p_text_eq(p_enum_names.get(i), name) {
            p_enum_found = true;
            return p_enum_values.get(i);
        }
        i = i + 1;
    }
    return 0;
}

!!! Give the name the value, adding it the first time and replacing it after that.
void p_enum_set -> str name, longlong v {
    int h = rgx_lk_hash(name);
    @int hashes = p_enum_names_h.data;
    int i = 0;
    while i < p_enum_names.len {
        if hashes[i] == h && p_text_eq(p_enum_names.get(i), name) {
            p_enum_values.put(i, v);
            end;
        }
        i = i + 1;
    }
    p_enum_names.add(name);
    p_enum_names_h.add(h);
    p_enum_values.add(v);
}

!!! ---- the rest of the chains ----
!!!
!!! One appender per node type a list in the tree is made of. They are all the
!!! same walk to the tail, and they stand together because every module appends to
!!! one of them.

@IntNode p_chain_int -> @IntNode head, @IntNode node {
    if head == null {
        return node;
    }
    @IntNode t = head;
    while t.next != null {
        t = t.next;
    }
    t.next = node;
    return head;
}

@StmtNode p_chain_stmt -> @StmtNode head, @StmtNode node {
    if head == null {
        return node;
    }
    @StmtNode t = head;
    while t.next != null {
        t = t.next;
    }
    t.next = node;
    return head;
}

@TArg p_chain_targ -> @TArg head, @TArg node {
    if head == null {
        return node;
    }
    @TArg t = head;
    while t.next != null {
        t = t.next;
    }
    t.next = node;
    return head;
}

!!! The elements of a pack binding are a chain of their own: they hang off
!!! `next_pack` so a pack element can carry a `next` of its own without the two
!!! lists mixing. A type argument list is chained by p_chain_targ().
@TArg p_chain_pack_targ -> @TArg head, @TArg node {
    if head == null {
        return node;
    }
    @TArg t = head;
    while t.next_pack != null {
        t = t.next_pack;
    }
    t.next_pack = node;
    return head;
}

@StructField p_chain_field -> @StructField head, @StructField node {
    if head == null {
        return node;
    }
    @StructField t = head;
    while t.next != null {
        t = t.next;
    }
    t.next = node;
    return head;
}

@StructMethod p_chain_method -> @StructMethod head, @StructMethod node {
    if head == null {
        return node;
    }
    @StructMethod t = head;
    while t.next != null {
        t = t.next;
    }
    t.next = node;
    return head;
}

@StructBapiMethod p_chain_bapi -> @StructBapiMethod head, @StructBapiMethod node {
    if head == null {
        return node;
    }
    @StructBapiMethod t = head;
    while t.next != null {
        t = t.next;
    }
    t.next = node;
    return head;
}


!!! ---- looking a token up by index ----
!!!
!!! the toolchain parser decides what a statement is by reading `tokens[pos + n]`, and
!!! the same questions come up here. A look past either end of the list answers
!!! with the first or the last token, so no caller has to guard its own walk.

Token p_tok -> int i {
    g_n_tok = g_n_tok + 1;
    if i < 0 {
        i = 0;
    }
    if i >= g_tokens.len {
        i = g_tokens.len - 1;
    }
    return g_tokens.get(i);
}

!!! The kind of a token `k` ahead, as an int.
!!!
!!! A loop condition must not call a function that answers a struct: the front end
!!! copies such a call into a temporary of the statement's own frame, and that
!!! temporary stands in front of the loop, so the condition would read the same
!!! value on every round and the loop would never end. A kind is an int, so this
!!! call is evaluated where it is written - and a token is asked for its kind in a
!!! condition far more often than for anything else.
int p_kind_at -> int k {
    return p_tok(k).tk;
}

!!! Whether a token's text is `lit`. A token keeps a span of the source rather than
!!! a copy of its spelling, so the comparison is over the span.
bool p_span_is -> Token t, str lit {
    return span_eq(t.start, t.stop, lit);
}

!!! Whether the token `k` ahead is spelled `lit`, for the same reason p_kind_at
!!! stands here: a loop condition cannot call a struct-returning function.
bool p_tok_is -> int k, str lit {
    return p_span_is(p_tok(k), lit);
}

!!! ---- parser: the program ----

!!! The statement starts that a resync may stop in front of: the toolchain parser uses
!!! the same list to step over the rest of a statement it could not parse.
bool p_at_stmt_boundary {
    if p_is(TK_EOF) {
        return true;
    }
    if p_is(TK_SEMI) || p_is(TK_RBRACE) {
        return true;
    }
    !!! A `{` that no statement has claimed starts a block of its own, and the
    !!! language has no such statement. It is a boundary all the same: p_sync used
    !!! to take it for the body it was recovering into and skip the whole `{ ... }`
    !!! silently, so a block written after another statement (`x = 1; { y = 2; }`)
    !!! lost its statements without a word, while the same block as the first
    !!! statement of a body was reported as meaningless.
    if p_is(TK_LBRACE) {
        return true;
    }
    if p_is(TK_IDENT) || p_is(TK_REF) || p_is(TK_AT) ||
       p_is(TK_PLUS_PLUS) || p_is(TK_MINUS_MINUS) {
        return true;
    }
    if p_is(TK_KEYWORD) {
        if p_name_is("type") || p_name_is("if") || p_name_is("while") ||
           p_name_is("do") || p_name_is("try") || p_name_is("throw") ||
           p_name_is("kind") || p_name_is("BLANG_API") || p_name_is("skip") ||
           p_name_is("continue") || p_name_is("local") || p_name_is("reload") ||
           p_name_is("stub") || p_name_is("package") || p_name_is("use") ||
           p_name_is("__get_built_in_func") || p_name_is("switch") ||
           p_name_is("return") || p_name_is("end") || p_name_is("back") ||
           p_name_is("rcode") || p_name_is("const") || p_name_is("static") ||
           p_name_is("utype") || p_name_is("introduce") ||
           p_name_is("attribute") || p_name_is("rule") || p_is_type() {
            return true;
        }
    }
    return false;
}

!!! Step over what is left of a statement that could not be parsed, so the next
!!! one starts where a statement may start.
void p_sync {
    while !p_is(TK_EOF) && !p_at_stmt_boundary() && !p_is(TK_LBRACE) {
        p_adv();
    }
    if p_is(TK_EOF) {
        end;
    }
    if p_is(TK_SEMI) {
        p_adv();
        end;
    }
    if p_is(TK_LBRACE) {
        p_skip_block();
    }
}

@StmtNode parse_program {
    !!! The enumerators of the whole file are collected first: an enum written below
    !!! a type that mentions it still has to be known while that type is read, and a
    !!! `#import` can put user code in front of the module that declares the enum.
    !!! the toolchain parser walks the tokens once for `kind` and throws the statements of
    !!! that walk away, errors included, so the real walk reports each one once.
    int saved_errors = p_errors;
    p_start();
    while !p_is(TK_EOF) {
        if p_is(TK_KEYWORD) && p_name_is("kind") {
            p_enum();
        } else {
            p_adv();
        }
    }
    p_errors = saved_errors;
    p_start();
    @StmtNode head = null;
    @StmtNode tail = null;
    while !p_is(TK_EOF) {
        int saved = p_pos;
        @StmtNode s = parse_stmt();
        if !p_at_stmt_boundary() {
            p_sync();
        }
        if p_pos == saved {
            !!! A statement that consumed nothing would be asked for again forever.
            p_adv();
        }
        if s == null {
            continue;
        }
        if head == null {
            head = s;
        } else {
            tail.next = s;
        }
        tail = s;
    }
    return head;
}

int count_stmts -> @StmtNode s {
    int n = 0;
    while s != null {
        n = n + 1;
        n = n + count_stmts(s.true_body);
        n = n + count_stmts(s.false_body);
        s = s.next;
    }
    return n;
}
