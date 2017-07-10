//=============================================================================
//	(C) 2006-2012  Robert Finch
//	All rights reserved.
//	robfinch@opencores.org
//
//	rolx16.v
//		Rotate or shift left by multiples of sixteen bits.
//
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
//=============================================================================
//
// rol 0,16,32 or 48 bits
module rolx16(op, a, b, o);
parameter DBW = 32;
localparam DMSB = DBW-1;
input op;
input [DMSB:0] a;
input [1:0] b;
output [DMSB:0] o;
reg [DMSB:0] o;

generate 
begin : g_rolx16
	if (DBW==8) begin
		wire [47:0] opx = {48{op}};
		always @(a or opx) 
			o <= a & opx[7:0];
	end
	else if (DBW==16) begin
		wire [47:0] opx = {48{op}};
		always @(a or opx) 
			o <= a & opx[15:0];
	end
	else if (DBW==32) begin
		wire [47:0] opx = {48{op}};
		always @(b or a or opx)
			case (b[0])
			1'd0:	o <= a;
			1'd1:	o <= {a[15:0],a[31:16]&opx[15:0]};
			endcase
	end
	else if (DBW==64) begin
		wire [47:0] opx = {48{op}};
		always @(b or a or opx)
			case (b[1:0])
			2'd0:	o <= a;
			2'd1:	o <= {a[47:0],a[63:48]&opx[15:0]};
			2'd2:	o <= {a[31:0],a[63:32]&opx[31:0]};
			2'd3:	o <= {a[15:0],a[63:16]&opx[47:0]};
			endcase
	end
end
endgenerate

endmodule
