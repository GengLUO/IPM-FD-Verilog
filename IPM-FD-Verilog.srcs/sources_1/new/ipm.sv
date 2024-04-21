module ipm #(
    parameter  bit [2:0] n = 4,
    parameter  bit [1:0] k = 1,
    localparam bit [2:0] N = n - k + 1
) (
    input logic clk_i,
    input logic reset_ni,
    input logic [31:0] a_i,
    input logic [31:0] b_i,

    input logic ipm_en_i,  // dynamic enable signal, for FSM control
    input logic ipm_sel_i,  // static decoder output, for data muxes
    input ibex_pkg::ipm_op_e ipm_operator_i,

    output logic [31:0] result_o,
    output logic valid_o
);

  // State definitions
  typedef enum logic [2:0] {
    IDLE,
    FIRST,
    COMPUTE,
    LAST
    // DONE
  } state_e;

  // Registers for FSM
  state_e ipm_state_q, ipm_state_d;
  logic request_q, request_d;

  // Registers for loop indices and intermediate values
  logic [$clog2(N)-1:0] i_q, j_q, i_d, j_d;

  logic [$clog2(N)-1:0] index_i, index_j;  //the true index to be performed on the matrix
  assign index_i = request_q ? i_q : j_q;
  assign index_j = request_q ? j_q : i_q;

  // multipliers
  logic [7:0] multiplier_inputs_a[0:2];
  logic [7:0] multiplier_inputs_b[0:2];
  logic [7:0] multiplier_results [0:2];

  logic       ipm_hold;
  logic       ipm_en;
  assign ipm_en = ipm_en_i;

  logic [7:0] mult_result[0:N-1];
  logic [7:0] a[0:N-1];
  logic [7:0] b[0:N-1];

  always_comb begin
    for (int i = 0; i < N; i++) begin
      a[N-1-i] = a_i[8*i+:8];
      b[N-1-i] = b_i[8*i+:8];
    end
  end

  // Memory for multiplication computations
  logic [7:0] T;
  logic [7:0] U;
  logic [7:0] U_prime_q, U_prime_d;

  //TODO: replace hardcoded random to PRNG
  logic [7:0] random[4][4];
  initial begin
    random[0][0] = 8'd43;
    random[0][1] = 8'd65;
    random[0][2] = 8'd63;
    random[0][3] = 8'd97;

    random[1][0] = 8'd123;
    random[1][1] = 8'd1;
    random[1][2] = 8'd239;
    random[1][3] = 8'd54;

    random[2][0] = 8'd78;
    random[2][1] = 8'd76;
    random[2][2] = 8'd127;
    random[2][3] = 8'd179;

    random[3][0] = 8'd222;
    random[3][1] = 8'd48;
    random[3][2] = 8'd74;
    random[3][3] = 8'd59;
  end

  ibex_pkg::ipm_op_e operator;
  assign operator = ipm_operator_i;

  logic [7:0] sq_res_block[0:3];
  sq sq_inst (
      .sq_i(a_i),
      .sq_o(sq_res_block)
  );

  //TODO: change position to copy with k
  logic [$clog2(k)-1:0] position_Lbox, position_q, position_d;
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

  always_ff @(posedge clk_i or negedge reset_ni) begin
    if (!reset_ni) begin
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
          position_d = (position_q + 1 < $bits(position_d)'(k - 1)) ? position_q + 1 : 0;
        end
        default: begin
          position_d = (position_q < $bits(position_d)'(k - 1)) ? position_q + 1 : 0;
        end
      endcase
    end
  end

  logic req;
  logic refr;
  logic [79:0] key;
  logic [24-1:0] prng;
  logic busy;
  logic ready;

  // Trivium instance 
  trivium_top #(
      .WORDSIZE(24),
      .OUTPUT_BITS(24)
  ) trivium (
      .clk_i(clk_i),
      .reset_ni(reset_ni),
      .req_i(req),
      .refr_i(refr),
      .key_i(key),
      .prng_o(prng),
      .busy_o(busy),
      .ready_o(ready)
  );

  always_comb begin : trivium_req_ctrl
    req  = 0;
    refr = 0;
    key  = 80'h00112233445566778899;

    if (ipm_en) begin
      unique case (operator)
        ibex_pkg::IPM_OP_MUL: begin
          // req = 1;
          req = request_q;
        end
        ibex_pkg::IPM_OP_MASK: begin
          req = (position_q == $bits(position_q)'(0)) ? 1 : 0;
        end
        default: ;
      endcase
    end
  end

  logic [7:0] rest_result[0:N-1];

  logic [7:0] gf_inv [0:255] = {
		8'h00, 8'h01, 8'h8d, 8'hf6, 8'hcb, 8'h52, 8'h7b, 8'hd1,
		8'he8, 8'h4f, 8'h29, 8'hc0, 8'hb0, 8'he1, 8'he5, 8'hc7,
		8'h74, 8'hb4, 8'haa, 8'h4b, 8'h99, 8'h2b, 8'h60, 8'h5f,
		8'h58, 8'h3f, 8'hfd, 8'hcc, 8'hff, 8'h40, 8'hee, 8'hb2,
		8'h3a, 8'h6e, 8'h5a, 8'hf1, 8'h55, 8'h4d, 8'ha8, 8'hc9,
		8'hc1, 8'h0a, 8'h98, 8'h15, 8'h30, 8'h44, 8'ha2, 8'hc2,
		8'h2c, 8'h45, 8'h92, 8'h6c, 8'hf3, 8'h39, 8'h66, 8'h42,	
		8'hf2, 8'h35, 8'h20, 8'h6f, 8'h77, 8'hbb, 8'h59, 8'h19,
		8'h1d, 8'hfe, 8'h37, 8'h67, 8'h2d, 8'h31, 8'hf5, 8'h69,
		8'ha7, 8'h64, 8'hab, 8'h13, 8'h54, 8'h25, 8'he9, 8'h09,
		8'hed, 8'h5c, 8'h05, 8'hca, 8'h4c, 8'h24, 8'h87, 8'hbf,
		8'h18, 8'h3e, 8'h22, 8'hf0, 8'h51, 8'hec, 8'h61, 8'h17,
		8'h16, 8'h5e, 8'haf, 8'hd3, 8'h49, 8'ha6, 8'h36, 8'h43,
		8'hf4, 8'h47, 8'h91, 8'hdf, 8'h33, 8'h93, 8'h21, 8'h3b,
		8'h79, 8'hb7, 8'h97, 8'h85, 8'h10, 8'hb5, 8'hba, 8'h3c,
		8'hb6, 8'h70, 8'hd0, 8'h06, 8'ha1, 8'hfa, 8'h81, 8'h82,
		8'h83, 8'h7e, 8'h7f, 8'h80, 8'h96, 8'h73, 8'hbe, 8'h56,
		8'h9b, 8'h9e, 8'h95, 8'hd9, 8'hf7, 8'h02, 8'hb9, 8'ha4,
		8'hde, 8'h6a, 8'h32, 8'h6d, 8'hd8, 8'h8a, 8'h84, 8'h72,
		8'h2a, 8'h14, 8'h9f, 8'h88, 8'hf9, 8'hdc, 8'h89, 8'h9a,
		8'hfb, 8'h7c, 8'h2e, 8'hc3, 8'h8f, 8'hb8, 8'h65, 8'h48,
		8'h26, 8'hc8, 8'h12, 8'h4a, 8'hce, 8'he7, 8'hd2, 8'h62,
		8'h0c, 8'he0, 8'h1f, 8'hef, 8'h11, 8'h75, 8'h78, 8'h71,
		8'ha5, 8'h8e, 8'h76, 8'h3d, 8'hbd, 8'hbc, 8'h86, 8'h57,
		8'h0b, 8'h28, 8'h2f, 8'ha3, 8'hda, 8'hd4, 8'he4, 8'h0f,
		8'ha9, 8'h27, 8'h53, 8'h04, 8'h1b, 8'hfc, 8'hac, 8'he6,
		8'h7a, 8'h07, 8'hae, 8'h63, 8'hc5, 8'hdb, 8'he2, 8'hea,
		8'h94, 8'h8b, 8'hc4, 8'hd5, 8'h9d, 8'hf8, 8'h90, 8'h6b,
		8'hb1, 8'h0d, 8'hd6, 8'heb, 8'hc6, 8'h0e, 8'hcf, 8'had,
		8'h08, 8'h4e, 8'hd7, 8'he3, 8'h5d, 8'h50, 8'h1e, 8'hb3,
		8'h5b, 8'h23, 8'h38, 8'h34, 8'h68, 8'h46, 8'h03, 8'h8c,
		8'hdd, 8'h9c, 8'h7d, 8'ha0, 8'hcd, 8'h1a, 8'h41, 8'h1c
  };

  // Instantiation of GF(256) multipliers
  gfmul gfmul_inst[0:2] (
      .rs1(multiplier_inputs_a),
      .rs2(multiplier_inputs_b),
      .rd (multiplier_results)
  );

  // State transition and output logic
  always_ff @(posedge clk_i or negedge reset_ni) begin
    if (!reset_ni) begin
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

      mult_result <= rest_result;

      // case (ipm_state_q)
      //   FIRST: begin
      //       mult_result[0] <= T ^ U;
      //       for (int i = 1; i < N; i++) begin
      //         mult_result[i] <= 0;
      //       end
      //   end
      //   COMPUTE, LAST: begin
      //       unique case (operator)
      //         ibex_pkg::IPM_OP_MUL: begin
      //           // mult_result[index_i] <= mult_result[index_i] ^ T ^ U;
      //           mult_result <= rest_result;
      //         end
      //         default;
      //       endcase
      //   end
      //   default: ;
      // endcase

      // if (operator == ibex_pkg::IPM_OP_MUL) begin
      //   mult_result <= rest_result;
      // end
      // else begin
      //   for (int i = 0; i < N; i++) begin
      //   mult_result[i] <= 0;
      //   end
      // end

    end
  end

  always_comb begin
    for (int i = 0; i < N; i++) begin
      rest_result[i] = 0;
    end
    unique case (operator)
      ibex_pkg::IPM_OP_MUL: begin
        // for (int i = 0; i < N; i++) begin
        //   rest_result[i] = mult_result[i];
        // end

        rest_result[index_i] = mult_result[index_i] ^ T ^ U;
        unique case (ipm_state_q)
          FIRST: begin
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
        //         ibex_pkg::IPM_OP_MUL: begin 
        //   for (int i = 0; i < N; i++) begin
        //     rest_result[i] = mult_result[i];
        //   end
        //   if (ipm_state_q == FIRST) begin
        //     for (int i = 0; i < N; i++) begin
        //       rest_result[i] = 0;
        //     end
        //     rest_result[0] = T ^ U;
        //   end else begin
        //     rest_result[index_i] = mult_result[index_i] ^ T ^ U;
        //   end
        // end
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
          rest_result[i] = random[0][i];
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
    if (ipm_sel_i) begin
      unique case (ipm_state_q)
        IDLE: begin
          ipm_state_d = FIRST;
        end
        FIRST: begin
          unique case (operator)
            ibex_pkg::IPM_OP_MUL: begin
              ipm_state_d = (i_d == 0 && j_d == 0) ? FIRST : COMPUTE;
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
  end

  always_ff @(posedge clk_i or negedge reset_ni) begin : request_signal
    if (!reset_ni) begin
      request_q <= 0;
    end else if (ipm_en) begin
      request_q <= request_d;
    end
  end

  always_ff @(posedge clk_i or negedge reset_ni) begin
    if (!reset_ni) begin
      U_prime_q <= 0;  //only used for ipmmul
    end else if (ipm_en) begin
      U_prime_q <= U_prime_d;  //only used for ipmmul
    end
  end

  always_comb begin
    request_d = 1;
    U_prime_d = 0;
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
          request_d = 1;  //need to 'MOVE'
          U_prime_d = 0;
        end else begin  //next cell is not at the diagonal
          if (request_q) begin  // toggle the request
            request_d = 0;
            U_prime_d = random[i_d][j_d];
          end else begin
            request_d = 1;
            U_prime_d = U_prime_q;
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
          multiplier_inputs_a[i] = random[0][i+1];
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
        //request_q == signal to indicate 'MOVE'
        if (request_q) begin
          if (j_q < $bits(j_q)'(N - 1)) begin : move_right
            //one row is not finished yet
            i_d = i_q;
            j_d = j_q + 1;  //continue to the right cell
          end else begin : move_next_row  // one row is finished (at the end of one row)
            i_d = i_q + 1;  // go to next row
            j_d = i_d;  // j starts from the diagonal
          end
        end else begin : stay_index  //i and j do not change
          i_d = i_q;
          j_d = j_q;
        end
      end else if (ipm_state_q == LAST) begin : clear_index
        i_d = 0;
        j_d = 0;
      end
    end else begin : not_mul
      i_d = 0;
      j_d = 0;
    end
    // end
  end

  // assign valid_o = ipm_state_q == DONE || ipm_state_q == LAST || (ipm_state_q == FIRST && operator != ibex_pkg::IPM_OP_MUL); //TODO: cope with != condition for extensibility
  assign valid_o = ipm_state_q == LAST || (ipm_state_q == FIRST && operator != ibex_pkg::IPM_OP_MUL); //TODO: cope with != condition for extensibility

  always_comb begin
    result_o = {8 * N{1'b0}};
    for (int i = 0; i < N; i++) begin
      if (operator != ibex_pkg::IPM_OP_MUL) begin
        result_o |= (rest_result[i] << (8 * (N - 1 - i)));
      end else if (ipm_state_q == LAST) begin
        result_o |= (rest_result[i] << (8 * (N - 1 - i)));
      end else begin
        result_o |= (mult_result[i] << (8 * (N - 1 - i)));
      end
    end
  end



endmodule
