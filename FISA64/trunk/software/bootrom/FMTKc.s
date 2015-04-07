	bss
	align	8
	align	8
public bss irq_stack:
	fill.b	4096,0x00

endpublic
	align	8
public bss FMTK_Inited:
	fill.b	8,0x00

endpublic
	align	8
public bss tempTCB:
	fill.b	398,0x00

endpublic
	align	8
public bss jcbs:
	fill.b	85680,0x00

endpublic
	align	8
public bss tcbs:
	fill.b	101888,0x00

endpublic
	align	8
public bss readyQ:
	fill.b	64,0x00

endpublic
	align	8
public bss runningTCB:
	fill.b	8,0x00

endpublic
	align	8
public bss freeTCB:
	fill.b	8,0x00

endpublic
	align	8
public bss sysstack:
	fill.b	8192,0x00

endpublic
	align	8
public bss stacks:
	fill.b	1048576,0x00

endpublic
	align	8
public bss sys_stacks:
	fill.b	1048576,0x00

endpublic
	align	8
public bss bios_stacks:
	fill.b	1048576,0x00

endpublic
	align	8
public bss fmtk_irq_stack:
	fill.b	4096,0x00

endpublic
	align	8
public bss mailbox:
	fill.b	165888,0x00

endpublic
	align	8
public bss message:
	fill.b	1048576,0x00

endpublic
	align	8
public bss IOFocusNdx:
	fill.b	8,0x00

endpublic
	align	8
public bss IOFocusTbl:
	fill.b	32,0x00

endpublic
	align	8
public bss iof_switch:
	fill.b	8,0x00

endpublic
	align	8
public bss BIOS1_sema:
	fill.b	8,0x00

endpublic
	align	8
public bss iof_sema:
	fill.b	8,0x00

endpublic
	align	8
public bss sys_sema:
	fill.b	8,0x00

endpublic
	align	8
public bss BIOS_RespMbx:
	fill.b	8,0x00

endpublic
	align	8
public bss video_bufs:
	fill.b	835584,0x00

endpublic
	align	8
public bss TimeoutList:
	fill.b	8,0x00

endpublic
	code
	align	16
public code getCPU:
	      	     	         cpuid r1,r0,#0
         rtl
     
endpublic

public code SetBound48:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	     lw      r1,24[bp]
     mtspr   112,r1      ; set lower bound
     lea     r1,32[bp]
     mtspr   176,r1      ; set upper bound
     mtspr   240,r0      ; modulo mask not used
     
FMTKc_3:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code SetBound49:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	     lw      r1,24[bp]
     mtspr   113,r1      ; set lower bound
     lea     r1,32[bp]
     mtspr   177,r1      ; set upper bound
     mtspr   241,r0      ; modulo mask not used
     
FMTKc_5:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code SetBound50:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	     lw      r1,24[bp]
     mtspr   114,r1      ; set lower bound
     lea     r1,32[bp]
     mtspr   178,r1      ; set upper bound
     mtspr   242,r0      ; modulo mask not used
     
FMTKc_7:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code SetBound51:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	     lw      r1,24[bp]
     mtspr   115,r1      ; set lower bound
     lea     r1,32[bp]
     mtspr   179,r1      ; set upper bound
     mtspr   243,r0      ; modulo mask not used
     
FMTKc_9:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code chkTCB:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        lw    r1,24[bp]
        chk   r1,r1,b48
    
FMTKc_11:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code GetRunningTCB:
	      	     	        mov r1,tr
        rtl
    
endpublic

public code SetRunningTCB:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	         lw  tr,24[bp]
     
FMTKc_15:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code DisplayIRQLive:
	      	     	         inc  $FFD00000+220,#1
         rtl
     
endpublic

public code GetJCBPtr:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_18
	      	mov  	bp,sp
	      	bsr  	GetRunningTCB
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

