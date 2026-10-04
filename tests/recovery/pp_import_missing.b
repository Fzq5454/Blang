!!! An `#import` of a name no `#export` publishes, and an extra `#endif`.
#import "no_such_export_at_all"
int main {
    return 0;
}
#endif
