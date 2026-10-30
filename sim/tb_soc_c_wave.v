`timescale 1ns / 1ps
module tb_soc_c_wave ();
    reg clk, rst;
    wire [511:0] c_out;
    integer cycle;
    
    soc_mini #(.ENABLE_MUL(1)) dut (
        .clk(clk), .rst(rst), .c_out(c_out)
    );
    
    initial begin
        $dumpfile("../build/soc_c.vcd");
        $dumpvars(0, tb_soc_c_wave);
    end
    
    initial begin
        clk = 0;
        rst = 1;
        cycle = 0;
        
        // Load compiled C firmware (matmul.c → prog_c.hex)
        $readmemh("prog_c.hex", dut.ram);
        
        #10 rst = 0;
        
        // Run for 2000 cycles (matmul expected ~1534)
        repeat(2000) begin
            @(posedge clk);
            cycle = cycle + 1;
        end
        
        $display("SoC C firmware: ran %0d cycles", cycle);
        $finish;
    end
    
    always #5 clk = ~clk;
endmodule
