// Copyright 2006, 2007 Dennis van Weeren
//
// This file is part of Minimig
//
// Minimig is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// (at your option) any later version.
//
// Minimig is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//
//
// This is the Minimig boot rom
// The bootrom contains code for early startup of the Minimig.
// The bootrom will download the kickstart rom image trough the floppy 
// interface to the kickstart ram area. 
//
// 11-04-2005	- removed rd signal because it is no longer necessary
// 19-04-2005	- expanded to 2Kbyte address space
// 21-12-2005	- added rd input
// 27-11-2006	- rom now implemented using blockram
// ----------
//
// JB:
// 2008-05-14	- Verilog 2001 style module definition
// 2008-05-14	- new bootloader
// 2008-09-27	- FPGA core version updated & code clean-up
// 2009-05-24	- clean-up & renaming
// 2009-06-06	- adapted bootloader for firmware with high resolution OSD display
// 2009-09-11	- updated bootloader code
// 2009-12-17	- updated bootloader code
// 2009-12-24	- updated version number
// 2010-06-03	- updated version number
// 2010-07-28	- updated version number
// 2010-08-18	- updated version number
//
// RF:
// 2017-11-23	- use external verilog header file with ROM contents

module bootrom
(
	input 	clk,					// bus clock
	input 	aen,    				// rom enable
	input	rd,						// bus read
	input 	[10:1] address_in,		// address in
	output 	reg [15:0] data_out		// data out
);

reg	 	[10:1] romaddress;
reg		[15:0] rommem [1023:0];

// use clocked address to infer blockram
always @(negedge clk)
	romaddress[10:1] <= address_in[10:1];

// the rom itself
// FPGA core version is stored in words 4-7 as 8 ASCII characters 
// bytes:
// 0-1: vendor id (YQ for JB :-)
// 2-3: year
// 4-5: month
// 6-7: day

// if all goes well this rom will be implemented using blockram
initial begin
`include "..\BOOT68K\bootx.vh"
end

// output enable
always @*
	if (aen && rd) begin
       data_out = rommem[romaddress[10:1]][15:0];
    end
	else
		data_out = 16'h0000;

endmodule
