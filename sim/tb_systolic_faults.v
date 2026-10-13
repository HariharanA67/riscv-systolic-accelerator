`timescale 1ns / 1ps
module tb_systolic_faults;
    reg clk = 0, rst = 1, start = 0, shift_en = 0, din = 0;
    wire dout, done;
    reg [127:0] A_vec, B_vec, mixed;
    reg [511:0] C_got;
    integer i, n, errors;

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

    // Compare C_got against the product of the matrices actually shifted in (a, b)
    task check(input [8*40-1:0] label, input [127:0] a, input [127:0] b);
        integer bad, rr, cc, kk;
        reg signed [31:0] ee, gg;
        begin
            bad = 0;
            for (rr = 0; rr < 4; rr = rr + 1)
                for (cc = 0; cc < 4; cc = cc + 1) begin
                    ee = 0;
                    for (kk = 0; kk < 4; kk = kk + 1)
                        ee = ee + $signed(a[(rr*4+kk)*8 +: 8]) * $signed(b[(kk*4+cc)*8 +: 8]);
                    gg = C_got[(rr*4+cc)*32 +: 32];
                    if (gg !== ee) bad = bad + 1;
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

        // F1: byte 0 of A is changed before the load. The design must compute the
        // product of the bytes that were actually shifted in (mixed), not the original A.
        mixed = A_vec;
        mixed[7:0] = ~A_vec[7:0];
        rst = 1; @(negedge clk); rst = 0;
        send_vec(mixed); send_vec(B_vec);
        @(negedge clk); start = 1; @(negedge clk); start = 0;
        wait (done == 1); @(negedge clk);
        read_c;
        check("F1 changed byte in A", mixed, B_vec);

        // F2: shift_en pulsed during RUN before done. Must not change the result.
        rst = 1; @(negedge clk); rst = 0;
        send_vec(A_vec); send_vec(B_vec);
        @(negedge clk); start = 1; @(negedge clk); start = 0;
        for (i = 0; i < 5; i = i + 1) begin
            @(negedge clk); shift_en = 1; @(negedge clk); shift_en = 0;
        end
        wait (done == 1); @(negedge clk);
        read_c;
        check("F2 shift during RUN", A_vec, B_vec);

        // F3: one extra rising edge after every bit. Each loop iteration consumes two
        // bits of C, so the sampled stream is C[511], C[509], C[507], ... (every other bit).
        // Expected: the 256 sampled bits equal the odd-position bits of C's 512-bit stream.
        rst = 1; @(negedge clk); rst = 0;
        send_vec(A_vec); send_vec(B_vec);
        @(negedge clk); start = 1; @(negedge clk); start = 0;
        wait (done == 1); @(negedge clk);
        begin : f3
            reg [511:0] c_ref, c_seen;
            reg [511:0] c_expect;
            integer bad, rr, cc, kk, j;
            reg signed [31:0] ee, gg;
            // Build the reference C from the matrices (C element e, bit 511 is MSB of element 15)
            for (rr = 0; rr < 4; rr = rr + 1)
                for (cc = 0; cc < 4; cc = cc + 1) begin
                    ee = 0;
                    for (kk = 0; kk < 4; kk = kk + 1)
                        ee = ee + $signed(A_vec[(rr*4+kk)*8 +: 8]) * $signed(B_vec[(kk*4+cc)*8 +: 8]);
                    c_ref[(rr*4+cc)*32 +: 32] = ee;
                end
            // Sample with an extra edge per bit: each iteration takes one bit, then skips one
            c_seen = 0;
            for (j = 0; j < 256; j = j + 1) begin
                c_seen[511 - j] = dout;
                @(negedge clk); shift_en = 1;
                @(negedge clk); shift_en = 0;
                @(negedge clk); shift_en = 1;
                @(negedge clk); shift_en = 0;
            end
            // Expected sampled bit j is C bit (511 - 2*j)
            bad = 0;
            for (j = 0; j < 256; j = j + 1)
                if (c_seen[511 - j] !== c_ref[511 - 2*j]) bad = bad + 1;
            if (bad == 0) $display("F3 extra edge between bits: PASSED (rule confirmed)");
            else begin $display("F3 extra edge between bits: FAILED (%0d of 256 bits differ)", bad); errors = errors + 1; end
        end

        if (errors == 0) $display("FAULT TESTS PASSED");
        else             $display("FAULT TESTS: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule
