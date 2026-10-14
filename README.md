# INT8 Output-Stationary Systolic Matrix Multiplier (4x4) with PicoRV32

A Verilog design that multiplies two 4x4 signed INT8 matrices into 32-bit results.
A PicoRV32 RISC-V core drives the accelerator through memory-mapped registers.
A serial-I/O wrapper is also provided for a small FPGA pin count.

## Status (simulation only; no hardware run)

### Verified in simulation (Icarus Verilog)
- `rtl/systolic_os_4x4.v` + `rtl/pe_os.v`: output-stationary array. Random, stress,
  and structured-pattern tests (`sim/tb_systolic_os_flat.v`, `sim/tb_systolic_patterns.v`).
- `rtl/systolic_top.v`: serial-I/O wrapper. Reset and back-to-back tests, a 1,000-run
  seed sweep, host-misuse tests, and fault tests (`sim/tb_systolic_top*.v`,
  `sim/tb_systolic_misuse*.v`, `sim/tb_systolic_sweep.v`, `sim/tb_systolic_faults.v`).
  Host protocol: `docs/host_protocol.md`. Start-to-done is 11 cycles (`sim/tb_timing.v`).
- `rtl/soc_mini.v` + `rtl/accel_mmio.v`: PicoRV32 SoC with the accelerator at 0x8000_0000.
  `ENABLE_MUL` defaults to 1. Runs a generated program (`sim/gen_prog.py`), compiled C
  firmware (`firmware/matmul.c`), and two software baselines (`firmware/matmul_sw.c`,
  `firmware/matmul_sw_mul.c`). All produce correct 4x4 products.

### Performance (simulation, whole-program cycles, PicoRV32)
| Path | Cycles (8 seeds) |
|---|---|
| Accelerator (compiled C) | 1,534 on every seed |
| Software, hardware MUL | 5,404 on every seed |
| Software, shift-and-add (no MUL) | 25,522 to 27,893 |

Against the best software written here, the accelerator path is about 3.5x faster on
this core and these kernels. A hand-optimized kernel could narrow the gap; not tested.
Timing includes the CPU copying A, B, and C.

### Synthesis and place-and-route (Yosys + nextpnr-ecp5, LFE5U-45F, 25 MHz target)
- `systolic_top`: 7 I/O pins, 16 of 72 multipliers, 49.16 MHz estimate.
- `soc_fit` (full SoC): 3 I/O pins, 16 of 72 multipliers, 2 of 108 block RAMs, 47.05 MHz estimate.
These are nextpnr estimates, not hardware measurements.

## Not done
- No hardware run. `constraints/ulx3s_systolic.lpf` and `constraints/pin_map.csv` are
  reference material only.
- The array is 4x4 only; it is not parameterized.
- The wrapper does not detect host data errors or short/long reads (by design; see spec).

## Run the simulations

## Layout
- `rtl/` RTL modules
- `sim/` testbenches, program and hex generators
- `firmware/` C firmware, startup code, linker script
- `docs/` host protocol spec and architecture diagram
- `constraints/` ULX3S pin constraints and pin map (reference)
- `synth/`, `firmware/README.md` placeholders
