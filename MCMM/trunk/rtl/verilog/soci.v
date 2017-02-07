`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	soci.v
//  - intefaces to global devices
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

module soci(num, rst_i, clk_i, net_i, net_o, mas, cyc_o, stb_o, ack_i, err_i, we_o, sel_o, adr_o, dat_i, dat_o);
parameter IDLE = 4'd1;
parameter READ = 4'd2;
parameter WRITE = 4'd3;
parameter TX = 4'd4;
parameter ERR = 4'd5;
parameter ERR_ACK = 4'd6;
input [5:0] num;
input rst_i;
input clk_i;
input [`PACKET_WID-1:0] net_i;
output reg [`PACKET_WID-1:0] net_o;
output reg [5:0] mas;
output reg cyc_o;
output reg stb_o;
input ack_i;
input err_i;
output reg we_o;
output reg [3:0] sel_o;
output reg [31:0] adr_o;
input [31:0] dat_i;
output reg [31:0] dat_o;

reg [`PACKET_WID-1:0] packeto;
reg needack;
reg [3:0] state;

always @(posedge clk_i)
if (rst_i) begin
  wb_nack();
  state <= IDLE;
  net_o <= {`PACKET_WID{1'b0}};
end
else begin
  case (state)
  IDLE:
    if (net_i[`RID]==num) begin
      mas <= net_i[`TID];
      cyc_o <= 1'b1;
      stb_o <= 1'b1;
      we_o <= net_i[68];
      sel_o <= net_i[67:64];
      adr_o <= net_i[63:32];
      dat_o <= net_i[31:0];
      needack <= net_i[69];
      if (net_i[68]==1'b0)
        state <= READ;
      else
        state <= WRITE;
      packeto[`RID] <= net_i[`TID];
      packeto[`TID] <= net_i[`RID];
      packeto[`ACK] <= 1'b1;
      packeto[`AGE] <= 8'h00;
      // Remove input packet from ring
      net_o <= {`PACKET_WID{1'b0}};
    end
    // Packet wasn't for me.
    else begin
      EchoAged();
    end
  READ:
    begin
      // Can't process any more packets while in read state.
      // Just echo them around the ring.
      EchoAged();
      if (ack_i|err_i) begin
        wb_nack();
        packeto[31:0] <= dat_i;
        state <= err_i ? ERR : TX;
      end
    end
  WRITE:
    begin
      EchoAged();
      if (ack_i|err_i) begin
        wb_nack();
        state <= err_i ? ERR : needack ? TX : IDLE;
//        state <= IDLE;
      end
    end
  // Here we are waiting for an opening to transmit
  TX:
    if (net_i[`RID]==6'h0) begin
      net_o <= packeto;
      state <= IDLE;
    end
    else begin
      EchoAged();
    end 
  // Acknowledge a bus error. Clears the bus error circuit.
  ERR:
    begin
      EchoAged();
      cyc_o <= 1'b1;
      stb_o <= 1'b1;
      adr_o <= 32'hFFDCFFE0;
      state <= ERR_ACK;
    end
  // The bus error circuit doesn't bother to send back an ack in case the
  // ack line is broken. It's safe to assume it's reset after a single cycle. 
  ERR_ACK:
    begin
      EchoAged();
      wb_nack();
      state <= needack ? TX : IDLE;
    end
  endcase
end

task wb_nack;
begin
  cyc_o <= 1'b0;
  stb_o <= 1'b0;
  we_o <= 1'b0;
  sel_o <= 4'h0;
end
endtask

task EchoAged;
begin
  if (net_i[`AGE]==6'h3F)
    net_o <= {`PACKET_WID{1'b0}};
  else begin
    net_o <= net_i;
    if (net_i[`RID]!=6'h0)
      net_o[`AGE] <= net_i[`AGE] + 1; // age the packet
  end
end
endtask

endmodule
