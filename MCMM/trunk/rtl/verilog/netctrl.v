`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	netctrl.v
//  - network controller for network on chip
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
//
// ============================================================================
//
`include "noc_defines.vh"

module netctrl(num, rst_i, clk_i, cs_i, cyc_i, stb_i, ack_o, we_i, adr_i, dat_i, dat_o, net_i, net_o);
input [5:0] num;
input rst_i;
input clk_i;
input cs_i;
input cyc_i;
input stb_i;
output ack_o;
input we_i;
input [31:0] adr_i;
input [31:0] dat_i;
output reg [31:0] dat_o;
input [`PACKET_WID-1:0] net_i;
output reg [`PACKET_WID-1:0] net_o;

reg rxp;
reg txp;
reg acko;
reg [`PACKET_WID-1:0] packeti;
wire [`PACKET_WID-1:0] rpacketi;
reg [`PACKET_WID-1:0] packeto;
wire cs = cyc_i & stb_i & cs_i;
assign ack_o = cs ? (we_i ? 1'b1 : acko) : 1'b0;

reg [5:0] ptr, ptr_inc;
vtdl #(.WID(`PACKET_WID), .DEP(64)) ufifo1
(
  .clk(clk_i),
  .ce(rxp),
  .a(ptr-6'd1),
  .d(packeti),
  .q(rpacketi)
);

always @(posedge clk_i)
if (rst_i) begin
  txp <= 1'b0;
  rxp <= 1'b0;
  acko <= 1'b0;
  dat_o <= 32'd0;
  ptr <= 6'h00;
  net_o <= {`PACKET_WID{1'b0}};
end
else begin
  rxp <= 1'b0;
  ptr_inc = 6'd0;
  // If it's my own packet that's come around again that means it wasn't
  // received, let it go round again.
  // OR transmit a waiting packet output.
  if (net_i[`TID]==num) begin
    net_o <= net_i;
  end
  // If it's a packet addressed to me, or a general broacast
  else if (net_i[`RID]==num || net_i[`RID]==`GBL) begin
    if (net_i[`RID]==num) begin
      // If it was an ack from a prior transmit zap the
      // packet. If we're waiting to transmit then transmit.
      if (net_i[`ACK]) begin
        if (txp) begin
          net_o <= packeto;
          txp <= 1'b0;
        end
        else
          net_o <= {`PACKET_WID{1'b0}};
      end
      // Otherwise, it wasn't an ack, and it was for us so
      // queue the packet in a fifo and send back an ack.
      else begin
        rxp <= 1'b1;
        packeti <= net_i;
        ptr_inc = 6'd1;
        net_o <= net_i;
        net_o[`RID] <= net_i[`TID];
        net_o[`TID] <= net_i[`RID];
        net_o[`ACK] <= 1'b1;
      end
    end
    // General broadcast, queue packet, but don't ack.
    // Forward the broadcast to the next node.
    else begin
      rxp <= 1'b1;
      packeti <= net_i;
      ptr_inc = 6'd1;
      net_o <= net_i;
    end
  end
  // Otherwise, not a packet for me. See if it's an empty
  // packet, which will allow us to transmit if need be.
  else if (net_i[`RID]==4'h0 && txp) begin
    net_o <= packeto;
    txp <= 1'b0;
  end
  // Otherwise ignore the packet.
  else begin
    net_o <= net_i;
  end

  // WISHBONE I/F
  if (cs) begin
    if (we_i) begin
      case(adr_i[4:2])
      3'd0: packeto[31:0] <= dat_i;
      3'd1: packeto[63:32] <= dat_i;
      3'd2: begin
            packeto[95:64] <= dat_i;
            packeto[`TID] <= num;  // insert our number
            packeto[`ACK] <= 1'b0; // clear ack bit
            end
      3'd6: txp <= 1'b1;
      endcase
    end
    else begin
      case(adr_i[4:2])
      3'd0: dat_o <= rpacketi[31:0];
      3'd1: dat_o <= rpacketi[63:32];
      3'd2: dat_o <= rpacketi[95:64];
      3'd6: begin
            ptr_inc = ptr_inc - 6'd1;
            if (ptr_inc[5] && ptr != 0)  // if ptr_inc is minus
              ptr <= ptr + ptr_inc;
            else if (ptr < 6'h3F)
              ptr <= ptr + ptr_inc; 
            ptr_inc = 6'd0;
            end
      3'd7: dat_o <= {num,txp,7'b0,2'b0,ptr};
      default:  dat_o <= 32'd0;
      endcase
      acko <= 1'b1;
    end
  end
  else begin
    acko <= 1'b0;
  end
  if (ptr < 6'h3F)
    ptr <= ptr + ptr_inc; 
end

endmodule
