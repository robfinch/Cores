// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// N4Vmmu.v
// - memory management unit
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
module N4Vmmu(clk_i, cyc_i, stb_i, ack_i, we_i, adr_i, dat_i,
	cyc_o, stb_o, ack_o, we_o, adr_o,
	ctrl_dat_i
);
input clk_i;
input cyc_i;
input stb_i;
input ack_i;
input we_i;
input [31:0] adr_i;
input [15:0] dat_i;
output cyc_o;
output stb_o;
output ack_o;
output we_o;
output [31:0] adr_o;
input [15:0] ctrl_dat_i;

parameter ST_IDLE = 5'd0;
parameter ST_READ_PD1 = 5'd1;
parameter ST_READ_PD2 = 5'd2;
parameter ST_READ_PD3 = 5'd3;
parameter ST_READ_PE1 = 5'd4;
parameter ST_READ_PE2 = 5'd5;
parameter ST_READ_PE3 = 5'd6;
parameter ST_READ_PE4 = 5'd7;
parameter ST_ADR = 5'd8;
parameter ST_DAT = 5'd9;
parameter ST_DAT2 = 5'd10;

reg [4:0] state;

reg [31:0] pta = 32'h1FFFF000;
reg [7:0] asid = 8'h00;
reg pzprot = 1'b0;
reg cyc, stb, ack;
reg [31:0] adr;
reg [31:0] pd, pe;
reg mmu_ack;
reg we;

reg wr_cam;
reg [4:0] wr_adr;
reg [31:0] cam_dat;
wire match;
wire [31:0] match_addr;
wire [31:0] padr;
reg [4:0] lineno;

wire sel_pta = cyc_i && stb_i && adr_i[31:4]==28'hFFFFFFF;
wire sel_pg_zero = adr_i[31:12]==20'h00000;
wire ra = ~pta[0] || adr_i[31:30]==2'b11 || sel_pg_zero;	// detect when to use real address

assign cyc_o = (ra|match) ? cyc_i : cyc;
assign stb_o = (ra|match) ? stb_i : stb;
assign adr_o = ra ? adr_i : match ? (padr[11] ? {padr[31:22],adr_i[21:0]} : {padr[31:12],adr_i[11:0]}) : adr;
assign ack_o = (ra|match) ? ack_i|mmu_ack : ack & ack_i;
assign we_o  = ra ? we_i & ~pzprot  : match ? we_i & padr[0] : we;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// ATC - Address Translation Cache
//
// The address translation cache is a small fully-associative memory that
// keeps track of the 32 most recent address translations. The cache keeps
// track of the address space identifier so that the cache does not have
// to be flushed when the address space changes.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

cam36x32 ucam1
(
	.clk(clk_i),
	.we(wr_cam),
	.wr_addr(wr_adr),
	.din({8'h00,asid_i,adr_i[31:12]}),
	.cmp_din({8'h00,asid_i,adr_i[31:12]}),
	.match_addr(match_addr),
	.match(match)
);

integer n;
always @*
begin
lineno = 0;
for (n = 0; n < 32; n = n + 1)
    if (match_addr[n]) lineno = n;
end

reg [31:0] mem [0:31];
assign padr = mem[lineno];
always @(posedge clk_i)
	if (wr_cam)
		mem[wr_adr] <= cam_dat;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Page table walking state machine
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

always @(posedge clk_i)
begin
mmu_ack <= 1'b0;
wr_cam <= 1'b0;
case(state)
ST_IDLE:
	if (sel_pta) begin
	    mmu_ack <= 1'b1;
		if (we_i)
			case(adr_i[3:1])
			3'd0:	pta[31:16] <= ctrl_dat_i;
			3'd1:	pta[15:0] <= ctrl_dat_i;
			3'd3:	asid <= ctrl_dat_i;
			3'd4:	pzprot <= ctrl_dat_i[0];
			endcase
	end
	else if (cyc_i & ~ra & ~match) begin
		cyc <= 1'b1;
		stb <= 1'b1;
		we <= 1'b0;
		adr <= {pta[31:12],adr_i[31:22],2'b00};
		state <= ST_READ_PD1;
	end
ST_READ_PD1:
	if (ack_i) begin
		stb <= 1'b0;
		pd[31:16] <= dat_i;
		state <= ST_READ_PD2;
	end
ST_READ_PD2:
	if (~ack_i) begin
		stb <= 1'b1;
		adr <= adr + 32'd2;
		state <= ST_READ_PD3;
	end
ST_READ_PD3:
	if (ack_i) begin
		stb <= 1'b0;
		pd[15:0] <= dat_i;
		state <= ST_READ_PE1;
		if (dat_i[11]) begin
			pe <= {pd[31:22],adr_i[21:12],dat_i[11:0]};
			state <= ST_ADR;
		end
	end
ST_READ_PE1:
	if (~ack_i) begin
		stb <= 1'b1;
		adr <= {pd[31:12],adr_i[21:12],2'b00};
		state <= ST_READ_PE2;
	end
ST_READ_PE2:
	if (ack_i) begin
		stb <= 1'b0;
		pe[31:16] <= dat_i;
		state <= ST_READ_PE3;
	end
ST_READ_PE3:
	if (~ack_i) begin
		stb <= 1'b1;
		adr <= adr + 32'd2;
		state <= ST_READ_PE4;
	end
ST_READ_PE4:
	if (ack_i) begin
		stb <= 1'b0;
		pe[15:0] <= dat_i;
		state <= ST_ADR;
	end
ST_ADR:
	if (~ack_i) begin
		stb <= 1'b1;
		we <= we_i & pe[1];
		ack <= 1'b1;
		adr <= {pe[31:12],adr_i[11:0]};
		wr_adr <= wr_adr + 5'd1;
		wr_cam <= 1'b1;
		cam_dat <= pe;
		state <= ST_DAT;
	end
ST_DAT:
	if (ack_i) begin
		cyc <= 1'b0;
		stb <= 1'b0;
		we  <= 1'b0;
		state <= ST_DAT2;
	end
ST_DAT2:
    if (~stb_i) begin
        ack <= 1'b0;
        state <= ST_IDLE;
    end
default:
	state <= ST_IDLE;
endcase
end
endmodule
