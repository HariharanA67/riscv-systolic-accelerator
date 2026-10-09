# RISC-V + Systolic Array Accelerator SoC

## Overview
Custom hardware accelerator for 4×4 INT8 matrix multiplication, integrated with PicoRV32 RISC-V core on a single SoC.

## Architecture

### Components
1. **Systolic Array (4×4)** — Parallel INT8 MAC units with pipelined processing elements
2. **PicoRV32 Core** — 32-bit RISC-V processor
3. **Memory Subsystem** — 4KB dual-port RAM
4. **UART Interface** — Serial communication (stub)

### Verified Results
- ✅ Systolic array: Identity × Identity = Identity (correct)
- ✅ RISC-V toolchain: riscv32-unknown-elf-gcc 16.1.0 working
- ✅ Firmware compilation: C→ELF→binary pipeline functional
- ⏳ Full system integration: in progress (PicoRV32 mem interface debugging)

## Simulation Status
- Systolic array testbench: **PASSING** (210ns runtime)
- SoC top-level testbench: **BUILDING** (memory interface refinement needed)

## Target Hardware
- **FPGA**: ULX3S (Lattice ECP5-12F)
- **Toolchain**: Yosys + nextpnr-ecp5
- **Language**: Verilog (IEEE 2009)

## Project Files

## Next Milestones
1. Fix PicoRV32 instruction fetch
2. Run full-system simulation with firmware
3. Measure speedup (SW cycles vs accelerator)
4. Synthesis for ULX3S
5. KiCad PCB design (power delivery, FTDI breakout)

---
**Repository**: https://github.com/HariharanA67/riscv-systolic-accelerator
**Status**: Active development
