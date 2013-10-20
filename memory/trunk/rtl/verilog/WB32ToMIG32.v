`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2011-2013  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// WB32ToMIG32.v
// - 32 bit WISHBONE to MIG bus bridge
// - supports constant address burst cycles and classic bus cycles
// - Not supported: the master driving the strobe line low during burst
//   access. The master is assumed to always be ready during a burst.
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
//`define SUPPORT_INCADR	1

module WB32ToMIG32 (
input rst_i,
input clk_i,

// WISHBONE PORT
input [1:0] bte_i,					// burst type extension
input [2:0] cti_i,					// cycle type indicator
input cyc_i,						// cycle in progress
input stb_i,						// data strobe
output ack_o,						// acknowledge
output rty_o,
input we_i,							// write cycle
input [3:0] sel_i,					// byte lane selects
input [31:0] adr_i,					// address
input [31:0] dat_i,					// data 
output [31:0] dat_o,
input [5:0] bl_i,					// burst length

// MIG port
input calib_done,
input cmd_full,
output reg cmd_en,
output reg [2:0] cmd_instr,
output reg [5:0] cmd_bl,
output reg [29:0] cmd_byte_addr,

output reg rd_en,
input [31:0] rd_data,
input rd_empty,
input rd_overflow,
input rd_error,

output reg wr_en,
output reg [3:0] wr_mask,
output reg [31:0] wr_data,
input wr_empty,
input wr_full,
input [6:0] wr_count,
input wr_underrun,
input wr_error
);
parameter IDLE = 4'd1;
parameter BWRITE_001 = 4'd2;
parameter BWRITE_010 = 4'd3;
parameter BWRITE_CMD = 4'd4;
parameter BWRITE_CMD_OFF = 4'd5;
parameter BREAD_000 = 4'd6;
parameter BREAD_001 = 4'd7;
parameter BREAD_010 = 4'd8;
parameter BREAD = 4'd9;
parameter BREAD1 = 4'd10;
parameter BREAD2 = 4'd11;
parameter NACK = 4'd12;

// Fill write FIFO then issue write command
reg [5:0] ctr;		// burst length counter
reg [31:0] dato;
reg [3:0] state;
reg ack1;

wire cs = cyc_i && stb_i;// && adr_i[63:32]==32'h00000000;		// circuit select
assign ack_o = ack1 & cs;		// Force ack_o low as soon as cyc_i or stb_i go low
assign dat_o = cs ? dato : 32'h00000000;	// Allow wire-or'ing data bus

reg [31:0] prev_adr;

always @(posedge clk_i)
if (rst_i) begin
	ack1 <= 1'b0;
	ctr <= 6'd0;
	state <= IDLE;
