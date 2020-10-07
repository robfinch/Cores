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
#define F_VREG	8192
#define F_VMREG	16384
#define F_ALL   (15|1024|F_VREG|F_VMREG)      /* all modes allowed */
#define F_NOVALUE 32768		/* dont need result value */

/*      addressing mode structure       */
/*
typedef AMODE {
	unsigned int mode : 6;
	unsigned int preg : 8;
	unsigned int sreg : 8;
	unsigned int segment : 4;
	unsigned int defseg : 1;
	unsigned int tempflag : 1;
	unsigned int type : 16;
	char FloatSize;
	unsigned int isUnsigned : 1;
	unsigned int lowhigh : 2;
	unsigned int isVolatile : 1;
	unsigned int isPascal : 1;
	unsigned int rshift : 8;
	short int deep;
	short int deep2;
	ENODE *offset;
	int8_t scale;
} AMODE;
*/

/*      output code structure   */
/*
OCODE {
	OCODE *fwd, *back, *comment;
	short opcode;
	short length;
	unsigned int isVolatile : 1;
	unsigned int isReferenced : 1;	// label is referenced by code
	unsigned int remove : 1;
	short pregreg;
	short predop;
	AMODE *oper1, *oper2, *oper3, *oper4;
};
*/
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
