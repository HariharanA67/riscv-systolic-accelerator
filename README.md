# INT8 Output-Stationary Systolic Matrix Multiplier (4x4) with PicoRV32

A Verilog design that multiplies two 4x4 signed INT8 matrices into 32-bit results.
A PicoRV32 RISC-V core drives the accelerator through memory-mapped registers.
A serial-I/O wrapper is also provided for a small FPGA pin count.

## Status (simulation only; no hardware run)

### Verified in simulation (Icarus Verilog)

#### Accelerator and wrapper
- `rtl/systolic_os_4x4.v` + `rtl/pe_os.v`: output-stationary 4x4 array. Verified with
  `sim/tb_systolic_os_flat.v` and `sim/tb_systolic_patterns.v`.
- `rtl/systolic_top.v`: serial-I/O wrapper.
  - `sim/tb_systolic_top.v`: 6 serial runs (random, extreme-value, identity), PASSED.
  - `sim/tb_systolic_sweep.v`: 1000 runs, 0 failed, PASSED.
  - `sim/tb_systolic_faults.v`: 3 fault cases, PASSED.
  - `sim/tb_systolic_misuse.v`: 5 host-misuse cases, PASSED.
  - `sim/tb_timing.v`: start-to-done is 11 cycles.
- Host protocol: `docs/host_protocol.md`.

#### PicoRV32 core and SoC
- `rtl/soc_mini.v` + `rtl/accel_mmio.v`: PicoRV32 SoC with the accelerator at 0x8000_0000. `ENABLE_MUL` defaults to 1.
- Compiled C firmware (`firmware/matmul.c`) and a shift-and-add software baseline (`firmware/matmul_sw.c`) both pass in simulation (`tb_soc_c`, `tb_soc_sw`).
- ISA family test (`sim/tb_isa_family.v`): **currently FAILS** (no final loop within 60000 cycles; 0/30 per `docs/simulation_evidence.md`). Under investigation.

### Performance (simulation, whole-program cycles, PicoRV32, single run)

| Path | Cycles |
|---|---|
| Accelerator (compiled C, `tb_soc_c`) | 1,534 |
| Software, shift-and-add (`tb_soc_sw`) | 26,053 |

The accelerator path used about 17x fewer cycles than the shift-and-add software in this repo (simulation only). The hardware-MUL baseline and a hand-optimized kernel (`matmul_opt.c`) have not been measured. Timing includes the CPU copying A, B, and C.

### Synthesis and place-and-route (Yosys + nextpnr-ecp5, LFE5U-45F, 25 MHz target)
- `systolic_top` (LFE5U-45F, CABGA381): fmax 50.47 MHz (lowest reported in the nextpnr log) at 25 MHz target. This is for the wrapper only, not the full SoC.
- These are nextpnr estimates, not hardware measurements.

## Not done
- No hardware run. `constraints/ulx3s_systolic.lpf` and `constraints/pin_map.csv` are reference material only.
- Full-SoC synthesis and timing have not been run.
- The ISA family test is failing (see above).
- The array is 4x4 only; it is not parameterized.
- The wrapper does not detect host data errors or short/long reads (by design; see spec).
- Reset/back-to-back and `misuse2`/`misuse3` tests not yet run.

## Layout
- `rtl/` RTL modules
- `sim/` testbenches, program and hex generators
- `firmware/` C firmware, startup code, linker script
- `docs/` host protocol spec and architecture diagram
- `constraints/` ULX3S pin constraints and pin map (reference)
- `synth/` synthesis script and build outputs