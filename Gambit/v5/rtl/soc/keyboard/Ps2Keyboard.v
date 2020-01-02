`timescale 1ns / 1ps
// ============================================================================
//	Ps2Keyboard.v - PS2 compatible keyboard interface
//
//	2015-2018 Robert Finch
//	robfinch<remove>@finitron.ca
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
//	Reg
//	0	keyboard transmit/receive register
//	1	status reg.		itk xxxx p
//		i = interrupt status
//		t = transmit complete
//		k = transmit acknowledge receipt (from keyboard)
//		p = parity error
//		A write to the status register clears the transmitter
//		state
//
// ============================================================================
//
module Ps2Keyboard(rst_i, clk_i, cs_i, cyc_i, stb_i, ack_o, we_i, adr_i, dat_i, dat_o, kclk, kd, irq_o);
parameter pAckStyle = 1'b0;
input rst_i;
input clk_i;
input cs_i;
input cyc_i;
input stb_i;
output reg ack_o = 1'b0;
input we_i;
input [3:0] adr_i;
input [7:0] dat_i;
output reg [7:0] dat_o;
inout tri kclk;
inout tri kd;
output irq_o;

reg rd;
reg [3:0] cd;
wire busy;
wire err;
wire read_data;
wire write_data;
wire [7:0] rx_data;
reg we;
reg [3:0] adr;
reg [7:0] dat;
reg [7:0] rd_data;
always @(posedge clk_i)
	ack_o <= cs_i & cyc_i & stb_i;
always @(posedge clk_i)
	we <= we_i;
always @(posedge clk_i)
	adr <= adr_i;
always @(posedge clk_i)
	dat <= dat_i;

assign irq_o = rd;

wire pe_write_data;
edge_det ued1 (.clk(clk_i), .ce(1'b1), .i(write_data), .pe(pe_write_data), .ne(), .ee());

Ps2Interface u1
(
	.clk(clk_i),
	.rst(rst_i),
	.ps2_clk(kclk),
	.ps2_data(kd),
	.tx_data(dat),
	.write_data(pe_write_data),
	.rx_data(rx_data),
	.read_data(read_data),
	.busy(busy),
	.err(err)
);

always @(posedge clk_i)
if (rst_i) begin
	rd <= 1'b0;
end
else begin
	if (read_data) begin
		rd <= 1'b1;
		rd_data <= rx_data;
	end
	if (ack_o & we & adr[0])
    rd <= 1'b0;
end

always @(posedge clk_i)
  if (adr[0])
    dat_o <= {rd,busy,5'b0,err};
  else
    dat_o <= rd_data;

assign write_data = ack_o & we & ~adr[0];

endmodule
