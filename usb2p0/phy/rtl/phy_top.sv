module phy_top (
    // System interfaces
    input  wire       i_clk_48m,       // 48MHz reference clock
    input  wire       i_clk_480m,      // 480MHz clock from PLL
    input  wire       i_rst_n,
    input  wire       i_pll_locked,
    
    // USB differential signals
    input  wire       i_dp,
    input  wire       i_dn,
    output wire       o_dp,
    output wire       o_dn,
    output wire       o_oe,
    output wire       o_pullup_en,      // 1.5k pullup control
    
    // Control
    input  wire       i_connect,
    input  wire       i_hs_capable,
    
    // UTMI Interface - Complete Standard Compliant
    input  wire [7:0] i_utmi_txdata,
    input  wire       i_utmi_txvalid,
    output wire       o_utmi_txready,
    
    output wire [7:0] o_utmi_rxdata,
    output wire       o_utmi_rxvalid,
    output wire       o_utmi_rxerror,
    output wire       o_utmi_rxactive,
    
    // UTMI Control
    input  wire [1:0] i_xcvrselect,     // 00=HS, 01=FS, 10=LS, 11=FS4LS
    input  wire [1:0] i_opmode,         // 00=Normal, 01=Non-driving, 10=Disable bit stuff
    input  wire       i_termselect,     // 0=FS/LS termination, 1=HS termination  
    input  wire       i_suspendm,       // 0=Normal, 1=Suspend mode
    
    // UTMI Status
    output wire [1:0] o_linestate,      // 00=SE0, 01=J, 10=K, 11=SE1
    output wire       o_hostdisconnect, // Host disconnect detected
    output wire       o_iddig,          // 0=A-device(host), 1=B-device(device)
    output wire       o_sessend,        // Session end
    output wire       o_sessvld,        // Session valid
    output wire       o_vbusvalid,      // VBUS valid
    
    // Status
    output wire       o_hs_mode,
    output wire       o_fs_mode,
    output wire       o_chirp_done,
    output wire [3:0] o_phy_state,
    output wire [2:0] o_clk_state
);

// Internal signals
wire usb_clk;
wire clk_valid;
wire [1:0] line_state;
wire se0, j_state, k_state, squelch;
wire chirp_dp, chirp_dn, chirp_oe, chirp_pullup;
wire tx_dp, tx_dn, tx_oe;
wire hs_mode, fs_mode;
wire [7:0] rx_data, tx_data;
wire rx_valid, tx_valid;
wire rx_error, tx_ready;
wire rx_active, rx_packet_end;

// Line state detector
usb2_line_state_detector u_line_detect (
    .i_clk(i_clk_48m),
    .i_rst_n(i_rst_n),
    .i_dp(i_dp),
    .i_dn(i_dn),
    .i_hs_mode(hs_mode),
    .o_line_state(line_state),
    .o_se0(se0),
    .o_j_state(j_state),
    .o_k_state(k_state),
    .o_squelch(squelch)
);

// Chirp protocol handler
usb2_chirp_handler u_chirp (
    .i_clk(i_clk_48m),
    .i_rst_n(i_rst_n),
    .i_se0(se0),
    .i_j_state(j_state),
    .i_k_state(k_state),
    .i_connect(i_connect),
    .i_hs_capable(i_hs_capable),
    .o_dp_drive(chirp_dp),
    .o_dn_drive(chirp_dn),
    .o_dp_oe(chirp_oe),
    .o_dn_oe(),
    .o_pullup_en(chirp_pullup),
    .o_hs_mode(hs_mode),
    .o_fs_mode(fs_mode),
    .o_chirp_done(o_chirp_done),
    .o_state(o_phy_state)
);

// Clock multiplexer
usb2_clock_mux u_clock_mux (
    .i_clk_base(i_clk_48m),
    .i_rst_n(i_rst_n),
    .i_clk_480m(i_clk_480m),
    .i_hs_mode(hs_mode),
    .i_pll_locked(i_pll_locked),
    .o_usb_clk(usb_clk),
    .o_clk_valid(clk_valid),
    .o_state(o_clk_state)
);

// RX Path
usb2_rx_path u_rx_path (
    .i_clk_ref(usb_clk),
    .i_rst_n(i_rst_n & clk_valid),
    .i_dp(i_dp),
    .i_dn(i_dn),
    .i_hs_mode(hs_mode),
    .i_squelch(squelch),
    .o_data(rx_data),
    .o_valid(rx_valid),
    .o_error(rx_error),
    .o_packet_end(rx_packet_end)
);

