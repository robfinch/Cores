// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2014  Robert Finch, Stratford
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
#include        <stdio.h>
#include        "c.h"
#include        "expr.h"
#include "Statement.h"
#include        "gen.h"
/*
 *	68000 C compiler
 *
 *	Copyright 1984, 1985, 1986 Matthew Brandt.
 *  all commercial rights reserved.
 *
 *	This compiler is intended as an instructive tool for personal use. Any
 *	use for profit without the written consent of the author is prohibited.
 *
 *	This compiler may be distributed freely for non-commercial use as long
 *	as this notice stays intact. Please forward any enhancements or questions
 *	to:
 *
 *		Matthew Brandt
 *		Box 920337
 *		Norcross, Ga 30092
 */

/*      global definitions      */

int gCpu = 888;
int regSP = 255;
int regBP = 253;
int regLR = -1;
int regXLR = 251;
int farcode = 0;
int wcharSupport = 1;
int verbose = 0;

FILE            *input = 0,
                *list = 0,
                *output = 0;
FILE			*outputG = 0;
int incldepth = 0;
int             lineno = 0;
int             nextlabel = 0;
int             lastch = 0;
int             lastst = 0;
char            lastid[33] = "";
char            laststr[MAX_STRLEN + 1] = "";
int64_t			ival = 0;
double          rval = 0.0;
int parseEsc = TRUE;

TABLE           gsyms[257],// = {0,0},
	           lsyms = {0,0};
SYM             *lasthead = (SYM *)NULL;
struct slit     *strtab = (struct slit *)NULL;
int             lc_static = 0;
int             lc_auto = 0;
int				lc_thread = 0;
struct snode    *bodyptr = 0;
int             global_flag = 1;
TABLE           defsyms = {0,0};
int             save_mask = 0;          /* register save mask */
TYP             tp_int, tp_econst;

int isPascal = FALSE;
int isOscall = FALSE;
int isInterrupt = FALSE;
int isNocall = FALSE;
int optimize = TRUE;
int exceptions = FALSE;
SYM *currentFn = (SYM *)NULL;
int callsFn = FALSE;

char nmspace[20][100];



