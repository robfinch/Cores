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
#define F_IMMED18	64		// 18-bit immediate constant

/*      addressing mode structure       */

typedef struct amode {
	unsigned int mode : 8;
	unsigned int preg : 8;
	unsigned int sreg : 8;
	unsigned int tempflag : 1;
	unsigned int isFloat : 1;
	int deep;           /* stack depth on allocation */
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
        op_move, op_add, op_addu, op_addi, op_sub, op_subi, op_mov, op_mtspr, op_ldi,
        op_muls, op_mulsi, op_mulu, op_divs, op_divsi, op_divu, op_and, op_andi,
        op_or, op_ori, op_xor, op_xori, op_asr, op_shl, op_shr, op_shru,
		op_shli, op_shri, op_shrui,
		op_bfext, op_bfextu,
		op_jmp, op_jsr, op_mului, op_mod, op_modu,
		op_fdmul, op_fdsub, op_fddiv, op_fdadd, op_fdneg,
		op_fsmul, op_fssub, op_fsdiv, op_fsadd, op_fsneg,
		op_fs2d, op_i2d,
		op_tas, op_bmi, op_subu, op_lwr, op_swc, op_loop, op_iret,
		op_sext32,op_sext16,op_sext8, op_dw, op_cache,
		op_subui, op_addui, op_sei,
		op_sw, op_sh, op_sc, op_sb, op_outb, op_inb, op_inbu,
		op_call, op_jal, op_beqi, op_bnei, op_tst,
		op_lw, op_lh, op_lc, op_lb, op_ret, op_sm, op_lm, op_ldis, op_lws, op_sws,
        op_rts, op_rti,
		op_bra, op_bf, op_eq, op_ne, op_lt, op_le, op_gt, op_ge,
		op_gtu, op_geu, op_ltu, op_leu, op_nr,
        op_bhi, op_bhs, op_blo, op_bls, op_ext, op_lea, op_swap,
        op_neg, op_not, op_cmp, op_clr, op_link, op_unlk, op_label, op_ilabel,
        op_pea, op_cmpi, op_dc, op_asm, op_stop, op_empty };

enum e_am {
        am_reg, am_breg, am_ind, am_brind, am_ainc, am_adec, am_indx, am_indx2,
        am_direct, am_immed, am_mask, am_none, am_indx3, am_predreg
	};

#define LR		1
#define XLR		11

#define BP		254
#define SP		255
