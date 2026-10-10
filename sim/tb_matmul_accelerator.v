`timescale 1ns / 1ps

module tb_matmul_accelerator();
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
        
        // Wait for pipeline to fill (2N-1 = 7 cycles + some margin)
        repeat(100) #10 clk = ~clk;
        
        $display("=== Systolic Array Results (after 1000ns) ===");
        for (int i = 0; i < 4; i = i + 1) begin
            for (int j = 0; j < 4; j = j + 1) begin
                $display("C[%d][%d] = %5d", i, j, c_result[i*4+j]);
            end
        end
        $finish;
    end
endmodule
