/*
ORSoC GFX accelerator core
Copyright 2012, ORSoC, Per Lenander, Anton Fosselius.

PER-PIXEL COLORING MODULE, alpha blending


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

*/

/*
This module performs alpha blending by fetching the pixel from the target and mixing it with the texel based on the current alpha value.

The exact formula is:
alpha = global_alpha_i * alpha_i
color_out = color_in * alpha + color_target * (1-alpha)       , where alpha is defined from 0 to 1 

alpha_i[7:0] is used, so the actual span is 0 (transparent) to 255 (opaque)

If alpha blending is disabled (blending_enable_i == 1'b0) the module just passes on the input pixel.
*/
module gfx_blender64(clk_i, rst_i,
  blending_enable_i, target_base_i, target_size_x_i, target_size_y_i, color_depth_i,
  x_counter_i, y_counter_i, z_i, alpha_i, global_alpha_i, write_i, ack_o,                      // from fragment
  target_ack_i, target_addr_o, target_data_i, target_sel_o, target_request_o, wbm_busy_i, // from/to wbm reader
  pixel_x_o, pixel_y_o, pixel_z_o, pixel_color_i, pixel_color_o, write_o, ack_i                      // to render
  );

parameter point_width = 16;

input                   clk_i;
input                   rst_i;

input                   blending_enable_i;
input            [31:3] target_base_i;
input [point_width-1:0] target_size_x_i;
input [point_width-1:0] target_size_y_i;
input             [1:0] color_depth_i;

// from fragment
input [point_width-1:0] x_counter_i;
input [point_width-1:0] y_counter_i;
input signed [point_width-1:0] z_i;
input             [7:0] alpha_i;
input             [7:0] global_alpha_i;
input            [31:0] pixel_color_i;
input                   write_i;
output reg              ack_o;

// Interface against wishbone master (reader)
input             target_ack_i;
output     [31:3] target_addr_o;
input      [31:0] target_data_i;
output reg  [7:0] target_sel_o;
output reg        target_request_o;
input             wbm_busy_i;

//to render
output reg [point_width-1:0] pixel_x_o;
output reg [point_width-1:0] pixel_y_o;
output reg signed [point_width-1:0] pixel_z_o;
output reg            [31:0] pixel_color_o;
output reg                   write_o;
input                        ack_i;

// State machine
reg [1:0] state;
parameter wait_state = 2'b00,
          target_read_state = 2'b01,
          write_pixel_state = 2'b10;

// Calculate alpha
reg [15:0] combined_alpha_reg;
wire [7:0] alpha = combined_alpha_reg[15:8];

// Calculate address of target pixel
// Addr[31:2] = Base + (Y*width + X) * ppb
reg [31:0] pixel_offset;
always @*
case(color_depth_i)
2'b00:	pixel_offset <= (target_size_x_i*y_counter_i + {16'h0, x_counter_i});
2'b01:	pixel_offset <= (target_size_x_i*y_counter_i + {16'h0, x_counter_i}) << 1;
2'b11:	pixel_offset <= (target_size_x_i*y_counter_i + {16'h0, x_counter_i}) << 2;
default:	pixel_offset <= 32'h0;
endcase

assign target_addr_o = target_base_i + pixel_offset[31:2];

function [7:0] R;
input [1:0] color_depth;
input [31:0] pixel_color;
case(color_depth)
2'b00:	R = pixel_color[5:0];
2'b01:	R = pixel_color[11:8];
2'b11:	R = pixel_color[23:16];
default:	R = 8'hFF;
endcase
endfunction

function [7:0] G;
input [1:0] color_depth;
input [31:0] pixel_color;
case(color_depth)
2'b00:	G = pixel_color[5:0];
2'b01:	G = pixel_color[7:4];
2'b11:	G = pixel_color[15:8];
default:	G = 8'h00;
endcase
endfunction

function [7:0] B;
input [1:0] color_depth;
input [31:0] pixel_color;
case(color_depth)
2'b00:	B = pixel_color[5:0];
2'b01:	B = pixel_color[3:0];
2'b11:	B = pixel_color[7:0];
default:	B = 8'h00;
endcase
endfunction

