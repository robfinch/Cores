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

extern int numerrs;
extern int total_errors;
extern int my_errno[80];
extern void closefiles();

static char *errtextstr[] = {
	"E Syntax error",
	"E Illegal character",
	"E Floating point",
	"E Illegal type",
	"E Undefined symbol",
	"E Duplicate symbol",
	"E Bad punctuation",
	"E Identifier expected",
	"E No initializer",
	"E Incomplete statement",
	"E Illegal initializer",
	"E Initializer size",
	"E Illegal class",
	"E block",
	"E No pointer",
	"E No function",
	"E No member",
	"E LValue required",
	"E Dereference",
	"E Mismatch",
	"E Expression expected",
	"E While/Until expected",
	"E Missing case statement",
	"E Duplicate case statement",
	"E Bad label",
	"E Preprocessor error",
	"E Include file",
	"E Can't open",
	"E Define",
	"E Expecting a catch statement",
	"E Bad bitfield width",
	"E Expression too complex",
	"E Asm statement too long - break into multiple statements",
	"E Too many case constants",
	"E Attempting to catch a structure - aggregates may not be caught - use a pointer to struct",
	"E Semaphore increment / decrement limited to 1 to 15.",
	"E Semaphore address must be 16 byte aligned.",
	"E Operator is not defined for float/double type.",
	"E Integer constant required.",
	"E Bad switch expression.",
	"E Not in a loop.",
	"E Check expression invalid",
	"E Bad array index",
	"E Too many dimensions",
	"E Out of predicate registers",
	"E Parameter list doesn't match prototype",
	"E Can't access private member",
	"E The function call signature doesn't match any of the class methods",
	"E Method not found",
	"E Out of memory",
	"E Too many symbols",
	"E Too many parameters - the compiler is limited to 20 or less",
	"E The 'this' pointer may only be used in a class method.",
	"E Bad function argument.",
	"E CSE Table full.",
	"W Unsigned branch if less than zero is always false.",
	"W Unsigned branch greater or equal to zero is always true.",
	"W Forever Infinite loop",
	"E Too many initilization elements for aggregate",
	"E Constant required.",
	"E A suitable type was not found initializing union.",
	"W Precision is being lost in the type conversion.",
	"E Compiler limit reached: too many trees.",
	"E Compiler limit reached: optimization stack full.",
	"E Compiler: stack empty.",
	"E Compiler: i-graph nodes in wrong order.",
	"E Cast aggregate should be a constant",
	"E Unsupported precision."
};

static char *errtext1000[] =
{
	"E Compiler: null pointer encountered",
	"E Compiler: circular list",
	"E Compiler: missing hidden structure pointer"
};

char *errtext(int errnum)
{
	if (errnum < 1000)
		return errtextstr[errnum];
	else
		return (errtext1000[errnum]);
	return "";
}

//
// error - print error information
//
void error(int n)
{
	if (numerrs < 80) {
		my_errno[numerrs++] = n;
		++total_errors;
	}
	else {
		closefiles();
		exit(1);
	}
}

void fatal(char *str)
{
	printf(str);
	closefiles();
	getchar();
	exit(2);
}


