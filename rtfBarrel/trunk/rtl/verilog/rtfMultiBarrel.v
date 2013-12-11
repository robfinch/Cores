// ============================================================================
//        __
//   \\__/ o\    (C) 2013  Robert Finch, Stratford
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
//
// ============================================================================
//
module rtfMultiBarrel(rst_i, clk_i, bte_o, cti_o, cyc_o, stb_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o);
parameter NCPUS = 8;
input rst_i;
input clk_i;
output reg [1:0] bte_o;
output reg [2:0] cti_o;
output reg cyc_o;
output reg stb_o;
input ack_i;
output reg we_o;
output reg [3:0] sel_o;
output reg [31:0] adr_o;
input [31:0] dat_i;
output reg [31:0] dat_o;

wire [1:0] bte [NCPUS-1:0];
wire [2:0] cti [NCPUS-1:0];
wire [NCPUS-1:0] cyc;
wire [NCPUS-1:0] stb;
reg [NCPUS-1:0] ack;
wire [NCPUS-1:0] we;
wire [3:0] sel [NCPUS-1:0];
wire [31:0] adr [NCPUS-1:0];
reg [31:0] dati [NCPUS-1:0];
wire [31:0] dato [NCPUS-1:0];

reg [2:0] which;
reg cyco;

genvar g;
generate
begin

for (g = 0; g < NCPUS; g = g + 1)
begin : skid
	rtfBarrel ug
	(
		.rst_i(rst_i),
		.clk_i(clk_i),
		.bte_o(bte[g]),
		.cti_o(cti[g]),
		.cyc_o(cyc[g]),
		.stb_o(stb[g]),
		.ack_i(ack[g]),
		.we_o(we[g]),
		.sel_o(sel[g]),
		.adr_o(adr[g]),
		.dat_o(dato[g]),
		.dat_i(dati[g])
	);
end
end
endgenerate

always @(which or ack_i)
begin
	bte_o <= bte[which];
	cti_o <= cti[which];
	cyc_o <= cyc[which];
	stb_o <= stb[which];
	we_o <= we[which];
	sel_o <= sel[which];
	adr_o <= adr[which];
	dat_o <= dato[which];
	ack[0] <= 1'b0;
	ack[1] <= 1'b0;
	ack[2] <= 1'b0;
	ack[3] <= 1'b0;
	ack[4] <= 1'b0;
	ack[5] <= 1'b0;
	ack[6] <= 1'b0;
	ack[7] <= 1'b0;
	ack[which] <= ack_i;
	dati[0] <= 32'd0;
	dati[1] <= 32'd0;
	dati[2] <= 32'd0;
	dati[3] <= 32'd0;
	dati[4] <= 32'd0;
	dati[5] <= 32'd0;
	dati[6] <= 32'd0;
	dati[7] <= 32'd0;
	dati[which] <= dat_i;
end

always @(posedge clk_i)
if (rst_i)
	cyco <= 1'b0;
else
	cyco <= cyc_o;

always @(posedge clk_i)
if (rst_i)
	which <= 3'd0;
else begin
	if (!cyc_o & cyco) begin
		which <= which + 3'd1;
		if (!cyc[which+3'd1])
			which <= which + 3'd2;
		else if (!cyc[which+3'd2])
			which <= which + 3'd3;
		else if (!cyc[which+3'd3])
			which <= which + 3'd4;
		else if (!cyc[which+3'd4])
			which <= which + 3'd5;
		else if (!cyc[which+3'd5])
			which <= which + 3'd6;
		else if (!cyc[which+3'd6])
			which <= which + 3'd7;
		else
			which <= which;
	end
end

endmodule
