	data
	align	8
	fill.b	1,0x00
	align	8
	fill.b	16,0x00
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
public bss freeJCB_:
	fill.b	1,0x00

endpublic
	data
	align	8
	fill.b	1,0x00
	bss
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
	fill.b	2,0x00
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
	      	     	         lh       r1,$FFD00000+220
         addui    r1,r1,#1
         sh       r1,$FFD00000+220
         rtl
     
endpublic

public code GetJCBPtr_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_9
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
	      	lea  	r7,tcbs_[gp]
	      	addu 	r5,r6,r7
	      	lb   	r5,719[r5]
	      	sxb  	r5,r5
	      	asli 	r4,r5,#11
	      	lea  	r5,jcbs_[gp]
	      	addu 	r3,r4,r5
	      	mov  	r1,r3
FMTKc_11:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_9:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_11
endpublic

	data
	align	8
FMTKc_12:	; startQ_
	db	0,0,0,1,0,0,0,2,0,0,0,3
	db	0,1,0,4,0,0,0,5,0,0,0,6
	db	0,1,0,7,0,0,0,0
	align	8
FMTKc_13:	; startQNdx_
	fill.b	1,0x00
	align	8
	fill.b	1,0x00
	code
	align	16
SelectTaskToRun_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_16
	      	mov  	bp,sp
	      	subui	sp,sp,#48
	      	push 	r11
	      	push 	r12
	      	lea  	r3,FMTKc_13[gp]
	      	mov  	r12,r3
	      	lb   	r3,[r12]
	      	addui	r3,r3,#1
	      	sb   	r3,[r12]
	      	lb   	r3,[r12]
	      	andi 	r3,r3,#31
	      	sb   	r3,[r12]
	      	lb   	r3,[r12]
	      	sxb  	r3,r3
	      	lea  	r4,FMTKc_12[gp]
	      	lb   	r3,0[r4+r3]
	      	sxb  	r3,r3
	      	sw   	r3,-40[bp]
	      	lw   	r3,-40[bp]
	      	andi 	r3,r3,#7
	      	sw   	r3,-40[bp]
	      	sw   	r0,-8[bp]
FMTKc_18:
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#8
	      	bge  	r4,FMTKc_19
	      	lw   	r4,-40[bp]
	      	asli 	r3,r4,#1
	      	lea  	r4,readyQ_[gp]
	      	lc   	r5,0[r4+r3]
	      	sc   	r5,-42[bp]
	      	lc   	r3,-42[bp]
	      	blt  	r3,FMTKc_21
	      	lc   	r3,-42[bp]
	      	cmp  	r4,r3,#256
	      	bge  	r4,FMTKc_21
	      	lc   	r5,-42[bp]
	      	asli 	r4,r5,#10
	      	lea  	r5,tcbs_[gp]
	      	addu 	r3,r4,r5
	      	sw   	r3,-24[bp]
	      	sw   	r0,-16[bp]
	      	lc   	r3,-42[bp]
	      	push 	r3
	      	bsr  	GetRunningTCB_
	      	pop  	r3
	      	mov  	r4,r1
	      	sxc  	r4,r4
	      	cmp  	r5,r3,r4
	      	beq  	r5,FMTKc_23
	      	lw   	r11,-24[bp]
	      	bra  	FMTKc_24
FMTKc_23:
	      	lw   	r5,-24[bp]
	      	lc   	r5,624[r5]
	      	asli 	r4,r5,#10
	      	lea  	r5,tcbs_[gp]
	      	addu 	r3,r4,r5
	      	mov  	r11,r3
