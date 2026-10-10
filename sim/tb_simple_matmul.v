`timescale 1ns / 1ps

module tb_simple_matmul();
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
        
        // Load identity matrices
        for (idx = 0; idx < 16; idx = idx + 1) begin
            i = idx / 4;
            if (i == idx % 4) begin
                a_in[idx] <= 8'd1;
                b_in[idx] <= 8'd1;
            end else begin
                a_in[idx] <= 8'd0;
                b_in[idx] <= 8'd0;
            end
        end
        
        #20;
        
        $display("=== Simple Matmul (Identity × Identity) ===");
        for (idx = 0; idx < 16; idx = idx + 1) begin
            i = idx / 4;
            $display("C[%d][%d] = %d", i, idx%4, c_out[idx]);
        end
        
        $finish;
    end
    
    always #5 clk = ~clk;
endmodule
