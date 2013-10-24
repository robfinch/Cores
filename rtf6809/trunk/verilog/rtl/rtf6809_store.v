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
// Memory store states
// The store states work for either eight bit or 32 bit mode              
// ============================================================================
//
// Stores always write through to memory, then optionally update the cache if
// there was a write hit.
STORE1:
	begin
		case(store_what)
		`STW_ACCA:	wb_write(acca);
		`STW_ACCB:	wb_write(accb);
		`STW_DPR:	wb_write(dpr);
		`STW_XL:	wb_write(xr[7:0]);
		`STW_XH:	wb_write(xr[15:8]);
		`STW_YL:	wb_write(yr[7:0]);
		`STW_YH:	wb_write(yr[15:8]);
		`STW_USPL:	wb_write(usp[7:0]);
		`STW_USPH:	wb_write(usp[15:8]);
		`STW_SSPL:	wb_write(ssp[7:0]);
		`STW_SSPH:	wb_write(ssp[15:8]);
		`STW_PCH:	wb_write(pc[15:8]);
		`STW_PCL:	wb_write(pc[7:0]);
		`STW_CCR:	wb_write(ccr);
		`STW_RES8:	wb_write(res8[7:0]);
		`STW_RES16H:	wb_write(res16[15:8]);
		`STW_RES16L:	wb_write(res16[7:0]);
		`STW_DEF8:	wb_write(wdat);
		default:	wb_write(wdat);
		endcase
`ifdef SUPPORT_DCACHE
		radr <= wadr;		// Do a cache read to test the hit
`endif
		state <= STORE2;
	end
	
// Terminal state for stores. Update the data cache if there was a cache hit.
// Clear any previously set lock status
STORE2:
	if (ack_i) begin
		lock_o <= 1'b0;
		wdat <= dat_o;
		wadr <= wadr + 16'd1;
		case(store_what)
		`SW_CCR:	next_state(PUSH2);
		`SW_ACCA:
			if (isINT | isPSHS | isPSHU)
				next_state(PUSH2);
			else	// STA
				next_state(IFETCH);
		`SW_ACCB:
			if (isINT | isPSHS | isPSHU)
				next_state(PUSH2);
			else	// STB
				next_state(IFETCH);
		`SW_DPR:	next_state(PUSH2);
		`SW_XH:
			begin
				store_what <= `SW_XL;
				next_state(STORE1);
			end
		`SW_XL:
			if (isINT | isPSHS | isPSHU)
				next_state(PUSH2);
			else	// STX
				next_state(IFETCH);
		`SW_YH:
			begin
				store_what <= `SW_YL;
				next_state(STORE1);
			end
		`SW_YL:
			if (isINT | isPSHS | isPSHU)
				next_state(PUSH2);
			else	// STY
				next_state(IFETCH);
		`SW_USPH:
			begin
				store_what <= `SW_USPL;
				next_state(STORE1);
			end
		`SW_USPL:
			if (isINT | isPSHS | isPSHU)
				next_state(PUSH2);
			else	// STU
				next_state(IFETCH);
		`SW_SSPH:
			begin
				store_what <= `SW_SSPL;
				next_state(STORE1);
			end
		`SW_SSPL:
			if (isINT | isPSHS | isPSHU)
				next_state(PUSH2);
			else	// STS
				next_state(IFETCH);
		`SW_PCH:
			begin
				store_what <= `SW_PCL;
				wadr <= wadr + 16'd1;
				next_state(STORE1);
			end
		`SW_PCL:
			if (isINT | isPSHS | isPSHU)
				next_state(PUSH2);
			else begin	// JSR
				next_state(IFETCH);
				case(ir10)
				`BSR:	pc <= pc + {{8{ir[15]}},ir[15:8]};
				`LBSR:	pc <= pc + ir[23:8];
				`JSR_DP:	pc <= {dp,ir[15:8]};
				`JSR_EXT:	pc <= ir[23:8];
				`JSR_NDX:
					begin
						if (isIndirect) begin
							radr <= fnNdxAddr();
							load_what <= `LW_PCH;
							next_state(LOAD1);
						end
						else
							pc <= fnNdxAddr();
					end
				endcase
			end
		endcase
`ifdef SUPPORT_DCACHE
		if (!dhit && write_allocate) begin
			state <= DCACHE1;
		end
`endif
	end
`ifdef SUPPORT_BERR
	else if (err_i) begin
		lock_o <= 1'b0;
		wb_nack();
		state <= BUS_ERROR;
	end
`endif
