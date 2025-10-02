module elastic_buffer #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
) (
    // Write side (USB clock domain)
    input  wire                    i_wr_clk,
    input  wire                    i_wr_rst_n,
    input  wire [DATA_WIDTH-1:0]   i_wr_data,
    input  wire                    i_wr_en,
    
    // Read side (UTMI clock domain)  
    input  wire                    i_rd_clk,
    input  wire                    i_rd_rst_n,
    input  wire                    i_rd_en,
    
    output reg  [DATA_WIDTH-1:0]   o_rd_data,
    output reg                     o_rd_valid,
    output reg                     o_empty,
    output reg                     o_full,
    output reg                     o_overflow,
    output reg                     o_underflow
);

localparam DEPTH = (1 << ADDR_WIDTH);

reg [DATA_WIDTH-1:0] memory [0:DEPTH-1];
reg [ADDR_WIDTH:0] wr_count, rd_count;

// Write pointer synchronization to read domain
always @(posedge i_rd_clk or negedge i_rd_rst_n) begin
    if (!i_rd_rst_n) begin
        wr_ptr_sync1 <= {(ADDR_WIDTH+1){1'b0}};
        wr_ptr_sync2 <= {(ADDR_WIDTH+1){1'b0}};
    end else begin
        wr_ptr_sync1 <= wr_ptr;
        wr_ptr_sync2 <= wr_ptr_sync1;
    end
end

// Read pointer synchronization to write domain  
always @(posedge i_wr_clk or negedge i_wr_rst_n) begin
    if (!i_wr_rst_n) begin
        rd_ptr_sync1 <= {(ADDR_WIDTH+1){1'b0}};
        rd_ptr_sync2 <= {(ADDR_WIDTH+1){1'b0}};
    end else begin
        rd_ptr_sync1 <= rd_ptr;
        rd_ptr_sync2 <= rd_ptr_sync1;
    end
end

// Write logic
always @(posedge i_wr_clk or negedge i_wr_rst_n) begin
    if (!i_wr_rst_n) begin
        wr_ptr <= {(ADDR_WIDTH+1){1'b0}};
        o_overflow <= 1'b0;
    end else if (i_wr_en && !o_full) begin
        memory[wr_ptr[ADDR_WIDTH-1:0]] <= i_wr_data;
        wr_ptr <= wr_ptr + 1'b1;
        o_overflow <= 1'b0;
    end else if (i_wr_en && o_full) begin
        o_overflow <= 1'b1;
    end
end

// Read logic
always @(posedge i_rd_clk or negedge i_rd_rst_n) begin
    if (!i_rd_rst_n) begin
        rd_ptr <= {(ADDR_WIDTH+1){1'b0}};
        o_rd_data <= {DATA_WIDTH{1'b0}};
        o_rd_valid <= 1'b0;
        o_underflow <= 1'b0;
    end else if (i_rd_en && !o_empty) begin
        o_rd_data <= memory[rd_ptr[ADDR_WIDTH-1:0]];
        rd_ptr <= rd_ptr + 1'b1;
        o_rd_valid <= 1'b1;
        o_underflow <= 1'b0;
    end else if (i_rd_en && o_empty) begin
        o_underflow <= 1'b1;
        o_rd_valid <= 1'b0;
    end else begin
        o_rd_valid <= 1'b0;
    end
end

// Status flags
always @(*) begin
    wr_count = wr_ptr - rd_ptr_sync2;
    rd_count = wr_ptr_sync2 - rd_ptr;
end

always @(posedge i_wr_clk or negedge i_wr_rst_n) begin
    if (!i_wr_rst_n) begin
        o_full <= 1'b0;
    end else begin
        o_full <= (wr_count == DEPTH);
    end
end

always @(posedge i_rd_clk or negedge i_rd_rst_n) begin
    if (!i_rd_rst_n) begin
        o_empty <= 1'b1;
    end else begin
        o_empty <= (rd_count == 0);
    end
end

endmodule