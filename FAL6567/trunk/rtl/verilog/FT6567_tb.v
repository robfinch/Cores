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
module FT6567_tb();
reg rst;
reg clk;
wire phi02;
reg phi02d;
wire aec;
wire ba;
reg csr_n;
reg cs_n;
reg rw;
wire [13:0] ad;
reg [23:0] adr;
wire ram_ce;
wire ram_oe;
wire ram_we;
wire [18:0] ram_ad;
wire [7:0] ram_db;
wire hSync;
wire vSync;
wire [7:0] db;
reg [7:0] dbi;

initial begin
  rst = 1'b1;
  clk = 1'b0;
  #600 rst = 1'b0;
end

always #5 clk = ~clk;
always #1 phi02d = phi02;
always #1 cs_n = (!phi02 | csr_n); 

FT6567 #(
  .pSimRasterEnable(1)
) u1
(
  .clk100(clk),
  .phi02(phi02),
  .rst_o(),
  .irq(),
  .cs_n(cs_n),
  .rw(rw),
  .ad(adr[15:0]),
  .db(db),
  .lp_n(),
  .ram_ce(ram_ce),
  .ram_oe(ram_oe),
  .ram_we(ram_we),
  .ram_ad(ram_ad),
  .ram_db(ram_db),
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

always @(negedge phi02)
if (rst) begin
  csr_n <= 1'b1;
  rw <= 1'b1;
  adr <= 24'hFFFFFF;
  dbi <= 8'd0;
  state <= 12'd0;
end
else begin
begin
    state <= state + 1;
    case(state)
    5: begin
      csr_n <= #1 1'b0;
      rw <= #1 1'b0;
      adr <= #1 24'h5C; // control reg #1
      dbi <= #1 8'h10;
      end
    7: begin
            csr_n <= #1 1'b0;
            rw <= #1 1'b0;
            adr <= #1 24'h50;
            dbi <= #1 8'hFE;
            end
    8: begin
      csr_n <= #1 1'b1;
      rw <= #1 1'b1;
      end
    9: begin
      csr_n <= #1 1'b0;
      rw <= #1 1'b0;
      adr <= #1 24'h6F;
      dbi <= #1 8'hA1;
      end
    10: begin
        csr_n <= #1 1'b0;
        rw <= #1 1'b0;
        adr <= #1 24'h64;
        dbi <= #1 8'h00;
        end
    15:
      begin
      csr_n <= #1 1'b0;
      rw <= #1 1'b0;
      adr <= #1 24'hA00000;
      dbi <= #1 8'h2C;
      end
    default:
      begin
        csr_n <= #1 1'b1;
        rw <= #1 1'b1;
      end
    endcase
    end
end

assign db = phi02d ? dbi : adr[23:16];

endmodule
