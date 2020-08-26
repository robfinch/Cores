/* -----------------------------------------------------------------------------
   
   (C) 1999 Bird Computer

   Function :      Header file for 68000 cross assembler.

   Changes
           Author      : R. Finch
           Date        : 90/02/14
           Release     : 1.0
           Description : new module

----------------------------------------------------------------------------- */

//#define DEMO

#include <setjmp.h>
#include <debug.h>

//#ifndef SYM_H
//#include "sym.h"
//#endif

#ifndef MACRO_H
#include "macro.h"
#endif

#ifndef OBJFILE_HPP
#include <objfile.hpp>
#endif

#ifndef SOUT_H
#include "SOut.h"
#endif

#ifndef BUF_HPP
#include <buf.hpp>
#endif

#include "asmbuf.h"

#ifndef ERR_H
#include "err.h"
#endif

#ifndef SECTION_TABLE_H
#include "SectionTable.h"
#endif

#ifdef E
#undef E
#endif
#ifdef I
#undef I
#endif
#ifdef ALLOC
#  define E
#  define I(x) x
#else
#  define E extern
#  define I(x)
#endif

// operand type processing
typedef struct
{
	int type;
	int pat;
	int reg1;
	int reg2;
	long imm;
	unsigned int k_factor : 1;
	unsigned int k_IsReg : 1;
	int k_reg;
	long k_imm;				// immediate k-factor value
	// extension word info
	unsigned int ireg : 4;	// index register
	unsigned int full : 1;	// full extension word format indicator
	unsigned int sc : 2;	// scale code
	unsigned int bs : 1;	// base suppressed
	unsigned int is : 1;	// index suppressed
	unsigned int bdc : 2;	// base displacement code
	__int32 bd;		// base displacement
	__int32 od;		// outer displacement
} SOpType;


#define MAXLINE   300
#define STRAREA   64000
#define MAXSYMS   4001

#ifndef TRUE
#define TRUE   1
#define FALSE  0
#endif

// floating point format
#define FP_IEEE 0		// IEEE standard floating-point
#define FP_FFP  1		// Motorola Fast-Floating-Point format

#define  MAXBUF  15000   /* Maximum file buffer size */
#define  NUMERRORS  28   /* number of error messages */
#define  MAXRELOC 300   // Maximum number of relocatable addresses.
#define MAX_MACRO_PARMS    16    // Maximum number of parameters to a macro
#define MAX_NAME_LEN 16
#define MAX_OPERANDS 60

// address mode codes
#define AM_DR        1        // Dn
#define AM_AR        2        // An
#define AM_AR_IND    4        // (An)
#define AM_AR_POST   8        // (An)+
#define AM_AR_PRE    16       // -(An)
#define AM_AR_DISP   32       // d16(An)
#define AM_AR_NDX    64       // d8(An, Xn.s)
#define AM_ABS_SHORT 128      // (abs).w

#define AM_ABS_LONG  256      // (abs).l
#define AM_PC_REL    512      // d16(PC)
#define AM_PC_NDX    1024     // d8(PC, Xn.s)
#define AM_IMMEDIATE 2048     // #

#define AM_MEM       4096     // ([ (not implemented)
#define AM_MEM_PC	 8192
#define AM_KFACT	(1 << 14)
#define AM_BITFLD	32768
#define AM_FPR		(1 << 16)	// FPn

// Composite
#define AM_RN		(AM_DR | AM_AR)
#define AM_ANY		0x3fff
#define AM_CTL		0x37e4
#define AM_CTLDR	(AM_CTL | AM_DR)
#define AM_ALT		0x11ff
#define AM_CTLALT	(AM_CTL & AM_ALT)	// 0x11e4
#define AM_CALTDR	((AM_CTL & AM_ALT) | AM_DR)	// 0x11e5
#define AM_CALTPRE	(AM_CTLALT | AM_AR_PRE)	// 0x11f4
#define AM_CTLPRE	(AM_CTL | AM_AR_PRE)	// 0x37f4
#define AM_CTLPOST	(AM_CTL | AM_AR_POST)	// 0x37ec
#define AM_DATA		0x3ffd
#define AM_DATA1	0x37fd
#define AM_DATALT	(AM_ALT & AM_DATA) // 0x11fd
#define AM_MEMORY	0x3ffc
#define AM_MEMALT	(AM_MEMORY & AM_ALT)	// 0x11fc
#define AM_MEMALT_DR	(AM_MEMALT | AM_DR)

#define M_BD   8
#define M_BR   4
#define M_XN   2
#define M_OD   1

// Processor 
#define PL_0	1	// 68000/68008
#define PL_1	2	// 68010
#define PL_2	4	// 68020
#define PL_3	8	// 68030
#define PL_4	16	// 68040
#define PL_6    32  // 68060
#define PL_EC40	64  // 68EC040
#define PL_LC40 2048	// 68LC040
#define PL_EC30 128	// 68EC030
#define PL_CPU32	256		// CPU32
#define PL_F	512	// 68881/68882
#define PL_M	1024	// 68851
#define PL_FT	2048
#define PL_ALL	(PL_0 | PL_1 | PL_2 | PL_3 | PL_4 | PL_CPU32 | PL_EC30 | PL_EC40 | PL_LC40)
#define PL_01	(PL_0 | PL_1)
#define PL_23   (PL_2 | PL_3)
#define PL_1234 (PL_1 | PL_2 | PL_3 | PL_4)
#define PL_234	(PL_2 | PL_3 | PL_4)
#define PL_1234C (PL_1234 | PL_CPU32)
#define PL_234C (PL_234 | PL_CPU32)
#define PL_4F	(PL_4 | PL_F)

// MMU 68030
#define MMU_PSR	0x6000
#define MMU_TT0	0x0800
#define MMU_TT1 0x0c00
// MMU 68EC030
#define MMU_ACUSR 0x6000
#define MMU_AC0	0x0400
#define MMU_AC1	0x0c00
// MMU 68030 or 68851
#define MMU_SRP	0x4800
#define MMU_CRP	0x4c00
#define MMU_TC	0x4000
// MMU 68851
#define MMU_DRP 0x4400
#define MMU_CAL	0x5000
#define MMU_VAL	0x5400
#define MMU_SCC 0x5800
#define MMU_AC	0x5c00
#define	MMU_BAD0 0x7000
#define	MMU_BAD1 0x7004
#define MMU_BAD2 0x7008
#define	MMU_BAD3 0x700C
#define	MMU_BAD4 0x7010
#define	MMU_BAD5 0x7014
#define	MMU_BAD6 0x7018
#define	MMU_BAD7 0x701C
#define MMU_BAC0 0x7400
#define	MMU_BAC1 0x7404
#define	MMU_BAC2 0x7408
#define	MMU_BAC3 0x740C
#define	MMU_BAC4 0x7410
#define	MMU_BAC5 0x7414
#define	MMU_BAC6 0x7418
#define	MMU_BAC7 0x741C
#define MMU_PCSR 0x6400

// Function macros

#define bit76(a)		(((a) & 3) << 6)
#define RegFld(a)       ((a) & 7)
#define RegFld2(a)      (((a) & 7) << 9)
#define RegFld4(a)      (((a) & 7) << 4)
#define RegFld5(a)      (((a) & 7) << 5)
#define RegFld6(a)		(((a) & 7) << 6)
#define RegFld7(a)		(((a) & 7) << 7)
#define ModFld(a)       (((a) & 7) << 3)
#define RegFld10(a)		(((a) & 7) << 10)
#define RegFld12(a)		(((a) & 15) << 12)
#define RegFld12a(a)	(((a) & 7) << 12)

#define IScaleBits(a)   (((a) & 3) << 9)
#define IADBit(a)       (((a) & 1) << 15)
#define IRegBits(a)     (((a) & 7) << 12)
#define IWLBit(a)       (((a) & 1) << 11)
#define IFIBit(a)       (((a) & 1) << 8)
#define IDispBits(a)    ((a) & 0xff)
#define IBSBit(a)       (((a) & 1) << 7)
#define IISBit(a)       (((a) & 1) << 6)
#define IBDBits(a)      (((a) & 3) << 4)
#define IIISBits(a)     ((a) & 7)

#define OModeBits(a)    (((a) & 7) << 3)
#define ORegBits(a)     ((a) & 7)

#define CODE_AREA    1
#define DATA_AREA    2
#define BSS_AREA     3
#define IDATA_AREA   2
#define UDATA_AREA   3  // BSS_AREA

#define tcmp()    TRUE
#define IsLegalReg(c)   ((c) >= '0' && (c) <= '7')

//#define BYTE    'b'
//#define WORD    'w'
//#define LONG    'l'

#define MACRO_PARM_MARKER       0x14    // Special character used to identify macro parameter


