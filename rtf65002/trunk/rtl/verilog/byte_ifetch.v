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
BYTE_IFETCH:
	begin
		vect <= `BYTE_IRQ_VECT;
		suppress_pcinc <= 4'hF;				// default: no suppression of increment
		opc <= pc;
		hwi <= `FALSE;
		isBusErr <= `FALSE;
		pg2 <= `FALSE;
		store_what <= `STW_DEF;
		if (nmi_edge & gie) begin
			ir[7:0] <= `BRK;
			nmi_edge <= 1'b0;
			wai <= 1'b0;
			hwi <= `TRUE;
			if (nmoi) begin
				vect <= `NMI_VECT;
				next_state(DECODE);
			end
			else begin
				vect <= `BYTE_NMI_VECT;
				next_state(BYTE_DECODE);
			end
		end
		else if (irq_i & gie) begin
			wai <= 1'b0;
			if (im) begin
				if (unCachedInsn) begin
					if (bhit) begin
						ir <= ibuf;
						next_state(BYTE_DECODE);
					end
					else
						state <= LOAD_IBUF1;
				end
				else begin
					if (ihit) begin
						ir <= insn;
						next_state(BYTE_DECODE);
					end
					else
						state <= ICACHE1;
				end
			end
			else begin
				ir[7:0] <= `BRK;
				hwi <= `TRUE;
				if (nmoi) begin
					vect <= {vbr[31:9],irq_vect,2'b00};
					next_state(DECODE);
				end
				else begin
					next_state(BYTE_DECODE);
				end
			end
		end
		else if (!wai) begin
			if (unCachedInsn) begin
				if (bhit) begin
					ir <= ibuf;
					next_state(BYTE_DECODE);
				end
				else
					state <= LOAD_IBUF1;
			end
			else begin
				if (ihit) begin
					ir <= insn;
					next_state(BYTE_DECODE);
				end
				else
					state <= ICACHE1;
			end
		end
		if (hist_capture) begin
			history_buf[history_ndx] <= pc;
			history_ndx <= history_ndx+7'd1;
		end
		case(ir[7:0])
		`TAY,`TXY,`DEY,`INY:	begin y[7:0] <= res8[7:0]; nf <= resn8; zf <= resz8; end
		`TAX,`TYX,`TSX,`DEX,`INX:	begin x[7:0] <= res8[7:0]; nf <= resn8; zf <= resz8; end
		`TSA,`TYA,`TXA,`INA,`DEA:	begin acc[7:0] <= res8[7:0]; nf <= resn8; zf <= resz8; end
		`TAS,`TXS: begin sp <= res8[7:0]; end
		`ADC_IMM:
			begin
				acc[7:0] <= df ? bcaio : res8[7:0];
				cf <= df ? bcaico : resc8;
