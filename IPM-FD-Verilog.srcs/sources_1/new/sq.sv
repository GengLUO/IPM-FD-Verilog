//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/23 16:49:59
// Design Name: 
// Module Name: sq
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


module sq #(
    parameter N = 4
) (
    input  logic [7:0] sq_i [0:N-1],
    output logic [7:0] sq_o [0:N-1]
);

  logic [7:0] sq[0:255];
    assign sq[0]  = 8'h00;
    assign sq[1]  = 8'h01;
    assign sq[2]  = 8'h04;
    assign sq[3]  = 8'h05;
    assign sq[4]  = 8'h10;
    assign sq[5]  = 8'h11;
    assign sq[6]  = 8'h14;
    assign sq[7]  = 8'h15;
    assign sq[8]  = 8'h40;
    assign sq[9]  = 8'h41;
    assign sq[10] = 8'h44;
    assign sq[11] = 8'h45;
    assign sq[12] = 8'h50;
    assign sq[13] = 8'h51;
    assign sq[14] = 8'h54;
    assign sq[15] = 8'h55;
    assign sq[16] = 8'h1b;
    assign sq[17] = 8'h1a;
    assign sq[18] = 8'h1f;
    assign sq[19] = 8'h1e;
    assign sq[20] = 8'h0b;
    assign sq[21] = 8'h0a;
    assign sq[22] = 8'h0f;
    assign sq[23] = 8'h0e;
    assign sq[24] = 8'h5b;
    assign sq[25] = 8'h5a;
    assign sq[26] = 8'h5f;
    assign sq[27] = 8'h5e;
    assign sq[28] = 8'h4b;
    assign sq[29] = 8'h4a;
    assign sq[30] = 8'h4f;
    assign sq[31] = 8'h4e;
    assign sq[32] = 8'h6c;
    assign sq[33] = 8'h6d;
    assign sq[34] = 8'h68;
    assign sq[35] = 8'h69;
    assign sq[36] = 8'h7c;
    assign sq[37] = 8'h7d;
    assign sq[38] = 8'h78;
    assign sq[39] = 8'h79;
    assign sq[40] = 8'h2c;
    assign sq[41] = 8'h2d;
    assign sq[42] = 8'h28;
    assign sq[43] = 8'h29;
    assign sq[44] = 8'h3c;
    assign sq[45] = 8'h3d;
    assign sq[46] = 8'h38;
    assign sq[47] = 8'h39;
    assign sq[48] = 8'h77;
    assign sq[49] = 8'h76;
    assign sq[50] = 8'h73;
    assign sq[51] = 8'h72;
    assign sq[52] = 8'h67;
    assign sq[53] = 8'h66;
    assign sq[54] = 8'h63;
    assign sq[55] = 8'h62;
    assign sq[56] = 8'h37;
    assign sq[57] = 8'h36;
    assign sq[58] = 8'h33;
    assign sq[59] = 8'h32;
    assign sq[60] = 8'h27;
    assign sq[61] = 8'h26;
    assign sq[62] = 8'h23;
    assign sq[63] = 8'h22;
    assign sq[64] = 8'hab;
    assign sq[65] = 8'haa;
    assign sq[66] = 8'haf;
    assign sq[67] = 8'hae;
    assign sq[68] = 8'hbb;
    assign sq[69] = 8'hba;
    assign sq[70] = 8'hbf;
    assign sq[71] = 8'hbe;
    assign sq[72] = 8'heb;
    assign sq[73] = 8'hea;
    assign sq[74] = 8'hef;
    assign sq[75] = 8'hee;
    assign sq[76] = 8'hfb;
    assign sq[77] = 8'hfa;
    assign sq[78] = 8'hff;
    assign sq[79] = 8'hfe;
    assign sq[80] = 8'hb0;
    assign sq[81] = 8'hb1;
    assign sq[82] = 8'hb4;
    assign sq[83] = 8'hb5;
    assign sq[84] = 8'ha0;
    assign sq[85] = 8'ha1;
    assign sq[86] = 8'ha4;
    assign sq[87] = 8'ha5;
    assign sq[88] = 8'hf0;
    assign sq[89] = 8'hf1;
    assign sq[90] = 8'hf4;
    assign sq[91] = 8'hf5;
    assign sq[92] = 8'he0;
    assign sq[93] = 8'he1;
    assign sq[94] = 8'he4;
    assign sq[95] = 8'he5;
    assign sq[96] = 8'hc7;
    assign sq[97] = 8'hc6;
    assign sq[98] = 8'hc3;
    assign sq[99] = 8'hc2;
    assign sq[100]= 8'hd7;
    assign sq[101]= 8'hd6;
    assign sq[102]= 8'hd3;
    assign sq[103]= 8'hd2;
    assign sq[104]= 8'h87;
    assign sq[105]= 8'h86;
    assign sq[106]= 8'h83;
    assign sq[107]= 8'h82;
    assign sq[108]= 8'h97;
    assign sq[109]= 8'h96;
    assign sq[110]= 8'h93;
    assign sq[111]= 8'h92;
    assign sq[112]= 8'hdc;
    assign sq[113]= 8'hdd;
    assign sq[114]= 8'hd8;
    assign sq[115]= 8'hd9;
    assign sq[116]= 8'hcc;
    assign sq[117]= 8'hcd;
    assign sq[118]= 8'hc8;
    assign sq[119]= 8'hc9;
    assign sq[120]= 8'h9c;
    assign sq[121]= 8'h9d;
    assign sq[122]= 8'h98;
    assign sq[123]= 8'h99;
    assign sq[124]= 8'h8c;
    assign sq[125]= 8'h8d;
    assign sq[126]= 8'h88;
    assign sq[127]= 8'h89;
    assign sq[128]= 8'h9a;
    assign sq[129]= 8'h9b;
    assign sq[130]= 8'h9e;
    assign sq[131]= 8'h9f;
    assign sq[132]= 8'h8a;
    assign sq[133]= 8'h8b;
    assign sq[134]= 8'h8e;
    assign sq[135]= 8'h8f;
    assign sq[136]= 8'hda;
    assign sq[137]= 8'hdb;
    assign sq[138]= 8'hde;
    assign sq[139]= 8'hdf;
    assign sq[140]= 8'hca;
    assign sq[141]= 8'hcb;
    assign sq[142]= 8'hce;
    assign sq[143]= 8'hcf;
    assign sq[144]= 8'h81;
    assign sq[145]= 8'h80;
    assign sq[146]= 8'h85;
    assign sq[147]= 8'h84;
    assign sq[148]= 8'h91;
    assign sq[149]= 8'h90;
    assign sq[150]= 8'h95;
    assign sq[151]= 8'h94;
    assign sq[152]= 8'hc1;
    assign sq[153]= 8'hc0;
    assign sq[154]= 8'hc5;
    assign sq[155]= 8'hc4;
    assign sq[156]= 8'hd1;
    assign sq[157]= 8'hd0;
    assign sq[158]= 8'hd5;
    assign sq[159]= 8'hd4;
    assign sq[160]= 8'hf6;
    assign sq[161]= 8'hf7;
    assign sq[162]= 8'hf2;
    assign sq[163]= 8'hf3;
    assign sq[164]= 8'he6;
    assign sq[165]= 8'he7;
    assign sq[166]= 8'he2;
    assign sq[167]= 8'he3;
    assign sq[168]= 8'hb6;
    assign sq[169]= 8'hb7;
    assign sq[170]= 8'hb2;
    assign sq[171]= 8'hb3;
    assign sq[172]= 8'ha6;
    assign sq[173]= 8'ha7;
    assign sq[174]= 8'ha2;
    assign sq[175]= 8'ha3;
    assign sq[176]= 8'hed;
    assign sq[177]= 8'hec;
    assign sq[178]= 8'he9;
    assign sq[179]= 8'he8;
    assign sq[180]= 8'hfd;
    assign sq[181]= 8'hfc;
    assign sq[182]= 8'hf9;
    assign sq[183]= 8'hf8;
    assign sq[184]= 8'had;
    assign sq[185]= 8'hac;
    assign sq[186]= 8'ha9;
    assign sq[187]= 8'ha8;
    assign sq[188]= 8'hbd;
    assign sq[189]= 8'hbc;
    assign sq[190]= 8'hb9;
    assign sq[191]= 8'hb8;
    assign sq[192]= 8'h31;
    assign sq[193]= 8'h30;
    assign sq[194]= 8'h35;
    assign sq[195]= 8'h34;
    assign sq[196]= 8'h21;
    assign sq[197]= 8'h20;
    assign sq[198]= 8'h25;
    assign sq[199]= 8'h24;
    assign sq[200]= 8'h71;
    assign sq[201]= 8'h70;
    assign sq[202]= 8'h75;
    assign sq[203]= 8'h74;
    assign sq[204]= 8'h61;
    assign sq[205]= 8'h60;
    assign sq[206]= 8'h65;
    assign sq[207]= 8'h64;
    assign sq[208]= 8'h2a;
    assign sq[209]= 8'h2b;
    assign sq[210]= 8'h2e;
    assign sq[211]= 8'h2f;
    assign sq[212]= 8'h3a;
    assign sq[213]= 8'h3b;
    assign sq[214]= 8'h3e;
    assign sq[215]= 8'h3f;
    assign sq[216]= 8'h6a;
    assign sq[217]= 8'h6b;
    assign sq[218]= 8'h6e;
    assign sq[219]= 8'h6f;
    assign sq[220]= 8'h7a;
    assign sq[221]= 8'h7b;
    assign sq[222]= 8'h7e;
    assign sq[223]= 8'h7f;
    assign sq[224]= 8'h5d;
    assign sq[225]= 8'h5c;
    assign sq[226]= 8'h59;
    assign sq[227]= 8'h58;
    assign sq[228]= 8'h4d;
    assign sq[229]= 8'h4c;
    assign sq[230]= 8'h49;
    assign sq[231]= 8'h48;
    assign sq[232]= 8'h1d;
    assign sq[233]= 8'h1c;
    assign sq[234]= 8'h19;
    assign sq[235]= 8'h18;
    assign sq[236]= 8'h0d;
    assign sq[237]= 8'h0c;
    assign sq[238]= 8'h09;
    assign sq[239]= 8'h08;
    assign sq[240]= 8'h46;
    assign sq[241]= 8'h47;
    assign sq[242]= 8'h42;
    assign sq[243]= 8'h43;
    assign sq[244]= 8'h56;
    assign sq[245]= 8'h57;
    assign sq[246]= 8'h52;
    assign sq[247]= 8'h53;
    assign sq[248]= 8'h06;
    assign sq[249]= 8'h07;
    assign sq[250]= 8'h02;
    assign sq[251]= 8'h03;
    assign sq[252]= 8'h16;
    assign sq[253]= 8'h17;
    assign sq[254]= 8'h12;
    assign sq[255]= 8'h13;

  always_comb begin
    for (int i = 0; i < N; i++) begin
      sq_o[i] = sq[sq_i[i]];
    end
  end

endmodule