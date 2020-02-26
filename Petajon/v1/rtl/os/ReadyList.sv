// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
// ============================================================================
//
module ReadyList(rst_i, clk_i, insert_i, remove_i, get_i, qry_i, tid_i, priority_i, tid_o, done_o);
input rst_i;
input clk_i;
input insert_i;
input remove_i;
input get_i;
input qry_i;
input [5:0] tid_i;
input [2:0] priority_i;
output reg [15:0] tid_o;
output reg done_o;

reg [31:0] in_readylist;	// bitmap of tasks in ready list
reg [6:0] nxt [0:31];
reg [6:0] prv [0:31];
reg [5:0] head [0:4];
reg [5:0] headv;
reg [5:0] ndx;
reg [5:0] hd;
reg [6:0] pv;
reg [6:0] nx;

reg [3:0] state;
parameter IDLE = 4'd0;
parameter GET1 = 4'd1;
parameter INSERT0 = 4'd2;
parameter INSERT1 = 4'd3;
parameter INSERT2 = 4'd4;
parameter INSERT3 = 4'd5;
parameter REMOVE1 = 4'd6;
parameter REMOVE2 = 4'd7;
parameter REMOVE3 = 4'd8;
parameter QRY1 = 4'd9;
parameter REMOVE4 = 4'd10;

always @(posedge clk_i)
if (rst_i) begin
	done_o <= 1'b1;
	goto (IDLE);
end
else begin
case(state)
IDLE:
	begin
		if (get_i) begin
			if (!headv[priority_i])
				tid_o <= 16'hFFFF;
			else begin
				goto (GET1);
				done_o <= 1'b0;
			end
			ndx <= head[priority_i];
		end
		else if (insert_i) begin
			if (!in_readylist[tid_i])
				if (!headv[priority_i]) begin
					headv[priority_i] <= 1'b1;
					head[priority_i] <= tid_i;
					ndx <= tid_i;
					done_o <= 1'b0;
					goto (INSERT0);
				end
				else begin
					ndx <= head[priority_i];
					hd <= head[priority_i];
					done_o <= 1'b0;
					goto (INSERT1);
				end
		end		
		else if (remove_i) begin
			if (in_readylist[tid_i]) begin
				ndx <= tid_i;
				done_o <= 1'b0;
				goto (REMOVE1);
			end
		end
		else if (qry_i) begin
			ndx <= tid_i;
			done_o <= 1'b0;
			goto (QRY1);
		end
	end
GET1:
	begin
		head[priority_i] <= nxt[ndx];
		tid_o <= {10'd0,ndx};
		done_o <= 1'b1;
		goto (IDLE);
	end
INSERT0:
	begin
		prv[ndx] <= tid_i;
		nxt[ndx] <= tid_i;
		done_o <= 1'b1;
		goto(IDLE);
	end
INSERT1:
	begin
		ndx <= prv[ndx];
		pv <= prv[ndx];
		prv[ndx] <= tid_i;	// head->prev = tid
		goto (INSERT2);
	end
INSERT2:
	begin
		nxt[ndx] <= tid_i;	// head->prev->next = tid
		ndx <= tid_i;
		goto (INSERT3);
	end
INSERT3:
	begin
		nxt[ndx] <= hd;			// tid->next = head
		prv[ndx] <= pv;			// tid->prev = prev
		in_readylist[tid_i] <= 1'b1;
		done_o <= 1'b1;
		goto (IDLE);
	end
REMOVE1:
	begin
		nx <= nxt[ndx];
		pv <= prv[ndx];
		ndx <= nxt[ndx];
		goto (REMOVE2);
	end
REMOVE2:
	begin
		prv[ndx] <= pv;			// nxt->prev = tid->prev
		ndx <= pv;
		goto (REMOVE3);
	end
REMOVE3:
	begin
		nxt[ndx] <= nx;			// prev->next = tid->next
		if (tid_i==head[priority_i])
			head[priority_i] <= nx;
		in_readylist[tid_i] <= 1'b0;
		ndx <= tid_i;
		goto (REMOVE4);
	end
REMOVE4:
	begin
		nxt[ndx] <= 7'h7F;
		prv[ndx] <= 7'h7F;
		done_o <= 1'b1;
		goto (IDLE);
	end
QRY1:
	begin
		tid_o[7:0] <= {nxt[ndx][6],nxt[ndx][6],nxt[ndx]};
		tid_o[15:8] <= {prv[ndx][6],prv[ndx][6],prv[ndx]};
		done_o <= 1'b1;
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
