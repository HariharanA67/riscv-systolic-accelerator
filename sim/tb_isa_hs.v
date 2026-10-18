`timescale 1ns / 1ps
module tb_isa_hs;
    reg clk = 0, rst = 1;
    soc_mini dut (.clk(clk), .rst(rst));
    always #5 clk = ~clk;
    integer cyc;
    initial begin
        $readmemh("prog_isa.hex", dut.ram);
        #22 rst = 0;
        for (cyc = 0; cyc < 2445; cyc = cyc + 1) begin
            @(posedge clk);
            if (cyc >= 2426)
                $display("t=%0d valid=%b instr=%b ready=%b addr=%h wstrb=%b pc_state=%0d",
                    cyc, dut.mem_valid, dut.mem_instr, dut.mem_ready, dut.mem_addr, dut.mem_wstrb, dut.cpu.cpu_state);
        end
        $finish;
    end
endmodule
