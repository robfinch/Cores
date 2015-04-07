	bss
	align	8
	align	8
public bss linendx:
	fill.b	8,0x00

endpublic
	align	8
public bss linebuf:
	fill.b	200,0x00

endpublic
	align	8
public bss dbg_stack:
	fill.b	4096,0x00

endpublic
	align	8
public bss dbg_dbctrl:
	fill.b	8,0x00

endpublic
	align	8
public bss regs:
	fill.b	256,0x00

endpublic
	align	8
public bss cr0save:
	fill.b	8,0x00

endpublic
	align	8
public bss ssm:
	fill.b	8,0x00

endpublic
	align	8
public bss repcount:
	fill.b	8,0x00

endpublic
	align	8
public bss curaddr:
	fill.b	8,0x00

endpublic
	align	8
public bss cursz:
	fill.b	8,0x00

endpublic
	align	8
public bss curfmt:
	fill.b	2,0x00

endpublic
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
	bss
	align	8
	align	8
public bss currep:
	fill.b	8,0x00

endpublic
	align	8
public bss muol:
	fill.b	8,0x00

endpublic
	align	8
public bss bmem:
	fill.b	8,0x00

endpublic
	align	8
public bss cmem:
	fill.b	8,0x00

endpublic
	align	8
public bss hmem:
	fill.b	8,0x00

endpublic
	align	8
public bss wmem:
	fill.b	8,0x00

endpublic
	code
	align	16
dbg_DisplayHelp:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_252
	      	mov  	bp,sp
	      	push 	#debugger_237
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_238
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_239
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_240
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_241
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_242
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_243
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_244
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_245
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_246
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_247
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_248
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_249
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_250
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	push 	#debugger_251
	      	bsr  	printf
	      	addui	sp,sp,#8
debugger_253:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_252:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_253
public code GetVBR:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        mfspr r1,vbr
    
debugger_255:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code set_vector:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_256
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	cmpu 	r3,r3,#511
	      	ble  	r3,debugger_257
debugger_259:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_257:
	      	lw   	r3,32[bp]
	      	beq  	r3,debugger_262
	      	lw   	r3,32[bp]
	      	and  	r3,r3,#3
	      	beq  	r3,debugger_260
debugger_262:
	      	bra  	debugger_259
debugger_260:
	      	lw   	r3,24[bp]
	      	asli 	r3,r3,#3
	      	push 	r3
	      	bsr  	GetVBR
	      	pop  	r3
	      	mov  	r4,r1
	      	lw   	r5,32[bp]
	      	sw   	r5,0[r4+r3]
	      	bra  	debugger_259
debugger_256:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_259
endpublic

public code dbg_GetCursorRow:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        ldi    r6,#3   ; Get cursor position
        sys    #410
        lsr    r1,r1,#8
    
debugger_264:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code dbg_GetCursorCol:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        ldi    r6,#3
        sys    #410
        and    r1,r1,#$FF
    
debugger_266:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code dbg_HomeCursor:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	         ldi   r6,#2
         ldi   r1,#0
         ldi   r2,#0
         sys   #410
     
debugger_268:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code dbg_GetDBAD:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	cmp  	r4,r3,#0
	      	beq  	r4,debugger_271
	      	cmp  	r4,r3,#1
	      	beq  	r4,debugger_272
	      	cmp  	r4,r3,#2
	      	beq  	r4,debugger_273
	      	cmp  	r4,r3,#3
	      	beq  	r4,debugger_274
	      	bra  	debugger_270
debugger_271:
	      	     	mfspr  r1,dbad0  
	      	bra  	debugger_270
debugger_272:
	      	     	mfspr  r1,dbad1  
	      	bra  	debugger_270
debugger_273:
	      	     	mfspr  r1,dbad2  
	      	bra  	debugger_270
debugger_274:
	      	     	mfspr  r1,dbad3  
	      	bra  	debugger_270
debugger_275:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
debugger_270:
	      	bra  	debugger_275
endpublic

public code dbg_SetDBAD:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	cmp  	r4,r3,#0
	      	beq  	r4,debugger_278
	      	cmp  	r4,r3,#1
	      	beq  	r4,debugger_279
	      	cmp  	r4,r3,#2
	      	beq  	r4,debugger_280
	      	cmp  	r4,r3,#3
	      	beq  	r4,debugger_281
	      	bra  	debugger_277
debugger_278:
	      	     	          lw    r1,32[bp]
          mtspr dbad0,r1
          
	      	bra  	debugger_277
debugger_279:
	      	     	          lw    r1,32[bp]
          mtspr dbad1,r1
          
	      	bra  	debugger_277
debugger_280:
	      	     	          lw    r1,32[bp]
          mtspr dbad2,r1
          
	      	bra  	debugger_277
debugger_281:
	      	     	          lw    r1,32[bp]
          mtspr dbad3,r1
          
	      	bra  	debugger_277
debugger_277:
debugger_282:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code dbg_arm:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	         lw    r1,24[bp]
         mtspr dbctrl,r1
     
debugger_284:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code CvtScreenToAscii:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	         lw    r1,24[bp]
         ldi   r6,#$21         ; screen to ascii
         sys   #410
     
debugger_286:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code dbg_getchar:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	ldi  	r11,#linendx
	      	ldi  	r3,#-1
	      	sc   	r3,-2[bp]
	      	lw   	r3,[r11]
	      	cmp  	r3,r3,#84
	      	bge  	r3,debugger_288
	      	lw   	r3,[r11]
	      	asli 	r3,r3,#1
	      	lcu  	r4,linebuf[r3]
	      	sc   	r4,-2[bp]
	      	inc  	[r11],#1
debugger_288:
	      	lcu  	r3,-2[bp]
	      	mov  	r1,r3
debugger_290:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code ignore_blanks:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#8
debugger_292:
	      	lw   	r3,linendx
	      	asli 	r3,r3,#1
	      	lcu  	r4,linebuf[r3]
	      	sc   	r4,-2[bp]
	      	inc  	linendx,#1
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#32
	      	beq  	r3,debugger_292
debugger_293:
debugger_294:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code dbg_ungetch:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	lw   	r3,linendx
	      	ble  	r3,debugger_296
	      	dec  	linendx,#1
debugger_296:
debugger_298:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code dbg_nextNonSpace:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_299
	      	mov  	bp,sp
	      	subui	sp,sp,#8
debugger_300:
	      	lw   	r3,linendx
	      	cmp  	r3,r3,#84
	      	bge  	r3,debugger_301
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#32
	      	bne  	r3,debugger_304
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#-1
	      	bne  	r3,debugger_302
debugger_304:
	      	lcu  	r3,-2[bp]
	      	mov  	r1,r3
debugger_305:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_302:
	      	bra  	debugger_300
debugger_301:
	      	ldi  	r1,#-1
	      	bra  	debugger_305
debugger_299:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_305
endpublic

public code dbg_nextSpace:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_306
	      	mov  	bp,sp
	      	subui	sp,sp,#8
debugger_307:
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#-1
	      	bne  	r3,debugger_309
	      	bra  	debugger_308
debugger_309:
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#32
	      	bne  	r3,debugger_307
debugger_308:
	      	lcu  	r3,-2[bp]
	      	mov  	r1,r3
debugger_311:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_306:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_311
endpublic

public code dbg_getHexNumber:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_312
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	sw   	r0,-16[bp]
	      	sw   	r0,-24[bp]
	      	bsr  	dbg_nextNonSpace
	      	dec  	linendx,#1
debugger_313:
	      	ldi  	r3,#1
	      	beq  	r3,debugger_314
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmpu 	r3,r3,#48
	      	blt  	r3,debugger_315
	      	lcu  	r3,-2[bp]
	      	cmpu 	r3,r3,#57
	      	bgt  	r3,debugger_315
	      	lw   	r3,-16[bp]
	      	asli 	r3,r3,#4
	      	lcu  	r4,-2[bp]
	      	subu 	r4,r4,#48
	      	or   	r3,r3,r4
	      	sw   	r3,-16[bp]
	      	bra  	debugger_316
debugger_315:
	      	lcu  	r3,-2[bp]
	      	cmpu 	r3,r3,#65
	      	blt  	r3,debugger_317
	      	lcu  	r3,-2[bp]
	      	cmpu 	r3,r3,#70
	      	bgt  	r3,debugger_317
	      	lw   	r3,-16[bp]
	      	asli 	r3,r3,#4
	      	lcu  	r4,-2[bp]
	      	addu 	r4,r4,#-55
	      	or   	r3,r3,r4
	      	sw   	r3,-16[bp]
	      	bra  	debugger_318
