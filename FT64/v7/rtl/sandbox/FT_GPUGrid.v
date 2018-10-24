// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//
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
// ============================================================================
//
module FT_GPUGrid(rst_i, 
	cmd_clk_i, cmd_core_i, wr_cmd_i, cmd_adr_i, cmd_dat_i, cmd_count_o,
	imem_wr_i, imem_adr_i, imem_dat_i,
	cyc_o, stb_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o,
	dot_clk_i, blank_i, vctr_i, hctr_i, fctr_i, zrgb_o);
input rst_i;
input cmd_clk_i;
input [14:0] cmd_core_i;
input wr_cmd_i;
input [31:0] cmd_dat_i;
input [7:0] cmd_adr_i;
output [6:0] cmd_count_o;
input imem_wr_i;
input [13:0] imem_adr_i;
input [31:0] imem_dat_i;
output cyc_o;
output stb_o;
input ack_i;
output we_o;
output [3:0] sel_o;
output [31:0] adr_o;
input [31:0] dat_i;
output [31:0] dat_o;
input dot_clk_i;
input blank_i;
input [11:0] vctr_i;
input [11:0] hctr_i;
input [5:0] fctr_i;
output reg [31:0] zrgb_o;

wire [11:0] vctr = vctr_i;
wire [11:0] hctr = hctr_i;

reg [15:0] scan_adr [0:11];
reg [15:0] scan_out;
wire [15:0] scan_out00;
wire [15:0] scan_out01;
wire [15:0] scan_out02;
wire [15:0] scan_out03;
wire [15:0] scan_out10;
wire [15:0] scan_out11;
wire [15:0] scan_out12;
wire [15:0] scan_out13;
wire [15:0] scan_out20;
wire [15:0] scan_out21;
wire [15:0] scan_out22;
wire [15:0] scan_out23;
reg [11:0] hoffs = 12'hF32;
reg [11:0] voffs = 12'hFDA;

