// Memory-mapped wrapper for systolic_os_4x4.
module accel_mmio (
    input  wire         clk,
    input  wire         rst,
    input  wire         req,
    input  wire         we,
    input  wire [11:0]  addr,
    input  wire [31:0]  wdata,
    output wire [31:0]  rdata,
    output wire [511:0] c_out
);
    reg [127:0] a_vec, b_vec;
    reg         busy, done, clr;
    reg [3:0]   feed_cnt;
    wire [511:0] c_flat;
    reg  [31:0]  a_in_flat, b_in_flat;
    wire [3:0]   k = addr[5:2];

    integer i;
    always @(*) begin
        a_in_flat = 32'd0;
        b_in_flat = 32'd0;
        for (i = 0; i < 4; i = i + 1) begin
            if (feed_cnt >= i && (feed_cnt - i) < 4) begin
                a_in_flat[i*8 +: 8] = a_vec[((i*4) + (feed_cnt - i))*8 +: 8];
                b_in_flat[i*8 +: 8] = b_vec[(((feed_cnt - i)*4) + i)*8 +: 8];
            end
        end
    end

    systolic_os_4x4 array (
        .clk(clk), .rst(rst), .clr(clr),
        .a_in_flat(a_in_flat), .b_in_flat(b_in_flat), .c_out_flat(c_flat)
    );

    always @(posedge clk) begin
        if (rst) begin
            a_vec <= 0; b_vec <= 0;
            busy <= 0; done <= 0; clr <= 0; feed_cnt <= 0;
        end else begin
            clr <= 0;
            if (busy) begin
                feed_cnt <= feed_cnt + 1;
                if (feed_cnt == 4'd10) begin
                    busy <= 0;
                    done <= 1;
                end
            end
            if (req && we && !busy) begin
                if (addr[11:8] == 4'h1 && addr[7:6] == 2'b00) a_vec[k*8 +: 8] <= wdata[7:0];
                if (addr[11:8] == 4'h2 && addr[7:6] == 2'b00) b_vec[k*8 +: 8] <= wdata[7:0];
                if (addr == 12'h000 && wdata[0]) begin
                    busy <= 1; done <= 0; feed_cnt <= 0; clr <= 1;
                end
            end
        end
    end

    assign rdata = (addr == 12'h004) ? {30'd0, busy, done} :
                   (addr[11:8] == 4'h3 && addr[7:6] == 2'b00) ? c_flat[k*32 +: 32] :
                   32'd0;
    assign c_out = c_flat;
endmodule
