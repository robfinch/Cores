// ============================================================================
//        __
//   \\__/ o\    (C) 2011-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// random.v
//     Multi-stream random number generator.
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
// 	Reg no.
//	0			read: random output bits [N:0], write: gen next number	
//  1           random stream number
//  2           m_z seed setting bits [N:0]
//  3           m_w seed setting bits [N:0]
//  N = 31 or 63
//  +- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|WISHBONE Datasheet
//	|WISHBONE SoC Architecture Specification, Revision B.3
//	|
//	|Description:						Specifications:
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|General Description:				random number generator
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|Supported Cycles:					SLAVE,READ/WRITE
//	|									SLAVE,BLOCK READ/WRITE
//	|									SLAVE,RMW
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|Data port, size:					32/64 bit
//	|Data port, granularity:			32/64 bit
//	|Data port, maximum operand size:	32/64 bit
//	|Data transfer ordering:			Undefined
//	|Data transfer sequencing:			Undefined
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|Clock frequency constraints:		none
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|Supported signal list and			Signal Name		WISHBONE equiv.
//	|cross reference to equivalent		ack_o			ACK_O
//	|WISHBONE signals					adr_i[3:0]		ADR_I()
//	|									clk_i			CLK_I
//	|                                   rst_i           RST_I()
//	|									dat_i(31:0)		DAT_I()
//	|									dat_o(31:0)		DAT_O()
//	|									cyc_i			CYC_I
//	|									stb_i			STB_I
//	|									we_i			WE_I
//	|
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|Special requirements:
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//
// ============================================================================
//
// Uses George Marsaglia's multiply method
//
// m_w = <choose-initializer>;    /* must not be zero */
// m_z = <choose-initializer>;    /* must not be zero */
//
// uint get_random()
// {
//     m_z = 36969 * (m_z & 65535) + (m_z >> 16);
//     m_w = 18000 * (m_w & 65535) + (m_w >> 16);
//     return (m_z << 16) + m_w;  /* 32-bit result */
// }
//
`define TRUE	1'b1
`define FALSE	1'b0

module random(rst_i, clk_i, cs_i, cyc_i, stb_i, ack_o, we_i, adr_i, dat_i, dat_o);
parameter WID=64;
input rst_i;
input clk_i;
input cs_i;
input cyc_i;
input stb_i;
output reg ack_o;
input we_i;
input [3:0] adr_i;			// connect to 4:1 for 64-bit
input [WID-1:0] dat_i;
output reg [WID-1:0] dat_o;
parameter pAckStyle = 1'b0;

reg ack;
reg cs;
reg we;
reg [3:0] adr;
reg [WID-1:0] dat;
always @(posedge clk_i)
	cs <= cs_i && cyc_i && stb_i;
always @(posedge clk_i)
	we <= we_i;
always @(posedge clk_i)
	adr <= adr_i;
always @(posedge clk_i)
	dat <= dat_i;

always @(posedge clk_i)
	ack_o <= cs;
//always @*
//	ack_o <= cs ? ack : pAckStyle;

reg [9:0] stream;
reg [WID-1:0] next_m_z;
reg [WID-1:0] next_m_w;
reg [WID-1:0] out;
reg wrw, wrz;
reg [WID-1:0] w,z;
wire [WID-1:0] m_zs;
wire [WID-1:0] m_ws;

rand_ram #(WID) u1 (clk_i, wrw, stream, w, m_ws);
rand_ram #(WID) u2 (clk_i, wrz, stream, z, m_zs);

always @*
begin
	if (WID==64) begin
		next_m_z <= (32'h36969696 * m_zs[31:0]) + m_zs[63:32];
		next_m_w <= (32'h18000000 * m_ws[31:0]) + m_ws[63:32];
	end
	else begin
		next_m_z <= (18'h36969 * m_zs[15:0]) + m_zs[31:16];
		next_m_w <= (18'h18000 * m_ws[15:0]) + m_ws[31:16];
	end
end

// Register read path
//
always @(posedge clk_i)
	case(adr[3:2])
	2'd0:
		if (WID==64)
			dat_o <= {m_zs[31:0],32'd0} + m_ws;
		else	
			dat_o <= {m_zs[15:0],16'd0} + m_ws;
	2'd1:	dat_o <= {6'h0,stream};
// Uncomment these for register read-back
//		3'd4:	dat_o <= m_z[31:16];
//		3'd5:	dat_o <= m_z[15: 0];
//		3'd6:	dat_o <= m_w[31:16];
//		3'd7:	dat_o <= m_w[15: 0];
	default:	dat_o <= 32'h0000;
	endcase

// Register write path
//
always @(posedge clk_i)
begin
	wrw <= `FALSE;
	wrz <= `FALSE;
	if (cs) begin
		if (we)
			case(adr[3:2])
			2'd0:
				begin
					z <= next_m_z;
					w <= next_m_w;
					wrw <= `TRUE;
					wrz <= `TRUE;
				end
			2'd1:	stream <= dat[9:0];
			2'd2:	begin z <= dat; wrz <= `TRUE; end
			2'd3:	begin w <= dat; wrw <= `TRUE; end
			endcase
	end
end

endmodule


// Tools were inferring a massive distributed ram so we help them out a bit by
// creating an explicit ram definition.

module rand_ram(clk, wr, ad, i, o);
parameter WID=64;
input clk;
input wr;
input [9:0] ad;
input [WID-1:0] i;
output [WID-1:0] o;

reg [WID-1:0] ri;
reg [9:0] regadr;
reg regwr;
(* RAM_STYLE="BLOCK" *)
reg [WID-1:0] mem [0:1023];

always @(posedge clk)
	regadr <= ad;
always @(posedge clk)
	regwr <= wr;
always @(posedge clk)
	ri <= i;
always @(posedge clk)
	if (regwr)
		mem[regadr] <= ri;
assign o = mem[regadr];

endmodule
