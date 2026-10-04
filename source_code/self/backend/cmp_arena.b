#once
!~
 ~  bootstrap/backend/cmp_arena.b: the block allocator of the .r compiler.
 ~
 ~  `malloc` in this runtime is VirtualAlloc (runtime/brtm.b, `_malloc`): every
 ~  request, however small, takes a whole 4 KiB page and a kernel call. The .r of a
 ~  large program becomes hundreds of thousands of nodes, and handing each one its
 ~  own page cost more than everything else the compiler does put together. the toolchain
 ~  takes `operator new` from a user-space allocator; this stands in for it.
 ~
 ~  A block is asked of the system a megabyte at a time and handed out sixteen
 ~  bytes at a time. Nothing given out here is ever given back, which is what a
 ~  compiler does - it reads one file, writes one program and exits, and the toolchain
 ~  port leaks the same nodes. The allocations that ARE given back keep using
 ~  `malloc`: the code buffer and the section buffers of the writer (their growth
 ~  copies into a fresh block and unlinks the old one), and the vectors of the
 ~  standard library.
 ~
 ~  What is left of the block is the state of one `Arena` - a global object, so it is
 ~  written with no `@`. The fields are private, so the only way to take from it is
 ~  the method `take`, declared inside the type and defined below it, and `cg_balloc`
 ~  keeps the name the modules of the backend call, the way they call the toolchain
 ~  `CodeGenerator::balloc`.
 ~!

#head "stdsrt"

!!! The block being handed out: where the next cell starts and how much of the block
!!! is left. Both are private - the type hands out cells, nothing else reads them.
type Arena {
    private @char base;
    private int left;

    !!! `n` bytes for the cell `cell`, which holds a pointer of some type: `malloc`
    !!! without a page per object. The size is rounded up to sixteen bytes, so every
    !!! object handed out stays aligned, and a block too small for the request is
    !!! replaced by one that holds it.
    public stub void take -> @void cell, int n;
};

!!! How much is asked of the system at a time. One page per object was the problem;
!!! a megabyte holds tens of thousands of them, and a block that is never touched
!!! costs nothing but address space.
int kArenaChunk = 1048576;

!!! The one arena of this program. No `@`: the block it hands out is the state of
!!! the object itself, not of a pointer to one.
Arena arena;

void Arena::take -> @void cell, int n {
    int want = (n + 15) & (0 - 16);
    if want < 16 {
        want = 16;
    }
    if self.left < want {
        int chunk = kArenaChunk;
        if chunk < want {
            chunk = want;
        }
        @void fresh = VirtualAlloc(null, (longlong)chunk, 12288, 4);
        if fresh == null {
            $cell = null;
            end;
        }
        self.base = (@char)fresh;
        self.left = chunk;
    }
    $cell = (@void)self.base;
    self.base = self.base + want;
    self.left = self.left - want;
}

!!! `n` bytes for the cell `cell`: the `CodeGenerator::balloc`, which every
!!! module of the backend calls.
void cg_balloc -> @void cell, int n {
    arena.take(cell, n);
}
