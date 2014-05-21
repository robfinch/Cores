#include <stdio.h>
#include <stdlib.h>
#include "am.h"
#include "operandsButterfly.h"
#include "cpu.h"
#include "mne.h"
#include "opa.h"
#include "a_all.h"
#include "asmButterfly.h"

#define MAX_OPERANDS 60
/*
extern "C" {
int Asm6502::imm(Opa*);
};
*/
/* --------------------------------------------------------------
      Opcode / Pseudo op table. MUST BE IN ALPHABETICAL ORDER.
-------------------------------------------------------------- */

static Opa byteAsm[] = { {a_db, 'B', -1}, NULL };
static Opa dbAsm[] = { {a_db, 'B', -1}, NULL };
static Opa dcAsm[] = { {a_db, 'C', -1}, NULL };
static Opa dwAsm[] = { {a_db, 'C', -1}, NULL };
static Opa charAsm[] = { {a_db, 'C', -1}, NULL };
static Opa alignAsm[] = { {a_align,0,1 }, NULL };
static Opa bssAsm[] = { {a_bss}, NULL };
static Opa codeAsm[] = { {a_code,0,0}, NULL };
static Opa cpuAsm[] = { {a_cpu,0,-1}, NULL };
static Opa dataAsm[] = { {a_data}, NULL };
static Opa endAsm[] = { {a_end}, NULL };
static Opa externAsm[] = {{a_extern,0,-1}, NULL };
static Opa fillAsm[] = { {a_fill,0,2}, NULL };
static Opa includeAsm[] = { {a_include,0,1}, NULL };
static Opa messageAsm[] = { {a_message,0,1}, NULL };
static Opa orgAsm[] = { {a_org,0,1}, NULL };
static Opa commentAsm[] = { {a_comment,0,-1}, NULL };
static Opa endmAsm[] = { {a_endm}, NULL};
static Opa wordAsm[] = { {a_db,'C',-1}, NULL };
static Opa publicAsm[] = { {a_public,0, -1}, NULL };
static Opa listAsm[] = {{a_list,0,1}, NULL};
static Opa macroAsm[] = {{a_macro,0,-1}, NULL};


static Opa addAsm[] =
{
	{AsmButterfly::addi, 0x1000, 3, (AM_REG<<16)|(AM_REG<<8)|(AM_IMM)},
	{AsmButterfly::rr, 0x2001, 2, (AM_REG<<8)|AM_REG},
	{AsmButterfly::addi2, 0x1000, 2, (AM_REG<<8)|(AM_IMM)},
	NULL
};

static Opa cmpAsm[] =
{
	{AsmButterfly::cmpi, 0x1000, 2, (AM_REG<<8)|(AM_IMM)},
	{AsmButterfly::rr, 0x2003, 2, (AM_REG<<8)|AM_REG},
	NULL
};

static Opa subAsm[] =
{
	{AsmButterfly::subi, 0x1000, 3, (AM_REG<<16)|(AM_REG<<8)|(AM_IMM)},
	{AsmButterfly::rr, 0x2002, 2, (AM_REG<<8)|AM_REG},
	{AsmButterfly::subi2, 0x1000, 2, (AM_REG<<8)|(AM_IMM)},
	NULL
};

static Opa andAsm[] =
{
	{AsmButterfly::ri, 0x3050, 2, (AM_REG<<8)|(AM_IMM)},
    {AsmButterfly::rr, 0x2005, 2, (AM_REG<<8)|AM_REG},
	NULL
};

static Opa subrAsm[] =
{
	{AsmButterfly::ri, 0x3020, 2, (AM_REG<<8)|(AM_IMM)},
	NULL
};

static Opa orAsm[] =
{
	{AsmButterfly::ri, 0x3060, 2, (AM_REG<<8)|(AM_IMM)},
    {AsmButterfly::rr, 0x2006, 2, (AM_REG<<8)|AM_REG},
	NULL
};

