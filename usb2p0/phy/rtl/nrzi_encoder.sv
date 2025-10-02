module nrzi_encoder (
    input  wire       i_clk,
    input  wire       i_rst_n,
    input  wire       i_data,          // NRZ data
    input  wire       i_valid,
    
    output reg        o_data,          // NRZI encoded data
    output reg        o_valid
);

reg prev_output;

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        prev_output <= 1'b0;
        o_data <= 1'b0;
        o_valid <= 1'b0;
    end else if (i_valid) begin
        if (i_data == 1'b1) begin
            o_data <= prev_output;      // No transition for '1'
        end else begin
            o_data <= ~prev_output;     // Transition for '0'  
        end
        prev_output <= o_data;
        o_valid <= 1'b1;
    end else begin
        o_valid <= 1'b0;
    end
end

endmodule