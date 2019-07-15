/* ===============================================================
	(C) 2002  Bird Computer
	All rights reserved.

	bc6502.v
	Version 1.0

	You are free to use and modify this code for non-commercial
	or evaluation purposes.
	
	If you do modify the code, please state the origin and
	note that you have modified the code.
	
	Please read the license agreement (license.html) file.
	
	Generic original 6502 compatible core.
	Undoc'd instructions are not supported.
	
==============================================================-= */

`timescale 1ns / 100ps

`define RESET_VEC	16'hFFFC
`define NMI_VEC		16'hFFFA
`define IRQ_VEC		16'hFFFE
`define BRK_VEC		16'hFFFE
`define SP_RESET	8'hFF		// reset value of the stack pointer

`define DECMD_SUPPORT	1

// Don't confuse these with the parameters!
`define DBW		8
`define ABW		16

`define JSR		8'h20
`define JMP		8'h4C
`define JMP_I	8'h6C
`define RTS		8'h60
`define RTI		8'h40

`define PHP		8'h08
`define PHA		8'h48
`define PLP		8'h28
`define PLA		8'h68

`define BRK		8'h00
`define INX		8'hE8
`define DEX		8'hCA
`define INY		8'hC8
`define DEY		8'h88

`define TYA		8'h98
`define TAY		8'ha8
`define TXA		8'h8A
`define	TAX		8'hAA
`define TXS		8'h9A
`define	TSX		8'hBA

`define ASL_A	8'h0A
`define ASL_Z	8'h06
`define ASL_ZX	8'h16
`define ASL_ABS	8'h0E
`define ASL_AX	8'h1E
`define	ROL_A	8'h2A
`define ROL_Z	8'h26
`define ROL_ZX	8'h36
`define ROL_ABS	8'h2E
`define ROL_AX	8'h3e
`define LSR_A	8'h4A
`define LSR_Z	8'h46
`define LSR_ZX	8'h56
`define LSR_ABS	8'h4E
`define LSR_AX	8'h5E
`define	ROR_A	8'h6A
`define ROR_Z	8'h66
`define ROR_ZX	8'h76
`define ROR_ABS	8'h6E
`define ROR_AX	8'h7E

`define DEC_Z	8'hC6
`define DEC_ZX	8'hD6
`define DEC_A	8'hCE
`define DEC_AX	8'hDE
`define INC_Z	8'hE6
`define INC_ZX	8'hF6
`define INC_A	8'hEE
`define INC_AX	8'hFE

`define CLD		8'hD8
`define SED		8'hF8
`define CLC		8'h18
`define	SEC		8'h38
`define	CLI		8'h58
`define	SEI		8'h78
`define CLV		8'hB8

`define NOP		8'hEA

// Group0 opcodes
`define GROUP0	2'b00
`define BIT		3'b001
`define STY		3'b100
`define LDY		3'b101
`define CPY		3'b110
`define CPX		3'b111

// Group1 opcodes
`define GROUP1	2'b01
`define	ORA		3'b000
`define AND		3'b001
`define EOR		3'b010
`define ADC		3'b011
`define STA		3'b100
`define LDA		3'b101
`define CMP		3'b110
`define SBC		3'b111

// Group2 opcodes
`define GROUP2	2'b10
`define ASL		3'b000
`define ROL		3'b001
`define LSR		3'b010
`define ROR		3'b011
`define STX		3'b100
`define LDX		3'b101
`define DEC		3'b110
`define INC		3'b111

`define BPL		3'b000
`define BMI		3'b001
`define BVC		3'b010
`define BVS		3'b011
`define BCC		3'b100
`define BCS		3'b101
`define BNE		3'b110
`define BEQ		3'b111

`define LDA_I	8'hA9
`define LDA_Z	8'hA5
`define LDA_ZX	8'hB5
`define LDA_IX	8'hA1
`define LDA_IY	8'hB1
`define LDA_A	8'hAD
`define LDA_AX	8'hBD
`define LDA_AY	8'hB9

`define LDY_I	8'hA0
`define LDY_Z	8'hA4
`define LDY_ZX	8'hB4
`define LDY_A	8'hAC
`define LDY_AX	8'hBC

`define CPY_I	8'hC0

`define LDX_I	8'hA2
`define	LDX_Z	8'hA6
`define LDX_ZY	8'hB6
`define LDX_A	8'hAE
`define LDX_AY	8'hBE

`define CPX_I	8'hE0

`define STA_Z	8'h85
`define STA_ZX	8'h95
`define STA_IX	8'h81
`define STA_IY	8'h91
`define STA_A	8'h8D
`define STA_AX	8'h9D
`define STA_AY	8'h99

`define STY_Z	8'h84
`define STY_ZX	8'h94
`define STY_A	8'h8C

`define	STX_Z	8'h86
`define STX_ZY	8'h96
`define STX_A	8'h8E


