    .section .init
    .globl _start
_start:
    li sp, 0x400          # stack pointer at top of 1 KB RAM region used by the program
    call main
1:  j 1b                  # if main returns, spin here (final loop)
