// =============================================================================
//  Multi-Cycle Triple-DES   (3 × 16 = 48 cycles per block)
//  -------------------------------------------------------
//  Re-uses ONE DES_MC core.  The three DES rounds are executed back-to-back:
//      Phase 1:  DES(K1,  decrypt    )   ← 16 cycles
//      Phase 2:  DES(K2, ~decrypt    )   ← 16 cycles
//      Phase 3:  DES(K1,  decrypt    )   ← 16 cycles
//
//      start ─┐_______________________________________________________
//      done  ───────────────────────────────────────────────────────┐_│
//             ←—— 48 cycles ——————————————————————————————————→
// =============================================================================
module triple_des_MC(
    input             clk,
    input             rst,
    input             start,            // 1-cycle pulse
    input      [63:0] in,
    input     [127:0] key,
    input             decrypt,
    output reg [63:0] out,
    output reg        done
);

    localparam P_IDLE = 2'd0;
    localparam P_1    = 2'd1;          // running DES #1
    localparam P_2    = 2'd2;          // running DES #2
    localparam P_3    = 2'd3;          // running DES #3

    reg [1:0]  phase;
    reg [63:0] in_latched;
    reg [63:0] inter;                  // intermediate value between phases

    // Inputs to the shared core
    reg         core_start;
    reg  [63:0] core_in;
    reg  [63:0] core_key;
    reg         core_decrypt;
    wire [63:0] core_out;
    wire        core_done;

    wire [63:0] key1 = key[127:64];
    wire [63:0] key2 = key[63:0];

    DES_MC core(
        .clk(clk), .rst(rst), .start(core_start),
        .in(core_in), .key(core_key), .decrypt(core_decrypt),
        .out(core_out), .done(core_done)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            phase        <= P_IDLE;
            in_latched   <= 0;
            inter        <= 0;
            out          <= 0;
            done         <= 0;
            core_start   <= 0;
            core_in      <= 0;
            core_key     <= 0;
            core_decrypt <= 0;
        end
        else begin
            core_start <= 0;          // default: no start
            done       <= 0;

            case (phase)
                // -------------------------------------------------------------
                P_IDLE: begin
                    if (start) begin
                        in_latched   <= in;
                        // launch DES #1
                        core_in      <= in;
                        core_key     <= key1;
                        core_decrypt <= decrypt;
                        core_start   <= 1'b1;
                        phase        <= P_1;
                    end
                end
                // -------------------------------------------------------------
                P_1: begin
                    if (core_done) begin
                        inter        <= core_out;
                        // launch DES #2
                        core_in      <= core_out;
                        core_key     <= key2;
                        core_decrypt <= ~decrypt;
                        core_start   <= 1'b1;
                        phase        <= P_2;
                    end
                end
                // -------------------------------------------------------------
                P_2: begin
                    if (core_done) begin
                        inter        <= core_out;
                        // launch DES #3
                        core_in      <= core_out;
                        core_key     <= key1;
                        core_decrypt <= decrypt;
                        core_start   <= 1'b1;
                        phase        <= P_3;
                    end
                end
                // -------------------------------------------------------------
                P_3: begin
                    if (core_done) begin
                        out   <= core_out;
                        done  <= 1'b1;
                        phase <= P_IDLE;
                    end
                end
            endcase
        end
    end

endmodule
