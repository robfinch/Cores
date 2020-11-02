// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	posit.sv
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
package posit;

`define PSTWID 32

parameter PSTWID = `PSTWID;
localparam es =
  PSTWID >= 80 ? 4 :
  PSTWID >= 64 ? 3 :
  PSTWID >= 52 ? 3 :
  PSTWID >= 40 ? 3 :
  PSTWID >= 32 ? 2 :
  PSTWID >= 24 ? 2 :
  PSTWID >= 16 ? 1 :
  PSTWID >= 8 ? 1 :
  0 ;
localparam rs = $clog2(PSTWID-1);

endpackage
