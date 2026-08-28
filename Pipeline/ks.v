`include "E.v"
`include "P.v"
`include "IP.v"
`include "IP_inv.v"
`include "PC1.v"
`include "PC2.v"


module KS_left_shift(input [5:1] level, input [28:1] in, output [28:1] out);
  assign out = (level == 1 || level == 2 || level == 9 || level == 16) ?
                {in[27:1], in[28]} : {in[26:1], in[28:27]};
endmodule

module KS(input [64:1] key, output [48:1] k1,
                            output [48:1] k2,
                            output [48:1] k3,
                            output [48:1] k4,
                            output [48:1] k5,
                            output [48:1] k6,
                            output [48:1] k7,
                            output [48:1] k8,
                            output [48:1] k9,
                            output [48:1] k10,
                            output [48:1] k11,
                            output [48:1] k12,
                            output [48:1] k13,
                            output [48:1] k14,
                            output [48:1] k15,
                            output [48:1] k16);
  wire [56:1] key_pc1;
  PC1 pc1_inst(key, key_pc1);

  wire [28:1] c [0:16];
  wire [28:1] d [0:16];
  wire [48:1] k [1:16];

  assign {c[0], d[0]} = key_pc1;

  genvar i;
  generate
    for (i = 1; i <= 16; i = i + 1) begin : blk
      wire [5:1] j = i;
      KS_left_shift KS_ls_inst1(j, c[i - 1], c[i]);
      KS_left_shift KS_ls_inst2(j, d[i - 1], d[i]);
      PC2 pc2_inst({c[i], d[i]}, k[i]);
    end
  endgenerate

  assign k1 = k[1];
  assign k2 = k[2];
  assign k3 = k[3];
  assign k4 = k[4];
  assign k5 = k[5];
  assign k6 = k[6];
  assign k7 = k[7];
  assign k8 = k[8];
  assign k9 = k[9];
  assign k10 = k[10];
  assign k11 = k[11];
  assign k12 = k[12];
  assign k13 = k[13];
  assign k14 = k[14];
  assign k15 = k[15];
  assign k16 = k[16];
endmodule