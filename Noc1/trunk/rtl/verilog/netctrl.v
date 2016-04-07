`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
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
`include "noc_defines.v"

module netctrl(num, rst, clk, cyc, stb, ack, we, adr, dati, dato, neti, neto);
input [3:0] num;
input rst;
input clk;
input cyc;
input stb;
output ack;
input we;
input [31:0] adr;
input [31:0] dati;
output reg [31:0] dato;
input [`PACKET_WID-1:0] neti;
output reg [`PACKET_WID-1:0] neto;

reg rxp;
reg txp;
reg acko;
reg [`PACKET_WID-1:0] packeti;
wire [`PACKET_WID-1:0] rpacketi;
reg [`PACKET_WID-1:0] packeto;
wire cs = cyc && stb && adr[31:16]==16'hFFD8;
assign ack = cs ? (we ? 1'b1 : acko) : 1'b0;

reg [5:0] ptr, ptr_inc;
vtdl #(.WID(`PACKET_WID), .DEP(64)) ufifo1
(
  .clk(clk),
  .ce(rxp),
  .a(ptr-6'd1),
  .d(packeti),
  .q(rpacketi)
);

always @(posedge clk)
if (rst) begin
  txp <= 1'b0;
  rxp <= 1'b0;
  acko <= 1'b0;
  dato <= 32'd0;
  ptr <= 6'h00;
  neto <= {`PACKET_WID{1'b0}};
end
else begin
  rxp <= 1'b0;
  ptr_inc = 6'd0;
  // If it's my own packet that's come around again that means it wasn't
  // received, let it go round again.
  // OR transmit a waiting packet output.
  if (neti[`TID]==num) begin
    neto <= neti;
  end
  // If it's a packet addressed to me, or a general broacast
  else if (neti[`RID]==num || neti[`RID]==`GBL) begin
    if (neti[`RID]==num) begin
      // If it was an ack from a prior transmit zap the
      // packet. If we're waiting to transmit then transmit.
      if (neti[`ACK]) begin
        if (txp) begin
          neto <= packeto;
          txp <= 1'b0;
        end
        else
          neto <= 128'b0;
      end
      // Otherwise, it wasn't an ack, and it was for us so
      // queue the packet in a fifo and send back an ack.
      else begin
        rxp <= 1'b1;
        packeti <= neti;
        ptr_inc = 6'd1;
        neto <= neti;
        neto[`RID] <= neti[`TID];
        neto[`TID] <= neti[`RID];
        neto[`ACK] <= 1'b1;
      end
    end
    // General broadcast, queue packet, but don't ack.
    // Forward the broadcast to the next node.
    else begin
      rxp <= 1'b1;
      packeti <= neti;
      ptr_inc = 6'd1;
      neto <= neti;
    end
  end
  // Otherwise, not a packet for me. See if it's an empty
  // packet, which will allow us to transmit if need be.
  else if (neti[`RID]==4'h0 && txp) begin
    neto <= packeto;
    txp <= 1'b0;
  end
  // Otherwise ignore the packet.
  else begin
    neto <= neti;
  end

  // WISHBONE I/F
  if (cs) begin
    if (we) begin
      case(adr[4:2])
      3'd0: packeto[31:0] <= dati;
      3'd1: packeto[63:32] <= dati;
      3'd2: begin
            packeto[95:64] <= dati;
            packeto[`TID] <= num;  // insert our number
            packeto[`ACK] <= 1'b0; // clear ack bit
            end
      3'd6: txp <= 1'b1;
      endcase
    end
    else begin
      case(adr[4:2])
      3'd0: dato <= rpacketi[31:0];
      3'd1: dato <= rpacketi[63:32];
      3'd2: dato <= rpacketi[95:64];
      3'd6: begin
            ptr_inc = ptr_inc - 6'd1;
            if (ptr_inc[5] && ptr != 0)  // if ptr_inc is minus
              ptr <= ptr + ptr_inc;
            else if (ptr < 6'h3F)
              ptr <= ptr + ptr_inc; 
            ptr_inc = 6'd0;
            end
      3'd7: dato <= {num,txp,7'b0,2'b0,ptr};
      default:  dato <= 32'd0;
      endcase
      acko <= 1'b1;
    end
  end
  else begin
    acko <= 1'b0;
    dato <= 32'h0;
  end
  if (ptr < 6'h3F)
    ptr <= ptr + ptr_inc; 
end

endmodule
