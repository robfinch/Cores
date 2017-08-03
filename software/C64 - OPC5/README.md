# Welcome to the C64 compiler for OPC5/OPC6

The compiler might actually work for some trivial programs. At least it should provide a head-start to writing assembly language code for the OPC5/OPC6.
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
- classes with single inheritance


## Many things to do yet:
- assignment operators like *= <<= etc.
- firstcall blocks

## Compiler Options
-o[pxrc] disables specific optimizations. -o by itself disables all optimizations
    p disables peephole optimizations
	x disables optimization of expressions
	r disables register optimizations
	c disables optmizations done by the code generator

-S	generates code with source lines embedded in it as comments
    this option doesn't work real well but is sufficient to be useful as an
	aid when viewing compiler output

### Register Usage
The compiler makes use of registers in the following fashion:
Reg |Usage|Comment|Saved by
----+-----+-------+--------
r0 | always zero | fixed use by hardware | ...
r1 | return value | by convention | caller
r2 | register variable | callee
r3 | register variable | callee
r4 | register variable | callee
r5 | temporary | expression processing | caller
r6 | temporary | | caller
r7 | temporary | | caller
r8 | parameter | register parameter to function | caller
r9 | parameter | | caller
r10 | parameter | | caller
r11 | class pointer | points to the current class data structure | caller
r12 | base pointer | | callee
r13 | link register | stores the return address | callee
r14 | stack pointer | | callee
r15 | program counter | fixed use by hardware | ...


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
Assembler code can be placed into the program. However the compiler does not parse the assembler code which many commerical compilers do. The compiler just copies the asm block to output in a raw fashion. So one has to be aware of the stack offsets to access parameters.

## pascal calling conventions
Unless specified as pascal the compiler uses the 'C' language calling convention of popping the registers passed to a function after the function is called in the caller's code. When the pascal calling convention is used register parameters are popped off the stack by the called routine. In some machines this is a faster way of doing things.

### naked
The keyword naked tells the compiler to omit code generation under certain circumstances. A naked function is a function where the prolog / epilog code has been omitted. This allows the programmer to substitute his own code in place of the compiler generated code. This is useful for specific routine types such as exception handlers.
The naked keyword can also be applied to the switch statement to reduce the amount of code emitted when a switch is implemented with a jump table. A naked switch doesn't check whether or not the switch expression is in the range of the cases resulting in smaller code. However if the expression is outside of the proper range the code may crash.

### inline
Inline code is emitted by the compiler 'inline' with other code. Rather than emit a call to a subroutine the entire contents of the routine is placed where used. This allows somewhat faster code at the expense of a larger memory footprint.
Inline code is often used for small functions where the overhead of calling a function might be larger than just including the code inline.

### until / loop / forever
An until loop works like a while loop except that the loop runs 'until' the condition is true. This is an alternate to writing 'while (!(cond))'.
'loop' is a way to code an unconditional loop construct. It is an alternative to writing 'while (1)'.
'forever' is another way to code a loop that's intentionally without a terminating condition.

### firstcall
'firstcall' blocks take care of allocating and managing a static variable used to limit a block of code to executing only the first time a function is called.

### block naming
Blocks of code may be given names for future reference. Follow the opening brace of a block of code directly with a ':' to name the block.

### class
A class in C64 operates much like a struct except that it may also have methods as members. Classes may inherit from other classes. Classes support single inheritance.
Template classes and operator overloading are not supported. Method overloading is supported.

ToDo: more docs

