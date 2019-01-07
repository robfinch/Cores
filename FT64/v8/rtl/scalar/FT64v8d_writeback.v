// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64v8d_writeback.v
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
	if (rfwr) begin
		regfile[Rt] <= res;
		if (Rt==5'd31)
			sp[ol] <= res;
	end

	if (ccrfwr_all) begin
		case(ccRt)
		3'd0:	cc[7:0] <= ccres;
		3'd1:	cc[15:8] <= ccres;
		3'd2:	cc[23:16] <= ccres;
		3'd3:	cc[31:24] <= ccres;
		3'd4:	cc[39:32] <= ccres;
		3'd5:	cc[47:40] <= ccres;
		3'd6:	cc[55:48] <= ccres;
		3'd7:	cc[63:56] <= ccres;
		endcase
	end
	else if (ccrfwr_ponz) begin
		for (n = 0; n < 8; n = n + 1)
			if (ccRt==n) begin
				cc[n*8] <= ccres[0];
				cc[n*8+1] <= ccres[1];
				cc[n*8+4] <= ccres[4];
				cc[n*8+5] <= ccres[5];
			end
	end
