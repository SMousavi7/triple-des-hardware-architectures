`include "E.v"
`include "P.v"
`include "S1.v"
`include "S2.v"
`include "S3.v"
`include "S4.v"
`include "S5.v"
`include "S6.v"
`include "S7.v"
`include "S8.v"
`include "IP.v"
`include "IP_inv.v"
`include "PC1.v"
`include "PC2.v"

// The Feistel function f.  All other DES sub-permutations are pulled in by
// the `include` directives above.  The round-by-round key schedule lives in
// the KS_step module (no global KS module is used in this implementation –
// each round computes its own round key in the same cycle).
module f(input [32:1] R, input [48:1] K, output [32:1] OUT);
  wire [48:1] R_E;
  E E_inst(R, R_E);
  wire [48:1] T = R_E ^ K;
  wire [6:1] S1_in, S2_in, S3_in, S4_in, S5_in, S6_in, S7_in, S8_in;
  assign {S1_in, S2_in, S3_in, S4_in, S5_in, S6_in, S7_in, S8_in} = T;
  wire [4:1] S1_out, S2_out, S3_out, S4_out, S5_out, S6_out, S7_out, S8_out;
  S1 S1_inst(S1_in, S1_out);
  S2 S2_inst(S2_in, S2_out);
  S3 S3_inst(S3_in, S3_out);
  S4 S4_inst(S4_in, S4_out);
  S5 S5_inst(S5_in, S5_out);
  S6 S6_inst(S6_in, S6_out);
  S7 S7_inst(S7_in, S7_out);
  S8 S8_inst(S8_in, S8_out);
  wire [32:1] S_out = {S1_out, S2_out, S3_out, S4_out, S5_out, S6_out, S7_out, S8_out};
  P P_inst(S_out, OUT);
endmodule
