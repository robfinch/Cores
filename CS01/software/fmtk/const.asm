; First 128 bytes are for integer register set
; Second 128 bytes are for float register set
; Leave some room for 64-bit regs
TCBsegs			EQU		$200		; segment register storage
TCBepc			EQU		$280
TCBStatus		EQU		$288
TCBPriority	EQU		$289
TCBStackBot	EQU		$290

TS_READY		EQU		1
TS_DEAD			EQU		2
