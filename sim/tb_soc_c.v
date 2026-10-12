`timescale 1ns / 1ps
module tb_soc_c;
    reg clk = 0, rst = 1;
    soc_mini dut (.clk(clk), .rst(rst));
    always #5 clk = ~clk;

    localparam [31:0] FINAL_LOOP = 32'h8;      // "j 8" after main returns (_start)
    localparam [31:0] JUMP_SELF  = 32'h0000006f;
    localparam integer MAX_CYCLES = 20000;
    localparam integer NEED_HITS  = 5;

    integer i, j, k, errors, cycles, loop_hits, first_loop_cycle, c_writes;
    reg signed [31:0] expected, got;

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
        $readmemh("prog_c.hex", dut.ram);
        #22 rst = 0;
        for (cycles = 0; cycles < MAX_CYCLES && loop_hits < NEED_HITS; cycles = cycles + 1)
            @(posedge clk);
        if (loop_hits < NEED_HITS) begin
            $display("C FIRMWARE FAILED: did not reach finish loop within %0d cycles", MAX_CYCLES);
            $finish;
        end
        $display("C firmware reached finish loop after %0d cycles (first fetch at cycle %0d)", cycles, first_loop_cycle);
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
        if (errors == 0 && c_writes >= 16)
            $display("C FIRMWARE PASSED: compiled C drove accelerator, C verified (%0d C writes)", c_writes);
        else
            $display("C FIRMWARE FAILED: %0d mismatches, %0d C writes before loop", errors, c_writes);
        $finish;
    end
endmodule