debugger_317:
	      	lcu  	r3,-2[bp]
	      	cmpu 	r3,r3,#97
	      	blt  	r3,debugger_319
	      	lcu  	r3,-2[bp]
	      	cmpu 	r3,r3,#102
	      	bgt  	r3,debugger_319
	      	lw   	r3,-16[bp]
	      	asli 	r3,r3,#4
	      	lcu  	r4,-2[bp]
	      	addu 	r4,r4,#-87
	      	or   	r3,r3,r4
	      	sw   	r3,-16[bp]
	      	bra  	debugger_320
debugger_319:
	      	lw   	r3,24[bp]
	      	lw   	r4,-16[bp]
	      	sw   	r4,[r3]
	      	lw   	r3,-24[bp]
	      	mov  	r1,r3
debugger_321:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_320:
debugger_318:
debugger_316:
	      	lw   	r3,-24[bp]
	      	addu 	r3,r3,#1
	      	sw   	r3,-24[bp]
	      	bra  	debugger_313
debugger_314:
	      	bra  	debugger_321
debugger_312:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_321
endpublic

public code dbg_ReadSetIB:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_324
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	ldi  	r11,#dbg_dbctrl
	      	lw   	r3,24[bp]
	      	cmpu 	r3,r3,#3
	      	ble  	r3,debugger_325
debugger_327:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_325:
	      	bsr  	dbg_nextNonSpace
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#61
	      	bne  	r3,debugger_328
	      	pea  	-16[bp]
	      	bsr  	dbg_GetHexNumber
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	ble  	r3,debugger_330
	      	push 	-16[bp]
	      	push 	24[bp]
	      	bsr  	dbg_SetDBAD
	      	addui	sp,sp,#16
	      	ldi  	r3,#1
	      	lw   	r4,24[bp]
	      	asl  	r3,r3,r4
	      	lw   	r4,[r11]
	      	or   	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r3,#196608
	      	lw   	r4,24[bp]
	      	asli 	r4,r4,#1
	      	asl  	r3,r3,r4
	      	com  	r3,r3
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
	      	bra  	debugger_331
debugger_330:
	      	push 	#0
	      	push 	24[bp]
	      	bsr  	dbg_SetDBAD
	      	addui	sp,sp,#16
	      	ldi  	r3,#1
	      	lw   	r4,24[bp]
	      	asl  	r3,r3,r4
	      	com  	r3,r3
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r3,#196608
	      	lw   	r4,24[bp]
	      	asli 	r4,r4,#1
	      	asl  	r3,r3,r4
	      	com  	r3,r3
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
debugger_331:
	      	bra  	debugger_329
debugger_328:
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#63
	      	bne  	r3,debugger_332
	      	lw   	r3,[r11]
	      	ldi  	r4,#196608
	      	lw   	r5,24[bp]
	      	asli 	r5,r5,#1
	      	asl  	r4,r4,r5
	      	and  	r3,r3,r4
	      	bne  	r3,debugger_334
	      	lw   	r3,[r11]
	      	ldi  	r4,#1
	      	lw   	r5,24[bp]
	      	asl  	r4,r4,r5
	      	ldi  	r5,#1
	      	lw   	r6,24[bp]
	      	asl  	r5,r5,r6
	      	seq  	r4,r4,r5
	      	and  	r3,r3,r4
	      	beq  	r3,debugger_334
	      	push 	24[bp]
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	24[bp]
	      	push 	#debugger_322
	      	bsr  	printf
	      	addui	sp,sp,#24
	      	bra  	debugger_335
debugger_334:
	      	push 	24[bp]
	      	push 	#debugger_323
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_335:
debugger_332:
debugger_329:
	      	bra  	debugger_327
debugger_324:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_327
endpublic

public code dbg_ReadSetDB:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_340
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	ldi  	r11,#dbg_dbctrl
	      	lw   	r3,24[bp]
	      	cmpu 	r3,r3,#3
	      	ble  	r3,debugger_341
debugger_343:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_341:
	      	bsr  	dbg_nextNonSpace
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#61
	      	bne  	r3,debugger_344
	      	pea  	-16[bp]
	      	bsr  	dbg_GetHexNumber
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	ble  	r3,debugger_346
	      	push 	-16[bp]
	      	push 	24[bp]
	      	bsr  	dbg_SetDBAD
	      	addui	sp,sp,#16
	      	ldi  	r3,#1
	      	lw   	r4,24[bp]
	      	asl  	r3,r3,r4
	      	lw   	r4,[r11]
	      	or   	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r3,#196608
	      	lw   	r4,24[bp]
	      	asli 	r4,r4,#1
	      	asl  	r3,r3,r4
	      	com  	r3,r3
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r3,#196608
	      	lw   	r4,24[bp]
	      	asli 	r4,r4,#1
	      	asl  	r3,r3,r4
	      	lw   	r4,[r11]
	      	or   	r4,r4,r3
	      	sw   	r4,[r11]
	      	bra  	debugger_347
debugger_346:
	      	push 	#0
	      	push 	24[bp]
	      	bsr  	dbg_SetDBAD
	      	addui	sp,sp,#16
	      	ldi  	r3,#1
	      	lw   	r4,24[bp]
	      	asl  	r3,r3,r4
	      	com  	r3,r3
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r3,#196608
	      	lw   	r4,24[bp]
	      	asli 	r4,r4,#1
	      	asl  	r3,r3,r4
	      	com  	r3,r3
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
debugger_347:
	      	bra  	debugger_345
debugger_344:
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#63
	      	bne  	r3,debugger_348
	      	lw   	r3,[r11]
	      	ldi  	r4,#196608
	      	lw   	r5,24[bp]
	      	asli 	r5,r5,#1
	      	asl  	r4,r4,r5
	      	and  	r3,r3,r4
	      	ldi  	r4,#196608
	      	lw   	r5,24[bp]
	      	asli 	r5,r5,#1
	      	asl  	r4,r4,r5
	      	cmp  	r3,r3,r4
	      	bne  	r3,debugger_350
	      	lw   	r3,[r11]
	      	ldi  	r4,#1
	      	lw   	r5,24[bp]
	      	asl  	r4,r4,r5
	      	ldi  	r5,#1
	      	lw   	r6,24[bp]
	      	asl  	r5,r5,r6
	      	seq  	r4,r4,r5
	      	and  	r3,r3,r4
	      	beq  	r3,debugger_350
	      	push 	24[bp]
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	24[bp]
	      	push 	#debugger_338
	      	bsr  	printf
	      	addui	sp,sp,#24
	      	bra  	debugger_351
debugger_350:
	      	push 	24[bp]
	      	push 	#debugger_339
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_351:
debugger_348:
debugger_345:
	      	bra  	debugger_343
debugger_340:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_343
endpublic

public code dbg_ReadSetDSB:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_356
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	ldi  	r11,#dbg_dbctrl
	      	lw   	r3,24[bp]
	      	cmpu 	r3,r3,#3
	      	ble  	r3,debugger_357
debugger_359:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_357:
	      	bsr  	dbg_nextNonSpace
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#61
	      	bne  	r3,debugger_360
	      	pea  	-16[bp]
	      	bsr  	dbg_GetHexNumber
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	ble  	r3,debugger_362
	      	push 	-16[bp]
	      	push 	24[bp]
	      	bsr  	dbg_SetDBAD
	      	addui	sp,sp,#16
	      	ldi  	r3,#1
	      	lw   	r4,24[bp]
	      	asl  	r3,r3,r4
	      	lw   	r4,[r11]
	      	or   	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r3,#196608
	      	lw   	r4,24[bp]
	      	asli 	r4,r4,#1
	      	asl  	r3,r3,r4
	      	com  	r3,r3
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r3,#65536
	      	lw   	r4,24[bp]
	      	asli 	r4,r4,#1
	      	asl  	r3,r3,r4
	      	lw   	r4,[r11]
	      	or   	r4,r4,r3
	      	sw   	r4,[r11]
	      	bra  	debugger_363
