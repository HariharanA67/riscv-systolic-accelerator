`timescale 1ns / 1ps
module tb_systolic_misuse;
    reg clk = 0, rst = 1, start = 0, shift_en = 0, din = 0;
    wire dout, done;
    reg [127:0] A_vec, B_vec;
    reg [511:0] C_got;
    integer i, n, errors;

    systolic_top dut (.clk(clk), .rst(rst), .start(start), .shift_en(shift_en),
                      .din(din), .dout(dout), .done(done));
    always #5 clk = ~clk;

    // Send all 128 bits of v, MSB first (bit 127 first), one per clock
    task send_vec(input [127:0] v);
        integer b;
        begin
            for (b = 127; b >= 0; b = b - 1) begin
                @(negedge clk); shift_en = 1; din = v[b];
            end
            @(negedge clk); shift_en = 0; din = 0;
        end
    endtask

    // Send `count` bits of the stream A then B (A first); bits beyond 256 are zeros
    task send_matrices(input integer count);
        integer b;
        reg [255:0] stream;
        begin
            stream = {A_vec, B_vec};
            for (b = 0; b < count; b = b + 1) begin
                @(negedge clk); shift_en = 1; din = (b < 256) ? stream[255 - b] : 1'b0;
            end
            @(negedge clk); shift_en = 0; din = 0;
        end
    endtask

    task pulse_start;
        begin
            @(negedge clk); start = 1;
            @(negedge clk); start = 0;
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

    task reset_dut;
        begin
            @(negedge clk); rst = 1;
            @(negedge clk); rst = 0;
        end
    endtask

    task check_result(input [8*40-1:0] label);
        integer r, c, kk, bad;
        reg signed [31:0] e, g;
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
            else begin
                $display("%0s: FAILED (%0d of 16 wrong)", label, bad);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        for (i = 0; i < 16; i = i + 1) begin
            A_vec[i*8 +: 8] = $random;
            B_vec[i*8 +: 8] = $random;
        end
        #12 rst = 0;

        // Case 1: early start before any bits are loaded (must be ignored)
        reset_dut;
        pulse_start;
        send_matrices(256);
        pulse_start;
        wait (done == 1);
        read_c;
        check_result("1 early start");

        // Case 2: too few bits (200), then start (must not run)
        reset_dut;
        send_matrices(200);
        pulse_start;
        repeat (30) @(negedge clk);
        if (done === 0) $display("2 too few bits: PASSED (done stayed 0)");
        else begin $display("2 too few bits: FAILED"); errors = errors + 1; end

        // Case 3: too many bits (300). Extra bits must not change the result.
        reset_dut;
        send_matrices(300);
        pulse_start;
        wait (done == 1);
        read_c;
        check_result("3 too many bits");

        // Case 4: shift_en held high during RUN
        reset_dut;
        send_matrices(256);
        pulse_start;
        @(negedge clk); shift_en = 1;
        repeat (15) @(negedge clk);
        shift_en = 0;
        wait (done == 1);
        read_c;
        check_result("4 shift_en during RUN");

        // Case 5: extra clocks after the 512-bit read
        reset_dut;
        send_matrices(256);
        pulse_start;
        wait (done == 1);
        read_c;
        @(negedge clk); shift_en = 1;
        repeat (20) @(negedge clk);
        shift_en = 0;
        check_result("5 extra read clocks");

        if (errors == 0) $display("MISUSE TESTS PASSED");
        else             $display("MISUSE TESTS: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule
