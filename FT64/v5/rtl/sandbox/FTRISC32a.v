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
	cmd_core_i, cmd_clk_i, wr_cmd_i, cmd_adr_i, cmd_dat_i, cmd_count_o, 
	cyc_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o,
	dot_clk_i, scan_adr_i, scan_dat_o);
input [14:0] corenum_i;
input rst_i;
input clk_i;
input [14:0] cmd_core_i;
input cmd_clk_i;
input wr_cmd_i;
input [7:0] cmd_adr_i;
input [31:0] cmd_dat_i;
output [6:0] cmd_count_o;
output reg cyc_o;
input ack_i;
output reg we_o;
output reg [3:0] sel_o;
output reg [31:0] adr_o;
input [31:0] dat_i;
output reg [31:0] dat_o;
input dot_clk_i;
input [14:0] scan_adr_i;
output [15:0] scan_dat_o;

parameter i_r2 = 6'h02;
parameter i_r1  = 6'h01;
parameter i_com = 5'h03;
parameter i_abs = 5'h04;
parameter i_not = 5'h05;
parameter i_redor = 5'h06;
parameter i_zxb = 5'h0A;
parameter i_4to8 = 5'h0B;
parameter i_2to8 = 5'h0C;
parameter i_zxh = 5'h09;
parameter i_popr  = 5'h0E;
parameter i_divwait = 5'h13;
parameter i_modwait = 5'h17;
parameter i_sxh = 5'h19;
parameter i_sxb = 5'h1A;
parameter i_8to4 = 5'h1B;
parameter i_8to2 = 5'h1C;
parameter i_rdcmd = 5'h1E;
parameter i_rdcmdcnt = 5'h1F;

parameter i_add = 6'h04;
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
parameter i_blend = 6'h10;
parameter i_transform = 6'h11;
parameter i_shl		= 3'h0;
parameter i_shr		= 3'h1;
parameter i_asr		= 3'h3;
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
parameter i_xnori = 6'h0E;
parameter i_jal  = 6'h18;
parameter i_call = 6'h19;
parameter i_sgtui = 6'h1C;
parameter i_ld   = 6'h20;
parameter i_st   = 6'h24;
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

parameter IDLE = 6'd0;
parameter IFETCH = 6'd1;
parameter DECODE = 6'd2;
parameter EXECUTE = 6'd3;
parameter WRITEBACK = 6'd4;
parameter LD1 = 6'd5;
parameter LD2 = 6'd6;
parameter LD3 = 6'd7;
parameter ST1 = 6'd8;
parameter ST2 = 6'd9;
parameter BLEND1 = 6'd10;
parameter BLEND2 = 6'd11;
parameter BLEND3 = 6'd12;
parameter TRANSFORM1 = 6'd13;
parameter TRANSFORM2 = 6'd14;
parameter TRANSFORM3 = 6'd15;
parameter TRANSFORM4 = 6'd16;
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

integer n;
reg [5:0] state;
reg [5:0] stkstate;
reg [13:0] pc;
reg [31:0] ir;
reg [31:0] control;
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

reg [1:0] which_dv;
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

(* ram_style="distributed" *)
reg [31:0] regfile [0:31];
reg [12:0] imem_adr;
(* ram_style="block" *)
reg [31:0] imem [0:4095];
initial begin
	for (n = 0; n < 4096; n = n + 1)
		imem[n] <= n;
end
reg [31:0] imem_o;
always @(posedge clk_i)
	imem_o <= imem[imem_adr];

wire cs_imem = adr_o[31:16]==16'hFFFC;
wire cs_ram  = adr_o[31:16]==16'h0010;
wire cs_cmd  = adr_o[31: 8]==24'hFFD000;
always @*
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
	i_shifti, i_shiftr, i_min, i_max:
		qrfw <= 1'b1;
	i_r1:
		case(ir[22:18])
		i_abs, i_com, i_not, i_redor, i_zxb, i_zxh, i_sxb, i_sxh,
		i_4to8, i_8to4, i_2to8, i_8to2, i_rdcmdcnt:
			qrfw <= 1'b1;
		default:	qrfw <= 1'b0;
		endcase
	default:	qrfw <= 1'b0;
	endcase
i_addi, i_csr, i_slti, i_sltui, i_andi, i_ori, i_xori, i_xnori,
i_jal, i_ret, i_sgtui, i_sgti, i_ld, i_lui:
	qrfw <= 1'b1;
default:	qrfw <= 1'b0;
endcase