debugger_362:
	      	push 	#0
	      	push 	24[bp]
	      	bsr  	dbg_SetDBAD
	      	addui	sp,sp,#16
	      	ldi  	r3,#1
	      	lw   	r4,24[bp]
	      	asl  	r3,r3,r4
	      	com  	r3,r3
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
	      	ldi  	r3,#196608
	      	lw   	r4,24[bp]
	      	asli 	r4,r4,#1
	      	asl  	r3,r3,r4
	      	com  	r3,r3
	      	lw   	r4,[r11]
	      	and  	r4,r4,r3
	      	sw   	r4,[r11]
debugger_363:
	      	bra  	debugger_361
debugger_360:
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#63
	      	bne  	r3,debugger_364
	      	lw   	r3,[r11]
	      	ldi  	r4,#196608
	      	lw   	r5,24[bp]
	      	asli 	r5,r5,#1
	      	asl  	r4,r4,r5
	      	and  	r3,r3,r4
	      	ldi  	r4,#65536
	      	lw   	r5,24[bp]
	      	asli 	r5,r5,#1
	      	asl  	r4,r4,r5
	      	cmp  	r3,r3,r4
	      	bne  	r3,debugger_366
	      	lw   	r3,[r11]
	      	ldi  	r4,#1
	      	lw   	r5,24[bp]
	      	asl  	r4,r4,r5
	      	ldi  	r5,#1
	      	lw   	r6,24[bp]
	      	asl  	r5,r5,r6
	      	seq  	r4,r4,r5
	      	and  	r3,r3,r4
	      	beq  	r3,debugger_366
	      	push 	24[bp]
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	24[bp]
	      	push 	#debugger_354
	      	bsr  	printf
	      	addui	sp,sp,#24
	      	bra  	debugger_367
debugger_366:
	      	push 	24[bp]
	      	push 	#debugger_355
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_367:
debugger_364:
debugger_361:
	      	bra  	debugger_359
debugger_356:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_359
endpublic

DispRegs:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_379
	      	mov  	bp,sp
	      	push 	r11
	      	ldi  	r11,#regs
	      	push 	32[r11]
	      	push 	24[r11]
	      	push 	16[r11]
	      	push 	8[r11]
	      	push 	#debugger_371
	      	bsr  	printf
	      	addui	sp,sp,#40
	      	push 	64[r11]
	      	push 	56[r11]
	      	push 	48[r11]
	      	push 	40[r11]
	      	push 	#debugger_372
	      	bsr  	printf
	      	addui	sp,sp,#40
	      	push 	96[r11]
	      	push 	88[r11]
	      	push 	80[r11]
	      	push 	72[r11]
	      	push 	#debugger_373
	      	bsr  	printf
	      	addui	sp,sp,#40
	      	push 	128[r11]
	      	push 	120[r11]
	      	push 	112[r11]
	      	push 	104[r11]
	      	push 	#debugger_374
	      	bsr  	printf
	      	addui	sp,sp,#40
	      	push 	160[r11]
	      	push 	152[r11]
	      	push 	144[r11]
	      	push 	136[r11]
	      	push 	#debugger_375
	      	bsr  	printf
	      	addui	sp,sp,#40
	      	push 	192[r11]
	      	push 	184[r11]
	      	push 	176[r11]
	      	push 	168[r11]
	      	push 	#debugger_376
	      	bsr  	printf
	      	addui	sp,sp,#40
	      	push 	224[r11]
	      	push 	216[r11]
	      	push 	208[r11]
	      	push 	200[r11]
	      	push 	#debugger_377
	      	bsr  	printf
	      	addui	sp,sp,#40
	      	push 	248[r11]
	      	push 	240[r11]
	      	push 	232[r11]
	      	push 	#debugger_378
	      	bsr  	printf
	      	addui	sp,sp,#32
debugger_380:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_379:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_380
DispReg:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_383
	      	mov  	bp,sp
	      	lw   	r3,24[bp]
	      	asli 	r3,r3,#3
	      	push 	regs[r3]
	      	push 	24[bp]
	      	push 	#debugger_382
	      	bsr  	printf
	      	addui	sp,sp,#24
debugger_384:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_383:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_384
public code dbg_prompt:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_386
	      	mov  	bp,sp
	      	push 	#debugger_385
	      	bsr  	printf
	      	addui	sp,sp,#8
debugger_387:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_386:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_387
endpublic

public code dbg_getDecNumber:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_388
	      	mov  	bp,sp
	      	subui	sp,sp,#24
	      	push 	r11
	      	lw   	r11,24[bp]
	      	bne  	r11,debugger_389
	      	ldi  	r1,#0
debugger_391:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_389:
	      	sw   	r0,-8[bp]
	      	sw   	r0,-24[bp]
debugger_392:
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-10[bp]
	      	push 	r3
	      	bsr  	isdigit
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	beq  	r3,debugger_393
	      	ldi  	r3,#-48
	      	lw   	r4,-8[bp]
	      	mul  	r4,r4,#10
	      	lcu  	r5,-10[bp]
	      	addu 	r4,r4,r5
	      	addu 	r3,r3,r4
	      	sw   	r3,-8[bp]
	      	inc  	-24[bp],#1
	      	bra  	debugger_392
debugger_393:
	      	dec  	linendx,#1
	      	lw   	r3,-8[bp]
	      	sw   	r3,[r11]
	      	lw   	r3,-24[bp]
	      	mov  	r1,r3
	      	bra  	debugger_391
debugger_388:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_391
endpublic

public code dbg_processReg:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_394
	      	mov  	bp,sp
	      	subui	sp,sp,#32
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_396
	      	bra  	debugger_397
debugger_396:
	      	bsr  	DispRegs
	      	bra  	debugger_395
debugger_397:
	      	lcu  	r3,-2[bp]
	      	push 	r3
	      	bsr  	isdigit
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	beq  	r3,debugger_398
	      	dec  	linendx,#1
	      	bsr  	dbg_getDecNumber
	      	mov  	r3,r1
	      	sw   	r3,-16[bp]
	      	bsr  	dbg_nextNonSpace
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_401
	      	cmp  	r4,r3,#61
	      	beq  	r4,debugger_402
	      	bra  	debugger_403
debugger_401:
	      	push 	-16[bp]
	      	bsr  	DispReg
	      	addui	sp,sp,#8
debugger_404:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_402:
	      	pea  	-24[bp]
	      	bsr  	dbg_getHexNumber
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	sw   	r3,-32[bp]
	      	lw   	r3,-32[bp]
	      	ble  	r3,debugger_405
	      	lw   	r3,-16[bp]
	      	asli 	r3,r3,#3
	      	lw   	r4,-24[bp]
	      	sw   	r4,regs[r3]
debugger_405:
	      	bra  	debugger_404
debugger_403:
	      	bra  	debugger_404
debugger_400:
debugger_398:
	      	bra  	debugger_404
debugger_395:
	      	bra  	debugger_404
debugger_394:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_404
endpublic

public code dbg_parse_begin:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_407
	      	mov  	bp,sp
	      	push 	r11
	      	ldi  	r11,#linebuf
	      	sw   	r0,linendx
	      	lcu  	r3,[r11]
	      	cmp  	r3,r3,#68
	      	bne  	r3,debugger_408
	      	lcu  	r3,2[r11]
	      	cmp  	r3,r3,#66
	      	bne  	r3,debugger_408
	      	lcu  	r3,4[r11]
	      	cmp  	r3,r3,#71
	      	bne  	r3,debugger_408
	      	lcu  	r3,6[r11]
	      	cmp  	r3,r3,#62
	      	bne  	r3,debugger_408
	      	ldi  	r3,#4
	      	sw   	r3,linendx
debugger_408:
	      	bsr  	dbg_parse_line
	      	mov  	r3,r1
	      	mov  	r1,r3
debugger_410:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_407:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_410
endpublic

public code dbg_parse_line:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_435
	      	mov  	bp,sp
	      	subui	sp,sp,#56
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	push 	r14
	      	push 	r15
	      	push 	r16
	      	push 	r17
	      	ldi  	r11,#muol
	      	ldi  	r12,#cursz
	      	ldi  	r13,#curaddr
	      	ldi  	r14,#curfmt
	      	ldi  	r15,#currep
	      	lea  	r3,-16[bp]
	      	mov  	r16,r3
	      	ldi  	r17,#dbg_dbctrl
