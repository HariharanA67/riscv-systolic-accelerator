// Serial-I/O wrapper for systolic_os_4x4. Back-to-back runs without reset.
// States: LOAD (256 bits, A then B, MSB first) -> RUN (10 feed cycles)
//         -> READ (512 bits of C, MSB first). READ returns to LOAD when done.
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
    reg [8:0]   cnt;        // bit counter within the current phase
    reg [3:0]   feed_cnt;
    reg         clr;
    wire [511:0] c_flat;

    // Skewed feed: row i gets A[i][k], column i gets B[k][i], with k = feed_cnt - i.
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
            a_sr <= 0; b_sr <= 0; c_sr <= 0;
        end else begin
            case (state)
                S_LOAD: begin
                    clr <= 0;
                    if (shift_en) begin
                        if (cnt < 128) a_sr <= {a_sr[126:0], din};
                        else           b_sr <= {b_sr[126:0], din};
                        if (cnt == 255) begin
                            cnt <= 0;
                            // Wait for start before running
                        end else begin
                            cnt <= cnt + 1;
                        end
                    end
                    if (start && cnt == 0 && done == 0) begin
                        state <= S_RUN; feed_cnt <= 0; clr <= 1;
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
                    if (shift_en) begin
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
