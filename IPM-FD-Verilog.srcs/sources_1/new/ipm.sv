module ipm #(
    parameter n = 5,
    parameter k = 2
) (
    input logic clk_i,
    input logic rst_ni,

    input logic [31:0] a_i,
    input logic [31:0] b_i,

    input logic ipm_en_i,  // dynamic enable signal, for FSM control
    input logic ipm_sel_i,  // static decoder output, for data muxes
    input ibex_pkg::ipm_op_e ipm_operator_i,

    output logic [31:0] result_o,
    output logic valid_o
);

  localparam N = n - k + 1;

  //unpack the operands
  logic [7:0] a[0:N-1];
  logic [7:0] b[0:N-1];

  always_comb begin
    // for (int i = 0; i < N; i++) begin
    //   a[N-1-i] = a_i[8*i+:8];
    //   b[N-1-i] = b_i[8*i+:8];
    // end
    a[0] = a_i[31-:8];
    a[1] = a_i[23-:8];
    a[2] = a_i[15-:8];
    a[3] = a_i[7-:8];
    b[0] = b_i[31-:8];
    b[1] = b_i[23-:8];
    b[2] = b_i[15-:8];
    b[3] = b_i[7-:8];
  end

  logic ipm_en;
  assign ipm_en = ipm_en_i;

  logic ipm_sel;
  assign ipm_sel = ipm_sel_i;

  ibex_pkg::ipm_op_e operator;
  assign operator = ipm_operator_i;

  // State definitions
  typedef enum logic [2:0] {
    IDLE,
    FIRST,
    COMPUTE,
    LAST
    // DONE
  } ipm_state_e;

  // FSM
  ipm_state_e ipm_state_q, ipm_state_d;

  // signal to indicate moving to next cell
  logic move_q, move_d;

  // Loop indices
  logic [$clog2(N)-1:0] i_q, j_q, i_d, j_d;

  logic [$clog2(N)-1:0] index_i, index_j;  //the true index to be performed on the matrix
  assign index_i = move_q ? i_q : j_q;
  assign index_j = move_q ? j_q : i_q;

  // multipliers
/* verilator lint_off UNOPTFLAT */
/* verilator lint_off IMPERFECTSCH */
  logic [7:0] multiplier_inputs_a[0:2];
