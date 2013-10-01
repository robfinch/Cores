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
`ifdef SUPPORT_STRING
MVN1:
	begin
		radr <= x;
		res <= x + 32'd1;
		retstate <= MVN2;
		load_what <= `WORD_312;
		state <= LOAD_MAC1;
	end
MVN2:
	begin
		radr <= y;
		wadr <= y;
		store_what <= `STW_B;
		x <= res;
		res <= y + 32'd1;
		acc <= acc - 32'd1;
		state <= STORE1;
	end
MVN3:
	begin
		state <= IFETCH;
		y <= res;
		if (acc==32'hFFFFFFFF)
			pc <= pc + 32'd1;
	end
MVP1:
	begin
		radr <= x;
		res <= x - 32'd1;
		retstate <= MVP2;
		load_what <= `WORD_312;
		state <= LOAD_MAC1;
	end
MVP2:
	begin
		radr <= y;
		wadr <= y;
		store_what <= `STW_B;
		x <= res;
		res <= y - 32'd1;
		acc <= acc - 32'd1;
		state <= STORE1;
	end
STS1:
	begin
		radr <= y;
		wadr <= y;
		store_what <= `STW_X;
		res <= y + 32'd1;
		acc <= acc - 32'd1;
		state <= STORE1;
	end
`endif