debugger_436:
	      	lw   	r3,linendx
	      	cmp  	r3,r3,#84
	      	bge  	r3,debugger_437
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#-1
	      	beq  	r4,debugger_439
	      	cmp  	r4,r3,#32
	      	beq  	r4,debugger_440
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_441
	      	cmp  	r4,r3,#113
	      	beq  	r4,debugger_442
	      	cmp  	r4,r3,#97
	      	beq  	r4,debugger_443
	      	cmp  	r4,r3,#105
	      	beq  	r4,debugger_444
	      	cmp  	r4,r3,#100
	      	beq  	r4,debugger_445
	      	cmp  	r4,r3,#114
	      	beq  	r4,debugger_446
	      	cmp  	r4,r3,#115
	      	beq  	r4,debugger_447
	      	cmp  	r4,r3,#120
	      	beq  	r4,debugger_448
	      	bra  	debugger_438
debugger_439:
debugger_449:
	      	pop  	r17
	      	pop  	r16
	      	pop  	r15
	      	pop  	r14
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_440:
	      	bra  	debugger_438
debugger_441:
	      	bsr  	dbg_DisplayHelp
	      	bra  	debugger_438
debugger_442:
	      	ldi  	r1,#1
	      	bra  	debugger_449
debugger_443:
	      	push 	[r17]
	      	bsr  	dbg_arm
	      	addui	sp,sp,#8
	      	bra  	debugger_438
debugger_444:
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_451
	      	cmp  	r4,r3,#48
	      	beq  	r4,debugger_452
	      	cmp  	r4,r3,#49
	      	beq  	r4,debugger_453
	      	cmp  	r4,r3,#50
	      	beq  	r4,debugger_454
	      	cmp  	r4,r3,#51
	      	beq  	r4,debugger_455
	      	bra  	debugger_450
debugger_451:
	      	lw   	r3,[r17]
	      	and  	r3,r3,#196608
	      	bne  	r3,debugger_456
	      	lw   	r3,[r17]
	      	and  	r3,r3,#1
	      	cmp  	r3,r3,#1
	      	bne  	r3,debugger_456
	      	push 	#0
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_411
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_456:
	      	lw   	r3,[r17]
	      	and  	r3,r3,#3145728
	      	bne  	r3,debugger_458
	      	lw   	r3,[r17]
	      	and  	r3,r3,#2
	      	cmp  	r3,r3,#2
	      	bne  	r3,debugger_458
	      	push 	#1
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_412
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_458:
	      	lw   	r3,[r17]
	      	and  	r3,r3,#50331648
	      	bne  	r3,debugger_460
	      	lw   	r3,[r17]
	      	and  	r3,r3,#4
	      	cmp  	r3,r3,#4
	      	bne  	r3,debugger_460
	      	push 	#2
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_413
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_460:
	      	lw   	r3,[r17]
	      	and  	r3,r3,#805306368
	      	bne  	r3,debugger_462
	      	lw   	r3,[r17]
	      	and  	r3,r3,#8
	      	cmp  	r3,r3,#8
	      	bne  	r3,debugger_462
	      	push 	#3
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_414
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_462:
	      	bra  	debugger_450
debugger_452:
	      	push 	#0
	      	bsr  	dbg_ReadSetIB
	      	addui	sp,sp,#8
	      	bra  	debugger_450
debugger_453:
	      	push 	#1
	      	bsr  	dbg_ReadSetIB
	      	addui	sp,sp,#8
	      	bra  	debugger_450
debugger_454:
	      	push 	#2
	      	bsr  	dbg_ReadSetIB
	      	addui	sp,sp,#8
	      	bra  	debugger_450
debugger_455:
	      	push 	#3
	      	bsr  	dbg_ReadSetIB
	      	addui	sp,sp,#8
	      	bra  	debugger_450
debugger_450:
	      	bra  	debugger_438
debugger_445:
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#105
	      	beq  	r4,debugger_465
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_466
	      	cmp  	r4,r3,#48
	      	beq  	r4,debugger_467
	      	cmp  	r4,r3,#49
	      	beq  	r4,debugger_468
	      	cmp  	r4,r3,#50
	      	beq  	r4,debugger_469
	      	cmp  	r4,r3,#51
	      	beq  	r4,debugger_470
	      	cmp  	r4,r3,#115
	      	beq  	r4,debugger_471
	      	bra  	debugger_472
debugger_465:
	      	bsr  	dbg_nextSpace
	      	push 	r16
	      	bsr  	dbg_getHexNumber
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	sw   	r3,-48[bp]
	      	lw   	r3,-48[bp]
	      	ble  	r3,debugger_473
	      	pea  	-24[bp]
	      	bsr  	dbg_getDecNumber
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	sw   	r3,-56[bp]
	      	lw   	r3,-56[bp]
	      	ble  	r3,debugger_475
debugger_477:
	      	lw   	r3,-56[bp]
	      	ble  	r3,debugger_478
	      	push 	#0
	      	push 	r16
	      	bsr  	disassem
	      	addui	sp,sp,#16
debugger_479:
	      	dec  	-56[bp],#1
	      	bra  	debugger_477
debugger_478:
	      	bra  	debugger_476
debugger_475:
	      	push 	#0
	      	push 	[r16]
	      	bsr  	disassem20
	      	addui	sp,sp,#16
debugger_476:
debugger_473:
	      	bra  	debugger_464
debugger_466:
	      	push 	#debugger_415
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	lw   	r3,[r17]
	      	and  	r3,r3,#196608
	      	cmp  	r3,r3,#196608
	      	bne  	r3,debugger_480
	      	lw   	r3,[r17]
	      	and  	r3,r3,#1
	      	cmp  	r3,r3,#1
	      	bne  	r3,debugger_480
	      	push 	#0
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_416
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_480:
	      	lw   	r3,[r17]
	      	and  	r3,r3,#3145728
	      	cmp  	r3,r3,#3145728
	      	bne  	r3,debugger_482
	      	lw   	r3,[r17]
	      	and  	r3,r3,#2
	      	cmp  	r3,r3,#2
	      	bne  	r3,debugger_482
	      	push 	#1
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_417
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_482:
	      	lw   	r3,[r17]
	      	and  	r3,r3,#50331648
	      	cmp  	r3,r3,#50331648
	      	bne  	r3,debugger_484
	      	lw   	r3,[r17]
	      	and  	r3,r3,#4
	      	cmp  	r3,r3,#4
	      	bne  	r3,debugger_484
	      	push 	#2
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_418
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_484:
	      	lw   	r3,[r17]
	      	and  	r3,r3,#805306368
	      	cmp  	r3,r3,#805306368
	      	bne  	r3,debugger_486
	      	lw   	r3,[r17]
	      	and  	r3,r3,#8
	      	cmp  	r3,r3,#8
	      	bne  	r3,debugger_486
	      	push 	#3
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_419
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_486:
	      	bra  	debugger_464
debugger_467:
	      	push 	#0
	      	bsr  	dbg_ReadSetDB
	      	addui	sp,sp,#8
	      	bra  	debugger_464
debugger_468:
	      	push 	#1
	      	bsr  	dbg_ReadSetDB
	      	addui	sp,sp,#8
	      	bra  	debugger_464
debugger_469:
	      	push 	#2
	      	bsr  	dbg_ReadSetDB
	      	addui	sp,sp,#8
	      	bra  	debugger_464
debugger_470:
	      	push 	#3
	      	bsr  	dbg_ReadSetDB
	      	addui	sp,sp,#8
	      	bra  	debugger_464
debugger_471:
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#63
	      	beq  	r4,debugger_489
	      	cmp  	r4,r3,#48
	      	beq  	r4,debugger_490
	      	cmp  	r4,r3,#49
	      	beq  	r4,debugger_491
	      	cmp  	r4,r3,#50
	      	beq  	r4,debugger_492
	      	cmp  	r4,r3,#51
	      	beq  	r4,debugger_493
	      	bra  	debugger_488
