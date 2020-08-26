#include <stdio.h>
#include "sym.h"
#include "fasm68.h"

char *verstr = "Finitron asm68 assembler    version 5.9   %.24s     Page %d\r\n";
char *verstr2 = "asm68 V5.9  (c) 1995-2020 Robert Finch - 680xx cross assembler\r\n";

int lineno;        // current assembler line
int pass;          // assembler's current pass
int lastpass=100;

//long ProgramCounter = 0;      // current program location during assembly
//long BSSCounter = 0;          // current uninitialized data address during assembly
//long DataCounter = 0;         // current initialized data area during assembly
SectionTable SectionTbl;
//char CurrentSection = CODE_AREA; // current output area.

CSymbolTbl *SymbolTbl;
CExtRefTbl *ExtRefTbl;
CStructTbl *StructTbl;

CLink *HeadFreeLink;  // head of list of free links
CSymbol *lastsym;		// last symbol referenced during expression evaluation

CMacroTbl *MacroTbl;

