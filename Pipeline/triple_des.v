// =============================================================================
//  Pipelined Triple-DES   (48 stages — ECB only)
//  ----------------------------------------------
//  Each pipeline stage performs ONE Feistel round AND generates ONE round key
//  in the same clock cycle, using a KS_step (single rotation + PC2).  No
//  round key is precomputed; the (C, D) halves walk through the pipeline
//  alongside (L, R).
//
//      Stages  1..16 : DES #1   with key K1
//      Stages 17..32 : DES #2   with key K2
//      Stages 33..48 : DES #3   with key K1
//
//  When the user requests encryption (decrypt = 0):
//      DES#1, DES#3 walk the KS *forward*  (k1, k2, …, k16)
//      DES#2        walks the KS *backward* (k16, k15, …, k1)
//  When the user requests decryption (decrypt = 1):  walks are mirrored.
// =============================================================================
module triple_des_pipe(
    input             clk,
    input             rst,
    input             valid_in,
    input      [63:0] in,
    input     [127:0] key,
    input             decrypt,
    output reg [63:0] out,
    output reg        valid_out
);

    // ---------- Initial (C, D) for K1 and K2  ----------
    wire [56:1] pc1_K1, pc1_K2;
    PC1 pc1_inst1(key[127:64], pc1_K1);
    PC1 pc1_inst2(key[63:0],   pc1_K2);
    wire [28:1] C0_K1 = pc1_K1[56:29];
    wire [28:1] D0_K1 = pc1_K1[28:1];
    wire [28:1] C0_K2 = pc1_K2[56:29];
    wire [28:1] D0_K2 = pc1_K2[28:1];

    // ---------- Pipeline storage (per stage) ----------
    reg [32:1] L_reg [1:48];
    reg [32:1] R_reg [1:48];
    reg [28:1] C_reg [1:48];
    reg [28:1] D_reg [1:48];
    reg        v_reg [1:48];

    // ---------- Per-stage walk parameters ----------
    // Stage s belongs to:
    //    DES#1 (s in 1..16),  DES#2 (s in 17..32),  DES#3 (s in 33..48)
    // For each stage we need:  level, reverse, apply_shift  for KS_step
    //
    // DES#1 (and DES#3) in encrypt mode:  forward walk
    //     local_round r = s, s-32   →  level = r, reverse=0, apply_shift=1
    // DES#1 (and DES#3) in decrypt mode:  backward walk
    //     local_round r = 1 → no shift (yields k16)
    //     local_round r > 1 → level = 18-r, reverse=1, apply_shift=1
    //
    // DES#2 is the opposite walk of DES#1/#3.
    //
    //  walk_fwd = (this DES's walk is forward)
    //           = (decrypt == 0  &&  this is DES#1 or DES#3)
    //          || (decrypt == 1  &&  this is DES#2)
    //
    //  ⇒ walk_fwd  =  decrypt XOR (DES is #2)

    function automatic [4:0] local_round(input integer s);
        begin
            if      (s <= 16) local_round = s;
            else if (s <= 32) local_round = s - 16;
            else              local_round = s - 32;
        end
    endfunction
    function automatic integer is_des2(input integer s);
        is_des2 = (s >= 17 && s <= 32) ? 1 : 0;
    endfunction

    // Combinational KS_step instances and Feistel computation per stage
    wire [28:1] C_in   [1:48];
    wire [28:1] D_in   [1:48];
    wire [32:1] L_in   [1:48];
    wire [32:1] R_in   [1:48];
    wire [28:1] C_next [1:48];
    wire [28:1] D_next [1:48];
    wire [48:1] rk     [1:48];
    wire [32:1] f_out  [1:48];
    wire [32:1] L_next [1:48];
    wire [32:1] R_next [1:48];

    // -------------- Stage inputs (data side) --------------
    //  Stage 1's data input = IP(in)
    wire [64:1] in_ip;
    IP ip_in(in, in_ip);
    assign L_in[1] = in_ip[64:33];
    assign R_in[1] = in_ip[32:1];

    //  Stage 17's data input = IP(IP_inv(swap(L16, R16)))   ← post DES#1
    wire [64:1] des1_post = {R_reg[16], L_reg[16]};
    wire [64:1] des1_out_w;
    IP_inv ipiv_12(des1_post, des1_out_w);
    wire [64:1] des2_in_ip;
    IP ip_12(des1_out_w, des2_in_ip);
    assign L_in[17] = des2_in_ip[64:33];
    assign R_in[17] = des2_in_ip[32:1];

    //  Stage 33's data input = IP(IP_inv(swap(L32, R32)))   ← post DES#2
    wire [64:1] des2_post = {R_reg[32], L_reg[32]};
    wire [64:1] des2_out_w;
    IP_inv ipiv_23(des2_post, des2_out_w);
    wire [64:1] des3_in_ip;
    IP ip_23(des2_out_w, des3_in_ip);
    assign L_in[33] = des3_in_ip[64:33];
    assign R_in[33] = des3_in_ip[32:1];

    // Other stages just forward registers
    genvar s;
    generate
        for (s = 2;  s <= 16; s = s + 1) begin : DI1
            assign L_in[s] = L_reg[s-1];
            assign R_in[s] = R_reg[s-1];
        end
        for (s = 18; s <= 32; s = s + 1) begin : DI2
            assign L_in[s] = L_reg[s-1];
            assign R_in[s] = R_reg[s-1];
        end
        for (s = 34; s <= 48; s = s + 1) begin : DI3
            assign L_in[s] = L_reg[s-1];
            assign R_in[s] = R_reg[s-1];
        end
    endgenerate

    // -------------- Stage inputs (key side) --------------
    //  Stage 1's (C, D) input = (C0_K1, D0_K1)
    //  Stage 17 's (C, D) input = (C0_K2, D0_K2)
    //  Stage 33's (C, D) input = (C0_K1, D0_K1)
    assign C_in[1]  = C0_K1;  assign D_in[1]  = D0_K1;
    assign C_in[17] = C0_K2;  assign D_in[17] = D0_K2;
    assign C_in[33] = C0_K1;  assign D_in[33] = D0_K1;
    generate
        for (s = 2;  s <= 16; s = s + 1) begin : KI1
            assign C_in[s] = C_reg[s-1];
            assign D_in[s] = D_reg[s-1];
        end
        for (s = 18; s <= 32; s = s + 1) begin : KI2
            assign C_in[s] = C_reg[s-1];
            assign D_in[s] = D_reg[s-1];
        end
        for (s = 34; s <= 48; s = s + 1) begin : KI3
            assign C_in[s] = C_reg[s-1];
            assign D_in[s] = D_reg[s-1];
        end
    endgenerate

    // -------------- KS_step + Feistel per stage --------------
    generate
        for (s = 1; s <= 48; s = s + 1) begin : RND
            // Decide walk direction for this stage.
            //   In encrypt mode (decrypt=0):  DES#1, DES#3 walk forward; DES#2 backward
            //   In decrypt mode (decrypt=1):  the opposite
            //   ⇒ walk_fwd = decrypt XNOR is_des2(s)
            localparam integer IS_D2 = (s >= 17 && s <= 32) ? 1 : 0;
            wire walk_fwd = ~(decrypt ^ IS_D2[0]);

            // Local round (1..16 within whichever DES we're in)
            wire [4:0] lr =
                (s <= 16) ? s[4:0] :
                (s <= 32) ? (s - 16) :
                            (s - 32);

            wire [4:0] level_w       = walk_fwd ? lr : (5'd18 - lr);
            wire       reverse_w     = ~walk_fwd;
            wire       apply_shift_w = walk_fwd ? 1'b1 : (lr != 5'd1);

            KS_step ks_st(
                .level(level_w),
                .apply_shift(apply_shift_w),
                .reverse(reverse_w),
                .C_in(C_in[s]), .D_in(D_in[s]),
                .C_out(C_next[s]), .D_out(D_next[s]),
                .k_round(rk[s])
            );

            f f_st(.R(R_in[s]), .K(rk[s]), .OUT(f_out[s]));
            assign L_next[s] = R_in[s];
            assign R_next[s] = L_in[s] ^ f_out[s];
        end
    endgenerate

    // -------------- Final IP_inv after stage 48 --------------
    wire [64:1] des3_post = {R_reg[48], L_reg[48]};
    wire [64:1] final_out;
    IP_inv ipiv_final(des3_post, final_out);

    // -------------- Sequential pipeline registers --------------
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 1; i <= 48; i = i + 1) begin
                L_reg[i] <= 32'b0;
                R_reg[i] <= 32'b0;
                C_reg[i] <= 28'b0;
                D_reg[i] <= 28'b0;
                v_reg[i] <= 1'b0;
            end
            out       <= 64'b0;
            valid_out <= 1'b0;
        end
        else begin
            // Stage 1 from inputs
            L_reg[1] <= L_next[1];
            R_reg[1] <= R_next[1];
            C_reg[1] <= C_next[1];
            D_reg[1] <= D_next[1];
            v_reg[1] <= valid_in;

            // Stages 2..48 advance
            for (i = 2; i <= 48; i = i + 1) begin
                L_reg[i] <= L_next[i];
                R_reg[i] <= R_next[i];
                C_reg[i] <= C_next[i];
                D_reg[i] <= D_next[i];
                v_reg[i] <= v_reg[i-1];
            end

            out       <= final_out;
            valid_out <= v_reg[48];
        end
    end

endmodule
