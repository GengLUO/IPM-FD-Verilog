//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/11 16:53:24
// Design Name: 
// Module Name: gfmul
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


module gfmul (
    input  logic [7:0] rs1,
    input  logic [7:0] rs2,
    output logic [7:0] rd
);

  logic [14:0] temp;

  always_comb begin
    temp[14] = rs1[7] & rs2[7];
    temp[13] = rs1[7] & rs2[6] ^ rs1[6] & rs2[7];
    temp[12] = rs1[7] & rs2[5] ^ rs1[6] & rs2[6] ^ rs1[5] & rs2[7];
    temp[11] = rs1[7] & rs2[4] ^ rs1[6] & rs2[5] ^ rs1[5] & rs2[6] ^ rs1[4] & rs2[7];
    temp[10] = rs1[7] & rs2[3] ^ rs1[6] & rs2[4] ^ rs1[5] & rs2[5] ^ rs1[4] & rs2[6] ^ rs1[3] & rs2[7];
    temp[9]  = rs1[7] & rs2[2] ^ rs1[6] & rs2[3] ^ rs1[5] & rs2[4] ^ rs1[4] & rs2[5] ^ rs1[3] & rs2[6] ^ rs1[2] & rs2[7];
    temp[8]  = rs1[7] & rs2[1] ^ rs1[6] & rs2[2] ^ rs1[5] & rs2[3] ^ rs1[4] & rs2[4] ^ rs1[3] & rs2[5] ^ rs1[2] & rs2[6] ^ rs1[1] & rs2[7];
    temp[7]  = rs1[7] & rs2[0] ^ rs1[6] & rs2[1] ^ rs1[5] & rs2[2] ^ rs1[4] & rs2[3] ^ rs1[3] & rs2[4] ^ rs1[2] & rs2[5] ^ rs1[1] & rs2[6] ^ rs1[0] & rs2[7];
    temp[6]  = rs1[6] & rs2[0] ^ rs1[5] & rs2[1] ^ rs1[4] & rs2[2] ^ rs1[3] & rs2[3] ^ rs1[2] & rs2[4] ^ rs1[1] & rs2[5] ^ rs1[0] & rs2[6];
    temp[5]  = rs1[5] & rs2[0] ^ rs1[4] & rs2[1] ^ rs1[3] & rs2[2] ^ rs1[2] & rs2[3] ^ rs1[1] & rs2[4] ^ rs1[0] & rs2[5];
    temp[4]  = rs1[4] & rs2[0] ^ rs1[3] & rs2[1] ^ rs1[2] & rs2[2] ^ rs1[1] & rs2[3] ^ rs1[0] & rs2[4];
    temp[3] = rs1[3] & rs2[0] ^ rs1[2] & rs2[1] ^ rs1[1] & rs2[2] ^ rs1[0] & rs2[3];
    temp[2] = rs1[2] & rs2[0] ^ rs1[1] & rs2[1] ^ rs1[0] & rs2[2];
    temp[1] = rs1[1] & rs2[0] ^ rs1[0] & rs2[1];
    temp[0] = rs1[0] & rs2[0];
  end

  assign rd[7] = temp[7] ^ temp[11] ^ temp[12] ^ temp[14];
  assign rd[6] = temp[6] ^ temp[10] ^ temp[11] ^ temp[13];
  assign rd[5] = temp[5] ^ temp[9] ^ temp[10] ^ temp[12];
  assign rd[4] = temp[4] ^ temp[8] ^ temp[9] ^ temp[11] ^ temp[14];
  assign rd[3] = temp[3] ^ temp[8] ^ temp[10] ^ temp[11] ^ temp[12] ^ temp[13] ^ temp[14];
  assign rd[2] = temp[2] ^ temp[9] ^ temp[10] ^ temp[13];
  assign rd[1] = temp[1] ^ temp[8] ^ temp[9] ^ temp[12] ^ temp[14];
  assign rd[0] = temp[0] ^ temp[8] ^ temp[12] ^ temp[13];
endmodule
