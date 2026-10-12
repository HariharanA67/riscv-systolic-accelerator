`timescale 1ns / 1ps
module tb_systolic_os2;
    reg clk = 0, rst = 1, clr = 0;
    reg signed [7:0] a_in [3:0];
    reg signed [7:0] b_in [3:0];
    wire signed [31:0] c_out [15:0];
    reg signed [7:0] A [15:0];
    reg signed [7:0] B [15:0];
    reg signed [31:0] expected;
    integer i, j, k, t, run, errors;

    systolic_os_4x4 dut (.clk(clk), .rst(rst), .clr(clr),
        .a_in(a_in), .b_in(b_in), .c_out(c_out));
    always #5 clk = ~clk;

    task run_matmul;
        begin
            clr = 1;
            for (t = 0; t < 10; t = t + 1) begin
                for (i = 0; i < 4; i = i + 1) begin
                    k = t - i;
                    a_in[i] = (k >= 0 && k < 4) ? A[i*4+k] : 8'sd0;
                end
                for (j = 0; j < 4; j = j + 1) begin
                    k = t - j;
                    b_in[j] = (k >= 0 && k < 4) ? B[k*4+j] : 8'sd0;
                end
                @(posedge clk); #1;
                clr = 0;
            end
            // Pad with zeros so the last products are fully accumulated
            for (t = 0; t < 2; t = t + 1) begin
                a_in[0] = 0; a_in[1] = 0; a_in[2] = 0; a_in[3] = 0;
                b_in[0] = 0; b_in[1] = 0; b_in[2] = 0; b_in[3] = 0;
                @(posedge clk); #1;
            end
        end
    endtask

    task check;
        begin
            for (i = 0; i < 4; i = i + 1)
                for (j = 0; j < 4; j = j + 1) begin
                    expected = 0;
                    for (k = 0; k < 4; k = k + 1)
                        expected = expected + A[i*4+k] * B[k*4+j];
                    if (c_out[i*4+j] !== expected) begin
                        errors = errors + 1;
                        $display("MISMATCH run%0d C[%0d][%0d]: got %0d expected %0d",
                                 run, i, j, c_out[i*4+j], expected);
                    end
                end
        end
    endtask

    initial begin
        errors = 0;
        #12 rst = 0;
        for (run = 0; run < 6; run = run + 1) begin
            // Mix of patterns: random, extremes (-128, 127), zeros
            for (i = 0; i < 16; i = i + 1) begin
                case (run)
                    0: begin A[i] = $random; B[i] = $random; end
                    1: begin A[i] = -8'sd128; B[i] = -8'sd128; end
                    2: begin A[i] = 8'sd127; B[i] = -8'sd128; end
                    3: begin A[i] = 0; B[i] = $random; end
                    default: begin A[i] = $random; B[i] = $random; end
                endcase
            end
            run_matmul;
            check;
        end
        if (errors == 0) $display("OS SYSTOLIC STRESS PASSED (6 runs, back-to-back)");
        else             $display("OS SYSTOLIC STRESS FAILED: %0d mismatches", errors);
        $finish;
    end
endmodule
