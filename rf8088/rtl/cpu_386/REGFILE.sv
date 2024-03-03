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

reg [31:0] rrro;			
reg [31:0] rmo;				// register output (controlled by mod r/m byte)
reg [31:0] rfso;

reg pf;						// parity flag
reg af;						// auxillary carry (half carry) flag
reg zf, cf, vf;
reg sf;						// sign flag
reg df;						// direction flag
reg ie;						// interrupt enable flag
reg tf;
wire [31:0] flags = {1'b0,1'b0,2'b00,vf,df,ie,tf,sf,zf,1'b0,af,1'b0,pf,1'b0,cf};

reg [7:0] ir;				// instruction register
reg [7:0] ir2;				// extended instruction register
reg [31:0] eip;				// instruction pointer
reg [31:0] ir_ip;			// instruction pointer of ir
reg [31:0] eax;
reg [31:0] ebx;
reg [31:0] ecx;
reg [31:0] edx;
reg [31:0] esi;				// source index
reg [31:0] edi;				// destination index
reg [31:0] ebp;				// base pointer
reg [31:0] esp;				// stack pointer
wire cxz = ecx==32'h0000;	// CX is zero

reg [15:0] cs;				// code segment
reg [15:0] ds;				// data segment
reg [15:0] es;				// extra segment
reg [15:0] fs;				// extra segment
reg [15:0] gs;				// extra segment
reg [15:0] ss;				// stack segment

desc386_t cs_desc;
desc386_t ds_desc;
desc386_t es_desc;
desc386_t fs_desc;
desc386_t gs_desc;
desc386_t ss_desc;
reg [31:0] gdtr, ldtr;

// renamed byte registers for convenience
wire [7:0] al = eax[7:0];
wire [7:0] ah = eax[15:8];
wire [7:0] dl = edx[7:0];
wire [7:0] dh = edx[15:8];
wire [7:0] cl = ecx[7:0];
wire [7:0] ch = ecx[15:8];
wire [7:0] bl = ebx[7:0];
wire [7:0] bh = ebx[15:8];
wire [15:0] ax = eax[15:0];
wire [15:0] bx = ebx[15:0];
wire [15:0] cx = ecx[15:0];
wire [15:0] dx = edx[15:0];

wire [31:0] cs_base = cs_desc.db ? {cs_desc.base_hi, cs_desc.base_lo} : {cs_desc.base_hi, cs_desc.base_lo} + {cs,`SEG_SHIFT};
wire [31:0] ss_base = cs_desc.db ? {ss_desc.base_hi, ss_desc.base_lo} : {ss_desc.base_hi, ss_desc.base_lo} + {ss,`SEG_SHIFT};
wire [31:0] ds_base = cs_desc.db ? {ds_desc.base_hi, ds_desc.base_lo} : {ds_desc.base_hi, ds_desc.base_lo} + {ds,`SEG_SHIFT};
wire [31:0] es_base = cs_desc.db ? {es_desc.base_hi, es_desc.base_lo} : {es_desc.base_hi, es_desc.base_lo} + {es,`SEG_SHIFT};
wire [31:0] fs_base = cs_desc.db ? {fs_desc.base_hi, fs_desc.base_lo} : {fs_desc.base_hi, fs_desc.base_lo} + {fs,`SEG_SHIFT};
wire [31:0] gs_base = cs_desc.db ? {gs_desc.base_hi, gs_desc.base_lo} : {gs_desc.base_hi, gs_desc.base_lo} + {gs,`SEG_SHIFT};

wire [31:0] csip = cs_base + ip;
wire [31:0] sssp = ss_base + (cs_desc.db ? esp : sp);
wire [31:0] dssi = ds_base + (cs_desc.db ? esi : si);
wire [31:0] esdi = es_base + (cs_desc.db ? edi : di);

// Read port
//
always_comb
	case({w,rrr})
	4'd0:	rrro <= {{8{eax[7]}},eax[7:0]};
	4'd1:	rrro <= {{8{ecx[7]}},ecx[7:0]};
	4'd2:	rrro <= {{8{edx[7]}},edx[7:0]};
	4'd3:	rrro <= {{8{ebx[7]}},ebx[7:0]};
	4'd4:	rrro <= {{8{eax[15]}},eax[15:8]};
	4'd5:	rrro <= {{8{ecx[15]}},ecx[15:8]};
	4'd6:	rrro <= {{8{edx[15]}},edx[15:8]};
	4'd7:	rrro <= {{8{ebx[15]}},ebx[15:8]};
	4'd8:	rrro <= eax;
	4'd9:	rrro <= ecx;
	4'd10:	rrro <= edx;
	4'd11:	rrro <= ebx;
	4'd12:	rrro <= esp;
	4'd13:	rrro <= ebp;
	4'd14:	rrro <= esi;
	4'd15:	rrro <= edi;
	endcase


// Second Read port
//
always_comb
	case({w,rm})
	4'd0:	rmo <= {{8{eax[7]}},eax[7:0]};
	4'd1:	rmo <= {{8{ecx[7]}},ecx[7:0]};
	4'd2:	rmo <= {{8{edx[7]}},edx[7:0]};
	4'd3:	rmo <= {{8{ebx[7]}},ebx[7:0]};
	4'd4:	rmo <= {{8{eax[15]}},eax[15:8]};
	4'd5:	rmo <= {{8{ecx[15]}},ecx[15:8]};
	4'd6:	rmo <= {{8{edx[15]}},edx[15:8]};
	4'd7:	rmo <= {{8{ebx[15]}},ebx[15:8]};
	4'd8:	rmo <= eax;
	4'd9:	rmo <= ecx;
	4'd10:	rmo <= edx;
	4'd11:	rmo <= ebx;
	4'd12:	rmo <= esp;
	4'd13:	rmo <= ebp;
	4'd14:	rmo <= esi;
	4'd15:	rmo <= edi;
	endcase


// Read segment registers
//
always_comb
	case(sreg3)
	3'd0:	rfso <= es;
	3'd1:	rfso <= cs;
	3'd2:	rfso <= ss;
	3'd3:	rfso <= ds;
	3'd4:	rfso <= fs;
	3'd5:	rfos <= gs;
	default:	rfso <= 16'h0000;
	endcase
