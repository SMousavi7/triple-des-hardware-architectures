
// =============================================================================
//  Pipelined Top Module  (ECB only)
//  --------------------------------
//  Streams the N blocks of the padded input into a 48-stage Triple-DES
//  pipeline, one block per clock.  Collects N blocks of output starting
//  48 cycles later.  Total latency for N blocks  =  48 + (N − 1)  cycles.
//
//  The `mode` and `iv` inputs are kept for interface compatibility with the
//  other implementations, but only `mode == 2'b00` (ECB) is supported – per
//  the assignment clarification.
// =============================================================================
module triple_des_top_module #(
    parameter IN_WIDTH    = 256,
    parameter BLOCK_COUNT = (IN_WIDTH + 63) / 64,
    parameter OUT_WIDTH   = BLOCK_COUNT * 64
) (
    input  wire                 clk,
    input  wire                 rst,
    input  wire                 start,
    input  wire [1:0]           mode,        // ignored – ECB only
    input  wire [IN_WIDTH-1:0]  data_in,
    input  wire [127:0]         key,
    input  wire [63:0]          iv,          // ignored – ECB only
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
    localparam S_IDLE = 2'd0;
    localparam S_FEED = 2'd1;     // injecting blocks (and possibly draining)
    localparam S_DRAIN= 2'd2;     // injection finished, still draining output
    localparam S_DONE = 2'd3;

    reg [1:0]                       state;
    reg [$clog2(BLOCK_COUNT+1)-1:0] in_idx;     // number of blocks injected
    reg [$clog2(BLOCK_COUNT+1)-1:0] out_idx;    // number of blocks collected

    reg  [63:0] block_in;
    reg         valid_in;
    wire [63:0] block_out;
    wire        valid_out;

    assign busy = (state != S_IDLE);

    triple_des_pipe pipe(
        .clk(clk), .rst(rst),
        .valid_in(valid_in), .in(block_in),
        .key(key), .decrypt(decrypt),
        .out(block_out), .valid_out(valid_out)
    );

    // ---- Combinational select of the current input block ----
    reg [63:0] next_block;
    integer    bi;
    always @(*) begin
        next_block = 64'b0;
        for (bi = 0; bi < BLOCK_COUNT; bi = bi + 1) begin
            if (bi == in_idx)
                next_block = padded_data[(OUT_WIDTH - 1 - (bi*64)) -: 64];
        end
    end

    // ---- Main sequential logic ----
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state    <= S_IDLE;
            in_idx   <= 0;
            out_idx  <= 0;
            valid_in <= 1'b0;
            block_in <= 64'b0;
            data_out <= {OUT_WIDTH{1'b0}};
            done     <= 1'b0;
        end
        else begin
            valid_in <= 1'b0;   // default

            case (state)
                S_IDLE: begin
                    done    <= 1'b0;
                    in_idx  <= 0;
                    out_idx <= 0;
                    if (start) begin
                        // First block goes in on the next cycle
                        data_out <= {OUT_WIDTH{1'b0}};
                        state    <= S_FEED;
                    end
                end

                S_FEED: begin
                    // Inject a block this cycle if any remain
                    if (in_idx < BLOCK_COUNT) begin
                        block_in <= next_block;
                        valid_in <= 1'b1;
                        in_idx   <= in_idx + 1;
                    end

                    // Collect a block this cycle if pipeline has one
                    if (valid_out) begin
                        data_out[(OUT_WIDTH - (out_idx*64)) - 1 -: 64] <= block_out;
                        out_idx <= out_idx + 1;
                        if (out_idx == BLOCK_COUNT - 1)
                            state <= S_DONE;
                    end

                    // If we injected the last block, transition to DRAIN next
                    if (in_idx == BLOCK_COUNT - 1)
                        state <= S_DRAIN;
                end

                S_DRAIN: begin
                    // No more injections; just keep collecting outputs.
                    if (valid_out) begin
                        data_out[(OUT_WIDTH - (out_idx*64)) - 1 -: 64] <= block_out;
                        out_idx <= out_idx + 1;
                        if (out_idx == BLOCK_COUNT - 1)
                            state <= S_DONE;
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
