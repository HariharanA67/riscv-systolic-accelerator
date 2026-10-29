# RISC-V + Systolic Array SoC

## Status
- [x] MAC unit (INT8 multiply-accumulate)
- [x] Processing Element (PE)
- [x] 4×4 Systolic Array
- [x] Simulation verified (identity + random matrix tests, layout confirmed)
- [x] Synthesis to gate-level (Yosys)
- [x] Place & route for ECP5 45F (nextpnr-ecp5)
- [x] Timing closed: 50.47 MHz (25 MHz target, 2× margin)
- [x] Bitstream generated (`synth/build/systolic_top.bit`)
- [ ] RISC-V softcore integration
- [ ] Firmware
- [ ] Hardware testing (simulation-only, no board)

## To run simulation

## Result
SYSTOLIC TOP PASSED (6 serial runs)
- Identity matrix test: layout verified (row-major A and C)
- Random 8-bit signed matrices: correct products
- Extreme values (−128 × 127): sign handling verified

## Synthesis & P&R


Gate-level: 1492 flip-flops, 1282 LUT4s, 16 multipliers (MULT18X18D), 312 carry chains.
Timing: 50.47 MHz fmax, passes 25 MHz target with 2× margin.

## Next steps
1. Integrate PicoRV32 softcore
2. Memory-mapped bus to accelerator
3. Write RISC-V firmware (matmul_sw.c, matmul_accel.c)
4. Full SoC testbench
5. Synthesis for ULX3S (ECP5)
