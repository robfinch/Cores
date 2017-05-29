#include <stdio.h>
#include "sym.h"
#include "Assembler.h"

/* ===============================================================
	(C) 2006  Robert Finch
	All rights reserved.
	rob@birdcomputer.ca
=============================================================== */

int lineno;        // current assembler line
int pass;          // assembler's current pass
int bOutOfPhase;

Counter ProgramCounter;      // current program location during assembly
Counter BSSCounter;          // current uninitialized data address during assembly
Counter DataCounter;         // current initialized data area during assembly
char CurrentArea = CODE_AREA; // current output area.

//Declarator *HeadFreeLink;  // head of list of free links

// 65816 index and memory size flags
int xf;
int mf;

//Cpu *cpu = &optab6502;
int seg, offs;
