`timescale 1ns / 1ps
module tb_soc_mini;
    reg clk = 0, rst = 1;
    soc_mini dut (.clk(clk), .rst(rst));
    always #5 clk = ~clk;

    localparam [31:0] FINAL_LOOP = 32'h198;  // word 102 of prog.hex: the final "j ."
    localparam integer MAX_CYCLES = 20000;

    integer i, j, k, errors, cycles, loop_hits;
    reg signed [31:0] expected, got;
    reg done_flag;

    // Count consecutive instruction fetches from the final loop address
    always @(posedge clk) begin
        if (!rst && dut.mem_valid && dut.mem_instr && dut.mem_addr == FINAL_LOOP && !dut.mem_ready)
            loop_hits <= loop_hits + 1;
        else if (!rst && dut.mem_valid && dut.mem_instr && !dut.mem_ready)
            loop_hits <= 0;
    end

    initial begin
        errors = 0; loop_hits = 0; done_flag = 0;
        $readmemh("prog.hex", dut.ram);
        #22 rst = 0;
        for (cycles = 0; cycles < MAX_CYCLES && loop_hits < 5; cycles = cycles + 1)
            @(posedge clk);
        if (loop_hits < 5) begin
            $display("SOC MINI FAILED: program did not reach the final loop within %0d cycles", MAX_CYCLES);
            $finish;
        end
        $display("program reached final loop after %0d cycles", cycles);
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
        if (errors == 0) $display("SOC MINI PASSED: program finished, C verified");
        else             $display("SOC MINI FAILED: %0d mismatches", errors);
        $finish;
    end
endmodule
