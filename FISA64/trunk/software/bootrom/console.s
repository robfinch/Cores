	data
	align	8
	db	0
	align	8
	db	0
	align	8
	db	0
	align	8
	db	0
	align	8
	db	0
	align	8
	db	0
	code
	align	16
public code GetScreenLocation:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_135
	      	mov  	bp,sp
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	lw   	r3,1616[r3]
	      	mov  	r1,r3
console_136:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_135:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_136
endpublic

public code GetCurrAttr:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_137
	      	mov  	bp,sp
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	lhu  	r3,1640[r3]
	      	mov  	r1,r3
console_138:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_137:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_138
endpublic

public code SetCurrAttr:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_139
	      	mov  	bp,sp
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	lhu  	r4,24[bp]
	      	sh   	r4,1640[r3]
console_140:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_139:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_140
endpublic

public code SetVideoReg:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	         lw   r1,24[bp]
         lw   r2,32[bp]
         asl  r1,r1,#2
         sh   r2,$FFDA0000[r1]
     
console_142:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code SetCursorPos:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_143
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lw   	r3,32[bp]
	      	sc   	r3,1638[r11]
	      	lw   	r3,24[bp]
	      	sc   	r3,1636[r11]
	      	bsr  	UpdateCursorPos
console_144:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_143:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_144
endpublic

public code SetCursorCol:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_145
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lw   	r3,24[bp]
	      	sc   	r3,1638[r11]
	      	bsr  	UpdateCursorPos
console_146:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_145:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_146
endpublic

public code GetCursorPos:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_147
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lcu  	r3,1638[r11]
	      	lcu  	r4,1636[r11]
	      	asli 	r4,r4,#8
	      	or   	r3,r3,r4
	      	mov  	r1,r3
console_148:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_147:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_148
endpublic

public code AsciiToScreen:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lcu  	r3,24[bp]
	      	cmp  	r3,r3,#91
	      	bne  	r3,console_150
	      	ldi  	r1,#27
console_152:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
console_150:
	      	lcu  	r3,24[bp]
	      	cmp  	r3,r3,#93
	      	bne  	r3,console_153
	      	ldi  	r1,#29
	      	bra  	console_152
console_153:
	      	lcu  	r3,24[bp]
	      	andi 	r3,r3,#255
	      	sc   	r3,24[bp]
	      	lcu  	r3,24[bp]
	      	ori  	r3,r3,#256
	      	sc   	r3,24[bp]
	      	lcu  	r3,24[bp]
	      	and  	r3,r3,#32
	      	bne  	r3,console_155
	      	lcu  	r3,24[bp]
	      	mov  	r1,r3
	      	bra  	console_152
console_155:
	      	lcu  	r3,24[bp]
	      	and  	r3,r3,#64
	      	bne  	r3,console_157
	      	lcu  	r3,24[bp]
	      	mov  	r1,r3
	      	bra  	console_152
console_157:
	      	lcu  	r3,24[bp]
	      	and  	r3,r3,#415
	      	sc   	r3,24[bp]
	      	lcu  	r3,24[bp]
	      	mov  	r1,r3
	      	bra  	console_152
endpublic

public code ScreenToAscii:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lcu  	r3,24[bp]
	      	andi 	r3,r3,#255
	      	sc   	r3,24[bp]
	      	lcu  	r3,24[bp]
	      	cmp  	r3,r3,#27
	      	bne  	r3,console_160
	      	ldi  	r1,#91
console_162:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
console_160:
	      	lcu  	r3,24[bp]
	      	cmp  	r3,r3,#29
	      	bne  	r3,console_163
	      	ldi  	r1,#93
	      	bra  	console_162
console_163:
	      	lcu  	r3,24[bp]
	      	cmpu 	r3,r3,#27
	      	bge  	r3,console_165
	      	lcu  	r3,24[bp]
	      	addui	r3,r3,#96
	      	sc   	r3,24[bp]
