// ============================================================================
//        __
//   \\__/ o\    (C) 2013  Robert Finch, Stratford
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
// ============================================================================
//
module cache6502(rst, clk, rdy, we, adr, dati, dato, bte_o, cti_o, cyc_o, stb_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o, bl_o, cacheEn, uncachedPage);
parameter INIT = 2'd0;
parameter IDLE = 2'd1;
parameter WAIT_ACK = 2'd2;
parameter BURST_WAIT_ACK = 2'd3;

input rst;
input clk;
output reg rdy;			// ready signal to cpu
input we;				// cpu's write enable
input [15:0] adr;		// cpu's address
input [7:0] dati;		// data from cpu to the cache
output reg [7:0] dato;	// data to the cpu from the cache

// WISHBONE signals
output reg [1:0] bte_o;	// burst type extension (always 00)
output reg [2:0] cti_o;	// cycle type indicator (000= normal, 001 = constant address burst)
output reg cyc_o;		// cycle is active indicator
output reg stb_o;		// data strobe
input ack_i;			// memory / IO is ready
output reg we_o;		// write cycle is in progress
output reg [3:0] sel_o;	// byte lane selects
output reg [15:0] adr_o;	// address
input [31:0] dat_i;			// data input to the cache
output reg [31:0] dat_o;	// data output to memory
// Memory controller support
output reg [5:0] bl_o;		// burst length to memory

input cacheEn;			// Cache is enabled.
input [15:8] uncachedPage;	// This page is always uncached

reg [1:0] state;
reg rdy1;				// internal ready signal
wire hit;				// cache hit
wire [7:0] cdato;
reg [7:0] dat;			// hold register for data coming from memory

wire [15:8] AH = adr[15:8];	// high order address bus
wire cacheInit = state==INIT;

