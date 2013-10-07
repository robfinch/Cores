// ============================================================================
//        __
//   \\__/ o\    (C) 2008,2013  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@opencores.org
//       ||
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
//  ds1626:
//
//  Interface to ds1626 TempPod.
//
// ============================================================================
// ds1626_clk:
//
// Drives the clk signal for the DS1626 temperature sensor. The clk signal
// is easily controlled by just looking at the rst line going to the DS1626.
// The clock is only active while rst is high.
//
// Max clk frequency is 1.75 MHz.
// The clk high/low time is 285 ns min.
// On a write extra bits transmitted will be ignored
// On a read extra clock cycles will cause a zero to be output
//
// Verilog 1995
// Webpack 9.2i xc3s1000 4-ft256
// 26 slices / 50 LUTs / 126.470 MHz
// 16 ff's
// ============================================================================

module ds1626_clk(rst_i, clk_i, bufin, bufout, trigger, done, rst1626, clk1626, d1626, q1626, en1626);
// Timing parameters
parameter pClkFreq = 50000000;
parameter tRC = pClkFreq / 10000000 + 1;	// Reset high before clock low 100ns
parameter tCL = pClkFreq /  3508772 + 1;	// Clock low  time	285 ns
parameter tCH = pClkFreq /  3508772 + 1;	// Clock high time
parameter tCRH = pClkFreq /  25000000 + 1;	// Clock hold time: 40 ns
// States
parameter CLK1 = 4'd1;
parameter CLK2 = 4'd2;
parameter CLK3 = 4'd3;
parameter CLK4 = 4'd4;
parameter CLK5 = 4'd5;
parameter CLK6 = 4'd6;
parameter CRH1 = 4'd7;
parameter CRH2 = 4'd8;
// Commands
parameter START_CNV = 8'h51;
parameter STOP_CNV = 8'h22;
parameter READ_TEMP = 8'hAA;
parameter READ_CONFIG = 8'hAC;
parameter READ_TH = 8'hA1;
parameter READ_TL = 8'hA2;
parameter WRITE_TH = 8'h01;
parameter WRITE_TL = 8'h02;
parameter WRITE_CONFIG = 8'h0C;
parameter POR = 8'h54;

// Signal Declarations
input  rst_i;			// system reset
input  clk_i;			// system clock
input  trigger;
output done;
reg done;
output [20:0] bufin;	// output buffer
reg    [20:0] bufin;
input  [20:0] bufout;	// input buffer
output rst1626;		// active low reset line going to the DS1626 (input here)
reg    rst1626;
output clk1626;			// clock line going to the DS1626
reg clk1626;			// registered output
output q1626;
output en1626;
input d1626;

// Vars
wire [7:0] cmd = bufout[8:1];
wire isRead =
	cmd==READ_CONFIG ||
	cmd==READ_TEMP ||
	cmd==READ_TH ||
	cmd==READ_TL
	;
reg out_t;				// controls i/o direction
reg [3:0] state;		// tracks the machine state
reg [12:0] pscnt;		// system clock prescaler
reg [4:0] cnt;

//assign dq1626 = out_t ? bufout[cnt] : 1'bz;
assign en1626 = out_t;
assign q1626 = bufout[cnt];

always @(posedge clk_i)
if (rst_i) begin
	rst1626 <= 1'b0;
	clk1626 <= 1'b1;
	pscnt <= 13'h0000;
	state <= CLK1;
	done <= 1'b0;
	cnt <= 5'd1;
	out_t <= 1'b0;
end
else begin

done <= 1'b0;

if (!pscnt[12])
	pscnt <= pscnt - 12'd1;

case(state)
// Wait for a transfer request
// - reset will be set to high
CLK1:
	if (trigger) begin
		rst1626 <= 1'b1;
		cnt   <= 5'd1;
		pscnt <= tRC;
		out_t <= 1'b1;
		state <= CLK2;
	end

// Wait reset high time
CLK2:
	if (pscnt[12])
		state <= CLK3;

// Set clock low time
// Drive the clock low
CLK3:
	begin
	pscnt   <= tCL;
	clk1626 <= 1'b0;
	state   <= CLK4;
	end

// Wait for the clock low period to expire
// Set the clock high period
// Drive the clock high on expiry
CLK4:
	if (pscnt[12]) begin
		pscnt <= tCH;
		clk1626 <= 1'b1;
		bufin[cnt] <= d1626;
		state <= CLK5;
	end

// wait for the clock high period to expire
// set the clock low period
// set output index
CLK5:
	if (pscnt[12]) begin
		if (cnt==5'd20)			// leave the clock line high and goto the hold time
			state <= CRH1;			// state
		else begin
			// switch to input mode after the sending the eight command bit
			// during a read operation
			if (cnt==5'd8 && isRead)
				out_t <= 1'b0;
			pscnt <= tCL;
			state <= CLK4;
			clk1626 <= 1'b0;
			cnt <= cnt + 5'd1;
		end
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Reset must be held high until tCRH after the clock goes high
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
CRH1:
	begin
	out_t <= 1'b1;
	pscnt <= tCRH;
	state <= CRH2;
	end
CRH2:
	if (pscnt[12]) begin
		rst1626 <= 1'b0;
		done    <= 1'b1;
		state   <= CLK1;
	end

default:
	begin
	out_t   <= 1'b1;
	rst1626 <= 1'b0;
	clk1626 <= 1'b1;
	state   <= CLK1;
	end
endcase

end

endmodule

