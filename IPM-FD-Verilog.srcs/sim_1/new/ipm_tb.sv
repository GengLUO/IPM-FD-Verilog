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
    localparam int n = 5;
    localparam int k = 2;
    localparam int N = n - k + 1;

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
    logic correct;
    logic [31:0] temp;
    logic [31:0] temp1 [0:1];
    logic [31:0] temp2 [0:1];
    logic [31:0] temp3 [0:1];
    logic [5:0] need_cycle;

    ipm #(
        .n(n),
        .k(k)
    ) ipm_inst (
        .clk_i(clk_i),
        .rst_ni(reset_ni),
        .a_i(a_i),
        .b_i(b_i),
        .ipm_en_i(ipm_en_i),
        .ipm_sel_i(ipm_sel_i),
        .ipm_operator_i(ipm_operator_i),
        .result_o(result_o),
        .valid_o(valid_o)
    );

    task perform_operation(input [31:0] a, input [31:0] b, input ibex_pkg::ipm_op_e op, input [31:0] exp_result);
        a_i = a;
        b_i = b;
        expected_result = exp_result;
        ipm_operator_i = op;

        // Start the operation
        ipm_en_i = 1;
        ipm_sel_i = 1;
        

//        if(op == ibex_pkg::IPM_OP_MUL) begin
//            #((10*N*N-5)/5);
//            ipm_en_i = 0;
//            ipm_sel_i = 0;
//            #40;
//            ipm_en_i = 1;
//            ipm_sel_i = 1;
//            #((10*N*N-5)/5*4);
//        end else #5;
        if(op == ibex_pkg::IPM_OP_MUL) begin
            #((10*need_cycle-5)/5);
            #((10*need_cycle-5)/5*4);
        end else if (op == ibex_pkg::IPM_OP_MASK) begin
            #((10*need_cycle-5));
        end else #5;
        if (result_o == expected_result) begin
            $display("Test successful completed. Result: %h", result_o);
            correct = 1;
        end
        else begin
            $display("Error!. Result result_o: %h, expected: %h", result_o, expected_result);
            correct = 1'bx;
        end
//        if(op != ibex_pkg::IPM_OP_MUL) #5; else #10;
        #5;
        ipm_en_i = 0;
        ipm_sel_i = 0;
//        #20;
        
//        // Reset control signals
//        ipm_en_i = 0;
//        ipm_sel_i = 0;
    endtask

    // Clock generation
    always #5 clk_i = ~clk_i; // Generate a clock with a period of 10ns

    // Testbench initialia_iation and stimulus
    initial begin
        // Initialia_ie Inputs
        clk_i = 1;
        reset_ni = 0;
        a_i = 0;
        b_i = 0;
        ipm_en_i = 0;
        ipm_sel_i = 0;
        ipm_operator_i = ibex_pkg::IPM_OP_MUL;
        expected_result = 0;
        correct = 0;
        need_cycle = 0;

        // Reset the design
        #50;
        reset_ni = 1; // Release reset
        #500;
        //n=4, k=1