cachemem u1 (
	.wclk(clk),
	.wce(cyc_o & (we_o ? hit & ack_i : ack_i)),
	.wsel(we_o ? sel_o : 4'hF),
	.wadr(adr_o),
	.wdati(we_o ? dat_o : dat_i),
	.rclk(~clk),
	.radr(adr),
	.rdato(cdato)
);

tagmem u2 (
	.wclk(clk),
	.wce(cyc_o && (we_o ? 1'b0 : ack_i) && adr_o[3:2]==2'b11),
	.wadr(adr_o),
	.cacheInit(cacheInit),
	.radr(adr),
	.hit(hit)
);

// Data going back to the cpu
always @(adr or uncachedPage or cacheEn or dat or cdato or cacheInit)
if (AH==uncachedPage || !cacheEn || cacheInit)
	dato <= dat;
else
	dato <= cdato;

// ready signal
always @(adr or uncachedPage or cacheEn or rdy1 or hit or we or cacheInit)
if (AH==uncachedPage || !cacheEn || cacheInit)
	rdy <= rdy1;
else
	rdy <= we ? rdy1 : hit;


always @(posedge clk)
if (rst) begin
	bte_o <= 2'b00;		// linear burst
	cti_o <= 3'b000;	// classic bus cycle
	bl_o <= 6'd0;
	cyc_o <= 1'b0;
	stb_o <= 1'b0;
	we_o <= 1'b0;
	sel_o <= 4'h0;
	adr_o <= 16'h0000;
	dat_o <= 32'h00000000;
	rdy1 <= 1'b0;
	state <= INIT;
end
else begin
rdy1 <= 1'b0;
case(state)
INIT:
	begin
		$display("INIT: %h", adr_o);
		adr_o <= adr_o + 16'd1;
		if (adr_o[12:4]==9'h1FF)
			state <= IDLE;
	end
IDLE:
	begin
		if (AH==uncachedPage || !cacheEn || we) begin
			state <= WAIT_ACK;
			bte_o <= 2'b00;
			cti_o <= 3'b000;
			bl_o <= 6'd0;
			cyc_o <= 1'b1;
			stb_o <= 1'b1;
			case(adr[1:0])
			2'd0:	sel_o <= 4'b0001;
			2'd1:	sel_o <= 4'b0010;
			2'd2:	sel_o <= 4'b0100;
			2'd3:	sel_o <= 4'b1000;
			endcase
			we_o <= we;
			adr_o <= {adr[15:2],2'b00};
			dat_o <= {4{dati}};
		end
		else if (!hit) begin
			state <= BURST_WAIT_ACK;
			bte_o <= 2'b00;		// linear burst
			cti_o <= 3'b001;	// constant address burst
			bl_o <= 6'd3;		// 4 words to read (16 bytes)
			cyc_o <= 1'b1;
			stb_o <= 1'b1;
			we_o <= 1'b0;
			adr_o <= {adr[15:4],4'h0};
		end
	end
WAIT_ACK:
	if (ack_i) begin
		state <= IDLE;
		cyc_o <= 1'b0;
		stb_o <= 1'b0;
		we_o <= 1'b0;
		adr_o <= 16'd0;
		dat_o <= 8'h00;
		case(adr_o)
		2'd0:	dat <= dat_i[7:0];
		2'd1:	dat <= dat_i[15:8];
		2'd2:	dat <= dat_i[23:16];
		2'd3:	dat <= dat_i[31:24];
		endcase
		rdy1 <= 1'b1;
	end
BURST_WAIT_ACK:
	if (ack_i) begin
		adr_o[3:2] <= adr_o[3:2] + 2'd1;
		if (adr_o[3:2]==2'b11) begin
			state <= IDLE;
			cti_o <= 3'b000;
			bl_o <= 6'd0;
			cyc_o <= 1'b0;
			stb_o <= 1'b0;
			sel_o <= 4'h0;
			adr_o <= 16'h0000;
		end
	end

endcase
end

endmodule

module cachemem(wclk, wce, wsel, wadr, wdati, rclk, radr, rdato);
input wclk;
input wce;
input [3:0] wsel;
input [15:0] wadr;
input [31:0] wdati;
input rclk;
input [15:0] radr;
output reg [7:0] rdato;

reg [31:0] mem [0:2047];	// 8kB cache
reg [15:0] rradr;

always @(posedge wclk)
	if (wce) begin
		if (wsel[0]) mem[wadr[12:2]] <= wdati[7:0];
		if (wsel[1]) mem[wadr[12:2]] <= wdati[15:8];
		if (wsel[2]) mem[wadr[12:2]] <= wdati[23:16];
		if (wsel[3]) mem[wadr[12:2]] <= wdati[31:24];
	end

always @(posedge rclk)
	rradr <= radr;

always @(rradr)
case(rradr[1:0])
2'd0:	rdato <= mem[rradr[12:2]][7:0];
2'd1:	rdato <= mem[rradr[12:2]][15:8];
2'd2:	rdato <= mem[rradr[12:2]][23:16];
2'd3:	rdato <= mem[rradr[12:2]][31:24];
endcase

endmodule


module tagmem(wclk, wce, wadr, cacheInit, radr, hit);
input wclk;
input wce;
input [15:0] wadr;
input cacheInit;
input [15:0] radr;
output hit;

reg [15:12] mem [0:511];

always @(posedge wclk)
	if (wce|cacheInit)
		mem [wadr[12:4]] <= {wadr[15:13],!cacheInit};

assign hit = mem[radr[12:4]]=={radr[15:13],1'b1};

endmodule

module cache6502_tb();

reg rst;
reg clk;
wire [1:0] bte;
wire [2:0] cti;
wire [5:0] bl;
wire cyc;
wire stb;
wire weo;
wire [3:0] sel;
reg [15:0] adr;
wire [15:0] adro;
reg we;
wire ack;
wire [7:0] dati;
reg [7:0] dato;
wire [7:0] mem_dato;
reg [31:0] lfsr;
wire lfsr_fb; 
xnor(lfsr_fb,lfsr[0],lfsr[1],lfsr[21],lfsr[31]);

initial begin
	#0 lfsr = 32'd0;
	#0 clk = 1'b0;
	#0 rst = 1'b0;
	#0 adr <= 16'hFFFA;
	#0 we <= 1'b0;
	#0 dato <= 8'h00;
	#50 rst = 1'b1;
	#50 rst = 1'b0;

end

always #5 clk = ~clk;
always #10 lfsr =  {lfsr[30:0],lfsr_fb};
always @(posedge clk)
	if (rdy) begin
		adr <= lfsr[15:0];
		we <= lfsr[16];
		dato <= lfsr[31:14];
	end

assign dati = lfsr[31:24];
assign ack = cyc&lfsr[23];

cache6502 u1 (
	.rst(rst),
	.clk(clk),
	.rdy(rdy),
	.we(we),
	.adr(adr),
	.dati(dati),
	.dato(dato),

	.bte_o(bte),
	.cti_o(cti),
	.cyc_o(cyc),
	.stb_o(stb),
	.ack_i(ack),
	.we_o(weo),
	.sel_o(sel),
	.adr_o(adro),
	.dat_i(lfsr[23:16]),
	.dat_o(mem_dato),
	.bl_o(bl),
	.cacheEn(1'b1),
	.uncachedPage(8'h00)
);

endmodule

