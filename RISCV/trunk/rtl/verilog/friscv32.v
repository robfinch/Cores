`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	friscv32.v
//  - RISC-V ISA compatible
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
//
// ============================================================================
//
`include "friscv32-config.v"
`include "friscv32-defines.v"

module friscv32(hartid_i, rst_i, clk_i, tm_clk_i, irq_i, cause_i,
	cyc_o, stb_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o);
input [31:0] hartid_i;
input rst_i;
input clk_i;
input tm_clk_i;
input irq_i;
input [7:0] cause_i;
output reg cyc_o;
output reg stb_o;
input ack_i;
output reg we_o;
output reg [3:0] sel_o;
output reg [31:0] adr_o;
input [31:0] dat_i;
output reg [31:0] dat_o;

parameter RESET = 4'd0;
parameter IFETCH = 4'd1;
parameter IFETCH_NACK = 4'd2;
parameter DECODE = 4'd3;
parameter EXECUTE = 4'd4;
parameter MEMORY = 4'd5;
parameter MEMORY_NACK = 4'd6;
parameter MEMORY2 = 4'd7;
parameter MEMORY2_NACK = 4'd8;

// CSRs
parameter MSTATUS 	= 12'h300;
parameter MTVEC  	= 12'h301;
parameter MIE     	= 12'h304;
parameter MSCRATCH	= 12'h340;
parameter MEPC    	= 12'h341;
parameter MCAUSE  	= 12'h342;
parameter MBADADDR 	= 12'h343;
parameter MTOHOST 	= 12'h780;
parameter MFROMHOST = 12'h781;
parameter RDCYCLE 	= 12'hC00;
parameter RDTIME  	= 12'hC01;
parameter RDINSTRET	= 12'hC02;
parameter RDCYCLEH	= 12'hC80;
parameter RDTIMEH 	= 12'hC81;
parameter RDINSTRETH= 12'hC82;
parameter MCPUID  	= 12'hF00;
parameter MIMPID  	= 12'hF01;
parameter MHARTID 	= 12'hF10;

reg [3:0] state;
reg [31:0] ir;
reg [31:0] pc;
wire [6:0] opcode = ir[6:0];
wire [2:0] funct3 = ir[14:12];
wire [6:0] funct7 = ir[31:25];
wire [4:0] Rs1 = ir[`RS1];
wire [4:0] Rs2 = ir[`RS2];
reg [4:0] Rd;
reg rfwr;
reg [31:0] regfile [0:31];
reg [31:0] sp [0:3];
wire [31:0] rfoa = Rs1==5'd14 ? sp[ol] : regfile[Rs1];
wire [31:0] rfob = Rs2==5'd14 ? sp[ol] : regfile[Rs2];
reg [31:0] a,b,imm,res,dp_o;
wire [55:0] bx;

// CSRs
reg [31:0] mstatus;
reg [63:0] mhartid;
reg [63:0] mscratch;
reg [63:0] rdcycle;
reg [63:0] rdinstret;
reg [63:0] rdtime,rdtimes;

wire [1:0] ol = mstatus[2:1];

reg [7:0] sel_wide;
reg [31:0] din;			// data input latch
wire [7:0] byte_in = din >> {adr_o[1:0],3'b0};
wire [15:0] half_in = din >> {adr_o[1],4'b0};
wire [31:0] word_in = din;

//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
wire [31:0] sum = a + b;
wire [31:0] dif = a - b;
wire [31:0] sumi = a + imm;
wire [31:0] shl32 = a[31:0] << b[4:0];
wire [31:0] shr32 = a[31:0] >> b[4:0];
assign bx = b << {sumi[1:0],3'b0};

always @*
case(opcode)
`LUI:	dp_o <= imm;
`AUIPC:	dp_o <= {pc[31:12] + imm[31:12],12'h000};
`JAL:	dp_o <= pc;
`JALR:	dp_o <= pc;
`ALU1:
		case(xfunct3)
		`ADDI:	dp_o <= sumi;
		`SLTI:	dp_o <= $signed(a) < $signed(imm);
		`SLTIU:	dp_o <= a < imm;
		`XORI:	dp_o <= a ^ imm;
		`ORI:	dp_o <= a | imm;
		`ANDI:	dp_o <= a & imm;
		`SLI:
		    case(ir[31:26])
		    6'h00:  dp_o <= a << ir[24:20];
		    default:  dp_o <= 32'd0;
		    endcase
		`SRI:
			if ((ir[31:26]==6'b010000) && a[31])
				dp_o <= (a >> ir[24:20]) | ~(64'hFFFFFFFFFFFFFFFF >> ir[24:20]);
			else
				dp_o <= a >> ir[24:20];
    default:    dp_o <= 32'd0;
		endcase
`RR:
		case(xfunct3)
		`GRP0:
		  case(xfunct7)
		  7'b0000000:  dp_o <= sum;
		  7'b0100000:  dp_o <= dif;
		  default:    dp_o <= 32'd0;
		  endcase
		`GRP1:
		  case(xfunct7)
		  7'b0000000: dp_o <= a << b[4:0];
		  default:    dp_o <= 32'd0;
		  endcase
		`GRP2:
		  case(xfunct7)
		  7'b0000000: dp_o <= $signed(a) < $signed(b); // SLT
		  default:    dp_o <= 32'd0;
		  endcase	
		`GRP3:
		  case(xfunct7)	
		  7'b0000000: dp_o <= a < b;         // SLTU
		  default:    dp_o <= 32'd0;
		  endcase
		`XOR:		dp_o <= a ^ b;
		`SRAL:
			if (ir[30] & a[31])
				dp_o <= (a >> b[4:0]) | ~(64'hFFFFFFFFFFFFFFFF >> b[4:0]);
			else
				dp_o <= a >> b[4:0];
		`OR:		dp_o <= a | b;
		`AND:		dp_o <= a & b;
	  default:    dp_o <= 32'd0;
		endcase
`RRW:
		case(funct3)
		`GRP0:
		  case(xfunct7)
		  7'b0000000:  dp_o <= sum;
		  7'b0100000:  dp_o <= dif;
		  default:    dp_o <= 32'd0;
		  endcase
		`GRP1:
		  case(xfunct7)
		  7'b0000000: dp_o <= shl32;
		  default:    dp_o <= 32'd0;
		  endcase
		`SRALW:
			if (ir[30] & a[31])
				dp_o <= {32'hFFFFFFFF,shr32 | ~(32'hFFFFFFFF >> b[4:0])};
			else
				dp_o <= shr32;
		endcase
//`Lx:	dp_o <= ldp_o;
`SYSTEM:
	case(funct3)
	3'b000:
		casez(ir[31:20])
		12'b0000_0000_0000: dp_o <= pc; // ECALL
		12'b0000_0000_0001: dp_o <= pc; // EBREAK
		default:  dp_o <= pc;
		endcase
	default:
		case(ir[31:20])
		MSTATUS:  	dp_o <= mstatus;
		MSCRATCH: 	dp_o <= mscratch;
		MHARTID:  	dp_o <= mhartid;
		RDCYCLE:		dp_o <= rdcycle;
		RDTIME:			dp_o <= rdtimes;
		RDINSTRET:	dp_o <= rdinstret;
		endcase
	endcase
default:	dp_o <= 32'd0;
endcase

// State machine
//
// Pretty simple, fetch, decode, execute and memory. Fetch and memory have nack
// states associated with them to allow the slave time to get off the bus
// before the next bus cycle begins.

always @(posedge clk_i)
if (rst_i)
	goto(RESET);
else
case(state)
RESET:		goto(IFETCH);
IFETCH:		if (ack_i)
				goto(IFETCH_NACK);
IFETCH_NACK:
			if (~ack_i)
				goto(DECODE);
DECODE:		goto(EXECUTE);
EXECUTE:	if (opcode==`Lx || opcode==`Sx)
				goto(MEMORY);
			else
				goto(IFETCH);
MEMORY:		if (ack_i)
				goto(MEMORY_NACK);
MEMORY_NACK:
			if (~ack_i)
				goto(|sel_wide[7:4] ? MEMORY2 : IFETCH);
MEMORY2:	if (ack_i)
				goto (MEMORY2_NACK);
MEMORY2_NACK:
			if (~ack_i)
				goto (IFETCH);
// Hardware error so reset, otherwise can't get to this state.
default:	goto(RESET);
endcase
end

// Bus interfacing
always @(posedge clk_i)
case(state)
RESET:
	wb_nack();
IFETCH:
	if (!cyc_o) begin
		cyc_o <= `HIGH;
		stb_o <= `HIGH;
		sel_o <= 4'hF;
		adr_o <= pc;
	end
	else if (ack_i)
		wb_nack();
EXECUTE:
	begin
		case(opcode)
		`Lx:
			case(funct3)
			`LB,`LBU:
				begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				sel_o <= 4'h1 << sumi[1:0];
				sel_wide <= 4'h1 << sumi[1:0];
				adr_o <= {sumi[31:2],2'h0};
				end
			`LH,`LHU:
				begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				sel_o <= 4'h3 << sumi[1:0];
				sel_wide <= 4'h3 << sumi[1:0];
				adr_o <= {sumi[31:3],2'b0};
				end
			`LW,`LWU:
				begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				sel_o <= 4'hF << sumi[1:0];
				sel_wide <= 4'hF << sumi[1:0];
				adr_o <= {sumi[31:2],2'b0};
				end
			endcase
		`Sx:
			case(funct3)
			`SB:
				begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				we_o <= `HIGH;
				sel_o <= 4'h1 << sumi[1:0];
				sel_wide <= 4'h1 << sumi[1:0];
				adr_o <= {sumi[31:2],2'h0};
				dat_o <= bx[31:0];
				end
			`SH:
				begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				we_o <= `HIGH;
				sel_o <= 4'h3 << sumi[1:0];
				sel_wide <= 4'h3 << sumi[1:0];
				adr_o <= {sumi[31:2],2'h0};
				dat_o <= bx[31:0];
				end
			`SW:
				begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				we_o <= `HIGH;
				sel_o <= 4'hF << sumi[1:0];
				sel_wide <= 4'h1 << sumi[1:0];
				adr_o <= {sumi[31:2],2'd0};
				dat_o <= bx[31:0];
				end
			endcase
		endcase
	end
MEMORY:
	if (ack_i) begin
		if (|sel_wide[7:4])
			stb_o <= `LOW;
		else
			wb_nack();
	end
MEMORY_NACK:
	if (|sel_wide[7:4]) begin
		sel_o <= sel_wide[7:4];
		stb_o <= `HIGH;
		adr_o[31:2] <= adr_o[31:2] + 30'd1;
		dat_o <= {8'h00,bx[55:32]};
	end
MEMORY2:
	if (ack_i)
		wb_nack();
endcase

// Register file update signal
always @(posedge clk_i)
begin
rfwr <= `FALSE;		// Just pulse for one clock
case(state)
RESET:	rfwr <= `TRUE;
EXECUTE:
	case(opcode)
	`LUI:	rfwr <= `TRUE;
	`AUIPC: rfwr <= `TRUE;
	`JAL:	rfwr <= `TRUE;
	`JALR:	rfwr <= `TRUE;
	`ALU1:	rfwr <= `TRUE;
	`RR:	rfwr <= `TRUE;
	`RRW:	rfwr <= `TRUE;
	default:	;
	endcase
MEMORY_NACK:
	if (~ack_i && opcode == `Lx)
		rfwr <= `TRUE;
MEMORY_NACK2:
	if (~ack_i && opcode == `Lx)
		rfwr <= `TRUE;
default:	;
endcase
end

// Register file update
always @(posedge clk_i)
if (rfwr)
begin
	regfile[Rd] <= |Rd ? res : 32'd0;
	if (Rd==5'd14)
		sp[ol] <= res;
end

// Determining when to branch
reg takb;
always @*
  case(funct3)
  `BEQ:	takb <= (a == b);
  `BNE:	takb <= (a != b);
  `BLT:	takb <= ($signed(a) < $signed(b));
  `BGE:	takb <= ($signed(a) >= $signed(b));
  `BLTU:	takb <= (a < b);
  `BGEU:	takb <= (a >= b);
  default:	takb <= `FALSE;
  endcase

// PC register
always @(posedge clk_i)
case(state)
RESET:
	pc <= `RSTPC;
EXECUTE:
	case(opcode)
	`JAL:	pc <= imm;
	`JALR:	pc <= {sumi[31:2],2'b00};
	`Bcc:	if (takb)
				pc <= pc + imm;
	default:	pc <= pc + 32'd4;
	endcase
endcase

// Loading instruction register
always @(posedge clk_i)
if (state==IFETCH_NACK)
	if (~ack_i)
		ir <= word_in;

// Decode destination register
always @(posedge clk_i)
if (state==RESET)
	Rd <= 5'd0;
else if (state==DECODE)
	case(opcode)
	`LUI:	Rd <= ir[`RD];
	`AUIPC:	Rd <= ir[`RD];
	`JAL:	Rd <= ir[`RD];
	`JALR:	Rd <= ir[`RD];
	`ALU1:	Rd <= ir[`RD];
	`RR:	Rd <= ir[`RD];
	`RRW:	Rd <= ir[`RD];
	`Lx:	Rd <= ir[`RD];
	default:	Rd <= 5'd0;
	endcase

