module clock_mux (
    input  wire       i_clk_base,      // Base clock (48MHz)
    input  wire       i_rst_n,
    input  wire       i_clk_480m,      // 480MHz clock
    input  wire       i_hs_mode,
    input  wire       i_pll_locked,
    
    output wire       o_usb_clk,
    output reg        o_clk_valid,
    output reg [2:0]  o_state
);

typedef enum logic [2:0] {
    CLK_INIT     = 3'h0,
    CLK_FS_MODE  = 3'h1,
    CLK_SWITCH   = 3'h2,
    CLK_HS_MODE  = 3'h3,
    CLK_ERROR    = 3'h4
} clk_state_t;

clk_state_t current_state, next_state;

reg clk_12m;
reg [1:0] fs_div_count;
reg clk_select;
reg clk_enable_fs, clk_enable_hs;
reg clk_select_sync_fs, clk_select_sync_hs;
reg [7:0] switch_delay;

// Generate 12MHz clock from 48MHz base
always @(posedge i_clk_base or negedge i_rst_n) begin
    if (!i_rst_n) begin
        fs_div_count <= 2'b0;
        clk_12m <= 1'b0;
    end else begin
        fs_div_count <= fs_div_count + 1'b1;
        if (fs_div_count == 2'b01) begin
            clk_12m <= ~clk_12m;
        end
    end
end

// Synchronize clock select to both domains
always @(posedge clk_12m or negedge i_rst_n) begin
    if (!i_rst_n) begin
        clk_select_sync_fs <= 1'b0;
        clk_enable_fs <= 1'b1;
    end else begin
        clk_select_sync_fs <= clk_select;
        clk_enable_fs <= ~clk_select_sync_fs;
    end
end

always @(posedge i_clk_480m or negedge i_rst_n) begin
    if (!i_rst_n) begin
        clk_select_sync_hs <= 1'b0;
        clk_enable_hs <= 1'b0;
    end else begin
        clk_select_sync_hs <= clk_select;
        clk_enable_hs <= clk_select_sync_hs;
    end
end

// State machine
always @(posedge i_clk_base or negedge i_rst_n) begin
    if (!i_rst_n) begin
        current_state <= CLK_INIT;
        switch_delay <= 8'b0;
    end else begin
        current_state <= next_state;
        if (current_state == CLK_SWITCH) begin
            switch_delay <= switch_delay + 1'b1;
        end else begin
            switch_delay <= 8'b0;
        end
    end
end

always @(*) begin
    next_state = current_state;
    clk_select = 1'b0;
    o_clk_valid = 1'b0;
    o_state = current_state;
    
    case (current_state)
        CLK_INIT: begin
            if (i_pll_locked) next_state = CLK_FS_MODE;
            else next_state = CLK_ERROR;
        end
        
        CLK_FS_MODE: begin
            clk_select = 1'b0;
            o_clk_valid = i_pll_locked;
            if (i_hs_mode && i_pll_locked) next_state = CLK_SWITCH;
            else if (!i_pll_locked) next_state = CLK_ERROR;
        end
        
        CLK_SWITCH: begin
            clk_select = switch_delay[7];
            if (&switch_delay) begin
                next_state = i_hs_mode ? CLK_HS_MODE : CLK_FS_MODE;
            end
        end
        
        CLK_HS_MODE: begin
            clk_select = 1'b1;
            o_clk_valid = i_pll_locked;
            if (!i_hs_mode) next_state = CLK_SWITCH;
            else if (!i_pll_locked) next_state = CLK_ERROR;
        end
        
        CLK_ERROR: begin
            clk_select = 1'b0;
            if (i_pll_locked) next_state = CLK_INIT;
        end
    endcase
end

// Glitch-free clock multiplexer
wire clk_fs_gated = clk_12m & clk_enable_fs;
wire clk_hs_gated = i_clk_480m & clk_enable_hs;

assign o_usb_clk = clk_select ? clk_hs_gated : clk_fs_gated;

endmodule