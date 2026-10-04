#once
!~
 ~  bootstrap/frontend/Chinese/chinese_heads.b: the Chinese diagnostics, the
 ~  contract.
 ~
 ~  Every diagnostic the front end prints
 ~  - the driver's errors, the warnings, the notes and the preprocessor's own
 ~  messages - can be shown in Chinese. The switch is off by default: with no
 ~  `-Chinese` the compiler prints exactly the same English text as before.
 ~
 ~  The translation lives in two pieces:
 ~    * zh_msg()  translates a message body a diagnostic site produced.
 ~    * zh_word() / zh_pick() translate the category words and the diagnostic
 ~      format strings the front end builds itself - those the message body sits
 ~      in, so the source excerpt and the caret stay byte for byte identical.
 ~  A source snippet, a caret line or a suggestion is never translated, so the
 ~  column layout of every diagnostic is preserved.
 ~
 ~  A module that prints a diagnostic reads this file through
 ~  `#head "Chinese/chinese_heads"`, the way the toolchain reads chinese; the table
 ~  and the matcher stand in Chinese/chinese.b, which the two drivers #head once.
 ~!

!!! True when Chinese output was asked for (`-Chinese`, or BLANG_CHINESE=1 for a
!!! front end started directly, e.g. gn.exe).
stub bool zh_enabled;

!!! Turn Chinese output on or off explicitly. Once called, the environment is no
!!! longer consulted.
stub void zh_enable -> bool on;

!!! The category word: "error" -> 错误, "warning" -> 警告, "note" -> 提示,
!!! "fatal error" -> 错误. An unknown word is answered unchanged.
stub str zh_word -> str english;

!!! Pick the Chinese text when Chinese output is on, the English one otherwise.
stub str zh_pick -> str english, str chinese;

!!! Translate one message body (no prefix, no source line). Text no rule matches
!!! is answered unchanged, so a message added later still prints in English.
stub str zh_msg -> str msg;

!!! Replace the category words of a whole diagnostic text. Only the words of a
!!! `file:line:col: error:` style header are touched; messages, source lines,
!!! carets, suggestions and colour escapes stay as they are.
stub str zh_prefixes -> str text;

!!! A message with a `file: error: text` shape (the preprocessor's own errors).
stub str zh_file_error -> str filename, str msg;

!!! The driver's fatal error, in the layout ux_fatal() uses:
!!!   <prog>: 错误: <msg>
!!!   编译终止。
stub void zh_fatal -> str prog, str msg;
