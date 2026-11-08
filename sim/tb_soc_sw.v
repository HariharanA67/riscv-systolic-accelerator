`timescale 1ns / 1ps
module tb_soc_sw ();
    reg clk, rst;
    integer seed;
    integer i, j, k, errors;
    reg signed [31:0] expected, got;
    wire [511:0] c_out;
    integer cycle, done_cycle;

    soc_mini #(.ENABLE_MUL(1)) dut (
        .clk(clk),
        .rst(rst),
        .c_out(c_out)
    );

    initial begin
        clk = 0;
        rst = 1;
        cycle = 0;
        done_cycle = 0;
        seed = 7;

        $readmemh("prog_sw.hex", dut.ram);

        // Defined, signed INT8 inputs: A at words 128..143, B at words 144..159
        // (byte addresses 0x200 and 0x240, same as RAM_A/RAM_B in matmul_opt.c)
        for (i = 0; i < 16; i = i + 1) begin
            dut.ram[128 + i] = ($random(seed) % 128);
            dut.ram[144 + i] = ($random(seed) % 128);
        end

        #10 rst = 0;

        // Run until we reach the final loop at 0x8
        repeat(50000) begin
            @(posedge clk);
            cycle = cycle + 1;
            if (dut.cpu.reg_pc == 32'h8 && done_cycle == 0) begin
                done_cycle = cycle;
            end
        end

        $display("SW done_cycle=%0d", done_cycle);

        // Verify C against expected product
        errors = 0;
        for (i = 0; i < 4; i = i + 1)
            for (j = 0; j < 4; j = j + 1) begin
                expected = 0;
                for (k = 0; k < 4; k = k + 1)
                    expected = expected + $signed(dut.ram[128 + i*4 + k][7:0]) * $signed(dut.ram[144 + k*4 + j][7:0]);
                got = dut.ram[256 + i*4 + j];
                if (i == 0 && j == 0)
                    $display("C00 expected=%0d got=%0d", expected, got);
                if ((^got === 1'bx) || (got !== expected)) begin
                    errors = errors + 1;
                    $display("MISMATCH C[%0d][%0d]: got %0d expected %0d", i, j, got, expected);
                end
            end

        if (errors == 0)
            $display("SW FIRMWARE PASSED: C verified, done_cycle=%0d", done_cycle);
        else
            $display("SW FIRMWARE FAILED: %0d mismatches", errors);

        $finish;
    end

    always #5 clk = ~clk;
endmodule