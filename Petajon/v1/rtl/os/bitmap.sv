// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	bitmap.sv
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

module bitmap(rst, clk, set_i, clear_i, clearall_i, bitno_i, bitno_o, done);
input rst;
input clk;
input set_i;
input clear_i;
input clearall_i;
input [13:0] bitno_i;
output reg [13:0] bitno_o;
output reg done;

integer n;
reg [63:0] pam [0:255];
reg [3:0] state;
reg [7:0] wordno;
reg [5:0] bitno;
reg [63:0] map;

parameter IDLE = 4'd0;
parameter ALLOC1 = 4'd1;
parameter ALLOC2 = 4'd2;
parameter ALLOC3 = 4'd3;
parameter ALLOC4 = 4'd4;
parameter ALLOC5 = 4'd5;
parameter FREE1 = 4'd6;
parameter FREE2 = 4'd7;
parameter FREE3 = 4'd8;
parameter RESET = 4'd9;
parameter ALLOC0 = 4'd10;

always @(posedge clk)
if (rst) begin
	done <= 1'b0;
	wordno <= 8'd0;
	state <= RESET;
end
else begin
case (state)
IDLE:
	begin
		if (clearall_i) begin
			wordno <= 8'd0;
			done <= 1'b0;
			goto (RESET);
		end
		else if (clear_i) begin
			wordno <= bitno_i[13:6];
			bitno <= bitno_i[5:0];
			done <= 1'b0;
			goto (FREE1);
		end
		else if (set_i) begin
			wordno <= bitno_i[13:6];
			bitno <= bitno_i[5:0];
			done <= 1'b0;
			goto (bitno_i==14'h0 ? ALLOC1 : ALLOC0);
		end
	end
RESET:
	begin
		pam[wordno] <= 64'h0;
		wordno <= wordno + 2'd1;
		if (wordno==8'd255) begin
			done <= 1'b1;
			goto (IDLE);
		end
	end

ALLOC0:
	begin
		map <= pam[wordno];
		goto (ALLOC3);
	end
ALLOC1:
	begin
		map <= pam[wordno];
		goto (ALLOC2);
	end
ALLOC2:
	begin
		goto (ALLOC3);
		if (map==64'hFFFFFFFFFFFFFFFF) begin
			wordno <= wordno + 2'd1;
			if (wordno==8'd127)
				goto (ALLOC5);
			else
				goto (ALLOC1);
		end
		for (n = 63; n >= 0; n = n - 1)
			if (map[n]==1'b0)
				bitno <= n;
	end
ALLOC3:
	begin
		map[bitno] <= 1'b1;
		goto (ALLOC4);
	end
ALLOC4:
	begin
		pam[wordno] <= map;
		bitno_o <= {wordno,bitno};
		done <= 1'b1;
		goto (IDLE);
	end
ALLOC5:
	begin
		bitno_o <= 13'h000;
		done <= 1'b1;
		goto (IDLE);
	end

FREE1:
	begin
		map <= pam[wordno];
		goto(FREE2);
	end
FREE2:
	begin
		map[bitno] <= 1'b0;
		goto(FREE3);
	end
FREE3:
	begin
		pam[wordno] <= map;
		done <= 1'b1;
		goto (IDLE);
	end
endcase
	
end

task goto;
input [3:0] nst;
begin
	state <= nst;
end
endtask

endmodule
