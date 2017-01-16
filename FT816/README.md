# FT832
Welcome to the FT832 core folder. This document provides a brief intro. to the FT832 core.

# Overview
The design of this core has been guided by discussions on the 6502.org forum. Features of the core include truly flat 32 bit addressing and 32 bit indirect addresses. The core is 65832 ISA backwards compatible. Also supported by this core is simple high-performance task switching. A segmented memory protection model has been added to the core as an option. New instructions have been added to support core functionality. Some of the instruction set has been designed around the notion that this core will be required for more heavy duty apps. The WDM opcode is used to extend the functionality of many existing instructions. When the existing instruction opcode is prefixed with 42h it may have additional functionality including extended address modes. For instance prefixing the REP instruction with 42h causes it to use a 16 bit immediate to update both the status register and new extended status register.
# Features
Some features include:
- Expanded addressing capabilities (32 bit addressing modes)
- Instruction caching
- Code, data and stack segment registers
- Multiple register contexts and high speed context switching
- Interpretive operating mode
- Single step mode
- Task / context vectoring interrupts (in native 32 bit mode)
- Combinational signed branches (branches that test both N and Z flags at the same time).
- Relative branches to subroutine (for position independent code)
- Long branching for regular branch instructions
- Multiply instruction
- Enhanced support for variable size data (size prefix codes)
- Configurable context / task switch support 
#Programming Model
The programming model is compatible with the W65C816S programming model, with the addition of three new segment registers and a task register. A number of new instructions and addressing modes have been added using the opcode reserved for that purpose (the WDM opcode). There is also an array of 512 task context registers if the core is configured for hardware support of tasks.
|Register|	Size|
|:---:|:---|		
|CS|16|	code selector	
|PB|	8|	program bank	
|PC|	16|	program counter	
|Acc|	32|	accumulator	
|x|	32|	x index register	
|y|	32|	y index register	
|SP|	32|	stack pointer	
|DS|	16|	data selector	
|SS|	16|	stack selector	
|DB|	8|	data bank	
|DPR|	16|	direct page register	
|SR|	8|	status register	
|SRX|	8|	status register extension	
|TR|	16|	Task Register	

Task Context Register Array (present only if hardware task support is configured):
|Register|
|:---:|	
|0|	Register context
|…	|
|511|	

 
# Segmentation Model
The segmentation model used by FT832 is extremely simple. There are only three segment selector registers (code, data and stack) and addresses are formed by a simple addition of a segment value to the program counter and effective data address. All data access is associated with the data segment. All instruction access is associated with the code segment. All stack accesses are associated with the stack segment. There is no way to override the association of the code segment with instruction access (program counter). For data access the segment may be overridden using one of the segment override prefixes (CS:, SS: SEG:, SEG0, IOS: ). The segment associated with stack instructions may not be overridden.
On reset both the code segment and data segment selector registers are set to zero.
The code segment may be set using the JMF, JSF,  JCF far instructions. The code segment may also be set in the task start-up record and loaded with the context via the LDT instruction.
The data segment may be set by pushing a value on the stack then pulling the data segment from the stack using the PLDS instruction.
The stack segment selector may be set by transferring a value to it from the accumulator using the TASS instruction.
 
## Selectors
There is a level of indirection when dealing with segments. Segment values are not directly encoded into the instruction instead a selector value is used. The selector values require only 16 bits rather than the 32 bits (or more) required for a segment value. This saves two bytes every time a segment value is needed. For instance when calling a far routine only the 16 bit code selector needs to be saved rather than a 32 bit code segment value. This save two memory accesses and the instruction is two bytes smaller. The selector points to an entry in the segment descriptor table. The actual segment value is found in the segment descriptor table.
Segment Register (or Selector) Format:
| 15   14|13  12|11                                                   0|
|:---:|:---:|:---:|
|~2	|~2	|Index12|
Index12: the index into the descriptor table
## The Segment Descriptor Table
The segment descriptor table contains information on the location and size for segments. The segment selectors point to entries in this table. This table is a special 4k entry dual-ported memory embedded within the processor. Entries in the table have the following format:
||43                36|35     32|31                                                         0|
|--|----|-----|:---|
|w0|ACR8|Size4|Base31..0|
|w1|ACR8|Size4|Base31..0|
…			

