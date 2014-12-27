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
`define SHIFT		6'd24
`define SHL					3'd0
`define SRU					3'd1
`define SRA					3'd2
`define SHIFTI		6'd25
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

module FISA64b(rst_i, clk_i, bte_o, cti_o, cyc_o, stb_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o);
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
input rst_i;
input clk_i;
output reg [1:0] bte_o;
output reg [2:0] cti_o;
output reg cyc_o;
output reg stb_o;
input ack_i;
output reg we_o;
output reg [3:0] sel_o;
output reg [63:0] adr_o;
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


reg im;								// interrupt mask
reg [2:0] imcd;						// mask countdown
reg [1:0] thread;
reg [63:0] pc,dpc,xpc;
reg [39:0] ir,xir,mir;
wire xsc = xir[31:30];
wire [5:0] xopcode = xir[5:0];
wire [5:0] xfunct = xir[39:34];

wire [7:0] Ra = {thread,ir[11: 6]};
wire [7:0] Rb = {thread,ir[17:12]};
wire [7:0] Rc = {thread,ir[23:18]};
wire [5:0] mopcode = mir[5:0];
wire mmd = mir[29:28];
wire [7:0] mRa = {thread,mir[11: 6]};
wire [7:0] mRb = {thread,mir[17:12]};
reg [7:0] Rt,xRt,mRt,wRt,tRt;

reg [63:0] regfile [255:0];

always @*
casex(Ra)
8'bxx000000:	rfoa <= 64'd0;
xRt:	rfoa <= xres;
wRt:	rfoa <= wres;
tRt:	rfoa <= tres;
8'bxx111111:	rfoa <= pc;
default:	rfoa <= regfile[Ra];
endcase

always @*
case(Rb)
8'bxx000000:	rfob <= 64'd0;
xRt:	rfob <= xres;
wRt:	rfob <= wres;
tRt:	rfob <= tres;
8'bxx111111:	rfob <= pc;
default:	rfob <= regfile[Rb];
endcase

always @*
case(Rc)
8'bxx000000:	rfoc <= 64'd0;
xRt:	rfoc <= xres;
wRt:	rfoc <= wres;
tRt:	rfoc <= tres;
8'bxx111111:	rfoc <= pc;
default:	rfoc <= regfile[Rc];
endcase

function [63:0] pcinc;
input [63:0] pc;
case(pc[1:0])
2'd0:	pcinc <= {pc[63:4],4'd5};
2'd1:	pcinc <= {pc[63:4],4'd10};
2'd2:	pcinc <= {pc[63:4]+60'd1,4'd0};
2'd3:	pcinc <= 64'd0;
endcase
endfunction

wire isCMPI = xopcode==`CMP;

reg advanceWBx;
reg advanceEX;
wire advanceWB = advanceEX | advanceWBx;
wire advanceRF = advanceEX;
wire advanceIF = advanceEX & advanceRF & ihit;

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
endcase

reg isICacheReset;
reg isICacheLoad;
wire [31:0] insn;
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

