module line_driver (
    input  wire i_clk,
    input  wire i_rst_n,
    input  wire i_nrzi_data,
    input  wire i_nrzi_valid,
    input  wire i_packet_start,
    input  wire i_packet_end,
    input  wire i_serial_done,
    input  wire i_hs_mode,
    
    output reg  o_dp,
    output reg  o_dn,
    output reg  o_oe,
    output wire o_ready
);

reg tx_active;

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_dp <= 1'b0;
        o_dn <= 1'b0;
        o_oe <= 1'b0;
        tx_active <= 1'b0;
    end
    else if (i_packet_start) begin
        tx_active <= 1'b1;
        o_oe <= 1'b1;
    end
    else if (i_packet_end || i_serial_done) begin
        tx_active <= 1'b0;
        o_oe <= 1'b0;
    end
    else if (i_nrzi_valid && tx_active) begin
        if (i_hs_mode) begin
            if (i_nrzi_data) begin
                o_dp <= 1'b1;
                o_dn <= 1'b0;
            end else begin
                o_dp <= 1'b0;
                o_dn <= 1'b1;
            end
        end
        else begin
            if (i_nrzi_data) begin
                o_dp <= 1'b0;
                o_dn <= 1'b1;
            end else begin
                o_dp <= 1'b1;
                o_dn <= 1'b0;
            end
        end
    end
end

assign o_ready = ~tx_active;

endmodule