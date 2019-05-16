`timescale 1ns / 1ps
// ============================================================================
//	Ps2Keyboard.v - PS2 compatible keyboard interface
//
//	2015 Robert Finch
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
module Ps2Keyboard_sim(rst_i, clk_i, cyc_i, stb_i, ack_o, we_i, adr_i, dat_i, dat_o, kclk, kd, irq_o);
parameter pIOAddress = 32'hFFDC0000;
parameter pAckStyle = 1'b0;
input rst_i;
input clk_i;
input cyc_i;
input stb_i;
output ack_o;
input we_i;
input [31:0] adr_i;
input [7:0] dat_i;
output reg [7:0] dat_o;
inout tri kclk;
inout tri kd;
output irq_o;

reg rd;
wire write_data;
wire cs_kbd = cyc_i & stb_i && adr_i[31:4]==pIOAddress[31:4];
assign ack_o = cs_kbd;
assign irq_o = rd;
reg read_data;
reg busy;
reg err;
reg [7:0] rx_data;
reg [19:0] cnt;
always @(posedge clk_i)
if (rst_i)
    cnt <= 20'd0;
else
    cnt <= cnt + 1;

always @(posedge clk_i)
if (rst_i) begin
    read_data <= 1'b0;
    rx_data <= 8'h00;
    busy <= 1'b0;
    err <= 1'b0;
end
else begin
read_data <= 0;
case(cnt)
300:
    begin
        read_data <= 1'b1;
        rx_data <= 8'h41;
    end
350:
    begin
        read_data <= 1'b1;
        rx_data <= 8'h42;
    end
400:
    begin
        read_data <= 1'b1;
        rx_data <= 8'h43;
    end
endcase
end

always @(posedge clk_i)
if (rst_i)
	rd <= 1'b0;
else begin
	if (read_data)
		rd <= 1'b1;
	else if (cs_kbd & ~we_i)
		rd <= 1'b0;
end

always @*
	if (cs_kbd & ~we_i) begin
		if (adr_i[0])
			dat_o <= {rd,busy,5'b0,err};
		else
			dat_o <= rx_data;
	end
	else
		dat_o <= 8'h00;

assign write_data = cs_kbd & we_i & ~adr_i[0];

endmodule
