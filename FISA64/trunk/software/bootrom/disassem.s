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
DispLS:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_74
	      	mov  	bp,sp
	      	push 	56[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	push 	#disassem_73
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
disassem_75:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_74:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_75
DispRI:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_80
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r3,56[bp]
	      	sh   	r3,-4[bp]
	      	push 	56[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	push 	#disassem_77
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	push 	56[bp]
	      	bsr  	DispRstc
	      	addui	sp,sp,#8
	      	push 	56[bp]
	      	bsr  	DispRac
	      	addui	sp,sp,#8
	      	lw   	r3,40[bp]
	      	beq  	r3,disassem_81
	      	lw   	r3,48[bp]
	      	asli 	r3,r3,#15
	      	lw   	r4,56[bp]
	      	asri 	r4,r4,#17
	      	or   	r3,r3,r4
	      	push 	r3
	      	push 	#disassem_78
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_82
disassem_81:
	      	lh   	r3,-4[bp]
	      	sxh  	r3,r3
	      	sxh  	r3,r3
	      	asri 	r3,r3,#17
	      	push 	r3
	      	push 	#disassem_79
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_82:
disassem_83:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_80:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_83
public code DispBcc:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_86
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	lw   	r3,40[bp]
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#32767
	      	asli 	r3,r3,#2
	      	sw   	r3,-16[bp]
	      	lw   	r3,40[bp]
	      	and  	r3,r3,#-2147483648
	      	beq  	r3,disassem_87
	      	lw   	r3,-16[bp]
	      	ori  	r3,r3,#-65536
	      	sw   	r3,-16[bp]
disassem_87:
	      	push 	40[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	push 	#disassem_84
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	push 	40[bp]
	      	bsr  	DispRac
	      	addui	sp,sp,#8
	      	lw   	r3,24[bp]
	      	lw   	r4,-16[bp]
	      	addu 	r3,r3,r4
	      	push 	r3
	      	push 	#disassem_85
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_89:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_86:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_89
endpublic

public code DispRR:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_91
	      	mov  	bp,sp
	      	push 	40[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	push 	#disassem_90
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	push 	40[bp]
	      	bsr  	DispRstc
	      	addui	sp,sp,#8
	      	push 	40[bp]
	      	bsr  	DispRac
	      	addui	sp,sp,#8
	      	push 	40[bp]
	      	bsr  	DispRb
	      	addui	sp,sp,#8
disassem_92:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_91:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_92
endpublic

public code disassem:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_165
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
disassem_166:
	      	lw   	r3,[r11]
	      	lw   	r4,32[bp]
	      	cmp  	r3,r3,r4
	      	bne  	r3,disassem_168
	      	bsr  	reverse_video
	      	ldi  	r3,#1
	      	sw   	r3,-96[bp]
disassem_168:
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
	      	beq  	r4,disassem_171
	      	cmp  	r4,r3,#2
	      	beq  	r4,disassem_172
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_173
	      	cmp  	r4,r3,#20
	      	beq  	r4,disassem_174
	      	cmp  	r4,r3,#5
	      	beq  	r4,disassem_175
	      	cmp  	r4,r3,#21
	      	beq  	r4,disassem_176
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_177
	      	cmp  	r4,r3,#22
	      	beq  	r4,disassem_178
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_179
	      	cmp  	r4,r3,#23
	      	beq  	r4,disassem_180
	      	cmp  	r4,r3,#8
	      	beq  	r4,disassem_181
	      	cmp  	r4,r3,#24
	      	beq  	r4,disassem_182
	      	cmp  	r4,r3,#12
	      	beq  	r4,disassem_183
	      	cmp  	r4,r3,#13
	      	beq  	r4,disassem_184
	      	cmp  	r4,r3,#14
	      	beq  	r4,disassem_185
	      	cmp  	r4,r3,#61
	      	beq  	r4,disassem_186
	      	cmp  	r4,r3,#57
	      	beq  	r4,disassem_187
	      	cmp  	r4,r3,#58
	      	beq  	r4,disassem_188
	      	cmp  	r4,r3,#55
	      	beq  	r4,disassem_189
	      	cmp  	r4,r3,#59
	      	beq  	r4,disassem_190
	      	cmp  	r4,r3,#64
	      	beq  	r4,disassem_191
	      	cmp  	r4,r3,#65
	      	beq  	r4,disassem_192
	      	cmp  	r4,r3,#66
	      	beq  	r4,disassem_193
	      	cmp  	r4,r3,#67
	      	beq  	r4,disassem_194
	      	cmp  	r4,r3,#68
	      	beq  	r4,disassem_195
	      	cmp  	r4,r3,#69
	      	beq  	r4,disassem_196
	      	cmp  	r4,r3,#70
	      	beq  	r4,disassem_197
	      	cmp  	r4,r3,#96
	      	beq  	r4,disassem_198
	      	cmp  	r4,r3,#97
	      	beq  	r4,disassem_199
	      	cmp  	r4,r3,#98
	      	beq  	r4,disassem_200
	      	cmp  	r4,r3,#99
	      	beq  	r4,disassem_201
	      	cmp  	r4,r3,#92
	      	beq  	r4,disassem_202
	      	cmp  	r4,r3,#110
	      	beq  	r4,disassem_203
	      	cmp  	r4,r3,#103
	      	beq  	r4,disassem_204
	      	cmp  	r4,r3,#87
	      	beq  	r4,disassem_205
	      	cmp  	r4,r3,#63
	      	beq  	r4,disassem_206
	      	cmp  	r4,r3,#10
	      	beq  	r4,disassem_207
	      	bra  	disassem_208
disassem_171:
	      	ldi  	r3,#1
	      	sw   	r3,-40[bp]
	      	lw   	r3,-88[bp]
	      	beq  	r3,disassem_209
	      	lh   	r3,-76[bp]
	      	sxh  	r3,r3
	      	sxh  	r3,r3
	      	asri 	r3,r3,#7
	      	sw   	r3,-48[bp]
	      	lw   	r3,-48[bp]
	      	and  	r3,r3,#16777216
	      	beq  	r3,disassem_211
	      	lw   	r3,-48[bp]
	      	ori  	r3,r3,#-16777216
	      	sw   	r3,-48[bp]
disassem_211:
	      	bra  	disassem_210
disassem_209:
	      	lw   	r3,-48[bp]
	      	asli 	r3,r3,#25
	      	lhu  	r4,-12[bp]
	      	andi 	r4,r4,#-1
	      	asri 	r4,r4,#7
	      	or   	r3,r3,r4
	      	sw   	r3,-48[bp]
disassem_210:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_93
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	sw   	r0,-88[bp]
	      	bra  	disassem_170
disassem_172:
	      	lw   	r3,-32[bp]
	      	cmp  	r4,r3,#55
	      	beq  	r4,disassem_214
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_215
	      	cmp  	r4,r3,#20
	      	beq  	r4,disassem_216
	      	cmp  	r4,r3,#5
	      	beq  	r4,disassem_217
	      	cmp  	r4,r3,#21
	      	beq  	r4,disassem_218
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_219
	      	cmp  	r4,r3,#22
	      	beq  	r4,disassem_220
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_221
	      	cmp  	r4,r3,#23
	      	beq  	r4,disassem_222
	      	cmp  	r4,r3,#8
	      	beq  	r4,disassem_223
	      	cmp  	r4,r3,#24
	      	beq  	r4,disassem_224
	      	cmp  	r4,r3,#12
	      	beq  	r4,disassem_225
	      	cmp  	r4,r3,#13
	      	beq  	r4,disassem_226
	      	cmp  	r4,r3,#14
	      	beq  	r4,disassem_227
	      	cmp  	r4,r3,#31
	      	beq  	r4,disassem_228
	      	cmp  	r4,r3,#30
	      	beq  	r4,disassem_229
	      	bra  	disassem_213
disassem_214:
	      	lhu  	r3,-12[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#31
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_231
	      	cmp  	r4,r3,#1
	      	beq  	r4,disassem_232
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_233
	      	cmp  	r4,r3,#29
	      	beq  	r4,disassem_234
	      	cmp  	r4,r3,#30
	      	beq  	r4,disassem_235
	      	cmp  	r4,r3,#31
	      	beq  	r4,disassem_236
	      	bra  	disassem_237
disassem_231:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_94
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_230
disassem_232:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_95
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_230
disassem_233:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_96
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_230
disassem_234:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_97
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_230
disassem_235:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_98
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_230
disassem_236:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_99
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_230
disassem_237:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_100
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_230
disassem_230:
	      	bra  	disassem_213
disassem_215:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_101
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_213
disassem_216:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_102
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_213
disassem_217:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_103
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_213
disassem_218:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_104
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_213
disassem_219:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_105
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_213
disassem_220:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_106
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_213
disassem_221:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_107
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_213
disassem_222:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_108
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_213
disassem_223:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_109
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_213
disassem_224:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_110
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_213
disassem_225:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_111
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_213
disassem_226:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_112
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_213
disassem_227:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_113
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_213
disassem_228:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_114
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
	      	push 	#disassem_115
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_213
disassem_229:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_116
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispSpr
	      	addui	sp,sp,#8
	      	push 	#disassem_117
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRa
	      	addui	sp,sp,#8
	      	push 	#disassem_118
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_213
disassem_213:
	      	bra  	disassem_170
disassem_173:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_119
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_174:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_120
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_175:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_121
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_176:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_122
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_177:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_123
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_178:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_124
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_179:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_125
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_180:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_126
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_181:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_127
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_182:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_128
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_183:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_129
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_184:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_130
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_185:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_131
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_186:
	      	lhu  	r3,-12[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#12
	      	and  	r3,r3,#7
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_239
	      	cmp  	r4,r3,#1
	      	beq  	r4,disassem_240
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_241
	      	cmp  	r4,r3,#5
	      	beq  	r4,disassem_242
	      	cmp  	r4,r3,#2
	      	beq  	r4,disassem_243
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_244
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_245
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_245
	      	bra  	disassem_238
disassem_239:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_132
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_238
disassem_240:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_133
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_238
disassem_241:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_134
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_238
disassem_242:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_135
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_238
disassem_243:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_136
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_238
disassem_244:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_137
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_238
disassem_245:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_138
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_238
disassem_238:
	      	bra  	disassem_170
disassem_187:
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
	      	beq  	r3,disassem_246
	      	lw   	r3,-64[bp]
	      	ori  	r3,r3,#-16777216
	      	sw   	r3,-64[bp]
disassem_246:
	      	lw   	r3,[r11]
	      	lw   	r4,-64[bp]
	      	asli 	r4,r4,#2
	      	addu 	r3,r3,r4
	      	sw   	r3,-56[bp]
	      	push 	-56[bp]
	      	push 	#disassem_139
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_170
disassem_188:
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
	      	beq  	r3,disassem_248
	      	lw   	r3,-64[bp]
	      	ori  	r3,r3,#-16777216
	      	sw   	r3,-64[bp]
disassem_248:
	      	lw   	r3,[r11]
	      	lw   	r4,-64[bp]
	      	asli 	r4,r4,#2
	      	addu 	r3,r3,r4
	      	sw   	r3,-56[bp]
	      	push 	-56[bp]
	      	push 	#disassem_140
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_170
disassem_189:
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
	      	push 	#disassem_141
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_170
disassem_190:
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
	      	push 	#disassem_142
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_170
disassem_191:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_143
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_192:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_144
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_193:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_145
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_194:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_146
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_195:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_147
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_196:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_148
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_197:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_149
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_198:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_150
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_199:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_151
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_200:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_152
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_201:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_153
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_202:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_154
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_203:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_155
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_170
disassem_204:
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
	      	bsr  	DispRa
	      	addui	sp,sp,#8
	      	push 	#disassem_157
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_170
disassem_205:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_158
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRst
	      	addui	sp,sp,#8
	      	push 	#disassem_159
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_170
disassem_206:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_160
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_170
disassem_207:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_161
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRstc
	      	addui	sp,sp,#8
	      	lw   	r3,-40[bp]
	      	beq  	r3,disassem_250
	      	lw   	r3,-48[bp]
	      	asli 	r3,r3,#15
	      	lhu  	r4,-12[bp]
	      	andi 	r4,r4,#-1
	      	asri 	r4,r4,#17
	      	or   	r3,r3,r4
	      	push 	r3
	      	push 	#disassem_162
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_251
disassem_250:
	      	lh   	r3,-76[bp]
	      	sxh  	r3,r3
	      	sxh  	r3,r3
	      	asri 	r3,r3,#17
	      	push 	r3
	      	push 	#disassem_163
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_251:
	      	bra  	disassem_170
disassem_208:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_164
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_170
disassem_170:
	      	lw   	r3,[r11]
	      	addu 	r3,r3,#4
	      	sw   	r3,[r11]
	      	lw   	r3,-96[bp]
	      	beq  	r3,disassem_252
	      	bsr  	reverse_video
	      	sw   	r0,-96[bp]
disassem_252:
	      	lw   	r3,-24[bp]
	      	cmp  	r3,r3,#124
	      	beq  	r3,disassem_166
disassem_167:
disassem_254:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_165:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_254
endpublic

public code disassem20:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_256
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	#disassem_255
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	sw   	r0,-8[bp]
disassem_257:
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#16
	      	bge  	r3,disassem_258
	      	push 	32[bp]
	      	pea  	24[bp]
	      	bsr  	disassem
	      	addui	sp,sp,#16
disassem_259:
	      	inc  	-8[bp],#1
	      	bra  	disassem_257
disassem_258:
disassem_260:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_256:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_260
endpublic

	rodata
	align	16
	align	8
disassem_255:	; Disassem:

	dc	68,105,115,97,115,115,101,109
	dc	58,13,10,0
disassem_164:	; ?????

	dc	63,63,63,63,63,13,10,0
disassem_163:	; #$%X

	dc	35,36,37,88,13,10,0
disassem_162:	; #$%X

	dc	35,36,37,88,13,10,0
disassem_161:	; LDI   
	dc	76,68,73,32,32,32,0
disassem_160:	; NOP

	dc	78,79,80,13,10,0
disassem_159:	; 

	dc	13,10,0
disassem_158:	; POP   
	dc	80,79,80,32,32,32,0
disassem_157:	; 

	dc	13,10,0
disassem_156:	; PUSH  
	dc	80,85,83,72,32,32,0
disassem_155:	; SWCR 
	dc	83,87,67,82,32,0
disassem_154:	; LWAR 
	dc	76,87,65,82,32,0
disassem_153:	; SW   
	dc	83,87,32,32,32,0
disassem_152:	; SH   
	dc	83,72,32,32,32,0
disassem_151:	; SC   
	dc	83,67,32,32,32,0
disassem_150:	; SB   
	dc	83,66,32,32,32,0
disassem_149:	; LW   
	dc	76,87,32,32,32,0
disassem_148:	; LHU  
	dc	76,72,85,32,32,0
disassem_147:	; LH   
	dc	76,72,32,32,32,0
disassem_146:	; LCU  
	dc	76,67,85,32,32,0
disassem_145:	; LC   
	dc	76,67,32,32,32,0
disassem_144:	; LBU  
	dc	76,66,85,32,32,0
disassem_143:	; LB   
	dc	76,66,32,32,32,0
disassem_142:	; RTS   #%X

	dc	82,84,83,32,32,32,35,37
	dc	88,13,10,0
disassem_141:	; RTL   #%X

	dc	82,84,76,32,32,32,35,37
	dc	88,13,10,0
disassem_140:	; BRA   $%X

	dc	66,82,65,32,32,32,36,37
	dc	88,13,10,0
disassem_139:	; BSR   $%X

	dc	66,83,82,32,32,32,36,37
	dc	88,13,10,0
disassem_138:	; ???  
	dc	63,63,63,32,32,0
disassem_137:	; BGE  
	dc	66,71,69,32,32,0
disassem_136:	; BGT  
	dc	66,71,84,32,32,0
disassem_135:	; BLE  
	dc	66,76,69,32,32,0
disassem_134:	; BLT  
	dc	66,76,84,32,32,0
disassem_133:	; BNE  
	dc	66,78,69,32,32,0
disassem_132:	; BEQ  
	dc	66,69,81,32,32,0
disassem_131:	; EOR  
	dc	69,79,82,32,32,0
disassem_130:	; OR   
	dc	79,82,32,32,32,0
disassem_129:	; AND  
	dc	65,78,68,32,32,0
disassem_128:	; DIVU 
	dc	68,73,86,85,32,0
disassem_127:	; DIV  
	dc	68,73,86,32,32,0
disassem_126:	; MULU 
	dc	77,85,76,85,32,0
disassem_125:	; MUL  
	dc	77,85,76,32,32,0
disassem_124:	; CMPU 
	dc	67,77,80,85,32,0
disassem_123:	; CMP  
	dc	67,77,80,32,32,0
disassem_122:	; SUBU 
	dc	83,85,66,85,32,0
disassem_121:	; SUB  
	dc	83,85,66,32,32,0
disassem_120:	; ADDU 
	dc	65,68,68,85,32,0
disassem_119:	; ADD  
	dc	65,68,68,32,32,0
disassem_118:	; 

	dc	13,10,0
disassem_117:	; ,
	dc	44,0
disassem_116:	; MTSPR 
	dc	77,84,83,80,82,32,0
disassem_115:	; 

	dc	13,10,0
disassem_114:	; MFSPR 
	dc	77,70,83,80,82,32,0
disassem_113:	; EOR  
	dc	69,79,82,32,32,0
disassem_112:	; OR   
	dc	79,82,32,32,32,0
disassem_111:	; AND  
	dc	65,78,68,32,32,0
disassem_110:	; DIVU 
	dc	68,73,86,85,32,0
disassem_109:	; DIV  
	dc	68,73,86,32,32,0
disassem_108:	; MULU 
	dc	77,85,76,85,32,0
disassem_107:	; MUL  
	dc	77,85,76,32,32,0
disassem_106:	; CMPU 
	dc	67,77,80,85,32,0
disassem_105:	; CMP  
	dc	67,77,80,32,32,0
disassem_104:	; SUBU 
	dc	83,85,66,85,32,0
disassem_103:	; SUB  
	dc	83,85,66,32,32,0
disassem_102:	; ADDU 
	dc	65,68,68,85,32,0
disassem_101:	; ADD  
	dc	65,68,68,32,32,0
disassem_100:	; ???

	dc	63,63,63,13,10,0
disassem_99:	; RTI

	dc	82,84,73,13,10,0
disassem_98:	; RTE

	dc	82,84,69,13,10,0
disassem_97:	; RTD

	dc	82,84,68,13,10,0
disassem_96:	; WAI

	dc	87,65,73,13,10,0
disassem_95:	; SEI

	dc	83,69,73,13,10,0
disassem_94:	; CLI

	dc	67,76,73,13,10,0
disassem_93:	; IMM

	dc	73,77,77,13,10,0
disassem_90:	; %s 
	dc	37,115,32,0
disassem_85:	; %06X

	dc	37,48,54,88,13,10,0
disassem_84:	; %s 
	dc	37,115,32,0
disassem_79:	; #$%X

	dc	35,36,37,88,13,10,0
disassem_78:	; #$%X

	dc	35,36,37,88,13,10,0
disassem_77:	; %s 
	dc	37,115,32,0
disassem_73:	; %s 
	dc	37,115,32,0
disassem_65:	; 

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
disassem_24:	; R%d,
	dc	82,37,100,44,0
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
