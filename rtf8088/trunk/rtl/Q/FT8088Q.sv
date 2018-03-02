
module FT8088Q(rst_i, clk_i,)
parameter QENTRIES = 8;
parameter NTHREAD = 31;
input rst_i;
input clk_i;

parameter IFETCH=8'd1;
parameter DECODE = 8'd7;
parameter DECODER2 = 8'd8;
parameter DECODER3 = 8'd9;

parameter FETCH_VECTOR = 8'd10;
parameter FETCH_IMM8 = 8'd11;
parameter FETCH_IMM8_ACK = 8'd12;
parameter FETCH_IMM16 = 8'd13;
parameter FETCH_IMM16_ACK = 8'd14;
parameter FETCH_IMM16a = 8'd15;
parameter FETCH_IMM16a_ACK = 8'd16;

parameter MOV_I2BYTREG = 8'd17;

parameter FETCH_DISP8 = 8'd18;
parameter FETCH_DISP16 = 8'd19;
parameter FETCH_DISP16_ACK = 8'd20;
parameter FETCH_DISP16a = 8'd21;
parameter FETCH_DISP16a_ACK = 8'd22;
parameter FETCH_DISP16b = 8'd23;

parameter FETCH_OFFSET = 8'd24;
parameter FETCH_OFFSET1 = 8'd25;
parameter FETCH_OFFSET2 = 8'd26;
parameter FETCH_OFFSET3 = 8'd27;
parameter FETCH_SEGMENT = 8'd28;
parameter FETCH_SEGMENT1 = 8'd29;
parameter FETCH_SEGMENT2 = 8'd30;
parameter FETCH_SEGMENT3 = 8'd31;
parameter FETCH_STK_ADJ1 = 8'd32;
parameter FETCH_STK_ADJ1_ACK = 8'd33;
parameter FETCH_STK_ADJ2 = 8'd34;
parameter FETCH_STK_ADJ2_ACK = 8'd35;
parameter FETCH_DATA = 8'd36;
parameter FETCH_DATA1 = 8'd37;

parameter BRANCH1 = 8'd40;
parameter BRANCH2 = 8'd41;
parameter BRANCH3 = 8'd42;

parameter PUSHA = 8'd43;
parameter PUSHA1= 8'd44;
parameter POPA = 8'd45;
parameter POPA1 = 8'd46;
parameter RET = 8'd47;
parameter RETF = 8'd48;
parameter RETF1 = 8'd49;
parameter JMPF = 8'd50;

parameter CALLF = 8'd51;
parameter CALLF1 = 8'd52;
parameter CALLF2 = 8'd53;
parameter CALLF3 = 8'd54;
parameter CALLF4 = 8'd55;
parameter CALLF5 = 8'd56;
parameter CALLF6 = 8'd57;
parameter CALLF7 = 8'd58;

parameter CALL = 8'd59;
parameter CALL1 = 8'd60;
parameter CALL2 = 8'd61;
parameter CALL3 = 8'd62;

parameter PUSH = 8'd63;
parameter PUSH1 = 8'd64;
parameter PUSH2 = 8'd65;
parameter PUSH3 = 8'd66;

parameter IRET = 8'd70;
parameter IRET1 = 8'd71;
parameter IRET2 = 8'd72;

parameter POP = 8'd73;
parameter POP1 = 8'd74;
parameter POP2 = 8'd75;
parameter POP3 = 8'd76;

parameter CALL_IN = 8'd77;
parameter CALL_IN1 = 8'd78;
parameter CALL_IN2 = 8'd79;
parameter CALL_IN3 = 8'd80;
parameter CALL_IN4 = 8'd81;

parameter STOS = 8'd83;
parameter STOS1 = 8'd84;
parameter STOS2 = 8'd85;
parameter MOVS = 8'd86;
parameter MOVS1 = 8'd87;
parameter MOVS2 = 8'd88;
parameter MOVS3 = 8'd89;
parameter MOVS4 = 8'd90;
parameter MOVS5 = 8'd91;

parameter WRITE_REG = 8'd92;

parameter EACALC = 8'd93;
parameter EACALC1 = 8'd94;
parameter EACALC_DISP8 = 8'd95;
parameter EACALC_DISP8_ACK = 8'd96;
parameter EACALC_DISP16 =  8'd97;
parameter EACALC_DISP16_ACK =  8'd98;
parameter EACALC_DISP16a =  8'd99;
parameter EACALC_DISP16a_ACK =  8'd100;
parameter EXECUTE = 8'd101;

parameter INB = 8'd102;
parameter INB1 = 8'd103;
parameter INB2 = 8'd104;
parameter INB3 = 8'd105;
parameter INW = 8'd106;
parameter INW1 = 8'd107;
parameter INW2 = 8'd108;
parameter INW3 = 8'd109;
parameter INW4 = 8'd110;
parameter INW5 = 8'd111;

parameter OUTB = 8'd112;
parameter OUTB_NACK = 8'd113;
parameter OUTB1 = 8'd114;
parameter OUTB1_NACK = 8'd115;
parameter OUTW = 8'd116;
parameter OUTW_NACK = 8'd117;
parameter OUTW1 = 8'd118;
parameter OUTW1_NACK = 8'd119;
parameter OUTW2 = 8'd120;
parameter OUTW2_NACK = 8'd121;
parameter FETCH_PORTNUMBER = 8'd122;

parameter INVALID_OPCODE = 8'd123;
parameter IRQ1 = 8'd126;

parameter JUMP_VECTOR1 = 8'd127;
parameter JUMP_VECTOR2 = 8'd128;
parameter JUMP_VECTOR3 = 8'd129;
parameter JUMP_VECTOR4 = 8'd130;
parameter JUMP_VECTOR5 = 8'd131;
parameter JUMP_VECTOR6 = 8'd132;
parameter JUMP_VECTOR7 = 8'd133;
parameter JUMP_VECTOR8 = 8'd134;
parameter JUMP_VECTOR9 = 8'd135;

parameter STORE_DATA = 8'd136;
parameter STORE_DATA1 = 8'd137;
parameter STORE_DATA2 = 8'd138;
parameter STORE_DATA3 = 8'd139;

parameter INTO = 8'd140;
parameter FIRST = 8'd141;

parameter INTA0 = 8'd142;
parameter INTA1 = 8'd143;
parameter INTA2 = 8'd144;
parameter INTA3 = 8'd145;

parameter RETPOP = 8'd150;
parameter RETPOP_NACK = 8'd151;
parameter RETPOP1 = 8'd152;
parameter RETPOP1_NACK = 8'd153;

parameter RETFPOP = 8'd154;
parameter RETFPOP1 = 8'd155;
parameter RETFPOP2 = 8'd156;
parameter RETFPOP3 = 8'd157;
parameter RETFPOP4 = 8'd158;
parameter RETFPOP5 = 8'd159;
parameter RETFPOP6 = 8'd160;
parameter RETFPOP7 = 8'd161;
parameter RETFPOP8 = 8'd162;

parameter XLAT_ACK = 8'd166;

parameter FETCH_DESC = 8'd170;
parameter FETCH_DESC1 = 8'd171;
parameter FETCH_DESC2 = 8'd172;
parameter FETCH_DESC3 = 8'd173;
parameter FETCH_DESC4 = 8'd174;
parameter FETCH_DESC5 = 8'd175;

parameter INSB = 8'd180;
parameter INSB1 = 8'd181;
parameter OUTSB = 8'd182;
parameter OUTSB1 = 8'd183;

parameter SCASB = 8'd185;
parameter SCASB1 = 8'd186;
parameter SCASW = 8'd187;
parameter SCASW1 = 8'd188;
parameter SCASW2 = 8'd189;

parameter CMPSW = 8'd190;
parameter CMPSW1 = 8'd191;
parameter CMPSW2 = 8'd192;
parameter CMPSW3 = 8'd193;
parameter CMPSW4 = 8'd194;
parameter CMPSW5 = 8'd195;

parameter LODS = 8'd196;
parameter LODS_NACK = 8'd197;
parameter LODS1 = 8'd198;
parameter LODS1_NACK = 8'd199;

parameter INSW = 8'd200;
parameter INSW1 = 8'd201;
parameter INSW2 = 8'd202;
parameter INSW3 = 8'd203;

parameter OUTSW = 8'd205;
parameter OUTSW1 = 8'd206;
parameter OUTSW2 = 8'd207;
parameter OUTSW3 = 8'd208;

parameter CALL_FIN = 8'd210;
parameter CALL_FIN1 = 8'd211;
parameter CALL_FIN2 = 8'd212;
parameter CALL_FIN3 = 8'd213;
parameter CALL_FIN4 = 8'd214;

parameter INT = 8'd220;
parameter INT1 = 8'd221;
parameter INT2 = 8'd222;
parameter INT3 = 8'd223;
parameter INT4 = 8'd224;
parameter INT5 = 8'd225;
parameter INT6 = 8'd226;
parameter INT7 = 8'd227;
parameter INT8 = 8'd228;
parameter INT9 = 8'd229;
parameter INT10 = 8'd230;
parameter INT11 = 8'd231;
parameter INT12 = 8'd232;
parameter INT13 = 8'd233;
parameter INT14 = 8'd234;

parameter IRET3 = 8'd235;
parameter IRET4 = 8'd236;
parameter IRET5 = 8'd237;
parameter IRET6 = 8'd238;
parameter IRET7 = 8'd239;
parameter IRET8 = 8'd240;
parameter IRET9 = 8'd241;
parameter IRET10 = 8'd242;
parameter IRET11 = 8'd243;
parameter IRET12 = 8'd244;

parameter INSB2 = 8'd246;
parameter OUTSB2 = 8'd247;

parameter CMPSB = 8'd250;
parameter CMPSB1 = 8'd251;
parameter CMPSB2 = 8'd252;
parameter CMPSB3 = 8'd253;
parameter CMPSB4 = 8'd254;

integer n;
reg [527:0] icmem0 [255:0];
reg [527:0] icmem1 [255:0];
reg [19:6] itmem00 [63:0];
reg [19:6] itmem01 [63:0];
reg [19:6] itmem02 [63:0];
reg [19:6] itmem03 [63:0];
reg [19:6] itmem10 [63:0];
reg [19:6] itmem11 [63:0];
reg [19:6] itmem12 [63:0];
reg [19:6] itmem13 [63:0];

wire hit00 = itmem00[csip0[11:6]]] == csip0[19:6];
wire hit01 = itmem01[csip0[11:6]]] == csip0[19:6];
wire hit02 = itmem02[csip0[11:6]]] == csip0[19:6];
wire hit03 = itmem03[csip0[11:6]]] == csip0[19:6];
wire hit0 = hit00|hit01|hit02|hit03;

reg [15:0] ip [0:NTHREAD];
reg [15:0] cs [0:NTHREAD];
reg [15:0] ax [0:NTHREAD];
reg [15:0] bx [0:NTHREAD];
reg [15:0] cx [0:NTHREAD];
reg [15:0] dx [0:NTHREAD];
reg [15:0] si [0:NTHREAD];
reg [15:0] di [0:NTHREAD];
reg [15:0] bp [0:NTHREAD];
reg [15:0] sp [0:NTHREAD];
reg [15:0] ss [0:NTHREAD];
reg [15:0] ds [0:NTHREAD];
reg [15:0] es [0:NTHREAD];

reg af [0:NTHREAD];

