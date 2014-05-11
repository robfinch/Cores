	bss
	align	8
public prevMoveDir:
	fill.w	1,0xffffffff
public moveDir:
	fill.w	1,0xffffffff
public score:
	fill.w	1,0xffffffff
public LeftColInv:
	fill.w	1,0xffffffff
public RightColInv:
	fill.w	1,0xffffffff
public TopRowInv:
	fill.w	1,0xffffffff
public BotRowInv:
	fill.w	1,0xffffffff
public tanksLeft:
	fill.w	1,0xffffffff
public Invaders:
	fill.w	320,0xffffffff
	code
	align	16
public DrawInvader:
	sub  	sp,#2
	st   	r14,0,sp
	st   	r12,1,sp
	lea  	r12,L_2
	tsr  	sp,r14
	sub  	sp,#2
	sub  	sp,#2
	st   	r3,0,sp
	st   	r4,1,sp
	ld   	r3,#CharPlot
	ld   	r4,3,r14
	ld   	r5,(r4)
	cmp  	r5,#0
	bne  	L_3
L_5:
	ld   	r4,1,sp
	ld   	r3,0,sp
	sub  	sp,#-2
	trs  	r14,sp
	ld   	r14,0,sp
	ld   	r12,1,sp
	sub  	sp,#-2
	rts  
L_3:
	ld   	r5,2,r4
	st   	r5,-1,r14
	ld   	r5,3,r4
	st   	r5,-2,r14
	ld   	r5,#32
	push 	r5
	ld   	r5,-2,r14
	push 	r5
	ld   	r5,-1,r14
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#32
	push 	r5
	ld   	r5,-2,r14
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#1
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#32
	push 	r5
	ld   	r5,-2,r14
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#2
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#32
	push 	r5
	ld   	r5,-2,r14
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#3
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#32
	push 	r5
	ld   	r5,-2,r14
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#4
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	lda  	1,r4
	cmp  	#1
	beq  	L_7
	cmp  	#2
	beq  	L_8
	bra  	L_6
L_7:
	ld   	r5,#32
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#1
	push 	r5
	ld   	r5,-1,r14
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#233
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#1
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#1
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#242
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#1
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#2
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#223
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#1
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#3
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#32
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#1
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#4
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#32
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#2
	push 	r5
	ld   	r5,-1,r14
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r6,2,r4
	and  	r5,r6,#1
	cmp  	r0,r5
	beq  	L_9
	ld   	r5,#24
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#2
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#1
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#24
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#2
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#3
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	bra  	L_10
L_9:
	ld   	r5,#22
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#2
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#1
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#22
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#2
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#3
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
L_10:
	ld   	r5,#32
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#2
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#2
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#32
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#2
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#4
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	bra  	L_6
L_8:
	ld   	r6,2,r4
	and  	r5,r6,#1
	cmp  	r0,r5
	beq  	L_11
	ld   	r5,#32
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#1
	push 	r5
	ld   	r5,-1,r14
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#98
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#1
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#1
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#153
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#1
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#2
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#98
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#1
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#3
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#32
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#1
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#4
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#32
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#2
	push 	r5
	ld   	r5,-1,r14
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#236
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#2
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#1
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#98
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#2
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#2
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#251
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#2
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#3
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#32
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#2
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#4
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	bra  	L_12
L_11:
	ld   	r5,#32
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#1
	push 	r5
	ld   	r5,-1,r14
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#252
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#1
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#1
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#153
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#1
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#2
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#254
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#1
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#3
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#32
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#1
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#4
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#32
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#2
	push 	r5
	ld   	r5,-1,r14
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#251
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#2
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#1
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#98
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#2
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#2
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#236
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#2
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#3
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
	ld   	r5,#32
	push 	r5
	ld   	r6,-2,r14
	add  	r5,r6,#2
	push 	r5
	ld   	r6,-1,r14
	add  	r5,r6,#4
	push 	r5
	jsr  	(r3)
	sub  	sp,#-3
	ld   	r5,r1
L_12:
L_6:
	bra  	L_5
L_2:
	pop  	r0
	ld   	r12,1,r14
	push 	r12
	bra  	L_5
