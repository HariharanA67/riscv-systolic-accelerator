`timescale 1ns / 1ps
module tb_systolic_misuse3;
    reg clk = 0, rst = 1, start = 0, shift_en = 0, din = 0;
    wire dout, done;
    reg [127:0] A_vec, B_vec;
    reg [511:0] C_got;
    reg signed [31:0] e, g;
    integer i, n, r, c, kk, errors, cyc;

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

    task check(input [8*40-1:0] label);
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

        for (cyc = 0; cyc < 10; cyc = cyc + 1) begin
            rst = 1; @(negedge clk); rst = 0;
            send_vec(A_vec); send_vec(B_vec);
            @(negedge clk); start = 1;            // first start launches the run
            @(negedge clk); start = 0;
            // assert a second start on RUN cycle `cyc`
            repeat (cyc) @(negedge clk);
            start = 1; @(negedge clk); start = 0;
            wait (done == 1);
            @(negedge clk);
            read_c;
            if (cyc == 0)      check("accumulate cycle 0");
            else if (cyc == 1) check("accumulate cycle 1");
            else if (cyc == 2) check("accumulate cycle 2");
            else if (cyc == 3) check("accumulate cycle 3");
            else if (cyc == 4) check("accumulate cycle 4");
            else if (cyc == 5) check("accumulate cycle 5");
            else if (cyc == 6) check("accumulate cycle 6");
            else if (cyc == 7) check("accumulate cycle 7");
            else if (cyc == 8) check("accumulate cycle 8");
            else               check("accumulate cycle 9");
        end

        if (errors == 0) $display("MISUSE3 PASSED");
        else             $display("MISUSE3: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule
