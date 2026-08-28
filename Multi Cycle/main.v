
// =============================================================================
//  Multi-Cycle Top
//  ---------------
//  Same FSM/handshake as the single-cycle version, but the cryptographic core
//  is `triple_des_MC` (48 cycles/block).  Total = 48 × Number_of_Blocks cycles.
//  Supports ECB / CBC / OFB.
// =============================================================================
module triple_des_top_module #(
    parameter IN_WIDTH    = 256,
    parameter BLOCK_COUNT = (IN_WIDTH + 63) / 64,
    parameter OUT_WIDTH   = BLOCK_COUNT * 64
) (
    input  wire                 clk,
    input  wire                 rst,
    input  wire                 start,
    input  wire [1:0]           mode,
    input  wire [IN_WIDTH-1:0]  data_in,
    input  wire [127:0]         key,
    input  wire [63:0]          iv,
    input  wire                 decrypt,
    output reg  [OUT_WIDTH-1:0] data_out,
    output reg                  done,
    output wire                 busy
);

    // ---- padding (no-op when OUT_WIDTH == IN_WIDTH) ----
    reg [OUT_WIDTH-1:0] padded_data;
    always @(*) begin
        padded_data = {OUT_WIDTH{1'b0}};
        padded_data[OUT_WIDTH-1 -: IN_WIDTH] = data_in;
        if (OUT_WIDTH > IN_WIDTH)
            padded_data[OUT_WIDTH-IN_WIDTH-1] = 1'b1;
    end

    // ---- FSM ----
    localparam S_IDLE = 3'd0;
    localparam S_LOAD = 3'd1;
    localparam S_EXEC = 3'd2;
    localparam S_WAIT = 3'd3;
    localparam S_SAVE = 3'd4;
    localparam S_DONE = 3'd5;

    reg [2:0]                       state;
    reg [$clog2(BLOCK_COUNT+1)-1:0] counter;
    reg [63:0]                      core_in;
    reg                             core_start;
    reg [63:0]                      selected_block;
    reg [63:0]                      salt;

    wire [63:0] core_out;
    wire        core_done;

    assign busy = (state != S_IDLE);

    triple_des_MC core(
        .clk(clk), .rst(rst), .start(core_start),
        .in(core_in), .key(key), .decrypt(decrypt),
        .out(core_out), .done(core_done)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state          <= S_IDLE;
            counter        <= 0;
            core_in        <= 64'b0;
            core_start     <= 1'b0;
            selected_block <= 64'b0;
            salt           <= 64'b0;
            data_out       <= {OUT_WIDTH{1'b0}};
            done           <= 1'b0;
        end
        else begin
            core_start <= 1'b0;

            case (state)
                S_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        salt     <= iv;
                        counter  <= 0;
                        data_out <= {OUT_WIDTH{1'b0}};
                        state    <= S_LOAD;
                    end
                end

                S_LOAD: begin
                    selected_block <= padded_data[(OUT_WIDTH - 1 - (counter*64)) -: 64];
                    state          <= S_EXEC;
                end

                S_EXEC: begin
                    case (mode)
                        2'b00: core_in <= selected_block;
                        2'b01: core_in <= decrypt ? selected_block: selected_block ^ salt;
                        2'b10: core_in <= salt;
                        default: core_in <= selected_block;
                    endcase
                    core_start <= 1'b1;
                    state      <= S_WAIT;
                end

                S_WAIT: begin
                    if (core_done)
                        state <= S_SAVE;
                end

                S_SAVE: begin
                    case (mode)
                        2'b00: begin
                            data_out[(OUT_WIDTH - (counter*64)) - 1 -: 64] <= core_out;
                        end
                        2'b01: begin
                            if (decrypt) begin
                                data_out[(OUT_WIDTH - (counter*64)) - 1 -: 64] <= core_out ^ salt;
                                salt <= selected_block;
                            end
                            else begin
                                data_out[(OUT_WIDTH - (counter*64)) - 1 -: 64] <= core_out;
                                salt <= core_out;
                            end
                        end
                        2'b10: begin
                            data_out[(OUT_WIDTH - (counter*64)) - 1 -: 64] <= core_out ^ selected_block;
                            salt <= core_out;
                        end
                        default: begin
                            data_out[(OUT_WIDTH - (counter*64)) - 1 -: 64] <= core_out;
                        end
                    endcase

                    if (counter == BLOCK_COUNT - 1)
                        state <= S_DONE;
                    else begin
                        counter <= counter + 1;
                        state   <= S_LOAD;
                    end
                end

                S_DONE: begin
                    done  <= 1'b1;
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
