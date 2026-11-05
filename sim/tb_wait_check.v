`timescale 1ns / 1ps
module tb_wait_check;
    reg clk = 0, rst = 1;
    reg stall_en = 0;
    wire [511:0] c_out;
    integer seed, stall_on, cycles, stalls, sc, hits, n, errors, fd, r, i;
    reg [31:0] addr, val, got, final_addr, rnd;
    reg [8*16-1:0] name;

    soc_mini #(.ENABLE_MUL(1)) dut (.clk(clk), .rst(rst), .stall_en(stall_en), .c_out(c_out));
    always #5 clk = ~clk;

    always @(negedge clk) begin
        if (!rst && stall_on) begin
            if (sc > 0) begin
                stall_en = 1; sc = sc - 1; stalls = stalls + 1;
            end else begin
                stall_en = 0;
                rnd = $random(seed);
                if (rnd[1:0] == 2'b00)
                    sc = (rnd[3:2] == 2'b00) ? 1 : rnd[3:2];
            end
        end
    end

    always @(posedge clk) begin
        if (!rst && dut.mem_valid && dut.mem_instr && !dut.mem_ready) begin
            if (dut.mem_addr == final_addr && dut.mem_rdata == 32'h6f)
                hits <= hits + 1;
            else
                hits <= 0;
        end
    end

    initial begin
        if (!$value$plusargs("stall=%d", stall_on)) stall_on = 0;
        if (!$value$plusargs("seed=%d", seed))      seed = 42;
        sc = 0; stalls = 0; hits = 0; errors = 0; n = 0;

        fd = $fopen("final_addr_arith_add_0.txt", "r");
        r = $fscanf(fd, "%h", final_addr);
        $fclose(fd);

        $readmemh("prog_arith_add_0.hex", dut.ram);
        #22 rst = 0;

        cycles = 0;
        while (cycles < 400000 && hits < 5) begin
            @(posedge clk);
            cycles = cycles + 1;
        end

        if (hits < 5) begin
            $display("WAIT CHECK FAILED: program did not reach final loop within 400000 cycles");
            $finish;
        end

        fd = $fopen("expect_arith_add_0.txt", "r");
        while (!$feof(fd)) begin
            r = $fscanf(fd, "%h %h %s\n", addr, val, name);
            if (r == 3) begin
                n = n + 1;
                got = dut.ram[addr[11:2]];
                if (got !== val) begin
                    errors = errors + 1;
                    $display("MISMATCH %h: got %h expected %h", addr, got, val);
                end
            end
        end
        $fclose(fd);

        $display("stall_on=%0d seed=%0d cycles=%0d stall_cycles=%0d words_checked=%0d errors=%0d",
                 stall_on, seed, cycles, stalls, n, errors);
        if (n == 39 && errors == 0 && (stall_on == 0 || stalls > 0))
            $display("WAIT CHECK PASSED");
        else
            $display("WAIT CHECK FAILED");
        $finish;
    end
endmodule
