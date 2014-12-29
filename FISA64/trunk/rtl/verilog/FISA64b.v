// ============================================================================
// FISA64.v
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
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
// ============================================================================
//
`define BRK		6'd0
`define RR		6'd2
`define MTSPR		6'd16
`define	MFSPR		6'd17
`define RTx			6'd18
`define NEXTPC		6'd19
`define SHIFT		6'd24
`define SHL					3'd0
`define SRU					3'd1
`define SRA					3'd2
`define SHIFTI		6'd25
`define MOD			6'd26
`define MODU		6'd27
`define ADD		6'd4
`define SUB		6'd5
`define CMP		6'd6
`define MUL		6'd7
`define MULU	6'd8
`define DIV		6'd9
`define DIVU	6'd10
`define AND		6'd12
`define OR		6'd13
`define XOR		6'd14
`define Bcc		6'b0100xx
`define BMI		5'd0
`define BPL		5'd1
`define BVS		5'd2
`define BVC		5'd3
`define BCS		5'd4
`define BCC		5'd5
`define BEQ		5'd6
`define BNE		5'd7
`define BHI		5'd8
`define BHS		5'd9
`define BLO		5'd10
`define BLS		5'd11
`define BGT		5'd12
`define BGE		5'd13
`define BLT		5'd14
`define BLE		5'd15
`define BRA		5'd16
`define BRN		5'd17
`define BRZ		5'd18
`define BRNZ	5'd19
`define DBNZ	5'd20
`define JAL		6'd20
`define MODI	6'd26
`define MODUI	6'd27
`define LB		6'd32
`define LBU		6'd33
`define LC		6'd34
`define LCU		6'd35
`define LH		6'd36
`define LHU		6'd37
`define LW		6'd38
`define SB		6'd39
`define SC		6'd40
`define SH		6'd41
`define SW		6'd42
`define NOP		6'd59
`define IMM1	6'd60
`define IMM2	6'd61

module FISA64b(rst_i, clk_i, bte_o, cti_o, bl_o, cyc_o, stb_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o);
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter RESET = 6'd1;
parameter RUN = 6'd2;
parameter LOADSTORE1 = 6'd8;
parameter LOADSTORE2 = 6'd9;
parameter LOADSTORE3 = 6'd10;
parameter LOADSTORE4 = 6'd11;
parameter LOADSTORE5 = 6'd12;
parameter LOADSTORE6 = 6'd13;
parameter MI1 = 6'd16;
parameter MI2 = 6'd17;
parameter MI3 = 6'd18;
parameter MI4 = 6'd19;
parameter MI5 = 6'd20;
parameter MI6 = 6'd21;
parameter MULDIV = 6'd24;
parameter MULT1 = 6'd25;
parameter MULT2 = 6'd26;
parameter MULT3 = 6'd27;
parameter DIV = 6'd28;
parameter FIX_SIGN = 6'd29;
parameter MD_RES = 6'd30;
parameter LOAD_ICACHE = 6'd32;
parameter LOAD_ICACHE2 = 6'd33;
parameter byt = 3'd0;
parameter char = 3'd1;
parameter half = 3'd2;
parameter word = 3'd3;
parameter lspc = 3'd7;

input rst_i;
input clk_i;
output reg [1:0] bte_o;
output reg [2:0] cti_o;
output reg [5:0] bl_o;
output reg cyc_o;
output reg stb_o;
input ack_i;
output reg we_o;
output reg [3:0] sel_o;
output reg [31:0] adr_o;
input [31:0] dat_i;
output reg [31:0] dat_o;

reg [7:0] dat8;
always @(sel_o,dat_i)
case(sel_o)
4'b0001:	dat8 <= dat_i[7:0];
4'b0010:	dat8 <= dat_i[15:8];
4'b0100:	dat8 <= dat_i[23:16];
4'b1000:	dat8 <= dat_i[31:24];
default:	dat8 <= 8'h00;
endcase

reg [15:0] dat16;
always @(sel_o,dat_i)
case(sel_o)
4'b0001:	dat16 <= {dat_i[7:0],8'h00};
4'b0011:	dat16 <= dat_i[15:0];
4'b0110:	dat16 <= dat_i[23:8];
4'b1100:	dat16 <= dat_i[31:16];
4'b1000:	dat16 <= dat_i[31:24];
default:	dat16 <= 16'h0000;
endcase

reg [31:0] dat32;
always @(sel_o,dat_i)
case(sel_o)
4'b0001:	dat32 <= {dat_i[7:0],24'h00};
4'b0011:	dat32 <= {dat_i[15:0],16'h0000};
4'b0111:	dat32 <= {dat_i[23:0],8'h00};
4'b1111:	dat32 <= dat_i[31:0];
4'b1110:	dat32 <= dat_i[23:8];
4'b1100:	dat32 <= dat_i[31:16];
4'b1000:	dat32 <= dat_i[31:24];
default:	dat32 <= 32'h0000;
endcase