// TX Path
usb2_tx_path u_tx_path (
    .i_clk(usb_clk),
    .i_rst_n(i_rst_n & clk_valid),
    .i_data(tx_data),
    .i_valid(tx_valid),
    .i_packet_start(tx_valid),      // Simplified - start when data valid
    .i_packet_end(~tx_valid),       // End when no more data
    .o_dp(tx_dp),
    .o_dn(tx_dn),
    .o_oe(tx_oe),
    .o_ready(tx_ready)
);

// Elastic Buffers for CDC
wire [7:0] rx_buf_data, tx_buf_data;
wire rx_buf_valid, tx_buf_valid;
wire rx_buf_ready, tx_buf_ready;
wire rx_buf_empty, tx_buf_full;

usb2_elastic_buffer #(.DATA_WIDTH(8), .ADDR_WIDTH(4)) u_rx_buffer (
    .i_wr_clk(usb_clk),
    .i_wr_rst_n(i_rst_n & clk_valid),
    .i_wr_data(rx_data),
    .i_wr_en(rx_valid),
    .i_rd_clk(i_clk_48m),
    .i_rd_rst_n(i_rst_n),
    .i_rd_en(rx_buf_ready),
    .o_rd_data(rx_buf_data),
    .o_rd_valid(rx_buf_valid),
    .o_empty(rx_buf_empty),
    .o_full(),
    .o_overflow(),
    .o_underflow()
);

usb2_elastic_buffer #(.DATA_WIDTH(8), .ADDR_WIDTH(4)) u_tx_buffer (
    .i_wr_clk(i_clk_48m),
    .i_wr_rst_n(i_rst_n),
    .i_wr_data(tx_buf_data),
    .i_wr_en(tx_buf_valid),
    .i_rd_clk(usb_clk),
    .i_rd_rst_n(i_rst_n & clk_valid),
    .i_rd_en(tx_ready),
    .o_rd_data(tx_data),
    .o_rd_valid(tx_valid),
    .o_empty(),
    .o_full(tx_buf_full),
    .o_overflow(),
    .o_underflow()
);

// Generate RX active signal
assign rx_active = rx_valid | (~rx_buf_empty);

// UTMI Interface - Complete Implementation
usb2_utmi_interface u_utmi (
    .i_clk(i_clk_48m),
    .i_rst_n(i_rst_n),
    
    // From/To elastic buffers (PHY side)
    .i_rx_data(rx_buf_data),
    .i_rx_valid(rx_buf_valid),
    .i_rx_error(rx_error),
    .i_rx_active(rx_active),
    .o_tx_data(tx_buf_data),
    .o_tx_valid(tx_buf_valid),
    .i_tx_ready(~tx_buf_full),
    
    // UTMI Interface (Controller side)
    .o_utmi_rxdata(o_utmi_rxdata),
    .o_utmi_rxvalid(o_utmi_rxvalid),
    .o_utmi_rxerror(o_utmi_rxerror),
    .o_utmi_rxactive(o_utmi_rxactive),
    .i_utmi_txdata(i_utmi_txdata),
    .i_utmi_txvalid(i_utmi_txvalid),
    .o_utmi_txready(o_utmi_txready),
    
    // UTMI Control inputs
    .i_xcvrselect(i_xcvrselect),
    .i_opmode(i_opmode),
    .i_termselect(i_termselect),
    .i_suspendm(i_suspendm),
    
    // UTMI Status outputs
    .o_linestate(o_linestate),
    .o_hostdisconnect(o_hostdisconnect),
    .o_iddig(o_iddig),
    .o_sessend(o_sessend),
    .o_sessvld(o_sessvld),
    .o_vbusvalid(o_vbusvalid),
    
    // Internal PHY status inputs
    .i_phy_linestate(line_state),
    .i_phy_hs_mode(hs_mode),
    .i_phy_fs_mode(fs_mode),
    .i_connect_state(i_connect),
    .i_suspend_req(i_suspendm)
);

// Output assignments with proper priority
assign o_dp = chirp_oe ? chirp_dp : (tx_oe ? tx_dp : 1'b0);
assign o_dn = chirp_oe ? chirp_dn : (tx_oe ? tx_dn : 1'b0);
assign o_oe = chirp_oe | tx_oe;
assign o_pullup_en = chirp_pullup;

// Status outputs
assign o_hs_mode = hs_mode;
assign o_fs_mode = fs_mode;

// Buffer control signals
assign rx_buf_ready = ~rx_buf_empty;  // Read when data available

endmodule