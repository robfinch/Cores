	bss
	align	8
public screen:
	fill.w	1,0xffffffff
public moveDir:
	fill.w	1,0xffffffff
public LeftColInv:
	fill.w	1,0xffffffff
public RightColInv:
	fill.w	1,0xffffffff
public Invaders:
	fill.w	240,0xffffffff
	code
	align	16
public DrawInvader:
	sub  	sp,#2
	st   	r14,0,sp
	tsr  	sp,r14
	sub  	sp,#2
	sub  	sp,#2
	st   	r3,0,sp
	st   	r4,1,sp
	ld   	r7,3,r14
	mul  	r6,r7,#30
	push 	r5
	ld   	r5,2,r14
	mul  	r8,r5,#6
	add  	r7,r8,#Invaders
	add  	r5,r6,r7
	ld   	r4,r5
	pop  	r5
	ld   	r5,(r4)
	cmp  	r5,#0
	bne  	L_1
L_3:
	ld   	r4,1,sp
	ld   	r3,0,sp
	sub  	sp,#-2
	trs  	r14,sp
	ld   	r14,0,sp
	sub  	sp,#-2
	rts  
L_1:
	ld   	r8,3,r4
	muls 	r7,r8,#56
	add  	r6,r7,2,r4
	add  	r5,r6,screen
	ld   	r3,r5
	lda  	1,r4
	cmp  	#1
	beq  	L_5
	bra  	L_4
L_5:
	ld   	r5,#32
	st   	r5,(r3)
	ld   	r5,#32
	st   	r5,1,r3
	ld   	r5,#32
	st   	r5,2,r3
	ld   	r5,#32
	st   	r5,3,r3
	ld   	r5,#32
	st   	r5,4,r3
	ld   	r5,#32
	st   	r5,56,r3
	ld   	r5,#233
	st   	r5,57,r3
	ld   	r5,#242
	st   	r5,58,r3
	ld   	r5,#223
	st   	r5,59,r3
	ld   	r5,#32
	st   	r5,60,r3
	ld   	r5,#32
	st   	r5,112,r3
	ld   	r6,2,r4
	and  	r5,r6,#1
	cmp  	r0,r5
	beq  	L_6
	ld   	r5,#24
	st   	r5,113,r3
	ld   	r5,#24
	st   	r5,115,r3
	bra  	L_7
L_6:
	ld   	r5,#22
	st   	r5,113,r3
	ld   	r5,#22
	st   	r5,115,r3
L_7:
	ld   	r5,#32
	st   	r5,114,r3
L_4:
	bra  	L_3
L_0:
public main:
	sub  	sp,#2
	st   	r14,0,sp
	st   	r12,1,sp
	lea  	r12,L_8
	tsr  	sp,r14
	sub  	sp,#3
	sub  	sp,#2
	st   	r3,0,sp
	st   	r4,1,sp
	ld   	r3,#moveDir
	ld   	r4,#Invaders
	jsr  	InitializeForScreen
	ld   	r5,r1
L_9:
	ld   	r5,LeftColInv
	push 	r5
	jsr  	IsColumnDestroyed
	sub  	sp,#-1
	ld   	r5,r1
	beq  	L_10
	ld   	r5,LeftColInv
	add  	r5,r5,#1
	st   	r5,LeftColInv
	ld   	r5,LeftColInv
	ld   	r6,RightColInv
	cmp  	r5,r6
	ble  	L_11
L_13:
	ld   	r4,1,sp
	ld   	r3,0,sp
	sub  	sp,#-2
	trs  	r14,sp
	ld   	r14,0,sp
	ld   	r12,1,sp
	sub  	sp,#-2
	rts  
L_11:
	ld   	r5,#0
	st   	r5,-1,r14
L_14:
	ld   	r5,-1,r14
	cmp  	r5,#5
	bge  	L_15
	ld   	r5,#0
	st   	r5,-2,r14
L_16:
	ld   	r5,-2,r14
	cmp  	r5,#8
	bge  	L_17
	ld   	r7,-2,r14
	mul  	r6,r7,#30
	push 	r5
	ld   	r5,-1,r14
	mul  	r8,r5,#6
	add  	r7,r8,r4
	add  	r5,r6,r7
	ld   	r6,5,r5
	sub  	r6,r6,#4
	st   	r6,5,r5
	pop  	r5
	ld   	r5,-2,r14
	add  	r5,r5,#1
	st   	r5,-2,r14
	bra  	L_16
