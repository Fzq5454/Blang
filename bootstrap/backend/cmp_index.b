#once
!~
 ~  bootstrap/backend/cmp_index.b: the name index of the code generator.
 ~
 ~  the toolchain keeps its tables in name table, so a name is found with one
 ~  hash probe. this implementation keeps them as chains, which is what a table that is also
 ~  walked in registration order wants, so a lookup walked the whole chain - and
 ~  the DLL import table holds every name kernel32 declares, while the question
 ~  "is this call a DLL import?" is asked at every call site. That walk was most
 ~  of this implementation's compile time.
 ~
 ~  The index here gives the probe back. It is one table of entries - the table an
 ~  entry belongs to, its key, four numbers and one text - with a bucket array
 ~  over it, and it is also the registration order: everything written out of one
 ~  of these tables walks the entries in registration order, which is the order
 ~  the toolchain writes them in (it keeps the same list for the same reason, because a
 ~  hash order is not reproducible across standard libraries).
 ~
 ~  An entry carries numbers and one text and not a pointer: the language has no
 ~  cast to a struct pointer, so a pointer cannot be put in an untyped slot and
 ~  read back again. A table whose value is a pointer keeps its chain and uses the
 ~  index only to answer whether the name is there at all.
 ~!

#head "cmp_text"
#head "vector"

!!! ---- the tables the index serves ----

!!! A table is a number and not a prefix of the key, so a lookup builds no key and
!!! two tables may hold the same name.
int kIxFuncMap = 1;        !!! name -> the offset its code starts at
int kIxFuncArity = 2;      !!! name -> how many parameters it takes
int kIxFuncVariadic = 3;   !!! name -> 1 when its last parameter is a pack
int kIxFuncRetType = 4;    !!! name -> the VarType it hands back
int kIxDeclared = 5;       !!! name -> 1, every function the module defines
int kIxLocalFunc = 6;      !!! name -> 1 when the function is not exported
int kIxRetStruct = 7;      !!! name -> the struct type it hands back, as text
int kIxDll = 8;            !!! name -> the index of its IAT slot, a DLL import
int kIxParamTypes = 10;    !!! name -> its parameter types, one byte each
int kIxStrCache = 11;      !!! text -> the .rdata offset it was placed at
int kIxKeyWord = 12;       !!! a word the parser starts a statement with -> its code
int kIxCastWord = 13;      !!! a word that spells a cast -> 1
int kIxLibSym = 14;        !!! a symbol of a linked library -> its code offset
int kIxDllImport = 15;     !!! a name the chain of DLL imports holds
int kIxFnParams = 16;      !!! a function whose parameter list is registered
int kIxFnParamTypes = 17;  !!! ... the types of its parameters
int kIxFnParamOffsets = 18;!!! ... the slot of each of its parameters
int kIxFnVars = 19;        !!! ... the variables of its body, for the debugger
int kIxFnLocalSyms = 20;   !!! ... the locals its body declared
int kIxFnParamStruct = 21; !!! ... the struct type each of its parameters takes

!!! ---- the entries ----

!!! A bucket holds the id of an entry, an entry id is one based and 0 is "none".
vector(int) ix_bucket;
!!! An entry -> the next entry in its bucket.
vector(int) ix_next;
!!! An entry -> the table it belongs to, its key, four numbers and one text.
vector(int) ix_table;
vector(str) ix_key;
vector(int) ix_v1;
vector(int) ix_v2;
vector(int) ix_v3;
vector(int) ix_v4;
vector(str) ix_s1;
int ix_count;
int ix_mask;
int ix_grow_at;

int ix_slot -> int id {
    return id - 1;
}

!!! The bucket a key falls in: djb2 over its bytes, masked to the table size. Any
!!! spread works - this is not its hash and does not have to be - what the
!!! two compilers have to agree on is the order the entries are walked in, and
!!! that order is the order they were put in.
int ix_hash -> str key {
    int h = 5381;
    int n = pe_len(key);
    int i = 0;
    while i < n {
        h = h * 33 + ((int)key[i] & 255);
        i = i + 1;
    }
    return h & ix_mask;
}

