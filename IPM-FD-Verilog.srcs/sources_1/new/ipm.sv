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

  //registers to hold the multiplication intermediate values
  logic [7:0] mult_result[0:N-1];

  logic [7:0] rest_result[0:N-1];

  // for multiplication computations
  logic [7:0] T;
  logic [7:0] U;
  logic [7:0] U_prime;

  //////////////////////
  // hardcoded random //
  //////////////////////

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

  ////////////
  // SQ box //
  ////////////
  logic [7:0] sq_res_block[0:N-1];
  sq #(
      .N(N)
  ) sq_inst (
      .sq_i(a),
      .sq_o(sq_res_block)
  );

  ///////////
  // L box //
  ///////////

  logic [$clog2(k):0] position_Lbox, position_q, position_d;

  logic [7:0] L_prime[0:N-1];
  logic [7:0] L_prime_inv[0:N-1];
  Lbox #(
      .N(N),
      .k(k)
  ) Lbox_inst (
      .position(position_Lbox),
      .L_prime(L_prime),
      .L_prime_inv(L_prime_inv)
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
  logic [7:0] prng;
  // logic busy;
  // logic ready;

  logic mul_req_random;
  logic mask_req_random;
  logic req_random_mux;

  always_comb begin
    mul_req_random = 0;

    if (operator == ibex_pkg::IPM_OP_MUL) begin
      if (index_i < index_j) begin
        mul_req_random = 1;
      end
    end
  end

  always_comb begin
    mask_req_random = 0;

    if (operator == ibex_pkg::IPM_OP_MASK) begin
      if (position_q == $bits(position_q)'(0) && ipm_state_q != LAST) begin
        // when computing on the first row, need to require random
        // but not the LAST
        mask_req_random = 1;
      end else if (position_q == $bits(position_q)'(k - 1)) begin
        // after computing all repetitions, require random for the following operation
        mask_req_random = 1;
      end else begin
        mask_req_random = 0;
      end
    end
  end

  always_comb begin
    req_random_mux = 0;

    if (ipm_sel) begin
      unique case (operator)
        ibex_pkg::IPM_OP_MUL: begin
          req_random_mux = mul_req_random;
        end
        ibex_pkg::IPM_OP_MASK: begin
          req_random_mux = mask_req_random;
        end
        default: ;
      endcase
    end
  end

  //Need to store the N-2 random masks, with another 1 from the current prng to form the N-1 masks to be used
  logic [7:0] random_mask_temp_q[0:N-2];
  logic [7:0] random_mask_temp_d[0:N-2];

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int i = 0; i < N - 1; i++) begin
        random_mask_temp_q[i] <= 0;
      end
    end else if (ipm_en) begin
      for (int i = 0; i < N - 1; i++) begin
        random_mask_temp_q[i] <= random_mask_temp_d[i];
      end
    end
  end

  always_comb begin
    for (int i = 0; i < N - 1; i++) begin
      random_mask_temp_d[i] = random_mask_temp_q[i];
    end
    unique case (operator)
      ibex_pkg::IPM_OP_MASK: begin
        if (position_q == $bits(position_q)'(0)) begin
          //only update the random number registers when compuiting on the first row
          random_mask_temp_d[j_q] = prng;
        end
      end
      default: ;
    endcase
  end

  // Trivium instance 
  trivium_top #(
      .WORDSIZE(8),
      .OUTPUT_BITS(8)
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
    req  = req_random_mux;
    refr = 0;
    key  = 80'h00112233445566778899;
  end

  // Instantiation of GF(256) multipliers
  gfmul gfmul_inst_0 (
      .rs1(multiplier_inputs_a[0]),
      .rs2(multiplier_inputs_b[0]),
      .rd (multiplier_results[0])
  );
  gfmul gfmul_inst_1 (
      .rs1(multiplier_inputs_a[1]),
      .rs2(multiplier_inputs_b[1]),
      .rd (multiplier_results[1])
  );
  gfmul gfmul_inst_2 (
      .rs1(multiplier_inputs_a[2]),
      .rs2(multiplier_inputs_b[2]),
      .rd (multiplier_results[2])
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
        for (int i = 1; i < N; i++) begin
          rest_result[i]   = random_mask_temp_q[i-1];
          rest_result[N-1] = prng;
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
          ibex_pkg::IPM_OP_MASK: begin
            ipm_state_d = (i_d == $bits(i_d)'(0) && j_d == $bits(j_d)'(0)) ? FIRST : COMPUTE;
          end
          ibex_pkg::IPM_OP_HOMOG, ibex_pkg::IPM_OP_SQUARE, ibex_pkg::IPM_OP_UNMASK: begin
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
          ibex_pkg::IPM_OP_MASK: begin
            ipm_state_d = (j_d + 1 == $bits(j_d)'(N - 1)) ? LAST :
                COMPUTE;  //require (n-k) or (N-1) cycles to complete
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

  always_comb begin
    move_d = 1;

    unique case (operator)
      ibex_pkg::IPM_OP_MUL: begin
        // if (ipm_en) begin
        if (i_d == j_d) begin  // next cell is at the diagonal, U_prime is 0, need random data for T
          move_d = 1;  //need to 'MOVE'
        end else begin  //next cell is not at the diagonal
          if (move_q) begin  // toggle the request
            move_d = 0;
          end else begin
            move_d = 1;
          end
        end
      end
      // end
      default: ;
    endcase
  end

  always_comb begin
    U_prime = (i_q == j_q) ? 0 : prng;
  end

  always_comb begin
    for (int i = 0; i < 3; i++) begin
      multiplier_inputs_a[i] = 0;
      multiplier_inputs_b[i] = 0;
    end
    T = 0;
    U = 0;

    unique case (operator)
      ibex_pkg::IPM_OP_MUL: begin
        multiplier_inputs_a[0] = a[index_i];
        multiplier_inputs_b[0] = b[index_j];

        multiplier_inputs_a[1] = multiplier_results[0];
        multiplier_inputs_b[1] = L_prime[index_j];
        T = multiplier_results[1];

        multiplier_inputs_a[2] = U_prime;
        multiplier_inputs_b[2] = L_prime_inv[index_i];
        U = multiplier_results[2];
      end
      ibex_pkg::IPM_OP_MASK: begin
        for (int i = 0; i < 3; i++) begin
          // multiplier_inputs_a[i] = random[i];
          if (i < 2) multiplier_inputs_a[i] = random_mask_temp_q[i];
          else multiplier_inputs_a[i] = prng;
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

    unique case (operator)
      ibex_pkg::IPM_OP_MUL: begin
        //When the current state is FIRST or COMPUTE,
        //which means MUL or MASK is computing
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
      end

      ibex_pkg::IPM_OP_MASK: begin
        if (ipm_state_q == LAST) begin
          j_d = 0;
        end else if (position_q == 0) begin
          j_d = j_q + 1;
        end else begin
          j_d = 0;
        end
      end
      default: begin
        i_d = 0;
        j_d = 0;
      end
    endcase
  end


  //////////////////
  // output logic //
  //////////////////

  always_comb begin
    valid_o = 0;
    unique case (operator)
      ibex_pkg::IPM_OP_MUL: begin
        valid_o = ipm_state_q == LAST;
      end
      ibex_pkg::IPM_OP_MASK: begin
        // For the repetitions, only one cycle is enough
        if (ipm_state_q == FIRST && position_q != $bits(position_q)'(0)) begin
          valid_o = 1;
        end  // For the first time, one need to wait till the LAST state
        else if (ipm_state_q == LAST) begin
          valid_o = 1;
        end else begin
          valid_o = 0;
        end
      end
      ibex_pkg::IPM_OP_SQUARE, ibex_pkg::IPM_OP_HOMOG, ibex_pkg::IPM_OP_UNMASK: begin
        valid_o = ipm_state_q == FIRST;
      end
      default: ;
    endcase
  end

  always_comb begin
    result_o[31-:8] = rest_result[0];
    result_o[23-:8] = rest_result[1];
    result_o[15-:8] = rest_result[2];
    result_o[7-:8]  = rest_result[3];
  end



endmodule
