	code
	align	16
public code SetNormAttr:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	         push  r6
         lw    r1,24[bp]
         ldi   r6,#$22
         sys   #410
         pop   r6
     
disassem_1:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code GetNormAttr:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	         push  r6
         ldi   r6,#$23
         sys   #410
         pop   r6
     
disassem_3:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code reverse_video:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_4
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	bsr  	GetNormAttr
	      	mov  	r3,r1
	      	andi 	r3,r3,#-1
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
	      	bsr  	SetNormAttr
	      	addui	sp,sp,#8
disassem_5:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_4:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_5
endpublic

public code DumpInsnBytes:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_7
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
	      	push 	#disassem_6
	      	bsr  	printf
	      	addui	sp,sp,#48
disassem_8:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_7:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_8
endpublic

DispRst:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_11
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	asri 	r3,r3,#12
	      	and  	r3,r3,#31
	      	push 	r3
	      	push 	#disassem_10
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_12:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_11:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_12
DispRstc:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_15
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	asri 	r3,r3,#12
	      	and  	r3,r3,#31
	      	push 	r3
	      	push 	#disassem_14
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_16:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_15:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_16
DispRac:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_19
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	asri 	r3,r3,#7
	      	and  	r3,r3,#31
	      	push 	r3
	      	push 	#disassem_18
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_20:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_19:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_20
DispRa:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_23
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	asri 	r3,r3,#7
	      	and  	r3,r3,#31
	      	push 	r3
	      	push 	#disassem_22
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_24:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_23:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_24
DispRb:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_27
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#31
	      	push 	r3
	      	push 	#disassem_26
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_28:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_27:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_28
DispSpr:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_45
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r3,24[bp]
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#255
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_47
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_48
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_49
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_50
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_51
	      	cmp  	r4,r3,#8
	      	beq  	r4,disassem_52
	      	cmp  	r4,r3,#9
	      	beq  	r4,disassem_53
	      	cmp  	r4,r3,#10
	      	beq  	r4,disassem_54
	      	cmp  	r4,r3,#50
	      	beq  	r4,disassem_55
	      	cmp  	r4,r3,#51
	      	beq  	r4,disassem_56
	      	cmp  	r4,r3,#52
	      	beq  	r4,disassem_57
	      	cmp  	r4,r3,#53
	      	beq  	r4,disassem_58
	      	cmp  	r4,r3,#54
	      	beq  	r4,disassem_59
	      	cmp  	r4,r3,#55
	      	beq  	r4,disassem_60
	      	bra  	disassem_61
disassem_47:
	      	push 	#disassem_30
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_46
disassem_48:
	      	push 	#disassem_31
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_46
disassem_49:
	      	push 	#disassem_32
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_46
disassem_50:
	      	push 	#disassem_33
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_46
disassem_51:
	      	push 	#disassem_34
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_46
disassem_52:
	      	push 	#disassem_35
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_46
disassem_53:
	      	push 	#disassem_36
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_46
disassem_54:
	      	push 	#disassem_37
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_46
disassem_55:
	      	push 	#disassem_38
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_46
disassem_56:
	      	push 	#disassem_39
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_46
disassem_57:
	      	push 	#disassem_40
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_46
disassem_58:
	      	push 	#disassem_41
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_46
disassem_59:
	      	push 	#disassem_42
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_46
disassem_60:
	      	push 	#disassem_43
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_46
disassem_61:
	      	push 	-8[bp]
	      	push 	#disassem_44
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_46:
disassem_62:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_45:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_62
DispMemAddress:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_68
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r3,40[bp]
	      	sh   	r3,-4[bp]
	      	lw   	r3,24[bp]
	      	beq  	r3,disassem_69
	      	lw   	r3,32[bp]
	      	asli 	r3,r3,#15
	      	lw   	r4,40[bp]
	      	asri 	r4,r4,#17
	      	or   	r3,r3,r4
	      	push 	r3
	      	push 	#disassem_64
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_70
disassem_69:
	      	lh   	r3,-4[bp]
	      	sxh  	r3,r3
	      	sxh  	r3,r3
	      	asri 	r3,r3,#17
	      	push 	r3
	      	push 	#disassem_65
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_70:
	      	lw   	r3,40[bp]
	      	asri 	r3,r3,#7
	      	and  	r3,r3,#31
	      	beq  	r3,disassem_71
	      	lw   	r3,40[bp]
	      	asri 	r3,r3,#7
	      	and  	r3,r3,#31
	      	push 	r3
	      	push 	#disassem_66
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_72
disassem_71:
	      	push 	#disassem_67
	      	bsr  	printf
	      	addui	sp,sp,#8