static Opa xorAsm[] =
{
	{AsmButterfly::ri, 0x3040, 2, (AM_REG<<8)|(AM_IMM)},
    {AsmButterfly::rr, 0x2004, 2, (AM_REG<<8)|AM_REG},
	NULL
};

static Opa shlAsm[] ={
	{AsmButterfly::riu, 0x3080, 2, (AM_REG<<8)|(AM_IMM)},
	{AsmButterfly::rr, 0x2008, 2, (AM_REG<<8)|AM_REG},
	NULL
};
static Opa shrAsm[] ={
	{AsmButterfly::riu, 0x30A0, 2, (AM_REG<<8)|(AM_IMM)},
	{AsmButterfly::rr, 0x200A, 2, (AM_REG<<8)|AM_REG},
	NULL
};
static Opa rolAsm[] ={
	{AsmButterfly::riu, 0x3090, 2, (AM_REG<<8)|(AM_IMM)},
	{AsmButterfly::rr, 0x2009, 2, (AM_REG<<8)|AM_REG},
	NULL
};
static Opa rorAsm[] ={
	{AsmButterfly::riu, 0x30B0, 2, (AM_REG<<8)|(AM_IMM)},
	{AsmButterfly::rr, 0x200B, 2, (AM_REG<<8)|AM_REG},
	NULL
};
static Opa asrAsm[] ={
	{AsmButterfly::riu, 0x30C0, 2, (AM_REG<<8)|(AM_IMM)},
	{AsmButterfly::rr, 0x200C, 2, (AM_REG<<8)|AM_REG},
	NULL
};
static Opa negAsm[] ={{AsmButterfly::shift, 0x3020, 1, AM_REG},	NULL};
static Opa notAsm[] ={{AsmButterfly::shift, 0x304F, 1, AM_REG},	NULL};

static Opa beqAsm[] ={ {AsmButterfly::br, 0xB800, 1}, NULL };
static Opa bltAsm[] ={ {AsmButterfly::br, 0xB000, 1}, NULL };
static Opa bgeAsm[] ={ {AsmButterfly::br, 0xB100, 1}, NULL };
static Opa bleAsm[] ={ {AsmButterfly::br, 0xB200, 1}, NULL };
static Opa bgtAsm[] ={ {AsmButterfly::br, 0xB300, 1}, NULL };
static Opa bltuAsm[] ={ {AsmButterfly::br, 0xB400, 1}, NULL };
static Opa bgeuAsm[] ={ {AsmButterfly::br, 0xB500, 1}, NULL };
static Opa bleuAsm[] ={ {AsmButterfly::br, 0xB600, 1}, NULL };
static Opa bgtuAsm[] ={ {AsmButterfly::br, 0xB700, 1}, NULL };
static Opa bneAsm[] ={ {AsmButterfly::br, 0xB900, 1}, NULL };
static Opa bmiAsm[] ={ {AsmButterfly::br, 0xBA00, 1}, NULL };
static Opa bplAsm[] ={ {AsmButterfly::br, 0xBB00, 1}, NULL };
static Opa braAsm[] ={ {AsmButterfly::br, 0xBE00, 1}, NULL };
static Opa bsrAsm[] ={ {AsmButterfly::br, 0xBF00, 1}, NULL };

static Opa tsrAsm[] = { {AsmButterfly::tsr, 0x30E0, 2}, NULL };
static Opa trsAsm[] = { {AsmButterfly::trs, 0x30F0, 2}, NULL };

static Opa sysAsm[] = {	{a_out16, 0x0001, 0}, NULL };
static Opa brkAsm[] = {	{a_out16, 0x0000, 0}, NULL };
static Opa diAsm[] = { {a_out16, 0x0021}, NULL };
static Opa eiAsm[] = { {a_out16, 0x0020}, NULL };
static Opa riAsm[] = { {a_out16, 0x0022}, NULL };
static Opa rtiAsm[] = { {a_out16, 0x0010}, NULL };
static Opa retAsm[] = { {a_out16, 0x40F0}, NULL };
static Opa nopAsm[] = { {a_out16, 0x0037}, NULL };


