module bit_stuffer (
    input  wire       i_clk,
    input  wire       i_rst_n,
    input  wire       i_data,
    input  wire       i_valid,
    input  wire       i_packet_start,
    
    output reg        o_data,
    output reg        o_valid
);

reg [2:0] ones_count;
reg insert_stuff;

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        ones_count <= 3'b0;
        insert_stuff <= 1'b0;
        o_data <= 1'b0;
        o_valid <= 1'b0;
    end else if (i_packet_start) begin
        ones_count <= 3'b0;
        insert_stuff <= 1'b0;
    end else if (insert_stuff) begin
        // Insert stuff bit (0)
        o_data <= 1'b0;
        o_valid <= 1'b1;
        insert_stuff <= 1'b0;
        ones_count <= 3'b0;
    end else if (i_valid) begin
        o_data <= i_data;
        o_valid <= 1'b1;
        
        if (i_data == 1'b1) begin
            ones_count <= ones_count + 1'b1;
            if (ones_count == 3'b101) begin  // 6 consecutive 1s
                insert_stuff <= 1'b1;
            end
        end else begin
            ones_count <= 3'b0;
        end
    end else begin
        o_valid <= 1'b0;
    end
end

endmodule