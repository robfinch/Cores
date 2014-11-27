// ============================================================================
//        __
//   \\__/ o\    (C) 2013, 2014  Robert Finch, Stratford
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
// The store states work for 8, 16 or 32 bit mode              
// ============================================================================
//
// Stores always write through to memory, then optionally update the cache if
// there was a write hit.
STORE1:
	begin
		case(store_what)
		`STW_ACC8:	data_write(acc[7:0]);
		`STW_X8:	data_write(x[7:0]);
		`STW_Y8:	data_write(y[7:0]);
		`STW_Z8:	data_write(8'h00);
		
		`STW_PC2316:	data_write(pc[23:16]);
		`STW_PC158:		data_write(pc[15:8]);
		`STW_PC70:		data_write(pc[7:0]);
		`STW_SR70:		data_write(sr8);
		`STW_DEF8:		data_write(wdat);
		`STW_DEF70:		begin data_write(wdat); mlb <= 1'b1; end
		`STW_DEF158:	data_write(wdat[15:8]);
		`STW_ACC70:		begin data_write(acc); mlb <= 1'b1; end
		`STW_ACC158:	data_write(acc[15:8]);
		`STW_X70:		begin data_write(x); mlb <= 1'b1; end
		`STW_X158:		data_write(x[15:8]);
		`STW_Y70:		begin data_write(y); mlb <= 1'b1; end
		`STW_Y158:		data_write(y[15:8]);
		`STW_Z70:		begin data_write(8'h00); mlb <= 1'b1; end
		`STW_Z158:		data_write(8'h00);
		`STW_DBR:		data_write(dbr);
		`STW_DPR158:	begin data_write(dpr[15:8]); mlb<= 1'b1; end
		`STW_DPR70:		data_write(dpr);
		`STW_TMP158:	begin data_write(tmp16[15:8]); mlb <= 1'b1; end
		`STW_TMP70:		data_write(tmp16);
		`STW_IA158:		begin data_write(ia[15:8]); mlb <= 1'b1; end
		`STW_IA70:		data_write(ia);
		default:	data_write(wdat);
		endcase
`ifdef SUPPORT_DCACHE
		radr <= wadr;		// Do a cache read to test the hit
`endif
		state <= STORE2;
	end
	
// Terminal state for stores. Update the data cache if there was a cache hit.
// Clear any previously set lock status
STORE2:
	if (rdy) begin
//		wdat <= dat_o;
		mlb <= 1'b0;
		data_nack();
		if (!em && (isMove|isSts)) begin
			state <= MVN3;
			retstate <= MVN3;
		end
		else begin
			if (em) begin
				if (isMove) begin
					state <= MVN816;
					retstate <= MVN816;
				end
				else begin
					moveto_ifetch();
					retstate <= IFETCH1;
				end
			end
			else begin
				moveto_ifetch();
				retstate <= IFETCH1;
			end
		end
		case(store_what)
		`STW_DEF70:
			begin
				mlb <= 1'b1;
				wadr <= wadr + 24'd1;
				store_what <= `STW_DEF158;
				retstate <= STORE1;
				state <= STORE1;
			end
		`STW_ACC70:
			begin
				mlb <= 1'b1;
				wadr <= wadr + 24'd1;
				store_what <= `STW_ACC158;
				retstate <= STORE1;
				state <= STORE1;
			end
		`STW_X70:
			begin
				mlb <= 1'b1;
				wadr <= wadr + 24'd1;
				store_what <= `STW_X158;
				retstate <= STORE1;
				state <= STORE1;
			end
		`STW_Y70:
			begin
				mlb <= 1'b1;
				wadr <= wadr + 24'd1;
				store_what <= `STW_Y158;
				retstate <= STORE1;
				state <= STORE1;
			end
		`STW_Z70:
			begin
				mlb <= 1'b1;
				wadr <= wadr + 24'd1;
				store_what <= `STW_Z158;
				retstate <= STORE1;
				state <= STORE1;
			end
		`STW_DPR158:
			begin
				set_sp();
				store_what <= `STW_DPR70;
				retstate <= STORE1;
				state <= STORE1;
			end
		`STW_TMP158:
			begin
				set_sp();
				store_what <= `STW_TMP70;
				retstate <= STORE1;
				state <= STORE1;
			end
		`STW_IA158:
			begin
				set_sp();
				store_what <= `STW_IA70;
				retstate <= STORE1;
				state <= STORE1;
			end
		`STW_PC2316:
			begin
				if (ir9 != `PHK) begin
					set_sp();
					store_what <= `STW_PC158;
					retstate <= STORE1;
					state <= STORE1;
				end
			end
		`STW_PC158:
			begin
				set_sp();
				store_what <= `STW_PC70;
				retstate <= STORE1;
				state <= STORE1;
			end
		`STW_PC70:
			begin
				case({1'b0,ir[7:0]})
				`BRK,`COP:
						begin
						set_sp();
						store_what <= `STW_SR70;
						retstate <= STORE1;
						state <= STORE1;
						end
				`JSR: 	begin
						pc[15:0] <= ir[23:8];
						end
				`JSL: 	begin
						pc[23:0] <= ir[31:8];
						end
				`JSR_INDX:
						begin
						state <= LOAD_MAC1;
						retstate <= LOAD_MAC1;
						load_what <= `PC_70;
						radr <= absx_address;
						end
				endcase
			end
		`STW_SR70:
			begin
				if (ir[7:0]==`BRK) begin
					load_what <= `PC_70;
					state <= LOAD_MAC1;
					retstate <= LOAD_MAC1;
					pc[23:16] <= 8'h00;//abs8[23:16];
					radr <= vect;
					im <= hwi;
				end
				else if (ir[7:0]==`COP) begin
					load_what <= `PC_70;
					state <= LOAD_MAC1;
					retstate <= LOAD_MAC1;
					pc[23:16] <= 8'h00;//abs8[23:16];
					radr <= vect;
					im <= 1'b1;
				end
			end
		default:
			if (isJsrIndx) begin
				load_what <= `PC_310;
				state <= LOAD_MAC1;
				retstate <= LOAD_MAC1;
				radr <= ir[31:8] + x;
			end
			else if (isJsrInd) begin
				load_what <= `PC_310;
				state <= LOAD_MAC1;
				retstate <= LOAD_MAC1;
				radr <= ir[31:8];
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
		mlb <= 1'b0;
		data_nack();
		derr_address <= ado[23:0];
		intno <= 9'd508;
		state <= BUS_ERROR;
	end
`endif
