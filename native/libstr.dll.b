!~
 ~  native/libbstr.dll.b: the libbstr.dll functions blang code may call.
 ~
 ~  A linked DLL is described to the compiler by meta/libbstr.dll.bmeta, and that
 ~  file is generated from this one with `blang.exe native/libbstr.dll.b -m`.
 ~  The name has to end in `.b` after the DLL name because -m strips only the last
 ~  extension, so `libbstr.dll.b` is what produces `meta/libbstr.dll.bmeta`.
 ~
 ~  libbstr.dll is the compiler's own utility DLL (libbstr/libbstr): reading a file
 ~  whole, the color switch, and the layout every diagnostic of the compiler is
 ~  written with. the compiler prints its errors through these functions, so a
 ~  blang program that calls them prints exactly the same text, with the same
 ~  colors, instead of approximating the layout: that is why the self-hosted
 ~  compiler can carry the same diagnostics as the one it is ported from.
 ~
 ~  Every line below is a `stub`: a signature and nothing else. -m writes the
 ~  signatures into the .r, so this file declares what the DLL exports while
 ~  carrying no code of its own.
 ~
 ~  Types follow the same mapping the generated native/*.dll.b files use: a
 ~  `char*` is a str, a `void*` is @void, a pointer to a 32-bit integer is @int,
 ~  and a bool is a bool. `ux_read_file` returns a malloc'd buffer that the
 ~  caller gives back with `unlink`.
 ~!

!!! Read a whole file; writes its size through sz. The result is a heap block, so
!!! it has to be released with unlink.
stub str ux_read_file -> str path, @int sz;

!!! Turn the color codes on for the standard error (Windows virtual terminal
!!! processing). Returns 1 when the terminal took them.
stub int ux_color_init;

!!! Whether a diagnostic prints the source line and the caret below its header.
!!! Off, every layout function writes the header line alone - what a program that
!!! came in on standard input asks for, since no file can be quoted under it.
stub void ux_show_source -> bool on;

!!! The same question to the caller that lays out the blocks of a note itself.
stub bool ux_source_shown;

!!! Print one color to the standard error: "bold", "red", "bold_red", "green" or
!!! "reset". Does nothing unless ux_color_init turned the codes on.
stub void ux_color -> str which;

!!! The fatal error of a tool: "prog: fatal error: msg" and the line saying
!!! compilation stopped, colored, on the standard error.
stub void ux_fatal -> str prog, str msg;

!!! The layout of one warning, written into buf (buf_size bytes) and returned as
!!! its length.
stub int ux_warning_buf -> @char buf, int buf_size, str filename, int line, int col,
                           str msg, str src_line, int highlight_len;

!!! One error, printed straight to the standard error.
stub void ux_error -> str filename, int line, int col, str msg, str src_line,
                      int highlight_len, str suggestion, int suggestion_col, bool show_tilde;

!!! The layout of one error, written into buf and returned as its length: the
!!! "file:line:col: error: msg" line, the source line with the span highlighted,
!!! the caret line under it and the suggestion, if there is one.
stub int ux_error_buf -> @char buf, int buf_size, str filename, int line, int col,
                         str msg, str src_line, int highlight_len,
                         str suggestion, int suggestion_col, bool show_tilde;

!!! The same layout with the "note" label and color, for the note that follows an
!!! error.
stub int ux_note_buf -> @char buf, int buf_size, str filename, int line, int col,
                        str msg, str src_line, int highlight_len;