FMTKc_24:
FMTKc_25:
	      	lb   	r4,717[r11]
	      	and  	r3,r4,#8
	      	bne  	r3,FMTKc_27
	      	lb   	r3,718[r11]
	      	sxb  	r3,r3
	      	push 	r3
	      	bsr  	getCPU_
	      	pop  	r3
	      	mov  	r4,r1
	      	cmp  	r5,r3,r4
	      	bne  	r5,FMTKc_29
	      	lw   	r4,-40[bp]
	      	asli 	r3,r4,#1
	      	lea  	r4,readyQ_[gp]
	      	lea  	r7,tcbs_[gp]
	      	subu 	r6,r11,r7
	      	lsri 	r5,r6,#10
	      	sc   	r5,0[r4+r3]
	      	lea  	r5,tcbs_[gp]
	      	subu 	r4,r11,r5
	      	lsri 	r3,r4,#10
	      	mov  	r1,r3
FMTKc_31:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_29:
FMTKc_27:
	      	lc   	r5,624[r11]
	      	asli 	r4,r5,#10
	      	lea  	r5,tcbs_[gp]
	      	addu 	r3,r4,r5
	      	mov  	r11,r3
	      	lw   	r4,-16[bp]
	      	addu 	r3,r4,#1
	      	sw   	r3,-16[bp]
	      	lw   	r3,-24[bp]
	      	cmp  	r4,r11,r3
	      	beq  	r4,FMTKc_32
	      	lw   	r3,-16[bp]
	      	cmp  	r4,r3,#256
	      	blt  	r4,FMTKc_25
FMTKc_32:
FMTKc_26:
FMTKc_21:
	      	inc  	-40[bp],#1
	      	lw   	r3,-40[bp]
	      	andi 	r3,r3,#7
	      	sw   	r3,-40[bp]
FMTKc_20:
	      	inc  	-8[bp],#1
	      	bra  	FMTKc_18
FMTKc_19:
	      	bsr  	GetRunningTCB_
	      	mov  	r3,r1
	      	mov  	r1,r3
	      	bra  	FMTKc_31
FMTKc_16:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_31
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
	      	ldi  	xlr,#FMTKc_36
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	push 	r14
	      	lea  	r3,TimeoutList_[gp]
	      	mov  	r12,r3
	      	lea  	r3,missed_ticks_[gp]
	      	mov  	r13,r3
	      	lea  	r3,tcbs_[gp]
	      	mov  	r14,r3
	      	bsr  	GetVecno_
	      	mov  	r3,r1
	      	cmp  	r4,r3,#451
	      	beq  	r4,FMTKc_39
	      	cmp  	r4,r3,#2
	      	beq  	r4,FMTKc_40
	      	bra  	FMTKc_41
FMTKc_39:
	      	     	             ldi   r1,#3				; reset the edge sense circuit
             sh	   r1,PIC_RSTE
         
	      	bsr  	getCPU_
	      	mov  	r3,r1
	      	bne  	r3,FMTKc_42
	      	bsr  	DisplayIRQLive_
FMTKc_42:
	      	push 	#10
	      	pea  	sys_sema_[gp]
	      	bsr  	ILockSemaphore_
	      	addui	sp,sp,#16
	      	mov  	r3,r1
	      	beq  	r3,FMTKc_44
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
	      	beq  	r3,FMTKc_46
	      	ldi  	r3,#4
	      	sb   	r3,717[r11]
FMTKc_48:
	      	lc   	r3,[r12]
	      	blt  	r3,FMTKc_49
	      	lc   	r3,[r12]
	      	cmp  	r4,r3,#256
	      	bge  	r4,FMTKc_49
	      	lc   	r5,[r12]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r14
	      	lw   	r3,656[r3]
	      	bgt  	r3,FMTKc_50
	      	bsr  	PopTimeoutList_
	      	mov  	r3,r1
	      	push 	r3
	      	bsr  	InsertIntoReadyList_
	      	bra  	FMTKc_51
FMTKc_50:
	      	lc   	r5,[r12]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r14
	      	lc   	r8,[r12]
	      	asli 	r7,r8,#10
	      	addu 	r6,r7,r14
	      	lw   	r6,656[r6]
	      	lw   	r7,[r13]
	      	subu 	r5,r6,r7
	      	subu 	r4,r5,#1
	      	sw   	r4,656[r3]
	      	sw   	r0,[r13]
	      	bra  	FMTKc_49
