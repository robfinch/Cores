// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// CC64 - 'C' derived language compiler
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
#include "stdafx.h"
/*      global definitions      */

Compiler compiler;
CPU cpu;
int pass;
int maxPn = 15;
int gCpu = 7;
int regPC = 254;
int regSP = 31;
int regFP = 30;
int regLR = 29;
int regXLR = 28;
int regGP = 27;
int regTP = 26;
int regCLP = 25;                // class pointer
int regPP = 56;					// program pointer
int regZero = 0;
int regFirstTemp = 3;
int regLastTemp = 10;
int regXoffs = 55;
int regFirstRegvar = 11;
int regLastRegvar = 16;
int regFirstArg = 17;
int regLastArg = 21;
int regAsm = 23;
int pregSP = 31;
int pregFP = 30;
int pregLR = 29;
int pregXLR = 28;
int pregGP = 27;
int pregTP = 26;
int pregCLP = 25;                // class pointer
int pregPP = 24;					// program pointer
int pregZero = 0;
int pregFirstTemp = 3;
int pregLastTemp = 9;
int pregFirstRegvar = 11;
int pregLastRegvar = 17;
int pregFirstArg = 18;
int pregLastArg = 22;
int farcode = 0;
int wcharSupport = 1;
int verbose = 0;
int use_gp = 0;
int address_bits = 32;
int maxVL = 64;
int nregs = 64;

int sizeOfChar = 1;
int sizeOfWord = 4;
int sizeOfFP = 4;
int sizeOfFPS = 4;
int sizeOfFPD = 4;
int sizeOfFPT = 6;
int sizeOfFPQ = 8;
int sizeOfPtr = 4;
int bitsPerByte = 13;

std::ifstream *ifs;
txtoStream ofs;
txtoStream lfs;
txtoStream dfs;
/*
FILE            *input = 0,
                *list = 0,
                *output = 0;*/
FILE			*outputG = 0;
int incldepth = 0;
int             lineno = 0;
int             nextlabel = 1;
int             lastch = 0;
int             lastst = 0;
char            lastid[128] = "";
char            lastkw[128] = "";
char            laststr[MAX_STRLEN + 1] = "";
int64_t			ival = 0;
double          rval = 0.0;
Float128		rval128;
char float_precision = 'd';
//FloatTriple     FAC1,FAC2;
//FLOAT           rval = {0,0,0,0,0,0};
int parseEsc = TRUE;

TABLE           gsyms[257];// = {0,0},
bool DataLabels[65535];
	           
SYM             *lasthead = (SYM *)NULL;
Float128		*quadtab = nullptr;
struct slit     *strtab = (struct slit *)NULL;
struct clit		*casetab = (struct clit *)NULL;
int             lc_static = 0;
int             lc_auto = 0;
int				lc_thread = 0;
Statement    *bodyptr = 0;
int             global_flag = 1;
TABLE           defsyms;
CSet *save_mask = nullptr;          /* register save mask */
CSet *fpsave_mask = nullptr;
TYP             tp_int, tp_econst;
bool dogen = true;
int isKernel = FALSE;
int isPascal = TRUE;
int isOscall = FALSE;
int isInterrupt = FALSE;
int isTask = FALSE;
int isNocall = FALSE;
int optimize = TRUE;
int opt_noregs = FALSE;
int opt_nopeep;
int opt_noexpr = FALSE;
int opt_nocgo = FALSE;
int opt_size = FALSE;
int opt_vreg = FALSE;
int exceptions = FALSE;
int mixedSource = FALSE;
Function *currentFn = (Function *)NULL;
int callsFn = FALSE;
int stmtdepth = 0;

char nmspace[20][100];
int bsave_mask;
short int loop_active;

FT64CodeGenerator cg;


