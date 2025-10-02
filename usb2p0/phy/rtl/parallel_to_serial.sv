module parallel_to_serial #(
    parameter PARALLEL_WIDTH = 8
) (
    input  wire                           i_clk,
    input  wire                           i_rst_n,
    input  wire [PARALLEL_WIDTH-1:0]     i_data,
    input  wire                           i_valid,
    input  wire                           i_load,
    
    output reg                            o_data,
    output reg                            o_valid,
    output reg                            o_done
);

reg [PARALLEL_WIDTH-1:0] shift_reg;
reg [$clog2(PARALLEL_WIDTH)-1:0] bit_count;
reg active;

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        shift_reg <= {PARALLEL_WIDTH{1'b0}};
        bit_count <= 0;
        o_data <= 1'b0;
        o_valid <= 1'b0;
        o_done <= 1'b0;
        active <= 1'b0;
    end else if (i_load && i_valid) begin
        shift_reg <= i_data;
        bit_count <= 0;
        active <= 1'b1;
        o_done <= 1'b0;
    end else if (active) begin
        o_data <= shift_reg[PARALLEL_WIDTH-1];
        shift_reg <= {shift_reg[PARALLEL_WIDTH-2:0], 1'b0};
        o_valid <= 1'b1;
        bit_count <= bit_count + 1'b1;
        
        if (bit_count == PARALLEL_WIDTH-1) begin
            active <= 1'b0;
            o_done <= 1'b1;
            o_valid <= 1'b0;
        end
    end else begin
        o_valid <= 1'b0;
        o_done <= 1'b0;
    end
end

endmodule