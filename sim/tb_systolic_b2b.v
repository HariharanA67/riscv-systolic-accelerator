`timescale 1ns / 1ps
module tb_systolic_b2b;
    reg clk = 0, rst = 1, start = 0, shift_en = 0, din = 0;
    wire dout, done;
    reg [127:0] A_vec, B_vec;
    reg [511:0] C_got;
    reg signed [31:0] e, g;
    integer i, n, r, c, kk, errors, run;

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

    task read_c;
        begin
            for (n = 511; n >= 0; n = n - 1) begin
                C_got[n] = dout;
                @(negedge clk); shift_en = 1;
                @(negedge clk); shift_en = 0;
            end
        end
    endtask

    task check(input integer id);
        integer bad, rr, cc, kk2;
        begin
            bad = 0;
            for (rr = 0; rr < 4; rr = rr + 1)
                for (cc = 0; cc < 4; cc = cc + 1) begin
                    e = 0;
                    for (kk2 = 0; kk2 < 4; kk2 = kk2 + 1)
                        e = e + $signed(A_vec[(rr*4+kk2)*8 +: 8]) * $signed(B_vec[(kk2*4+cc)*8 +: 8]);
                    g = C_got[(rr*4+cc)*32 +: 32];
                    if (g !== e) bad = bad + 1;
                end
            if (bad == 0) $display("B2B run %0d: PASSED", id);
            else begin $display("B2B run %0d: FAILED (%0d of 16 wrong)", id, bad); errors = errors + 1; end
        end
    endtask

    initial begin
        errors = 0;
        #12 rst = 0;
        for (run = 0; run < 8; run = run + 1) begin
            // new random data each run, no reset between runs
            for (i = 0; i < 16; i = i + 1) begin
                A_vec[i*8 +: 8] = $random;
                B_vec[i*8 +: 8] = $random;
            end
            if (run == 0) begin
                // first run only: reset once at the very start
            end
            send_vec(A_vec); send_vec(B_vec);
            @(negedge clk); start = 1; @(negedge clk); start = 0;
            wait (done == 1);
            @(negedge clk);
            read_c;
            check(run);
        end
        if (errors == 0) $display("B2B PASSED (8 back-to-back runs, no reset between)");
        else             $display("B2B: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule
