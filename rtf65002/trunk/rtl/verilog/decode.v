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
DECODE:
	begin
		first_ifetch <= `TRUE;
		Rt <= 4'h0;		// Default
		state <= IFETCH;
		pc <= pc + pc_inc;
		a <= rfoa;
		ttrig <= tf;
		// This case statement should include all opcodes or the opcode
		// will end up being treated as an undefined operation.
		case(ir9)
		`STP:	clk_en <= 1'b0;
		`NOP:	;
//				casex(ir[63:0])
//				{`NOP,`NOP,`NOP,`NOP,`NOP,`NOP,`NOP,`NOP}:	pc <= pcp8;
//				{8'hxx,`NOP,`NOP,`NOP,`NOP,`NOP,`NOP,`NOP}:	pc <= pcp7;
//				{16'hxxxx,`NOP,`NOP,`NOP,`NOP,`NOP,`NOP}:	pc <= pcp6;
//				{24'hxxxxxx,`NOP,`NOP,`NOP,`NOP,`NOP}:	pc <= pcp5;
//				{32'hxxxxxxxx,`NOP,`NOP,`NOP,`NOP}:	pc <= pcp4;
//				{40'hxxxxxxxxxx,`NOP,`NOP,`NOP}:	pc <= pcp3;
//				{48'hxxxxxxxxxxxx,`NOP,`NOP}:	pc <= pcp2;
//				{56'hxxxxxxxxxxxxxx,`NOP}:	pc <= pcp1;
//				endcase
		`CLC:	cf <= 1'b0;
		`SEC:	cf <= 1'b1;
		`CLV:	vf <= 1'b0;
		`CLI:	im <= 1'b0;
		`CLD:	df <= 1'b0;
		`SED:	df <= 1'b1;
		`SEI:	im <= 1'b1;
		`WAI:	wai <= 1'b1;
		`TON:	tf <= 1'b1;
		`TOFF:	tf <= 1'b0;
		`EMM:	begin em <= 1'b1; state <= BYTE_IFETCH; end
		`DEX:	begin 
					res <= x - 32'd1;
					// DEX/BNE accelerator
//					if (ir[15:8]==`BNE) begin
//						if (x!=32'd1) begin
//							if (ir[23:16]==8'h01)
//								pc <= pc + {{16{ir[39]}},ir[39:24]} + 32'd1;
//							else
//								pc <= pc + {{24{ir[23]}},ir[23:16]} + 32'd1;
//						end
//						else begin
//							if (ir[23:16]==8'h01)
//								pc <= pcp5;
//							else
//								pc <= pcp3;
//						end
//					end
				end
		`INX:	res <= x + 32'd1;
		`DEY:	res <= y - 32'd1;
		`INY:	res <= y + 32'd1;
		`DEA:	res <= acc - 32'd1;
		`INA:	res <= acc + 32'd1;
		`TSX,`TSA:	res <= isp;
		`TXS,`TXA,`TXY:	res <= x;
		`TAX,`TAY,`TAS:	res <= acc;
		`TYA,`TYX:	res <= y;
		`TRS:		res <= rfoa;
		`TSR:		begin
						Rt <= ir[15:12];
						case(ir[11:8])
						4'h0:	
							begin
`ifdef SUPPORT_ICACHE
								res[0] <= icacheOn;
`endif
`ifdef SUPPORT_DCACHE
								res[1] <= dcacheOn;
								res[2] <= write_allocate;