reg [15:0] cs0, ip0;
reg [15:0] cs1, ip1;
wire [19:0] csip0 = {cs0,4'h0} + ip0;
wire [19:0] csip1 = {cs1,4'h0} + ip1;

reg fetchbuf0_v;
reg [4:0] fetchbuf0_thrd;
reg [15:0] fetchbuf0_pc;
reg [15:0] fetchbuf0_cs;
reg [47:0] fetchbuf0_instr;

reg [QENTRIES-1:0] iqentry_val;
reg [QENTRIES-1:0] iqentry_done;
reg [QENTRIES-1:0] iqentry_out;
reg [QENTRIES-1:0] iqentry_agen;
reg [3:0] iqentry_icnt [0:QENTRIES-1];
reg [5:0] iqentry_state [0:QENTRIES-1];
reg [47:0] iqentry_instr [0:QENTRIES-1];
reg [7:0] iqentry_ir [0:QENTRIES-1];
reg [7:0] iqentry_ir2 [0:QENTRIES-1];
reg [QENTRIES-1:0] iqentry_w;
reg [QENTRIES-1:0] iqentry_d;
reg [QENTRIES-1:0] iqentry_v;
reg [QENTRIES-1:0] iqentry_sxi;
reg [1:0] iqentry_mod [0:QENTRIES-1];
reg [2:0] iqentry_rrr [0:QENTRIES-1];
reg [1:0] iqentry_rm [0:QENTRIES-1];
reg [1:0] iqentry_sreg2 [0:QENTRIES-1];
reg [2:0] iqentry_sreg3 [0:QENTRIES-1];
reg [15:0] iqentry_a [0:QENTRIES-1];
reg [15:0] iqentry_b [0:QENTRIES-1];
reg [15:0] iqentry_seg [0:QENTRIES-1];
reg [15:0] iqentry_offset [0:QENTRIES-1];
reg [15:0] iqentry_disp [0:QENTRIES-1];
reg [15:0] iqentry_offsdisp [0:QENTRIES-1];
reg [19:0] iqentry_ea [0:QENTRIES-1];
reg [QENTRIES-1:0] iqentry_buslock;
reg [4:0] iqentry_tgt [0:QENTRIES-1];
reg [8:0] iqentry_ftgt [0:QENTRIES-1];
reg [15:0] iqentry_res [0:QENTRIES-1];
reg [QENTRIES-1:0] iqentry_cf;
reg [QENTRIES-1:0] iqentry_pf;
reg [QENTRIES-1:0] iqentry_af;
reg [QENTRIES-1:0] iqentry_zf;
reg [QENTRIES-1:0] iqentry_sf;
reg [QENTRIES-1:0] iqentry_tf;
reg [QENTRIES-1:0] iqentry_iff;
reg [QENTRIES-1:0] iqentry_df;
reg [QENTRIES-1:0] iqentry_of;
reg [7:0] iqentry_int[0:QENTRIES-1];

reg [2:0] alu0_id;
reg [7:0] alu0_ir;
reg [15:0] alu0_a;
reg [15:0] alu0_b;
reg alu0_cf;
wire [1%:0] alu_o;

reg fcu0_state;
reg [2:0] fcu0_id;
reg [7:0] fcu0_ir;
reg [15:0] fcu0_cx;
reg fcu0_zf;
reg fcu0_cf;
reg fcu0_sf;
reg fcu0_of;
reg fcu0_pf;
wire fcu0_takb;

reg fcu1_state;
reg [2:0] fcu1_id;
reg [7:0] fcu1_ir;
reg [15:0] fcu1_cx;
reg fcu1_zf;
reg fcu1_cf;
reg fcu1_sf;
reg fcu1_of;
reg fcu1_pf;
wire fcu1_takb;

function [15:0] seg_reg;
input [7:0] ir;
input [7:0] prefix1;
input [7:0] prefix2;
input [7:0] modrm;
input [4:0] thrd;
case(ir)
`SCASB: seg_reg = es[thrd];
`SCASW: seg_reg = es[thrd];
default:
	case(prefix1)
	`CS: seg_reg = cs[thrd];
	`DS: seg_reg = ds[thrd];
	`ES: seg_reg = es[thrd];
	`SS: seg_reg = ss[thrd];
	default:
		case(prefix2)
		`CS: seg_reg = cs[thrd];
		`DS: seg_reg = ds[thrd];
		`ES: seg_reg = es[thrd];
		`SS: seg_reg = ss[thrd];
		default:
			casex(ir)
			`CMPSB: seg_reg = ds[thrd];
			`CMPSW: seg_reg = ds[thrd];
			`LODSB:	seg_reg = ds[thrd];
			`LODSW:	seg_reg = ds[thrd];
			`MOVSB: seg_reg = ds[thrd];
			`MOVSW: seg_reg = ds[thrd];
			`STOSB: seg_reg = ds[thrd];
			`STOSW: seg_reg = ds[thrd];
			`MOV_AL2M: seg_reg = ds[thrd];
			`MOV_AX2M: seg_reg = ds[thrd];
			default:
				case(modrm)
				5'b00_000:	seg_reg = ds[thrd];
				5'b00_001:	seg_reg = ds[thrd];
				5'b00_010:	seg_reg = ss[thrd];
				5'b00_011:	seg_reg = ss[thrd];
				5'b00_100:	seg_reg = ds[thrd];
				5'b00_101:	seg_reg = ds[thrd];
				5'b00_110:	seg_reg = ds[thrd];
				5'b00_111:	seg_reg = ds[thrd];
			
				5'b01_000:	seg_reg = ds[thrd];
				5'b01_001:	seg_reg = ds[thrd];
				5'b01_010:	seg_reg = ss[thrd];
				5'b01_011:	seg_reg = ss[thrd];
				5'b01_100:	seg_reg = ds[thrd];
				5'b01_101:	seg_reg = ds[thrd];
				5'b01_110:	seg_reg = ss[thrd];
				5'b01_111:	seg_reg = ds[thrd];
			
				5'b10_000:	seg_reg = ds[thrd];
				5'b10_001:	seg_reg = ds[thrd];
				5'b10_010:	seg_reg = ss[thrd];
				5'b10_011:	seg_reg = ss[thrd];
				5'b10_100:	seg_reg = ds[thrd];
				5'b10_101:	seg_reg = ds[thrd];
				5'b10_110:	seg_reg = ss[thrd];
				5'b10_111:	seg_reg = ds[thrd];
			
				default:	seg_reg = ds[thrd];
				endcase
			endcase
		endcase
	endcase
endcase
endfunction

function [15:0] rmo;
input w;
input [2:0] rm;
input [4:0] thrd;
case({w,rm})
4'd0:	rmo = {{8{ax[thrd][7]}},ax[thrd][7:0]};
4'd1:	rmo = {{8{cx[thrd][7]}},cx[thrd][7:0]};
4'd2:	rmo = {{8{dx[thrd][7]}},dx[thrd][7:0]};
4'd3:	rmo = {{8{bx[thrd][7]}},bx[thrd][7:0]};
4'd4:	rmo = {{8{ax[thrd][15]}},ax[thrd][15:8]};
4'd5:	rmo = {{8{cx[thrd][15]}},cx[thrd][15:8]};
4'd6:	rmo = {{8{dx[thrd][15]}},dx[thrd][15:8]};
4'd7:	rmo = {{8{bx[thrd][15]}},bx[thrd][15:8]};
4'd8:	rmo = ax[thrd];
4'd9:	rmo = cx[thrd];
4'd10:	rmo = dx[thrd];
4'd11:	rmo = bx[thrd];
4'd12:	rmo = sp[thrd];
4'd13:	rmo = bp[thrd];
4'd14:	rmo = si[thrd];
4'd15:	rmo = di[thrd];
endcase
endfunction

function [15:0] rfso;
input [2:0] sg3;
input [4:0] thrd;
case(sg3)
3'd0:	rfso = es[thrd];
3'd1:	rfso = cs[thrd];
3'd2:	rfso = ss[thrd];
3'd3:	rfso = ds[thrd];
default:	rfso = 16'h0000;
endcase
endfunction

// Detect when to fetch the mod-r/m byte
//
function fetch_modrm;
input [7:0] ir;
input [7:0] ir2;
fetch_modrm = 
	ir==8'h00 || ir==8'h01 || ir==8'h02 || ir==8'h03 || // ADD
	ir==8'h08 || ir==8'h09 || ir==8'h0A || ir==8'h0B || // OR
	ir==8'h10 || ir==8'h11 || ir==8'h12 || ir==8'h13 ||	// ADC
	ir==8'h18 || ir==8'h19 || ir==8'h1A || ir==8'h1B || // SBB
	ir==8'h20 || ir==8'h21 || ir==8'h22 || ir==8'h23 || // AND
	ir==8'h28 || ir==8'h29 || ir==8'h2A || ir==8'h2B || // SUB
	ir==8'h30 || ir==8'h31 || ir==8'h32 || ir==8'h33 || // XOR
	ir==8'h38 || ir==8'h39 || ir==8'h3A || ir==8'h3B || // CMP
	ir==8'h3C || ir==8'h3D ||						    // CMP
	ir==8'h62 ||	// BOUND
	ir==8'h63 ||	// ARPL
	ir==8'h69 || ir==8'h6B ||							// IMUL
	ir[7:4]==4'h8 ||
	(ir[7]==1'b0 && ir[6]==1'b0 && ir[2]==1'b0) ||		// arithmetic
	(ir==8'h0F && ir2[7:4]==4'hA && ir2[2:1]==2'b10) ||
	ir==8'hC4 || ir==8'hC5 ||							// LES / LDS
	ir==8'hC6 || ir==8'hC7 || 							// MOV I
	ir==8'hC0 || ir==8'hC1 ||							// shift / rotate
	ir==8'hD0 || ir==8'hD1 || ir==8'hD2 || ir==8'hD3 ||	// shift / rotate
	ir==8'hF6 || ir==8'hF7 ||							// NOT / NEG / TEST / MUL / IMUL / DIV / IDIV
	ir==8'hFE || ir==8'hFF								// INC / DEC / CALL
	;
endfunction

FT8088Q_evaluate_branch ube0
(
	.ir(fcu0_ir),
	.cx(fcu0_cx),
	.zf(fcu0_zf),
	.cf(fcu0_cf),
	.sf(fcu0_sf),
	.vf(fcu0_of),
	.pf(fcu0_pf),
	.take_br(fcu0_takb)
);

FT8088Q_evaluate_branch ube1
(
	.ir(fcu1_ir),
	.cx(fcu1_cx),
	.zf(fcu1_zf),
	.cf(fcu1_cf),
	.sf(fcu1_sf),
	.vf(fcu1_of),
	.pf(fcu1_pf),
	.take_br(fcu1_takb)
);

FT8088Q_ALU alu0
(
	.ir(alu0_ir),
	.a(alu0_a),
	.b(alu0_b),
	.cf(alu0_cf),
	.o(alu0_o)
);

always @(posedge clk)
begin
	// Fetch instructions
	if (hit0) begin
		fetchbuf0_v <= `VAL;
		fetchbuf0_thrd <= ipndx0;
		fetchbuf0_ip <= ip0;
		fetchbuf0_cs <= cs0;
		fetchbuf0_instr <= icmem0[{way0,csip0[11:6]}] >> {csip0[5:0],3'b0};
		ip0 <= next_ip[ipndx0];
		cs0 <= next_cs[ipndx0];
		ipndx0 <= ipndx0 + 4'd1;
	end
	if (hit1) begin
		fetchbuf1_v <= `VAL;
		fetchbuf1_thrd <= ipndx1;
		fetchbuf1_ip <= ip1;
		fetchbuf1_cs <= cs1;
		fetchbuf1_instr <= icmem1[{way1,csip1[11:6]}] >> {csip1[5:0],3'b0};
		ip1 <= next_ip[ipndx1];
		cs1 <= next_cs[ipndx1];
		ipndx1 <= ipndx1 + 4'd1;
	end
	// Queue Instructions
	case ({fetchbuf1_v,fetchbuf0_v})
	2'b00:	;
	2'b01:
		if (iqentry_v[tail0]==`INV) begin
			iqentry_v[tail0] <= `VAL;
			iqentry_state[tail0] <= DECODE;
			iqentry_thrd[tail0] <= fetchbuf0_thrd;
			iqentry_icnt[tail0] <= 4'd1;
			iqentry_ip[tail0] <= fetchbuf0_ip;
			iqentry_cs[tail0] <= fetchbuf0_cs;
			iqentry_instr[tail0] <= {`NOP,fetchbuf0_instr[63:8]};
			iqentry_prefix1[tail0] <= 8'h00;
			iqentry_prefix2[tail0] <= 8'h00;
			iqentry_w[tail0] <= fetchbuf0_instr[0];
			iqentry_d[tail0] <= fetchbuf0_instr[1];
			iqentry_v[tail0] <= fetchbuf0_instr[1];
			iqentry_sxi[tail0] <= fetchbuf0_instr[1];
			iqentry_sreg2[tail0] <= fetchbuf0_instr[4:3];
			iqentry_sreg3[tail0] <= {1'b0,fetchbuf0_instr[4:3]};
			iqentry_ir[tail0] <= fetchbuf0_instr[7:0];
			iqentry_ir2[tail0] <= 8'h00;
			iqentry_mod[tail0] <= fetchbuf0_instr[15:14];
			iqentry_rrr[tail0] <= fetchbuf0_instr[13:11];
			iqentry_rm[tail0] <= fetchbuf0_instr[10:8];
			iqentry_buslock[tail0] <= 1'b0;
			iqentry_cf[tail0] <= cf[fetchbuf0_thrd];
			iqentry_pf[tail0] <= pf[fetchbuf0_thrd];
			iqentry_af[tail0] <= af[fetchbuf0_thrd];
			iqentry_zf[tail0] <= zf[fetchbuf0_thrd];
			iqentry_sf[tail0] <= sf[fetchbuf0_thrd];
			iqentry_tf[tail0] <= tf[fetchbuf0_thrd];
			iqentry_iff[tail0] <= iff[fetchbuf0_thrd];
			iqentry_df[tail0] <= df[fetchbuf0_thrd];
			iqentry_of[tail0] <= of[fetchbuf0_thrd];
			iqentry_wrregs[tail0] <= 1'b0;
			iqentry_wrsregs[tail0] <= 1'b0;
			iqentry_ftgt[tail0] <= 9'h00;
			fetchbuf0_v <= `INV;
			tail0 <= tail0 + 3'd1;
			tail1 <= tail1 + 3'd1;
		end
	2'b10:
		if (iqentry_v[tail0]==`INV) begin
			iqentry_state[tail0] <= DECODE;
			iqentry_v[tail0] <= `VAL;
			iqentry_thrd[tail0] <= fetchbuf1_thrd;
			iqentry_icnt[tail0] <= 4'd1;
			iqentry_ip[tail0] <= fetchbuf1_ip;
			iqentry_cs[tail0] <= fetchbuf1_cs;
			iqentry_instr[tail0] <= {`NOP,fetchbuf1_instr[63:8]};
			iqentry_prefix1[tail0] <= 8'h00;
			iqentry_prefix2[tail0] <= 8'h00;
			iqentry_w[tail0] <= fetchbuf1_instr[0];
			iqentry_d[tail0] <= fetchbuf1_instr[1];
			iqentry_v[tail0] <= fetchbuf1_instr[1];
			iqentry_sxi[tail0] <= fetchbuf1_instr[1];
			iqentry_sreg2[tail0] <= fetchbuf1_instr[4:3];
			iqentry_sreg3[tail0] <= {1'b0,fetchbuf1_instr[4:3]};
			iqentry_ir[tail0] <= fetchbuf1_instr[7:0];
			iqentry_ir2[tail0] <= 8'h00;
			iqentry_mod[tail0] <= fetchbuf1_instr[15:14];
			iqentry_rrr[tail0] <= fetchbuf1_instr[13:11];
			iqentry_rm[tail0] <= fetchbuf1_instr[10:8];
			iqentry_buslock[tail0] <= 1'b0;
			iqentry_cf[tail0] <= cf[fetchbuf1_thrd];
			iqentry_pf[tail0] <= pf[fetchbuf1_thrd];
			iqentry_af[tail0] <= af[fetchbuf1_thrd];
			iqentry_zf[tail0] <= zf[fetchbuf1_thrd];
			iqentry_sf[tail0] <= sf[fetchbuf1_thrd];
			iqentry_tf[tail0] <= tf[fetchbuf1_thrd];
			iqentry_iff[tail0] <= iff[fetchbuf1_thrd];
			iqentry_df[tail0] <= df[fetchbuf1_thrd];
			iqentry_of[tail0] <= of[fetchbuf1_thrd];
			iqentry_wrregs[tail0] <= 1'b0;
			iqentry_wrsregs[tail0] <= 1'b0;
			iqentry_ftgt[tail0] <= 9'h00;
			fetchbuf1_v <= `INV;
			tail0 <= tail0 + 3'd1;
			tail1 <= tail1 + 3'd1;
		end
	2'b11:
		begin
			if (iqentry_v[tail0]==`INV) begin
				iqentry_state[tail0] <= DECODE;
				iqentry_v[tail0] <= `VAL;
				iqentry_thrd[tail0] <= fetchbuf0_thrd;
				iqentry_icnt[tail0] <= 4'd1;
				iqentry_ip[tail0] <= fetchbuf0_ip;
				iqentry_cs[tail0] <= fetchbuf0_cs;
				iqentry_instr[tail0] <= {`NOP,fetchbuf0_instr[63:8]};
				iqentry_prefix1[tail0] <= 8'h00;
				iqentry_prefix2[tail0] <= 8'h00;
				iqentry_w[tail0] <= fetchbuf0_instr[0];
				iqentry_d[tail0] <= fetchbuf0_instr[1];
				iqentry_v[tail0] <= fetchbuf0_instr[1];
				iqentry_sxi[tail0] <= fetchbuf0_instr[1];
				iqentry_sreg2[tail0] <= fetchbuf0_instr[4:3];
				iqentry_sreg3[tail0] <= {1'b0,fetchbuf0_instr[4:3]};
				iqentry_ir[tail0] <= fetchbuf0_instr[7:0];
				iqentry_ir2[tail0] <= 8'h00;
				iqentry_mod[tail0] <= fetchbuf0_instr[15:14];
				iqentry_rrr[tail0] <= fetchbuf0_instr[13:11];
				iqentry_rm[tail0] <= fetchbuf0_instr[10:8];
				iqentry_buslock[tail0] <= 1'b0;
				iqentry_cf[tail0] <= cf[fetchbuf0_thrd];
				iqentry_pf[tail0] <= pf[fetchbuf0_thrd];
				iqentry_af[tail0] <= af[fetchbuf0_thrd];
				iqentry_zf[tail0] <= zf[fetchbuf0_thrd];
				iqentry_sf[tail0] <= sf[fetchbuf0_thrd];
				iqentry_tf[tail0] <= tf[fetchbuf0_thrd];
				iqentry_iff[tail0] <= iff[fetchbuf0_thrd];
				iqentry_df[tail0] <= df[fetchbuf0_thrd];
				iqentry_of[tail0] <= of[fetchbuf0_thrd];
				iqentry_wrregs[tail0] <= 1'b0;
				iqentry_wrsregs[tail0] <= 1'b0;
				iqentry_ftgt[tail0] <= 9'h00;
				fetchbuf0_v <= `INV;
				tail0 <= tail0 + 3'd1;
				tail1 <= tail1 + 3'd1;
			end
			if (iqentry_v[tail1]==`INV) begin
				iqentry_state[tail1] <= DECODE;
				iqentry_v[tail1] <= `VAL;
				iqentry_thrd[tail1] <= fetchbuf1_thrd;
				iqentry_icnt[tail1] <= 4'd1;
				iqentry_ip[tail1] <= fetchbuf1_ip;
				iqentry_cs[tail1] <= fetchbuf1_cs;
				iqentry_instr[tail1] <= {`NOP,fetchbuf1_instr[63:8]};
				iqentry_prefix1[tail1] <= 8'h00;
				iqentry_prefix2[tail1] <= 8'h00;
				iqentry_w[tail1] <= fetchbuf1_instr[0];
				iqentry_d[tail1] <= fetchbuf1_instr[1];
				iqentry_v[tail1] <= fetchbuf1_instr[1];
				iqentry_sxi[tail1] <= fetchbuf1_instr[1];
				iqentry_sreg2[tail1] <= fetchbuf1_instr[4:3];
				iqentry_sreg3[tail1] <= {1'b0,fetchbuf1_instr[4:3]};
				iqentry_ir[tail1] <= fetcbuf1_instr[7:0];
				iqentry_ir2[tail1] <= 8'h00;
				iqentry_mod[tail1] <= fetchbuf1_instr[15:14];
				iqentry_rrr[tail1] <= fetchbuf1_instr[13:11];
				iqentry_rm[tail1] <= fetchbuf1_instr[10:8];
				iqentry_buslock[tail1] <= 1'b0;
				iqentry_cf[tail1] <= cf[fetchbuf1_thrd];
				iqentry_pf[tail1] <= pf[fetchbuf1_thrd];
				iqentry_af[tail1] <= af[fetchbuf1_thrd];
				iqentry_zf[tail1] <= zf[fetchbuf1_thrd];
				iqentry_sf[tail1] <= sf[fetchbuf1_thrd];
				iqentry_tf[tail1] <= tf[fetchbuf1_thrd];
				iqentry_iff[tail1] <= iff[fetchbuf1_thrd];
				iqentry_df[tail1] <= df[fetchbuf1_thrd];
				iqentry_of[tail1] <= of[fetchbuf1_thrd];
				iqentry_wrregs[tail1] <= 1'b0;
				iqentry_wrsregs[tail1] <= 1'b0;
				iqentry_ftgt[tail1] <= 9'h00;
				fetchbuf1_v <= `INV;
				tail0 <= tail0 + 3'd2;
				tail1 <= tail1 + 3'd2;
			end
		end
	end

	for (n = 0; n < QENTRIES; n = n + 1)
	case(iqentry_state[n])
	DECODE:
		// Stay in decode state
		case(fetchbuf0_ir[n])
		`MORE1,
		`MORE2,
		`EXTOP:
			begin
				iqentry_ir2[n] <= iqentry_instr[n][7:0];
				iqentry_instr[n] <= {`NOP,iqentry_instr[n][63:8]};
				iqentry_icnt[n] <= iqentry_icnt[n] + 4'd1;
			end
		default:	;
		endcase
		
		casez(iqentry_ir[n])
		//-----------------------------------------------------------------
		// Flag register operations
		//-----------------------------------------------------------------
		`CLC:
			begin
			iqentry_ftgt[n] <= 9'h01;
			iqentry_cf[n] <= 1'b0;
			iqentry_done[n] <= `VAL;
			iqentry_state[n] <= `WRITEBACK;
			end
		`CMC:
			begin
			iqentry_ftgt[n] <= 9'h01;
			iqentry_cf[n] <= ~iqentry_cf[n];
			iqentry_done[n] <= `VAL;
			iqentry_state[n] <= `WRITEBACK;
			end
		`STC:
			begin
			iqentry_ftgt[n] <= 9'h01;
			iqentry_cf[n] <= 1'b1;
			iqentry_done[n] <= `VAL;
			iqentry_state[n] <= `WRITEBACK;
			end
		`CLD:
			begin
			iqentry_ftgt[n] <= 9'h80;
			iqentry_df[n] <= 1'b0;
			iqentry_done[n] <= `VAL;
			iqentry_state[n] <= `WRITEBACK;
			end
		`STD:
			begin
			iqentry_ftgt[n] <= 9'h80;
			iqentry_df[n] <= 1'b1;
			iqentry_done[n] <= `VAL;
			iqentry_state[n] <= `WRITEBACK;
			end
		`CLI:
			begin
			iqentry_ftgt[n] <= 9'h40;
			iqentry_iff[n] <= 1'b0;
			iqentry_done[n] <= `VAL;
			iqentry_state[n] <= `WRITEBACK;
			end
		`STI:
			begin
			iqentry_ftgt[n] <= 9'h40;
			iqentry_iff[n] <= 1'b1;
			iqentry_done[n] <= `VAL;
			iqentry_state[n] <= `WRITEBACK;
			end
		`LAHF:
			begin
				ax[iqentry_thrd[n]][15] <= sf[iqentry_thrd[n]];
				ax[iqentry_thrd[n]][14] <= zf[iqentry_thrd[n]];
				ax[iqentry_thrd[n]][12] <= af[iqentry_thrd[n]];
				ax[iqentry_thrd[n]][10] <= pf[iqentry_thrd[n]];
				ax[iqentry_thrd[n]][8] <= cf[iqentry_thrd[n]];
				iqentry_state[n] <= IFETCH;
			end
		`SAHF:
			begin
				sf[iqentry_thrd[n]] <= ax[iqentry_thrd[n]][7];
				zf[iqentry_thrd[n]] <= ax[iqentry_thrd[n]][6];
				af[iqentry_thrd[n]] <= ax[iqentry_thrd[n]][4];
				pf[iqentry_thrd[n]] <= ax[iqentry_thrd[n]][2];
				cf[iqentry_thrd[n]] <= ax[iqentry_thrd[n]][0];
				iqentry_state[n] <= IFETCH;
			end

		//-----------------------------------------------------------------
		// Flow control operations
		//-----------------------------------------------------------------
		`JMP:
			begin
				ip[iqentry_thrd[n]] <= ip[iqentry_thrd[n]] + iqentry_instr[15:0];
				iqentry_icnt[n] <= 4'd0;
				iqentry_done[n] <= `TRUE;
				iqentry_state[n] <= WRITEBACK;
			end
		`JMPF:
			begin
				ip[iqentry_thrd[n]] <= iqentry_instr[15:0];
				cs[iqentry_thrd[n]] <= iqentry_instr[31:16];
				iqentry_icnt[n] <= 4'd0;
				iqentry_done[n] <= `TRUE;
				iqentry_state[n] <= WRITEBACK;
			end
		`CALL:
			begin
				ip[iqentry_thrd[n]] <= ip[iqentry_thrd[n]] + iqentry_instr[15:0];
				iqentry_icnt[n] <= 4'd0;
				iqentry_done[n] <= `TRUE;
				state <= CALL;
			end
		`CALL:
			begin
				iqentry_state[n] <= CALL;
			end
		`CALLF:
			begin
				iqentry_state[n] <= CALLF;
			end
		`RET,`RETF,`RETFPOP,`RETPOP:
			begin
				iqentry_state[n] <= RET;
			end
		`JMPS,`JCXZ,`Jcc:
			begin
				iqentry_state[n] <= ISSUE;
			end

		//-----------------------------------------------------------------
		// Control Prefix
		//-----------------------------------------------------------------
		// Stay in DECODE state for these
		`LOCK:
			begin
			iqentry_buslock[n] <= 1'b1;
			iqentry_instr[n] <= {`NOP,iqentry_instr[n][63:8]};
			iqentry_icnt[n] <= iqentry_icnt[n] + 4'd1;
			end
		`REPZ,`REPNZ,`CS,`DS,`ES,`SS:
			begin
			if (iqentry_prefix1[n]) begin
				iqentry_prefix2[n] <= iqentry_instr[n][7:0];
			end
			else begin
				iqentry_prefix1[n] <= iqentry_instr[n][7:0];
			end
			iqentry_instr[n] <= {`NOP,iqentry_instr[n][63:8]};
			iqentry_icnt[n] <= iqentry_icnt[n] + 4'd1;
			end
		`MOV_I2AX,
		`MOV_I2BX,
		`MOV_I2CX,
		`MOV_I2DX,
		`MOV_I2SI,
		`MOV_I2DI,
		`MOV_I2BP,
		`MOV_I2SP:
			begin
			iqentry_state[n] <= WRITEBACK;
			iqentry_w[n] <= 1'b1;
			iqentry_rrr[n] <= ir[2:0];
			iqentry_wrregs[n] <= 1'b1;
			iqentry_res[n] <= iqentry_instr[15:0];
			iqentry_icnt[n] <= iqentry_icnt[n] + 4'd2;
			if (ip[iqentry_thrd[n]]+iqentry_icnt[n]==16'hFFFF) begin
				iqentry_int[n] <= 8'h0d;
				iqentry_state[n] <= INT2;
			end
			end
		`MOV_I2AL,
		`MOV_I2BL,
		`MOV_I2CL,
		`MOV_I2DL,
		`MOV_I2AH,
		`MOV_I2BH,
		`MOV_I2CH,
		`MOV_I2DH:
			begin
			iqentry_w[n] <= 1'b0;
			iqentry_rrr[n] <= ir[2:0];
			iqentry_wrregs[n] <= 1'b1;
			iqentry_state[n] <= WRITEBACK;
			iqentry_res[n] <= iqentry_instr[7:0];
			iqentry_icnt[n] <= iqentry_icnt[n] + 4'd1;
			end
		`XLAT:
			begin
			iqentry_state[n] <= MEM_ACCESS;
			iqentry_mem[n] <= `VAL;
			iqentry_out[n] <= `VAL;
			iqentry_tgt[n] <= 5'b01000;
			iqentry_ea[n] <= {seg_reg(
				iqentry_instr[n][7:0],
				iqentry_prefix1[n],
				iqentry_prefix1[n],
				8'h00,	// modrm
				iqentry_thrd[n]),`SEG_SHIFT} + bx[iqentry_thrd[n]] + al[iqentry_thrd[n]];
			end
		`AAA:
			begin
			iqentry_w[n] <= 1'b1;
			iqentry_rrr[n] <= 3'd0;
			iqentry_wrregs[n] <= 1'b1;
			iqentry_state[n] <= WRITEBACK;
			iqentry_tgt[n] <= 5'b00000;
			if (ax[iqentry_thrd[n]][3:0]>4'h9 || af[iqentry_thrd[n]]) begin
				iqentry_res[n][3:0] <= ax[iqentry_thrd[n]][3:0] + 4'd6;
				iqentry_res[n][7:4] <= 4'h0;
				iqentry_res[n][15:8] <= ax[iqentry_thrd[n]][15:8] + 8'd1;
			end
			else
				iqentry_res[n] <= ax[iqentry_thrd[n]];
			iqentry_done[n] <= `VAL;
			af[iqentry_thrd[n]] <= (ax[iqentry_thrd[n]][3:0]>4'h9 || af[iqentry_thrd[n]]);
			cf[iqentry_thrd[n]] <= (ax[iqentry_thrd[n]][3:0]>4'h9 || af[iqentry_thrd[n]]);
			end
		`AAS:
			begin
			iqentry_state[n] <= WRITEBACK;
			iqentry_w[n] <= 1'b1;
			iqentry_rrr[n] <= 3'd0;
			iqentry_wrregs[n] <= 1'b1;
			if (ax[iqentry_thrd[n]][3:0]>4'h9 || af[iqentry_thrd[n]]) begin
				iqentry_res[n][3:0] <= ax[iqentry_thrd[n]][3:0] - 4'd6;
				iqentry_res[n][7:4] <= 4'h0;
				iqentry_res[n][15:8] <= ax[iqentry_thrd[n]][15:8] - 8'd1;
			end
			else
				iqentry_res[n] <= ax[iqentry_thrd[n]];
			af[iqentry_thrd[n]] <= (ax[iqentry_thrd[n]][3:0]>4'h9 || af[iqentry_thrd[n]]);
			cf[iqentry_thrd[n]] <= (ax[iqentry_thrd[n]][3:0]>4'h9 || af[iqentry_thrd[n]]);
			end
		`ADD_ALI8,`ADC_ALI8,`SUB_ALI8,`SBB_ALI8,`AND_ALI8,`OR_ALI8,`XOR_ALI8:
			begin
				iqentry_w[n] <= 1'b0;
				iqentry_rrr[n] <= 3'd0;
				iqentry_wrregs[n] <= 1'b1;
				iqentry_a[n] <= {{8{ax[iqentry_thrd[n]][7]}},ax[iqentry_thrd[n]][7:0]};
				iqentry_b[n] <= {{8{iqentry_instr[n][7]}},iqentry_instr[n][7:0]};
				iqentry_icnt[n] <= iqentry_icnt[n] + 4'd1;
				iqentry_state[n] <= ISSUE;
			end
		`CMP_ALI8,`TEST_ALI8:
			begin
				iqentry_w[n] <= 1'b0;
				iqentry_rrr[n] <= 3'd0;
				iqentry_a[n] <= {{8{ax[iqentry_thrd[n]][7]}},ax[iqentry_thrd[n]][7:0]};
				iqentry_b[n] <= {{8{iqentry_instr[n][7]}},iqentry_instr[n][7:0]};
				iqentry_icnt[n] <= iqentry_icnt[n] + 4'd1;
				iqentry_state[n] <= ISSUE;
			end
		`ADD_AXI16,`ADC_AXI16,`SUB_AXI16,`SBB_AXI16,`AND_AXI16,`OR_AXI16,`XOR_AXI16:
			begin
				iqentry_w[n] <= 1'b1;
				iqentry_rrr[n] <= 3'd0;
				iqentry_wrregs[n] <= 1'b1;
				iqentry_a[n] <= ax[iqentry_thrd[n]];
				iqentry_b[n] <= iqentry_instr[n][15:0];
				iqentry_icnt[n] <= iqentry_icnt[n] + 4'd2;
				iqentry_state[n] <= ISSUE;
				if (ip[iqentry_thrd[n]]+iqentry_icnt[n]==16'hFFFF) begin
					iqentry_int[n] <= 8'h0d;
					iqentry_state[n] <= INT2;
				end
			end
		`CMP_AXI16,`TEST_AXI16:
			begin
				iqentry_w[n] <= 1'b1;
				iqentry_rrr[n] <= 3'd0;
				iqentry_a[n] <= ax[iqentry_thrd[n]];
				iqentry_b[n] <= iqentry_instr[n][15:0];
				iqentry_icnt[n] <= iqentry_icnt[n] + 4'd2;
				iqentry_state[n] <= ISSUE;
				if (ip[iqentry_thrd[n]]+iqentry_icnt[n]==16'hFFFF) begin
					iqentry_int[n] <= 8'h0d;
					iqentry_state[n] <= INT2;
				end
			end
		`ALU_I2R8:
			begin
				iqentry_w[n] <= 1'b0;
				iqentry_wrregs[n] <= iqentry_rrr[n] != 3'd7;	// CMP
				iqentry_a[n] <= rrro(iqentry_w[n],iqentry_rm[n],iqentry_thrd[n]);
				iqentry_b[n] <= {{8{iqentry_instr[n][7]}},iqentry_instr[n][7:0]};
				iqentry_state[n] <= ISSUE;
			end
		`ALU_I2R16:
			begin
				iqentry_w[n] <= 1'b1;
				iqentry_wrregs[n] <= iqentry_rrr[n] != 3'd7;
				iqentry_a[n] <= rrro(iqentry_w[n],iqentry_rm[n],iqentry_thrd[n]);
				iqentry_b[n] <= iqentry_instr[n][15:0];
				iqentry_state[n] <= ISSUE;
				if (ip[iqentry_thrd[n]]+iqentry_icnt[n]==16'hFFFF) begin
					iqentry_int[n] <= 8'h0d;
					iqentry_state[n] <= INT2;
				end
			end
		`XCHG_AXR:
			begin
				iqentry_state[n] <= WRITEBACK;
				iqentry_w[n] <= 1'b1;
				iqentry_rrr[n] <= ir[2:0];
				iqentry_wrregs[n] <= 1'b1;
				iqentry_res[n] <= ax[iqentry_thrd[n]];
				case(ir[2:0])
				3'd0:	ax[iqentry_thrd[n]] <= ax[iqentry_thrd[n]];
				3'd1:	ax[iqentry_thrd[n]] <= cx[iqentry_thrd[n]];
				3'd2:	ax[iqentry_thrd[n]] <= dx[iqentry_thrd[n]];
				3'd3:	ax[iqentry_thrd[n]] <= bx[iqentry_thrd[n]];
				3'd4:	ax[iqentry_thrd[n]] <= sp[iqentry_thrd[n]];
				3'd5:	ax[iqentry_thrd[n]] <= bp[iqentry_thrd[n]];
				3'd6:	ax[iqentry_thrd[n]] <= si[iqentry_thrd[n]];
				3'd7:	ax[iqentry_thrd[n]] <= di[iqentry_thrd[n]];
				endcase
			end
		`CBW:
			begin
				ax[iqentry_thrd[n]][15:8] <= {8{ax[iqentry_thrd[n]][7]}};
				iqentry_state[n] <= IFETCH;
			end
		`CWD:
			begin
				iqentry_state[n] <= WRITEBACK;
				iqentry_w[n] <= 1'b1;
				iqentry_rrr[n] <= 3'd2;
				iqentry_wrregs[n] <= 1'b1;
				iqentry_res[n] <= {16{ax[iqentry_thrd[n]][15]}};
			end

		
		`DEC_REG,`INC_REG:
			begin
				iqentry_w[n] <= 1'b1;
				iqentry_rrr[n] <= iqentry_ir[n][2:0];
				iqentry_state[n] <= REGFETCHA;
			end

		`LEA: 
			iqentry_state[n] <= EXECUTE;

		//-----------------------------------------------------------------
		// String Operations
		//-----------------------------------------------------------------
		`LODSB: iqentry_state[n] <= LODS;
		`LODSW: iqentry_state[n] <= LODS;
		`STOSB: iqentry_state[n] <= STOS;
		`STOSW: iqentry_state[n] <= STOS;
		`MOVSB: iqentry_state[n] <= MOVS;
		`MOVSW: iqentry_state[n] <= MOVS;
		`CMPSB: iqentry_state[n] <= CMPSB;
		`CMPSW: iqentry_state[n] <= CMPSW;
		`SCASB: iqentry_state[n] <= SCASB;
		`SCASW: iqentry_state[n] <= SCASW;

		//-----------------------------------------------------------------
		// Stack Operations
		//-----------------------------------------------------------------
		`PUSH_REG: begin sp[iqentry_thrd[n]] <= sp[iqentry_thrd[n]] - 16'd2; iqentry_state[n] <= PUSH; end
		`PUSH_DS: begin sp[iqentry_thrd[n]] <= sp[iqentry_thrd[n]] - 16'd2; iqentry_state[n] <= PUSH; end
		`PUSH_ES: begin sp[iqentry_thrd[n]] <= sp[iqentry_thrd[n]] - 16'd2; iqentry_state[n] <= PUSH; end
		`PUSH_SS: begin sp[iqentry_thrd[n]] <= sp[iqentry_thrd[n]] - 16'd2; iqentry_state[n] <= PUSH; end
		`PUSH_CS: begin sp[iqentry_thrd[n]] <= sp[iqentry_thrd[n]] - 16'd2; iqentry_state[n] <= PUSH; end
		`PUSHF: begin sp[iqentry_thrd[n]] <= sp[iqentry_thrd[n]] - 16'd2; iqentry_state[n] <= PUSH; end
		`POP_REG: iqentry_state[n] <= POP;
		`POP_DS: iqentry_state[n] <= POP;
		`POP_ES: iqentry_state[n] <= POP;
		`POP_SS: iqentry_state[n] <= POP;
		`POPF: iqentry_state[n] <= POP;

		//-----------------------------------------------------------------
		// Flow controls
		//-----------------------------------------------------------------
		`NOP: iqentry_state[n] <= IFETCH;
		`HLT: if (pe_nmi | (irq_i & ie)) iqentry_state[n] <= IFETCH;
		`WAI: if (!busy_i) iqentry_state[n] <= IFETCH;
		`LOOP: begin cx[iqentry_state[n]] <= cx[iqentry_state[n]] - 16'd1; iqentry_state[n] <= BRANCH1; end
		`LOOPZ: begin cx[iqentry_state[n]] <= cx[iqentry_state[n]] - 16'd1; iqentry_state[n] <= BRANCH1; end
		`LOOPNZ: begin cx[iqentry_state[n]] <= cx[iqentry_state[n]] - 16'd1; iqentry_state[n] <= BRANCH1; end
		`Jcc: iqentry_state[n] <= BRANCH1;
		`JCXZ: iqentry_state[n] <= BRANCH1;
		`JMPS: iqentry_state[n] <= BRANCH1;
		`JMPF: iqentry_state[n] <= FETCH_OFFSET;
		`CALL: begin sp[iqentry_thrd[n]] <= sp[iqentry_thrd[n]] - 16'd2; iqentry_state[n] <= FETCH_DISP16; end
		`CALLF: begin sp[iqentry_thrd[n]] <= sp[iqentry_thrd[n]] - 16'd2; iqentry_state[n] <= FETCH_OFFSET; end
		`RET: iqentry_state[n] <= RET;		// data16 is zero
		`RETPOP: iqentry_state[n] <= RET;
		`RETF: iqentry_state[n] <= RET;	// data16 is zero
		`RETFPOP: iqentry_state[n] <= RET;
		`IRET: iqentry_state[n] <= IRET1;
		`INT: iqentry_state[n] <= INT;
		`INT3: begin iqentry_int[n] <= 8'd3; iqentry_state[n] <= INT2; end
		`INTO:
			if (vf[iqentry_thrd[n]]) begin
				iqentry_int[n] <= 8'd4;
				iqentry_state[n] <= INT2;
			end
			else
				iqentry_state[n] <= IFETCH;

		//-----------------------------------------------------------------
		// IO instructions
		// - fetch port number, then vector
		//-----------------------------------------------------------------
		`INB: iqentry_state[n] <= INB;
		`INW: iqentry_state[n] <= INW;
		`OUTB: iqentry_state[n] <= OUTB;
		`OUTW: iqentry_state[n] <= OUTW;
		`INB_DX: begin iqentry_ea[n] <= {`SEG_SHIFT,dx[iqentry_thrd[n]]}; iqentry_state[n] <= INB1; end
		`INW_DX: begin iqentry_ea[n] <= {`SEG_SHIFT,dx[iqentry_thrd[n]]}; iqentry_state[n] <= INW1; end
		`OUTB_DX: begin iqentry_ea[n] <= {`SEG_SHIFT,dx[iqentry_thrd[n]]}; iqentry_state[n] <= OUTB1; end
		`OUTW_DX: begin iqentry_ea[n] <= {`SEG_SHIFT,dx[iqentry_thrd[n]]}; iqentry_state[n] <= OUTW1; end
		`INSB: iqentry_state[n] <= INSB;
		`OUTSB: iqentry_state[n] <= OUTSB;
		`OUTSW: iqentry_state[n] <= OUTSW;

		//-----------------------------------------------------------------
		// Memory Operations
		//-----------------------------------------------------------------
		
		`MOV_AL2M,`MOV_AX2M:
			begin
				iqentry_res[n] <= ax[iqentry_thrd[n]];
				iqentry_ea[n] <= {seg_reg(
					iqentry_ir[n],
					iqentry_prefix1[n],
					iqentry_prefix1[n],
					8'h00,	// modrm
					iqentry_thrd[n]),`SEG_SHIFT} + iqentry_instr[15:0];
				iqentry_icnt[n] <= iqentry_icnt[n] + 4'd2;
				iqentry_state[n] <= STORE_DATA;
			end
		`MOV_M2AL:
			begin
				iqentry_w[n] <= 1'b0;
				iqentry_d[n] <= 1'b0;
				iqentry_rrr[n] <= 3'd0;
				iqentry_wrregs[n] <= 1'b1;
				iqentry_ea[n] <= {seg_reg(
					iqentry_ir[n],
					iqentry_prefix1[n],
					iqentry_prefix1[n],
					8'h00,	// modrm
					iqentry_thrd[n]),`SEG_SHIFT} + iqentry_instr[15:0];
				iqentry_icnt[n] <= iqentry_icnt[n] + 4'd2;
				iqentry_state[n] <= FETCH_DATA;
			end
		`MOV_M2AX:
			begin
				iqentry_w[n] <= 1'b1;
				iqentry_d[n] <= 1'b0;
				iqentry_rrr[n] <= 3'd0;
				iqentry_wrregs[n] <= 1'b1;
				iqentry_ea[n] <= {seg_reg(
					iqentry_ir[n],
					iqentry_prefix1[n],
					iqentry_prefix1[n],
					8'h00,	// modrm
					iqentry_thrd[n]),`SEG_SHIFT} + iqentry_instr[15:0];
				iqentry_icnt[n] <= iqentry_icnt[n] + 4'd2;
				iqentry_state[n] <= FETCH_DATA;
			end
		default:
			begin
				if (iqentry_v[n]) iqentry_b[n] <= cx[iqentry_thrd[n]][3:0];
				else iqentry_b[n]  <= 16'd1;
				//-----------------------------------------------------------------
				// MOD/RM instructions
				//-----------------------------------------------------------------
				$display("Fetching mod/rm, w=",w);
				if (ir==`MOV_R2S || ir==`MOV_S2R)
					iqentry_w[n] <= 1'b1;
				if (ir==`LDS || ir==`LES)
					iqentry_w[n] <= 1'b1;
				if (fetch_modrm(iqentry_ir[n],iqentry_ir2[n])) begin
					iqentry_mod[n] <= iqentry_instr[n][7:6];
					iqentry_rrr[n] <= iqentry_instr[n][5:3];
					iqentry_rm[n] <= iqentry_instr[n][2:0];
					iqentry_instr[n] <= {`NOP,iqentry_instr[n][63:8]};
					iqentry_icnt[n] <= iqentry_icnt[n] + 4'd1;
					iqentry_state[n] <= EACALC;
				end
				else
					iqentry_state[n] <= WRITEBACK;	// to update ip
			end
		endcase
	REGFETCHA:
		begin
			iqentry_a[n] <= rrro(iqentry_w[n],iqentry_rm[n],iqentry_thrd[n]);
			iq_entry_state[n] <= EXECUTE;
		end

	// Issue instruction to functional unit
	ISSUE:
		case(iqentry_ir[n])
		`ALU_I2R8,`ALU_I2R16,`ADD,`ADD_ALI8,`ADD_AXI16,`ADC,`ADC_ALI8,`ADC_AXI16,
		`AND,`OR,`XOR,`AND_ALI8,`OR_ALI8,`XOR_ALI8,`AND_AXI16,`OR_AXI16,`XOR_AXI16:
			if (alu0_state==IDLE) begin
				alu0_state <= BUSY;
				alu0_ir <= iqentry_ir[n];
				alu0_a <= iqentry_a[n];
				alu0_b <= iqentry_b[n];
				alu0_cf <= cf[iqentry_thrd[n]];
				alu0_id <= n;
				iqentry_state[n] <= OUT;
			end
			else if (alu1_state==IDLE) begin
				alu1_state <= BUSY;
				alu1_ir <= iqentry_ir[n];
				alu1_a <= iqentry_a[n];
				alu1_b <= iqentry_b[n];
				alu1_cf <= cf[iqentry_thrd[n]];
				alu1_id <= n;
				iqentry_state[n] <= OUT;
			end
		`JMPS,`JCXZ,`Jcc:
			if (fcu0_state==IDLE) begin
				fcu0_id <= n;
				fcu0_state <= BUSY;
				fcu0_ir <= iqentry_ir[n];
				fcu0_cx <= cx[iqentry_thrd[n]];
				fcu0_cf <= cf[iqentry_thrd[n]];
				fcu0_pf <= pf[iqentry_thrd[n]];
				fcu0_sf <= sf[iqentry_thrd[n]];
				fcu0_of <= of[iqentry_thrd[n]];				
				fcu0_zf <= zf[iqentry_thrd[n]];
				iqentry_state[n] <= OUT;
			end
			else if (fcu1_state==IDLE) begin
				fcu1_id <= n;
				fcu1_state <= BUSY;
				fcu1_ir <= iqentry_ir[n];
				fcu1_cx <= cx[iqentry_thrd[n]];
				fcu1_cf <= cf[iqentry_thrd[n]];
				fcu1_pf <= pf[iqentry_thrd[n]];
				fcu1_sf <= sf[iqentry_thrd[n]];
				fcu1_of <= of[iqentry_thrd[n]];				
				fcu1_zf <= zf[iqentry_thrd[n]];
				iqentry_state[n] <= OUT;
			end
		endcase
	WRITEBACK:
		if (iqentry_v[head0] & iqentry_done[head0]) begin
			if (iqentry_wrregs[head0])
				case({iqentry_w[head0],iqentry_rrr[head0]})
				4'b0000:	ax[iqentry_thrd[head0]][7:0] <= iqentry_res[head0][7:0];
				4'b0001:	cx[iqentry_thrd[head0]][7:0] <= iqentry_res[head0][7:0];
				4'b0010:	dx[iqentry_thrd[head0]][7:0] <= iqentry_res[head0][7:0];
				4'b0011:	bx[iqentry_thrd[head0]][7:0] <= iqentry_res[head0][7:0];
				4'b0100:	ax[iqentry_thrd[head0]][15:8] <= iqentry_res[head0][7:0];
				4'b0101:	cx[iqentry_thrd[head0]][15:8] <= iqentry_res[head0][7:0];
				4'b0110:	dx[iqentry_thrd[head0]][15:8] <= iqentry_res[head0][7:0];
				4'b0111:	bx[iqentry_thrd[head0]][15:8] <= iqentry_res[head0][7:0];
				4'b1000:	ax[iqentry_thrd[head0]] <= iqentry_res[head0];
				4'b1001:	cx[iqentry_thrd[head0]] <= iqentry_res[head0];
				4'b1010:	dx[iqentry_thrd[head0]] <= iqentry_res[head0];
				4'b1011:	bx[iqentry_thrd[head0]] <= iqentry_res[head0];
				4'b1100:	sp[iqentry_thrd[head0]] <= iqentry_res[head0];
				4'b1101:	bp[iqentry_thrd[head0]] <= iqentry_res[head0];
				4'b1110:	si[iqentry_thrd[head0]] <= iqentry_res[head0];
				4'b1111:	di[iqentry_thrd[head0]] <= iqentry_res[head0];
				endcase

			// Write to segment register
			//
			if (iqentry_wrsregs[head0])
				case(iqentry_rrr[head0])
				3'd0:	es[iqentry_thrd[head0]] <= res[iqentry_thrd[head0]];
				3'd1:	cs[iqentry_thrd[head0]] <= res[iqentry_thrd[head0]];
				3'd2:	ss[iqentry_thrd[head0]] <= res[iqentry_thrd[head0]];
				3'd3:	ds[iqentry_thrd[head0]] <= res[iqentry_thrd[head0]];
				default:	;
				endcase
			if (iqentry_ftgt[head0][0])  cf[iqentry_thrd[head0]] <= iqentry_cf[head0];
			if (iqentry_ftgt[head0][1])  pf[iqentry_thrd[head0]] <= iqentry_pf[head0];
			if (iqentry_ftgt[head0][2])  af[iqentry_thrd[head0]] <= iqentry_af[head0];
			if (iqentry_ftgt[head0][3])  zf[iqentry_thrd[head0]] <= iqentry_zf[head0];
			if (iqentry_ftgt[head0][4])  sf[iqentry_thrd[head0]] <= iqentry_sf[head0];
			if (iqentry_ftgt[head0][5])  tf[iqentry_thrd[head0]] <= iqentry_tf[head0];
			if (iqentry_ftgt[head0][6])  iff[iqentry_thrd[head0]] <= iqentry_iff[head0];
			if (iqentry_ftgt[head0][7])  df[iqentry_thrd[head0]] <= iqentry_df[head0];
			if (iqentry_ftgt[head0][8])  of[iqentry_thrd[head0]] <= iqentry_of[head0];
				
			iqentry_val[head0] <= `INV;
			iqentry_done[head0] <= `INV;
			iqentry_state[head0] <= IFETCH;
			ip[iqentry_thrd[head0]] <= ip[iqentry_thrd[head0]] + iqentry_icnt[head0];
			head0 <= head0 + 3'd1;
			head1 <= head1 + 3'd1;
			if (iqentry_v[head1] & iqentry_done[head1]) begin
				if (iqentry_wrregs[head1])
					case({iqentry_w[head1],iqentry_rrr[head1]})
					4'b0000:	ax[iqentry_thrd[head1]][7:0] <= iqentry_res[head1][7:0];
					4'b0001:	cx[iqentry_thrd[head1]][7:0] <= iqentry_res[head1][7:0];
					4'b0010:	dx[iqentry_thrd[head1]][7:0] <= iqentry_res[head1][7:0];
					4'b0011:	bx[iqentry_thrd[head1]][7:0] <= iqentry_res[head1][7:0];
					4'b0100:	ax[iqentry_thrd[head1]][15:8] <= iqentry_res[head1][7:0];
					4'b0101:	cx[iqentry_thrd[head1]][15:8] <= iqentry_res[head1][7:0];
					4'b0110:	dx[iqentry_thrd[head1]][15:8] <= iqentry_res[head1][7:0];
					4'b0111:	bx[iqentry_thrd[head1]][15:8] <= iqentry_res[head1][7:0];
					4'b1000:	ax[iqentry_thrd[head1]] <= iqentry_res[head1];
					4'b1001:	cx[iqentry_thrd[head1]] <= iqentry_res[head1];
					4'b1010:	dx[iqentry_thrd[head1]] <= iqentry_res[head1];
					4'b1011:	bx[iqentry_thrd[head1]] <= iqentry_res[head1];
					4'b1100:	sp[iqentry_thrd[head1]] <= iqentry_res[head1];
					4'b1101:	bp[iqentry_thrd[head1]] <= iqentry_res[head1];
					4'b1110:	si[iqentry_thrd[head1]] <= iqentry_res[head1];
					4'b1111:	di[iqentry_thrd[head1]] <= iqentry_res[head1];
					endcase

				// Write to segment register
				//
				if (iqentry_wrsregs[head1])
					case(iqentry_rrr[head1])
					3'd0:	es[iqentry_thrd[head1]] <= res[iqentry_thrd[head1]];
					3'd1:	cs[iqentry_thrd[head1]] <= res[iqentry_thrd[head1]];
					3'd2:	ss[iqentry_thrd[head1]] <= res[iqentry_thrd[head1]];
					3'd3:	ds[iqentry_thrd[head1]] <= res[iqentry_thrd[head1]];
					default:	;
					endcase
				if (iqentry_ftgt[head1][0])  cf[iqentry_thrd[head1]] <= iqentry_cf[head1];
				if (iqentry_ftgt[head1][1])  pf[iqentry_thrd[head1]] <= iqentry_pf[head1];
				if (iqentry_ftgt[head1][2])  af[iqentry_thrd[head1]] <= iqentry_af[head1];
				if (iqentry_ftgt[head1][3])  zf[iqentry_thrd[head1]] <= iqentry_zf[head1];
				if (iqentry_ftgt[head1][4])  sf[iqentry_thrd[head1]] <= iqentry_sf[head1];
				if (iqentry_ftgt[head1][5])  tf[iqentry_thrd[head1]] <= iqentry_tf[head1];
				if (iqentry_ftgt[head1][6])  iff[iqentry_thrd[head1]] <= iqentry_iff[head1];
				if (iqentry_ftgt[head1][7])  df[iqentry_thrd[head1]] <= iqentry_df[head1];
				if (iqentry_ftgt[head1][8])  of[iqentry_thrd[head1]] <= iqentry_of[head1];
				iqentry_val[head1] <= `INV;
				iqentry_done[head1] <= `INV;
				iqentry_state[head1] <= IFETCH;
				ip[iqentry_thrd[head1]] <= ip[iqentry_thrd[head1]] + iqentry_icnt[head1];
				head0 <= head0 + 3'd2;
				head1 <= head1 + 3'd2;
			end
		end
	EACALC:
		case(iqentry_mod[n])
		2'b00:
			begin
			case(iqentry_rm[n])
			3'b000:	iqentry_offset[n] <= bx[iqentry_thrd[n]] + si[iqentry_thrd[n]];
			3'b001:	iqentry_offset[n] <= bx[iqentry_thrd[n]] + di[iqentry_thrd[n]];
			3'b010: iqentry_offset[n] <= bp[iqentry_thrd[n]] + si[iqentry_thrd[n]];
			3'b011: iqentry_offset[n] <= bp[iqentry_thrd[n]] + di[iqentry_thrd[n]];
			3'b100:	iqentry_offset[n] <= si[iqentry_thrd[n]];
			3'b101:	iqentry_offset[n] <= di[iqentry_thrd[n]];
			3'b110: begin
						iqentry_offset[n] <= 16'h0000;
						iqentry_disp[n] <= iqentry_instr[15:0];
						iqentry_icnt[n] <= iqentry_icnt[n] + 4'd2;
					end
			3'b111: iqentry_offset[n] <= bx[iqentry_thrd[n]];
			endcase
			iqentry_state[n] <= EACALC1;
			end
		2'b01:
			begin
			case(iqentry_rm[n])
			3'b000:	iqentry_offset[n] <= bx[iqentry_thrd[n]] + si[iqentry_thrd[n]];
			3'b001:	iqentry_offset[n] <= bx[iqentry_thrd[n]] + di[iqentry_thrd[n]];
			3'b010: iqentry_offset[n] <= bp[iqentry_thrd[n]] + si[iqentry_thrd[n]];
			3'b011: iqentry_offset[n] <= bp[iqentry_thrd[n]] + di[iqentry_thrd[n]];
			3'b100:	iqentry_offset[n] <= si[iqentry_thrd[n]];
			3'b101:	iqentry_offset[n] <= di[iqentry_thrd[n]];
			3'b110: iqentry_offset[n] <= bp[iqentry_thrd[n]];
			3'b111: iqentry_offset[n] <= bx[iqentry_thrd[n]];
			endcase
			iqentry_disp16[n] <= {{8{iqentry_instr[n][7]}},iqentry_instr[n][7:0]};
			iqentry_instr[n] <= {`NOP,iqentry_instr[n][63:8]};
			iqentry_icnt[n] <= iqentry_icnt[n] + 4'd2;
			iqentry_state[n] <= EACALC1;
			end
		2'b10:
			begin
			case(iqentry_rm[n])
			3'b000:	iqentry_offset[n] <= bx[iqentry_thrd[n]] + si[iqentry_thrd[n]];
			3'b001:	iqentry_offset[n] <= bx[iqentry_thrd[n]] + di[iqentry_thrd[n]];
			3'b010: iqentry_offset[n] <= bp[iqentry_thrd[n]] + si[iqentry_thrd[n]];
			3'b011: iqentry_offset[n] <= bp[iqentry_thrd[n]] + di[iqentry_thrd[n]];
			3'b100:	iqentry_offset[n] <= si[iqentry_thrd[n]];
			3'b101:	iqentry_offset[n] <= di[iqentry_thrd[n]];
			3'b110: iqentry_offset[n] <= bp[iqentry_thrd[n]];
			3'b111: iqentry_offset[n] <= bx[iqentry_thrd[n]];
			endcase
			iqentry_disp16[n] <= iqentry_instr[n][15:0];
			iqentry_instr[n] <= {`NOP,`NOP,iqentry_instr[n][63:16]};
			iqentry_icnt[n] <= iqentry_icnt[n] + 4'd2;
			iqentry_state[n] <= EACALC1;
			end
		2'b11:
			begin
				iqentry_state[n] <= EXECUTE;
				case(iqentry_ir[n])
				`MOV_I8M:
					begin
						iqentry_rrr[n] <= iqentry_rm[n];
						if (iqentry_rrr[n]==3'd0) begin
							iqentry_b[n] <= iqentry_instr[n][7:0];
							iqentry_instr[n] <= {`NOP,iqentry_instr[n][63:8]};
							iqentry_icnt[n] <= iqentry_icnt[n] + 4'd1;
						end
					end
				`MOV_I16M:
					begin
						iqentry_rrr[n] <= iqentry_rm[n];
						if (iqentry_rrr[n]==3'd0) begin
							iqentry_b[n] <= iqentry_instr[n][15:0];
							iqentry_instr[n] <= {`NOP,`NOP,iqentry_instr[n][63:16]};
							iqentry_icnt[n] <= iqentry_icnt[n] + 4'd2;
						end
					end
				`MOV_S2R:
					begin
						iqentry_a[n] <= rfso(iqentry_seg3[n],iqentry_thrd[n]);
						iqentry_b[n] <= rfso(iqentry_seg3[n],iqentry_thrd[n]);
					end
				`MOV_R2S:
					begin
						iqentry_a[n] <= rmo(iqentry_w[n],iqentry_rm[n],iqentry_thrd[n]);
						iqentry_b[n] <= rmo(iqentry_w[n],iqentry_rm[n],iqentry_thrd[n]);
					end
				`POP_MEM:
					begin
						iqentry_ir[n] <= 8'h58|iqentry_rm[n];
						iqentry_state[n] <= POP;
					end
				`XCHG_MEM:
					begin
						wrregs <= 1'b1;
						iqentry_res[n] <= rmo(iqentry_w[n],iqentry_rm[n],iqentry_thrd[n]);
						iqentry_b[n] <= rrro(iqentry_w[n],iqentry_rm[n],iqentry_thrd[n]);
					end
				// shifts and rotates
				8'hD0,8'hD1,8'hD2,8'hD3:
					begin
						iqentry_b[n] <= rmo(iqentry_w[n],iqentry_rm[n],iqentry_thrd[n]);
					end
				// The TEST instruction is the only one needing to fetch an immediate value.
				8'hF6,8'hF7:
					// 000 = TEST
					// 010 = NOT
					// 011 = NEG
					// 100 = MUL
					// 101 = IMUL
					// 110 = DIV
					// 111 = IDIV
					if (iqentry_rrr[n]==3'b000) begin	// TEST
						iqentry_a[n] <= rmo(iqentry_w[n],iqentry_rm[n],iqentry_thrd[n]);
						iqentry_b[n] <= iqentry_w[n] ? iqentry_instr[15:0] : iqentry_instr[7:0];
						iqentry_instr[n] <= iqentry_w[n] ? {`NOP,`NOP,iqentry_instr[63:16]} : {`NOP,iqentry_instr[63:8]};
						iqentry_icnt[n] <= iqentry_icnt[n] + iqentry_w[n] ? 4'd2 : 4'd1;
					end
					else
						iqentry_b[n] <= rmo(iqentry_w[n],iqentry_rm[n],iqentry_thrd[n]);
				default:
				    begin
						if (d) begin
							iqentry_a[n] <= rmo(iqentry_w[n],iqentry_rm[n],iqentry_thrd[n]);
							iqentry_b[n] <= rrro(iqentry_w[n],iqentry_rm[n],iqentry_thrd[n]);
						end
						else begin
							iqentry_a[n] <= rrro(iqentry_w[n],iqentry_rm[n],iqentry_thrd[n]);
							iqentry_b[n] <= rmo(iqentry_w[n],iqentry_rm[n],iqentry_thrd[n]);
						end
					end
				endcase
				hasFetchedData <= 1'b1;
			end
		endcase
	EACALC1:
		begin
		casez(iqentry_ir[n])
		`EXTOP:
			casez(iqentry_ir2[n])
			8'h00:
				begin
					case(iqentry_rrr[n])
					3'b010: iqentry_state[n] <= FETCH_DESC;	// LLDT
					3'b011: iqentry_state[n] <= FETCH_DATA;	// LTR
					default: iqentry_state[n] <= FETCH_DATA;
					endcase
					if (iqentry_w[n] && (offsdisp==16'hFFFF)) begin
						iqentry_int[n] <= 8'h0d;
						iqentry_state[n] <= INT2;
					end
				end
			8'h01:
				begin
					case(iqentry_rrr[n])
					3'b010: iqentry_state[n] <= FETCH_DESC;
					3'b011: iqentry_state[n] <= FETCH_DESC;
					default: iqentry_state[n] <= FETCH_DATA;
					endcase
					if (iqentry_w[n] && (offsdisp==16'hFFFF)) begin
						iqentry_int[n] <= 8'h0d;
						iqentry_state[n] <= INT2;
					end
				end
			8'h03:
				if (iqentry_w[n] && (offsdisp==16'hFFFF)) begin
					iqentry_int[n] <= 8'h0d;
					iqentry_state[n] <= INT2;
				end
				else
					iqentry_state[n] <= FETCH_DATA;
			default:
				if (iqentry_w[n] && (offsdisp==16'hFFFF)) begin
					iqentry_int[n] <= 8'h0d;
					iqentry_state[n] <= INT2;
				end
				else
					iqentry_state[n] <= FETCH_DATA;
			endcase
		`MOV_I8M:
			begin
				iqentry_b[n] <= {8{iqentry_instr[7:0]}},iqentry_instr[7:0]};
				iqentry_instr[n] <= {`NOP,iqentry_instr[n][63:8]};
				iqentry_state[n] <= EXECUTE;
			end
		`MOV_I16M:
			if (iqentry_ip[n]==16'hFFFF) begin
				iqentry_int[n] <= 8'h0d;
				iqentry_state[n] <= INT2;
			end
			else begin
				iqentry_b[n] <= iqentry_instr[15:0];
				iqentry_instr[n] <= {`NOP,`NOP,iqentry_instr[n][63:16]};
				iqentry_state[n] <= EXECUTE;
			end
		`POP_MEM:
			begin
				iqentry_state[n] <= POP;
			end
		`XCHG_MEM:
			begin
//				bus_locked <= 1'b1;
				iqentry_state[n] <= FETCH_DATA;
			end
		8'b1000100?:	// Move to memory
			begin
				$display("EACALC1: state <= STORE_DATA");
				if (iqentry_w[n] && (offsdisp==16'hFFFF)) begin
					iqentry_int[n] <= 8'h0d;
					iqentry_state[n] <= INT2;
				end
				else begin	
					iqentry_res[n] <= rrro(iqentry_w[n],iqentry_rm[n],iqentry_thrd[n]);
					iqentry_state[n] <= STORE_DATA;
				end
			end
		default:
			begin
				$display("EACALC1: state <= FETCH_DATA");
				if (iqentry_w[n] && (offsdisp==16'hFFFF)) begin
					iqentry_int[n] <= 8'h0d;
					iqentry_state[n] <= INT2;
				end
				else
					iqentry_state[n] <= FETCH_DATA;
				if (iqentry_ir[n]==8'hff) begin
					case(iqentry_rrr[n])
					3'b011: iqentry_state[n] <= CALLF;	// CAll FAR indirect
					3'b101: iqentry_state[n] <= JUMP_VECTOR1;	// JMP FAR indirect
					3'b110:	begin iqentry_d[n] <= 1'b0; iqentry_state[n] <= FETCH_DATA; end// for a push
					default: ;
					endcase
				end
			end
		endcase
//		ea <= ea + disp16;
		iqentry_ea[n] <= {iqentry_seg[n],`SEG_SHIFT} + iqentry_offsdisp[n];	// offsdisp = offset + disp16
		end

	EXECUTE:
		casez(iqentry_ir[n])
		`EXTOP:
			casex(ir2)
			`LxDT: iqentry_state[n] <= FETCH_DESC;
			endcase

		`DAA:
			begin
				iqentry_state[n] <= IFETCH;
			end

		`ALU_I2R8,`ALU_I2R16,`ADD,`ADD_ALI8,`ADD_AXI16,`ADC,`ADC_ALI8,`ADC_AXI16:
			begin
				iqentry_state[n] <= WRITEBACK;
				iqentry_wrregs[n] <= 1'b1;
				iqentry_ftgt[n] <= 9'h11F;
			end

		`AND,`OR,`XOR,`AND_ALI8,`OR_ALI8,`XOR_ALI8,`AND_AXI16,`OR_AXI16,`XOR_AXI16:
			begin
				iqentry_state[n] <= WRITEBACK;
				iqentry_wrregs[n] <= 1'b1;
				iqentry_ftgt[n] <= 9'h11B;
			end

		`TEST:
			begin
				iqentry_state[n] <= WRITEBACK;
				iqentry_ftgt[n] <= 9'h11B;
			end

		`CMP,`CMP_ALI8,`CMP_AXI16:
			begin
				iqentry_state[n] <= WRITEBACK;
				iqentry_ftgt[n] <= 9'h11F;
			end

		`SBB,`SUB,`SBB_ALI8,`SUB_ALI8,`SBB_AXI16,`SUB_AXI16:
			begin
				iqentry_state[n] <= WRITEBACK;
				iqentry_wrregs[n] <= 1'b1;
				iqentry_ftgt[n] <= 9'h11F;
			end

		8'hF6,8'hF7:
			begin
				state <= IFETCH;
				case(TTT)
				3'd0:	// TEST
					begin
					end
				3'd2:	// NOT
					begin
						iqentry_wrregs[n] <= 1'b1;
					end
				3'd3:	// NEG
					begin
					end
				// Normally only a single register update is required, however with 
				// multiply word both AX and DX need to be updated. So we bypass the
				// regular update here.
				3'd4:
					begin
						if (iqentry_w[n]) begin
							ax <= p32[15:0];
							dx <= p32[31:16];
							iqentry_ftgt[n] <= 9'h101;
						end
						else begin
							ax <= p16;
							iqentry_ftgt[n] <= 9'h101;
						end
					end
				3'd5:
					begin
						if (w) begin
							ax <= wp[15:0];
							dx <= wp[31:16];
							iqentry_ftgt[n] <= 9'h101;
						end
						else begin
							ax <= p;
							iqentry_ftgt[n] <= 9'h101;
						end
					end
				3'd6,3'd7:
					begin
						$display("state <= DIVIDE1");
						state <= DIVIDE1;
					end
				default:	;
				endcase
			end

		`INC_REG,`DEC_REG:
			begin
				iqentry_state[n] <= WRITEBACK;
				iqentry_wrregs[n] <= 1'b1;
				iqentry_ftgt[n] <= 9'h11E;
				iqentry_w[n] <= 1'b1;
			end
//		`IMUL:
//			begin
//				state <= IFETCH;
//				wrregs <= 1'b1;
//				w <= 1'b1;
//				rrr <= 3'd0;
//				res <= alu_o;
//				if (w) begin
//					cf <= wp[31:16]!={16{resnw}};
//					vf <= wp[31:16]!={16{resnw}};
//					dx <= wp[31:16];
//				end
//				else begin
//					cf <= ah!={8{resnb}};
//					vf <= ah!={8{resnb}};
//				end
//			end

		//-----------------------------------------------------------------
		// Memory Operations
		//-----------------------------------------------------------------
			
		// registers not allowed on LEA
		// invalid opcode
		//
		`LEA:
			begin
				iqentry_w[n] <= 1'b1;
				iqentry_res[n] <= iqentry_ea[n];
				iqentry_wrregs[n] <= 1'b1;
				if (iqentry_mod[n]==2'b11) begin
					iqentry_int[n] <= 8'h06;
					iqentry_state[n] <= INT;
				end
				else begin
					iqentry_state[n] <= WRITEBACK;
				end
			end
		`LDS:
			begin
				iqentry_rrr[n] <= 3'd3;
				iqentry_wrsregs[n] <= 1'b1;
				res <= alu_o;
				iqentry_state[n] <= WRITEBACK;
			end
		`LES:
			begin
				iqentry_rrr[n] <= 3'd0;
				wrsregs <= 1'b1;
				res <= alu_o;
				iqentry_state[n] <= WRITEBACK;
			end

		`MOV_RR8,`MOV_RR16,
		`MOV_MR,
		`MOV_M2AL,`MOV_M2AX:
			begin
				iqentry_state[n] <= WRITEBACK;
				iqentry_wrregs[n] <= 1'b1;
				res <= alu_o;
			end
		`XCHG_MEM:
			begin
				wrregs <= 1'b1;
				if (mod==2'b11) rrr <= rm;
				res <= alu_o;
				b <= rrro;
				state <= mod==2'b11 ? IFETCH : XCHG_MEM;
			end
		`MOV_I8M,`MOV_I16M:
			begin
				res <= alu_o;
				state <= rrr==3'd0 ? STORE_DATA : INVALID_OPCODE;
			end

		`MOV_S2R:
			begin
				w <= 1'b1;
				rrr <= rm;
				res <= b;
				if (mod==2'b11) begin
					state <= IFETCH;
					wrregs <= 1'b1;
				end
				else
					state <= STORE_DATA;
			end
		`MOV_R2S:
			begin
				wrsregs <= 1'b1;
				res <= alu_o;
				state <= IFETCH;
			end

		`LODSB:
			begin
				state <= IFETCH;
				wrregs <= 1'b1;
				w <= 1'b0;
				rrr <= 3'd0;
				res <= a[7:0];
				if ( df) si <= si_dec;
				if (!df) si <= si_inc;
			end
		`LODSW:
			begin
				state <= IFETCH;
				wrregs <= 1'b1;
				w <= 1'b1;
				rrr <= 3'd0;
				res <= a;
				if ( df) si <= si - 16'd2;
				if (!df) si <= si + 16'd2;
			end

		8'hD0,8'hD1,8'hD2,8'hD3,8'hC0,8'hC1:
			begin
				state <= IFETCH;
				wrregs <= 1'b1;
				rrr <= rm;
				if (w)
					case(rrr)
					3'b000:	// ROL
						begin
							res <= shlo[15:0]|shlo[31:16];
							cf <= bmsb;
							vf <= bmsb^b[14];
						end
					3'b001:	// ROR
						begin
							res <= shruo[15:0]|shruo[31:16];
							cf <= b[0];
							vf <= cf^b[15];
						end
					3'b010:	// RCL
						begin
							res <= shlco[16:1]|shlco[32:17];
							cf <= b[15];
							vf <= b[15]^b[14];
						end
					3'b011:	// RCR
						begin
							res <= shrcuo[15:0]|shrcuo[31:16];
							cf <= b[0];
							vf <= cf^b[15];
						end
					3'b100:	// SHL
						begin
							res <= shlo[15:0];
							cf <= shlo[16];
							vf <= b[15]^b[14];
						end
					3'b101:	// SHR
						begin
							res <= shruo[31:16];
							cf <= shruo[15];
							vf <= b[15];
						end
					3'b111:	// SAR
						begin
							res <= shro;
							cf <= b[0];
							vf <= 1'b0;
						end
					endcase
				else
					case(rrr)
					3'b000:	// ROL
						begin
							res <= shlo8[7:0]|shlo8[15:8];
							cf <= b[7];
							vf <= b[7]^b[6];
						end
					3'b001:	// ROR
						begin
							res <= shruo8[15:8]|shruo8[7:0];
							cf <= b[0];
							vf <= cf^b[7];
						end
					3'b010:	// RCL
						begin
							res <= shlco8[8:1]|shlco8[16:9];
							cf <= b[7];
							vf <= b[7]^b[6];
						end
					3'b011:	// RCR
						begin
							res <= shrcuo8[15:8]|shrcuo8[7:0];
							cf <= b[0];
							vf <= cf^b[7];
						end
					3'b100:	// SHL
						begin
							res <= shlo8[7:0];
							cf <= shlo8[8];
							vf <= b[7]^b[6];
						end
					3'b101:	// SHR
						begin
							res <= shruo8[15:8];
							cf <= shruo8[7];
							vf <= b[7];
						end
					3'b111:	// SAR
						begin
							res <= shro8;
							cf <= b[0];
							vf <= 1'b0;
						end
					endcase
			end

		//-----------------------------------------------------------------
		//-----------------------------------------------------------------
		`GRPFF:
			begin
				case(iqentry_rrr[n])
				3'b000,3'b001:	// INC / DEC
					begin
						iqentry_state[n] <= WRITEBACK;
						iqentry_wrregs[n] <= 1'b1;
						iqentry_ftgt[n] <= 9'h11E;
						iqentry_w[n] <= 1'b1;
						iqentry_rrr[n] <= iqentry_rm[n];
					end
				3'b010:	begin sp <= sp_dec; state <= CALL_IN; end
				// These two should not be reachable here, as they would
				// be trapped by the EACALC.
				3'b011:	state <= CALL_FIN;	// CALL FAR indirect
				3'b101:	// JMP FAR indirect
					begin
						ip <= offset;
						cs <= selector;
						state <= IFETCH;
					end
				3'b110:	begin sp <= sp_dec; state <= PUSH; end
				default:
					begin
						iqentry_ftgt[n] <= 9'h104;
						iqentry_state[n] <= WRITEBACK;
					end
				endcase
			end

		//-----------------------------------------------------------------
		//-----------------------------------------------------------------
		default:
			iqentry_state[n] <= IFETCH;
		endcase
	end
	endcase
	
	// Memory Machine
	begin
		case(mem_state)
		IDLE:
			for (n = 0; n < QENTRIES; n = n + 1) begin
				if (iqentry_v[n])
					case(iqentry_state[n])
					FETCH_DATA:
						begin
							mem_state <= ACK1;
							mem_id <= n;
							lock_o <= iqentry_buslock[n] | iqentry_w[n];
							cyc_o <= `HIGH;
							stb_o <= `HIGH;
							sel_o <= 2'b11;
							adr_o <= iqentry_ea[n];
						end
					RET:
						begin
							mem_state <= RET_ACK1;
							mem_id <= n;
							lock_o <= `HIGH;
							cyc_o <= `HIGH;
							stb_o <= `HIGH;
							sel_o <= 2'b11;
							adr_o <= {ss[iqentry_thrd[n]],`SEG_SHIFT} + sp[iqentry_thrd[n]];
						end
					XLAT:
						begin
							mem_state <= XLAT_ACK;
							mem_id <= n;
							cyc_o <= `HIGH;
							stb_o <= `HIGH;
							sel_o <= 2'b11;
							adr_o <= iqentry_ea[iqentry_thrd[n]];
						end
					endcase
			end
		XLAT_ACK:
			if (ack_i) begin
				cyc_o <= `LOW;
				stb_o <= `LOW;
				iqentry_res[mem_id] <= {8'h00,dat_i};
				iqentry_state[mem_id] <= WRITEBACK;
				mem_state <= XLAT_NACK;
			end
		XLAT_NACK:
			if (~ack_i) begin
				mem_state <= IDLE;
			end
		ACK1:
			if (ack_i) begin
				mem_state <= NACK1;
				cyc_o <= iqentry_w[mem_id];
				stb_o <= `LOW;
				if (iqentry_d[mem_id]) begin
					iqentry_a[mem_id] <= rrro(iqentry_w[mem_id],iqentry_rm[mem_id],iqentry_thrd[mem_id]);
					iqentry_b[mem_id][ 7:0] <= dat_i;
					iqentry_b[mem_id][15:8] <= {8{dat_i[7]}};
				end
				else begin
					iqentry_b[mem_id] <= rrro(iqentry_w[mem_id],iqentry_rm[mem_id],iqentry_thrd[mem_id]);
					iqentry_a[mem_id][ 7:0] <= dat_i;
					iqentry_a[mem_id][15:8] <= {8{dat_i[7]}};
				end
				if (!iqentry_w[mem_id])
				begin
					case(ir)
					8'h80,8'h83,8'hC0,8'hC1,8'hC6,8'hF6:
						begin
							iqentry_b[mem_id] <= iqentry_instr[mem_id][7:0];
							iqentry_instr[mem_id] <= {`NOP,iqentry_instr[mem_id][63:8]};
							iqentry_icnt[n] <= iqentry_icnt[n] + 4'd1;
							iqentry_state[mem_id] <= EXECUTE;
						end
					8'h81,8'hC7,8'hF7:
						begin
							iqentry_b[mem_id] <= iqentry_instr[mem_id][15:0];
							iqentry_instr[mem_id] <= {`NOP,`NOP,iqentry_instr[mem_id][63:16]};
							iqentry_icnt[n] <= iqentry_icnt[n] + 4'd2;
							iqentry_state[mem_id] <= EXECUTE;
						end
					default: iqentry_state[mem_id] <= EXECUTE;
					endcase
					hasFetchedData <= 1'b1;
				end
			end
		NACK1:
			if (~ack_i) begin
				if (iqentry_w[mem_id])
					mem_state <= CYC2;
				else
					mem_state <= IDLE;
			end
		CYC2:
			begin
				mem_state <= ACK2;
				lock_o <= iqentry_buslock[mem_id] | iqentry_w[mem_id];
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				sel_o <= 2'b11;
				adr_o <= iqentry_ea[n] + 20'd1;
			end
		ACK2:
			if (ack_i) begin
				mem_state <= NACK2;
				lock_o <= iqentry_buslock[mem_id];
				cyc_o <= 1'b0;
				stb_o <= 1'b0;
				if (iqentry_d[mem_id])
					iqentry_b[mem_id][15:8] <= dat_i;
				else
					iqentry_a[mem_id][15:8] <= dat_i;
				case(ir)
				8'h80,8'h83,8'hC0,8'hC1,8'hC6,8'hF6:
					begin
						iqentry_b[mem_id] <= iqentry_instr[mem_id][7:0];
						iqentry_instr[mem_id] <= {`NOP,iqentry_instr[mem_id][63:8]};
						iqentry_icnt[n] <= iqentry_icnt[n] + 4'd1;
						iqentry_state[mem_id] <= EXECUTE;
					end
				8'h81,8'hC7,8'hF7:
					begin
						iqentry_b[mem_id] <= iqentry_instr[mem_id][15:0];
						iqentry_instr[mem_id] <= {`NOP,`NOP,iqentry_instr[mem_id][63:16]};
						iqentry_icnt[n] <= iqentry_icnt[n] + 4'd2;
						iqentry_state[mem_id] <= EXECUTE;
					end
				default: iqentry_state[mem_id] <= EXECUTE;
				endcase
			end
		NACK2:
			if (~ack_i) begin
				mem_state <= IDLE;
			end

		RET_ACK1:
			if (ack_i) begin
				mem_state <= RET_NACK1;
				stb_o <= `LOW;
				ip[iqentry_thrd[mem_id]][7:0] <= dat_i;
				iqentry_icnt[mem_id] <= 4'd0;	// probably not needed
			end
		RET_NACK1:
			if (~ack_i) begin
				stb_o <= `HIGH;
				adr_o <= adr_o + 20'd1;
				mem_state <= RET_ACK2;
			end
		RET_ACK2:
			if (ack_i) begin
				mem_state <= RET_NACK2;
				if (iqentry_ir[mem_id]]!=`RETF || iqentry_ir[mem_id]]!=`RETFPOP) begin
					lock_o <= `LOW;
					cyc_o <= `LOW;
				end
				stb_o <= `LOW;
				ip[iqentry_thrd[mem_id]][15:8] <= dat_i;
			end
		RET_NACK2:
			if (~ack_i) begin
				if (iqentry_ir[mem_id]]==`RETF || iqentry_ir[mem_id]]==`RETFPOP) begin
					stb_o <= `HIGH;
					adr_o <= adr_o + 20'd1;
					mem_state <= RETF_ACK1;
				end
				else begin	// near return finished
					mem_state <= IDLE;
					iqentry_state[mem_id] <= IFETCH;
					iqentry_val[mem_id] <= `INV;
				end
				if (iqentry_ir[mem_id]==`RETPOP || iqentry_ir[mem_id]]==`RETFPOP)
					sp[iqentry_thrd[mem_id]] <= sp[iqentry_thrd[mem_id]] + iqentry_instr[15:0];
			end
		RETF_ACK1:
			if (ack_i) begin
				mem_state <= RETF_NACK1;
				stb_o <= `LOW;
				cs[iqentry_thrd[mem_id]][7:0] <= dat_i;
			end
		RETF_NACK1:
			if (~ack_i) begin
				stb_o <= `HIGH;
				adr_o <= adr_o + 20'd1;
				mem_state <= RETF_ACK2;
			end
		RETF_ACK2:
			if (ack_i) begin
				mem_state <= RETF_NACK2;
				lock_o <= `LOW;
				cyc_o <= `LOW;
				stb_o <= `LOW;
				cs[iqentry_thrd[mem_id]][15:8] <= dat_i;
			end
		RETF_NACK2:
			if (~ack_i) begin
				mem_state <= IDLE;
				iqentry_state[mem_id] <= IFETCH;
				iqentry_val[mem_id] <= `INV;
			end

		endcase
	end

	if (alu0_v) begin
		iqentry_res[alu0_id] <= alu0_o;
		iqentry_pf[alu0_id] <= alu0_pf_o;
		iqentry_af[alu0_id] <= alu0_af_o;
		iqentry_cf[alu0_id] <= alu0_cf_o;
		iqentry_vf[alu0_id] <= alu0_vf_o;
		iqentry_sf[alu0_id] <= alu0_sf_o;
		iqentry_zf[alu0_id] <= alu0_zf_o;
		iqentry_state[alu0_id] <= EXECUTE;
	end
	
	if (fcu0_state==BUSY) begin
		fcu0_state <= IDLE;
		if (fcu0_takb) begin
			iqentry_icnt[fcu0_id] <= 0;
			ip[iqentry_thrd[fcu0_id]] <= ip[iqentry_thrd[fcu0_id]] + {{8{iqentry_instr[fcu0_id][7]}},iqentry_instr[fcu0_id][7:0]};
		end
		else
			iqentry_icnt[fcu0_id] <= iqentry_icnt[fcu0_id] + 4'd1;
		iqentry_done[fcu0_id] <= `TRUE;
		iqentry_state[fcu0_id] <= WRITEBACK;
	end

	if (fcu1_state==BUSY) begin
		fcu1_state <= IDLE;
		if (fcu1_takb) begin
			iqentry_icnt[fcu1_id] <= 0;
			ip[iqentry_thrd[fcu1_id]] <= ip[iqentry_thrd[fcu1_id]] + {{8{iqentry_instr[fcu1_id][7]}},iqentry_instr[fcu1_id][7:0]};
		end
		else
			iqentry_icnt[fcu1_id] <= iqentry_icnt[fcu1_id] + 4'd1;
		iqentry_done[fcu1_id] <= `TRUE;
		iqentry_state[fcu1_id] <= WRITEBACK;
	end

	// Execute Instruction
	for (n = 0; n < QENTRIES; n = n + 1)
	if (iqentry_state[n]==EXECUTE) begin

	end

end
	
endmodule