Size4 Field
The segment is usually expanded in chunks. 
|Bits|Data Size|
|----|:---|
3-0|0000 = 0
0001| = 256|
0010| = 1024|
0011| = 4096|
0100| = 16384|
0101| = 65536|
0110| = 256k|
0111| = 1MB|
1000| = 4 MB|
1001| = 16 MB|
1010| = 64MB|
1011| = 256MB|
1100| = 1GB|
1101| = 4GB|

# Multi-Tasking
## Overview
The FT832 core has hardware support for a multi-tasking operating system. One of the requirements for the tasking system is that it be fast. A goal was that context switching be at least as fast as could be done on the 65xxx series. One of the attractive features of the 65xxx series is the limited amount of context which is required to be stored during a context switch. This results in extremely fast context switching. As a result the latency in processing interrupt routines is low. One of the problems with adding additional registers to the programming model is that the context switch time is impacted. In keeping with low latency context switches, switching contexts with the FT832 can be done in as little as six clock cycles. Unlike some other cpu’s supporting multi-tasking, the register context isn’t saved to memory during a context switch. Instead the register context is saved in a dedicated register array. Access to this register array is single cycle for storing all registers or restoring all registers. This allows the FT832 to be even faster (lower latency) for processing interrupt routines while at the same time supporting an expanded programming model.
A second requirement of the tasking system is that it be simple. Target applications of the FT832 are more for embedded systems rather than being a full-fledged workstation type processor.
## Operation
At reset the core begins running software in task / context #0. Since the core does not automatically load from the task start-up table at reset, it is necessary to initialize the register set manually. This is no different than the existing 65xxx series initialization requirements. See the table “Reset Settings on Reset” to determine which registers are pre-set to which values. For other tasks the entire register set may be pre-set from entries in the task start-up table.
The task start-up table is table of 32 byte entries which contain starting values for each of the processor’s program visible registers. This table may be located anywhere in memory. The processor’s internal registers are not loaded from the start-up table; just the ones that can be programmed. Entries in the start-up table may be loaded into processor’s task context registers using the LDT instruction. Loading a task context from a start-up table entry does not automatically start the task. The task will be started when it is invoked with the TSK instruction.
In native 32 bit mode the core may be configured (default) to use task number for interrupt vectors rather than addresses. It’s lower latency to switch tasks automatically on interrupt rather than first going to an interrupt service routine. Using a task number allows the interrupt processing routine to be located anywhere in memory while the vector contents are only 16 bits.
It is possible to switch to a 32 bit interrupt handler during interrupt processing for 8 or 16 bit emulation modes.
 
# New Addressing Modes
There are several new addressing modes for existing instructions. Extra-long addressing for both absolute and absolute indexed addresses is available. The extra-long addressing mode is formed by prefixing the regular absolute address modes opcode with the extended opcode indicator byte ($42). This gives access to a 32 bit offset for a number of instructions which were not supported by the absolute long address modes. Extra-long indirect addressing modes are additional addressing mode available in the same manner as extra-long addressing. The indirect address mode instructions are prefixed with the opcode extension byte ($42).
The segment value of an address may be explicitly specified using the SEG prefix. The SEG prefix may be applied to direct page addresses, absolute addresses, absolute long addresses, and absolute extra-long addresses. The assembler syntax has the form: 
LDA $34:$1234
This tells the core to use the segment associated with selector number $34 and load the accumulator with the value at offset $1234 in the segment. If the segment isn’t specified either the data or stack selector will be used depending on the addressing mode.
It is possible to use segmented indirect addresses by applying the FAR prefix to the indirect address instruction. As in the following:
EOR FAR ($100,X)
In this case the address looked-up is a far address. The address will contain two extra bytes in order to specify a selector. In this case the address will contain four bytes. Two for the offset and two for the segment. This may be most useful for specifying subroutine arguments that are far (segmented) addresses. As in:
 LDA FAR {3,S},Y
 which uses a six byte indirect address located on the stack (four for offset and two for selector) to load the accumulator from.
