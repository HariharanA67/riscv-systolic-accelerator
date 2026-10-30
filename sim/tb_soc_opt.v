`timescale 1ns / 1ps
module tb_soc_opt ();
    reg clk, rst;
    wire [511:0] c_out;
    integer cycle, done_cycle;
    
    soc_mini #(.ENABLE_MUL(1)) dut (
        .clk(clk),
        .rst(rst),
        .c_out(c_out)
    );
    
    initial begin
        clk = 0;
        rst = 1;
        cycle = 0;
        done_cycle = 0;
        
        $readmemh("prog_opt.hex", dut.ram);
        
        #10 rst = 0;
        
        // Run until we return from main (x1 goes back to near 0x8)
        repeat(50000) begin
            @(posedge clk);
            cycle = cycle + 1;
            if (dut.cpu.reg_pc >= 32'h8 && dut.cpu.reg_pc <= 32'h10 && done_cycle == 0) begin
                done_cycle = cycle;
            end
        end
        
        $display("OPT done_cycle=%0d", done_cycle);
        $finish;
    end
    
    always #5 clk = ~clk;
endmodule
