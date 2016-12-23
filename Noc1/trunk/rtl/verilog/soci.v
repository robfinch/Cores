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
`include "noc_defines.v"

module soci(num, rst, clk, neti, neto, mas, cyc, stb, ack, err, we, sel, adr, dati, dato);
parameter IDLE = 4'd1;
parameter READ = 4'd2;
parameter WRITE = 4'd3;
parameter TX = 4'd4;
parameter ERR = 4'd5;
parameter ERR_ACK = 4'd6;
input [3:0] num;
input rst;
input clk;
input [`PACKET_WID-1:0] neti;
output reg [`PACKET_WID-1:0] neto;
output reg [3:0] mas;
output reg cyc;
output reg stb;
input ack;
input err;
output reg we;
output reg [3:0] sel;
output reg [31:0] adr;
input [31:0] dati;
output reg [31:0] dato;

reg [`PACKET_WID-1:0] packeto;
reg needack;
reg [3:0] state;

always @(posedge clk)
if (rst) begin
  wb_nack();
  state <= IDLE;
  neto <= {`PACKET_WID{1'b0}};
end
else begin
  case (state)
  IDLE:
    if (neti[`RID]==num) begin
      mas <= neti[`TID];
      cyc <= 1'b1;
      stb <= 1'b1;
      we <= neti[68];
      sel <= neti[67:64];
      adr <= neti[63:32];
      dato <= neti[31:0];
      needack <= neti[69];
      if (neti[68]==1'b0)
        state <= READ;
      else
        state <= WRITE;
      packeto[`RID] <= neti[`TID];
      packeto[`TID] <= neti[`RID];
      packeto[`ACK] <= 1'b1;
      packeto[`AGE] <= 8'h00;
      // Remove input packet from ring
      neto <= 128'd0;
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
      if (ack|err) begin
        wb_nack();
        packeto[31:0] <= dati;
        state <= err ? ERR : TX;
      end
    end
  WRITE:
    begin
      EchoAged();
      if (ack|err) begin
        wb_nack();
        state <= err ? ERR : needack ? TX : IDLE;
//        state <= IDLE;
      end
    end
  // Here we are waiting for an opening to transmit
  TX:
    if (neti[`RID]==4'h0) begin
      neto <= packeto;
      state <= IDLE;
    end
    else begin
      EchoAged();
    end 
  // Acknowledge a bus error. Clears the bus error circuit.
  ERR:
    begin
      EchoAged();
      cyc <= 1'b1;
      stb <= 1'b1;
      adr <= 32'hFFDCFFE0;
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
  cyc <= 1'b0;
  stb <= 1'b0;
  we <= 1'b0;
  sel <= 4'h0;
end
endtask

task EchoAged;
begin
  if (neti[`AGE]==6'h3F)
    neto <= 128'd0;
  else begin
    neto <= neti;
    if (neti[`RID]!=4'h0)
      neto[`AGE] <= neti[`AGE] + 1; // age the packet
  end
end
endtask

endmodule
