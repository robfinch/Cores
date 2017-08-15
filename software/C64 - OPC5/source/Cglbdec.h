#ifndef CGBLDEC_H
#define CGBLDEC_H

// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// C64 - 'C' derived language compiler
//  - 64 bit CPU
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//                                                                          
// ============================================================================
//
//#define DOTRACE	1
#ifdef DOTRACE
#define TRACE(x)	x
#else
#define TRACE(x)
#endif

extern int maxPn;
extern int hook_predreg;
extern int gCpu;
extern int regGP;
extern int regSP;
extern int regBP;
extern int regLR;
extern int regXLR;
extern int regPC;
extern int regCLP;
extern int regZero;
extern int regFirstParm;
extern int regLastParm;
extern int farcode;
extern int wcharSupport;
extern int verbose;
extern int use_gp;
extern int address_bits;
extern std::ifstream *ifs;
extern txtoStream ofs;
extern txtoStream lfs;
extern txtoStream dfs;
extern int mangledNames;
extern int sizeOfWord;
extern int sizeOfFP;
extern int sizeOfFPT;
extern int sizeOfFPD;
extern int sizeOfFPQ;

extern GlobalDeclaration *gd;
extern bool firstLineOfFunc;
extern char last_rem[132];

/*
extern FILE             *input,
                        *list,
                        *output;
*/
extern FILE *outputG;
extern int incldepth;
extern int              lineno;
extern int              nextlabel;
extern int              lastch;
extern int              lastst;
extern char             lastid[128];
extern char             lastkw[128];
extern char             laststr[MAX_STLP1];
extern int64_t	ival;
extern double           rval;
extern char float_precision;
extern int parseEsc;
//extern FloatTriple      FAC1,FAC2;

extern TABLE            gsyms[257],
                        lsyms;
extern TABLE            tagtable;
extern SYM              *lasthead;
extern struct slit      *strtab;
extern struct clit		*casetab;
extern int              lc_static;
extern int              lc_auto;
extern int				lc_thread;
extern Statement     *bodyptr;       /* parse tree for function */
extern int              global_flag;
extern TABLE            defsyms;
extern int64_t          save_mask;      /* register save mask */
extern int64_t          fpsave_mask;
extern int				bsave_mask;
extern int uctran_off;
extern int isKernel;
extern int isPascal;
extern int isOscall;
extern int isInterrupt;
extern int isTask;
extern int isNocall;
extern bool isRegister;
extern int asmblock;
extern int optimize;
extern int opt_noregs;
extern int opt_nopeep;
extern int opt_noexpr;
extern int opt_nocgo;
extern bool opt_allowregs;
extern int exceptions;
extern int mixedSource;
extern SYM *currentFn;
extern int iflevel;
extern int foreverlevel;
extern int looplevel;
extern int loopexit;
extern int regmask;
extern int bregmask;
extern Statement *currentStmt;
extern bool dogen;

extern TYP *stdint;
extern TYP *stduint;
extern TYP *stdlong;
extern TYP *stdulong;
extern TYP *stdshort;
extern TYP *stdushort;
extern TYP *stdchar;
extern TYP *stduchar;
extern TYP *stdbyte;
extern TYP *stdubyte;
extern TYP *stdstring;
extern TYP *stddbl;
extern TYP *stdtriple;
extern TYP *stdflt;
extern TYP *stddouble;
extern TYP *stdfunc;
extern TYP *stdexception;
extern TYP *stdconst;
extern TYP *stdquad;

extern std::string *declid;
extern Compiler compiler;

extern OCODE *peep_head;
extern OCODE *peep_tail;

// Analyze.c
extern short int csendx;
extern CSEList CSETable;

#endif
