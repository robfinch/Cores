`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2013-2020  Robert Finch, Waterloo
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
//	0x00	- encoded request number (read / write)
//			This register contains the number identifying
//			the current requester in bits 0 to 4
//			If there is no
//			active request, then this number will be 
//			zero.
//          bits 13 to 25 set the base number for the vector
//
//	0x04	- request enable (read / write)
//			this register contains request enable bits
//			for each request line. 1 = request
//			enabled, 0 = request disabled. On reset this
//			register is set to zero (disable all ints).
//			bit zero is specially reserved for nmi
//			Only the low order 32-bits of the register are
//      implmented.
//
//	0x08   - write only
//			this register disables the interrupt indicated
//			by the low order five bits of the input data
//			
//	0x0C	- write only
//			this register enables the interrupt indicated
//			by the low order five bits of the input data
//
//  0x14	- write only
//			This register resets the edge sense circuitry
//			indicated by the low order five bits of the input data.
//
//  0x18  - write only
//      This register triggers the interrupt indicated by the low
//      order five bits of the input data.
//
//	0x20	- write only
//			this register indicates which interrupt inputs are
// 			edge sensitive
//
//	0x24	- write only
//			this register indicates which interrupt inputs are
// 			edge sensitive
//
//  0x80    - irq control for irq #0
//  0x84    - irq control for irq #1
//            bits 0 to 7  = cause code to issue
//						bit  8 to 9  = processor
//							01 = cpu#1
//							10 = cpu#2
//							11 = alternate
//            bits 13 to 15 = irq level to issue
//            bit 16 = irq enable
//            bit 17 = edge sensitivity
//=============================================================================

module Petajon_pic
(
	input rst_i,		// reset
	input clk_i,		// system clock
	input cs_i,
	input cyc_i,
	input stb_i,
	output ack_o,       // controller is ready
	input wr_i,			// write
	input [7:0] adr_i,	// address
	input [31:0] dat_i,
	output reg [31:0] dat_o,
	output vol_o,		// volatile register selected
	input i1, i2, i3, i4, i5, i6, i7,
		i8, i9, i10, i11, i12, i13, i14, i15,
		i16, i17, i18, i19, i20, i21, i22, i23,
		i24, i25, i26, i27, i28, i29, i30, i31,
	output [2:0] irqo,	// normally connected to the processor irq
	output [2:0] irqo2,
	input nmii,		// nmi input connected to nmi requester
	output nmio,	// normally connected to the nmi of cpu
	output [7:0] causeo
);
//parameter pIOAddress = 32'hFFDC_0F00;

wire clk;
reg [31:0] trig;
reg [31:0] ie;					// interrupt enable register
reg [1:0] isw [0:31];		// interrupt switch
reg rdy1;
reg [4:0] irqenc;
wire [31:0] i = {   i31,i30,i29,i28,i27,i26,i25,i24,i23,i22,i21,i20,i19,i18,i17,i16,
                    i15,i14,i13,i12,i11,i10,i9,i8,i7,i6,i5,i4,i3,i2,i1,nmii};
reg [31:0] ib;
reg [31:0] ipedge;
reg [31:0] inedge;
reg [31:0] rste;
reg [31:0] esL;
reg [31:0] esH;
reg [3:0] irq [0:31];
reg [7:0] cause [0:31];
integer n;

initial begin
	ie <= 32'h0;	
	esL <= 64'h0;
	esH <= 64'h0;
	rste <= 32'h0;
	for (n = 0; n < 32; n = n + 1) begin
		cause[n] <= 8'h00;
		irq[n] <= 4'h8;
		isw[n] <= 2'b01;
	end
end

wire cs = cyc_i && stb_i && cs_i;
assign vol_o = cs;

assign clk = clk_i;
//BUFH ucb1 (.I(clk_i), .O(clk));

always @(posedge clk)
	rdy1 <= cs;
assign ack_o = cs ? (wr_i ? 1'b1 : rdy1) : 1'b0;

// write registers	
always @(posedge clk)
	if (rst_i) begin
		ie <= 32'h0;
		rste <= 32'h0;
		trig <= 32'h0;
		esL <= 32'h0;
		esH <= 32'h0;
	end
	else begin
		rste <= 32'h0;
		trig <= 32'h0;
		if (cs & wr_i) begin
			casez (adr_i[7:2])
			6'd0: ;
			6'd1:
				begin
					ie[31:0] <= dat_i[31:0];
				end
			6'd2,6'd3:
				ie[dat_i[4:0]] <= adr_i[2];
			6'd4:	;
			6'd5:	rste[dat_i[4:0]] <= 1'b1;
			6'd6:	trig[dat_i[4:0]] <= 1'b1;
			6'd8:	esL <= dat_i[31:0];
			6'd9:	esH <= dat_i[31:0];
			6'b1?????:
			     begin
			     	 cause[adr_i[6:2]] <= dat_i[7:0];
			     	 isw[adr_i[6:2]] <= dat_i[9:8];
		         irq[adr_i[6:2]] <= dat_i[15:13];
		         ie[adr_i[6:2]] <= dat_i[16];
		         esL[adr_i[6:2]] <= dat_i[17];
		         esH[adr_i[6:2]] <= dat_i[18];
			     end
			endcase
		end
	end

// read registers
always @(posedge clk)
begin
	if (irqenc!=5'd0)
		$display("PIC: %d",irqenc);
	if (cs)
		casez (adr_i[7:2])
		6'd0:	dat_o <= cause[irqenc];
		6'b1?????: dat_o <= {esH[adr_i[6:2]],esL[adr_i[6:2]],ie[adr_i[6:2]],irq[adr_i[6:2]],3'b0,isw[adr_i[6:2]],cause[adr_i[6:2]]};
		default:	dat_o <= ie;
		endcase
	else
		dat_o <= 64'h0000;
end

assign irqo = (irqenc == 5'h0 || !isw[irqenc][0]) ? 3'd0 : irq[irqenc] & {3{ie[irqenc]}};
assign irqo2 = (irqenc == 5'h0 || !isw[irqenc][1]) ? 3'd0 : irq[irqenc] & {3{ie[irqenc]}};
assign causeo = (irqenc == 5'h0) ? 8'd0 : cause[irqenc];
assign nmio = nmii & ie[0];

// Edge detect circuit
always @(posedge clk)
begin
	for (n = 1; n < 32; n = n + 1)
	begin
		ib[n] <= i[n];
		if (trig[n]) begin
			if (esL[n])
				ipedge[n] <= 1'b1;
			if (esH[n])
				inedge[n] <= 1'b1;
		end
		if (i[n] & !ib[n]) ipedge[n] <= 1'b1;
		if (!i[n] & ib[n]) inedge[n] <= 1'b1;
		if (rste[n]) begin
			ipedge[n] <= 1'b0;
			inedge[n] <= 1'b0;
		end
	end
end

// irq requests are latched on every rising clock edge to prevent
// misreads
// nmi is not encoded
always @(posedge clk)
begin
	irqenc <= 5'd0;
	for (n = 31; n > 0; n = n - 1)
		case({esH[n],esL[n]})
		2'b00:	if (i[n]) irqenc <= n;
		2'b01:	if (ipedge[n]) irqenc <= n;
		2'b10:	if (inedge[n]) irqenc <= n;
		2'b11:	if (ipedge[n]|inedge[n]) irqenc <= n;
		endcase
end

endmodule
