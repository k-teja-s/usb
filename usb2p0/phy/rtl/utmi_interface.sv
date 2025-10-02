module utmi_interface (
    input  wire       i_clk,
    input  wire       i_rst_n,
    
    // From/To elastic buffers (PHY side)
    input  wire [7:0] i_rx_data,
    input  wire       i_rx_valid,
    input  wire       i_rx_error,
    input  wire       i_rx_active,
    
    output reg  [7:0] o_tx_data,
    output reg        o_tx_valid,
    input  wire       i_tx_ready,
    
    // UTMI Interface (Controller side)
    output reg  [7:0] o_utmi_rxdata,
    output reg        o_utmi_rxvalid,
    output reg        o_utmi_rxerror,
    output reg        o_utmi_rxactive,
    
    input  wire [7:0] i_utmi_txdata,
    input  wire       i_utmi_txvalid,
    output reg        o_utmi_txready,
    
    // UTMI Control inputs
    input  wire [1:0] i_xcvrselect,    // 00=HS, 01=FS, 10=LS, 11=FS4LS
    input  wire [1:0] i_opmode,        // 00=Normal, 01=Non-driving, 10=Disable bit stuff, 11=Reserved
    input  wire       i_termselect,    // 0=FS/LS termination, 1=HS termination
    input  wire       i_suspendm,      // 0=Normal, 1=Suspend mode
    
    // UTMI Status outputs
    output reg  [1:0] o_linestate,     // 00=SE0, 01=J, 10=K, 11=SE1
    output reg        o_hostdisconnect, // Host disconnect detected
    output reg        o_iddig,          // 0=A-device(host), 1=B-device(device)
    output reg        o_sessend,        // Session end
    output reg        o_sessvld,        // Session valid
    output reg        o_vbusvalid,      // VBUS valid
    
    // Internal PHY status inputs
    input  wire [1:0] i_phy_linestate,
    input  wire       i_phy_hs_mode,
    input  wire       i_phy_fs_mode,
    input  wire       i_connect_state,
    input  wire       i_suspend_req
);

// UTMI Operation Mode definitions
localparam [1:0] 
    OPMODE_NORMAL       = 2'b00,
    OPMODE_NON_DRIVING  = 2'b01,
    OPMODE_DISABLE_BITSTUFF = 2'b10,
    OPMODE_RESERVED     = 2'b11;

// UTMI Transceiver Select definitions  
localparam [1:0]
    XCVR_HS             = 2'b00,
    XCVR_FS             = 2'b01,
    XCVR_LS             = 2'b10,
    XCVR_FS4LS          = 2'b11;

// Internal registers
reg [7:0] rx_data_reg;
reg rx_valid_reg;
reg rx_error_reg;
reg rx_active_reg;
reg tx_ready_reg;

// UTMI FSM states
typedef enum logic [2:0] {
    UTMI_IDLE           = 3'h0,
    UTMI_RX_ACTIVE      = 3'h1,
    UTMI_TX_ACTIVE      = 3'h2,
    UTMI_SUSPEND        = 3'h3,
    UTMI_ERROR          = 3'h4
} utmi_state_t;

utmi_state_t current_state, next_state;

// State machine sequential logic
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        current_state <= UTMI_IDLE;
    end else begin
        current_state <= next_state;
    end
end

// State machine combinational logic
always @(*) begin
    next_state = current_state;
    
    case (current_state)
        UTMI_IDLE: begin
            if (i_suspendm) begin
                next_state = UTMI_SUSPEND;
            end else if (i_rx_active && i_rx_valid) begin
                next_state = UTMI_RX_ACTIVE;
            end else if (i_utmi_txvalid && i_tx_ready) begin
                next_state = UTMI_TX_ACTIVE;
            end else if (i_rx_error) begin
                next_state = UTMI_ERROR;
            end
        end
        
        UTMI_RX_ACTIVE: begin
            if (i_rx_error) begin
                next_state = UTMI_ERROR;
            end else if (!i_rx_active) begin
                next_state = UTMI_IDLE;
            end else if (i_suspendm) begin
                next_state = UTMI_SUSPEND;
            end
        end
        
        UTMI_TX_ACTIVE: begin
            if (!i_utmi_txvalid || !i_tx_ready) begin
                next_state = UTMI_IDLE;
            end else if (i_suspendm) begin
                next_state = UTMI_SUSPEND;
            end
        end
        
        UTMI_SUSPEND: begin
            if (!i_suspendm) begin
                next_state = UTMI_IDLE;
            end
        end
        
        UTMI_ERROR: begin
            if (!i_rx_error && !i_rx_active) begin
                next_state = UTMI_IDLE;
            end
        end
        
        default: begin
            next_state = UTMI_IDLE;
        end
    endcase
end

