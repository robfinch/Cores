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
//
//  Usage:
//  - write the command and data to the command / data registers
//  - write to the trigger register triggerring a transfer
//  - poll the data transfer done bit in the data register
//  - poll the done bit in the config register to determine when the 
//    conversion is done.
//  - device can take up to 1s to perform a measurment
//
//  Max 10us to transfer data
//  Min 94ms to perform conversion (default is 750ms)
//
//  Max clk frequency to the ds1626 is 1.75 MHz.
//  The clk high/low time is 285 ns min.
//
//  Verilog 1995
//  Webpack 13.1i xc3s1200e 4-fg320
//  85 slices / 160 LUTs / 152.116 MHz
//  63 ff's
//
//  +- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|WISHBONE Datasheet
//	|WISHBONE SoC Architecture Specification, Revision B.3
//	|
//	|Description:						Specifications:
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|General Description:				Bitmap Controller
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|Supported Cycles:					SLAVE
//	|                                   SLAVE,READ/WRITE
//	|									SLAVE,BLOCK READ/WRITE
//	|									SLAVE,RMW
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|Data port, size:					16 bit
//	|Data port, granularity:			16 bit
//	|Data port, maximum operand size:	16 bit
//	|Data transfer ordering:			Undefined
//	|Data transfer sequencing:			Undefined
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|Clock frequency constraints:		none
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//  |SLAVE Port
//	|Supported signal list and			Signal Name		WISHBONE equiv.
//	|cross reference to equivalent		ack_o			ACK_O
//	|WISHBONE signals					adr_i(1:0)		ADR_I()
//	|									clk_i			CLK_I
//	|                                   rst_i           RST_I()
//	|									dat_i(15:0)		DAT_I()
//	|									dat_o(15:0)		DAT_O()
//	|									cyc_i			CYC_O
//	|									ds_n			STB_O
//	|									we_i			WE_O
//  |                                   sel_i(1:0)      SEL_I()
//	|
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|Special requirements:
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//
// ============================================================================

module ds1626io(
	rst_i, clk_i, cyc_i, stb_i, ack_o, we_i, sel_i, adr_i, dat_i, dat_o, 
	rst1626, clk1626, d1626, q1626, en1626
);
parameter pClkFreq = 50000000;
parameter pTmpNumber = 4'h0;

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

// SYSCON
input  rst_i;			// system reset
input  clk_i;			// system clock

// Slave Port
input  cyc_i;			// cycle is valid
input  stb_i;			// device strobe
output ack_o;			// acknowledge
input  we_i;			// write
input  [ 1:0] sel_i;	// port select
input  [33:0] adr_i;	// address
input  [15:0] dat_i;	// data input
output [15:0] dat_o;	// data output

// I/O connections
output rst1626;
output clk1626;
input d1626;
output q1626;
output en1626;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg [15:0] dat_o;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg ack;
reg trig;
reg [ 4:0] maxcnt;

reg [ 7:0] cmd;
reg [11:0] dat;
wire [20:0] bufin;
wire done;

wire cs_ds1626 = cyc_i && stb_i && (adr_i[33:10]==24'hFFDC03) && (adr_i[9:6]==pTmpNumber);
always @(posedge clk_i)
	ack <= cs_ds1626;
assign ack_o = cs_ds1626 ? (we_i ? 1'b1 : ack) : 1'b0;


ds1626_clk #(.pClkFreq(pClkFreq)) u1
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.bufin(bufin),
	.bufout({dat,cmd,1'b0}),
	.trigger(trig),
	.done(done),
	.rst1626(rst1626),
	.clk1626(clk1626),
	.d1626(d1626),
	.q1626(q1626),
	.en1626(en1626)
);

always @(posedge clk_i)
	if (rst_i) begin
		trig <= 1'b1;
		cmd  <= POR;
		dat  <= 12'h000;
	end
	else begin
		if (done)
			dat <= bufin[20:9];

		if (rst1626) begin
			trig <= 1'b0;
			if (cs_ds1626)
				dat_o <= adr_i[2] ? {rst1626,3'b0,dat} : {trig,7'b0,cmd};
			else
				dat_o <= 16'h0000;
		end
		else if (cs_ds1626) begin
			dat_o <= adr_i[2] ? {rst1626,3'b0,dat} : {trig,7'b0,cmd};
			if (we_i) begin
				// write to command register
				// (triggers io transfer)
				case(adr_i[2])
				1'd0:
					begin
					cmd  <= dat_i[7:0];
					trig <= 1'b1;
					end
				// write to data register
				1'd1:
					begin
					dat[ 7:0] <= dat_i[ 7:0];
					dat[11:8] <= dat_i[11:8];
					end
				endcase
			end
		end
		else
			dat_o <= 16'h0000;
	end

endmodule

