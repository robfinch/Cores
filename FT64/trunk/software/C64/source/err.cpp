// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2016  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// C32 - Raptor32 'C' derived language compiler
//  - 32 bit CPU
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

extern int numerrs;
extern int total_errors;
extern int my_errno[80];
extern void closefiles();

static char *errtextstr[] = {
	"Syntax error",
	"Illegal character",
	"Floating point",
	"Illegal type",
	"Undefined symbol",
	"Duplicate symbol",
	"Bad punctuation",
	"Identifier expected",
	"No initializer",
	"Incomplete statement",
	"Illegal initializer",
	"Initializer size",
	"Illegal class",
	"block",
	"No pointer",
	"No function",
	"No member",
	"LValue required",
	"Dereference",
	"Mismatch",
	"Expression expected",
	"While/Until expected",
	"Missing case statement",
	"Duplicate case statement",
	"Bad label",
	"Preprocessor error",
	"Include file",
	"Can't open",
	"Define",
	"Expecting a catch statement",
	"Bad bitfield width",
	"Expression too complex",
	"Asm statement too long - break into multiple statements",
	"Too many case constants",
	"Attempting to catch a structure - aggregates may not be caught - use a pointer to struct",
	"Semaphore increment / decrement limited to 1 to 15.",
	"Semaphore address must be 16 byte aligned.",
	"Operator is not defined for float/double type.",
	"Integer constant required.",
	"Bad switch expression.",
	"Not in a loop.",
	"Check expression invalid",
	"Bad array index",
	"Too many dimensions",
	"Out of predicate registers",
	"Parameter list doesn't match prototype",
	"Can't access private member",
	"The function call signature doesn't match any of the class methods",
	"Method not found",
	"Out of memory",
	"Too many symbols",
	"Too many parameters - the compiler is limited to 20 or less",
	"The 'this' pointer may only be used in a class method.",
	"Bad function argument."
};

char *errtext(int errnum)
{
	if (errnum < 1000)
		return errtextstr[errnum];
	return "";
}

/*
 *      error - print error information
 */
void error(int n)
{
	if (numerrs < 80) {
		my_errno[numerrs++] = n;
		++total_errors;
	}
	else
		exit(1);
}

void fatal(char *str)
{
	printf(str);
	closefiles();
	getchar();
	exit(2);
}


