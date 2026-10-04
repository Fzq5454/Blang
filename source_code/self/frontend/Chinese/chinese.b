#once
!~
 ~  bootstrap/frontend/Chinese/chinese.b: the Chinese diagnostics.
 ~
 ~  Every diagnostic the front end
 ~  prints - errors, warnings, notes and the driver's fatal errors - can be shown
 ~  in Chinese; the switch is off by default, so a run without `-Chinese` prints
 ~  exactly the English text it always did.
 ~
 ~  The translation is table driven, exactly as it is in the toolchain:
 ~
 ~    * `zh_table_fill` maps a whole English message to its Chinese text. `%s` /
 ~      `%d` / `%zu` stand for the parts that change, and `{1}`, `{2}`, ... name
 ~      those parts in the Chinese sentence, which may put them in another order
 ~      than the English one. The rules are tried longest match first, over and
 ~      over, which also covers a message the front end assembled from several
 ~      fragments.
 ~    * `zh_prefixes` translates the category word of a diagnostic header and
 ~      leaves everything else - message, source excerpt, caret, suggestion and
 ~      the colour escapes - untouched, so the column layout cannot shift.
 ~
 ~  A message that carries colour escapes between the quotes is matched as it
 ~  stands: a capture keeps whatever it matched, escapes included, so a bold
 ~  identifier survives the translation.
 ~!

#head "stdsrt"
#head "text_buf"
#head "vector"
#head "preproc_env"
#head "Chinese/chinese_heads"

!!! The environment reader of driver_common.b, which is included after the front
!!! end: `-Chinese` reaches gn.exe (and a front end started on its own) through
!!! BLANG_CHINESE.
stub str env_get -> str name;

!!! ---- one rule ----

type ZhRule {
    str en;
    str zh;
    @ZhRule next;
};

@ZhRule zh_rules;
@ZhRule zh_rules_tail;

!!! ---- the captures of a match ----
!!!
!!! A placeholder is capture number 1, 2, ... in the order it stands in the
!!! pattern, exactly as regex numbers its groups, and a capture is the byte
!!! range of the text it matched. `zh_cap_*` belongs to the match being tried and
!!! `zh_best_*` to the best match the pass has found so far; both are made long
!!! enough for the widest pattern of the table before the first match runs, which
!!! is what makes `put` below legal.
!!!
!!! They stand as globals and not as the answer of one call because the matcher
!!! is a recursion over the pattern: the captures of a match are written as the
!!! pattern is walked, and only the caller that owns the pass knows whether the
!!! match it just made is the best one.
vector(int) zh_cap_from;
vector(int) zh_cap_to;
vector(int) zh_best_from;
vector(int) zh_best_to;

!!! How many captures one match can hold: the widest rule of the table has four
!!! placeholders, and the room is kept generous so that a rule added later needs
!!! no second look.
int zh_cap_slots = 32;

!!! One rule at the end of the table. The order is the order of the table, and
!!! it is part of the data: the matcher takes the longest match and, when two
!!! rules match the same length, the one that stands first.
void zh_rule_add -> str en, str zh {
    ZhRule proto;
    @ZhRule r;
    malloc(@r, size proto);
    r.en = en;
    r.zh = zh;
    r.next = null;
    if zh_rules == null {
        zh_rules = r;
    } else {
        zh_rules_tail.next = r;
    }
    zh_rules_tail = r;
}

!!! The table itself stands below, after the machinery the rules are stored with;
!!! this is the forward declaration that lets the two meet.
stub void zh_table_fill;

bool zh_table_built;

void zh_table_ready {
    if zh_table_built {
        end;
    }
    zh_table_built = true;
    int k = 0;
    while k < zh_cap_slots {
        zh_cap_from.add(0);
        zh_cap_to.add(0);
        zh_best_from.add(0);
        zh_best_to.add(0);
        k = k + 1;
    }
    zh_table_fill();
}