// Split colors for alpha blending (render color)
wire [7:0] blend_color_r = R(color_depth_i,pixel_color_i);
wire [7:0] blend_color_g = G(color_depth_i,pixel_color_i);
wire [7:0] blend_color_b = B(color_depth_i,pixel_color_i);

// Split colors for alpha blending (from target surface)
wire [7:0] target_color_r = R(color_depth_i,target_data_i);
wire [7:0] target_color_g = G(color_depth_i,target_data_i);
wire [7:0] target_color_b = B(color_depth_i,target_data_i);

// Alpha blending (per color channel):
// rgb = (alpha1)(rgb1) + (1-alpha1)(rgb2)
wire [15:0] alpha_color_r = blend_color_r * alpha + target_color_r * ~alpha;
wire [15:0] alpha_color_g = blend_color_g * alpha + target_color_g * ~alpha;
wire [15:0] alpha_color_b = blend_color_b * alpha + target_color_b * ~alpha;

wire [31:0] dest_color;
// Memory to color converter
memory_to_color64 memory_proc(
.color_depth_i (color_depth_i),
.mem_i (target_data_i),
.mem_lsb_i (x_counter_i[2:0]),
.color_o (dest_color),
.sel_o ()
);

// Acknowledge when a command has completed
always @(posedge clk_i or posedge rst_i)
begin
  // reset, init component
  if(rst_i)
  begin
    ack_o            <= 1'b0;
    write_o          <= 1'b0;
    pixel_x_o        <= 1'b0;
    pixel_y_o        <= 1'b0;
    pixel_z_o        <= 1'b0;
    pixel_color_o    <= 1'b0;
    target_request_o <= 1'b0;
    target_sel_o     <= 8'hFF;
  end
  // Else, set outputs for next cycle
  else
  begin
    case (state)

      wait_state:
      begin
        ack_o <= 1'b0;

        if(write_i)
        begin
          if(!blending_enable_i)
          begin
            pixel_x_o     <= x_counter_i;
            pixel_y_o     <= y_counter_i;
            pixel_z_o     <= z_i;
            pixel_color_o <= pixel_color_i;
            write_o       <= 1'b1;
          end
          else
          begin
            target_request_o   <= !wbm_busy_i;
            combined_alpha_reg <= alpha_i * global_alpha_i;
          end
        end
      end

      // Read pixel color at target (request is sent through the wbm reader arbiter).
      target_read_state:
        if(target_ack_i)
        begin
          // When we receive an ack from memory, calculate the combined color and send the pixel forward in the pipeline (go to write state)
          write_o          <= 1'b1;
          pixel_x_o        <= x_counter_i;
          pixel_y_o        <= y_counter_i;
          pixel_z_o        <= z_i;
          target_request_o <= 1'b0;

      	  // Recombine colors
      	  case(color_depth_i)
      	  2'b00: pixel_color_o <= {pixel_color_i[7:6],alpha_color_r[13:8]};
      	  2'b01: pixel_color_o <= {pixel_color_i[15:12],alpha_color_r[11:8], alpha_color_g[11:8], alpha_color_b[11:8]};
      	  2'b11: pixel_color_o <= {pixel_color_i[31:24],alpha_color_r[15:8], alpha_color_g[15:8], alpha_color_b[15:8]};
      	  default:	pixel_color_o <= 32'hFFFF0000;
      		endcase
        end
        else
          target_request_o <= !wbm_busy_i | target_request_o;

      // Ack and return to wait state
      write_pixel_state:
      begin
        write_o <= 1'b0;
        if(ack_i)
          ack_o <= 1'b1;    
      end

    endcase
  end
end

// State machine
always @(posedge clk_i or posedge rst_i)
begin
  // reset, init component
  if(rst_i)
    state <= wait_state;
  // Move in statemachine
  else
    case (state)

      wait_state:
        if(write_i & blending_enable_i)
          state <= target_read_state;
        else if(write_i)
          state <= write_pixel_state;

      target_read_state:
        if(target_ack_i)
          state <= write_pixel_state;

      write_pixel_state:
        if(ack_i)
          state <= wait_state;

    endcase
end

endmodule

