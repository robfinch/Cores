// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2018  Robert Finch, Waterloo
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

CPU cpu;
int pass;
int maxPn = 15;
int gCpu = 7;
int regPC = 254;
int regSP = 31;//63;
int regFP = 30;//62;
int regLR = 29;//61;
int regXLR = 28;//60;
int regGP = 27;//59;
int regTP = 26;//58;
int regCLP = 25;//57;                // class pointer
int regZero = 0;
int regFirstTemp = 3;//5;
int regLastTemp = 10;//20;
int regFirstRegvar = 11;//21;
int regLastRegvar = 17;//34;
int regFirstArg = 18;//35;
int regLastArg = 22;//47;
int farcode = 0;
int wcharSupport = 1;
int verbose = 0;
int use_gp = 0;
int address_bits = 32;
int maxVL = 64;

int sizeOfWord = 8;
int sizeOfFP = 8;
int sizeOfFPS = 8;
int sizeOfFPD = 8;
int sizeOfFPT = 12;
int sizeOfFPQ = 16;
int sizeOfPtr = 8;

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
int             nextlabel = 0;
int             lastch = 0;
int             lastst = 0;
char            lastid[128] = "";
char            lastkw[128] = "";
char            laststr[MAX_STRLEN + 1] = "";
int64_t			ival = 0;
double          rval = 0.0;
Float128		rval128;
char float_precision = 't';
//FloatTriple     FAC1,FAC2;
//FLOAT           rval = {0,0,0,0,0,0};
int parseEsc = TRUE;

TABLE           gsyms[257];// = {0,0},
	           
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
int64_t         save_mask = 0;          /* register save mask */
int64_t         fpsave_mask = 0;
TYP             tp_int, tp_econst;
bool dogen = true;
int isKernel = FALSE;
int isPascal = FALSE;
int isOscall = FALSE;
int isInterrupt = FALSE;
int isTask = FALSE;
int isNocall = FALSE;
int optimize = TRUE;
int opt_noregs = FALSE;
int opt_nopeep;
int opt_noexpr = FALSE;
int opt_nocgo = FALSE;
int exceptions = FALSE;
int mixedSource = FALSE;
SYM *currentFn = (SYM *)NULL;
int callsFn = FALSE;
int stmtdepth = 0;

char nmspace[20][100];



