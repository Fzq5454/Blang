#head "stdsrt"
#head "fileio"

!!! 写入 n 个零字节
void wzeros -> @void f, int n {
    int i = 0;
    while i < n {
        writeFileByte(f, 0);
        i++;
    }
}

!!! 小端写入 16 位
void w16 -> @void f, int v {
    writeFileByte(f, v % 256);
    writeFileByte(f, (v / 256) % 256);
}

!!! 小端写入 32 位
void w32 -> @void f, int v {
    writeFileByte(f, v % 256);
    writeFileByte(f, (v / 256) % 256);
    writeFileByte(f, (v / 65536) % 256);
    writeFileByte(f, (v / 16777216) % 256);
}

!!! 单个 DLL + 单个函数的导入表总字节数
!!! IDT(40) + ILT(16) + IAT(16) + hint/name(2+fn_len+1) + dll名(dll_len+1)
int imp_size -> int fn_len, int dll_len {
    return 76 + fn_len + dll_len;
}

!!! 在当前位置写一个 DLL 的导入描述符 + ILT/IAT + 名字，返回 IAT 的 RVA
!!! 布局：IDT[2项] ILT[2项] IAT[2项] hint/name dll名
!!! 注：函数名长度/DLL 名长度固定为 ExitProcess(11) / kernel32.dll(12)
int build_import -> @void f, str dll, str fn, int base {
    int ilt = base + 40;          !!! IDT 两项 (20+20)
    int iat = base + 56;          !!! + ILT 两项 (8+8)
    int hn  = base + 72;          !!! + IAT 两项 (8+8)
    int dln = base + 75 + 11;     !!! + hint(2) + 函数名(11) + null(1)

    !!! IDT[0]
    w32(f, ilt);   !!! OriginalFirstThunk
    w32(f, 0);     !!! TimeDateStamp
    w32(f, 0);     !!! ForwarderChain
    w32(f, dln);   !!! Name -> DLL 名字符串
    w32(f, iat);   !!! FirstThunk
    !!! IDT[1] 终止
    wzeros(f, 20);
    !!! ILT
    w32(f, hn); w32(f, 0);
    w32(f, 0);  w32(f, 0);
    !!! IAT
    w32(f, hn); w32(f, 0);
    w32(f, 0);  w32(f, 0);
    !!! hint/name
    writeFileByte(f, 0); writeFileByte(f, 0);
    writeFile(f, fn);
    writeFileByte(f, 0);
    !!! DLL 名
    writeFile(f, dll);
    writeFileByte(f, 0);

    return iat;
}