always @*
case(xopcode)
`RR:
		case(xfunct)
		`ADD:	res <= a + b;
		`SUB:	res <= a - b;
		`CMP:	res <= {nf,vf,60'd0,zf,cf};
		`AND:	res <= a & b;
		`OR:	res <= a | b;
		`EOR:	res <= a ^ b;
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
			default:	res <= 64'd0;
			endcase
		endcase
`ADD:	res <= a + imm;
`SUB:	res <= a - imm;
`CMP:	res <= {nf,vf,60'd0,zf,cf};
`AND:	res <= a & imm;
`OR:	res <= a | imm;
`EOR:	res <= a ^ imm;
`Bcc:	res <= b - 64'd1;			// For DBNZ
default:	res <= 64'd0;
endcase

always @(posedge clk)
if (rst_i) begin
	im <= TRUE;
	imcd <= 3'b111;
end
else begin
case(state)
RUN:
begin

	//-------------------------------------------------------------------------
	// IFETCH stage
	//-------------------------------------------------------------------------
	if (advanceIF) begin
		insncnt <= insncnt + 32'd1;
		if (imcd!=3'b111)
			imcd <= {imcd,1'b0};
		if (imcd==3'b000) begin
			imcd <= 3'b111;
			im <= 1'b0;
		end
		ir <= insn;
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
		xfunct <= funct;
		xpc <= dpc;
		a <= rfoa;
		b <= rfob;
		c <= rfoc;
		
		// Set immediate value
		case(opcode)
		`JMP,`JSR:	imm <= xisImm ? {{10{xir[31]}},xir[31:6],ir[31:6],2'b00} : {{36{ir[31]}},ir[31:6],2'b00};
		`Bcc:		imm <= {{43{ir[39]}},ir[39:21],ir[22:21]};
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`SB,`SC,`SH,`SW:
			imm <= xisImm ? {{24{xir[31]}},xir[31:6],ir[31:18]} : {{50{ir[31]}},ir[31:18]};
		default:	imm <= xisImm ? {xir[23:8],ir[31:16]} : {{16{ir[31]}},ir[31:16]};
		endcase

		// Set target register
		casex(opcode)
		`RR:
			case(funct)
			`ADD,`SUB,`CMP,`MUL,`MULU,`DIV,`DIVU,`AND,`OR,`EOR,
			`MFSPR:
				xRt <= Rc;
			default:	xRt <= {thread,6'd0};
			endcase
		`ADD,`SUB,`MUL,`MULU,`DIV,`DIVU,`AND,`OR,`EOR,
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
	// EXECUTE
	//-------------------------------------------------------------------------

	if (advanceEX) begin
		mir <= xir;
		wRt <= xRt;
		wres <= res;
		ea <= a + (b << xsc) + imm;
		xa <= a;
		xb <= b;
		xc <= c;
		casex(xopcode)
		`Bcc:
			begin
				if (takb) begin
					nop_ir();
					nop_xir();
					if (imm==64'd0)
						pc <= a;
					else begin
						pc[63:16] <= a[63:16] + imm[63:16];
						pc[15:0] <= imm[15:0];
					end
				end
			end
		endcase
	end
	else if (advanceWB) begin
	end

	//-------------------------------------------------------------------------
	// WRITEBACK
	//-------------------------------------------------------------------------
	if (advanceWB) begin
		tRt <= wRt;
		tres <= wres;
		regfile[wRt] <= wres;
		if (wRt[5:0] != 6'd0)
			$display("r%d = %h", wRt[5:0], wres);
	end

end	// RUN

LOADSTORE1:
	begin
		next_state(LOADSTORE2);
		// Handle auto-increment/decrement address mode. Place on result bus
		// for register update. By the time the load / store is complete
		// several clock cycles will have taken place, and the register 
		// update will be long done.
		if (mmd[1]) begin
			if (mRb==6'd0) begin
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
					else begin wres <= {{32{dat16[31]}},dat32}; wb_nack(); next_state(RUN); advanceEX <= TRUE; end
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
					default:	begin wres[63:32] <= {{32{wres[31]}}; wb_nack(); next_state(RUN); advanceEX <= TRUE; end
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
		2'd1:	begin wres[63:56] <= dat32[31:24];
		2'd2:	begin wres[63:48] <= dat32[31:16];
		2'd3:	begin wres[63:40] <= dat32[31: 8];
		endcase
	end
endcase
end

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
	adr_o <= adr;
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
	adr_o <= {adr[63:2] + 62'd1,2'b00};
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
	adr_o <= {adr[63:2]+62'd2,2'b00};
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
	byt:	dat_o <= {8{dat[7:0]}};
	char:	dat_o <= adr[0] ? {4{{dat[7:0],dat[15:8]}}	: {4{dat[15:0]}};
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

task nop_xir;
begin
	xir <= {34'd0,6'd59};	// NOP
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
