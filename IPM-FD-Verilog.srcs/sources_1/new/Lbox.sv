//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/23 18:15:53
// Design Name: 
// Module Name: Lbox
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


module Lbox #(
    parameter  bit [2:0] n = 4,
    parameter  bit [1:0] k = 1,
    localparam bit [2:0] N = n - k + 1
) (
    input logic [$clog2(k)-1:0] position,
    output logic [7:0] L_prime[0:N-1]
);

  logic [7:0] L[0:k-1][0:N-1];

  always_comb begin
    case ({
      k, N
    })
      {
        2'd1, 3'd1
      } : begin
        L[0][0] = 8'd1;
      end
      {
        2'd1, 3'd2
      } : begin
        L[0][0] = 8'd1;
        L[0][1] = 8'd27;
      end
      {
        2'd1, 3'd3
      } : begin
        L[0][0] = 8'd1;
        L[0][1] = 8'd27;
        L[0][2] = 8'd250;
      end
      {
        2'd1, 3'd4
      } : begin
        L[0][0] = 8'd1;
        L[0][1] = 8'd27;
        L[0][2] = 8'd250;
        L[0][3] = 8'd188;
      end
      {
        2'd2, 3'd1
      } : begin
        L[0][0] = 8'd1;
        L[1][0] = 8'd1;
      end
      {
        2'd2, 3'd2
      } : begin
        L[0][0] = 8'd1;
        L[0][1] = 8'd27;

        L[1][0] = 8'd1;
        L[1][1] = 8'd188;
      end
      {
        2'd2, 3'd3
      } : begin
        L[0][0] = 8'd1;
        L[0][1] = 8'd27;
        L[0][2] = 8'd151;

        L[1][0] = 8'd1;
        L[1][1] = 8'd239;
        L[1][2] = 8'd128;
      end
      ////////////////////////////////////DUMMY TEST FOR n=5, k=2/////////////////////////////////////////////////
      {
        2'd2, 3'd5
      } : begin
        L[0][0] = 8'd1;
        L[0][1] = 8'd43;
        L[0][2] = 8'd122;
        L[0][3] = 8'd199;

        L[1][0] = 8'd1;
        L[1][1] = 8'd27;
        L[1][2] = 8'd250;
        L[1][3] = 8'd188;
      end
      ////////////////////////////////////DUMMY TEST FOR n=5, k=2/////////////////////////////////////////////////
      default: begin

      end
    endcase
  end

  always_comb begin
    for (int i = 0; i < N; i++) begin
      L_prime[i] = L[position][i];
    end
  end


endmodule
