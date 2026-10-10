module systolic_array_4x4 (
    input clk,
    input rst,
    input signed [7:0] a_in_flat [15:0],
    input signed [7:0] b_in_flat [15:0],
    output signed [31:0] c_out_flat [15:0]
);

    wire signed [7:0] a_fwd [3:0][3:0];
    wire signed [7:0] b_fwd [3:0][3:0];
    wire signed [31:0] acc_fwd [3:0][3:0];
    
    genvar i, j;
    generate
        for (i = 0; i < 4; i = i + 1) begin : row
            for (j = 0; j < 4; j = j + 1) begin : col
                wire signed [7:0] a_sel;
                wire signed [7:0] b_sel;
                wire signed [31:0] acc_sel;
                
                // A input: row i, col j
                if (i == 0) 
                    assign a_sel = a_in_flat[i*4 + j];
                else 
                    assign a_sel = a_fwd[i-1][j];
                
                // B input: row i, col j
                if (j == 0)
                    assign b_sel = b_in_flat[i*4 + j];
                else
                    assign b_sel = b_fwd[i][j-1];
                
                // Accumulator: from top
                if (i == 0)
                    assign acc_sel = 32'b0;
                else
                    assign acc_sel = acc_fwd[i-1][j];
                
                processing_element pe (
                    .clk(clk),
                    .rst(rst),
                    .a_in(a_sel),
                    .b_in(b_sel),
                    .acc_in(acc_sel),
                    .a_out(a_fwd[i][j]),
                    .b_out(b_fwd[i][j]),
                    .acc_out(acc_fwd[i][j])
                );
            end
        end
    endgenerate
    
    assign c_out_flat[0] = acc_fwd[0][0];
    assign c_out_flat[1] = acc_fwd[0][1];
    assign c_out_flat[2] = acc_fwd[0][2];
    assign c_out_flat[3] = acc_fwd[0][3];
    assign c_out_flat[4] = acc_fwd[1][0];
    assign c_out_flat[5] = acc_fwd[1][1];
    assign c_out_flat[6] = acc_fwd[1][2];
    assign c_out_flat[7] = acc_fwd[1][3];
    assign c_out_flat[8] = acc_fwd[2][0];
    assign c_out_flat[9] = acc_fwd[2][1];
    assign c_out_flat[10] = acc_fwd[2][2];
    assign c_out_flat[11] = acc_fwd[2][3];
    assign c_out_flat[12] = acc_fwd[3][0];
    assign c_out_flat[13] = acc_fwd[3][1];
    assign c_out_flat[14] = acc_fwd[3][2];
    assign c_out_flat[15] = acc_fwd[3][3];

endmodule
