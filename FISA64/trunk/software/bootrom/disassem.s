	code
	align	16
public code DumpInsnBytes:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_1
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
	      	push 	#disassem_0
	      	bsr  	printf
	      	addui	sp,sp,#48
disassem_2:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_1:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_2
endpublic

DispRst:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_5
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	asri 	r3,r3,#12
	      	and  	r3,r3,#31
	      	push 	r3
	      	push 	#disassem_4
	      	bsr  	printf
	      	addui	sp,sp,#16
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
DispRstc:
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
DispRac:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_13
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	asri 	r3,r3,#7
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
DispRa:
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
DispRb:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_21
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	asri 	r3,r3,#17
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
DispSpr:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_36
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r3,24[bp]
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#255
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_38
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_39
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_40
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_41
	      	cmp  	r4,r3,#8
	      	beq  	r4,disassem_42
	      	cmp  	r4,r3,#9
	      	beq  	r4,disassem_43
	      	cmp  	r4,r3,#10
	      	beq  	r4,disassem_44
	      	cmp  	r4,r3,#50
	      	beq  	r4,disassem_45
	      	cmp  	r4,r3,#51
	      	beq  	r4,disassem_46
	      	cmp  	r4,r3,#52
	      	beq  	r4,disassem_47
	      	cmp  	r4,r3,#53
	      	beq  	r4,disassem_48
	      	bra  	disassem_49
