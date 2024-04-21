//`timescale 1ns / 1ps

module trivium_top #(
    parameter   int   WORDSIZE = 24,
    parameter   int   OUTPUT_BITS = 24
  )
  (
    input   logic                    clk_i, rst_i,
    input   logic                    req_i, refr_i,
    input   logic [79:0]             key_i,
    output  logic [WORDSIZE-1:0]     prng_o,
    output  logic                    busy_o,
    output  logic                    ready_o
    );
  
  logic  wRst, wEn;
  
  logic [OUTPUT_BITS-1:0] wStream;
  
  // Fixed IV
  logic  [79:0] wIV;
  assign  wIV = 80'h14F16FBA23D4499F06E3; 
   
  // Trivium instance 
  trivium #( .OUTPUT_BITS(OUTPUT_BITS))
  trivium_INST
  (  .clk(clk_i), .rst(wRst), .en(wEn), .iv_i(wIV), .key_i(key_i), .stream_o(wStream) );
  
  // State definition  
  localparam sRST       = 3'b000;
  localparam sINIT      = 3'b001;
  localparam sFETCH     = 3'b010;
  localparam sIDLE      = 3'b011;
  
  // Intervals for FSM (initialization of Trivium, fetching a word)
  localparam int unsigned INIT_INTERVAL  = 1152 / OUTPUT_BITS;
  localparam int unsigned FETCH_INTERVAL = WORDSIZE / OUTPUT_BITS;
  
  reg [$clog2(INIT_INTERVAL):0]   rCnt_Current, wCnt_Next;
  
  // FSM state
  reg [2:0] rFSM_Current, wFSM_Next; 
  
  // Register updates
  always_ff @(posedge clk_i)
  begin
    if (rst_i==1)
      begin
        rFSM_Current <= sRST;
        rCnt_Current <= 0;
      end
    else
      begin
        rFSM_Current <= wFSM_Next;
        rCnt_Current <= wCnt_Next;
      end
  end
  
  // Next state logic: drives signals to Trivium engine
  //  -> wRst : to reset the core (set up new key)
  //  -> wEn  : to enable the core
  // Monitors inputs:
  //  -> req_i  : new request for PRNG word
  //  -> refr_i : new request to refresh Key
  always_comb
    begin
      case (rFSM_Current)
      
        sRST :
          begin
            wFSM_Next = sINIT;
            wCnt_Next = 0;
          end 
           
        sINIT :
          begin
            //if ( rCnt_Current == (INIT_INTERVAL - 1) ) begin
            if ( rCnt_Current == $bits(rCnt_Current)'(INIT_INTERVAL - 1) ) begin
              wFSM_Next = sFETCH;
              wCnt_Next = 0;
            end else begin
              wFSM_Next = sINIT;
              wCnt_Next = rCnt_Current + 1;
            end
          end 
           
        sFETCH :
          begin
//            if ( rCnt_Current == $bits(rCnt_Current)'(FETCH_INTERVAL - 1) ) begin
//              wFSM_Next = sIDLE;
//              wCnt_Next = 0;
//            end else 
//            begin
//              wFSM_Next = sFETCH;
//              wCnt_Next = rCnt_Current + 1;
//            end
            wCnt_Next = 0;
            if ( req_i == 1 ) begin
              wFSM_Next = sFETCH;
            end else if (refr_i == 1) begin
              wFSM_Next = sRST;            
            end else begin
              wFSM_Next = sIDLE;
            end
          end 
 
        sIDLE :
          begin
            wCnt_Next = 0;
            if ( req_i == 1 ) begin
              wFSM_Next = sFETCH;
            end else if (refr_i == 1) begin
              wFSM_Next = sRST;            
            end else begin
              wFSM_Next = sIDLE;
            end
          end  
           
        default :
          begin
            wFSM_Next = sINIT;
            wCnt_Next = 0;
          end 
        endcase
    end 
    
    
//    always_ff @(posedge clk_i)
//    begin
////      if (rFSM_Current == sFETCH)
//        prng_o <= wStream;
//    end 
    
    assign prng_o = wStream;
    //when rFSM_Current == sFETCH, stores the value
    // the prng_o updates when wEn == 1
    
    assign wRst = (rFSM_Current==sRST) ? 1 : 0;
    assign wEn = (rFSM_Current==sINIT || rFSM_Current==sFETCH) ? 1 : 0;
    assign busy_o = (rFSM_Current==sIDLE) ? 0 : 1;
    assign ready_o = (rFSM_Current==sFETCH || rFSM_Current==sIDLE) ? 1 : 0;
    
    
endmodule