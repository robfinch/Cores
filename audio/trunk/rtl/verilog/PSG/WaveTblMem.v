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

module WaveTblMem(rst_i, clk_i,
	cpu_cyc_i, cpu_stb_i, cpu_ack_o, cpu_we_i, cpu_adr_i, cpu_dat_i, cpu_dat_o,
	psg_cyc_i, psg_stb_i, psg_ack_o, psg_adr_i, psg_dat_o
);
input rst_i;
input clk_i;
input cpu_cyc_i;
input cpu_stb_i;
output cpu_ack_o;
input cpu_we_i;
input [33:0] cpu_adr_i;
input [15:0] cpu_dat_i;
output [15:0] cpu_dat_o;
reg [15:0] cpu_dat_o;

input psg_cyc_i;
input psg_stb_i;
output psg_ack_o;
input [14:0] psg_adr_i;
output [11:0] psg_dat_o;
reg [11:0] psg_dat_o;

wire cs = cpu_cyc_i && cpu_stb_i && (cpu_adr_i[33:18]==16'hFFD6);
wire pcs = psg_cyc_i && psg_stb_i;

reg crdy1,crdy2,prdy1,prdy2;
always @(posedge clk_i)
begin
	crdy1 <= cs & !(crdy1|crdy2);
	crdy2 <= crdy1 & cs;
	prdy1 <= pcs & !(prdy1|prdy2);
	prdy2 <= prdy1 & pcs;
end
assign cpu_ack_o = cs ? (cpu_we_i ? 1'b1 : crdy2) : 1'b0;
assign psg_ack_o = pcs ? prdy2 : 1'b0;

reg [11:0] mem [0:8191];
reg [14:2] radrc,radrp;

always @(posedge clk_i)
	if (cs & cpu_we_i)
		mem[cpu_adr_i[14:2]] <= cpu_dat_i[15:4];

wire pe_stb,pe_pstb;
edge_det u1(.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(cpu_stb_i), .pe(pe_stb), .ne(), .ee() );
edge_det u2(.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(psg_stb_i), .pe(pe_pstb), .ne(), .ee() );

reg [14:2] ctr,pctr;
always @(posedge clk_i)
	if (pe_stb)
		ctr <= cpu_adr_i[14:2] + 13'd1;
	else
		ctr <= ctr + 13'd1;
always @(posedge clk_i)
	if (pe_pstb)
		pctr <= psg_adr_i[14:2] + 13'd1;
	else
		pctr <= pctr + 13'd1;

always @(posedge clk_i)
	radrc <= pe_stb ? cpu_adr_i[14:2] : ctr;
always @(posedge clk_i)
	radrp <= pe_pstb ? psg_adr_i[14:2] : pctr;
wire [11:0] cpu_d = mem[radrc];
wire [11:0] psg_d = mem[radrp];

always @(posedge clk_i)
	if (cs)
		cpu_dat_o <= {cpu_d,4'h0};
	else
		cpu_dat_o <= 16'h0000;

always @(posedge clk_i)
	psg_dat_o <= psg_d;

endmodule
