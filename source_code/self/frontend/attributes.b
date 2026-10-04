#once
!~
 ~  bootstrap/frontend/attributes.b: the built-in attributes of
 ~  `attribute <object>: <NAME>` — the frontend/attributes.
 ~
 ~  `attribute a: USED` tells the compiler something about the object `a` that it
 ~  cannot work out for itself: that a name is used, that its value is read, that it
 ~  is initialized, what its type is, or what is known about a function's body. The
 ~  object is a function, a struct, a variable or a constant, and a member of a
 ~  struct or a package member is named the way the source names it (`S.f`, `S.m`,
 ~  `pkg::f`).
 ~
 ~  The names are built in and this file is the whole list of them, the way
 ~  `frontend/attributes` is for the front end: a name that is not one of
 ~  these is reported, so a typo cannot be taken for a property the compiler does
 ~  not have. The parser records every `attribute` statement it reads in `attr_uses`
 ~  and the passes the attributes speak to read that list.
 ~!

#head "stdsrt"
#head "preproc_env"
#head "types"

!!! Declared before use: `attr_kind` asks whether a name is one of the type names,
!!! and the list of them stands below it.
stub bool attr_is_type_name -> str name;

!!! What an attribute says about an object.
int ATTR_EFFECT_USED = 1;    !!! the name counts as used (-W-nused)
int ATTR_EFFECT_READ = 2;    !!! the value counts as read (-W-read-nused)
int ATTR_EFFECT_INIT = 4;    !!! the object counts as initialized
int ATTR_EFFECT_TYPE = 8;    !!! the attribute names the object's type
int ATTR_EFFECT_NOBODY = 16; !!! a function whose body this file does not check
int ATTR_EFFECT_NOWARN = 32; !!! the warnings of its body are not reported

!!! What one name of the built-in table stands for: an effect, or one of the type
!!! names. ATTR_KIND_NONE means the compiler does not know the name.
int ATTR_KIND_NONE = 0;
int ATTR_KIND_USED = 1;
int ATTR_KIND_READ = 2;
int ATTR_KIND_INIT = 3;
int ATTR_KIND_EXTERN = 4;
int ATTR_KIND_NORETURN = 5;
int ATTR_KIND_NOWARN = 6;
int ATTR_KIND_TYPE = 7;

!!! Which entry of the table a name is. The order is the order table.
int attr_kind -> str name {
    if pe_eq(name, "USED") {
        return ATTR_KIND_USED;
    }
    if pe_eq(name, "READ") {
        return ATTR_KIND_READ;
    }
    if pe_eq(name, "INIT") {
        return ATTR_KIND_INIT;
    }
    !!! `EXTERN` is a function another file (or a library) defines: this file
    !!! declares it and calls it, and the body written here - often none at all - is
    !!! not checked. `NORETURN` is a function that does not come back (it exits or
    !!! throws), so a `return` is not missing from it. `NOWARN` keeps the warnings of
    !!! its body out of the output.
    if pe_eq(name, "EXTERN") {
        return ATTR_KIND_EXTERN;
    }
    if pe_eq(name, "NORETURN") {
        return ATTR_KIND_NORETURN;
    }
    if pe_eq(name, "NOWARN") {
        return ATTR_KIND_NOWARN;
    }
    if pe_eq(name, "SILENT") {
        return ATTR_KIND_NOWARN;
    }
    if attr_is_type_name(name) {
        return ATTR_KIND_TYPE;
    }
    return ATTR_KIND_NONE;
}

!!! Whether the name is one of the type names, spelled the way the .r spells them.
bool attr_is_type_name -> str name {
    if pe_eq(name, "INT") {
        return true;
    }
    if pe_eq(name, "LONG") {
        return true;
    }
    if pe_eq(name, "LONGLONG") {
        return true;
    }
    if pe_eq(name, "STR") {
        return true;
    }
    if pe_eq(name, "FLOAT") {
        return true;
    }
    if pe_eq(name, "CHAR") {
        return true;
    }
    if pe_eq(name, "BOOL") {
        return true;
    }
    if pe_eq(name, "VOID") {
        return true;
    }
    if pe_eq(name, "ANY") {
        return true;
    }
    if pe_eq(name, "FUNC") {
        return true;
    }
    if pe_eq(name, "AT_INT") {
        return true;
    }
    if pe_eq(name, "AT_LONG") {
        return true;
    }
    if pe_eq(name, "AT_LONGLONG") {
        return true;
    }
    if pe_eq(name, "AT_STR") {
        return true;
    }
    if pe_eq(name, "AT_FLOAT") {
        return true;
    }
    if pe_eq(name, "AT_CHAR") {
        return true;
    }
    if pe_eq(name, "AT_BOOL") {
        return true;
    }
    if pe_eq(name, "AT_VOID") {
        return true;
    }
    if pe_eq(name, "AT_FUNC") {
        return true;
    }
    if pe_eq(name, "UTYPE_INT") {
        return true;
    }
    if pe_eq(name, "UTYPE_LONG") {
        return true;
    }
    if pe_eq(name, "UTYPE_LONGLONG") {
        return true;
    }
    if pe_eq(name, "UTYPE_CHAR") {
        return true;
    }
    return false;
}

