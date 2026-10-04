#once
!~
 ~  bootstrap/backend/codegen_intern.b: string interning.
 ~
 ~  the same text goes into .rdata once, so
 ~  two equal string literals are the same address. That is what makes `==` on two
 ~  strings a pointer comparison, which is how the frontend spells it.
 ~
 ~  The table is the index and not a chain: a module has thousands of distinct
 ~  messages and every literal is looked up, so walking a chain of them was the
 ~  single largest cost of compiling one. The offset a text was placed at is never
 ~  0, which is the "not there" the index answers.
 ~!

#head "cg_heads"
#head "cmp_index"

int cg_intern_str -> str s {
    int rva = ix_get(kIxStrCache, s, 1);
    if rva != 0 {
        return rva;
    }
    rva = pw_add_rdata_str(s);
    ix_set(kIxStrCache, s, rva, 0, 0, 0, "");
    return rva;
}
