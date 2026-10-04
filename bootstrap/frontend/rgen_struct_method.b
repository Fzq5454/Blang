#once
!~
 ~  bootstrap/frontend/rgen_struct_method.b: the frontend/rgen_struct_method.
 ~
 ~  Two questions about a call written on a receiver: whether `x.m(...)` names a
 ~  method (or a BLANG_API method) of the struct `x` is, and which BLANG_API method
 ~  a call names.
 ~
 ~  Both read the struct of the receiver as it is declared where the call is written
 ~  (receiver_struct_type_of), never from the flat symbol table: another body may
 ~  have declared the same name with a different type, and the flat table would
 ~  answer with that first declaration.
 ~!

#head "rgen"

!!! Whether `func_name` is a method of the struct `struct_var` denotes, a method
!!! function or a BLANG_API method. False when the receiver is not a struct at all.
bool rg_is_struct_method -> str func_name, str struct_var {
    str stype = rg_receiver_struct_type_of(struct_var);
    if stype == "" {
        return false;
    }
    if rg_resolve_method_func(stype, func_name, true) != null {
        return true;
    }
    return rg_resolve_bapi_method(stype, func_name, true) != null;
}

!!! The BLANG_API statement of the method `func_name` of the struct `struct_var`
!!! denotes, or null.
@StmtNode rg_find_struct_bapi -> str func_name, str struct_var {
    str stype = rg_receiver_struct_type_of(struct_var);
    if stype == "" {
        return null;
    }
    return rg_resolve_bapi_method(stype, func_name, true);
}