InsertIntoReadyList:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_21
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	push 	r12
	      	push 	24[bp]
	      	bsr  	chkTCB
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
	      	lb   	r3,392[r11]
	      	cmp  	r3,r3,#7
	      	bgt  	r3,FMTKc_27
	      	lb   	r3,392[r11]
	      	bge  	r3,FMTKc_25
FMTKc_27:
	      	ldi  	r1,#2
	      	bra  	FMTKc_24
FMTKc_25:
	      	ldi  	r3,#16
	      	sb   	r3,393[r11]
	      	lb   	r3,392[r11]
	      	sxb  	r3,r3
	      	asli 	r3,r3,#3
	      	lw   	r12,readyQ[r3]
	      	bne  	r12,FMTKc_28
	      	sw   	r11,312[r11]
	      	sw   	r11,320[r11]
	      	lb   	r3,392[r11]
	      	sxb  	r3,r3
	      	asli 	r3,r3,#3
	      	sw   	r11,readyQ[r3]
	      	ldi  	r1,#0
	      	bra  	FMTKc_24
FMTKc_28:
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
RemoveFromReadyList:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_31
	      	mov  	bp,sp
	      	push 	r11
	      	push 	r12
	      	lw   	r11,24[bp]
	      	ldi  	r12,#readyQ
	      	push 	r11
	      	bsr  	chkTCB
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	bne  	r3,FMTKc_32
	      	ldi  	r1,#1
FMTKc_34:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_32:
	      	lb   	r3,392[r11]
	      	cmp  	r3,r3,#7
	      	bgt  	r3,FMTKc_37
	      	lb   	r3,392[r11]
	      	bge  	r3,FMTKc_35
FMTKc_37:
	      	ldi  	r1,#2
	      	bra  	FMTKc_34
FMTKc_35:
	      	lb   	r3,392[r11]
	      	sxb  	r3,r3
	      	asli 	r3,r3,#3
	      	lw   	r3,0[r12+r3]
	      	cmp  	r11,r11,r3
	      	bne  	r11,FMTKc_38
	      	lb   	r3,392[r11]
	      	sxb  	r3,r3
	      	asli 	r3,r3,#3
	      	lw   	r4,312[r11]
	      	sw   	r4,0[r12+r3]
FMTKc_38:
	      	lb   	r3,392[r11]
	      	sxb  	r3,r3
	      	asli 	r3,r3,#3
	      	lw   	r3,0[r12+r3]
	      	cmp  	r11,r11,r3
	      	bne  	r11,FMTKc_40
	      	asli 	r11,r11,#3
	      	sw   	r0,0[r12+r11]
FMTKc_40:
	      	lw   	r3,312[r11]
	      	lw   	r4,320[r11]
	      	sw   	r4,320[r3]
	      	lw   	r3,320[r11]
	      	lw   	r4,312[r11]
	      	sw   	r4,312[r3]
	      	sw   	r0,312[r11]
	      	sw   	r0,320[r11]
	      	sb   	r0,393[r11]
	      	ldi  	r1,#0
	      	bra  	FMTKc_34
FMTKc_31:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_34
InsertIntoTimeoutList:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	lw   	r12,24[bp]
	      	ldi  	r13,#TimeoutList
	      	lw   	r3,[r13]
	      	bne  	r3,FMTKc_44
	      	lw   	r3,32[bp]
	      	sw   	r3,368[r12]
	      	sw   	r12,[r13]
	      	sw   	r0,312[r12]
	      	sw   	r0,320[r12]
	      	ldi  	r1,#0
FMTKc_46:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
FMTKc_44:
	      	sw   	r0,-16[bp]
	      	lw   	r11,[r13]
FMTKc_47:
	      	lw   	r3,32[bp]
	      	lw   	r4,368[r11]
	      	cmp  	r3,r3,r4
	      	ble  	r3,FMTKc_48
	      	lw   	r3,368[r11]
	      	lw   	r4,32[bp]
	      	subu 	r4,r4,r3
	      	sw   	r4,32[bp]
	      	sw   	r11,-16[bp]
	      	lw   	r11,312[r11]
	      	bra  	FMTKc_47
