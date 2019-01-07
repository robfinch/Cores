// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64v8d_push.v
//		
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
//
// ============================================================================
//
PUSH:
	begin
		cyc_o <= `HIGH;
		stb_o <= `HIGH;
		we_o <= `HIGH;
		sel_o <= 8'hFF;
		adr_o <= {data_base,13'd0} + sp[ol] - 64'd8;
		dat_o <= b;
		goto (PUSH1);
	end
PUSH1:
	if (ack_i) begin
		cyc_o <= `LOW;
		stb_o <= `LOW;
		we_o <= `LOW;
		sel_o <= 8'h00;
		sp[ol] <= sp[ol] - 64'd8;
		ret();
	end
