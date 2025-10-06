`timescale 1ns/1ps

module line_state_detector_tb ();

  // Testbench signals
  reg        i_clk;
  reg        i_rst_n;
  reg        i_dp;
  reg        i_dn;
  reg        i_hs_mode;

  wire [1:0] o_line_state;
  wire       o_se0;
  wire       o_se1;
  wire       o_j_state;
  wire       o_k_state;
  wire       o_hs_mode;
  wire       o_squelch;

  // DUT instantiation
  line_state_detector dut (
    .i_clk      (i_clk),
    .i_rst_n    (i_rst_n),
    .i_dp       (i_dp),
    .i_dn       (i_dn),
    .i_hs_mode  (i_hs_mode),
    .o_line_state(o_line_state),
    .o_se0      (o_se0),
    .o_se1      (o_se1),
    .o_j_state  (o_j_state),
    .o_k_state  (o_k_state),
    .o_hs_mode  (o_hs_mode),
    .o_squelch  (o_squelch)
  );

  // Clock generation
  initial begin
    i_clk = 0;
    forever #5 i_clk = ~i_clk;  
  end


task reset_task;
begin
end
endtask
  // Stimulus
  initial begin
    // Initialize inputs
	@(negedge i_clk) 
    i_rst_n   = 0;
    i_dp      = 0;
    i_dn      = 0;
    i_hs_mode = 0;

    // Apply reset
	@(negedge i_clk) i_rst_n=1'b1;

    // Sequence of line states
  	 {i_dp, i_dn} = 2'b00; // SE0
	@(negedge i_clk) {i_dp, i_dn} = 2'b01; //  FS K
	@(negedge i_clk) {i_dp, i_dn} = 2'b10; //  FS J
     @(negedge i_clk) {i_dp, i_dn} = 2'b11; // SE1


repeat(5)
	@(negedge i_clk);

    // Switch to HS mode
    @(negedge i_clk)i_hs_mode = 1;
 	 {i_dp, i_dn} = 2'b01; // SE1
	@(negedge i_clk) {i_dp, i_dn} = 2'b10; // HS J 
	@(negedge i_clk) {i_dp, i_dn} = 2'b11; // HS K
     @(negedge i_clk) {i_dp, i_dn} = 2'b00; // SE0

repeat(5)
	@(negedge i_clk);

    // Finish
    #100 $finish;
  end

  // Monitor outputs
  initial begin
    $monitor("T=%0t | dp=%b dn=%b hs_mode=%b | o_line_state=%b o_se0=%b o_se1=%b o_j=%b o_k=%b o_hs_mode=%b",
              $time, i_dp, i_dn, i_hs_mode,
              o_line_state, o_se0, o_se1, o_j_state, o_k_state, o_hs_mode);
  end

endmodule

