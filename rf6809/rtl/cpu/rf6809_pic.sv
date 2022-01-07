`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2013-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
//          bits 8 to 15 set the base number for the vector
//
//	0x04	- request enable (read / write)
//			this register contains request enable bits
//			for each request line. 1 = request
//			enabled, 0 = request disabled. On reset this
//			register is set to zero (disable all ints).
//			bit zero is specially reserved for nmi
//
//	0x08   - write only
//			this register disables the interrupt indicated
//			by the low order five bits of the input data
//			
//	0x0C	- write only
//			this register enables the interrupt indicated
//			by the low order five bits of the input data
//
//	0x10	- write only
//			this register indicates which interrupt inputs are
// 			edge sensitive
//
//  0x14	- write only
//			This register resets the edge sense circuitry
//			indicated by the low order five bits of the input data.
//
//  0x18  - write only
//      This register triggers the interrupt indicated by the low
//      order five bits of the input data.
//
//  0x80    - irq control for irq #0
//  0x84    - irq control for irq #1
//            bits 0 to 7  = cause code to issue
//            bits 8 to 11 = irq level to issue
//            bit 16 = irq enable
//            bit 17 = edge sensitivity
//=============================================================================

module rf6809_pic
(
	input rst_i,		// reset
	input clk_i,		// system clock
	input cs_i,
	input cyc_i,
	input stb_i,
	output ack_o,       // controller is ready
	input wr_i,			// write
	input [7:0] adr_i,	// address
	input [7:0] dat_i,
	output reg [7:0] dat_o,
	output vol_o,		// volatile register selected
	output reg m_cyc_o,
	output reg m_stb_o,
	input m_ack_i,
	output reg m_we_o,
	output reg [23:0] m_adr_o,
	output reg [7:0] m_dat_o,
	input i1, i2, i3, i4, i5, i6, i7,
		i8, i9, i10, i11, i12, i13, i14, i15,
		i16, i17, i18, i19, i20, i21, i22, i23,
		i24, i25, i26, i27, i28, i29, i30, i31,
	output reg [3:0] irqo,	// normally connected to the processor irq
	input nmii,		// nmi input connected to nmi requester
	output reg nmio,	// normally connected to the nmi of cpu
	output reg [7:0] causeo,
	output reg [5:0] server_o
);
parameter pIOAddress = 32'hFF95_0000;

wire clk;
reg [31:0] trig;
reg [31:0] ie;		// interrupt enable register
reg rdy1;
reg [4:0] irqenc;
wire [31:0] i = {   i31,i30,i29,i28,i27,i26,i25,i24,i23,i22,i21,i20,i19,i18,i17,i16,
                    i15,i14,i13,i12,i11,i10,i9,i8,i7,i6,i5,i4,i3,i2,i1,nmii};
reg [31:0] ib;
reg [31:0] iedge;
reg [31:0] rste;
reg [31:0] es;
reg [3:0] irq [0:31];
reg [7:0] cause [0:31];
reg [5:0] server [0:31];
integer n;

initial begin
	ie <= 32'h0;	
	es <= 32'hFFFFFFFF;
	rste <= 32'h0;
	for (n = 0; n < 32; n = n + 1) begin
		cause[n] <= 8'h00;
		irq[n] <= 4'h8;
		server[n] <= 6'd2;
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
	end
	else begin
		rste <= 32'h0;
		trig <= 32'h0;
		if (cs & wr_i) begin
			casez (adr_i[7:0])
			8'd0: ;
			8'd4:	ie[31:24] <= dat_i;
			8'd5:	ie[23:16] <= dat_i;
			8'd6:	ie[15: 8] <= dat_i;
			8'd7:	ie[ 7: 0] <= dat_i;
			8'd8,8'd9:
				ie[dat_i[4:0]] <= adr_i[0];
			8'd12: 	es[31:24] <= dat_i;
			8'd13:	es[23:16] <= dat_i;
			8'd14:	es[15: 8] <= dat_i;
			8'd15:	es[ 7: 0] <= dat_i;
			8'd16:	rste[dat_i[4:0]] <= 1'b1;
			8'd17:	trig[dat_i[4:0]] <= 1'b1;
			8'b1?????00:
	     	 cause[adr_i[6:2]] <= dat_i;
			8'b1?????01:
			     begin
			         irq[adr_i[6:2]] <= dat_i[3:0];
			         ie[adr_i[6:2]] <= dat_i[6];
			         es[adr_i[6:2]] <= dat_i[7];
			     end
			8'b1?????10:
				server[adr_i[6:2]] <= dat_i[5:0];
			default:	;
			endcase
		end
	end

// read registers
always @(posedge clk)
begin
	if (irqenc!=5'd0)
		$display("PIC: %d",irqenc);
	if (cs)
		casez (adr_i[7:0])
		8'd0:	dat_o <= cause[irqenc];
		8'd4:	dat_o <= ie[31:24];
		8'd5:	dat_o <= ie[23:16];
		8'd6:	dat_o <= ie[15: 8];
		8'd7:	dat_o <= ie[ 7: 0];
		8'b1?????00: dat_o <= cause[adr_i[6:2]];
		8'b1?????01: dat_o <= {es[adr_i[6:2]],ie[adr_i[6:2]],2'b0,irq[adr_i[6:2]]};
		8'b1?????10:	dat_o <= {2'b0,server[adr_i[6:2]]};
		default:	dat_o <= 8'h00;
		endcase
	else
		dat_o <= 8'h00;
end

// Master cycle
reg [5:0] state;
parameter ST_IDLE = 6'd0;
parameter ST_ACK = 6'd1;
always @(posedge clk)
begin
	case(state)
	ST_IDLE:
		if (irqo) begin
			m_cyc_o <= 1'b1;
			m_stb_o <= 1'b1;
			m_we_o <= 1'b1;
			m_adr_o <= {4'hC,server[irqenc]-2'd1,20'hFFF00+irqenc};
			m_dat_o <= 8'h01;
			state <= ST_ACK;
		end
	ST_ACK:
		if (m_ack_i) begin
			m_cyc_o <= 1'b0;
			m_stb_o <= 1'b0;
			m_we_o <= 1'b0;
			state <= ST_IDLE;
		end
	default:
		state <= ST_IDLE;
	endcase
end

always @(posedge clk)
  irqo <= (irqenc == 5'h0) ? 4'd0 : irq[irqenc] & {4{ie[irqenc]}};
always @(posedge clk)
  causeo <= (irqenc == 5'h0) ? 8'd0 : cause[irqenc];
always @(posedge clk)
  server_o <= (irqenc == 5'h0) ? 6'd0 : server[irqenc];
always @(posedge clk)
  nmio <= nmii & ie[0];

// Edge detect circuit
always @(posedge clk)
begin
	for (n = 1; n < 32; n = n + 1)
	begin
		ib[n] <= i[n];
		if (trig[n]) iedge[n] <= 1'b1;
		if (i[n] & !ib[n]) iedge[n] <= 1'b1;
		if (rste[n]) iedge[n] <= 1'b0;
	end
end

// irq requests are latched on every rising clock edge to prevent
// misreads
// nmi is not encoded
always @(posedge clk)
begin
	irqenc <= 5'd0;
	for (n = 31; n > 0; n = n - 1)
		if ((es[n] ? iedge[n] : i[n])) irqenc <= n;
end

endmodule