//        perform_operation(32'hac1665fd, 32'h4ba78430, ibex_pkg::IPM_OP_MUL, 32'hef23bd40);
//        perform_operation(32'hac1665fd, 32'h4ba78430, ibex_pkg::IPM_OP_MUL, 32'hef23bd40);
//        perform_operation(32'h21000000, 32'h00000000, ibex_pkg::IPM_OP_MASK, 32'ha8413f61);
//        perform_operation(32'h63343a1e, 32'h6b7a52da, ibex_pkg::IPM_OP_HOMOG, 32'hd5343a1e);
//        perform_operation(32'ha8413f61, 32'h6b7a52da, ibex_pkg::IPM_OP_SQUARE, 32'hb68c9dc2);
        //////////////MASK
        need_cycle = n-k;
        perform_operation(32'h21000000, 32'h00000000, ibex_pkg::IPM_OP_MASK, 32'hf5413f61);
        #50;
        need_cycle = 1;
        perform_operation(32'h21000000, 32'h00000000, ibex_pkg::IPM_OP_MASK, 32'ha8413f61);
        
        need_cycle = n-k;
        perform_operation(32'h37000000, 32'h00000000, ibex_pkg::IPM_OP_MASK, 32'he3413f61);
        need_cycle = 1;
        perform_operation(32'h37000000, 32'h00000000, ibex_pkg::IPM_OP_MASK, 32'hbe413f61);
        /////////////MULT
        need_cycle = N*N;
        perform_operation(32'hf5413f61, 32'he3413f61, ibex_pkg::IPM_OP_MUL, 32'ha2d56509);
        #50;
        need_cycle = N*N;
        perform_operation(32'ha8413f61, 32'hbe413f61, ibex_pkg::IPM_OP_MUL, 32'hd89b0dcd);
        /////////////HOMOG
        need_cycle = 1;
        perform_operation(32'ha2d56509, 32'hd89b0dcd, ibex_pkg::IPM_OP_HOMOG, 32'h66d56509);
        ////////////SQUARE
        need_cycle = 1;
        perform_operation(32'hf5413f61, 32'h00000000, ibex_pkg::IPM_OP_SQUARE, 32'h575e2de3);
        need_cycle = 1;
        perform_operation(32'ha8413f61, 32'h00000000, ibex_pkg::IPM_OP_SQUARE, 32'hb68c9dc2);
        /////////////HOMOG
        need_cycle = 1;
        perform_operation(32'h575e2de3, 32'hb68c9dc2, ibex_pkg::IPM_OP_HOMOG, 32'hd05e2de3);
        //////////////UNMASK
        need_cycle = 1;
        perform_operation(32'hf5413f61, 32'h00000000, ibex_pkg::IPM_OP_UNMASK, 32'h21000000);
        need_cycle = 1;
        perform_operation(32'ha8413f61, 32'h00000000, ibex_pkg::IPM_OP_UNMASK, 32'h21000000);
        
//        #50;
//        perform_operation_with_random_masks(32'h21000000, 32'h00000000, ibex_pkg::IPM_OP_MASK, 32'h21000000);
//        perform_mult_with_random_masks(32'h04000000, 32'h04000000, ibex_pkg::IPM_OP_MUL, 32'h10000000);
        $finish;
    end

    task perform_operation_with_random_masks(input [31:0] a, input [31:0] b, input ibex_pkg::ipm_op_e op, input [31:0] exp_result);
        a_i = a;
        b_i = b;
        expected_result = exp_result;
        ipm_operator_i = op;

        for (int i = 0; i < k; i ++) begin
        // Start the operation
        ipm_en_i = 1;
        ipm_sel_i = 1;
        
        if(op == ibex_pkg::IPM_OP_MUL) begin
            #((10*N*N-5)/5);
            #((10*N*N-5)/5*4);
        end else #5;
        temp = result_o;
        #5;
        end
        
        
        a_i = temp;
        ipm_operator_i = ibex_pkg::IPM_OP_UNMASK;
        
        for (int i = 0; i < k; i ++) begin
        // Start the operation
        ipm_en_i = 1;
        ipm_sel_i = 1;
        
        if(op == ibex_pkg::IPM_OP_MUL) begin
            #((10*N*N-5)/5);
            #((10*N*N-5)/5*4);
        end else #5;
        temp = result_o;
        #5;
        end

        
        
        if (result_o == expected_result) begin
            $display("Test successful completed. Result: %h", result_o);
            correct = 1;
        end
        else begin
            $display("Error!. Result result_o: %h, expected: %h", result_o, expected_result);
            correct = 1'bx;
        end
//        if(op != ibex_pkg::IPM_OP_MUL) #5; else #10;
        #5;
        ipm_en_i = 0;
        ipm_sel_i = 0;
    endtask;
    
    task perform_mult_with_random_masks(input [31:0] a, input [31:0] b, input ibex_pkg::ipm_op_e op, input [31:0] exp_result);
        a_i = a;
        b_i = 0;

        ipm_operator_i = ibex_pkg::IPM_OP_MASK;

        for (int i = 0; i < k; i ++) begin
        // Start the operation
        ipm_en_i = 1;
        ipm_sel_i = 1;
        
        if(ipm_operator_i == ibex_pkg::IPM_OP_MUL) begin
            #((10*N*N-5)/5);
            #((10*N*N-5)/5*4);
        end else #5;
        temp1[i] = result_o;
        #5;
        end
        
        a_i = b;
        b_i = 0;
        for (int i = 0; i < k; i ++) begin
        // Start the operation
        ipm_en_i = 1;
        ipm_sel_i = 1;
        
        if(ipm_operator_i == ibex_pkg::IPM_OP_MUL) begin
            #((10*N*N-5)/5);
            #((10*N*N-5)/5*4);
        end else #5;
        temp2[i] = result_o;
        #5;
        end
        
        /////////////MULT
        perform_operation(temp1[0], temp2[0], ibex_pkg::IPM_OP_MUL, 32'ha2d56509);
        temp3[0] = result_o;
        perform_operation(temp1[1], temp2[1], ibex_pkg::IPM_OP_MUL, 32'hd89b0dcd);
        temp3[1] = result_o;
        /////////////HOMOG
        perform_operation(temp3[0], temp3[1], ibex_pkg::IPM_OP_HOMOG, 32'h66d56509);
        temp3[1] = {result_o[31:24], temp3[0][23:0]};
//        ////////////SQUARE
//        perform_operation(32'hf5413f61, 32'h00000000, ibex_pkg::IPM_OP_SQUARE, 32'h575e2de3);
//        perform_operation(32'ha8413f61, 32'h00000000, ibex_pkg::IPM_OP_SQUARE, 32'hb68c9dc2);
//        /////////////HOMOG
//        perform_operation(32'h575e2de3, 32'hb68c9dc2, ibex_pkg::IPM_OP_HOMOG, 32'hd05e2de3);
        //////////////UNMASK
        perform_operation(temp3[0], 32'h00000000, ibex_pkg::IPM_OP_UNMASK, exp_result);
        perform_operation(temp3[1], 32'h00000000, ibex_pkg::IPM_OP_UNMASK, exp_result);
        
    endtask;
endmodule

