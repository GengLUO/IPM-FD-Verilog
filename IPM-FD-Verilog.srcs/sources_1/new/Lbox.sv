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
    parameter k = 1,
    parameter N = 4
) (
    input logic [$clog2(k):0] position,
    output logic [7:0] L_prime[0:N-1-1],
    output logic [7:0] L_prime_inv[0:N-1-1]
);

  // initial begin
  //   $display("bits = %d, %d, %d", $bits(n), $bits(k), $bits(N));
  // end
  // logic [7:0] L[0:k-1][0:N-1];
  logic [7:0] L[0:k][0:N];
  // logic [7:0] L_inv[0:k-1][0:N-1];
  logic [7:0] L_inv[0:k][0:N];

  always_comb begin
    case ({
      2'(k), 3'(N - 1)
    })
      // {
      //   2'd1, 3'd1
      // } : begin
      //   L[0][0] = 8'd1;


      //   L_inv[0][0] = 8'd1;
      // end
      {
        2'd1, 3'd1
      } : begin
        // L[0][0] = 8'd1;
        L[0][0] = 8'd27;


        // L_inv[0][0] = 8'd1;
        L_inv[0][0] = 8'hcc;
      end
      {
        2'd1, 3'd2
      } : begin
        // L[0][0] = 8'd1;
        L[0][0] = 8'd27;
        L[0][1] = 8'd250;


        // L_inv[0][0] = 8'd1;
        L_inv[0][0] = 8'hcc;
        L_inv[0][1] = 8'h7d;
      end
      {
        2'd1, 3'd3
      } : begin
        // L[0][0] = 8'd1;
        L[0][0] = 8'd27;
        L[0][1] = 8'd250;
        L[0][2] = 8'd188;


        // L_inv[0][0] = 8'd1;
        L_inv[0][0] = 8'hcc;
        L_inv[0][1] = 8'h7d;
        L_inv[0][2] = 8'hbd;
      end
      // {
      //   2'd2, 3'd1
      // } : begin
      //   L[0][0] = 8'd1;
      //   L[1][0] = 8'd1;


      //   L_inv[0][0] = 8'd1;
      //   L_inv[1][0] = 8'd1;
      // end
      {
        2'd2, 3'd1
      } : begin
        // L[0][0] = 8'd1;
        L[0][0] = 8'd27;

        // L[1][0] = 8'd1;
        L[1][0] = 8'd188;


        // L_inv[0][0] = 8'd1;
        L_inv[0][0] = 8'hcc;

        // L_inv[1][0] = 8'd1;
        L_inv[1][0] = 8'hbd;
      end
      {
        2'd2, 3'd2
      } : begin
        // L[0][0] = 8'd1;
        L[0][0] = 8'd27;
        L[0][1] = 8'd151;

        // L[1][0] = 8'd1;
        L[1][0] = 8'd239;
        L[1][1] = 8'd128;


        // L_inv[0][0] = 8'd1;
        L_inv[0][0] = 8'hcc;
        L_inv[0][1] = 8'h72;

        // L_inv[1][0] = 8'd1;
        L_inv[1][0] = 8'hb3;
        L_inv[1][1] = 8'h83;
      end
      ////////////////////////////////////DUMMY TEST FOR n=5, k=2/////////////////////////////////////////////////
      {
        2'd2, 3'd3
      } : begin
        // L[0][0] = 8'd1;
        L[0][0] = 8'd43;
        L[0][1] = 8'd122;
        L[0][2] = 8'd199;

        // L[1][0] = 8'd1;
        L[1][0] = 8'd27;
        L[1][1] = 8'd250;
        L[1][2] = 8'd188;


        // L_inv[0][0] = 8'd1;
        L_inv[0][0] = 8'h15;
        L_inv[0][1] = 8'hd0;
        L_inv[0][2] = 8'h0f;

        // L_inv[1][0] = 8'd1;
        L_inv[1][0] = 8'hcc;
        L_inv[1][1] = 8'h7d;
        L_inv[1][2] = 8'hbd;
      end
      ////////////////////////////////////DUMMY TEST FOR n=5, k=2/////////////////////////////////////////////////
      default: begin

      end
    endcase
  end

  always_comb begin
    for (int i = 0; i < N - 1; i++) begin
      L_prime[i] = L[position][i];
      L_prime_inv[i] = L_inv[position][i];
    end
  end


endmodule
