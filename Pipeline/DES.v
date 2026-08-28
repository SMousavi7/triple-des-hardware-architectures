// =============================================================================
//  Multi-Cycle DES  (one Feistel round per clock cycle)
//  -----------------------------------------------------
//  The key schedule is computed ONE STEP AT A TIME, in lock-step with the
//  Feistel rounds.  At every clock we only do:
//      * one left- (or right-) rotation of the (C, D) halves
//      * one PC2 → round-key
//      * one Feistel round
//  No round key is precomputed.
// =============================================================================
module DES_MC(
    input             clk,
    input             rst,
    input             start,         // 1-cycle pulse: latch input + begin
    input      [64:1] in,
    input      [64:1] key,
    input             decrypt,
    output reg [64:1] out,
    output reg        done
);

    // ---------- PC1: combinational, derives (C_0, D_0) from key ----------
    wire [56:1] key_pc1;
    PC1 pc1_inst(key, key_pc1);
    wire [28:1] C0 = key_pc1[56:29];
    wire [28:1] D0 = key_pc1[28:1];

    // ---------- Key-schedule register ----------
    reg [28:1] C_reg, D_reg;

    // ---------- Round counter and Feistel halves ----------
    reg [4:0]  round;     // 0 = idle; 1..16 = round being performed
    reg [32:1] L_reg, R_reg;

    // ---------- KS_step inputs ----------
    // Encryption walk : level = round, reverse=0, apply_shift=1 always
    // Decryption walk : round 1 → no shift  (level/reverse don't matter, just gate it)
    //                   round i>1 → level = 18 − round, reverse=1, apply_shift=1
    wire [4:0] level_w       = decrypt ? (5'd18 - round) : round;
    wire       reverse_w     = decrypt;
    wire       apply_shift_w = decrypt ? (round != 5'd1) : 1'b1;

    wire [28:1] C_next, D_next;
    wire [48:1] round_key;
    KS_step ks_step(
        .level(level_w), .apply_shift(apply_shift_w), .reverse(reverse_w),
        .C_in(C_reg), .D_in(D_reg),
        .C_out(C_next), .D_out(D_next),
        .k_round(round_key)
    );

    // ---------- Feistel f() ----------
    wire [32:1] f_out;
    f f_inst(.R(R_reg), .K(round_key), .OUT(f_out));
    wire [32:1] L_next = R_reg;
    wire [32:1] R_next = L_reg ^ f_out;

    // ---------- IP and IP_inv ----------
    wire [64:1] in_ip;
    IP ip_inst(in, in_ip);
    wire [64:1] pre_inv = {R_next, L_next};
    wire [64:1] out_final;
    IP_inv ip_inv_inst(pre_inv, out_final);

    // ---------- FSM ----------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            round <= 0;
            L_reg <= 0;
            R_reg <= 0;
            C_reg <= 0;
            D_reg <= 0;
            out   <= 0;
            done  <= 0;
        end
        else begin
            done <= 0;

            if (round == 0) begin
                if (start) begin
                    {L_reg, R_reg} <= in_ip;     // post-IP halves
                    C_reg          <= C0;        // start key walk from (C_0, D_0)
                    D_reg          <= D0;
                    round          <= 1;
                end
            end
            else if (round == 16) begin
                out   <= out_final;
                done  <= 1'b1;
                round <= 0;
            end
            else begin
                L_reg <= L_next;
                R_reg <= R_next;
                C_reg <= C_next;
                D_reg <= D_next;
                round <= round + 1;
            end
        end
    end

endmodule
