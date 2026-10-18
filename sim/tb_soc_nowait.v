`timescale 1ns / 1ps

module tb_soc_nowait ();
    reg clk, rst;
    wire [511:0] c_out;
    integer cycle, addr;
    
    soc_mini #(.ENABLE_MUL(1)) dut (
        .clk(clk),
        .rst(rst),
        .stall_en(1'b0),
        .c_out(c_out)
    );
    
    initial begin
        clk = 0;
        rst = 1;
        cycle = 0;
        
        $readmemh("prog_arith_add_0.hex", dut.ram);
        
        #10 rst = 0;
        
        repeat(150000) begin
            @(posedge clk);
            cycle = cycle + 1;
        end
        
        for (addr = 'h400; addr <= 'h44c; addr = addr + 4) begin
            $display("RAM[%h] = %h", addr, dut.ram[addr[11:2]]);
        end
        
        $display("NOWAIT cycles=%0d", cycle);
        $finish;
    end
    
    always #5 clk = ~clk;

endmodule