wire clk = clk_i;
reg [5:0] state;
reg [2:0] ld_size,st_size;
reg kernel_mode;
reg im;								// interrupt mask
reg [2:0] imcd;						// mask countdown
reg [9:0] owner;					// current lot owner
reg [1:0] thread;
reg [63:0] pc,dpc,xpc,wpc;
reg [63:0] IPC,EPC;
reg [63:0] vbr;						// vector base register
reg [39:0] ir,xir,mir,wir;
wire [5:0] opcode = ir[5:0];
wire [5:0] funct = ir[39:34];
wire xsc = xir[31:30];
wire [5:0] xopcode = xir[5:0];
wire [5:0] xfunct = xir[39:34];
wire [2:0] xmd = xir[26:24];
wire [5:0] wopcode = wir[5:0];
wire [5:0] wfunct = wir[39:34];
reg [63:0] tick;					// tick counter
reg [63:0] insncnt;					// instruction fetch counter
wire [7:0] Ra = {thread,ir[11: 6]};
wire [7:0] Rb = {thread,ir[17:12]};
wire [7:0] Rc = {thread,ir[23:18]};
wire [5:0] mopcode = mir[5:0];
wire [2:0] mmd = mir[26:24];
wire [7:0] mRa = {thread,mir[11: 6]};
wire [7:0] mRb = {thread,mir[17:12]};
reg [7:0] Rt,xRt,mRt,wRt,tRt;
reg [63:0] a,b,c,imm,xa,xb,xc;
reg [63:0] ea;
reg [63:0] regfile [255:0];
reg [63:0] rfoa,rfob,rfoc;
reg [63:0] res,wres,tres;

always @*
casex(Ra)
8'bxx000000:	rfoa <= 64'd0;
xRt:	rfoa <= res;
wRt:	rfoa <= wres;
tRt:	rfoa <= tres;
8'bxx111111:	rfoa <= pc;
default:	rfoa <= regfile[Ra];
endcase

always @*
casex(Rb)
8'bxx000000:	rfob <= 64'd0;
xRt:	rfob <= res;
wRt:	rfob <= wres;
tRt:	rfob <= tres;
8'bxx111111:	rfob <= pc;
default:	rfob <= regfile[Rb];
endcase

always @*
casex(Rc)
8'bxx000000:	rfoc <= 64'd0;
xRt:	rfoc <= res;
wRt:	rfoc <= wres;
tRt:	rfoc <= tres;
8'bxx111111:	rfoc <= pc;
default:	rfoc <= regfile[Rc];
endcase

function [63:0] pcinc;
input [63:0] pc;
case(pc[1:0])
2'd0:	pcinc = {pc[63:4],4'd5};
2'd1:	pcinc = {pc[63:4],4'd10};
2'd2:	pcinc = {pc[63:4]+60'd1,4'd0};
2'd3:	pcinc = 64'd0;
endcase
endfunction

wire isCMPI = xopcode==`CMP;

reg advanceWBx;
reg advanceEX;
wire advanceWB = advanceEX | advanceWBx;
wire advanceRF = advanceEX;
wire advanceIF = advanceEX & advanceRF & ihit;

reg takb;
always @(xir,b)
case({xir[20:18],xir[1:0]})
`BMI:	takb <=  b[63];
`BPL:	takb <= !b[63];
`BVS:	takb <=  b[62];
`BVC:	takb <= !b[62];
`BCS:	takb <=  b[0];
`BCC:	takb <= !b[0];
`BEQ:	takb <=  b[1];
`BNE:	takb <= !b[1];
`BRA:	takb <= TRUE;
`BRN:	takb <= FALSE;
`BHI:	takb <= b[0] & !b[1];
`BHS:	takb <= b[0];
`BLO:	takb <= !b[0];
`BLS:	takb <= !b[0] | b[1];
`BGT:	takb <= (b[63] & b[62] & !b[1]) | (!b[63] & !b[62] & !b[1]);
`BGE:	takb <= (b[63] & b[62])|(!b[63] & !b[62]);
`BLT:	takb <= (b[63] & !b[62])|(!b[63] & b[62]);
`BLE:	takb <= b[1] | (b[63] & !b[62])|(!b[63] & b[62]);
`BRA:	takb <= TRUE;
`BRN:	takb <= FALSE;
`BRZ:	takb <= b==64'd0;
`BRNZ:	takb <= b!=64'd0;
`DBNZ:	takb <= b!=64'd0;
default:	takb <= TRUE;
endcase

reg isICacheReset;
reg isICacheLoad;
wire [39:0] insn;
wire ihit;

fisa64_icache_ram u1
(
	.wclk(clk),
	.wa(adr_o[12:0]),
	.wr(isICacheLoad & ack_i),
	.i(dat_i),
	.rclk(~clk),
	.pc(pc[12:0]),
	.insn(insn)
);

