// ============================================================================
//        __
//   \\__/ o\    (C) 2005-2022  Robert Finch, Waterloo
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

module uart6551Rx(rst, clk,
	cyc, cs, wr, dout, ack,
	fifoEnable, fifoClear, clearGErr,
	parityCtrl, frameSize, stop_bits, wordLength, baud16x_ce, clear, rxd,
	full, empty, frameErr, overrun, parityErr, break_o, gerr, qcnt, cnt, bitStream);
input rst;
input clk;
input cyc;				// valid bus cycle
input cs;				// core select
input wr;				// read reciever
output [7:0] dout;		// fifo data out
output ack;
input fifoEnable;		// enable the fifo
input fifoClear;
input clearGErr;		// clear global error
input [2:0] parityCtrl;
input [7:0] frameSize;	// frame count
input [2:0] stop_bits;
input [3:0] wordLength;
input baud16x_ce;		// baud rate clock enable
input clear;			// clear reciever
input rxd;				// external serial input
output full;			// receive fifo full
output empty;           // receiver fifo is empty
output frameErr;		// framing error
output overrun;			// receiver overrun
output parityErr;		// parity error
output break_o;			// break detected
output gerr;			// global error indicator
output [3:0] qcnt;		// count of number of words queued
output [9:0] cnt;		// receiver counter
output bitStream;		// received bit stream

//0 - simple sampling at middle of symbol period
//>0 - sampling of 3 middle ticks of sumbol perion and results as majority
parameter SamplerStyle = 0;


reg overrun;
reg [9:0] cnt;			// sample bit rate counter / timeout counter
reg [10:0] rx_data;		// working receive data register
reg [9:0] t2;			// data minus stop bit(s)
reg [7:0] t3,t4;		// data minus parity bit and start bit
reg [7:0] t5;
reg p1;
reg gerr;				// global error status
reg perr;				// parity error
reg ferr = 1'b0;				// framing error
wire bz;				// break detected
reg state;				// state machine
reg wf;					// fifo write
wire empty;
reg didRd;
wire [7:0] dout1;
reg full1;
wire fifoFull, fifoEmpty;

