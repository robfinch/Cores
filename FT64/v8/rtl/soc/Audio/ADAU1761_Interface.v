// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// ADAU1761_Interface
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
module ADAU1761_Interface(rst_i, 
	clk_i, cs_i, cyc_i, stb_i, ack_o, we_i, dat_i,
	aud0_i, aud2_i, audi_o,
	ac_mclk_i, ac_bclk_o, ac_lrclk_o, ac_adc_sdata_i, ac_dac_sdata_o,
	en_rxtx_o, en_tx_o,
	record_i, playback_i
);
input rst_i;
input clk_i;
input cs_i;
input cyc_i;
input stb_i;
output reg ack_o;
input we_i;
input [7:0] dat_i;
input [15:0] aud0_i;
input [15:0] aud2_i;
output reg [15:0] audi_o;
input ac_mclk_i;
output ac_bclk_o;
tri ac_bclk_o;
output ac_lrclk_o;
tri ac_lrclk_o;
input ac_adc_sdata_i;
output ac_dac_sdata_o;
input record_i;
input playback_i;
output reg en_rxtx_o;
output reg en_tx_o;

reg en_rx;
reg en_tx;
wire pe_record, ne_record;
wire pe_playback, ne_playback;
edge_det u1 (.clk(clk_i), .ce(1'b1), .i(record_i), .pe(pe_record), .ne(ne_record), .ee());
edge_det u2 (.clk(clk_i), .ce(1'b1), .i(playback_i), .pe(pe_playback), .ne(ne_playback), .ee());

always @(posedge clk_i)
begin
	if (pe_record)
		en_rx <= 1'b1;
	if (ne_record)
		en_rx <= 1'b0;
	if (pe_playback)
		en_tx <= 1'b1;
	if (ne_playback)
		en_tx <= 1'b0;
	if (cs_i & cyc_i & stb_i & we_i) begin
		en_tx <= dat_i[1];
		en_rx <= dat_i[0];
	end
end
wire en_rxtx = en_tx|en_rx;
always @(posedge clk_i)
	ack_o <= cs_i & cyc_i & stb_i;
always @(posedge clk_i)
	en_rxtx_o <=  en_rxtx;
always @(posedge clk_i)
	en_tx_o <= en_tx;

reg [3:0] bclk;
reg [63:0] lrclk;
reg [31:0] ldato, rdato, ain;
reg [63:0] sdato;
assign ac_bclk_o = bclk[3];
assign ac_lrclk_o = lrclk[63];
assign ac_dac_sdata_o = sdato[31];

always @(posedge ac_mclk_i)
if (rst_i)
  bclk <= 4'b0011;
else
  bclk <= {bclk[2:0],bclk[3]};

always @(posedge ac_mclk_i)
if (rst_i)
  lrclk <= 64'hFFFFFFFF00000000;
else
  lrclk <= {lrclk[62:0],lrclk[63]};

always @(posedge ac_mclk_i)
if (rst_i) begin
	audi_o <= 16'h0;
  sdato <= {1'b0,aud0_i,16'h0000,aud2_i[15:1]};
end
else begin
  if (bclk==4'b1001) begin
    if (lrclk==64'h800000007FFFFFFF)
      sdato <= {aud0_i,16'h0000,aud2_i,16'h0000};
    else
      sdato <= {sdato[62:0],1'b0};
  end
  if (bclk==4'b1100) begin
    ain <= {ain[30:0],ac_adc_sdata_i};
    if (lrclk==64'hFFFFFFFC00000003 || lrclk==64'h00000003FFFFFFFC)
      audi_o <= {ain[14:0],ac_adc_sdata_i};
  end
end

endmodule