debugger_489:
	      	lw   	r3,[r17]
	      	and  	r3,r3,#196608
	      	cmp  	r3,r3,#65536
	      	bne  	r3,debugger_494
	      	lw   	r3,[r17]
	      	and  	r3,r3,#1
	      	cmp  	r3,r3,#1
	      	bne  	r3,debugger_494
	      	push 	#0
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_420
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_494:
	      	lw   	r3,[r17]
	      	and  	r3,r3,#3145728
	      	cmp  	r3,r3,#1048576
	      	bne  	r3,debugger_496
	      	lw   	r3,[r17]
	      	and  	r3,r3,#2
	      	cmp  	r3,r3,#2
	      	bne  	r3,debugger_496
	      	push 	#1
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_421
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_496:
	      	lw   	r3,[r17]
	      	and  	r3,r3,#50331648
	      	cmp  	r3,r3,#16777216
	      	bne  	r3,debugger_498
	      	lw   	r3,[r17]
	      	and  	r3,r3,#4
	      	cmp  	r3,r3,#4
	      	bne  	r3,debugger_498
	      	push 	#2
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_422
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_498:
	      	lw   	r3,[r17]
	      	and  	r3,r3,#805306368
	      	cmp  	r3,r3,#268435456
	      	bne  	r3,debugger_500
	      	lw   	r3,[r17]
	      	and  	r3,r3,#8
	      	cmp  	r3,r3,#8
	      	bne  	r3,debugger_500
	      	push 	#3
	      	bsr  	dbg_GetDBAD
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	push 	r3
	      	push 	#debugger_423
	      	bsr  	printf
	      	addui	sp,sp,#16
debugger_500:
	      	bra  	debugger_488
debugger_490:
	      	push 	#0
	      	bsr  	dbg_ReadSetDSB
	      	addui	sp,sp,#8
	      	bra  	debugger_488
debugger_491:
	      	push 	#1
	      	bsr  	dbg_ReadSetDSB
	      	addui	sp,sp,#8
	      	bra  	debugger_488
debugger_492:
	      	push 	#2
	      	bsr  	dbg_ReadSetDSB
	      	addui	sp,sp,#8
	      	bra  	debugger_488
debugger_493:
	      	push 	#3
	      	bsr  	dbg_ReadSetDSB
	      	addui	sp,sp,#8
	      	bra  	debugger_488
debugger_488:
	      	bra  	debugger_464
debugger_472:
	      	bsr  	dbg_nextSpace
	      	push 	#0
	      	push 	#0
	      	bsr  	dbg_SetDBAD
	      	addui	sp,sp,#16
	      	push 	#0
	      	push 	#1
	      	bsr  	dbg_SetDBAD
	      	addui	sp,sp,#16
	      	push 	#0
	      	push 	#2
	      	bsr  	dbg_SetDBAD
	      	addui	sp,sp,#16
	      	push 	#0
	      	push 	#3
	      	bsr  	dbg_SetDBAD
	      	addui	sp,sp,#16
	      	push 	#0
	      	bsr  	dbg_arm
	      	addui	sp,sp,#8
	      	bra  	debugger_464
debugger_464:
	      	bra  	debugger_438
debugger_446:
	      	bsr  	dbg_processReg
	      	bra  	debugger_438
debugger_447:
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#115
	      	bne  	r3,debugger_502
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#45
	      	bne  	r3,debugger_504
	      	lw   	r3,[r17]
	      	andi 	r3,r3,#4611686018427387903
	      	sw   	r3,[r17]
	      	push 	[r17]
	      	bsr  	dbg_arm
	      	addui	sp,sp,#8
	      	sw   	r0,ssm
	      	bra  	debugger_505
debugger_504:
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#43
	      	beq  	r3,debugger_508
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#109
	      	bne  	r3,debugger_506
debugger_508:
	      	lw   	r3,[r17]
	      	ori  	r3,r3,#4611686018427387904
	      	sw   	r3,[r17]
	      	push 	[r17]
	      	bsr  	dbg_arm
	      	addui	sp,sp,#8
	      	ldi  	r3,#1
	      	sw   	r3,ssm
	      	ldi  	r1,#1
	      	bra  	debugger_449
debugger_506:
debugger_505:
debugger_502:
	      	bra  	debugger_438
debugger_448:
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#47
	      	bne  	r3,debugger_509
	      	pea  	-40[bp]
	      	bsr  	dbg_getDecNumber
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	sw   	r3,-48[bp]
	      	lw   	r3,-48[bp]
	      	ble  	r3,debugger_511
	      	lw   	r3,-40[bp]
	      	sw   	r3,[r15]
debugger_511:
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#105
	      	beq  	r4,debugger_514
	      	cmp  	r4,r3,#115
	      	beq  	r4,debugger_515
	      	cmp  	r4,r3,#120
	      	beq  	r4,debugger_516
	      	bra  	debugger_513
debugger_514:
	      	ldi  	r3,#105
	      	sc   	r3,[r14]
	      	push 	r16
	      	bsr  	dbg_getHexNumber
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	sw   	r3,-48[bp]
	      	lw   	r3,-48[bp]
	      	ble  	r3,debugger_517
	      	lw   	r3,[r16]
	      	sw   	r3,[r13]
debugger_517:
	      	bra  	debugger_513
debugger_515:
	      	ldi  	r3,#115
	      	sc   	r3,[r14]
	      	push 	r16
	      	bsr  	dbg_getHexNumber
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	sw   	r3,-48[bp]
	      	lw   	r3,-48[bp]
	      	ble  	r3,debugger_519
	      	lw   	r3,[r16]
	      	sw   	r3,[r13]
debugger_519:
	      	bra  	debugger_513
debugger_516:
	      	ldi  	r3,#120
	      	sc   	r3,[r14]
	      	bsr  	dbg_getchar
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	sc   	r3,-2[bp]
	      	lcu  	r3,-2[bp]
	      	cmp  	r4,r3,#98
	      	beq  	r4,debugger_522
	      	cmp  	r4,r3,#99
	      	beq  	r4,debugger_523
	      	cmp  	r4,r3,#104
	      	beq  	r4,debugger_524
	      	cmp  	r4,r3,#119
	      	beq  	r4,debugger_525
	      	bra  	debugger_526
debugger_522:
	      	ldi  	r3,#98
	      	sw   	r3,[r12]
	      	ldi  	r3,#16
	      	sw   	r3,[r11]
	      	bra  	debugger_521
debugger_523:
	      	ldi  	r3,#99
	      	sw   	r3,[r12]
	      	ldi  	r3,#8
	      	sw   	r3,[r11]
	      	bra  	debugger_521
debugger_524:
	      	ldi  	r3,#104
	      	sw   	r3,[r12]
	      	ldi  	r3,#4
	      	sw   	r3,[r11]
	      	bra  	debugger_521
debugger_525:
	      	ldi  	r3,#119
	      	sw   	r3,[r12]
	      	ldi  	r3,#2
	      	sw   	r3,[r11]
	      	bra  	debugger_521
debugger_526:
	      	dec  	linendx,#1
debugger_521:
	      	push 	r16
	      	bsr  	dbg_getHexNumber
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	sw   	r3,-48[bp]
	      	lw   	r3,-48[bp]
	      	ble  	r3,debugger_527
	      	lw   	r3,[r16]
	      	sw   	r3,[r13]
debugger_527:
	      	bra  	debugger_513
debugger_513:
debugger_509:
	      	lcu  	r3,[r14]
	      	cmp  	r4,r3,#105
	      	beq  	r4,debugger_530
	      	cmp  	r4,r3,#115
	      	beq  	r4,debugger_531
	      	cmp  	r4,r3,#120
	      	beq  	r4,debugger_532
	      	bra  	debugger_529
debugger_530:
	      	push 	#debugger_424
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	sw   	r0,-48[bp]
debugger_533:
	      	lw   	r3,-48[bp]
	      	lw   	r4,[r15]
	      	cmp  	r3,r3,r4
	      	bge  	r3,debugger_534
	      	bsr  	getcharNoWait
	      	mov  	r3,r1
	      	cmp  	r3,r3,#3
	      	bne  	r3,debugger_536
	      	bra  	debugger_534
debugger_536:
	      	push 	#0
	      	push 	r13
	      	bsr  	disassem
	      	addui	sp,sp,#16
debugger_535:
	      	inc  	-48[bp],#1
	      	bra  	debugger_533
debugger_534:
	      	bra  	debugger_529
debugger_531:
	      	sw   	r0,-48[bp]
debugger_538:
	      	lw   	r3,-48[bp]
	      	lw   	r4,[r15]
	      	cmp  	r3,r3,r4
	      	bge  	r3,debugger_539
	      	bsr  	getcharNoWait
	      	mov  	r3,r1
	      	cmp  	r3,r3,#3
	      	bne  	r3,debugger_541
	      	bra  	debugger_539
