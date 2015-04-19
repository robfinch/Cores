	data
	align	8
	fill.b	1,0x00
	align	8
	fill.b	16,0x00
	align	8
	align	8
	fill.b	1984,0x00
	align	8
	align	8
	bss
	align	8
public bss irq_stack_:
	fill.b	4096,0x00

endpublic
	align	8
public bss sp_tmp_:
	fill.b	8,0x00

endpublic
	align	8
public bss FMTK_Inited_:
	fill.b	8,0x00

endpublic
	data
	align	8
	fill.b	880,0x00
	bss
	align	2048
public bss jcbs_:
	fill.b	104448,0x00

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
	align	64
public bss mailbox_:
	fill.b	65536,0x00

endpublic
	align	32
public bss message_:
	fill.b	524288,0x00

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
	fill.b	2,0x00

endpublic
	align	8
public bss freeMBX_:
	fill.b	2,0x00

endpublic
	data
	align	8
	fill.b	4,0x00
	bss
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
	code
	align	16
public code FMTK_BrTbl_:
	      	     	          bra  FMTKInitialize_
          bra  FMTK_StartTask_
          bra  FMTK_ExitTask_
          bra  FMTK_KillTask_
          bra  FMTK_SetTaskPriority_
          bra  FMTK_Sleep_
          bra  FMTK_AllocMbx_
          bra  FMTK_FreeMbx_
          bra  FMTK_PostMsg_
          bra  FMTK_SendMsg_
          bra  FMTK_WaitMsg_
          bra  FMTK_CheckMsg_
      
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
	      	ldi  	xlr,#FMTKc_6
	      	mov  	bp,sp
	      	push 	r3
	      	push 	r4
	      	push 	r5
	      	push 	r6
	      	bsr  	GetRunningTCB_
	      	pop  	r6
	      	pop  	r5
	      	pop  	r4
	      	pop  	r3
	      	mov  	r7,r1
	      	asli 	r6,r7,#10
	      	addu 	r5,r6,#tcbs_
	      	lb   	r5,719[r5]
	      	sxb  	r5,r5
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,#jcbs_
	      	mov  	r1,r3
FMTKc_7:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_6:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_7
endpublic

	data
	align	8
FMTKc_8:	; startQ_
	db	0,0,0,1,0,0,0,2,0,0,0,3
	db	0,1,0,4,0,0,0,5,0,0,0,6
	db	0,1,0,7,0,0,0,0
	align	8
FMTKc_9:	; startQNdx_
	fill.b	1,0x00
	align	8
	fill.b	1,0x00
	code
	align	16
SelectTaskToRun_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_12
	      	mov  	bp,sp
	      	subui	sp,sp,#48
	      	push 	r11
	      	push 	r12
	      	ldi  	r12,#FMTKc_9
	      	lb   	r3,[r12]
	      	addui	r3,r3,#1
	      	sb   	r3,[r12]
	      	lb   	r3,[r12]
	      	andi 	r3,r3,#31
	      	sb   	r3,[r12]
	      	lb   	r3,[r12]
	      	sxb  	r3,r3
	      	lb   	r3,FMTKc_8[r3]
	      	sxb  	r3,r3
	      	sw   	r3,-40[bp]
	      	lw   	r3,-40[bp]
	      	andi 	r3,r3,#7
	      	sw   	r3,-40[bp]
	      	sw   	r0,-8[bp]
