`timescale 1ns / 1ps

module tb_matmul_fixed();
    reg clk, rst;
    reg signed [7:0] a_in [15:0];
    reg signed [7:0] b_in [15:0];
    wire signed [31:0] c_out [15:0];
    
    integer i, j, idx;
    
    systolic_array_4x4 dut (
        .clk(clk),
        .rst(rst),
        .a_in_flat(a_in),
        .b_in_flat(b_in),
        .c_out_flat(c_out)
    );
    
    initial begin
        clk = 0;
        rst = 1;
        #10 rst = 0;
        
        // Load test matrices (like identity test did)
        for (idx = 0; idx < 16; idx = idx + 1) begin
            i = idx / 4;
            j = idx % 4;
            a_in[idx] <= i + 1;      // Row + 1
            b_in[idx] <= j + 2;      // Col + 2
        end
        
        // Run for 30 cycles
        repeat(30) #10;
        
        $display("=== Systolic Array Matmul ===");
        for (idx = 0; idx < 16; idx = idx + 1) begin
            i = idx / 4;
            j = idx % 4;
            $display("C[%d][%d] = %d", i, j, c_out[idx]);
        end
        
        $finish;
    end
    
    always #5 clk = ~clk;
endmodule