long GetNumeric(char *ptr, char **eptr, int base); // get numeric value from input


// Used for recording information about files as they are encountered
typedef struct
{
   char *name;       // File name
   int LastLine;     // Line number processed
   int errors;       // Number of errors.
   int warnings;     // Number of warnings
   FILE *fp;			// file pointer for end pseudo-op
   CSymbolTbl *lst;  // local symbol table
} SFileInfo;


// user specified (command line options)
E int Processor;          // Processor to assemble for
E int gProcessor;
E int giProcessor;			// processor set by command line
E int OutputFormat;       // Output format (COFF,ELF,BIN)
E char ObjOut;            // generate object records
E char Debug;             // Debug indicator
E char liston;            // generate a listing flag
E __int8 fListing;		  // generate a listing flag
E __int8 fBinOut;		// generate binary output
E __int8 fSymOut;		// generate symbol table
E __int8 fSOut;			// generate S-file output
E __int8 fErrOut;
E __int8 fVerilogOut;
E char ShowLines;         // show line numbers in listing file
E int verbose;            // verbosity
E __int8 fpFormat;			// floating point format

E int fp_cpid;			// floating point coprocessor id
E int mmu_cpid;			// memory management unit coprocessor id

// error handling
E char WarnLevel;         // error warning level
E int errtype;            // global error flag
E int errors;             // number of errors logged
E int errors2;			// number of errors in pass
E int errcount;
E int warnings;           // number of warnings logged
E int PhaseErr;

// processing
E char InComment;         // True if processing within comment
E char InComment2;
E char InQuote;
E int CommentChar;        // character used to indicate comment

E int g_nops;			// number of operands
E SOpType gOpType;

extern int lineno;        // current assembler line
extern int pass;          // assembler's current pass
extern int lastpass;

E unsigned __int32 StartAddress;
E __int8 fStartDefined;
E __int8 fFirstCode;
E int InputLine;          // Overall input line number
E int OutputLine;
E char firstword;         // true if processing first word of opcode
E char DoingDef;           // Indicates processing def instruction
E char ForceErr;
E CSymbolTbl *LocalSymTbl;
E char current_label[NAME_MAX*2+1];

// Macro handling
E int CollectingMacro;    // TRUE if collecting macro lines
E char *parmlist[MAX_MACRO_PARMS];     // storage for macro parameters
E char macrobuf[2048];    // working macro buffer
E int macrobufndx;        // index to current position in macro buffer
E long MacroCounter;      // a count of macros used for macro locals
E int gNargs;             // number of macro arguments
E char gMacroName[NAME_MAX];     // Current working macro name
E CMacro gMacro;           // Current working macro

//extern long ProgramCounter;     // current program location during assembly
//extern long BSSCounter;         // current uninitialized data address during assembly
//extern long DataCounter;        // current initialized data area during assembly
//extern char CurrentSection;		// current output area.

// binary code vars
E int SaveOpSize;                // Save area for operand size
E int SaveOpCode[11];            // Save area for operand codes.
E unsigned int wordop[20];       // parsed operand bit patterns
E int opsize;                    // Operand size
E char gSzChar;                  // Operand size character.
E char *gOperand[MAX_OPERANDS];  // array of pointers to operands

//*** File Input/Output ***
// Input
E FILE *ifp;              // input file
E CAsmBuf ibuf;           // input buffer with custom operations
E char inbuf[20000];      // input buffer (containing multiple line substitutions)
E char *inptr;            // input pointer
E int FileNum;            // number of file
E int CurFileNum;         // Number of the current file
E int FileLevel;          // Level of included files
E SFileInfo File[255];    // keeps a record of all files processed (for symbol table)

// Output
E char ofname[MAXLINE];   // output file name.
E char fnameObj[MAXLINE];
E char fnameBin[MAXLINE];
E char fnameVer[MAXLINE];
E char fnameList[MAXLINE];
E char fnameSym[MAXLINE];
E char fnameS[MAXLINE];
E char fnameErr[MAXLINE];
E char fnameMem[MAXLINE];
E char FirstObj;          // flag to indicate if any object code has been output yet
E CObjFile ObjFile;       // Area to build object records
E FILE *ofp;              // binary output file
E FILE *fpBin;
E FILE *fpVerilog;
E FILE *fpList;
E FILE *fpSym;
E CSOut gSOut;			// S37 output generator
E FILE *fpErr;
E FILE *fpMem;

// Output formatting
E char *sol;
E char ListLine[MAXLINE];
E int page;               // page number
E int PageLength;
E int PageWidth;
E int col;                // current column in source output
extern char *verstr;
extern char *verstr2;
extern SectionTable SectionTbl;
extern CSymbolTbl *SymbolTbl;
extern CExtRefTbl *ExtRefTbl;
extern CStructTbl *StructTbl;

extern CLink *HeadFreeLink;  // head of list of free links
extern CMacroTbl *MacroTbl;
extern CSymbol *lastsym;

extern short int CurrentSection();

int main(int, char *[]);
void GetCmdArgs();
void ParseCmdLine(char *);
void Assemble(char *, char *);

extern "C" {
void displayHelp();
void displayStartupMessage();
};
void displaySymbolTable();
void outListLine();
void SearchAndSub();
int PrcLine(int, char *);
int PrcFile(char *);
int run();

// Routines
// SHashVal HashFnc(SDef *);  //external
int addsym(char *s, char len, long n);
int bwl2bit(int);
int fmt2bit(int);
int condcode(char *s);

// Output
int emit(int size, unsigned __int64 data);  // output routines
void emitnull(void);
int emitw(unsigned int word);
void emitb(unsigned int byte);   // spits out a data byte to file/listing, increments counters
void emitimm(char);
int emitrest(void);
int emits(int, unsigned __int64);
int stdemit(char *, int, int, int, int);
int stdemit1(int, int);
void flushSOut(void);

void outListLine(void);

long Counter(void);
int GetSzChar(void);
long sz46(char);
void StripComments(char *);
void err(jmp_buf, int, ...);
int fcmp(char *, CSymbol *);
int GetCReg(char *, int *);
int GetMMUReg(char *, int *);
int howbig(char);
int invcc(char *);
int issymbol(char *);
int icmp(CSymbol *, CSymbol *);
void label(char *, int);
int IsAReg(char *, int *);
int IsDReg(char *, int *);
int IsDRegPair(char *, int *, int *);
int IsRegIndPair(char *, int *, int *);
int IsRegList(char *, int *);
int IsFPReg(char *, int *);
int IsFPCR(char *);
int IsFPCRList(char *);
int IsFPRegList(char *);
int IsFPRegPair(char *, int *, int *);
int OpType(char *, int *, long);
void OutListLine(void);
void RestoreOps(void);
int ReverseBits(int);
int ReverseBitsByte(int);
void SaveOps(void);
int GetOperands();

int min(int, int);

// control registers
typedef struct 
{
	char *name;
	unsigned __int16 num;
	unsigned __int16 PrcLevel;
} SCReg;

// opcode control class
typedef struct _tagSOp
{
   char *mneu;						// mneumonic
   int (*func)(struct _tagSOp *);	// processing function
   unsigned __int16 ocode;			// object code base
   unsigned __int16 ocode2;			// second opcode
   unsigned __int16 PrcLevel;		// Processor level of instruction
   __int16 NumOps;					// Number of operands.
} SOp;


// Opcode processing
int m_align(SOp *);
int m_abcd(SOp *);
int m_add(SOp *);
int m_adda(SOp *);
int m_addi(SOp *);
int m_addq(SOp *);
int m_addx(SOp *);
int m_and(SOp *);
int m_andi(SOp *);
int m_shift(SOp *);
int m_branch(SOp *);
int m_bitop(SOp *);
int m_bfchg(SOp *);
int m_bftst(SOp *);
int m_bfexts(SOp *);
int m_bfins(SOp *);
int m_bkpt(SOp *);
int m_branch(SOp *);
int m_bss(SOp *);
int m_byte(SOp *);
int m_callm(SOp *);
int m_cas(SOp *);
int m_cas2(SOp *);
int m_chk(SOp *);
int m_chk2(SOp *);
int m_cinv(SOp *);
int m_clr(SOp *);
int m_cmp(SOp *);
int m_cmpm(SOp *);
int m_code(SOp *);
int m_comment(SOp *);
int m_cpbcc(SOp *);
int m_cpdbcc(SOp *);
int m_cpgen(SOp *);
int m_cprestore(SOp *);
int m_cpsave(SOp *);
int m_cpscc(SOp *);
int m_cptrapcc(SOp *);
int m_cpu(SOp *);
int m_data(SOp *);
int m_dbranch(SOp *);
int m_dc(SOp *);
int m_divide(SOp *);
int m_end(SOp *);
int m_endm(SOp *);
int m_ends(SOp *);
int m_eor(SOp *);
int m_equ(char *);
int m_even(SOp *);
int m_exg(SOp *);
int m_ext(SOp *);
int m_extb(SOp *);
int m_extern(SOp *);

