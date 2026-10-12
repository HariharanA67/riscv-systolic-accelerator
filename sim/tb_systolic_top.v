`timescale 1ns / 1ps
module tb_systolic_top;
    reg clk = 0, rst = 1, start = 0, shift_en = 0, din = 0;
    wire dout, done;
    reg [127:0] A_vec, B_vec;
    reg [511:0] C_got;
    reg signed [31:0] expected, got;
    integer i, j, k, n, run, errors;

    systolic_top dut (.clk(clk), .rst(rst), .start(start), .shift_en(shift_en),
                      .din(din), .dout(dout), .done(done));
    always #5 clk = ~clk;

    // Send one 128-bit vector, MSB first, one bit per clock
    task send_vec(input [127:0] v);
        integer b;
        begin
            for (b = 127; b >= 0; b = b - 1) begin
                @(negedge clk);
                shift_en = 1; din = v[b];
            end
            @(negedge clk);
            shift_en = 0; din = 0;
        end
    endtask

    initial begin
        errors = 0;
        #12 rst = 0;
        for (run = 0; run < 6; run = run + 1) begin
            // Random matrices in row-major byte order; run 1 uses extremes
            for (i = 0; i < 16; i = i + 1) begin
                if (run == 1) begin
                    A_vec[i*8 +: 8] = -8'sd128;
                    B_vec[i*8 +: 8] = 8'sd127;
                end else begin
                    A_vec[i*8 +: 8] = $random;
                    B_vec[i*8 +: 8] = $random;
                end
            end
            // Reset between runs
            @(negedge clk); rst = 1; @(negedge clk); rst = 0;

            send_vec(A_vec);
            send_vec(B_vec);

            // Start and wait for done
            @(negedge clk); start = 1;
            @(negedge clk); start = 0;
            wait (done == 1);
            @(negedge clk);

            // Read 512 bits, MSB first
            shift_en = 1;
            for (n = 511; n >= 0; n = n - 1) begin
                C_got[n] = dout;
                @(negedge clk);
            end
            shift_en = 0;

            // Compare against reference
            for (i = 0; i < 4; i = i + 1)
                for (j = 0; j < 4; j = j + 1) begin
                    expected = 0;
                    for (k = 0; k < 4; k = k + 1)
                        expected = expected + $signed(A_vec[(i*4+k)*8 +: 8]) * $signed(B_vec[(k*4+j)*8 +: 8]);
                    got = C_got[(i*4+j)*32 +: 32];
                    if (got !== expected) begin
                        errors = errors + 1;
                        $display("run%0d MISMATCH C[%0d][%0d]: got %0d expected %0d", run, i, j, got, expected);
                    end
                end
        end
        if (errors == 0) $display("SYSTOLIC TOP PASSED (6 serial runs)");
        else             $display("SYSTOLIC TOP FAILED: %0d mismatches", errors);
        $finish;
    end
endmodule
