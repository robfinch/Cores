# RISCV - Register Sets (RSP) Proposal
RISCV ISA specification. Working draft, subject to change.

<strong>Contributors:</strong> Robert T. Finch

## Introduction
Many designs have the opportunity to support multiple register files. The register file is often implemented with standard memories (FPGA / ASIC) that are much larger than the number of visible registers.
It makes sense then to use the "extra" memory space to implement more registers. Common approaches to supporting more registers include separate register files for separate modes of operation in the processor.
User mode may have it's own dedicated register file along with a separate register file for machine mode. Many early machines had a dedicated stack pointer for each of user and system mode because of issues that arise when using only a user stack pointer to service system exceptions.
The register set is often automatically switched when the processor switches modes of operation.
Having a separate register set to support interrupts allows high-speed operation of interrupt routines.

## Proposal
This proposal proposes a means to access user registers from other modes of operation.

We propose:

* to add a non-standard read/write CSR accessible only to machine mode (CSR $780) to contain register set selection bits
* to allow the register set in use to be selected independently for each register field of an instruction.
* that the register set selection of user registers be automatic when the processor is switched to user mode.
* that the register set selection of machine registers is automatic when an interrupt or exception occurs.

## Rationale
Many designs offer ways to move values between register sets. This is often done with dedicated move instructions. Another approach is to have a subset of registers visible to multiple operating modes.
Rather than add custom move instructions to the instruction set, what it proposed here is to use a CSR to control the selected register set for <italic>all</italic> instructions.
Using a CSR register has greater flexibility than custom move instructions or register subset selections. For instance by switching the register set using a CSR, load and store operations may be performed against an alternate register set.
Automatic register set selection occurring during mode switches adds a safety factor to system operation. When an operating mode is activated the registers should be selected as expected. If for some reason the processor mode is accidently switched to user mode from machine mode, only user mode registers should be accessible.

## Examples
Operating system calls often need to transfer data between user and machine mode. Returning a value requires moving values between register sets.
This can be done by setting a selection bit in a CSR.

ERETx:
	csrrs	$x0,#$780,#1				; select user regfile for destination
	mov		$v1,$v1							; move return values to user registers
	mov		$v0,$v0
	eret											; return (auto selects user registers)

Another frequent operating system requirement is to save the user state. This becomes easy to do with regset selection controlled by a CSR.

;------------------------------------------------------------------------------
; Swap from outgoing context to incoming context.
;
; Parameters:
;		a0 = pointer to ACB of outgoing context
;		a1 = pointer to ACB of incoming context
;------------------------------------------------------------------------------

SwapContext:
	; Save outgoing register set in ACB
	csrrs	$x0,#$780,#4	; select user register set for Rs2
	sw		$x1,4[$a0]
	sw		$x2,8[$a0]
	sw		$x3,12[$a0]
	sw		$x4,16[$a0]
	sw		$x5,20[$a0]
	sw		$x6,24[$a0]
	sw		$x7,28[$a0]

## CSR Format
  XLEN - 1            4    3     2     1     0
+-----------------------+-----+-----+-----+----+
: XLEN-1 to 4 reserved  : Rs3 : Rs2 : Rs1 : Rd :
+-----------------------+-----+-----+-----+----+

## Operation
If the bit corresponding to the register field of a instruction is set in the CSR then that register field refers to the user register file.
Otherwise if the bit is clear then the default register set for the current operating mode of the processor is selected for that register.

## CSR Typical Values
1 = user mode registers are selected as the destination for all following instructions.
4 = user mode registers are selected as the source for Rs2 for all following instructions. This would typically be used to perform a store of user registers.

## Hardware Impact
A CSR ($780) is used. The upper bits of the register file index need to be supplied by a register. Machine exception processing must set the upper bits of the register file index appropriately.

## Software Impact
No changes to the existing instruction set are required. Software may need to be altered to make use of the CSR.

## Example Test System
A test system has been constructed implementing the register set selection CSR. This test system has four registers sets, one user mode register set and three machine mode register sets. While logically independent all four register sets are part of the same memory.
When an exception or interrupt occurs, machine mode is activated and the an internal register set selection is incremented. When a exception return instruction is executed the internal register set selection is decremented.
This system setup allows an interrupt to have it's own dedicated register file for high-speed interrupt processing, while allowing interrupts to occur while processing in the machine mode.
User mode registers are made accessible to the operating system running in machine mode through the use of the CSR. Interrupts do not access user or operating system registers.

