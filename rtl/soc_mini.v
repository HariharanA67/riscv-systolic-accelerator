// PicoRV32 + 4 KB RAM at 0x0000_0000 + accelerator at 0x8000_0000.
// Memory handshake matches the testbench model that passed Steps A and B.
module soc_mini (
    input wire clk,
    input wire rst
);
    wire        mem_valid, mem_instr;
    reg         mem_ready;
    wire [31:0] mem_addr, mem_wdata;
    wire [3:0]  mem_wstrb;
    reg  [31:0] mem_rdata;
    reg  [31:0] ram [0:1023];

    wire        sel_acc = mem_addr[31];
    wire        req     = mem_valid & ~mem_ready;
    wire [31:0] acc_rdata;

    accel_mmio acc (
        .clk(clk), .rst(rst),
        .req(req & sel_acc), .we(|mem_wstrb),
        .addr(mem_addr[11:0]), .wdata(mem_wdata), .rdata(acc_rdata)
    );

    always @(posedge clk) begin
        if (rst) begin
            mem_ready <= 0;
        end else begin
            mem_ready <= 0;
            if (req) begin
                mem_ready <= 1;
                if (sel_acc) begin
                    mem_rdata <= acc_rdata;
                end else begin
                    mem_rdata <= ram[mem_addr[11:2]];
                    if (mem_wstrb[0]) ram[mem_addr[11:2]][7:0]   <= mem_wdata[7:0];
                    if (mem_wstrb[1]) ram[mem_addr[11:2]][15:8]  <= mem_wdata[15:8];
                    if (mem_wstrb[2]) ram[mem_addr[11:2]][23:16] <= mem_wdata[23:16];
                    if (mem_wstrb[3]) ram[mem_addr[11:2]][31:24] <= mem_wdata[31:24];
                end
            end
        end
    end

    picorv32 #(.PROGADDR_RESET(32'h0), .STACKADDR(32'h0000_0400)) cpu (
        .clk(clk), .resetn(~rst),
        .mem_valid(mem_valid), .mem_instr(mem_instr), .mem_ready(mem_ready),
        .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata)
    );
endmodule
