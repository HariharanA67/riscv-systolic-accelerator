`timescale 1ns / 1ps
module tb_soc_opt_debug ();
    reg clk, rst;
    integer cycle;
    
    soc_mini #(.ENABLE_MUL(1)) dut (
        .clk(clk),
        .rst(rst)
    );
    
    initial begin
        clk = 0;
        rst = 1;
        cycle = 0;
        
        $readmemh("prog_opt.hex", dut.ram);
        
        #10 rst = 0;
        
        repeat(2000) begin
            @(posedge clk);
            cycle = cycle + 1;
            // Print PC and busy flag every 50 cycles
            if (cycle % 50 == 0 || cycle < 20 || cycle > 1450) begin
                $display("C=%4d PC=%08x ACC_BUSY=%d", cycle, dut.cpu.reg_pc, dut.accel.busy);
            end
        end
        
        $finish;
    end
    
    always #5 clk = ~clk;
endmodule
