module matrix_controller (
    input clk,
    input rst,
    input start,                          // Start computation
    output reg busy,                      // Busy flag
    output reg done,                      // Done flag
    output reg [1:0] state,               // State for debugging
    // Data loading interface
    output reg load_enable,               // Enable data loading
    output reg [2:0] row_addr,            // Row address for A/B
    output reg [2:0] col_addr,            // Column address for A/B
    // Matrix data
    output reg signed [7:0] a_data,       // A matrix element
    output reg signed [7:0] b_data        // B matrix element
);

    // State machine
    localparam IDLE = 2'b00, LOAD = 2'b01, COMPUTE = 2'b10, OUTPUT = 2'b11;
    
    reg [2:0] load_count;      // Counts loaded elements (0-15 for 4x4)
    reg [4:0] compute_count;   // Counts compute cycles (pipeline depth + data transit)
    
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
            load_enable <= 0;
            load_count <= 0;
            compute_count <= 0;
            row_addr <= 0;
            col_addr <= 0;
            a_data <=

cat > rtl/matrix_controller.v << 'EOF'
module matrix_controller (
    input clk,
    input rst,
    input start,                          // Start computation
    output reg busy,                      // Busy flag
    output reg done,                      // Done flag
    output reg [1:0] state,               // State for debugging
    // Data loading interface
    output reg load_enable,               // Enable data loading
    output reg [2:0] row_addr,            // Row address for A/B
    output reg [2:0] col_addr,            // Column address for A/B
    // Matrix data
    output reg signed [7:0] a_data,       // A matrix element
    output reg signed [7:0] b_data        // B matrix element
);

    // State machine
    localparam IDLE = 2'b00, LOAD = 2'b01, COMPUTE = 2'b10, OUTPUT = 2'b11;
    
    reg [2:0] load_count;      // Counts loaded elements (0-15 for 4x4)
    reg [4:0] compute_count;   // Counts compute cycles (pipeline depth + data transit)
    
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
            load_enable <= 0;
            load_count <= 0;
            compute_count <= 0;
            row_addr <= 0;
            col_addr <= 0;
            a_data <= 0;
            b_data <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        state <= LOAD;
                        busy <= 1;
                        load_count <= 0;
                        load_enable <= 1;
                    end
                end
                
                LOAD: begin
                    // Load 16 elements (4x4 matrix) row by row
                    if (load_count < 16) begin
                        row_addr <= load_count[3:2];  // Row: 0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3
                        col_addr <= load_count[1:0];  // Col: 0,1,2,3,0,1,2,3,...
                        // In real design, a_data and b_data come from external memory
                        // For now, just placeholder: you'd read from a FIFO or memory
                        load_count <= load_count + 1;
                    end else begin
                        load_enable <= 0;
                        state <= COMPUTE;
                        compute_count <= 0;
                    end
                end
                
                COMPUTE: begin
                    // Wait for pipeline to fill and data to propagate
                    // Systolic array: fill time = 2*N-1 = 2*4-1 = 7 cycles
                    // Then 1 more cycle for result to exit = 8 cycles total
                    if (compute_count < 8) begin
                        compute_count <= compute_count + 1;
                    end else begin
                        state <= OUTPUT;
                    end
                end
                
                OUTPUT: begin
                    done <= 1;
                    busy <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
