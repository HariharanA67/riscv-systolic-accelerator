# INT8 Output-Stationary Systolic Matrix Multiplier (4x4) with PicoRV32

A Verilog design that multiplies two 4x4 signed INT8 matrices into 32-bit results.
A PicoRV32 RISC-V core drives the accelerator through memory-mapped registers.
A serial-I/O wrapper is also provided for a small FPGA pin count.

## Status (simulation only; no hardware run)

### Verified in simulation (Icarus Verilog)

#### Accelerator and wrapper
- `rtl/systolic_os_4x4.v` + `rtl/pe_os.v`: output-stationary 4x4 array. Verified with
  `sim/tb_systolic_os_flat.v` (PASSED) and `sim/tb_systolic_patterns.v` (patterns P1–P5, PASSED).
- `rtl/systolic_top.v`: serial-I/O wrapper.
  - `sim/tb_systolic_top.v`: 6 serial runs (random, extreme-value, identity), PASSED.
  - `sim/tb_systolic_sweep.v`: 1000 runs, 0 failed, PASSED.
  - `sim/tb_systolic_faults.v`: 3 fault cases, PASSED.
  - `sim/tb_systolic_misuse.v`: 5 host-misuse cases, PASSED.
  - `sim/tb_systolic_misuse2.v`: 2 cases (start during RUN and READ), PASSED.
  - `sim/tb_systolic_misuse3.v`: repeated-start cases, PASSED.
  - `sim/tb_systolic_b2b.v`: 8 back-to-back runs with no reset between, PASSED. A mutant with the accumulator clear removed fails runs 2–8 (16 of 16 outputs wrong in each).
  - `sim/tb_timing.v`: start-to-done is 11 cycles.

#### PicoRV32 core and SoC
- `rtl/soc_mini.v` + `rtl/accel_mmio.v`: PicoRV32 SoC with the accelerator at 0x8000_0000. `ENABLE_MUL` defaults to 1.
- Compiled C firmware (`firmware/matmul.c`) and a shift-and-add software baseline (`firmware/matmul_sw.c`) both pass in simulation (`tb_soc_c`, `tb_soc_sw`).
- Wait-state test (`sim/tb_wait_check.v`, stall wrapper in `sim/test_wrappers/`, not `rtl/`): 39 words checked against `expect_arith_add_0.txt`. Baseline 1,089 cycles; stalled 1,219 cycles with 377 stall cycles (random seed per run). Both pass. The stall wrapper is a test-only copy of `soc_mini` and is not part of the RTL.

- ISA coverage (`sim/gen_isa_full.py` via `sim/gen_isa_split.py`): 1045 checks in 13 chunks, 0 wrong on `sim/tb_isa_family.v`. Run each chunk with its matching `+hex= +exp= +fin=` files.

### Performance (simulation, whole-program cycles, PicoRV32, single run)
| Path | Cycles |
|---|---|
| Accelerator, compiled C (`tb_soc_c`) | 1,534 |
| Accelerator, optimized C (`tb_soc_opt`) | 1,327 |
| Software, hardware MUL (`tb_soc_swmul`) | 5,382 |
| Software, shift-and-add (`tb_soc_sw`) | 26,053 |

All four were checked against the expected product (one input set). Versus the hardware-MUL software, the optimized accelerator path used about 4x fewer cycles (simulation only). Timing includes the CPU copying A, B, and C.

### Synthesis and place-and-route (Yosys + nextpnr-ecp5, LFE5U-45F, 25 MHz target)
- `systolic_top` (LFE5U-45F, CABGA381): fmax 50.32 MHz at 25 MHz target (lowest value in nextpnr log, `synth/pnr.log`). Place-and-route estimate only, not measured on hardware. This is for the wrapper only, not the full SoC.
- `soc_fit` (full SoC: PicoRV32 + accelerator, LFE5U-45F, CABGA381): Yosys synth_ecp5 succeeds (1868 TRELLIS_FF, 3321 LUT4, 16 MULT18X18D, 2 DP16KD). nextpnr fmax 53.22 MHz at 25 MHz target (lowest value in nextpnr log, `synth/pnr_soc.log`). Place-and-route estimate only, not measured on hardware.
## Not done
- No hardware run. `constraints/ulx3s_systolic.lpf` and `constraints/pin_map.csv` are reference material only.

- The array is 4x4 only; it is not parameterized.
- The wrapper does not detect host data errors or short/long reads (by design; see spec).

## Layout
- `rtl/` RTL modules
- `sim/` testbenches, program and hex generators
- `firmware/` C firmware, startup code, linker script
- `docs/` host protocol spec and architecture diagram
- `constraints/` ULX3S pin constraints and pin map (reference)
- `synth/` synthesis script and build outputs