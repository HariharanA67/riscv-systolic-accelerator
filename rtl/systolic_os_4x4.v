// 4x4 output-stationary systolic array.
// a_in[i]: A-stream entering row i from the left.
// b_in[j]: B-stream entering column j from the top.
// c_out[i*4+j]: accumulator of PE(i,j) = C[i][j].
module systolic_os_4x4 (
    input  wire               clk,
    input  wire               rst,
    input  wire               clr,
    input  wire signed [7:0]  a_in [3:0],
    input  wire signed [7:0]  b_in [3:0],
    output wire signed [31:0] c_out [15:0]
);
    wire signed [7:0]  a_h [3:0][4:0];  // horizontal A links
    wire signed [7:0]  b_v [4:0][3:0];  // vertical B links
    wire signed [31:0] acc [3:0][3:0];

    genvar i, j;
    generate
        for (i = 0; i < 4; i = i + 1) begin : row
            assign a_h[i][0] = a_in[i];
            for (j = 0; j < 4; j = j + 1) begin : col
                if (i == 0) begin : top
                    assign b_v[0][j] = b_in[j];
                end
                pe_os pe (
                    .clk(clk), .rst(rst), .clr(clr),
                    .a_in(a_h[i][j]),  .b_in(b_v[i][j]),
                    .a_out(a_h[i][j+1]), .b_out(b_v[i+1][j]),
                    .acc(acc[i][j])
                );
                assign c_out[i*4+j] = acc[i][j];
            end
        end
    endgenerate
endmodule
