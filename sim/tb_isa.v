`timescale 1ns / 1ps
module tb_isa;
    reg clk = 0, rst = 1;
    soc_mini dut (.clk(clk), .rst(rst));
    always #5 clk = ~clk;

    localparam [31:0] JUMP_SELF = 32'h0000006f;
    localparam integer MAX_CYCLES = 50000;
    localparam integer NEED_HITS  = 5;

    reg [31:0] FINAL_LOOP;
    integer cycles, loop_hits, first_loop_cycle, errors, checks, fd, rc;
    reg [31:0] addr, want, got;
    reg [8*16-1:0] name;
    reg [31:0] rfinal;

    always @(posedge clk) begin
        if (!rst && dut.mem_valid && dut.mem_instr && !dut.mem_ready) begin
            if (dut.mem_addr == FINAL_LOOP && dut.mem_rdata == JUMP_SELF) begin
                loop_hits <= loop_hits + 1;
                if (first_loop_cycle < 0) first_loop_cycle = cycles;
            end else begin
                loop_hits <= 0;
            end
        end
    end

    initial begin
        errors = 0; checks = 0; loop_hits = 0; first_loop_cycle = -1; cycles = 0;
        fd = $fopen("final_addr.txt", "r");
        rc = $fscanf(fd, "%h", rfinal);
        $fclose(fd);
        FINAL_LOOP = rfinal;
        $readmemh("prog_isa.hex", dut.ram);
        #22 rst = 0;
        for (cycles = 0; cycles < MAX_CYCLES && loop_hits < NEED_HITS; cycles = cycles + 1)
            @(posedge clk);
        if (loop_hits < NEED_HITS) begin
            $display("ISA FAILED: did not reach final loop within %0d cycles", MAX_CYCLES);
            $finish;
        end
        $display("ISA program reached final loop after %0d cycles", cycles);
        fd = $fopen("expect_isa.txt", "r");
        while (!$feof(fd)) begin
            rc = $fscanf(fd, "%h %h %s\n", addr, want, name);
            if (rc == 3) begin
                checks = checks + 1;
                got = dut.ram[addr[11:2]];
                if (got !== want) begin
                    errors = errors + 1;
                    $display("MISMATCH %0s @%h: got %h expected %h", name, addr, got, want);
                end
            end
        end
        $fclose(fd);
        if (errors == 0) $display("ISA PASSED: %0d checks", checks);
        else             $display("ISA FAILED: %0d of %0d checks wrong", errors, checks);
        $finish;
    end
endmodule
