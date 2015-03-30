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
	      	ldi  	xlr,#disassem_42
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r3,24[bp]
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#255
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_44
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_45
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_46
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_47
	      	cmp  	r4,r3,#8
	      	beq  	r4,disassem_48
	      	cmp  	r4,r3,#9
	      	beq  	r4,disassem_49
	      	cmp  	r4,r3,#10
	      	beq  	r4,disassem_50
	      	cmp  	r4,r3,#50
	      	beq  	r4,disassem_51
	      	cmp  	r4,r3,#51
	      	beq  	r4,disassem_52
	      	cmp  	r4,r3,#52
	      	beq  	r4,disassem_53
	      	cmp  	r4,r3,#53
	      	beq  	r4,disassem_54
	      	cmp  	r4,r3,#54
	      	beq  	r4,disassem_55
	      	cmp  	r4,r3,#55
	      	beq  	r4,disassem_56
	      	bra  	disassem_57
disassem_44:
	      	push 	#disassem_28
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_43
disassem_45:
	      	push 	#disassem_29
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_43
disassem_46:
	      	push 	#disassem_30
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_43
disassem_47:
	      	push 	#disassem_31
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_43
disassem_48:
	      	push 	#disassem_32
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_43
disassem_49:
	      	push 	#disassem_33
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_43
disassem_50:
	      	push 	#disassem_34
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_43
disassem_51:
	      	push 	#disassem_35
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_43
disassem_52:
	      	push 	#disassem_36
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_43
disassem_53:
	      	push 	#disassem_37
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_43
disassem_54:
	      	push 	#disassem_38
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_43
disassem_55:
	      	push 	#disassem_39
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_43
disassem_56:
	      	push 	#disassem_40
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_43
disassem_57:
	      	push 	-8[bp]
	      	push 	#disassem_41
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_43:
disassem_58:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_42:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_58
DispMemAddress:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_64
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r3,40[bp]
	      	sh   	r3,-4[bp]
	      	lw   	r3,24[bp]
	      	beq  	r3,disassem_65
	      	lw   	r3,32[bp]
	      	asli 	r3,r3,#15
	      	lw   	r4,40[bp]
	      	asri 	r4,r4,#17
	      	or   	r3,r3,r4
	      	push 	r3
	      	push 	#disassem_60
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_66
disassem_65:
	      	lh   	r3,-4[bp]
	      	sxh  	r3,r3
	      	sxh  	r3,r3
	      	asri 	r3,r3,#17
	      	push 	r3
	      	push 	#disassem_61
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_66:
	      	lw   	r3,40[bp]
	      	asri 	r3,r3,#7
	      	and  	r3,r3,#31
	      	beq  	r3,disassem_67
	      	lw   	r3,40[bp]
	      	asri 	r3,r3,#7
	      	and  	r3,r3,#31
	      	push 	r3
	      	push 	#disassem_62
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_68
disassem_67:
	      	push 	#disassem_63
	      	bsr  	printf
	      	addui	sp,sp,#8
