module chirp_handler (
    input  wire       i_clk,
    input  wire       i_rst_n,
    input  wire       i_se0,
    input  wire       i_j_state,
    input  wire       i_k_state,
    input  wire       i_connect,
    input  wire       i_hs_capable,
    
    output reg        o_dp_drive,
    output reg        o_dn_drive,
    output reg        o_dp_oe,
    output reg        o_dn_oe,
    output reg        o_pullup_en,
    output reg        o_hs_mode,
    output reg        o_fs_mode,
    output reg        o_chirp_done,
    output reg [3:0]  o_state
);

// FSM states
typedef enum logic [3:0] {
    CHIRP_IDLE          = 4'h0,
    CHIRP_FS_CONNECT    = 4'h1,
    CHIRP_WAIT_RESET    = 4'h2,
    CHIRP_DETECT_RESET  = 4'h3,
    CHIRP_SEND_K        = 4'h4,
    CHIRP_WAIT_HOST     = 4'h5,
    CHIRP_DETECT_HOST   = 4'h6,
    CHIRP_HS_SUCCESS    = 4'h7,
    CHIRP_FS_FALLBACK   = 4'h8
} chirp_state_t;

chirp_state_t current_state, next_state;

// Timing parameters
localparam [`USB2_TIMER_WIDTH-1:0] RESET_MIN_TIME = 24'd480000;    // 10ms @ 48MHz
localparam [`USB2_TIMER_WIDTH-1:0] CHIRP_K_TIME = 24'd144000;      // 3ms @ 48MHz  
localparam [`USB2_TIMER_WIDTH-1:0] HOST_TIMEOUT = 24'd4800000;     // 100ms @ 48MHz
localparam [`USB2_TIMER_WIDTH-1:0] CHIRP_DETECT = 24'd2400;        // 50us @ 48MHz

reg [`USB2_TIMER_WIDTH-1:0] timer_count;
reg timer_enable, timer_expired;
reg [2:0] host_chirp_count;
reg reset_detected;

// Timer logic
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        timer_count <= 24'b0;
        timer_expired <= 1'b0;
    end else if (timer_enable) begin
        timer_count <= timer_count + 1'b1;
        timer_expired <= (timer_count >= RESET_MIN_TIME) ||
                        (timer_count >= CHIRP_K_TIME) ||
                        (timer_count >= HOST_TIMEOUT) ||
                        (timer_count >= CHIRP_DETECT);
    end else begin
        timer_count <= 24'b0;
        timer_expired <= 1'b0;
    end
end

// State machine
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        current_state <= CHIRP_IDLE;
    end else begin
        current_state <= next_state;
    end
end

always @(*) begin
    next_state = current_state;
    timer_enable = 1'b0;
    
    case (current_state)
        CHIRP_IDLE: begin
            if (i_connect) next_state = CHIRP_FS_CONNECT;
        end
        
        CHIRP_FS_CONNECT: begin
            next_state = CHIRP_WAIT_RESET;
        end
        
        CHIRP_WAIT_RESET: begin
            if (i_se0) next_state = CHIRP_DETECT_RESET;
        end
        
        CHIRP_DETECT_RESET: begin
            timer_enable = 1'b1;
            if (!i_se0 && timer_expired) begin
                next_state = i_hs_capable ? CHIRP_SEND_K : CHIRP_FS_FALLBACK;
            end else if (!i_se0) begin
                next_state = CHIRP_WAIT_RESET;
            end
        end
        
        CHIRP_SEND_K: begin
            timer_enable = 1'b1;
            if (timer_expired) next_state = CHIRP_WAIT_HOST;
        end
        
        CHIRP_WAIT_HOST: begin
            timer_enable = 1'b1;
            if (i_j_state || i_k_state) next_state = CHIRP_DETECT_HOST;
            else if (timer_expired) next_state = CHIRP_FS_FALLBACK;
        end
        
        CHIRP_DETECT_HOST: begin
            timer_enable = 1'b1;
            if (host_chirp_count >= 3'd6) next_state = CHIRP_HS_SUCCESS;
            else if (timer_expired && !i_j_state && !i_k_state) next_state = CHIRP_FS_FALLBACK;
        end
        
        CHIRP_HS_SUCCESS: begin
            // Stay in HS mode
        end
        
        CHIRP_FS_FALLBACK: begin
            // Stay in FS mode
        end
    endcase
end

// Output logic
always @(*) begin
    o_dp_drive = 1'b0;
    o_dn_drive = 1'b0;
    o_dp_oe = 1'b0;
    o_dn_oe = 1'b0;
    o_pullup_en = 1'b0;
    o_hs_mode = 1'b0;
    o_fs_mode = 1'b0;
    o_chirp_done = 1'b0;
    o_state = current_state;
    
    case (current_state)
        CHIRP_FS_CONNECT, CHIRP_WAIT_RESET, CHIRP_DETECT_RESET: begin
            o_pullup_en = 1'b1;
            o_fs_mode = 1'b1;
        end
        
        CHIRP_SEND_K: begin
            o_dp_drive = 1'b0;
            o_dn_drive = 1'b1;
            o_dp_oe = 1'b1;
            o_dn_oe = 1'b1;
            o_fs_mode = 1'b1;
        end
        
        CHIRP_WAIT_HOST, CHIRP_DETECT_HOST: begin
            o_fs_mode = 1'b1;
        end
        
        CHIRP_HS_SUCCESS: begin
            o_hs_mode = 1'b1;
            o_chirp_done = 1'b1;
        end
        
        CHIRP_FS_FALLBACK: begin
            o_pullup_en = 1'b1;
            o_fs_mode = 1'b1;
            o_chirp_done = 1'b1;
        end
    endcase
end

// Host chirp detection
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        host_chirp_count <= 3'b0;
    end else if (current_state == CHIRP_DETECT_HOST) begin
        if ((i_j_state || i_k_state) && timer_expired) begin
            host_chirp_count <= host_chirp_count + 1'b1;
        end
    end else begin
        host_chirp_count <= 3'b0;
    end
end

endmodule