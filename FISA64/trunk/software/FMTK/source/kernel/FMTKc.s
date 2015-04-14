	data
	align	8
	fill.b	24,0x00
	align	8
	fill.b	1984,0x00
	align	8
	bss
	align	8
public bss irq_stack_:
	fill.b	4096,0x00

endpublic
	align	8
public bss FMTK_Inited_:
	fill.b	8,0x00

endpublic
	data
	align	8
	fill.b	312,0x00
	bss
	align	512
public bss tempTCB_:
	fill.b	512,0x00

endpublic
	data
	align	8
	fill.b	512,0x00
	bss
	align	2048
public bss jcbs_:
	fill.b	104448,0x00

endpublic
	align	512
public bss tcbs_:
	fill.b	131072,0x00

endpublic
	align	8
public bss readyQ_:
	fill.b	64,0x00

endpublic
	align	8
public bss freeTCB_:
	fill.b	8,0x00

endpublic
	align	8
public bss sysstack_:
	fill.b	8192,0x00

endpublic
	align	8
public bss stacks_:
	fill.b	2097152,0x00

endpublic
	align	8
public bss sys_stacks_:
	fill.b	1048576,0x00

endpublic
	align	8
public bss bios_stacks_:
	fill.b	1048576,0x00

endpublic
	align	8
public bss fmtk_irq_stack_:
	fill.b	4096,0x00

endpublic
	align	8
public bss fmtk_sys_stack_:
	fill.b	4096,0x00

endpublic
	data
	align	8
	fill.b	56,0x00
	bss
	align	128
public bss mailbox_:
	fill.b	262144,0x00

endpublic
	align	32
public bss message_:
	fill.b	1048576,0x00

endpublic
	align	8
public bss nMsgBlk_:
	fill.b	8,0x00

endpublic
	align	8
public bss nMailbox_:
	fill.b	8,0x00

endpublic
	align	8
public bss freeMSG_:
	fill.b	8,0x00

endpublic
	align	8
public bss freeMBX_:
	fill.b	8,0x00

endpublic
	align	8
public bss IOFocusNdx_:
	fill.b	8,0x00

endpublic
	align	8
public bss IOFocusTbl_:
	fill.b	32,0x00

endpublic
	align	8
public bss iof_switch_:
	fill.b	8,0x00

endpublic
	align	8
public bss BIOS1_sema_:
	fill.b	8,0x00

endpublic
	align	8
public bss iof_sema_:
	fill.b	8,0x00

endpublic
	align	8
public bss sys_sema_:
	fill.b	8,0x00

endpublic
	align	8
public bss BIOS_RespMbx_:
	fill.b	8,0x00

endpublic
	align	8
public bss hasUltraHighPriorityTasks_:
	fill.b	2,0x00

endpublic
	data
	align	8
	fill.b	6,0x00
	bss
	align	8
public bss missed_ticks_:
	fill.b	8,0x00

endpublic
	align	8
public bss video_bufs_:
	fill.b	835584,0x00

endpublic
	align	8
public bss TimeoutList_:
	fill.b	8,0x00

endpublic
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
     
FMTKc_1:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
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
     
FMTKc_3:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
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
     
FMTKc_5:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
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
     
FMTKc_7:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code chkTCB_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        lw    r1,24[bp]
        chk   r1,r1,b48
    
FMTKc_9:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code GetRunningTCB_:
	      	     	        mov r1,tr
        rtl
    
endpublic

public code SetRunningTCB_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	         lw  tr,24[bp]
     
FMTKc_13:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code GetVecno_:
	      	     	        mfspr  r1,12
        rtl
    
endpublic

public code DisplayIRQLive_:
	      	     	         inc  $FFD00000+220,#1
         rtl
     
endpublic

public code GetJCBPtr_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_18
	      	mov  	bp,sp
	      	bsr  	GetRunningTCB_
	      	mov  	r3,r1
	      	lw   	r3,376[r3]
	      	mov  	r1,r3
FMTKc_19:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_18:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_19
endpublic

InsertIntoReadyList_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_21
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	push 	r12
	      	push 	24[bp]
	      	bsr  	chkTCB_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	bne  	r3,FMTKc_22
	      	ldi  	r1,#1
FMTKc_24:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_22:
	      	lb   	r3,424[r11]
	      	cmp  	r3,r3,#63
	      	bgt  	r3,FMTKc_27
	      	lb   	r3,424[r11]
	      	bge  	r3,FMTKc_25
FMTKc_27:
	      	ldi  	r1,#2
	      	bra  	FMTKc_24
FMTKc_25:
	      	lb   	r3,424[r11]
	      	cmp  	r3,r3,#3
	      	bge  	r3,FMTKc_28
	      	ldi  	r3,#1
	      	lb   	r4,424[r11]
	      	sxb  	r4,r4
	      	sxb  	r4,r4
	      	asl  	r3,r3,r4
	      	lcu  	r4,hasUltraHighPriorityTasks_
	      	or   	r4,r4,r3
	      	sc   	r4,hasUltraHighPriorityTasks_
FMTKc_28:
	      	ldi  	r3,#16
	      	sb   	r3,425[r11]
	      	lb   	r3,424[r11]
	      	sxb  	r3,r3
	      	sxb  	r3,r3
	      	asri 	r3,r3,#3
	      	asli 	r3,r3,#3
	      	lw   	r12,readyQ_[r3]
	      	bne  	r12,FMTKc_30
	      	sw   	r11,312[r11]
	      	sw   	r11,320[r11]
	      	lb   	r3,424[r11]
	      	sxb  	r3,r3
	      	sxb  	r3,r3
	      	asri 	r3,r3,#3
	      	asli 	r3,r3,#3
	      	sw   	r11,readyQ_[r3]
	      	ldi  	r1,#0
	      	bra  	FMTKc_24