disassem_68:
disassem_69:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_64:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_69
DispLS:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_72
	      	mov  	bp,sp
	      	push 	56[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	push 	#disassem_71
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
disassem_73:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_72:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_73
DispRI:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_78
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r3,56[bp]
	      	sh   	r3,-4[bp]
	      	push 	56[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	push 	#disassem_75
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	push 	56[bp]
	      	bsr  	DispRstc
	      	addui	sp,sp,#8
	      	push 	56[bp]
	      	bsr  	DispRac
	      	addui	sp,sp,#8
	      	lw   	r3,40[bp]
	      	beq  	r3,disassem_79
	      	lw   	r3,48[bp]
	      	asli 	r3,r3,#15
	      	lw   	r4,56[bp]
	      	asri 	r4,r4,#17
	      	or   	r3,r3,r4
	      	push 	r3
	      	push 	#disassem_76
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_80
disassem_79:
	      	lh   	r3,-4[bp]
	      	sxh  	r3,r3
	      	sxh  	r3,r3
	      	asri 	r3,r3,#17
	      	push 	r3
	      	push 	#disassem_77
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_80:
disassem_81:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_78:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_81
public code DispBcc:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_84
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	lw   	r3,40[bp]
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#32767
	      	asli 	r3,r3,#2
	      	sw   	r3,-16[bp]
	      	lw   	r3,40[bp]
	      	and  	r3,r3,#-2147483648
	      	beq  	r3,disassem_85
	      	lw   	r3,-16[bp]
	      	ori  	r3,r3,#-65536
	      	sw   	r3,-16[bp]
disassem_85:
	      	push 	40[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	push 	#disassem_82
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	push 	40[bp]
	      	bsr  	DispRac
	      	addui	sp,sp,#8
	      	lw   	r3,24[bp]
	      	lw   	r4,-16[bp]
	      	addu 	r3,r3,r4
	      	push 	r3
	      	push 	#disassem_83
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_87:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_84:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_87
endpublic

public code DispRR:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_89
	      	mov  	bp,sp
	      	push 	40[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	push 	#disassem_88
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
disassem_90:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_89:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_90
endpublic

public code disassem:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_163
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
disassem_164:
	      	lw   	r3,[r11]
	      	lw   	r4,32[bp]
	      	cmp  	r3,r3,r4
	      	bne  	r3,disassem_166
	      	bsr  	reverse_video
	      	ldi  	r3,#1
	      	sw   	r3,-96[bp]
disassem_166:
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
	      	beq  	r4,disassem_169
	      	cmp  	r4,r3,#2
	      	beq  	r4,disassem_170
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_171
	      	cmp  	r4,r3,#20
	      	beq  	r4,disassem_172
	      	cmp  	r4,r3,#5
	      	beq  	r4,disassem_173
	      	cmp  	r4,r3,#21
	      	beq  	r4,disassem_174
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_175
	      	cmp  	r4,r3,#22
	      	beq  	r4,disassem_176
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_177
	      	cmp  	r4,r3,#23
	      	beq  	r4,disassem_178
	      	cmp  	r4,r3,#8
	      	beq  	r4,disassem_179
	      	cmp  	r4,r3,#24
	      	beq  	r4,disassem_180
	      	cmp  	r4,r3,#12
	      	beq  	r4,disassem_181
	      	cmp  	r4,r3,#13
	      	beq  	r4,disassem_182
	      	cmp  	r4,r3,#14
	      	beq  	r4,disassem_183
	      	cmp  	r4,r3,#61
	      	beq  	r4,disassem_184
	      	cmp  	r4,r3,#57
	      	beq  	r4,disassem_185
	      	cmp  	r4,r3,#58
	      	beq  	r4,disassem_186
	      	cmp  	r4,r3,#55
	      	beq  	r4,disassem_187
	      	cmp  	r4,r3,#59
	      	beq  	r4,disassem_188
	      	cmp  	r4,r3,#64
	      	beq  	r4,disassem_189
	      	cmp  	r4,r3,#65
	      	beq  	r4,disassem_190
	      	cmp  	r4,r3,#66
	      	beq  	r4,disassem_191
	      	cmp  	r4,r3,#67
	      	beq  	r4,disassem_192
	      	cmp  	r4,r3,#68
	      	beq  	r4,disassem_193
	      	cmp  	r4,r3,#69
	      	beq  	r4,disassem_194
	      	cmp  	r4,r3,#70
	      	beq  	r4,disassem_195
	      	cmp  	r4,r3,#96
	      	beq  	r4,disassem_196
	      	cmp  	r4,r3,#97
	      	beq  	r4,disassem_197
	      	cmp  	r4,r3,#98
	      	beq  	r4,disassem_198
	      	cmp  	r4,r3,#99
	      	beq  	r4,disassem_199
	      	cmp  	r4,r3,#92
	      	beq  	r4,disassem_200
	      	cmp  	r4,r3,#110
	      	beq  	r4,disassem_201
	      	cmp  	r4,r3,#103
	      	beq  	r4,disassem_202
	      	cmp  	r4,r3,#87
	      	beq  	r4,disassem_203
	      	cmp  	r4,r3,#63
	      	beq  	r4,disassem_204
	      	cmp  	r4,r3,#10
	      	beq  	r4,disassem_205
	      	bra  	disassem_206
disassem_169:
	      	ldi  	r3,#1
	      	sw   	r3,-40[bp]
	      	lw   	r3,-88[bp]
	      	beq  	r3,disassem_207
	      	lh   	r3,-76[bp]
	      	sxh  	r3,r3
	      	sxh  	r3,r3
	      	asri 	r3,r3,#7
	      	sw   	r3,-48[bp]
	      	lw   	r3,-48[bp]
	      	and  	r3,r3,#16777216
	      	beq  	r3,disassem_209
	      	lw   	r3,-48[bp]
	      	ori  	r3,r3,#-16777216
	      	sw   	r3,-48[bp]
disassem_209:
	      	bra  	disassem_208
disassem_207:
	      	lw   	r3,-48[bp]
	      	asli 	r3,r3,#25
	      	lhu  	r4,-12[bp]
	      	andi 	r4,r4,#-1
	      	asri 	r4,r4,#7
	      	or   	r3,r3,r4
	      	sw   	r3,-48[bp]
disassem_208:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_91
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	sw   	r0,-88[bp]
	      	bra  	disassem_168
disassem_170:
	      	lw   	r3,-32[bp]
	      	cmp  	r4,r3,#55
	      	beq  	r4,disassem_212
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_213
	      	cmp  	r4,r3,#20
	      	beq  	r4,disassem_214
	      	cmp  	r4,r3,#5
	      	beq  	r4,disassem_215
	      	cmp  	r4,r3,#21
	      	beq  	r4,disassem_216
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_217
	      	cmp  	r4,r3,#22
	      	beq  	r4,disassem_218
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_219
	      	cmp  	r4,r3,#23
	      	beq  	r4,disassem_220
	      	cmp  	r4,r3,#8
	      	beq  	r4,disassem_221
	      	cmp  	r4,r3,#24
	      	beq  	r4,disassem_222
	      	cmp  	r4,r3,#12
	      	beq  	r4,disassem_223
	      	cmp  	r4,r3,#13
	      	beq  	r4,disassem_224
	      	cmp  	r4,r3,#14
	      	beq  	r4,disassem_225
	      	cmp  	r4,r3,#31
	      	beq  	r4,disassem_226
	      	cmp  	r4,r3,#30
	      	beq  	r4,disassem_227
	      	bra  	disassem_211
disassem_212:
	      	lhu  	r3,-12[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#31
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_229
	      	cmp  	r4,r3,#1
	      	beq  	r4,disassem_230
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_231
	      	cmp  	r4,r3,#29
	      	beq  	r4,disassem_232
	      	cmp  	r4,r3,#30
	      	beq  	r4,disassem_233
	      	cmp  	r4,r3,#31
	      	beq  	r4,disassem_234
	      	bra  	disassem_235
disassem_229:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_92
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_228
disassem_230:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_93
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_228
disassem_231:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_94
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_228
disassem_232:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_95
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_228
disassem_233:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_96
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_228
disassem_234:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_97
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_228
disassem_235:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_98
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_228
disassem_228:
	      	bra  	disassem_211
disassem_213:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_99
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_211
disassem_214:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_100
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_211
disassem_215:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_101
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_211
disassem_216:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_102
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_211
disassem_217:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_103
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_211
disassem_218:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_104
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_211
disassem_219:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_105
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_211
disassem_220:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_106
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_211
disassem_221:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_107
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_211
disassem_222:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_108
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_211
disassem_223:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_109
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_211
disassem_224:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_110
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_211
disassem_225:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_111
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_211
disassem_226:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_112
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
	      	push 	#disassem_113
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_211
disassem_227:
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
	      	bsr  	DispSpr
	      	addui	sp,sp,#8
	      	push 	#disassem_115
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRa
	      	addui	sp,sp,#8
	      	push 	#disassem_116
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_211
disassem_211:
	      	bra  	disassem_168
disassem_171:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_117
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_172:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_118
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_173:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_119
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_174:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_120
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_175:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_121
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_176:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_122
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_177:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_123
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_178:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_124
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_179:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_125
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_180:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_126
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_181:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_127
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_182:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_128
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_183:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_129
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_184:
	      	lhu  	r3,-12[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#12
	      	and  	r3,r3,#7
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_237
	      	cmp  	r4,r3,#1
	      	beq  	r4,disassem_238
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_239
	      	cmp  	r4,r3,#5
	      	beq  	r4,disassem_240
	      	cmp  	r4,r3,#2
	      	beq  	r4,disassem_241
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_242
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_243
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_243
	      	bra  	disassem_236
disassem_237:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_130
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_236
disassem_238:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_131
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_236
disassem_239:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_132
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_236
disassem_240:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_133
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_236
disassem_241:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_134
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_236
disassem_242:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_135
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_236
disassem_243:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_136
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_236
disassem_236:
	      	bra  	disassem_168
disassem_185:
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
	      	beq  	r3,disassem_244
	      	lw   	r3,-64[bp]
	      	ori  	r3,r3,#-16777216
	      	sw   	r3,-64[bp]
disassem_244:
	      	lw   	r3,-64[bp]
	      	asli 	r3,r3,#2
	      	asli 	r3,r3,#3
	      	addu 	r11,r11,r3
	      	sw   	r11,-56[bp]
	      	push 	-56[bp]
	      	push 	#disassem_137
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_168
disassem_186:
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
	      	lw   	r3,-64[bp]
	      	asli 	r3,r3,#2
	      	asli 	r3,r3,#3
	      	addu 	r11,r11,r3
	      	sw   	r11,-56[bp]
	      	push 	-56[bp]
	      	push 	#disassem_138
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_168
disassem_187:
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
	      	push 	#disassem_139
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_168
disassem_188:
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
	      	push 	#disassem_140
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_168
disassem_189:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_141
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_190:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_142
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_191:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_143
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_192:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_144
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_193:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_145
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_194:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_146
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_195:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_147
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_196:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_148
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_197:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_149
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_198:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_150
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_199:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_151
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_200:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_152
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_201:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_153
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_168
disassem_202:
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
	      	bsr  	DispRa
	      	addui	sp,sp,#8
	      	push 	#disassem_155
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_168
disassem_203:
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
	      	bsr  	DispRst
	      	addui	sp,sp,#8
	      	push 	#disassem_157
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_168
disassem_204:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_158
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_168
disassem_205:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_159
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRstc
	      	addui	sp,sp,#8
	      	lw   	r3,-40[bp]
	      	beq  	r3,disassem_248
	      	lw   	r3,-48[bp]
	      	asli 	r3,r3,#15
	      	lhu  	r4,-12[bp]
	      	andi 	r4,r4,#-1
	      	asri 	r4,r4,#17
	      	or   	r3,r3,r4
	      	push 	r3
	      	push 	#disassem_160
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_249
disassem_248:
	      	lh   	r3,-76[bp]
	      	sxh  	r3,r3
	      	sxh  	r3,r3
	      	asri 	r3,r3,#17
	      	push 	r3
	      	push 	#disassem_161
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_249:
	      	bra  	disassem_168
disassem_206:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_162
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_168
disassem_168:
	      	lw   	r3,[r11]
	      	addu 	r3,r3,#4
	      	sw   	r3,[r11]
	      	lw   	r3,-96[bp]
	      	beq  	r3,disassem_250
	      	bsr  	reverse_video
	      	sw   	r0,-96[bp]
disassem_250:
	      	lw   	r3,-24[bp]
	      	cmp  	r3,r3,#124
	      	beq  	r3,disassem_164
disassem_165:
disassem_252:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_163:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_252
endpublic

public code disassem20:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_254
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	#disassem_253
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	sw   	r0,-8[bp]
disassem_255:
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#16
	      	bge  	r3,disassem_256
	      	push 	32[bp]
	      	pea  	24[bp]
	      	bsr  	disassem
	      	addui	sp,sp,#16
disassem_257:
	      	inc  	-8[bp],#1
	      	bra  	disassem_255
disassem_256:
disassem_258:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_254:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_258
endpublic

	rodata
	align	16
	align	8
disassem_253:	; Disassem:

	dc	68,105,115,97,115,115,101,109
	dc	58,13,10,0
disassem_162:	; ????? 

	dc	63,63,63,63,63,32,13,10
	dc	0
disassem_161:	; #$%X

	dc	35,36,37,88,13,10,0
disassem_160:	; #$%X

	dc	35,36,37,88,13,10,0
disassem_159:	; LDI   
	dc	76,68,73,32,32,32,0
disassem_158:	; NOP   

	dc	78,79,80,32,32,32,13,10
	dc	0
disassem_157:	; 

	dc	13,10,0
disassem_156:	; POP   
	dc	80,79,80,32,32,32,0
disassem_155:	; 

	dc	13,10,0
disassem_154:	; PUSH  
	dc	80,85,83,72,32,32,0
disassem_153:	; SWCR  
	dc	83,87,67,82,32,32,0
disassem_152:	; LWAR  
	dc	76,87,65,82,32,32,0
disassem_151:	; SW    
	dc	83,87,32,32,32,32,0
disassem_150:	; SH    
	dc	83,72,32,32,32,32,0
disassem_149:	; SC    
	dc	83,67,32,32,32,32,0
disassem_148:	; SB    
	dc	83,66,32,32,32,32,0
disassem_147:	; LW    
	dc	76,87,32,32,32,32,0
disassem_146:	; LHU   
	dc	76,72,85,32,32,32,0
disassem_145:	; LH    
	dc	76,72,32,32,32,32,0
disassem_144:	; LCU   
	dc	76,67,85,32,32,32,0
disassem_143:	; LC    
	dc	76,67,32,32,32,32,0
disassem_142:	; LBU   
	dc	76,66,85,32,32,32,0
disassem_141:	; LB    
	dc	76,66,32,32,32,32,0
disassem_140:	; RTS   #%X

	dc	82,84,83,32,32,32,35,37
	dc	88,13,10,0
disassem_139:	; RTL   #%X

	dc	82,84,76,32,32,32,35,37
	dc	88,13,10,0
disassem_138:	; BRA   $%X

	dc	66,82,65,32,32,32,36,37
	dc	88,13,10,0
disassem_137:	; BSR   $%X

	dc	66,83,82,32,32,32,36,37
	dc	88,13,10,0
disassem_136:	; ???   
	dc	63,63,63,32,32,32,0
disassem_135:	; BGE   
	dc	66,71,69,32,32,32,0
disassem_134:	; BGT   
	dc	66,71,84,32,32,32,0
disassem_133:	; BLE   
	dc	66,76,69,32,32,32,0
disassem_132:	; BLT   
	dc	66,76,84,32,32,32,0
disassem_131:	; BNE   
	dc	66,78,69,32,32,32,0
disassem_130:	; BEQ   
	dc	66,69,81,32,32,32,0
disassem_129:	; EOR   
	dc	69,79,82,32,32,32,0
disassem_128:	; OR    
	dc	79,82,32,32,32,32,0
disassem_127:	; AND   
	dc	65,78,68,32,32,32,0
disassem_126:	; DIVU  
	dc	68,73,86,85,32,32,0
disassem_125:	; DIV   
	dc	68,73,86,32,32,32,0
disassem_124:	; MULU  
	dc	77,85,76,85,32,32,0
disassem_123:	; MUL   
	dc	77,85,76,32,32,32,0
disassem_122:	; CMPU  
	dc	67,77,80,85,32,32,0
disassem_121:	; CMP   
	dc	67,77,80,32,32,32,0
disassem_120:	; SUBU  
	dc	83,85,66,85,32,32,0
disassem_119:	; SUB   
	dc	83,85,66,32,32,32,0
disassem_118:	; ADDU  
	dc	65,68,68,85,32,32,0
disassem_117:	; ADD   
	dc	65,68,68,32,32,32,0
disassem_116:	; 

	dc	13,10,0
disassem_115:	; ,
	dc	44,0
disassem_114:	; MTSPR 
	dc	77,84,83,80,82,32,0
disassem_113:	; 

	dc	13,10,0
disassem_112:	; MFSPR 
	dc	77,70,83,80,82,32,0
disassem_111:	; EOR   
	dc	69,79,82,32,32,32,0
disassem_110:	; OR    
	dc	79,82,32,32,32,32,0
disassem_109:	; AND   
	dc	65,78,68,32,32,32,0
disassem_108:	; DIVU  
	dc	68,73,86,85,32,32,0
disassem_107:	; DIV   
	dc	68,73,86,32,32,32,0
disassem_106:	; MULU  
	dc	77,85,76,85,32,32,0
disassem_105:	; MUL   
	dc	77,85,76,32,32,32,0
disassem_104:	; CMPU  
	dc	67,77,80,85,32,32,0
disassem_103:	; CMP   
	dc	67,77,80,32,32,32,0
disassem_102:	; SUBU  
	dc	83,85,66,85,32,32,0
disassem_101:	; SUB   
	dc	83,85,66,32,32,32,0
disassem_100:	; ADDU  
	dc	65,68,68,85,32,32,0
disassem_99:	; ADD   
	dc	65,68,68,32,32,32,0
disassem_98:	; ???

	dc	63,63,63,13,10,0
disassem_97:	; RTI

	dc	82,84,73,13,10,0
disassem_96:	; RTE

	dc	82,84,69,13,10,0
disassem_95:	; RTD

	dc	82,84,68,13,10,0
disassem_94:	; WAI

	dc	87,65,73,13,10,0
disassem_93:	; SEI

	dc	83,69,73,13,10,0
disassem_92:	; CLI

	dc	67,76,73,13,10,0
disassem_91:	; IMM

	dc	73,77,77,13,10,0
disassem_88:	; %s 
	dc	37,115,32,0
disassem_83:	; %06X

	dc	37,48,54,88,13,10,0
disassem_82:	; %s 
	dc	37,115,32,0
disassem_77:	; #$%X

	dc	35,36,37,88,13,10,0
disassem_76:	; #$%X

	dc	35,36,37,88,13,10,0
disassem_75:	; %s 
	dc	37,115,32,0
disassem_71:	; %s 
	dc	37,115,32,0
disassem_63:	; 

	dc	13,10,0
disassem_62:	; [R%d]

	dc	91,82,37,100,93,13,10,0
disassem_61:	; $%x
	dc	36,37,120,0
disassem_60:	; $%X
	dc	36,37,88,0
disassem_41:	; SPR%d
	dc	83,80,82,37,100,0
disassem_40:	; DBSTAT
	dc	68,66,83,84,65,84,0
disassem_39:	; DBCTRL
	dc	68,66,67,84,82,76,0
disassem_38:	; DBAD3
	dc	68,66,65,68,51,0
disassem_37:	; DBAD2
	dc	68,66,65,68,50,0
disassem_36:	; DBAD1
	dc	68,66,65,68,49,0
disassem_35:	; DBAD0
	dc	68,66,65,68,48,0
disassem_34:	; VBR
	dc	86,66,82,0
disassem_33:	; EPC
	dc	69,80,67,0
disassem_32:	; IPC
	dc	73,80,67,0
disassem_31:	; DPC
	dc	68,80,67,0
disassem_30:	; CLK
	dc	67,76,75,0
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
