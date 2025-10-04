module tx_path (
    input  wire       i_clk,
    input  wire       i_rst_n,
    input  wire [7:0] i_data,
    input  wire       i_valid,
    input  wire       i_packet_start,
    input  wire       i_packet_end,
    
    output wire       o_dp,
    output wire       o_dn,
    output wire       o_oe,
    output wire       o_ready
);

// Internal signals
wire serial_data;
wire serial_valid;
wire serial_done;
wire stuff_data;
wire stuff_valid;
wire nrzi_data;
wire nrzi_valid;

// Parallel to Serial
usb2_parallel_to_serial #(.PARALLEL_WIDTH(8)) u_p2s (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_data(i_data),
    .i_valid(i_valid),
    .i_load(i_packet_start),
    .o_data(serial_data),
    .o_valid(serial_valid),
    .o_done(serial_done)
);

// Bit Stuffer
usb2_bit_stuffer u_stuffer (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_data(serial_data),
    .i_valid(serial_valid),
    .i_packet_start(i_packet_start),
    .o_data(stuff_data),
    .o_valid(stuff_valid)
);

// NRZI Encoder
usb2_nrzi_encoder u_nrzi_enc (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_data(stuff_data),
    .i_valid(stuff_valid),
    .o_data(nrzi_data),
    .o_valid(nrzi_valid)
);

// line driver
line_driver u_line_driver (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_nrzi_data(nrzi_data),
    .i_nrzi_valid(nrzi_valid),
    .i_packet_start(i_packet_start),
    .i_packet_end(i_packet_end),
    .i_serial_done(serial_done),
    .i_hs_mode(i_hs_mode),
    .o_dp(o_dp),
    .o_dn(o_dn),
    .o_oe(o_oe),
    .o_ready(o_ready)
);

endmodule