!!! ---- the table ----
!!!
!!! Every rule, in the order frontend/Chinese/chinese has them. A longer,
!!! more specific message has to stand before a shorter rule that would also
!!! match part of it.
void zh_table_fill {
    !!! ---- prototype / definition mismatch ----
    zh_rule_add("parameter %d '%s' is '%s', but the prototype declares '%s'",
                "第 %d 个参数 '%s' 为 '%s'，但原型声明为 '%s'");
    zh_rule_add("parameter %d is '%s', but the prototype declares '%s'",
                "第 %d 个参数为 '%s'，但原型声明为 '%s'");
    zh_rule_add("return type is '%s', but the prototype declares '%s'",
                "返回类型为 '%s'，但原型声明为 '%s'");
    zh_rule_add("parameter %d '%s' declared here as '%s'",
                "第 %d 个参数 '%s' 在此处声明为 '%s'");
    zh_rule_add("parameter %d declared here as '%s'", "第 %d 个参数在此处声明为 '%s'");
    zh_rule_add("return type declared here as '%s'", "返回类型在此处声明为 '%s'");
    zh_rule_add("function '%s' used before declared", "函数 '%s' 在声明之前被使用");
    zh_rule_add("base type '%s' of type '%s' is not defined",
                "类型 '%s' 的基类型 '%s' 未定义");
    zh_rule_add("operator '%s' of type '%s' cannot be written with a value on its left",
                "类型 '%s' 的运算符 '%s' 左侧不能是值");
    zh_rule_add("meaningless token '%s' in BLANG_API", "BLANG_API 中无意义的记号 '%s'");

    !!! ---- packages ----
    zh_rule_add("'%s' is not imported", "'{1}' 未被导入");
    zh_rule_add("function '%s' is defined in package '%s'", "函数 '{1}' 定义在包 '{2}' 中");
    zh_rule_add("struct '%s' is defined in package '%s'", "结构体 '{1}' 定义在包 '{2}' 中");
    zh_rule_add("variable '%s' is defined in package '%s'", "变量 '{1}' 定义在包 '{2}' 中");
    zh_rule_add("'%s' is not declared in the global scope", "'{1}' 没有在全局作用域中声明");

    !!! ---- templates ----
    zh_rule_add("argument %s must be a constant %s expression", "第 {1} 个实参必须是常量 {2} 表达式");
    zh_rule_add("argument %s must be a type, got the template '%s'",
                "第 {1} 个实参必须是类型，但给的是模板 '{2}'");
    zh_rule_add("argument %s must be a type, got a value", "第 {1} 个实参必须是类型，但给的是值");
    zh_rule_add("argument %s must be an integer, got '%s'",
                "第 {1} 个实参必须是整数，但给的是 '{2}'");
    zh_rule_add("generic struct '%s' needs type arguments, e.g. '%s(int)'",
                "泛型结构体 '{1}' 需要类型实参，例如 '{2}(int)'");
    zh_rule_add("template '%s' needs a value for parameter '%s'; write %s(<value>)(...) to give it",
                "模板 '{1}' 的参数 '{2}' 需要一个值；请写成 {3}(<value>)(...) 来提供它");
    zh_rule_add("operator '%s' takes one parameter", "运算符 '{1}' 需要 1 个参数");
    zh_rule_add("operator '%s' takes %s parameter(s)", "运算符 '{1}' 需要 {2} 个参数");
    zh_rule_add("literal %s does not fit in '%s', the constructor parameter of '%s'",
                "字面量 {1} 放不进 '{2}'，它是结构体 '{3}' 的构造参数");

    !!! ---- arrays / index chains ----
    zh_rule_add("array '%s' has %s dimension(s), got %s index(es)",
                "数组 '{1}' 有 {2} 维，但给了 {3} 个下标");
    zh_rule_add("array field '%s' needs %s index(es), got %s",
                "数组字段 '{1}' 需要 {2} 个下标，实际给了 {3} 个");
    zh_rule_add("char array field '%s' is stored as a str and cannot be indexed element by element",
                "字符数组字段 '{1}' 以 str 存储，不能逐元素取下标");
    zh_rule_add("assignment through '[]' of an array element is not supported; read the element, change the copy and store it back",
                "不支持通过数组元素的 '[]' 赋值；请读出该元素、修改副本后再写回");

    !!! ---- constructors / conversions ----
    zh_rule_add("parameter %d of a converting constructor must be a scalar or the value of another type",
                "转换构造函数的第 %d 个参数必须是标量或其它类型的值");
    zh_rule_add("'%s' must be instantiated, e.g. '%s'", "'{1}' 必须实例化，例如 '{2}'");

    !!! ---- driver / scheduler messages ----
    zh_rule_add("Compilation completed.", "编译完成。");
    zh_rule_add("cannot write '%s'", "无法写入 '{1}'");
    zh_rule_add("cannot read '%s'", "无法读取 '{1}'");
    zh_rule_add("internal error", "内部错误");
    zh_rule_add("cannot write temp file '%s'", "无法写入临时文件 '{1}'");
    zh_rule_add("__badd needs a parameter name", "__badd 需要参数名");

    !!! ---- names, declarations ----
    zh_rule_add("undeclared identifier '%s'", "未声明的标识符 '%s'");
    zh_rule_add("undeclared function '%s'", "未声明的函数 '%s'");
    zh_rule_add("undeclared generic struct '%s'", "未声明的泛型结构体 '%s'");
    zh_rule_add("undeclared struct type '%s'", "未声明的结构体类型 '%s'");
    zh_rule_add("undeclared type '%s'", "未声明的类型 '%s'");
    zh_rule_add("unknown generic struct '%s'", "未知的泛型结构体 '%s'");
    zh_rule_add("unknown builtin function '%s'", "未知的内建函数 '%s'");
    zh_rule_add("unknown argument name '%s'", "未知的参数名 '%s'");
    zh_rule_add("redeclared to '%s'", "重复声明为 '%s'");
    zh_rule_add("redefinition of function '%s'", "函数 '%s' 重复定义");
    zh_rule_add("redefinition of method '%s'", "方法 '%s' 重复定义");
    zh_rule_add("previous definition is here", "前一个定义在这里");
    zh_rule_add("declared here", "在此处声明");
    zh_rule_add("declared here; function '%s' used before declared",
                "在此处声明；函数 '%s' 在声明之前被使用");
    zh_rule_add("type is declared here", "类型在这里声明");
    zh_rule_add("enum member '%s' redefined with different value",
                "枚举成员 '%s' 以不同的值重复定义");
    zh_rule_add("identifier '%s' never used", "标识符 '%s' 从未使用");
    zh_rule_add("function '%s' never used", "函数 '%s' 从未使用");
    zh_rule_add("comparison between '%s' and '%s'", "比较 '%s' 与 '%s'");
    zh_rule_add("operation between '%s' and '%s'", "对 '%s' 与 '%s' 进行运算");
    zh_rule_add("variable cannot reference itself in its own initializer",
                "变量不能在自身的初始化式中引用自己");
    zh_rule_add("did you mean '%s'?", "是否想写 '%s'？");
    zh_rule_add("named arguments are not supported for '%s'", "'%s' 不支持具名实参");
    zh_rule_add("cannot assign to const '%s'", "不能给常量 '%s' 赋值");
    zh_rule_add("cannot modify const '%s'", "不能修改常量 '%s'");
    zh_rule_add("cannot bind 'ref' to const '%s'", "不能用 'ref' 绑定常量 '%s'");
    zh_rule_add("const '%s' must be initialized", "常量 '%s' 必须初始化");
    zh_rule_add("const is not supported for a struct field", "结构体字段不支持 const");
    zh_rule_add("declared const here", "此处声明为常量");
    zh_rule_add("static is not supported for a function", "函数不支持 static");
    zh_rule_add("static is not supported for a struct field", "结构体字段不支持 static");
    zh_rule_add("static is only allowed for a local variable, not '%s'",
                "static 只能用于函数内的局部变量，不能用于 '%s'");
    zh_rule_add("static is only supported for a scalar variable, not '%s'",
                "static 只支持标量变量，不支持 '%s'");
    zh_rule_add("static is only supported for a scalar parameter, not '%s'",
                "static 只支持标量参数，不支持 '%s'");
    zh_rule_add("utype is only for 'int', 'longlong' or 'char'",
                "utype 只能用于 'int'、'longlong' 或 'char'");
    zh_rule_add("utype is only for 'int' or 'longlong' on a struct field",
                "结构体字段上的 utype 只能用于 'int' 或 'longlong'");
    zh_rule_add("macro '%s' expands to '%s'", "宏 '%s' 展开为 '%s'");

    !!! ---- struct / type members ----
    zh_rule_add("struct '%s' has no member '%s'", "结构体 '%s' 没有成员 '%s'");
    zh_rule_add("type '%s' has no member '%s'", "类型 '%s' 没有成员 '%s'");
    zh_rule_add("super has no member '%s'", "父类型没有成员 '%s'");
    zh_rule_add("type '%s' has no method '%s'", "类型 '%s' 没有方法 '%s'");
    zh_rule_add("member '%s' is private in type '%s'", "成员 '%s' 在类型 '%s' 中是私有的");
    zh_rule_add("member '%s' is protected in type '%s'", "成员 '%s' 在类型 '%s' 中是受保护的");
    zh_rule_add("super has no method '%s'", "父类型没有方法 '%s'");
    zh_rule_add("type '%s' has no operator '%s'", "类型 '%s' 没有运算符 '%s'");
    zh_rule_add("no matching 'operator%s' for '%s' and '%s'",
                "没有匹配的 'operator%s'：'{2}' 和 '{3}'");
    zh_rule_add("no matching 'operator%s' for '%s'", "没有匹配的 'operator%s'：'{2}'");
    zh_rule_add("'%s' declares %d operator overloads, they are:",
                "'%s' 声明了 %d 个运算符重载，分别为：");
    zh_rule_add("'%s' declares one operator overload:", "'%s' 声明了 1 个运算符重载：");
    zh_rule_add("'%s' declares no operator overloads", "'%s' 没有声明任何运算符重载");
    zh_rule_add("it is 'operator %s'", "它是 'operator %s'");
    zh_rule_add("it takes %d argument(s), this use needs %d", "它收 %d 个参数，这里需要 %d 个");
    zh_rule_add("it expects '%s', got '%s'", "它需要 '%s'，实际为 '%s'");
    zh_rule_add("it does not accept this use", "它不接受这种用法");
    zh_rule_add("type '%s' has no conversion to '%s'", "类型 '%s' 不能转换为 '%s'");
    zh_rule_add("type '%s' has no conversion for an 'any' argument",
                "类型 '%s' 不能转换为 'any' 参数");
    zh_rule_add("member '%s' of struct '%s' is not a struct",
                "结构体 '{2}' 的成员 '{1}' 不是结构体");
    zh_rule_add("element is not a struct", "元素不是结构体");
    zh_rule_add("'%s' is not a struct", "'%s' 不是结构体");
    zh_rule_add("'%s' is not an array", "'%s' 不是数组");
    zh_rule_add("'%s' is not defined", "'%s' 未定义");
    zh_rule_add("'%s' is stored as a str and cannot be indexed element by element",
                "'%s' 以 str 存储，不能逐元素取下标");
    zh_rule_add("struct cannot contain itself by value", "结构体不能按值包含自身");
    zh_rule_add("inheritance cycle detected involving type '%s'", "类型 '%s' 存在继承环");
    zh_rule_add("base type '%s'", "基类型 '%s'");
    zh_rule_add("'%s' is already declared for type '%s'", "类型 '%s' 已经声明了 '%s'");

    !!! ---- type mismatch and argument checks ----
    zh_rule_add("return type mismatch", "返回类型不匹配");
    zh_rule_add("type mismatch", "类型不匹配");
    zh_rule_add("argument %zu missing '%s', got '%s'", "第 {1} 个参数需要 '{2}'，实际为 '{3}'");
    zh_rule_add("argument %d missing '%s', got '%s'", "第 {1} 个参数需要 '{2}'，实际为 '{3}'");
    zh_rule_add("argument '%s' specified more than once", "参数 '%s' 被指定了多次");
    zh_rule_add("argument '%s' must be a constant %s expression", "参数 '%s' 必须是常量 %s 表达式");
    zh_rule_add("'%s' must be a constant integer expression", "'%s' 必须是常量整数表达式");
    zh_rule_add("'%s' must be a constant expression", "'%s' 必须是常量表达式");
    zh_rule_add("default argument must be a constant expression", "默认参数必须是常量表达式");
    zh_rule_add("value for parameter '%s' must be a constant %s expression",
                "参数 '%s' 的值必须是常量 %s 表达式");
    zh_rule_add("parameter without a default value may not follow a parameter with one",
                "没有默认值的参数不能跟在有默认值的参数之后");
    zh_rule_add("positional argument after named argument", "位置参数不能出现在具名参数之后");
    zh_rule_add("function '%s' needs at least %zu argument(s), got %zu",
                "函数 '%s' 至少需要 %zu 个参数，实际给了 %zu 个");
    zh_rule_add("function '%s' needs %zu argument(s), got %zu",
                "函数 '%s' 需要 %zu 个参数，实际给了 %zu 个");
    zh_rule_add("no matching overload for function '%s'", "函数 '%s' 没有匹配的重载版本");
    zh_rule_add("ambiguous call to overloaded function '%s'", "重载函数 '%s' 的调用有歧义");
    zh_rule_add("no prototype of method '%s' in type '%s'",
                "类型 '{2}' 中没有方法 '{1}' 的原型声明");
    zh_rule_add("no prototype of function '%s'", "函数 '%s' 没有原型声明");
    zh_rule_add("no prototype of method '%s'", "方法 '%s' 没有原型声明");
    zh_rule_add("template '%s' needs %zu type argument(s), got %zu",
                "模板 '%s' 需要 %zu 个类型实参，实际给了 %zu 个");
    zh_rule_add("generic struct '%s' needs %zu type argument(s), got %zu",
                "泛型结构体 '%s' 需要 %zu 个类型实参，实际给了 %zu 个");
    zh_rule_add("template '%s' needs a type for parameter '%s'",
                "模板 '%s' 的参数 '%s' 需要一个类型");
    zh_rule_add("template '%s' needs a value for parameter '%s'",
                "模板 '%s' 的参数 '%s' 需要一个值");
    zh_rule_add("template '%s' needs a template name for parameter '%s'",
                "模板 '%s' 的参数 '%s' 需要一个模板名");
    zh_rule_add("cannot deduce type argument '%s' of template '%s'",
                "无法推导模板 '%s' 的类型实参 '%s'");
    zh_rule_add("cannot deduce type argument", "无法推导类型实参");
    zh_rule_add("must be a type, got the template '%s'", "需要一个类型，但给的是模板 '%s'");
    zh_rule_add("must be a type, got a value", "需要一个类型，但给的是值");
    zh_rule_add("must be a template name", "需要一个模板名");
    zh_rule_add("must be an integer, got '%s'", "需要一个整数，但给的是 '%s'");
    zh_rule_add("'%s' must be instantiated, e.g. '%s'", "'%s' 必须实例化，例如 '%s'");
    zh_rule_add("'%s' needs type arguments, e.g. '%s'", "'%s' 需要类型实参，例如 '%s'");
    zh_rule_add("malformed template argument list in type '%s'",
                "类型 '%s' 的模板实参列表格式错误");
    zh_rule_add("missing ')' in template argument list", "模板实参列表中缺少 ')'");
    zh_rule_add("missing ')' after template type arguments", "模板类型实参之后缺少 ')'");
    zh_rule_add("missing '>' after builtin name", "内建函数名之后缺少 '>'");
    zh_rule_add("missing '<' after __get_built_in_func", "__get_built_in_func 之后缺少 '<'");
    zh_rule_add("missing builtin function name inside <...>", "<...> 中缺少内建函数名");
    zh_rule_add("missing template parameter name after TEMPLATE", "TEMPLATE 之后缺少模板参数名");
    zh_rule_add("missing type parameter name after TYPENAME", "TYPENAME 之后缺少类型参数名");
    zh_rule_add("missing '{' after introduce type parameters",
                "introduce 的类型参数之后缺少 '{'");

    !!! ---- assignment / initialization ----
    zh_rule_add("cannot assign a '%s' value to field '%s' of type '%s'",
                "不能把 '%s' 类型的值赋给字段 '%s'（类型为 '%s'）");
    zh_rule_add("cannot assign a '%s' value to '%s'", "不能把 '%s' 类型的值赋给 '%s'");
    zh_rule_add("cannot assign an initializer list to array field '%s'",
                "不能把初始化列表赋给数组字段 '%s'");
    zh_rule_add("cannot initialize '%s' with a '%s' value", "不能用 '%s' 类型的值初始化 '%s'");
    zh_rule_add("cannot initialize '%s' with a value of type '%s'",
                "不能用 '%s' 类型的值初始化 '%s'");
    zh_rule_add("initializer list cannot be used with the array field '%s'",
                "数组字段 '%s' 不能使用初始化列表");
    zh_rule_add("nested initializer is not supported here", "这里不支持嵌套初始化");
    zh_rule_add("a converting constructor from '%s'", "从 '%s' 的转换构造函数");
    zh_rule_add("cannot return a '%s' value from a function returning '%s'",
                "不能从返回 '{2}' 的函数中返回 '{1}' 类型的值");
    zh_rule_add("'%s' value from a function returning '%s'",
                "'{1}' 类型的值，而函数返回 '{2}'");
    zh_rule_add("'%s' must contain at least one return statement",
                "'%s' 至少要有一条 return 语句");
    zh_rule_add("function '%s' must contain at least one return statement",
                "函数 '%s' 至少要有一条 return 语句");
    zh_rule_add("return statement in void function is not allowed",
                "void 函数中不允许 return 语句");
    zh_rule_add("'%s' must return '%s'", "'%s' 必须返回 '%s'");
    zh_rule_add("'%s' must return 'int' or 'bool'", "'%s' 必须返回 'int' 或 'bool'");
    zh_rule_add("'%s' takes %s", "'%s' 接受 %s");
    zh_rule_add("'%s' needs %s", "'%s' 需要 %s");
    zh_rule_add("array size of field '%s'", "字段 '%s' 的数组大小");
    zh_rule_add("array field '%s'", "数组字段 '%s'");
    zh_rule_add("char array field '%s'", "字符数组字段 '%s'");
    zh_rule_add("array size required inside '[]'", "'[]' 中需要数组大小");
    zh_rule_add("index required inside '[]'", "'[]' 中需要下标");
    zh_rule_add("assignment through '[]' of an array element is not supported",
                "不支持通过数组元素的 '[]' 赋值");
    zh_rule_add("'; assign its elements one by one", "；请逐个元素赋值");
    zh_rule_add("'; convert it explicitly", "；请显式转换");
    zh_rule_add("element access needs an array field", "元素访问需要一个数组字段");
    zh_rule_add("@ can only be applied to a variable or array element",
                "@ 只能作用于变量或数组元素");
    zh_rule_add("++/-- can only be applied to a variable", "++/-- 只能作用于变量");

    !!! ---- operators / methods ----
    zh_rule_add("expected an overloadable operator symbol after 'operator'",
                "'operator' 之后需要可重载的运算符");
    zh_rule_add("expected a method or operator declaration after 'reload'",
                "'reload' 之后需要方法或运算符声明");
    zh_rule_add("missing return type before 'operator'", "'operator' 之前缺少返回类型");
    zh_rule_add("missing '{' after operator declaration", "运算符声明之后缺少 '{'");
    zh_rule_add("declare 'int operator ", "声明 'int operator ");
    zh_rule_add("' cannot be written with a value on its left", "' 的左侧不能是值");
    zh_rule_add("destruct cannot have parameters", "析构函数不能有参数");
    zh_rule_add("missing destruct name", "缺少析构函数名");
    zh_rule_add("missing init name", "缺少构造函数名");

    !!! ---- parser expectations ----
    zh_rule_add("expected ','", "需要 ','");
    zh_rule_add("expected ';'", "需要 ';'");
    zh_rule_add("expected '%s', got '%s'", "需要 '%s'，实际为 '%s'");
    zh_rule_add("expected an expression", "需要一个表达式");
    zh_rule_add("expected a type", "需要一个类型");
    zh_rule_add("expected a statement", "需要一条语句");
    zh_rule_add("expected a method or operator declaration", "需要方法或运算符声明");
    zh_rule_add("expected a variable name", "需要一个变量名");
    zh_rule_add("expected a function name", "需要一个函数名");
    zh_rule_add("expected a type name", "需要一个类型名");
    zh_rule_add("expected a parameter name", "需要一个参数名");
    zh_rule_add("expected a type after '@'", "需要 '@' 之后的类型");
    zh_rule_add("expected a type after 'ref'", "需要 'ref' 之后的类型");
    zh_rule_add("expected a value", "需要一个值");
    zh_rule_add("expected a string", "需要一个字符串");
    zh_rule_add("expected a constant", "需要一个常量");
    zh_rule_add("expected a method name", "需要一个方法名");
    zh_rule_add("expected a field name", "需要一个字段名");
    zh_rule_add("expected a struct name", "需要一个结构体名");
    zh_rule_add("expected a member name", "需要一个成员名");
    zh_rule_add("expected a template name", "需要一个模板名");
    zh_rule_add("expected a lambda", "需要一个 lambda");
    zh_rule_add("expected a block", "需要一个语句块");
    zh_rule_add("expected a condition", "需要一个条件表达式");
    zh_rule_add("expected a body", "需要函数体");
    zh_rule_add("expected a type argument", "需要一个类型实参");
    zh_rule_add("expected a value argument", "需要一个值实参");
    zh_rule_add("expected a template argument", "需要一个模板实参");
    zh_rule_add("expected a package name", "需要一个包名");
    zh_rule_add("expected an alias name", "需要一个别名");
    zh_rule_add("expected an enum name", "需要一个枚举名");
    zh_rule_add("expected an enum member name", "需要一个枚举成员名");

    zh_rule_add("expected an overloadable operator symbol", "需要一个可重载的运算符");
    zh_rule_add("expected an operator symbol", "需要一个运算符");
    zh_rule_add("expected a method or operator", "需要方法或运算符");
    zh_rule_add("expected a destructor name", "需要一个析构函数名");
    zh_rule_add("expected a constructor name", "需要一个构造函数名");
    zh_rule_add("expected a pointer type", "需要一个指针类型");
    zh_rule_add("expected a variable or array element", "需要变量或数组元素");
    zh_rule_add("expected a numeric value", "需要一个数值");
    zh_rule_add("expected an integer value", "需要一个整数值");
    zh_rule_add("expected an integer", "需要一个整数");
    zh_rule_add("expected a class or struct", "需要一个类型或结构体");
    zh_rule_add("expected a name", "需要一个名称");
    zh_rule_add("expected 'THEN'", "需要 'THEN'");
    zh_rule_add("expected ')'", "需要 ')'");
    zh_rule_add("expected ',' or ']'", "需要 ',' 或 ']'");
    zh_rule_add("expected CASE or UNMATCH, got '%s'", "需要 CASE 或 UNMATCH，实际为 '%s'");
    zh_rule_add("expected function name after CLOSURE", "CLOSURE 之后需要函数名");
    zh_rule_add("expected function name", "需要函数名");
    zh_rule_add("expected variable name after DREF", "DREF 之后需要变量名");
    zh_rule_add("expected variable name after RELEASE", "RELEASE 之后需要变量名");
    zh_rule_add("expected quoted builtin name", "需要带引号的内建函数名");
    zh_rule_add("expected quoted builtin name after BSPREAD",
                "BSPREAD 之后需要带引号的内建函数名");
    zh_rule_add("expected ','", "需要 ','");
    zh_rule_add("expected ']'", "需要 ']'");
    zh_rule_add("expected ':'", "需要 ':'");
    zh_rule_add("expected '(' after SWITCH", "SWITCH 之后需要 '('");
    zh_rule_add("expected '('", "需要 '('");
    zh_rule_add("expected '{'", "需要 '{'");
    zh_rule_add("expected '}'", "需要 '}'");
    zh_rule_add("expected ';' after", "之后需要 ';'");
    zh_rule_add("expected '='", "需要 '='");
    zh_rule_add("expected 'while'", "需要 'while'");
    zh_rule_add("expected 'case' or 'unmatch'", "需要 'case' 或 'unmatch'");
    zh_rule_add("expected EOF", "需要文件结束");
    zh_rule_add("compilation terminated.", "编译终止。");

    !!! ---- "missing X" ----
    zh_rule_add("missing ';' after struct definition", "结构体定义之后缺少 ';'");
    zh_rule_add("missing ';' after stub declaration", "stub 声明之后缺少 ';'");
    zh_rule_add("missing ';' after return", "return 之后缺少 ';'");
    zh_rule_add("missing ';' after skip", "skip 之后缺少 ';'");
    zh_rule_add("missing ';' after end", "end 之后缺少 ';'");
    zh_rule_add("missing ';' after back", "back 之后缺少 ';'");
    zh_rule_add("missing ';' after continue", "continue 之后缺少 ';'");
    zh_rule_add("missing ';' after use", "use 之后缺少 ';'");
    zh_rule_add("missing ';'", "缺少 ';'");
    zh_rule_add("missing '(' after '=>'", "'=>' 之后缺少 '('");
    zh_rule_add("missing '{' after lambda parameters", "lambda 参数之后缺少 '{'");
    zh_rule_add("missing ',' or ']' in lambda parameters", "lambda 参数中缺少 ',' 或 ']'");
    zh_rule_add("missing parameter name in lambda", "lambda 中缺少参数名");
    zh_rule_add("missing '{' after package name", "包名之后缺少 '{'");
    zh_rule_add("missing '}' at the end of the package", "包的结尾缺少 '}'");
    zh_rule_add("missing 'while' after do block", "do 块之后缺少 'while'");
    zh_rule_add("missing '++' or '--'", "缺少 '++' 或 '--'");
    zh_rule_add("missing alias name after >", "'>' 之后缺少别名");
    zh_rule_add("missing API function name", "缺少 API 函数名");
    zh_rule_add("missing base type name after ':'", "':' 之后缺少基类型名");
    zh_rule_add("missing builtin function name", "缺少内建函数名");
    zh_rule_add("missing enum member name", "缺少枚举成员名");
    zh_rule_add("missing enum name", "缺少枚举名");
    zh_rule_add("missing expression", "缺少表达式");
    zh_rule_add("missing field type or 'function'", "缺少字段类型或 'function'");
    zh_rule_add("missing function name", "缺少函数名");
    zh_rule_add("missing identifier after '::'", "'::' 之后缺少标识符");
    zh_rule_add("missing integer value after '-'", "'-' 之后缺少整数值");
    zh_rule_add("missing integer value after '='", "'=' 之后缺少整数值");
    zh_rule_add("missing object name after '::'", "'::' 之后缺少对象名");
    zh_rule_add("missing package name", "缺少包名");
    zh_rule_add("missing parameter name", "缺少参数名");
    zh_rule_add("missing return type before", "之前缺少返回类型");
    zh_rule_add("missing string literal after 'rcode'", "'rcode' 之后缺少字符串字面量");
    zh_rule_add("missing string literal", "缺少字符串字面量");
    zh_rule_add("missing struct name", "缺少结构体名");
    zh_rule_add("missing type after '@'", "'@' 之后缺少类型");
    zh_rule_add("missing type after 'ref'", "'ref' 之后缺少类型");
    zh_rule_add("missing type or variable after 'size'", "'size' 之后缺少类型或变量");
    zh_rule_add("missing array name after 'count'", "'count' 之后缺少数组名");
    zh_rule_add("missing value parameter name", "缺少值参数名");
    zh_rule_add("missing variable name", "缺少变量名");
    zh_rule_add("missing type", "缺少类型");
    zh_rule_add("missing ')'", "缺少 ')'");
    zh_rule_add("missing ']'", "缺少 ']'");
    zh_rule_add("missing '}'", "缺少 '}'");
    zh_rule_add("missing '{'", "缺少 '{'");
    zh_rule_add("missing ':'", "缺少 ':'");
    zh_rule_add("missing '='", "缺少 '='");
    zh_rule_add("missing 'case' or 'unmatch'", "缺少 'case' 或 'unmatch'");
    zh_rule_add("missing ';' after", "之后缺少 ';'");

    !!! ---- misc parse errors ----
    zh_rule_add("invalid operator '%s'", "无效的运算符 '%s'");
    zh_rule_add("invalid assignment", "无效的赋值");
    !!! `attribute <object>: <NAME>`: the built-in attributes and what the statement
    !!! says when it cannot be read or points at nothing.
    zh_rule_add("unknown attribute '%s'", "未知的属性 '%s'");
    zh_rule_add("missing object name after 'attribute'", "'attribute' 之后缺少对象名");
    zh_rule_add("missing ':' after the object of 'attribute'", "'attribute' 的对象之后缺少 ':'");
    zh_rule_add("missing attribute name after ':'", "':' 之后缺少属性名");
    zh_rule_add("attribute names an object that is not declared: '%s'", "属性指向的对象没有声明：'%s'");
    zh_rule_add("a type attribute cannot be used on a struct '%s'", "类型属性不能用在结构体 '%s' 上");
    zh_rule_add("type attribute '%s' does not match the declared type of '%s'", "类型属性 '%s' 与 '%s' 的声明类型不符");
    zh_rule_add("conflicting type attributes on '%s'", "'%s' 上的类型属性互相冲突");
    zh_rule_add("'%s' is declared after this attribute", "'%s' 在这条属性之后才声明");
    zh_rule_add("the receiver of field '%s' has no known type", "字段 '%s' 的接收者类型未知");
    zh_rule_add("stub is only for a method declaration", "'stub' 只能用于方法声明");
    zh_rule_add("struct '%s' has no method '%s'", "结构体 '%s' 没有方法 '%s'");
    zh_rule_add("method '%s.%s' already has a body", "方法 '%s.%s' 已经有函数体");
    zh_rule_add("the definition of '%s.%s' does not match its declaration", "'%s.%s' 的定义与声明不一致");
    !!! `rule <NAME>(...)`: the built-in rules and what the statement says when it
    !!! cannot be read or names something the compiler does not have.
    zh_rule_add("unknown rule '%s'", "未知的规则 '%s'");
    zh_rule_add("missing rule name after 'rule'", "'rule' 之后缺少规则名");
    zh_rule_add("missing '(' after the rule name", "规则名之后缺少 '('");
    zh_rule_add("rule 'pair' needs a report, a level, a message and two functions", "'pair' 规则需要一份报告、一个级别、一条信息和两个函数");
    zh_rule_add("rule 'msg_en_zh' needs a rule and two messages", "'msg_en_zh' 规则需要一条规则和两条信息");
    zh_rule_add("the first argument of 'msg_en_zh' is the rule to check with", "'msg_en_zh' 的第一个参数是用来检查的规则");
    zh_rule_add("the messages of 'msg_en_zh' are two strings", "'msg_en_zh' 的两条信息是字符串");
    zh_rule_add("rule 'warn' needs a rule", "'warn' 规则需要一条规则");
    zh_rule_add("the first argument of 'warn' is the rule to check with", "'warn' 的第一个参数是用来检查的规则");
    zh_rule_add("the first argument of 'pair' is the report of 'not_pair(...)'", "'pair' 的第一个参数应是 'not_pair(...)' 的报告");
    zh_rule_add("the level of a rule is \"error\", \"warning\" or \"note\"", "规则的级别是 \"error\"、\"warning\" 或 \"note\"");
    zh_rule_add("the message of a rule is a string", "规则的信息是一个字符串");
    zh_rule_add("the objects a rule checks are written as plain names", "规则检查的对象要写成普通名字");
    zh_rule_add("'%s' is not declared before this rule", "'%s' 没有在这条规则之前声明");
    zh_rule_add("'%s' is declared after this rule", "'%s' 在这条规则之后才声明");
    zh_rule_add("the functions of 'pair' are read as two halves of the same size", "'pair' 的函数按等长的两半读取");
    zh_rule_add("an assignment written as a value must target a variable", "作为值书写的赋值必须以变量为目标");
    zh_rule_add("cannot write an assignment of type '%s' as a value", "无法把 '%s' 类型的赋值当作值使用");
    zh_rule_add("meaningless character '%s'", "无意义的字符 '%s'");
    zh_rule_add("unterminated string", "字符串缺少收尾的双引号");
    zh_rule_add("unterminated char literal", "字符字面量没有收尾的单引号");
    zh_rule_add("meaningless EOF; missing '}'", "文件提前结束；缺少 '}'");
    zh_rule_add("meaningless '%s'; missing '->' or '{'", "'%s' 无意义；缺少 '->' 或 '{'");
    zh_rule_add("meaningless token '%s'", "无意义的记号 '%s'");
    zh_rule_add("meaningless '%s'", "'%s' 无意义");
    zh_rule_add("meaningless ", "无意义的 ");
    zh_rule_add("'end' is only allowed in void functions", "'end' 只能用在 void 函数中");
    zh_rule_add("'skip' outside of a loop", "'skip' 不在循环内");
    zh_rule_add("expected 'exception' after the try block", "try 块之后需要 'exception'");
    zh_rule_add("expected '(' after 'exception'", "'exception' 之后需要 '('");
    zh_rule_add("expected the name of the exception variable", "需要异常变量的名字");
    zh_rule_add("expected ')' after the exception variable", "异常变量之后需要 ')'");
    zh_rule_add("missing ';' after throw", "throw 之后缺少 ';'");
    zh_rule_add("throw needs an exception code, got '%s'", "throw 需要一个异常码，但给的是 '%s'");
    zh_rule_add("'void' is not valid for variable declaration", "'void' 不能用于变量声明");
    zh_rule_add("stub function must not have a body", "stub 函数不能有函数体");
    zh_rule_add("destruct cannot have parameters", "析构函数不能有参数");
    zh_rule_add("unmatched this '('", "此处未匹配的 '('");
    zh_rule_add("unmatched this '{'", "此处未匹配的 '{'");
    zh_rule_add("In function", "在函数");
    zh_rule_add("From head file", "来自头文件");

    !!! ---- preprocessor ----
    zh_rule_add("circular include: '%s'", "循环包含：'%s'");
    zh_rule_add("cannot open head file '%s'", "无法打开头文件 '%s'");
    zh_rule_add("#export name must start with '*'", "#export 名称必须以 '*' 开头");
    zh_rule_add("#import name must start with '*'", "#import 名称必须以 '*' 开头");
    zh_rule_add("#import missing '['", "#import 缺少 '['");
    zh_rule_add("#import missing ']'", "#import 缺少 ']'");
    zh_rule_add("mismatched #export '%s', expecting '#export %s'",
                "#export '%s' 不匹配，期望 '#export %s'");
    zh_rule_add("no such file or directory", "没有这个文件或目录");
    zh_rule_add("file format not recognized: ", "无法识别的文件格式： ");
    zh_rule_add("unrecognized command-line option '", "无法识别的命令行选项 '");
    zh_rule_add("no input file", "没有输入文件");
    zh_rule_add("-R and -I cannot be used together", "-R 与 -I 不能同时使用");
    zh_rule_add("-R is meaningless for .r input files", "对 .r 输入文件来说 -R 没有意义");
    zh_rule_add("-I is meaningless for .r input files", "对 .r 输入文件来说 -I 没有意义");
}