FMTKc_30:
	      	sw   	r12,312[r11]
	      	lw   	r3,320[r12]
	      	sw   	r3,320[r11]
	      	lw   	r3,320[r12]
	      	sw   	r11,312[r3]
	      	sw   	r11,320[r12]
	      	ldi  	r1,#0
	      	bra  	FMTKc_24
FMTKc_21:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_24
RemoveFromReadyList_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_33
	      	mov  	bp,sp
	      	push 	r11
	      	push 	r12
	      	lw   	r11,24[bp]
	      	ldi  	r12,#readyQ_
	      	push 	r11
	      	bsr  	chkTCB_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	bne  	r3,FMTKc_34
	      	ldi  	r1,#1
FMTKc_36:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_34:
	      	lb   	r3,424[r11]
	      	cmp  	r3,r3,#63
	      	bgt  	r3,FMTKc_39
	      	lb   	r3,424[r11]
	      	bge  	r3,FMTKc_37
FMTKc_39:
	      	ldi  	r1,#2
	      	bra  	FMTKc_36
FMTKc_37:
	      	lb   	r3,424[r11]
	      	sxb  	r3,r3
	      	sxb  	r3,r3
	      	asri 	r3,r3,#3
	      	asli 	r3,r3,#3
	      	lw   	r3,0[r12+r3]
	      	cmp  	r11,r11,r3
	      	bne  	r11,FMTKc_40
	      	lb   	r3,424[r11]
	      	sxb  	r3,r3
	      	sxb  	r3,r3
	      	asri 	r3,r3,#3
	      	asli 	r3,r3,#3
	      	lw   	r4,312[r11]
	      	sw   	r4,0[r12+r3]
FMTKc_40:
	      	lb   	r3,424[r11]
	      	sxb  	r3,r3
	      	sxb  	r3,r3
	      	asri 	r3,r3,#3
	      	asli 	r3,r3,#3
	      	lw   	r3,0[r12+r3]
	      	cmp  	r11,r11,r3
	      	bne  	r11,FMTKc_42
	      	lb   	r3,424[r11]
	      	sxb  	r3,r3
	      	sxb  	r3,r3
	      	asri 	r3,r3,#3
	      	asli 	r3,r3,#3
	      	sw   	r0,0[r12+r3]
FMTKc_42:
	      	lw   	r3,312[r11]
	      	lw   	r4,320[r11]
	      	sw   	r4,320[r3]
	      	lw   	r3,320[r11]
	      	lw   	r4,312[r11]
	      	sw   	r4,312[r3]
	      	sw   	r0,312[r11]
	      	sw   	r0,320[r11]
	      	sb   	r0,425[r11]
	      	ldi  	r1,#0
	      	bra  	FMTKc_36
FMTKc_33:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_36
InsertIntoTimeoutList_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	lw   	r12,24[bp]
	      	ldi  	r13,#TimeoutList_
	      	lw   	r3,[r13]
	      	bne  	r3,FMTKc_46
	      	lw   	r3,32[bp]
	      	sw   	r3,368[r12]
	      	sw   	r12,[r13]
	      	sw   	r0,312[r12]
	      	sw   	r0,320[r12]
	      	ldi  	r1,#0
FMTKc_48:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
FMTKc_46:
	      	sw   	r0,-16[bp]
	      	lw   	r11,[r13]
FMTKc_49:
	      	lw   	r3,32[bp]
	      	lw   	r4,368[r11]
	      	cmp  	r3,r3,r4
	      	ble  	r3,FMTKc_50
	      	lw   	r3,368[r11]
	      	lw   	r4,32[bp]
	      	subu 	r4,r4,r3
	      	sw   	r4,32[bp]
	      	sw   	r11,-16[bp]
	      	lw   	r11,312[r11]
	      	bra  	FMTKc_49
FMTKc_50:
	      	sw   	r11,312[r12]
	      	lw   	r3,-16[bp]
	      	sw   	r3,320[r12]
	      	beq  	r11,FMTKc_51
	      	lw   	r3,32[bp]
	      	lw   	r4,368[r11]
	      	subu 	r4,r4,r3
	      	sw   	r4,368[r11]
	      	sw   	r12,320[r11]
FMTKc_51:
	      	lw   	r3,-16[bp]
	      	beq  	r3,FMTKc_53
	      	lw   	r3,-16[bp]
	      	sw   	r12,312[r3]
	      	bra  	FMTKc_54
FMTKc_53:
	      	sw   	r12,[r13]
FMTKc_54:
	      	lb   	r3,425[r12]
	      	ori  	r3,r3,#1
	      	sb   	r3,425[r12]
	      	ldi  	r1,#0
	      	bra  	FMTKc_48
RemoveFromTimeoutList_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	push 	r11
	      	lw   	r11,24[bp]
	      	lw   	r3,312[r11]
	      	beq  	r3,FMTKc_57
	      	lw   	r3,312[r11]
	      	lw   	r4,320[r11]
	      	sw   	r4,320[r3]
	      	lw   	r3,312[r11]
	      	lw   	r4,368[r11]
	      	lw   	r5,368[r3]
	      	addu 	r5,r5,r4
	      	sw   	r5,368[r3]
FMTKc_57:
	      	lw   	r3,320[r11]
	      	beq  	r3,FMTKc_59
	      	lw   	r3,320[r11]
	      	lw   	r4,312[r11]
	      	sw   	r4,312[r3]
FMTKc_59:
	      	sb   	r0,425[r11]
	      	sw   	r0,312[r11]
	      	sw   	r0,320[r11]
