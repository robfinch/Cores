// ============================================================================
//        __
//   \\__/ o\    (C) 2004-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
// ============================================================================
//
`define IDLE	0
`define CNT		1

module rtfUartTx(rst, clk, cyc, cs, wr, din, ack,
	fifoEnable, fifoClear, txBreak,
	frameSize, wordLength, parityCtrl, baud16x_ce,
	cts, clear, txd, full, empty, qcnt);

input rst;
input clk;
input cyc;			// bus cycle valid
input cs;			// core select
input wr;			// write transmitter
input [31:0] din;		// fifo data in
output ack;

input fifoEnable;
input fifoClear;
input txBreak;
input [9:0] frameSize;
input [5:0] wordLength;
input [2:0] parityCtrl;
input baud16x_ce;	// baud rate clock enable
input cts;			// clear to send
input clear;		// clear transmitter
output reg txd;		// external serial output
output full;		// fifo is full
output empty;		// fifo is empty
output [5:0] qcnt;	// number of characters queued

reg [31:0] t1, t2;
reg [31:0] tx_data;	// transmit data working reg (raw)
reg state;			// state machine state
reg [9:0] cnt;		// baud clock counter
reg rd;
reg p1, p2;			// parity bit

assign ack = cyc & cs;
wire awr = ack & wr;

`ifdef UART_NO_TX_FIFO
reg [31:0] fdo;
reg empty;

always @(posedge clk)
	if (awr) fdo <= din;

always @(posedge clk)
	begin
		if (awr) empty <= 0;
		else if (rd) empty <= 1;
	end

assign full = ~empty;
`else
// generate an empty signal for when the fifo is disabled
reg fempty2;
always @(posedge clk)
	if (rst)
		fempty2 <= 1;
	else begin
		if (awr) fempty2 <= 0;
		else if (rd) fempty2 <= 1;
	end


wire [7:0] fdo;		// fifo data output
wire rdf = fifoEnable ? rd : awr;
wire fempty;
wire ffull;
rtfUartFifo #(32,64) fifo0
(
	.rst(rst|clear|fifoClear),
	.clk(clk),
	.wr(awr),
	.rd(rdf),
	.din(din),
	.dout(fdo),
	.full(ffull),
	.empty(fempty),
	.ctr(qcnt)
);
assign empty = fifoEnable ? fempty : fempty2;
assign full = fifoEnable ? ffull : ~fempty2;
`endif


// mask transmit data for word length
// this mask is needed for proper parity generation
integer n;
reg [31:0] mask;
always @(wordLength)
	for (n = 0; n < 32; n = n + 1)
		mask[n] = n < wordLength ? 1'b1 : 1'b0;

always @(fdo or mask)
if (txBreak)
	t1 <= 0;
else
	t1 <= fdo & mask;


// compute parity bit
always @(parityCtrl or t1)
begin
	case (parityCtrl)
	3'b001:	p1 <= ~^t1;// odd parity
	3'b011:	p1 <= ^t1;	// even parity
	3'b101: p1 <= 1;	// mark bit
	3'b111:	p1 <= 0;	// space bit
	default: p1 <= 1;	// stop bit when no parity
	endcase
end

/*
Could pipeline this, but then watch out for empty signal control
always @(posedge clk)
	if (ce)	t2 <= t1;

always @(posedge clk)
	if (ce) p2 <= p1;
*/
always @(t1)
	t2 <= t1;
	
always @(p1)
	p2 <= p1;

always @(posedge clk)
if (rst)
	state <= `IDLE;
else begin
	if (clear)
		state <= `IDLE;
	if (baud16x_ce) begin
		case(state)
		`IDLE:
			if ((!empty && cts)||txBreak)
				state <= `CNT;
		`CNT:
			if (cnt==frameSize)
				state <= `IDLE;
		endcase
	end
end

always @(posedge clk)
if (rst)
	cnt <= 10'h000;
else begin
	if (clear)
		cnt <= 10'h000;
	if (baud16x_ce) begin
		case(state)
		`IDLE:
			cnt <= 10'h000;
		`CNT:
			cnt <= cnt + 10'd1;
		endcase
	end
end

always @(posedge clk)
if (rst)
	rd <= 0;
else begin
	rd <= 0;
	if (clear)
		rd <= 0;
	if (baud16x_ce) begin
		case(state)
		`IDLE:
			if ((!empty && cts)||txBreak)
				rd <= 1;
		endcase
	end
end

always @(posedge clk)
if (rst)
	tx_data <= 32'hFFFFFFFF;
else begin
	if (baud16x_ce) begin
		case(state)
		`IDLE:
			if ((!empty && cts)||txBreak)
				tx_data <= txBreak ? 32'd0 : fdo;
		`CNT:
			begin
				// Shift the data out. LSB first.
				if (cnt[3:0]==4'hF) begin
					if (cnt[9:4] < wordLength)
						tx_data <= {1'b1,tx_data[31:1]};
				end
			end
		endcase
	end
end

always @(posedge clk)
if (rst)
	txd <= 1'b1;
else begin
	if (baud16x_ce) begin
		case(state)
		`IDLE:
			if ((!empty && cts)||txBreak)
				txd <= 1'b0;
		`CNT:
			begin
				// Shift the data out. LSB first.
				if (cnt[3:0]==4'hF) begin
					if (cnt[9:4] < wordLength)
						txd <= tx_data[0];
					else if (cnt[9:4]==wordLength)
						txd <= p2;
					else
						txd <= 1'b1;
				end
			end
		endcase
	end
end

endmodule