!!! ---- walking the pattern of a rule ----
!!!
!!! the toolchain turns every `en` into a regex once and keeps the compiled list,
!!! because building a regular expression costs far more than matching with it.
!!! Reading the pattern here is a scan of the bytes of `en`, no more work than one
!!! `%` test per byte, so the pattern is walked where it is used and the table
!!! stays the only copy of it.
!!!
!!! A placeholder is lazy - `(.*?)` - and takes the shortest run that lets the
!!! rest of the pattern match, which is the order regex backtracks in. The
!!! last placeholder of a pattern is greedy - `(.*)` - because a lazy one there
!!! would match empty and leave the tail of the message behind. A placeholder
!!! never crosses the end of the line, which is what `.` means to regex.

!!! Whether the byte after a `%` starts a placeholder. `%zu` is one placeholder
!!! written with two letters, so both are part of it.
bool zh_is_ph -> char c {
    if c == 's' || c == 'd' || c == 'c' || c == 'f' || c == 'z' || c == 'u' {
        return true;
    }
    return false;
}

!!! How many bytes the placeholder beginning at `en[ei]` takes: 3 for `%zu`, 2
!!! for every other one.
int zh_ph_len -> str en, int ei {
    if en[ei + 1] == 'z' && en[ei + 2] == 'u' {
        return 3;
    }
    return 2;
}