// Handle operands
always @(posedge clk_i)
if (state==DECODE)
	a <= rfoa;
always @(posedge clk_i)
if (state==DECODE)
	b <= rfob;
always @(posedge clk_i)
if (state==DECODE)
	case(opcode)
	`LUI:	imm <= {{32{ir[31]}},ir[31:12],12'h000};
	`AUIPC:	imm <= {{32{ir[31]}},ir[31:12],12'h000};
	`JAL:	imm <= {{53{ir[31]}},ir[31],ir[19:12],ir[20],ir[30:22],2'b0};
	`JALR:	imm <= {{52{ir[31]}},ir[31:20]};
	`ALU1:	imm <= {{52{ir[31]}},ir[31:20]};
	`Bcc:	imm <= {{52{ir[31]}},ir[31],ir[7],ir[30:25],ir[11:9],2'b0};
	`Lx:	imm <= {{52{ir[31]}},ir[31:20]};
	`Sx:	imm <= {{52{ir[31]}},ir[31:25],ir[11:7]};
	default:imm <= {{52{ir[31]}},ir[31:20]};
	endcase

// Data input latch
always @(posedge clk_i)
if (ack_i)
	din <= dat_i;

// Get results
always @(posedge clk_i)
case(state)
RESET:	res <= 32'd0;	// To load x0 with 0.
EXECUTE:	res <= dp_o;
MEMORY_NACK:
	case(opcode)
	`Lx:
		case(funct3)
		`LB:	res <= {{24{byte_in[7]}},byte_in};
		`LBU:	res <= {{24{1'b0}},byte_in};
		`LH:	res <= {{16{half_in[15]}},half_in};
		`LHU:	res <= {{16{1'b0}},half_in};
		`LW:	res <= word_in;
		`LWU:	res <= word_in;
		default:	;
		endcase
	default:	;
	endcase
MEMORY2_NACK:
	case(opcode)
	`Lx:
		case(funct3)
		`LH:	res <= {{16{byte_in[7]}},byte_in,res[7:0]};
		`LHU:	res <= {{16{1'b0}},byte_in,res[7:0]};
		`LW:	
			case(sel_wide[7:4])
			4'b0001:	res <= {word_in[7:0],res[23:0]};
			4'b0011:	res <= {word_in[15:0],res[15:0]};
			default:	res <= {word_in[23:0],res[7:0]};
			endcase
		`LWU:
			case(sel_wide[7:4])
			4'b0001:	res <= {word_in[7:0],res[23:0]};
			4'b0011:	res <= {word_in[15:0],res[15:0]};
			default:	res <= {word_in[23:0],res[7:0]};
			endcase
		default:	;
		endcase
	endcase
default:	;
endcase

always @(posedge clk_i)
mhartid <= hartid_i;

always @(posedge clk_i)
if (state==RESET)
	rdcycle <= 64'd0;
else
	rdcycle <= rdcycle + 64'd1;

always @(posedge clk_i)
if (state==RESET)
	rdinstret <= 64'd0;
else if (state==EXECUTE)
	rdinstret <= rdinstret + 64'd1;

always @(posedge tm_clk_i)
if (rst_i)
	rdtime <= 64'd0;
else
	rdtime <= rdtime + 64'd1;
always @(posedge clk_i)
	rdtimes <= rdtime;


always @(posedge clk_i)
if (state==EXECUTE)
if (opcode==`SYSTEM)
	case(funct3)
    3'b001: write_csr(funct3,ir[31:20],Ra,a);
    3'b010: write_csr(funct3,ir[31:20],Ra,a);
    3'b101: write_csr(funct3,ir[31:20],5'd31,imm);
    3'b110: write_csr(funct3,ir[31:20],5'd31,imm);
    default:	;
	endcase

task goto;
input [3:0] nst;
begin
	state <= nst;
end
endtask

task wb_nack;
begin
	cyc_o <= `LOW;
	stb_o <= `LOW;
	we_o <= `LOW;
	sel_o <= 8'h00;
end
endtask

task write_csr;
input [2:0] funct3;
input [11:0] csrno;
input [4:0] regno;
input [63:0] val;
begin
if (regno != 5'd0)
case(csrno)
MSTATUS:	mstatus <= val;
MSCRATCH:	mscratch <= val;
endcase
end
endtask

endmodule