`endif
								res[31:3] <= 29'd0;
							end
						4'h2:	res <= prod[31:0];
						4'h3:	res <= prod[63:32];
						4'h4:	res <= tick;
						4'h5:	begin res <= lfsr; lfsr <= {lfsr[30:0],lfsr_fb}; end
						4'd7:	res <= abs8;
						4'h8:	res <= {vbr[31:1],nmoi};
						4'h9:	res <= derr_address;
						4'hA:	begin res <= history_buf[history_ndx];	history_ndx <= history_ndx + 6'd1; end
						4'hE:	res <= {spage[31:8],sp};
						4'hF:	res <= isp;
						default:	res <= 32'd0;
						endcase
					end
		`ASL_ACC:	begin res <= {acc,1'b0}; end
		`ROL_ACC:	begin res <= {acc,cf};end
		`LSR_ACC:	begin res <= {acc[0],1'b0,acc[31:1]}; end
		`ROR_ACC:	begin res <= {acc[0],cf,acc[31:1]}; end

		`RR:
			begin
				state <= IFETCH;
				Rt <= ir[19:16];
				case(ir[23:20])
				`ADD_RR:	begin res <= rfoa + rfob + {31'b0,df&cf}; b <= rfob; end
				`SUB_RR:	begin res <= rfoa - rfob - {31'b0,df&~cf&|ir[19:16]}; b <= rfob; end
				`AND_RR:	begin res <= rfoa & rfob; b <= rfob; end	// for bit flags
				`OR_RR:		begin res <= rfoa | rfob; b <= rfob; end
				`EOR_RR:	begin res <= rfoa ^ rfob; b <= rfob; end
				`MUL_RR:	begin a <= rfoa; b <= rfob; state <= MULDIV1; end
				`MULS_RR:	begin a <= rfoa; b <= rfob; state <= MULDIV1; end
`ifdef SUPPORT_DIVMOD
				`DIV_RR:	begin a <= rfoa; b <= rfob; state <= MULDIV1; end
				`DIVS_RR:	begin a <= rfoa; b <= rfob; state <= MULDIV1; end
				`MOD_RR:	begin a <= rfoa; b <= rfob; state <= MULDIV1; end
				`MODS_RR:	begin a <= rfoa; b <= rfob; state <= MULDIV1; end
`endif
`ifdef SUPPORT_SHIFT
				`ASL_RRR:	begin b <= rfob; state <= CALC; end
				`LSR_RRR:	begin b <= rfob; state <= CALC; end
`endif
				default:
					begin
						Rt <= 4'h0;
						pg2 <= `FALSE;
						ir <= {8{`BRK}};
						hwi <= `TRUE;
						vect <= {vbr[31:9],9'd495,2'b00};
						pc <= pc;		// override the pc increment
						state <= DECODE;
					end
				endcase
			end
		`LD_RR:		begin res <= rfoa; Rt <= ir[15:12]; end
		`ASL_RR:	begin res <= {rfoa,1'b0}; Rt <= ir[15:12]; end
		`ROL_RR:	begin res <= {rfoa,cf}; Rt <= ir[15:12]; end
		`LSR_RR:	begin res <= {rfoa[0],1'b0,rfoa[31:1]}; Rt <= ir[15:12]; end
		`ROR_RR:	begin res <= {rfoa[0],cf,rfoa[31:1]}; Rt <= ir[15:12]; end
		`DEC_RR:	begin res <= rfoa - 32'd1; Rt <= ir[15:12]; end
		`INC_RR:	begin res <= rfoa + 32'd1; Rt <= ir[15:12]; end

		`ADD_IMM8:	begin res <= rfoa + {{24{ir[23]}},ir[23:16]} + {31'b0,df&cf}; Rt <= ir[15:12]; b <= {{24{ir[23]}},ir[23:16]}; end
		`SUB_IMM8:	begin res <= rfoa - {{24{ir[23]}},ir[23:16]} - {31'b0,df&~cf&|ir[15:12]}; Rt <= ir[15:12]; b <= {{24{ir[23]}},ir[23:16]}; end
		`MUL_IMM8:	begin a <= rfoa; b <= {{24{ir[23]}},ir[23:16]}; Rt <= ir[15:12]; state <= MULDIV1; end
`ifdef SUPPORT_DIVMOD
		`DIV_IMM8:	begin a <= rfoa; b <= {{24{ir[23]}},ir[23:16]}; Rt <= ir[15:12]; state <= MULDIV1; end
		`MOD_IMM8:	begin a <= rfoa; b <= {{24{ir[23]}},ir[23:16]}; Rt <= ir[15:12]; state <= MULDIV1; end
`endif
		`OR_IMM8:	begin res <= rfoa | {{24{ir[23]}},ir[23:16]}; Rt <= ir[15:12]; end
		`AND_IMM8: 	begin res <= rfoa & {{24{ir[23]}},ir[23:16]}; Rt <= ir[15:12]; b <= {{24{ir[23]}},ir[23:16]}; end
		`EOR_IMM8:	begin res <= rfoa ^ {{24{ir[23]}},ir[23:16]}; Rt <= ir[15:12]; end
		`CMP_IMM8:	begin res <= acc - {{24{ir[15]}},ir[15:8]}; end
`ifdef SUPPORT_SHIFT
		`ASL_IMM8:	begin b <= ir[20:16]; Rt <= ir[15:12]; state <= CALC; end
		`LSR_IMM8:	begin b <= ir[20:16]; Rt <= ir[15:12]; state <= CALC; end
`endif

		`ADD_IMM16:	begin res <= rfoa + {{16{ir[31]}},ir[31:16]} + {31'b0,df&cf}; Rt <= ir[15:12]; b <= {{16{ir[31]}},ir[31:16]}; end
		`SUB_IMM16:	begin res <= rfoa - {{16{ir[31]}},ir[31:16]} - {31'b0,df&~cf&|ir[15:12]}; Rt <= ir[15:12]; b <= {{16{ir[31]}},ir[31:16]}; end
		`MUL_IMM16:	begin a <= rfoa; b <= {{16{ir[31]}},ir[31:16]}; Rt <= ir[15:12]; state <= MULDIV1; end
`ifdef SUPPORT_DIVMOD
		`DIV_IMM16:	begin a <= rfoa; b <= {{16{ir[31]}},ir[31:16]}; Rt <= ir[15:12]; state <= MULDIV1; end
		`MOD_IMM16:	begin a <= rfoa; b <= {{16{ir[31]}},ir[31:16]}; Rt <= ir[15:12]; state <= MULDIV1; end
`endif
		`OR_IMM16:	begin res <= rfoa | {{16{ir[31]}},ir[31:16]}; Rt <= ir[15:12]; end
		`AND_IMM16:	begin res <= rfoa & {{16{ir[31]}},ir[31:16]}; Rt <= ir[15:12]; b <= {{16{ir[31]}},ir[31:16]}; end
		`EOR_IMM16:	begin res <= rfoa ^ {{16{ir[31]}},ir[31:16]}; Rt <= ir[15:12]; end
	
		`ADD_IMM32:	begin res <= rfoa + ir[47:16] + {31'b0,df&cf}; Rt <= ir[15:12]; b <= ir[47:16]; end
		`SUB_IMM32:	begin res <= rfoa - ir[47:16] - {31'b0,df&~cf&|ir[15:12]}; Rt <= ir[15:12]; b <= ir[47:16]; end
		`MUL_IMM16:	begin a <= rfoa; b <= ir[47:16]; Rt <= ir[15:12]; state <= MULDIV1; end
`ifdef SUPPORT_DIVMOD
		`DIV_IMM32:	begin a <= rfoa; b <= ir[47:16]; Rt <= ir[15:12]; state <= MULDIV1; end
		`MOD_IMM32:	begin a <= rfoa; b <= ir[47:16]; Rt <= ir[15:12]; state <= MULDIV1; end
`endif
		`OR_IMM32:	begin res <= rfoa | ir[47:16]; Rt <= ir[15:12]; end
		`AND_IMM32:	begin res <= rfoa & ir[47:16]; Rt <= ir[15:12]; b <= ir[47:16]; end
		`EOR_IMM32:	begin res <= rfoa ^ ir[47:16]; Rt <= ir[15:12]; end

		`LDX_IMM32,`LDY_IMM32,`LDA_IMM32:	res <= ir[39:8];
		`LDX_IMM16,`LDA_IMM16:	res <= {{16{ir[23]}},ir[23:8]};
		`LDX_IMM8,`LDA_IMM8: res <= {{24{ir[15]}},ir[15:8]};

		`SUB_SP8:	res <= isp - {{24{ir[15]}},ir[15:8]};
		`SUB_SP16:	res <= isp - {{16{ir[23]}},ir[23:8]};
		`SUB_SP32:	res <= isp - ir[39:8];

		`CPX_IMM32:	res <= x - ir[39:8];
		`CPY_IMM32:	res <= y - ir[39:8];

		`LDX_ZPX,`LDY_ZPX:
			begin
				radr <= zpx32xy_address;
				load_what <= `WORD_311;
				state <= LOAD_MAC1;
			end
		`ORB_ZPX:
			begin
				Rt <= ir[19:16];
				radr <= zpx32_address[31:2];
				radr2LSB <= zpx32_address[1:0];
				load_what <= `WORD_310;
				state <= LOAD_MAC1;
			end
		`LDX_ABS,`LDY_ABS:
			begin
				radr <= ir[39:8];
				load_what <= `WORD_311;
				state <= LOAD_MAC1;
			end
		`ORB_ABS:
			begin
				Rt <= ir[15:12];
				radr <= ir[47:18];
				radr2LSB <= ir[17:16];
				load_what <= `WORD_310;
				state <= LOAD_MAC1;
			end
		`LDX_ABSY,`LDY_ABSX:
			begin
				radr <= absx32xy_address;
				load_what <= `WORD_311;
				state <= LOAD_MAC1;
			end
		`ORB_ABSX:
			begin
				Rt <= ir[19:16];
				radr <= absx32_address[31:2];
				radr2LSB <= absx32_address[1:0];
				load_what <= `WORD_310;
				state <= LOAD_MAC1;
			end
		`ST_ZPX:
			begin
				wadr <= zpx32_address;
				store_what <= `STW_RFA;
				state <= STORE1;
			end
		`STB_ZPX:
			begin
				wadr <= zpx32_address[31:2];
				wadr2LSB <= zpx32_address[1:0];
				store_what <= `STW_RFA8;
				state <= STORE1;
			end
		`ST_DSP:
			begin
				wadr <= {{24{ir[23]}},ir[23:16]} + isp;
				store_what <= `STW_RFA;
				state <= STORE1;
			end
		`ST_ABS:
			begin
				wadr <= ir[47:16];
				store_what <= `STW_RFA;
				state <= STORE1;
			end
		`STB_ABS:
			begin
				wadr <= ir[47:18];
				wadr2LSB <= ir[17:16];
				store_what <= `STW_RFA8;
				state <= STORE1;
			end
		`ST_ABSX:
			begin
				wadr <= absx32_address;
				store_what <= `STW_RFA;
				state <= STORE1;
			end
		`STB_ABSX:
			begin
				wadr <= absx32_address[31:2];
				wadr2LSB <= absx32_address[1:0];
				store_what <= `STW_RFA8;
				state <= STORE1;
			end
		`STX_ZPX:
			begin
				wadr <= zpx32xy_address;
				store_what <= `STW_X;
				state <= STORE1;
			end
		`STX_ABS:
			begin
				wadr <= ir[39:8];
				store_what <= `STW_X;
				state <= STORE1;
			end
		`STY_ZPX:
			begin
				wadr <= zpx32xy_address;
				store_what <= `STW_Y;
				state <= STORE1;
			end
		`STY_ABS:
			begin
				wadr <= ir[39:8];
				store_what <= `STW_Y;
				state <= STORE1;
			end
		`ADD_ZPX,`SUB_ZPX,`AND_ZPX:
			begin
				Rt <= ir[19:16];
				radr <= zpx32_address;
				load_what <= `WORD_310;
				state <= LOAD_MAC1;
			end
		// Trim a clock cycle off of loads by testing for Ra = 0.
		`OR_ZPX,`EOR_ZPX:
			begin
				Rt <= ir[19:16];
				radr <= zpx32_address;
				load_what <= (Ra==4'd0) ? `WORD_311: `WORD_310;
				state <= LOAD_MAC1;
			end
		`ASL_ZPX,`ROL_ZPX,`LSR_ZPX,`ROR_ZPX,`INC_ZPX,`DEC_ZPX:
			begin
				radr <= zpx32xy_address;
				load_what <= `WORD_310;
				state <= LOAD_MAC1;
			end
		`ADD_DSP,`SUB_DSP,`OR_DSP,`AND_DSP,`EOR_DSP:
			begin
				Rt <= ir[15:12];
				radr <= {{24{ir[23]}},ir[23:16]} + isp;
				load_what <= `WORD_310;
				state <= LOAD_MAC1;
			end
		`ADD_IX,`SUB_IX,`OR_IX,`AND_IX,`EOR_IX,`ST_IX:
			begin
				if (ir[7:0]!=`ST_IX)	// for ST_IX, Rt=0
					Rt <= ir[19:16];
				radr <= zpx32_address;
				load_what <= `IA_310;
				store_what <= `STW_A;
				state <= LOAD_MAC1;			
			end
		`ADD_RIND,`SUB_RIND,`OR_RIND,`AND_RIND,`EOR_RIND:
			begin
				radr <= rfob;
				Rt <= ir[19:16];
				load_what <= `WORD_310;
				state <= LOAD_MAC1;
			end
		`ST_RIND:
			begin
				wadr <= rfob;
				store_what <= `STW_RFA;
				state <= STORE1;
			end
		`ADD_IY,`SUB_IY,`OR_IY,`AND_IY,`EOR_IY,`ST_IY:
			begin
				if (ir[7:0]!=`ST_IY)	// for ST_IY, Rt=0
					Rt <= ir[19:16];
				isIY <= 1'b1;
				radr <= ir[31:20];
				load_what <= `IA_310;
				store_what <= `STW_A;
				state <= LOAD_MAC1;	
			end
		`OR_ABS,`EOR_ABS:
			begin
				radr <= ir[47:16];
				Rt <= ir[15:12];
				load_what <= (Ra==4'd0) ? `WORD_311 : `WORD_310;
				state <= LOAD_MAC1;
			end
		`ADD_ABS,`SUB_ABS,`AND_ABS:
			begin
				radr <= ir[47:16];
				Rt <= ir[15:12];
				load_what <= `WORD_310;
				state <= LOAD_MAC1;
			end
		`ASL_ABS,`ROL_ABS,`LSR_ABS,`ROR_ABS,`INC_ABS,`DEC_ABS:
			begin
				radr <= ir[39:8];
				load_what <= `WORD_310;
				state <= LOAD_MAC1;
			end
		`ADD_ABSX,`SUB_ABSX,`AND_ABSX:
			begin
				radr <= absx32_address;
				Rt <= ir[19:16];
				load_what <= `WORD_310;
				state <= LOAD_MAC1;
			end
		`OR_ABSX,`EOR_ABSX:
			begin
				radr <= absx32_address;
				Rt <= ir[19:16];
				load_what <= (Ra==4'd0) ? `WORD_311 : `WORD_310;
				state <= LOAD_MAC1;
			end
		`ASL_ABSX,`ROL_ABSX,`LSR_ABSX,`ROR_ABSX,`INC_ABSX,`DEC_ABSX:
			begin
				radr <= absx32xy_address;
				load_what <= `WORD_310;
				state <= LOAD_MAC1;
			end

		`CPX_ZPX:
			begin
				radr <= zpx32xy_address;
				load_what <= `WORD_310;
				state <= LOAD_MAC1;
			end
		`CPY_ZPX:
			begin
				radr <= zpx32xy_address;
				load_what <= `WORD_310;
				state <= LOAD_MAC1;
			end
		`CPX_ABS:
			begin
				radr <= ir[39:8];
				load_what <= `WORD_310;
				state <= LOAD_MAC1;
			end
		`CPY_ABS:
			begin
				radr <= ir[39:8];
				load_what <= `WORD_310;
				state <= LOAD_MAC1;
			end
		`BRK:
			begin
				bf <= !hwi;
				km <= `TRUE;
				hist_capture <= `FALSE;
				radr <= isp_dec;
				wadr <= isp_dec;
				isp <= isp_dec;
				store_what <= `STW_PCHWI;
				state <= STORE1;
			end
		`INT0,`INT1:
			begin
				pg2 <= `FALSE;
				ir <= {8{`BRK}};
				vect <= {vbr[31:9],ir[15:7],2'b00};
				state <= DECODE;
			end
		`JMP:
			begin
				pc[15:0] <= ir[23:8];
				state <= IFETCH;
			end
		`JML:
			begin
				pc <= ir[39:8];
				state <= IFETCH;
			end
		`JMP_IND:
			begin
				radr <= ir[39:8];
				load_what <= `PC_310;
				state <= LOAD_MAC1;
			end
		`JMP_INDX:
			begin
				radr <= ir[39:8] + x;
				load_what <= `PC_310;
				state <= LOAD_MAC1;
			end
		`JMP_RIND:
			begin
				pc <= rfoa;
				res <= pc + 32'd2;
				Rt <= ir[15:12];
				state <= IFETCH;
			end
		`JSR:
			begin
				radr <= isp_dec;
				wadr <= isp_dec;
				isp <= isp_dec;
				store_what <= `STW_DEF;
				wdat <= pc+{31'd1,suppress_pcinc[0]};
				pc <= {pc[31:16],ir[23:8]};
				state <= STORE1;
			end
		`JSR_RIND:
			begin
				radr <= isp_dec;
				wadr <= isp_dec;
				wdat <= pc + 32'd2;
				isp <= isp_dec;
				store_what <= `STW_DEF;
				pc <= rfoa;
				state <= STORE1;
			end
		`JSL,`JSR_INDX,`JSR_IND:
			begin
				radr <= isp_dec;
				wadr <= isp_dec;
				isp <= isp_dec;
				store_what <= `STW_DEF;
				wdat <= suppress_pcinc[0] ? pc + 32'd5 : pc + 32'd2;
				pc <= ir[39:8];		// This pc assignment will be overridden later by JSR_INDX
				state <= STORE1;
			end
		`BSR:
			begin
				radr <= isp_dec;
				wadr <= isp_dec;
				isp <= isp_dec;
				store_what <= `STW_DEF;
				wdat <= pc+{31'd1,suppress_pcinc[0]};
				pc <= pc + {{16{ir[23]}},ir[23:8]};
				state <= STORE1;
			end
		`RTS,`RTL:
				begin
				radr <= isp;
				load_what <= `PC_310;
				state <= LOAD_MAC1;
				end
		`RTI:	begin
				hist_capture <= `TRUE;
				radr <= isp;
				load_what <= `SR_310;
				state <= LOAD_MAC1;
				end
		`BEQ,`BNE,`BPL,`BMI,`BCC,`BCS,`BVC,`BVS,`BRA,
		`BGT,`BGE,`BLT,`BLE,`BHI,`BLS:
			begin
				state <= IFETCH;
				if (ir[15:8]==8'h00) begin
					pg2 <= `FALSE;
					ir <= {8{`BRK}};
					pc <= pc;		// override the pc increment
					vect <= {vbr[31:9],`SLP_VECTNO,2'b00};
					state <= DECODE;
				end
				else if (ir[15:8]==8'h1) begin
					if (takb)
						pc <= pc + {{16{ir[31]}},ir[31:16]};
					else
						pc <= pcp4;
				end
				else begin
					if (takb)
						pc <= pc + {{24{ir[15]}},ir[15:8]};
					else
						pc <= pcp2;
				end
			end
		`BRL:
			begin
				if (ir[23:8]==16'h0000) begin
					pg2 <= `FALSE;
					ir <= {8{`BRK}};
					vect <= {vbr[31:9],`SLP_VECTNO,2'b00};
					pc <= pc;		// override the pc increment
					state <= DECODE;
				end
				else begin
					pc <= pc + {{16{ir[23]}},ir[23:8]};
					state <= IFETCH;
				end
			end
`ifdef SUPPORT_EXEC
		`EXEC,`ATNI:
			begin
				exbuf[31:0] <= rfoa;
				exbuf[63:32] <= rfob;
				state <= IFETCH;
			end
`endif
		`PHP:
			begin
				radr <= isp_dec;
				wadr <= isp_dec;
				store_what <= `STW_SR;
				isp <= isp_dec;
				state <= STORE1;
			end
		`PHA:
			begin
				radr <= isp_dec;
				wadr <= isp_dec;
				store_what <= `STW_ACC;
				isp <= isp_dec;
				state <= STORE1;
			end
		`PHX:
			begin
				radr <= isp_dec;
				wadr <= isp_dec;
				store_what <= `STW_X;
				isp <= isp_dec;
				state <= STORE1;
			end
		`PHY:
			begin
				radr <= isp_dec;
				wadr <= isp_dec;
				store_what <= `STW_Y;
				isp <= isp_dec;
				state <= STORE1;
			end
		`PUSH:
			begin
				radr <= isp_dec;
				wadr <= isp_dec;
				store_what <= `STW_RFA;
				state <= STORE1;
				isp <= isp_dec;
			end
		`PUSHA:
			begin
				radr <= isp_dec;
				wadr <= isp_dec;
				ir[11:8] <= 4'd1;
				store_what <= `STW_RFA;
				state <= STORE1;
				isp <= isp_dec;
			end
		`PLP:
			begin
				radr <= isp;
				load_what <= `SR_310;
				state <= LOAD_MAC1;
			end
		`PLA,`PLX,`PLY:
			begin
				radr <= isp;
				isp <= isp_inc;
				load_what <= `WORD_311;
				state <= LOAD_MAC1;
			end
		`POP:
			begin
				Rt <= ir[15:12];
				radr <= isp;
				isp <= isp_inc;
				load_what <= `WORD_311;
				state <= LOAD_MAC1;
			end
		`POPA:
			begin
				Rt <= 4'd15;
				radr <= isp;
				isp <= isp_inc;
				load_what <= `WORD_311;
				state <= LOAD_MAC1;
			end
`ifdef SUPPORT_STRING
		`MVN:	state <= MVN1;
		`MVP:	state <= MVP1;
		`STS:	state <= STS1;
`endif
		`PG2:	begin
					pg2 <= `TRUE;
					ir <= ir[63:8];
					state <= DECODE;
				end
		default:	// unimplemented opcode
			begin
				res <= 32'd0;
				pg2 <= `FALSE;
				ir <= {8{`BRK}};
				hwi <= `TRUE;
				vect <= {vbr[31:9],9'd495,2'b00};
				pc <= pc;		// override the pc increment
				state <= DECODE;
			end
		endcase
	end
