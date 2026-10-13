`timescale 1ns / 1ps
module tb_systolic_patterns;
    reg clk = 0, rst = 1, start = 0, shift_en = 0, din = 0;
    wire dout, done;
    reg [127:0] A_vec, B_vec;
    reg [511:0] C_got;
    reg signed [31:0] e, g;
    integer i, n, r, c, kk, errors, p;

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

    task run_once;
        begin
            rst = 1; @(negedge clk); rst = 0;
            send_vec(A_vec); send_vec(B_vec);
            @(negedge clk); start = 1; @(negedge clk); start = 0;
            wait (done == 1);
            @(negedge clk);
            for (n = 511; n >= 0; n = n - 1) begin
                C_got[n] = dout;
                @(negedge clk); shift_en = 1;
                @(negedge clk); shift_en = 0;
            end
        end
    endtask

    task check(input [8*40-1:0] label);
        integer bad, rr, cc, kk2;
        reg signed [31:0] ee, gg;
        begin
            bad = 0;
            for (rr = 0; rr < 4; rr = rr + 1)
                for (cc = 0; cc < 4; cc = cc + 1) begin
                    ee = 0;
                    for (kk2 = 0; kk2 < 4; kk2 = kk2 + 1)
                        ee = ee + $signed(A_vec[(rr*4+kk2)*8 +: 8]) * $signed(B_vec[(kk2*4+cc)*8 +: 8]);
                    gg = C_got[(rr*4+cc)*32 +: 32];
                    if (gg !== ee) bad = bad + 1;
                end
            if (bad == 0) $display("%0s: PASSED", label);
            else begin $display("%0s: FAILED (%0d of 16 wrong)", label, bad); errors = errors + 1; end
        end
    endtask

    initial begin
        errors = 0;
        #12 rst = 0;

        // P1: all zeros
        A_vec = 0; B_vec = 0;
        run_once; check("P1 all zeros");

        // P2: identity A times random B (result must equal B)
        A_vec = 0;
        for (i = 0; i < 4; i = i + 1) A_vec[(i*4+i)*8 +: 8] = 8'sd1;
        for (i = 0; i < 16; i = i + 1) B_vec[i*8 +: 8] = $random;
        run_once; check("P2 identity x random");

        // P3: single nonzero element in A and in B, at each of the 16 positions of A
        // (B fixed at all ones). Result row r gets the value wherever A[r][k] is set.
        for (p = 0; p < 16; p = p + 1) begin
            A_vec = 0; B_vec = 0;
            A_vec[p*8 +: 8] = 8'sd5;
            for (i = 0; i < 16; i = i + 1) B_vec[i*8 +: 8] = 8'sd1;
            run_once;
            if (p == 0)       check("P3 single A elem 0");
            else if (p == 5)  check("P3 single A elem 5");
            else if (p == 10) check("P3 single A elem 10");
            else if (p == 15) check("P3 single A elem 15");
        end

        // P4: single nonzero element in B, A fixed at all ones
        for (p = 0; p < 16; p = p + 1) begin
            A_vec = 0; B_vec = 0;
            for (i = 0; i < 16; i = i + 1) A_vec[i*8 +: 8] = 8'sd1;
            B_vec[p*8 +: 8] = 8'sd7;
            run_once;
            if (p == 0)       check("P4 single B elem 0");
            else if (p == 5)  check("P4 single B elem 5");
            else if (p == 10) check("P4 single B elem 10");
            else if (p == 15) check("P4 single B elem 15");
        end

        // P5: extremes everywhere
        A_vec = 0; B_vec = 0;
        for (i = 0; i < 16; i = i + 1) begin
            A_vec[i*8 +: 8] = (i % 2) ? 8'sd127 : -8'sd128;
            B_vec[i*8 +: 8] = (i % 3) ? -8'sd128 : 8'sd127;
        end
        run_once; check("P5 extremes");

        if (errors == 0) $display("PATTERN TESTS PASSED");
        else             $display("PATTERN TESTS: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule
