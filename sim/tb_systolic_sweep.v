`timescale 1ns / 1ps
module tb_systolic_sweep;
    reg clk = 0, rst = 1, start = 0, shift_en = 0, din = 0;
    wire dout, done;
    reg [127:0] A_vec, B_vec;
    reg [511:0] C_got;
    integer i, n, rr, cc, kk2, errors, runs, trial, seed, rs;
    reg signed [31:0] ee, gg;

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

    task run_and_check(input integer do_reset);
        integer bad;
        begin
            if (do_reset) begin rst = 1; @(negedge clk); rst = 0; end
            send_vec(A_vec); send_vec(B_vec);
            @(negedge clk); start = 1; @(negedge clk); start = 0;
            wait (done == 1);
            @(negedge clk);
            for (n = 511; n >= 0; n = n - 1) begin
                C_got[n] = dout;
                @(negedge clk); shift_en = 1;
                @(negedge clk); shift_en = 0;
            end
            bad = 0;
            for (rr = 0; rr < 4; rr = rr + 1)
                for (cc = 0; cc < 4; cc = cc + 1) begin
                    ee = 0;
                    for (kk2 = 0; kk2 < 4; kk2 = kk2 + 1)
                        ee = ee + $signed(A_vec[(rr*4+kk2)*8 +: 8]) * $signed(B_vec[(kk2*4+cc)*8 +: 8]);
                    gg = C_got[(rr*4+cc)*32 +: 32];
                    if (gg !== ee) bad = bad + 1;
                end
            if (bad != 0) begin
                errors = errors + 1;
                $display("FAIL seed=%0d trial=%0d reset=%0d (%0d of 16 wrong)", seed, trial, do_reset, bad);
            end
        end
    endtask

    initial begin
        errors = 0; runs = 0;
        #12 rst = 0;
        for (seed = 1; seed <= 20; seed = seed + 1) begin
            rs = seed;
            for (trial = 0; trial < 50; trial = trial + 1) begin
                for (i = 0; i < 16; i = i + 1) begin
                    A_vec[i*8 +: 8] = $random(rs);
                    B_vec[i*8 +: 8] = $random(rs);
                end
                run_and_check(trial % 2);
                runs = runs + 1;
            end
        end
        $display("SWEEP: %0d runs, %0d failed", runs, errors);
        if (errors == 0) $display("SWEEP PASSED");
        else             $display("SWEEP FAILED");
        $finish;
    end
endmodule