FMTKc_61:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
PopTimeoutList_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	ldi  	r11,#TimeoutList_
	      	lw   	r3,[r11]
	      	sw   	r3,-8[bp]
	      	lw   	r3,[r11]
	      	beq  	r3,FMTKc_64
	      	lw   	r3,[r11]
	      	lw   	r4,312[r3]
	      	sw   	r4,[r11]
	      	lw   	r3,[r11]
	      	beq  	r3,FMTKc_66
	      	lw   	r3,[r11]
	      	sw   	r0,320[r3]
FMTKc_66:
FMTKc_64:
	      	lw   	r3,-8[bp]
	      	mov  	r1,r3
FMTKc_68:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
	data
	align	8
FMTKc_69:	; startQ_
	db	0,0,0,1,0,0,0,2,0,0,0,3
	db	0,1,0,4,0,0,0,5,0,0,0,6
	db	0,1,0,7,0,0,0,0
	align	8
FMTKc_70:	; startQNdx_
	fill.b	1,0x00
	align	8
	fill.b	1,0x00
	code
	align	16
SelectTaskToRun_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_73
	      	mov  	bp,sp
	      	subui	sp,sp,#40
	      	push 	r11
	      	push 	r12
	      	ldi  	r12,#FMTKc_70
	      	lb   	r3,[r12]
	      	addui	r3,r3,#1
	      	sb   	r3,[r12]
	      	lb   	r3,[r12]
	      	andi 	r3,r3,#31
	      	sb   	r3,[r12]
	      	lb   	r3,[r12]
	      	sxb  	r3,r3
	      	lb   	r3,FMTKc_69[r3]
	      	sxb  	r3,r3
	      	sxb  	r3,r3
	      	sw   	r3,-40[bp]
	      	sw   	r0,-8[bp]
FMTKc_74:
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#8
	      	bge  	r3,FMTKc_75
	      	lw   	r3,-40[bp]
	      	asli 	r3,r3,#3
	      	lw   	r4,readyQ_[r3]
	      	sw   	r4,-24[bp]
	      	lw   	r3,-24[bp]
	      	beq  	r3,FMTKc_77
	      	sw   	r0,-16[bp]
	      	lw   	r3,-24[bp]
	      	lw   	r11,312[r3]
FMTKc_79:
	      	lb   	r3,425[r11]
	      	and  	r3,r3,#8
	      	bne  	r3,FMTKc_81
	      	lb   	r3,426[r11]
	      	sxb  	r3,r3
	      	push 	r3
	      	bsr  	getCPU_
	      	pop  	r3
	      	mov  	r4,r1
	      	cmp  	r3,r3,r4
	      	bne  	r3,FMTKc_83
	      	lw   	r3,-40[bp]
	      	asli 	r3,r3,#3
	      	sw   	r11,readyQ_[r3]
	      	mov  	r1,r11
FMTKc_85:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_83:
FMTKc_81:
	      	lw   	r11,312[r11]
	      	lw   	r3,-16[bp]
	      	addu 	r3,r3,#1
	      	sw   	r3,-16[bp]
	      	lw   	r3,-24[bp]
	      	cmp  	r11,r11,r3
	      	beq  	r11,FMTKc_86
	      	lw   	r3,-16[bp]
	      	cmp  	r3,r3,#256
	      	blt  	r3,FMTKc_79
FMTKc_86:
FMTKc_80:
FMTKc_77:
	      	inc  	-40[bp],#1
	      	lw   	r3,-40[bp]
	      	andi 	r3,r3,#7
	      	sw   	r3,-40[bp]
FMTKc_76:
	      	inc  	-8[bp],#1
	      	bra  	FMTKc_74
FMTKc_75:
	      	bsr  	GetRunningTCB_
	      	mov  	r3,r1
	      	mov  	r1,r3
	      	bra  	FMTKc_85
FMTKc_73:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_85
public code FMTK_SystemCall_:
	      	     	         lea   sp,sys_stacks_[tr]
         sw    r1,8[tr]
         sw    r2,16[tr]
         sw    r3,24[tr]
         sw    r4,32[tr]
         sw    r5,40[tr]
         sw    r6,48[tr]
         sw    r7,56[tr]
         sw    r8,64[tr]
         sw    r9,72[tr]
         sw    r10,80[tr]
         sw    r11,88[tr]
         sw    r12,96[tr]
         sw    r13,104[tr]
         sw    r14,112[tr]
         sw    r15,120[tr]
         sw    r16,128[tr]
         sw    r17,136[tr]
         sw    r18,144[tr]
         sw    r19,152[tr]
         sw    r20,160[tr]
         sw    r21,168[tr]
         sw    r22,176[tr]
         sw    r23,184[tr]
         sw    r24,192[tr]
         sw    r25,200[tr]
         sw    r26,208[tr]
         sw    r27,216[tr]
         sw    r28,224[tr]
         sw    r29,232[tr]
         sw    r30,240[tr]
         sw    r31,248[tr]
         mfspr r1,isp
         sw    r1,256[tr]
         mfspr r1,dsp
         sw    r1,264[tr]
         mfspr r1,esp
         sw    r1,272[tr]
         mfspr r1,ipc
         sw    r1,280[tr]
         mfspr r1,dpc
         sw    r1,288[tr]
         mfspr r1,epc
         sw    r1,296[tr]
         mfspr r1,cr0
         sw    r1,304[tr]

    	 mfspr r6,epc           ; get return address into r6
    	 and   r7,r6,#-4        ; clear LSB's
    	 lh	   r7,4[r7]			; get static call number parameter into r7
    	 addui r6,r6,#8		    ; update return address
    	 sw    r6,296[tr]
    	 cmpu  r6,r7,#20
    	 bgt   r6,.bad_callno
    	 asl   r7,r7,#1
    	 lcu   r6,syscall_vectors[r7]       ; load the vector into r6
    	 or    r6,r6,#FMTK_SystemCall_ & 0xFFFFFFFFFFFF0000
    	 jsr   [r6]				; do the system function
    	 sw    r1,8[tr]
