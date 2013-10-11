// ============================================================================
//        __
//   \\__/ o\    (C) 2013  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@opencores.org
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
`include "rtf65002_defines.v"

module rtf65002_pcinc8(opcode,suppress_pcinc,inc);
input [7:0] opcode;
input [3:0] suppress_pcinc;
output reg [3:0] inc;

always @(opcode,suppress_pcinc)
if (suppress_pcinc==4'hF)
	case(opcode)
	`BRK:	inc <= 4'd0;
	`BPL,`BMI,`BCS,`BCC,`BVS,`BVC,`BEQ,`BNE,`BRA:	inc <= 4'd2;
	`BRL: inc <= 4'd3;
	`CLC,`SEC,`CLD,`SED,`CLV,`CLI,`SEI:	inc <= 4'd1;
	`TAS,`TSA,`TAY,`TYA,`TAX,`TXA,`TSX,`TXS,`TYX,`TXY:	inc <= 4'd1;
	`INY,`DEY,`INX,`DEX,`INA,`DEA: inc <= 4'd1;
	`NAT: inc <= 4'd1;
	`STP,`WAI: inc <= 4'd1;
	`JMP,`JML,`JMP_IND,`JMP_INDX,
	`RTS,`RTL,`RTI: inc <= 4'd0;
	`JSR,`JSR_INDX:	inc <= 4'd2;
	`JSL:	inc <= 4'd4;
	`NOP: inc <= 4'd1;

	`ADC_IMM,`SBC_IMM,`CMP_IMM,`AND_IMM,`ORA_IMM,`EOR_IMM,`LDA_IMM:	inc <= 4'd2;
	`LDX_IMM,`LDY_IMM,`CPX_IMM,`CPY_IMM,`BIT_IMM: inc <= 4'd2;

	`TRB_ZP,`TSB_ZP,
	`ADC_ZP,`SBC_ZP,`CMP_ZP,`AND_ZP,`ORA_ZP,`EOR_ZP,`LDA_ZP,`STA_ZP: inc <= 4'd2;
	`LDY_ZP,`LDX_ZP,`STY_ZP,`STX_ZP,`CPX_ZP,`CPY_ZP,`BIT_ZP,`STZ_ZP: inc <= 4'd2;
	`ASL_ZP,`ROL_ZP,`LSR_ZP,`ROR_ZP,`INC_ZP,`DEC_ZP: inc <= 4'd2;

	`ADC_ZPX,`SBC_ZPX,`CMP_ZPX,`AND_ZPX,`ORA_ZPX,`EOR_ZPX,`LDA_ZPX,`STA_ZPX: inc <= 4'd2;
	`LDY_ZPX,`STY_ZPX,`BIT_ZPX,`STZ_ZPX: inc <= 4'd2;
	`ASL_ZPX,`ROL_ZPX,`LSR_ZPX,`ROR_ZPX,`INC_ZPX,`DEC_ZPX: inc <= 4'd2;
	`LDX_ZPY,`STX_ZPY: inc <= 4'd2;

	`ADC_I,`SBC_I,`AND_I,`ORA_I,`EOR_I,`CMP_I,`LDA_I,`STA_I,
	`ADC_IX,`SBC_IX,`CMP_IX,`AND_IX,`OR_IX,`EOR_IX,`LDA_IX,`STA_IX: inc <= 4'd2;

	`ADC_IY,`SBC_IY,`CMP_IY,`AND_IY,`OR_IY,`EOR_IY,`LDA_IY,`STA_IY: inc <= 4'd2;

	`TRB_ABS,`TSB_ABS,
	`ADC_ABS,`SBC_ABS,`CMP_ABS,`AND_ABS,`OR_ABS,`EOR_ABS,`LDA_ABS,`STA_ABS: inc <= 4'd3;
	`LDX_ABS,`LDY_ABS,`STX_ABS,`STY_ABS,`CPX_ABS,`CPY_ABS,`BIT_ABS,`STZ_ABS: inc <= 4'd3;
	`ASL_ABS,`ROL_ABS,`LSR_ABS,`ROR_ABS,`INC_ABS,`DEC_ABS: inc <= 4'd3;

	`ADC_ABSX,`SBC_ABSX,`CMP_ABSX,`AND_ABSX,`OR_ABSX,`EOR_ABSX,`LDA_ABSX,`STA_ABSX: inc <= 4'd3;
	`LDY_ABSX,`BIT_ABSX,`STZ_ABSX:	inc <= 4'd3;
	`ASL_ABSX,`ROL_ABSX,`LSR_ABSX,`ROR_ABSX,`INC_ABSX,`DEC_ABSX: inc <= 4'd3;

	`ADC_ABSY,`SBC_ABSY,`CMP_ABSY,`AND_ABSY,`ORA_ABSY,`EOR_ABSY,`LDA_ABSY,`STA_ABSY: inc <= 4'd3;
	`LDX_ABSY: inc <= 4'd3;

	`ASL_ACC,`LSR_ACC,`ROR_ACC,`ROL_ACC: inc <= 4'd1;

	`PHP,`PHA,`PHX,`PHY,`PLP,`PLA,`PLX,`PLY: inc <= 4'd1;

	default:	inc <= 4'd0;	// unimplemented instruction
	endcase
else
	inc <= 4'd0;
endmodule
