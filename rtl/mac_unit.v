module mac_unit (
    input clk,
    input rst,
    input signed [7:0] a,      // 8-bit signed input A
    input signed [7:0] b,      // 8-bit signed input B
    input signed [31:0] acc_in, // 32-bit accumulator input
    output signed [31:0] acc_out // 32-bit accumulator output
);

    wire signed [15:0] product; // 8x8 = 16 bits
    
    // Multiply A * B
    assign product = a * b;
    
    // Accumulate: acc_out = acc_in + product
    assign acc_out = acc_in + product;

endmodule
