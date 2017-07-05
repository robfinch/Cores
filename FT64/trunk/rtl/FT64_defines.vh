// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_defines.v
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
`define HIGH        1'b1
`define LOW         1'b0
`define TRUE        1'b1
`define FALSE       1'b0

`define ZERO		64'd0

`define BRK     5'd0
`define Bcc     5'd1
`define BEQZ        3'd0
`define BNEZ        3'd1
`define BMI         3'd2
`define BPL         3'd3
`define BLTZ        3'd2
`define BGEZ        3'd3
`define RR      5'd2
`define ADD	        5'd4
`define SUB         6'd5
`define CMP         5'd6
`define CMPU        5'd7
`define AND         5'd8
`define OR          5'd9
`define XOR         5'h0A
`define SHL         5'h10
`define SHR         5'h11
`define SHLI        5'h12
`define SHRI        5'h13
`define SEI         6'h30
`define CLI         6'h31
`define RTI         6'h32
`define ADDI	5'd4
`define CMPI    5'd6
`define CMPUI   5'd7
`define ANDI    5'd8
`define ORI     5'd9
`define XORI    6'h0A
`define CSRRW   6'h0E
`define LH      6'h10
`define LHU     6'h11
`define LW      6'h12
`define SH      6'h14
`define SW	    6'h16
`define JAL	    6'h18
`define IMML    6'h1B
`define IMMM    6'h1C
`define IMMH    6'h1D
`define NOP     6'h1E

`define NOP_INSN    {26'd0,`NOP}

`define CSR_HARTID  12'h001
`define CSR_TICK    12'h002
`define CSR_EPC     12'h040
`define CSR_STATUS  12'h044

// JALR and EXTENDED are synonyms
`define EXTEND	3'd7

// system-call subclasses:
`define SYS_NONE	3'd0
`define SYS_CALL	3'd1
`define SYS_MFSR	3'd2
`define SYS_MTSR	3'd3
`define SYS_RFU1	3'd4
`define SYS_RFU2	3'd5
`define SYS_RFU3	3'd6
`define SYS_EXC		3'd7	// doesn't need to be last, but what the heck

// exception types:
`define EXC_NONE	4'd0
`define EXC_HALT	4'd1
`define EXC_TLBMISS	4'd2
`define EXC_SIGSEGV	4'd3
`define EXC_INVALID	4'd4

//`define INSTRUCTION_OP	15:13	// opcode
//`define INSTRUCTION_RA	12:10	// rA 
//`define INSTRUCTION_RB	9:7	// rB 
//`define INSTRUCTION_RC	2:0	// rC 
//`define INSTRUCTION_IM	6:0	// immediate (7-bit)
//`define INSTRUCTION_LI	9:0	// large unsigned immediate (10-bit, 0-extended)
//`define INSTRUCTION_SB	6	// immediate's sign bit
//`define INSTRUCTION_S1  6:4	// contains the syscall sub-class (NONE, CALL, MFSR, MTSR, EXC, etc.)
//`define INSTRUCTION_S2  3:0	// contains the sub-class identifier value

`define INSTRUCTION_OP  5:0
`define INSTRUCTION_RA  10:6
`define INSTRUCTION_RB  15:11
`define INSTRUCTION_RC  20:16
`define INSTRUCTION_IM  31:16
`define INSTRUCTION_SB  31
`define INSTRUCTION_S1  25:21
`define INSTRUCTION_S2  31:26
`define INSTRUCTION_COND    13:11

`define FORW_BRANCH	1'b0
`define BACK_BRANCH	1'b1

`define DRAMSLOT_AVAIL	2'b00
`define DRAMREQ_READY	2'b11

`define INV	1'b0
`define VAL	1'b1

//
// define PANIC types
//
`define PANIC_NONE		4'd0
`define PANIC_FETCHBUFBEQ	4'd1
`define PANIC_INVALIDISLOT	4'd2
`define PANIC_MEMORYRACE	4'd3
`define PANIC_IDENTICALDRAMS	4'd4
`define PANIC_OVERRUN		4'd5
`define PANIC_HALTINSTRUCTION	4'd6
`define PANIC_INVALIDMEMOP	4'd7
`define PANIC_INVALIDFBSTATE	4'd9
`define PANIC_INVALIDIQSTATE	4'd10
`define PANIC_BRANCHBACK	4'd11
`define PANIC_BADTARGETID	4'd12