.0001:
         lw    r1,256[tr]
         mtspr isp,r1
         lw    r1,264[tr]
         mtspr dsp,r1
         lw    r1,272[tr]
         mtspr esp,r1
         lw    r1,280[tr]
         mtspr ipc,r1
         lw    r1,288[tr]
         mtspr dpc,r1
         lw    r1,296[tr]
         mtspr epc,r1
         lw    r1,304[tr]
         mtspr cr0,r1
         lw    r1,8[tr]
         lw    r2,16[tr]
         lw    r3,24[tr]
         lw    r4,32[tr]
         lw    r5,40[tr]
         lw    r6,48[tr]
         lw    r7,56[tr]
         lw    r8,64[tr]
         lw    r9,72[tr]
         lw    r10,80[tr]
         lw    r11,88[tr]
         lw    r12,96[tr]
         lw    r13,104[tr]
         lw    r14,112[tr]
         lw    r15,120[tr]
         lw    r16,128[tr]
         lw    r17,136[tr]
         lw    r18,144[tr]
         lw    r19,152[tr]
         lw    r20,160[tr]
         lw    r21,168[tr]
         lw    r22,176[tr]
         lw    r23,184[tr]
         lw    r25,200[tr]
         lw    r26,208[tr]
         lw    r27,216[tr]
         lw    r28,224[tr]
         lw    r29,232[tr]
         lw    r31,248[tr]
         rte
.bad_callno:
         ldi   r1,#E_BadFuncno
         sw    r1,8[tr]
         bra   .0001   
syscall_vectors:
        dc    FMTKInitialize_
        dc    FMTK_StartTask_
        dc    FMTK_ExitTask_
        dc    FMTK_KillTask_
        dc    FMTK_SetTaskPriority_
        dc    FMTK_Sleep_
        dc    FMTK_AllocMbx_
        dc    FMTK_FreeMbx_
        dc    FMTK_PostMsg_
        dc    FMTK_SendMsg_
        dc    FMTK_WaitMsg_
        dc    FMTK_CheckMsg_
        align  4
    
endpublic

public code FMTK_SchedulerIRQ_:
	      	     	         lea   sp,fmtk_irq_stack_+4088
         sw    r1,8[tr]
         sw    r2,16[tr]
         sw    r3,24[tr]
         sw    r4,32[tr]
         sw    r5,40[tr]
         sw    r6,48[tr]
         sw    r7,56[tr]
         sw    r8,64[tr]
         sw    r9,72[tr]
         sw    r10,80[tr]
         sw    r11,88[tr]
         sw    r12,96[tr]
         sw    r13,104[tr]
         sw    r14,112[tr]
         sw    r15,120[tr]
         sw    r16,128[tr]
         sw    r17,136[tr]
         sw    r18,144[tr]
         sw    r19,152[tr]
         sw    r20,160[tr]
         sw    r21,168[tr]
         sw    r22,176[tr]
         sw    r23,184[tr]
         sw    r24,192[tr]
         sw    r25,200[tr]
         sw    r26,208[tr]
         sw    r27,216[tr]
         sw    r28,224[tr]
         sw    r29,232[tr]
         sw    r30,240[tr]
         sw    r31,248[tr]
         mfspr r1,isp
         sw    r1,256[tr]
         mfspr r1,dsp
         sw    r1,264[tr]
         mfspr r1,esp
         sw    r1,272[tr]
         mfspr r1,ipc
         sw    r1,280[tr]
         mfspr r1,dpc
         sw    r1,288[tr]
         mfspr r1,epc
         sw    r1,296[tr]
         mfspr r1,cr0
         sw    r1,304[tr]
     
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_89
	      	mov  	bp,sp
	      	push 	r11
	      	push 	r12
	      	ldi  	r11,#missed_ticks_
	      	ldi  	r12,#TimeoutList_
	      	bsr  	GetVecno_
	      	mov  	r3,r1
	      	cmp  	r4,r3,#451
	      	beq  	r4,FMTKc_91
	      	cmp  	r4,r3,#2
	      	beq  	r4,FMTKc_92
	      	bra  	FMTKc_93
FMTKc_91:
	      	     	             ldi   r1,#3				; reset the edge sense circuit
             sh	   r1,PIC_RSTE
         
	      	bsr  	DisplayIRQLive_
	      	ldi  	r5,#sys_sema_
	      	mov  	r1,r5
	      	ldi  	r2,#10
	      	bsr  	_LockSema
	      	beq  	r1,FMTKc_95
	      	bsr  	GetRunningTCB_
	      	mov  	r3,r1
	      	lb   	r3,424[r3]
	      	beq  	r3,FMTKc_97
	      	bsr  	GetRunningTCB_
	      	mov  	r3,r1
	      	ldi  	r4,#4
	      	sb   	r4,425[r3]
FMTKc_99:
	      	lw   	r3,[r12]
	      	beq  	r3,FMTKc_100
	      	lw   	r3,[r12]
	      	lw   	r3,368[r3]
	      	bgt  	r3,FMTKc_101
	      	bsr  	PopTimeoutList_
	      	mov  	r3,r1
	      	push 	r3
	      	bsr  	InsertIntoReadyList_
	      	addui	sp,sp,#8
	      	bra  	FMTKc_102
FMTKc_101:
	      	lw   	r3,[r12]
	      	lw   	r3,368[r3]
	      	lw   	r4,[r11]
	      	subu 	r3,r3,r4
	      	subu 	r3,r3,#1
	      	lw   	r4,[r12]
	      	sw   	r3,368[r4]
	      	sw   	r0,[r11]
	      	bra  	FMTKc_100
