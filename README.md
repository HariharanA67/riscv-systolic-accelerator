# INT8 Output-Stationary Systolic Matrix Multiplier (4x4) with PicoRV32

A Verilog design that multiplies two 4x4 signed INT8 matrices into 32-bit results.
A PicoRV32 RISC-V core runs firmware (compiled C, or a generated program) that drives
the accelerator through memory-mapped registers. A serial-I/O wrapper is also provided
for a small FPGA pin count.

## Status

### Verified in simulation (Icarus Verilog)
- `rtl/matmul_simple.v`: 4x4 multiply checked against a reference (identity, -128 x -128,
  20 random pairs).
- `rtl/systolic_os_4x4.v` + `rtl/pe_os.v`: output-stationary array with skewed inputs,
  checked against reference matmul (`sim/tb_systolic_os_flat.v`).
- `rtl/systolic_top.v`: serial-I/O wrapper, 6 runs with reset and 6 back-to-back runs
  without reset (`sim/tb_systolic_top.v`, `sim/tb_systolic_top_noreset.v`).
- PicoRV32 (`rtl/picorv32.v`, upstream YosysHQ core): fetch and store verified with
  hand-encoded programs (`sim/tb_cpu_fetch.v`, `sim/tb_cpu_store.v`).
- `rtl/soc_mini.v` + `rtl/accel_mmio.v`: SoC with the accelerator at `0x8000_0000`.
  - Generated program (`sim/gen_prog.py`): copies A and B, starts the array, polls done,
    copies C back. Results match the reference (`sim/tb_soc_mini.v`), data seeds 7, 1, 2, 3.
  - Compiled C firmware (`firmware/matmul.c`, `start.S`, `link.ld`, built with
    `riscv32-unknown-elf-gcc -march=rv32i -nostdlib`): same operation, results match for
    eight data seeds (`sim/tb_soc_c.v`, `sim/make_c_hex.py`).
  - Software baseline (`firmware/matmul_sw.c`): same product in C with shift-and-add
    multiplication, since the core has no MUL instruction. Results match for eight seeds
    (`sim/tb_soc_sw.v`, `sim/make_sw_hex.py`).

### Performance (simulation only, whole-program cycles)
Measured from start of the program to its final loop, including the CPU copying A, B, and C.

| Path | Cycles (8 seeds) |
|---|---|
| Accelerator firmware | 1,534 on every seed |
| Software baseline | 25,522 to 27,893 |

Speedup: about 16.6x to 18.2x. This is against a PicoRV32 configuration without a
multiply instruction. A core with MUL would narrow the gap. The array's compute time
alone was not measured separately.

### Synthesis and place-and-route (Yosys + nextpnr-ecp5, LFE5U-45F, 25 MHz target)
- `systolic_top`: 7 I/O pins, 16 of 72 multipliers, 45.7 MHz estimate.
- `soc_fit` (full SoC, observed through one XOR output): 3 I/O pins, 16 of 72 multipliers,
  2 of 108 block RAMs, 47 MHz estimate.
These are nextpnr estimates, not measurements on hardware. The C firmware path has not
been resynthesized with the final RTL.

## Not yet done
- Nothing has been run on the physical ULX3S board. `constraints/ulx3s_systolic.lpf`
  and `constraints/pin_map.csv` are reference material only.
- Host misbehavior (early start, wrong bit counts) is not tested.
- Software and accelerator timings were measured on one fixed testbench schedule; the
  4x4 size only.
- Place-and-route has not been rerun on the final RTL.

## Run the simulations
The firmware binaries are built with:

## Layout
- `rtl/` RTL modules
- `sim/` testbenches, program and hex generators
- `firmware/` C firmware, startup code, linker script
- `constraints/` ULX3S pin constraints and pin map (reference)
- `docs/` architecture diagram
- `synth/` placeholder
