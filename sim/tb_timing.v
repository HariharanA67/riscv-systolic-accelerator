`timescale 1ns / 1ps
module tb_timing;
    reg clk = 0, rst = 1, start = 0, shift_en = 0, din = 0;
    wire dout, done;
    integer i, t_start, t_done;
    systolic_top dut (.clk(clk), .rst(rst), .start(start), .shift_en(shift_en),
                      .din(din), .dout(dout), .done(done));
    always #5 clk = ~clk;
    initial begin
        #12 rst = 0;
        for (i = 0; i < 256; i = i + 1) begin
            @(negedge clk); shift_en = 1; din = 0;
            @(negedge clk); shift_en = 0;
        end
        @(negedge clk); start = 1; t_start = $time;
        @(negedge clk); start = 0;
        wait (done == 1); t_done = $time;
        $display("start-to-done: %0d cycles", (t_done - t_start) / 10);
        $finish;
    end
endmodule