// floating point
int m_fabs(SOp *);
int m_fbcc(SOp *);
int m_fdbcc(SOp *);
int m_fmove(SOp *);
int m_fmovecr(SOp *);
int m_fmovem(SOp *);
int m_fnop(SOp *);
int m_frestore(SOp *);
int m_fsave(SOp *);
int m_fscc(SOp *);
int m_fsincos(SOp *);
int m_ftrapcc(SOp *);
int m_ftst(SOp *);

int m_fill(SOp *);
int m_ffp(SOp *);
int m_include(SOp *);
int m_jump(SOp *);
int m_lea(SOp *);
int m_link(SOp *);
int m_lpstop(SOp *);
int m_lst_on(SOp *);
int m_macro(SOp *);
int m_mul(SOp *);
int m_lword(SOp *);
int m_message(SOp *);
int m_move(SOp *);
int m_move16(SOp *);
int m_movea(SOp *);
int m_movec(SOp *);
int m_movem(SOp *);
int m_movep(SOp *);
int m_moveq(SOp *);
int m_moves(SOp *);
int m_nbcd(SOp *);
int m_org(SOp *);

// mmu
int m_pbcc(SOp *);
int m_pdbcc(SOp *);
int m_pflush(SOp *);
int m_pflusha(SOp *);
int m_pflushn(SOp *);
int m_pflushr(SOp *);
int m_pload(SOp *);
int m_pmove(SOp *);
int m_prestore(SOp *);
int m_psave(SOp *);
int m_pscc(SOp *);
int m_ptest(SOp *);
int m_ptrapcc(SOp *);
int m_pvalid(SOp *);

int m_pea(SOp *);
int m_public(SOp *);
int m_rtd(SOp *);
int m_rtm(SOp *);
int m_section(SOp *);
int m_set(SOp *);
int m_size(SOp *);
int m_stop(SOp *);
int m_struct(SOp *);
int m_swap(SOp *);
int m_tbls(SOp *);
int m_trap(SOp *);
int m_trapcc(SOp *);
int m_tst(SOp *);
int m_unlk(SOp *);
int m_unpk(SOp *);
int m_unmacr(SOp *);
int m_word(SOp *);
int m_wordout(SOp *);


/* ----------------------------------

   68000 opcode

   oooooooooommmrrr   structure
   15             0   bit

   Indexing extension

   arrrw000dddddddd
   15             0
---------------------------------- */

// Routines
#ifdef ALLOC
SCReg creg[] =
{
	"SFC",	0,		PL_1234C | PL_EC30 | PL_EC40 | PL_LC40,
	"DFC",	1,		PL_1234C | PL_EC30 | PL_EC40 | PL_LC40,
	"USP",	0x800,	PL_1234C | PL_EC30 | PL_EC40 | PL_LC40,
	"VBR",	0x801,	PL_1234C | PL_EC30 | PL_EC40 | PL_LC40,
	"CACR", 2,		PL_234 | PL_EC30 | PL_EC40 | PL_LC40,
	"CAAR", 0x802,	PL_234 | PL_EC30 | PL_EC40 | PL_LC40,
	"MSP",	0x803,	PL_234 | PL_EC30 | PL_EC40 | PL_LC40,
	"ISP",	0x804,	PL_234 | PL_EC30 | PL_EC40 | PL_LC40,
	"TC",	3,		PL_4 | PL_EC40 | PL_LC40,
	"ITT0", 4,		PL_4 | PL_LC40,
	"ITT1", 5,		PL_4 | PL_LC40,
	"DTT0", 6,		PL_4 | PL_LC40,
	"DTT1", 7,		PL_4 | PL_LC40,
	"MMUSR", 0x805, PL_4 | PL_EC40 | PL_LC40,
	"URP",	0x806,	PL_4 | PL_EC40 | PL_LC40,
	"SRP",	0x807,	PL_4 | PL_EC40 | PL_LC40,
	// 68EC040 only
	"IACR0", 4,		PL_EC40,
	"IACR1", 5,		PL_EC40,
	"DACR0", 6,		PL_EC40,
	"DACR1", 7,		PL_EC40
};

SCReg mmureg[] = 
{
	"SRP", 0x4800, (PL_M | PL_3),
	"CRP", 0x4c00, (PL_M | PL_3),
	"TC",  0x4000, (PL_M | PL_3),
	"PSR", 0x6000, (PL_M | PL_3),
	"TT0", 0x0800, PL_3,
	"TT1", 0x0c00, PL_3,
	"ACUSR", 0x6000, PL_EC30,
	"AC0", 0x0400, PL_EC30,
	"AC1", 0x0c00, PL_EC30,
	"DRP", 0x4400, PL_M,
	"CAL", 0x5000, PL_M,
	"VAL", 0x5400, PL_M,
	"SCC", 0x5800, PL_M,
	"AC",  0x5c00, PL_M,
	"BAD0", 0x7000, PL_M,
	"BAD1", 0x7004, PL_M,
	"BAD2", 0x7008, PL_M,
	"BAD3", 0x700C, PL_M,
	"BAD4", 0x7010, PL_M,
	"BAD5", 0x7014, PL_M,
	"BAD6", 0x7018, PL_M,
	"BAD7", 0x701C, PL_M,
	"BAC0", 0x7400, PL_M,
	"BAC1", 0x7404, PL_M,
	"BAC2", 0x7408, PL_M,
	"BAC3", 0x740C, PL_M,
	"BAC4", 0x7410, PL_M,
	"BAC5", 0x7414, PL_M,
	"BAC6", 0x7418, PL_M,
	"BAC7", 0x741C, PL_M,
	"PCSR", 0x6400, PL_M
};

/* --------------------------------------------------------------
      Opcode / Pseudo op table. MUST BE IN ALPHEBETICAL ORDER.
-------------------------------------------------------------- */