reg takb;
always @*
case(ir[31:26])
i_bcc:
	case (ir[20:18])
	i_beq:	takb <= a == b;
	i_bne:	takb <= a != b;
	i_blt:	takb <= $signed(a) < $signed(b);
	i_bge:	takb <= $signed(a) >= $signed(b);
	i_bltu:	takb <= a < b;
	i_bgeu:	takb <= a >= b;
	default	takb <= 1'b0;
	endcase
i_beqi:	takb <= a == {{24{ir[20]}},ir[20:13]};
default:	takb <= 1'b0;
endcase

reg [13:0] r0;
(* ram_style="distributed" *)
reg [13:0] rstack [0:63];
(* ram_style="distributed" *)
reg [31:0] dstack [0:63];
reg [31:0] s0;

wire [4:0] Ra = ir[12:8];
wire [4:0] Rb = ir[17:13];
wire [4:0] Rc = ir[22:18];
reg [4:0] Rt;

wire [31:0] rfoa = regfile[Ra];
wire [31:0] rfob = regfile[Rb];
wire [31:0] rfoc = regfile[Rc];
reg [31:0] a, b, c, imm, res, ea;

wire signed [63:0] prod = $signed(a) * $signed(b);
reg [63:0] prod1, prod2;
always @(posedge clk_i)
	prod1 <= prod;
always @(posedge clk_i)
	prod2 <= prod1;

wire [31:0] color4to8 = {a[15:12],4'h0,a[11:8],4'h0,a[7:4],4'h0,a[3:0],4'h0};
wire [31:0] color8to4 = {a[31:28],a[23:20],a[15:12],a[7:4]};
wire [15:0] aprod_r = (alpha * a[23:16]) + (~alpha * b[23:16]);
wire [15:0] aprod_g = (alpha * a[15: 8]) + (~alpha * b[15: 8]);
wire [15:0] aprod_b = (alpha * a[ 7: 0]) + (~alpha * b[ 7: 0]);
wire [31:0] aprod = {a[31:24],aprod_r[15:8],aprod_g[15:8],aprod_b[15:8]};
reg [31:0] aprod1,aprod2;
always @(posedge clk_i)
	aprod1 <= aprod;
always @(posedge clk_i)
	aprod2 <= aprod1;

reg [31:0] a1, b1, c1, x1;
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
if (rd_cmd) begin
	case(cmd_fifo[39:32])
	8'h00:	control <= cmd_fifo[31:0];
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