assign ack = cyc & cs;
wire pe_rd;
edge_det ued1 (.rst(rst), .clk(clk), .ce(1'b1), .i(ack & ~wr), .pe(pe_rd), .ne(), .ee());

assign bitStream = rx_data[10];
assign bz = t4==8'd0;
wire rdf = fifoEnable ? pe_rd : wf;

uart6551Fifo #(.WID(11)) uf1
(
	.clk(clk),
	.rst(rst|clear|fifoClear),
	.wr(wf),
	.rd(rdf),
	.din({bz,perr,ferr,t4}),
	.dout({break_o,parityErr,frameErr,dout1}),
	.ctr(qcnt),
	.full(fifoFull),
	.empty(fifoEmpty)
);

assign dout = fifoEnable ? dout1 : t5;
assign empty = fifoEnable ? fifoEmpty : ~full1;
assign full = fifoEnable ? fifoFull : full1;

// compute 1/2 the length of the last bit
// needed for framing error detection
reg [7:0] halfLastBit;
always @(stop_bits)
if (stop_bits==3'd3)	// 1.5 stop bits ?
	halfLastBit <= 8'd4;
else
	halfLastBit <= 8'd8;

// record a global error status
always_ff @(posedge clk)
if (rst)
	gerr <= 0;
else begin
	if (clearGErr)
		gerr <= perr | ferr | bz;
	else
		gerr <= gerr | perr | ferr | bz;
end


// strip off stop bits	
always @(stop_bits or rx_data)
if (stop_bits==3'd2)
	t2 <= rx_data[9:0];
else
	t2 <= {rx_data[8:0],1'b0};

// grab the parity bit
always @(t2)
	p1 <= t2[9];

// strip off parity and start bit
always @(parityCtrl or t2)
if (parityCtrl[0])
	t3 <= t2[8:1];
else
	t3 <= t2[9:2];

// mask receive data for word length
// depending on the word length, the first few bits in the
// recieve shift register will be invalid because the shift
// register shifts from MSB to LSB and shorter frames
// won't shift as far towards the LSB.
always @(wordLength or t3)
	t4 <= t3 >> (4'd8 - wordLength);

// detect a parity err
always @(parityCtrl or t4 or p1) begin
	case (parityCtrl)
	3'b001:	perr <= p1 != ~^t4;	// odd parity
	3'b011:	perr <= p1 != ^t4;	// even parity
	default: perr <= 0;
	endcase
end


// Three stage synchronizer to synchronize incoming data to
// the local clock (avoids metastability).

reg [5:0] rxdd          /* synthesis ramstyle = "logic" */; // synchronizer flops
reg rxdsmp;             // majority samples
reg rdxstart;           // for majority style sample solid 3tik-wide sample
reg [1:0] rxdsum [0:1];
always_ff @(posedge clk)
if (baud16x_ce) begin
	rxdd <= {rxdd[4:0],rxd};
  if (SamplerStyle == 0) begin
    rxdsmp <= rxdd[3];
    rdxstart <= rxdd[4]&~rxdd[3];
  end
  else begin
    rxdsum[1] <= rxdsum[0];
    rxdsum[0] <= {1'b0,rxdd[3]} + {1'b0,rxdd[4]} + {1'b0,rxdd[5]};
    rxdsmp <= rxdsum[1] > 2'd1;
    rdxstart <= (rxdsum[0] == 2'b00) & (rxdsum[1] == 2'b11);
  end
end


always_ff @(posedge clk)
if (rst)
	state <= `IDLE;
else begin
	if (clear)
		state <= `IDLE;
	else if (baud16x_ce) begin
		case (state)
		// Sit in the idle state until a start bit is
		// detected.
		`IDLE:
			if (rdxstart)
				state <= `CNT;
		`CNT:
			begin
				// Switch back to the idle state a little
				// bit too soon.
				if (cnt[7:2]==frameSize[7:2])
					state <= `IDLE;
				// On start bit check make sure the start
				// bit is low, otherwise go back to the
				// idle state because it's a false start.
				if (cnt[7:0]==8'h07) begin
					if (rxdsmp)
						state <= `IDLE;
				end
			end
		default:	;
		endcase
	end
end

always_ff @(posedge clk)
if (rst)
	cnt <= 8'h00;
else begin
	if (clear)
		cnt <= 8'h00;
	else if (baud16x_ce) begin
		cnt <= cnt + 8'h1;
		case (state)
		`IDLE:
			begin
				// reset counter on read of reciever
				// (resets timeout count).
				if (didRd)
					cnt <= 8'h0;
				if (rdxstart)
					cnt <= 8'h0;
			end
		default:	;
		endcase
	end
end

always_ff @(posedge clk)
if (rst)
	wf <= 1'b0;
else begin
	// Clear write flag
	wf <= 1'b0;
	if (clear)
		wf <= 1'b0;
	else if (baud16x_ce) begin
		case (state)
		`CNT:
			// End of the frame ?
			// - write data to fifo
			if (cnt[7:0]==frameSize-halfLastBit) begin
				if (!full)
					wf <= 1'b1;
			end
		default:	;
		endcase
	end
end

always_ff @(posedge clk)
if (rst)
	t5 <= 1'b0;
else begin
	if (wf)
		t5 <= t4;
end

always_ff @(posedge clk)
if (rst)
	full1 <= 1'b0;
else begin
	if (wf)
		full1 <= 1'b1;
	else if (pe_rd)
		full1 <= 1'b0;
end

always_ff @(posedge clk)
if (rst)
	didRd <= 1'b0;
else begin
	// set a read flag for later reference
	if (pe_rd)
		didRd <= 1'b1;
	if (clear)
		didRd <= 1'b0;
	else if (baud16x_ce) begin
		case (state)
		`IDLE:
			begin
				if (didRd)
					didRd <= 1'b0;
				if (rdxstart)
					didRd <= 1'b0;
			end
		default:	;
		endcase
	end
end

always_ff @(posedge clk)
if (rst)
	rx_data <= 11'h0;
else begin
	if (clear)
		rx_data <= 11'h0;
	else if (baud16x_ce) begin
		case (state)
		`CNT:
			begin
				//if (cnt[7:2]==frameSize[7:2])
				//	rx_data <= 11'h0;
				if (cnt[3:0]==4'h7)
					rx_data <= {rxdsmp,rx_data[10:1]};
			end
		default:	;
		endcase
	end
end

// Overrun: trying to recieve data when recieve buffer is already full.
always_ff @(posedge clk)
if (rst)
	overrun <= 1'b0;
else begin
	if (!full)
		overrun <= 1'b0;
	if (clear)
		overrun <= 1'b0;
	else if (baud16x_ce) begin
		case (state)
		`CNT:
			if (cnt[7:0]==frameSize-halfLastBit) begin
				if (full)
					overrun <= 1'b1;
			end
		default:	;
		endcase
	end
end

always_ff @(posedge clk)
if (rst)
	ferr <= 1'b0;
else begin
	if (clear)
		ferr <= 1'b0;
	else if (baud16x_ce) begin
		case (state)
		`CNT:
			if (cnt[7:0]==frameSize-halfLastBit)
				ferr <= ~rxdsmp;
		default:	;
		endcase
	end
end

endmodule

