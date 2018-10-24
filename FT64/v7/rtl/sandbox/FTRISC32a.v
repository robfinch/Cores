// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// FTRISC32a
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
module FTRISC32a(corenum_i, rst_i, clk_i,
	imem_wr_i, imem_wadr_i, imem_dat_i,
	cmd_core_i, cmd_clk_i, wr_cmd_i, cmd_adr_i, cmd_dat_i, cmd_dat_o, cmd_count_o, 
	cyc_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o,
	dot_clk_i, scan_adr_i, scan_dat_o, vctr_i, hctr_i, frame_i);
input [14:0] corenum_i;
input rst_i;
input clk_i;
input imem_wr_i;
input [13:0] imem_wadr_i;
input [31:0] imem_dat_i;
input [14:0] cmd_core_i;
input cmd_clk_i;
input wr_cmd_i;
input [7:0] cmd_adr_i;
input [31:0] cmd_dat_i;
output reg [31:0] cmd_dat_o;
output [6:0] cmd_count_o;
output cyc_o;
input ack_i;
output reg we_o;
output reg [3:0] sel_o;
output reg [31:0] adr_o;
input [31:0] dat_i;
output reg [31:0] dat_o;
input dot_clk_i;
input [15:0] scan_adr_i;
output [15:0] scan_dat_o;
input [11:0] vctr_i;
input [11:0] hctr_i;
input [5:0] frame_i;

parameter i_r2 = 6'h02;
parameter i_r1  = 6'h01;
parameter i_com = 5'h03;
parameter i_abs = 5'h04;
parameter i_not = 5'h05;
parameter i_redor = 5'h06;
parameter i_zxb = 5'h0A;
parameter i_4to8 = 5'h0B;
parameter i_2to8 = 5'h0C;
parameter i_zxc = 5'h09;
parameter i_popr  = 5'h0E;
parameter i_sxc = 5'h19;
parameter i_sxb = 5'h1A;
parameter i_8to4 = 5'h1B;
parameter i_8to2 = 5'h1C;
parameter i_rdcmd = 5'h1E;
parameter i_rdcmdcnt = 5'h1F;

parameter i_add = 6'h04;
parameter i_sub = 6'h05;
parameter i_slt = 6'h06;
parameter i_sltu = 6'h07;
parameter i_sle = 6'h28;
parameter i_sleu = 6'h29;
parameter i_and = 6'h08;
parameter i_or  = 6'h09;
parameter i_xor = 6'h0A;
parameter i_nand = 6'h0C;
parameter i_nor  = 6'h0D;
parameter i_xnor = 6'h0E;
parameter i_shifti = 6'h0F;
parameter i_transform = 6'h11;
parameter i_shl		= 3'h0;
parameter i_shr		= 3'h1;
parameter i_asr		= 3'h3;
parameter i_testscn = 6'h20;
parameter i_testclip = 6'h21;
parameter i_fxdiv = 6'h2B;
parameter i_min  = 6'h2C;
parameter i_max  = 6'h2D;
parameter i_shiftr = 6'h2F;
parameter i_mul  = 6'h3A;
parameter i_fxmul = 6'h3B;
parameter i_addi = 6'h04;
parameter i_csr  = 6'h05;
parameter i_slti = 6'h06;
parameter i_sltui = 6'h07;
parameter i_andi = 6'h08;
parameter i_ori  = 6'h09;
parameter i_xori = 6'h0A;
parameter i_blend = 6'h0C;
parameter i_xnori = 6'h0E;
parameter i_jal  = 6'h18;
parameter i_call = 6'h19;
parameter i_sgtui = 6'h1C;
parameter i_ld   = 6'h20;
parameter i_st   = 6'h24;
parameter i_bb_  = 6'h26;
parameter i_bbs  = 2'd0;
parameter i_bbc  = 2'd1;
parameter i_ibne = 2'd2;
parameter i_dbnz = 2'd3;
parameter i_lui  = 6'h27;
parameter i_jmp  = 6'h28;
parameter i_ret  = 6'h29;
parameter i_sgti = 6'h2C;
parameter i_bcc  = 6'h30;
parameter i_beq	 = 3'd0;
parameter i_bne  = 3'd1;
parameter i_blt  = 3'd2;
parameter i_bge  = 3'd3;
parameter i_bltu = 3'd6;
parameter i_bgeu = 3'd7;
parameter i_beqi = 6'h32;
parameter i_fxmuli = 6'h39;
parameter i_muli = 6'h3A;
parameter i_nop  = 6'h3D;

parameter i_lcx = 6'h20;
parameter i_lhx = 6'h10;
parameter i_scx	= 6'h24;
parameter i_shx = 6'h14;

parameter csr_corenum = 10'h001;

parameter char = 2'd1;
parameter half = 2'd2;

