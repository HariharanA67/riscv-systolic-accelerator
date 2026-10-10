`timescale 1ns / 1ps

module tb_matmul_benchmark();
    reg clk, rst;
    reg signed [7:0] a_in [15:0];
    reg signed [7:0] b_in [15:0];
    wire signed [31:0] c_out [15:0];
    
    integer i, idx;
    
    matmul_simple dut (
        .clk(clk),
        .rst(rst),
        .a(a_in),
        .b(b_in),
        .c(c_out)
    );
    
    initial begin
        clk = 0;
        rst = 1;
        #10 rst = 0;
        
        // Load test matrices
        for (idx = 0; idx < 16; idx = idx + 1) begin
            a_in[idx] <= idx + 1;
            b_in[idx] <= idx + 2;
        end
        
        #20;
        
        $display("=== Matmul Accelerator Results ===");
        $display("Input A[0] = [1 2 3 4]");
        $display("Input B[0] = [2 3 4 5]");
        $display("");
        for (idx = 0; idx < 4; idx = idx + 1) begin
            $display("C[%d][0]=%3d  C[%d][1]=%3d  C[%d][2]=%3d  C[%d][3]=%3d", 
                idx, c_out[idx*4], idx, c_out[idx*4+1], idx, c_out[idx*4+2], idx, c_out[idx*4+3]);
        end
        
        $finish;
    end
    
    always #5 clk = ~clk;
endmodule
