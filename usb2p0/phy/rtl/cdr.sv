module cdr (
    input  wire       i_clk_ref,       // Reference clock
    input  wire       i_rst_n,
    input  wire       i_data,          // Incoming serial data
    input  wire       i_hs_mode,
    
    output reg        o_recovered_clk,
    output reg        o_data_valid,
    output reg        o_lock_detect
);

parameter PLL_DIV_FS = 8'h04;  // For 12MHz
parameter PLL_DIV_HS = 8'h01;  // For 480MHz

reg [7:0] phase_count;
reg [7:0] div_ratio;
reg data_prev;
reg edge_detect;
reg [3:0] lock_count;

always @(*) begin
    div_ratio = i_hs_mode ? PLL_DIV_HS : PLL_DIV_FS;
end

// Edge detection
always @(posedge i_clk_ref or negedge i_rst_n) begin
    if (!i_rst_n) begin
        data_prev <= 1'b0;
        edge_detect <= 1'b0;
    end else begin
        data_prev <= i_data;
        edge_detect <= i_data ^ data_prev;
    end
end

// Phase tracking
always @(posedge i_clk_ref or negedge i_rst_n) begin
    if (!i_rst_n) begin
        phase_count <= 8'b0;
        o_recovered_clk <= 1'b0;
    end else begin
        if (edge_detect) begin
            phase_count <= 8'h00;  // Reset phase on edge
        end else begin
            phase_count <= phase_count + 1'b1;
        end
        
        // Generate recovered clock
        if (phase_count == (div_ratio >> 1)) begin
            o_recovered_clk <= ~o_recovered_clk;
        end
    end
end

// Lock detection
always @(posedge i_clk_ref or negedge i_rst_n) begin
    if (!i_rst_n) begin
        lock_count <= 4'b0;
        o_lock_detect <= 1'b0;
        o_data_valid <= 1'b0;
    end else if (edge_detect) begin
        if (lock_count < 4'hF) begin
            lock_count <= lock_count + 1'b1;
        end
        o_lock_detect <= (lock_count > 4'h8);
        o_data_valid <= o_lock_detect;
    end
end

endmodule