`timescale 1ns / 1ps
// ============================================================================
//  i8255.v
//  - PIO
//
//	(C) 2012  Robert Finch, Stratford
//	robfinch<remove>@opencores.org
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
// ============================================================================
//
module i8255(rst_i, clk_i, cyc_i, stb_i, ack_o, we_i, adr_i, dat_i, dat_o, a, b, c);
parameter pIOAddress = 16'h0370;
input rst_i;
input clk_i;
input cyc_i;
input stb_i;
output ack_o;
input we_i;
input [15:0] adr_i;
input [7:0] dat_i;
output [7:0] dat_o;
reg [7:0] dat_o;
inout [7:0] a;
tri [7:0] a;
inout [7:0] b;
tri [7:0] b;
inout [7:0] c;
tri [7:0] c;

reg [7:0] ao,bo,co;		// output registers
reg [7:0] aL,bL;		// input latches
reg [1:0] modeA;
reg modeB;
reg [7:0] cio;
reg aio;
reg bio;
wire INTEai = co[4];
wire INTEao = co[6];
wire INTEb = co[2];
wire ackA_n = c[6];
wire stbA_n = c[4];
wire ackB_n = c[2];
wire stbB_n = c[2];
reg ostbA_n,ostbB_n;	// old strobe
reg oackA_n,oackB_n;	// old acknowledge
reg ack1;

wire cs = cyc_i && stb_i && (adr_i[15:2]==pIOAddress[15:2]);
always @(posedge clk_i)
	ack1 <= cs;
assign ack_o = cs ? (we_i ? 1'b1 : ack1) : 1'b0;
wire wr = cs & we_i;
reg owr;				// old write
reg [1:0] oad;			// old address

// Input port latches
always @(stbA_n)
	if (stbA_n==1'b0)
		aL <= a;
always @(stbB_n)
	if (stbB_n==1'b0)
		bL <= b;

always @(posedge clk_i)
if (rst_i) begin
	modeA <= 2'd0;
	modeB <= 1'b0;
	cio <= 8'hFF;
	aio <= 1'b1;
	bio <= 1'b1;
	ao <= 8'h00;
	bo <= 8'h00;
	co <= 8'h00;
end
else begin
	owr <= wr;
	oad <= adr_i[1:0];

	ostbA_n <= stbA_n;
	ostbB_n <= stbB_n;
	oackA_n <= ackA_n;
	oackB_n <= ackB_n;

	// Ports in Input mode: Negative edge on strobe actives IBF signal
	if (stbA_n==1'b0 && ostbA_n==1'b1 && ((modeA==2'd1 && aio) || modeA==2'd2))
		co[5] <= 1'b1;
	if (stbB_n==1'b0 && ostbB_n==1'b1 && modeB==1'b1 && bio)
		co[1] <= 1'b1;
	// Ports in input mode: rising edge on strobe sets interrupt output if INTE is set.
	if (stbA_n==1'b1 && ostbA_n==1'b0 && ((modeA==2'd1 && aio) || modeA==2'd2))
		if (INTEai)
			co[3] <= 1'b1;
	if (stbB_n==1'b1 && ostbB_n==1'b0 && modeB==1'b1 && bio)
		if (INTEb)
			co[0] <= 1'b1;
	// Ports in output mode: Rising edge on ACK sets interrupt output if INTE is set.
	if (!oackA_n & ackA_n && ((modeA==2'd1 && !aio) || modeA==2'd2))
		if (INTEao)
			co[3] <= 1'b1;
	if (!oackB_n & ackB_n && (modeB==1'd1 && !bio))
		if (INTEb)
			co[0] <= 1'b1;

	// Deactivation of write causes OBF_n to be activated
	// Output: write causes INTR to be reset
	if (!wr & owr) begin
		case(oad)
		2'd0:	begin
					if ((modeA==2'd1 && !aio) || modeA==2'd2)
						co[7] <= 1'b0;
					if ((modeA==2'd1 && !aio) || modeA==2'd2)
						if (INTEao)
							co[3] <= 1'b0;
				end
		2'd1:	begin 
					if (modeB==1'b1 && !bio)
						co[1] <= 1'b0;
					if (modeB==1'b1 && !bio)
						if (INTEb)
							co[0] <= 1'b0;
				end
	end
	// falling edge of ACK causes OBF_n to be deactivated
	if (oackA_n & !ackA_n && ((modeA==2'b01 && !aio) || modeA==2'd2))
		co[7] <= 1'b1;
	if (oackB_n & !ackB_n && (modeB==1'b1 && !bio))
		co[1] <= 1'b1;

	if (cs & we_i) begin
		case(adr_i[1:0])
		2'd0:	ao <= dat_i;
		2'd1:	bo <= dat_i;
		2'd2:	co <= dat_i;
		2'd3:
				begin
					if (dat_i[7]) begin
						modeB <= dat_i[2];
						if (dat_i[2]) begin
							// Port C pin directions are the same for
							// both input and output under mode 1
							cio[2] <= 1'b1;
							cio[1] <= 1'b0;
							cio[0] <= 1'b0;
						end
						else begin
							cio[3] <= dat_i[0];	// This pin control will be overridden by Port A settings.
							cio[2] <= dat_i[0];
							cio[1] <= dat_i[0];
							cio[0] <= dat_i[0];
						end
						modeA <= dat_i[6:5];
						case(dat_i[6:5])
						2'b00:	begin
									cio[7] <= dat_i[3];
									cio[6] <= dat_i[3];
									cio[5] <= dat_i[3];
									cio[4] <= dat_i[3];
								end
						2'b01: 	begin
									// Mode 1 - Input
									if (dat_i[4]) begin
										cio[4] <= 1'b1;
										cio[5] <= 1'b0;
										cio[3] <= 1'b0;
									end
									// Mode 1 - Output
									else begin
										cio[7] <= 1'b0;
										cio[6] <= 1'b1;
										cio[3] <= 1'b0;
									end
								end
						2'b02:	begin
									cio[7] <= 1'b0;
									cio[6] <= 1'b1;
									cio[4] <= 1'b1;
									cio[5] <= 1'b0;
									cio[3] <= 1'b0;
								end
						endcase
						aio <= dat_i[4];
						bio <= dat_i[1];
						// Mode change causes port A and C outputs to be
						// reset to zero.
						if (dat_i[6:5]!=modeA) begin
							ao <= 8'h00;
							co <= 8'h00;
						end
					end
					else begin
						case(dat_i[3:1])
						3'd0:	co[0] <= dat_i[0];
						3'd1:	co[1] <= dat_i[0];
						3'd2:	co[2] <= dat_i[0];
						3'd3:	co[3] <= dat_i[0];
						3'd4:	co[4] <= dat_i[0];
						3'd5:	co[5] <= dat_i[0];
						3'd6:	co[6] <= dat_i[0];
						3'd7:	co[7] <= dat_i[0];
						endcase
					end
				end
		endcase
	end
	// Reads
	if (cs) begin
		case(adr_i[1:0])
		2'd0:	begin 
					if (modeA==2'b00)	// Simple I/O
						dat_o <= aio ? a : ao;
					else begin			// Handshake I/O
						// Reading port clears IBF
						if (aio==1'b1) begin
							dat_o <= aL;
							co[5] <= 1'b0;
							if (INTEai)		// Reading the port resets the interrupt
								co[3] <= 1'b0;
						end
						else
							dat_o <= ao;
					end
				end
		2'd1:	begin
					if (modeB==1'b0)
						dat_o <= bio ? b : bo;
					else begin
						// Reading port clears IBF
						if (bio==1'b1) begin
							dat_o <= bL;
							co[1] <= 1'b0;
							if (INTEb)		// Reading the port resets the interrupt
								co[0] <= 1'b0;
						end
						else
							dat_o <= bo;
					end
				end
		2'd2:	dat_o <= {
					cio[0] ? c[0] : co[0],
					cio[1] ? c[1] : co[1],
					cio[2] ? c[2] : co[2],
					cio[3] ? c[3] : co[3],
					cio[4] ? c[4] : co[4],
					cio[5] ? c[5] : co[5],
					cio[6] ? c[6] : co[6],
					cio[7] ? c[7] : co[7],
					};
		2'd3:	dat_o <= 8'h00;		// no read of control word 
		endcase
	end
	else
		dat_o <= 8'h00;
end


// In mode 2 the I/O is defined as output when ACK is active, otherwise input; the aio setting is a don't care.
assign a =
	(modeA==2'd2) ? (ackA_n==1'b0 ? ao : 8'bz) :
	aio ? 8'bz : ao;
assign b = bio ? 8'bz : bo;
assign c[0] = cio[0] ? 1'bz : co[0];
assign c[1] = cio[1] ? 1'bz : co[1];
assign c[2] = cio[2] ? 1'bz : co[2];
assign c[3] = cio[3] ? 1'bz : co[3];
assign c[4] = cio[4] ? 1'bz : co[4];
assign c[5] = cio[5] ? 1'bz : co[5];
assign c[6] = cio[6] ? 1'bz : co[6];
assign c[7] = cio[7] ? 1'bz : co[7];

endmodule
