`timescale 1ns / 1ps
module tb_isa_trap;
    reg clk = 0, rst = 1;
    soc_mini dut (.clk(clk), .rst(rst));
    always #5 clk = ~clk;
    integer cyc;
    initial begin
        $readmemh("prog_isa.hex", dut.ram);
        #22 rst = 0;
        for (cyc = 0; cyc < 2500; cyc = cyc + 1) @(posedge clk);
        $display("TRAP=%0d", dut.cpu.trap);
        $display("STATE=%0d", dut.cpu.cpu_state);
        $display("INSTR584=%h", dut.ram[12'h584>>2]);
        $display("INSTR580=%h", dut.ram[12'h580>>2]);
        $display("INSTR57C=%h", dut.ram[12'h57c>>2]);
        $finish;
    end
endmodule
