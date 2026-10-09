module soc_top (
    input clk,
    input rst,
    output uart_tx
);

    // PicoRV32 signals
    wire [31:0] pcpu_addr;
    wire [31:0] pcpu_wdata;
    wire [3:0] pcpu_wstrb;
    wire pcpu_re, pcpu_we;
    wire pcpu_mem_valid;
    wire pcpu_mem_ready;
    reg [31:0] pcpu_rdata;
    
    // RAM
    reg [31:0] mem [0:1023];
    
    // Cycle counter
    reg [31:0] cycle_count = 32'h0;
    
    // Assign mem_valid
    assign pcpu_mem_valid = pcpu_re | pcpu_we;
    assign pcpu_mem_ready = 1'b1;  // Memory always ready
    
    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;
    end
    
    // Memory read/write
    always @(posedge clk) begin
        if (pcpu_we) begin
            // RAM write (all addresses for now)
            if (pcpu_wstrb[0]) mem[pcpu_addr[11:2]][7:0]   <= pcpu_wdata[7:0];
            if (pcpu_wstrb[1]) mem[pcpu_addr[11:2]][15:8]  <= pcpu_wdata[15:8];
            if (pcpu_wstrb[2]) mem[pcpu_addr[11:2]][23:16] <= pcpu_wdata[23:16];
            if (pcpu_wstrb[3]) mem[pcpu_addr[11:2]][31:24] <= pcpu_wdata[31:24];
        end
    end
    
    always @(*) begin
        pcpu_rdata = mem[pcpu_addr[11:2]];
    end
    
    // PicoRV32 core
    picorv32 #(
        .STACKADDR(32'h0FFF),
        .PROGADDR_RESET(32'h0)
    ) cpu (
        .clk(clk),
        .resetn(~rst),
        .mem_valid(pcpu_mem_valid),
        .mem_ready(pcpu_mem_ready),
        .mem_instr(pcpu_re),
        .mem_addr(pcpu_addr),
        .mem_wdata(pcpu_wdata),
        .mem_wstrb(pcpu_wstrb),
        .mem_rdata(pcpu_rdata)
    );
    
    assign uart_tx = 1'b1;  // Stub
    
endmodule
