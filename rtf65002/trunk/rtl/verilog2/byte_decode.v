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
// Byte mode decode/execute state
// ============================================================================
//
BYTE_DECODE:
	begin
		first_ifetch <= `TRUE;
		state <= BYTE_IFETCH;
		pc <= pc + pc_inc8;
		case(ir[7:0])
		`SEP:	;	// see byte_ifetch
		`REP:	;
		`STP:	begin clk_en <= 1'b0; end
//		`NAT:	begin em <= 1'b0; state <= IFETCH; end
		`WDM:	if (ir[15:8]==`XCE) begin em <= 1'b0; state <= IFETCH; pc <= pc + 32'd2; end
		`XCE:	begin m816 <= ~cf; cf <= ~m816; end
		`NOP:	;
		`CLC:	begin cf <= 1'b0; end
		`SEC:	begin cf <= 1'b1; end
		`CLV:	begin vf <= 1'b0; end
		`CLI:	begin im <= 1'b0; end
		`SEI:	begin im <= 1'b1; end
		`CLD:	begin df <= 1'b0; end
		`SED:	begin df <= 1'b1; end
		`WAI:	begin wai <= 1'b1; end
		`DEX:	begin res8 <= x[7:0] - 8'd1; res16 <= x[15:0] - 16'd1; end
		`INX:	begin res8 <= x[7:0] + 8'd1; res16 <= x[15:0] + 16'd1; end
		`DEY:	begin res8 <= y[7:0] - 8'd1; res16 <= y[15:0] - 16'd1; end
		`INY:	begin res8 <= y[7:0] + 8'd1; res16 <= y[15:0] + 16'd1; end
		`DEA:	begin res8 <= acc[7:0] - 8'd1; res16 <= acc[15:0] - 16'd1; end
		`INA:	begin res8 <= acc[7:0] + 8'd1; res16 <= acc[15:0] + 16'd1; end
		`TSX,`TSA:	begin res8 <= sp[7:0]; res16 <= sp[15:0]; end
		`TXS,`TXA,`TXY:	begin res8 <= x[7:0]; res16 <= x[15:0]; end
		`TAX,`TAY,`TAS:	begin res8 <= acc[7:0]; res16 <= acc[15:0]; end
		`TYA,`TYX:	begin res8 <= y[7:0]; res16 <= y[15:0]; end
		`TDC:		begin res16 <= dpr; end
		`TCD:		begin res16 <= acc[15:0]; end
		`ASL_ACC:	begin res8 <= {acc8,1'b0}; res16 <= {acc16,1'b0}; end
		`ROL_ACC:	begin res8 <= {acc8,cf}; res16 <= {acc16,cf}; end
		`LSR_ACC:	begin res8 <= {acc8[0],1'b0,acc8[7:1]}; res16 <= {acc16[0],1'b0,acc16[15:1]}; end
		`ROR_ACC:	begin res8 <= {acc8[0],cf,acc8[7:1]}; res16 <= {acc16[0],cf,acc16[15:1]}; end
		// Handle # mode
		`LDA_IMM:
			begin
				res8 <= ir[15:8];
				res16 <= ir[23:8];
			end
		`LDX_IMM,`LDY_IMM:
			begin
				res8 <= ir[15:8];
				res16 <= ir[23:8];
			end
		`ADC_IMM:
			begin
				res8 <= acc8 + ir[15:8] + {7'b0,cf};
				res16 <= acc16 + ir[23:8] + {15'b0,cf};
				b8 <= ir[15:8];		// for overflow calc
				b16 <= ir[23:8];
			end
		`SBC_IMM:
			begin
//				res8 <= acc8 - ir[15:8] - ~cf;
				res8 <= acc8 - ir[15:8] - {7'b0,~cf};
				res16 <= acc16 - ir[23:8] - {15'b0,~cf};
				$display("sbc: %h= %h-%h-%h", acc8 - ir[15:8] - {7'b0,~cf},acc8,ir[15:8],~cf);
				b8 <= ir[15:8];		// for overflow calc
				b16 <= ir[23:8];
			end
		`AND_IMM,`BIT_IMM:
			begin
				res8 <= acc8 & ir[15:8];
				res16 <= acc16 & ir[23:8];
				b8 <= ir[15:8];	// for bit flags
				b16 <= ir[23:8];
			end
		`ORA_IMM:	begin res8 <= acc8 | ir[15:8]; res16 <= acc16 | ir[23:8]; end
		`EOR_IMM:	begin res8 <= acc8 ^ ir[15:8]; res16 <= acc16 ^ ir[23:8]; end
		`CMP_IMM:	begin res8 <= acc8 - ir[15:8]; res16 <= acc16 - ir[23:8]; end
		`CPX_IMM:	begin res8 <= x8 - ir[15:8]; res16 <= x16 - ir[23:8]; end
		`CPY_IMM:	begin res8 <= y8 - ir[15:8]; res16 <= y16 - ir[23:8]; end
		// Handle zp mode
		`LDA_ZP:
			begin
				radr <= zp_address[31:2];
				radr2LSB <= zp_address[1:0];
				load_what <= m16 ? `HALF_71 : `BYTE_71;
				state <= LOAD_MAC1;
			end
		`LDX_ZP,`LDY_ZP:
			begin
				radr <= zp_address[31:2];
				radr2LSB <= zp_address[1:0];
				load_what <= xb16 ? `HALF_71 : `BYTE_71;
				state <= LOAD_MAC1;
			end
		`ADC_ZP,`SBC_ZP,`AND_ZP,`ORA_ZP,`EOR_ZP,`CMP_ZP,
		`BIT_ZP,
		`ASL_ZP,`ROL_ZP,`LSR_ZP,`ROR_ZP,`INC_ZP,`DEC_ZP,`TRB_ZP,`TSB_ZP:
			begin
				radr <= zp_address[31:2];
				radr2LSB <= zp_address[1:0];
				load_what <= m16 ? `HALF_70 : `BYTE_70;
				state <= LOAD_MAC1;
			end
		`CPX_ZP,`CPY_ZP:
			begin
				radr <= zp_address[31:2];
				radr2LSB <= zp_address[1:0];
				load_what <= xb16 ? `HALF_70 : `BYTE_70;
				state <= LOAD_MAC1;
			end
		`STA_ZP:
			begin
				wadr <= zp_address[31:2];
				wadr2LSB <= zp_address[1:0];
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				state <= STORE1;
			end
		`STX_ZP:
			begin
				wadr <= zp_address[31:2];
				wadr2LSB <= zp_address[1:0];
				store_what <= xb16 ? `STW_X70 : `STW_X8;
				state <= STORE1;
			end
		`STY_ZP:
			begin
				wadr <= zp_address[31:2];
				wadr2LSB <= zp_address[1:0];
				store_what <= xb16 ? `STW_Y70 : `STW_Y8;
				state <= STORE1;
			end
		`STZ_ZP:
			begin
				wadr <= zp_address[31:2];
				wadr2LSB <= zp_address[1:0];
				store_what <= m16 ? `STW_Z70 : `STW_Z8;
				state <= STORE1;
			end
		// Handle zp,x mode
		`LDA_ZPX:
			begin
				radr <= zpx_address[31:2];
				radr2LSB <= zpx_address[1:0];
				load_what <= m16 ? `HALF_71 : `BYTE_71;
				state <= LOAD_MAC1;
			end
		`LDY_ZPX:
			begin
				radr <= zpx_address[31:2];
				radr2LSB <= zpx_address[1:0];
				load_what <= xb16 ? `HALF_71 : `BYTE_71;
				state <= LOAD_MAC1;
			end
		`ADC_ZPX,`SBC_ZPX,`AND_ZPX,`ORA_ZPX,`EOR_ZPX,`CMP_ZPX,
		`BIT_ZPX,
		`ASL_ZPX,`ROL_ZPX,`LSR_ZPX,`ROR_ZPX,`INC_ZPX,`DEC_ZPX:
			begin
				radr <= zpx_address[31:2];
				radr2LSB <= zpx_address[1:0];
				load_what <= m16 ? `HALF_70 : `BYTE_70;
				state <= LOAD_MAC1;
			end
		`STA_ZPX:
			begin
				wadr <= zpx_address[31:2];
				wadr2LSB <= zpx_address[1:0];
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				state <= STORE1;
			end
		`STY_ZPX:
			begin
				wadr <= zpx_address[31:2];
				wadr2LSB <= zpx_address[1:0];
				store_what <= xb16 ? `STW_Y70 : `STW_Y8;
				state <= STORE1;
			end
		`STZ_ZPX:
			begin
				wadr <= zpx_address[31:2];
				wadr2LSB <= zpx_address[1:0];
				store_what <= m16 ? `STW_Z70 : `STW_Z8;
				state <= STORE1;
			end
		// Handle zp,y
		`LDX_ZPY:
			begin
				radr <= zpy_address[31:2];
				radr2LSB <= zpy_address[1:0];
				load_what <= xb16 ? `HALF_71 : `BYTE_71;
				state <= LOAD_MAC1;
			end
		`STX_ZPY:
			begin
				wadr <= zpy_address[31:2];
				wadr2LSB <= zpy_address[1:0];
				store_what <= xb16 ? `STW_X70 : `STW_X8;
				state <= STORE1;
			end
		`ADC_DSP,`SBC_DSP,`CMP_DSP,`ORA_DSP,`AND_DSP,`EOR_DSP,`LDA_DSP,`STA_DSP:
			begin
				radr <= dsp_address[31:2];
				radr2LSB <= dsp_address[1:0];
				load_what <= m16 ? `HALF_70 : `BYTE_70;
				state <= LOAD_MAC1;
			end
		// Handle (zp,x)
		`ADC_IX,`SBC_IX,`AND_IX,`ORA_IX,`EOR_IX,`CMP_IX,`LDA_IX,`STA_IX:
			begin
				radr <= zpx_address[31:2];
				radr2LSB <= zpx_address[1:0];
				load_what <= `IA_70;
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				state <= LOAD_MAC1;
			end
		// Handle (zp),y
		`ADC_IY,`SBC_IY,`AND_IY,`ORA_IY,`EOR_IY,`CMP_IY,`LDA_IY,`STA_IY:
			begin
				radr <= zp_address[31:2];
				radr2LSB <= zp_address[1:0];
				isIY <= `TRUE;
				load_what <= `IA_70;
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				state <= LOAD_MAC1;
			end
		// Handle (d,sp),y
		`ADC_DSPIY,`SBC_DSPIY,`CMP_DSPIY,`ORA_DSPIY,`AND_DSPIY,`EOR_DSPIY,`LDA_DSPIY,`STA_DSPIY:
			begin
				radr <= dsp_address[31:2];
				radr2LSB <= dsp_address[1:0];
				isIY <= `TRUE;
				load_what <= `IA_70;
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				state <= LOAD_MAC1;
			end
		// Handle [zp],y
		`ADC_IYL,`SBC_IYL,`AND_IYL,`ORA_IYL,`EOR_IYL,`CMP_IYL,`LDA_IYL,`STA_IYL:
			begin
				radr <= zp_address[31:2];
				radr2LSB <= zp_address[1:0];
				isIY24 <= `TRUE;
				load_what <= `IA_70;
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				state <= LOAD_MAC1;
			end
		// Handle abs
		`LDA_ABS:
			begin
				radr <= abs_address[31:2];
				radr2LSB <= abs_address[1:0];
				load_what <= m16 ? `HALF_71 : `BYTE_71;
				state <= LOAD_MAC1;
			end
		`LDX_ABS,`LDY_ABS:
			begin
				radr <= abs_address[31:2];
				radr2LSB <= abs_address[1:0];
				load_what <= xb16 ? `HALF_71 : `BYTE_71;
				state <= LOAD_MAC1;
			end
		`ADC_ABS,`SBC_ABS,`AND_ABS,`ORA_ABS,`EOR_ABS,`CMP_ABS,
		`ASL_ABS,`ROL_ABS,`LSR_ABS,`ROR_ABS,`INC_ABS,`DEC_ABS,`TRB_ABS,`TSB_ABS,
		`BIT_ABS:
			begin
				radr <= abs_address[31:2];
				radr2LSB <= abs_address[1:0];
				load_what <= m16 ? `HALF_70 : `BYTE_70;
				state <= LOAD_MAC1;
			end
		`CPX_ABS,`CPY_ABS:
			begin
				radr <= abs_address[31:2];
				radr2LSB <= abs_address[1:0];
				load_what <= xb16 ? `HALF_70 : `BYTE_70;
				state <= LOAD_MAC1;
			end
		`STA_ABS:
			begin
				wadr <= abs_address[31:2];
				wadr2LSB <= abs_address[1:0];
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				state <= STORE1;
			end
		`STX_ABS:
			begin
				wadr <= abs_address[31:2];
				wadr2LSB <= abs_address[1:0];
				store_what <= xb16 ? `STW_X70 : `STW_X8;
				state <= STORE1;
			end	
		`STY_ABS:
			begin
				wadr <= abs_address[31:2];
				wadr2LSB <= abs_address[1:0];
				store_what <= xb16 ? `STW_Y70 : `STW_Y8;
				state <= STORE1;
			end
		`STZ_ABS:
			begin
				wadr <= abs_address[31:2];
				wadr2LSB <= abs_address[1:0];
				store_what <= m16 ? `STW_Z70 : `STW_Z8;
				state <= STORE1;
			end
		// Handle abs,x
		`ADC_ABSX,`SBC_ABSX,`AND_ABSX,`ORA_ABSX,`EOR_ABSX,`CMP_ABSX,`LDA_ABSX,
		`ASL_ABSX,`ROL_ABSX,`LSR_ABSX,`ROR_ABSX,`INC_ABSX,`DEC_ABSX,`BIT_ABSX:
			begin
				radr <= absx_address[31:2];
				radr2LSB <= absx_address[1:0];
				load_what <= m16 ? `HALF_70 : `BYTE_70;
				state <= LOAD_MAC1;
			end
		`LDY_ABSX:
			begin
				radr <= absx_address[31:2];
				radr2LSB <= absx_address[1:0];
				load_what <= xb16 ? `HALF_70 : `BYTE_70;
				state <= LOAD_MAC1;
			end
		`STA_ABSX:
			begin
				wadr <= absx_address[31:2];
				wadr2LSB <= absx_address[1:0];
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				state <= STORE1;
			end
		`STZ_ABSX:
			begin
				wadr <= absx_address[31:2];
				wadr2LSB <= absx_address[1:0];
				store_what <= m16 ? `STW_Z70 : `STW_Z8;
				state <= STORE1;
			end
		// Handle abs,y
		`ADC_ABSY,`SBC_ABSY,`AND_ABSY,`ORA_ABSY,`EOR_ABSY,`CMP_ABSY,`LDA_ABSY:
			begin
				radr <= absy_address[31:2];
				radr2LSB <= absy_address[1:0];
				load_what <= m16 ? `HALF_70 : `BYTE_70;
				state <= LOAD_MAC1;
			end
		`LDX_ABSY:
			begin
				radr <= absy_address[31:2];
				radr2LSB <= absy_address[1:0];
				load_what <= xb16 ? `HALF_70 : `BYTE_70;
				state <= LOAD_MAC1;
			end
		`STA_ABSY:
			begin
				wadr <= absy_address[31:2];
				wadr2LSB <= absy_address[1:0];
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				state <= STORE1;
			end
		// Handle al
		`ADC_AL,`SBC_AL,`AND_AL,`ORA_AL,`EOR_AL,`CMP_AL,`LDA_AL:
			begin
				radr <= al_address[31:2];
				radr2LSB <= al_address[1:0];
				load_what <= m16 ? `HALF_70 : `BYTE_70;
				state <= LOAD_MAC1;
			end
		`STA_AL:
			begin
				wadr <= al_address[31:2];
				wadr2LSB <= al_address[1:0];
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				state <= STORE1;
			end
		// Handle alx
		`ADC_ALX,`SBC_ALX,`AND_ALX,`ORA_ALX,`EOR_ALX,`CMP_ALX,`LDA_ALX:
			begin
				radr <= alx_address[31:2];
				radr2LSB <= alx_address[1:0];
				load_what <= m16 ? `HALF_70 : `BYTE_70;
				state <= LOAD_MAC1;
			end
		`STA_ALX:
			begin
				wadr <= alx_address[31:2];
				wadr2LSB <= alx_address[1:0];
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				state <= STORE1;
			end
		// Handle (zp)
		`ADC_I,`SBC_I,`AND_I,`ORA_I,`EOR_I,`CMP_I,`LDA_I,`STA_I,`PEI:
			begin
				radr <= zp_address[31:2];
				radr2LSB <= zp_address[1:0];
				load_what <= `IA_70;
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				state <= LOAD_MAC1;
			end
		// Handle [zp]
		`ADC_IL,`SBC_IL,`AND_IL,`ORA_IL,`EOR_IL,`CMP_IL,`LDA_IL,`STA_IL:
			begin
				isI24 <= `TRUE;
				radr <= zp_address[31:2];
				radr2LSB <= zp_address[1:0];
				load_what <= `IA_70;
				store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
				state <= LOAD_MAC1;
			end
		`BRK:
			begin
				if (m816) begin
					radr <= {spage[31:24],8'h00,sp[15:2]};
					radr2LSB <= sp[1:0];
					wadr <= {spage[31:24],8'h00,sp[15:2]};
					wadr2LSB <= sp[1:0];
				end
				else begin
					radr <= {spage[31:16],8'h01,sp[7:2]};
					radr2LSB <= sp[1:0];
					wadr <= {spage[31:16],8'h01,sp[7:2]};
					wadr2LSB <= sp[1:0];
				end
				sp <= sp_dec;
				store_what <= `STW_PC3124;
				state <= STORE1;
				bf <= !hwi;
			end
		`COP:
			begin
				if (m816) begin
					radr <= {spage[31:24],8'h00,sp[15:2]};
					radr2LSB <= sp[1:0];
					wadr <= {spage[31:24],8'h00,sp[15:2]};
					wadr2LSB <= sp[1:0];
				end
				else begin
					radr <= {spage[31:16],8'h01,sp[7:2]};
					radr2LSB <= sp[1:0];
					wadr <= {spage[31:16],8'h01,sp[7:2]};
					wadr2LSB <= sp[1:0];
				end
				sp <= sp_dec;
				store_what <= `STW_PC3124;
				state <= STORE1;
				vect <= `COP_VECT_816;
			end
		`JMP:
			begin
				pc[15:0] <= abs_address[15:0];
			end
		`JML:
			begin
				pc <= ir[31:8];
			end
		`JMP_IND:
			begin
				radr <= abs_address[31:2];
				radr2LSB <= abs_address[1:0];
				load_what <= `PC_70;
				state <= LOAD_MAC1;
			end
		`JMP_INDX:
			begin
				radr <= absx_address[31:2];
				radr2LSB <= absx_address[1:0];
				load_what <= `PC_70;
				state <= LOAD_MAC1;
			end	
		`JSR:
			begin
				radr <= {spage[31:16],8'h01,sp[7:2]};
				wadr <= {spage[31:16],8'h01,sp[7:2]};
				radr2LSB <= sp[1:0];
				wadr2LSB <= sp[1:0];
				store_what <= `STW_PC158;
				sp <= sp_dec;
				state <= STORE1;
			end
		`JSL:
			begin
				radr <= {spage[31:16],8'h01,sp[7:2]};
				wadr <= {spage[31:16],8'h01,sp[7:2]};
				radr2LSB <= sp[1:0];
				wadr2LSB <= sp[1:0];
				sp <= sp_dec;
				store_what <= `STW_PC2316;
				state <= STORE1;
			end
		`JSR_INDX:
			begin
				radr <= {spage[31:8],sp[7:2]};
				wadr <= {spage[31:8],sp[7:2]};
				radr2LSB <= sp[1:0];
				wadr2LSB <= sp[1:0];
				sp <= sp_dec;
				store_what <= `STW_PC158;
				state <= STORE1;
			end
		`RTS,`RTL:
			begin
				inc_sp();
				load_what <= `PC_70;
				state <= LOAD_MAC1;
			end
		`RTI:	begin
				inc_sp();
				load_what <= `SR_70;
				state <= LOAD_MAC1;
				end
		`BEQ,`BNE,`BPL,`BMI,`BCC,`BCS,`BVC,`BVS,`BRA:
			begin
				if (ir[15:8]==8'hFF) begin
					if (takb)
						pc <= pc + {{16{ir[31]}},ir[31:16]};
					else
						pc <= pc + 32'd4;
				end
				else
				begin
					if (takb)
						pc <= pc + {{24{ir[15]}},ir[15:8]} + 32'd2;
					else
						pc <= pc + 32'd2;
				end
			end
		`PHP:
			begin
				if (m816) begin
					radr <= {spage[31:24],8'h00,sp[15:2]};
					radr2LSB <= sp[1:0];
					wadr <= {spage[31:24],8'h00,sp[15:2]};
					wadr2LSB <= sp[1:0];
				end
				else begin
					radr <= {spage[31:16],8'h01,sp[7:2]};
					radr2LSB <= sp[1:0];
					wadr <= {spage[31:16],8'h01,sp[7:2]};
					wadr2LSB <= sp[1:0];
				end
				sp <= sp_dec;
				store_what <= `STW_SR70;
				state <= STORE1;
			end
		`PHB:
			begin
				if (m816) begin
					radr <= {spage[31:24],8'h00,sp[15:2]};
					radr2LSB <= sp[1:0];
					wadr <= {spage[31:24],8'h00,sp[15:2]};
					wadr2LSB <= sp[1:0];
				end
				else begin
					radr <= {spage[31:16],8'h01,sp[7:2]};
					radr2LSB <= sp[1:0];
					wadr <= {spage[31:16],8'h01,sp[7:2]};
					wadr2LSB <= sp[1:0];
				end
				sp <= sp_dec;
				store_what <= `STW_DBR;
				state <= STORE1;
			end
		`PHD:
			begin
				if (m816) begin
					radr <= {spage[31:24],8'h00,sp[15:2]};
					radr2LSB <= sp[1:0];
					wadr <= {spage[31:24],8'h00,sp[15:2]};
					wadr2LSB <= sp[1:0];
				end
				else begin
					radr <= {spage[31:16],8'h01,sp[7:2]};
					radr2LSB <= sp[1:0];
					wadr <= {spage[31:16],8'h01,sp[7:2]};
					wadr2LSB <= sp[1:0];
				end
				sp <= sp_dec;
				store_what <= `STW_DPR158;
				state <= STORE1;
			end
		`PHK:
			begin
				if (m816) begin
					radr <= {spage[31:24],8'h00,sp[15:2]};
					radr2LSB <= sp[1:0];
					wadr <= {spage[31:24],8'h00,sp[15:2]};
					wadr2LSB <= sp[1:0];
				end
				else begin
					radr <= {spage[31:16],8'h01,sp[7:2]};
					radr2LSB <= sp[1:0];
					wadr <= {spage[31:16],8'h01,sp[7:2]};
					wadr2LSB <= sp[1:0];
				end
				sp <= sp_dec;
				store_what <= `STW_PC2316;
				state <= STORE1;
			end
		`PHA:	tsk_push(`STW_ACC8,`STW_ACC70);
		`PHX:	tsk_push(`STW_X8,`STW_X70);
		`PHY:	tsk_push(`STW_Y8,`STW_Y70);
		`PEA:
			begin
				tmp16 <= ir[23:8];
				if (m816) begin
					radr <= {spage[31:24],8'h00,sp[15:2]};
					radr2LSB <= sp[1:0];
					wadr <= {spage[31:24],8'h00,sp[15:2]};
					wadr2LSB <= sp[1:0];
				end
				else begin
					radr <= {spage[31:16],8'h01,sp[7:2]};
					radr2LSB <= sp[1:0];
					wadr <= {spage[31:16],8'h01,sp[7:2]};
					wadr2LSB <= sp[1:0];
				end
				sp <= sp_dec;
				store_what <= `STW_TMP158;
				state <= STORE1;
			end
		`PER:
			begin
				tmp16 <= pc[15:0] + ir[23:8] + 16'd3;
				if (m816) begin
					radr <= {spage[31:24],8'h00,sp[15:2]};
					radr2LSB <= sp[1:0];
					wadr <= {spage[31:24],8'h00,sp[15:2]};
					wadr2LSB <= sp[1:0];
				end
				else begin
					radr <= {spage[31:16],8'h01,sp[7:2]};
					radr2LSB <= sp[1:0];
					wadr <= {spage[31:16],8'h01,sp[7:2]};
					wadr2LSB <= sp[1:0];
				end
				sp <= sp_dec;
				store_what <= `STW_TMP158;
				state <= STORE1;
			end
		`PLP:
			begin
				inc_sp();
				load_what <= `SR_70;
				state <= LOAD_MAC1;
			end
		`PLA:
			begin
				inc_sp();
				load_what <= m16 ? `HALF_71S : `BYTE_71;
				state <= LOAD_MAC1;
			end
		`PLX,`PLY:
			begin
				inc_sp();
				load_what <= xb16 ? `HALF_71S : `BYTE_71;
				state <= LOAD_MAC1;
			end
		`PLB:
			begin
				inc_sp();
				load_what <= `BYTE_71;
				state <= LOAD_MAC1;
			end
		`PLD:
			begin
				inc_sp();
				load_what <= `HALF_71;
				state <= LOAD_MAC1;
			end
		`MVN:
			begin
				radr <= {ir[23:16],xb16 ? x[15:0] : {8'h00,x[7:0]}};
				x[15:0] <= x[15:0] + 16'd1;
				load_what <= `BYTE_72;
				state <= LOAD_MAC1;
			end
		`MVP:
			begin
				radr <= {ir[23:16],xb16 ? x[15:0] : {8'h00,x[7:0]}};
				x[15:0] <= x[15:0] - 16'd1;
				load_what <= `BYTE_72;
				state <= LOAD_MAC1;
			end
		default:	// unimplemented opcode
			pc <= pc + 32'd1;
		endcase
	end
	