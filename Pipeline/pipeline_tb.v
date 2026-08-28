`timescale 1ns/1ps

module pipeline_tb;

    reg clk;
    reg rst;
    reg start;
    reg [1:0] mode;
    reg [319:0] data_in;
    reg [127:0] key;
    reg [63:0] iv;
    reg decrypt;

    wire [319:0] data_out;
    wire done;
    wire busy;

    triple_des_top_module #(.IN_WIDTH(320)) dut (
        .clk(clk), .rst(rst), .start(start), .mode(mode),
        .data_in(data_in), .key(key), .iv(iv), .decrypt(decrypt),
        .data_out(data_out), .done(done), .busy(busy)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1; start = 0; decrypt = 0; iv = 0;
        #30 rst = 0;

        // ============== TEST 1: ECB, 256-bit ==============
        $display("TEST VECTOR 1 - ECB (pipeline)");
        mode = 0;
        key = {64'hA4E9432CE07AD076, 64'h572F7C1513DA495E};
        data_in = {64'h12BB6F8DF45EF216,
                   64'hBA7BDE0C26FBA7DC,
                   64'hD1BF4B48A0F02854,
                   64'h9947E3E0C209EE51,
                   64'h0000000000000000};
        @(posedge clk); start = 1; @(posedge clk); start = 0;
        wait(done);
        if (data_out[319:64] == {64'h307D644D19BEB557,
                                 64'h59C0DC3E862B8238,
                                 64'h7EB35CC8ECE07C78,
                                 64'h0B8762E0708F1DF1})
            $display("TEST1 PASS");
        else begin
            $display("TEST1 FAIL");
            $display("  got = %h %h %h %h",
                data_out[319:256], data_out[255:192],
                data_out[191:128], data_out[127:64]);
        end

        #20;

        // ============== TEST 4: ECB, 300-bit (padded) ==============
        $display("TEST VECTOR 4 - ECB 300bit (pipeline)");
        mode = 0;
        key = {64'hA4E9432CE07AD076, 64'h572F7C1513DA495E};
        data_in = {64'h12BB6F8DF45EF216,
                   64'hBA7BDE0C26FBA7DC,
                   64'hD1BF4B48A0F02854,
                   64'h9947E3E0C209EE51,
                   64'h000009A4EF286214};
        @(posedge clk); start = 1; @(posedge clk); start = 0;
        wait(done);
        if (data_out[319:64] == {64'h307D644D19BEB557,
                                 64'h59C0DC3E862B8238,
                                 64'h7EB35CC8ECE07C78,
                                 64'h0B8762E0708F1DF1})
            $display("TEST4 PASS");
        else begin
            $display("TEST4 FAIL");
            $display("  got = %h %h %h %h",
                data_out[319:256], data_out[255:192],
                data_out[191:128], data_out[127:64]);
        end

        #50 $finish;
    end

endmodule
