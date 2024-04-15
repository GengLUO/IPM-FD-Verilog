`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/11 16:54:54
// Design Name: 
// Module Name: gfmul_tb
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


module gfmul_tb;

logic [7:0] rs1;
logic [7:0] rs2;
logic [7:0] rd;

// Instantiate the Unit Under Test (UUT)
gfmul uut (
    .rs1(rs1), 
    .rs2(rs2), 
    .rd(rd)
);

initial begin
    // Initialia_ie Inputs
    rs1 = 0;
    rs2 = 0;
    #100; // Wait 100 ns for global reset

    // Apply test vectors
    rs1 = 8'hff; rs2 = 8'h55; #10;
    rs1 = 8'h23; rs2 = 8'h81; #10;
    rs1 = 8'ha5; rs2 = 8'h5a; #10;
    rs1 = 8'h02; rs2 = 8'h03; #10;
    rs1 = 8'h1c; rs2 = 8'hfe; #10;
    rs1 = 8'he3; rs2 = 8'h7f; #10;
    
    // Wait for a while and check the output
    #100;
    
    // Finish the simulation
    $finish;
end

endmodule
