`include "rtf65000-defines.sv"

module idecoder(instr, dc_ori_sr, dc_ori, dc_andi_sr, dc_andi, dc_subi, dc_addi, dc_eori_sr, dc_eori,
	dc_cmpi, dc_btst, dc_bchg, dc_bclr, dc_bset, dc_movea, dc_move, dc_move_from_sr, dc_move_to_sr,
	dc_negx, dc_clr, dc_neg, dc_not, dc_ext, dc_nbcd, dc_swap, dc_pea, dc_illegal, dc_tas, dc_tst,
	dc_trap, dc_link, dc_unlk, dc_reset, dc_nop, dc_stop, dc_rti, dc_rts, dc_trapv, dc_jsr, dc_jmp,
	dc_lea, dc_chk, dc_dbcc, dc_scc, dc_addq, dc_subq, dc_bra, dc_bsr, dc_bcc, dc_moveq, dc_divu,
	dc_divs, dc_sbcd, dc_or, dc_sub, dc_subx, dc_suba, dc_eor, dc_cmp, dc_cmpa, dc_mulu, dc_muls,
	dc_abcd, dc_exg, dc_and, dc_add, dc_addx, dc_adda, dc_asdm, dc_lsdm, dc_roxdm, dc_rodm,
	dc_asd, dc_lsd, dc_roxd, dc_rod);
input [79:0] instr;
output dc_ori_sr, dc_ori, dc_andi_sr, dc_andi, dc_subi, dc_addi, dc_eori_sr, dc_eori,
	dc_cmpi, dc_btst, dc_bchg, dc_bclr, dc_bset, dc_movea, dc_move, dc_move_from_sr, dc_move_to_sr,
	dc_negx, dc_clr, dc_neg, dc_not, dc_ext, dc_nbcd, dc_swap, dc_pea, dc_illegal, dc_tas, dc_tst,
	dc_trap, dc_link, dc_unlk, dc_reset, dc_nop, dc_stop, dc_rti, dc_rts, dc_trapv, dc_jsr, dc_jmp,
	dc_lea, dc_chk, dc_dbcc, dc_scc, dc_addq, dc_subq, dc_bra, dc_bsr, dc_bcc, dc_moveq, dc_divu,
	dc_divs, dc_sbcd, dc_or, dc_sub, dc_subx, dc_suba, dc_eor, dc_cmp, dc_cmpa, dc_mulu, dc_muls,
	dc_abcd, dc_exg, dc_and, dc_add, dc_addx, dc_adda, dc_asdm, dc_lsdm, dc_roxdm, dc_rodm,
	dc_asd, dc_lsd, dc_roxd, dc_rod;
assign dc_ori_sr = instr[15:0] == 16'h007C;
assign dc_ori = instr[15:8]==8'h00 && !dc_ori_sr;
assign dc_andi_sr = instr[15:0] == 16'h027C;
assign dc_andi = instr[15:8]==8'h02 & !andi_sr;
assign dc_subi = instr[15:8]==8'h04;
assign dc_addi = instr[15:8]==8'h06;
assign dc_eori_sr = instr[15:0] == 16'h0A7C;
assign dc_eori = instr[15:8]==8'h0A && !eori_sr;
assign dc_cmpi = instr[15:8]==8'h0C;
assign dc_btst = instr[15:6]==10'b0000_1000_00;
assign dc_bchg = instr[15:6]==10'b0000_1000_01;
assign dc_bclr = instr[15:6]==10'b0000_1000_10;
assign dc_bset = instr[15:6]==10'b0000_1000_11;
assign dc_movea = instr[15:14]==2'b00 && instr[8:6]==3'b001;
assign dc_move = instr[15:14]==2'b00 && !movea;
assign dc_move_from_sr = instr[15:6]==10'b0100_0000_11;
assign dc_move_to_sr = instr[15:6]==10'b0100_0110_11;
assign dc_negx = instr[15:8]==8'h40 && !move_from_sr;
assign dc_clr = instr[15:8]==8'h42;
assign dc_neg = instr[15:8]==8'h44;
assign dc_not = instr[15:8]==8'h46;
assign dc_ext = instr[15:8]==8'h48 && instr[7] && instr[5:3]==3'b000;
assign dc_nbcd = instr[15:6]==10'b0100_1000_00;
assign dc_swap = instr[15:3]==13'b0100_1000_0100_0;
assign dc_pea = instr[15:6]==10'b0100_1000_01 && !dc_swap;
assign dc_illegal = instr[15:0]==16'h4AFC;
assign dc_tas = instr[15:6]==10'b0100_1010_11 && !dc_illegal;
assign dc_tst = instr[15:8]==8'h4A && !dc_tas && !dc_illegal;
assign dc_trap = instr[15:4]==12'h4E4;
assign dc_link = instr[15:3]==13'b0100_1110_0101_0;
assign dc_unlk = instr[15:3]==13'b0100_1110_0101_1;
assign dc_reset = instr[15:0]==16'h4E70;
assign dc_nop = instr[15:0]==16'h4E71;
assign dc_stop = instr[15:0]==16'h4E72;
assign dc_rti = instr[15:0]==16'h4E73;
assign dc_rts = instr[15:0]==16'h4E75;
assign dc_trapv = instr[15:0]==16'h4E76;
assign dc_jsr = instr[15:6]==10'b0100_1110_10;
assign dc_jmp = instr[15:6]==10'b0100_1110_11;
assign dc_lea = instr[15:12]==4'h4 && instr[8:6]==3'b111;
assign dc_chk = instr[15:12]==4'h4 && instr[8:6]==3'b110;
assign dc_dbcc = instr[15:12]==4'h5 && instr[7:3]==5'b11001;
assign dc_scc = instr[15:12]==4'h5 && instr[7:6]==2'b11 && !dc_dbcc;
assign dc_addq = instr[15:12]==4'h5 && instr[8]==1'b0 && !dc_scc && !dc_dbcc;
assign dc_subq = instr[15:12]==4'h5 && instr[8]==1'b1 && !dc_scc && !dc_dbcc;
assign dc_bra = instr[15:8]==8'h60;
assign dc_bsr = instr[15:8]==8'h61;
assign dc_bcc = instr[15:12]==4'h6 && !dc_bra && !dc_bsr;
assign dc_moveq = instr[15:12]==4'h7 && instr[8]==1'b0;
assign dc_divu = instr[15:12]==4'h8 && instr[8:6]==3'b011;
assign dc_divs = instr[15:12]==4'h8 && instr[8:6]==3'b111;
assign dc_sbcd = instr[15:12]==4'h8 && instr[8:4]==5'b10000;
assign dc_or = instr[15:12]==4'h8 && !dc_divu && !dc_divs && !dc_sbcd;
assign dc_subx = instr[15:12]==4'h9 && instr[8] && instr[5:4]==2'b00;
assign dc_suba  = instr[15:12]==4'h9 && instr[7:6]==2'b11 && !dc_subx;
assign dc_sub = instr[15:12]==4'h9 && !dc_subx && !dc_suba;
assign dc_cmpa = instr[15:12]==4'hB && instr[7:6]==2'b11; 
assign dc_eor = instr[15:12]==4'hB && instr[8]==1'b1 && !dc_cmpa;
assign dc_cmp = instr[15:12]==4'hB && instr[8]==1'b0 && !dc_cmpa;
assign dc_exg = instr[15:12]==4'hC && instr[8]==1'b1 && instr[5:4]==2'b00;
assign dc_mulu = instr[15:12]==4'hC && instr[8:6]==3'b011;
assign dc_muls = instr[15:12]==4'hC && instr[8:6]==3'b111 && !dc_exg;
assign dc_abcd = instr[15:12]==4'hc && instr[8:4]==5'b10000 && !dc_exg;
assign dc_and = instr[15:12]==4'hC && !dc_exg && !dc_mulu && !dc_muls && !dc_abcd;
assign dc_adda = instr[15:12]==4'hD && instr[7:6]==2'b11;
assign dc_addx = instr[15:12]==4'hD && instr[8]==1'b1 && instr[5:4]==2'b00 && !dc_adda;
assign dc_add = instr[15:12]==4'hD && !dc_addx && !dc_adda;
assign dc_asdm = instr[15:9]==7'b1110_000 && instr[7:6]==2'b11;
assign dc_lsdm = instr[15:9]==7'b1110_001 && instr[7:6]==2'b11;
assign dc_roxdm = instr[15:9]==7'b1110_010 && instr[7:6]==2'b11;
assign dc_rodm = instr[15:9]==7'b1110_011 && instr[7:6]==2'b11;
assign dc_asd = instr[15:12]==4'hE && instr[7:6] != 2'b11 && instr[4:3]==2'b00;
assign dc_lsd = instr[15:12]==4'hE && instr[7:6] != 2'b11 && instr[4:3]==2'b01;
assign dc_roxd = instr[15:12]==4'hE && instr[7:6] != 2'b11 && instr[4:3]==2'b10;
assign dc_rod = instr[15:12]==4'hE && instr[7:6] != 2'b11 && instr[4:3]==2'b11;

wire IsMR = dc_ori | dc_andi | dc_subi | dc_eori | dc_cmpi 
	| dc_btst | dc_bchg | dc_bclr | dc_bset
	| dc_movea | dc_move_from_sr | dc_move_to_sr
	| dc_negx | dc_neg | dc_clr | dc_not
	| dc_nbcd | dc_pea | dc_tas | dc_tst 
	| dc_jsr | dc_jmp | dc_movem | dc_lea | dc_chk
	| dc_addq | dc_subq | dc_scc | dc_divu | dc_divs
	| dc_or | dc_sub | dc_suba | dc_eor | dc_cmp
	| dc_cmpa | dc_mulu | dc_muls | dc_and | dc_add
	| dc_adda 
	| dc_asdm | dc_lsdm | dc_roxdm | dc_rodm
	;
wire HasExtWord = IsMR && (instr[`M]==3'b010 || instr[`M]==3'b110
								|| (instr[`M]==3'b111 && instr[`Xn]==3'b010)
								|| (instr[`M]==3'b111 && instr[`Xn]==3'b011)
								)
								;
wire IsAbsShort = IsMR && (instr[`M]==3'b111 && instr[`Xn]==3'b000);
wire IsAbsLong = IsMR && (instr[`M]==3'b111 && instr[`Xn]==3'b001);

wire HasImm16 = 
		dc_ori_sr | dc_andi_sr | dc_eori_sr 
	| ((dc_ori | dc_andi | dc_eori | dc_addi | dc_cmpi) && instr[7]==1'b0)
	| dc_stop | dc_link
	;
wire HasImm32 =
	  ((dc_ori | dc_andi | dc_eori | dc_addi | dc_cmpi) && instr[7]==1'b1)
	  ;
	
if (dc_ori_sr | dc_andi_sr | dc_eori_sr)
	length = 4'd4;
else if (dc_ori | dc_andi | dc_subi | dc_eori | dc_cmpi 
	| dc_btst | dc_bchg | dc_bclr | dc_bset
	| dc_movea | dc_move_from_sr | dc_move_to_sr
	| dc_negx | dc_neg | dc_clr | dc_not
	| dc_nbcd | dc_pea | dc_tas | dc_tst 
	| dc_jsr | dc_jmp | dc_movem | dc_lea | dc_chk
	| dc_addq | dc_subq | dc_scc | dc_divu | dc_divs
	| dc_or | dc_sub | dc_suba | dc_eor | dc_cmp
	| dc_cmpa | dc_mulu | dc_muls | dc_and | dc_add
	| dc_adda 
	| dc_asdm | dc_lsdm | dc_roxdm | dc_rodm)

endmodule
