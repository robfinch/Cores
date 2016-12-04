#ifndef GEN_H
#define GEN_H
/*
 *      code generation structures and constants
 */

#define F_REG   1       /* register direct mode allowed */
#define F_BREG	2		/* branch register */
#define F_MEM   4       /* memory alterable modes allowed */
#define F_IMMED 8       /* immediate mode allowed */
#define F_ALT   7       /* alterable modes */
#define F_DALT  5       /* data alterable modes */
#define F_VOL   16      /* need volitile operand */
#define F_IMMED18	64	// 18-bit immediate constant
#define F_IMM0	128		/* immediate value 0 */
#define F_IMM8	256
#define F_IMMED13  512
#define F_FPREG 1024
#define F_IMM6  2048
#define BF_ASSIGN	4096
#define F_ALL   (15|1024)      /* all modes allowed */
#define F_NOVALUE 32768		/* dont need result value */

/*      addressing mode structure       */

typedef struct amode {
	unsigned int mode : 6;
	unsigned int preg : 8;
	unsigned int sreg : 8;
	unsigned int segment : 4;
	unsigned int defseg : 1;
	unsigned int tempflag : 1;
	unsigned int isFloat : 1;
	unsigned int isAddress : 1;
	char FloatSize;
	unsigned int isUnsigned : 1;
	unsigned int lowhigh : 2;
	unsigned int isVolatile : 1;
	unsigned int isPascal : 1;
	unsigned int rshift : 8;
	short int deep;           /* stack depth on allocation */
	short int deep2;
	ENODE *offset;
	int8_t scale;
} AMODE;

/*      output code structure   */

struct ocode {
	struct ocode *fwd, *back;
	short opcode;
	short length;
	unsigned int isVolatile : 1;
	short pregreg;
	short predop;
	AMODE *oper1, *oper2, *oper3, *oper4;
};

enum e_op {
        op_move, op_add, op_addu, op_addi, op_sub, op_subi, op_mov, op_mtspr, op_mfspr, op_ldi, op_ld,
        op_mul, op_muli, op_mulu, op_divi, op_modi, op_modui, 
        op_div, op_divs, op_divsi, op_divu, op_and, op_andi, op_eor, op_eori,
        op_or, op_ori, op_xor, op_xori, op_asr, op_asri, op_shl, op_shr, op_shru, op_ror, op_rol,
		op_shli, op_shri, op_shrui, op_shlu, op_shlui, op_rori, op_roli,
		op_bfext, op_bfextu, op_bfins,
		op_jmp, op_jsr, op_mului, op_mod, op_modu,
		op_bmi, op_subu, op_lwr, op_swc, op_loop, op_iret,
		op_sext32,op_sext16,op_sext8, op_sxb, op_sxc, op_sxh, op_zxb, op_zxc, op_zxh,
		op_dw, op_cache,
		op_subui, op_addui, op_sei,
		op_sw, op_sh, op_sc, op_sb, op_outb, op_inb, op_inbu,
		op_sfd, op_lfd,
		op_call, op_jal, op_beqi, op_bnei, op_tst,

		op_beq, op_bne, op_blt, op_ble, op_bgt, op_bge,
		op_bltu, op_bleu, op_bgtu, op_bgeu,
		op_bltui, op_bleui, op_blti, op_blei, op_bgti, op_bgtui, op_bgei, op_bgeui,
		op_bbs, op_bbc,

		op_brz, op_brnz, op_br,
		op_lft, op_sft,
		op_lw, op_lh, op_lc, op_lb, op_ret, op_sm, op_lm, op_ldis, op_lws, op_sws,
		op_lvb, op_lvc, op_lvh, op_lvw,
		op_inc, op_dec,
		op_lbu, op_lcu, op_lhu, op_sti,
		op_lf, op_sf,
        op_rts, op_rti, op_rtd,
		op_push, op_pop, op_movs,
		op_seq, op_sne, op_slt, op_sle, op_sgt, op_sge, op_sltu, op_sleu, op_sgtu, op_sgeu,
		op_bra, op_bf, op_eq, op_ne, op_lt, op_le, op_gt, op_ge,
		op_feq, op_fne, op_flt, op_fle, op_fgt, op_fge,
		op_gtu, op_geu, op_ltu, op_leu, op_nr,
        op_bhi, op_bhs, op_blo, op_bls, op_ext, op_lea, op_swap,
        op_neg, op_not, op_com, op_cmp, op_clr, op_link, op_unlk, op_label, op_ilabel,
        op_pea, op_cmpi, op_dc, op_asm, op_stop, op_fnname, 
        // W65C816 ops
        op_sec, op_clc, op_lda, op_sta, op_stz, op_adc, op_sbc, op_ora,
        op_jsl, 
        op_rtl, op_php, op_plp, op_cli, op_ldx, op_stx, op_brl,
        op_pha, op_phx, op_pla, op_plx, op_rep, op_sep,
        op_bpl, op_tsa, op_tas,
        // FISA64
        op_lc0i, op_lc1i, op_lc2i, op_lc3i, op_chk, op_chki,
        op_cmpu, op_bsr, op_bun,
        op_sll, op_slli, op_srl, op_srli, op_sra, op_srai, op_asl, op_lsr, op_asli, op_lsri, op_rem,
        // floating point
		op_fbeq, op_fbne, op_fbor, op_fbun, op_fblt, op_fble, op_fbgt, op_fbge,
		op_fcvtsq,
		op_fadd, op_fsub, op_fmul, op_fdiv, op_fcmp, op_fneg,
		op_ftmul, op_ftsub, op_ftdiv, op_ftadd, op_ftneg, op_ftcmp,
		op_fdmul, op_fdsub, op_fddiv, op_fdadd, op_fdneg, op_fdcmp,
		op_fsmul, op_fssub, op_fsdiv, op_fsadd, op_fsneg, op_fscmp,
		op_fs2d, op_i2d, op_i2t, op_ftoi,
		op_fmov,
        op_fdmov, op_fix2flt, op_mtfp, op_mffp, op_flt2fix, op_mv2flt, op_mv2fix,

		op_hint,
        op_empty };

enum e_seg {
	op_ns = 0,
	op_ds = 1 << 8,
	op_ts = 2 << 8,
	op_bs = 3 << 8,
	op_rs = 4 << 8,
	op_es = 5 << 8,
	op_seg6 = 6 << 8,
	op_seg7 = 7 << 8,
	op_seg8 = 8 << 8,
	op_seg9 = 9 << 8,
	op_seg10 = 10 << 8,
	op_seg11 = 11 << 8, 
	op_seg12 = 12 << 8,
	op_seg13 = 13 << 8,
	op_ss = 14 << 8,
	op_cs = 15 << 8
};

enum e_am {
        am_reg, am_sreg, am_breg, am_fpreg, am_ind, am_brind, am_ainc, am_adec, am_indx, am_indx2,
        am_direct, am_jdirect, am_immed, am_mask, am_none, am_indx3, am_predreg
	};

#define LR		1
#define CLR		11

#define BP		26
#define SP		27

#define DS		0x21
#define BSS		0x23
#define LS		0x29
#define XLS		0x2A
#define SS		0x2E
#define CS		0x2F

#endif
