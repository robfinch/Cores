`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DSD7_bench.v
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
module DSD7_bench();

reg rst;
reg clk;
wire irdy;
wire [31:0] adr;
wire [31:0] idat;
wire vda;
wire vpa;

initial begin
    #0 rst = 1'b0;
    #0 clk = 1'b0;
    #20 rst = 1'b1;
    #80 rst = 1'b0;
end

always #5 clk = ~clk;

DSD7 ucpu1
(
    .hartid_i(32'h1),
    .rst_i(rst),
    .clk_i(clk),
    .irq_i(1'b0),
    .ivec_i(9'h000),
    .vda_o(vda),
    .vpa_o(vpa),
    .rdy_i(irdy),
    .lock_o(),
    .wr_o(),
    .sel_o(),
    .adr_o(adr),
    .dat_i(idat),
    .dat_o(),
    .sr_o(),
    .cr_o(),
    .rb_i()
 );

bootrom_sim u2
(
    .rst_i(rst),
    .clk_i(clk),
    .va_i(vda|vpa),
    .rdy_o(irdy),
    .adr_i(adr),
    .dat_o(idat)
);

endmodule
