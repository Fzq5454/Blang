#once
!~
 ~  bootstrap/frontend/parser_block.b: the frontend/parser_block.
 ~
 ~  A block is `{ statement... }` or a single statement, and the two are the same
 ~  thing to the parser: a statement, and a list of them.
 ~
 ~  the toolchain version appends to the caller's list and hands back where the closing
 ~  brace stood. Here the block answers the chain of its statements, which is the
 ~  shape the tree has (see ast.b), and the caller links it: a body is the first
 ~  statement and each one holds the next.
 ~
 ~  Two things keep the walk honest, exactly as in the toolchain version: a statement that
 ~  consumed nothing is stepped over (`pos == saved`), so a parse that cannot make
 ~  progress still ends, and a statement that ended somewhere a statement may not
 ~  start is resynced from.
 ~!

#head "parser"

!!! Where the `}` of the block that was just read stood: the out_close_line and
!!! out_close_col `parse_block`, which the function reader keeps for the
!!! "must contain at least one return statement" message. Both stay 0 when the
!!! block is one statement with no braces, or when it ran into the end of the file,
!!! which is what the toolchain leaves them as well.
int p_block_end_line;
int p_block_end_col;

@StmtNode p_block {
    !!! A body is `{ statement... }` or one statement, and the toolchain falls back to the
    !!! single statement when no `{` stands where the body begins. That is what
    !!! makes `} else if <condition> {` read as an `else` whose body is another
    !!! `if`: the `else` takes the statement that follows it as its body.
    p_block_end_line = 0;
    p_block_end_col = 0;
    if !p_is(TK_LBRACE) {
        return parse_stmt();
    }
    !!! Where the `{` stood, for the note a body that is never closed points at it.
    int lbrace_line = p_cur.line;
    int lbrace_col = p_cur.col;
    p_adv();
    @StmtNode head = null;
    @StmtNode tail = null;
    while !p_is(TK_RBRACE) {
        if p_is(TK_EOF) {
            !!! the toolchain parser names the token it ran out on and points a note at the
            !!! '{' that was never closed, and the note stands with the other
            !!! collected ones under the errors of the file.
            p_error_at(p_prev.line, p_prev.col + (p_prev.stop - p_prev.start), 0,
                       "meaningless EOF; missing '}'");
            p_unmatched_brace_note(lbrace_line, lbrace_col);
            return head;
        }
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
    !!! The `}` the body ends on, taken before it is stepped over, which is the
    !!! position `parse_block` hands back.
    p_block_end_line = p_cur.line;
    p_block_end_col = p_cur.col;
    p_adv();
    return head;
}
