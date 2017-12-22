// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	cam.v
//  CAM primitives
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
//
// The cam is implemented as two memories. The first memory is the data memory
// which is used to store the data as per usual. The second memory is a bitmap
// of which memory locations the data is stored in.
// Because two memories are used writing is a two step process. First the
// bit of where the old data is stored must be updated by clearing it for old
// data. Next the bitmap of the data storage is set for the new data.
// ============================================================================
//
module cam6x32(clk, we, wr_addr, din, cmp_din, match_addr, match);
input clk;
input we;
input [4:0] wr_addr;
input [5:0] din;
input [5:0] cmp_din;
output [31:0] match_addr;
output match;

reg [31:0] bmem [0:63];
reg [5:0] dmem [0:31];
reg [5:0] din2;

integer n;
initial begin
    for (n = 0; n < 64; n = n + 1)
        bmem[n] = 0;
    for (n = 0; n < 32; n = n + 1)
        dmem[n] = 0;
end

reg we2;
wire [5:0] madr = (we2|we) ? dmem[wr_addr] : cmp_din;

always @(posedge clk)
    din2 <= din;
always @(posedge clk)
    we2 <= we;

always @(posedge clk)
    if (we & ~we2)
        bmem[madr] <= bmem[madr] & ~(32'd1 << wr_addr);
    else if (we2 & ~we)
        bmem[madr] <= bmem[madr] | (32'd1 << wr_addr);

always @(posedge clk)
    if (we)
        dmem[wr_addr] <= din2;

assign match_addr = bmem[madr];
assign match = |match_addr;

endmodule

// Write six bits of data to one of 64 addresses
 
module cam6x64(clk, we, wr_addr, din, cmp_din, match_addr, match);
input clk;
input we;
input [5:0] wr_addr;
input [5:0] din;
input [5:0] cmp_din;
output [63:0] match_addr;
output match;

reg [63:0] bmem [0:63];
reg [5:0] dmem [0:63];
reg [5:0] din2;

integer n;
initial begin
    for (n = 0; n < 64; n = n + 1)
        bmem[n] = 0;
    for (n = 0; n < 64; n = n + 1)
        dmem[n] = 0;
end

reg we2;
wire [5:0] madr = (we2 & ~we) ? din2 : we ? dmem[wr_addr] : cmp_din;

always @(posedge clk)
    din2 <= din;
always @(posedge clk)
    we2 <= we;

// This looks like it might be updating the same address during we and we2 ubt
// bmem[adr] actually likely changes inbetween the write pulses due to an
// update of dmem[wr_addr].
always @(posedge clk)
    if (we & ~we2)
        bmem[madr] <= bmem[madr] & ~(64'd1 << wr_addr);
    else if (we2 & ~we)
        bmem[madr] <= bmem[madr] | (64'd1 << wr_addr);

always @(posedge clk)
    if (we2 & ~we)
        dmem[wr_addr] <= din2;

assign match_addr = bmem[madr];
assign match = |match_addr;

endmodule

module cam36x32(clk, we, wr_addr, din, cmp_din, match_addr, match);
input clk;
input we;
input [4:0] wr_addr;
input [35:0] din;
input [35:0] cmp_din;
output [31:0] match_addr;
output match;

wire [31:0] match_addr0, match_addr1, match_addr2, match_addr3, match_addr4, match_addr5;
wire [31:0] match_addr = match_addr0 & match_addr1 & match_addr2 & match_addr3 & match_addr4 & match_addr5;

DSD9_cam6x32 u1 (clk, we, wr_addr, din[ 5: 0], cmp_din[ 5: 0], match_addr0);
DSD9_cam6x32 u2 (clk, we, wr_addr, din[11: 6], cmp_din[11: 6], match_addr1);
DSD9_cam6x32 u3 (clk, we, wr_addr, din[17:12], cmp_din[17:12], match_addr2);
DSD9_cam6x32 u4 (clk, we, wr_addr, din[23:18], cmp_din[23:18], match_addr3);
DSD9_cam6x32 u5 (clk, we, wr_addr, din[29:24], cmp_din[29:24], match_addr4);
DSD9_cam6x32 u6 (clk, we, wr_addr, din[35:30], cmp_din[35:30], match_addr5);

assign match = |match_addr;

endmodule

module cam36x64(clk, we, wr_addr, din, cmp_din, match_addr, match);
input clk;
input we;
input [5:0] wr_addr;
input [35:0] din;
input [35:0] cmp_din;
output [63:0] match_addr;
output match;

wire [63:0] match_addr0, match_addr1, match_addr2, match_addr3, match_addr4, match_addr5;
wire [63:0] match_addr = match_addr0 & match_addr1 & match_addr2 & match_addr3 & match_addr4 & match_addr5;

cam6x64 u1 (clk, we, wr_addr, din[ 5: 0], cmp_din[ 5: 0], match_addr0);
cam6x64 u2 (clk, we, wr_addr, din[11: 6], cmp_din[11: 6], match_addr1);
cam6x64 u3 (clk, we, wr_addr, din[17:12], cmp_din[17:12], match_addr2);
cam6x64 u4 (clk, we, wr_addr, din[23:18], cmp_din[23:18], match_addr3);
cam6x64 u5 (clk, we, wr_addr, din[29:24], cmp_din[29:24], match_addr4);
cam6x64 u6 (clk, we, wr_addr, din[35:30], cmp_din[35:30], match_addr5);

assign match = |match_addr;

endmodule
