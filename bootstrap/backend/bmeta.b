#once
!~
 ~  bootstrap/backend/bmeta.b: the reader of the .bmeta signature files.
 ~
 ~  the reader in backend/bmeta. A `.bmeta` carries the exported
 ~  signatures of one DLL: cmp places them into the image so that a call the
 ~  compiler writes itself (`__bcall("_malloc")`) resolves through a thunk exactly
 ~  like a call written in the source does.
 ~
 ~  The block is walked with the cursor of cmp_file.b, because the reader of the
 ~  runtime answers no length and the records have to be bounded by one.
 ~!

#head "cg_heads"
#head "cmp_file"

!!! The type byte a `.bmeta` stores for a type, which is the toolchain vbmeta_type. The
!!! reader turns it back with cm_bmeta_type, so the two tables have to agree.
int cg_vbmeta_type -> VarType t {
    switch t {
        case BOOL:
            return 0x01;
        case INT:
            return 0x02;
        case STR:
            return 0x03;
        case ANY:
            return 0x04;
        case CHAR:
            return 0x05;
        case FLOAT:
            return 0x06;
        case LONG:
            return 0x07;
        case AT_INT:
            return 0x10;
        case AT_FLOAT:
            return 0x11;
        case AT_CHAR:
            return 0x12;
        case AT_STR:
            return 0x13;
        case AT_VOID:
            return 0x14;
        case AT_BOOL:
            return 0x15;
        case FUNC:
            return 0x16;
        case AT_FUNC:
            return 0x17;
        case AT_LONG:
            return 0x18;
    }
    !!! `void`, which is the 0 the writer gives every type the table does not name.
    return 0x00;
}

!!! Write the `.bmeta` of the DLL just built: the exported signatures of every
!!! function that is not local, which is the same set the export table gets. A
!!! `-link` or `-system` for this DLL reads it back.
bool cg_write_bmeta -> str out_path {
    cm_mkdir(cm_side_write_dir("meta"));
    str path = cm_side_write_path("meta", cm_base_name(out_path) + ".bmeta");
    if !cm_open_write(path) {
        return false;
    }
    int nrec = 0;
    @CgFuncSig s = cg_func_signatures;
    while s != null {
        if !s.is_local {
            nrec = nrec + 1;
        }
        s = s.next;
    }
    cm_w8c('B');
    cm_w8c('L');
    cm_w8c('M');
    cm_w8c('T');
    cm_w16(0x0100);
    cm_w16(nrec);
    cm_w32(0);
    s = cg_func_signatures;
    while s != null {
        if !s.is_local {
            cm_w8(pe_len(s.name));
            @char np = (@char)s.name;
            cm_wraw(np, pe_len(s.name));
            cm_w8(cg_vbmeta_type(s.ret_type));
            cm_w8(cn_type_n(s.param_types));
            int i = 0;
            @CmpTypeNode pt = s.param_types;
            @CmpStrNode pn = s.param_names;
            while pt != null {
                str nm = "";
                if pn != null {
                    nm = pn.s;
                    pn = pn.next;
                }
                cm_w8(cg_vbmeta_type(pt.ty));
                cm_w8(pe_len(nm));
                @char pnp = (@char)nm;
                cm_wraw(pnp, pe_len(nm));
                pt = pt.next;
                i = i + 1;
            }
        }
        s = s.next;
    }
    return true;
}

!!! Append one signature to the chain, in the order the file lists them: a
!!! signature is found by name, so the order is only what makes a walk read in the
!!! file's order.
@CgBmetaFunc cg_bmeta_add -> @CgBmetaFunc head, @CgBmetaFunc bf {
    if head == null {
        return bf;
    }
    @CgBmetaFunc t = head;
    while t.next != null {
        t = t.next;
    }
    t.next = bf;
    return head;
}

!!! One type byte of a `.bmeta`, which is the toolchain bmeta_to_vartype. A declaration
!!! file may mark a Windows value unsigned: the width is the one of the signed code
!!! and the backend computes on the same bytes, so the value passes through
!!! unchanged.
VarType cm_bmeta_type -> int b {
    switch b {
        case 0x01:
            return BOOL;
        case 0x02:
            return INT;
        case 0x08:
            return INT;
        case 0x03:
            return STR;
        case 0x04:
            return ANY;
        case 0x05:
            return CHAR;
        case 0x0A:
            return CHAR;
        case 0x06:
            return FLOAT;
        case 0x07:
            return LONG;
        case 0x09:
            return LONG;
        case 0x10:
            return AT_INT;
        case 0x11:
            return AT_FLOAT;
        case 0x12:
            return AT_CHAR;
        case 0x13:
            return AT_STR;
        case 0x14:
            return AT_VOID;
        case 0x15:
            return AT_BOOL;
        case 0x16:
            return FUNC;
        case 0x17:
            return AT_FUNC;
        case 0x18:
            return AT_LONG;
    }
    return VOID;
}

!!! The signatures of `dll`, or null when its `.bmeta` is not found. The three
!!! places are the ones the toolchain looks in: BLANG_HOME/meta, the meta directory one
!!! level up from it (where a compiler in bin/ finds the install) and meta/ under
!!! the working directory.
@CgBmetaFunc cg_read_bmeta -> str dll {
    str data = cm_open_side("meta", cm_base_name(dll) + ".bmeta");
    if data == null {
        return null;
    }
    if cm_len < 12 {
        return null;
    }
    if data[0] != 'B' || data[1] != 'L' || data[2] != 'M' || data[3] != 'T' {
        return null;
    }
    !!! The record count, little endian at bytes 6 and 7.
    int nrec = ((int)data[6] & 255) + (((int)data[7] & 255) * 256);
    cm_walk(data);
    cm_pos = 12;
    @CgBmetaFunc head = null;
    int i = 0;
    while i < nrec {
        if cm_pos >= cm_len {
            skip;
        }
        CgBmetaFunc proto;
        @CgBmetaFunc bf;
        cg_balloc(@bf, size proto);
        bf.name = "";
        bf.ret_type = VOID;
        bf.param_types = null;
        bf.next = null;
        if cm_pos + 1 > cm_len {
            skip;
        }
        int name_len = cm_u8();
        if cm_pos + name_len + 1 > cm_len {
            skip;
        }
        bf.name = cm_take(name_len);
        bf.ret_type = cm_bmeta_type(cm_u8());
        if cm_pos + 1 > cm_len {
            skip;
        }
        int pc = cm_u8();
        int j = 0;
        while j < pc {
            if cm_pos + 2 > cm_len {
                skip;
            }
            VarType pt = cm_bmeta_type(cm_u8());
            int pnl = cm_u8();
            if cm_pos + pnl > cm_len {
                skip;
            }
            cm_pos = cm_pos + pnl;
            bf.param_types = cn_type(bf.param_types, pt);
            j = j + 1;
        }
        head = cg_bmeta_add(head, bf);
        i = i + 1;
    }
    return head;
}
