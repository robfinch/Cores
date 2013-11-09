// ============================================================================
//        __
//   \\__/ o\    (C) 2013  Robert Finch, Stratford
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
//
// Thor Scaler
//
// ============================================================================
//
`ifndef THOR_DEFINES
`define THOR_DEFINES	1'b1

`define TRUE	1'b1
`define FALSE	1'b0
`define INV		1'b0
`define VAL		1'b1
`define ZERO		64'd0


`define TST			8'b0000xxxx
`define CMP			8'b0001xxxx
`define CMPI		8'b0010xxxx
`define BR			8'b0011xxxx

`define ADD			8'h40
`define SUB			8'h41
`define MUL			8'h42
`define DIV			8'h43
`define ADDU		8'h44
`define SUBU		8'h45
`define MULU		8'h46
`define DIVU		8'h47
`define ADDI		8'h48
`define SUBI		8'h49
`define MULI		8'h4A
`define DIVI		8'h4B
`define ADDUI		8'h4C
`define SUBUI		8'h4D
`define MULUI		8'h4E
`define DIVUI		8'h4F
`define AND			8'h50
`define OR			8'h51
`define EOR			8'h52
`define ANDI		8'h53
`define ORI			8'h54
`define EORI		8'h55
`define _2ADDU		8'h56
`define _4ADDU		8'h57

`define SHL			8'h58
`define SHR			8'h59
`define SHLU		8'h5A
`define SHRU		8'h5B
`define ROL			8'h5C
`define ROR			8'h5D
`define SHLI		8'h5E
`define SHRI		8'h5F
`define SHLUI		8'h60
`define SHRUI		8'h61
`define ROLI		8'h62
`define RORI		8'h63

`define _8ADDU		8'h64
`define _16ADDU		8'h65
`define NAND		8'h66
`define NOR			8'h67
`define ENOR		8'h68
`define ANDC		8'h69
`define ORC			8'h6A
`define _2ADDUI		8'h6B
`define _4ADDUI		8'h6C
`define _8ADDUI		8'h6D
`define _16ADDUI	8'h6E
`define LDI			8'h6F

`define NEG			8'h70
`define NOT			8'h71

`define LB			8'h80
`define LBU			8'h81
`define LC			8'h82
`define LCU			8'h83
`define LH			8'h84
`define LHU			8'h85
`define LW			8'h86
`define LFS			8'h87
`define LFD			8'h88
`define PFLD		8'h8F

`define SB			8'h90
`define SC			8'h91
`define SH			8'h92
`define SW			8'h93
`define SFS			8'h94
`define SFD			8'h95

`define STSB		8'h98
`define STSC		8'h99
`define STSH		8'h99
`define STSW		8'h9A

`define CACHE		8'h9F

// Flow control Opcodes
`define JSR			8'hA2
`define RTS			8'hA3
`define LOOP		8'hA4
`define SYS			8'hA5
`define INT			8'hA6

`define MFSPR		8'hA8
`define MTSPR		8'hA9

`define NOP		8'hE1
`define RTE		8'hF3
`define RTI		8'hF4
`define SYNC	8'hF8
`define CLI		8'hFA
`define SEI		8'hFB
`define IMM		8'hFF

`define PREDC	3:0
`define PREDR	7:4
`define OPCODE	15:8
`define RA		23:16
`define RB		31:24
`define INSTRUCTION_RA	23:16
`define INSTRUCTION_RB	31:24

`define XTBL	4'd12
`define EPC		4'd13
`define IPC		4'd14

// Special Registers
`define TICK		8'h02
`define PREGS		8'h04
`define BREGS		8'h1x
`define SREGS		8'h2x

// exception types:
`define EXC_NONE	4'd0
`define EXC_HALT	4'd1
`define EXC_TLBMISS	4'd2
`define EXC_SIGSEGV	4'd3
`define EXC_INVALID	4'd4
`define EXC_SYS		4'd5
`define EXC_INT		4'd6
`define EXC_OFL		4'd7

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

`define DRAMSLOT_AVAIL	2'b00
`define DRAMREQ_READY	2'b11

`endif
