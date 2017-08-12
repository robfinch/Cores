#ifndef _GEN_H
#define _GEN_H
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

// output code structure

struct ocode {
	struct ocode *fwd, *back, *comment;
	short opcode;
	short length;
	unsigned int isVolatile : 1;
	unsigned int isReferenced : 1;		// set if label is referenced
	unsigned int remove : 1;			// set to remove instruction in peephole opt.
	short pregreg;
	short predop;
	AMODE *oper1, *oper2, *oper3, *oper4;
};

enum e_pop { pop_always, pop_nop, pop_z, pop_nz, pop_c, pop_nc, pop_mi, pop_pl };

enum e_op {
        op_add, op_addi, op_adc, op_sub, op_sbc, op_subi, op_mov,
		op_ld, op_sto,
        op_and, op_andi,
        op_or, op_ori, op_xor, op_xori,
		op_ror, op_asr,
		op_rori,
		op_jsr,
		op_bmi,
		op_out, op_in,
		op_beq, op_bne, op_blt, op_ble, op_bgt, op_bge,
		op_bltu, op_bleu, op_bgtu, op_bgeu,
		op_inc, op_dec,
        op_rti,
		op_push, op_pop,
        op_not, op_cmp, op_cmpc, op_label, op_ilabel,
        op_cmpi, op_asm,
		op_nop, op_rem,
		op_hint,
		op_preload,
		op_fnname,
		op_dc,
		op_mul, op_div,
		op_mulu, op_divu, op_putpsr,
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
