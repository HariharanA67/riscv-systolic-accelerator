# INT8 Output-Stationary Systolic Matrix Multiplier (4x4)

A Verilog RTL block that multiplies two 4x4 signed INT8 matrices and produces
32-bit results, with serial I/O suitable for a small FPGA pin count.

## Status

Verified in simulation (Icarus Verilog):
- `rtl/matmul_simple.v`: reference-style 4x4 matrix multiply, checked against
  a testbench reference (identity, -128 x -128 corner case, 20 random pairs).
- `rtl/systolic_os_4x4.v` with `rtl/pe_os.v`: output-stationary array with
  skewed inputs, checked against reference matmul (one fixed pattern and
  six back-to-back stress runs).
- `rtl/systolic_top.v`: serial-I/O wrapper (LOAD / RUN / READ FSM), checked
  over six runs with reset and six back-to-back runs without reset.

Synthesis and place-and-route (Yosys + nextpnr-ecp5, LFE5U-45F, 25 MHz target):
- `systolic_top` fits: 7 I/O pins, 16 of 72 multipliers, 45.7 MHz estimate.
  This is a fit and timing estimate, not a hardware test.

## Not yet done
- No pin constraints (LPF) for the ULX3S; the design has not run on hardware.
- PicoRV32 integration is unfinished (`rtl/soc_top.v`, `rtl/soc_top_wb.v`). The
  RISC-V core does not fetch instructions in simulation.
- No firmware runs on the SoC.
- No tests for host misbehaviour (early start, wrong bit counts).

## Run the simulation

## Layout
- `rtl/` RTL modules
- `sim/` self-checking testbenches
- `firmware/` placeholder (no working firmware yet)
- `synth/` placeholder
