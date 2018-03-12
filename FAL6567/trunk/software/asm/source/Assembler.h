#pragma once

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <setjmp.h>
#include "MyString.h"
#include "debug.h"
#include "sym.h"
#include "HashTable.h"
#include "Macro.h"
#include "Rept.h"
#include "objfile.h"
#include "types.h"
#include "fstreamS19.h"
#include "buf.h"
#include "asmbuf.h"
#include "err.h"
#include "FileInfo.h"
#include "cpu.h"
#include "operand.h"
#include "counter.h"

#define MAXLINE   300
#define STRAREA   64000
#define MAXSYMS   4001
#define SRC_COL	  (getCpu()->src_col)

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
/*
#define AM_RN	1        // Rn
#define AM_REG	1
#define AM_IMM	2
#define AM_ABS	3
#define AM_IND  3        // [Rn]
#define AM_RIND	3
#define AM_DRIND	4       // d[Rn]

#define AM_NDX    8       // [Rn+Rn]
#define AM_ABS_SHORT 16      // [abs].b
#define AM_ABS_LONG  32      // [abs].w
#define AM_IMMEDIATE 64     // #
#define AM_SPR_RN	128
*/
#include "am.h"
#include "am6502.h"

// Processor 
#define PG_1		1

#define CODE_AREA    1
#define DATA_AREA    2
#define BSS_AREA     3
#define IDATA_AREA   2
#define UDATA_AREA   3  // BSS_AREA

#define tcmp()    TRUE

#define MACRO_PARM_MARKER       0x14    // Special character used to identify macro parameter

namespace RTFClasses
{
	extern Cpu optab6502;
	extern Cpu optabW65C02;
	extern Cpu optabW65C816S;
	extern Cpu optabFT832;
	extern Cpu optabFT833;
	extern Cpu optabRTF65002;
	extern Debug debug;

	class Assembler;
	extern Assembler theAssembler;

	class Assembler
	{
		static const char *verstr;
		static const char *verstr2;

		int m_argc;
		char **m_argv;
		char **m_envp;

		Cpu *cpu;

		char **progArg;
		int progArgc;
	public:
		int sol2;
		// user specified (command line options)
		int Processor;          // Processor to assemble for
	private:
		String gProcessor;
		String giProcessor;		// processor set by command line
		int OutputFormat;       // Output format (COFF,ELF,BIN)
		bool bObjOut;            // generate object records
		bool Debug;             // Debug indicator
		bool liston;            // generate a listing flag

		bool fListing;	// generate a listing flag
		bool fBinOut;	// generate binary output
		bool fSymOut;	// generate symbol table
		bool fSOut;		// generate S-file output
		bool fErrOut;
		bool bMemOut;			// output .mem file
		bool bVerOut;			// output verilog ROM listing

		bool ShowLines;         // show line numbers in listing file
		int verbose;            // verbosity
		__int8 fpFormat;			// floating point format

		// error handling
		char WarnLevel;         // error warning level
		int errorsDuringPass;			// number of errors in pass
		int errcount;
		int errors;             // number of errors logged
		int warnings;           // number of warnings logged
		int NumInsn;			// number of instructions processed
		__int64 ByteCount;			// count of number of instruction bytes
		__int64 CycleCount;		// count of number of clock cycles
		__int32 checksum;

		// processing
		int InComment;         // True if processing within comment
		int InComment2;
		bool InQuote;
		int CommentChar;        // character used to indicate comment

		int g_nops;			// number of operands

		int lineno;        // current assembler line
		int pass;          // assembler's current pass

		unsigned __int32 StartAddress;
		bool fStartDefined;
		bool fFirstCode;
		int InputLine;          // Overall input line number
		int OutputLine;
		char firstword;         // true if processing first word of opcode
		bool DoingDc;           // Indicates processing dc instruction
		bool ForceErr;

