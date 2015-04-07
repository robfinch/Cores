	code
	align	16
public code putch:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        push    r6
		lw		r1,24[bp]
		ldi     r6,#14    ; Teletype output function
        sys     #410      ; Video BIOS call
        pop     r6
	
stdio_969:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#24
endpublic

public code putnum:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#stdio_971
	      	mov  	bp,sp
	      	subui	sp,sp,#424
	      	push 	r11
	      	lea  	r3,-418[bp]
	      	mov  	r11,r3
	      	lw   	r3,32[bp]
	      	blt  	r3,stdio_974
	      	lw   	r3,32[bp]
	      	cmp  	r3,r3,#200
	      	ble  	r3,stdio_972
stdio_974:
	      	sw   	r0,32[bp]
stdio_972:
	      	lw   	r3,24[bp]
	      	bge  	r3,stdio_975
	      	ldi  	r3,#45
	      	bra  	stdio_976
stdio_975:
	      	ldi  	r4,#43
	      	mov  	r3,r4
stdio_976:
	      	sc   	r3,-18[bp]
	      	lw   	r3,24[bp]
	      	bge  	r3,stdio_977
	      	lw   	r3,24[bp]
	      	neg  	r3,r3
	      	sw   	r3,24[bp]
stdio_977:
	      	sw   	r0,-8[bp]
stdio_979:
	      	lw   	r3,-8[bp]
	      	and  	r3,r3,#3
	      	cmp  	r3,r3,#3
	      	bne  	r3,stdio_981
	      	lcu  	r3,40[bp]
	      	sxc  	r3,r3
	      	beq  	r3,stdio_981
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#1
	      	lcu  	r4,40[bp]
	      	sc   	r4,0[r11+r3]
	      	inc  	-8[bp],#1
stdio_981:
	      	lw   	r3,24[bp]
	      	mod  	r3,r3,#10
	      	sw   	r3,-16[bp]
	      	lw   	r3,-16[bp]
	      	cmp  	r3,r3,#9
	      	bgt  	r3,stdio_985
	      	lw   	r3,-16[bp]
	      	bge  	r3,stdio_983
stdio_985:
	      	push 	#stdio_970
	      	bsr  	printf
	      	addui	sp,sp,#8
stdio_983:
	      	lw   	r3,-16[bp]
	      	addu 	r3,r3,#48
	      	lw   	r4,-8[bp]
	      	asli 	r4,r4,#1
	      	sc   	r3,0[r11+r4]
	      	lw   	r3,24[bp]
	      	divs 	r3,r3,#10
	      	sw   	r3,24[bp]
	      	inc  	-8[bp],#1
	      	lw   	r3,24[bp]
	      	beq  	r3,stdio_986
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#18
	      	ble  	r3,stdio_979
stdio_986:
stdio_980:
	      	lcu  	r3,-18[bp]
	      	cmp  	r3,r3,#45
	      	bne  	r3,stdio_987
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#1
	      	lcu  	r4,-18[bp]
	      	sc   	r4,0[r11+r3]
	      	inc  	-8[bp],#1
stdio_987:
stdio_989:
	      	lw   	r3,-8[bp]
	      	lw   	r4,32[bp]
	      	cmp  	r3,r3,r4
	      	bge  	r3,stdio_990
	      	lcu  	r3,48[bp]
	      	push 	r3
	      	bsr  	putch
stdio_991:
	      	dec  	32[bp],#1
	      	bra  	stdio_989
stdio_990:
stdio_992:
	      	lw   	r3,-8[bp]
	      	ble  	r3,stdio_993
	      	dec  	-8[bp],#1
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#1
	      	lcu  	r3,0[r11+r3]
	      	push 	r3
	      	bsr  	putch
	      	bra  	stdio_992
stdio_993:
stdio_994:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#32
stdio_971:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	stdio_994
endpublic

public code puthexnum:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#stdio_995
	      	mov  	bp,sp
	      	subui	sp,sp,#424
	      	push 	r11
	      	lea  	r3,-418[bp]
	      	mov  	r11,r3
	      	lw   	r3,32[bp]
	      	blt  	r3,stdio_998
	      	lw   	r3,32[bp]
	      	cmp  	r3,r3,#200
	      	ble  	r3,stdio_996
