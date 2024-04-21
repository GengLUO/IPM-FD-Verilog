//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/19 17:43:18
// Design Name: 
// Module Name: trivium_TOP_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module trivium_TOP_tb;

  parameter int WORDSIZE = 24;
  parameter int OUTPUT_BITS = 24;

  // Inputs
  logic clk_i, reset_ni, req_i, refr_i;
  logic [79:0] key_i;

  // Outputs
  logic [WORDSIZE-1:0] prng_o;
  logic busy_o, ready_o;

  // Instantiate the Unit Under Test (UUT)
  trivium_top #(
      .WORDSIZE(WORDSIZE),
      .OUTPUT_BITS(OUTPUT_BITS)
  ) uut (
      .clk_i(clk_i), 
      .reset_ni(reset_ni), 
      .req_i(req_i), 
      .refr_i(refr_i), 
      .key_i(key_i), 
      .prng_o(prng_o), 
      .busy_o(busy_o), 
      .ready_o(ready_o)
  );

  // Clock generation
  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i;  // 100MHz Clock
  end

  // Test sequence
  initial begin
    // Initialize Inputs
    reset_ni = 0;
    req_i = 0;
    refr_i = 0;
    key_i = 80'h00112233445566778899;  // Example key

    // Reset the system
    #100;
    reset_ni = 1;

    // Wait for device to be ready
//    #50;
    wait(ready_o);
    #50;


    for (int i = 0; i < 16; i++)
        request_random();
        
    #50;
    
    for (int i = 0; i < 16; i++)
        request_random();
    

    // Refresh key
    refr_i = 1;
    #10 refr_i = 0;

    // Check outputs post-refresh
    #100;

    $finish;
  end

  // Display output whenever prng_o changes or other significant events occur
//  always @(posedge clk_i) begin
//    if (ready_o) begin
//      $display("Time: %0t, PRNG Output: %0h, Busy: %b, Ready: %b", $time, prng_o, busy_o, ready_o);
//    end
//  end

  // Assertions and checks
  initial begin
    // Check that the module is not initially ready
    assert (ready_o == 0) else $error("Module should not be ready immediately after reset.");

    // Wait for the first ready signal
    @(posedge ready_o);

    // Now the module should be ready to accept requests
    assert (ready_o == 1) else $error("Module should be ready after initialization.");
  end
  
  task request_random();
//    wait (ready_o == 1);
    
    req_i = 1;
    #10 req_i = 0;
//    #10;
    
    $display("Time: %0t, PRNG Output: %0h, Busy: %b, Ready: %b", $time, prng_o, busy_o, ready_o);
    
//    #20;
  endtask;

endmodule
