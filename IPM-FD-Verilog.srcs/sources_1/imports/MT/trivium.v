//`timescale 1ns / 1ps

module trivium #(
    parameter OUTPUT_BITS = 4
  )
  (
    input   wire                    clk, rst, en,
    input   wire [79:0]             iv_i,
    input   wire [79:0]             key_i,
    output  wire [OUTPUT_BITS-1:0]  stream_o
  );
  
  reg [287:0] state [0:OUTPUT_BITS];
  
  reg [OUTPUT_BITS-1:0]  t1, t2, t3;
  
  always @(posedge clk)
  begin
    if (rst==1)
      state[0] <= {3'b111, 112'h0000000000000000000000000000, iv_i , 12'h000 , 1'b0, key_i};
    else if (en==1)
      state[0] <= state[OUTPUT_BITS];
  end
  
  genvar i;
  generate for (i=1; i <= OUTPUT_BITS; i = i + 1) begin: MultipleCycles
    always @(*)
    begin
      t1[i - 1] = state[i - 1][161] ^ state[i - 1][176];
      t2[i - 1] = state[i - 1][65] ^ state[i - 1][92];
      t3[i - 1] = state[i - 1][242] ^ state[i - 1][287];
      state[i] = {state[i - 1][286:177],t1[i - 1] ^ (state[i - 1][174] & state[i - 1][175]) ^ state[i - 1][263],state[i - 1][175:93],t2[i - 1] ^ (state[i - 1][90] & state[i - 1][91]) ^ state[i - 1][170],state[i - 1][91:0],t3[i - 1] ^ (state[i - 1][285] & state[i - 1][286]) ^ state[i - 1][68]};
    end
    assign stream_o[i - 1] = t1[OUTPUT_BITS - i] ^ t2[OUTPUT_BITS - i] ^ t3[OUTPUT_BITS - i];
  end
  endgenerate
    
endmodule