FMTKc_102:
	      	bra  	FMTKc_99
FMTKc_100:
	      	bsr  	GetRunningTCB_
	      	mov  	r3,r1
	      	lb   	r3,424[r3]
	      	cmp  	r3,r3,#2
	      	ble  	r3,FMTKc_103
	      	bsr  	SelectTaskToRun_
	      	mov  	r3,r1
	      	push 	r3
	      	bsr  	SetRunningTCB_
	      	addui	sp,sp,#8
FMTKc_103:
	      	bsr  	GetRunningTCB_
	      	mov  	r3,r1
	      	ldi  	r4,#8
	      	sb   	r4,425[r3]
	      	bra  	FMTKc_98
FMTKc_97:
	      	inc  	[r11],#1
FMTKc_98:
	      	mov  	r1,r5
	      	bsr  	_UnlockSema
	      	bra  	FMTKc_96
FMTKc_95:
	      	inc  	[r11],#1
FMTKc_96:
	      	bra  	FMTKc_90
FMTKc_92:
	      	bsr  	GetRunningTCB_
	      	mov  	r3,r1
	      	ldi  	r4,#4
	      	sb   	r4,425[r3]
	      	bsr  	SelectTaskToRun_
	      	mov  	r3,r1
	      	push 	r3
	      	bsr  	SetRunningTCB_
	      	addui	sp,sp,#8
	      	bsr  	GetRunningTCB_
	      	mov  	r3,r1
	      	ldi  	r4,#8
	      	sb   	r4,425[r3]
	      	bra  	FMTKc_90
FMTKc_93:
FMTKc_90:
FMTKc_105:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	     	RestoreContext:
         lw    r1,256[tr]
         mtspr isp,r1
         lw    r1,264[tr]
         mtspr dsp,r1
         lw    r1,272[tr]
         mtspr esp,r1
         lw    r1,280[tr]
         mtspr ipc,r1
         lw    r1,288[tr]
         mtspr dpc,r1
         lw    r1,296[tr]
         mtspr epc,r1
         lw    r1,304[tr]
         mtspr cr0,r1
         lw    r1,8[tr]
         lw    r2,16[tr]
         lw    r3,24[tr]
         lw    r4,32[tr]
         lw    r5,40[tr]
         lw    r6,48[tr]
         lw    r7,56[tr]
         lw    r8,64[tr]
         lw    r9,72[tr]
         lw    r10,80[tr]
         lw    r11,88[tr]
         lw    r12,96[tr]
         lw    r13,104[tr]
         lw    r14,112[tr]
         lw    r15,120[tr]
         lw    r16,128[tr]
         lw    r17,136[tr]
         lw    r18,144[tr]
         lw    r19,152[tr]
         lw    r20,160[tr]
         lw    r21,168[tr]
         lw    r22,176[tr]
         lw    r23,184[tr]
         lw    r25,200[tr]
         lw    r26,208[tr]
         lw    r27,216[tr]
         lw    r28,224[tr]
         lw    r29,232[tr]
         lw    r31,248[tr]
         rti
     
FMTKc_89:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_105
endpublic

public code panic_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_107
	      	mov  	bp,sp
	      	push 	24[bp]
	      	bsr  	putstr_
	      	addui	sp,sp,#8
FMTKc_106:
	      	bra  	FMTKc_106
FMTKc_108:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_107:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_108
endpublic

public code DumpTaskList_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_112
	      	mov  	bp,sp
	      	subui	sp,sp,#32
	      	push 	r11
	      	push 	#FMTKc_109
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	sw   	r0,-24[bp]
FMTKc_113:
	      	lw   	r3,-24[bp]
	      	cmp  	r3,r3,#8
	      	bge  	r3,FMTKc_114
	      	lw   	r3,-24[bp]
	      	asli 	r3,r3,#3
	      	lw   	r4,readyQ_[r3]
	      	sw   	r4,-16[bp]
	      	lw   	r11,-16[bp]
	      	lw   	r3,-16[bp]
	      	beq  	r3,FMTKc_116
	      	sw   	r0,-32[bp]
FMTKc_118:
	      	push 	r11
	      	bsr  	chkTCB_
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	bne  	r3,FMTKc_120
	      	bra  	FMTKc_119
FMTKc_120:
	      	push 	368[r11]
	      	push 	312[r11]
	      	push 	320[r11]
	      	push 	r11
	      	lb   	r3,425[r11]
	      	sxb  	r3,r3
	      	push 	r3
	      	lb   	r3,424[r11]
	      	sxb  	r3,r3
	      	push 	r3
	      	lb   	r3,426[r11]
	      	sxb  	r3,r3
	      	push 	r3
	      	push 	#FMTKc_110
	      	bsr  	printf_
	      	addui	sp,sp,#64
	      	lw   	r11,312[r11]
	      	bsr  	getcharNoWait_
	      	mov  	r3,r1
	      	cmp  	r3,r3,#3
	      	bne  	r3,FMTKc_122
	      	bra  	FMTKc_111
FMTKc_122:
	      	lw   	r3,-32[bp]
	      	addu 	r3,r3,#1
	      	sw   	r3,-32[bp]
	      	lw   	r3,-16[bp]
	      	cmp  	r11,r11,r3
	      	beq  	r11,FMTKc_124
	      	lw   	r3,-32[bp]
	      	cmp  	r3,r3,#256
	      	blt  	r3,FMTKc_118
FMTKc_124:
FMTKc_119:
FMTKc_116:
FMTKc_115:
	      	inc  	-24[bp],#1
	      	bra  	FMTKc_113
FMTKc_114:
FMTKc_111:
FMTKc_125:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_112:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_125
endpublic

