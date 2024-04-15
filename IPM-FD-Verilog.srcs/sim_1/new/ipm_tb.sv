`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/13 21:26:24
// Design Name: 
// Module Name: ipmmul_ex_tb
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


module ipm_tb;



  // Parameters
  localparam int n = 4;
  localparam int k = 1;

  // Testbench signals
  logic clk_i;
  logic reset_ni;
  logic [31:0] a_i;
  logic [31:0] b_i;
  logic ipm_en_i;
  logic ipm_sel_i;
  logic [31:0] result_o;
  logic [31:0] expected_result;
  logic valid_o;
  ibex_pkg::ipm_op_e ipm_operator_i;

  // Instantiate the Unit Under Test (UUT)
  //    ipmmul_ex #(
  //        .N(N)
  //    ) uut (
  //        .clk_i(clk_i),
  //        .reset_ni(reset_ni),
  //        .a_i(a_i),
  //        .b_i(b_i),
  //        .ipm_en_i(ipm_en_i),
  //        .ipm_sel_i(ipm_sel_i),
  //        .result_o(result_o),
  //        .valid_o(valid_o)
  //    );
  ipm #(
      .n(n),
      .k(k)
  ) ipm_inst (
      .clk_i(clk_i),
      .reset_ni(reset_ni),
      .a_i(a_i),
      .b_i(b_i),
      .ipm_en_i(ipm_en_i),
      .ipm_sel_i(ipm_sel_i),
      .ipm_operator_i(ipm_operator_i),
      .result_o(result_o),
      .valid_o(valid_o)
  );

  // Clock generation
  always #5 clk_i = ~clk_i;  // Generate a clock with a period of 10ns

  // Testbench initialia_iation and stimulus
  initial begin
    // Initialia_ie Inputs
    clk_i = 0;
    reset_ni = 0;
    a_i = 0;
    b_i = 0;
    ipm_en_i = 0;
    ipm_sel_i = 0;
    ipm_operator_i = ibex_pkg::IPM_OP_MUL;

    // Reset the design
    #100;
    reset_ni = 1;  // Release reset
    #100;


    a_i = 32'hac1665fd;  // Example value
    b_i = 32'h4ba78430;  // Example value
    expected_result = 32'hef23bd40;

    // Start the operation
    ipm_en_i = 1;
    ipm_sel_i = 1;

    // Wait for operation to complete
    wait (valid_o == 1);
    $display("Operation completed. Result result_o: %h, expected: %h", result_o, 32'hef23bd40);
    #20;
    ipm_en_i  = 0;
    ipm_sel_i = 0;

    // Add more stimuli or checks as needed

    // Finish simulation
    #100;
    ipm_operator_i = ibex_pkg::IPM_OP_MASK;
    a_i = 32'h21000000;  // Example value
    b_i = 32'h00000000;  // Example value
    expected_result = 32'ha8413f61;

    // Start the operation
    ipm_en_i = 1;
    ipm_sel_i = 1;

    // Wait for operation to complete
    wait (valid_o == 1);
    $display("Operation completed. Result result_o: %h, expected: %h", result_o, 32'ha8413f61);
    #20;
    ipm_en_i  = 0;
    ipm_sel_i = 0;

    // Add more stimuli or checks as needed

    // Finish simulation
    #100;
    ipm_operator_i = ibex_pkg::IPM_OP_HOMOG;
    a_i = 32'h63343a1e;  // Example value
    b_i = 32'h6b7a52da;  // Example value
    expected_result = 32'hd5343a1e;

    // Start the operation
    ipm_en_i = 1;
    ipm_sel_i = 1;

    // Wait for operation to complete
    wait (valid_o == 1);
    $display("Operation completed. Result result_o: %h, expected: %h", result_o, 32'hd5343a1e);
    #20;
    ipm_en_i  = 0;
    ipm_sel_i = 0;

    // Add more stimuli or checks as needed

    // Finish simulation
    #100;
    ipm_operator_i = ibex_pkg::IPM_OP_SQUARE;
    a_i = 32'ha8413f61;  // Example value
    b_i = 32'h6b7a52da;  // Example value
    expected_result = 32'hb68c9dc2;

    // Start the operation
    ipm_en_i = 1;
    ipm_sel_i = 1;

    // Wait for operation to complete
    wait (valid_o == 1);
    $display("Operation completed. Result result_o: %h, expected: %h", result_o, 32'hb68c9dc2);
    #20;
    ipm_en_i  = 0;
    ipm_sel_i = 0;

    // Finish simulation
    #100;

    $finish;
  end

endmodule

