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
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		we_o <= 1'b1;
		if (em || isStb) begin
			case(wadr2LSB)
			2'd0:	sel_o <= 4'b0001;
			2'd1:	sel_o <= 4'b0010;
			2'd2:	sel_o <= 4'b0100;
			2'd3:	sel_o <= 4'b1000;
			endcase
		end
		else
			sel_o <= 4'hf;
		adr_o <= {wadr,2'b00};
		case(store_what)
		`STW_ACC:	dat_o <= acc;
		`STW_X:		dat_o <= x;
		`STW_Y:		dat_o <= y;
		`STW_PC:	dat_o <= pc;
		`STW_PC2:	dat_o <= pc + 32'd2;
		`STW_PCHWI:	dat_o <= pc+{30'b0,~hwi,1'b0};
		`STW_OPC:	dat_o <= opc;
		`STW_SR:	dat_o <= sr;
		`STW_RFA:	dat_o <= rfoa;
		`STW_RFA8:	dat_o <= {4{rfoa[7:0]}};
		`STW_A:		dat_o <= a;
		`STW_B:		dat_o <= b;
		`STW_CALC:	dat_o <= calc_res;
`ifdef SUPPORT_EM8
		`STW_ACC8:	dat_o <= {4{acc8}};
		`STW_X8:	dat_o <= {4{x8}};
		`STW_Y8:	dat_o <= {4{y8}};
		`STW_Z8:	dat_o <= {4{8'h00}};
		`STW_PC3124:	dat_o <= {4{pc[31:24]}};
		`STW_PC2316:	dat_o <= {4{pc[23:16]}};
		`STW_PC158:		dat_o <= {4{pc[15:8]}};
		`STW_PC70:		dat_o <= {4{pc[7:0]}};
		`STW_SR70:		dat_o <= {4{sr8}};
`endif
		default:	dat_o <= wdat;
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
		wdat <= dat_o;
		if (isMove|isSts) begin
			state <= MVN3;
			retstate <= MVN3;
		end
		else begin
			if (em) begin
				state <= BYTE_IFETCH;
				retstate <= BYTE_IFETCH;
			end
			else begin
				state <= IFETCH;
				retstate <= IFETCH;
			end
		end
		lock_o <= 1'b0;
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		we_o <= 1'b0;
		sel_o <= 4'h0;
		adr_o <= 34'h0;
		dat_o <= 32'h0;
		case(store_what)
		`STW_PC,`STW_PC2,`STW_PCHWI,`STW_OPC:
			if (isBrk|isBusErr) begin
				radr <= isp_dec;
				wadr <= isp_dec;
				isp <= isp_dec;
				store_what <= `STW_SR;
				state <= STORE1;
				retstate <= STORE1;
			end
		`STW_SR:
			if (isBrk|isBusErr) begin
				load_what <= `PC_310;
				state <= LOAD_MAC1;
				retstate <= LOAD_MAC1;
				radr <= vect[31:2];
				ttrig <= 1'b0;
				tf <= 1'b0;			// turn off trace mode
				if (hwi)
					im <= 1'b1;
				em <= 1'b0;			// make sure we process in native mode; we might have been called up during emulation mode
			end
		`STW_RFA:
			if (isPusha) begin
				if (ir[11:8]==4'hF) begin
					state <= IFETCH;
					retstate <= IFETCH;
				end
				else begin
					state <= STORE1;
					retstate <= STORE1;
					radr <= isp_dec;
					wadr <= isp_dec;
					isp <= isp_dec;
				end
				ir[11:8] <= ir[11:8] + 4'd1;
			end
`ifdef SUPPORT_EM8
		`STW_PC3124:
			begin
				radr <= {spage[31:8],sp[7:2]};
				wadr <= {spage[31:8],sp[7:2]};
				radr2LSB <= sp[1:0];
				wadr2LSB <= sp[1:0];
				store_what <= `STW_PC2316;
				sp <= sp_dec;
				state <= STORE1;
			end
		`STW_PC2316:
			begin
				radr <= {spage[31:8],sp[7:2]};
				wadr <= {spage[31:8],sp[7:2]};
				radr2LSB <= sp[1:0];
				wadr2LSB <= sp[1:0];
				sp <= sp_dec;
				store_what <= `STW_PC158;
				state <= STORE1;
			end
		`STW_PC158:
			begin
				radr <= {spage[31:8],sp[7:2]};
				wadr <= {spage[31:8],sp[7:2]};
				radr2LSB <= sp[1:0];
				wadr2LSB <= sp[1:0];
				sp <= sp_dec;
				store_what <= `STW_PC70;
				state <= STORE1;
			end
		`STW_PC70:
			begin
				case(ir[7:0])
				`BRK: 	begin
						radr <= {spage[31:8],sp[7:2]};
						wadr <= {spage[31:8],sp[7:2]};
						radr2LSB <= sp[1:0];
						wadr2LSB <= sp[1:0];
						sp <= sp_dec;
						store_what <= `STW_SR70;
						state <= STORE1;
						end
				`JSR: 	begin
						pc <= ir[23:8];
						end
				`JSL: 	begin
						pc <= ir[39:8];
						end
				`JSR_INDX:
						begin
						state <= LOAD_MAC1;
						retstate <= LOAD_MAC1;
						load_what <= `PC_70;
						radr <= absx_address[31:2];
						radr2LSB <= absx_address[1:0];
						end
				endcase
			end
		`STW_SR70:
			begin
				if (ir[7:0]==`BRK) begin
					load_what <= `PC_70;
					state <= LOAD_MAC1;
					retstate <= LOAD_MAC1;
					pc[31:16] <= abs8[31:16];
					radr <= vect[31:2];
					radr2LSB <= vect[1:0];
					im <= hwi;
				end
			end
`endif
		default:
			if (isJsrIndx) begin
				load_what <= `PC_310;
				state <= LOAD_MAC1;
				retstate <= LOAD_MAC1;
				radr <= ir[39:8] + x;
			end
			else if (isJsrInd) begin
				load_what <= `PC_310;
				state <= LOAD_MAC1;
				retstate <= LOAD_MAC1;
				radr <= ir[39:8];
			end
		endcase
`ifdef SUPPORT_DCACHE
		if (!dhit && write_allocate) begin
			dmiss <= `TRUE;
			state <= WAIT_DHIT;
		end
`endif
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

	