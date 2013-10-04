`timescale 1ns / 1ps
// ============================================================================
//  Sprite RAM
//
//	(C) 2005-2012  Robert Finch
//	robfinch<remove>@opencores.org
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

//`define VENDOR_ANY
`define VENDOR_XILINX
`define SPARTAN3

module rtfSpriteRam(
clka, adra, dia, doa, cea, wea, rsta,
clkb, adrb, dib, dob, ceb, web, rstb);
input clka;
input [10:1] adra;
input [15:0] dia;
output [15:0] doa;
input cea;				// clock enable a
input wea;
input rsta;
input clkb;
input [10:2] adrb;
input [31:0] dib;
output [31:0] dob;
input ceb;				// clock enable b
input web;
input rstb;

`ifdef VENDOR_XILINX

`ifdef SPARTAN3
	RAMB16_S18_S36 ram0(
		.CLKA(clka), .ADDRA(adra), .DIA(dia), .DIPA(2'b11), .DOA(doa), .ENA(cea), .WEA(wea), .SSRA(rsta),
		.CLKB(clkb), .ADDRB(adrb), .DIB(dib), .DIPB(4'b1111), .DOB(dob), .ENB(ceb), .WEB(web), .SSRB(rstb)  );
`endif
`ifdef SPARTAN6
	RAMB16_S18_S36 ram0(
		.CLKA(clka), .ADDRA(adra), .DIA(dia), .DIPA(2'b11), .DOA(doa), .ENA(cea), .WEA(wea), .SSRA(rsta),
		.CLKB(clkb), .ADDRB(adrb), .DIB(dib), .DIPB(4'b1111), .DOB(dob), .ENB(ceb), .WEB(web), .SSRB(rstb)  );
`endif
`endif

`ifdef VENDOR_ALTERA
`endif

`ifdef VENDOR_ANY

reg [15:0] memL [0:511];
reg [15:0] memH [0:511];
reg [10:1] radra;
reg [10:2] radrb;

// register read addresses
always @(posedge clka)
	if (cea)
		radra <= adra;
always @(posedge clkb)
	if (ceb)
		radrb <= adrb;


always @(posedge clkb)
	if (ceb)
		if (web) begin
			memL[adrb] <= dib[15: 0];
			memH[adrb] <= dib[31:16];
		end

assign doa = radra[1] ? memH[radra[10:2]] : memL[radra[10:2]];
assign dob = {memH[radrb],memL[radrb]};

`endif

endmodule
