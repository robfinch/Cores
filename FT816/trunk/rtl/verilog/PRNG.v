`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// PRNG.v
//  - Random number generator
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
//-----------------------------------------------------------------------------
// Uses George Marsaglia's multiply method.
//-----------------------------------------------------------------------------

module PRNG(rst, clk, vda, rw, ad, db, rdy);
parameter pIOAddress = 24'hFEA100;
input rst;
input clk;
input vda;
input rw;
input [23:0] ad;
inout tri [7:0] db;
output rdy;

reg [31:0] m_z;
reg [31:0] m_w;
reg [31:0] next_m_z;
reg [31:0] next_m_w;

always @(m_z or m_w)
begin
	next_m_z <= (18'd36969 * m_z[15:0]) + m_z[31:16];
	next_m_w <= (18'd18000 * m_w[15:0]) + m_w[31:16];
end

wire [31:0] rand = {m_z[15:0],16'd0} + m_w;

reg rdy1,rdy2;
reg [7:0] dbo;
wire cs_rand = vda && (ad[23:4]==pIOAddress[23:4]);
assign db = cs_rand & rw ? dbo : {8{1'bz}};
assign rdy = !cs_rand ? 1'b1 : ~rw ? 1'b1 : rdy2;

always @(posedge clk)
if (rst) begin
	rdy1 <= 1'b0;
	rdy2 <= 1'b0;
end
else begin
	rdy1 <= cs_rand;
	rdy2 <= rdy1 & cs_rand;
end

always @(posedge clk)
if (rst) begin
	m_z <= 32'h99999999;
	m_w <= 32'h88888888;
	dbo <= 8'h00;
end
else begin
	if (vda & cs_rand & ~rw)
		case(ad[3:0])
		4'd0:	m_z[7:0] <= db;
		4'd1:	m_z[15:8] <= db;
		4'd2:	m_z[23:16] <= db;
		4'd3:	m_z[31:24] <= db;
		4'd4:	m_w[7:0] <= db;
		4'd5:	m_w[15:8] <= db;
		4'd6:	m_w[23:16] <= db;
		4'd7:	m_w[31:24] <= db;
		4'd14:	begin
				m_z <= next_m_z;
				m_w <= next_m_w;
				end
		endcase
	case(ad[3:0])
	4'd8:	dbo <= rand[7:0];
	4'd9:	dbo <= rand[15:8];
	4'd10:	dbo <= rand[23:16];
	4'd11:	dbo <= rand[31:24];
	default:	dbo <= rand[7:0];
	endcase
end

endmodule