!!! How many placeholders a pattern holds, which is how many captures a match of
!!! it fills.
int zh_count_caps -> str en {
    int n = 0;
    int i = 0;
    while en[i] != (char)0 {
        if en[i] == '%' && zh_is_ph(en[i + 1]) {
            n = n + 1;
            i = i + zh_ph_len(en, i);
        } else {
            i = i + 1;
        }
    }
    return n;
}

!!! The end of the line `text` stands on at `from`: where a placeholder stops.
int zh_hole_end -> str text, int from {
    int i = from;
    while text[i] != (char)0 && text[i] != '\n' && text[i] != '\r' {
        i = i + 1;
    }
    return i;
}

!!! Match `en` from `ei` against `text` at `ti`: how many bytes of the text the
!!! pattern takes, or -1 when it cannot match there. `cap` is the number of the
!!! next placeholder, so a pattern of `k` placeholders is a match with the
!!! captures 1..k.
int zh_match -> str en, int ei, str text, int ti, int cap {
    if en[ei] == (char)0 {
        return 0;
    }
    !!! The room the captures are written in. A pattern wider than it is not one
    !!! this table holds, and refusing to match is the safe answer: writing past
    !!! the room would corrupt whatever stands next.
    if cap > zh_cap_slots {
        return -1;
    }
    if en[ei] == '%' && zh_is_ph(en[ei + 1]) {
        int plen = zh_ph_len(en, ei);
        if en[ei + plen] == (char)0 {
            !!! The last thing in the pattern: everything to the end of the line.
            int e = zh_hole_end(text, ti);
            zh_cap_from.put(cap, ti);
            zh_cap_to.put(cap, e);
            return e - ti;
        }
        !!! Shortest first, then one byte longer, until the rest of the pattern
        !!! matches or the line ends.
        int len = 0;
        bool going = true;
        while going {
            zh_cap_from.put(cap, ti);
            zh_cap_to.put(cap, ti + len);
            int rest = zh_match(en, ei + plen, text, ti + len, cap + 1);
            if rest >= 0 {
                return len + rest;
            }
            if text[ti + len] == (char)0 || text[ti + len] == '\n'
               || text[ti + len] == '\r' {
                going = false;
            } else {
                len = len + 1;
            }
        }
        return -1;
    }
    if text[ti] != en[ei] {
        return -1;
    }
    !!! The failure of the rest has to be asked for by hand: `1 + (-1)` is 0, and
    !!! 0 is a match of no length, so adding first would turn every failure into a
    !!! match of the bytes that happened to line up before it.
    int after = zh_match(en, ei + 1, text, ti + 1, cap);
    if after < 0 {
        return -1;
    }
    return 1 + after;
}