FMTKc_51:
	      	bra  	FMTKc_48
FMTKc_49:
	      	lb   	r3,716[r11]
	      	cmp  	r4,r3,#2
	      	ble  	r4,FMTKc_52
	      	bsr  	SelectTaskToRun_
	      	mov  	r3,r1
	      	push 	r3
	      	bsr  	SetRunningTCB_
FMTKc_52:
	      	bsr  	GetRunningTCBPtr_
	      	mov  	r3,r1
	      	ldi  	r4,#8
	      	sb   	r4,717[r3]
	      	bra  	FMTKc_47
FMTKc_46:
	      	inc  	[r13],#1
FMTKc_47:
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
	      	bra  	FMTKc_45
FMTKc_44:
	      	inc  	[r13],#1
FMTKc_45:
	      	bra  	FMTKc_38
FMTKc_40:
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
	      	bra  	FMTKc_38
FMTKc_41:
FMTKc_38:
	      	bsr  	GetRunningTCBPtr_
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lw   	r3,744[r11]
	      	beq  	r3,FMTKc_54
	      	lw   	r3,536[r11]
	      	sw   	r3,560[r11]
	      	lw   	r3,536[r11]
	      	sw   	r3,592[r11]
	      	lw   	r3,744[r11]
	      	sw   	r3,320[r11]
	      	sw   	r0,744[r11]
	      	ldi  	r3,#24
	      	sw   	r3,328[r11]
FMTKc_54:
FMTKc_56:
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
     
FMTKc_36:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_56
endpublic

public code panic_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_58
	      	mov  	bp,sp
	      	push 	24[bp]
	      	bsr  	putstr_
	      	addui	sp,sp,#8
FMTKc_57:
	      	bra  	FMTKc_57
FMTKc_60:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_58:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_60
endpublic

	data
	align	8
FMTKc_62:	; ex_
	dw	0
	code
	align	16
public code IdleTask_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_64
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	ldi  	r3,#4291821568
	      	sw   	r3,-16[bp]
FMTKc_61:
FMTKc_66:
	      	ldi  	xlr,#FMTKc_69
	      	inc  	-8[bp],#1
	      	bsr  	getCPU_
	      	mov  	r3,r1
	      	bne  	r3,FMTKc_70
	      	ldi  	r4,#4
	      	mulu 	r3,r4,#57
	      	lw   	r4,-16[bp]
	      	lw   	r5,-8[bp]
	      	sh   	r5,0[r4+r3]
FMTKc_70:
	      	bra  	FMTKc_68
FMTKc_69:
FMTKc_72:
	      	cmp  	r3,r2,#24
	      	bne  	r3,FMTKc_73
	      	sw   	r1,FMTKc_62[gp]
	      	lw   	r4,FMTKc_62[gp]
	      	ldi  	r5,#4294967295
	      	cmp  	r6,r5,#515
	      	bne  	r6,FMTKc_75
	      	ldi  	r5,#1
	      	bra  	FMTKc_76
FMTKc_75:
	      	ldi  	r5,#0
FMTKc_76:
	      	and  	r3,r4,r5
	      	beq  	r3,FMTKc_73
	      	pea  	FMTKc_63[gp]
	      	bsr  	printf_
	      	addui	sp,sp,#8
	      	bra  	FMTKc_74
FMTKc_73:
	      	lw   	r1,FMTKc_62[gp]
	      	ldi  	r2,#24
	      	bra  	FMTKc_64
FMTKc_74:
FMTKc_68:
	      	ldi  	xlr,#FMTKc_64
	      	bra  	FMTKc_66
FMTKc_67:
FMTKc_77:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_64:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_77
endpublic

	data
	align	8
	code
	align	16
