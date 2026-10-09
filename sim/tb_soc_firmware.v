`timescale 1ns / 1ps

module tb_soc_firmware();
    reg clk, rst;
    wire uart_tx;
    integer read_count, write_count;
    reg [31:0] last_pc;
    
    soc_top dut (
        .clk(clk),
        .rst(rst),
        .uart_tx(uart_tx)
    );
    
    initial begin
        read_count = 0;
        write_count = 0;
        last_pc = 0;
        
        // Initialize RAM to zero
        for (int i = 0; i < 1024; i = i + 1) begin
            dut.mem[i] = 32'h0;
        end
        
        // Load firmware bytecode
        dut.mem[0] = 32'hdeadc7b7;
        dut.mem[1] = 32'heef78793;
        dut.mem[2] = 32'h80000737;
        dut.mem[3] = 32'h00f72023;
        dut.mem[4] = 32'h0000006f;
        
        clk = 0;
        rst = 1;
        #20 rst = 0;
        
        repeat(2000) begin
            #10 clk = ~clk;
        end
        
        $display("=== SoC Firmware Simulation ===");
        $display("Cycle count: %d", dut.cycle_count);
        $display("Memory reads: %d", read_count);
        $display("Memory writes: %d", write_count);
        $finish;
    end
    
    always @(posedge clk) begin
        if (dut.pcpu_re) begin
            read_count = read_count + 1;
            $display("[%d] READ addr=%h", dut.cycle_count, dut.pcpu_addr);
        end
        if (dut.pcpu_we) begin
            write_count = write_count + 1;
            $display("[%d] WRITE addr=%h data=%h", dut.cycle_count, dut.pcpu_addr, dut.pcpu_wdata);
        end
    end
endmodule