debugger_541:
	      	push 	#84
	      	lw   	r3,[r13]
	      	asri 	r3,r3,#1
	      	asli 	r3,r3,#1
	      	lw   	r4,cmem
	      	addu 	r3,r3,r4
	      	push 	r3
	      	bsr  	putstr
	      	addui	sp,sp,#16
	      	mov  	r3,r1
	      	asli 	r3,r3,#1
	      	lw   	r4,[r13]
	      	addu 	r4,r4,r3
	      	sw   	r4,[r13]
	      	push 	#debugger_425
	      	bsr  	printf
	      	addui	sp,sp,#8
debugger_540:
	      	inc  	-48[bp],#1
	      	bra  	debugger_538
debugger_539:
	      	bra  	debugger_529
debugger_532:
	      	sw   	r0,-48[bp]
debugger_543:
	      	lw   	r3,-48[bp]
	      	lw   	r4,[r15]
	      	cmp  	r3,r3,r4
	      	bge  	r3,debugger_544
	      	bsr  	getcharNoWait
	      	mov  	r3,r1
	      	cmp  	r3,r3,#3
	      	bne  	r3,debugger_546
	      	bra  	debugger_544
debugger_546:
	      	lw   	r3,-48[bp]
	      	lw   	r4,muol
	      	modu 	r3,r3,r4
	      	bne  	r3,debugger_548
	      	lw   	r3,[r12]
	      	cmp  	r4,r3,#98
	      	beq  	r4,debugger_551
	      	cmp  	r4,r3,#99
	      	beq  	r4,debugger_552
	      	cmp  	r4,r3,#104
	      	beq  	r4,debugger_553
	      	cmp  	r4,r3,#119
	      	beq  	r4,debugger_554
	      	bra  	debugger_550
debugger_551:
	      	lw   	r3,[r13]
	      	lw   	r4,-48[bp]
	      	addu 	r3,r3,r4
	      	push 	r3
	      	push 	#debugger_426
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	debugger_550
debugger_552:
	      	lw   	r3,[r13]
	      	lw   	r4,-48[bp]
	      	asli 	r4,r4,#1
	      	addu 	r3,r3,r4
	      	push 	r3
	      	push 	#debugger_427
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	debugger_550
debugger_553:
	      	lw   	r3,[r13]
	      	lw   	r4,-48[bp]
	      	asli 	r4,r4,#2
	      	addu 	r3,r3,r4
	      	push 	r3
	      	push 	#debugger_428
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	debugger_550
debugger_554:
	      	lw   	r3,[r13]
	      	lw   	r4,-48[bp]
	      	asli 	r4,r4,#3
	      	addu 	r3,r3,r4
	      	push 	r3
	      	push 	#debugger_429
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	debugger_550
debugger_550:
debugger_548:
	      	     	 right here ; 
	      	lw   	r3,[r12]
	      	cmp  	r4,r3,#98
	      	beq  	r4,debugger_556
	      	cmp  	r4,r3,#99
	      	beq  	r4,debugger_557
	      	cmp  	r4,r3,#104
	      	beq  	r4,debugger_558
	      	cmp  	r4,r3,#119
	      	beq  	r4,debugger_559
	      	bra  	debugger_555
debugger_556:
	      	lw   	r3,[r13]
	      	lw   	r4,-48[bp]
	      	addu 	r3,r3,r4
	      	lw   	r4,bmem
	      	lbu  	r3,0[r4+r3]
	      	push 	r3
	      	push 	#debugger_430
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	debugger_555
debugger_557:
	      	lw   	r3,[r13]
	      	asri 	r3,r3,#1
	      	lw   	r4,-48[bp]
	      	addu 	r3,r3,r4
	      	asli 	r3,r3,#1
	      	lw   	r4,cmem
	      	lcu  	r3,0[r4+r3]
	      	push 	r3
	      	push 	#debugger_431
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	debugger_555
debugger_558:
	      	lw   	r3,[r13]
	      	asri 	r3,r3,#2
	      	lw   	r4,-48[bp]
	      	addu 	r3,r3,r4
	      	asli 	r3,r3,#2
	      	lw   	r4,hmem
	      	lhu  	r3,0[r4+r3]
	      	push 	r3
	      	push 	#debugger_432
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	debugger_555
debugger_559:
	      	lw   	r3,[r13]
	      	asri 	r3,r3,#3
	      	lw   	r4,-48[bp]
	      	addu 	r3,r3,r4
	      	asli 	r3,r3,#3
	      	lw   	r4,wmem
	      	lw   	r3,0[r4+r3]
	      	push 	r3
	      	push 	#debugger_433
	      	bsr  	printf
	      	addui	sp,sp,#16
	      	bra  	debugger_555
debugger_555:
debugger_545:
	      	inc  	-48[bp],#1
	      	bra  	debugger_543
debugger_544:
	      	lw   	r3,[r12]
	      	cmp  	r4,r3,#98
	      	beq  	r4,debugger_561
	      	cmp  	r4,r3,#99
	      	beq  	r4,debugger_562
	      	cmp  	r4,r3,#104
	      	beq  	r4,debugger_563
	      	cmp  	r4,r3,#119
	      	beq  	r4,debugger_564
	      	bra  	debugger_560
debugger_561:
	      	lw   	r3,-48[bp]
	      	lw   	r4,[r13]
	      	addu 	r4,r4,r3
	      	sw   	r4,[r13]
debugger_562:
	      	lw   	r3,-48[bp]
	      	asli 	r3,r3,#1
	      	lw   	r4,[r13]
	      	addu 	r4,r4,r3
	      	sw   	r4,[r13]
debugger_563:
	      	lw   	r3,-48[bp]
	      	asli 	r3,r3,#2
	      	lw   	r4,[r13]
	      	addu 	r4,r4,r3
	      	sw   	r4,[r13]
debugger_564:
	      	lw   	r3,-48[bp]
	      	asli 	r3,r3,#3
	      	lw   	r4,[r13]
	      	addu 	r4,r4,r3
	      	sw   	r4,[r13]
debugger_560:
	      	push 	#debugger_434
	      	bsr  	printf
	      	addui	sp,sp,#8
	      	bra  	debugger_529
debugger_529:
debugger_438:
	      	bra  	debugger_436
debugger_437:
	      	ldi  	r1,#0
	      	bra  	debugger_449
debugger_435:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_449
endpublic

public code dbg_irq:
	      	     	         lea   sp,dbg_stack+4088
         sw    r1,regs+8
         sw    r2,regs+16
         sw    r3,regs+24
         sw    r4,regs+32
         sw    r5,regs+40
         sw    r6,regs+48
         sw    r7,regs+56
         sw    r8,regs+64
         sw    r9,regs+72
         sw    r10,regs+80
         sw    r11,regs+88
         sw    r12,regs+96
         sw    r13,regs+104
         sw    r14,regs+112
         sw    r15,regs+120
         sw    r16,regs+128
         sw    r17,regs+136
         sw    r18,regs+144
         sw    r19,regs+152
         sw    r20,regs+160
         sw    r21,regs+168
         sw    r22,regs+176
         sw    r23,regs+184
         sw    r24,regs+192
         sw    r25,regs+200
         sw    r26,regs+208
         sw    r27,regs+216
         sw    r28,regs+224
         sw    r29,regs+232
         sw    r30,regs+240
         sw    r31,regs+248
         mfspr r1,cr0
         sw    r1,cr0save

         mfspr r1,dbctrl
         push  r1
         mtspr dbctrl,r0
         mfspr r1,dpc
         push  r1
         bsr   debugger
         addui sp,sp,#16
         
         lw    r1,cr0save
         mtspr cr0,r1
         lw    r1,regs+8
         lw    r2,regs+16
         lw    r3,regs+24
         lw    r4,regs+32
         lw    r5,regs+40
         lw    r6,regs+48
         lw    r7,regs+56
         lw    r8,regs+64
         lw    r9,regs+72
         lw    r10,regs+80
         lw    r11,regs+88
         lw    r12,regs+96
         lw    r13,regs+104
         lw    r14,regs+112
         lw    r15,regs+120
         lw    r16,regs+128
         lw    r17,regs+136
         lw    r18,regs+144
         lw    r19,regs+152
         lw    r20,regs+160
         lw    r21,regs+168
         lw    r22,regs+176
         lw    r23,regs+184
         lw    r24,regs+192
         lw    r25,regs+200
         lw    r26,regs+208
         lw    r27,regs+216
         lw    r28,regs+224
         lw    r29,regs+232
         lw    r30,regs+240
         lw    r31,regs+248
         rtd
     
endpublic