		// Macro handling
		bool CollectingMacro;    // TRUE if collecting macro lines
		String *parmlist[MAX_MACRO_PARMS];     // storage for macro parameters
		String macrobuf;		// working macro buffer
		int gNargs;             // number of macro arguments
		Macro gMacro;           // Current working macro
		Rept gRept;				// Current working repeat
		bool lineExpanded;

		Counter ProgramCounter; // current program location during assembly
		Counter BSSCounter;     // current uninitialized data address during assembly
		Counter DataCounter;	// current initialized data area during assembly
		char CurrentArea;		// current output area.
		int bOutOfPhase;
		bool bGen;				// output generation pass

		// binary code vars
		int SaveOpSize;                // Save area for operand size
		int SaveOpCode[11];            // Save area for operand codes.
		unsigned int wordop[20];       // parsed operand bit patterns
		int opsize;                    // Operand size

		//*** File Input/Output ***
		// Input
		FILE *ifp;              // input file
		AsmBuf *ibuf;			//input buffer with custom operations
		char *inptr;            // input pointer
		int FileNum;            // number of file
		int CurFileNum;         // Number of the current file
		int FileLevel;          // Level of included files

		// Output
		char ofname[MAXLINE];   // output file name.
		char fnameObj[MAXLINE];
		char fnameBin[MAXLINE];
		char fnameList[MAXLINE];
		char fnameMem[MAXLINE];
		char fnameVer[MAXLINE];
		char fnameVerDP[MAXLINE];
		char fnameSym[MAXLINE];
		char fnameS[MAXLINE];
		char fnameErr[MAXLINE];
		bool bFirstObj;          // flag to indicate if any object code has been output yet
		ObjFile ObjFilex;       // Area to build object records
		FILE *ofp;              // binary output file
		FILE *fpBin;
		FILE *fpList;
		FILE *fpMem;
		FILE *fpSym;
		FILE *fpVer;
		FILE *fpVerDP;
		fstreamS19 gSOut;			// S37 output generator
		FILE *fpErr;

		// Output formatting
//		char *sol;
		int sol;
		char ListLine[MAXLINE];
		int page;               // page number
		int PageLength;
		int PageWidth;
		int col;                // current column in source output
public:
		String lastLabel;
		bool bGlobalEquates;
		int gSzChar;                  // Operand size character.
private:
		SymbolTable *localSymTbl;
		SymbolTable *gSymbolTable;
		ExtRefTbl *extRefTbl;
		StructTbl *structTbl;
		String SearchList[500];
		int nSearchList;
		String appendText;
		String appendFiles;

		Declarator *headFreeLink;  // head of list of free links
		HashTable *macroTbl;
		HashTable *reptTbl;

		void setProcessor(String cpu);
		int getIdentifier(char *ptr, char **sptr, char **eptr);
		long getNumeric(char *ptr, char **eptr, int base); // get numeric value from input

		void GetCmdArgs();
		int parseCmdLine(int *);
		void Assemble(char *, char *);

		int CollectMacroLine();
		bool isEndOfComment();
		bool inBlockComment();
		void copyChToMacro(char ch);
		void SearchAndSub();
		int processLine();
		void processFile(char *, char *);
		void processMneumonic(Mne *optr);
		int run();

		// Routines
		// SHashVal HashFnc(SDef *);  //external
		int addsym(char *s, char len, long n);
		int fmt2bit(int);
		int condcode(char *s);

		// Output
		void emit(int size, unsigned __int64 data);  // output routines
		void emit0(void);
		int emitrest(void);
		int emits(int, unsigned __int64);
		int stdemit(char *, int, int, int, int);
		int stdemit1(int, int);
		void emit8Obj(unsigned int byte);	// emit to object file
		void emit8Bin(unsigned int byte);
		void emit8Mem(unsigned int byte);
		void emit8Verilog(unsigned int byte);
		void emit8VerilogDP(unsigned int byte);
		void emit8DoingDc(unsigned int byte);
		void emit8FirstListCol(unsigned int byte);
		void emit8ListCol(unsigned int byte);
		int par32(unsigned int);
		void flushStack2();
		void flushStack4();