public main:
	sub  	sp,#2
	st   	r14,0,sp
	st   	r12,1,sp
	lea  	r12,L_15
	tsr  	sp,r14
	sub  	sp,#3
	sub  	sp,#2
	st   	r3,0,sp
	st   	r4,1,sp
	ld   	r3,#prevMoveDir
	ld   	r4,#moveDir
	     			jsr	(0xFFFF8014>>2)
	
L_13:
	jsr  	InitializeForGame
	ld   	r5,r1
L_16:
L_14:
	jsr  	InitializeForScreen
	ld   	r5,r1
L_18:
L_20:
	ld   	r5,LeftColInv
	push 	r5
	jsr  	IsColumnDestroyed
	sub  	sp,#-1
	ld   	r5,r1
	beq  	L_21
	ld   	r5,LeftColInv
	add  	r5,r5,#1
	st   	r5,LeftColInv
	ld   	r5,LeftColInv
	ld   	r6,RightColInv
	cmp  	r5,r6
	ble  	L_22
	ld   	r5,score
	add  	r5,r5,#1000
	st   	r5,score
	bra  	L_14
L_22:
	ld   	r5,#0
	st   	r5,-1,r14
L_24:
	ld   	r5,-1,r14
	cmp  	r5,#5
	bge  	L_25
	ld   	r5,#0
	st   	r5,-2,r14
L_26:
	ld   	r5,-2,r14
	cmp  	r5,#8
	bge  	L_27
	ld   	r7,-2,r14
	mul  	r6,r7,#40
	push 	r5
	ld   	r5,-1,r14
	asl  	r8,r5,#3
	add  	r7,r8,#Invaders
	add  	r5,r6,r7
	ld   	r6,5,r5
	sub  	r6,r6,#4
	st   	r6,5,r5
	pop  	r5
	ld   	r5,-2,r14
	add  	r5,r5,#1
	st   	r5,-2,r14
	bra  	L_26
L_27:
	ld   	r5,-1,r14
	add  	r5,r5,#1
	st   	r5,-1,r14
	bra  	L_24
L_25:
	bra  	L_20
L_21:
L_28:
	ld   	r5,RightColInv
	push 	r5
	jsr  	IsColumnDestroyed
	sub  	sp,#-1
	ld   	r5,r1
	beq  	L_29
	ld   	r5,RightColInv
	sub  	r5,r5,#1
	st   	r5,RightColInv
	ld   	r5,LeftColInv
	ld   	r6,RightColInv
	cmp  	r5,r6
	ble  	L_30
	ld   	r5,score
	add  	r5,r5,#1000
	st   	r5,score
	bra  	L_14
L_30:
	ld   	r5,#0
	st   	r5,-1,r14
L_32:
	ld   	r5,-1,r14
	cmp  	r5,#5
	bge  	L_33
	ld   	r5,#0
	st   	r5,-2,r14
L_34:
	ld   	r5,-2,r14
	cmp  	r5,#8
	bge  	L_35
	ld   	r7,-2,r14
	mul  	r6,r7,#40
	push 	r5
	ld   	r5,-1,r14
	asl  	r8,r5,#3
	add  	r7,r8,#Invaders
	add  	r5,r6,r7
	ld   	r6,4,r5
	add  	r6,r6,#4
	st   	r6,4,r5
	pop  	r5
	ld   	r5,-2,r14
	add  	r5,r5,#1
	st   	r5,-2,r14
	bra  	L_34
L_35:
	ld   	r5,-1,r14
	add  	r5,r5,#1
	st   	r5,-1,r14
	bra  	L_32
L_33:
	bra  	L_28
L_29:
L_36:
	ld   	r5,TopRowInv
	push 	r5
	jsr  	IsRowDestroyed
	sub  	sp,#-1
	ld   	r5,r1
	beq  	L_37
	ld   	r5,TopRowInv
	add  	r5,r5,#1
	st   	r5,TopRowInv
	ld   	r5,TopRowInv
	ld   	r6,BotRowInv
	cmp  	r5,r6
	ble  	L_38
	ld   	r5,score
	add  	r5,r5,#1000
	st   	r5,score
	bra  	L_14
