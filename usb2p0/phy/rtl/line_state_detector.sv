module line_state_detector (
    input  wire       i_clk,
    input  wire       i_rst_n,
    input  wire       i_dp,
    input  wire       i_dn,
    input  wire       i_hs_mode,
    
    output reg  [1:0] o_line_state,
    output reg        o_se0,
	output reg        o_se1,
    output reg        o_j_state,
    output reg        o_k_state,
	output reg		  o_hs_mode,
    output reg        o_squelch
);

parameter SQUELCH_THRESHOLD = 4'h3;

typedef bit [1:0] enum {LS00_SE0,LS01_HSK_FSK,LS10_HSJ_FSJ,LS11_SE1} line_states;
line_states line_state_sync;

reg [3:0] squelch_counter;
reg dp_sync, dn_sync;

// Input synchronization
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        dp_sync <= 1'b0;
        dn_sync <= 1'b0;
        line_state_sync <= LS00_SE0;
    end else begin
        dp_sync <= i_dp;
        dn_sync <= i_dn;
        line_state_sync <= {dp_sync, dn_sync};
    end
end

// Line state detection
always @(*) begin
    case (line_state_sync)
        2'b00: o_line_state = LS00_SE0;
        2'b01: o_line_state = i_hs_mode ? LS01_HSK_FSK : LS10_HSJ_FSJ;
        2'b10: o_line_state = i_hs_mode ? LS10_HSJ_FSJ : LS01_HSK_FSK;
        2'b11: o_line_state = LS11_SE1;
    endcase
end

// State outputs
always @(*) begin
    o_se0 = (o_line_state == LS00_SE0);
    o_j_state = (o_line_state == LS10_HSJ_FSJ);
    o_k_state = (o_line_state == LS01_HSK_FSK);
	o_hs_mode = i_hs_mode;
	o_se1 = (o_line_state == LS11_SE1);
end

// Squelch detection for HS mode
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        squelch_counter <= 4'b0;
        o_squelch <= 1'b0;
    end
	else if (i_hs_mode) begin
        if (o_se0) begin
            if (squelch_counter < SQUELCH_THRESHOLD) begin
                squelch_counter <= squelch_counter + 1'b1;
            end
			else begin
                o_squelch <= 1'b1;
            end
        end 
		else begin
            squelch_counter <= 4'b0;
            o_squelch <= 1'b0;
        end
    end
	else begin
        o_squelch <= 1'b0;
    end
end

endmodule