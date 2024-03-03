// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  Register file
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

reg [15:0] rrro;			
reg [15:0] rmo;				// register output (controlled by mod r/m byte)
reg [15:0] rfso;

reg pf;						// parity flag
reg af;						// auxillary carry (half carry) flag
reg zf, cf, vf;
reg sf;						// sign flag
reg df;						// direction flag
reg ie;						// interrupt enable flag
reg tf;
wire [15:0] flags = {1'b0,1'b0,2'b00,vf,df,ie,tf,sf,zf,1'b0,af,1'b0,pf,1'b0,cf};

reg [7:0] ir;				// instruction register
reg [7:0] ir2;				// extended instruction register
reg [15:0] ip;				// instruction pointer
reg [15:0] ir_ip;			// instruction pointer of ir
reg [15:0] ax;
reg [15:0] bx;
reg [15:0] cx;
reg [15:0] dx;
reg [15:0] si;				// source index
reg [15:0] di;				// destination index
reg [15:0] bp;				// base pointer
reg [15:0] sp;				// stack pointer
wire cxz = cx==16'h0000;	// CX is zero

reg [15:0] cs;				// code segment
reg [15:0] ds;				// data segment
reg [15:0] es;				// extra segment
reg [15:0] ss;				// stack segment

// renamed byte registers for convenience
wire [7:0] al = ax[7:0];
wire [7:0] ah = ax[15:8];
wire [7:0] dl = dx[7:0];
wire [7:0] dh = dx[15:8];
wire [7:0] cl = cx[7:0];
wire [7:0] ch = cx[15:8];
wire [7:0] bl = bx[7:0];
wire [7:0] bh = bx[15:8];

wire [19:0] csip = {cs,4'd0} + ip;
wire [19:0] sssp = {ss,4'd0} + sp;
wire [19:0] dssi = {ds,4'd0} + si;
wire [19:0] esdi = {es,4'd0} + di;

// Read port
//
always_comb
	case({w,rrr})
	4'd0:	rrro <= {{8{ax[7]}},ax[7:0]};
	4'd1:	rrro <= {{8{cx[7]}},cx[7:0]};
	4'd2:	rrro <= {{8{dx[7]}},dx[7:0]};
	4'd3:	rrro <= {{8{bx[7]}},bx[7:0]};
	4'd4:	rrro <= {{8{ax[15]}},ax[15:8]};
	4'd5:	rrro <= {{8{cx[15]}},cx[15:8]};
	4'd6:	rrro <= {{8{dx[15]}},dx[15:8]};
	4'd7:	rrro <= {{8{bx[15]}},bx[15:8]};
	4'd8:	rrro <= ax;
	4'd9:	rrro <= cx;
	4'd10:	rrro <= dx;
	4'd11:	rrro <= bx;
	4'd12:	rrro <= sp;
	4'd13:	rrro <= bp;
	4'd14:	rrro <= si;
	4'd15:	rrro <= di;
	endcase


// Second Read port
//
always_comb
	case({w,rm})
	4'd0:	rmo <= {{8{ax[7]}},ax[7:0]};
	4'd1:	rmo <= {{8{cx[7]}},cx[7:0]};
	4'd2:	rmo <= {{8{dx[7]}},dx[7:0]};
	4'd3:	rmo <= {{8{bx[7]}},bx[7:0]};
	4'd4:	rmo <= {{8{ax[15]}},ax[15:8]};
	4'd5:	rmo <= {{8{cx[15]}},cx[15:8]};
	4'd6:	rmo <= {{8{dx[15]}},dx[15:8]};
	4'd7:	rmo <= {{8{bx[15]}},bx[15:8]};
	4'd8:	rmo <= ax;
	4'd9:	rmo <= cx;
	4'd10:	rmo <= dx;
	4'd11:	rmo <= bx;
	4'd12:	rmo <= sp;
	4'd13:	rmo <= bp;
	4'd14:	rmo <= si;
	4'd15:	rmo <= di;
	endcase


// Read segment registers
//
always_comb
	case(sreg3)
	3'd0:	rfso <= es;
	3'd1:	rfso <= cs;
	3'd2:	rfso <= ss;
	3'd3:	rfso <= ds;
	default:	rfso <= 16'h0000;
	endcase
