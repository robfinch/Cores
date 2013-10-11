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
task load_tsk;
input [31:0] dat;
input [7:0] dat8;
begin
	case(load_what)
	`WORD_310:
				begin
					b <= dat;
					b8 <= dat8;		// for the orb instruction
					state <= CALC;
				end
	`WORD_311:	// For pla/plx/ply/pop/ldx/ldy
				begin
					res <= dat;
					state <= isPopa ? LOAD_MAC3 : IFETCH;
				end
	`WORD_312:
			begin
				b <= dat;
				radr <= y;
				wadr <= y;
				store_what <= `STW_B;
				x <= res[31:0];
				acc <= acc - 32'd1;
				state <= STORE1;
			end
	`WORD_313:
			begin
				a <= dat;
				radr <= y;
				load_what <= `WORD_314;
				x <= res[31:0];
				state <= LOAD_MAC1;
			end
	`WORD_314:
			begin
				b <= dat;
				acc <= acc - 32'd1;
				state <= CMPS1;
			end
`ifdef SUPPORT_EM8
	`BYTE_70:
				begin
					b8 <= dat8;
					state <= BYTE_CALC;
				end
	`BYTE_71:
			begin
				res8 <= dat8;
				state <= BYTE_IFETCH;
			end
`endif
	`SR_310:	begin
					cf <= dat[0];
					zf <= dat[1];
					im <= dat[2];
					df <= dat[3];
					bf <= dat[4];
					tf <= dat[28];
					em <= dat[29];
					vf <= dat[30];
					nf <= dat[31];
					if (isRTI) begin
						radr <= isp;
						isp <= isp_inc;
						load_what <= `PC_310;
						state <= LOAD_MAC1;
					end
					else	// PLP
						state <= IFETCH;
				end
`ifdef SUPPORT_EM8
	`SR_70:		begin
					cf <= dat8[0];
					zf <= dat8[1];
					im <= dat8[2];
					df <= dat8[3];
					bf <= dat8[4];
					vf <= dat8[6];
					nf <= dat8[7];
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
					pc[7:0] <= dat8;
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
					pc[15:8] <= dat8;
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
					pc[23:16] <= dat8;
					load_what <= `PC_3124;
					if (isRTI|isRTL) begin
						radr <= {spage[31:8],sp_inc[7:2]};
						radr2LSB <= sp_inc[1:0];
						sp <= sp_inc;
					end
					state <= LOAD_MAC1;	
				end
	`PC_3124:	begin
					pc[31:24] <= dat8;
					load_what <= `NOTHING;
					if (isRTL)
						state <= RTS1;
					else
						state <= BYTE_IFETCH;
				end
`endif
	`PC_310:	begin
					pc <= dat;
					load_what <= `NOTHING;
					if (isRTI) begin
						km <= `FALSE;
						hist_capture <= `TRUE;
					end
					state <= em ? BYTE_IFETCH : IFETCH;
				end
	`IA_310:
			begin
				radr <= dat;
				wadr <= dat;
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
				ia[7:0] <= dat8;
				load_what <= `IA_158;
				state <= LOAD_MAC1;
			end
	`IA_158:
			begin
				ia[15:8] <= dat8;
				ia[31:16] <= abs8[31:16];
				state <= isIY ? BYTE_IY5 : BYTE_IX5;
			end
`endif
	endcase
end
endtask
