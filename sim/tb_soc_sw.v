`timescale 1ns / 1ps
module tb_soc_sw;
    reg clk = 0, rst = 1;
    soc_mini dut (.clk(clk), .rst(rst));
    always #5 clk = ~clk;

    localparam [31:0] FINAL_LOOP = 32'h8;      // "j 8" after main returns (_start)
    localparam [31:0] JUMP_SELF  = 32'h0000006f;
    localparam integer MAX_CYCLES = 400000;
    localparam integer NEED_HITS  = 5;

    integer i, j, k, errors, cycles, loop_hits, first_loop_cycle, c_writes;
    reg signed [31:0] expected, got, a_val, b_val;

    always @(posedge clk) begin
        if (!rst && dut.mem_valid && dut.mem_instr && !dut.mem_ready) begin
            if (dut.mem_addr == FINAL_LOOP && dut.mem_rdata == JUMP_SELF) begin
                loop_hits <= loop_hits + 1;
                if (first_loop_cycle < 0) first_loop_cycle = cycles;
            end else begin
                loop_hits <= 0;
            end
        end
    end

    always @(posedge clk) begin
        if (!rst && dut.mem_valid && !dut.mem_instr && !dut.mem_ready && |dut.mem_wstrb
            && dut.mem_addr[31] == 1'b0 && dut.mem_addr[11:2] >= 10'd256 && dut.mem_addr[11:2] < 10'd272
            && first_loop_cycle < 0)
            c_writes = c_writes + 1;
    end

    initial begin
        errors = 0; loop_hits = 0; first_loop_cycle = -1; c_writes = 0; cycles = 0;
        $readmemh("prog_sw.hex", dut.ram);
        #22 rst = 0;
        for (cycles = 0; cycles < MAX_CYCLES && loop_hits < NEED_HITS; cycles = cycles + 1)
            @(posedge clk);
        if (loop_hits < NEED_HITS) begin
            $display("SW FIRMWARE FAILED: did not reach finish loop within %0d cycles", MAX_CYCLES);
            $finish;
        end
        $display("SW firmware reached finish loop after %0d cycles (first fetch at cycle %0d)", cycles, first_loop_cycle);
        for (i = 0; i < 4; i = i + 1)
            for (j = 0; j < 4; j = j + 1) begin
                expected = 0;
                for (k = 0; k < 4; k = k + 1) begin
                    a_val = dut.ram[128 + i*4 + k];   // full 32-bit word, sign-extended
                    b_val = dut.ram[144 + k*4 + j];
                    expected = expected + a_val * b_val;
                end
                got = dut.ram[256 + i*4 + j];
                if (got !== expected) begin
                    errors = errors + 1;
                    $display("MISMATCH C[%0d][%0d]: got %0d expected %0d", i, j, got, expected);
                end
            end
        if (errors == 0)
            $display("SW FIRMWARE PASSED: software matmul computed correct C (%0d C writes)", c_writes);
        else
            $display("SW FIRMWARE FAILED: %0d mismatches", errors);
        $finish;
    end
endmodule
