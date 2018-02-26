`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2013-2018  Robert Finch, Waterloo
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
//		Encodes discrete interrupt request signals into five
//	bit code using a priority encoder.
//	
//	reg
//	0x008	- interrupt enable, bit set (read/write)
//			When written for each set bit in the input data
//          the corresponding interrupt source will be enabled
//
//  0x010	- interrupt disable, bit set (read/write)
//			When written for each set bit in the input data
//		    the corresponding interrupt source will be disabled
//
//	0x018	- interrupt acknowledge
//			Write the interrupt number to be acknowledged to this
//			register. Writing the register will reset the edge sense
//          circuit and advance the rotating interrupt target for
//          that interrupt
//
//	0x020	- interrupt control for interrupt #1
//            bits 0 to 6  = cause code value
//            bits 8 to 11 = irq level to issue
//            bit 16 = irq enable
//            bit 17 = edge sensitivity
//
//	0x028	- static target assignment for interrupt #1
//			This register determines which interrupt outputs will be
//			activated when the interrupt occurs.
//
//  0x030	- rotating target assignment for interrupt #1
//			This register determines which interrupt outputs will be
//			activated when the interrupt occurs.
//			This register will rotate automatically on interrupt acknowledge
//
//	0x038	- not used
//
//	0x040 to 0x7F8 repeat of 0x020 to 0x38 except for interrupts #2 to 63
//=============================================================================
//
module FT64_plic(rst_i, clk_i, cs_i, cyc_i, stb_i, ack_o, we_i, adr_i, dat_i, dat_o,
	i_i,
	irq_o
);
parameter NIRQ = 32;
parameter NTGT = 32;
input rst_i;
input clk_i;
input cs_i;
input cyc_i;
input stb_i;
output ack_o;
input we_i;
input [11:0] adr_i;
input [63:0] dat_i;
output reg [63:0] dat_o;

input [NIRQ-1:0] i_i;
output reg [3:0] irq_o [0:NTGT-1];

reg [7:0] cause [0:NIRQ-1];
reg [NTGT-1:0] rotreg [0:NIRQ-1];	// rotating assigment reg
reg [NTGT-1:0] statreg [0:NIRQ-1];	// static assignment reg
reg [NIRQ-1:0] iedge;		// interrupt edge detected
reg [NIRQ-1:0] pil;			// previous interrupt level
reg [NIRQ-1:0] ie;          // interrupt enable
reg [NIRQ-1:0] es;			// edge sensitivity
reg [NIRQ-1:0] rste;		// reset edge sense
reg [3:0] irq [0:NIRQ-1];	// interrupt level
reg [NIRQ-1:0] i;

wire cs = cs_i & cyc_i & stb_i;
reg rdy1;
always @(posedge clk_i)
	rdy1 <= cs;
assign ack_o = cs ? (we_i ? 1'b1 : rdy1) : 1'b0;

// write registers	
always @(posedge clk_i)
	if (rst_i) begin
		ie <= 64'h0;
		rste <= 64'h0;
	end
	else begin
		rste <= 64'h0;
		if (cs & we_i) begin
			casez (adr_i[10:3])
			8'b00000001:	ie <= ie | dat_i;
			8'b00000010:	ie <= ie & ~dat_i;
			8'b00000011:	begin
							rste[dat_i[5:0]] <= 1'b1;
							rotreg[dat_i[5:0]] <= {rotreg[dat_i[5:0]][NTGT-2:0],rotreg[dat_i[5:0]][NTGT-1]};
							end
			8'b??????00:
			     begin
			     	 cause[adr_i[10:5]] <= dat_i[6:0];
			         irq[adr_i[10:5]] <= dat_i[11:8];
			         ie[adr_i[10:5]] <= dat_i[16];
			         es[adr_i[10:5]] <= dat_i[17];
			     end
			8'b??????01:	statreg[adr_i[10:5]] <= dat_i[31:0];
			8'b??????10:	rotreg[adr_i[10:5]] <= dat_i[31:0];
			endcase
		end
	end

// read registers
always @(posedge clk_i)
begin
	if (i!=64'd0)
		$display("PIC: %h",i);
	casez (adr_i[10:3])
	9'b0000000?:	dat_o <= ie;
	9'b00000010:	dat_o <= ie;
	9'b??????00:	dat_o <= {es[adr_i[10:5]],ie[adr_i[10:5]],4'b0,irq[adr_i[10:5]],1'b0,cause[adr_i[10:5]]};
	9'b??????01:	dat_o <= statreg[adr_i[10:5]];
	9'b??????10:	dat_o <= rotreg[adr_i[10:5]];
	default:	dat_o <= ie;
	endcase
end

// Edge detect circuit
integer n, m;
always @(posedge clk_i)
begin
	for (n = 1; n < 64; n = n + 1)
	begin
		pil[n] <= i_i[n];
		if (i_i[n] & !pil[n]) iedge[n] <= 1'b1;
		if (rste[n]) iedge[n] <= 1'b0;
	end
end

// irq requests are latched on every rising clock edge to prevent
// misreads
// nmi is not encoded
always @(posedge clk_i)
begin
	for (n = 63; n > 0; n = n - 1)
		i[n] = ie[n] & (es[n] ? iedge[n] : i_i[n]);
end

always @(posedge clk_i)
	for (n = 0; n < 64; n = n + 1) begin
		for (m = 0; m < 32; m = m + 1) begin
			if (statreg[n][m])
				irq_o[m] <= i[n] ? irq[n] : 4'h0;
			if (rotreg[n][m])
				irq_o[m] <= i[n] ? irq[n] : 4'h0;
		end
	end

endmodule
