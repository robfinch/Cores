// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64SoC.v
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
module FT64SoC(cpu_resetn, xclk, led, sw,
    gtp_clk_p, gtp_clk_n,
    dp_tx_hp_detect, dp_tx_aux_p, dp_tx_aux_n, dp_rx_aux_p, dp_rx_aux_n,
    dp_tx_lane0_p, dp_tx_lane0_n, dp_tx_lane1_p, dp_tx_lane1_n
);
input cpu_resetn;
input xclk;
output reg [7:0] led;
input [7:0] sw;
input gtp_clk_p;
input gtp_clk_n;
input dp_tx_hp_detect;
output dp_tx_aux_p;
output dp_tx_aux_n;
input dp_rx_aux_p;
input dp_rx_aux_n;
output dp_tx_lane0_p;
output dp_tx_lane0_n;
output dp_tx_lane1_p;
output dp_tx_lane1_n;

wire rst;
wire xrst = ~cpu_resetn;
wire clk25, clk80, clk100, clk400;

wire cyc, stb, ack;
wire we;
wire [1:0] sel;
wire [31:0] adr;
wire [63:0] dati;
wire [63:0] dato;

NexysVideoClkgen ucg1
 (
  // Clock out ports
  .clk100(clk100),
  .clk400(clk400),
  .clk80(clk80),
  .clk25(clk25),
  // Status and control signals
  .reset(xrst), 
  .locked(locked),       // output locked
 // Clock in ports
  .clk_in1(xclk)
);
assign rst = !locked;

top_level udp1
(
    .clk100(clk100),
    .debug(),
    .gtptxp({dp_tx_lane1_p,dp_tx_lane0_p}),
    .gtptxn({dp_tx_lane1_n,dp_tx_lane0_n}),
    .refclk0_p(gtp_clk_p),
    .refclk0_n(gtp_clk_n), 
    .refclk1_p(gtp_clk_p),
    .refclk1_n(gtp_clk_n),
    .dp_tx_hp_detect(dp_tx_hp_detect),
    .dp_tx_aux_p(dp_tx_aux_p),
    .dp_tx_aux_n(dp_tx_aux_n),
    .dp_rx_aux_p(dp_rx_aux_p),
    .dp_rx_aux_n(dp_rx_aux_n)
);

wire cs_led = cyc && stb && (adr[31:4]==28'hFFDC060);
wire ack_led = cs_led;
always @(posedge clk25)
if (cs_led)
    led <= dato[7:0];
wire [7:0] led_dato = sw;

assign ack = ack_led;
assign dati = {8{led_dato}};

FT64 ucpu1
(
    .rst(rst),
    .clk(clk25),
    .irq_i(3'd0),
    .vec_i(9'h000),
    .cyc_o(cyc),
    .stb_o(stb),
    .ack_i(ack),
    .we_o(we),
    .sel_o(sel),
    .adr_o(adr),
    .dat_o(dato),
    .dat_i(dati)
);

endmodule
