module rf65000(rst_i, clk_i, cyc_o, stb_o, ack_i, err_i, we_o, sel_o, adr_o, dat_i, dat_o);
input rst_i;
input clk_i;
output reg cyc_o;
output reg stb_o;
input ack_i;
input err_i;
output reg we_o;
output reg [3:0] sel_o;
output reg [31:0] adr_o;
input [31:0] dat_i;
output reg [31:0] dat_o;

typedef enum logic [7:0] {
	RESET1 = 8'd1,RESET2,
	IFETCH,
	DECODE,
	FETCH_IMM32,
	FETCH_IMM64,
	FETCH_OCTA,
	STORE_OCTA,
	ADD,ADD1
	SUB,SUB1,
	SHIFT,SHIFT1,
	BCC,
	DBRA,
	BSR,
	BSR2,
	BSR3,
	RTS,
	DD1,
	DD2
} state_t;
state_t state;
state_t state_stk1;
state_t state_stk2;
state_t state_stk3;
state_t state_stk4;

reg [31:0] pc;
reg [31:0] ea;
reg [31:0] ir;
reg [63:0] regs [0:31];
reg [63:0] sp,usp,ssp;
reg [63:0] lc;
reg [7:0] Cr [0:7];
reg sf,tf,df,fdf;
reg [2:0] ipl;
reg [7:0] cpl;
wire [31:0] sr = {cpl, 8'h00, tf, 1'b0, sf, 2'b00, ipl, 4'b0, df, fdf, 2'b00};
reg [31:0] isr;

typedef enum logic [4:0] {
	FU_NONE = 5'd0,
	FU_ADD,
	FU_SHIFT
} flag_update_t;
flag_update_t flag_update;

reg [2:0] Ct, Ca;
reg [2:0] shift_op;

reg [63:0] a,b,d;
reg [63:0] rfoa, rfob;
reg [ 8:0] resB;
reg [16:0] resW;
reg [32:0] resT;
reg [64:0] resO;

// These functions take the MSBs of the operands and results and return an
// overflow status.

// If the signs of the operands are the same, and the sign of the result does
// not match the operands sign.
function fnAddOverflow;
input r;
input a;
input b;
	fnAddOverflow = (r ^ b) & (1'b1 ^ a ^ b);
endfunction

// If the signs of the operands are different and sign of the result does not
// match the first operand.
function fnSubOverflow;
input r;
input a;
input b;
	fnSubOverflow = (r ^ a) & (a ^ b);
endfunction

always_ff @(posedge clk)
if (rfwrB) begin
	regs[Rt][ 7:0] <= resB[ 7:0];
	if (Rt==5'd31)
		sp[7:0] <= resB[ 7:0];
end
else if (rfwrW) begin
	regs[Rt][15:0] <= resW[15:0];
	if (Rt==5'd31)
		sp[15:0] <= resW[15:0];
end
else if (rfwrT) begin
	regs[Rt][31:0] <= resT[31:0];
	if (Rt==5'd31)
		sp[31:0] <= resT[31:0];
end
else if (rfwrO) begin
	regs[Rt][63:0] <= resO[63:0];
	if (Rt==5'd63)
		sp[63:0] <= resO[63:0];
end

always_comb
	rfoa <= Ra==5'd31 ? sp : regs[Ra];
always_comb
	rfob <= Rb==5'd31 ? sp : regs[Rb];

function [7:0] fnBCDToBinary8
input [7:0] bcd;
	fnBCDToBinary8 = bcd[7:4] * 4'd10 + bcd[3:0];
endfunction

function [15:0] fnBCDToBinary16
input [15:0] bcd;
	fnBCDToBinary16 = bcd[15:12] * 10'd1000 + bcd[11:8] * 7'd100 + bcd[7:4] * 4'd10 + bcd[3:0];
endfunction

wire [9:0] dd8out;
wire [19:0] dd16out;
wire dd8done, dd16done;
DDBinToBCD #(.WID(8)) udd1
(
	.rst(rst_i),
	.clk(clk_i),
	.ld(state==DD1),
	.bin(resB),
	.bcd(dd8out),
	.done(dd8done)
);
DDBinToBCD #(.WID(16)) udd2
(
	.rst(rst_i),
	.clk(clk_i),
	.ld(state==DD1),
	.bin(resW),
	.bcd(dd16out),
	.done(dd16done)
);

always_comb
	case(ir[9:5])
	5'd0:	takb <= 1'b1;
	5'd1: takb <= 1'b0;
	5'd2: takb <= !cf & !zf;	// HI
	5'd3: takb <=  cf | zf;		// LS
	5'd4: takb <= !cf;				// HS / CC
	5'd5:	takb <=  cf;				// LO / CS
	5'd6:	takb <= !zf;				// NE
	5'd7:	takb <=  zf;				// EQ
	5'd8: takb <= !vf;				// VC
	5'd9: takb <=  vf;				// VS
	5'd10: takb <= !nf;				// PL
	5'd11:	takb <= nf;				// MI
	5'd12: 	takb <= (nf & vf) | (!nf & !vf);	// GE
	5'd13:	takb <= (nf & !vf) | (!nf & vf);	// LT
	5'd14:	takb <= (nf & vf & !zf) | (!nf & !vf & zf);	// GT
	5'd15:	takb <= zf | (nf & !vf) | (!nf & vf);	// LE
	5'd16:	takb <= ord;			// FOR
	5'd17:	takb <= !ord;			// FUN
	5'd18:	takb <= !(lt|eq);	// FGT
	5'd19:	takb <= lt|eq;		// FLE
	5'd20:	takb <= !lt;			// FGE
	5'd21:	takb <= lt;				// FLT
	5'd22:	takb <= !eq;			// FNE
	5'd23:	takb <= eq;				// FEQ
	default:	takb <= 1'b1;
	endcase

always_ff @(posedge clk)
if (rst_i) begin
	flag_update <= FU_NONE;
	ea <= 'd0;
	call (FETCH_OCTA,RESET1);
end
else begin
case(state)
IFETCH:
	begin
		rfwrB <= FALSE;
		rfwrW <= FALSE;
		rfwrT <= FALSE;
		rfwrO <= FALSE;
		case(flag_update)
		FU_ADD:
			begin
				case(sz)
				2'b00:	Cr[Ct][0] <= resB[ 8];
				2'b01:	Cr[Ct][0] <= resW[16];
				2'b10:	Cr[Ct][0] <= resT[32];
				2'b11:	Cr[Ct][0] <= resO[64];
				endcase
				case(sz)
				2'b00:	Cr[Ct][1] <= fnAddOverflow(resB[ 7],a[ 7],b[ 7]);
				2'b01:	Cr[Ct][1] <= fnAddOverflow(resW[15],a[15],b[15]);
				2'b10:	Cr[Ct][1] <= fnAddOverflow(resT[31],a[31],b[31]);
				2'b11:	Cr[Ct][1] <= fnAddOverflow(resO[63],a[63],b[63]);
				endcase
				case(sz)
				2'b00:	Cr[Ct][2] <= resB[ 7:0]=='d0;
				2'b01:	Cr[Ct][2] <= resW[15:0]=='d0;
				2'b10:	Cr[Ct][2] <= resT[31:0]=='d0;
				2'b11:	Cr[Ct][2] <= resO[63:0]=='d0;
				endcase
				case(sz)
				2'b00:	Cr[Ct][3] <= resB[ 7];
				2'b01:	Cr[Ct][3] <= resW[15];
				2'b10:	Cr[Ct][3] <= resT[31];
				2'b11:	Cr[Ct][3] <= resO[63];
				endcase
			end
		FU_SHIFT:
			begin
				Cr[Ct][0] <= cf;
				Cr[Ct][1] <= vf;
				Cr[Ct][2] <= zf;
				Cr[Ct][3] <= nf;
			end
		endcase
		flag_update <= FU_NONE;
		if (!cyc_o) begin
			cyc_o <= HIGH;
			stb_o <= HIGH;
			sel_o <= 4'b1111;
			adr_o <= pc;
		end
		else if (ack_i) begin
			cyc_o <= LOW;
			stb_o <= LOW;
			ir <= dat_i;
			opcode <= dat_i[4:0];
			sz <= dat_i[6:5];
			Rt <= dat_i[11:7];
			Ca <= dat_i[12:10];
			Ra <= dat_i[16:12];
			Rb <= dat_i[22:18];
			Ct <= dat_i[31:29];
			goto (DECODE);
		end
	end
DECODE:
	begin
		pc <= pc + 4'd4;
		cf <= Cr[Ct][0];
		vf <= Cr[Ct][1];
		zf <= Cr[Ct][2];
		nf <= Cr[Ct][3];
		case(ir[4:0])
		5'd4:	// ADD
			begin
				a <= rfoa;
				if (ir[17]) begin
					if (ir[28:24]==5'd16)
						call(FETCH_IMM32,df ? ADD1 : ADD);
					else if (ir[28:24]==5'd17)
						call(FETCH_IMM64,df ? ADD1 : ADD);
					else begin
						b <= {{54{ir[28]}},ir[28:24],ir[22:18]};
						goto (df ? ADD1 : ADD);
					end
				end
				else begin
					b <= rfob;
					goto (df ? ADD1 : ADD);
				end
			end
		5'd5:		// SUB
			begin
				a <= rfoa;
				if (ir[17]) begin
					if (ir[28:24]==5'd16)
						call(FETCH_IMM32,df?SUB1:SUB);
					else if (ir[28:24]==5'd17)
						call(FETCH_IMM64,df?SUB1:SUB);
					else begin
						b <= {{54{ir[28]}},ir[28:24],ir[22:18]};
						goto (df?SUB1:SUB);
					end
				end
				else begin
					b <= rfob;
					goto (df?SUB1:SUB);
				end
			end
		5'd14:	// SHIFT
			begin
				b <= ir[17] ? {ir[24],ir[22:18]} : rfob[5:0];
				resB <= {1'b0,rfoa[ 7:0]};
				resW <= {1'b0,rfoa[15:0]};
				resT <= {1'b0,rfoa[31:0]};
				resO <= {1'b0,rfoa[63:0]};
				shift_op <= {ir[23],ir[28:27]};
				if (df)
					goto (SHIFT1);
				else
					goto (SHIFT);
			end
		5'd15:
			begin
				case(ir[28:24])
				5'd0:	begin ea <= sp; call (FETCH_OCTA,RTS); end
				5'd1: begin ea <= sp; call (FETCH_TETRA,RTI); end
				default:	tUnimplemented();
				endcase
			end
		5'd28:	// Bcc
			begin
				cf <= Cr[Ca][0];
				vf <= Cr[Ca][1];
				zf <= Cr[Ca][2];
				nf <= Cr[Ca][3];
				eq <= Cr[Ca][4];
				lt <= Cr[Ca][5];
				ord <= Cr[Ca][6];
				if (ir[9:5]==5'd0) begin
					pc <= pc + {{40{ir[12]}},ir[12:10],ir[31:13],2'b00};
					goto (IFETCH);
				end
				else if (ir[9:5]==5'd1) begin
					ea <= sp - 4'd8;
					d <= pc + 4'd4;		// d = pointer to next instruction
					call (STORE_OCTA,BSR);
				end
				else
					goto (BCC);
			end
		5'd29:	// DBcc
			begin
				cf <= Cr[Ca][0];
				vf <= Cr[Ca][1];
				zf <= Cr[Ca][2];
				nf <= Cr[Ca][3];
				eq <= Cr[Ca][4];
				lt <= Cr[Ca][5];
				ord <= Cr[Ca][6];
				goto (DBRA);
			end
		endcase
	end

//------------------------------------------------------------------------------
// RESET
// - reset sequence is to load the SSP from the vector table then the PC
// - program execution begins at the PC location.
// - system mode is set, trace is disabled, interrupt level 7 is set,
//   privilege level 255 is set. decimal mode is cleared.
// - all other registers are in an undefined state.
//------------------------------------------------------------------------------

RESET1:
	begin
		ssp <= b;
		sp <= b;
		sf <= TRUE;
		tf <= FALSE;
		df <= FALSE;
		fdf <= FALSE;
		ipl <= 3'd7;
		cpl <= 8'hFF;
		ea <= 4'd8;
		call (FETCH_OCTA,RESET2);
	end
RESET2:
	begin
		pc <= b;
		goto (IFETCH);
	end

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

FETCH_IMM32:
	if (!cyc_o) begin
		cyc_o <= HIGH;
		stb_o <= HIGH;
		sel_o <= 4'b1111;
		adr_o <= pc;
	end
	else if (ack_i) begin
		cyc_o <= LOW;
		stb_o <= LOW;
		sel_o <= 4'h0;
		b <= {{64{dat_i[31]}},dat_i};
		goto (FETCH_IMM32a);
	end
FETCH_IMM32a:
	begin
		pc <= pc + 4'd4;
		ret();
	end

FETCH_IMM64:
	if (!cyc_o) begin
		cyc_o <= HIGH;
		stb_o <= HIGH;
		sel_o <= 4'b1111;
		adr_o <= pc;
	end
	else if (ack_i) begin
		cyc_o <= LOW;
		stb_o <= LOW;
		sel_o <= 4'h0;
		b[31:0] <= dat_i;
		goto (FETCH_IMM64a);
	end
FETCH_IMM64:
	if (!cyc_o) begin
		cyc_o <= HIGH;
		stb_o <= HIGH;
		sel_o <= 4'b1111;
		adr_o <= pc + 4'd4;
	end
	else if (ack_i) begin
		cyc_o <= LOW;
		stb_o <= LOW;
		sel_o <= 4'h0;
		b[63:32] <= dat_i;
		goto (FETCH_IMM64b);
	end
FETCH_IMM64b:
	begin
		pc <= pc + 4'd8;
		ret();
	end

FETCH_BYTE:
	if (!cyc_o) begin
		cyc_o <= HIGH;
		stb_o <= HIGH;
		sel_o <= 4'b1111;
		adr_o <= ea;
	end
	else if (ack_i) begin
		cyc_o <= LOW;
		stb_o <= LOW;
		sel_o <= 4'h0;
		b[7:0] <= dat_i >> {ea[1:0],3'b0};
		ret();
	end

FETCH_WYDE:
	case(ea[1:0])
	2'b00:
		if (!cyc_o) begin
			cyc_o <= HIGH;
			stb_o <= HIGH;
			sel_o <= 4'b1111;
			adr_o <= ea;
		end
		else if (ack_i) begin
			cyc_o <= LOW;
			stb_o <= LOW;
			sel_o <= 4'h0;
			b[15:0] <= dat_i[15:0];
			ret();
		end
	2'b01:
		if (!cyc_o) begin
			cyc_o <= HIGH;
			stb_o <= HIGH;
			sel_o <= 4'b1111;
			adr_o <= ea;
		end
		else if (ack_i) begin
			cyc_o <= LOW;
			stb_o <= LOW;
			sel_o <= 4'h0;
			b[15:0] <= dat_i[23:8];
			ret();
		end
	2'b10:
		if (!cyc_o) begin
			cyc_o <= HIGH;
			stb_o <= HIGH;
			sel_o <= 4'b1111;
			adr_o <= ea;
		end
		else if (ack_i) begin
			cyc_o <= LOW;
			stb_o <= LOW;
			sel_o <= 4'h0;
			b[15:0] <= dat_i[31:16];
			ret();
		end
	2'b11:
		if (!cyc_o) begin
			cyc_o <= HIGH;
			stb_o <= HIGH;
			sel_o <= 4'b1111;
			adr_o <= ea;
		end
		else if (ack_i) begin
			stb_o <= LOW;
			b[7:0] <= dat_i[31:24];
			goto(FETCH_WYDE2);
		end
	endcase
FETCH_WYDE2:
	if (!stb_o) begin
		stb_o <= HIGH;
		sel_o <= 4'b1111;
		adr_o <= ea + 2'd1;
	end
	else if (ack_i) begin
		cyc_o <= LOW;
		stb_o <= LOW;
		sel_o <= 4'h0;		
		b[15:8] <= dat_i[7:0];
		ret();
	end

FETCH_TETRA:
	case(ea[1:0])
	2'b00:
		if (!cyc_o) begin
			cyc_o <= HIGH;
			stb_o <= HIGH;
			sel_o <= 4'b1111;
			adr_o <= ea;
		end
		else if (ack_i) begin
			stb_o <= LOW;
			we_o <= LOW;
			b[31:0] <= dat_i;
			b[63:32] <= {32{dat_i[31]}};
			ret();
		end
	2'b01:
		if (!cyc_o) begin
			cyc_o <= HIGH;
			stb_o <= HIGH;
			sel_o <= 4'b1111;
			adr_o <= ea;
		end
		else if (ack_i) begin
			stb_o <= LOW;
			b[23:0] <= dat_i[31:8];
			goto (FETCH_TETRA2);
		end
	2'b10:
		if (!cyc_o) begin
			cyc_o <= HIGH;
			stb_o <= HIGH;
			sel_o <= 4'b1111;
			adr_o <= ea;
		end
		else if (ack_i) begin
			stb_o <= LOW;
			b[15:0] <= dat_i[31:16];
			goto (FETCH_TETRA2);
		end
	2'b11:
		if (!cyc_o) begin
			cyc_o <= HIGH;
			stb_o <= HIGH;
			sel_o <= 4'b1111;
			adr_o <= ea;
		end
		else if (ack_i) begin
			stb_o <= LOW;
			b[7:0] <= dat_i[31:24];
			goto (FETCH_TETRA2);
		end
	endcase
FETCH_TETRA2:
	case(ea[1:0])
	2'b00:	ret();
	2'b01:
		if (!stb_o) begin
			stb_o <= HIGH;
			sel_o <= 4'b1111;
			adr_o <= ea + 4'd3;
		end
		else if (ack_i) begin
			cyc_o <= LOW;
			stb_o <= LOW;
			sel_o <= 4'h0;
			b[31:24] <= dat_i[7:0];
			b[63:32] <= {32{dat_i[7]}};
			ret();
		end
	2'b10:
		if (!stb_o) begin
			stb_o <= HIGH;
			sel_o <= 4'b1111;
			adr_o <= ea + 4'd2;
		end
		else if (ack_i) begin
			cyc_o <= LOW;
			stb_o <= LOW;
			sel_o <= 4'h0;
			b[31:16] <= dat_i[15:0];
			b[63:32] <= {32{dat_i[15]}};
			ret();
		end
	2'b11:
		if (!stb_o) begin
			stb_o <= HIGH;
			sel_o <= 4'b1111;
			adr_o <= ea + 4'd1;
		end
		else if (ack_i) begin
			cyc_o <= LOW;
			stb_o <= LOW;
			sel_o <= 4'h0;
			b[31:8] <= dat_i[23:0];
			b[63:32] <= {32{dat_i[23]}};
			ret();
		end
	endcase

FETCH_OCTA:
	case(ea[1:0])
	2'b00:
		if (!cyc_o) begin
			cyc_o <= HIGH;
			stb_o <= HIGH;
			sel_o <= 4'b1111;
			adr_o <= ea;
		end
		else if (ack_i) begin
			stb_o <= LOW;
			b[31:0] <= dat_i;
			goto (FETCH_OCTA2);
		end
	2'b01:
		if (!cyc_o) begin
			cyc_o <= HIGH;
			stb_o <= HIGH;
			sel_o <= 4'b1111;
			adr_o <= ea;
		end
		else if (ack_i) begin
			stb_o <= LOW;
			b[23:0] <= dat_i >> 4'd8;
			goto (FETCH_OCTA2);
		end
	2'b10:
		if (!cyc_o) begin
			cyc_o <= HIGH;
			stb_o <= HIGH;
			sel_o <= 4'b1111;
			adr_o <= ea;
		end
		else if (ack_i) begin
			stb_o <= LOW;
			b[15:0] <= dat_i >> 5'd16;
			goto (FETCH_OCTA2);
		end
	2'b11:
		if (!cyc_o) begin
			cyc_o <= HIGH;
			stb_o <= HIGH;
			sel_o <= 4'b1111;
			adr_o <= ea;
		end
		else if (ack_i) begin
			stb_o <= LOW;
			b[7:0] <= dat_i >> 6'd24;
			goto (FETCH_OCTA2);
		end
	endcase
FETCH_OCTA2:
	case(ea[1:0])
	2'b00:
		if (!stb_o) begin
			stb_o <= HIGH;
			sel_o <= 4'b1111;
			adr_o <= ea + 4'd4;
		end
		else if (ack_i) begin
			cyc_o <= LOW;
			stb_o <= LOW;
			sel_o <= 4'h0;
			b[63:32] <= dat_i;
			ret();
		end
	2'b01:
		if (!stb_o) begin
			stb_o <= HIGH;
			sel_o <= 4'b1111;
			adr_o <= ea + 4'd3;
		end
		else if (ack_i) begin
			stb_o <= LOW;
			b[55:24] <= dat_i;
			goto (FETCH_OCTA3);
		end
	2'b10:
		if (!stb_o) begin
			stb_o <= HIGH;
			sel_o <= 4'b1111;
			adr_o <= ea + 4'd2;
		end
		else if (ack_i) begin
			stb_o <= LOW;
			b[47:16] <= dat_i;
			goto (FETCH_OCTA3);
		end
	2'b11:
		if (!stb_o) begin
			stb_o <= HIGH;
			sel_o <= 4'b1111;
			adr_o <= ea + 4'd1;
		end
		else if (ack_i) begin
			stb_o <= LOW;
			b[39:8] <= dat_i;
			goto (FETCH_OCTA3);
		end
	endcase
FETCH_OCTA3:
	case(ea[1:0])
	2'b00:	ret();
	2'b01:
		if (!stb_o) begin
			stb_o <= HIGH;
			sel_o <= 4'b1111;
			adr_o <= ea + 4'd4;
		end
		else if (ack_i) begin
			cyc_o <= LOW;
			stb_o <= LOW;
			sel_o <= 4'h0;
			b[63:56] <= dat_i[7:0];
			ret();
		end
	2'b10:
		if (!stb_o) begin
			stb_o <= HIGH;
			sel_o <= 4'b1111;
			adr_o <= ea + 4'd4;
		end
		else if (ack_i) begin
			cyc_o <= LOW;
			stb_o <= LOW;
			sel_o <= 4'h0;
			b[63:48] <= dat_i[15:0];
			ret();
		end
	2'b11:
		if (!stb_o) begin
			stb_o <= HIGH;
			sel_o <= 4'b1111;
			adr_o <= ea + 4'd4;
		end
		else if (ack_i) begin
			cyc_o <= LOW;
			stb_o <= LOW;
			sel_o <= 4'h0;
			b[63:40] <= dat_i[23:0];
			ret();
		end
	endcase

STORE_BYTE:
	if (!cyc_o) begin
		cyc_o <= HIGH;
		stb_o <= HIGH;
		we_o <= HIGH;
		sel_o <= 4'd1 << ea[1:0];
		adr_o <= ea;
		dat_o <= {4{d[7:0]}};
	end
	else if (ack_i) begin
		cyc_o <= LOW;
		stb_o <= LOW;
		we_o <= LOW;
		ret();
	end

STORE_WYDE:
	if (!cyc_o) begin
		cyc_o <= HIGH;
		stb_o <= HIGH;
		we_o <= HIGH;
		sel_o <= 4'd3 << ea[1:0];
		adr_o <= ea;
		dat_o <= d[15:0] << {ea[1:0],3'b0};
	end
	else if (ack_i) begin
		stb_o <= LOW;
		we_o <= LOW;
		if (ea[1:0]==2'b11)
			goto (STORE_WYDE2);
		else begin
			cyc_o <= LOW;
			sel_o <= 4'h0;
			ret();
		end
	end
STORE_WYDE2:
	if (!stb_o) begin
		stb_o <= HIGH;
		we_o <= HIGH;
		sel_o <= 4'd1;
		adr_o <= ea + 2'd1;
		dat_o <= d[15:8];
	end
	else if (ack_i) begin
		cyc_o <= LOW;
		stb_o <= LOW;
		we_o <= LOW;
		sel_o <= 4'd0;
		ret();
	end	
	
STORE_TETRA:
	if (!cyc_o) begin
		cyc_o <= HIGH;
		stb_o <= HIGH;
		we_o <= HIGH;
		sel_o <= 4'd15 << ea[1:0];
		adr_o <= ea;
		dat_o <= d[31:0] << {ea[1:0],3'b0};
	end
	else if (ack_i) begin
		stb_o <= LOW;
		we_o <= LOW;
		if (ea[1:0]!=2'b00)
			goto (STORE_TETRA2);
		else begin
			cyc_o <= LOW;
			sel_o <= 4'h0;
			ret();
		end
	end
STORE_TETRA2:
	if (!stb_o) begin
		stb_o <= HIGH;
		we_o <= HIGH;
		sel_o <= ~(4'd15 << ea[1:0]);
		case(ea[1:0])
		2'b00:	;
		2'b01:
			begin
				adr_o <= ea + 4'd3;
				dat_o <= d[31:24];
			end
		2'b10:
			begin
				adr_o <= ea + 4'd2;
				dat_o <= d[31:16];
			end
		2'b11:
			begin
				adr_o <= ea + 4'd1;
				dat_o <= d[31:8];
			end
		endcase
	end
	else if (ack_i) begin
		cyc_o <= LOW;
		stb_o <= LOW;
		we_o <= LOW;
		sel_o <= 4'd0;
		ret();
	end	

STORE_OCTA:
	if (!cyc_o) begin
		cyc_o <= HIGH;
		stb_o <= HIGH;
		we_o <= HIGH;
		sel_o <= 4'd15 << ea[1:0];
		adr_o <= ea;
		dat_o <= d[31:0] << {ea[1:0],3'b0};
	end
	else if (ack_i) begin
		stb_o <= LOW;
		we_o <= LOW;
		goto (STORE_OCTA2);
	end
STORE_OCTA2:
	if (!stb_o) begin
		stb_o <= HIGH;
		we_o <= HIGH;
		sel_o <= 4'b1111;
		case(ea[1:0])
		2'b00:	
			begin
				adr_o <= ea + 4'd4;
				dat_o <= d[63:32];
			end
		2'b01:
			begin
				adr_o <= ea + 4'd3;
				dat_o <= d[55:24];
			end
		2'b10:
			begin
				adr_o <= ea + 4'd2;
				dat_o <= d[47:16];
			end
		2'b11:
			begin
				adr_o <= ea + 4'd1;
				dat_o <= d[39:8];
			end
		endcase
	end
	else if (ack_i) begin
		case(ea[1:0])
		2'b00:
			begin
				cyc_o <= LOW;
				stb_o <= LOW;
				we_o <= LOW;
				sel_o <= 4'd0;
				ret();
			end
		default:
			begin
				stb_o <= LOW;
				we_o <= LOW;
				goto(STORE_OCTA3);
			end
		endcase
	end	
STORE_OCTA3:
	if (!stb_o) begin
		stb_o <= HIGH;
		we_o <= HIGH;
		case(ea[1:0])
		2'b00:	;
		2'b01:	
			begin
				sel_o <= 4'b0001;
				adr_o <= ea + 4'd7;
				dat_o <= d[63:56];
			end
		2'b10:
			begin
				sel_o <= 4'b0011;
				adr_o <= ea + 4'd6;
				dat_o <= d[63:48];
			end
		2'b11:
			begin
				sel_o <= 4'b0111;
				adr_o <= ea + 4'd5;
				dat_o <= d[63:40];
			end
		endcase
	end
	else if (ack_i) begin
		cyc_o <= LOW;
		stb_o <= LOW;
		we_o <= LOW;
		sel_o <= 4'd0;
		ret();
	end

//------------------------------------------------------------------------------
// ADD / ADC
//------------------------------------------------------------------------------
ADD1:
	begin
		b <= fnBCDToBinary8(b);
		resB <= fnBCDToBinary8(resB);
		resW <= fnBCDToBinary16(resW);
		goto (ADD);
	end
ADD:
	begin
		flag_update <= FU_ADD;
		case(sz)
		2'b00:	resB <= a[ 7:0] + b[ 7:0] + (ir[23] & cf);
		2'b01:	resW <= a[15:0] + b[15:0] + (ir[23] & cf);
		2'b10:	resT <= a[31:0] + b[31:0] + (ir[23] & cf);
		2'b11:	resO <= a[63:0] + b[63:0] + (ir[23] & cf);
		endcase
		if (df)
			goto (DD1);
		else
			goto (IFETCH);
	end

//------------------------------------------------------------------------------
// SUB
//------------------------------------------------------------------------------
SUB1:
	begin
		b <= fnBCDToBinary8(b);
		resB <= fnBCDToBinary8(resB);
		resW <= fnBCDToBinary16(resW);
		goto (SUB);
	end
SUB:
	begin
		flag_update <= FU_SUB;
		case(sz)
		2'b00:	resB <= ir[23] ? b[ 7:0] - a[ 7:0] : a[ 7:0] + b[ 7:0];
		2'b01:	resW <= ir[23] ? b[15:0] - a[15:0] : a[15:0] + b[15:0];
		2'b10:	resT <= ir[23] ? b[31:0] - a[31:0] : a[31:0] + b[31:0];
		2'b11:	resO <= ir[23] ? b[63:0] - a[63:0] : a[63:0] + b[63:0];
		endcase
		if (df)
			goto (DD1);
		else
			goto (IFETCH);
	end

//------------------------------------------------------------------------------
// ASL / LSL / ROL / ASR / LSR / ROR
//------------------------------------------------------------------------------
SHIFT1:
	begin
		b <= fnBCDToBinary8(b);
		resB <= fnBCDToBinary8(resB);
		resW <= fnBCDToBinary16(resW);
		goto (SHIFT);
	end
SHIFT:
	begin
		if (|b) begin
			b <= b - 2'd1;
			case(shift_op)
			3'b000:	// ASL
				case(sz)
				2'b00:	begin resB <= {resB[ 7:0],1'b0}; cf <= resB[ 7]; if (resB[ 7] != resB[ 8]) vf <= 1'b1; end
				2'b01:	begin resW <= {resW[15:0],1'b0}; cf <= resW[15]; if (resW[15] != resW[16]) vf <= 1'b1; end
				2'b10:	begin resT <= {resT[31:0],1'b0}; cf <= resT[31]; if (resT[31] != resT[31]) vf <= 1'b1; end
				2'b11:	begin resO <= {resO[63:0],1'b0}; cf <= resO[63]; if (resO[63] != resO[63]) vf <= 1'b1; end
				endcase
			3'b001:	// LSL
				case(sz)
				2'b00:	begin resB <= {resB[ 7:0],1'b0}; cf <= resB[ 7]; vf <= 1'b0; end
				2'b01:	begin resW <= {resW[15:0],1'b0}; cf <= resW[15]; vf <= 1'b0; end
				2'b10:	begin resT <= {resT[31:0],1'b0}; cf <= resT[31]; vf <= 1'b0; end
				2'b11:	begin resO <= {resO[63:0],1'b0}; cf <= resO[63]; vf <= 1'b0; end
				endcase
			3'b010:	// ROL
				case(sz)
				2'b00:	begin resB <= {resB[ 7:0],cf}; cf <= resB[ 7]; vf <= 1'b0; end
				2'b01:	begin resW <= {resW[15:0],cf}; cf <= resW[15]; vf <= 1'b0; end
				2'b10:	begin resT <= {resT[31:0],cf}; cf <= resT[31]; vf <= 1'b0; end
				2'b11:	begin resO <= {resO[63:0],cf}; cf <= resO[63]; vf <= 1'b0; end
				endcase
			endcase
		end
		else begin
			flag_update <= FU_SHIFT;
			case(sz)
			2'b00:	nf <= resB[ 7];
			2'b01:	nf <= resW[15];
			2'b10:	nf <= resT[31];
			2'b11:	nf <= resO[63];
			endcase
			case(sz)
			2'b00:	zf <= resB[ 7:0]=='d0;
			2'b01:	zf <= resW[15:0]=='d0;
			2'b10:	zf <= resT[31:0]=='d0;
			2'b11:	zf <= resO[63:0]=='d0;
			endcase
			case(sz)
			2'b00:	rfwrB <= TRUE;
			2'b01:	rfwrW <= TRUE;
			2'b10:	rfwrT <= TRUE;
			2'b11:	rfwrO <= TRUE;
			endcase
			if (df)
				goto (DD1);
			else
				goto (IFETCH);
		end
	end

//------------------------------------------------------------------------------
// Convert binary result to BCD.
//------------------------------------------------------------------------------

DD1:	goto(DD2);
DD2:
	case(sz)
	2'b00:
		if (dd8done) begin
			resB <= dd8out[7:0];
			rfwrB <= TRUE;
			cf <= |dd8out[9:8];
			resB[8] <= |dd8out[9:8];
			goto (IFETCH);
		end
	2'b01:
		if (dd16done) begin
			resW <= dd16out[15:0];
			rfwrW <= TRUE;
			cf <= |dd16out[19:16];
			resW[16] <= |dd8out[19:16];
			goto (IFETCH);
		end
	default:	goto (IFETCH);
	endcase

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

BCC:
	begin
		if (takb)
			pc <= pc + {{43{ir[31]}},ir[31:13],2'b00};
		goto (IFETCH);
	end

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

DBRA:
	begin
		if (!takb) begin
			lc <= lc - 2'd1;
			if (lc != 'd0)
				pc <= pc + {{43{ir[31]}},ir[31:13],2'b00};
		end
		goto (IFETCH);
	end

//------------------------------------------------------------------------------
// BSR
// - after pushing the return address decrement the SP and add the branch
//   displacement to the PC.
//------------------------------------------------------------------------------

BSR:
	begin
		pc <= pc + {{40{ir[12]}},ir[12:10],ir[31:13],2'b00};
		sp <= sp - 4'd8;
		goto (IFETCH);
	end

//------------------------------------------------------------------------------
// RTS
// - after popping the return address add the amount of inline arguments to 
//   skip over to the PC and the amount of stacked arguments to pop to the SP.
//------------------------------------------------------------------------------

RTS:
	begin
		pc <= b + {ir[11:7],2'd0};
		sp <= sp + 4'd8 + {ir[22:18],ir[16:12],2'd0};
		goto (IFETCH);
	end

//------------------------------------------------------------------------------
// RTI
// - after popping the return address add the amount of inline arguments to 
//   skip over to the PC and the amount of stacked arguments to pop to the SP.
//------------------------------------------------------------------------------

RTI:
	begin
		isr <= b[31:0];
		ea <= sp + 4'd4;
		call (FETCH_OCTA,RTI2);
	end
RTI2:
	begin
		fdf <= isr[2];
		df <= isr[3];
		ipl <= isr[10:8];
		sf <= isr[13];
		tf <= isr[15];
		cpl <= isr[31:24];
		pc <= b;
		pc <= b + {ir[11:7],2'd0};
		sp <= sp + 4'd12 + {ir[22:18],ir[16:12],2'd0};
		goto (IFETCH);
	end

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

TRAP:
	begin
		isr <= sr;
		sf <= 1'b1;		// switch to system mode
		if (!sf) begin
			usp <= sp;
			sp <= ssp;
		end
	end
	
endcase
end

task tUnimplemented;
begin
	vecno <= 8'd4;
	goto (TRAP);
end
endtask

task goto;
input state_t nst;
begin
	state <= nst;
end
endtask

task gosub;
input state_t tgt;
begin
	state_stk1 <= state;
	state_stk2 <= state_stk1;
	state_stk3 <= state_stk2;
	state_stk4 <= state_stk3;
	state <= tgt;
end
endtask

task call;
input state_t tgt;
input state_t retst;
begin
	state_stk1 <= retst;
	state_stk2 <= state_stk1;
	state_stk3 <= state_stk2;
	state_stk4 <= state_stk3;
	state <= tgt;
end
endtask

task push;
input state_t st;
begin
	state_stk1 <= st;
	state_stk2 <= state_stk1;
	state_stk3 <= state_stk2;
	state_stk4 <= state_stk3;
end
endtask

endmodule