parameter IDLE = 6'd0;
parameter IFETCH = 6'd1;
parameter DECODE = 6'd2;
parameter EXECUTE = 6'd3;
parameter WRITEBACK = 6'd4;
parameter LD1 = 6'd5;
parameter LD2 = 6'd6;
parameter LD3 = 6'd7;
parameter ST1 = 6'd8;
parameter BLEND1 = 6'd10;
parameter BLEND2 = 6'd11;
parameter BLEND3 = 6'd12;
parameter BR = 6'd14;
parameter SHIFT = 6'd15;
parameter TRANSFORM5 = 6'd17;
parameter TRANSFORM6 = 6'd18;
parameter TRANSFORM7 = 6'd19;
parameter DELAY1 = 6'd20;
parameter DELAY2 = 6'd21;
parameter DELAY3 = 6'd22;
parameter FXMUL1 = 6'd23;
parameter FXMUL2 = 6'd24;
parameter MUL1 = 6'd25;
parameter MUL2 = 6'd26;

parameter TRANSFORM1 = 3'd1;
parameter TRANSFORM2 = 3'd2;
parameter TRANSFORM3 = 3'd3;
parameter TRANSFORM4 = 3'd4;
parameter TDELAY3 = 3'd5;
parameter TDELAY2 = 3'd6;
parameter TDELAY1 = 3'd7;

parameter ST_IDLE = 2'd00;
parameter ST2 = 2'd01;

integer n;
reg cyc;
reg [1:0] memsize;
reg [5:0] state;
reg [5:0] stkstate;
reg [2:0] tstate;
reg [2:0] tstkstate;
reg [1:0] sstate;
reg [13:0] pc;
reg [31:0] ir;
reg [31:0] control;
reg [31:0] status;
reg clear_status;
reg [7:0] alpha;
reg [7:0] alpha_pt0, alpha_pt1, alpha_pt2, gbl_alpha;
reg [31:0] colorkey;
reg [31:0] target_base;
reg [31:0] target_x0;
reg [31:0] target_y0;
reg [31:0] target_x1;
reg [31:0] target_y1;
reg [31:0] tex0_base;
reg [31:0] tex0_size_x;
reg [31:0] tex0_size_y;
reg [31:0] src_p0_x;
reg [31:0] src_p0_y;
reg [31:0] src_p1_x;
reg [31:0] src_p1_y;
reg [31:0] dest_x;
reg [31:0] dest_y;
reg [31:0] dest_z;
reg [31:0] clip_p0_x;
reg [31:0] clip_p0_y;
reg [31:0] clip_p1_x;
reg [31:0] clip_p1_y;
reg [31:0] color0, color1, color2;
reg [31:0] u0;
reg [31:0] v0;
reg [31:0] u1;
reg [31:0] v1;
reg [31:0] u2;
reg [31:0] v2;
reg [31:0] zbuffer_base;

wire [29:0] scanpos = {frame_i,vctr_i,hctr_i};

reg which_dv;
reg [3:0] ld_dv;
wire [3:0] dv_done;
wire [63:0] dv1_qo, dv2_qo, dv3_qo, dv4_qo;
wire [63:0] dv1_ro, dv2_ro, dv3_ro, dv4_ro;

wire ram_ack;
wire [31:0] ram_dat;
reg rd_cmd;
wire [39:0] cmd_fifo;
wire [6:0] cmd_count;
reg [31:0] dati;

(* ram_style="distributed" *)
reg [31:0] cmd_shadow [0:63];
always @(posedge clk_i)
	if (rd_cmd)
		cmd_shadow[cmd_fifo[39:34]] <= cmd_fifo[31:0];
wire [31:0] cmd_shadow_o = cmd_shadow[adr_o[7:2]];
wire [31:0] cmd_shadow1_o = cmd_shadow[cmd_adr_i[7:2]];
always @(posedge clk_i)
if (cmd_core_i==corenum_i)
	case(cmd_adr_i)
	8'h00:	cmd_dat_o <= control;
	8'h04:	cmd_dat_o <= status;
	default:	cmd_dat_o <= cmd_shadow1_o;
	endcase
else
	cmd_dat_o <= 32'd0;

