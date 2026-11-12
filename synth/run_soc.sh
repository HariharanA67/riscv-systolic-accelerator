#!/bin/bash
# Full-SoC fit check for ECP5 (soc_fit = PicoRV32 + RAM + accelerator).
# Post-route fmax from nextpnr is an estimate, not a hardware measurement.
set -o pipefail
cd "$(dirname "$0")/.."
mkdir -p build/soc
SRC="rtl/soc_fit.v rtl/soc_mini.v rtl/picorv32.v rtl/accel_mmio.v rtl/systolic_os_4x4.v rtl/pe_os.v"
yosys -q -l build/soc/yosys.log -p "read_verilog $SRC; hierarchy -check -top soc_fit; synth_ecp5 -top soc_fit -json build/soc/soc_fit.json"
nextpnr-ecp5 --45k --package CABGA381 --speed 6 --freq 25 \
  --json build/soc/soc_fit.json --textcfg build/soc/soc_fit_out.config 2>&1 | tee build/soc/pnr.log
ecppack build/soc/soc_fit_out.config build/soc/soc_fit.bit
echo "--- post-route fmax (last line is the one to report) ---"
grep "Max frequency" build/soc/pnr.log
