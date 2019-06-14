// ============================================================================
//        __
//   \\__/ o\    (C) 2014-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// AS64 - Assembler
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
#ifndef SYMBOL_H
#define SYMBOL_H

#include "Int128.h"

typedef struct {
  int ord;        // ordinal
  int name;       // name table index
	Int128 value;
  char segment;
  char defined;
  char isExtern;
  char phaserr;
  char scope;     // P = public
	bool isMacro;
	Macro *macro;
  int bits;
} SYM;

SYM *find_symbol(char *name);
SYM *new_symbol(char *name);
void DumpSymbols();
extern int numsym;

#endif
