module tb_systolic_array ();

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
        
        // Initialize A and B to identity matrices (flattened)
        for (idx = 0; idx < 16; idx = idx + 1) begin
            i = idx / 4;
            j = idx % 4;
            if (i == j) begin
                a_in[idx] <= 8'd1;
                b_in[idx] <= 8'd1;
            end else begin
                a_in[idx] <= 8'd0;
                b_in[idx] <= 8'd0;
            end
        end
        
        // Run for 20 cycles
        repeat(20) #10;
        
        $display("Result matrix C:");
        for (idx = 0; idx < 16; idx = idx + 1) begin
            i = idx / 4;
            j = idx % 4;
            $display("C[%0d][%0d] = %0d", i, j, c_out[idx]);
        end
        
        $finish;
    end
    
    always #5 clk = ~clk;

endmodule
