#once
!~
 ~  bootstrap/frontend/preprocessor_heads.b: the preprocessor surface.
 ~
 ~  The records the passes hand each other and the declarations of the passes
 ~  themselves. The bodies are in preprocessor.b, next to the file they come from,
 ~  and preprocessor.b reads this module first, so a pass may call one that stands
 ~  below it (the newline pass calls the text walker, the condition reader calls the
 ~  macro table).
 ~!

#head "preproc_env"

!!! One `#replace` directive: the name it replaces, the text it stands for, where
!!! the directive itself was written (a diagnostic under replaced text points at it)
!!! and where the name stood where it was used.
type ReplaceInfo {
    str from;
    str to;
    str filename;
    int line_to;
    int col_to;
    str src_line;
    int line_from;
    int col_from;
    str src_line_from;
    @ReplaceInfo next;
};

!!! The (file, line) a preprocessed line came from, kept per preprocessed line the
!!! way the toolchain version keeps it in an unordered_map<int, pair<string,int>>.
!!!
!!! the toolchain answers a lookup and an insertion in constant time whatever the map
!!! holds. A chain of entries answers them by walking, and every pass over the text
!!! asks about its lines once per line, so a chain makes the preprocessor quadratic
!!! in the size of the file it reads: the compiler's own front end preprocesses to
!!! a megabyte of text, and that walk is where the seconds went.
!!!
!!! The three blocks hold the entries in ascending line order. Every caller writes
!!! its text line by line, so a new line goes on the end of the blocks and only a
!!! lookup by line costs anything, which is a binary search. The entries are kept
!!! in three parallel blocks rather than in one block of a struct: an element of a
!!! pointer field of a pointer struct is not a form the language reaches, while
!!! indexing a local pointer is (the same reason `vector.reserve` copies through
!!! locals).
type LineSrc {
    @int lines;      !!! the line numbers, ascending
    @str files;      !!! the file each of them came from
    @int srcs;       !!! the line of that file
    int len;         !!! how many entries there are
    int cap;         !!! how many the blocks hold
};

!!! The replacement an offset of the preprocessed text came from.
type RepPos {
    int off;
    @ReplaceInfo info;
    @RepPos next;
};

!!! One open conditional. The stack belongs to the compile rather than to a file, so
!!! an `#if` opened in one file can be closed in a file it includes (`#if` spanning
!!! a `#head`), and the "has no #endif" check happens once, when the whole walk is
!!! over. `file` and `line` are where it was opened, for that message.
type CondFrame {
    bool parent_active;
    bool active;
    bool taken;
    bool seen_else;
    int line;
    str file;
    @CondFrame next;
};

!!! preprocessor.b: the pass that folds `..` and `.` in a header path.
stub str preprocess_clean_path -> str p;

!!! preprocessor.b: the two text passes over a whole file.
stub str preprocess_replaces -> str src, str filename, @ReplaceInfo reps;
stub str preprocess_newlines -> str src, str filename, @LineSrc source_map;

!!! The helpers the passes build their text with.
stub str pp_last_name -> @NameList head;
stub @NameList pp_drop_last -> @NameList head;
stub str pp_trim_eol -> str s;
stub bool pp_alnum_char -> str s, int i;
stub void pp_emit -> str src, int from, int to, str sof_file, int sof_line, bool newline;

!!! The walk over the files calls itself, because a `#head` inside a file is read by
!!! the same pass one level down.
stub str preprocess_includes -> str src, str filename;

!!! The prescan of the `#export` blocks, one file at a time, and the stack its own
!!! copy of the `#if` family is kept on.
stub void pp_prescan_exports -> str src;

!!! preprocessor.b: the source map. The lexer looks a line up in it for every
!!! diagnostic it reports, so the two calls it needs are declared here.
stub @LineSrc pp_src_new;
stub int pp_src_find -> @LineSrc map, int line;
stub void pp_src_put -> @LineSrc map, int line, str file, int src_line;
stub @CondFrame pp_pc_push -> @CondFrame st, bool parent_active, bool active,
                              bool taken, int line;

!!! The `#if` expression reader: the descent from a value down through the
!!! operators, each level leaving its answer in pp_c_out.
stub bool pp_c_value;
stub bool pp_c_unary;
stub bool pp_c_mul;
stub bool pp_c_add;
stub bool pp_c_shift;
stub bool pp_c_relational;
stub bool pp_c_equality;
stub bool pp_c_bit_and;
stub bool pp_c_bit_xor;
stub bool pp_c_bit_or;
stub bool pp_c_and_expr;
stub bool pp_c_or_expr;
stub bool pp_c_parenthesized;
stub bool pp_c_macro_value -> str name;
stub bool pp_c_str_operand;
stub bool pp_c_has_macro -> str name;
