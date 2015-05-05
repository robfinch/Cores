/*
ORSoC GFX accelerator core
Copyright 2012, ORSoC, Per Lenander, Anton Fosselius.

RENDERING MODULE

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
 Modified to support a greater number of color depths and pixels may be bit
 aligned in a 128 bit memory strip.
*/

module gfx_renderer(clk_i, rst_i,
	target_base_i, zbuffer_base_i, target_size_x_i, target_size_y_i, color_depth_i,
	pixel_x_i, pixel_y_i, pixel_z_i, zbuffer_enable_i, color_i,
	render_addr_o, render_dat_o,
	ack_o, ack_i,
	write_i, writez_o, write_o,
	mb_o, me_o
	);

parameter point_width = 16;
parameter BPP16 = 3'd5;
input clk_i;
input rst_i;

// Render target information, used for checking out of bounds and stride when writing pixels
input            [31:0] target_base_i;
input            [31:0] zbuffer_base_i;
input [point_width-1:0] target_size_x_i;
input [point_width-1:0] target_size_y_i;

input             [2:0] color_depth_i;

input [point_width-1:0] pixel_x_i;
input [point_width-1:0] pixel_y_i;
input [point_width-1:0] pixel_z_i;
input                   zbuffer_enable_i;
input            [31:0] color_i;

input      write_i;
output reg write_o;
output reg writez_o;

output reg [6:0] mb_o;
output reg [6:0] me_o;

// Output registers connected to the wbm
output reg [31:0] render_addr_o;
output reg [31:0] render_dat_o;

wire        [3:0] target_sel;
wire       [31:0] target_dat;
wire        [3:0] zbuffer_sel;
wire       [31:0] zbuffer_dat;

output reg ack_o;
input      ack_i;

// TODO: Fifo for incoming pixel data?



// Define memory address
// Addr[31:2] = Base + (Y*width + X) * ppb
wire [31:0] target_addr;
wire [31:0] zbuffer_offset;
wire [6:0] mb, me, mbz, mez;

gfx_CalcAddress u1
(
	.base_address_i(target_base_i),
	.color_depth_i(color_depth_i),
	.hdisplayed_i(target_size_x_i),
	.x_coord_i(pixel_x_i),
	.y_coord_i(pixel_y_i),
	.address_o(target_addr),
	.mb_o(mb),
	.me_o(me)
);

gfx_CalcAddress u2
(
	.base_address_i(zbuffer_base_i),
	.color_depth_i(BPP16),
	.hdisplayed_i(target_size_x_i),
	.x_coord_i(pixel_x_i),
	.y_coord_i(pixel_y_i),
	.address_o(zbuffer_addr),
	.mb_o(mbz),
	.me_o(mez)
);

assign target_dat = color_i;
assign zbuffer_dat = pixel_z_i[point_width-1:0];

// State machine
reg [1:0] state;
parameter wait_state        = 2'b00,
          write_pixel_state = 2'b01,
          write_z_state     = 2'b10;

// Acknowledge when a command has completed
always @(posedge clk_i)
begin
  //  reset, init component
  if(rst_i)
  begin
    write_o       <= 1'b0;
	writez_o      <= 1'b0;
    ack_o         <= 1'b0;
    render_addr_o <= 1'b0;
    render_dat_o  <= 1'b0;
	mb_o <= 7'd0;
	me_o <= 7'd0;
  end
  // Else, set outputs for next cycle
  else
  begin
    case (state)

      wait_state:
      begin
        ack_o   <= 1'b0;
        if(write_i)
        begin
          render_addr_o <= target_addr;
          render_dat_o  <= target_dat;
		  mb_o <= mb;
		  me_o <= me;
          write_o <= 1'b1;
        end
      end

      // Write pixel to memory. If depth buffering is enabled, write z value too
      write_pixel_state:
      begin
        if(ack_i)
        begin
          render_addr_o <= {zbuffer_addr,2'b00};
          render_dat_o  <= zbuffer_dat;
		  mb_o <= mbz;
		  me_o <= mez;
		  write_o <= 1'b0;
          writez_o       <= zbuffer_enable_i;
          ack_o         <= ~zbuffer_enable_i;
        end
        else
          write_o       <= 1'b0;
      end

      write_z_state:
      begin
        writez_o       <= 1'b0;
        ack_o         <= ack_i;
      end

    endcase
  end
end

// State machine
always @(posedge clk_i)
begin
  // reset, init component
  if(rst_i)
    state <= wait_state;
  // Move in statemachine
  else
    case (state)

      wait_state:
        if(write_i)
          state <= write_pixel_state;

      write_pixel_state:
        if(ack_i & zbuffer_enable_i)
          state <= write_z_state;
        else if(ack_i)
          state <= wait_state;

      write_z_state:
        if(ack_i)
          state <= wait_state;

    endcase
end

endmodule

