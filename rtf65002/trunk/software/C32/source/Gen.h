/*
 *      code generation structures and constants
 */

#define F_REG   1       /* register direct mode allowed */
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
	unsigned int preg : 6;
	unsigned int sreg : 6;
	unsigned int tempflag : 1;
	unsigned int isFloat : 1;
	int deep;           /* stack depth on allocation */
	struct enode *offset;
	__int8 scale;
	SYM *sym;
} AMODE;

/*      output code structure   */

struct ocode {
	struct ocode *fwd, *back;
	short opcode;
	short length;
	unsigned int isVolatile : 1;
	AMODE *oper1, *oper2, *oper3;
};

enum e_op {
        op_add, op_sub, op_cmp, op_subsp,
        op_mul, op_mulu, op_div, op_divu, op_mod, op_modu,
		op_and, op_or, op_eor,
		op_asr, op_asl, op_lsr,
		op_jmp,
		op_tas,
		op_bra, op_bmi ,op_beq, op_bne,
		op_blt, op_ble, op_bgt, op_bge,
		op_bhi, op_bhs, op_blo, op_bls, 
		op_dw,
		op_php, op_sei,
		op_push, op_pop,
		op_ld, op_lb, op_st, op_sb, op_lea, op_lda,
		op_jsr, 	
        op_rts, op_rti,	
        op_tst,
		op_tsr, op_trs,
		op_not,
		op_neg,
		op_label, op_ilabel,
        op_dc, op_asm, op_stop, op_empty
};

enum e_am {
        am_reg, am_ind, am_ainc, am_adec, am_indx, am_indx2,
        am_direct, am_immed, am_mask, am_none, am_indx3
	};

int bitsset(int mask);
AMODE *makereg(int r);
void GenerateMonadic(int op, int len, AMODE *ap1);
void GenerateDiadic(int op, int len, AMODE *ap1, AMODE *ap2);
void GenerateTriadic(int op, int len, AMODE *ap1, AMODE *ap2, AMODE *ap3);
AMODE *GenerateExpression(ENODE *node, int flags, int size);
int GetNaturalSize(ENODE *node);
