// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DSD9_bench.v
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
module DSD9_bench();

reg rst;
reg clk;
wire irdy;
wire [31:0] adr;
wire [127:0] idat;
wire [127:0] odat;
wire [127:0] sr_dat;
wire [127:0] mm_dat;
wire wr;
wire [15:0] sel;
wire cyc;
wire stb;
wire tc1_ack,sr_ack,mm_ack,br_ack,leds_ack,tc2_ack,btn_ack;
wire [31:0] tc1_dato,tc2_dato;
wire [127:0] vb1_dato;
wire vb1_ack;
wire video_cyc;
wire video_stb;
wire [31:0] video_adr;
wire [31:0] video_dato;
wire [31:0] btn_dat;
reg [31:0] btn_dat1;
wire btn_cs;
wire video_wr;
wire sseg_ack;
integer seed;

initial begin
    seed = 0;
    #0 rst = 1'b0;
    #0 clk = 1'b0;
    #20 rst = 1'b1;
    #80 rst = 1'b0;
end

always #5 clk = ~clk;

DSD9_mpu u1
(
    .hartid_i(32'd1),
    .rst_i(rst),
    .clk_i(clk),
    .cyc_o(cyc),
    .stb_o(stb),
    .ack_i(br_ack|vb1_ack|sr_ack|mm_ack|leds_ack|sseg_ack|tc2_ack|btn_ack),
    .wr_o(wr),
    .sel_o(sel),
    .adr_o(adr),
    .dat_i(idat|sr_dat|{4{vb1_dato}}|{4{mm_dat}}|{4{tc2_dato}}|{4{btn_dat}}),
    .dat_o(odat),
    .sr_o(),
    .cr_o(),
    .rb_i()
);

bootrom u2
(
    .rst_i(rst),
    .clk_i(clk),
    .cyc_i(cyc),
    .stb_i(stb),
    .ack_o(br_ack),
    .adr_i(adr),
    .dat_o(idat)
);

scratchram u3
(
    .rst_i(rst),
    .clk_i(clk),
    .cyc_i(cyc),
    .stb_i(stb),
    .wr_i(wr),
    .ack_o(sr_ack),
    .sel_i(sel),
    .adr_i(adr),
    .dat_i(odat),
    .dat_o(sr_dat)
);

assign sseg_ack = cyc && stb && (adr[31:4]== 28'hFFDC008);

mainMemory_sim u4
(
    .rst_i(rst),
    .clk_i(clk),
    .cyc_i(cyc),
    .stb_i(stb),
    .wr_i(wr),
    .ack_o(mm_ack),
    .sel_i(sel),
    .adr_i(adr),
    .dat_i(odat),
    .dat_o(mm_dat)
);

IOBridge vb1
(
    .rst_i(rst),
    .clk_i(clk),

    .s_cyc_i(cyc),
    .s_stb_i(stb),
    .s_ack_o(vb1_ack),
    .s_sel_i(sel),
    .s_we_i(wr),
    .s_adr_i(adr),
    .s_dat_i(odat),
    .s_dat_o(vb1_dato),
    
	.m_cyc_o(video_cyc),
	.m_stb_o(video_stb),
	.m_ack_i(tc1_ack),
	.m_we_o(video_wr),
	.m_sel_o(),
	.m_adr_o(video_adr),
	.m_dat_i(tc1_dato),
	.m_dat_o(video_dato)
);

DSD9_TextController #(.num(1)) tc1
(
	.rst_i(rst),
	.clk_i(clk),
	.cyc_i(video_cyc),
	.stb_i(video_stb),
	.ack_o(tc1_ack),
	.wr_i(video_wr),
	.adr_i(video_adr),
	.dat_i(video_dato),
	.dat_o(tc1_dato),
	.lp(),
	.curpos(),
	.vclk(),
	.hsync(),
	.vsync(),
	.blank(),
	.border(),
	.rgbIn(),
	.rgbOut()
);

DSD9_TextController #(.num(2),.pTextAddress(32'hFFD10000),.pRegAddress(32'hFFDA0100)) tc2
(
	.rst_i(rst),
	.clk_i(clk),
	.cyc_i(video_cyc),
	.stb_i(video_stb),
	.ack_o(tc2_ack),
	.wr_i(video_wr),
	.adr_i(video_adr),
	.dat_i(video_dato),
	.dat_o(tc2_dato),
	.lp(),
	.curpos(),
	.vclk(),
	.hsync(),
	.vsync(),
	.blank(),
	.border(),
	.rgbIn(),
	.rgbOut()
);

assign leds_ack = cyc && stb && (adr[31:8]==24'hFFDC06);

always @(posedge clk)
begin
    $display("%d", $time);
    $display("  %h %h %h", u1.u1.pc, u1.u1.insn, u1.u1.iinsn);
    $display("  dir=%h", u1.u1.dir);
    $display("  xir=%h", u1.u1.xir);
end

assign btn_cs = cyc && stb && (adr[31:4]==28'hFFDC009);
assign btn_dat = btn_cs ? btn_dat1 : 32'd0;
assign btn_ack = btn_cs;

always @(posedge clk)
    btn_dat1 <= $random(seed) % 32;

endmodule