disassem_72:
disassem_73:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_68:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_73
DispInc:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_82
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	lw   	r3,40[bp]
	      	sh   	r3,-4[bp]
	      	lw   	r3,40[bp]
	      	asri 	r3,r3,#7
	      	and  	r3,r3,#31
	      	sw   	r3,-16[bp]
	      	lw   	r3,40[bp]
	      	asri 	r3,r3,#12
	      	and  	r3,r3,#31
	      	sw   	r3,-24[bp]
	      	lw   	r3,-24[bp]
	      	and  	r3,r3,#16
	      	cmp  	r3,r3,#16
	      	bne  	r3,disassem_83
	      	lw   	r3,-24[bp]
	      	ori  	r3,r3,#-16
	      	sw   	r3,-24[bp]
	      	lw   	r3,-24[bp]
	      	neg  	r3,r3
	      	sw   	r3,-24[bp]
	      	push 	#disassem_75
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_84
disassem_83:
	      	push 	#disassem_76
	      	bsr  	printf
	      	addui	sp,sp,#8
disassem_84:
	      	lw   	r3,24[bp]
	      	beq  	r3,disassem_85
	      	lw   	r3,32[bp]
	      	asli 	r3,r3,#15
	      	lw   	r4,40[bp]
	      	asri 	r4,r4,#17
	      	or   	r3,r3,r4
	      	push 	r3
	      	push 	#disassem_77
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_86
disassem_85:
	      	lh   	r3,-4[bp]
	      	sxh  	r3,r3
	      	sxh  	r3,r3
	      	asri 	r3,r3,#17
	      	push 	r3
	      	push 	#disassem_78
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_86:
	      	lw   	r3,-16[bp]
	      	bne  	r3,disassem_87
	      	push 	#disassem_79
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_88
disassem_87:
	      	push 	-16[bp]
	      	push 	#disassem_80
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_88:
	      	push 	-24[bp]
	      	push 	#disassem_81
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_89:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_82:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_89
PrintSc:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_93
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	cmp  	r3,r3,#1
	      	ble  	r3,disassem_94
	      	push 	24[bp]
	      	push 	#disassem_91
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_95
disassem_94:
	      	push 	#disassem_92
	      	bsr  	printf
	      	addui	sp,sp,#8
disassem_95:
disassem_96:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_93:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_96
DispBrk:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_102
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
	      	beq  	r4,disassem_104
	      	cmp  	r4,r3,#1
	      	beq  	r4,disassem_105
	      	cmp  	r4,r3,#2
	      	beq  	r4,disassem_106
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_107
	      	bra  	disassem_103
disassem_104:
	      	push 	-16[bp]
	      	push 	#disassem_98
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_105:
	      	push 	-16[bp]
	      	push 	#disassem_99
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_106:
	      	push 	-16[bp]
	      	push 	#disassem_100
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_107:
	      	push 	-16[bp]
	      	push 	#disassem_101
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_103:
disassem_108:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_102:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_108
DispIndexedAddr:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_115
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
	      	push 	#disassem_110
	      	bsr  	printf
	      	addui	sp,sp,#24
	      	lw   	r3,-8[bp]
	      	beq  	r3,disassem_116
	      	push 	-8[bp]
	      	push 	#disassem_111
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_116:
	      	lw   	r3,-16[bp]
	      	beq  	r3,disassem_118
	      	lw   	r3,-24[bp]
	      	beq  	r3,disassem_118
	      	push 	#disassem_112
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	-40[bp]
	      	bsr  	PrintSc
	      	addui	sp,sp,#8
	      	bra  	disassem_119
disassem_118:
	      	lw   	r3,-16[bp]
	      	bne  	r3,disassem_120
	      	push 	-24[bp]
	      	push 	#disassem_113
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	push 	-40[bp]
	      	bsr  	PrintSc
	      	addui	sp,sp,#8
	      	bra  	disassem_121
