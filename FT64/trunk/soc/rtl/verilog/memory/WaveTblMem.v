`timescale 1ns / 1ps
//=============================================================================
// (C) 2012,2013 Robert Finch
//	All rights reserved.
//
// WaveTblMem.v
//	16 kiB wave table memory
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
//=============================================================================

module WaveTblMem(rst_i, clk_i, cs_i,
	cpu_cyc_i, cpu_stb_i, cpu_ack_o, cpu_we_i, cpu_adr_i, cpu_dat_i, cpu_dat_o,
	psg_adr_i, psg_dat_o
);
input rst_i;
input clk_i;
input cs_i;
input cpu_cyc_i;
input cpu_stb_i;
output cpu_ack_o;
input cpu_we_i;
input [14:0] cpu_adr_i;
input [15:0] cpu_dat_i;
output [15:0] cpu_dat_o;
reg [15:0] cpu_dat_o;

input [13:0] psg_adr_i;
output [11:0] psg_dat_o;
reg [11:0] psg_dat_o;

wire cs = cpu_cyc_i & cpu_stb_i & cs_i;

reg crdy1,crdy2;
always @(posedge clk_i)
begin
	crdy1 <= cs & !(crdy1|crdy2);
	crdy2 <= crdy1 & cs;
end
assign cpu_ack_o = cs ? (cpu_we_i ? 1'b1 : crdy2) : 1'b0;

reg [11:0] mem [0:8191];
reg [12:0] radrc,radrp;

always @(posedge clk_i)
	if (cs & cpu_we_i)
		mem[cpu_adr_i[14:2]] <= cpu_dat_i[15:4];

wire pe_stb,pe_pstb;
edge_det u1(.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(cpu_stb_i), .pe(pe_stb), .ne(), .ee() );

reg [12:0] ctr;
always @(posedge clk_i)
	if (pe_stb)
		ctr <= cpu_adr_i[14:2] + 13'd1;
	else
		ctr <= ctr + 13'd1;
always @(posedge clk_i)
	radrc <= pe_stb ? cpu_adr_i[14:2] : ctr;
always @(posedge clk_i)
	radrp <= psg_adr_i[13:1];
wire [11:0] cpu_d = mem[radrc];
wire [11:0] psg_d = mem[radrp];

always @(posedge clk_i)
    cpu_dat_o <= {cpu_d,4'h0};

always @(posedge clk_i)
	psg_dat_o <= psg_d;

endmodule
