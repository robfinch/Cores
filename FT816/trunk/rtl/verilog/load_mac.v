// ============================================================================
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
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
			mlb <= 1'b1;
		if (isBrk)
			vpb <= `TRUE;
		data_read(radr);
		state <= LOAD_MAC2;
	end
`ifdef SUPPORT_DCACHE
	else if (dhit)
		load_tsk(rdat,rdat8,rdat16);
	else begin
		retstate <= LOAD_MAC1;
		state <= DCACHE1;
	end
`endif
LOAD_MAC2:
	if (rdy) begin
		data_nack();
`include "load_tsk.v"
//		load_tsk(db,b16);
	end
`ifdef SUPPORT_BERR
	else if (err_i) begin
		mlb <= 1'b0;
		data_nack();
		derr_address <= ado;
		intno <= 9'd508;
		state <= BUS_ERROR;
	end
`endif
RTS1:
	begin
		vpa <= `TRUE;
		vda <= `TRUE;
		pc <= pc + 24'd1;
		ado <= pc + 24'd1;
		next_state(IFETCH1);
	end
BYTE_IX5:
	begin
		isI24 <= `FALSE;
		radr <= ia;
		load_what <= m16 ? `HALF_70 : `BYTE_70;
		state <= LOAD_MAC1;
		if (ir[7:0]==`STA_IX || ir[7:0]==`STA_I || ir[7:0]==`STA_IL) begin
			wadr <= ia;
			store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
			state <= STORE1;
		end
		else if (ir[7:0]==`PEI) begin
			set_sp();
			store_what <= `STW_IA158;
			state <= STORE1;
		end
	end
BYTE_IY5:
	begin
		isIY <= `FALSE;
		isIY24 <= `FALSE;
		radr <= iapy8;
		wadr <= iapy8;
		store_what <= m16 ? `STW_ACC70 : `STW_ACC8;
		load_what <= m16 ? `HALF_70 : `BYTE_70;
		$display("IY addr: %h", iapy8);
		if (ir[7:0]==`STA_IY || ir[7:0]==`STA_IYL || ir[7:0]==`STA_DSPIY)
			state <= STORE1;
		else
			state <= LOAD_MAC1;
	end