L_38:
	ld   	r5,#0
	st   	r5,-1,r14
L_40:
	ld   	r5,-1,r14
	cmp  	r5,#5
	bge  	L_41
	ld   	r5,#0
	st   	r5,-2,r14
L_42:
	ld   	r5,-2,r14
	cmp  	r5,#8
	bge  	L_43
	ld   	r7,-2,r14
	mul  	r6,r7,#40
	push 	r5
	ld   	r5,-1,r14
	asl  	r8,r5,#3
	add  	r7,r8,#Invaders
	add  	r5,r6,r7
	ld   	r6,7,r5
	sub  	r6,r6,#3
	st   	r6,7,r5
	pop  	r5
	ld   	r5,-2,r14
	add  	r5,r5,#1
	st   	r5,-2,r14
	bra  	L_42
L_43:
	ld   	r5,-1,r14
	add  	r5,r5,#1
	st   	r5,-1,r14
	bra  	L_40
L_41:
	bra  	L_36
L_37:
L_44:
	ld   	r5,BotRowInv
	push 	r5
	jsr  	IsRowDestroyed
	sub  	sp,#-1
	ld   	r5,r1
	beq  	L_45
	ld   	r5,BotRowInv
	sub  	r5,r5,#1
	st   	r5,BotRowInv
	ld   	r5,TopRowInv
	ld   	r6,BotRowInv
	cmp  	r5,r6
	ble  	L_46
	ld   	r5,score
	add  	r5,r5,#1000
	st   	r5,score
	bra  	L_14
L_46:
	ld   	r5,#0
	st   	r5,-1,r14
L_48:
	ld   	r5,-1,r14
	cmp  	r5,#5
	bge  	L_49
	ld   	r5,#0
	st   	r5,-2,r14
L_50:
	ld   	r5,-2,r14
	cmp  	r5,#8
	bge  	L_51
	ld   	r7,-2,r14
	mul  	r6,r7,#40
	push 	r5
	ld   	r5,-1,r14
	asl  	r8,r5,#3
	add  	r7,r8,#Invaders
	add  	r5,r6,r7
	ld   	r6,6,r5
	add  	r6,r6,#3
	st   	r6,6,r5
	pop  	r5
	ld   	r5,-2,r14
	add  	r5,r5,#1
	st   	r5,-2,r14
	bra  	L_50
L_51:
	ld   	r5,-1,r14
	add  	r5,r5,#1
	st   	r5,-1,r14
	bra  	L_48
L_49:
	bra  	L_44
L_45:
	ld   	r5,#0
	st   	r5,-1,r14
L_52:
	ld   	r5,-1,r14
	cmp  	r5,#5
	bge  	L_53
	ld   	r5,#0
	st   	r5,-2,r14
L_54:
	ld   	r5,-2,r14
	cmp  	r5,#8
	bge  	L_55
	ld   	r7,-2,r14
	mul  	r6,r7,#40
	push 	r5
	ld   	r5,-1,r14
	asl  	r8,r5,#3
	add  	r7,r8,#Invaders
	add  	r5,r6,r7
	st   	r5,-3,r14
	pop  	r5
	ld   	r5,-3,r14
	push 	r5
	jsr  	DrawInvader
	sub  	sp,#-1
	ld   	r5,-2,r14
	add  	r5,r5,#1
	st   	r5,-2,r14
	bra  	L_54
L_55:
	ld   	r5,-1,r14
	add  	r5,r5,#1
	st   	r5,-1,r14
	bra  	L_52
L_53:
	ld   	r5,#Invaders
	st   	r5,-3,r14
	ld   	r5,(r4)
	cmp  	r5,#1
	bne  	L_56
	ld   	r5,-3,r14
	push 	r5
	jsr  	MoveLeft
	sub  	sp,#-1
	ld   	r5,r1
	bne  	L_58
	ld   	r5,#1
	st   	r5,(r3)
	ld   	r5,#0
	st   	r5,(r4)
L_58:
	bra  	L_57
