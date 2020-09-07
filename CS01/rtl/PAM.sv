// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	PAM.sv
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

module PAM(rst, clk, alloc_i, free_i, freeall_i, stat_i, pageno_i, val_i, pageno_o, done);
parameter BPW = 32;                   // bits per word in parallel
parameter RAMSIZE = 32768;            // sizeof block ram in bits
parameter PAMSIZE = 512;
localparam NWORD = RAMSIZE / BPW;     // sizeof block ram in bits / BPW
localparam NPAM = PAMSIZE / BPW;
parameter OSPAGEMAP = {BPW{1'b1}};
parameter FULLWORD = {BPW{1'b1}};
localparam LOGBPW = $clog2(BPW-1);
input rst;
input clk;
input alloc_i;
input free_i;
input freeall_i;
input stat_i;
input [1:0] val_i;
input [$clog2(NWORD-1)-1+LOGBPW:0] pageno_i;
output reg [$clog2(NWORD-1)-1+LOGBPW:0] pageno_o;
output reg done;

integer n;
(* ram_style="block" *)
reg [BPW-1:0] pam [0:NWORD-1];
reg [3:0] state;
reg [$clog2(NWORD-1)-1:0] wordno, curword;
reg [LOGBPW-1:0] bitno;
reg [BPW-1:0] map;
reg [$clog2(NWORD-1)-1:0] srchcnt;  // search counter

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
parameter STAT1 = 4'd10;
parameter STAT2 = 4'd11;
parameter STAT3 = 4'd12;

wire wr_pam = state==RESET || state==ALLOC4 || state==FREE3 || state==STAT3;
wire [31:0] pamo;

PAM_ram u1 (clk, wr_pam, wordno, map, wordno, pamo);

always @(posedge clk)
if (rst) begin
	done <= 1'b0;
	curword <= 4'd0;
	wordno <= 4'd0;
	srchcnt <= 4'd0;
	// Force pages to always be allocated already
	// First 32 pages allocated for the OS
  map <= {BPW{1'b1}};
	state <= RESET;
end
else begin
case (state)
IDLE:
	begin
		if (freeall_i) begin
		  srchcnt <= 4'd0;
		  curword <= 4'd0;
			wordno <= 4'd0;
			done <= 1'b0;
			map <= {BPW{1'b1}};
			goto (RESET);
		end
		else if (free_i) begin
			wordno <= pageno_i[$clog2(NWORD-1)-1+LOGBPW:LOGBPW];
			bitno <= pageno_i[LOGBPW-1:0];
			done <= 1'b0;
			goto (FREE1);
		end
		else if (alloc_i) begin
		  srchcnt <= 4'd0;
			wordno <= curword;
			done <= 1'b0;
			goto (ALLOC1);
		end
		else if (stat_i) begin
			wordno <= pageno_i[$clog2(NWORD-1)-1+LOGBPW:LOGBPW];
			bitno <= pageno_i[LOGBPW-1:0];
			done <= 1'b0;
			goto (STAT1);
	  end
	end
RESET:
	begin
		// Force last page allocated for system stack
		map <= {BPW{1'b0}};
		if (wordno==NPAM-2)
			map[BPW-1] <= 1'b1;
	  curword <= 2'd0;
		wordno <= wordno + 3'd1;
		srchcnt <= srchcnt + 3'd1;
		if (srchcnt==NPAM-1) begin
			done <= 1'b1;
			goto (IDLE);
		end
	end

ALLOC1:
	begin
		map <= pamo;
		goto (ALLOC2);
	end
ALLOC2:
	begin
		goto (ALLOC3);
		if (map==FULLWORD) begin
			wordno <= wordno + 2'd1;
			if (wordno==NPAM-1)
			  wordno <= 2'd0;
			srchcnt <= srchcnt + 2'd1;
			if (srchcnt==NPAM-1)
				goto (ALLOC5);
			else
				goto (ALLOC1);
		end
		for (n = 0; n < BPW; n = n + 1)
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
	  curword <= wordno;
		pageno_o <= {wordno,bitno};
		done <= 1'b1;
		goto (IDLE);
	end
ALLOC5:
	begin
		pageno_o <= 4'h0;
		done <= 1'b1;
		goto (IDLE);
	end

FREE1:
	begin
		map <= pamo;//pam[wordno];
		goto(FREE2);
	end
FREE2:
	begin
		map[bitno] <= 1'b0;
		goto(FREE3);
	end
FREE3:
	begin
		done <= 1'b1;
		goto (IDLE);
	end
	
STAT1:
  begin
    map <= pamo;
    goto (STAT2);
  end
STAT2:
  begin
    pageno_o <= map[bitno];
    if (!val_i[1])
      map[bitno] <= val_i[0];
    goto (STAT3);
  end
STAT3:
  begin
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

module PAM_ram(clk, wr, wa, i, ra, o);
input clk;
input wr;
input [9:0] wa;
input [31:0] i;
input [9:0] ra;
output [31:0] o;

(* ram_style="block" *)
reg [31:0] mem [0:1023];
reg [9:0] rra;

always @(posedge clk)
  if (wr)
    mem [wa] <= i;
always @(posedge clk)
  rra <= ra;
assign o = mem[rra];

endmodule
