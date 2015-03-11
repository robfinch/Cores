`define TRUE	1'b1
`define FALSE	1'b0

`define RR		7'h02
`define ADD		7'h04
`define SUB		7'h05
`define CMP		7'h06
`define MUL		7'h07
`define DIV		7'h08
`define MOD		7'h09
`define LDI		7'h0A
`define MOV			7'h0B
`define AND		7'h0C
`define OR		7'h0D
`define EOR		7'h0E
`define SXB			7'h10
`define SXC			7'h11
`define SXH			7'h12
`define ADDU	7'h14
`define SUBU	7'h15
`define CMPU	7'h16
`define MULU	7'h17
`define DIVU	7'h18
`define MODU	7'h19
`define MTSPR		7'h1E
`define MFSPR		7'h1F
`define SEQ		7'h20
`define SNE		7'h21
`define SGT		7'h28
`define SLE		7'h29
`define SGE		7'h2A
`define SLT		7'h2B
`define SHI		7'h2C
`define SLS		7'h2D
`define SHS		7'h2E
`define SLO		7'h2F
`define BRK		7'h38
`define BSR		7'h39
`define BRA		7'h3A
`define RTS		7'h3B
`define JAL		7'h3C
`define Bcc		7'h3D
`define BEQ			3'h0
`define BNE			3'h1
`define BGT			3'h2
`define BGE			3'h3
`define BLT			3'h4
`define BLE			3'h5
`define NOP		7'h3F
`define SLL			7'h30
`define SRL			7'h31
`define ROL			7'h32
`define ROR			7'h33
`define SRA			7'h34
`define SLLI		7'h38
`define SRLI		7'h39
`define ROLI		7'h3A
`define RORI		7'h3B
`define SRAI		7'h3C

`define RTE			7'h3E
`define RTI			7'h3F
`define FENCE		7'h40
`define LB		7'h40
`define LBU		7'h41
`define LC		7'h42
`define LCU		7'h43
`define LH		7'h44
`define LHU		7'h45
`define LW		7'h46
`define LBX		7'h48
`define LBUX	7'h49
`define LCX		7'h4A
`define LCUX	7'h4B
`define LHX		7'h4C
`define LHUX	7'h4D
`define LWX		7'h4E
`define LEAX	7'h4F

`define SB		7'h60
`define SC		7'h61
`define SH		7'h62
`define SW		7'h63
`define INC		7'h64
`define SBX		7'h68
`define SCX		7'h69
`define SHX		7'h6A
`define SWX		7'h6B

`define SYSTEM	7'b1110011
`define SCALL		3'd0

`define CR0			8'd00
`define CR3			8'd03
`define TICK		8'd04
`define IPC			8'd08
`define EPC			8'd09
`define VBR			8'd10
`define EA			8'd40
`define TAGS		8'd41
`define LOTGRP		8'd42

`define BRK_NMI	{1'b1,5'd0,9'd510,10'd0,`BRK}
`define BRK_IRQ	{1'b1,5'd0,vect_i,10'd0,`BRK}
`define BRK_EXF	{6'd0,9'd497,10'd0,`BRK}

module FISA64(rst_i, clk_i, nmi_i, irq_i, vect_i, bte_o, cti_o, bl_o, cyc_o, stb_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o);
input rst_i;
input clk_i;
input nmi_i;
input irq_i;
input [8:0] vect_i;
output reg [1:0] bte_o;
output reg [2:0] cti_o;
output reg [5:0] bl_o;
output reg cyc_o;
output reg stb_o;
input ack_i;
output reg we_o;
output reg [7:0] sel_o;
output reg [31:0] adr_o;
input [63:0] dat_i;
output reg [63:0] dat_o;

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;

parameter RESET = 6'd1;
parameter IFETCH1 = 6'd2;
parameter IFETCH2 = 6'd3;
parameter DECODE = 6'd4;
parameter EXECUTE = 6'd5;
parameter LOAD1 = 6'd8;
parameter LOAD2 = 6'd9;
parameter LOAD3 = 6'd10;
parameter LOAD4 = 6'd11;
parameter LOAD5 = 6'd12;
parameter INC = 6'd16;
parameter STORE1 = 6'd17;
parameter STORE2 = 6'd18;
parameter STORE3 = 6'd19;
parameter STORE4 = 6'd20;
parameter STORE5 = 6'd21;
parameter LOAD_ICACHE = 6'd22;
parameter LOAD_ICACHE2 = 6'd23;
parameter LOAD_ICACHE3 = 6'd24;
parameter LOAD_ICACHE4 = 6'd25;
parameter RUN = 6'd26;
parameter PEA = 6'd27;
parameter MULDIV = 6'd32;
parameter MULT1 = 6'd33;
parameter MULT2 = 6'd34;
parameter MULT3 = 6'd35;
parameter DIV = 6'd36;
parameter FIX_SIGN = 6'd37;
parameter MD_RES = 6'd38;
parameter byt = 2'd0;
parameter half = 2'd1;
parameter char = 2'd2;
parameter word = 2'd3;

