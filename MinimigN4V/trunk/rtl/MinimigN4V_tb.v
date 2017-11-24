// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	MinimigN4V_tb.v
//  - testbench circuit for system
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
module MinimigN4V_tb();

reg xclk;
reg cpu_resetn;
wire [7:0] led;

initial begin
    xclk = 1'b0;
    cpu_resetn = 1'b0;
    #200 cpu_resetn = 1'b1;
end

always #5 xclk = ~xclk;

MinimigGrid #(.SIM(1'b1)) ummn4v1
(
    .cpu_resetn(cpu_resetn),
    .xclk(xclk),
    .led(led),
    .kd(),
    .kclk(),
    .TMDS_OUT_clk_p(),
    .TMDS_OUT_clk_n(),
    .TMDS_OUT_data_p(),
    .TMDS_OUT_data_n()
);

endmodule
