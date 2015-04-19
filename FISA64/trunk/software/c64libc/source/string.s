	code
	align	16
public code memcpy_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        lw    r1,32[bp]
        lw    r2,24[bp]
        lw    r3,40[bp]
    .0001:
        lb    r4,[r1]
        sb    r4,[r2]
        addui r1,r1,#1
        addui r2,r2,#1
        subui r3,r3,#1
        bgt   r3,.0001
    
	      	lw   	r3,24[bp]
	      	mov  	r1,r3
string_1:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code memcpyH_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        lw    r1,32[bp]
        lw    r2,24[bp]
        lw    r3,40[bp]
    .0001:
        lh    r4,[r1]
        sh    r4,[r2]
        addui r1,r1,#4
        addui r2,r2,#4
        subui r3,r3,#1
        bgt   r3,.0001
    
	      	lw   	r3,24[bp]
	      	mov  	r1,r3
string_3:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code memcpyW_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        lw    r1,32[bp]
        lw    r2,24[bp]
        lw    r3,40[bp]
    .0001:
        lw    r4,[r1]
        sw    r4,[r2]
        addui r1,r1,#8
        addui r2,r2,#8
        subui r3,r3,#1
        bgt   r3,.0001
    
	      	lw   	r3,24[bp]
	      	mov  	r1,r3
string_5:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code memset_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        lw    r1,24[bp]
        lw    r2,32[bp]
        lw    r3,40[bp]
.0001:
        sb    r2,[r1]
        addui r1,r1,#1
        subui r3,r3,#1
        bgt   r3,.0001
    
	      	lw   	r3,24[bp]
	      	mov  	r1,r3
string_7:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code memsetH_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        lw    r1,24[bp]
        lw    r2,32[bp]
        lw    r3,40[bp]
.0001:
        sh    r2,[r1]
        addui r1,r1,#4
        subui r3,r3,#1
        bgt   r3,.0001
    
	      	lw   	r3,24[bp]
	      	mov  	r1,r3
string_9:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code memsetW_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	     	        lw    r1,24[bp]
        lw    r2,32[bp]
        lw    r3,40[bp]
.0001:
        sw    r2,[r1]
        addui r1,r1,#8
        subui r3,r3,#1
        bgt   r3,.0001
    
	      	lw   	r3,24[bp]
	      	mov  	r1,r3
string_11:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code memchr_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r3,24[bp]
	      	sw   	r3,-8[bp]
string_13:
	      	lw   	r3,40[bp]
	      	ble  	r3,string_14
	      	lw   	r3,-8[bp]
	      	lbu  	r3,[r3]
	      	lbu  	r4,32[bp]
	      	cmp  	r5,r3,r4
	      	bne  	r5,string_16
	      	lw   	r3,-8[bp]
	      	mov  	r1,r3
string_18:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
string_16:
string_15:
	      	inc  	-8[bp],#1
	      	dec  	40[bp],#1
	      	bra  	string_13
string_14:
	      	ldi  	r1,#0
	      	bra  	string_18
endpublic

public code strlen_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	lw   	r11,24[bp]
	      	bne  	r11,string_20
	      	ldi  	r1,#0
string_22:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
string_20:
	      	sw   	r0,-8[bp]
string_23:
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lcu  	r3,0[r11+r3]
	      	beq  	r3,string_24
string_25:
	      	inc  	-8[bp],#1
	      	bra  	string_23
string_24:
	      	lw   	r3,-8[bp]
	      	mov  	r1,r3
	      	bra  	string_22
endpublic

public code strcpy_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	push 	r12
	      	lw   	r11,24[bp]
	      	lw   	r12,32[bp]
	      	sw   	r0,-8[bp]
string_27:
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lcu  	r3,0[r12+r3]
	      	beq  	r3,string_28
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#1
	      	lcu  	r5,0[r12+r3]
	      	sc   	r5,0[r11+r4]
string_29:
	      	inc  	-8[bp],#1
	      	bra  	string_27
string_28:
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	sc   	r0,0[r11+r3]
	      	mov  	r1,r11
string_30:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code strncpy_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	push 	r12
	      	lw   	r11,24[bp]
	      	lw   	r12,32[bp]
	      	sw   	r0,-8[bp]
string_32:
	      	lw   	r3,-8[bp]
	      	lw   	r4,40[bp]
	      	cmp  	r5,r3,r4
	      	bge  	r5,string_33
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#1
	      	lcu  	r5,0[r12+r3]
	      	sc   	r5,0[r11+r4]
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lcu  	r3,0[r12+r3]
	      	bne  	r3,string_35
	      	bra  	string_33
string_35:
string_34:
	      	inc  	-8[bp],#1
	      	bra  	string_32
string_33:
string_37:
	      	lw   	r3,-8[bp]
	      	lw   	r4,40[bp]
	      	cmp  	r5,r3,r4
	      	bge  	r5,string_38
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	sc   	r0,0[r11+r3]
string_39:
	      	inc  	-8[bp],#1
	      	bra  	string_37
string_38:
	      	mov  	r1,r11
string_40:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
endpublic

public code strncmp_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#16
	      	push 	r11
	      	push 	r12
	      	lw   	r11,24[bp]
	      	lw   	r12,32[bp]
	      	cmp  	r3,r11,r12
	      	bne  	r3,string_42
	      	ldi  	r1,#0
string_44:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
string_42:
string_45:
	      	lw   	r3,40[bp]
	      	ble  	r3,string_46
	      	lcu  	r3,[r11]
	      	lcu  	r4,[r12]
	      	cmp  	r5,r3,r4
	      	beq  	r5,string_48
	      	lcu  	r3,[r11]
	      	lcu  	r4,[r12]
	      	cmpu 	r5,r3,r4
	      	bge  	r5,string_50
	      	ldi  	r3,#-1
	      	bra  	string_51
string_50:
	      	ldi  	r4,#1
	      	mov  	r3,r4
string_51:
	      	mov  	r1,r3
	      	bra  	string_44
string_48:
	      	lcu  	r3,[r11]
	      	bne  	r3,string_52
	      	ldi  	r1,#0
	      	bra  	string_44
string_52:
string_49:
string_47:
	      	addui	r11,r11,#2
	      	addui	r12,r12,#2
	      	dec  	40[bp],#1
	      	bra  	string_45
string_46:
	      	ldi  	r1,#0
	      	bra  	string_44
endpublic

public code strchr_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r3,24[bp]
	      	sw   	r3,-8[bp]
string_55:
	      	lw   	r3,40[bp]
	      	ble  	r3,string_56
	      	lw   	r3,-8[bp]
	      	lcu  	r3,[r3]
	      	lcu  	r4,32[bp]
	      	cmp  	r5,r3,r4
	      	bne  	r5,string_58
	      	lw   	r3,-8[bp]
	      	mov  	r1,r3
string_60:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
string_58:
string_57:
	      	inc  	-8[bp],#2
	      	dec  	40[bp],#1
	      	bra  	string_55
string_56:
	      	ldi  	r1,#0
	      	bra  	string_60
endpublic

	rodata
	align	16
	align	8
;	global	strcpy_
;	global	memcpyH_
;	global	memsetH_
;	global	memcpyW_
;	global	memsetW_
;	global	strncmp_
;	global	strncpy_
;	global	memchr_
;	global	memcpy_
;	global	memset_
;	global	strchr_
;	global	strlen_