fisa64_itag_ram u2
(
	.wclk(clk),
	.wa(adr_o),
	.v(!isICacheReset),
	.wr((isICacheLoad & ack_i && (adr_o[3:2]==2'b11))|isICacheReset),
	.rclk(~clk),
	.pc(pc),
	.hit(ihit)
);

wire [15:0] lotinfo_o;
reg [10:0] rea;
reg [15:0] lotinfo [2047:0];
always @(negedge clk)
	rea <= ea[26:16];
assign lotinfo_o = lotinfo[rea];

wire iisImm = insn[5:0]==`IMM1 || insn[5:0]==`IMM2;
wire xisImm = xir[5:0]==`IMM2 || xir[5:0]==`IMM2;
wire wisImm = wir[5:0]==`IMM2 || wir[5:0]==`IMM2;


// Overflow:
// Add: the signs of the inputs are the same, and the sign of the
// sum is different
// Sub: the signs of the inputs are different, and the sign of
// the sum is the same as B
function overflow;
input op;
input a;
input b;
input s;
begin
overflow = (op ^ s ^ b) & (~op ^ a ^ b);
end
endfunction

// Generate result flags for compare instructions
wire [64:0] cmp_res = a - (isCMPI ? imm : b);
reg nf,vf,cf,zf;
always @(cmp_res or a or b or imm or isCMPI)
begin
	cf <= ~cmp_res[64];
	nf <= cmp_res[63];
	vf <= overflow(1,a[63],isCMPI ? imm[63] : b[63], cmp_res[63]);
	zf <= cmp_res[63:0]==64'd0;
end

always @*
casex(xopcode)
`RR:
		case(xfunct)
		`ADD:	res <= a + b;
		`SUB:	res <= a - b;
		`CMP:	res <= {nf,vf,60'd0,zf,cf};
		`AND:	res <= a & b;
		`OR:	res <= a | b;
		`XOR:	res <= a ^ b;
		`SHIFT:
			case(xir[33:31])
			`SHL:	res <= a << b[5:0];
			`SRU:	res <= a >> b[5:0];
			`SRA:	res <= (a >> b[5:0]) | ~(32'hFFFFFFFF >> b[5:0]);
			default:	res <= 64'd0;
			endcase
		`SHIFTI:
			case(xir[33:31])
			`SHL:	res <= a << xir[23:18];
			`SRU:	res <= a >> xir[23:18];
			`SRA:	res <= (a >> xir[23:18]) | ~(32'hFFFFFFFF >> xir[23:18]);
			default:	res <= 64'd0;
			endcase
		`MFSPR:
			case(xir[33:24])
			10'd0:	res <= tick;
			10'd1:	res <= insncnt;
			10'd3:	res <= thread;
			10'd4:	res <= vbr;
			10'd5:	res <= IPC;
			10'd6:	res <= EPC;
			default:	res <= 64'd0;
			endcase
		default:	res <= 64'd0;
		endcase
`ADD:	res <= a + imm;
`SUB:	res <= a - imm;
`CMP:	res <= {nf,vf,60'd0,zf,cf};
`AND:	res <= a & imm;
`OR:	res <= a | imm;
`XOR:	res <= a ^ imm;
`Bcc:	res <= b - 64'd1;			// For DBNZ
default:	res <= 64'd0;
endcase

// Multiply / Divide / Modulus
reg [6:0] cnt;
reg res_sgn;
reg [63:0] aa, bb;
reg [63:0] q, r;
wire [63:0] pa = a[63] ? -a : a;
wire [127:0] p1 = aa * bb;
reg [127:0] p;
wire [63:0] diff = r - bb;

always @(posedge clk)
if (rst_i) begin
	im <= TRUE;
	imcd <= 3'b111;
	wb_nack();
	nop_ir();
	nop_xir();
	nop_wir();
	advanceEX <= TRUE;
	state <= RESET;
	adr_o[3:2] <= 2'b11;
	isICacheLoad <= FALSE;
	isICacheReset <= TRUE;
	thread <= 2'b00;
	insncnt <= 64'd0;
	tick <= 64'd0;
	pc <= 64'h0FFF0;
end
else begin
tick <= tick + 64'd1;
case(state)
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

	//-------------------------------------------------------------------------
	// IFETCH stage
	//-------------------------------------------------------------------------
	if (advanceIF) begin
		insncnt <= insncnt + 64'd1;
		if (imcd!=3'b111)
			imcd <= {imcd[1:0],1'b0};
		if (imcd==3'b000) begin
			imcd <= 3'b111;
			im <= 1'b0;
		end
		ir <= insn;
		if (!iisImm)
			dpc <= pc;
		pc <= pcinc(pc);
	end
	else begin
		if (!ihit)
			next_state(LOAD_ICACHE);
		if (advanceRF) begin
			if (!iisImm)
				nop_ir();
			dpc <= pc;
			pc <= pc;
		end
	end

	//-------------------------------------------------------------------------
	// DECODE / REGFETCH
	//-------------------------------------------------------------------------
	if (advanceRF) begin
		xir <= ir;
		xpc <= dpc;
		a <= rfoa;
		b <= rfob;
		c <= rfoc;
		
		// Set immediate value
		casex(opcode)
		`JAL:		imm <= {{40{ir[39]}},ir[39:18],ir[19:18]};
		`Bcc:		imm <= {{43{ir[39]}},ir[39:21],ir[22:21]};
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`SB,`SC,`SH,`SW:
			begin
				if (wisImm && xisImm)
					imm <= {wir[24:6],xir[39:6],ir[39:29]};
				else if (xisImm)
					imm <= {{19{xir[39]}},xir[39:6],ir[39:29]};
				else
					imm <= {{53{ir[39]}},ir[39:29]};
			end
		default:
			begin
				if (wisImm && xisImm)
					imm <= {wir[13:6],xir[39:6],ir[39:18]};
				else if (xisImm)
					imm <= {{8{xir[39]}},xir[39:6],ir[39:18]};
				else
					imm <= {{42{ir[39]}},ir[39:18]};
			end
		endcase

		// Set target register
		casex(opcode)
		`RR:
			case(funct)
			`ADD,`SUB,`CMP,`MUL,`MULU,`DIV,`DIVU,`AND,`OR,`XOR,
			`MFSPR:
				xRt <= Rc;
			default:	xRt <= {thread,6'd0};
			endcase
		`ADD,`SUB,`MUL,`MULU,`DIV,`DIVU,`AND,`OR,`XOR,
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,
		`JAL:
			xRt <= Rb;
		`CMP:
			xRt <= Rb;
		`Bcc:
			if ({xir[20:18],xir[1:0]}==`DBNZ)
				xRt <= Rb;
			else
				xRt <= {thread,6'd0};
		default:	xRt <= {thread,6'd0};
		endcase
	end

	else if (advanceEX) begin
		if (!xisImm)
			nop_xir();
	end

	//-------------------------------------------------------------------------
	//-------------------------------------------------------------------------
	// EXECUTE
	//-------------------------------------------------------------------------
	//-------------------------------------------------------------------------

	if (advanceEX) begin
		mir <= xir;
		mRt <= xRt;
		wRt <= xRt;
		wres <= res;
		wpc <= xpc;
		wir <= xir;
		xa <= a;
		xb <= b;
		xc <= c;
		casex(xopcode)
		`RR:
			case(xfunct)
			`MTSPR:
				case(xir[33:24])
				10'd3:	thread <= a[1:0];
				10'd4:	vbr <= a;
				10'd5:	IPC <= a;
				10'd6:	EPC <= a;
				endcase
			`MUL,`MULU,`DIV,`DIVU:
				begin
					advanceEX <= FALSE;
					next_state(MULDIV);
				end
			endcase
		`MUL,`MULU,`DIV,`DIVU:
			begin
				advanceEX <= FALSE;
				next_state(MULDIV);
			end
		`JAL:
			begin
				nop_ir();
				nop_xir();
				wres <= pcinc(xpc);
				pc[63:4] <= a[63:4] + imm[63:4];
				if (imm==64'd0)
					pc[3:0] <= a[3:0];
				else
					pc[3:0] <= imm[3:0];
			end
		`Bcc:
			if (takb) begin
				nop_ir();
				nop_xir();
				pc[63:4] <= a[63:4] + imm[63:4];
				if (imm==64'd0)
					pc[3:0] <= a[3:0];
				else
					pc[3:0] <= imm[3:0];
			end
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW:
			begin
			advanceEX <= FALSE;
			case(xmd)
			3'd0:	begin ea <= a + imm; next_state(LOADSTORE1); end
			3'd1:	begin ea <= a + (b << xsc) + imm; next_state(LOADSTORE1); end
			3'd2:	begin ea <= a + (b << xsc) + imm; next_state(LOADSTORE1); end
			3'd3:	begin ea <= a + (b << xsc) + imm; next_state(LOADSTORE1); end
			3'd4:	begin ea <= a + imm; next_state(MI1); end
			3'd5:	begin ea <= a + imm; next_state(MI1); end
			3'd6:	begin ea <= a + imm; next_state(MI1); end
			3'd7:	begin ea <= a + imm; next_state(MI1); end
			endcase
			xb <= b;
			xc <= c;
			case(xopcode)
			`LB,`LBU:	ld_size <= byt;
			`LC,`LCU:	ld_size <= char;
			`LH,`LHU:	ld_size <= half;
			`LW:		ld_size <= word;
			endcase
			end
		`SB,`SC,`SH,`SW:
			begin
			advanceEX <= FALSE;
			case(xmd)
			3'd0:	begin ea <= a + imm; next_state(LOADSTORE1); end
			3'd1:	begin ea <= a + (b << xsc) + imm; next_state(LOADSTORE1); end
			3'd2:	begin ea <= a + (b << xsc) + imm; next_state(LOADSTORE1); end
			3'd3:	begin ea <= a + (b << xsc) + imm; next_state(LOADSTORE1); end
			3'd4:	begin ea <= a + imm; next_state(MI1); end
			3'd5:	begin ea <= a + imm; next_state(MI1); end
			3'd6:	begin ea <= a + imm; next_state(MI1); end
			3'd7:	begin ea <= a + imm; next_state(MI1); end
			endcase
			xb <= b;
			xc <= c;
			case(xopcode)
			`SB:	st_size <= byt;
			`SC:	st_size <= char;
			`SH:	st_size <= half;
			`SW:	st_size <= word;
			endcase
			end
		endcase
	end
	else if (advanceWB) begin
		wRt <= 8'd0;
		wres <= 64'd0;
		if (!wisImm)
			nop_wir();
	end

	//-------------------------------------------------------------------------
	//-------------------------------------------------------------------------
	// WRITEBACK
	//-------------------------------------------------------------------------
	//-------------------------------------------------------------------------
	if (advanceWB) begin
		tRt <= wRt;
		tres <= wres;
		regfile[wRt] <= wres;
		if (wRt[5:0] != 6'd0)
			$display("r%d = %h", wRt[5:0], wres);
		if (wopcode==`RR && wfunct==`RTx)
			begin
				nop_ir();
				nop_xir();
				nop_wir();
				if (wir[17]) begin
					pc <= {IPC[63:2],IPC[3:2]};
					if (IPC[0])
						im <= TRUE;
					else
						imcd <= 3'b110;
				end
				else
					pc <= EPC;
			end
		else if (wopcode==`BRK) begin
			nop_ir();
			nop_xir();
			nop_wir();
			if (wir[17]) begin
				IPC <= {wpc[63:2],1'b1,im};
				im <= 1'b1;
			end
			else
				EPC <= wpc;//pcinc(wpc);
			pc <= {vbr[63:13],wir[14:6],4'h0};
		end
	end

end	// RUN

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Multiply / Divide / Modulus machine states.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

MULDIV:
	begin
		cnt <= 7'd64;
		case(xopcode)
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
				bb <= imm[63] ? -imm : imm;
				res_sgn <= a[63] ^ imm[63];
				next_state(MULT1);
			end
		`DIVU,`MODUI:
			begin
				aa <= a;
				bb <= imm;
				q <= a[62:0];
				r <= a[63];
				res_sgn <= 1'b0;
				next_state(DIV);
			end
		`DIV,`MODI:
			begin
				aa <= a[63] ? -a : a;
				bb <= imm[63] ? -imm : imm;
				q <= pa[62:0];
				r <= pa[63];
				res_sgn <= a[63] ^ imm[63];
				next_state(DIV);
			end
		`RR:
			case(xfunct)
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
		if (xopcode==`MUL || xopcode==`MULU || (xopcode==`RR && (xfunct==`MUL || xfunct==`MULU)))
			wres <= p[63:0];
		else if (xopcode==`DIV || xopcode==`DIVU || (xopcode==`RR && (xfunct==`DIV || xfunct==`DIVU)))
			wres <= q[63:0];
		else
			wres <= r[63:0];
		advanceEX <= TRUE;
		next_state(RUN);
	end


// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// Memory Stage
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

// Burst read indirect address
MI1:
	begin
		wb_burst(6'd3,ea);
		next_state(MI2);
	end
MI2:
	if (ack_i) begin
		ea[31:0] <= dat_i;
		next_state(MI3);
	end
MI3:
	if (ack_i) begin
		ea[63:32] <= dat_i;
		next_state(MI4);
	end
MI4:
	if (ack_i) begin
//		ea[95:64] <= dat_i;
		next_state(MI5);
	end
MI5:
	if (ack_i) begin
//		ea[127:96] <= dat_i;
		next_state(MI6);
	end
// Post indexing stage
MI6:
	begin
		ea <= ea + (xb << xsc);
		next_state(LOADSTORE1);
	end

LOADSTORE1:
	begin
		next_state(LOADSTORE2);
		// Handle auto-increment/decrement address mode. Place on result bus
		// for register update. By the time the load / store is complete
		// several clock cycles will have taken place, and the register 
		// update will be long done.
		if (mmd==3'd2 || mmd==3'd3 || mmd==3'd6 || mmd==3'd7) begin
			if (mRb[5:0]==6'd0) begin
				wRt <= mRa;
				case(mopcode)
				`LB,`LBU,`SB:	wres <= mmd[0] ? xa + 64'd1 : xa - 64'd1;
				`LC,`LCU,`SC:	wres <= mmd[0] ? xa + 64'd2 : xa - 64'd2;
				`LH,`LHU,`SH:	wres <= mmd[0] ? xa + 64'd4 : xa - 64'd4;
				`LW,`SW:	wres <= mmd[0] ? xa + 64'd8 : xa - 64'd8;
				endcase
				advanceWBx <= TRUE;
			end
			else begin
				wRt <= mRb;
				wres <= mmd[0] ? xb + 64'd1 : xb - 64'd1;
				advanceWBx <= TRUE;
			end
		end
		case(mopcode)
		`LB,`LBU:	wb_read1(byt,ea);
		`LC,`LCU:	wb_read1(char,ea);
		`LH,`LHU:	wb_read1(half,ea);
		`LW:		wb_read1(word,ea);
		`SB:		wb_write1(byt,ea,xc);
		`SC:		wb_write1(char,ea,xc);
		`SH:		wb_write1(half,ea,xc);
		`SW:		wb_write1(word,ea,xc);
		endcase
	end

LOADSTORE2:
	begin
		advanceWBx <= FALSE;
		wRt <= mRt;	// restore true target register
		if (ack_i) begin
			stb_o <= FALSE;	// deactive strobe
			case(mopcode)
			`LB:	begin wres <= {{56{dat8[7]}},dat8}; wb_nack(); next_state(RUN); advanceEX <= TRUE; end
			`LBU:	begin wres <= dat8; wb_nack(); next_state(RUN); advanceEX <= TRUE; end
			`LC:	if (ea[1:0]==2'b11) begin wres[7:0] <= dat16[7:0]; next_state(LOADSTORE3); end
					else begin wres <= {{48{dat16[15]}},dat16}; wb_nack(); next_state(RUN); advanceEX <= TRUE; end
			`LCU:	if (ea[1:0]==2'b11) begin wres[7:0] <= dat16[7:0]; next_state(LOADSTORE3); end
					else begin wres <= dat16; wb_nack(); next_state(RUN); advanceEX <= TRUE; end
			`LH:	if (ea[1:0]!=2'b00) begin
						case(ea[1:0])
						2'd1:	wres <= dat32[23:0];
						2'd2:	wres <= dat32[15:0];
						2'd3:	wres <= dat32[7:0];
						default:	wres <= 64'd0;
						endcase
						next_state(LOADSTORE3);
					end
					else begin wres <= {{32{dat32[31]}},dat32}; wb_nack(); next_state(RUN); advanceEX <= TRUE; end
			`LHU:	if (ea[1:0]!=2'b00) begin
						case(ea[1:0])
						2'd1:	wres <= dat32[23:0];
						2'd2:	wres <= dat32[15:0];
						2'd3:	wres <= dat32[7:0];
						default:	wres <= 64'd0;
						endcase
						next_state(LOADSTORE3);
					end
					else begin wres <= dat32; wb_nack(); next_state(RUN); advanceEX <= TRUE; end
			`LW:	begin
						next_state(LOADSTORE3);
						case(ea[1:0])
						2'd0:	wres <= dat32;
						2'd1:	wres <= dat32[23:0];
						2'd2:	wres <= dat32[15:0];
						2'd3:	wres <= dat32[7:0];
						endcase
					end
			`SB:	begin wb_nack(); next_state(RUN); advanceEX <= TRUE; end
			`SC:	if (ea[1:0]==2'b11)
						next_state(LOADSTORE3);
					else begin wb_nack(); next_state(RUN); advanceEX <= TRUE; end
			`SH:	if (ea[1:0]!=2'b00)
						next_state(LOADSTORE3);
					else begin wb_nack(); next_state(RUN); advanceEX <= TRUE; end
			`SW:	next_state(LOADSTORE3);
			endcase
		end
	end

LOADSTORE3:
	begin
		next_state(LOADSTORE4);
		case(mopcode)
		`LC,`LCU:	wb_read2(char,ea);
		`LH,`LHU:	wb_read2(half,ea);
		`LW:		wb_read2(word,ea);
		`SC:		wb_write2(char,ea,xc);
		`SH:		wb_write2(half,ea,xc);
		`SW:		wb_write2(word,ea,xc);
		endcase
	end

LOADSTORE4:
	begin
		if (ack_i) begin
			stb_o <= FALSE;
			case(mopcode)
			`LC:	begin wres[63:8] <= {{48{dat16[15]}},dat16[15:8]}; wb_nack(); next_state(RUN); advanceEX <= TRUE; end
			`LCU:	begin wres[63:8] <= dat16[15:8]; wb_nack(); next_state(RUN); advanceEX <= TRUE; end
			`LH:	case(ea[1:0])
					2'd1:	begin wres[63:24] <= {{32{dat32[31]}},dat32[31:24]}; wb_nack(); next_state(RUN); advanceEX <= TRUE; end
					2'd2:	begin wres[63:16] <= {{32{dat32[31]}},dat32[31:16]}; wb_nack(); next_state(RUN); advanceEX <= TRUE; end
					2'd3:	begin wres[63: 8] <= {{32{dat32[31]}},dat32[31: 8]}; wb_nack(); next_state(RUN); advanceEX <= TRUE; end
					default:	begin wres[63:32] <= {32{wres[31]}}; wb_nack(); next_state(RUN); advanceEX <= TRUE; end
					endcase
			`LHU:	case(ea[1:0])
					2'd1:	begin wres[63:24] <= dat32[31:24]; wb_nack(); next_state(RUN); advanceEX <= TRUE; end
					2'd2:	begin wres[63:16] <= dat32[31:16]; wb_nack(); next_state(RUN); advanceEX <= TRUE; end
					2'd3:	begin wres[63: 8] <= dat32[31: 8]; wb_nack(); next_state(RUN); advanceEX <= TRUE; end
					default:	begin wres[63:32] <= 32'd0; wb_nack(); next_state(RUN); advanceEX <= TRUE; end
					endcase
			`LW:	case(ea[1:0])
					2'd0:	begin wres[63:32] <= dat32; wb_nack(); next_state(RUN); advanceEX <= TRUE; end
					2'd1:	begin wres[55:24] <= dat32; next_state(LOADSTORE5); end
					2'd2:	begin wres[47:16] <= dat32; next_state(LOADSTORE5); end
					2'd3:	begin wres[39: 8] <= dat32; next_state(LOADSTORE5); end
					endcase
			`SC:	begin wb_nack(); next_state(RUN); advanceEX <= TRUE; end
			`SH:	begin wb_nack(); next_state(RUN); advanceEX <= TRUE; end
			`SW:	if (ea[1:0]!=2'b00) next_state(LOADSTORE5); else begin wb_nack(); next_state(RUN); advanceEX <= TRUE; end
			endcase
		end
	end
	
LOADSTORE5:
	begin
		next_state(LOADSTORE6);
		case(mopcode)
		`LW:	wb_read3(ea);
		`SW:	wb_write3(ea,xc);
		default:	begin wb_nack(); next_state(RUN); advanceEX <= TRUE; end	// can't happen
		endcase
	end

LOADSTORE6:
	if (ack_i) begin
		wb_nack();
		next_state(RUN);
		advanceEX <= TRUE;
		case(ea[1:0])
		2'd0:	;	// can't happen
		2'd1:	wres[63:56] <= dat32[31:24];
		2'd2:	wres[63:48] <= dat32[31:16];
		2'd3:	wres[63:40] <= dat32[31: 8];
		endcase
	end

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// Cache load states
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

LOAD_ICACHE:
	begin
		isICacheLoad <= TRUE;
		wb_burst(6'd3,{pc[31:4],4'h0});
		next_state(LOAD_ICACHE2);
	end
LOAD_ICACHE2:
	if (ack_i) begin
		adr_o[3:2] <= adr_o[3:2] + 2'd1;
		if (adr_o[3:2]==2'b10)
			cti_o <= 3'b111;
		if (adr_o[3:2]==2'b11) begin
			isICacheLoad <= FALSE;
			wb_nack();
			next_state(RUN);
		end
	end

endcase
end

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// Supoort tasks
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

task wb_read1;
input [2:0] sz;
input [63:0] adr;
begin
	cyc_o <= TRUE;
	stb_o <= TRUE;
	case(sz)
	byt:	case(adr[1:0])
			2'd0:	sel_o <= 4'b0001;
			2'd1:	sel_o <= 4'b0010;
			2'd2:	sel_o <= 4'b0100;
			2'd3:	sel_o <= 4'b1000;
			endcase
	char:	case(adr[1:0])
			2'd0:	sel_o <= 4'b0011;
			2'd1:	sel_o <= 4'b0110;
			2'd2:	sel_o <= 4'b1100;
			2'd3:	sel_o <= 4'b1000;
			endcase
	half,word:	case(adr[1:0])
			2'd0:	sel_o <= 4'b1111;
			2'd1:	sel_o <= 4'b1110;
			2'd2:	sel_o <= 4'b1100;
			2'd3:	sel_o <= 4'b1000;
			endcase
	default:	sel_o <= 4'b0000;
	endcase
	adr_o <= adr[31:0];
end
endtask

task wb_read2;
input [2:0] sz;
input [63:0] adr;
begin
	cyc_o <= TRUE;
	stb_o <= TRUE;
	case(sz)
	char:	case(adr[1:0])
			2'd3:	sel_o <= 4'b0001;
			default:	sel_o <= 4'b0000;
			endcase
	half:	case(adr[1:0])
			2'd1:	sel_o <= 4'b0001;
			2'd2:	sel_o <= 4'b0011;
			2'd3:	sel_o <= 4'b0111;
			default:	sel_o <= 4'b0000;
			endcase
	word:	sel_o <= 4'b1111;
	default:	sel_o <= 4'b0000;
	endcase
	adr_o <= {adr[31:2] + 30'd1,2'b00};
end
endtask

task wb_read3;
input [63:0] adr;
begin
	cyc_o <= TRUE;
	stb_o <= TRUE;
	case(adr[1:0])
	2'd1:	sel_o <= 4'b0001;
	2'd2:	sel_o <= 4'b0011;
	2'd3:	sel_o <= 4'b0111;
	default:	sel_o <= 4'b0000;
	endcase
	adr_o <= {adr[31:2]+30'd2,2'b00};
end
endtask

task wb_write1;
input [2:0] sz;
input [63:0] adr;
input [63:0] dat;
begin
	we_o <= TRUE;
	wb_read1(sz,adr);
	case(sz)
	byt:	dat_o <= {4{dat[7:0]}};
	char:	dat_o <= adr[0] ? {2{dat[7:0],dat[15:8]}}	: {2{dat[15:0]}};
	half,word:	case(adr[1:0])
			2'd0:	dat_o <= dat[31:0];
			2'd1:	dat_o <= {dat[23:0],8'h00};
			2'd2:	dat_o <= {dat[15:0],16'h0000};
			2'd3:	dat_o <= {dat[7:0],24'h000000};
			endcase
	default:	dat_o <= 32'd0;
	endcase
end
endtask

task wb_write2;
input [2:0] sz;
input [63:0] adr;
input [63:0] dat;
begin
	we_o <= TRUE;
	wb_read2(sz,adr);
	case(sz)
	half:	case(adr[1:0])
			2'd1:	dat_o <= dat[31:24];
			2'd2:	dat_o <= dat[31:16];
			2'd3:	dat_o <= dat[31: 8];
			default:	dat_o <= 32'd0;
			endcase
	word:	case(adr[1:0])
			2'd0:	dat_o <= dat[63:32];
			2'd1:	dat_o <= dat[55:24];
			2'd2:	dat_o <= dat[47:16];
			2'd3:	dat_o <= dat[39: 8];
			endcase
	default:	dat_o <= 32'd0;
	endcase
end
endtask

task wb_write3;
input [63:0] adr;
input [63:0] dat;
begin
	we_o <= TRUE;
	wb_read3(adr);
	case(adr[1:0])
	2'd0:	dat_o <= 32'd0;
	2'd1:	dat_o <= dat[63:56];
	2'd2:	dat_o <= dat[63:48];
	2'd3:	dat_o <= dat[63:40];
	endcase
end
endtask

task wb_burst;
input [5:0] ln;
input [63:0] adr;
begin
	cti_o <= 3'b001;
	bl_o <= ln;
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	sel_o <= 4'hF;
	adr_o <= {adr[31:2],2'b00};
end
endtask

task wb_nack;
begin
	bte_o <= 2'b00;
	cti_o <= 3'b000;
	bl_o <= 6'd0;
	cyc_o <= 1'b0;
	stb_o <= 1'b0;
	we_o <= 1'b0;
	sel_o <= 4'h0;
	adr_o <= 32'h0;
	dat_o <= 32'h0;
end
endtask

task next_state;
input [5:0] st;
begin
	state <= st;
end
endtask

task nop_ir;
begin
	ir <= {34'd0,6'd59};	// NOP
end
endtask

task nop_xir;
begin
	xir <= {34'd0,6'd59};	// NOP
end
endtask

task nop_wir;
begin
	wir <= {34'd0,6'd59};	// NOP
end
endtask

endmodule

module fisa64_icache_ram(wclk, wa, wr, i, rclk, pc, insn);
input wclk;
input [12:0] wa;
input wr;
input [31:0] i;
input rclk;
input [12:0] pc;
output reg [39:0] insn;

reg [12:0] rpc;
reg [119:0] icache_ram [511:0];
reg [119:0] bundle;

always @(posedge wclk)
begin
	if (wr & wa[3:2]==2'b00) icache_ram [wa[12:4]][31: 0] <= i;
	if (wr & wa[3:2]==2'b01) icache_ram [wa[12:4]][63:32] <= i;
	if (wr & wa[3:2]==2'b10) icache_ram [wa[12:4]][95:64] <= i;
	if (wr & wa[3:2]==2'b11) icache_ram [wa[12:4]][119:96] <= i[23:0];
end
always @(posedge rclk)
	rpc <= pc;
always @*
	bundle <= icache_ram[rpc[12:4]];
always @(rpc,bundle)
case(rpc[3:2])
2'd0:	insn <= bundle[39: 0];
2'd1:	insn <= bundle[79:40];
2'd2:	insn <= bundle[119:80];
2'd3:	insn <= {34'd0,6'd59};	// NOP
endcase
endmodule

module fisa64_itag_ram(wclk, wa, v, wr, rclk, pc, hit);
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
