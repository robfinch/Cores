`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	frisc_soc_tb.v
//  - test bench for system on a chip
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
module friscv_soc_tb();
reg rst;
reg xclk;
wire [15:0] led;
wire [7:0] an;
wire [7:0] ssg;
wire [3:0] red, green, blue;

initial begin
  #0 xclk = 0;
  #0 rst = 1;
  #20 rst = 0;
  #100 rst = 1;
end

always #5 xclk = ~xclk;

friscv_soc usoc1
(
  .cpu_resetn(rst),
  .btnl(),
  .btnr(),
  .btnc(),
  .btnd(),
  .btnu(),
  .xclk(xclk),
  .led(led),
  .sw(),
  .an(an),
  .ssg(ssg), 
  .red(red),
  .green(green),
  .blue(blue),
  .hSync(),
  .vSync(),
  .UartTx(),
  .UartRx()
);
  
endmodule
