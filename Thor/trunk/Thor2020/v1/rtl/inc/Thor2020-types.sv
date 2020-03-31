`ifndef TYPES_SV
`define TYPES_SV	1'b1

// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
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

typedef logic [`AMSB:0] tAddress;
typedef logic [63:0] tData;

typedef struct packed {
	logic [40:0] raw;
} tRawInstruction;

typedef struct packed {
	logic [25:0] payload;
	logic [6:0] opcode;
	logic [3:0] pr;
	logic [2:0] pc;
	logic rc;
} tGenInstruction;

typedef struct packed {
	logic [19:0] target;
	logic [2:0] Ca;
	logic [2:0] Ct;
	logic [6:0] opcode;
	logic [3:0] pr;
	logic [2:0] pc;
	logic rc;
} tJmpInstruction;

typedef struct packed {
  logic [6:0] funct;
	logic pad1;
	logic [11:0] imm;
	logic [2:0] Ca;
	logic [2:0] pad3;
	logic [6:0] opcode;
	logic [3:0] pr;
	logic [2:0] pc;
	logic rc;
} tRtsInstruction;

typedef union packed {
	tRawInstruction raw;
	tGenInstruction gen;
	tJmpInstruction jmp;
	tRtsInstruction rts;
} tInstruction;

typedef struct packed {
  logic sign;
  logic [14:0] exp;
  logic [63:0] man;
} tFloat;

`endif