FMTKc_48:
	      	sw   	r11,312[r12]
	      	lw   	r3,-16[bp]
	      	sw   	r3,320[r12]
	      	beq  	r11,FMTKc_49
	      	lw   	r3,32[bp]
	      	lw   	r4,368[r11]
	      	subu 	r4,r4,r3
	      	sw   	r4,368[r11]
	      	sw   	r12,320[r11]
FMTKc_49:
	      	lw   	r3,-16[bp]
	      	beq  	r3,FMTKc_51
	      	lw   	r3,-16[bp]
	      	sw   	r12,312[r3]
	      	bra  	FMTKc_52
FMTKc_51:
	      	sw   	r12,[r13]
FMTKc_52:
	      	lb   	r3,393[r12]
	      	ori  	r3,r3,#1
	      	sb   	r3,393[r12]
	      	ldi  	r1,#0
	      	bra  	FMTKc_46
RemoveFromTimeoutList:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	push 	r11
	      	lw   	r11,24[bp]
	      	lw   	r3,312[r11]
	      	beq  	r3,FMTKc_55
	      	lw   	r3,312[r11]
	      	lw   	r4,320[r11]
	      	sw   	r4,320[r3]
	      	lw   	r3,312[r11]
	      	lw   	r4,368[r11]
	      	lw   	r5,368[r3]
	      	addu 	r5,r5,r4
	      	sw   	r5,368[r3]
FMTKc_55:
	      	lw   	r3,320[r11]
	      	beq  	r3,FMTKc_57
	      	lw   	r3,320[r11]
	      	lw   	r4,312[r11]
	      	sw   	r4,312[r3]
FMTKc_57:
	      	sb   	r0,393[r11]
	      	sw   	r0,312[r11]
	      	sw   	r0,320[r11]
FMTKc_59:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
PopTimeoutList:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	ldi  	r11,#TimeoutList
	      	lw   	r3,[r11]
	      	sw   	r3,-8[bp]
	      	lw   	r3,[r11]
	      	beq  	r3,FMTKc_62
	      	lw   	r3,[r11]
	      	lw   	r4,312[r3]
	      	sw   	r4,[r11]
FMTKc_62:
	      	lw   	r3,-8[bp]
	      	mov  	r1,r3
FMTKc_64:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
	data
	align	8
	align	8
FMTKc_65:	; startQ
	db	0,0,0,1,0,0,0,2,0,0,0,3
	db	0,1,0,4,0,0,0,5,0,0,0,6
	db	0,1,0,7,0,0,0,0
	align	8
FMTKc_66:	; startQNdx
	fill.b	1,0x00
	align	8
	db	0
	code
	align	16
SelectTaskToRun:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_69
	      	mov  	bp,sp
	      	subui	sp,sp,#32
	      	push 	r11
	      	push 	r12
	      	ldi  	r12,#FMTKc_66
	      	lb   	r3,[r12]
	      	addui	r3,r3,#1
	      	sb   	r3,[r12]
	      	lb   	r3,[r12]
	      	andi 	r3,r3,#31
	      	sb   	r3,[r12]
	      	lb   	r3,[r12]
	      	sxb  	r3,r3
	      	lb   	r3,FMTKc_65[r3]
	      	sxb  	r3,r3
	      	sxb  	r3,r3
	      	sw   	r3,-32[bp]
	      	sw   	r0,-8[bp]
FMTKc_70:
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#8
	      	bge  	r3,FMTKc_71
	      	lw   	r3,-32[bp]
	      	asli 	r3,r3,#3
	      	lw   	r4,readyQ[r3]
	      	sw   	r4,-16[bp]
	      	lw   	r3,-16[bp]
	      	beq  	r3,FMTKc_73
	      	lw   	r3,-16[bp]
	      	lw   	r11,312[r3]
