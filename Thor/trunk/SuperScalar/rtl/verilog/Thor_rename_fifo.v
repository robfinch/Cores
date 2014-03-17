// ============================================================================
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
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
//
// Thor Register Rename Fifo
//
// ============================================================================
//
module Thor_rename_fifo(clk,push2,push1,pop2,pop1,wi0, wi1, wo0, wo1);
parameter PREG = 128;
input clk;
input push2;
input push1;
input pop2;
input pop1;
input [6:0] wi0;
input [6:0] wi1;
output [6:0] wo0;
output [6:0] wo1;

integer n;
reg [6:0] mem [PREG-1:0];

initial begin
	for (n = 0; n < PREG; n = n + 1)
		mem[n] <= n + 1;
end

always @(posedge clk)
casex ({push2,push1,pop2,pop1})
4'b0000:	;	// do nothing
4'b0001:	// pop 1
	begin
		wo0 <= mem[0];
		wo1 <= mem[0];
		for (n = 0; n < PREG-1; n = n + 1)
			mem[n] <= mem[n+1];
	end
4'b0010:	// pop 2
4'b0011:	// pop 1 and pop2
	begin
		wo0 <= mem[0];
		wo1 <= mem[1];
		for (n = 0; n < PREG-2; n = n + 1)
			mem[n] <= mem[n+2];
	end
4'b0100:	// push 1
	begin
		for (n = 0; n < PREG-1; n = n + 1)
			mem[n+1] <= mem[n];
		mem[0] <= wi0;
	end
4'b0101:	// push1, pop1
	begin
		wo0 <= wi0;
		wo1 <= wi0;
	end
4'b0110:	// push 1, pop2 = pop1
4'b0111:
	begin
		wo0 <= wi0;
		wo1 <= mem[0];
		for (n = 0; n < PREG-1; n = n + 1)
			mem[n] <= mem[n+1];
	end
4'b1000:
	begin
		for (n = 0; n < PREG-1; n = n + 1)
			mem[n+2] <= mem[n];
		mem[0] <= wi0;
		mem[1] <= wi1;
	end
// push2, pop1 = push1
4'b1001:
	begin
		for (n = 0; n < PREG-1; n = n + 1)
			mem[n+1] <= mem[n];
		mem[0] <= wi1;
		wo0 <= wi0;
		wo1 <= wi0;
	end
4'b1x1x:
	begin
		wo0 <= wi0;
		wo1 <= wi1;
	end
endcase

endmodule