SOp optab[] =
{
// Opcode      Processing  Bit Pattern Proc lev Num Ops
   ".align",   m_align,    0,      0,      PL_ALL,  1,
   ".bss",     m_bss,      0,      0,      PL_ALL,  0,
   ".code",    m_code,     0,      0,      PL_ALL,  0,
   ".cpu",     m_cpu,      0,      0,      PL_ALL,  0,
   ".data",    m_data,     0,      0,      PL_ALL,  0,
   ".dc",      m_dc,       0,      0,      PL_ALL,  0,
   ".end", 	   m_end,      0,      0,      PL_ALL,  0,
   ".even",    m_even,     0,      0,      PL_ALL,  0,
   ".ffp",     m_ffp,      0,      0,      PL_ALL,  0,
   ".fill",    m_fill,     0,      0,      PL_ALL,  2,
   ".include", m_include,  0,      0,      PL_ALL,  1,
   ".message", m_message,  0,      0,      PL_ALL,  1,
   ".section", m_section,  0,      0,      PL_ALL,  1,
   "abcd",     m_abcd,     0xc100, 0x0000, PL_ALL,  2,
   "add",      m_add,      0xd000, 0,      PL_ALL,  2,
   "adda",     m_adda,     0xd0c0, 0,      PL_ALL,  2,
   "addi",     m_addi,     0x0600, 0,      PL_ALL,  2,
   "addq",     m_addq,     0x5000, 0,      PL_ALL,  2,
   "addx",     m_addx,     0xd100, 0,      PL_ALL,  2,
   "align",    m_align,    0,      0,      PL_ALL,  1,
   "and",      m_and,      0xc000, 0,      PL_ALL,  2,
   "andi",     m_andi,     0x0200, 0,      PL_ALL,  2,
   "asl",      m_shift,    0xe100, 0,      PL_ALL,  0,
   "asr",      m_shift,    0xe000, 0,      PL_ALL,  0,
   "bcc",      m_branch,   0x6400, 0,      PL_ALL,  1,
   "bchg",     m_bitop,    0x0040, 0,      PL_ALL,  2,
   "bclr",     m_bitop,    0x0080, 0,      PL_ALL,  2,
   "bcs",      m_branch,   0x6500, 0,      PL_ALL,  1,
   "beq",      m_branch,   0x6700, 0,      PL_ALL,  1,
   "bfchg",    m_bfchg,    0xeac0, 0,      PL_234 | PL_EC30 | PL_EC40 | PL_LC40,  1,
   "bfclr",    m_bfchg,    0xecc0, 0,      PL_234 | PL_EC30 | PL_EC40 | PL_LC40,  1,
   "bfexts",   m_bfexts,   0xebc0, 0,      PL_234 | PL_EC30 | PL_EC40 | PL_LC40,  2,
   "bfextu",   m_bfexts,   0xe9c0, 0,      PL_234 | PL_EC30 | PL_EC40 | PL_LC40,  2,
   "bfffo",    m_bfexts,   0xedc0, 0,      PL_234 | PL_EC30 | PL_EC40 | PL_LC40,  2,
   "bfins",    m_bfins,    0xefc0, 0,      PL_234 | PL_EC30 | PL_EC40 | PL_LC40,  2,
   "bfset",    m_bfchg,    0xeec0, 0,      PL_234 | PL_EC30 | PL_EC40 | PL_LC40,  1,
   "bftst",    m_bftst,    0xe8c0, 0,      PL_234 | PL_EC30 | PL_EC40 | PL_LC40,  1,
   "bge",      m_branch,   0x6c00, 0,      PL_ALL,       1,
   "bgnd",     m_wordout,  0x4afa, 0,      PL_CPU32,     0,
   "bgt",      m_branch,   0x6e00, 0,      PL_ALL,       1,
   "bhi",      m_branch,   0x6200, 0,      PL_ALL,       1,
   "bhs",      m_branch,   0x6400, 0,      PL_ALL,       1,
   "bkpt",     m_bkpt,     0x4848, 0,      PL_1234C | PL_EC30 | PL_EC40 | PL_LC40,     1,
   "ble",      m_branch,   0x6f00, 0,      PL_ALL,       1,
   "blo",      m_branch,   0x6500, 0,      PL_ALL,       1,
   "bls",      m_branch,   0x6300, 0,      PL_ALL,       1,
   "blt",      m_branch,   0x6d00, 0,      PL_ALL,       1,
   "bmi",      m_branch,   0x6b00, 0,      PL_ALL,       1,
   "bne",      m_branch,   0x6600, 0,      PL_ALL,       1,
   "bpl",      m_branch,   0x6a00, 0,      PL_ALL,       1,
   "bra",      m_branch,   0x6000, 0,      PL_ALL,       1,
   "bset",     m_bitop,    0x00c0, 0,      PL_ALL,       2,
   "bsr",      m_branch,   0x6100, 0,      PL_ALL,       1,
   "bss",      m_bss,      0,      0,      PL_ALL,       0,
   "bt",       m_branch,   0x6000, 0,      PL_ALL,       1,
   "btst",     m_bitop,    0x0000, 0,      PL_ALL,       2,
   "bvc",      m_branch,   0x6800, 0,      PL_ALL,       1,
   "bvs",      m_branch,   0x6900, 0,      PL_ALL,       1,
   "byte",     m_byte,     0,      0,      PL_ALL,       0,
   "callm",    m_callm,    0x06c0, 0,      PL_2,         2,
   "cas",      m_cas,      0x08c0, 0,      PL_234 | PL_EC30 | PL_EC40 | PL_LC40,	     3,
   "cas2",     m_cas2,     0x08fc, 0,      PL_234 | PL_EC30 | PL_EC40 | PL_LC40,		 3,
   "chk",      m_chk,      0x4180, 0,      PL_ALL,       2,
   "chk2",     m_chk2,     0x00c0, 0,      PL_234C | PL_EC30 | PL_EC40 | PL_LC40,      2,
   "cinva",    m_cinv,     0xf418, 0,      PL_4 | PL_LC40,         1,
   "cinvl",    m_cinv,     0xf408, 0,      PL_4 | PL_LC40,	     2,
   "cinvp",    m_cinv,     0xf410, 0,      PL_4 | PL_LC40,		 2,
   "clr",      m_clr,      0x4200, 0,      PL_ALL,       1,
   "cmp",      m_cmp,      0xb000, 0,      PL_ALL,       2,
   	// changed opcode from 00c0 to 0080 so chk2 can distinguish
   "cmp2",     m_chk2,     0x0080, 0,      PL_234C | PL_EC30 | PL_EC40 | PL_LC40,      2,
   "cmpa",     m_adda,     0xb0c0, 0,      PL_ALL,       2,
   "cmpi",     m_addi,     0x0c00, 0,      PL_ALL,       2,
   "cmpm",     m_cmpm,     0xb108, 0,      PL_ALL,       2,
   "code",     m_code,     0,      0,      PL_ALL,       0,
   "comment",  m_comment,  0,      0,      PL_ALL,       0,

   "cpbcc",    m_cpbcc,    0xf080, 0,      PL_23 | PL_EC30,        0,
   "cpdbcc",   m_cpdbcc,   0xf048, 0,      PL_23 | PL_EC30,        0,
   "cpgen",    m_cpgen,    0xf000, 0,      PL_23 | PL_EC30,        0,
   "cprestore",m_cprestore,0xf140, 0,      PL_23 | PL_EC30,        2,
   "cpsave",   m_cpsave,   0xf100, 0,      PL_23 | PL_EC30,        2,
   "cpscc",    m_cpscc,    0xf040, 0,      PL_23 | PL_EC30,        0,
   "cptrapcc", m_cptrapcc, 0xf078, 0,      PL_23 | PL_EC30,        0,

   "cpu",      m_cpu,      0,      0,      PL_ALL,       0,
   "cpusha",   m_cinv,     0xf438, 0,      PL_4 | PL_LC40,         1,
   "cpushl",   m_cinv,     0xf428, 0,      PL_4 | PL_LC40,         2,
   "cpushp",   m_cinv,     0xf430, 0,      PL_4 | PL_LC40,         2,
   "data",     m_data,     0,      0,      PL_ALL,       0,
   "dbcc",     m_dbranch,  0x54c8, 0,      PL_ALL,       2,
   "dbcs",     m_dbranch,  0x55c8, 0,      PL_ALL,       2,
   "dbeq",     m_dbranch,  0x57c8, 0,      PL_ALL,       2,
   "dbf",      m_dbranch,  0x51c8, 0,      PL_ALL,       2,
   "dbge",     m_dbranch,  0x5cc8, 0,      PL_ALL,       2,
   "dbgt",     m_dbranch,  0x5ec8, 0,      PL_ALL,       2,
   "dbhi",     m_dbranch,  0x52c8, 0,      PL_ALL,       2,
   "dbhs",     m_dbranch,  0x54c8, 0,      PL_ALL,       2,
   "dble",     m_dbranch,  0x5fc8, 0,      PL_ALL,       2,
   "dblo",     m_dbranch,  0x55c8, 0,      PL_ALL,       2,
   "dbls",     m_dbranch,  0x53c8, 0,      PL_ALL,       2,
   "dblt",     m_dbranch,  0x5dc8, 0,      PL_ALL,       2,
   "dbmi",     m_dbranch,  0x5bc8, 0,      PL_ALL,       2,
   "dbne",     m_dbranch,  0x56c8, 0,      PL_ALL,       2,
   "dbpl",     m_dbranch,  0x5ac8, 0,      PL_ALL,       2,
   "dbra",     m_dbranch,  0x51c8, 0,      PL_ALL,       2,
   "dbt",      m_dbranch,  0x50c8, 0,      PL_ALL,       2,
   "dbvc",     m_dbranch,  0x58c8, 0,      PL_ALL,       2,
   "dbvs",     m_dbranch,  0x59c8, 0,      PL_ALL,       2,
   "dc",       m_dc,       0,      0,      PL_ALL,       0,
   "dcb",      m_fill,     0,      0,      PL_ALL,       2,
   "divs",     m_divide,   0x81c0, 0x0800, PL_ALL,       2,
   "divsl",    m_divide,   0x4c40, 0x0800, PL_234C | PL_EC30 | PL_EC40 | PL_LC40,      2,
   "divu",     m_divide,   0x80c0, 0x0000, PL_ALL,       2,
   "divul",    m_divide,   0x4c40, 0x0000, PL_234C | PL_EC30 | PL_EC40 | PL_LC40,      2,
   "ds",       m_dc,       0,      0,      PL_ALL,       0,
   "end", 	   m_end,      0,      0,      PL_ALL,       0,
   "endm",     m_endm,     0,      0,      PL_ALL,       0,
   "ends",     m_ends,     0,      0,      PL_ALL,       1,
   "eor",      m_eor,      0xb100, 0,      PL_ALL,       2,
   "eori",     m_andi,     0x0a00, 0,      PL_ALL,       2,
   "even",     m_even,     0,      0,      PL_ALL,       0,
   "exg",      m_exg,      0xc100, 0,      PL_ALL,       2,
   "ext",      m_ext,      0x4880, 0,      PL_ALL,       1,
   "extb",     m_extb,     0x49C0, 0,      PL_234 | PL_EC30 | PL_EC40 | PL_LC40,       1,
   "extern",   m_extern,   0,      0,      PL_ALL,      -1,

   "fabs",     m_fabs,     0xf000, 0x0018, PL_4F,  0,
   "facos",    m_fabs,	   0xf000, 0x001c, PL_4F,        0,
   "fadd",     m_fabs,     0xf000, 0x0022, PL_4F,        2,
   "fasin",    m_fabs,	   0xf000, 0x000c, PL_4F,        0,
   "fatan",    m_fabs,	   0xf000, 0x000a, PL_4F,        0,
   "fatanh",   m_fabs,	   0xf000, 0x000d, PL_4F,        0,

   "fbeq",     m_fbcc,     0xf081, 0,      PL_4F,        1,
   "fbf",      m_fbcc,     0xf080, 0,      PL_4F,        1,
   "fbge",     m_fbcc,     0xf093, 0,      PL_4F,        1,
   "fbgl",     m_fbcc,     0xf096, 0,      PL_4F,        1,
   "fbgle",    m_fbcc,     0xf097, 0,      PL_4F,        1,
   "fbgt",     m_fbcc,     0xf092, 0,      PL_4F,        1,
   "fble",     m_fbcc,     0xf095, 0,      PL_4F,        1,
   "fblt",     m_fbcc,     0xf094, 0,      PL_4F,        1,
   "fbne",     m_fbcc,     0xf08e, 0,      PL_4F,        1,
   "fbnge",    m_fbcc,     0xf09c, 0,      PL_4F,        1,
   "fbngl",    m_fbcc,     0xf099, 0,      PL_4F,        1,
   "fbngle",   m_fbcc,     0xf098, 0,      PL_4F,        1,
   "fbngt",    m_fbcc,     0xf09d, 0,      PL_4F,        1,
   "fbnle",    m_fbcc,     0xf09a, 0,      PL_4F,        1,
   "fbnlt",    m_fbcc,     0xf09b, 0,      PL_4F,        1,
   "fboge",    m_fbcc,     0xf083, 0,      PL_4F,        1,
   "fbogl",    m_fbcc,     0xf086, 0,      PL_4F,        1,
   "fbogt",    m_fbcc,     0xf082, 0,      PL_4F,        1,
   "fbole",    m_fbcc,     0xf085, 0,      PL_4F,        1,
   "fbolt",    m_fbcc,     0xf084, 0,      PL_4F,        1,
   "fbor",     m_fbcc,     0xf087, 0,      PL_4F,        1,
   "fbra",     m_fbcc,     0xf08f, 0,      PL_4F,        1,
   "fbseq",    m_fbcc,     0xf091, 0,      PL_4F,        1,
   "fbsf",     m_fbcc,     0xf090, 0,      PL_4F,        1,
   "fbsne",    m_fbcc,     0xf09e, 0,      PL_4F,        1,
   "fbst",     m_fbcc,     0xf09f, 0,      PL_4F,        1,
   "fbt",      m_fbcc,     0xf08f, 0,      PL_4F,        1,
   "fbueq",    m_fbcc,     0xf089, 0,      PL_4F,        1,
   "fbuge",    m_fbcc,     0xf08b, 0,      PL_4F,        1,
   "fbugt",    m_fbcc,     0xf08a, 0,      PL_4F,        1,
   "fbule",    m_fbcc,     0xf08d, 0,      PL_4F,        1,
   "fbult",    m_fbcc,     0xf08c, 0,      PL_4F,        1,
   "fbun",     m_fbcc,     0xf088, 0,      PL_4F,        1,

   "fcmp",     m_fabs,     0xf000, 0x0038, PL_4F,        2,
   "fcos",     m_fabs,	   0xf000, 0x001d, PL_4F,        0,
   "fcosh",    m_fabs,	   0xf000, 0x0019, PL_4F,        0,
	

   "fdadd",    m_fabs,     0xf000, 0x0066, PL_4,         2,
   "fdabs",    m_fabs,     0xf000, 0x005c, PL_4,         0,

   "fdbeq",    m_fdbcc,    0xf048, 0x0001, PL_4F,        2,
   "fdbf",     m_fdbcc,    0xf048, 0x0000, PL_4F,        2,
   "fdbge",    m_fdbcc,    0xf048, 0x0013, PL_4F,        2,
   "fdbgl",    m_fdbcc,    0xf048, 0x0016, PL_4F,        2,
   "fdbgle",   m_fdbcc,    0xf048, 0x0017, PL_4F,        2,
   "fdbgt",    m_fdbcc,    0xf048, 0x0012, PL_4F,        2,
   "fdble",    m_fdbcc,    0xf048, 0x0015, PL_4F,        2,
   "fdblt",    m_fdbcc,    0xf048, 0x0014, PL_4F,        2,
   "fdbne",    m_fdbcc,    0xf048, 0x000e, PL_4F,        2,
   "fdbnge",   m_fdbcc,    0xf048, 0x001c, PL_4F,        2,
   "fdbngl",   m_fdbcc,    0xf048, 0x0019, PL_4F,        2,
   "fdbngle",  m_fdbcc,    0xf048, 0x0018, PL_4F,        2,
   "fdbngt",   m_fdbcc,    0xf048, 0x001d, PL_4F,        2,
   "fdbnle",   m_fdbcc,    0xf048, 0x001a, PL_4F,        2,
   "fdbnlt",   m_fdbcc,    0xf048, 0x001b, PL_4F,        2,
   "fdboge",   m_fdbcc,    0xf048, 0x0003, PL_4F,        2,
   "fdbogl",   m_fdbcc,    0xf048, 0x0006, PL_4F,        2,
   "fdbogt",   m_fdbcc,    0xf048, 0x0002, PL_4F,        2,
   "fdbole",   m_fdbcc,    0xf048, 0x0005, PL_4F,        2,
   "fdbolt",   m_fdbcc,    0xf048, 0x0004, PL_4F,        2,
   "fdbor",    m_fdbcc,    0xf048, 0x0007, PL_4F,        2,
   "fdbra",    m_fdbcc,    0xf048, 0x0000, PL_4F,        2,
   "fdbseq",   m_fdbcc,    0xf048, 0x0011, PL_4F,        2,
   "fdbsf",    m_fdbcc,    0xf048, 0x0010, PL_4F,        2,
   "fdbsne",   m_fdbcc,    0xf048, 0x001e, PL_4F,        2,
   "fdbst",    m_fdbcc,    0xf048, 0x001f, PL_4F,        2,
   "fdbt",     m_fdbcc,    0xf048, 0x000f, PL_4F,        2,
   "fdbueq",   m_fdbcc,    0xf048, 0x0009, PL_4F,        2,
   "fdbuge",   m_fdbcc,    0xf048, 0x000b, PL_4F,        2,
   "fdbugt",   m_fdbcc,    0xf048, 0x000a, PL_4F,        2,
   "fdbule",   m_fdbcc,    0xf048, 0x000d, PL_4F,        2,
   "fdbult",   m_fdbcc,    0xf048, 0x000c, PL_4F,        2,
   "fdbun",    m_fdbcc,    0xf048, 0x0008, PL_4F,        2,

   "fddiv",    m_fabs,     0xf000, 0x0064, PL_4,         2,
   "fdiv",     m_fabs,     0xf000, 0x0020, PL_4F,        2,
   "fdmove",   m_fmove,    0xf000, 0x0044, PL_4,         2,
   "fdmul",    m_fabs,     0xf000, 0x0067, PL_4,         2,
   "fdneg",    m_fabs,     0xf000, 0x005e, PL_4,         0,
   "fdsqrt",   m_fabs,     0xf000, 0x0045, PL_4,         0,
   "fdsub",    m_fabs,     0xf000, 0x006c, PL_4,         2,
   "fetox",    m_fabs,     0xf000, 0x0010, PL_4F,        0,
   "fetoxm1",  m_fabs,     0xf000, 0x0008, PL_4F,        0,

   "ffp",      m_ffp,      0,      0,      PL_ALL,       0,

   "fgetexp",  m_fabs,     0xf000, 0x001e, PL_4F,        0,
   "fgetman",  m_fabs,     0xf000, 0x001f, PL_4F,        0,
   "fill",     m_fill,     0,      0,      PL_ALL,       2,
   "fint",     m_fabs,     0xf000, 0x0001, PL_4F,        0,
   "fintrz",   m_fabs,     0xf000, 0x0003, PL_4F,        0,
   "flog10",   m_fabs,     0xf000, 0x0015, PL_4F,        0,
   "flog2",    m_fabs,     0xf000, 0x0016, PL_4F,        0,
   "flogn",    m_fabs,     0xf000, 0x0014, PL_4F,        0,
   "flognp1",  m_fabs,     0xf000, 0x0006, PL_4F,        0,
   "fmod",     m_fabs,     0xf000, 0x0021, PL_4F,        0,
   "fmove",    m_fmove,    0xf000, 0x0000, PL_4F,        2,
   "fmovecr",  m_fmovecr,  0xf000, 0x5c00, PL_4F,        2,
   "fmovem",   m_fmovem,   0xf000, 0x8000, PL_4F,        2,
   "fmul",     m_fabs,     0xf000, 0x0023, PL_4F,        2,
   "fneg",     m_fabs,     0xf000, 0x001a, PL_4F,        0,
   "fnop",     m_fnop,     0xf800, 0x0000, PL_4F,        0,
   "frem",     m_fabs,     0xf000, 0x0025, PL_4F,        2,
   "frestore", m_frestore, 0xf140, 0x0000, PL_4F,        1,
   "fsabs",    m_fabs,     0xf000, 0x0058, PL_4,         0,
   "fsadd",    m_fabs,     0xf000, 0x0062, PL_4,         2,
   "fsave",	   m_fsave,    0xf100, 0x0000, PL_4F,        1,
   "fscale",   m_fabs,     0xf000, 0x0026, PL_4F,        2,
   "fsdiv",    m_fabs,     0xf000, 0x0060, PL_4,         2,

   "fseq",     m_fscc,     0xf040, 0x0001, PL_4F,        1,
   "fsf",      m_fscc,     0xf040, 0x0000, PL_4F,        1,
   "fsge",     m_fscc,     0xf040, 0x0013, PL_4F,        1,
   "fsgl",     m_fscc,     0xf040, 0x0016, PL_4F,        1,
   "fsgldiv",  m_fabs,     0xf000, 0x0024, PL_4F,        2,
   "fsgle",    m_fscc,     0xf040, 0x0017, PL_4F,        1,
   "fsglmul",  m_fabs,     0xf000, 0x0027, PL_4F,        2,
   "fsgt",     m_fscc,     0xf040, 0x0012, PL_4F,        1,
   "fsin",     m_fabs,     0xf000, 0x000e, PL_4F,        0,
   "fsincos",  m_fsincos,  0xf000, 0x0030, PL_4F,        2,
   "fsinh",    m_fabs,     0xf000, 0x0002, PL_4F,        0,
   "fsle",     m_fscc,     0xf040, 0x0015, PL_4F,        1,
   "fslt",     m_fscc,     0xf040, 0x0014, PL_4F,        1,
   "fsmove",   m_fmove,    0xf000, 0x0040, PL_4,         2,
   "fsmul",    m_fabs,     0xf000, 0x0063, PL_4,         2,
   "fsne",     m_fscc,     0xf040, 0x000e, PL_4F,        1,
   "fsneg",    m_fabs,     0xf000, 0x005a, PL_4,         0,
   "fsnge",    m_fscc,     0xf040, 0x001c, PL_4F,        1,
   "fsngl",    m_fscc,     0xf040, 0x0019, PL_4F,        1,
   "fsngle",   m_fscc,     0xf040, 0x0018, PL_4F,        1,
   "fsngt",    m_fscc,     0xf040, 0x001d, PL_4F,        1,
   "fsnle",    m_fscc,     0xf040, 0x001a, PL_4F,        1,
   "fsnlt",    m_fscc,     0xf040, 0x001b, PL_4F,        1,
   "fsoge",    m_fscc,     0xf040, 0x0003, PL_4F,        1,
   "fsogl",    m_fscc,     0xf040, 0x0006, PL_4F,        1,
   "fsogt",    m_fscc,     0xf040, 0x0002, PL_4F,        1,
   "fsole",    m_fscc,     0xf040, 0x0005, PL_4F,        1,
   "fsolt",    m_fscc,     0xf040, 0x0004, PL_4F,        1,
   "fsor",     m_fscc,     0xf040, 0x0007, PL_4F,        1,
   "fsqrt",    m_fabs,     0xf000, 0x0004, PL_4F,        0,
   "fsra",     m_fscc,     0xf040, 0x0000, PL_4F,        1,
   "fsseq",    m_fscc,     0xf040, 0x0011, PL_4F,        1,
   "fssf",     m_fscc,     0xf040, 0x0010, PL_4F,        1,
   "fssne",    m_fscc,     0xf040, 0x001e, PL_4F,        1,
   "fssqrt",   m_fabs,     0xf000, 0x0041, PL_4,         0,
   "fsst",     m_fscc,     0xf040, 0x001f, PL_4F,        1,
   "fssub",    m_fabs,     0xf000, 0x0068, PL_4,         2,
   "fst",      m_fscc,     0xf040, 0x000f, PL_4F,        1,
   "fsub",     m_fabs,     0xf000, 0x0028, PL_4F,        2,
   "fsueq",    m_fscc,     0xf040, 0x0009, PL_4F,        1,
   "fsuge",    m_fscc,     0xf040, 0x000b, PL_4F,        1,
   "fsugt",    m_fscc,     0xf040, 0x000a, PL_4F,        1,
   "fsule",    m_fscc,     0xf040, 0x000d, PL_4F,        1,
   "fsult",    m_fscc,     0xf040, 0x000c, PL_4F,        1,
   "fsun",     m_fscc,     0xf040, 0x0008, PL_4F,        1,
   "ftan",     m_fabs,     0xf000, 0x000f, PL_4F,        0,
   "ftanh",    m_fabs,     0xf000, 0x0009, PL_4F,        0,
   "ftentox",  m_fabs,     0xf000, 0x0012, PL_4F,        0,

   "ftrapeq",  m_ftrapcc,  0xf078, 0x0001, PL_4F,        0,
   "ftrapf",   m_ftrapcc,  0xf078, 0x0000, PL_4F,        0,
   "ftrapge",  m_ftrapcc,  0xf078, 0x0013, PL_4F,        0,
   "ftrapgl",  m_ftrapcc,  0xf078, 0x0016, PL_4F,        0,
   "ftrapgle", m_ftrapcc,  0xf078, 0x0017, PL_4F,        0,
   "ftrapgt",  m_ftrapcc,  0xf078, 0x0012, PL_4F,        0,
   "ftraple",  m_ftrapcc,  0xf078, 0x0015, PL_4F,        0,
   "ftraplt",  m_ftrapcc,  0xf078, 0x0014, PL_4F,        0,
   "ftrapne",  m_ftrapcc,  0xf078, 0x000e, PL_4F,        0,
   "ftrapnge", m_ftrapcc,  0xf078, 0x001c, PL_4F,        0,
   "ftrapngl", m_ftrapcc,  0xf078, 0x0019, PL_4F,        0,
   "ftrapngle",m_ftrapcc,  0xf078, 0x0018, PL_4F,        0,
   "ftrapngt", m_ftrapcc,  0xf078, 0x001d, PL_4F,        0,
   "ftrapnle", m_ftrapcc,  0xf078, 0x001a, PL_4F,        0,
   "ftrapnlt", m_ftrapcc,  0xf078, 0x001b, PL_4F,        0,
   "ftrapoge", m_ftrapcc,  0xf078, 0x0003, PL_4F,        0,
   "ftrapogl", m_ftrapcc,  0xf078, 0x0006, PL_4F,        0,
   "ftrapogt", m_ftrapcc,  0xf078, 0x0002, PL_4F,        0,
   "ftrapole", m_ftrapcc,  0xf078, 0x0005, PL_4F,        0,
   "ftrapolt", m_ftrapcc,  0xf078, 0x0004, PL_4F,        0,
   "ftrapor",  m_ftrapcc,  0xf078, 0x0007, PL_4F,        0,
   "ftrapseq", m_ftrapcc,  0xf078, 0x0011, PL_4F,        0,
   "ftrapsf",  m_ftrapcc,  0xf078, 0x0010, PL_4F,        0,
   "ftrapsne", m_ftrapcc,  0xf078, 0x001e, PL_4F,        0,
   "ftrapst",  m_ftrapcc,  0xf078, 0x001f, PL_4F,        0,
   "ftrapt",   m_ftrapcc,  0xf078, 0x000f, PL_4F,        0,
   "ftrapueq", m_ftrapcc,  0xf078, 0x0009, PL_4F,        0,
   "ftrapuge", m_ftrapcc,  0xf078, 0x000b, PL_4F,        0,
   "ftrapugt", m_ftrapcc,  0xf078, 0x000a, PL_4F,        0,
   "ftrapule", m_ftrapcc,  0xf078, 0x000d, PL_4F,        0,
   "ftrapult", m_ftrapcc,  0xf078, 0x000c, PL_4F,        0,
   "ftrapun",  m_ftrapcc,  0xf078, 0x0008, PL_4F,        0,

   "ftst",     m_ftst,     0xf000, 0x003a, PL_4F,        1,
   "ftwotox",  m_fabs,     0xf000, 0x0011, PL_4F,        0,

   "illegal",  m_wordout,  0x4afc, 0,      PL_ALL,       0,
   "include",  m_include,  0,      0,      PL_ALL,       1,
   "jmp",      m_jump,     0x4ec0, 0,      PL_ALL,       1,
   "jsr",      m_jump,     0x4e80, 0,      PL_ALL,       1,
   "lea",      m_lea,      0x41c0, 0,      PL_ALL,       2,
   "link",     m_link,     0x4e50, 0,      PL_ALL,       2,
   "list",     m_lst_on,   0,      0,      PL_ALL,       1,
   "lpstop",   m_lpstop,   0xf800, 0x01c0, PL_CPU32,     1,
   "lsl",      m_shift,    0xe108, 0,      PL_ALL,       0,
   "lsr",      m_shift,    0xe008, 0,      PL_ALL,       0,
   "lword",    m_lword,    0,      0,      PL_ALL,       0,
   "macro",    m_macro,    0,      0,      PL_ALL,      -1,
   "message",  m_message,  0,      0,      PL_ALL,       1,
   "move",     m_move,     0x0000, 0,      PL_ALL,       2,
   "move16",   m_move16,   0xf600, 0,      PL_4 | PL_EC40 | PL_LC40,         2,
   "movea",    m_movea,    0x2040, 0,      PL_ALL,       2,
   "movec",    m_movec,    0x4e7a, 0,      PL_1234C | PL_EC30 | PL_EC40 | PL_LC40,     2,
   "movem",    m_movem,    0x4880, 0,      PL_ALL,       2,
   "movep",    m_movep,    0x0108, 0,      PL_ALL,       2,
   "moveq",    m_moveq,    0x7000, 0,      PL_ALL,       2,
   "moves",    m_moves,    0x0e00, 0,      PL_1234C | PL_EC30 | PL_EC40 | PL_LC40,     2,
   "muls",     m_mul,      0xc1c0, 0x0800, PL_ALL,       2,
   "mulu",     m_mul,      0xc0c0, 0,      PL_ALL,       2,
   "nbcd",     m_nbcd,     0x4800, 0,      PL_ALL,       1,
   "neg",      m_clr,      0x4400, 0,      PL_ALL,       1,
   "negx",     m_clr,      0x4000, 0,      PL_ALL,       1,
   "nop",      m_wordout,  0x4e71, 0,      PL_ALL,       0,
   "not",      m_clr,      0x4600, 0,      PL_ALL,       1,
   "or",       m_and,      0x8000, 0,      PL_ALL,       2,
   "org",      m_org,      0,      0,      PL_ALL,       1,
   "ori",      m_andi,     0x0000, 0,      PL_ALL,       2,
   "pack",     m_unpk,     0x8140, 0,      PL_234 | PL_EC30 | PL_EC40 | PL_LC40,	     3,

   "pbac",     m_pbcc,     0xf087, 0,      PL_M,         1,
   "pbas",     m_pbcc,     0xf086, 0,      PL_M,         1,
   "pbbc",     m_pbcc,     0xf081, 0,      PL_M,         1,
   "pbbs",     m_pbcc,     0xf080, 0,      PL_M,         1,
   "pbcc",     m_pbcc,     0xf08f, 0,      PL_M,         1,
   "pbcs",     m_pbcc,     0xf08e, 0,      PL_M,         1,
   "pbgc",     m_pbcc,     0xf08d, 0,      PL_M,         1,
   "pbgs",     m_pbcc,     0xf08c, 0,      PL_M,         1,
   "pbic",     m_pbcc,     0xf08b, 0,      PL_M,         1,
   "pbis",     m_pbcc,     0xf08a, 0,      PL_M,         1,
   "pblc",     m_pbcc,     0xf083, 0,      PL_M,         1,
   "pbls",     m_pbcc,     0xf082, 0,      PL_M,         1,
   "pbsc",     m_pbcc,     0xf085, 0,      PL_M,         1,
   "pbss",     m_pbcc,     0xf084, 0,      PL_M,         1,
   "pbwc",     m_pbcc,     0xf089, 0,      PL_M,         1,
   "pbws",     m_pbcc,     0xf088, 0,      PL_M,         1,

   "pdbac",    m_pdbcc,    0xf048, 0x0007, PL_M,         2,
   "pdbas",    m_pdbcc,    0xf048, 0x0006, PL_M,         2,
   "pdbbc",    m_pdbcc,    0xf048, 0x0001, PL_M,         2,
   "pdbbs",    m_pdbcc,    0xf048, 0x0000, PL_M,         2,
   "pdbcc",    m_pdbcc,    0xf048, 0x000f, PL_M,         2,
   "pdbcs",    m_pdbcc,    0xf048, 0x000e, PL_M,         2,
   "pdbgc",    m_pdbcc,    0xf048, 0x000d, PL_M,         2,
   "pdbgs",    m_pdbcc,    0xf048, 0x000c, PL_M,         2,
   "pdbic",    m_pdbcc,    0xf048, 0x000b, PL_M,         2,
   "pdbis",    m_pdbcc,    0xf048, 0x000a, PL_M,         2,
   "pdblc",    m_pdbcc,    0xf048, 0x0003, PL_M,         2,
   "pdbls",    m_pdbcc,    0xf048, 0x0002, PL_M,         2,
   "pdbsc",    m_pdbcc,    0xf048, 0x0005, PL_M,         2,
   "pdbss",    m_pdbcc,    0xf048, 0x0004, PL_M,         2,
   "pdbwc",    m_pdbcc,    0xf048, 0x0009, PL_M,         2,
   "pdbws",    m_pdbcc,    0xf048, 0x0008, PL_M,         2,

   "pea",      m_pea,      0x4840, 0,      PL_ALL,       1,

   "pflush",   m_pflush,   0xf000, 0x3000, (PL_3 | PL_4 | PL_M | PL_EC40 | PL_LC40), 0,
   "pflusha",  m_pflusha,  0,      0,      (PL_3 | PL_4 | PL_M | PL_EC40 | PL_LC40), 0,
   "pflushan", m_wordout,  0xf510, 0,      PL_4 | PL_EC40 | PL_LC40,         0,
   "pflushn",  m_pflushn,  0xf500, 0,      PL_4 | PL_EC40 | PL_LC40,         0,
   "pflushr",  m_pflushr,  0xf000, 0xa000, PL_M,         1,
   "pflushs",  m_pflush,   0xf000, 0x3200, PL_M,         0,
   "ploadr",   m_pload,    0xf000, 0x2200, (PL_3 | PL_M), 2,
   "ploadw",   m_pload,    0xf000, 0x2000, (PL_3 | PL_M), 2,
   "pmove",    m_pmove,    0xf000, 0x0000, PL_3 | PL_EC30 | PL_M,  2,
   "pmovefd",  m_pmove,    0xf000, 0x0100, PL_3 | PL_EC30,         2,
   "prestore", m_prestore, 0xf140, 0,      PL_M,         1,

   "psac",	   m_pscc,     0xf040, 0x0007, PL_M,         1,
   "psas",     m_pscc,     0xf040, 0x0006, PL_M,         1,
   "psave",    m_psave,    0xf100, 0,      PL_M,         1,
   "psbc",     m_pscc,     0xf040, 0x0001, PL_M,         1,
   "psbs",     m_pscc,     0xf040, 0x0000, PL_M,         1,
   "pscc",     m_pscc,     0xf040, 0x000f, PL_M,         1,
   "pscs",     m_pscc,     0xf040, 0x000e, PL_M,         1,
   "psgc",     m_pscc,     0xf040, 0x000d, PL_M,         1,
   "psgs",     m_pscc,     0xf040, 0x000c, PL_M,         1,
   "psic",     m_pscc,     0xf040, 0x000b, PL_M,         1,
   "psis",     m_pscc,     0xf040, 0x000a, PL_M,         1,
   "pslc",     m_pscc,     0xf040, 0x0003, PL_M,         1,
   "psls",     m_pscc,     0xf040, 0x0002, PL_M,         1,
   "pssc",     m_pscc,     0xf040, 0x0005, PL_M,         1,
   "psss",     m_pscc,     0xf040, 0x0004, PL_M,         1,
   "pswc",     m_pscc,     0xf040, 0x0009, PL_M,         1,
   "psws",     m_pscc,     0xf040, 0x0008, PL_M,         1,

   "ptestr",   m_ptest,    0xf000, 0x8200, (PL_3 | PL_4 | PL_M | PL_EC30 | PL_EC40 | PL_LC40), 0,
   "ptestw",   m_ptest,    0xf000, 0x8000, (PL_3 | PL_4 | PL_M | PL_EC30 | PL_EC40 | PL_LC40), 0,

   "ptrapac",  m_ptrapcc,  0xf078, 0x0007, PL_M,         0,
   "ptrapas",  m_ptrapcc,  0xf078, 0x0006, PL_M,         0,
   "ptrapbc",  m_ptrapcc,  0xf078, 0x0001, PL_M,         0,
   "ptrapbs",  m_ptrapcc,  0xf078, 0x0000, PL_M,         0,
   "ptrapcc",  m_ptrapcc,  0xf078, 0x000f, PL_M,         0,
   "ptrapcs",  m_ptrapcc,  0xf078, 0x000e, PL_M,         0,
   "ptrapgc",  m_ptrapcc,  0xf078, 0x000d, PL_M,         0,
   "ptrapgs",  m_ptrapcc,  0xf078, 0x000c, PL_M,         0,
   "ptrapic",  m_ptrapcc,  0xf078, 0x000b, PL_M,         0,
   "ptrapis",  m_ptrapcc,  0xf078, 0x000a, PL_M,         0,
   "ptraplc",  m_ptrapcc,  0xf078, 0x0003, PL_M,         0,
   "ptrapls",  m_ptrapcc,  0xf078, 0x0002, PL_M,         0,
   "ptrapsc",  m_ptrapcc,  0xf078, 0x0005, PL_M,         0,
   "ptrapss",  m_ptrapcc,  0xf078, 0x0004, PL_M,         0,
   "ptrapwc",  m_ptrapcc,  0xf078, 0x0009, PL_M,         0,
   "ptrapws",  m_ptrapcc,  0xf078, 0x0008, PL_M,         0,

   "public",   m_public,   0,      0,      PL_ALL,      -1,
   "pvalid",   m_pvalid,   0xf000, 0x2400, PL_M,         2,
   "reset",    m_wordout,  0x4e70, 0,      PL_ALL,       0,
   "rol",      m_shift,    0xe118, 0,      PL_ALL,       0,
   "ror",      m_shift,    0xe018, 0,      PL_ALL,       0,
   "roxl",     m_shift,    0xe110, 0,      PL_ALL,       0,
   "roxr",     m_shift,    0xe010, 0,      PL_ALL,       0,
   "rtd",      m_rtd,      0x4e74, 0,      PL_1234C | PL_EC30 | PL_EC40 | PL_LC40,     1,
   "rte",      m_wordout,  0x4e73, 0,      PL_ALL,       0,
   "rtm",      m_rtm,      0x06c0, 0,      PL_2,         0,
   "rtr",      m_wordout,  0x4e77, 0,      PL_ALL,       0,
   "rts",      m_wordout,  0x4e75, 0,      PL_ALL,       0,
   "sbcd",     m_abcd,     0x8100, 0,      PL_ALL,       2,
   "scc",      m_set,      0x54c0, 0,      PL_ALL,       0,
   "scs",      m_set,      0x55c0, 0,      PL_ALL,       0,
   "section",  m_section,  0,      0,      PL_ALL,       1,
   "seq",      m_set,      0x57c0, 0,      PL_ALL,       0,
   "sf",       m_set,      0x51c0, 0,      PL_ALL,       0,
   "sge",      m_set,      0x5cc0, 0,      PL_ALL,       0,
   "sgt",      m_set,      0x5ec0, 0,      PL_ALL,       0,
   "shi",      m_set,      0x52c0, 0,      PL_ALL,       0,
   "shs",      m_set,      0x54c0, 0,      PL_ALL,       0,
   "size",     m_size,     0,      0,      PL_ALL,       0,
   "sle",      m_set,      0x5fc0, 0,      PL_ALL,       0,
   "slo",      m_set,      0x55c0, 0,      PL_ALL,       0,
   "sls",      m_set,      0x53c0, 0,      PL_ALL,       0,
   "slt",      m_set,      0x5dc0, 0,      PL_ALL,       0,
   "smi",      m_set,      0x5bc0, 0,      PL_ALL,       0,
   "sne",      m_set,      0x56c0, 0,      PL_ALL,       0,
   "spl",      m_set,      0x5ac0, 0,      PL_ALL,       0,
   "st",       m_set,      0x50c0, 0,      PL_ALL,       0,
   "stop",     m_stop,     0x4e72, 0,      PL_ALL,       1,
   "struct",   m_struct,   0,      0,      PL_ALL,       1,
   "sub",      m_add,      0x9000, 0,      PL_ALL,       2,
   "suba",     m_adda,     0x90c0, 0,      PL_ALL,       2,
   "subi",     m_addi,     0x0400, 0,      PL_ALL,       2,
   "subq",     m_addq,     0x5100, 0,      PL_ALL,       2,
   "subx",     m_addx,     0x9100, 0,      PL_ALL,       2,
   "svc",      m_set,      0x58c0, 0,      PL_ALL,       0,
   "svs",      m_set,      0x59c0, 0,      PL_ALL,       0,
   "swap",     m_swap,     0x4840, 0,      PL_ALL,       1,
   "tas",      m_nbcd,     0x4ac0, 0,      PL_ALL,       1,
   "tbls",     m_tbls,     0xf800, 0x0800, PL_CPU32,     2,
   "tblsn",    m_tbls,     0xf800, 0x0c00, PL_CPU32,     2,
   "tblu",     m_tbls,     0xf800, 0x0000, PL_CPU32,     2,
   "tblun",    m_tbls,     0xf800, 0x0400, PL_CPU32,     2,
   "text",     m_code,     0,      0,      PL_ALL,       0,
   "trap",     m_trap,     0x4e40, 0,      PL_ALL,       1,
   "trapcc",   m_trapcc,   0x54f8, 0,      PL_234C | PL_EC30 | PL_EC40 | PL_LC40,      0,
   "trapcs",   m_trapcc,   0x55f8, 0,      PL_234C | PL_EC30 | PL_EC40 | PL_LC40,      0,
   "trapeq",   m_trapcc,   0x57f8, 0,      PL_234C | PL_EC30 | PL_EC40 | PL_LC40,      0,
   "trapf",    m_trapcc,   0x51f8, 0,      PL_234C | PL_EC30 | PL_EC40 | PL_LC40,      0,
   "trapge",   m_trapcc,   0x5cf8, 0,      PL_234C | PL_EC30 | PL_EC40 | PL_LC40,      0,
   "trapgt",   m_trapcc,   0x5ef8, 0,      PL_234C | PL_EC30 | PL_EC40 | PL_LC40,      0,
   "traphi",   m_trapcc,   0x52f8, 0,      PL_234C | PL_EC30 | PL_EC40 | PL_LC40,      0,
   "traphs",   m_trapcc,   0x54f8, 0,      PL_234C | PL_EC30 | PL_EC40 | PL_LC40,      0,
   "traple",   m_trapcc,   0x5ff8, 0,      PL_234C | PL_EC30 | PL_EC40 | PL_LC40,      0,
   "traplo",   m_trapcc,   0x55f8, 0,      PL_234C | PL_EC30 | PL_EC40 | PL_LC40,      0,
   "trapls",   m_trapcc,   0x53f8, 0,      PL_234C | PL_EC30 | PL_EC40 | PL_LC40,      0,
   "traplt",   m_trapcc,   0x5df8, 0,      PL_234C | PL_EC30 | PL_EC40 | PL_LC40,      0,
   "trapmi",   m_trapcc,   0x5bf8, 0,      PL_234C | PL_EC30 | PL_EC40 | PL_LC40,      0,
   "trapne",   m_trapcc,   0x56f8, 0,      PL_234C | PL_EC30 | PL_EC40 | PL_LC40,      0,
   "trappl",   m_trapcc,   0x5af8, 0,      PL_234C | PL_EC30 | PL_EC40 | PL_LC40,      0,
   "trapt",    m_trapcc,   0x50f8, 0,      PL_234C | PL_EC30 | PL_EC40 | PL_LC40,      0,
   "trapv",    m_wordout,  0x4e76, 0,      PL_ALL,       0,
   "trapvc",   m_trapcc,   0x58f8, 0,      PL_234C | PL_EC30 | PL_EC40 | PL_LC40,      0,
   "trapvs",   m_trapcc,   0x59f8, 0,      PL_234C | PL_EC30 | PL_EC40 | PL_LC40,	     0,
   "tst",      m_tst,      0x4a00, 0,      PL_ALL,       1,
   "unlk",     m_unlk,     0x4e58, 0,      PL_ALL,       1,
   "unpk",     m_unpk,     0x8180, 0,      PL_234 | PL_EC30 | PL_EC40 | PL_LC40,       3,
   "word",     m_word,     0,      0,      PL_ALL,       0
};

#else
extern SOp optab[];
extern SCReg creg[];
extern SCReg mmureg[];
#endif

#define  NOPS	(sizeof(optab) / sizeof(SOp)) // number of mneumomics including psuedos
#define N_CREG 20	//	(sizeof(creg) / sizeof(SCReg)) Why doesn't this work ?
#define N_MMUREG 31	// (sizeof(mmureg) / sizeof(SCReg)) Why doesn't this work ?


