// Output-stationary PE: each PE owns one accumulator (one C element).
// A flows left -> right, B flows top -> bottom, one cycle per hop.
module pe_os (
    input  wire               clk,
    input  wire               rst,
    input  wire               clr,      // clear accumulator (start of a new product)
    input  wire signed [7:0]  a_in,
    input  wire signed [7:0]  b_in,
    output reg  signed [7:0]  a_out,
    output reg  signed [7:0]  b_out,
    output reg  signed [31:0] acc
);
    always @(posedge clk) begin
        if (rst) begin
            a_out <= 0;
            b_out <= 0;
            acc   <= 0;
        end else begin
            a_out <= a_in;
            b_out <= b_in;
            if (clr)
                acc <= a_in * b_in;
            else
                acc <= acc + a_in * b_in;
        end
    end
endmodule
