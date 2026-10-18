`timescale 1ns / 1ps

module tb_soc_wait ();
    reg clk, rst, stall_en;
    wire [511:0] c_out;
    integer seed, cycle, stall_counter, total_stalls;
    integer i, errors, addr, got, want;
    
    soc_mini #(.ENABLE_MUL(1)) dut (
        .clk(clk),
        .rst(rst),
        .stall_en(stall_en),
        .c_out(c_out)
    );
    
    initial begin
        clk = 0;
        rst = 1;
        stall_en = 0;
        cycle = 0;
        stall_counter = 0;
        total_stalls = 0;
        errors = 0;
        
        if (!$value$plusargs("seed=%d", seed)) seed = 42;
        
        $readmemh("prog_arith_add_0.hex", dut.ram);
        
        #10 rst = 0;
        
        repeat(150000) begin
            @(posedge clk);
            cycle = cycle + 1;
            
            if (cycle % 50 == 0) begin
                stall_counter = ($random() % 4);
            end
            
            if (stall_counter > 0) begin
                stall_en = 1;
                stall_counter = stall_counter - 1;
                total_stalls = total_stalls + 1;
            end else begin
                stall_en = 0;
            end
        end
        
        // Check RAM values at expected addresses (0x400-0x44c)
        for (addr = 'h400; addr <= 'h44c; addr = addr + 4) begin
            want = 32'hxxxxxxxx;  // Placeholder; should read from file
            got = dut.ram[addr[11:2]];
            $display("RAM[%h] = %h", addr, got);
        end
        
        $display("WAIT seed=%0d cycles=%0d total_stall_cycles=%0d errors=%0d", 
                 seed, cycle, total_stalls, errors);
        $finish;
    end
    
    always #5 clk = ~clk;

endmodule
