# systolic_top host protocol

## Interface
- clk: rising-edge clock.
- rst: synchronous, active high. Clears all state, including the loaded flag and the read position.
- din: one data bit, sampled on rising clk edges where shift_en is high in LOAD.
- shift_en: host strobe. In LOAD it shifts one input bit per clock. In READ, each rising edge shifts out one output bit.
- start: pulse high for one clock to begin a run.
- done: high after the array finishes, until the read completes.
- dout: current output bit, MSB first (valid after done).

## Sequence for one matrix multiply
1. Assert rst for at least one clock (required once at power-up; optional between runs).
2. Send 256 bits in LOAD: 128 bits of A, then 128 bits of B. Each block is sent MSB first (bit 127 first). Hold shift_en high for exactly one clock per bit.
3. Pulse start for one clock. Accepted only after all 256 bits are in.
4. Wait for done to go high.
5. Read 512 bits of C. Sample dout, then produce one rising edge on shift_en (low, high, low). Repeat 512 times, MSB first. C element e is at bits [e*32 +: 32], row-major (element 0 = C[0][0], element 15 = C[3][3]).
6. After the 512th bit, the wrapper returns to LOAD and is ready for the next run.

## Host rules
- Drop shift_en between bits. Each rising edge of shift_en in READ shifts one bit.
- Do not rely on dout before done.
- Bits sent beyond 256 in LOAD are ignored.
- start outside a full load is ignored, including during RUN and READ.
- shift_en during RUN has no effect.

## Not checked by the wrapper
- The data the host sends. A wrong or changed byte gives a wrong, self-consistent result.
- Short or long reads. The host must count 512 bits.
- Operands are signed INT8; products and sums are 32-bit signed.

## Timing
- done rises 10 cycles after start (9-cycle skewed feed plus capture).
