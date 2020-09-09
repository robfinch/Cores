# RISCV - Lightweight Hardware Queues (LHQ) Proposal
RISCV ISA specification. Working draft, subject to change.

<strong>Contributors:</strong> Robert T. Finch

## Introduction
Queues or FIFO's are common piece of many systems. They may be used for rate throttling data transfers between devices or software programs. Or they may be used for managing lists of objects such as operating system task lists.
Queues are often stored in main memory and managed by standard instructions. Hardware based queues are potentially much faster.

## Proposal

We propose:
* adding several custom instructions for light-weight hardware queue management
* that the LHQ's are accessible via custom instructions and are not implemented in the memory system

## Rationale
Queues are often implemented as part of the memory system. As part of the memory system they may be shared between devices.
Most often queues are managed by software. The issue with memory based queues is one of performance and complexity; implementing a small hardware queue which is not on the main bus may be much faster.
This proposal is suggesting that even small fixed size hardware queues may be valuable for a system.

## Custom Instructions

### PUSHQ
PUSHQ pushs a value in Rs1 onto the hardware queue identified by Rs2.

### POPQ
POPQ pops the value at the head of the queue identified by Rs1 into Rd. The queue is advanced.

### PEEKQ
PEEKQ reads the value at the head of the queue identified by Rs1 into Rd without advancing the queue.
Consecutive PEEKQ operations to the same queue will return the same head of queue value.

## Examples
Inserting into a queue. The following code inserts a task into a ready queue, making use of the pushq instruction.
```
InsertIntoReadyQueue:
	ldbu	$t0,TCBStatus[$a0]	; set status to ready
	or		$t0,$t0,#TS_READY
	stb		$t0,TCBStatus[$a0]
	ldb		$t0,TCBPriority[$a0]  ; queue select based on priority
	pushq	$a0,$t0
	ret
```