static Opa scAsm[] =
{
    {AsmButterfly::lscAbs, 0xC000, 2, (AM_REG<<8)|(AM_ABS)},
    {AsmButterfly::lsRind, 0xC000, 2, (AM_REG<<8)|(AM_RIND)},
    {AsmButterfly::lscDrind, 0xC000, 2, (AM_REG<<8)|(AM_DRIND)},
	NULL
};

static Opa swAsm[] =
{
    {AsmButterfly::lswAbs, 0xD000, 2, (AM_REG<<8)|(AM_ABS)},
    {AsmButterfly::lsRind, 0xD000, 2, (AM_REG<<8)|(AM_RIND)},
    {AsmButterfly::lswDrind, 0xD000, 2, (AM_REG<<8)|(AM_DRIND)},
	NULL
};

static Opa lcAsm[] =
{
    {AsmButterfly::lscAbs, 0xE000, 2, (AM_REG<<8)|(AM_ABS)},
    {AsmButterfly::lsRind, 0xE000, 2, (AM_REG<<8)|(AM_RIND)},
    {AsmButterfly::lscDrind, 0xE000, 2, (AM_REG<<8)|(AM_DRIND)},
	NULL
};

static Opa leaAsm[] =
{
    {AsmButterfly::lscAbs, 0x1000, 2, (AM_REG<<8)|(AM_ABS)},
    {AsmButterfly::lsRind, 0x1000, 2, (AM_REG<<8)|(AM_RIND)},
    {AsmButterfly::lscDrind, 0x1000, 2, (AM_REG<<8)|(AM_DRIND)},
	NULL
};

static Opa lwAsm[] =
{
    {AsmButterfly::ldi, 0x1000, 2, (AM_REG<<8)|(AM_IMM)},
    {AsmButterfly::ldr, 0x1000, 2, (AM_REG<<8)|(AM_REG)},
    {AsmButterfly::lswAbs, 0xF000, 2, (AM_REG<<8)|(AM_ABS)},
    {AsmButterfly::lsRind, 0xF000, 2, (AM_REG<<8)|(AM_RIND)},
    {AsmButterfly::lswDrind, 0xF000, 2, (AM_REG<<8)|(AM_DRIND)},
	NULL
};


static Opa jalAsm[] =
{
    {AsmButterfly::lscAbs, 0x4000, 2, (AM_REG<<8)|(AM_ABS)},
    {AsmButterfly::lsRind, 0x4000, 2, (AM_REG<<8)|(AM_RIND)},
    {AsmButterfly::lscDrind, 0x4000, 2, (AM_REG<<8)|(AM_DRIND)},
	NULL
};


static Opa jmpAsm[] =
{
    {AsmButterfly::jmpAbs, 0x4000, 1, AM_ABS},
    {AsmButterfly::jmpRind, 0x4000, 1, AM_RIND},
    {AsmButterfly::jmpDrind, 0x4000, 1, AM_DRIND},
	NULL
};


static Opa callAsm[] =
{
    {AsmButterfly::jmpAbs, 0x4F00, 1, AM_ABS},
    {AsmButterfly::jmpRind, 0x4F00, 1, AM_RIND},
    {AsmButterfly::jmpDrind, 0x4F00, 1, AM_DRIND},
	NULL
};

static Opa trapAsm[] =
{
    {AsmButterfly::trap, 0x0000, 1, AM_IMM},
	NULL
};

