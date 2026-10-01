module processing_element (
    input clk,
    input rst,
    input signed [7:0] a_in,      // Data flowing down
    input signed [7:0] b_in,      // Data flowing right
    input signed [31:0] acc_in,   // Accumulator from above
    output signed [7:0] a_out,    // Forward A to next PE
    output signed [7:0] b_out,    // Forward B to next PE
    output signed [31:0] acc_out  // Result to next PE
);

    wire signed [31:0] mac_result;
    
    // MAC computation
    mac_unit mac (
        .clk(clk),
        .rst(rst),
        .a(a_in),
        .b(b_in),
        .acc_in(acc_in),
        .acc_out(mac_result)
    );
    
    // Pipeline registers (one cycle delay)
    reg signed [7:0] a_reg, b_reg;
    reg signed [31:0] acc_reg;
    
    always @(posedge clk) begin
        if (rst) begin
            a_reg <= 0;
            b_reg <= 0;
            acc_reg <= 0;
        end else begin
            a_reg <= a_in;
            b_reg <= b_in;
            acc_reg <= mac_result;
        end
    end
    
    assign a_out = a_reg;
    assign b_out = b_reg;
    assign acc_out = acc_reg;

endmodule
