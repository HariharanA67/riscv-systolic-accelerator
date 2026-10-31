`timescale 1ns / 1ps
module tb_soc_opt_check;
    reg clk = 0, rst = 1;
    soc_mini #(.ENABLE_MUL(1)) dut (.clk(clk), .rst(rst));
    always #5 clk = ~clk;

    localparam [31:0] FINAL_LOOP = 32'h8;
    localparam [31:0] JUMP_SELF  = 32'h0000006f;
    localparam integer MAX_CYCLES = 400000;
    localparam integer NEED_HITS  = 5;

    integer i, j, k, errors, cycles, loop_hits, accel_writes, accel_reads, nz_a, nz_b;
    reg signed [31:0] expected, got, a32, b32;

    always @(posedge clk) begin
        if (!rst && dut.mem_valid && dut.mem_instr && !dut.mem_ready) begin
            if (dut.mem_addr == FINAL_LOOP && dut.mem_rdata == JUMP_SELF)
                loop_hits <= loop_hits + 1;
            else
                loop_hits <= 0;
        end
    end

    always @(posedge clk) begin
        if (!rst && dut.mem_valid && !dut.mem_ready && dut.mem_addr[31]) begin
            if (|dut.mem_wstrb) accel_writes = accel_writes + 1;
            else                accel_reads  = accel_reads + 1;
        end
    end

    initial begin
        errors = 0; loop_hits = 0; cycles = 0;
        accel_writes = 0; accel_reads = 0;
        $readmemh("prog_opt.hex", dut.ram);
        #22 rst = 0;
        for (cycles = 0; cycles < MAX_CYCLES && loop_hits < NEED_HITS; cycles = cycles + 1)
            @(posedge clk);
        if (loop_hits < NEED_HITS) begin
            $display("OPT CHECK FAILED: did not reach finish loop within %0d cycles", MAX_CYCLES);
            $finish;
        end
        $display("OPT firmware reached finish loop after %0d cycles", cycles);
        $display("accelerator bus activity: %0d writes, %0d reads", accel_writes, accel_reads);

        // Input sanity: reject tests whose inputs are mostly zero
        nz_a = 0; nz_b = 0;
        for (i = 0; i < 16; i = i + 1) begin
            if (dut.ram[128 + i][7:0] != 0) nz_a = nz_a + 1;
            if (dut.ram[144 + i][7:0] != 0) nz_b = nz_b + 1;
        end
        $display("input check: %0d nonzero A values, %0d nonzero B values", nz_a, nz_b);
        if (nz_a < 8 || nz_b < 8) begin
            $display("OPT CHECK FAILED: inputs mostly zero, check would be meaningless");
            $finish;
        end

        // INT8 reference: the accelerator only uses the low byte of each value
        for (i = 0; i < 4; i = i + 1)
            for (j = 0; j < 4; j = j + 1) begin
                expected = 0;
                for (k = 0; k < 4; k = k + 1) begin
                    a32 = $signed(dut.ram[128 + i*4 + k][7:0]);
                    b32 = $signed(dut.ram[144 + k*4 + j][7:0]);
                    expected = expected + a32 * b32;
                end
                got = dut.ram[256 + i*4 + j];
                if (got !== expected) begin
                    errors = errors + 1;
                    $display("MISMATCH C[%0d][%0d]: got %0d expected %0d", i, j, got, expected);
                end
            end

        if (errors == 0 && accel_writes >= 33 && accel_reads >= 16)
            $display("OPT CHECK PASSED: accelerator computed correct INT8 C (%0d writes, %0d reads)", accel_writes, accel_reads);
        else
            $display("OPT CHECK FAILED: %0d mismatches, %0d accel writes, %0d accel reads", errors, accel_writes, accel_reads);
        $finish;
    end
endmodule