public code IdleTask_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
FMTKc_127:
	      	ldi  	r3,#1
	      	beq  	r3,FMTKc_128
	      	     	             inc  $FFD00000+228
         
	      	bra  	FMTKc_127
FMTKc_128:
FMTKc_129:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code FMTK_ExitTask_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_131
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	ldi  	r5,#sys_sema_
	      	mov  	r1,r5
	      	ldi  	r2,#-1
	      	bsr  	_LockSema
	      	push 	-8[bp]
	      	bsr  	RemoveFromReadyList_
	      	addui	sp,sp,#8
	      	push 	-8[bp]
	      	bsr  	RemoveFromTimeoutList_
	      	addui	sp,sp,#8
	      	bsr  	GetRunningTCB_
	      	mov  	r3,r1
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	lw   	r4,416[r3]
	      	sw   	r4,-16[bp]
FMTKc_135:
	      	lw   	r3,-16[bp]
	      	beq  	r3,FMTKc_136
	      	lw   	r3,-16[bp]
	      	lw   	r4,[r3]
	      	sw   	r4,-24[bp]
	      	push 	-16[bp]
	      	bsr  	FMTK_FreeMbx_
	      	addui	sp,sp,#8
	      	lw   	r3,-24[bp]
	      	sw   	r3,-16[bp]
	      	bra  	FMTKc_135
FMTKc_136:
	      	mov  	r1,r5
	      	bsr  	_UnlockSema
	      	     	int #2 
FMTKc_130:
	      	bra  	FMTKc_130
FMTKc_137:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_131:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_137
endpublic

public code FMTK_StartTask_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_138
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	ldi  	r5,#sys_sema_
	      	mov  	r1,r5
	      	ldi  	r2,#-1
	      	bsr  	_LockSema
	      	lw   	r11,freeTCB_
	      	lw   	r3,312[r11]
	      	sw   	r3,freeTCB_
	      	mov  	r1,r5
	      	bsr  	_UnlockSema
	      	lw   	r3,32[bp]
	      	sb   	r3,426[r11]
	      	lw   	r3,24[bp]
	      	sb   	r3,424[r11]
	      	lw   	r3,40[bp]
	      	sw   	r3,280[r11]
	      	lw   	r3,360[r11]
	      	addu 	r3,r3,#8184
	      	sw   	r3,256[r11]
	      	lw   	r3,56[bp]
	      	sw   	r3,376[r11]
	      	lw   	r3,48[bp]
	      	sw   	r3,8[r11]
	      	ldi  	r3,#FMTK_ExitTask_
	      	sw   	r3,248[r11]
	      	ldi  	r5,#sys_sema_
	      	mov  	r1,r5
	      	ldi  	r2,#-1
	      	bsr  	_LockSema
	      	push 	r11
	      	bsr  	InsertIntoReadyList_
	      	addui	sp,sp,#8
	      	mov  	r1,r5
	      	bsr  	_UnlockSema
	      	ldi  	r1,#0
FMTKc_145:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_138:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_145
endpublic

public code FMTK_Sleep_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_146
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	ldi  	r5,#sys_sema_
	      	mov  	r1,r5
	      	ldi  	r2,#-1
	      	bsr  	_LockSema
	      	bsr  	GetRunningTCB_
	      	mov  	r3,r1
	      	sw   	r3,-8[bp]
	      	push 	-8[bp]
	      	bsr  	RemoveFromReadyList_
	      	addui	sp,sp,#8
	      	push 	24[bp]
	      	push 	-8[bp]
	      	bsr  	InsertIntoTimeoutList_
	      	addui	sp,sp,#16
	      	mov  	r1,r5
	      	bsr  	_UnlockSema
	      	     	int #2 
	      	ldi  	r1,#0
FMTKc_150:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_146:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_150
endpublic

public code FMTK_SetTaskPriority_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_151
	      	mov  	bp,sp
	      	push 	r11
	      	lw   	r11,24[bp]
	      	lw   	r3,32[bp]
	      	cmp  	r3,r3,#63
	      	bgt  	r3,FMTKc_154
	      	lw   	r3,32[bp]
	      	bge  	r3,FMTKc_152
FMTKc_154:
	      	ldi  	r1,#4
FMTKc_155:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_152:
	      	ldi  	r5,#sys_sema_
	      	mov  	r1,r5
	      	ldi  	r2,#-1
	      	bsr  	_LockSema
	      	lb   	r3,425[r11]
	      	and  	r3,r3,#24
	      	beq  	r3,FMTKc_159
	      	push 	r11
	      	bsr  	RemoveFromReadyList_
	      	addui	sp,sp,#8
	      	lw   	r3,32[bp]
	      	sb   	r3,424[r11]
	      	push 	r11
	      	bsr  	InsertIntoReadyList_
	      	addui	sp,sp,#8
	      	bra  	FMTKc_160
FMTKc_159:
	      	lw   	r3,32[bp]
	      	sb   	r3,424[r11]
FMTKc_160:
	      	mov  	r1,r5
	      	bsr  	_UnlockSema
	      	ldi  	r1,#0
	      	bra  	FMTKc_155
FMTKc_151:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_155
endpublic

