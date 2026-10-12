`timescale 1ns / 1ps
module tb_cpu_fetch;
    reg clk = 0, resetn = 0;
    wire mem_valid, mem_instr;
    reg  mem_ready;
    wire [31:0] mem_addr, mem_wdata;
    wire [3:0]  mem_wstrb;
    reg  [31:0] mem_rdata;
    reg  [31:0] ram [0:255];
    integer cycles, n_fetch;

    picorv32 #(.PROGADDR_RESET(32'h0), .STACKADDR(32'h0000_0400)) cpu (
        .clk(clk), .resetn(resetn),
        .mem_valid(mem_valid), .mem_instr(mem_instr), .mem_ready(mem_ready),
        .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata)
    );
    always #5 clk = ~clk;

    // Simple memory: ready one cycle after valid, word-addressed
    always @(posedge clk) begin
        mem_ready <= 0;
        if (mem_valid && !mem_ready) begin
            mem_ready <= 1;
            mem_rdata <= ram[mem_addr[9:2]];
            if (mem_wstrb != 0) ram[mem_addr[9:2]] <= mem_wdata;
            $display("[%0t] %s addr=%h wstrb=%b rdata=%h",
                $time, mem_instr ? "FETCH" : "DATA ",
                mem_addr, mem_wstrb, ram[mem_addr[9:2]]);
            if (mem_instr) n_fetch = n_fetch + 1;
        end
    end

    initial begin
        ram[0] = 32'h00100093;  // addi x1, x0, 1
        ram[1] = 32'h00200113;  // addi x2, x0, 2
        ram[2] = 32'h0020A023;  // sw x2, 0(x1)  (store to 1; alignment will trap)
        ram[3] = 32'h0000006f;  // j .
        n_fetch = 0;
        #22 resetn = 1;
        #400;
        $display("fetches observed: %0d", n_fetch);
        $finish;
    end
endmodule