console_165:
	      	lcu  	r3,24[bp]
	      	mov  	r1,r3
	      	bra  	console_162
endpublic

public code UpdateCursorPos:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_167
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lcu  	r3,1636[r11]
	      	lcu  	r4,1634[r11]
	      	mulu 	r3,r3,r4
	      	lcu  	r4,1638[r11]
	      	addu 	r3,r3,r4
	      	sxc  	r3,r3
	      	sw   	r3,-16[bp]
	      	push 	-16[bp]
	      	push 	#11
	      	bsr  	SetVideoReg
	      	addui	sp,sp,#16
console_168:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_167:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_168
endpublic

public code HomeCursor:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_169
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	sc   	r0,1638[r11]
	      	sc   	r0,1636[r11]
	      	bsr  	UpdateCursorPos
console_170:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_169:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_170
endpublic

public code CalcScreenLocation:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_171
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lcu  	r3,1636[r11]
	      	lcu  	r4,1634[r11]
	      	mulu 	r3,r3,r4
	      	lcu  	r4,1638[r11]
	      	addu 	r3,r3,r4
	      	sxc  	r3,r3
	      	sw   	r3,-16[bp]
	      	push 	-16[bp]
	      	push 	#11
	      	bsr  	SetVideoReg
	      	addui	sp,sp,#16
	      	bsr  	GetScreenLocation
	      	mov  	r3,r1
	      	lw   	r4,-16[bp]
	      	asli 	r4,r4,#2
	      	addu 	r3,r3,r4
	      	mov  	r1,r3
console_172:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_171:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_172
endpublic

public code ClearScreen:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_173
	      	mov  	bp,sp
	      	subui	sp,sp,#40
	      	push 	r11
	      	push 	r12
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	bsr  	GetScreenLocation
	      	mov  	r3,r1
	      	mov  	r12,r3
	      	lcu  	r3,1632[r11]
	      	lcu  	r4,1634[r11]
	      	mul  	r3,r3,r4
	      	sw   	r3,-24[bp]
	      	bsr  	GetCurrAttr
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#32
	      	bsr  	AsciiToScreen
	      	addui	sp,sp,#8
	      	pop  	r3
	      	mov  	r4,r1
	      	sxc  	r4,r4
	      	or   	r3,r3,r4
	      	sh   	r3,-36[bp]
	      	sw   	r0,-16[bp]
console_174:
	      	lw   	r3,-16[bp]
	      	lw   	r4,-24[bp]
	      	cmp  	r3,r3,r4
	      	bge  	r3,console_175
	      	lw   	r3,-16[bp]
	      	asli 	r3,r3,#2
	      	lh   	r4,-36[bp]
	      	sh   	r4,0[r12+r3]
console_176:
	      	inc  	-16[bp],#1
	      	bra  	console_174
console_175:
console_177:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_173:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_177
endpublic

public code BlankLine:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_178
	      	mov  	bp,sp
	      	subui	sp,sp,#40
	      	push 	r11
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	bsr  	GetScreenLocation
	      	mov  	r3,r1
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	lcu  	r4,1634[r11]
	      	lw   	r5,24[bp]
	      	mul  	r4,r4,r5
	      	asli 	r4,r4,#2
	      	addu 	r3,r3,r4
	      	sw   	r3,-8[bp]
	      	bsr  	GetCurrAttr
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#32
	      	bsr  	AsciiToScreen
	      	addui	sp,sp,#8
	      	pop  	r3
	      	mov  	r4,r1
	      	sxc  	r4,r4
	      	or   	r3,r3,r4
	      	sh   	r3,-36[bp]
	      	sw   	r0,-16[bp]
console_179:
	      	lw   	r3,-16[bp]
	      	lcu  	r4,1634[r11]
	      	sxc  	r4,r4
	      	cmp  	r3,r3,r4
	      	bge  	r3,console_180
	      	lw   	r3,-16[bp]
	      	asli 	r3,r3,#2
	      	lw   	r4,-8[bp]
	      	lh   	r5,-36[bp]
	      	sh   	r5,0[r4+r3]
