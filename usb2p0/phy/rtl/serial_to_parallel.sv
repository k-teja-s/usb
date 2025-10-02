module serial_to_parallel #(
    parameter PARALLEL_WIDTH = 8
) (
    input  wire                           i_clk,
    input  wire                           i_rst_n,
    input  wire                           i_data,
    input  wire                           i_valid,
    input  wire                           i_sync_pattern,  // SYNC field detected
    
    output reg  [PARALLEL_WIDTH-1:0]     o_data,
    output reg                            o_valid,
    output reg                            o_error
);

reg [PARALLEL_WIDTH-1:0] shift_reg;
reg [$clog2(PARALLEL_WIDTH)-1:0] bit_count;
reg sync_detected;

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        shift_reg <= {PARALLEL_WIDTH{1'b0}};
        bit_count <= 0;
        o_data <= {PARALLEL_WIDTH{1'b0}};
        o_valid <= 1'b0;
        o_error <= 1'b0;
        sync_detected <= 1'b0;
    end else if (i_sync_pattern) begin
        bit_count <= 0;
        sync_detected <= 1'b1;
        o_error <= 1'b0;
    end else if (i_valid && sync_detected) begin
        shift_reg <= {shift_reg[PARALLEL_WIDTH-2:0], i_data};
        bit_count <= bit_count + 1'b1;
        
        if (bit_count == PARALLEL_WIDTH-1) begin
            o_data <= {shift_reg[PARALLEL_WIDTH-2:0], i_data};
            o_valid <= 1'b1;
            bit_count <= 0;
        end else begin
            o_valid <= 1'b0;
        end
    end else begin
        o_valid <= 1'b0;
    end
end

endmodule