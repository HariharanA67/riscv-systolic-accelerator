#!/bin/bash
# Reproduce systolic_top synthesis + place & route for ECP5 (simulation-only claim: fmax estimate).
set -e
cd "$(dirname "$0")"
mkdir -p build
yosys -l synth_systolic.log synth_systolic.ys
nextpnr-ecp5 --45k --package CABGA381 --speed 6 --freq 25 \
  --json build/systolic_top.json --textcfg build/systolic_top_out.config 2>&1 | tee pnr.log
ecppack build/systolic_top_out.config build/systolic_top.bit 2>&1 | tee ecppack.log
echo "--- fmax lines ---"
grep "Max frequency" pnr.log
