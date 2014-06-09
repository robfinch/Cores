// ============================================================================
// Table887_sys.v
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
module Table887_sys(btn, clk, Led, sw);
input [5:0] btn;
input clk;
output [7:0] Led;
reg [7:0] Led;
input [7:0] sw;

wire xreset = ~btn[0];
reg [16:0] rommem [8191:0];
reg [15:0] rammem [511:0];
wire sys_cyc;
wire sys_stb;
wire sys_we;
wire [15:0] sys_adr;
wire [15:0] sys_dato;
reg [15:0] sys_dati;

initial begin
`include "..\..\software\asm\Thorasm\bin\test887.ver"
end

always @(posedge clk)
	if (sys_adr==16'hC600 && sys_we && sys_cyc)
		Led <= sys_dato[7:0];

always @(negedge clk)
	casex(sys_adr)
	16'b00xx_xxxx_xxxx_xxxx:	sys_dati <= rommem[sys_adr[13:1]];
	16'b0100_00xx_xxxx_xxxx:	sys_dati <= rammem[sys_adr[9:1]];
	16'b1100_0110_0000_0000:	sys_dati <= sw;
	endcase

always @(posedge clk)
	if (sys_cyc && sys_we && sys_adr[15:10]==6'b010000)
		rammem[sys_adr[9:1]] <= sys_dato;

Table887 u1
(
	.rst_i(xreset),
	.clk_i(clk),
	.cyc_o(sys_cyc),
	.stb_o(sys_stb),
	.ack_i(1'b1),
	.we_o(sys_we),
	.adr_o(sys_adr),
	.dat_i(sys_dati),
	.dat_o(sys_dato)
);

endmodule