disassem_120:
	      	lw   	r3,-24[bp]
	      	bne  	r3,disassem_122
	      	push 	#disassem_114
	      	bsr  	printf
	      	addui	sp,sp,#8
disassem_122:
disassem_121:
disassem_119:
disassem_124:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_115:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_124
DispLS:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_127
	      	mov  	bp,sp
	      	push 	56[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	push 	#disassem_126
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
disassem_128:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_127:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_128
DispRI:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_133
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r3,56[bp]
	      	sh   	r3,-4[bp]
	      	push 	56[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	push 	#disassem_130
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	push 	56[bp]
	      	bsr  	DispRstc
	      	addui	sp,sp,#8
	      	push 	56[bp]
	      	bsr  	DispRac
	      	addui	sp,sp,#8
	      	lw   	r3,40[bp]
	      	beq  	r3,disassem_134
	      	lw   	r3,48[bp]
	      	asli 	r3,r3,#15
	      	lw   	r4,56[bp]
	      	asri 	r4,r4,#17
	      	or   	r3,r3,r4
	      	push 	r3
	      	push 	#disassem_131
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_135
disassem_134:
	      	lh   	r3,-4[bp]
	      	sxh  	r3,r3
	      	sxh  	r3,r3
	      	asri 	r3,r3,#17
	      	push 	r3
	      	push 	#disassem_132
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_135:
disassem_136:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_133:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_136
public code DispBcc:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_139
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	lw   	r3,40[bp]
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#32767
	      	asli 	r3,r3,#2
	      	sw   	r3,-16[bp]
	      	lw   	r3,40[bp]
	      	and  	r3,r3,#-2147483648
	      	beq  	r3,disassem_140
	      	lw   	r3,-16[bp]
	      	ori  	r3,r3,#-65536
	      	sw   	r3,-16[bp]
disassem_140:
	      	push 	40[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	push 	#disassem_137
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	push 	40[bp]
	      	bsr  	DispRac
	      	addui	sp,sp,#8
	      	lw   	r3,24[bp]
	      	lw   	r4,-16[bp]
	      	addu 	r3,r3,r4
	      	push 	r3
	      	push 	#disassem_138
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_142:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_139:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_142
endpublic

public code DispRR:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_147
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
	      	cmp  	r3,r3,#13
	      	bne  	r3,disassem_148
	      	lw   	r3,-16[bp]
	      	bne  	r3,disassem_148
	      	push 	#disassem_143
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
	      	push 	#disassem_144
	      	bsr  	printf
	      	addui	sp,sp,#8
disassem_150:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_148:
	      	push 	32[bp]
	      	push 	#disassem_145
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
	      	push 	#disassem_146
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_150
disassem_147:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_150
endpublic

public code disassem:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_236
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
disassem_237:
	      	lw   	r3,[r11]
	      	lw   	r4,32[bp]
	      	cmp  	r3,r3,r4
	      	bne  	r3,disassem_239
	      	bsr  	reverse_video
	      	ldi  	r3,#1
	      	sw   	r3,-96[bp]
disassem_239:
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
	      	beq  	r4,disassem_242
	      	cmp  	r4,r3,#2
	      	beq  	r4,disassem_243
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_244
	      	cmp  	r4,r3,#20
	      	beq  	r4,disassem_245
	      	cmp  	r4,r3,#5
	      	beq  	r4,disassem_246
	      	cmp  	r4,r3,#21
	      	beq  	r4,disassem_247
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_248
	      	cmp  	r4,r3,#22
	      	beq  	r4,disassem_249
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_250
	      	cmp  	r4,r3,#23
	      	beq  	r4,disassem_251
	      	cmp  	r4,r3,#8
	      	beq  	r4,disassem_252
	      	cmp  	r4,r3,#24
	      	beq  	r4,disassem_253
	      	cmp  	r4,r3,#12
	      	beq  	r4,disassem_254
	      	cmp  	r4,r3,#13
	      	beq  	r4,disassem_255
	      	cmp  	r4,r3,#14
	      	beq  	r4,disassem_256
	      	cmp  	r4,r3,#61
	      	beq  	r4,disassem_257
	      	cmp  	r4,r3,#56
	      	beq  	r4,disassem_258
	      	cmp  	r4,r3,#57
	      	beq  	r4,disassem_259
	      	cmp  	r4,r3,#58
	      	beq  	r4,disassem_260
	      	cmp  	r4,r3,#55
	      	beq  	r4,disassem_261
	      	cmp  	r4,r3,#59
	      	beq  	r4,disassem_262
	      	cmp  	r4,r3,#64
	      	beq  	r4,disassem_263
	      	cmp  	r4,r3,#65
	      	beq  	r4,disassem_264
	      	cmp  	r4,r3,#66
	      	beq  	r4,disassem_265
	      	cmp  	r4,r3,#67
	      	beq  	r4,disassem_266
	      	cmp  	r4,r3,#68
	      	beq  	r4,disassem_267
	      	cmp  	r4,r3,#69
	      	beq  	r4,disassem_268
	      	cmp  	r4,r3,#70
	      	beq  	r4,disassem_269
	      	cmp  	r4,r3,#71
	      	beq  	r4,disassem_270
	      	cmp  	r4,r3,#72
	      	beq  	r4,disassem_271
	      	cmp  	r4,r3,#73
	      	beq  	r4,disassem_272
	      	cmp  	r4,r3,#74
	      	beq  	r4,disassem_273
	      	cmp  	r4,r3,#75
	      	beq  	r4,disassem_274
	      	cmp  	r4,r3,#76
	      	beq  	r4,disassem_275
	      	cmp  	r4,r3,#77
	      	beq  	r4,disassem_276
	      	cmp  	r4,r3,#78
	      	beq  	r4,disassem_277
	      	cmp  	r4,r3,#79
	      	beq  	r4,disassem_278
	      	cmp  	r4,r3,#100
	      	beq  	r4,disassem_279
	      	cmp  	r4,r3,#96
	      	beq  	r4,disassem_280
	      	cmp  	r4,r3,#97
	      	beq  	r4,disassem_281
	      	cmp  	r4,r3,#98
	      	beq  	r4,disassem_282
	      	cmp  	r4,r3,#99
	      	beq  	r4,disassem_283
	      	cmp  	r4,r3,#104
	      	beq  	r4,disassem_284
	      	cmp  	r4,r3,#105
	      	beq  	r4,disassem_285
	      	cmp  	r4,r3,#106
	      	beq  	r4,disassem_286
	      	cmp  	r4,r3,#107
	      	beq  	r4,disassem_287
	      	cmp  	r4,r3,#92
	      	beq  	r4,disassem_288
	      	cmp  	r4,r3,#110
	      	beq  	r4,disassem_289
	      	cmp  	r4,r3,#103
	      	beq  	r4,disassem_290
	      	cmp  	r4,r3,#87
	      	beq  	r4,disassem_291
	      	cmp  	r4,r3,#63
	      	beq  	r4,disassem_292
	      	cmp  	r4,r3,#10
	      	beq  	r4,disassem_293
	      	bra  	disassem_294
disassem_242:
	      	ldi  	r3,#1
	      	sw   	r3,-40[bp]
	      	lw   	r3,-88[bp]
	      	beq  	r3,disassem_295
	      	lh   	r3,-76[bp]
	      	sxh  	r3,r3
	      	sxh  	r3,r3
	      	asri 	r3,r3,#7
	      	sw   	r3,-48[bp]
	      	lw   	r3,-48[bp]
	      	and  	r3,r3,#16777216
	      	beq  	r3,disassem_297
	      	lw   	r3,-48[bp]
	      	ori  	r3,r3,#-16777216
	      	sw   	r3,-48[bp]
disassem_297:
	      	bra  	disassem_296
disassem_295:
	      	lw   	r3,-48[bp]
	      	asli 	r3,r3,#25
	      	lhu  	r4,-12[bp]
	      	andi 	r4,r4,#-1
	      	asri 	r4,r4,#7
	      	or   	r3,r3,r4
	      	sw   	r3,-48[bp]
disassem_296:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_151
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	sw   	r0,-88[bp]
	      	bra  	disassem_241
disassem_243:
	      	lw   	r3,-32[bp]
	      	cmp  	r4,r3,#55
	      	beq  	r4,disassem_300
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_301
	      	cmp  	r4,r3,#20
	      	beq  	r4,disassem_302
	      	cmp  	r4,r3,#5
	      	beq  	r4,disassem_303
	      	cmp  	r4,r3,#21
	      	beq  	r4,disassem_304
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_305
	      	cmp  	r4,r3,#22
	      	beq  	r4,disassem_306
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_307
	      	cmp  	r4,r3,#23
	      	beq  	r4,disassem_308
	      	cmp  	r4,r3,#8
	      	beq  	r4,disassem_309
	      	cmp  	r4,r3,#24
	      	beq  	r4,disassem_310
	      	cmp  	r4,r3,#12
	      	beq  	r4,disassem_311
	      	cmp  	r4,r3,#13
	      	beq  	r4,disassem_312
	      	cmp  	r4,r3,#14
	      	beq  	r4,disassem_313
	      	cmp  	r4,r3,#31
	      	beq  	r4,disassem_314
	      	cmp  	r4,r3,#30
	      	beq  	r4,disassem_315
	      	bra  	disassem_299
disassem_300:
	      	lhu  	r3,-12[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#31
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_317
	      	cmp  	r4,r3,#1
	      	beq  	r4,disassem_318
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_319
	      	cmp  	r4,r3,#29
	      	beq  	r4,disassem_320
	      	cmp  	r4,r3,#30
	      	beq  	r4,disassem_321
	      	cmp  	r4,r3,#31
	      	beq  	r4,disassem_322
	      	bra  	disassem_323
disassem_317:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_152
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_316
disassem_318:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_153
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_316
disassem_319:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_154
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_316
disassem_320:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_155
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_316
disassem_321:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_156
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_316
disassem_322:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_157
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_316
disassem_323:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_158
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_316
disassem_316:
	      	bra  	disassem_299
disassem_301:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_159
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_299
disassem_302:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_160
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_299
disassem_303:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_161
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_299
disassem_304:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_162
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_299
disassem_305:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_163
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_299
disassem_306:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_164
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_299
disassem_307:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_165
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_299
disassem_308:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_166
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_299
disassem_309:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_167
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_299
disassem_310:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_168
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_299
disassem_311:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_169
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_299
disassem_312:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_170
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_299
disassem_313:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_171
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_299
disassem_314:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_172
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
	      	push 	#disassem_173
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_299
disassem_315:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_174
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispSpr
	      	addui	sp,sp,#8
	      	push 	#disassem_175
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRa
	      	addui	sp,sp,#8
	      	push 	#disassem_176
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_299
disassem_299:
	      	bra  	disassem_241
disassem_244:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_177
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_245:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_178
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_246:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_179
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_247:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_180
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_248:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_181
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_249:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_182
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_250:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_183
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_251:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_184
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_252:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_185
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_253:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_186
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_254:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_187
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_255:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_188
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_256:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_189
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_257:
	      	lhu  	r3,-12[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#12
	      	and  	r3,r3,#7
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_325
	      	cmp  	r4,r3,#1
	      	beq  	r4,disassem_326
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_327
	      	cmp  	r4,r3,#5
	      	beq  	r4,disassem_328
	      	cmp  	r4,r3,#2
	      	beq  	r4,disassem_329
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_330
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_331
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_331
	      	bra  	disassem_324
disassem_325:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_190
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_324
disassem_326:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_191
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_324
disassem_327:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_192
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_324
disassem_328:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_193
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_324
disassem_329:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_194
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_324
disassem_330:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_195
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_324
disassem_331:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_196
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_324
disassem_324:
	      	bra  	disassem_241
disassem_258:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispBrk
	      	addui	sp,sp,#8
	      	bra  	disassem_241
disassem_259:
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
	      	beq  	r3,disassem_332
	      	lw   	r3,-64[bp]
	      	ori  	r3,r3,#-16777216
	      	sw   	r3,-64[bp]
disassem_332:
	      	lw   	r3,[r11]
	      	lw   	r4,-64[bp]
	      	asli 	r4,r4,#2
	      	addu 	r3,r3,r4
	      	sw   	r3,-56[bp]
	      	push 	-56[bp]
	      	push 	#disassem_197
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_241
disassem_260:
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
	      	beq  	r3,disassem_334
	      	lw   	r3,-64[bp]
	      	ori  	r3,r3,#-16777216
	      	sw   	r3,-64[bp]
disassem_334:
	      	lw   	r3,[r11]
	      	lw   	r4,-64[bp]
	      	asli 	r4,r4,#2
	      	addu 	r3,r3,r4
	      	sw   	r3,-56[bp]
	      	push 	-56[bp]
	      	push 	#disassem_198
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_241
disassem_261:
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
	      	push 	#disassem_199
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_241
disassem_262:
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
	      	push 	#disassem_200
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_241
disassem_263:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_201
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_264:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_202
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_265:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_203
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_266:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_204
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_267:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_205
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_268:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_206
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_269:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_207
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_270:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_208
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_271:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_209
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_241
disassem_272:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_210
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_241
disassem_273:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_211
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_241
disassem_274:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_212
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_241
disassem_275:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_213
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_241
disassem_276:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_214
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_241
disassem_277:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_215
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_241
disassem_278:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_216
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_241
disassem_279:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	bsr  	DispInc
	      	addui	sp,sp,#24
	      	bra  	disassem_241
disassem_280:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_217
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_281:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_218
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_282:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_219
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_283:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_220
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_284:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_221
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_241
disassem_285:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_222
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_241
disassem_286:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_223
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_241
disassem_287:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_224
	      	push 	[r11]
	      	bsr  	DispIndexedAddr
	      	addui	sp,sp,#24
	      	bra  	disassem_241
disassem_288:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_225
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_289:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_226
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_241
disassem_290:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_227
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRa
	      	addui	sp,sp,#8
	      	push 	#disassem_228
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_241
disassem_291:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_229
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRst
	      	addui	sp,sp,#8
	      	push 	#disassem_230
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_241
disassem_292:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_231
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_241
disassem_293:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_232
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRstc
	      	addui	sp,sp,#8
	      	lw   	r3,-40[bp]
	      	beq  	r3,disassem_336
	      	lw   	r3,-48[bp]
	      	asli 	r3,r3,#15
	      	lhu  	r4,-12[bp]
	      	andi 	r4,r4,#-1
	      	asri 	r4,r4,#17
	      	or   	r3,r3,r4
	      	push 	r3
	      	push 	#disassem_233
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_337
disassem_336:
	      	lh   	r3,-76[bp]
	      	sxh  	r3,r3
	      	sxh  	r3,r3
	      	asri 	r3,r3,#17
	      	push 	r3
	      	push 	#disassem_234
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_337:
	      	bra  	disassem_241
disassem_294:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_235
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_241
disassem_241:
	      	lw   	r3,[r11]
	      	addu 	r3,r3,#4
	      	sw   	r3,[r11]
	      	lw   	r3,-96[bp]
	      	beq  	r3,disassem_338
	      	bsr  	reverse_video
	      	sw   	r0,-96[bp]
disassem_338:
	      	lw   	r3,-24[bp]
	      	cmp  	r3,r3,#124
	      	beq  	r3,disassem_237
disassem_238:
disassem_340:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_236:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_340
endpublic

public code disassem20:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_342
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	#disassem_341
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	sw   	r0,-8[bp]
disassem_343:
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#16
	      	bge  	r3,disassem_344
	      	push 	32[bp]
	      	pea  	24[bp]
	      	bsr  	disassem
	      	addui	sp,sp,#16
disassem_345:
	      	inc  	-8[bp],#1
	      	bra  	disassem_343
disassem_344:
disassem_346:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_342:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_346
endpublic

	rodata
	align	16
	align	8
disassem_341:	; Disassem:
	dc	68,105,115,97,115,115,101,109
	dc	58,13,10,0
disassem_235:	; ?????
	dc	63,63,63,63,63,13,10,0
disassem_234:	; #$%X
	dc	35,36,37,88,13,10,0
disassem_233:	; #$%X
	dc	35,36,37,88,13,10,0
disassem_232:	; LDI   
	dc	76,68,73,32,32,32,0
disassem_231:	; NOP
	dc	78,79,80,13,10,0
disassem_230:
	dc	13,10,0
disassem_229:	; POP   
	dc	80,79,80,32,32,32,0
disassem_228:
	dc	13,10,0
disassem_227:	; PUSH  
	dc	80,85,83,72,32,32,0
disassem_226:	; SWCR 
	dc	83,87,67,82,32,0
disassem_225:	; LWAR 
	dc	76,87,65,82,32,0
disassem_224:	; SW   
	dc	83,87,32,32,32,0
disassem_223:	; SH   
	dc	83,72,32,32,32,0
disassem_222:	; SC   
	dc	83,67,32,32,32,0
disassem_221:	; SB   
	dc	83,66,32,32,32,0
disassem_220:	; SW   
	dc	83,87,32,32,32,0
disassem_219:	; SH   
	dc	83,72,32,32,32,0
disassem_218:	; SC   
	dc	83,67,32,32,32,0
disassem_217:	; SB   
	dc	83,66,32,32,32,0
disassem_216:	; LEA  
	dc	76,69,65,32,32,0
disassem_215:	; LW   
	dc	76,87,32,32,32,0
disassem_214:	; LHU  
	dc	76,72,85,32,32,0
disassem_213:	; LH   
	dc	76,72,32,32,32,0
disassem_212:	; LCU  
	dc	76,67,85,32,32,0
disassem_211:	; LC   
	dc	76,67,32,32,32,0
disassem_210:	; LBU  
	dc	76,66,85,32,32,0
disassem_209:	; LB   
	dc	76,66,32,32,32,0
disassem_208:	; LEA  
	dc	76,69,65,32,32,0
disassem_207:	; LW   
	dc	76,87,32,32,32,0
disassem_206:	; LHU  
	dc	76,72,85,32,32,0
disassem_205:	; LH   
	dc	76,72,32,32,32,0
disassem_204:	; LCU  
	dc	76,67,85,32,32,0
disassem_203:	; LC   
	dc	76,67,32,32,32,0
disassem_202:	; LBU  
	dc	76,66,85,32,32,0
disassem_201:	; LB   
	dc	76,66,32,32,32,0
disassem_200:	; RTS   #%X
	dc	82,84,83,32,32,32,35,37
	dc	88,13,10,0
disassem_199:	; RTL   #%X
	dc	82,84,76,32,32,32,35,37
	dc	88,13,10,0
disassem_198:	; BRA   $%X
	dc	66,82,65,32,32,32,36,37
	dc	88,13,10,0
disassem_197:	; BSR   $%X
	dc	66,83,82,32,32,32,36,37
	dc	88,13,10,0
disassem_196:	; ???  
	dc	63,63,63,32,32,0
disassem_195:	; BGE  
	dc	66,71,69,32,32,0
disassem_194:	; BGT  
	dc	66,71,84,32,32,0
disassem_193:	; BLE  
	dc	66,76,69,32,32,0
disassem_192:	; BLT  
	dc	66,76,84,32,32,0
disassem_191:	; BNE  
	dc	66,78,69,32,32,0
disassem_190:	; BEQ  
	dc	66,69,81,32,32,0
disassem_189:	; EOR  
	dc	69,79,82,32,32,0
disassem_188:	; OR   
	dc	79,82,32,32,32,0
disassem_187:	; AND  
	dc	65,78,68,32,32,0
disassem_186:	; DIVU 
	dc	68,73,86,85,32,0
disassem_185:	; DIV  
	dc	68,73,86,32,32,0
disassem_184:	; MULU 
	dc	77,85,76,85,32,0
disassem_183:	; MUL  
	dc	77,85,76,32,32,0
disassem_182:	; CMPU 
	dc	67,77,80,85,32,0
disassem_181:	; CMP  
	dc	67,77,80,32,32,0
disassem_180:	; SUBU 
	dc	83,85,66,85,32,0
disassem_179:	; SUB  
	dc	83,85,66,32,32,0
disassem_178:	; ADDU 
	dc	65,68,68,85,32,0
disassem_177:	; ADD  
	dc	65,68,68,32,32,0
disassem_176:
	dc	13,10,0
disassem_175:	; ,
	dc	44,0
disassem_174:	; MTSPR 
	dc	77,84,83,80,82,32,0
disassem_173:
	dc	13,10,0
disassem_172:	; MFSPR 
	dc	77,70,83,80,82,32,0
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
disassem_158:	; ???
	dc	63,63,63,13,10,0
disassem_157:	; RTI
	dc	82,84,73,13,10,0
disassem_156:	; RTE
	dc	82,84,69,13,10,0
disassem_155:	; RTD
	dc	82,84,68,13,10,0
disassem_154:	; WAI
	dc	87,65,73,13,10,0
disassem_153:	; SEI
	dc	83,69,73,13,10,0
disassem_152:	; CLI
	dc	67,76,73,13,10,0
disassem_151:	; IMM
	dc	73,77,77,13,10,0
disassem_146:
	dc	13,10,0
disassem_145:	; %s 
	dc	37,115,32,0
disassem_144:
	dc	13,10,0
disassem_143:	; MOV   
	dc	77,79,86,32,32,32,0
disassem_138:	; %06X
	dc	37,48,54,88,13,10,0
disassem_137:	; %s 
	dc	37,115,32,0
disassem_132:	; #$%X
	dc	35,36,37,88,13,10,0
disassem_131:	; #$%X
	dc	35,36,37,88,13,10,0
disassem_130:	; %s 
	dc	37,115,32,0
disassem_126:	; %s 
	dc	37,115,32,0
disassem_114:	; [R%d]
	dc	91,82,37,100,93,13,10,0
disassem_113:	; [R%d
	dc	91,82,37,100,0
disassem_112:	; [R%d+R%d
	dc	91,82,37,100,43,82,37,100
	dc	0
disassem_111:	; $%X
	dc	36,37,88,0
disassem_110:	; %s R%d,
	dc	37,115,32,82,37,100,44,0
disassem_101:	; BRK?  #%X
	dc	66,82,75,63,32,32,35,37
	dc	88,13,10,0
disassem_100:	; INT   #%X
	dc	73,78,84,32,32,32,35,37
	dc	88,13,10,0
disassem_99:	; DBG   #%X
	dc	68,66,71,32,32,32,35,37
	dc	88,13,10,0
disassem_98:	; SYS   #%X
	dc	83,89,83,32,32,32,35,37
	dc	88,13,10,0
disassem_92:	; ]
	dc	93,13,10,0
disassem_91:	; *%d]
	dc	42,37,100,93,13,10,0
disassem_81:	; #%d
	dc	35,37,100,13,10,0
disassem_80:	; [R%d],
	dc	91,82,37,100,93,44,0
disassem_79:	; ,
	dc	44,0
disassem_78:	; $%X
	dc	36,37,88,0
disassem_77:	; $%X
	dc	36,37,88,0
disassem_76:	; INC   
	dc	73,78,67,32,32,32,0
disassem_75:	; DEC   
	dc	68,69,67,32,32,32,0
disassem_67:
	dc	13,10,0
disassem_66:	; [R%d]
	dc	91,82,37,100,93,13,10,0
disassem_65:	; $%X
	dc	36,37,88,0
disassem_64:	; $%X
	dc	36,37,88,0
disassem_44:	; SPR%d
	dc	83,80,82,37,100,0
disassem_43:	; DBSTAT
	dc	68,66,83,84,65,84,0
disassem_42:	; DBCTRL
	dc	68,66,67,84,82,76,0
disassem_41:	; DBAD3
	dc	68,66,65,68,51,0
disassem_40:	; DBAD2
	dc	68,66,65,68,50,0
disassem_39:	; DBAD1
	dc	68,66,65,68,49,0
disassem_38:	; DBAD0
	dc	68,66,65,68,48,0
disassem_37:	; VBR
	dc	86,66,82,0
disassem_36:	; EPC
	dc	69,80,67,0
disassem_35:	; IPC
	dc	73,80,67,0
disassem_34:	; DPC
	dc	68,80,67,0
disassem_33:	; CLK
	dc	67,76,75,0
disassem_32:	; TICK
	dc	84,73,67,75,0
disassem_31:	; CR3
	dc	67,82,51,0
disassem_30:	; CR0
	dc	67,82,48,0
disassem_26:	; R%d
	dc	82,37,100,0
disassem_22:	; R%d
	dc	82,37,100,0
disassem_18:	; R%d,
	dc	82,37,100,44,0
disassem_14:	; R%d,
	dc	82,37,100,44,0
disassem_10:	; r%d
	dc	114,37,100,0
disassem_6:	; %06X %02X %02X %02X %02X	
	dc	37,48,54,88,32,37,48,50
	dc	88,32,37,48,50,88,32,37
	dc	48,50,88,32,37,48,50,88
	dc	9,0
;	global	DispRR
;	global	DumpInsnBytes
;	global	GetNormAttr
;	global	disassem
;	global	SetNormAttr
;	global	reverse_video
	extern	printf
;	global	DispBcc
;	global	disassem20
	extern	putstr2
