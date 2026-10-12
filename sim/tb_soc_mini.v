`timescale 1ns / 1ps
module tb_soc_mini;
    reg clk = 0, rst = 1;
    soc_mini dut (.clk(clk), .rst(rst));
    always #5 clk = ~clk;

    localparam [31:0] FINAL_LOOP = 32'h198;   // word 102 of prog.hex: "j ."
    localparam [31:0] JUMP_SELF  = 32'h0000006f;
    localparam integer MAX_CYCLES = 20000;
    localparam integer NEED_HITS  = 5;

    integer i, j, k, errors, cycles;
    integer loop_hits;          // consecutive fetches of the final loop
    integer first_loop_cycle;   // cycle when the loop was first fetched, -1 if never
    integer c_word_writes_before_loop;
    reg signed [31:0] expected, got;

    // Count consecutive fetches of "j ." at the final address
    always @(posedge clk) begin
        if (!rst && dut.mem_valid && dut.mem_instr && !dut.mem_ready) begin
            if (dut.mem_addr == FINAL_LOOP && dut.mem_rdata == JUMP_SELF) begin
                loop_hits <= loop_hits + 1;
                if (first_loop_cycle < 0) first_loop_cycle = cycles;
            end else if (first_loop_cycle < 0) begin
                loop_hits <= 0;
            end
        end
    end

    // Count writes of C-result words (RAM words 256..271) before the loop
    always @(posedge clk) begin
        if (!rst && dut.mem_valid && !dut.mem_instr && !dut.mem_ready && |dut.mem_wstrb
            && dut.mem_addr[31] == 1'b0 && dut.mem_addr[11:2] >= 10'd256 && dut.mem_addr[11:2] < 10'd272
            && first_loop_cycle < 0)
            c_word_writes_before_loop = c_word_writes_before_loop + 1;
    end

    initial begin
        errors = 0; loop_hits = 0; first_loop_cycle = -1;
        c_word_writes_before_loop = 0; cycles = 0;
        $readmemh("prog.hex", dut.ram);
        #22 rst = 0;
        for (cycles = 0; cycles < MAX_CYCLES && loop_hits < NEED_HITS; cycles = cycles + 1)
            @(posedge clk);
        if (loop_hits < NEED_HITS) begin
            $display("SOC MINI FAILED: program did not reach the final loop within %0d cycles", MAX_CYCLES);
            $finish;
        end
        $display("program reached final loop after %0d cycles (first fetch at cycle %0d)", cycles, first_loop_cycle);
        if (c_word_writes_before_loop < 16)
            $display("note: only %0d C-result writes seen before the loop", c_word_writes_before_loop);
        for (i = 0; i < 4; i = i + 1)
            for (j = 0; j < 4; j = j + 1) begin
                expected = 0;
                for (k = 0; k < 4; k = k + 1)
                    expected = expected + $signed(dut.ram[128 + i*4 + k][7:0]) * $signed(dut.ram[144 + k*4 + j][7:0]);
                got = dut.ram[256 + i*4 + j];
                if (got !== expected) begin
                    errors = errors + 1;
                    $display("MISMATCH C[%0d][%0d]: got %0d expected %0d", i, j, got, expected);
                end
            end
        if (errors == 0 && c_word_writes_before_loop >= 16)
            $display("SOC MINI PASSED: program finished, C written before loop, C verified");
        else
            $display("SOC MINI FAILED: %0d mismatches, %0d C writes before loop", errors, c_word_writes_before_loop);
        $finish;
    end
endmodule