FMTKc_75:
	      	lb   	r3,393[r11]
	      	and  	r3,r3,#8
	      	bne  	r3,FMTKc_77
	      	lb   	r3,394[r11]
	      	sxb  	r3,r3
	      	push 	r3
	      	bsr  	getCPU
	      	pop  	r3
	      	mov  	r4,r1
	      	cmp  	r3,r3,r4
	      	bne  	r3,FMTKc_79
	      	lw   	r3,-32[bp]
	      	asli 	r3,r3,#3
	      	sw   	r11,readyQ[r3]
	      	mov  	r1,r11
FMTKc_81:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_79:
FMTKc_77:
	      	lw   	r11,312[r11]
	      	lw   	r3,-16[bp]
	      	cmp  	r11,r11,r3
	      	bne  	r11,FMTKc_75
FMTKc_76:
FMTKc_73:
	      	inc  	-32[bp],#1
	      	lw   	r3,-32[bp]
	      	andi 	r3,r3,#7
	      	sw   	r3,-32[bp]
FMTKc_72:
	      	inc  	-8[bp],#1
	      	bra  	FMTKc_70
FMTKc_71:
	      	bsr  	GetRunningTCB
	      	mov  	r3,r1
	      	mov  	r1,r3
	      	bra  	FMTKc_81
FMTKc_69:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_81
public code TimerIRQ:
	      	push 	r11
	      	ldi  	r11,#TimeoutList
	      	     	         lea   sp,fmtk_irq_stack+4088
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
     
	      	bsr  	DisplayIRQLive
	      	bsr  	GetRunningTCB
	      	mov  	r3,r1
	      	ldi  	r4,#4
	      	sb   	r4,393[r3]
FMTKc_83:
	      	lw   	r3,[r11]
	      	beq  	r3,FMTKc_84
	      	lw   	r3,[r11]
	      	lw   	r3,368[r3]
	      	bne  	r3,FMTKc_85
	      	bsr  	PopTimeoutList
	      	mov  	r3,r1
	      	push 	r3
	      	bsr  	InsertIntoReadyList
	      	addui	sp,sp,#8
	      	bra  	FMTKc_86
FMTKc_85:
	      	lw   	r3,[r11]
	      	dec  	368[r3],#1
	      	bra  	FMTKc_84
FMTKc_86:
	      	bra  	FMTKc_83
FMTKc_84:
	      	bsr  	SelectTasktoRun
	      	mov  	r3,r1
	      	push 	r3
	      	bsr  	SetRunningTCB
	      	addui	sp,sp,#8
	      	bsr  	GetRunningTCB
	      	mov  	r3,r1
	      	ldi  	r4,#8
	      	sb   	r4,393[r3]
	      	     	RestoreContext:
         lw    r1,256[tr]
         mtspr isp,r1
         lw    r1,264[tr]
         mtspr dsp,r1
         sl    r1,272[tr]
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
         lw    r30,240[tr]
         lw    r31,248[tr]
         rti
     
FMTKc_87:
FMTKc_82:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_87
endpublic

public code RescheduleIRQ:
	      	     	         lea   sp,fmtk_irq_stack+4088
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
     
	      	bsr  	GetRunningTCB
	      	mov  	r3,r1
	      	ldi  	r4,#4
	      	sb   	r4,393[r3]
	      	bsr  	SelectTasktoRun
	      	mov  	r3,r1
	      	push 	r3
	      	bsr  	SetRunningTCB
	      	addui	sp,sp,#8
	      	bsr  	GetRunningTCB
	      	mov  	r3,r1
	      	ldi  	r4,#8
	      	sb   	r4,393[r3]
	      	     	         bra   RestoreContext
     
FMTKc_89:
FMTKc_88:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_89
endpublic