module bc6502(reset, clk, nmi, irq, rdy, so, di, do, rw, ma,
	rw_nxt, ma_nxt, sync, state, flags);
	parameter ABW = `ABW;
	parameter DBW = `DBW;

	input reset;
	input clk;
	input nmi;				// active high
	input irq;				// active high
	input rdy;
	input so;				// set overflow
	input [DBW-1:0] di;		// data input bus
	output [DBW-1:0] do;	// data output bus
	reg [DBW-1:0] do;
	output rw;
	reg rw;
	output [ABW-1:0] ma;
	reg [ABW-1:0] ma;
	// The following two signals can be useful for interfacing
	// to synchronous memory by providing values just before the
	// clock edge rather than after.
	output rw_nxt;
	output [ABW-1:0] ma_nxt;
	tri [ABW-1:0] ma_nxt;
	output sync;
	// The following two signals are provided mainly for
	// debugging.
	output [31:0] state;	// cpu state
	output [4:0] flags;

	//-----------------------------------
	reg [7:0] cres;		// critical reset sequencer
	wire creset = cres[7];
	reg [DBW-1:0] ir;
	reg [DBW-1:0] dil;	// data input latch

	// Processor Programming Model registers
	reg	[DBW-1:0] a_reg;		// A accumulator
	reg [DBW-1:0] x_reg;		// X index register
	reg [DBW-1:0] y_reg;		// Y index register
	reg [DBW-1:0] sp_reg;		// SP stack pointer
	reg	[ABW-1:0] pc_reg;		// PC program counter
	reg nf,vf,bf,df,im,zf,cf;	// SR status register
	wire [7:0] sr_reg = {nf,vf,1'b1,bf,df,im,zf,cf};

	tri [DBW-1:0] res;					// internal result bus
	reg [DBW-1:0] tmp;					// temp reg needed for some operations
	reg [ABW-1:0] pc_nxt;
	reg [DBW-1:0] dout_nxt;
	reg rw_nxt;

	reg prev_nmi;				// track previous nmi state for edge detection
	wire nmi_edge = nmi & ~prev_nmi;
	wire any_int = nmi_edge | (irq & ~im);

	// cpu states
	wire s_reset;
	wire s_reset1;
	wire s_reset2;
	wire s_reset3;
	wire s_nmi1, s_nmi2, s_nmi3, s_nmi4, s_nmi5;
	wire s_ld_pch;
	wire s_exec;
	wire s_branch;
	wire s_dataFetch;
	wire s_update;
	wire s_afterWrite;
	wire s_ix1, s_ix2;
	wire s_iy1, s_iy2;
	wire s_abs1;
	wire s_jmpi1;
	wire s_jsr1, s_jsr2;
	wire s_pul;
	wire s_rts1, s_rts2, s_rts3;
	wire s_rti1, s_rti2, s_rti3;
	wire s_sync;

	assign state = {
		s_reset, s_reset1, s_reset2, s_reset3,
		s_nmi1,	s_nmi2,	s_nmi3,	s_nmi4,	s_nmi5,
		s_ld_pch,
		s_exec,
		s_branch,
		s_dataFetch,
		s_update,
		s_afterWrite,
		s_ix1, s_ix2,
		s_iy1, s_iy2,
		s_abs1,
		s_jmpi1,
		s_jsr1,	s_jsr2,
		s_pul,
		s_rts1,	s_rts2,	s_rts3,
		s_rti1,	s_rti2, s_rti3,
		s_sync};

	assign sync = s_sync;

	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	// Instruction Decoding Section
	wire [2:0] cond = ir[7:5];
	wire branch = ir[4:0]==5'b10000;
	reg taken;
	assign flags = {nf,zf,cf,vf,taken};

	wire jmp = (ir == `JMP);
	wire jmpi = (ir == `JMP_I);

	wire php = ir==`PHP;
	wire pha = ir==`PHA;
	wire psh = php|pha;
	wire plp = ir==`PLP;
	wire pla = ir==`PLA;
	wire pul = plp|pla;

	wire jsr = ir==`JSR;
	wire rts = ir==`RTS;
	wire rti = ir==`RTI;
	wire brk = ir==`BRK;

	wire nop = ir==`NOP;	
	wire inx = ir==`INX;
	wire iny = ir==`INY;
	wire dex = ir==`DEX;
	wire dey = ir==`DEY;

	wire clc = ir==`CLC;
	wire cld = ir==`CLD;
	wire clv = ir==`CLV;
	wire cli = ir==`CLI;
	wire sec = ir==`SEC;
	wire sed = ir==`SED;
	wire sei = ir==`SEI;
	
	wire tay = ir==`TAY;
	wire tya = ir==`TYA;
	wire tax = ir==`TAX;
	wire txa = ir==`TXA;
	wire tsx = ir==`TSX;
	wire txs = ir==`TXS;

	wire ror_a = ir==`ROR_A;
	wire lsr_a = ir==`LSR_A;
	wire rol_a = ir==`ROL_A;
	wire asl_a = ir==`ASL_A;
	
	wire ldx = ir[7:5]==`LDX;
	wire stxx= ir[7:5]==`STX;
	wire ror = ir[7:5]==`ROR;
	wire rol = ir[7:5]==`ROL;
	wire lsr = ir[7:5]==`LSR;
	wire asl = ir[7:5]==`ASL;
	wire inc = ir[7:5]==`INC;
	wire dec = ir[7:5]==`DEC;

	wire ldy = ir[7:5]==`LDY;
	wire styy = ir[7:5]==`STY;
	wire cmp = ir[7:5]==`CMP;
	
	wire ldy_i = ir==`LDY_I;
	wire cpy_i = ir==`CPY_I;
	wire ldx_i = ir==`LDX_I;
	wire cpx_i = ir==`CPX_I;

	// miscellaneous operations
	wire mop = nop | inx | dex | iny | dey |
				txa | tax | tya | tay | txs | tsx |
				cld | sed | sei | cli | sec | clc | clv |
				asl_a | lsr_a | ror_a | rol_a;

	// address modes zp:zp,x:zp,y:(zp,x):(zp),y:#:abs:abs,x:abs,y
	wire ix = 	(ir[4:2]==3'b000&&ir[0]==1'b1);
	wire zp = 	(ir[4:2]==3'b001);
	wire imm =	(ir[4:2]==3'b010&&ir[0]==1'b1) || (ir[7]==1'b1 && ir[4:0]==5'b00000) || ldx_i;
	wire abs = 	(ir[4:2]==3'b011);
	wire iy = 	(ir[4:2]==3'b100&&ir[0]==1'b1);
	wire zpy =  (ir==`STX_ZY || ir==`LDX_ZY);
	wire zpx = 	(ir[4:2]==3'b101) && !zpy;
	wire absy = (ir[4:2]==3'b110 && ir[0]==1'b1) || ir==`LDX_AY;
	wire absx = (ir[4:2]==3'b111) && !absy;
	wire zpxy = zp|zpx|zpy;
	wire absxy = abs|absx|absy;

	// sta/stx/sty
	wire sta = ir==`STA_Z||ir==`STA_ZX||ir==`STA_IX
		||ir==`STA_IY||ir==`STA_A||ir==`STA_AX
		||ir==`STA_AY;
	wire sty = ir==`STY_Z||ir==`STY_ZX||ir==`STY_A;
	wire stx = ir==`STX_Z||ir==`STX_ZY||ir==`STX_A;
	wire staxy = sta | stx | sty;


	wire grp0 = ir[1:0]==2'b00;
	wire grp1 = ir[1:0]==2'b01;
	wire grp2 = ir[1:0]==2'b10;
	wire grp2m = (asl | rol | lsr | ror | dec | inc) & grp2;	// memory ops
	wire grp2x = (ldx | stxx) & grp2;	// X reg. ops
	// When to update the status flags
	wire grp0_us = (ir[3:0]==4'h4 || ir[3:0]==4'hC || (ldy_i | cpy_i | cpx_i));
	wire grp1_us = grp1;
	wire grp2_us = grp2 && ir[3:0]!=4'hA;


	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	// Select between A, X, or Y registers
	reg [7:0] axy_reg;
	always @(a_reg or x_reg or y_reg or stx or sty or tya or txa or
		inx or dex or iny or dey or txs)
	begin
		if (inx|dex|stx|txa|txs)
			axy_reg <= x_reg;
		else if (iny|dey|sty|tya)
			axy_reg <= y_reg;
		else
			axy_reg <= a_reg;
	end

	// incrementers / decrementers
	// Note: addsub needs inverted carry for subtract!!!
	// A separate module is used here to allow the synthesizer
	// to make better use of resources.
	wire [7:0] axy_addo;
	addsub #(8) axy_adder(
		.op(dex | dey),
		.ci(dex | dey),
		.a({1'b0,axy_reg}),
		.b(9'h1),
		.o(axy_addo),
		.co(), .v()
	);

	wire [7:0] sp_addo;
	addsub #(8) spadder(
		.op(s_nmi1 | s_nmi2 |
			s_jsr1 | s_jsr2 |
			(s_sync & any_int) |
			(s_exec & (brk|psh))),
		.ci(s_nmi1 | s_nmi2 |
			s_jsr1 | s_jsr2 |
			(s_sync & any_int) |
			(s_exec & (brk|psh))),
		.a({1'b0,sp_reg}),
		.b(9'h1),
		.o(sp_addo),
		.co(), .v()
	);

	// these flags are used to merge states together
	reg firq, fbrk;

	wire nfo0,cfo0,vfo0,zfo0;
	wire nfo1,cfo1,vfo1,zfo1;
	wire nfo2,cfo2,zfo2;
	wire [DBW-1:0] grp0_o;
	wire [DBW-1:0] grp1_o;
	wire [DBW-1:0] grp2_o;

	// datapath processing
	dp_group0 grp0_inst(.ir(ir),
		.a_reg(a_reg), .x_reg(x_reg), .y_reg(y_reg), .d(dil),
		.ni(nf), .vi(vf), .zi(zf), .ci(cf),
		.n(nfo0), .v(vfo0), .z(zfo0), .c(cfo0) );

	dp_group1 grp1_inst(.ir(ir), .dec(df),
		.ni(nf), .vi(vf), .zi(zf), .ci(cf),
		.a_reg(a_reg), .d(dil), .o(grp1_o),
		.n(nfo1), .v(vfo1), .z(zfo1), .c(cfo1) );

	dp_group2 grp2_inst(.ir(ir), .ldx(ldx), .stxx(stxx), .d(dil),
		.ci(cf), .ni(nf), .zi(zf),
		.c(cfo2), .n(nfo2), .z(zfo2),
		.o(grp2_o) );

	// inline datapath processing
	assign res = s_exec & (inx|iny)|(dex|dey) ? axy_addo : 8'bz;
	assign res = s_exec & (tay|tax|txa|tya|txs) ? axy_reg : 8'bz;
	assign res = s_exec & tsx ? sp_reg : 8'bz;
	assign res = s_exec & ror_a ? {cf,a_reg[DBW-1:1]} : 8'bz;
	assign res = s_exec & lsr_a ? {1'b0,a_reg[DBW-1:1]} : 8'bz;
	assign res = s_exec & rol_a ? {a_reg[DBW-2:0],cf} : 8'bz;
	assign res = s_exec & asl_a ? {a_reg[DBW-2:0],1'b0} : 8'bz;

	assign res = s_pul ? di : 8'bz;
	assign res = s_update & (grp0|grp2) ? dil : 8'bz;
	assign res = s_update & grp1 ? grp1_o : 8'bz;


	// control unit
	sequencer seq0(
		.reset(reset), .creset(creset), .clk(clk), .rdy(rdy),
		.any_int(any_int),
		.grp0(grp0), .grp1(grp1), .grp2x(grp2x), .grp2m(grp2m),
		.brk(brk),
		.mop(mop),
		.rti(rti), .rts(rts),
		.pul(pul), .psh(psh),
		.jsr(jsr),
		.jmp(jmp), .jmpi(jmpi), .branch(branch), .staxy(staxy),
		.ix(ix), .iy(iy), .absxy(absxy), .imm(imm), .zpxy(zpxy),
		.s_reset(s_reset), .s_reset1(s_reset1), .s_reset2(s_reset2), .s_reset3(s_reset3),
		.s_nmi1(s_nmi1), .s_nmi2(s_nmi2), .s_nmi3(s_nmi3), .s_nmi4(s_nmi4), .s_nmi5(s_nmi5),
		.s_ld_pch(s_ld_pch), .s_exec(s_exec), .s_branch(s_branch), .s_dataFetch(s_dataFetch), .s_update(s_update),
		.s_afterWrite(s_afterWrite),
		.s_ix1(s_ix1), .s_ix2(s_ix2), .s_iy1(s_iy1), .s_iy2(s_iy2),
		.s_abs1(s_abs1),
		.s_jmpi1(s_jmpi1),
		.s_jsr1(s_jsr1), .s_jsr2(s_jsr2),
		.s_pul(s_pul),
		.s_rts1(s_rts1), .s_rts2(s_rts2), .s_rts3(s_rts3),
		.s_rti1(s_rti1), .s_rti2(s_rti2), .s_rti3(s_rti3),
		.s_sync(s_sync) );


	// Generate critical reset
	always @(posedge clk)
		if (reset)
			cres <= 8'hFF;
		else
			cres <= {cres[6:0],1'b0};

	//-------------------------------------------------------------
	// Memory related hardware
	//-------------------------------------------------------------

	// Determine exception vector address
	reg [ABW-1:0] vec;
	always @(s_nmi3 or firq or fbrk) begin
		if (s_nmi3) begin
			if (firq)
				vec <= `IRQ_VEC;
			else if (fbrk)
				vec <= `BRK_VEC;
			else
				vec <= `NMI_VEC;
		end
		else
			vec <= `RESET_VEC;
	end


	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	// Select between X, Y, Z registers for memory addressing.
	reg [7:0] xyz_reg;
	always @(x_reg or y_reg or absx or absy or zpx or zpy or
		s_iy2 or ix or s_abs1 or s_exec)
	begin
		if ((s_abs1 & absx)|(s_exec & (zpx|ix)))
			xyz_reg <= x_reg;
		else if ((s_abs1 &absy)|(s_exec & zpy)|s_iy2)
			xyz_reg <= y_reg;
		else
			xyz_reg <= 8'h00;
	end


	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	// memory address multiplexing
	// Because of the amount of multiplexing on the address bus
	// a multiplexor is implemented with a tri-state bus.
	// Otherwise a 16 bit 16 to 1 multiplexor would be required
	// which uses a lot of resources.

	// ma = vector
	assign ma_nxt = (reset | s_reset | s_reset1 | s_nmi3) ? vec : 16'bz;
	// ma = ma + 1
	assign ma_nxt = (s_reset2 | s_nmi4 | s_jmpi1 | s_ix1 | s_iy1) ? ma + 1 : 16'bz;
	// ma = pc + 1
	assign ma_nxt = ((s_sync & ~any_int) | (s_exec & (absxy | jsr | branch)) | s_rts3) ? pc_reg + 1 : 16'bz;
	// ma = tmp
	// abs,y must take precedence over abs,x
	assign ma_nxt = (s_reset3 | s_nmi5 | s_rti3 | s_rts2 | s_ld_pch | 
		s_iy2 | s_ix2 | s_abs1 ) ? {{di,tmp}+xyz_reg} : 16'bz;	// abs : abs,x : abs,y : (zp),y
	// zero page modes
	assign ma_nxt = (s_exec & (zpxy | ix | iy)) ? {8'h00,di + xyz_reg} : 16'bz;		// zp : zp,x : zp,y : (zp,x) : (zp),y  // all zp modes

	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	// all stack modes
	assign ma_nxt[ABW-1:8] = ((s_exec & (brk|psh|pul|rts|rti)) |
				s_rts1 |
				s_rti1 | s_rti2 |
				s_nmi1 | s_nmi2 |
				s_jsr1 | s_jsr2 |
				(s_sync & any_int)
				) ? 8'h1 : 8'bz;
	// ma = sp
	assign ma_nxt[7:0] = (
				s_nmi1 | s_nmi2 |
				s_jsr1 | s_jsr2 |
				(s_sync & any_int) |
				(s_exec & (brk|psh))
				) ? sp_reg : 8'bz;
	assign ma_nxt[7:0] = ((s_exec & (pul|rts|rti)) | s_rts1 | s_rti1 | s_rti2) ? sp_addo : 8'bz;

	// branch instr.
	// ma = pc + (sign extend)disp
	assign ma_nxt = (s_branch & taken) ? {pc_reg + {{8{tmp[DBW-1]}},tmp}} : 16'bz;
	// ma = ma
	assign ma_nxt = ((s_dataFetch|s_update) & grp2m) ? ma : 16'bz;
	// ma = pc
	assign ma_nxt = ((s_branch & ~taken) | s_pul | s_afterWrite |
		(s_exec & (imm | mop)) | ((s_dataFetch|s_update) & (grp0 | grp1 | grp2x)) ) ?
		pc_reg : 16'bz;


	//-------------------------------------------------------------
	//-------------------------------------------------------------
	// latch incoming immediate data
	always @(posedge clk)
		if (reset)
			dil <= 8'b0;
		else begin
			if (rdy) begin
				if (s_exec & imm)
					dil <= di;
				else if (s_dataFetch)
					dil <= di;
			end
		end


	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	// pc / ma manipulation
	always @(s_reset3 or s_rts2 or s_rts3 or s_rti3 or s_nmi5 or
		s_exec or s_ld_pch or s_abs1 or 
		jmp or jsr or s_sync or any_int or 
		branch or s_branch or s_jsr1 or s_jsr2 or imm or zpxy or
		ix or iy or absxy or jmpi or pc_reg or di or tmp or ir or
		ma_nxt)
	begin
		if (
			s_rts2 | s_rts3 |
			s_rti3 | s_nmi5 |
			(s_reset3 | s_ld_pch | (s_abs1 & jmp)) |
			(s_sync & ~any_int) |
			s_branch |
			(s_exec & branch) |
			(s_exec & jsr)
			)
			pc_nxt <= ma_nxt;
		else if (s_jsr1)
			pc_nxt <= {di,pc_reg[7:0]};
		else if (s_jsr2)
			pc_nxt <= {pc_reg[15:8],tmp};
		else if (
			(s_exec & (imm | zpxy | ix | iy | absxy)) |
			(s_abs1 & ~(jmp | jmpi)) )
			pc_nxt <= pc_reg + 1;
		else
			pc_nxt <= pc_reg;
	end

	always @(posedge clk)
		if (reset) begin
			pc_reg <= `RESET_VEC;
			ma <= `RESET_VEC;
		end
		else if (rdy) begin
			ma <= ma_nxt;
			pc_reg <= pc_nxt;
		end


	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	// sp manipulation
	// we also reset the other regs here
	always @(posedge clk)
		if (reset)
			sp_reg <= `SP_RESET;
		else if (rdy) begin
			if (
				s_nmi1 | s_nmi2 |
				s_jsr1 | s_jsr2 |
				(s_sync & any_int) |
				(s_exec & (brk|psh|pul|rts|rti)) |
				s_rts1 | s_rti1 | s_rti2
				)
				sp_reg <= sp_addo;
			else if (s_exec & txs)
				sp_reg <= res;
		end


	// tmp manipulation
	always @(posedge clk)
		if (reset)
			tmp <= 0;
		else if (rdy) begin
			if (s_reset2 | s_nmi4 | s_rts1 | s_rti2 |
				s_jmpi1 |
				s_ix1 | s_iy1 | (s_exec & absxy) |
				(s_exec & (jsr | branch))
				)
				tmp <= di;
		end


	// rw manipulation - - - - - - - - - - - - - - - - - - - - - -
	// Note: the cpu is always either reading or writing to memory,
	// it doesn't have any idle cycles. This can be seen from the
	// memory address multiplexer, which is always set to a valid
	// value.
	always @(s_sync or any_int or zpxy or psh or brk or ldx or 
		staxy or s_exec or ir or s_jsr1 or s_jsr2 or
		s_ix2 or
		s_iy2 or s_abs1 or
		s_nmi1 or s_nmi2 or s_update or grp2m)
	begin
		if ( (s_sync & any_int) |
			(s_exec & zpxy & staxy) |
			(s_exec & (brk|psh)) |
			s_jsr1 | s_jsr2 |
			(staxy & (s_ix2 | s_iy2 | s_abs1)) |
			s_nmi1 | s_nmi2 |
			(s_update & grp2m) )
			rw_nxt <= 0;
		else
			rw_nxt <= 1;
	end

	always @(posedge clk)
		if (reset)
			rw <= 1;
		else if (rdy)
			rw <= rw_nxt;


	// dout manipulation - - - - - - - - - - - - - - - - - - - - -
	always @(s_nmi1 or s_nmi2 or
		s_jsr1 or s_jsr2 or pc_reg or sr_reg or
		php or pha or staxy or axy_reg or 
		nf or vf or bf or df or zf or cf or im or brk or 
		s_exec or zpxy or s_ix2 or s_iy2 or grp2m or
		s_abs1 or sta or stx or s_sync or any_int or
		s_update or a_reg or x_reg or y_reg or do or grp2_o)
	begin
		// Place pc on bus for interrupt, or subroutine call
		if ((s_sync & any_int) | (s_exec & brk) | s_jsr1)
			dout_nxt <= pc_reg[ABW-1:8];
		else if (s_nmi1 | s_jsr2)
			dout_nxt <= pc_reg[7:0];
		else if ((staxy & ((s_exec & zpxy) | (s_ix2 | s_iy2 | s_abs1))) |
			(s_exec & pha) )
			dout_nxt <= axy_reg;
		else if ((s_exec & php) | s_nmi2)
			dout_nxt <= sr_reg;
		else if (s_update & grp2m)
			dout_nxt <= grp2_o;
		else
			dout_nxt <= do;
	end

	always @(posedge clk)
		if (reset)
			do <= 8'b0;
		else if (rdy)
			do <= dout_nxt;


	// A,X,Y Register loading -  -  -  -  -  -  -  -  -  -  -  -  -
	always @(posedge clk) begin
		if (reset) begin
			a_reg <= 8'b0;
			x_reg <= 8'b0;
			y_reg <= 8'b0;
		end
		else begin
			if (rdy) begin
				if ( (s_exec & (tya | txa | ror_a | lsr_a | rol_a | asl_a)) |
					(s_pul & pla) |
					(s_update & grp1 & ~cmp) )
					a_reg <= res;
				if ( (s_exec & (inx | dex | tax | tsx)) |
					(s_update & grp2 & ldx) )
					x_reg <= res;
				if ( (s_exec & (iny | dey | tay)) |
					(s_update & grp0 & ldy) )
					y_reg <= res;
			end
		end
	end


	// Load instruction register - - - - - - - - - - - - - - - - -
	// Also track the nmi state for nmi edge detection
	always @(posedge clk)
		if (reset) begin
			ir <= `NOP;
			prev_nmi <= 0;
		end
		else if (s_reset1) begin
			ir <= `NOP;
			prev_nmi <= 0;
		end
		else if (rdy & s_sync) begin
			ir <= di;
			prev_nmi <= nmi;
		end


	// Evaluate branch condition - - - - - - - - - - - - - - - - -
	reg takb;
	always @(cond or nf or vf or cf or zf)
		begin
			case (cond)
			`BPL:	takb <= ~nf;
			`BMI: 	takb <= nf;
			`BVC:	takb <= ~vf;
			`BVS: 	takb <= vf;
			`BCC:	takb <= ~cf;
			`BCS: 	takb <= cf;
			`BNE:	takb <= ~zf;
			`BEQ: 	takb <= zf;
			endcase
		end


	// SR flags updating - - - - - - - - - - - - - - - - - - - - - 
	always @(posedge clk) begin
		if (reset) begin
			firq <= 0;
			vf <= 0;
			nf <= 0;
			im <= 1;
			zf <= 0;
			cf <= 0;
			df <= 0;
			bf <= 0;
		end
		else if (rdy) begin

			if (so)
				vf <= 1'b1;

			if (s_reset1) begin
				firq <= 0;
				fbrk <= 0;
				cf <= 0;
				df <= 0;
				nf <= 0;
				vf <= 0;
				zf <= 0;
				im <= 1;
				bf <= 0;
			end
			// NMI / IRQ / BRK ---------------------
			if (s_nmi2) begin
				bf <= fbrk;
				im <= 1;
			end
			if (s_nmi4) begin
				fbrk <= 0;
				firq <= 0;
			end
			// sync indicates the start of an instruction cycle
			// when active. we can check for an nmi or irq first
			// before proceding with the instruction.
			if (s_sync) begin
				// irq is level sensitive
				if (any_int) begin
					// nmi takes precedence
					if (~nmi_edge)
						firq <= 1;
				end
			end

			else if (s_exec) begin

				taken <= takb;

				case (ir)
				`BRK:	fbrk <= 1;
				`INX,`DEX,`TAX,`TSX,
				`INY,`DEY,`TAY,
				`TYA,`TXA:
						begin
						zf <= res==0;
						nf <= res[DBW-1];
						end
				`CLD:	df <= 0;
				`SED:	df <= 1;
				`CLC:	cf <= 0;
				`SEC:	cf <= 1;
				`CLI:	im <= 0;
				`SEI:	im <= 1;
				`CLV:	vf <= 0;
				`ROR_A,`LSR_A:
						begin
						cf <= a_reg[0];
						zf <= res==0;
						nf <= res[DBW-1];
						end
				`ROL_A,`ASL_A:
						begin
						cf <= a_reg[DBW-1];
						zf <= res==0;
						nf <= res[DBW-1];
						end
				// eval branch cond.
				default: ;
				endcase

				$display("s_exec byte default cond=%h ir=%h ir[7:5]=%h", cond, ir, ir[7:5]);

			end

			//======================================
			// subsequent opcode states
			//======================================
			
			if ((s_pul & plp) | s_rti1) begin
				nf <= res[7];
				vf <= res[6];
				bf <= res[4];
				df <= res[3];
				im <= res[2];
				zf <= res[1];
				cf <= res[0];
			end
			
			if (s_pul & pla) begin
				zf <= res==0;
				nf <= res[DBW-1];
			end

			// mega state1
			// at this point the fetched op should be incoming
			// from d.
			// store will already have been done, except for
			// memory direct
			if (s_update) begin
			
				if (grp0_us) begin
					nf <= nfo0;
					vf <= vfo0;
					cf <= cfo0;
					zf <= zfo0;
				end

				if (grp1_us) begin
					nf <= nfo1;
					vf <= vfo1;
					cf <= cfo1;
					zf <= zfo1;
				end

				if (grp2_us) begin
					nf <= nfo2;
					cf <= cfo2;
					zf <= zfo2;
				end

			end	// `s_update

		end // if (rdy)
	end


endmodule


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Handle Group 0 opcodes - opcodes with the two lsb = 00
// ------00
// LDY, STY, CPY, CPX, and BIT
module dp_group0(ir,a_reg,x_reg,y_reg,d,ni,vi,zi,ci,n,v,z,c);
	parameter DBW = 8;
	input [DBW-1:0] ir;
	input [DBW-1:0] a_reg;
	input [DBW-1:0] x_reg;
	input [DBW-1:0] y_reg;
	input [DBW-1:0] d;
	input ni, vi, zi, ci;
	output n, v, z, c;

	wire [DBW-1:0] w_bit = a_reg & d;
	wire [DBW:0] w_cpy = y_reg - d;
	wire [DBW:0] w_cpx = x_reg - d;

	reg [DBW-1:0] res;
	wire ldy = ir[7:5]==`LDY;
	wire cpy = ir[7:5]==`CPY;
	wire cpx = ir[7:5]==`CPX;
	wire bitt = ir[7:5]==`BIT;

	always @(ir or w_cpx or w_cpy or w_bit or d) begin
		case (ir[7:5])
		`CPX:		res <= w_cpx[DBW-1:0];
		`CPY:		res <= w_cpy[DBW-1:0];
		`BIT:		res <= w_bit;
		default:	res <= d;
		endcase
	end

	assign n = cpy | cpx | ldy ? res[DBW-1] : bitt ? d[7] : ni;
	assign z = cpy | cpx | bitt | ldy ? res==0 : zi;
	assign v = bitt ? d[DBW-2] : vi;
	assign c = cpy ? ~w_cpy[DBW] : cpx ? ~w_cpx[DBW] : ci;

endmodule


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Handle Group 1 opcodes - opcodes with the two lsb = 01
// ------01
// 
module dp_group1(ir,dec,ni,vi,zi,ci,a_reg,d,o,n,v,z,c);
	parameter DBW = 8;
	input [7:0] ir;
	input dec;
	input ni, vi, zi, ci;
	input [DBW-1:0] a_reg;
	input [DBW-1:0] d;
	output [DBW-1:0] o;
	reg [DBW-1:0] o;
	output n, v, z, c;

	wire [DBW-1:0] adc_o, sbc_o, cmp_o;
	wire adc_c, sbc_c, cmp_c;

	wire adc = ir[7:5]==`ADC;
	wire sbc = ir[7:5]==`SBC;
	wire cmp = ir[7:5]==`CMP;
	wire sta = ir[7:5]==`STA;


	// alu ops
	always @(ir or a_reg or d or adc_o or cmp_o or sbc_o) begin
		case(ir[7:5])
		`ORA: 	o <= a_reg | d;
		`AND:	o <= a_reg & d;
		`EOR:	o <= a_reg ^ d;
		`ADC:	o <= adc_o;
		`STA:	o <= a_reg;
		`LDA:	o <= d;
		`CMP:	o <= cmp_o;
		`SBC:	o <= sbc_o;
		endcase
	end


	add #(`DECMD_SUPPORT) add0 (.dec(dec), .ci(ci), .a(a_reg), .b(d), .o(adc_o), .c(adc_c) );
	// 6502 uses inverted carry on subtract
	sub #(`DECMD_SUPPORT) sub0 (.dec(dec), .ci(~ci), .a(a_reg), .b(d), .o(sbc_o), .c(sbc_c) );

	wire [DBW:0] cmp_tmp = a_reg - d;	// compare
	assign cmp_c = cmp_tmp[DBW];
	assign cmp_o = cmp_tmp[DBW-1:0];
	assign n = sta ? ni : o[DBW-1];
	assign z = sta ? zi : o==0;
	assign c = adc ? adc_c : sbc ? ~sbc_c : cmp ? ~cmp_c : ci;
	assign v = (adc | sbc) ?
		 (sbc ^ o[DBW-1] ^ d[DBW-1]) & (~sbc ^ a_reg[DBW-1] ^ d[DBW-1]) : vi;

endmodule


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Handle Group 2 opcodes - opcodes with the two lsb = 10
// ------10
// 
module dp_group2(ir,ldx,stxx,d,ci,ni,zi,c,n,z,o);
	parameter DBW = 8;
	input [7:0] ir;
	input ldx;
	input stxx;
	input [DBW-1:0] d;
	input ci, ni, zi;
	output c, n, z;
	output [DBW-1:0] o;
	reg [DBW-1:0] o;

	reg sc;		// shift carry
	wire d_shift = ~ir[7];
	
	always @(ir or d or ci) begin
		case(ir[7:5])
		`ASL:	begin
				o <= {d[DBW-2:0],1'b0};
				sc <= d[DBW-1];
				end
		`ROL:	begin
				o <= {d[DBW-2:0],ci};
				sc <= d[DBW-1];
				end
		`LSR:	begin
				o <= {1'b0,d[DBW-1:1]};
				sc <= d[0];
				end
		`ROR:	begin
				o <= {ci,d[DBW-1:1]};
				sc <= d[0];
				end
		// A store does not affect the flags so the output can
		// be set to anything.
		`STX:	o <= d;
		// Output needs to be set on a load so the flags can
		// be set.
		`LDX:	o <= d;
		`DEC:	o <= d - 8'd1;
		`INC:	o <= d + 8'd1;
		endcase
	end

	assign c = d_shift ? sc : ci;	// cf set only for shifts
	assign n = stxx ? ni : o[DBW-1];
	assign z = stxx ? zi : o==0;

endmodule


// Yikes!
// If you understand this, you're doing well. It took me
// quite a bit of head scratching. I've basically broken the
// add down into two half adds and adjusted the carry and
// sum based on decimal mode, mimicing the 6502.
// hc2 will only be set in decimal mode if least significant
// nybble is 10 or greater.
module add(dec, ci, a, b, o, c);
	parameter dec_support = 1;	// indicates whether or not to support decimal mode
	input dec;
	input ci;
	input [7:0] a;
	input [7:0] b;
	output [7:0] o;
	output c;

	reg [7:0] o;
	reg c;

	wire c4, c8;
	wire [7:0] dec_sum;
	reg [9:0] bin_sum;

	nyb_add na0(.dec(dec), .ci(ci), .a(a[3:0]), .b(b[3:0]), .o(dec_sum[3:0]), .c(c4) );
	nyb_add na1(.dec(dec), .ci(c4), .a(a[7:4]), .b(b[7:4]), .o(dec_sum[7:4]), .c(c8) );

	always @(a or b or ci)
		bin_sum <= {a,ci} + {b,1'b1};

	always @(bin_sum or dec_sum or c8)
		if (dec_support) begin
			o <= dec_sum;
			c <= c8;
		end
		else begin
			o <= bin_sum[8:1];
			c <= bin_sum[9];
		end

endmodule


module nyb_add(dec, ci, a, b, o, c);
	input dec;	// decimal mode indicator
	input ci;	// carry in
	input [3:0] a;
	input [3:0] b;
	output [3:0] o;
	output c;

	// Note: XST does not like assigning to grouped bits on LHS
	// which is why all the temps
	reg [5:0] tmp1;
	reg [4:0] tmp2;
	wire hc1 = tmp1[5];
	wire hc2 = tmp2[4];
	assign c = hc1 | hc2;
	wire [3:0] sum = tmp1[4:1];
	assign o = tmp2[3:0];

	always @(dec or a or b or ci or sum or hc1) begin
		tmp1 <= {a,ci} + {b,1'b1};
		// +6 if in decimal mode and lo nybble > 10
		if (sum >= 4'd10)
			tmp2 <= sum + {1'b0,dec,dec,1'b0};
		else
			tmp2 <= sum;
	end
		
endmodule


// Subtract is similar to add. In decimal mode, if the subtract
// results in a negative number, then six has to be subtracted
// from the nybble.

module sub(dec, ci, a, b, o, c);
	parameter dec_support = 1;	// indicates whether or not to support decimal mode
	input dec;
	input ci;
	input [7:0] a;
	input [7:0] b;
	output [7:0] o;
	output c;

	reg [7:0] o;
	reg c;

	wire c4, c8;
	wire [7:0] dec_dif;
	reg [9:0] bin_dif;

	nyb_sub ns0(.dec(dec), .ci(ci), .a(a[3:0]), .b(b[3:0]), .o(dec_dif[3:0]), .c(c4) );
	nyb_sub ns1(.dec(dec), .ci(c4), .a(a[7:4]), .b(b[7:4]), .o(dec_dif[7:4]), .c(c8) );

	always @(a or b or ci)
		bin_dif <= {a,~ci} - {b,1'b1};

	always @(bin_dif or dec_dif or c8)
		if (dec_support) begin
			o <= dec_dif;
			c <= c8;
		end
		else begin
			o <= bin_dif[8:1];
			c <= bin_dif[9];
		end

endmodule


module nyb_sub(dec, ci, a, b, o, c);
	input dec;	// decimal mode indicator
	input ci;	// carry in
	input [3:0] a;
	input [3:0] b;
	output [3:0] o;
	output c;

	// Note: XST does not like assigning to grouped bits on LHS
	// which is why all the temps
	reg [5:0] tmp1;
	reg [4:0] tmp2;
	wire hb1 = tmp1[5];
	wire hb2 = tmp2[4];
	assign c = hb1 | hb2;
	wire [3:0] dif = tmp1[4:1];
	assign o = tmp2[3:0];

	always @(dec or a or b or ci or dif or hb1) begin
		tmp1 <= {a,~ci} - {b,1'b1};
		// -6 if in decimal mode and lo nybble < 0
		tmp2 <= dif - {1'b0, hb1 & dec, hb1 & dec, 1'b0};
	end
		
endmodule


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// 		This module sequences through the states based on previous
// states, the ir value, and some control signals.
//		A one hot state machine is used because we have plenty
// of regs and it eases decoding.
module sequencer(reset, creset, clk, rdy,
	any_int, grp0, grp1, grp2x, grp2m,
	brk,
	mop,
	rti, rts, pul, psh,
	jsr,
	jmp, jmpi, branch, staxy, ix, iy, absxy, imm, zpxy,
	s_reset, s_reset1, s_reset2, s_reset3,
	s_nmi1, s_nmi2, s_nmi3, s_nmi4, s_nmi5,
	s_ld_pch, s_exec, s_branch, s_dataFetch, s_update, s_afterWrite,
	s_ix1, s_ix2, s_iy1, s_iy2,
	s_abs1,
	s_jmpi1,
	s_jsr1, s_jsr2,
	s_pul,
	s_rts1, s_rts2, s_rts3,
	s_rti1, s_rti2, s_rti3,
	s_sync);
	input reset;
	input creset;
	input clk;
	input rdy;
	input any_int;
	input grp0, grp1, grp2x, grp2m;
	input brk;
	input mop;
	input rti;
	input rts;
	input pul;
	input psh;
	input jsr;
	input jmp;
	input jmpi;
	input branch;
	input staxy;
	input ix;
	input iy;
	input absxy;
	input imm;
	input zpxy;
	output s_reset;
	output s_reset1;
	output s_reset2;
	output s_reset3;
	output s_nmi1, s_nmi2, s_nmi3, s_nmi4, s_nmi5;
	output s_ld_pch;
	output s_exec;
	output s_branch;
	output s_dataFetch;
	output s_update;
	output s_afterWrite;
	output s_ix1, s_ix2;
	output s_iy1, s_iy2;
 	output s_abs1;
	output s_jmpi1;
	output s_jsr1, s_jsr2;
	output s_pul;
	output s_rts1, s_rts2, s_rts3;
	output s_rti1, s_rti2, s_rti3;
	output s_sync;

	reg s_reset;
	reg s_reset1;
	reg s_reset2;
	reg s_reset3;
	reg s_nmi1, s_nmi2, s_nmi3, s_nmi4, s_nmi5;
	reg s_ld_pch;
	reg s_exec;
	reg s_branch;
	reg s_dataFetch;
	reg s_update;
	reg s_afterWrite;
	reg s_ix1;
	reg s_ix2;
	reg s_iy1;
	reg s_iy2;
	reg s_abs1;
	reg s_jmpi1;
	reg s_jsr1, s_jsr2;
	reg s_pul;
	reg s_rts1, s_rts2, s_rts3;
	reg s_rti1, s_rti2, s_rti3;
	reg s_sync;

	always @(posedge clk) begin
		// put our states in a known condition - none selected
		if (reset) begin
			s_reset <= 1;
			s_reset1 <= 0;
			s_reset2 <= 0;
			s_reset3 <= 0;
			s_nmi1 <= 0;
			s_nmi2 <= 0;
			s_nmi3 <= 0;
			s_nmi4 <= 0;
			s_nmi5 <= 0;
			s_ld_pch <= 0;
			s_exec <= 0;
			s_branch <= 0;
			s_dataFetch <= 0;	// Latch in non-immediate data
			s_update <= 0;		// Update the machine state
			s_afterWrite <= 0;	// Switch the address bus back to pc after a write.
			s_ix1 <= 0;
			s_ix2 <= 0;
			s_iy1 <= 0;
			s_iy2 <= 0;
			s_abs1 <= 0;
			s_jmpi1 <= 0;
			s_jsr1 <= 0;
			s_jsr2 <= 0;
			s_pul <= 0;
			s_rts1 <= 0;
			s_rts2 <= 0;
			s_rts3 <= 0;
			s_rti1 <= 0;
			s_rti2 <= 0;
			s_rti3 <= 0;
			s_sync <= 0;
		end
		else if (creset)
			s_reset <= 1;
		else if (rdy) begin
			// advance states
			// Only a single state should be active at any one time
			
			// the reset state is actually evaluated here rather
			// than at a higher level as it is convenient to do so
			if (s_reset)
				s_reset <= 0;

			s_reset1 <= s_reset;
			s_reset2 <= s_reset1;
			s_reset3 <= s_reset2;
			s_nmi1 <= (s_sync & any_int) | (s_exec & brk);
			s_exec <= s_sync & ~any_int;
			s_nmi2 <= s_nmi1;
			s_nmi3 <= s_nmi2;
			s_nmi4 <= s_nmi3;
			s_nmi5 <= s_nmi4;
			s_sync <= s_reset3 | s_afterWrite | s_ld_pch | s_pul | s_rts3 |
				s_rti3 | s_nmi5 |
				(s_abs1 & jmp) | s_branch |
				(s_update & (grp0 | grp1 | grp2x)) |
				(s_exec & mop);
			s_branch <= s_exec & branch;
			s_rts1 <= s_exec & rts;
			s_rts2 <= s_rts1;
			s_rts3 <= s_rts2;
			s_rti1 <= s_exec & rti;
			s_rti2 <= s_rti1;
			s_rti3 <= s_rti2;
			s_pul <= (s_exec & pul);
			s_jsr1 <= (s_exec & jsr);
			s_jsr2 <= s_jsr1;
			s_jmpi1 <= s_abs1 & jmpi;
			s_ld_pch <= s_jmpi1;
			s_dataFetch <= ~staxy & (
				(s_abs1 & ~(jmp | jmpi)) |
				s_ix2 | s_iy2 | (s_exec & zpxy));
			s_update <= s_dataFetch | (s_exec & imm);
			s_afterWrite <= s_jsr2 |
				(s_update & grp2m) |
				(s_abs1 & staxy) |
				(s_ix2 & staxy) |
				(s_iy2 & staxy) |
				(s_exec & ((zpxy & staxy) | psh));
			s_ix1 <= s_exec & ix;
			s_ix2 <= s_ix1;
			s_iy1 <= s_exec & iy;
			s_iy2 <= s_iy1;
			s_abs1 <= s_exec & absxy;

			// if somehow got to an invalid state reset
			// this is really a processor error or perhaps
			// trying to execute an invalid opcode
/*
			s_reset1 <= s_reset | ~(
				s_reset1 |
				s_reset2 |
				s_reset3 |
				s_nmi1 |
				s_nmi2 |
				s_nmi3 |
				s_nmi4 |
				s_ld_pch |
				s_exec |
				s_dataFetch |
				s_update |
				s_afterWrite |
				s_ix1 |
				s_ix2 |
				s_iy1 |
				s_iy2 |
				s_abs1 |
				s_jmpi1 |
				s_jsr1 |
				s_jsr2 |
				s_pul |
				s_rts3 |
				s_rti1 |
				s_rti2 |
				s_sync); */
			// End of state advancement
		end // if (rdy)
		if (s_reset1) begin
			$display("*****************************************");
			$display("*****************************************");
			$display("**** Came out of reset ****");
			$display("*****************************************");
			$display("*****************************************");
		end
		$display("states");
		$display("\ts_reset=%b s_reset1=%b reset2=%b reset3=%b",s_reset,s_reset1,s_reset2,s_reset3);
		$display("\ts_nmi1=%b s_nmi2=%b s_nmi3=%b s_nmi4=%b",s_nmi1, s_nmi2, s_nmi3, s_nmi4);
		$display("\ts_ld_pch=%b",s_ld_pch);
		$display("\ts_exec=%b",s_exec);
		$display("\ts_branch=%b", s_branch);
		$display("\ts_ms1=%b s_update=%b", s_dataFetch, s_update);
		$display("\ts_post_write=%b",s_afterWrite);
		$display("\ts_ix1=%b s_ix2=%b",s_ix1, s_ix2);
		$display("\ts_iy1=%b s_iy2=%b",s_iy1, s_iy2);
		$display("\ts_abs1=%b",s_abs1);
		$display("\ts_jmpi1=%b",s_jmpi1);
		$display("\ts_jsr1=%b s_jsr2=%b",s_jsr1, s_jsr2);
		$display("\ts_pul=%b",s_pul);
		$display("\ts_rts1=%b s_rts2=%b s_rts3=%b",s_rts1,s_rts2,s_rts3);
		$display("\ts_rti1=%b s_rti2=%b",s_rti1, s_rti2);
		$display("\ts_sync=%b",s_sync);
	end	// always

endmodule