stdio_998:
	      	sw   	r0,32[bp]
stdio_996:
	      	sw   	r0,-8[bp]
	      	lw   	r3,24[bp]
	      	bge  	r3,stdio_999
	      	ldi  	r3,#45
	      	bra  	stdio_1000
stdio_999:
	      	ldi  	r4,#43
	      	mov  	r3,r4
stdio_1000:
	      	sc   	r3,-18[bp]
	      	lw   	r3,24[bp]
	      	bge  	r3,stdio_1001
	      	lw   	r3,24[bp]
	      	neg  	r3,r3
	      	sw   	r3,24[bp]
stdio_1001:
stdio_1003:
	      	lw   	r3,24[bp]
	      	and  	r3,r3,#15
	      	sw   	r3,-16[bp]
	      	lw   	r3,-16[bp]
	      	cmp  	r3,r3,#10
	      	bge  	r3,stdio_1005
	      	lw   	r3,-16[bp]
	      	addu 	r3,r3,#48
	      	lw   	r4,-8[bp]
	      	asli 	r4,r4,#1
	      	sc   	r3,0[r11+r4]
	      	bra  	stdio_1006
stdio_1005:
	      	lw   	r3,40[bp]
	      	beq  	r3,stdio_1007
	      	lw   	r3,-16[bp]
	      	subu 	r3,r3,#-55
	      	lw   	r4,-8[bp]
	      	asli 	r4,r4,#1
	      	sc   	r3,0[r11+r4]
	      	bra  	stdio_1008
stdio_1007:
	      	lw   	r3,-16[bp]
	      	subu 	r3,r3,#-87
	      	lw   	r4,-8[bp]
	      	asli 	r4,r4,#1
	      	sc   	r3,0[r11+r4]
stdio_1008:
stdio_1006:
	      	lw   	r3,24[bp]
	      	asri 	r3,r3,#4
	      	sw   	r3,24[bp]
	      	inc  	-8[bp],#1
	      	lw   	r3,24[bp]
	      	beq  	r3,stdio_1009
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#18
	      	blt  	r3,stdio_1003
stdio_1009:
stdio_1004:
	      	lcu  	r3,-18[bp]
	      	cmp  	r3,r3,#45
	      	bne  	r3,stdio_1010
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#1
	      	lcu  	r4,-18[bp]
	      	sc   	r4,0[r11+r3]
	      	inc  	-8[bp],#1
stdio_1010:
stdio_1012:
	      	lw   	r3,-8[bp]
	      	lw   	r4,32[bp]
	      	cmp  	r3,r3,r4
	      	bge  	r3,stdio_1013
	      	lcu  	r3,-18[bp]
	      	cmp  	r3,r3,#45
	      	bne  	r3,stdio_1014
	      	ldi  	r3,#32
	      	bra  	stdio_1015
stdio_1014:
	      	lcu  	r4,48[bp]
	      	sxc  	r4,r4
	      	mov  	r3,r4
stdio_1015:
	      	push 	r3
	      	bsr  	putch
	      	dec  	32[bp],#1
	      	bra  	stdio_1012
stdio_1013:
stdio_1016:
	      	lw   	r3,-8[bp]
	      	ble  	r3,stdio_1017
	      	dec  	-8[bp],#1
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#1
	      	lcu  	r3,0[r11+r3]
	      	push 	r3
	      	bsr  	putch
	      	bra  	stdio_1016
stdio_1017:
stdio_1018:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#32
stdio_995:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	stdio_1018
endpublic

public code putstr:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#stdio_1019
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	lw   	r11,24[bp]
	      	sw   	r11,-8[bp]
stdio_1020:
	      	lcu  	r3,[r11]
	      	beq  	r3,stdio_1021
	      	lw   	r3,32[bp]
	      	ble  	r3,stdio_1021
	      	lcu  	r3,[r11]
	      	push 	r3
	      	bsr  	putch
stdio_1022:
	      	addui	r11,r11,#2
	      	dec  	32[bp],#1
	      	bra  	stdio_1020
stdio_1021:
	      	lw   	r3,-8[bp]
	      	asli 	r3,r3,#1
	      	subu 	r11,r11,r3
	      	lsri 	r11,r11,#1
	      	mov  	r1,r11