(* ram_style="distributed" *)
reg [31:0] regfile [0:31];
reg [14:0] imem_adr;
(* ram_style="block" *)
reg [31:0] rommem [0:4095];
initial begin
`include "d:\\cores5\\FT64\\v7\\software\\boot\\GPU.ve0";
end
reg [31:0] imem_o;
always @(posedge clk_i)
	if (imem_wr_i)
		rommem[imem_wadr_i[13:2]] <= imem_dat_i;
always @(posedge clk_i)
	imem_o <= rommem[imem_adr[13:2]];

wire cs_imem = adr_o[31:16]==16'hFFFC;
wire cs_ram  = adr_o[31:16]==16'h0010;
wire cs_cmd  = adr_o[31: 8]==24'hFFD000;
wire cs_ext = ~(cs_imem|cs_ram|cs_cmd);
assign cyc_o = cs_ext & cyc;
always @(posedge clk_i)
casez({cs_imem,cs_ram,cs_cmd})
3'b1??:	dati <= imem_o;
3'b01?:	dati <= ram_dat;
3'b001:	dati <= cmd_shadow_o;
default:	dati <= dat_i;
endcase


// Quick register file write, write will take place within one cycle.
reg qrfw;
always @*
case(ir[5:0])
i_r2:
	case(ir[31:26])
	i_add, i_slt, i_sltu, i_sle, i_sleu, i_and, i_or, i_xor, i_nand, i_nor, i_xnor,
	i_shifti, i_shiftr, i_min, i_max, i_testclip:
		qrfw <= 1'b1;
	i_r1:
		case(ir[22:18])
		i_abs, i_com, i_not, i_redor, i_zxb, i_zxc, i_sxb, i_sxc,
		i_4to8, i_8to4, i_2to8, i_8to2, i_rdcmdcnt:
			qrfw <= 1'b1;
		default:	qrfw <= 1'b0;
		endcase
	default:	qrfw <= 1'b0;
	endcase
i_addi, i_csr, i_slti, i_sltui, i_andi, i_ori, i_xori, i_xnori,
i_jal, i_sgtui, i_sgti, i_lui:
	qrfw <= 1'b1;
default:	qrfw <= 1'b0;
endcase

// Registering the value of takb will help keep the fmax high and ease routing.
// But it does cost a clock cycle.
reg takb;
always @(posedge clk_i)
case(ir[5:0])
i_bcc:
	case (ir[15:13])
	i_beq:	takb <= a == b;
	i_bne:	takb <= a != b;
	i_blt:	takb <= $signed(a) < $signed(b);
	i_bge:	takb <= $signed(a) >= $signed(b);
	i_bltu:	takb <= a < b;
	i_bgeu:	takb <= a >= b;
	default:	takb <= 1'b0;
	endcase
i_bb_:
	case(ir[14:13])
	i_bbs:	takb <=  a[{ir[21:18],ir[15]}];
	i_bbc:	takb <= ~a[{ir[21:18],ir[15]}];
	default:	takb <= 1'b0;
	endcase
i_beqi:	takb <= a == {{24{ir[22]}},ir[22:18],ir[15:13]};
default:	takb <= 1'b0;
endcase
// Might as well use the extra clock cyle to register the branch target address
// result.
reg [31:0] br_target;

// Shifts are registered, once again to avoid performing too much work in a
// single clock cycle.
reg [31:0] shlor, shror, asror, shloi, shroi, asroi;
always @(posedge clk_i)
	shlor <= a << Rc;
always @(posedge clk_i)
	shror <= a >> Rc;
always @(posedge clk_i)
	asror <= a[31] ? (a >> Rc) | ~({32{1'b1}} >> Rc) : a >> Rc;
always @(posedge clk_i)
	shloi <= a << b[4:0];
always @(posedge clk_i)
	shroi <= a >> b[4:0];
always @(posedge clk_i)
	asroi <= a[31] ? (a >> b[4:0]) | ~({32{1'b1}} >> b[4:0]) : a >> b[4:0];

reg clp;
always @(posedge clk_i)
begin
	clp <= 1'b0;
	if (a < target_x0 || a >= target_x1)
		clp <= 1'b1;
	else if (b < target_y0 || b >= target_y1)
		clp <= 1'b1;
	else if (control[5]) begin
		if (a < clip_p0_x || a >= clip_p1_x)
			clp <= 1'b1;
		else if (b < clip_p0_y || b >= clip_p1_y)
			clp <= 1'b1;
	end
end

wire [4:0] Ra = ir[12: 8];
wire [4:0] Rb = ir[22:18];
wire [4:0] Rc = ir[27:23];
reg [4:0] Rt;

wire [31:0] rfoa = regfile[Ra];
wire [31:0] rfob = regfile[Rb];
wire [31:0] rfoc = regfile[Rc];
reg [31:0] a, b, c, d, imm, res, ea;

wire signed [63:0] prod = $signed(a) * $signed(b);
reg [63:0] prod1, prod2;
always @(posedge clk_i)
	prod1 <= prod;
always @(posedge clk_i)
	prod2 <= prod1;

wire [31:0] color4to8 = {a[15:12],4'h0,a[11:8],4'h0,a[7:4],4'h0,a[3:0],4'h0};
wire [31:0] color8to4 = {a[31:28],a[23:20],a[15:12],a[7:4]};
wire [15:0] aprod_r = (c[7:0] * a[23:16]) + (~c[7:0] * b[23:16]);
wire [15:0] aprod_g = (c[7:0] * a[15: 8]) + (~c[7:0] * b[15: 8]);
wire [15:0] aprod_b = (c[7:0] * a[ 7: 0]) + (~c[7:0] * b[ 7: 0]);
wire [31:0] aprod = {a[31:24],aprod_r[15:8],aprod_g[15:8],aprod_b[15:8]};
reg [31:0] aprod1,aprod2;
always @(posedge clk_i)
	aprod1 <= aprod;
always @(posedge clk_i)
	aprod2 <= aprod1;

reg [31:0] a1, b1, c1, x1;
reg [31:0] at, bt, ct;
// Transform matrix co-efficients
reg [31:0] aa, ab, ac, tx;
reg [31:0] ba, bb, bc, ty;
reg [31:0] ca, cb, cc, tz;
// Transform matrix products
reg [63:0] aax, bax, cax;
reg [63:0] aby, bby, cby;
reg [63:0] acz, bcz, ccz;

wire [63:0] pax = a1 * x1;
wire [63:0] pbx = b1 * x1;
wire [63:0] pcx = c1 * x1;

wire signed [63:0] x_prime = aax + aby + acz + {tx,16'h0};
wire signed [63:0] y_prime = bax + bby + bcz + {ty,16'h0};
wire signed [63:0] z_prime = cax + cby + ccz + {tz,16'h0};


FT_GPUCmdFifo ucf1 (
  .rst(rst_i),
  .wr_clk(cmd_clk_i),
  .rd_clk(clk_i),
  .din({cmd_adr_i,cmd_dat_i}),
  .wr_en(wr_cmd_i && (corenum_i==cmd_core_i || cmd_core_i==15'h7fff)),
  .rd_en(rd_cmd),
  .dout(cmd_fifo),
  .full(),
  .empty(),
  .rd_data_count(cmd_count),
  .wr_data_count(cmd_count_o)
);

always @(posedge clk_i)
if (rst_i) begin
	rd_cmd <= 1'b0;
	control <= 32'h2;			// 16bpp color depth
	status[31:16] <= 16'd64;
//	target_x0 <= corenum_i[4:0] * 8'd100;
//	target_y0 <= corenum_i[9:5] * 8'd100;
//	target_x1 <= (corenum_i[4:0] + 5'd1) * 8'd100;
//	target_y1 <= (corenum_i[9:5] + 5'd1) * 8'd100;
end
else begin
	rd_cmd <= 1'b0;
if (rd_cmd) begin
	case(cmd_fifo[39:32])
	8'h00:	
		begin
			control <= cmd_fifo[31:0];
			if (|control[13:8] || |control[19:18])
				status[0] <= 1'b1;
		end
	8'h08:
		begin	
			alpha_pt0 <= cmd_fifo[31:24];
			alpha_pt1 <= cmd_fifo[23:16];
			alpha_pt2 <= cmd_fifo[15: 8];
			gbl_alpha <= cmd_fifo[ 7: 0];
		end
	8'h0C:	colorkey <= cmd_fifo[31:0];
	8'h10:	target_base <= cmd_fifo[31:0];
	8'h1C:	tex0_base <= cmd_fifo[31:0];
	8'h20:	tex0_size_x <= cmd_fifo[31:0];
	8'h24:	tex0_size_y <= cmd_fifo[31:0];
	8'h28:	src_p0_x <= cmd_fifo[31:0];
	8'h2C:	src_p0_y <= cmd_fifo[31:0];
	8'h30:	src_p1_x <= cmd_fifo[31:0];
	8'h34:	src_p1_y <= cmd_fifo[31:0];
	8'h38:	dest_x <= cmd_fifo[31:0];
	8'h3C:	dest_y <= cmd_fifo[31:0];
	8'h40:	dest_z <= cmd_fifo[31:0];
	8'h44:	aa <= cmd_fifo[31:0];
	8'h48:	ab <= cmd_fifo[31:0];
	8'h4C:	ac <= cmd_fifo[31:0];
	8'h50:	tx <= cmd_fifo[31:0];
	8'h54:	ba <= cmd_fifo[31:0];
	8'h58:	bb <= cmd_fifo[31:0];
	8'h5C:	bc <= cmd_fifo[31:0];
	8'h60:	ty <= cmd_fifo[31:0];
	8'h64:	ca <= cmd_fifo[31:0];
	8'h68:	cb <= cmd_fifo[31:0];
	8'h6C:	cc <= cmd_fifo[31:0];
	8'h70:	tz <= cmd_fifo[31:0];
	8'h74:	clip_p0_x <= cmd_fifo[31:0];
	8'h78:	clip_p0_y <= cmd_fifo[31:0];
	8'h7C:	clip_p1_x <= cmd_fifo[31:0];
	8'h80:	clip_p1_y <= cmd_fifo[31:0];
	8'h84:	color0 <= cmd_fifo[31:0];
	8'h88:	color1 <= cmd_fifo[31:0];
	8'h8C:	color2 <= cmd_fifo[31:0];
	8'h90:	u0 <= cmd_fifo[31:0];
	8'h94:	v0 <= cmd_fifo[31:0];
	8'h98:	u1 <= cmd_fifo[31:0];
	8'h9C:	v1 <= cmd_fifo[31:0];
	8'hA0:	u2 <= cmd_fifo[31:0];
	8'hA4:	v2 <= cmd_fifo[31:0];
	8'hA8:	zbuffer_base <= cmd_fifo[31:0];
	8'hAC:	target_x0 <= cmd_fifo[31:0];
	8'hB0:	target_y0 <= cmd_fifo[31:0];
	8'hB4:	target_x1 <= cmd_fifo[31:0];
	8'hB8:	target_x1 <= cmd_fifo[31:0];
	default:	;
	endcase
end
else if (cs_cmd && adr_o[7:2]==8'h04 && we_o) begin
	status[0] <= dat_o[0];
	if (!dat_o[1])
		rd_cmd <= 1'b1;
end
end

wire [23:0] lfsr1_o;
lfsr #(24) ulfsr1(rst_i, dot_clk_i, 1'b1, 1'b0, lfsr1_o);
wire [15:0] lfsr_o = lfsr1_o[15:0];
reg por;

always @(posedge dot_clk_i)
if (rst_i)
	por <= 1'b1;
else begin
	if (frame_i > 6'd60)
		por <= 1'b0;
end

FT_GPURam ulr1
(
  .clka(clk_i),
  .ena(cyc & cs_ram),
  .wea({4{we_o}} & sel_o),
  .addra(adr_o[15:2]),
  .dina(dat_o),
  .douta(ram_dat),
  .clkb(dot_clk_i),
  .enb(1'b1),
  .web({2{por}}),
  .addrb(scan_adr_i),
  .dinb(lfsr_o),
  .doutb(scan_dat_o)
);

ack_gen #(
	.READ_STAGES(3),
	.WRITE_STAGES(1),
	.REGISTER_OUTPUT(1)
) ag1
(
	.clk_i(clk_i),
	.ce_i(1'b1),
	.i(cyc & cs_ram),
	.we_i(cyc & cs_ram & we_o),
	.o(ram_ack)
);

wire imem_ack;
ack_gen #(
	.READ_STAGES(3),
	.WRITE_STAGES(1),
	.REGISTER_OUTPUT(1)
) ag2
(
	.clk_i(clk_i),
	.ce_i(1'b1),
	.i(cs_imem & cyc),
	.we_i(1'b0),
	.o(imem_ack)
);

reg acki;
always @(posedge clk_i)
	acki <= ram_ack | ack_i | cs_cmd | imem_ack;

/*
FT64_GSdivider #(.WID(32), .WHOLE(16), .POINTS(16)) udv1 (
	.rst(rst_i),
	.clk(clk_i),
	.ld(ld_dv[0]),
	.abort(1'b0),
	.sgn(1'b1),
	.sgnus(1'b0),
	.a(a),
	.b(b),
	.qo(dv1_qo),
	.dvByZr(),
	.done(dv_done[0]),
	.idle()
);

FT64_GSdivider #(.WID(32), .WHOLE(16), .POINTS(16)) udv2 (
	.rst(rst_i),
	.clk(clk_i),
	.ld(ld_dv[1]),
	.abort(1'b0),
	.sgn(1'b1),
	.sgnus(1'b0),
	.a(a),
	.b(b),
	.qo(dv2_qo),
	.dvByZr(),
	.done(dv_done[1]),
	.idle()
);
*/

FT64_divider #(64) udv1 (
	.rst(rst_i),
	.clk(clk_i),
	.ld(ld_dv[0]),
	.abort(1'b0),
	.sgn(1'b1),
	.sgnus(1'b0),
	.a({{16{a[31]}},a,16'd0}),
	.b({{32{b[31]}},b}),
	.qo(dv1_qo),
	.ro(dv1_ro),
	.dvByZr(),
	.done(dv_done[0]),
	.idle()
);

FT64_divider #(64) udv2 (
	.rst(rst_i),
	.clk(clk_i),
	.ld(ld_dv[1]),
	.abort(1'b0),
	.sgn(1'b1),
	.sgnus(1'b0),
	.a({{16{a[31]}},a,16'd0}),
	.b({{32{b[31]}},b}),
	.qo(dv2_qo),
	.ro(dv2_ro),
	.dvByZr(),
	.done(dv_done[1]),
	.idle()
);
/*
FT64_divider #(64) udv3 (
	.rst(rst_i),
	.clk(clk_i),
	.ld(ld_dv[2]),
	.abort(1'b0),
	.sgn(1'b1),
	.sgnus(1'b0),
	.a({{16{a[31]}},a,16'd0}),
	.b({{32{b[31]}},b}),
	.qo(dv3_qo),
	.ro(dv3_ro),
	.dvByZr(),
	.done(dv_done[2]),
	.idle()
);

FT64_divider #(64) udv4 (
	.rst(rst_i),
	.clk(clk_i),
	.ld(ld_dv[3]),
	.abort(1'b0),
	.sgn(1'b1),
	.sgnus(1'b0),
	.a({{16{a[31]}},a,16'd0}),
	.b({{32{b[31]}},b}),
	.qo(dv4_qo),
	.ro(dv4_ro),
	.dvByZr(),
	.done(dv_done[3]),
	.idle()
);
*/

always @(posedge clk_i)
if (rst_i) begin
	pc <= 32'hFFFC0100;
	imem_adr <= 32'hFFFC0100;
	call (DELAY3,IFETCH);
	tstate <= TRANSFORM4;
	sstate <= ST_IDLE;
	cyc <= 1'b0;
	we_o <= 1'b0;
	adr_o <= 32'h0;
end
else begin
	ld_dv <= 4'b0;

case(sstate)
ST_IDLE:
	;
ST2:
	if (acki) begin
		cyc <= 1'b0;
		we_o <= 1'b0;
		sstate <= ST_IDLE;
	end
endcase

case(tstate)
TRANSFORM1:
	begin
		a1 <= aa;
		b1 <= ab;
		c1 <= ac;
		x1 <= at;
		tstkstate <= TRANSFORM2;
		tstate <= TDELAY3;
	end
TRANSFORM2:
	begin
		aax <= pax;
		bax <= pbx;
		cax <= pcx;
		a1 <= ab;
		b1 <= bb;
		c1 <= cb;
		x1 <= bt;
		tstkstate <= TRANSFORM3;
		tstate <= TDELAY3;
	end
TRANSFORM3:
	begin
		aby <= pax;
		bby <= pbx;
		cby <= pcx;
		a1 <= ac;
		b1 <= bc;
		c1 <= cc;
		x1 <= ct;
		tstkstate <= TRANSFORM4;
		tstate <= TDELAY3;
	end
TRANSFORM4:
	begin
		acz <= pax;
		bcz <= pbx;
		ccz <= pcx;
	end
TDELAY3:	tstate <= TDELAY2;
TDELAY2:	tstate <= TDELAY1;
TDELAY1:	tstate <= tstkstate;
endcase

case(state)
IFETCH:
	begin
		ir <= imem_o;
		pc <= pc + 16'd4;
		imem_adr <= pc + 16'd4;
		goto (DECODE);
	end
DECODE:
	begin
		goto (EXECUTE);
		if (Ra==5'd0)
			a <= 32'd0;
		else
			a <= rfoa;
		if (Rb==5'd0)
			b <= 32'd0;
		else
			b <= rfob;
		if (Rc==5'd0)
			c <= 32'd0;
		else
			c <= rfoc;
		if (ir[5:0]==i_st)
			imm <= {{18{ir[31]}},ir[31:23],ir[17:13]};
		else 
			imm <= {{18{ir[31]}},ir[31:18]};
		Rt <= 5'd0;
		if (qrfw)
			case(ir[5:0])
			i_r2:
				case(ir[31:26])
				i_r1, i_shifti:	Rt <= ir[17:13];
				default:	Rt <= ir[17:13];
				endcase
			i_lui:	Rt <= ir[17:13];
			default:	Rt <= ir[17:13];
			endcase
		// Multi-cycle ops
		else begin
			case(ir[5:0])
			i_r2:
				case(ir[31:26])
				i_fxdiv,
				i_fxmul,i_mul:	Rt <= ir[17:13];
				i_lhx,i_lcx:	Rt <= ir[17:13];
				default:	Rt <= 5'd0;
				endcase
			i_fxmuli,i_muli:	Rt <= ir[17:13];
			i_bb_:	Rt <= 5'd0;
			i_call:	Rt <= 5'd29;
			i_ret:	Rt <= 5'd31;
			i_ld:		Rt <= ir[17:13];
			default:	Rt <= 5'd0;
			endcase
		end
	end
EXECUTE:
	begin
		if (qrfw)
			call (WRITEBACK,IFETCH);
		case(ir[5:0])
		i_r2:
			begin
			case(ir[31:26])
			i_r1:
				case(ir[22:18])
				i_abs:	res <= a[31] ? -a : a;
				i_com:	res <= ~a;
				i_not:	res <= a != 32'd0;
				i_redor:	res <= |a;
				i_zxb:	res <= {24'd0,a[7:0]};
				i_zxc:	res <= {16'd0,a[15:0]};
				i_sxb:	res <= {{24{a[7]}},a[7:0]};
				i_sxc:	res <= {{16{a[15]}},a[15:0]};
				i_4to8:	res <= color4to8;
				i_8to4:	res <= color8to4;
				i_popr:	begin popr(); call (DELAY2,IFETCH); end
				i_rdcmdcnt:	res <= cmd_count;
				default:	;
				endcase
			i_add:	res <= a + b;
			i_sub:	res <= a - b;
			i_fxmul:	goto (FXMUL1);
			i_fxdiv:
				if (ir[25]) begin
						case(a[1:0])
						2'd0:	if (!dv_done[0]) goto (EXECUTE); else begin res <= dv1_qo[31:0]; call (WRITEBACK,IFETCH); end
						2'd1:	if (!dv_done[1]) goto (EXECUTE); else begin res <= dv2_qo[31:0]; call (WRITEBACK,IFETCH); end
						2'd2:	if (!dv_done[2]) goto (EXECUTE); else begin res <= dv3_qo[31:0]; call (WRITEBACK,IFETCH); end
						2'd3:	if (!dv_done[3]) goto (EXECUTE); else begin res <= dv4_qo[31:0]; call (WRITEBACK,IFETCH); end
						endcase
				end
				else begin
					if (dv_done[which_dv]) begin
						ld_dv[which_dv] <= 1'b1;
						which_dv <= which_dv + 1'd1;
						res <= which_dv;
						call (WRITEBACK,IFETCH);
					end
					else
						goto (EXECUTE);
				end
			i_mul:	goto (MUL1);
			i_and:	res <= a & b;
			i_or:		res <= a | b;
			i_xor:	res <= a ^ b;
			i_nand:	res <= ~(a & b);
			i_nor:	res <= ~(a | b);
			i_xnor:	res <= ~(a ^ b);
			i_slt:	res <= $signed(a) < $signed(b);
			i_sltu:	res <= a < b;
			i_sle:	res <= $signed(a) <= $signed(b);
			i_sleu:	res <= a <= b;
			i_shifti:	goto (SHIFT);
			i_shiftr: goto (SHIFT);
			i_testscn: res <= (scanpos & a) > b;
			i_testclip:	goto (SHIFT);
			i_min:	res <= $signed(a) < $signed(b) ? a : b;
			i_max:	res <= $signed(a) > $signed(b) ? a : b;
			i_lcx:
				begin
					ea <= a + (b << ir[24:23]);
					ea[0] <= 1'b0;
					memsize = char;
					goto (LD1);
				end
			i_lhx:
				begin
					ea <= a + (b << ir[24:23]);
					ea[1:0] <= 1'b0;
					memsize = half;
					goto (LD1);
				end
			endcase
			case({ir[31:28],ir[17:16]})
			i_scx:
				begin
					ea <= a + (b << ir[14:13]);
					ea[0] <= 1'b0;
					d <= c;
					memsize = char;
					goto (ST1);
				end
			i_shx:
				begin
					ea <= a + (b << ir[14:13]);
					ea[1:0] <= 1'b0;
					d <= c;
					memsize = half;
					goto (ST1);
				end
				endcase
			end
		i_lui:	res <= {ir[31:18],ir[12:8],14'h0};
		i_addi:	res <= a + imm;
		i_andi:	res <= a & imm;
		i_ori:	res <= a | imm;
		i_xori:	res <= a ^ imm;
		i_xnori:	res <= ~(a ^ imm);
		i_slti:	res <= $signed(a) < $signed(b);
		i_sltui:	res <= a < b;
		i_sgti:	res <= $signed(a) > $signed(b);
		i_sgtui:	res <= a > b;
		i_csr:	read_csr(ir[27:18], res);
		i_blend:	goto (BLEND1);
		i_transform:	
			if (ir[25])
				goto (TRANSFORM5);
			else begin
				at <= a;
				bt <= b;
				ct <= c;
				tstate <= TRANSFORM1;
				goto (IFETCH);
			end
		i_bb_,i_bcc,i_beqi:
			begin
				br_target <= pc + {{20{ir[31]}},ir[31:23],ir[17],2'b0};
				goto (BR);
			end
		i_jmp:	begin pc <= {ir[31:9],2'b0}; imem_adr <= {ir[31:9],2'b0}; call (DELAY3,IFETCH); end
		i_call:	begin res <= pc; pc <= {ir[31:9],2'b0}; imem_adr <= {ir[31:9],2'b0}; call (DELAY2,LD3); end
		i_ret:	begin pc <= b; imem_adr <= b; res <= a + {ir[31:23],3'b0}; call (DELAY2,LD3); end
		i_ld:	
			begin
				ea <= a + imm;
				if (ir[19:18]==2'b10) begin
					memsize = half;
					ea[1:0] <= 2'd0;
				end
				else begin
					memsize = char;
					ea[0] <= 1'd0;
				end
				goto (LD1);
			end
		i_st:
			begin
				ea <= a + imm;
				if (ir[14:13]==2'b10) begin
					ea[1:0] <= 2'd0;
					memsize = half;
				end
				else begin
					ea[0] <= 1'd0;
					memsize = char;
				end
				d <= b;
				goto (ST1);
			end
		endcase
	end
SHIFT:
	begin
		case(ir[31:26])
		i_shifti:
			case(ir[25:23])
			i_shl:	res <= shlor;
			i_shr:	res <= shror;
			i_asr:	res <= asror;
			default:	;
			endcase
		i_shiftr:
			case(ir[25:23])
			i_shl:	res <= shloi;
			i_shr:	res <= shroi;
			i_asr:	res <= asroi;
			default:	;
			endcase
		i_testclip:	res <= clp;
		endcase
		call (WRITEBACK,IFETCH);
	end
// Branches are given an extra state in order to calculate takb in a registered
// fashion.
BR:
	case(ir[5:0])
	i_bb_:
		if (takb) begin
			pc <= br_target;
			imem_adr <= br_target;
			call (DELAY3,IFETCH);
		end
		else
			call(DELAY1,IFETCH);
	i_bcc,i_beqi:
		if (takb) begin
			pc <= br_target;
			imem_adr <= br_target;
			call (DELAY3,IFETCH);
		end
		else
			call(DELAY1,IFETCH);
	default:	goto (IFETCH);
	endcase
WRITEBACK:
	begin
		regfile[Rt] <= res;
		return();
	end
LD1:
	if (~acki & ~cyc) begin
		cyc <= 1'b1;
		adr_o <= ea;
		imem_adr <= ea[14:0];
		if (memsize==half)
			sel_o <= 4'hF;
		else
			sel_o <= ea[1] ? 4'b1100 : 4'b0011;
		goto (LD2);
	end
LD2:
	if (acki) begin
		cyc <= 1'b0;
		if (memsize==half)
			res <= dati;
		else
			res <= ea[1] ? {{16{dati[31]}},dati[31:16]} : {{16{dati[15]}},dati[15:0]};
		imem_adr <= pc;
		call (DELAY2,LD3);	// for pc
	end
LD3:
	call (WRITEBACK,IFETCH);
ST1:
	if (~acki & ~cyc) begin
		cyc <= 1'b1;
		we_o <= 1'b1;
		adr_o <= ea;
		if (memsize==half) begin
			sel_o <= 4'hF;
			dat_o <= d;
		end
		else begin
			sel_o <= ea[1] ? 4'b1100 : 4'b0011;
			dat_o <= {2{d[15:0]}};
		end
		sstate <= ST2;
		goto (IFETCH);
	end
FXMUL1:	call(DELAY3,FXMUL2);
FXMUL2:
	begin
		res <= prod2[47:16];
		call (WRITEBACK,IFETCH);
	end
MUL1:	call(DELAY3,MUL2);
MUL2:
	begin
		res <= prod2[31:0];
		call (WRITEBACK,IFETCH);
	end
BLEND1:	goto (BLEND2);
BLEND2:	goto (BLEND3);
BLEND3:	
	begin
		Rt <= ir[27:23];
		res <= aprod2;
		call (WRITEBACK,IFETCH);
	end
TRANSFORM5:
	if (tstate==TRANSFORM4) begin
		Rt <= Ra;
		res <= x_prime[47:16];
		goto (TRANSFORM6);
	end
TRANSFORM6:
	begin
		Rt <= Rb;
		res <= y_prime[47:16];
		regfile[Rt] <= res;
		goto (TRANSFORM7);
	end
TRANSFORM7:
	begin
		Rt <= Rc;
		res <= z_prime[47:16];
		regfile[Rt] <= res;
		call (WRITEBACK,IFETCH);
	end
DELAY3:	goto (DELAY2);
DELAY2:	goto (DELAY1);
DELAY1:	return();
endcase

end

task read_csr;
input [9:0] csrno;
output [31:0] o;
begin
	case(csrno)
	csr_corenum:	o = corenum_i;
	default:	o = 32'd0;
	endcase
end
endtask

task goto;
input [5:0] nst;
begin
	state <= nst;
end
endtask;

task call;
input [5:0] nst;
input [5:0] rst;
begin
	stkstate <= rst;
	goto(nst);
end
endtask

task return;
begin
	state <= stkstate;
end
endtask

endmodule
