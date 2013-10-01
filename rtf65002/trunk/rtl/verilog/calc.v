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
// Extra state required for some datapath operations.                       
// ============================================================================
//
CALC:
	begin
		state <= IFETCH;
		res <= calc_res;
		wadr <= radr; 			// These two lines for the shift/inc/dec ops
		store_what <= `STW_CALC;
		case(ir9)
		`ASL_ZPX,`ASL_ABS,`ASL_ABSX,
		`ROL_ZPX,`ROL_ABS,`ROL_ABSX,
		`LSR_ZPX,`LSR_ABS,`LSR_ABSX,
		`ROR_ZPX,`ROR_ABS,`ROR_ABSX,
		`INC_ZPX,`INC_ABS,`INC_ABSX,
		`DEC_ZPX,`DEC_ABS,`DEC_ABSX:
			state <= STORE1;
		endcase
	end