static Mne opsButterfly[] =
{
	{".align", alignAsm, 1 },
	{".bss", bssAsm, 0},
	{".byte", byteAsm, MAX_OPERANDS },
	{".char", charAsm, MAX_OPERANDS },
	{".code", codeAsm, 0 },
	{".comment", commentAsm, -1 },
	{".cpu", cpuAsm, -1 },
	{".data", dataAsm, 0 },
	{".db", dbAsm, MAX_OPERANDS },
	{".dc", dcAsm, MAX_OPERANDS },
	{".dw", dwAsm, MAX_OPERANDS },
	{".end", endAsm, 0 },
	{".endm", endmAsm, 0 },
	{".extern", externAsm, -1 },
	{".fill", fillAsm, 2 },
	{".include", includeAsm, 1 },
	{".list", listAsm, 1 },
	{".macro", macroAsm, -1 },
	{".message", messageAsm, 1 },
	{".org", orgAsm, 1 },
	{".public", publicAsm, -1 },
	{".word", wordAsm, MAX_OPERANDS },

	{"add", addAsm, 3 },
	{"align", alignAsm, 1 },
	{"and", andAsm, 2 },
	{"asr", asrAsm, 1 },

	{"beq", beqAsm, 1 },
	{"bge", bgeAsm, 1 },
	{"bgeu", bgeuAsm, 1 },
	{"bgt", bgtAsm, 1 },
	{"bgtu", bgtuAsm, 1 },
	{"ble", bleAsm, 1 },
	{"bleu", bleuAsm, 1 },
	{"blt", bltAsm, 1 },
	{"bltu", bltuAsm, 1 },
	{"bmi", bmiAsm, 1 },
	{"bne", bneAsm, 1 },
	{"bpl", bplAsm, 1 },
	{"bra", braAsm, 1 },
	{"brk", brkAsm, 1 },
	{"bsr", bsrAsm, 1 },
	{"bss", bssAsm, 0},

	{"byte", byteAsm, MAX_OPERANDS },
	{"call", callAsm, 1 },
	{"char", charAsm, MAX_OPERANDS },

	{"cmp", cmpAsm, 3 },

	{"code", codeAsm, 0 },
	{"comment", commentAsm, -1 },
//	{"cp", cpAsm, 1 },
	{"cpu", cpuAsm, -1 },
	
	{"data", dataAsm, 0 },
	{"db", dbAsm, MAX_OPERANDS },
	{"dc", dcAsm, MAX_OPERANDS },

	{"di", diAsm, 0 },
	
	{"dw", dwAsm, MAX_OPERANDS },
	{"ei", eiAsm, 0 },
	{"end", endAsm, 0 },
	{"endm", endmAsm, 0 },

	{"extern", externAsm, -1 },

    {"fill", fillAsm, 2 },

	{"include", includeAsm, 1 },

	{"jal", jalAsm, 2 },
	{"jmp", jmpAsm, 1 },

    {"lc", lcAsm, 2 },
    {"lea", leaAsm, 2 },

    {"list", listAsm, 1 },

	{"lw", lwAsm, 2 },

	{"macro", macroAsm, -1 },
	{"message", messageAsm, 1 },

	{"neg", negAsm, 1 },

	{"nop", nopAsm, 0 },

	{"not", nopAsm, 1 },

	{"or", orAsm, 2 },
	
	{"org", orgAsm, 1 },

	{"public", publicAsm, -1 },

	{"ret", retAsm, 0 },
	{"ri", riAsm, 0 },
	{"rol", rolAsm, 1 },
	{"ror", rorAsm, 1 },
	{"rti", rtiAsm, 0 },
	{"sc", scAsm, 2 },
	{"shl", shlAsm, 1 },
	{"shr", shrAsm, 1 },
	{"sub", subAsm, 3 },
	{"subr", subrAsm, 2 },
	{"sw", swAsm, 2 },
	{"sys", sysAsm, 1 },
	{"trap", trapAsm, 1 },
	{"trs", trsAsm, 2 },
	{"tsr", tsrAsm, 2 },
	{"word", wordAsm, MAX_OPERANDS },
	{"xor", xorAsm, 2 },
};

OperandsButterfly operButterfly;

Cpu optabButterfly =
{
	"Butterfly", 32, 2, 38, sizeof(opsButterfly)/sizeof(Mne), opsButterfly, (Operands *)&operButterfly
};

