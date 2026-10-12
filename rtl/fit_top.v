// Fit-check wrapper: keeps matmul_simple's logic but exposes few I/O pins.
// Inputs come from a shift register; the output is reduced to one bit.
module fit_top (
    input  wire clk,
    input  wire rst,
    input  wire din,        // serial input bit
    input  wire load,       // shift one bit into A/B registers
    output wire dout        // XOR of all result bits
);
    reg signed [127:0] a_reg, b_reg;
    wire signed [511:0] c_w;

    always @(posedge clk) begin
        if (rst) begin
            a_reg <= 0;
            b_reg <= 0;
        end else if (load) begin
            a_reg <= {a_reg[126:0], din};
            b_reg <= {b_reg[126:0], a_reg[127]};
        end
    end

    matmul_simple core (
        .clk(clk), .rst(rst),
        .a_in(a_reg), .b_in(b_reg),
        .c_out(c_w)
    );

    assign dout = ^c_w;
endmodule
