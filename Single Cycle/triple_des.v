module triple_des(
    input             clk,
    input             rst,
    input      [63:0] in,
    input     [127:0] key,
    input             decrypt,
    input             start,   // one-cycle pulse to begin a new block
    output reg [63:0] out,
    output reg        done
    );

    // FSM states (single-cycle DES → 3 cycles total per block)
    localparam S_IDLE = 2'b00;
    localparam S_S1   = 2'b01;
    localparam S_S2   = 2'b10;
    localparam S_S3   = 2'b11;

    wire [63:0] key1 = key[127:64];
    wire [63:0] key2 = key[63:0];

    reg  [63:0] in_latched;
    reg  [63:0] d11;
    reg  [63:0] d22;
    wire [63:0] out1;
    wire [63:0] out2;
    wire [63:0] out3;
    reg  [1:0]  state;

    // 3-DES chain : E_K1 → D_K2 → E_K1   (or reverse when decrypt=1)
    DES d1(.in(in_latched), .key(key1), .decrypt(decrypt),  .out(out1));
    DES d2(.in(d11),        .key(key2), .decrypt(~decrypt), .out(out2));
    DES d3(.in(d22),        .key(key1), .decrypt(decrypt),  .out(out3));

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out        <= 64'b0;
            d11        <= 64'b0;
            d22        <= 64'b0;
            in_latched <= 64'b0;
            done       <= 1'b0;
            state      <= S_IDLE;
        end
        else begin
            case (state)
                S_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        in_latched <= in;       // latch the input only once
                        state      <= S_S1;
                    end
                end
                S_S1: begin
                    d11   <= out1;              // 1st DES result
                    state <= S_S2;
                end
                S_S2: begin
                    d22   <= out2;              // 2nd DES result
                    state <= S_S3;
                end
                S_S3: begin
                    out   <= out3;              // 3rd DES result
                    done  <= 1'b1;              // signal "block done"
                    state <= S_IDLE;            // wait for next start
                end
            endcase
        end
    end

endmodule
