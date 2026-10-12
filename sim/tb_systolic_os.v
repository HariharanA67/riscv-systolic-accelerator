`timescale 1ns / 1ps
module tb_systolic_os;
    reg clk = 0, rst = 1, clr = 0;
    reg signed [7:0] a_in [3:0];
    reg signed [7:0] b_in [3:0];
    wire signed [31:0] c_out [15:0];
    reg signed [7:0] A [15:0];
    reg signed [7:0] B [15:0];
    reg signed [31:0] expected;
    integer i, j, k, t, errors;

    systolic_os_4x4 dut (.clk(clk), .rst(rst), .clr(clr),
        .a_in(a_in), .b_in(b_in), .c_out(c_out));

    always #5 clk = ~clk;

    initial begin
        errors = 0;
        for (i = 0; i < 16; i = i + 1) begin
            A[i] = $random; B[i] = $random;
        end
        // Load test: A = 1..16 row-major, B = random
        for (i = 0; i < 16; i = i + 1) begin
            A[i] = i + 1;
            B[i] = $random;
        end
        #12 rst = 0;
        clr = 1;

        // 4 rows of A and 4 cols of B, skewed; 4 + 4 + 4 - 2 = 10 active cycles
        for (t = 0; t < 10; t = t + 1) begin
            for (i = 0; i < 4; i = i + 1) begin
                k = t - i;   // row i starts i cycles late
                a_in[i] = (k >= 0 && k < 4) ? A[i*4+k] : 8'sd0;
            end
            for (j = 0; j < 4; j = j + 1) begin
                k = t - j;   // column j starts j cycles late
                b_in[j] = (k >= 0 && k < 4) ? B[k*4+j] : 8'sd0;
            end
            @(posedge clk); #1;
            clr = 0;
        end

        // Compare against reference C = A x B
        for (i = 0; i < 4; i = i + 1)
            for (j = 0; j < 4; j = j + 1) begin
                expected = 0;
                for (k = 0; k < 4; k = k + 1)
                    expected = expected + A[i*4+k] * B[k*4+j];
                if (c_out[i*4+j] !== expected) begin
                    errors = errors + 1;
                    $display("MISMATCH C[%0d][%0d]: got %0d expected %0d",
                             i, j, c_out[i*4+j], expected);
                end
            end

        if (errors == 0) $display("OS SYSTOLIC PASSED");
        else             $display("OS SYSTOLIC FAILED: %0d mismatches", errors);
        $finish;
    end
endmodule
