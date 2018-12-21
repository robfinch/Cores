

module FT64v8(rst_i, clk_i);
input rst_i;
input clk_i;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
// Register file states
parameter AR = 2'b00;			// Architectural register
parameter AV = 2'b01;			// Available
parameter RBNV= 2'b10;		// Rename buffer - not valid
parameter RBV = 2'b11;		// Rename buffer - valid

parameter QENTRIES = 64;
parameter ROB_ENTRIES = 64;

integer n;

reg [63:0] ol_stack;
wire [1:0] ol = ol_stack[1:0];

reg [31:0] sreg_in_use [7:0];

reg [7:0] cregfile [0:15];				// condition code registers
reg [1:0] cregfile_state [0:15];
reg [279:0] sregfile [0:31];		// segment registers
reg [1:0] sregfile_state [0:31];
reg [63:0] aregfile [0:63];			// address registers including code address
reg [1:0] aregfile_state [0:63];
reg [63:0] dregfile [0:63];
reg [1:0] dregfile_state [0:63];

reg [23:0] desc_selector [0:63];
reg [255:0] desc_cache [0:63];
reg [63:0] desc_cache_v;
reg [5:0] desc_cache_ndx;
reg [1:0] desc_cnt;

reg [3:0] insn_lengths [0:255];
reg [255:0] microcode [0:255];

wire [63:0] insn0 = insn[63:0];

reg sregfile_wr0;
reg [4:0] sregfile_tgt0;
reg [279:0] sregfile_in0;

