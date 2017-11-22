// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	Clock.v
//  Master clock generator for MinimigGrid
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
module clock_generator
(
    input   reset,
    output  locked,
	input	mclk,		// 4.433619 MHz master clock input
	output	clk28m,	 	// 28.37516 MHz clock output
	output	reg c1,		// clk28m clock domain signal synchronous with clk signal
	output	reg c3,		// clk28m clock domain signal synchronous with clk signal delayed by 90 degrees
	output	cck,		// colour clock output (3.54 MHz)
	output 	clk, 		// 7.09379  MHz clock output
	output	cpu_clk,
	output  clk400,
	output  clk80,
	input	turbo,
	output 	reg [9:0] eclk	// 0.709379 MHz clock enable output (clk domain pulse)
);

//            __    __    __    __    __
// clk28m  __/  \__/  \__/  \__/  \__/  
//            ___________             __
// clk     __/           \___________/  
//            ___________             __
// c1      __/           \___________/   <- clk28m domain
//                  ___________
// c3      ________/           \________ <- clk28m domain
//

wire	pll_mclk;
wire	pll_cpuclk;
wire    clk10;

IBUFG mclk_buf ( .I(mclk), .O(pll_mclk) );	

//----------------------------------------------------------------------------
//  Output     Output      Phase    Duty Cycle   Pk-to-Pk     Phase
//   Clock     Freq (MHz)  (degrees)    (%)     Jitter (ps)  Error (ps)
//----------------------------------------------------------------------------
// clk_out1___100.000______0.000______50.0______141.599____119.546
// clk_out2____28.646______0.000______50.0______183.065____119.546
// clk_out3_____7.161______0.000______50.0______240.909____119.546
// clk_out4____57.292______0.000______50.0______159.115____119.546
// clk_out5____28.646_____90.000______50.0______183.065____119.546
//
clk_wiz clk_wiz1
(
    // Clock out ports
    .clk_out2(clk400),
    .clk_out3(clk80),
    .clk_out4(clk28m),  // 40MHz
    .clk_out5(clk10),   // 10MHz
    // Status and control signals
    .reset(reset), // input reset
    .locked(locked),       // output locked
    // Clock in ports
    .clk_in1(pll_mclk)
);

BUFGMUX cpu_clk_buf 
(
    .O(cpu_clk),	// Clock MUX output
    .I0(~clk10),	// Clock0 input
    .I1(~clk28m),	// Clock1 input
    .S(turbo)		// Clock select input
);

reg	[3:0] e_cnt;	//used to generate e clock enable

// E clock counter
always @(posedge clk10)
	if (e_cnt[3] && e_cnt[0]) begin
		e_cnt[3:0] <= 0;
		eclk <= 10'b0000000001;
	end
	else begin
		e_cnt[3:0] <= e_cnt[3:0] + 1;
		eclk <= {eclk[8:0],eclk[9]};
	end

// CCK clock output
assign cck = ~e_cnt[0];
		
always @(posedge clk28m)
	c3 <= clk10;
	
always @(posedge clk28m)
	c1 <= ~c3;
	
endmodule