FMTKc_13:
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#8
	      	bge  	r4,FMTKc_14
	      	lw   	r4,-40[bp]
	      	asli 	r3,r4,#1
	      	lc   	r4,readyQ_[r3]
	      	sc   	r4,-42[bp]
	      	lc   	r3,-42[bp]
	      	blt  	r3,FMTKc_16
	      	lc   	r3,-42[bp]
	      	cmp  	r4,r3,#256
	      	bge  	r4,FMTKc_16
	      	lc   	r5,-42[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,#tcbs_
	      	sw   	r3,-24[bp]
	      	sw   	r0,-16[bp]
	      	lc   	r3,-42[bp]
	      	push 	r3
	      	bsr  	GetRunningTCB_
	      	pop  	r3
	      	mov  	r4,r1
	      	sxc  	r4,r4
	      	cmp  	r5,r3,r4
	      	beq  	r5,FMTKc_18
	      	lw   	r11,-24[bp]
	      	bra  	FMTKc_19
FMTKc_18:
	      	lw   	r5,-24[bp]
	      	lc   	r5,624[r5]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,#tcbs_
	      	mov  	r11,r3
FMTKc_19:
FMTKc_20:
	      	lb   	r4,717[r11]
	      	and  	r3,r4,#8
	      	bne  	r3,FMTKc_22
	      	lb   	r3,718[r11]
	      	sxb  	r3,r3
	      	push 	r3
	      	bsr  	getCPU_
	      	pop  	r3
	      	mov  	r4,r1
	      	cmp  	r5,r3,r4
	      	bne  	r5,FMTKc_24
	      	subu 	r4,r11,#tcbs_
	      	lsri 	r3,r4,#10
	      	lw   	r5,-40[bp]
	      	asli 	r4,r5,#1
	      	sc   	r3,readyQ_[r4]
	      	subu 	r4,r11,#tcbs_
	      	lsri 	r3,r4,#10
	      	mov  	r1,r3
FMTKc_26:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_24:
FMTKc_22:
	      	lc   	r5,624[r11]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,#tcbs_
	      	mov  	r11,r3
	      	lw   	r4,-16[bp]
	      	addu 	r3,r4,#1
	      	sw   	r3,-16[bp]
	      	lw   	r3,-24[bp]
	      	cmp  	r4,r11,r3
	      	beq  	r4,FMTKc_27
	      	lw   	r3,-16[bp]
	      	cmp  	r4,r3,#256
	      	blt  	r4,FMTKc_20
FMTKc_27:
FMTKc_21:
FMTKc_16:
	      	inc  	-40[bp],#1
	      	lw   	r3,-40[bp]
	      	andi 	r3,r3,#7
	      	sw   	r3,-40[bp]
FMTKc_15:
	      	inc  	-8[bp],#1
	      	bra  	FMTKc_13
FMTKc_14:
	      	bsr  	GetRunningTCB_
	      	mov  	r3,r1
	      	mov  	r1,r3
	      	bra  	FMTKc_26
FMTKc_12:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_26
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
    	 asl   r7,r7,#2
    	 lw    r1,8[tr]         ; get back r1, we trashed it above
    	 push  r5
    	 push  r4
    	 push  r3
    	 push  r2
    	 push  r1
    	 jsr   FMTK_BrTbl_[r7]	; do the system function
    	 addui sp,sp,#40
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
    
endpublic

public code FMTK_SchedulerIRQ_:
	      	     	         lea   sp,fmtk_irq_stack_+4088
         sw    r1,8+312[tr]
         sw    r2,16+312[tr]
         sw    r3,24+312[tr]
         sw    r4,32+312[tr]
         sw    r5,40+312[tr]
         sw    r6,48+312[tr]
         sw    r7,56+312[tr]
         sw    r8,64+312[tr]
         sw    r9,72+312[tr]
         sw    r10,80+312[tr]
         sw    r11,88+312[tr]
         sw    r12,96+312[tr]
         sw    r13,104+312[tr]
         sw    r14,112+312[tr]
         sw    r15,120+312[tr]
         sw    r16,128+312[tr]
         sw    r17,136+312[tr]
         sw    r18,144+312[tr]
         sw    r19,152+312[tr]
         sw    r20,160+312[tr]
         sw    r21,168+312[tr]
         sw    r22,176+312[tr]
         sw    r23,184+312[tr]
         sw    r24,192+312[tr]
         sw    r25,200+312[tr]
         sw    r26,208+312[tr]
         sw    r27,216+312[tr]
         sw    r28,224+312[tr]
         sw    r29,232+312[tr]
         sw    r30,240+312[tr]
         sw    r31,248+312[tr]
         mfspr r1,isp
         sw    r1,256+312[tr]
         mfspr r1,dsp
         sw    r1,264+312[tr]
         mfspr r1,esp
         sw    r1,272+312[tr]
         mfspr r1,ipc
         sw    r1,280+312[tr]
         mfspr r1,dpc
         sw    r1,288+312[tr]
         mfspr r1,epc
         sw    r1,296+312[tr]
         mfspr r1,cr0
         sw    r1,304+312[tr]
         mfspr r1,tick
         sw    r1,$2D8[tr]
     
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_30
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	push 	r14
	      	ldi  	r12,#TimeoutList_
	      	ldi  	r13,#missed_ticks_
	      	ldi  	r14,#tcbs_
	      	bsr  	GetVecno_
	      	mov  	r3,r1
	      	cmp  	r4,r3,#451
	      	beq  	r4,FMTKc_32
	      	cmp  	r4,r3,#2
	      	beq  	r4,FMTKc_33
	      	bra  	FMTKc_34
FMTKc_32:
	      	     	             ldi   r1,#3				; reset the edge sense circuit
             sh	   r1,PIC_RSTE
         
	      	bsr  	DisplayIRQLive_
	      	push 	#10
	      	push 	#sys_sema_
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKc_35
	      	bsr  	GetRunningTCBPtr_
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lw   	r4,736[r11]
	      	lw   	r6,728[r11]
	      	lw   	r7,720[r11]
	      	subu 	r5,r6,r7
	      	addu 	r3,r4,r5
	      	sw   	r3,736[r11]
	      	lb   	r3,716[r11]
	      	beq  	r3,FMTKc_37
	      	ldi  	r3,#4
	      	sb   	r3,717[r11]
FMTKc_39:
	      	lc   	r3,[r12]
	      	blt  	r3,FMTKc_40
	      	lc   	r3,[r12]
	      	cmp  	r4,r3,#256
	      	bge  	r4,FMTKc_40
	      	lc   	r5,[r12]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r14
	      	lw   	r3,656[r3]
	      	bgt  	r3,FMTKc_41
	      	bsr  	PopTimeoutList_
	      	mov  	r3,r1
	      	push 	r3
	      	bsr  	InsertIntoReadyList_
	      	bra  	FMTKc_42
FMTKc_41:
	      	lc   	r7,[r12]
	      	asli 	r6,r7,#10
	      	addu 	r5,r6,r14
	      	lw   	r5,656[r5]
	      	lw   	r6,[r13]
	      	subu 	r4,r5,r6
	      	subu 	r3,r4,#1
	      	lc   	r6,[r12]
	      	asli 	r5,r6,#10
	      	addu 	r4,r5,r14
	      	sw   	r3,656[r4]
	      	sw   	r0,[r13]
	      	bra  	FMTKc_40
FMTKc_42:
	      	bra  	FMTKc_39
FMTKc_40:
	      	lb   	r3,716[r11]
	      	cmp  	r4,r3,#2
	      	ble  	r4,FMTKc_43
	      	bsr  	SelectTaskToRun_
	      	mov  	r3,r1
	      	push 	r3
	      	bsr  	SetRunningTCB_
FMTKc_43:
	      	bsr  	GetRunningTCBPtr_
	      	mov  	r3,r1
	      	ldi  	r4,#8
	      	sb   	r4,717[r3]
	      	bra  	FMTKc_38
FMTKc_37:
	      	inc  	[r13],#1
FMTKc_38:
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
	      	bra  	FMTKc_36
FMTKc_35:
	      	inc  	[r13],#1
FMTKc_36:
	      	bra  	FMTKc_31
FMTKc_33:
	      	bsr  	GetRunningTCBPtr_
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lw   	r4,736[r11]
	      	lw   	r6,728[r11]
	      	lw   	r7,720[r11]
	      	subu 	r5,r6,r7
	      	addu 	r3,r4,r5
	      	sw   	r3,736[r11]
	      	ldi  	r3,#4
	      	sb   	r3,717[r11]
	      	lw   	r4,592[r11]
	      	addu 	r3,r4,#4
	      	sw   	r3,592[r11]
	      	bsr  	SelectTaskToRun_
	      	mov  	r3,r1
	      	push 	r3
	      	bsr  	SetRunningTCB_
	      	bsr  	GetRunningTCBPtr_
	      	mov  	r3,r1
	      	ldi  	r4,#8
	      	sb   	r4,717[r3]
	      	bra  	FMTKc_31
FMTKc_34:
FMTKc_31:
FMTKc_45:
	      	pop  	r14
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	     	RestoreContext:
         mfspr r1,tick
         sw    r1,$2d0[tr]
         lw    r1,256+312[tr]
         mtspr isp,r1
         lw    r1,264+312[tr]
         mtspr dsp,r1
         lw    r1,272+312[tr]
         mtspr esp,r1
         lw    r1,280+312[tr]
         mtspr ipc,r1
         lw    r1,288+312[tr]
         mtspr dpc,r1
         lw    r1,296+312[tr]
         mtspr epc,r1
         lw    r1,304+312[tr]
         mtspr cr0,r1
         lw    r1,8+312[tr]
         lw    r2,16+312[tr]
         lw    r3,24+312[tr]
         lw    r4,32+312[tr]
         lw    r5,40+312[tr]
         lw    r6,48+312[tr]
         lw    r7,56+312[tr]
         lw    r8,64+312[tr]
         lw    r9,72+312[tr]
         lw    r10,80+312[tr]
         lw    r11,88+312[tr]
         lw    r12,96+312[tr]
         lw    r13,104+312[tr]
         lw    r14,112+312[tr]
         lw    r15,120+312[tr]
         lw    r16,128+312[tr]
         lw    r17,136+312[tr]
         lw    r18,144+312[tr]
         lw    r19,152+312[tr]
         lw    r20,160+312[tr]
         lw    r21,168+312[tr]
         lw    r22,176+312[tr]
         lw    r23,184+312[tr]
         lw    r25,200+312[tr]
         lw    r26,208+312[tr]
         lw    r27,216+312[tr]
         lw    r28,224+312[tr]
         lw    r29,232+312[tr]
         lw    r31,248+312[tr]
         rti
     
FMTKc_30:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_45
endpublic

public code panic_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_47
	      	mov  	bp,sp
	      	push 	24[bp]
	      	bsr  	putstr_
	      	addui	sp,sp,#8
FMTKc_46:
	      	bra  	FMTKc_46
FMTKc_48:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_47:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_48
endpublic

public code IdleTask_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
FMTKc_50:
	      	ldi  	r3,#1
	      	beq  	r3,FMTKc_51
	      	     	             inc  $FFD00000+228
         
	      	bra  	FMTKc_50
FMTKc_51:
FMTKc_52:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

	data
	align	8
	code
	align	16
public code FMTK_ExitTask_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_54
	      	mov  	bp,sp
	      	subui	sp,sp,#32
	      	push 	r11
	      	ldi  	r11,#tcbs_
	      	     	mfspr r1,ivno 
	      	bsr  	GetRunningTCB_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	push 	#-1
	      	push 	#sys_sema_
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKc_55
	      	lc   	r3,-2[bp]
	      	push 	r3
	      	bsr  	RemoveFromReadyList_
	      	lc   	r3,-2[bp]
	      	push 	r3
	      	bsr  	RemoveFromTimeoutList_
	      	sw   	r0,-32[bp]
FMTKc_57:
	      	lw   	r3,-32[bp]
	      	cmp  	r4,r3,#4
	      	bge  	r4,FMTKc_58
	      	lw   	r4,-24[bp]
	      	asli 	r3,r4,#1
	      	lc   	r7,-2[bp]
	      	asli 	r6,r7,#10
	      	addu 	r5,r6,r11
	      	addu 	r4,r5,#704
	      	lc   	r3,0[r4+r3]
	      	blt  	r3,FMTKc_60
	      	lw   	r5,-32[bp]
	      	asli 	r4,r5,#1
	      	lc   	r7,-2[bp]
	      	asli 	r6,r7,#10
	      	addu 	r5,r6,r11
	      	addu 	r3,r4,r5
	      	lc   	r3,704[r3]
	      	push 	r3
	      	bsr  	FMTK_FreeMbx_
	      	addui	sp,sp,#8
	      	lw   	r5,-32[bp]
	      	asli 	r4,r5,#1
	      	lc   	r7,-2[bp]
	      	asli 	r6,r7,#10
	      	addu 	r5,r6,r11
	      	addu 	r3,r4,r5
	      	ldi  	r4,#-1
	      	sc   	r4,704[r3]
FMTKc_60:
FMTKc_59:
	      	inc  	-32[bp],#1
	      	bra  	FMTKc_57
FMTKc_58:
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
FMTKc_55:
	      	     	int #2 
FMTKc_53:
	      	bra  	FMTKc_53
FMTKc_62:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_54:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_62
endpublic

	data
	align	8
	code
	align	16
public code FMTK_StartTask_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_63
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	push 	r11
	      	     	mfspr r1,ivno 
	      	push 	#-1
	      	push 	#sys_sema_
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKc_64
	      	lc   	r3,freeTCB_
	      	sc   	r3,-2[bp]
	      	lc   	r5,-2[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,#tcbs_
	      	lc   	r4,624[r3]
	      	sc   	r4,freeTCB_
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
FMTKc_64:
	      	lc   	r5,-2[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,#tcbs_
	      	mov  	r11,r3
	      	lw   	r3,32[bp]
	      	sb   	r3,718[r11]
	      	lw   	r3,24[bp]
	      	sb   	r3,716[r11]
	      	lb   	r3,56[bp]
	      	sb   	r3,719[r11]
	      	lw   	r3,48[bp]
	      	sw   	r3,320[r11]
	      	ldi  	r3,#FMTK_ExitTask_
	      	sw   	r3,560[r11]
	      	lw   	r4,648[r11]
	      	addu 	r3,r4,#8184
	      	sw   	r3,568[r11]
	      	lw   	r3,40[bp]
	      	sw   	r3,592[r11]
	      	ldi  	r3,#5368709120
	      	sw   	r3,616[r11]
	      	sw   	r0,720[r11]
	      	sw   	r0,728[r11]
	      	sw   	r0,736[r11]
	      	push 	#-1
	      	push 	#sys_sema_
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKc_66
	      	lc   	r3,-2[bp]
	      	push 	r3
	      	bsr  	InsertIntoReadyList_
FMTKc_66:
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
FMTKc_68:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_63:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_68
endpublic

	data
	align	8
	fill.b	6,0x00
	bss
	align	8
public bss E_Ok_:
	fill.b	8,0x00

endpublic
	code
	align	16
public code FMTK_Sleep_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_69
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	     	mfspr r1,ivno 
	      	push 	#-1
	      	push 	#sys_sema_
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKc_70
	      	bsr  	GetRunningTCB_
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lc   	r3,-2[bp]
	      	push 	r3
	      	bsr  	RemoveFromReadyList_
	      	push 	24[bp]
	      	lc   	r3,-2[bp]
	      	push 	r3
	      	bsr  	InsertIntoTimeoutList_
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
FMTKc_70:
	      	     	int #2 
	      	ldi  	r1,#0
FMTKc_72:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_69:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_72
endpublic

public code FMTK_SetTaskPriority_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_73
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	     	mfspr r1,ivno 
	      	lw   	r3,32[bp]
	      	cmp  	r4,r3,#63
	      	bgt  	r4,FMTKc_76
	      	lw   	r3,32[bp]
	      	bge  	r3,FMTKc_74
FMTKc_76:
	      	ldi  	r1,#4
FMTKc_77:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_74:
	      	push 	#-1
	      	push 	#sys_sema_
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKc_78
	      	lc   	r5,24[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,#tcbs_
	      	mov  	r11,r3
	      	lb   	r4,717[r11]
	      	and  	r3,r4,#24
	      	beq  	r3,FMTKc_80
	      	lc   	r3,24[bp]
	      	push 	r3
	      	bsr  	RemoveFromReadyList_
	      	lw   	r3,32[bp]
	      	sb   	r3,716[r11]
	      	lc   	r3,24[bp]
	      	push 	r3
	      	bsr  	InsertIntoReadyList_
	      	bra  	FMTKc_81
FMTKc_80:
	      	lw   	r3,32[bp]
	      	sb   	r3,716[r11]
FMTKc_81:
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
FMTKc_78:
	      	ldi  	r1,#0
	      	bra  	FMTKc_77
FMTKc_73:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_77
endpublic

public code FMTKInitialize_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_82
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	push 	r12
	      	ldi  	r11,#tcbs_
	      	ldi  	r12,#jcbs_
	      	     	mfspr r1,ivno 
	      	     	            ldi   r1,#20
            sc    r1,LEDS
        
	      	sc   	r0,hasUltraHighPriorityTasks_
	      	sw   	r0,missed_ticks_
	      	sw   	r0,IOFocusTbl_
	      	sw   	r0,IOFocusNdx_
	      	push 	#sys_sema_
	      	bsr  	UnlockSemaphore_
	      	push 	#iof_sema_
	      	bsr  	UnlockSemaphore_
	      	sw   	r0,-8[bp]
FMTKc_83:
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#16384
	      	bge  	r4,FMTKc_84
	      	lw   	r4,-8[bp]
	      	addu 	r3,r4,#1
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#5
	      	sc   	r3,message_[r4]
FMTKc_85:
	      	inc  	-8[bp],#1
	      	bra  	FMTKc_83
FMTKc_84:
	      	ldi  	r3,#message_
	      	ldi  	r4,#-1
	      	sc   	r4,524256[r3]
	      	sc   	r0,freeMSG_
	      	     	            ldi   r1,#30
            sc    r1,LEDS
        
	      	sw   	r0,-8[bp]
FMTKc_86:
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#51
	      	bge  	r4,FMTKc_87
	      	lw   	r3,-8[bp]
	      	lw   	r6,-8[bp]
	      	asli 	r5,r6,#11
	      	addu 	r4,r5,r12
	      	sb   	r3,1682[r4]
	      	lw   	r3,-8[bp]
	      	bne  	r3,FMTKc_89
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,r12
	      	ldi  	r4,#4291821568
	      	sw   	r4,1616[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,r12
	      	sw   	r0,1624[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,r12
	      	ldi  	r4,#2537472
	      	sh   	r4,1640[r3]
	      	push 	r12
	      	bsr  	RequestIOFocus_
	      	addui	sp,sp,#8
	      	bra  	FMTKc_90
FMTKc_89:
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,r12
	      	sw   	r0,1616[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,r12
	      	sw   	r0,1624[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,r12
	      	ldi  	r4,#2537472
	      	sh   	r4,1640[r3]
FMTKc_90:
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,r12
	      	ldi  	r4,#31
	      	sc   	r4,1632[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,r12
	      	ldi  	r4,#84
	      	sc   	r4,1634[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,r12
	      	sc   	r0,1636[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,r12
	      	sc   	r0,1638[r3]
FMTKc_88:
	      	inc  	-8[bp],#1
	      	bra  	FMTKc_86
FMTKc_87:
	      	     	            ldi   r1,#40
            sc    r1,LEDS
        
	      	sw   	r0,-8[bp]
FMTKc_91:
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#8
	      	bge  	r4,FMTKc_92
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	ldi  	r4,#-1
	      	sc   	r4,readyQ_[r3]
FMTKc_93:
	      	inc  	-8[bp],#1
	      	bra  	FMTKc_91
FMTKc_92:
	      	sw   	r0,-8[bp]
FMTKc_94:
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#256
	      	bge  	r4,FMTKc_95
	      	lw   	r3,-8[bp]
	      	lw   	r6,-8[bp]
	      	asli 	r5,r6,#10
	      	addu 	r4,r5,r11
	      	sc   	r3,714[r4]
	      	lw   	r4,-8[bp]
	      	addu 	r3,r4,#1
	      	lw   	r6,-8[bp]
	      	asli 	r5,r6,#10
	      	addu 	r4,r5,r11
	      	sc   	r3,624[r4]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r11
	      	ldi  	r4,#-1
	      	sc   	r4,626[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r11
	      	sb   	r0,717[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r11
	      	ldi  	r4,#56
	      	sb   	r4,716[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r11
	      	sb   	r0,718[r3]
	      	ldi  	r4,#sys_stacks_
	      	addu 	r3,r4,#4088
	      	lw   	r6,-8[bp]
	      	asli 	r5,r6,#10
	      	addu 	r4,r5,r11
	      	sw   	r3,632[r4]
	      	ldi  	r4,#bios_stacks_
	      	addu 	r3,r4,#4088
	      	lw   	r6,-8[bp]
	      	asli 	r5,r6,#10
	      	addu 	r4,r5,r11
	      	sw   	r3,640[r4]
	      	ldi  	r4,#stacks_
	      	addu 	r3,r4,#8184
	      	lw   	r6,-8[bp]
	      	asli 	r5,r6,#10
	      	addu 	r4,r5,r11
	      	sw   	r3,648[r4]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r11
	      	sb   	r0,719[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r11
	      	sw   	r0,656[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r11
	      	ldi  	r4,#-1
	      	sc   	r4,704[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r11
	      	ldi  	r4,#-1
	      	sc   	r4,706[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r11
	      	ldi  	r4,#-1
	      	sc   	r4,708[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r11
	      	ldi  	r4,#-1
	      	sc   	r4,710[r3]
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#2
	      	bge  	r4,FMTKc_97
	      	lw   	r3,-8[bp]
	      	lw   	r6,-8[bp]
	      	asli 	r5,r6,#10
	      	addu 	r4,r5,r11
	      	sb   	r3,718[r4]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r11
	      	ldi  	r4,#24
	      	sb   	r4,716[r3]
FMTKc_97:
FMTKc_96:
	      	inc  	-8[bp],#1
	      	bra  	FMTKc_94
FMTKc_95:
	      	ldi  	r3,#-1
	      	sc   	r3,261744[r11]
	      	ldi  	r3,#2
	      	sc   	r3,freeTCB_
	      	     	            ldi   r1,#42
            sc    r1,LEDS
        
	      	push 	#0
	      	bsr  	InsertIntoReadyList_
	      	push 	#1
	      	bsr  	InsertIntoReadyList_
	      	ldi  	r3,#8
	      	sb   	r3,717[r11]
	      	ldi  	r3,#8
	      	sb   	r3,1741[r11]
	      	     	            ldi   r1,#44
            sc    r1,LEDS
        
	      	push 	#0
	      	bsr  	SetRunningTCB_
	      	ldi  	r3,#-1
	      	sc   	r3,TimeoutList_
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
	      	push 	#0
	      	push 	#0
	      	push 	#IdleTask_
	      	push 	#0
	      	push 	#56
	      	bsr  	FMTK_StartTask_
	      	addui	sp,sp,#40
	      	push 	#0
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
        
FMTKc_99:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_82:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_99
endpublic

	rodata
	align	16
	align	8
FMTKc_11:
	dc	78,111,32,101,110,116,114,105
	dc	101,115,32,105,110,32,114,101
	dc	97,100,121,32,113,117,101,117
	dc	101,46,0
	extern	jcbs_
	extern	tcbs_
	extern	nMsgBlk_
	extern	PopTimeoutList_
	extern	putstr_
;	global	FMTK_SetTaskPriority_
;	global	outb_
	extern	IOFocusTbl_
;	global	outc_
;	global	FMTK_ExitTask_
;	global	outh_
	extern	irq_stack_
	extern	IOFocusNdx_
	extern	DumpTaskList_
;	global	outw_
	extern	fmtk_irq_stack_
	extern	GetRunningTCB_
	extern	fmtk_sys_stack_
	extern	message_
;	global	SetRunningTCB_
	extern	mailbox_
	extern	FMTK_Inited_
	extern	missed_ticks_
;	global	panic_
;	global	chkTCB_
	extern	GetRunningTCBPtr_
;	global	UnlockSemaphore_
;	global	IdleTask_
;	global	GetVecno_
;	global	FMTK_SchedulerIRQ_
;	global	GetJCBPtr_
	extern	video_bufs_
	extern	getCPU_
	extern	hasUltraHighPriorityTasks_
;	global	LockSemaphore_
	extern	iof_switch_
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
;	global	FMTK_BrTbl_
	extern	sysstack_
	extern	freeTCB_
	extern	RequestIOFocus_
	extern	TimeoutList_
;	global	RemoveFromTimeoutList_
;	global	SetBound50_
	extern	stacks_
	extern	freeMSG_
	extern	freeMBX_
;	global	SetBound51_
;	global	FMTK_Sleep_
;	global	SetBound48_
;	global	SetBound49_
;	global	InsertIntoTimeoutList_
;	global	FMTK_SystemCall_
;	global	RemoveFromReadyList_
;	global	sp_tmp_
	extern	bios_stacks_
;	global	InsertIntoReadyList_