//						vf <= resv8;
				vf <= (res8[7] ^ b8[7]) & (1'b1 ^ acc[7] ^ b8[7]);
				nf <= df ? bcaio[7] : resn8;
				zf <= df ? bcaio==8'h00 : resz8;
			end
		`ADC_ZP,`ADC_ZPX,`ADC_IX,`ADC_IY,`ADC_ABS,`ADC_ABSX,`ADC_ABSY,`ADC_I:
			begin
				acc[7:0] <= df ? bcao : res8[7:0];
				cf <= df ? bcaco : resc8;
				vf <= (res8[7] ^ b8[7]) & (1'b1 ^ acc[7] ^ b8[7]);
				nf <= df ? bcao[7] : resn8;
				zf <= df ? bcao==8'h00 : resz8;
			end
		`SBC_IMM:
			begin
				acc[7:0] <= df ? bcsio : res8[7:0];
				cf <= ~(df ? bcsico : resc8);
				vf <= (1'b1 ^ res8[7] ^ b8[7]) & (acc[7] ^ b8[7]);
				nf <= df ? bcsio[7] : resn8;
				zf <= df ? bcsio==8'h00 : resz8;
			end
		`SBC_ZP,`SBC_ZPX,`SBC_IX,`SBC_IY,`SBC_ABS,`SBC_ABSX,`SBC_ABSY,`SBC_I:
			begin
				acc[7:0] <= df ? bcso : res8[7:0];
				vf <= (1'b1 ^ res8[7] ^ b8[7]) & (acc[7] ^ b8[7]);
				cf <= ~(df ? bcsco : resc8);
				nf <= df ? bcso[7] : resn8;
				zf <= df ? bcso==8'h00 : resz8;
			end
		`CMP_IMM,`CMP_ZP,`CMP_ZPX,`CMP_IX,`CMP_IY,`CMP_ABS,`CMP_ABSX,`CMP_ABSY,`CMP_I,
		`CPX_IMM,`CPX_ZP,`CPX_ABS,
		`CPY_IMM,`CPY_ZP,`CPY_ABS:
				begin cf <= ~resc8; nf <= resn8; zf <= resz8; end
		`BIT_IMM,`BIT_ZP,`BIT_ZPX,`BIT_ABS,`BIT_ABSX:
				begin nf <= b8[7]; vf <= b8[6]; zf <= resz8; end
		`TRB_ZP,`TRB_ABS,`TSB_ZP,`TSB_ABS:
			begin zf <= resz8; end
		`LDA_IMM,`LDA_ZP,`LDA_ZPX,`LDA_IX,`LDA_IY,`LDA_ABS,`LDA_ABSX,`LDA_ABSY,`LDA_I,
		`AND_IMM,`AND_ZP,`AND_ZPX,`AND_IX,`AND_IY,`AND_ABS,`AND_ABSX,`AND_ABSY,`AND_I,
		`ORA_IMM,`ORA_ZP,`ORA_ZPX,`ORA_IX,`ORA_IY,`ORA_ABS,`ORA_ABSX,`ORA_ABSY,`ORA_I,
		`EOR_IMM,`EOR_ZP,`EOR_ZPX,`EOR_IX,`EOR_IY,`EOR_ABS,`EOR_ABSX,`EOR_ABSY,`EOR_I:
			begin acc[7:0] <= res8[7:0]; nf <= resn8; zf <= resz8; end
		`ASL_ACC:	begin acc[7:0] <= res8[7:0]; cf <= resc8; nf <= resn8; zf <= resz8; end
		`ROL_ACC:	begin acc[7:0] <= res8[7:0]; cf <= resc8; nf <= resn8; zf <= resz8; end
		`LSR_ACC:	begin acc[7:0] <= res8[7:0]; cf <= resc8; nf <= resn8; zf <= resz8; end
		`ROR_ACC:	begin acc[7:0] <= res8[7:0]; cf <= resc8; nf <= resn8; zf <= resz8; end
		`ASL_ZP,`ASL_ZPX,`ASL_ABS,`ASL_ABSX: begin cf <= resc8; nf <= resn8; zf <= resz8; end
		`ROL_ZP,`ROL_ZPX,`ROL_ABS,`ROL_ABSX: begin cf <= resc8; nf <= resn8; zf <= resz8; end
		`LSR_ZP,`LSR_ZPX,`LSR_ABS,`LSR_ABSX: begin cf <= resc8; nf <= resn8; zf <= resz8; end
		`ROR_ZP,`ROR_ZPX,`ROR_ABS,`ROR_ABSX: begin cf <= resc8; nf <= resn8; zf <= resz8; end
		`INC_ZP,`INC_ZPX,`INC_ABS,`INC_ABSX: begin nf <= resn8; zf <= resz8; end
		`DEC_ZP,`DEC_ZPX,`DEC_ABS,`DEC_ABSX: begin nf <= resn8; zf <= resz8; end
		`PLA:	begin acc[7:0] <= res8[7:0]; zf <= resz8; nf <= resn8; end
		`PLX:	begin x[7:0] <= res8[7:0]; zf <= resz8; nf <= resn8; end
		`PLY:	begin y[7:0] <= res8[7:0]; zf <= resz8; nf <= resn8; end
		`LDX_IMM,`LDX_ZP,`LDX_ZPY,`LDX_ABS,`LDX_ABSY:	begin x[7:0] <= res8[7:0]; nf <= resn8; zf <= resz8; end
		`LDY_IMM,`LDY_ZP,`LDY_ZPX,`LDY_ABS,`LDY_ABSX:	begin y[7:0] <= res8[7:0]; nf <= resn8; zf <= resz8; end
		endcase
	end
