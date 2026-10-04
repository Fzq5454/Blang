!~
 ~  if_example.b: conditionals - which lines exist at all.
 ~
 ~  `#if` decides which lines are compiled from what the build says, not from what
 ~  the source contains: the numbers come from the command line (-D) and the facts
 ~  come from the compiler itself (built_in(...)). A branch that was not taken is
 ~  never read, so code that belongs to another platform or another build cannot
 ~  break this one. `#elif` and `#else` are the rest of the chain, `#endif` ends it.
 ~
 ~  Build:
 ~    blang.exe if_example.b -o if_example.exe -dbrtm -dbprintf
 ~    blang.exe if_example.b -o if_example.exe -dbrtm -dbprintf -D LEVEL=2
 ~    blang.exe if_example.b -o if_example.exe -dbrtm -dbprintf -D LEVEL=1
 ~!

#head "format"

#if defined(LEVEL) && LEVEL >= 2
    #replace MODE "verbose"
#elif defined(LEVEL) && LEVEL == 1
    #replace MODE "normal"
#else
    #replace MODE "quiet"
#endif

#if str_eq(MODE, "verbose")
    #replace CHAT "chatty"
#else
    #replace CHAT "terse"
#endif

#if built_in(PTR_SIZE) == 8
    #replace BITS "64"
#else
    #replace BITS "32"
#endif

int main {
    printf("mode=%s\n", MODE);

#if built_in(SUBSYSTEM_GUI)
    printf("a windowed build: there is no console to print this on\n");
#else
    printf("console build, %s-bit, %s\n", BITS, CHAT);
#endif

    return 0;
}
