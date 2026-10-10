module soc_top_wb (
    input clk,
    input rst,
    output uart_tx
);

    wire [31:0] wb_adr;
    wire [31:0] wb_wdata;
    wire [3:0] wb_sel;
    wire wb_we;
    wire wb_stb;
    wire wb_cyc;
    reg [31:0] wb_rdata;
    reg wb_ack;
    
    reg [31:0] mem [0:1023];
    reg [31:0] cycle_count = 32'h0;
    
    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;
    end
    
    always @(posedge clk) begin
        wb_ack <= 0;
        if (wb_stb && wb_cyc && !wb_ack) begin
            wb_ack <= 1;
            if (wb_we) begin
                if (wb_sel[0]) mem[wb_adr[11:2]][7:0]   <= wb_wdata[7:0];
                if (wb_sel[1]) mem[wb_adr[11:2]][15:8]  <= wb_wdata[15:8];
                if (wb_sel[2]) mem[wb_adr[11:2]][23:16] <= wb_wdata[23:16];
                if (wb_sel[3]) mem[wb_adr[11:2]][31:24] <= wb_wdata[31:24];
            end
            wb_rdata <= mem[wb_adr[11:2]];
        end
    end
    
    picorv32_wb cpu (
        .wb_clk_i(clk),
        .wb_rst_i(rst),
        .wbm_adr_o(wb_adr),
        .wbm_dat_o(wb_wdata),
        .wbm_dat_i(wb_rdata),
        .wbm_we_o(wb_we),
        .wbm_sel_o(wb_sel),
        .wbm_stb_o(wb_stb),
        .wbm_ack_i(wb_ack),
        .wbm_cyc_o(wb_cyc)
    );
    
    assign uart_tx = 1'b1;
    
endmodule
