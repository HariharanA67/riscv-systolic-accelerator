`timescale 1ns / 1ps
module tb_isa_where;
    reg clk = 0, rst = 1;
    soc_mini dut (.clk(clk), .rst(rst));
    always #5 clk = ~clk;
    integer cyc, last_pc_printed;
    reg [31:0] last_pc;
    integer fetches;
    initial begin
        fetches = 0; last_pc = 0;
        $readmemh("prog_isa.hex", dut.ram);
        #22 rst = 0;
        for (cyc = 0; cyc < 50000; cyc = cyc + 1) begin
            @(posedge clk);
            if (dut.mem_valid && !dut.mem_ready) begin
                $display("req t=%0d instr=%b addr=%h wstrb=%b", cyc, dut.mem_instr, dut.mem_addr, dut.mem_wstrb);
                fetches = fetches + 1;
                last_pc = dut.mem_addr;
            end
        end
        $display("total fetches: %0d", fetches);
        $display("last fetched PC: %h", last_pc);
        $display("instruction there: %h", dut.ram[last_pc[11:2]]);
        $finish;
    end
endmodule