!!! The type a type attribute names.
VarType attr_type_of -> str name {
    if pe_eq(name, "INT") {
        return INT;
    }
    if pe_eq(name, "LONG") {
        return LONG;
    }
    if pe_eq(name, "LONGLONG") {
        return LONG;
    }
    if pe_eq(name, "STR") {
        return STR;
    }
    if pe_eq(name, "FLOAT") {
        return FLOAT;
    }
    if pe_eq(name, "CHAR") {
        return CHAR;
    }
    if pe_eq(name, "BOOL") {
        return BOOL;
    }
    if pe_eq(name, "VOID") {
        return VOID;
    }
    if pe_eq(name, "ANY") {
        return ANY;
    }
    if pe_eq(name, "FUNC") {
        return FUNC;
    }
    if pe_eq(name, "AT_INT") {
        return AT_INT;
    }
    if pe_eq(name, "AT_LONG") {
        return AT_LONG;
    }
    if pe_eq(name, "AT_LONGLONG") {
        return AT_LONG;
    }
    if pe_eq(name, "AT_STR") {
        return AT_STR;
    }
    if pe_eq(name, "AT_FLOAT") {
        return AT_FLOAT;
    }
    if pe_eq(name, "AT_CHAR") {
        return AT_CHAR;
    }
    if pe_eq(name, "AT_BOOL") {
        return AT_BOOL;
    }
    if pe_eq(name, "AT_VOID") {
        return AT_VOID;
    }
    if pe_eq(name, "AT_FUNC") {
        return AT_FUNC;
    }
    if pe_eq(name, "UTYPE_INT") {
        return INT;
    }
    if pe_eq(name, "UTYPE_LONG") {
        return LONG;
    }
    if pe_eq(name, "UTYPE_LONGLONG") {
        return LONG;
    }
    if pe_eq(name, "UTYPE_CHAR") {
        return CHAR;
    }
    return INT;
}

!!! Whether that type is read without a sign (`UTYPE_INT` and the like).
bool attr_is_unsigned -> str name {
    if pe_eq(name, "UTYPE_INT") {
        return true;
    }
    if pe_eq(name, "UTYPE_LONG") {
        return true;
    }
    if pe_eq(name, "UTYPE_LONGLONG") {
        return true;
    }
    if pe_eq(name, "UTYPE_CHAR") {
        return true;
    }
    return false;
}

!!! The spelling the compiler's tables hold for the object of an attribute use: a
!!! package member is written `pkg::f` in the source and stored as `pkg__f`, every
!!! other name is the name as written. the toolchain applies its attributes on the name
!!! the reader sees and keeps them in tables keyed by the internal spelling, so the
!!! two are told apart where a table is asked (`extern_funcs`, `used_funcs`, ...).
!!! This helper is this implementation's own: the toolchain builds the internal name where it needs
!!! it and has no function for it.
str attr_table_name -> str object, bool scoped {
    if !scoped {
        return object;
    }
    str built = "";
    int sl = pe_len(object);
    int i = 0;
    while i < sl {
        if object[i] == ':' && i + 1 < sl && object[i + 1] == ':' {
            built = built + "__";
            i = i + 2;
            continue;
        }
        built = built + (str)object[i];
        i = i + 1;
    }
    return built;
}

!!! The effects of a name, as the bit set the toolchain table holds.
int attr_effects -> str name {
    int k = attr_kind(name);
    if k == ATTR_KIND_USED {
        return ATTR_EFFECT_USED;
    }
    if k == ATTR_KIND_READ {
        return ATTR_EFFECT_READ;
    }
    if k == ATTR_KIND_INIT {
        return ATTR_EFFECT_INIT;
    }
    if k == ATTR_KIND_EXTERN {
        return ATTR_EFFECT_NOBODY + ATTR_EFFECT_USED;
    }
    if k == ATTR_KIND_NORETURN {
        return ATTR_EFFECT_NOBODY;
    }
    if k == ATTR_KIND_NOWARN {
        return ATTR_EFFECT_NOWARN;
    }
    if k == ATTR_KIND_TYPE {
        return ATTR_EFFECT_TYPE;
    }
    return 0;
}

