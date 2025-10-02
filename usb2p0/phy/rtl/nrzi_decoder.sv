module nrzi_decoder (
    input  wire       i_clk,
    input  wire       i_rst_n,
    input  wire       i_data,          // NRZI encoded data
    input  wire       i_valid,
    
    output reg        o_data,          // NRZ decoded data  
    output reg        o_valid
);

reg data_prev;

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        data_prev <= 1'b0;
        o_data <= 1'b0;
        o_valid <= 1'b0;
    end else if (i_valid) begin
        o_data <= ~(i_data ^ data_prev);  // NRZI decode: no transition = 1, transition = 0
        data_prev <= i_data;
        o_valid <= 1'b1;
    end else begin
        o_valid <= 1'b0;
    end
end

endmodule