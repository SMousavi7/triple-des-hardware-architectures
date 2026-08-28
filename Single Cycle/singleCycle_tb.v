`timescale 1ns/1ps

module triple_des_top_module_tb;

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

triple_des_top_module #(.IN_WIDTH(320)) dut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .mode(mode),
    .data_in(data_in),
    .key(key),
    .iv(iv),
    .decrypt(decrypt),
    .data_out(data_out),
    .done(done)
);

always #5 clk = ~clk;

initial begin
clk = 0;
rst = 1;
start = 0;
decrypt = 0;
#30;
rst = 0;

/////////////////////////////////////////////////////////
$display("TEST VECTOR 1 - ECB");

mode = 0;
key = {64'hA4E9432CE07AD076 , 64'h572F7C1513DA495E};
iv  = 64'h0;

data_in = {
64'h12BB6F8DF45EF216,
64'hBA7BDE0C26FBA7DC,
64'hD1BF4B48A0F02854,
64'h9947E3E0C209EE51,
64'h0000000000000000
};

start = 1;
#200 start = 0;

wait(done);

if(data_out[319:64] ==
{
64'h307D644D19BEB557,
64'h59C0DC3E862B8238,
64'h7EB35CC8ECE07C78,
64'h0B8762E0708F1DF1
})
$display("TEST1 PASS");
else
$display("TEST1 FAIL");

#20;

/////////////////////////////////////////////////////////
$display("TEST VECTOR 2 - CBC");

mode = 1;
key = {64'hFDDF34345EEF082F , 64'hA42AAB494576EC94};
iv  = 64'h2B0A1D10B06D3A2C;

data_in = {
64'h81A239C31A855554,
64'h72558978F41CA01A,
64'h6D841401ED8661BB,
64'h3222EAA63D9E44A5,
64'h0000000000000000
};

start = 1;
#200 start = 0;

wait(done);

if(data_out[319:64] ==
{
64'h297AB4B44A9BC2FC,
64'hE63817B28BDDAFD3,
64'h34AC5E9E57AA9A51,
64'hF07839AFEB067989
})
$display("TEST2 PASS");
else
$display("TEST2 FAIL");

#20;

/////////////////////////////////////////////////////////
$display("TEST VECTOR 3 - OFB");

mode = 2;
key = {64'h79AD455EADF8B6D9 , 64'h20BADAD96110683D};
iv  = 64'h3D1EF94987749B72;

data_in = {
64'h8D166A08A65AA998,
64'h781AA16D615C9BA0,
64'h2F66D7EEB7001EAE,
64'h4D9CA6F1A93FAD05,
64'h0000000000000000
};

start = 1;
#200 start = 0;

wait(done);

if(data_out[319:64] ==
{
64'h54E4ABC45BA14D1D,
64'hE80E5F020DBF64CF,
64'h9EF1A890E81103AE,
64'hA54DBF8F287FFEBD
})
$display("TEST3 PASS");
else
$display("TEST3 FAIL");

#20;

/////////////////////////////////////////////////////////
$display("TEST VECTOR 4 - ECB (300bit)");

mode = 0;
key = {64'hA4E9432CE07AD076 , 64'h572F7C1513DA495E};
iv  = 0;

data_in = {
64'h12BB6F8DF45EF216,
64'hBA7BDE0C26FBA7DC,
64'hD1BF4B48A0F02854,
64'h9947E3E0C209EE51,
64'h000009A4EF286214
};

start = 1;
#200 start = 0;

wait(done);

if(data_out[319:64] ==
{
64'h307D644D19BEB557,
64'h59C0DC3E862B8238,
64'h7EB35CC8ECE07C78,
64'h0B8762E0708F1DF1
})
$display("TEST4 PASS");
else
$display("TEST4 FAIL");

#20;

/////////////////////////////////////////////////////////
$display("TEST VECTOR 5 - CBC (300bit)");

mode = 1;
key = {64'hFDDF34345EEF082F , 64'hA42AAB494576EC94};
iv  = 64'h2B0A1D10B06D3A2C;

data_in = {
64'h81A239C31A855554,
64'h72558978F41CA01A,
64'h6D841401ED8661BB,
64'h3222EAA63D9E44A5,
64'h000009A4EF286214
};

start = 1;
#200 start = 0;

wait(done);

if(data_out[319:64] ==
{
64'h297AB4B44A9BC2FC,
64'hE63817B28BDDAFD3,
64'h34AC5E9E57AA9A51,
64'hF07839AFEB067989
})
$display("TEST5 PASS");
else
$display("TEST5 FAIL");

#20;

/////////////////////////////////////////////////////////
$display("TEST VECTOR 6 - OFB (300bit)");

mode = 2;
key = {64'h79AD455EADF8B6D9 , 64'h20BADAD96110683D};
iv  = 64'h3D1EF94987749B72;

data_in = {
64'h8D166A08A65AA998,
64'h781AA16D615C9BA0,
64'h2F66D7EEB7001EAE,
64'h4D9CA6F1A93FAD05,
64'h000009A4EF286214
};

start = 1;
#200 start = 0;

wait(done);

if(data_out[319:64] ==
{
64'h54E4ABC45BA14D1D,
64'hE80E5F020DBF64CF,
64'h9EF1A890E81103AE,
64'hA54DBF8F287FFEBD
})
$display("TEST6 PASS");
else
$display("TEST6 FAIL");

#50;
$stop;

end

endmodule
