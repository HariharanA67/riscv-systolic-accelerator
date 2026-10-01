# RISC-V + Systolic Array SoC

## Status
- [x] MAC unit (INT8 multiply-accumulate)
- [x] Processing Element (PE)
- [x] 4×4 Systolic Array
- [x] Simulation verified
- [ ] RISC-V softcore integration
- [ ] Firmware
- [ ] Full SoC synthesis

## To run simulation
cd sim
iverilog -g2009 -o tb_systolic ../rtl/mac_unit.v ../rtl/processing_element.v ../rtl/systolic_array_4x4.v tb_systolic_array.v
vvp tb_systolic

## Result
Identity × Identity = Identity (correct)

## Next steps
1. Integrate PicoRV32 softcore
2. Memory-mapped bus
3. Write RISC-V firmware (matmul_sw.c, matmul_accel.c)
4. Full SoC testbench
5. Synthesis for ULX3S (ECP5)
