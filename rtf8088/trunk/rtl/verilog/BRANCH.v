//============================================================================
//  BRANCH.v
//  Jcc disp8
//  - conditional branches
//  - fetch an 8 bit displacement and add into IP
//
//
//  (C) 2009-2012 Robert Finch
//  Stratford
//  robfinch<remove>@opencores.org
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
//=============================================================================
//
// Fetch branch displacement if taking branch, otherwise skip
//
BRANCH1:
	if (take_br) begin
		`INITIATE_CODE_READ
		state <= BRANCH2;
	end
	else begin
		ip <= ip_inc;
		state <= IFETCH;
	end
BRANCH2:
	if (ack_i) begin
		`TERMINATE_CODE_READ
		disp16 <= {{8{dat_i[7]}},dat_i};
		state <= BRANCH3;
	end
BRANCH3:
	begin
		ip <= ip + disp16;
		state <= IFETCH;
	end
