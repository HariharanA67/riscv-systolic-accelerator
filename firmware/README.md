# Firmware

Reference inputs for the simulation testbenches are the hex files committed in `sim/`:
`sim/prog_c.hex`, `sim/prog_opt.hex`, `sim/prog_sw.hex`, `sim/prog_swmul.hex`.
The reported cycle counts (1,512; 1,327; 25,838 at seed 7 with range 22,103–32,238; 5,382) come from these files.

Rebuilding the ELF from `*.c`, `start.S`, and `link.ld` is optional. The toolchain flags used for the
original ELFs are not recorded, and a rebuild with `-march=rv32im -mabi=ilp32 -O2` did not reproduce the
original binary byte-for-byte, so cycle counts may change. Do not use a rebuilt ELF for reported numbers
until its hex reproduces the values above.
