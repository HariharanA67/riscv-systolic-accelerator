`timescale 1ns / 1ps

module tb_systolic_benchmark();
    reg clk, rst;
    reg signed [7:0] a_in_flat [15:0];
    reg signed [7:0] b_in_flat [15:0];
    wire signed [31:0] c_out_flat [15:0];
    
    systolic_array_4x4 dut (
        .clk(clk),
        .rst(rst),
        .a_in_flat(a_in_flat),
        .b_in_flat(b_in_flat),
        .c_out_flat(c_out_flat)
    );
    
    initial begin
        clk = 0;
        rst = 1;
        #10 rst = 0;
        
        // Load identity matrices
        for (int i = 0; i < 16; i++) begin
            a_in_flat[i] = (i % 5 == 0) ? 8'sd1 : 8'sd0;
            b_in_flat[i] = (i % 5 == 0) ? 8'sd1 : 8'sd0;
        end
        
        repeat(20) #10 clk = ~clk;
        
        $display("=== Systolic Array Output ===");
        $display("C[0][0] = %d", c_out_flat[0]);
        $display("C[0][1] = %d", c_out_flat[1]);
        $display("C[1][0] = %d", c_out_flat[4]);
        $finish;
    end
endmodule
