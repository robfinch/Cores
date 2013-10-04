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
LOAD_MAC1:
`ifdef SUPPORT_DCACHE
	if (unCachedData)
`endif
	begin
		if (isRMW)
			lock_o <= 1'b1;
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= 4'hF;
		adr_o <= {radr,2'b00};
		state <= LOAD_MAC2;
	end
`ifdef SUPPORT_DCACHE
	else if (dhit) begin
		case(load_what)
		`WORD_310:
				begin
					b <= rdat;
					b8 <= rdat8;		// for the orb instruction
					state <= CALC;
				end
		`WORD_311:	// For pla/plx/ply/pop
					begin
						res <= rdat;
						state <= isPopa ? LOAD_MAC3 : IFETCH;
					end
		`WORD_312:
				begin
					b <= rdat;
					state <= retstate;
				end
`ifdef SUPPORT_EM8
		`BYTE_70:
				begin
					b8 <= rdat8;
					state <= BYTE_CALC;
				end
		`BYTE_71:
				begin
					res8 <= rdat8;
					state <= BYTE_IFETCH;
				end
`endif
		`SR_310:
				begin
					cf <= rdat[0];
					zf <= rdat[1];
					im <= rdat[2];
					df <= rdat[3];
					bf <= rdat[4];
					tf <= rdat[28];
					em <= rdat[29];
					vf <= rdat[30];
					nf <= rdat[31];
					isp <= isp_inc;
					radr <= isp_inc;
					if (isRTI)
						load_what <= `PC_310;
					else	// PLP
						state <= IFETCH;
				end
`ifdef SUPPORT_EM8
		`SR_70:
				begin
					cf <= rdat8[0];
					zf <= rdat8[1];
					im <= rdat8[2];
					df <= rdat8[3];
					bf <= rdat8[4];
					vf <= rdat8[6];
					nf <= rdat8[7];
					if (isRTI) begin
						load_what <= `PC_70;
						radr <= {spage[31:8],sp_inc[7:2]};
						radr2LSB <= sp_inc[1:0];
						sp <= sp_inc;
					end
					else	// PLP
						state <= BYTE_IFETCH;
				end
		`PC_70:
				begin
					pc[7:0] <= rdat8;
					if (isRTI | isRTS | isRTL) begin
						radr <= {spage[31:8],sp_inc[7:2]};
						radr2LSB <= sp_inc[1:0];
						sp <= sp_inc;
					end
					else begin	// JMP (abs)
						radr <= radr34p1[33:2];
						radr2LSB <= radr34p1[1:0];
					end
					load_what <= `PC_158;
				end
		`PC_158:
				begin
					pc[15:8] <= rdat8;
					if (isRTI|isRTL) begin
						radr <= {spage[31:8],sp_inc[7:2]};
						radr2LSB <= sp_inc[1:0];
						sp <= sp_inc;
						load_what <= `PC_2316;
					end
					else if (isRTS)	// rts instruction
						state <= RTS1;
					else			// jmp (abs)
						state <= BYTE_IFETCH;
				end
		`PC_2316:
				begin
					pc[23:16] <= rdat8;
					if (isRTI|isRTL) begin
						radr <= {spage[31:8],sp_inc[7:2]};
						radr2LSB <= sp_inc[1:0];
						sp <= sp_inc;
					end
					load_what <= `PC_3124;
				end	
		`PC_3124:
				begin
					pc[31:24] <= rdat8;
					load_what <= `NOTHING;
					if (isRTL)
						state <= RTS1;
					else
						state <= BYTE_IFETCH;
				end
`endif
		`PC_310:
				begin
					pc <= rdat;
					if (isRTI|isRTS|isRTL)
						isp <= isp_inc;
					load_what <= `NOTHING;
					// For the RTI instruction switch back to byte mode if flag is set.
					// Normally em will not be set.
					state <= em ? BYTE_IFETCH : IFETCH;
					if (isRTI)
						km <= `FALSE;
				end
		`IA_310:
				begin
					radr <= rdat;
					wadr <= rdat;
					wdat <= a;
					if (isIY)
						state <= IY3;
					else if (ir9==`ST_IX)
						state <= STORE1;
					else begin
						load_what <= `WORD_310;
					end
				end
`ifdef SUPPORT_EM8
		`IA_70:
				begin
					radr <= radr34p1[33:2];
					radr2LSB <= radr34p1[1:0];
					ia[7:0] <= rdat8;
					load_what <= `IA_158;
				end
		`IA_158:
				begin
					ia[15:8] <= rdat8;
					ia[31:16] <= 16'h0000;
					state <= isIY ? BYTE_IY5 : BYTE_IX5;
				end
`endif
		endcase
	end
	else
		dmiss <= `TRUE;
`endif
LOAD_MAC2:
	if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		sel_o <= 4'h0;
		adr_o <= 34'h0;
		case(load_what)
		`WORD_310:
					begin
						b <= dat_i;
						b8 <= dati;		// for the orb instruction
						state <= CALC;
					end
		`WORD_311:	// For pla/plx/ply/pop/ldx/ldy
					begin
						res <= dat_i;
						state <= isPopa ? LOAD_MAC3 : IFETCH;
					end
		`WORD_312:
				begin
					b <= dat_i;
					state <= retstate;
				end
`ifdef SUPPORT_EM8
		`BYTE_70:
					begin
						b8 <= dati;
						state <= BYTE_CALC;
					end
		`BYTE_71:
				begin
					res8 <= dati;
					state <= BYTE_IFETCH;
				end
`endif
		`SR_310:	begin
						cf <= dat_i[0];
						zf <= dat_i[1];
						im <= dat_i[2];
						df <= dat_i[3];
						bf <= dat_i[4];
						tf <= dat_i[28];
						em <= dat_i[29];
						vf <= dat_i[30];
						nf <= dat_i[31];
						isp <= isp_inc;
						radr <= isp_inc;
						if (isRTI) begin
							load_what <= `PC_310;
							state <= LOAD_MAC1;
						end
						else	// PLP
							state <= IFETCH;
					end
`ifdef SUPPORT_EM8
		`SR_70:		begin
						cf <= dati[0];
						zf <= dati[1];
						im <= dati[2];
						df <= dati[3];
						bf <= dati[4];
						vf <= dati[6];
						nf <= dati[7];
						if (isRTI) begin
							load_what <= `PC_70;
							radr <= {spage[31:8],sp_inc[7:2]};
							radr2LSB <= sp_inc[1:0];
							sp <= sp_inc;
							state <= LOAD_MAC1;
						end		
						else	// PLP
							state <= BYTE_IFETCH;
					end
		`PC_70:		begin
						pc[7:0] <= dati;
						load_what <= `PC_158;
						if (isRTI|isRTS|isRTL) begin
							radr <= {spage[31:8],sp_inc[7:2]};
							radr2LSB <= sp_inc[1:0];
							sp <= sp_inc;
						end
						else begin	// JMP (abs)
							radr <= radr34p1[33:2];
							radr2LSB <= radr34p1[1:0];
						end
						state <= LOAD_MAC1;
					end
		`PC_158:	begin
						pc[15:8] <= dati;
						if (isRTI|isRTL) begin
							load_what <= `PC_2316;
							radr <= {spage[31:8],sp_inc[7:2]};
							radr2LSB <= sp_inc[1:0];
							sp <= sp_inc;
							state <= LOAD_MAC1;
						end
						else if (isRTS)	// rts instruction
							state <= RTS1;
						else			// jmp (abs)
							state <= BYTE_IFETCH;
					end
		`PC_2316:	begin
						pc[23:16] <= dati;
						load_what <= `PC_3124;
						if (isRTI|isRTL) begin
							radr <= {spage[31:8],sp_inc[7:2]};
							radr2LSB <= sp_inc[1:0];
							sp <= sp_inc;
						end
						state <= LOAD_MAC1;	
					end
		`PC_3124:	begin
						pc[31:24] <= dati;
						load_what <= `NOTHING;
						if (isRTL)
							state <= RTS1;
						else
							state <= BYTE_IFETCH;
					end
`endif
		`PC_310:	begin
						pc <= dat_i;
						load_what <= `NOTHING;
						if (isRTI | isRTL | isRTS)
							isp <= isp_inc;
						if (isRTI)
							km <= `FALSE;
						state <= em ? BYTE_IFETCH : IFETCH;
					end
		`IA_310:
				begin
					radr <= dat_i;
					wadr <= dat_i;
					wdat <= a;
					if (isIY)
						state <= IY3;
					else if (ir9==`ST_IX)
						state <= STORE1;
					else begin
						load_what <= `WORD_310;
						state <= LOAD_MAC1;
					end
				end
`ifdef SUPPORT_EM8
		`IA_70:
				begin
					radr <= radr34p1[33:2];
					radr2LSB <= radr34p1[1:0];
					ia[7:0] <= dati;
					load_what <= `IA_158;
					state <= LOAD_MAC1;
				end
		`IA_158:
				begin
					ia[15:8] <= dati;
					ia[31:16] <= abs8[31:16];
					state <= isIY ? BYTE_IY5 : BYTE_IX5;
				end
`endif
		endcase
	end
`ifdef SUPPORT_BERR
	else if (err_i) begin
		lock_o <= 1'b0;
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		we_o <= 1'b0;
		sel_o <= 4'h0;
		dat_o <= 32'h0;
		state <= BUS_ERROR;
	end
`endif
LOAD_MAC3:
	begin
		regfile[Rt] <= res;
		case(Rt)
		4'h1:	acc <= res;
		4'h2:	x <= res;
		4'h3:	y <= res;
		default:	;
		endcase
		// Rt will be zero by the time the IFETCH stage is entered because of
		// the decrement below.
		if (Rt==4'd1)
			state <= IFETCH;
		else begin
			radr <= isp;
			isp <= isp_inc;
			state <= LOAD_MAC1;
		end
		Rt <= Rt - 4'd1;
	end

RTS1:
	begin
		pc <= pc + 32'd1;
		state <= BYTE_IFETCH;
	end
IY3:
	begin
		radr <= radr + y;
		wadr <= radr + y;
		if (ir9==`ST_IY) begin
			store_what <= `STW_A;
			state <= STORE1;
		end
		else begin
			load_what <= `WORD_310;
			state <= LOAD_MAC1;
		end
		isIY <= 1'b0;
	end
`ifdef SUPPORT_EM8
BYTE_IX5:
	begin
		radr <= ia[31:2];
		radr2LSB <= ia[1:0];
		load_what <= `BYTE_70;
		state <= LOAD_MAC1;
		if (ir[7:0]==`STA_IX || ir[7:0]==`STA_I) begin
			wadr <= ia[31:2];
			wadr2LSB <= ia[1:0];
			store_what <= `STW_ACC8;
			state <= STORE1;
		end
	end
BYTE_IY5:
	begin
		isIY <= `FALSE;
		radr <= iapy8[31:2];
		radr2LSB <= iapy8[1:0];
		$display("IY addr: %h", iapy8);
		if (ir[7:0]==`STA_IY) begin
			wadr <= iapy8[31:2];
			wadr2LSB <= iapy8[1:0];
			store_what <= `STW_ACC8;
			state <= STORE1;
		end
		else begin
			load_what <= `BYTE_70;
			state <= LOAD_MAC1;
		end
	end
`endif
