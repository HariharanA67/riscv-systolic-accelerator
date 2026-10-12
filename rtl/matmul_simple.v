// 4x4 INT8 matrix multiply: C = A x B
// Inputs/outputs are flattened row-major.
// A[r][k] = a_in[(r*4+k)*8 +: 8], C[r][c] = c_out[(r*4+c)*32 +: 32]
// Result is registered: it appears one clock after the inputs.
module matmul_simple (
    input  wire               clk,
    input  wire               rst,
    input  wire signed [127:0] a_in,
    input  wire signed [127:0] b_in,
    output reg  signed [511:0] c_out
);
    always @(posedge clk) begin
        if (rst) begin
            c_out <= 512'd0;
        end else begin : compute
            integer r, c, k;
            reg signed [31:0] acc;
            reg signed [15:0] p;
            reg signed [511:0] tmp;
            tmp = 512'd0;
            for (r = 0; r < 4; r = r + 1) begin
                for (c = 0; c < 4; c = c + 1) begin
                    acc = 32'sd0;
                    for (k = 0; k < 4; k = k + 1) begin
                        p   = $signed(a_in[(r*4+k)*8 +: 8]) * $signed(b_in[(k*4+c)*8 +: 8]);
                        acc = acc + p;
                    end
                    tmp[(r*4+c)*32 +: 32] = acc;
                end
            end
            c_out <= tmp;
        end
    end
endmodule
