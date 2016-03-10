// ============================================================================
//        __
//   \\__/ o\    (C) 2013-2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//
//
// Thor SuperScalar
//
// ============================================================================
//
module Thor_icachemem(wclk, wce, wr, wa, wd, rclk, pc, insn);
parameter DBW=64;
parameter ABW=32;
parameter ECC=1'b0;
input wclk;
input wce;
input wr;
input [ABW-1:0] wa;
input [(ECC?((DBW==64)?DBW+13:DBW+6):DBW-1):0] wd;
input rclk;
input [ABW-1:0] pc;
output reg [127:0] insn;

wire [127:0] insn0;
wire [127:0] insn1;
wire [(ECC?155:127):0] insn0a;
wire [(ECC?155:127):0] insn1a;

generate
begin : cache_mem
if (DBW==32) begin
if (ECC) begin
/*
blk_mem_gen_2 uicm1 (
  .clka(wclk),    // input wire clka
  .ena(wce),      // input wire ena
  .wea(wr),      // input wire [0 : 0] wea
  .addra(wa[14:2]),  // input wire [14 : 0] addra
  .dina(wd),    // input wire [31 : 0] dina
  .clkb(rclk),    // input wire clkb
  .enb(1'b1),
  .addrb(pc[14:4]),  // input wire [12 : 0] addrb
  .doutb(insn0a)  // output wire [127 : 0] doutb
);

blk_mem_gen_2 uicm2 (
  .clka(wclk),    // input wire clka
  .ena(wce),      // input wire ena
  .wea(wr),      // input wire [0 : 0] wea
  .addra(wa[14:2]),  // input wire [14 : 0] addra
  .dina(wd),    // input wire [31 : 0] dina
  .clkb(rclk),    // input wire clkb
  .enb(1'b1),
  .addrb(pc[14:4]+11'd1),  // input wire [12 : 0] addrb
  .doutb(insn1a)  // output wire [127 : 0] doutb
);
*/
end
else begin
icache_ram uicm1 (
    .wclk(wclk),
    .wce(wce),
    .wr(wr),
    .wa(wa[14:2]),
    .d(wd[31:0]),
    .rclk(rclk),
    .rce(1'b1),
    .ra(pc[14:4]),
    .q(insn0a)
);

icache_ram uicm2 (
    .wclk(wclk),
    .wce(wce),
    .wr(wr),
    .wa(wa[14:2]),
    .d(wd[31:0]),
    .rclk(rclk),
    .rce(1'b1),
    .ra(pc[14:4]+11'd1),
    .q(insn1a)
);
/*
blk_mem_gen_0 uicm1 (
  .clka(wclk),    // input wire clka
  .ena(wce),      // input wire ena
  .wea(wr),      // input wire [0 : 0] wea
  .addra(wa[14:2]),  // input wire [14 : 0] addra
  .dina(wd[31:0]),    // input wire [31 : 0] dina
  .clkb(rclk),    // input wire clkb
  .enb(1'b1),
  .addrb(pc[14:4]),  // input wire [12 : 0] addrb
  .doutb(insn0a)  // output wire [127 : 0] doutb
);

blk_mem_gen_0 uicm2 (
  .clka(wclk),    // input wire clka
  .ena(wce),      // input wire ena
  .wea(wr),      // input wire [0 : 0] wea
  .addra(wa[14:2]),  // input wire [14 : 0] addra
  .dina(wd[31:0]),    // input wire [31 : 0] dina
  .clkb(rclk),    // input wire clkb
  .enb(1'b1),
  .addrb(pc[14:4]+11'd1),  // input wire [12 : 0] addrb
  .doutb(insn1a)  // output wire [127 : 0] doutb
);
*/
end

end
else begin
if (ECC) begin
/*
blk_mem_gen_3 uicm1 (
  .clka(wclk),    // input wire clka
  .ena(wce),      // input wire ena
  .wea(wr),      // input wire [0 : 0] wea
  .addra(wa[14:3]),  // input wire [14 : 0] addra
  .dina(wd),    // input wire [31 : 0] dina
  .clkb(rclk),    // input wire clkb
  .enb(1'b1),
  .addrb(pc[14:4]),  // input wire [12 : 0] addrb
  .doutb(insn0a)  // output wire [127 : 0] doutb
);

blk_mem_gen_3 uicm2 (
  .clka(wclk),    // input wire clka
  .ena(wce),      // input wire ena
  .wea(wr),      // input wire [0 : 0] wea
  .addra(wa[14:3]),  // input wire [14 : 0] addra
  .dina(wd),    // input wire [31 : 0] dina
  .clkb(rclk),    // input wire clkb
  .enb(1'b1),
  .addrb(pc[14:4]+11'd1),  // input wire [12 : 0] addrb
  .doutb(insn1a)  // output wire [127 : 0] doutb
);
*/
end
else begin
/*
blk_mem_gen_1 uicm1 (
  .clka(wclk),    // input wire clka
  .ena(wce),      // input wire ena
  .wea(wr),      // input wire [0 : 0] wea
  .addra(wa[14:3]),  // input wire [14 : 0] addra
  .dina(wd[63:0]),    // input wire [31 : 0] dina
  .clkb(rclk),    // input wire clkb
  .enb(1'b1),
  .addrb(pc[14:4]),  // input wire [12 : 0] addrb
  .doutb(insn0a)  // output wire [127 : 0] doutb
);

blk_mem_gen_1 uicm2 (
  .clka(wclk),    // input wire clka
  .ena(wce),      // input wire ena
  .wea(wr),      // input wire [0 : 0] wea
  .addra(wa[14:3]),  // input wire [14 : 0] addra
  .dina(wd[63:0]),    // input wire [31 : 0] dina
  .clkb(rclk),    // input wire clkb
  .enb(1'b1),
  .addrb(pc[14:4]+11'd1),  // input wire [12 : 0] addrb
  .doutb(insn1a)  // output wire [127 : 0] doutb
);
*/
end
end

end
endgenerate

generate
begin : ECCx
if (ECC) begin
/*
ecc_0 uecc1a (
  .ecc_correct_n(1'b0),    // input wire ecc_correct_n
  .ecc_data_in(insn0a[31:0]),        // input wire [31 : 0] ecc_data_in
  .ecc_data_out(insn0[31:0]),      // output wire [31 : 0] ecc_data_out
  .ecc_chkbits_in({insn0a[37:32],insn0a[38]}),  // input wire [6 : 0] ecc_chkbits_in
  .ecc_sbit_err(),      // output wire ecc_sbit_err
  .ecc_dbit_err()      // output wire ecc_dbit_err
);
ecc_0 uecc1b (
  .ecc_correct_n(1'b0),    // input wire ecc_correct_n
  .ecc_data_in(insn0a[70:39]),        // input wire [31 : 0] ecc_data_in
  .ecc_data_out(insn0[63:32]),      // output wire [31 : 0] ecc_data_out
  .ecc_chkbits_in({insn0a[76:71],insn0a[77]}),  // input wire [6 : 0] ecc_chkbits_in
  .ecc_sbit_err(),      // output wire ecc_sbit_err
  .ecc_dbit_err()      // output wire ecc_dbit_err
);
ecc_0 uecc1c (
  .ecc_correct_n(1'b0),    // input wire ecc_correct_n
  .ecc_data_in(insn0a[109:78]),        // input wire [31 : 0] ecc_data_in
  .ecc_data_out(insn0[95:64]),      // output wire [31 : 0] ecc_data_out
  .ecc_chkbits_in({insn0a[115:110],insn0a[116]}),  // input wire [6 : 0] ecc_chkbits_in
  .ecc_sbit_err(),      // output wire ecc_sbit_err
  .ecc_dbit_err()      // output wire ecc_dbit_err
);
ecc_0 uecc1d (
  .ecc_correct_n(1'b0),    // input wire ecc_correct_n
  .ecc_data_in(insn0a[148:117]),        // input wire [31 : 0] ecc_data_in
  .ecc_data_out(insn0[127:96]),      // output wire [31 : 0] ecc_data_out
  .ecc_chkbits_in({insn0a[154:149],insn0a[155]}),  // input wire [6 : 0] ecc_chkbits_in
  .ecc_sbit_err(),      // output wire ecc_sbit_err
  .ecc_dbit_err()      // output wire ecc_dbit_err
);
ecc_0 uecc2a (
  .ecc_correct_n(1'b0),    // input wire ecc_correct_n
  .ecc_data_in(insn1a[31:0]),        // input wire [31 : 0] ecc_data_in
  .ecc_data_out(insn1[31:0]),      // output wire [31 : 0] ecc_data_out
  .ecc_chkbits_in({insn1a[37:32],insn1a[38]}),  // input wire [6 : 0] ecc_chkbits_in
  .ecc_sbit_err(),      // output wire ecc_sbit_err
  .ecc_dbit_err()      // output wire ecc_dbit_err
);
ecc_0 uecc2b (
  .ecc_correct_n(1'b0),    // input wire ecc_correct_n
  .ecc_data_in(insn1a[70:39]),        // input wire [31 : 0] ecc_data_in
  .ecc_data_out(insn1[63:32]),      // output wire [31 : 0] ecc_data_out
  .ecc_chkbits_in({insn1a[76:71],insn1a[77]}),  // input wire [6 : 0] ecc_chkbits_in
  .ecc_sbit_err(),      // output wire ecc_sbit_err
  .ecc_dbit_err()      // output wire ecc_dbit_err
);
ecc_0 uecc2c (
  .ecc_correct_n(1'b0),    // input wire ecc_correct_n
  .ecc_data_in(insn1a[109:78]),        // input wire [31 : 0] ecc_data_in
  .ecc_data_out(insn1[95:64]),      // output wire [31 : 0] ecc_data_out
  .ecc_chkbits_in({insn1a[115:110],insn1a[116]}),  // input wire [6 : 0] ecc_chkbits_in
  .ecc_sbit_err(),      // output wire ecc_sbit_err
  .ecc_dbit_err()      // output wire ecc_dbit_err
);
ecc_0 uecc2d (
  .ecc_correct_n(1'b0),    // input wire ecc_correct_n
  .ecc_data_in(insn1a[148:117]),        // input wire [31 : 0] ecc_data_in
  .ecc_data_out(insn1[127:96]),      // output wire [31 : 0] ecc_data_out
  .ecc_chkbits_in({insn1a[154:149],insn1a[155]}),  // input wire [6 : 0] ecc_chkbits_in
  .ecc_sbit_err(),      // output wire ecc_sbit_err
  .ecc_dbit_err()      // output wire ecc_dbit_err
);
*/
end
else begin
assign insn0 = insn0a;//{insn0a[148:117],insn0a[109:78],insn0a[70:39],insn0a[31:0]};
assign insn1 = insn1a;//{insn1a[148:117],insn1a[109:78],insn1a[70:39],insn1a[31:0]};
end
end
endgenerate

always @(pc or insn0 or insn1)
case(pc[3:0])
4'd0:	insn <= insn0;
4'd1:	insn <= {insn1[7:0],insn0[127:8]};
4'd2:	insn <= {insn1[15:0],insn0[127:16]};
4'd3:	insn <= {insn1[23:0],insn0[127:24]};
4'd4:	insn <= {insn1[31:0],insn0[127:32]};
4'd5:	insn <= {insn1[39:0],insn0[127:40]};
4'd6:	insn <= {insn1[47:0],insn0[127:48]};
4'd7:	insn <= {insn1[55:0],insn0[127:56]};
4'd8:	insn <= {insn1[63:0],insn0[127:64]};
4'd9:	insn <= {insn1[71:0],insn0[127:72]};
4'd10:	insn <= {insn1[79:0],insn0[127:80]};
4'd11:	insn <= {insn1[87:0],insn0[127:88]};
4'd12:	insn <= {insn1[95:0],insn0[127:96]};
4'd13:	insn <= {insn1[103:0],insn0[127:104]};
4'd14:	insn <= {insn1[111:0],insn0[127:112]};
4'd15:	insn <= {insn1[119:0],insn0[127:120]};
endcase

endmodule