// RX Data Path: PHY to UTMI (Receive)
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_utmi_rxdata <= 8'h00;
        o_utmi_rxvalid <= 1'b0;
        o_utmi_rxerror <= 1'b0;
        o_utmi_rxactive <= 1'b0;
        rx_data_reg <= 8'h00;
        rx_valid_reg <= 1'b0;
        rx_error_reg <= 1'b0;
        rx_active_reg <= 1'b0;
    end else begin
        // Register PHY inputs
        rx_data_reg <= i_rx_data;
        rx_valid_reg <= i_rx_valid;
        rx_error_reg <= i_rx_error;
        rx_active_reg <= i_rx_active;
        
        // Generate UTMI RX outputs
        case (current_state)
            UTMI_RX_ACTIVE: begin
                if (i_opmode == OPMODE_NORMAL || i_opmode == OPMODE_DISABLE_BITSTUFF) begin
                    o_utmi_rxdata <= rx_data_reg;
                    o_utmi_rxvalid <= rx_valid_reg;
                    o_utmi_rxactive <= rx_active_reg;
                    o_utmi_rxerror <= rx_error_reg;
                end else begin
                    // Non-driving mode - no valid data
                    o_utmi_rxvalid <= 1'b0;
                    o_utmi_rxactive <= 1'b0;
                    o_utmi_rxerror <= 1'b0;
                end
            end
            
            UTMI_ERROR: begin
                o_utmi_rxerror <= 1'b1;
                o_utmi_rxvalid <= 1'b0;
                o_utmi_rxactive <= 1'b0;
            end
            
            default: begin
                o_utmi_rxvalid <= 1'b0;
                o_utmi_rxactive <= 1'b0;
                o_utmi_rxerror <= 1'b0;
            end
        endcase
    end
end

// TX Data Path: UTMI to PHY (Transmit)
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_tx_data <= 8'h00;
        o_tx_valid <= 1'b0;
        o_utmi_txready <= 1'b0;
        tx_ready_reg <= 1'b0;
    end else begin
        tx_ready_reg <= i_tx_ready;
        
        case (current_state)
            UTMI_TX_ACTIVE: begin
                if (i_opmode == OPMODE_NORMAL || i_opmode == OPMODE_DISABLE_BITSTUFF) begin
                    if (i_utmi_txvalid && tx_ready_reg) begin
                        o_tx_data <= i_utmi_txdata;
                        o_tx_valid <= 1'b1;
                        o_utmi_txready <= 1'b1;
                    end else begin
                        o_tx_valid <= 1'b0;
                        o_utmi_txready <= tx_ready_reg;
                    end
                end else begin
                    // Non-driving mode
                    o_tx_valid <= 1'b0;
                    o_utmi_txready <= 1'b0;
                end
            end
            
            UTMI_IDLE: begin
                o_tx_valid <= 1'b0;
                o_utmi_txready <= tx_ready_reg && (i_opmode != OPMODE_NON_DRIVING);
            end
            
            default: begin
                o_tx_valid <= 1'b0;
                o_utmi_txready <= 1'b0;
            end
        endcase
    end
end

// UTMI Status Outputs
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_linestate <= 2'b00;          // SE0
        o_hostdisconnect <= 1'b0;
        o_iddig <= 1'b1;               // Device mode (B-device)
        o_sessend <= 1'b0;
        o_sessvld <= 1'b0;
        o_vbusvalid <= 1'b0;
    end else begin
        // Line State mapping from PHY
        o_linestate <= i_phy_linestate;
        
        // Device mode - always B-device
        o_iddig <= 1'b1;
        
        // Host disconnect detection
        // In device mode, detect when host stops driving
        if (i_phy_linestate == 2'b00 && !i_rx_active) begin
            o_hostdisconnect <= 1'b1;
        end else if (i_connect_state) begin
            o_hostdisconnect <= 1'b0;
        end
        
        // Session management (simplified for device mode)
        if (i_connect_state && (i_phy_hs_mode || i_phy_fs_mode)) begin
            o_sessvld <= 1'b1;
            o_vbusvalid <= 1'b1;
            o_sessend <= 1'b0;
        end else begin
            o_sessvld <= 1'b0;
            o_vbusvalid <= 1'b0;
            o_sessend <= 1'b1;
        end
    end
end

// UTMI Control Signal Validation
reg xcvr_select_valid;
reg opmode_valid;

always @(*) begin
    // Validate transceiver select based on PHY mode
    case (i_xcvrselect)
        XCVR_HS: xcvr_select_valid = i_phy_hs_mode;
        XCVR_FS, XCVR_LS, XCVR_FS4LS: xcvr_select_valid = i_phy_fs_mode;
        default: xcvr_select_valid = 1'b0;
    endcase
    
    // Validate operation mode
    case (i_opmode)
        OPMODE_NORMAL, OPMODE_NON_DRIVING, OPMODE_DISABLE_BITSTUFF: opmode_valid = 1'b1;
        OPMODE_RESERVED: opmode_valid = 1'b0;
        default: opmode_valid = 1'b0;
    endcase
end

// Debug and monitoring signals (optional - can be removed in synthesis)
`ifdef USB2_DEBUG
reg [31:0] debug_rx_packet_count;
reg [31:0] debug_tx_packet_count;
reg [31:0] debug_error_count;

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        debug_rx_packet_count <= 32'h0;
        debug_tx_packet_count <= 32'h0;
        debug_error_count <= 32'h0;
    end else begin
        if (o_utmi_rxvalid && !rx_valid_reg) begin
            debug_rx_packet_count <= debug_rx_packet_count + 1'b1;
        end
        if (o_tx_valid && !o_tx_valid) begin
            debug_tx_packet_count <= debug_tx_packet_count + 1'b1;
        end
        if (o_utmi_rxerror) begin
            debug_error_count <= debug_error_count + 1'b1;
        end
    end
end
`endif

endmodule