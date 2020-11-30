#define I_AUIPC	3
#define I_ADDI	4
#define I_ANDI	8
#define I_ORI		9
#define I_XORI	10
#define I_XNORI	14
#define I_CALL	25
#define I_LUI		39
#define I_JMP		40
#define I_RET		41
#define I_MODI		46
#define I_MULUI		56
#define I_MULI		58
#define I_DIVUI		60
#define I_NOP			61
#define I_DIVI		62

char *op_major[64] = {
	"BRK","?","?","AUIPC","ADD","CSR","SLT","SLTU",
	"AND","OR","XOR","?","BLEND","REX","XNOR","FLT",
	"?", "LV?U", "?", "LB", "?", "SB", "NDX", "SWC",
	"JAL","CALL","?","LF?","SGTU","LWR","CACHE","EXEC",
	"L?", "L?U", "BF?", "LBU", "S?", "CAS", "BB?", "LUI",
	"JMP", "RET", "MULF", "SF?", "SGT", "", "MOD", "AMO",
	"B??", "?", "BEQ", "?", "?", "?", "LV", "SV",
	"MULU", "FXMUL", "MUL", "LV?", "DIVU", "NOP", "DIV", "AMO"
};

int insn_length(unsigned __int16 *ad)
{
	unsigned __int16 i0;

	i0 = ad[0];
	// Return size of instruction
	if (i0 & 0x80) {
		return (2);		
	}
	else {
		if (i0 & 0x40)
			return (6);
	}
	return (4);
}

unsigned __int16 *find_insn(unsigned __int16 *st, unsigned __int16 *tgt)
{
	int sum;
	int count;
	
	st = st - 1;
	for (count = 0; count < 8; count++) {
		st = st + 1;
		sum = insn_length(st);
		sum += insn_length(st + (sum >> 1));
		sum += insn_length(st + (sum >> 1));
		sum += insn_length(st + (sum >> 1));
		if ((st + (sum >> 1)) < tgt)
			st += 1;
		else if ((st + (sum >> 1)) > tgt)
			st -= 1;
		else
			break;
	}
	return (st);
}


int disassem(unsigned __int16 *ad)
{
	unsigned __int16 i0,i1,i2;
	unsigned int insn;
	unsigned int op;
	unsigned int r;
	int imm;
	char *str;

	i0 = ad[0];
	i1 = ad[1];
	i2 = ad[2];
	insn = i0 | (i1 << 16) | (i2 << 32);
	imm = (insn >> 14) & 0x3fff;
	if ((imm >> 13) & 1)
		imm |= 0xffffffffffffc000L;

	// Compressed instruction
	if (i0 & 0x80) {
		if (i0 & 0x40) {
			op = i0 >> 12;
			switch(op) {
			case 3:	// PUSH
				r = i0 & 0x1f;
				dbg_printf("PUSH r%d", r);				
				break;
			case 4,6,8,10:
				imm = ((i0 & 0x20) >> 2);
				imm |= (((i0 >> 8) & 15) << 4);
				if ((imm >> 7) & 1)
					imm |= 0xffffffffffffff00L;
				r = i0 & 0x1f;
				dbg_printf("%cH r%d,%d[%cp]", (op==9||op==11) ? 'S' : 'L',r, imm, (op==7||op==11) ? 'f' : 's');
				break;			
			case 5,7,9,11:
				imm = ((i0 & 0x20) >> 2);
				imm |= (((i0 >> 8) & 15) << 4);
				if ((imm >> 7) & 1)
					imm |= 0xffffffffffffff00L;
				r = i0 & 0x1f;
				dbg_printf("%cW r%d,%d[%cp]", (op==9||op==11) ? 'S' : 'L',r, imm, (op==7||op==11) ? 'f' : 's');
				break;			
			}
		}
		else {
			switch(i0 >> 12) {
			case 0:	// ADDI / NOP
				imm = ((i0 & 0x20) >> 5);
				imm |= (((i0 >> 8) & 15) << 1);
				if ((imm >> 5) & 1)
					imm |= 0xffffffffffffffe0L;
				r = i0 & 0x1f;
				if (r==31)	{ // ADDI SP
					imm <<= 3;
					dbg_printf("ADDI sp,sp,#%d", imm);
				}
				else {
					dbg_printf("ADDI r%d,r%d,#%d", r, r, imm);
				}
				break;
			case 2:	// RET / ANDI
				r = i0 & 0x1f;
				if (r==0)	{ // ADDI SP
					imm = ((i0 & 0x20) >> 5);
					imm |= (((i0 >> 8) & 15) << 1);
					imm <<= 3;
					dbg_printf("RET #", imm);
				}
				else {
					imm = ((i0 & 0x20) >> 5);
					imm |= (((i0 >> 8) & 15) << 1);
					if ((imm >> 5) & 1)
						imm |= 0xffffffffffffffe0L;
					dbg_printf("ANDI r%d,r%d,#%d", r, r, imm);
				}
				break;
			}
		}
	}
	else {
		op = i0 & 0x3f;
		str = op_major[op];
		switch(op) {
		case I_ADDI, I_ANDI, I_ORI, I_XORI, I_XNORI, I_MULUI, I_MULI, I_MODI, I_DIVI, I_DIVUI:
			dbg_printf("%s r%d,r%d,#%d", str, (insn >> 13) & 0x1f, (insn >> 8) & 0x1f, imm);
			break;
		case I_CALL, I_JMP:	dbg_printf("%s $%X", str, ((insn >> 8) << 1)); break;
		}
	}
	dbg_printf("\r\n");
	// Return size of instruction
	return (insn_length(ad));
}

int disassem24(unsigned __int16 *ad, unsigned __int16 *ln)
{
	int n;
	
	dbg_printf("\r\n");
	for (n = 0; n < 24; n++) {
		ad += disassem(ad) >> 1;
	}
}
