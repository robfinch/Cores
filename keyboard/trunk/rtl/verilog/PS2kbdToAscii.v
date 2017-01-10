`timescale 1ns / 1ps
// ============================================================================
//  Keyboard 
//  - Reads keys from PS2 style keyboard
//
//	(C) 2010-2014  Robert Finch
//	robfinch<remove>@finitron.ca
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
//	Convert a PS2 keyboard to ascii
//
//	Reg
//	$00		ascii code - bit 15 = strobe
//                       bit 0-7 = ascii code
//                       bit 8 = shift status
//                       bit 9 = control status
//                       bit 10 = alt status
//                       bit 11 = 1=keyup/0=keydown status
//                       bit 12 = numlock status
//                       bit 13 = capslock status
//                       bit 14 = scroll lock status
//	$04		access this address clears keyboard strobe
//  $08		contains ps2 scan code
//  $0C     keyboard write port
//	
//
//	Verilog 1995
//	Webpack 9.2i  xc3s1200-4fg320
//	64 slices / 118 LUTs / 175.009 MHz
//  72 ff's / 2 BRAM (2048x16)
//
// ============================================================================

// PS2 scan codes
`define SC_LSHIFT	8'h12
`define SC_RSHIFT	8'h59
`define SC_CTRL		8'h14
`define SC_ALT		8'h11
`define SC_DEL		8'h71	// extend
`define SC_LCTRL	8'h58
`define SC_EXTEND	8'hE0
`define SC_KEYUP	8'hF0
`define SC_NUMLOCK	8'h77
`define SC_SCROLLLOCK	8'h7E
`define SC_CAPSLOCK	8'h58

module PS2KbdToAscii(rst_i, clk_i, cyc_i, stb_i, ack_o, we_i, adr_i, dat_i, dat_o, kclk, kd, irq, rst_o);
parameter pClkFreq=25000000;
parameter pIOAddress=32'hFFDC0000;
input rst_i;				// reset
input clk_i;				// master clock
input cyc_i;
input stb_i;
output ack_o;				// ready
input we_i;
input [31:0] adr_i;			// address
input [7:0] dat_i;
output [15:0] dat_o;		// data output
reg [15:0] dat_o;
inout kclk;				// keyboard clock from keyboard
tri kclk;
inout kd;				// keyboard data
tri kd;
output irq;				// data available
output rst_o;			// reset output CTRL-ALT-DEL was pressed

wire cs = cyc_i && stb_i && (adr_i[31:4]==pIOAddress[31:4]);

reg strobe;
wire ps2_irq;
reg ps2_irq1;
reg ps2_cs;
wire ack_ps2;
wire [7:0] ps2_o;

// keyboard state
reg keyup;
reg extend;				// extended keycode active
reg shift;				// shift status
reg ctrl;				// control status
reg alt;				// alt status
reg x;
reg capsLock;
reg scrollLock;
reg numLock;

reg [7:0] sc,sc1;
reg scku;				// keyup state at time of scan code

reg ack1,ack2,ack3;
always @(posedge clk_i)
begin
	ack1 <= #1 cs;
	ack2 <= #1 ack1 & cs;
	ack3 <= #1 ack2 & cs;
end
assign ack_o = cs ? (we_i ? 1'b1 : ack3) : 1'b0;
wire cs_ps2 = cs & (adr_i[3]|we_i) & ack1 & ~ack2;

wire ign;
wire [7:0] xlat_o;
PS2ScanToAscii u1
(
	.shift(shift),
	.ctrl(ctrl),
	.alt(1'b0),
	.sc(sc),
	.extend(x),
	.ascii(xlat_o)
);
assign irq = strobe;
always @(posedge clk_i)
	if (cs)
		case(adr_i[3:2])
		2'd0:	dat_o <= {strobe,scrollLock,capsLock,numLock,scku,ctrl,alt,shift,xlat_o};
		2'd1:	dat_o <= ps2_o;	// keyboard strobe clear
		2'd2:	dat_o <= {scrollLock,capsLock,numLock,scku,ctrl,alt,shift,sc1};
		2'd3:	dat_o <= sc1;
		endcase
	else
		dat_o <= 16'h0000;

always @(posedge clk_i)
	if (ack_ps2)
		sc1 <= ps2_o;


PS2kbd #(.pClkFreq(pClkFreq), .pIOAddress(pIOAddress)) u2
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.cyc_i(ps2_cs|cs_ps2),
	.stb_i(ps2_cs|cs_ps2),
	.ack_o(ack_ps2),
	.we_i(ps2_cs ? 1'b0 : cs_ps2 ? we_i : 1'b0),
	.adr_i(ps2_cs ? pIOAddress : adr_i),
	.dat_i(dat_i),
	.dat_o(ps2_o),
	.vol_o(),
	.irq(ps2_irq),
	.kclk(kclk),
	.kd(kd)
);


// This little machine takes care of issuing a read cycle to the ps2 keyboard
// when data is present.
always @(posedge clk_i)
	if (rst_i) begin
		ps2_cs <= #1 0;
		ps2_irq1 <= #1 0;
	end
	else begin
		// has an PS2 keyboard event happened ?
		// If so, read the ps2 port
		ps2_irq1 <= #1 ps2_irq;
		if (ps2_irq & ~ps2_irq1)
			ps2_cs <= #1 1;
		else
			ps2_cs <= #1 0;
	end


// This machine
// 1) clears the strobe line on an access to the keyboard strobe clear address
// 2) activates the strobe on a keydown event, filtering out special keys
// like control and alt
// 3) captures the state of ctrl,alt and shift and filters these codes out
always @(posedge clk_i)
	if (rst_i) begin
		keyup <= #1 0;
		extend <= #1 0;
		shift <= #1 0;
		ctrl <= #1 0;
		alt <= #1 0;
		sc <= #1 0;
		scku <= #1 1'b0;
		x <= #1 1'b0;
		strobe <= #1 0;
	end
	else begin
		if (cs && adr_i[3:2]==2'b01)
			strobe <= #1 0;
		if (ps2_cs) begin
			case (ps2_o[7:0])
			`SC_KEYUP:	keyup <= #1 1;
			`SC_EXTEND:	extend <= #1 1;
			default:
				begin
				case(ps2_o[7:0])
				`SC_CTRL:	ctrl <= #1 ~keyup;
				`SC_ALT:	alt <= #1 ~keyup;
				`SC_LSHIFT,
				`SC_RSHIFT:	shift <= #1 ~keyup;
				`SC_CAPSLOCK:	capsLock <= #1 ~keyup;
				`SC_NUMLOCK:	numLock <= #1 ~keyup;
				`SC_SCROLLLOCK:	scrollLock <= #1 ~keyup;
				default:
					begin
					sc <= #1 ps2_o[7:0];
					scku <= keyup;
					x <= #1 extend;
					strobe <= #1 1'b1;//keyup ? strobe : 1'b1;
					end
				endcase
				keyup <= #1 0;
				extend <= #1 0;
				end
			endcase
		end
	end

// CTRL-ALT-DEL
assign rst_o = ps2_o[7:0]==`SC_DEL && alt && ctrl;

endmodule
