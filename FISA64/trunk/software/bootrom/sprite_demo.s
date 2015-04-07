	bss
	align	8
	align	8
public bss demo_stack:
	fill.b	4096,0x00

endpublic
	data
	align	8
	align	8
public data pSpriteController:
	dw	-2437120
endpublic

	bss
	align	8
	align	8
public bss sprites:
	fill.b	1024,0x00

endpublic
	code
	align	16
public code sprite_main:
	      	     	          push  lr
          lea   sp,demo_stack+4088
          bsr   sprite_demo
          rts
      
endpublic

sprite_demo:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#sprite_demo_3
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	ldi  	r11,#sprites
	      	ldi  	r12,#4292611072
	      	ldi  	r13,#4292345856
	      	sw   	r0,-8[bp]
sprite_demo_4:
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#32
	      	bge  	r3,sprite_demo_5
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#2
	      	asli 	r3,r3,#2
	      	lw   	r4,pSpriteController
	      	addu 	r3,r3,r4
	      	ldi  	r4,#56292
	      	sh   	r4,4[r3]
sprite_demo_6:
	      	inc  	-8[bp],#1
	      	bra  	sprite_demo_4
sprite_demo_5:
	      	sw   	r0,-8[bp]
sprite_demo_7:
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#16384
	      	bge  	r3,sprite_demo_8
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#2
	      	lhu  	r4,[r12]
	      	sh   	r4,0[r13+r3]
sprite_demo_9:
	      	inc  	-8[bp],#1
	      	bra  	sprite_demo_7
sprite_demo_8:
	      	sw   	r0,-8[bp]
sprite_demo_10:
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#32
	      	bge  	r3,sprite_demo_11
	      	lw   	r3,[r12]
	      	mod  	r3,r3,#1364
	      	addu 	r3,r3,#218
	      	lw   	r4,-8[bp]
	      	asli 	r4,r4,#5
	      	sw   	r3,0[r11+r4]
	      	lw   	r3,[r12]
	      	mod  	r3,r3,#768
	      	addu 	r3,r3,#27
	      	lw   	r4,-8[bp]
	      	asli 	r4,r4,#5
	      	addu 	r4,r4,r11
	      	sw   	r3,8[r4]
	      	lw   	r3,[r12]
	      	and  	r3,r3,#7
	      	subu 	r3,r3,#4
	      	lw   	r4,-8[bp]
	      	asli 	r4,r4,#5
	      	addu 	r4,r4,r11
	      	sw   	r3,16[r4]
	      	lw   	r3,[r12]
	      	and  	r3,r3,#7
	      	subu 	r3,r3,#4
	      	lw   	r4,-8[bp]
	      	asli 	r4,r4,#5
	      	addu 	r4,r4,r11
	      	sw   	r3,24[r4]
sprite_demo_12:
	      	inc  	-8[bp],#1
	      	bra  	sprite_demo_10
sprite_demo_11:
sprite_demo_13:
	      	ldi  	r3,#1
	      	beq  	r3,sprite_demo_14
	      	sw   	r0,-8[bp]
sprite_demo_15:
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#32
	      	bge  	r3,sprite_demo_16
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#5
	      	lw   	r3,0[r11+r3]
	      	lw   	r4,-8[bp]
	      	asli 	r4,r4,#5
	      	addu 	r4,r4,r11
	      	lw   	r4,16[r4]
	      	addu 	r3,r3,r4
	      	mod  	r3,r3,#1366
	      	addu 	r3,r3,#218
	      	lw   	r4,-8[bp]
	      	asli 	r4,r4,#5
	      	sw   	r3,0[r11+r4]
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#5
	      	addu 	r3,r3,r11
	      	lw   	r3,8[r3]
	      	lw   	r4,-8[bp]
	      	asli 	r4,r4,#5
	      	addu 	r4,r4,r11
	      	lw   	r4,24[r4]
	      	addu 	r3,r3,r4
	      	mod  	r3,r3,#768
	      	addu 	r3,r3,#27
	      	lw   	r4,-8[bp]
	      	asli 	r4,r4,#5
	      	addu 	r4,r4,r11
	      	sw   	r3,8[r4]
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#5
	      	lw   	r3,0[r11+r3]
	      	lw   	r4,-8[bp]
	      	asli 	r4,r4,#5
	      	addu 	r4,r4,r11
	      	lw   	r4,8[r4]
	      	asli 	r4,r4,#16
	      	addu 	r3,r3,r4
	      	lw   	r4,-8[bp]
	      	asli 	r4,r4,#2
	      	asli 	r4,r4,#2
	      	lw   	r5,pSpriteController
	      	sh   	r3,0[r5+r4]
sprite_demo_17:
	      	inc  	-8[bp],#1
	      	bra  	sprite_demo_15
sprite_demo_16:
	      	     	            ldi  r1,#1000000
            bsr  MicroDelay
        
	      	bsr  	getcharNoWait
	      	mov  	r3,r1
	      	cmp  	r3,r3,#3
	      	bne  	r3,sprite_demo_18
sprite_demo_20:
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
sprite_demo_18:
	      	bra  	sprite_demo_13
sprite_demo_14:
	      	bra  	sprite_demo_20
sprite_demo_3:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	sprite_demo_20
	rodata
	align	16
	align	8
;	global	sprites
;	global	pSpriteController
;	global	demo_stack
	extern	getcharNoWait
;	global	sprite_main