!!! The Chinese text of a rule with the captures of the best match put in:
!!! `{1}`, `{2}`, ... name a capture by number, so a sentence may use them in
!!! another order than the English one, and the `%s`-style placeholders of the
!!! pattern take the captures in order. `ncap` is how many captures the match
!!! has, which is how many placeholders the pattern holds.
str zh_expand -> str zh, int ncap, str text {
    @TextBuf b = tx_new();
    int next = 1;
    int i = 0;
    while zh[i] != (char)0 {
        bool done = false;
        if zh[i] == '{' && zh[i + 1] >= '0' && zh[i + 1] <= '9' {
            int j = i + 1;
            int idx = 0;
            while zh[j] >= '0' && zh[j] <= '9' {
                idx = idx * 10 + ((int)zh[j] - 48);
                j = j + 1;
            }
            if zh[j] == '}' {
                if idx > 0 && idx <= ncap {
                    tx_add(b, pe_sub(text, zh_best_from.get(idx),
                                     zh_best_to.get(idx) - zh_best_from.get(idx)));
                }
                i = j + 1;
                done = true;
            }
        }
        if !done {
            if zh[i] == '%' && zh_is_ph(zh[i + 1]) {
                i = i + zh_ph_len(zh, i);
                if next <= ncap {
                    tx_add(b, pe_sub(text, zh_best_from.get(next),
                                     zh_best_to.get(next) - zh_best_from.get(next)));
                    next = next + 1;
                }
            } else {
                tx_add_ch(b, zh[i]);
                i = i + 1;
            }
        }
    }
    return tx_copy(b);
}

