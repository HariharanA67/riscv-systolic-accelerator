`timescale 1ns / 1ps
module tb_srli_min;
    reg clk = 0, rst = 1;
    soc_mini dut (.clk(clk), .rst(rst));
    always #5 clk = ~clk;
    integer cyc;
    initial begin
        dut.ram[0] = 32'h800000b7;   // lui x1, 0x80000
        dut.ram[1] = 32'hf3208093;   // addi x1, x1, -208
        dut.ram[2] = 32'h0020d193;   // srli x3, x1, 2
        dut.ram[3] = 32'h0000006f;   // j .
        #22 rst = 0;
        for (cyc = 0; cyc < 200; cyc = cyc + 1) @(posedge clk);
        $display("TRAP=%0d x1 fetched sequence done", dut.cpu.trap);
        $finish;
    end
endmodule