always @(posedge dot_clk_i)
begin
	scan_adr[0] <= {(vctr[11:1]-8'd000 + voffs[11:1]),7'd0} + (hctr[11:1]-11'd000 + hoffs[11:1]);
	scan_adr[1] <= {(vctr[11:1]-8'd000 + voffs[11:1]),7'd0} + (hctr[11:1]-11'd128 + hoffs[11:1]);
	scan_adr[2] <= {(vctr[11:1]-8'd000 + voffs[11:1]),7'd0} + (hctr[11:1]-11'd256 + hoffs[11:1]);
	scan_adr[3] <= {(vctr[11:1]-8'd000 + voffs[11:1]),7'd0} + (hctr[11:1]-11'd384 + hoffs[11:1]);
	scan_adr[4] <= {(vctr[11:1]-8'd160 + voffs[11:1]),7'd0} + (hctr[11:1]-11'd000 + hoffs[11:1]);
	scan_adr[5] <= {(vctr[11:1]-8'd160 + voffs[11:1]),7'd0} + (hctr[11:1]-11'd128 + hoffs[11:1]);
	scan_adr[6] <= {(vctr[11:1]-8'd160 + voffs[11:1]),7'd0} + (hctr[11:1]-11'd256 + hoffs[11:1]);
	scan_adr[7] <= {(vctr[11:1]-8'd160 + voffs[11:1]),7'd0} + (hctr[11:1]-11'd384 + hoffs[11:1]);
	/*
	scan_adr[8] <= (vctr[11:1]-8'd200) * 8'd100 + (hctr[11:1]-11'd000);
	scan_adr[9] <= (vctr[11:1]-8'd200) * 8'd100 + (hctr[11:1]-11'd100);
	scan_adr[10] <= (vctr[11:1]-8'd200) * 8'd100 + (hctr[11:1]-11'd200);
	scan_adr[11] <= (vctr[11:1]-8'd200) * 8'd100 + (hctr[11:1]-11'd300);
	*/
end
/*
always @(posedge dot_clk_i)
	casez({blank_i, (vctr < 8'd100), (vctr < 8'd200), (hctr < 11'd100), (hctr < 11'd200), (hctr < 11'd300)})
	6'b1?????:	scan_out <= 16'h0;
	6'b011111:	scan_out <= scan_out00;
	6'b011011:	scan_out <= scan_out01;
	6'b011001:	scan_out <= scan_out02;
	6'b011000:	scan_out <= scan_out03;
	6'b001111:	scan_out <= scan_out10;
	6'b001011:	scan_out <= scan_out11;
	6'b001001:	scan_out <= scan_out12;
	6'b001000:	scan_out <= scan_out13;
	6'b000111:	scan_out <= scan_out20;
	6'b000011:	scan_out <= scan_out21;
	6'b000001:	scan_out <= scan_out22;
	6'b000000:	scan_out <= scan_out23;
	default:	scan_out <= 16'h0;
	endcase
*/
always @(posedge dot_clk_i)
	casez({blank_i, (vctr < 8'd160 - voffs), (vctr < 8'd320 - voffs), (hctr < 11'd128 - hoffs), (hctr < 11'd256 - hoffs), (hctr < 11'd384 - hoffs), (hctr < 11'd512 - hoffs)})
	7'b1??????:	scan_out <= 16'h0;
	7'b0111111:	scan_out <= scan_out00;
	7'b0110111:	scan_out <= scan_out01;
	7'b0110011:	scan_out <= scan_out02;
	7'b0110001:	scan_out <= scan_out03;
	7'b0011111:	scan_out <= scan_out10;
	7'b0010111:	scan_out <= scan_out11;
	7'b0010011:	scan_out <= scan_out12;
	7'b0010001:	scan_out <= scan_out13;
	default:	scan_out <= 16'h0;
	endcase
always @(posedge dot_clk_i)
	zrgb_o <= {scan_out[15:12],4'd0,scan_out[11:8],4'd0,scan_out[7:4],4'd0,scan_out[3:0],4'd0};

// Lots of wires but not complex
wire u00_cyc, u00_ack, u00_we;
wire [31:0] u00_adr, u00_dati, u00_dato;
wire u01_cyc, u01_ack, u01_we;
wire [31:0] u01_adr, u01_dati, u01_dato;
wire u02_cyc, u02_ack, u02_we;
wire [31:0] u02_adr, u02_dati, u02_dato;
wire u03_cyc, u03_ack, u03_we;
wire [31:0] u03_adr, u03_dati, u03_dato;

wire u10_cyc, u10_ack, u10_we;
wire [31:0] u10_adr, u10_dati, u10_dato;
wire u11_cyc, u11_ack, u11_we;
wire [31:0] u11_adr, u11_dati, u11_dato;
wire u12_cyc, u12_ack, u12_we;
wire [31:0] u12_adr, u12_dati, u12_dato;
wire u13_cyc, u13_ack, u13_we;
wire [31:0] u13_adr, u13_dati, u13_dato;

wire u20_cyc, u20_ack, u20_we;
wire [31:0] u20_adr, u20_dati, u20_dato;
wire u21_cyc, u21_ack, u21_we;
wire [31:0] u21_adr, u21_dati, u21_dato;
wire u22_cyc, u22_ack, u22_we;
wire [31:0] u22_adr, u22_dati, u22_dato;
wire u23_cyc, u23_ack, u23_we;
wire [31:0] u23_adr, u23_dati, u23_dato;

wire m2_cyc, m2_stb, m2_ack, m2_we;
wire [3:0] m2_sel;
wire [31:0] m2_adr, m2_dato, m2_dati;
wire [14:0] m2_rsp, m2_req;

wire m3_cyc, m3_stb, m3_ack, m3_we;
wire [3:0] m3_sel;
wire [31:0] m3_adr, m3_dato, m3_dati;
wire [14:0] m3_rsp, m3_req;

wire m4_cyc, m4_stb, m4_ack, m4_we;
wire [3:0] m4_sel;
wire [31:0] m4_adr, m4_dato, m4_dati;
wire [14:0] m4_rsp, m4_req;

wire m5_cyc, m5_stb, m5_ack, m5_we;
wire [3:0] m5_sel;
wire [31:0] m5_adr, m5_dato, m5_dati;
wire [14:0] m5_rsp, m5_req;

wire m6_cyc, m6_stb, m6_ack, m6_we;
wire [3:0] m6_sel;
wire [31:0] m6_adr, m6_dato, m6_dati;
wire [14:0] m6_rsp, m6_req;

wire m7_cyc, m7_stb, m7_ack, m7_we;
wire [3:0] m7_sel;
wire [31:0] m7_adr, m7_dato, m7_dati;
wire [14:0] m7_rsp, m7_req;

wire m8_cyc, m8_stb, m8_ack, m8_we;
wire [3:0] m8_sel;
wire [31:0] m8_adr, m8_dato, m8_dati;
wire [14:0] m8_rsp, m8_req;

wire m9_cyc, m9_stb, m9_ack, m9_we;
wire [3:0] m9_sel;
wire [31:0] m9_adr, m9_dato, m9_dati;
wire [14:0] m9_rsp, m9_req;

wire m10_cyc, m10_stb, m10_ack, m10_we;
wire [3:0] m10_sel;
wire [31:0] m10_adr, m10_dato, m10_dati;
wire [14:0] m10_rsp, m10_req;

wire m11_cyc, m11_stb, m11_ack, m11_we;
wire [3:0] m11_sel;
wire [31:0] m11_adr, m11_dato, m11_dati;
wire [14:0] m11_rsp, m11_req;

wire m12_cyc, m12_stb, m12_ack, m12_we;
wire [3:0] m12_sel;
wire [31:0] m12_adr, m12_dato, m12_dati;
wire [14:0] m12_rsp, m12_req;

wire m13_cyc, m13_stb, m13_ack, m13_we;
wire [3:0] m13_sel;
wire [31:0] m13_adr, m13_dato, m13_dati;
wire [14:0] m13_rsp, m13_req;

wire grnt00, grnt01, grnt02, grnt03;
wire grnt10, grnt11, grnt12, grnt13;
wire grnt20, grnt21, grnt22, grnt23;

// Use a bridge to access imem
wire imem_wr;
wire [31:0] imem_dat;
wire [13:0] imem_adr;

delay2 #( 1) ud1 (.clk(clk_i), .ce(1'b1), .i(imem_wr_i),  .o(imem_we));
delay2 #(14) ud2 (.clk(clk_i), .ce(1'b1), .i(imem_adr_i), .o(imem_adr));
delay2 #(32) ud3 (.clk(clk_i), .ce(1'b1), .i(imem_dat_i), .o(imem_dat));

round_robin #(12) urr1
(
	.rst(rst_i),
	.clk(clk_i),
	.ce(1'b1),
	.req({u23_cyc,u22_cyc,u21_cyc,u20_cyc,u13_cyc,u12_cyc,u11_cyc,u10_cyc,u03_cyc,u02_cyc,u01_cyc,u00_cyc}),
	.lock({u23_cyc,u22_cyc,u21_cyc,u20_cyc,u13_cyc,u12_cyc,u11_cyc,u10_cyc,u03_cyc,u02_cyc,u01_cyc,u00_cyc}),
	.sel({grnt23,grnt22,grnt21,grnt20,grnt13,grnt12,grnt11,grnt10,grnt03,grnt02,grnt01,grnt00})
);

FTRISC32a u00 (
	.corenum_i(15'h00),
	.rst_i(rst_i),
	.clk_i(dot_clk_i),
	.cmd_core_i(cmd_core_i),
	.cmd_clk_i(cmd_clk_i),
	.wr_cmd_i(wr_cmd_i),
	.cmd_adr_i(cmd_adr_i),
	.cmd_dat_i(cmd_dat_i),
	.cmd_count_o(cmd_count_o), 
	.imem_wr_i(imem_wr_i),
	.imem_wadr_i(imem_adr_i),
	.imem_dat_i(imem_dat_i),
	.cyc_o(u00_cyc),
	.ack_i(u00_ack),
	.we_o(u00_we),
	.adr_o(u00_adr),
	.dat_i(u00_dati),
	.dat_o(u00_dato),
	.dot_clk_i(dot_clk_i),
	.scan_adr_i(scan_adr[0]),
	.scan_dat_o(scan_out00),
	.vctr_i(vctr_i),
	.hctr_i(hctr_i),
	.frame_i(fctr_i)
);

FT64_GPUBusMux ubm2 (
	.rst_i(rst_i),
	.clk_i(dot_clk_i),
	.ce_i(1'b1),
	.grnt_i(grnt00),
	.s1_req_i(15'h7ffe),
	.s1_cyc_i(1'b0),
	.s1_stb_i(1'b0),
	.s1_ack_o(),
	.s1_we_i(1'b0),
	.s1_sel_i(4'h0),
	.s1_adr_i(32'd0),
	.s1_dat_o(),
	.s1_dat_i(32'd0),
	.s2_req_i(15'h00),
	.s2_cyc_i(u00_cyc),
	.s2_stb_i(u00_cyc),
	.s2_ack_o(u00_ack),
	.s2_we_i(u00_we),
	.s2_sel_i(4'hF),
	.s2_adr_i(u00_adr),
	.s2_dat_o(u00_dati),
	.s2_dat_i(u00_dato),
	.m1_req_o(m00_req),
	.m1_rsp_i(m2_rsp),
	.m1_cyc_o(m2_cyc),
	.m1_stb_o(m2_stb),
	.m1_ack_i(m2_ack),
	.m1_we_o(m2_we),
	.m1_sel_o(m2_sel),
	.m1_adr_o(m2_adr),
	.m1_dat_o(m2_dato),
	.m1_dat_i(m2_dati)
);

FTRISC32a u01 (
	.corenum_i(15'h01),
	.rst_i(rst_i),
	.clk_i(dot_clk_i),
	.cmd_core_i(cmd_core_i),
	.cmd_clk_i(cmd_clk_i),
	.wr_cmd_i(wr_cmd_i),
	.cmd_adr_i(cmd_adr_i),
	.cmd_dat_i(cmd_dat_i),
	.cmd_count_o(), 
	.imem_wr_i(imem_wr_i),
	.imem_wadr_i(imem_adr_i),
	.imem_dat_i(imem_dat_i),
	.cyc_o(u01_cyc),
	.ack_i(u01_ack),
	.we_o(u01_we),
	.adr_o(u01_adr),
	.dat_i(u01_dati),
	.dat_o(u01_dato),
	.dot_clk_i(dot_clk_i),
	.scan_adr_i(scan_adr[1]),
	.scan_dat_o(scan_out01),
	.vctr_i(vctr_i),
	.hctr_i(hctr_i),
	.frame_i(fctr_i)
);

FT64_GPUBusMux ubm3 (
	.rst_i(rst_i),
	.clk_i(dot_clk_i),
	.ce_i(1'b1),
	.grnt_i(grnt01),
	.s1_req_i(m2_req),
	.s1_cyc_i(m2_cyc),
	.s1_stb_i(m2_stb),
	.s1_ack_o(m2_ack),
	.s1_we_i(m2_we),
	.s1_sel_i(m2_sel),
	.s1_adr_i(m2_adr),
	.s1_dat_o(m2_dati),
	.s1_dat_i(m2_dato),
	.s2_req_i(15'h01),
	.s2_cyc_i(u01_cyc),
	.s2_stb_i(u01_cyc),
	.s2_ack_o(u01_ack),
	.s2_we_i(u01_we),
	.s2_sel_i(4'hF),
	.s2_adr_i(u01_adr),
	.s2_dat_o(u01_dati),
	.s2_dat_i(u01_dato),
	.m1_req_o(m01_req),
	.m1_rsp_i(m3_rsp),
	.m1_cyc_o(m3_cyc),
	.m1_stb_o(m3_stb),
	.m1_ack_i(m3_ack),
	.m1_we_o(m3_we),
	.m1_sel_o(m3_sel),
	.m1_adr_o(m3_adr),
	.m1_dat_o(m3_dato),
	.m1_dat_i(m3_dati)
);

FTRISC32a u02 (
	.corenum_i(15'h02),
	.rst_i(rst_i),
	.clk_i(dot_clk_i),
	.cmd_core_i(cmd_core_i),
	.cmd_clk_i(cmd_clk_i),
	.wr_cmd_i(wr_cmd_i),
	.cmd_adr_i(cmd_adr_i),
	.cmd_dat_i(cmd_dat_i),
	.cmd_count_o(), 
	.imem_wr_i(imem_wr_i),
	.imem_wadr_i(imem_adr_i),
	.imem_dat_i(imem_dat_i),
	.cyc_o(u02_cyc),
	.ack_i(u02_ack),
	.we_o(u02_we),
	.adr_o(u02_adr),
	.dat_i(u02_dati),
	.dat_o(u02_dato),
	.dot_clk_i(dot_clk_i),
	.scan_adr_i(scan_adr[2]),
	.scan_dat_o(scan_out02),
	.vctr_i(vctr_i),
	.hctr_i(hctr_i),
	.frame_i(fctr_i)
);

FT64_GPUBusMux ubm4 (
	.rst_i(rst_i),
	.clk_i(dot_clk_i),
	.ce_i(1'b1),
	.grnt_i(grnt02),
	.s1_req_i(m3_req),
	.s1_cyc_i(m3_cyc),
	.s1_stb_i(m3_stb),
	.s1_ack_o(m3_ack),
	.s1_we_i(m3_we),
	.s1_sel_i(m3_sel),
	.s1_adr_i(m3_adr),
	.s1_dat_o(m3_dati),
	.s1_dat_i(m3_dato),
	.s2_req_i(15'h02),
	.s2_cyc_i(u02_cyc),
	.s2_stb_i(u02_cyc),
	.s2_ack_o(u02_ack),
	.s2_we_i(u02_we),
	.s2_sel_i(4'hF),
	.s2_adr_i(u02_adr),
	.s2_dat_o(u02_dati),
	.s2_dat_i(u02_dato),
	.m1_req_o(m02_req),
	.m1_rsp_i(m4_rsp),
	.m1_cyc_o(m4_cyc),
	.m1_stb_o(m4_stb),
	.m1_ack_i(m4_ack),
	.m1_we_o(m4_we),
	.m1_sel_o(m4_sel),
	.m1_adr_o(m4_adr),
	.m1_dat_o(m4_dato),
	.m1_dat_i(m4_dati)
);

FTRISC32a u03 (
	.corenum_i(15'h03),
	.rst_i(rst_i),
	.clk_i(dot_clk_i),
	.cmd_core_i(cmd_core_i),
	.cmd_clk_i(cmd_clk_i),
	.wr_cmd_i(wr_cmd_i),
	.cmd_adr_i(cmd_adr_i),
	.cmd_dat_i(cmd_dat_i),
	.cmd_count_o(), 
	.imem_wr_i(imem_wr_i),
	.imem_wadr_i(imem_adr_i),
	.imem_dat_i(imem_dat_i),
	.cyc_o(u03_cyc),
	.ack_i(u03_ack),
	.we_o(u03_we),
	.adr_o(u03_adr),
	.dat_i(u03_dati),
	.dat_o(u03_dato),
	.dot_clk_i(dot_clk_i),
	.scan_adr_i(scan_adr[3]),
	.scan_dat_o(scan_out03),
	.vctr_i(vctr_i),
	.hctr_i(hctr_i),
	.frame_i(fctr_i)
);

FT64_GPUBusMux ubm5 (
	.rst_i(rst_i),
	.clk_i(dot_clk_i),
	.ce_i(1'b1),
	.grnt_i(grnt03),
	.s1_req_i(m4_req),
	.s1_cyc_i(m4_cyc),
	.s1_stb_i(m4_stb),
	.s1_ack_o(m4_ack),
	.s1_we_i(m4_we),
	.s1_sel_i(m4_sel),
	.s1_adr_i(m4_adr),
	.s1_dat_o(m4_dati),
	.s1_dat_i(m4_dato),
	.s2_req_i(15'h03),
	.s2_cyc_i(u03_cyc),
	.s2_stb_i(u03_cyc),
	.s2_ack_o(u03_ack),
	.s2_we_i(u03_we),
	.s2_sel_i(4'hF),
	.s2_adr_i(u03_adr),
	.s2_dat_o(u03_dati),
	.s2_dat_i(u03_dato),
	.m1_req_o(m03_req),
	.m1_rsp_i(m5_rsp),
	.m1_cyc_o(m5_cyc),
	.m1_stb_o(m5_stb),
	.m1_ack_i(m5_ack),
	.m1_we_o(m5_we),
	.m1_sel_o(m5_sel),
	.m1_adr_o(m5_adr),
	.m1_dat_o(m5_dato),
	.m1_dat_i(m5_dati)
);

FTRISC32a u10 (
	.corenum_i(15'h10),
	.rst_i(rst_i),
	.clk_i(dot_clk_i),
	.cmd_core_i(cmd_core_i),
	.cmd_clk_i(cmd_clk_i),
	.wr_cmd_i(wr_cmd_i),
	.cmd_adr_i(cmd_adr_i),
	.cmd_dat_i(cmd_dat_i),
	.cmd_count_o(), 
	.imem_wr_i(imem_wr_i),
	.imem_wadr_i(imem_adr_i),
	.imem_dat_i(imem_dat_i),
	.cyc_o(u10_cyc),
	.ack_i(u10_ack),
	.we_o(u10_we),
	.adr_o(u10_adr),
	.dat_i(u10_dati),
	.dat_o(u10_dato),
	.dot_clk_i(dot_clk_i),
	.scan_adr_i(scan_adr[4]),
	.scan_dat_o(scan_out10),
	.vctr_i(vctr_i),
	.hctr_i(hctr_i),
	.frame_i(fctr_i)
);

FT64_GPUBusMux ubm6 (
	.rst_i(rst_i),
	.clk_i(dot_clk_i),
	.ce_i(1'b1),
	.grnt_i(grnt10),
	.s1_req_i(m5_req),
	.s1_cyc_i(m5_cyc),
	.s1_stb_i(m5_stb),
	.s1_ack_o(m5_ack),
	.s1_we_i(m5_we),
	.s1_sel_i(m5_sel),
	.s1_adr_i(m5_adr),
	.s1_dat_o(m5_dati),
	.s1_dat_i(m5_dato),
	.s2_req_i(15'h10),
	.s2_cyc_i(u10_cyc),
	.s2_stb_i(u10_cyc),
	.s2_ack_o(u10_ack),
	.s2_we_i(u10_we),
	.s2_sel_i(4'hF),
	.s2_adr_i(u10_adr),
	.s2_dat_o(u10_dati),
	.s2_dat_i(u10_dato),
	.m1_req_o(m10_req),
	.m1_rsp_i(m6_rsp),
	.m1_cyc_o(m6_cyc),
	.m1_stb_o(m6_stb),
	.m1_ack_i(m6_ack),
	.m1_we_o(m6_we),
	.m1_sel_o(m6_sel),
	.m1_adr_o(m6_adr),
	.m1_dat_o(m6_dato),
	.m1_dat_i(m6_dati)
);

FTRISC32a u11 (
	.corenum_i(15'h11),
	.rst_i(rst_i),
	.clk_i(dot_clk_i),
	.cmd_core_i(cmd_core_i),
	.cmd_clk_i(cmd_clk_i),
	.wr_cmd_i(wr_cmd_i),
	.cmd_adr_i(cmd_adr_i),
	.cmd_dat_i(cmd_dat_i),
	.cmd_count_o(), 
	.imem_wr_i(imem_wr_i),
	.imem_wadr_i(imem_adr_i),
	.imem_dat_i(imem_dat_i),
	.cyc_o(u11_cyc),
	.ack_i(u11_ack),
	.we_o(u11_we),
	.adr_o(u11_adr),
	.dat_i(u11_dati),
	.dat_o(u11_dato),
	.dot_clk_i(dot_clk_i),
	.scan_adr_i(scan_adr[5]),
	.scan_dat_o(scan_out11),
	.vctr_i(vctr_i),
	.hctr_i(hctr_i),
	.frame_i(fctr_i)
);

FT64_GPUBusMux ubm7 (
	.rst_i(rst_i),
	.clk_i(dot_clk_i),
	.ce_i(1'b1),
	.grnt_i(grnt11),
	.s1_req_i(m6_req),
	.s1_cyc_i(m6_cyc),
	.s1_stb_i(m6_stb),
	.s1_ack_o(m6_ack),
	.s1_we_i(m6_we),
	.s1_sel_i(m6_sel),
	.s1_adr_i(m6_adr),
	.s1_dat_o(m6_dati),
	.s1_dat_i(m6_dato),
	.s2_req_i(15'h11),
	.s2_cyc_i(u11_cyc),
	.s2_stb_i(u11_cyc),
	.s2_ack_o(u11_ack),
	.s2_we_i(u11_we),
	.s2_sel_i(4'hF),
	.s2_adr_i(u11_adr),
	.s2_dat_o(u11_dati),
	.s2_dat_i(u11_dato),
	.m1_req_o(m11_req),
	.m1_rsp_i(m7_rsp),
	.m1_cyc_o(m7_cyc),
	.m1_stb_o(m7_stb),
	.m1_ack_i(m7_ack),
	.m1_we_o(m7_we),
	.m1_sel_o(m7_sel),
	.m1_adr_o(m7_adr),
	.m1_dat_o(m7_dato),
	.m1_dat_i(m7_dati)
);

FTRISC32a u12 (
	.corenum_i(15'h12),
	.rst_i(rst_i),
	.clk_i(dot_clk_i),
	.cmd_core_i(cmd_core_i),
	.cmd_clk_i(cmd_clk_i),
	.wr_cmd_i(wr_cmd_i),
	.cmd_adr_i(cmd_adr_i),
	.cmd_dat_i(cmd_dat_i),
	.cmd_count_o(), 
	.imem_wr_i(imem_wr_i),
	.imem_wadr_i(imem_adr_i),
	.imem_dat_i(imem_dat_i),
	.cyc_o(u12_cyc),
	.ack_i(u12_ack),
	.we_o(u12_we),
	.adr_o(u12_adr),
	.dat_i(u12_dati),
	.dat_o(u12_dato),
	.dot_clk_i(dot_clk_i),
	.scan_adr_i(scan_adr[6]),
	.scan_dat_o(scan_out12),
	.vctr_i(vctr_i),
	.hctr_i(hctr_i),
	.frame_i(fctr_i)
);

FT64_GPUBusMux ubm8 (
	.rst_i(rst_i),
	.clk_i(dot_clk_i),
	.ce_i(1'b1),
	.grnt_i(grnt12),
	.s1_req_i(m7_req),
	.s1_cyc_i(m7_cyc),
	.s1_stb_i(m7_stb),
	.s1_ack_o(m7_ack),
	.s1_we_i(m7_we),
	.s1_sel_i(m7_sel),
	.s1_adr_i(m7_adr),
	.s1_dat_o(m7_dati),
	.s1_dat_i(m7_dato),
	.s2_req_i(15'h12),
	.s2_cyc_i(u12_cyc),
	.s2_stb_i(u12_cyc),
	.s2_ack_o(u12_ack),
	.s2_we_i(u12_we),
	.s2_sel_i(4'hF),
	.s2_adr_i(u12_adr),
	.s2_dat_o(u12_dati),
	.s2_dat_i(u12_dato),
	.m1_req_o(m12_req),
	.m1_rsp_i(m8_rsp),
	.m1_cyc_o(m8_cyc),
	.m1_stb_o(m8_stb),
	.m1_ack_i(m8_ack),
	.m1_we_o(m8_we),
	.m1_sel_o(m8_sel),
	.m1_adr_o(m8_adr),
	.m1_dat_o(m8_dato),
	.m1_dat_i(m8_dati)
);

FTRISC32a u13 (
	.corenum_i(15'h13),
	.rst_i(rst_i),
	.clk_i(dot_clk_i),
	.cmd_core_i(cmd_core_i),
	.cmd_clk_i(cmd_clk_i),
	.wr_cmd_i(wr_cmd_i),
	.cmd_adr_i(cmd_adr_i),
	.cmd_dat_i(cmd_dat_i),
	.cmd_count_o(), 
	.imem_wr_i(imem_wr_i),
	.imem_wadr_i(imem_adr_i),
	.imem_dat_i(imem_dat_i),
	.cyc_o(u13_cyc),
	.ack_i(u13_ack),
	.we_o(u13_we),
	.adr_o(u13_adr),
	.dat_i(u13_dati),
	.dat_o(u13_dato),
	.dot_clk_i(dot_clk_i),
	.scan_adr_i(scan_adr[7]),
	.scan_dat_o(scan_out13),
	.vctr_i(vctr_i),
	.hctr_i(hctr_i),
	.frame_i(fctr_i)
);

FT64_GPUBusMux ubm9 (
	.rst_i(rst_i),
	.clk_i(dot_clk_i),
	.ce_i(1'b1),
	.grnt_i(grnt13),
	.s1_req_i(m8_req),
	.s1_cyc_i(m8_cyc),
	.s1_stb_i(m8_stb),
	.s1_ack_o(m8_ack),
	.s1_we_i(m8_we),
	.s1_sel_i(m8_sel),
	.s1_adr_i(m8_adr),
	.s1_dat_o(m8_dati),
	.s1_dat_i(m8_dato),
	.s2_req_i(15'h13),
	.s2_cyc_i(u13_cyc),
	.s2_stb_i(u13_cyc),
	.s2_ack_o(u13_ack),
	.s2_we_i(u13_we),
	.s2_sel_i(4'hF),
	.s2_adr_i(u13_adr),
	.s2_dat_o(u13_dati),
	.s2_dat_i(u13_dato),
	.m1_req_o(m13_req),
	.m1_rsp_i(m9_rsp),
	.m1_cyc_o(m9_cyc),
	.m1_stb_o(m9_stb),
	.m1_ack_i(m9_ack),
	.m1_we_o(m9_we),
	.m1_sel_o(m9_sel),
	.m1_adr_o(m9_adr),
	.m1_dat_o(m9_dato),
	.m1_dat_i(m9_dati)
);

/*
FTRISC32a u20 (
	.corenum_i(15'h20),
	.rst_i(rst_i),
	.clk_i(dot_clk_i),
	.cmd_core_i(cmd_core_i),
	.cmd_clk_i(cmd_clk_i),
	.wr_cmd_i(wr_cmd_i),
	.cmd_adr_i(cmd_adr_i),
	.cmd_dat_i(cmd_dat_i),
	.cmd_count_o(), 
	.cyc_o(u20_cyc),
	.ack_i(u20_ack),
	.we_o(u20_we),
	.adr_o(u20_adr),
	.dat_i(u20_dati),
	.dat_o(u20_dato),
	.dot_clk_i(dot_clk_i),
	.scan_adr_i(scan_adr[8]),
	.scan_dat_o(scan_out20),
	.frame_i(fctr_i)
);

FT64_GPUBusMux ubm10 (
	.rst_i(rst_i),
	.clk_i(dot_clk_i),
	.ce_i(1'b1),
	.grnt_i(grnt20),
	.s1_req_i(m9_req),
	.s1_cyc_i(m9_cyc),
	.s1_stb_i(m9_stb),
	.s1_ack_o(m9_ack),
	.s1_we_i(m9_we),
	.s1_sel_i(m9_sel),
	.s1_adr_i(m9_adr),
	.s1_dat_o(m9_dati),
	.s1_dat_i(m9_dato),
	.s2_req_i(15'h20),
	.s2_cyc_i(u20_cyc),
	.s2_stb_i(u20_cyc),
	.s2_ack_o(u20_ack),
	.s2_we_i(u20_we),
	.s2_sel_i(4'hF),
	.s2_adr_i(u20_adr),
	.s2_dat_o(u20_dati),
	.s2_dat_i(u20_dato),
	.m1_req_o(m10_req),
	.m1_rsp_i(m10_rsp),
	.m1_cyc_o(m10_cyc),
	.m1_stb_o(m10_stb),
	.m1_ack_i(m10_ack),
	.m1_we_o(m10_we),
	.m1_sel_o(m10_sel),
	.m1_adr_o(m10_adr),
	.m1_dat_o(m10_dato),
	.m1_dat_i(m10_dati)
);

FTRISC32a u21 (
	.corenum_i(15'h21),
	.rst_i(rst_i),
	.clk_i(dot_clk_i),
	.cmd_core_i(cmd_core_i),
	.cmd_clk_i(cmd_clk_i),
	.wr_cmd_i(wr_cmd_i),
	.cmd_adr_i(cmd_adr_i),
	.cmd_dat_i(cmd_dat_i),
	.cmd_count_o(), 
	.cyc_o(u21_cyc),
	.ack_i(u21_ack),
	.we_o(u21_we),
	.adr_o(u21_adr),
	.dat_i(u21_dati),
	.dat_o(u21_dato),
	.dot_clk_i(dot_clk_i),
	.scan_adr_i(scan_adr[9]),
	.scan_dat_o(scan_out21),
	.frame_i(fctr_i)
);

FT64_GPUBusMux ubm11 (
	.rst_i(rst_i),
	.clk_i(dot_clk_i),
	.ce_i(1'b1),
	.grnt_i(grnt21),
	.s1_req_i(m10_req),
	.s1_cyc_i(m10_cyc),
	.s1_stb_i(m10_stb),
	.s1_ack_o(m10_ack),
	.s1_we_i(m10_we),
	.s1_sel_i(m10_sel),
	.s1_adr_i(m10_adr),
	.s1_dat_o(m10_dati),
	.s1_dat_i(m10_dato),
	.s2_req_i(15'h21),
	.s2_cyc_i(u21_cyc),
	.s2_stb_i(u21_cyc),
	.s2_ack_o(u21_ack),
	.s2_we_i(u21_we),
	.s2_sel_i(4'hF),
	.s2_adr_i(u21_adr),
	.s2_dat_o(u21_dati),
	.s2_dat_i(u21_dato),
	.m1_req_o(m11_req),
	.m1_rsp_i(m11_rsp),
	.m1_cyc_o(m11_cyc),
	.m1_stb_o(m11_stb),
	.m1_ack_i(m11_ack),
	.m1_we_o(m11_we),
	.m1_sel_o(m11_sel),
	.m1_adr_o(m11_adr),
	.m1_dat_o(m11_dato),
	.m1_dat_i(m11_dati)
);

FTRISC32a u22 (
	.corenum_i(15'h22),
	.rst_i(rst_i),
	.clk_i(dot_clk_i),
	.cmd_core_i(cmd_core_i),
	.cmd_clk_i(cmd_clk_i),
	.wr_cmd_i(wr_cmd_i),
	.cmd_adr_i(cmd_adr_i),
	.cmd_dat_i(cmd_dat_i),
	.cmd_count_o(), 
	.cyc_o(u22_cyc),
	.ack_i(u22_ack),
	.we_o(u22_we),
	.adr_o(u22_adr),
	.dat_i(u22_dati),
	.dat_o(u22_dato),
	.dot_clk_i(dot_clk_i),
	.scan_adr_i(scan_adr[10]),
	.scan_dat_o(scan_out22),
	.frame_i(fctr_i)
);

FT64_GPUBusMux ubm12 (
	.rst_i(rst_i),
	.clk_i(dot_clk_i),
	.ce_i(1'b1),
	.grnt_i(grnt22),
	.s1_req_i(m11_req),
	.s1_cyc_i(m11_cyc),
	.s1_stb_i(m11_stb),
	.s1_ack_o(m11_ack),
	.s1_we_i(m11_we),
	.s1_sel_i(m11_sel),
	.s1_adr_i(m11_adr),
	.s1_dat_o(m11_dati),
	.s1_dat_i(m11_dato),
	.s2_req_i(15'h22),
	.s2_cyc_i(u22_cyc),
	.s2_stb_i(u22_cyc),
	.s2_ack_o(u22_ack),
	.s2_we_i(u22_we),
	.s2_sel_i(4'hF),
	.s2_adr_i(u22_adr),
	.s2_dat_o(u22_dati),
	.s2_dat_i(u22_dato),
	.m1_req_o(m12_req),
	.m1_rsp_i(m12_rsp),
	.m1_cyc_o(m12_cyc),
	.m1_stb_o(m12_stb),
	.m1_ack_i(m12_ack),
	.m1_we_o(m12_we),
	.m1_sel_o(m12_sel),
	.m1_adr_o(m12_adr),
	.m1_dat_o(m12_dato),
	.m1_dat_i(m12_dati)
);

FTRISC32a u23 (
	.corenum_i(15'h23),
	.rst_i(rst_i),
	.clk_i(dot_clk_i),
	.cmd_core_i(cmd_core_i),
	.cmd_clk_i(cmd_clk_i),
	.wr_cmd_i(wr_cmd_i),
	.cmd_adr_i(cmd_adr_i),
	.cmd_dat_i(cmd_dat_i),
	.cmd_count_o(), 
	.cyc_o(u23_cyc),
	.ack_i(u23_ack),
	.we_o(u23_we),
	.adr_o(u23_adr),
	.dat_i(u23_dati),
	.dat_o(u23_dato),
	.dot_clk_i(dot_clk_i),
	.scan_adr_i(scan_adr[11]),
	.scan_dat_o(scan_out23),
	.frame_i(fctr_i)
);

FT64_GPUBusMux ubm13 (
	.rst_i(rst_i),
	.clk_i(dot_clk_i),
	.ce_i(1'b1),
	.grnt_i(grnt23),
	.s1_req_i(m12_req),
	.s1_cyc_i(m12_cyc),
	.s1_stb_i(m12_stb),
	.s1_ack_o(m12_ack),
	.s1_we_i(m12_we),
	.s1_sel_i(m12_sel),
	.s1_adr_i(m12_adr),
	.s1_dat_o(m12_dati),
	.s1_dat_i(m12_dato),
	.s2_req_i(15'h23),
	.s2_cyc_i(u23_cyc),
	.s2_stb_i(u23_cyc),
	.s2_ack_o(u23_ack),
	.s2_we_i(u23_we),
	.s2_sel_i(4'hF),
	.s2_adr_i(u23_adr),
	.s2_dat_o(u23_dati),
	.s2_dat_i(u23_dato),
	.m1_req_o(m13_req),
	.m1_rsp_i(m13_rsp),
	.m1_cyc_o(m13_cyc),
	.m1_stb_o(m13_stb),
	.m1_ack_i(m13_ack),
	.m1_we_o(m13_we),
	.m1_sel_o(m13_sel),
	.m1_adr_o(m13_adr),
	.m1_dat_o(m13_dato),
	.m1_dat_i(m13_dati)
);
*/
/*
assign cyc_o = m13_cyc;
assign stb_o = m13_stb;
assign we_o = m13_we;
assign sel_o = m13_sel;
assign adr_o = m13_adr;
assign dat_o = m13_dato;
*/
assign cyc_o = m9_cyc;
assign stb_o = m9_stb;
assign we_o = m9_we;
assign sel_o = m9_sel;
assign adr_o = m9_adr;
assign dat_o = m9_dato;

assign m13_dati = dat_i;
assign m12_dati = dat_i;
assign m11_dati = dat_i;
assign m10_dati = dat_i;
assign m9_dati = dat_i;
assign m8_dati = dat_i;
assign m7_dati = dat_i;
assign m6_dati = dat_i;
assign m5_dati = dat_i;
assign m4_dati = dat_i;
assign m3_dati = dat_i;
assign m2_dati = dat_i;
assign m13_ack = ack_i;
assign m12_ack = ack_i;
assign m11_ack = ack_i;
assign m10_ack = ack_i;
assign m9_ack = ack_i;
assign m8_ack = ack_i;
assign m7_ack = ack_i;
assign m6_ack = ack_i;
assign m5_ack = ack_i;
assign m4_ack = ack_i;
assign m3_ack = ack_i;
assign m2_ack = ack_i;
assign m13_rsp = m9_req;
assign m12_rsp = m9_req;
assign m11_rsp = m9_req;
assign m10_rsp = m9_req;
assign m9_rsp = m9_req;
assign m8_rsp = m9_req;
assign m7_rsp = m9_req;
assign m6_rsp = m9_req;
assign m5_rsp = m9_req;
assign m4_rsp = m9_req;
assign m3_rsp = m9_req;
assign m2_rsp = m9_req;

endmodule
