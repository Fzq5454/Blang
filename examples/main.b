#head "stdsrt"

void false_alloc {
    system.out("alloc success!\n");
}

void false_free {
    system.out("free success!\n");
}

rule warn(pair(not_pair(false_alloc, false_free), "warning", "alloc and free are not match", false_alloc, false_free))

int main {
    false_alloc();
    return 0;
}