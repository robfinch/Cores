`timescale 1ns / 10ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2023-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//                                                                          
// ============================================================================

import fta_bus_pkg::*;
//import rf8088_pkg::SIM;

//import nic_pkg::*;

//`define USE_GATED_CLOCK	1'b1
//`define HAS_MMU 1'b1
//`define HAS_FRAME_BUFFER 1'b1

module rf8088_soc(cpu_resetn, xclk, led, sw, btnl, btnr, btnc, btnd, btnu, 
  kclk, kd, uart_txd, uart_rxd,
  TMDS_OUT_clk_p, TMDS_OUT_clk_n, TMDS_OUT_data_p, TMDS_OUT_data_n,
  ac_mclk, ac_adc_sdata, ac_dac_sdata, ac_bclk, ac_lrclk,
  rtc_clk, rtc_data,
  spiClkOut, spiDataIn, spiDataOut, spiCS_n,
  sd_cmd, sd_dat, sd_clk, sd_cd, sd_reset,
  pti_clk, pti_rxf, pti_txe, pti_rd, pti_wr, pti_siwu, pti_oe, pti_dat, spien,
  oled_sdin, oled_sclk, oled_dc, oled_res, oled_vbat, oled_vdd
  ,ddr3_ck_p,ddr3_ck_n,ddr3_cke,ddr3_reset_n,ddr3_ras_n,ddr3_cas_n,ddr3_we_n,
  ddr3_ba,ddr3_addr,ddr3_dq,ddr3_dqs_p,ddr3_dqs_n,ddr3_dm,ddr3_odt
//    gtp_clk_p, gtp_clk_n,
//    dp_tx_hp_detect, dp_tx_aux_p, dp_tx_aux_n, dp_rx_aux_p, dp_rx_aux_n,
//    dp_tx_lane0_p, dp_tx_lane0_n, dp_tx_lane1_p, dp_tx_lane1_n
);
input cpu_resetn;
input xclk;
output reg [7:0] led;
input [7:0] sw;
input btnl;
input btnr;
input btnc;
input btnd;
input btnu;
inout kclk;
tri kclk;
inout kd;
tri kd;
output uart_txd;
input uart_rxd;
output TMDS_OUT_clk_p;
output TMDS_OUT_clk_n;
output [2:0] TMDS_OUT_data_p;
output [2:0] TMDS_OUT_data_n;
output ac_mclk;
input ac_adc_sdata;
output reg ac_dac_sdata;
inout reg ac_bclk;
inout reg ac_lrclk;
inout rtc_clk;
tri rtc_clk;
inout rtc_data;
tri rtc_data;
output spiCS_n;
output spiClkOut;
output spiDataOut;
input spiDataIn;
inout sd_cmd;
tri sd_cmd;
inout [3:0] sd_dat;
tri [3:0] sd_dat;
output sd_clk;
input sd_cd;
output sd_reset;
input pti_clk;
input pti_rxf;
input pti_txe;
output pti_rd;
output pti_wr;
input spien;
output pti_siwu;
output pti_oe;
inout [7:0] pti_dat;
output oled_sdin;
output oled_sclk;
output oled_dc;
output oled_res;
output oled_vbat;
output oled_vdd;

output [0:0] ddr3_ck_p;
output [0:0] ddr3_ck_n;
output [0:0] ddr3_cke;
output ddr3_reset_n;
output ddr3_ras_n;
output ddr3_cas_n;
output ddr3_we_n;
output [2:0] ddr3_ba;
output [14:0] ddr3_addr;
inout [15:0] ddr3_dq;
inout [1:0] ddr3_dqs_p;
inout [1:0] ddr3_dqs_n;
output [1:0] ddr3_dm;
output [0:0] ddr3_odt;

fta_cmd_request128_t cpu_req;
fta_cmd_response128_t cpu_resp;
wire clk100, clk200;
wire cpu_clk = clk100;
wire xrst = ~cpu_resetn;
wire locked;
wire rst = ~locked;
fta_cmd_response64_t leds_cresp;
fta_cmd_response128_t [6:0] resps;

rf8088clk clkgen
(
  // Clock out ports
  .clk200(clk200),
  .clk100(clk100),
  // Status and control signals
  .reset(xrst),
  .locked(locked),
 // Clock in ports
  .clk_in1(xclk)
);

wire cs_io2 = cpu_req.padr[31:20]==12'hFD0;
wire cs_config = cpu_req.padr[31:28]==4'hD;

wire cs_leds = cpu_req.padr[19:8]==12'hFFF && cpu_req.stb && cs_io2;
wire cs_br3_leds = cpu_req.padr[31:8]==24'hFEDFFF && cpu_req.stb;

ledport_fta64 uleds1
(
	.rst(rst),
	.clk(cpu_clk),
	.cs(cs_br3_leds),
	.req(cpu_req),
	.resp(leds_cresp),
	.led(led)
);

scratchmem128pci_fta
#(
	.IO_ADDR(32'hFFF80001),
	.CFG_FUNC(3'd0)
)
uscr1
(
	.rst_i(rst),
	.cs_config_i(cs_config),
	.cs_ram_i(cpu_req.padr[31:24]==8'hFF),
	.clk_i(cpu_clk),
	.req(cpu_req),
	.resp(resps[4]),
	.ip('d0),
	.sp('d0)
);

fta_respbuf #(.CHANNELS(7)) urspbuf1
(
	.rst(rst),
	.clk(cpu_clk),
	.resp(resps),
	.resp_o(cpu_resp)
);

/*
assign resps[0] = fta_cmd_response128_t'(ch7resp);
assign resps[1] = br1_resp;
assign resps[2] = br3_resp;
assign resps[3].cid = cpu_cid;
assign resps[3].tid = cpu_tid;
assign resps[3].ack = sema_ack;
assign resps[3].next = 1'b0;
assign resps[3].dat = {4{sema_dato}};
assign resps[3].adr = cpu_adr;
assign resps[5] = br4_resp;
*/

rf8088_mpu umpu1
(
	.rst(rst),
	.clk(cpu_clk),
	.fta_req(cpu_req),
	.fta_resp(cpu_resp)
);

endmodule
