`timescale 1ns / 1ps
module tb_soc_mini;
    reg clk = 0, rst = 1;
    soc_mini dut (.clk(clk), .rst(rst));
    always #5 clk = ~clk;

    integer i, j, k, errors;
    reg signed [31:0] expected, got;

    initial begin
        errors = 0;
        $readmemh("prog.hex", dut.ram);
        #22 rst = 0;
        #30000;: copy, compute, copy back
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
        if (errors == 0) $display("SOC MINI PASSED: CPU drove accelerator, C verified");
        else             $display("SOC MINI FAILED: %0d mismatches", errors);
        $finish;
    end
endmodule
