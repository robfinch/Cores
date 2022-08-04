// ============================================================================
//        __
//   \\__/ o\    (C) 2004-2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//		
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ============================================================================
//
`define IDLE	0
`define CNT		1

//`define UART_NO_TX_FIFO	1'b1

module uart6551Tx(rst, clk, cyc, cs, wr, din, ack,
	fifoEnable, fifoClear, txBreak,
	frameSize, wordLength, parityCtrl, baud16x_ce,
	cts, clear, txd, full, empty, qcnt);

input rst;
input clk;
input cyc;			// bus cycle valid
input cs;			// core select
input wr;			// write transmitter
input [7:0] din;		// fifo data in
output ack;

input fifoEnable;
input fifoClear;
input txBreak;
input [7:0] frameSize;
input [3:0] wordLength;
input [2:0] parityCtrl;
input baud16x_ce;	// baud rate clock enable
input cts;			// clear to send
input clear;		// clear transmitter
output reg txd;		// external serial output
output full;		// fifo is full
output empty;		// fifo is empty
output [3:0] qcnt;	// number of characters queued

reg [7:0] t1;
reg [11:0] t2;
reg [11:0] tx_data;	// transmit data working reg (raw)
reg state;			// state machine state
reg [7:0] cnt;		// baud clock counter
reg rd;
reg p1, p2;			// parity bit

assign ack = cyc & cs;
edge_det ued1 (.rst(rst), .clk(clk), .ce(1'b1), .i(ack & wr), .pe(awr), .ne(), .ee());

`ifdef UART_NO_TX_FIFO
reg [7:0] fdo2;
reg empty;

always_ff @(posedge clk)
	if (awr) fdo2 <= {3'd0,din};

always_ff @(posedge clk)
	begin
		if (awr) empty <= 0;
		else if (rd) empty <= 1;
	end

assign full = ~empty;
wire [7:0] fdo = fdo2;
`else
reg [7:0] fdo2;
always_ff @(posedge clk)
	if (awr) fdo2 <= {3'd0,din};
// generate an empty signal for when the fifo is disabled
reg fempty2;
always_ff @(posedge clk)
	if (rst)
		fempty2 <= 1;
	else begin
		if (awr) fempty2 <= 0;
		else if (rd) fempty2 <= 1;
	end


wire [7:0] fdo1;		// fifo data output
wire rdf = fifoEnable ? rd : awr;
wire fempty;
wire ffull;
uart6551Fifo #(.WID(8)) fifo0
(
  .clk(clk),
  .rst(rst|clear|fifoClear),
  .din(din),
  .wr(awr),
  .rd(rdf),
  .dout(fdo1),
  .full(ffull),
  .empty(fempty),
  .ctr(qcnt)
);
assign empty = fifoEnable ? fempty : fempty2;
assign full = fifoEnable ? ffull : ~fempty2;
wire [7:0] fdo = fifoEnable ? fdo1 : fdo2;
`endif

// mask transmit data for word length
// this mask is needed for proper parity generation
integer n;
reg [7:0] mask;
always @*
	for (n = 0; n < 8; n = n + 1)
		mask[n] = n < wordLength ? 1'b1 : 1'b0;

always_comb
if (txBreak)
	t1 <= 0;
else
	t1 <= fdo & mask;


// compute parity bit
always_comb
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
// Insert start, parity bit and stop
always_comb
case(wordLength)
4'd5:	t2 <= {5'b11111,p1,t1[4:0],1'b0};
4'd6:	t2 <= {4'b1111,p1,t1[5:0],1'b0};
4'd7:	t2 <= {3'b111,p1,t1[6:0],1'b0};
default:	t2 <= {2'b11,p1,t1[7:0],1'b0};
endcase

always_ff @(posedge clk)
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

always_ff @(posedge clk)
if (rst)
	cnt <= 8'h00;
else begin
	if (clear)
		cnt <= 8'h00;
	if (baud16x_ce) begin
		case(state)
		`IDLE:
			cnt <= 8'h00;
		`CNT:
			cnt <= cnt + 8'd1;
		endcase
	end
end

always_ff @(posedge clk)
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

always_ff @(posedge clk)
if (rst)
	tx_data <= 12'hFFF;
else begin
	if (baud16x_ce) begin
		case(state)
		`IDLE:
			if ((!empty && cts)||txBreak)
				tx_data <= t2;
		`CNT:
			// Shift the data out. LSB first.
			if (cnt[3:0]==4'hF)
				tx_data <= {1'b1,tx_data[11:1]};
		endcase
	end
end

always_ff @(posedge clk)
if (rst)
	txd <= 1'b1;
else
	txd <= tx_data[0];

endmodule