L_56:
	ld   	r5,(r4)
	cmp  	r5,#2
	bne  	L_60
	ld   	r5,-3,r14
	push 	r5
	jsr  	MoveRight
	sub  	sp,#-1
	ld   	r5,r1
	bne  	L_62
	ld   	r5,#2
	st   	r5,(r3)
	ld   	r5,#0
	st   	r5,(r4)
L_62:
	bra  	L_61
L_60:
	ld   	r5,(r4)
	cmp  	r5,#0
	bne  	L_64
	ld   	r5,-3,r14
	push 	r5
	jsr  	MoveDown
	sub  	sp,#-1
	ld   	r5,r1
	bne  	L_66
	ld   	r5,tanksLeft
	sub  	r5,r5,#1
	st   	r5,tanksLeft
	ld   	r5,tanksLeft
	cmp  	r5,#0
	bgt  	L_68
	jsr  	GameOver
	ld   	r5,r1
	bra  	L_13
L_68:
	bra  	L_14
L_66:
L_64:
L_61:
L_57:
	ld   	r5,#0
	st   	r5,-1,r14
L_70:
	ld   	r5,-1,r14
	cmp  	r5,#5
	bge  	L_71
	ld   	r5,#0
	st   	r5,-2,r14
L_72:
	ld   	r5,-2,r14
	cmp  	r5,#8
	bge  	L_73
	ld   	r7,-2,r14
	mul  	r6,r7,#40
	push 	r5
	ld   	r5,-1,r14
	asl  	r8,r5,#3
	add  	r7,r8,#Invaders
	add  	r5,r6,r7
	st   	r5,-3,r14
	pop  	r5
	lda  	(r4)
	cmp  	#1
	beq  	L_75
	cmp  	#2
	beq  	L_76
	cmp  	#0
	beq  	L_77
	bra  	L_74
L_75:
	ld   	r5,-3,r14
	push 	r5
	jsr  	MoveLeft
	sub  	sp,#-1
	ld   	r5,r1
	bra  	L_74
L_76:
	ld   	r5,-3,r14
	push 	r5
	jsr  	MoveRight
	sub  	sp,#-1
	ld   	r5,r1
	bra  	L_74
L_77:
	ld   	r5,-3,r14
	push 	r5
	jsr  	MoveDown
	sub  	sp,#-1
	ld   	r5,r1
L_74:
	ld   	r5,-2,r14
	add  	r5,r5,#1
	st   	r5,-2,r14
	bra  	L_72
L_73:
	ld   	r5,-1,r14
	add  	r5,r5,#1
	st   	r5,-1,r14
	bra  	L_70
L_71:
	ld   	r5,(r4)
	cmp  	r5,#0
	bne  	L_78
	ld   	r5,(r3)
	cmp  	r5,#1
	bne  	L_80
	ld   	r5,#0
	st   	r5,(r3)
	ld   	r5,#2
	st   	r5,(r4)
	bra  	L_81
L_80:
	ld   	r5,(r3)
	cmp  	r5,#2
	bne  	L_82
	ld   	r5,#0
	st   	r5,(r3)
	ld   	r5,#1
	st   	r5,(r4)
L_82:
L_81:
L_78:
	bra  	L_18
L_19:
	bra  	L_16
L_17:
L_84:
	ld   	r4,1,sp
	ld   	r3,0,sp
	sub  	sp,#-2
	trs  	r14,sp
	ld   	r14,0,sp
	ld   	r12,1,sp
	sub  	sp,#-2
	rts  
L_15:
	pop  	r0
	ld   	r12,1,r14
	push 	r12
	bra  	L_84
public ClearScreen:
	sub  	sp,#2
	st   	r14,0,sp
	tsr  	sp,r14
	     			jsr ($FFFF801C>>2)
	
L_86:
	trs  	r14,sp
	ld   	r14,0,sp
	sub  	sp,#-2
	rts  
L_85:
public CharPlot:
	sub  	sp,#2
	st   	r14,0,sp
	tsr  	sp,r14
	     			ld	r1,5,sp
		ld	r2,4,sp
		ld	r3,3,sp
		jsr	($FFFF8044>>2)
	