public code FMTKInitialize_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_161
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	ldi  	r11,#tcbs_
	      	ldi  	r12,#jcbs_
	      	ldi  	r13,#message_
	      	lw   	r3,FMTK_Inited_
	      	cmp  	r3,r3,#305419896
	      	beq  	r3,FMTKc_162
	      	     	            ldi   r1,#20
            sc    r1,LEDS
        
	      	ldi  	r1,#sys_sema_
	      	bsr  	_UnlockSema
	      	ldi  	r1,#iof_sema_
	      	bsr  	_UnlockSema
	      	sc   	r0,hasUltraHighPriorityTasks_
	      	sw   	r0,missed_ticks_
	      	sw   	r0,IOFocusTbl_
	      	sw   	r0,IOFocusNdx_
	      	push 	#511
	      	ldi  	r3,#131072
	      	addu 	r3,r3,r11
	      	push 	r3
	      	push 	r11
	      	bsr  	SetBound48_
	      	addui	sp,sp,#24
	      	push 	#2047
	      	ldi  	r3,#104448
	      	addu 	r3,r3,r12
	      	push 	r3
	      	push 	r12
	      	bsr  	SetBound49_
	      	addui	sp,sp,#24
	      	push 	#127
	      	ldi  	r3,#262144
	      	addu 	r3,r3,#mailbox_
	      	push 	r3
	      	push 	#mailbox_
	      	bsr  	SetBound50_
	      	addui	sp,sp,#24
	      	push 	#31
	      	ldi  	r3,#1048576
	      	addu 	r3,r3,r13
	      	push 	r3
	      	push 	r13
	      	bsr  	SetBound51_
	      	addui	sp,sp,#24
	      	sw   	r0,-8[bp]
FMTKc_164:
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#32768
	      	bge  	r3,FMTKc_165
	      	ldi  	r3,#32
	      	lw   	r4,-8[bp]
	      	asli 	r4,r4,#5
	      	addu 	r4,r4,r13
	      	addu 	r3,r3,r4
	      	lw   	r4,-8[bp]
	      	asli 	r4,r4,#5
	      	sw   	r3,0[r13+r4]
FMTKc_166:
	      	inc  	-8[bp],#1
	      	bra  	FMTKc_164
FMTKc_165:
	      	sw   	r0,1048544[r13]
	      	sw   	r13,freeMSG_
	      	     	            ldi   r1,#30
            sc    r1,LEDS
        
	      	sw   	r0,-8[bp]
FMTKc_167:
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#51
	      	bge  	r3,FMTKc_168
	      	lw   	r3,-8[bp]
	      	lw   	r4,-8[bp]
	      	asli 	r4,r4,#11
	      	addu 	r4,r4,r12
	      	sc   	r3,1678[r4]
	      	lw   	r3,-8[bp]
	      	bne  	r3,FMTKc_170
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#11
	      	addu 	r3,r3,r12
	      	ldi  	r4,#4291821568
	      	sw   	r4,1616[r3]
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#11
	      	addu 	r3,r3,r12
	      	sw   	r0,1624[r3]
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#11
	      	addu 	r3,r3,r12
	      	ldi  	r4,#2537472
	      	sh   	r4,1640[r3]
	      	push 	r12
	      	bsr  	RequestIOFocus_
	      	addui	sp,sp,#8
	      	bra  	FMTKc_171
FMTKc_170:
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#11
	      	addu 	r3,r3,r12
	      	sw   	r0,1616[r3]
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#11
	      	addu 	r3,r3,r12
	      	sw   	r0,1624[r3]
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#11
	      	addu 	r3,r3,r12
	      	ldi  	r4,#2537472
	      	sh   	r4,1640[r3]
FMTKc_171:
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#11
	      	addu 	r3,r3,r12
	      	ldi  	r4,#31
	      	sc   	r4,1632[r3]
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#11
	      	addu 	r3,r3,r12
	      	ldi  	r4,#84
	      	sc   	r4,1634[r3]
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#11
	      	addu 	r3,r3,r12
	      	sc   	r0,1636[r3]
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#11
	      	addu 	r3,r3,r12
	      	sc   	r0,1638[r3]
FMTKc_169:
	      	inc  	-8[bp],#1
	      	bra  	FMTKc_167
FMTKc_168:
	      	     	            ldi   r1,#40
            sc    r1,LEDS
        
	      	sw   	r0,-8[bp]
FMTKc_172:
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#8
	      	bge  	r3,FMTKc_173
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#3
	      	sw   	r0,readyQ_[r3]
FMTKc_174:
	      	inc  	-8[bp],#1
	      	bra  	FMTKc_172
FMTKc_173:
	      	sw   	r0,-8[bp]
FMTKc_175:
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#256
	      	bge  	r3,FMTKc_176
	      	lw   	r3,-8[bp]
	      	lw   	r4,-8[bp]
	      	asli 	r4,r4,#9
	      	addu 	r4,r4,r11
	      	sc   	r3,428[r4]
	      	ldi  	r3,#512
	      	lw   	r4,-8[bp]
	      	asli 	r4,r4,#9
	      	addu 	r4,r4,r11
	      	addu 	r3,r3,r4
	      	lw   	r4,-8[bp]
	      	asli 	r4,r4,#9
	      	addu 	r4,r4,r11
	      	sw   	r3,312[r4]
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#9
	      	addu 	r3,r3,r11
	      	sw   	r0,320[r3]
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#9
	      	addu 	r3,r3,r11
	      	sb   	r0,425[r3]
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#9
	      	addu 	r3,r3,r11
	      	ldi  	r4,#56
	      	sb   	r4,424[r3]
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#9
	      	addu 	r3,r3,r11
	      	sb   	r0,426[r3]
	      	ldi  	r3,#sys_stacks_
	      	addu 	r3,r3,#4088
	      	lw   	r4,-8[bp]
	      	asli 	r4,r4,#9
	      	addu 	r4,r4,r11
	      	sw   	r3,344[r4]
	      	ldi  	r3,#bios_stacks_
	      	addu 	r3,r3,#4088
	      	lw   	r4,-8[bp]
	      	asli 	r4,r4,#9
	      	addu 	r4,r4,r11
	      	sw   	r3,352[r4]
	      	ldi  	r3,#stacks_
	      	addu 	r3,r3,#8184
	      	lw   	r4,-8[bp]
	      	asli 	r4,r4,#9
	      	addu 	r4,r4,r11
	      	sw   	r3,360[r4]
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#9
	      	addu 	r3,r3,r11
	      	sw   	r12,376[r3]
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#9
	      	addu 	r3,r3,r11
	      	sw   	r0,368[r3]
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#9
	      	addu 	r3,r3,r11
	      	sw   	r0,416[r3]
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#2
	      	bge  	r3,FMTKc_178
	      	lw   	r3,-8[bp]
	      	lw   	r4,-8[bp]
	      	asli 	r4,r4,#9
	      	addu 	r4,r4,r11
	      	sb   	r3,426[r4]
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#9
	      	addu 	r3,r3,r11
	      	ldi  	r4,#24
	      	sb   	r4,424[r3]
