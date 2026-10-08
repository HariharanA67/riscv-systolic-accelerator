module soc_top (
    input clk,
    input rst,
    output uart_tx
);

    // PicoRV32 signals
    wire [31:0] pcpu_addr;
    wire [31:0] pcpu_wdata;
    reg [31:0] pcpu_rdata;
    wire pcpu_we;
    wire pcpu_re;
    wire pcpu_valid;
    
    // Memory (simulated RAM: 4KB)
    reg [31:0] mem [0:1023];
    
    // Cycle counter
    reg [31:0] cycle_count;
    
    // Helper wires for PicoRV32
    wire mem_valid = pcpu_re | pcpu_we;
    wire mem_instr = pcpu_re;
    wire [3:0] mem_wstrb = pcpu_we ? 4'hF : 4'h0;
    
    // PicoRV32 CPU
    picorv32 cpu (
        .clk(clk),
        .resetn(~rst),
        .mem_valid(mem_valid),
        .mem_instr(mem_instr),
        .mem_addr(pcpu_addr),
        .mem_wdata(pcpu_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(pcpu_rdata)
    );
    
    // Cycle counter
    always @(posedge clk) begin
        if (rst)
            cycle_count <= 0;
        else
            cycle_count <= cycle_count + 1;
    end
    
    // Memory read/write logic
    always @(posedge clk) begin
        if (pcpu_re && pcpu_addr[31:12] == 20'b0) begin
            // RAM read
            pcpu_rdata <= mem[pcpu_addr[11:2]];
        end else if (pcpu_re && pcpu_addr[31:10] == 22'h20000) begin
            // Accelerator register read
            case (pcpu_addr[5:2])
                4'h0: pcpu_rdata <= cycle_count;
                4'h1: pcpu_rdata <= 32'h0;
                default: pcpu_rdata <= 32'h0;
            endcase
        end
    end
    
    always @(posedge clk) begin
        if (pcpu_we && pcpu_addr[31:12] == 20'b0) begin
            // RAM write
            mem[pcpu_addr[11:2]] <= pcpu_wdata;
        end
    end
    
    assign uart_tx = 1'b1;

endmodule