public code debugger:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_568
	      	mov  	bp,sp
	      	subui	sp,sp,#40
	      	push 	r11
	      	push 	r12
	      	push 	r13
	      	push 	r14
	      	ldi  	r11,#bmem
	      	ldi  	r12,#ssm
	      	ldi  	r13,#dbg_dbctrl
	      	lw   	r3,32[bp]
	      	sw   	r3,[r13]
	      	ldi  	r14,#4291821568
	      	lw   	r3,24[bp]
	      	and  	r3,r3,#-4
	      	sw   	r3,24[bp]
	      	lw   	r3,24[bp]
	      	beq  	r3,debugger_569
	      	push 	24[bp]
	      	lw   	r3,24[bp]
	      	subu 	r3,r3,#16
	      	push 	r3
	      	bsr  	disassem20
	      	addui	sp,sp,#16
debugger_569:
debugger_571:
	      	push 	#debugger_567
	      	bsr  	printf
	      	addui	sp,sp,#8
debugger_573:
	      	bsr  	getchar
	      	mov  	r3,r1
	      	sc   	r3,-2[bp]
	      	lw   	r3,[r12]
	      	beq  	r3,debugger_575
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#115
	      	bne  	r3,debugger_577
	      	lw   	r3,[r13]
	      	andi 	r3,r3,#4611686018426404862
	      	sw   	r3,[r13]
	      	lw   	r3,[r13]
	      	ori  	r3,r3,#4611686018427387904
	      	sw   	r3,[r13]
	      	push 	[r13]
	      	bsr  	dbg_arm
	      	addui	sp,sp,#8
debugger_579:
	      	pop  	r14
	      	pop  	r13
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_577:
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#45
	      	beq  	r3,debugger_582
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#3
	      	bne  	r3,debugger_580
debugger_582:
	      	sw   	r0,[r12]
	      	lw   	r3,[r13]
	      	andi 	r3,r3,#4611686018427387903
	      	sw   	r3,[r13]
	      	push 	[r13]
	      	bsr  	dbg_arm
	      	addui	sp,sp,#8
	      	bra  	debugger_579
debugger_580:
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#110
	      	bne  	r3,debugger_583
	      	ldi  	r3,#2
	      	sw   	r3,[r12]
	      	lw   	r3,[r13]
	      	andi 	r3,r3,#4611686018426404863
	      	sw   	r3,[r13]
	      	lw   	r3,[r13]
	      	ori  	r3,r3,#524289
	      	sw   	r3,[r13]
	      	lw   	r3,24[bp]
	      	lbu  	r3,[r3+r11]
	      	and  	r3,r3,#127
	      	cmp  	r3,r3,#124
	      	bne  	r3,debugger_585
	      	lw   	r3,24[bp]
	      	addu 	r3,r3,#4
	      	lbu  	r3,[r3+r11]
	      	and  	r3,r3,#127
	      	cmp  	r3,r3,#124
	      	bne  	r3,debugger_585
	      	inc  	24[bp],#12
	      	bra  	debugger_586
debugger_585:
	      	lw   	r3,24[bp]
	      	lbu  	r3,[r3+r11]
	      	and  	r3,r3,#127
	      	cmp  	r3,r3,#124
	      	bne  	r3,debugger_587
	      	inc  	24[bp],#8
	      	bra  	debugger_588
debugger_587:
	      	inc  	24[bp],#4
debugger_588:
debugger_586:
	      	push 	24[bp]
	      	push 	#0
	      	bsr  	dbg_SetDBAD
	      	addui	sp,sp,#16
	      	push 	[r13]
	      	bsr  	dbg_arm
	      	addui	sp,sp,#8
	      	bra  	debugger_579
debugger_583:
	      	bra  	debugger_576
debugger_575:
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#13
	      	bne  	r3,debugger_589
	      	bra  	debugger_574
debugger_589:
	      	lcu  	r3,-2[bp]
	      	cmp  	r3,r3,#12
	      	bne  	r3,debugger_591
	      	     	                           bsr ClearScreen
                       
	      	bsr  	dbg_HomeCursor
	      	bra  	debugger_574
debugger_591:
	      	lcu  	r3,-2[bp]
	      	push 	r3
	      	bsr  	putch
	      	addui	sp,sp,#8
debugger_576:
	      	ldi  	r3,#1
	      	bne  	r3,debugger_573
debugger_574:
	      	bsr  	dbg_GetCursorRow
	      	mov  	r3,r1
	      	sxb  	r3,r3
	      	sw   	r3,-16[bp]
	      	bsr  	dbg_GetCursorCol
	      	mov  	r3,r1
	      	sxb  	r3,r3
	      	sw   	r3,-24[bp]
	      	sw   	r0,-40[bp]
debugger_593:
	      	lw   	r3,-40[bp]
	      	cmp  	r3,r3,#84
	      	bge  	r3,debugger_594
	      	lw   	r3,-16[bp]
	      	mul  	r3,r3,#84
	      	lw   	r4,-40[bp]
	      	addu 	r3,r3,r4
	      	asli 	r3,r3,#2
	      	lhu  	r3,0[r14+r3]
	      	and  	r3,r3,#1023
	      	push 	r3
	      	bsr  	CvtScreenToAscii
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	sxc  	r3,r3
	      	lw   	r4,-40[bp]
	      	asli 	r4,r4,#1
	      	sc   	r3,linebuf[r4]
debugger_595:
	      	inc  	-40[bp],#1
	      	bra  	debugger_593
debugger_594:
	      	bsr  	dbg_parse_begin
	      	mov  	r3,r1
	      	cmp  	r3,r3,#1
	      	bne  	r3,debugger_596
	      	bra  	debugger_572
debugger_596:
	      	bra  	debugger_571
debugger_572:
	      	bra  	debugger_579
debugger_568:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_579
endpublic

public code dbg_init:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#debugger_598
	      	mov  	bp,sp
	      	push 	#dbg_irq
	      	push 	#496
	      	bsr  	set_vector
	      	addui	sp,sp,#16
	      	push 	#dbg_irq
	      	push 	#495
	      	bsr  	set_vector
	      	addui	sp,sp,#16
	      	sw   	r0,ssm
	      	sw   	r0,bmem
	      	sw   	r0,cmem
	      	sw   	r0,hmem
	      	sw   	r0,wmem
	      	ldi  	r3,#65536
	      	sw   	r3,curaddr
	      	ldi  	r3,#16
	      	sw   	r3,muol
	      	ldi  	r3,#98
	      	sw   	r3,cursz
	      	ldi  	r3,#120
	      	sc   	r3,curfmt
	      	ldi  	r3,#1
	      	sw   	r3,currep
	      	sw   	r0,dbg_dbctrl
debugger_599:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
debugger_598:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	debugger_599
endpublic

	rodata
	align	16
	align	8
debugger_567:
	dc	13,10,68,66,71,62,0
debugger_434:
	dc	13,10,0
debugger_433:
	dc	37,48,49,54,88,32,0
debugger_432:
	dc	37,48,56,88,32,0
debugger_431:
	dc	37,48,52,88,32,0
debugger_430:
	dc	37,48,50,88,32,0
debugger_429:
	dc	13,10,37,48,54,88,32,0
debugger_428:
	dc	13,10,37,48,54,88,32,0
debugger_427:
	dc	13,10,37,48,54,88,32,0
debugger_426:
	dc	13,10,37,48,54,88,32,0
debugger_425:
	dc	13,10,0
debugger_424:
	dc	13,10,0
debugger_423:
	dc	100,115,50,61,37,48,56,88
	dc	13,10,0
debugger_422:
	dc	100,115,50,61,37,48,56,88
	dc	13,10,0
debugger_421:
	dc	100,115,49,61,37,48,56,88
	dc	13,10,0
debugger_420:
	dc	100,115,48,61,37,48,56,88
	dc	13,10,0
debugger_419:
	dc	100,50,61,37,48,56,88,13
	dc	10,0
debugger_418:
	dc	100,50,61,37,48,56,88,13
	dc	10,0
debugger_417:
	dc	100,49,61,37,48,56,88,13
	dc	10,0
debugger_416:
	dc	100,48,61,37,48,56,88,13
	dc	10,0
debugger_415:
	dc	13,10,0
debugger_414:
	dc	105,50,61,37,48,56,88,13
	dc	10,0
debugger_413:
	dc	105,50,61,37,48,56,88,13
	dc	10,0