FT_GPURam ulr1
(
  .clka(clk_i),
  .ena(cyc_o & cs_ram),
  .wea({4{we_o}} & sel_o),
  .addra(adr_o[15:2]),
  .dina(dat_o),
  .douta(ram_dat),
  .clkb(dot_clk_i),
  .enb(1'b1),
  .web(2'b0),
  .addrb(scan_adr_i),
  .dinb(16'h0),
  .doutb(scan_dat_o)
);

ack_gen #(.READ_STAGES(3),
	.WRITE_STAGES(1),
	.REGISTER_OUTPUT(1)
) ag1
(
	.clk_i(clk_i),
	.ce_i(1'b1),
	.i(cyc_o && adr_o[15:14]!=2'b11),
	.we_i(we_o),
	.o(ram_ack)
);

wire imem_ack;
ack_gen #(.READ_STAGES(3),
	.WRITE_STAGES(1),
	.REGISTER_OUTPUT(1)
) ag2
(
	.clk_i(clk_i),
	.ce_i(1'b1),
	.i(cs_imem & cyc_o),
	.we_i(1'b0),
	.o(imem_ack)
);

wire acki = ram_ack | ack_i | cs_cmd | imem_ack;

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

always @(posedge clk_i)
if (rst_i) begin
	pc <= 32'hFFFC0100;
	rd_cmd <= 1'b0;
	call (DELAY3,IFETCH);
end
else begin
	ld_dv <= 4'b0;
	rd_cmd <= 1'b0;
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
		imm <= {{18{ir[31]}},ir[31:18]};
		Rt <= 5'd0;
		if (qrfw)
			case(ir[5:0])
			i_r2:
				case(ir[31:26])
				i_r1, i_shifti:	Rt <= ir[17:13];
				default:	Rt <= ir[22:18];
				endcase
			i_lui:	Rt <= ir[12:8];
			i_ret:	Rt <= ir[12:8];
			default:	Rt <= ir[17:13];
			endcase
		// Multi-cycle ops
		else begin
			case(ir[5:0])
			i_r2:
				case(ir[31:26])
				i_fxdiv,
				i_fxmul,i_mul:	Rt <= ir[22:18];
				default:	Rt <= 5'd0;
				endcase
			i_fxmuli,i_muli:	Rt <= ir[17:13];
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
			case(ir[31:26])
			i_r1:
				case(ir[22:18])
				i_abs:	res <= a[31] ? -a : a;
				i_com:	res <= ~a;
				i_not:	res <= a != 32'd0;
				i_redor:	res <= |a;
				i_zxb:	res <= {24'd0,a[7:0]};
				i_zxh:	res <= {16'd0,a[15:0]};
				i_sxb:	res <= {{24{a[7]}},a[7:0]};
				i_sxh:	res <= {{16{a[15]}},a[15:0]};
				i_4to8:	res <= color4to8;
				i_8to4:	res <= color8to4;
				i_popr:	begin popr(); call (DELAY2,IFETCH); end
				i_divwait:
						case(a[1:0])
						2'd0:	if (!dv_done[0]) goto (EXECUTE); else begin Rt = Ra; res <= dv1_qo[31:0]; call (WRITEBACK,IFETCH); end
						2'd1:	if (!dv_done[1]) goto (EXECUTE); else begin Rt = Ra; res <= dv2_qo[31:0]; call (WRITEBACK,IFETCH); end
						2'd2:	if (!dv_done[2]) goto (EXECUTE); else begin Rt = Ra; res <= dv3_qo[31:0]; call (WRITEBACK,IFETCH); end
						2'd3:	if (!dv_done[3]) goto (EXECUTE); else begin Rt = Ra; res <= dv4_qo[31:0]; call (WRITEBACK,IFETCH); end
						endcase
				i_modwait:
						case(a[1:0])
						2'd0:	if (!dv_done[0]) goto (EXECUTE); else begin Rt = Ra; res <= dv1_ro[31:0]; call (WRITEBACK,IFETCH); end
						2'd1:	if (!dv_done[1]) goto (EXECUTE); else begin Rt = Ra; res <= dv2_ro[31:0]; call (WRITEBACK,IFETCH); end
						2'd2:	if (!dv_done[2]) goto (EXECUTE); else begin Rt = Ra; res <= dv3_ro[31:0]; call (WRITEBACK,IFETCH); end
						2'd3:	if (!dv_done[3]) goto (EXECUTE); else begin Rt = Ra; res <= dv4_ro[31:0]; call (WRITEBACK,IFETCH); end
						endcase
				i_rdcmd:	begin rd_cmd <= 1'b1; goto (IFETCH); end
				i_rdcmdcnt:	res <= cmd_count;
				default:	;
				endcase
			i_add:	res <= a + b;
			i_fxmul:	goto (FXMUL1);
			i_fxdiv:
				begin
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
			i_shifti:
				case(ir[25:23])
				i_shl:	res <= a << ir[22:18];
				i_shr:	res <= a >> ir[22:18];
				i_asr:	res <= a[31] ? (a >> ir[22:18]) | ~({32{1'b1}} >> ir[22:18]) : a >> ir[22:18];
				default:	;
				endcase
			i_shiftr:
				case(ir[25:23])
				i_shl:	res <= a << b[4:0];
				i_shr:	res <= a >> b[4:0];
				i_asr:	res <= a[31] ? (a >> b[4:0]) | ~({32{1'b1}} >> b[4:0]) : a >> b[4:0];
				default:	;
				endcase
			i_blend:	goto (BLEND1);
			endcase
		i_lui:	res <= {ir[31:13],14'h0};
		i_addi:	res <= a + imm;
		i_andi:	res <= a & imm;
		i_ori:	res <= a | imm;
		i_xori:	res <= a ^ imm;
		i_xnori:	res <= ~(a ^ imm);
		i_slti:	res <= $signed(a) < $signed(b);
		i_sltui:	res <= a < b;
		i_sgti:	res <= $signed(a) > $signed(b);
		i_sgtui:	res <= a > b;
		i_transform:	goto (TRANSFORM1);
		i_bcc,i_beqi:
			if (takb) begin
				pc <= pc + {{21{ir[31]}},ir[31:21]};
				imem_adr <= pc + {{21{ir[31]}},ir[31:21]};
				call (DELAY3,IFETCH);
			end
			else
				call(DELAY1,IFETCH);
		i_jmp:	begin pc <= ir[23:8]; imem_adr <= ir[23:8]; call (DELAY3,IFETCH); end
		i_call:	begin r0 <= pc + 16'd4; pushr(); pc <= ir[23:8]; imem_adr <= ir[23:8]; call (DELAY3,IFETCH); end
		i_ret:	begin pc <= r0; imem_adr <= r0; popr(); res <= a + imm; end
		i_ld:	
			begin
				ea <= a + imm;
				if (ir[19:18]==2'b10)
					ea[1:0] <= 2'd0;
				else
					ea[0] <= 1'd0;
				goto (LD1);
			end
		i_st:
			begin
				ea <= a + imm;
				if (ir[19:18]==2'b10)
					ea[1:0] <= 2'd0;
				else
					ea[0] <= 1'd0;
				goto (ST1);
			end
		endcase
	end
WRITEBACK:
	begin
		regfile[Rt] <= res;
		return();
	end
LD1:
	if (~acki) begin
		cyc_o <= 1'b1;
		adr_o <= ea;
		imem_adr <= ea[12:0];
		if (ir[19:18]==2'b10)
			sel_o <= 4'hF;
		else
			sel_o <= ea[1] ? 4'b1100 : 4'b0011;
		goto (LD2);
	end
LD2:
	if (acki) begin
		cyc_o <= 1'b0;
		if (ir[19:18]==2'b10)
			res <= dat_i;
		else
			res <= ea[1] ? {{16{dat_i[31]}},dat_i[31:16]} : {{16{dat_i[15]}},dat_i[15:0]};
		imem_adr <= pc;
		call (DELAY2,LD3);	// for pc
	end
LD3:
	call (WRITEBACK,IFETCH);
ST1:
	if (~acki) begin
		cyc_o <= 1'b1;
		we_o <= 1'b1;
		adr_o <= ea;
		if (ir[19:18]==2'b10) begin
			sel_o <= 4'hF;
			dat_o <= b;
		end
		else begin
			sel_o <= ea[1] ? 4'b1100 : 4'b0011;
			dat_o <= {2{b[15:0]}};
		end
		goto (ST2);
	end
ST2:
	if (acki) begin
		cyc_o <= 1'b0;
		we_o <= 1'b0;
		goto(IFETCH);
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
		Rt <= ir[22:18];
		res <= aprod2;
		call (WRITEBACK,IFETCH);
	end
TRANSFORM1:
	begin
		a1 <= aa;
		b1 <= ab;
		c1 <= ac;
		x1 <= a;
		call (DELAY3,TRANSFORM2);
	end
TRANSFORM2:
	begin
		aax <= pax;
		bax <= pbx;
		cax <= pcx;
		a1 <= ab;
		b1 <= bb;
		c1 <= cb;
		x1 <= b;
		call (DELAY3,TRANSFORM3);
	end
TRANSFORM3:
	begin
		aby <= pax;
		bby <= pbx;
		cby <= pcx;
		a1 <= ac;
		b1 <= bc;
		c1 <= cc;
		x1 <= c;
		call (DELAY3,TRANSFORM4);
	end
TRANSFORM4:
	begin
		acz <= pax;
		bcz <= pbx;
		ccz <= pcx;
	end
TRANSFORM5:
	begin
		Rt <= Ra;
		res <= x_prime[47:16];
		call (WRITEBACK,TRANSFORM6);
	end
TRANSFORM6:
	begin
		Rt <= Rb;
		res <= y_prime[47:16];
		call (WRITEBACK,TRANSFORM7);
	end
TRANSFORM7:
	begin
		Rt <= Rc;
		res <= z_prime[47:16];
		call (WRITEBACK,IFETCH);
	end
DELAY3:	goto (DELAY2);
DELAY2:	goto (DELAY1);
DELAY1:	return();
endcase
end

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

task push;
begin
	for (n = 0; n < 63; n = n + 1)
		dstack[n+1] <= dstack[n];
	dstack[0] <= s0;
end
endtask

task pop;
begin
	for (n = 0; n < 63; n = n + 1)
		dstack[n] <= dstack[n+1];
	s0 <= dstack[0];
end
endtask

task pushr;
begin
	for (n = 0; n < 63; n = n + 1)
		rstack[n+1] <= rstack[n];
	rstack[0] <= r0;
end
endtask

task popr;
begin
	for (n = 0; n < 63; n = n + 1)
		rstack[n] <= rstack[n+1];
	r0 <= rstack[0];
end
endtask

endmodule
