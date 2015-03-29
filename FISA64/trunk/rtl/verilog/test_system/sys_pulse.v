// ============================================================================
//        __
//   \\__/ o\    (C) 2015  Robert Finch, Stratford
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
module sys_pulse(rst, clk50, pulse1024Hz, pulse30Hza, pulse30Hzb);
parameter pClkFreq=50000000;
input rst;
input clk50;
output pulse1024Hz;
output pulse30Hza;
output pulse30Hzb;

// 1000Hz pulse generator
reg [19:0] cnt;
wire pulse1024 = cnt==pClkFreq/1024;
assign pulse1024Hz = cnt>=pClkFreq/1024-10;

always @(posedge clk50)
if (rst)
	cnt <= 20'd1;
else begin
	if (pulse1024)
		cnt <= 20'd1;
	else
		cnt <= cnt + 20'd1;
end

reg [31:0] cnt2;
wire pulse30a = cnt2==pClkFreq/30;
assign pulse30Hza = cnt2>=pClkFreq/30-10;
assign pulse30Hzb = (cnt2>=(pClkFreq/30)/2-10) && (cnt2 < (pClkFreq/30)/2) ;

always @(posedge clk50)
if (rst)
	cnt2 <= 32'd1;
else begin
	if (pulse30a)
		cnt2 <= 32'd1;
	else
		cnt2 <= cnt2 + 32'd1;
end
endmodule
