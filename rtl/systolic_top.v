// Serial-I/O wrapper for systolic_os_4x4.
// Load: while shift_en is high and not busy, send 256 bits: first A, then B.
//       Each 128-bit vector is sent MSB first (vector bit 127 first, bit 0 last),
//       so element e (bits [e*8 +: 8]) ends up in the right place.
// Start: pulse start (after loading). The array is fed a skewed schedule for
//        10 cycles, then C is captured on the following cycle.
// Read: after done, while shift_en is high, 512 bits of C come out on dout,
//       MSB first (bit 511 first, which is C element 15's top bit).
module systolic_top (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire shift_en,
    input  wire din,
    output wire dout,
    output reg  done
);
    reg [127:0] a_sr, b_sr;
    reg [511:0] c_sr;
    reg [8:0]   load_cnt;   // 0..256 bits loaded
    reg [8:0]   read_cnt;   // 0..512 bits read
    reg [3:0]   feed_cnt;   // 0..10
    reg         feeding, reading, clr;
    wire [511:0] c_flat;
    reg  [31:0]  a_in_flat, b_in_flat;

    // Skewed feed. Row i gets A[i][k] with k = feed_cnt - i.
    // Column i gets B[k][i] with k = feed_cnt - i. Outside 0..3, the value is 0.
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
            a_sr <= 0; b_sr <= 0; c_sr <= 0;
            load_cnt <= 0; read_cnt <= 0; feed_cnt <= 0;
            feeding <= 0; reading <= 0; clr <= 0; done <= 0;
        end else begin
            // Load phase
            if (!feeding && !reading && !done && shift_en && load_cnt < 256) begin
                if (load_cnt < 128)
                    a_sr <= {a_sr[126:0], din};
                else
                    b_sr <= {b_sr[126:0], din};
                load_cnt <= load_cnt + 1;
            end
            // Start feeding
            if (start && load_cnt == 256 && !feeding && !done) begin
                feeding <= 1; feed_cnt <= 0; clr <= 1;
            end
            // Feed for cycles 0..9, then capture on cycle 10
            if (feeding) begin
                clr <= 0;
                feed_cnt <= feed_cnt + 1;
                if (feed_cnt == 10) begin
                    feeding <= 0;
                    done <= 1;
                    c_sr <= c_flat;
                    reading <= 1;
                    read_cnt <= 0;
                end
            end
            // Read phase
            if (reading && shift_en) begin
                c_sr <= {c_sr[510:0], 1'b0};
                read_cnt <= read_cnt + 1;
                if (read_cnt == 511) reading <= 0;
            end
        end
    end

    assign dout = c_sr[511];
endmodule
