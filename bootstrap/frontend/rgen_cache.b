#once
!~
 ~  bootstrap/frontend/rgen_cache.b: the key hash the symbol tables are walked by.
 ~
 ~  Every symbol table of the code generator is a chain
 ~  and every pass asks the same names over and over, so answering one lookup walks
 ~  the chain: on the compiler's own source that walk was most of the run - the
 ~  emitter alone spent 61 s of 127 s looking names up.
 ~
 ~  Each node of those chains carries the hash of its key (`hash`), written once when
 ~  the node is made. A lookup hashes the name it is asked about and compares that
 ~  number with the one on each node, so a node the lookup is not about is rejected
 ~  with one integer compare instead of a call to `p_text_eq`; only the node whose
 ~  hash matches has its text compared, which is the one answer that costs a string
 ~  compare. That took the emitter from 46.9 s to 15.6 s on the compiler's own
 ~  source and the type checker from 18.2 s to 7.3 s.
 ~
 ~  A direct mapped cache of the answers was tried beside this and taken out again:
 ~  a table of 4096 entries per type, each remembering the chain and the node that
 ~  answered, made the pass that asks about the most names 2.8 s *slower*, because a
 ~  name looked up for the first time pays for the entry as well as the walk and the
 ~  emitter's chains are short. The hash on the node is what pays.
 ~
 ~  The hash is a field of the node rather than a table beside the chain because a
 ~  pointer to a struct cannot be cast back from an address in this language, so an
 ~  array of node addresses could not be read back as the node it names.
 ~!

#head "rgen_heads"

!!! The hash of a name, kept under 2^24 so one step never overflows an int.
int g_n_hash;
int rgx_lk_hash -> str key {
    g_n_hash = g_n_hash + 1;
    int h = 0;
    int i = 0;
    while key[i] != (char)0 {
        h = ((h * 31) + ((int)key[i] & 255)) & 16777215;
        i = i + 1;
    }
    return h;
}

!!! ---- how long each stage took ----
!!!
!!! BLANG_TIME=1 makes the front end print the time of every stage to stderr. It is
!!! a switch of the compiler and not an option, so it changes nothing but the
!!! messages: the same source behind it produces the same .r. That is what lets a
!!! measurement be taken without changing what is being measured, which is what the
!!! timing edits of a debugging session do not do.

bool g_time_on;

void time_check {
    @void cell;
    malloc(@cell, 8);
    int n = GetEnvironmentVariableA("BLANG_TIME", (str)cell, 8);
    if n > 0 {
        g_time_on = true;
    }
    unlink(@cell);
}

int time_now {
    return (int)GetTickCount();
}

void time_print -> str what, int ms {
    if g_time_on {
        system.err("[time] ", what, ": ", ms, " ms\n");
    }
}
