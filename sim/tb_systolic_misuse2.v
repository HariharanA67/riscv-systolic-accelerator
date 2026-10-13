`timescale 1ns / 1ps
module tb_systolic_misuse2;
    reg clk = 0, rst = 1, start = 0, shift_en = 0, din = 0;
    wire dout, done;
    reg [127:0] A_vec, B_vec;
    reg [511:0] C_got;
    reg signed [31:0] e, g;
    integer i, n, r, c, kk, errors;

    systolic_top dut (.clk(clk), .rst(rst), .start(start), .shift_en(shift_en),
                      .din(din), .dout(dout), .done(done));
    always #5 clk = ~clk;

    task send_vec(input [127:0] v);
        integer b;
        begin
            for (b = 127; b >= 0; b = b - 1) begin
                @(negedge clk); shift_en = 1; din = v[b];
                @(negedge clk); shift_en = 0; din = 0;
            end
        end
    endtask

    task pulse_start;
        begin
            @(negedge clk); start = 1;
            @(negedge clk); start = 0;
        end
    endtask

    task check(input [8*40-1:0] label);
        integer bad;
        begin
            bad = 0;
            for (r = 0; r < 4; r = r + 1)
                for (c = 0; c < 4; c = c + 1) begin
                    e = 0;
                    for (kk = 0; kk < 4; kk = kk + 1)
                        e = e + $signed(A_vec[(r*4+kk)*8 +: 8]) * $signed(B_vec[(kk*4+c)*8 +: 8]);
                    g = C_got[(r*4+c)*32 +: 32];
                    if (g !== e) bad = bad + 1;
                end
            if (bad == 0) $display("%0s: PASSED", label);
            else begin $display("%0s: FAILED (%0d of 16 wrong)", label, bad); errors = errors + 1; end
        end
    endtask

    initial begin
        errors = 0;
        for (i = 0; i < 16; i = i + 1) begin
            A_vec[i*8 +: 8] = $random;
            B_vec[i*8 +: 8] = $random;
        end
        #12 rst = 0;

        // Case 6: start pulsed during RUN
        send_vec(A_vec); send_vec(B_vec);
        pulse_start;
        repeat (3) @(negedge clk);
        start = 1; @(negedge clk); start = 0;
        wait (done == 1);
        @(negedge clk);
        for (n = 511; n >= 0; n = n - 1) begin
            C_got[n] = dout;
            @(negedge clk); shift_en = 1;
            @(negedge clk); shift_en = 0;
        end
        check("6 start during RUN");

        // Case 7: start pulsed in the middle of the read-out
        rst = 1; @(negedge clk); rst = 0;
        send_vec(A_vec); send_vec(B_vec);
        pulse_start;
        wait (done == 1);
        @(negedge clk);
        for (n = 511; n >= 0; n = n - 1) begin
            if (n == 255) begin start = 1; @(negedge clk); start = 0; end
            C_got[n] = dout;
            @(negedge clk); shift_en = 1;
            @(negedge clk); shift_en = 0;
        end
        check("7 start during READ");

        if (errors == 0) $display("MISUSE2 PASSED");
        else             $display("MISUSE2: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule
