// Fit-check top: one output, keeps the full SoC including the accelerator.
module soc_fit (
    input  wire clk,
    input  wire rst,
    output wire obs
);
    wire [511:0] c_all;
    soc_mini soc (.clk(clk), .rst(rst), .c_out(c_all));
    assign obs = ^c_all;
endmodule
