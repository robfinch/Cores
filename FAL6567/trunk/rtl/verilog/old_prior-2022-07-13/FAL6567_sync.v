// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// FAL6567_sync.v
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
`define TRUE	1'b1
`define FALSE	1'b0

module FAL6567_sync(chip, rst, clk, turbo2, rasterX, rasterY, hSync, vSync, cSync);
parameter CHIP6567R8 = 2'd0;
parameter CHIP6567OLD = 2'd1;
parameter CHIP6569 = 2'd2;
parameter CHIP6572 = 2'd3;
input [1:0] chip;
input rst;
input clk;
input turbo2;
input [9:0] rasterX;
input [8:0] rasterY;
output reg hSync;
output reg vSync;
output reg cSync;

always @(posedge clk)
if (rst)
	vSync <= `FALSE;
else begin
	case(chip)
	CHIP6567R8,CHIP6567OLD:
		if (rasterY >= 3 && rasterY < 6)
			vSync <= `TRUE;
		else
			vSync <= `FALSE;
	CHIP6569,CHIP6572:
		if (rasterY >= 313 || rasterY < 3)
			vSync <= `TRUE;
		else
			vSync <= `FALSE;
	endcase
end

reg [9:0] hSyncWidth;
always @(posedge clk)
case(chip)
CHIP6567R8,CHIP6567OLD:
	hSyncWidth <= turbo2 ? 10'd49 : 10'd42;
CHIP6569,CHIP6572:
	hSyncWidth <= turbo2 ? 10'd45 : 10'd37;
endcase
always @(posedge clk)
begin
	hSync <= `FALSE;
	if (rasterX < hSyncWidth)	// 8%
		hSync <= `TRUE;
end

// Compute Equalization pulses
wire EQ, SE;
EqualizationPulse ueqp1
(
	.chip(chip),
	.turbo2(turbo2),
	.rasterX(rasterX),
	.EQ(EQ)
);

// Compute Serration pulses
SerrationPulse usep1
(
	.chip(chip),
	.turbo2(turbo2),
	.rasterX(rasterX),
	.SE(SE)
);

// Compute composite sync.
// sync is negative going
always @(posedge clk)
case(chip)
CHIP6567R8,CHIP6567OLD,
CHIP6569,CHIP6572:
	case(rasterY)
	9'd0:	cSync <= ~EQ;
	9'd1:	cSync <= ~EQ;
	9'd2:	cSync <= ~EQ;
	9'd3:	cSync <= ~SE;
	9'd4:	cSync <= ~SE;
	9'd5:	cSync <= ~SE;
	9'd6:	cSync <= ~EQ;
	9'd7:	cSync <= ~EQ;
	9'd8:	cSync <= ~EQ;
	default:
			cSync <= ~hSync;
	endcase
endcase

endmodule
