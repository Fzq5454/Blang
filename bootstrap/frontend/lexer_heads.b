#once
!~
 ~  bootstrap/frontend/lexer_heads.b: what lexer.b declares before it is read.
 ~
 ~  the declarations of frontend/lexer. The lexer's diagnostics call
 ~  each other and char_text stands below the messages that need it, so the surface
 ~  is stated here and lexer.b carries the bodies. Nothing else belongs in this
 ~  file: it is read by lexer.b, and by whatever needs to call into the lexer, so it
 ~  must not pull the lexer's own module in (that would be a cycle).
 ~!

!!! A lexical diagnostic, written where the scanner stands. It is the same libbstr
!!! call the parser's diagnostics go through, so a bad character in a literal and a
!!! bad statement read the same way, color included. the toolchain tokenizer collects its
!!! diagnostics and lets the driver print them; printing them here keeps the order
!!! and the positions exact.
stub void lex_error_at -> int line, int col, int len, str msg;

!!! The one-character text a message about a bad character needs.
stub str char_text -> char c;

!!! The banner a diagnostic carries when it names text from a `#head` file (the toolchain
!!! `head_file_banner` of frontend/lexer): `• From head file '<name>':`. The name
!!! is the file name alone, without its directory.
stub str lex_head_banner -> str f;
