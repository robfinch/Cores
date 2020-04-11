// ============================================================================
//        __
//   \\__/ o\    (C) 2019-2020  Robert Finch, Waterloo
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
// Check how many instructions can be queued. This might be fewer than the
// number ready to queue from the fetch stage if queue slots aren't
// available or if there are no more physical registers left for remapping.
// The fetch stage needs to know how many instructions will queue so this
// logic is placed here.
// For the VEX instruction, the instruction can't queue until register Rs1
// is valid, because register Rs1 is used to specify the vector element to
// read.
//
// ============================================================================
//
`include "..\inc\Gambit-config.sv"
`include "..\inc\Gambit-defines.sv"
`include "..\inc\Gambit-types.sv"

module getQueuedCount(rst, clk, ce, branchmiss,
  decbufv0, decbufv1,
  brk, tails, rob_tails, slotvd,
	slot_jmp, take_branch, iqs_v, rob_v, queuedCnt, queuedCntNzp, queuedCntd1,
	queuedCntd2, queuedOnp, queuedOn);
parameter IQ_ENTRIES = `IQ_ENTRIES;
parameter QSLOTS = `QSLOTS;
parameter RENTRIES = `RENTRIES;
parameter RSLOTS = `RSLOTS;
input rst;
input clk;
input ce;
input branchmiss;
input decbufv0;
input decbufv1;
input [QSLOTS-1:0] brk;
input Qid tails [0:QSLOTS*2-1];
input Rid rob_tails [0:RSLOTS*2-1];
input [QSLOTS-1:0] slotvd;
input [QSLOTS-1:0] slot_jmp;
input [QSLOTS-1:0] take_branch;
input [IQ_ENTRIES-1:0] iqs_v;
input [RENTRIES-1:0] rob_v;
output reg [2:0] queuedCnt;
output reg queuedCntNzp;							// queued count is non-zero
output reg [2:0] queuedCntd1;
output reg [2:0] queuedCntd2;
output reg [QSLOTS-1:0] queuedOnp;
output reg [QSLOTS-1:0] queuedOn;

wire fourEmpty = iqs_v[tails[0]]==`INV && iqs_v[tails[1]]==`INV
 						    && iqs_v[tails[2]]==`INV && iqs_v[tails[3]]==`INV;
wire oneEmpty = iqs_v[tails[0]]==`INV;
wire twoEmpty = iqs_v[tails[0]]==`INV && iqs_v[tails[1]]==`INV;

always @*
begin
	queuedCnt = 3'd0;
	queuedOnp = 2'd0;
	queuedCntNzp = 1'b0;
	if (!branchmiss) begin
    if (twoEmpty) begin
      queuedCnt = decbufv0|decbufv1;
      queuedOnp[0] = decbufv0;
      queuedCntNzp = 1'b1;
      if (decbufv1 && ((take_branch[0]==1'b0 && slot_jmp[0]==1'b0 && brk[0]==1'b0) || !decbufv0)) begin
        if (`WAYS > 1) begin
        	queuedCnt = decbufv0 ? 3'd2 : 3'd1;
	        queuedOnp[1] = decbufv1;
	      end
      end
  	end
  end
end

always @(posedge clk)
if (rst) begin
	queuedCntd1 <= 3'd0;
	queuedCntd2 <= 3'd0;
	queuedOn <= 2'b00;
end
else begin
	queuedCntd2 <= queuedCntd1;
	if (ce) begin
		queuedOn <= queuedOnp;
  	queuedCntd1 <= queuedCnt;
	end
end

endmodule
