// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// FT64seq.v
// - FT64 processing core - sequential version
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
`define BRK		6'h00
`define R2		6'h02
`define R1			6'h01
`define ABS				5'h04
`define NOT             5'h05
`define Scc		6'h06
`define Sccu	6'h07
`define SUB			6'h05
`define SHIFTW		6'h0F
`define SHIFTB		6'h1F
`define SWINC		6'h19
`define LWINC		6'h1A
`define UNLINK		6'h1B
`define SYNC		6'h22
`define XCHG		6'h2E
`define SHIFTC		6'h2F
`define SEI			6'h30
`define RTI			6'h32
`define DIVMODU		6'h3C
`define DIVMODSU	6'h3D
`define DIVMOD		6'h3E
`define SHIFTH		6'h3F
`define BccR	6'h03
`define ADD		6'h04
`define CMP		6'h06
`define CMPU	6'h07
`define AND		6'h08
`define OR		6'h09
`define XOR		6'h0A
`define TGT		6'h0C
`define REX		6'h0D
`define CSR		6'h0E
`define LH		6'h10
`define LHU		6'h11
`define LW		6'h12
`define LB		6'h13
`define SH		6'h14
`define SB		6'h15
`define SW		6'h16
`define JAL		6'h18
`define CALL	6'h19
`define QOPI	6'h1A
`define QOR			3'd0
`define QADD		3'd1
`define QAND		3'd2
`define QXOR		3'd3
`define SccI	6'h1B
`define NOP		6'h1C
`define LC		6'h20
`define LCU		6'h21
`define LBU		6'h23
`define SC		6'h24
`define BBc0	6'h26
`define BBc1	6'h27
`define JMP		6'h28
`define RET		6'h29
`define LINK	6'h2A
`define CALLR	6'h2B
`define MODUI	6'h2C
`define MODSUI	6'h2D
`define MODI	6'h2E
`define Bcc0	6'h30
`define Bcc1	6'h31
`define BEQ0	6'h32
`define BEQ1	6'h33
`define MULU	6'h3A
`define MULSU	6'h39
`define MUL		6'h3A
`define DIVUI	6'h3C
`define DIVSUI	6'h3D
`define DIVI	6'h3E

`define SHL		4'h0
`define SHR		4'h1
`define ASL		4'h2
`define ASR		4'h3
`define ROL		4'h4
`define ROR		4'h5
`define SHLI	4'h8
`define SHRI	4'h9
`define ASLI	4'hA
`define ASRI	4'hB
`define ROLI	4'hC
`define RORI	4'hD

`define BEQ		4'h0
`define BNE		4'h1
`define BLT		4'h2
`define BGE		4'h3
`define BLTU	4'h4
`define BGEU	4'h5
`define FBEQ	4'h8
`define FBNE	4'h9
`define FBLT	4'hA
`define FBGE	4'hB

`define HARTID	11'h001
`define TICK	11'h002
`define CAUSE	11'h006
`define SCRATCH	11'h009
`define SEMA	11'h00C
`define TVEC	11'b000_0011_0???

module FT64seq(hartid_i, rst_i, clk_i, irq_i, cause_i,
	cyc_o, stb_o, ack_i, sel_o, we_o, adr_o, dat_i, dat_o,
	state);
input [63:0] hartid_i;
input rst_i;
input clk_i;
input [2:0] irq_i;
input [8:0] cause_i;
output reg cyc_o;
output reg stb_o;
input ack_i;
output reg [15:0] sel_o;
output reg we_o;
output reg [31:0] adr_o;
input [127:0] dat_i;
output reg [127:0] dat_o;
output reg [7:0] state;

parameter RST_ADDR = 32'hFFFC0100;
parameter RESET = 8'd0;
parameter IFETCH = 8'd1;
parameter REGFETCH = 8'd2;
parameter DECODE = 8'd3;
parameter EXECUTE = 8'd4;
parameter MEMORY = 8'd5;
parameter MEMORY2 = 8'd6;
parameter MULDIV2 = 8'd7;

integer n, m;
reg [63:0] sema;
reg [43:0] brkstack [0:4];
reg [31:0] tvec [0:7];
reg [2:0] ol;
reg [2:0] im;
reg [7:0] pl;
reg [31:0] pc;
reg [31:0] ir;
wire [5:0] opcode = ir[5:0];
wire [5:0] funct = ir[31:26];
wire [4:0] func5 = ir[25:21];
wire [3:0] func4 = ir[25:22];
reg [31:0] ibuf_adr [0:7];
reg [31:0] ibuf [0:7];
reg [2:0] ibuf_cnt;
reg rfwr;
reg [4:0] Ra, Rb, Rc, Rt;
reg [63:0] regfile [0:31];
wire [63:0] rfoa = regfile[Ra];
wire [63:0] rfob = regfile[Rb];
wire [63:0] rfoc = regfile[Rc];
reg [63:0] a,b,c,res;

// CSR's
reg [8:0] cause;
reg [63:0] scratch;
reg [63:0] tick;

wire [127:0] produ = a * b;
wire [127:0] prods = $signed(a) * $signed(b);
wire [127:0] prodsu = $signed(a) * b;
wire [2:0] npl = ir[23:16] | a;
wire [31:0] sum = a + b;
wire [31:0] eandx = a + (b << ir[22:21]);
wire [63:0] am8 = a - 32'd8;	// for link

always @*
begin
m <= 4'hF;
for (n = 0; n < 8; n = n + 1)
	if (pc==ibuf_adr[n])
		m <= n;
end

wire [7:0] byte_in = dat_i >> {adr_o[3:0],3'b0};
wire [15:0] char_in = dat_i >> {adr_o[3:1],4'h0};
wire [31:0] half_in = dat_i >> {adr_o[3:2],5'h0};
wire [63:0] word_in = dat_i >> {adr_o[3],6'h0};

reg div_ld;
wire div_done;
wire [63:0] div_qo, div_ro;
wire div_sgn = opcode==`DIVI || opcode==`MODI || (opcode==`R2 && (funct==`DIVMOD));
wire div_sgnus = opcode==`DIVSUI || opcode==`MODSUI || (opcode==`R2 && (funct==`DIVMODSU));

FT64_divider udiv1
(
	.rst(rst_i),
	.clk(clk_i),
	.ld(div_ld),
	.abort(),
	.sgn(div_sgn),
	.sgnus(div_sgnus),
	.a(a),
	.b(b),
	.qo(div_qo),
	.ro(div_ro),
	.dvByZr(),
	.done(div_done),
	.idle()
);

//Evaluate branch condition
reg takb;
always @*
case(opcode)
`BccR:
	case(ir[24:21])
	`BEQ:	takb <= a==b;
	`BNE:	takb <= a!=b;
	`BLT:	takb <= $signed(a) < $signed(b);
	`BGE:	takb <= $signed(a) >= $signed(b);
	`BLTU:	takb <= a < b;
	`BGEU:	takb <= a >= b;
	default:	takb <= `TRUE;
	endcase
`Bcc0,`Bcc1:
	case(ir[19:16])
	`BEQ:	takb <= a==b;
	`BNE:	takb <= a!=b;
	`BLT:	takb <= $signed(a) < $signed(b);
	`BGE:	takb <= $signed(a) >= $signed(b);
	`BLTU:	takb <= a < b;
	`BGEU:	takb <= a >= b;
	default:	takb <= `TRUE;
	endcase
`BEQ0,`BEQ1:	takb <= a==b;
`BBc0,`BBc1:
	case(ir[19:17])
	3'd0:	takb <= a[ir[16:11]];	// BBS
	3'd1:	takb <= ~a[ir[16:11]];	// BBC
	default:	takb <= `TRUE;
	endcase
default:	takb <= `TRUE;
endcase

always @(posedge clk_i)
if (rst_i)
	state <= RESET;
else begin
div_ld <= `FALSE;
case(state)
RESET:
	begin
	im <= 3'd7;
	ol <= 3'd0;
	pl <= 8'h00;
	pc <= RST_ADDR;
	cyc_o <= `LOW;
	stb_o <= `LOW;
	we_o <= `LOW;
	sel_o <= 16'h0000;
	adr_o <= 32'hFFFFFFFF;
	goto(IFETCH);
	end
IFETCH:
	if (!cyc_o) begin
		if (irq_i > im) begin
			ir <= {13'd0,irq_i,1'b0,cause_i,`BRK};
			goto(DECODE);
		end
		else if (m[3]) begin
			cyc_o <= `HIGH;
			stb_o <= `HIGH;
			sel_o <= 16'hFFFF;
			adr_o <= pc;
		end
		else begin
			ir <= ibuf[m];
			pc <= pc + 32'd4;
			goto(DECODE);
		end
		if (rfwr)
			regfile[Rt] <= |Rt ? res : 64'd0;
		rfwr <= `FALSE;
	end
	else if (ack_i) begin
		ir <= half_in;
		ibuf[ibuf_cnt] <= half_in;
		ibuf_adr[ibuf_cnt] <= pc;
		ibuf_cnt <= ibuf_cnt + 3'd1;
		cyc_o <= `LOW;
		stb_o <= `LOW;
		sel_o <= 16'h0000;
		adr_o <= 32'hFFFFFFFF;
		pc <= pc + 32'd4;
		goto(DECODE);
	end
DECODE:
	begin
		goto(REGFETCH);
		Ra <= ir[10:6];
		Rb <= ir[15:11];
		Rc <= ir[20:16];
		case(opcode)
		`BRK:
			begin
				for (n = 0; n < 4; n = n + 1)
					brkstack[n+1] <= brkstack[n];
				brkstack[0] <= {pc[31:2],pl,ol,im};
				if (ir[15]==1'b0)
					im <= ir[18:16];
				ol <= 3'd0;
				pl <= 8'h00;
				pc <= tvec[0];
				goto(IFETCH);
			end
		`R2:
			begin
				Rt <= ir[20:16];
				case(funct)
				`RTI:
					begin
						pc <= {brkstack[0][43:14],2'b00};
						pl <= brkstack[0][13:6];
						ol <= brkstack[0][5:3];
						im <= brkstack[0][2:0];
						for (n = 0; n < 4; n = n + 1)
							brkstack[n] <= brkstack[n+1];
						sema[0] <= 1'b0;
						sema[{ir[21],ir[15:11]}] <= 1'b0;
						goto(IFETCH);
					end
				`R1:
					case(func5)
					`ABS,`NOT:	Rt <= ir[15:11];
					endcase
				`SYNC:	goto(IFETCH);
				`SB,`SC,`SH,`SW:	Rt <= 5'd0;
				`SWINC:
					Rt <= ir[20:16];
				endcase
			end
		`TGT:	goto(IFETCH);
		`REX:	Ra <= ir[10:6];
		`NOP:	goto(IFETCH);
		`JMP:
			begin
			pc <= {pc[31:28],ir[31:6],2'b00};
			goto(IFETCH);
			end
		`CALL:
			begin
			Ra <= 5'd31;
			Rt <= 5'd31;
			end
		`CALLR:
			begin
			Ra <= 5'd31;
			Rt <= 5'd31;
			end
		`JAL,`RET:
			begin
			Ra <= ir[10:6];
			Rt <= ir[15:11];
			end
		`CSR:
			begin
			Ra <= ir[10:6];
			Rt <= ir[15:11];
			end
		`QOPI:	Ra <= ir[15:11];
		`ADD,`CMP,`CMPU,`AND,`OR,`XOR,
		`MUL,`MULU,`MULSU,
		`DIVI,`DIVUI,`DIVSUI,`MODI,`MODUI,`MODSUI,
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LWINC:
			Rt <= ir[15:11];
		`SB,`SC,`SH,`SW:
			Rt <= 5'd0;
		endcase
	end
REGFETCH:
	begin
		goto(EXECUTE);
		case(opcode)
		`R2:
			case(funct)
			`R1:
				case(func5)
				`ABS,`NOT:	a <= rfoa;
				endcase
			`SHIFTW,`SHIFTB,`SHIFTC,`SHIFTH:
				begin
				a <= rfoa;
				case(func4)
				`SHL,`SHR,`ASL,`ASR,`ROL,`ROR:
					b <= rfob;
				`SHLI,`SHRI,`ASLI,`ASRI,`ROLI,`RORI:
					b <= {ir[21],ir[15:11]};
				endcase
				end
			`ADD,`Scc,`Sccu,
			`AND,`OR,`XOR,
			`MUL,`MULU,`MULSU:
				begin
				a <= rfoa;
				b <= rfob;
				end
			`DIVMOD,`DIVMODU,`DIVMODSU:
				begin
				a <= rfoa;
				b <= rfob;
				div_ld <= `TRUE;
				end
			`LB,`LBU,`LH,`LHU,`LC,`LCU,`LW,
			`SB,`SC,`SH,`SW:
				begin
				a <= rfoa;
				b <= rfob;
				c <= rfoc;
				end
			endcase
		`ADD,`CMP,`MUL:
			begin
			a <= rfoa;
			b <= {{48{ir[31]}},ir[31:16]};
			end
		`DIVI,`MODI:
			begin
			a <= rfoa;
			b <= {{48{ir[31]}},ir[31:16]};
			div_ld <= `TRUE;
			end
		`SccI:
			begin
			a <= rfoa;
			case(ir[31:28])
			4'h2,4'h3,4'h4,4'h5,4'h6,4'h7:
				b <= {{52{ir[27]}},ir[27:16]};
			4'hC,4'hD,4'hE,4'hF:
				b <= {{52{1'b0}},ir[27:16]};
			endcase
			end
		`AND:
			begin
			a <= rfoa;
			b <= {{48{1'b1}},ir[31:16]};
			end
		`CMPU,`OR,`XOR,`MULU,`MULSU:
			begin
			a <= rfoa;
			b <= {{48{1'b0}},ir[31:16]};
			end
		`DIVUI,`DIVSUI,`MODUI,`MODSUI:
			begin
			a <= rfoa;
			b <= {{48{1'b0}},ir[31:16]};
			div_ld <= `TRUE;
			end
		`XCHG:
			begin
			b <= rfob;
			c <= rfoc;
			end
		`QOPI:
			begin
				a <= rfoa;
				case(ir[10:8])
				3'd0,3'd3:	// OR, XOR
					case(ir[7:6])
					2'd0:	b <= {{48{1'b0}},ir[31:16]};
					2'd1:	b <= {{32{1'b0}},ir[31:16]} << 16;
					2'd2:	b <= {{16{1'b0}},ir[31:16]} << 32;
					2'd3:	b <= {ir[31:16]} << 48;
					endcase
				3'd1:	// ADD
					case(ir[7:6])
					2'd0:	b <= {{48{ir[31]}},ir[31:16]};
					2'd1:	b <= {{32{ir[31]}},ir[31:16]} << 16;
					2'd2:	b <= {{16{ir[31]}},ir[31:16]} << 32;
					2'd3:	b <= {ir[31:16]} << 48;
					endcase
				3'd2:	// AND
					case(ir[7:6])
					2'd0:	b <= {{48{1'b1}},ir[31:16]};
					2'd1:	b <= {{32{1'b1}},ir[31:16],16'hFFFF};
					2'd2:	b <= {{16{1'b1}},ir[31:16],32'hFFFFFFFF};
					2'd3:	b <= {ir[31:16],48'hFFFFFFFFFFFF};
					endcase
				default:	b <= 64'd0;
				endcase
			end
		`Bcc0,`Bcc1,`BccR,`BBc0,`BBc1:
			begin
			a <= rfoa;
			b <= rfob;
			c <= rfoc;
			end
		`BEQ0,`BEQ1:
			begin
			a <= rfoa;
			b <= {{55{ir[19]}},ir[19:11]};
			end
		`JAL:
			begin
			a <= rfoa;
			b <= {{48{ir[31]}},ir[31:16]};
			end
		`CALL:
			begin
			a <= rfoa;
			b <= 64'hFFFFFFFFFFFFFFF8;	// -8
			end
		`CALLR:
			begin
			a <= rfoa;
			b <= rfob;
			end
		`RET:
			begin
			a <= rfoa;
			b <= {{48{ir[31]}},ir[31:16]};	// +8
			end
		`REX:	a <= rfoa;
		`CSR:	a <= rfoa;
		`LB,`LBU,`LH,`LHU,`LC,`LCU,`LW,
		`SB,`SC,`SH,`SW:
			begin
			a <= rfoa;
			b <= {{48{ir[31]}},ir[31:16]};
			c <= rfob;
			end
		`SWINC:
			begin
			a <= rfoa;
			c <= rfob;
			end
		endcase
	end
EXECUTE:
	begin
		goto(IFETCH);
		case(opcode)
		`R2:
			case(funct)
			`R1:
				case(func5)
				`ABS:	begin res <= a[63] ? -a : a; rfwr <= `TRUE; end
				`NOT:   begin res <= a!=0 ? 64'd0 : 64'd1; rfwr <= `TRUE; end
				endcase
			`SEI:	im <= a[2:0] | ir[13:11];
			`UNLINK:
				begin
					res <= b + 32'd8;
					rfwr <= `TRUE;
					cyc_o <= `HIGH;
					stb_o <= `HIGH;
					sel_o <= 16'h0FF << {b[3],3'b0};
					adr_o <= b;
					goto(MEMORY);
				end
			`SHIFTW:
				case(func4)
				`SHL,`SHLI:	res <= a << b[5:0];
				`SHR,`SHRI:	res <= a >> b[5:0];
				`ASL,`ASLI:	res <= a << b[5:0];
				`ASR,`ASRI:	res <= a[63] ? ~(64'hFFFFFFFFFFFFFFFF >> b[5:0]) | (a >> b[5:0])
								: a >> b[5:0];
				`ROL,`ROLI: res <= (a << b[5:0]) | (a >> (7'd64 - b[5:0]));
				`ROR,`RORI: res <= (a >> b[5:0]) | (a << (7'd64 - b[5:0]));
				endcase
			`ADD:	begin res <= a + b; rfwr <= `TRUE; end
			`Scc:	begin
					rfwr <= `TRUE;
					case(ir[25:23])
					3'd0:	res <= $signed(a) < $signed(b) ? 64'hFFFFFFFFFFFFFFFF : a==b ? 64'h0 : 64'h1;
					3'd2:	res <= a==b;
					3'd3:	res <= a!=b;
					3'd4:	res <= $signed(a) < $signed(b);
					3'd5:	res <= $signed(a) >= $signed(b);
					3'd6:	res <= $signed(a) <= $signed(b);
					3'd7:	res <= $signed(a) > $signed(b);
					endcase
					end
			`Sccu:	begin
					rfwr <= `TRUE;
					case(ir[25:23])
					3'd0:	res <= a < b ? 64'hFFFFFFFFFFFFFFFF : a==b ? 64'h0 : 64'h1;
					3'd2:	res <= a==b;
					3'd3:	res <= a!=b;
					3'd4:	res <= a < b;
					3'd5:	res <= a >= b;
					3'd6:	res <= a <= b;
					3'd7:	res <= a > b;
					endcase
					end
			`CMPU:	begin res <= a < b ? 64'hFFFFFFFFFFFFFFFF : a==b ? 64'h0 : 64'h1; rfwr <= `TRUE; end
			`MULU:	begin res <= produ[63:0]; rfwr <= `TRUE; goto(MULDIV2); end
			`MUL:	begin res <= prods[63:0]; rfwr <= `TRUE; goto(MULDIV2); end
			`MULSU:	begin res <= prodsu[63:0]; rfwr <= `TRUE; goto(MULDIV2); end
			`DIVMOD,`DIVMODU,`DIVMODSU:
					if (div_done) begin
						res <= div_qo;
						rfwr <= `TRUE;
						goto(MULDIV2);
					end
			`AND:	begin res <= a & b; rfwr <= `TRUE; end
			`OR:	begin res <= a | b; rfwr <= `TRUE; end
			`XOR:	begin res <= a ^ b; rfwr <= `TRUE; end
			`XCHG:	begin res <= b; Rt <= ir[20:16]; rfwr <= `TRUE; goto(MULDIV2); end
			`LB,`LBU:
				begin
					cyc_o <= `HIGH;
					stb_o <= `HIGH;
					sel_o <= 16'h01 << sum[3:0];
					adr_o <= eandx;
					goto(MEMORY);
				end
			`LC,`LCU:
				begin
					cyc_o <= `HIGH;
					stb_o <= `HIGH;
					sel_o <= 16'h03 << {sum[3:1],1'b0};
					adr_o <= eandx;
					goto(MEMORY);
				end
			`LH,`LHU:
				begin
					cyc_o <= `HIGH;
					stb_o <= `HIGH;
					sel_o <= 16'h0F << {sum[3:2],2'b0};
					adr_o <= eandx;
					goto(MEMORY);
				end
			`LW:
				begin
					cyc_o <= `HIGH;
					stb_o <= `HIGH;
					sel_o <= 16'hFF << {sum[3],3'b0};
					adr_o <= eandx;
					goto(MEMORY);
				end
			`SB:
				begin
					cyc_o <= `HIGH;
					stb_o <= `HIGH;
					we_o <= `HIGH;
					sel_o <= 16'h01 << sum[3:0];
					adr_o <= eandx;
					dat_o <= {16{c[7:0]}};
					goto(MEMORY);
				end
			`SC:
				begin
					cyc_o <= `HIGH;
					stb_o <= `HIGH;
					we_o <= `HIGH;
					sel_o <= 16'h03 << {sum[3:1],1'b0};
					adr_o <= eandx;
					dat_o <= {8{c[15:0]}};
					goto(MEMORY);
				end
			`SH:
				begin
					cyc_o <= `HIGH;
					stb_o <= `HIGH;
					we_o <= `HIGH;
					sel_o <= 16'h0F << {sum[3:2],2'b0};
					adr_o <= eandx;
					dat_o <= {4{c[31:0]}};
					goto(MEMORY);
				end
			`SW:
				begin
					cyc_o <= `HIGH;
					stb_o <= `HIGH;
					we_o <= `HIGH;
					sel_o <= 16'hFF << {sum[3],3'b0};
					adr_o <= eandx;
					dat_o <= {2{c}};
					goto(MEMORY);
				end
			endcase
		`ADD:	begin res <= a + b; rfwr <= `TRUE; end
		`CMP:	begin res <= $signed(a) < $signed(b) ? 64'hFFFFFFFFFFFFFFFF : a==b ? 64'h0 : 64'h1; rfwr <= `TRUE; end
		`CMPU:	begin res <= a < b ? 64'hFFFFFFFFFFFFFFFF : a==b ? 64'h0 : 64'h1; rfwr <= `TRUE; end
		`SccI:
				begin
				rfwr <= `TRUE;
				case(ir[31:28])
				4'd2:	res <= a==b;
				4'd3:	res <= a!=b;
				4'd4:	res <= $signed(a) < $signed(b);
				4'd5:	res <= $signed(a) >= $signed(b);
				4'd6:	res <= $signed(a) <= $signed(b);
				4'd7:	res <= $signed(a) > $signed(b);
				4'd12:	res <= a < b;
				4'd13:	res <= a >= b;
				4'd14:	res <= a <= b;
				4'd15:	res <= a > b;
				endcase
				end
		`MULU:	begin res <= produ[63:0]; rfwr <= `TRUE; end
		`MUL:	begin res <= prods[63:0]; rfwr <= `TRUE; end
		`MULSU:	begin res <= prodsu[63:0]; rfwr <= `TRUE; end
		`DIVI,`DIVUI,`DIVSUI,`MODI,`MODUI,`MODSUI:
				if (div_done) begin
					res <= div_qo;
					rfwr <= `TRUE;
				end
		`AND:	begin res <= a & b; rfwr <= `TRUE; end
		`OR:	begin res <= a | b; rfwr <= `TRUE; end
		`XOR:	begin res <= a ^ b; rfwr <= `TRUE; end
		`QOPI:
		      begin
		      rfwr <= `TRUE;
		      case(ir[10:8])
		      3'd0:   res <= a | b;
		      3'd1:   res <= a + b;
		      3'd2:   res <= a & b;
		      3'd3:   res <= a ^ b;
		      endcase
		      end
		`Bcc0,`Bcc1,`BEQ0,`BEQ1,`BBc0,`BBc1:
			if (takb)
				pc <= pc + {{21{ir[31]}},ir[31:22],ir[0],2'b00};
		`BccR:
			if (takb)
				pc <= c;
		`JAL:
			begin
				pc <= {sum[31:2],2'b00};
				rfwr <= `TRUE;
				res <= pc;
			end
		`CALL:	
			begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				we_o <= `HIGH;
				sel_o <= 16'hFF << {am8[3],3'b0};
				adr_o <= am8;
				dat_o <= pc;
				pc <= {pc[31:28],ir[31:6],2'b00};
				goto(MEMORY);
			end
		`CALLR:
			begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				we_o <= `HIGH;
				sel_o <= 16'hFF << {am8[3],3'b0};
				adr_o <= am8;
				dat_o <= pc;
				pc <= b + {{48{ir[31]}},ir[31:16]};
				goto(MEMORY);
			end
		`RET:
			begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				sel_o <= 16'hFF << {a[3],3'b0};
				adr_o <= a;
				goto(MEMORY);
			end
		`REX:
			begin
				ol <= ir[13:11];
				case(ir[13:11])
				3'd0:		pl <= 8'h00;
				3'd1:		pl <= 8'h01;
				default:	pl <= (npl < 2) ? {5'd0,ir[13:11]} : npl;
				endcase
				if (ir[13:11]!=3'd0)
					pc <= tvec[ir[13:11]];
				im <= ir[26:24];
			end
		`CSR:
			begin
				case(ir[31:30])
				2'd0:	begin read_csr(ir[26:16],res); rfwr <= `TRUE; end
				default:begin
							rfwr <= `TRUE;
							read_csr(ir[26:16],res);
							write_csr(ir[26:16],ir[31:30],a);
						end
				endcase
			end
		`LINK:
			begin
				res <= am8;
				rfwr <= `TRUE;
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				we_o <= `HIGH;
				sel_o <= 16'h0FF << {am8[3],3'b0};
				adr_o <= am8;
				dat_o <= b;
				goto(MEMORY);
			end
		`LB,`LBU:
			begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				sel_o <= 16'h01 << sum[3:0];
				adr_o <= sum;
				goto(MEMORY);
			end
		`LC,`LCU:
			begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				sel_o <= 16'h03 << {sum[3:1],1'b0};
				adr_o <= sum;
				goto(MEMORY);
			end
		`LH,`LHU:
			begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				sel_o <= 16'h0F << {sum[3:2],2'b0};
				adr_o <= sum;
				goto(MEMORY);
			end
		`LW:
			begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				sel_o <= 16'hFF << {sum[3],3'b0};
				adr_o <= sum;
				goto(MEMORY);
			end
		`SB:
			begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				we_o <= `HIGH;
				sel_o <= 16'h01 << sum[3:0];
				adr_o <= sum;
				dat_o <= {16{c[7:0]}};
				goto(MEMORY);
			end
		`SC:
			begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				we_o <= `HIGH;
				sel_o <= 16'h03 << {sum[3:1],1'b0};
				adr_o <= sum;
				dat_o <= {8{c[15:0]}};
				goto(MEMORY);
			end
		`SH:
			begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				we_o <= `HIGH;
				sel_o <= 16'h0F << {sum[3:2],2'b0};
				adr_o <= sum;
				dat_o <= {4{c[31:0]}};
				goto(MEMORY);
			end
		`SW:
			begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				we_o <= `HIGH;
				sel_o <= 16'hFF << {sum[3],3'b0};
				adr_o <= sum;
				dat_o <= {2{c}};
				goto(MEMORY);
			end
		`SWINC:
			begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				we_o <= `HIGH;
				sel_o <= 16'hFF << {sum[3],3'b0};
				adr_o <= ir[25] ? a + {{27{ir[25]}},ir[25:21]} : a;
				dat_o <= {2{c}};
				goto(MEMORY);
			end
		endcase
	end
MEMORY:
	if (ack_i) begin
		goto(IFETCH);
		if (rfwr)
			regfile[Rt] <= |Rt ? res : 64'd0;
		cyc_o <= `LOW;
		stb_o <= `LOW;
		we_o <= `LOW;
		sel_o <= 16'h0000;
		adr_o <= 32'hFFFFFFFF;
		case(opcode)
		`R2:
			case(funct)
			`UNLINK:	begin res <= word_in; Rt <= Rb; rfwr <= `TRUE; end
			endcase	
		`LINK:	begin res <= a + {{48{ir[31]}},ir[31:16]}; Rt <= Ra; rfwr <= `TRUE; end
		`CALL:	begin res <= am8; rfwr <= `TRUE; end
		`CALLR:	begin res <= am8; rfwr <= `TRUE; end
		`RET:	begin res <= sum; rfwr <= `TRUE; pc <= {word_in[31:2],2'b0}; end
		`LB:	begin res <= {{56{byte_in[7]}},byte_in}; rfwr <= `TRUE; end
		`LBU:	begin res <= {{56{1'b0}},byte_in}; rfwr <= `TRUE; end
		`LC:	begin res <= {{48{char_in[15]}},char_in}; rfwr <= `TRUE; end
		`LCU:	begin res <= {{48{1'b0}},char_in}; rfwr <= `TRUE; end
		`LH:	begin res <= {{32{half_in[31]}},half_in}; rfwr <= `TRUE; end
		`LHU:	begin res <= {{32{1'b0}},half_in}; rfwr <= `TRUE; end
		`LW:	begin res <= word_in; rfwr <= `TRUE; end
		`LWINC:	begin res <= word_in; rfwr <= `TRUE; goto(MEMORY2); end
		`SWINC: begin res <= a + {{27{ir[25]}},ir[25:21]}; rfwr <= `TRUE; end
		endcase
	end
	// Extra state needed for LWINC
MEMORY2:
	begin
		if (rfwr)
			regfile[Rt] <= |Rt ? res : 64'd0;
		Rt <= ir[20:16];
		res <= a + {{27{ir[25]}},ir[25:21]};	
		goto(IFETCH);	
	end
MULDIV2:
	begin
		if (rfwr)
			regfile[Rt] <= |Rt ? res : 64'd0;
		Rt <= ir[25:21];
		case(funct)
		`MUL:	res <= prods[127:64];
		`MULU:	res <= produ[127:64];
		`MULSU:	res <= prodsu[127:64];
		`DIVMOD,`DIVMODU,`DIVMODSU:
				res <= div_ro;
		`XCHG:	begin res <= c; Rt <= ir[15:11]; end
		endcase
		goto(IFETCH);	
	end

endcase
end

task read_csr;
input [11:0] regno;
output [63:0] val;
begin
	casez(regno)
	`HARTID:	val <= hartid_i;
	`TICK:	val <= tick;
	`CAUSE:	val <= {55'd0,cause};
	`SCRATCH:	val <= scratch;
	`SEMA:	val <= sema;
	`TVEC:	val <= tvec[regno[2:0]];
	endcase
end
endtask

task write_csr;
input [11:0] regno;
input [1:0] op;
input [63:0] val;
begin
	case(op)
	2'd0:	;	// read only
	2'd1:
		casez(regno)
		`CAUSE:	cause <= val[8:0];
		`SCRATCH:	scratch <= val;
		`SEMA:	sema <= val;
		`TVEC:	tvec[regno[2:0]] <= val;
		endcase
	2'd2:
		casez(regno)
		`SEMA:	sema <= sema | val;
		endcase
	2'd3:
		casez(regno)
		`SEMA:	sema <= sema & ~val;
		endcase
	endcase
end
endtask

task goto;
input [7:0] st;
begin
	state <= st;
end
endtask

endmodule
