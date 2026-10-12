OUTPUT_ARCH("riscv")
ENTRY(_start)
MEMORY {
    ROM (rx) : ORIGIN = 0x00000000, LENGTH = 0x200
    RAM (rw) : ORIGIN = 0x00000200, LENGTH = 0x600
}
SECTIONS {
    .text : { *(.init) *(.text*) } > ROM
    .data : { *(.data*) } > RAM
    .bss  : { *(.bss*) *(COMMON) } > RAM
}
