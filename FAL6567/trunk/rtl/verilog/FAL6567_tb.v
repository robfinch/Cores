// ============================================================================
// (C) 2016 Robert Finch
// rob<remove>@finitron.ca
// All Rights Reserved.
//
//	FAL6567_tb.v
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
module FAL6567_tb();
reg rst;
reg clk;
wire phi02;
wire aec;
wire ba;
reg cs_n;
reg rw;
wire [13:0] ad;
reg [13:0] adr;
wire ras_n;
wire cas_n;
wire hSync;
wire vSync;
wire [11:0] db;
reg [11:0] dbi;

initial begin
  rst = 1'b1;
  clk = 1'b0;
  #30 rst = 1'b0;
end

always #5 clk = ~clk;

FAL6567 #(
  .pSimRasterEnable(1)
) u1
(
  .chip(2'b00),
  .clk100(clk),
  .phi02(phi02),
  .rst_n_o(),
  .irq(),
  .aec(aec),
  .ba(ba),
  .cs_n(cs_n),
  .rw(rw),
  .ad(ad),
  .db(db),
  .ras_n(ras_n),
  .cas_n(cas_n),
  .lp_n(),
  .hSync(hSync),
  .vSync(vSync),
  .red(),
  .green(),
  .blue()
);

reg [11:0] state;
reg phi02a;
always @(posedge clk)
  phi02a <= phi02;

always @(posedge clk)
if (rst) begin
  cs_n <= 1'b1;
  rw <= 1'b1;
  adr <= 14'h3FFF;
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

assign ad = phi02 & aec ? adr : 14'bz; 

always @(posedge clk)
if (rst)
  dbi <= 12'd0;
else if (phi02 && !phi02a) begin
case(state)
5:   dbi <= 12'h10;
6:   dbi <= 12'h20;
7:   dbi <= 12'hFF;
default:
casex (ad)
14'b000xxxxxxxxxxx: dbi <= ad[11:0];
14'h8xx:  if (!cas_n) dbi <= {ad[3:0],ad[7:0]};
14'h3FFF: dbi <= 12'h000;
default: dbi <= ad[11:0];
endcase
endcase
end
assign db = dbi;

endmodule
