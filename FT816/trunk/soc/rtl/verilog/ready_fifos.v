// ============================================================================
//        __
//   \\__/ o\    (C) 2013-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// ready_fifos.v
// - 512 entry fifos for ready list
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
module ready_fifos(rst, clk, rdy, cs, vda, rw, ad, i, o);
input rst;
input clk;
output rdy;
input cs;
input vda;
input rw;
input [4:0] ad;
input [7:0] i;
output reg [7:0] o;
 
reg [7:0] dil;      // input data latch

always @(posedge clk)
begin
    if (~rw & ~ad[0]) dil <= i;
end

reg rdy1;
always @(posedge clk)
    rdy1 <= cs & vda;
assign rdy = cs ? (rw ? rdy1 : 1'b1) : 1'b1;

wire cs0 = cs && vda && ad[3:1]==3'd0;
wire cs1 = cs && vda && ad[3:1]==3'd1;
wire cs2 = cs && vda && ad[3:1]==3'd2;
wire cs3 = cs && vda && ad[3:1]==3'd3;
wire cs4 = cs && vda && ad[3:1]==3'd4;

wire wr_en0 = cs0 & ~rw & ad[0] & ~ad[4];
wire wr_en1 = cs1 & ~rw & ad[0] & ~ad[4];
wire wr_en2 = cs2 & ~rw & ad[0] & ~ad[4];
wire wr_en3 = cs3 & ~rw & ad[0] & ~ad[4];
wire wr_en4 = cs4 & ~rw & ad[0] & ~ad[4];

wire rd_en0 = cs0 & rw & ~ad[0] & ~ad[4];
wire rd_en1 = cs1 & rw & ~ad[0] & ~ad[4];
wire rd_en2 = cs2 & rw & ~ad[0] & ~ad[4];
wire rd_en3 = cs3 & rw & ~ad[0] & ~ad[4];
wire rd_en4 = cs4 & rw & ~ad[0] & ~ad[4];

wire [8:0] dout0;
wire [8:0] dout1;
wire [8:0] dout2;
wire [8:0] dout3;
wire [8:0] dout4;

wire [8:0] data_count0;
wire [8:0] data_count1;
wire [8:0] data_count2;
wire [8:0] data_count3;
wire [8:0] data_count4;

ready_fifo ufifo0
(
  .clk(clk),                // input wire clk
  .srst(rst),               // input wire srst
  .din({i[0],dil}),        // input wire [8 : 0] din
  .wr_en(wr_en0),          // input wire wr_en
  .rd_en(rd_en0),           // input wire rd_en
  .dout(dout0),              // output wire [8 : 0] dout
  .full(),              // output wire full
  .empty(),            // output wire empty
  .data_count(data_count0)  // output wire [8 : 0] data_count
);

ready_fifo ufifo1
(
  .clk(clk),                // input wire clk
  .srst(rst),               // input wire srst
  .din({i[0],dil}),        // input wire [8 : 0] din
  .wr_en(wr_en1),          // input wire wr_en
  .rd_en(rd_en1),           // input wire rd_en
  .dout(dout1),              // output wire [8 : 0] dout
  .full(),              // output wire full
  .empty(),            // output wire empty
  .data_count(data_count1)  // output wire [8 : 0] data_count
);

ready_fifo ufifo2
(
  .clk(clk),                // input wire clk
  .srst(rst),               // input wire srst
  .din({i[0],dil}),        // input wire [8 : 0] din
  .wr_en(wr_en2),          // input wire wr_en
  .rd_en(rd_en2),           // input wire rd_en
  .dout(dout2),              // output wire [8 : 0] dout
  .full(),              // output wire full
  .empty(),            // output wire empty
  .data_count(data_count2)  // output wire [8 : 0] data_count
);

ready_fifo ufifo3
(
  .clk(clk),                // input wire clk
  .srst(rst),               // input wire srst
  .din({i[0],dil}),        // input wire [8 : 0] din
  .wr_en(wr_en3),          // input wire wr_en
  .rd_en(rd_en3),           // input wire rd_en
  .dout(dout3),              // output wire [8 : 0] dout
  .full(),              // output wire full
  .empty(),            // output wire empty
  .data_count(data_count3)  // output wire [8 : 0] data_count
);

ready_fifo ufifo4
(
  .clk(clk),                // input wire clk
  .srst(rst),               // input wire srst
  .din({i[0],dil}),        // input wire [8 : 0] din
  .wr_en(wr_en4),          // input wire wr_en
  .rd_en(rd_en4),           // input wire rd_en
  .dout(dout4),              // output wire [8 : 0] dout
  .full(),              // output wire full
  .empty(),            // output wire empty
  .data_count(data_count4)  // output wire [8 : 0] data_count
);

always @*
case(ad[4:0])
5'h00:  o <= dout0[7:0];
5'h01:  o <= {7'd0,dout0[8]}; 
5'h02:  o <= dout1[7:0];
5'h03:  o <= {7'd0,dout1[8]}; 
5'h04:  o <= dout2[7:0];
5'h05:  o <= {7'd0,dout2[8]}; 
5'h06:  o <= dout3[7:0];
5'h07:  o <= {7'd0,dout3[8]}; 
5'h08:  o <= dout4[7:0];
5'h09:  o <= {7'd0,dout4[8]}; 
5'h10:  o <= data_count0[7:0];
5'h11:  o <= {7'd0,data_count0[8]}; 
5'h12:  o <= data_count1[7:0];
5'h13:  o <= {7'd0,data_count1[8]}; 
5'h14:  o <= data_count2[7:0];
5'h15:  o <= {7'd0,data_count2[8]}; 
5'h16:  o <= data_count3[7:0];
5'h17:  o <= {7'd0,data_count3[8]}; 
5'h18:  o <= data_count4[7:0];
5'h19:  o <= {7'd0,data_count4[8]}; 
default:    o <= 8'h00;
endcase

endmodule
