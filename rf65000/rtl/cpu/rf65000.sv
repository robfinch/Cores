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
	IFETCH = 8'd1,
	DECODE,
	FETCH_IMM32,
	FETCH_IMM64,
	ADD,
	SUB,
	SHIFT,
	BCC,
	DBRA,
	BSR,
	BSR2,
	BSR3
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
reg [63:0] sp;
reg [63:0] lc;
reg [7:0] Cr [0:7];

typedef enum logic [4:0] {
	FU_NONE = 5'd0,
	FU_ADD = 5'd1
} flag_update_t;
flag_update_t flag_update;

reg [2:0] Ct, Ca;
reg [2:0] shift_op;

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
	rfoa <= regs[Ra];
always_comb
	rfob <= regs[Rb];

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
	pc <= 32'h1000;
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
						call(FETCH_IMM32,ADD);
					else if (ir[28:24]==5'd17)
						call(FETCH_IMM64,ADD);
					else begin
						b <= {{54{ir[28]}},ir[28:24],ir[22:18]};
						goto (ADD);
					end
				end
				else begin
					b <= rfob;
					goto (ADD);
				end
			end
		5'd5:		// SUB
			begin
				a <= rfoa;
				if (ir[17]) begin
					if (ir[28:24]==5'd16)
						call(FETCH_IMM32,SUB);
					else if (ir[28:24]==5'd17)
						call(FETCH_IMM64,SUB);
					else begin
						b <= {{54{ir[28]}},ir[28:24],ir[22:18]};
						goto (SUB);
					end
				end
				else begin
					b <= rfob;
					goto (SUB);
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
				goto (SHIFT);
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
				if (ir[9:5]==5'd1)
					goto (BSR);
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

//------------------------------------------------------------------------------
// ADD / ADC
//------------------------------------------------------------------------------
ADD:
	begin
		flag_update <= FU_ADD;
		case(sz)
		2'b00:	resB <= a[ 7:0] + b[ 7:0] + (ir[23] & cf);
		2'b01:	resW <= a[15:0] + b[15:0] + (ir[23] & cf);
		2'b10:	resT <= a[31:0] + b[31:0] + (ir[23] & cf);
		2'b11:	resO <= a[63:0] + b[63:0] + (ir[23] & cf);
		endcase
		goto (IFETCH);
	end

//------------------------------------------------------------------------------
// SUB
//------------------------------------------------------------------------------
SUB:
	begin
		flag_update <= FU_SUB;
		case(sz)
		2'b00:	resB <= ir[23] ? b[ 7:0] - a[ 7:0] : a[ 7:0] + b[ 7:0];
		2'b01:	resW <= ir[23] ? b[15:0] - a[15:0] : a[15:0] + b[15:0];
		2'b10:	resT <= ir[23] ? b[31:0] - a[31:0] : a[31:0] + b[31:0];
		2'b11:	resO <= ir[23] ? b[63:0] - a[63:0] : a[63:0] + b[63:0];
		endcase
		goto (IFETCH);
	end

//------------------------------------------------------------------------------
// ASL / LSL / ROL / ASR / LSR / ROR
//------------------------------------------------------------------------------
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
			flag_update <= TRUE;
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
			goto (IFETCH);
		end
	end

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
//------------------------------------------------------------------------------

BSR:
	if (!cyc_o) begin
		cyc_o <= HIGH;
		stb_o <= HIGH;
		we_o <= HIGH;
		sel_o <= 4'b1111;
		adr_o <= sp - 4'd4;
		dat_o <= pc[31:0];
	end
	else if (ack_i) begin
		stb_o <= LOW;
		we_o <= LOW;
		goto (BSR2);
	end
BSR2:
	if (!stb_o) begin
		stb_o <= HIGH;
		we_o <= HIGH;
		sel_o <= 4'b1111;
		adr_o <= sp - 4'd8;
		dat_o <= pc[63:32];
	end
	else if (ack_i) begin
		cyc_o <= LOW;
		stb_o <= LOW;
		we_o <= LOW;
		sel_o <= 'd0;
		goto (BSR3);
	end
BSR3:
	begin
		pc <= pc + {{43{ir[31]}},ir[31:13],2'b00};
		sp <= sp - 4'd8;
		goto (IFETCH);
	end


endcase
end

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