public code FMTK_KillTask_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_78
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	push 	r11
	      	push 	r12
	      	lea  	r3,tcbs_[gp]
	      	mov  	r12,r3
	      	     	mfspr r1,ivno 
	      	lw   	r3,24[bp]
	      	sc   	r3,-2[bp]
	      	push 	#-1
	      	pea  	sys_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKc_80
	      	lc   	r3,-2[bp]
	      	push 	r3
	      	bsr  	RemoveFromReadyList_
	      	lc   	r3,-2[bp]
	      	push 	r3
	      	bsr  	RemoveFromTimeoutList_
	      	sw   	r0,-16[bp]
FMTKc_82:
	      	lw   	r3,-16[bp]
	      	cmp  	r4,r3,#4
	      	bge  	r4,FMTKc_83
	      	lw   	r4,-16[bp]
	      	asli 	r3,r4,#1
	      	lc   	r7,-2[bp]
	      	asli 	r6,r7,#10
	      	addu 	r5,r6,r12
	      	addu 	r4,r5,#704
	      	lc   	r3,0[r4+r3]
	      	blt  	r3,FMTKc_85
	      	lw   	r4,-16[bp]
	      	asli 	r3,r4,#1
	      	lc   	r7,-2[bp]
	      	asli 	r6,r7,#10
	      	addu 	r5,r6,r12
	      	addu 	r4,r5,#704
	      	lc   	r3,0[r4+r3]
	      	cmp  	r4,r3,#1024
	      	bge  	r4,FMTKc_85
	      	lw   	r5,-16[bp]
	      	asli 	r4,r5,#1
	      	lc   	r7,-2[bp]
	      	asli 	r6,r7,#10
	      	addu 	r5,r6,r12
	      	addu 	r3,r4,r5
	      	lc   	r3,704[r3]
	      	push 	r3
	      	bsr  	FMTK_FreeMbx_
	      	addui	sp,sp,#8
	      	lw   	r5,-16[bp]
	      	asli 	r4,r5,#1
	      	lc   	r7,-2[bp]
	      	asli 	r6,r7,#10
	      	addu 	r5,r6,r12
	      	addu 	r3,r4,r5
	      	ldi  	r4,#-1
	      	sc   	r4,704[r3]
FMTKc_85:
FMTKc_84:
	      	inc  	-16[bp],#1
	      	bra  	FMTKc_82
FMTKc_83:
	      	lc   	r7,-2[bp]
	      	asli 	r6,r7,#10
	      	addu 	r5,r6,r12
	      	lb   	r5,719[r5]
	      	sxb  	r5,r5
	      	asli 	r4,r5,#11
	      	lea  	r5,jcbs_[gp]
	      	addu 	r3,r4,r5
	      	mov  	r11,r3
	      	sw   	r0,-16[bp]
FMTKc_87:
	      	lw   	r3,-16[bp]
	      	cmp  	r4,r3,#8
	      	bge  	r4,FMTKc_88
	      	lw   	r4,-16[bp]
	      	asli 	r3,r4,#1
	      	addu 	r4,r11,#1682
	      	lc   	r3,0[r4+r3]
	      	lc   	r4,-2[bp]
	      	cmp  	r5,r3,r4
	      	bne  	r5,FMTKc_90
	      	lw   	r5,-16[bp]
	      	asli 	r4,r5,#1
	      	addu 	r3,r4,r11
	      	ldi  	r4,#-1
	      	sc   	r4,1682[r3]
FMTKc_90:
FMTKc_89:
	      	inc  	-16[bp],#1
	      	bra  	FMTKc_87
FMTKc_88:
	      	sw   	r0,-16[bp]
FMTKc_92:
	      	lw   	r3,-16[bp]
	      	cmp  	r4,r3,#8
	      	bge  	r4,FMTKc_93
	      	lw   	r4,-16[bp]
	      	asli 	r3,r4,#1
	      	addu 	r4,r11,#1682
	      	lc   	r3,0[r4+r3]
	      	cmp  	r4,r3,#-1
	      	beq  	r4,FMTKc_95
	      	bra  	FMTKc_93
