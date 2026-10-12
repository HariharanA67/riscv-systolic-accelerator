`timescale 1ns / 1ps
module tb_cpu_store;
    reg clk = 0, resetn = 0;
    wire mem_valid, mem_instr;
    reg  mem_ready;
    wire [31:0] mem_addr, mem_wdata;
    wire [3:0]  mem_wstrb;
    reg  [31:0] mem_rdata;
    reg  [31:0] ram [0:255];
    reg  saw_store;
    integer i;

    picorv32 #(.PROGADDR_RESET(32'h0), .STACKADDR(32'h0000_0400)) cpu (
        .clk(clk), .resetn(resetn),
        .mem_valid(mem_valid), .mem_instr(mem_instr), .mem_ready(mem_ready),
        .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata)
    );
    always #5 clk = ~clk;

    always @(posedge clk) begin
        mem_ready <= 0;
        if (mem_valid && !mem_ready) begin
            mem_ready <= 1;
            mem_rdata <= ram[mem_addr[9:2]];
            if (mem_wstrb != 0) begin
                ram[mem_addr[9:2]] <= mem_wdata;
                if (mem_addr == 32'h100 && mem_wdata == 32'hCAFE1234) saw_store <= 1;
                $display("[%0t] STORE addr=%h data=%h wstrb=%b", $time, mem_addr, mem_wdata, mem_wstrb);
            end
        end
    end

    initial begin
        for (i = 0; i < 256; i = i + 1) ram[i] = 0;
        // lui x1, 0x0     ; x1 = 0 (base)
        // lui x2, 0xCAFE1 ; x2 = 0xCAFE1000
        // addi x2, x2, 0x234 ; x2 = 0xCAFE1234
        // addi x3, x0, 0x100 ; x3 = 0x100
        // sw x2, 0(x3)
        // jal x0, .
        ram[0] = 32'h00000097; // placeholder, replaced below
        ram[0] = 32'hCAFE1137; // lui x2, 0xCAFE1
        ram[1] = 32'h23410113; // addi x2, x2, 0x234
        ram[2] = 32'h10000193; // addi x3, x0, 0x100
        ram[3] = 32'h0021A023; // sw x2, 0(x3)
        ram[4] = 32'h0000006f; // j .
        saw_store = 0;
        #22 resetn = 1;
        #600;
        if (saw_store) $display("STORE TEST PASSED: 0xCAFE1234 written to 0x100");
        else           $display("STORE TEST FAILED");
        $finish;
    end
endmodule
