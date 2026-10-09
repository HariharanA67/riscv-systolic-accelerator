# RISC-V Systolic Accelerator SoC — Progress Report

## ✅ Completed
1. **Systolic Array RTL** — 4×4 INT8 systolic array with MAC units, processing elements, verified with testbench
2. **RISC-V Toolchain** — riscv32-unknown-elf-gcc working (GCC 16.1.0)
3. **Firmware Compilation** — matmul.c compiles to valid RISC-V ELF binary
4. **SoC Top-Level** — PicoRV32 + RAM integrated

## ⏳ In Progress
- PicoRV32 instruction fetch not working in simulation
- Need to debug mem_ready, mem_valid handshake

## Next Steps
1. Fix PicoRV32 memory interface (likely need formal specs)
2. Alternatively: use simpler RISC-V core or direct RTL simulation
3. Measure systolic array speedup vs software matmul
4. Synthesis for ULX3S ECP5

## Files
- `rtl/soc_top.v` — Top-level SoC
- `firmware/matmul.c` → `matmul.elf` → `matmul.bin`
- `sim/tb_soc_firmware.v` — Full-system testbench