public code panic:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_91
	      	mov  	bp,sp
	      	push 	24[bp]
	      	bsr  	putstr
	      	addui	sp,sp,#8
FMTKc_90:
	      	bra  	FMTKc_90
FMTKc_92:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_91:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_92
endpublic

public code DumpTaskList:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_96
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	push 	r11
	      	push 	#FMTKc_93
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	sw   	r0,-24[bp]
FMTKc_97:
	      	lw   	r3,-24[bp]
	      	cmp  	r3,r3,#8
	      	bge  	r3,FMTKc_98
	      	lw   	r3,-24[bp]
	      	asli 	r3,r3,#3
	      	lw   	r4,readyQ[r3]
	      	sw   	r4,-16[bp]
	      	lw   	r11,-16[bp]
	      	lw   	r3,-16[bp]
	      	beq  	r3,FMTKc_100
FMTKc_102:
	      	push 	368[r11]
	      	push 	312[r11]
	      	push 	320[r11]
	      	push 	r11
	      	lb   	r3,392[r11]
	      	sxb  	r3,r3
	      	push 	r3
	      	lb   	r3,394[r11]
	      	sxb  	r3,r3
	      	push 	r3
	      	push 	#FMTKc_94
	      	bsr  	printf
	      	addui	sp,sp,#56
	      	lw   	r11,312[r11]
	      	bsr  	getcharNoWait
	      	mov  	r3,r1
	      	cmp  	r3,r3,#3
	      	bne  	r3,FMTKc_104
	      	bra  	FMTKc_95
FMTKc_104:
	      	lw   	r3,-16[bp]
	      	cmp  	r11,r11,r3
	      	bne  	r11,FMTKc_102
FMTKc_103:
FMTKc_100:
FMTKc_99:
	      	inc  	-24[bp],#1
	      	bra  	FMTKc_97
FMTKc_98:
FMTKc_95:
FMTKc_106:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_96:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_106
endpublic

public code IdleTask:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
FMTKc_108:
	      	ldi  	r3,#1
	      	beq  	r3,FMTKc_109
	      	     	             inc  $FFD00000+228
         
	      	bra  	FMTKc_108
FMTKc_109:
FMTKc_110:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code ExitTask:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_112
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	bsr  	LockSYS
	      	push 	-8[bp]
	      	bsr  	RemoveFromReadyList
	      	addui	sp,sp,#8
	      	push 	-8[bp]
	      	bsr  	RemoveFromTimeoutList
	      	addui	sp,sp,#8
	      	bsr  	GetRunningTCB
	      	mov  	r3,r1
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	lw   	r4,384[r3]
	      	sw   	r4,-16[bp]
FMTKc_113:
	      	lw   	r3,-16[bp]
	      	beq  	r3,FMTKc_114
	      	lw   	r3,-16[bp]
	      	sw   	r3,-24[bp]
	      	push 	-16[bp]
	      	bsr  	FreeMbx
	      	addui	sp,sp,#8
	      	lw   	r3,-24[bp]
	      	sw   	r3,-16[bp]
	      	bra  	FMTKc_113
FMTKc_114:
	      	bsr  	UnlockSYS
	      	     	int #2 
FMTKc_111:
	      	bra  	FMTKc_111
FMTKc_115:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_112:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_115
endpublic

public code StartTask:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_116
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	bsr  	LockSYS
	      	lw   	r11,freeTCB
	      	lw   	r3,312[r11]
	      	sw   	r3,freeTCB
	      	bsr  	UnlockSYS
	      	lw   	r3,32[bp]
	      	sb   	r3,394[r11]
	      	lw   	r3,40[bp]
	      	sw   	r3,280[r11]
	      	lw   	r3,360[r11]
	      	addu 	r3,r3,#4088
	      	sw   	r3,256[r11]
	      	lw   	r3,56[bp]
	      	sw   	r3,376[r11]
	      	lw   	r3,48[bp]
	      	sw   	r3,8[r11]
	      	ldi  	r3,#ExitTask
	      	sw   	r3,248[r11]
	      	bsr  	LockSYS
	      	push 	r11
	      	bsr  	InsertIntoReadyList
	      	addui	sp,sp,#8
	      	bsr  	UnlockSYS
	      	ldi  	r1,#0
