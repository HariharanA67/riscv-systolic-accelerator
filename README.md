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
  - `sim/tb_systolic_misuse3.v`: repeated-start and accumulate-cycle cases, PASSED.
  - `sim/tb_systolic_b2b.v`: 8 back-to-back runs with no reset between, PASSED. A mutant with the accumulator clear removed fails runs 2–8 (16 of 16 outputs wrong in each).
  - `sim/tb_timing.v`: start-to-done is 11 cycles.

#### PicoRV32 core and SoC
- `rtl/soc_mini.v` + `rtl/accel_mmio.v`: PicoRV32 SoC with the accelerator at 0x8000_0000. `ENABLE_MUL` defaults to 1.
- Firmware checked in simulation: `matmul_sw` (`tb_soc_sw`, 26,053 cycles) and `matmul_opt` (`tb_soc_opt_check`, 1,349 cycles), both on seed-7 data. The compiled-C `matmul.c` is not re-verified here.
- Wait-state test (`sim/tb_wait_check.v`, stall wrapper in `sim/test_wrappers/`, not `rtl/`): 39 words checked against `expect_arith_add_0.txt`. Baseline 1,089 cycles; stalled 1,219 cycles with 377 stall cycles (random seed per run). Both pass. The stall wrapper is a test-only copy of `soc_mini` and is not part of the RTL.

- ISA: 30 family programs via `run_families.sh` (871 checks, 0 wrong); full-ISA program `prog_isa.hex` (99 checks, 0 wrong).

- Full SoC (`rtl/soc_fit.v`, synthesis top): wraps `soc_mini` with an XOR reduction of the accelerator output. Optimized-firmware matmul is checked on `soc_mini` by `sim/tb_soc_opt_check.v` (passes; an A-path mutant fails).

### Performance (simulation, seed-7 data, whole-program cycles, PicoRV32)
| Path | Cycles |
|---|---|
| Accelerator, optimized C (`tb_soc_opt_check`) | 1,349 |
| Software, shift-and-add (`tb_soc_sw`) | 26,053 |

Simulation only. The two rows are different programs, so this is not a controlled speedup comparison. Timing includes the CPU copying A, B, and C. No hardware-MUL baseline was run in this session.

### Synthesis and place-and-route (Yosys + nextpnr-ecp5, LFE5U-45F, 25 MHz target)
- `systolic_top` (LFE5U-45F, CABGA381): post-route fmax 52.85 MHz at 25 MHz target (`synth/run_synth.sh`, nextpnr-ecp5 0.10). Place-and-route estimate only, not measured on hardware. Wrapper only, not the full SoC.
- `soc_fit` (full SoC: PicoRV32 + 4 KB RAM + accelerator, LFE5U-45F, CABGA381): post-route fmax 54.73 MHz at 25 MHz target (`synth/run_soc.sh`). Utilization: 4,583 LUT4 (10%), 1,868 FF (4%), 16 MULT18X18D (22%), 2 DP16KD (1%). Place-and-route estimate only, not measured on hardware.

## Not done
- No hardware run. `constraints/ulx3s_systolic.lpf`, `constraints/pin_map.csv`, and `constraints/soc_fit.lpf` are reference material; pin mapping is not verified against a board.
- Wait-state test covers seeds 42 and 7 only; the 100-seed range has not been run.
- The array is 4x4 only; it is not parameterized.
- The wrapper does not detect host data errors or short/long reads (by design; see spec).

## How to regenerate generated files
These files are gitignored and rebuilt from source:

- ISA chunks (13 programs with expected values and final addresses):
  `cd sim && python3 gen_isa_split.py`
- Firmware hex (from the linked ELF):
  `riscv32-unknown-elf-objcopy -O binary firmware/matmul_opt.elf /tmp/opt.bin && python3 gen_opt_hex.py`
  (same pattern for `matmul_sw_mul.elf` with `gen_swmul_hex.py`)
- Testbench binaries: `iverilog -g2009 -o <name> ...` (see "Run the simulations")

- Firmware ELFs are optional to rebuild; the committed `sim/prog_*.hex` files are the reference inputs. See `firmware/README.md`.

## Layout
- `rtl/` RTL modules
- `sim/` testbenches, program and hex generators
- `firmware/` C firmware, startup code, linker script
- `docs/` host protocol spec and architecture diagram
- `constraints/` ULX3S pin constraints and pin map (reference)
- `synth/` synthesis script and build outputs

## Run the simulations
 - `bash sim/run_families.sh`: runs the 30 `gen_families.py` programs (871 checks) with their matching inputs; prints `RESULT: ALL FAMILY CHECKS PASSED`.
 - ISA chunks: `cd sim && python3 gen_isa_split.py`, then run each `prog_isa<k>.hex` with its matching `expect_isa<k>.txt` and `final_addr_isa<k>.txt` via `+hex= +exp= +fin=`.