		int getSzChar(void);
		int GetSzCode(int szChar);
		void StripComments(char *);
		void err(jmp_buf, int, ...);
		int fcmp(char *, Symbol *);
		int howbig(char);
		int invcc(char *);
		int issymbol(char *);
		int icmp(Symbol *, Symbol *);
		void label(char *, int);
		int IsReg(char *, int *);
		int IsSPRReg(char *, int *);
		void RestoreOps(void);
		int ReverseBits(int);
		int ReverseBitsByte(int);
		void SaveOps(void);
		int GetOperands();

		void displayHelp();
		bool validateRegistration();
		void openOutputStreams();
		void initializeForPass();

	public:
		FileInfo File[255];    // keeps a record of all files processed (for symbol table)
		String gOperand[MAX_OPERANDS];	// array of operands
		bool errtype;            // global error flag

	public:
		int main(int argc, char **argv, char **envp);
		int getArgc() { return m_argc; };
		char **getArgv() { return m_argv; };
		char **getEnvp() { return m_envp; };
		String getExeName() { 
               String aa;
               aa = m_argv[0];
               return aa; };

		// pseudo-op processing
		bool processPseudo(char *);
		void align();
		void bss();
		void code();
		void comment();
		void a_cpu();
		void data();
		void db(char sz);
		void dc(char sz);
		void end();
		void endm();
		void endr();
		int equ(char *iid);
		void a_extern();
		void fill();
		void include();
		void list();
		void lword();
		void macro();
		int macro2(char *);
		void rept();
		void message();
		void org();
		void a_public();

		Counter &getCounter(void);
		Counter &getProgramCounter() { return ProgramCounter; };
		char getCurrentArea() { return CurrentArea; };
		int getCurFilenum() { return CurFileNum; };
		int getCurLinenum() { return File[getCurFilenum()].LastLine; };
		int getLineno() { return lineno; };
		int getFileLevel() { return FileLevel; };
		SymbolTable *getLocalSymTbl() { return localSymTbl; };
		SymbolTable *getGlobalSymTbl() { return gSymbolTable; };
		__int8 getFpFormat() { return fpFormat; };
		int getPass() { return pass; };
		AsmBuf *getIBuf() { return ibuf; };
		void OutListLine(void);
		int listAddr();
		Cpu *getCpu() { return cpu; };
		FILE *getErrFp() { return fpErr; };
		bool isGenerationPass() { return bGen; };
		bool isForcedErr() { return ForceErr; };
		void incWarnings() { File[CurFileNum].warnings++; warnings++; };
		void incErrors() { File[CurFileNum].errors++; errors++; };
		void incErrorsDuringPass() { errorsDuringPass++; };
		int emit32(unsigned int word);
		void emit24(int word);
		void emit16(int word);
		void emit8(unsigned int byte);   // spits out a data byte to file/listing, increments counters
		bool isBlockComment2();
		bool isBlockComment1();
		int out8(Opa *o);
		int out16(Opa *o);
		int out24(Opa *o);
		int out32(Opa *o);
		int getStartOfLine() { return sol; };
		void setStartOfLine(int s) { sol = s; };
		void AddToSearchList();
		void ProcessUndefs();
		void processAppendFiles();
		void makeUnresolvedSymbolsGlobal(SymbolTable *tbl);
	};

	Cpu *getCpu();
}

extern "C" {
#undef min
int min(int, int);
}


//#define NOPS_6502	(sizeof(optab6502) / sizeof(SOp)) // number of mneumomics including psuedos
#define NOPS_WDC65C02	(sizeof(optabWDC65C02) / sizeof(SOp)) // number of mneumomics including psuedos
#define NOPS	NOPS_6502
//#define  NOPS	(sizeof(cpu) / sizeof(SOp)) // number of mneumomics including psuedos