console_181:
	      	inc  	-16[bp],#1
	      	bra  	console_179
console_180:
console_182:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_178:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_182
endpublic

public code ScrollUp:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_183
	      	mov  	bp,sp
	      	subui	sp,sp,#32
	      	push 	r11
	      	push 	r12
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	bsr  	GetScreenLocation
	      	mov  	r3,r1
	      	mov  	r12,r3
	      	lcu  	r3,1632[r11]
	      	subu 	r3,r3,#1
	      	lcu  	r4,1634[r11]
	      	sxc  	r4,r4
	      	mul  	r3,r3,r4
	      	sw   	r3,-24[bp]
	      	sw   	r0,-16[bp]
console_184:
	      	lw   	r3,-16[bp]
	      	lw   	r4,-24[bp]
	      	cmp  	r3,r3,r4
	      	bge  	r3,console_185
	      	lw   	r3,-16[bp]
	      	lcu  	r4,1634[r11]
	      	sxc  	r4,r4
	      	addu 	r3,r3,r4
	      	asli 	r3,r3,#2
	      	lw   	r4,-16[bp]
	      	asli 	r4,r4,#2
	      	lh   	r5,0[r12+r3]
	      	sh   	r5,0[r12+r4]
console_186:
	      	inc  	-16[bp],#1
	      	bra  	console_184
console_185:
	      	lcu  	r3,1632[r11]
	      	subu 	r3,r3,#1
	      	push 	r3
	      	bsr  	BlankLine
	      	addui	sp,sp,#8
console_187:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_183:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_187
endpublic

public code IncrementCursorPos:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_188
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lcu  	r3,1638[r11]
	      	addui	r3,r3,#1
	      	sc   	r3,1638[r11]
	      	lcu  	r3,1638[r11]
	      	lcu  	r4,1634[r11]
	      	cmpu 	r3,r3,r4
	      	bge  	r3,console_189
	      	bsr  	UpdateCursorPos
console_191:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_189:
	      	sc   	r0,1638[r11]
	      	lcu  	r3,1636[r11]
	      	addui	r3,r3,#1
	      	sc   	r3,1636[r11]
	      	lcu  	r3,1636[r11]
	      	lcu  	r4,1632[r11]
	      	cmpu 	r3,r3,r4
	      	bge  	r3,console_192
	      	bsr  	UpdateCursorPos
	      	bra  	console_191
console_192:
	      	lcu  	r3,1636[r11]
	      	subui	r3,r3,#1
	      	sc   	r3,1636[r11]
	      	bsr  	ScrollUp
	      	bra  	console_191
console_188:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_191
endpublic

public code DisplayChar:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_194
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	push 	r11
	      	push 	r12
	      	bsr  	GetJCBPtr
	      	mov  	r3,r1
	      	mov  	r11,r3
	      	lcu  	r3,24[bp]
	      	cmp  	r4,r3,#13
	      	beq  	r4,console_196
	      	cmp  	r4,r3,#10
	      	beq  	r4,console_197
	      	cmp  	r4,r3,#145
	      	beq  	r4,console_198
	      	cmp  	r4,r3,#144
	      	beq  	r4,console_199
	      	cmp  	r4,r3,#147
	      	beq  	r4,console_200
	      	cmp  	r4,r3,#146
	      	beq  	r4,console_201
	      	cmp  	r4,r3,#148
	      	beq  	r4,console_202
	      	cmp  	r4,r3,#153
	      	beq  	r4,console_203
	      	cmp  	r4,r3,#8
	      	beq  	r4,console_204
	      	cmp  	r4,r3,#9
	      	beq  	r4,console_205
	      	bra  	console_206
console_196:
	      	sc   	r0,1638[r11]
	      	bsr  	UpdateCursorPos
	      	bra  	console_195