L_88:
	trs  	r14,sp
	ld   	r14,0,sp
	sub  	sp,#-2
	rts  
L_87:
public InitializeForScreen:
	sub  	sp,#2
	st   	r14,0,sp
	st   	r12,1,sp
	lea  	r12,L_89
	tsr  	sp,r14
	sub  	sp,#2
	sub  	sp,#1
	st   	r3,0,sp
	ld   	r3,#Invaders
	jsr  	ClearScreen
	ld   	r5,#0
	st   	r5,-1,r14
L_90:
	ld   	r5,-1,r14
	cmp  	r5,#5
	bhs  	L_91
	ld   	r5,#0
	st   	r5,-2,r14
L_92:
	ld   	r5,-2,r14
	cmp  	r5,#8
	bhs  	L_93
	lda  	-1,r14
	cmp  	#0
	beq  	L_95
	cmp  	#2
	beq  	L_96
	cmp  	#1
	beq  	L_96
	cmp  	#4
	beq  	L_97
	cmp  	#3
	beq  	L_97
	bra  	L_94
L_95:
	ld   	r7,-2,r14
	mul  	r6,r7,#40
	push 	r5
	ld   	r5,-1,r14
	asl  	r8,r5,#3
	add  	r7,r8,r3
	add  	r5,r6,r7
	ld   	r6,#1
	st   	r6,1,r5
	pop  	r5
L_96:
	ld   	r7,-2,r14
	mul  	r6,r7,#40
	push 	r5
	ld   	r5,-1,r14
	asl  	r8,r5,#3
	add  	r7,r8,r3
	add  	r5,r6,r7
	ld   	r6,#2
	st   	r6,1,r5
	pop  	r5
L_97:
	ld   	r7,-2,r14
	mul  	r6,r7,#40
	push 	r5
	ld   	r5,-1,r14
	asl  	r8,r5,#3
	add  	r7,r8,r3
	add  	r5,r6,r7
	ld   	r6,#3
	st   	r6,1,r5
	pop  	r5
L_94:
	ld   	r6,-2,r14
	mul  	r5,r6,#40
	ld   	r8,-1,r14
	asl  	r7,r8,#3
	add  	r6,r7,r3
	add  	r7,r5,r6
	ld   	r6,#1
	st   	r6,(r7)
	ld   	r7,-2,r14
	mul  	r6,r7,#40
	push 	r5
	ld   	r5,-1,r14
	asl  	r8,r5,#3
	add  	r7,r8,r3
	add  	r5,r6,r7
	ld   	r8,-2,r14
	asl  	r7,r8,#2
	add  	r6,r7,#12
	st   	r6,2,r5
	pop  	r5
	ld   	r7,-2,r14
	mul  	r6,r7,#40
	push 	r5
	ld   	r5,-1,r14
	asl  	r8,r5,#3
	add  	r7,r8,r3
	add  	r5,r6,r7
	ld   	r8,-1,r14
	mul  	r7,r8,#3
	add  	r6,r7,#1
	st   	r6,3,r5
	pop  	r5
	ld   	r7,-2,r14
	mul  	r6,r7,#40
	push 	r5
	ld   	r5,-1,r14
	asl  	r8,r5,#3
	add  	r7,r8,r3
	add  	r5,r6,r7
	ld   	r8,-2,r14
	asl  	r7,r8,#2
	add  	r6,r7,#24
	st   	r6,4,r5
	pop  	r5
	ld   	r7,-2,r14
	mul  	r6,r7,#40
	push 	r5
	ld   	r5,-1,r14
	asl  	r8,r5,#3
	add  	r7,r8,r3
	add  	r5,r6,r7
	ld   	r7,-2,r14
	asl  	r6,r7,#2
	st   	r6,5,r5
	pop  	r5
	ld   	r7,-2,r14
	mul  	r6,r7,#40
	push 	r5
	ld   	r5,-1,r14
	asl  	r8,r5,#3
	add  	r7,r8,r3
	add  	r5,r6,r7
	ld   	r8,-1,r14
	mul  	r7,r8,#3
	add  	r6,r7,#24
	st   	r6,6,r5
	pop  	r5
	ld   	r7,-2,r14
	mul  	r6,r7,#40
	push 	r5
	ld   	r5,-1,r14
	asl  	r8,r5,#3
	add  	r7,r8,r3
	add  	r5,r6,r7
	ld   	r8,-1,r14
	mul  	r7,r8,#3
	add  	r6,r7,#1
	st   	r6,7,r5
	pop  	r5
	ld   	r5,-2,r14
	add  	r5,r5,#1
	st   	r5,-2,r14
	bra  	L_92
