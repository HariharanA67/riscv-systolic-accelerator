`timescale 1ns / 1ps
module tb_systolic_os_flat;
    reg clk = 0, rst = 1, clr = 0;
    reg signed [31:0] a_in_flat, b_in_flat;
    wire signed [511:0] c_out_flat;
    reg signed [7:0] A [15:0];
    reg signed [7:0] B [15:0];
    reg signed [31:0] expected, got;
    integer i, j, k, t, errors;

    systolic_os_4x4 dut (.clk(clk), .rst(rst), .clr(clr),
        .a_in_flat(a_in_flat), .b_in_flat(b_in_flat), .c_out_flat(c_out_flat));
    always #5 clk = ~clk;

    initial begin
        errors = 0;
        for (i = 0; i < 16; i = i + 1) begin
            A[i] = i + 1;
            B[i] = $random;
        end
        #12 rst = 0;
        clr = 1;
        for (t = 0; t < 10; t = t + 1) begin
            for (i = 0; i < 4; i = i + 1) begin
                k = t - i;
                a_in_flat[i*8 +: 8] = (k >= 0 && k < 4) ? A[i*4+k] : 8'sd0;
            end
            for (j = 0; j < 4; j = j + 1) begin
                k = t - j;
                b_in_flat[j*8 +: 8] = (k >= 0 && k < 4) ? B[k*4+j] : 8'sd0;
            end
            @(posedge clk); #1;
            clr = 0;
        end
        for (i = 0; i < 4; i = i + 1)
            for (j = 0; j < 4; j = j + 1) begin
                expected = 0;
                for (k = 0; k < 4; k = k + 1)
                    expected = expected + A[i*4+k] * B[k*4+j];
                got = c_out_flat[(i*4+j)*32 +: 32];
                if (got !== expected) begin
                    errors = errors + 1;
                    $display("MISMATCH C[%0d][%0d]: got %0d expected %0d", i, j, got, expected);
                end
            end
        if (errors == 0) $display("OS FLAT PASSED");
        else             $display("OS FLAT FAILED: %0d mismatches", errors);
        $finish;
    end
endmodule