end
else begin
cmd_en <= 1'b0;		// Forces cmd_en to be just a 1-cycle pulse
wr_en <= 1'b0;
case(state)
IDLE:
	if (cs & calib_done) begin
		ctr <= 6'd0;
		// Build command
		// Capture the address. MIG doesn't want this address until the command
		// is issued after the FIFO is full. The WB master might change it's address,
		// as it starts a new cycle, so we need to remember what it was originally.
		cmd_byte_addr <= {adr_i[29:2],2'b00};
		if (cti_i==3'b001 || cti_i==3'b010)
			cmd_bl <= bl_i;
		else
			cmd_bl <= 6'd0;
		cmd_instr <= we_i ? 3'b000 : 3'b001;	// WRITE / READ
		prev_adr <= adr_i;

		// Write cycles
		if (we_i) begin
			case(cti_i)
			// Since we are only writing a word, we only need to wait for a single
			// opening.
			3'b000,3'b111:
				if (!wr_full) begin
					ack1 <= 1'b1;
					wr_en <= 1'b1;
					wr_data <= dat_i;
					wr_mask <= ~sel_i;
					state <= BWRITE_CMD;
				end
			// Since we want to write a burst of numerous data, we wait until the
			// write FIFO is empty. We could wait until the FIFO count is greater
			// than the burst length.
			3'b001:
				if (wr_empty) begin
					ack1 <= 1'b1;
					wr_en <= 1'b1;
					wr_data <= dat_i;
					wr_mask <= ~sel_i;
					ctr <= 6'd1;
					state <= BWRITE_001;
				end
`ifdef SUPPORT_INCADR
			3'b010:
				if (wr_empty) begin
					prev_adr <= adr_i;
					ack1 <= 1'b1;
					wr_en <= 1'b1;
					wr_data <= dat_i;
					wr_mask <= ~sel_i;
					ctr <= 6'd1;
					state <= BWRITE_010;
				end
`endif
			// Could assert err_o
			default:	;
			endcase
		end
		// Read cycles
		else begin
			if (!cmd_full) begin
				cmd_en <= 1'b1;
				case(cti_i)
				3'b000:	state <= BREAD_001;
				3'b001:	state <= BREAD_001;
`ifdef SUPPORT_INCADR
				3'b010: state <= BREAD_010;
`endif
				3'b111:	state <= BREAD_001;
				default:	;
				endcase
			end
		end
	end

//---------------------------------------------------------
// Burst or single write
// - we assume that since the write fifo was empty to
//   begin with, that we don't need to check the status
//---------------------------------------------------------

// constant address burst
BWRITE_001:
	if (stb_i) begin
		ack1 <= 1'b1;
		wr_en <= 1'b1;
		wr_data <= dat_i;
		wr_mask <= ~sel_i;
		ctr <= ctr + 6'd1;
		if (ctr>=bl_i || !cyc_i || cti_i==3'b111)
			state <= BWRITE_CMD;
	end
	else
		ack1 <= 1'b0;

`ifdef SUPPORT_INCADR
// To write in incrementing address mode, we wait for the
// address to change before writing. Teh master might just hold
// onto the same address for more than one cycle. We only want to
// write to the fifo once per address.
BWRITE_010:
	if (stb_i) begin
		if (adr_i != prev_adr) begin
			ack1 <= 1'b1;
			wr_en <= 1'b1;
			wr_data <= dat_i;
			wr_mask <= ~sel_i;
			prev_adr <= adr_i;
			ctr <= ctr + 6'd1;
		end
		if (ctr>=bl_i || !cyc_i || cti_i==3'b111)
			state <= BWRITE_CMD;
	end
	else
		ack1 <= 1'b0;
`endif

BWRITE_CMD:
	if (!cmd_full) begin
		cmd_en <= 1'b1;
		state <= NACK;
	end

// single read
// Constant address burst
BREAD_001:
	begin
		if (stb_i)
			rd_en <= 1'b1;
		else begin
			ack1 <= 1'b0;
			rd_en <= 1'b0;
		end
		if (rd_en) begin
			if (rd_empty)
				ack1 <= 1'b0;
			else begin
				ack1 <= 1'b1;
				dato <= rd_data;
				ctr <= ctr + 6'd1;
				if (ctr >= bl_i || cti_i==3'b000 || cti_i==3'b111)
					state <= NACK;
			end
		end
		// abort cycle if ternminated early
		if (!cyc_i) begin
			ack1 <= 1'b0;
			state <= NACK;
		end
	end

`ifdef SUPPORT_INCADR
// Incrementing address burst
BREAD_010:
	begin
		if (stb_i)
			rd_en <= 1'b1;
		else begin
			ack1 <= 1'b0;
			rd_en <= 1'b0;
		end
		if (adr_i==prev_adr && ack1)
			rd_en <= 1'b0;
		if (rd_en & !rd_empty) begin
			prev_adr <= adr_i;
			ack1 <= 1'b1;
			dato <= rd_data;
			ctr <= ctr + 6'd1;
			if (ctr >= bl_i || !cyc_i || cti_i==3'b000 || cti_i==3'b111)
				state <= NACK;
		end
	end
`endif

//---------------------------------------------------------
//---------------------------------------------------------
// If cyc_o went inactive during BWRITE_CMD (ack1==1'b0) then move
// to next state. cyc_i might have gone back to active as the next
// bus cycle could have started.
//
NACK:
	begin
		if (!cyc_i)
			ack1 <= 1'b0;
		if (!rd_empty)
			rd_en <= 1'b1;
		else if (!cyc_i || ack1==1'b0) begin
			ack1 <= 1'b0;
			rd_en <= 1'b0;
			state <= IDLE;
		end
	end

endcase
end
endmodule