disassem_38:
	      	push 	#disassem_24
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_37
disassem_39:
	      	push 	#disassem_25
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_37
disassem_40:
	      	push 	#disassem_26
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_37
disassem_41:
	      	push 	#disassem_27
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_37
disassem_42:
	      	push 	#disassem_28
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_37
disassem_43:
	      	push 	#disassem_29
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_37
disassem_44:
	      	push 	#disassem_30
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_37
disassem_45:
	      	push 	#disassem_31
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_37
disassem_46:
	      	push 	#disassem_32
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_37
disassem_47:
	      	push 	#disassem_33
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_37
disassem_48:
	      	push 	#disassem_34
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_37
disassem_49:
	      	push 	-8[bp]
	      	push 	#disassem_35
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_37:
disassem_50:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_36:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_50
DispMemAddress:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_55
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r3,40[bp]
	      	sh   	r3,-4[bp]
	      	lw   	r3,24[bp]
	      	beq  	r3,disassem_56
	      	lw   	r3,32[bp]
	      	lw   	r4,40[bp]
	      	asri 	r4,r4,#17
	      	or   	r3,r3,r4
	      	push 	r3
	      	push 	#disassem_52
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_57
disassem_56:
	      	lh   	r3,-4[bp]
	      	sxh  	r3,r3
	      	sxh  	r3,r3
	      	asri 	r3,r3,#17
	      	push 	r3
	      	push 	#disassem_53
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_57:
	      	lw   	r3,40[bp]
	      	asri 	r3,r3,#7
	      	and  	r3,r3,#31
	      	beq  	r3,disassem_58
	      	lw   	r3,40[bp]
	      	asri 	r3,r3,#7
	      	and  	r3,r3,#31
	      	push 	r3
	      	push 	#disassem_54
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_58:
disassem_60:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_55:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_60
DispLS:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_63
	      	mov  	bp,sp
	      	push 	56[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	push 	#disassem_62
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
disassem_64:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_63:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_64
DispRI:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_69
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r3,56[bp]
	      	sh   	r3,-4[bp]
	      	push 	56[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	push 	#disassem_66
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	push 	56[bp]
	      	bsr  	DispRstc
	      	addui	sp,sp,#8
	      	push 	56[bp]
	      	bsr  	DispRac
	      	addui	sp,sp,#8
	      	lw   	r3,40[bp]
	      	beq  	r3,disassem_70
	      	lw   	r3,48[bp]
	      	lw   	r4,56[bp]
	      	asri 	r4,r4,#17
	      	or   	r3,r3,r4
	      	push 	r3
	      	push 	#disassem_67
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_71
disassem_70:
	      	lh   	r3,-4[bp]
	      	sxh  	r3,r3
	      	sxh  	r3,r3
	      	asri 	r3,r3,#17
	      	push 	r3
	      	push 	#disassem_68
	      	bsr  	printf
	      	addui	sp,sp,#16
disassem_71:
disassem_72:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_69:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_72
public code DispBcc:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_75
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	lw   	r3,40[bp]
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#32767
	      	asli 	r3,r3,#2
	      	sw   	r3,-16[bp]
	      	lw   	r3,-16[bp]
	      	and  	r3,r3,#262144
	      	beq  	r3,disassem_76
	      	lw   	r3,-16[bp]
	      	ori  	r3,r3,#-262144
	      	sw   	r3,-16[bp]
disassem_76:
	      	push 	40[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	push 	#disassem_73
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	push 	40[bp]
	      	bsr  	DispRac
	      	addui	sp,sp,#8
	      	lw   	r3,24[bp]
	      	lw   	r4,-16[bp]
	      	addu 	r3,r3,r4
	      	push 	r3
	      	push 	#disassem_74
	      	bsr  	printf
	      	addui	sp,sp,#16
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
endpublic

public code DispRR:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_80
	      	mov  	bp,sp
	      	push 	40[bp]
	      	push 	24[bp]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	32[bp]
	      	push 	#disassem_79
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
disassem_81:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_80:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_81
endpublic

public code disassem:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_146
	      	mov  	bp,sp
	      	subui	sp,sp,#72
	      	push 	r11
	      	push 	r12
	      	lw   	r11,24[bp]
	      	ldi  	r12,#0
	      	sw   	r0,-40[bp]
disassem_147:
	      	lw   	r3,[r11]
	      	asri 	r3,r3,#2
	      	sw   	r3,-72[bp]
	      	lw   	r3,-72[bp]
	      	asli 	r3,r3,#2
	      	lhu  	r4,0[r12+r3]
	      	sh   	r4,-12[bp]
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
	      	beq  	r4,disassem_150
	      	cmp  	r4,r3,#2
	      	beq  	r4,disassem_151
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_152
	      	cmp  	r4,r3,#20
	      	beq  	r4,disassem_153
	      	cmp  	r4,r3,#5
	      	beq  	r4,disassem_154
	      	cmp  	r4,r3,#21
	      	beq  	r4,disassem_155
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_156
	      	cmp  	r4,r3,#22
	      	beq  	r4,disassem_157
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_158
	      	cmp  	r4,r3,#23
	      	beq  	r4,disassem_159
	      	cmp  	r4,r3,#8
	      	beq  	r4,disassem_160
	      	cmp  	r4,r3,#24
	      	beq  	r4,disassem_161
	      	cmp  	r4,r3,#12
	      	beq  	r4,disassem_162
	      	cmp  	r4,r3,#13
	      	beq  	r4,disassem_163
	      	cmp  	r4,r3,#14
	      	beq  	r4,disassem_164
	      	cmp  	r4,r3,#61
	      	beq  	r4,disassem_165
	      	cmp  	r4,r3,#57
	      	beq  	r4,disassem_166
	      	cmp  	r4,r3,#58
	      	beq  	r4,disassem_167
	      	cmp  	r4,r3,#55
	      	beq  	r4,disassem_168
	      	cmp  	r4,r3,#59
	      	beq  	r4,disassem_169
	      	cmp  	r4,r3,#64
	      	beq  	r4,disassem_170
	      	cmp  	r4,r3,#65
	      	beq  	r4,disassem_171
	      	cmp  	r4,r3,#66
	      	beq  	r4,disassem_172
	      	cmp  	r4,r3,#67
	      	beq  	r4,disassem_173
	      	cmp  	r4,r3,#68
	      	beq  	r4,disassem_174
	      	cmp  	r4,r3,#69
	      	beq  	r4,disassem_175
	      	cmp  	r4,r3,#70
	      	beq  	r4,disassem_176
	      	cmp  	r4,r3,#96
	      	beq  	r4,disassem_177
	      	cmp  	r4,r3,#97
	      	beq  	r4,disassem_178
	      	cmp  	r4,r3,#98
	      	beq  	r4,disassem_179
	      	cmp  	r4,r3,#99
	      	beq  	r4,disassem_180
	      	cmp  	r4,r3,#92
	      	beq  	r4,disassem_181
	      	cmp  	r4,r3,#110
	      	beq  	r4,disassem_182
	      	bra  	disassem_183
disassem_150:
	      	ldi  	r3,#1
	      	sw   	r3,-40[bp]
	      	lw   	r3,-48[bp]
	      	asl  	r3,r3,#25
	      	sw   	r3,-48[bp]
	      	lhu  	r3,-12[bp]
	      	and  	r3,r3,#-128
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#7
	      	lw   	r4,-48[bp]
	      	or   	r4,r4,r3
	      	sw   	r4,-48[bp]
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_82
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_149
disassem_151:
	      	lw   	r3,-32[bp]
	      	cmp  	r4,r3,#55
	      	beq  	r4,disassem_185
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_186
	      	cmp  	r4,r3,#20
	      	beq  	r4,disassem_187
	      	cmp  	r4,r3,#5
	      	beq  	r4,disassem_188
	      	cmp  	r4,r3,#21
	      	beq  	r4,disassem_189
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_190
	      	cmp  	r4,r3,#22
	      	beq  	r4,disassem_191
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_192
	      	cmp  	r4,r3,#23
	      	beq  	r4,disassem_193
	      	cmp  	r4,r3,#8
	      	beq  	r4,disassem_194
	      	cmp  	r4,r3,#24
	      	beq  	r4,disassem_195
	      	cmp  	r4,r3,#12
	      	beq  	r4,disassem_196
	      	cmp  	r4,r3,#13
	      	beq  	r4,disassem_197
	      	cmp  	r4,r3,#14
	      	beq  	r4,disassem_198
	      	cmp  	r4,r3,#31
	      	beq  	r4,disassem_199
	      	cmp  	r4,r3,#30
	      	beq  	r4,disassem_200
	      	bra  	disassem_184
disassem_185:
	      	lhu  	r3,-12[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#17
	      	and  	r3,r3,#31
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_202
	      	cmp  	r4,r3,#1
	      	beq  	r4,disassem_203
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_204
	      	cmp  	r4,r3,#29
	      	beq  	r4,disassem_205
	      	cmp  	r4,r3,#30
	      	beq  	r4,disassem_206
	      	cmp  	r4,r3,#31
	      	beq  	r4,disassem_207
	      	bra  	disassem_208
disassem_202:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_83
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_201
disassem_203:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_84
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_201
disassem_204:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_85
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_201
disassem_205:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_86
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_201
disassem_206:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_87
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_201
disassem_207:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_88
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_201
disassem_208:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_89
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_201
disassem_201:
	      	bra  	disassem_184
disassem_186:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_90
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_184
disassem_187:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_91
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_184
disassem_188:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_92
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_184
disassem_189:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_93
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_184
disassem_190:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_94
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_184
disassem_191:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_95
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_184
disassem_192:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_96
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_184
disassem_193:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_97
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_184
disassem_194:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_98
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_184
disassem_195:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_99
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_184
disassem_196:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_100
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_184
disassem_197:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_101
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_184
disassem_198:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_102
	      	push 	[r11]
	      	bsr  	DispRR
	      	addui	sp,sp,#24
	      	bra  	disassem_184
disassem_199:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_103
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
	      	push 	#disassem_104
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_184
disassem_200:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	push 	#disassem_105
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispSpr
	      	addui	sp,sp,#8
	      	push 	#disassem_106
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	bsr  	DispRa
	      	addui	sp,sp,#8
	      	push 	#disassem_107
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	disassem_184
disassem_184:
	      	bra  	disassem_149
disassem_152:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_108
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_153:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_109
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_154:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_110
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_155:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_111
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_156:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_112
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_157:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_113
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_158:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_114
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_159:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_115
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_160:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_116
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_161:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_117
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_162:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_118
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_163:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_119
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_164:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_120
	      	push 	[r11]
	      	bsr  	DispRI
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_165:
	      	lhu  	r3,-12[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#12
	      	and  	r3,r3,#7
	      	cmp  	r4,r3,#0
	      	beq  	r4,disassem_210
	      	cmp  	r4,r3,#1
	      	beq  	r4,disassem_211
	      	cmp  	r4,r3,#4
	      	beq  	r4,disassem_212
	      	cmp  	r4,r3,#5
	      	beq  	r4,disassem_213
	      	cmp  	r4,r3,#2
	      	beq  	r4,disassem_214
	      	cmp  	r4,r3,#3
	      	beq  	r4,disassem_215
	      	cmp  	r4,r3,#6
	      	beq  	r4,disassem_216
	      	cmp  	r4,r3,#7
	      	beq  	r4,disassem_216
	      	bra  	disassem_209
disassem_210:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_121
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_209
disassem_211:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_122
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_209
disassem_212:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_123
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_209
disassem_213:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_124
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_209
disassem_214:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_125
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_209
disassem_215:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_126
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_209
disassem_216:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	#disassem_127
	      	push 	[r11]
	      	bsr  	DispBcc
	      	addui	sp,sp,#24
	      	bra  	disassem_209
disassem_209:
	      	bra  	disassem_149
disassem_166:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	lhu  	r3,-12[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#7
	      	sw   	r3,-64[bp]
	      	lw   	r3,-64[bp]
	      	and  	r3,r3,#16777216
	      	beq  	r3,disassem_217
	      	lw   	r3,-64[bp]
	      	ori  	r3,r3,#-16777216
	      	sw   	r3,-64[bp]
disassem_217:
	      	lw   	r3,-64[bp]
	      	asli 	r3,r3,#2
	      	asli 	r3,r3,#3
	      	addu 	r11,r11,r3
	      	sw   	r11,-56[bp]
	      	push 	-56[bp]
	      	push 	#disassem_128
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_149
disassem_167:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	[r11]
	      	bsr  	DumpInsnBytes
	      	addui	sp,sp,#16
	      	lhu  	r3,-12[bp]
	      	andi 	r3,r3,#-1
	      	asri 	r3,r3,#7
	      	sw   	r3,-64[bp]
	      	lw   	r3,-64[bp]
	      	and  	r3,r3,#16777216
	      	beq  	r3,disassem_219
	      	lw   	r3,-64[bp]
	      	ori  	r3,r3,#-16777216
	      	sw   	r3,-64[bp]
disassem_219:
	      	lw   	r3,-64[bp]
	      	asli 	r3,r3,#2
	      	asli 	r3,r3,#3
	      	addu 	r11,r11,r3
	      	sw   	r11,-56[bp]
	      	push 	-56[bp]
	      	push 	#disassem_129
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_149
disassem_168:
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
	      	push 	#disassem_130
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_149
disassem_169:
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
	      	push 	#disassem_131
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_149
disassem_170:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_132
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_171:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_133
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_172:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_134
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_173:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_135
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_174:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_136
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_175:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_137
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_176:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_138
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_177:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_139
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_178:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_140
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_179:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_141
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_180:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_142
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_181:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_143
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_182:
	      	lhu  	r3,-12[bp]
	      	push 	r3
	      	push 	-48[bp]
	      	push 	-40[bp]
	      	push 	#disassem_144
	      	push 	[r11]
	      	bsr  	DispLS
	      	addui	sp,sp,#40
	      	bra  	disassem_149
disassem_183:
	      	push 	[r11]
	      	push 	#disassem_145
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	disassem_149
disassem_149:
	      	lw   	r3,[r11]
	      	addu 	r3,r3,#4
	      	sw   	r3,[r11]
	      	lw   	r3,-24[bp]
	      	cmp  	r3,r3,#124
	      	beq  	r3,disassem_147
disassem_148:
disassem_221:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_146:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_221
endpublic

public code disassem20:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#disassem_224
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	#disassem_222
	      	bsr  	putstr2
	      	push 	#disassem_223
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bsr  	getchar
	      	sw   	r0,-8[bp]
disassem_225:
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#20
	      	bge  	r3,disassem_226
	      	pea  	24[bp]
	      	bsr  	disassem
	      	addui	sp,sp,#8
disassem_227:
	      	inc  	-8[bp],#1
	      	bra  	disassem_225
disassem_226:
disassem_228:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
disassem_224:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	disassem_228
endpublic

	rodata
	align	16
	align	8
disassem_223:	; Disassem:

	dc	68,105,115,97,115,115,101,109
	dc	58,13,10,0
disassem_222:	; Disassem:

	dc	68,105,115,97,115,115,101,109
	dc	58,13,10,0
disassem_145:	; %06X	?????

	dc	37,48,54,88,9,63,63,63
	dc	63,63,13,10,0
disassem_144:	; SWCR 
	dc	83,87,67,82,32,0
disassem_143:	; LWAR 
	dc	76,87,65,82,32,0
disassem_142:	; SW   
	dc	83,87,32,32,32,0
disassem_141:	; SH   
	dc	83,72,32,32,32,0
disassem_140:	; SC   
	dc	83,67,32,32,32,0
disassem_139:	; SB   
	dc	83,66,32,32,32,0
disassem_138:	; LW   
	dc	76,87,32,32,32,0
disassem_137:	; LHU  
	dc	76,72,85,32,32,0
disassem_136:	; LH   
	dc	76,72,32,32,32,0
disassem_135:	; LCU  
	dc	76,67,85,32,32,0
disassem_134:	; LC   
	dc	76,67,32,32,32,0
disassem_133:	; LBU  
	dc	76,66,85,32,32,0
disassem_132:	; LB   
	dc	76,66,32,32,32,0
disassem_131:	; RTS  	#%x

	dc	82,84,83,32,32,9,35,37
	dc	120,13,10,0
disassem_130:	; RTL  	#%x

	dc	82,84,76,32,32,9,35,37
	dc	120,13,10,0
disassem_129:	; BRA  	%x
	dc	66,82,65,32,32,9,37,120
	dc	0
disassem_128:	; BSR  	%x
	dc	66,83,82,32,32,9,37,120
	dc	0
disassem_127:	; ???  
	dc	63,63,63,32,32,0
disassem_126:	; BGE  
	dc	66,71,69,32,32,0
disassem_125:	; BGT  
	dc	66,71,84,32,32,0
disassem_124:	; BLE  
	dc	66,76,69,32,32,0
disassem_123:	; BLT  
	dc	66,76,84,32,32,0
disassem_122:	; BNE  
	dc	66,78,69,32,32,0
disassem_121:	; BEQ  
	dc	66,69,81,32,32,0
disassem_120:	; EOR  
	dc	69,79,82,32,32,0
disassem_119:	; OR   
	dc	79,82,32,32,32,0
disassem_118:	; AND  
	dc	65,78,68,32,32,0
disassem_117:	; DIVU 
	dc	68,73,86,85,32,0
disassem_116:	; DIV  
	dc	68,73,86,32,32,0
disassem_115:	; MULU 
	dc	77,85,76,85,32,0
disassem_114:	; MUL  
	dc	77,85,76,32,32,0
disassem_113:	; CMPU 
	dc	67,77,80,85,32,0
disassem_112:	; CMP  
	dc	67,77,80,32,32,0
disassem_111:	; SUBU  
	dc	83,85,66,85,32,32,0
disassem_110:	; SUB  
	dc	83,85,66,32,32,0
disassem_109:	; ADDU  
	dc	65,68,68,85,32,32,0
disassem_108:	; ADD  
	dc	65,68,68,32,32,0
disassem_107:	; 

	dc	13,10,0
disassem_106:	; ,
	dc	44,0
disassem_105:	; MTSPR	
	dc	77,84,83,80,82,9,0
disassem_104:	; 

	dc	13,10,0
disassem_103:	; MFSPR	
	dc	77,70,83,80,82,9,0
disassem_102:	; EOR  
	dc	69,79,82,32,32,0
disassem_101:	; OR   
	dc	79,82,32,32,32,0
disassem_100:	; AND  
	dc	65,78,68,32,32,0
disassem_99:	; DIVU 
	dc	68,73,86,85,32,0
disassem_98:	; DIV  
	dc	68,73,86,32,32,0
disassem_97:	; MULU 
	dc	77,85,76,85,32,0
disassem_96:	; MUL  
	dc	77,85,76,32,32,0
disassem_95:	; CMPU 
	dc	67,77,80,85,32,0
disassem_94:	; CMP  
	dc	67,77,80,32,32,0
disassem_93:	; SUBU 
	dc	83,85,66,85,32,0
disassem_92:	; SUB  
	dc	83,85,66,32,32,0
disassem_91:	; ADDU 
	dc	65,68,68,85,32,0
disassem_90:	; ADD  
	dc	65,68,68,32,32,0
disassem_89:	; ???

	dc	63,63,63,13,10,0
disassem_88:	; RTI

	dc	82,84,73,13,10,0
disassem_87:	; RTE

	dc	82,84,69,13,10,0
disassem_86:	; RTD

	dc	82,84,68,13,10,0
disassem_85:	; WAI

	dc	87,65,73,13,10,0
disassem_84:	; SEI

	dc	83,69,73,13,10,0
disassem_83:	; CLI

	dc	67,76,73,13,10,0
disassem_82:	; IMM

	dc	73,77,77,13,10,0
disassem_79:	; %s	
	dc	37,115,9,0
disassem_74:	; %06X
	dc	37,48,54,88,0
disassem_73:	; %s	
	dc	37,115,9,0
disassem_68:	; #$%x

	dc	35,36,37,120,13,10,0
disassem_67:	; #$%x

	dc	35,36,37,120,13,10,0
disassem_66:	; %s	
	dc	37,115,9,0
disassem_62:	; %s	
	dc	37,115,9,0
disassem_54:	; [r%d]

	dc	91,114,37,100,93,13,10,0
disassem_53:	; $%x
	dc	36,37,120,0
disassem_52:	; $%x
	dc	36,37,120,0
disassem_35:	; spr%d
	dc	115,112,114,37,100,0
disassem_34:	; dbad3
	dc	100,98,97,100,51,0
disassem_33:	; dbad2
	dc	100,98,97,100,50,0
disassem_32:	; dbad1
	dc	100,98,97,100,49,0
disassem_31:	; dbad0
	dc	100,98,97,100,48,0
disassem_30:	; vbr
	dc	118,98,114,0
disassem_29:	; epc
	dc	101,112,99,0
disassem_28:	; ipc
	dc	105,112,99,0
disassem_27:	; dpc
	dc	100,112,99,0
disassem_26:	; clk
	dc	99,108,107,0
disassem_25:	; cr3
	dc	99,114,51,0
disassem_24:	; cr0
	dc	99,114,48,0
disassem_20:	; r%d,
	dc	114,37,100,44,0
disassem_16:	; r%d
	dc	114,37,100,0
disassem_12:	; r%d,
	dc	114,37,100,44,0
disassem_8:	; r%d,
	dc	114,37,100,44,0
disassem_4:	; r%d
	dc	114,37,100,0
disassem_0:	; %06X %02X %02X %02X %02X	
	dc	37,48,54,88,32,37,48,50
	dc	88,32,37,48,50,88,32,37
	dc	48,50,88,32,37,48,50,88
	dc	9,0
;	global	DispRR
;	global	DumpInsnBytes
;	global	disassem
	extern	printf
;	global	DispBcc
;	global	disassem20
	extern	getchar
	extern	putstr2
