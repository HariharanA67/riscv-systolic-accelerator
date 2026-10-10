`timescale 1ns / 1ps

module tb_soc_wb();
    reg clk, rst;
    wire uart_tx;
    
    soc_top_wb dut (
        .clk(clk),
        .rst(rst),
        .uart_tx(uart_tx)
    );
    
    initial begin
        // Load NOP instructions
        for (int i = 0; i < 1024; i = i + 1) begin
            dut.mem[i] = 32'h00000013;
        end
        
        clk = 0;
        rst = 1;
        #100 rst = 0;
        
        repeat(500) #10 clk = ~clk;
        
        $display("Cycle count: %d", dut.cycle_count);
        $finish;
    end
    
    always @(posedge clk) begin
        if (dut.wb_stb) begin
            $display("[%d] WB access addr=%h", dut.cycle_count, dut.wb_adr);
        end
    end
endmodule
