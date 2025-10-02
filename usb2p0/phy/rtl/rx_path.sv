module rx_path (
    input  wire       i_clk_ref,
    input  wire       i_rst_n,
    input  wire       i_dp,
    input  wire       i_dn,
    input  wire       i_hs_mode,
    input  wire       i_squelch,
    
    output wire [7:0] o_data,
    output wire       o_valid,
    output wire       o_error,
    output wire       o_packet_end
);

// Internal signals
wire recovered_clk;
wire cdr_valid;
wire cdr_lock;
wire nrzi_data;
wire nrzi_valid;
wire destuff_data;
wire destuff_valid;
wire destuff_error;
wire sync_detected;

// Clock and Data Recovery
usb2_cdr u_cdr (
    .i_clk_ref(i_clk_ref),
    .i_rst_n(i_rst_n),
    .i_data(i_hs_mode ? (i_dp & ~i_squelch) : i_dp),
    .i_hs_mode(i_hs_mode),
    .o_recovered_clk(recovered_clk),
    .o_data_valid(cdr_valid),
    .o_lock_detect(cdr_lock)
);

// NRZI Decoder
usb2_nrzi_decoder u_nrzi_dec (
    .i_clk(recovered_clk),
    .i_rst_n(i_rst_n),
    .i_data(i_hs_mode ? (i_dp & ~i_squelch) : i_dp),
    .i_valid(cdr_valid & cdr_lock),
    .o_data(nrzi_data),
    .o_valid(nrzi_valid)
);

// Bit Destuffer
usb2_bit_destuffer u_destuffer (
    .i_clk(recovered_clk),
    .i_rst_n(i_rst_n),
    .i_data(nrzi_data),
    .i_valid(nrzi_valid),
    .i_packet_start(sync_detected),
    .o_data(destuff_data),
    .o_valid(destuff_valid),
    .o_error(destuff_error)
);

// Serial to Parallel
usb2_serial_to_parallel #(.PARALLEL_WIDTH(8)) u_s2p (
    .i_clk(recovered_clk),
    .i_rst_n(i_rst_n),
    .i_data(destuff_data),
    .i_valid(destuff_valid),
    .i_sync_pattern(sync_detected),
    .o_data(o_data),
    .o_valid(o_valid),
    .o_error(o_error)
);

// SYNC pattern detection (simplified)
reg [7:0] sync_shift_reg;
always @(posedge recovered_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        sync_shift_reg <= 8'h00;
    end else if (nrzi_valid) begin
        sync_shift_reg <= {sync_shift_reg[6:0], nrzi_data};
    end
end

assign sync_detected = (sync_shift_reg == 8'h80);  // KJKJKJKK pattern
assign o_packet_end = i_squelch | destuff_error;

endmodule