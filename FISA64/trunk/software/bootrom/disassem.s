	code
	align	16
public code SetCurAttr:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	         lw    r1,24[bp]
         bsr   SetCurrAttr
     
disassem_1:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code reverse_video:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_2
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	bsr  	GetCurrAttr
	      	mov  	r3,r1
	      	sh   	r3,-4[bp]
	      	lhu  	r3,-4[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#10
	      	asli 	r3,r3,#19
	      	lhu  	r4,-4[bp]
	      	andi 	r4,r4,#-1
	      	asri 	r4,r4,#19
	      	asli 	r4,r4,#10
	      	or   	r3,r3,r4
	      	sh   	r3,-4[bp]
	      	lhu  	r3,-4[bp]
	      	push 	r3
	      	bsr  	SetCurAttr
	      	addui	sp,sp,#8
disassem_3:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_2:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_3
endpublic

public code DumpInsnBytes:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_5
	      	mov  	bp,sp
	      	lw   	r3,32[bp]
	      	asri 	r3,r3,#24
	      	and  	r3,r3,#255
	      	push 	r3
	      	lw   	r3,32[bp]
	      	asri 	r3,r3,#16
	      	and  	r3,r3,#255
	      	push 	r3
	      	lw   	r3,32[bp]
	      	asri 	r3,r3,#8
	      	and  	r3,r3,#255
	      	push 	r3
	      	lw   	r3,32[bp]
	      	and  	r3,r3,#255
	      	push 	r3
	      	push 	24[bp]
	      	push 	#disassem_4
	      	bsr  	printf
	      	addui	sp,sp,#48
disassem_6:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_5:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_6
endpublic

DispRst:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_9
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	asri 	r3,r3,#12
	      	and  	r3,r3,#31
	      	push 	r3
	      	push 	#disassem_8
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_10:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_9:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_10
DispRstc:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_13
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	asri 	r3,r3,#12
	      	and  	r3,r3,#31
	      	push 	r3
	      	push 	#disassem_12
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_14:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_13:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_14
DispRac:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_17
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	asri 	r3,r3,#7
	      	and  	r3,r3,#31
	      	push 	r3
	      	push 	#disassem_16
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_18:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_17:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_18
DispRa:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_21
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	asri 	r3,r3,#7
	      	and  	r3,r3,#31
	      	push 	r3
	      	push 	#disassem_20
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_22:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_21:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_22
DispRb:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_25
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#31
	      	push 	r3
	      	push 	#disassem_24
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_26:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_25:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_26
DispSpr:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_43
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r3,24[bp]
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#255
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_45
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_46
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_47
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_48
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_49
	      	cmp  	r4,r3,#8
	      	beq  	r4,disassem_50
	      	cmp  	r4,r3,#9
	      	beq  	r4,disassem_51
	      	cmp  	r4,r3,#10
	      	beq  	r4,disassem_52
	      	cmp  	r4,r3,#50
	      	beq  	r4,disassem_53
	      	cmp  	r4,r3,#51
	      	beq  	r4,disassem_54
	      	cmp  	r4,r3,#52
	      	beq  	r4,disassem_55
	      	cmp  	r4,r3,#53
	      	beq  	r4,disassem_56
	      	cmp  	r4,r3,#54
	      	beq  	r4,disassem_57
	      	cmp  	r4,r3,#55
	      	beq  	r4,disassem_58
	      	bra  	disassem_59
disassem_45:
	      	push 	#disassem_28
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_44
disassem_46:
	      	push 	#disassem_29
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_44
disassem_47:
	      	push 	#disassem_30
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_44
disassem_48:
	      	push 	#disassem_31
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_44
disassem_49:
	      	push 	#disassem_32
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_44
disassem_50:
	      	push 	#disassem_33
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_44
disassem_51:
	      	push 	#disassem_34
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_44
disassem_52:
	      	push 	#disassem_35
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_44
disassem_53:
	      	push 	#disassem_36
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_44
disassem_54:
	      	push 	#disassem_37
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_44
disassem_55:
	      	push 	#disassem_38
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_44
disassem_56:
	      	push 	#disassem_39
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_44
disassem_57:
	      	push 	#disassem_40
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_44
disassem_58:
	      	push 	#disassem_41
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_44
disassem_59:
	      	push 	-8[bp]
	      	push 	#disassem_42
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_44:
disassem_60:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_43:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_60
DispMemAddress:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_66
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r3,40[bp]
	      	sh   	r3,-4[bp]
	      	lw   	r3,24[bp]
	      	beq  	r3,disassem_67
	      	lw   	r3,32[bp]
	      	asli 	r3,r3,#15
	      	lw   	r4,40[bp]
	      	asri 	r4,r4,#17
	      	or   	r3,r3,r4
	      	push 	r3
	      	push 	#disassem_62
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_68
disassem_67:
	      	lh   	r3,-4[bp]
	      	sxh  	r3,r3
	      	sxh  	r3,r3
	      	asri 	r3,r3,#17
	      	push 	r3
	      	push 	#disassem_63
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_68:
	      	lw   	r3,40[bp]
	      	asri 	r3,r3,#7
	      	and  	r3,r3,#31
	      	beq  	r3,disassem_69
	      	lw   	r3,40[bp]
	      	asri 	r3,r3,#7
	      	and  	r3,r3,#31
	      	push 	r3
	      	push 	#disassem_64
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_70
disassem_69:
	      	push 	#disassem_65
	      	bsr  	printf
	      	addui	sp,sp,#8
disassem_70:
disassem_71:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_66:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_71
PrintSc:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_75
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	cmp  	r3,r3,#1
	      	ble  	r3,disassem_76
	      	push 	24[bp]
	      	push 	#disassem_73
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_77
disassem_76:
	      	push 	#disassem_74
	      	bsr  	printf
	      	addui	sp,sp,#8
disassem_77:
disassem_78:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_75:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_78
DispBrk:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_84
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	lhu  	r3,24[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#30
	      	and  	r3,r3,#3
	      	sw   	r3,-8[bp]
	      	lhu  	r3,24[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#511
	      	sw   	r3,-16[bp]
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_86
	      	cmp  	r4,r3,#1
	      	beq  	r4,disassem_87
	      	cmp  	r4,r3,#2
	      	beq  	r4,disassem_88
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_89
	      	bra  	disassem_85
disassem_86:
	      	push 	-16[bp]
	      	push 	#disassem_80
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_87:
	      	push 	-16[bp]
	      	push 	#disassem_81
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_88:
	      	push 	-16[bp]
	      	push 	#disassem_82
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_89:
	      	push 	-16[bp]
	      	push 	#disassem_83
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_85:
disassem_90:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_84:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_90
DispIndexedAddr:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_97
	      	mov  	bp,sp
	      	subui	sp,sp,#40
	      	lhu  	r3,40[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#24
	      	sw   	r3,-8[bp]
	      	lhu  	r3,40[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#7
	      	and  	r3,r3,#31
	      	sw   	r3,-16[bp]
	      	lhu  	r3,40[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#12
	      	and  	r3,r3,#31
	      	sw   	r3,-32[bp]
	      	lhu  	r3,40[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#31
	      	sw   	r3,-24[bp]
	      	lhu  	r3,40[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#22
	      	and  	r3,r3,#3
	      	sw   	r3,-40[bp]
	      	ldi  	r3,#1
	      	lw   	r4,-40[bp]
	      	asl  	r3,r3,r4
	      	sw   	r3,-40[bp]
	      	lhu  	r3,40[bp]
	      	push 	r3
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	-32[bp]
	      	push 	32[bp]
	      	push 	#disassem_92
	      	bsr  	printf
	      	addui	sp,sp,#24
	      	lw   	r3,-8[bp]
	      	beq  	r3,disassem_98
	      	push 	-8[bp]
	      	push 	#disassem_93
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_98:
	      	lw   	r3,-16[bp]
	      	beq  	r3,disassem_100
	      	lw   	r3,-24[bp]
	      	beq  	r3,disassem_100
	      	push 	#disassem_94
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	-40[bp]
	      	bsr  	PrintSc
	      	addui	sp,sp,#8
	      	bra  	disassem_101
disassem_100:
	      	lw   	r3,-16[bp]
	      	bne  	r3,disassem_102
	      	push 	-24[bp]
	      	push 	#disassem_95
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	push 	-40[bp]
	      	bsr  	PrintSc
	      	addui	sp,sp,#8
	      	bra  	disassem_103
disassem_102:
	      	lw   	r3,-24[bp]
	      	bne  	r3,disassem_104
	      	push 	#disassem_96
	      	bsr  	printf
	      	addui	sp,sp,#8
disassem_104:
disassem_103:
disassem_101:
disassem_106:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_97:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_106
DispLS:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_109
	      	mov  	bp,sp
	      	push 	56[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	push 	#disassem_108
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	push 	56[bp]
	      	bsr  	DispRstc
	      	addui	sp,sp,#8
	      	push 	56[bp]
	      	push 	48[bp]
	      	push 	40[bp]
	      	bsr  	DispMemAddress
	      	addui	sp,sp,#24
disassem_110:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_109:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_110
DispRI:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_115
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r3,56[bp]
	      	sh   	r3,-4[bp]
	      	push 	56[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	push 	#disassem_112
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	push 	56[bp]
	      	bsr  	DispRstc
	      	addui	sp,sp,#8
	      	push 	56[bp]
	      	bsr  	DispRac
	      	addui	sp,sp,#8
	      	lw   	r3,40[bp]
	      	beq  	r3,disassem_116
	      	lw   	r3,48[bp]
	      	asli 	r3,r3,#15
	      	lw   	r4,56[bp]
	      	asri 	r4,r4,#17
	      	or   	r3,r3,r4
	      	push 	r3
	      	push 	#disassem_113
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_117
disassem_116:
	      	lh   	r3,-4[bp]
	      	sxh  	r3,r3
	      	sxh  	r3,r3
	      	asri 	r3,r3,#17
	      	push 	r3
	      	push 	#disassem_114
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_117:
disassem_118:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_115:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_118
public code DispBcc:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_121
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	lw   	r3,40[bp]
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#32767
	      	asli 	r3,r3,#2
	      	sw   	r3,-16[bp]
	      	lw   	r3,40[bp]
	      	and  	r3,r3,#-2147483648
	      	beq  	r3,disassem_122
	      	lw   	r3,-16[bp]
	      	ori  	r3,r3,#-65536
	      	sw   	r3,-16[bp]
disassem_122:
	      	push 	40[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	push 	#disassem_119
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	push 	40[bp]
	      	bsr  	DispRac
	      	addui	sp,sp,#8
	      	lw   	r3,24[bp]
	      	lw   	r4,-16[bp]
	      	addu 	r3,r3,r4
	      	push 	r3
	      	push 	#disassem_120
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_124:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_121:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_124
endpublic

public code DispRR:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_129
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	lhu  	r3,40[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#25
	      	sw   	r3,-8[bp]
	      	lhu  	r3,40[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#31
	      	sw   	r3,-16[bp]
	      	lhu  	r3,40[bp]
	      	push 	r3
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#14
	      	bne  	r3,disassem_130
	      	lw   	r3,-16[bp]
	      	bne  	r3,disassem_130
	      	push 	#disassem_125
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,40[bp]
	      	push 	r3
	      	bsr  	DispRstc
	      	addui	sp,sp,#8
	      	lhu  	r3,40[bp]
	      	push 	r3
	      	bsr  	DispRa
	      	addui	sp,sp,#8
	      	push 	#disassem_126
	      	bsr  	printf
	      	addui	sp,sp,#8
disassem_132:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_130:
	      	push 	32[bp]
	      	push 	#disassem_127
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	lhu  	r3,40[bp]
	      	push 	r3
	      	bsr  	DispRstc
	      	addui	sp,sp,#8
	      	lhu  	r3,40[bp]
	      	push 	r3
	      	bsr  	DispRac
	      	addui	sp,sp,#8
	      	lhu  	r3,40[bp]
	      	push 	r3
	      	bsr  	DispRb
	      	addui	sp,sp,#8
	      	push 	#disassem_128
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_132
disassem_129:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_132
endpublic

public code disassem:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_218
	      	mov  	bp,sp
	      	subui	sp,sp,#96
	      	push 	r11
	      	push 	r12
	      	lw   	r11,24[bp]
	      	ldi  	r12,#0
	      	sw   	r0,-40[bp]
	      	sw   	r0,-48[bp]
	      	ldi  	r3,#1
	      	sw   	r3,-88[bp]
	      	sw   	r0,-96[bp]
disassem_219:
	      	lw   	r3,[r11]
	      	lw   	r4,32[bp]
	      	cmp  	r3,r3,r4
	      	bne  	r3,disassem_221
	      	bsr  	reverse_video
	      	ldi  	r3,#1
	      	sw   	r3,-96[bp]
disassem_221:
	      	lw   	r3,[r11]
	      	asri 	r3,r3,#2
	      	sw   	r3,-72[bp]
	      	lw   	r3,-72[bp]
	      	asli 	r3,r3,#2
	      	lhu  	r4,0[r12+r3]
	      	sh   	r4,-12[bp]
	      	lh   	r3,-12[bp]
	      	sh   	r3,-76[bp]
	      	lhu  	r3,-12[bp]
	      	and  	r3,r3,#127
	      	sw   	r3,-24[bp]
	      	lhu  	r3,-12[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#25
	      	and  	r3,r3,#127
	      	sw   	r3,-32[bp]
	      	lw   	r3,-24[bp]
	      	cmp  	r4,r3,#124
	      	beq  	r4,disassem_224
	      	cmp  	r4,r3,#2
	      	beq  	r4,disassem_225
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_226
	      	cmp  	r4,r3,#20
	      	beq  	r4,disassem_227
	      	cmp  	r4,r3,#5
	      	beq  	r4,disassem_228
	      	cmp  	r4,r3,#21
	      	beq  	r4,disassem_229
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_230
	      	cmp  	r4,r3,#22
	      	beq  	r4,disassem_231
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_232
	      	cmp  	r4,r3,#23
	      	beq  	r4,disassem_233
	      	cmp  	r4,r3,#8
	      	beq  	r4,disassem_234
	      	cmp  	r4,r3,#24
	      	beq  	r4,disassem_235
	      	cmp  	r4,r3,#12
	      	beq  	r4,disassem_236
	      	cmp  	r4,r3,#13
	      	beq  	r4,disassem_237
	      	cmp  	r4,r3,#14
	      	beq  	r4,disassem_238
	      	cmp  	r4,r3,#61
	      	beq  	r4,disassem_239
	      	cmp  	r4,r3,#56
	      	beq  	r4,disassem_240
	      	cmp  	r4,r3,#57
	      	beq  	r4,disassem_241
	      	cmp  	r4,r3,#58
	      	beq  	r4,disassem_242
	      	cmp  	r4,r3,#55
	      	beq  	r4,disassem_243
	      	cmp  	r4,r3,#59
	      	beq  	r4,disassem_244
	      	cmp  	r4,r3,#64
	      	beq  	r4,disassem_245
	      	cmp  	r4,r3,#65
	      	beq  	r4,disassem_246
	      	cmp  	r4,r3,#66
	      	beq  	r4,disassem_247
	      	cmp  	r4,r3,#67
	      	beq  	r4,disassem_248
	      	cmp  	r4,r3,#68
	      	beq  	r4,disassem_249
	      	cmp  	r4,r3,#69
	      	beq  	r4,disassem_250
	      	cmp  	r4,r3,#70
	      	beq  	r4,disassem_251
	      	cmp  	r4,r3,#71
	      	beq  	r4,disassem_252
	      	cmp  	r4,r3,#72
	      	beq  	r4,disassem_253
	      	cmp  	r4,r3,#73
	      	beq  	r4,disassem_254
	      	cmp  	r4,r3,#74
	      	beq  	r4,disassem_255
	      	cmp  	r4,r3,#75
	      	beq  	r4,disassem_256
	      	cmp  	r4,r3,#76
	      	beq  	r4,disassem_257
	      	cmp  	r4,r3,#77
	      	beq  	r4,disassem_258
	      	cmp  	r4,r3,#78
	      	beq  	r4,disassem_259
	      	cmp  	r4,r3,#79
	      	beq  	r4,disassem_260
	      	cmp  	r4,r3,#96
	      	beq  	r4,disassem_261
	      	cmp  	r4,r3,#97
	      	beq  	r4,disassem_262
	      	cmp  	r4,r3,#98
	      	beq  	r4,disassem_263
	      	cmp  	r4,r3,#99
	      	beq  	r4,disassem_264
	      	cmp  	r4,r3,#104
	      	beq  	r4,disassem_265
	      	cmp  	r4,r3,#105
	      	beq  	r4,disassem_266
	      	cmp  	r4,r3,#106
	      	beq  	r4,disassem_267
	      	cmp  	r4,r3,#107
	      	beq  	r4,disassem_268
	      	cmp  	r4,r3,#92
	      	beq  	r4,disassem_269
	      	cmp  	r4,r3,#110
	      	beq  	r4,disassem_270
	      	cmp  	r4,r3,#103
	      	beq  	r4,disassem_271
	      	cmp  	r4,r3,#87
	      	beq  	r4,disassem_272
	      	cmp  	r4,r3,#63
	      	beq  	r4,disassem_273
	      	cmp  	r4,r3,#10
	      	beq  	r4,disassem_274
	      	bra  	disassem_275
disassem_224:
	      	ldi  	r3,#1
	      	sw   	r3,-40[bp]
	      	lw   	r3,-88[bp]
	      	beq  	r3,disassem_276
	      	lh   	r3,-76[bp]
	      	sxh  	r3,r3
	      	sxh  	r3,r3
	      	asri 	r3,r3,#7
	      	sw   	r3,-48[bp]
	      	lw   	r3,-48[bp]
	      	and  	r3,r3,#16777216
	      	beq  	r3,disassem_278
	      	lw   	r3,-48[bp]
	      	ori  	r3,r3,#-16777216
	      	sw   	r3,-48[bp]
disassem_278:
	      	bra  	disassem_277
disassem_276:
	      	lw   	r3,-48[bp]
	      	asli 	r3,r3,#25
	      	lhu  	r4,-12[bp]
	      	andi 	r4,r4,#-1
	      	asri 	r4,r4,#7
	      	or   	r3,r3,r4
	      	sw   	r3,-48[bp]
disassem_277:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_133
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	sw   	r0,-88[bp]
	      	bra  	disassem_223
disassem_225:
	      	lw   	r3,-32[bp]
	      	cmp  	r4,r3,#55
	      	beq  	r4,disassem_281
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_282
	      	cmp  	r4,r3,#20
	      	beq  	r4,disassem_283
	      	cmp  	r4,r3,#5
	      	beq  	r4,disassem_284
	      	cmp  	r4,r3,#21
	      	beq  	r4,disassem_285
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_286
	      	cmp  	r4,r3,#22
	      	beq  	r4,disassem_287
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_288
	      	cmp  	r4,r3,#23
	      	beq  	r4,disassem_289
	      	cmp  	r4,r3,#8
	      	beq  	r4,disassem_290
	      	cmp  	r4,r3,#24
	      	beq  	r4,disassem_291
	      	cmp  	r4,r3,#12
	      	beq  	r4,disassem_292
	      	cmp  	r4,r3,#13
	      	beq  	r4,disassem_293
	      	cmp  	r4,r3,#14
	      	beq  	r4,disassem_294
	      	cmp  	r4,r3,#31
	      	beq  	r4,disassem_295
	      	cmp  	r4,r3,#30
	      	beq  	r4,disassem_296
	      	bra  	disassem_280
disassem_281:
	      	lhu  	r3,-12[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#31
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_298
	      	cmp  	r4,r3,#1
	      	beq  	r4,disassem_299
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_300
	      	cmp  	r4,r3,#29
	      	beq  	r4,disassem_301
	      	cmp  	r4,r3,#30
	      	beq  	r4,disassem_302
	      	cmp  	r4,r3,#31
	      	beq  	r4,disassem_303
	      	bra  	disassem_304
disassem_298:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_134
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_297
disassem_299:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_135
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_297
disassem_300:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_136
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_297
disassem_301:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_137
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_297
disassem_302:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_138
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_297
disassem_303:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_139
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_297
disassem_304:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_140
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_297
disassem_297:
	      	bra  	disassem_280
disassem_282:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_141
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_280
disassem_283:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_142
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_280
disassem_284:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_143
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_280
disassem_285:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_144
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_280
disassem_286:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_145
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_280
disassem_287:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_146
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_280
disassem_288:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_147
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_280
disassem_289:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_148
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_280
disassem_290:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_149
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_280
disassem_291:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_150
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_280
disassem_292:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_151
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_280
disassem_293:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_152
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_280
disassem_294:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_153
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_280
disassem_295:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_154
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRstc
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispSpr
	      	addui	sp,sp,#8
	      	push 	#disassem_155
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_280
disassem_296:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_156
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispSpr
	      	addui	sp,sp,#8
	      	push 	#disassem_157
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRa
	      	addui	sp,sp,#8
	      	push 	#disassem_158
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_280
disassem_280:
	      	bra  	disassem_223
disassem_226:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_159
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_227:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_160
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_228:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_161
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_229:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_162
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_230:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_163
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_231:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_164
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_232:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_165
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_233:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_166
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_234:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_167
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_235:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_168
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_236:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_169
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_237:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_170
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_238:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_171
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_239:
	      	lhu  	r3,-12[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#12
	      	and  	r3,r3,#7
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_306
	      	cmp  	r4,r3,#1
	      	beq  	r4,disassem_307
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_308
	      	cmp  	r4,r3,#5
	      	beq  	r4,disassem_309
	      	cmp  	r4,r3,#2
	      	beq  	r4,disassem_310
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_311
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_312
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_312
	      	bra  	disassem_305
disassem_306:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_172
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_305
disassem_307:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_173
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_305
disassem_308:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_174
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_305
disassem_309:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_175
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_305
disassem_310:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_176
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_305
disassem_311:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_177
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_305
disassem_312:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_178
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_305
disassem_305:
	      	bra  	disassem_223
disassem_240:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispBrk
	      	addui	sp,sp,#8
	      	bra  	disassem_223
disassem_241:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	lhu  	r3,-12[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#7
	      	sw   	r3,-64[bp]
	      	lhu  	r3,-12[bp]
	      	and  	r3,r3,#-2147483648
	      	beq  	r3,disassem_313
	      	lw   	r3,-64[bp]
	      	ori  	r3,r3,#-16777216
	      	sw   	r3,-64[bp]
disassem_313:
	      	lw   	r3,[r11]
	      	lw   	r4,-64[bp]
	      	asli 	r4,r4,#2
	      	addu 	r3,r3,r4
	      	sw   	r3,-56[bp]
	      	push 	-56[bp]
	      	push 	#disassem_179
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_223
disassem_242:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	lhu  	r3,-12[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#7
	      	sw   	r3,-64[bp]
	      	lhu  	r3,-12[bp]
	      	and  	r3,r3,#-2147483648
	      	beq  	r3,disassem_315
	      	lw   	r3,-64[bp]
	      	ori  	r3,r3,#-16777216
	      	sw   	r3,-64[bp]
disassem_315:
	      	lw   	r3,[r11]
	      	lw   	r4,-64[bp]
	      	asli 	r4,r4,#2
	      	addu 	r3,r3,r4
	      	sw   	r3,-56[bp]
	      	push 	-56[bp]
	      	push 	#disassem_180
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_223
disassem_243:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	lhu  	r3,-12[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#17
	      	sw   	r3,-56[bp]
	      	push 	-56[bp]
	      	push 	#disassem_181
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_223
disassem_244:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	lhu  	r3,-12[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#17
	      	sw   	r3,-56[bp]
	      	push 	-56[bp]
	      	push 	#disassem_182
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_223
disassem_245:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_183
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_246:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_184
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_247:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_185
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_248:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_186
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_249:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_187
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_250:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_188
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_251:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_189
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_252:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_190
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_253:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_191
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_223
disassem_254:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_192
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_223
disassem_255:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_193
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_223
disassem_256:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_194
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_223
disassem_257:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_195
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_223
disassem_258:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_196
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_223
disassem_259:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_197
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_223
disassem_260:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_198
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_223
disassem_261:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_199
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_262:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_200
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_263:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_201
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_264:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_202
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_265:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_203
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_223
disassem_266:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_204
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_223
disassem_267:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_205
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_223
disassem_268:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_206
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_223
disassem_269:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_207
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_270:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_208
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_223
disassem_271:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_209
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRa
	      	addui	sp,sp,#8
	      	push 	#disassem_210
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_223
disassem_272:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_211
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRst
	      	addui	sp,sp,#8
	      	push 	#disassem_212
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_223
disassem_273:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_213
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_223
disassem_274:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_214
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRstc
	      	addui	sp,sp,#8
	      	lw   	r3,-40[bp]
	      	beq  	r3,disassem_317
	      	lw   	r3,-48[bp]
	      	asli 	r3,r3,#15
	      	lhu  	r4,-12[bp]
	      	andi 	r4,r4,#-1
	      	asri 	r4,r4,#17
	      	or   	r3,r3,r4
	      	push 	r3
	      	push 	#disassem_215
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_318
disassem_317:
	      	lh   	r3,-76[bp]
	      	sxh  	r3,r3
	      	sxh  	r3,r3
	      	asri 	r3,r3,#17
	      	push 	r3
	      	push 	#disassem_216
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_318:
	      	bra  	disassem_223
disassem_275:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_217
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_223
disassem_223:
	      	lw   	r3,[r11]
	      	addu 	r3,r3,#4
	      	sw   	r3,[r11]
	      	lw   	r3,-96[bp]
	      	beq  	r3,disassem_319
	      	bsr  	reverse_video
	      	sw   	r0,-96[bp]
disassem_319:
	      	lw   	r3,-24[bp]
	      	cmp  	r3,r3,#124
	      	beq  	r3,disassem_219
disassem_220:
disassem_321:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_218:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_321
endpublic

public code disassem20:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_323
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	#disassem_322
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	sw   	r0,-8[bp]
disassem_324:
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#16
	      	bge  	r3,disassem_325
	      	push 	32[bp]
	      	pea  	24[bp]
	      	bsr  	disassem
	      	addui	sp,sp,#16
disassem_326:
	      	inc  	-8[bp],#1
	      	bra  	disassem_324
disassem_325:
disassem_327:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_323:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_327
endpublic

	rodata
	align	16
	align	8
disassem_322:	; Disassem:
	dc	68,105,115,97,115,115,101,109
	dc	58,13,10,0
disassem_217:	; ?????
	dc	63,63,63,63,63,13,10,0
disassem_216:	; #$%X
	dc	35,36,37,88,13,10,0
disassem_215:	; #$%X
	dc	35,36,37,88,13,10,0
disassem_214:	; LDI   
	dc	76,68,73,32,32,32,0
disassem_213:	; NOP
	dc	78,79,80,13,10,0
disassem_212:
	dc	13,10,0
disassem_211:	; POP   
	dc	80,79,80,32,32,32,0
disassem_210:
	dc	13,10,0
disassem_209:	; PUSH  
	dc	80,85,83,72,32,32,0
disassem_208:	; SWCR 
	dc	83,87,67,82,32,0
disassem_207:	; LWAR 
	dc	76,87,65,82,32,0
disassem_206:	; SW   
	dc	83,87,32,32,32,0
disassem_205:	; SH   
	dc	83,72,32,32,32,0
disassem_204:	; SC   
	dc	83,67,32,32,32,0
disassem_203:	; SB   
	dc	83,66,32,32,32,0
disassem_202:	; SW   
	dc	83,87,32,32,32,0
disassem_201:	; SH   
	dc	83,72,32,32,32,0
disassem_200:	; SC   
	dc	83,67,32,32,32,0
disassem_199:	; SB   
	dc	83,66,32,32,32,0
disassem_198:	; LEA  
	dc	76,69,65,32,32,0
disassem_197:	; LW   
	dc	76,87,32,32,32,0
disassem_196:	; LHU  
	dc	76,72,85,32,32,0
disassem_195:	; LH   
	dc	76,72,32,32,32,0
disassem_194:	; LCU  
	dc	76,67,85,32,32,0
disassem_193:	; LC   
	dc	76,67,32,32,32,0
disassem_192:	; LBU  
	dc	76,66,85,32,32,0
disassem_191:	; LB   
	dc	76,66,32,32,32,0
disassem_190:	; LEA  
	dc	76,69,65,32,32,0
disassem_189:	; LW   
	dc	76,87,32,32,32,0
disassem_188:	; LHU  
	dc	76,72,85,32,32,0
disassem_187:	; LH   
	dc	76,72,32,32,32,0
disassem_186:	; LCU  
	dc	76,67,85,32,32,0
disassem_185:	; LC   
	dc	76,67,32,32,32,0
disassem_184:	; LBU  
	dc	76,66,85,32,32,0
disassem_183:	; LB   
	dc	76,66,32,32,32,0
disassem_182:	; RTS   #%X
	dc	82,84,83,32,32,32,35,37
	dc	88,13,10,0
disassem_181:	; RTL   #%X
	dc	82,84,76,32,32,32,35,37
	dc	88,13,10,0
disassem_180:	; BRA   $%X
	dc	66,82,65,32,32,32,36,37
	dc	88,13,10,0
disassem_179:	; BSR   $%X
	dc	66,83,82,32,32,32,36,37
	dc	88,13,10,0
disassem_178:	; ???  
	dc	63,63,63,32,32,0
disassem_177:	; BGE  
	dc	66,71,69,32,32,0
disassem_176:	; BGT  
	dc	66,71,84,32,32,0
disassem_175:	; BLE  
	dc	66,76,69,32,32,0
disassem_174:	; BLT  
	dc	66,76,84,32,32,0
disassem_173:	; BNE  
	dc	66,78,69,32,32,0
disassem_172:	; BEQ  
	dc	66,69,81,32,32,0
disassem_171:	; EOR  
	dc	69,79,82,32,32,0
disassem_170:	; OR   
	dc	79,82,32,32,32,0
disassem_169:	; AND  
	dc	65,78,68,32,32,0
disassem_168:	; DIVU 
	dc	68,73,86,85,32,0
disassem_167:	; DIV  
	dc	68,73,86,32,32,0
disassem_166:	; MULU 
	dc	77,85,76,85,32,0
disassem_165:	; MUL  
	dc	77,85,76,32,32,0
disassem_164:	; CMPU 
	dc	67,77,80,85,32,0
disassem_163:	; CMP  
	dc	67,77,80,32,32,0
disassem_162:	; SUBU 
	dc	83,85,66,85,32,0
disassem_161:	; SUB  
	dc	83,85,66,32,32,0
disassem_160:	; ADDU 
	dc	65,68,68,85,32,0
disassem_159:	; ADD  
	dc	65,68,68,32,32,0
disassem_158:
	dc	13,10,0
disassem_157:	; ,
	dc	44,0
disassem_156:	; MTSPR 
	dc	77,84,83,80,82,32,0
disassem_155:
	dc	13,10,0
disassem_154:	; MFSPR 
	dc	77,70,83,80,82,32,0
disassem_153:	; EOR  
	dc	69,79,82,32,32,0
disassem_152:	; OR   
	dc	79,82,32,32,32,0
disassem_151:	; AND  
	dc	65,78,68,32,32,0
disassem_150:	; DIVU 
	dc	68,73,86,85,32,0
disassem_149:	; DIV  
	dc	68,73,86,32,32,0
disassem_148:	; MULU 
	dc	77,85,76,85,32,0
disassem_147:	; MUL  
	dc	77,85,76,32,32,0
disassem_146:	; CMPU 
	dc	67,77,80,85,32,0
disassem_145:	; CMP  
	dc	67,77,80,32,32,0
disassem_144:	; SUBU 
	dc	83,85,66,85,32,0
disassem_143:	; SUB  
	dc	83,85,66,32,32,0
disassem_142:	; ADDU 
	dc	65,68,68,85,32,0
disassem_141:	; ADD  
	dc	65,68,68,32,32,0
disassem_140:	; ???
	dc	63,63,63,13,10,0
disassem_139:	; RTI
	dc	82,84,73,13,10,0
disassem_138:	; RTE
	dc	82,84,69,13,10,0
disassem_137:	; RTD
	dc	82,84,68,13,10,0
disassem_136:	; WAI
	dc	87,65,73,13,10,0
disassem_135:	; SEI
	dc	83,69,73,13,10,0
disassem_134:	; CLI
	dc	67,76,73,13,10,0
disassem_133:	; IMM
	dc	73,77,77,13,10,0
disassem_128:
	dc	13,10,0
disassem_127:	; %s 
	dc	37,115,32,0
disassem_126:
	dc	13,10,0
disassem_125:	; MOV   
	dc	77,79,86,32,32,32,0
disassem_120:	; %06X
	dc	37,48,54,88,13,10,0
disassem_119:	; %s 
	dc	37,115,32,0
disassem_114:	; #$%X
	dc	35,36,37,88,13,10,0
disassem_113:	; #$%X
	dc	35,36,37,88,13,10,0
disassem_112:	; %s 
	dc	37,115,32,0
disassem_108:	; %s 
	dc	37,115,32,0
disassem_96:	; [R%d]
	dc	91,82,37,100,93,13,10,0
disassem_95:	; [R%d
	dc	91,82,37,100,0
disassem_94:	; [R%d+R%d
	dc	91,82,37,100,43,82,37,100
	dc	0
disassem_93:	; $%X
	dc	36,37,88,0
disassem_92:	; %s R%d,
	dc	37,115,32,82,37,100,44,0
disassem_83:	; BRK?  #%X
	dc	66,82,75,63,32,32,35,37
	dc	88,13,10,0
disassem_82:	; INT   #%X
	dc	73,78,84,32,32,32,35,37
	dc	88,13,10,0
disassem_81:	; DBG   #%X
	dc	68,66,71,32,32,32,35,37
	dc	88,13,10,0
disassem_80:	; SYS   #%X
	dc	83,89,83,32,32,32,35,37
	dc	88,13,10,0
disassem_74:	; ]
	dc	93,13,10,0
disassem_73:	; *%d]
	dc	42,37,100,93,13,10,0
disassem_65:
	dc	13,10,0
disassem_64:	; [R%d]
	dc	91,82,37,100,93,13,10,0
disassem_63:	; $%X
	dc	36,37,88,0
disassem_62:	; $%X
	dc	36,37,88,0
disassem_42:	; SPR%d
	dc	83,80,82,37,100,0
disassem_41:	; DBSTAT
	dc	68,66,83,84,65,84,0
disassem_40:	; DBCTRL
	dc	68,66,67,84,82,76,0
disassem_39:	; DBAD3
	dc	68,66,65,68,51,0
disassem_38:	; DBAD2
	dc	68,66,65,68,50,0
disassem_37:	; DBAD1
	dc	68,66,65,68,49,0
disassem_36:	; DBAD0
	dc	68,66,65,68,48,0
disassem_35:	; VBR
	dc	86,66,82,0
disassem_34:	; EPC
	dc	69,80,67,0
disassem_33:	; IPC
	dc	73,80,67,0
disassem_32:	; DPC
	dc	68,80,67,0
disassem_31:	; CLK
	dc	67,76,75,0
disassem_30:	; TICK
	dc	84,73,67,75,0
disassem_29:	; CR3
	dc	67,82,51,0
disassem_28:	; CR0
	dc	67,82,48,0
disassem_24:	; R%d
	dc	82,37,100,0
disassem_20:	; R%d
	dc	82,37,100,0
disassem_16:	; R%d,
	dc	82,37,100,44,0
disassem_12:	; R%d,
	dc	82,37,100,44,0
disassem_8:	; r%d
	dc	114,37,100,0
disassem_4:	; %06X %02X %02X %02X %02X	
	dc	37,48,54,88,32,37,48,50
	dc	88,32,37,48,50,88,32,37
	dc	48,50,88,32,37,48,50,88
	dc	9,0
;	global	DispRR
;	global	DumpInsnBytes
	extern	GetCurrAttr
;	global	disassem
;	global	reverse_video
	extern	printf
;	global	DispBcc
;	global	disassem20
	extern	putstr2
;	global	SetCurAttr