function [7:0] fnRa;
input [63:0] insn;
case(insn[7:0])
`ADD,`SUB,`CMP,`MUL,`DIV:
	fnRa = insn[12:8];
`AND,`OR,`XOR,`NAND,`NOR,`XNOR:
	fnRa = insn[12:8];
default:
	fnRa = 8'h00;
endcase
endfunction

function Source1Valid;
input [7:0] opcode;
case(opcode)
endcase
endfunction

function Source2Valid;
input [7:0] opcode;
case(opcode)
`ADDI,`CMPI,
`ANDI,`ORI,`XORI,`XNORI,
`ADDI30,`CMPI30,
`ANDI30,`ORI30,`XORI30,`XNORI30:
	Source2Valid = TRUE;
endcase
endfunction

reg [63:0] iq0_pc [0:QENTRIES-1];
reg [63:0] iq0_insn [0:QENTRIES-1];

reg [ROB_ENTRIES-1:0] rob_s1v;
reg [ROB_ENTRIES-1:0] rob_s2v;
reg [ROB_ENTRIES-1:0] rob_s3v;
reg [ROB_ENTRIES-1:0] rob_s4v;
reg [7:0] rob_tgt [0:ROB_ENTRIES-1];
reg [7:0] rob_fre [0:ROB_ENTRIES-1];

always @(posedge clk_i) begin
	insn1 <= insn >> {insn_lengths[insn0[7:0]],3'b0};
	insn1_pc <= pc0 + insn_lengths[insn0[7:0]];
	insn0d1 <= insn0;
	insn0d1_pc <= pc0;
end
always @(posedge clk_i) begin
	insn2 <= insn1 >> {insn_lengths[insn1[7:0]],3'b0};
	insn2_pc <= insn1_pc + insn_lengths[insn1[7:0]];
	insn1d1 <= insn1;
	insn1d1_pc <= insn1_pc;
	insn0d2 <= insn0d1;
	insn0d2_pc <= insn0d1_pc;
end
always @(posedge clk_i) begin
	insn3 <= insn2 >> {insn_lengths[insn2[7:0]],3'b0};
	insn3_pc <= insn2_pc + insn_lengths[insn2[7:0]];
	insn2d1 <= insn2;
	insn2d1_pc <= insn2_pc;
	insn1d2 <= insn1d1;
	insn1d2_pc <= insn1d1_pc;
	insn0d3 <= insn0d2;
	insn0d3_pc <= insn0d2_pc;
end

vtdl #(.WID(64), .DEP(64)) uiq_pc0(clk_i, 1'b1, a, insn0d3_pc, ins0_pc);
vtdl #(.WID(64), .DEP(64)) uiq_pc1(clk_i, 1'b1, a, insn1d2_pc, ins1_pc);
vtdl #(.WID(64), .DEP(64)) uiq_pc2(clk_i, 1'b1, a, insn2d1_pc, ins2_pc);
vtdl #(.WID(64), .DEP(64)) uiq_pc3(clk_i, 1'b1, a, insn3_pc,   ins3_pc);

vtdl #(.WID(64), .DEP(64)) uiq_insn0(clk_i, 1'b1, a, insn0d3, ins0);
vtdl #(.WID(64), .DEP(64)) uiq_insn1(clk_i, 1'b1, a, insn1d2, ins1);
vtdl #(.WID(64), .DEP(64)) uiq_insn2(clk_i, 1'b1, a, insn2d1, ins2);
vtdl #(.WID(64), .DEP(64)) uiq_insn3(clk_i, 1'b1, a, insn3,   ins3);

reg [63:0] ara;		// address register available
always @*
for (n = 0; n < 64; n = n + 1)
	ara[n] <= aregfile_state[n]==AV;

wire [63:0] ara0 = {ara[63:1],1'b0};
wire [63:0] ara1 = {ara[47:1],1'b0,ara[63:48]};
wire [63:0] ara2 = {ara[31:1],1'b0,ara[63:32]};
wire [63:0] ara3 = {ara[15:1],1'b0,ara[63:16]};

reg [63:0] dra;		// data register available
always @*
for (n = 0; n < 64; n = n + 1)
	dra[n] <= dregfile_state[n]==AV;

wire [63:0] dra0 = {dra[63:1],1'b0};
wire [63:0] dra1 = {dra[47:1],1'b0,dra[63:48]};
wire [63:0] dra2 = {dra[31:1],1'b0,dra[63:32]};
wire [63:0] dra3 = {dra[15:1],1'b0,dra[63:16]};

reg [31:0] sra;		// segment register available
always @*
for (n = 0; n < 32; n = n + 1)
	sra[n] <= sregfile_state[n]==AV;

wire [31:0] sra0 = sra;
wire [31:0] sra1 = {sra[23:0],sra[31:24]};
wire [31:0] sra2 = {sra[15:0],sra[31:16]};
wire [31:0] sra3 = {sra[ 7:0],sra[31: 8]};

reg [15:0] cra;	// condition register available
always @*
for (n = 0; n < 16; n = n + 1)
	cra[n] <= cregfile_state[n]==AV;
ffo16 uffz16 (cra,Crt);

ffo32 uffz320 (sra0,Srt0);
ffo32 uffz321 (sra1,Srt1);
ffo32 uffz322 (sra2,Srt2);
ffo32 uffz323 (sra3,Srt3);

wire [7:0] ffzo,flzo;
ffo256 uffz0(riu0,Rt0);
ffo256 uffz1(riu1,Rt1);
ffo256 uffz2(riu2,Rt2);
ffo256 uffz3(riu3,Rt3);

wire [4:0] Sn0 = srename_map[map_ndx][fnSn(fetchbuf0_instr)];
wire [4:0] Sn1 = srename_map[map_ndx][fnSn(fetchbuf1_instr)];
wire [4:0] Sn2 = srename_map[map_ndx][fnSn(fetchbuf2_instr)];
wire [4:0] Sn3 = srename_map[map_ndx][fnSn(fetchbuf3_instr)];
wire [4:0] oSt0 = srename_map[map_ndx][fnSt(fetchbuf0_instr)];
wire [4:0] oSt1 = srename_map[map_ndx][fnSt(fetchbuf1_instr)];
wire [4:0] oSt2 = srename_map[map_ndx][fnSt(fetchbuf2_instr)];
wire [4:0] oSt3 = srename_map[map_ndx][fnSt(fetchbuf3_instr)];

wire [5:0] Aa0 = arename_map[map_ndx][fnAa(fetchbuf0_instr)];
wire [5:0] Ab0 = arename_map[map_ndx][fnAb(fetchbuf0_instr)];
wire [5:0] oAt0 = arename_map[map_ndx][fnAt(fetchbuf0_instr)];
wire [5:0] Aa1 = arename_map[map_ndx][fnAa(fetchbuf1_instr)];
wire [5:0] Ab1 = arename_map[map_ndx][fnAb(fetchbuf1_instr)];
wire [5:0] oAt1 = arename_map[map_ndx][fnAt(fetchbuf1_instr)];
wire [5:0] Aa2 = arename_map[map_ndx][fnAa(fetchbuf2_instr)];
wire [5:0] Ab2 = arename_map[map_ndx][fnAb(fetchbuf2_instr)];
wire [5:0] oAt2 = arename_map[map_ndx][fnAt(fetchbuf2_instr)];
wire [5:0] Aa3 = arename_map[map_ndx][fnAa(fetchbuf3_instr)];
wire [5:0] Ab3 = arename_map[map_ndx][fnAb(fetchbuf3_instr)];
wire [5:0] oAt3 = arename_map[map_ndx][fnAt(fetchbuf3_instr)];

wire [7:0] Ra0 = rename_map[map_ndx][fnRa(fetchbuf0_instr)];
wire [7:0] Rb0 = rename_map[map_ndx][fnRb(fetchbuf0_instr)];
wire [7:0] Rc0 = rename_map[map_ndx][fnRc(fetchbuf0_instr)];
wire [7:0] oRt0 = rename_map[map_ndx][fnRt(fetchbuf0_instr)];
wire [7:0] Ra1 = rename_map[map_ndx][fnRa(fetchbuf1_instr)];
wire [7:0] Rb1 = rename_map[map_ndx][fnRb(fetchbuf1_instr)];
wire [7:0] Rc1 = rename_map[map_ndx][fnRc(fetchbuf1_instr)];
wire [7:0] oRt1 = rename_map[map_ndx][fnRt(fetchbuf1_instr)];
wire [7:0] Ra2 = rename_map[map_ndx][fnRa(fetchbuf2_instr)];
wire [7:0] Rb2 = rename_map[map_ndx][fnRb(fetchbuf2_instr)];
wire [7:0] Rc2 = rename_map[map_ndx][fnRc(fetchbuf2_instr)];
wire [7:0] oRt2 = rename_map[map_ndx][fnRt(fetchbuf2_instr)];
wire [7:0] Ra3 = rename_map[map_ndx][fnRa(fetchbuf3_instr)];
wire [7:0] Rb3 = rename_map[map_ndx][fnRb(fetchbuf3_instr)];
wire [7:0] Rc3 = rename_map[map_ndx][fnRc(fetchbuf3_instr)];
wire [7:0] oRt3 = rename_map[map_ndx][fnRt(fetchbuf3_instr)];


reg [23:0] bitcmp_instr;
reg [1:0] bitcmp_opcls;
reg [3:0] bitcmp_tgt;
reg [7:0] bitcmp_res;
reg [63:0] bitcmp_opa;
reg bitcmp_opav;
reg [63:0] bitcmp_opb;
reg bitcmp_opbv;
reg [63:0] bitcmp_opi;
reg [63:0] bitcmp_tmp;

always @*
	bitcmp_tmp <= bitcmp_opa - bitcmp_opb;

always @(posedge clk)
begin
	case(bitcmp_instr[7:0])
	`BIT:
		begin
			bitcmp_res[0] <= !bitcmp_opa[bitcmp_instr[23:18]];
			bitcmp_res[1] <=  bitcmp_opa[63];
			bitcmp_res[2] <=  1'b0;	// V
			bitcmp_res[3] <= 	1'b0;	// C
			bitcmp_res[4] <=  bitcmp_opa[0];	// O
			bitcmp_res[5] <= ^bitcmp_opa;			// P
			bitcmp_res[6] <=  1'b0;
			bitcmp_res[7] <=  1'b0;
		end
	`CMP:
		begin
			bitcmp_res[0] <= bitcmp_tmp==64'd0;
			bitcmp_res[1] <= bitcmp_tmp[63];
			bitcmp_res[2] <= 1'b0;
			bitcmp_res[3] <= 1'b0;
			bitcmp_res[4] <= bitcmp_tmp[0];
			bitcmp_res[5] <= ^bitcmp_tmp;
			bitcmp_res[6] <=  1'b0;
			bitcmp_res[7] <=  1'b0;
		end
	endcase	
end

always @(posedge clk)
begin
end


always @(posedge clk)
if (rst) begin
	// Condition code registers
	for (n = 0; n < 16; n = n + 1)
		if (n < 8)
			cregfile_state[n] <= AR;
		else
			cregfile_state[n] <= AV;
	// Address registers (code and data)
	for (n = 0; n < 64; n = n + 1)
		if (n < 32)
			aregfile_state[n] <= AR;
		else
			aregfile_state[n] <= AV;
	// Data registers
	for (n = 0; n < 64; n = n + 1)
		if (n < 32)
			dregfile_state[n] <= AR;
		else
			dregfile_state[n] <= AV;
	// Segment registers
	for (n = 0; n < 32; n = n + 1)
		if (n < 14)
			sregfile_state[n] <= AR;
		else
			sregfile_state[n] <= AV;
end
else begin
	sregfile_wr0 <= `FALSE;
	sregfile_wr1 <= `FALSE;

	if (sregfile_wr0) begin
		sregfile[sregfile_tgt0] <= sregfile_in0;
		if (sregfile_state[sregfile_tgt0]==`RBNV)
			sregfile_state[sregfile_tgt0] <= `RBV;
	end

case(opcode)
`MOVS:
	begin
		if (sregfile_state[Sn0]==`AR || sregfile_state[Sn0]==`RBV) begin
			sregfile_in0 <= sregfile[Sn0];
			sregfile_tgt0 <= St0;
			sregfile_wr0 <= `TRUE;
		end
	end
endcase

reg cmp_x;
reg [47:0] cmp_instr;
reg cmp_xn1v;
reg cmp_xn2v;
reg [63:0] cmp_xn1;
reg [63:0] cmp_xn2;
reg [63:0] cmp_const;
reg [63:0] cmp_xdiff;
reg [63:0] cmp_xidiff;
reg [7:0] cmp_res;

if (!cmp_xn1v && cmp_xn1[5] && aregfile_tgt0==cmp_xn1[4:0] && aregfile_wr0)
begin
	cmp_xn1 <= aregfile_in0;
	cmp_xn1v <= `TRUE;
