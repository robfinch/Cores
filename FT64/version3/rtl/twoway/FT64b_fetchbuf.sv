// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64b_fetchbuf.sv
// - fetch buffer for super barrel processor
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
`include "FT64_defines.svh"

// FETCH
//
// fetch exactly two instructions from memory into the fetch buffer
// unless either one of the buffers is still full, in which case we
// do nothing (kinda like alpha approach)
// Like to turn this into an independent module at some point.
//
module FT64b_fetchbuf(rst, clk, hirq,
	cs_i, cyc_i, stb_i, ack_o, we_i, adr_i, dat_i,
	regLR,
    insn0, insn1, phit0, phit1,
    queued1, queued2, queuedNop,
    pc0, pc1,
    pcndx0, pcndx1,
    next_pc, fetchbuf, fetchbufA_v, fetchbufB_v, fetchbufC_v, fetchbufD_v,
    fetchbufA_instr, fetchbufA_pc,
    fetchbufB_instr, fetchbufB_pc,
    fetchbufC_instr, fetchbufC_pc,
    fetchbufD_instr, fetchbufD_pc,
    fetchbufA_thrd, fetchbufB_thrd, fetchbufC_thrd, fetchbufD_thrd,
    fetchbufA_dc, fetchbufB_dc, fetchbufC_dc, fetchbufD_dc,
    fetchbuf0_instr, fetchbuf1_instr,
    fetchbuf0_thrd, fetchbuf1_thrd,
    fetchbuf0_pc, fetchbuf1_pc,
    fetchbuf0_v, fetchbuf1_v,
    fetchbuf0_dc, fetchbuf1_dc,
    codebuf0, codebuf1,
    nop_fetchbuf
);
parameter AMSB = 31;
parameter RSTPC = 32'hFFFC0100;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
input rst;
input clk;
input [31:0] hirq;
input cs_i;
input cyc_i;
input stb_i;
output ack_o;
input we_i;
input [14:0] adr_i;
input [35:0] dat_i;
input [5:0] regLR;
input [35:0] insn0;
input [35:0] insn1;
input phit0;
input phit1;
input queued1;
input queued2;
input queuedNop;
output reg [AMSB:0] pc0;
output reg [AMSB:0] pc1;
output reg [3:0] pcndx0;
output reg [3:0] pcndx1;
input [31:0] next_pc [0:31];
output reg fetchbuf;
output reg fetchbufA_v;
output reg fetchbufB_v;
output reg fetchbufC_v;
output reg fetchbufD_v;
output fetchbuf0_thrd;
output fetchbuf1_thrd;
output reg [35:0] fetchbufA_instr;
output reg [35:0] fetchbufB_instr;
output reg [35:0] fetchbufC_instr;
output reg [35:0] fetchbufD_instr;
output reg [AMSB:0] fetchbufA_pc;
output reg [AMSB:0] fetchbufB_pc;
output reg [AMSB:0] fetchbufC_pc;
output reg [AMSB:0] fetchbufD_pc;
output reg [4:0] fetchbufA_thrd; 
output reg [4:0] fetchbufB_thrd; 
output reg [4:0] fetchbufC_thrd; 
output reg [4:0] fetchbufD_thrd; 
output reg fetchbufA_dc;
output reg fetchbufB_dc;
output reg fetchbufC_dc;
output reg fetchbufD_dc;
output [35:0] fetchbuf0_instr;
output [35:0] fetchbuf1_instr;
output [AMSB:0] fetchbuf0_pc;
output [AMSB:0] fetchbuf1_pc;
output fetchbuf0_dc;
output fetchbuf1_dc;
output fetchbuf0_v;
output fetchbuf1_v;
input [35:0] codebuf0;
input [35:0] codebuf1;
input [3:0] nop_fetchbuf;

integer n;

// Maps a subset of registers for compressed instructions.
function [5:0] fnRp;
input [3:0] rg;
case(rg)
4'd0:	fnRp = 6'd1;		// return value 0
4'd1:	fnRp = 6'd2;		// return value 1 / temp
4'd2:	fnRp = 6'd3;		// temp
4'd3:	fnRp = 6'd4;		// temp
4'd4:	fnRp = 6'd5;		// temp
4'd5:	fnRp = 6'd11;		// regvar
4'd6:	fnRp = 6'd12;		// regvar
4'd7:	fnRp = 6'd13;		// regvar
4'd8:	fnRp = 6'd14;		// regvar
4'd9:	fnRp = 6'd18;		// arg1
4'd10:	fnRp = 6'd19;		// arg2
4'd11:	fnRp = 6'd20;		// arg3
4'd12:	fnRp = 6'd23;		// constant builder
4'd13:	fnRp = 6'd60;		// exception handler address
4'd14:	fnRp = 6'd61;		// return address
4'd15:	fnRp = 6'd62;		// frame pointer
endcase
endfunction

function [35:0] expand;
input [17:0] cinstr;
casez({cinstr[17:14],cinstr[6]})
5'b00000:	// NOP / ADDI
	case(cinstr[5:0])
	6'd63:	begin
			expand[35:20] = {{7{cinstr[13]}},cinstr[13:8],3'b0};
			expand[19:14] = cinstr[5:0];
			expand[13:8] = cinstr[5:0];
			expand[7] = 1'b1;
			expand[6:0] = `ADDI;
			end
	default:
			begin
			expand[35:20] = {{10{cinstr[13]}},cinstr[13:8]};
			expand[19:14] = cinstr[5:0];
			expand[13:8] = cinstr[5:0];
			expand[7] = 1'b1;
			expand[6:0] = `ADDI;
			end
	endcase
5'b00010:	// SYS
			if (cinstr[5:0]==6'd0) begin
				expand[6:0] = `SYS;
				expand[7] = 1'b1;
				expand[16:8] = {3'd1,cinstr[13:8]};
				expand[17] = 1'b0;
				expand[21:18] = 4'd0;
				expand[26:22] = 5'd1;
				expand[35:27] = 9'd0;
			end
			// LDI
			else begin
				expand[35:20] = {{10{cinstr[13]}},cinstr[13:8]};
				expand[19:14] = cinstr[5:0];
				expand[13:8] = 6'd0;
				expand[7] = 1'b1;
				expand[6:0] = `ORI;
			end
5'b00100:	// RET / ANDI
			if (cinstr[5:0]==6'd0) begin
				expand[6:0] = `RET;
				expand[7] = 1'b1;
				expand[13:8] = 6'h3F;
				expand[19:14] = 6'h3D;
				expand[35:20] = {7'd0,cinstr[13:8],3'd0};
			end
			else begin
				expand[6:0] = `ANDI;
				expand[7] = 1'b1;
				expand[13:8] = cinstr[5:0];
				expand[19:14] = cinstr[5:0];
				expand[35:20] = {{10{cinstr[13]}},cinstr[13:8]};
			end
5'b00110:	// SHLI
			begin
			expand[35:30] = 6'h10;	// SHL
			expand[29] = 1'b1;		// immediate mode
			expand[28:26] = 3'b011;	// word size
			expand[25:20] = cinstr[13:8];	// amount
			expand[19:14] = cinstr[5:0];
			expand[13:8] = cinstr[5:0];
			expand[7] = 1'b1;
			expand[6:0] = 8'h02;		// R2 instruction
			end
5'b01000:
			case(cinstr[5:4])
			2'd0:		// SHRI
				begin
				expand[35:30] = 6'h12;	// SHR
				expand[29] = 1'b1;		// immediate mode
				expand[28:26] = 3'b011;	// word size
				expand[25:20] = cinstr[13:8];	// amount
				expand[19:14] = fnRp(cinstr[3:0]);
				expand[13:8] = fnRp(cinstr[3:0]);
				expand[7] = 1'b1;
				expand[6:0] = 8'h02;		// R2 instruction
				end
			2'd1:		// ASRI
				begin
				expand[35:30] = 6'h13;	// ASR
				expand[29] = 1'b1;		// immediate mode
				expand[28:26] = 3'b011;	// word size
				expand[25:20] = cinstr[13:8];	// amount
				expand[19:14] = fnRp(cinstr[3:0]);
				expand[13:8] = fnRp(cinstr[3:0]);
				expand[7] = 1'b1;
				expand[6:0] = 8'h02;		// R2 instruction
				end
			2'd2:		// ANDI
				begin
				expand[35:20] = {{10{cinstr[13]}},cinstr[13:8]};
				expand[19:14] = fnRp(cinstr[3:0]);
				expand[13:8] = fnRp(cinstr[3:0]);
				expand[7] = 1'b1;
				expand[6:0] = `ORI;
				end
			2'd3:
				case(cinstr[13:12])
				2'd0:	begin
						expand[35:30] = `SUB;
						expand[28:26] = 3'b011;	// word size
						expand[25:20] = fnRp(cinstr[11:8]);
						expand[19:14] = fnRp(cinstr[3:0]);
						expand[13:8] = fnRp(cinstr[3:0]);
						expand[7] = 1'b1;
						expand[6:0] = 8'h02;		// R2 instruction
						end
				2'd1:	begin
						expand[35:30] = `AND;
						expand[28:26] = 3'b011;	// word size
						expand[25:20] = fnRp(cinstr[11:8]);
						expand[19:14] = fnRp(cinstr[3:0]);
						expand[13:8] = fnRp(cinstr[3:0]);
						expand[7] = 1'b1;
						expand[6:0] = 8'h02;		// R2 instruction
						end
				2'd2:	begin
						expand[35:30] = `OR;
						expand[28:26] = 3'b011;	// word size
						expand[25:20] = fnRp(cinstr[11:8]);
						expand[19:14] = fnRp(cinstr[3:0]);
						expand[13:8] = fnRp(cinstr[3:0]);
						expand[7] = 1'b1;
						expand[6:0] = 8'h02;		// R2 instruction
						end
				2'd3:	begin
						expand[35:30] = `XOR;
						expand[28:26] = 3'b011;	// word size
						expand[25:20] = fnRp(cinstr[11:8]);
						expand[19:14] = fnRp(cinstr[3:0]);
						expand[13:8] = fnRp(cinstr[3:0]);
						expand[7] = 1'b1;
						expand[6:0] = 8'h02;		// R2 instruction
						end
				endcase
			endcase
5'b01110:
		begin
			expand[35:25] = {{3{cinstr[13]}},{cinstr[13:8],cinstr[5:4]}};
			expand[24:23] = 2'b11;	// always branch
			expand[22:20] = 3'd0;		// BEQ
			expand[19:8] = 12'd0;		// r0==r0
			expand[7] = 1'b1;
			expand[6:0] = `Bcc;		// 0x38
		end
5'b10??0:
		begin
			expand[35:25] = {{3{cinstr[15]}},{cinstr[15:8]}};
			expand[24:23] = 2'b00;		// predict
			expand[22:20] = 3'd0;			// BEQ
			expand[19:14] = 6'd0;			// r0
			expand[13:8] = cinstr[5:0];	// Ra
			expand[7] = 1'b1;
			expand[6:0] = `Bcc;
		end
5'b11??0:
		begin
			expand[35:25] = {{3{cinstr[15]}},{cinstr[15:8]}};
			expand[24:23] = 2'b00;		// predict
			expand[22:20] = 3'd1;			// BNE
			expand[19:14] = 6'd0;			// r0
			expand[13:8] = cinstr[5:0];	// Ra
			expand[7] = 1'b1;
			expand[6:0] = `Bcc;
		end
5'b00001:
		begin
			expand[35:30] = `MOV;
			expand[29:27] = 3'd7;			// move current to current
			expand[26:20] = 7'd0;			// register set (ignored)
			expand[19:14] = cinstr[13:8];
			expand[13:8] = cinstr[5:0];
			expand[7] = 1'b1;
			expand[6:0] = 8'h02;
		end
5'b00011:	// ADD
		begin
			expand[35:30] = `ADD;
			expand[28:26] = 3'b011;	// word size
			expand[25:20] = cinstr[5:0];
			expand[19:14] = cinstr[13:8];
			expand[13:8] = cinstr[5:0];
			expand[7] = 1'b1;
			expand[6:0] = 8'h02;		// R2 instruction
		end
5'b00101:	// JALR
		begin
			expand[35:20] = 20'd0;
			expand[19:14] = cinstr[13:8];
			expand[13:8] = cinstr[5:0];
			expand[7] = 1'b1;
			expand[6:0] = `JAL;
		end
5'b01001:	// LH Rt,d[SP]
		begin
			expand[35:20] = {{5{cinstr[13]}},cinstr[13:8],3'd0};
			expand[19:14] = cinstr[5:0];
			expand[13:8] = 6'd63;
			expand[7] = 1'b1;
			expand[6:0] = `LH;
		end
5'b01011:	// LW Rt,d[SP]
		begin
			expand[35:20] = {{5{cinstr[13]}},cinstr[13:8],3'd0};
			expand[19:14] = cinstr[5:0];
			expand[13:8] = 6'd63;
			expand[7] = 1'b1;
			expand[6:0] = `LW;
		end
5'b01101:	// LH Rt,d[fP]
		begin
			expand[35:20] = {{5{cinstr[13]}},cinstr[13:8],3'd0};
			expand[19:14] = cinstr[5:0];
			expand[13:8] = 6'd62;
			expand[7] = 1'b1;
			expand[6:0] = `LH;
		end
5'b01111:	// LW Rt,d[FP]
		begin
			expand[35:20] = {{5{cinstr[13]}},cinstr[13:8],3'd0};
			expand[19:14] = cinstr[5:0];
			expand[13:8] = 6'd62;
			expand[7] = 1'b1;
			expand[6:0] = `LW;
		end
5'b10001:	// SH Rt,d[SP]
		begin
			expand[35:20] = {{5{cinstr[13]}},cinstr[13:8],3'd0};
			expand[19:14] = cinstr[5:0];
			expand[13:8] = 6'd63;
			expand[7] = 1'b1;
			expand[6:0] = `SH;
		end
5'b10011:	// SW Rt,d[SP]
		begin
			expand[35:20] = {{5{cinstr[13]}},cinstr[13:8],3'd0};
			expand[19:14] = cinstr[5:0];
			expand[13:8] = 6'd63;
			expand[7] = 1'b1;
			expand[6:0] = `SW;
		end
5'b10101:	// SH Rt,d[fP]
		begin
			expand[35:20] = {{5{cinstr[13]}},cinstr[13:8],3'd0};
			expand[19:14] = cinstr[5:0];
			expand[13:8] = 6'd62;
			expand[7] = 1'b1;
			expand[6:0] = `SH;
		end
5'b10111:	// SW Rt,d[FP]
		begin
			expand[35:20] = {{5{cinstr[13]}},cinstr[13:8],3'd0};
			expand[19:14] = cinstr[5:0];
			expand[13:8] = 6'd62;
			expand[7] = 1'b1;
			expand[6:0] = `SW;
		end
5'b11001:
		begin
			expand[35:20] = {{9{cinstr[13:12]}},cinstr[5:4],3'd0};
			expand[19:14] = fnRp(cinstr[11:8]);
			expand[13:8] = fnRp(cinstr[3:0]);
			expand[7] = 1'b1;
			expand[6:0] = `LW;
		end
5'b11111:
		begin
			expand[35:20] = {{9{cinstr[13:12]}},cinstr[5:4],3'd0};
			expand[19:14] = fnRp(cinstr[11:8]);
			expand[13:8] = fnRp(cinstr[3:0]);
			expand[7] = 1'b1;
			expand[6:0] = `SW;
		end
default:
		begin
			expand[35:8] = 28'd0;
			expand[7] = 1'b1;
			expand[6:0] = `NOP;
		end
endcase

endfunction

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

assign ack_o = cs_i & cyc_i & stb_i;
reg [35:0] DecompressTable [0:4095];
always @(posedge clk)
if (cyc_i & stb_i & we_i & cs_i)
	DecompressTable[adr_i[14:3]] <= dat_i[35:0];
wire [35:0] expand0 = DecompressTable[{insn0[6],insn0[17:7]}];
wire [35:0] expand1 = DecompressTable[{insn1[6],insn1[17:7]}];

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 


reg [31:0] pc0n [0:15];
reg [31:0] pc1n [0:15];

always @(posedge clk)
if (rst) begin
	for (n = 0; n < 16; n = n + 1)
	begin
		pc0n[n] <= RSTPC;
		pc1n[n] <= RSTPC;
    end
    pcndx0 <= 4'd0;
    pcndx1 <= 4'd0;
	fetchbufA_v <= 0;
	fetchbufB_v <= 0;
	fetchbufC_v <= 0;
	fetchbufD_v <= 0;
	fetchbuf <= 0;
end
else begin
	
    if (fetchbuf == 1'b0) case ({fetchbufA_v, fetchbufB_v, (queued1|queuedNop), (queued2|queuedNop)})
	4'b00_00 : ;	// do nothing
//		4'b00_01 : panic <= `PANIC_INVALIDIQSTATE;
	4'b00_10 : ;	// do nothing
	4'b00_11 : ;	// do nothing
	4'b01_00 : ;	// do nothing
//		4'b01_01 : panic <= `PANIC_INVALIDIQSTATE;

	4'b01_10,
	4'b01_11 : begin	// enqueue fbB and flip fetchbuf
		 fetchbufB_v <= `INV;
		  fetchbuf <= ~fetchbuf;
	    end

	4'b10_00 : ;	// do nothing
//		4'b10_01 : panic <= `PANIC_INVALIDIQSTATE;

	4'b10_10,
	4'b10_11 : begin	// enqueue fbA and flip fetchbuf
		 fetchbufA_v <= `INV;
		  fetchbuf <= ~fetchbuf;
	    end

	4'b11_00 : ;	// do nothing
//		4'b11_01 : panic <= `PANIC_INVALIDIQSTATE;

	4'b11_10 : begin	// enqueue fbA but leave fetchbuf
		 fetchbufA_v <= `INV;
	    end

	4'b11_11 : begin	// enqueue both and flip fetchbuf
		 fetchbufA_v <= `INV;
		 fetchbufB_v <= `INV;
		  fetchbuf <= ~fetchbuf;
	    end
	default:  ;
    endcase
    else case ({fetchbufC_v, fetchbufD_v, (queued1|queuedNop), (queued2|queuedNop)})
	4'b00_00 : ;	// do nothing
//		4'b00_01 : panic <= `PANIC_INVALIDIQSTATE;
	4'b00_10 : ;	// do nothing
	4'b00_11 : ;	// do nothing
	4'b01_00 : ;	// do nothing
//		4'b01_01 : panic <= `PANIC_INVALIDIQSTATE;

	4'b01_10,
	4'b01_11 : begin	// enqueue fbD and flip fetchbuf
		 fetchbufD_v <= `INV;
		  fetchbuf <= ~fetchbuf;
	    end

	4'b10_00 : ;	// do nothing
//		4'b10_01 : panic <= `PANIC_INVALIDIQSTATE;

	4'b10_10,
	4'b10_11 : begin	// enqueue fbC and flip fetchbuf
		 fetchbufC_v <= `INV;
		  fetchbuf <= ~fetchbuf;
	    end

	4'b11_00 : ;	// do nothing
//		4'b11_01 : panic <= `PANIC_INVALIDIQSTATE;

	4'b11_10 : begin	// enqueue fbC but leave fetchbuf
		 fetchbufC_v <= `INV;
	    end

	4'b11_11 : begin	// enqueue both and flip fetchbuf
		 fetchbufC_v <= `INV;
		 fetchbufD_v <= `INV;
		  fetchbuf <= ~fetchbuf;
	    end
	default:  ;
    endcase
    //
    // get data iff the fetch buffers are empty
    //
    if (fetchbufA_v == `INV && fetchbufB_v == `INV) begin
        FetchAB();
        // fetchbuf steering logic correction
        if (fetchbufC_v==`INV && fetchbufD_v==`INV && phit0 && phit1)
              fetchbuf <= 1'b0;
    end
    else if (fetchbufC_v == `INV && fetchbufD_v == `INV)
	    FetchCD();
	
	// The fetchbuffer is invalidated at the end of a vector instruction
	// queue.
	if (nop_fetchbuf[0])  fetchbufA_v <= `INV;
	if (nop_fetchbuf[1])  fetchbufB_v <= `INV;
	if (nop_fetchbuf[2])  fetchbufC_v <= `INV;
	if (nop_fetchbuf[3])  fetchbufD_v <= `INV;
end

assign fetchbuf0_instr = (fetchbuf == 1'b0) ? fetchbufA_instr : fetchbufC_instr;
assign fetchbuf0_v     = (fetchbuf == 1'b0) ? fetchbufA_v     : fetchbufC_v    ;
assign fetchbuf0_pc    = (fetchbuf == 1'b0) ? fetchbufA_pc    : fetchbufC_pc   ;
assign fetchbuf0_thrd  = (fetchbuf == 1'b0) ? fetchbufA_thrd  : fetchbufC_thrd ;
assign fetchbuf0_dc    = (fetchbuf == 1'b0) ? fetchbufA_dc    : fetchbufC_dc   ;
assign fetchbuf1_instr = (fetchbuf == 1'b0) ? fetchbufB_instr : fetchbufD_instr;
assign fetchbuf1_v     = (fetchbuf == 1'b0) ? fetchbufB_v     : fetchbufD_v    ;
assign fetchbuf1_pc    = (fetchbuf == 1'b0) ? fetchbufB_pc    : fetchbufD_pc   ;
assign fetchbuf1_dc    = (fetchbuf == 1'b0) ? fetchbufB_dc    : fetchbufD_dc   ;
assign fetchbuf1_thrd  = (fetchbuf == 1'b0) ? fetchbufB_thrd  : fetchbufD_thrd ;

wire insn0_dc = insn0[6:0]==7'b0010000 || insn0[6:0]==7'b1101000;
wire insn1_dc = insn1[6:0]==7'b0010000 || insn1[6:0]==7'b1101000;

task FetchA;
begin
    if (insn0[`INSTRUCTION_OP]==`EXEC)
         fetchbufA_instr <= codebuf0;
    else if (insn0_dc)
         fetchbufA_instr <= expand0;
//    else if (insn0[7])
//         fetchbufA_instr <= expand(insn0[17:0]);
    else
         fetchbufA_instr <= insn0;
     fetchbufA_v <= `VAL;
     fetchbufA_pc <= pc0;
     fetchbufA_thrd <= {1'b0,pcndx0};
     if (phit0 && ~hirq[{1'b0,pcndx0}]) begin
	     pc0n[pcndx0] <= next_pc[{1'b0,pcndx0}];
	     pcndx0 <= pcndx0 + 4'd1;
	     pc0 <= pc0n[pcndx0 + 4'd1];
	 end
end
endtask

task FetchB;
begin
    if (insn1[`INSTRUCTION_OP]==`EXEC)
         fetchbufB_instr <= codebuf1;
    else if (insn1_dc)
         fetchbufB_instr <= expand1;
//    else if (insn1[7])
//         fetchbufB_instr <= expand(insn1[17:0]);
    else
         fetchbufB_instr <= insn1;
     fetchbufB_v <= `VAL;
     fetchbufB_pc <= pc1;
     fetchbufB_thrd <= {1'b1,pcndx1};
     if (phit1 && ~hirq[{1'b1,pcndx1}]) begin
	     pc1n[pcndx1] <= next_pc[{1'b1,pcndx1}];
	     pcndx1 <= pcndx1 + 4'd1;
	     pc1 <= pc1n[pcndx1 + 4'd1];
	 end
end
endtask


task FetchAB;
begin
	FetchA();
	FetchB();
end
endtask

task FetchC;
begin
    if (insn0[`INSTRUCTION_OP]==`EXEC)
         fetchbufC_instr <= codebuf0;
    else if (insn0_dc)
         fetchbufC_instr <= expand0;
//    else if (insn0[7])
//         fetchbufC_instr <= expand(insn0[17:0]);
    else
         fetchbufC_instr <= insn0;
     fetchbufC_v <= `VAL;
     fetchbufC_pc <= pc0;
     fetchbufC_thrd <= {1'b0,pcndx0};
     if (phit0 && ~hirq[{1'b0,pcndx0}]) begin
	     pc0n[pcndx0] <= next_pc[{1'b0,pcndx0}];
	     pcndx0 <= pcndx0 + 4'd1;
	     pc0 <= pc0n[pcndx0 + 4'd1];
	 end
end
endtask

task FetchD;
begin
    if (insn1[`INSTRUCTION_OP]==`EXEC)
         fetchbufD_instr <= codebuf1;
    else if (insn1_dc)
         fetchbufD_instr <= expand1;
//    else if (insn1[7])
//         fetchbufD_instr <= expand(insn1[17:0]);
    else
         fetchbufD_instr <= insn1;
     fetchbufD_v <= `VAL;
     fetchbufD_pc <= pc1;
     fetchbufD_thrd <= {1'b1,pcndx1};
     if (phit1 && ~hirq[{1'b1,pcndx1}]) begin
	     pc1n[pcndx1] <= next_pc[{1'b1,pcndx1}];
	     pcndx1 <= pcndx1 + 4'd1;
	     pc1 <= pc1n[pcndx1 + 4'd1];
	 end
end
endtask

task FetchCD;
begin
	FetchC();
	FetchD();
end
endtask

endmodule
