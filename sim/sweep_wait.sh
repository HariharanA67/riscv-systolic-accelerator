#!/bin/bash
# Wait-state sweep: seeds 1-100 with memory stalls, plus one no-stall baseline.
# Each run is recorded once in build_wait/results.csv: seed,stall,PASS|FAIL,stall_cycles
cd "$(dirname "$0")" || exit 2
OUT=build_wait
mkdir -p $OUT
RES=$OUT/results.csv
touch $RES
iverilog -g2009 -o $OUT/tb_wait tb_wait_check.v test_wrappers/soc_stall.v \
  ../rtl/picorv32.v ../rtl/accel_mmio.v ../rtl/systolic_os_4x4.v ../rtl/pe_os.v || exit 1
for seed in $(seq 1 100); do
  grep -q "^$seed,1," $RES && continue
  out=$(vvp $OUT/tb_wait +stall=1 +seed=$seed 2>&1)
  sc=$(echo "$out" | grep -o "stall_cycles=[0-9]*" | cut -d= -f2)
  if echo "$out" | grep -q "WAIT CHECK PASSED" && [ "${sc:-0}" -gt 0 ]; then st=PASS; else st=FAIL; fi
  echo "$seed,1,$st,${sc:-0}" >> $RES
done
if ! grep -q "^0,0," $RES; then
  out=$(vvp $OUT/tb_wait +stall=0 +seed=1 2>&1)
  if echo "$out" | grep -q "WAIT CHECK PASSED"; then st=PASS; else st=FAIL; fi
  echo "0,0,$st,0" >> $RES
fi
awk -F, '$2==1{n++; if($3=="PASS")p++; else f++; if(min==""||$4<min)min=$4; if($4>max)max=$4}
  END{printf "tb_wait stall=1: runs=%d passed=%d failed=%d stall_cycles min=%s max=%s\n", n,p,f,min,max}' $RES | tee $OUT/summary.txt
grep ",0,PASS," $RES >/dev/null && echo "baseline stall=0: PASS" || echo "baseline stall=0: FAIL"
