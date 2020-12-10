// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	nPower_tb.sv
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

module nPower_tb();
reg rst;
reg clk;
reg wc_clk;

initial begin
  rst = 0;
  clk = 0;
  wc_clk = 0;
  #10 rst = 1;
  #150 rst = 0;
end

always #5 clk = ~clk;
always #20 wc_clk = ~wc_clk;

wire cyc, stb, we;
wire [15:0] sel;
wire [31:0] adr;
wire [127:0] dato;
reg [127:0] dati;

wire br_ack;
wire [127:0] br_dato;
wire scratch_ack;
wire [127:0] scratch_dato;
wire cs_rom = adr[31:20]==12'hFFF;
wire cs_scratchmem = adr[31:16]==16'hFF40;

scratchmem128 uscrath1 (
  .rst_i(rst),
  .clk_i(clk),
  .cs_i(cs_scratchmem),
  .cyc_i(cyc),
  .stb_i(stb),
  .ack_o(scratch_ack),
  .we_i(we),
  .sel_i(sel),
  .adr_i(adr[15:0]),
  .dat_i(dato),
  .dat_o(scratch_dato),
  .sp()
);

bootrom128 ubr (
  .rst_i(rst),
  .clk_i(clk),
  .cs_i(cs_rom),
  .cyc_i(cyc),
  .stb_i(stb),
  .ack_o(br_ack),
  .adr_i(adr[17:0]),
  .dat_o(br_dato)
);

always @*
  if (cs_rom)
    dati = br_dato;
  else
    dati = scratch_dato;

nPower ucpu1 (
  .rst_i(rst),
  .clk_i(clk),
//  .wc_clk_i(wc_clk),
//  .nmi_i(1'b0),
//  .irq_i(1'b0),
//  .cause_i(8'h00),
  .vpa_o(),
  .cyc_o(cyc),
  .stb_o(stb),
  .ack_i(br_ack|scratch_ack),
  .sel_o(sel),
  .we_o(we),
  .adr_o(adr),
  .dat_i(dati),
  .dat_o(dato)
//  .sr_o(),
//  .cr_o(),
//  .rb_i(1'b0)
);

endmodule
