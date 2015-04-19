	data
	align	8
	fill.b	1,0x00
	align	8
	fill.b	16,0x00
	align	8
	fill.b	1984,0x00
	align	8
	align	8
	code
	align	16
public code SetBound48_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	     lw      r1,24[bp]
     mtspr   112,r1      ; set lower bound
     lw      r1,32[bp]
     mtspr   176,r1      ; set upper bound
     lw      r1,40[bp]
     mtspr   240,r1      ; modulo mask not used
     
SetBounds_1:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#40
endpublic

public code SetBound49_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	     lw      r1,24[bp]
     mtspr   113,r1      ; set lower bound
     lw      r1,32[bp]
     mtspr   177,r1      ; set upper bound
     lw      r1,40[bp]
     mtspr   241,r1      ; modulo mask not used
     
SetBounds_3:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#40
endpublic

public code SetBound50_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	     lw      r1,24[bp]
     mtspr   114,r1      ; set lower bound
     lw      r1,32[bp]
     mtspr   178,r1      ; set upper bound
     lw      r1,40[bp]
     mtspr   242,r1      ; modulo mask not used
     
SetBounds_5:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#40
endpublic

public code SetBound51_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	     lw      r1,24[bp]
     mtspr   115,r1      ; set lower bound
     lw      r1,32[bp]
     mtspr   179,r1      ; set upper bound
     lw      r1,40[bp]
     mtspr   243,r1      ; modulo mask not used
     
SetBounds_7:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#40
endpublic

	rodata
	align	16
	align	8
;	global	outb_
;	global	outc_
;	global	outh_
	extern	DumpTaskList_
;	global	outw_
	extern	GetRunningTCB_
;	global	SetRunningTCB_
;	global	chkTCB_
;	global	UnlockSemaphore_
	extern	GetVecno_
	extern	GetJCBPtr_
	extern	getCPU_
;	global	LockSemaphore_
;	global	set_vector_
;	global	RemoveFromTimeoutList_
;	global	SetBound50_
;	global	SetBound51_
;	global	SetBound48_
;	global	SetBound49_
;	global	InsertIntoTimeoutList_
;	global	RemoveFromReadyList_
;	global	InsertIntoReadyList_