FMTKc_178:
FMTKc_177:
	      	inc  	-8[bp],#1
	      	bra  	FMTKc_175
FMTKc_176:
	      	sw   	r0,130872[r11]
	      	ldi  	r3,#1024
	      	addu 	r3,r3,r11
	      	sw   	r3,freeTCB_
	      	     	            ldi   r1,#42
            sc    r1,LEDS
        
	      	push 	r11
	      	bsr  	InsertIntoReadyList_
	      	addui	sp,sp,#8
	      	ldi  	r3,#512
	      	addu 	r3,r3,r11
	      	push 	r3
	      	bsr  	InsertIntoReadyList_
	      	addui	sp,sp,#8
	      	ldi  	r3,#8
	      	sb   	r3,425[r11]
	      	ldi  	r3,#8
	      	sb   	r3,937[r11]
	      	     	            ldi   r1,#44
            sc    r1,LEDS
        
	      	push 	r11
	      	bsr  	SetRunningTCB_
	      	addui	sp,sp,#8
	      	sw   	r0,TimeoutList_
	      	push 	#FMTK_SystemCall_
	      	push 	#4
	      	bsr  	set_vector_
	      	addui	sp,sp,#16
	      	push 	#FMTK_SchedulerIRQ_
	      	push 	#2
	      	bsr  	set_vector_
	      	addui	sp,sp,#16
	      	push 	#FMTK_SchedulerIRQ_
	      	push 	#451
	      	bsr  	set_vector_
	      	addui	sp,sp,#16
	      	push 	r12
	      	push 	#0
	      	push 	#IdleTask_
	      	push 	#0
	      	push 	#56
	      	bsr  	FMTK_StartTask_
	      	addui	sp,sp,#40
	      	push 	r12
	      	push 	#0
	      	push 	#IdleTask_
	      	push 	#1
	      	push 	#56
	      	bsr  	FMTK_StartTask_
	      	addui	sp,sp,#40
	      	ldi  	r3,#305419896
	      	sw   	r3,FMTK_Inited_
	      	     	            ldi   r1,#50
            sc    r1,LEDS
        
FMTKc_162:
FMTKc_180:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_161:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_180
endpublic

	rodata
	align	16
	align	8
FMTKc_110:
	dc	37,51,100,32,37,51,100,32
	dc	37,48,50,88,32,37,48,56
	dc	88,32,37,48,56,88,32,37
	dc	48,56,88,32,37,48,56,88
	dc	13,10,0
FMTKc_109:
	dc	67,80,85,32,80,114,105,32
	dc	83,116,97,116,32,32,32,84
	dc	97,115,107,32,32,32,32,32
	dc	80,114,101,118,32,32,32,32
	dc	32,78,101,120,116,32,32,32
	dc	84,105,109,101,111,117,116,13
	dc	10,0
FMTKc_72:
	dc	78,111,32,101,110,116,114,105
	dc	101,115,32,105,110,32,114,101
	dc	97,100,121,32,113,117,101,117
	dc	101,46,0
	extern	jcbs_
	extern	tcbs_
	extern	nMsgBlk_
	extern	putstr_
;	global	FMTK_SetTaskPriority_
;	global	outb_
	extern	IOFocusTbl_
;	global	outc_
;	global	FMTK_ExitTask_
;	global	outh_
	extern	irq_stack_
	extern	IOFocusNdx_
;	global	DumpTaskList_
;	global	outw_
	extern	fmtk_irq_stack_
;	global	GetRunningTCB_
	extern	runningTCB_
	extern	fmtk_sys_stack_
	extern	message_
;	global	SetRunningTCB_
	extern	mailbox_
	extern	FMTK_Inited_
	extern	missed_ticks_
;	global	panic_
;	global	chkTCB_
;	global	IdleTask_
;	global	GetVecno_
;	global	FMTK_SchedulerIRQ_
;	global	GetJCBPtr_
	extern	video_bufs_
	extern	getCPU_
	extern	hasUltraHighPriorityTasks_
	extern	iof_switch_
	extern	getcharNoWait_
;	global	FMTK_StartTask_
	extern	nMailbox_
	extern	FMTK_FreeMbx_
;	global	set_vector_
	extern	iof_sema_
;	global	FMTKInitialize_
	extern	sys_stacks_
	extern	BIOS_RespMbx_
;	global	DisplayIRQLive_
	extern	BIOS1_sema_
	extern	sys_sema_
	extern	readyQ_
	extern	sysstack_
	extern	freeTCB_
	extern	RequestIOFocus_
	extern	TimeoutList_
	extern	stacks_
	extern	freeMSG_
	extern	freeMBX_
;	global	SetBound50_
;	global	SetBound51_
;	global	FMTK_Sleep_
;	global	tempTCB_
;	global	SetBound48_
;	global	SetBound49_
;	global	FMTK_SystemCall_
	extern	printf_
	extern	bios_stacks_
