// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	ReadyQueues.sv
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

module ReadyQueues(rst_i, clk_i, insert_i, remove_i, tid_i, priority_i, tid_o);
parameter NQ = 8;
input rst_i;
input clk_i;
input insert_i;
input remove_i;
input [7:0] tid_i;
input [2:0] priority_i;
output reg [15:0] tid_o;

reg [NQ-1:0] wrq, rdq;
wire [7:0] tid [0:NQ-1];
wire [5:0] data_count [0:NQ-1];
wire [NQ-1:0] empty;
wire [NQ-1:0] valid;
integer n;
genvar g;
generate begin : ques
for (g = 0; g < NQ; g = g + 1)
//  vtdl #(8,64) uq1 (clk_i, wrq[g], qndx[g], tid_i, tid[g]);
ReadyFifo uqx (
  .clk(clk_i),                // input wire clk
  .srst(rst_i),              // input wire srst
  .din(tid_i),                // input wire [7 : 0] din
  .wr_en(wrq[g]),            // input wire wr_en
  .rd_en(rdq[g]),            // input wire rd_en
  .dout(tid[g]),              // output wire [7 : 0] dout
  .full(),              // output wire full
  .empty(empty[g]),            // output wire empty
  .valid(valid[g]),            // output wire valid
  .data_count(data_count[g])  // output wire [5 : 0] data_count
);
end
endgenerate

always @(posedge clk_i)
begin
	for (n = 0; n < NQ; n = n + 1) 
		rdq[n] <= 1'b0;
	for (n = 0; n < NQ; n = n + 1) 
		wrq[n] <= 1'b0;
	if (remove_i) begin
	  rdq[priority_i] <= 1'b1;
		tid_o <= {valid[priority_i],empty[priority_i],data_count[priority_i],tid[priority_i]};
	end
	else if (insert_i)
		wrq[priority_i] <= 1'b1;
end

endmodule
