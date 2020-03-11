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
`define IOF_INSERT	7'd16
`define IOF_REMOVE	7'd17
`define IOF_GETNXT	7'd18
`define IOF_GETPRV	7'd19

module IOFocusList(rst_i, clk_i, cmd_i, tid_i, tid_o, done_o);
input rst_i;
input clk_i;
input [6:0] cmd_i;
input [5:0] tid_i;
output reg [6:0] tid_o;
output reg done_o;

reg [63:0] in_focuslist;	// bitmap of tasks in ready list
reg [5:0] tid [0:63];
reg [5:0] nxt [0:63];
reg [5:0] prv [0:63];
reg [5:0] head;
reg headv;
reg [5:0] ndx;
reg [5:0] hd;
reg [5:0] pv;
reg [5:0] nx;

reg [3:0] state;
parameter IDLE = 4'd0;
parameter GETNXT1 = 4'd1;
parameter INSERT0 = 4'd2;
parameter INSERT1 = 4'd3;
parameter INSERT2 = 4'd4;
parameter INSERT3 = 4'd5;
parameter REMOVE1 = 4'd6;
parameter REMOVE2 = 4'd7;
parameter REMOVE3 = 4'd8;
parameter GETPRV1 = 4'd9;

always @(posedge clk_i)
if (rst_i) begin
	done_o <= 1'b1;
	goto (IDLE);
end
else begin
case(state)
IDLE:
	begin
		case(cmd_i)
		`IOF_GETNXT:
			begin
				if (!headv)
					tid_o <= 7'h7F;
				else begin
					goto (GETNXT1);
					done_o <= 1'b0;
				end
				ndx <= head;
			end
		`IOF_GETPRV:
			begin
				if (!headv)
					tid_o <= 7'h7F;
				else begin
					goto (GETPRV1);
					done_o <= 1'b0;
				end
				ndx <= head;
			end
		`IOF_INSERT:
			begin
				if (!in_focuslist[tid_i])
					if (!headv) begin
						headv <= 1'b1;
						head <= tid_i;
						ndx <= tid_i;
						done_o <= 1'b0;
						goto (INSERT0);
					end
					else begin
						ndx <= head;
						hd <= head;
						done_o <= 1'b0;
						goto (INSERT1);
					end
			end		
		`IOF_REMOVE:
			begin
				if (in_focuslist[tid_i]) begin
					ndx <= tid_i;
					done_o <= 1'b0;
					goto (REMOVE1);
				end
			end
		endcase
	end
GETNXT1:
	begin
		head <= nxt[ndx];
		tid_o <= nxt[ndx];
		done_o <= 1'b1;
		goto (IDLE);
	end
GETPRV1:
	begin
		head <= prv[ndx];
		tid_o <= prv[ndx];
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
		in_focuslist[tid_i] <= 1'b1;
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
		if (tid_i==head)
			tid_o <= 7'd1;
		else
			tid_o <= 7'd0;
//			head <= nx;
		done_o <= 1'b1;
		in_focuslist[tid_i] <= 1'b0;
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
