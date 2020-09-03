# RISCV - Garbage Collect Interrupt Enable / Disable (GCIED) Proposal
RISCV ISA specification. Working draft, subject to change.

<strong>Contributors:</strong> Robert T. Finch, Allen Baum, Paul Campbell, Bill Huffman

## Introduction
For a garbage collected system which is interrupt driven, false positive matches of object pointers can occur any time storage is allocated but not yet initialized.
This may occur during execution of a function prolog when the stack space has been allocated but not yet initialized.
To prevent these false matches, this proposal suggests deferring the processing of garbage collect interrupts until after the function prolog is complete. This would be accomplished by disabling the garbage collect interrupt during the function prolog.
Further also on stack allocations GC interrupts may be deferred.

### Acronyms

GC = Garbage Collect

## Scope
This document applies only to interrupt driven garbage collection systems.

## Proposal

We propose to:
* add a new user mode CSR register ($004) to contain the garbage collect interrupt enable bit

* modify the JAL instruction operation so that it automatically disables GC interrupts only when operating at the user level.

* OR modify the ADDI, SUB instructions so that they automatically disable GC interrupts only when operating at the user level and an update to the stack pointer is occurring.

* OR add a new custom instruction 'GCSUB' for allocations which will automatically disable GC interrupts only when operating at the user level.

### Rationale

Function prolog code usually begins with a stack allocation followed by some register spills to the allocated area. This usually occurs near the start of a function.
Rather than add additional code to the instruction stream which costs code size and execution time, it is proposed to modify the JAL instruction so that it automatically disables the garbage collect interrupt while operating at the user level.
A JAL instruction is close to the beginning of the function prolog as JAL is used to invoke functions.
The JAL instruction would detect user mode, then clear the GC enable bit in the new CSR. Since this is just a single bit clear the hardware cost is small.

Modifying the ADDI or SUB instructions are more hardware costly as they need to detect the registers involved, but further reduce false positive matches by allowing any stack allocation to trigger a disable of the GC interrupt.

Since JAL, ADDI and SUB are standard instructions already present and already implemented in many designs and it would represent a significant impact to process such as regression testing, it may be more desirable to implement a custom instruction.

The new CSR register containing a single bit is required as it represents an interrupt enable / disable capability in user mode which currently does not have a register for this.
Using CSR register operations to modify an enable bit is a standard approach. The existing CSR instructions may be used to modify the bit.
Setting the bit (enabling GC interrupts) in user mode only may be important for common code modules which are used by multiple privilege modes.
If the OS determined to disable interrupts they should not inadvertently be enabled by executing a common code module.
Using CSR register $004 is suggested as it mirrors the interrupt enable / disable registers of the the other privilege modes. Potentially the CSR could be used to contain other user level interrupt bits.

The primary reason to modify an existing instruction or add a new custom instruction is to reduce the size of code. GC interrupts could be deferred simply using an additional CSR instruction in the instruction stream. However that cost code size and performance.

### Lock-out
One possibility is to lock-out the GC interrupt for a number of instructions after the JAL, SUB, ADDI or GCSUB. This could be for a fixed number of instructions or based on the allocation size of the SUB, ADDI or GCSUB.

#### Advantages:
It hides the GC lockout architecturally so that no additional instructions are required in the instruction stream. There is no impact to code size and existing code-base can be used.

#### Disadvantages:
While the GC is locked out, other interrupts are not, and it may require saving additional state (the current lockout count) in an interrupt routine.
Otherwise the GC deferral may not be as effective.


### Hardware Impact
The cost of implmenting the deferred garbage collection is small. It is the manipulation of a single bit using hardware decodes (JAL/CSR) that are already present.
An additional decode for the 'GCSUB' instruction must be present if implemented.

### Software Impact
Enabling the GC interrupt after the function prolog requires a CSR set instruction in the instruction stream. This may increase the size of user mode code.
With a lockout count there may be no software impact.

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

In superscalar and other advanced pipelines, switching the interrupt status may result in pipeline flushes which will impact performance.
Since the GC interrupt switches would occur frequently performance may be affected in a manner which makes implmenting the GC interrupt deferrals not worthwhile for those architectures.

## Other ideas

The size of the function prolog is known by the compiler. Since this is a known value it could be included as the limit as part of a call instruction.
A small field (three or four bits) in a call instruction could indicate the prolog size in multiples of four words for instance.
This would require a new call instruction, possibly a 48-bit instruction.

## Summary
The benefit of deferring GC interrupts may not be significant, but the hardware cost is small.
There are potentially some research topics which could be followed up on. For instance given that there are cases where the GC deferral doesn't completely isolate the allocated area, does the performance impact of false matches negate the benefit of deferring GC interrupts?
