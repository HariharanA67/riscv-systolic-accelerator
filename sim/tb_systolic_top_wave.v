`timescale 1ns / 1ps
module tb_systolic_top_wave ();
    reg clk, rst, start, shift_en, din;
    wire dout, done;
    reg [511:0] c_expected;
    integer i, bit_idx;
    
    systolic_top dut (
        .clk(clk), .rst(rst), .start(start), .shift_en(shift_en),
        .din(din), .dout(dout), .done(done)
    );
    
    initial begin
        $dumpfile("../build/wrapper.vcd");
        $dumpvars(0, tb_systolic_top_wave);
    end
    
    initial begin
        clk = 0;
        rst = 1;
        start = 0;
        shift_en = 0;
        din = 0;
        
        #10 rst = 0;
        
        // LOAD phase: shift in 256 bits (A then B, MSB first)
        // For identity matrix: A[i][i]=1, others=0; B[i][i]=1, others=0
        for (i = 0; i < 256; i = i + 1) begin
            @(posedge clk);
            shift_en = 1;
            if (i < 128) begin
                // A matrix (128 bits = 16 * 8 bits)
                // A[0][0]=1 (byte 0), all others 0
                din = (i == 0) ? 1'b1 : 1'b0;
            end else begin
                // B matrix (128 bits)
                // B[0][0]=1 (byte 128), all others 0
                din = (i == 128) ? 1'b1 : 1'b0;
            end
        end
        shift_en = 0;
        
        // Wait for loaded and issue start
        repeat(5) @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        // Wait for done pulse
        @(posedge done);
        repeat(5) @(posedge clk);
        
        // READ phase: shift out 512 bits
        for (i = 0; i < 512; i = i + 1) begin
            shift_en = 1;
            @(posedge clk);
            shift_en = 0;
            @(posedge clk);
        end
        
        repeat(10) @(posedge clk);
        $finish;
    end
    
    always #5 clk = ~clk;
endmodule