L_17:
	ld   	r5,-1,r14
	add  	r5,r5,#1
	st   	r5,-1,r14
	bra  	L_14
L_15:
	bra  	L_9
L_10:
L_18:
	ld   	r5,RightColInv
	push 	r5
	jsr  	IsColumnDestroyed
	sub  	sp,#-1
	ld   	r5,r1
	beq  	L_19
	ld   	r5,RightColInv
	sub  	r5,r5,#1
	st   	r5,RightColInv
	ld   	r5,LeftColInv
	ld   	r6,RightColInv
	cmp  	r5,r6
	ble  	L_20
	bra  	L_13
L_20:
	ld   	r5,#0
	st   	r5,-1,r14
L_22:
	ld   	r5,-1,r14
	cmp  	r5,#5
	bge  	L_23
	ld   	r5,#0
	st   	r5,-2,r14
L_24:
	ld   	r5,-2,r14
	cmp  	r5,#8
	bge  	L_25
	ld   	r7,-2,r14
	mul  	r6,r7,#30
	push 	r5
	ld   	r5,-1,r14
	mul  	r8,r5,#6
	add  	r7,r8,r4
	add  	r5,r6,r7
	ld   	r6,4,r5
	add  	r6,r6,#4
	st   	r6,4,r5
	pop  	r5
	ld   	r5,-2,r14
	add  	r5,r5,#1
	st   	r5,-2,r14
	bra  	L_24
L_25:
	ld   	r5,-1,r14
	add  	r5,r5,#1
	st   	r5,-1,r14
	bra  	L_22
L_23:
	bra  	L_18
L_19:
	ld   	r5,#0
	st   	r5,-1,r14
L_26:
	ld   	r5,-1,r14
	cmp  	r5,#5
	bge  	L_27
	ld   	r5,#0
	st   	r5,-2,r14
L_28:
	ld   	r5,-2,r14
	cmp  	r5,#8
	bge  	L_29
	ld   	r5,-2,r14
	push 	r5
	ld   	r5,-1,r14
	push 	r5
	jsr  	DrawInvader
	sub  	sp,#-2
	ld   	r5,-2,r14
	add  	r5,r5,#1
	st   	r5,-2,r14
	bra  	L_28
L_29:
	ld   	r5,-1,r14
	add  	r5,r5,#1
	st   	r5,-1,r14
	bra  	L_26
L_27:
	st   	r4,-3,r14
	ld   	r5,(r3)
	cmp  	r5,#1
	bne  	L_30
	ld   	r5,-3,r14
	push 	r5
	jsr  	MoveLeft
	sub  	sp,#-1
	ld   	r5,r1
	bne  	L_32
	ld   	r5,#0
	st   	r5,(r3)
L_32:
L_30:
	ld   	r5,(r3)
	cmp  	r5,#2
	bne  	L_34
	ld   	r5,-3,r14
	push 	r5
	jsr  	MoveRight
	sub  	sp,#-1
	ld   	r5,r1
	bne  	L_36
	ld   	r5,#0
	st   	r5,(r3)
L_36:
L_34:
	ld   	r5,#0
	st   	r5,-1,r14
L_38:
	ld   	r5,-1,r14
	cmp  	r5,#5
	bge  	L_39
	ld   	r5,#0
	st   	r5,-2,r14
L_40:
	ld   	r5,-2,r14
	cmp  	r5,#8
	bge  	L_41
	ld   	r7,-2,r14
	mul  	r6,r7,#30
	push 	r5
	ld   	r5,-1,r14
	mul  	r8,r5,#6
	add  	r7,r8,r4
	add  	r5,r6,r7
	st   	r5,-3,r14
	pop  	r5
	lda  	(r3)
	cmp  	#1
	beq  	L_43
	cmp  	#2
	beq  	L_44
	cmp  	#0
	beq  	L_45
	bra  	L_42
L_43:
	ld   	r5,-3,r14
	push 	r5
	jsr  	MoveLeft
	sub  	sp,#-1
	ld   	r5,r1
	bra  	L_42
L_44:
	ld   	r5,-3,r14
	push 	r5
	jsr  	MoveRight
	sub  	sp,#-1
	ld   	r5,r1
	bra  	L_42
L_45:
	ld   	r5,-3,r14
	push 	r5
	jsr  	MoveDown
	sub  	sp,#-1
	ld   	r5,r1