void main {
    @void f = getFile("tiny.exe", "w");

    !!! ===== DOS 头 (0x00 - 0x3F) =====
    writeFileByte(@f, 0x4D);   !!! 'M'
    writeFileByte(@f, 0x5A);   !!! 'Z'
    wzeros(@f, 0x16);          !!! 0x02..0x17
    w16(@f, 0x40);             !!! 0x18 e_lfarlc
    wzeros(@f, 0x22);          !!! 0x1A..0x3B
    w32(@f, 0x80);             !!! 0x3C e_lfanew

    !!! ===== DOS 存根 (0x40 - 0x7F) =====
    writeFileByte(@f, 0x0E); writeFileByte(@f, 0x1F); writeFileByte(@f, 0xBA); writeFileByte(@f, 0x0E);
    writeFileByte(@f, 0x00); writeFileByte(@f, 0xB4); writeFileByte(@f, 0x09); writeFileByte(@f, 0xCD);
    writeFileByte(@f, 0x21); writeFileByte(@f, 0xB8); writeFileByte(@f, 0x01); writeFileByte(@f, 0x4C);
    writeFileByte(@f, 0xCD); writeFileByte(@f, 0x21);
    writeFile(@f, "This program cannot be run in DOS mode.");
    writeFileByte(@f, 0x0D); writeFileByte(@f, 0x0D); writeFileByte(@f, 0x0A); writeFileByte(@f, 0x24);
    wzeros(@f, 7);

    !!! ===== PE 签名 (0x80 - 0x83) =====
    writeFileByte(@f, 0x50);   !!! 'P'
    writeFileByte(@f, 0x45);   !!! 'E'
    wzeros(@f, 2);

    !!! ===== COFF 头 (0x84 - 0x97) =====
    w16(@f, 0x8664);           !!! Machine AMD64
    w16(@f, 2);                !!! NumberOfSections = 2
    wzeros(@f, 12);            !!! TimeDateStamp/SymTable/NumSyms
    w16(@f, 0xF0);             !!! SizeOfOptionalHeader
    w16(@f, 0x22);             !!! Characteristics

    !!! ===== 可选头 (0x98 - 0x187) =====
    w16(@f, 0x20B);            !!! Magic PE32+
    wzeros(@f, 2);             !!! LinkerVersion
    w32(@f, 0x200);            !!! SizeOfCode
    wzeros(@f, 8);             !!! SizeOfInit/UninitData
    w32(@f, 0x1000);           !!! AddressOfEntryPoint
    w32(@f, 0x1000);           !!! BaseOfCode
    !!! ImageBase = 0x140000000 (64-bit)
    writeFileByte(@f, 0x00); writeFileByte(@f, 0x00); writeFileByte(@f, 0x00); writeFileByte(@f, 0x40);
    writeFileByte(@f, 0x01); writeFileByte(@f, 0x00); writeFileByte(@f, 0x00); writeFileByte(@f, 0x00);
    w32(@f, 0x1000);           !!! SectionAlignment
    w32(@f, 0x200);            !!! FileAlignment
    w16(@f, 6);                !!! MajorOSVersion
    w16(@f, 0);                !!! MinorOSVersion
    w16(@f, 0);                !!! MajorImageVersion
    w16(@f, 0);                !!! MinorImageVersion
    w16(@f, 6);                !!! MajorSubsystemVersion
    w16(@f, 0);                !!! MinorSubsystemVersion
    wzeros(@f, 4);             !!! Win32VersionValue
    w32(@f, 0x3000);           !!! SizeOfImage
    w32(@f, 0x200);            !!! SizeOfHeaders
    wzeros(@f, 4);             !!! CheckSum
    w16(@f, 3);                !!! Subsystem CUI
    w16(@f, 0x160);            !!! DllCharacteristics
    !!! SizeOfStackReserve = 0x100000
    writeFileByte(@f, 0x00); writeFileByte(@f, 0x00); writeFileByte(@f, 0x10); writeFileByte(@f, 0x00);
    writeFileByte(@f, 0x00); writeFileByte(@f, 0x00); writeFileByte(@f, 0x00); writeFileByte(@f, 0x00);
    !!! SizeOfStackCommit = 0x1000
    writeFileByte(@f, 0x00); writeFileByte(@f, 0x10); writeFileByte(@f, 0x00); writeFileByte(@f, 0x00);
    writeFileByte(@f, 0x00); writeFileByte(@f, 0x00); writeFileByte(@f, 0x00); writeFileByte(@f, 0x00);
    !!! SizeOfHeapReserve = 0x100000
    writeFileByte(@f, 0x00); writeFileByte(@f, 0x00); writeFileByte(@f, 0x10); writeFileByte(@f, 0x00);
    writeFileByte(@f, 0x00); writeFileByte(@f, 0x00); writeFileByte(@f, 0x00); writeFileByte(@f, 0x00);
    !!! SizeOfHeapCommit = 0x1000
    writeFileByte(@f, 0x00); writeFileByte(@f, 0x10); writeFileByte(@f, 0x00); writeFileByte(@f, 0x00);
    writeFileByte(@f, 0x00); writeFileByte(@f, 0x00); writeFileByte(@f, 0x00); writeFileByte(@f, 0x00);
    wzeros(@f, 4);             !!! LoaderFlags
    w32(@f, 16);               !!! NumberOfRvaAndSizes
    !!! 数据目录[0] 导出表 (全零)
    wzeros(@f, 8);
    !!! 数据目录[1] 导入表: RVA 0x2000, Size 由 imp_size 计算
    w32(@f, 0x2000);
    w32(@f, imp_size(11, 12));
    !!! 数据目录[2..15]
    wzeros(@f, 112);

    !!! ===== 节表 (0x188 - 0x1D7) =====
    !!! 节 1: .text
    writeFileByte(@f, 0x2E); writeFileByte(@f, 0x74); writeFileByte(@f, 0x65);
    writeFileByte(@f, 0x78); writeFileByte(@f, 0x74);   !!! ".text"
    wzeros(@f, 3);
    w32(@f, 0x1000);           !!! VirtualSize
    w32(@f, 0x1000);           !!! VirtualAddress
    w32(@f, 0x200);            !!! SizeOfRawData
    w32(@f, 0x200);            !!! PointerToRawData
    wzeros(@f, 12);
    w32(@f, 0x60000020);       !!! Characteristics
    !!! 节 2: .idata
    writeFileByte(@f, 0x2E); writeFileByte(@f, 0x69); writeFileByte(@f, 0x64);
    writeFileByte(@f, 0x61); writeFileByte(@f, 0x74); writeFileByte(@f, 0x61);  !!! ".idata"
    wzeros(@f, 2);
    w32(@f, 0x1000);           !!! VirtualSize
    w32(@f, 0x2000);           !!! VirtualAddress
    w32(@f, 0x200);            !!! SizeOfRawData
    w32(@f, 0x400);            !!! PointerToRawData
    wzeros(@f, 12);
    w32(@f, 0xC0000040);       !!! Characteristics

    !!! ===== 头补齐到 0x200 =====
    wzeros(@f, 0x28);          !!! 0x1D8..0x1FF

    !!! ===== .text 代码 (0x200) =====
    int iat = 0x2000 + 56;     !!! IAT RVA = 节基址 + IDT(40) + ILT(16)
    int disp = iat - 0x100C;   !!! call 的下一条指令 RVA = 0x100C
    writeFileByte(@f, 0x48); writeFileByte(@f, 0x83); writeFileByte(@f, 0xEC); writeFileByte(@f, 0x28);  !!! sub rsp, 40
    writeFileByte(@f, 0x31); writeFileByte(@f, 0xC9);  !!! xor ecx, ecx
    writeFileByte(@f, 0xFF); writeFileByte(@f, 0x15);  !!! call [rip+disp32]
    w32(@f, disp);
    wzeros(@f, 0x1F4);         !!! 补齐 .text 到 0x200

    !!! ===== .idata 导入表 (0x400) =====
    build_import(@f, "kernel32.dll", "ExitProcess", 0x2000);
    wzeros(@f, 0x200 - imp_size(11, 12));

    system.out("tiny.exe written\n");
}
