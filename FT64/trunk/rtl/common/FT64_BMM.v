// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_BMM.v
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
module FT64_BMM(op,a,b,o);
parameter DBW=64;
parameter N=7;
input op;	// 0 = MOR, 1 = MXOR
input [DBW-1:0] a;
input [DBW-1:0] b;
output reg [DBW-1:0] o;

integer n,i,j;
reg omor[0:N][0:N];
reg omxor[0:N][0:N];
reg am[0:N][0:N];
reg bm[0:N][0:N];

always @*
for (i = 0; i <= N; i = i + 1) begin
	for (j = 0; j <= N; j = j + 1) begin
		am[i][j] = a[(N-i)*(N+1)+(N-j)];
		bm[i][j] = b[(N-i)*(N+1)+(N-j)];
	end
end

always @*
for (i = 0; i <= N; i = i + 1) begin
	for (j = 0; j <= N; j = j + 1) begin
		omor[i][j] =
				 (am[i][0]&bm[0][j])
				|(am[i][1]&bm[1][j])
				|(am[i][2]&bm[2][j])
				|(am[i][3]&bm[3][j])
				|(am[i][4]&bm[4][j])
				|(am[i][5]&bm[5][j])
				|(am[i][6]&bm[6][j])
				|(am[i][7]&bm[7][j]);
		omxor[i][j] =
				 (am[i][0]&bm[0][j])
				^(am[i][1]&bm[1][j])
				^(am[i][2]&bm[2][j])
				^(am[i][3]&bm[3][j])
				^(am[i][4]&bm[4][j])
				^(am[i][5]&bm[5][j])
				^(am[i][6]&bm[6][j])
				^(am[i][7]&bm[7][j]);
	end
end

always @*
case (op)
1'b0:	begin
		for (i = 0; i <= N; i = i + 1)
    		for (j = 0; j <= N; j = j + 1)
    			o[(N-i)*(N+1)+(N-j)] = omor[i][j];
    	end
1'b1:	begin
		for (i = 0; i <= N; i = i + 1)
    		for (j = 0; j <= N; j = j + 1)
    			o[(N-i)*(N+1)+(N-j)] = omxor[i][j];
    	end
endcase

endmodule
