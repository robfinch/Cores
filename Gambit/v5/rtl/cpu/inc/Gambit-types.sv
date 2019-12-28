// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
// Types
`ifndef TYPES_H
`define TYPES_H		1
//`include ".\Gambit-config.sv"

typedef struct packed
{
logic [1:0] fl;
logic [5:0] opcode;
logic [3:0] tgt;
logic [3:0] src1;
logic [3:0] src2;
logic [3:0] cnst;
} MicroOp;

typedef logic [7:0] MicroOpPtr;

typedef logic [`ABITS] Address;
typedef logic [`QBITS] Qid;

// Different Instruction Formats

typedef struct packed
{
	logic [6:0] opcode;
	logic [44:0] payload;
} Gen_Instruction;

typedef struct packed
{
	logic [6:0] opcode;
	logic [4:0] Rt;
	logic [4:0] Ra;
	logic [7:0] imm8;
	logic one;
	logic [25:0] pad;
} RI8_Instruction;

typedef struct packed
{
	logic [6:0] opcode;
	logic [4:0] Rt;
	logic [4:0] Ra;
	logic [4:0] Rb;
	logic [2:0] padr;
	logic zero;
	logic [25:0] pad;
} RR_Instruction;

typedef struct packed
{
	logic [6:0] opcode;
	logic [4:0] Rt;
	logic [4:0] Ra;
	logic [21:0] imm22;
	logic [12:0] pad13;
} RI22_Instruction;

typedef struct packed
{
	logic [6:0] opcode;
	logic [4:0] Rt;
	logic [4:0] Ra;
	logic [34:0] imm35;
} RI35_Instruction;

typedef struct packed
{
	logic [6:0] opcode;
	logic [4:0] Rt;
	logic [4:0] Ra;
	logic [29:0] imm30;
	logic [4:0] pad5;
} RIS_Instruction;

typedef struct packed
{
	logic [6:0] opcode;
	logic [1:0] exop;
	logic [1:0] pred;
	logic [2:0] cr;
	logic [11:0] disp;
	logic [25:0] pad25;
} Branch_Instruction;

typedef struct packed
{ 
	logic [6:0] opcode;
	logic [4:0] Rt;
	logic [4:0] Ra;
	logic [11:0] regno;
	logic [3:0] pad4;
	logic [2:0] ol;
	logic [2:0] op;
	logic [12:0] pad13;
} CSR_Instruction;

typedef struct packed
{
	logic [6:0] opcode;
	logic [1:0] lk;
	logic [42:0] addr;
} Jal_Instruction;

typedef struct packed
{
	logic [6:0] opcode;
	logic [1:0] lk;
	logic [3:0] Ra;
	logic [38:0] pad39;
} Jalrn_Instruction;

typedef struct packed
{
	logic [6:0] opcode;
	logic [1:0] exop;
	logic [1:0] lk;
	logic [1:0] pad2;
	logic [38:0] pad39;
} Ret_Instruction;

typedef struct packed
{
	logic [6:0] opcode;
	logic [1:0] exop;
	logic [3:0] sigmsk;
	logic [38:0] pad39;
} Wai_Instruction;

typedef struct packed
{
	logic [6:0] opcode;
	logic [1:0] exop;
	logic [3:0] cnst;
	logic [38:0] pad39;
} Stp_Instruction;

typedef struct packed
{
	logic [6:0] opcode;
	logic [4:0] Ra;
	logic pad1;
	logic [12:0] pl;
	logic [2:0] tgt;
	logic [3:0] imask;
	logic [5:0] pad6;
	logic [12:0] pad13;
} Rex_Instruction;

typedef struct packed
{
	logic [6:0] opcode;
	logic [4:0] Rt;
	logic [4:0] Ra;
	logic [1:0] icmd;
	logic [2:0] dcmd;
	logic [2:0] pad3;
	logic zero;
	logic [25:0] pad26;
} Cache_Instruction;

typedef struct packed
{
	logic [51:0] bits;
} RAW_Instruction;

typedef union packed
{
	logic [51:0] raw;
	Gen_Instruction gen;
	RR_Instruction rr;
	RI8_Instruction ri8;
	RI22_Instruction ri22;
	RI35_Instruction ri35;
	RIS_Instruction ris;
	Branch_Instruction br;
	Jal_Instruction jal;
	Jalrn_Instruction jalrn;
	Ret_Instruction ret;
	Wai_Instruction wai;
	Stp_Instruction stp;
	Rex_Instruction rex;
	CSR_Instruction csr;
	Cache_Instruction cache;
} Instruction;

// Re-order buffer entry
typedef struct packed
{
	Qid id;
	logic [1:0] state;
	Address pc;
	Instruction instr;
	logic [7:0] exc;
	Address ma;
	logic [51:0] res;
	logic [`RBIT:0] tgt;
	logic rfw;
} RobEntry;

class Rob;
	integer n, i;
	RobEntry robEntries [0:`RENTRIES-1];

	function [`RENTRIES-1:0] GetV;
		for (n = 0; n < `RENTRIES; n = n + 1)
			GetV[n] = robEntries[n].state != 2'b0;	// INVALID
	endfunction
	function logic[1:0] [0:`RENTRIES-1] GetState;
		for (n = 0; n < `RENTRIES; n = n + 1)
			GetState[n] = robEntries[n].state;
	endfunction

	task display;
	input [`RBITS] head;
	input [`RBITS] tail;
	begin
	$display ("------------- Reorder Buffer ------------");
	for (i = 0; i < `RENTRIES; i = i + 1)
	$display("%c%c %d(%d): %c %h %d %h #",
		 (i[`RBITS]==head)?"C":".",
		 (i[`RBITS]==tail)?"Q":".",
		  i[`RBITS],
		  robEntries[i].id,
		  robEntries[i].state==2'd0 ? "-" :
		  robEntries[i].state==2'd1 ? "A"  :
		  robEntries[i].state==2'd2 ? "C"  : "D",
		  robEntries[i].exc,
		  robEntries[i].tgt,
		  robEntries[i].res
		);
	end
	endtask

endclass

`endif
