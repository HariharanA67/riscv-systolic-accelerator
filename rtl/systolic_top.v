// Serial-I/O wrapper for systolic_os_4x4.
// LOAD: accepts exactly 256 bits (A then B, each MSB first) while shift_en is high.
//       Bits after the 256th are ignored. start is accepted only when all 256 bits are in.
// RUN:  10 feed cycles, then C is captured. shift_en is ignored.
// READ: one bit of C per RISING EDGE of shift_en (host must drop shift_en between bits),
//       MSB first. A held-over shift_en cannot shift the result.
//       After 512 bits, the wrapper returns to LOAD.
module systolic_top (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire shift_en,
    input  wire din,
    output wire dout,
    output reg  done
);
    localparam S_LOAD = 2'd0, S_RUN = 2'd1, S_READ = 2'd2;

    reg [1:0]   state;
    reg [127:0] a_sr, b_sr;
    reg [511:0] c_sr;
    reg [8:0]   cnt;
    reg [3:0]   feed_cnt;
    reg         clr;
    reg         loaded;
    reg         se_prev;     // previous shift_en, for rising-edge detection
    wire        se_rise = shift_en & ~se_prev;
    wire [511:0] c_flat;

    reg [31:0] a_in_flat, b_in_flat;
    integer i;
    always @(*) begin
        a_in_flat = 32'd0;
        b_in_flat = 32'd0;
        for (i = 0; i < 4; i = i + 1) begin
            if (feed_cnt >= i && (feed_cnt - i) < 4) begin
                a_in_flat[i*8 +: 8] = a_sr[((i*4) + (feed_cnt - i))*8 +: 8];
                b_in_flat[i*8 +: 8] = b_sr[(((feed_cnt - i)*4) + i)*8 +: 8];
            end
        end
    end

    systolic_os_4x4 array (
        .clk(clk), .rst(rst), .clr(clr),
        .a_in_flat(a_in_flat), .b_in_flat(b_in_flat), .c_out_flat(c_flat)
    );

    always @(posedge clk) begin
        if (rst) begin
            state <= S_LOAD; cnt <= 0; feed_cnt <= 0; clr <= 0; done <= 0;
            loaded <= 0; se_prev <= 0;
            a_sr <= 0; b_sr <= 0; c_sr <= 0;
        end else begin
            se_prev <= shift_en;
            case (state)
                S_LOAD: begin
                    clr <= 0;
                    if (shift_en && !loaded) begin
                        if (cnt < 128) a_sr <= {a_sr[126:0], din};
                        else           b_sr <= {b_sr[126:0], din};
                        if (cnt == 255) begin
                            loaded <= 1;
                            cnt    <= 0;
                        end else begin
                            cnt <= cnt + 1;
                        end
                    end
                    if (start && loaded) begin
                        state    <= S_RUN;
                        feed_cnt <= 0;
                        clr      <= 1;
                        done     <= 0;
                        loaded   <= 0;
                    end
                end
                S_RUN: begin
                    clr <= 0;
                    feed_cnt <= feed_cnt + 1;
                    if (feed_cnt == 10) begin
                        c_sr  <= c_flat;
                        done  <= 1;
                        state <= S_READ;
                        cnt   <= 0;
                    end
                end
                S_READ: begin
                    if (se_rise) begin
                        c_sr <= {c_sr[510:0], 1'b0};
                        cnt  <= cnt + 1;
                        if (cnt == 511) begin
                            state <= S_LOAD;
                            cnt   <= 0;
                            done  <= 0;
                        end
                    end
                end
            endcase
        end
    end

    assign dout = c_sr[511];
endmodule