!!! ---- the switch ----

!!! -1: not decided yet, 0: English, 1: Chinese. A front end started on its own -
!!! gn.exe, or blang.exe handed a `.b` file - reads the variable blang.exe sets
!!! for `-Chinese`, and once zh_enable has been called the environment is no
!!! longer consulted.
int zh_on = -1;

!!! The diagnostics are UTF-8, so the console has to be told to decode them as
!!! UTF-8: on a code page such as 936 the Chinese text would be mojibake.
void zh_console {
    SetConsoleOutputCP(65001);
}

bool zh_enabled {
    if zh_on < 0 {
        str e = env_get("BLANG_CHINESE");
        zh_on = 0;
        if pe_len(e) > 0 && e[0] == '1' {
            zh_on = 1;
            zh_console();
        }
    }
    return zh_on == 1;
}

void zh_enable -> bool on {
    if on {
        zh_on = 1;
        zh_console();
    } else {
        zh_on = 0;
    }
}

!!! The category word of a diagnostic. An unknown word is answered unchanged, so
!!! a diagnostic site added later still prints in English.
str zh_word -> str english {
    if !zh_enabled() {
        return english;
    }
    if pe_eq(english, "error") {
        return "错误";
    }
    if pe_eq(english, "warning") {
        return "警告";
    }
    if pe_eq(english, "note") {
        return "提示";
    }
    if pe_eq(english, "fatal error") {
        return "错误";
    }
    return english;
}