L_93:
	ld   	r5,-1,r14
	add  	r5,r5,#1
	st   	r5,-1,r14
	bra  	L_90
L_91:
	ld   	r5,#0
	st   	r5,LeftColInv
	ld   	r5,#4
	st   	r5,RightColInv
	ld   	r5,#0
	st   	r5,TopRowInv
	ld   	r5,#7
	st   	r5,BotRowInv
L_98:
	ld   	r3,0,sp
	sub  	sp,#-1
	trs  	r14,sp
	ld   	r14,0,sp
	ld   	r12,1,sp
	sub  	sp,#-2
	rts  
L_89:
	pop  	r0
	ld   	r12,1,r14
	push 	r12
	bra  	L_98
public InitializeForGame:
	sub  	sp,#2
	st   	r14,0,sp
	tsr  	sp,r14
	ld   	r5,#0
	st   	r5,score
	ld   	r5,#3
	st   	r5,tanksLeft
L_100:
	trs  	r14,sp
	ld   	r14,0,sp
	sub  	sp,#-2
	rts  
L_99:
public IsColumnDestroyed:
	sub  	sp,#2
	st   	r14,0,sp
	tsr  	sp,r14
	sub  	sp,#1
	st   	r3,0,sp
	ld   	r3,#Invaders
	ld   	r6,3,r14
	mul  	r5,r6,#40
	add  	r6,r5,r3
	ld   	r6,(r6)
	cmp  	r6,#0
	bne  	L_102
	ld   	r7,3,r14
	mul  	r6,r7,#40
	ld   	r8,#8
	add  	r7,r8,r3
	add  	r8,r6,r7
	ld   	r7,(r8)
	cmp  	r7,#0
	bne  	L_102
	ld   	r8,3,r14
	mul  	r7,r8,#40
	push 	r5
	ld   	r5,#16
	add  	r8,r5,r3
	add  	r5,r7,r8
	ld   	r8,(r5)
	cmp  	r8,#0
	bne  	L_102
	ld   	r5,3,r14
	mul  	r8,r5,#40
	push 	r6
	ld   	r6,#24
	add  	r5,r6,r3
	add  	r6,r8,r5
	ld   	r5,(r6)
	cmp  	r5,#0
	bne  	L_102
	ld   	r6,3,r14
	mul  	r5,r6,#40
	push 	r7
	ld   	r7,#32
	add  	r6,r7,r3
	add  	r7,r5,r6
	ld   	r6,(r7)
	cmp  	r6,#0
	bne  	L_102
	ld   	r1,#1
L_104:
	ld   	r3,0,sp
	sub  	sp,#-1
	trs  	r14,sp
	ld   	r14,0,sp
	sub  	sp,#-2
	rts  
L_102:
	ld   	r1,#0
	bra  	L_104