FMTKc_95:
FMTKc_94:
	      	inc  	-16[bp],#1
	      	bra  	FMTKc_92
FMTKc_93:
	      	lw   	r3,-16[bp]
	      	cmp  	r4,r3,#8
	      	bne  	r4,FMTKc_97
	      	lb   	r3,freeJCB_[gp]
	      	sb   	r3,1698[r11]
	      	lea  	r5,jcbs_[gp]
	      	subu 	r4,r11,r5
	      	lsri 	r3,r4,#11
	      	sb   	r3,freeJCB_[gp]
FMTKc_97:
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
FMTKc_80:
FMTKc_99:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_78:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_99
endpublic

public code FMTK_ExitTask_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_101
	      	mov  	bp,sp
	      	     	mfspr r1,ivno 
	      	bsr  	GetRunningTCB_
	      	mov  	r3,r1
	      	push 	r3
	      	bsr  	KillTask_
	      	addui	sp,sp,#8
	      	     	int #2 
FMTKc_100:
	      	bra  	FMTKc_100
FMTKc_103:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_101:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_103
endpublic

	data
	align	8
	code
	align	16
public code FMTK_StartTask_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_104
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	lea  	r3,tcbs_[gp]
	      	mov  	r12,r3
	      	lea  	r3,freeTCB_[gp]
	      	mov  	r13,r3
	      	     	mfspr r1,ivno 
	      	push 	#-1
	      	pea  	sys_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKc_106
	      	lc   	r3,[r13]
	      	sc   	r3,-2[bp]
	      	lc   	r5,-2[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r12
	      	lc   	r4,624[r3]
	      	sc   	r4,[r13]
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
FMTKc_106:
	      	lc   	r5,-2[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r12
	      	mov  	r11,r3
	      	lw   	r3,32[bp]
	      	sb   	r3,718[r11]
	      	lw   	r3,24[bp]
	      	sb   	r3,716[r11]
	      	lb   	r3,56[bp]
	      	sb   	r3,719[r11]
	      	sw   	r0,-24[bp]
FMTKc_108:
	      	lw   	r3,-24[bp]
	      	cmp  	r4,r3,#8
	      	bge  	r4,FMTKc_109
	      	lw   	r4,-24[bp]
	      	asli 	r3,r4,#1
	      	lb   	r7,56[bp]
	      	sxb  	r7,r7
	      	asli 	r6,r7,#11
	      	lea  	r7,jcbs_[gp]
	      	addu 	r5,r6,r7
	      	addu 	r4,r5,#1682
	      	lc   	r3,0[r4+r3]
	      	bge  	r3,FMTKc_111
	      	lw   	r5,-24[bp]
	      	asli 	r4,r5,#1
	      	lb   	r7,56[bp]
	      	sxb  	r7,r7
	      	asli 	r6,r7,#11
	      	lea  	r7,jcbs_[gp]
	      	addu 	r5,r6,r7
	      	addu 	r3,r4,r5
	      	lc   	r4,-2[bp]
	      	sc   	r4,1682[r3]
	      	bra  	FMTKc_109
FMTKc_111:
FMTKc_110:
	      	inc  	-24[bp],#1
	      	bra  	FMTKc_108
FMTKc_109:
	      	lw   	r3,-24[bp]
	      	cmp  	r4,r3,#8
	      	bne  	r4,FMTKc_113
	      	push 	#-1
	      	pea  	sys_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKc_115
	      	lc   	r5,-2[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r12
	      	lc   	r4,[r13]
	      	sc   	r4,624[r3]
	      	lc   	r3,-2[bp]
	      	sc   	r3,[r13]
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
FMTKc_115:
	      	ldi  	r1,#69
FMTKc_117:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_113:
	      	lw   	r3,48[bp]
	      	sw   	r3,320[r11]
	      	ldi  	r3,#FMTK_ExitTask_
	      	sw   	r3,536[r11]
	      	ldi  	r3,#FMTK_ExitTask_
	      	sw   	r3,560[r11]
	      	lw   	r4,648[r11]
	      	addu 	r3,r4,#8184
	      	sw   	r3,568[r11]
	      	lw   	r4,40[bp]
	      	or   	r3,r4,#1
	      	sw   	r3,592[r11]
	      	ldi  	r3,#5368709120
	      	sw   	r3,616[r11]
	      	sw   	r0,720[r11]
	      	sw   	r0,728[r11]
	      	sw   	r0,736[r11]
	      	sw   	r0,744[r11]
	      	push 	#-1
	      	pea  	sys_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKc_118
	      	lc   	r3,-2[bp]
	      	push 	r3
	      	bsr  	InsertIntoReadyList_
FMTKc_118:
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
	      	bra  	FMTKc_117
FMTKc_104:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_117
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
	      	ldi  	xlr,#FMTKc_120
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	     	mfspr r1,ivno 
	      	push 	#-1
	      	pea  	sys_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKc_122
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
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
FMTKc_122:
	      	     	int #2 
	      	ldi  	r1,#0
FMTKc_124:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_120:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_124
endpublic

public code FMTK_SetTaskPriority_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_125
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	     	mfspr r1,ivno 
	      	lw   	r3,32[bp]
	      	cmp  	r4,r3,#63
	      	bgt  	r4,FMTKc_129
	      	lw   	r3,32[bp]
	      	bge  	r3,FMTKc_127
FMTKc_129:
	      	ldi  	r1,#4
FMTKc_130:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_127:
	      	push 	#-1
	      	pea  	sys_sema_[gp]
	      	bsr  	LockSemaphore_
	      	mov  	r3,r1
	      	beq  	r3,FMTKc_131
	      	lc   	r5,24[bp]
	      	asli 	r4,r5,#10
	      	lea  	r5,tcbs_[gp]
	      	addu 	r3,r4,r5
	      	mov  	r11,r3
	      	lb   	r4,717[r11]
	      	and  	r3,r4,#24
	      	beq  	r3,FMTKc_133
	      	lc   	r3,24[bp]
	      	push 	r3
	      	bsr  	RemoveFromReadyList_
	      	lw   	r3,32[bp]
	      	sb   	r3,716[r11]
	      	lc   	r3,24[bp]
	      	push 	r3
	      	bsr  	InsertIntoReadyList_
	      	bra  	FMTKc_134
FMTKc_133:
	      	lw   	r3,32[bp]
	      	sb   	r3,716[r11]
FMTKc_134:
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
FMTKc_131:
	      	ldi  	r1,#0
	      	bra  	FMTKc_130
FMTKc_125:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_130
endpublic

public code FMTKInitialize_:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#FMTKc_135
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	push 	r12
	      	lea  	r3,tcbs_[gp]
	      	mov  	r11,r3
	      	lea  	r3,jcbs_[gp]
	      	mov  	r12,r3
	      	     	mfspr r1,ivno 
	      	     	            ldi   r1,#20
            sc    r1,LEDS
        
	      	ldi  	r3,#0
	      	andi 	r3,r3,#65535
	      	sc   	r3,hasUltraHighPriorityTasks_[gp]
	      	sw   	r0,missed_ticks_[gp]
	      	sw   	r0,IOFocusTbl_[gp]
	      	ldi  	r3,#0
	      	sw   	r3,IOFocusNdx_[gp]
	      	sw   	r0,iof_switch_[gp]
	      	pea  	sys_sema_[gp]
	      	bsr  	UnlockSemaphore_
	      	pea  	iof_sema_[gp]
	      	bsr  	UnlockSemaphore_
	      	pea  	kbd_sema_[gp]
	      	bsr  	UnlockSemaphore_
	      	sw   	r0,-8[bp]
FMTKc_137:
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#16384
	      	bge  	r4,FMTKc_138
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#5
	      	lea  	r4,message_[gp]
	      	lw   	r6,-8[bp]
	      	addu 	r5,r6,#1
	      	andi 	r5,r5,#65535
	      	sc   	r5,0[r4+r3]
FMTKc_139:
	      	inc  	-8[bp],#1
	      	bra  	FMTKc_137
FMTKc_138:
	      	lea  	r3,message_[gp]
	      	ldi  	r4,#-1
	      	andi 	r4,r4,#65535
	      	sc   	r4,524256[r3]
	      	sc   	r0,freeMSG_[gp]
	      	     	            ldi   r1,#30
            sc    r1,LEDS
        
	      	sw   	r0,-8[bp]
FMTKc_140:
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#51
	      	bge  	r4,FMTKc_141
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,r12
	      	lw   	r4,-8[bp]
	      	sb   	r4,1681[r3]
	      	sw   	r0,-16[bp]
FMTKc_143:
	      	lw   	r3,-16[bp]
	      	cmp  	r4,r3,#8
	      	bge  	r4,FMTKc_144
	      	lw   	r5,-16[bp]
	      	asli 	r4,r5,#1
	      	lw   	r7,-8[bp]
	      	asli 	r6,r7,#11
	      	addu 	r5,r6,r12
	      	addu 	r3,r4,r5
	      	ldi  	r4,#-1
	      	sc   	r4,1682[r3]
FMTKc_145:
	      	inc  	-16[bp],#1
	      	bra  	FMTKc_143
FMTKc_144:
	      	lw   	r3,-8[bp]
	      	bne  	r3,FMTKc_146
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,r12
	      	ldi  	r4,#4291821568
	      	sw   	r4,1616[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,r12
	      	lea  	r4,video_bufs_[gp]
	      	sw   	r4,1624[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,r12
	      	ldi  	r4,#2537472
	      	andi 	r4,r4,#4294967295
	      	sh   	r4,1640[r3]
	      	push 	r12
	      	bsr  	RequestIOFocus_
	      	addui	sp,sp,#8
	      	bra  	FMTKc_147
FMTKc_146:
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,r12
	      	lea  	r4,video_bufs_[gp]
	      	sw   	r4,1616[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,r12
	      	lea  	r4,video_bufs_[gp]
	      	sw   	r4,1624[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,r12
	      	ldi  	r4,#2537472
	      	andi 	r4,r4,#4294967295
	      	sh   	r4,1640[r3]
FMTKc_147:
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,r12
	      	ldi  	r4,#31
	      	andi 	r4,r4,#65535
	      	sc   	r4,1632[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,r12
	      	ldi  	r4,#84
	      	andi 	r4,r4,#65535
	      	sc   	r4,1634[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,r12
	      	ldi  	r4,#0
	      	andi 	r4,r4,#65535
	      	sc   	r4,1636[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,r12
	      	ldi  	r4,#0
	      	andi 	r4,r4,#65535
	      	sc   	r4,1638[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,r12
	      	sb   	r0,1647[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,r12
	      	sb   	r0,1648[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,r12
	      	sb   	r0,1644[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#11
	      	addu 	r3,r4,r12
	      	sb   	r0,1645[r3]
FMTKc_142:
	      	inc  	-8[bp],#1
	      	bra  	FMTKc_140
FMTKc_141:
	      	     	            ldi   r1,#40
            sc    r1,LEDS
        
	      	sw   	r0,-8[bp]
FMTKc_148:
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#8
	      	bge  	r4,FMTKc_149
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lea  	r4,readyQ_[gp]
	      	ldi  	r5,#-1
	      	sc   	r5,0[r4+r3]
FMTKc_150:
	      	inc  	-8[bp],#1
	      	bra  	FMTKc_148
FMTKc_149:
	      	sw   	r0,-8[bp]
FMTKc_151:
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#256
	      	bge  	r4,FMTKc_152
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r11
	      	lw   	r4,-8[bp]
	      	sc   	r4,714[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r11
	      	lw   	r5,-8[bp]
	      	addu 	r4,r5,#1
	      	sc   	r4,624[r3]
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
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r11
	      	lea  	r5,sys_stacks_[gp]
	      	addu 	r4,r5,#4088
	      	sw   	r4,632[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r11
	      	lea  	r5,bios_stacks_[gp]
	      	addu 	r4,r5,#4088
	      	sw   	r4,640[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r11
	      	lea  	r5,stacks_[gp]
	      	addu 	r4,r5,#8184
	      	sw   	r4,648[r3]
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
	      	bge  	r4,FMTKc_154
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r11
	      	lw   	r4,-8[bp]
	      	sb   	r4,718[r3]
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r11
	      	ldi  	r4,#24
	      	sb   	r4,716[r3]
FMTKc_154:
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#10
	      	addu 	r3,r4,r11
	      	sw   	r0,744[r3]
FMTKc_153:
	      	inc  	-8[bp],#1
	      	bra  	FMTKc_151
FMTKc_152:
	      	ldi  	r3,#-1
	      	sc   	r3,261744[r11]
	      	ldi  	r3,#2
	      	sc   	r3,freeTCB_[gp]
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
	      	sc   	r3,TimeoutList_[gp]
	      	push 	#FMTK_SystemCall_
	      	push 	#4
	      	bsr  	set_vector_
	      	push 	#FMTK_SchedulerIRQ_
	      	push 	#2
	      	bsr  	set_vector_
	      	push 	#FMTK_SchedulerIRQ_
	      	push 	#451
	      	bsr  	set_vector_
	      	push 	#0
	      	push 	#0
	      	push 	#shell_
	      	push 	#0
	      	push 	#24
	      	bsr  	FMTK_StartTask_
	      	addui	sp,sp,#40
	      	push 	#0
	      	push 	#0
	      	push 	#IdleTask_
	      	push 	#0
	      	push 	#63
	      	bsr  	FMTK_StartTask_
	      	addui	sp,sp,#40
	      	push 	#0
	      	push 	#0
	      	push 	#IdleTask_
	      	push 	#1
	      	push 	#63
	      	bsr  	FMTK_StartTask_
	      	addui	sp,sp,#40
	      	ldi  	r3,#305419896
	      	sw   	r3,FMTK_Inited_[gp]
	      	     	            ldi   r1,#50
            sc    r1,LEDS
        
FMTKc_156:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
FMTKc_135:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	FMTKc_156
endpublic

	rodata
	align	16
	align	8
FMTKc_63:
	dc	73,100,108,101,84,97,115,107
	dc	58,32,67,84,82,76,45,67
	dc	32,112,114,101,115,115,101,100
	dc	46,13,10,0
FMTKc_15:
	dc	78,111,32,101,110,116,114,105
	dc	101,115,32,105,110,32,114,101
	dc	97,100,121,32,113,117,101,117
	dc	101,46,0
	extern	jcbs_
	extern	tcbs_
	extern	nMsgBlk_
;	global	FMTK_KillTask_
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
	extern	shell_
;	global	GetVecno_
;	global	FMTK_SchedulerIRQ_
	extern	KillTask_
;	global	GetJCBPtr_
	extern	video_bufs_
	extern	getCPU_
	extern	hasUltraHighPriorityTasks_
;	global	LockSemaphore_
	extern	iof_switch_
;	global	FMTK_StartTask_
	extern	kbd_sema_
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
;	global	freeJCB_
	extern	sysstack_
	extern	ILockSemaphore_
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
	extern	printf_
	extern	bios_stacks_
;	global	InsertIntoReadyList_
