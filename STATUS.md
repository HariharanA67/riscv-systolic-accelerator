# Project Status - October 9, 2026

## What Works
✅ Systolic array RTL compiles and simulates
✅ RISC-V toolchain (gcc 16.1.0)
✅ Firmware compiles to binary

## What Needs Work
⚠️ Systolic array input/output timing (pipeline not filling correctly with batch data)
⚠️ PicoRV32 memory interface not responding in simulation
⚠️ Full system integration pending

## Next Phase
- Redesign systolic array for proper batch matmul (fix B input routing)
- Or: Skip SoC integration, focus on pure RTL accelerator performance
- Measure real vs expected cycle counts

## Time Investment
- RTL design: 6 hours
- Simulation & debugging: 8 hours
- Firmware/toolchain: 4 hours
**Total: ~18 hours**
