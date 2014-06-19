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
#define F_ALL   15      /* all modes allowed */
#define F_VOL   16      /* need volitile operand */
#define F_NOVALUE 32    /* dont need result value */
#define F_IMMED18	64	// 18-bit immediate constant
#define F_IMM0	128		/* immediate value 0 */
#define F_IMM8	256

/*      addressing mode structure       */

typedef struct amode {
	unsigned int mode : 8;
	unsigned int preg : 8;
	unsigned int sreg : 8;
	unsigned int segment : 4;
	unsigned int tempflag : 1;
	unsigned int isFloat : 1;
	unsigned int isUnsigned : 1;
	short int deep;           /* stack depth on allocation */
	short int deep2;
	struct enode *offset;
	__int8 scale;
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
        op_move, op_add, op_addu, op_addi, op_sub, op_subi, op_mov, op_mtspr, op_mfspr, op_ldi,
        op_mul, op_muli, op_mulu, op_divs, op_divsi, op_divu, op_and, op_andi, op_eor, op_eori,
        op_or, op_ori, op_xor, op_xori, op_asr, op_asri, op_shl, op_shr, op_shru,
		op_shli, op_shri, op_shrui, op_shlu, op_shlui,
		op_bfext, op_bfextu, op_bfins,
		op_jmp, op_jsr, op_mului, op_mod, op_modu,
		op_fdmul, op_fdsub, op_fddiv, op_fdadd, op_fdneg,
		op_fsmul, op_fssub, op_fsdiv, op_fsadd, op_fsneg,
		op_fs2d, op_i2d,
		op_tas, op_bmi, op_subu, op_lwr, op_swc, op_loop, op_iret,
		op_sext32,op_sext16,op_sext8, op_sxb, op_sxc, op_sxh, 
		op_dw, op_cache,
		op_subui, op_addui, op_sei,
		op_sw, op_sh, op_sc, op_sb, op_outb, op_inb, op_inbu,
		op_call, op_jal, op_beqi, op_bnei, op_tst,
		op_beq, op_bne, op_blt, op_ble, op_bgt, op_bge,
		op_bltu, op_bleu, op_bgtu, op_bgeu,
		op_brz, op_brnz,
		op_lw, op_lh, op_lc, op_lb, op_ret, op_sm, op_lm, op_ldis, op_lws, op_sws,
		op_lbu, op_lcu, op_lhu, op_sti,
        op_rts, op_rti, op_rtd,
		op_push, op_pop, op_movs,
		op_bra, op_bf, op_eq, op_ne, op_lt, op_le, op_gt, op_ge,
		op_gtu, op_geu, op_ltu, op_leu, op_nr,
        op_bhi, op_bhs, op_blo, op_bls, op_ext, op_lea, op_swap,
        op_neg, op_not, op_cmp, op_clr, op_link, op_unlk, op_label, op_ilabel,
        op_pea, op_cmpi, op_dc, op_asm, op_stop, op_fnname, op_empty };

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
        am_reg, am_sreg, am_breg, am_ind, am_brind, am_ainc, am_adec, am_indx, am_indx2,
        am_direct, am_immed, am_mask, am_none, am_indx3, am_predreg
	};

#define LR		250
#define CLR		251

#define BP		253
#define SP		255

#define DS		0x21
#define BSS		0x23
#define LS		0x29
#define XLS		0x2A
#define SS		0x2E
#define CS		0x2F

#endif