stdio_1023:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#16
stdio_1019:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	stdio_1023
endpublic

public code putstr2:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        push    r6
        lw      r1,24[bp]
        ldi     r6,#$1B   ; Video BIOS DisplayString16 function
        sys     #410
        pop     r6
    
stdio_1025:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#24
endpublic

public code getcharNoWait:
	      	     	        push    lr
        bsr     KeybdGetCharNoWait
        pop     lr
        rtl
        push    r6
        ld      r6,#3    ; KeybdGetCharNoWait
        sys     #10
        pop     r6
        rtl
	
endpublic

public code getchar:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#stdio_1028
	      	mov  	bp,sp
	      	subui	sp,sp,#8
stdio_1029:
	      	bsr  	getcharNoWait
	      	mov  	r3,r1
	      	sw   	r3,-8[bp]
	      	lw   	r3,-8[bp]
	      	cmp  	r3,r3,#-1
	      	beq  	r3,stdio_1029
stdio_1030:
	      	lw   	r3,-8[bp]
	      	and  	r3,r3,#255
	      	mov  	r1,r3
stdio_1031:
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
stdio_1028:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	stdio_1031
endpublic

public code printf:
	      	push 	lr
	      	push 	xlr
	      	push 	bp
	      	ldi  	xlr,#stdio_1033
	      	mov  	bp,sp
	      	subui	sp,sp,#40
	      	push 	r11
	      	push 	r12
	      	lea  	r3,24[bp]
	      	mov  	r11,r3
	      	mov  	r12,r11
stdio_1034:
	      	lw   	r3,[r11]
	      	lcu  	r3,[r3]
	      	beq  	r3,stdio_1035
	      	ldi  	r3,#32
	      	sc   	r3,-34[bp]
	      	lw   	r3,[r11]
	      	lcu  	r3,[r3]
	      	cmp  	r3,r3,#37
	      	bne  	r3,stdio_1037
	      	sw   	r0,-16[bp]
	      	ldi  	r3,#65535
	      	sw   	r3,-24[bp]
	      	inc  	[r11],#2
stdio_1032:
	      	lw   	r3,[r11]
	      	lcu  	r3,[r3]
	      	cmp  	r4,r3,#37
	      	beq  	r4,stdio_1040
	      	cmp  	r4,r3,#99
	      	beq  	r4,stdio_1041
	      	cmp  	r4,r3,#100
	      	beq  	r4,stdio_1042
	      	cmp  	r4,r3,#120
	      	beq  	r4,stdio_1043
	      	cmp  	r4,r3,#88
	      	beq  	r4,stdio_1044
	      	cmp  	r4,r3,#115
	      	beq  	r4,stdio_1045
	      	cmp  	r4,r3,#48
	      	beq  	r4,stdio_1046
	      	cmp  	r4,r3,#57
	      	beq  	r4,stdio_1047
	      	cmp  	r4,r3,#56
	      	beq  	r4,stdio_1047
	      	cmp  	r4,r3,#55
	      	beq  	r4,stdio_1047
	      	cmp  	r4,r3,#54
	      	beq  	r4,stdio_1047
	      	cmp  	r4,r3,#53
	      	beq  	r4,stdio_1047
	      	cmp  	r4,r3,#52
	      	beq  	r4,stdio_1047
	      	cmp  	r4,r3,#51
	      	beq  	r4,stdio_1047
	      	cmp  	r4,r3,#50
	      	beq  	r4,stdio_1047
	      	cmp  	r4,r3,#49
	      	beq  	r4,stdio_1047
	      	cmp  	r4,r3,#46
	      	beq  	r4,stdio_1048
	      	bra  	stdio_1039
stdio_1040:
	      	push 	#37
	      	bsr  	putch
	      	bra  	stdio_1039
stdio_1041:
	      	addui	r12,r12,#8
	      	push 	[r12]
	      	bsr  	putch
	      	bra  	stdio_1039
stdio_1042:
	      	addui	r12,r12,#8
	      	lcu  	r3,-34[bp]
	      	push 	r3
	      	push 	#0
	      	push 	-16[bp]
	      	push 	[r12]
	      	bsr  	putnum
	      	bra  	stdio_1039
