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
string_2:
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
string_5:
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
string_8:
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
string_11:
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
string_14:
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
string_17:
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
string_20:
	      	lw   	r3,40[bp]
	      	ble  	r3,string_21
	      	lw   	r3,-8[bp]
	      	lb   	r3,[r3]
	      	lb   	r4,32[bp]
	      	cmp  	r5,r3,r4
	      	bne  	r5,string_23
	      	lw   	r3,-8[bp]
	      	mov  	r1,r3
string_25:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
string_23:
string_22:
	      	inc  	-8[bp],#1
	      	dec  	40[bp],#1
	      	bra  	string_20
string_21:
	      	ldi  	r1,#0
	      	bra  	string_25
endpublic

public code strlen_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	push 	r11
	      	lw   	r11,24[bp]
	      	bne  	r11,string_28
	      	ldi  	r1,#0
string_30:
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
string_28:
	      	sw   	r0,-8[bp]
string_31:
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lc   	r3,0[r11+r3]
	      	beq  	r3,string_32
string_33:
	      	inc  	-8[bp],#1
	      	bra  	string_31
string_32:
	      	lw   	r3,-8[bp]
	      	mov  	r1,r3
	      	bra  	string_30
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
string_36:
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lc   	r3,0[r12+r3]
	      	beq  	r3,string_37
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#1
	      	lcu  	r5,0[r12+r4]
	      	sc   	r5,0[r11+r3]
string_38:
	      	inc  	-8[bp],#1
	      	bra  	string_36
string_37:
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	ldi  	r4,#0
	      	andi 	r4,r4,#65535
	      	sc   	r4,0[r11+r3]
	      	mov  	r1,r11
string_39:
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
string_42:
	      	lw   	r3,-8[bp]
	      	lw   	r4,40[bp]
	      	cmp  	r5,r3,r4
	      	bge  	r5,string_43
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lw   	r5,-8[bp]
	      	asli 	r4,r5,#1
	      	lcu  	r5,0[r12+r4]
	      	sc   	r5,0[r11+r3]
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	lc   	r3,0[r12+r3]
	      	bne  	r3,string_45
	      	bra  	string_43
string_45:
string_44:
	      	inc  	-8[bp],#1
	      	bra  	string_42
string_43:
string_47:
	      	lw   	r3,-8[bp]
	      	lw   	r4,40[bp]
	      	cmp  	r5,r3,r4
	      	bge  	r5,string_48
	      	lw   	r4,-8[bp]
	      	asli 	r3,r4,#1
	      	ldi  	r4,#0
	      	andi 	r4,r4,#65535
	      	sc   	r4,0[r11+r3]
string_49:
	      	inc  	-8[bp],#1
	      	bra  	string_47
string_48:
	      	mov  	r1,r11
string_50:
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
	      	bne  	r3,string_53
	      	ldi  	r1,#0
string_55:
	      	pop  	r12
	      	pop  	r11
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
string_53:
string_56:
	      	lw   	r3,40[bp]
	      	ble  	r3,string_57
	      	lc   	r3,[r11]
	      	lc   	r4,[r12]
	      	cmp  	r5,r3,r4
	      	beq  	r5,string_59
	      	lc   	r3,[r11]
	      	lc   	r4,[r12]
	      	cmpu 	r5,r3,r4
	      	bge  	r5,string_61
	      	ldi  	r3,#-1
	      	bra  	string_62
string_61:
	      	ldi  	r4,#1
	      	mov  	r3,r4
string_62:
	      	mov  	r1,r3
	      	bra  	string_55
string_59:
	      	lc   	r3,[r11]
	      	bne  	r3,string_63
	      	ldi  	r1,#0
	      	bra  	string_55
string_63:
string_60:
string_58:
	      	addui	r11,r11,#2
	      	addui	r12,r12,#2
	      	dec  	40[bp],#1
	      	bra  	string_56
string_57:
	      	ldi  	r1,#0
	      	bra  	string_55
endpublic

public code strchr_:
	      	subui	sp,sp,#16
	      	push 	bp
	      	mov  	bp,sp
	      	subui	sp,sp,#8
	      	lw   	r3,24[bp]
	      	sw   	r3,-8[bp]
string_67:
	      	lw   	r3,40[bp]
	      	ble  	r3,string_68
	      	lw   	r3,-8[bp]
	      	lc   	r3,[r3]
	      	lc   	r4,32[bp]
	      	cmp  	r5,r3,r4
	      	bne  	r5,string_70
	      	lw   	r3,-8[bp]
	      	mov  	r1,r3
string_72:
	      	mov  	sp,bp
	      	pop  	bp
	      	rtl  	#16
string_70:
string_69:
	      	inc  	-8[bp],#2
	      	dec  	40[bp],#1
	      	bra  	string_67
string_68:
	      	ldi  	r1,#0
	      	bra  	string_72
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
