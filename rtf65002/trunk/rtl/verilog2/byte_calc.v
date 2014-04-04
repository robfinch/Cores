// ============================================================================
//        __
//   \\__/ o\    (C) 2013,2014  Robert Finch, Stratford
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
// Datapath calculations - eight/sixteen bit mode                                                                
// ============================================================================
//
BYTE_CALC:
	begin
		state <= BYTE_IFETCH;
		wadr <= radr;
		wadr2LSB <= radr2LSB;
		store_what <= m16 ? `STW_DEF70 : `STW_DEF8;
		case(ir[7:0])
		`ADC_IMM,`ADC_ZP,`ADC_ZPX,`ADC_IX,`ADC_IY,`ADC_ABS,`ADC_ABSX,`ADC_ABSY,`ADC_I:	begin res8 <= acc8 + b8 + {7'b0,cf}; res16 <= acc16 + b16 + {15'd0,cf}; end
		`SBC_IMM,`SBC_ZP,`SBC_ZPX,`SBC_IX,`SBC_IY,`SBC_ABS,`SBC_ABSX,`SBC_ABSY,`SBC_I:	begin res8 <= acc8 - b8 - {7'b0,~cf}; res16 <= acc16 - b16 - {15'd0,~cf}; end
		`CMP_IMM,`CMP_ZP,`CMP_ZPX,`CMP_IX,`CMP_IY,`CMP_ABS,`CMP_ABSX,`CMP_ABSY,`CMP_I:	begin res8 <= acc8 - b8; res16 <= acc16 - b16; end
		`AND_IMM,`AND_ZP,`AND_ZPX,`AND_IX,`AND_IY,`AND_ABS,`AND_ABSX,`AND_ABSY,`AND_I:	begin res8 <= acc8 & b8; res16 <= acc16 & b16; end
		`ORA_IMM,`ORA_ZP,`ORA_ZPX,`ORA_IX,`ORA_IY,`ORA_ABS,`ORA_ABSX,`ORA_ABSY,`ORA_I:	begin res8 <= acc8 | b8; res16 <= acc16 | b16; end
		`EOR_IMM,`EOR_ZP,`EOR_ZPX,`EOR_IX,`EOR_IY,`EOR_ABS,`EOR_ABSX,`EOR_ABSY,`EOR_I:	begin res8 <= acc8 ^ b8; res16 <= acc16 ^ b16; end
		`LDA_IMM,`LDA_ZP,`LDA_ZPX,`LDA_IX,`LDA_IY,`LDA_ABS,`LDA_ABSX,`LDA_ABSY,`LDA_I: begin res8 <= b8; res16 <= b16; end
		`BIT_IMM,`BIT_ZP,`BIT_ZPX,`BIT_ABS,`BIT_ABSX:	begin res8 <= acc8 & b8; res16 <= acc16 & b16; end
		`TRB_ZP,`TRB_ABS:	begin res8 <= ~acc8 & b8; res16 <= ~acc16 & b16; wdat <= m16 ? {2{~acc16 & b16}} : {4{~acc8 & b8}}; state <= STORE1; end
		`TSB_ZP,`TSB_ABS:	begin res8 <= acc8 | b8; res16 <= acc16 | b16; wdat <= m16 ? {2{acc16 | b16}} : {4{acc8 | b8}}; state <= STORE1; end
		`LDX_IMM,`LDX_ZP,`LDX_ZPY,`LDX_ABS,`LDX_ABSY:	begin res8 <= b8; res16 <= b16; end
		`LDY_IMM,`LDY_ZP,`LDY_ZPX,`LDY_ABS,`LDY_ABSX:	begin res8 <= b8; res16 <= b16; end
		`CPX_IMM,`CPX_ZP,`CPX_ABS:	begin res8 <= x8 - b8; res16 <= x16 - b16; end
		`CPY_IMM,`CPY_ZP,`CPY_ABS:	begin res8 <= y8 - b8; res16 <= y16 - b16; end
		`ASL_ZP,`ASL_ZPX,`ASL_ABS,`ASL_ABSX:	begin res8 <= {b8,1'b0}; res16 <= {b16,1'b0}; wdat <= m16 ? {2{b16[14:0],1'b0}} : {4{b8[6:0],1'b0}}; state <= STORE1; end
		`ROL_ZP,`ROL_ZPX,`ROL_ABS,`ROL_ABSX:	begin res8 <= {b8,cf}; res16 <= {b16,cf}; wdat <= m16 ? {2{b16[14:0],cf}} : {4{b8[6:0],cf}}; state <= STORE1; end
		`LSR_ZP,`LSR_ZPX,`LSR_ABS,`LSR_ABSX:	begin res8 <= {b8[0],1'b0,b8[7:1]}; res16 <= {b16[0],1'b0,b16[15:1]}; wdat <= m16 ? {2{1'b0,b16[15:1]}}: {4{1'b0,b8[7:1]}}; state <= STORE1; end
		`ROR_ZP,`ROR_ZPX,`ROR_ABS,`ROR_ABSX:	begin res8 <= {b8[0],cf,b8[7:1]}; res16 <= {b16[0],cf,b16[15:1]}; wdat <= m16 ? {2{cf,b16[15:1]}} : {4{cf,b8[7:1]}}; state <= STORE1; end
		`INC_ZP,`INC_ZPX,`INC_ABS,`INC_ABSX:	begin res8 <= b8 + 8'd1; res16 <= b16 + 16'd1; wdat <= m16 ? {2{b16+16'd1}} : {4{b8+8'd1}}; state <= STORE1; end
		`DEC_ZP,`DEC_ZPX,`DEC_ABS,`DEC_ABSX:	begin res8 <= b8 - 8'd1; res16 <= b16 - 16'd1; wdat <= m16 ? {2{b16-16'd1}} : {4{b8-8'd1}}; state <= STORE1; end
		endcase
	end