console_197:
	      	lcu  	r3,1636[r11]
	      	lcu  	r4,1632[r11]
	      	cmpu 	r3,r3,r4
	      	bge  	r3,console_207
	      	lcu  	r3,1636[r11]
	      	addui	r3,r3,#1
	      	sc   	r3,1636[r11]
	      	bsr  	UpdateCursorPos
	      	bra  	console_208
console_207:
	      	bsr  	ScrollUp
console_208:
	      	bra  	console_195
console_198:
	      	lcu  	r3,1638[r11]
	      	lcu  	r4,1634[r11]
	      	cmpu 	r3,r3,r4
	      	bge  	r3,console_209
	      	lcu  	r3,1638[r11]
	      	addui	r3,r3,#1
	      	sc   	r3,1638[r11]
	      	bsr  	UpdateCursorPos
console_209:
	      	bra  	console_195
console_199:
	      	lcu  	r3,1636[r11]
	      	cmpu 	r3,r3,#0
	      	ble  	r3,console_211
	      	lcu  	r3,1636[r11]
	      	subui	r3,r3,#1
	      	sc   	r3,1636[r11]
	      	bsr  	UpdateCursorPos
console_211:
	      	bra  	console_195
console_200:
	      	lcu  	r3,1638[r11]
	      	cmpu 	r3,r3,#0
	      	ble  	r3,console_213
	      	lcu  	r3,1638[r11]
	      	subui	r3,r3,#1
	      	sc   	r3,1638[r11]
	      	bsr  	UpdateCursorPos
console_213:
	      	bra  	console_195
console_201:
	      	lcu  	r3,1636[r11]
	      	lcu  	r4,1632[r11]
	      	cmpu 	r3,r3,r4
	      	bge  	r3,console_215
	      	lcu  	r3,1636[r11]
	      	addui	r3,r3,#1
	      	sc   	r3,1636[r11]
	      	bsr  	UpdateCursorPos
console_215:
	      	bra  	console_195
console_202:
	      	lcu  	r3,1638[r11]
	      	bne  	r3,console_217
	      	sc   	r0,1636[r11]
console_217:
	      	sc   	r0,1638[r11]
	      	bsr  	UpdateCursorPos
	      	bra  	console_195
console_203:
	      	bsr  	CalcScreenLocation
	      	mov  	r3,r1
	      	mov  	r12,r3
	      	lcu  	r3,1638[r11]
	      	sxc  	r3,r3
	      	sw   	r3,-16[bp]
console_219:
	      	lw   	r3,-16[bp]
	      	lcu  	r4,1634[r11]
	      	subu 	r4,r4,#1
	      	cmp  	r3,r3,r4
	      	bge  	r3,console_220
	      	lw   	r3,-16[bp]
	      	asli 	r3,r3,#2
	      	addu 	r3,r3,r12
	      	lw   	r4,-16[bp]
	      	asli 	r4,r4,#2
	      	lh   	r5,4[r3]
	      	sh   	r5,0[r12+r4]
console_221:
	      	inc  	-16[bp],#1
	      	bra  	console_219
console_220:
	      	bsr  	GetCurrAttr
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#32
	      	bsr  	AsciiToScreen
	      	addui	sp,sp,#8
	      	pop  	r3
	      	mov  	r4,r1
	      	sxc  	r4,r4
	      	or   	r3,r3,r4
	      	lw   	r4,-16[bp]
	      	asli 	r4,r4,#2
	      	sh   	r3,0[r12+r4]
	      	bra  	console_195
console_204:
	      	lcu  	r3,1638[r11]
	      	cmpu 	r3,r3,#0
	      	ble  	r3,console_222
	      	lcu  	r3,1638[r11]
	      	subui	r3,r3,#1
	      	sc   	r3,1638[r11]
	      	bsr  	CalcScreenLocation
	      	mov  	r3,r1
	      	mov  	r12,r3
	      	lcu  	r3,1638[r11]
	      	sxc  	r3,r3
	      	sw   	r3,-16[bp]