FMTKc_117:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_116:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_117
endpublic

public code FMTKInitialize:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_118
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	push 	r12
	      	ldi  	r11,#tcbs
	      	ldi  	r12,#jcbs
	      	lw   	r3,FMTK_Inited
	      	cmp  	r3,r3,#305419896
	      	beq  	r3,FMTKc_119
	      	     	            ldi   r1,#20
            sc    r1,LEDS
        
	      	bsr  	UnlockSYS
	      	bsr  	UnlockIOF
	      	sw   	r0,-8[bp]
FMTKc_121:
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#51
	      	bge  	r3,FMTKc_122
	      	lw   	r3,-8[bp]
	      	lw   	r4,-8[bp]
	      	mulu 	r4,r4,#1680
	      	addu 	r4,r4,r12
	      	sc   	r3,1678[r4]
	      	lw   	r3,-8[bp]
	      	bne  	r3,FMTKc_124
	      	lw   	r3,-8[bp]
	      	mulu 	r3,r3,#1680
	      	addu 	r3,r3,r12
	      	ldi  	r4,#4291821568
	      	sw   	r4,1616[r3]
	      	lw   	r3,-8[bp]
	      	mulu 	r3,r3,#204
	      	addu 	r3,r3,#video_bufs
	      	lw   	r4,-8[bp]
	      	mulu 	r4,r4,#1680
	      	addu 	r4,r4,r12
	      	sw   	r3,1624[r4]
	      	lw   	r3,-8[bp]
	      	mulu 	r3,r3,#1680
	      	addu 	r3,r3,r12
	      	ldi  	r4,#2537472
	      	sh   	r4,1640[r3]
	      	push 	r12
	      	bsr  	RequestIOFocus
	      	addui	sp,sp,#8
	      	bra  	FMTKc_125
FMTKc_124:
	      	lw   	r3,-8[bp]
	      	mulu 	r3,r3,#204
	      	addu 	r3,r3,#video_bufs
	      	lw   	r4,-8[bp]
	      	mulu 	r4,r4,#1680
	      	addu 	r4,r4,r12
	      	sw   	r3,1616[r4]
	      	lw   	r3,-8[bp]
	      	mulu 	r3,r3,#204
	      	addu 	r3,r3,#video_bufs
	      	lw   	r4,-8[bp]
	      	mulu 	r4,r4,#1680
	      	addu 	r4,r4,r12
	      	sw   	r3,1624[r4]
	      	lw   	r3,-8[bp]
	      	mulu 	r3,r3,#1680
	      	addu 	r3,r3,r12
	      	ldi  	r4,#2537472
	      	sh   	r4,1640[r3]
FMTKc_125:
	      	lw   	r3,-8[bp]
	      	mulu 	r3,r3,#1680
	      	addu 	r3,r3,r12
	      	ldi  	r4,#31
	      	sc   	r4,1632[r3]
	      	lw   	r3,-8[bp]
	      	mulu 	r3,r3,#1680
	      	addu 	r3,r3,r12
	      	ldi  	r4,#84
	      	sc   	r4,1634[r3]
	      	lw   	r3,-8[bp]
	      	mulu 	r3,r3,#1680
	      	addu 	r3,r3,r12
	      	sc   	r0,1636[r3]
	      	lw   	r3,-8[bp]
	      	mulu 	r3,r3,#1680
	      	addu 	r3,r3,r12
	      	sc   	r0,1638[r3]
FMTKc_123:
	      	inc  	-8[bp],#1
	      	bra  	FMTKc_121