L_42:
	ld   	r5,-2,r14
	add  	r5,r5,#1
	st   	r5,-2,r14
	bra  	L_40
L_41:
	ld   	r5,-1,r14
	add  	r5,r5,#1
	st   	r5,-1,r14
	bra  	L_38
L_39:
	bra  	L_13
L_8:
	pop  	r0
	ld   	r12,1,r14
	push 	r12
	bra  	L_13
public InitializeForScreen:
	sub  	sp,#2
	st   	r14,0,sp
	tsr  	sp,r14
	sub  	sp,#2
	sub  	sp,#1
	st   	r3,0,sp
	ld   	r3,#Invaders
	ld   	r5,#-3145728
	st   	r5,screen
	ld   	r5,#0
	st   	r5,-1,r14
L_47:
	ld   	r5,-1,r14
	cmp  	r5,#5
	bhs  	L_48
	ld   	r5,#0
	st   	r5,-2,r14
L_49:
	ld   	r5,-2,r14
	cmp  	r5,#8
	bhs  	L_50
	lda  	-1,r14
	cmp  	#0
	beq  	L_52
	cmp  	#2
	beq  	L_53
	cmp  	#1
	beq  	L_53
	cmp  	#4
	beq  	L_54
	cmp  	#3
	beq  	L_54
	bra  	L_51
L_52:
	ld   	r7,-2,r14
	mul  	r6,r7,#30
	push 	r5
	ld   	r5,-1,r14
	mul  	r8,r5,#6
	add  	r7,r8,r3
	add  	r5,r6,r7
	ld   	r6,#1
	st   	r6,1,r5
	pop  	r5
L_53:
	ld   	r7,-2,r14
	mul  	r6,r7,#30
	push 	r5
	ld   	r5,-1,r14
	mul  	r8,r5,#6
	add  	r7,r8,r3
	add  	r5,r6,r7
	ld   	r6,#2
	st   	r6,1,r5
	pop  	r5
L_54:
	ld   	r7,-2,r14
	mul  	r6,r7,#30
	push 	r5
	ld   	r5,-1,r14
	mul  	r8,r5,#6
	add  	r7,r8,r3
	add  	r5,r6,r7
	ld   	r6,#3
	st   	r6,1,r5
	pop  	r5
L_51:
	ld   	r6,-2,r14
	mul  	r5,r6,#30
	ld   	r8,-1,r14
	mul  	r7,r8,#6
	add  	r6,r7,r3
	add  	r7,r5,r6
	ld   	r6,#1
	st   	r6,(r7)
	ld   	r7,-2,r14
	mul  	r6,r7,#30
	push 	r5
	ld   	r5,-1,r14
	mul  	r8,r5,#6
	add  	r7,r8,r3
	add  	r5,r6,r7
	ld   	r8,-2,r14
	asl  	r7,r8,#2
	add  	r6,r7,#12
	st   	r6,2,r5
	pop  	r5
	ld   	r7,-2,r14
	mul  	r6,r7,#30
	push 	r5
	ld   	r5,-1,r14
	mul  	r8,r5,#6
	add  	r7,r8,r3
	add  	r5,r6,r7
	ld   	r8,-1,r14
	mul  	r7,r8,#3
	add  	r6,r7,#1
	st   	r6,3,r5
	pop  	r5
	ld   	r7,-2,r14
	mul  	r6,r7,#30
	push 	r5
	ld   	r5,-1,r14
	mul  	r8,r5,#6
	add  	r7,r8,r3
	add  	r5,r6,r7
	ld   	r8,-2,r14
	asl  	r7,r8,#2
	add  	r6,r7,#24
	st   	r6,4,r5
	pop  	r5
	ld   	r7,-2,r14
	mul  	r6,r7,#30
	push 	r5
	ld   	r5,-1,r14
	mul  	r8,r5,#6
	add  	r7,r8,r3
	add  	r5,r6,r7
	ld   	r7,-2,r14
	asl  	r6,r7,#2
	st   	r6,5,r5
	pop  	r5
	ld   	r5,-2,r14
	add  	r5,r5,#1
	st   	r5,-2,r14
	bra  	L_49
L_50:
	ld   	r5,-1,r14
	add  	r5,r5,#1
	st   	r5,-1,r14
	bra  	L_47
