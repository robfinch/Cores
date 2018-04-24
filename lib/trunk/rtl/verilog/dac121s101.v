//=============================================================================
//  dac121s101
//  - DAC (digital to analogue) converter interface core
//
//
//	(C) 2010,2011 Robert T Finch
//	robfinch<remove>@OpenCores.org
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
//  Webpack 9.2i xc3s1200e 4fg320
//  38 slices / 71 LUTs / 183.824 MHz
//  36 ff's
//
//=============================================================================

module dac121s101(rst_i, clk_i, cyc_i, stb_i, ack_o, we_i, dat_i, sclk, sync, d);
parameter pClkFreq=60000000;
parameter pPrescale=pClkFreq/50000000 + 1;	//2x freq
// states
parameter IDLE=4'd0;
parameter LOAD=4'd1;
parameter SHIFT=4'd2;
parameter TERM=4'd3;

// SYSCON
input rst_i;
input clk_i;

input cyc_i;
input stb_i;
input we_i;
output ack_o;
input [15:0] dat_i;

output sclk;
output sync;
output d;

// Registered outputs
reg sclk;
reg sync;

reg [1:0] state;
reg pe_sclk;
reg [7:0] ps_cnt;	// prescale counter
reg [3:0] cnt;		// shift bit counter
reg [15:0] dd;
reg ack;

assign ack_o = cyc_i & stb_i & ack;


// Prescale the system clock
// The DAC has a max clock frequency of 30MHz.
//
always @(posedge clk_i)
if (rst_i) begin
	ps_cnt <= 8'd1;
	sclk <= 1'b0;
	pe_sclk <= 1'b0;
end
else begin
	pe_sclk <= 1'b0;
	if (ps_cnt==pPrescale) begin
		ps_cnt <= 8'd1;
		sclk <= !sclk;
		pe_sclk <= sclk==1'b0;
	end
	else
		ps_cnt <= ps_cnt + 8'd1;
end


always @(posedge clk_i)
if (rst_i) begin
	ack <= 1'b0;
	sync <= 1'b1;
	dd <= 16'h0000;
	cnt <= 4'd0;
	state <= IDLE;
end
else begin

	if (!cyc_i || !stb_i)
		ack <= 1'b0;

	case(state)
	IDLE:
		if (cyc_i & stb_i & we_i) begin
			state <= LOAD;
			dd[11:0] <= dat_i[13:0];
			dd[15:12] <= 4'b0000;
			ack <= 1'b1;
		end
	LOAD:
		if (pe_sclk) begin
			sync <= 1'b0;
			cnt <= 4'd0;
			state <= SHIFT;
		end
	SHIFT:
		if (pe_sclk) begin
			dd <= {dd[14:0],1'b0};
			cnt <= cnt + 4'd1;
			if (cnt==4'd15)
				state <= TERM;
		end
	TERM:
		if (pe_sclk) begin
			sync <= 1'b1;
			state <= IDLE;
		end
	default:
		state <= IDLE;
	endcase
end

assign d = dd[15];

endmodule
