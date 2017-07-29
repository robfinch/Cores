# Welcome to the C64 compiler for OPC5

The compiler might actually work for some trivial programs. At least it should provide a head-start to writing assembly language code for the OPC5.
The compiler expects to be able to find the "fpp.exe" program which is a pre-processor for the compiler.

## History
The compiler is a steadily evolving compiler that was originally a 68k compiler written in the '80s by Matthew Brandt. It has undergone many, many changes with many new features and bears only a passing resemblance to the original compiler. You will still see Matthew's copyright notice in some of the files.

## Features Supported
The compiler supports the 'C' language but includes some additional features some of which are incorporated into most modern 'C' compilers.

- run-time type identification (via typenum())
- function prolog / epilog control
- multiple case constants eg. case ‘1’,’2’,’3’:
- assembler code (asm)
- pascal calling conventions (pascal)
- no calling conventions (nocall / naked)
- inline code
- additional loop constructs (until, loop, forever)
- true/false are defined as 1 and 0 respectively
- structure alignment control
- firstcall blocks
- block naming


## Many things to do yet:
- division operators
- assignment operators like *= <<= etc.
- firstcall blocks

### typenum(<type>)
Returns a hash code for the type which allows a number to be associated with type so the type may be checked at run-time.

### prolog / eplilog control
The 'prolog' and 'epilog' statements allow control over code that is invoked when a function is first called (prolog) or exited(epilog).
The statements may be located anywhere in the function and the compiler will output the code at the proper place.
'prolog' statements are not heavily optimized by the compiler because the compiler assumes that no temporary registers are available yet.
The main purpose of prolog / epilog code is allow control over entrance and exit code for things like interrupt routines or system calls.

### case constants
Multiple case constants may be listed under a single case statement. Normal 'C' does not allow this, but it has been added to several modern compilers.

### asm
Assembler code can be placed into the program. However the compiler does not parse the assembler code which many commerical compilers do. So one has to be aware of the stack offsets to access parameters.

## pascal calling conventions

### 

ToDo: more docs