L_48:
	ld   	r5,#0
	st   	r5,LeftColInv
	ld   	r5,#4
	st   	r5,RightColInv
L_55:
	ld   	r3,0,sp
	sub  	sp,#-1
	trs  	r14,sp
	ld   	r14,0,sp
	sub  	sp,#-2
	rts  
L_46:
public IsColumnDestroyed:
	sub  	sp,#2
	st   	r14,0,sp
	tsr  	sp,r14
	sub  	sp,#1
	st   	r3,0,sp
	ld   	r3,#Invaders
	ld   	r6,2,r14
	mul  	r5,r6,#30
	add  	r6,r5,r3
	ld   	r6,(r6)
	cmp  	r6,#0
	bne  	L_57
	ld   	r7,2,r14
	mul  	r6,r7,#30
	ld   	r8,#6
	add  	r7,r8,r3
	add  	r8,r6,r7
	ld   	r7,(r8)
	cmp  	r7,#0
	bne  	L_57
	ld   	r8,2,r14
	mul  	r7,r8,#30
	push 	r5
	ld   	r5,#12
	add  	r8,r5,r3
	add  	r5,r7,r8
	ld   	r8,(r5)
	cmp  	r8,#0
	bne  	L_57
	ld   	r5,2,r14
	mul  	r8,r5,#30
	push 	r6
	ld   	r6,#18
	add  	r5,r6,r3
	add  	r6,r8,r5
	ld   	r5,(r6)
	cmp  	r5,#0
	bne  	L_57
	ld   	r6,2,r14
	mul  	r5,r6,#30
	push 	r7
	ld   	r7,#24
	add  	r6,r7,r3
	add  	r7,r5,r6
	ld   	r6,(r7)
	cmp  	r6,#0
	bne  	L_57
	ld   	r1,#1
L_59:
	ld   	r3,0,sp
	sub  	sp,#-1
	trs  	r14,sp
	ld   	r14,0,sp
	sub  	sp,#-2
	rts  
L_57:
	ld   	r1,#0
	bra  	L_59
L_56:
public MoveLeft:
	sub  	sp,#2
	st   	r14,0,sp
	tsr  	sp,r14
	sub  	sp,#1
	st   	r3,0,sp
	ld   	r3,2,r14
	ld   	r5,2,r3
	ld   	r6,5,r3
	cmp  	r5,r6
	ble  	L_61
	ld   	r5,2,r3
	sub  	r5,r5,#1
	st   	r5,2,r3
	ld   	r1,#1
L_63:
	ld   	r3,0,sp
	sub  	sp,#-1
	trs  	r14,sp
	ld   	r14,0,sp
	sub  	sp,#-2
	rts  
L_61:
	ld   	r1,#0
	bra  	L_63
L_60:
public MoveRight:
	sub  	sp,#2
	st   	r14,0,sp
	tsr  	sp,r14
	sub  	sp,#1
	st   	r3,0,sp
	ld   	r3,2,r14
	ld   	r5,2,r3
	ld   	r6,4,r3
	cmp  	r5,r6
	bge  	L_65
	ld   	r5,2,r3
	add  	r5,r5,#1
	st   	r5,2,r3
	ld   	r1,#1
L_67:
	ld   	r3,0,sp
	sub  	sp,#-1
	trs  	r14,sp
	ld   	r14,0,sp
	sub  	sp,#-2
	rts  
L_65:
	ld   	r1,#0
	bra  	L_67
L_64:
public MoveDown:
	sub  	sp,#2
	st   	r14,0,sp
	tsr  	sp,r14
	sub  	sp,#1
	st   	r3,0,sp
	ld   	r3,2,r14
	ld   	r5,3,r3
	cmp  	r5,#31
	bge  	L_69
	ld   	r5,3,r3
	add  	r5,r5,#1
	st   	r5,3,r3
	ld   	r1,#1
L_71:
	ld   	r3,0,sp
	sub  	sp,#-1
	trs  	r14,sp
	ld   	r14,0,sp
	sub  	sp,#-2
	rts  
L_69:
	ld   	r1,#0
	bra  	L_71
L_68:
	align	8
;	global	MoveLeft
;	global	MoveDown
;	global	Invaders
;	global	RightColInv
;	global	DrawInvader
;	global	screen
;	global	MoveRight
;	global	InitializeForScreen
;	global	main
;	global	moveDir
;	global	LeftColInv
;	global	IsColumnDestroyed
