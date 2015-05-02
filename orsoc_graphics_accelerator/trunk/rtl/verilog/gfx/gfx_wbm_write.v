/*
ORSoC GFX accelerator core
Copyright 2012, ORSoC, Per Lenander, Anton Fosselius.

The Wishbone master component will interface with the video memory, writing outgoing pixels to it.

Loosely based on the vga lcds wishbone writer (LGPL) in orpsocv2 by Julius Baxter, julius@opencores.org

 This file is part of orgfx.

 orgfx is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version. 

 orgfx is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public License
 along with orgfx.  If not, see <http://www.gnu.org/licenses/>.
 
 Robert Finch
 Modified: The writer queues up write data in a 128 bit buffer, which flushes
 when the buffer address changes. Read-modify-write cycles are used as the
 pixel data may be located on bit boundaries. The memory system in use loads
 or store 128 bit data at a time, so it's more memory efficient to use a 
 write cache. the buffer is snooped by the reader in case the pixel data
 needed during a read operation is located in the write buffer.
*/

//synopsys translate_off
`include "timescale.v"
//synopsys translate_on

module gfx_wbm_write (clk_i, rst_i,
                      cyc_o, stb_o, cti_o, bte_o, we_o, adr_o, sel_o, ack_i, err_i, dat_i, dat_o, sint_o,
                      write_i, writez_i, ack_o,
                      render_addr_i, render_dat_i, mb_i, me_i,
					  reader_addr_i, reader_match_o, reader_dat_o);

  // wishbone signals
  input         clk_i;    // master clock input
  input         rst_i;    // Asynchronous active high reset
  output reg    cyc_o;    // cycle output
  output        stb_o;    // strobe ouput
  output reg [15:0] sel_o;
  output [ 2:0] cti_o;    // cycle type id
  output [ 1:0] bte_o;    // burst type extension
  output reg    we_o;     // write enable output
  output reg [31:0] adr_o;    // address output
  input         ack_i;    // wishbone cycle acknowledge
  input         err_i;    // wishbone cycle error
  input  [127:0] dat_i;
  output reg [127:0] dat_o;    // wishbone data out           /// TEMP reg ///

  output        sint_o;     // non recoverable error, interrupt host

  // Renderer stuff
  input         write_i;
  input         writez_i;
  output reg    ack_o;

  input [31:0]  render_addr_i;
  input [31:0]  render_dat_i;
  input [6:0] mb_i;
  input [6:0] me_i;
  input [31:0] reader_addr_i;
  output reader_match_o;
  output reg [127:0] reader_dat_o;
 
parameter IDLE = 3'd1;
parameter READ128ACK = 3'd2;
parameter WRITEOLD = 3'd3;
parameter WRITEOLD2 = 3'd4;
parameter READ128 = 3'd5;
parameter UPDBUF = 3'd6;
parameter WAITACK = 3'd7;
  //
  // module body
  //
reg [127:0] o;
//  assign adr_o  = {render_addr_i[31:4], 4'h0};
  assign sint_o = err_i;
  // We only write, these can be constant
  assign stb_o  = 1'b1;
  assign cti_o  = 3'b000;
  assign bte_o  = 2'b00;

reg [31:4] bufadr;
reg [127:0] buf128;
reg [127:0] mask;
reg [127:0] o2;
reg [3:0] state;
reg dirty;
integer nn,n;
always @(mb_i or me_i or nn)
	for (nn = 0; nn < 128; nn = nn + 1)
		mask[nn] <= (nn >= mb_i) ^ (nn <= me_i) ^ (me_i >= mb_i);

always @*
begin
	o2 = render_dat_i << mb_i;
	for (n = 0; n < 128; n = n + 1) o[n] = (mask[n] ? o2[n] : buf128[n]);
end

  // Acknowledge when a command has completed
  always @(posedge clk_i)
  begin
    //  reset, init component
    if(rst_i)
    begin
      ack_o <= 1'b0;
      cyc_o <= 1'b0;
	  we_o <= 1'b0;
	  dirty <= 1'b0;
	  bufadr <= 32'hFFFFFFFF;
	  state <= IDLE;
    end
    // Else, set outputs for next cycle
    else
    begin
	case(state)
	IDLE:
		begin
			ack_o <= 1'b0;
			if (write_i) begin
				if (bufadr==render_addr_i[31:4])	// same buffer
					state <= UPDBUF;
				else
					state <= dirty ? WRITEOLD : READ128;
			end
			else if (writez_i) begin
				cyc_o <= 1'b1;
				we_o <= 1'b1;
				sel_o <= 16'h3 << mb_i[6:3];
				dat_o <= {8{render_dat_i[15:0]}};
				state <= WAITACK;
			end
		end
	WRITEOLD:
		begin
			cyc_o <= 1'b1;
			we_o <= 1'b1;
			sel_o <= 16'hFFFF;
			adr_o <= {bufadr,4'h0};
			dat_o <= buf128;
			state <= WRITEOLD2;
		end
	WRITEOLD2:
		if (ack_i) begin
			cyc_o <= 1'b0;
			we_o <= 1'b0;
			dirty <= 1'b0;
			state <= READ128;
		end
	READ128:
		begin
			cyc_o <= 1'b1;
			sel_o <= 16'hFFFF;
			adr_o <= {render_addr_i[31:4],4'h0};
			state <= READ128ACK;
		end
	READ128ACK:
		if (ack_i) begin
			cyc_o <= 1'b0;
			buf128 <= dat_i;
			bufadr <= render_addr_i[31:4];
			state <= UPDBUF;
		end
	UPDBUF:
		begin
			dirty <= 1'b1;
			ack_o <= 1'b1;
			buf128 <= o;
			state <= IDLE;
		end
	WAITACK:
		if (ack_i) begin
			cyc_o <= 1'b0;
			we_o <= 1'b0;
			sel_o <= 16'h0000;
			ack_o <= 1'b1;
			state <= IDLE;
		end
	endcase
    end
  end

assign reader_match_o = reader_addr_i[31:4]==bufadr;
always @(posedge clk_i)
begin
	if (reader_match_o)
		reader_dat_o <= buf128;
end

endmodule