stdio_1043:
	      	addui	r12,r12,#8
	      	lcu  	r3,-34[bp]
	      	push 	r3
	      	push 	#0
	      	push 	-16[bp]
	      	push 	[r12]
	      	bsr  	puthexnum
	      	bra  	stdio_1039
stdio_1044:
	      	addui	r12,r12,#8
	      	lcu  	r3,-34[bp]
	      	push 	r3
	      	push 	#1
	      	push 	-16[bp]
	      	push 	[r12]
	      	bsr  	puthexnum
	      	bra  	stdio_1039
stdio_1045:
	      	addui	r12,r12,#8
	      	push 	-24[bp]
	      	push 	[r12]
	      	bsr  	putstr
	      	mov  	r3,r1
	      	sw   	r3,-32[bp]
	      	bra  	stdio_1039
stdio_1046:
	      	ldi  	r3,#48
	      	sc   	r3,-34[bp]
stdio_1047:
	      	lw   	r3,[r11]
	      	lcu  	r3,[r3]
	      	subu 	r3,r3,#48
	      	sw   	r3,-16[bp]
	      	inc  	[r11],#2
stdio_1049:
	      	lw   	r3,[r11]
	      	lcu  	r3,[r3]
	      	push 	r3
	      	bsr  	isdigit
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	beq  	r3,stdio_1050
	      	lw   	r3,-16[bp]
	      	muli 	r3,r3,#10
	      	sw   	r3,-16[bp]
	      	lw   	r3,[r11]
	      	lcu  	r3,[r3]
	      	subu 	r3,r3,#48
	      	lw   	r4,-16[bp]
	      	addu 	r4,r4,r3
	      	sw   	r4,-16[bp]
	      	inc  	[r11],#2
	      	bra  	stdio_1049
stdio_1050:
	      	lw   	r3,[r11]
	      	lcu  	r3,[r3]
	      	cmp  	r3,r3,#46
	      	beq  	r3,stdio_1051
	      	bra  	stdio_1032
stdio_1051:
stdio_1048:
	      	inc  	[r11],#2
	      	lw   	r3,[r11]
	      	lcu  	r3,[r3]
	      	push 	r3
	      	bsr  	isdigit
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	bne  	r3,stdio_1053
	      	bra  	stdio_1032
stdio_1053:
	      	lw   	r3,[r11]
	      	lcu  	r3,[r3]
	      	subu 	r3,r3,#48
	      	sw   	r3,-24[bp]
	      	inc  	[r11],#2
stdio_1055:
	      	lw   	r3,[r11]
	      	lcu  	r3,[r3]
	      	push 	r3
	      	bsr  	isdigit
	      	addui	sp,sp,#8
	      	mov  	r3,r1
	      	beq  	r3,stdio_1056
	      	lw   	r3,-24[bp]
	      	muli 	r3,r3,#10
	      	sw   	r3,-24[bp]
	      	lw   	r3,[r11]
	      	lcu  	r3,[r3]
	      	subu 	r3,r3,#48
	      	lw   	r4,-24[bp]
	      	addu 	r4,r4,r3
	      	sw   	r4,-24[bp]
	      	inc  	[r11],#2
	      	bra  	stdio_1055
stdio_1056:
	      	bra  	stdio_1032
stdio_1039:
	      	bra  	stdio_1038
stdio_1037:
	      	lw   	r3,[r11]
	      	lcu  	r3,[r3]
	      	push 	r3
	      	bsr  	putch
stdio_1038:
stdio_1036:
	      	inc  	[r11],#2
	      	bra  	stdio_1034
stdio_1035:
stdio_1057:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	pop  	xlr
	      	pop  	lr
	      	rtl  	#0
stdio_1033:
	      	lw   	lr,8[bp]
	      	sw   	lr,16[bp]
	      	bra  	stdio_1057
endpublic

	rodata
	align	16
	align	8
stdio_970:
	dc	109,111,100,101,114,114,32,0
;	global	putch
;	global	getcharNoWait
;	global	printf
;	global	putnum
;	global	putstr
;	global	getchar
;	global	putstr2
	extern	isdigit
;	global	puthexnum