!!! The Chinese text when Chinese output is on, the English one otherwise. The
!!! two get the same arguments, so a diagnostic format string can be picked here
!!! and the message body that follows it can still go through zh_msg.
str zh_pick -> str english, str chinese {
    if zh_enabled() {
        return chinese;
    }
    return english;
}

!!! ---- translating one message ----

!!! Translate a message body. The longest match wins, repeatedly, so a message
!!! the front end assembled from several fragments is translated piece by piece;
!!! a tie goes to the rule that stands first in the table. Sixteen passes are
!!! enough for every message of the compiler, and the walk stops earlier when no
!!! rule matches any more or a replacement would change nothing - which is what
!!! keeps a rule whose Chinese text equals its English one from looping.
str zh_msg -> str msg {
    if !zh_enabled() || pe_len(msg) == 0 {
        return msg;
    }
    zh_table_ready();
    str text = msg;
    bool more = true;
    int pass = 0;
    while pass < 16 && more {
        @ZhRule bestr = null;
        int best_len = 0;
        int best_at = 0;
        int best_ncap = 0;
        @ZhRule r = zh_rules;
        while r != null {
            int ncap = zh_count_caps(r.en);
            int n = pe_len(text);
            !!! The leftmost match is taken and the walk goes on after it, and of
            !!! the matches found that way the longest is kept. A zero-length
            !!! match ends the walk, which is what `if (m.length() == 0) break;`
            !!! does in the toolchain.
            int pos = 0;
            while pos <= n {
                int len = zh_match(r.en, 0, text, pos, 1);
                if len < 0 {
                    pos = pos + 1;
                } else if len == 0 {
                    pos = n + 1;
                } else {
                    if len > best_len {
                        best_len = len;
                        best_at = pos;
                        bestr = r;
                        best_ncap = ncap;
                        int k = 1;
                        while k <= ncap {
                            zh_best_from.put(k, zh_cap_from.get(k));
                            zh_best_to.put(k, zh_cap_to.get(k));
                            k = k + 1;
                        }
                    }
                    pos = pos + len;
                }
            }
            r = r.next;
        }
        if bestr == null || best_len == 0 {
            more = false;
        } else {
            str rep = zh_expand(bestr.zh, best_ncap, text);
            if pe_eq(rep, pe_sub(text, best_at, best_len)) {
                more = false;
            } else {
                text = pe_sub(text, 0, best_at) + rep
                       + pe_sub_to_end(text, best_at + best_len);
                pass = pass + 1;
            }
        }
    }
    return text;
}