!!! One `attribute <object>: <NAME>` of the source: the object as the source names
!!! it (`pkg::f`, `S.f`, `f`) and the name after the `:`.
type AttrUse {
    str object;
    str name;
    !!! `S.f` / `S.m`: the struct and the member, split where the parser read the
    !!! `.` (a `str` cannot be indexed here, so the split has to happen while the
    !!! name is being read). `scoped` is a `pkg::f` name, which the tables keep
    !!! under its internal spelling.
    str owner;
    str member;
    bool scoped;
    !!! Where the name stands, for the diagnostic about an object nothing declares.
    int line;
    int col;
    int len;
    @AttrUse next;
};

!!! A line range whose warnings are not reported: the body of a function written
!!! `attribute f: NOWARN` (with `SILENT` as the other spelling).
type AttrRange {
    int lo;
    int hi;
    @AttrRange next;
};

@AttrRange attr_ranges;

!!! An attribute whose object is declared after the use is reported and not applied:
!!! the `apply_object` returns on the spot, so nothing the attribute says reaches
!!! the declaration. this implementation reports that in rg_apply_attr_checks (rgen_declare.b)
!!! and applies what an attribute says in later passes of its own, so the position of
!!! such a use is recorded here and the passes that apply the effects leave it alone.
type AttrSkip {
    int line;
    int col;
    @AttrSkip next;
};

@AttrSkip attr_skips;

void attr_skip_add -> int line, int col {
    AttrSkip proto;
    @AttrSkip e;
    malloc(@e, size proto);
    e.line = line;
    e.col = col;
    e.next = null;
    if attr_skips == null {
        attr_skips = e;
        end;
    }
    @AttrSkip t = attr_skips;
    while t.next != null {
        t = t.next;
    }
    t.next = e;
}

bool attr_is_skipped -> int line, int col {
    @AttrSkip e = attr_skips;
    while e != null {
        if e.line == line && e.col == col {
            return true;
        }
        e = e.next;
    }
    return false;
}

!!! The `attribute` that gives this object a type, or null when none does. The record
!!! is handed back rather than its name: the diagnostic a conflict makes points at the
!!! attribute the way the toolchain points at it, and that needs its position.
@AttrUse attr_type_use_of -> str object {
    @AttrUse u = attr_uses;
    while u != null {
        if pe_eq(u.object, object) && attr_kind(u.name) == ATTR_KIND_TYPE {
            return u;
        }
        u = u.next;
    }
    return null;
}

void attr_range_add -> int lo, int hi {
    AttrRange proto;
    @AttrRange r;
    malloc(@r, size proto);
    r.lo = lo;
    r.hi = hi;
    r.next = attr_ranges;
    attr_ranges = r;
}

!!! Whether a warning standing on this line is one `NOWARN` asked not to hear.
bool attr_in_nowarn -> int line {
    @AttrRange r = attr_ranges;
    while r != null {
        if line >= r.lo && line <= r.hi {
            return true;
        }
        r = r.next;
    }
    return false;
}

!!! Every attribute the source wrote, in the order it wrote them. The parser fills
!!! it and the passes read it, which is what makes an attribute usable before or
!!! after the declaration it talks about.
@AttrUse attr_uses;

!!! Whether an attribute carrying this effect was written for this object. This is
!!! what each pass asks: the unused check wants USED and READ, the const check INIT,
!!! and the control-flow check NOBODY. A pass that asks before the effect is applied
!!! needs no extra walk of its own.
bool attr_has_effect -> str object, int effect {
    @AttrUse u = attr_uses;
    while u != null {
        if pe_eq(u.object, object) && (attr_effects(u.name) & effect) != 0 {
            return true;
        }
        u = u.next;
    }
    return false;
}

void attr_use_add -> str object, str name, str owner, str member, bool scoped,
                     int line, int col, int len {
    AttrUse proto;
    @AttrUse u;
    malloc(@u, size proto);
    u.object = object;
    u.name = name;
    u.owner = owner;
    u.member = member;
    u.scoped = scoped;
    u.line = line;
    u.col = col;
    u.len = len;
    u.next = null;
    !!! The list keeps the order the source wrote: the passes report an unknown
    !!! object in the order a reader would meet it.
    if attr_uses == null {
        attr_uses = u;
        end;
    }
    @AttrUse t = attr_uses;
    while t.next != null {
        t = t.next;
    }
    t.next = u;
}
