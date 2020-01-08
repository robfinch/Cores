`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2019-2020  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@opencores.org
//       ||
//
// rtf65004-types.sv
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
`ifndef RTF65004_TYPES
`define RTF65004_TYPES	1'b1

typedef logic [47:0] MacroInstr;
typedef logic [2:0] ILen;
typedef logic [`ABITS] Address;
typedef logic [`QBITS] Qid;
typedef logic [`RBITS] Rid;

typedef struct packed
{
	logic [`UOQ_ENTRIES-1:0] v;
	Address [`UOQ_ENTRIES-1:0] pc;
	MacroInst [`UOQ_ENTRIES-1:0] inst;
	ILen [`UOQ_ENTRIES-1:0] ilen;
	MicroOp [`UOQ_ENTRIES-1:0] uop;
} uOPQ;

typedef struct packed
{
	logic [`IQ_ENTRIES-1:0] v;
	logic [`IQ_ENTRIES-1:0] queued;
	logic [`IQ_ENTRIES-1:0] out;
	logic [`IQ_ENTRIES-1:0] agen;
	logic [`IQ_ENTRIES-1:0] mem;
	logic [`IQ_ENTRIES-1:0] done;
	logic [`IQ_ENTRIES-1:0] cmt;
} IQState;

typedef struct packed
{
	IQState iqs;
	Address predicted_pc;
	logic [`IQ_ENTRIES-1:0] sync;
	logic [`IQ_ENTRIES-1:0] prior_sync;
	Qid [`IQ_ENTRIES-1:0] prior_sync_qid;
} IQ;

`endif