FMTKc_122:
	      	ldi  	r3,#101888
	      	addu 	r3,r3,r11
	      	push 	r3
	      	push 	r11
	      	bsr  	SetBound48
	      	addui	sp,sp,#16
	      	ldi  	r3,#85680
	      	addu 	r3,r3,r12
	      	push 	r3
	      	push 	r12
	      	bsr  	SetBound49
	      	addui	sp,sp,#16
	      	push 	#mailbox
	      	push 	#mailbox
	      	bsr  	SetBound50
	      	addui	sp,sp,#16
	      	ldi  	r3,#1048576
	      	addu 	r3,r3,#message
	      	push 	r3
	      	push 	#message
	      	bsr  	SetBound51
	      	addui	sp,sp,#16
	      	sw   	r0,-8[bp]
FMTKc_126:
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#8
	      	bge  	r3,FMTKc_127
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#3
	      	sw   	r0,readyQ[r3]
FMTKc_128:
	      	inc  	-8[bp],#1
	      	bra  	FMTKc_126
FMTKc_127:
	      	sw   	r0,-8[bp]
FMTKc_129:
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#256
	      	bge  	r3,FMTKc_130
	      	lw   	r3,-8[bp]
	      	lw   	r4,-8[bp]
	      	mulu 	r4,r4,#398
	      	addu 	r4,r4,r11
	      	sc   	r3,396[r4]
	      	ldi  	r3,#398
	      	lw   	r4,-8[bp]
	      	mulu 	r4,r4,#398
	      	addu 	r4,r4,r11
	      	addu 	r3,r3,r4
	      	lw   	r4,-8[bp]
	      	mulu 	r4,r4,#398
	      	addu 	r4,r4,r11
	      	sw   	r3,312[r4]
	      	lw   	r3,-8[bp]
	      	mulu 	r3,r3,#398
	      	addu 	r3,r3,r11
	      	sw   	r0,320[r3]
	      	lw   	r3,-8[bp]
	      	mulu 	r3,r3,#398
	      	addu 	r3,r3,r11
	      	sb   	r0,393[r3]
	      	lw   	r3,-8[bp]
	      	mulu 	r3,r3,#398
	      	addu 	r3,r3,r11
	      	ldi  	r4,#7
	      	sb   	r4,392[r3]
	      	lw   	r3,-8[bp]
	      	mulu 	r3,r3,#398
	      	addu 	r3,r3,r11
	      	sb   	r0,394[r3]
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#11
	      	addu 	r3,r3,#sys_stacks
	      	addu 	r3,r3,#4088
	      	lw   	r4,-8[bp]
	      	mulu 	r4,r4,#398
	      	addu 	r4,r4,r11
	      	sw   	r3,344[r4]
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#11
	      	addu 	r3,r3,#bios_stacks
	      	addu 	r3,r3,#4088
	      	lw   	r4,-8[bp]
	      	mulu 	r4,r4,#398
	      	addu 	r4,r4,r11
	      	sw   	r3,352[r4]
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#11
	      	addu 	r3,r3,#stacks
	      	addu 	r3,r3,#4088
	      	lw   	r4,-8[bp]
	      	mulu 	r4,r4,#398
	      	addu 	r4,r4,r11
	      	sw   	r3,360[r4]
	      	lw   	r3,-8[bp]
	      	mulu 	r3,r3,#398
	      	addu 	r3,r3,r11
	      	sw   	r12,376[r3]
	      	lw   	r3,-8[bp]
	      	mulu 	r3,r3,#398
	      	addu 	r3,r3,r11
	      	sw   	r0,368[r3]
	      	lw   	r3,-8[bp]
	      	mulu 	r3,r3,#398
	      	addu 	r3,r3,r11
	      	sw   	r0,384[r3]
	      	lw   	r3,-8[bp]
	      	bne  	r3,FMTKc_132
	      	lw   	r3,-8[bp]
	      	mulu 	r3,r3,#398
	      	addu 	r3,r3,r11
	      	ldi  	r4,#3
	      	sb   	r4,392[r3]