wire clk = clk_i;
reg [5:0] state;
reg [63:0] tick;			// tick counter
reg [31:0] vbr;				// vector base register
reg km;						// kernel mode
reg [7:0] kmb;				// backup kernel mode flag
reg pe;						// protected mode enabled
reg im;						// interrupt mask
reg [31:0] pc,dpc,xpc;
reg [31:0] epc,ipc;			// exception and interrupt PC's
reg gie;					// global interrupt enable
reg StatusHWI;
reg [31:4] ibufadr;
reg [127:0] ibuf;
reg [63:0] regfile [31:0];
reg [63:0] sp;
reg [31:0] ir,xir,mir,wir;
wire [6:0] opcode = ir[6:0];
wire [6:0] funct = ir[31:25];
reg [6:0] xfunct,mfunct;
reg [6:0] xopcode,mopcode,wopcode;
wire [4:0] Ra = ir[11:7];
wire [4:0] Rb = ir[21:17];
wire [4:0] Rc = ir[16:12];
reg [4:0] xRt,mRt,wRt;
reg [63:0] rfoa,rfob,rfoc;
always @*
case(Ra)
5'd0:	rfoa <= 64'd0;
xRt:	rfoa <= res;
wRt:	rfoa <= wres;
default:	rfoa <= regfile[Ra];
endcase
always @*
case(Rb)
5'd0:	rfob <= 64'd0;
xRt:	rfob <= res;
wRt:	rfob <= wres;
default:	rfob <= regfile[Rb];
endcase
always @*
case(Rc)
5'd0:	rfoc <= 64'd0;
xRt:	rfoc <= res;
wRt:	rfoc <= wres;
default:	rfoc <= regfile[Rc];
endcase
reg [63:0] a,b,c,imm,xb;
wire [63:0] pa = a[63] ? -a : a;
reg [63:0] aa,bb;
reg [63:0] q,r;
reg [127:0] p;
wire [127:0] p1 = aa * bb;
wire [63:0] diff = r - bb;
reg [6:0] cnt;
reg [63:0] res,ea,xres,mres,wres,lres;
reg res_sgn;
reg [1:0] ld_size, st_size;
reg [31:0] insncnt;

reg advanceEX;
reg advanceWBx;
wire advanceWB = advanceEX|advanceWBx;
wire advanceRF = advanceEX;
wire advanceIF = advanceRF & ihit;

reg isICacheReset;
reg isICacheLoad;
wire [31:0] insn;
wire ihit;

FISA64_icache_ram u1
(
	.wclk(clk),
	.wa(adr_o[12:0]),
	.wr(isICacheLoad & ack_i),
	.i(dat_i),
	.rclk(~clk),
	.pc(pc[12:0]),
	.insn(insn)
);

