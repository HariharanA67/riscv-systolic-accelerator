`timescale 1ns / 1ps

module tb_soc_trap ();
    reg clk, rst;
    wire [511:0] c_out;
    wire trap_signal;
    integer cycle, max_cycles;
    string hexfile, test_name;
    
    soc_mini #(.ENABLE_MUL(1)) dut (
        .clk(clk),
        .rst(rst),
        .c_out(c_out)
    );
    
    // Read trap from the core
    assign trap_signal = dut.cpu.trap;
    
    initial begin
        clk = 0;
        rst = 1;
        cycle = 0;
        max_cycles = 10000;
        
        // Get test name from plusarg
        if (!$value$plusargs("test=%s", test_name)) test_name = "ebreak";
        
        if (test_name == "ebreak")
            hexfile = "prog_trap_ebreak.hex";
        else if (test_name == "illegal")
            hexfile = "prog_trap_illegal.hex";
        else begin
            $display("ERROR: unknown test '%s'", test_name);
            $finish;
        end
        
        $readmemh(hexfile, dut.ram);
        
        #10 rst = 0;
        
        // Run until trap or timeout
        repeat(max_cycles) begin
            @(posedge clk);
            cycle = cycle + 1;
            if (trap_signal) begin
                $display("TRAP %0s: caught at cycle %0d", test_name, cycle);
                $finish;
            end
        end
        
        $display("TRAP %0s: FAILED no trap within %0d cycles", test_name, max_cycles);
        $finish;
    end
    
    always #5 clk = ~clk;

endmodule
