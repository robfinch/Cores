// ============================================================================
// (C) 2016-2022 Robert Finch
// rob<remove>@finitron.ca
// All Rights Reserved.
//
//	FAL6567j_tb.sv
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
module FAL6567j_tb();
reg rst;
reg clk;
wire phi02;
wire aec;
wire ba;
reg cs_n;
reg rw;
wire [7:0] ad;
reg [13:0] adr;
reg [13:0] ad14;
wire ras_n;
wire cas_n;
wire hSync;
wire vSync;
wire [7:0] db;
wire [3:0] db811;
reg [11:0] dbi;
wire [18:0] ram_adr;
wire [7:0] ram_dat;
wire ram_ce;
wire ram_we;
wire ram_oe;
wire TMDS_clk_p, TMDS_clk_n;
wire [2:0] TMDS_data_p, TMDS_data_n;
wire [3:0] luma;
reg clk100;
reg [7:0] displayRam [0:16383];
reg [3:0] colorRam [0:1023];
wire [7:0] displayRamOut = displayRam[ad14];
wire [3:0] colorRamOut = colorRam[ad14[9:0]];
integer a;

initial begin
  rst = 1'b1;
  clk = 1'b0;
  clk100 = 1'b0;
  #2000 rst = 1'b0;
end

integer n;
initial begin
	a = $urandom(1);
	for (n = 0; n < 16384; n = n + 1)
		displayRam[n] = $urandom();
	for (n = 0; n < 1024; n = n + 1)
		colorRam[n] = $urandom();
end

always #41.667 clk = ~clk;
always #5 clk100 <= ~clk100;

FAL6567j #(
  .pSimRasterEnable(1),
  .SIM(1'b1)
) u1
(
  .sysclk(clk),
  .phi02(phi02),
  .rst_o(),
  .irq(),
  .aec(aec),
  .ba(ba),
  .cs_n(cs_n),
  .rw(rw),
  .ad(ad),
  .db(db),
  .db811(db811),
  .ras_n(ras_n),
  .cas_n(cas_n),
  .lp_n(),
	.TMDS_OUT_clk_p(TMDS_clk_p),
	.TMDS_OUT_clk_n(TMDS_clk_n),
	.TMDS_OUT_data_p(TMDS_data_p),
	.TMDS_OUT_data_n(TMDS_data_n),
	.luma(luma)
);

reg [11:0] state;
reg phi02a;
always @(posedge clk)
  phi02a <= phi02;

always @(posedge clk)
if (rst) begin
  cs_n <= 1'b1;
  rw <= 1'b1;
  adr <= 8'hFF;
  state <= 12'd0;
end
else begin
  if (phi02 & !phi02a) begin
    state <= state + 1;
    case(state)
    5: begin
      cs_n <= 1'b0;
      rw <= 1'b0;
      adr <= 6'd17;
      end
    6: begin
        cs_n <= 1'b0;
        rw <= 1'b0;
        adr <= 6'd24;
        end
    7: begin
            cs_n <= 1'b0;
            rw <= 1'b0;
            adr <= 6'd21;
            end
    8: begin
      cs_n <= 1'b1;
      rw <= 1'b1;
      end
    endcase
    end
end

assign ad = phi02 & aec ? adr : 8'bz; 

// Capture address output by FAL6567 during ras and cas
always @(posedge clk100)
if (rst)
	ad14 <= 14'd0;
else begin
	if (!aec) begin
		if (!cas_n)
			ad14[13:8] <= ad[5:0];
		else if (!ras_n)
			ad14[7:0]<=  ad[7:0];
	end
	else
		ad14 <= adr;
end

always @(posedge clk)
if (rst)
  dbi <= 12'd0;
else begin
	if (phi02 && !phi02a) begin
		case(state)
		5:   dbi <= 12'h10;
		6:   dbi <= 12'h20;
		7:   dbi <= 12'hFE;
		default:
		casex (ad)
		14'b000xxxxxxxxxxx: dbi <= ad[7:0];
		14'h8xx:  if (!cas_n) dbi <= {ad[3:0],ad[7:0]};
		14'h3FFF: dbi <= 12'h000;
		default: dbi <= ad[11:0];
		endcase
		endcase
	end
end
assign db = aec ? dbi : displayRamOut;
assign db811 = aec ? 4'd0 : colorRamOut;

endmodule