/* verilator lint_on UNOPTFLAT*/
/* verilator lint_on IMPERFECTSCH */
  logic [7:0] multiplier_inputs_b[0:2];
  logic [7:0] multiplier_results[0:2];

  //registers to hold the intermediate values
  logic [7:0] mult_result[0:N-1];

  logic [7:0] rest_result[0:N-1];

  // for multiplication computations
  logic [7:0] T;
  logic [7:0] U;
  logic [7:0] U_prime_q, U_prime_d;

  // hardcoded random
  // logic [7:0] random[4][4];
  // initial begin
  //   random[0][0] = 8'd43;
  //   random[0][1] = 8'd65;
  //   random[0][2] = 8'd63;
  //   random[0][3] = 8'd97;

  //   random[1][0] = 8'd123;
  //   random[1][1] = 8'd1;
  //   random[1][2] = 8'd239;
  //   random[1][3] = 8'd54;

  //   random[2][0] = 8'd78;
  //   random[2][1] = 8'd76;
  //   random[2][2] = 8'd127;
  //   random[2][3] = 8'd179;

  //   random[3][0] = 8'd222;
  //   random[3][1] = 8'd48;
  //   random[3][2] = 8'd74;
  //   random[3][3] = 8'd59;
  // end

  ///////////
  // SQ box//
  ///////////
  logic [7:0] sq_res_block[0:3];
  sq sq_inst (
      .sq_i(a_i),
      .sq_o(sq_res_block)
  );

  ///////////
  // L box //
  ///////////

  logic [$clog2(k):0] position_Lbox, position_q, position_d;

  logic [7:0] L_prime[0:N-1];
  Lbox #(
      .n(n),
      .k(k)
  ) Lbox_inst (
      .position(position_Lbox),
      .L_prime (L_prime)
  );

  //homiginization operation start from the second row
  assign position_Lbox = (operator == ibex_pkg::IPM_OP_HOMOG) ? position_q + 1 : position_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      position_q <= 0;
    end else if (ipm_en) begin
      position_q <= position_d;
    end
  end

  always_comb begin : position_update
    position_d = position_q;
    if (valid_o) begin
      unique case (operator)
        ibex_pkg::IPM_OP_HOMOG: begin
          position_d = (position_q + 2 < $bits(position_d)'(k)) ? position_q + 1 : 0;
        end
        default: begin
          position_d = (position_q + 1 < $bits(position_d)'(k)) ? position_q + 1 : 0;
        end
      endcase
    end
  end

  ///////////
  // PRNG  //
  ///////////

  logic req;
  logic refr;
  logic [79:0] key;
  logic [24-1:0] prng;
  // logic busy;
  // logic ready;

  logic mul_req_random;
  // logic mask_req_random;

  logic [7:0] random[0:2];
  always_comb begin
    for (int i = 0; i < 3; i++) begin
      random[3-1-i] = prng[8*i+:8];
    end
  end

  // Trivium instance 
  trivium_top #(
      .WORDSIZE(24),
      .OUTPUT_BITS(24)
  ) trivium (
      .clk_i(clk_i),
      .reset_ni(rst_ni),
      .req_i(req),
      .refr_i(refr),
      .key_i(key),
      .prng_o(prng),
      .busy_o(),
      .ready_o()
  );

  always_comb begin : trivium_req_ctrl
    req  = 0;
    refr = 0;
    key  = 80'h00112233445566778899;

    if (ipm_sel) begin
      unique case (operator)
        ibex_pkg::IPM_OP_MUL: begin
          req = mul_req_random;
        end
        ibex_pkg::IPM_OP_MASK: begin
          req = (position_q == $bits(position_q)'(k - 1)) ? 1 : 0;
        end
        default: ;
      endcase
    end
  end

  //TODO: store inverse of L in L box
  logic [7:0] gf_inv [0:255];
  assign gf_inv[0]   = 8'h00;
  assign gf_inv[1]   = 8'h01;
  assign gf_inv[2]   = 8'h8d;
  assign gf_inv[3]   = 8'hf6;
  assign gf_inv[4]   = 8'hcb;
  assign gf_inv[5]   = 8'h52;
  assign gf_inv[6]   = 8'h7b;
  assign gf_inv[7]   = 8'hd1;
  assign gf_inv[8]   = 8'he8;
  assign gf_inv[9]   = 8'h4f;

  assign gf_inv[10]  = 8'h29;
  assign gf_inv[11]  = 8'hc0;
  assign gf_inv[12]  = 8'hb0;
  assign gf_inv[13]  = 8'he1;
  assign gf_inv[14]  = 8'he5;
  assign gf_inv[15]  = 8'hc7;
  assign gf_inv[16]  = 8'h74;
  assign gf_inv[17]  = 8'hb4;
  assign gf_inv[18]  = 8'haa;
  assign gf_inv[19]  = 8'h4b;

  assign gf_inv[20]  = 8'h99;
  assign gf_inv[21]  = 8'h2b;
  assign gf_inv[22]  = 8'h60;
  assign gf_inv[23]  = 8'h5f;
  assign gf_inv[24]  = 8'h58;
  assign gf_inv[25]  = 8'h3f;
  assign gf_inv[26]  = 8'hfd;
  assign gf_inv[27]  = 8'hcc;
  assign gf_inv[28]  = 8'hff;
  assign gf_inv[29]  = 8'h40;

  assign gf_inv[30]  = 8'hee;
  assign gf_inv[31]  = 8'hb2;
  assign gf_inv[32]  = 8'h3a;
  assign gf_inv[33]  = 8'h6e;
  assign gf_inv[34]  = 8'h5a;
  assign gf_inv[35]  = 8'hf1;
  assign gf_inv[36]  = 8'h55;
  assign gf_inv[37]  = 8'h4d;
  assign gf_inv[38]  = 8'ha8;
  assign gf_inv[39]  = 8'hc9;

  assign gf_inv[40]  = 8'hc1;
  assign gf_inv[41]  = 8'h0a;
  assign gf_inv[42]  = 8'h98;
  assign gf_inv[43]  = 8'h15;
  assign gf_inv[44]  = 8'h30;
  assign gf_inv[45]  = 8'h44;
  assign gf_inv[46]  = 8'ha2;
  assign gf_inv[47]  = 8'hc2;
  assign gf_inv[48]  = 8'h2c;
  assign gf_inv[49]  = 8'h45;

  assign gf_inv[50]  = 8'h92;
  assign gf_inv[51]  = 8'h6c;
  assign gf_inv[52]  = 8'hf3;
  assign gf_inv[53]  = 8'h39;
  assign gf_inv[54]  = 8'h66;
  assign gf_inv[55]  = 8'h42;	
  assign gf_inv[56]  = 8'hf2;
  assign gf_inv[57]  = 8'h35;
  assign gf_inv[58]  = 8'h20;
  assign gf_inv[59]  = 8'h6f;

  assign gf_inv[60]  = 8'h77;
  assign gf_inv[61]  = 8'hbb;
  assign gf_inv[62]  = 8'h59;
  assign gf_inv[63]  = 8'h19;
  assign gf_inv[64]  = 8'h1d;
  assign gf_inv[65]  = 8'hfe;
  assign gf_inv[66]  = 8'h37;
  assign gf_inv[67]  = 8'h67;
  assign gf_inv[68]  = 8'h2d;
  assign gf_inv[69]  = 8'h31;

  assign gf_inv[70]  = 8'hf5;
  assign gf_inv[71]  = 8'h69;
  assign gf_inv[72]  = 8'ha7;
  assign gf_inv[73]  = 8'h64;
  assign gf_inv[74]  = 8'hab;
  assign gf_inv[75]  = 8'h13;
  assign gf_inv[76]  = 8'h54;
  assign gf_inv[77]  = 8'h25;
  assign gf_inv[78]  = 8'he9;
  assign gf_inv[79]  = 8'h09;

  assign gf_inv[80]  = 8'hed;
  assign gf_inv[81]  = 8'h5c;
  assign gf_inv[82]  = 8'h05;
  assign gf_inv[83]  = 8'hca;
  assign gf_inv[84]  = 8'h4c;
  assign gf_inv[85]  = 8'h24;
  assign gf_inv[86]  = 8'h87;
  assign gf_inv[87]  = 8'hbf;
  assign gf_inv[88]  = 8'h18;
  assign gf_inv[89]  = 8'h3e;

  assign gf_inv[90]  = 8'h22;
  assign gf_inv[91]  = 8'hf0;
  assign gf_inv[92]  = 8'h51;
  assign gf_inv[93]  = 8'hec;
  assign gf_inv[94]  = 8'h61;
  assign gf_inv[95]  = 8'h17;
  assign gf_inv[96]  = 8'h16;
  assign gf_inv[97]  = 8'h5e;
  assign gf_inv[98]  = 8'haf;
  assign gf_inv[99]  = 8'hd3;

  assign gf_inv[100] = 8'h49;
  assign gf_inv[101] = 8'ha6;
  assign gf_inv[102] = 8'h36;
  assign gf_inv[103] = 8'h43;
  assign gf_inv[104] = 8'hf4;
  assign gf_inv[105] = 8'h47;
  assign gf_inv[106] = 8'h91;
  assign gf_inv[107] = 8'hdf;
  assign gf_inv[108] = 8'h33;
  assign gf_inv[109] = 8'h93;

  assign gf_inv[110] = 8'h21;
  assign gf_inv[111] = 8'h3b;
  assign gf_inv[112] = 8'h79;
  assign gf_inv[113] = 8'hb7;
  assign gf_inv[114] = 8'h97;
  assign gf_inv[115] = 8'h85;
  assign gf_inv[116] = 8'h10;
  assign gf_inv[117] = 8'hb5;
  assign gf_inv[118] = 8'hba;
  assign gf_inv[119] = 8'h3c;
  
  assign gf_inv[120] = 8'hb6;
  assign gf_inv[121] = 8'h70;
  assign gf_inv[122] = 8'hd0;
  assign gf_inv[123] = 8'h06;
  assign gf_inv[124] = 8'ha1;
  assign gf_inv[125] = 8'hfa;
  assign gf_inv[126] = 8'h81;
  assign gf_inv[127] = 8'h82;
  assign gf_inv[128] = 8'h83;
  assign gf_inv[129] = 8'h7e;
  
  assign gf_inv[130] = 8'h7f;
  assign gf_inv[131] = 8'h80;
  assign gf_inv[132] = 8'h96;
  assign gf_inv[133] = 8'h73;
  assign gf_inv[134] = 8'hbe;
  assign gf_inv[135] = 8'h56;
  assign gf_inv[136] = 8'h9b;
  assign gf_inv[137] = 8'h9e;
  assign gf_inv[138] = 8'h95;
  assign gf_inv[139] = 8'hd9;
  
  assign gf_inv[140] = 8'hf7;
  assign gf_inv[141] = 8'h02;
  assign gf_inv[142] = 8'hb9;
  assign gf_inv[143] = 8'ha4;
  assign gf_inv[144] = 8'hde;
  assign gf_inv[145] = 8'h6a;
  assign gf_inv[146] = 8'h32;
  assign gf_inv[147] = 8'h6d;
  assign gf_inv[148] = 8'hd8;
  assign gf_inv[149] = 8'h8a;
  
  assign gf_inv[150] = 8'h84;
  assign gf_inv[151] = 8'h72;
  assign gf_inv[152] = 8'h2a;
  assign gf_inv[153] = 8'h14;
  assign gf_inv[154] = 8'h9f;
  assign gf_inv[155] = 8'h88;
  assign gf_inv[156] = 8'hf9;
  assign gf_inv[157] = 8'hdc;
  assign gf_inv[158] = 8'h89;
  assign gf_inv[159] = 8'h9a;
  
  assign gf_inv[160] = 8'hfb;
  assign gf_inv[161] = 8'h7c;
  assign gf_inv[162] = 8'h2e;
  assign gf_inv[163] = 8'hc3;
  assign gf_inv[164] = 8'h8f;
  assign gf_inv[165] = 8'hb8;
  assign gf_inv[166] = 8'h65;
  assign gf_inv[167] = 8'h48;
  assign gf_inv[168] = 8'h26;
  assign gf_inv[169] = 8'hc8;

  assign gf_inv[170] = 8'h12;
  assign gf_inv[171] = 8'h4a;
  assign gf_inv[172] = 8'hce;
  assign gf_inv[173] = 8'he7;
  assign gf_inv[174] = 8'hd2;
  assign gf_inv[175] = 8'h62;
  assign gf_inv[176] = 8'h0c;
  assign gf_inv[177] = 8'he0;
  assign gf_inv[178] = 8'h1f;
  assign gf_inv[179] = 8'hef;

  assign gf_inv[180] = 8'h11;
  assign gf_inv[181] = 8'h75;
  assign gf_inv[182] = 8'h78;
  assign gf_inv[183] = 8'h71;
  assign gf_inv[184] = 8'ha5;
  assign gf_inv[185] = 8'h8e;
  assign gf_inv[186] = 8'h76;
  assign gf_inv[187] = 8'h3d;
  assign gf_inv[188] = 8'hbd;
  assign gf_inv[189] = 8'hbc;

  assign gf_inv[190] = 8'h86;
  assign gf_inv[191] = 8'h57;
  assign gf_inv[192] = 8'h0b;
  assign gf_inv[193] = 8'h28;
  assign gf_inv[194] = 8'h2f;
  assign gf_inv[195] = 8'ha3;
  assign gf_inv[196] = 8'hda;
  assign gf_inv[197] = 8'hd4;
  assign gf_inv[198] = 8'he4;
  assign gf_inv[199] = 8'h0f;

  assign gf_inv[200] = 8'ha9;
  assign gf_inv[201] = 8'h27;
  assign gf_inv[202] = 8'h53;
  assign gf_inv[203] = 8'h04;
  assign gf_inv[204] = 8'h1b;
  assign gf_inv[205] = 8'hfc;
  assign gf_inv[206] = 8'hac;
  assign gf_inv[207] = 8'he6;
  assign gf_inv[208] = 8'h7a;
  assign gf_inv[209] = 8'h07;

  assign gf_inv[210] = 8'hae;
  assign gf_inv[211] = 8'h63;
  assign gf_inv[212] = 8'hc5;
  assign gf_inv[213] = 8'hdb;
  assign gf_inv[214] = 8'he2;
  assign gf_inv[215] = 8'hea;
  assign gf_inv[216] = 8'h94;
  assign gf_inv[217] = 8'h8b;
  assign gf_inv[218] = 8'hc4;
  assign gf_inv[219] = 8'hd5;

  assign gf_inv[220] = 8'h9d;
  assign gf_inv[221] = 8'hf8;
  assign gf_inv[222] = 8'h90;
  assign gf_inv[223] = 8'h6b;
  assign gf_inv[224] = 8'hb1;
  assign gf_inv[225] = 8'h0d;
  assign gf_inv[226] = 8'hd6;
  assign gf_inv[227] = 8'heb;
  assign gf_inv[228] = 8'hc6;
  assign gf_inv[229] = 8'h0e;

  assign gf_inv[230] = 8'hcf;
  assign gf_inv[231] = 8'had;
  assign gf_inv[232] = 8'h08;
  assign gf_inv[233] = 8'h4e;
  assign gf_inv[234] = 8'hd7;
  assign gf_inv[235] = 8'he3;
  assign gf_inv[236] = 8'h5d;
  assign gf_inv[237] = 8'h50;
  assign gf_inv[238] = 8'h1e;
  assign gf_inv[239] = 8'hb3;

  assign gf_inv[240] = 8'h5b;
  assign gf_inv[241] = 8'h23;
  assign gf_inv[242] = 8'h38;
  assign gf_inv[243] = 8'h34;
  assign gf_inv[244] = 8'h68;
  assign gf_inv[245] = 8'h46;
  assign gf_inv[246] = 8'h03;
  assign gf_inv[247] = 8'h8c;
  assign gf_inv[248] = 8'hdd;
  assign gf_inv[249] = 8'h9c;

  assign gf_inv[250] = 8'h7d;
  assign gf_inv[251] = 8'ha0;
  assign gf_inv[252] = 8'hcd;
  assign gf_inv[253] = 8'h1a;
  assign gf_inv[254] = 8'h41;
  assign gf_inv[255] = 8'h1c;

// Instantiation of GF(256) multipliers
        gfmul gfmul_inst_0 (
            .rs1(multiplier_inputs_a[0]),
            .rs2(multiplier_inputs_b[0]),
            .rd(multiplier_results[0])
        );
        gfmul gfmul_inst_1 (
            .rs1(multiplier_inputs_a[1]),
            .rs2(multiplier_inputs_b[1]),
            .rd(multiplier_results[1])
        );
        gfmul gfmul_inst_2 (
            .rs1(multiplier_inputs_a[2]),
            .rs2(multiplier_inputs_b[2]),
            .rd(multiplier_results[2])
        );

  // State transition and output logic
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      ipm_state_q <= IDLE;
      i_q <= 0;
      j_q <= 0;
      for (int i = 0; i < N; i++) begin
        mult_result[i] <= 0;
      end
    end else if (ipm_en) begin
      ipm_state_q <= ipm_state_d;
      i_q <= i_d;
      j_q <= j_d;
      if (operator == ibex_pkg::IPM_OP_MUL) begin
        mult_result <= rest_result;
      end
    end
  end

  always_comb begin
    for (int i = 0; i < N; i++) begin
      rest_result[i] = 0;
    end
    unique case (operator)
      ibex_pkg::IPM_OP_MUL: begin
        unique case (ipm_state_q)
          FIRST: begin
            for (int i = 0; i < N; i++) begin
              rest_result[i] = 0;
            end
            rest_result[0] = T ^ U;
          end
          COMPUTE, LAST: begin
            for (int i = 0; i < N; i++) begin
              rest_result[i] = mult_result[i];
            end
            rest_result[index_i] = mult_result[index_i] ^ T ^ U;
          end
          default: ;
        endcase
      end
      ibex_pkg::IPM_OP_HOMOG: begin
        rest_result[0] = b[0] ^ multiplier_results[0] ^ multiplier_results[1] ^ multiplier_results[2];
        for (int i = 1; i < N; i++) begin
          rest_result[i] = a[i];
        end
      end
      ibex_pkg::IPM_OP_SQUARE: begin
        rest_result[0] = sq_res_block[0];
        for (int i = 1; i < N; i++) begin
          rest_result[i] = multiplier_results[i-1];
        end
      end
      ibex_pkg::IPM_OP_MASK: begin
        rest_result[0] = a[0] ^ multiplier_results[0] ^ multiplier_results[1] ^ multiplier_results[2];
        for (int i = 1; i < n; i++) begin
          rest_result[i] = random[i-1];
          // rest_result[i] = random[0][i];
        end
      end
      ibex_pkg::IPM_OP_UNMASK: begin
        rest_result[0] = a[0] ^ multiplier_results[0] ^ multiplier_results[1] ^ multiplier_results[2];
      end
      default: ;
    endcase
  end


  // Next state logic
  always_comb begin
    ipm_state_d = ipm_state_q;
    unique case (ipm_state_q)
      IDLE: begin
        ipm_state_d = FIRST;
      end
      FIRST: begin
        unique case (operator)
          ibex_pkg::IPM_OP_MUL: begin
            ipm_state_d = (i_d == $bits(i_d)'(0) && j_d == $bits(j_d)'(0)) ? FIRST : COMPUTE;
          end
          ibex_pkg::IPM_OP_HOMOG, ibex_pkg::IPM_OP_SQUARE, ibex_pkg::IPM_OP_MASK, ibex_pkg::IPM_OP_UNMASK: begin
            ipm_state_d = FIRST;  //require 0 cycle, can already get the result
          end
          default: ;
        endcase
      end
      COMPUTE: begin
        unique case (operator)
          ibex_pkg::IPM_OP_MUL: begin
            ipm_state_d = (i_d == $bits(i_d)'(N - 1) && j_d == $bits(j_d)'(N - 1)) ? LAST :
                COMPUTE;  //require n^2 cycles to complete
          end
          default: ;
        endcase
      end
      LAST: begin
        ipm_state_d = FIRST;
      end
      // DONE: ipm_state_d = FIRST;
      default: ipm_state_d = IDLE;
    endcase
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : move_signal
    if (!rst_ni) begin
      move_q <= 0;
    end else if (ipm_en) begin
      move_q <= move_d;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      U_prime_q <= 0;  //only used for ipmmul
    end else if (ipm_en) begin
      U_prime_q <= U_prime_d;  //only used for ipmmul
    end
  end

  always_comb begin
    move_d = 1;
    U_prime_d = 0;
    mul_req_random = 0;
    for (int i = 0; i < 3; i++) begin
      multiplier_inputs_a[i] = 0;
      multiplier_inputs_b[i] = 0;
    end
    T = 0;
    U = 0;

    unique case (operator)
      ibex_pkg::IPM_OP_MUL: begin
        // if (ipm_en) begin
        if (i_d == j_d) begin  // next cell is at the diagonal, U_prime is 0, need random data for T
          move_d = 1;  //need to 'MOVE'
          U_prime_d = 0;
          mul_req_random = 0;
        end else begin  //next cell is not at the diagonal
          if (move_q) begin  // toggle the request
            move_d = 0;
            U_prime_d = random[0];
            // U_prime_d = random[i_d][j_d];
            mul_req_random = 1;
          end else begin
            move_d = 1;
            U_prime_d = U_prime_q;
            mul_req_random = 0;
          end
        end
      end
      // end
      default: ;
    endcase

    unique case (operator)
      ibex_pkg::IPM_OP_MUL: begin
        multiplier_inputs_a[0] = a[index_i];
        multiplier_inputs_b[0] = b[index_j];

        multiplier_inputs_a[1] = multiplier_results[0];
        multiplier_inputs_b[1] = L_prime[index_j];
        T = multiplier_results[1];

        multiplier_inputs_a[2] = U_prime_q;
        multiplier_inputs_b[2] = gf_inv[L_prime[index_i]];
        U = multiplier_results[2];
      end
      ibex_pkg::IPM_OP_MASK: begin
        for (int i = 0; i < 3; i++) begin
          multiplier_inputs_a[i] = random[i];
          // multiplier_inputs_a[i] = random[0][i+1];
          multiplier_inputs_b[i] = L_prime[i+1];
        end
      end
      ibex_pkg::IPM_OP_HOMOG: begin
        for (int i = 0; i < 3; i++) begin
          multiplier_inputs_a[i] = L_prime[i+1];
          multiplier_inputs_b[i] = a[i+1] ^ b[i+1];
        end
      end
      ibex_pkg::IPM_OP_SQUARE: begin
        for (int i = 0; i < 3; i++) begin
          multiplier_inputs_a[i] = sq_res_block[i+1];
          multiplier_inputs_b[i] = L_prime[i+1];
        end
      end
      ibex_pkg::IPM_OP_UNMASK: begin
        for (int i = 0; i < 3; i++) begin
          multiplier_inputs_a[i] = a[i+1];
          multiplier_inputs_b[i] = L_prime[i+1];
        end
      end
      default: ;
    endcase
  end

  always_comb begin : Index_update_logic
    i_d = i_q;
    j_d = j_q;

    // if (ipm_en) begin
    if (operator == ibex_pkg::IPM_OP_MUL) begin  //only for MUL
      //When the current state is FIRST or COMPUTE,
      //which means IPM_MUL is computing
      if (ipm_state_q != IDLE && ipm_state_q != LAST) begin
        //move_q == signal to indicate 'MOVE'
        if (move_q) begin : move_index
          if (j_q < $bits(j_q)'(N - 1)) begin : move_right
            i_d = i_q;
            j_d = j_q + 1;  //continue to the right cell
          end else begin : move_next_row
            i_d = i_q + 1;  // go to next row
            j_d = i_d;  // j starts from the diagonal
          end
        end else begin : stay_index  //i and j do not change
          i_d = i_q;
          j_d = j_q;
        end
      end else if (ipm_state_q == LAST) begin : last_cycle_clear_index
        i_d = 0;
        j_d = 0;
      end
    end else begin : not_mul_clear_index
      i_d = 0;
      j_d = 0;
    end
    // end
  end

  // assign valid_o = ipm_state_q == DONE || ipm_state_q == LAST || (ipm_state_q == FIRST && operator != ibex_pkg::IPM_OP_MUL); //TODO: cope with != condition for extensibility
  assign valid_o = ipm_state_q == LAST || (ipm_state_q == FIRST && operator != ibex_pkg::IPM_OP_MUL); //TODO: cope with != condition for extensibility

  // always_comb begin
  //   result_o = {8 * N{1'b0}};
  //   for (int i = 0; i < N; i++) begin
  //     if (operator != ibex_pkg::IPM_OP_MUL) begin
  //       result_o |= (rest_result[i] << $bits(rest_result[i])'((8 * (N - 1 - i))));
  //     end else if (ipm_state_q == LAST) begin
  //       result_o |= (rest_result[i] << $bits(rest_result[i])'((8 * (N - 1 - i))));
  //     end else begin
  //       result_o |= (mult_result[i] << $bits(rest_result[i])'((8 * (N - 1 - i))));
  //     end
  //   end
  // end
  // always_comb begin
  //   for (int i = 0; i < N; i++) begin
  //     result_o[8*i+:8] = rest_result[N-1-i];
  //   end
  // end
  always_comb begin
    result_o[31-:8] = rest_result[0];
    result_o[23-:8] = rest_result[1];
    result_o[15-:8] = rest_result[2];
    result_o[7-:8] = rest_result[3];
  end



endmodule
