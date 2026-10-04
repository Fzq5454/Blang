#once
!~
 ~  bootstrap/frontend/rules.b: the built-in rules of `rule <NAME>(...)` — this implementation of
 ~
 ~  `rule` is a statement that asks the compiler to check something about the program
 ~  that no single declaration can say. Its arguments are expressions: a string, a
 ~  name, or a call of a rule helper (`not_pair`), which is what carries the report a
 ~  rule makes.
 ~
 ~  The names are built in and this file is the whole list of them, the way
 ~  attributes.b holds the attributes: a name that is not one of these is reported,
 ~  so a typo cannot be taken for a check the compiler does not have. A rule writes
 ~  nothing into the .r.
 ~!

#head "stdsrt"
#head "preproc_env"
#head "types"

!!! Which built-in rule a statement names.
int RULE_NONE = 0;
int RULE_PAIR = 1;
int RULE_MSG_EN_ZH = 2;
int RULE_WARN = 3;

int rule_find -> str name {
    if pe_eq(name, "pair") {
        !!! `pair(<report>, "<level>", "<message>", <function>, <function>, ...)`:
        !!! every call of the functions in the first half must have one in the second
        !!! half (`a1 b1 a2 b2` and `a1 a2 b1 b2` are both paired, `a1` alone is not),
        !!! and the first call left over is reported at its own position with the
        !!! level and the message the statement gives.
        return RULE_PAIR;
    }
    if pe_eq(name, "msg_en_zh") {
        !!! `msg_en_zh(<rule>, "<english>", "<chinese>")`: the check of the rule it
        !!! names - the rule statement written inside it, with its own level, message
        !!! and functions - reported with the English message, or with the Chinese one
        !!! when the compiler speaks Chinese.
        return RULE_MSG_EN_ZH;
    }
    if pe_eq(name, "warn") {
        !!! `warn(<rule>)`: the same check, reported as a warning of the -W-userdef
        !!! class. Nothing is reported until the switch is given, and the level the
        !!! rule inside wrote is not the level of the report: every one of them is a
        !!! warning, because a check a program writes for itself does not decide that
        !!! the build fails.
        return RULE_WARN;
    }
    return RULE_NONE;
}

!!! Whether a rule's report is a diagnostic of its own, which is what `warn` needs of
!!! the rule it runs: a rule that reports can be wrapped and reported again.
bool rule_reports -> int which {
    if which == RULE_PAIR || which == RULE_MSG_EN_ZH {
        return true;
    }
    return false;
}

!!! One `rule <NAME>(...)` of the source: the rule it names and its arguments as
!!! written. The parser reads the arguments, so they are a chain of expressions.
type RuleUse {
    str name;
    @ExprNode args;
    int nargs;
    int line;
    int col;
    int len;
    @RuleUse next;
};

!!! Every rule the source wrote, in the order it wrote them.
@RuleUse rule_uses;

void rule_use_add -> str name, @ExprNode args, int nargs, int line, int col, int len {
    RuleUse proto;
    @RuleUse u;
    malloc(@u, size proto);
    u.name = name;
    u.args = args;
    u.nargs = nargs;
    u.line = line;
    u.col = col;
    u.len = len;
    u.next = null;
    if rule_uses == null {
        rule_uses = u;
        end;
    }
    @RuleUse t = rule_uses;
    while t.next != null {
        t = t.next;
    }
    t.next = u;
}
