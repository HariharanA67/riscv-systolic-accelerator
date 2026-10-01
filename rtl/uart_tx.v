module uart_tx (
    input clk,
    input rst,
    input [7:0] data_in,
    input send,
    output reg tx,
    output reg busy
);

    localparam CLK_PER_BIT = 868;  // For 115200 baud @ 100MHz
    
    reg [13:0] baud_counter;
    reg [3:0] bit_index;
    reg [9:0] shift_reg;  // Start + 8 data + stop
    
    always @(posedge clk) begin
        if (rst) begin
            tx <= 1;
            busy <= 0;
            baud_counter <= 0;
            bit_index <= 0;
        end else if (send && !busy) begin
            shift_reg <= {1'b1, data_in, 1'b0};  // stop, data, start
            bit_index <= 0;
            busy <= 1;
            baud_counter <= 0;
        end else if (busy) begin
            if (baud_counter < CLK_PER_BIT - 1) begin
                baud_counter <= baud_counter + 1;
            end else begin
                baud_counter <= 0;
                tx <= shift_reg[bit_index];
                if (bit_index < 9) begin
                    bit_index <= bit_index + 1;
                end else begin
                    busy <= 0;
                end
            end
        end
    end

endmodule
