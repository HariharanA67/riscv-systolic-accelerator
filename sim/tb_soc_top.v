module tb_soc_top ();

    reg clk, rst;
    wire uart_tx;
    
    soc_top dut (
        .clk(clk),
        .rst(rst),
        .uart_tx(uart_tx)
    );
    
    initial begin
        clk = 0;
        rst = 1;
        #20 rst = 0;
        
        // Run for 100 cycles to see clock ticking
        repeat(100) #10;
        
        $display("SoC simulation completed successfully");
        $display("Cycle count: %0d", dut.cycle_count);
        
        $finish;
    end
    
    always #5 clk = ~clk;

endmodule
