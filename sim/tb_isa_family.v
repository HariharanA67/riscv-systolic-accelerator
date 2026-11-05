`timescale 1ns / 1ps
module tb_isa_family;
    reg clk = 0, rst = 1;
    soc_mini dut (.clk(clk), .rst(rst));
    always #5 clk = ~clk;

    localparam [31:0] JUMP_SELF = 32'h0000006f;
    localparam integer MAX_CYCLES = 60000, NEED_HITS = 5;

    reg [31:0] FINAL_LOOP;
    integer cycles, loop_hits, errors, checks, fd, rc;
    reg [31:0] addr, want, got, rfinal;
    reg [8*24-1:0] name;
    reg [8*64-1:0] hexfile, expfile, finalfile;
    reg ok;

    always @(posedge clk) begin
        if (!rst && dut.mem_valid && dut.mem_instr && !dut.mem_ready) begin
            if (dut.mem_addr == FINAL_LOOP && dut.mem_rdata == JUMP_SELF)
                loop_hits <= loop_hits + 1;
            else
                loop_hits <= 0;
        end
    end

    initial begin
        if (!$value$plusargs("hex=%s", hexfile)) begin $display("ERROR: pass +hex= +exp= +fin="); $finish; end
        if (!$value$plusargs("exp=%s", expfile)) begin $display("ERROR: pass +hex= +exp= +fin="); $finish; end
        if (!$value$plusargs("fin=%s", finalfile)) begin $display("ERROR: pass +hex= +exp= +fin="); $finish; end
        errors = 0; checks = 0; loop_hits = 0;
        fd = $fopen(finalfile, "r"); rc = $fscanf(fd, "%h", rfinal); $fclose(fd);
        FINAL_LOOP = rfinal;
        $readmemh(hexfile, dut.ram);
        #22 rst = 0;
        ok = 0;
        for (cycles = 0; cycles < MAX_CYCLES && !ok; cycles = cycles + 1) begin
            @(posedge clk);
            if (loop_hits >= NEED_HITS) ok = 1;
        end
        if (!ok) begin
            $display("FAMILY FAILED %0s: no final loop within %0d cycles", hexfile, MAX_CYCLES);
            $finish;
        end
        fd = $fopen(expfile, "r");
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
        $display("FAMILY %0s: %0d checks, %0d wrong", hexfile, checks, errors);
        $finish;
    end
endmodule