L_101:
public IsRowDestroyed:
	sub  	sp,#2
	st   	r14,0,sp
	tsr  	sp,r14
	sub  	sp,#1
	st   	r3,0,sp
	ld   	r3,#Invaders
	ld   	r6,3,r14
	asl  	r5,r6,#3
	add  	r6,r5,r3
	ld   	r6,(r6)
	cmp  	r6,#0
	bne  	L_106
	ld   	r8,3,r14
	asl  	r7,r8,#3
	add  	r6,r7,r3
	ld   	r6,40,r6
	cmp  	r6,#0
	bne  	L_106
	ld   	r8,3,r14
	asl  	r7,r8,#3
	add  	r6,r7,r3
	ld   	r6,80,r6
	cmp  	r6,#0
	bne  	L_106
	ld   	r8,3,r14
	asl  	r7,r8,#3
	add  	r6,r7,r3
	ld   	r6,120,r6
	cmp  	r6,#0
	bne  	L_106
	ld   	r8,3,r14
	asl  	r7,r8,#3
	add  	r6,r7,r3
	ld   	r6,160,r6
	cmp  	r6,#0
	bne  	L_106
	ld   	r8,3,r14
	asl  	r7,r8,#3
	add  	r6,r7,r3
	ld   	r6,200,r6
	cmp  	r6,#0
	bne  	L_106
	ld   	r8,3,r14
	asl  	r7,r8,#3
	add  	r6,r7,r3
	ld   	r6,240,r6
	cmp  	r6,#0
	bne  	L_106
	ld   	r8,3,r14
	asl  	r7,r8,#3
	add  	r6,r7,r3
	ld   	r6,280,r6
	cmp  	r6,#0
	bne  	L_106
	ld   	r1,#1
L_108:
	ld   	r3,0,sp
	sub  	sp,#-1
	trs  	r14,sp
	ld   	r14,0,sp
	sub  	sp,#-2
	rts  
L_106:
	ld   	r1,#0
	bra  	L_108
L_105:
public MoveLeft:
	sub  	sp,#2
	st   	r14,0,sp
	tsr  	sp,r14
	sub  	sp,#1
	st   	r3,0,sp
	ld   	r3,3,r14
	ld   	r5,2,r3
	ld   	r6,5,r3
	cmp  	r5,r6
	bls  	L_110
	ld   	r5,2,r3
	sub  	r5,r5,#1
	st   	r5,2,r3
	ld   	r1,#1
L_112:
	ld   	r3,0,sp
	sub  	sp,#-1
	trs  	r14,sp
	ld   	r14,0,sp
	sub  	sp,#-2
	rts  
L_110:
	ld   	r1,#0
	bra  	L_112
L_109:
public MoveRight:
	sub  	sp,#2
	st   	r14,0,sp
	tsr  	sp,r14
	sub  	sp,#1
	st   	r3,0,sp
	ld   	r3,3,r14
	ld   	r5,2,r3
	ld   	r6,4,r3
	cmp  	r5,r6
	bhs  	L_114
	ld   	r5,2,r3
	add  	r5,r5,#1
	st   	r5,2,r3
	ld   	r1,#1
L_116:
	ld   	r3,0,sp
	sub  	sp,#-1
	trs  	r14,sp
	ld   	r14,0,sp
	sub  	sp,#-2
	rts  
L_114:
	ld   	r1,#0
	bra  	L_116
L_113:
public MoveDown:
	sub  	sp,#2
	st   	r14,0,sp
	tsr  	sp,r14
	sub  	sp,#1
	st   	r3,0,sp
	ld   	r3,3,r14
	ld   	r5,3,r3
	cmp  	r5,#31
	bhs  	L_118
	ld   	r5,3,r3
	add  	r5,r5,#1
	st   	r5,3,r3
	ld   	r1,#1
L_120:
	ld   	r3,0,sp
	sub  	sp,#-1
	trs  	r14,sp
	ld   	r14,0,sp
	sub  	sp,#-2
	rts  
L_118:
	ld   	r1,#0
	bra  	L_120
L_117:
public GameOver:
	sub  	sp,#2
	st   	r14,0,sp
	tsr  	sp,r14
L_122:
	trs  	r14,sp
	ld   	r14,0,sp
	sub  	sp,#-2
	rts  
L_121:
	align	8
;	global	GameOver
;	global	score
;	global	CharPlot
;	global	MoveLeft
;	global	MoveDown
;	global	Invaders
;	global	ClearScreen
;	global	RightColInv
;	global	DrawInvader
;	global	prevMoveDir
;	global	BotRowInv
;	global	MoveRight
;	global	TopRowInv
;	global	InitializeForScreen
;	global	main
;	global	IsRowDestroyed
;	global	tanksLeft
;	global	InitializeForGame
;	global	moveDir
;	global	LeftColInv
;	global	IsColumnDestroyed