debugger_412:
	dc	105,49,61,37,48,56,88,13
	dc	10,0
debugger_411:
	dc	105,48,61,37,48,56,88,13
	dc	10,0
debugger_385:
	dc	13,10,68,66,71,62,0
debugger_382:
	dc	114,37,100,61,37,88,13,10
	dc	0
debugger_378:
	dc	114,50,57,61,37,88,32,115
	dc	112,61,37,88,32,108,114,61
	dc	37,88,13,10,0
debugger_377:
	dc	114,50,53,61,37,88,32,114
	dc	50,54,61,37,88,32,114,50
	dc	55,61,37,88,32,114,50,56
	dc	61,37,88,13,10,0
debugger_376:
	dc	114,50,49,61,37,88,32,114
	dc	50,50,61,37,88,32,114,50
	dc	51,61,37,88,32,116,114,61
	dc	37,88,13,10,0
debugger_375:
	dc	114,49,55,61,37,88,32,114
	dc	49,56,61,37,88,32,114,49
	dc	57,61,37,88,32,114,50,48
	dc	61,37,88,13,10,0
debugger_374:
	dc	114,49,51,61,37,88,32,114
	dc	49,52,61,37,88,32,114,49
	dc	53,61,37,88,32,114,49,54
	dc	61,37,88,13,10,0
debugger_373:
	dc	114,57,61,37,88,32,114,49
	dc	48,61,37,88,32,114,49,49
	dc	61,37,88,32,114,49,50,61
	dc	37,88,13,10,0
debugger_372:
	dc	114,53,61,37,88,32,114,54
	dc	61,37,88,32,114,55,61,37
	dc	88,32,114,56,61,37,88,13
	dc	10,0
debugger_371:
	dc	13,10,114,49,61,37,88,32
	dc	114,50,61,37,88,32,114,51
	dc	61,37,88,32,114,52,61,37
	dc	88,13,10,0
debugger_355:
	dc	13,10,68,66,71,62,100,115
	dc	37,100,32,60,110,111,116,32
	dc	115,101,116,62,0
debugger_354:
	dc	13,10,68,66,71,62,100,115
	dc	37,100,61,37,48,56,88,13
	dc	10,0
debugger_339:
	dc	13,10,68,66,71,62,100,37
	dc	100,32,60,110,111,116,32,115
	dc	101,116,62,0
debugger_338:
	dc	13,10,68,66,71,62,100,37
	dc	100,61,37,48,56,88,13,10
	dc	0
debugger_323:
	dc	13,10,68,66,71,62,105,37
	dc	100,32,60,110,111,116,32,115
	dc	101,116,62,0
debugger_322:
	dc	13,10,68,66,71,62,105,37
	dc	100,61,37,48,56,88,13,10
	dc	0
debugger_251:
	dc	13,10,68,66,71,62,0
debugger_250:
	dc	13,10,84,121,112,101,32,39
	dc	113,39,32,116,111,32,113,117
	dc	105,116,46,0
debugger_249:
	dc	13,10,97,114,109,32,100,101
	dc	98,117,103,103,105,110,103,32
	dc	109,111,100,101,32,117,115,105
	dc	110,103,32,116,104,101,32,39
	dc	97,39,32,99,111,109,109,97
	dc	110,100,46,0
debugger_248:
	dc	13,10,79,110,99,101,32,116
	dc	104,101,32,100,101,98,117,103
	dc	32,114,101,103,105,115,116,101
	dc	114,115,32,97,114,101,32,115
	dc	101,116,32,105,116,32,105,115
	dc	32,110,101,99,101,115,115,97
	dc	114,121,32,116,111,32,0
debugger_247:
	dc	13,10,83,101,116,116,105,110
	dc	103,32,97,32,114,101,103,105
	dc	115,116,101,114,32,116,111,32
	dc	122,101,114,111,32,119,105,108
	dc	108,32,99,108,101,97,114,32
	dc	116,104,101,32,98,114,101,97
	dc	107,112,111,105,110,116,46,0
debugger_246:
	dc	13,10,105,110,100,105,99,97
	dc	116,101,32,97,32,100,97,116
	dc	97,32,115,116,111,114,101,32
	dc	111,110,108,121,32,98,114,101
	dc	97,107,112,111,105,110,116,46
	dc	0
debugger_245:
	dc	13,10,98,114,101,97,107,112
	dc	111,105,110,116,46,32,80,114
	dc	101,102,105,120,32,116,104,101
	dc	32,114,101,103,105,115,116,101
	dc	114,32,110,117,109,98,101,114
	dc	32,119,105,116,104,32,39,100
	dc	115,39,32,116,111,0
debugger_244:
	dc	13,10,105,110,115,116,114,117
	dc	99,116,105,111,110,32,98,114
	dc	101,97,107,112,111,105,110,116
	dc	32,111,114,32,97,32,39,100
	dc	39,32,116,111,32,105,110,100
	dc	105,99,97,116,101,32,97,32
	dc	100,97,116,97,0
debugger_243:
	dc	13,10,80,114,101,102,105,120
	dc	32,116,104,101,32,114,101,103
	dc	105,115,116,101,114,32,110,117
	dc	109,98,101,114,32,119,105,116
	dc	104,32,97,110,32,39,105,39
	dc	32,116,111,32,105,110,100,105
	dc	99,97,116,101,32,97,110,0
debugger_242:
	dc	13,10,84,104,101,114,101,32
	dc	97,114,101,32,97,32,116,111
	dc	116,97,108,32,111,102,32,102
	dc	111,117,114,32,98,114,101,97
	dc	107,112,111,105,110,116,32,114
	dc	101,103,105,115,116,101,114,115
	dc	32,40,48,45,51,41,46,0
debugger_241:
	dc	13,10,68,66,71,62,105,49
	dc	61,49,50,51,52,53,54,55
	dc	56,32,32,32,32,32,119,105
	dc	108,108,32,97,115,115,105,103
	dc	110,32,49,50,51,52,53,54
	dc	55,56,32,116,111,32,105,49
	dc	0
debugger_240:
	dc	13,10,97,110,32,97,100,100
	dc	114,101,115,115,32,116,111,32
	dc	105,116,46,0
debugger_239:
	dc	13,10,70,111,108,108,111,119
	dc	105,110,103,32,97,32,98,114
	dc	101,97,107,112,111,105,110,116
	dc	32,114,101,103,105,115,116,101
	dc	114,32,119,105,116,104,32,97
	dc	110,32,39,61,39,32,97,115
	dc	115,105,103,110,115,32,0
debugger_238:
	dc	13,10,68,66,71,62,105,50
	dc	63,0
debugger_237:
	dc	13,10,39,63,39,32,113,117
	dc	101,114,105,101,115,32,116,104
	dc	101,32,115,116,97,116,117,115
	dc	32,111,102,32,97,32,98,114
	dc	101,97,107,112,111,105,110,116
	dc	32,114,101,103,105,115,116,101
	dc	114,32,97,115,32,105,110,58
	dc	0
;	global	dbg_dbctrl
;	global	GetVBR
;	global	dbg_parse_begin
;	global	dbg_ReadSetDSB
	extern	putch
;	global	dbg_prompt
	extern	getcharNoWait
;	global	cursz
;	global	dbg_nextSpace
;	global	CvtScreenToAscii
	extern	dbg_GetHexNumber
;	global	set_vector
;	global	dbg_init
;	global	dbg_getDecNumber
;	global	debugger
;	global	dbg_GetCursorCol
;	global	ssm
	extern	disassem
;	global	dbg_getHexNumber
;	global	ignore_blanks
;	global	dbg_GetCursorRow
;	global	dbg_nextNonSpace
;	global	dbg_getchar
;	global	repcount
;	global	dbg_ungetch
;	global	curfmt
;	global	currep
	extern	printf
;	global	dbg_HomeCursor
;	global	bmem
;	global	dbg_stack
;	global	cmem
;	global	hmem
;	global	dbg_processReg
;	global	dbg_parse_line
;	global	regs
	extern	putstr
;	global	cr0save
;	global	wmem
;	global	dbg_GetDBAD
;	global	dbg_ReadSetDB
	extern	disassem20
;	global	muol
;	global	dbg_ReadSetIB
;	global	dbg_SetDBAD
;	global	dbg_arm
;	global	dbg_irq
	extern	getchar
;	global	linebuf
;	global	curaddr
	extern	isdigit
;	global	linendx
