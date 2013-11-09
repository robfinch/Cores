		code
		org		0xFFFFF800
start
		ldi		r1,#1234
		ldi		r2,#5678
		ldi		r3,#7777
		ldi		r4,#4444
		ldi		r5,#8888
		ldi		r6,#9999
		add		r1,r2,r3
		nand	r3,r4,r5
		nand	r4,r5,r6
		add		r1,r3,r4
		tst		p1,r1
p1.eq	br		foobar
		add		r1,r4,r5
		nop
		nop
foobar
		addi	r1,r57,#1234
		cmpi	p1,r1,#1233
p1.eq	subi	r1,r1,#10
		org		0xFFFFFFF0
		nop
		br		start
		br		start
		org		0xFFFFFFFF