!!! ---- the category words of a diagnostic header ----

!!! The words the front end puts in front of a message, after the `file:line:col:`
!!! part and its `: `. `zh_cat_zh` is what zh_word answers for the same word.
str zh_cat_en -> int i {
    if i == 0 {
        return "fatal error";
    }
    if i == 1 {
        return "error";
    }
    if i == 2 {
        return "warning";
    }
    return "note";
}

str zh_cat_zh -> int i {
    if i == 2 {
        return "警告";
    }
    if i == 3 {
        return "提示";
    }
    return "错误";
}

!!! The offset of `pat` in `s` from `from` on, or -1.
int zh_find -> str s, str pat, int from {
    int n = pe_len(s);
    int m = pe_len(pat);
    if m == 0 {
        return -1;
    }
    int i = from;
    while i + m <= n {
        if pe_matches(s, i, pat) {
            return i;
        }
        i = i + 1;
    }
    return -1;
}

!!! Whether a colour escape starts at `s[i]`.
bool zh_is_esc -> str s, int i {
    if s[i] == (char)27 && s[i + 1] == '[' {
        return true;
    }
    return false;
}

!!! The visible bytes of one line, with the colour escapes taken out, and where
!!! each of them stands in the line: `zh_plain_pos[i]` is the offset in the raw
!!! line of the i-th visible byte. The category word is found on the visible text
!!! and then cut out of the raw one, so the escapes inside it go with it and the
!!! rest of the line - message, source excerpt, caret and its colours - cannot
!!! shift by a byte.
vector(int) zh_plain_pos;

str zh_plain_build -> str raw {
    zh_plain_pos.clear();
    @TextBuf b = tx_new();
    int i = 0;
    while raw[i] != (char)0 {
        if zh_is_esc(raw, i) {
            i = i + 2;
            while raw[i] != (char)0 && raw[i] != 'm' {
                i = i + 1;
            }
            if raw[i] == 'm' {
                i = i + 1;
            }
        } else {
            zh_plain_pos.add(i);
            tx_add_ch(b, raw[i]);
            i = i + 1;
        }
    }
    return tx_copy(b);
}

!!! Translate the category words of a whole diagnostic text. Only the word of a
!!! `file:line:col: error:` style header is touched - and only the first word of
!!! a line that is preceded by `:`, so a message that happens to contain the word
!!! "error" is left alone. Everything else, the message body included, stays as
!!! it is.
str zh_prefixes -> str text {
    if !zh_enabled() || pe_len(text) == 0 {
        return text;
    }
    @TextBuf out = tx_new();
    int i = 0;
    bool more = true;
    while more {
        int e = zh_find(text, "\n", i);
        bool last = (e < 0);
        str line = "";
        if last {
            line = pe_sub_to_end(text, i);
        } else {
            line = pe_sub(text, i, e - i + 1);
        }
        if pe_len(line) > 0 {
            str plain = zh_plain_build(line);
            int hit = -1;
            int hit_len = 0;
            int hit_cat = -1;
            int c = 0;
            while c < 4 && hit < 0 {
                str w = zh_cat_en(c);
                int wl = pe_len(w);
                int at = zh_find(plain, w, 0);
                while at >= 0 {
                    !!! The word that names the category stands after a `:`.
                    int before = at;
                    while before > 0 && plain[before - 1] == ' ' {
                        before = before - 1;
                    }
                    if before > 0 && plain[before - 1] == ':' {
                        hit = at;
                        hit_len = wl;
                        hit_cat = c;
                        at = -1;
                    } else {
                        at = zh_find(plain, w, at + 1);
                    }
                }
                c = c + 1;
            }
            if hit >= 0 {
                int raw_from = zh_plain_pos.get(hit);
                int raw_to = zh_plain_pos.get(hit + hit_len - 1) + 1;
                line = pe_sub(line, 0, raw_from) + zh_cat_zh(hit_cat)
                       + pe_sub_to_end(line, raw_to);
            }
            !!! The two whole-line texts the front end prints around a fatal error.
            int tl = pe_len(plain);
            while tl > 0 && (plain[tl - 1] == '\n' || plain[tl - 1] == '\r') {
                tl = tl - 1;
            }
            if pe_eq(pe_sub(plain, 0, tl), "compilation terminated.") {
                if pe_len(line) > 0 && line[pe_len(line) - 1] == '\n' {
                    line = "编译终止。\n";
                } else {
                    line = "编译终止。";
                }
            }
        }
        tx_add(out, line);
        if last {
            more = false;
        } else {
            i = e + 1;
        }
    }
    return tx_copy(out);
}

!!! ---- the driver's own messages ----

!!! A message with a `file: error: text` shape: the preprocessor's own errors.
str zh_file_error -> str filename, str msg {
    if !zh_enabled() {
        return filename + ": error: " + msg;
    }
    return filename + ": " + zh_word("error") + ": " + zh_msg(msg);
}

!!! The driver's fatal error, in the layout ux_fatal uses:
!!!
!!!   <prog>: 错误: <msg>
!!!   编译终止。
!!!
!!! The English path is ux_fatal itself, so a run without `-Chinese` prints
!!! exactly what it printed before. The quoted parts of the message are not put
!!! in bold here, which is what the toolchain does as well: the translated text is
!!! written as it stands.
void zh_fatal -> str prog, str msg {
    if !zh_enabled() {
        ux_fatal(prog, msg);
        end;
    }
    str text = zh_msg(msg);
    ux_color("bold");
    system.err(prog + ": ");
    ux_color("reset");
    ux_color("bold_red");
    system.err(zh_word("fatal error") + ": ");
    ux_color("reset");
    system.err(text + "\n");
    system.err("编译终止。\n");
}