end
if (!cmp_xn1v && !cmp_xn1[5] && dregfile_tgt0==cmp_xn1[4:0] && dregfile_wr0)
begin
	cmp_xn1 <= dregfile_in0;
	cmp_xn1v <= `TRUE;
end
if (!cmp_xn1v && cmp_xn1[5] && aregfile_tgt1==cmp_xn1[4:0] && aregfile_wr1)
begin
	cmp_xn1 <= aregfile_in1;
	cmp_xn1v <= `TRUE;
end
if (!cmp_xn2v && cmp_xn2[5] && aregfile_tgt0==cmp_xn2[4:0] && aregfile_wr0)
begin
	cmp_xn2 <= aregfile_in0;
	cmp_xn2v <= `TRUE;
end
if (!cmp_xn2v && cmp_xn2[5] && aregfile_tgt1==cmp_xn2[4:0] && aregfile_wr1)
begin
	cmp_xn2 <= aregfile_in1;
	cmp_xn2v <= `TRUE;
end

cmp_x <= cmp_xn1v & cmp_xn2v & ~cmp_v;
cmp_xdiff <= cmp_xn1 - cmp_cn2;
cmp_xidiff <= cmp_xn1 - cmp_const;
always @(posedge clk)
case(cmp_instr[7:0])
`CMP:
	begin
		cmp_res[0] <= cmp_xdiff==64'd0;
		cmp_res[1] <= cmp_xdiff[63];
	end
endcase

reg aguA_x,aguA_x1,aguA_x2,aguA_x3;
reg [47:0] aguA_instr;
reg aguA_anv;
reg aguA_segv;
reg aguA_xnv;
reg aguA_dispv;
reg [2:0] aguA_scale;
reg [100:0] aguA_base,aguA_base2,aguA_base3;
reg [63:0] aguA_lower,aguA_lower1,aguA_lower2,aguA_lower3;
reg [63:0] aguA_upper,aguA_upper1,aguA_upper2,aguA_upper3;
reg [63:0] aguA_an,aguA_an1;
reg [63:0] aguA_xn,aguA_xn1,aguA_xn2;
reg [63:0] aguA_disp,aguA_disp1;

// When the instruction is issued to the AGU
if (!aguA_segv) begin
	if (sregfile_state[SnA]==`AR || sregfile_state[SnA]==`RBV) begin
		aguA_base <= {sregfile[SnA][223:192],sregfile[SnA][63:0]};
		aguA_lower <= sregfile[SnA][127:64];
		aguA_upper <= sregfile[SnA][191:128];
		aguA_segv <= `TRUE;
		srename_map[map_ndx][SnA][`REFCNT] <= srename_map[map_ndx][SnA][`REFCNT] - 2'd1;
	end
	else if (sregfile_state[SnA]==`RBNV) begin
		aguA_base[4:0] <= SnA;
		aguA_segv <= `FALSE;
	end
end

// On an update to a segment register, see if a value can be latched into the
// AGU's segment argument.
if (aguA_base[4:0]==sregfile_tgt0 && sregfile_wr0 && !aguA_segv) begin
	aguA_base <= {sregfile_in0[223:192],sregfile_in0[63:0]};
	aguA_lower <= sregfile_in0[127:64];
	aguA_upper <= sregfile_in0[191:128];
	aguA_segv <= `TRUE;
	srename_map[map_ndx][sregfile_tgt0][`REFCNT] <= srename_map[map_ndx][sregfile_tgt0][`REFCNT] - 2'd1;
end

reg [6:0] desc_match;

begin
	if (desc_selector[{2'b00,aguA_selector[3:0]}]==aguA_selector && desc_cache_v[{2'b00,aguA_selector[3:0]}])
		desc_match <= {2'b00,aguA_selector[3:0]};
	else if (desc_selector[{2'b01,aguA_selector[3:0]}]==aguA_selector && desc_cache_v[{2'b01,aguA_selector[3:0]}])
		desc_match <= {2'b01,aguA_selector[3:0]};
	else if (desc_selector[{2'b10,aguA_selector[3:0]}]==aguA_selector && desc_cache_v[{2'b10,aguA_selector[3:0]}])
		desc_match <= {2'b10,aguA_selector[3:0]};
	else if (desc_selector[{2'b11,aguA_selector[3:0]}]==aguA_selector && desc_cache_v[{2'b11,aguA_selector[3:0]}])
		desc_match <= {2'b11,aguA_selector[3:0]};
	else
		desc_match <= 7'h40;
end
if (!desc_match[6]) begin
	desc_ndx <= desc_match[5:0];
	desc_in <= desc_cache[desc_match[5:0]];
end


reg aguA_x <= aguA_anv & aguA_basev & aguA_xnv & aguA_dispv & ~aguA_v;
// AGU
if (aguA_x) begin
	// Cycle1 get scale and displacement
	case(aguA_instr[7:0])
	`LB,`LD:	aguA_scale <= aguA_instr[26:24];
	`LDIS,`MOV2SEG:	aguA_scale <= 3'd5;
	default:	aguA_scale <= 3'd0;
	endcase
	case(aguA_instr[7:0])
	`LB,`LD:	aguA_disp1 <= {{46{aguA_instr[47]}},aguA_instr[47:30]};
	default:	aguA_disp1 <= 64'h0;
	case(aguA_instr[7:0])
	`LDIS:		aguA_lg1 <= aguA_instr[27];
	`MOV2SEG:	aguA_lg1 <= aguA_xn[15];
	default:	aguA_lg1 <= 1'b0;
	endcase
	endcase
	case(aguA_instr[7:0])
	`LDIS:		aguA_xn1 <= aguA_instr[26:12];
	`MOV2SEG:	aguA_xn1 <= aguA_xn[14:0];
	default:	aguA_xn1 <= aguA_xn;
	endcase
	case(aguA_instr[7:0])
	`LDIS,`MOV2SEG:	aguA_an1 <= 64'h0;
	default:	aguA_an1 <= aguA_an;
	endcase
	aguA_x1 <= `TRUE;
	// Cycle2 add displacement, scale index
	aguA_xn2 <= aguA_xn1 << aguA_scale;
	aguA_adr2 <= aguA_an1 + aguA_disp1;
	aguA_x2 <= aguA_x1;
	case(aguA_instr[7:0])
	`LDIS,`MOV2SEG:
		begin
			aguA_base2 <= aguA_lg1 ? {ldt_base,5'd0} : {gdt_base,5'd0};
			aguA_lower2 <= aguA_lg1 ? ldt_lower : gdt_lower;
			aguA_upper2 <= aguA_lg1 ? ldt_upper : gdt_upper;
		end
	default:	;
	endcase
	// Cycle3 add scaled index
	aguA_base3 <= aguA_base2;
	aguA_lower3 <= aguA_lower2;
	aguA_upper3 <= aduA_upper2;
	aguA_adr3 <= aguA_adr2 + aguA_xn2;
	aguA_x3 <= aguA_x2;
	// Cycle4 add base
	if (aguA_adr3 < aguA_lower3 || aguA_adr3 >= aguA_upper3)
		dramA_exc <= `FLT_SGB;	// segment bounds fault
	dramA_addr <= aguA_base3 + aguA_adr3;
	aguA_v <= aguA_x3;
end


// dramX_v only set on a load
if (mem1_available && dramA_v && rob_v[ dramA_id[`QBITS] ] && rob_segload[dramA_id[`QBITS]]) begin
	sregfile_in0 <= rdramA_bus;
	sregfile_tgt0 <= rob_tgt[dramA_id[`QBITS]][4:0];
	sregfile_wr0 <= `TRUE;
	rob_exc	[ dramA_id[`QBITS] ] <= dramA_exc;
	rob_done[ dramA_id[`QBITS] ] <= `VAL;
	rob_out [ dramA_id[`QBITS] ] <= `INV;
	rob_cmt [ dramA_id[`QBITS] ] <= `VAL;
	rob_aq  [ dramA_id[`QBITS] ] <= `INV;
end
if (mem2_available && `NUM_MEM > 1 && dramB_v && rob_v[ dramB_id[`QBITS] ] && rob_segload[dramB_id[`QBITS]]) begin
	sregfile_in1 <= rdramB_bus;
	sregfile_tgt1 <= rob_tgt[dramB_id[`QBITS]][4:0];
	sregfile_wr1 <= `TRUE;
	rob_exc	[ dramB_id[`QBITS] ] <= dramB_exc;
	rob_done[ dramB_id[`QBITS] ] <= `VAL;
	rob_out [ dramB_id[`QBITS] ] <= `INV;
	rob_cmt [ dramB_id[`QBITS] ] <= `VAL;
	rob_aq  [ dramB_id[`QBITS] ] <= `INV;
end

end

reg [23:0] seg_selector;

case(bstate)
B_Idle:
	begin
		if (~acki & ~cyc & dram0_load_selector) begin
			cti_o <= 3'b001;
			cyc <= `HIGH;
			stb_o <= `HIGH;
			sel_o <= 8'hFF;
			vadr <= dram0_addr;
			desc_cnt <= 2'd0;
			bstate <= B_LoadDesc;
		end
	end
B_LoadDesc:
	begin
		if (acki) begin
			if (!bok_i) begin
				stb_o <= `LOW;
				bstate <= B_LoadDescStb;
			end
			case(desc_cnd)
			2'b00:	desc_in[63:0] <= dat_i;
			2'b01:	desc_in[127:64] <= dat_i;
			2'b10:	desc_in[191:128] <= dat_i;
			2'b11:	desc_in[255:192] <= dat_i;
			endcase
			if (desc_cnt==2'd2)
				cti_o <= 3'b111;
			if (desc_cnt==3'd3) begin
				wb_nack();
				cti_o <= 3'b000;
				bstate <= B_Idle;
				seg_state <= SEG_CHK;
			end
			desc_cnt <= desc_cnt + 2'd1;
		end
	end
B_LoadDescStb:
	begin
		stb_o <= `HIGH;
		bstate <= B_LoadDesc;
	end

case(seg_state)
SEG_IDLE:	;
SEG_CHK:
	begin
		seg_state <= SEG_PASSED_CHK;
		// Is it a zero descriptor?
		if (desc_in[255:192]==64'd0) begin
			// Attempting to load the stack segment with a zero selector results in a
			// fault.
			if (seg_tgt==4'd6)	// SS target?
				rob_exc[dram0_id[`QBITS]] <= `FLT_SSZ;
			else begin
				sregfile_tgt <= seg_rtgt;
				sregfile_wr <= `TRUE;
				sregfile_in <= desc_in;
			end
			desc_cache[desc_ndx] <= desc_in;
		end
		else begin
			if (desc_in[255]==1'b0) begin
				rob_exc[dram0_id[`QBITS]] <= `FLT_SNP;			// segment not present
			end
			// A code segment must be loaded into a code segment register
			if (desc_in[255:248] >= 8'h98 && desc_in[255:248] <= 8'h9F) begin
				if (seg_tgt != 4'd7 && seg_tgt != 4'd8 && seg_tgt != 4'd9)
					rob_exc[dram0_id[`QBITS]] <= `FLT_STX;			// segment type exception
				if (cpl != desc_in[247:240])
					rob_exc[dram0_id[`QBITS]] <= `FLT_PRIV;			// privilege violation
			end
			// Check for LDT
			else if (desc_in[255:248]==8'h82 && seg_tgt != 4'd11)
				rob_exc[dram0_id[`QBITS]] <= `FLT_STX;			// segment type exception
		end
	end
SEG_PASSED_CHK:
	begin
		desc_cache[desc_ndx] <= desc_in;
		desc_cache_v[desc_ndx] <= `VAL;
		sregfile_wr <= `TRUE;
		sregfile_tgt <= rob_tgt[];
		sregfile_in	<= desc_in;
		seg_state <= SEG_IDLE;
	end

endcase

endcase

task tDram0Issue;
input [`QBITSP1] n;
begin
//	dramA_v <= `INV;
	dram0 		<= `DRAMSLOT_BUSY;
	dram0_id 	<= { 1'b1, n[`QBITS] };
	dram0_instr <= iqentry_instr[n];
	dram0_rmw  <= iqentry_rmw[n];
	dram0_preload <= iqentry_preload[n];
	dram0_tgt 	<= iqentry_tgt[n];
	dram0_data	<= iqentry_a2[n];
	dram0_addr	<= iqentry_ma[n];
	//             if (ol[iqentry_thrd[n]]==`OL_USER)
	//             	dram0_seg   <= (iqentry_Ra[n]==5'd30 || iqentry_Ra[n]==5'd31) ? {ss[iqentry_thrd[n]],13'd0} : {ds[iqentry_thrd[n]],13'd0};
	//             else
	dram0_unc   <= iqentry_ma[n][31:20]==12'hFFD || !dce || iqentry_loadv[n];
	dram0_memsize <= iqentry_memsz[n];
	dram0_load <= iqentry_load[n];
	dram0_store <= iqentry_store[n];
`ifdef SUPPORT_SMT
	dram0_ol   <= (iqentry_Ra[n][4:0]==5'd31 || iqentry_Ra[n][4:0]==5'd30) ? ol[iqentry_thrd[n]] : dl[iqentry_thrd[n]];
`else
	dram0_ol   <= (iqentry_Ra[n][4:0]==5'd31 || iqentry_Ra[n][4:0]==5'd30) ? ol : dl;
`endif
	// Once the memory op is issued reset the a1_v flag.
	// This will cause the a1 bus to look for new data from memory (a1_s is pointed to a memory bus)
	// This is used for the load and compare instructions.
	// must reset the a1 source too.
	//iqentry_a1_v[n] <= `INV;
	iqentry_state[n] <= IQS_MEM;
end
endtask


endmodule

