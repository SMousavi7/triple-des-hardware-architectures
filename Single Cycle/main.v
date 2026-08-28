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

module triple_des_top_module #(
    parameter IN_WIDTH    = 256,
    parameter BLOCK_COUNT = (IN_WIDTH + 63) / 64,    // ceil(IN_WIDTH/64)
    parameter OUT_WIDTH   = BLOCK_COUNT * 64
) (
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   start,
    input  wire [1:0]             mode,         // 00=ECB, 01=CBC, 10=OFB
    input  wire [IN_WIDTH-1:0]    data_in,
    input  wire [127:0]           key,
    input  wire [63:0]            iv,
    input  wire                   decrypt,
    output reg  [OUT_WIDTH-1:0]   data_out,
    output reg                    done,
    output wire                   busy
);

    // ===== Optional zero/one padding (only when OUT_WIDTH > IN_WIDTH) =====
    // For this assignment IN_WIDTH=320 → BLOCK_COUNT=5 → OUT_WIDTH=320,
    // so this combinational block is a pass-through.
    reg [OUT_WIDTH-1:0] padded_data;
    always @(*) begin
        padded_data = {OUT_WIDTH{1'b0}};
        padded_data[OUT_WIDTH-1 -: IN_WIDTH] = data_in;
        if (OUT_WIDTH > IN_WIDTH)
            padded_data[OUT_WIDTH-IN_WIDTH-1] = 1'b1;
    end

    // ===== FSM =====
    localparam S_IDLE = 3'd0;
    localparam S_LOAD = 3'd1;
    localparam S_EXEC = 3'd2;   // present input + issue 1-cycle start pulse
    localparam S_WAIT = 3'd3;   // wait until the core asserts done
    localparam S_SAVE = 3'd4;   // capture core output, update salt, advance
    localparam S_DONE = 3'd5;

    reg [2:0]               state;
    reg [$clog2(BLOCK_COUNT+1)-1:0] counter;
    reg [63:0]              triple_des_input;
    reg                     triple_des_start;
    reg [63:0]              selected_block;
    reg [63:0]              salt;

    wire [63:0] triple_des_output;
    wire        done_triple_des;

    assign busy = (state != S_IDLE);

    triple_des t1(
        .clk    (clk),
        .rst    (rst),
        .in     (triple_des_input),
        .key    (key),
        .decrypt(decrypt),
        .start  (triple_des_start),
        .out    (triple_des_output),
        .done   (done_triple_des)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state            <= S_IDLE;
            counter          <= 0;
            triple_des_input <= 64'b0;
            triple_des_start <= 1'b0;
            selected_block   <= 64'b0;
            salt             <= 64'b0;
            data_out         <= {OUT_WIDTH{1'b0}};
            done             <= 1'b0;
        end
        else begin
            // default: keep start pulse low
            triple_des_start <= 1'b0;

            case (state)
                // ------------------------------------------------
                S_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        salt     <= iv;
                        counter  <= 0;
                        data_out <= {OUT_WIDTH{1'b0}};
                        state    <= S_LOAD;
                    end
                end

                // ------------------------------------------------
                S_LOAD: begin
                    selected_block <= padded_data[(OUT_WIDTH - 1 - (counter * 64)) -: 64];
                    state          <= S_EXEC;
                end

                // ------------------------------------------------
                S_EXEC: begin
                    // Drive the core input based on the cipher mode.
                    case (mode)
                        2'b00: triple_des_input <= selected_block;                  // ECB
                        2'b01: triple_des_input <= decrypt ? selected_block
                                                           : selected_block ^ salt; // CBC
                        2'b10: triple_des_input <= salt;                            // OFB
                        default: triple_des_input <= selected_block;
                    endcase

                    triple_des_start <= 1'b1;     // one-cycle start pulse
                    state            <= S_WAIT;
                end

                // ------------------------------------------------
                S_WAIT: begin
                    // The core needs exactly 3 cycles after start;
                    // wait until done is asserted before consuming output.
                    if (done_triple_des)
                        state <= S_SAVE;
                end

                // ------------------------------------------------
                S_SAVE: begin
                    case (mode)
                        2'b00: begin // ECB
                            data_out[(OUT_WIDTH - (counter * 64)) - 1 -: 64] <= triple_des_output;
                        end
                        2'b01: begin // CBC
                            if (decrypt) begin
                                data_out[(OUT_WIDTH - (counter * 64)) - 1 -: 64] <= triple_des_output ^ salt;
                                salt <= selected_block;
                            end
                            else begin
                                data_out[(OUT_WIDTH - (counter * 64)) - 1 -: 64] <= triple_des_output;
                                salt <= triple_des_output;
                            end
                        end
                        2'b10: begin // OFB
                            data_out[(OUT_WIDTH - (counter * 64)) - 1 -: 64] <= triple_des_output ^ selected_block;
                            salt <= triple_des_output;
                        end
                        default: begin
                            data_out[(OUT_WIDTH - (counter * 64)) - 1 -: 64] <= triple_des_output;
                        end
                    endcase

                    if (counter == BLOCK_COUNT - 1)
                        state <= S_DONE;
                    else begin
                        counter <= counter + 1;
                        state   <= S_LOAD;
                    end
                end

                // ------------------------------------------------
                S_DONE: begin
                    done  <= 1'b1;
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