console_224:
	      	lw   	r3,-16[bp]
	      	lcu  	r4,1634[r11]
	      	subu 	r4,r4,#1
	      	cmp  	r3,r3,r4
	      	bge  	r3,console_225
	      	lw   	r3,-16[bp]
	      	asli 	r3,r3,#2
	      	addu 	r3,r3,r12
	      	lw   	r4,-16[bp]
	      	asli 	r4,r4,#2
	      	lh   	r5,4[r3]
	      	sh   	r5,0[r12+r4]
console_226:
	      	inc  	-16[bp],#1
	      	bra  	console_224
console_225:
	      	bsr  	GetCurrAttr
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#32
	      	bsr  	AsciiToScreen
	      	addui	sp,sp,#8
	      	pop  	r3
	      	mov  	r4,r1
	      	sxc  	r4,r4
	      	or   	r3,r3,r4
	      	lw   	r4,-16[bp]
	      	asli 	r4,r4,#2
	      	sh   	r3,0[r12+r4]
console_222:
	      	bra  	console_195
console_205:
	      	push 	#32
	      	bsr  	DisplayChar
	      	addui	sp,sp,#8
	      	push 	#32
	      	bsr  	DisplayChar
	      	addui	sp,sp,#8
	      	push 	#32
	      	bsr  	DisplayChar
	      	addui	sp,sp,#8
	      	push 	#32
	      	bsr  	DisplayChar
	      	addui	sp,sp,#8
	      	bra  	console_195
console_206:
	      	bsr  	CalcScreenLocation
	      	mov  	r3,r1
	      	mov  	r12,r3
	      	bsr  	GetCurrAttr
	      	mov  	r3,r1
	      	push 	r3
	      	lcu  	r4,24[bp]
	      	push 	r4
	      	bsr  	AsciiToScreen
	      	addui	sp,sp,#8
	      	pop  	r3
	      	mov  	r4,r1
	      	sxc  	r4,r4
	      	or   	r3,r3,r4
	      	sh   	r3,[r12]
	      	bsr  	IncrementCursorPos
	      	bra  	console_195
console_195:
console_227:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_194:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_227
endpublic

public code CRLF:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_228
	      	mov  	bp,sp
	      	push 	#13
	      	bsr  	DisplayChar
	      	addui	sp,sp,#8
	      	push 	#10
	      	bsr  	DisplayChar
	      	addui	sp,sp,#8
console_229:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_228:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_229
endpublic

public code DisplayString:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_230
	      	mov  	bp,sp
	      	push 	r11
	      	lw   	r11,24[bp]
console_231:
	      	lcu  	r3,[r11]
	      	beq  	r3,console_232
	      	lcu  	r3,[r11]
	      	push 	r3
	      	bsr  	DisplayChar
	      	addui	sp,sp,#8
	      	addui	r11,r11,#2
	      	bra  	console_231
console_232:
console_233:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_230:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_233
endpublic

public code DisplayStringCRLF:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#console_234
	      	mov  	bp,sp
	      	push 	24[bp]
	      	bsr  	DisplayString
	      	addui	sp,sp,#8
	      	bsr  	CRLF
console_235:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
console_234:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	console_235
endpublic

	rodata
	align	16
	align	8
;	global	HomeCursor
;	global	AsciiToScreen
;	global	ScreenToAscii
;	global	CalcScreenLocation
;	global	UpdateCursorPos
	extern	GetJCBPtr
;	global	CRLF
;	global	ScrollUp
;	global	SetVideoReg
;	global	ClearScreen
;	global	DisplayString
;	global	DisplayChar
;	global	IncrementCursorPos
;	global	GetCurrAttr
;	global	SetCurrAttr
;	global	BlankLine
;	global	DisplayStringCRLF
;	global	GetScreenLocation
	extern	IOFocusNdx
;	global	SetCursorCol
;	global	GetCursorPos
;	global	SetCursorPos
