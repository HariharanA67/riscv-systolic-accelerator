`timescale 1ns / 1ps

module tb_matmul_debug();
    reg clk, rst;
    reg signed [7:0] a_mat [15:0];
    reg signed [7:0] b_mat [15:0];
    wire signed [31:0] c_result [15:0];
    
    systolic_array_4x4 accel (
        .clk(clk),
        .rst(rst),
        .a_in_flat(a_mat),
        .b_in_flat(b_mat),
        .c_out_flat(c_result)
    );
    
    initial begin
        clk = 0;
        rst = 1;
        #10 rst = 0;
        
        // Load matrices
        for (int i = 0; i < 16; i = i + 1) begin
            a_mat[i] = i + 1;
            b_mat[i] = i + 2;
        end
        
        // Wait 200 cycles (very long)
        repeat(200) #10 clk = ~clk;
        
        $display("=== After 2000ns ===");
        $display("C[0][0] = %d (expected 100)", c_result[0]);
        $display("C[0][1] = %d (expected 110)", c_result[1]);
        $display("C[1][1] = %d (expected 378)", c_result[5]);
        $finish;
    end
endmodule
