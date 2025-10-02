module bit_destuffer (
    input  wire       i_clk,
    input  wire       i_rst_n,
    input  wire       i_data,
    input  wire       i_valid,
    input  wire       i_packet_start,
    
    output reg        o_data,
    output reg        o_valid,
    output reg        o_error
);

reg [2:0] ones_count;
reg stuff_next;

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        ones_count <= 3'b0;
        stuff_next <= 1'b0;
        o_data <= 1'b0;
        o_valid <= 1'b0;
        o_error <= 1'b0;
    end else if (i_packet_start) begin
        ones_count <= 3'b0;
        stuff_next <= 1'b0;
        o_error <= 1'b0;
    end else if (i_valid) begin
        if (stuff_next) begin
            // This should be a stuffed bit (should be 0)
            if (i_data == 1'b1) begin
                o_error <= 1'b1;  // Bit stuffing violation
            end
            stuff_next <= 1'b0;
            o_valid <= 1'b0;    // Don't output stuffed bit
            ones_count <= 3'b0;
        end else begin
            o_data <= i_data;
            o_valid <= 1'b1;
            
            if (i_data == 1'b1) begin
                ones_count <= ones_count + 1'b1;
                if (ones_count == 3'b101) begin  // 6 consecutive 1s
                    stuff_next <= 1'b1;
                end
            end else begin
                ones_count <= 3'b0;
            end
        end
    end else begin
        o_valid <= 1'b0;
    end
end

endmodule