`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
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
//
//	Verilog 1995
//
// ============================================================================
//
module node(rst_i, clk_i, sclk, rxdX, txdX, rxdY, txdY, rxdZ, txdZ, cyc, stb, ack, we, adr, dati, dato);
input rst_i;
input clk_i;
input sclk;
input [3:0] rxdX;
input [3:0] rxdY;
input [3:0] rxdZ;
output [3:0] txdX;
output [3:0] txdY;
output [3:0] txdZ;
output cyc;
output stb;
input ack;
output we;
output [15:0] adr;
input [7:0] dati;
output [7:0] dato;
parameter ID = 12'h111;
parameter HAS_ZROUTE = 0;

wire [7:0] rout_dato;
wire rout_ack;
wire brAck;
wire ramAck;

wire cs_rom;
wire cs_ram = adr[15:13]==3'h0 && cyc && stb; 
wire routCs = adr[15:8]==8'hB0;

reg [7:0] romo;
wire [7:0] ramo;
reg [15:0] radr;
always @(posedge clk_i)
    radr <= adr;
generate begin
if (ID==12'h111 || ID==12'h421) begin
assign cs_rom = adr[15:14]==2'b11 && cyc && stb;
reg [7:0] rommem [0:16383];
always @(posedge clk_i)
    romo <= rommem[radr[13:0]];
initial begin
    $readmemh("C:\\Cores4\\Butterfly\\trunk\\software\\bfasm\\debug\\noc_boot11.mem",rommem);
end
end
else begin
assign cs_rom = adr[15:13]==3'b111 && cyc && stb;
reg [7:0] rommem [0:8191];
always @(posedge clk_i)
    romo <= rommem[radr[12:0]];
if (ID==12'h211)
initial begin
    $readmemh("C:\\Cores4\\Butterfly\\trunk\\software\\bfasm\\debug\\noc_boot21.mem",rommem);
end
else if (ID==12'h311)
initial begin
    $readmemh("C:\\Cores4\\Butterfly\\trunk\\software\\bfasm\\debug\\noc_boot31.mem",rommem);
end
else if (ID==12'h411)
initial begin
    $readmemh("C:\\Cores4\\Butterfly\\trunk\\software\\bfasm\\debug\\noc_boot41.mem",rommem);
end
else
initial begin
    $readmemh("C:\\Cores4\\Butterfly\\trunk\\software\\bfasm\\debug\\noc_boot.mem",rommem);
end
end
end
endgenerate

node_ramXX uram1 (
  .clka(clk_i),   // input wire clka
  .ena(cs_ram),   // input wire ena
  .wea(we),      // input wire [0 : 0] wea
  .addra(adr[12:0]),  // input wire [11 : 0] addra
  .dina(dato),    // input wire [7 : 0] dina
  .douta(ramo)  // output wire [7 : 0] douta
);

reg romrdy,romrdy1,ramrdy1,ramrdy2;
always @(posedge clk_i)
    romrdy <= cs_rom;
always @(posedge clk_i)
    romrdy1 <= romrdy & cs_rom;
always @(posedge clk_i)
    ramrdy1 <= cs_ram;
always @(posedge clk_i)
    ramrdy2 <= ramrdy1 & cs_ram;
assign brAck = cs_rom ? romrdy1 : 1'b0;
assign ramAck = cs_ram ? ramrdy2 : 1'b0;

routerTop #(HAS_ZROUTE) urout1
(
    .X(ID[11:8]),
    .Y(ID[7:4]),
    .Z(ID[3:0]),
    .rst_i(rst_i),
    .clk_i(clk_i),
    .cs_i(routCs),
    .cyc_i(cyc),
    .stb_i(stb),
    .ack_o(rout_ack),
    .we_i(we),
    .adr_i(adr[4:0]),
    .dat_i(dato),
    .dat_o(rout_dato),
    .sclk(sclk),
    .rxdX(rxdX),
    .rxdY(rxdY),
    .rxdZ(rxdZ),
    .txdX(txdX),
    .txdY(txdY),
    .txdZ(txdZ)
);

wire iack = rout_ack|brAck|ramAck|ack; 
reg [7:0] idati;

always @*
casex({cs_rom,cs_ram,routCs})
3'b1xx:    idati <= romo;
3'b01x:    idati <= ramo;
3'b001:    idati <= rout_dato;
default:   idati <= dati;
endcase

Butterfly16 ucpu1
(
	.id(ID),		// cpu id (which cpu am I?)
	.nmi(1'b0),			// non-maskable interrupt
	.irq(1'b0),			// irq inputs
	.go(1'b1),			// exit stop state if active
	// Bus master interface
	.rst_i(rst_i),			// reset
	.clk_i(clk_i),			// clock
	.soc_o(),		// start of cyc_ole
	.cyc_o(cyc),		// cyc_ole valid
	.ack_i(iack),			// bus transfer complete
	.ird_o(),		// instruction read cyc_ole
	.we_o(we),		// write cycle
	.adr_o(adr),	// address
	.dat_i(idati),		// instruction / data input bus
	.dat_o(dato),	// data output bus
	.soc_nxt_o(),		// start of cyc_ole is next
	.cyc_nxt_o(),		// next cyc_ole will be valid
	.ird_nxt_o(),			// next cyc_ole will be an instruction read
	.we_nxt_o(),			// next cyc_ole will be a we_oite
	.adr_nxt_o(),	// address for next cyc_ole
	.dat_nxt_o()	// data output for next cyc_ole
);

assign stb = cyc;

endmodule