FISA64_itag_ram u2
(
	.wclk(clk),
	.wa(adr_o),
	.v(!isICacheReset),
	.wr((isICacheLoad & ack_i && (adr_o[3]==1'b1))|isICacheReset),
	.rclk(~clk),
	.pc(pc),
	.hit(ihit)
);

reg [31:0] rpc;		// registered PC value
always @(negedge clk)
	rpc <= pc;
reg [15:0] lottags [2047:0];
always @(posedge clk)
	if (advanceEX && xopcode==`RR && xfunct==`MTSPR && xir[24:19]==`TAGS)
		lottags[ea[26:16]] <= a[15:0];
wire [15:0] lottag = lottags[ea[26:16]];
wire [15:0] lottagX = lottags[rpc[26:16]];

reg [9:0] lotgrp [5:0];

wire isLotOwner = km | (((lotgrp[0]==lottag[15:6]) ||
					(lotgrp[1]==lottag[15:6]) ||
					(lotgrp[2]==lottag[15:6]) ||
					(lotgrp[3]==lottag[15:6]) ||
					(lotgrp[4]==lottag[15:6]) ||
					(lotgrp[5]==lottag[15:6])))
					;
wire isLotOwnerX = km | (((lotgrp[0]==lottagX[15:6]) ||
					(lotgrp[1]==lottagX[15:6]) ||
					(lotgrp[2]==lottagX[15:6]) ||
					(lotgrp[3]==lottagX[15:6]) ||
					(lotgrp[4]==lottagX[15:6]) ||
					(lotgrp[5]==lottagX[15:6])))
					;

wire lti = $signed(a) < $signed(imm);
wire ltui = a < imm;
wire eqi = a==imm;
wire eq = a==b;
wire lt = $signed(a) < $signed(b);
wire ltu = a < b;

always @*
case(xopcode)
`BSR:	res <= xpc + 64'd4;
`JAL:	res <= xpc + 64'd4;
`RTS:	res <= c + imm;
`ADD:	res <= a + imm;
`ADDU:	res <= a + imm;
`SUB:	res <= a - imm;
`SUBU:	res <= a - imm;
`CMP:	res <= lti ? 64'hFFFFFFFFFFFFFFFF : eqi ? 64'd0 : 64'd1;
`CMPU:	res <= ltui ? 64'hFFFFFFFFFFFFFFFF : eqi ? 64'd0 : 64'd1;
`AND:	res <= a & imm;
`OR:	res <= a | imm;
`EOR:	res <= a ^ imm;
`LDI:
	case(xir[8:7])
	2'd0:	res <= imm;
	2'd1:	res <= {imm[63:16],c[15:0]};
	2'd2:	res <= {imm[63:32],c[31:0]};
	2'd3:	res <= {imm[63:48],c[47:0]};
	endcase
`SEQ:	res <= eqi;
`SNE:	res <= !eqi;
`SGT:	res <= !(lti|eqi);
`SGE:	res <= !lti;
`SLT:	res <= lti;
`SLE:	res <= lti|eqi;
`SHI:	res <= !(ltui|eqi);
`SHS:	res <= !ltui;
`SLO:	res <= ltui;
`SLS:	res <= ltui|eqi;
`RR:
	case(xfunct)
	`MFSPR:
		if (km) begin
			case(xir[24:17])
			`CR0:		res <= pe;
			`TICK:		res <= tick;
			`EPC:		res <= epc;
			`IPC:		res <= ipc;
			`VBR:		res <= vbr;
			`EA:		res <= ea;
			`TAGS:		res <= lottag;
			`LOTGRP:	res <= {lotgrp[5],lotgrp[4],lotgrp[3],lotgrp[2],lotgrp[1],lotgrp[0]};
			default:	res <= 64'd0;
			endcase
		end
		else begin
			case(xir[24:17])
			default:	res <= 64'd0;
			endcase
		end
	`ADD:	res <= a + b;
	`ADDU:	res <= a + b;
	`SUB:	res <= a - b;
	`SUBU:	res <= a - b;
	`CMP:	res <= lt ? 64'hFFFFFFFFFFFFFFFF : eq ? 64'd0 : 64'd1;
	`CMPU:	res <= ltu ? 64'hFFFFFFFFFFFFFFFF : eq ? 64'd0 : 64'd1;
	`AND:	res <= a & b;
	`OR:	res <= a | b;
	`EOR:	res <= a ^ b;
	`SEQ:	res <= eq;
	`SNE:	res <= !eq;
	`SGT:	res <= !(lt|eq);
	`SGE:	res <= !lt;
	`SLT:	res <= lt;
	`SLE:	res <= lt|eq;
	`SHI:	res <= !(ltu|eq);
	`SHS:	res <= !ltu;
	`SLO:	res <= ltu;
	`SLS:	res <= ltu|eq;
	`SLLI:	res <= a << xir[22:17];
	`SLL:	res <= a << b[5:0];
	`SRLI:	res <= a >> xir[22:17];
	`SRL:	res <= a >> b[5:0];
	`SRAI:	if (a[63])
				res <= (a >> xir[22:17]) | ~(64'hFFFFFFFFFFFFFFFF >> xir[22:17]);
			else
				res <= a >> xir[22:17];
	`SRA:	if (a[63])
				res <= (a >> b[5:0]) | ~(64'hFFFFFFFFFFFFFFFF >> b[5:0]);
			else
				res <= a >> b[5:0];
	`SXB:	res <= {{56{a[7]}},a[7:0]};
	`SXC:	res <= {{48{a[15]}},a[15:0]};
	`SXH:	res <= {{32{a[31]}},a[31:0]};
	default:	res <= 64'd0;
	endcase
`LEAX:	res <= a + (b << xir[23:22]) + imm;
default:	res <= 64'd0;
endcase

reg nmi1;
reg nmi_edge;
always @(posedge clk)
if (rst_i) begin
	insncnt <= 32'd0;
	ibufadr <= 28'd0;
	tick <= 64'd0;
	vbr <= 32'd0;
	km <= `TRUE;
	pe <= `FALSE;
	pc <= 32'hE000;
	state <= RESET;
	nop_ir();
	nop_xir();
	wb_nack();
	adr_o[3] <= 1'b1;	// adr_o[3] must be set
	isICacheReset <= TRUE;
	isICacheLoad <= FALSE;
	advanceEX <= TRUE;
	advanceWBx <= `FALSE;
	gie <= `FALSE;
	StatusHWI <= `FALSE;
	nmi1 <= `FALSE;
	nmi_edge <= `FALSE;
end
else begin
tick <= tick + 64'd1;
advanceWBx <= `FALSE;
nmi1 <= nmi_i;
if (nmi_i & ~nmi1)
	nmi_edge <= `TRUE;
case (state)
RESET:
begin
	adr_o <= adr_o + 32'd16;
	if (adr_o[12:4]==9'h1ff) begin
		isICacheReset <= FALSE;
		state <= RUN;
	end
end
RUN:
begin
	// IFETCH stage
	if (advanceIF) begin
		insncnt <= insncnt + 32'd1;
		if (!StatusHWI & gie & nmi_edge) begin
			StatusHWI <= `TRUE;
			ir <= `BRK_NMI;
			nmi_edge <= `FALSE;
		end
		else if (!StatusHWI & gie & !im & irq_i) begin
			StatusHWI <= `TRUE;
			ir <= `BRK_IRQ;
		end
		else
			ir <= ((isLotOwnerX && (km ? lottagX[0] : lottagX[3])) || !pe) ? insn : `BRK_EXF;
		dpc <= pc;
		pc <= pc + 32'd4;
	end
	else begin
		if (!ihit)
			next_state(LOAD_ICACHE);
		if (advanceRF) begin
			nop_ir();
			dpc <= pc;
			pc <= pc;
		end
	end
	
	// DECODE / REGFETCH
	if (advanceRF) begin
		xir <= ir;
		xopcode <= opcode;
		xfunct <= funct;
		xpc <= dpc;
		a <= rfoa;
		b <= rfob;
		c <= rfoc;
		case(opcode)
		`LDI:
			case(ir[8:7])
			2'd0:	imm <= {{48{ir[31]}},ir[31:17],ir[11]};
			2'd1:	imm <= {{32{ir[31]}},ir[31:17],ir[11],16'h0000};
			2'd2:	imm <= {{16{ir[31]}},ir[31:17],ir[11],32'h0000};
			2'd3:	imm <= {ir[31:17],ir[11],48'h0000};
			endcase
		`BSR,`BRA:	imm <= {ir[31:7],2'b00};
		`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`LEAX,
		`SBX,`SCX,`SHX,`SWX:
			imm <= ir[31:24];
		default:	imm <= {{49{ir[31]}},ir[31:17]};
		endcase
		case(opcode)
		`RR:
			case(funct)
			`MTSPR,`RTI,`RTE,`FENCE:
				xRt <= 5'd0;
			endcase
		`Bcc,`BRK:
			xRt <= 5'd0;
		`SB,`SC,`SH,`SW,`SBX,`SCX,`SHX,`SWX,`INC:
			xRt <= 5'd0;
		`BSR:	xRt <= 5'h1F;
		default:	xRt <= ir[16:12];
		endcase
	end
	else if (advanceEX) begin
		nop_xir();
	end

	// EXECUTE
	if (advanceEX) begin
		wRt <= xRt;
		wres <= res;
		wir <= xir;
		wopcode <= xopcode;
		case(xopcode)
		`RR:
			case(xfunct)
			`MTSPR:
				if (km) begin
					case(xir[24:17])
					`CR0:		pe <= a[0];
					`EPC:		epc <= {a[31:2],2'b00};
					`IPC:		ipc <= {a[31:2],2'b00};
					`VBR:		begin vbr <= a[31:0]; vbr[12:0] <= 13'h000; end
					`EA:		ea <= a;
					`LOTGRP:
						begin
							lotgrp[0] <= a[ 9: 0];
							lotgrp[1] <= a[19:10];
							lotgrp[2] <= a[29:20];
							lotgrp[3] <= a[39:30];
							lotgrp[4] <= a[49:40];
							lotgrp[5] <= a[59:50];
						end
					endcase
				end
				else privilege_violation();
			`MFSPR:	if (!km) privilege_violation();
			`MUL,`MULU,`DIV,`DIVU,`MOD,`MODU:
					begin
					mopcode <= xopcode;
					mfunct <= xfunct;
					next_state(MULDIV);
					advanceEX <= FALSE;
					end
			`RTE:
				if (km) begin
					km <= kmb[0];
					kmb <= {1'b1,kmb[7:1]};
					pc <= epc;
					nop_ir();
					nop_xir();
				end
				else privilege_violation();
			`RTI:
				if (km) begin
					km <= kmb[0];
					kmb <= {1'b1,kmb[7:1]};
					pc <= ipc;
					nop_ir();
					nop_xir();
				end
				else privilege_violation();
			endcase
		`MUL,`MULU,`DIV,`DIVU,`MOD,`MODU:
				begin
				mopcode <= xopcode;
				mfunct <= xfunct;
				next_state(MULDIV);
				advanceEX <= FALSE;
				end
		`BSR,`BRA:
				begin
					pc <= xpc + imm;
					pc[1:0] <= 2'b0;
					nop_ir();
					nop_xir();
				end
		`JAL:	begin
					pc <= a + {imm,2'b00};
					pc[1:0] <= 2'b0;
					nop_ir();
					nop_xir();
				end
		`RTS:	begin
					pc <= a;
					pc[1:0] <= 2'b00;
					nop_ir();
					nop_xir();
				end
		`Bcc:	case(xir[14:12])
				`BEQ:	if (~|a) begin pc <= xpc + {imm,2'b00}; nop_ir(); nop_xir(); end
				`BNE:	if ( |a) begin pc <= xpc + {imm,2'b00}; nop_ir(); nop_xir(); end
				`BGT:	if (~a[63] & |a[62:0]) begin pc <= xpc + {imm,2'b00}; nop_ir(); nop_xir(); end
				`BGE:	if (~a[63]) begin pc <= xpc + {imm,2'b00}; nop_ir(); nop_xir(); end
				`BLT:	if (a[63]) begin pc <= xpc + {imm,2'b00}; nop_ir(); nop_xir(); end
				`BLE:	if (a[63] | ~|a[63:0]) begin pc <= xpc + {imm,2'b00}; nop_ir(); nop_xir(); end
				endcase
		`BRK:	begin
				if (xir[31]) begin
					StatusHWI <= `FALSE;
					ipc <= xpc;
				end
				else
					epc <= xpc;
				kmb <= {kmb[6:0],km};
				km <= `TRUE;
				advanceEX <= FALSE;
				mopcode <= xopcode;
				mir <= xir;
				ea <= {vbr[31:12],xir[25:17],3'b000};
				ld_size <= word;
				next_state(LOAD1);
				nop_ir();
				nop_xir();
				end
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`INC:
				begin
				next_state(LOAD1);
				advanceEX <= FALSE;
				mopcode <= xopcode;
				mir <= xir;
				ea <= a + imm;
				case(xopcode)
				`LB,`LBU:	ld_size <= byt;
				`LC,`LCU:	ld_size <= char;
				`LH,`LHU:	ld_size <= half;
				`LW,`INC:	ld_size <= word;
				endcase
				end
		`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX:
				begin
				next_state(LOAD1);
				advanceEX <= FALSE;
				mopcode <= xopcode;
				ea <= a + (b << xir[23:22]) + imm;
				case(xopcode)
				`LBX,`LBUX:	ld_size <= byt;
				`LCX,`LCUX:	ld_size <= char;
				`LHX,`LHUX:	ld_size <= half;
				`LWX:		ld_size <= word;
				endcase
				end
		`SB,`SC,`SH,`SW:
				begin
				next_state(STORE1);
				advanceEX <= FALSE;
				mopcode <= xopcode;
				ea <= a + imm;
				xb <= c;
				case(xopcode)
				`SB:	st_size <= byt;
				`SC:	st_size <= char;
				`SH:	st_size <= half;
				`SW:	st_size <= word;
				endcase
				end
		`SBX,`SCX,`SHX,`SWX:
				begin
				next_state(STORE1);
				advanceEX <= FALSE;
				mopcode <= xopcode;
				ea <= a + (b << xir[23:22]) + imm;
				xb <= c;
				case(xopcode)
				`SBX:	st_size <= byt;
				`SCX:	st_size <= char;
				`SHX:	st_size <= half;
				`SWX:	st_size <= word;
				endcase
				end
		endcase
	end
	else if (advanceWB) begin
		wRt <= 5'd0;
		wres <= 64'd0;
	end

	// WRITEBACK
	if (advanceWB) begin
		regfile[wRt] <= wres;
		if (wRt==5'd30)	// write to SP globally enables interrupts
			gie <= `TRUE;
		if (wRt != 5'd0)
			$display("r%d = %h", wRt, wres);
	end

end	// RUN

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Multiply / Divide / Modulus machine states.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

MULDIV:
	begin
		cnt <= 7'd64;
		case(mopcode)
		`MULU:
			begin
				aa <= a;
				bb <= imm;
				res_sgn <= 1'b0;
				next_state(MULT1);
			end
		`MUL:
			begin
				aa <= a[63] ? -a : a;
				bb <= imm[63] ? ~imm+64'd1 : imm;
				res_sgn <= a[63] ^ imm[63];
				next_state(MULT1);
			end
		`DIVU,`MODU:
			begin
				aa <= a;
				bb <= imm;
				q <= a[62:0];
				r <= a[63];
				res_sgn <= 1'b0;
				next_state(DIV);
			end
		`DIV,`MOD:
			begin
				aa <= a[63] ? ~a+64'd1 : a;
				bb <= imm[63] ? ~imm+64'd1 : imm;
				q <= pa[62:0];
				r <= pa[63];
				res_sgn <= a[63] ^ imm[63];
				next_state(DIV);
			end
		`RR:
			case(mfunct)
			`MULU:
				begin
					aa <= a;
					bb <= b;
					res_sgn <= 1'b0;
					next_state(MULT1);
				end
			`MUL:
				begin
					aa <= a[63] ? -a : a;
					bb <= b[63] ? -b : b;
					res_sgn <= a[63] ^ b[63];
					next_state(MULT1);
				end
			`DIVU,`MODU:
				begin
					aa <= a;
					bb <= b;
					q <= a[62:0];
					r <= a[63];
					res_sgn <= 1'b0;
					next_state(DIV);
				end
			`DIV,`MOD:
				begin
					aa <= a[63] ? -a : a;
					bb <= b[63] ? -b : b;
					q <= pa[62:0];
					r <= pa[63];
					res_sgn <= a[63] ^ b[63];
//					if (b==64'd0)
//						divide_by_zero();
//					else
						next_state(DIV);
				end
			default:
				begin
				advanceEX <= TRUE;
				state <= RUN;
				end
			endcase
		endcase
	end
// Three wait states for the multiply to take effect. These are needed at
// higher clock frequencies. The multipler is a multi-cycle path that
// requires a timing constraint.
MULT1:	state <= MULT2;
MULT2:	state <= MULT3;
MULT3:	begin
			p <= p1;
			next_state(res_sgn ? FIX_SIGN : MD_RES);
		end
DIV:
	begin
		q <= {q[62:0],~diff[63]};
		if (cnt==7'd0) begin
			next_state(res_sgn ? FIX_SIGN : MD_RES);
			if (diff[63])
				r <= r[62:0];
			else
				r <= diff[62:0];
		end
		else begin
			if (diff[63])
				r <= {r[62:0],q[63]};
			else
				r <= {diff[62:0],q[63]};
		end
		cnt <= cnt - 7'd1;
	end

FIX_SIGN:
	begin
		next_state(MD_RES);
		if (res_sgn) begin
			p <= -p;
			q <= -q;
			r <= -r;
		end
	end

MD_RES:
	begin
		if (mopcode==`MUL || mopcode==`MULU || (mopcode==`RR && (mfunct==`MUL || mfunct==`MULU)))
			wres <= p[63:0];
		else if (mopcode==`DIV || mopcode==`DIVU || (mopcode==`RR && (mfunct==`DIV || mfunct==`DIVU)))
			wres <= q[63:0];
		else
			wres <= r[63:0];
		advanceEX <= TRUE;
		next_state(RUN);
	end

LOAD1:	next_state(LOAD2);

LOAD2:
	begin
		// Check for read attribute on lot
		if ((isLotOwner && (km ? lottag[2] : lottag[5])) || !pe) begin
			wb_read1(ld_size,ea);
			next_state(LOAD3);
		end
		else begin
			wb_read1(word,{vbr[31:12],9'd499,3'b000});	// Data read fault
			mopcode <= `BRK;
			epc <= xpc;
			next_state(LOAD3);
		end
	end
LOAD3:
	if (ack_i) begin
		case(mopcode)
		`LB,`LBX:
			begin
			wb_nack();
			next_state(RUN);
			advanceEX <= TRUE;
			case(ea[2:0])
			3'd0:	wres <= {{56{dat_i[7]}},dat_i[7:0]};
			3'd1:	wres <= {{56{dat_i[15]}},dat_i[15:8]};
			3'd2:	wres <= {{56{dat_i[23]}},dat_i[23:16]};
			3'd3:	wres <= {{56{dat_i[31]}},dat_i[31:24]};
			3'd4:	wres <= {{56{dat_i[39]}},dat_i[39:32]};
			3'd5:	wres <= {{56{dat_i[47]}},dat_i[47:40]};
			3'd6:	wres <= {{56{dat_i[55]}},dat_i[55:48]};
			3'd7:	wres <= {{56{dat_i[63]}},dat_i[63:56]};
			endcase
			end
		`LBU,`LBUX:
			begin
			wb_nack();
			next_state(RUN);
			advanceEX <= TRUE;
			case(ea[2:0])
			3'd0:	wres <= dat_i[7:0];
			3'd1:	wres <= dat_i[15:8];
			3'd2:	wres <= dat_i[23:16];
			3'd3:	wres <= dat_i[31:24];
			3'd4:	wres <= dat_i[39:32];
			3'd5:	wres <= dat_i[47:40];
			3'd6:	wres <= dat_i[55:48];
			3'd7:	wres <= dat_i[63:56];
			endcase
			end
		`LC,`LCX:
			case(ea[2:0])
			3'd0:	begin wres <= {{48{dat_i[15]}},dat_i[15:0]}; next_state(RUN); wb_nack(); advanceEX <= TRUE; end
			3'd1:	begin wres <= {{48{dat_i[23]}},dat_i[23:8]}; next_state(RUN); wb_nack(); advanceEX <= TRUE; end
			3'd2:	begin wres <= {{48{dat_i[31]}},dat_i[31:16]}; next_state(RUN); wb_nack(); advanceEX <= TRUE; end
			3'd3:	begin wres <= {{48{dat_i[39]}},dat_i[39:24]}; next_state(RUN); wb_nack(); advanceEX <= TRUE; end
			3'd4:	begin wres <= {{48{dat_i[47]}},dat_i[47:32]}; next_state(RUN); wb_nack(); advanceEX <= TRUE; end
			3'd5:	begin wres <= {{48{dat_i[55]}},dat_i[55:40]}; next_state(RUN); wb_nack(); advanceEX <= TRUE; end
			3'd6:	begin wres <= {{48{dat_i[63]}},dat_i[63:48]}; next_state(RUN); wb_nack(); advanceEX <= TRUE; end
			3'd7:	begin wres[7:0] <= dat_i[63:56]; next_state(LOAD4); wb_half_nack(); end
			endcase
		`LCU,`LCUX:
			case(ea[2:0])
			3'd0:	begin wres <= dat_i[15:0]; next_state(RUN); wb_nack(); advanceEX <= TRUE; end
			3'd1:	begin wres <= dat_i[23:8]; next_state(RUN); wb_nack(); advanceEX <= TRUE; end
			3'd2:	begin wres <= dat_i[31:16]; next_state(RUN); wb_nack(); advanceEX <= TRUE; end
			3'd3:	begin wres <= dat_i[39:24]; next_state(RUN); wb_nack(); advanceEX <= TRUE; end
			3'd4:	begin wres <= dat_i[47:32]; next_state(RUN); wb_nack(); advanceEX <= TRUE; end
			3'd5:	begin wres <= dat_i[55:40]; next_state(RUN); wb_nack(); advanceEX <= TRUE; end
			3'd6:	begin wres <= dat_i[63:48]; next_state(RUN); wb_nack(); advanceEX <= TRUE; end
			3'd7:	begin wres[7:0] <= dat_i[63:56]; next_state(LOAD4); wb_half_nack(); end
			endcase
		`LH,`LHX:
			case(ea[2:0])
			3'd0:	begin wres <= {{32{dat_i[31]}},dat_i[31:0]}; next_state(RUN); wb_nack(); advanceEX <= TRUE; end
			3'd1:	begin wres <= {{32{dat_i[39]}},dat_i[39:8]}; next_state(RUN); wb_nack(); advanceEX <= TRUE; end
			3'd2:	begin wres <= {{32{dat_i[47]}},dat_i[47:16]}; next_state(RUN); wb_nack(); advanceEX <= TRUE; end
			3'd3:	begin wres <= {{32{dat_i[55]}},dat_i[55:24]}; next_state(RUN); wb_nack(); advanceEX <= TRUE; end
			3'd4:	begin wres <= {{32{dat_i[63]}},dat_i[63:32]}; next_state(RUN); wb_nack(); advanceEX <= TRUE; end
			3'd5:	begin wres[23:0] <= dat_i[63:40]; next_state(LOAD4); wb_half_nack(); end
			3'd6:	begin wres[15:0] <= dat_i[63:48]; next_state(LOAD4); wb_half_nack(); end
			3'd7:	begin wres[ 7:0] <= dat_i[63:56]; next_state(LOAD4); wb_half_nack(); end
			endcase
		`LHU,`LHUX:
			case(ea[2:0])
			3'd0:	begin wres <= dat_i[31:0]; next_state(RUN); wb_nack(); advanceEX <= TRUE; end
			3'd1:	begin wres <= dat_i[39:8]; next_state(RUN); wb_nack(); advanceEX <= TRUE; end
			3'd2:	begin wres <= dat_i[47:16]; next_state(RUN); wb_nack(); advanceEX <= TRUE; end
			3'd3:	begin wres <= dat_i[55:24]; next_state(RUN); wb_nack(); advanceEX <= TRUE; end
			3'd4:	begin wres <= dat_i[63:32]; next_state(RUN); wb_nack(); advanceEX <= TRUE; end
			3'd5:	begin wres[23:0] <= dat_i[63:40]; next_state(LOAD4); wb_half_nack(); end
			3'd6:	begin wres[15:0] <= dat_i[63:48]; next_state(LOAD4); wb_half_nack(); end
			3'd7:	begin wres[ 7:0] <= dat_i[63:56]; next_state(LOAD4); wb_half_nack(); end
			endcase
		`LW,`LWX:
			case(ea[2:0])
			3'd0:	begin wres <= dat_i[63:0]; next_state(RUN); wb_nack(); advanceEX <= TRUE; end
			3'd1:	begin wres[55:0] <= dat_i[63:8]; next_state(LOAD4); wb_half_nack(); end
			3'd2:	begin wres[47:0] <= dat_i[63:16]; next_state(LOAD4); wb_half_nack(); end
			3'd3:	begin wres[39:0] <= dat_i[63:24]; next_state(LOAD4); wb_half_nack(); end
			3'd4:	begin wres[31:0] <= dat_i[63:32]; next_state(LOAD4); wb_half_nack(); end
			3'd5:	begin wres[23:0] <= dat_i[63:40]; next_state(LOAD4); wb_half_nack(); end
			3'd6:	begin wres[15:0] <= dat_i[63:48]; next_state(LOAD4); wb_half_nack(); end
			3'd7:	begin wres[ 7:0] <= dat_i[63:56]; next_state(LOAD4); wb_half_nack(); end
			endcase
		`INC:
			case(ea[2:0])
			3'd0:	begin wres <= dat_i[63:0]; next_state(INC); wb_half_nack(); end
			3'd1:	begin wres[55:0] <= dat_i[63:8]; next_state(LOAD4); wb_half_nack(); end
			3'd2:	begin wres[47:0] <= dat_i[63:16]; next_state(LOAD4); wb_half_nack(); end
			3'd3:	begin wres[39:0] <= dat_i[63:24]; next_state(LOAD4); wb_half_nack(); end
			3'd4:	begin wres[31:0] <= dat_i[63:32]; next_state(LOAD4); wb_half_nack(); end
			3'd5:	begin wres[23:0] <= dat_i[63:40]; next_state(LOAD4); wb_half_nack(); end
			3'd6:	begin wres[15:0] <= dat_i[63:48]; next_state(LOAD4); wb_half_nack(); end
			3'd7:	begin wres[ 7:0] <= dat_i[63:56]; next_state(LOAD4); wb_half_nack(); end
			endcase
		// Memory access is aligned
		`BRK:	begin nop_ir(); nop_xir(); pc <= dat_i[63:0]; next_state(RUN); wb_nack(); advanceEX <= TRUE; km <= `TRUE; end
		endcase
	end
LOAD4:
	begin
		wb_read2(ld_size,ea);
		next_state(LOAD5);
	end
LOAD5:
	if (ack_i) begin
		if (mopcode==`INC) begin
			wb_half_nack();
			next_state(INC);
		end
		else begin
			wb_nack();
			next_state(RUN);
			advanceEX <= TRUE;
		end
		case(mopcode)
		`LC,`LCX:	wres[63:8] <= {{48{dat_i[7]}},dat_i[7:0]};
		`LCU,`LCUX:	wres[63:8] <= dat_i[7:0];
		`LH,`LHX:
			case(ea[2:0])
			3'd5:	wres[63:24] <= {{32{dat_i[7]}},dat_i[7:0]};
			3'd6:	wres[63:16] <= {{32{dat_i[15]}},dat_i[15:0]};
			3'd7:	wres[63: 8] <= {{32{dat_i[23]}},dat_i[23:0]};
			default:	;
			endcase
		`LHU,`LHUX:
			case(ea[2:0])
			3'd5:	wres[63:24] <= dat_i[7:0];
			3'd6:	wres[63:16] <= dat_i[15:0];
			3'd7:	wres[63: 8] <= dat_i[23:0];
			default:	;
			endcase
		`LW,`LWX:
			case(ea[2:0])
			3'd0:	;
			3'd1:	wres[63:56] <= dat_i[7:0];
			3'd2:	wres[63:48] <= dat_i[15:0];
			3'd3:	wres[63:40] <= dat_i[23:0];
			3'd4:	wres[63:32] <= dat_i[31:0];
			3'd5:	wres[63:24] <= dat_i[39:0];
			3'd6:	wres[63:16] <= dat_i[47:0];
			3'd7:	wres[63: 8] <= dat_i[55:0];
			endcase
		`INC:
			case(ea[2:0])
			3'd0:	;
			3'd1:	wres[63:56] <= dat_i[7:0];
			3'd2:	wres[63:48] <= dat_i[15:0];
			3'd3:	wres[63:40] <= dat_i[23:0];
			3'd4:	wres[63:32] <= dat_i[31:0];
			3'd5:	wres[63:24] <= dat_i[39:0];
			3'd6:	wres[63:16] <= dat_i[47:0];
			3'd7:	wres[63: 8] <= dat_i[55:0];
			endcase
		endcase
	end

INC:
	begin
		xb <= wres + {{59{mir[16]}},mir[16:12]};
		next_state(STORE2);
	end

STORE1:	next_state(STORE2);

STORE2:
	begin
		// check for write attribute on lot
		if ((isLotOwner && (km ? lottag[1] : lottag[4])) || !pe) begin
			wb_write1(st_size,ea,xb);
			next_state(STORE3);
		end
		else begin
			wb_read1(word,{vbr[31:12],9'd498,3'b000});	// Data write fault
			mopcode <= `BRK;
			epc <= xpc;
			next_state(LOAD3);
		end
	end
STORE3:
	if (ack_i) begin
		if ((st_size==char && ea[2:0]==3'b111) ||
			(st_size==half && ea[2:0]>3'd4) ||
			(st_size==word && ea[2:0]!=3'b00)) begin
			wb_half_nack();
			next_state(STORE4);
		end
		else begin
			wb_nack();
			advanceEX <= TRUE;
			next_state(RUN);
		end
	end
STORE4:
	begin
		wb_write2(st_size,ea,xb);
		next_state(STORE5);
	end
STORE5:
	if (ack_i) begin
		wb_nack();
		advanceEX <= TRUE;
		next_state(RUN);
	end

LOAD_ICACHE:
	begin
		isICacheLoad <= TRUE;
		wb_read1(word,{pc[31:4],4'h0});
		next_state(LOAD_ICACHE2);
	end
LOAD_ICACHE2:
	if (ack_i) begin
		wb_half_nack();
		next_state(LOAD_ICACHE3);
	end
LOAD_ICACHE3:
	begin
		wb_read1(word,{pc[31:4],4'h8});
		next_state(LOAD_ICACHE4);
	end
LOAD_ICACHE4:
	if (ack_i) begin
		wb_nack();
		isICacheLoad <= FALSE;
		next_state(RUN);
	end

endcase
end

// Set select lines for first memory cycle
task wb_sel1;
input [1:0] sz;
input [31:0] adr;
begin
	case(sz)
	byt:
		case(adr[2:0])
		3'd0:	sel_o <= 8'h01;
		3'd1:	sel_o <= 8'h02;
		3'd2:	sel_o <= 8'h04;
		3'd3:	sel_o <= 8'h08;
		3'd4:	sel_o <= 8'h10;
		3'd5:	sel_o <= 8'h20;
		3'd6:	sel_o <= 8'h40;
		3'd7:	sel_o <= 8'h80;
		endcase
	char:
		case(adr[2:0])
		3'd0:	sel_o <= 8'h03;
		3'd1:	sel_o <= 8'h06;
		3'd2:	sel_o <= 8'h0C;
		3'd3:	sel_o <= 8'h18;
		3'd4:	sel_o <= 8'h30;
		3'd5:	sel_o <= 8'h60;
		3'd6:	sel_o <= 8'hC0;
		3'd7:	sel_o <= 8'h80;
		endcase
	half:
		case(adr[2:0])
		3'd0:	sel_o <= 8'h0F;
		3'd1:	sel_o <= 8'h1E;
		3'd2:	sel_o <= 8'h3C;
		3'd3:	sel_o <= 8'h78;
		3'd4:	sel_o <= 8'hF0;
		3'd5:	sel_o <= 8'hE0;
		3'd6:	sel_o <= 8'hC0;
		3'd7:	sel_o <= 8'h80;
		endcase
	word:
		case(adr[2:0])
		3'd0:	sel_o <= 8'hFF;
		3'd1:	sel_o <= 8'hFE;
		3'd2:	sel_o <= 8'hFC;
		3'd3:	sel_o <= 8'hF8;
		3'd4:	sel_o <= 8'hF0;
		3'd5:	sel_o <= 8'hE0;
		3'd6:	sel_o <= 8'hC0;
		3'd7:	sel_o <= 8'h80;
		endcase
	endcase
end
endtask

// Set select lines for second memory cycle
task wb_sel2;
input [1:0] sz;
input [31:0] adr;
begin
	case(sz)
	byt:	sel_o <= 8'h00;
	char:	sel_o <= 8'h01;
	half:
		case(adr[2:0])
		3'd5:	sel_o <= 8'h01;
		3'd6:	sel_o <= 8'h03;
		3'd7:	sel_o <= 8'h07;
		default:	sel_o <= 8'h00;
		endcase
	word:
		case(adr[2:0])
		3'd0:	sel_o <= 8'h00;
		3'd1:	sel_o <= 8'h01;
		3'd2:	sel_o <= 8'h03;
		3'd3:	sel_o <= 8'h07;
		3'd4:	sel_o <= 8'h0F;
		3'd5:	sel_o <= 8'h1F;
		3'd6:	sel_o <= 8'h3F;
		3'd7:	sel_o <= 8'h7F;
		endcase
	endcase
end
endtask

task wb_dato;
input [1:0] sz;
input [31:0] adr;
input [63:0] dat;
begin
	case(sz)
	byt:
		begin
		dat_o <= {8{dat[7:0]}};
		end
	char:
		case(adr[0])
		1'b0:	dat_o <= {4{dat[15:0]}};
		1'b1:	dat_o <= {dat[7:0],dat[15:0],dat[15:0],dat[15:0],dat[15:8]};
		endcase
	half:
		case(adr[1:0])
		2'd0:	dat_o <= {2{dat[31:0]}};
		2'd1:	dat_o <= {dat[23:0],dat[31:0],dat[31:24]};
		2'd2:	dat_o <= {dat[15:0],dat[31:0],dat[31:16]};
		2'd3:	dat_o <= {dat[ 7:0],dat[31:0],dat[31: 8]};
		endcase
	word:
		case(adr[2:0])
		3'd0:	dat_o <= dat;
		3'd1:	dat_o <= {dat[55:0],dat[63:56]};
		3'd2:	dat_o <= {dat[47:0],dat[63:48]};
		3'd3:	dat_o <= {dat[39:0],dat[63:40]};
		3'd4:	dat_o <= {dat[31:0],dat[63:32]};
		3'd5:	dat_o <= {dat[23:0],dat[63:24]};
		3'd6:	dat_o <= {dat[15:0],dat[63:16]};
		3'd7:	dat_o <= {dat[ 7:0],dat[63: 8]};
		endcase
	endcase
end
endtask

task wb_read1;
input [1:0] sz;
input [31:0] adr;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	adr_o <= adr;
	wb_sel1(sz,adr);
end
endtask;

task wb_read2;
input [1:0] sz;
input [31:0] adr;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	adr_o <= {adr[31:3]+30'd1,3'b000};
	wb_sel2(sz,adr);
end
endtask;

task wb_burst;
input [5:0] bl;
input [31:0] adr;
begin
	bte_o <= 2'b00;
	cti_o <= 3'b001;
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	sel_o <= 8'hFF;
	adr_o <= {adr[31:3],3'b000};
end
endtask

task wb_write1;
input [1:0] sz;
input [31:0] adr;
input [31:0] dat;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	we_o <= 1'b1;
	adr_o <= adr;
	wb_sel1(sz,adr);
	wb_dato(sz,adr,dat);
end
endtask

task wb_write2;
input [1:0] sz;
input [31:0] adr;
input [31:0] dat;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	we_o <= 1'b1;
	adr_o <= {adr[31:3]+29'd1,3'b000};
	wb_sel2(sz,adr);
	wb_dato(sz,adr,dat);
end
endtask

task wb_nack;
begin
	bte_o <= 2'b00;
	cti_o <= 3'b000;
	cyc_o <= 1'b0;
	stb_o <= 1'b0;
	we_o <= 1'b0;
	sel_o <= 8'h00;
	adr_o <= 32'd0;
	dat_o <= 64'd0;
end
endtask

task wb_half_nack;
begin
	stb_o <= 1'b0;
	we_o <= 1'b0;
	sel_o <= 8'h00;
	adr_o <= 32'h0;
end
endtask

task nop_ir;
begin
	ir <= {25'h0,7'h3F};	// NOP
end
endtask

task nop_xir;
begin
	xopcode <= 7'h3F;
	xRt <= 6'b0;
	xir <= {25'h0,7'h3F};	// NOP
end
endtask 

task next_state;
input [5:0] st;
begin
	state <= st;
end
endtask

task privilege_violation;
begin
	epc <= xpc;
	kmb <= {kmb[6:0],km};
	km <= `TRUE;
	advanceEX <= FALSE;
	mopcode <= `BRK;
	mir <= xir;
	ea <= {vbr[31:12],9'd501,3'b000};	// privilege violation
	ld_size <= word;
	next_state(LOAD1);
end
endtask

function [127:0] fnStateName;
input [5:0] state;
case(state)
RESET:	fnStateName = "RESET ";
RUN:	fnStateName = "RUN ";
LOAD1:  fnStateName = "LOAD1 ";
LOAD2:  fnStateName = "LOAD2 ";
LOAD3:  fnStateName = "LOAD3 ";
LOAD4:  fnStateName = "LOAD4 ";
LOAD5:  fnStateName = "LOAD5 ";
INC:  fnStateName = "INC    ";
STORE1:  fnStateName = "STORE1 ";
STORE2:  fnStateName = "STORE2 ";
STORE3:  fnStateName = "STORE3 ";
STORE4:  fnStateName = "STORE4 ";
STORE5:  fnStateName = "STORE5 ";
LOAD_ICACHE:	fnStateName = "LOAD_ICACHE ";
LOAD_ICACHE2:	fnStateName = "LOAD_ICACHE2 ";
LOAD_ICACHE3:	fnStateName = "LOAD_ICACHE3 ";
LOAD_ICACHE4:	fnStateName = "LOAD_ICACHE4 ";
endcase
endfunction

endmodule

module FISA64_icache_ram(wclk, wa, wr, i, rclk, pc, insn);
input wclk;
input [12:0] wa;
input wr;
input [63:0] i;
input rclk;
input [12:0] pc;
output [31:0] insn;

reg [12:0] rpc;
reg [63:0] icache_ram [1023:0];
always @(posedge wclk)
	if (wr) icache_ram [wa[12:3]] <= i;
always @(posedge rclk)
	rpc <= pc;
wire [63:0] ico = icache_ram[rpc[12:3]];
assign insn = rpc[2] ? ico[63:32] : ico[31:0];

endmodule

module FISA64_itag_ram(wclk, wa, v, wr, rclk, pc, hit);
input wclk;
input [31:0] wa;
input v;
input wr;
input rclk;
input [31:0] pc;
output hit;

reg [31:0] rpc;
reg [32:13] itag_ram [511:0];
always @(posedge wclk)
	if (wr) itag_ram[wa[12:4]] <= {v,wa[31:13]};
always @(posedge rclk)
	rpc <= pc;
wire [32:13] tag_out = itag_ram[rpc[12:4]];
assign hit = tag_out=={1'b1,rpc[31:13]};

endmodule

