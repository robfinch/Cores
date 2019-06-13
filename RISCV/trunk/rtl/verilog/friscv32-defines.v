// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	friscv32-defines.v
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
`define TRUE    1'b1
`define FALSE   1'b0

`define LUI		7'b0110111
`define AUIPC	7'b0010111
`define JAL		7'b1101111
`define JALR	7'b1100111
`define Bcc		7'b1100011
`define BEQ			3'd0
`define BNE			3'd1
`define BLT			3'd4
`define BGE			3'd5
`define BLTU		3'd6
`define BGEU		3'd7
`define Lx		7'b0000011
`define LB			3'd0
`define LH			3'd1
`define LW			3'd2
`define LD			3'd3
`define LBU			3'd4
`define LHU			3'd5
`define LWU			3'd6
`define Sx		7'b0100011
`define SB			3'd0
`define SH			3'd1
`define SW			3'd2
`define SD			3'd3
`define ALU1	7'b0010011
`define ADDI		3'd0
`define SLI			3'd1
`define SLTI		3'd2
`define SLTIU		3'd3
`define XORI		3'd4
`define SRI			3'd5
`define ORI			3'd6
`define ANDI		3'd7
`define ALU1W	7'b0011011
`define ADDIW		3'd0
`define SLIW		3'd1
`define SRIW		3'd5
`define RR		7'b0110011
`define GRP0		3'd0
`define GRP1		3'd1
`define GRP2		3'd2
`define GRP3		3'd3
`define XOR			3'd4
`define SRAL		3'd5
`define OR			3'd6
`define AND			3'd7
`define RRW		7'b0111011
`define GRP0		3'd0
`define GRP1		3'd1
`define SRALW		3'd5
`define FENCE	7'b0001111
`define SYSTEM	7'b1110011
`define SCALL		3'd0
`define RDCTI		3'd2
`define O64     7'h3F
`define ECALL   32'b00000000_00000000_00000000_01110011
`define ERET    32'b00010000_00000000_00000000_01110011
`define WFI     32'b00010000_00100000_00000000_01110011

`define NOPINSN {12'b0,5'b0,3'b000,5'b0,7'b0010011}


`define regXLR      5'd13
`define regV0       5'd16
`define regV1       5'd17

`define RD		11:7
`define RS1		19:15
`define RS2		24:20
