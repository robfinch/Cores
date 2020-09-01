# RISCV - Garbage Collect Interrupt Enable / Disable (GCIED) Proposal
RISCV ISA specification. Working draft, subject to change.

### Contributors: Robert T. Finch

## Introduction
For a garbage collected system which is interrupt driven, false positive matches of object pointers can occur during execution of a function prolog when the stack space has been allocated but not yet initilized.
To prevent these false matches, this proposal suggests deferring the processing of garbage collect interrupts until after the function prolog is complete. This would be accomplished by disabling the garbage collect interrupt during the function prolog.

## Scope
This document applies only to interrupt driven garbage collection systems.

## Proposal

We propose to:
* add a new user mode CSR register ($004) to contain the garbage collect interrupt enable bit

* modify the JAL instruction operation so that it automatically disables GC interrupts only when operating at the user level.

### Rationale

Function prolog code usually begins with a stack allocation followed by some register spills to the allocated area. This usually occurs near the start of a function.
Rather than add additional code to the instruction stream which costs code size and execution time, it is proposed to modify the JAL instruction so that it automatically disables the garbage collect interrupt while operating at the user level.
A JAL instruction is close to the beginning of the function prolog as JAL is used to invoke functions.
The JAL instruction would detect user mode, then clear the GC enable bit in the new CSR. Since this is just a single bit clear the hardware cost is small.

The new CSR register containing a single bit is required as it represents an interrupt enable / disable capability in user mode which currently does not have a register for this.
Using CSR register operations to modify an enable bit is a standard approach. The existing CSR instructions may be used to modify the bit.
This bit may only be set to enable GC interrupts only in user mode. In other operating modes the CSR GC bit update would be ignored.
Setting the bit (enabling GC interrupts) in user mode only may be important for common code modules which are used by multiple privilege modes.
If the OS determined to disable interrupts they should not inadvertently be enabled by executing a common code module.
Using CSR register $004 is suggested as it mirrors the interrupt enable / disable registers of the the other privilege modes. Potentially the CSR could be used to contain other user level interrupt bits.

### Hardware Impact
The cost of implmenting the deferred garbage collection is small. It is the manipulation of a single bit using hardware decodes (JAL/CSR) that are already present.

### Software Impact
Enabling the GC interrupt after the function prolog requires a CSR set instruction in the instruction stream. This may increase the size of user mode code.

## Operating Scenarios
It is concievable that enabling the GC interrupt is omitted from code. Since JAL would disable the interrupt it would be possible for a user mode program to prevent GC interrupts from occuring.
Since only the GC interrupt is affected the operating system still has a chance to run normally. The OS may include a watchdog for the GC interrupt.
If GC interrupts are somehow disabled, items sent to the garbage will build up and eventually the system may run out of resources. This should result in an allocation error of some sort. At this point the GC could be checked for proper operation.
Note that if running apps are switched the new app may enable GC.
The likely-hood of bad things happening to the system is small.

## Further Proposal

We propose to add an instruction count limit to the disabling of GC interrupts by a JAL instruction.

### Rationale

Most function prologs are short. By placing a limit on the interrupt disable that occurs executing a JAL instruction, there is no need for a CSR set operation at the end of the prolog.
What would happen is once a JAL instruction is executed the GC enable bit in the CSR would be clear disabling further interrupts. A count-down instruction counter would be initialized to a small value TBD.
The JAL instruction triggers operation of the count-down which then counts with each instruction executed. When the counter reaches zero, GC interrupts are enabled and counting stops.

### Advantages:

* The existing code-base can be used unchanged and reap the benefits of the GC deferral.
* There is no impact on the size of code.
* It hides the feature architecturally.

### Disadvantages:

* Rather than manipulating a single bit, a multi-bit counter is required. The hardware cost may be increased.
* Using a fixed counter value may not cover all function prolog cases. There may be function prologs too large which might result in false matches.
  The function prolog may be shorter than the count value meaning interrupts are unnecessarily deferred.
  
## Issues

It may not be sufficient to manipulate a GC enable bit in multi-core systems.

## Other ideas

The size of the function prolog is known by the compiler. Since this is a known value it could be included as the limit as part of a call instruction.
A small field (three or four bits) in a call instruction could indicate the prolog size in multiples of four words for instance.

