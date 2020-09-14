// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	Timeouter.sv
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

module Timeouter(rst_i, clk_i, dec_i, set_i, qry_i, pop_i, tid_i, timeout_i, timeout_o, zeros_o, qadr, done_o);
input rst_i;
input clk_i;
input dec_i;
input set_i;
input qry_i;
input pop_i;
input [4:0] tid_i;
input [31:0] timeout_i;
output reg [31:0] timeout_o;
output [7:0] zeros_o;
output [7:0] qadr;
output reg done_o;

reg [32:0] tmo [0:63];
reg [4:0] ndx;
reg [2:0] state;
parameter IDLE = 3'd0;
parameter DEC1 = 3'd1;
parameter SET1 = 3'd2;
parameter QRY1 = 3'd3;
parameter POPZ1 = 3'd4;

reg wrq, rdq;
reg [7:0] qin;
//vtdl #(8,64) uq1 (clk_i, wrq, qadr, qin, zeros_o);
ReadyFifo uqx (
  .clk(clk_i),                // input wire clk
  .srst(rst_i),              // input wire srst
  .din(qin),                // input wire [7 : 0] din
  .wr_en(wrq),            // input wire wr_en
  .rd_en(rdq),            // input wire rd_en
  .dout(zeros_o),              // output wire [7 : 0] dout
  .full(),              // output wire full
  .empty(qadr[6]),            // output wire empty
  .valid(qadr[7]),            // output wire valid
  .data_count(qadr[5:0])  // output wire [5 : 0] data_count
);

always @(posedge clk_i)
if (rst_i) begin
  qin <= 8'hFF;
  wrq <= 1'b0;
  rdq <= 1'b0;
	done_o <= 1'b1;
	goto (IDLE);
end
else begin
wrq <= 1'b0;
rdq <= 1'b0;
case(state)
IDLE:
	begin
		if (dec_i) begin
			ndx <= 5'd0;
			goto (DEC1);
		end
		else if (set_i) begin
			ndx <= tid_i;
			done_o <= 1'b0;
			goto (SET1);
		end
		else if (qry_i) begin
			ndx <= tid_i;
			done_o <= 1'b0;
			goto (QRY1);
		end
		else if (pop_i)
		  rdq <= 1'b1;
	end
DEC1:
	begin
		ndx <= ndx + 1;
		if (tmo[ndx][32]==1'b0) begin
 			tmo[ndx] <= tmo[ndx] - 2'd1;
  	  if (tmo[ndx][31:0] == 32'd0) begin
  		  wrq <= 1'b1;
  		  qin <= ndx;
  	  end
	  end
		if (ndx==5'd31)
			goto (IDLE);
	end
SET1:
	begin
		tmo[ndx] <= timeout_i;
		done_o <= 1'b1;
		goto (IDLE);
	end
QRY1:
	begin
		timeout_o <= tmo[ndx];
		done_o <= 1'b1;
		goto (IDLE);
	end
endcase
end

task goto;
input [2:0] nst;
begin
	state <= nst;
end
endtask

endmodule
