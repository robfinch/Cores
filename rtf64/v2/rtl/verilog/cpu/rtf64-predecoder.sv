// ============================================================================
//        __
//   \\__/ o\    (C) 2019-2020  Robert Finch, Waterloo
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
`include "../inc/rtf64-defines.sv"

// Given the byte opcode, the instruction length is determined.
module rtf64_predecoder(i, o);
input [7:0] i;
output reg [7:0] o;

always @*
casez(i)
`R3A:     o = 8'h04;
`R2:     	o = 8'h04;
`R3B:     o = 8'h04;
`ADD:     o = 8'h04;
`SUBF:    o = 8'h04;
`MUL:     o = 8'h04;
`AND:     o = 8'h04;
`OR:      o = 8'h04;
`EOR:     o = 8'h04;
`SHIFT:   o = 8'h04;
`SET:     o = 8'h04;
`MULU:    o = 8'h04;
`CSR:     o = 8'h05;
`DIV:     o = 8'h04;
`DIVU:    o = 8'h04;
`DIVSU:   o = 8'h04;
`R2B:     o = 8'h04;
`MULF:    o = 8'h04;
`MULSU:   o = 8'h04;
`PERM:    o = 8'h06;
`REM:     o = 8'h04;
`REMU:    o = 8'h04;
`BYTNDX:  o = 8'h04;
`WYDNDX:  o = 8'h05;
`EXT:     o = 8'h04;
`DEP:     o = 8'h04;
`DEPI:    o = 8'h04;
`FFO:     o = 8'h04;
`REMSU:   o = 8'h04;
`DIVR:    o = 8'h04;
`SAND:    o = 8'h04;
`SOR:     o = 8'h04;
`SEQ:     o = 8'h04;
`SNE:     o = 8'h04;
`SLT:     o = 8'h04;
`SGE:     o = 8'h04;
`SLE:     o = 8'h04;
`SGT:     o = 8'h04;
`SLTU:    o = 8'h04;
`SGEU:    o = 8'h04;
`SLEU:    o = 8'h04;
`SGTU:    o = 8'h04;
`ADD5:    o = 8'h03;
`OR5:     o = 8'h03;
`ADD22:   o = 8'h03;
`ADD2R:   o = 8'h03;
`OR2R:    o = 8'h03;
`ADC2R:   o = 8'h03;
`ADDISP10: o = 8'h02;
`ADDUI:   o = 8'h08;
`ANDUI:   o = 8'h08;
`ORUI:    o = 8'h08;
`AUIIP:   o = 8'h08;
`BLR:     o = 8'h14;
`JMP:     o = 8'h15;
`JSR:     o = 8'h15;
`RTS:     o = 8'h12;
`RTL:     o = 8'h13;
`RTE:     o = 8'h13;
`BEQ:     o = 8'h13;
`BNE:     o = 8'h13;
`BLT:     o = 8'h13;
`BGE:     o = 8'h13;
`BLE:     o = 8'h13;
`BGT:     o = 8'h13;
`BLTU:    o = 8'h13;
`BGEU:    o = 8'h13;
`BLEU:    o = 8'h13;
`BGTU:    o = 8'h13;
`BVC:     o = 8'h13;
`BVS:     o = 8'h13;
`BOD:     o = 8'h13;
`BEQI:    o = 8'h14;
`BPS:     o = 8'h13;
`BRA:     o = 8'h13;
`BEQZ:    o = 8'h13;
`BNEZ:    o = 8'h13;
`BBC:     o = 8'h14;
`BBS:     o = 8'h14;
`RTX:     o = 8'h11;
`JSR18:   o = 8'h13;
`BT:      o = 8'h12;
`CI:      o = 8'h22;
`BRK:     o = 8'h32;
`NOP:     o = 8'h31;
`OSR2:    o = 8'h34;
`ATNI:    o = 8'h32;
`EXEC:    o = 8'h32;
`LDBS:    o = 8'h43;
`LDBUS:   o = 8'h43;
`LDWS:    o = 8'h43;
`LDWUS:   o = 8'h43;
`LDTS:    o = 8'h43;
`LDTUS:   o = 8'h43;
`LDOS:    o = 8'h43;
`LDORS:   o = 8'h43;
`LDOT:    o = 8'h44;
`LEAS:    o = 8'h43;
`UNLINK:  o = 8'h41;
`POP:     o = 8'h42;
`PLDOS:   o = 8'h43;
`FLDOS:   o = 8'h43;
`LEA:     o = 8'h44;
`PLDO:    o = 8'h44;
`FLDO:    o = 8'h44;
`LDM:     o = 8'h46;
`LDB:     o = 8'h44;
`LDBU:    o = 8'h44;
`LDW:     o = 8'h44;
`LDWU:    o = 8'h44;
`LDT:     o = 8'h44;
`LDTU:    o = 8'h44;
`LDO:     o = 8'h44;
`LDOR:    o = 8'h44;
`STBS:    o = 8'h43;
`STWS:    o = 8'h43;
`STTS:    o = 8'h43;
`STOS:    o = 8'h43;
`STOCS:   o = 8'h43;
`STPTRS:  o = 8'h43;
`STOTS:   o = 8'h43;
`STOIS:		o = 8'h44;
`PUSHC:   o = 8'h44;
`PUSH:    o = 8'h42;
`LINK:    o = 8'h43;
`FSTOS:   o = 8'h43;
`PSTOS:   o = 8'h43;
`STM:     o = 8'h46;
`STB:     o = 8'h44;
`STW:     o = 8'h44;
`STT:     o = 8'h44;
`STO:     o = 8'h44;
`STOC:    o = 8'h44;
`STPTR:   o = 8'h44;
`STOT:    o = 8'h44;
`PFDP:    o = 8'h54;
`PST2:    o = 8'h54;
`PMA:     o = 8'h54;
`PMS:     o = 8'h54;
`PNMA:    o = 8'h54;
`PNMS:    o = 8'h54;
`FLT2:    o = 8'h64;
`FMA:     o = 8'h64;
`FMS:     o = 8'h64;
`FNMA:    o = 8'h64;
`FNMS:    o = 8'h64;
default:  o = 8'h74;
endcase

endmodule
