// `define ASSERT(expr) begin if (!(expr)) begin $display("FAIL"); end end

// module triple_des_top_module_tb;
//   reg[127:0]key ;
//   reg[255:0]plain_text ;
//   reg[1:0] mode;
//   reg[63:0] iv;
//   wire[255:0] out;

//   triple_des_top_module sadra(.mode(mode), .data_in(plain_text), .iv(iv), .key(key), .decrypt(1'b0), .data_out(out));

//   initial begin
//     //Test Vector 1 (ECB)
//     mode = 2'b00;
//     key = 128'hA4E9432CE07AD076572F7C1513DA495E;
//     iv = 64'd0;
//     plain_text = 256'h12BB6F8DF45EF216BA7BDE0C26FBA7DCD1BF4B48A0F028549947E3E0C209EE51;
//     #5
//     `ASSERT(out == 256'h307D644D19BEB55759C0DC3E862B82387EB35CC8ECE07C780B8762E0708F1DF1)
//     #5
//     //Test Vector 2 (CBC)
//     mode = 2'b01;
//     key = 128'hFDDF34345EEF082FA42AAB494576EC94;
//     iv = 64'h2B0A1D10B06D3A2C;
//     plain_text = 256'h81A239C31A85555472558978F41CA01A6D841401ED8661BB3222EAA63D9E44A5;
//     #5
//     `ASSERT(out == 256'h297AB4B44A9BC2FCE63817B28BDDAFD334AC5E9E57AA9A51F07839AFEB067989)
//     #5
//     //Test Vector 3 (OFB)
//     mode = 2'b10;
//     key = 128'h79AD455EADF8B6D920BADAD96110683D;
//     iv = 64'h3D1EF94987749B72;
//     plain_text = 256'h8D166A08A65AA998781AA16D615C9BA02F66D7EEB7001EAE4D9CA6F1A93FAD05;
//     #5
//     `ASSERT(out == 256'h54E4ABC45BA14D1DE80E5F020DBF64CF9EF1A890E81103AEA54DBF8F287FFEBD)
//   end
  
// endmodule