void ix_buckets_clear {
    ix_bucket.clear();
    int i = 0;
    while i < ix_mask + 1 {
        ix_bucket.add(0);
        i = i + 1;
    }
}

void ix_init {
    ix_next.clear();
    ix_table.clear();
    ix_key.clear();
    ix_v1.clear();
    ix_v2.clear();
    ix_v3.clear();
    ix_v4.clear();
    ix_s1.clear();
    ix_count = 0;
    ix_mask = 1023;
    ix_grow_at = 768;
    ix_buckets_clear();
}

!!! Twice as many buckets and every entry put back. The chains are rebuilt in id
!!! order, so a bucket ends up holding the newest entry first; only the order the
!!! entries are walked in matters and that is the id order, which does not move.
void ix_rehash {
    ix_mask = ix_mask * 2 + 1;
    ix_grow_at = (ix_mask * 3) / 4;
    ix_buckets_clear();
    int id = 1;
    while id <= ix_count {
        int s = ix_slot(id);
        int b = ix_hash(ix_key.get(s));
        ix_next.put(s, ix_bucket.get(b));
        ix_bucket.put(b, id);
        id = id + 1;
    }
}

int ix_find -> int tbl, str key {
    int id = ix_bucket.get(ix_hash(key));
    while id != 0 {
        int s = ix_slot(id);
        if ix_table.get(s) == tbl && pe_eq(ix_key.get(s), key) {
            return id;
        }
        id = ix_next.get(s);
    }
    return 0;
}

bool ix_has -> int tbl, str key {
    return ix_find(tbl, key) != 0;
}

!!! Put a value under a name, or replace the value of the entry that name already
!!! has - the entry keeps its place, which is what "the first appearance decides
!!! the order" means.
void ix_set -> int tbl, str key, int v1, int v2, int v3, int v4, str s1 {
    int id = ix_find(tbl, key);
    if id != 0 {
        int s = ix_slot(id);
        ix_v1.put(s, v1);
        ix_v2.put(s, v2);
        ix_v3.put(s, v3);
        ix_v4.put(s, v4);
        ix_s1.put(s, s1);
        end;
    }
    ix_next.add(0);
    ix_table.add(tbl);
    ix_key.add(key);
    ix_v1.add(v1);
    ix_v2.add(v2);
    ix_v3.add(v3);
    ix_v4.add(v4);
    ix_s1.add(s1);
    ix_count = ix_count + 1;
    int s = ix_slot(ix_count);
    int b = ix_hash(key);
    ix_next.put(s, ix_bucket.get(b));
    ix_bucket.put(b, ix_count);
    if ix_count >= ix_grow_at {
        ix_rehash();
    }
}

!!! One of the four numbers of a name, 0 when the name is not there.
!!! One of the four numbers of one entry.
int ix_get_v -> int id, int which {
    int s = ix_slot(id);
    switch which {
        case 2:
            return ix_v2.get(s);
        case 3:
            return ix_v3.get(s);
        case 4:
            return ix_v4.get(s);
    }
    return ix_v1.get(s);
}

!!! One of the four numbers of a name, 0 when the name is not there.
int ix_get -> int tbl, str key, int which {
    int id = ix_find(tbl, key);
    if id == 0 {
        return 0;
    }
    return ix_get_v(id, which);
}

!!! The text of a name, `def` when the name is not there.
str ix_get_s -> int tbl, str key, str def {
    int id = ix_find(tbl, key);
    if id == 0 {
        return def;
    }
    return ix_s1.get(ix_slot(id));
}

str ix_get_key -> int id {
    return ix_key.get(ix_slot(id));
}

!!! The first entry of `tbl` after `from`, which walks the entries in the order
!!! they were put in. 0 when there is none.
int ix_after -> int tbl, int from {
    int id = from + 1;
    while id <= ix_count {
        if ix_table.get(ix_slot(id)) == tbl {
            return id;
        }
        id = id + 1;
    }
    return 0;
}

!!! The first entry of `tbl`, or 0 when the table is empty.
int ix_first -> int tbl {
    return ix_after(tbl, 0);
}
