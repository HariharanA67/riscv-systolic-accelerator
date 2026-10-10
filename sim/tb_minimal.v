`timescale 1ns / 1ps

module tb_minimal();
    reg clk, rst;
    wire uart_tx;
    
    soc_top dut (
        .clk(clk),
        .rst(rst),
        .uart_tx(uart_tx)
    );
    
    initial begin
        // Fill RAM with NOPs (0x00000013)
        for (int i = 0; i < 1024; i++) begin
            dut.mem[i] = 32'h00000013;
        end
        
        clk = 0;
        rst = 1;
        #100 rst = 0;  // Long reset
        
        repeat(1000) begin
            #10 clk = ~clk;
        end
        
        $display("Cycle count: %d", dut.cycle_count);
        $finish;
    end
    
    always @(posedge clk) begin
        if (dut.pcpu_mem_valid) begin
            $display("[%d] mem_valid=%b instr=%b addr=%h", 
                dut.cycle_count, dut.pcpu_mem_valid, dut.pcpu_mem_instr, dut.pcpu_addr);
        end
    end
endmodule
