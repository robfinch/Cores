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
	else if (dhit)
		load_tsk(rdat,rdat8);
	else begin
		retstate <= LOAD_MAC1;
		state <= DCACHE1;
	end
`endif
LOAD_MAC2:
	if (ack_i) begin
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		sel_o <= 4'h0;
		adr_o <= 34'h0;
		load_tsk(dat_i,dati);
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