FMTKc_132:
FMTKc_131:
	      	inc  	-8[bp],#1
	      	bra  	FMTKc_129
FMTKc_130:
	      	sw   	r0,101802[r11]
	      	ldi  	r3,#398
	      	addu 	r3,r3,r11
	      	sw   	r3,freeTCB
	      	push 	r11
	      	bsr  	InsertIntoReadyList
	      	addui	sp,sp,#8
	      	push 	r11
	      	bsr  	SetRunningTCB
	      	addui	sp,sp,#8
	      	sw   	r0,TimeoutList
	      	sw   	r12,IOFocusNdx
	      	ldi  	r3,#1
	      	sw   	r3,IOFocusTbl
	      	push 	#RescheduleIRQ
	      	push 	#2
	      	bsr  	set_vector
	      	addui	sp,sp,#16
	      	push 	#TimerIRQ
	      	push 	#451
	      	bsr  	set_vector
	      	addui	sp,sp,#16
	      	push 	r12
	      	push 	#0
	      	push 	#IdleTask
	      	push 	#0
	      	push 	#7
	      	bsr  	StartTask
	      	addui	sp,sp,#40
	      	push 	r12
	      	push 	#0
	      	push 	#IdleTask
	      	push 	#1
	      	push 	#7
	      	bsr  	StartTask
	      	addui	sp,sp,#40
	      	ldi  	r3,#305419896
	      	sw   	r3,FMTK_Inited
	      	     	            ldi   r1,#50
            sc    r1,LEDS
        
FMTKc_119:
FMTKc_134:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_118:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_134
endpublic

	rodata
	align	16
	align	8
FMTKc_94:
	dc	37,51,100,32,37,51,100,32
	dc	37,48,56,88,32,37,48,56
	dc	88,32,37,48,56,88,32,37
	dc	48,56,88,13,10,0
FMTKc_93:
	dc	67,80,85,32,80,114,105,32
	dc	32,32,84,97,115,107,32,32
	dc	32,32,32,80,114,101,118,32
	dc	32,32,32,32,78,101,120,116
	dc	32,32,32,84,105,109,101,111
	dc	117,116,13,10,0
FMTKc_68:
	dc	78,111,32,101,110,116,114,105
	dc	101,115,32,105,110,32,114,101
	dc	97,100,121,32,113,117,101,117
	dc	101,46,0
;	global	panic
	extern	SelectTasktoRun
;	global	chkTCB
;	global	IdleTask
;	global	GetJCBPtr
;	global	video_bufs
;	global	getCPU
;	global	ExitTask
;	global	iof_switch
	extern	getcharNoWait
	extern	set_vector
;	global	iof_sema
;	global	FMTKInitialize
;	global	sys_stacks
	extern	UnlockIOF
;	global	BIOS_RespMbx
;	global	DisplayIRQLive
;	global	BIOS1_sema
;	global	sys_sema
;	global	readyQ
	extern	UnlockSYS
;	global	sysstack
;	global	freeTCB
	extern	RequestIOFocus
;	global	TimeoutList
	extern	LockSYS
;	global	stacks
;	global	SetBound50
;	global	SetBound51
;	global	tempTCB
;	global	SetBound48
;	global	SetBound49
	extern	printf
;	global	bios_stacks
;	global	StartTask
;	global	jcbs
	extern	FreeMbx
;	global	tcbs
	extern	putstr
;	global	IOFocusTbl
;	global	irq_stack
;	global	IOFocusNdx
;	global	DumpTaskList
;	global	fmtk_irq_stack
;	global	runningTCB
;	global	GetRunningTCB
;	global	message
;	global	SetRunningTCB
;	global	mailbox
;	global	TimerIRQ
;	global	FMTK_Inited
;	global	RescheduleIRQ
