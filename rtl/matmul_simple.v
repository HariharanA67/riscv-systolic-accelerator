// Simple 4x4 matmul: C = A × B
module matmul_simple (
    input clk,
    input rst,
    input signed [7:0] a [15:0],   // A matrix (flattened)
    input signed [7:0] b [15:0],   // B matrix (flattened)
    output reg signed [31:0] c [15:0]  // C matrix (flattened)
);

    integer i, j, k;
    reg signed [31:0] sum;
    
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 16; i = i + 1)
                c[i] <= 0;
        end else begin
            // Compute all C elements in parallel
            for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 4; j = j + 1) begin
                    sum = 0;
                    for (k = 0; k < 4; k = k + 1) begin
                        sum = sum + (a[i*4 + k] * b[k*4 + j]);
                    end
                    c[i*4 + j] <= sum;
                end
            end
        end
    end
endmodule
