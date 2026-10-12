`timescale 1ns / 1ps
module tb_matmul_simple;
    reg clk = 0;
    reg rst = 1;
    reg signed [127:0] a_in, b_in;
    wire signed [511:0] c_out;
    integer t, r, c, k, errors;
    reg signed [31:0] expected;
    reg signed [31:0] got;

    matmul_simple dut (.clk(clk), .rst(rst), .a_in(a_in), .b_in(b_in), .c_out(c_out));

    always #5 clk = ~clk;

    task check_result;
        begin
            #1;
            for (r = 0; r < 4; r = r + 1) begin
                for (c = 0; c < 4; c = c + 1) begin
                    expected = 0;
                    for (k = 0; k < 4; k = k + 1)
                        expected = expected + $signed(a_in[(r*4+k)*8 +: 8]) * $signed(b_in[(k*4+c)*8 +: 8]);
                    got = c_out[(r*4+c)*32 +: 32];
                    if (got !== expected) begin
                        errors = errors + 1;
                        $display("MISMATCH C[%0d][%0d]: got %0d expected %0d", r, c, got, expected);
                    end
                end
            end
        end
    endtask

    initial begin
        errors = 0;
        a_in = 0; b_in = 0;
        #12 rst = 0;

        // Test 1: identity x random
        a_in = 0;
        for (k = 0; k < 4; k = k + 1) a_in[(k*4+k)*8 +: 8] = 8'sd1;
        for (k = 0; k < 16; k = k + 1) b_in[k*8 +: 8] = $random;
        @(posedge clk); check_result;

        // Test 2: edge case -128 x -128
        for (k = 0; k < 16; k = k + 1) begin
            a_in[k*8 +: 8] = -8'sd128;
            b_in[k*8 +: 8] = -8'sd128;
        end
        @(posedge clk); check_result;

        // Test 3: 20 random matrix pairs
        for (t = 0; t < 20; t = t + 1) begin
            for (k = 0; k < 16; k = k + 1) begin
                a_in[k*8 +: 8] = $random;
                b_in[k*8 +: 8] = $random;
            end
            @(posedge clk); check_result;
        end

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("FAILED: %0d mismatches", errors);
        $finish;
    end
endmodule
