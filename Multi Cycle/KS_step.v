// =============================================================================
//  Single-round key-schedule step
//  ------------------------------
//  Produces ONE round-key on every clock cycle, using ONLY a left/right
//  rotation of the current (C, D) halves – no precomputation of the entire
//  schedule.  This satisfies the assignment requirement that each round key
//  is derived at the same cycle the round is performed.
//
//  Encryption walk:                     Decryption walk:
//    start with (C_0, D_0)                start with (C_0, D_0) = (C_16, D_16)
//    round 1 : shift left by 1            round 1 : NO shift            → k_16
//    round 2 : shift left by 1            round 2 : shift right by 1    → k_15
//    round 3 : shift left by 2            round 3 : shift right by 2    → k_14
//      ... (per DES table)                  ... (table mirrored)
//    round 16: shift left by 1            round 16: shift right by 1    → k_1
//
//  Ports:
//      level        : the *shift-table index* (1..16).
//                     Encryption: level = round_idx.
//                     Decryption: level = 18 − round_idx (only used for rnd 2..16).
//      apply_shift  : 0 ⇒ keep (C,D) (decrypt round 1).
//      reverse      : 0 ⇒ rotate left, 1 ⇒ rotate right.
// =============================================================================
module KS_step(
    input      [4:0]  level,
    input             apply_shift,
    input             reverse,
    input      [28:1] C_in,
    input      [28:1] D_in,
    output     [28:1] C_out,
    output     [28:1] D_out,
    output     [48:1] k_round
);
    wire shift1 = (level == 5'd1  || level == 5'd2 ||
                   level == 5'd9  || level == 5'd16);

    // Left rotate
    wire [28:1] C_left  = shift1 ? {C_in[27:1], C_in[28]}     : {C_in[26:1], C_in[28:27]};
    wire [28:1] D_left  = shift1 ? {D_in[27:1], D_in[28]}     : {D_in[26:1], D_in[28:27]};

    // Right rotate
    wire [28:1] C_right = shift1 ? {C_in[1],    C_in[28:2]}   : {C_in[2:1],  C_in[28:3]};
    wire [28:1] D_right = shift1 ? {D_in[1],    D_in[28:2]}   : {D_in[2:1],  D_in[28:3]};

    assign C_out = ~apply_shift ? C_in    :
                    reverse     ? C_right : C_left;
    assign D_out = ~apply_shift ? D_in    :
                    reverse     ? D_right : D_left;

    PC2 pc2_inst({C_out, D_out}, k_round);
endmodule
